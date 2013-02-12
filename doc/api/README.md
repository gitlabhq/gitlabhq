# GitLab API

All API requests require authentication. You need to pass a `private_token` parameter by url or header. You can find or reset your private token in your profile.

If no, or an invalid, `private_token` is provided then an error message will be returned with status code 401:

```json
{
  "message": "401 Unauthorized"
}
```

API requests should be prefixed with `api` and the API version. The API version is defined in `lib/api.rb`.

Example of a valid API request:

```
GET http://example.com/api/v3/projects?private_token=QVy1PB7sTxfy4pqfZM1U
```

The API uses JSON to serialize data. You don't need to specify `.json` at the end of API URL.

#### Pagination

When listing resources you can pass the following parameters:

+ `page` (default: `1`) - page number
+ `per_page` (default: `20`, max: `100`) - number of items to list per page

## Contents

+ [Users](https://github.com/gitlabhq/gitlabhq/blob/master/doc/api/users.md)
+ [Session](https://github.com/gitlabhq/gitlabhq/blob/master/doc/api/session.md)
+ [Projects](https://github.com/gitlabhq/gitlabhq/blob/master/doc/api/projects.md)
+ [Groups](https://github.com/gitlabhq/gitlabhq/blob/master/doc/api/groups.md)
+ [Snippets](https://github.com/gitlabhq/gitlabhq/blob/master/doc/api/snippets.md)
+ [Repositories](https://github.com/gitlabhq/gitlabhq/blob/master/doc/api/repositories.md)
+ [Issues](https://github.com/gitlabhq/gitlabhq/blob/master/doc/api/issues.md)
+ [Milestones](https://github.com/gitlabhq/gitlabhq/blob/master/doc/api/milestones.md)
+ [Notes](https://github.com/gitlabhq/gitlabhq/blob/master/doc/api/notes.md)
