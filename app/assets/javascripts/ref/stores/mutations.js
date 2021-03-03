import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import httpStatusCodes from '~/lib/utils/http_status';
import { X_TOTAL_HEADER } from '../constants';
import * as types from './mutation_types';

export default {
  [types.SET_ENABLED_REF_TYPES](state, refTypes) {
    state.enabledRefTypes = refTypes;
  },
  [types.SET_PROJECT_ID](state, projectId) {
    state.projectId = projectId;
  },
  [types.SET_SELECTED_REF](state, selectedRef) {
    state.selectedRef = selectedRef;
  },
  [types.SET_QUERY](state, query) {
    state.query = query;
  },

  [types.REQUEST_START](state) {
    state.requestCount += 1;
  },
  [types.REQUEST_FINISH](state) {
    state.requestCount -= 1;
  },

  [types.RECEIVE_BRANCHES_SUCCESS](state, response) {
    state.matches.branches = {
      list: convertObjectPropsToCamelCase(response.data).map((b) => ({
        name: b.name,
        default: b.default,
      })),
      totalCount: parseInt(response.headers[X_TOTAL_HEADER], 10),
      error: null,
    };
  },
  [types.RECEIVE_BRANCHES_ERROR](state, error) {
    state.matches.branches = {
      list: [],
      totalCount: 0,
      error,
    };
  },

  [types.RECEIVE_TAGS_SUCCESS](state, response) {
    state.matches.tags = {
      list: convertObjectPropsToCamelCase(response.data).map((b) => ({
        name: b.name,
      })),
      totalCount: parseInt(response.headers[X_TOTAL_HEADER], 10),
      error: null,
    };
  },
  [types.RECEIVE_TAGS_ERROR](state, error) {
    state.matches.tags = {
      list: [],
      totalCount: 0,
      error,
    };
  },

  [types.RECEIVE_COMMITS_SUCCESS](state, response) {
    const commit = convertObjectPropsToCamelCase(response.data);

    state.matches.commits = {
      list: [
        {
          name: commit.shortId,
          value: commit.id,
          subtitle: commit.title,
        },
      ],
      totalCount: 1,
      error: null,
    };
  },
  [types.RECEIVE_COMMITS_ERROR](state, error) {
    state.matches.commits = {
      list: [],
      totalCount: 0,

      // 404's are expected when the search query doesn't match any commits
      // and shouldn't be treated as an actual error
      error: error.response?.status !== httpStatusCodes.NOT_FOUND ? error : null,
    };
  },
  [types.RESET_COMMIT_MATCHES](state) {
    state.matches.commits = {
      list: [],
      totalCount: 0,
      error: null,
    };
  },
};
