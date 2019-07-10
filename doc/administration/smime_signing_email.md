# Signing outgoing email with S/MIME

Notification emails sent by Gitlab can be signed with S/MIME for improved
security.

> **Note:**
Please be aware that S/MIME certificates and TLS/SSL certificates are not the
same and are used for different purposes: TLS creates a secure channel, whereas
S/MIME signs and/or encrypts the message itself

## Enable S/MIME signing

This setting must be explicitly enabled and a single pair of key and certificate
files must be provided in `gitlab.rb` or `gitlab.yml` if you are using Omnibus
GitLab or installed GitLab from source respectively:

```yaml
email_smime:
  enabled: true
  key_file: /etc/pki/smime/private/gitlab.key
  cert_file: /etc/pki/smime/certs/gitlab.crt
```

- Both files must be provided PEM-encoded.
- The key file must be unencrypted so that Gitlab can read it without user 
  intervention.

NOTE: **Note:** Be mindful of the access levels for your private keys and visibility to
third parties.

### How to convert S/MIME PKCS#12 / PFX format to PEM encoding

Typically S/MIME certificates are handled in binary PKCS#12 format (`.pfx` or `.p12`
extensions), which contain the following in a single encrypted file:

- Server certificate
- Intermediate certificates (if any)
- Private key

In order to export the required files in PEM encoding from the PKCS#12 file,
the `openssl` command can be used:

```bash
#-- Extract private key in PEM encoding (no password, unencrypted)
$ openssl pkcs12 -in gitlab.p12 -nocerts -nodes -out gitlab.key

#-- Extract certificates in PEM encoding (full certs chain including CA)
$ openssl pkcs12 -in gitlab.p12 -nokeys -out gitlab.crt
```
