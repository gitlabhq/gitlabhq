<script>
import ModalStore from '../../stores/modal_store';

export default {
  data() {
    return {
      modal: ModalStore.store,
      state: gl.issueBoards.BoardsStore.state,
    };
  },
  computed: {
    selected() {
      return this.modal.selectedList || this.state.lists[1];
    },
  },
  destroyed() {
    this.modal.selectedList = null;
  },
};
</script>
<template>
  <div class="dropdown inline">
    <button
      class="dropdown-menu-toggle"
      type="button"
      data-toggle="dropdown"
      aria-expanded="false">
      <span
        :style="{ backgroundColor: selected.label.color }"
        class="dropdown-label-box">
      </span>
      {{ selected.title }}
      <i class="fa fa-chevron-down"></i>
    </button>
    <div class="dropdown-menu dropdown-menu-selectable dropdown-menu-drop-up">
      <ul>
        <li
          v-for="(list, i) in state.lists"
          v-if="list.type == 'label'"
          :key="i">
          <a
            :class="{ 'is-active': list.id == selected.id }"
            href="#"
            role="button"
            @click.prevent="modal.selectedList = list">
            <span
              :style="{ backgroundColor: list.label.color }"
              class="dropdown-label-box">
            </span>
            {{ list.title }}
          </a>
        </li>
      </ul>
    </div>
  </div>
</template>
