# frozen_string_literal: true

class UpdateFinishStatusForBbmMigrations < Gitlab::Database::Migration[2.2]
  milestone '17.3'

  FINISHED_STATUS = '3'
  FINALIZED_STATUS = '6'

  # All these migrations were finished by ensure_batched_background_migration_is_finished method.
  JOB_CLASS_NAMES = %w[
    BackfillAdminModeScopeForPersonalAccessTokens
    BackfillArchivedAndTraversalIdsToVulnerabilityReads
    BackfillBranchProtectionNamespaceSetting
    BackfillCatalogResourceVersionSemVer
    BackfillCatalogResourceVersionsReleasedAt
    BackfillClusterAgentTokensProjectId
    BackfillCodeSuggestionsNamespaceSettings
    BackfillDefaultOrganizationOwners
    BackfillDefaultOrganizationOwnersAgain
    BackfillDefaultOrganizationUsers
    BackfillDeploymentApprovalsProjectId
    BackfillDesignManagementRepositories
    BackfillDismissalReasonInVulnerabilityReads
    BackfillEpicBasicFieldsToWorkItemRecord
    BackfillEpicDatesToWorkItemDatesSources
    BackfillEpicIssuesIntoWorkItemParentLinks
    BackfillFindingIdInVulnerabilities
    BackfillHasIssuesForExternalIssueLinks
    BackfillHasRemediationsOfVulnerabilityReads
    BackfillIssueSearchDataNamespaceId
    BackfillMergeRequestDiffsProjectId
    BackfillMergeRequestReviewLlmSummariesProjectId
    BackfillMissingCiCdSettings
    BackfillMissingVulnerabilityDismissalDetails
    BackfillNugetNormalizedVersion
    BackfillOnboardingStatusStepUrl
    BackfillOrDropCiPipelineOnProjectId
    BackfillPackagesTagsProjectId
    BackfillPartitionIdCiPipelineArtifact
    BackfillPartitionIdCiPipelineChatData
    BackfillPartitionIdCiPipelineConfig
    BackfillPartitionIdCiPipelineMessage
    BackfillPartitionIdCiPipelineMetadata
    BackfillProjectStatisticsStorageSizeWithRecentSize
    BackfillProjectStatisticsStorageSizeWithoutPipelineArtifactsSizeJob
    BackfillProjectWikiRepositories
    BackfillRelatedEpicLinksToIssueLinks
    BackfillRootStorageStatisticsForkStorageSizes
    BackfillSbomOccurrencesTraversalIdsAndArchived
    BackfillUserPreferencesWithDefaults
    BackfillUsersColorModeId
    BackfillUsersWithDefaults
    BackfillUuidConversionColumnInVulnerabilityOccurrences
    BackfillVsCodeSettingsUuid
    BackfillVsCodeSettingsVersion
    BackfillWorkItemHierarchyForEpics
    BackfillWorkspacePersonalAccessToken
    BackupAndRemoveNotesWithNullNoteableType
    CleanupPersonalAccessTokensWithNilExpiresAt
    ConvertCreditCardValidationDataToHashes
    CreateComplianceStandardsAdherence
    DeleteInvalidProtectedBranchMergeAccessLevels
    DeleteInvalidProtectedBranchPushAccessLevels
    DeleteInvalidProtectedTagCreateAccessLevels
    DeleteOrphanedTransferredProjectApprovalRules
    DeleteOrphansApprovalMergeRequestRules2
    DropVulnerabilitiesWithoutFindingId
    FixAllowDescendantsOverrideDisabledSharedRunners
    FixCorruptedScannerIdsOfVulnerabilityReads
    MarkDuplicateNpmPackagesForDestruction
    MigrateHumanUserType
    PopulateVulnerabilityDismissalFields
    PurgeSecurityScansWithEmptyFindingData
    RemoveInvalidDeployAccessLevelGroups
    ResyncBasicEpicFieldsToWorkItem
    UpdateWorkspacesConfigVersion
  ].freeze

  class BatchedMigration < MigrationRecord
    self.table_name = :batched_background_migrations
  end

  def up
    BatchedMigration
      .where(status: FINISHED_STATUS, job_class_name: JOB_CLASS_NAMES)
      .update_all(status: FINALIZED_STATUS)
  end

  def down
    # no-op
  end
end
