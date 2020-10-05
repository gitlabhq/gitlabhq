import query from '../queries/app_data.query.graphql';

const hasSubmittedChangesResolver = (_, { input: { hasSubmittedChanges } }, { cache }) => {
  const { appData } = cache.readQuery({ query });
  cache.writeQuery({
    query,
    data: {
      appData: {
        __typename: 'AppData',
        ...appData,
        hasSubmittedChanges,
      },
    },
  });
};

export default hasSubmittedChangesResolver;
