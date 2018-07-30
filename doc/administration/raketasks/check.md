# Integrity Check Rake Task

## Repository Integrity

Even though Git is very resilient and tries to prevent data integrity issues,
there are times when things go wrong. The following Rake tasks intend to
help GitLab administrators diagnose problem repositories so they can be fixed.

There are 3 things that are checked to determine integrity.

1. Git repository file system check ([git fsck](https://git-scm.com/docs/git-fsck)).
   This step verifies the connectivity and validity of objects in the repository.
1. Check for `config.lock` in the repository directory.
1. Check for any branch/references lock files in `refs/heads`.

It's important to note that the existence of `config.lock` or reference locks
alone do not necessarily indicate a problem. Lock files are routinely created
and removed as Git and GitLab perform operations on the repository. They serve
to prevent data integrity issues. However, if a Git operation is interrupted these
locks may not be cleaned up properly.

The following symptoms may indicate a problem with repository integrity. If users
experience these symptoms you may use the rake tasks described below to determine
exactly which repositories are causing the trouble.

- Receiving an error when trying to push code - `remote: error: cannot lock ref`
- A 500 error when viewing the GitLab dashboard or when accessing a specific project.

### Check all GitLab repositories

This task loops through all repositories on the GitLab server and runs the
integrity check described previously.

**Omnibus Installation**

```
sudo gitlab-rake gitlab:git:fsck
```

**Source Installation**

```bash
sudo -u git -H bundle exec rake gitlab:git:fsck RAILS_ENV=production
```

## Uploaded Files Integrity

Various types of files can be uploaded to a GitLab installation by users.
These integrity checks can detect missing files. Additionally, for locally
stored files, checksums are generated and stored in the database upon upload,
and these checks will verify them against current files.

Currently, integrity checks are supported for the following types of file:

* CI artifacts (Available from version 10.7.0)
* LFS objects (Available from version 10.6.0)
* User uploads (Available from version 10.6.0)

**Omnibus Installation**

```
sudo gitlab-rake gitlab:artifacts:check
sudo gitlab-rake gitlab:lfs:check
sudo gitlab-rake gitlab:uploads:check
```

**Source Installation**

```bash
sudo -u git -H bundle exec rake gitlab:artifacts:check RAILS_ENV=production
sudo -u git -H bundle exec rake gitlab:lfs:check RAILS_ENV=production
sudo -u git -H bundle exec rake gitlab:uploads:check RAILS_ENV=production
```

These tasks also accept some environment variables which you can use to override
certain values:

Variable  | Type    | Description
--------- | ------- | -----------
`BATCH`   | integer | Specifies the size of the batch. Defaults to 200.
`ID_FROM` | integer | Specifies the ID to start from, inclusive of the value.
`ID_TO`   | integer | Specifies the ID value to end at, inclusive of the value.
`VERBOSE` | boolean | Causes failures to be listed individually, rather than being summarized.

```bash
sudo gitlab-rake gitlab:artifacts:check BATCH=100 ID_FROM=50 ID_TO=250
sudo gitlab-rake gitlab:lfs:check BATCH=100 ID_FROM=50 ID_TO=250
sudo gitlab-rake gitlab:uploads:check BATCH=100 ID_FROM=50 ID_TO=250
```

Example output:

```
$ sudo gitlab-rake gitlab:uploads:check
Checking integrity of Uploads
- 1..1350: Failures: 0
- 1351..2743: Failures: 0
- 2745..4349: Failures: 2
- 4357..5762: Failures: 1
- 5764..7140: Failures: 2
- 7142..8651: Failures: 0
- 8653..10134: Failures: 0
- 10135..11773: Failures: 0
- 11777..13315: Failures: 0
Done!
```

Example verbose output:

```
$ sudo gitlab-rake gitlab:uploads:check VERBOSE=1
Checking integrity of Uploads
- 1..1350: Failures: 0
- 1351..2743: Failures: 0
- 2745..4349: Failures: 2
  - Upload: 3573: #<Errno::ENOENT: No such file or directory @ rb_sysopen - /opt/gitlab/embedded/service/gitlab-rails/public/uploads/user-foo/project-bar/7a77cc52947bfe188adeff42f890bb77/image.png>
  - Upload: 3580: #<Errno::ENOENT: No such file or directory @ rb_sysopen - /opt/gitlab/embedded/service/gitlab-rails/public/uploads/user-foo/project-bar/2840ba1ba3b2ecfa3478a7b161375f8a/pug.png>
- 4357..5762: Failures: 1
  - Upload: 4636: #<Google::Apis::ServerError: Server error>
- 5764..7140: Failures: 2
  - Upload: 5812: #<NoMethodError: undefined method `hashed_storage?' for nil:NilClass>
  - Upload: 5837: #<NoMethodError: undefined method `hashed_storage?' for nil:NilClass>
- 7142..8651: Failures: 0
- 8653..10134: Failures: 0
- 10135..11773: Failures: 0
- 11777..13315: Failures: 0
Done!
```

## LDAP Check

The LDAP check Rake task will test the bind_dn and password credentials
(if configured) and will list a sample of LDAP users. This task is also
executed as part of the `gitlab:check` task, but can run independently.
See [LDAP Rake Tasks - LDAP Check](ldap.md#check) for details.

[git-fsck]: https://git-scm.com/docs/git-fsck
