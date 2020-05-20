import $ from 'jquery';
import Vue from 'vue';
import collapseIcon from './icons/fullscreen_collapse.svg';
import expandIcon from './icons/fullscreen_expand.svg';

export default (ModalStore, boardsStore) => {
  const issueBoardsContent = document.querySelector('.content-wrapper > .js-focus-mode-board');

  return new Vue({
    el: document.getElementById('js-toggle-focus-btn'),
    data: {
      modal: ModalStore.store,
      store: boardsStore.state,
      isFullscreen: false,
    },
    methods: {
      toggleFocusMode() {
        $(this.$refs.toggleFocusModeButton).tooltip('hide');
        issueBoardsContent.classList.toggle('is-focused');

        this.isFullscreen = !this.isFullscreen;
      },
    },
    template: `
      <div class="board-extra-actions">
        <a
          href="#"
          class="btn btn-default has-tooltip prepend-left-10 js-focus-mode-btn"
          data-qa-selector="focus_mode_button"
          role="button"
          aria-label="Toggle focus mode"
          title="Toggle focus mode"
          ref="toggleFocusModeButton"
          @click="toggleFocusMode">
          <span v-show="isFullscreen">
            ${collapseIcon}
          </span>
          <span v-show="!isFullscreen">
            ${expandIcon}
          </span>
        </a>
      </div>
    `,
  });
};
