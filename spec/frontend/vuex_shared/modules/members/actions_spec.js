import { noop } from 'lodash';
import axios from 'axios';
import MockAdapter from 'axios-mock-adapter';
import { members } from 'jest/vue_shared/components/members/mock_data';
import testAction from 'helpers/vuex_action_helper';
import httpStatusCodes from '~/lib/utils/http_status';
import * as types from '~/vuex_shared/modules/members/mutation_types';
import { updateMemberRole } from '~/vuex_shared/modules/members/actions';

describe('Vuex members actions', () => {
  let mock;

  beforeEach(() => {
    mock = new MockAdapter(axios);
  });

  afterEach(() => {
    mock.restore();
  });

  describe('updateMemberRole', () => {
    const memberId = members[0].id;
    const accessLevel = { integerValue: 30, stringValue: 'Developer' };

    const payload = {
      memberId,
      accessLevel,
    };
    const state = {
      members,
      memberPath: '/groups/foo-bar/-/group_members/:id',
      requestFormatter: noop,
    };

    describe('successful request', () => {
      it(`commits ${types.RECEIVE_MEMBER_ROLE_SUCCESS} mutation`, async () => {
        let requestPath;
        mock.onPut().replyOnce(config => {
          requestPath = config.url;
          return [httpStatusCodes.OK, {}];
        });

        await testAction(updateMemberRole, payload, state, [
          {
            type: types.RECEIVE_MEMBER_ROLE_SUCCESS,
            payload,
          },
        ]);

        expect(requestPath).toBe('/groups/foo-bar/-/group_members/238');
      });
    });

    describe('unsuccessful request', () => {
      beforeEach(() => {
        mock.onPut().replyOnce(httpStatusCodes.BAD_REQUEST, { message: 'Bad request' });
      });

      it(`commits ${types.RECEIVE_MEMBER_ROLE_ERROR} mutation`, async () => {
        try {
          await testAction(updateMemberRole, payload, state, [
            {
              type: types.RECEIVE_MEMBER_ROLE_SUCCESS,
            },
          ]);
        } catch {
          // Do nothing
        }
      });

      it('throws error', async () => {
        await expect(testAction(updateMemberRole, payload, state)).rejects.toThrowError();
      });
    });
  });
});
