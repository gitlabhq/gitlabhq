# Migrating projects to a GitLab instance

1. [Bitbucket](import_projects_from_bitbucket.md)
2. [GitHub](import_projects_from_github.md)
3. [GitLab.com](import_projects_from_gitlab_com.md)
4. [SVN](migrating_from_svn.md)

### Note
* If you'd like to migrate from a self-hosted GitLab instance to GitLab.com, you can copy your repos by changing the remote and pushing to the new server; but issues and merge requests can't be imported.

* Repositories are imported to GitLab via HTTP. 
If the repository is too large, it can timeout. We have a soft limit of 10GB.
