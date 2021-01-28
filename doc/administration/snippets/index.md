---
type: reference, howto
stage: Create
group: Editor
info: "To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments"
---

# Snippets settings **(FREE SELF)**

Adjust the snippets' settings of your GitLab instance.

## Snippets content size limit

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/31133) in GitLab 12.6.

You can set a maximum content size limit for snippets. This limit can prevent
abuse of the feature. The default value is **52428800 Bytes** (50 MB).

### How does it work?

The content size limit is applied when a snippet is created or updated.

This limit doesn't affect existing snippets until they're updated and their
content changes.

### Snippets size limit configuration

This setting is not available through the [Admin Area settings](../../user/admin_area/settings/index.md).
In order to configure this setting, use either the Rails console
or the [Application settings API](../../api/settings.md).

NOTE:
The value of the limit **must** be in bytes.

#### Through the Rails console

The steps to configure this setting through the Rails console are:

1. Start the Rails console:

   ```shell
   # For Omnibus installations
   sudo gitlab-rails console

   # For installations from source
   sudo -u git -H bundle exec rails console -e production
   ```

1. Update the snippets maximum file size:

   ```ruby
   ApplicationSetting.first.update!(snippet_size_limit: 50.megabytes)
   ```

To retrieve the current value, start the Rails console and run:

  ```ruby
  Gitlab::CurrentSettings.snippet_size_limit
  ```

#### Through the API

To set the snippets size limit through the Application Settings API (similar to
[updating any other setting](../../api/settings.md#change-application-settings)), use this command:

```shell
curl --request PUT --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/application/settings?snippet_size_limit=52428800"
```

You can also use the API to [retrieve the current value](../../api/settings.md#get-current-application-settings).

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/application/settings"
```
