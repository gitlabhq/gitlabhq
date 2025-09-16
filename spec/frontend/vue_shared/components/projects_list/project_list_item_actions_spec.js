import { nextTick } from 'vue';
import { GlLoadingIcon } from '@gitlab/ui';
import projects from 'test_fixtures/api/users/projects/get.json';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import {
  renderArchiveSuccessToast,
  renderUnarchiveSuccessToast,
  renderRestoreSuccessToast,
} from '~/vue_shared/components/projects_list/utils';
import { archiveProject, unarchiveProject, restoreProject } from '~/rest_api';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import ListActions from '~/vue_shared/components/list_actions/list_actions.vue';
import ProjectListItemActions from '~/vue_shared/components/projects_list/project_list_item_actions.vue';
import {
  ACTION_EDIT,
  ACTION_RESTORE,
  ACTION_DELETE,
  ACTION_ARCHIVE,
  ACTION_UNARCHIVE,
} from '~/vue_shared/components/list_actions/constants';
import { createAlert } from '~/alert';
import { useMockInternalEventsTracking } from 'helpers/tracking_internal_events_helper';
import { RESOURCE_TYPES } from '~/groups_projects/constants';

jest.mock('~/vue_shared/components/projects_list/utils', () => ({
  ...jest.requireActual('~/vue_shared/components/projects_list/utils'),
  renderRestoreSuccessToast: jest.fn(),
  renderArchiveSuccessToast: jest.fn(),
  renderUnarchiveSuccessToast: jest.fn(),
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
  const fireAction = async (action) => {
    findListActions().props('actions')[action].action();
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
          [ACTION_ARCHIVE]: {
            action: expect.any(Function),
          },
          [ACTION_UNARCHIVE]: {
            action: expect.any(Function),
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

  describe('when archive action is fired', () => {
    const { bindInternalEventDocument } = useMockInternalEventsTracking();

    it('should call trackEvent method', async () => {
      const { trackEventSpy } = bindInternalEventDocument(wrapper.element);

      await fireAction(ACTION_ARCHIVE);
      await waitForPromises();

      expect(trackEventSpy).toHaveBeenCalledWith(
        'archive_namespace_in_quick_action',
        {
          label: RESOURCE_TYPES.PROJECT,
          property: 'archive',
        },
        undefined,
      );
    });

    describe('when API call is successful', () => {
      it('calls archiveProject, properly sets loading state, and emits refetch event', async () => {
        archiveProject.mockResolvedValueOnce();

        await fireAction(ACTION_ARCHIVE);
        expect(archiveProject).toHaveBeenCalledWith(projectWithActions.id);

        expect(findListActionsLoadingIcon().exists()).toBe(true);
        expect(findListActions().exists()).toBe(false);

        await waitForPromises();

        expect(findListActionsLoadingIcon().exists()).toBe(false);
        expect(findListActions().exists()).toBe(true);

        expect(wrapper.emitted('refetch')).toEqual([[]]);
        expect(renderArchiveSuccessToast).toHaveBeenCalledWith(projectWithActions);
        expect(createAlert).not.toHaveBeenCalled();
      });
    });

    describe('when API call is not successful', () => {
      const error = new Error();

      it('calls archiveProject, properly sets loading state, and shows error alert', async () => {
        archiveProject.mockRejectedValue(error);

        await fireAction(ACTION_ARCHIVE);
        expect(archiveProject).toHaveBeenCalledWith(projectWithActions.id);

        expect(findListActionsLoadingIcon().exists()).toBe(true);
        expect(findListActions().exists()).toBe(false);

        await waitForPromises();

        expect(findListActionsLoadingIcon().exists()).toBe(false);
        expect(findListActions().exists()).toBe(true);

        expect(wrapper.emitted('refetch')).toBeUndefined();
        expect(createAlert).toHaveBeenCalledWith({
          message: 'An error occurred archiving the project. Please refresh the page to try again.',
          error,
          captureError: true,
        });
        expect(renderArchiveSuccessToast).not.toHaveBeenCalled();
      });
    });
  });

  describe('when unarchive action is fired', () => {
    const { bindInternalEventDocument } = useMockInternalEventsTracking();

    it('should call trackEvent method', async () => {
      const { trackEventSpy } = bindInternalEventDocument(wrapper.element);

      await fireAction(ACTION_UNARCHIVE);
      await waitForPromises();

      expect(trackEventSpy).toHaveBeenCalledWith(
        'archive_namespace_in_quick_action',
        {
          label: RESOURCE_TYPES.PROJECT,
          property: 'unarchive',
        },
        undefined,
      );
    });

    describe('when API call is successful', () => {
      it('calls unarchiveProject, properly sets loading state, and emits refetch event', async () => {
        unarchiveProject.mockResolvedValueOnce();

        await fireAction(ACTION_UNARCHIVE);
        expect(unarchiveProject).toHaveBeenCalledWith(projectWithActions.id);

        expect(findListActionsLoadingIcon().exists()).toBe(true);
        expect(findListActions().exists()).toBe(false);

        await waitForPromises();

        expect(findListActionsLoadingIcon().exists()).toBe(false);
        expect(findListActions().exists()).toBe(true);

        expect(wrapper.emitted('refetch')).toEqual([[]]);
        expect(renderUnarchiveSuccessToast).toHaveBeenCalledWith(projectWithActions);
        expect(createAlert).not.toHaveBeenCalled();
      });
    });

    describe('when API call is not successful', () => {
      const error = new Error();

      it('calls unarchiveProject, properly sets loading state, and shows error alert', async () => {
        unarchiveProject.mockRejectedValue(error);

        await fireAction(ACTION_UNARCHIVE);
        expect(unarchiveProject).toHaveBeenCalledWith(projectWithActions.id);

        expect(findListActionsLoadingIcon().exists()).toBe(true);
        expect(findListActions().exists()).toBe(false);

        await waitForPromises();

        expect(findListActionsLoadingIcon().exists()).toBe(false);
        expect(findListActions().exists()).toBe(true);

        expect(wrapper.emitted('refetch')).toBeUndefined();
        expect(createAlert).toHaveBeenCalledWith({
          message:
            'An error occurred unarchiving the project. Please refresh the page to try again.',
          error,
          captureError: true,
        });
        expect(renderUnarchiveSuccessToast).not.toHaveBeenCalled();
      });
    });
  });

  describe('when restore action is fired', () => {
    describe('when API call is successful', () => {
      it('calls restoreProject, properly sets loading state, and emits refetch event', async () => {
        restoreProject.mockResolvedValueOnce();

        await fireAction(ACTION_RESTORE);
        expect(restoreProject).toHaveBeenCalledWith(projectWithActions.id);

        expect(findListActionsLoadingIcon().exists()).toBe(true);
        expect(findListActions().exists()).toBe(false);

        await waitForPromises();

        expect(findListActionsLoadingIcon().exists()).toBe(false);
        expect(findListActions().exists()).toBe(true);

        expect(wrapper.emitted('refetch')).toEqual([[]]);
        expect(renderRestoreSuccessToast).toHaveBeenCalledWith(projectWithActions);
        expect(createAlert).not.toHaveBeenCalled();
      });
    });

    describe('when API call is not successful', () => {
      const error = new Error();

      it('calls restoreProject, properly sets loading state, and shows error alert', async () => {
        restoreProject.mockRejectedValue(error);

        await fireAction(ACTION_RESTORE);
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
