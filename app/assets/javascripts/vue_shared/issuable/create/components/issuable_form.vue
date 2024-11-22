<script>
import { GlForm, GlFormInput, GlFormCheckbox, GlFormGroup } from '@gitlab/ui';
import LabelsSelect from '~/sidebar/components/labels/labels_select_vue/labels_select_root.vue';
import { VARIANT_EMBEDDED } from '~/sidebar/components/labels/labels_select_widget/constants';
import MarkdownEditor from '~/vue_shared/components/markdown/markdown_editor.vue';
import { __, sprintf } from '~/locale';
import { issuableTypeText } from '~/issues/constants';

export default {
  VARIANT_EMBEDDED,
  components: {
    GlForm,
    GlFormInput,
    GlFormCheckbox,
    GlFormGroup,
    MarkdownEditor,
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
    issuableType: {
      type: String,
      required: true,
    },
  },
  descriptionFormFieldProps: {
    ariaLabel: __('Description'),
    class: 'rspec-issuable-form-description',
    placeholder: __('Write a comment or drag your files here…'),
    dataTestid: 'issuable-form-description-field',
    id: 'issuable-description',
    name: 'issuable-description',
  },
  data() {
    return {
      issuableTitle: '',
      issuableDescription: '',
      issuableConfidential: false,
      selectedLabels: [],
    };
  },
  computed: {
    confidentialityText() {
      return sprintf(
        __(
          'This %{issuableType} is confidential and should only be visible to team members with at least the Planner role.',
        ),
        { issuableType: issuableTypeText[this.issuableType] },
      );
    },
  },
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
        <markdown-editor
          v-model="issuableDescription"
          :render-markdown-path="descriptionPreviewPath"
          :markdown-docs-path="descriptionHelpPath"
          :form-field-props="$options.descriptionFormFieldProps"
        />
      </div>
    </div>
    <div data-testid="issuable-confidential" class="form-group row">
      <div class="col-12">
        <gl-form-group :label="__('Confidentiality')" label-for="issuable-confidential">
          <gl-form-checkbox id="issuable-confidential" v-model="issuableConfidential">
            {{ confidentialityText }}
          </gl-form-checkbox>
        </gl-form-group>
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
    <div data-testid="issuable-create-actions" class="footer-block gl-mt-6 gl-flex">
      <slot
        name="actions"
        :issuable-title="issuableTitle"
        :issuable-description="issuableDescription"
        :issuable-confidential="issuableConfidential"
        :selected-labels="selectedLabels"
      ></slot>
    </div>
  </gl-form>
</template>
