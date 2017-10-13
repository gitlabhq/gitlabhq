/* globals Flash */
import Visibility from 'visibilityjs';
import axios from 'axios';
import Poll from './lib/utils/poll';
import { s__ } from './locale';
import './flash';

/**
 * Cluster page has 2 separate parts:
 *   Toggle button
 *
 * - Polling status while creating or scheduled
 * -- Update status area with the response result
 */

class ClusterService {
  constructor(options = {}) {
    this.options = options;
  }
  fetchData() {
    return axios.get(this.options.endpoint);
  }
}

export default class Clusters {
  constructor() {
    const dataset = document.querySelector('.js-edit-cluster-form').dataset;

    this.state = {
      statusPath: dataset.statusPath,
      clusterStatus: dataset.clusterStatus,
      clusterStatusReason: dataset.clusterStatusReason,
      toggleStatus: dataset.toggleStatus,
    };

    this.service = new ClusterService({ endpoint: this.state.statusPath });
    this.toggleButton = document.querySelector('.js-toggle-cluster');
    this.toggleInput = document.querySelector('.js-toggle-input');
    this.errorContainer = document.querySelector('.js-cluster-error');
    this.successContainer = document.querySelector('.js-cluster-success');
    this.creatingContainer = document.querySelector('.js-cluster-creating');
    this.errorReasonContainer = this.errorContainer.querySelector('.js-error-reason');

    this.toggleButton.addEventListener('click', this.toggle.bind(this));

    if (this.state.clusterStatus !== 'created') {
      this.updateContainer(this.state.clusterStatus, this.state.clusterStatusReason);
    }

    if (this.state.statusPath) {
      this.initPolling();
    }
  }

  toggle() {
    this.toggleButton.classList.toggle('checked');
    this.toggleInput.setAttribute('value', this.toggleButton.classList.contains('checked').toString());
  }

  initPolling() {
    this.poll = new Poll({
      resource: this.service,
      method: 'fetchData',
      successCallback: (data) => {
        const { status, status_reason } = data.data;
        this.updateContainer(status, status_reason);
      },
      errorCallback: () => {
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

  updateContainer(status, error) {
    this.hideAll();
    switch (status) {
      case 'created':
        this.successContainer.classList.remove('hidden');
        break;
      case 'errored':
        this.errorContainer.classList.remove('hidden');
        this.errorReasonContainer.textContent = error;
        break;
      case 'scheduled':
      case 'creating':
        this.creatingContainer.classList.remove('hidden');
        break;
      default:
        this.hideAll();
    }
  }
}
