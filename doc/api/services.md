# Services

## GitLab CI

### Edit GitLab CI service

Set GitLab CI service for a project.

```
PUT /projects/:id/services/gitlab-ci
```

Parameters:

- `token` (required) - CI project token
- `project_url` (required) - CI project url

### Delete GitLab CI service

Delete GitLab CI service settings for a project.

```
DELETE /projects/:id/services/gitlab-ci
```

## Hipchat

### Edit Hipchat service

Set Hipchat service for project.

```
PUT /projects/:id/services/hipchat
```
Parameters:

- `token` (required) - Hipchat token
- `room` (required) - Hipchat room name

### Delete Hipchat service

Delete Hipchat service for a project.

```
DELETE /projects/:id/services/hipchat
```
