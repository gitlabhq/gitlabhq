import axios from '~/lib/utils/axios_utils';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';

const mapNestedEnvironment = (env) => ({
  ...convertObjectPropsToCamelCase(env, { deep: true }),
  __typename: 'NestedLocalEnvironment',
});
const mapEnvironment = (env) => ({
  ...convertObjectPropsToCamelCase(env),
  __typename: 'LocalEnvironment',
});

export const resolvers = (endpoint) => ({
  Query: {
    environmentApp() {
      return axios.get(endpoint, { params: { nested: true } }).then((res) => ({
        availableCount: res.data.available_count,
        environments: res.data.environments.map(mapNestedEnvironment),
        reviewApp: {
          ...convertObjectPropsToCamelCase(res.data.review_app),
          __typename: 'ReviewApp',
        },
        stoppedCount: res.data.stopped_count,
        __typename: 'LocalEnvironmentApp',
      }));
    },
    folder(_, { environment: { folderPath } }) {
      return axios.get(folderPath, { params: { per_page: 3 } }).then((res) => ({
        availableCount: res.data.available_count,
        environments: res.data.environments.map(mapEnvironment),
        stoppedCount: res.data.stopped_count,
        __typename: 'LocalEnvironmentFolder',
      }));
    },
  },
  Mutations: {
    stopEnvironment(_, { environment: { stopPath } }) {
      return axios.post(stopPath);
    },
    deleteEnvironment(_, { environment: { deletePath } }) {
      return axios.delete(deletePath);
    },
    rollbackEnvironment(_, { environment: { retryUrl } }) {
      return axios.post(retryUrl);
    },
    cancelAutoStop(_, { environment: { autoStopPath } }) {
      return axios.post(autoStopPath);
    },
  },
});
