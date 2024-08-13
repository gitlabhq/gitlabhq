import { createAlert } from '~/alert';
import axios from '~/lib/utils/axios_utils';
import { __ } from '~/locale';

export default class PayloadDownloader {
  constructor(trigger) {
    this.trigger = trigger;
  }

  init() {
    this.spinner = this.trigger.querySelector('.js-spinner');
    this.text = this.trigger.querySelector('.js-text');

    this.trigger.addEventListener('click', (event) => {
      event.preventDefault();

      return this.requestPayload();
    });
  }

  requestPayload() {
    this.spinner.classList.add('gl-inline');

    return axios
      .get(this.trigger.dataset.endpoint, {
        responseType: 'json',
      })
      .then(({ data }) => {
        PayloadDownloader.downloadFile(data);
      })
      .catch(() => {
        createAlert({
          message: __('Error fetching payload data.'),
        });
      })
      .finally(() => {
        this.spinner.classList.remove('gl-inline');
      });
  }

  static downloadFile(data) {
    const blob = new Blob([JSON.stringify(data)], { type: 'application/json' });

    const link = document.createElement('a');
    link.href = window.URL.createObjectURL(blob);
    link.download = `${data.recorded_at.slice(0, 10)} payload.json`;
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
    window.URL.revokeObjectURL(link.href);
  }
}
