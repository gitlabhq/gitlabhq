import { removeLastSlashInUrlPath, removeUrlProtocol } from '~/lib/utils/url_utility';
import {
  findChildWithMark,
  openTag,
  closeTag,
  getMarkText,
  preserveUnchangedMark,
} from '../serialization_helpers';

/**
 * Validates that the provided URL is a valid GFM autolink
 *
 * @param {String} url
 * @returns Returns true when the URL is a valid GFM autolink
 */
const isValidAutolinkURL = (url) =>
  /(https?:\/\/)?([\w-])+\.{1}([a-zA-Z]{2,63})([/\w-]*)*\/?\??([^#\n\r]*)?#?([^\n\r]*)/.test(url);

const normalizeUrl = (url) => {
  const processedUrl = removeLastSlashInUrlPath(removeUrlProtocol(url));
  try {
    return decodeURIComponent(processedUrl);
  } catch {
    return processedUrl;
  }
};

/**
 * This function detects whether a link should be serialized
 * as an autolink.
 *
 * See https://github.github.com/gfm/#autolinks-extension-
 * to understand the parsing rules of autolinks.
 * */
const isAutoLink = (linkMark, parent) => {
  const { title, href } = linkMark.attrs;

  if (title || !/^\w+:/.test(href)) {
    return false;
  }

  const { child } = findChildWithMark(linkMark, parent);

  if (
    !child ||
    !child.isText ||
    !isValidAutolinkURL(href) ||
    normalizeUrl(child.text) !== normalizeUrl(href)
  ) {
    return false;
  }

  return true;
};

/**
 * Returns true if the user used brackets to the define
 * the autolink in the original markdown source
 */
const isBracketAutoLink = (sourceMarkdown) => /^<.+?>$/.test(sourceMarkdown);

function getLinkHref(mark, useCanonicalSrc = true) {
  const { canonicalSrc, href } = mark.attrs;

  if (useCanonicalSrc) return canonicalSrc || href || '';
  return href || '';
}

const link = preserveUnchangedMark({
  open(state, mark, parent) {
    if (isAutoLink(mark, parent)) {
      return isBracketAutoLink(mark.attrs.sourceMarkdown) ? '<' : '';
    }

    const { href, title, isGollumLink, sourceTagName, sourceMarkdown } = mark.attrs;

    // eslint-disable-next-line @gitlab/require-i18n-strings
    if (href.startsWith('data:') || href.startsWith('blob:')) return '';

    const attrs = {
      href: state.esc(getLinkHref(mark, state.options.useCanonicalSrc)),
    };

    if (title) {
      attrs.title = state.esc(title);
    }

    if (sourceTagName && !sourceMarkdown) return openTag(sourceTagName, attrs);
    if (isGollumLink) return '[[';
    return '[';
  },
  close(state, mark, parent) {
    if (isAutoLink(mark, parent)) {
      return isBracketAutoLink(mark.attrs.sourceMarkdown) ? '>' : '';
    }

    const {
      href = '',
      title,
      sourceTagName,
      sourceMarkdown,
      isReference,
      isGollumLink,
      canonicalSrc,
    } = mark.attrs;

    // eslint-disable-next-line @gitlab/require-i18n-strings
    if (href.startsWith('data:') || href.startsWith('blob:')) return '';

    if (sourceTagName && !sourceMarkdown) {
      return closeTag(sourceTagName);
    }

    if (isReference) {
      return `][${state.esc(getLinkHref(mark, state.options.useCanonicalSrc))}]`;
    }

    if (isGollumLink) {
      const text = getMarkText(mark, parent);
      const escapedCanonicalSrc = state.esc(canonicalSrc);

      if (text.toLowerCase() === escapedCanonicalSrc.toLowerCase()) {
        return ']]';
      }

      return `|${escapedCanonicalSrc}]]`;
    }

    return `](${state.esc(getLinkHref(mark, state.options.useCanonicalSrc))}${
      title ? ` ${state.quote(title)}` : ''
    })`;
  },
});

export default link;
