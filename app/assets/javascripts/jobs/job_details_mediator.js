/* global Build */

import Visibility from 'visibilityjs';
import Flash from '../flash';
import Poll from '../lib/utils/poll';
import JobStore from './stores/job_store';
import JobService from './services/job_service';
import Job from '../job';
import handleRevealVariables from '../build_variables';

export default class JobMediator {
  constructor(options = {}) {
    this.options = options;

    this.store = new JobStore();
    this.service = new JobService(options.endpoint);

    this.state = {
      isLoading: false,
    };
  }

  initBuildClass() {
    this.build = new Job();
    handleRevealVariables();
  }

  fetchJob() {
    this.poll = new Poll({
      resource: this.service,
      method: 'getJob',
      successCallback: response => this.successCallback(response),
      errorCallback: () => this.errorCallback(),
    });

    if (!Visibility.hidden()) {
      this.state.isLoading = true;
      this.poll.makeRequest();
    } else {
      this.getJob();
    }

    Visibility.change(() => {
      if (!Visibility.hidden()) {
        this.poll.restart();
      } else {
        this.poll.stop();
      }
    });
  }

  getJob() {
    return this.service.getJob()
      .then(response => this.successCallback(response))
      .catch(() => this.errorCallback());
  }

  successCallback(response) {
    this.state.isLoading = false;
    return this.store.storeJob(response.data);
  }

  errorCallback() {
    this.state.isLoading = false;

    return new Flash('An error occurred while fetching the job.');
  }
}
