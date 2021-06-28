---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Award emoji API **(FREE)**

An [awarded emoji](../user/award_emojis.md) tells a thousand words.

We call GitLab objects on which you can award an emoji "awardables". You can award emojis on the following:

- [Epics](../user/group/epics/index.md) ([API](epics.md)).
- [Issues](../user/project/issues/index.md) ([API](issues.md)).
- [Merge requests](../user/project/merge_requests/index.md) ([API](merge_requests.md)).
- [Snippets](../user/snippets.md) ([API](snippets.md)).

Emojis can also [be awarded](../user/award_emojis.md#award-emoji-for-comments) on comments (also known as notes). See also [Notes API](notes.md).

## Issues, merge requests, and snippets

See [Award Emoji on Comments](#award-emoji-on-comments) for information on using these endpoints with comments.

### List an awardable's award emojis

Get a list of all award emojis for a specified awardable.

```plaintext
GET /projects/:id/issues/:issue_iid/award_emoji
GET /projects/:id/merge_requests/:merge_request_iid/award_emoji
GET /projects/:id/snippets/:snippet_id/award_emoji
```

Parameters:

| Attribute      | Type           | Required | Description                                                                  |
|:---------------|:---------------|:---------|:-----------------------------------------------------------------------------|
| `id`           | integer/string | yes      | ID or [URL-encoded path of the project](index.md#namespaced-path-encoding). |
| `issue_iid`/`merge_request_iid`/`snippet_id` | integer        | yes      | ID (`iid` for merge requests/issues, `id` for snippets) of an awardable.     |

Example request:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/1/issues/80/award_emoji"
```

Example response:

```json
[
  {
    "id": 4,
    "name": "1234",
    "user": {
      "name": "Administrator",
      "username": "root",
      "id": 1,
      "state": "active",
      "avatar_url": "http://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
      "web_url": "http://gitlab.example.com/root"
    },
    "created_at": "2016-06-15T10:09:34.206Z",
    "updated_at": "2016-06-15T10:09:34.206Z",
    "awardable_id": 80,
    "awardable_type": "Issue"
  },
  {
    "id": 1,
    "name": "microphone",
    "user": {
      "name": "User 4",
      "username": "user4",
      "id": 26,
      "state": "active",
      "avatar_url": "http://www.gravatar.com/avatar/7e65550957227bd38fe2d7fbc6fd2f7b?s=80&d=identicon",
      "web_url": "http://gitlab.example.com/user4"
    },
    "created_at": "2016-06-15T10:09:34.177Z",
    "updated_at": "2016-06-15T10:09:34.177Z",
    "awardable_id": 80,
    "awardable_type": "Issue"
  }
]
```

### Get single award emoji

Get a single award emoji from an issue, snippet, or merge request.

```plaintext
GET /projects/:id/issues/:issue_iid/award_emoji/:award_id
GET /projects/:id/merge_requests/:merge_request_iid/award_emoji/:award_id
GET /projects/:id/snippets/:snippet_id/award_emoji/:award_id
```

Parameters:

| Attribute      | Type           | Required | Description                                                                  |
|:---------------|:---------------|:---------|:-----------------------------------------------------------------------------|
| `id`           | integer/string | yes      | ID or [URL-encoded path of the project](index.md#namespaced-path-encoding). |
| `issue_iid`/`merge_request_iid`/`snippet_id` | integer        | yes      | ID (`iid` for merge requests/issues, `id` for snippets) of an awardable.     |
| `award_id`     | integer        | yes      | ID of the award emoji.                                                       |

Example request:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/1/issues/80/award_emoji/1"
```

Example response:

```json
{
  "id": 1,
  "name": "microphone",
  "user": {
    "name": "User 4",
    "username": "user4",
    "id": 26,
    "state": "active",
    "avatar_url": "http://www.gravatar.com/avatar/7e65550957227bd38fe2d7fbc6fd2f7b?s=80&d=identicon",
    "web_url": "http://gitlab.example.com/user4"
  },
  "created_at": "2016-06-15T10:09:34.177Z",
  "updated_at": "2016-06-15T10:09:34.177Z",
  "awardable_id": 80,
  "awardable_type": "Issue"
}
```

### Award a new emoji

Create an award emoji on the specified awardable.

```plaintext
POST /projects/:id/issues/:issue_iid/award_emoji
POST /projects/:id/merge_requests/:merge_request_iid/award_emoji
POST /projects/:id/snippets/:snippet_id/award_emoji
```

Parameters:

| Attribute      | Type           | Required | Description                                                                  |
|:---------------|:---------------|:---------|:-----------------------------------------------------------------------------|
| `id`           | integer/string | yes      | ID or [URL-encoded path of the project](index.md#namespaced-path-encoding). |
| `issue_iid`/`merge_request_iid`/`snippet_id` | integer        | yes      | ID (`iid` for merge requests/issues, `id` for snippets) of an awardable.     |
| `name`         | string         | yes      | Name of the emoji without colons.                                            |

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/1/issues/80/award_emoji?name=blowfish"
```

Example Response:

```json
{
  "id": 344,
  "name": "blowfish",
  "user": {
    "name": "Administrator",
    "username": "root",
    "id": 1,
    "state": "active",
    "avatar_url": "http://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
    "web_url": "http://gitlab.example.com/root"
  },
  "created_at": "2016-06-17T17:47:29.266Z",
  "updated_at": "2016-06-17T17:47:29.266Z",
  "awardable_id": 80,
  "awardable_type": "Issue"
}
```

### Delete an award emoji

Sometimes it's just not meant to be and you need to remove the award.

Only an administrator or the author of the award can delete an award emoji.

```plaintext
DELETE /projects/:id/issues/:issue_iid/award_emoji/:award_id
DELETE /projects/:id/merge_requests/:merge_request_iid/award_emoji/:award_id
DELETE /projects/:id/snippets/:snippet_id/award_emoji/:award_id
```

Parameters:

| Attribute      | Type           | Required | Description                                                                  |
|:---------------|:---------------|:---------|:-----------------------------------------------------------------------------|
| `id`           | integer/string | yes      | ID or [URL-encoded path of the project](index.md#namespaced-path-encoding). |
| `issue_iid`/`merge_request_iid`/`snippet_id` | integer        | yes      | ID (`iid` for merge requests/issues, `id` for snippets) of an awardable.     |
| `award_id`     | integer        | yes      | ID of an award emoji.                                                        |

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/1/issues/80/award_emoji/344"
```

## Award Emoji on Comments

Comments (also known as notes) are a sub-resource of issues, merge requests, and snippets.

NOTE:
The examples below describe working with award emojis on an issue's comments, but can be
adapted to comments on merge requests and snippets. Therefore, you have to replace
`issue_iid` either with `merge_request_iid` or with the `snippet_id`.

### List a comment's award emojis

Get all award emojis for a comment (note).

```plaintext
GET /projects/:id/issues/:issue_iid/notes/:note_id/award_emoji
```

Parameters:

| Attribute   | Type           | Required | Description                                                                  |
|:------------|:---------------|:---------|:-----------------------------------------------------------------------------|
| `id`        | integer/string | yes      | ID or [URL-encoded path of the project](index.md#namespaced-path-encoding). |
| `issue_iid` | integer        | yes      | Internal ID of an issue.                                                     |
| `note_id`   | integer        | yes      | ID of a comment (note).                                                      |

Example request:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/1/issues/80/notes/1/award_emoji"
```

Example response:

```json
[
  {
    "id": 2,
    "name": "mood_bubble_lightning",
    "user": {
      "name": "User 4",
      "username": "user4",
      "id": 26,
      "state": "active",
      "avatar_url": "http://www.gravatar.com/avatar/7e65550957227bd38fe2d7fbc6fd2f7b?s=80&d=identicon",
      "web_url": "http://gitlab.example.com/user4"
    },
    "created_at": "2016-06-15T10:09:34.197Z",
    "updated_at": "2016-06-15T10:09:34.197Z",
    "awardable_id": 1,
    "awardable_type": "Note"
  }
]
```

### Get an award emoji for a comment

Get a single award emoji for a comment (note).

```plaintext
GET /projects/:id/issues/:issue_iid/notes/:note_id/award_emoji/:award_id
```

Parameters:

| Attribute   | Type           | Required | Description                                                                  |
|:------------|:---------------|:---------|:-----------------------------------------------------------------------------|
| `id`        | integer/string | yes      | ID or [URL-encoded path of the project](index.md#namespaced-path-encoding). |
| `issue_iid` | integer        | yes      | Internal ID of an issue.                                                     |
| `note_id`   | integer        | yes      | ID of a comment (note).                                                      |
| `award_id`  | integer        | yes      | ID of the award emoji.                                                       |

Example request:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/1/issues/80/notes/1/award_emoji/2"
```

Example response:

```json
{
  "id": 2,
  "name": "mood_bubble_lightning",
  "user": {
    "name": "User 4",
    "username": "user4",
    "id": 26,
    "state": "active",
    "avatar_url": "http://www.gravatar.com/avatar/7e65550957227bd38fe2d7fbc6fd2f7b?s=80&d=identicon",
    "web_url": "http://gitlab.example.com/user4"
  },
  "created_at": "2016-06-15T10:09:34.197Z",
  "updated_at": "2016-06-15T10:09:34.197Z",
  "awardable_id": 1,
  "awardable_type": "Note"
}
```

### Award a new emoji on a comment

Create an award emoji on the specified comment (note).

```plaintext
POST /projects/:id/issues/:issue_iid/notes/:note_id/award_emoji
```

Parameters:

| Attribute   | Type           | Required | Description                                                                  |
|:------------|:---------------|:---------|:-----------------------------------------------------------------------------|
| `id`        | integer/string | yes      | ID or [URL-encoded path of the project](index.md#namespaced-path-encoding). |
| `issue_iid` | integer        | yes      | Internal ID of an issue.                                                     |
| `note_id`   | integer        | yes      | ID of a comment (note).                                                      |
| `name`      | string         | yes      | Name of the emoji without colons.                                            |

Example request:

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/1/issues/80/notes/1/award_emoji?name=rocket"
```

Example response:

```json
{
  "id": 345,
  "name": "rocket",
  "user": {
    "name": "Administrator",
    "username": "root",
    "id": 1,
    "state": "active",
    "avatar_url": "http://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
    "web_url": "http://gitlab.example.com/root"
  },
  "created_at": "2016-06-17T19:59:55.888Z",
  "updated_at": "2016-06-17T19:59:55.888Z",
  "awardable_id": 1,
  "awardable_type": "Note"
}
```

### Delete an award emoji from a comment

Sometimes it's just not meant to be and you need to remove the award.

Only an administrator or the author of the award can delete an award emoji.

```plaintext
DELETE /projects/:id/issues/:issue_iid/notes/:note_id/award_emoji/:award_id
```

Parameters:

| Attribute   | Type           | Required | Description                                                                  |
|:------------|:---------------|:---------|:-----------------------------------------------------------------------------|
| `id`        | integer/string | yes      | ID or [URL-encoded path of the project](index.md#namespaced-path-encoding). |
| `issue_iid` | integer        | yes      | Internal ID of an issue.                                                     |
| `note_id`   | integer        | yes      | ID of a comment (note).                                                      |
| `award_id`  | integer        | yes      | ID of an award_emoji.                                                        |

Example request:

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/1/issues/80/award_emoji/345"
```
