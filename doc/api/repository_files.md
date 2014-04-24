# Repository files

## CRUD for repository files

## Create, read, update and delete repository files using this API

---

## Get file from repository

Allows you to receive information about file in repository like name, size, content. Note that file content is Base64 encoded.

```
GET /projects/:id/repository/files
```

Example response:

```json
{
  "file_name": "key.rb",
  "file_path": "app/models/key.rb",
  "size": 1476,
  "encoding": "base64",
  "content": "IyA9PSBTY2hlbWEgSW5mb3...",
  "ref": "master",
  "blob_id": "79f7bbd25901e8334750839545a9bd021f0e4c83",
  "commit_id": "d5a3ff139356ce33e37e73add446f16869741b50"
}
```

Parameters:

- `file_path` (required) - Full path to new file. Ex. lib/class.rb
- `ref` (required) - The name of branch, tag or commit

## Create new file in repository

```
POST /projects/:id/repository/files
```

Example response:

```json
{
  "file_name": "app/project.rb",
  "branch_name": "master"
}
```

Parameters:

- `file_path` (required) - Full path to new file. Ex. lib/class.rb
- `branch_name` (required) - The name of branch
- `encoding` (optional) - 'text' or 'base64'. Text is default.
- `content` (required) - File content
- `commit_message` (required) - Commit message

## Update existing file in repository

```
PUT /projects/:id/repository/files
```

Example response:

```json
{
  "file_name": "app/project.rb",
  "branch_name": "master"
}
```

Parameters:

- `file_path` (required) - Full path to file. Ex. lib/class.rb
- `branch_name` (required) - The name of branch
- `encoding` (optional) - 'text' or 'base64'. Text is default.
- `content` (required) - New file content
- `commit_message` (required) - Commit message

## Delete existing file in repository

```
DELETE /projects/:id/repository/files
```

Example response:

```json
{
  "file_name": "app/project.rb",
  "branch_name": "master"
}
```

Parameters:

- `file_path` (required) - Full path to file. Ex. lib/class.rb
- `branch_name` (required) - The name of branch
- `commit_message` (required) - Commit message
