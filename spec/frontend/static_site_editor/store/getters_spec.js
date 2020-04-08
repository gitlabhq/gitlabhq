import createState from '~/static_site_editor/store/state';
import { isContentLoaded } from '~/static_site_editor/store/getters';
import { sourceContent as content } from '../mock_data';

describe('Static Site Editor Store getters', () => {
  describe('isContentLoaded', () => {
    it('returns true when content is not empty', () => {
      expect(isContentLoaded(createState({ content }))).toBe(true);
    });

    it('returns false when content is empty', () => {
      expect(isContentLoaded(createState({ content: '' }))).toBe(false);
    });
  });
});
