import $ from 'jquery';
import htmlSnippetsShow from 'test_fixtures/snippets/show.html';
import emojis from 'public/-/emojis/4/emojis.json';
import { initEmojiMock, clearEmojiMock } from 'helpers/emoji';
import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
import waitForPromises from 'helpers/wait_for_promises';
import initGFMInput from '~/behaviors/markdown/gfm_auto_complete';
import initDeprecatedNotes from '~/init_deprecated_notes';

describe('GFM emoji autocomplete', () => {
  beforeEach(async () => {
    // Primed with the real emoji dataset rather than `mockEmojiData`: the
    // expectations below assert real emoji names and the search ordering
    // quirks they expose, which a handful of fixture emoji cannot reproduce.
    // Priming the cache also means no emoji request is made.
    await initEmojiMock(emojis);

    setHTMLFixture(htmlSnippetsShow);

    initGFMInput($('.js-gfm-input:not(.js-gfm-input-initialized)'));
    initDeprecatedNotes();
  });

  afterEach(() => {
    clearEmojiMock();
    resetHTMLFixture();
  });

  const findNoteTextarea = () => document.getElementById('note_note');
  const findAtViewEmojiMenu = () => document.getElementById('at-view-58');
  const findAtwhoResult = () =>
    Array.from(findAtViewEmojiMenu().querySelectorAll('li')).map((x) => x.innerText.trim());

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

    await waitForPromises();

    expect(findAtwhoResult()).toEqual(expected);
  });
});
