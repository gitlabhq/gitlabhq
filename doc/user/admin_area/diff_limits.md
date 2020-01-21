---
type: reference
---

# Diff limits administration **(CORE ONLY)**

You can set a maximum size for display of diff files (patches).

For details about diff files, [View changes between files](../project/merge_requests/reviewing_and_managing_merge_requests.md#view-changes-between-file-versions).

## Maximum diff patch size

Diff files which exceed this value will be presented as 'too large' and won't
be expandable. Instead of an expandable view, a link to the blob view will be
shown.

Patches greater than 10% of this size will be automatically collapsed, and a
link to expand the diff will be presented.

NOTE: **Note:**
Merge requests and branch comparison views will be affected.

CAUTION: **Caution:**
This setting is experimental. An increased maximum will increase resource
consumption of your instance. Keep this in mind when adjusting the maximum.

1. Go to **Admin Area > Settings > General**.
1. Expand **Diff limits**.
1. Enter a value for **Maximum diff patch size**, measured in bytes.
1. Click on **Save changes**.

<!-- ## Troubleshooting

Include any troubleshooting steps that you can foresee. If you know beforehand what issues
one might have when setting this up, or when something is changed, or on upgrading, it's
important to describe those, too. Think of things that may go wrong and include them here.
This is important to minimize requests for support, and to avoid doc comments with
questions that you know someone might ask.

Each scenario can be a third-level heading, e.g. `### Getting error message X`.
If you have none to add when creating a doc, leave this section in place
but commented out to help encourage others to add to it in the future. -->
