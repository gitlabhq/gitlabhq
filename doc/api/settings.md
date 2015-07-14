# Application settings

This API allows you to read and modify GitLab instance application settings. 


## Get current application settings: 

```
GET /application/settings
```

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
  "twitter_sharing_enabled": true,
  "restricted_visibility_levels": [],
  "max_attachment_size": 10,
  "session_expire_delay": 10080,
  "default_project_visibility": 0,
  "default_snippet_visibility": 0,
  "restricted_signup_domains": [],
  "user_oauth_applications": true,
  "after_sign_out_path": ""
}
```

## Change application settings: 



```
PUT /application/settings
```

Parameters:

- `default_projects_limit` - project limit per user
- `signup_enabled` - enable registration
- `signin_enabled` - enable login via GitLab account
- `gravatar_enabled` - enable gravatar
- `sign_in_text` - text on login page
- `home_page_url` - redirect to this URL when not logged in
- `default_branch_protection` - determine if developers can push to master
- `twitter_sharing_enabled` - allow users to share project creation in twitter
- `restricted_visibility_levels` - restrict certain visibility levels
- `max_attachment_size` - limit attachment size
- `session_expire_delay` - session lifetime
- `default_project_visibility` - what visibility level new project receives
- `default_snippet_visibility` - what visibility level new snippet receives
- `restricted_signup_domains` - force people to use only corporate emails for signup
- `user_oauth_applications` - allow users to create oauth applicaitons
- `after_sign_out_path` - where redirect user after logout

All parameters are optional. You can send only one that you want to change.


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
  "twitter_sharing_enabled": true,
  "restricted_visibility_levels": [],
  "max_attachment_size": 10,
  "session_expire_delay": 10080,
  "default_project_visibility": 0,
  "default_snippet_visibility": 0,
  "restricted_signup_domains": [],
  "user_oauth_applications": true,
  "after_sign_out_path": ""
}
```
