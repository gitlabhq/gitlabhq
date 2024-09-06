<script>
/*
`rawReferences` are separated by spaces.
Given `abc 123 zxc`, `rawReferences = ['abc', '123', 'zxc']`

Consider you are typing `abc 123 zxc` in the input and your caret position is
at position 4 right before the `123` `rawReference`. Then you type `#` and
it becomes a valid reference, `#123`, but we don't want to jump it straight into
`pendingReferences` because you could still want to type. Say you typed `999`
and now we have `#999123`. Only when you move your caret away from that `rawReference`
do we actually put it in the `pendingReferences`.

Your caret can stop touching a `rawReference` can happen in a variety of ways:

 - As you type, we only tokenize after you type a space or move with the arrow keys
 - On blur, we consider your caret not touching anything

---

 - When you click the "Add related issues"(in the `AddIssuableForm`),
   we submit the `pendingReferences` to the server and they come back as actual `relatedIssues`
 - When you click the "Cancel"(in the `AddIssuableForm`), we clear out `pendingReferences`
   and hide the `AddIssuableForm` area.

*/
import { createAlert } from '~/alert';
import { getIdFromGraphQLId, isGid } from '~/graphql_shared/utils';
import { TYPE_ISSUE } from '~/issues/constants';
import { HTTP_STATUS_NOT_FOUND } from '~/lib/utils/http_status';
import { __ } from '~/locale';
import {
  relatedIssuesRemoveErrorMap,
  pathIndeterminateErrorMap,
  addRelatedIssueErrorMap,
  PathIdSeparator,
} from '../constants';
import RelatedIssuesService from '../services/related_issues_service';
import RelatedIssuesStore from '../stores/related_issues_store';
import RelatedIssuesBlock from './related_issues_block.vue';

