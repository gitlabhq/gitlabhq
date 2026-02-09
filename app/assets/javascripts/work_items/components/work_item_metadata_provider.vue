<script>
import { computed } from 'vue';
import { TYPENAME_GROUP } from '~/graphql_shared/constants';
import { normalizeRender } from '~/lib/utils/vue3compat/normalize_render';
import workItemMetadataQuery from 'ee_else_ce/work_items/graphql/work_item_metadata.query.graphql';
import workItemTypesConfigurationQuery from '~/work_items/graphql/work_item_types_configuration.query.graphql';

export default normalizeRender({
  name: 'WorkItemMetadataProvider',
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
      hasBlockedIssuesFeature: computed(() => this.metadata.hasBlockedIssuesFeature),
      hasGroupBulkEditFeature: computed(() => this.metadata.hasGroupBulkEditFeature),
      hasCustomFieldsFeature: computed(() => this.metadata.hasCustomFieldsFeature),
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
      canAdminLabel: computed(() => Boolean(this.metadata?.adminLabel)),
      canCreateProjects: computed(() => Boolean(this.metadata?.createProjects)),
      canBulkAdminEpic: computed(() => Boolean(this.metadata?.bulkAdminEpic)),
      isGroup: computed(() => this.metadata.id?.includes(TYPENAME_GROUP) || false),
      calendarPath: computed(() => this.metadata.calendarPath),
      rssPath: computed(() => this.metadata.rssPath),
      autocompleteAwardEmojisPath: computed(() => this.metadata.autocompleteAwardEmojisPath),
      newTrialPath: computed(() => this.metadata.newTrialPath),
      newIssuePath: computed(() => this.metadata.newIssuePath),
      groupPath: computed(() => this.metadata.groupPath),
      releasesPath: computed(() => this.metadata.releasesPath),
      projectImportJiraPath: computed(() => this.metadata.projectImportJiraPath),
      exportCsvPath: computed(() => this.metadata.exportCsvPath),
      canAdminIssue: computed(() => Boolean(this.metadata?.adminIssue)),
      canAdminProject: computed(() => Boolean(this.metadata?.adminProject)),
      canImportWorkItems: computed(() => Boolean(this.metadata?.importWorkItems)),
      groupId: computed(() => this.metadata?.groupId),
      isIssueRepositioningDisabled: computed(() =>
        Boolean(this.metadata?.isIssueRepositioningDisabled),
      ),
      maxAttachmentSize: computed(() => this.metadata?.maxAttachmentSize),
      showNewWorkItem: computed(() => Boolean(this.metadata?.showNewWorkItem)),
      showNewIssueLink: computed(() => Boolean(this.metadata?.showNewWorkItem)),
      timeTrackingLimitToHours: computed(() => Boolean(this.metadata?.timeTrackingLimitToHours)),
      duoRemoteFlowsAvailability: computed(() => Boolean(this.metadata?.hasDuoRemoteFlowsFeature)),
      hasProjects: computed(() => Boolean(this.metadata?.hasProjects)),
      canReadCrmOrganization: computed(() => Boolean(this.metadata?.readCrmOrganization)),
      canReadCrmContact: computed(() => Boolean(this.metadata?.readCrmContact)),
      projectNamespaceFullPath: computed(() => this.metadata?.namespaceFullPath),
      getWorkItemTypeConfiguration: computed(() => (typeName) => {
        return this.workItemTypesConfiguration[typeName];
      }),
      workItemTypesConfiguration: computed(() => this.workItemTypesConfiguration),
      subscribedSavedViewLimit: computed(() => this.metadata.subscribedSavedViewLimit),
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
      workItemTypesConfiguration: {},
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
          ...(namespace.availableFeatures || {}),
          ...(namespace.linkPaths || {}),
          ...(namespace.userPermissions || {}),
          ...(namespace.metadata || {}),
          id: namespace.id,
          subscribedSavedViewLimit: namespace.subscribedSavedViewLimit,
        };
      },
    },
    workItemTypesConfiguration: {
      query: workItemTypesConfigurationQuery,
      variables() {
        return {
          fullPath: this.fullPath,
        };
      },
      update(data) {
        const nodes = data?.namespace?.workItemTypes?.nodes || [];
        // Transform array to hash keyed by type name
        return nodes.reduce((acc, type) => {
          return { ...acc, [type.name]: type };
        }, {});
      },
    },
  },
  render() {
    return this.$scopedSlots.default?.();
  },
});
</script>
