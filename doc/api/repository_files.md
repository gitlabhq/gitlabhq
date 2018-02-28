# Repository files API

**CRUD for repository files**

**Create, read, update and delete repository files using this API**

## Get file from repository

Allows you to receive information about file in repository like name, size,
content. Note that file content is Base64 encoded. This endpoint can be accessed
without authentication if the repository is publicly accessible.

```
GET /projects/:id/repository/files/:file_path
```

```bash
curl --request GET --header 'PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK' 'https://gitlab.example.com/api/v4/projects/13083/repository/files/app%2Fmodels%2Fkey%2Erb?ref=master'
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

- `file_path` (required) - Url encoded full path to new file. Ex. lib%2Fclass%2Erb
- `ref` (required) - The name of branch, tag or commit

## Get raw file from repository

```
GET /projects/:id/repository/files/:file_path/raw
```

```bash
curl --request GET --header 'PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK' 'https://gitlab.example.com/api/v4/projects/13083/repository/files/app%2Fmodels%2Fkey%2Erb/raw?ref=master'
```

Parameters:

- `file_path` (required) - Url encoded full path to new file. Ex. lib%2Fclass%2Erb
- `ref` (required) - The name of branch, tag or commit

## Create new file in repository

```
POST /projects/:id/repository/files/:file_path
```

```bash
curl --request POST --header 'PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK' 'https://gitlab.example.com/api/v4/projects/13083/repository/files/app%2Fprojectrb%2E?branch=master&author_email=author%40example.com&author_name=Firstname%20Lastname&content=some%20content&commit_message=create%20a%20new%20file'
```

Example response:

```json
{
  "file_path": "app/project.rb",
  "branch": "master"
}
```

Parameters:

- `file_path` (required) - Url encoded full path to new file. Ex. lib%2Fclass%2Erb
- `branch` (required) - Name of the branch
- `start_branch` (optional) - Name of the branch to start the new commit from
- `encoding` (optional) - Change encoding to 'base64'. Default is text.
- `author_email` (optional) - Specify the commit author's email address
- `author_name` (optional) - Specify the commit author's name
- `content` (required) - File content
- `commit_message` (required) - Commit message

## Update existing file in repository

```
PUT /projects/:id/repository/files/:file_path
```

```bash
curl --request PUT --header 'PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK' 'https://gitlab.example.com/api/v4/projects/13083/repository/files/app%2Fproject%2Erb?branch=master&author_email=author%40example.com&author_name=Firstname%20Lastname&content=some%20other%20content&commit_message=update%20file'
```

Example response:

```json
{
  "file_path": "app/project.rb",
  "branch": "master"
}
```

Parameters:

- `file_path` (required) - Url encoded full path to new file. Ex. lib%2Fclass%2Erb
- `branch` (required) - Name of the branch
- `start_branch` (optional) - Name of the branch to start the new commit from
- `encoding` (optional) - Change encoding to 'base64'. Default is text.
- `author_email` (optional) - Specify the commit author's email address
- `author_name` (optional) - Specify the commit author's name
- `content` (required) - New file content
- `commit_message` (required) - Commit message
- `last_commit_id` (optional) - Last known file commit id

If the commit fails for any reason we return a 400 error with a non-specific
error message. Possible causes for a failed commit include:
- the `file_path` contained `/../` (attempted directory traversal);
- the new file contents were identical to the current file contents, i.e. the
  user tried to make an empty commit;
- the branch was updated by a Git push while the file edit was in progress.

Currently gitlab-shell has a boolean return code, preventing GitLab from specifying the error.

## Delete existing file in repository

```
DELETE /projects/:id/repository/files/:file_path
```

```bash
curl --request DELETE --header 'PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK' 'https://gitlab.example.com/api/v4/projects/13083/repository/files/app%2Fproject%2Erb?branch=master&author_email=author%40example.com&author_name=Firstname%20Lastname&commit_message=delete%20file'
```

Parameters:

- `file_path` (required) - Url encoded full path to new file. Ex. lib%2Fclass%2Erb
- `branch` (required) - Name of the branch
- `start_branch` (optional) - Name of the branch to start the new commit from
- `author_email` (optional) - Specify the commit author's email address
- `author_name` (optional) - Specify the commit author's name
- `commit_message` (required) - Commit message
- `last_commit_id` (optional) - Last known file commit id
