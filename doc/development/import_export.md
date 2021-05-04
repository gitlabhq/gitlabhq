---
stage: Manage
group: Import
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Import/Export development documentation

Troubleshooting and general development guidelines and tips for the [Import/Export feature](../user/project/settings/import_export.md).

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i> This document is originally based on the [Import/Export 201 presentation available on YouTube](https://www.youtube.com/watch?v=V3i1OfExotE).

## Troubleshooting commands

Finds information about the status of the import and further logs using the JID:

```ruby
# Rails console
Project.find_by_full_path('group/project').import_state.slice(:jid, :status, :last_error)
> {"jid"=>"414dec93f941a593ea1a6894", "status"=>"finished", "last_error"=>nil}
```

```shell
# Logs
grep JID /var/log/gitlab/sidekiq/current
grep "Import/Export error" /var/log/gitlab/sidekiq/current
grep "Import/Export backtrace" /var/log/gitlab/sidekiq/current
tail /var/log/gitlab/gitlab-rails/importer.log
```

## Troubleshooting performance issues

Read through the current performance problems using the Import/Export below.

### OOM errors

Out of memory (OOM) errors are normally caused by the [Sidekiq Memory Killer](../administration/operations/sidekiq_memory_killer.md):

```shell
SIDEKIQ_MEMORY_KILLER_MAX_RSS = 2000000
SIDEKIQ_MEMORY_KILLER_HARD_LIMIT_RSS = 3000000
SIDEKIQ_MEMORY_KILLER_GRACE_TIME = 900
```

An import status `started`, and the following Sidekiq logs signal a memory issue:

```shell
WARN: Work still in progress <struct with JID>
```

### Timeouts

Timeout errors occur due to the `Gitlab::Import::StuckProjectImportJobsWorker` marking the process as failed:

```ruby
module Gitlab
  module Import
    class StuckProjectImportJobsWorker
      include Gitlab::Import::StuckImportJob
      # ...
    end
  end
end

module Gitlab
  module Import
    module StuckImportJob
      # ...
      IMPORT_JOBS_EXPIRATION = 15.hours.to_i
      # ...
      def perform
        stuck_imports_without_jid_count = mark_imports_without_jid_as_failed!
        stuck_imports_with_jid_count = mark_imports_with_jid_as_failed!

        track_metrics(stuck_imports_with_jid_count, stuck_imports_without_jid_count)
      end
      # ...
    end
  end
end
```

```shell
Marked stuck import jobs as failed. JIDs: xyz
```

```plaintext
  +-----------+    +-----------------------------------+
  |Export Job |--->| Calls ActiveRecord `as_json` and  |
  +-----------+    | `to_json` on all project models   |
                   +-----------------------------------+

  +-----------+    +-----------------------------------+
  |Import Job |--->| Loads all JSON in memory, then    |
  +-----------+    | inserts into the DB in batches    |
                   +-----------------------------------+
```

### Problems and solutions

| Problem | Possible solutions |
| -------- | -------- |
| [Slow JSON](https://gitlab.com/gitlab-org/gitlab/-/issues/25251) loading/dumping models from the database | [split the worker](https://gitlab.com/gitlab-org/gitlab/-/issues/25252) |
| | Batch export
| | Optimize SQL
| | Move away from `ActiveRecord` callbacks (difficult)
| High memory usage (see also some [analysis](https://gitlab.com/gitlab-org/gitlab/-/issues/18857) | DB Commit sweet spot that uses less memory |
| | [Netflix Fast JSON API](https://github.com/Netflix/fast_jsonapi) may help |
| | Batch reading/writing to disk and any SQL

### Temporary solutions

While the performance problems are not tackled, there is a process to workaround
importing big projects, using a foreground import:

[Foreground import](https://gitlab.com/gitlab-com/gl-infra/infrastructure/-/issues/5384) of big projects for customers.
(Using the import template in the [infrastructure tracker](https://gitlab.com/gitlab-com/gl-infra/infrastructure/))

## Security

The Import/Export feature is constantly updated (adding new things to export), however
the code hasn't been refactored in a long time. We should perform a code audit (see
[confidential issue](../user/project/issues/confidential_issues.md) `https://gitlab.com/gitlab-org/gitlab/-/issues/20720`).
to make sure its dynamic nature does not increase the number of security concerns.

### Security in the code

Some of these classes provide a layer of security to the Import/Export.

The `AttributeCleaner` removes any prohibited keys:

```ruby
# AttributeCleaner
# Removes all `_ids` and other prohibited keys
    class AttributeCleaner
      ALLOWED_REFERENCES = RelationFactory::PROJECT_REFERENCES + RelationFactory::USER_REFERENCES + ['group_id']

      def clean
        @relation_hash.reject do |key, _value|
          prohibited_key?(key) || !@relation_class.attribute_method?(key) || excluded_key?(key)
        end.except('id')
      end

      ...

```

The `AttributeConfigurationSpec` checks and confirms the addition of new columns:

```ruby
# AttributeConfigurationSpec
<<-MSG
  It looks like #{relation_class}, which is exported using the project Import/Export, has new attributes:

  Please add the attribute(s) to SAFE_MODEL_ATTRIBUTES if you consider this can be exported.
  Otherwise, please blacklist the attribute(s) in IMPORT_EXPORT_CONFIG by adding it to its correspondent
  model in the +excluded_attributes+ section.

  SAFE_MODEL_ATTRIBUTES: #{File.expand_path(safe_attributes_file)}
  IMPORT_EXPORT_CONFIG: #{Gitlab::ImportExport.config_file}
MSG
```

The `ModelConfigurationSpec` checks and confirms the addition of new models:

```ruby
# ModelConfigurationSpec
<<-MSG
  New model(s) <#{new_models.join(',')}> have been added, related to #{parent_model_name}, which is exported by
  the Import/Export feature.

  If you think this model should be included in the export, please add it to `#{Gitlab::ImportExport.config_file}`.

  Definitely add it to `#{File.expand_path(ce_models_yml)}`
  to signal that you've handled this error and to prevent it from showing up in the future.
MSG
```

The `ExportFileSpec` detects encrypted or sensitive columns:

```ruby
# ExportFileSpec
<<-MSG
  Found a new sensitive word <#{key_found}>, which is part of the hash #{parent.inspect}
  If you think this information shouldn't get exported, please exclude the model or attribute in
  IMPORT_EXPORT_CONFIG.

  Otherwise, please add the exception to +safe_list+ in CURRENT_SPEC using #{sensitive_word} as the
  key and the correspondent hash or model as the value.

  Also, if the attribute is a generated unique token, please add it to RelationFactory::TOKEN_RESET_MODELS
  if it needs to be reset (to prevent duplicate column problems while importing to the same instance).

  IMPORT_EXPORT_CONFIG: #{Gitlab::ImportExport.config_file}
  CURRENT_SPEC: #{__FILE__}
MSG
```

## Versioning

Import/Export does not use strict SemVer, since it has frequent constant changes
during a single GitLab release. It does require an update when there is a breaking change.

```ruby
# ImportExport
module Gitlab
  module ImportExport
    extend self

    # For every version update, the version history in import_export.md has to be kept up to date.
    VERSION = '0.2.4'
```

## Version history

Check the [version history](../user/project/settings/import_export.md#version-history)
for compatibility when importing and exporting projects.

### When to bump the version up

If we rename model/columns or perform any format, we need to bump the version
modifications in the JSON structure or the file structure of the archive file.

We do not need to bump the version up in any of the following cases:

- Add a new column or a model
- Remove a column or model (unless there is a DB constraint)
- Export new things (such as a new type of upload)

Every time we bump the version, the integration specs fail and can be fixed with:

```shell
bundle exec rake gitlab:import_export:bump_version
```

## A quick dive into the code

### Import/Export configuration (`import_export.yml`)

The main configuration `import_export.yml` defines what models can be exported/imported.

Model relationships to be included in the project import/export:

```yaml
project_tree:
  - labels:
    - :priorities
  - milestones:
    - events:
      - :push_event_payload
  - issues:
    - events:
    # ...
```

Only include the following attributes for the models specified:

```yaml
included_attributes:
  user:
    - :id
    - :email
  # ...
```

Do not include the following attributes for the models specified:

```yaml
excluded_attributes:
  project:
    - :name
    - :path
    - ...
```

Extra methods to be called by the export:

```yaml
# Methods
methods:
  labels:
    - :type
  label:
    - :type
```

Customize the export order of the model relationships:

```yaml
# Specify a custom export reordering for a given relationship
# For example for issues we use a custom export reordering by relative_position, so that on import, we can reset the
# relative position value, but still keep the issues order to the order in which issues were in the exported project.
# By default the ordering of relations is done by PK.
# column - specify the column by which to reorder, by default it is relation's PK
# direction - specify the ordering direction :asc or :desc, default :asc
# nulls_position - specify where would null values be positioned. Because custom ordering column can contain nulls we
#                  need to also specify where would the nulls be placed. It can be :nulls_last or :nulls_first, defaults
#                  to :nulls_last

export_reorders:
  project:
    issues:
      column: :relative_position
      direction: :asc
      nulls_position: :nulls_last
```

### Import

The import job status moves from `none` to `finished` or `failed` into different states:

_import\_status_: none -> scheduled -> started -> finished/failed

While the status is `started` the `Importer` code processes each step required for the import.

```ruby
# ImportExport::Importer
module Gitlab
  module ImportExport
    class Importer
      def execute
        if import_file && check_version! && restorers.all?(&:restore) && overwrite_project
          project
        else
          raise Projects::ImportService::Error.new(@shared.errors.join(', '))
        end
      rescue => e
        raise Projects::ImportService::Error.new(e.message)
      ensure
        remove_import_file
      end

      def restorers
        [repo_restorer, wiki_restorer, project_tree, avatar_restorer,
         uploads_restorer, lfs_restorer, statistics_restorer]
      end
```

The export service, is similar to the `Importer`, restoring data instead of saving it.

### Export

```ruby
# ImportExport::ExportService
module Projects
  module ImportExport
    class ExportService < BaseService

      def save_all!
        if save_services
          Gitlab::ImportExport::Saver.save(project: project, shared: @shared)
          notify_success
        else
          cleanup_and_notify_error!
        end
      end

      def save_services
        [version_saver, avatar_saver, project_tree_saver, uploads_saver, repo_saver,
           wiki_repo_saver, lfs_saver].all?(&:save)
      end
```

## Test fixtures

Fixtures used in Import/Export specs live in `spec/fixtures/lib/gitlab/import_export`. There are both Project and Group fixtures.

There are two versions of each of these fixtures:

- A human readable single JSON file with all objects, called either `project.json` or `group.json`.
- A folder named `tree`, containing a tree of files in `ndjson` format. **Please do not edit files under this folder manually unless strictly necessary.**

The tools to generate the NDJSON tree from the human-readable JSON files live in the [`gitlab-org/memory-team/team-tools`](https://gitlab.com/gitlab-org/memory-team/team-tools/-/blob/master/import-export/) project.

### Project

**Please use `legacy-project-json-to-ndjson.sh` to generate the NDJSON tree.**

The NDJSON tree looks like:

```shell
tree
├── project
│   ├── auto_devops.ndjson
│   ├── boards.ndjson
│   ├── ci_cd_settings.ndjson
│   ├── ci_pipelines.ndjson
│   ├── container_expiration_policy.ndjson
│   ├── custom_attributes.ndjson
│   ├── error_tracking_setting.ndjson
│   ├── external_pull_requests.ndjson
│   ├── issues.ndjson
│   ├── labels.ndjson
│   ├── merge_requests.ndjson
│   ├── milestones.ndjson
│   ├── pipeline_schedules.ndjson
│   ├── project_badges.ndjson
│   ├── project_feature.ndjson
│   ├── project_members.ndjson
│   ├── protected_branches.ndjson
│   ├── protected_tags.ndjson
│   ├── releases.ndjson
│   ├── services.ndjson
│   ├── snippets.ndjson
│   └── triggers.ndjson
└── project.json
```

### Group

**Please use `legacy-group-json-to-ndjson.rb` to generate the NDJSON tree.**

The NDJSON tree looks like this:

```shell
tree
└── groups
    ├── 4351
    │   ├── badges.ndjson
    │   ├── boards.ndjson
    │   ├── epics.ndjson
    │   ├── labels.ndjson
    │   ├── members.ndjson
    │   └── milestones.ndjson
    ├── 4352
    │   ├── badges.ndjson
    │   ├── boards.ndjson
    │   ├── epics.ndjson
    │   ├── labels.ndjson
    │   ├── members.ndjson
    │   └── milestones.ndjson
    ├── _all.ndjson
    ├── 4351.json
    └── 4352.json
```

WARNING:
When updating these fixtures, please ensure you update both `json` files and `tree` folder, as the tests apply to both.
