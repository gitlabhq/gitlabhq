# Application settings

These API calls allow you to read and modify GitLab instance application
settings as appear in `/admin/application_settings`. You have to be an
administrator in order to perform this action.

## Get current application settings

List the current application settings of the GitLab instance.

```
GET /application/settings
```

```bash
curl --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" https://gitlab.example.com/api/v3/application/settings
```

Example response:

```json
{
   "default_projects_limit" : 10,
   "signup_enabled" : true,
   "id" : 1,
   "default_branch_protection" : 2,
   "restricted_visibility_levels" : [],
   "signin_enabled" : true,
   "after_sign_out_path" : null,
   "max_attachment_size" : 10,
   "user_oauth_applications" : true,
   "updated_at" : "2016-01-04T15:44:55.176Z",
   "session_expire_delay" : 10080,
   "home_page_url" : null,
   "default_snippet_visibility" : 0,
   "domain_whitelist" : [],
   "domain_blacklist_enabled" : false,
   "domain_blacklist" : [],
   "created_at" : "2016-01-04T15:44:55.176Z",
   "default_project_visibility" : 0,
   "gravatar_enabled" : true,
   "sign_in_text" : null,
   "container_registry_token_expire_delay": 5,
   "repository_storage": "default",
   "koding_enabled": false,
   "koding_url": null
}
```

## Change application settings

```
PUT /application/settings
```

| Attribute | Type | Required | Description |
| --------- | ---- | :------: | ----------- |
| `default_projects_limit` | integer  | no | Project limit per user. Default is `10` |
| `signup_enabled`    | boolean | no  | Enable registration. Default is `true`. |
| `signin_enabled`    | boolean | no  | Enable login via a GitLab account. Default is `true`. |
| `gravatar_enabled`  | boolean | no  | Enable Gravatar |
| `sign_in_text`      | string  | no  | Text on login page |
| `home_page_url`     | string  | no  | Redirect to this URL when not logged in |
| `default_branch_protection` | integer | no | Determine if developers can push to master. Can take `0` _(not protected, both developers and masters can push new commits, force push or delete the branch)_, `1` _(partially protected, developers can push new commits, but cannot force push or delete the branch, masters can do anything)_ or `2` _(fully protected, developers cannot push new commits, force push or delete the branch, masters can do anything)_ as a parameter. Default is `2`. |
| `restricted_visibility_levels` | array of integers | no | Selected levels cannot be used by non-admin users for projects or snippets. Can take `0` _(Private)_, `1` _(Internal)_ and `2` _(Public)_ as a parameter. Default is null which means there is no restriction. |
| `max_attachment_size` | integer | no | Limit attachment size in MB |
| `session_expire_delay` | integer | no | Session duration in minutes. GitLab restart is required to apply changes |
| `default_project_visibility` | integer | no | What visibility level new projects receive. Can take `0` _(Private)_, `1` _(Internal)_ and `2` _(Public)_ as a parameter. Default is `0`.|
| `default_snippet_visibility` | integer | no | What visibility level new snippets receive. Can take `0` _(Private)_, `1` _(Internal)_ and `2` _(Public)_ as a parameter. Default is `0`.|
| `domain_whitelist` | array of strings | no | Force people to use only corporate emails for sign-up. Default is null, meaning there is no restriction. |
| `domain_blacklist_enabled` | boolean | no | Enable/disable the `domain_blacklist` |
| `domain_blacklist` | array of strings | yes (if `domain_blacklist_enabled` is `true`) | People trying to sign-up with emails from this domain will not be allowed to do so. |
| `user_oauth_applications` | boolean | no | Allow users to register any application to use GitLab as an OAuth provider |
| `after_sign_out_path` | string | no | Where to redirect users after logout |
| `container_registry_token_expire_delay` | integer | no | Container Registry token duration in minutes |
| `repository_storage` | string | no | Storage path for new projects. The value should be the name of one of the repository storage paths defined in your gitlab.yml |
| `enabled_git_access_protocol` | string | no | Enabled protocols for Git access. Allowed values are: `ssh`, `http`, and `nil` to allow both protocols. |
| `koding_enabled` | boolean | no | Enable Koding integration. Default is `false`. |
| `koding_url` | string | yes (if `koding_enabled` is `true`) |  The Koding instance URL for integration. |

```bash
curl --request PUT --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" https://gitlab.example.com/api/v3/application/settings?signup_enabled=false&default_project_visibility=1
```

Example response:

```json
{
  "id": 1,
  "default_projects_limit": 10,
  "signup_enabled": true,
  "signin_enabled": true,
  "gravatar_enabled": true,
  "sign_in_text": "",
  "created_at": "2015-06-12T15:51:55.432Z",
  "updated_at": "2015-06-30T13:22:42.210Z",
  "home_page_url": "",
  "default_branch_protection": 2,
  "restricted_visibility_levels": [],
  "max_attachment_size": 10,
  "session_expire_delay": 10080,
  "default_project_visibility": 1,
  "default_snippet_visibility": 0,
  "domain_whitelist": [],
  "domain_blacklist_enabled" : false,
  "domain_blacklist" : [],
  "user_oauth_applications": true,
  "after_sign_out_path": "",
  "container_registry_token_expire_delay": 5,
  "repository_storage": "default",
  "koding_enabled": false,
  "koding_url": null
}
```
