/* globals Flash */
import Visibility from 'visibilityjs';
import axios from 'axios';
import Poll from './lib/utils/poll';
import { s__ } from './locale';
import './flash';
import { convertPermissionToBoolean } from './lib/utils/common_utils';

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
 * Cluster page has 2 separate parts:
 * - Update form with toggle button
 * -- Check initial state and set the toggle button
 * -- Listen to changes
 * -- Check permissions in order to disable
 * -- Update cluster based on toggle status
 *
 * - Polling status while creating or scheduled
 * -- Update status area with the response result
 *
 */
export default class ClusterEdit {
  constructor() {
    const dataset = document.querySelector('.js-edit-cluster-form').dataset;

    this.state = {
      endpoints: {
        checkStatus: dataset.checkStatus,
        editPath: dataset.editPath,
      },
      canUpdate: convertPermissionToBoolean(dataset.canUpdate),
      clusterStatus: dataset.clusterStatus,
      toggleStatus: dataset.toggleStatus,
    };

    this.service = new ClusterService({ endpoints: this.state.endpoints });
    this.toggleButton = document.querySelector('.js-toggle-cluster');
    this.errorContainer = document.querySelector('.js-cluster-error');
    this.successContainer = document.querySelector('.js-cluster-success');
    this.creatingContainer = document.querySelector('.js-cluster-creating');

    this.initEditForm();

    if (this.clusterStatus === 'scheduled' || this.clusterStatus === 'creating') {
      this.initPoling();
    }
  }

  initEditForm() {
    this.toggleButton.addEventListener('click', this.toggle.bind(this));
    document.querySelector('.js-edit-cluster-button').addEventListener('click', this.updateData.bind(this));
  }

  toggle() {
    this.toggleButton.classList.toggle('checked');
    this.state.toggleStatus = this.toggleButton.classList.contains('checked').toString();
  }

  updateData() {
    this.service.updateData(this.state.toggleStatus);
  }

  initPoling() {
    this.poll = new Poll({
      resource: this.service,
      method: 'fetchData',
      successCallback: (data) => {
        const { status } = data.data;
        this.updateContainer(status);
      },
      errorCallback: (error) => {
        this.updateContainer('error', error);
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
      case 'error':
        this.errorContainer.classList.remove('hidden');
        this.errorContainer.querySelector('.js-error-reason').textContent = error.status_reason;
        break;
      case 'creating':
        this.creatingContainer.classList.add('hidden');
        break;
      default:
        this.hideAll();
    }
  }

}
