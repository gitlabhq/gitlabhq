import {
  deleteParams,
  renderDeleteSuccessToast,
  renderLeaveSuccessToast,
  renderRestoreSuccessToast,
  availableGraphQLGroupActions,
} from '~/vue_shared/components/groups_list/utils';
import {
  ACTION_EDIT,
  ACTION_RESTORE,
  ACTION_DELETE,
  ACTION_LEAVE,
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
  permanentDeletionDate: '2024-03-31',
};

const MOCK_GROUP_PENDING_DELETION = {
  ...MOCK_GROUP,
  markedForDeletion: true,
  permanentDeletionDate: '2024-03-31',
};

describe('availableGraphQLGroupActions', () => {
  describe.each`
    userPermissions                                              | markedForDeletion | isSelfDeletionInProgress | availableActions
    ${{ viewEditPage: false, removeGroup: false }}               | ${false}          | ${false}                 | ${[]}
    ${{ viewEditPage: true, removeGroup: false }}                | ${false}          | ${false}                 | ${[ACTION_EDIT]}
    ${{ viewEditPage: false, removeGroup: true }}                | ${false}          | ${false}                 | ${[ACTION_DELETE]}
    ${{ viewEditPage: true, removeGroup: true }}                 | ${false}          | ${false}                 | ${[ACTION_EDIT, ACTION_DELETE]}
    ${{ viewEditPage: true, removeGroup: false }}                | ${true}           | ${false}                 | ${[ACTION_EDIT]}
    ${{ viewEditPage: true, removeGroup: true }}                 | ${true}           | ${false}                 | ${[ACTION_EDIT, ACTION_RESTORE, ACTION_DELETE]}
    ${{ viewEditPage: true, removeGroup: true, canLeave: true }} | ${true}           | ${false}                 | ${[ACTION_EDIT, ACTION_RESTORE, ACTION_LEAVE, ACTION_DELETE]}
    ${{ viewEditPage: true, removeGroup: true }}                 | ${true}           | ${true}                  | ${[ACTION_EDIT]}
  `(
    'availableGraphQLGroupActions',
    ({ userPermissions, markedForDeletion, isSelfDeletionInProgress, availableActions }) => {
      it(`when userPermissions = ${JSON.stringify(userPermissions)}, markedForDeletion is ${markedForDeletion}, then availableActions = [${availableActions}] and is sorted correctly`, () => {
        expect(
          availableGraphQLGroupActions({
            userPermissions,
            markedForDeletion,
            isSelfDeletionInProgress,
          }),
        ).toStrictEqual(availableActions);
      });
    },
  );
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
