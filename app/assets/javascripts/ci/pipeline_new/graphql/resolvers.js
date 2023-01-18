import axios from '~/lib/utils/axios_utils';

export const resolvers = {
  Mutation: {
    createPipeline: (_, { endpoint, ref, variablesAttributes }) => {
      return axios
        .post(endpoint, { ref, variables_attributes: variablesAttributes })
        .then((response) => {
          const { id } = response.data;
          return {
            id,
            errors: [],
            totalWarnings: 0,
            warnings: [],
          };
        })
        .catch((err) => {
          const { errors = [], totalWarnings = 0, warnings = [] } = err.response.data;

          return {
            id: null,
            errors,
            totalWarnings,
            warnings,
          };
        });
    },
  },
};
