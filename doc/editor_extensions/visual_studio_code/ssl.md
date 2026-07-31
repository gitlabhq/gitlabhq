---
stage: AI Clients
group: Developer Clients
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Use the VS Code extension with custom and self-signed certificates
---

You can use the GitLab for VS Code extension even if your GitLab instance uses
either a custom or self-signed SSL certificate.

## Use a custom certificate

In controlled enterprise environments, organizations often use custom
certificate authorities (CA). The GitLab for VS Code extension must trust these
certificates to communicate with your GitLab instance.

### Download the complete certificate chain

You must download the complete certificate chain. This includes:

- The root CA certificate.
- Any intermediate CA certificates.
- Optional. The server certificate (usually downloaded automatically).

Contact your IT or security team and request either of the following:

- The complete certificate chain in PEM format.
- Individual root and intermediate CA certificates.

#### Export the complete certificate chain

Instead of contacting your IT or security team, you can export the
complete certificate chain from your browser:

{{< tabs >}}

{{< tab title="Google Chrome & Microsoft Edge" >}}

1. Go to your GitLab instance.
1. Select the padlock icon in the address bar.
1. Select **Connection is secure** > **Certificate is valid**.
1. Go to the **Certification Path** tab.
1. Export each certificate in the chain starting from the root.

{{< /tab >}}

{{< tab title="Firefox" >}}

1. Go to your GitLab instance.
1. Select the padlock icon in the address bar.
1. Select **Connection secure** > **More information**.
1. Select **View Certificate**.
1. Download each certificate in the chain in PEM format.

{{< /tab >}}

{{< /tabs >}}

### Configure the custom certificate

You can configure the custom certificate in multiple ways.

#### Use the system certificate store

If your organization installs trusted certificate authorities at the operating system level, the
GitLab for VS Code extension automatically trusts these certificate authorities through the underlying
Node.js and VS Code runtime.

This works well in:

- Corporate-managed devices with pre-installed root and intermediate certificate authorities.
- Environments where other HTTPS tools already work without custom CA configuration.

Prerequisites:

- GitLab Workflow extension version 6.51.1 or later.
- VS Code version 1.101.2 or later.
- The `gitlab.ca` VS Code setting is not in use.

You do not have to configure any other GitLab extension settings in this scenario.

#### Specify a custom certificate file

Prerequisites:

