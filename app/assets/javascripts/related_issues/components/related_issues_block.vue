<script>
import { GlLink, GlIcon, GlButton } from '@gitlab/ui';
import {
  issuableIconMap,
  issuableQaClassMap,
  linkedIssueTypesMap,
  linkedIssueTypesTextMap,
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
    badgeLabel() {
      return this.isFetching && this.relatedIssues.length === 0 ? '...' : this.relatedIssues.length;
    },
    hasHelpPath() {
      return this.helpPath.length > 0;
    },
    issuableTypeIcon() {
      return issuableIconMap[this.issuableType];
    },
    qaClass() {
      return issuableQaClassMap[this.issuableType];
    },
  },
  linkedIssueTypesTextMap,
};
</script>

<template>
  <div id="related-issues" class="related-issues-block">
    <div class="card card-slim gl-overflow-hidden">
      <div
        :class="{ 'panel-empty-heading border-bottom-0': !hasBody }"
        class="card-header gl-display-flex gl-justify-content-space-between"
      >
        <h3
          class="card-title h5 position-relative gl-my-0 gl-display-flex gl-align-items-center gl-h-7"
        >
          <gl-link
            id="user-content-related-issues"
            class="anchor position-absolute gl-text-decoration-none"
            href="#related-issues"
            aria-hidden="true"
          />
          <slot name="header-text">{{ __('Linked issues') }}</slot>
          <gl-link
            v-if="hasHelpPath"
            :href="helpPath"
            target="_blank"
            class="gl-display-flex gl-align-items-center gl-ml-2 gl-text-gray-500"
            :aria-label="__('Read more about related issues')"
          >
            <gl-icon name="question" :size="12" />
          </gl-link>

          <div class="gl-display-inline-flex">
            <div class="js-related-issues-header-issue-count gl-display-inline-flex gl-mx-5">
              <span class="gl-display-inline-flex gl-align-items-center">
                <gl-icon :name="issuableTypeIcon" class="gl-mr-2 gl-text-gray-500" />
                {{ badgeLabel }}
              </span>
            </div>
            <gl-button
              v-if="canAdmin"
              data-qa-selector="related_issues_plus_button"
              icon="plus"
              :aria-label="__('Add a related issue')"
              :class="qaClass"
              class="js-issue-count-badge-add-button"
              @click="$emit('toggleAddRelatedIssuesForm', $event)"
            />
          </div>
        </h3>
        <slot name="header-actions"></slot>
      </div>
      <div
        class="linked-issues-card-body bg-gray-light"
        :class="{
          'gl-p-5': isFormVisible || shouldShowTokenBody,
        }"
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
