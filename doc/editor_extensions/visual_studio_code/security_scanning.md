---
stage: AI-powered
group: Editor Extensions
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Use the GitLab for VS Code extension to perform and review security scans.
title: Secure your application in GitLab for VS Code
---

Use the GitLab for VS Code extension to check your application for security vulnerabilities. Review
security findings and run static application security testing (SAST) for files directly in your IDE.

## View security findings

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Prerequisites:

- GitLab for VS Code 3.74.0 or later.
- A project that includes [Security Risk Management](https://about.gitlab.com/features/?stage=secure)
  features, such as static application security testing (SAST), dynamic application security testing
  (DAST), container scanning, or dependency scanning.
- Configured [security risk management](../../user/application_security/secure_your_application.md)
  features.

To view security findings:

1. In VS Code, on the left sidebar, select **GitLab** ({{< icon name="tanuki" >}}).
1. In the current branch section, expand **Security scanning**.
1. Select either **New findings** or **Fixed findings**.
1. Select a severity level.
1. Select a finding to open it in a VS Code tab.

## Perform SAST scanning

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com
- Status: Experiment

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab-vscode-extension/-/issues/1675) in VS Code extension 5.31.

{{< /history >}}

Static application security testing (SAST) in VS Code detects vulnerabilities in the active file.
With early detection, you can remediate vulnerabilities before you merge your changes into the
default branch.

When you trigger a SAST scan, the content of the active file is passed to GitLab and checked against
SAST vulnerability rules. GitLab shows scan results in the **GitLab** ({{< icon name="tanuki" >}})
extension panel.

<i class="fa-youtube-play" aria-hidden="true"></i>
To learn about setting up SAST scanning, see
[SAST scanning in VS Code](https://www.youtube.com/watch?v=s-qOSQO0i-8) on GitLab Unfiltered.
<!-- Video published on 2025-02-10 -->

Prerequisites:

- GitLab for VS Code 5.31.0 or later.
- The extension is [authenticated with GitLab](setup.md#authenticate-with-gitlab).
- Real-time SAST scan is [enabled](setup.md#code-security).

To perform SAST scanning of a file in VS Code:

<!-- markdownlint-disable MD044 -->

1. Open the file.
1. Trigger the SAST scan by either:
   - Saving the file (if you have enabled [scanning on file save](setup.md#code-security)).
   - Using the Command Palette:
     1. Open the Command Palette:
        - For macOS, press <kbd>Command</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>.
        - For Windows or Linux, press <kbd>Control</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>.
     1. Search for **GitLab: Run Remote Scan (SAST)** and press <kbd>Enter</kbd>.
1. View the results of the SAST scan.
   1. In VS Code, on the left sidebar, select **GitLab** ({{< icon name="tanuki" >}}).
   1. Expand the GitLab remote scan (SAST) section. The results of the SAST scan are listed in
      descending order by severity.
   1. Select a finding to review the details.

<!-- markdownlint-enable MD044 -->