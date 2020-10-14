import { members } from 'jest/vue_shared/components/members/mock_data';
import mutations from '~/vuex_shared/modules/members/mutations';
import * as types from '~/vuex_shared/modules/members/mutation_types';

describe('Vuex members mutations', () => {
  describe(types.RECEIVE_MEMBER_ROLE_SUCCESS, () => {
    it('updates member', () => {
      const state = {
        members,
      };

      const accessLevel = { integerValue: 30, stringValue: 'Developer' };

      mutations[types.RECEIVE_MEMBER_ROLE_SUCCESS](state, {
        memberId: members[0].id,
        accessLevel,
      });

      expect(state.members[0].accessLevel).toEqual(accessLevel);
    });
  });

  describe(types.RECEIVE_MEMBER_ROLE_ERROR, () => {
    it('shows error message', () => {
      const state = {
        showError: false,
        errorMessage: '',
      };

      mutations[types.RECEIVE_MEMBER_ROLE_ERROR](state);

      expect(state.showError).toBe(true);
      expect(state.errorMessage).toBe(
        "An error occurred while updating the member's role, please try again.",
      );
    });
  });

  describe(types.HIDE_ERROR, () => {
    it('sets `showError` to `false`', () => {
      const state = {
        showError: true,
        errorMessage: 'foo bar',
      };

      mutations[types.HIDE_ERROR](state);

      expect(state.showError).toBe(false);
    });

    it('sets `errorMessage` to an empty string', () => {
      const state = {
        showError: true,
        errorMessage: 'foo bar',
      };

      mutations[types.HIDE_ERROR](state);

      expect(state.errorMessage).toBe('');
    });
  });
});
