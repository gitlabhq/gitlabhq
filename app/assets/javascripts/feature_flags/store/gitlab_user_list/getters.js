import statuses from './status';

export const userListOptions = ({ userLists }) =>
  userLists.map(({ name, id }) => ({ value: id, text: name }));

export const hasUserLists = ({ userLists, status }) =>
  [statuses.START, statuses.LOADING].indexOf(status) > -1 || userLists.length > 0;

export const isLoading = ({ status }) => status === statuses.LOADING;

export const hasError = ({ status }) => status === statuses.ERROR;
