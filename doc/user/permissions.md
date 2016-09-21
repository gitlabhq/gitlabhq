# Permissions

Users have different abilities depending on the access level they have in a
particular group or project. If a user is both in a group's project and the
project itself, the highest permission level is used.

On public and internal projects the Guest role is not enforced. All users will
be able to create issues, leave comments, and pull or download the project code.

GitLab administrators receive all permissions.

To add or import a user, you can follow the [project users and members
documentation](../workflow/add-user/add-user.md).

## Project

The following table depicts the various user permission levels in a project.

| Action                                | Guest   | Reporter   | Developer   | Master   | Owner  |
|---------------------------------------|---------|------------|-------------|----------|--------|
| Create new issue                      | ✓       | ✓          | ✓           | ✓        | ✓      |
| Leave comments                        | ✓       | ✓          | ✓           | ✓        | ✓      |
| See a list of builds                  | ✓ [^1]  | ✓          | ✓           | ✓        | ✓      |
| See a build log                       | ✓ [^1]  | ✓          | ✓           | ✓        | ✓      |
| Download and browse build artifacts   | ✓ [^1]  | ✓          | ✓           | ✓        | ✓      |
| Pull project code                     |         | ✓          | ✓           | ✓        | ✓      |
| Download project                      |         | ✓          | ✓           | ✓        | ✓      |
| Create code snippets                  |         | ✓          | ✓           | ✓        | ✓      |
| Manage issue tracker                  |         | ✓          | ✓           | ✓        | ✓      |
| Manage labels                         |         | ✓          | ✓           | ✓        | ✓      |
| See a commit status                   |         | ✓          | ✓           | ✓        | ✓      |
| See a container registry              |         | ✓          | ✓           | ✓        | ✓      |
| See environments                      |         | ✓          | ✓           | ✓        | ✓      |
| Manage/Accept merge requests          |         |            | ✓           | ✓        | ✓      |
| Create new merge request              |         |            | ✓           | ✓        | ✓      |
| Create new branches                   |         |            | ✓           | ✓        | ✓      |
| Push to non-protected branches        |         |            | ✓           | ✓        | ✓      |
| Force push to non-protected branches  |         |            | ✓           | ✓        | ✓      |
| Remove non-protected branches         |         |            | ✓           | ✓        | ✓      |
| Add tags                              |         |            | ✓           | ✓        | ✓      |
| Write a wiki                          |         |            | ✓           | ✓        | ✓      |
| Cancel and retry builds               |         |            | ✓           | ✓        | ✓      |
| Create or update commit status        |         |            | ✓           | ✓        | ✓      |
| Update a container registry           |         |            | ✓           | ✓        | ✓      |
| Remove a container registry image     |         |            | ✓           | ✓        | ✓      |
| Create new environments               |         |            | ✓           | ✓        | ✓      |
| Create new milestones                 |         |            |             | ✓        | ✓      |
| Add new team members                  |         |            |             | ✓        | ✓      |
| Push to protected branches            |         |            |             | ✓        | ✓      |
| Enable/disable branch protection      |         |            |             | ✓        | ✓      |
| Turn on/off protected branch push for devs|         |            |             | ✓        | ✓      |
| Rewrite/remove Git tags               |         |            |             | ✓        | ✓      |
| Edit project                          |         |            |             | ✓        | ✓      |
| Add deploy keys to project            |         |            |             | ✓        | ✓      |
| Configure project hooks               |         |            |             | ✓        | ✓      |
| Manage runners                        |         |            |             | ✓        | ✓      |
| Manage build triggers                 |         |            |             | ✓        | ✓      |
| Manage variables                      |         |            |             | ✓        | ✓      |
| Delete environments                   |         |            |             | ✓        | ✓      |
| Switch visibility level               |         |            |             |          | ✓      |
| Transfer project to another namespace |         |            |             |          | ✓      |
| Remove project                        |         |            |             |          | ✓      |
| Force push to protected branches [^2] |         |            |             |          |        |
| Remove protected branches [^2]        |         |            |             |          |        |

[^1]: If **Public pipelines** is enabled in **Project Settings > CI/CD Pipelines**
[^2]: Not allowed for Guest, Reporter, Developer, Master, or Owner

## Group

Any user can remove themselves from a group, unless they are the last Owner of
the group. The following table depicts the various user permission levels in a
group.

| Action                  | Guest | Reporter | Developer | Master | Owner |
|-------------------------|-------|----------|-----------|--------|-------|
| Browse group            | ✓     | ✓        | ✓         | ✓      | ✓     |
| Edit group              |       |          |           |        | ✓     |
| Create project in group |       |          |           | ✓      | ✓     |
| Manage group members    |       |          |           |        | ✓     |
| Remove group            |       |          |           |        | ✓     |

## External Users

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

## Project features

Project features like wiki and issues can be hidden from users depending on
which visibility level you select on project settings.

- Disabled: disabled for everyone
- Only team members: only team members will see even if your project is public or internal
- Everyone with access: everyone can see depending on your project visibility level

## GitLab CI

GitLab CI permissions rely on the role the user has in GitLab. There are four
permission levels it total:

- admin
- master
- developer
- guest/reporter

The admin user can perform any action on GitLab CI in scope of the GitLab
instance and project. In addition, all admins can use the admin interface under
`/admin/runners`.

| Action                                | Guest, Reporter | Developer   | Master   | Admin  |
|---------------------------------------|-----------------|-------------|----------|--------|
| See commits and builds                | ✓               | ✓           | ✓        | ✓      |
| Retry or cancel build                 |                 | ✓           | ✓        | ✓      |
| Remove project                        |                 |             | ✓        | ✓      |
| Create project                        |                 |             | ✓        | ✓      |
| Change project configuration          |                 |             | ✓        | ✓      |
| Add specific runners                  |                 |             | ✓        | ✓      |
| Add shared runners                    |                 |             |          | ✓      |
| See events in the system              |                 |             |          | ✓      |
| Admin interface                       |                 |             |          | ✓      |

