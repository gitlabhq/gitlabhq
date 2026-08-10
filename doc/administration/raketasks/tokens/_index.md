---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Access token Rake tasks
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/467416) in GitLab 17.2.

{{< /history >}}

## Analyze token expiration dates

In GitLab 16.0, a [background migration](https://gitlab.com/gitlab-org/gitlab/-/issues/369123)
gave all non-expiring personal, project, and group access tokens an expiration date set at one
year after those tokens were created.

To identify which tokens might have been affected by this migration, you can run a
Rake task that analyses all access tokens and displays the top ten most common expiration dates:

   {{< tabs >}}

   {{< tab title="Linux package (Omnibus)" >}}

   ```shell
   gitlab-rake gitlab:tokens:analyze
   ```

   {{< /tab >}}

   {{< tab title="Helm chart (Kubernetes)" >}}

   ```shell
   # Find the toolbox pod
   kubectl --namespace <namespace> get pods -lapp=toolbox
   kubectl exec -it <toolbox-pod-name> -- sh -c 'cd /srv/gitlab && bin/rake gitlab:tokens:analyze'
   ```

   {{< /tab >}}

   {{< tab title="Docker" >}}

   ```shell
   sudo docker exec -it <container_name> /bin/bash
   gitlab-rake gitlab:tokens:analyze
   ```

   {{< /tab >}}

   {{< tab title="Self-compiled (source)" >}}

   ```shell
   sudo RAILS_ENV=production -u git -H bundle exec rake gitlab:tokens:analyze
   ```

   {{< /tab >}}

   {{< /tabs >}}

This task analyzes all the access tokens and groups them by expiration date.
The left column shows the expiration date, and the right column shows how many tokens
have that expiration date. Example output:

```plaintext
======= Personal/Project/Group Access Token Expiration Migration =======
Started at: 2023-06-15 10:20:35 +0000
Finished  : 2023-06-15 10:23:01 +0000
===== Top 10 Personal/Project/Group Access Token Expiration Dates =====
| Expiration Date | Count |
|-----------------|-------|
| 2024-06-15      | 1565353 |
| 2017-12-31      | 2508  |
| 2018-01-01      | 1008  |
| 2016-12-31      | 833   |
| 2017-08-31      | 705   |
| 2017-06-30      | 596   |
| 2018-12-31      | 548   |
| 2017-05-31      | 523   |
| 2017-09-30      | 520   |
| 2017-07-31      | 494   |
========================================================================
```

In this example, you can see that over 1.5 million access tokens have an
expiration date of 2024-06-15, one year after the migration was run
on 2023-06-15. This suggests that most of these tokens were assigned by
the migration. However, there is no way to know for sure whether other
tokens were created manually with the same date.

The top 10 dates can include dates in the past, and a `(none)` row for tokens with no expiration
date. Read the dates and not only the counts when you look for an upcoming mass expiration.

## Update expiration dates in bulk

Prerequisites:

You must:

- Be an administrator.
- Have an interactive terminal.

Run the following Rake task to extend or remove expiration dates from tokens in bulk:

1. Run the tool:

   {{< tabs >}}

   {{< tab title="Linux package (Omnibus)" >}}

   ```shell
   gitlab-rake gitlab:tokens:edit
   ```

   {{< /tab >}}

   {{< tab title="Helm chart (Kubernetes)" >}}

   ```shell
   # Find the toolbox pod
   kubectl --namespace <namespace> get pods -lapp=toolbox
   kubectl exec -it <toolbox-pod-name> -- sh -c 'cd /srv/gitlab && bin/rake gitlab:tokens:edit'
   ```

   {{< /tab >}}

   {{< tab title="Docker" >}}

   ```shell
   sudo docker exec -it <container_name> /bin/bash
   gitlab-rake gitlab:tokens:edit
   ```

   {{< /tab >}}

   {{< tab title="Self-compiled (source)" >}}

   ```shell
   sudo RAILS_ENV=production -u git -H bundle exec rake gitlab:tokens:edit
   ```

   {{< /tab >}}

   {{< /tabs >}}

   After the tool starts, it shows the output from the [analyze step](#analyze-token-expiration-dates)
   plus an additional prompt about modifying the expiration dates:

   ```plaintext
   ======= Personal/Project/Group Access Token Expiration Migration =======
   Started at: 2023-06-15 10:20:35 +0000
   Finished  : 2023-06-15 10:23:01 +0000
   ===== Top 10 Personal/Project/Group Access Token Expiration Dates =====
   | Expiration Date | Count |
   |-----------------|-------|
   | 2024-05-14      | 1565353 |
   | 2017-12-31      | 2508  |
   | 2018-01-01      | 1008  |
   | 2016-12-31      | 833   |
   | 2017-08-31      | 705   |
   | 2017-06-30      | 596   |
   | 2018-12-31      | 548   |
   | 2017-05-31      | 523   |
   | 2017-09-30      | 520   |
   | 2017-07-31      | 494   |
   ========================================================================
   What do you want to do? (Press ↑/↓ arrow or 1-3 number to move and Enter to select)
   ‣ 1. Extend expiration date
     2. Remove expiration date
     3. Quit
   ```

### Extend expiration dates

The task sets the selected expiration date on every token, including revoked tokens and
impersonation tokens. The count shown before you confirm the action includes these tokens.

To extend expiration dates on all tokens matching a given expiration date:

1. Select option 1, `Extend expiration date`:

   ```plaintext
   What do you want to do?
   ‣ 1. Extend expiration date
     2. Remove expiration date
     3. Quit
   ```

1. The tool asks you to select one of the expiration dates listed. For example:

   ```plaintext
   Select an expiration date (Press ↑/↓/←/→ arrow to move and Enter to select)
   ‣ 2024-05-14
     2017-12-31
     2018-01-01
     2016-12-31
     2017-08-31
     2017-06-30
   ```

   Use the arrow keys on your keyboard to select a date. To abort,
   scroll all the way down and select `--> Abort`. Press <kbd>Enter</kbd> to confirm
   your selection:

   ```plaintext
   Select an expiration date
     2017-06-30
     2018-12-31
     2017-05-31
     2017-09-30
     2017-07-31
   ‣ --> Abort
   ```

   If you select a date, the tool prompts you for a new expiration date:

   ```plaintext
   What would you like the new expiration date to be? (2025-05-14) 2024-05-14
   ```

   The default is one year from the selected date. Press <kbd>Enter</kbd>
   to use the default, or manually enter a date in `YYYY-MM-DD` format.

1. After you have entered a valid date, the tool asks one more time for confirmation:

   ```plaintext
   Old expiration date: 2024-05-14
   New expiration date: 2025-05-14
   WARNING: This will now update 1565353 token(s). Are you sure? (y/N)
   ```

   If you enter `y`, the tool extends the expiration date
   for all the tokens with the selected expiration date.

   If you enter `N`, the tool aborts the update task and return to the
   original analyze output.

### Remove expiration dates

To remove expiration dates on all tokens matching
a given expiration date:

1. Select option 2, `Remove expiration date`:

   ```plaintext
   What do you want to do?
     1. Extend expiration date
   ‣ 2. Remove expiration date
     3. Quit
   ```

1. The tool asks you to select the expiration date from the table. For example:

   ```plaintext
   Select an expiration date (Press ↑/↓/←/→ arrow to move and Enter to select)
   ‣ 2024-05-14
     2017-12-31
     2018-01-01
     2016-12-31
     2017-08-31
     2017-06-30
   ```

   Use the arrow keys on your keyboard to select a date. To abort,
   scroll all the way down and select `--> Abort`. Press <kbd>Enter</kbd> to confirm
   your selection:

   ```plaintext
   Select an expiration date
     2017-06-30
     2018-12-31
     2017-05-31
     2017-09-30
     2017-07-31
   ‣ --> Abort
   ```

1. After selecting a date, the tool prompts you to confirm the selection:

   ```plaintext
   WARNING: This will remove the expiration for tokens that expire on 2024-05-14.
   This will affect 1565353 tokens. Are you sure? (y/N)
   ```

   If you enter `y`, the tool removes the expiration date for all the
   tokens with the selected expiration date.

   If you enter `N`, the tool aborts the update task and returns to the first menu.

## Find tokens the Rake tasks do not report

The `gitlab:tokens:analyze` task groups tokens by expiration date and reports how many share each
date. It does not list individual tokens, and it reports only the 10 most common dates.

For personal access tokens, use the
[personal access tokens API](../../../api/personal_access_tokens.md) instead. Administrators can list
every personal access token in the instance and filter with `expires_before` and `expires_after`.

The project and group access token APIs filter by expiration date for a single project or group only.
To sweep an entire instance for project and group access tokens, run the following script in the
[Rails console](../../operations/rails_console.md).

To list project and group access tokens that expire in a given date range:

```ruby
# Any duration works. For example: 1.week, 90.days, 6.months, 1.year.
date_range = 1.month

PersonalAccessToken.project_access_token.where(expires_at: Date.today .. Date.today + date_range).find_each do |token|
  token.user.members.each do |member|
    type = member.is_a?(GroupMember) ? 'Group' : 'Project'

    puts "Expiring #{type} access token in #{type} ID #{member.source_id}, Token ID: #{token.id}, Name: #{token.name}, Scopes: #{token.scopes}, Last used: #{token.last_used_at}"
  end
end
```

To list project and group access tokens that have no expiration date, replace the `expires_at`
condition with `expires_at: nil`, and change `Expiring` in the message to `No expiration date for`.

## Validate custom issuer URL configuration for CI/CD ID Tokens

If you configure a non-public GitLab instance with [OpenID Connect in AWS to retrieve temporary credentials](../../../ci/cloud_services/aws/_index.md#configure-a-non-public-gitlab-instance),
use the `ci:validate_id_token_configuration` Rake task to validate the token configuration:

```shell
bundle exec rake ci:validate_id_token_configuration
```
