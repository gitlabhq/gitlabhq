---
stage: Data Stores
group: Database
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Database Lab and Postgres.ai

Internal users at GitLab have access to the Database Lab Engine (DLE) and
[postgres.ai](https://console.postgres.ai/) for testing performance of database queries
on replicated production data. Unlike a typical read-only production replica, in the DLE you can
also create, update, and delete rows. You can also test the performance of
schema changes, like additional indexes or columns, in an isolated copy of production data.

## Database Lab quick start

1. [Visit the console](https://console.postgres.ai/).
1. Select **Sign in with Google**. (Not GitLab, as you need Google SSO to connect with our project.)
1. After you sign in, select the GitLab organization and then visit "Ask Joe" in the sidebar.
1. Select the database you're testing against:
   - Most queries for the GitLab project run against `gitlab-production-tunnel-pg12`.
   - If the query is for a CI table, select `gitlab-production-ci`.
   - If the query is for the container registry, select `gitlab-production-registry`.
1. Type `explain <Query Text>` in the chat box to get a plan.

## Access Database Lab Engine

Access to the DLE is helpful for:

- Database reviewers and maintainers.
- Engineers who work on merge requests that have large effects on databases.

To access the DLE's services, you can:

- Perform query testing in the Postgres.ai web console.
  Employees access both services with their GitLab Google account. Query testing
  provides `EXPLAIN` (analyze, buffers) plans for queries executed there.
- Migration testing by triggering a job as a part of a merge request.
- Direct `psql` access to DLE instead of a production replica. Available to authorized users only.
  To request `psql` access, file an [access request](https://about.gitlab.com/handbook/business-technology/end-user-services/onboarding-access-requests/access-requests/#individual-or-bulk-access-request).

For more assistance, use the `#database` Slack channel.

NOTE:
If you need only temporary access to a production replica, instead of a Database Lab
clone, follow the runbook procedure for connecting to the
[database console with Teleport](https://gitlab.com/gitlab-com/runbooks/-/blob/master/docs/teleport/Connect_to_Database_Console_via_Teleport.md).
This procedure is similar to [Rails console access with Teleport](https://gitlab.com/gitlab-com/runbooks/-/blob/master/docs/teleport/Connect_to_Rails_Console_via_Teleport.md#how-to-use-teleport-to-connect-to-rails-console).

### Query testing

You can access Database Lab's query analysis features either:

- In [the Postgres.ai web console](https://console.postgres.ai/GitLab/joe-instances).
  Shows only the commands you run.

#### Generate query plans

Query plans are an essential part of the database review process. These plans
enable us to decide quickly if a given query can be performant on GitLab.com.
Running the `explain` command generates an `explain` plan and a link to the Postgres.ai
console with more query analysis. For example, running `EXPLAIN SELECT * FROM application_settings`
does the following:

1. Runs `explain (analyze, buffers) select * from application_settings;` against a database clone.
1. Responds with timing and buffer details from the run.
1. Provides a [detailed, shareable report on the results](https://console.postgres.ai/shared/24d543c9-893b-4ff6-8deb-a8f902f85a53).

#### Making schema changes

Sometimes when testing queries, a contributor may realize that the query needs an index
or other schema change to make added queries more performant. To test the query, run the `exec` command.
For example, running this command:

```sql
exec CREATE INDEX on application_settings USING btree (instance_administration_project_id)
```

creates the specified index on the table. You can [test queries](#generate-query-plans) leveraging
the new index. `exec` does not return any results, only the time required to execute the query.

#### Reset the clone

After many changes, such as after a destructive query or an ineffective index,
you must start over. To reset your designated clone, run `reset`.

#### Checking indexes

Use Database Lab to check the status of an index with the meta-command `\d <index_name>`.

Caveats:

- Indexes are created in both the `main` and `ci` databases, so be sure to use the instance
  that matches the table's `gitlab_schema`. For example, if the index is added to
  [`ci_builds`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/db/docs/ci_builds.yml#L14),
  use `gitlab-production-ci`.
- Database Lab typically has a small delay of a few hours. If more up-to-date information
  is required, you can instead request access to a replica [via Teleport](https://gitlab.com/gitlab-com/runbooks/-/blob/master/docs/teleport/Connect_to_Database_Console_via_Teleport.md)

For example: `\d index_design_management_designs_on_project_id` produces:

```plaintext
Index "public.index_design_management_designs_on_project_id"
   Column   |  Type   | Key? | Definition
------------+---------+------+------------
 project_id | integer | yes  | project_id
btree, for table "public.design_management_designs"
```

In the case of an invalid index, the output ends with `invalid`, like:

```plaintext
Index "public.index_design_management_designs_on_project_id"
   Column   |  Type   | Key? | Definition
------------+---------+------+------------
 project_id | integer | yes  | project_id
btree, for table "public.design_management_designs", invalid
```

If the index doesn't exist, JoeBot throws an error like:

```plaintext
ERROR: psql error: psql:/tmp/psql-query-932227396:1: error: Did not find any relation named "no_index".
```

### Migration testing

For information on testing migrations, review our
[database migration testing documentation](database_migration_pipeline.md).

### Access the console with `psql`

NOTE:
You must have `AllFeaturesUser` [`psql` access](#access-database-lab-engine) to access the console with `psql`.

#### Simplified access through `pgai` Ruby gem

[@mbobin](https://gitlab.com/mbobin) created the [`pgai` Ruby Gem](https://gitlab.com/mbobin/pgai/#pgai) that
greatly simplifies access to a database clone, with support for:

- Access to all database clones listed in the [Postgres.ai instances page](https://console.postgres.ai/gitlab/instances);
- Multiple `psql` sessions on the same clone.

If you have `AllFeaturesUser` [`psql` access](#access-database-lab-engine), you can follow the steps below to configure
the `pgai` Gem:

1. To get started, you need to gather some values from the [Postgres.ai instances page](https://console.postgres.ai/gitlab/instances):

   1. Navigate to the instance that you want to configure and the on right side of the screen.
   1. Under **Connection**, select **Connect**. The menu might be collapsed.

      A pop-up with everything that's needed for configuration appears, using this format:

      ```shell
      dblab init --url http://127.0.0.1:1234 --token TOKEN --environment-id <environment-id>
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

#### Manual access through the Postgres.ai instances page

Team members with [`psql` access](#access-database-lab-engine), can gain direct access
to a clone via `psql`. Access to `psql` enables you to see data, not just metadata.

To connect to a clone using `psql`:

1. Create a clone from the [desired instance](https://console.postgres.ai/gitlab/instances/).
   1. Provide a **Clone ID**: Something that uniquely identifies your clone, such as `yourname-testing-gitlabissue`.
   1. Provide a **Database username** and **Database password**: Connects `psql` to your clone.
   1. Select **Enable deletion protection** if you want to preserve your clone. Avoid selecting this option.
      Clones are removed after 12 hours.
1. In the **Clone details** page of the Postgres.ai web interface, copy and run
   the command to start SSH port forwarding for the clone.
1. In the **Clone details** page of the Postgres.ai web interface, copy and run the `psql` connection string.
   Use the password provided at setup and set the `dbname` to `gitlabhq_dblab` (or check what databases are available by using `psql -l` with the same query string but `dbname=postgres`).

After you connect, use clone like you would any `psql` console in production, but with
the added benefit and safety of an isolated writeable environment.
