## List snippets

Get a list of project snippets.

```
GET /projects/:id/snippets
```

Parameters:

+ `id` (required) - The ID of a project

## Single snippet

Get a project snippet.

```
GET /projects/:id/snippets/:snippet_id
```

Parameters:

+ `id` (required) - The ID of a project
+ `snippet_id` (required) - The ID of a project's snippet

```json
{
  "id": 1,
  "title": "test",
  "file_name": "add.rb",
  "author": {
    "id": 1,
    "username": "john_smith",
    "email": "john@example.com",
    "name": "John Smith",
    "blocked": false,
    "created_at": "2012-05-23T08:00:58Z"
  },
  "expires_at": null,
  "updated_at": "2012-06-28T10:52:04Z",
  "created_at": "2012-06-28T10:52:04Z"
}
```

## Snippet content

Get a raw project snippet.

```
GET /projects/:id/snippets/:snippet_id/raw
```

Parameters:

+ `id` (required) - The ID of a project
+ `snippet_id` (required) - The ID of a project's snippet

## New snippet

Create a new project snippet.

```
POST /projects/:id/snippets
```

Parameters:

+ `id` (required) - The ID of a project
+ `title` (required) - The title of a snippet
+ `file_name` (required) - The name of a snippet file
+ `lifetime` (optional) - The expiration date of a snippet
+ `code` (required) - The content of a snippet

Will return created snippet with status `201 Created` on success, or `404 Not found` on fail.

## Edit snippet

Update an existing project snippet.

```
PUT /projects/:id/snippets/:snippet_id
```

Parameters:

+ `id` (required) - The ID of a project
+ `snippet_id` (required) - The ID of a project's snippet
+ `title` (optional) - The title of a snippet
+ `file_name` (optional) - The name of a snippet file
+ `lifetime` (optional) - The expiration date of a snippet
+ `code` (optional) - The content of a snippet

Will return updated snippet with status `200 OK` on success, or `404 Not found` on fail.

## Delete snippet

Delete existing project snippet.

```
DELETE /projects/:id/snippets/:snippet_id
```

Parameters:

+ `id` (required) - The ID of a project
+ `snippet_id` (required) - The ID of a project's snippet

Status code `200` will be returned on success.

