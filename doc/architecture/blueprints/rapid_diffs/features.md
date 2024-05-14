---
status: proposed
creation-date: "2023-10-10"
authors: [ "@thomasrandolph", "@patrickbajao", "@igor.drozdov", "@jerasmus", "@iamphill", "@slashmanov", "@psjakubowska" ]
coach: [ "@ntepluhina" ]
approvers: [ ]
owning-stage: "~devops::create"
participating-stages: []
---

This is an appendix to the [Reusable Rapid Diffs document](index.md).

# Diffs features

Below is a complete list of features for merge request and commit diffs grouped by diff viewers (Code, Image, Other).

✓ – available in both MR and Commit views.

| Features                          | Code   | Image | Other |
|-----------------------------------|--------|-------|-------|
| Filename                          | ✓      | ✓     | ✓     |
| Copy file path                    | ✓      | ✓     | ✓     |
| Collapse and expand file          | ✓      | ✓     | ✓     |
| File stats                        | ✓      | ✓     | ✓     |
| Lines changed (0 for blobs)       | ✓      | ✓     | ✓     |
| Permissions changed               | ✓      | ✓     | ✓     |
| CRUD comment on file              | ✓      | ✓     | ✓     |
| View file link                    | ✓      | ✓     | ✓     |
| Mark as viewed                    | MR     | MR    | MR    |
| Hide all comments                 | MR     | MR    | MR    |
| Show full file (expand all lines) | MR     |       |       |
| Open in Web IDE link              | MR     |       |       |
| Line link                         | ✓      |       |       |
| Edit file link                    | ✓      |       |       |
| Code highlight (multiple themes)  | ✓      |       |       |
| Expand lines                      | ✓      |       |       |
| CRUD comment on specific line     | Commit      |       |       |
| CRUD comment on line range        | MR      |       |       |
| Draft comment on line range       | MR      |       |       |
| Code quality highlights           | ✓      |       |       |
| Test coverage highlights          | ✓      |       |       |
| Hide whitespace changes           | ✓      |       |       |
| Auto-collapse large file          | ✓      |       |       |
| View as raw                       | Commit |       |       |
| Side by side view                 |        | ✓     |       |