export default {
  name: 'RelatedIssuesRoot',
  components: {
    RelatedIssuesBlock,
  },
  props: {
    endpoint: {
      type: String,
      required: true,
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
    helpPath: {
      type: String,
      required: false,
      default: '',
    },
    issuableType: {
      type: String,
      required: false,
      default: TYPE_ISSUE,
    },
    allowAutoComplete: {
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
    pathIdSeparator: {
      type: String,
      required: false,
      default: PathIdSeparator.Issue,
    },
    cssClass: {
      type: String,
      required: false,
      default: '',
    },
    showCategorizedIssues: {
      type: Boolean,
      required: false,
      default: true,
    },
  },
  data() {
    this.store = new RelatedIssuesStore();

    return {
      state: this.store.state,
      isFetching: false,
      isSubmitting: false,
      isFormVisible: false,
      inputValue: '',
      hasError: false,
      errorMessage: null,
    };
  },
  computed: {
    autoCompleteSources() {
      if (!this.allowAutoComplete) return {};
      return gl.GfmAutoComplete && gl.GfmAutoComplete.dataSources;
    },
  },
  created() {
    this.service = new RelatedIssuesService(this.endpoint);
    this.fetchRelatedIssues();
  },
  methods: {
    findRelatedIssueById(id) {
      return this.state.relatedIssues.find((issue) => issue.id === id);
    },
    onRelatedIssueRemoveRequest(idToRemove) {
      if (isGid(idToRemove)) {
        const deletedId = getIdFromGraphQLId(idToRemove);
        this.state.relatedIssues = this.state.relatedIssues.filter(
          (issue) => issue.id !== deletedId,
        );
        return;
      }

      const issueToRemove = this.findRelatedIssueById(idToRemove);

      if (issueToRemove) {
        RelatedIssuesService.remove(issueToRemove.relationPath)
          .then(({ data }) => {
            this.store.setRelatedIssues(data.issuables);
          })
          .catch((res) => {
            if (res && res.status !== HTTP_STATUS_NOT_FOUND) {
              createAlert({ message: relatedIssuesRemoveErrorMap[this.issuableType] });
            }
          });
      } else {
        createAlert({ message: pathIndeterminateErrorMap[this.issuableType] });
      }
    },
    onToggleAddRelatedIssuesForm() {
      this.isFormVisible = !this.isFormVisible;
    },
    onPendingIssueRemoveRequest(indexToRemove) {
      this.store.removePendingRelatedIssue(indexToRemove);
    },
    onPendingFormSubmit(event) {
      this.processAllReferences(event.pendingReferences);

      if (this.state.pendingReferences.length > 0) {
        this.hasError = false;
        this.isSubmitting = true;
        this.service
          .addRelatedIssues(this.state.pendingReferences, event.linkedIssueType)
          .then(({ data }) => {
            // We could potentially lose some pending issues in the interim here
            this.store.setPendingReferences([]);
            this.store.setRelatedIssues(data.issuables);

            // Close the form on submission
            this.isFormVisible = false;
          })
          .catch(({ response }) => {
            this.hasError = true;
            this.errorMessage = addRelatedIssueErrorMap[this.issuableType];
            if (response && response.data && response.data.message) {
              this.errorMessage = response.data.message;
            }
            this.isFormVisible = true;
          })
          .finally(() => {
            this.isSubmitting = false;
          });
      }
    },
    onPendingFormCancel() {
      this.hasError = false;
      this.isFormVisible = false;
      this.store.setPendingReferences([]);
      this.inputValue = '';
    },
    fetchRelatedIssues() {
      this.isFetching = true;
      this.service
        .fetchRelatedIssues()
        .then(({ data }) => {
          this.store.setRelatedIssues(data);
        })
        .catch(() => {
          this.store.setRelatedIssues([]);
          createAlert({ message: __('An error occurred while fetching issues.') });
        })
        .finally(() => {
          this.isFetching = false;
        });
    },
    saveIssueOrder({ issueId, beforeId, afterId, oldIndex, newIndex }) {
      const issueToReorder = this.findRelatedIssueById(issueId);

      if (issueToReorder) {
        RelatedIssuesService.saveOrder({
          endpoint: issueToReorder.relationPath,
          move_before_id: beforeId,
          move_after_id: afterId,
        })
          .then(({ data }) => {
            if (!data.message) {
              this.store.updateIssueOrder(oldIndex, newIndex);
            }
          })
          .catch(() => {
            createAlert({ message: __('An error occurred while reordering issues.') });
          });
      }
    },
    onInput({ untouchedRawReferences, touchedReference }) {
      this.store.addPendingReferences(untouchedRawReferences);

      this.formatInput(touchedReference);
    },
    formatInput(touchedReference = '') {
      const startsWithNumber = String(touchedReference).match(/^[0-9]/) !== null;

      if (startsWithNumber) {
        const { pathIdSeparator } = this;
        this.inputValue = `${pathIdSeparator}${touchedReference}`;
      } else {
        this.inputValue = `${touchedReference}`;
      }
    },
    onBlur(newValue) {
      this.processAllReferences(newValue);
    },
    processAllReferences(value = '') {
      const rawReferences = value.split(/\s+/).filter((reference) => reference.trim().length > 0);

      this.store.addPendingReferences(rawReferences);
      this.inputValue = '';
    },
  },
};
</script>

<template>
  <related-issues-block
    ref="relatedIssuesBlock"
    :class="cssClass"
    :help-path="helpPath"
    :is-fetching="isFetching"
    :is-submitting="isSubmitting"
    :related-issues="state.relatedIssues"
    :can-admin="canAdmin"
    :can-reorder="canReorder"
    :pending-references="state.pendingReferences"
    :is-form-visible="isFormVisible"
    :input-value="inputValue"
    :auto-complete-sources="autoCompleteSources"
    :auto-complete-epics="autoCompleteEpics"
    :auto-complete-issues="autoCompleteIssues"
    :issuable-type="issuableType"
    :path-id-separator="pathIdSeparator"
    :show-categorized-issues="showCategorizedIssues"
    :has-error="hasError"
    :item-add-failure-message="errorMessage"
    @saveReorder="saveIssueOrder"
    @toggleAddRelatedIssuesForm="onToggleAddRelatedIssuesForm"
    @addIssuableFormInput="onInput"
    @addIssuableFormBlur="onBlur"
    @addIssuableFormSubmit="onPendingFormSubmit"
    @addIssuableFormCancel="onPendingFormCancel"
    @pendingIssuableRemoveRequest="onPendingIssueRemoveRequest"
    @relatedIssueRemoveRequest="onRelatedIssueRemoveRequest"
    @showForm="isFormVisible = true"
    @hideForm="isFormVisible = false"
  />
</template>
