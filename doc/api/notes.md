## List notes

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

### List issue notes

Get a list of issue notes.

```
GET /projects/:id/issues/:issue_id/notes
```

Parameters:

+ `id` (required) - The ID of a project
+ `issue_id` (required) - The ID of an issue

### List snippet notes

Get a list of snippet notes.

```
GET /projects/:id/snippets/:snippet_id/notes
```

Parameters:

+ `id` (required) - The ID of a project
+ `snippet_id` (required) - The ID of a snippet

## Single note

### Single wall note

Get a wall note.

```
GET /projects/:id/notes/:note_id
```

Parameters:

+ `id` (required) - The ID of a project
+ `note_id` (required) - The ID of a wall note

### Single issue note

Get an issue note.

```
GET /projects/:id/issues/:issue_id/:notes/:note_id
```

Parameters:

+ `id` (required) - The ID of a project
+ `issue_id` (required) - The ID of a project issue
+ `note_id` (required) - The ID of an issue note

### Single snippet note

Get a snippet note.

```
GET /projects/:id/issues/:snippet_id/:notes/:note_id
```

Parameters:

+ `id` (required) - The ID of a project
+ `snippet_id` (required) - The ID of a project snippet
+ `note_id` (required) - The ID of an snippet note

## New note

### New wall note

Create a new wall note.

```
POST /projects/:id/notes
```

Parameters:

+ `id` (required) - The ID of a project
+ `body` (required) - The content of a note

Will return created note with status `201 Created` on success, or `404 Not found` on fail.


### New issue note

Create a new issue note.

```
POST /projects/:id/issues/:issue_id/notes
```

Parameters:

+ `id` (required) - The ID of a project
+ `issue_id` (required) - The ID of an issue
+ `body` (required) - The content of a note

Will return created note with status `201 Created` on success, or `404 Not found` on fail.

### New snippet note

Create a new snippet note.

```
POST /projects/:id/snippets/:snippet_id/notes
```

Parameters:

+ `id` (required) - The ID of a project
+ `snippet_id` (required) - The ID of an snippet
+ `body` (required) - The content of a note

Will return created note with status `201 Created` on success, or `404 Not found` on fail.
