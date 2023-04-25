<script>
import { GlForm, GlFormInput, GlFormGroup } from '@gitlab/ui';
import MarkdownField from '~/vue_shared/components/markdown/field.vue';
import LabelsSelect from '~/sidebar/components/labels/labels_select_vue/labels_select_root.vue';
import { VARIANT_EMBEDDED } from '~/sidebar/components/labels/labels_select_widget/constants';

export default {
  VARIANT_EMBEDDED,
  components: {
    GlForm,
    GlFormInput,
    GlFormGroup,
    MarkdownField,
    LabelsSelect,
  },
  props: {
    descriptionPreviewPath: {
      type: String,
      required: true,
    },
    descriptionHelpPath: {
      type: String,
      required: true,
    },
    labelsFetchPath: {
      type: String,
      required: true,
    },
    labelsManagePath: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      issuableTitle: '',
      issuableDescription: '',
      selectedLabels: [],
    };
  },
  computed: {},
  methods: {
    handleUpdateSelectedLabels(labels) {
      if (labels.length) {
        this.selectedLabels = labels;
      }
    },
  },
};
</script>

<template>
  <gl-form class="common-note-form gfm-form" @submit.stop.prevent>
    <div data-testid="issuable-title" class="row">
      <label for="issuable-title" class="col-12 gl-mb-0">{{ __('Title') }}</label>
      <div class="col-12">
        <gl-form-group :description="__('Maximum of 255 characters')">
          <gl-form-input
            id="issuable-title"
            v-model="issuableTitle"
            maxlength="255"
            :autofocus="true"
            :placeholder="__('Title')"
          />
        </gl-form-group>
      </div>
    </div>
    <div data-testid="issuable-description" class="form-group row">
      <label for="issuable-description" class="col-12">{{ __('Description') }}</label>
      <div class="col-12">
        <markdown-field
          :markdown-preview-path="descriptionPreviewPath"
          :markdown-docs-path="descriptionHelpPath"
          :add-spacing-classes="false"
          :show-suggest-popover="true"
          :textarea-value="issuableDescription"
        >
          <template #textarea>
            <textarea
              id="issuable-description"
              ref="textarea"
              v-model="issuableDescription"
              dir="auto"
              class="note-textarea rspec-issuable-form-description js-gfm-input js-autosize markdown-area"
              data-qa-selector="issuable_form_description_field"
              :aria-label="__('Description')"
              :placeholder="__('Write a comment or drag your files here…')"
            ></textarea>
          </template>
        </markdown-field>
      </div>
    </div>
    <div data-testid="issuable-labels" class="form-group row">
      <label for="issuable-labels" class="col-12">{{ __('Labels') }}</label>
      <div class="col-12">
        <div class="issuable-form-select-holder">
          <labels-select
            :allow-label-edit="true"
            :allow-label-create="true"
            :allow-multiselect="true"
            :allow-scoped-labels="true"
            :labels-fetch-path="labelsFetchPath"
            :labels-manage-path="labelsManagePath"
            :selected-labels="selectedLabels"
            :labels-list-title="__('Select label')"
            :footer-create-label-title="__('Create project label')"
            :footer-manage-label-title="__('Manage project labels')"
            :variant="$options.VARIANT_EMBEDDED"
            @updateSelectedLabels="handleUpdateSelectedLabels"
          />
        </div>
      </div>
    </div>
    <div data-testid="issuable-create-actions" class="footer-block gl-display-flex gl-mt-6">
      <slot
        name="actions"
        :issuable-title="issuableTitle"
        :issuable-description="issuableDescription"
        :selected-labels="selectedLabels"
      ></slot>
    </div>
  </gl-form>
</template>
