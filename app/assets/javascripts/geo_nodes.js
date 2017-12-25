/* eslint-disable no-new*/
import axios from 'axios';
import SmartInterval from '~/smart_interval';
import { s__ } from '~/locale';
import { parseSeconds, stringifyTime } from './lib/utils/pretty_time';
import { formatDate, timeIntervalInWords } from './lib/utils/datetime_utility';
import timeago from './vue_shared/mixins/timeago';

const healthyClass = 'geo-node-healthy';
const unhealthyClass = 'geo-node-unhealthy';
const unknownClass = 'geo-node-unknown';
const healthyIcon = 'fa-check';
const unhealthyIcon = 'fa-times';
const unknownIcon = 'fa-times';
const notAvailable = 'Not Available';
const versionMismatch = 'Does not match the primary node version';
const versionMismatchClass = 'geo-node-version-mismatch';
const storageMismatch = 'Does not match the primary storage configuration';
const storageMismatchClass = 'geo-node-storage-mismatch';

class GeoNodeStatus {
  constructor(el) {
    this.$el = $(el);
    this.$icon = $('.js-geo-node-icon', this.$el);
    this.$loadingIcon = $('.js-geo-node-loading', this.$el);
    this.$dbReplicationLag = $('.js-db-replication-lag', this.$status);
    this.$healthStatus = $('.js-health-status', this.$el);
    this.$status = $('.js-geo-node-status', this.$el);
    this.$repositories = $('.js-repositories', this.$status);
    this.$wikis = $('.js-wikis', this.$status);
    this.$lfsObjects = $('.js-lfs-objects', this.$status);
    this.$attachments = $('.js-attachments', this.$status);
    this.$syncSettings = $('.js-sync-settings', this.$status);
    this.$lastEventSeen = $('.js-last-event-seen', this.$status);
    this.$lastCursorEvent = $('.js-last-cursor-event', this.$status);
    this.$health = $('.js-health-message', this.$status.parent());
    this.$version = $('.js-gitlab-version', this.$status);
    this.$secondaryVersion = $('.js-secondary-version', this.$status);
    this.$secondaryStorage = $('.js-secondary-storage-shards', this.$status);
    this.endpoint = this.$el.data('status-url');
    this.$advancedStatus = $('.js-advanced-geo-node-status-toggler', this.$status.parent());
    this.$advancedStatus.on('click', GeoNodeStatus.toggleShowAdvancedStatus.bind(this));
    this.primaryVersion = $('.js-primary-version').text();
    this.primaryRevision = $('.js-primary-revision').text().replace(/\W/g, '');
    this.primaryStorageConfiguration = $('.primary-node').data('storageShards');

    this.statusInterval = new SmartInterval({
      callback: this.getStatus.bind(this),
      startingInterval: 30000,
      maxInterval: 120000,
      hiddenInterval: 240000,
      incrementByFactorOf: 15000,
      immediateExecution: true,
    });
  }

  static toggleShowAdvancedStatus(e) {
    const $element = $(e.currentTarget);
    const $advancedStatusItems = this.$status.find('.js-advanced-status');

    $element.find('.js-advance-toggle')
      .html(gl.utils.spriteIcon($advancedStatusItems.is(':hidden') ? 'angle-up' : 'angle-down', 's16'));
    $advancedStatusItems.toggleClass('hidden');
  }

  static getSyncStatistics({ syncedCount, failedCount, totalCount }) {
    const syncedPercent = Math.ceil((syncedCount / totalCount) * 100);
    const failedPercent = Math.ceil((failedCount / totalCount) * 100);
    const waitingPercent = 100 - syncedPercent - failedPercent;

    return {
      syncedPercent,
      waitingPercent,
      failedPercent,
      syncedCount,
      failedCount,
      waitingCount: totalCount - syncedCount - failedCount,
    };
  }

  static renderSyncGraph($itemEl, syncStats) {
    const graphItems = [
      {
        itemSel: '.js-synced',
        itemTooltip: s__('GeoNodeSyncStatus|Synced'),
        itemCount: syncStats.syncedCount,
        itemPercent: syncStats.syncedPercent,
      },
      {
        itemSel: '.js-waiting',
        itemTooltip: s__('GeoNodeSyncStatus|Out of sync'),
        itemCount: syncStats.waitingCount,
        itemPercent: syncStats.waitingPercent,
      },
      {
        itemSel: '.js-failed',
        itemTooltip: s__('GeoNodeSyncStatus|Failed'),
        itemCount: syncStats.failedCount,
        itemPercent: syncStats.failedPercent,
      },
    ];

    $itemEl.find('.js-stats-unavailable')
      .toggleClass('hidden',
        !!graphItems[0].itemCount ||
        !!graphItems[1].itemCount ||
        !!graphItems[2].itemCount);

    graphItems.forEach((item) => {
      $itemEl.find(item.itemSel)
        .toggleClass('has-value has-tooltip', !!item.itemCount)
        .attr('data-original-title', `${item.itemTooltip}: ${item.itemCount}`)
        .text(`${item.itemPercent}%` || '')
        .css('width', `${item.itemPercent}%`);
    });
  }

