import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import Vuex from 'vuex';
import { MOCK_PROJECT, MOCK_QUERY } from 'jest/search/mock_data';
import { visitUrl, setUrlParams } from '~/lib/utils/url_utility';
import { PROJECTS_LOCAL_STORAGE_KEY } from '~/search/store/constants';
import ProjectFilter from '~/search/topbar/components/project_filter.vue';
import SearchableDropdown from '~/search/topbar/components/searchable_dropdown.vue';
import { ANY_OPTION, GROUP_DATA, PROJECT_DATA } from '~/search/topbar/constants';

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
  };

  const createComponent = (initialState, props) => {
    const store = new Vuex.Store({
      state: {
        query: MOCK_QUERY,
        ...initialState,
      },
      actions: actionSpies,
    });

    wrapper = shallowMount(ProjectFilter, {
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

      it('calls fetchProjects with the search paramter', () => {
        expect(actionSpies.fetchProjects).toHaveBeenCalledWith(expect.any(Object), search);
      });
    });

    describe('when @change is emitted', () => {
      describe('with Any', () => {
        beforeEach(() => {
          findSearchableDropdown().vm.$emit('change', ANY_OPTION);
        });

        it('calls setUrlParams with null, no group id, then calls visitUrl', () => {
          expect(setUrlParams).toHaveBeenCalledWith({
            [PROJECT_DATA.queryParam]: null,
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

        it('calls setUrlParams with project id, group id, then calls visitUrl', () => {
          expect(setUrlParams).toHaveBeenCalledWith({
            [GROUP_DATA.queryParam]: MOCK_PROJECT.namespace.id,
            [PROJECT_DATA.queryParam]: MOCK_PROJECT.id,
          });
          expect(visitUrl).toHaveBeenCalled();
        });

        it(`calls setFrequentProject with the group and ${PROJECTS_LOCAL_STORAGE_KEY}`, () => {
          expect(actionSpies.setFrequentProject).toHaveBeenCalledWith(
            expect.any(Object),
            MOCK_PROJECT,
          );
        });
      });
    });
  });

  describe('computed', () => {
    describe('selectedProject', () => {
      describe('when initialData is null', () => {
        beforeEach(() => {
          createComponent();
        });

        it('sets selectedProject to ANY_OPTION', () => {
          expect(wrapper.vm.selectedProject).toBe(ANY_OPTION);
        });
      });

      describe('when initialData is set', () => {
        beforeEach(() => {
          createComponent({}, { initialData: MOCK_PROJECT });
        });

        it('sets selectedProject to the initialData', () => {
          expect(wrapper.vm.selectedProject).toBe(MOCK_PROJECT);
        });
      });
    });
  });

  describe('onCreate', () => {
    beforeEach(() => {
      createComponent();
    });

    it('calls loadFrequentProjects', () => {
      expect(actionSpies.loadFrequentProjects).toHaveBeenCalledTimes(1);
    });
  });
});
