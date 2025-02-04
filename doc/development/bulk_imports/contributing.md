---
stage: Foundations
group: Import and Integrate
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: Add new relations to the direct transfer importer
---

At a high level, to add a new relation to the direct transfer importer, you must:

1. Add a new relation to the list of exported data.
1. Add a new ETL (Extract/Transform/Load) Pipeline on the import side with data processing instructions.
1. Add newly-created pipeline to the list of importing stages.
1. Add a label for the newly created relation to display in the UI.
1. Ensure sufficient test coverage.

NOTE:
To mitigate the risk of introducing bugs and performance issues, newly added relations should be put behind a feature flag.

## Export from source

There are a few types of relations we export:

- ActiveRecord associations. Read from `import_export.yml` file, serialized to JSON, written to a NDJSON file. Each relation is exported to either a `.gz` file, or `.tar.gz`
  file if a collection, uploaded, and served using the REST API of destination instance of GitLab to download and import.
- Binary files. For example, uploads or LFS objects.
- A handful of relations that are not exported but are read from the GraphQL API directly during import.

For ActiveRecord associations, you should use NDJSON over GraphQL API for performance reasons. Heavily-nested associations can produce a lot of network
requests which can slow down the overall migration.

### Exporting an ActiveRecord relation

The direct transfer importer's underlying behavior is heavily based on file-based importer,
which uses the [`import_export.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/import_export/project/import_export.yml) file that
describes a list of `Project` associations to be included in the export.
A similar [`import_export.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/import_export/group/import_export.yml) is available for `Group`.

For example, let's say we have a new `Project` association called `documents`. To add support for importing that new association, we must:

1. Add it to `import_export.yml` file.
1. Add test coverage for the new relation.
1. Verify that the added relation is exporting as expected.

#### Add it to `import_export.yml` file

NOTE:
Associations listed in this file are imported from top to bottom. If you have an association that is order-dependent, put the dependencies before the
associations that require them. For example, documents must be imported before merge requests, otherwise they are not valid.

1. Add your association to `tree.project` within the `import_export.yml`.

   ```diff
   diff --git a/lib/gitlab/import_export/project/import_export.yml b/lib/gitlab/import_export/project/import_export.yml
   index 43d66e0e67b7..0880a27dfce2 100644
   --- a/lib/gitlab/import_export/project/import_export.yml
   +++ b/lib/gitlab/import_export/project/import_export.yml
   @@ -122,6 +122,7 @@ tree:
            - label:
              - :priorities
        - :service_desk_setting
   +    - :documents
      group_members:
        - :user
   ```

   NOTE:
   If your association is relates to an Enterprise Edition-only feature, add it to the `ee.tree.project` tree at the end of the file so that it is only exported
   and imported in Enterprise Edition instances of GitLab.

   If your association doesn't need to include any sub-relations, then this is enough. But if it needs more sub-relations to be included (for example, notes),
   you must list them out. Let's say documents can have notes (with award emojis on notes) and award emojis (on documents), which we want to migrate. In this
   case, our relation becomes the following:

   ```diff
   diff --git a/lib/gitlab/import_export/project/import_export.yml b/lib/gitlab/import_export/project/import_export.yml
   index 43d66e0e67b7..0880a27dfce2 100644
   --- a/lib/gitlab/import_export/project/import_export.yml
   +++ b/lib/gitlab/import_export/project/import_export.yml
   @@ -122,6 +122,7 @@ tree:
            - label:
              - :priorities
        - :service_desk_setting
   +    - documents:
          - :award_emoji
          - notes:
            - :award_emoji
      group_members:
        - :user
   ```

1. Add `included_attributes` of the relation. By default, any relation attribute that is not listed in `included_attributes` of the YAML file are filtered
   out on both export and import. To include the attributes you need, you must add them to `included_attributes` list as following:

   ```diff
   diff --git a/lib/gitlab/import_export/project/import_export.yml b/lib/gitlab/import_export/project/import_export.yml
   index 43d66e0e67b7..dbf0e1275ecf 100644
   --- a/lib/gitlab/import_export/project/import_export.yml
   +++ b/lib/gitlab/import_export/project/import_export.yml
   @@ -142,6 +142,9 @@ import_only_tree:

    # Only include the following attributes for the models specified.
    included_attributes:
   +  documents:
   +    - :title
   +    - :description
      user:
        - :id
        - :public_email
   ```

