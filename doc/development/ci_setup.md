# CI setup

This document describes what services we use for testing GitLab and GitLab CI. 

What services we currently use for testing GitLab: 

### GitLab CI at ci.gitlab.org

We use it for testing software from private server at dev.gitlab.org

### Semaphore at semaphoreapp.com

We use for testing Pull requests and builds from our mirror on github.com

### GitLab CI at gitlab-ce.githost.io

We use it for testing our repository at gitlab.com


## Table of CI usage 


| Software                              | GitLab CI (ci.gitlab.org) | GitLab CI (githost.io) | Semaphore |
|---------------------------------------|---------------------------|------------------------|-----------|
| GitLab CE @ MySQL                     | ✓                         | ✓                      |           |
| GitLab CE @ PostgreSQL                |                           |                        | ✓         |
| GitLab EE @ MySQL                     | ✓                         |                        |           |
| GitLab CI @ MySQL                     | ✓                         |                        |           |
| GitLab CI @ PostgreSQL                |                           |                        | ✓         |
| GitLab CI Runner                      | ✓                         |                        | ✓         |
| GitLab Shell                          | ✓                         |                        | ✓         |
| GitLab Shell                          | ✓                         |                        | ✓         |
