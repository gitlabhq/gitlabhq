<script>
import markdownField from '~/vue_shared/components/markdown/field.vue';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import updateMixin from '../../mixins/update';

export default {
  components: {
    markdownField,
  },
  mixins: [glFeatureFlagsMixin(), updateMixin],
  props: {
    formState: {
      type: Object,
      required: true,
    },
    markdownPreviewPath: {
      type: String,
      required: true,
    },
    markdownDocsPath: {
      type: String,
      required: true,
    },
    canAttachFile: {
      type: Boolean,
      required: false,
      default: true,
    },
    enableAutocomplete: {
      type: Boolean,
      required: false,
      default: true,
    },
  },
  mounted() {
    this.$refs.textarea.focus();
  },
};
</script>

<template>
  <div class="common-note-form">
    <label class="sr-only" for="issue-description">{{ __('Description') }}</label>
    <markdown-field
      :markdown-preview-path="markdownPreviewPath"
      :markdown-docs-path="markdownDocsPath"
      :can-attach-file="canAttachFile"
      :enable-autocomplete="enableAutocomplete"
      :textarea-value="formState.description"
    >
      <template #textarea>
        <!-- eslint-disable vue/no-mutating-props -->
        <textarea
          id="issue-description"
          ref="textarea"
          v-model="formState.description"
          class="note-textarea js-gfm-input js-autosize markdown-area qa-description-textarea"
          dir="auto"
          :data-supports-quick-actions="!glFeatures.tributeAutocomplete"
          :aria-label="__('Description')"
          :placeholder="__('Write a comment or drag your files here…')"
          @keydown.meta.enter="updateIssuable"
          @keydown.ctrl.enter="updateIssuable"
        >
        </textarea>
        <!-- eslint-enable vue/no-mutating-props -->
      </template>
    </markdown-field>
  </div>
</template>
