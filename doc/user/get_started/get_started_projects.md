---
stage: Data Stores
group: Tenant Scale
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Get started organizing work with projects

In GitLab, the data related to a specific development effort goes in a project.
The project serves as a central hub for collaboration, version control, and project management.

Projects provide the environment for managing and collaborating
on software development projects, from planning and coding to testing and deployment.

Project creation and maintenance is part of a larger workflow:

![Workflow](img/get_started_projects_v16_11.png)

## Step 1: Create a project

Start by creating a new project in GitLab to contain your codebase,
documentation, and related resources.

A project contains a repository. A repository contains all the files,
directories, and data related to your work.

Set the appropriate visibility level (public, internal, or private) for your project,
based on your project's security and collaboration requirements.
Configure project settings, like merge request approvals, issue tracking,
and CI/CD pipelines, to align with your development workflow.

Use description templates to maintain consistency and provide essential information
when creating issues, merge requests, or other project entities.

For more information, see:

- [Create a project](../project/index.md)
- [Manage projects](../project/working_with_projects.md)
- [Project visibility](../public_access.md)
- [Project settings](../project/settings/index.md)
- [Description templates](../project/description_templates.md)

## Step 2: Secure and control access to projects

To grant specific access rights to automated tools or external systems,
helping ensure secure integration with your GitLab projects, generate project access tokens.

If you want to securely deploy your project to external systems,
create deploy keys. These keys can grant read-only access to your repositories.

And finally, to provide temporary and limited access to
your project's repository and registry, create deploy tokens, which
help enable secure deployments and automation.

For more information, see:

- [Project access tokens](../project/settings/project_access_tokens.md)
- [Deploy keys](../project/deploy_keys/index.md)
- [Deploy tokens](../project/deploy_tokens/index.md)

## Step 3: Collaborate and share projects

You can invite multiple projects to a group, sometimes called
`sharing a project with a group`. Each project has its own repository,
issues, merge requests, and other features.
When you have multiple projects in the same group, your team members can collaborate
on specific projects while still maintaining
a high-level overview of all the work being done in the group.

To further refine who has access to which projects, you can
add subgroups to your group.

For more information, see:

- [Share projects](../project/members/share_project_with_groups.md)

## Step 4: Enhance project discoverability and recognition

To create a consistent and easily recognizable naming scheme for your projects,
use reserved project and group names. Consistent names can help make projects
more discoverable.

Use the search functionality to quickly find specific projects,
issues, merge requests, or code snippets across your GitLab instance.

Another way to make your projects more discoverable is to add badges
to your project's `README` file. Badges can display important information,
like build status, test coverage, or version number. They provide a
quick overview of your project's health and status.

And finally, topics are labels that you can assign to projects
to help you organize and find them. You can assign a topic to several projects.

For more information, see:

- [Reserved project and group names](../reserved_names.md)
- [Search](../search/index.md)
- [Badges](../project/badges.md)
- [Project topics](../project/project_topics.md)

## Step 5: Boost development efficiency and maintain code quality

Use the code intelligence features, like code navigation,
hover information, and auto-completion, to enhance your productivity and
maintain a high-quality codebase. Code intelligence is a range of tools
that help you efficiently explore, analyze, and maintain your codebase.

To quickly locate and go to specific files in your project,
use the file finder.

For more information, see:

- [Code intelligence](../project/code_intelligence.md)
- [Files](../project/repository/files/index.md)

## Step 6: Migrate projects into GitLab

When necessary, use file exports to migrate projects to GitLab.
You can migrate from other version control systems or GitLab instances.
When you migrate a frequently accessed repository to GitLab, you can continue to
access it by its original name by using a project alias.

On GitLab.com, you can transfer a project from one namespace to another,
which is essentially moving it so that another group or team can have
access or ownership.

For more information, see:

- [Migrate projects by using file exports](../project/import/index.md)
- [Project aliases](../project/working_with_projects.md#project-aliases)
- [Transfer a project to another namespace](../project/settings/migrate_projects.md)
