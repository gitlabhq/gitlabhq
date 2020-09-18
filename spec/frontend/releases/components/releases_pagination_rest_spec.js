import Vuex from 'vuex';
import { mount, createLocalVue } from '@vue/test-utils';
import { GlPagination } from '@gitlab/ui';
import ReleasesPaginationRest from '~/releases/components/releases_pagination_rest.vue';
import createStore from '~/releases/stores';
import createListModule from '~/releases/stores/modules/list';
import * as commonUtils from '~/lib/utils/common_utils';

commonUtils.historyPushState = jest.fn();

const localVue = createLocalVue();
localVue.use(Vuex);

describe('~/releases/components/releases_pagination_rest.vue', () => {
  let wrapper;
  let listModule;

  const projectId = 19;

  const createComponent = pageInfo => {
    listModule = createListModule({ projectId });

    listModule.state.restPageInfo = pageInfo;

    listModule.actions.fetchReleases = jest.fn();

    wrapper = mount(ReleasesPaginationRest, {
      store: createStore({
        modules: {
          list: listModule,
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
      expect(listModule.actions.fetchReleases.mock.calls).toEqual([
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
