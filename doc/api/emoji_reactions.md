---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Emoji reactions API
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

> [Renamed](https://gitlab.com/gitlab-org/gitlab/-/issues/409884) from "award emoji" to "emoji reactions" in GitLab 16.0.

An [emoji reaction](../user/emoji_reactions.md) tells a thousand words.

We call GitLab objects that accept emoji reactions awardables. You can react with emoji on the following:

- [Epics](../user/group/epics/_index.md) ([API](epics.md)).
- [Issues](../user/project/issues/_index.md) ([API](issues.md)).
- [Merge requests](../user/project/merge_requests/_index.md) ([API](merge_requests.md)).
- [Snippets](../user/snippets.md) ([API](snippets.md)).
- [Comments](../user/emoji_reactions.md#emoji-reactions-for-comments) ([API](notes.md)).

## Issues, merge requests, and snippets

For information on using these endpoints with comments, see [Add reactions to comments](#add-reactions-to-comments).

### List an awardable's emoji reactions

> - [Changed](https://gitlab.com/gitlab-org/gitlab/-/issues/335068) in GitLab 15.1 to allow unauthenticated access to public awardables.

Get a list of all emoji reactions for a specified awardable. This endpoint can
be accessed without authentication if the awardable is publicly accessible.

```plaintext
GET /projects/:id/issues/:issue_iid/award_emoji
GET /projects/:id/merge_requests/:merge_request_iid/award_emoji
GET /projects/:id/snippets/:snippet_id/award_emoji
```

Parameters:

| Attribute      | Type           | Required | Description                                                                  |
|:---------------|:---------------|:---------|:-----------------------------------------------------------------------------|
| `id`           | integer/string | yes      | ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |
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

### Get single emoji reaction

> - [Changed](https://gitlab.com/gitlab-org/gitlab/-/issues/335068) in GitLab 15.1 to allow unauthenticated access to public awardables.

Get a single emoji reaction from an issue, snippet, or merge request. This endpoint can
be accessed without authentication if the awardable is publicly accessible.

```plaintext
GET /projects/:id/issues/:issue_iid/award_emoji/:award_id
GET /projects/:id/merge_requests/:merge_request_iid/award_emoji/:award_id
GET /projects/:id/snippets/:snippet_id/award_emoji/:award_id
```

Parameters:

| Attribute      | Type           | Required | Description                                                                  |
|:---------------|:---------------|:---------|:-----------------------------------------------------------------------------|
| `id`           | integer/string | yes      | ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |
| `issue_iid`/`merge_request_iid`/`snippet_id` | integer        | yes      | ID (`iid` for merge requests/issues, `id` for snippets) of an awardable.     |
| `award_id`     | integer        | yes      | ID of the emoji reaction.                                                       |

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

### Add a new emoji reaction

Add an emoji reaction on the specified awardable.

```plaintext
POST /projects/:id/issues/:issue_iid/award_emoji
POST /projects/:id/merge_requests/:merge_request_iid/award_emoji
POST /projects/:id/snippets/:snippet_id/award_emoji
```

Parameters:

| Attribute      | Type           | Required | Description                                                                  |
|:---------------|:---------------|:---------|:-----------------------------------------------------------------------------|
| `id`           | integer/string | yes      | ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |
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

### Delete an emoji reaction

Sometimes it's just not meant to be and you need to remove your reaction.

Only an administrator or the author of the reaction can delete an emoji reaction.

```plaintext
DELETE /projects/:id/issues/:issue_iid/award_emoji/:award_id
DELETE /projects/:id/merge_requests/:merge_request_iid/award_emoji/:award_id
DELETE /projects/:id/snippets/:snippet_id/award_emoji/:award_id
```

Parameters:

| Attribute      | Type           | Required | Description                                                                  |
|:---------------|:---------------|:---------|:-----------------------------------------------------------------------------|
| `id`           | integer/string | yes      | ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |
| `issue_iid`/`merge_request_iid`/`snippet_id` | integer        | yes      | ID (`iid` for merge requests/issues, `id` for snippets) of an awardable.     |
| `award_id`     | integer        | yes      | ID of an emoji reaction.                                                        |

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/1/issues/80/award_emoji/344"
```

## Add reactions to comments

Comments (also known as notes) are a sub-resource of issues, merge requests, and snippets.

NOTE:
The examples below describe working with emoji reactions on an issue's comments, but can be
adapted to comments on merge requests and snippets. Therefore, you have to replace
`issue_iid` either with `merge_request_iid` or with the `snippet_id`.

### List a comment's emoji reactions

> - [Changed](https://gitlab.com/gitlab-org/gitlab/-/issues/335068) in GitLab 15.1 to allow unauthenticated access to public comments.

Get all emoji reactions for a comment (note). This endpoint can
be accessed without authentication if the comment is publicly accessible.

```plaintext
GET /projects/:id/issues/:issue_iid/notes/:note_id/award_emoji
```

Parameters:

| Attribute   | Type           | Required | Description                                                                  |
|:------------|:---------------|:---------|:-----------------------------------------------------------------------------|
| `id`        | integer/string | yes      | ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |
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

### Get an emoji reaction for a comment

> - [Changed](https://gitlab.com/gitlab-org/gitlab/-/issues/335068) in GitLab 15.1 to allow unauthenticated access to public comments.

Get a single emoji reaction for a comment (note). This endpoint can
be accessed without authentication if the comment is publicly accessible.

```plaintext
GET /projects/:id/issues/:issue_iid/notes/:note_id/award_emoji/:award_id
```

Parameters:

| Attribute   | Type           | Required | Description                                                                  |
|:------------|:---------------|:---------|:-----------------------------------------------------------------------------|
| `id`        | integer/string | yes      | ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |
| `issue_iid` | integer        | yes      | Internal ID of an issue.                                                     |
| `note_id`   | integer        | yes      | ID of a comment (note).                                                      |
| `award_id`  | integer        | yes      | ID of the emoji reaction.                                                       |

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

### Add a new emoji reaction to a comment

Create an emoji reaction on the specified comment (note).

```plaintext
POST /projects/:id/issues/:issue_iid/notes/:note_id/award_emoji
```

Parameters:

| Attribute   | Type           | Required | Description                                                                  |
|:------------|:---------------|:---------|:-----------------------------------------------------------------------------|
| `id`        | integer/string | yes      | ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |
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

### Delete an emoji reaction from a comment

Sometimes it's just not meant to be and you need to remove the reaction.

Only an administrator or the author of the reaction can delete an emoji reaction.

```plaintext
DELETE /projects/:id/issues/:issue_iid/notes/:note_id/award_emoji/:award_id
```

Parameters:

| Attribute   | Type           | Required | Description                                                                  |
|:------------|:---------------|:---------|:-----------------------------------------------------------------------------|
| `id`        | integer/string | yes      | ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |
| `issue_iid` | integer        | yes      | Internal ID of an issue.                                                     |
| `note_id`   | integer        | yes      | ID of a comment (note).                                                      |
| `award_id`  | integer        | yes      | ID of an emoji reaction.                                                        |

Example request:

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/1/issues/80/award_emoji/345"
```
