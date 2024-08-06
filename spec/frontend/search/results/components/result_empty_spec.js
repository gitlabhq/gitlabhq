import Vue from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';

import { shallowMountExtended } from 'helpers/vue_test_utils_helper';

import GlobalSearchResultsEmpty from '~/search/results/components/result_empty.vue';
import { MOCK_QUERY } from '../../mock_data';

Vue.use(Vuex);

describe('GlobalSearchResultsEmpty', () => {
  let wrapper;

  const getterSpies = {
    currentScope: jest.fn(() => 'blobs'),
  };

  const createComponent = (
    props,
    initialState = { query: { scope: 'blobs' }, searchType: 'zoekt' },
  ) => {
    const store = new Vuex.Store({
      state: {
        query: MOCK_QUERY,
        ...initialState,
      },
      getters: getterSpies,
    });

    wrapper = shallowMountExtended(GlobalSearchResultsEmpty, {
      store,
      propsData: {
        ...props,
      },
    });
  };

  describe('component basics', () => {
    beforeEach(() => {
      createComponent();
    });

    it(`renders all parts of header`, () => {
      expect(wrapper.element).toMatchSnapshot();
    });
  });
});
