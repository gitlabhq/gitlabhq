---
stage: Create
group: Source Code
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: Custom group-level project templates development guidelines
---

This document was created to help contributors understand the code design of
[custom group-level project templates](../../user/group/custom_project_templates.md).
You should read this document before making changes to the code for this feature.

This document is intentionally limited to an overview of how the code is
designed, as code can change often. To understand how a specific part of the
feature works, view the code and the specs. The details here explain how the
major components of the templating feature work.

NOTE:
This document should be updated when parts of the codebase referenced in this
document are updated, removed, or new parts are added.

## Basic overview

A custom group-level project template is a regular project that is exported and
then imported into the newly created project.

Given we have `Group1` which contains template subgroup named `Subgroup1`.
Inside Subgroup1 we have a project called `Template1`.
`User1` creates `Project1` inside `Group1` using `Template1`, the logic follows these
steps:

1. Initialize `Project1`
1. Export `Template1`
1. Import into `Project1`

## Business logic

- `ProjectsController#create`: the controller where the flow begins
  - Defined in `app/controllers/projects_controller.rb`.
- `Projects::CreateService`: handles the creation of the project.
  - Defined in `app/services/projects/create_service.rb`.
- `EE::Projects::CreateService`: EE extension for create service
  - Defined in `ee/app/services/ee/projects/create_service.rb`.
- `Projects::CreateFromTemplateService`: handles creating a project from a custom project template.
  - Defined in `app/services/projects/create_from_template_service.rb`
- `EE:Projects::CreateFromTemplateService`: EE extension for create from template service.
  - Defined in `ee/app/services/ee/projects/create_from_template_service.rb`.
- `Projects::GitlabProjectsImportService`: Handles importing the template.
  - Defined in `app/services/projects/gitlab_projects_import_service.rb`.
- `EE::Projects::GitlabProjectsImportService`: EE extension to import service.
  - Defined in `ee/app/services/ee/projects/gitlab_projects_import_service.rb`.
- `ProjectTemplateExportWorker`: Handles exporting the custom template.
  - Defined in `ee/app/workers/project_template_export_worker.rb`.
- `ProjectExportWorker`: Base class for ProjectTemplateExportWorker.
  - Defined in `app/workers/project_export_worker.rb`.
- `Projects::ImportExport::ExportService`: Service to export project.
  - Defined in `app/workers/project_export_worker.rb`.
- `Gitlab::ImportExport::VersionSaver`: Handles exporting the versions.
  - Defined in `lib/gitlab/import_export/version_saver.rb`.
- `Gitlab::ImportExport::UploadsManager`: Handles exporting uploaded files.
  - Defined in `lib/gitlab/import_export/uploads_manager.rb`.
- `Gitlab::ImportExport::AvatarSaver`: Exports the avatars.
  - Defined in `lib/gitlab/import_export/avatar_saver.rb`.
- `Gitlab::ImportExport::Project::TreeSaver`: Exports the project and related objects.
  - Defined in `lib/gitlab/import_export/project/tree_saver.rb`.
- `EE:Gitlab::ImportExport::Project::TreeSaver`: Exports the project and related objects.
  - Defined in `lib/gitlab/import_export/project/tree_saver.rb`.
- `Gitlab::ImportExport::Json::StreamingSerializer`: Serializes the exported objects to JSON.
  - Defined in `lib/gitlab/import_export/json/streaming_serializer.rb`.
- `Gitlab::ImportExport::Reader`: Wrapper around exported JSON files.
  - Defined in `lib/gitlab/import_export/reader.rb`.
- `Gitlab::ImportExport::AttributesFinder`: Parses configuration and finds attributes in exported JSON files.
  - Defined in `lib/gitlab/import_export/attributes_finder.rb`.
- `Gitlab::ImportExport::Config`: Wrapper around import/export YAML configuration file.
  - Defined in `lib/gitlab/import_export/config.rb`.
- `Gitlab::ImportExport`: Entry point with convenience methods.
  - Defined in `lib/gitlab/import_export.rb`.
- `Gitlab::ImportExport::UploadsSaver`: Exports uploaded files.
  - Defined in `lib/gitlab/import_export/uploads_saver.rb`.
