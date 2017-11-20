/* eslint-disable func-names, no-var, no-underscore-dangle, prefer-template, prefer-arrow-callback*/

import VisibilitySelect from './visibility_select';

function highlightChanges($elm) {
  $elm.addClass('highlight-changes');
  setTimeout(() => $elm.removeClass('highlight-changes'), 10);
}

export default class ProjectNew {
  constructor() {
    this.toggleSettings = this.toggleSettings.bind(this);
    this.$selects = $('.features select');
    this.$repoSelects = this.$selects.filter('.js-repo-select');
<<<<<<< HEAD
    this.$enableApprovers = $('.js-require-approvals-toggle');
    this.$projectSelects = this.$selects.not('.js-repo-select');

    $('.project-edit-container').on('ajax:before', (function(_this) {
      return function() {
        $('.project-edit-container').hide();
        return $('.save-project-loader').show();
      };
    })(this));
=======
    this.$projectSelects = this.$selects.not('.js-repo-select');

    $('.project-edit-container').on('ajax:before', () => {
      $('.project-edit-container').hide();
      return $('.save-project-loader').show();
    });
>>>>>>> ce-com/master

    this.initVisibilitySelect();

    this.toggleSettings();
<<<<<<< HEAD
    this.bindEvents();
    this.toggleRepoVisibility();
  }

  bindEvents () {
    this.$selects.on('change', () => this.toggleSettings());
    $('#require_approvals').on('change', e => this.toggleApproverSettingsVisibility(e));
  }

=======
    this.toggleSettingsOnclick();
    this.toggleRepoVisibility();
  }

>>>>>>> ce-com/master
  initVisibilitySelect() {
    const visibilityContainer = document.querySelector('.js-visibility-select');
    if (!visibilityContainer) return;
    const visibilitySelect = new VisibilitySelect(visibilityContainer);
    visibilitySelect.init();

    const $visibilitySelect = $(visibilityContainer).find('select');
    let projectVisibility = $visibilitySelect.val();
    const PROJECT_VISIBILITY_PRIVATE = '0';

    $visibilitySelect.on('change', () => {
      const newProjectVisibility = $visibilitySelect.val();

      if (projectVisibility !== newProjectVisibility) {
        this.$projectSelects.each((idx, select) => {
          const $select = $(select);
          const $options = $select.find('option');
          const values = $.map($options, e => e.value);

          // if switched to "private", limit visibility options
          if (newProjectVisibility === PROJECT_VISIBILITY_PRIVATE) {
            if ($select.val() !== values[0] && $select.val() !== values[1]) {
              $select.val(values[1]).trigger('change');
              highlightChanges($select);
            }
            $options.slice(2).disable();
          }

          // if switched from "private", increase visibility for non-disabled options
          if (projectVisibility === PROJECT_VISIBILITY_PRIVATE) {
            $options.enable();
            if ($select.val() !== values[0] && $select.val() !== values[values.length - 1]) {
              $select.val(values[values.length - 1]).trigger('change');
              highlightChanges($select);
            }
          }
        });

        projectVisibility = newProjectVisibility;
      }
    });
  }

<<<<<<< HEAD
  toggleApproverSettingsVisibility(e) {
    this.$requiredApprovals = $('#project_approvals_before_merge');
    const enabled = $(e.target).prop('checked');
    const val = enabled ? 1 : 0;
    this.$requiredApprovals.val(val);
    this.$requiredApprovals.prop('min', val);
    $('.nested-settings').toggleClass('hidden', !enabled);
  }

=======
>>>>>>> ce-com/master
  toggleSettings() {
    this.$selects.each(function () {
      var $select = $(this);
      var className = $select.data('field')
        .replace(/_/g, '-')
        .replace('access-level', 'feature');
      ProjectNew._showOrHide($select, '.' + className);
    });
  }

<<<<<<< HEAD
  static _showOrHide(checkElement, container) {
    var $container = $(container);

    if ($(checkElement).val() !== '0') {
      return $container.show();
    } else {
      return $container.hide();
    }
  }

  toggleRepoVisibility () {
=======
  toggleSettingsOnclick() {
    this.$selects.on('change', this.toggleSettings);
  }

  static _showOrHide(checkElement, container) {
    const $container = $(container);

    if ($(checkElement).val() !== '0') {
      return $container.show();
    }
    return $container.hide();
  }

  toggleRepoVisibility() {
>>>>>>> ce-com/master
    var $repoAccessLevel = $('.js-repo-access-level select');
    var $lfsEnabledOption = $('.js-lfs-enabled select');
    var containerRegistry = document.querySelectorAll('.js-container-registry')[0];
    var containerRegistryCheckbox = document.getElementById('project_container_registry_enabled');
    var prevSelectedVal = parseInt($repoAccessLevel.val(), 10);

    this.$repoSelects.find("option[value='" + $repoAccessLevel.val() + "']")
      .nextAll()
      .hide();

<<<<<<< HEAD
    $repoAccessLevel.off('change')
=======
    $repoAccessLevel
      .off('change')
>>>>>>> ce-com/master
      .on('change', function () {
        var selectedVal = parseInt($repoAccessLevel.val(), 10);

        this.$repoSelects.each(function () {
          var $this = $(this);
          var repoSelectVal = parseInt($this.val(), 10);

          $this.find('option').enable();

          if (selectedVal < repoSelectVal || repoSelectVal === prevSelectedVal) {
            $this.val(selectedVal).trigger('change');
            highlightChanges($this);
          }

          $this.find("option[value='" + selectedVal + "']").nextAll().disable();
        });

        if (selectedVal) {
          this.$repoSelects.removeClass('disabled');

          if ($lfsEnabledOption.length) {
            $lfsEnabledOption.removeClass('disabled');
            highlightChanges($lfsEnabledOption);
          }
          if (containerRegistry) {
            containerRegistry.style.display = '';
          }
        } else {
          this.$repoSelects.addClass('disabled');

          if ($lfsEnabledOption.length) {
            $lfsEnabledOption.val('false').addClass('disabled');
            highlightChanges($lfsEnabledOption);
          }
          if (containerRegistry) {
            containerRegistry.style.display = 'none';
            containerRegistryCheckbox.checked = false;
          }
        }

        prevSelectedVal = selectedVal;
      }.bind(this));
  }
}
