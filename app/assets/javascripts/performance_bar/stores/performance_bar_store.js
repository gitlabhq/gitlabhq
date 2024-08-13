import { mergeUrlParams } from '~/lib/utils/url_utility';
import { sprintf, s__ } from '~/locale';

export default class PerformanceBarStore {
  constructor() {
    this.requests = [];
  }

  // eslint-disable-next-line max-params
  addRequest(requestId, requestUrl, operationName, requestParams, methodVerb) {
    if (this.findRequest(requestId)) {
      this.updateRequestBatchedQueriesCount(requestId);
    } else {
      let displayName = '';

      if (methodVerb) {
        displayName += `${methodVerb.toUpperCase()} `;
      }

      displayName += PerformanceBarStore.truncateUrl(requestUrl);

      if (operationName) {
        displayName += ` (${operationName})`;
      }

      this.requests.push({
        id: requestId,
        url: requestUrl,
        fullUrl: mergeUrlParams(requestParams, requestUrl),
        method: methodVerb,
        details: {},
        queriesInBatch: 1, // only for GraphQL
        displayName,
      });
    }

    return this.requests;
  }
  updateRequestBatchedQueriesCount(requestId) {
    const existingRequest = this.findRequest(requestId);
    existingRequest.queriesInBatch += 1;

    const originalDisplayName = existingRequest.displayName;
    const regex = /\d+ queries batched/;
    if (regex.test(originalDisplayName)) {
      existingRequest.displayName = originalDisplayName.replace(
        regex,
        sprintf(s__('PerformanceBar|%{queryCount} queries batched'), {
          queryCount: existingRequest.queriesInBatch,
        }),
      );
    } else {
      existingRequest.displayName = sprintf(
        s__('PerformanceBar|%{originalDisplayName} [%{queryCount} queries batched]'),
        {
          originalDisplayName,
          queryCount: existingRequest.queriesInBatch,
        },
      );
    }
  }

  findRequest(requestId) {
    return this.requests.find((request) => request.id === requestId);
  }

  addRequestDetails(requestId, requestDetails) {
    const request = this.findRequest(requestId);

    request.details = requestDetails.data;

    return request;
  }

  setRequestDetailsData(requestId, metricKey, requestDetailsData) {
    const selectedRequest = this.findRequest(requestId);
    if (selectedRequest) {
      selectedRequest.details = {
        ...selectedRequest.details,
        [metricKey]: requestDetailsData,
      };
    }
  }

  requestsWithDetails() {
    return this.requests.filter((request) => request.details);
  }

  canTrackRequest(requestUrl) {
    // We want to store at most 2 unique requests per URL, as additional
    // requests to the same URL probably aren't very interesting.
    //
    // GraphQL requests are the exception: because all GraphQL requests
    // go to the same URL, we set a higher limit of 10 to allow
    // capturing different queries a page may make.
    const requestsLimit = requestUrl.endsWith('/api/graphql') ? 10 : 2;

    return this.requests.filter((request) => request.url === requestUrl).length < requestsLimit;
  }

  static truncateUrl(requestUrl) {
    const [rootAndQuery] = requestUrl.split('#');
    const [root, query] = rootAndQuery.split('?');
    const components = root.replace(/\/$/, '').split('/');

    let truncated = components[components.length - 1];
    if (truncated.match(/^\d+$/)) {
      truncated = `${components[components.length - 2]}/${truncated}`;
    }
    if (query) {
      truncated += `?${query}`;
    }

    return truncated;
  }
}
