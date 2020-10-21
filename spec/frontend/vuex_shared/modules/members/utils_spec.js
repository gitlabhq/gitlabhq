import { members } from 'jest/vue_shared/components/members/mock_data';
import { findMember } from '~/vuex_shared/modules/members/utils';

describe('Members Vuex utils', () => {
  describe('findMember', () => {
    it('finds member by ID', () => {
      const state = {
        members,
      };

      expect(findMember(state, members[0].id)).toEqual(members[0]);
    });
  });
});
