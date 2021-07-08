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

This content is intended for members of the GitLab Team as well as community
contributors. Content specific to the GitLab Team should instead be included in
the [Handbook](https://about.gitlab.com/handbook/).

For information on using GitLab to work on your own software projects, see the
[GitLab user documentation](../user/index.md).

For information on working with the GitLab APIs, see the [API documentation](../api/README.md).

For information about how to install, configure, update, and upgrade your own
GitLab instance, see the [administration documentation](../administration/index.md).

## Get started

- Set up the GitLab development environment with the
  [GitLab Development Kit (GDK)](https://gitlab.com/gitlab-org/gitlab-development-kit/-/blob/main/README.md)
- [GitLab contributing guide](contributing/index.md)
  - [Issues workflow](contributing/issue_workflow.md) for more information about:
    - Issue tracker guidelines.
    - Triaging.
    - Labels.
    - Feature proposals.
    - Issue weight.
    - Regression issues.
    - Technical or UX debt.
  - [Merge requests workflow](contributing/merge_request_workflow.md) for more
    information about:
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
- [Code review guidelines](code_review.md) for reviewing code and having code
  reviewed
- [Database review guidelines](database_review.md) for reviewing
  database-related changes and complex SQL queries, and having them reviewed
- [Secure coding guidelines](secure_coding_guidelines.md)
- [Pipelines for the GitLab project](pipelines.md)

Complementary reads:

- [GitLab core team & GitLab Inc. contribution process](https://gitlab.com/gitlab-org/gitlab/-/blob/master/PROCESS.md)
- [Security process for developers](https://gitlab.com/gitlab-org/release/docs/blob/master/general/security/developer.md#security-releases-critical-non-critical-as-a-developer)
- [Guidelines for implementing Enterprise Edition features](ee_features.md)
- [Danger bot](dangerbot.md)
- [Guidelines for changelogs](changelog.md)
- [Requesting access to ChatOps on GitLab.com](chatops_on_gitlabcom.md#requesting-access) (for GitLab team members)
- [Patch release process for developers](https://gitlab.com/gitlab-org/release/docs/blob/master/general/patch/process.md#process-for-developers)
- [Adding a new service component to GitLab](adding_service_component.md)

### Development guidelines review

When you submit a change to the GitLab development guidelines, who
you ask for reviews depends on the level of change.

#### Wording, style, or link changes

Not all changes require extensive review. For example, MRs that don't change the
content's meaning or function can be reviewed, approved, and merged by any
maintainer or Technical Writer. These can include:

- Typo fixes.
- Clarifying links, such as to external programming language documentation.
- Changes to comply with the [Documentation Style Guide](documentation/index.md)
  that don't change the intent of the documentation page.

#### Specific changes

If the MR proposes changes that are limited to a particular stage, group, or team,
request a review and approval from an experienced GitLab Team Member in that
group. For example, if you're documenting a new internal API used exclusively by
a given group, request an engineering review from one of the group's members.

After the engineering review is complete, assign the MR to the
[Technical Writer associated with the stage and group](https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments)
in the modified documentation page's metadata.

If you have questions or need further input, request a review from the
Technical Writer assigned to the [Development Guidelines](https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments-to-development-guidelines).

#### Broader changes

Some changes affect more than one group. For example:

- Changes to [code review guidelines](code_review.md).
- Changes to [commit message guidelines](contributing/merge_request_workflow.md#commit-messages-guidelines).
- Changes to guidelines in [feature flags in development of GitLab](feature_flags/).
- Changes to [feature flags documentation guidelines](documentation/feature_flags.md).

In these cases, use the following workflow:

1. Request a peer review from a member of your team.
1. Request a review and approval of an Engineering Manager (EM)
   or Staff Engineer who's responsible for the area in question:

   - [Frontend](https://about.gitlab.com/handbook/engineering/frontend/)
   - [Backend](https://about.gitlab.com/handbook/engineering/)
   - [Database](https://about.gitlab.com/handbook/engineering/development/database/)
   - [User Experience (UX)](https://about.gitlab.com/handbook/engineering/ux/)
   - [Security](https://about.gitlab.com/handbook/engineering/security/)
   - [Quality](https://about.gitlab.com/handbook/engineering/quality/)
     - [Engineering Productivity](https://about.gitlab.com/handbook/engineering/quality/engineering-productivity-team/)
   - [Infrastructure](https://about.gitlab.com/handbook/engineering/infrastructure/)
   - [Technical Writing](https://about.gitlab.com/handbook/engineering/ux/technical-writing/)

   You can skip this step for MRs authored by EMs or Staff Engineers responsible
   for their area.

   If there are several affected groups, you may need approvals at the
   EM/Staff Engineer level from each affected area.

1. After completing the reviews, consult with the EM/Staff Engineer
   author / approver of the MR.

   If this is a significant change across multiple areas, request final review
   and approval from the VP of Development, the DRI for Development Guidelines,
   @clefelhocz1.

1. After all approvals are complete, assign the merge request to the
   Technical Writer for [Development Guidelines](https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments-to-development-guidelines)
   for final content review and merge. The Technical Writer may ask for
   additional approvals as previously suggested before merging the MR.

### Reviewer values

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/57293) in GitLab 14.1.

As a reviewer or as a reviewee, make sure to familiarize yourself with
the [reviewer values](https://about.gitlab.com/handbook/engineering/workflow/reviewer-values/) we strive for at GitLab.

## UX and Frontend guides

- [GitLab Design System](https://design.gitlab.com/), for building GitLab with
  existing CSS styles and elements
- [Frontend guidelines](fe_guide/index.md)
- [Emoji guide](fe_guide/emojis.md)

## Backend guides

### General

- [Directory structure](directory_structure.md)
- [GitLab utilities](utilities.md)
- [Newlines style guide](newlines_styleguide.md)
- [Logging](logging.md)
- [Dealing with email/mailers](emails.md)
- [Kubernetes integration guidelines](kubernetes.md)
- [Permissions](permissions.md)
- [Code comments](code_comments.md)
- [Windows Development on GCP](windows.md)
- [FIPS compliance](fips_compliance.md)
- [`Gemfile` guidelines](gemfile.md)

### Things to be aware of

- [Gotchas](gotchas.md) to avoid
- [Avoid modules with instance variables](module_with_instance_variables.md), if
  possible
- [Guidelines for reusing abstractions](reusing_abstractions.md)

### Rails Framework related

- [Routing](routing.md)
- [Rails initializers](rails_initializers.md)
- [Mass Inserting Models](mass_insert.md)
- [Issuable-like Rails models](issuable-like-models.md)
- [Issue types vs first-class types](issue_types.md)
- [DeclarativePolicy framework](policies.md)

### Debugging

- [Pry debugging](pry_debugging.md)
- [Sidekiq debugging](../administration/troubleshooting/sidekiq.md)

### Git specifics

- [How Git object deduplication works in GitLab](git_object_deduplication.md)
- [Git LFS](lfs.md)

### API

- [API style guide](api_styleguide.md) for contributing to the API
- [GraphQL API style guide](api_graphql_styleguide.md) for contributing to the
  [GraphQL API](../api/graphql/index.md)

### GitLab components and features

- [Developing against interacting components or features](interacting_components.md)
- [Manage feature flags](feature_flags/index.md)
- [Licensed feature availability](licensed_feature_availability.md)
- [Accessing session data](session.md)
- [How to dump production data to staging](db_dump.md)
- [Geo development](geo.md)
- [Redis guidelines](redis.md)
- [Sidekiq guidelines](sidekiq_style_guide.md) for working with Sidekiq workers
- [Working with Gitaly](gitaly.md)
- [Elasticsearch integration docs](elasticsearch.md)
- [Working with Merge Request diffs](diffs.md)
- [Approval Rules](approval_rules.md)
- [Repository mirroring](repository_mirroring.md)
- [File uploads](uploads.md)
- [Auto DevOps development guide](auto_devops.md)
- [Renaming features](renaming_features.md)
- [Code Intelligence](code_intelligence/index.md)
- [Feature categorization](feature_categorization/index.md)
- [Wikis development guide](wikis.md)
- [Image scaling guide](image_scaling.md)
- [Cascading Settings](cascading_settings.md)
- [Shell commands](shell_commands.md) in the GitLab codebase
- [Value Stream Analytics development guide](value_stream_analytics.md)
- [Application limits](application_limits.md)

### Import/Export

- [Working with the GitHub importer](github_importer.md)
- [Import/Export development documentation](import_export.md)
- [Test Import Project](import_project.md)
- [Group migration](bulk_import.md)
- [Export to CSV](export_csv.md)

## Language-specific guides

### Go guides

- [Go Guidelines](go_guide/index.md)

### Shell Scripting guides

- [Shell scripting standards and style guidelines](shell_scripting_guide/index.md)

## Performance guides

- [Instrumentation](instrumentation.md) for Ruby code running in production
  environments.
- [Performance guidelines](performance.md) for writing code, benchmarks, and
  certain patterns to avoid.
- [Merge request performance guidelines](merge_request_performance_guidelines.md)
  for ensuring merge requests do not negatively impact GitLab performance
- [Profiling](profiling.md) a URL, measuring performance using Sherlock, or
  tracking down N+1 queries using Bullet.
- [Cached queries guidelines](cached_queries.md), for tracking down N+1 queries
  masked by query caching, memory profiling and why should we avoid cached
  queries.

## Database guides

See [database guidelines](database/index.md).

## Integration guides

- [Jira Connect app](integrations/jira_connect.md)
- [Security Scanners](integrations/secure.md)
- [Secure Partner Integration](integrations/secure_partner_integration.md)
- [How to run Jenkins in development environment](integrations/jenkins.md)
- [How to run local `Codesandbox` integration for Web IDE Live Preview](integrations/codesandbox.md)

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

## Product Intelligence guides

- [Product Intelligence guide](https://about.gitlab.com/handbook/product/product-intelligence-guide/)
- [Service Ping guide](usage_ping/index.md)
- [Snowplow guide](snowplow/index.md)

## Experiment guide

- [Introduction](experiment_guide/index.md)

## Build guides

- [Building a package for testing purposes](build_test_package.md)

## Compliance

- [Licensing](licensing.md) for ensuring license compliance

## Domain-specific guides

- [CI/CD development documentation](cicd/index.md)
- [AppSec development documentation](appsec/index.md)

## Other Development guides

- [Defining relations between files using projections](projections.md)
- [Reference processing](reference_processing.md)
- [Compatibility with multiple versions of the application running at the same time](multi_version_compatibility.md)
- [Features inside `.gitlab/`](features_inside_dot_gitlab.md)
- [Dashboards for stage groups](stage_group_dashboards.md)
- [Preventing transient bugs](transient/prevention-patterns.md)

## Other GitLab Development Kit (GDK) guides

- [Run full Auto DevOps cycle in a GDK instance](https://gitlab.com/gitlab-org/gitlab-development-kit/blob/main/doc/howto/auto_devops.md)
- [Using GitLab Runner with the GDK](https://gitlab.com/gitlab-org/gitlab-development-kit/blob/main/doc/howto/runner.md)
- [Using the Web IDE terminal with the GDK](https://gitlab.com/gitlab-org/gitlab-development-kit/-/blob/main/doc/howto/web_ide_terminal_gdk_setup.md)
