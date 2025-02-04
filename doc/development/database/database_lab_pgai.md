---
stage: Data Access
group: Database Frameworks
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: Database Lab access using the `pgai` Ruby gem
---

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
      dblab init --url "http://127.0.0.1:<local-port>" --token TOKEN --environment-id <environment-id>
      ```

      ```shell
      ssh -NTML <local-port>:localhost:<instance-port> <instance-host> -i ~/.ssh/id_rsa
      ```

1. To configure `ssh`, follow the instruction at [Access the console with `psql`](database_lab.md#access-the-console-with-psql), replacing `${USER}` with your postgres.ai username.

1. Run the following commands:

   ```shell
   gem install pgai

   # Before running the following command,
   # grab an access token from https://console.postgres.ai/gitlab/tokens
   pgai config --prefix=<postgresai-user>

   # Grab the respective port values from https://console.postgres.ai/gitlab/instances
   # for the instances you'll be using (in this case, for the `main` database instance)
   pgai env add --alias main --id <instance-host> --port <instance-port> -n <database_name>
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
