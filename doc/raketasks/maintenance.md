### Setup production application

Runs the following rake tasks:

* db:setup (Create the database, load the schema, and initialize with the seed data)
* db:seed_fu (Loads seed data for the current environment.)
* gitlab:app:enable_automerge (see "Features")

```
bundle exec rake gitlab:app:setup
```


### Check GitLab installation status

[Trouble-Shooting-Guide](https://github.com/gitlabhq/gitlab-public-wiki/wiki/Trouble-Shooting-Guide)

```
bundle exec rake gitlab:app:status
```

Example output:

```
config/database.yml............exists
config/gitlab.yml............exists
/home/git/repositories/............exists
/home/git/repositories/ is writable?............YES
Can clone gitolite-admin?............YES
Can git commit?............YES
UMASK for .gitolite.rc is 0007? ............YES
/home/git/.gitolite/hooks/common/post-receive exists? ............YES

Validating projects repositories:
* abcd.....post-receive file ok
* abcdtest.....post-receive file missing

Finished

```


### Rebuild each key at gitolite config

This will send all users ssh public keys to gitolite and grant them access (based on their permission) to their projects.

```
bundle exec rake gitlab:gitolite:update_keys
```


### Rebuild each project at gitolite config

This makes sure that all projects are present in gitolite and can be accessed.

```
bundle exec rake gitlab:gitolite:update_repos
```

### Import bare repositories into GitLab project instance

Notes:

* project owner will be a first admin
* existing projects will be skipped

How to use:

1. copy your bare repos under git base_path (see `config/gitlab.yml` git_host -> base_path)
2. run the command below

```
bundle exec rake gitlab:import:repos RAILS_ENV=production
```

Example output:

```
Processing abcd.git
 * Created abcd (abcd.git)
[...]
```
