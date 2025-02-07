---
stage: Create
group: Source Code
info: "To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments"
description: "Configure snippets settings for your GitLab instance."
title: Snippets
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab Self-Managed

You can configure a maximum size for a snippet to prevent abuse.
The default limit is 52428800 bytes (50 MB).
The limit is applied when a snippet is created or updated.
The limit does not affect existing snippets unless they are updated and their
content changes.

## Configure the snippet size limit

To configure the snippet size limit, you can use the Rails console
or the [Application settings API](../../api/settings.md).

The limit **must** be in bytes.

This setting is not available in the [**Admin** area settings](../settings/_index.md).

### Use the Rails console

To configure this setting through the Rails console:

1. [Start the Rails console](../operations/rails_console.md#starting-a-rails-console-session).
1. Update the snippets maximum file size:

   ```ruby
   ApplicationSetting.first.update!(snippet_size_limit: 50.megabytes)
   ```

To retrieve the current value, start the Rails console and run:

  ```ruby
  Gitlab::CurrentSettings.snippet_size_limit
  ```

### Use the API

To set the limit by using the Application Settings API
(similar to [updating any other setting](../../api/settings.md#update-application-settings)),
use this command:

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>"
  --url "https://gitlab.example.com/api/v4/application/settings?snippet_size_limit=52428800"
```

You can also use the API to [retrieve the current value](../../api/settings.md#get-details-on-current-application-settings).

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/application/settings"
```

## Related topics

- [User snippets](../../user/snippets.md)
