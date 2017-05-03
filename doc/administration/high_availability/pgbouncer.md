## Enabling PgBouncer

PgBouncer is now bundled as part of the GitLab EE package, and can be used as a connection pooler for the built in PostgreSQL database.

To enable pgbouncer do the following:

__Note__: The password digests can be obtained by running: `echo -n 'PASSWORD + USERNAME' | md5sum`

### On the database server ensure at least the following attributes are set:
```ruby
postgresql['listen_address'] = '0.0.0.0'
postgresql['trust_auth_cidr_addresses'] = ['127.0.0.1/32']
postgresql['md5_auth_cidr_addresses'] = [CIDR]
```
CIDR should be the cidr address of the pgbouncer server that will be connecting to the database.
```ruby
postgresql['sql_user_password'] = 'PASSWORD_HASH'
postgresql['pgbouncer_user_password'] = 'PASSWORD_HASH'
```
The default for postgresql['sql_user'] is `gitlab`, this is the account that the GitLab application uses to connect to the database.

The default for `postgresql['pgbouncer_user']` is `pgbouncer`, this will be the user that the pgbouncer service uses to authenticate to the database.
Both `postgresql['pgbouncer_user']` and `postgresql['pgbouncer_user_password']` should match what is set in the next step for the pgbouncer server.


### On the pgbouncer server, the following attributes should be set
```ruby
pgbouncer['enable'] = true
pgbouncer['databases'] = {
  your_database_name: {
    host: HOSTNAME,
    user: USERNAME,
    password: PASSWORD_HASH
}
```
The user, and the password hash should be the same as what is on the database server
You can specify multiple databases in `pgbouncer['databases']` if required.

### On the server which will be running unicorn, ensure the following attributes are set:
```ruby
gitlab_rails['db_adapter'] = "postgresql"
gitlab_rails['db_encoding'] = "utf8"
gitlab_rails['db_host'] = 'IP_OF_PGBOUNCER'
gitlab_rails['db_port'] = 6432
gitlab_rails['db_username'] = "gitlab"
gitlab_rails['db_password'] = 'PASSWORD'
```
`gitlab_rails['db_password']` should be the plain text password you want to use for the database user. For security purposes, run the following to ensure that `/etc/gitlab/gitlab.rb` cannot be accessed by just anyone:
1. `chown root:root /etc/gitlab/gitlab.rb`
1. `chmod 0600 /etc/gitlab/gitlab.rb`

Run `gitlab-ctl reconfigure` on all of the servers in order for GitLab to pick up the new settings.
