# Authorization for Merge requests

There are two main ways to have a merge request flow with GitLab: working with protected branches in a single repository, or working with forks of an authoritative project.

## Protected branch flow

With the protected branch flow everybody works within the same GitLab project.

The project maintainers get Master access and the regular developers get Developer access.

The maintainers mark the authoritative branches as 'Protected'.

The developers push feature branches to the project and create merge requests to have their feature branches reviewed and merged into one of the protected branches.

Only users with Master access can merge changes into a protected branch.

### Advantages

- fewer projects means less clutter
- developers need to consider only one remote repository

### Disadvantages

- manual setup of protected branch required for each new project

## Forking workflow

With the forking workflow the maintainers get Master access and the regular developers get Reporter access to the authoritative repository, which prohibits them from pushing any changes to it.

Developers create forks of the authoritative project and push their feature branches to their own forks.

To get their changes into master they need to create a merge request across forks.

### Advantages

- in an appropriately configured GitLab group, new projects automatically get the required access restrictions for regular developers: fewer manual steps to configure authorization for new projects

### Disadvantages

- the project need to keep their forks up to date, which requires more advanced Git skills (managing multiple remotes)
