import Api from '~/api';

export const resolvers = {
  Query: {
    blobContent(_, { projectPath, path, ref }) {
      return {
        __typename: 'BlobContent',
        rawData: Api.getRawFile(projectPath, path, { ref }).then(({ data }) => {
          return data;
        }),
      };
    },
  },
};

export default resolvers;
