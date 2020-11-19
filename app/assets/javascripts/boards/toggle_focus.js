import $ from 'jquery';
import Vue from 'vue';
import { GlIcon } from '@gitlab/ui';
import { hide } from '~/tooltips';

export default (ModalStore, boardsStore) => {
  const issueBoardsContent = document.querySelector('.content-wrapper > .js-focus-mode-board');

  return new Vue({
    el: document.getElementById('js-toggle-focus-btn'),
    components: {
      GlIcon,
    },
    data: {
      modal: ModalStore.store,
      store: boardsStore.state,
      isFullscreen: false,
    },
    methods: {
      toggleFocusMode() {
        const $el = $(this.$refs.toggleFocusModeButton);
        hide($el);

        issueBoardsContent.classList.toggle('is-focused');

        this.isFullscreen = !this.isFullscreen;
      },
    },
    template: `
      <div class="board-extra-actions">
        <a
          href="#"
          class="btn btn-default has-tooltip gl-ml-3 js-focus-mode-btn"
          data-qa-selector="focus_mode_button"
          role="button"
          aria-label="Toggle focus mode"
          title="Toggle focus mode"
          ref="toggleFocusModeButton"
          @click="toggleFocusMode">
          <gl-icon :name="isFullscreen ? 'minimize' : 'maximize'" />
        </a>
      </div>
    `,
  });
};
