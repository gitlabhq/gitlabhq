<script>
import { GlForm, GlFormInput } from '@gitlab/ui';
import MarkdownField from '~/vue_shared/components/markdown/field.vue';
import { DropdownVariant } from '~/vue_shared/components/sidebar/labels_select_vue/constants';
import LabelsSelect from '~/vue_shared/components/sidebar/labels_select_vue/labels_select_root.vue';

export default {
  LabelSelectVariant: DropdownVariant,
  components: {
    GlForm,
    GlFormInput,
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
    <div data-testid="issuable-title" class="form-group row">
      <label for="issuable-title" class="col-form-label col-sm-2">{{ __('Title') }}</label>
      <div class="col-sm-10">
        <gl-form-input
          id="issuable-title"
          v-model="issuableTitle"
          :autofocus="true"
          :placeholder="__('Title')"
        />
      </div>
    </div>
    <div data-testid="issuable-description" class="form-group row">
      <label for="issuable-description" class="col-form-label col-sm-2">{{
        __('Description')
      }}</label>
      <div class="col-sm-10">
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
              class="note-textarea qa-issuable-form-description rspec-issuable-form-description js-gfm-input js-autosize markdown-area"
              :aria-label="__('Description')"
              :placeholder="__('Write a comment or drag your files here…')"
            ></textarea>
          </template>
        </markdown-field>
      </div>
    </div>
    <div class="row">
      <div class="col-lg-6">
        <div data-testid="issuable-labels" class="form-group row">
          <label for="issuable-labels" class="col-form-label col-md-2 col-lg-4">{{
            __('Labels')
          }}</label>
          <div class="col-md-8 col-sm-10">
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
                :variant="$options.LabelSelectVariant.Embedded"
                @updateSelectedLabels="handleUpdateSelectedLabels"
              />
            </div>
          </div>
        </div>
      </div>
    </div>
    <div
      data-testid="issuable-create-actions"
      class="footer-block row-content-block gl-display-flex"
    >
      <slot
        name="actions"
        :issuable-title="issuableTitle"
        :issuable-description="issuableDescription"
        :selected-labels="selectedLabels"
      ></slot>
    </div>
  </gl-form>
</template>
