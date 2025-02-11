---
stage: Foundations
group: Import and Integrate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: System hooks
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab Self-Managed

System hooks (not to be confused with [server hooks](server_hooks.md) or [file hooks](file_hooks.md)) perform HTTP POST
requests and are triggered on the following events:

- `group_create`
- `group_destroy`
- `group_rename`
- `key_create`
- `key_destroy`
- `project_create`
- `project_destroy`
- `project_rename`
- `project_transfer`
- `project_update`
- `repository_update`
- `user_access_request_revoked_for_group`
- `user_access_request_revoked_for_project`
- `user_access_request_to_group`
- `user_access_request_to_project`
- `user_add_to_group`
- `user_add_to_team`
- `user_create`
- `user_destroy`
- `user_failed_login`
- `user_remove_from_group`
- `user_remove_from_team`
- `user_rename`
- `user_update_for_group`
- `user_update_for_team`

The triggers for most of these are self-explanatory, but `project_update` and `project_rename` require clarification:

- `project_update` triggers when an attribute of a project is changed (including name, description, and tags)
  **except** when the `path` attribute is also changed.
- `project_rename` triggers when an attribute of a project (including `path`) is changed. If you only care about the
  repository URL, just listen for `project_rename`.

`user_failed_login` is sent whenever a **blocked** user attempts to sign in and is denied access.

As an example, use system hooks for logging or changing information in an LDAP server.

You can also enable triggers for other events, such as push events, and disable the `repository_update` event
when you create a system hook.

NOTE:
For push and tag events, the same structure and deprecations are followed as [project and group webhooks](../user/project/integrations/webhooks.md). However, commits are never displayed.

## Create a system hook

> - **Name** and **Description** [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/141977) in GitLab 16.9.

To create a system hook:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **System hooks**.
1. Select **Add new webhook**.
1. In **URL**, enter the URL of the webhook endpoint.
   The URL must be percent-encoded if it contains one or more special characters.
1. Optional. In **Name**, enter the name of the webhook.
1. Optional. In **Description**, enter the description of the webhook.
1. Optional. In **Secret token**, enter the secret token to validate requests.

   The token is sent with the webhook request in the `X-Gitlab-Token` HTTP header.
   Your webhook endpoint can check the token to verify the request is legitimate.

1. In the **Trigger** section, select the checkbox for each GitLab
   [event](../user/project/integrations/webhook_events.md) you want to trigger the webhook.