  static renderEventStats($eventEl, eventId, eventTimestamp) {
    const $eventTimestampEl = $eventEl.find('.js-event-timestamp');
    let eventDate = notAvailable;

    if (eventTimestamp && eventTimestamp > 0) {
      eventDate = formatDate(new Date(eventTimestamp * 1000));
    }

    if (eventId) {
      $eventEl.find('.js-event-id').text(eventId);
      $eventTimestampEl
        .attr('title', eventDate)
        .text(`(${timeago.methods.timeFormated(eventDate)})`);
    }
  }

  static renderSyncSettings($syncSettings, namespaces, eventStats) {
    const { lastEventId, lastEventTimestamp, cursorEventId, cursorEventTimestamp } = eventStats;
    const $syncStatusIcon = $syncSettings.find('.js-sync-status-icon');
    const DIFFS = {
      FIVE_MINS: 300,
      HOUR: 3600,
    };
    let eventDateTime;
    let cursorDateTime;

    $syncSettings.find('.js-sync-type')
      .text(namespaces.length > 0 ? 'Selective' : 'Full');

    if (lastEventTimestamp && lastEventTimestamp > 0) {
      eventDateTime = new Date(lastEventTimestamp * 1000);
    }

    if (cursorEventTimestamp && cursorEventTimestamp > 0) {
      cursorDateTime = new Date(cursorEventTimestamp * 1000);
    }

    const timeDiffInSeconds = (cursorDateTime - eventDateTime) / 1000;
    if (timeDiffInSeconds <= DIFFS.FIVE_MINS) {
      // Lag is under 5 mins
      $syncStatusIcon.html(gl.utils.spriteIcon('retry', 's16'));
    } else if (timeDiffInSeconds > DIFFS.FIVE_MINS &&
               timeDiffInSeconds <= DIFFS.HOUR) {
      // Lag is between 5 mins to an hour
      $syncStatusIcon.html(gl.utils.spriteIcon('warning', 's16'));
      $syncSettings.attr('data-original-title', s__('GeoNodeSyncStatus|Node is slow, overloaded, or it just recovered after an outage.'));
    } else {
      // Lag is over an hour
      $syncSettings.find('.js-sync-status').addClass('sync-status-failure');
      $syncStatusIcon.html(gl.utils.spriteIcon('status_failed', 's16'));
      $syncSettings.attr('data-original-title', s__('GeoNodeSyncStatus|Node is failing or broken.'));
    }

    const timeAgoStr = timeIntervalInWords(timeDiffInSeconds);
    const pendingEvents = lastEventId - cursorEventId;
    $syncSettings
      .find('.js-sync-status-timestamp')
      .text(`${timeAgoStr} (${pendingEvents} events)`);
  }

  getStatus() {
    return axios.get(this.endpoint)
      .then((response) => {
        this.handleStatus(response.data);
        return response;
      })
      .catch((err) => {
        this.handleError(err);
      });
  }

