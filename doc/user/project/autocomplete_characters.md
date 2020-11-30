---
stage: Create
group: Source Code
info: "To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments"
type: reference
description: "Autocomplete chars in Markdown fields."
---

# Autocomplete characters

The autocomplete characters provide a quick way of entering field values into
Markdown fields. When you start typing a word in a Markdown field with one of
the following characters, GitLab progressively autocompletes against a set of
matching values. The string matching is not case sensitive.

| Character | Autocompletes |
| :-------- | :------------ |
| `~`       | Labels |
| `%`       | Milestones |
| `@`       | Users and groups |
| `#`       | Issues |
| `!`       | Merge requests |
| `&`       | Epics |
| `$`       | Snippets |
| `:`       | Emoji |
| `/`       | Quick Actions |

Up to 5 of the most relevant matches are displayed in a popup list. When you
select an item from the list, the value is entered in the field. The more
characters you enter, the more precise the matches are.

Autocomplete characters are useful when combined with [Quick Actions](quick_actions.md).

## Example

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

In an Issue comment, entering `@l` results in the following popup list
appearing. Note that user `shelba` is not included, because the list includes
only the 5 users most relevant to the Issue.

![Popup list which includes users whose username or name contains the letter `l`](img/autocomplete_characters_example1_v12_0.png)

If you continue to type, `@le`, the popup list changes to the following. The
popup now only includes users where `le` appears in their username, or a word in
their name.

![Popup list which includes users whose username or name contains the string `le`](img/autocomplete_characters_example2_v12_0.png)
