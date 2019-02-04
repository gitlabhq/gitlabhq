import Visibility from 'visibilityjs';
import Vue from 'vue';
import { s__ } from '../locale';
import Flash from '../flash';
import Poll from '../lib/utils/poll';
import ServerlessStore from './stores/serverless_store';
import ServerlessDetailsStore from './stores/serverless_details_store';
import GetFunctionsService from './services/get_functions_service';
import Functions from './components/functions.vue';
import FunctionDetails from './components/function_details.vue';

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
      } = document.querySelector('.js-serverless-function-details-page').dataset;
      const el = document.querySelector('#js-serverless-function-details');
      this.store = new ServerlessDetailsStore();
      const { store } = this;

      const service = {
        name: serviceName,
        description: serviceDescription,
        environment: serviceEnvironment,
        url: serviceUrl,
        namespace: serviceNamespace,
        podcount: servicePodcount,
      };

      this.store.updateDetailedFunction(service);
      this.functionDetails = new Vue({
        el,
        data() {
          return {
            state: store.state,
          };
        },
        render(createElement) {
          return createElement(FunctionDetails, {
            props: {
              func: this.state.functionDetail,
            },
          });
        },
      });
    } else {
      const { statusPath, clustersPath, helpPath, installed } = document.querySelector(
        '.js-serverless-functions-page',
      ).dataset;

      this.service = new GetFunctionsService(statusPath);
      this.knativeInstalled = installed !== undefined;
      this.store = new ServerlessStore(this.knativeInstalled, clustersPath, helpPath);
      this.initServerless();
      this.functionLoadCount = 0;

      if (statusPath && this.knativeInstalled) {
        this.initPolling();
      }
    }
  }

  initServerless() {
    const { store } = this;
    const el = document.querySelector('#js-serverless-functions');

    this.functions = new Vue({
      el,
      data() {
        return {
          state: store.state,
        };
      },
      render(createElement) {
        return createElement(Functions, {
          props: {
            functions: this.state.functions,
            installed: this.state.installed,
            clustersPath: this.state.clustersPath,
            helpPath: this.state.helpPath,
            loadingData: this.state.loadingData,
            hasFunctionData: this.state.hasFunctionData,
          },
        });
      },
    });
  }

  initPolling() {
    this.poll = new Poll({
      resource: this.service,
      method: 'fetchData',
      successCallback: data => this.handleSuccess(data),
      errorCallback: () => Serverless.handleError(),
    });

    if (!Visibility.hidden()) {
      this.poll.makeRequest();
    } else {
      this.service
        .fetchData()
        .then(data => this.handleSuccess(data))
        .catch(() => Serverless.handleError());
    }

    Visibility.change(() => {
      if (!Visibility.hidden() && !this.destroyed) {
        this.poll.restart();
      } else {
        this.poll.stop();
      }
    });
  }

  handleSuccess(data) {
    if (data.status === 200) {
      this.store.updateFunctionsFromServer(data.data);
      this.store.updateLoadingState(false);
    } else if (data.status === 204) {
      /* Time out after 3 attempts to retrieve data */
      this.functionLoadCount += 1;
      if (this.functionLoadCount === 3) {
        this.poll.stop();
        this.store.toggleNoFunctionData();
      }
    }
  }

  static handleError() {
    Flash(s__('Serverless|An error occurred while retrieving serverless components'));
  }

  destroy() {
    this.destroyed = true;

    if (this.poll) {
      this.poll.stop();
    }

    this.functions.$destroy();
    this.functionDetails.$destroy();
  }
}