- Have a [certificate bundle file in PEM format](#use-a-custom-certificate),
  with the full certificate chain. Every certificate must be concatenated in
  order from root to intermediate:

  ```plaintext
  -----BEGIN CERTIFICATE-----
  [Root CA Certificate]
  -----END CERTIFICATE-----
  -----BEGIN CERTIFICATE-----
  [Intermediate CA Certificate]
  -----END CERTIFICATE-----
  ```

1. Open VS Code.
1. Open the Command Palette:
   - On Windows and Linux: <kbd>Control</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>.
   - On macOS: <kbd>Command</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>.
1. Type "Preferences: Open User Settings (JSON)" and select it. The `settings.json` file opens.
1. Add the `gitlab.ca` setting with the absolute path to your certificate bundle
   file, replacing the example path with the actual path to your certificate file:

   {{< tabs >}}

   {{< tab title="macOS and Linux" >}}

   ```json
        {
         "gitlab.ca": "/etc/ssl/certs/ca-bundle.pem"
        }
   ```

   {{< /tab >}}

   {{< tab title="Windows" >}}

   ```json
       {
        "gitlab.ca": "C:\\certs\\ca-bundle.pem"
       }
   ```

   {{< /tab >}}

   {{< /tabs >}}

1. Save the file.
1. Reload VS Code for the changes to take effect.

#### Disable certificate verification

> [!warning]
> Disabling certificate verification is a security risk. Only disable verification for testing or development.

1. Open VS Code.
1. Open the Command Palette:
   - On Windows and Linux: <kbd>Control</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>.
   - On macOS: <kbd>Command</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>.
1. Type "Preferences: Open User Settings (JSON)" and select it. The `settings.json` file opens.
1. Add the following setting:

   ```json
   {
     "gitlab.ignoreCertificateErrors": true
   }
   ```

1. Save the file.
1. Reload VS Code for the changes to take effect.

## Use a self-signed SSL certificate

Prerequisites:

- Your GitLab instance uses a certificate signed with a self-signed certificate authority (CA).
- GitLab for VS Code version 6.51.1 or later.
- VS Code version 1.101.2 or later.
- The `gitlab.ca` VS Code setting is not in use.

> [!note]
> If you also use a proxy to connect to your GitLab instance, add a comment to [issue 314](https://gitlab.com/gitlab-org/gitlab-vscode-extension/-/issues/314).
> If you still have connection problems after completing these steps, review [epic 6244](https://gitlab.com/groups/gitlab-org/-/epics/6244), which links to all existing SSL issues for the GitLab for VS Code extension.

To use a self-signed SSL certificate:

1. Ensure your CA certificate is correctly added to your system for the extension to work. VS Code reads
   the system certificate store, and changes all node `http` requests to trust the certificates:

   ```mermaid
   %%{init: { "fontFamily": "GitLab Sans" }}%%
   graph LR
      accTitle: Self-signed certificate chain
      accDescr: Shows a self-signed CA that signs the GitLab instance certificate.

      A[Self-signed CA] -- signed --> B[Your GitLab instance certificate]
   ```

   The GitLab instance certificate's CA must be explicitly specified as a trusted CA. If intermediate certificates are in use, these must be available on the system. If the entire chain does not validate successfully, network connections within the extension fail to authenticate.

   For more information, see [Self-signed certificate error when installing Python support in WSL](https://github.com/microsoft/vscode/issues/131836#issuecomment-909983815) in the Visual Studio Code issue tracker.

1. In your VS Code `settings.json`, set `"http.systemCertificates": true`. The default value is `true`, so you might not need to change this value.
1. Complete the instructions in the following sections for your operating system.

### Windows

> [!note]
> These instructions were tested on Windows 10 and VS Code 1.60.0.

Make sure you can see your self-signed CA in your certificate store:

1. Open the command prompt.
1. Run `certmgr`.
1. Make sure you see your certificate in **Trusted Root Certification Authorities** > **Certificates**.

### Linux

> [!note]
> These instructions were tested on Arch Linux `5.14.3-arch1-1` and VS Code 1.60.0.

1. Use your operating system's tools to confirm you can add our self-signed CA to your system:
   - `update-ca-trust` (Fedora, RHEL, CentOS)
   - `update-ca-certificates` (Ubuntu, Debian, OpenSUSE, SLES)
   - `trust` (Arch)
1. Confirm the CA certificate is in `/etc/ssl/certs/ca-certificates.crt` or `/etc/ssl/certs/ca-bundle.crt`.
   VS Code [checks this location](https://github.com/microsoft/vscode/issues/131836#issuecomment-909983815).

### MacOS

> [!note]
> These instructions were tested on macOS Tahoe 26, VS Code 1.101.2, and GitLab for VS Code 6.51.1.

Make sure you see the self-signed CA in your keychain:

1. Go to **Finder** > **Applications** > **Utilities** > **Keychain Access**.
1. In the left-hand column, select **System**.
1. Find your self-signed CA certificate in the list.
1. Right-click the certificate and select **Get Info**.
1. Expand the **Trust** section.
1. Ensure the **Secure Sockets Layer (SSL)** option is set to 'Always Trust'.

## Related topics

- [VS Code network settings](https://code.visualstudio.com/docs/setup/network)
- [OpenSSL documentation](https://www.openssl.org/docs/)
- [GitLab SSL configuration](https://docs.gitlab.com/omnibus/settings/ssl.html)

## Troubleshooting

When working with custom and self-signed certificates in the VS Code extension,
you might encounter the following issues.

### Error: "...unable to verify the first certificate"

You might get an error that states "...unable to verify the first certificate".

This issue occurs when there are missing intermediate certificates in the chain.

To resolve this:

1. Verify you have the complete certificate chain.
1. Ensure all certificates are in PEM format.
1. Check that certificates are concatenated in the correct order (root > intermediate > leaf).

### Error: "...self signed certificate in certificate chain"

You might get an error that states "...self signed certificate in certificate chain".

This issue occurs when VS Code does not trust your organization's root CA.

To resolve this, do either of the following:

- Add your root CA to the certificate bundle.
- Enable the system certificate store if the CA is installed system-wide.

### Error: "...certificate has expired"

You might get an error that states "...certificate has expired".

This issue occurs when one or more certificates in the chain have expired.

To resolve this:

1. Request updated certificates from your IT or security team.
1. Check the certificate expiration dates by running `openssl x509 -in certificate.pem -noout -dates`.

### General troubleshooting steps

If you continue experiencing issues, try the following.

#### Check the extension logs

1. Open the Command Palette:
   - On Windows and Linux: <kbd>Control</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>.
   - On macOS: <kbd>Command</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>.
1. Type "Preferences: Open User Settings (JSON)" and select that option. The `settings.json` file opens.
1. Add the following to `settings.json` to enable detailed logging:

   ```json
   {
     "gitlab.debug": true
   }
   ```

1. To view the logs, in the Command Palette, type "GitLab: Show Extension Logs"
   and select it.
1. Look for certificate errors in the logs.

#### Verify the certificate chain configuration

1. Test the connection with the custom CA:

   ```shell
   curl --cacert /path/to/ca-bundle.pem "https://gitlab.example.com"
   ```

1. Check the certificate details:

   ```shell
   openssl x509 -in ca-bundle.pem -text -noout
   ```

1. Verify the certificate chain, replacing `server-cert.pem` with your server's
   certificate:

   ```shell
   openssl verify -CAfile ca-bundle.pem server-cert.pem
   ```

#### Contact support

- [GitLab Forum](https://forum.gitlab.com)
- [GitLab Discord](https://discord.gg/gitlab) `#vscode-extension` channel
- [Open an issue](https://gitlab.com/gitlab-org/gitlab-vscode-extension/-/issues)
- Contact your GitLab account team. Include the extension logs and certificate
  verification output.
