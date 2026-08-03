# frozen_string_literal: true

require_relative 'setup_task'

# Prepares every configured database for Siphon replication. Per database it installs the
# siphon_alter_publication SECURITY DEFINER function, grants EXECUTE on it to the siphon user
# only, creates an empty publication, and grants USAGE and SELECT on the public and
# gitlab_partitions_* schemas to the Siphon users. Safe to run repeatedly.
#
# The Siphon users must already exist. Creating them needs a superuser, because the REPLICATION
# attribute on siphon_replicator is superuser-only, so this task only reports them as missing.
#
#   bundle exec rake gitlab:siphon:setup
#   SIPHON_DATABASE=ci bundle exec rake gitlab:siphon:setup
#
# SIPHON_USER_PREFIX       role name prefix, default `siphon`
# SIPHON_DATABASE          limit to one database (`main`, `ci`, `sec`), default all
# SIPHON_PUBLICATION_NAME  publication name, default `siphon_publication_<database>_1`,
#                          only allowed together with SIPHON_DATABASE
namespace :gitlab do
  namespace :siphon do
    desc 'GitLab | Siphon | Set up the publication, helper function and grants on every configured database'
    task setup: :gitlab_environment do
      Tasks::Gitlab::Siphon::SetupTask.new(
        user_prefix: ENV['SIPHON_USER_PREFIX'],
        database: ENV['SIPHON_DATABASE'],
        publication_name: ENV['SIPHON_PUBLICATION_NAME']
      ).execute
    end
  end
end
