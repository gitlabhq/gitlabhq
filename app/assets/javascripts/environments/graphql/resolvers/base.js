import axios from '~/lib/utils/axios_utils';
import { s__ } from '~/locale';
import {
  convertObjectPropsToCamelCase,
  parseIntPagination,
  normalizeHeaders,
} from '~/lib/utils/common_utils';

import pageInfoQuery from '~/graphql_shared/client/page_info.query.graphql';
import pollIntervalQuery from '../queries/poll_interval.query.graphql';
import environmentToRollbackQuery from '../queries/environment_to_rollback.query.graphql';
import environmentToStopQuery from '../queries/environment_to_stop.query.graphql';
import environmentToDeleteQuery from '../queries/environment_to_delete.query.graphql';
import environmentToChangeCanaryQuery from '../queries/environment_to_change_canary.query.graphql';
import isEnvironmentStoppingQuery from '../queries/is_environment_stopping.query.graphql';

const buildErrors = (errors = []) => ({
  errors,
  __typename: 'LocalEnvironmentErrors',
});

const mapNestedEnvironment = (env) => ({
  ...convertObjectPropsToCamelCase(env, { deep: true }),
  __typename: 'NestedLocalEnvironment',
});
const mapEnvironment = (env) => ({
  ...convertObjectPropsToCamelCase(env, { deep: true }),
  __typename: 'LocalEnvironment',
});

export const baseQueries = (endpoint) => ({
  environmentApp(_context, { page, scope, search }, { cache }) {
    return axios.get(endpoint, { params: { nested: true, page, scope, search } }).then((res) => {
      const headers = normalizeHeaders(res.headers);
      const interval = headers['POLL-INTERVAL'];
      const pageInfo = { ...parseIntPagination(headers), __typename: 'LocalPageInfo' };

      if (interval) {
        cache.writeQuery({ query: pollIntervalQuery, data: { interval: parseFloat(interval) } });
      } else {
        cache.writeQuery({ query: pollIntervalQuery, data: { interval: undefined } });
      }

      cache.writeQuery({
        query: pageInfoQuery,
        data: { pageInfo },
      });

      return {
        activeCount: res.data.active_count,
        environments: res.data.environments.map(mapNestedEnvironment),
        reviewApp: {
          ...convertObjectPropsToCamelCase(res.data.review_app),
          __typename: 'ReviewApp',
        },
        canStopStaleEnvironments: res.data.can_stop_stale_environments,
        stoppedCount: res.data.stopped_count,
        __typename: 'LocalEnvironmentApp',
      };
    });
  },
  folder(_, { environment: { folderPath }, scope, search, perPage, page }) {
    // eslint-disable-next-line camelcase
    const per_page = perPage || 3;
    const pageNumber = page || 1;
    return axios
      .get(folderPath, { params: { scope, search, per_page, page: pageNumber } })
      .then((res) => ({
        activeCount: res.data.active_count,
        environments: res.data.environments.map(mapEnvironment),
        stoppedCount: res.data.stopped_count,
        __typename: 'LocalEnvironmentFolder',
      }));
  },
  isLastDeployment(_, { environment }) {
    return environment?.lastDeployment?.isLast;
  },
});

export const baseMutations = {
  stopEnvironmentREST(_, { environment }, { client, cache }) {
    client.writeQuery({
      query: isEnvironmentStoppingQuery,
      variables: { environment },
      data: { isEnvironmentStopping: true },
    });
    return axios
      .post(environment.stopPath)
      .then(() => buildErrors())
      .then(() => {
        cache.evict({ fieldName: 'folder' });
      })
      .catch(() => {
        client.writeQuery({
          query: isEnvironmentStoppingQuery,
          variables: { environment },
          data: { isEnvironmentStopping: false },
        });
        return buildErrors([
          s__('Environments|An error occurred while stopping the environment, please try again'),
        ]);
      });
  },
  deleteEnvironment(_, { environment: { deletePath } }, { cache }) {
    return axios
      .delete(deletePath)
      .then(() => buildErrors())
      .then(() => cache.evict({ fieldName: 'folder' }))
      .catch(() =>
        buildErrors([
          s__(
            'Environments|An error occurred while deleting the environment. Check if the environment stopped; if not, stop it and try again.',
          ),
        ]),
      );
  },
  rollbackEnvironment(_, { environment, isLastDeployment }, { cache }) {
    return axios
      .post(environment?.retryUrl)
      .then(() => buildErrors())
      .then(() => {
        cache.evict({ fieldName: 'folder' });
      })
      .catch(() => {
        buildErrors([
          isLastDeployment
            ? s__(
                'Environments|An error occurred while re-deploying the environment, please try again',
              )
            : s__(
                'Environments|An error occurred while rolling back the environment, please try again',
              ),
        ]);
      });
  },
  setEnvironmentToStop(_, { environment }, { client }) {
    client.writeQuery({
      query: environmentToStopQuery,
      data: { environmentToStop: environment },
    });
  },
  action(_, { action: { playPath } }) {
    return axios
      .post(playPath)
      .then(() => buildErrors())
      .catch(() => buildErrors([s__('Environments|An error occurred while making the request.')]));
  },
  setEnvironmentToDelete(_, { environment }, { client }) {
    client.writeQuery({
      query: environmentToDeleteQuery,
      data: { environmentToDelete: environment },
    });
  },
  setEnvironmentToRollback(_, { environment }, { client }) {
    client.writeQuery({
      query: environmentToRollbackQuery,
      data: { environmentToRollback: environment },
    });
  },
  setEnvironmentToChangeCanary(_, { environment, weight }, { client }) {
    client.writeQuery({
      query: environmentToChangeCanaryQuery,
      data: { environmentToChangeCanary: environment, weight },
    });
  },
  cancelAutoStop(_, { autoStopUrl }) {
    return axios
      .post(autoStopUrl)
      .then(() => buildErrors())
      .catch((err) =>
        buildErrors([
          err?.response?.data?.message ||
            s__('Environments|An error occurred while canceling the auto stop, please try again'),
        ]),
      );
  },
};
