import Vue, { nextTick } from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import { GlLoadingIcon, GlCard } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import ZoektBlobResults from '~/search/results/components/zoekt_blob_results.vue';
import waitForPromises from 'helpers/wait_for_promises';
import EmptyResult from '~/search/results/components/result_empty.vue';

import { MOCK_QUERY, mockGetBlobSearchQuery } from '../../mock_data';

jest.mock('~/alert');

Vue.use(Vuex);

describe('ZoektBlobResults', () => {
  let wrapper;

  const getterSpies = {
    currentScope: jest.fn(() => 'blobs'),
  };

  const defaultState = { ...MOCK_QUERY, query: { scope: 'blobs' }, searchType: 'zoekt' };
  const defaultProps = { hasResults: true, isLoading: false, blobSearch: {} };

  const createComponent = ({ initialState = {}, propsData = {} } = {}) => {
    const store = new Vuex.Store({
      state: {
        ...defaultState,
        ...initialState,
      },
      getters: getterSpies,
    });
    wrapper = shallowMountExtended(ZoektBlobResults, {
      propsData: {
        ...defaultProps,
        ...propsData,
      },
      store,
      stubs: {
        GlCard,
      },
    });
  };

  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findEmptyResult = () => wrapper.findComponent(EmptyResult);

  beforeEach(() => {
    window.gon.user_color_mode = 'gl-light';
  });

  describe('when loading results', () => {
    beforeEach(async () => {
      createComponent({
        propsData: { isLoading: true },
      });
      jest.advanceTimersByTime(500);
      await waitForPromises();
    });

    it('renders loading icon', () => {
      expect(findLoadingIcon().exists()).toBe(true);
    });
  });

  describe('when component loads normally', () => {
    beforeEach(async () => {
      createComponent({
        propsData: {
          blobSearch: mockGetBlobSearchQuery.data.blobSearch,
        },
      });
      jest.advanceTimersByTime(500);
      await waitForPromises();
    });

    it(`renders component properly`, async () => {
      await nextTick();
      expect(wrapper.element).toMatchSnapshot();
    });
  });

  describe('when component has no results', () => {
    beforeEach(async () => {
      createComponent({
        propsData: { hasResults: false },
      });
      jest.advanceTimersByTime(500);
      await waitForPromises();
    });

    it(`renders component properly`, async () => {
      await nextTick();
      expect(findEmptyResult().exists()).toBe(true);
    });
  });
});
