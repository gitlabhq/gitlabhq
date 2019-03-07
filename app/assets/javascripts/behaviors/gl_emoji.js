import 'document-register-element';
import isEmojiUnicodeSupported from '../emoji/support';
import { initEmojiMap, getEmojiInfo, emojiFallbackImageSrc, emojiImageTag } from '../emoji';

class GlEmoji extends HTMLElement {
  constructor() {
    super();

    let emojiUnicode = this.textContent.trim();
    const { fallbackSpriteClass, fallbackSrc, forceFallback } = this.dataset;
    let { name, unicodeVersion } = this.dataset;

    initEmojiMap()
      .then(() => {
        if (!unicodeVersion) {
          const emojiInfo = getEmojiInfo(name);

          if (emojiInfo) {
            if (name !== emojiInfo.name) {
              ({ name } = emojiInfo);
              this.dataset.name = emojiInfo.name;
            }
            unicodeVersion = emojiInfo.u;
            this.dataset.uni = unicodeVersion;

            if (forceFallback === 'true' && !fallbackSpriteClass) {
              this.innerHTML = emojiImageTag(name, emojiFallbackImageSrc(name));
            } else {
              emojiUnicode = emojiInfo.e;
              this.innerHTML = emojiInfo.e;
            }

            this.title = emojiInfo.d;
          }
        }

        const isEmojiUnicode =
          this.childNodes &&
          Array.prototype.every.call(this.childNodes, childNode => childNode.nodeType === 3);
        const hasImageFallback = fallbackSrc && fallbackSrc.length > 0;
        const hasCssSpriteFalback = fallbackSpriteClass && fallbackSpriteClass.length > 0;

        if (
          emojiUnicode &&
          isEmojiUnicode &&
          !isEmojiUnicodeSupported(emojiUnicode, unicodeVersion)
        ) {
          // CSS sprite fallback takes precedence over image fallback
          if (hasCssSpriteFalback) {
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
      })
      .catch(error => {
        // Only reject is already handled in initEmojiMap
        throw error;
      });
  }
}

export default function installGlEmojiElement() {
  if (!customElements.get('gl-emoji')) {
    customElements.define('gl-emoji', GlEmoji);
  }
}
