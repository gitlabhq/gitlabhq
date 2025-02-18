---
stage: Data Access
group: Database Frameworks
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: Post Deployment Migrations
---

Post deployment migrations are regular Rails migrations that can optionally be
executed after a deployment. By default these migrations are executed alongside
the other migrations. To skip these migrations you must set the
environment variable `SKIP_POST_DEPLOYMENT_MIGRATIONS` to a non-empty value
when running `rake db:migrate`.

For example, this would run all migrations including any post deployment
migrations:

```shell
bundle exec rake db:migrate
```

This however skips post deployment migrations:

```shell
export SKIP_POST_DEPLOYMENT_MIGRATIONS=true
bundle exec rake db:migrate
```

For GitLab.com, these migrations are executed on a daily basis at the discretion of
release managers through the
[post-deploy migration pipeline](https://gitlab.com/gitlab-org/release/docs/-/blob/master/general/post_deploy_migration/readme.md).

## Deployment Integration

Say you're using Chef for deploying new versions of GitLab and you'd like to run
post deployment migrations after deploying a new version. Let's assume you
usually use the command `chef-client` to do so. To make use of this feature
you'd have to run this command as follows:

```shell
export SKIP_POST_DEPLOYMENT_MIGRATIONS=true
sudo chef-client
```

Once all servers have been updated you can run `chef-client` again on a single
server _without_ the environment variable.

The process is similar for other deployment techniques: first you would deploy
with the environment variable set, then you re-deploy a single
server but with the variable _unset_.

## Creating Migrations

To create a post deployment migration you can use the following Rails generator:

```shell
bundle exec rails g post_deployment_migration migration_name_here
```

This generates the migration file in `db/post_migrate`. These migrations
behave exactly like regular Rails migrations.

## Use Cases

Post deployment migrations can be used to perform migrations that mutate state
that an existing version of GitLab depends on. For example, say you want to
remove a column from a table. This requires downtime as a GitLab instance
depends on this column being present while it's running. Usually you'd follow
these steps in such a case:

1. Stop the GitLab instance
1. Run the migration removing the column
1. Start the GitLab instance again

Using post deployment migrations we can instead follow these steps:

1. Deploy a new version of GitLab while ignoring post deployment migrations
1. Re-run `rake db:migrate` but without the environment variable set

Here we don't need any downtime as the migration takes place _after_ a new
version (which doesn't depend on the column anymore) has been deployed.

Some other examples where these migrations are useful:

- Cleaning up data generated due to a bug in GitLab
- Removing tables
- Migrating jobs from one Sidekiq queue to another
