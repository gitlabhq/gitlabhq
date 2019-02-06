export default class ServerlessStore {
  constructor(knativeInstalled = false, clustersPath, helpPath) {
    this.state = {
      functions: {},
      hasFunctionData: true,
      loadingData: true,
      installed: knativeInstalled,
      clustersPath,
      helpPath,
    };
  }

  updateFunctionsFromServer(upstreamFunctions = []) {
    this.state.functions = upstreamFunctions.reduce((rv, func) => {
      const envs = rv;
      envs[func.environment_scope] = (rv[func.environment_scope] || []).concat([func]);

      return envs;
    }, {});
  }

  updateLoadingState(loadingData) {
    this.state.loadingData = loadingData;
  }

  toggleNoFunctionData() {
    this.state.hasFunctionData = false;
  }
}
