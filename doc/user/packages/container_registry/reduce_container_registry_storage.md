---
stage: Package
group: Container Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Reduce container registry storage

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, Self-managed, GitLab Dedicated

Container registries can grow in size over time if you don't manage your registry usage. For example,
if you add a large number of images or tags:

- Retrieving the list of available tags or images becomes slower.
- They take up a large amount of storage space on the server.

You should delete unnecessary images and tags and set up a [cleanup policy](#cleanup-policy)
to automatically manage your container registry usage.

## View container registry usage

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com

> - [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/5523) in GitLab 15.7

To view the storage usage for the container registry:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Settings > Usage Quotas**.

You cannot view container registry usage for self-managed instances, but this is
proposed in [epic 5521](https://gitlab.com/groups/gitlab-org/-/epics/5521).

## How container registry usage is calculated

Image layers stored in the container registry are deduplicated at the root namespace level.

An image is only counted once if:

- You tag the same image more than once in the same repository.
- You tag the same image across distinct repositories under the same root namespace.

An image layer is only counted once if:

- You share the image layer across multiple images in the same container repository, project, or group.
- You share the image layer across different repositories.

Only layers that are referenced by tagged images are accounted for. Untagged images and any layers
referenced exclusively by them are subject to [online garbage collection](../container_registry/delete_container_registry_images.md#garbage-collection).
Untagged image layers are automatically deleted after 24 hours if they remain unreferenced during that period.

Image layers are stored on the storage backend in the original (usually compressed) format. This
means that the measured size for any given image layer should match the size displayed on the
corresponding [image manifest](https://github.com/opencontainers/image-spec/blob/main/manifest.md#example-image-manifest).

Namespace usage is refreshed a few minutes after a tag is pushed or deleted from any container repository under the namespace.

### Delayed refresh

It is not possible to calculate container registry usage
with maximum precision in real time for extremely large namespaces (about 1% of namespaces).
To enable maintainers of these namespaces to see their usage, there is a delayed fallback mechanism.
See [epic 9413](https://gitlab.com/groups/gitlab-org/-/epics/9413) for more details.

If the usage for a namespace cannot be calculated with precision, GitLab falls back to the delayed method.
In the delayed method, the displayed usage size is the sum of **all** unique image layers
in the namespace. Untagged image layers are not ignored. As a result,
the displayed usage size might not change significantly after deleting tags. Instead,
the size value only changes when:

- An automated [garbage collection process](../container_registry/delete_container_registry_images.md#garbage-collection)
  runs and deletes untagged image layers. After a user deletes a tag, a garbage collection run
  is scheduled to start 24 hours later. During that run, images that were previously tagged
  are analyzed and their layers deleted if not referenced by any other tagged image.
  If any layers are deleted, the namespace usage is updated.
- The namespace's registry usage shrinks enough that GitLab can measure it with maximum precision.
  As usage for namespaces shrinks to be under the [limits](../../../user/usage_quotas.md#namespace-storage-limit),
  the measurement switches automatically from delayed to precise usage measurement.
  There is no place in the UI to determine which measurement method is being used,
  but [issue 386468](https://gitlab.com/gitlab-org/gitlab/-/issues/386468) proposes to improve this.

## Cleanup policy

> - [Renamed](https://gitlab.com/gitlab-org/gitlab/-/issues/218737) from "expiration policy" to "cleanup policy" in GitLab 13.2.
> - [Required permissions](https://gitlab.com/gitlab-org/gitlab/-/issues/350682) changed from developer to maintainer in GitLab 15.0.

The cleanup policy is a scheduled job you can use to remove tags from the container registry.
For the project where it's defined, tags matching the regex pattern are removed.
The underlying layers and images remain.

To delete the underlying layers and images that aren't associated with any tags, administrators can use
[garbage collection](../../../administration/packages/container_registry.md#removing-untagged-manifests-and-unreferenced-layers) with the `-m` switch.

### Enable the cleanup policy

You can run cleanup policies on all projects with these exceptions:

- For self-managed GitLab instances, the project must have been created
  in GitLab 12.8 or later. However, an administrator can enable the cleanup policy
  for all projects (even those created before GitLab 12.8) in
  [GitLab application settings](../../../api/settings.md#change-application-settings)
  by setting `container_expiration_policies_enable_historic_entries` to true.
  Alternatively, you can execute the following command in the [Rails console](../../../administration/operations/rails_console.md#starting-a-rails-console-session):

  ```ruby
  ApplicationSetting.last.update(container_expiration_policies_enable_historic_entries: true)
  ```

  Enabling cleanup policies on all projects can impact performance, especially if you
  are using an [external registry](#use-with-external-container-registries).

WARNING:
For performance reasons, enabled cleanup policies are automatically disabled for projects on
GitLab.com that don't have a container image.

### How the cleanup policy works

The cleanup policy collects all tags in the container registry and excludes tags until the only
tags you want to delete remain.

The cleanup policy searches for images based on the tag name. Support for full path matching is tracked in issue [281071](https://gitlab.com/gitlab-org/gitlab/-/issues/281071).

The cleanup policy:

1. Collects all tags for a given repository in a list.
1. Excludes the tag named `latest`.
1. Evaluates the `name_regex` (tags to expire), excluding non-matching names.
1. Excludes any tags matching the `name_regex_keep` value (tags to preserve).
1. Excludes any tags that do not have a manifest (not part of the options in the UI).
1. Orders the remaining tags by `created_date`.
1. Excludes the N tags based on the `keep_n` value (Number of tags to retain).
1. Excludes the tags more recent than the `older_than` value (Expiration interval).
1. Deletes the remaining tags in the list from the container registry.

WARNING:
On GitLab.com, the execution time for the cleanup policy is limited. Some tags may remain in
the container registry after the policy runs. The next time the policy runs, the remaining tags are included.
It may take multiple runs to delete all tags.

WARNING:
GitLab self-managed installations support third-party container registries that comply with the
[Docker Registry HTTP API V2](https://distribution.github.io/distribution/spec/api/)
specification. However, this specification does not include a tag delete operation. Therefore, GitLab uses a
workaround to delete tags when interacting with third-party container registries. Refer to
issue [15737](https://gitlab.com/gitlab-org/gitlab/-/issues/15737)
for more information. Due to possible implementation variations, this workaround is not guaranteed
to work with all third-party registries in the same predictable way. If you use the GitLab Container
Registry, this workaround is not required because we implemented a special tag delete operation. In
this case, you can expect cleanup policies to be consistent and predictable.

#### Example cleanup policy workflow

The interaction between the keep and remove rules for the cleanup policy can be complex.
For example, with a project with this cleanup policy configuration:

- **Keep the most recent**: 1 tag per image name.
- **Keep tags matching**: `production-.*`
- **Remove tags older than**: 7 days.
- **Remove tags matching**: `.*`.

And a container repository with these tags:

- `latest`, published 2 hours ago.
- `production-v44`, published 3 days ago.
- `production-v43`, published 6 days ago.
- `production-v42`, published 11 days ago.
- `dev-v44`, published 2 days ago.
- `dev-v43`, published 5 day ago.
- `dev-v42`, published 10 days ago.
- `v44`, published yesterday.
- `v43`, published 12 days ago.
- `v42`, published 20 days ago.

In this example, the tags that would be deleted in the next cleanup run are `dev-v42`, `v43`, and `v42`.
You can interpret the rules as applying with this precedence:

1. The keep rules have highest precedence. Tags must be kept when they match **any** rule.
   - The `latest` tag must be kept, because `latest` tags are always kept.
   - The `production-v44`, `production-v43`, and `production-v42` tags must be kept,
     because they match the **Keep tags matching** rule.
   - The `v44` tag must be kept because it's the most recent, matching the **Keep the most recent** rule.
1. The remove rules have lower precedence, and tags are only deleted if **all** rules match.
   For the tags not matching any keep rules (`dev-44`, `dev-v43`, `dev-v42`, `v43`, and `v42`):
   - `dev-44` and `dev-43` do **not** match the **Remove tags older than**, and are kept.
   - `dev-v42`, `v43`, and `v42` match both **Remove tags older than** and **Remove tags matching**
     rules, so these three tags can be deleted.

### Create a cleanup policy

You can create a cleanup policy in [the API](#use-the-cleanup-policy-api) or the UI.

To create a cleanup policy in the UI:

1. For your project, go to **Settings > Packages and registries**.
1. In the **Cleanup policies** section, select **Set cleanup rules**.
1. Complete the fields:

   | Field                      | Description |
   |----------------------------|-------------|
   | **Toggle**                 | Turn the policy on or off. |
   | **Run cleanup**            | How often the policy should run. |
   | **Keep the most recent**   | How many tags to _always_ keep for each image. |
   | **Keep tags matching**     | A regex pattern that determines which tags to preserve. The `latest` tag is always preserved. For all tags, use `.*`. See other [regex pattern examples](#regex-pattern-examples). |
   | **Remove tags older than** | Remove only tags older than X days. |
   | **Remove tags matching**   | A regex pattern that determines which tags to remove. This value cannot be blank. For all tags, use `.*`. See other [regex pattern examples](#regex-pattern-examples). |

1. Select **Save**.

The policy runs on the scheduled interval you selected.

NOTE:
If you edit the policy and select **Save** again, the interval is reset.

### Regex pattern examples

Cleanup policies use regex patterns to determine which tags should be preserved or removed, both in the UI and the API.

Regex patterns are automatically surrounded with `\A` and `\Z` anchors. Therefore, you do not need to include any
`\A`, `\Z`, `^` or `$` tokens in the regex patterns.

Here are some examples of regex patterns you can use:

- Match all tags:

  ```plaintext
  .*
  ```

  This pattern is the default value for the expiration regex.

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

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/288812) in GitLab 13.9 [with a flag](../../../administration/feature_flags.md) named `container_registry_expiration_policies_throttling`. Disabled by default.
> - [Enabled by default](https://gitlab.com/groups/gitlab-org/-/epics/2270) in GitLab 14.9.
> - [Removed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/84996) the feature flag `container_registry_expiration_policies_throttling` in GitLab 15.0.

Cleanup policies are executed as a background process. This process is complex, and depending on the number of tags to delete,
the process can take time to finish.

You can use the following application settings to prevent server resource starvation:

- `container_registry_expiration_policies_worker_capacity`: the maximum number of cleanup workers
  running concurrently. This value must be greater than or equal to `0`. You should start with a low
  number and increase it after monitoring the resources used by the background workers. To remove
  all workers and not execute the cleanup policies, set this to `0`. The default value is `4`.
- `container_registry_delete_tags_service_timeout`: the maximum time (in seconds) that the cleanup
  process can take to delete a batch of tags. The default value is `250`.
- `container_registry_cleanup_tags_service_max_list_size`: the maximum number of tags that can be
  deleted in a single execution. Additional tags must be deleted in another execution. You should
  start with a low number and increase it after verifying that container images are properly
  deleted. The default value is `200`.
- `container_registry_expiration_policies_caching`: enable or disable tag creation timestamp caching
  during execution of policies. Cached timestamps are stored in [Redis](../../../development/architecture.md#redis).
  Enabled by default.

For self-managed instances, those settings can be updated in the [Rails console](../../../administration/operations/rails_console.md#starting-a-rails-console-session):

```ruby
ApplicationSetting.last.update(container_registry_expiration_policies_worker_capacity: 3)
```

They are also available in the [Admin Area](../../../administration/admin_area.md):

1. On the left sidebar, at the bottom, select **Admin Area**.
1. Select **Settings > CI/CD**
1. Expand **Container Registry**.

### Use the cleanup policy API

You can set, update, and disable the cleanup policies using the GitLab API.

Examples:

- Select all tags, keep at least 1 tag per image, clean up any tag older than 14 days, run once a month, preserve
  any images with the name `main`, and the policy is enabled:

  ```shell
  curl --request PUT --header 'Content-Type: application/json;charset=UTF-8' --header "PRIVATE-TOKEN: <your_access_token>" \
       --data-binary '{"container_expiration_policy_attributes":{"cadence":"1month","enabled":true,"keep_n":1,"older_than":"14d","name_regex":".*","name_regex_keep":".*-main"}}' \
       "https://gitlab.example.com/api/v4/projects/2"
  ```

Valid values for `cadence` when using the API are:

- `1d` (every day)
- `7d` (every week)
- `14d` (every two weeks)
- `1month` (every month)
- `3month` (every quarter)

Valid values for `keep_n` (number of tags kept per image name) when using the API are:

- `1`
- `5`
- `10`
- `25`
- `50`
- `100`

Valid values for `older_than` (days until tags are automatically removed) when using the API are:

- `7d`
- `14d`
- `30d`
- `90d`

See the API documentation for further details: [Edit project API](../../../api/projects.md#edit-project).

### Use with external container registries

When using an [external container registry](../../../administration/packages/container_registry.md#use-an-external-container-registry-with-gitlab-as-an-auth-endpoint),
running a cleanup policy on a project may have some performance risks.
If a project runs a policy to remove thousands of tags,
the GitLab background jobs may get backed up or fail completely.
For projects created before GitLab 12.8, you should enable container cleanup policies
only if the number of tags being cleaned up is minimal.

## More container registry storage reduction options

Here are some other options you can use to reduce the container registry storage used by your project:

- Use the [GitLab UI](delete_container_registry_images.md#use-the-gitlab-ui)
  to delete individual image tags or the entire repository containing all the tags.
- Use the API to [delete individual image tags](../../../api/container_registry.md#delete-a-registry-repository-tag).
- Use the API to [delete the entire container registry repository containing all the tags](../../../api/container_registry.md#delete-registry-repository).
- Use the API to [delete registry repository tags in bulk](../../../api/container_registry.md#delete-registry-repository-tags-in-bulk).

## Troubleshooting cleanup policies

### `Something went wrong while updating the cleanup policy.`

If you see this error message, check the regex patterns to ensure they are valid.

GitLab uses [RE2 syntax](https://github.com/google/re2/wiki/Syntax) for regular expressions in the cleanup policy. You can test them with the [regex101 regex tester](https://regex101.com/) using the `Golang` flavor.
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

  - Extend the expiration delay of the container registry authentication tokens. This defaults to 5
    minutes. You can set a custom value by running
    `ApplicationSetting.last.update(container_registry_token_expire_delay: <integer>)` in the Rails
    console, where `<integer>` is the desired number of minutes. For reference, the expiration delay
    is set to 15 minutes on GitLab.com. If you increase this value you increase the
    time required to revoke permissions.

Alternatively, you can generate a list of tags to delete, and use that list to delete
the tags. To create the list and delete the tags:

1. Run the following shell script. The command just before the `for` loop ensures that
   `list_o_tags.out` is always reinitialized when starting the loop. After running this command, all
   the tags' names are written to the `list_o_tags.out` file:

   ```shell
   # Get a list of all tags in a certain container repository while considering [pagination](../../../api/rest/index.md#pagination)
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

1. Remove any tags that you want to keep from the `list_o_tags.out` file. For example, you can use `sed` to
   parse the file and remove the tags.

   ::Tabs

   :::TabTitle Linux

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

   :::TabTitle macOS

   ```shell
   # Remove the `latest` tag from the file
   sed -i .bak '/latest/d' list_o_tags.out

   # Remove the first N tags from the file
   sed -i .bak '1,Nd' list_o_tags.out

   # Remove the tags starting with `Av` from the file
   sed -i .bak '/^Av/d' list_o_tags.out

   # Remove the tags ending with `_v3` from the file
   sed -i .bak '/_v3$/d' list_o_tags.out
   ```

   ::EndTabs

1. Double-check the `list_o_tags.out` file to make sure it contains only the tags that you want to
   delete.

1. Run this shell script to delete the tags in the `list_o_tags.out` file:

   ```shell
   # loop over list_o_tags.out to delete a single tag at a time
   while read -r LINE || [[ -n $LINE ]]; do echo ${LINE}; curl --request DELETE --header 'PRIVATE-TOKEN: <PAT>' "https://gitlab.example.com/api/v4/projects/<Project_id>/registry/repositories/<container_repo_id>/tags/${LINE}"; sleep 0.1; echo; done < list_o_tags.out > delete.logs
   ```
