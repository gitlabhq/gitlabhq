---
stage: none
group: unassigned
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: Adding a new Service Component to GitLab
---

The GitLab product is made up of several service components that run as independent system processes in communication with each other. These services can be run on the same instance, or spread across different instances. A list of the existing components can be found in the [GitLab architecture overview](architecture.md).

## Integration phases

The following outline re-uses the [maturity metric](https://handbook.gitlab.com/handbook/product/ux/category-maturity/category-maturity-scorecards/) naming as an example of the various phases of integrating a component. These phases are only loosely coupled to a components actual maturity, and are intended as a guide for implementation order. For example, a component does not need to be enabled by default to be Lovable. Being enabled by default does not on its own cause a component to be Lovable.

- Proposed
  - [Proposing a new component](#proposing-a-new-component)
- Minimal
  - [Integrating a new service with GitLab](#integrating-a-new-service-with-gitlab)
  - [Handling service dependencies](#handling-service-dependencies)
- Viable
  - [Bundled with GitLab installations](#bundling-a-service-with-gitlab)
  - [End-to-end testing in GitLab QA](testing_guide/end_to_end/beginners_guide/_index.md)
  - [Release management](#release-management)
  - [Enabled on GitLab.com](feature_flags/controls.md#enabling-a-feature-for-gitlabcom)
- Complete
  - [Validated by the Reference Architecture group and scaled out recommendations made](https://handbook.gitlab.com/handbook/engineering/infrastructure/test-platform/self-managed-excellence/#reference-architectures)
- Lovable
  - Enabled by default for the majority of users

## Proposing a new component

The initial step for integrating a new component with GitLab starts with creating a [Feature proposal in the issue tracker](https://gitlab.com/gitlab-org/gitlab/-/issues/new?issuable_template=Feature%20proposal).

Identify the [product category](https://handbook.gitlab.com/handbook/product/categories/) the component falls under and assign the Engineering Manager and Product Manager responsible for that category.

The general steps for getting any GitLab feature from proposal to release can be found in the [Product development flow](https://handbook.gitlab.com/handbook/product-development-flow/).

## Integrating a new service with GitLab

Adding a new service follows the same [merge request workflow](contributing/merge_request_workflow.md) as other contributions, and must meet the same [completion criteria](contributing/merge_request_workflow.md#definition-of-done).
In addition, it needs to cover the following:

- The [architecture component list](architecture.md#component-list) has been updated to include the service.
- Features provided by the component have been accepted into the [GitLab Product Direction](https://about.gitlab.com/direction/).
- Documentation is available and the support team has been made aware of the new component.

**For services that can operate completely separate from GitLab:**

The first iteration should be to add the ability to connect and use the service as an externally installed component. Often this involves providing settings in GitLab to connect to the service, or allow connections from it. And then shipping documentation on how to install and configure the service with GitLab.

[Elasticsearch](../integration/advanced_search/elasticsearch.md#install-an-elasticsearch-or-aws-opensearch-cluster) is an example of a service that has been integrated this way. Many of the other services, including internal projects like Gitaly, started off as separately installed alternatives.

**For services that depend on the existing GitLab codebase:**

The first iteration should be opt-in, either through the `gitlab.yml` configuration or through [feature flags](feature_flags/_index.md). For these types of services it is often necessary to [bundle the service and its dependencies with GitLab](#bundling-a-service-with-gitlab) as part of the initial integration.

NOTE:
[ActionCable](https://docs.gitlab.com/omnibus/settings/actioncable.html) is an example of a service that has been added this way.

## Bundling a service with GitLab

Code shipped with GitLab needs to use a license approved by the Legal team. See the list of [existing approved licenses](https://handbook.gitlab.com/handbook/engineering/open-source/#using-open-source-software).

Notify the [Distribution team](https://handbook.gitlab.com/handbook/engineering/infrastructure/core-platform/systems/distribution/) when adding a new dependency that must be compiled. We must be able to compile the dependency on all supported platforms.

New services to be bundled with GitLab need to be available in the following environments.

**Development environment**

The first step of bundling a new service is to provide it in the development environment to engage in collaboration and feedback.

- [Include in the GDK](https://gitlab.com/gitlab-org/gitlab-development-kit)
- [Include in the self-compiled installation instructions](../install/installation.md)

**Standard install methods**

In order for a service to be bundled for end-users or GitLab.com, it needs to be included in the standard install methods:

- [Included in the Omnibus package](https://gitlab.com/gitlab-org/omnibus-gitlab)
- [Included in the GitLab Helm charts](https://gitlab.com/gitlab-org/charts/gitlab)

## Handling service dependencies

Dependencies should be kept up to date and be tracked for security updates. For the Rails codebase, the JavaScript and Ruby dependencies are
scanned for vulnerabilities using GitLab [dependency scanning](../user/application_security/dependency_scanning/_index.md).

In addition, any system dependencies used in Omnibus packages or the Cloud Native images should be added to the [dependency update automation](https://handbook.gitlab.com/handbook/engineering/infrastructure/core-platform/systems/distribution/maintenance/dependencies.io/#adding-new-dependencies).

## Release management

If the service component needs to be updated or released with the monthly GitLab release, then it should be added to the [release tools automation](https://gitlab.com/gitlab-org/release-tools). This project is maintained by the [Delivery group](https://handbook.gitlab.com/handbook/engineering/infrastructure-platforms/gitlab-delivery/delivery/).

Different levels of automation are available to include a component in GitLab monthly releases. The requirements and process for including a component in a release at these different levels are detailed in the [release documentation](https://gitlab.com/gitlab-org/release/docs/-/tree/master/components).

A list of the projects with releases managed by release tools can be found in the [release tools project directory](https://gitlab.com/gitlab-org/release-tools/-/tree/master/lib/release_tools/project).

For example, the desired version of Gitaly, GitLab Workhorse, and GitLab Shell need to be synchronized through the various release pipelines.
