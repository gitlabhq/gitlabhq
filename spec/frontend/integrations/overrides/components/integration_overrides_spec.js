import { GlTable, GlLink, GlPagination } from '@gitlab/ui';
import { shallowMount, mount } from '@vue/test-utils';
import MockAdapter from 'axios-mock-adapter';
import waitForPromises from 'helpers/wait_for_promises';
import { DEFAULT_PER_PAGE } from '~/api';
import createFlash from '~/flash';
import IntegrationOverrides from '~/integrations/overrides/components/integration_overrides.vue';
import axios from '~/lib/utils/axios_utils';
import httpStatus from '~/lib/utils/http_status';
import ProjectAvatar from '~/vue_shared/components/project_avatar.vue';

jest.mock('~/flash');

const mockOverrides = Array(DEFAULT_PER_PAGE * 3)
  .fill(1)
  .map((_, index) => ({
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

  const createComponent = ({ mountFn = shallowMount } = {}) => {
    wrapper = mountFn(IntegrationOverrides, {
      propsData: defaultProps,
    });
  };

  beforeEach(() => {
    mockAxios = new MockAdapter(axios);
    mockAxios.onGet(defaultProps.overridesPath).reply(httpStatus.OK, mockOverrides, {
      'X-TOTAL': mockOverrides.length,
      'X-PAGE': 1,
    });
  });

  afterEach(() => {
    mockAxios.restore();
    wrapper.destroy();
  });

  const findGlTable = () => wrapper.findComponent(GlTable);
  const findPagination = () => wrapper.findComponent(GlPagination);
  const findRowsAsModel = () =>
    findGlTable()
      .findAllComponents(GlLink)
      .wrappers.map((link) => {
        const avatar = link.findComponent(ProjectAvatar);

        return {
          href: link.attributes('href'),
          avatarUrl: avatar.props('projectAvatarUrl'),
          avatarName: avatar.props('projectName'),
          text: link.text(),
        };
      });

  describe('while loading', () => {
    it('sets GlTable `busy` attribute to `true`', () => {
      createComponent();

      const table = findGlTable();
      expect(table.exists()).toBe(true);
      expect(table.attributes('busy')).toBe('true');
    });
  });

  describe('when initial request is successful', () => {
    it('sets GlTable `busy` attribute to `false`', async () => {
      createComponent();
      await waitForPromises();

      const table = findGlTable();
      expect(table.exists()).toBe(true);
      expect(table.attributes('busy')).toBeFalsy();
    });

    describe('table template', () => {
      beforeEach(async () => {
        createComponent({ mountFn: mount });
        await waitForPromises();
      });

      it('renders overrides as rows in table', () => {
        expect(findRowsAsModel()).toEqual(
          mockOverrides.map((x) => ({
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
      mockAxios.onGet(defaultProps.overridesPath).reply(httpStatus.INTERNAL_SERVER_ERROR);
      createComponent();
      await waitForPromises();
    });

    it('calls createFlash', () => {
      expect(createFlash).toHaveBeenCalledTimes(1);
      expect(createFlash).toHaveBeenCalledWith({
        message: IntegrationOverrides.i18n.defaultErrorMessage,
        captureError: true,
        error: expect.any(Error),
      });
    });
  });

  describe('pagination', () => {
    it('triggers fetch when `input` event is emitted', async () => {
      createComponent();
      jest.spyOn(axios, 'get');
      await waitForPromises();

      await findPagination().vm.$emit('input', 2);
      expect(axios.get).toHaveBeenCalledWith(defaultProps.overridesPath, {
        params: { page: 2, per_page: DEFAULT_PER_PAGE },
      });
    });

    it('does not render with <=1 page', async () => {
      mockAxios.onGet(defaultProps.overridesPath).reply(httpStatus.OK, [mockOverrides[0]], {
        'X-TOTAL': 1,
        'X-PAGE': 1,
      });

      createComponent();
      await waitForPromises();

      expect(findPagination().exists()).toBe(false);
    });
  });
});
