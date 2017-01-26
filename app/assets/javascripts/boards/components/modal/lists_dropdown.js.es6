/* global Vue */
(() => {
  const ModalStore = gl.issueBoards.ModalStore;

  gl.issueBoards.ModalFooterListsDropdown = Vue.extend({
    data() {
      return {
        modal: ModalStore.store,
        state: gl.issueBoards.BoardsStore.state,
      };
    },
    computed: {
      selected() {
        return this.modal.selectedList;
      },
    },
    template: `
      <div class="dropdown inline">
        <button
          class="dropdown-menu-toggle"
          type="button"
          data-toggle="dropdown"
          aria-expanded="false">
          {{ selected.title }}
          <span
            class="dropdown-label-box pull-right"
            :style="{ backgroundColor: selected.label.color }">
          </span>
          <i class="fa fa-chevron-down"></i>
        </button>
        <div class="dropdown-menu dropdown-menu-selectable">
          <ul>
            <li
              v-for="list in state.lists"
              v-if="list.type == 'label'">
              <a
                href="#"
                role="button"
                :class="{ 'is-active': list.id == selected.id }"
                @click="modal.selectedList = list">
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
})();
