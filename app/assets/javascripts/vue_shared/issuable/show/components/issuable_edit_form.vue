<script>
import { GlForm, GlFormGroup, GlFormInput } from '@gitlab/ui';
import $ from 'jquery';

import Autosave from '~/autosave';
import MarkdownField from '~/vue_shared/components/markdown/field.vue';
import ZenMode from '~/zen_mode';

import eventHub from '../event_hub';

export default {
  components: {
    GlForm,
    GlFormGroup,
    GlFormInput,
    MarkdownField,
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
    };
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
      const { titleInput, descriptionInput } = this.$refs;

      if (!titleInput || !descriptionInput) return;

      this.autosaveTitle = new Autosave($(titleInput.$el), [
        document.location.pathname,
        document.location.search,
        'title',
      ]);

      this.autosaveDescription = new Autosave($(descriptionInput.$el), [
        document.location.pathname,
        document.location.search,
        'description',
      ]);
    },
    resetAutosave() {
      this.autosaveTitle.reset();
      this.autosaveDescription.reset();
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
        class="qa-title-input"
        @keydown="handleKeydown($event, 'title')"
      />
    </gl-form-group>
    <gl-form-group
      data-testid="description"
      :label="__('Description')"
      :label-sr-only="!showFieldTitle"
      label-for="issuable-description"
      label-class="gl-pb-0!"
      class="col-12 gl-px-0 common-note-form"
    >
      <markdown-field
        :markdown-preview-path="descriptionPreviewPath"
        :markdown-docs-path="descriptionHelpPath"
        :enable-autocomplete="enableAutocomplete"
        :textarea-value="description"
      >
        <template #textarea>
          <textarea
            id="issuable-description"
            ref="descriptionInput"
            v-model="description"
            :data-supports-quick-actions="enableAutocomplete"
            :aria-label="__('Description')"
            :placeholder="__('Write a comment or drag your files here…')"
            class="note-textarea js-gfm-input js-autosize markdown-area qa-description-textarea"
            dir="auto"
            @keydown="handleKeydown($event, 'description')"
          ></textarea>
        </template>
      </markdown-field>
    </gl-form-group>
    <div data-testid="actions" class="col-12 gl-mt-3 gl-mb-3 gl-px-0 clearfix">
      <slot
        name="edit-form-actions"
        :issuable-title="title"
        :issuable-description="description"
      ></slot>
    </div>
  </gl-form>
</template>
