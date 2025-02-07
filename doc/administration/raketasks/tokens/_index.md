---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Access token Rake tasks
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab Self-Managed

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/467416) in GitLab 17.2.

## Analyze token expiration dates

In GitLab 16.0, a [background migration](https://gitlab.com/gitlab-org/gitlab/-/issues/369123)
gave all non-expiring personal, project, and group access tokens an expiration date set at one
year after those tokens were created.

To identify which tokens might have been affected by this migration, you can run a
Rake task that analyses all access tokens and displays the top ten most common expiration dates:

   ::Tabs

   :::TabTitle Linux package (Omnibus)

   ```shell
   gitlab-rake gitlab:tokens:analyze
   ```

   :::TabTitle Helm chart (Kubernetes)

   ```shell
   # Find the toolbox pod
   kubectl --namespace <namespace> get pods -lapp=toolbox
   kubectl exec -it <toolbox-pod-name> -- sh -c 'cd /srv/gitlab && bin/rake gitlab:tokens:analyze'
   ```

   :::TabTitle Docker

   ```shell
   sudo docker exec -it <container_name> /bin/bash
   gitlab-rake gitlab:tokens:analyze
   ```

   :::TabTitle Self-compiled (source)

   ```shell
   sudo RAILS_ENV=production -u git -H bundle exec rake gitlab:tokens:analyze
   ```

   ::EndTabs

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

## Update expiration dates in bulk

Prerequisites:

You must:

- Be an administrator.
- Have an interactive terminal.

Run the following Rake task to extend or remove expiration dates from tokens in bulk:

1. Run the tool:

   ::Tabs

   :::TabTitle Linux package (Omnibus)

   ```shell
   gitlab-rake gitlab:tokens:edit
   ```

   :::TabTitle Helm chart (Kubernetes)

   ```shell
   # Find the toolbox pod
   kubectl --namespace <namespace> get pods -lapp=toolbox
   kubectl exec -it <toolbox-pod-name> -- sh -c 'cd /srv/gitlab && bin/rake gitlab:tokens:edit'
   ```

   :::TabTitle Docker

   ```shell
   sudo docker exec -it <container_name> /bin/bash
   gitlab-rake gitlab:tokens:edit
   ```

   :::TabTitle Self-compiled (source)

   ```shell
   sudo RAILS_ENV=production -u git -H bundle exec rake gitlab:tokens:edit
   ```

   ::EndTabs

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
