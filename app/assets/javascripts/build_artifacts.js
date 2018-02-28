/* eslint-disable func-names, space-before-function-paren, wrap-iife, prefer-arrow-callback, no-unused-vars, no-return-assign, max-len */
import { visitUrl } from './lib/utils/url_utility';
import { convertPermissionToBoolean } from './lib/utils/common_utils';

window.BuildArtifacts = (function() {
  function BuildArtifacts() {
    this.disablePropagation();
    this.setupEntryClick();
    this.setupTooltips();
  }

  BuildArtifacts.prototype.disablePropagation = function() {
    $('.top-block').on('click', '.download', function(e) {
      return e.stopPropagation();
    });
    return $('.tree-holder').on('click', 'tr[data-link] a', function(e) {
      return e.stopImmediatePropagation();
    });
  };

  BuildArtifacts.prototype.setupEntryClick = function() {
    return $('.tree-holder').on('click', 'tr[data-link]', function(e) {
      visitUrl(this.dataset.link, convertPermissionToBoolean(this.dataset.externalLink));
    });
  };

  BuildArtifacts.prototype.setupTooltips = function() {
    $('.js-artifact-tree-tooltip').tooltip({
      placement: 'bottom',
      // Stop the tooltip from hiding when we stop hovering the element directly
      // We handle all the showing/hiding below
      trigger: 'manual',
    });

    // We want the tooltip to show if you hover anywhere on the row
    // But be placed below and in the middle of the file name
    $('.js-artifact-tree-row')
      .on('mouseenter', (e) => {
        $(e.currentTarget).find('.js-artifact-tree-tooltip').tooltip('show');
      })
      .on('mouseleave', (e) => {
        $(e.currentTarget).find('.js-artifact-tree-tooltip').tooltip('hide');
      });
  };

  return BuildArtifacts;
})();
