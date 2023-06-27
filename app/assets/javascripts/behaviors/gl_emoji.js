import {
  initEmojiMap,
  getEmojiInfo,
  emojiFallbackImageSrc,
  emojiImageTag,
  findCustomEmoji,
} from '../emoji';
import isEmojiUnicodeSupported from '../emoji/support';

class GlEmoji extends HTMLElement {
  connectedCallback() {
    this.initialize();
  }
  initialize() {
    let emojiUnicode = this.textContent.trim();
    const { fallbackSpriteClass, fallbackSrc } = this.dataset;
    let { name, unicodeVersion } = this.dataset;

    return initEmojiMap().then(() => {
      if (!unicodeVersion) {
        const emojiInfo = getEmojiInfo(name);

        if (emojiInfo) {
          if (name !== emojiInfo.name) {
            ({ name } = emojiInfo);
            this.dataset.name = emojiInfo.name;
          }
          unicodeVersion = emojiInfo.u;
          this.dataset.unicodeVersion = unicodeVersion;

          emojiUnicode = emojiInfo.e;
          this.textContent = emojiInfo.e;

          this.title = emojiInfo.d;
        }
      }

      const isEmojiUnicode =
        this.childNodes &&
        Array.prototype.every.call(this.childNodes, (childNode) => childNode.nodeType === 3);

      const customEmoji = findCustomEmoji(name);
      const hasImageFallback = fallbackSrc?.length > 0;
      const hasCssSpriteFallback = fallbackSpriteClass?.length > 0;

      if (emojiUnicode && isEmojiUnicode && isEmojiUnicodeSupported(emojiUnicode, unicodeVersion)) {
        // noop
      } else if (hasCssSpriteFallback) {
        if (!gon.emoji_sprites_css_added && gon.emoji_sprites_css_path) {
          const emojiSpriteLinkTag = document.createElement('link');
          emojiSpriteLinkTag.setAttribute('rel', 'stylesheet');
          emojiSpriteLinkTag.setAttribute('href', gon.emoji_sprites_css_path);
          document.head.appendChild(emojiSpriteLinkTag);
          gon.emoji_sprites_css_added = true;
        }
        // IE 11 doesn't like adding multiple at once :(
        this.classList.add('emoji-icon');
        this.classList.add(fallbackSpriteClass);
      } else if (hasImageFallback) {
        this.innerHTML = '';
        this.appendChild(emojiImageTag(name, customEmoji?.src || fallbackSrc));
      } else {
        const src = emojiFallbackImageSrc(name);
        this.innerHTML = '';
        this.appendChild(emojiImageTag(name, src));
      }
    });
  }
}

export default function installGlEmojiElement() {
  if (!customElements.get('gl-emoji')) {
    customElements.define('gl-emoji', GlEmoji);
  }
}
