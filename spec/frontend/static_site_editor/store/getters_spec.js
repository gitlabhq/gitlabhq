import createState from '~/static_site_editor/store/state';
import { isContentLoaded, contentChanged } from '~/static_site_editor/store/getters';
import { sourceContent as content } from '../mock_data';

describe('Static Site Editor Store getters', () => {
  describe('isContentLoaded', () => {
    it('returns true when originalContent is not empty', () => {
      expect(isContentLoaded(createState({ originalContent: content }))).toBe(true);
    });

    it('returns false when originalContent is empty', () => {
      expect(isContentLoaded(createState({ originalContent: '' }))).toBe(false);
    });
  });

  describe('contentChanged', () => {
    it('returns true when content and originalContent are different', () => {
      const state = createState({ content, originalContent: 'something else' });

      expect(contentChanged(state)).toBe(true);
    });

    it('returns false when content and originalContent are the same', () => {
      const state = createState({ content, originalContent: content });

      expect(contentChanged(state)).toBe(false);
    });
  });
});
