/* eslint-disable no-new*/
import './smart_interval';
import { parseSeconds, stringifyTime } from './lib/utils/pretty_time';

const healthyClass = 'geo-node-healthy';
const unhealthyClass = 'geo-node-unhealthy';
const unknownClass = 'geo-node-unknown';
const healthyIcon = 'fa-check';
const unhealthyIcon = 'fa-times';
const unknownIcon = 'fa-times';
const notAvailable = 'Not Available';

class GeoNodeStatus {
  constructor(el) {
    this.$el = $(el);
    this.$icon = $('.js-geo-node-icon', this.$el);
    this.$loadingIcon = $('.js-geo-node-loading', this.$el);
    this.$dbReplicationLag = $('.js-db-replication-lag', this.$status);
    this.$healthStatus = $('.js-health-status', this.$el);
    this.$status = $('.js-geo-node-status', this.$el);
    this.$repositoriesSynced = $('.js-repositories-synced', this.$status);
    this.$repositoriesFailed = $('.js-repositories-failed', this.$status);
    this.$lfsObjectsSynced = $('.js-lfs-objects-synced', this.$status);
    this.$lfsObjectsFailed = $('.js-lfs-objects-failed', this.$status);
    this.$attachmentsSynced = $('.js-attachments-synced', this.$status);
    this.$attachmentsFailed = $('.js-attachments-failed', this.$status);
    this.$lastEventSeen = $('.js-last-event-seen', this.$status);
    this.$lastCursorEvent = $('.js-last-cursor-event', this.$status);
    this.$health = $('.js-health', this.$status);
    this.endpoint = this.$el.data('status-url');
    this.$advancedStatus = $('.js-advanced-geo-node-status-toggler', this.$status);
    this.$advancedStatus.on('click', GeoNodeStatus.toggleShowAdvancedStatus);

    this.statusInterval = new gl.SmartInterval({
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
    const $closestStatus = $element.siblings('.advanced-status');

    $element.find('.fa').toggleClass('fa-angle-down').toggleClass('fa-angle-up');
    $closestStatus.toggleClass('hidden');
  }

  static formatCountAndPercentage(count, total, percentage) {
    if (count !== null || total != null) {
      return `${gl.text.addDelimiter(count)}/${gl.text.addDelimiter(total)} (${percentage})`;
    }

    return notAvailable;
  }

  static formatCount(count) {
    if (count !== null) {
      gl.text.addDelimiter(count);
    }

    return notAvailable;
  }

  getStatus() {
    $.getJSON(this.endpoint, (status) => {
      this.setStatusIcon(status.healthy);
      this.setHealthStatus(status.healthy);

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

      const repoText = GeoNodeStatus.formatCountAndPercentage(
        status.repositories_synced_count,
        status.repositories_count,
        status.repositories_synced_in_percentage);

      const repoFailedText = GeoNodeStatus.formatCount(status.repositories_failed_count);

      const lfsText = GeoNodeStatus.formatCountAndPercentage(
        status.lfs_objects_synced_count,
        status.lfs_objects_count,
        status.lfs_objects_synced_in_percentage);

      const lfsFailedText = GeoNodeStatus.formatCount(status.lfs_objects_failed_count);

      const attachmentText = GeoNodeStatus.formatCountAndPercentage(
        status.attachments_synced_count,
        status.attachments_count,
        status.attachments_synced_in_percentage);

      const attachmentFailedText = GeoNodeStatus.formatCount(status.attachments_failed_count);

      this.$repositoriesSynced.text(repoText);
      this.$repositoriesFailed.text(repoFailedText);
      this.$lfsObjectsSynced.text(lfsText);
      this.$lfsObjectsFailed.text(lfsFailedText);
      this.$attachmentsSynced.text(attachmentText);
      this.$attachmentsFailed.text(attachmentFailedText);

      let eventDate = notAvailable;
      let cursorDate = notAvailable;
      let lastEventSeen = notAvailable;
      let lastCursorEvent = notAvailable;

      if (status.last_event_timestamp !== null && status.last_event_timestamp > 0) {
        eventDate = gl.utils.formatDate(new Date(status.last_event_timestamp * 1000));
      }

      if (status.cursor_last_event_timestamp !== null && status.cursor_last_event_timestamp > 0) {
        cursorDate = gl.utils.formatDate(new Date(status.cursor_last_event_timestamp * 1000));
      }

      if (status.last_event_id !== null) {
        lastEventSeen = `${status.last_event_id} (${eventDate})`;
      }

      if (status.cursor_last_event_id !== null) {
        lastCursorEvent = `${status.cursor_last_event_id} (${cursorDate})`;
      }

      this.$lastEventSeen.text(lastEventSeen);
      this.$lastCursorEvent.text(lastCursorEvent);

      if (status.health === 'Healthy') {
        this.$health.text('');
      } else {
        const strippedData = $('<div>').html(`${status.health}`).text();
        this.$health.html(`<code class="geo-health">${strippedData}</code>`);
      }

      this.$status.show();
    });
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

  setHealthStatus(healthy) {
    if (healthy) {
      this.$healthStatus.removeClass(unhealthyClass)
                        .addClass(healthyClass)
                        .text('Healthy');
    } else {
      this.$healthStatus.removeClass(healthyClass)
                        .addClass(unhealthyClass)
                        .text('Unhealthy');
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
