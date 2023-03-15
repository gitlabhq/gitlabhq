const { parse, compile: compilerDomCompile } = require('@vue/compiler-dom');

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
