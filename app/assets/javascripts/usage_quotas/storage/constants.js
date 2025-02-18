import { helpPagePath } from '~/helpers/help_page_helper';

export const storageTypeHelpPaths = {
  lfsObjects: helpPagePath('/user/project/repository/repository_size', {
    anchor: 'clean-up-repository',
  }),
  containerRegistry: helpPagePath(
    'user/packages/container_registry/reduce_container_registry_storage',
  ),
  buildArtifacts: helpPagePath('ci/jobs/job_artifacts', {
    anchor: 'keep-artifacts-from-most-recent-successful-jobs',
  }),
  packages: helpPagePath('user/packages/package_registry/_index.md', {
    anchor: 'reduce-storage-usage',
  }),
  repository: helpPagePath('user/project/repository/repository_size'),
  snippets: helpPagePath('user/snippets', {
    anchor: 'reduce-snippets-repository-size',
  }),
  wiki: helpPagePath('administration/wikis/_index.md', {
    anchor: 'reduce-wiki-repository-size',
  }),
};
