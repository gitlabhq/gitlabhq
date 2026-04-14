import getProjectByPathResponse from 'test_fixtures/graphql/graphql_shared/queries/get_project_by_path.graphql.json';
import {
  ACTION_REQUEST_ACCESS,
  ACTION_WITHDRAW_ACCESS_REQUEST,
} from '~/vue_shared/components/list_actions/constants';
import { formatProject } from '~/projects/home_panel/formatter';
import { formatGraphQLProject } from '~/vue_shared/components/projects_list/formatter';

describe('formatProject', () => {
  const mockProject = getProjectByPathResponse.data.project;

  it('correctly formats the project', () => {
    const expected = formatGraphQLProject(mockProject);

    expect(formatProject(mockProject)).toEqual(expected);
  });

  describe.each`
    canWithdraw | canRequest | withdrawPath   | requestPath   | expectedActions
    ${true}     | ${false}   | ${'/withdraw'} | ${null}       | ${[ACTION_WITHDRAW_ACCESS_REQUEST]}
    ${true}     | ${false}   | ${null}        | ${null}       | ${[]}
    ${false}    | ${true}    | ${null}        | ${'/request'} | ${[ACTION_REQUEST_ACCESS]}
    ${false}    | ${true}    | ${null}        | ${null}       | ${[]}
    ${true}     | ${true}    | ${'/withdraw'} | ${'/request'} | ${[ACTION_WITHDRAW_ACCESS_REQUEST]}
    ${false}    | ${false}   | ${'/withdraw'} | ${'/request'} | ${[]}
  `(
    'when canWithdrawAccessRequest=$canWithdraw, canRequestAccess=$canRequest, withdrawAccessRequestPath=$withdrawPath, and requestAccessPath=$requestPath',
    ({ canWithdraw, canRequest, withdrawPath, requestPath, expectedActions }) => {
      it('includes expected actions', () => {
        const options = {
          canWithdrawAccessRequest: canWithdraw,
          canRequestAccess: canRequest,
          withdrawAccessRequestPath: withdrawPath,
          requestAccessPath: requestPath,
        };

        expect(formatProject(mockProject, options)).toMatchObject({
          availableActions: expect.arrayContaining(expectedActions),
          withdrawAccessRequestPath: withdrawPath,
          requestAccessPath: requestPath,
        });
      });
    },
  );
});
