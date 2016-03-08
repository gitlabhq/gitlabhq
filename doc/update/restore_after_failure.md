# Restoring from backup after a failed upgrade

Upgrades are usually smooth and restoring from backup is a rare occurrence.
However, it's important to know how to recover when problems do arise.

## Roll back to an earlier version and restore a backup

In some cases after a failed upgrade, the fastest solution is to roll back to
the previous version you were using.

First, roll back the code or package. For source installations this involves
checking out the older version (branch or tag). For Omnibus installations this
means installing the older .deb or .rpm package. Then, restore from a backup.
Follow the instructions in the
[Backup and Restore](../raketasks/backup_restore.md#restore-a-previously-created-backup)
documentation.

## Potential problems on the next upgrade

When a rollback is necessary it can produce problems on subsequent upgrade
attempts. This is because some tables may have been added during the failed
upgrade. If these tables are still present after you restore from the
older backup it can lead to migration failures on future upgrades.

Starting in GitLab 8.6 we drop all tables prior to importing the backup to
prevent this problem. If you've restored a backup to a version prior to 8.6 you
may need to manually correct the problem next time you upgrade.

Example error:

```
== 20151103134857 CreateLfsObjects: migrating =================================
-- create_table(:lfs_objects)
rake aborted!
StandardError: An error has occurred, this and all later migrations canceled:

PG::DuplicateTable: ERROR:  relation "lfs_objects" already exists
```

Copy the version from the error. In this case the version number is
`20151103134857`.

>**WARNING:** Use the following steps only if you are certain this is what you
need to do.

### GitLab 8.6+

Pass the version to a database rake task to manually mark the migration as
complete.

```
# Source install
sudo -u git -H bundle exec rake gitlab:db:mark_migration_complete[20151103134857] RAILS_ENV=production

# Omnibus install
sudo gitlab-rake gitlab:db:mark_migration_complete[20151103134857]
```

Once the migration is successfully marked, run the rake `db:migrate` task again.
You will likely have to repeat this process several times until all failed
migrations are marked complete.

### GitLab < 8.6

```
# Source install
sudo -u git -H bundle exec rails console production

# Omnibus install
sudo gitlab-rails console
```

At the Rails console, type the following commands:

```
ActiveRecord::Base.connection.execute("INSERT INTO schema_migrations (version) VALUES('20151103134857')")
exit
```

Once the migration is successfully marked, run the rake `db:migrate` task again.
You will likely have to repeat this process several times until all failed
migrations are marked complete.

