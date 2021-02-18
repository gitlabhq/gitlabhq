import Visibility from 'visibilityjs';
import createFlash from '~/flash';
import axios from '~/lib/utils/axios_utils';
import Poll from '~/lib/utils/poll';
import { s__ } from '~/locale';
import { SourceGroupsManager } from './source_groups_manager';

export class StatusPoller {
  constructor({ client, pollPath }) {
    this.client = client;

    this.eTagPoll = new Poll({
      resource: {
        fetchJobs: () => axios.get(pollPath),
      },
      method: 'fetchJobs',
      successCallback: ({ data }) => this.updateImportsStatuses(data),
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

    this.groupManager = new SourceGroupsManager({ client });
  }

  startPolling() {
    this.eTagPoll.makeRequest();
  }

  async updateImportsStatuses(importStatuses) {
    importStatuses.forEach(({ id, status_name: statusName }) => {
      const group = this.groupManager.findByImportId(id);
      if (group.id) {
        this.groupManager.setImportStatus(group, statusName);
      }
    });
  }
}