- `Gitlab::ImportExport::RepoSaver`: Exports the repository.
  - Defined in `lib/gitlab/import_export/repo_saver.rb`.
- `Gitlab::ImportExport::WikiRepoSaver`: Exports the wiki repository.
  - Defined in `lib/gitlab/import_export/wiki_repo_saver.rb`.
- `EE:Gitlab::ImportExport::WikiRepoSaver`: Extends wiki repository saver.
  - Defined in `ee/lib/ee/gitlab/import_export/wiki_repo_saver.rb`.
- `Gitlab::ImportExport::LfsSaver`: Export LFS objects and files.
  - Defined in `lib/gitlab/import_export/lfs_saver.rb`.
- `Gitlab::ImportExport::SnippetsRepoSaver`: Exports snippets repository
  - Defined in `lib/gitlab/import_export/snippet_repo_saver.rb`.
- `Gitlab::ImportExport::DesignRepoSaver`: Exports design repository
  - Defined in `lib/gitlab/import_export/design_repo_saver.rb`.
- `Gitlab::ImportExport::Error`: Custom error object.
  - Defined in `lib/gitlab/import_export/error.rb`.
- `Gitlab::ImportExport::AfterExportStrategyBuilder`: Acts as callback to run after export is completed.
  - Defined in `lib/gitlab/import_export/after_export_strategy_builder.rb`.
- `Gitlab::Export::Logger`: Logger used during export.
  - Defined in `lib/gitlab/export/logger.rb`.
- `Gitlab::ImportExport::LogUtil`: Builds log messages.
  - Defined in `lib/gitlab/import_export/log_util.rb`.
- `Gitlab::ImportExport::AfterExportStrategies::CustomTemplateExportImportStrategy`: Callback class to import the template after it has been exported.
  - Defined in `ee/lib/ee/gitlab/import_export/after_export_strategies/custom_template_export_import_strategy.rb`.
- `Gitlab::TemplateHelper`: Helpers for importing templates.
  - Defined in `lib/gitlab/template_helper.rb`.
- `ImportExportUpload`: Stores the import and export archive files.
  - Defined in `app/models/import_export_upload.rb`.
- `Gitlab::ImportExport::AfterExportStrategies::BaseAfterExportStrategy`: Base after export strategy.
  - Defined in `lib/gitlab/import_export/after_export_strategies/base_after_export_strategy.rb`.
- `RepositoryImportWorker`: Worker to trigger the import step.
  - Defined in `app/workers/repository_import_worker.rb`.
- `EE::RepositoryImportWorker`: Extension to repository import worker.
  - Defined in `ee/app/workers/ee/repository_import_worker.rb`.
- `Projects::ImportService`: Executes the import step.
  - Defined in `app/services/projects/import_service.rb`.
- `EE:Projects::ImportService`: Extends import service.
  - Defined in `ee/app/services/ee/projects/import_service.rb`.
- `Projects::LfsPointers::LfsImportService`: Imports the LFS objects.
  - Defined in `app/services/projects/lfs_pointers/lfs_import_service.rb`.
- `Projects::LfsPointers::LfsObjectDownloadListService`: Main service to request links to download LFS objects.
  - Defined in `app/services/projects/lfs_pointers/lfs_object_download_list_service.rb`.
- `Projects::LfsPointers::LfsDownloadLinkListService`: Handles requesting links in batches and building list.
  - Defined in `app/services/projects/lfs_pointers/lfs_download_link_list_service.rb`.
- `Projects::LfsPointers::LfsListService`: Retrieves LFS blob pointers.
  - Defined in `app/services/projects/lfs_pointers/lfs_list_service.rb`.
- `Projects::LfsPointers::LfsDownloadService`: Downloads and links LFS objects.
  - Defined in `app/services/projects/lfs_pointers/lfs_download_service.rb`.
- `Gitlab::ImportSources`: Module to configure which importer to use.
  - Defined in `lib/gitlab/import_sources.rb`.
- `EE::Gitlab::ImportSources`: Extends import sources.
  - Defined in `ee/lib/ee/gitlab/import_sources.rb`.
