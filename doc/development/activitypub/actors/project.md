---
stage: Create
group: Source Code
info: "To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments"
---

# Activities for project actor **(EXPERIMENT)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/127023) in GitLab 16.5 [with two flags](../../../administration/feature_flags.md) named `activity_pub` and `activity_pub_project`. Disabled by default. This feature is an [Experiment](../../../policy/experiment-beta-support.md).

FLAG:
On self-managed GitLab, by default this feature is not available. To make it available,
an administrator can [enable the feature flags](../../../administration/feature_flags.md)
named `activity_pub` and `activity_pub_project`.
On GitLab.com, this feature is not available.
The feature is not ready for production use.

This feature requires two feature flags:

- `activity_pub`: Enables or disables all ActivityPub-related features.
- `activity_pub_project`: Enables and disable ActivityPub features specific to
  projects. Requires the `activity_pub` flag to also be enabled.

## Profile

```javascript
{
  "@context": "https://www.w3.org/ns/activitystreams",
  "id": PROJECT_URL,
  "type": "Application",
  "name": PROJECT_NAME,
  "summary": PROJECT_DESCRIPTION,
  "url": PROJECT_URL,
  "outbox": PROJECT_OUTBOX_URL,
  "inbox": null,
}
```

## Outbox

For a project, we can map the events happening on the project activity
timeline on GitLab, when a user:

