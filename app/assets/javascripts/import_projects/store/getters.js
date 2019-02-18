export const namespaceSelectOptions = state => {
  const serializedNamespaces = state.namespaces.map(({ fullPath }) => ({
    id: fullPath,
    text: fullPath,
  }));

  return [
    { text: 'Groups', children: serializedNamespaces },
    {
      text: 'Users',
      children: [{ id: state.defaultTargetNamespace, text: state.defaultTargetNamespace }],
    },
  ];
};

export const isImportingAnyRepo = state => state.reposBeingImported.length > 0;

export const hasProviderRepos = state => state.providerRepos.length > 0;

export const hasImportedProjects = state => state.importedProjects.length > 0;
