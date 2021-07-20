/* eslint-disable func-names, no-return-assign */

import $ from 'jquery';
import Cookies from 'js-cookie';
import initClonePanel from '~/clone_panel';
import initDeprecatedJQueryDropdown from '~/deprecated_jquery_dropdown';
import createFlash from '~/flash';
import axios from '~/lib/utils/axios_utils';
import { serializeForm } from '~/lib/utils/forms';
import { mergeUrlParams } from '~/lib/utils/url_utility';
import { __ } from '~/locale';
import projectSelect from '../../project_select';

export default class Project {
  constructor() {
    initClonePanel();

    // Ref switcher
    if (document.querySelector('.js-project-refs-dropdown')) {
      Project.initRefSwitcher();
      $('.project-refs-select').on('change', function () {
        return $(this).parents('form').trigger('submit');
      });
    }

    $('.hide-no-ssh-message').on('click', function (e) {
      Cookies.set('hide_no_ssh_message', 'false');
      $(this).parents('.no-ssh-key-message').remove();
      return e.preventDefault();
    });
    $('.hide-no-password-message').on('click', function (e) {
      Cookies.set('hide_no_password_message', 'false');
      $(this).parents('.no-password-message').remove();
      return e.preventDefault();
    });
    $('.hide-auto-devops-implicitly-enabled-banner').on('click', function (e) {
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
    $('.project-item-select').on('click', (e) => Project.changeProject($(e.currentTarget).val()));
  }

  static changeProject(url) {
    return (window.location = url);
  }

  static initRefSwitcher() {
    const refListItem = document.createElement('li');
    const refLink = document.createElement('a');

    refLink.href = '#';

    return $('.js-project-refs-dropdown').each(function () {
      const $dropdown = $(this);
      const selected = $dropdown.data('selected');
      const fieldName = $dropdown.data('fieldName');
      const shouldVisit = Boolean($dropdown.data('visit'));
      const $form = $dropdown.closest('form');
      const action = $form.attr('action');
      const linkTarget = mergeUrlParams(serializeForm($form[0]), action);

      return initDeprecatedJQueryDropdown($dropdown, {
        data(term, callback) {
          axios
            .get($dropdown.data('refsUrl'), {
              params: {
                ref: $dropdown.data('ref'),
                search: term,
              },
            })
            .then(({ data }) => callback(data))
            .catch(() =>
              createFlash({
                message: __('An error occurred while getting projects'),
              }),
            );
        },
        selectable: true,
        filterable: true,
        filterRemote: true,
        filterByText: true,
        inputFieldName: $dropdown.data('inputFieldName'),
        fieldName,
        renderRow(ref) {
          const li = refListItem.cloneNode(false);

          const link = refLink.cloneNode(false);

          if (ref === selected) {
            link.className = 'is-active';
          }
          link.textContent = ref;
          link.dataset.ref = ref;
          if (ref.length > 0 && shouldVisit) {
            link.href = mergeUrlParams({ [fieldName]: ref }, linkTarget);
          }

          li.appendChild(link);

          return li;
        },
        id(obj, $el) {
          return $el.attr('data-ref');
        },
        toggleLabel(obj, $el) {
          return $el.text().trim();
        },
        clicked(options) {
          const { e } = options;
          e.preventDefault();

          // Since this page does not reload when changing directories in a repo
          // the rendered links do not have the path to the current directory.
          // This updates the path based on the current url and then opens
          // the the url with the updated path parameter.
          if (shouldVisit) {
            const selectedUrl = new URL(e.target.href);
            const loc = window.location.href;

            if (loc.includes('/-/')) {
              // Since the current ref in renderRow is outdated on page changes
              // (To be addressed in: https://gitlab.com/gitlab-org/gitlab/-/issues/327085)
              // We are deciphering the current ref from the dropdown data instead
              const currentRef = $dropdown.data('ref');
              // The split and startWith is to ensure an exact word match
              // and avoid partial match ie. currentRef is "dev" and loc is "development"
              const splitPathAfterRefPortion = loc.split('/-/')[1].split(currentRef)[1];
              const doesPathContainRef = splitPathAfterRefPortion?.startsWith('/');

              if (doesPathContainRef) {
                // We are ignoring the url containing the ref portion
                // and plucking the thereafter portion to reconstructure the url that is correct
                const targetPath = splitPathAfterRefPortion?.slice(1).split('#')[0];
                selectedUrl.searchParams.set('path', targetPath);
                selectedUrl.hash = window.location.hash;
              }
            }

            // Open in new window if "meta" key is pressed
            if (e.metaKey) {
              window.open(selectedUrl.href, '_blank');
            } else {
              window.location.href = selectedUrl.href;
            }
          }
        },
      });
    });
  }
}
