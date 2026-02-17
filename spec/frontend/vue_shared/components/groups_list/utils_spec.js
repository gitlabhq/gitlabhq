import {
  availableGraphQLGroupActions,
  deleteParams,
  renderArchiveSuccessToast,
  renderDeleteSuccessToast,
  renderLeaveSuccessToast,
  renderRestoreSuccessToast,
  renderUnarchiveSuccessToast,
} from '~/vue_shared/components/groups_list/utils';
import {
  ACTION_ARCHIVE,
  ACTION_COPY_ID,
  ACTION_DELETE,
  ACTION_DELETE_IMMEDIATELY,
  ACTION_EDIT,
  ACTION_LEAVE,
  ACTION_RESTORE,
  ACTION_UNARCHIVE,
} from '~/vue_shared/components/list_actions/constants';
import toast from '~/vue_shared/plugins/global_toast';

jest.mock('~/vue_shared/plugins/global_toast');

const MOCK_GROUP = {
  name: 'Group',
  fullName: 'Group',
  fullPath: 'path/to/group',
};

const MOCK_GROUP_WITH_DELAY_DELETION = {
  ...MOCK_GROUP,
  markedForDeletion: false,
  isSelfDeletionScheduled: false,
  permanentDeletionDate: '2024-03-31',
};

const MOCK_GROUP_PENDING_DELETION = {
  ...MOCK_GROUP,
  markedForDeletion: true,
  isSelfDeletionScheduled: true,
  permanentDeletionDate: '2024-03-31',
};

afterEach(() => {
  window.gon = {};
});

describe('availableGraphQLGroupActions', () => {
  describe('when user has viewEditPage permission', () => {
    it('includes edit action', () => {
      const availableActions = availableGraphQLGroupActions({
        userPermissions: { viewEditPage: true },
      });

      expect(availableActions).toContain(ACTION_EDIT);
    });
  });

  describe('when user has no viewEditPage permission', () => {
    it('does not include edit action', () => {
      const availableActions = availableGraphQLGroupActions({
        userPermissions: { viewEditPage: false },
      });

      expect(availableActions).not.toContain(ACTION_EDIT);
    });
  });

  describe('when user has archiveGroup permission', () => {
    describe.each`
      description                             | archived | isSelfArchived | markedForDeletion | expectedActions
      ${'group is not archived'}              | ${false} | ${false}       | ${false}          | ${[ACTION_COPY_ID, ACTION_ARCHIVE]}
      ${'group is archived'}                  | ${true}  | ${true}        | ${false}          | ${[ACTION_COPY_ID, ACTION_UNARCHIVE]}
      ${'group belongs to an archived group'} | ${true}  | ${false}       | ${false}          | ${[ACTION_COPY_ID]}
      ${'group is scheduled for deletion'}    | ${false} | ${false}       | ${true}           | ${[ACTION_COPY_ID]}
    `('when $description', ({ archived, isSelfArchived, markedForDeletion, expectedActions }) => {
      it('returns expected actions', () => {
        const availableActions = availableGraphQLGroupActions({
          userPermissions: { archiveGroup: true },
          archived,
          isSelfArchived,
          markedForDeletion,
        });

        expect(availableActions).toStrictEqual(expectedActions);
      });
    });
  });

  describe('when user has no archiveGroup permission', () => {
    it('does not include archive nor unarchive action', () => {
      const availableActions = availableGraphQLGroupActions({
        userPermissions: { archiveGroup: false },
      });

      expect(availableActions).toStrictEqual([ACTION_COPY_ID]);
    });
  });

  describe('when user has removeGroup permission', () => {
    describe.each`
      description                           | markedForDeletion | isSelfDeletionScheduled | isSelfDeletionInProgress | expectedActions
      ${'group is not marked for deletion'} | ${false}          | ${false}                | ${false}                 | ${[ACTION_COPY_ID, ACTION_DELETE]}
      ${'group is scheduled for deletion'}  | ${true}           | ${true}                 | ${false}                 | ${[ACTION_COPY_ID, ACTION_RESTORE, ACTION_DELETE_IMMEDIATELY]}
      ${'group belongs to a deleted group'} | ${true}           | ${false}                | ${false}                 | ${[ACTION_COPY_ID]}
      ${'group deletion is in progress'}    | ${true}           | ${true}                 | ${true}                  | ${[]}
    `(
      'when $description',
      ({
        markedForDeletion,
        isSelfDeletionScheduled,
        isSelfDeletionInProgress,
        expectedActions,
      }) => {
        it('returns expected actions', () => {
          const availableActions = availableGraphQLGroupActions({
            userPermissions: { removeGroup: true },
            markedForDeletion,
            isSelfDeletionInProgress,
            isSelfDeletionScheduled,
          });

          expect(availableActions).toStrictEqual(expectedActions);
        });
      },
    );
  });

  describe('when user has no removeGroup permission', () => {
    it('does not include delete actions', () => {
      const availableActions = availableGraphQLGroupActions({
        userPermissions: { removeGroup: false },
      });

      expect(availableActions).toStrictEqual([ACTION_COPY_ID]);
    });
  });

  describe('when user has canLeave permission', () => {
    it('includes leave action', () => {
      const availableActions = availableGraphQLGroupActions({
        userPermissions: { canLeave: true },
      });

      expect(availableActions).toContain(ACTION_LEAVE);
    });
  });

  describe('when user has no canLeave permission', () => {
    it('does not include leave', () => {
      const availableActions = availableGraphQLGroupActions({
        userPermissions: { canLeave: false },
      });

      expect(availableActions).not.toContain(ACTION_LEAVE);
    });
  });
});

