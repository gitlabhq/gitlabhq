import { __ } from '../locale';

export const errorMessagesTypes = {
  FETCH_REGISTRY: 'FETCH_REGISTRY',
  FETCH_REPOS: 'FETCH_REPOS',
  DELETE_REPO: 'DELETE_REPO',
  DELETE_REGISTRY: 'DELETE_REGISTRY',
};

export const errorMessages = {
  [errorMessagesTypes.FETCH_REGISTRY]: __('Something went wrong while fetching the registry list.'),
  [errorMessagesTypes.FETCH_REPOS]: __('Something went wrong while fetching the projects.'),
  [errorMessagesTypes.DELETE_REPO]: __('Something went wrong on our end.'),
  [errorMessagesTypes.DELETE_REGISTRY]: __('Something went wrong on our end.'),
};
