export default class PerformanceBarStore {
  constructor() {
    this.requests = [];
  }

  addRequest(requestId, requestUrl, requestDetails) {
    if (!this.findRequest(requestId)) {
      this.requests.push({
        id: requestId,
        url: requestUrl,
        details: requestDetails,
      });
    }

    return this.requests;
  }

  findRequest(requestId) {
    return this.requests.find(request => request.id === requestId);
  }

  addRequestDetails(requestId, requestDetails) {
    const request = this.findRequest(requestId);

    request.details = requestDetails;

    return request;
  }

  requestsWithDetails() {
    return this.requests.filter(request => request.details);
  }

  canTrackRequest(requestUrl) {
    return (
      this.requests.filter(request => request.url === requestUrl).length < 2
    );
  }
}
