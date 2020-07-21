import Vue from 'vue';
import Functions from './components/functions.vue';
import FunctionDetails from './components/function_details.vue';
import { createStore } from './store';

export default class Serverless {
  constructor() {
    if (document.querySelector('.js-serverless-function-details-page') != null) {
      const entryPointData = document.querySelector('.js-serverless-function-details-page').dataset;
      const store = createStore(entryPointData);

      const {
        serviceName,
        serviceDescription,
        serviceEnvironment,
        serviceUrl,
        serviceNamespace,
        servicePodcount,
        serviceMetricsUrl,
        prometheus,
      } = entryPointData;
      const el = document.querySelector('#js-serverless-function-details');

      const service = {
        name: serviceName,
        description: serviceDescription,
        environment: serviceEnvironment,
        url: serviceUrl,
        namespace: serviceNamespace,
        podcount: servicePodcount,
        metricsUrl: serviceMetricsUrl,
      };

      this.functionDetails = new Vue({
        el,
        store,
        render(createElement) {
          return createElement(FunctionDetails, {
            props: {
              func: service,
              hasPrometheus: prometheus !== undefined,
            },
          });
        },
      });
    } else {
      const entryPointData = document.querySelector('.js-serverless-functions-page').dataset;
      const store = createStore(entryPointData);

      const el = document.querySelector('#js-serverless-functions');
      this.functions = new Vue({
        el,
        store,
        render(createElement) {
          return createElement(Functions);
        },
      });
    }
  }

  destroy() {
    this.destroyed = true;

    this.functions.$destroy();
    this.functionDetails.$destroy();
  }
}
