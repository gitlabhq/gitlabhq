import { GlCollapsibleListbox } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
import { pick, clone } from 'lodash';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import ProjectDropdown from '~/error_tracking_settings/components/project_dropdown.vue';
import { defaultProps, projectList, staleProject } from '../mock';

Vue.use(Vuex);

describe('error tracking settings project dropdown', () => {
  let wrapper;

  function mountComponent() {
    wrapper = shallowMount(ProjectDropdown, {
      propsData: {
        ...pick(
          defaultProps,
          'dropdownLabel',
          'invalidProjectLabel',
          'projects',
          'projectSelectionLabel',
          'selectedProject',
          'token',
        ),
        hasProjects: false,
        isProjectInvalid: false,
      },
    });
  }

  beforeEach(() => {
    mountComponent();
  });

  describe('empty project list', () => {
    it('renders the dropdown', () => {
      expect(wrapper.find('#project-dropdown').exists()).toBe(true);
      expect(wrapper.findComponent(GlCollapsibleListbox).exists()).toBe(true);
    });

    it('shows helper text', () => {
      expect(wrapper.find('.js-project-dropdown-label').exists()).toBe(true);
      expect(wrapper.find('.js-project-dropdown-label').text()).toContain(
        'To enable project selection',
      );
    });

    it('does not show an error', () => {
      expect(wrapper.find('.js-project-dropdown-error').exists()).toBe(false);
    });

    it('does not contain any dropdown items', () => {
      expect(wrapper.findComponent(GlCollapsibleListbox).props('items')).toEqual([]);
      expect(wrapper.findComponent(GlCollapsibleListbox).props('toggleText')).toBe(
        'No projects available',
      );
    });
  });

  describe('populated project list', () => {
    beforeEach(async () => {
      wrapper.setProps({ projects: clone(projectList), hasProjects: true });

      await nextTick();
    });

    it('renders the dropdown', () => {
      expect(wrapper.find('#project-dropdown').exists()).toBe(true);
      expect(wrapper.findComponent(GlCollapsibleListbox).exists()).toBe(true);
    });

    it('contains a number of dropdown items', () => {
      expect(wrapper.findComponent(GlCollapsibleListbox).exists()).toBe(true);
      expect(wrapper.findComponent(GlCollapsibleListbox).props('items').length).toBe(2);
    });
  });

  describe('selected project', () => {
    const selectedProject = clone(projectList[0]);

    beforeEach(async () => {
      wrapper.setProps({ projects: clone(projectList), selectedProject, hasProjects: true });
      await nextTick();
    });

    it('does not show helper text', () => {
      expect(wrapper.find('.js-project-dropdown-label').exists()).toBe(false);
      expect(wrapper.find('.js-project-dropdown-error').exists()).toBe(false);
    });
  });

  describe('invalid project selected', () => {
    beforeEach(async () => {
      wrapper.setProps({
        projects: clone(projectList),
        selectedProject: staleProject,
        isProjectInvalid: true,
      });
      await nextTick();
    });

    it('displays a error', () => {
      expect(wrapper.find('.js-project-dropdown-label').exists()).toBe(false);
      expect(wrapper.find('.js-project-dropdown-error').exists()).toBe(true);
    });
  });
});
