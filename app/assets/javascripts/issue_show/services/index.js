export default class Service {
  constructor(resource, endpoint) {
    this.resource = resource;
    this.endpoint = endpoint;
  }

  getTitle() {
    return this.resource.get(this.endpoint);
  }
}
