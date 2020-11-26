---
type: reference, howto
stage: Create
group: Knowledge
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Wiki settings **(CORE ONLY)**

Adjust the wiki settings of your GitLab instance.

## Wiki page content size limit

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/31176) in GitLab 13.2.

You can set a maximum content size limit for wiki pages. This limit can prevent
abuse of the feature. The default value is **52428800 Bytes** (50 MB).

### How does it work?

The content size limit will be applied when a wiki page is created or updated
through the GitLab UI or API. Local changes pushed via Git will not be validated.

In order not to break any existing wiki pages, the limit doesn't have any
effect on them until a wiki page is edited again and the content changes.

### Wiki page content size limit configuration

This setting is not available through the [Admin Area settings](../../user/admin_area/settings/index.md).
In order to configure this setting, use either the Rails console
or the [Application settings API](../../api/settings.md).

NOTE: **Note:**
The value of the limit **must** be in bytes. The minimum value is 1024 bytes.

#### Through the Rails console

The steps to configure this setting through the Rails console are:

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

The process to set the wiki page size limit through the Application Settings API is
exactly the same as you would do to [update any other setting](../../api/settings.md#change-application-settings).

```shell
curl --request PUT --header "PRIVATE-TOKEN: <your_access_token>" https://gitlab.example.com/api/v4/application/settings?wiki_page_max_content_bytes=52428800
```

You can also use the API to [retrieve the current value](../../api/settings.md#get-current-application-settings).

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" https://gitlab.example.com/api/v4/application/settings
```
