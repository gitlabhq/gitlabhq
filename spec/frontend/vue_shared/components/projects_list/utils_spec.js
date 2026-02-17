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
  ACTION_COPY_ID,
  ACTION_DELETE,
  ACTION_DELETE_IMMEDIATELY,
  ACTION_EDIT,
  ACTION_RESTORE,
  ACTION_UNARCHIVE,
} from '~/vue_shared/components/list_actions/constants';
import toast from '~/vue_shared/plugins/global_toast';

jest.mock('~/vue_shared/plugins/global_toast');

const MOCK_PROJECT = {
  name: 'With Delay Project',
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
  describe('when user has viewEditPage permission', () => {
    it('includes edit action', () => {
      const availableActions = availableGraphQLProjectActions({
        userPermissions: { viewEditPage: true },
      });

      expect(availableActions).toContain(ACTION_EDIT);
    });
  });

  describe('when user has no viewEditPage permission', () => {
    it('does not include edit action', () => {
      const availableActions = availableGraphQLProjectActions({
        userPermissions: { viewEditPage: false },
      });

      expect(availableActions).not.toContain(ACTION_EDIT);
    });
  });

  describe('when user has no archiveProject permission', () => {
    it('does not include archive nor unarchive action', () => {
      const availableActions = availableGraphQLProjectActions({
        userPermissions: { archiveProject: false },
      });

      expect(availableActions).toStrictEqual([ACTION_COPY_ID]);
    });
  });

  describe('when user has archiveProject permission', () => {
    describe.each`
      description                               | archived | isSelfArchived | markedForDeletion | expectedActions
      ${'project is not archived'}              | ${false} | ${false}       | ${false}          | ${[ACTION_COPY_ID, ACTION_ARCHIVE]}
      ${'project is archived'}                  | ${true}  | ${true}        | ${false}          | ${[ACTION_COPY_ID, ACTION_UNARCHIVE]}
      ${'project belongs to an archived group'} | ${true}  | ${false}       | ${false}          | ${[ACTION_COPY_ID]}
      ${'project is marked for deletion'}       | ${false} | ${false}       | ${true}           | ${[ACTION_COPY_ID]}
    `('when $description', ({ archived, isSelfArchived, markedForDeletion, expectedActions }) => {
      it('returns expected actions', () => {
        const availableActions = availableGraphQLProjectActions({
          userPermissions: { archiveProject: true },
          archived,
          isSelfArchived,
          markedForDeletion,
        });

        expect(availableActions).toStrictEqual(expectedActions);
      });
    });
  });

  describe('when user has no removeProject permission', () => {
    it('does not include delete actions', () => {
      const availableActions = availableGraphQLProjectActions({
        userPermissions: { removeProject: false },
      });

      expect(availableActions).toStrictEqual([ACTION_COPY_ID]);
    });
  });

  describe('when user has removeProject permission', () => {
    describe.each`
      description                             | markedForDeletion | isSelfDeletionScheduled | isSelfDeletionInProgress | expectedActions
      ${'project is not marked for deletion'} | ${false}          | ${false}                | ${false}                 | ${[ACTION_COPY_ID, ACTION_DELETE]}
      ${'project is scheduled for deletion'}  | ${true}           | ${true}                 | ${false}                 | ${[ACTION_COPY_ID, ACTION_RESTORE, ACTION_DELETE_IMMEDIATELY]}
      ${'project belongs to a deleted group'} | ${true}           | ${false}                | ${false}                 | ${[ACTION_COPY_ID]}
      ${'project deletion is in progress'}    | ${true}           | ${true}                 | ${true}                  | ${[]}
    `(
      'when $description',
      ({
        markedForDeletion,
        isSelfDeletionScheduled,
        isSelfDeletionInProgress,
        expectedActions,
      }) => {
        it('returns expected actions', () => {
          const availableActions = availableGraphQLProjectActions({
            userPermissions: { removeProject: true },
            markedForDeletion,
            isSelfDeletionInProgress,
            isSelfDeletionScheduled,
          });

          expect(availableActions).toStrictEqual(expectedActions);
        });
      },
    );
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
        `${MOCK_PROJECT_DELAY_DELETION_ENABLED.name} moved to pending deletion.`,
      );
    });
  });

  describe('when project has already been marked for deletion', () => {
    beforeEach(() => {
      renderDeleteSuccessToast(MOCK_PROJECT_PENDING_DELETION);
    });

    it('renders toast explaining project is being deleted', () => {
      expect(toast).toHaveBeenCalledWith(`${MOCK_PROJECT_PENDING_DELETION.name} is being deleted.`);
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
