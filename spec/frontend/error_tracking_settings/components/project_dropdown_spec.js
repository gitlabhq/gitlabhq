import _ from 'underscore';
import Vuex from 'vuex';
import { createLocalVue, shallowMount } from '@vue/test-utils';
import { GlDropdown, GlDropdownItem } from '@gitlab/ui';
import ProjectDropdown from '~/error_tracking_settings/components/project_dropdown.vue';
import { defaultProps, projectList, staleProject } from '../mock';

const localVue = createLocalVue();
localVue.use(Vuex);

describe('error tracking settings project dropdown', () => {
  let wrapper;

  function mountComponent() {
    wrapper = shallowMount(ProjectDropdown, {
      localVue,
      propsData: {
        ..._.pick(
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

  afterEach(() => {
    if (wrapper) {
      wrapper.destroy();
    }
  });

  describe('empty project list', () => {
    it('renders the dropdown', () => {
      expect(wrapper.find('#project-dropdown').exists()).toBeTruthy();
      expect(wrapper.find(GlDropdown).exists()).toBeTruthy();
    });

    it('shows helper text', () => {
      expect(wrapper.find('.js-project-dropdown-label').exists()).toBeTruthy();
      expect(wrapper.find('.js-project-dropdown-label').text()).toContain(
        'To enable project selection',
      );
    });

    it('does not show an error', () => {
      expect(wrapper.find('.js-project-dropdown-error').exists()).toBeFalsy();
    });

    it('does not contain any dropdown items', () => {
      expect(wrapper.find(GlDropdownItem).exists()).toBeFalsy();
      expect(wrapper.find(GlDropdown).props('text')).toBe('No projects available');
    });
  });

  describe('populated project list', () => {
    beforeEach(() => {
      wrapper.setProps({ projects: _.clone(projectList), hasProjects: true });

      return wrapper.vm.$nextTick();
    });

    it('renders the dropdown', () => {
      expect(wrapper.find('#project-dropdown').exists()).toBeTruthy();
      expect(wrapper.find(GlDropdown).exists()).toBeTruthy();
    });

    it('contains a number of dropdown items', () => {
      expect(wrapper.find(GlDropdownItem).exists()).toBeTruthy();
      expect(wrapper.findAll(GlDropdownItem).length).toBe(2);
    });
  });

  describe('selected project', () => {
    const selectedProject = _.clone(projectList[0]);

    beforeEach(() => {
      wrapper.setProps({ projects: _.clone(projectList), selectedProject, hasProjects: true });
      return wrapper.vm.$nextTick();
    });

    it('does not show helper text', () => {
      expect(wrapper.find('.js-project-dropdown-label').exists()).toBeFalsy();
      expect(wrapper.find('.js-project-dropdown-error').exists()).toBeFalsy();
    });
  });

  describe('invalid project selected', () => {
    beforeEach(() => {
      wrapper.setProps({
        projects: _.clone(projectList),
        selectedProject: staleProject,
        isProjectInvalid: true,
      });
      return wrapper.vm.$nextTick();
    });

    it('displays a error', () => {
      expect(wrapper.find('.js-project-dropdown-label').exists()).toBeFalsy();
      expect(wrapper.find('.js-project-dropdown-error').exists()).toBeTruthy();
    });
  });
});
