---
stage: Package
group: Package Registry
info: For assistance with this tutorial, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments-to-other-projects-and-subjects.
title: 'Tutorial: Structure the package registry for enterprise scale'
---

As your organization grows, package management can become increasingly complex.
The GitLab package registry model offers a powerful solution for enterprise package management.
Understanding how to leverage the package registry is important to working with packages securely, simply, and at scale.

In this tutorial, you'll learn how to incorporate the GitLab package registry model into an enterprise group structure. Although the examples provided here are specific to Maven and npm packages, you can extend the concepts of this tutorial to any package supported by the GitLab package registry.

When you finish this tutorial, you'll know how to:

1. [Set up a single root or top-level group to structure your work](#create-an-enterprise-structure).
1. [Configure projects for publishing packages with clear ownership](#set-up-a-top-level-group).
1. [Set up top-level group package consumption for simplified access](#publish-packages).
1. [Add deploy tokens so your team can access your organization's packages](#add-deploy-tokens).
1. [Configure CI/CD to work with your packages securely](#use-packages-with-cicd).

## Before you begin

You'll need the following to complete this tutorial:

- An npm or Maven package.
- Familiarity with the GitLab package registry.
- A test project. You can use an existing project, or create one for this tutorial.

## Understand the GitLab package registry

Traditional package managers like JFrog Artifactory and Sonatype Nexus use a single, centralized repository to store and update your packages.
With GitLab, you manage packages directly in your group or project. This means:

- Teams publish packages to projects that store code.
- Teams consume packages from root group registries that aggregate all packages below them.
- Access control is inherited from your existing GitLab permissions.

Because your packages are stored and managed like code, you can add package management to your existing projects or groups.
This model offers several advantages:

- Clear ownership of packages alongside their source code
- Granular access control without additional configuration
- Simplified CI/CD integration
- Natural alignment with team structures
- Single URL for accessing all company packages through root group consumption

## Create an enterprise structure

Consider organizing your code under a single top-level group. For example:

```plaintext
company/ (top-level group)
├── retail-division/
│   ├── shared-libraries/    # Division-specific shared code
│   └── teams/
│       ├── checkout/        # Team publishes packages here
│       └── inventory/       # Team publishes packages here
├── banking-division/
│   ├── shared-libraries/    # Division-specific shared code
│   └── teams/
│       ├── payments/        # Team publishes packages here
│       └── fraud/           # Team publishes packages here
└── shared-platform/         # Enterprise-wide shared code
    ├── java-commons/        # Shared Java libraries
    └── ui-components/       # Shared UI components
```

In this structure, all the teams in a company publish code and packages to their own projects,
while inheriting the configurations of the top-level `company/` group.

## Set up a top-level group

You can use an existing top-level group if you have one, and you have the Owner role.

If you don't have a group, create one:

1. On the left sidebar, at the top, select **Create new** ({{< icon name="plus" >}}) and **New group**. If you've [turned on the new navigation](../../interface_redesign.md#turn-new-navigation-on-or-off), this button is in the upper-right corner.
1. In **Group name**, enter a name for the group.
1. In **Group URL**, enter a path for the group, which is used as the namespace.
1. Choose the [visibility level](../../public_access.md).
1. Optional. Fill in information to personalize your experience.
1. Select **Create group**.

This group will store the other groups and projects in your organization. If you have other projects and groups, you can
[transfer them to the new top-level group](../../group/manage.md#transfer-a-group) for management.

Before you move on, make sure you have at least:

- A top-level group.
- A project that belongs to the top-level group or one of its subgroups.

## Publish packages

To maintain clear ownership, teams should publish packages to their own package registries.
This keeps packages with their source code and ensures version history is tied to project activity.

{{< tabs >}}

{{< tab title="Maven projects" >}}

To publish Maven packages:

- Configure your `pom.xml` file to publish to the project's package registry:

  ```xml
  <!-- checkout/pom.xml -->
  <distributionManagement>
      <repository>
          <id>gitlab-maven</id>
          <url>${CI_API_V4_URL}/projects/${CI_PROJECT_ID}/packages/maven</url>
      </repository>
  </distributionManagement>
  ```

{{< /tab >}}

{{< tab title="npm projects" >}}

To publish npm packages:

- Configure your `package.json` file:

  ```json
  // ui-components/package.json
  {
    "name": "@company/ui-components",
    "publishConfig": {
      "registry": "${CI_API_V4_URL}/projects/${CI_PROJECT_ID}/packages/npm/"
    }
  }
  ```

{{< /tab >}}

{{< /tabs >}}

## Consume packages

Because your projects are organized under a single top-level group, your packages are still accessible to
the organization. Let's configure a single API endpoint for your teams to consume packages from.

{{< tabs >}}

{{< tab title="Maven projects" >}}

- Configure your `pom.xml` to access packages from the top-level group:

  ```xml
  <!-- Any project's pom.xml -->
  <repositories>
      <repository>
          <id>gitlab-maven</id>
          <url>https://gitlab.example.com/api/v4/groups/company/-/packages/maven</url>
      </repository>
  </repositories>
  ```

{{< /tab >}}

{{< tab title="npm projects" >}}

- Configure your `.npmrc` file:

  ```shell
  # Any project's .npmrc
  @company:registry=https://gitlab.example.com/api/v4/groups/company/-/packages/npm/
  ```

{{< /tab >}}

{{< /tabs >}}

This configuration automatically provides access to all packages across your organization while maintaining the benefits of project-based publishing.

## Add deploy tokens

Next, we'll add a read-only deploy token. This token provides access to the packages stored in the subgroups and projects of the organization,
so your teams can use them for development.

1. In your top-level group, on the left sidebar, select **Settings** > **Repository**.
1. Expand **Deploy tokens**.
1. Select **Add token**.
1. Complete the fields, and set the scope to `read_repository`.
1. Select **Create deploy token**.

You can add as many deploy tokens to your top-level group as you need.
Remember to rotate your tokens periodically. If you suspect a token has been exposed, revoke and replace it immediately.

## Use packages with CI/CD

When CI/CD jobs need to access the package registry, they authenticate with the predefined CI/CD variable
`CI_JOB_TOKEN`. This authentication happens automatically, so you don't need to do any extra configuration:

```yaml
publish:
  script:
    - mvn deploy  # For Maven packages
    # or
    - npm publish # For npm packages
  # CI_JOB_TOKEN provides automatic authentication
```

## Summary and next steps

Organizing your GitLab projects under one top-level group confers several benefits:

- Simplified configuration:
  - One URL for all package access
  - Consistent setup across teams
  - Easy token rotation
- Clear ownership:
  - Packages stay with their source code
  - Teams maintain control over publishing
  - Version history is tied to project activity
- Natural organization:
  - Your groups match your company structure
  - Teams can collaborate while remaining autonomous

The GitLab package registry model offers a powerful solution for enterprise package management. By combining project-based publishing with top-level group consumption,
you get the best of both worlds: clear ownership and simplified access.

This approach scales naturally with your organization while maintaining security and ease of use.
Start by implementing this model with a single team or division, and expand as you see the benefits of this integrated approach.
Remember that while this tutorial focused on Maven and npm, the same principles apply to all package types supported by GitLab.
