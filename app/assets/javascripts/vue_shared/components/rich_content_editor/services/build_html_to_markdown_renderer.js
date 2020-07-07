const buildHTMLToMarkdownRender = baseRenderer => {
  return {
    TEXT_NODE(node) {
      return baseRenderer.getSpaceControlled(
        baseRenderer.trim(baseRenderer.getSpaceCollapsedText(node.nodeValue)),
        node,
      );
    },
  };
};

export default buildHTMLToMarkdownRender;
