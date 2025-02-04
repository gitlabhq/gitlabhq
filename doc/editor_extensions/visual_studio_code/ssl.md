---
stage: Create
group: Editor Extensions
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Using the VS Code extension with self-signed certificates
---

You can still use the GitLab Workflow extension for VS Code even if your GitLab instance uses a self-signed SSL certificate.

If you also use a proxy to connect to your GitLab instance, let us know in
[issue 314](https://gitlab.com/gitlab-org/gitlab-vscode-extension/-/issues/314). If you still have connection problems
after completing these steps, review [epic 6244](https://gitlab.com/groups/gitlab-org/-/epics/6244), which links to
all existing SSL issues for the GitLab Workflow extension.

## Use the extension with a self-signed CA

Prerequisites:

- Your GitLab instance uses a certificate signed with a self-signed certificate authority (CA).

1. Ensure your CA certificate is correctly added to your system for the extension to work. VS Code reads
   the system certificate store, and changes all node `http` requests to trust the certificates:

   ```mermaid
   graph LR;
   A[Self-signed CA] -- signed --> B[Your GitLab instance certificate]
   ```

   For more information, see [Self-signed certificate error when installing Python support in WSL](https://github.com/microsoft/vscode/issues/131836#issuecomment-909983815) in the Visual Studio Code issue queue.

1. In your VS Code `settings.json`, set `"http.systemCertificates": true`. The default value is `true`, so you might not need to change this value.
1. Follow the instructions for your operating system:

### Windows

NOTE:
These instructions were tested on Windows 10 and VS Code 1.60.0.

Make sure you can see your self-signed CA in your certificate store:

1. Open the command prompt.
1. Run `certmgr`.
1. Make sure you see your certificate in **Trusted Root Certification Authorities > Certificates**.

### Linux

NOTE:
These instructions were tested on Arch Linux `5.14.3-arch1-1` and VS Code 1.60.0.

1. Use your operating system's tools to confirm you can add our self-signed CA to your system:
   - `update-ca-trust` (Fedora, RHEL, CentOS)
   - `update-ca-certificates` (Ubuntu, Debian, OpenSUSE, SLES)
   - `trust` (Arch)
1. Confirm the CA certificate is in `/etc/ssl/certs/ca-certificates.crt` or `/etc/ssl/certs/ca-bundle.crt`.
   VS Code [checks this location](https://github.com/microsoft/vscode/issues/131836#issuecomment-909983815).

### MacOS

NOTE:
These instructions are untested, but should work as intended. If you can confirm this setup,
create a documentation issue with more information.

Make sure you see the self-signed CA in your keychain:

1. Go to **Finder > Applications > Utilities > Keychain Access**.
1. In the left-hand column, select **System**.
1. Your self-signed CA certificate should be on the list.
