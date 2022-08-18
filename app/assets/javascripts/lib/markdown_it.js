/**
 * This module replaces markdown-it with an empty function. markdown-it
 * is a dependency of the prosemirror-markdown package. prosemirror-markdown
 * uses markdown-it to parse markdown and produce an AST. However, the
 * features that use prosemirror-markdown in the GitLab application do not
 * require markdown parsing.
 *
 * Replacing markdown-it with this empty function removes unnecessary javascript
 * from the production builds.
 */
export default () => {};
