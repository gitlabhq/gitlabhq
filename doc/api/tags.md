# Tags

## List project repository tags

Get a list of repository tags from a project, sorted by name in reverse alphabetical order.

```
GET /projects/:id/repository/tags
```

Parameters:

- `id` (required) - The ID of a project

```json
[
  {
    "commit": {
      "author_name": "John Smith",
      "author_email": "john@example.com",
      "authored_date": "2012-05-28T04:42:42-07:00",
      "committed_date": "2012-05-28T04:42:42-07:00",
      "committer_name": "Jack Smith",
      "committer_email": "jack@example.com",
      "id": "2695effb5807a22ff3d138d593fd856244e155e7",
      "message": "Initial commit",
      "parents_ids": [
        "2a4b78934375d7f53875269ffd4f45fd83a84ebe"
      ]
    },
    "release": {
      "tag_name": "1.0.0",
      "description": "Amazing release. Wow"
    },
    "name": "v1.0.0",
    "message": null
  }
]
```

## Create a new tag

Creates a new tag in the repository that points to the supplied ref.

```
POST /projects/:id/repository/tags
```

Parameters:

- `id` (required) - The ID of a project
- `tag_name` (required) - The name of a tag
- `ref` (required) - Create tag using commit SHA, another tag name, or branch name.
- `message` (optional) - Creates annotated tag.
- `release_description` (optional) - Add release notes to the git tag and store it in the GitLab database.

```json
{
  "commit": {
    "author_name": "John Smith",
    "author_email": "john@example.com",
    "authored_date": "2012-05-28T04:42:42-07:00",
    "committed_date": "2012-05-28T04:42:42-07:00",
    "committer_name": "Jack Smith",
    "committer_email": "jack@example.com",
    "id": "2695effb5807a22ff3d138d593fd856244e155e7",
    "message": "Initial commit",
    "parents_ids": [
      "2a4b78934375d7f53875269ffd4f45fd83a84ebe"
    ]
  },
  "release": {
    "tag_name": "1.0.0",
    "description": "Amazing release. Wow"
  },
  "name": "v1.0.0",
  "message": null
}
```
The message will be `nil` when creating a lightweight tag otherwise
it will contain the annotation.

It returns 200 if the operation succeed. In case of an error,
405 with an explaining error message is returned.


## Create a new release

Add release notes to the existing git tag. It returns 201 if the release is
created successfully. If the tag does not exist, 404 is returned. If there
already exists a release for the given tag, 409 is returned.

```
POST /projects/:id/repository/tags/:tag_name/release
```

Parameters:

- `id` (required) - The ID of a project
- `tag_name` (required) - The name of a tag
- `description` (required) - Release notes with markdown support

```json
{
  "tag_name": "1.0.0",
  "description": "Amazing release. Wow"
}
```

## Update a release

Updates the release notes of a given release. It returns 200 if the release is
successfully updated. If the tag or the release does not exist, it returns 404
with a proper error message.

```
PUT /projects/:id/repository/tags/:tag_name/release
```

Parameters:

- `id` (required) - The ID of a project
- `tag_name` (required) - The name of a tag
- `description` (required) - Release notes with markdown support

```json
{
  "tag_name": "1.0.0",
  "description": "Amazing release. Wow"
}
```