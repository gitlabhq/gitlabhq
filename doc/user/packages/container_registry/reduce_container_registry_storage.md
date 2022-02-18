---
stage: Package
group: Package
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Reduce Container Registry Storage **(FREE)**

Container registries become large over time without cleanup. When a large number of images or tags are added:

- Fetching the list of available tags or images becomes slower.
- They take up a large amount of storage space on the server.

We recommend deleting unnecessary images and tags, and setting up a [cleanup policy](#cleanup-policy)
to automatically manage your container registry usage.

## Check Container Registry Storage Use

The Usage Quotas page (**Settings > Usage Quotas > Storage**) displays storage usage for Packages,
which doesn't include the Container Registry. To track work on this, see the epic
[Storage management for the Container Registry](https://gitlab.com/groups/gitlab-org/-/epics/7226).

## Cleanup policy

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/15398) in GitLab 12.8.
> - [Renamed](https://gitlab.com/gitlab-org/gitlab/-/issues/218737) from "expiration policy" to "cleanup policy" in GitLab 13.2.

The cleanup policy is a scheduled job you can use to remove tags from the Container Registry.
For the project where it's defined, tags matching the regex pattern are removed.
The underlying layers and images remain.

To delete the underlying layers and images that aren't associated with any tags, administrators can use
[garbage collection](../../../administration/packages/container_registry.md#removing-untagged-manifests-and-unreferenced-layers) with the `-m` switch.

### Enable the cleanup policy

Cleanup policies can be run on all projects, with these exceptions:

- For self-managed GitLab instances, the project must have been created
  in GitLab 12.8 or later. However, an administrator can enable the cleanup policy
  for all projects (even those created before 12.8) in
  [GitLab application settings](../../../api/settings.md#change-application-settings)
  by setting `container_expiration_policies_enable_historic_entries` to true.
  Alternatively, you can execute the following command in the [Rails console](../../../administration/operations/rails_console.md#starting-a-rails-console-session):

  ```ruby
  ApplicationSetting.last.update(container_expiration_policies_enable_historic_entries: true)
  ```

  There are performance risks with enabling it for all projects, especially if you
  are using an [external registry](#use-with-external-container-registries).
- For self-managed GitLab instances, you can enable or disable the cleanup policy for a specific
  project.

  To enable it:

  ```ruby
  Feature.enable(:container_expiration_policies_historic_entry, Project.find(<project id>))
  ```

  To disable it:

  ```ruby
  Feature.disable(:container_expiration_policies_historic_entry, Project.find(<project id>))
  ```

WARNING:
For performance reasons, enabled cleanup policies are automatically disabled for projects on
GitLab.com that don't have a container image.

### How the cleanup policy works

The cleanup policy collects all tags in the Container Registry and excludes tags
until only the tags to be deleted remain.

The cleanup policy searches for images based on the tag name. Support for the full path [has not yet been implemented](https://gitlab.com/gitlab-org/gitlab/-/issues/281071), but would allow you to clean up dynamically-named tags.

The cleanup policy:

1. Collects all tags for a given repository in a list.
1. Excludes the tag named `latest` from the list.
1. Evaluates the `name_regex` (tags to expire), excluding non-matching names from the list.
1. Excludes from the list any tags matching the `name_regex_keep` value (tags to preserve).
1. Excludes any tags that do not have a manifest (not part of the options in the UI).
1. Orders the remaining tags by `created_date`.
1. Excludes from the list the N tags based on the `keep_n` value (Number of tags to retain).
1. Excludes from the list the tags more recent than the `older_than` value (Expiration interval).
1. Finally, the remaining tags in the list are deleted from the Container Registry.

WARNING:
On GitLab.com, the execution time for the cleanup policy is limited, and some of the tags may remain in
the Container Registry after the policy runs. The next time the policy runs, the remaining tags are included,
so it may take multiple runs for all tags to be deleted.

WARNING:
GitLab self-managed installs support for third-party container registries that comply with the
[Docker Registry HTTP API V2](https://docs.docker.com/registry/spec/api/)
specification. However, this specification does not include a tag delete operation. Therefore, when
interacting with third-party container registries, GitLab uses a workaround to delete tags. See the
[related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/15737)
for more information. Due to possible implementation variations, this workaround is not guaranteed
to work with all third-party registries in the same predictable way. If you use the GitLab Container
Registry, this workaround is not required because we implemented a special tag delete operation. In
this case, you can expect cleanup policies to be consistent and predictable.

### Create a cleanup policy

You can create a cleanup policy in [the API](#use-the-cleanup-policy-api) or the UI.

To create a cleanup policy in the UI:

1. For your project, go to **Settings > Packages & Registries**.
1. Expand the **Clean up image tags** section.
1. Complete the fields.

   | Field                                                                     | Description                                                                                                       |
   |---------------------------------------------------------------------------|-------------------------------------------------------------------------------------------------------------------|
   | **Toggle** | Turn the policy on or off. |
   | **Run cleanup** | How often the policy should run. |
   | **Keep the most recent** | How many tags to _always_ keep for each image. |
   | **Keep tags matching** | The regex pattern that determines which tags to preserve. The `latest` tag is always preserved. For all tags, use `.*`. See other [regex pattern examples](#regex-pattern-examples). |
   | **Remove tags older than** | Remove only tags older than X days. |
   | **Remove tags matching**  | The regex pattern that determines which tags to remove. This value cannot be blank. For all tags, use `.*`. See other [regex pattern examples](#regex-pattern-examples). |

1. Click **Save**.

Depending on the interval you chose, the policy is scheduled to run.

NOTE:
If you edit the policy and click **Save** again, the interval is reset.

### Regex pattern examples

Cleanup policies use regex patterns to determine which tags should be preserved or removed, both in the UI and the API.

Regex patterns are automatically surrounded with `\A` and `\Z` anchors. Do not include any `\A`, `\Z`, `^` or `$` token in the regex patterns as they are not necessary.

Here are examples of regex patterns you may want to use:

- Match all tags:

  ```plaintext
  .*
  ```

  This is the default value for the expiration regex.

- Match tags that start with `v`:

  ```plaintext
  v.+
  ```

- Match only the tag named `main`:

  ```plaintext
  main
  ```

- Match tags that are either named or start with `release`:

  ```plaintext
  release.*
  ```

- Match tags that either start with `v`, are named `main`, or begin with `release`:

  ```plaintext
  (?:v.+|main|release.*)
  ```

### Set cleanup limits to conserve resources

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/288812) in GitLab 13.9.
> - It's [deployed behind a feature flag](../../feature_flags.md), disabled by default.
> - It's enabled on GitLab.com.
> - It's not recommended for production use.
> - To use it in GitLab self-managed instances, ask a GitLab administrator to [enable it](#enable-or-disable-cleanup-policy-limits).

Cleanup policies are executed as a background process. This process is complex, and depending on the number of tags to delete,
the process can take time to finish.

To prevent server resource starvation, the following application settings are available:

- `container_registry_expiration_policies_worker_capacity`. The maximum number of cleanup workers running concurrently. This must be greater than `1`.
   We recommend starting with a low number and increasing it after monitoring the resources used by the background workers.
- `container_registry_delete_tags_service_timeout`. The maximum time, in seconds, that the cleanup process can take to delete a batch of tags.
- `container_registry_cleanup_tags_service_max_list_size`. The maximum number of tags that can be deleted in a single execution. Additional tags must be deleted in another execution.
   We recommend starting with a low number, like `100`, and increasing it after monitoring that container images are properly deleted.

For self-managed instances, those settings can be updated in the [Rails console](../../../administration/operations/rails_console.md#starting-a-rails-console-session):

  ```ruby
  ApplicationSetting.last.update(container_registry_expiration_policies_worker_capacity: 3)
  ```

Alternatively, once the limits are [enabled](#enable-or-disable-cleanup-policy-limits),
they are available in the [administrator area](../../admin_area/index.md):

1. On the top bar, select **Menu > Admin**.
1. Go to **Settings > CI/CD > Container Registry**.

#### Enable or disable cleanup policy limits

The cleanup policies limits are under development and not ready for production use. They are
deployed behind a feature flag that is **disabled by default**.
[GitLab administrators with access to the GitLab Rails console](../../../administration/feature_flags.md)
can enable it.

To enable it:

```ruby
Feature.enable(:container_registry_expiration_policies_throttling)
```

To disable it:

```ruby
Feature.disable(:container_registry_expiration_policies_throttling)
```

### Use the cleanup policy API

You can set, update, and disable the cleanup policies using the GitLab API.

Examples:

- Select all tags, keep at least 1 tag per image, clean up any tag older than 14 days, run once a month, preserve any images with the name `main` and the policy is enabled:

  ```shell
  curl --request PUT --header 'Content-Type: application/json;charset=UTF-8' --header "PRIVATE-TOKEN: <your_access_token>" \
       --data-binary '{"container_expiration_policy_attributes":{"cadence":"1month","enabled":true,"keep_n":1,"older_than":"14d","name_regex":"","name_regex_delete":".*","name_regex_keep":".*-main"}}' \
       "https://gitlab.example.com/api/v4/projects/2"
  ```

Valid values for `cadence` when using the API are:

- `1d` (every day)
- `7d` (every week)
- `14d` (every two weeks)
- `1month` (every month)
- `3month` (every quarter)

See the API documentation for further details: [Edit project](../../../api/projects.md#edit-project).

### Use with external container registries

When using an [external container registry](../../../administration/packages/container_registry.md#use-an-external-container-registry-with-gitlab-as-an-auth-endpoint),
running a cleanup policy on a project may have some performance risks.
If a project runs a policy to remove thousands of tags
the GitLab background jobs may get backed up or fail completely.
It is recommended you only enable container cleanup
policies for projects that were created before GitLab 12.8 if you are confident the number of tags
being cleaned up is minimal.

## More Container Registry storage reduction options

Here are some other options to reduce your project's use of Container Registry storage:

- Use the [GitLab UI](index.md#delete-images)
  to delete individual image tags or the entire repository containing all the tags.
- Use the API to [delete individual image tags](../../../api/container_registry.md#delete-a-registry-repository-tag).
- Use the API to [delete the entire container registry repository containing all the tags](../../../api/container_registry.md#delete-registry-repository).
- Use the API to [delete registry repository tags in bulk](../../../api/container_registry.md#delete-registry-repository-tags-in-bulk).

## Troubleshooting cleanup policies

### `Something went wrong while updating the cleanup policy.`

If you see this error message, check the regex patterns to ensure they are valid.

GitLab uses [RE2 syntax](https://github.com/google/re2/wiki/Syntax) for regular expressions in the cleanup policy. You can test them with the [regex101 regex tester](https://regex101.com/).
View some common [regex pattern examples](#regex-pattern-examples).

### The cleanup policy doesn't delete any tags

There can be different reasons behind this:

- In GitLab 13.6 and earlier, when you run the cleanup policy you may expect it to delete tags and
  it does not. This occurs when the cleanup policy is saved without editing the value in the
  **Remove tags matching** field. This field has a grayed out `.*` value as a placeholder. Unless
  `.*` (or another regex pattern) is entered explicitly into the field, a `nil` value is submitted.
  This value prevents the saved cleanup policy from matching any tags. As a workaround, edit the
  cleanup policy. In the **Remove tags matching** field, enter `.*` and save. This value indicates
  that all tags should be removed.

- If you are on GitLab self-managed instances and you have 1000+ tags in a container repository, you
  might run into a [Container Registry token expiration issue](https://gitlab.com/gitlab-org/gitlab/-/issues/288814),
  with `error authorizing context: invalid token` in the logs.

  To fix this, there are two workarounds:

  - If you are on GitLab 13.9 or later, you can [set limits for the cleanup policy](reduce_container_registry_storage.md#set-cleanup-limits-to-conserve-resources).
    This limits the cleanup execution in time, and avoids the expired token error.

  - Extend the expiration delay of the Container Registry authentication tokens. This defaults to 5
    minutes. You can set a custom value by running
    `ApplicationSetting.last.update(container_registry_token_expire_delay: <integer>)` in the Rails
    console, where `<integer>` is the desired number of minutes. For reference, 15 minutes is the
    value currently in use for GitLab.com. Be aware that by extending this value you increase the
    time required to revoke permissions.

If the previous fixes didn't work or you are on earlier versions of GitLab, you can generate a list
of the tags that you want to delete, and then use that list to delete the tags. To do this, follow
these steps:

1. Run the following shell script. The command just before the `for` loop ensures that
   `list_o_tags.out` is always reinitialized when starting the loop. After running this command, all
   the tags' names will be in the `list_o_tags.out` file:

   ```shell
   # Get a list of all tags in a certain container repository while considering [pagination](../../../api/index.md#pagination)
   echo -n "" > list_o_tags.out; for i in {1..N}; do curl --header 'PRIVATE-TOKEN: <PAT>' "https://gitlab.example.com/api/v4/projects/<Project_id>/registry/repositories/<container_repo_id>/tags?per_page=100&page=${i}" | jq '.[].name' | sed 's:^.\(.*\).$:\1:' >> list_o_tags.out; done
   ```

   If you have Rails console access, you can enter the following commands to retrieve a list of tags limited by date:

   ```shell
   output = File.open( "/tmp/list_o_tags.out","w" )
   Project.find(<Project_id>).container_repositories.find(<container_repo_id>).tags.each do |tag|
     output << tag.name + "\n" if tag.created_at < 1.month.ago
   end;nil
   output.close
   ```

   This set of commands creates a `/tmp/list_o_tags.out` file listing all tags with a `created_at` date of older than one month.

1. Remove from the `list_o_tags.out` file any tags that you want to keep. Here are some example
   `sed` commands for this. Note that these commands are simply examples. You may change them to
   best suit your needs:

   ```shell
   # Remove the `latest` tag from the file
   sed -i '/latest/d' list_o_tags.out

   # Remove the first N tags from the file
   sed -i '1,Nd' list_o_tags.out

   # Remove the tags starting with `Av` from the file
   sed -i '/^Av/d' list_o_tags.out

   # Remove the tags ending with `_v3` from the file
   sed -i '/_v3$/d' list_o_tags.out
   ```

   If you are running macOS, you must add `.bak` to the commands. For example:

   ```shell
   sed -i .bak '/latest/d' list_o_tags.out
   ```

1. Double-check the `list_o_tags.out` file to make sure it contains only the tags that you want to
   delete.

1. Run this shell script to delete the tags in the `list_o_tags.out` file:

   ```shell
   # loop over list_o_tags.out to delete a single tag at a time
   while read -r LINE || [[ -n $LINE ]]; do echo ${LINE}; curl --request DELETE --header 'PRIVATE-TOKEN: <PAT>' "https://gitlab.example.com/api/v4/projects/<Project_id>/registry/repositories/<container_repo_id>/tags/${LINE}"; sleep 0.1; echo; done < list_o_tags.out > delete.logs
   ```
