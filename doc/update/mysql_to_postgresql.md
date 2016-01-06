# Migrating GitLab from MySQL to Postgres
*Make sure you view this [guide from the `master` branch](https://gitlab.com/gitlab-org/gitlab-ce/blob/master/doc/update/mysql_to_postgresql.md#migrating-gitlab-from-mysql-to-postgres) for the most up to date instructions.*

If you are replacing MySQL with Postgres while keeping GitLab on the same server all you need to do is to export from MySQL, convert the resulting SQL file, and import it into Postgres. If you are also moving GitLab to another server, or if you are switching to omnibus-gitlab, you may want to use a GitLab backup file. The second part of this documents explains the procedure to do this.

## Export from MySQL and import into Postgres

Use this if you are keeping GitLab on the same server.

```
sudo service gitlab stop

# Update /home/git/gitlab/config/database.yml

git clone https://github.com/gitlabhq/mysql-postgresql-converter.git -b gitlab
cd mysql-postgresql-converter
mysqldump --compatible=postgresql --default-character-set=utf8 -r gitlabhq_production.mysql -u root gitlabhq_production -p
python db_converter.py gitlabhq_production.mysql gitlabhq_production.psql
ed -s gitlabhq_production.psql < move_drop_indexes.ed

# Import the database dump as the application database user
sudo -u git psql -f gitlabhq_production.psql -d gitlabhq_production

# Install gems for PostgreSQL (note: the line below states '--without ... mysql')
sudo -u git -H bundle install --without development test mysql --deployment

sudo service gitlab start
```

## Converting a GitLab backup file from MySQL to Postgres
**Note:** Please make sure to have Python 2.7.x (or higher) installed.

GitLab backup files (`<timestamp>_gitlab_backup.tar`) contain a SQL dump. Using the lanyrd database converter we can replace a MySQL database dump inside the tar file with a Postgres database dump. This can be useful if you are moving to another server.

```
# Stop GitLab
sudo service gitlab stop

# Create the backup
cd /home/git/gitlab
sudo -u git -H bundle exec rake gitlab:backup:create RAILS_ENV=production

# Note the filename of the backup that was created. We will call it
# TIMESTAMP_gitlab_backup.tar below.

# Move the backup file we will convert to its own directory
sudo -u git -H mkdir -p tmp/backups/postgresql
sudo -u git -H mv tmp/backups/TIMESTAMP_gitlab_backup.tar tmp/backups/postgresql/

# Create a separate database dump with PostgreSQL compatibility
cd tmp/backups/postgresql
sudo -u git -H mysqldump --compatible=postgresql --default-character-set=utf8 -r gitlabhq_production.mysql -u root gitlabhq_production -p

# Clone the database converter
sudo -u git -H git clone https://github.com/gitlabhq/mysql-postgresql-converter.git -b gitlab

# Convert gitlabhq_production.mysql
sudo -u git -H mkdir db
sudo -u git -H python mysql-postgresql-converter/db_converter.py gitlabhq_production.mysql db/database.sql
sudo -u git -H ed -s db/database.sql < mysql-postgresql-converter/move_drop_indexes.ed

# Compress database backup
# Warning: If you have Gitlab 7.12.0 or older skip this step and import the database.sql directly into the backup with:
# sudo -u git -H tar rf TIMESTAMP_gitlab_backup.tar db/database.sql
# The compressed databasedump is not supported at 7.12.0 and older.
sudo -u git -H gzip db/database.sql

# Replace the MySQL dump in TIMESTAMP_gitlab_backup.tar.

# Warning: if you forget to replace TIMESTAMP below, tar will create a new file
# 'TIMESTAMP_gitlab_backup.tar' without giving an error.

sudo -u git -H tar rf TIMESTAMP_gitlab_backup.tar db/database.sql.gz

# Done! TIMESTAMP_gitlab_backup.tar can now be restored into a Postgres GitLab
# installation.
# See https://gitlab.com/gitlab-org/gitlab-ce/blob/master/doc/raketasks/backup_restore.md for more information about backups.
```
