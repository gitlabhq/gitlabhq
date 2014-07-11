# Migrating GitLab from MySQL to Postgres

If you are replacing MySQL with Postgres while keeping GitLab on the same server all you need to do is to export from MySQL, import into Postgres and rebuild the indexes as described below. If you are also moving GitLab to another server, or if you are switching to omnibus-gitlab, you may want to use a GitLab backup file. The second part of this documents explains the procedure to do this.

## Export from MySQL and import into Postgres

Use this if you are keeping GitLab on the same server.

```
sudo service gitlab stop

# Update /home/git/gitlab/config/database.yml

git clone https://github.com/gitlabhq/mysql-postgresql-converter.git
cd mysql-postgresql-converter
mysqldump --compatible=postgresql --default-character-set=utf8 -r databasename.mysql -u root gitlabhq_production
python db_converter.py databasename.mysql databasename.psql
psql -f databasename.psql -d gitlabhq_production

# Rebuild indexes (see below)

sudo service gitlab start
```

## Rebuild indexes

The lanyrd database converter script does not preserve all indexes, so we have to recreate them ourselves after migrating from MySQL. It is not necessary to shut down GitLab for this process.

### For non-omnibus installations

On non-omnibus installations (distributed using Git) we retrieve the index declarations from version control using `git stash`.

```
# Clone the database converter on your Postgres-backed GitLab server
cd /tmp
git clone https://github.com/gitlabhq/mysql-postgresql-converter.git

cd /home/git/gitlab

# Stash changes to db/schema.rb to make sure we can find the right index statements
sudo -u git -H git stash

# Generate add_index.rb
ruby /tmp/mysql-postgresql-converter/add_index_statements.rb db/schema.rb > /tmp/mysql-postgresql-converter/add_index.rb

# Create the indexes
sudo -u git -H bundle exec rails runner -e production 'eval $stdin.read' < /tmp/mysql-postgresql-converter/add_index.rb
```

### For omnibus-gitlab installations

On omnibus-gitlab we need to get the index declarations from a file called `schema.rb.bundled`. For versions older than 6.9, we need to download the file.

```
# Clone the database converter on your Postgres-backed GitLab server
cd /tmp
/opt/gitlab/embedded/bin/git clone https://github.com/gitlabhq/mysql-postgresql-converter.git
cd /tmp/mysql-postgresql-converter

# Download schema.rb.bundled if necessary
test -e /opt/gitlab/embedded/service/gitlab-rails/db/schema.rb.bundled || sudo /opt/gitlab/embedded/bin/curl -o /opt/gitlab/embedded/service/gitlab-rails/db/schema.rb.bundled https://gitlab.com/gitlab-org/gitlab-ce/raw/v6.9.1/db/schema.rb

# Generate add_index.rb
/opt/gitlab/embedded/bin/ruby add_index_statements.rb /opt/gitlab/embedded/service/gitlab-rails/db/schema.rb.bundled > add_index.rb

# Create the indexes
/opt/gitlab/bin/gitlab-rails runner 'eval $stdin.read' < add_index.rb
```

## Converting a GitLab backup file from MySQL to Postgres

GitLab backup files (<timestamp>_gitlab_backup.tar) contain a SQL dump. Using the lanyrd database converter we can replace a MySQL database dump inside the tar file with a Postgres database dump. This can be useful if you are moving to another server.

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
sudo -u git -H mysqldump --compatible=postgresql --default-character-set=utf8 -r gitlabhq_production.mysql -u root gitlabhq_production

# Clone the database converter
sudo -u git -H git clone https://github.com/gitlabhq/mysql-postgresql-converter.git

# Convert gitlabhq_production.mysql
sudo -u git -H mkdir db
sudo -u git -H python mysql-postgresql-converter/db_converter.py gitlabhq_production.mysql db/database.sql

# Replace the MySQL dump in TIMESTAMP_gitlab_backup.tar.

# Warning: if you forget to replace TIMESTAMP below, tar will create a new file
# 'TIMESTAMP_gitlab_backup.tar' without giving an error.

sudo -u git -H tar rf TIMESTAMP_gitlab_backup.tar db/database.sql

# Done! TIMESTAMP_gitlab_backup.tar can now be restored into a Postgres GitLab
# installation. Remember to recreate the indexes after the import.
```
