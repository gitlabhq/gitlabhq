/* eslint-disable consistent-return */

import axios from '../lib/utils/axios_utils';

export class GitLabDropdownRemote {
  constructor(dataEndpoint, options) {
    this.dataEndpoint = dataEndpoint;
    this.options = options;
  }

  execute() {
    if (typeof this.dataEndpoint === 'string') {
      return this.fetchData();
    }
    if (typeof this.dataEndpoint === 'function') {
      if (this.options.beforeSend) {
        this.options.beforeSend();
      }
      return this.dataEndpoint('', (data) => {
        // Fetch the data by calling the data function
        if (this.options.success) {
          this.options.success(data);
        }
        if (this.options.beforeSend) {
          return this.options.beforeSend();
        }
      });
    }
  }

  fetchData() {
    if (this.options.beforeSend) {
      this.options.beforeSend();
    }

    // Fetch the data through ajax if the data is a string
    return axios.get(this.dataEndpoint).then(({ data }) => {
      if (this.options.success) {
        return this.options.success(data);
      }
    });
  }
}
