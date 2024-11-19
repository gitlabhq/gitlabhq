import {
  SET_INITIAL_DATA,
  FETCH_AWARDS_SUCCESS,
  ADD_NEW_AWARD,
  REMOVE_AWARD,
} from '~/emoji/awards_app/store/mutation_types';
import mutations from '~/emoji/awards_app/store/mutations';
import { EMOJI_THUMBS_UP, EMOJI_THUMBS_DOWN } from '~/emoji/constants';

describe('Awards app mutations', () => {
  describe('SET_INITIAL_DATA', () => {
    it('sets initial data', () => {
      const state = {};

      mutations[SET_INITIAL_DATA](state, {
        path: 'https://gitlab.com',
        currentUserId: 1,
        canAwardEmoji: true,
      });

      expect(state).toEqual({
        path: 'https://gitlab.com',
        currentUserId: 1,
        canAwardEmoji: true,
      });
    });
  });

  describe('FETCH_AWARDS_SUCCESS', () => {
    it('sets awards', () => {
      const state = { awards: [] };

      mutations[FETCH_AWARDS_SUCCESS](state, [EMOJI_THUMBS_UP]);

      expect(state.awards).toEqual([EMOJI_THUMBS_UP]);
    });

    it('does not overwrite previously set awards', () => {
      const state = { awards: [EMOJI_THUMBS_UP] };

      mutations[FETCH_AWARDS_SUCCESS](state, [EMOJI_THUMBS_DOWN]);

      expect(state.awards).toEqual([EMOJI_THUMBS_UP, EMOJI_THUMBS_DOWN]);
    });
  });

  describe('ADD_NEW_AWARD', () => {
    it('adds new award to array', () => {
      const state = { awards: [EMOJI_THUMBS_UP] };

      mutations[ADD_NEW_AWARD](state, EMOJI_THUMBS_DOWN);

      expect(state.awards).toEqual([EMOJI_THUMBS_UP, EMOJI_THUMBS_DOWN]);
    });
  });

  describe('REMOVE_AWARD', () => {
    it('removes award from array', () => {
      const state = { awards: [{ id: 1 }, { id: 2 }] };

      mutations[REMOVE_AWARD](state, 1);

      expect(state.awards).toEqual([{ id: 2 }]);
    });
  });
});
