import { shallowMount } from '@vue/test-utils';
import { cloneDeep } from 'lodash';
import Vue from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import { MOCK_GROUP, MOCK_QUERY, CURRENT_SCOPE } from 'jest/search/mock_data';
import { visitUrl, setUrlParams } from '~/lib/utils/url_utility';
import { GROUPS_LOCAL_STORAGE_KEY } from '~/search/store/constants';
import GroupFilter from '~/search/sidebar/components/group_filter.vue';
import SearchableDropdown from '~/search/sidebar/components/shared/searchable_dropdown.vue';

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
    searchHandler: jest.fn(),
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
        currentScope: () => CURRENT_SCOPE,
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

  const findSearchableDropdown = () => wrapper.findComponent(SearchableDropdown);

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

    describe('when @change is emitted with Any', () => {
      beforeEach(() => {
        findSearchableDropdown().vm.$emit('change', {
          id: null,
          name: 'Any',
          name_with_namespace: 'Any',
        });
      });

      it('calls setUrlParams with group null, project id null, nav_source null, and then calls visitUrl', () => {
        expect(setUrlParams).toHaveBeenCalledWith({
          group_id: null,
          project_id: null,
          nav_source: null,
          scope: CURRENT_SCOPE,
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

      it('calls setUrlParams with group id, project id null, nav_source null, and then calls visitUrl', () => {
        expect(setUrlParams).toHaveBeenCalledWith({
          group_id: MOCK_GROUP.id,
          project_id: null,
          nav_source: null,
          scope: CURRENT_SCOPE,
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
          expect(wrapper.vm.selectedGroup).toStrictEqual({
            id: null,
            name: 'Any',
            name_with_namespace: 'Any',
          });
        });
      });

      describe('when initialData is set', () => {
        beforeEach(() => {
          createComponent({ groupInitialJson: { ...MOCK_GROUP } }, {});
        });

        it('sets selectedGroup to ANY_OPTION', () => {
          // cloneDeep to fix Property or method `nodeType` is not defined bug
          expect(cloneDeep(wrapper.vm.selectedGroup)).toStrictEqual(MOCK_GROUP);
        });
      });
    });
  });

  describe.each`
    navSource   | initialData   | callMethod
    ${null}     | ${null}       | ${false}
    ${null}     | ${MOCK_GROUP} | ${false}
    ${'navbar'} | ${null}       | ${false}
    ${'navbar'} | ${MOCK_GROUP} | ${true}
  `('onCreate', ({ navSource, initialData, callMethod }) => {
    describe(`when nav_source is ${navSource} and ${
      initialData ? 'has' : 'does not have'
    } an initial group`, () => {
      beforeEach(() => {
        createComponent(
          {
            query: { ...MOCK_QUERY, nav_source: navSource },
            groupInitialJson: { ...initialData },
          },
          {},
        );
      });

      it(`${callMethod ? 'does' : 'does not'} call setFrequentGroup`, () => {
        if (callMethod) {
          expect(actionSpies.setFrequentGroup).toHaveBeenCalledWith(
            expect.any(Object),
            initialData,
          );
        } else {
          expect(actionSpies.setFrequentGroup).not.toHaveBeenCalled();
        }
      });
    });
  });
});
