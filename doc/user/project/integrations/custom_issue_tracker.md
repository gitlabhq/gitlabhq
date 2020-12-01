---
stage: Create
group: Ecosystem
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Custom Issue Tracker service

To enable the Custom Issue Tracker integration in a project:

1. Go to **Settings > Integrations**.
1. Click **Custom Issue Tracker**
1. Fill in the tracker's details, such as title, description, and URLs.
   You can edit these fields later as well.

   These are some of the required fields:

   | Field           | Description |
   | --------------- | ----------- |
   | **Project URL**   | The URL to the project in the custom issue tracker. |
   | **Issues URL**    | The URL to the issue in the issue tracker project that is linked to this GitLab project. Note that the `issues_url` requires `:id` in the URL. This ID is used by GitLab as a placeholder to replace the issue number. For example, `https://customissuetracker.com/project-name/:id`. |
   | **New issue URL** | Currently unused. Planned to be changed in a future release. |

1. Click **Test settings and save changes**.

After you configure and enable the Custom Issue Tracker service, you see a link on the GitLab
project pages that takes you to that custom issue tracker.

## Referencing issues

Issues are referenced with `<ANYTHING>-<ID>` (for example, `PROJECT-143`), where `<ANYTHING>` can be any string in CAPS, and `<ID>`
is a number used in the target project of the custom integration.

`<ANYTHING>` is a placeholder to differentiate against GitLab issues, which are referenced with `#<ID>`. You can use a project name or project key to replace it for example.

When building the hyperlink, the `<ANYTHING>` part is ignored, and links always point to the address
specified in `issues_url`, so in the example above, `PROJECT-143` would refer to
`https://customissuetracker.com/project-name/143`.
