---
comments: false
type: index, dev
stage: none
group: Development
info: "See the Technical Writers assigned to Development Guidelines: https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments-to-development-guidelines"
description: "Development Guidelines: learn how to contribute to GitLab."
---

# Contributor and Development Docs

Learn the processes and technical information needed for contributing to GitLab.

This content is intended for members of the GitLab Team as well as community contributors.
Content specific to the GitLab Team should instead be included in the [Handbook](https://about.gitlab.com/handbook/).

For information on using GitLab to work on your own software projects, see the [GitLab user documentation](../user/index.md).

For information on working with GitLab's API, see the [API documentation](../api/README.md).

For information on how to install, configure, update, and upgrade your own GitLab instance, see the [administration documentation](../administration/index.md).

## Get started

- Set up GitLab's development environment with [GitLab Development Kit (GDK)](https://gitlab.com/gitlab-org/gitlab-development-kit/-/blob/master/README.md)
- [GitLab contributing guide](contributing/index.md)
  - [Issues workflow](contributing/issue_workflow.md) for more information on:
    - Issue tracker guidelines.
    - Triaging.
    - Labels.
    - Feature proposals.
    - Issue weight.
    - Regression issues.
    - Technical or UX debt.
  - [Merge requests workflow](contributing/merge_request_workflow.md) for more
    information on:
    - Merge request guidelines.
    - Contribution acceptance criteria.
    - Definition of done.
    - Dependencies.
  - [Style guides](contributing/style_guides.md)
  - [Implement design & UI elements](contributing/design.md)
- [GitLab Architecture Overview](architecture.md)
- [Rake tasks](rake_tasks.md) for development

## Processes

**Must-reads:**

- [Guide on adapting existing and introducing new components](architecture.md#adapting-existing-and-introducing-new-components)
- [Code review guidelines](code_review.md) for reviewing code and having code reviewed
- [Database review guidelines](database_review.md) for reviewing database-related changes and complex SQL queries, and having them reviewed
- [Secure coding guidelines](secure_coding_guidelines.md)
- [Pipelines for the GitLab project](pipelines.md)

Complementary reads:

- [GitLab core team & GitLab Inc. contribution process](https://gitlab.com/gitlab-org/gitlab/blob/master/PROCESS.md)
- [Security process for developers](https://gitlab.com/gitlab-org/release/docs/blob/master/general/security/developer.md#security-releases-critical-non-critical-as-a-developer)
- [Guidelines for implementing Enterprise Edition features](ee_features.md)
- [Danger bot](dangerbot.md)
- [Generate a changelog entry with `bin/changelog`](changelog.md)
- [Requesting access to Chatops on GitLab.com](chatops_on_gitlabcom.md#requesting-access) (for GitLab team members)
- [Patch release process for developers](https://gitlab.com/gitlab-org/release/docs/blob/master/general/patch/process.md#process-for-developers)
- [Adding a new service component to GitLab](adding_service_component.md)

### Development guidelines review

When you submit a change to GitLab's development guidelines, request a review
from:

- A member of your team or group, to check for technical accuracy.
- For **significant** changes or proposals, request review from:
  - Engineering managers (FE, BE, DB, Security, UX, and others), according to the subject or process you're proposing.
  - The VP of Development (DRI) ([@clefelhocz1](https://gitlab.com/clefelhocz1)), for
  final approval of the new or changed guidelines.
- The [Technical Writer assigned to dev guidelines](https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments-to-development-guidelines),
  to review the content for consistency and adherence to documentation guidelines.

## UX and Frontend guides

- [GitLab Design System](https://design.gitlab.com/) for building GitLab with existing CSS styles and elements
- [Frontend guidelines](fe_guide/index.md)
- [Emoji guide](fe_guide/emojis.md)

## Backend guides

- [GitLab utilities](utilities.md)
- [Issuable-like Rails models](issuable-like-models.md)
- [Logging](logging.md)
- [API style guide](api_styleguide.md) for contributing to the API
- [GraphQL API style guide](api_graphql_styleguide.md) for contributing to the [GraphQL API](../api/graphql/index.md)
- [Sidekiq guidelines](sidekiq_style_guide.md) for working with Sidekiq workers
- [Working with Gitaly](gitaly.md)
- [Manage feature flags](feature_flags/index.md)
- [Licensed feature availability](licensed_feature_availability.md)
- [Dealing with email/mailers](emails.md)
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
- [Test Import Project](import_project.md)
- [Elasticsearch integration docs](elasticsearch.md)
- [Working with Merge Request diffs](diffs.md)
- [Kubernetes integration guidelines](kubernetes.md)
- [Permissions](permissions.md)
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
- [Mass Inserting Models](mass_insert.md)
- [Value Stream Analytics development guide](value_stream_analytics.md)
- [Issue types vs first-class types](issue_types.md)
- [Application limits](application_limits.md)
- [Redis guidelines](redis.md)
- [Rails initializers](rails_initializers.md)
- [Code comments](code_comments.md)
- [Renaming features](renaming_features.md)
- [Windows Development on GCP](windows.md)
- [Code Intelligence](code_intelligence/index.md)
- [Approval Rules](approval_rules.md)
- [Feature categorization](feature_categorization/index.md)
- [Wikis development guide](wikis.md)
- [Newlines style guide](newlines_styleguide.md)
- [Image scaling guide](image_scaling.md)

## Performance guides

- [Instrumentation](instrumentation.md) for Ruby code running in production
  environments.
- [Performance guidelines](performance.md) for writing code, benchmarks, and
  certain patterns to avoid.
- [Merge request performance guidelines](merge_request_performance_guidelines.md)
  for ensuring merge requests do not negatively impact GitLab performance
- [Profiling](profiling.md) a URL, measuring performance using Sherlock, or
  tracking down N+1 queries using Bullet.
- [Cached queries guidelines](cached_queries.md), for tracking down N+1 queries masked by query caching, memory profiling and why should
  we avoid cached queries.

## Database guides

See [database guidelines](database/index.md).

## Integration guides

- [Jira Connect app](integrations/jira_connect.md)
- [Security Scanners](integrations/secure.md)
- [Secure Partner Integration](integrations/secure_partner_integration.md)
- [How to run Jenkins in development environment](integrations/jenkins.md)

## Testing guides

- [Testing standards and style guidelines](testing_guide/index.md)
- [Frontend testing standards and style guidelines](testing_guide/frontend_testing.md)

## Refactoring guides

- [Refactoring guidelines](refactoring_guide/index.md)

## Deprecation guides

- [Deprecation guidelines](deprecation_guidelines/index.md)

## Documentation guides

- [Writing documentation](documentation/index.md)
- [Documentation style guide](documentation/styleguide/index.md)
- [Markdown](../user/markdown.md)

## Internationalization (i18n) guides

- [Introduction](i18n/index.md)
- [Externalization](i18n/externalization.md)
- [Translation](i18n/translation.md)

## Product Analytics guides

- [Product Analytics guide](https://about.gitlab.com/handbook/product/product-analytics-guide/)
- [Usage Ping guide](product_analytics/usage_ping.md)
- [Snowplow guide](product_analytics/snowplow.md)

## Experiment guide

- [Introduction](experiment_guide/index.md)

## Build guides

- [Building a package for testing purposes](build_test_package.md)

## Compliance

- [Licensing](licensing.md) for ensuring license compliance

## Go guides

- [Go Guidelines](go_guide/index.md)

## Shell Scripting guides

- [Shell scripting standards and style guidelines](shell_scripting_guide/index.md)

## Domain-specific guides

- [CI/CD development documentation](cicd/index.md)

## Other Development guides

- [Defining relations between files using projections](projections.md)
- [Reference processing](reference_processing.md)
- [Compatibility with multiple versions of the application running at the same time](multi_version_compatibility.md)
- [Features inside `.gitlab/`](features_inside_dot_gitlab.md)

## Other GitLab Development Kit (GDK) guides

- [Run full Auto DevOps cycle in a GDK instance](https://gitlab.com/gitlab-org/gitlab-development-kit/blob/master/doc/howto/auto_devops.md)
- [Using GitLab Runner with the GDK](https://gitlab.com/gitlab-org/gitlab-development-kit/blob/master/doc/howto/runner.md)
- [Using the Web IDE terminal with the GDK](https://gitlab.com/gitlab-org/gitlab-development-kit/-/blob/master/doc/howto/web_ide_terminal_gdk_setup.md)
