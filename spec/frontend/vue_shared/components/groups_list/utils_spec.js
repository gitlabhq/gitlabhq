import { deleteParams, renderDeleteSuccessToast } from '~/vue_shared/components/groups_list/utils';
import toast from '~/vue_shared/plugins/global_toast';

jest.mock('~/vue_shared/plugins/global_toast');

const MOCK_GROUP_NO_DELAY_DELETION = {
  fullName: 'No Delay Group',
  fullPath: 'path/to/group/1',
  isAdjournedDeletionEnabled: false,
  markedForDeletionOn: null,
  permanentDeletionDate: null,
};

const MOCK_GROUP_WITH_DELAY_DELETION = {
  fullName: 'With Delay Group',
  fullPath: 'path/to/group/2',
  isAdjournedDeletionEnabled: true,
  markedForDeletionOn: null,
  permanentDeletionDate: '2024-03-31',
};

const MOCK_GROUP_PENDING_DELETION = {
  fullName: 'Pending Deletion Group',
  fullPath: 'path/to/group/3',
  isAdjournedDeletionEnabled: true,
  markedForDeletionOn: '2024-03-24',
  permanentDeletionDate: '2024-03-31',
};

describe('renderDeleteSuccessToast', () => {
  it('when delayed deletion is disabled, renders the delete immediately message', () => {
    renderDeleteSuccessToast(MOCK_GROUP_NO_DELAY_DELETION);

    expect(toast).toHaveBeenCalledWith(
      `Group '${MOCK_GROUP_NO_DELAY_DELETION.fullName}' is being deleted.`,
    );
  });

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

describe('deleteParams', () => {
  it('when delayed deletion is disabled, returns an empty object', () => {
    const res = deleteParams(MOCK_GROUP_NO_DELAY_DELETION);

    expect(res).toStrictEqual({});
  });

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
