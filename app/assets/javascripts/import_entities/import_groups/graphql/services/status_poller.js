import gql from 'graphql-tag';
import createFlash from '~/flash';
import { s__ } from '~/locale';
import bulkImportSourceGroupsQuery from '../queries/bulk_import_source_groups.query.graphql';
import { STATUSES } from '../../../constants';
import { SourceGroupsManager } from './source_groups_manager';

const groupId = (i) => `group${i}`;

function generateGroupsQuery(groups) {
  return gql`{
    ${groups
      .map(
        (g, idx) =>
          `${groupId(idx)}: group(fullPath: "${g.import_target.target_namespace}/${
            g.import_target.new_name
          }") { id }`,
      )
      .join('\n')}
  }`;
}

export class StatusPoller {
  constructor({ client, interval }) {
    this.client = client;
    this.interval = interval;
    this.timeoutId = null;
    this.groupManager = new SourceGroupsManager({ client });
  }

  startPolling() {
    if (this.timeoutId) {
      return;
    }

    this.checkPendingImports();
  }

  stopPolling() {
    clearTimeout(this.timeoutId);
    this.timeoutId = null;
  }

  async checkPendingImports() {
    try {
      const { bulkImportSourceGroups } = this.client.readQuery({
        query: bulkImportSourceGroupsQuery,
      });

      const groupsInProgress = bulkImportSourceGroups.nodes.filter(
        (g) => g.status === STATUSES.STARTED,
      );
      if (groupsInProgress.length) {
        const { data: results } = await this.client.query({
          query: generateGroupsQuery(groupsInProgress),
          fetchPolicy: 'no-cache',
        });
        const completedGroups = groupsInProgress.filter((_, idx) => Boolean(results[groupId(idx)]));
        completedGroups.forEach((group) => {
          this.groupManager.setImportStatus(group, STATUSES.FINISHED);
        });
      }
    } catch (e) {
      createFlash({
        message: s__('BulkImport|Update of import statuses with realtime changes failed'),
      });
    } finally {
      this.timeoutId = setTimeout(() => this.checkPendingImports(), this.interval);
    }
  }
}
