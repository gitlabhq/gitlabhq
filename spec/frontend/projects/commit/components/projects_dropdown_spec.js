import { GlDropdownItem, GlSearchBoxByType } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import Vuex from 'vuex';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import ProjectsDropdown from '~/projects/commit/components/projects_dropdown.vue';

Vue.use(Vuex);

describe('ProjectsDropdown', () => {
  let wrapper;
  let store;
  const spyFetchProjects = jest.fn();
  const projectsMockData = [
    { id: '1', name: '_project_1_', refsUrl: '_project_1_/refs' },
    { id: '2', name: '_project_2_', refsUrl: '_project_2_/refs' },
    { id: '3', name: '_project_3_', refsUrl: '_project_3_/refs' },
  ];

  const createComponent = (term, state = {}) => {
    store = new Vuex.Store({
      getters: {
        sortedProjects: () => projectsMockData,
      },
      state,
    });

    wrapper = extendedWrapper(
      shallowMount(ProjectsDropdown, {
        store,
        propsData: {
          value: term,
        },
      }),
    );
  };

  const findAllDropdownItems = () => wrapper.findAllComponents(GlDropdownItem);
  const findSearchBoxByType = () => wrapper.findComponent(GlSearchBoxByType);
  const findDropdownItemByIndex = (index) => wrapper.findAllComponents(GlDropdownItem).at(index);
  const findNoResults = () => wrapper.findByTestId('empty-result-message');

  afterEach(() => {
    wrapper.destroy();
    spyFetchProjects.mockReset();
  });

  describe('No projects found', () => {
    beforeEach(() => {
      createComponent('_non_existent_project_');
    });

    it('renders empty results message', () => {
      expect(findNoResults().text()).toBe('No matching results');
    });

    it('shows GlSearchBoxByType with default attributes', () => {
      expect(findSearchBoxByType().exists()).toBe(true);
      expect(findSearchBoxByType().vm.$attrs).toMatchObject({
        placeholder: 'Search projects',
      });
    });
  });

  describe('Search term is empty', () => {
    beforeEach(() => {
      createComponent('');
    });

    it('renders all projects when search term is empty', () => {
      expect(findAllDropdownItems()).toHaveLength(3);
      expect(findDropdownItemByIndex(0).text()).toBe('_project_1_');
      expect(findDropdownItemByIndex(1).text()).toBe('_project_2_');
      expect(findDropdownItemByIndex(2).text()).toBe('_project_3_');
    });

    it('should not be selected on the inactive project', () => {
      expect(wrapper.vm.isSelected('_project_1_')).toBe(false);
    });
  });

  describe('Projects found', () => {
    beforeEach(() => {
      createComponent('_project_1_', { targetProjectId: '1' });
    });

    it('renders only the project searched for', () => {
      expect(findAllDropdownItems()).toHaveLength(1);
      expect(findDropdownItemByIndex(0).text()).toBe('_project_1_');
    });

    it('should not display empty results message', () => {
      expect(findNoResults().exists()).toBe(false);
    });

    it('should signify this project is selected', () => {
      expect(findDropdownItemByIndex(0).props('isChecked')).toBe(true);
    });

    it('should signify the project is not selected', () => {
      expect(wrapper.vm.isSelected('_not_selected_project_')).toBe(false);
    });

    describe('Custom events', () => {
      it('should emit selectProject if a project is clicked', () => {
        findDropdownItemByIndex(0).vm.$emit('click');

        expect(wrapper.emitted('selectProject')).toEqual([['1']]);
        expect(wrapper.vm.filterTerm).toBe('_project_1_');
      });
    });
  });

  describe('Case insensitive for search term', () => {
    beforeEach(() => {
      createComponent('_PrOjEcT_1_');
    });

    it('renders only the project searched for', () => {
      expect(findAllDropdownItems()).toHaveLength(1);
      expect(findDropdownItemByIndex(0).text()).toBe('_project_1_');
    });
  });
});
