import { GlCollapsibleListbox } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { createTestingPinia } from '@pinia/testing';
import { PiniaVuePlugin } from 'pinia';
import Vue, { nextTick } from 'vue';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import ProjectsDropdown from '~/projects/commit/components/projects_dropdown.vue';
import { useCherryPickCommit } from '~/projects/commit/store/cherry_pick_commit';

Vue.use(PiniaVuePlugin);

describe('ProjectsDropdown', () => {
  let wrapper;
  let pinia;
  let store;
  const projectsMockData = [
    { id: '1', name: '_project_1_', refsUrl: '_project_1_/refs' },
    { id: '2', name: '_project_2_', refsUrl: '_project_2_/refs' },
    { id: '3', name: '_project_3_', refsUrl: '_project_3_/refs' },
  ];

  const createComponent = (term, state = {}) => {
    pinia = createTestingPinia();
    store = useCherryPickCommit();
    store.$patch({ projects: projectsMockData, ...state });

    wrapper = extendedWrapper(
      shallowMount(ProjectsDropdown, {
        pinia,
        provide: {
          modalStore: store,
        },
        propsData: {
          value: term,
        },
      }),
    );
  };

  const findDropdown = () => wrapper.findComponent(GlCollapsibleListbox);

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
