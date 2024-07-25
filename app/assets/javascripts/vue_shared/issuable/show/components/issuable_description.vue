<script>
import SafeHtml from '~/vue_shared/directives/safe_html';
import { renderGFM } from '~/behaviors/markdown/render_gfm';

export default {
  directives: {
    SafeHtml,
  },
  props: {
    issuable: {
      type: Object,
      required: true,
    },
    enableTaskList: {
      type: Boolean,
      required: true,
    },
    canEdit: {
      type: Boolean,
      required: true,
    },
    taskListUpdatePath: {
      type: String,
      required: true,
    },
  },
  mounted() {
    renderGFM(this.$refs.gfmContainer);
  },
};
</script>

<template>
  <div
    class="description"
    :class="{ 'js-task-list-container': canEdit && enableTaskList }"
    data-testid="description-content"
  >
    <div ref="gfmContainer" v-safe-html="issuable.descriptionHtml" class="md"></div>
    <textarea
      v-if="issuable.description && enableTaskList"
      ref="textarea"
      :value="issuable.description"
      :data-update-url="taskListUpdatePath"
      class="js-task-list-field gl-hidden"
      dir="auto"
    >
    </textarea>
  </div>
</template>