1. Add `excluded_attributes` of the relation. We also have `excluded_attributes` list present in the file. You don't need to add excluded attributes for
   `Project`, but you do still need to do it for `Group`. This list represent attributes that should not be included in the export and should be ignored
   on import. These attributes usually are:

   - Anything that ends on `_id` or `_ids`
   - Anything that includes `attributes` (except `custom_attributes`)
   - Anything that ends on `_html`
   - Anything sensitive (e.g. tokens, encrypted data)

   See a full list of prohibited references [here](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/import_export/attribute_cleaner.rb#L14-21).

1. Add `methods` of the relation. If your relation has a method (for example, `document.signature`) that must also be exported, you can add it in the `methods` section.
   The exported value will be present in the export and you can do something with it on import. For example, assigning it to a field.

For example, we export return value of `note_diff_file.diff_export` [method](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/import_export/project/import_export.yml#L1161-1161) and on import
[set `note_diff_file.diff`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/import_export/project/relation_factory.rb#L149-151) to the exported value of this method.

#### Add test coverage for new relation

Because the direct transfer uses the file-based importer under the hood, we must add test coverage for a new relation with tests in the scope of the file-based
importer, which also covers the export side of the direct transfer importer. Add tests to:

1. `spec/lib/gitlab/import_export/project/tree_saver_spec.rb`. A similar file is available for `Group`.
1. `ee/spec/lib/ee/gitlab/import_export/project/tree_saver_spec.rb` for EE-specific relations.

Follow other relations example to add the new tests.

#### Verifying added relation is exporting as expected

Any newly-added relation specified in `import_export.yml` is automatically added to the export files written on disk, so no extra actions are required.

Once the relation is added and tests are added, we can manually check that the relation is exported. It should automatically be included in both:

- File-based imports and exports. Use the [project export functionality](../../user/project/settings/import_export.md#export-a-project-and-its-data) to export,
  download, and inspect the exported data.
- Direct transfer exports. Use the [`export_relations` API](../../api/project_relations_export.md) to export, download, and inspect exported relations
  (it might be exported in batches).

### Export a binary relation

If adding support for a binary relation:

1. Create a new export service that performs export on disk. See example
   [`BulkImports::LfsObjectsExportService`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/app/services/bulk_imports/lfs_objects_export_service.rb).
1. Add the relation to the
   [list of `file_relations`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/app/models/bulk_imports/file_transfer/project_config.rb).
1. Add the relation to `BulkImports::FileExportService`.

[Example](https://gitlab.com/gitlab-org/gitlab/-/commit/7867db2c22fb9c9850e1dcb49f26fa2b89a665c6)

## Import on destination

As mentioned above, there are three kinds of relations in direct transfer imports:

1. NDJSON-exported relations, downloaded from the `export_relations` API. For example, `documents.ndjson.gz`.
1. GraphQL API relations. For example, `members` information is fetched using GraphQL to import group and project user memberships.
1. Binary relations, downloaded from the `export_relations` API. For example, `lfs_objects.tar.gz`.

Because the direct transfer importer is based on the Extract/Transform/Load data processing technique, to start importing a relation we must define:

- A new relation importing pipeline. For example, `DocumentsPipeline`.
- A data extractor for the pipeline to know where and how to extract the data. For example, `NdjsonPipeline`.
- A list of transformers, which is a set of classes that are going to transform the data to the format you need.
- A loader, which is going to persist data somewhere. For example, save a row in the database or create a new LFS object.

No matter what type of relation is being imported, the Pipeline class structure is the same:

```ruby
module BulkImports
  module Common
    module Pipelines
      class DocumentsPipeline
        include Pipeline

        def extract(context)
          BulkImports::Pipeline::ExtractedData.new(data: file_paths)
        end

        def transform(context, object)
          ...
        end

        def load(context, object)
          document.save!
        end
      end
    end
  end
end
```

### Importing a relation from NDJSON

#### Defining a pipeline

From the previous example, our `documents` relation is exported to NDJSON file, in which case we can use both:

- `NdjsonPipeline`, which includes automatic data transformation from a JSON to an ActiveRecord object (which is using file-based importer under the hood).
- `NdjsonExtractor`, which downloads the `.ndjson.gz` file from source instance using the `/export_relations/download` REST API endpoint.

Each step of the ETL pipeline can be defined as a method or a class.

```ruby
  class DocumentsPipeline
    include NdjsonPipeline

    relation_name 'documents'

    extractor ::BulkImports::Common::Extractors::NdjsonExtractor, relation: relation
end
```

This new pipeline will now:

1. Download the `documents.ndjson.gz` file from the source instance.
1. Read the contents of the NDJSON file and deserialize JSON to convert to an ActiveRecord object.
1. Save it in the database in scope of a project.

A pipeline can be placed under either:

- The `BulkImports::Common::Pipelines` namespace if it's shared and to be used in both Group and Project migrations. For example, `LabelsPipeline` is a common
  pipeline and is referenced in both Group and Project stage lists.
- The `BulkImports::Projects::Pipelines` namespace if a pipeline belongs to a Project migration.
- The `BulkImports::Groups::Pipelines` namespace if a pipeline belongs to a Group migration.

#### Adding a new pipeline to stages

The direct transfer importer performs migration of groups and projects in stages. The list of stages is defined in:

- For `Project`: `lib/bulk_imports/projects/stage.rb`.
- For `Group`: `lib/bulk_imports/groups/stage.rb`.

Each stage:

- Can have multiple pipelines that run in parallel.
- Must fully complete before moving to the next stage.

Let's add our pipeline to the `Project` stage:

```ruby
module BulkImports
  module Projects
    class Stage < ::BulkImports::Stage
      private

       def config
        {
          project: {
            pipeline: BulkImports::Projects::Pipelines::ProjectPipeline,
            stage: 0
          },
          repository: {
            pipeline: BulkImports::Projects::Pipelines::RepositoryPipeline,
            maximum_source_version: '15.0.0',
            stage: 1
          },
          documents: {
            pipeline: BulkImports::Projects::Pipelines::DocumentsPipeline,
            minimum_source_version: '16.11.0',
            stage: 2
          }
       end
    end
  end
end
```

We specified:

- `stage: 2`, so project and repository stages must complete first before our pipeline is run in stage 2.
- `minimum_source_version: '16.11.0'`. Because we introduced `documents` relation for exports in this milestone, it's not available in previous GitLab versions. Therefore
  so this pipeline only runs if source version is 16.11 or later.

NOTE:
If a relation is deprecated and need only to run the pipeline up to a certain version, we can specify `maximum_source_version` attribute.

#### Covering a pipeline with tests

Because we already covered the export side with tests, we must do the same for the import side. For the direct transfer importer, each pipeline has a separate spec
file that would look something like [this example](https://gitlab.com/gitlab-org/gitlab/-/blob/master/spec/lib/bulk_imports/common/pipelines/milestones_pipeline_spec.rb).

[Example](https://gitlab.com/gitlab-org/gitlab/-/blob/master/spec/lib/bulk_imports/common/pipelines/milestones_pipeline_spec.rb)

### Importing a relation from GraphQL API

If your relation is available through GraphQL API, you can use `GraphQlExtractor` and perform transformations and loading within the pipeline class.

`MembersPipeline` example:

```ruby
module BulkImports
  module Common
    module Pipelines
      class MembersPipeline
        include Pipeline

        transformer Common::Transformers::ProhibitedAttributesTransformer
        transformer Common::Transformers::MemberAttributesTransformer

        def extract(context)
          graphql_extractor.extract(context)
        end

        def load(_context, data)
          ...

          member.save!
        end

        private

        def graphql_extractor
          @graphql_extractor ||= BulkImports::Common::Extractors::GraphqlExtractor
            .new(query: BulkImports::Common::Graphql::GetMembersQuery)
        end
      end
    end
  end
end

```

The rest of the steps are identical to the steps above.

### Import a binary relation

A binary relation pipeline has the same structure as other pipelines, all you need to do is define what happens during extract/transform/load steps.

`LfsObjectsPipeline` example:

```ruby
module BulkImports
  module Common
    module Pipelines
      class LfsObjectsPipeline
        include Pipeline

        file_extraction_pipeline!

        def extract(_context)
          download_service.execute
          decompression_service.execute
          extraction_service.execute

          ...
        end

        def load(_context, file_path)
          ...

          lfs_object.save!
        end
      end
    end
  end
end
```

There are a number of helper service classes to assist with data download:

- `BulkImports::FileDownloadService`: Downloads a file from a given location.
- `BulkImports::FileDecompressionService`: Gzip decompression service with required validations.
- `BulkImports::ArchiveExtractionService`: Tar extraction service.

## Adapt the UI

### Add a label for the new relation

Once a new relation is added to Direct Transfer, you need to make sure that the relation is displayed in human readable form in the UI.

1. Add a new key value pair to the [`BULK_IMPORT_STATIC_ITEMS`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/app/assets/javascripts/import/constants.js#L9)

```diff
diff --git a/app/assets/javascripts/import/constants.js b/app/assets/javascripts/import/constants.js
index 439f453cd9d3..d6b4119a0af9 100644
--- a/app/assets/javascripts/import/constants.js
+++ b/app/assets/javascripts/import/constants.js
@@ -31,6 +31,7 @@ export const BULK_IMPORT_STATIC_ITEMS = {
   service_desk_setting: __('Service Desk'),
   vulnerabilities: __('Vulnerabilities'),
   commit_notes: __('Commit notes'),
+  documents: __('Documents')
 };
 
 const STATISTIC_ITEMS = {
```
