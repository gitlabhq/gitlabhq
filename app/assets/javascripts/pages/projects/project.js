/* eslint-disable func-names, no-return-assign */

import $ from 'jquery';
import { setCookie } from '~/lib/utils/common_utils';
import initClonePanel from '~/clone_panel';
import initDeprecatedJQueryDropdown from '~/deprecated_jquery_dropdown';
import { createAlert } from '~/flash';
import axios from '~/lib/utils/axios_utils';
import { serializeForm } from '~/lib/utils/forms';
import { mergeUrlParams } from '~/lib/utils/url_utility';
import { __ } from '~/locale';

const BRANCH_REF_TYPE = 'heads';
const TAG_REF_TYPE = 'tags';
const BRANCH_GROUP_NAME = __('Branches');
const TAG_GROUP_NAME = __('Tags');

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

    $('.js-hide-no-ssh-message').on('click', function (e) {
      setCookie('hide_no_ssh_message', 'false');
      $(this).parents('.js-no-ssh-key-message').remove();
      return e.preventDefault();
    });
    $('.js-hide-no-password-message').on('click', function (e) {
      setCookie('hide_no_password_message', 'false');
      $(this).parents('.js-no-password-message').remove();
      return e.preventDefault();
    });
    $('.hide-auto-devops-implicitly-enabled-banner').on('click', function (e) {
      const projectId = $(this).data('project-id');
      const cookieKey = `hide_auto_devops_implicitly_enabled_banner_${projectId}`;
      setCookie(cookieKey, 'false');
      $(this).parents('.auto-devops-implicitly-enabled-banner').remove();
      return e.preventDefault();
    });
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
      const refType = $dropdown.data('refType');
      const fieldName = $dropdown.data('fieldName');
      const shouldVisit = Boolean($dropdown.data('visit'));
      const $form = $dropdown.closest('form');
      const path = $form.find('#path').val();
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
              createAlert({
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
        renderRow(ref, _, params) {
          const li = refListItem.cloneNode(false);

          const link = refLink.cloneNode(false);

          if (ref === selected) {
            // Check group and current ref type to avoid adding a class when tags and branches share the same name
            if (
              (refType === BRANCH_REF_TYPE && params.group === BRANCH_GROUP_NAME) ||
              (refType === TAG_REF_TYPE && params.group === TAG_GROUP_NAME) ||
              !refType
            ) {
              link.className = 'is-active';
            }
          }

          link.textContent = ref;
          link.dataset.ref = ref;
          if (ref.length > 0 && shouldVisit) {
            const urlParams = { [fieldName]: ref };
            if (params.group === BRANCH_GROUP_NAME) {
              urlParams.ref_type = BRANCH_REF_TYPE;
            } else if (params.group === TAG_GROUP_NAME) {
              urlParams.ref_type = TAG_REF_TYPE;
            }

            link.href = mergeUrlParams(urlParams, linkTarget);
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

          if (!shouldVisit) {
            e.preventDefault();
          }

          // Some pages need to dynamically get the current path
          // so they can opt-in to JS getting the path from the
          // current URL by not setting a path in the dropdown form
          if (shouldVisit && path === undefined) {
            e.preventDefault();

            const selectedUrl = new URL(e.target.href);
            const loc = window.location.href;

            if (loc.includes('/-/')) {
              const currentRef = $dropdown.data('ref');
              // The split and startWith is to ensure an exact word match
              // and avoid partial match ie. currentRef is "dev" and loc is "development"
              const splitPathAfterRefPortion = loc.split('/-/')[1].split(currentRef)[1];
              const doesPathContainRef = splitPathAfterRefPortion?.startsWith('/');

              if (doesPathContainRef) {
                // We are ignoring the url containing the ref portion
                // and plucking the thereafter portion to reconstructure the url that is correct
                const targetPath = splitPathAfterRefPortion?.slice(1).split('#')[0].split('?')[0];
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
