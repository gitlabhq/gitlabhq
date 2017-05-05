<script>
/* global Flash */

import eventHub from '../event_hub';
import RelatedIssuesBlock from './related_issues_block.vue';
import RelatedIssuesStore from '../stores/related_issues_store';
import RelatedIssuesService from '../services/related_issues_service';

export default {
  name: 'RelatedIssuesRoot',

  props: {
    endpoint: {
      type: String,
      required: true,
    },
    currentNamespacePath: {
      type: String,
      required: true,
    },
    currentProjectPath: {
      type: String,
      required: true,
    },
    canAddRelatedIssues: {
      type: Boolean,
      required: false,
      default: false,
    },
    helpPath: {
      type: String,
      required: false,
      default: '',
    },
  },

  data() {
    this.store = new RelatedIssuesStore();

    return {
      state: this.store.state,
      isFormVisible: false,
      inputValue: '',
    };
  },

  components: {
    relatedIssuesBlock: RelatedIssuesBlock,
  },

  computed: {
    computedRelatedIssues() {
      return this.store.getIssuesFromReferences(
        this.state.relatedIssues,
        this.currentNamespacePath,
        this.currentProjectPath,
      );
    },
    computedPendingRelatedIssues() {
      return this.store.getIssuesFromReferences(
        this.state.pendingRelatedIssues,
        this.currentNamespacePath,
        this.currentProjectPath,
      );
    },
  },

  methods: {
    onRelatedIssueRemoveRequest(reference) {
      this.store.setRelatedIssues(this.state.relatedIssues.filter(ref => ref !== reference));

      this.service.removeRelatedIssue(this.state.issueMap[reference].destroy_relation_path)
        .catch(() => {
          // Restore issue we were unable to delete
          this.store.setRelatedIssues(this.state.relatedIssues.concat(reference));

          // eslint-disable-next-line no-new
          new Flash('An error occurred while removing related issues.');
        });
    },
    onShowAddRelatedIssuesForm() {
      this.isFormVisible = true;
    },
    onAddIssuableFormIssuableRemoveRequest(reference) {
      this.store.setPendingRelatedIssues(
        this.state.pendingRelatedIssues.filter(ref => ref !== reference),
      );
    },
    onAddIssuableFormSubmit() {
      const currentPendingIssues = this.state.pendingRelatedIssues;

      this.service.addRelatedIssues(currentPendingIssues)
        .then(res => res.json())
        .then(() => {
          this.store.setRelatedIssues(this.state.relatedIssues.concat(currentPendingIssues));
        })
        .catch(() => {
          // Restore issues we were unable to submit
          this.store.setPendingRelatedIssues(
            _.uniq(this.state.pendingRelatedIssues.concat(currentPendingIssues)),
          );

          // eslint-disable-next-line no-new
          new Flash('An error occurred while submitting related issues.');
        });
      this.store.setPendingRelatedIssues([]);
    },
    onAddIssuableFormCancel() {
      this.isFormVisible = false;
      this.store.setPendingRelatedIssues([]);
      this.inputValue = '';
    },
    fetchRelatedIssues() {
      this.service.fetchRelatedIssues()
        .then(res => res.json())
        .then((issues) => {
          const relatedIssueReferences = issues.map((issue) => {
            const referenceKey = `${issue.namespace_full_path}/${issue.project_path}#${issue.iid}`;

            this.store.addToIssueMap(referenceKey, issue);

            return referenceKey;
          });
          this.store.setRelatedIssues(relatedIssueReferences);
        })
        .catch(() => {
          // eslint-disable-next-line no-new
          new Flash('An error occurred while fetching related issues.');
        });
    },
  },

  created() {
    eventHub.$on('relatedIssue-removeRequest', this.onRelatedIssueRemoveRequest);
    eventHub.$on('showAddRelatedIssuesForm', this.onShowAddRelatedIssuesForm);
    eventHub.$on('pendingIssuable-removeRequest', this.onAddIssuableFormIssuableRemoveRequest);
    eventHub.$on('addIssuableFormSubmit', this.onAddIssuableFormSubmit);
    eventHub.$on('addIssuableFormCancel', this.onAddIssuableFormCancel);

    this.service = new RelatedIssuesService(this.endpoint);
    this.fetchRelatedIssues();
  },

  beforeDestroy() {
    eventHub.$off('relatedIssue-removeRequest', this.onRelatedIssueRemoveRequest);
    eventHub.$off('showAddRelatedIssuesForm', this.onShowAddRelatedIssuesForm);
    eventHub.$off('pendingIssuable-removeRequest', this.onAddIssuableFormIssuableRemoveRequest);
    eventHub.$off('addIssuableFormSubmit', this.onAddIssuableFormSubmit);
    eventHub.$off('addIssuableFormCancel', this.onAddIssuableFormCancel);
  },
};
</script>

<template>
  <related-issues-block
    :help-path="helpPath"
    :related-issues="computedRelatedIssues"
    :can-add-related-issues="canAddRelatedIssues"
    :pending-related-issues="computedPendingRelatedIssues"
    :is-form-visible="isFormVisible"
    :input-value="inputValue" />
</template>
