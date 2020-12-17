import { noop } from 'lodash';
import axios from 'axios';
import MockAdapter from 'axios-mock-adapter';
import { members, group } from 'jest/members/mock_data';
import testAction from 'helpers/vuex_action_helper';
import { useFakeDate } from 'helpers/fake_date';
import httpStatusCodes from '~/lib/utils/http_status';
import * as types from '~/members/store/mutation_types';
import {
  updateMemberRole,
  showRemoveGroupLinkModal,
  hideRemoveGroupLinkModal,
  updateMemberExpiration,
} from '~/members/store/actions';

describe('Vuex members actions', () => {
  describe('update member actions', () => {
    let mock;

    const state = {
      members,
      memberPath: '/groups/foo-bar/-/group_members/:id',
      requestFormatter: noop,
    };

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

      describe('successful request', () => {
        it(`commits ${types.RECEIVE_MEMBER_ROLE_SUCCESS} mutation`, async () => {
          mock.onPut().replyOnce(httpStatusCodes.OK);

          await testAction(updateMemberRole, payload, state, [
            {
              type: types.RECEIVE_MEMBER_ROLE_SUCCESS,
              payload,
            },
          ]);

          expect(mock.history.put[0].url).toBe('/groups/foo-bar/-/group_members/238');
        });
      });

      describe('unsuccessful request', () => {
        it(`commits ${types.RECEIVE_MEMBER_ROLE_ERROR} mutation and throws error`, async () => {
          mock.onPut().networkError();

          await expect(
            testAction(updateMemberRole, payload, state, [
              {
                type: types.RECEIVE_MEMBER_ROLE_ERROR,
              },
            ]),
          ).rejects.toThrowError(new Error('Network Error'));
        });
      });
    });

    describe('updateMemberExpiration', () => {
      useFakeDate(2020, 2, 15, 3);

      const memberId = members[0].id;
      const expiresAt = '2020-3-17';

      describe('successful request', () => {
        describe('changing expiration date', () => {
          it(`commits ${types.RECEIVE_MEMBER_EXPIRATION_SUCCESS} mutation`, async () => {
            mock.onPut().replyOnce(httpStatusCodes.OK);

            await testAction(updateMemberExpiration, { memberId, expiresAt }, state, [
              {
                type: types.RECEIVE_MEMBER_EXPIRATION_SUCCESS,
                payload: { memberId, expiresAt: '2020-03-17T00:00:00Z' },
              },
            ]);

            expect(mock.history.put[0].url).toBe('/groups/foo-bar/-/group_members/238');
          });
        });

        describe('removing the expiration date', () => {
          it(`commits ${types.RECEIVE_MEMBER_EXPIRATION_SUCCESS} mutation`, async () => {
            mock.onPut().replyOnce(httpStatusCodes.OK);

            await testAction(updateMemberExpiration, { memberId, expiresAt: null }, state, [
              {
                type: types.RECEIVE_MEMBER_EXPIRATION_SUCCESS,
                payload: { memberId, expiresAt: null },
              },
            ]);
          });
        });
      });

      describe('unsuccessful request', () => {
        it(`commits ${types.RECEIVE_MEMBER_EXPIRATION_ERROR} mutation and throws error`, async () => {
          mock.onPut().networkError();

          await expect(
            testAction(updateMemberExpiration, { memberId, expiresAt }, state, [
              {
                type: types.RECEIVE_MEMBER_EXPIRATION_ERROR,
              },
            ]),
          ).rejects.toThrowError(new Error('Network Error'));
        });
      });
    });
  });

  describe('Group Link Modal', () => {
    const state = {
      removeGroupLinkModalVisible: false,
      groupLinkToRemove: null,
    };

    describe('showRemoveGroupLinkModal', () => {
      it(`commits ${types.SHOW_REMOVE_GROUP_LINK_MODAL} mutation`, () => {
        testAction(showRemoveGroupLinkModal, group, state, [
          {
            type: types.SHOW_REMOVE_GROUP_LINK_MODAL,
            payload: group,
          },
        ]);
      });
    });

    describe('hideRemoveGroupLinkModal', () => {
      it(`commits ${types.HIDE_REMOVE_GROUP_LINK_MODAL} mutation`, () => {
        testAction(hideRemoveGroupLinkModal, group, state, [
          {
            type: types.HIDE_REMOVE_GROUP_LINK_MODAL,
          },
        ]);
      });
    });
  });
});
