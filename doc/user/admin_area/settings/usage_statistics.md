---
type: reference
---

# Usage statistics **(CORE ONLY)**

GitLab Inc. will periodically collect information about your instance in order
to perform various actions.

All statistics are opt-out. You can enable/disable them in the
**Admin Area > Settings > Metrics and profiling** section **Usage statistics**.

## Network configuration

Allow network traffic from your GitLab instance to IP address `104.196.17.203:443`, to send
usage statistics to GitLab Inc.

If your GitLab instance is behind a proxy, set the appropriate [proxy configuration variables](https://docs.gitlab.com/omnibus/settings/environment-variables.html).

## Version Check **(CORE ONLY)**

If enabled, version check will inform you if a new version is available and the
importance of it through a status. This is shown on the help page (i.e. `/help`)
for all signed in users, and on the admin pages. The statuses are:

- Green: You are running the latest version of GitLab.
- Orange: An updated version of GitLab is available.
- Red: The version of GitLab you are running is vulnerable. You should install
  the latest version with security fixes as soon as possible.

![Orange version check example](img/update-available.png)

GitLab Inc. collects your instance's version and hostname (through the HTTP
referer) as part of the version check. No other information is collected.

This information is used, among other things, to identify to which versions
patches will need to be backported, making sure active GitLab instances remain
secure.

If you disable version check, this information will not be collected. Enable or
disable the version check in **Admin Area > Settings > Metrics and profiling > Usage statistics**.

### Request flow example

The following example shows a basic request/response flow between the self-managed GitLab instance
and the GitLab Version Application:

```mermaid
sequenceDiagram
    participant GitLab instance
    participant Version Application
    GitLab instance->>Version Application: Is there a version update?
    loop Version Check
        Version Application->>Version Application: Record version info
    end
    Version Application->>GitLab instance: Response (PNG/SVG)
```

## Usage Ping **(CORE ONLY)**

See [Usage Ping guide](../../../development/telemetry/usage_ping.md).

## Instance statistics visibility **(CORE ONLY)**

Once usage ping is enabled, GitLab will gather data from other instances and
will be able to show [usage statistics](../../instance_statistics/index.md)
of your instance to your users.

To make this visible only to admins, go to **Admin Area > Settings > Metrics and profiling**, expand
**Usage statistics**, and set the **Instance Statistics visibility** option to **Only admins**.

<!-- ## Troubleshooting

Include any troubleshooting steps that you can foresee. If you know beforehand what issues
one might have when setting this up, or when something is changed, or on upgrading, it's
important to describe those, too. Think of things that may go wrong and include them here.
This is important to minimize requests for support, and to avoid doc comments with
questions that you know someone might ask.

Each scenario can be a third-level heading, e.g. `### Getting error message X`.
If you have none to add when creating a doc, leave this section in place
but commented out to help encourage others to add to it in the future. -->
