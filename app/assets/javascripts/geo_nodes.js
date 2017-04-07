/* eslint-disable no-new*/
import './smart_interval';

const healthyClass = 'geo-node-icon-healthy';
const unhealthyClass = 'geo-node-icon-unhealthy';

class GeoNodeStatus {
  constructor(el) {
    this.$el = $(el);
    this.$icon = $('.js-geo-node-icon', this.$el);
    this.$status = $('.js-geo-node-status', this.$el);
    this.$repositoriesSynced = $('.js-repositories-synced', this.$status);
    this.$repositoriesFailed = $('.js-repositories-failed', this.$status);
    this.$lfsObjectsSynced = $('.js-lfs-objects-synced', this.$status);
    this.$attachmentsSynced = $('.js-attachments-synced', this.$status);
    this.$health = $('.js-health', this.$status);
    this.endpoint = this.$el.data('status-url');

    this.statusInterval = new gl.SmartInterval({
      callback: this.getStatus.bind(this),
      startingInterval: 30000,
      maxInterval: 120000,
      hiddenInterval: 240000,
      incrementByFactorOf: 15000,
      immediateExecution: true,
    });
  }

  getStatus() {
    $.getJSON(this.endpoint, (status) => {
      this.setStatusIcon(status.healthy);
      this.$repositoriesSynced.html(`${status.repositories_synced_count}/${status.repositories_count} (${status.repositories_synced_in_percentage})`);
      this.$repositoriesFailed.html(status.repositories_failed_count);
      this.$lfsObjectsSynced.html(`${status.lfs_objects_synced_count}/${status.lfs_objects_count} (${status.lfs_objects_synced_in_percentage})`);
      this.$attachmentsSynced.html(`${status.attachments_synced_count}/${status.attachments_count} (${status.attachments_synced_in_percentage})`);
      this.$health.html(status.health);

      this.$status.show();
    });
  }

  setStatusIcon(healthy) {
    if (healthy) {
      this.$icon.removeClass(unhealthyClass)
                .addClass(healthyClass)
                .attr('title', 'Healthy');
    } else {
      this.$icon.removeClass(healthyClass)
                .addClass(unhealthyClass)
                .attr('title', 'Unhealthy');
    }

    this.$icon.tooltip('fixTitle');
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
