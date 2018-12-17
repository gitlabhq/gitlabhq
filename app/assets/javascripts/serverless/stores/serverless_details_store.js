export default class ServerlessDetailsStore {
  constructor() {
    this.state = {
      functionDetail: {},
    };
  }

  updateDetailedFunction(func) {
    this.state.functionDetail = func;
  }
}
