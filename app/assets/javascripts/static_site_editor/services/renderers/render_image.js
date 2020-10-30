const canRender = ({ type }) => type === 'image';

// NOTE: the `metadata` is not used yet, but will be used in a follow-up iteration
// To be removed with the next iteration of https://gitlab.com/gitlab-org/gitlab/-/issues/218531
// eslint-disable-next-line no-unused-vars
let metadata;

const render = (node, { skipChildren }) => {
  skipChildren();

  // To be removed with the next iteration of https://gitlab.com/gitlab-org/gitlab/-/issues/218531
  // TODO resolve relative paths

  return {
    type: 'openTag',
    tagName: 'img',
    selfClose: true,
    attributes: {
      src: node.destination,
      alt: node.firstChild.literal,
    },
  };
};

const build = (mounts, project) => {
  metadata = { mounts, project };
  return { canRender, render };
};

export default { build };
