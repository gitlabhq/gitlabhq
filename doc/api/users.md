## List users

Get a list of users.

```
GET /users
```

```json
[
  {
    "id": 1,
    "username": "john_smith",
    "email": "john@example.com",
    "name": "John Smith",
    "blocked": false,
    "created_at": "2012-05-23T08:00:58Z",
    "bio": null,
    "skype": "",
    "linkedin": "",
    "twitter": "",
    "dark_scheme": false,
    "extern_uid": "john.smith",
    "provider": "provider_name",
    "theme_id": 1
  },
  {
    "id": 2,
    "username": "jack_smith",
    "email": "jack@example.com",
    "name": "Jack Smith",
    "blocked": false,
    "created_at": "2012-05-23T08:01:01Z",
    "bio": null,
    "skype": "",
    "linkedin": "",
    "twitter": "",
    "dark_scheme": true,
    "extern_uid": "jack.smith",
    "provider": "provider_name",
    "theme_id": 1
  }
]
```

Return values:

+ `200 Ok` on success and a list with all users
+ `401 Unauthorized` if user is not allowed to access the list


## Single user

Get a single user.

```
GET /users/:id
```

Parameters:

+ `id` (required) - The ID of a user

```json
{
  "id": 1,
  "username": "john_smith",
  "email": "john@example.com",
  "name": "John Smith",
  "blocked": false,
  "created_at": "2012-05-23T08:00:58Z",
  "bio": null,
  "skype": "",
  "linkedin": "",
  "twitter": "",
  "dark_scheme": false,
  "extern_uid": "john.smith",
  "provider": "provider_name",
  "theme_id": 1
}
```

Return values:

+ `200 Ok` on success and the user entry
+ `401 Unauthorized` if it is not allowed to access the user
+ `404 Not Found` if the user with ID is not found


## User creation

Creates a new user. Note only administrators can create new users.

```
POST /users
```

Parameters:

+ `email` (required)          - Email
+ `password` (required)       - Password
+ `username` (required)       - Username
+ `name` (required)           - Name
+ `skype` (optional)          - Skype ID
+ `linkedin` (optional)       - Linkedin
+ `twitter` (optional)        - Twitter account
+ `projects_limit` (optional) - Number of projects user can create
+ `extern_uid` (optional)     - External UID
+ `provider` (optional)       - External provider name
+ `bio` (optional)            - User's bio

Return values:

+ `201 Created` on success and returns the new user
+ `400 Bad Request` if one of the required attributes is missing from the request
+ `401 Unauthorized` if the user is not authorized
+ `403 Forbidden` if the user is not allowed to create a new user (must be admin)
+ `404 Not Found` if something else fails
+ `409 Conflict` if a user with the same email address or username already exists


## User modification

Modifies an existing user. Only administrators can change attributes of a user.

```
PUT /users/:id
```

Parameters:

+ `email`                             - Email
+ `username`                          - Username
+ `name`                              - Name
+ `password`                          - Password
+ `skype`                             - Skype ID
+ `linkedin`                          - Linkedin
+ `twitter`                           - Twitter account
+ `projects_limit`                    - Limit projects wich user can create
+ `extern_uid`                        - External UID
+ `provider`                          - External provider name
+ `bio`                               - User's bio

Return values:

+ `200 Ok` on success and returns the new user
+ `401 Unauthorized` if the user is not authorized
+ `403 Forbidden` if the user is not allowed to create a new user (must be admin)
+ `404 Not Found` if something else fails

Note, at the moment this method does only return a 404 error, even in cases where a 409 (Conflict) would
be more appropriate, e.g. when renaming the email address to some exsisting one.


## User deletion

Deletes a user. Available only for administrators. This is an idempotent function, calling this function
for a non-existent user id still returns a status code `200 Ok`. The JSON response differs if the user
was actually deleted or not. In the former the user is returned and in the latter not.

```
DELETE /users/:id
```

Parameters:

+ `id` (required) - The ID of the user

Return values:

