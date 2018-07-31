# Cleanup

## Remove garbage from filesystem. Important! Data loss!

Remove namespaces(dirs) from all repository storage paths if they don't exist in GitLab database.

```
# omnibus-gitlab
sudo gitlab-rake gitlab:cleanup:dirs

# installation from source
bundle exec rake gitlab:cleanup:dirs RAILS_ENV=production
```

Rename repositories from all repository storage paths if they don't exist in GitLab database.
The repositories get a `+orphaned+TIMESTAMP` suffix so that they cannot block new repositories from being created.

```
# omnibus-gitlab
sudo gitlab-rake gitlab:cleanup:repos

# installation from source
bundle exec rake gitlab:cleanup:repos RAILS_ENV=production
```

Clean up local project upload files if they don't exist in GitLab database. The
task attempts to fix the file if it can find its project, otherwise it moves the
file to a lost and found directory.

```
# omnibus-gitlab
sudo gitlab-rake gitlab:cleanup:project_uploads

# installation from source
bundle exec rake gitlab:cleanup:project_uploads RAILS_ENV=production
```

Example output:

```
$ sudo gitlab-rake gitlab:cleanup:project_uploads
I, [2018-07-27T12:08:27.671559 #89817]  INFO -- : Looking for orphaned project uploads to clean up. Dry run...
D, [2018-07-27T12:08:28.293568 #89817] DEBUG -- : Processing batch of 500 project upload file paths, starting with /opt/gitlab/embedded/service/gitlab-rails/public/uploads/test.out
I, [2018-07-27T12:08:28.689869 #89817]  INFO -- : Can move to lost and found /opt/gitlab/embedded/service/gitlab-rails/public/uploads/test.out -> /opt/gitlab/embedded/service/gitlab-rails/public/uploads/-/project-lost-found/test.out
I, [2018-07-27T12:08:28.755624 #89817]  INFO -- : Can fix /opt/gitlab/embedded/service/gitlab-rails/public/uploads/foo/bar/89a0f7b0b97008a4a18cedccfdcd93fb/foo.txt -> /opt/gitlab/embedded/service/gitlab-rails/public/uploads/qux/foo/bar/89a0f7b0b97008a4a18cedccfdcd93fb/foo.txt
I, [2018-07-27T12:08:28.760257 #89817]  INFO -- : Can move to lost and found /opt/gitlab/embedded/service/gitlab-rails/public/uploads/foo/bar/1dd6f0f7eefd2acc4c2233f89a0f7b0b/image.png -> /opt/gitlab/embedded/service/gitlab-rails/public/uploads/-/project-lost-found/foo/bar/1dd6f0f7eefd2acc4c2233f89a0f7b0b/image.png
I, [2018-07-27T12:08:28.764470 #89817]  INFO -- : To cleanup these files run this command with DRY_RUN=false

$ sudo gitlab-rake gitlab:cleanup:project_uploads DRY_RUN=false
I, [2018-07-27T12:08:32.944414 #89936]  INFO -- : Looking for orphaned project uploads to clean up...
D, [2018-07-27T12:08:33.293568 #89817] DEBUG -- : Processing batch of 500 project upload file paths, starting with /opt/gitlab/embedded/service/gitlab-rails/public/uploads/test.out
I, [2018-07-27T12:08:33.689869 #89817]  INFO -- : Did move to lost and found /opt/gitlab/embedded/service/gitlab-rails/public/uploads/test.out -> /opt/gitlab/embedded/service/gitlab-rails/public/uploads/-/project-lost-found/test.out
I, [2018-07-27T12:08:33.755624 #89817]  INFO -- : Did fix /opt/gitlab/embedded/service/gitlab-rails/public/uploads/foo/bar/89a0f7b0b97008a4a18cedccfdcd93fb/foo.txt -> /opt/gitlab/embedded/service/gitlab-rails/public/uploads/qux/foo/bar/89a0f7b0b97008a4a18cedccfdcd93fb/foo.txt
I, [2018-07-27T12:08:33.760257 #89817]  INFO -- : Did move to lost and found /opt/gitlab/embedded/service/gitlab-rails/public/uploads/foo/bar/1dd6f0f7eefd2acc4c2233f89a0f7b0b/image.png -> /opt/gitlab/embedded/service/gitlab-rails/public/uploads/-/project-lost-found/foo/bar/1dd6f0f7eefd2acc4c2233f89a0f7b0b/image.png
```