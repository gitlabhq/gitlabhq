/**
 * Vue 3 template compiler for the Vue 3 migration.
 *
 * During the migration, the same templates must run on Vue 2 and on Vue 3 compat mode.
 * They are written for Vue 2, and we do not want to change them one by one. This compiler
 * lets the Vue 3 build compile them as they are.
 *
 * The Vue 3 compiler reads some Vue 2 patterns differently, and some of them trigger Vue 3
 * bugs. So, before it compiles, `transformAst` rewrites those patterns into the form that
 * renders as Vue 2 does. The Vue 2 build also has global configuration that the template
 * compiler must know about. For example, `CUSTOM_ELEMENTS` does here what
 * `Vue.config.ignoredElements` does for Vue 2.
 *
 * When we drop Vue 2 support, templates can use Vue 3 syntax directly, and this file goes away.
 */
const { parse: compilerDomParse, compile: compilerDomCompile } = require('@vue/compiler-dom');

// Custom elements that should not be resolved as Vue components
// Defined here because webpack 4 cannot serialize functions in loader options
const CUSTOM_ELEMENTS = ['gl-emoji'];
const isCustomElement = (tag) => CUSTOM_ELEMENTS.includes(tag);

const COMMENT_NODE_TYPE = 3;

const hasProp = (node, prop) => node.props?.some((p) => p.name === prop);

function modifyKeysInsideTemplateTag(templateNode) {
  if (templateNode.tag !== 'template' || !hasProp(templateNode, 'for')) {
    return;
  }

  let keyCandidate = null;
  for (const node of templateNode.children) {
    const keyBindingIndex = node.props
      ? node.props.findIndex((prop) => prop.arg && prop.arg.content === 'key')
      : -1;

    if (keyBindingIndex !== -1 && !hasProp(node, 'for')) {
      if (!keyCandidate) {
        keyCandidate = node.props[keyBindingIndex];
      }
      node.props.splice(keyBindingIndex, 1);
    }
  }

  if (keyCandidate) {
    templateNode.props.push(keyCandidate);
  }
}

function getSlotName(node) {
  return node?.props?.find((prop) => prop.name === 'slot')?.arg?.content;
}

function filterCommentNodeAndTrailingSpace(node, idx, list) {
  if (node.type === COMMENT_NODE_TYPE) {
    return false;
  }

  if (node.content !== ' ') {
    return true;
  }

  if (list[idx - 1]?.type === COMMENT_NODE_TYPE) {
    return false;
  }

  return true;
}

function filterCommentNodes(node) {
  const { length: originalLength } = node.children;
  // eslint-disable-next-line no-param-reassign
  node.children = node.children.filter(filterCommentNodeAndTrailingSpace);
  if (node.children.length !== originalLength) {
    // trim remaining spaces
    while (node.children.at(-1)?.content === ' ') {
      node.children.pop();
    }
  }
}

function dropVOnceForChildrenInsideVIfBecauseOfIssue7725(node) {
  // See https://github.com/vuejs/core/issues/7725 for details
  if (!hasProp(node, 'if')) {
    return;
  }

  node.children?.forEach((child) => {
    if (Array.isArray(child.props)) {
      // eslint-disable-next-line no-param-reassign
      child.props = child.props.filter((prop) => prop.name !== 'once');
    }
  });
}

function fixSameSlotsInsideTemplateFailingWhenUsingWhitespacePreserveDueToIssue6063(node) {
  // See https://github.com/vuejs/core/issues/6063 for details
  // eslint-disable-next-line no-param-reassign
  node.children = node.children.filter((child, idx) => {
    if (child.content !== ' ') {
      // We need to drop only comment nodes
      return true;
    }

    const previousNodeSlotName = getSlotName(node.children[idx - 1]);
    const nextNodeSlotName = getSlotName(node.children[idx + 1]);

    if (previousNodeSlotName && previousNodeSlotName === nextNodeSlotName) {
      // We have a space beween two slot entries with same slot name, we need to drop it
      return false;
    }

    return true;
  });
}

/**
 * Walks every node of a parsed template and changes it in place:
 *
 * - Moves a `key` from the children of `<template v-for>` to the `<template>`. Vue 2
 *   allows the key on the children, but Vue 3 expects it on the `<template>`.
 * - Removes `v-once` from the direct children of a `v-if` node (vuejs/core#7725).
 * - Removes comments and the whitespace after them. Vue 3 counts them as content, so an
 *   empty slot or a component root with a comment behaves differently (vuejs/core#7909).
 * - Removes the whitespace between two slots with the same name (vuejs/core#6063).
 *
 * @param {import('@vue/compiler-core').RootNode} rootNode
 * @returns {import('@vue/compiler-core').RootNode} The same `rootNode`.
 */
function transformAst(rootNode) {
  const pendingNodes = [rootNode];
  while (pendingNodes.length) {
    const currentNode = pendingNodes.pop();
    if (Array.isArray(currentNode.children)) {
      // This one will be dropped all together with compiler when we drop Vue.js 2 support
      modifyKeysInsideTemplateTag(currentNode);

      dropVOnceForChildrenInsideVIfBecauseOfIssue7725(currentNode);

      // See https://github.com/vuejs/core/issues/7909 for details
      // However, this issue applies not only to root-level nodes
      // But on any level comments could change slot emptiness detection
      // so we simply drop them
      filterCommentNodes(currentNode);

      fixSameSlotsInsideTemplateFailingWhenUsingWhitespacePreserveDueToIssue6063(currentNode);

      currentNode.children.forEach((child) => pendingNodes.push(child));
    }
  }
  return rootNode;
}

/**
 * Same as `parse` from `@vue/compiler-dom`, with `isCustomElement` as the default. The
 * parser decides whether a tag is an element or a component, so it needs it too.
 *
 * @param {string} template
 * @param {import('@vue/compiler-core').ParserOptions} [options]
 * @returns {import('@vue/compiler-core').RootNode}
 */
function parse(template, options) {
  return compilerDomParse(template, { isCustomElement, ...options });
}

/**
 * Same as `compile` from `@vue/compiler-dom`, with `isCustomElement` as the default, and
 * `transformAst` applied first. Like upstream, it changes a passed AST in place.
 *
 * @param {string | import('@vue/compiler-core').RootNode} template
 * @param {import('@vue/compiler-core').CompilerOptions} [options]
 * @returns {import('@vue/compiler-core').CodegenResult}
 */
function compile(template, options) {
  const rootNode = typeof template === 'string' ? parse(template, options) : template;
  return compilerDomCompile(transformAst(rootNode), { isCustomElement, ...options });
}

module.exports = {
  isCustomElement,
  parse,
  compile,
};
