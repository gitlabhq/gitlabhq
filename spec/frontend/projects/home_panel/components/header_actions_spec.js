import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import ProjectHeaderActions from '~/projects/home_panel/components/header_actions.vue';
import ProjectListItemActions from '~/vue_shared/components/projects_list/project_list_item_actions.vue';
import { visitUrlWithAlerts } from '~/lib/utils/url_utility';
import {
  ACTION_DELETE,
  ACTION_DELETE_IMMEDIATELY,
  ACTION_LEAVE,
} from '~/vue_shared/components/list_actions/constants';
import setWindowLocation from 'helpers/set_window_location_helper';

jest.mock('~/lib/utils/url_utility', () => ({
  ...jest.requireActual('~/lib/utils/url_utility'),
  visitUrlWithAlerts: jest.fn(),
}));

describe('ProjectHeaderActions', () => {
  let wrapper;

  const mockProject = {
    id: 1,
    name: 'Test Project',
    nameWithNamespace: 'Test Group / Test Project',
    fullPath: 'test-group/test-project',
  };

  const defaultProps = {
    project: mockProject,
    dashboardPath: '/dashboard/projects',
  };

  const createComponent = (props = {}) => {
    wrapper = shallowMountExtended(ProjectHeaderActions, {
      propsData: { ...defaultProps, ...props },
    });
  };

  const findProjectListItemActions = () => wrapper.findComponent(ProjectListItemActions);

  beforeEach(() => {
    createComponent();
  });

  it('renders ProjectListItemActions component', () => {
    expect(findProjectListItemActions().exists()).toBe(true);
  });

  it('passes project prop to ProjectListItemActions', () => {
    expect(findProjectListItemActions().props('project')).toEqual(mockProject);
  });

  describe('when action event is emitted', () => {
    describe('when action is ACTION_DELETE', () => {
      it('redirects to dashboardPath with scheduled deletion alert', () => {
        findProjectListItemActions().vm.$emit('action', ACTION_DELETE);

        expect(visitUrlWithAlerts).toHaveBeenCalledWith('http://test.host/dashboard/projects', [
          {
            id: 'namespace-delete-scheduled-success',
            message: 'Test Project moved to pending deletion.',
            variant: 'info',
          },
        ]);
      });
    });

    describe('when action is ACTION_DELETE_IMMEDIATELY', () => {
      it('redirects to dashboardPath', () => {
        findProjectListItemActions().vm.$emit('action', ACTION_DELETE_IMMEDIATELY);

        expect(visitUrlWithAlerts).toHaveBeenCalledWith('http://test.host/dashboard/projects', [
          {
            id: 'namespace-delete-success',
            message: 'Test Project is being deleted.',
            variant: 'info',
          },
        ]);
      });
    });

    describe('when action is ACTION_LEAVE', () => {
      it('redirects to dashboardPath with alerts', () => {
        findProjectListItemActions().vm.$emit('action', ACTION_LEAVE);

        expect(visitUrlWithAlerts).toHaveBeenCalledWith('http://test.host/dashboard/projects', [
          {
            id: 'namespace-leave-success',
            message: 'You left the "Test Group / Test Project" project.',
            variant: 'info',
          },
        ]);
      });
    });

    describe('when action is any other action', () => {
      it('redirects to the fullpath', () => {
        setWindowLocation('?leave=1&search=text');

        findProjectListItemActions().vm.$emit('action', 'some-other-action');

        expect(visitUrlWithAlerts).toHaveBeenCalledWith(
          `http://test.host/${mockProject.fullPath}`,
          [],
        );
      });
    });
  });
});
