---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Custom Git clients in the Code dropdown list
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed
- Status: Beta

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/604390) in GitLab 19.5 [with a flag](../feature_flags/_index.md) named `custom_code_dropdown_clients`. Disabled by default.

{{< /history >}}

> [!flag]
> The availability of this feature is controlled by a feature flag. For more information, see the history.

Add custom clients to the **Open with** section of the **Code** dropdown list on project pages.
Users can then clone a repository directly into a Git client that GitLab doesn't list by default.

## Configure custom clients

Prerequisites:

- You must be an administrator.
- The `custom_code_dropdown_clients` feature flag must be enabled.

To configure entries:

1. In the upper-right corner, select **Admin**.
1. Select **Settings** > **Repository**.
1. Expand **General**.
1. Select **Add client**.
1. Complete the fields.
   Enter at least one URL template.
   - **Display name**: The label shown to users in the dropdown list. Not translated.
   - **SSH URL template**: The URL opened when a user selects **SSH**.
   - **HTTPS URL template**: The URL opened when a user selects **HTTPS**.
1. Select **Add**.

To edit an entry, next to it select **Edit client** ({{< icon name="pencil" >}}),
update the fields, then select **Save**.

To delete an entry, next to it select **Delete client** ({{< icon name="remove" >}}),
then in the confirmation dialog select **Delete client**.

You can configure up to 20 entries.

## URL templates

Each URL template must contain the placeholder `{url}` exactly once.
When the Code dropdown list is rendered, GitLab replaces the placeholder server-side
with the project's percent-encoded clone URL.

### Allowed URL schemes

Enter the scheme expected by the client you're integrating.
Any URL scheme is accepted, except the following, which a browser can use to run
scripts or read local files:

- `javascript`
- `data`
- `vbscript`
- `file`
- `blob`
- `filesystem`
- `about`

Selecting an entry passes the URL to whichever application the user's operating
system has registered for that scheme.

> [!note]
> GitLab cannot verify what that application does with the URL. Add only clients you trust.

If no application is registered for the scheme on the user's operating system, the
browser cannot open the link.

### Examples

The following entries have been verified against vendor documentation.

Always confirm the current URI scheme against the official documentation of the
client you're integrating, before publishing the entry to your users.

| Display name | SSH URL template | HTTPS URL template | Source |
|---|---|---|---|
| VSCodium | `vscodium://vscode.git/clone?url={url}` | `vscodium://vscode.git/clone?url={url}` | [VSCodium prepare_vscode.sh](https://github.com/VSCodium/vscodium/blob/master/prepare_vscode.sh) registers `urlProtocol` as `vscodium`, reusing the upstream VS Code `vscode.git/clone` handler. |
| Tower | `gittower://openRepo/{url}` | `gittower://openRepo/{url}` | [Tower documentation (macOS)](https://www.git-tower.com/help/guides/integration/url-scheme/mac), [Tower documentation (Windows)](https://www.git-tower.com/help/guides/integration/url-scheme/windows) |
| Sourcetree, Fork | `sourcetree://cloneRepo?cloneUrl={url}` | `sourcetree://cloneRepo?cloneUrl={url}` | Fork intercepts the same scheme. |

Some clients are not compatible with the single `{url}` placeholder model. For example,
GitKraken and GitHub Desktop need extra per-repository parameters. Other clients (such
as Zed and Working Copy) appear in third-party documentation but lack an official vendor
URI scheme reference. Verify with the vendor before adding such entries.
