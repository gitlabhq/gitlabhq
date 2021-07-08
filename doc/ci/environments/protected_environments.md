---
stage: Release
group: Release
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
type: concepts, howto
---

# Protected environments **(PREMIUM)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/6303) in [GitLab Premium](https://about.gitlab.com/pricing/) 11.3.

[Environments](../environments/index.md) can be used for different reasons:

- Some of them are just for testing.
- Others are for production.

Since deploy jobs can be raised by different users with different roles, it is important that
specific environments are "protected" to prevent unauthorized people from affecting them.

By default, a protected environment does one thing: it ensures that only people
with the right privileges can deploy to it, thus keeping it safe.

NOTE:
A GitLab admin is always allowed to use environments, even if they are protected.

To protect, update, or unprotect an environment, you need to have at least the
[Maintainer role](../../user/permissions.md).

## Protecting environments

To protect an environment:

1. Navigate to your project's **Settings > CI/CD**.
1. Expand the **Protected environments** section.
1. From the **Environment** dropdown menu, select the environment you want to protect.
1. In the **Allowed to Deploy** dropdown menu, select the role, users, or groups you
   want to give deploy access to. Keep in mind that:
   - There are two roles to choose from:
     - **Maintainers**: Allows access to all maintainers in the project.
     - **Developers**: Allows access to all maintainers and all developers in the project.
   - You can only select groups that are already associated with the project.
   - Only users that have at least the Developer role appear in
     the **Allowed to Deploy** dropdown menu.
1. Click the **Protect** button.

The protected environment now appears in the list of protected environments.

### Use the API to protect an environment

Alternatively, you can use the API to protect an environment:

1. Use a project with a CI that creates an environment. For example:

   ```yaml
   stages:
     - test
     - deploy

   test:
     stage: test
     script:
       - 'echo "Testing Application: ${CI_PROJECT_NAME}"'

   production:
     stage: deploy
     when: manual
     script:
       - 'echo "Deploying to ${CI_ENVIRONMENT_NAME}"'
     environment:
       name: ${CI_JOB_NAME}
   ```

