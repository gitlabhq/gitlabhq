## Wall

### List project wall notes

Get a list of project wall notes.

```
GET /projects/:id/notes
```

```json
[
  {
    "id": 522,
    "body": "The solution is rather tricky",
    "author": {
      "id": 1,
      "username": "john_smith",
      "email": "john@example.com",
      "name": "John Smith",
      "blocked": false,
      "created_at": "2012-05-23T08:00:58Z"
    },
    "created_at": "2012-11-27T19:16:44Z"
  }
]
```

Parameters:

+ `id` (required) - The ID of a project


### Get single wall note

Returns a single wall note.

```
GET /projects/:id/notes/:note_id
```

Parameters:

+ `id` (required) - The ID of a project
+ `note_id` (required) - The ID of a wall note


### Create new wall note

Creates a new wall note.

```
POST /projects/:id/notes
```

Parameters:

+ `id` (required) - The ID of a project
+ `body` (required) - The content of a note


## Issues

### List project issue notes

Gets a list of all notes for a single issue.

```
GET /projects/:id/issues/:issue_id/notes
```

Parameters:

+ `id` (required) - The ID of a project
+ `issue_id` (required) - The ID of an issue


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


### Create new merge request note

Creates a new note for a single merge request.

```
POST /projects/:id/merge_requests/:merge_request_id/notes
```

Parameters:

+ `id` (required) - The ID of a project
+ `merge_request_id` (required) - The ID of a merge request
+ `body` (required) - The content of a note

