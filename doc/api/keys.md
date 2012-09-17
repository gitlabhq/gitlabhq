## List keys

Get a list of currently authenticated user's keys.

```
GET /keys
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

## Single key

Get a single key.

```
GET /keys/:id
```

Parameters:

+ `id` (required) - The ID of a key

```json
{
  "id": 1,
  "title" : "Public key"
  "key": "ssh-rsa AAAAB3NzaC1yc2EAAAABJQAAAIEAiPWx6WM4lhHNedGfBpPJNPpZ7yKu+dnn1SJejgt4
      596k6YjzGGphH2TUxwKzxcKDKKezwkpfnxPkSMkuEspGRt/aZZ9wa++Oi7Qkr8prgHc4
      soW6NUlfDzpvZK2H5E7eQaSeP3SAwGmQKUFHCddNaP0L+hM7zhFNzjFvpaMgJw0="
}
```
## Add key

Create new key owned by currently authenticated user

```
POST /keys
```

Parameters:

+ `title` (required) - new SSH Key's title
+ `key` (required) - new SSH key

Will return created key with status `201 Created` on success, or `404 Not
found` on fail.

## Delete key

Delete key owned by currently authenticated user

```
DELETE /keys/:id
```

Parameters:

+ `id` (required) - key ID

Will return `200 OK` on success, or `404 Not Found` on fail.