1. Use the UI to [create a new group](../../user/group/index.md#create-a-group).
   For example, this group is called `protected-access-group` and has the group ID `9899826`. Note
   that the rest of the examples in these steps use this group.

   ![Group Access](img/protected_access_group_v13_6.png)

1. Use the API to add a user to the group as a reporter:

   ```shell
   $ curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" \
          --data "user_id=3222377&access_level=20" "https://gitlab.com/api/v4/groups/9899826/members"

   {"id":3222377,"name":"Sean Carroll","username":"sfcarroll","state":"active","avatar_url":"https://assets.gitlab-static.net/uploads/-/system/user/avatar/3222377/avatar.png","web_url":"https://gitlab.com/sfcarroll","access_level":20,"created_at":"2020-10-26T17:37:50.309Z","expires_at":null}
   ```

1. Use the API to add the group to the project as a reporter:

   ```shell
   $ curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" \
          --request POST "https://gitlab.com/api/v4/projects/22034114/share?group_id=9899826&group_access=20"

   {"id":1233335,"project_id":22034114,"group_id":9899826,"group_access":20,"expires_at":null}
   ```

1. Use the API to add the group with protected environment access:

   ```shell
   curl --header 'Content-Type: application/json' --request POST --data '{"name": "production", "deploy_access_levels": [{"group_id": 9899826}]}' \
        --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.com/api/v4/projects/22034114/protected_environments"
   ```

The group now has access and can be seen in the UI.

## Environment access by group membership

A user may be granted access to protected environments as part of
[group membership](../../user/group/index.md). Users with
[Reporter permissions](../../user/permissions.md), can only be granted access to
protected environments with this method.

## Deployment branch access

Users with the [Developer role](../../user/permissions.md) can be granted
access to a protected environment through any of these methods:

- As an individual contributor, through a role.
- Through a group membership.

If the user also has push or merge access to the branch deployed on production,
they have the following privileges:

- [Stopping an environment](index.md#stopping-an-environment).
- [Delete a stopped environment](index.md#delete-a-stopped-environment).
- [Create an environment terminal](index.md#web-terminals).

## Deployment-only access to protected environments

Users granted access to a protected environment, but not push or merge access
to the branch deployed to it, are only granted access to deploy the environment. An individual in a
group with the Reporter permission, or in groups added to the project with Reporter permissions,
appears in the dropdown menu for deployment-only access.

To add deployment-only access:

1. Add a group with Reporter permissions.
1. Add user(s) to the group.
1. Invite the group to be a project member.
1. Follow the steps outlined in [Protecting Environments](#protecting-environments).

Note that deployment-only access is the only possible access level for groups with [Reporter permissions](../../user/permissions.md).

## Modifying and unprotecting environments

Maintainers can:

- Update existing protected environments at any time by changing the access in the
  **Allowed to Deploy** dropdown menu.
- Unprotect a protected environment by clicking the **Unprotect** button for that environment.

After an environment is unprotected, all access entries are deleted and must
be re-entered if the environment is re-protected.

For more information, see [Deployment safety](deployment_safety.md).

## Group-level protected environments

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/215888) in [GitLab Premium](https://about.gitlab.com/pricing/) 14.0.
> - [Deployed behind a feature flag](../../user/feature_flags.md), disabled by default.
> - Disabled on GitLab.com.
> - Not recommended for production use.
> - To use in GitLab self-managed instances, ask a GitLab administrator to [enable it](#enable-or-disable-group-level-protected-environments). **(FREE SELF)**

This in-development feature might not be available for your use. There can be
[risks when enabling features still in development](../../user/feature_flags.md#risks-when-enabling-features-still-in-development).
Refer to this feature's version history for more details.

Typically, large enterprise organizations have an explicit permission boundary
between [developers and operators](https://about.gitlab.com/topics/devops/).
Developers build and test their code, and operators deploy and monitor the
application. With group-level protected environments, the permission of each
group is carefully configured in order to prevent unauthorized access and
maintain proper separation of duty. Group-level protected environments
extend the [project-level protected environments](#protecting-environments)
to the group-level.

The permissions of deployments can be illustrated in the following table:

| Environment | Developer  | Operator | Category |
|-------------|------------|----------|----------|
| Development | Allowed    | Allowed  | Lower environment  |
| Testing     | Allowed    | Allowed  | Lower environment  |
| Staging     | Disallowed | Allowed  | Higher environment |
| Production  | Disallowed | Allowed  | Higher environment |

_(Reference: [Deployment environments on Wikipedia](https://en.wikipedia.org/wiki/Deployment_environment))_

### Group-level protected environments names

Contrary to project-level protected environments, group-level protected
environments use the [deployment tier](index.md#deployment-tier-of-environments)
as their name.

A group may consist of many project environments that have unique names.
For example, Project-A has a `gprd` environment and Project-B has a `Production`
environment, so protecting a specific environment name doesn't scale well.
By using deployment tiers, both are recognized as `production` deployment tier
and are protected at the same time.

### Configure group-level memberships

In an enterprise organization, with thousands of projects under a single group,
ensuring that all of the [project-level protected environments](#protecting-environments)
are properly configured is not a scalable solution. For example, a developer
might gain privileged access to a higher environment when they are added as a
maintainer to a new project. Group-level protected environments can be a solution
in this situation.

To maximize the effectiveness of group-level protected environments,
[group-level memberships](../../user/group/index.md) must be correctly
configured:

- Operators should be assigned the [maintainer role](../../user/permissions.md)
  (or above) to the top-level group. They can maintain CI/CD configurations for
  the higher environments (such as production) in the group-level settings page,
  wnich includes group-level protected environments,
  [group-level runners](../runners/runners_scope.md#group-runners),
  [group-level clusters](../../user/group/clusters/index.md), etc. Those
  configurations are inherited to the child projects as read-only entries.
  This ensures that only operators can configure the organization-wide
  deployment ruleset.
- Developers should be assigned the [developer role](../../user/permissions.md)
  (or below) at the top-level group, or explicitly assigned to a child project
  as maintainers. They do *NOT* have access to the CI/CD configurations in the
  top-level group, so operators can ensure that the critical configuration won't
  be accidentally changed by the developers.
- For sub-groups and child projects:
  - Regarding [sub-groups](../../user/group/subgroups/index.md), if a higher
    group has configured the group-level protected environment, the lower groups
    cannot override it.
  - [Project-level protected environments](#protecting-environments) can be
    combined with the group-level setting. If both group-level and project-level
    environment configurations exist, the user must be allowed in **both**
    rulesets in order to run a deployment job.
  - Within a project or a sub-group of the top-level group, developers can be
    safely assigned the Maintainer role to tune their lower environments (such
    as `testing`).

Having this configuration in place:

- If a user is about to run a deployment job in a project and allowed to deploy
  to the environment, the deployment job proceeds.
- If a user is about to run a deployment job in a project but disallowed to
  deploy to the environment, the deployment job fails with an error message.

### Protect a group-level environment

To protect a group-level environment:

1. Make sure your environments have the correct
   [`deployment_tier`](index.md#deployment-tier-of-environments) defined in
   `gitlab-ci.yml`.
1. Configure the group-level protected environments via the
   [REST API](../../api/group_protected_environments.md).

NOTE:
Configuration [via the UI](https://gitlab.com/gitlab-org/gitlab/-/issues/325249)
is scheduled for a later release.

### Enable or disable Group-level protected environments **(FREE SELF)**

Group-level protected environments is under development and not ready for production use. It is
deployed behind a feature flag that is **disabled by default**.
[GitLab administrators with access to the GitLab Rails console](../../administration/feature_flags.md)
can enable it.

To enable it:

```ruby
Feature.enable(:group_level_protected_environments)
```

To disable it:

```ruby
Feature.disable(:group_level_protected_environments)
```

<!-- ## Troubleshooting

Include any troubleshooting steps that you can foresee. If you know beforehand what issues
one might have when setting this up, or when something is changed, or on upgrading, it's
important to describe those, too. Think of things that may go wrong and include them here.
This is important to minimize requests for support, and to avoid doc comments with
questions that you know someone might ask.

Each scenario can be a third-level heading, e.g. `### Getting error message X`.
If you have none to add when creating a doc, leave this section in place
but commented out to help encourage others to add to it in the future. -->
