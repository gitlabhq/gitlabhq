export const viewerDataStructure = () => ({
  loading: false,
  path: '',
  icon: '',
  html: '',
  name: '',
  serverRender: true,
  renderError: '',
});

export const dataStructure = () => ({
  id: '',
  key: '',
  type: '',
  name: '',
  extension: '',
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
  lastCommitPath: '',
  lastCommit: {
    url: '',
    message: '',
    updatedAt: '',
  },
  tree_url: '',
  blamePath: '',
  commitsPath: '',
  permalink: '',
  rawPath: '',
  binary: false,
  raw: '',
  content: '',
  parentTreeUrl: '',
  currentViewer: 'rich',
  rich: viewerDataStructure(),
  simple: viewerDataStructure(),
});

export const decorateData = (entity) => {
  const {
    id,
    type,
    url,
    name,
    icon,
    tree_url,
    path,
    content = '',
    tempFile = false,
    active = false,
    opened = false,
    changed = false,
    parentTreeUrl = '',
    level = 0,
    binary = false,
  } = entity;

  return {
    ...dataStructure(),
    id,
    key: `${name}-${type}-${id}`,
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
    content,
    binary,
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

export const createTemp = ({ name, path, type, level, changed, content, binary }) => {
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
    binary,
  });
};

export const createOrMergeEntry = ({ tree, entry, type, parentTreeUrl, level }) => {
  const found = findEntry(tree, type, entry.name);

  if (found) {
    return Object.assign({}, found, {
      id: entry.id,
      url: entry.url,
      tempFile: false,
    });
  }

  return decorateData({
    ...entry,
    type,
    parentTreeUrl,
    level,
  });
};

export const createViewerStructure = (file, type, data) => {
  const viewerData = data[`${type}_viewer`];

  if (viewerData) {
    Object.assign(file[type], {
      path: viewerData.path,
      icon: viewerData.switcher_icon,
      name: viewerData.name,
      serverRender: viewerData.server_side,
      renderError: viewerData.render_error_reason,
    });
  }
};
