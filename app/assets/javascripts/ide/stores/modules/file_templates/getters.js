import { __ } from '~/locale';
import { DEFAULT_CI_CONFIG_PATH } from '~/lib/utils/constants';
import { leftSidebarViews } from '../../../constants';

export const templateTypes = () => [
  {
    name: DEFAULT_CI_CONFIG_PATH,
    key: 'gitlab_ci_ymls',
  },
  {
    name: '.gitignore',
    key: 'gitignores',
  },
  {
    name: __('LICENSE'),
    key: 'licenses',
  },
  {
    name: __('Dockerfile'),
    key: 'dockerfiles',
  },
];

export const showFileTemplatesBar = (_, getters, rootState) => (name) =>
  getters.templateTypes.find((t) => t.name === name) &&
  rootState.currentActivityView === leftSidebarViews.edit.name;
