/* eslint-disable func-names, no-new */

import $ from 'jquery';
import store from '~/boards/stores';
import initDeprecatedJQueryDropdown from '~/deprecated_jquery_dropdown';
import createFlash from '~/flash';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import axios from '~/lib/utils/axios_utils';
import { __ } from '~/locale';
import CreateLabelDropdown from '../../create_label';
import { fullLabelId } from '../boards_util';
import boardsStore from '../stores/boards_store';

function shouldCreateListGraphQL(label) {
  return store.getters.shouldUseGraphQL && !store.getters.getListByLabelId(fullLabelId(label));
}

// eslint-disable-next-line @gitlab/no-global-event-off
$(document)
  .off('created.label')
  .on('created.label', (e, label, addNewList) => {
    if (!addNewList) {
      return;
    }

    if (shouldCreateListGraphQL(label)) {
      store.dispatch('createList', { labelId: fullLabelId(label) });
    } else {
      boardsStore.new({
        title: label.title,
        position: boardsStore.state.lists.length - 2,
        list_type: 'label',
        label: {
          id: label.id,
          title: label.title,
          color: label.color,
        },
      });
    }
  });

export default function initNewListDropdown() {
  $('.js-new-board-list').each(function () {
    const $dropdownToggle = $(this);
    const $dropdown = $dropdownToggle.closest('.dropdown');
    new CreateLabelDropdown(
      $dropdown.find('.dropdown-new-label'),
      $dropdownToggle.data('namespacePath'),
      $dropdownToggle.data('projectPath'),
    );

    initDeprecatedJQueryDropdown($dropdownToggle, {
      data(term, callback) {
        const reqFailed = () => {
          $dropdownToggle.data('bs.dropdown').hide();
          createFlash({
            message: __('Error fetching labels.'),
          });
        };

        if (store.getters.shouldUseGraphQL) {
          store
            .dispatch('fetchLabels')
            .then((data) => callback(data))
            .catch(reqFailed);
        } else {
          axios
            .get($dropdownToggle.attr('data-list-labels-path'))
            .then(({ data }) => callback(data))
            .catch(reqFailed);
        }
      },
      renderRow(label) {
        const active = store.getters.shouldUseGraphQL
          ? store.getters.getListByLabelId(label.id)
          : boardsStore.findListByLabelId(label.id);
        const $li = $('<li />');
        const $a = $('<a />', {
          class: active ? `is-active js-board-list-${getIdFromGraphQLId(active.id)}` : '',
          text: label.title,
          href: '#',
        });
        const $labelColor = $('<span />', {
          class: 'dropdown-label-box',
          style: `background-color: ${label.color}`,
        });

        return $li.append($a.prepend($labelColor));
      },
      search: {
        fields: ['title'],
      },
      filterable: true,
      selectable: true,
      multiSelect: true,
      containerSelector: '.js-tab-container-labels .dropdown-page-one .dropdown-content',
      clicked(options) {
        const { e } = options;
        const label = options.selectedObj;
        e.preventDefault();

        if (shouldCreateListGraphQL(label)) {
          store.dispatch('createList', { labelId: label.id });
        } else if (!boardsStore.findListByLabelId(label.id)) {
          boardsStore.new({
            title: label.title,
            position: boardsStore.state.lists.length - 2,
            list_type: 'label',
            label: {
              id: label.id,
              title: label.title,
              color: label.color,
            },
          });
        }
      },
    });
  });
}
