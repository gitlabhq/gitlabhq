import {
  availableGraphQLProjectActions,
  deleteParams,
  renderArchiveSuccessToast,
  renderDeleteSuccessToast,
  renderRestoreSuccessToast,
  renderUnarchiveSuccessToast,
} from '~/vue_shared/components/projects_list/utils';
import {
  ACTION_ARCHIVE,
  ACTION_DELETE,
  ACTION_EDIT,
  ACTION_RESTORE,
  ACTION_UNARCHIVE,
} from '~/vue_shared/components/list_actions/constants';
import toast from '~/vue_shared/plugins/global_toast';

jest.mock('~/vue_shared/plugins/global_toast');

const MOCK_PROJECT = {
  nameWithNamespace: 'With Delay Project',
  fullPath: 'path/to/project/2',
  group: {
    id: 'gid://gitlab/Group/2',
  },
};

const MOCK_PROJECT_DELAY_DELETION_ENABLED = {
  ...MOCK_PROJECT,
  markedForDeletion: false,
  isSelfDeletionScheduled: false,
  permanentDeletionDate: '2024-03-31',
};

const MOCK_PROJECT_PENDING_DELETION = {
  ...MOCK_PROJECT,
  markedForDeletion: true,
  isSelfDeletionScheduled: true,
  permanentDeletionDate: '2024-03-31',
};

describe('availableGraphQLProjectActions', () => {
  beforeEach(() => {
    window.gon = {
      features: {
        disallowImmediateDeletion: false,
      },
    };
  });

  describe.each`
    userPermissions                                  | markedForDeletion | isSelfDeletionInProgress | isSelfDeletionScheduled | archived | availableActions
    ${{ viewEditPage: false, removeProject: false }} | ${false}          | ${false}                 | ${false}                | ${false} | ${[]}
    ${{ viewEditPage: true, removeProject: false }}  | ${false}          | ${false}                 | ${false}                | ${false} | ${[ACTION_EDIT]}
    ${{ viewEditPage: false, removeProject: true }}  | ${false}          | ${false}                 | ${false}                | ${false} | ${[ACTION_DELETE]}
    ${{ viewEditPage: true, removeProject: true }}   | ${false}          | ${false}                 | ${false}                | ${false} | ${[ACTION_EDIT, ACTION_DELETE]}
    ${{ viewEditPage: true, removeProject: false }}  | ${true}           | ${false}                 | ${false}                | ${false} | ${[ACTION_EDIT]}
    ${{ viewEditPage: true, removeProject: true }}   | ${true}           | ${false}                 | ${false}                | ${false} | ${[ACTION_EDIT]}
    ${{ viewEditPage: true, removeProject: true }}   | ${true}           | ${false}                 | ${true}                 | ${false} | ${[ACTION_EDIT, ACTION_RESTORE, ACTION_DELETE]}
    ${{ viewEditPage: true, removeProject: true }}   | ${true}           | ${false}                 | ${false}                | ${false} | ${[ACTION_EDIT]}
    ${{ viewEditPage: true, removeProject: true }}   | ${true}           | ${false}                 | ${true}                 | ${false} | ${[ACTION_EDIT, ACTION_RESTORE, ACTION_DELETE]}
    ${{ viewEditPage: true, removeProject: true }}   | ${true}           | ${true}                  | ${false}                | ${false} | ${[]}
    ${{ viewEditPage: true, removeProject: true }}   | ${true}           | ${true}                  | ${true}                 | ${false} | ${[]}
    ${{ archiveProject: true }}                      | ${false}          | ${false}                 | ${false}                | ${false} | ${[ACTION_ARCHIVE]}
    ${{ archiveProject: true }}                      | ${false}          | ${false}                 | ${false}                | ${true}  | ${[ACTION_UNARCHIVE]}
    ${{ archiveProject: false }}                     | ${false}          | ${false}                 | ${false}                | ${false} | ${[]}
    ${{ archiveProject: false }}                     | ${false}          | ${false}                 | ${false}                | ${true}  | ${[]}
  `(
    'availableGraphQLProjectActions',
    ({
      userPermissions,
      markedForDeletion,
      isSelfDeletionInProgress,
      isSelfDeletionScheduled,
      archived,
      availableActions,
    }) => {
      it(`when userPermissions = ${JSON.stringify(userPermissions)}, markedForDeletion is ${markedForDeletion}, isSelfDeletionInProgress is ${isSelfDeletionInProgress}, isSelfDeletionScheduled is ${isSelfDeletionScheduled}, and  archived is ${archived} then availableActions = [${availableActions}] and is sorted correctly`, () => {
        expect(
          availableGraphQLProjectActions({
            userPermissions,
            markedForDeletion,
            isSelfDeletionInProgress,
            isSelfDeletionScheduled,
            archived,
          }),
        ).toStrictEqual(availableActions);
      });
    },
  );

  describe('when disallowImmediateDeletion feature flag is enabled', () => {
    beforeEach(() => {
      window.gon = {
        features: {
          disallowImmediateDeletion: true,
        },
      };
    });

    it('does not allow deleting immediately', () => {
      expect(
        availableGraphQLProjectActions({
          userPermissions: { viewEditPage: true, removeProject: true },
          markedForDeletion: true,
          isSelfDeletionInProgress: false,
          isSelfDeletionScheduled: true,
        }),
      ).toStrictEqual([ACTION_EDIT, ACTION_RESTORE]);
    });

    describe('when userPermissions include adminAllResources', () => {
      it('allows deleting immediately', () => {
        expect(
          availableGraphQLProjectActions({
            userPermissions: { removeProject: true, adminAllResources: true },
            markedForDeletion: true,
            isSelfDeletionInProgress: false,
            isSelfDeletionScheduled: true,
          }),
        ).toStrictEqual([ACTION_RESTORE, ACTION_DELETE]);
      });
    });
  });
});

describe('renderArchiveSuccessToast', () => {
  it('calls toast correctly', () => {
    renderArchiveSuccessToast(MOCK_PROJECT);

    expect(toast).toHaveBeenCalledWith(
      `Project '${MOCK_PROJECT.nameWithNamespace}' has been successfully archived.`,
    );
  });
});

describe('renderUnarchiveSuccessToast', () => {
  it('calls toast correctly', () => {
    renderUnarchiveSuccessToast(MOCK_PROJECT);

    expect(toast).toHaveBeenCalledWith(
      `Project '${MOCK_PROJECT.nameWithNamespace}' has been successfully unarchived.`,
    );
  });
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
