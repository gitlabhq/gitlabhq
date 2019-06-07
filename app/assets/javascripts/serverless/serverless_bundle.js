import Vue from 'vue';
import Functions from './components/functions.vue';
import FunctionDetails from './components/function_details.vue';
import { createStore } from './store';

export default class Serverless {
  constructor() {
    if (document.querySelector('.js-serverless-function-details-page') != null) {
      const {
        serviceName,
        serviceDescription,
        serviceEnvironment,
        serviceUrl,
        serviceNamespace,
        servicePodcount,
        serviceMetricsUrl,
        prometheus,
        clustersPath,
        helpPath,
      } = document.querySelector('.js-serverless-function-details-page').dataset;
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
        store: createStore(),
        render(createElement) {
          return createElement(FunctionDetails, {
            props: {
              func: service,
              hasPrometheus: prometheus !== undefined,
              clustersPath,
              helpPath,
            },
          });
        },
      });
    } else {
      const { statusPath, clustersPath, helpPath } = document.querySelector(
        '.js-serverless-functions-page',
      ).dataset;

      const el = document.querySelector('#js-serverless-functions');
      this.functions = new Vue({
        el,
        store: createStore(),
        render(createElement) {
          return createElement(Functions, {
            props: {
              clustersPath,
              helpPath,
              statusPath,
            },
          });
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
