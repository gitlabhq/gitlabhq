import { initEmojiMock, clearEmojiMock } from 'helpers/emoji';
import waitForPromises from 'helpers/wait_for_promises';
import installGlEmojiElement from '~/behaviors/gl_emoji';
import { EMOJI_VERSION } from '~/emoji';

import * as EmojiUnicodeSupport from '~/emoji/support';

jest.mock('~/emoji/support');

describe('gl_emoji', () => {
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

  beforeEach(async () => {
    await initEmojiMock(emojiData);
  });

  afterEach(() => {
    clearEmojiMock();

    document.body.innerHTML = '';
  });

  describe.each([
    [
      'bomb emoji just with name attribute',
      '<gl-emoji data-name="bomb"></gl-emoji>',
      '<gl-emoji data-name="bomb" data-unicode-version="6.0" title="bomb">💣</gl-emoji>',
      `<gl-emoji data-name="bomb" data-unicode-version="6.0" title="bomb"><img class="emoji" title=":bomb:" alt=":bomb:" src="/-/emojis/${EMOJI_VERSION}/bomb.png" width="16" height="16" align="absmiddle"></gl-emoji>`,
    ],
    [
      'bomb emoji with name attribute and unicode version',
      '<gl-emoji data-name="bomb" data-unicode-version="6.0">💣</gl-emoji>',
      '<gl-emoji data-name="bomb" data-unicode-version="6.0">💣</gl-emoji>',
      `<gl-emoji data-name="bomb" data-unicode-version="6.0"><img class="emoji" title=":bomb:" alt=":bomb:" src="/-/emojis/${EMOJI_VERSION}/bomb.png" width="16" height="16" align="absmiddle"></gl-emoji>`,
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
      '<gl-emoji data-fallback-src="/bomb.png" data-name="bomb" data-unicode-version="6.0" title="bomb"><img class="emoji" title=":bomb:" alt=":bomb:" src="/bomb.png" width="16" height="16" align="absmiddle"></gl-emoji>',
    ],
    [
      'invalid emoji',
      '<gl-emoji data-name="invalid_emoji"></gl-emoji>',
      '<gl-emoji data-name="grey_question" data-unicode-version="6.0" title="white question mark ornament">❔</gl-emoji>',
      `<gl-emoji data-name="grey_question" data-unicode-version="6.0" title="white question mark ornament"><img class="emoji" title=":grey_question:" alt=":grey_question:" src="/-/emojis/${EMOJI_VERSION}/grey_question.png" width="16" height="16" align="absmiddle"></gl-emoji>`,
    ],
    [
      'custom emoji with image fallback',
      '<gl-emoji data-fallback-src="https://cultofthepartyparrot.com/parrots/hd/parrot.gif" data-name="party-parrot" data-unicode-version="custom"></gl-emoji>',
      '<gl-emoji data-fallback-src="https://cultofthepartyparrot.com/parrots/hd/parrot.gif" data-name="party-parrot" data-unicode-version="custom"><img class="emoji" title=":party-parrot:" alt=":party-parrot:" src="https://cultofthepartyparrot.com/parrots/hd/parrot.gif" width="16" height="16" align="absmiddle"></gl-emoji>',
      '<gl-emoji data-fallback-src="https://cultofthepartyparrot.com/parrots/hd/parrot.gif" data-name="party-parrot" data-unicode-version="custom"><img class="emoji" title=":party-parrot:" alt=":party-parrot:" src="https://cultofthepartyparrot.com/parrots/hd/parrot.gif" width="16" height="16" align="absmiddle"></gl-emoji>',
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

  it('escapes gl-emoji name', async () => {
    const glEmojiElement = markupToDomElement(
      "<gl-emoji data-name='&#34;x=&#34y&#34 onload=&#34;alert(document.location.href)&#34;' data-unicode-version='x'>abc</gl-emoji>",
    );

    await waitForPromises();

    expect(glEmojiElement.outerHTML).toBe(
      '<gl-emoji data-name="&quot;x=&quot;y&quot; onload=&quot;alert(document.location.href)&quot;" data-unicode-version="x"><img class="emoji" title=":&quot;x=&quot;y&quot; onload=&quot;alert(document.location.href)&quot;:" alt=":&quot;x=&quot;y&quot; onload=&quot;alert(document.location.href)&quot;:" src="/-/emojis/2/grey_question.png" width="16" height="16" align="absmiddle"></gl-emoji>',
    );
  });

  it('Adds sprite CSS if emojis are not supported', async () => {
    const testPath = '/test-path.css';
    jest.spyOn(EmojiUnicodeSupport, 'default').mockReturnValue(false);
    window.gon.emoji_sprites_css_path = testPath;

    expect(document.head.querySelector(`link[href="${testPath}"]`)).toBe(null);
    expect(window.gon.emoji_sprites_css_added).toBe(undefined);

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
