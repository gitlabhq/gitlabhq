import { __ } from '~/locale';

export const namespaceSelectOptions = state => {
  const serializedNamespaces = state.namespaces.map(({ fullPath }) => ({
    id: fullPath,
    text: fullPath,
  }));

  return [
    { text: __('Groups'), children: serializedNamespaces },
    {
      text: __('Users'),
      children: [{ id: state.defaultTargetNamespace, text: state.defaultTargetNamespace }],
    },
  ];
};

export const isImportingAnyRepo = state => state.reposBeingImported.length > 0;

export const hasProviderRepos = state => state.providerRepos.length > 0;

export const hasImportedProjects = state => state.importedProjects.length > 0;

export const hasIncompatibleRepos = state => state.incompatibleRepos.length > 0;

export const reposPathWithFilter = ({ reposPath, filter = '' }) =>
  filter ? `${reposPath}?filter=${filter}` : reposPath;
export const jobsPathWithFilter = ({ jobsPath, filter = '' }) =>
  filter ? `${jobsPath}?filter=${filter}` : jobsPath;
