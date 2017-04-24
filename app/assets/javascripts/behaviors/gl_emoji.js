import installCustomElements from 'document-register-element';
import emojiMap from 'emojis/digests.json';
import emojiAliases from 'emojis/aliases.json';
import { getUnicodeSupportMap } from './gl_emoji/unicode_support_map';
import { isEmojiUnicodeSupported } from './gl_emoji/is_emoji_unicode_supported';

installCustomElements(window);

const generatedUnicodeSupportMap = getUnicodeSupportMap();

function emojiImageTag(name, src) {
  return `<img class="emoji" title=":${name}:" alt=":${name}:" src="${src}" width="20" height="20" align="absmiddle" />`;
}

function assembleFallbackImageSrc(inputName) {
  let name = Object.prototype.hasOwnProperty.call(emojiAliases, inputName) ?
    emojiAliases[inputName] : inputName;
  let emojiInfo = emojiMap[name];
  // Fallback to question mark for unknown emojis
  if (!emojiInfo) {
    name = 'grey_question';
    emojiInfo = emojiMap[name];
  }
  const fallbackImageSrc = `${gon.asset_host || ''}${gon.relative_url_root || ''}/assets/emoji/${name}-${emojiInfo.digest}.png`;

  return fallbackImageSrc;
}
const glEmojiTagDefaults = {
  sprite: false,
  forceFallback: false,
};
function glEmojiTag(inputName, options) {
  const opts = Object.assign({}, glEmojiTagDefaults, options);
  let name = Object.prototype.hasOwnProperty.call(emojiAliases, inputName) ?
    emojiAliases[inputName] : inputName;
  let emojiInfo = emojiMap[name];
  // Fallback to question mark for unknown emojis
  if (!emojiInfo) {
    name = 'grey_question';
    emojiInfo = emojiMap[name];
  }

  const fallbackImageSrc = assembleFallbackImageSrc(name);
  const fallbackSpriteClass = `emoji-${name}`;

  const classList = [];
  if (opts.forceFallback && opts.sprite) {
    classList.push('emoji-icon');
    classList.push(fallbackSpriteClass);
  }
  const classAttribute = classList.length > 0 ? `class="${classList.join(' ')}"` : '';
  const fallbackSpriteAttribute = opts.sprite ? `data-fallback-sprite-class="${fallbackSpriteClass}"` : '';
  let contents = emojiInfo.moji;
  if (opts.forceFallback && !opts.sprite) {
    contents = emojiImageTag(name, fallbackImageSrc);
  }

  return `
  <gl-emoji
    ${classAttribute}
    data-name="${name}"
    data-fallback-src="${fallbackImageSrc}"
    ${fallbackSpriteAttribute}
    data-unicode-version="${emojiInfo.unicodeVersion}"
    title=${emojiInfo.description}
  >
    ${contents}
  </gl-emoji>
  `;
}

function installGlEmojiElement() {
  const GlEmojiElementProto = Object.create(HTMLElement.prototype);
  GlEmojiElementProto.createdCallback = function createdCallback() {
    const emojiUnicode = this.textContent.trim();
    const {
      name,
      unicodeVersion,
      fallbackSrc,
      fallbackSpriteClass,
    } = this.dataset;

    const isEmojiUnicode = this.childNodes && Array.prototype.every.call(
      this.childNodes,
      childNode => childNode.nodeType === 3,
    );
    const hasImageFallback = fallbackSrc && fallbackSrc.length > 0;
    const hasCssSpriteFalback = fallbackSpriteClass && fallbackSpriteClass.length > 0;

    if (
      isEmojiUnicode &&
      !isEmojiUnicodeSupported(generatedUnicodeSupportMap, emojiUnicode, unicodeVersion)
    ) {
      // CSS sprite fallback takes precedence over image fallback
      if (hasCssSpriteFalback) {
        // IE 11 doesn't like adding multiple at once :(
        this.classList.add('emoji-icon');
        this.classList.add(fallbackSpriteClass);
      } else if (hasImageFallback) {
        this.innerHTML = emojiImageTag(name, fallbackSrc);
      } else {
        const src = assembleFallbackImageSrc(name);
        this.innerHTML = emojiImageTag(name, src);
      }
    }
  };

  document.registerElement('gl-emoji', {
    prototype: GlEmojiElementProto,
  });
}

export {
  installGlEmojiElement,
  glEmojiTag,
  emojiImageTag,
};
