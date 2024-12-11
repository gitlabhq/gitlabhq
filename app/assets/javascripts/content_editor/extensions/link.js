import { markInputRule } from '@tiptap/core';
import { Link } from '@tiptap/extension-link';

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

export default Link.extend({
  inclusive: false,

  addOptions() {
    return {
      ...this.parent?.(),
      openOnClick: false,
    };
  },

  addInputRules() {
    const markdownLinkSyntaxInputRuleRegExp = /(?:^|\s)\[([\w|\s|-]+)\]\((?<href>.+?)\)$/gm;

    return [
      markInputRule({
        find: markdownLinkSyntaxInputRuleRegExp,
        type: this.type,
        getAttributes: extractHrefFromMarkdownLink,
      }),
    ];
  },
  addAttributes() {
    return {
      uploading: {
        default: false,
        renderHTML: ({ uploading }) => (uploading ? { class: 'with-attachment-icon' } : {}),
      },
      href: {
        default: null,
        parseHTML: (element) => element.getAttribute('href'),
      },
      title: {
        title: null,
        parseHTML: (element) =>
          element.classList.contains('gfm') ? null : element.getAttribute('title'),
      },
      // only for gollum links (wikis)
      isGollumLink: {
        default: false,
        parseHTML: (element) => Boolean(element.dataset.gollum),
        renderHTML: () => '',
      },
      isWikiPage: {
        default: false,
        parseHTML: (element) => Boolean(element.classList.contains('gfm-gollum-wiki-page')),
        renderHTML: ({ isWikiPage }) => (isWikiPage ? { class: 'gfm-gollum-wiki-page' } : {}),
      },
      canonicalSrc: {
        default: null,
        parseHTML: (element) => element.dataset.canonicalSrc,
        renderHTML: () => '',
      },
      isReference: {
        default: false,
        renderHTML: () => '',
      },
    };
  },
  addCommands() {
    return {
      ...this.parent?.(),
      editLink:
        (attrs) =>
        ({ chain }) => {
          chain().setMeta('creatingLink', true).setLink(attrs).run();
        },
    };
  },

  addKeyboardShortcuts() {
    return {
      'Mod-k': () => this.editor.commands.editLink(),
    };
  },
});
