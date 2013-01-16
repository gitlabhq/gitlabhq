## Description of GitLab structure


### Directory structure

    |-- home
    |   |-- gitlab
    |       |-- gitlab
    |       |-- gitlab-satellites
    |   |-- git
    |       |-- repositories
    |       |-- .gitolite


gitlab
  Holds all the code of gitlab application.

gitlab-satellites
  Contains a copy of all repositories with working tree. 
  Used to automatically merge requests, edit files etc...

repositories
  Keeps all you repositories in bare format here

