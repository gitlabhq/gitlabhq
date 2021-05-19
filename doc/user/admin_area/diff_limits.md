---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
type: reference
---

# Diff limits administration **(FREE SELF)**

You can set a maximum size for display of diff files (patches).

For details about diff files, [view changes between files](../project/merge_requests/changes.md).

## Maximum diff patch size

Diff files which exceed this value are presented as 'too large' and cannot
be expandable. Instead of an expandable view, a link to the blob view is
shown.

Patches greater than 10% of this size are automatically collapsed, and a
link to expand the diff is presented.
This affects merge requests and branch comparison views.

To set the maximum diff patch size:

1. Go to the Admin Area (**{admin}**) and select **Settings > General**.
1. Expand **Diff limits**.
1. Enter a value for **Maximum diff patch size**, measured in bytes.
1. Select **Save changes**.

WARNING:
This setting is experimental. An increased maximum increases resource
consumption of your instance. Keep this in mind when adjusting the maximum.

<!-- ## Troubleshooting

Include any troubleshooting steps that you can foresee. If you know beforehand what issues
one might have when setting this up, or when something is changed, or on upgrading, it's
important to describe those, too. Think of things that may go wrong and include them here.
This is important to minimize requests for support, and to avoid doc comments with
questions that you know someone might ask.

Each scenario can be a third-level heading, e.g. `### Getting error message X`.
If you have none to add when creating a doc, leave this section in place
but commented out to help encourage others to add to it in the future. -->
