const { memoize, isString, isRegExp } = require('lodash');
const { parse } = require('postcss');
const { CSS_TO_REMOVE } = require('./constants');

const getSelectorRemoveTesters = memoize(() =>
  CSS_TO_REMOVE.map((x) => {
    if (isString(x)) {
      return (selector) => x === selector;
    }
    if (isRegExp(x)) {
      return (selector) => x.test(selector);
    }

    throw new Error(`Unexpected type in CSS_TO_REMOVE content "${x}". Expected String or RegExp.`);
  }),
);

const getRemoveTesters = memoize(() => {
  const selectorTesters = getSelectorRemoveTesters();

  // These are mostly carried over from the previous project
  // https://gitlab.com/gitlab-org/frontend/gitlab-css-statistics/-/blob/2aa00af25dba08fc71081c77206f45efe817ea4b/lib/gl_startup_extract.js
  return [
    (node) => node.type === 'comment',
    (node) =>
      node.type === 'atrule' &&
      (node.params === 'print' ||
        node.params === 'prefers-reduced-motion: reduce' ||
        node.name === 'keyframe' ||
        node.name === 'charset'),
    (node) => node.selector && node.selectors && !node.selectors.length,
    (node) => node.selector && selectorTesters.some((fn) => fn(node.selector)),
    (node) =>
      node.type === 'decl' &&
      (node.prop === 'transition' ||
        node.prop.indexOf('-webkit-') > -1 ||
        node.prop.indexOf('-ms-') > -1),
  ];
});

const getNodesToRemove = (nodes) => {
  const removeTesters = getRemoveTesters();
  const remNodes = [];

  nodes.forEach((node) => {
    if (removeTesters.some((fn) => fn(node))) {
      remNodes.push(node);
    } else if (node.nodes?.length) {
      remNodes.push(...getNodesToRemove(node.nodes));
    }
  });

  return remNodes;
};

const getEmptyNodesToRemove = (nodes) =>
  nodes
    .filter((node) => node.nodes)
    .reduce((acc, node) => {
      if (node.nodes.length) {
        acc.push(...getEmptyNodesToRemove(node.nodes));
      } else {
        acc.push(node);
      }

      return acc;
    }, []);

const cleanCSS = (css) => {
  const cssRoot = parse(css);

  getNodesToRemove(cssRoot.nodes).forEach((node) => {
    node.remove();
  });

  getEmptyNodesToRemove(cssRoot.nodes).forEach((node) => {
    node.remove();
  });

  return cssRoot.toResult().css;
};

module.exports = { cleanCSS };
