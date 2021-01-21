import { shallowMount, createLocalVue } from '@vue/test-utils';
import { nextTick } from 'vue';
import Vuex from 'vuex';
import { GlAlert } from '@gitlab/ui';
import MembersApp from '~/members/components/app.vue';
import FilterSortContainer from '~/members/components/filter_sort/filter_sort_container.vue';
import * as commonUtils from '~/lib/utils/common_utils';
import { RECEIVE_MEMBER_ROLE_ERROR, HIDE_ERROR } from '~/members/store/mutation_types';
import mutations from '~/members/store/mutations';

describe('MembersApp', () => {
  const localVue = createLocalVue();
  localVue.use(Vuex);

  let wrapper;
  let store;

  const createComponent = (state = {}, options = {}) => {
    store = new Vuex.Store({
      state: {
        showError: true,
        errorMessage: 'Something went wrong, please try again.',
        ...state,
      },
      mutations,
    });

    wrapper = shallowMount(MembersApp, {
      localVue,
      store,
      ...options,
    });
  };

  const findAlert = () => wrapper.find(GlAlert);
  const findFilterSortContainer = () => wrapper.find(FilterSortContainer);

  beforeEach(() => {
    commonUtils.scrollToElement = jest.fn();
  });

  afterEach(() => {
    wrapper.destroy();
    store = null;
  });

  describe('when `showError` is changed to `true`', () => {
    it('renders and scrolls to error alert', async () => {
      createComponent({ showError: false, errorMessage: '' });

      store.commit(RECEIVE_MEMBER_ROLE_ERROR);

      await nextTick();

      const alert = findAlert();

      expect(alert.exists()).toBe(true);
      expect(alert.text()).toBe(
        "An error occurred while updating the member's role, please try again.",
      );
      expect(commonUtils.scrollToElement).toHaveBeenCalledWith(alert.element);
    });
  });

  describe('when `showError` is changed to `false`', () => {
    it('does not render and scroll to error alert', async () => {
      createComponent();

      store.commit(HIDE_ERROR);

      await nextTick();

      expect(findAlert().exists()).toBe(false);
      expect(commonUtils.scrollToElement).not.toHaveBeenCalled();
    });
  });

  describe('when alert is dismissed', () => {
    it('hides alert', async () => {
      createComponent();

      findAlert().vm.$emit('dismiss');

      await nextTick();

      expect(findAlert().exists()).toBe(false);
    });
  });

  it('renders `FilterSortContainer`', () => {
    createComponent();

    expect(findFilterSortContainer().exists()).toBe(true);
  });
});
