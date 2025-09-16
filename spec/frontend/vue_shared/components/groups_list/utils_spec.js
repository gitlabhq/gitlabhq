import {
  deleteParams,
  renderDeleteSuccessToast,
  renderLeaveSuccessToast,
  renderRestoreSuccessToast,
  availableGraphQLGroupActions,
  renderArchiveSuccessToast,
  renderUnarchiveSuccessToast,
} from '~/vue_shared/components/groups_list/utils';
import {
  ACTION_EDIT,
  ACTION_ARCHIVE,
  ACTION_UNARCHIVE,
  ACTION_RESTORE,
  ACTION_DELETE,
  ACTION_LEAVE,
  ACTION_DELETE_IMMEDIATELY,
} from '~/vue_shared/components/list_actions/constants';
import toast from '~/vue_shared/plugins/global_toast';

jest.mock('~/vue_shared/plugins/global_toast');

const MOCK_GROUP = {
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
  beforeEach(() => {
    window.gon = {
      features: {
        disallowImmediateDeletion: false,
      },
    };
  });

  describe.each`
    userPermissions                                              | markedForDeletion | isSelfDeletionInProgress | isSelfDeletionScheduled | archived | features                   | availableActions
    ${{ viewEditPage: false, removeGroup: false }}               | ${false}          | ${false}                 | ${false}                | ${false} | ${{}}                      | ${[]}
    ${{ viewEditPage: true, removeGroup: false }}                | ${false}          | ${false}                 | ${false}                | ${false} | ${{}}                      | ${[ACTION_EDIT]}
    ${{ viewEditPage: false, removeGroup: true }}                | ${false}          | ${false}                 | ${false}                | ${false} | ${{}}                      | ${[ACTION_DELETE]}
    ${{ viewEditPage: true, removeGroup: true }}                 | ${false}          | ${false}                 | ${false}                | ${false} | ${{}}                      | ${[ACTION_EDIT, ACTION_DELETE]}
    ${{ viewEditPage: true, removeGroup: false }}                | ${true}           | ${false}                 | ${false}                | ${false} | ${{}}                      | ${[ACTION_EDIT]}
    ${{ viewEditPage: true, removeGroup: true }}                 | ${true}           | ${false}                 | ${false}                | ${false} | ${{}}                      | ${[ACTION_EDIT]}
    ${{ viewEditPage: true, removeGroup: true }}                 | ${true}           | ${false}                 | ${true}                 | ${false} | ${{}}                      | ${[ACTION_EDIT, ACTION_RESTORE, ACTION_DELETE_IMMEDIATELY]}
    ${{ viewEditPage: true, removeGroup: true, canLeave: true }} | ${true}           | ${false}                 | ${false}                | ${false} | ${{}}                      | ${[ACTION_EDIT, ACTION_LEAVE]}
    ${{ viewEditPage: true, removeGroup: true, canLeave: true }} | ${true}           | ${false}                 | ${true}                 | ${false} | ${{}}                      | ${[ACTION_EDIT, ACTION_RESTORE, ACTION_LEAVE, ACTION_DELETE_IMMEDIATELY]}
    ${{ viewEditPage: true, removeGroup: true }}                 | ${true}           | ${true}                  | ${false}                | ${false} | ${{}}                      | ${[]}
    ${{ viewEditPage: true, removeGroup: true }}                 | ${true}           | ${true}                  | ${true}                 | ${false} | ${{}}                      | ${[]}
    ${{ archiveGroup: true }}                                    | ${false}          | ${false}                 | ${false}                | ${false} | ${{ archiveGroup: true }}  | ${[ACTION_ARCHIVE]}
    ${{ archiveGroup: true }}                                    | ${false}          | ${false}                 | ${false}                | ${true}  | ${{ archiveGroup: true }}  | ${[ACTION_UNARCHIVE]}
    ${{ archiveGroup: false }}                                   | ${false}          | ${false}                 | ${false}                | ${false} | ${{ archiveGroup: true }}  | ${[]}
    ${{ archiveGroup: false }}                                   | ${false}          | ${false}                 | ${false}                | ${true}  | ${{ archiveGroup: true }}  | ${[]}
    ${{ archiveGroup: true }}                                    | ${false}          | ${false}                 | ${false}                | ${false} | ${{ archiveGroup: false }} | ${[]}
    ${{ archiveGroup: true }}                                    | ${false}          | ${false}                 | ${false}                | ${true}  | ${{ archiveGroup: false }} | ${[ACTION_UNARCHIVE]}
    ${{ archiveGroup: false }}                                   | ${false}          | ${false}                 | ${false}                | ${false} | ${{ archiveGroup: false }} | ${[]}
    ${{ archiveGroup: false }}                                   | ${false}          | ${false}                 | ${false}                | ${true}  | ${{ archiveGroup: false }} | ${[]}
  `(
    'availableGraphQLGroupActions',
    ({
      userPermissions,
      markedForDeletion,
      isSelfDeletionInProgress,
      isSelfDeletionScheduled,
      archived,
      features,
      availableActions,
    }) => {
      beforeEach(() => {
        window.gon.features = features;
      });

      it(`when userPermissions = ${JSON.stringify(userPermissions)}, markedForDeletion is ${markedForDeletion}, isSelfDeletionInProgress is ${isSelfDeletionInProgress}, isSelfDeletionScheduled is ${isSelfDeletionScheduled}, and archived is ${archived} then availableActions = [${availableActions}] and is sorted correctly`, () => {
        expect(
          availableGraphQLGroupActions({
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
        availableGraphQLGroupActions({
          userPermissions: { viewEditPage: true, removeGroup: true },
          markedForDeletion: true,
          isSelfDeletionInProgress: false,
          isSelfDeletionScheduled: true,
        }),
      ).toStrictEqual([ACTION_EDIT, ACTION_RESTORE]);
    });

    describe('when userPermissions include adminAllResources', () => {
      it('allows deleting immediately', () => {
        expect(
          availableGraphQLGroupActions({
            userPermissions: { removeGroup: true, adminAllResources: true },
            markedForDeletion: true,
            isSelfDeletionInProgress: false,
            isSelfDeletionScheduled: true,
          }),
        ).toStrictEqual([ACTION_RESTORE, ACTION_DELETE_IMMEDIATELY]);
      });
    });
  });
});

describe('renderDeleteSuccessToast', () => {
  it('when delayed deletion is enabled and group is not pending deletion, calls toast with pending deletion info', () => {
    renderDeleteSuccessToast(MOCK_GROUP_WITH_DELAY_DELETION);

    expect(toast).toHaveBeenCalledWith(
      `Group '${MOCK_GROUP_WITH_DELAY_DELETION.fullName}' will be deleted on ${MOCK_GROUP_WITH_DELAY_DELETION.permanentDeletionDate}.`,
    );
  });

  it('when delayed deletion is enabled and group is already pending deletion, renders the delete immediately message', () => {
    renderDeleteSuccessToast(MOCK_GROUP_PENDING_DELETION);

    expect(toast).toHaveBeenCalledWith(
      `Group '${MOCK_GROUP_PENDING_DELETION.fullName}' is being deleted.`,
    );
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
