export default class ServerlessStore {
  constructor(knativeInstalled = false, clustersPath, helpPath) {
    this.state = {
      functions: [],
      hasFunctionData: true,
      loadingData: true,
      installed: knativeInstalled,
      clustersPath,
      helpPath,
    };
  }

  updateFunctionsFromServer(functions = []) {
    this.state.functions = functions;
  }

  updateLoadingState(loadingData) {
    this.state.loadingData = loadingData;
  }

  toggleNoFunctionData() {
    this.state.hasFunctionData = false;
  }
}
