export const dataStructure = ({
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
});

export const decorateData = (entity, type, parentTreeUrl = '', level = 0) => {
  const {
    id,
    url,
    name,
    icon,
    last_commit,
    tree_url,
    path,
    tempFile,
    active = false,
    opened = false,
  } = entity;

  return {
    ...dataStructure,
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
    // eslint-disable-next-line camelcase
    lastCommit: last_commit ? {
      // url: `${Store.projectUrl}/commit/${last_commit.id}`,
      message: last_commit.message,
      updatedAt: last_commit.committed_date,
    } : {},
  };
};

export const findIndexOfFile = (state, file) => state.findIndex(f => f.path === file.path);

export const setPageTitle = (title) => {
  document.title = title;
};

export const pushState = (url) => {
  history.pushState({ url }, '', url);
};
