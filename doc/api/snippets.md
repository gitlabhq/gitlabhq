## List snippets

Get a list of project snippets.

```
GET /projects/:id/snippets
```

Parameters:

+ `id` (required) - The ID of a project

Return values:

+ `200 Ok` on success and a list of project snippets
+ `401 Unauthorized` if user is not authenticated


## Single snippet

Get a single project snippet.

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

Return values:

+ `200 Ok` on success and the project snippet
+ `401 Unauthorized` if user is not authenticated
+ `404 Not Found` if snippet ID not found


## Create new snippet

Creates a new project snippet.

```
POST /projects/:id/snippets
```

Parameters:

+ `id` (required) - The ID of a project
+ `title` (required) - The title of a snippet
+ `file_name` (required) - The name of a snippet file
+ `lifetime` (optional) - The expiration date of a snippet
+ `code` (required) - The content of a snippet

Return values:

+ `201 Created` if snippet was successfully created and the snippet as JSON payload
+ `400 Bad Request` if one of the required attributes is not given
+ `401 Unauthorized` if user is not authenticated
+ `404 Not Found` if project ID not found


## Edit snippet

Updates an existing project snippet.

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

Return values:

+ `200 Ok` on success and the updated project snippet
+ `401 Unauthorized` if user is not authenticated
+ `404 Not Found` if project ID not found


## Delete snippet

Deletes an existing project snippet. This is an idempotent function and deleting a non-existent
snippet still returns a `200 Ok` status code.

```
DELETE /projects/:id/snippets/:snippet_id
```

Parameters:

+ `id` (required) - The ID of a project
+ `snippet_id` (required) - The ID of a project's snippet

Return values:

+ `200 Ok` on success and if the snippet was deleted its content
+ `401 Unauthorized` if user is not authenticated
+ `404 Not Found` if project ID not found


## Snippet content

Get a raw project snippet.

```
GET /projects/:id/snippets/:snippet_id/raw
```

Parameters:

+ `id` (required) - The ID of a project
+ `snippet_id` (required) - The ID of a project's snippet

Return values:

+ `200 Ok` on success and the raw snippet
+ `401 Unauthorized` if user is not authenticated
+ `404 Not Found` if project ID or snippet ID is not found