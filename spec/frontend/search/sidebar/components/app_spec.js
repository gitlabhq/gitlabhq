import { GlButton, GlLink } from '@gitlab/ui';
import { createLocalVue, shallowMount } from '@vue/test-utils';
import Vuex from 'vuex';
import { MOCK_QUERY } from 'jest/search/mock_data';
import GlobalSearchSidebar from '~/search/sidebar/components/app.vue';
import ConfidentialityFilter from '~/search/sidebar/components/confidentiality_filter.vue';
import StatusFilter from '~/search/sidebar/components/status_filter.vue';

const localVue = createLocalVue();
localVue.use(Vuex);

describe('GlobalSearchSidebar', () => {
  let wrapper;

  const actionSpies = {
    applyQuery: jest.fn(),
    resetQuery: jest.fn(),
  };

  const createComponent = (initialState) => {
    const store = new Vuex.Store({
      state: {
        query: MOCK_QUERY,
        ...initialState,
      },
      actions: actionSpies,
    });

    wrapper = shallowMount(GlobalSearchSidebar, {
      localVue,
      store,
    });
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  const findSidebarForm = () => wrapper.find('form');
  const findStatusFilter = () => wrapper.find(StatusFilter);
  const findConfidentialityFilter = () => wrapper.find(ConfidentialityFilter);
  const findApplyButton = () => wrapper.find(GlButton);
  const findResetLinkButton = () => wrapper.find(GlLink);

  describe('template', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders StatusFilter always', () => {
      expect(findStatusFilter().exists()).toBe(true);
    });

    it('renders ConfidentialityFilter always', () => {
      expect(findConfidentialityFilter().exists()).toBe(true);
    });

    it('renders ApplyButton always', () => {
      expect(findApplyButton().exists()).toBe(true);
    });
  });

  describe('ResetLinkButton', () => {
    describe('with no filter selected', () => {
      beforeEach(() => {
        createComponent({ query: {} });
      });

      it('does not render', () => {
        expect(findResetLinkButton().exists()).toBe(false);
      });
    });

    describe('with filter selected', () => {
      beforeEach(() => {
        createComponent();
      });

      it('does render when a filter selected', () => {
        expect(findResetLinkButton().exists()).toBe(true);
      });
    });
  });

  describe('actions', () => {
    beforeEach(() => {
      createComponent();
    });

    it('clicking ApplyButton calls applyQuery', () => {
      findSidebarForm().trigger('submit');

      expect(actionSpies.applyQuery).toHaveBeenCalled();
    });

    it('clicking ResetLinkButton calls resetQuery', () => {
      findResetLinkButton().vm.$emit('click');

      expect(actionSpies.resetQuery).toHaveBeenCalled();
    });
  });
});