- [Creates the repository](#user-creates-the-repository).
- [Pushes commits](#user-pushes-commits).
- [Pushes a tag](#user-pushes-a-tag).
- [Opens a merge request](#user-opens-a-merge-request).
- [Accepts a merge request](#user-accepts-a-merge-request).
- [Closes a merge request](#user-closes-a-merge-request).
- [Opens an issue](#user-opens-an-issue).
- [Closes an issue](#user-closes-an-issue).
- [Reopens an issue](#user-reopens-an-issue).
- [Comments on a merge request](#user-comments-on-a-merge-request).
- [Comments on an issue](#user-comments-on-an-issue).
- [Creates a wiki page](#user-creates-a-wiki-page).
- [Updates a wiki page](#user-updates-a-wiki-page).
- [Destroys a wiki page](#user-destroys-a-wiki-page).
- [Joins the project](#user-joins-the-project).
- [Leaves the project](#user-leaves-the-project).
- [Deletes the repository](#user-deletes-the-repository).

There's also a Design tab in the project activities, but it's just empty in
all projects I follow and I don't see anything related to it in my projects
sidebar. Maybe it's a premium feature? If so, it's of no concern to us for
public following through ActivityPub.

### User creates the repository

```javascript
{
  "id": PROJECT_OUTBOX_URL#event_id,
  "type": "Create",
  "to": [
    "https://www.w3.org/ns/activitystreams#Public"
  ],
  "actor": {
    "id": USER_PROFILE_URL,
    "type": "Person",
    "name": USER_NAME,
    "url": USER_PROFILE_URL,
  },
  "object": {
    "id": PROJECT_URL,
    "type": "Application",
    "name": PROJECT_NAME,
    "summary": PROJECT_DESCRIPTION,
    "url": PROJECT_URL,
  }
}
```

### User pushes commits

```javascript
{
  "id": PROJECT_OUTBOX_URL#event_id,
  "type": "Update",
  "actor": {
    "id": USER_PROFILE_URL,
    "type": "Person",
    "name": USER_NAME,
    "url": USER_PROFILE_URL,
  },
  "object": {
    "id": PROJECT_URL,
    "type": "Application",
    "name": PROJECT_NAME,
    "summary": PROJECT_DESCRIPTION,
    "url": PROJECT_URL,
  },
  "result": COMMITS_DIFF_URL,
}
```

### User pushes a tag

```javascript
{
  "id": PROJECT_OUTBOX_URL#event_id,
  "type": "Update",
  "actor": {
    "id": USER_PROFILE_URL,
    "type": "Person",
    "name": USER_NAME,
    "url": USER_PROFILE_URL,
  },
  "object": {
    "id": PROJECT_URL,
    "type": "Application",
    "name": PROJECT_NAME,
    "summary": PROJECT_DESCRIPTION,
    "url": PROJECT_URL,
  },
  "name": TAG_NAME,
  "result": COMMIT_URL,
}
```

### User opens a merge request

```javascript
{
  "id": PROJECT_OUTBOX_URL#event_id,
  "type": "Add",
  "to": [
    "https://www.w3.org/ns/activitystreams#Public"
  ],
  "actor": {
    "id": USER_PROFILE_URL,
    "type": "Person",
    "name": USER_NAME,
    "url": USER_PROFILE_URL,
  },
  "object": {
    "id": MERGE_REQUEST_URL,
    "type": "Application",
    "name": MERGE_REQUEST_TITLE,
    "url": MERGE_REQUEST_URL,
    "context": {
      "id": PROJECT_URL,
      "type": "Application",
      "name": PROJECT_NAME,
      "summary": PROJECT_DESCRIPTION,
      "url": PROJECT_URL,
    },
  },
  "target": {
    "id": PROJECT_URL,
    "type": "Application",
    "name": PROJECT_NAME,
    "summary": PROJECT_DESCRIPTION,
    "url": PROJECT_URL,
  },
}
```

### User accepts a merge request

```javascript
{
  "id": PROJECT_OUTBOX_URL#event_id,
  "type": "Accept",
  "to": [
    "https://www.w3.org/ns/activitystreams#Public"
  ],
  "actor": {
    "id": USER_PROFILE_URL,
    "type": "Person",
    "name": USER_NAME,
    "url": USER_PROFILE_URL,
  },
  "object": {
    "id": MERGE_REQUEST_URL,
    "type": "Application",
    "name": MERGE_REQUEST_TITLE,
    "url": MERGE_REQUEST_URL,
    "context": {
      "id": PROJECT_URL,
      "type": "Application",
      "name": PROJECT_NAME,
      "summary": PROJECT_DESCRIPTION,
      "url": PROJECT_URL,
    },
  },
  "target": {
    "id": PROJECT_URL,
    "type": "Application",
    "name": PROJECT_NAME,
    "summary": PROJECT_DESCRIPTION,
    "url": PROJECT_URL,
  },
}
```

### User closes a merge request

```javascript
{
  "id": PROJECT_OUTBOX_URL#event_id,
  "type": "Remove",
  "to": [
    "https://www.w3.org/ns/activitystreams#Public"
  ],
  "actor": {
    "id": USER_PROFILE_URL,
    "type": "Person",
    "name": USER_NAME,
    "url": USER_PROFILE_URL,
  },
  "object": {
    "id": MERGE_REQUEST_URL,
    "type": "Application",
    "name": MERGE_REQUEST_TITLE,
    "url": MERGE_REQUEST_URL,
    "context": {
      "id": PROJECT_URL,
      "type": "Application",
      "name": PROJECT_NAME,
      "summary": PROJECT_DESCRIPTION,
      "url": PROJECT_URL,
    },
  },
  "origin": {
    "id": PROJECT_URL,
    "type": "Application",
    "name": PROJECT_NAME,
    "summary": PROJECT_DESCRIPTION,
    "url": PROJECT_URL,
  },
}
```

### User opens an issue

```javascript
{
  "id": PROJECT_OUTBOX_URL#event_id,
  "type": "Add",
  "to": [
    "https://www.w3.org/ns/activitystreams#Public"
  ],
  "actor": {
    "id": USER_PROFILE_URL,
    "type": "Person",
    "name": USER_NAME,
    "url": USER_PROFILE_URL,
  },
  "object": {
    "id": ISSUE_URL,
    "type": "Page",
    "name": ISSUE_TITLE,
    "url": ISSUE_URL,
    "context": {
      "id": PROJECT_URL,
      "type": "Application",
      "name": PROJECT_NAME,
      "summary": PROJECT_DESCRIPTION,
      "url": PROJECT_URL,
    }
  },
  "target": {
    "id": PROJECT_URL,
    "type": "Application",
    "name": PROJECT_NAME,
    "summary": PROJECT_DESCRIPTION,
    "url": PROJECT_URL,
  }
}
```

Why to add the project both as `object.context` and `target`? For multiple
consistency reasons:

- The **Add** activity is more commonly used with a `target`.
- The **Remove** activity used to close the issue is more
  commonly used with an `origin`.
- The **Update** activity used to reopen an issue specifies that
  `target` and `origin` have no specific meaning, making `context` better
  suited for that.
- We could use `context` only with **Update**, but merge requests
  must be taken into consideration.

Merge requests are very similar to issues, so we want their activities to
be similar. While the best type for issues is `page`, the type chosen for
merge request is `application`, both to distinguish it from issues and because
they contain code.

To distinguish merge requests from projects (which are also `application`),
merge requests are an `application` with another `application` (the project)
as context. Given the merge request will have a `context` even with the **Add**
and **Remove** activities, the same is done with issues for consistency.

An alternative that was considered, but dismissed: instead of **Add** for issues,
use **Create**. That would have allowed us to always use `context`, but
it creates more problems that it solves. **Accept** and **Reject** could work quite
well for closing merge requests, but what would we use to close issues?
**Delete** is incorrect, as the issue is not deleted, just closed.
Reopening the issue later would require an **Update** after a
**Delete**.

Using **Create** for opening issues and **Remove** for closing
issues would be asymmetrical:

- **Create** is mirrored by **Delete**.
- **Add** is mirrored by **Remove**.

To minimize pain for those who will build on top of those resources, it's best
to duplicate the project information as `context` and `target` / `origin`.

### User closes an issue

```javascript
{
  "id": PROJECT_OUTBOX_URL#event_id,
  "type": "Remove",
  "to": [
    "https://www.w3.org/ns/activitystreams#Public"
  ],
  "actor": {
    "id": USER_PROFILE_URL,
    "type": "Person",
    "name": USER_NAME,
    "url": USER_PROFILE_URL,
  },
  "object": {
    "id": ISSUE_URL,
    "type": "Page",
    "name": ISSUE_TITLE,
    "url": ISSUE_URL,
    "context": {
      "id": PROJECT_URL,
      "type": "Application",
      "name": PROJECT_NAME,
      "summary": PROJECT_DESCRIPTION,
      "url": PROJECT_URL,
    },
  },
  "origin": {
    "id": PROJECT_URL,
    "type": "Application",
    "name": PROJECT_NAME,
    "summary": PROJECT_DESCRIPTION,
    "url": PROJECT_URL,
  },
}
```

### User reopens an issue

```javascript
{
  "id": PROJECT_OUTBOX_URL#event_id,
  "type": "Update",
  "to": [
    "https://www.w3.org/ns/activitystreams#Public"
  ],
  "actor": {
    "id": USER_PROFILE_URL,
    "type": "Person",
    "name": USER_NAME,
    "url": USER_PROFILE_URL,
  },
  "object": {
    "id": ISSUE_URL,
    "type": "Page",
    "name": ISSUE_TITLE,
    "url": ISSUE_URL,
    "context": {
      "id": PROJECT_URL,
      "type": "Application",
      "name": PROJECT_NAME,
      "summary": PROJECT_DESCRIPTION,
      "url": PROJECT_URL,
    },
  },
}
```

### User comments on a merge request

```javascript
{
  "id": PROJECT_OUTBOX_URL#event_id,
  "type": "Add",
  "to": [
    "https://www.w3.org/ns/activitystreams#Public"
  ],
  "actor": {
    "id": USER_PROFILE_URL,
    "type": "Person",
    "name": USER_NAME,
    "url": USER_PROFILE_URL,
  },
  "object": {
    "id": NOTE_URL,
    "type": "Note",
    "content": NOTE_NOTE,
  },
  "target": {
    "id": MERGE_REQUEST_URL,
    "type": "Application",
    "name": MERGE_REQUEST_TITLE,
    "url": MERGE_REQUEST_URL,
    "context": {
      "id": PROJECT_URL,
      "type": "Application",
      "name": PROJECT_NAME,
      "summary": PROJECT_DESCRIPTION,
      "url": PROJECT_URL,
    },
  },
}
```

### User comments on an issue

```javascript
{
  "id": PROJECT_URL#event_id,
  "type": "Add",
  "to": [
    "https://www.w3.org/ns/activitystreams#Public"
  ],
  "actor": {
    "id": USER_PROFILE_URL,
    "type": "Person",
    "name": USER_NAME,
    "url": USER_PROFILE_URL,
  },
  "object": {
    "id": NOTE_URL,
    "type": "Note",
    "content": NOTE_NOTE,
  },
  "target": {
    "id": ISSUE_URL,
    "type": "Page",
    "name": ISSUE_TITLE,
    "url": ISSUE_URL,
    "context": {
      "id": PROJECT_URL,
      "type": "Application",
      "name": PROJECT_NAME,
      "summary": PROJECT_DESCRIPTION,
      "url": PROJECT_URL,
    },
  },
}
```

### User creates a wiki page

```javascript
{
  "id": PROJECT_OUTBOX_URL#event_id,
  "type": "Create",
  "to": [
    "https://www.w3.org/ns/activitystreams#Public"
  ],
  "actor": {
    "id": USER_PROFILE_URL,
    "type": "Person",
    "name": USER_NAME,
    "url": USER_PROFILE_URL,
  },
  "object": {
    "id": WIKI_PAGE_URL,
    "type": "Page",
    "name": WIKI_PAGE_HUMAN_TITLE,
    "url": WIKI_PAGE_URL,
  }
}
```

### User updates a wiki page

```javascript
{
  "id": PROJECT_OUTBOX_URL#event_id,
  "type": "Update",
  "to": [
    "https://www.w3.org/ns/activitystreams#Public"
  ],
  "actor": {
    "id": USER_PROFILE_URL,
    "type": "Person",
    "name": USER_NAME,
    "url": USER_PROFILE_URL,
  },
  "object": {
    "id": WIKI_PAGE_URL,
    "type": "Page",
    "name": WIKI_PAGE_HUMAN_TITLE,
    "url": WIKI_PAGE_URL,
  }
}
```

### User destroys a wiki page

```javascript
{
  "id": PROJECT_OUTBOX_URL#event_id,
  "type": "Delete",
  "to": [
    "https://www.w3.org/ns/activitystreams#Public"
  ],
  "actor": {
    "id": USER_PROFILE_URL,
    "type": "Person",
    "name": USER_NAME,
    "url": USER_PROFILE_URL,
  },
  "object": {
    "id": WIKI_PAGE_URL,
    "type": "Page",
    "name": WIKI_PAGE_HUMAN_TITLE,
    "url": WIKI_PAGE_URL,
  }
}
```

### User joins the project

```javascript
{
  "id": PROJECT_OUTBOX_URL#event_id,
  "type": "Add",
  "to": [
    "https://www.w3.org/ns/activitystreams#Public"
  ],
  "actor": {
    "id": USER_PROFILE_URL,
    "type": "Person",
    "name": USER_NAME,
    "url": USER_PROFILE_URL,
  },
  "object": {
    "id": USER_PROFILE_URL,
    "type": "Person",
    "name": USER_NAME,
    "url": USER_PROFILE_URL,
  },
  "target": {
    "id": PROJECT_URL,
    "type": "Application",
    "name": PROJECT_NAME,
    "summary": PROJECT_DESCRIPTION,
    "url": PROJECT_URL,
  },
}
```

The GitLab project timeline does not mention who added a member to the
project, so this does the same. However, the **Add** activity requires an Actor.
For that reason, we use the same person as actor and object.

In the **Members** page of a project contains a `source` attribute.
While there is sometimes mention of who added the user, this is used mainly
to distinguish if the user is a member attached to the project directly, or
through a group. It would not be a good "actor" (that would rather be an
`origin` for the membership).

### User leaves the project

```javascript
{
  "id": PROJECT_OUTBOX_URL#event_id,
  "type": "Remove",
  "to": [
    "https://www.w3.org/ns/activitystreams#Public"
  ],
  "actor": {
    "id": USER_PROFILE_URL,
    "type": "Person",
    "name": USER_NAME,
    "url": USER_PROFILE_URL,
  },
  "object": {
    "id": USER_PROFILE_URL,
    "type": "Person",
    "name": USER_NAME,
    "url": USER_PROFILE_URL,
  },
  "target": {
    "id": PROJECT_URL,
    "type": "Application",
    "name": PROJECT_NAME,
    "summary": PROJECT_DESCRIPTION,
    "url": PROJECT_URL,
  },
}
```

See [User joined the project](#user-joins-the-project).

### User deletes the repository

```javascript
{
  "id": PROJECT_OUTBOX_URL#event_id,
  "type": "Delete",
  "to": [
    "https://www.w3.org/ns/activitystreams#Public"
  ],
  "actor": {
    "id": USER_PROFILE_URL,
    "type": "Person",
    "name": USER_NAME,
    "url": USER_PROFILE_URL,
  },
  "object": {
    "id": PROJECT_URL,
    "type": "Application",
    "name": PROJECT_NAME,
    "summary": PROJECT_DESCRIPTION,
    "url": PROJECT_URL,
  }
}
```
