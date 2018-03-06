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
import _ from 'underscore';
import Flash from '~/flash';
import eventHub from '../event_hub';
import RelatedIssuesBlock from './related_issues_block.vue';
import RelatedIssuesStore from '../stores/related_issues_store';
import RelatedIssuesService from '../services/related_issues_service';

const SPACE_FACTOR = 1;

export default {
  name: 'RelatedIssuesRoot',
  components: {
    relatedIssuesBlock: RelatedIssuesBlock,
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
    title: {
      type: String,
      required: false,
      default: 'Related issues',
    },
    allowAutoComplete: {
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
    };
  },
  computed: {
    autoCompleteSources() {
      if (!this.allowAutoComplete) return {};
      return gl.GfmAutoComplete && gl.GfmAutoComplete.dataSources;
    },
  },
  created() {
    eventHub.$on('relatedIssue-removeRequest', this.onRelatedIssueRemoveRequest);
    eventHub.$on('toggleAddRelatedIssuesForm', this.onToggleAddRelatedIssuesForm);
    eventHub.$on('pendingIssuable-removeRequest', this.onPendingIssueRemoveRequest);
    eventHub.$on('addIssuableFormSubmit', this.onPendingFormSubmit);
    eventHub.$on('addIssuableFormCancel', this.onPendingFormCancel);
    eventHub.$on('addIssuableFormInput', this.onInput);
    eventHub.$on('addIssuableFormBlur', this.onBlur);

    this.service = new RelatedIssuesService(this.endpoint);
    this.fetchRelatedIssues();
  },
  beforeDestroy() {
    eventHub.$off('relatedIssue-removeRequest', this.onRelatedIssueRemoveRequest);
    eventHub.$off('toggleAddRelatedIssuesForm', this.onToggleAddRelatedIssuesForm);
    eventHub.$off('pendingIssuable-removeRequest', this.onPendingIssueRemoveRequest);
    eventHub.$off('addIssuableFormSubmit', this.onPendingFormSubmit);
    eventHub.$off('addIssuableFormCancel', this.onPendingFormCancel);
    eventHub.$off('addIssuableFormInput', this.onInput);
    eventHub.$off('addIssuableFormBlur', this.onBlur);
  },
  methods: {
    onRelatedIssueRemoveRequest(idToRemove) {
      const issueToRemove = _.find(this.state.relatedIssues, issue => issue.id === idToRemove);

      if (issueToRemove) {
        RelatedIssuesService.remove(issueToRemove.relation_path)
          .then(res => res.json())
          .then((data) => {
            this.store.setRelatedIssues(data.issues);
          })
          .catch((res) => {
            if (res && res.status !== 404) {
              Flash('An error occurred while removing issues.');
            }
          });
      } else {
        Flash('We could not determine the path to remove the issue');
      }
    },
    onToggleAddRelatedIssuesForm() {
      this.isFormVisible = !this.isFormVisible;
    },
    onPendingIssueRemoveRequest(indexToRemove) {
      this.store.removePendingRelatedIssue(indexToRemove);
    },
    onPendingFormSubmit(newValue) {
      this.processAllReferences(newValue);

      if (this.state.pendingReferences.length > 0) {
        this.isSubmitting = true;
        this.service.addRelatedIssues(this.state.pendingReferences)
          .then(res => res.json())
          .then((data) => {
            // We could potentially lose some pending issues in the interim here
            this.store.setPendingReferences([]);
            this.store.setRelatedIssues(data.issues);

            this.isSubmitting = false;
            // Close the form on submission
            this.isFormVisible = false;
          })
          .catch((res) => {
            this.isSubmitting = false;
            let errorMessage = 'We can\'t find an issue that matches what you are looking for.';
            if (res.data && res.data.message) {
              errorMessage = res.data.message;
            }
            Flash(errorMessage);
          });
      }
    },
    onPendingFormCancel() {
      this.isFormVisible = false;
      this.store.setPendingReferences([]);
      this.inputValue = '';
    },
    fetchRelatedIssues() {
      this.isFetching = true;
      this.service.fetchRelatedIssues()
        .then(res => res.json())
        .then((issues) => {
          this.store.setRelatedIssues(issues);
          this.isFetching = false;
        })
        .catch(() => {
          this.store.setRelatedIssues([]);
          this.isFetching = false;
          Flash('An error occurred while fetching issues.');
        });
    },
    saveIssueOrder({ issueId, beforeId, afterId, oldIndex, newIndex }) {
      const issueToReorder = _.find(this.state.relatedIssues, issue => issue.id === issueId);

      if (issueToReorder) {
        RelatedIssuesService.saveOrder({
          endpoint: issueToReorder.relation_path,
          move_before_id: beforeId,
          move_after_id: afterId,
        })
        .then(res => res.json())
        .then((res) => {
          if (!res.message) {
            this.store.updateIssueOrder(oldIndex, newIndex);
          }
        })
        .catch(() => {
          Flash('An error occurred while reordering issues.');
        });
      }
    },
    onInput(newValue, caretPos) {
      const rawReferences = newValue
        .split(/\s/);

      let touchedReference;
      let iteratingPos = 0;
      const untouchedRawReferences = rawReferences
        .filter((reference) => {
          let isTouched = false;
          if (caretPos >= iteratingPos && caretPos <= (iteratingPos + reference.length)) {
            touchedReference = reference;
            isTouched = true;
          }

          // `+ SPACE_FACTOR` to factor in the missing space we split at earlier
          iteratingPos = iteratingPos + reference.length + SPACE_FACTOR;
          return !isTouched;
        })
        .filter(reference => reference.trim().length > 0);

      this.store.setPendingReferences(
        this.state.pendingReferences.concat(untouchedRawReferences),
      );
      this.inputValue = `${touchedReference}`;
    },
    onBlur(newValue) {
      this.processAllReferences(newValue);
    },
    processAllReferences(value = '') {
      const rawReferences = value
        .split(/\s+/)
        .filter(reference => reference.trim().length > 0);

      this.store.setPendingReferences(
        this.state.pendingReferences.concat(rawReferences),
      );
      this.inputValue = '';
    },
  },
};
</script>

<template>
  <related-issues-block
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
    :title="title"
    @saveReorder="saveIssueOrder"
  />
</template>
