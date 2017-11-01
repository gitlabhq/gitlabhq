export const dataStructure = () => ({
  id: '',
  type: '',
  name: '',
  url: '',
  path: '',
  level: 0,
  tempFile: false,
  icon: '',
  tree: [],
  loading: false,
  opened: false,
  active: false,
  changed: false,
  lastCommit: {},
  tree_url: '',
  blamePath: '',
  commitsPath: '',
  permalink: '',
  rawPath: '',
  binary: false,
  html: '',
  raw: '',
  content: '',
  parentTreeUrl: '',
  renderError: false,
  base64: false,
});

export const decorateData = (entity, projectUrl = '') => {
  const {
    id,
    type,
    url,
    name,
    icon,
    last_commit,
    tree_url,
    path,
    renderError,
    content = '',
    tempFile = false,
    active = false,
    opened = false,
    changed = false,
    parentTreeUrl = '',
    level = 0,
    base64 = false,
  } = entity;

  return {
    ...dataStructure(),
    id,
    type,
    name,
    url,
    tree_url,
    path,
    level,
    tempFile,
    icon: `fa-${icon}`,
    opened,
    active,
    parentTreeUrl,
    changed,
    renderError,
    content,
    base64,
    // eslint-disable-next-line camelcase
    lastCommit: last_commit ? {
      url: `${projectUrl}/commit/${last_commit.id}`,
      message: last_commit.message,
      updatedAt: last_commit.committed_date,
    } : {},
  };
};

export const findEntry = (state, type, name) => state.tree.find(
  f => f.type === type && f.name === name,
);
export const findIndexOfFile = (state, file) => state.findIndex(f => f.path === file.path);

export const setPageTitle = (title) => {
  document.title = title;
};

export const pushState = (url) => {
  history.pushState({ url }, '', url);
};

export const createTemp = ({ name, path, type, level, changed, content, base64 }) => {
  const treePath = path ? `${path}/${name}` : name;

  return decorateData({
    id: new Date().getTime().toString(),
    name,
    type,
    tempFile: true,
    path: treePath,
    icon: type === 'tree' ? 'folder' : 'file-text-o',
    changed,
    content,
    parentTreeUrl: '',
    level,
    base64,
    renderError: base64,
  });
};
