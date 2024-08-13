<script>
import { GlLink, GlIcon, GlLoadingIcon, GlButton, GlCard } from '@gitlab/ui';
import { __, sprintf } from '~/locale';
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
    GlIcon,
    GlLoadingIcon,
    GlButton,
    GlCard,
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
    hasError: {
      type: Boolean,
      required: false,
      default: false,
    },
    itemAddFailureMessage: {
      type: String,
      required: false,
      default: '',
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
    emptyStateMessage() {
      return this.showCategorizedIssues
        ? sprintf(this.$options.i18n.emptyItemsPremium, { issuableType: this.issuableType })
        : sprintf(this.$options.i18n.emptyItemsFree, { issuableType: this.issuableType });
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
  i18n: {
    emptyItemsFree: __("Link %{issuableType}s together to show that they're related."),
    emptyItemsPremium: __(
      "Link %{issuableType}s together to show that they're related or that one is blocking others.",
    ),
  },
  ariaControlsId: 'related-issues-card',
};
</script>

<template>
  <div id="related-issues" class="related-issues-block">
    <gl-card
      :id="$options.ariaControlsId"
      class="gl-new-card"
      :class="{ 'is-collapsed': !isOpen }"
      header-class="gl-new-card-header"
      body-class="gl-new-card-body"
    >
      <template #header>
        <div class="gl-new-card-title-wrapper">
          <h3 class="gl-new-card-title" data-testid="card-title">
            <gl-link
              id="user-content-related-issues"
              class="anchor position-absolute gl-text-decoration-none"
              href="#related-issues"
              aria-hidden="true"
            />
            <slot name="header-text">{{ headerText }}</slot>
          </h3>
          <div class="gl-new-card-count js-related-issues-header-issue-count">
            <gl-icon :name="issuableTypeIcon" class="gl-mr-2" />
            {{ badgeLabel }}
          </div>
        </div>
        <slot name="header-actions"></slot>
        <gl-button
          v-if="canAdmin"
          size="small"
          data-testid="related-issues-plus-button"
          :aria-label="addIssuableButtonText"
          class="gl-ml-3"
          @click="addButtonClick"
        >
          <slot name="add-button-text">{{ __('Add') }}</slot>
        </gl-button>
        <div class="gl-new-card-toggle">
          <gl-button
            category="tertiary"
            size="small"
            :icon="toggleIcon"
            :aria-label="toggleLabel"
            :aria-expanded="isOpen.toString()"
            :aria-controls="$options.ariaControlsId"
            data-testid="toggle-links"
            @click="handleToggle"
          />
        </div>
      </template>
      <div
        v-if="isOpen"
        class="linked-issues-card-body gl-new-card-content"
        data-testid="related-issues-body"
      >
        <div
          v-if="isFormVisible"
          class="js-add-related-issues-form-area gl-new-card-add-form"
          :class="{ 'gl-mb-5': shouldShowTokenBody, 'gl-show-field-errors': hasError }"
          data-testid="add-item-form"
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
            :has-error="hasError"
            :item-add-failure-message="itemAddFailureMessage"
            @pendingIssuableRemoveRequest="$emit('pendingIssuableRemoveRequest', $event)"
            @addIssuableFormInput="$emit('addIssuableFormInput', $event)"
            @addIssuableFormBlur="$emit('addIssuableFormBlur', $event)"
            @addIssuableFormSubmit="$emit('addIssuableFormSubmit', $event)"
            @addIssuableFormCancel="$emit('addIssuableFormCancel', $event)"
          />
        </div>
        <template v-if="shouldShowTokenBody">
          <gl-loading-icon v-if="isFetching" size="sm" class="gl-py-2" />
          <related-issues-list
            v-for="(category, index) in categorisedIssues"
            :key="category.linkType"
            :list-link-type="category.linkType"
            :heading="$options.linkedIssueTypesTextMap[category.linkType]"
            :can-admin="canAdmin"
            :can-reorder="canReorder"
            :is-fetching="isFetching"
            :issuable-type="issuableType"
            :path-id-separator="pathIdSeparator"
            :related-issues="category.issues"
            :class="{
              'gl-pb-3 gl-mb-5 gl-border-b-1 gl-border-b-solid gl-border-b-gray-100':
                index !== categorisedIssues.length - 1,
            }"
            @relatedIssueRemoveRequest="$emit('relatedIssueRemoveRequest', $event)"
            @saveReorder="$emit('saveReorder', $event)"
          />
        </template>
        <p v-if="!shouldShowTokenBody && !isFormVisible" class="gl-new-card-empty">
          {{ emptyStateMessage }}
          <gl-link
            v-if="hasHelpPath"
            :href="helpPath"
            data-testid="help-link"
            :aria-label="helpLinkText"
          >
            {{ __('Learn more.') }}
          </gl-link>
        </p>
      </div>
    </gl-card>
  </div>
</template>
