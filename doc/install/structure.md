# GitLab directory structure

This is the directory structure you will end up with following the instructions in the Installation Guide.

    |-- home
    |   |-- git
    |       |-- .ssh
    |       |-- gitlab
    |       |-- gitlab-satellites
    |       |-- gitlab-shell
    |       |-- repositories


**/home/git/.ssh**

**/home/git/gitlab**
  This is where GitLab lives.

**/home/git/gitlab-satellites**
  Contains a copy of all repositories with a working tree.
  It's used for merge requests, editing files, etc.

**/home/git/repositories**
  Holds all your repositories in bare format.
  This is the place Git uses when you pull/push to your projects.

You can change them in your `config/gitlab.yml` file.
