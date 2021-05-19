import Visibility from 'visibilityjs';
import createFlash from '~/flash';
import axios from '~/lib/utils/axios_utils';
import Poll from '~/lib/utils/poll';
import { s__ } from '~/locale';

export class StatusPoller {
  constructor({ updateImportStatus, pollPath }) {
    this.eTagPoll = new Poll({
      resource: {
        fetchJobs: () => axios.get(pollPath),
      },
      method: 'fetchJobs',
      successCallback: ({ data: statuses }) => {
        statuses.forEach((status) => updateImportStatus(status));
      },
      errorCallback: () =>
        createFlash({
          message: s__('BulkImport|Update of import statuses with realtime changes failed'),
        }),
    });

    Visibility.change(() => {
      if (!Visibility.hidden()) {
        this.eTagPoll.restart();
      } else {
        this.eTagPoll.stop();
      }
    });
  }

  startPolling() {
    this.eTagPoll.makeRequest();
  }
}
