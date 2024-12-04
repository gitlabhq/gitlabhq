import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import MockAdapter from 'axios-mock-adapter';
import { GlFormCheckbox } from '@gitlab/ui';
import AjaxCache from '~/lib/utils/ajax_cache';
import axios from '~/lib/utils/axios_utils';
import SourceBranchFilter from '~/search/sidebar/components/source_branch_filter/index.vue';
import FilterDropdown from '~/search/sidebar/components/shared/filter_dropdown.vue';
import { useMockInternalEventsTracking } from 'helpers/tracking_internal_events_helper';
import { MOCK_QUERY } from 'jest/search/mock_data';

Vue.use(Vuex);

describe('Source branch filter', () => {
  let wrapper;
  let mock;
  const actions = {
    setQuery: jest.fn(),
    applyQuery: jest.fn(),
  };

  const defaultState = {
    query: {
      scope: 'merge_requests',
      group_id: 1,
      search: '*',
    },
  };

  const createComponent = (state) => {
    const store = new Vuex.Store({
      ...defaultState,
      state,
      actions,
    });

    wrapper = shallowMount(SourceBranchFilter, {
      store,
    });
  };

  const findBranchDropdown = () => wrapper.findComponent(FilterDropdown);
  const findGlFormCheckbox = () => wrapper.findComponent(GlFormCheckbox);

  describe('when nothing is selected', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders the component', () => {
      expect(findBranchDropdown().exists()).toBe(true);
      expect(findGlFormCheckbox().exists()).toBe(true);
    });
  });

  describe('when everything is selected', () => {
    beforeEach(() => {
      createComponent({
        query: {
          ...MOCK_QUERY,
          'not[source_branch]': 'feature',
        },
      });
    });

    it('renders the component with selected options', () => {
      expect(findBranchDropdown().props('selectedItem')).toBe('feature');
      expect(findGlFormCheckbox().attributes('checked')).toBe('true');
    });

    it('displays the correct placeholder text and icon', () => {
      expect(findBranchDropdown().props('searchText')).toBe('feature');
      expect(findBranchDropdown().props('icon')).toBe('branch');
    });
  });

  describe('when opening dropdown', () => {
    beforeEach(() => {
      mock = new MockAdapter(axios);
      jest.spyOn(axios, 'get');
      jest.spyOn(AjaxCache, 'retrieve');

      createComponent({
        groupInitialJson: {
          id: 1,
          full_name: 'gitlab-org/gitlab-test',
          full_path: 'gitlab-org/gitlab-test',
        },
      });
    });

    afterEach(() => {
      mock.restore();
    });

    it('calls AjaxCache with correct params', () => {
      findBranchDropdown().vm.$emit('shown');
      expect(AjaxCache.retrieve).toHaveBeenCalledWith(
        '/-/autocomplete/merge_request_source_branches.json?group_id=1',
      );
    });
  });

  describe.each(['source_branch', 'not[source_branch]'])(
    'when selecting a branch with and withouth toggle',
    (paramName) => {
      const { bindInternalEventDocument } = useMockInternalEventsTracking();

      beforeEach(() => {
        createComponent({
          query: {
            ...MOCK_QUERY,
            [paramName]: 'feature',
          },
        });
      });

      it(`calls setQuery with correct param ${paramName}`, () => {
        const { trackEventSpy } = bindInternalEventDocument(wrapper.element);
        findBranchDropdown().vm.$emit('selected', 'feature');

        expect(actions.setQuery).toHaveBeenCalledWith(expect.anything(), {
          key: paramName,
          value: 'feature',
        });

        expect(trackEventSpy).toHaveBeenCalledWith(
          'select_source_branch_filter_on_merge_request_page',
          {
            label: paramName === 'not[source_branch]' ? 'exclude' : 'include',
          },
          undefined,
        );
      });
    },
  );

  describe('when reseting selected branch', () => {
    beforeEach(() => {
      createComponent();
    });

    it(`calls setQuery with correct param`, () => {
      findBranchDropdown().vm.$emit('reset');

      expect(actions.setQuery).toHaveBeenCalledWith(expect.anything(), {
        key: 'source_branch',
        value: '',
      });

      expect(actions.setQuery).toHaveBeenCalledWith(expect.anything(), {
        key: 'not[source_branch]',
        value: '',
      });

      expect(actions.applyQuery).toHaveBeenCalled();
    });
  });
});
