# Application settings API

These API calls allow you to read and modify GitLab instance application
settings as appear in `/admin/application_settings`. You have to be an
administrator in order to perform this action.

## Get current application settings

List the current application settings of the GitLab instance.

```
GET /application/settings
```

```bash
curl --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" https://gitlab.example.com/api/v4/application/settings
```

Example response:

```json
{
   "default_projects_limit" : 100000,
   "signup_enabled" : true,
   "id" : 1,
   "default_branch_protection" : 2,
   "restricted_visibility_levels" : [],
   "password_authentication_enabled" : true,
   "after_sign_out_path" : null,
   "max_attachment_size" : 10,
   "user_oauth_applications" : true,
   "updated_at" : "2016-01-04T15:44:55.176Z",
   "session_expire_delay" : 10080,
   "home_page_url" : null,
   "default_snippet_visibility" : "private",
   "domain_whitelist" : [],
   "domain_blacklist_enabled" : false,
   "domain_blacklist" : [],
   "created_at" : "2016-01-04T15:44:55.176Z",
   "default_project_visibility" : "private",
   "default_group_visibility" : "private",
   "gravatar_enabled" : true,
   "sign_in_text" : null,
   "container_registry_token_expire_delay": 5,
   "repository_storages": ["default"],
   "koding_enabled": false,
   "koding_url": null,
   "plantuml_enabled": false,
   "plantuml_url": null,
   "terminal_max_session_time": 0,
   "polling_interval_multiplier": 1.0,
   "rsa_key_restriction": 0,
   "dsa_key_restriction": 0,
   "ecdsa_key_restriction": 0,
   "ed25519_key_restriction": 0,
}
```

## Change application settings

```
PUT /application/settings
```

