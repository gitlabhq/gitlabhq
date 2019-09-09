# Application statistics API

## Get current application statistics

List the current statistics of the GitLab instance. You have to be an
administrator in order to perform this action.

NOTE: **Note:**
These statistics are approximate.

```
GET /application/statistics
```

```bash
curl --header "PRIVATE-TOKEN: <your_access_token>" https://gitlab.example.com/api/v4/application/statistics
```

Example response:

```json
{
   "forks": "10",
   "issues": "76",
   "merge_requests": "27",
   "notes": "954",
   "snippets": "50",
   "ssh_keys": "10",
   "milestones": "40",
   "users": "50",
   "groups": "10",
   "projects": "20",
   "active_users": "50"
}
```
