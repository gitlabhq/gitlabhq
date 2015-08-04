# Permissions

Users have different abilities depending on the access level they have in a particular group or project.

If a user is both in a project group and in the project itself, the highest permission level is used.

If a user is a GitLab administrator they receive all permissions.

To add or import a user, you can follow the [project users and members
documentation](doc/workflow/add-user/add-user.md).

## Project

| Action                                | Guest   | Reporter   | Developer   | Master   | Owner  |
|---------------------------------------|---------|------------|-------------|----------|--------|
| Create new issue                      | ✓       | ✓          | ✓           | ✓        | ✓      |
| Leave comments                        | ✓       | ✓          | ✓           | ✓        | ✓      |
| Pull project code                     |         | ✓          | ✓           | ✓        | ✓      |
| Download project                      |         | ✓          | ✓           | ✓        | ✓      |
| Create code snippets                  |         | ✓          | ✓           | ✓        | ✓      |
| Manage issue tracker                  |         | ✓          | ✓           | ✓        | ✓      |
| Manage labels                         |         | ✓          | ✓           | ✓        | ✓      |
| Manage merge requests                 |         |            | ✓           | ✓        | ✓      |
| Create new merge request              |         |            | ✓           | ✓        | ✓      |
| Create new branches                   |         |            | ✓           | ✓        | ✓      |
| Push to non-protected branches        |         |            | ✓           | ✓        | ✓      |
| Force push to non-protected branches  |         |            | ✓           | ✓        | ✓      |
| Remove non-protected branches         |         |            | ✓           | ✓        | ✓      |
| Add tags                              |         |            | ✓           | ✓        | ✓      |
| Write a wiki                          |         |            | ✓           | ✓        | ✓      |
| Create new milestones                 |         |            |             | ✓        | ✓      |
| Add new team members                  |         |            |             | ✓        | ✓      |
| Push to protected branches            |         |            |             | ✓        | ✓      |
| Enable/disable branch protection      |         |            |             | ✓        | ✓      |
| Turn on/off prot. branch push for devs|         |            |             | ✓        | ✓      |
| Rewrite/remove git tags               |         |            |             | ✓        | ✓      |
| Edit project                          |         |            |             | ✓        | ✓      |
| Add deploy keys to project            |         |            |             | ✓        | ✓      |
| Configure project hooks               |         |            |             | ✓        | ✓      |
| Switch visibility level               |         |            |             |          | ✓      |
| Transfer project to another namespace |         |            |             |          | ✓      |
| Remove project                        |         |            |             |          | ✓      |
| Force push to protected branches      |         |            |             |          |        |
| Remove protected branches             |         |            |             |          |        |

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
