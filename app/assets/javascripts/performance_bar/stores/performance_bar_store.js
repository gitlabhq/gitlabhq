export default class PerformanceBarStore {
  constructor() {
    this.requests = [];
  }

  addRequest(requestId, requestUrl) {
    if (!this.findRequest(requestId)) {
      const shortUrl = PerformanceBarStore.truncateUrl(requestUrl);

      this.requests.push({
        id: requestId,
        url: requestUrl,
        truncatedUrl: shortUrl,
        details: {},
        hasWarnings: false,
      });
    }

    return this.requests;
  }

  findRequest(requestId) {
    return this.requests.find((request) => request.id === requestId);
  }

  addRequestDetails(requestId, requestDetails) {
    const request = this.findRequest(requestId);

    request.details = requestDetails.data;
    request.hasWarnings = requestDetails.has_warnings;

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
