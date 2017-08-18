/* eslint-disable func-names, space-before-function-paren, wrap-iife, no-use-before-define, camelcase, quotes, object-shorthand, no-shadow, no-unused-vars, comma-dangle, no-var, prefer-template, no-underscore-dangle, consistent-return, one-var, one-var-declaration-per-line, default-case, prefer-arrow-callback, max-len */
/* global Flash */
/* global Sortable */

(function() {
  this.Milestone = (function() {
    function Milestone() {
      this.bindTabsSwitching();

      // Load merge request tab if it is active
      // merge request tab is active based on different conditions in the backend
      this.loadTab($('.js-milestone-tabs .active a'));

      this.loadInitialTab();
    }

    Milestone.prototype.bindTabsSwitching = function() {
      return $('a[data-toggle="tab"]').on('show.bs.tab', (e) => {
        const $target = $(e.target);

        location.hash = $target.attr('href');
        this.loadTab($target);
      });
    };

    Milestone.prototype.loadInitialTab = function() {
      const $target = $(`.js-milestone-tabs a[href="${location.hash}"]`);

      if ($target.length) {
        $target.tab('show');
      }
    };

    Milestone.prototype.loadTab = function($target) {
      const endpoint = $target.data('endpoint');
      const tabElId = $target.attr('href');

      if (endpoint && !$target.hasClass('is-loaded')) {
        $.ajax({
          url: endpoint,
          dataType: 'JSON',
        })
        .fail(() => new Flash('Error loading milestone tab'))
        .done((data) => {
          $(tabElId).html(data.html);
          $target.addClass('is-loaded');
        });
      }
    };

    return Milestone;
  })();
}).call(window);
