/* globals Flash */
import Visibility from 'visibilityjs';
import axios from 'axios';
import Poll from './lib/utils/poll';
import { s__ } from './locale';
import './flash';

class ClusterService {
  constructor(options = {}) {
    this.options = options;
  }

  fetchData() {
    return axios.get(this.options.endpoints.checkStatus);
  }

  updateData(value) {
    return axios.put(this.options.endpoints.editPath,
      {
        cluster: {
          enabled: value,
        },
      },
    );
  }
}
/**
 * Handles visibily toggle
 * Polls the state
 */
export default class ClusterEdit {
  constructor() {
    const dataset = document.querySelector('.js-edit-cluster-form').dataset;

    this.state = {
      endpoints: {
        checkStatus: dataset.checkStatus,
        editPath: dataset.editPath,
      },
      canUpdate: dataset.canUpdate,
      clusterStatus: dataset.clusterStatus,
    };

    this.service = new ClusterService({ endpoints: this.state.endpoints });
    this.toggleButton = document.querySelector('.js-toggle-cluster');
    this.errorContainer = document.querySelector('.js-cluster-error');
    this.successContainer = document.querySelector('.js-cluster-success');
    this.creatingContainer = document.querySelector('.js-cluster-creating');
    this.bindEvents();
  }

  bindEvents() {
    if (!this.canUpdate) {
      this.disableToggle();
    }

    if (this.clusterStatus) {
      // update to enable or disabled!
    }

    this.toggleButton.addEventListener('click', this.toggle.bind(this));

    document.querySelector('.js-edit-cluster-button').addEventListener('click', this.updateData.bind(this));

    this.initPoling();
  }

  toggle() {
    this.toggleButton.classList.toggle('checked');
    this.toggleStatus = this.toggleButton.classList.contains('checked').toString();
  }

  updateData() {
    this.service.updateData(this.state.toggleStatus);
  }

  disableToggle(disable = true) {
    this.toggleButton.classList.toggle('disabled', disable);
    this.toggleButton.setAttribute('disabled', disable);
  }

  initPoling() {
    if (this.state.clusterStatus === 'created') return;

    this.poll = new Poll({
      resource: this.service,
      method: 'fetchData',
      successCallback: (data) => {
        const { status } = data.data;
        this.updateContainer(status);
      },
      errorCallback: () => {
        this.updateContainer('error');
        Flash(s__('ClusterIntegration|Something went wrong on our end.'));
      },
    });

    if (!Visibility.hidden()) {
      this.poll.makeRequest();
    } else {
      this.service.fetchData();
    }

    Visibility.change(() => {
      if (!Visibility.hidden()) {
        this.poll.restart();
      } else {
        this.poll.stop();
      }
    });
  }

  hideAll() {
    this.errorContainer.classList.add('hidden');
    this.successContainer.classList.add('hidden');
    this.creatingContainer.classList.add('hidden');
  }

  updateContainer(status) {
    this.hideAll();
    switch (status) {
      case 'created':
        this.successContainer.classList.remove('hidden');
        break;
      case 'error':
        this.errorContainer.classList.remove('hidden');
        break;
      case 'creating':
        this.creatingContainer.classList.add('hidden');
        break;
      default:
        this.hideAll();
    }
  }

}