1. Optional. Clear the **Enable SSL verification** checkbox
   to disable [SSL verification](../user/project/integrations/_index.md#ssl-verification).
1. Select **Add system hook**.

## Hooks request example

**Request header**:

```plaintext
X-Gitlab-Event: System Hook
```

**Project created:**

```json
{
            "created_at": "2012-07-21T07:30:54Z",
            "updated_at": "2012-07-21T07:38:22Z",
            "event_name": "project_create",
                  "name": "StoreCloud",
           "owner_email": "johnsmith@example.com",
            "owner_name": "John Smith",
                "owners": [{
                           "name": "John",
                           "email": "user1@example.com"
                          }],
                  "path": "storecloud",
   "path_with_namespace": "jsmith/storecloud",
            "project_id": 74,
 "project_namespace_id" : 23,
    "project_visibility": "private"
}
```

**Project destroyed:**

```json
{
            "created_at": "2012-07-21T07:30:58Z",
            "updated_at": "2012-07-21T07:38:22Z",
            "event_name": "project_destroy",
                  "name": "Underscore",
           "owner_email": "johnsmith@example.com",
            "owner_name": "John Smith",
                "owners": [{
                           "name": "John",
                           "email": "user1@example.com"
                          }],
                  "path": "underscore",
   "path_with_namespace": "jsmith/underscore",
            "project_id": 73,
 "project_namespace_id" : 23,
    "project_visibility": "internal"
}
```

**Project renamed:**

```json
{
               "created_at": "2012-07-21T07:30:58Z",
               "updated_at": "2012-07-21T07:38:22Z",
               "event_name": "project_rename",
                     "name": "Underscore",
                     "path": "underscore",
      "path_with_namespace": "jsmith/underscore",
               "project_id": 73,
               "owner_name": "John Smith",
              "owner_email": "johnsmith@example.com",
                   "owners": [{
                              "name": "John",
                              "email": "user1@example.com"
                             }],
    "project_namespace_id" : 23,
       "project_visibility": "internal",
  "old_path_with_namespace": "jsmith/overscore"
}
```

`project_rename` is not triggered if the namespace changes.
Refer to `group_rename` and `user_rename` for that case.

**Project transferred:**

```json
{
               "created_at": "2012-07-21T07:30:58Z",
               "updated_at": "2012-07-21T07:38:22Z",
               "event_name": "project_transfer",
                     "name": "Underscore",
                     "path": "underscore",
      "path_with_namespace": "scores/underscore",
               "project_id": 73,
               "owner_name": "John Smith",
              "owner_email": "johnsmith@example.com",
                   "owners": [{
                              "name": "John",
                              "email": "user1@example.com"
                             }],
    "project_namespace_id" : 23,
       "project_visibility": "internal",
  "old_path_with_namespace": "jsmith/overscore"
}
```

**Project updated:**

```json
{
            "created_at": "2012-07-21T07:30:54Z",
            "updated_at": "2012-07-21T07:38:22Z",
            "event_name": "project_update",
                  "name": "StoreCloud",
           "owner_email": "johnsmith@example.com",
            "owner_name": "John Smith",
                "owners": [{
                           "name": "John",
                           "email": "user1@example.com"
                          }],
                  "path": "storecloud",
   "path_with_namespace": "jsmith/storecloud",
            "project_id": 74,
 "project_namespace_id" : 23,
    "project_visibility": "private"
}
```

**Access request for group removed:**

```json
{
    "created_at": "2012-07-21T07:30:56Z",
    "updated_at": "2012-07-21T07:38:22Z",
    "event_name": "user_access_request_revoked_for_group",
  "group_access": "Maintainer",
      "group_id": 78,
    "group_name": "StoreCloud",
    "group_path": "storecloud",
    "user_email": "johnsmith@example.com",
     "user_name": "John Smith",
 "user_username": "johnsmith",
       "user_id": 41
}
```

**Access request for project removed:**

```json
{
                  "created_at": "2012-07-21T07:30:56Z",
                  "updated_at": "2012-07-21T07:38:22Z",
                  "event_name": "user_access_request_revoked_for_project",
                "access_level": "Maintainer",
                  "project_id": 74,
                "project_name": "StoreCloud",
                "project_path": "storecloud",
 "project_path_with_namespace": "jsmith/storecloud",
                  "user_email": "johnsmith@example.com",
                   "user_name": "John Smith",
               "user_username": "johnsmith",
                     "user_id": 41,
          "project_visibility": "private"
}
```

**Access request for group created:**

```json
{
    "created_at": "2012-07-21T07:30:56Z",
    "updated_at": "2012-07-21T07:38:22Z",
    "event_name": "user_access_request_to_group",
  "group_access": "Maintainer",
      "group_id": 78,
    "group_name": "StoreCloud",
    "group_path": "storecloud",
    "user_email": "johnsmith@example.com",
     "user_name": "John Smith",
 "user_username": "johnsmith",
       "user_id": 41
}
```

**Access request for project created:**

```json
{
                  "created_at": "2012-07-21T07:30:56Z",
                  "updated_at": "2012-07-21T07:38:22Z",
                  "event_name": "user_access_request_to_project",
                "access_level": "Maintainer",
                  "project_id": 74,
                "project_name": "StoreCloud",
                "project_path": "storecloud",
 "project_path_with_namespace": "jsmith/storecloud",
                  "user_email": "johnsmith@example.com",
                   "user_name": "John Smith",
               "user_username": "johnsmith",
                     "user_id": 41,
          "project_visibility": "private"
}
```

**New Team Member:**

```json
{
                  "created_at": "2012-07-21T07:30:56Z",
                  "updated_at": "2012-07-21T07:38:22Z",
                  "event_name": "user_add_to_team",
                "access_level": "Maintainer",
                  "project_id": 74,
                "project_name": "StoreCloud",
                "project_path": "storecloud",
 "project_path_with_namespace": "jsmith/storecloud",
                  "user_email": "johnsmith@example.com",
                   "user_name": "John Smith",
               "user_username": "johnsmith",
                     "user_id": 41,
          "project_visibility": "private"
}
```

**Team Member Removed:**

```json
{
                  "created_at": "2012-07-21T07:30:56Z",
                  "updated_at": "2012-07-21T07:38:22Z",
                  "event_name": "user_remove_from_team",
                "access_level": "Maintainer",
                  "project_id": 74,
                "project_name": "StoreCloud",
                "project_path": "storecloud",
 "project_path_with_namespace": "jsmith/storecloud",
                  "user_email": "johnsmith@example.com",
                   "user_name": "John Smith",
               "user_username": "johnsmith",
                     "user_id": 41,
          "project_visibility": "private"
}
```

**Team Member Updated:**

```json
{
                  "created_at": "2012-07-21T07:30:56Z",
                  "updated_at": "2012-07-21T07:38:22Z",
                  "event_name": "user_update_for_team",
                "access_level": "Maintainer",
                  "project_id": 74,
                "project_name": "StoreCloud",
                "project_path": "storecloud",
 "project_path_with_namespace": "jsmith/storecloud",
                  "user_email": "johnsmith@example.com",
                   "user_name": "John Smith",
               "user_username": "johnsmith",
                     "user_id": 41,
          "project_visibility": "private"
}
```

**User created:**

```json
{
   "created_at": "2012-07-21T07:44:07Z",
   "updated_at": "2012-07-21T07:38:22Z",
        "email": "js@gitlabhq.com",
   "event_name": "user_create",
         "name": "John Smith",
     "username": "js",
      "user_id": 41
}
```

**User removed:**

```json
{
   "created_at": "2012-07-21T07:44:07Z",
   "updated_at": "2012-07-21T07:38:22Z",
        "email": "js@gitlabhq.com",
   "event_name": "user_destroy",
         "name": "John Smith",
     "username": "js",
      "user_id": 41
}
```

**User failed login:**

```json
{
  "event_name": "user_failed_login",
  "created_at": "2017-10-03T06:08:48Z",
  "updated_at": "2018-01-15T04:52:06Z",
        "name": "John Smith",
       "email": "user4@example.com",
     "user_id": 26,
    "username": "user4",
       "state": "blocked"
}
```

If the user is blocked through LDAP, `state` is `ldap_blocked`.

**User renamed:**

```json
{
    "event_name": "user_rename",
    "created_at": "2017-11-01T11:21:04Z",
    "updated_at": "2017-11-01T14:04:47Z",
          "name": "new-name",
         "email": "best-email@example.tld",
       "user_id": 58,
      "username": "new-exciting-name",
  "old_username": "old-boring-name"
}
```

**Key added**

```json
{
    "event_name": "key_create",
    "created_at": "2014-08-18 18:45:16 UTC",
    "updated_at": "2012-07-21T07:38:22Z",
      "username": "root",
           "key": "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC58FwqHUbebw2SdT7SP4FxZ0w+lAO/erhy2ylhlcW/tZ3GY3mBu9VeeiSGoGz8hCx80Zrz+aQv28xfFfKlC8XQFpCWwsnWnQqO2Lv9bS8V1fIHgMxOHIt5Vs+9CAWGCCvUOAurjsUDoE2ALIXLDMKnJxcxD13XjWdK54j6ZXDB4syLF0C2PnAQSVY9X7MfCYwtuFmhQhKaBussAXpaVMRHltie3UYSBUUuZaB3J4cg/7TxlmxcNd+ppPRIpSZAB0NI6aOnqoBCpimscO/VpQRJMVLr3XiSYeT6HBiDXWHnIVPfQc03OGcaFqOit6p8lYKMaP/iUQLm+pgpZqrXZ9vB john@localhost",
           "id": 4
}
```

**Key removed**

```json
{
    "event_name": "key_destroy",
    "created_at": "2014-08-18 18:45:16 UTC",
    "updated_at": "2012-07-21T07:38:22Z",
      "username": "root",
           "key": "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC58FwqHUbebw2SdT7SP4FxZ0w+lAO/erhy2ylhlcW/tZ3GY3mBu9VeeiSGoGz8hCx80Zrz+aQv28xfFfKlC8XQFpCWwsnWnQqO2Lv9bS8V1fIHgMxOHIt5Vs+9CAWGCCvUOAurjsUDoE2ALIXLDMKnJxcxD13XjWdK54j6ZXDB4syLF0C2PnAQSVY9X7MfCYwtuFmhQhKaBussAXpaVMRHltie3UYSBUUuZaB3J4cg/7TxlmxcNd+ppPRIpSZAB0NI6aOnqoBCpimscO/VpQRJMVLr3XiSYeT6HBiDXWHnIVPfQc03OGcaFqOit6p8lYKMaP/iUQLm+pgpZqrXZ9vB john@localhost",
            "id": 4
}
```

**Group created:**

```json
{
   "created_at": "2012-07-21T07:30:54Z",
   "updated_at": "2012-07-21T07:38:22Z",
   "event_name": "group_create",
         "name": "StoreCloud",
         "path": "storecloud",
     "group_id": 78
}
```

**Group removed:**

```json
{
   "created_at": "2012-07-21T07:30:54Z",
   "updated_at": "2012-07-21T07:38:22Z",
   "event_name": "group_destroy",
         "name": "StoreCloud",
         "path": "storecloud",
     "group_id": 78
}
```

**Group renamed:**

```json
{
     "event_name": "group_rename",
     "created_at": "2017-10-30T15:09:00Z",
     "updated_at": "2017-11-01T10:23:52Z",
           "name": "Better Name",
           "path": "better-name",
      "full_path": "parent-group/better-name",
       "group_id": 64,
       "old_path": "old-name",
  "old_full_path": "parent-group/old-name"
}
```

**New Group Member:**

```json
{
    "created_at": "2012-07-21T07:30:56Z",
    "updated_at": "2012-07-21T07:38:22Z",
    "event_name": "user_add_to_group",
  "group_access": "Maintainer",
      "group_id": 78,
    "group_name": "StoreCloud",
    "group_path": "storecloud",
    "user_email": "johnsmith@example.com",
     "user_name": "John Smith",
 "user_username": "johnsmith",
       "user_id": 41
}
```

**Group Member Removed:**

```json
{
    "created_at": "2012-07-21T07:30:56Z",
    "updated_at": "2012-07-21T07:38:22Z",
    "event_name": "user_remove_from_group",
  "group_access": "Maintainer",
      "group_id": 78,
    "group_name": "StoreCloud",
    "group_path": "storecloud",
    "user_email": "johnsmith@example.com",
     "user_name": "John Smith",
 "user_username": "johnsmith",
       "user_id": 41
}
```

**Group Member Updated:**

```json
{
    "created_at": "2012-07-21T07:30:56Z",
    "updated_at": "2012-07-21T07:38:22Z",
    "event_name": "user_update_for_group",
  "group_access": "Maintainer",
      "group_id": 78,
    "group_name": "StoreCloud",
    "group_path": "storecloud",
    "user_email": "johnsmith@example.com",
     "user_name": "John Smith",
 "user_username": "johnsmith",
       "user_id": 41
}
```

## Push events

Triggered when you push to the repository, except when pushing tags.
It generates one event per modified branch.

**Request header**:

```plaintext
X-Gitlab-Event: System Hook
```

**Request body:**

```json
{
  "event_name": "push",
  "before": "95790bf891e76fee5e1747ab589903a6a1f80f22",
  "after": "da1560886d4f094c3e6c9ef40349f7d38b5d27d7",
  "ref": "refs/heads/master",
  "checkout_sha": "da1560886d4f094c3e6c9ef40349f7d38b5d27d7",
  "user_id": 4,
  "user_name": "John Smith",
  "user_email": "john@example.com",
  "user_avatar": "https://s.gravatar.com/avatar/d4c74594d841139328695756648b6bd6?s=8://s.gravatar.com/avatar/d4c74594d841139328695756648b6bd6?s=80",
  "project_id": 15,
  "project":{
    "name":"Diaspora",
    "description":"",
    "web_url":"http://example.com/mike/diaspora",
    "avatar_url":null,
    "git_ssh_url":"git@example.com:mike/diaspora.git",
    "git_http_url":"http://example.com/mike/diaspora.git",
    "namespace":"Mike",
    "visibility_level":0,
    "path_with_namespace":"mike/diaspora",
    "default_branch":"master",
    "homepage":"http://example.com/mike/diaspora",
    "url":"git@example.com:mike/diaspora.git",
    "ssh_url":"git@example.com:mike/diaspora.git",
    "http_url":"http://example.com/mike/diaspora.git"
  },
  "repository":{
    "name": "Diaspora",
    "url": "git@example.com:mike/diaspora.git",
    "description": "",
    "homepage": "http://example.com/mike/diaspora",
    "git_http_url":"http://example.com/mike/diaspora.git",
    "git_ssh_url":"git@example.com:mike/diaspora.git",
    "visibility_level":0
  },
  "commits": [
    {
      "id": "c5feabde2d8cd023215af4d2ceeb7a64839fc428",
      "message": "Add simple search to projects in public area",
      "timestamp": "2013-05-13T18:18:08+00:00",
      "url": "https://dev.gitlab.org/gitlab/gitlabhq/commit/c5feabde2d8cd023215af4d2ceeb7a64839fc428",
      "author": {
        "name": "Example User",
        "email": "user@example.com"
      }
    }
  ],
  "total_commits_count": 1
}
```

## Tag events

Triggered when you create (or delete) tags to the repository.
It generates one event per modified tag.

**Request header**:

```plaintext
X-Gitlab-Event: System Hook
```

**Request body:**

```json
{
  "event_name": "tag_push",
  "before": "0000000000000000000000000000000000000000",
  "after": "82b3d5ae55f7080f1e6022629cdb57bfae7cccc7",
  "ref": "refs/tags/v1.0.0",
  "checkout_sha": "5937ac0a7beb003549fc5fd26fc247adbce4a52e",
  "user_id": 1,
  "user_name": "John Smith",
  "user_avatar": "https://s.gravatar.com/avatar/d4c74594d841139328695756648b6bd6?s=8://s.gravatar.com/avatar/d4c74594d841139328695756648b6bd6?s=80",
  "project_id": 1,
  "project":{
    "name":"Example",
    "description":"",
    "web_url":"http://example.com/jsmith/example",
    "avatar_url":null,
    "git_ssh_url":"git@example.com:jsmith/example.git",
    "git_http_url":"http://example.com/jsmith/example.git",
    "namespace":"Jsmith",
    "visibility_level":0,
    "path_with_namespace":"jsmith/example",
    "default_branch":"master",
    "homepage":"http://example.com/jsmith/example",
    "url":"git@example.com:jsmith/example.git",
    "ssh_url":"git@example.com:jsmith/example.git",
    "http_url":"http://example.com/jsmith/example.git"
  },
  "repository":{
    "name": "Example",
    "url": "ssh://git@example.com/jsmith/example.git",
    "description": "",
    "homepage": "http://example.com/jsmith/example",
    "git_http_url":"http://example.com/jsmith/example.git",
    "git_ssh_url":"git@example.com:jsmith/example.git",
    "visibility_level":0
  },
  "commits": [],
  "total_commits_count": 0
}
```

## Merge request events

Triggered when a new merge request is created, an existing merge request was
updated/merged/closed or a commit is added in the source branch.

**Request header**:

```plaintext
X-Gitlab-Event: System Hook
```

```json
{
  "object_kind": "merge_request",
  "event_type": "merge_request",
  "user": {
    "id": 1,
    "name": "Administrator",
    "username": "root",
    "avatar_url": "http://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=40\u0026d=identicon",
    "email": "admin@example.com"
  },
  "project": {
    "id": 1,
    "name":"Gitlab Test",
    "description":"Aut reprehenderit ut est.",
    "web_url":"http://example.com/gitlabhq/gitlab-test",
    "avatar_url":null,
    "git_ssh_url":"git@example.com:gitlabhq/gitlab-test.git",
    "git_http_url":"http://example.com/gitlabhq/gitlab-test.git",
    "namespace":"GitlabHQ",
    "visibility_level":20,
    "path_with_namespace":"gitlabhq/gitlab-test",
    "default_branch":"master",
    "homepage":"http://example.com/gitlabhq/gitlab-test",
    "url":"http://example.com/gitlabhq/gitlab-test.git",
    "ssh_url":"git@example.com:gitlabhq/gitlab-test.git",
    "http_url":"http://example.com/gitlabhq/gitlab-test.git"
  },
  "repository": {
    "name": "Gitlab Test",
    "url": "http://example.com/gitlabhq/gitlab-test.git",
    "description": "Aut reprehenderit ut est.",
    "homepage": "http://example.com/gitlabhq/gitlab-test"
  },
  "object_attributes": {
    "id": 99,
    "target_branch": "master",
    "source_branch": "ms-viewport",
    "source_project_id": 14,
    "author_id": 51,
    "assignee_id": 6,
    "title": "MS-Viewport",
    "created_at": "2013-12-03T17:23:34Z",
    "updated_at": "2013-12-03T17:23:34Z",
    "milestone_id": null,
    "state": "opened",
    "merge_status": "unchecked",
    "target_project_id": 14,
    "iid": 1,
    "description": "",
    "source": {
      "name":"Awesome Project",
      "description":"Aut reprehenderit ut est.",
      "web_url":"http://example.com/awesome_space/awesome_project",
      "avatar_url":null,
      "git_ssh_url":"git@example.com:awesome_space/awesome_project.git",
      "git_http_url":"http://example.com/awesome_space/awesome_project.git",
      "namespace":"Awesome Space",
      "visibility_level":20,
      "path_with_namespace":"awesome_space/awesome_project",
      "default_branch":"master",
      "homepage":"http://example.com/awesome_space/awesome_project",
      "url":"http://example.com/awesome_space/awesome_project.git",
      "ssh_url":"git@example.com:awesome_space/awesome_project.git",
      "http_url":"http://example.com/awesome_space/awesome_project.git"
    },
    "target": {
      "name":"Awesome Project",
      "description":"Aut reprehenderit ut est.",
      "web_url":"http://example.com/awesome_space/awesome_project",
      "avatar_url":null,
      "git_ssh_url":"git@example.com:awesome_space/awesome_project.git",
      "git_http_url":"http://example.com/awesome_space/awesome_project.git",
      "namespace":"Awesome Space",
      "visibility_level":20,
      "path_with_namespace":"awesome_space/awesome_project",
      "default_branch":"master",
      "homepage":"http://example.com/awesome_space/awesome_project",
      "url":"http://example.com/awesome_space/awesome_project.git",
      "ssh_url":"git@example.com:awesome_space/awesome_project.git",
      "http_url":"http://example.com/awesome_space/awesome_project.git"
    },
    "last_commit": {
      "id": "da1560886d4f094c3e6c9ef40349f7d38b5d27d7",
      "message": "fixed readme",
      "timestamp": "2012-01-03T23:36:29+02:00",
      "url": "http://example.com/awesome_space/awesome_project/commits/da1560886d4f094c3e6c9ef40349f7d38b5d27d7",
      "author": {
        "name": "GitLab dev user",
        "email": "gitlabdev@dv6700.(none)"
      }
    },
    "work_in_progress": false,
    "url": "http://example.com/diaspora/merge_requests/1",
    "action": "open",
    "assignee": {
      "name": "User1",
      "username": "user1",
      "avatar_url": "http://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=40\u0026d=identicon"
    }
  },
  "labels": [{
    "id": 206,
    "title": "API",
    "color": "#ffffff",
    "project_id": 14,
    "created_at": "2013-12-03T17:15:43Z",
    "updated_at": "2013-12-03T17:15:43Z",
    "template": false,
    "description": "API related issues",
    "type": "ProjectLabel",
    "group_id": 41
  }],
  "changes": {
    "updated_by_id": {
      "previous": null,
      "current": 1
    },
    "updated_at": {
      "previous": "2017-09-15 16:50:55 UTC",
      "current":"2017-09-15 16:52:00 UTC"
    },
    "labels": {
      "previous": [{
        "id": 206,
        "title": "API",
        "color": "#ffffff",
        "project_id": 14,
        "created_at": "2013-12-03T17:15:43Z",
        "updated_at": "2013-12-03T17:15:43Z",
        "template": false,
        "description": "API related issues",
        "type": "ProjectLabel",
        "group_id": 41
      }],
      "current": [{
        "id": 205,
        "title": "Platform",
        "color": "#123123",
        "project_id": 14,
        "created_at": "2013-12-03T17:15:43Z",
        "updated_at": "2013-12-03T17:15:43Z",
        "template": false,
        "description": "Platform related issues",
        "type": "ProjectLabel",
        "group_id": 41
      }]
    }
  }
}
```

## Repository Update events

Triggered only once when you push to the repository (including tags).

**Request header**:

```plaintext
X-Gitlab-Event: System Hook
```

**Request body:**

```json
{
  "event_name": "repository_update",
  "user_id": 1,
  "user_name": "John Smith",
  "user_email": "admin@example.com",
  "user_avatar": "https://s.gravatar.com/avatar/d4c74594d841139328695756648b6bd6?s=8://s.gravatar.com/avatar/d4c74594d841139328695756648b6bd6?s=80",
  "project_id": 1,
  "project": {
    "name":"Example",
    "description":"",
    "web_url":"http://example.com/jsmith/example",
    "avatar_url":null,
    "git_ssh_url":"git@example.com:jsmith/example.git",
    "git_http_url":"http://example.com/jsmith/example.git",
    "namespace":"Jsmith",
    "visibility_level":0,
    "path_with_namespace":"jsmith/example",
    "default_branch":"master",
    "homepage":"http://example.com/jsmith/example",
    "url":"git@example.com:jsmith/example.git",
    "ssh_url":"git@example.com:jsmith/example.git",
    "http_url":"http://example.com/jsmith/example.git"
  },
  "changes": [
    {
      "before":"8205ea8d81ce0c6b90fbe8280d118cc9fdad6130",
      "after":"4045ea7a3df38697b3730a20fb73c8bed8a3e69e",
      "ref":"refs/heads/master"
    }
  ],
  "refs":["refs/heads/master"]
}
```

## Local requests in system hooks

[Requests to local network by system hooks](../security/webhooks.md) can be allowed
or blocked by an administrator.

<!-- ## Troubleshooting

Include any troubleshooting steps that you can foresee. If you know beforehand what issues
one might have when setting this up, or when something is changed, or on upgrading, it's
important to describe those, too. Think of things that may go wrong and include them here.
This is important to minimize requests for support, and to avoid doc comments with
questions that you know someone might ask.

Each scenario can be a third-level heading, for example `### Getting error message X`.
If you have none to add when creating a doc, leave this section in place
but commented out to help encourage others to add to it in the future. -->
