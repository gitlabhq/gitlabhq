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
};
</script>

<template>
  <div id="related-issues" class="related-issues-block">
    <gl-card
      class="gl-overflow-hidden gl-mt-5 gl-mb-0"
      header-class="gl-p-0 gl-border-0"
      body-class="gl-p-0 gl-bg-gray-10"
    >
      <template #header>
        <div
          :class="{
            'gl-border-b-1': isOpen,
            'gl-border-b-0': !isOpen,
          }"
          class="gl-display-flex gl-justify-content-space-between gl-pl-5 gl-pr-4 gl-py-4 gl-bg-white gl-border-b-solid gl-border-b-gray-100"
        >
          <h3
            class="card-title h5 gl-relative gl-my-0 gl-display-flex gl-align-items-center gl-flex-grow-1 gl-line-height-24"
          >
            <gl-link
              id="user-content-related-issues"
              class="anchor position-absolute gl-text-decoration-none"
              href="#related-issues"
              aria-hidden="true"
            />
            <slot name="header-text">{{ headerText }}</slot>

            <div
              class="js-related-issues-header-issue-count gl-display-inline-flex gl-mx-3 gl-text-gray-500"
            >
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
              data-testid="toggle-links"
              @click="handleToggle"
            />
          </div>
        </div>
      </template>
      <div
        v-if="isOpen"
        class="linked-issues-card-body gl-py-3 gl-px-4 gl-bg-gray-10"
        data-testid="related-issues-body"
      >
        <div
          v-if="isFormVisible"
          class="js-add-related-issues-form-area card-body bg-white gl-mt-2 gl-border-1 gl-border-solid gl-border-gray-100 gl-rounded-base"
          :class="{ 'gl-mb-5': shouldShowTokenBody, 'gl-show-field-errors': hasError }"
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
        <div v-if="!shouldShowTokenBody && !isFormVisible" data-testid="related-items-empty">
          <p class="gl-p-2 gl-mb-0 gl-text-gray-500">
            {{ emptyStateMessage }}
            <gl-link
              v-if="hasHelpPath"
              :href="helpPath"
              target="_blank"
              data-testid="help-link"
              :aria-label="helpLinkText"
            >
              {{ __('Learn more.') }}
            </gl-link>
          </p>
        </div>
      </div>
    </gl-card>
  </div>
</template>
