import { markInputRule } from '@tiptap/core';
import { Link } from '@tiptap/extension-link';

export const markdownLinkSyntaxInputRuleRegExp = /(?:^|\s)\[([\w|\s|-]+)\]\((?<href>.+?)\)$/gm;
export const urlSyntaxRegExp = /(?:^|\s)(?<href>(?:https?:\/\/|www\.)[\S]+)(?:\s|\n)$/gim;

const extractHrefFromMatch = (match) => {
  return { href: match.groups.href };
};

export const extractHrefFromMarkdownLink = (match) => {
  /**
   * Removes the last capture group from the match to satisfy
   * tiptap markInputRule expectation of having the content as
   * the last capture group in the match.
   *
   * https://github.com/ueberdosis/tiptap/blob/%40tiptap/core%402.0.0-beta.75/packages/core/src/inputRules/markInputRule.ts#L11
   */
  match.pop();
  return extractHrefFromMatch(match);
};

export const tiptapExtension = Link.extend({
  addInputRules() {
    return [
      markInputRule(markdownLinkSyntaxInputRuleRegExp, this.type, extractHrefFromMarkdownLink),
      markInputRule(urlSyntaxRegExp, this.type, extractHrefFromMatch),
    ];
  },
  addAttributes() {
    return {
      ...this.parent?.(),
      href: {
        default: null,
        parseHTML: (element) => {
          return {
            href: element.getAttribute('href'),
          };
        },
      },
      canonicalSrc: {
        default: null,
        parseHTML: (element) => {
          return {
            canonicalSrc: element.dataset.canonicalSrc,
          };
        },
      },
    };
  },
}).configure({
  openOnClick: false,
});

export const serializer = {
  open() {
    return '[';
  },
  close(state, mark) {
    const href = mark.attrs.canonicalSrc || mark.attrs.href;
    return `](${state.esc(href)}${mark.attrs.title ? ` ${state.quote(mark.attrs.title)}` : ''})`;
  },
};