  handleStatus(status) {
    this.setStatusIcon(status.healthy);
    this.setHealthStatus({
      healthy: status.healthy,
      healthStatus: status.health_status,
      healthMessage: status.health,
    });
    this.$version.text(status.version);

      // Replication lag can be nil if the secondary isn't actually streaming
    if (status.db_replication_lag_seconds !== null && status.db_replication_lag_seconds >= 0) {
      const parsedTime = parseSeconds(status.db_replication_lag_seconds, {
        hoursPerDay: 24,
        daysPerWeek: 7,
      });
      this.$dbReplicationLag.text(stringifyTime(parsedTime));
    } else {
      this.$dbReplicationLag.text('UNKNOWN');
    }

    if (!this.primaryVersion || (this.primaryVersion === status.version
      && this.primaryRevision === status.revision)) {
      this.$secondaryVersion.removeClass(`${versionMismatchClass}`);
      this.$secondaryVersion.text(`${status.version} (${status.revision})`);
    } else {
      this.$secondaryVersion.addClass(`${versionMismatchClass}`);
      this.$secondaryVersion.text(`${status.version} (${status.revision}) - ${versionMismatch}`);
    }

    if (status.storage_shards_match === null) {
      this.$secondaryStorage.text('UNKNOWN');
    } else if (status.storage_shards_match) {
      this.$secondaryStorage.removeClass(`${storageMismatchClass}`);
      this.$secondaryStorage.text('OK');
    } else {
      this.$secondaryStorage.addClass(`${storageMismatchClass}`);
      this.$secondaryStorage.text(storageMismatch);
    }

    if (status.repositories_count > 0) {
      const repositoriesStats = GeoNodeStatus.getSyncStatistics({
        syncedCount: status.repositories_synced_count,
        failedCount: status.repositories_failed_count,
        totalCount: status.repositories_count,
      });
      GeoNodeStatus.renderSyncGraph(this.$repositories, repositoriesStats);
    }

    if (status.wikis_count > 0) {
      const wikisStats = GeoNodeStatus.getSyncStatistics({
        syncedCount: status.wikis_synced_count,
        failedCount: status.wikis_failed_count,
        totalCount: status.wikis_count,
      });
      GeoNodeStatus.renderSyncGraph(this.$wikis, wikisStats);
    }

    if (status.lfs_objects_count > 0) {
      const lfsObjectsStats = GeoNodeStatus.getSyncStatistics({
        syncedCount: status.lfs_objects_synced_count,
        failedCount: status.lfs_objects_failed_count,
        totalCount: status.lfs_objects_count,
      });
      GeoNodeStatus.renderSyncGraph(this.$lfsObjects, lfsObjectsStats);
    }

    if (status.attachments_count > 0) {
      const attachmentsStats = GeoNodeStatus.getSyncStatistics({
        syncedCount: status.attachments_synced_count,
        failedCount: status.attachments_failed_count,
        totalCount: status.attachments_count,
      });
      GeoNodeStatus.renderSyncGraph(this.$attachments, attachmentsStats);
    }

    if (status.namespaces) {
      GeoNodeStatus.renderSyncSettings(
        this.$syncSettings,
        status.namespaces, {
          lastEventId: status.last_event_id,
          lastEventTimestamp: status.last_event_timestamp,
          cursorEventId: status.cursor_last_event_id,
          cursorEventTimestamp: status.cursor_last_event_timestamp,
        });
    }

    GeoNodeStatus.renderEventStats(
      this.$lastEventSeen,
      status.last_event_id,
      status.last_event_timestamp);
    GeoNodeStatus.renderEventStats(
      this.$lastCursorEvent,
      status.cursor_last_event_id,
      status.cursor_last_event_timestamp);

    this.$status.removeClass('hidden');
  }

  handleError(err) {
    this.setStatusIcon(false);
    this.setHealthStatus(false);
    this.$health.text(err);
    this.$health.removeClass('hidden');
    this.$status.removeClass('hidden');
  }

  setStatusIcon(healthy) {
    this.$loadingIcon.hide();
    this.$icon.removeClass(`${unknownClass} ${unknownIcon}`);

    if (healthy) {
      this.$icon.removeClass(`${unhealthyClass} ${unhealthyIcon}`)
                .addClass(`${healthyClass} ${healthyIcon}`)
                .attr('title', 'Healthy');
    } else {
      this.$icon.removeClass(`${healthyClass} ${healthyIcon}`)
                .addClass(`${unhealthyClass} ${unhealthyIcon}`)
                .attr('title', 'Unhealthy');
    }
  }

  setHealthStatus({ healthy, healthStatus, healthMessage }) {
    if (healthy) {
      this.$healthStatus.removeClass(unhealthyClass)
                        .addClass(healthyClass)
                        .text(healthMessage);
      this.$health.text('');
      this.$health.addClass('hidden');
    } else {
      this.$healthStatus.removeClass(healthyClass)
                        .addClass(unhealthyClass)
                        .text(healthStatus);
      const strippedData = $('<div>').html(`${healthMessage}`).text();
      this.$health.text(strippedData);
      this.$health.removeClass('hidden');
    }
  }
}

class GeoNodes {
  constructor(container) {
    this.$container = $(container);
    this.pollForSecondaryNodeStatus();
  }

  pollForSecondaryNodeStatus() {
    $('.js-geo-secondary-node', this.$container).each((i, el) => {
      new GeoNodeStatus(el);
    });
  }
}

export default GeoNodes;
