<script>
/* global ListLabel */
import _ from 'underscore';
import Cookies from 'js-cookie';

const Store = gl.issueBoards.BoardsStore;

export default {
  data() {
    return {
      predefinedLabels: [
        new ListLabel({ title: 'To Do', color: '#F0AD4E' }),
        new ListLabel({ title: 'Doing', color: '#5CB85C' }),
      ],
    };
  },
  methods: {
    addDefaultLists() {
      this.clearBlankState();

      this.predefinedLabels.forEach((label, i) => {
        Store.addList({
          title: label.title,
          position: i,
          list_type: 'label',
          label: {
            title: label.title,
            color: label.color,
          },
        });
      });

      Store.state.lists = _.sortBy(Store.state.lists, 'position');

      // Save the labels
      gl.boardService.generateDefaultLists()
        .then(res => res.data)
        .then((data) => {
          data.forEach((listObj) => {
            const list = Store.findList('title', listObj.title);

            list.id = listObj.id;
            list.label.id = listObj.label.id;
            list.getIssues()
              .catch(() => {
                // TODO: handle request error
              });
          });
        })
        .catch(() => {
          Store.removeList(undefined, 'label');
          Cookies.remove('issue_board_welcome_hidden', {
            path: '',
          });
          Store.addBlankState();
        });
    },
    clearBlankState: Store.removeBlankState.bind(Store),
  },
};

</script>

<template>
  <div class="board-blank-state">
    <p>
      Add the following default lists to your Issue Board with one click:
    </p>
    <ul class="board-blank-state-list">
      <li
        v-for="(label, index) in predefinedLabels"
        :key="index"
      >
        <span
          class="label-color"
          :style="{ backgroundColor: label.color }">
        </span>
        {{ label.title }}
      </li>
    </ul>
    <p>
      Starting out with the default set of lists will get you
      right on the way to making the most of your board.
    </p>
    <button
      class="btn btn-create btn-inverted btn-block"
      type="button"
      @click.stop="addDefaultLists">
      Add default lists
    </button>
    <button
      class="btn btn-default btn-block"
      type="button"
      @click.stop="clearBlankState">
      Nevermind, I'll use my own
    </button>
  </div>
</template>
