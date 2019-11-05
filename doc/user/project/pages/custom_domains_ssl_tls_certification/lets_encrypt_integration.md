---
type: reference
description: "Automatic Let's Encrypt SSL certificates for GitLab Pages."
---

# GitLab Pages integration with Let's Encrypt

> [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/issues/28996) in GitLab 12.1. For versions earlier than GitLab 12.1, see the [manual Let's Encrypt instructions](../lets_encrypt_for_gitlab_pages.md).
This feature is in **beta** and may still have bugs. See all the related issues linked from this [issue's description](https://gitlab.com/gitlab-org/gitlab-foss/issues/28996) for more information.

The GitLab Pages integration with Let's Encrypt (LE) allows you
to use LE certificates for your Pages website with custom domains
without the hassle of having to issue and update them yourself;
GitLab does it for you, out-of-the-box.

[Let's Encrypt](https://letsencrypt.org) is a free, automated, and
open source Certificate Authority.

CAUTION: **Caution:**
This feature covers only certificates for **custom domains**, not the wildcard certificate required to run [Pages daemon](../../../../administration/pages/index.md) **(CORE ONLY)**. Wildcard certificate generation is tracked in [this issue](https://gitlab.com/gitlab-org/omnibus-gitlab/issues/3342).

## Requirements

Before you can enable automatic provisioning of an SSL certificate for your domain, make sure you have:

- Created a [project](../getting_started_part_two.md) in GitLab
  containing your website's source code.
- Acquired a domain (`example.com`) and added a [DNS entry](index.md)
  pointing it to your Pages website.
- [Added your domain to your Pages project](index.md#1-add-a-custom-domain-to-pages)
  and verified your ownership.
- Verified your website is up and running, accessible through your custom domain.

NOTE: **Note:**
GitLab's Let's Encrypt integration is enabled and available on GitLab.com.
For **self-managed** GitLab instances, make sure your administrator has
[enabled it](../../../../administration/pages/index.md#lets-encrypt-integration).

## Enabling Let's Encrypt integration for your custom domain

Once you've met the requirements, enable Let's Encrypt integration:

1. Navigate to your project's **Settings > Pages**.
1. Find your domain and click **Details**.
1. Click **Edit** in the top-right corner.
1. Enable Let's Encrypt integration by switching **Automatic certificate management using Let's Encrypt**:

   ![Enable Let's Encrypt](img/lets_encrypt_integration_v12_1.png)

1. Click **Save changes**.

Once enabled, GitLab will obtain a LE certificate and add it to the
associated Pages domain. It also will be renewed automatically by GitLab.

> **Notes:**
>
> - Issuing the certificate and updating Pages configuration
>   **can take up to an hour**.
> - If you already have SSL certificate in domain settings it
>   will continue to work until it will be replaced by Let's Encrypt's certificate.

## Troubleshooting

### Error "Certificate misses intermediates"

If you get an error **Certificate misses intermediates** while trying to enable Let's Encrypt integration for your domain, follow the steps below:

1. Go to your project's **Settings > Pages**.
1. Turn off **Force HTTPS** if it's turned on.
1. Click **Details** on your domain.
1. Click the **Edit** button in the top right corner of domain details page.
1. Enable Let's Encrypt integration.
1. Click **Save**.
1. Go to your project's **Settings > Pages**.
1. Turn on **Force HTTPS**.

<!-- Include any troubleshooting steps that you can foresee. If you know beforehand what issues
one might have when setting this up, or when something is changed, or on upgrading, it's
important to describe those, too. Think of things that may go wrong and include them here.
This is important to minimize requests for support, and to avoid doc comments with
questions that you know someone might ask.

Each scenario can be a third-level heading, e.g. `### Getting error message X`.
If you have none to add when creating a doc, leave this section in place
but commented out to help encourage others to add to it in the future. -->
