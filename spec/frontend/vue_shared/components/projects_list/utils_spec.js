import {
  availableGraphQLProjectActions,
  deleteParams,
  renderDeleteSuccessToast,
  renderRestoreSuccessToast,
} from '~/vue_shared/components/projects_list/utils';
import {
  ACTION_EDIT,
  ACTION_RESTORE,
  ACTION_DELETE,
} from '~/vue_shared/components/list_actions/constants';
import toast from '~/vue_shared/plugins/global_toast';

jest.mock('~/vue_shared/plugins/global_toast');

const MOCK_PERSONAL_PROJECT = {
  nameWithNamespace: 'No Delay Project',
  fullPath: 'path/to/project/1',
  isAdjournedDeletionEnabled: false,
  markedForDeletionOn: null,
  permanentDeletionDate: '2024-03-31',
  group: null,
};

const MOCK_PROJECT_DELAY_DELETION_DISABLED = {
  nameWithNamespace: 'No Delay Project',
  fullPath: 'path/to/project/1',
  isAdjournedDeletionEnabled: false,
  markedForDeletionOn: null,
  permanentDeletionDate: '2024-03-31',
  group: {
    id: 'gid://gitlab/Group/1',
  },
};

const MOCK_PROJECT_DELAY_DELETION_ENABLED = {
  nameWithNamespace: 'With Delay Project',
  fullPath: 'path/to/project/2',
  isAdjournedDeletionEnabled: true,
  markedForDeletionOn: null,
  permanentDeletionDate: '2024-03-31',
  group: {
    id: 'gid://gitlab/Group/2',
  },
};

const MOCK_PROJECT_PENDING_DELETION = {
  nameWithNamespace: 'Pending Deletion Project',
  fullPath: 'path/to/project/3',
  isAdjournedDeletionEnabled: true,
  markedForDeletionOn: '2024-03-24',
  permanentDeletionDate: '2024-03-31',
  group: {
    id: 'gid://gitlab/Group/3',
  },
};

describe('availableGraphQLProjectActions', () => {
  describe.each`
    userPermissions                                  | markedForDeletionOn | availableActions
    ${{ viewEditPage: false, removeProject: false }} | ${null}             | ${[]}
    ${{ viewEditPage: true, removeProject: false }}  | ${null}             | ${[ACTION_EDIT]}
    ${{ viewEditPage: false, removeProject: true }}  | ${null}             | ${[ACTION_DELETE]}
    ${{ viewEditPage: true, removeProject: true }}   | ${null}             | ${[ACTION_EDIT, ACTION_DELETE]}
    ${{ viewEditPage: true, removeProject: false }}  | ${'2024-12-31'}     | ${[ACTION_EDIT]}
    ${{ viewEditPage: true, removeProject: true }}   | ${'2024-12-31'}     | ${[ACTION_EDIT, ACTION_RESTORE, ACTION_DELETE]}
  `(
    'availableGraphQLProjectActions',
    ({ userPermissions, markedForDeletionOn, availableActions }) => {
      it(`when userPermissions = ${JSON.stringify(userPermissions)}, markedForDeletionOn is ${markedForDeletionOn}, then availableActions = [${availableActions}] and is sorted correctly`, () => {
        expect(
          availableGraphQLProjectActions({ userPermissions, markedForDeletionOn }),
        ).toStrictEqual(availableActions);
      });
    },
  );
});

describe('renderRestoreSuccessToast', () => {
  it('calls toast correctly', () => {
    renderRestoreSuccessToast(MOCK_PROJECT_PENDING_DELETION);

    expect(toast).toHaveBeenCalledWith(
      `Project '${MOCK_PROJECT_PENDING_DELETION.nameWithNamespace}' has been successfully restored.`,
    );
  });
});

describe('renderDeleteSuccessToast', () => {
  describe('when adjourned deletion is enabled', () => {
    beforeEach(() => {
      renderDeleteSuccessToast(MOCK_PROJECT_DELAY_DELETION_ENABLED);
    });

    it('renders toast explaining project will be delayed deleted', () => {
      expect(toast).toHaveBeenCalledWith(
        `Project '${MOCK_PROJECT_DELAY_DELETION_ENABLED.nameWithNamespace}' will be deleted on ${MOCK_PROJECT_DELAY_DELETION_ENABLED.permanentDeletionDate}.`,
      );
    });
  });

  describe('when adjourned deletion is not enabled', () => {
    beforeEach(() => {
      renderDeleteSuccessToast(MOCK_PROJECT_DELAY_DELETION_DISABLED);
    });

    it('renders toast explaining project is being deleted', () => {
      expect(toast).toHaveBeenCalledWith(
        `Project '${MOCK_PROJECT_DELAY_DELETION_DISABLED.nameWithNamespace}' is being deleted.`,
      );
    });
  });

  describe('when adjourned deletion is available at the global level but not the project level', () => {
    beforeEach(() => {
      window.gon = {
        licensed_features: {
          adjournedDeletionForProjectsAndGroups: true,
        },
      };
      renderDeleteSuccessToast(MOCK_PROJECT_DELAY_DELETION_DISABLED);
    });

    it('renders toast explaining project is deleted and when data will be removed', () => {
      expect(toast).toHaveBeenCalledWith(
        `Deleting project '${MOCK_PROJECT_DELAY_DELETION_DISABLED.nameWithNamespace}'. All data will be removed on ${MOCK_PROJECT_DELAY_DELETION_DISABLED.permanentDeletionDate}.`,
      );
    });
  });

  describe('when project is a personal project', () => {
    beforeEach(() => {
      renderDeleteSuccessToast(MOCK_PERSONAL_PROJECT);
    });

    it('renders toast explaining project is being deleted', () => {
      expect(toast).toHaveBeenCalledWith(
        `Project '${MOCK_PERSONAL_PROJECT.nameWithNamespace}' is being deleted.`,
      );
    });
  });

  describe('when project has already been marked for deletion', () => {
    beforeEach(() => {
      renderDeleteSuccessToast(MOCK_PROJECT_PENDING_DELETION);
    });

    it('renders toast explaining project is being deleted', () => {
      expect(toast).toHaveBeenCalledWith(
        `Project '${MOCK_PROJECT_PENDING_DELETION.nameWithNamespace}' is being deleted.`,
      );
    });
  });
});

describe('deleteParams', () => {
  it('returns empty object', () => {
    expect(deleteParams(MOCK_PROJECT_DELAY_DELETION_ENABLED)).toStrictEqual({});
  });

  describe('when project has already been marked for deletion', () => {
    it('sets permanently_remove param to true and passes full_path param', () => {
      expect(deleteParams(MOCK_PROJECT_PENDING_DELETION)).toStrictEqual({
        permanently_remove: true,
        full_path: MOCK_PROJECT_PENDING_DELETION.fullPath,
      });
    });
  });
});
