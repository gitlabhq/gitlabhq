const { parse, compile: compilerDomCompile } = require('@vue/compiler-dom');

const COMMENT_NODE_TYPE = 3;

const hasProp = (node, prop) => node.props?.some((p) => p.name === prop);

function modifyKeysInsideTemplateTag(templateNode) {
  if (!templateNode.tag === 'template' || !hasProp(templateNode, 'for')) {
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

module.exports = {
  parse,
  compile(template, options) {
    const rootNode = parse(template, options);

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

    return compilerDomCompile(rootNode, options);
  },
};
