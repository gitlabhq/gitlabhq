import { formatGroup } from '~/groups/show/actions/formatter';
import {
  formatGraphQLGroup,
  formatGroupForGraphQLResolver,
} from '~/vue_shared/components/groups_list/formatter';
import {
  ACTION_EDIT,
  ACTION_REQUEST_ACCESS,
  ACTION_WITHDRAW_ACCESS_REQUEST,
} from '~/vue_shared/components/list_actions/constants';

describe('formatGroup', () => {
  const mockData = {
    id: 1,
    name: 'test-group',
    full_name: 'Test Group',
    full_path: 'test-group',
    edit_path: '/groups/test-group/edit',
    withdraw_access_request_path: '/groups/test-group/withdraw_access',
    request_access_path: '/groups/test-group/request_access',
    can_edit: true,
  };

  it('correctly formats the group', () => {
    const expected = formatGraphQLGroup(formatGroupForGraphQLResolver(mockData));

    expect(formatGroup(mockData)).toEqual(expected);
  });

  describe.each`
    canWithdraw | canRequest | withdrawPath   | requestPath   | expectedActions
    ${true}     | ${false}   | ${'/withdraw'} | ${null}       | ${[ACTION_EDIT, ACTION_WITHDRAW_ACCESS_REQUEST]}
    ${true}     | ${false}   | ${null}        | ${null}       | ${[ACTION_EDIT]}
    ${false}    | ${true}    | ${null}        | ${'/request'} | ${[ACTION_EDIT, ACTION_REQUEST_ACCESS]}
    ${false}    | ${true}    | ${null}        | ${null}       | ${[ACTION_EDIT]}
    ${true}     | ${true}    | ${'/withdraw'} | ${'/request'} | ${[ACTION_EDIT, ACTION_WITHDRAW_ACCESS_REQUEST]}
    ${false}    | ${false}   | ${'/withdraw'} | ${'/request'} | ${[ACTION_EDIT]}
  `(
    'when canWithdrawAccessRequest=$canWithdraw, canRequestAccess=$canRequest, withdrawAccessRequestPath=$withdrawPath, and requestAccessPath=$requestPath',
    ({ canWithdraw, canRequest, withdrawPath, requestPath, expectedActions }) => {
      it('includes expected actions', () => {
        const groupData = {
          ...mockData,
          withdraw_access_request_path: withdrawPath,
          request_access_path: requestPath,
        };

        const permissions = {
          canWithdrawAccessRequest: canWithdraw,
          canRequestAccess: canRequest,
        };

        expect(formatGroup(groupData, permissions).availableActions).toEqual(
          expect.arrayContaining(expectedActions),
        );
      });
    },
  );
});
