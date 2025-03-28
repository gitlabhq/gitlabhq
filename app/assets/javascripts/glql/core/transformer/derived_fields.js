export const derivedFields = {
  lastComment: (node) => ({
    ...node,
    lastComment: node.lastComment.nodes[0]?.bodyHtml,
  }),
};
