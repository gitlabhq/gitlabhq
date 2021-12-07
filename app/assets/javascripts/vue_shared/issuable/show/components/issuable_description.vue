<script>
import { GlSafeHtmlDirective as SafeHtml } from '@gitlab/ui';
import $ from 'jquery';
import '~/behaviors/markdown/render_gfm';

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
    this.renderGFM();
  },
  methods: {
    renderGFM() {
      $(this.$refs.gfmContainer).renderGFM();
    },
  },
};
</script>

<template>
  <div class="description" :class="{ 'js-task-list-container': canEdit && enableTaskList }">
    <div ref="gfmContainer" v-safe-html="issuable.descriptionHtml" class="md"></div>
    <textarea
      v-if="issuable.description && enableTaskList"
      ref="textarea"
      :value="issuable.description"
      :data-update-url="taskListUpdatePath"
      class="gl-display-none js-task-list-field"
      dir="auto"
    >
    </textarea>
  </div>
</template>
