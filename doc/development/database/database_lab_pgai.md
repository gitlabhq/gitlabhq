---
stage: Data Stores
group: Database
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
---

# Database Lab access using the `pgai` Ruby gem

WARNING:
The `pgai` gem has not yet been updated to use the new database lab instances so you will only be able to access `gitlab-production-main` and `gitlab-production-ci` using this tool.

[@mbobin](https://gitlab.com/mbobin) created the [`pgai` Ruby Gem](https://gitlab.com/mbobin/pgai/#pgai) that
greatly simplifies access to a database clone, with support for:

- Access to all database clones listed in the [Postgres.ai instances page](https://console.postgres.ai/gitlab/instances);
- Multiple `psql` sessions on the same clone.

If you have `AllFeaturesUser` [`psql` access](database_lab.md#access-database-lab-engine),
you can follow the steps below to configure the `pgai` Gem:

1. To get started, you need to gather some values from the [Postgres.ai instances page](https://console.postgres.ai/gitlab/instances):

   1. Go to the instance that you want to configure and the on right side of the screen.
   1. Under **Connection**, select **Connect**. The menu might be collapsed.

      A dialog with everything that's needed for configuration appears, using this format:

      ```shell
      dblab init --url "http://127.0.0.1:1234" --token TOKEN --environment-id <environment-id>
      ```

      ```shell
      ssh -NTML 1234:localhost:<environment-port> <postgresai-user>@<postgresai-proxy> -i ~/.ssh/id_rsa
      ```

1. Add the following snippet to your SSH configuration file at `~/.ssh/config`, replacing the variable values:

   ```plaintext
   Host pgai-proxy
     HostName <postgresai-proxy>
     User <postgresai-user>
     IdentityFile ~/.ssh/id_ed25519
   ```

1. Run the following command so you can accept the server key fingerprint:

   ```shell
   ssh pgai-proxy
   ```

1. Run the following commands:

   ```shell
   gem install pgai

   # Grab an access token: https://console.postgres.ai/gitlab/tokens
   # GITLAB_USER is your GitLab handle
   pgai config --dbname=gitlabhq_dblab --prefix=$GITLAB_USER --proxy=pgai-proxy

   # Grab the respective port values from https://console.postgres.ai/gitlab/instances
   # for the instances you'll be using (in this case, for the `main` database instance)
   pgai env add --alias main --id <environment-id> --port <environment-port>
   ```

1. Once this one-time configuration is done, you can use `pgai connect` to connect to a particular database. For
   instance, to connect to the `main` database:

   ```shell
   pgai connect main
   ```

1. Once done with the clone, you can destroy it:

   ```shell
   pgai destroy main
   ```
