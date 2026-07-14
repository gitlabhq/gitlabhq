<script>
import { GlLink } from '@gitlab/ui';
import CrudComponent from '~/vue_shared/components/crud_component.vue';
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
    CrudComponent,
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
    headerText: {
      type: String,
      required: false,
      default: '',
    },
    addButtonText: {
      type: String,
      required: false,
      default: '',
    },
  },
  emits: [
    'add-issuable-form-blur',
    'add-issuable-form-cancel',
    'add-issuable-form-input',
    'add-issuable-form-submit',
    'hideForm',
    'pending-issuable-remove-request',
    'related-issue-remove-request',
    'save-reorder',
    'showForm',
  ],
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

      if (this.relatedIssues.length > 0) {
        return [{ issues: this.relatedIssues }];
      }

      return [];
    },
    shouldShowTokenBody() {
      return this.hasRelatedIssues || this.isFetching;
    },
    headerTextDisplay() {
      return this.headerText ? this.headerText : issuablesBlockHeaderTextMap[this.issuableType];
    },
    addButtonTextDisplay() {
      if (!this.canAdmin) {
        return;
      }

      // eslint-disable-next-line consistent-return
      return this.addButtonText ? this.addButtonText : __('Add');
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
    emptyStateMessage() {
      return this.showCategorizedIssues
        ? sprintf(this.$options.i18n.emptyItemsPremium, { issuableType: this.issuableType })
        : sprintf(this.$options.i18n.emptyItemsFree, { issuableType: this.issuableType });
    },
  },
  watch: {
    isFormVisible(newVal) {
      if (newVal === true) {
        this.$refs.relatedIssuesWidget.showForm();
      } else {
        this.$refs.relatedIssuesWidget.hideForm();
      }
    },
  },
  mounted() {
    if (this.isFormVisible) {
      this.$refs.relatedIssuesWidget.showForm();
    }
  },
  methods: {
    handleFormSubmit(event) {
      this.$emit('add-issuable-form-submit', event);
    },
    handleFormCancel(event) {
      this.$emit('add-issuable-form-cancel', event);
      this.$refs.relatedIssuesWidget.hideForm();
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
  <crud-component
    ref="relatedIssuesWidget"
    is-collapsible
    :is-loading="isFetching"
    :title="headerTextDisplay"
    :icon="issuableTypeIcon"
    :count="badgeLabel"
    :toggle-text="addButtonTextDisplay"
    :toggle-aria-label="addIssuableButtonText"
    :help-path="helpPath"
    :help-link-text="helpLinkText"
    anchor-id="related-issues"
    data-testid="related-issues-block"
    @showForm="$emit('showForm')"
    @hideForm="$emit('hideForm')"
  >
    <template #actions>
      <slot name="header-actions"></slot>
    </template>

    <template #form>
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
        @pending-issuable-remove-request="$emit('pending-issuable-remove-request', $event)"
        @add-issuable-form-input="$emit('add-issuable-form-input', $event)"
        @add-issuable-form-blur="$emit('add-issuable-form-blur', $event)"
        @add-issuable-form-submit="handleFormSubmit"
        @add-issuable-form-cancel="handleFormCancel"
      />
    </template>

    <template v-if="!shouldShowTokenBody" #empty>
      <slot name="empty-state-message">{{ emptyStateMessage }}</slot>
      <gl-link
        v-if="hasHelpPath"
        :href="helpPath"
        data-testid="help-link"
        :aria-label="helpLinkText"
      >
        {{ __('Learn more.') }}
      </gl-link>
    </template>

    <template #default>
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
          'gl-mb-5 gl-border-b-1 gl-border-b-default gl-border-b-solid':
            index !== categorisedIssues.length - 1,
        }"
        @related-issue-remove-request="$emit('related-issue-remove-request', $event)"
        @save-reorder="$emit('save-reorder', $event)"
      />
    </template>
  </crud-component>
</template>
