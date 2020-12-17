import { members } from 'jest/members/mock_data';
import { findMember } from '~/members/store/utils';

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
