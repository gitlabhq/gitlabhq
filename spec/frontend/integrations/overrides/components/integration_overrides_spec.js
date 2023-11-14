import { GlTable, GlLink, GlPagination, GlAlert } from '@gitlab/ui';
import { shallowMount, mount } from '@vue/test-utils';
import MockAdapter from 'axios-mock-adapter';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import waitForPromises from 'helpers/wait_for_promises';
import { DEFAULT_PER_PAGE } from '~/api';
import IntegrationOverrides from '~/integrations/overrides/components/integration_overrides.vue';
import IntegrationTabs from '~/integrations/overrides/components/integration_tabs.vue';

import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_INTERNAL_SERVER_ERROR, HTTP_STATUS_OK } from '~/lib/utils/http_status';
import ProjectAvatar from '~/vue_shared/components/project_avatar.vue';
import UrlSync from '~/vue_shared/components/url_sync.vue';

const mockOverrides = Array(DEFAULT_PER_PAGE * 3)
  .fill(1)
  .map((_, index) => ({
    id: index,
    name: `test-proj-${index}`,
    avatar_url: `avatar-${index}`,
    full_path: `test-proj-${index}`,
    full_name: `test-proj-${index}`,
  }));

describe('IntegrationOverrides', () => {
  let wrapper;
  let mockAxios;

  const defaultProps = {
    overridesPath: 'mock/overrides',
  };

  const createComponent = ({ mountFn = shallowMount, stubs } = {}) => {
    wrapper = mountFn(IntegrationOverrides, {
      propsData: defaultProps,
      stubs,
    });
  };

  beforeEach(() => {
    mockAxios = new MockAdapter(axios);
    mockAxios.onGet(defaultProps.overridesPath).reply(HTTP_STATUS_OK, mockOverrides, {
      'X-TOTAL': mockOverrides.length,
      'X-PAGE': 1,
    });
  });

  afterEach(() => {
    mockAxios.restore();
  });

  const findGlTable = () => wrapper.findComponent(GlTable);
  const findPagination = () => wrapper.findComponent(GlPagination);
  const findIntegrationTabs = () => wrapper.findComponent(IntegrationTabs);
  const findRowsAsModel = () =>
    findGlTable()
      .findAllComponents(GlLink)
      .wrappers.map((link) => {
        const avatar = link.findComponent(ProjectAvatar);

        return {
          id: avatar.props('projectId'),
          href: link.attributes('href'),
          avatarUrl: avatar.props('projectAvatarUrl'),
          avatarName: avatar.props('projectName'),
          text: link.text(),
        };
      });
  const findAlert = () => wrapper.findComponent(GlAlert);

  describe('while loading', () => {
    it('sets GlTable `busy` attribute to `true`', () => {
      createComponent();

      const table = findGlTable();
      expect(table.exists()).toBe(true);
      expect(table.attributes('busy')).toBe('true');
    });

    it('renders IntegrationTabs with count as `null`', () => {
      createComponent();

      expect(findIntegrationTabs().props('projectOverridesCount')).toBe(null);
    });
  });

  describe('when initial request is successful', () => {
    it('sets GlTable `busy` attribute to `false`', async () => {
      createComponent();
      await waitForPromises();

      const table = findGlTable();
      expect(table.exists()).toBe(true);
      expect(table.attributes('busy')).toBeUndefined();
    });

    it('renders IntegrationTabs with count', async () => {
      createComponent();
      await waitForPromises();

      expect(findIntegrationTabs().props('projectOverridesCount')).toBe(mockOverrides.length);
    });

    describe('table template', () => {
      beforeEach(async () => {
        createComponent({ mountFn: mount });
        await waitForPromises();
      });

      it('renders overrides as rows in table', () => {
        expect(findRowsAsModel()).toEqual(
          mockOverrides.map((x) => ({
            id: x.id,
            href: x.full_path,
            avatarUrl: x.avatar_url,
            avatarName: x.name,
            text: expect.stringContaining(x.full_name),
          })),
        );
      });
    });
  });

  describe('when request fails', () => {
    beforeEach(async () => {
      jest.spyOn(Sentry, 'captureException');
      mockAxios.onGet(defaultProps.overridesPath).reply(HTTP_STATUS_INTERNAL_SERVER_ERROR);

      createComponent();
      await waitForPromises();
    });

    it('displays error alert', () => {
      const alert = findAlert();
      expect(alert.exists()).toBe(true);
      expect(alert.text()).toBe(IntegrationOverrides.i18n.defaultErrorMessage);
    });

    it('hides overrides table', () => {
      const table = findGlTable();
      expect(table.exists()).toBe(false);
    });

    it('captures exception in Sentry', () => {
      expect(Sentry.captureException).toHaveBeenCalledWith(expect.any(Error));
    });
  });

  describe('pagination', () => {
    describe('when total items does not exceed the page limit', () => {
      it('does not render', async () => {
        mockAxios.onGet(defaultProps.overridesPath).reply(HTTP_STATUS_OK, [mockOverrides[0]], {
          'X-TOTAL': DEFAULT_PER_PAGE - 1,
          'X-PAGE': 1,
        });

        createComponent();

        // wait for initial load
        await waitForPromises();

        expect(findPagination().exists()).toBe(false);
      });
    });

    describe('when total items exceeds the page limit', () => {
      const mockPage = 2;

      beforeEach(async () => {
        createComponent({ stubs: { UrlSync } });
        mockAxios.onGet(defaultProps.overridesPath).reply(HTTP_STATUS_OK, [mockOverrides[0]], {
          'X-TOTAL': DEFAULT_PER_PAGE * 2,
          'X-PAGE': mockPage,
        });

        // wait for initial load
        await waitForPromises();
      });

      it('renders', () => {
        expect(findPagination().exists()).toBe(true);
      });

      describe('when navigating to a page', () => {
        beforeEach(async () => {
          jest.spyOn(axios, 'get');

          // trigger a page change
          await findPagination().vm.$emit('input', mockPage);
        });

        it('performs GET request with correct params', () => {
          expect(axios.get).toHaveBeenCalledWith(defaultProps.overridesPath, {
            params: { page: mockPage, per_page: DEFAULT_PER_PAGE },
          });
        });

        it('updates `page` URL parameter', () => {
          expect(window.location.search).toBe(`?page=${mockPage}`);
        });
      });
    });
  });
});
