import { memoize } from 'lodash';
import { n__ } from '~/locale';

const parser = new DOMParser();

export default class AssetResolver {
  constructor({ renderMarkdown }) {
    this.renderMarkdown = renderMarkdown;
  }

  resolveUrl = memoize(async (canonicalSrc) => {
    const { body: html } = (await this.renderMarkdown(`[link](${canonicalSrc})`)) || {};
    if (!html) return canonicalSrc;

    const { body } = parser.parseFromString(html, 'text/html');
    return body.querySelector('a').getAttribute('href');
  });

  resolveReference = memoize(async (originalText) => {
    const text = originalText.replace(/(\+|\+s)$/, '');
    const toRender = `${text} ${text}+ ${text}+s`;
    const { body: html } = (await this.renderMarkdown(toRender)) || {};

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
  });

  explainQuickAction = memoize(async (text) => {
    const {
      references: { commands: html },
    } = (await this.renderMarkdown(text)) || { references: {} };
    if (!html) return '';

    const { body } = parser.parseFromString(html, 'text/html') || {};
    const p = body.querySelectorAll('p');

    const labelsLength = p[0]?.querySelectorAll('.gl-label').length;
    if (labelsLength >= 1) {
      if (text.startsWith('/label')) return n__('Adds a label.', 'Adds %d labels.', labelsLength);
      if (text.startsWith('/unlabel'))
        return n__('Removes a label.', 'Removes %d labels.', labelsLength);
      if (text.startsWith('/relabel'))
        return n__(
          'Replaces all labels with %d label.',
          'Replaces all labels with %d labels.',
          labelsLength,
        );
    }

    return p[0]?.textContent;
  });

  renderDiagram = memoize(async (code, language) => {
    const backticks = '`'.repeat(4);
    const { body: html } = await this.renderMarkdown(
      `${backticks}${language}\n${code}\n${backticks}`,
    );

    const { body } = parser.parseFromString(html, 'text/html');
    const img = body.querySelector('img');
    if (!img) return '';

    return img.dataset.src || img.getAttribute('src');
  });
}
