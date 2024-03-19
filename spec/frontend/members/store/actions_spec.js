import axios from 'axios';
import MockAdapter from 'axios-mock-adapter';
import { noop } from 'lodash';
import { useFakeDate } from 'helpers/fake_date';
import testAction from 'helpers/vuex_action_helper';
import { members, group, modalData } from 'jest/members/mock_data';
import { HTTP_STATUS_OK } from '~/lib/utils/http_status';
import {
  updateMemberRole,
  showRemoveGroupLinkModal,
  hideRemoveGroupLinkModal,
  showRemoveMemberModal,
  hideRemoveMemberModal,
  updateMemberExpiration,
} from '~/members/store/actions';
import * as types from '~/members/store/mutation_types';

const mockedRequestFormatter = jest.fn().mockImplementation(noop);

describe('Vuex members actions', () => {
  describe('update member actions', () => {
    let mock;

    const state = {
      members,
      memberPath: '/groups/foo-bar/-/group_members/:id',
      requestFormatter: mockedRequestFormatter,
    };

    beforeEach(() => {
      mock = new MockAdapter(axios);
    });

    afterEach(() => {
      mock.restore();
    });

    describe('updateMemberRole', () => {
      const memberId = members[0].id;
      const accessLevel = 30;
      const memberRoleId = 90;

      const payload = { memberId, accessLevel, memberRoleId };

      describe('successful request', () => {
        describe('updates member role', () => {
          const MOCK_REQUEST_RESULT = { status: 'ok' };
          let response;

          beforeEach(async () => {
            mock.onPut().replyOnce(HTTP_STATUS_OK, MOCK_REQUEST_RESULT);
            response = await testAction(updateMemberRole, payload, state, []);
          });

          it('will make the PUT request', () => {
            expect(mock.history.put[0].url).toBe('/groups/foo-bar/-/group_members/238');
            expect(mockedRequestFormatter).toHaveBeenCalledWith({
              accessLevel,
              memberRoleId,
            });
          });

          it('will return the request result', () => {
            expect(response.data).toEqual(MOCK_REQUEST_RESULT);
          });
        });
      });

      describe('unsuccessful request', () => {
        it(`commits ${types.RECEIVE_MEMBER_ROLE_ERROR} mutation and throws error`, async () => {
          const error = new Error('Network Error');
          mock.onPut().reply(() => Promise.reject(error));

          await expect(
            testAction(updateMemberRole, payload, state, [
              {
                type: types.RECEIVE_MEMBER_ROLE_ERROR,
                payload: { error },
              },
            ]),
          ).rejects.toThrow(error);
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
            mock.onPut().replyOnce(HTTP_STATUS_OK);

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
            mock.onPut().replyOnce(HTTP_STATUS_OK);

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
          const error = new Error('Network Error');
          mock.onPut().reply(() => Promise.reject(error));

          await expect(
            testAction(updateMemberExpiration, { memberId, expiresAt }, state, [
              {
                type: types.RECEIVE_MEMBER_EXPIRATION_ERROR,
                payload: { error },
              },
            ]),
          ).rejects.toThrow(error);
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
        return testAction(showRemoveGroupLinkModal, group, state, [
          {
            type: types.SHOW_REMOVE_GROUP_LINK_MODAL,
            payload: group,
          },
        ]);
      });
    });

    describe('hideRemoveGroupLinkModal', () => {
      it(`commits ${types.HIDE_REMOVE_GROUP_LINK_MODAL} mutation`, () => {
        return testAction(hideRemoveGroupLinkModal, group, state, [
          {
            type: types.HIDE_REMOVE_GROUP_LINK_MODAL,
          },
        ]);
      });
    });
  });

  describe('Remove member modal', () => {
    const state = {
      removeMemberModalVisible: false,
      removeMemberModalData: {},
    };

    describe('showRemoveMemberModal', () => {
      it(`commits ${types.SHOW_REMOVE_MEMBER_MODAL} mutation`, () => {
        return testAction(showRemoveMemberModal, modalData, state, [
          {
            type: types.SHOW_REMOVE_MEMBER_MODAL,
            payload: modalData,
          },
        ]);
      });
    });

    describe('hideRemoveMemberModal', () => {
      it(`commits ${types.HIDE_REMOVE_MEMBER_MODAL} mutation`, () => {
        return testAction(hideRemoveMemberModal, undefined, state, [
          {
            type: types.HIDE_REMOVE_MEMBER_MODAL,
          },
        ]);
      });
    });
  });
});
