import { shallowMount } from '@vue/test-utils';
import { cloneDeep } from 'lodash';
import Vue from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import { MOCK_PROJECT, MOCK_QUERY, CURRENT_SCOPE } from 'jest/search/mock_data';
import { visitUrl, setUrlParams } from '~/lib/utils/url_utility';
import ProjectFilter from '~/search/sidebar/components/project_filter.vue';
import SearchableDropdown from '~/search/sidebar/components/shared/searchable_dropdown.vue';

Vue.use(Vuex);

jest.mock('~/lib/utils/url_utility', () => ({
  visitUrl: jest.fn(),
  setUrlParams: jest.fn(),
}));

describe('ProjectFilter', () => {
  let wrapper;

  const actionSpies = {
    fetchProjects: jest.fn(),
    setFrequentProject: jest.fn(),
    loadFrequentProjects: jest.fn(),
  };

  const defaultProps = {
    initialData: null,
    projectInitialJson: MOCK_PROJECT,
    searchHandler: jest.fn(),
  };

  const createComponent = (initialState, props) => {
    const store = new Vuex.Store({
      state: {
        query: MOCK_QUERY,
        projectInitialJson: MOCK_PROJECT,
        ...initialState,
      },
      actions: actionSpies,
      getters: {
        frequentProjects: () => [],
        currentScope: () => CURRENT_SCOPE,
      },
    });

    wrapper = shallowMount(ProjectFilter, {
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

    describe('when @change is emitted', () => {
      describe('with Any', () => {
        beforeEach(() => {
          findSearchableDropdown().vm.$emit('change', {
            id: null,
            name: 'Any',
            name_with_namespace: 'Any',
          });
        });

        it('calls setUrlParams with null, no group id, nav_source null, then calls visitUrl', () => {
          expect(setUrlParams).toHaveBeenCalledWith({
            include_archived: null,
            project_id: null,
            nav_source: null,
            scope: CURRENT_SCOPE,
          });
          expect(visitUrl).toHaveBeenCalled();
        });

        it('does not call setFrequentProject', () => {
          expect(actionSpies.setFrequentProject).not.toHaveBeenCalled();
        });
      });

      describe('with a Project', () => {
        beforeEach(() => {
          findSearchableDropdown().vm.$emit('change', MOCK_PROJECT);
        });

        it('calls setUrlParams with project id, group id, nav_source null, then calls visitUrl', () => {
          expect(setUrlParams).toHaveBeenCalledWith({
            group_id: MOCK_PROJECT.namespace.id,
            include_archived: null,
            project_id: MOCK_PROJECT.id,
            nav_source: null,
            scope: CURRENT_SCOPE,
          });
          expect(visitUrl).toHaveBeenCalled();
        });

        it(`calls setFrequentProject with the group and global-search-frequent-projects`, () => {
          expect(actionSpies.setFrequentProject).toHaveBeenCalledWith(
            expect.any(Object),
            MOCK_PROJECT,
          );
        });
      });
    });

    describe('when @first-open is emitted', () => {
      beforeEach(() => {
        findSearchableDropdown().vm.$emit('first-open');
      });

      it('calls loadFrequentProjects', () => {
        expect(actionSpies.loadFrequentProjects).toHaveBeenCalledTimes(1);
      });
    });
  });

  describe('computed', () => {
    describe('selectedProject', () => {
      describe('when initialData is null', () => {
        beforeEach(() => {
          createComponent(
            {
              projectInitialJson: {
                id: null,
                name: 'Any',
                name_with_namespace: 'Any',
              },
            },
            {},
          );
        });

        it('sets selectedProject to ANY_OPTION', () => {
          expect(cloneDeep(wrapper.vm.selectedProject)).toStrictEqual({
            id: null,
            name: 'Any',
            name_with_namespace: 'Any',
          });
        });
      });

      describe('when initialData is set', () => {
        beforeEach(() => {
          createComponent({ projectInitialJson: MOCK_PROJECT }, {});
        });

        it('sets selectedProject to the initialData', () => {
          expect(wrapper.vm.selectedProject).toEqual(MOCK_PROJECT);
        });
      });
    });
  });

  describe.each`
    navSource   | initialData     | callMethod
    ${null}     | ${null}         | ${false}
    ${null}     | ${MOCK_PROJECT} | ${false}
    ${'navbar'} | ${null}         | ${false}
    ${'navbar'} | ${MOCK_PROJECT} | ${true}
  `('onCreate', ({ navSource, initialData, callMethod }) => {
    describe(`when nav_source is ${navSource} and ${
      initialData ? 'has' : 'does not have'
    } an initial project`, () => {
      beforeEach(() => {
        createComponent(
          {
            query: { ...MOCK_QUERY, nav_source: navSource },
            projectInitialJson: { ...initialData },
          },
          {},
        );
      });

      it(`${callMethod ? 'does' : 'does not'} call setFrequentProject`, () => {
        if (callMethod) {
          expect(actionSpies.setFrequentProject).toHaveBeenCalledWith(
            expect.any(Object),
            initialData,
          );
        } else {
          expect(actionSpies.setFrequentProject).not.toHaveBeenCalled();
        }
      });
    });
  });
});
