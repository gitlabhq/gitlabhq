<script>
import { GlLink, GlIcon, GlButton } from '@gitlab/ui';
import { __ } from '~/locale';
import {
  issuableIconMap,
  linkedIssueTypesMap,
  linkedIssueTypesTextMap,
  issuablesBlockHeaderTextMap,
  issuablesBlockHelpTextMap,
  issuablesBlockAddButtonTextMap,
} from '../constants';
import AddIssuableForm from './add_issuable_form.vue';
import RelatedIssuesList from './related_issues_list.vue';

export default {
  name: 'RelatedIssuesBlock',
  components: {
    GlLink,
    GlButton,
    GlIcon,
    AddIssuableForm,
    RelatedIssuesList,
  },
  props: {
    isFetching: {
      type: Boolean,
      required: false,
      default: false,
    },
    isSubmitting: {
      type: Boolean,
      required: false,
      default: false,
    },
    relatedIssues: {
      type: Array,
      required: false,
      default: () => [],
    },
    canAdmin: {
      type: Boolean,
      required: false,
      default: false,
    },
    canReorder: {
      type: Boolean,
      required: false,
      default: false,
    },
    isFormVisible: {
      type: Boolean,
      required: false,
      default: false,
    },
    pendingReferences: {
      type: Array,
      required: false,
      default: () => [],
    },
    inputValue: {
      type: String,
      required: false,
      default: '',
    },
    pathIdSeparator: {
      type: String,
      required: true,
    },
    helpPath: {
      type: String,
      required: false,
      default: '',
    },
    autoCompleteSources: {
      type: Object,
      required: false,
      default: () => ({}),
    },
    issuableType: {
      type: String,
      required: true,
    },
    showCategorizedIssues: {
      type: Boolean,
      required: false,
      default: true,
    },
    autoCompleteEpics: {
      type: Boolean,
      required: false,
      default: true,
    },
    autoCompleteIssues: {
      type: Boolean,
      required: false,
      default: true,
    },
  },
  data() {
    return {
      isOpen: true,
    };
  },
  computed: {
    hasRelatedIssues() {
      return this.relatedIssues.length > 0;
    },
    categorisedIssues() {
      if (this.showCategorizedIssues) {
        return Object.values(linkedIssueTypesMap)
          .map((linkType) => ({
            linkType,
            issues: this.relatedIssues.filter((issue) => issue.linkType === linkType),
          }))
          .filter((obj) => obj.issues.length > 0);
      }

      return [{ issues: this.relatedIssues }];
    },
    shouldShowTokenBody() {
      return this.hasRelatedIssues || this.isFetching;
    },
    hasBody() {
      return this.isFormVisible || this.shouldShowTokenBody;
    },
    headerText() {
      return issuablesBlockHeaderTextMap[this.issuableType];
    },
    helpLinkText() {
      return issuablesBlockHelpTextMap[this.issuableType];
    },
    addIssuableButtonText() {
      return issuablesBlockAddButtonTextMap[this.issuableType];
    },
    badgeLabel() {
      return this.isFetching && this.relatedIssues.length === 0 ? '...' : this.relatedIssues.length;
    },
    hasHelpPath() {
      return this.helpPath.length > 0;
    },
    issuableTypeIcon() {
      return issuableIconMap[this.issuableType];
    },
    toggleIcon() {
      return this.isOpen ? 'chevron-lg-up' : 'chevron-lg-down';
    },
    toggleLabel() {
      return this.isOpen ? __('Collapse') : __('Expand');
    },
  },
  methods: {
    handleToggle() {
      this.isOpen = !this.isOpen;
    },
    addButtonClick(event) {
      this.isOpen = true;
      this.$emit('toggleAddRelatedIssuesForm', event);
    },
  },
  linkedIssueTypesTextMap,
};
</script>

