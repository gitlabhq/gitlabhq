---
stage: Create
group: Source Code
info: "To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments"
type: reference
description: "Autocomplete characters in Markdown fields."
---

# Autocomplete characters **(FREE)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/36705) in GitLab 13.9: you can search using the full name in user autocomplete.

The autocomplete characters provide a quick way of entering field values into
Markdown fields. When you start typing a word in a Markdown field with one of
the following characters, GitLab progressively autocompletes against a set of
matching values. The string matching is not case sensitive.

| Character | Autocompletes | Relevant matches shown |
| :-------- | :------------ | :---- |
| `~`       | Labels | 20 |
| `%`       | Milestones | 5 |
| `@`       | Users and groups | 10 |
| `#`       | Issues | 5 |
| `!`       | Merge requests | 5 |
| `&`       | Epics | 5 |
| `$`       | Snippets | 5 |
| `:`       | Emoji | 5 |
| `/`       | Quick Actions | 100 |

When you select an item from the list, the value is entered in the field.
The more characters you enter, the more precise the matches are.

Autocomplete characters are useful when combined with [Quick Actions](quick_actions.md).

## User autocomplete

Assume your GitLab instance includes the following users:

<!-- vale gitlab.Spelling = NO -->

| Username        | Name |
| :-------------- | :--- |
| alessandra      | Rosy Grant |
| lawrence.white  | Kelsey Kerluke |
| leanna          | Rosemarie Rogahn |
| logan_gutkowski | Lee Wuckert |
| shelba          | Josefine Haley |

<!-- vale gitlab.Spelling = YES -->

User autocompletion sorts by the users whose username or name start with your query first.
For example, typing `@lea` shows `leanna` first and typing `@ros` shows `Rosemarie Rogahn` and `Rosy Grant` first.
Any usernames or names that include your query are shown afterwards in the autocomplete menu.

You can also search across the full name to find a user.
To find `Rosy Grant`, even if their username is for example `alessandra`, you can type their full name without spaces like `@rosygrant`.