- `Gitlab::ImportExport::Importer`: Importer class.
  - Defined in `lib/gitlab/import_export/importer.rb`.
- `EE::Gitlab::ImportExport::Importer`: Extends importer.
  - Defined in `ee/lib/ee/gitlab/import_export/importer.rb`.
- `Gitlab::ImportExport::FileImporter`: Imports archive files.
  - Defined in `lib/gitlab/import_export/file_importer.rb`.
- `Gitlab::ImportExport::DecompressedArchiveSizeValidator`: Validates archive file size.
  - Defined in `lib/gitlab/import_export/decompressed_archive_size_validator.rb`.
- `Gitlab::ImportExport::VersionChecker`: Verifies version of export matches importer.
  - Defined in `lib/gitlab/import_export/version_checker.rb`.
- `Gitlab::ImportExport::Project::TreeRestorer`: Handles importing project and associated objects.
  - Defined in `lib/gitlab/import_export/project/tree_restorer.rb`.
- `Gitlab::ImportExport::Json::NdjsonReader`: Reader for JSON export files.
  - Defined in `lib/gitlab/import_export/json/ndjson_reader.rb`.
- `Gitlab::ImportExport::AvatarRestorer`: Handles importing avatar files.
  - Defined in `lib/gitlab/import_export/avatar_restorer.rb`.
- `Gitlab::ImportExport::RepoRestorer`: Handles importing repositories.
  - Defined in `lib/gitlab/import_export/repo_restorer.rb`.
- `EE:Gitlab::ImportExport::RepoRestorer`: Extends repository restorer.
  - Defined in `ee/lib/ee/gitlab/import_export/repo_restorer.rb`.
- `Gitlab::ImportExport::DesignRepoRestorer`: Handles restoring design repository.
  - Defined in `lib/gitlab/import_export/design_repo_restorer.rb`.
- `Gitlab::ImportExport::UploadsRestorer`: Handles restoring uploaded files.
  - Defined in `lib/gitlab/import_export/uploads_restorer.rb`.
- `Gitlab::ImportExport::LfsRestorer`: Restores LFS objects.
  - Defined in `lib/gitlab/import_export/lfs_restorer.rb`.
- `Gitlab::ImportExport::SnippetsRepoRestorer`: Handles restoring snippets repository.
  - Defined in `lib/gitlab/import_export/snippets_repo_restorer.rb`.
- `Gitlab::ImportExport::SnippetRepoRestorer`: Handles restoring individual snippets.
  - Defined in `lib/gitlab/import_export/snippet_repo_restorer.rb`.
- `Snippets::RepositoryValidationService`: Validates snippets repository archive.
  - Defined in `app/services/snippets/repository_validation_service.rb`.
- `Snippets::UpdateStatisticsService`: Updates statistics for the snippets repository.
  - Defined in `app/services/snippets/update_statistics_service.rb`.
- `Gitlab::BackgroundMigration::BackfillSnippetRepositories`: Backfills missing snippets in hashed storage.
  - Defined in `lib/gitlab/background_migration/backfill_snippet_repositories.rb`.
- `Gitlab::ImportExport::StatisticsRestorer`: Refreshes project statistics.
  - Defined in `lib/gitlab/import_export/importer.rb`.
- `Gitlab::ImportExport::Project::CustomTemplateRestorer`: Handles additional imports for custom templates.
  - Defined in `ee/lib/gitlab/import_export/project/custom_template_restorer.rb`.
- `Gitlab::ImportExport::Project::ProjectHooksRestorer`: Handles importing project hooks.
  - Defined in `ee/lib/gitlab/import_export/project/project_hooks_restorer.rb`.
- `Gitlab::ImportExport::Project::DeployKeysRestorer`: Handles importing deploy keys.
  - Defined in `ee/lib/gitlab/import_export/project/deploy_keys_restorer.rb`.
- `Gitlab::ImportExport::Project::CustomTemplateRestorerHelper`: Helpers for custom templates restorer.
  - Defined in `ee/lib/gitlab/import_export/project/custom_template_restorer_helper.rb`.
