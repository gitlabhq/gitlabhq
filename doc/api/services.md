# Services

## GitLab CI

### Edit GitLab CI service

Set GitLab CI service for a project.

```
PUT /projects/:id/services/gitlab-ci
```

Parameters:

- `token` (required) - CI project token
- `project_url` (required) - CI project URL

### Delete GitLab CI service

Delete GitLab CI service settings for a project.

```
DELETE /projects/:id/services/gitlab-ci
```

## HipChat

### Edit HipChat service

Set HipChat service for project.

```
PUT /projects/:id/services/hipchat
```
Parameters:

- `token` (required) - HipChat token
- `room` (required) - HipChat room name

### Delete HipChat service

Delete HipChat service for a project.

```
DELETE /projects/:id/services/hipchat
```
