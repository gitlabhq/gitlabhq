# Repository files

**CRUD for repository files**

**Create, read, update and delete repository files using this API**

## Get file from repository

Allows you to receive information about file in repository like name, size, content. Note that file content is Base64 encoded.

```
GET /projects/:id/repository/files
```

```bash
curl --request GET --header 'PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK' 'https://gitlab.example.com/api/v3/projects/13083/repository/files?file_path=app/models/key.rb&ref=master'
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
  "commit_id": "d5a3ff139356ce33e37e73add446f16869741b50",
  "last_commit_id": "570e7b2abdd848b95f2f578043fc23bd6f6fd24d"
}
```

Parameters:

- `file_path` (required) - Full path to new file. Ex. lib/class.rb
- `ref` (required) - The name of branch, tag or commit

## Create new file in repository

```
POST /projects/:id/repository/files
```

```bash
curl --request POST --header 'PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK' 'https://gitlab.example.com/api/v3/projects/13083/repository/files?file_path=app/project.rb&branch_name=master&author_email=author%40example.com&author_name=Firstname%20Lastname&content=some%20content&commit_message=create%20a%20new%20file'
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
- `author_email` (optional) - Specify the commit author's email address
- `author_name` (optional) - Specify the commit author's name
- `content` (required) - File content
- `commit_message` (required) - Commit message

## Update existing file in repository

```
PUT /projects/:id/repository/files
```

```bash
curl --request PUT --header 'PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK' 'https://gitlab.example.com/api/v3/projects/13083/repository/files?file_path=app/project.rb&branch_name=master&author_email=author%40example.com&author_name=Firstname%20Lastname&content=some%20other%20content&commit_message=update%20file'
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
- `author_email` (optional) - Specify the commit author's email address
- `author_name` (optional) - Specify the commit author's name
- `content` (required) - New file content
- `commit_message` (required) - Commit message

If the commit fails for any reason we return a 400 error with a non-specific
error message. Possible causes for a failed commit include:
- the `file_path` contained `/../` (attempted directory traversal);
- the new file contents were identical to the current file contents, i.e. the
  user tried to make an empty commit;
- the branch was updated by a Git push while the file edit was in progress.

Currently gitlab-shell has a boolean return code, preventing GitLab from specifying the error.

## Delete existing file in repository

```
DELETE /projects/:id/repository/files
```

```bash
curl --request PUT --header 'PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK' 'https://gitlab.example.com/api/v3/projects/13083/repository/files?file_path=app/project.rb&branch_name=master&author_email=author%40example.com&author_name=Firstname%20Lastname&commit_message=delete%20file'
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
- `author_email` (optional) - Specify the commit author's email address
- `author_name` (optional) - Specify the commit author's name
- `commit_message` (required) - Commit message
