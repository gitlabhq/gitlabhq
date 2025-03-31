<script>
import SafeHtml from '~/vue_shared/directives/safe_html';
import { renderGFM } from '~/behaviors/markdown/render_gfm';
import { toggleCheckbox } from '~/behaviors/markdown/utils';

const isCheckbox = (target) => target?.classList.contains('task-list-item-checkbox');

export default {
  name: 'WorkItemNoteBody',
  directives: {
    SafeHtml,
  },
  props: {
    note: {
      type: Object,
      required: true,
    },
    hasAdminNotePermission: {
      type: Boolean,
      required: false,
      default: false,
    },
    hasReplies: {
      type: Boolean,
      required: false,
      default: false,
    },
    isUpdating: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  watch: {
    'note.bodyHtml': {
      immediate: true,
      async handler(newVal, oldVal) {
        if (newVal === oldVal) {
          return;
        }
        await this.$nextTick();
        this.renderGFM();
        this.disableCheckboxes(false);
      },
    },
    isUpdating: {
      handler(isUpdating) {
        this.disableCheckboxes(isUpdating);
      },
    },
  },
  methods: {
    renderGFM() {
      renderGFM(this.$refs['note-body']);
      gl?.lazyLoader?.searchLazyImages();
    },
    disableCheckboxes(disabled) {
      if (!this.hasAdminNotePermission) {
        return;
      }
      this.$el.querySelectorAll('.task-list-item-checkbox').forEach((checkbox) => {
        checkbox.disabled = disabled; // eslint-disable-line no-param-reassign
      });
    },
    toggleCheckboxes(event) {
      if (!this.hasAdminNotePermission) {
        return;
      }

      const { target } = event;

      if (!isCheckbox(target)) {
        return;
      }

      const { sourcepos } = target.parentElement.dataset;

      if (!sourcepos) {
        return;
      }

      const commentText = toggleCheckbox({
        rawMarkdown: this.note.body,
        checkboxChecked: target.checked,
        sourcepos,
      });

      this.$emit('updateNote', { commentText, executeOptimisticResponse: false });
    },
  },
  safeHtmlConfig: {
    ADD_TAGS: ['use', 'gl-emoji', 'copy-code'],
  },
};
</script>

<template>
  <div ref="note-body">
    <div
      v-safe-html:[$options.safeHtmlConfig]="note.bodyHtml"
      class="note-text md"
      data-testid="work-item-note-body"
      @change="toggleCheckboxes"
    ></div>
  </div>
</template>
