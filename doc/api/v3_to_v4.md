# V3 to V4 version

Our V4 API version is currently available as *Beta*! It means that V3
will still be supported and remain unchanged for now, but be aware that the following
changes are in V4:

### Changes

- Removed `/projects/:search` (use: `/projects?search=x`)
- `iid` filter has been removed from `projects/:id/issues`
- `projects/:id/merge_requests?iid[]=x&iid[]=y` array filter has been renamed to `iids`
- Endpoints under `projects/merge_request/:id` have been removed (use: `projects/merge_requests/:id`)
- Project snippets do not return deprecated field `expires_at`
- Endpoints under `projects/:id/keys` have been removed (use `projects/:id/deploy_keys`)
