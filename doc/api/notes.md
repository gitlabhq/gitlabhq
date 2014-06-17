# Notes

Notes are comments on snippets, issues or merge requests.

## Issues

### List project issue notes

Gets a list of all notes for a single issue.

```
GET /projects/:id/issues/:issue_id/notes
```

Parameters:

+ `id` (required) - The ID of a project
+ `issue_id` (required) - The ID of an issue

```json
[
  {
    "id": 302,
    "body": "_Status changed to closed_",
    "attachment": null,
    "author": {
      "id": 1,
      "username": "pipin",
      "email": "admin@example.com",
      "name": "Pip",
      "state": "active",
      "created_at": "2013-09-30T13:46:01Z"
    },
    "created_at": "2013-10-02T09:22:45Z"
  },
  {
    "id": 305,
    "body": "Text of the comment\r\n",
    "attachment": null,
    "author": {
      "id": 1,
      "username": "pipin",
      "email": "admin@example.com",
      "name": "Pip",
      "state": "active",
      "created_at": "2013-09-30T13:46:01Z"
    },
    "created_at": "2013-10-02T09:56:03Z"
  }
]
```

### Get single issue note

Returns a single note for a specific project issue

```
GET /projects/:id/issues/:issue_id/notes/:note_id
```

Parameters:

+ `id` (required) - The ID of a project
+ `issue_id` (required) - The ID of a project issue
+ `note_id` (required) - The ID of an issue note


### Create new issue note

Creates a new note to a single project issue.

```
POST /projects/:id/issues/:issue_id/notes
```

Parameters:

+ `id` (required) - The ID of a project
+ `issue_id` (required) - The ID of an issue
+ `body` (required) - The content of a note


## Snippets

### List all snippet notes

Gets a list of all notes for a single snippet. Snippet notes are comments users can post to a snippet.

```
GET /projects/:id/snippets/:snippet_id/notes
```

Parameters:

+ `id` (required) - The ID of a project
+ `snippet_id` (required) - The ID of a project snippet


### Get single snippet note

Returns a single note for a given snippet.

```
GET /projects/:id/snippets/:snippet_id/notes/:note_id
```

Parameters:

+ `id` (required) - The ID of a project
+ `snippet_id` (required) - The ID of a project snippet
+ `note_id` (required) - The ID of an snippet note

```json
{
  "id": 52,
  "title": "Snippet",
  "file_name": "snippet.rb",
  "author": {
    "id": 1,
    "username": "pipin",
    "email": "admin@example.com",
    "name": "Pip",
    "state": "active",
    "created_at": "2013-09-30T13:46:01Z"
  },
  "expires_at": null,
  "updated_at": "2013-10-02T07:34:20Z",
  "created_at": "2013-10-02T07:34:20Z"
}
```

### Create new snippet note

Creates a new note for a single snippet. Snippet notes are comments users can post to a snippet.

```
POST /projects/:id/snippets/:snippet_id/notes
```

Parameters:

+ `id` (required) - The ID of a project
+ `snippet_id` (required) - The ID of an snippet
+ `body` (required) - The content of a note


## Merge Requests

### List all merge request notes

Gets a list of all notes for a single merge request.

```
GET /projects/:id/merge_requests/:merge_request_id/notes
```

Parameters:

+ `id` (required) - The ID of a project
+ `merge_request_id` (required) - The ID of a project merge request


### Get single merge request note

Returns a single note for a given merge request.

```
GET /projects/:id/merge_requests/:merge_request_id/notes/:note_id
```

Parameters:

+ `id` (required) - The ID of a project
+ `merge_request_id` (required) - The ID of a project merge request
+ `note_id` (required) - The ID of a merge request note

```json
{
  "id": 301,
  "body": "Comment for MR",
  "attachment": null,
  "author": {
    "id": 1,
    "username": "pipin",
    "email": "admin@example.com",
    "name": "Pip",
    "state": "active",
    "created_at": "2013-09-30T13:46:01Z"
  },
  "created_at": "2013-10-02T08:57:14Z"
}
```

### Create new merge request note

Creates a new note for a single merge request.

```
POST /projects/:id/merge_requests/:merge_request_id/notes
```

Parameters:

+ `id` (required) - The ID of a project
+ `merge_request_id` (required) - The ID of a merge request
+ `body` (required) - The content of a note

