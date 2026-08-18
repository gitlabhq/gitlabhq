export const getTransferFailedTarget = (todo = {}) => {
  if (todo.body) {
    return todo.body.replace(/\//g, ' / ');
  }

  if (todo.group?.fullName) {
    return todo.group.fullName;
  }

  if (todo.project?.nameWithNamespace) {
    return todo.project.nameWithNamespace;
  }

  return todo.targetEntity?.name || '';
};

export const getTransferFailedSource = (todo = {}) => {
  return todo.targetEntity?.name || getTransferFailedTarget(todo);
};

const stripHash = (url = '') => url.split('#')[0];

export const getTransferFailedSourceUrl = (todo = {}) => {
  return stripHash(todo.targetUrl || '');
};

export const getTransferFailedRetryUrl = (todo = {}) => {
  return todo.transferFailedRetryUrl || '';
};
