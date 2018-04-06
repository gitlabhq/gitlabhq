/* eslint-disable func-names, space-before-function-paren, no-var, consistent-return, no-new, prefer-arrow-callback, no-return-assign, one-var, one-var-declaration-per-line, object-shorthand, no-else-return, newline-per-chained-call, no-shadow, vars-on-top, prefer-template, max-len */

import $ from 'jquery';
import Cookies from 'js-cookie';
import { __ } from '~/locale';
import { visitUrl } from '~/lib/utils/url_utility';
import axios from '~/lib/utils/axios_utils';
import flash from '~/flash';
import projectSelect from '../../project_select';

export default class Project {
  constructor() {
    const $cloneOptions = $('ul.clone-options-dropdown');
    const $projectCloneField = $('#project_clone');
    const $cloneBtnText = $('a.clone-dropdown-btn span');

    const selectedCloneOption = $cloneBtnText.text().trim();
    if (selectedCloneOption.length > 0) {
      $(`a:contains('${selectedCloneOption}')`, $cloneOptions).addClass('is-active');
    }

    $('a', $cloneOptions).on('click', (e) => {
      const $this = $(e.currentTarget);
      const url = $this.attr('href');
      const activeText = $this.find('.dropdown-menu-inner-title').text();

      e.preventDefault();

      $('.is-active', $cloneOptions).not($this).removeClass('is-active');
      $this.toggleClass('is-active');
      $projectCloneField.val(url);
      $cloneBtnText.text(activeText);

      $('#modal-geo-info').data({
        cloneUrlSecondary: $this.attr('href'),
        cloneUrlPrimary: $this.data('primaryUrl') || '',
      });

      return $('.clone').text(url);
    });
    // Ref switcher
    Project.initRefSwitcher();
    $('.project-refs-select').on('change', function() {
      return $(this).parents('form').submit();
    });
    $('.hide-no-ssh-message').on('click', function(e) {
      Cookies.set('hide_no_ssh_message', 'false');
      $(this).parents('.no-ssh-key-message').remove();
      return e.preventDefault();
    });
    $('.hide-no-password-message').on('click', function(e) {
      Cookies.set('hide_no_password_message', 'false');
      $(this).parents('.no-password-message').remove();
      return e.preventDefault();
    });
    $('.hide-shared-runner-limit-message').on('click', function(e) {
      var $alert = $(this).parents('.shared-runner-quota-message');
      var scope = $alert.data('scope');
      Cookies.set('hide_shared_runner_quota_message', 'false', { path: scope });
      $alert.remove();
      e.preventDefault();
    });
    Project.projectSelectDropdown();
  }

  static projectSelectDropdown() {
    projectSelect();
    $('.project-item-select').on('click', e => Project.changeProject($(e.currentTarget).val()));
  }

  static changeProject(url) {
    return window.location = url;
  }

  static initRefSwitcher() {
    var refListItem = document.createElement('li');
    var refLink = document.createElement('a');

    refLink.href = '#';

    return $('.js-project-refs-dropdown').each(function() {
      var $dropdown, selected;
      $dropdown = $(this);
      selected = $dropdown.data('selected');
      return $dropdown.glDropdown({
        data(term, callback) {
          axios.get($dropdown.data('refsUrl'), {
            params: {
              ref: $dropdown.data('ref'),
              search: term,
            },
          })
          .then(({ data }) => callback(data))
          .catch(() => flash(__('An error occurred while getting projects')));
        },
        selectable: true,
        filterable: true,
        filterRemote: true,
        filterByText: true,
        inputFieldName: $dropdown.data('inputFieldName'),
        fieldName: $dropdown.data('fieldName'),
        renderRow: function(ref) {
          var li = refListItem.cloneNode(false);

          if (ref.header != null) {
            li.className = 'dropdown-header';
            li.textContent = ref.header;
          } else {
            var link = refLink.cloneNode(false);

            if (ref === selected) {
              link.className = 'is-active';
            }

            link.textContent = ref;
            link.dataset.ref = ref;

            li.appendChild(link);
          }

          return li;
        },
        id: function(obj, $el) {
          return $el.attr('data-ref');
        },
        toggleLabel: function(obj, $el) {
          return $el.text().trim();
        },
        clicked: function(options) {
          const { e } = options;
          e.preventDefault();
          if ($('input[name="ref"]').length) {
            var $form = $dropdown.closest('form');

            var $visit = $dropdown.data('visit');
            var shouldVisit = $visit ? true : $visit;
            var action = $form.attr('action');
            var divider = action.indexOf('?') === -1 ? '?' : '&';
            if (shouldVisit) {
              visitUrl(`${action}${divider}${$form.serialize()}`);
            }
          }
        },
      });
    });
  }
}
