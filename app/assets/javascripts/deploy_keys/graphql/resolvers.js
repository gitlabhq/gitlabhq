import { gql } from '@apollo/client/core';
import axios from '~/lib/utils/axios_utils';
import {
  convertObjectPropsToCamelCase,
  parseIntPagination,
  normalizeHeaders,
} from '~/lib/utils/common_utils';
import pageInfoQuery from '~/graphql_shared/client/page_info.query.graphql';
import currentPageQuery from './queries/current_page.query.graphql';
import currentScopeQuery from './queries/current_scope.query.graphql';
import confirmRemoveKeyQuery from './queries/confirm_remove_key.query.graphql';

export const mapDeployKey = (deployKey) => ({
  ...convertObjectPropsToCamelCase(deployKey, { deep: true }),
  __typename: 'LocalDeployKey',
});

const DEFAULT_PAGE_SIZE = 5;

export const resolvers = (endpoints) => ({
  Project: {
    deployKeys(_, { scope, page, search }, { client }) {
      const key = `${scope}Endpoint`;
      let { [key]: endpoint } = endpoints;

      if (!endpoint) {
        endpoint = endpoints.enabledKeysEndpoint;
      }

      return axios
        .get(endpoint, { params: { page, per_page: DEFAULT_PAGE_SIZE, ...search } })
        .then(({ headers, data }) => {
          const normalizedHeaders = normalizeHeaders(headers);
          const pageInfo = {
            ...parseIntPagination(normalizedHeaders),
            __typename: 'LocalPageInfo',
          };
          client.writeQuery({
            query: pageInfoQuery,
            variables: { input: { page, scope, search } },
            data: { pageInfo },
          });
          return data?.keys?.map(mapDeployKey) || [];
        });
    },
  },
  Mutation: {
    currentPage(_, { page }, { client }) {
      client.writeQuery({
        query: currentPageQuery,
        data: { currentPage: page },
      });
    },
    currentScope(_, { scope }, { client }) {
      const key = `${scope}Endpoint`;
      const { [key]: endpoint } = endpoints;

      if (!endpoint) {
        throw new Error(`invalid deploy key scope selected: ${scope}`);
      }

      client.writeQuery({
        query: currentPageQuery,
        data: { currentPage: 1 },
      });
      client.writeQuery({
        query: currentScopeQuery,
        data: { currentScope: scope },
      });
    },
    disableKey(_, _variables, { client }) {
      const {
        deployKeyToRemove: { id },
      } = client.readQuery({
        query: confirmRemoveKeyQuery,
      });

      const fragment = gql`
        fragment DisablePath on LocalDeployKey {
          disablePath
        }
      `;

      const { disablePath } = client.readFragment({ fragment, id: `LocalDeployKey:${id}` });

      return axios.put(disablePath).then(({ data }) => {
        client.cache.evict({ fieldName: 'deployKeyToRemove' });
        client.cache.evict({ id: `LocalDeployKey:${id}` });
        client.cache.gc();

        return data;
      });
    },
    enableKey(_, { id }, { client }) {
      const fragment = gql`
        fragment EnablePath on LocalDeployKey {
          enablePath
        }
      `;

      const { enablePath } = client.readFragment({ fragment, id: `LocalDeployKey:${id}` });

      return axios.put(enablePath).then(({ data }) => {
        client.cache.evict({ id: `LocalDeployKey:${id}` });
        client.cache.gc();

        return data;
      });
    },
    confirmDisable(_, { id }, { client }) {
      client.writeQuery({
        query: confirmRemoveKeyQuery,
        data: { deployKeyToRemove: id ? { id, __type: 'LocalDeployKey' } : null },
      });
    },
  },
});
