<script>
import { computed } from 'vue';
import { TYPENAME_GROUP } from '~/graphql_shared/constants';
import workItemMetadataQuery from 'ee_else_ce/work_items/graphql/work_item_metadata.query.graphql';

export default {
  provide() {
    // We provide the metadata values as computed properties
    // so that they can be reactive and update when the Apollo query updates.
    return {
      hasIssueWeightsFeature: computed(() => this.metadata.hasIssueWeightsFeature),
      hasIterationsFeature: computed(() => this.metadata.hasIterationsFeature),
      hasOkrsFeature: computed(() => this.metadata.hasOkrsFeature),
      hasSubepicsFeature: computed(() => this.metadata.hasSubepicsFeature),
      hasIssuableHealthStatusFeature: computed(() => this.metadata.hasIssuableHealthStatusFeature),
      hasEpicsFeature: computed(() => this.metadata.hasEpicsFeature),
      hasScopedLabelsFeature: computed(() => this.metadata.hasScopedLabelsFeature),
      hasQualityManagementFeature: computed(() => this.metadata.hasQualityManagementFeature),
      hasLinkedItemsEpicsFeature: computed(() => this.metadata.hasLinkedItemsEpicsFeature),
      hasIssueDateFilterFeature: computed(() => this.metadata.hasIssueDateFilterFeature),
      hasStatusFeature: computed(() => this.metadata?.hasWorkItemStatusFeature),
      issuesListPath: computed(() => this.metadata.issuesList),
      contributionGuidePath: computed(() => this.metadata.contributionGuidePath),
      epicsListPath: computed(() => this.metadata.epicsList),
      groupIssuesPath: computed(() => this.metadata.groupIssues),
      labelsFetchPath: computed(() => this.metadata.labelsFetch),
      labelsManagePath: computed(() => this.metadata.labelsManage),
      newProjectPath: computed(() => this.metadata.newProject),
      registerPath: computed(() => this.metadata.register),
      reportAbusePath: computed(() => this.metadata.reportAbuse),
      signInPath: computed(() => this.metadata.signIn),
      issuesSettings: computed(() => this.metadata?.issuesSettings),
      metadataLoading: computed(() => this.$apollo.queries.metadata.loading),
      userExportEmail: computed(() => this.metadata?.userExportEmail),
      newWorkItemEmailAddress: computed(() => this.metadata.newWorkItemEmailAddress),
      canCreateWorkItem: computed(() => this.metadata.createWorkItem),
      emailsHelpPagePath: computed(() => this.metadata.emailsHelpPagePath),
      markdownHelpPath: computed(() => this.metadata.markdownHelpPath),
      quickActionsHelpPath: computed(() => this.metadata.quickActionsHelpPath),
      // newCommentTemplatePaths not included as it is already available on the `WorkItem` type.
      isGroup: computed(() => this.metadata.id?.includes(TYPENAME_GROUP) || false),
    };
  },
  props: {
    fullPath: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      metadata: {},
    };
  },
  apollo: {
    metadata: {
      query: workItemMetadataQuery,
      variables() {
        return {
          fullPath: this.fullPath,
        };
      },
      update(data) {
        const namespace = data?.namespace || {};
        return {
          ...(namespace.licensedFeatures || {}),
          ...(namespace.linkPaths || {}),
          ...(namespace.userPermissions || {}),
          id: namespace.id,
        };
      },
    },
  },
  render() {
    return this.$scopedSlots.default();
  },
};
</script>
