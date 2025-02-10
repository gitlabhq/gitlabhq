---
stage: Plan
group: Knowledge
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Wiki settings
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab Self-Managed

Adjust the wiki settings of your GitLab instance.

## Wiki page content size limit

You can set a maximum content size limit for wiki pages. This limit can prevent
abuse of the feature. The default value is **52428800 Bytes** (50 MB).

### How does it work?

The content size limit is applied when a wiki page is created or updated
through the GitLab UI or API. Local changes pushed via Git are not validated.

To break any existing wiki pages, the limit doesn't take effect until a wiki page
is edited again and the content changes.

### Wiki page content size limit configuration

This setting is not available through the [**Admin** area settings](../settings/_index.md).
To configure this setting, use either the Rails console
or the [Application settings API](../../api/settings.md).

NOTE:
The value of the limit must be in bytes. The minimum value is 1024 bytes.

#### Through the Rails console

To configure this setting through the Rails console:

1. Start the Rails console:

   ```shell
   # For Omnibus installations
   sudo gitlab-rails console

   # For installations from source
   sudo -u git -H bundle exec rails console -e production
   ```

1. Update the wiki page maximum content size:

   ```ruby
   ApplicationSetting.first.update!(wiki_page_max_content_bytes: 50.megabytes)
   ```

To retrieve the current value, start the Rails console and run:

  ```ruby
  Gitlab::CurrentSettings.wiki_page_max_content_bytes
  ```

#### Through the API

To set the wiki page size limit through the Application Settings API, use a command,
as you would to [update any other setting](../../api/settings.md#update-application-settings):

```shell
curl --request PUT --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/application/settings?wiki_page_max_content_bytes=52428800"
```

You can also use the API to [retrieve the current value](../../api/settings.md#get-details-on-current-application-settings):

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/application/settings"
```

### Reduce wiki repository size

The wiki counts as part of the [namespace storage size](../settings/account_and_limit_settings.md),
so you should keep your wiki repositories as compact as possible.

For more information about tools to compact repositories,
read the documentation on [reducing repository size](../../user/project/repository/repository_size.md#methods-to-reduce-repository-size).

## Allow URI includes for AsciiDoc

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/348687) in GitLab 16.1.

Include directives import content from separate pages or external URLs,
and display them as part of the content of the current document. To enable
AsciiDoc includes, enable the feature through the Rails console or the API.

### Through the Rails console

To configure this setting through the Rails console:

1. Start the Rails console:

   ```shell
   # For Omnibus installations
   sudo gitlab-rails console

   # For installations from source
   sudo -u git -H bundle exec rails console -e production
   ```

1. Update the wiki to allow URI includes for AsciiDoc:

   ```ruby
   ApplicationSetting.first.update!(wiki_asciidoc_allow_uri_includes: true)
   ```

To check if includes are enabled, start the Rails console and run:

  ```ruby
  Gitlab::CurrentSettings.wiki_asciidoc_allow_uri_includes
  ```

### Through the API

To set the wiki to allow URI includes for AsciiDoc through the
[Application Settings API](../../api/settings.md#update-application-settings),
use a `curl` command:

```shell
curl --request PUT --header "PRIVATE-TOKEN: <your_access_token>" \
  "https://gitlab.example.com/api/v4/application/settings?wiki_asciidoc_allow_uri_includes=true"
```

## Related topics

- [User documentation for wikis](../../user/project/wiki/_index.md)
- [Project wikis API](../../api/wikis.md)
- [Group wikis API](../../api/group_wikis.md)