| Attribute | Type | Required | Description |
| --------- | ---- | :------: | ----------- |
| `default_projects_limit` | integer  | no | Project limit per user. Default is `100000` |
| `signup_enabled`    | boolean | no  | Enable registration. Default is `true`. |
| `password_authentication_enabled`    | boolean | no  | Enable authentication via a GitLab account password. Default is `true`. |
| `gravatar_enabled`  | boolean | no  | Enable Gravatar |
| `sign_in_text`      | string  | no  | Text on login page |
| `home_page_url`     | string  | no  | Redirect to this URL when not logged in |
| `default_branch_protection` | integer | no | Determine if developers can push to master. Can take `0` _(not protected, both developers and masters can push new commits, force push or delete the branch)_, `1` _(partially protected, developers can push new commits, but cannot force push or delete the branch, masters can do anything)_ or `2` _(fully protected, developers cannot push new commits, force push or delete the branch, masters can do anything)_ as a parameter. Default is `2`. |
| `restricted_visibility_levels` | array of strings | no | Selected levels cannot be used by non-admin users for projects or snippets. Can take `private`, `internal` and `public` as a parameter. Default is null which means there is no restriction. |
| `max_attachment_size` | integer | no | Limit attachment size in MB |
| `session_expire_delay` | integer | no | Session duration in minutes. GitLab restart is required to apply changes |
| `default_project_visibility` | string | no | What visibility level new projects receive. Can take `private`, `internal` and `public` as a parameter. Default is `private`.|
| `default_snippet_visibility` | string | no | What visibility level new snippets receive. Can take `private`, `internal` and `public` as a parameter. Default is `private`.|
| `default_group_visibility` | string | no | What visibility level new groups receive. Can take `private`, `internal` and `public` as a parameter. Default is `private`.|
| `domain_whitelist` | array of strings | no | Force people to use only corporate emails for sign-up. Default is null, meaning there is no restriction. |
| `domain_blacklist_enabled` | boolean | no | Enable/disable the `domain_blacklist` |
| `domain_blacklist` | array of strings | yes (if `domain_blacklist_enabled` is `true`) | People trying to sign-up with emails from this domain will not be allowed to do so. |
| `user_oauth_applications` | boolean | no | Allow users to register any application to use GitLab as an OAuth provider |
| `after_sign_out_path` | string | no | Where to redirect users after logout |
| `container_registry_token_expire_delay` | integer | no | Container Registry token duration in minutes |
| `repository_storages` | array of strings | no | A list of names of enabled storage paths, taken from `gitlab.yml`. New projects will be created in one of these stores, chosen at random. |
| `enabled_git_access_protocol` | string | no | Enabled protocols for Git access. Allowed values are: `ssh`, `http`, and `nil` to allow both protocols. |
| `koding_enabled` | boolean | no | Enable Koding integration. Default is `false`. |
| `koding_url` | string | yes (if `koding_enabled` is `true`) |  The Koding instance URL for integration. |
| `disabled_oauth_sign_in_sources` | Array of strings | no | Disabled OAuth sign-in sources |
| `plantuml_enabled` | boolean | no | Enable PlantUML integration. Default is `false`. |
| `plantuml_url` | string | yes (if `plantuml_enabled` is `true`) |  The PlantUML instance URL for integration. |
| `terminal_max_session_time` | integer | no | Maximum time for web terminal websocket connection (in seconds). Set to 0 for unlimited time. |
| `polling_interval_multiplier` | decimal | no | Interval multiplier used by endpoints that perform polling. Set to 0 to disable polling. |
| `rsa_key_restriction` | integer | no | The minimum allowed bit length of an uploaded RSA key. Default is `0` (no restriction). `-1` disables RSA keys.
| `dsa_key_restriction` | integer | no | The minimum allowed bit length of an uploaded DSA key. Default is `0` (no restriction). `-1` disables DSA keys.
| `ecdsa_key_restriction` | integer | no | The minimum allowed curve size (in bits) of an uploaded ECDSA key. Default is `0` (no restriction). `-1` disables ECDSA keys.
| `ed25519_key_restriction` | integer | no | The minimum allowed curve size (in bits) of an uploaded ED25519 key. Default is `0` (no restriction). `-1` disables ED25519 keys.
| `circuitbreaker_access_retries           | integer          | no                                            | The number of attempts GitLab will make to access a storage.                                                                                                                                                                                                                                                                                                                                                                                              |
| `circuitbreaker_backoff_threshold        | integer          | no                                            | The number of failures after which GitLab will start temporarily disabling access to a storage shard on a host.                                                                                                                                                                                                                                                                                                                                                                                                                                                        |
| `circuitbreaker_failure_count_threshold` | integer          | no                                            | The number of failures of after which GitLab will completely prevent access to the storage.                                                                                                                                                                                                                                                                                                                                                               |
| `circuitbreaker_failure_reset_time`      | integer          | no                                            | Time in seconds GitLab will keep storage failure information. When no failures occur during this time, the failure information is reset.                                                                                                                                                                                                                                                                                                                  |
| `circuitbreaker_failure_wait_time`       | integer          | no                                            | Time in seconds GitLab will block access to a failing storage to allow it to recover.                                                                                                                                                                                                                                                                                                                                                                     |
| `circuitbreaker_storage_timeout`         | integer          | no                                            | Seconds to wait for a storage access attempt                                                                                                                                                                                                                                                                                                                                                                                                              |

```bash
curl --request PUT --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" https://gitlab.example.com/api/v4/application/settings?signup_enabled=false&default_project_visibility=internal
```

Example response:

```json
{
  "id": 1,
  "default_projects_limit": 100000,
  "signup_enabled": true,
  "password_authentication_enabled": true,
  "gravatar_enabled": true,
  "sign_in_text": "",
  "created_at": "2015-06-12T15:51:55.432Z",
  "updated_at": "2015-06-30T13:22:42.210Z",
  "home_page_url": "",
  "default_branch_protection": 2,
  "restricted_visibility_levels": [],
  "max_attachment_size": 10,
  "session_expire_delay": 10080,
  "default_project_visibility": "internal",
  "default_snippet_visibility": "private",
  "default_group_visibility": "private",
  "domain_whitelist": [],
  "domain_blacklist_enabled" : false,
  "domain_blacklist" : [],
  "user_oauth_applications": true,
  "after_sign_out_path": "",
  "container_registry_token_expire_delay": 5,
  "repository_storages": ["default"],
  "koding_enabled": false,
  "koding_url": null,
  "plantuml_enabled": false,
  "plantuml_url": null,
  "terminal_max_session_time": 0,
  "polling_interval_multiplier": 1.0,
  "rsa_key_restriction": 0,
  "dsa_key_restriction": 0,
  "ecdsa_key_restriction": 0,
  "ed25519_key_restriction": 0,
}
```