describe('renderDeleteSuccessToast', () => {
  it('when delayed deletion is enabled and group is not pending deletion, calls toast with pending deletion info', () => {
    renderDeleteSuccessToast(MOCK_GROUP_WITH_DELAY_DELETION);

    expect(toast).toHaveBeenCalledWith(
      `${MOCK_GROUP_WITH_DELAY_DELETION.name} moved to pending deletion.`,
    );
  });

  it('when delayed deletion is enabled and group is already pending deletion, renders the delete permanently message', () => {
    renderDeleteSuccessToast(MOCK_GROUP_PENDING_DELETION);

    expect(toast).toHaveBeenCalledWith(`${MOCK_GROUP_PENDING_DELETION.name} is being deleted.`);
  });
});

describe('renderLeaveSuccessToast', () => {
  it('calls toast correctly', () => {
    renderLeaveSuccessToast(MOCK_GROUP);

    expect(toast).toHaveBeenCalledWith(`You left the "${MOCK_GROUP.fullName}" group.`);
  });
});

describe('renderRestoreSuccessToast', () => {
  it('calls toast correctly', () => {
    renderRestoreSuccessToast(MOCK_GROUP);

    expect(toast).toHaveBeenCalledWith(
      `Group '${MOCK_GROUP.fullName}' has been successfully restored.`,
    );
  });
});

describe('renderArchiveSuccessToast', () => {
  it('calls toast correctly', () => {
    renderArchiveSuccessToast(MOCK_GROUP);

    expect(toast).toHaveBeenCalledWith(
      `Group '${MOCK_GROUP.fullName}' has been successfully archived.`,
    );
  });
});

describe('renderUnarchiveSuccessToast', () => {
  it('calls toast correctly', () => {
    renderUnarchiveSuccessToast(MOCK_GROUP);

    expect(toast).toHaveBeenCalledWith(
      `Group '${MOCK_GROUP.fullName}' has been successfully unarchived.`,
    );
  });
});

describe('deleteParams', () => {
  it('when delayed deletion is enabled and group is not pending deletion, returns an empty object', () => {
    const res = deleteParams(MOCK_GROUP_WITH_DELAY_DELETION);

    expect(res).toStrictEqual({});
  });

  it('when delayed deletion is enabled and group is already pending deletion, returns permanent deletion params', () => {
    const res = deleteParams(MOCK_GROUP_PENDING_DELETION);

    expect(res).toStrictEqual({
      permanently_remove: true,
    });
  });
});
