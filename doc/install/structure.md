# GitLab directory structure

This is the directory structure you will end up with following the instructions in the Installation Guide.

    |-- home
    |   |-- gitlab
    |       |-- .ssh
    |       |-- gitlab
    |       |-- gitlab-satellites
    |   |-- git
    |       |-- .gitolite
    |       |-- .ssh
    |       |-- bin
    |       |-- gitolite
    |       |-- repositories


**/home/gitlab/.ssh**
  Contains the Gitolite admin key GitLab uses to configure Gitolite.

**/home/gitlab/gitlab**
  This is where GitLab lives.

**/home/gitlab/gitlab-satellites**
  Contains a copy of all repositories with a working tree.
  It's used for merge requests, editing files, etc.

**/home/git/.ssh**
  Contains the SSH access configuration managed by Gitolite.

**/home/git/bin**
  Contains Gitolite executables.

**/home/git/gitolite**
  This is where Gitolite lives.

**/home/git/repositories**
  Holds all your repositories in bare format.
  This is the place Git uses when you pull/push to your projects.

You can change them in your `config/gitlab.yml` file.
