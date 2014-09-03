# System hooks

Your GitLab instance can perform HTTP POST requests on the following events: `project_create`, `project_destroy`, `user_add_to_team`, `user_remove_from_team`, `user_create`, `user_destroy`, `key_create` and `key_destroy`.

System hooks can be used, e.g. for logging or changing information in a LDAP server.

## Hooks request example

**Project created:**

```json
{
          "created_at": "2012-07-21T07:30:54Z",
          "event_name": "project_create",
                "name": "StoreCloud",
         "owner_email": "johnsmith@gmail.com",
          "owner_name": "John Smith",
                "path": "stormcloud",
 "path_with_namespace": "jsmith/stormcloud",
          "project_id": 74,
  "project_visibility": "private",
}
```

**Project destroyed:**

```json
{
          "created_at": "2012-07-21T07:30:58Z",
          "event_name": "project_destroy",
                "name": "Underscore",
         "owner_email": "johnsmith@gmail.com",
          "owner_name": "John Smith",
                "path": "underscore",
 "path_with_namespace": "jsmith/underscore",
          "project_id": 73,
  "project_visibility": "internal",
}
```

**New Team Member:**

```json
{
         "created_at": "2012-07-21T07:30:56Z",
         "event_name": "user_add_to_team",
     "project_access": "Master",
         "project_id": 74,
       "project_name": "StoreCloud",
       "project_path": "storecloud",
         "user_email": "johnsmith@gmail.com",
          "user_name": "John Smith",
 "project_visibility": "private",
}
```

**Team Member Removed:**

```json
{
         "created_at": "2012-07-21T07:30:56Z",
         "event_name": "user_remove_from_team",
     "project_access": "Master",
         "project_id": 74,
       "project_name": "StoreCloud",
       "project_path": "storecloud",
         "user_email": "johnsmith@gmail.com",
          "user_name": "John Smith",
 "project_visibility": "private",
}
```

**User created:**

```json
{
   "created_at": "2012-07-21T07:44:07Z",
        "email": "js@gitlabhq.com",
   "event_name": "user_create",
         "name": "John Smith",
      "user_id": 41
}
```

**User removed:**

```json
{
   "created_at": "2012-07-21T07:44:07Z",
        "email": "js@gitlabhq.com",
   "event_name": "user_destroy",
         "name": "John Smith",
      "user_id": 41
}
```

**Key added**

```json
{
    "event_name": "key_create",
    "created_at": "2014-08-18 18:45:16 UTC",
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
      "username": "root",
           "key": "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC58FwqHUbebw2SdT7SP4FxZ0w+lAO/erhy2ylhlcW/tZ3GY3mBu9VeeiSGoGz8hCx80Zrz+aQv28xfFfKlC8XQFpCWwsnWnQqO2Lv9bS8V1fIHgMxOHIt5Vs+9CAWGCCvUOAurjsUDoE2ALIXLDMKnJxcxD13XjWdK54j6ZXDB4syLF0C2PnAQSVY9X7MfCYwtuFmhQhKaBussAXpaVMRHltie3UYSBUUuZaB3J4cg/7TxlmxcNd+ppPRIpSZAB0NI6aOnqoBCpimscO/VpQRJMVLr3XiSYeT6HBiDXWHnIVPfQc03OGcaFqOit6p8lYKMaP/iUQLm+pgpZqrXZ9vB john@localhost",
            "id": 4
}
```
