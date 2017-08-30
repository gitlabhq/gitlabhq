/* eslint-disable no-new*/
import './smart_interval';

const healthyClass = 'geo-node-healthy';
const unhealthyClass = 'geo-node-unhealthy';
const unknownClass = 'geo-node-unknown';
const healthyIcon = 'fa-check';
const unhealthyIcon = 'fa-times';
const unknownIcon = 'fa-times';

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
    this.$attachmentsSynced = $('.js-attachments-synced', this.$status);
    this.$lastEventSeen = $('.js-last-event-seen', this.$status);
    this.$lastCursorEvent = $('.js-last-cursor-event', this.$status);
    this.$health = $('.js-health', this.$status);
    this.endpoint = this.$el.data('status-url');
    this.$advancedStatus = $('.js-advanced-geo-node-status-toggler', this.$status)
    this.$advancedStatus.on('click', this.toggleShowAdvancedStatus);

    this.statusInterval = new gl.SmartInterval({
      callback: this.getStatus.bind(this),
      startingInterval: 30000,
      maxInterval: 120000,
      hiddenInterval: 240000,
      incrementByFactorOf: 15000,
      immediateExecution: true,
    });
  }

  toggleShowAdvancedStatus(e) {
    const element = $(e.currentTarget);
    const closestStatus = element.closest('.advanced-geo-node-status-container').find('.advanced-status');
    const currentlyActive = !closestStatus.hasClass('hide-status')
    const togglerContainer = currentlyActive ? $('.toggler-inactive-container') : $('.toggler-active-container')

    element.detach().appendTo(togglerContainer);
    element.find('.fa').toggleClass('fa-angle-down').toggleClass('fa-angle-up');
    closestStatus.toggleClass('hide-status');
  }

  getStatus() {
    $.getJSON(this.endpoint, (status) => {
      this.setStatusIcon(status.healthy);
      this.setHealthStatus(status.healthy);

      // Replication lag can be nil if the secondary isn't actually streaming
      if (status.db_replication_lag) {
        const parsedTime = gl.utils.prettyTime.parseSeconds(status.db_replication_lag);
        this.$dbReplicationLag.text(gl.utils.prettyTime.stringifyTime(parsedTime));
      } else {
        this.$dbReplicationLag.text('UNKNOWN');
      }

      this.$repositoriesSynced.html(`${status.repositories_synced_count}/${status.repositories_count} (${status.repositories_synced_in_percentage})`);
      this.$repositoriesFailed.html(status.repositories_failed_count);
      this.$lfsObjectsSynced.html(`${status.lfs_objects_synced_count}/${status.lfs_objects_count} (${status.lfs_objects_synced_in_percentage})`);
      this.$attachmentsSynced.html(`${status.attachments_synced_count}/${status.attachments_count} (${status.attachments_synced_in_percentage})`);
      const eventDate = gl.utils.formatDate(new Date(status.last_event_date));
      const cursorDate = gl.utils.formatDate(new Date(status.cursor_last_event_date));
      this.$lastEventSeen.html(`${status.last_event_id} (${eventDate})`);
      this.$lastCursorEvent.html(`${status.cursor_last_event_id} (${cursorDate})`);
      if (status.health === 'Healthy') {
        this.$health.html('');
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
                        .html('Healthy');
    } else {
      this.$healthStatus.removeClass(healthyClass)
                        .addClass(unhealthyClass)
                        .html('Unhealthy');
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