## Builds permissions

> Changed in GitLab 8.12.

GitLab 8.12 has completely redesigned build permission system.
You can find all discussion and all our concerns when choosing the current approach:
https://gitlab.com/gitlab-org/gitlab-ce/issues/18994

We decided that builds permission should be tightly integrated with a permission
of a user who is triggering a build.

The reason to do it like that:

- We already have permission system in place: group and project membership of users,
- We already fully know who is triggering a build (using git push, using web, executing triggers),
- We already know what user is allowed to do,
- We use the user permission for builds that are triggered by him,
- This opens us a lot of possibilities to further enforce user permissions, like:
  allowing only specific users to access runners, secure variables and environments,
- It is simple and convenient, that your build can access to everything that you have access to,
- We choose to short living unique tokens, granting access for time of the build,

Currently, any build that is triggered by the user, it's also signed with his permissions.
When user do `git push` or changes files through web (**the pusher**),
we will usually create a new Pipeline.
The Pipeline will be signed as created be the pusher.
Any build created in this pipeline will have the permissions of **the pusher**.

This allows us to make it really easy to evaluate access for all dependent projects,
container images that the pusher would have access too.
The permission is granted only for time that build is running.
The access is revoked after the build is finished.

It is important to note that we have a few types of Users:

- Administrators: CI builds created by Administrators would not have access to all GitLab projects,
  but only to projects and container images of projects that the user is a member of or that are either public, or internal,

- External users: CI builds created by external users will have access only to projects to which user has at least reporter access,
  this rules out accessing all internal projects by default,

This allows us to make the CI and permission system more trustable.
Let's consider the following scenario:

1. You are an employee of the company. Your company have number of internal tool repositories.
   You have multiple CI builds that make use of this repositories.

2. You invite a new user, a visitor, the external user. CI builds created by that user do not have access to internal repositories,
   because user also doesn't have the access from within GitLab. You as an employee have to grant explicit access for this user.
   This allows us to prevent from accidental data leakage.

### Build privileges

This table shows granted privileges for builds triggered by specific types of users:

| Action                                      | Guest, Reporter | Developer   | Master   | Admin  |
|---------------------------------------------|-----------------|-------------|----------|--------|
| Run CI build                                |                 | ✓           | ✓        | ✓      |
| Clone source and LFS from current project   |                 | ✓           | ✓        | ✓      |
| Clone source and LFS from public projects   |                 | ✓           | ✓        | ✓      |
| Clone source and LFS from internal projects |                 | ✓ [^3]      | ✓ [^3]   | ✓      |
| Clone source and LFS from private projects  |                 | ✓ [^4]      | ✓ [^4]   | ✓ [^4] |
| Push source and LFS                         |                 |             |          |        |
| Pull container images from current project  |                 | ✓           | ✓        | ✓      |
| Pull container images from public projects  |                 | ✓           | ✓        | ✓      |
| Pull container images from internal projects|                 | ✓ [^3]      | ✓ [^3]   | ✓      |
| Pull container images from private projects |                 | ✓ [^4]      | ✓ [^4]   | ✓ [^4] |
| Push container images to current project    |                 | ✓           | ✓        | ✓      |
| Push container images to other projects     |                 |             |          |        |

[^3]: Only if user is not external one.
[^4]: Only if user is a member of the project.

### Build token

The above gives a question about trustability of build token.
Unique build token is generated for each project.
This build token allows to access all projects that would be normally accessible
to the user creating that build.

We try to make sure that this token doesn't leak.
We do that by:
1. Securing all API endpoints to not expose the build token,
1. Masking the build token from build logs,
1. Allowing to use the build token only when build is running,

However, this brings a question about runners security.
To make sure that this token doesn't leak you also make sure that you configure
your runners in most secure possible way, by avoiding using this configurations:
1. Any usage of `privileged` mode if the machines are re-used is risky,
1. Using `shell` executor,

By using in-secure GitLab Runner configuration you allow the rogue developers
to steal the tokens of other builds.

### Debugging problems

It can happen that some of the users will complain that CI builds do fail for them.

It is most likely that your project access other projects sources,
and the user doesn't have the permissions.
In the build log look for information about 403 or forbidden access.

You then as Administrator can verify that the user is a member of the group or project,
and you when impersonated as the user can retry a failing build
on behalf of the user to verify that everything is correct.

### Before 8.12

In versions before 8.12 all CI builds would use runners token to checkout project sources.

The project runners token was a token that you would find in
[CI/CD Pipelines](https://gitlab.com/my-group/my-project/pipelines/settings).

The project runners token was used for registering new specific runners assigned to project
and to checkout project sources.

The project runners token could also be used to use GitLab Container Registry for that project,
allowing to pull and push Docker images from within CI build.

This token was limited to access only that project.

GitLab would create an special checkout URL:
```
https://gitlab-ci-token:<project-runners-token>/gitlab.com/gitlab-org/gitlab-ce.git
```

User could also use in his CI builds all docker related commands
to interact with GitLab Container Registry:
```
docker login -u gitlab-ci-token -p $CI_BUILD_TOKEN registry.gitlab.com
```

Using single token had multiple security implications:

- Token would be readable to anyone who has developer access to project who could run CI builds,
  allowing to register any specific runner for a project,
- Token would allow to access only project sources,
  forbidding to accessing any other projects,
- Token was not expiring, and multi-purpose: used for checking out sources,
  for registering specific runners and for accessing project's container registry with read-write permissions
