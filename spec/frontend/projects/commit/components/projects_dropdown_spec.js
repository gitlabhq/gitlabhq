import { GlCollapsibleListbox } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
// eslint-disable-next-line no-restricted-imports
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

  const findDropdown = () => wrapper.findComponent(GlCollapsibleListbox);

  afterEach(() => {
    spyFetchProjects.mockReset();
  });

  describe('Projects found', () => {
    beforeEach(() => {
      createComponent('_project_1_', { targetProjectId: '1' });
    });

    describe('Custom events', () => {
      it('should emit input if a project is clicked', () => {
        findDropdown().vm.$emit('select', '1');

        expect(wrapper.emitted('input')).toEqual([['1']]);
      });
    });
  });

  describe('Case insensitive for search term', () => {
    beforeEach(() => {
      createComponent('_PrOjEcT_1_', { targetProjectId: '1' });
    });

    it('renders only the project searched for', async () => {
      findDropdown().vm.$emit('search', '_project_1_');

      await nextTick();

      expect(findDropdown().props('items')).toEqual([{ text: '_project_1_', value: '1' }]);
    });
  });
});
