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
  markedForDeletionOn: null,
  permanentDeletionDate: '2024-03-31',
};

const MOCK_PROJECT_PENDING_DELETION = {
  ...MOCK_PROJECT,
  markedForDeletionOn: '2024-03-24',
  permanentDeletionDate: '2024-03-31',
};

describe('availableGraphQLProjectActions', () => {
  describe.each`
    userPermissions                                  | markedForDeletionOn | archived | availableActions
    ${{ viewEditPage: false, removeProject: false }} | ${null}             | ${false} | ${[]}
    ${{ viewEditPage: true, removeProject: false }}  | ${null}             | ${false} | ${[ACTION_EDIT]}
    ${{ viewEditPage: false, removeProject: true }}  | ${null}             | ${false} | ${[ACTION_DELETE]}
    ${{ viewEditPage: true, removeProject: true }}   | ${null}             | ${false} | ${[ACTION_EDIT, ACTION_DELETE]}
    ${{ viewEditPage: true, removeProject: false }}  | ${'2024-12-31'}     | ${false} | ${[ACTION_EDIT]}
    ${{ viewEditPage: true, removeProject: true }}   | ${'2024-12-31'}     | ${false} | ${[ACTION_EDIT, ACTION_RESTORE, ACTION_DELETE]}
    ${{ archiveProject: true }}                      | ${null}             | ${false} | ${[ACTION_ARCHIVE]}
    ${{ archiveProject: true }}                      | ${null}             | ${true}  | ${[ACTION_UNARCHIVE]}
    ${{ archiveProject: false }}                     | ${null}             | ${false} | ${[]}
    ${{ archiveProject: false }}                     | ${null}             | ${true}  | ${[]}
  `(
    'availableGraphQLProjectActions',
    ({ userPermissions, markedForDeletionOn, archived, availableActions }) => {
      it(`when userPermissions = ${JSON.stringify(userPermissions)}, markedForDeletionOn is ${markedForDeletionOn}, and archived is ${archived} then availableActions = [${availableActions}] and is sorted correctly`, () => {
        expect(
          availableGraphQLProjectActions({ userPermissions, markedForDeletionOn, archived }),
        ).toStrictEqual(availableActions);
      });
    },
  );
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
