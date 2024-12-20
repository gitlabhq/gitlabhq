import $ from 'jquery';
import htmlSnippetsShow from 'test_fixtures/snippets/show.html';
import axios from '~/lib/utils/axios_utils';
import initGFMInput from '~/behaviors/markdown/gfm_auto_complete';
import initDeprecatedNotes from '~/init_deprecated_notes';
import { setHTMLFixture } from 'helpers/fixtures';

describe('Integration Snippets notes', () => {
  beforeEach(() => {
    setHTMLFixture(htmlSnippetsShow);

    // Check if we have to Load GFM Input
    const $gfmInputs = $('.js-gfm-input:not(.js-gfm-input-initialized)');
    initGFMInput($gfmInputs);

    initDeprecatedNotes();
  });

  describe('emoji autocomplete', () => {
    const findNoteTextarea = () => document.getElementById('note_note');
    const findAtViewEmojiMenu = () => document.getElementById('at-view-58');
    const findAtwhoResult = () => {
      return Array.from(findAtViewEmojiMenu().querySelectorAll('li')).map((x) =>
        x.innerText.trim(),
      );
    };
    const fillNoteTextarea = (val) => {
      const textarea = findNoteTextarea();

      textarea.dispatchEvent(new Event('focus'));
      textarea.value = val;
      textarea.dispatchEvent(new Event('input'));
      textarea.dispatchEvent(new Event('click'));
    };

    it.each([
      [
        ':heart',
        [
          'heart',
          'heart decoration',
          'heart exclamation',
          'heart hands',
          'heart hands: dark skin tone',
        ],
      ],
      [':red', ['red apple', 'red circle', 'red envelope', 'red exclamation mark', 'red hair']],
      [
        ':circle',
        // TODO: https://gitlab.com/gitlab-org/gitlab/-/issues/347549
        // These autocompleted results aren't very good. The autocompletion should be improved.
        ['circled M', 'red circle', 'blue circle', 'black circle', 'brown circle'],
      ],
      [':', ['grinning', 'smiley', 'smile', 'grin', 'laughing']],
      // We do not want the search to start with space https://gitlab.com/gitlab-org/gitlab/-/issues/322548
      [': ', []],
      // We want to preserve that we can have space INSIDE the search
      [':red ci', ['red circle', 'hollow red circle']],
    ])('shows a correct list of matching emojis when user enters %s', async (input, expected) => {
      fillNoteTextarea(input);

      await axios.waitForAll();

      const result = findAtwhoResult();
      expect(result).toEqual(expected);
    });
  });
});
