<script>
import { GlForm, GlFormGroup, GlFormInput } from '@gitlab/ui';
import { __ } from '~/locale';
import Autosave from '~/autosave';
import MarkdownEditor from '~/vue_shared/components/markdown/markdown_editor.vue';
import markdownEditorEventHub from '~/vue_shared/components/markdown/eventhub';
import { CLEAR_AUTOSAVE_ENTRY_EVENT } from '~/vue_shared/constants';
import ZenMode from '~/zen_mode';
import eventHub from '../event_hub';

export default {
  components: {
    GlForm,
    GlFormGroup,
    GlFormInput,
    MarkdownEditor,
  },
  props: {
    issuable: {
      type: Object,
      required: true,
    },
    enableAutocomplete: {
      type: Boolean,
      required: true,
    },
    enableAutosave: {
      type: Boolean,
      required: true,
    },
    enableZenMode: {
      type: Boolean,
      required: true,
    },
    showFieldTitle: {
      type: Boolean,
      required: true,
    },
    descriptionPreviewPath: {
      type: String,
      required: true,
    },
    descriptionHelpPath: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      title: '',
      description: '',
      formFieldProps: {
        id: 'issuable-description',
        name: 'issuable-description',
        'aria-label': __('Description'),
        placeholder: __('Write a comment or drag your files here…'),
        class: 'note-textarea js-gfm-input js-autosize markdown-area',
      },
    };
  },
  computed: {
    descriptionAutosaveKey() {
      if (this.enableAutosave)
        return [document.location.pathname, document.location.search, 'description'].join('/');
      return '';
    },
  },
  watch: {
    issuable: {
      handler(value) {
        this.title = value?.title || '';
        this.description = value?.description || '';
      },
      deep: true,
      immediate: true,
    },
  },
  created() {
    eventHub.$on('update.issuable', this.resetAutosave);
    eventHub.$on('close.form', this.resetAutosave);
  },
  mounted() {
    if (this.enableAutosave) this.initAutosave();

    // eslint-disable-next-line no-new
    if (this.enableZenMode) new ZenMode();
  },
  beforeDestroy() {
    eventHub.$off('update.issuable', this.resetAutosave);
    eventHub.$off('close.form', this.resetAutosave);
  },
  methods: {
    initAutosave() {
      const { titleInput } = this.$refs;

      if (!titleInput) return;

      this.autosaveTitle = new Autosave(titleInput.$el, [
        document.location.pathname,
        document.location.search,
        'title',
      ]);
    },
    resetAutosave() {
      this.autosaveTitle.reset();

      markdownEditorEventHub.$emit(CLEAR_AUTOSAVE_ENTRY_EVENT, this.descriptionAutosaveKey);
    },
    handleKeydown(e, inputType) {
      this.$emit(`keydown-${inputType}`, e, {
        issuableTitle: this.title,
        issuableDescription: this.description,
      });
    },
  },
};
</script>

<template>
  <gl-form>
    <gl-form-group
      data-testid="title"
      :label="__('Title')"
      :label-sr-only="!showFieldTitle"
      label-for="issuable-title"
      class="col-12 gl-px-0"
    >
      <gl-form-input
        id="issuable-title"
        ref="titleInput"
        v-model.trim="title"
        :placeholder="__('Title')"
        :aria-label="__('Title')"
        :autofocus="true"
        @keydown="handleKeydown($event, 'title')"
      />
    </gl-form-group>
    <gl-form-group
      data-testid="description"
      :label="__('Description')"
      :label-sr-only="!showFieldTitle"
      label-for="issuable-description"
      class="col-12 common-note-form gl-px-0"
    >
      <markdown-editor
        v-model="description"
        :render-markdown-path="descriptionPreviewPath"
        :markdown-docs-path="descriptionHelpPath"
        :enable-autocomplete="enableAutocomplete"
        :supports-quick-actions="enableAutocomplete"
        :form-field-props="formFieldProps"
        @keydown="handleKeydown($event, 'description')"
      />
    </gl-form-group>
    <div data-testid="actions" class="gl-my-3 gl-flex gl-flex-col gl-gap-3">
      <slot
        name="edit-form-actions"
        :issuable-title="title"
        :issuable-description="description"
      ></slot>
    </div>
  </gl-form>
</template>
