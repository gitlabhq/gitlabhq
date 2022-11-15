import Vue from 'vue';
import $ from 'jquery';
import { escape } from 'lodash';
import GroupSelect from '~/vue_shared/components/group_select/group_select.vue';
import { groupsPath } from '~/vue_shared/components/group_select/utils';
import { __ } from '~/locale';
import Api from './api';
import { loadCSSFile } from './lib/utils/css_utils';
import { select2AxiosTransport } from './lib/utils/select2_utils';

const initVueSelect = () => {
  [...document.querySelectorAll('.ajax-groups-select')].forEach((el) => {
    const { parentId: parentGroupID, groupsFilter, inputId } = el.dataset;

    return new Vue({
      el,
      components: {
        GroupSelect,
      },
      render(createElement) {
        return createElement(GroupSelect, {
          props: {
            inputName: el.name,
            initialSelection: el.value || null,
            parentGroupID,
            groupsFilter,
            inputId,
            clearable: el.classList.contains('allowClear'),
          },
        });
      },
    });
  });
};

const groupsSelect = () => {
  loadCSSFile(gon.select2_css_path)
    .then(() => {
      // Needs to be accessible in rspec
      window.GROUP_SELECT_PER_PAGE = 20;

      $('.ajax-groups-select').each(function setAjaxGroupsSelect2() {
        const $select = $(this);
        const allAvailable = $select.data('allAvailable');
        const skipGroups = $select.data('skipGroups') || [];
        const parentGroupID = $select.data('parentId');
        const groupsFilter = $select.data('groupsFilter');
        const minAccessLevel = $select.data('minAccessLevel');

        $select.select2({
          placeholder: __('Search for a group'),
          allowClear: $select.hasClass('allowClear'),
          multiple: $select.hasClass('multiselect'),
          minimumInputLength: 0,
          ajax: {
            url: Api.buildUrl(groupsPath(groupsFilter, parentGroupID)),
            dataType: 'json',
            quietMillis: 250,
            transport: select2AxiosTransport,
            data(search, page) {
              return {
                search,
                page,
                per_page: window.GROUP_SELECT_PER_PAGE,
                all_available: allAvailable,
                min_access_level: minAccessLevel,
              };
            },
            results(data, page) {
              const groups = data.length ? data : data.results || [];
              const more = data.pagination ? data.pagination.more : false;
              const results = groups.filter((group) => skipGroups.indexOf(group.id) === -1);

              return {
                results,
                page,
                more,
              };
            },
          },
          // eslint-disable-next-line consistent-return
          initSelection(element, callback) {
            const id = $(element).val();
            if (id !== '') {
              return Api.group(id, callback);
            }
          },
          formatResult(object) {
            return `<div class='group-result'> <div class='group-name'>${escape(
              object.full_name,
            )}</div> <div class='group-path'>${object.full_path}</div> </div>`;
          },
          formatSelection(object) {
            return escape(object.full_name);
          },
          dropdownCssClass: 'ajax-groups-dropdown select2-infinite',
          // we do not want to escape markup since we are displaying html in results
          escapeMarkup(m) {
            return m;
          },
        });

        $select.on('select2-loaded', () => {
          const dropdown = document.querySelector('.select2-infinite .select2-results');
          dropdown.style.height = `${Math.floor(dropdown.scrollHeight)}px`;
        });
      });
    })
    .catch(() => {});
};

export default () => {
  if ($('.ajax-groups-select').length) {
    if (gon.features?.vueGroupSelect) {
      initVueSelect();
    } else {
      import(/* webpackChunkName: 'select2' */ 'select2/select2')
        .then(groupsSelect)
        .catch(() => {});
    }
  }
};
