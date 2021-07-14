import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import Vuex from 'vuex';
import { MOCK_GROUP, MOCK_QUERY } from 'jest/search/mock_data';
import { visitUrl, setUrlParams } from '~/lib/utils/url_utility';
import { GROUPS_LOCAL_STORAGE_KEY } from '~/search/store/constants';
import GroupFilter from '~/search/topbar/components/group_filter.vue';
import SearchableDropdown from '~/search/topbar/components/searchable_dropdown.vue';
import { ANY_OPTION, GROUP_DATA, PROJECT_DATA } from '~/search/topbar/constants';

Vue.use(Vuex);

jest.mock('~/lib/utils/url_utility', () => ({
  visitUrl: jest.fn(),
  setUrlParams: jest.fn(),
}));

describe('GroupFilter', () => {
  let wrapper;

  const actionSpies = {
    fetchGroups: jest.fn(),
    setFrequentGroup: jest.fn(),
    loadFrequentGroups: jest.fn(),
  };

  const defaultProps = {
    initialData: null,
  };

  const createComponent = (initialState, props) => {
    const store = new Vuex.Store({
      state: {
        query: MOCK_QUERY,
        ...initialState,
      },
      actions: actionSpies,
      getters: {
        frequentGroups: () => [],
      },
    });

    wrapper = shallowMount(GroupFilter, {
      store,
      propsData: {
        ...defaultProps,
        ...props,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  const findSearchableDropdown = () => wrapper.find(SearchableDropdown);

  describe('template', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders SearchableDropdown always', () => {
      expect(findSearchableDropdown().exists()).toBe(true);
    });
  });

  describe('events', () => {
    beforeEach(() => {
      createComponent();
    });

    describe('when @search is emitted', () => {
      const search = 'test';

      beforeEach(() => {
        findSearchableDropdown().vm.$emit('search', search);
      });

      it('calls fetchGroups with the search paramter', () => {
        expect(actionSpies.fetchGroups).toHaveBeenCalledTimes(1);
        expect(actionSpies.fetchGroups).toHaveBeenCalledWith(expect.any(Object), search);
      });
    });

    describe('when @change is emitted with Any', () => {
      beforeEach(() => {
        findSearchableDropdown().vm.$emit('change', ANY_OPTION);
      });

      it('calls setUrlParams with group null, project id null, and then calls visitUrl', () => {
        expect(setUrlParams).toHaveBeenCalledWith({
          [GROUP_DATA.queryParam]: null,
          [PROJECT_DATA.queryParam]: null,
        });

        expect(visitUrl).toHaveBeenCalled();
      });

      it('does not call setFrequentGroup', () => {
        expect(actionSpies.setFrequentGroup).not.toHaveBeenCalled();
      });
    });

    describe('when @change is emitted with a group', () => {
      beforeEach(() => {
        findSearchableDropdown().vm.$emit('change', MOCK_GROUP);
      });

      it('calls setUrlParams with group id, project id null, and then calls visitUrl', () => {
        expect(setUrlParams).toHaveBeenCalledWith({
          [GROUP_DATA.queryParam]: MOCK_GROUP.id,
          [PROJECT_DATA.queryParam]: null,
        });

        expect(visitUrl).toHaveBeenCalled();
      });

      it(`calls setFrequentGroup with the group and ${GROUPS_LOCAL_STORAGE_KEY}`, () => {
        expect(actionSpies.setFrequentGroup).toHaveBeenCalledWith(expect.any(Object), MOCK_GROUP);
      });
    });

    describe('when @first-open is emitted', () => {
      beforeEach(() => {
        findSearchableDropdown().vm.$emit('first-open');
      });

      it('calls loadFrequentGroups', () => {
        expect(actionSpies.loadFrequentGroups).toHaveBeenCalledTimes(1);
      });
    });
  });

  describe('computed', () => {
    describe('selectedGroup', () => {
      describe('when initialData is null', () => {
        beforeEach(() => {
          createComponent();
        });

        it('sets selectedGroup to ANY_OPTION', () => {
          expect(wrapper.vm.selectedGroup).toBe(ANY_OPTION);
        });
      });

      describe('when initialData is set', () => {
        beforeEach(() => {
          createComponent({}, { initialData: MOCK_GROUP });
        });

        it('sets selectedGroup to ANY_OPTION', () => {
          expect(wrapper.vm.selectedGroup).toBe(MOCK_GROUP);
        });
      });
    });
  });
});
