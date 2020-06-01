<script>
import RichContentEditor from '~/vue_shared/components/rich_content_editor/rich_content_editor.vue';
import PublishToolbar from './publish_toolbar.vue';
import EditHeader from './edit_header.vue';

export default {
  components: {
    RichContentEditor,
    PublishToolbar,
    EditHeader,
  },
  props: {
    title: {
      type: String,
      required: true,
    },
    content: {
      type: String,
      required: true,
    },
    savingChanges: {
      type: Boolean,
      required: true,
    },
    returnUrl: {
      type: String,
      required: false,
      default: '',
    },
  },
  data() {
    return {
      editableContent: this.content,
      saveable: false,
    };
  },
  computed: {
    modified() {
      return this.content !== this.editableContent;
    },
  },
  methods: {
    onSubmit() {
      this.$emit('submit', { content: this.editableContent });
    },
  },
};
</script>
<template>
  <div class="d-flex flex-grow-1 flex-column h-100">
    <edit-header class="py-2" :title="title" />
    <rich-content-editor v-model="editableContent" class="mb-9 h-100" />
    <publish-toolbar
      class="gl-fixed gl-left-0 gl-bottom-0 gl-w-full"
      :return-url="returnUrl"
      :saveable="modified"
      :saving-changes="savingChanges"
      @submit="onSubmit"
    />
  </div>
</template>
