import * as getters from '~/error_tracking_settings/store/getters';
import defaultState from '~/error_tracking_settings/store/state';
import { projectList, projectWithHtmlTemplate, staleProject } from '../mock';

describe('Error Tracking Settings - Getters', () => {
  let state;

  beforeEach(() => {
    state = defaultState();
  });

  describe('hasProjects', () => {
    it('should reflect when no projects exist', () => {
      expect(getters.hasProjects(state)).toEqual(false);
    });

    it('should reflect when projects exist', () => {
      state.projects = projectList;

      expect(getters.hasProjects(state)).toEqual(true);
    });
  });

  describe('isProjectInvalid', () => {
    const mockGetters = { hasProjects: true };
    it('should show when a project is valid', () => {
      state.projects = projectList;
      [state.selectedProject] = projectList;

      expect(getters.isProjectInvalid(state, mockGetters)).toEqual(false);
    });

    it('should show when a project is invalid', () => {
      state.projects = projectList;
      state.selectedProject = staleProject;

      expect(getters.isProjectInvalid(state, mockGetters)).toEqual(true);
    });
  });

  describe('dropdownLabel', () => {
    const mockGetters = { hasProjects: false };
    it('should display correctly when there are no projects available', () => {
      expect(getters.dropdownLabel(state, mockGetters)).toEqual('No projects available');
    });

    it('should display correctly when a project is selected', () => {
      [state.selectedProject] = projectList;

      expect(getters.dropdownLabel(state, mockGetters)).toEqual('organizationName | slug');
    });

    it('should display correctly when no project is selected', () => {
      state.projects = projectList;

      expect(getters.dropdownLabel(state, { hasProjects: true })).toEqual('Select project');
    });
  });

  describe('invalidProjectLabel', () => {
    it('should display an error containing the project name', () => {
      [state.selectedProject] = projectList;

      expect(getters.invalidProjectLabel(state)).toEqual(
        'Project "name" is no longer available. Select another project to continue.',
      );
    });

    it('should properly escape the label text', () => {
      state.selectedProject = projectWithHtmlTemplate;

      expect(getters.invalidProjectLabel(state)).toEqual(
        'Project "&lt;strong&gt;bold&lt;/strong&gt;" is no longer available. Select another project to continue.',
      );
    });
  });

  describe('projectSelectionLabel', () => {
    it('should show the correct message when the token is empty', () => {
      expect(getters.projectSelectionLabel(state)).toEqual(
        'To enable project selection, enter a valid Auth Token.',
      );
    });

    it('should show the correct message when token exists', () => {
      state.token = 'test-token';

      expect(getters.projectSelectionLabel(state)).toEqual(
        'Click Connect to reestablish the connection to Sentry and activate the dropdown.',
      );
    });
  });
});
