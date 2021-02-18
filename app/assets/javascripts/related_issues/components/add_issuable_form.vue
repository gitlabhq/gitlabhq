<script>
import { GlFormGroup, GlFormRadioGroup, GlButton } from '@gitlab/ui';
import { mergeUrlParams } from '~/lib/utils/url_utility';
import { __ } from '~/locale';

import {
  issuableTypesMap,
  itemAddFailureTypesMap,
  linkedIssueTypesMap,
  addRelatedIssueErrorMap,
  addRelatedItemErrorMap,
} from '../constants';
import RelatedIssuableInput from './related_issuable_input.vue';

export default {
  name: 'AddIssuableForm',
  components: {
    GlFormGroup,
    GlFormRadioGroup,
    RelatedIssuableInput,
    GlButton,
  },
  props: {
    inputValue: {
      type: String,
      required: true,
    },
    pendingReferences: {
      type: Array,
      required: false,
      default: () => [],
    },
    autoCompleteSources: {
      type: Object,
      required: false,
      default: () => ({}),
    },
    showCategorizedIssues: {
      type: Boolean,
      required: false,
      default: false,
    },
    isSubmitting: {
      type: Boolean,
      required: false,
      default: false,
    },
    pathIdSeparator: {
      type: String,
      required: true,
    },
    issuableType: {
      type: String,
      required: false,
      default: issuableTypesMap.ISSUE,
    },
    hasError: {
      type: Boolean,
      required: false,
      default: false,
    },
    itemAddFailureType: {
      type: String,
      required: false,
      default: itemAddFailureTypesMap.NOT_FOUND,
    },
    itemAddFailureMessage: {
      type: String,
      required: false,
      default: '',
    },
    confidential: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      linkedIssueType: linkedIssueTypesMap.RELATES_TO,
      linkedIssueTypes: [
        {
          text: __('relates to'),
          value: linkedIssueTypesMap.RELATES_TO,
        },
        {
          text: __('blocks'),
          value: linkedIssueTypesMap.BLOCKS,
        },
        {
          text: __('is blocked by'),
          value: linkedIssueTypesMap.IS_BLOCKED_BY,
        },
      ],
    };
  },
  computed: {
    isSubmitButtonDisabled() {
      return (
        (this.inputValue.length === 0 && this.pendingReferences.length === 0) || this.isSubmitting
      );
    },
    addRelatedErrorMessage() {
      if (this.itemAddFailureMessage) {
        return this.itemAddFailureMessage;
      } else if (this.itemAddFailureType === itemAddFailureTypesMap.NOT_FOUND) {
        return addRelatedIssueErrorMap[this.issuableType];
      }
      // Only other failure is MAX_NUMBER_OF_CHILD_EPICS at the moment
      return addRelatedItemErrorMap[this.itemAddFailureType];
    },
    transformedAutocompleteSources() {
      if (!this.confidential) {
        return this.autoCompleteSources;
      }

      if (!this.autoCompleteSources?.issues || !this.autoCompleteSources?.epics) {
        return this.autoCompleteSources;
      }

      return {
        ...this.autoCompleteSources,
        issues: mergeUrlParams({ confidential_only: true }, this.autoCompleteSources.issues),
        epics: mergeUrlParams({ confidential_only: true }, this.autoCompleteSources.epics),
      };
    },
  },
  methods: {
    onPendingIssuableRemoveRequest(params) {
      this.$emit('pendingIssuableRemoveRequest', params);
    },
    onFormSubmit() {
      this.$emit('addIssuableFormSubmit', {
        pendingReferences: this.$refs.relatedIssuableInput.$refs.input.value,
        linkedIssueType: this.linkedIssueType,
      });
    },
    onFormCancel() {
      this.$emit('addIssuableFormCancel');
    },
    onAddIssuableFormInput(params) {
      this.$emit('addIssuableFormInput', params);
    },
    onAddIssuableFormBlur(params) {
      this.$emit('addIssuableFormBlur', params);
    },
  },
};
</script>

<template>
  <form @submit.prevent="onFormSubmit">
    <template v-if="showCategorizedIssues">
      <gl-form-group
        :label="__('The current issue')"
        label-for="linked-issue-type-radio"
        label-class="label-bold"
        class="mb-2"
      >
        <gl-form-radio-group
          id="linked-issue-type-radio"
          v-model="linkedIssueType"
          :options="linkedIssueTypes"
          :checked="linkedIssueType"
        />
      </gl-form-group>
      <p class="bold">
        {{ __('the following issue(s)') }}
      </p>
    </template>
    <related-issuable-input
      ref="relatedIssuableInput"
      input-id="add-related-issues-form-input"
      :confidential="confidential"
      :focus-on-mount="true"
      :references="pendingReferences"
      :path-id-separator="pathIdSeparator"
      :input-value="inputValue"
      :auto-complete-sources="transformedAutocompleteSources"
      :auto-complete-options="{ issues: true, epics: true }"
      :issuable-type="issuableType"
      @pendingIssuableRemoveRequest="onPendingIssuableRemoveRequest"
      @formCancel="onFormCancel"
      @addIssuableFormBlur="onAddIssuableFormBlur"
      @addIssuableFormInput="onAddIssuableFormInput"
    />
    <p v-if="hasError" class="gl-field-error">
      {{ addRelatedErrorMessage }}
    </p>
    <div class="add-issuable-form-actions clearfix">
      <gl-button
        ref="addButton"
        category="primary"
        variant="success"
        :disabled="isSubmitButtonDisabled"
        :loading="isSubmitting"
        type="submit"
        class="js-add-issuable-form-add-button float-left"
        data-qa-selector="add_issue_button"
      >
        {{ __('Add') }}
      </gl-button>
      <gl-button class="float-right" @click="onFormCancel">
        {{ __('Cancel') }}
      </gl-button>
    </div>
  </form>
</template>
