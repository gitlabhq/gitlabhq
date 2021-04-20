import { GlPagination } from '@gitlab/ui';
import { mount, createLocalVue } from '@vue/test-utils';
import Vuex from 'vuex';
import * as commonUtils from '~/lib/utils/common_utils';
import ReleasesPaginationRest from '~/releases/components/releases_pagination_rest.vue';
import createStore from '~/releases/stores';
import createIndexModule from '~/releases/stores/modules/index';

commonUtils.historyPushState = jest.fn();

const localVue = createLocalVue();
localVue.use(Vuex);

describe('~/releases/components/releases_pagination_rest.vue', () => {
  let wrapper;
  let indexModule;

  const projectId = 19;

  const createComponent = (pageInfo) => {
    indexModule = createIndexModule({ projectId });

    indexModule.state.restPageInfo = pageInfo;

    indexModule.actions.fetchReleases = jest.fn();

    wrapper = mount(ReleasesPaginationRest, {
      store: createStore({
        modules: {
          index: indexModule,
        },
        featureFlags: {},
      }),
      localVue,
    });
  };

  const findGlPagination = () => wrapper.find(GlPagination);

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('when a page number is clicked', () => {
    const newPage = 2;

    beforeEach(() => {
      createComponent({
        perPage: 20,
        page: 1,
        total: 40,
        totalPages: 2,
        nextPage: 2,
      });

      findGlPagination().vm.$emit('input', newPage);
    });

    it('calls fetchReleases with the correct page', () => {
      expect(indexModule.actions.fetchReleases.mock.calls).toEqual([
        [expect.anything(), { page: newPage }],
      ]);
    });

    it('calls historyPushState with the new URL', () => {
      expect(commonUtils.historyPushState.mock.calls).toEqual([
        [expect.stringContaining(`?page=${newPage}`)],
      ]);
    });
  });
});
