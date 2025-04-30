export const dataStructure = () => ({
  id: '',
  // Key will contain a mixture of ID and path
  // it can also contain a prefix `pending-` for files opened in review mode
  key: '',
  type: '',
  name: '',
  path: '',
  tempFile: false,
  tree: [],
  loading: false,
  opened: false,
  active: false,
  changed: false,
  staged: false,
  lastCommitSha: '',
  rawPath: '',
  raw: '',
  content: '',
  size: 0,
  parentPath: null,
  lastOpenedAt: 0,
  mrChange: null,
  deleted: false,
  prevPath: undefined,
  mimeType: '',
});

export const decorateData = (entity) => {
  const {
    id,
    type,
    name,
    path,
    content = '',
    tempFile = false,
    active = false,
    opened = false,
    changed = false,
    rawPath = '',
    file_lock,
    parentPath = '',
    mimeType = '',
  } = entity;

  return Object.assign(dataStructure(), {
    id,
    key: `${name}-${type}-${id}`,
    type,
    name,
    path,
    tempFile,
    opened,
    active,
    changed,
    content,
    rawPath,
    file_lock,
    parentPath,
    mimeType,
  });
};

const sortTreesByTypeAndName = (a, b) => {
  if (a.type === 'tree' && b.type === 'blob') {
    return -1;
  }
  if (a.type === 'blob' && b.type === 'tree') {
    return 1;
  }
  if (a.name < b.name) return -1;
  if (a.name > b.name) return 1;
  return 0;
};

export const linkTreeNodes = (tree) => {
  return tree.map((entity) =>
    Object.assign(entity, {
      tree: entity.tree.length ? linkTreeNodes(entity.tree) : [],
    }),
  );
};

export const sortTree = (sortedTree) =>
  sortedTree
    .map((entity) =>
      Object.assign(entity, {
        tree: entity.tree.length ? sortTree(entity.tree) : [],
      }),
    )
    .sort(sortTreesByTypeAndName);
