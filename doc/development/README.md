---
comments: false
description: 'Learn how to contribute to GitLab.'
---

# Contributor and Development Docs

## Get started

- Set up GitLab's development environment with [GitLab Development Kit (GDK)](https://gitlab.com/gitlab-org/gitlab-development-kit/blob/master/doc/howto/README.md)
- [GitLab contributing guide](contributing/index.md)
- [Architecture](architecture.md) of GitLab
- [Rake tasks](rake_tasks.md) for development

## Processes

- [GitLab core team & GitLab Inc. contribution process](https://gitlab.com/gitlab-org/gitlab/blob/master/PROCESS.md)
- [Generate a changelog entry with `bin/changelog`](changelog.md)
- [Code review guidelines](code_review.md) for reviewing code and having code reviewed
- [Database review guidelines](database_review.md) for reviewing database-related changes and complex SQL queries
- [Pipelines for the GitLab project](pipelines.md)
- [Guidelines for implementing Enterprise Edition features](ee_features.md)
- [Security process for developers](https://gitlab.com/gitlab-org/release/docs/blob/master/general/security/developer.md#security-releases-critical-non-critical-as-a-developer)
- [Requesting access to Chatops on GitLab.com](chatops_on_gitlabcom.md#requesting-access) (for GitLabbers)
- [Danger bot](dangerbot.md)

## UX and Frontend guides

- [GitLab Design System](https://design.gitlab.com/) for building GitLab with existing CSS styles and elements
- [Frontend guidelines](fe_guide/index.md)
- [Emoji guide](fe_guide/emojis.md)

## Backend guides

- [GitLab utilities](utilities.md)
- [Issuable-like Rails models](issuable-like-models.md)
- [Logging](logging.md)
- [API styleguide](api_styleguide.md) Use this styleguide if you are
  contributing to the API
- [GraphQL API styleguide](api_graphql_styleguide.md) Use this
  styleguide if you are contributing to the [GraphQL API](../api/graphql/index.md)
- [Sidekiq guidelines](sidekiq_style_guide.md) for working with Sidekiq workers
- [Working with Gitaly](gitaly.md)
- [Manage feature flags](feature_flags.md)
- [Licensed feature availability](licensed_feature_availability.md)
- [View sent emails or preview mailers](emails.md)
- [Shell commands](shell_commands.md) in the GitLab codebase
- [`Gemfile` guidelines](gemfile.md)
- [Pry debugging](pry_debugging.md)
- [Sidekiq debugging](sidekiq_debugging.md)
- [Accessing session data](session.md)
- [Gotchas](gotchas.md) to avoid
- [Avoid modules with instance variables](module_with_instance_variables.md) if possible
- [How to dump production data to staging](db_dump.md)
- [Working with the GitHub importer](github_importer.md)
- [Import/Export development documentation](import_export.md)
- [Elasticsearch integration docs](elasticsearch.md)
- [Working with Merge Request diffs](diffs.md)
- [Kubernetes integration guidelines](kubernetes.md)
- [Permissions](permissions.md)
- [Prometheus metrics](prometheus_metrics.md)
- [Guidelines for reusing abstractions](reusing_abstractions.md)
- [DeclarativePolicy framework](policies.md)
- [How Git object deduplication works in GitLab](git_object_deduplication.md)
- [Geo development](geo.md)
- [Routing](routing.md)
- [Repository mirroring](repository_mirroring.md)
- [Git LFS](lfs.md)
- [Developing against interacting components or features](interacting_components.md)
- [File uploads](uploads.md)
- [Auto DevOps development guide](auto_devops.md)
- [Cycle Analytics development guide](cycle_analytics.md)

## Performance guides

- [Instrumentation](instrumentation.md) for Ruby code running in production
  environments
- [Performance guidelines](performance.md) for writing code, benchmarks, and
  certain patterns to avoid
- [Merge request performance guidelines](merge_request_performance_guidelines.md)
  for ensuring merge requests do not negatively impact GitLab performance
- [Profiling](profiling.md) a URL, measuring performance using Sherlock, or
  tracking down N+1 queries using Bullet

## Database guides

### Tooling

- [Understanding EXPLAIN plans](understanding_explain_plans.md)
- [explain.depesz.com](https://explain.depesz.com/) for visualising the output
  of `EXPLAIN`
- [pgFormatter](http://sqlformat.darold.net/) a PostgreSQL SQL syntax beautifier

### Migrations

- [What requires downtime?](what_requires_downtime.md)
- [SQL guidelines](sql.md) for working with SQL queries
- [Migrations style guide](migration_style_guide.md) for creating safe SQL migrations
- [Testing Rails migrations](testing_guide/testing_migrations_guide.md) guide
- [Post deployment migrations](post_deployment_migrations.md)
- [Background migrations](background_migrations.md)
- [Swapping tables](swapping_tables.md)
- [Deleting migrations](deleting_migrations.md)

### Best practices

- [Merge Request checklist](database_merge_request_checklist.md)
- [Adding database indexes](adding_database_indexes.md)
- [Foreign keys & associations](foreign_keys.md)
- [Single table inheritance](single_table_inheritance.md)
- [Polymorphic associations](polymorphic_associations.md)
- [Serializing data](serializing_data.md)
- [Hash indexes](hash_indexes.md)
- [Storing SHA1 hashes as binary](sha1_as_binary.md)
- [Iterating tables in batches](iterating_tables_in_batches.md)
- [Ordering table columns](ordering_table_columns.md)
- [Verifying database capabilities](verifying_database_capabilities.md)
- [Database Debugging and Troubleshooting](database_debugging.md)
- [Query Count Limits](query_count_limits.md)
- [Database helper modules](database_helpers.md)
- [Code comments](code_comments.md)
- [Creating enums](creating_enums.md)

### Case studies

- [Database case study: Filtering by label](filtering_by_label.md)
- [Database case study: Namespaces storage statistics](namespaces_storage_statistics.md)

## Integration guides

- [Jira Connect app](integrations/jira_connect.md)

## Testing guides

- [Testing standards and style guidelines](testing_guide/index.md)
- [Frontend testing standards and style guidelines](testing_guide/frontend_testing.md)

## Documentation guides

- [Writing documentation](documentation/index.md)
- [Documentation styleguide](documentation/styleguide.md)
- [Markdown](../user/markdown.md)

## Internationalization (i18n) guides

- [Introduction](i18n/index.md)
- [Externalization](i18n/externalization.md)
- [Translation](i18n/translation.md)

## Event tracking guides

- [Introduction](event_tracking/index.md)
- [Frontend tracking guide](event_tracking/frontend.md)
- [Backend tracking guide](event_tracking/backend.md)

## Experiment Guide

- [Introduction](experiment_guide/index.md)

## Build guides

- [Building a package for testing purposes](build_test_package.md)

## Compliance

- [Licensing](licensing.md) for ensuring license compliance

## Go guides

- [Go Guidelines](go_guide/index.md)

## Shell Scripting guides

- [Shell scripting standards and style guidelines](shell_scripting_guide/index.md)

## Other Development guides

- [Defining relations between files using projections](projections.md)

## Other GitLab Development Kit (GDK) guides

- [Run full Auto DevOps cycle in a GDK instance](https://gitlab.com/gitlab-org/gitlab-development-kit/blob/master/doc/howto/auto_devops.md)
- [Using GitLab Runner with GDK](https://gitlab.com/gitlab-org/gitlab-development-kit/blob/master/doc/howto/runner.md)
