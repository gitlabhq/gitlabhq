import { n__ } from '~/locale';
import { memoizeAsync } from '~/lib/utils/memoize_async';
import { escape } from './serializer/link';

const parser = new DOMParser();

export default class AssetResolver {
  #cachedRenderMarkdown;

  constructor({ renderMarkdown }) {
    this.#cachedRenderMarkdown = memoizeAsync(renderMarkdown);
  }

  async #render(markdown) {
    return (await this.#cachedRenderMarkdown(markdown).catch(() => null)) || {};
  }

  async resolveUrl(canonicalSrc) {
    const { body: html } = await this.#render(`[link](${escape(canonicalSrc)})`);
    if (!html) return canonicalSrc;

    const { body } = parser.parseFromString(html, 'text/html');
    return body.querySelector('a').getAttribute('href');
  }

  async resolveIframeSrc(canonicalSrc) {
    const { body: html } = await this.#render(`![image](${escape(canonicalSrc)})`);
    if (!html) return { src: canonicalSrc, providerId: null };

    const { body } = parser.parseFromString(html, 'text/html');
    const embed = body.querySelector('.js-render-iframe');
    if (!embed) return { src: canonicalSrc, providerId: null };

    return { src: embed.dataset.iframeSrc, providerId: embed.dataset.iframeProviderId };
  }

  async resolvePlaceholder(placeholder) {
    const { body: html } = await this.#render(placeholder);
    if (!html) return null;

    const { body } = parser.parseFromString(html, 'text/html');
    const span = body.querySelector('span[data-placeholder]');
    if (!span) return null;

    return { placeholder, value: (span.dataset.placeholder && span.textContent) || null };
  }

  async resolveReference(originalText) {
    const text = originalText.replace(/(\+|\+s)$/, '');
    const toRender = `${text} ${text}+ ${text}+s`;
    const { body: html } = await this.#render(toRender);

    if (!html) return {};

    const { body } = parser.parseFromString(html, 'text/html');
    const a = body.querySelectorAll('a');
    if (!a.length) return {};

    return {
      href: a[0]?.getAttribute('href'),
      text: a[0]?.textContent,
      expandedText: a[1]?.textContent,
      fullyExpandedText: a[2]?.textContent,
      backgroundColor: a[0]?.firstElementChild?.style.backgroundColor,
    };
  }

  async explainQuickAction(text) {
    const { references: { commands: html } = {} } = await this.#render(text);
    if (!html) return '';

    const { body } = parser.parseFromString(html, 'text/html') || {};
    const p = body.querySelectorAll('p');

    const labelsLength = p[0]?.querySelectorAll('.gl-label').length;
    if (labelsLength >= 1) {
      // eslint-disable-next-line @gitlab/no-hardcoded-urls -- False positive, not a URL
      if (text.startsWith('/label')) return n__('Adds a label.', 'Adds %d labels.', labelsLength);
      // eslint-disable-next-line @gitlab/no-hardcoded-urls -- False positive, not a URL
      if (text.startsWith('/unlabel'))
        return n__('Removes a label.', 'Removes %d labels.', labelsLength);
      // eslint-disable-next-line @gitlab/no-hardcoded-urls -- False positive, not a URL
      if (text.startsWith('/relabel'))
        return n__(
          'Replaces all labels with %d label.',
          'Replaces all labels with %d labels.',
          labelsLength,
        );
    }

    return p[0]?.textContent;
  }

  async renderDiagram(code, language) {
    const backticks = '`'.repeat(4);
    const { body: html } = await this.#render(`${backticks}${language}\n${code}\n${backticks}`);
    if (!html) return '';

    const { body } = parser.parseFromString(html, 'text/html');
    const img = body.querySelector('img');
    if (!img) return '';

    return img.dataset.src || img.getAttribute('src');
  }
}
