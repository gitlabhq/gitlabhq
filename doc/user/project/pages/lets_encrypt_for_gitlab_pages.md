---
stage: Release
group: Release
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
description: "How to secure GitLab Pages websites with Let's Encrypt (manual process, deprecated)."
---

# Let's Encrypt for GitLab Pages (manual process, deprecated) **(FREE)**

WARNING:
This method is still valid but was **deprecated** in favor of the
[Let's Encrypt integration](custom_domains_ssl_tls_certification/lets_encrypt_integration.md)
introduced in GitLab 12.1.

If you have a GitLab Pages website served under your own domain,
you might want to secure it with a SSL/TLS certificate.

[Let's Encrypt](https://letsencrypt.org) is a free, automated, and
open source Certificate Authority.

## Requirements

To follow along with this tutorial, we assume you already have:

- [Created a project](index.md#getting-started) in GitLab
  containing your website's source code.
- Acquired a domain (`example.com`) and added a [DNS entry](custom_domains_ssl_tls_certification/index.md#set-up-pages-with-a-custom-domain)
  pointing it to your Pages website.
- [Added your domain to your Pages project](custom_domains_ssl_tls_certification/index.md#steps)
  and verified your ownership.
- Cloned your project into your computer.
- Your website up and running, served under HTTP protocol at `http://example.com`.

## Obtaining a Let's Encrypt certificate

Once you have the requirements addressed, follow the instructions
below to learn how to obtain the certificate.

Note that these instructions were tested on macOS Mojave. For other operating systems the steps
might be slightly different. Follow the
[CertBot instructions](https://certbot.eff.org/) according to your OS.

1. On your computer, open a terminal and navigate to your repository's
   root directory:

   ```shell
   cd path/to/dir
   ```

1. Install CertBot (the tool Let's Encrypt uses to issue certificates):

   ```shell
   brew install certbot
   ```

1. Request a certificate for your domain (`example.com`) and
   provide an email account (`your@email.com`) to receive notifications:

   ```shell
   sudo certbot certonly -a manual -d example.com --email your@email.com
   ```

   Alternatively, you can register without adding an email account,
   but you aren't notified about the certificate expiration's date:

   ```shell
   sudo certbot certonly -a manual -d example.com --register-unsafely-without-email
   ```

   NOTE:
   Read through CertBot's documentation on their
   [command line options](https://certbot.eff.org/docs/using.html#certbot-command-line-options).

1. You're prompted with a message to agree with their terms.
   Press `A` to agree and `Y` to let they log your IP.

   CertBot then prompts you with the following message:

   ```shell
   Create a file containing just this data:

   Rxnv6WKo95hsuLVX3osmT6LgmzsJKSaK9htlPToohOP.HUGNKk82jlsmOOfphlt8Jy69iuglsn095nxOMH9j3Yb

   And make it available on your web server at this URL:

   http://example.com/.well-known/acme-challenge/Rxnv6WKo95hsuLVX3osmT6LgmzsJKSaK9htlPToohOP

   Press Enter to Continue
   ```

1. **Do not press Enter yet.** Let's Encrypt needs to verify your
   domain ownership before issuing the certificate. To do so, create 3
   consecutive directories under your website's root:
   `/.well-known/acme-challenge/Rxnv6WKo95hsuLVX3osmT6LgmzsJKSaK9htlPToohOP/`
   and add to the last folder an `index.html` file containing the content
   referred on the previous prompt message:

   ```shell
   Rxnv6WKo95hsuLVX3osmT6LgmzsJKSaK9htlPToohOP.HUGNKk82jlsmOOfphlt8Jy69iuglsn095nxOMH9j3Yb
   ```

   Note that this file needs to be accessed under
   `http://example.com/.well-known/acme-challenge/Rxnv6WKo95hsuLVX3osmT6LgmzsJKSaK9htlPToohOP`
   to allow Let's Encrypt to verify the ownership of your domain,
   therefore, it needs to be part of the website content under the
   repository's [`public`](index.md#how-it-works) folder.

1. Add, commit, and push the file into your repository in GitLab. Once the pipeline
   passes, press **Enter** on your terminal to continue issuing your
   certificate. CertBot then prompts you with the following message:

   ```shell
   Waiting for verification...
   Cleaning up challenges

   IMPORTANT NOTES:
    - Congratulations! Your certificate and chain have been saved at:
      /etc/letsencrypt/live/example.com/fullchain.pem
      Your key file has been saved at:
      /etc/letsencrypt/live/example.com/privkey.pem
      Your cert will expire on 2019-03-12. To obtain a new or tweaked
      version of this certificate in the future, simply run certbot
      again. To non-interactively renew *all* of your certificates, run
      "certbot renew"
    - If you like Certbot, please consider supporting our work by:

      Donating to ISRG / Let's Encrypt:   https://letsencrypt.org/donate
      Donating to EFF:                    https://eff.org/donate-le
   ```

## Add your certificate to GitLab Pages

Now that your certificate has been issued, let's add it to your Pages site:

1. Back at GitLab, navigate to your project's **Settings > Pages**,
   find your domain and click **Details** and **Edit** to add your certificate.
1. From your terminal, copy and paste the certificate into the first field
   **Certificate (PEM)**:

   ```shell
   sudo cat /etc/letsencrypt/live/example.com/fullchain.pem | pbcopy
   ```

1. Copy and paste the private key into the second field **Key (PEM)**:

   ```shell
   sudo cat /etc/letsencrypt/live/example.com/privkey.pem | pbcopy
   ```

1. Click **Save changes** to apply them to your website.
1. Wait a few minutes for the configuration changes to take effect.
1. Visit your website at `https://example.com`.

To force `https` connections on your site, navigate to your
project's **Settings > Pages** and check **Force HTTPS (requires
valid certificates)**.

## Renewal

Let's Encrypt certificates expire every 90 days and you must
renew them periodically. To renew all your certificates at once, run:

```shell
sudo certbot renew
```
