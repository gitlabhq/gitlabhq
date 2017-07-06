# Permissions

Users have different abilities depending on the access level they have in a
particular group or project. If a user is both in a group's project and the
project itself, the highest permission level is used.

On public and internal projects the Guest role is not enforced. All users will
be able to create issues, leave comments, and pull or download the project code.

When a member leaves the team the all assigned Issues and Merge Requests
will be unassigned automatically.

GitLab administrators receive all permissions.

To add or import a user, you can follow the [project users and members
documentation](../workflow/add-user/add-user.md).

## Project

The following table depicts the various user permission levels in a project.

| Action                                | Guest   | Reporter   | Developer   | Master   | Owner  |
|---------------------------------------|---------|------------|-------------|----------|--------|
| Create new issue                      | ✓       | ✓          | ✓           | ✓        | ✓      |
| Create confidential issue             | ✓       | ✓          | ✓           | ✓        | ✓      |
| View confidential issues              | (✓) [^1] | ✓          | ✓           | ✓        | ✓      |
| Leave comments                        | ✓       | ✓          | ✓           | ✓        | ✓      |
| See a list of jobs                    | ✓ [^2]  | ✓          | ✓           | ✓        | ✓      |
| See a job   log                       | ✓ [^2]  | ✓          | ✓           | ✓        | ✓      |
| Download and browse job artifacts     | ✓ [^2]  | ✓          | ✓           | ✓        | ✓      |
| View wiki pages                       | ✓       | ✓          | ✓           | ✓        | ✓      |
| Pull project code                     |         | ✓          | ✓           | ✓        | ✓      |
| Download project                      |         | ✓          | ✓           | ✓        | ✓      |
| Create code snippets                  |         | ✓          | ✓           | ✓        | ✓      |
| Manage issue tracker                  |         | ✓          | ✓           | ✓        | ✓      |
| Manage labels                         |         | ✓          | ✓           | ✓        | ✓      |
| See a commit status                   |         | ✓          | ✓           | ✓        | ✓      |
| See a container registry              |         | ✓          | ✓           | ✓        | ✓      |
| See environments                      |         | ✓          | ✓           | ✓        | ✓      |
| Create new environments               |         |            | ✓           | ✓        | ✓      |
| Use environment terminals             |         |            |             | ✓        | ✓      |
| Stop environments                     |         |            | ✓           | ✓        | ✓      |
| See a list of merge requests          |         | ✓          | ✓           | ✓        | ✓      |
| Manage/Accept merge requests          |         |            | ✓           | ✓        | ✓      |
| Create new merge request              |         |            | ✓           | ✓        | ✓      |
| Create new branches                   |         |            | ✓           | ✓        | ✓      |
| Push to non-protected branches        |         |            | ✓           | ✓        | ✓      |
| Force push to non-protected branches  |         |            | ✓           | ✓        | ✓      |
| Remove non-protected branches         |         |            | ✓           | ✓        | ✓      |
| Add tags                              |         |            | ✓           | ✓        | ✓      |
| Write a wiki                          |         |            | ✓           | ✓        | ✓      |
| Cancel and retry jobs                 |         |            | ✓           | ✓        | ✓      |
| Create or update commit status        |         |            | ✓           | ✓        | ✓      |
| Update a container registry           |         |            | ✓           | ✓        | ✓      |
| Remove a container registry image     |         |            | ✓           | ✓        | ✓      |
| Create new milestones                 |         |            |             | ✓        | ✓      |
| Add new team members                  |         |            |             | ✓        | ✓      |
| Push to protected branches            |         |            |             | ✓        | ✓      |
| Enable/disable branch protection      |         |            |             | ✓        | ✓      |
| Turn on/off protected branch push for devs|         |            |             | ✓        | ✓      |
| Enable/disable tag protections        |         |            |             | ✓        | ✓      |
| Rewrite/remove Git tags               |         |            |             | ✓        | ✓      |
| Edit project                          |         |            |             | ✓        | ✓      |
| Add deploy keys to project            |         |            |             | ✓        | ✓      |
| Configure project hooks               |         |            |             | ✓        | ✓      |
| Manage runners                        |         |            |             | ✓        | ✓      |
| Manage job triggers                   |         |            |             | ✓        | ✓      |
| Manage variables                      |         |            |             | ✓        | ✓      |
| Manage pages                          |         |            |             | ✓        | ✓      |
| Manage pages domains and certificates |         |            |             | ✓        | ✓      |
| Switch visibility level               |         |            |             |          | ✓      |
| Transfer project to another namespace |         |            |             |          | ✓      |
| Remove project                        |         |            |             |          | ✓      |
| Force push to protected branches [^3] |         |            |             |          |        |
| Remove protected branches [^3]        |         |            |             |          |        |
| Remove pages                          |         |            |             |          | ✓      |

## Group

Any user can remove themselves from a group, unless they are the last Owner of
the group. The following table depicts the various user permission levels in a
group.

