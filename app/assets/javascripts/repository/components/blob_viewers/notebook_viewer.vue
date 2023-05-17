<script>
import { stripPathTail } from '~/lib/utils/url_utility';
import NotebookViewer from '~/blob/notebook/notebook_viewer.vue';

export default {
  components: { NotebookViewer },
  provide() {
    // `relativeRawPath` is injected in app/assets/javascripts/notebook/cells/markdown.vue
    // It is needed for images in Markdown cells that reference local files to work.
    // See the following MR for more context:
    // https://gitlab.com/gitlab-org/gitlab/-/merge_requests/69075
    return { relativeRawPath: stripPathTail(this.url) };
  },
  props: {
    blob: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      url: this.blob.rawPath,
    };
  },
};
</script>

<template>
  <notebook-viewer :endpoint="url" />
</template>
