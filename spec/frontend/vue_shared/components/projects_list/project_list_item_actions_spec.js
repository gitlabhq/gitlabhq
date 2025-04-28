import { nextTick } from 'vue';
import { GlLoadingIcon } from '@gitlab/ui';
import projects from 'test_fixtures/api/users/projects/get.json';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { renderRestoreSuccessToast } from '~/vue_shared/components/projects_list/utils';
import { restoreProject } from '~/rest_api';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import ListActions from '~/vue_shared/components/list_actions/list_actions.vue';
import ProjectListItemActions from '~/vue_shared/components/projects_list/project_list_item_actions.vue';
import {
  ACTION_EDIT,
  ACTION_RESTORE,
  ACTION_DELETE,
} from '~/vue_shared/components/list_actions/constants';
import { createAlert } from '~/alert';

jest.mock('~/vue_shared/components/projects_list/utils', () => ({
  ...jest.requireActual('~/vue_shared/components/projects_list/utils'),
  renderRestoreSuccessToast: jest.fn(),
}));
jest.mock('~/alert');
jest.mock('~/api/projects_api');

describe('ProjectListItemActions', () => {
  let wrapper;

  const [project] = convertObjectPropsToCamelCase(projects, { deep: true });

  const editPath = '/foo/bar/edit';
  const projectWithActions = {
    ...project,
    availableActions: [ACTION_EDIT, ACTION_RESTORE, ACTION_DELETE],
    editPath,
  };

  const defaultProps = {
    project: projectWithActions,
  };

  const createComponent = ({ props = {} } = {}) => {
    wrapper = shallowMountExtended(ProjectListItemActions, {
      propsData: { ...defaultProps, ...props },
    });
  };

  const findListActions = () => wrapper.findComponent(ListActions);
  const findListActionsLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const restoreProjectAction = async () => {
    findListActions().props('actions')[ACTION_RESTORE].action();
    await nextTick();
  };

  beforeEach(() => {
    createComponent();
  });

  describe('template', () => {
    it('displays actions dropdown', () => {
      expect(findListActions().props()).toMatchObject({
        actions: {
          [ACTION_EDIT]: {
            href: editPath,
          },
          [ACTION_RESTORE]: {
            action: expect.any(Function),
          },
          [ACTION_DELETE]: {
            action: expect.any(Function),
          },
        },
        availableActions: [ACTION_EDIT, ACTION_RESTORE, ACTION_DELETE],
      });
    });
  });

  describe('when restore action is fired', () => {
    describe('when API call is successful', () => {
      it('calls restoreProject, properly sets loading state, and emits refetch event', async () => {
        restoreProject.mockResolvedValueOnce();

        await restoreProjectAction();
        expect(restoreProject).toHaveBeenCalledWith(projectWithActions.id);

        expect(findListActionsLoadingIcon().exists()).toBe(true);
        expect(findListActions().exists()).toBe(false);

        await waitForPromises();

        expect(findListActionsLoadingIcon().exists()).toBe(false);
        expect(findListActions().exists()).toBe(true);

        expect(wrapper.emitted('refetch')).toEqual([[]]);
        expect(renderRestoreSuccessToast).toHaveBeenCalledWith(projectWithActions, 'Project');
        expect(createAlert).not.toHaveBeenCalled();
      });
    });

    describe('when API call is not successful', () => {
      const error = new Error();

      it('calls restoreProject, properly sets loading state, and shows error alert', async () => {
        restoreProject.mockRejectedValue(error);

        await restoreProjectAction();
        expect(restoreProject).toHaveBeenCalledWith(projectWithActions.id);

        expect(findListActionsLoadingIcon().exists()).toBe(true);
        expect(findListActions().exists()).toBe(false);

        await waitForPromises();

        expect(findListActionsLoadingIcon().exists()).toBe(false);
        expect(findListActions().exists()).toBe(true);

        expect(wrapper.emitted('refetch')).toBeUndefined();
        expect(createAlert).toHaveBeenCalledWith({
          message: 'An error occurred restoring the project. Please refresh the page to try again.',
          error,
          captureError: true,
        });
        expect(renderRestoreSuccessToast).not.toHaveBeenCalled();
      });
    });
  });

  describe('when delete action is fired', () => {
    beforeEach(() => {
      findListActions().props('actions')[ACTION_DELETE].action();
    });

    it('emits delete event', () => {
      expect(wrapper.emitted('delete')).toEqual([[]]);
    });
  });
});
