---
stage: none
group: unassigned
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: Feature development
---

Consult these topics for information on contributing to specific GitLab features.

## UX and Frontend guides

- [GitLab Design System](https://design.gitlab.com/), for building GitLab with
  existing CSS styles and elements
- [Frontend guidelines](fe_guide/_index.md)
- [Emoji guide](fe_guide/emojis.md)

## Backend guides

### General

- [Software design guides](software_design.md)
- [GitLab EventStore](event_store.md) to publish/subscribe to domain events
- [GitLab utilities](utilities.md)
- [Newlines style guide](backend/ruby_style_guide.md#newlines-style-guide)
- [Logging](logging.md)
- [Dealing with email/mailers](emails.md)
- [Kubernetes integration guidelines](kubernetes.md)
- [Permissions](permissions.md)
- [Code comments](code_comments.md)
- [Windows Development on GCP](windows.md)
- [FIPS 140-2 and 140-3](fips_gitlab.md)
- [`Gemfile` guidelines](gemfile.md)
- [Ruby upgrade guidelines](ruby_upgrade.md)

### Things to be aware of

- [Gotchas](gotchas.md) to avoid
- [Avoid modules with instance variables](module_with_instance_variables.md), if
  possible
- [Guidelines for reusing abstractions](reusing_abstractions.md)
- [Ruby 3 gotchas](ruby3_gotchas.md)

### Rails Framework related

- [Routing](routing.md)
- [Rails initializers](rails_initializers.md)
- [Mass Inserting Models](mass_insert.md)
- [Issuable-like Rails models](issuable-like-models.md)
- [Issue types vs first-class types](issue_types.md)
- [DeclarativePolicy framework](policies.md)
- [Rails update guidelines](rails_update.md)

### Debugging

- [Pry debugging](pry_debugging.md)
- [Sidekiq debugging](../administration/sidekiq/sidekiq_troubleshooting.md)
- [VS Code debugging](vs_code_debugging.md)

### Git specifics

- [How Git object deduplication works in GitLab](git_object_deduplication.md)
- [Git LFS](lfs.md)

### API

- [API style guide](api_styleguide.md) for contributing to the API
- [GraphQL API style guide](api_graphql_styleguide.md) for contributing to the
  [GraphQL API](../api/graphql/_index.md)

### GitLab components and features

- [Developing against interacting components or features](interacting_components.md)
- [Manage feature flags](feature_flags/_index.md)
- [Implementing Enterprise Edition features](ee_features.md)
- [Accessing session data](session.md)
- [How to dump production data to staging](database/db_dump.md)
- [Geo development](geo.md)
- [Redis guidelines](redis.md)
  - [Adding a new Redis instance](redis/new_redis_instance.md)
- [Sidekiq guidelines](sidekiq/_index.md) for working with Sidekiq workers
- [Working with Gitaly](gitaly.md)
- [Advanced search integration docs](advanced_search.md)
- [Working with merge request diffs](merge_request_concepts/diffs/_index.md)
- [Approval Rules](merge_request_concepts/approval_rules.md)
- [Repository mirroring](repository_mirroring.md)
- [Uploads development guide](uploads/_index.md)
- [Auto DevOps development guide](auto_devops.md)
- [Renaming features](renaming_features.md)
- [Code Intelligence](code_intelligence/_index.md)
- [Feature categorization](feature_categorization/_index.md)
- [Wikis development guide](wikis.md)
- [Image scaling guide](image_scaling.md)
- [Cascading Settings](cascading_settings.md)
- [Shell commands](shell_commands.md) in the GitLab codebase
- [Value Stream Analytics development guide](value_stream_analytics.md)
- [Application limits](application_limits.md)
- [AI features](ai_features/_index.md)
- [Application settings](application_settings.md)
- [Remote Development](remote_development/_index.md)
- [Markdown (GLFM) development guide](gitlab_flavored_markdown/_index.md)

### Import and Export

- [Add new relations to the direct transfer importer](bulk_imports/contributing.md)
- [Principles of importer design](import/principles_of_importer_design.md)
- [Working with the GitHub importer](github_importer.md)
- [Import/Export development documentation](import_export.md)
- [Test Import Project](import_project.md)
- [Group migration](bulk_import.md)
- [Export to CSV](export_csv.md)

### Integrations

- [Integrations development guide](integrations/_index.md)
- [GitLab for Jira Cloud app](integrations/jira_connect.md)
- [Security Scanners](integrations/secure.md)
- [Secure Partner Integration](integrations/secure_partner_integration.md)
- [How to run Jenkins in development environment](integrations/jenkins.md)

The following integration guides are internal. Some integrations require access to administrative accounts of third-party services and are available only for GitLab team members to contribute to:

- [Jira integration development](https://gitlab.com/gitlab-org/foundations/import-and-integrate/team/-/blob/main/integrations/jira.md)
- [GitLab for Slack app development](https://gitlab.com/gitlab-org/foundations/import-and-integrate/team/-/blob/main/integrations/slack.md)

## Performance guides

- [Performance guidelines](performance.md) for writing code, benchmarks, and
  certain patterns to avoid.
- [Caching guidelines](caching.md) for using caching in Rails under a GitLab environment.
- [Merge request performance guidelines](merge_request_concepts/performance.md)
  for ensuring merge requests do not negatively impact GitLab performance
- [Profiling](profiling.md) a URL or tracking down N+1 queries using Bullet.
- [Cached queries guidelines](cached_queries.md), for tracking down N+1 queries
  masked by query caching, memory profiling and why should we avoid cached
  queries.
- [JSON guidelines](json.md) for how to handle JSON in a performant manner.
- [GraphQL API optimizations](api_graphql_styleguide.md#optimizations) for how to optimize GraphQL code.

## Database guides

See [database guidelines](database/_index.md).

## Testing guides

- [Testing standards and style guidelines](testing_guide/_index.md)
- [Frontend testing standards and style guidelines](testing_guide/frontend_testing.md)

## Refactoring guides

- [Refactoring guidelines](refactoring_guide/_index.md)

## Deprecation guides

- [Deprecation guidelines](deprecation_guidelines/_index.md)

## Documentation guides

- [Writing documentation](documentation/_index.md)
- [Documentation style guide](documentation/styleguide/_index.md)
- [Markdown](../user/markdown.md)

## Internationalization (i18n) guides

- [Introduction](i18n/_index.md)
- [Externalization](i18n/externalization.md)
- [Translation](i18n/translation.md)

## Analytics Instrumentation guides

- [Service Ping guide](internal_analytics/service_ping/_index.md)
- [Internal Events guide](internal_analytics/internal_event_instrumentation/quick_start.md)

## Experiment guide

- [Introduction](experiment_guide/_index.md)

## Build guides

- [Building a package for testing purposes](build_test_package.md)

## Compliance

- [Licensing](licensing.md) for ensuring license compliance

## Domain-specific guides

- [CI/CD development documentation](cicd/_index.md)
- [Sec Section development documentation](sec/_index.md)

## Technical Reference by Group

- [Create: Source Code BE](backend/create_source_code_be/_index.md)

## Other development guides

- [Defining relations between files using projections](projections.md)
- [Compatibility with multiple versions of the application running at the same time](multi_version_compatibility.md)
- [Features inside `.gitlab/`](features_inside_dot_gitlab.md)
- [Dashboards for stage groups](stage_group_observability/_index.md)
- [Preventing transient bugs](transient/prevention-patterns.md)
- [GitLab Application SLIs](application_slis/_index.md)
- [Spam protection and CAPTCHA development guide](spam_protection_and_captcha/_index.md)
- [RuboCop development guide](rubocop_development_guide.md)

## Other GitLab Development Kit (GDK) guides

- [Using GitLab Runner with the GDK](https://gitlab.com/gitlab-org/gitlab-development-kit/blob/main/doc/howto/runner.md)
- [Using the Web IDE terminal with the GDK](https://gitlab.com/gitlab-org/gitlab-development-kit/-/blob/main/doc/howto/web_ide_terminal_gdk_setup.md)
- [Gitpod configuration internals page](gitpod_internals.md)
