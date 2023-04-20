const { parse, compile: compilerDomCompile } = require('@vue/compiler-dom');

const COMMENT_NODE_TYPE = 3;

const getPropIndex = (node, prop) => node.props?.findIndex((p) => p.name === prop) ?? -1;

function modifyKeysInsideTemplateTag(templateNode) {
  let keyCandidate = null;
  for (const node of templateNode.children) {
    const keyBindingIndex = node.props
      ? node.props.findIndex((prop) => prop.arg && prop.arg.content === 'key')
      : -1;

    if (keyBindingIndex !== -1 && getPropIndex(node, 'for') === -1) {
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

module.exports = {
  parse,
  compile(template, options) {
    const rootNode = parse(template, options);

    // We do not want to switch to whitespace: collapse mode which is Vue.js 3 default
    // It will be too devastating to codebase

    // However, without `whitespace: condense` Vue will treat spaces between comments
    // and nodes itself as text nodes, resulting in multi-root component
    // For multi-root component passing classes / attributes fallthrough will not work

    // See https://github.com/vuejs/core/issues/7909 for details

    // To fix that we simply drop all component comments only on top-level
    rootNode.children = rootNode.children.filter((n) => n.type !== COMMENT_NODE_TYPE);

    const pendingNodes = [rootNode];
    while (pendingNodes.length) {
      const currentNode = pendingNodes.pop();
      if (getPropIndex(currentNode, 'for') !== -1) {
        if (currentNode.tag === 'template') {
          // This one will be dropped all together with compiler when we drop Vue.js 2 support
          modifyKeysInsideTemplateTag(currentNode);
        }

        // This one will be dropped when https://github.com/vuejs/core/issues/7725 will be fixed
        const vOncePropIndex = getPropIndex(currentNode, 'once');
        if (vOncePropIndex !== -1) {
          currentNode.props.splice(vOncePropIndex, 1);
        }
      }

      currentNode.children?.forEach((child) => pendingNodes.push(child));
    }

    return compilerDomCompile(rootNode, options);
  },
};
