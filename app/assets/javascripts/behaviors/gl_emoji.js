import {
  initEmojiMap,
  getEmojiInfo,
  emojiFallbackImageSrc,
  emojiImageTag,
  FALLBACK_EMOJI_KEY,
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
            if (emojiInfo.name === FALLBACK_EMOJI_KEY && this.innerHTML) {
              return; // When fallback emoji is used, but there is a <img> provided, use the <img> instead
            }

            ({ name } = emojiInfo);
            this.dataset.name = emojiInfo.name;
          }
          unicodeVersion = emojiInfo.u;
          this.dataset.unicodeVersion = unicodeVersion;

          emojiUnicode = emojiInfo.e;
          this.innerHTML = emojiInfo.e;

          this.title = emojiInfo.d;
        }
      }

      const isEmojiUnicode =
        this.childNodes &&
        Array.prototype.every.call(this.childNodes, (childNode) => childNode.nodeType === 3);

      if (
        emojiUnicode &&
        isEmojiUnicode &&
        !isEmojiUnicodeSupported(emojiUnicode, unicodeVersion)
      ) {
        const hasImageFallback = fallbackSrc && fallbackSrc.length > 0;
        const hasCssSpriteFallback = fallbackSpriteClass && fallbackSpriteClass.length > 0;

        // CSS sprite fallback takes precedence over image fallback
        if (hasCssSpriteFallback) {
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
          this.innerHTML = emojiImageTag(name, fallbackSrc);
        } else {
          const src = emojiFallbackImageSrc(name);
          this.innerHTML = emojiImageTag(name, src);
        }
      }
    });
  }
}

export default function installGlEmojiElement() {
  if (!customElements.get('gl-emoji')) {
    customElements.define('gl-emoji', GlEmoji);
  }
}
