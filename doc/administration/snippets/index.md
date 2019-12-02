---
type: reference, howto
---

# Snippets settings **(CORE ONLY)**

Adjust the snippets' settings of your GitLab instance.

## Snippets content size limit

> [Introduced](https://gitlab.com/gitlab-org/gitlab/issues/31133) in GitLab 12.6.

You can set a content size max limit in snippets. This limit can prevent
abuses of the feature. The default content size limit is **52428800 Bytes** (50MB).

### How does it work?

The content size limit will be applied when a snippet is created or
updated. Nevertheless, in order not to break any existing snippet,
the limit will only be enforced in stored snippets when the content
is updated.

### Snippets size limit configuration

This setting is not available through the [Admin Area settings](../../user/admin_area/settings/index.md).
In order to configure this setting, use either the Rails console
or the [Application settings API](../../api/settings.md).

NOTE: **IMPORTANT:**
The value of the limit **must** be in Bytes.

#### Through the Rails console

The steps to configure this setting through the Rails console are:

1. Start the Rails console:

   ```bash
   # For Omnibus installations
   sudo gitlab-rails console

   # For installations from source
   sudo -u git -H bundle exec rails console production
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

The process to set the snippets size limit through the Application Settings API is
exactly the same as you would do to [update any other setting](../../api/settings.md#change-application-settings).

```bash
curl --request PUT --header "PRIVATE-TOKEN: <your_access_token>" https://gitlab.example.com/api/v4/application/settings?snippet_size_limit=52428800
```

You can also use the API to [retrieve the current value](../../api/settings.md#get-current-application-settings).

```bash
curl --header "PRIVATE-TOKEN: <your_access_token>" https://gitlab.example.com/api/v4/application/settings
```