+ `200 Ok` on success and returns the deleted user
+ `401 Unauthorized` if the user is not authorized
+ `403 Forbidden` if the user is not allowed to create a new user (must be admin)
+ `404 Not Found` if user with ID not found or something else fails


## Current user

Gets currently authenticated user.

```
GET /user
```

```json
{
  "id": 1,
  "username": "john_smith",
  "email": "john@example.com",
  "name": "John Smith",
  "blocked": false,
  "created_at": "2012-05-23T08:00:58Z",
  "bio": null,
  "skype": "",
  "linkedin": "",
  "twitter": "",
  "dark_scheme": false,
  "theme_id": 1
}
```

Return values:

+ `200 Ok` on success and returns the current user
+ `401 Unauthorized` if the user is not authorized
+ `404 Not Found` if something else fails


## List SSH keys

Get a list of currently authenticated user's SSH keys.

```
GET /user/keys
```

```json
[
  {
    "id": 1,
    "title" : "Public key"
    "key": "ssh-rsa AAAAB3NzaC1yc2EAAAABJQAAAIEAiPWx6WM4lhHNedGfBpPJNPpZ7yKu+dnn1SJejgt4
      596k6YjzGGphH2TUxwKzxcKDKKezwkpfnxPkSMkuEspGRt/aZZ9wa++Oi7Qkr8prgHc4
      soW6NUlfDzpvZK2H5E7eQaSeP3SAwGmQKUFHCddNaP0L+hM7zhFNzjFvpaMgJw0=",
  },
  {
    "id": 3,
    "title" : "Another Public key"
    "key": "ssh-rsa AAAAB3NzaC1yc2EAAAABJQAAAIEAiPWx6WM4lhHNedGfBpPJNPpZ7yKu+dnn1SJejgt4
      596k6YjzGGphH2TUxwKzxcKDKKezwkpfnxPkSMkuEspGRt/aZZ9wa++Oi7Qkr8prgHc4
      soW6NUlfDzpvZK2H5E7eQaSeP3SAwGmQKUFHCddNaP0L+hM7zhFNzjFvpaMgJw0="
  }
]
```

Parameters:

+ **none**

Return values:

+ `200 Ok` on success and a list of ssh keys
+ `401 Unauthorized` if the user is not authenticated
+ `404 Not Found` if something else fails


## Single SSH key

Get a single key.

```
GET /user/keys/:id
```

Parameters:

+ `id` (required) - The ID of an SSH key

```json
{
  "id": 1,
  "title" : "Public key"
  "key": "ssh-rsa AAAAB3NzaC1yc2EAAAABJQAAAIEAiPWx6WM4lhHNedGfBpPJNPpZ7yKu+dnn1SJejgt4
      596k6YjzGGphH2TUxwKzxcKDKKezwkpfnxPkSMkuEspGRt/aZZ9wa++Oi7Qkr8prgHc4
      soW6NUlfDzpvZK2H5E7eQaSeP3SAwGmQKUFHCddNaP0L+hM7zhFNzjFvpaMgJw0="
}
```

Return values:

+ `200 Ok` on success and the ssh key with ID
+ `401 Unauthorized` if it is not allowed to access the user
+ `404 Not Found` if the ssh key with ID not found


## Add SSH key

Creates a new key owned by the currently authenticated user.

```
POST /user/keys
```

Parameters:

+ `title` (required) - new SSH Key's title
+ `key` (required) - new SSH key

Return values:

+ `201 Created` on success and the added key
+ `400 Bad Request` if one of the required attributes is not given
+ `401 Unauthorized` if user is not authorized to add ssh key
+ `404 Not Found` if something else fails


## Delete SSH key

Deletes key owned by currently authenticated user. This is an idempotent function and calling it on a key that is already
deleted or not available results in `200 Ok`.

```
DELETE /user/keys/:id
```

Parameters:

+ `id` (required) - SSH key ID

Return values:

+ `200 Ok` on success
+ `401 Unauthorized` if user is not allowed to delete they key
+ `404 Not Found` if something else fails
