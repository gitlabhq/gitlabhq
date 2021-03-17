import MockAdapter from 'axios-mock-adapter';
import waitForPromises from 'helpers/wait_for_promises';
import installGlEmojiElement from '~/behaviors/gl_emoji';
import { initEmojiMap, EMOJI_VERSION } from '~/emoji';

import * as EmojiUnicodeSupport from '~/emoji/support';
import axios from '~/lib/utils/axios_utils';

jest.mock('~/emoji/support');

describe('gl_emoji', () => {
  let mock;
  const emojiData = {
    grey_question: {
      c: 'symbols',
      e: '❔',
      d: 'white question mark ornament',
      u: '6.0',
    },
    bomb: {
      c: 'objects',
      e: '💣',
      d: 'bomb',
      u: '6.0',
    },
  };

  beforeAll(() => {
    jest.spyOn(EmojiUnicodeSupport, 'default').mockReturnValue(true);
    installGlEmojiElement();
  });

  function markupToDomElement(markup) {
    const div = document.createElement('div');
    div.innerHTML = markup;
    document.body.appendChild(div);

    return div.firstElementChild;
  }

  beforeEach(() => {
    mock = new MockAdapter(axios);
    mock.onGet(`/-/emojis/${EMOJI_VERSION}/emojis.json`).reply(200, emojiData);

    return initEmojiMap().catch(() => {});
  });

  afterEach(() => {
    mock.restore();

    document.body.innerHTML = '';
  });

  describe.each([
    [
      'bomb emoji just with name attribute',
      '<gl-emoji data-name="bomb"></gl-emoji>',
      '<gl-emoji data-name="bomb" data-unicode-version="6.0" title="bomb">💣</gl-emoji>',
      '<gl-emoji data-name="bomb" data-unicode-version="6.0" title="bomb"><img class="emoji" title=":bomb:" alt=":bomb:" src="/-/emojis/1/bomb.png" width="20" height="20" align="absmiddle"></gl-emoji>',
    ],
    [
      'bomb emoji with name attribute and unicode version',
      '<gl-emoji data-name="bomb" data-unicode-version="6.0">💣</gl-emoji>',
      '<gl-emoji data-name="bomb" data-unicode-version="6.0">💣</gl-emoji>',
      '<gl-emoji data-name="bomb" data-unicode-version="6.0"><img class="emoji" title=":bomb:" alt=":bomb:" src="/-/emojis/1/bomb.png" width="20" height="20" align="absmiddle"></gl-emoji>',
    ],
    [
      'bomb emoji with sprite fallback',
      '<gl-emoji data-fallback-sprite-class="emoji-bomb" data-name="bomb"></gl-emoji>',
      '<gl-emoji data-fallback-sprite-class="emoji-bomb" data-name="bomb" data-unicode-version="6.0" title="bomb">💣</gl-emoji>',
      '<gl-emoji data-fallback-sprite-class="emoji-bomb" data-name="bomb" data-unicode-version="6.0" title="bomb" class="emoji-icon emoji-bomb">💣</gl-emoji>',
    ],
    [
      'bomb emoji with image fallback',
      '<gl-emoji data-fallback-src="/bomb.png" data-name="bomb"></gl-emoji>',
      '<gl-emoji data-fallback-src="/bomb.png" data-name="bomb" data-unicode-version="6.0" title="bomb">💣</gl-emoji>',
      '<gl-emoji data-fallback-src="/bomb.png" data-name="bomb" data-unicode-version="6.0" title="bomb"><img class="emoji" title=":bomb:" alt=":bomb:" src="/bomb.png" width="20" height="20" align="absmiddle"></gl-emoji>',
    ],
    [
      'invalid emoji',
      '<gl-emoji data-name="invalid_emoji"></gl-emoji>',
      '<gl-emoji data-name="grey_question" data-unicode-version="6.0" title="white question mark ornament">❔</gl-emoji>',
      '<gl-emoji data-name="grey_question" data-unicode-version="6.0" title="white question mark ornament"><img class="emoji" title=":grey_question:" alt=":grey_question:" src="/-/emojis/1/grey_question.png" width="20" height="20" align="absmiddle"></gl-emoji>',
    ],
  ])('%s', (name, markup, withEmojiSupport, withoutEmojiSupport) => {
    it(`renders correctly with emoji support`, async () => {
      jest.spyOn(EmojiUnicodeSupport, 'default').mockReturnValue(true);
      const glEmojiElement = markupToDomElement(markup);

      await waitForPromises();

      expect(glEmojiElement.outerHTML).toBe(withEmojiSupport);
    });

    it(`renders correctly without emoji support`, async () => {
      jest.spyOn(EmojiUnicodeSupport, 'default').mockReturnValue(false);
      const glEmojiElement = markupToDomElement(markup);

      await waitForPromises();

      expect(glEmojiElement.outerHTML).toBe(withoutEmojiSupport);
    });
  });

  it('Adds sprite CSS if emojis are not supported', async () => {
    const testPath = '/test-path.css';
    jest.spyOn(EmojiUnicodeSupport, 'default').mockReturnValue(false);
    window.gon.emoji_sprites_css_path = testPath;

    expect(document.head.querySelector(`link[href="${testPath}"]`)).toBe(null);
    expect(window.gon.emoji_sprites_css_added).toBeFalsy();

    markupToDomElement(
      '<gl-emoji data-fallback-sprite-class="emoji-bomb" data-name="bomb"></gl-emoji>',
    );
    await waitForPromises();

    expect(document.head.querySelector(`link[href="${testPath}"]`).outerHTML).toBe(
      '<link rel="stylesheet" href="/test-path.css">',
    );
    expect(window.gon.emoji_sprites_css_added).toBe(true);
  });
});
