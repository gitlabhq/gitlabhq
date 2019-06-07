/* eslint-disable func-names, no-new, promise/catch-or-return */

import $ from 'jquery';
import axios from '~/lib/utils/axios_utils';
import CreateLabelDropdown from '../../create_label';
import boardsStore from '../stores/boards_store';

$(document)
  .off('created.label')
  .on('created.label', (e, label, addNewList) => {
    if (!addNewList) {
      return;
    }

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
  });

export default function initNewListDropdown() {
  $('.js-new-board-list').each(function() {
    const $this = $(this);
    new CreateLabelDropdown(
      $this.closest('.dropdown').find('.dropdown-new-label'),
      $this.data('namespacePath'),
      $this.data('projectPath'),
    );

    $this.glDropdown({
      data(term, callback) {
        axios.get($this.attr('data-list-labels-path')).then(({ data }) => {
          callback(data);
        });
      },
      renderRow(label) {
        const active = boardsStore.findListByLabelId(label.id);
        const $li = $('<li />');
        const $a = $('<a />', {
          class: active ? `is-active js-board-list-${active.id}` : '',
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

        if (!boardsStore.findListByLabelId(label.id)) {
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
