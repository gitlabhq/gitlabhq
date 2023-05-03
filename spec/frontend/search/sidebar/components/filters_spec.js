import { GlButton, GlLink } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import Vuex from 'vuex';
import { MOCK_QUERY } from 'jest/search/mock_data';
import ResultsFilters from '~/search/sidebar/components/results_filters.vue';
import ConfidentialityFilter from '~/search/sidebar/components/confidentiality_filter.vue';
import StatusFilter from '~/search/sidebar/components/status_filter.vue';

Vue.use(Vuex);

describe('GlobalSearchSidebarFilters', () => {
  let wrapper;

  const actionSpies = {
    applyQuery: jest.fn(),
    resetQuery: jest.fn(),
  };

  const defaultGetters = {
    currentScope: () => 'issues',
  };

  const createComponent = (initialState) => {
    const store = new Vuex.Store({
      state: {
        urlQuery: MOCK_QUERY,
        ...initialState,
      },
      actions: actionSpies,
      getters: defaultGetters,
    });

    wrapper = shallowMount(ResultsFilters, {
      store,
    });
  };

  const findSidebarForm = () => wrapper.find('form');
  const findStatusFilter = () => wrapper.findComponent(StatusFilter);
  const findConfidentialityFilter = () => wrapper.findComponent(ConfidentialityFilter);
  const findApplyButton = () => wrapper.findComponent(GlButton);
  const findResetLinkButton = () => wrapper.findComponent(GlLink);

  describe('Renders correctly', () => {
    beforeEach(() => {
      createComponent({ urlQuery: MOCK_QUERY });
    });
    it('renders StatusFilter', () => {
      expect(findStatusFilter().exists()).toBe(true);
    });

    it('renders ConfidentialityFilter', () => {
      expect(findConfidentialityFilter().exists()).toBe(true);
    });

    it('renders ApplyButton', () => {
      expect(findApplyButton().exists()).toBe(true);
    });
  });

  describe('ApplyButton', () => {
    describe('when sidebarDirty is false', () => {
      beforeEach(() => {
        createComponent({ sidebarDirty: false });
      });

      it('disables the button', () => {
        expect(findApplyButton().attributes('disabled')).toBeDefined();
      });
    });

    describe('when sidebarDirty is true', () => {
      beforeEach(() => {
        createComponent({ sidebarDirty: true });
      });

      it('enables the button', () => {
        expect(findApplyButton().attributes('disabled')).toBe(undefined);
      });
    });
  });

  describe('ResetLinkButton', () => {
    describe('with no filter selected', () => {
      beforeEach(() => {
        createComponent({ urlQuery: {} });
      });

      it('does not render', () => {
        expect(findResetLinkButton().exists()).toBe(false);
      });
    });

    describe('with filter selected', () => {
      beforeEach(() => {
        createComponent({ urlQuery: MOCK_QUERY });
      });

      it('does render', () => {
        expect(findResetLinkButton().exists()).toBe(true);
      });
    });

    describe('with filter selected and user updated query back to default', () => {
      beforeEach(() => {
        createComponent({ urlQuery: MOCK_QUERY, query: {} });
      });

      it('does render', () => {
        expect(findResetLinkButton().exists()).toBe(true);
      });
    });
  });

  describe('actions', () => {
    beforeEach(() => {
      createComponent({});
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

  describe.each`
    scope               | showFilter
    ${'issues'}         | ${true}
    ${'merge_requests'} | ${false}
    ${'projects'}       | ${false}
    ${'milestones'}     | ${false}
    ${'users'}          | ${false}
    ${'notes'}          | ${false}
    ${'wiki_blobs'}     | ${false}
    ${'blobs'}          | ${false}
  `(`ConfidentialityFilter`, ({ scope, showFilter }) => {
    beforeEach(() => {
      defaultGetters.currentScope = () => scope;
      createComponent();
    });
    afterEach(() => {
      defaultGetters.currentScope = () => 'issues';
    });

    it(`does${showFilter ? '' : ' not'} render when scope is ${scope}`, () => {
      expect(findConfidentialityFilter().exists()).toBe(showFilter);
    });
  });

  describe.each`
    scope               | showFilter
    ${'issues'}         | ${true}
    ${'merge_requests'} | ${true}
    ${'projects'}       | ${false}
    ${'milestones'}     | ${false}
    ${'users'}          | ${false}
    ${'notes'}          | ${false}
    ${'wiki_blobs'}     | ${false}
    ${'blobs'}          | ${false}
  `(`StatusFilter`, ({ scope, showFilter }) => {
    beforeEach(() => {
      defaultGetters.currentScope = () => scope;
      createComponent();
    });
    afterEach(() => {
      defaultGetters.currentScope = () => 'issues';
    });

    it(`does${showFilter ? '' : ' not'} render when scope is ${scope}`, () => {
      expect(findStatusFilter().exists()).toBe(showFilter);
    });
  });
});
