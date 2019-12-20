<script>
import Cookies from 'js-cookie';
import { __ } from '~/locale';
import ListLabel from '~/boards/models/label';
import boardsStore from '../stores/boards_store';

export default {
  data() {
    return {
      predefinedLabels: [
        new ListLabel({ title: __('To Do'), color: '#F0AD4E' }),
        new ListLabel({ title: __('Doing'), color: '#5CB85C' }),
      ],
    };
  },
  methods: {
    addDefaultLists() {
      this.clearBlankState();

      this.predefinedLabels.forEach((label, i) => {
        boardsStore.addList({
          title: label.title,
          position: i,
          list_type: 'label',
          label: {
            title: label.title,
            color: label.color,
          },
        });
      });

      const loadListIssues = listObj => {
        const list = boardsStore.findList('title', listObj.title);

        if (!list) {
          return null;
        }

        list.id = listObj.id;
        list.label.id = listObj.label.id;
        return list.getIssues().catch(() => {
          // TODO: handle request error
        });
      };

      // Save the labels
      boardsStore
        .generateDefaultLists()
        .then(res => res.data)
        .then(data => Promise.all(data.map(loadListIssues)))
        .catch(() => {
          boardsStore.removeList(undefined, 'label');
          Cookies.remove('issue_board_welcome_hidden', {
            path: '',
          });
          boardsStore.addBlankState();
        });
    },
    clearBlankState: boardsStore.removeBlankState.bind(boardsStore),
  },
};
</script>

<template>
  <div class="board-blank-state p-3">
    <p>
      {{
        s__('BoardBlankState|Add the following default lists to your Issue Board with one click:')
      }}
    </p>
    <ul class="list-unstyled board-blank-state-list">
      <li v-for="(label, index) in predefinedLabels" :key="index">
        <span
          :style="{ backgroundColor: label.color }"
          class="label-color position-relative d-inline-block rounded"
        ></span>
        {{ label.title }}
      </li>
    </ul>
    <p>
      {{
        s__(
          'BoardBlankState|Starting out with the default set of lists will get you right on the way to making the most of your board.',
        )
      }}
    </p>
    <button
      class="btn btn-success btn-inverted btn-block"
      type="button"
      @click.stop="addDefaultLists"
    >
      {{ s__('BoardBlankState|Add default lists') }}
    </button>
    <button class="btn btn-default btn-block" type="button" @click.stop="clearBlankState">
      {{ s__("BoardBlankState|Nevermind, I'll use my own") }}
    </button>
  </div>
</template>