| Action                  | Guest | Reporter | Developer | Master | Owner |
|-------------------------|-------|----------|-----------|--------|-------|
| Browse group            | ✓     | ✓        | ✓         | ✓      | ✓     |
| Edit group              |       |          |           |        | ✓     |
| Create subgroup         |       |          |           |        | ✓     |
| Create project in group |       |          |           | ✓      | ✓     |
| Manage group members    |       |          |           |        | ✓     |
| Remove group            |       |          |           |        | ✓     |
| Manage group labels     |       | ✓        | ✓         | ✓      | ✓     |

## External users

In cases where it is desired that a user has access only to some internal or
private projects, there is the option of creating **External Users**. This
feature may be useful when for example a contractor is working on a given
project and should only have access to that project.

External users can only access projects to which they are explicitly granted
access, thus hiding all other internal or private ones from them. Access can be
granted by adding the user as member to the project or group.

They will, like usual users, receive a role in the project or group with all
the abilities that are mentioned in the table above. They cannot however create
groups or projects, and they have the same access as logged out users in all
other cases.

An administrator can flag a user as external [through the API](../api/users.md)
or by checking the checkbox on the admin panel. As an administrator, navigate
to **Admin > Users** to create a new user or edit an existing one. There, you
will find the option to flag the user as external.

By default new users are not set as external users. This behavior can be changed
by an administrator under **Admin > Application Settings**.

## Auditor users

>[Introduced][ee-998] in [GitLab Enterprise Edition Premium][eep] 8.17.

Auditor users are given read-only access to all projects, groups, and other
resources on the GitLab instance.

[Read more about Auditor users.](../administration/auditor_users.md)

## Project features

Project features like wiki and issues can be hidden from users depending on
which visibility level you select on project settings.

- Disabled: disabled for everyone
- Only team members: only team members will see even if your project is public or internal
- Everyone with access: everyone can see depending on your project visibility level

## GitLab CI

GitLab CI permissions rely on the role the user has in GitLab. There are four
permission levels in total:

- admin
- master
- developer
- guest/reporter

The admin user can perform any action on GitLab CI in scope of the GitLab
instance and project. In addition, all admins can use the admin interface under
`/admin/runners`.

| Action                                | Guest, Reporter | Developer   | Master   | Admin  |
|---------------------------------------|-----------------|-------------|----------|--------|
| See commits and jobs                  | ✓               | ✓           | ✓        | ✓      |
| Retry or cancel job                   |                 | ✓           | ✓        | ✓      |
| Remove project                        |                 |             | ✓        | ✓      |
| Create project                        |                 |             | ✓        | ✓      |
| Change project configuration          |                 |             | ✓        | ✓      |
| Add specific runners                  |                 |             | ✓        | ✓      |
| Add shared runners                    |                 |             |          | ✓      |
| See events in the system              |                 |             |          | ✓      |
| Admin interface                       |                 |             |          | ✓      |

### Jobs permissions

>**Note:**
GitLab 8.12 has a completely redesigned job permissions system.
Read all about the [new model and its implications][new-mod].

This table shows granted privileges for jobs triggered by specific types of
users:

| Action                                      | Guest, Reporter | Developer   | Master   | Admin  |
|---------------------------------------------|-----------------|-------------|----------|--------|
| Run CI job                                  |                 | ✓           | ✓        | ✓      |
| Clone source and LFS from current project   |                 | ✓           | ✓        | ✓      |
| Clone source and LFS from public projects   |                 | ✓           | ✓        | ✓      |
| Clone source and LFS from internal projects |                 | ✓ [^4]      | ✓ [^4]   | ✓      |
| Clone source and LFS from private projects  |                 | ✓ [^5]      | ✓ [^5]   | ✓ [^5] |
| Push source and LFS                         |                 |             |          |        |
| Pull container images from current project  |                 | ✓           | ✓        | ✓      |
| Pull container images from public projects  |                 | ✓           | ✓        | ✓      |
| Pull container images from internal projects|                 | ✓ [^4]      | ✓ [^4]   | ✓      |
| Pull container images from private projects |                 | ✓ [^5]      | ✓ [^5]   | ✓ [^5] |
| Push container images to current project    |                 | ✓           | ✓        | ✓      |
| Push container images to other projects     |                 |             |          |        |

[^1]: Guest users can only view the confidential issues they created themselves
[^2]: If **Public pipelines** is enabled in **Project Settings > Pipelines**
[^3]: Not allowed for Guest, Reporter, Developer, Master, or Owner
[^4]: Only if user is not external one.
[^5]: Only if user is a member of the project.
[ce-18994]: https://gitlab.com/gitlab-org/gitlab-ce/issues/18994
[new-mod]: project/new_ci_build_permissions_model.md
[ee-998]: https://gitlab.com/gitlab-org/gitlab-ee/merge_requests/998
[eep]: https://about.gitlab.com/gitlab-ee/