<template>
  <div id="related-issues" class="related-issues-block">
    <div class="card card-slim gl-overflow-hidden gl-mt-5 gl-mb-0">
      <div
        :class="{
          'panel-empty-heading border-bottom-0': !hasBody,
          'gl-border-b-1': isOpen,
          'gl-border-b-0': !isOpen,
        }"
        class="gl-display-flex gl-justify-content-space-between gl-line-height-24 gl-py-3 gl-px-5 gl-bg-gray-10 gl-border-b-solid gl-border-b-gray-100"
      >
        <h3 class="card-title h5 gl-my-0 gl-display-flex gl-align-items-center gl-flex-grow-1">
          <gl-link
            id="user-content-related-issues"
            class="anchor position-absolute gl-text-decoration-none"
            href="#related-issues"
            aria-hidden="true"
          />
          <slot name="header-text">{{ headerText }}</slot>
          <gl-link
            v-if="hasHelpPath"
            :href="helpPath"
            target="_blank"
            class="gl-display-flex gl-align-items-center gl-ml-2 gl-text-gray-500"
            data-testid="help-link"
            :aria-label="helpLinkText"
          >
            <gl-icon name="question" :size="12" />
          </gl-link>

          <div class="js-related-issues-header-issue-count gl-display-inline-flex gl-mx-3">
            <span class="gl-display-inline-flex gl-align-items-center">
              <gl-icon :name="issuableTypeIcon" class="gl-mr-2 gl-text-gray-500" />
              {{ badgeLabel }}
            </span>
          </div>
        </h3>
        <slot name="header-actions"></slot>
        <gl-button
          v-if="canAdmin"
          size="small"
          data-qa-selector="related_issues_plus_button"
          data-testid="related-issues-plus-button"
          :aria-label="addIssuableButtonText"
          class="gl-ml-3"
          @click="addButtonClick"
        >
          <slot name="add-button-text">{{ __('Add') }}</slot>
        </gl-button>
        <div class="gl-pl-3 gl-ml-3 gl-border-l-1 gl-border-l-solid gl-border-l-gray-100">
          <gl-button
            category="tertiary"
            size="small"
            :icon="toggleIcon"
            :aria-label="toggleLabel"
            :disabled="!hasRelatedIssues"
            data-testid="toggle-links"
            @click="handleToggle"
          />
        </div>
      </div>
      <div
        v-if="isOpen"
        class="linked-issues-card-body gl-bg-gray-10"
        :class="{
          'gl-p-5': isFormVisible || shouldShowTokenBody,
        }"
        data-testid="related-issues-body"
      >
        <div
          v-if="isFormVisible"
          class="js-add-related-issues-form-area card-body bordered-box bg-white"
        >
          <add-issuable-form
            :show-categorized-issues="showCategorizedIssues"
            :is-submitting="isSubmitting"
            :issuable-type="issuableType"
            :input-value="inputValue"
            :pending-references="pendingReferences"
            :auto-complete-sources="autoCompleteSources"
            :auto-complete-epics="autoCompleteEpics"
            :auto-complete-issues="autoCompleteIssues"
            :path-id-separator="pathIdSeparator"
            @pendingIssuableRemoveRequest="$emit('pendingIssuableRemoveRequest', $event)"
            @addIssuableFormInput="$emit('addIssuableFormInput', $event)"
            @addIssuableFormBlur="$emit('addIssuableFormBlur', $event)"
            @addIssuableFormSubmit="$emit('addIssuableFormSubmit', $event)"
            @addIssuableFormCancel="$emit('addIssuableFormCancel', $event)"
          />
        </div>
        <template v-if="shouldShowTokenBody">
          <related-issues-list
            v-for="category in categorisedIssues"
            :key="category.linkType"
            :list-link-type="category.linkType"
            :heading="$options.linkedIssueTypesTextMap[category.linkType]"
            :can-admin="canAdmin"
            :can-reorder="canReorder"
            :is-fetching="isFetching"
            :issuable-type="issuableType"
            :path-id-separator="pathIdSeparator"
            :related-issues="category.issues"
            @relatedIssueRemoveRequest="$emit('relatedIssueRemoveRequest', $event)"
            @saveReorder="$emit('saveReorder', $event)"
          />
        </template>
      </div>
    </div>
  </div>
</template>
