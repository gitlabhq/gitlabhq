import Vue from 'vue';
import ModalStore from '../../stores/modal_store';

gl.issueBoards.ModalFooterListsDropdown = Vue.extend({
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
  template: `
    <div class="dropdown inline">
      <button
        class="dropdown-menu-toggle"
        type="button"
        data-toggle="dropdown"
        aria-expanded="false">
        <span
          class="dropdown-label-box"
          :style="{ backgroundColor: selected.label.color }">
        </span>
        {{ selected.title }}
        <i class="fa fa-chevron-down"></i>
      </button>
      <div class="dropdown-menu dropdown-menu-selectable dropdown-menu-drop-up">
        <ul>
          <li
            v-for="list in state.lists"
            v-if="list.type == 'label'">
            <a
              href="#"
              role="button"
              :class="{ 'is-active': list.id == selected.id }"
              @click.prevent="modal.selectedList = list">
              <span
                class="dropdown-label-box"
                :style="{ backgroundColor: list.label.color }">
              </span>
              {{ list.title }}
            </a>
          </li>
        </ul>
      </div>
    </div>
  `,
});
