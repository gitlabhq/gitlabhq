# Forks API

This API is intended to aid in the setup and configuration of
forked projects on Gitlab CI. 

__Authentication is done by GitLab user token & GitLab project token__

## Forks

### Create fork for project



```
POST /forks
```

Parameters:

    project_id (required) - The ID of a project
    project_token (requires) - Project token
    private_token(required) - User private token
    data (required) - GitLab project data (name_with_namespace, web_url, default_branch, ssh_url_to_repo)
