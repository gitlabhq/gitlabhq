# Permissions

Users have different abilities depending on the access level they have in a particular group or project.

If a user is both in a project group and in the project itself, the highest permission level is used.

If a user is a GitLab administrator they receive all permissions.

On public and internal projects the Guest role is not enforced.
All users will be able to create issues, leave comments, and pull or download the project code.

To add or import a user, you can follow the [project users and members
documentation](../workflow/add-user/add-user.md).

## Project

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
| Manage merge requests                 |         |            | ✓           | ✓        | ✓      |
| Create new merge request              |         |            | ✓           | ✓        | ✓      |
| Create new branches                   |         |            | ✓           | ✓        | ✓      |
| Push to non-protected branches        |         |            | ✓           | ✓        | ✓      |
| Force push to non-protected branches  |         |            | ✓           | ✓        | ✓      |
| Remove non-protected branches         |         |            | ✓           | ✓        | ✓      |
| Add tags                              |         |            | ✓           | ✓        | ✓      |
| Write a wiki                          |         |            | ✓           | ✓        | ✓      |
| Cancel and retry builds               |         |            | ✓           | ✓        | ✓      |
| Create or update commit status        |         |            | ✓           | ✓        | ✓      |
| Create new milestones                 |         |            |             | ✓        | ✓      |
| Add new team members                  |         |            |             | ✓        | ✓      |
| Push to protected branches            |         |            |             | ✓        | ✓      |
| Enable/disable branch protection      |         |            |             | ✓        | ✓      |
| Turn on/off prot. branch push for devs|         |            |             | ✓        | ✓      |
| Rewrite/remove git tags               |         |            |             | ✓        | ✓      |
| Edit project                          |         |            |             | ✓        | ✓      |
| Add deploy keys to project            |         |            |             | ✓        | ✓      |
| Configure project hooks               |         |            |             | ✓        | ✓      |
| Manage runners                        |         |            |             | ✓        | ✓      |
| Manage build triggers                 |         |            |             | ✓        | ✓      |
| Manage variables                      |         |            |             | ✓        | ✓      |
| Switch visibility level               |         |            |             |          | ✓      |
| Transfer project to another namespace |         |            |             |          | ✓      |
| Remove project                        |         |            |             |          | ✓      |
| Force push to protected branches      |         |            |             |          |        |
| Remove protected branches             |         |            |             |          |        |

[^1]: If **Allow guest to access builds** is enabled in CI settings

## Group

In order for a group to appear as public and be browsable, it must contain at
least one public project.

Any user can remove themselves from a group, unless they are the last Owner of the group.

| Action                  | Guest | Reporter | Developer | Master | Owner |
|-------------------------|-------|----------|-----------|--------|-------|
| Browse group            | ✓     | ✓        | ✓         | ✓      | ✓     |
| Edit group              |       |          |           |        | ✓     |
| Create project in group |       |          |           | ✓      | ✓     |
| Manage group members    |       |          |           |        | ✓     |
| Remove group            |       |          |           |        | ✓     |

## External Users

In cases where it is desired that a user has access to some internal or private projects, but others
should remain hidden from this user, there is the option of creating `External Users`.
An administrator can flag a user as external through the API or by checking the checkbox on the admin panel.

In the case of a new user: navigate to the **Admin** area and click the **New User** button. If you would like to
edit a user, go to the user list on the **Admin** area and click the **Edit** button.

External users can only access projects to which they are explicitly granted access, thus hiding all internal projects.
Access can be granted by adding the users as member to the project or by including this user in a group. External users will, like usual users, receive
a role in the project or group with all the abilities that are mentioned in the table above.

External users cannot create groups or projects, and have the same access as logged out users in all other cases. This feature may be
useful when for example a contractor is working on a given project and should only access the given project and public
projects.
