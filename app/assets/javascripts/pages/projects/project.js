/* eslint-disable func-names, no-var, no-return-assign, one-var,
 one-var-declaration-per-line, object-shorthand, vars-on-top */

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
    const $cloneBtnLabel = $('.js-git-clone-holder .js-clone-dropdown-label');

    const selectedCloneOption = $cloneBtnLabel.text().trim();
    if (selectedCloneOption.length > 0) {
      $(`a:contains('${selectedCloneOption}')`, $cloneOptions).addClass('is-active');
    }

    $('a', $cloneOptions).on('click', e => {
      e.preventDefault();
      const $this = $(e.currentTarget);
      const url = $this.attr('href');
      const cloneType = $this.data('cloneType');

      $('.is-active', $cloneOptions).removeClass('is-active');
      $(`a[data-clone-type="${cloneType}"]`).each(function() {
        const $el = $(this);
        const activeText = $el.find('.dropdown-menu-inner-title').text();
        const $container = $el.closest('.project-clone-holder');
        const $label = $container.find('.js-clone-dropdown-label');

        $el.toggleClass('is-active');
        $label.text(activeText);
      });

      $projectCloneField.val(url);
      $('.js-git-empty .js-clone').text(url);
    });
    // Ref switcher
    Project.initRefSwitcher();
    $('.project-refs-select').on('change', function() {
      return $(this)
        .parents('form')
        .submit();
    });
    $('.hide-no-ssh-message').on('click', function(e) {
      Cookies.set('hide_no_ssh_message', 'false');
      $(this)
        .parents('.no-ssh-key-message')
        .remove();
      return e.preventDefault();
    });
    $('.hide-no-password-message').on('click', function(e) {
      Cookies.set('hide_no_password_message', 'false');
      $(this)
        .parents('.no-password-message')
        .remove();
      return e.preventDefault();
    });
    $('.hide-auto-devops-implicitly-enabled-banner').on('click', function(e) {
      const projectId = $(this).data('project-id');
      const cookieKey = `hide_auto_devops_implicitly_enabled_banner_${projectId}`;
      Cookies.set(cookieKey, 'false');
      $(this).parents('.auto-devops-implicitly-enabled-banner').remove();
      return e.preventDefault();
    });
    Project.projectSelectDropdown();
  }

  static projectSelectDropdown() {
    projectSelect();
    $('.project-item-select').on('click', e => Project.changeProject($(e.currentTarget).val()));
  }

  static changeProject(url) {
    return (window.location = url);
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
          axios
            .get($dropdown.data('refsUrl'), {
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
