# Gitlab::Housekeeper

Housekeeping following https://gitlab.com/gitlab-org/gitlab/-/merge_requests/134487

## Running

Technically you can skip steps 1-2 below if you don't want to create a fork but
it's recommended as using a bot account with no permissions in
`gitlab-org/gitlab` will ensure we can't cause much damage if the script makes
a mistake. The alternative of using your own API token with it's permissions to
`gitlab-org/gitlab` has slightly more risks.

1. Create a fork of `gitlab-org/gitlab` where your MRs will come from
1. Create a project access token for that project
1. Set `housekeeper` remote to the fork you created
   ```
   git remote add housekeeper git@gitlab.com:DylanGriffith/gitlab.git
   ```
1. Open a Postgres.ai tunnel on localhost port 6305
1. Set the Postgres AI env vars matching the tunnel details for your tunnel
   ```
   export POSTGRES_AI_CONNECTION_STRING='host=localhost port=6305 user=dylan dbname=gitlabhq_dblab'
    export POSTGRES_AI_PASSWORD='the-password'
   ```
1. Set the GitLab client details. Will be used to create MR from housekeeper remote:
   ```
   export HOUSEKEEPER_FORK_PROJECT_ID=52263761 # Same project as housekeeper remote
   export HOUSEKEEPER_TARGET_PROJECT_ID=52263761 # Can be 278964 (gitlab-org/gitlab) when ready to create real MRs
    export HOUSEKEEPER_GITLAB_API_TOKEN=the-api-token
   ```
1. Run it:
   ```
   bundle exec gitlab-housekeeper -d -m3 -r keeps/overdue_finalize_background_migration.rb -k Keeps::OverdueFinalizeBackgroundMigration
   ```
