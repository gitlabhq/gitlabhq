<script>
import { GlFormTextarea } from '@gitlab/ui';

import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';

import RichContentEditor from '~/vue_shared/components/rich_content_editor/rich_content_editor.vue';
import PublishToolbar from '../components/publish_toolbar.vue';
import EditHeader from '../components/edit_header.vue';

export default {
  components: {
    GlFormTextarea,
    RichContentEditor,
    PublishToolbar,
    EditHeader,
  },
  mixins: [glFeatureFlagsMixin()],
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
  <div class="d-flex flex-grow-1 flex-column">
    <edit-header class="py-2" :title="title" />
    <rich-content-editor v-if="glFeatures.richContentEditor" v-model="editableContent" />
    <gl-form-textarea v-else v-model="editableContent" class="h-100 shadow-none" />
    <publish-toolbar
      class="gl-fixed gl-left-0 gl-bottom-0 gl-w-full"
      :return-url="returnUrl"
      :saveable="modified"
      :saving-changes="savingChanges"
      @submit="onSubmit"
    />
  </div>
</template>
