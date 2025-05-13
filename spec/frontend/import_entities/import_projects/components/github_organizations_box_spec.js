import { GlCollapsibleListbox } from '@gitlab/ui';
import MockAdapter from 'axios-mock-adapter';
import { mount } from '@vue/test-utils';
import { nextTick } from 'vue';
import { captureException } from '~/sentry/sentry_browser_wrapper';
import waitForPromises from 'helpers/wait_for_promises';

import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_INTERNAL_SERVER_ERROR, HTTP_STATUS_OK } from '~/lib/utils/http_status';
import { createAlert } from '~/alert';

import GithubOrganizationsBox from '~/import_entities/import_projects/components/github_organizations_box.vue';

jest.mock('~/sentry/sentry_browser_wrapper');
jest.mock('~/alert');

const mockResponse = {
  provider_groups: [{ name: 'alpha-1' }, { name: 'alpha-2' }, { name: 'beta-1' }],
};

describe('GithubOrganizationsBox component', () => {
  let wrapper;
  let mockAxios;

  const findListbox = () => wrapper.findComponent(GlCollapsibleListbox);
  const mockGithubGroupPath = '/mock/groups.json';

  const createComponent = (props) => {
    wrapper = mount(GithubOrganizationsBox, {
      propsData: {
        value: 'some-org',
        ...props,
      },
      provide: () => ({
        statusImportGithubGroupPath: mockGithubGroupPath,
      }),
    });
  };

  beforeEach(() => {
    mockAxios = new MockAdapter(axios);
  });

  afterEach(() => {
    mockAxios.restore();
  });

  it('renders listbox as loading', () => {
    createComponent();
    expect(findListbox().props('loading')).toBe(true);
  });

  it('sets toggle-text to all organizations when selection is not provided', () => {
    createComponent({ value: '' });
    expect(findListbox().props('toggleText')).toBe('All organizations');
  });

  it('sets toggle-text to organization name when it is provided', () => {
    const ORG_NAME = 'org';
    createComponent({ value: ORG_NAME });

    expect(findListbox().props('toggleText')).toBe(ORG_NAME);
  });

  it('emits selected organization from underlying listbox', () => {
    createComponent();

    findListbox().vm.$emit('select', 'org-id');
    expect(wrapper.emitted('input').at(-1)).toStrictEqual(['org-id']);
  });

  describe('when request is successful', () => {
    beforeEach(async () => {
      mockAxios.onGet(mockGithubGroupPath).reply(HTTP_STATUS_OK, mockResponse);

      createComponent();
      await waitForPromises();
    });

    it('renders listbox as loaded', () => {
      expect(findListbox().props('loading')).toBe(false);
    });

    it('filters organizations on search', async () => {
      findListbox().vm.$emit('search', 'alpha');
      await nextTick();

      // 2 items matching search; 1 item for 'All organizations'
      expect(findListbox().props('items')).toHaveLength(3);
    });
  });

  describe('when request fails', () => {
    it('reports error to sentry', async () => {
      mockAxios.onGet(mockGithubGroupPath).reply(HTTP_STATUS_INTERNAL_SERVER_ERROR);

      createComponent();
      await waitForPromises();

      expect(captureException).toHaveBeenCalled();
      expect(createAlert).toHaveBeenCalled();
    });
  });

  describe('infinite scroll', () => {
    describe('when less than 25 organizations are returned', () => {
      it('does not enable infinite scroll', async () => {
        createComponent();
        await waitForPromises();

        expect(findListbox().props('infiniteScroll')).toBe(false);
      });
    });

    describe('when 25 organizations are returned', () => {
      const mockResponsePage1 = {
        provider_groups: Array(25)
          .fill()
          .map((_, i) => ({ name: `org-${i}` })),
      };

      beforeEach(async () => {
        mockAxios.onGet(mockGithubGroupPath).replyOnce(HTTP_STATUS_OK, mockResponsePage1);

        createComponent();
        await waitForPromises();
      });

      it('enables infinite scroll', () => {
        expect(findListbox().props('infiniteScroll')).toBe(true);
      });

      describe('when bottom is reached', () => {
        beforeEach(() => {
          mockAxios
            .onGet(mockGithubGroupPath, { params: { page: 2 } })
            .replyOnce(HTTP_STATUS_OK, mockResponse);

          findListbox().vm.$emit('bottom-reached');
        });

        it('loads more organizations', async () => {
          expect(findListbox().props('infiniteScrollLoading')).toBe(true);

          await waitForPromises();

          expect(findListbox().props('infiniteScrollLoading')).toBe(false);
          // 25 items on page 1; 3 items on page 2; 1 item for 'All organizations'
          expect(findListbox().props('items')).toHaveLength(29);
        });

        it('disables infinite scroll when page 2 has less than 25 organizations', async () => {
          await waitForPromises();
          expect(findListbox().props('infiniteScroll')).toBe(false);
        });
      });
    });
  });
});
