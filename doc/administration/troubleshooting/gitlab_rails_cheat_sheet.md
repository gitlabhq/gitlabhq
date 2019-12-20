---
type: reference
---

# GitLab Rails Console Cheat Sheet

This is the GitLab Support Team's collection of information regarding the GitLab Rails
console, for use while troubleshooting. It is listed here for transparency,
and it may be useful for users with experience with these tools. If you are currently
having an issue with GitLab, it is highly recommended that you check your
[support options](https://about.gitlab.com/support/) first, before attempting to use
this information.

CAUTION: **CAUTION:**
Please note that some of these scripts could be damaging if not run correctly,
or under the right conditions. We highly recommend running them under the
guidance of a Support Engineer, or running them in a test environment with a
backup of the instance ready to be restored, just in case.

CAUTION: **CAUTION:**
Please also note that as GitLab changes, changes to the code are inevitable,
and so some scripts may not work as they once used to. These are not kept
up-to-date as these scripts/commands were added as they were found/needed. As
mentioned above, we recommend running these scripts under the supervision of a
Support Engineer, who can also verify that they will continue to work as they
should and, if needed, update the script for the latest version of GitLab.

## Use the Rails Runner

If the script you want to run is short, you can use the Rails Runner to avoid
entering the rails console in the first place. Here's an example of its use:

```bash
gitlab-rails runner "RAILS_COMMAND"

# Example with a 2-line script
gitlab-rails runner "user = User.first; puts user.username"
```

## Enable debug logging on rails console

```ruby
Rails.logger.level = 0
```

## Enable debug logging for ActiveRecord (db issues)

```ruby
ActiveRecord::Base.logger = Logger.new(STDOUT)
```

## Temporarily Disable Timeout

```ruby
ActiveRecord::Base.connection.execute('SET statement_timeout TO 0')
```

## Find specific methods for an object

```ruby
Array.methods.select { |m| m.to_s.include? "sing" }
Array.methods.grep(/sing/)
```

## Find method source

Works for [non-instrumented methods](../../development/instrumentation.md#checking-instrumented-methods):

```ruby
instance_of_object.method(:foo).source_location

# Example for when we would call project.private?
project.method(:private?).source_location
```

## Query an object

```ruby
o = Object.where('attribute like ?', 'ex')
```

## View all keys in cache

```ruby
Rails.cache.instance_variable_get(:@data).keys
```

## Rails console history

```ruby
puts Readline::HISTORY.to_a
```

## Profile a page

```ruby
# Before 11.6.0
logger = Logger.new(STDOUT)
admin_token = User.find_by_username('ADMIN_USERNAME').personal_access_tokens.first.token
app.get("URL/?private_token=#{admin_token}")

# From 11.6.0
admin = User.find_by_username('ADMIN_USERNAME')
url = "/url/goes/here"
Gitlab::Profiler.with_user(admin) { app.get(url) }
```

## Using the GitLab profiler inside console (used as of 10.5)

```ruby
logger = Logger.new(STDOUT)
admin = User.find_by_username('ADMIN_USERNAME')
Gitlab::Profiler.profile('URL', logger: logger, user: admin)
```

## Time an operation

```ruby
# A single operation
Benchmark.measure { <operation> }

# A breakdown of multiple operations
Benchmark.bm do |x|
  x.report(:label1) { <operation_1> }
  x.report(:label2) { <operation_2> }
end
```

## Command Line

### Check the GitLab version fast

```bash
grep -m 1 gitlab /opt/gitlab/version-manifest.txt
```

### Debugging SSH

```bash
GIT_SSH_COMMAND="ssh -vvv" git clone <repository>
```

### Debugging over HTTPS

```bash
GIT_CURL_VERBOSE=1 GIT_TRACE=1 git clone <repository>
```

## Projects

### Find projects

```ruby
# A single project
project = Project.find_by_full_path('PROJECT_PATH')

# All projects in a particular namespace.  Can be a username, a group
# ('gitlab-org'), or even include subgroups ('gitlab-org/distribution')
namespace = Namespace.find_by_full_path('NAMESPACE_PATH')
projects = namespace.all_projects
```

### Clear a project's cache

```ruby
ProjectCacheWorker.perform_async(project.id)
```

### Expire the .exists? cache

```ruby
project.repository.expire_exists_cache
```

### Make all projects private

```ruby
Project.update_all(visibility_level: 0)
```

### Find & remove projects that are pending deletion

```ruby
#
# This section will list all the projects which are pending deletion
#
projects = Project.where(pending_delete: true)
projects.each do |p|
  puts "Project name: #{p.id}"
  puts "Project name: #{p.name}"
  puts "Repository path: #{p.repository.storage_path}"
end

#
# Assign a user (the root user will do)
#
user = User.find_by_username('root')

#
# For each project listed repeat these two commands
#

# Find the project, update the xxx-changeme values from above
project = Project.find_by_full_path('group-changeme/project-changeme')

# Delete the project
::Projects::DestroyService.new(project, user, {}).execute
```

Next, run `sudo gitlab-rake gitlab:cleanup:repos` on the command line to finish.

### Destroy a project

```ruby
project = Project.find_by_full_path('')
user = User.find_by_username('')
ProjectDestroyWorker.perform_async(project.id, user.id, {})
# or ProjectDestroyWorker.new.perform(project.id, user.id, {})
# or Projects::DestroyService.new(project, user).execute
```

### Remove fork relationship manually

```ruby
p = Project.find_by_full_path('')
u = User.find_by_username('')
::Projects::UnlinkForkService.new(p, u).execute
```

### Make a project read-only (can only be done in the console)

```ruby
# Make a project read-only
project.repository_read_only = true; project.save

# OR
project.update!(repository_read_only: true)
```

### Bulk update service integration password for _all_ projects

For example, change the Jira user's password for all projects that have the Jira
integration active:

```ruby
p = Project.find_by_sql("SELECT p.id FROM projects p LEFT JOIN services s ON p.id = s.project_id WHERE s.type = 'JiraService' AND s.active = true")

p.each do |project|
  project.jira_service.update_attribute(:password, '<your-new-password>')
end
```

### Identify un-indexed projects

```ruby
Project.find_each do |project|
  puts "id #{project.id}: #{project.namespace.name.to_s}/#{project.name.to_s}" if project.index_status.nil?
end
```

## Wikis

### Recreate

A Projects Wiki can be recreated by

**Note:** This is a destructive operation, the Wiki will be empty

```ruby
p = Project.find_by_full_path('<username-or-group>/<project-name>')  ### enter your projects path

GitlabShellWorker.perform_in(0, :remove_repository, p.repository_storage, p.wiki.disk_path)  ### deletes the wiki project from the filesystem

p.create_wiki  ### creates the wiki project on the filesystem
```

## Imports / Exports

```ruby
# Find the project and get the error
p = Project.find_by_full_path('<username-or-group>/<project-name>')

p.import_error

# To finish the import on GitLab running version before 11.6
p.import_finish

# To finish the import on GitLab running version 11.6 or after
p.import_state.mark_as_failed("Failed manually through console.")
```

### Rename imported repository

In a specific situation, an imported repository needed to be renamed. The Support
Team was informed of a backup restore that failed on a single repository, which created
the project with an empty repository. The project was successfully restored to a dev
instance, then exported, and imported into a new project under a different name.

The Support Team was able to transfer the incorrectly named imported project into the
correctly named empty project using the steps below.

Move the new repository to the empty repository:

```bash
mv /var/opt/gitlab/git-data/repositories/<group>/<new-project> /var/opt/gitlab/git-data/repositories/<group>/<empty-project>
```

Make sure the permissions are correct:

```bash
chown -R git:git <path-to-directory>.git
```

Clear the cache:

```bash
sudo gitlab-rake cache:clear
```

## Repository

### Search sequence of pushes to a repository

If it seems that a commit has gone "missing", search the sequence of pushes to a repository.
[This StackOverflow article](https://stackoverflow.com/questions/13468027/the-mystery-of-the-missing-commit-across-merges)
describes how you can end up in this state without a force push.

If you look at the output from the sample code below for the target branch, you will
see a discontinuity in the from/to commits as you step through the output. Each new
push should be "from" the "to" SHA of the previous push. When this discontinuity happens,
you will see two pushes with the same "from" SHA:

```ruby
p = Project.find_with_namespace('u/p')
p.events.code_push.last(100).each do |e|
  printf "%-20.20s %8s...%8s (%s)\n", e.data[:ref], e.data[:before], e.data[:after], e.author.try(:username)
end
```

GitLab 9.5 and above:

```ruby
p = Project.find_by_full_path('u/p')
p.events.code_push.last(100).each do |e|
  printf "%-20.20s %8s...%8s (%s)\n", e.push_event_payload[:ref], e.push_event_payload[:commit_from], e.push_event_payload[:commit_to], e.author.try(:username)
end
```

## Mirrors

### Find mirrors with "bad decrypt" errors

```ruby
total = 0
bad = []
ProjectImportData.find_each do |data|
  begin
    total += 1
    data.credentials
  rescue => e
    bad << data
  end
end

puts "Bad count: #{bad.count} / #{total}"
bad.each do |repo|
  puts Project.find(repo.project_id).full_path
end; bad.count
```

### Transfer mirror users and tokens to a single service account

Use case: If you have multiple users using their own GitHub credentials to set up
repository mirroring, mirroring breaks when people leave the company. Use this
script to migrate disparate mirroring users and tokens into a single service account:

```ruby
svc_user = User.find_by(username: 'ourServiceUser')
token = 'githubAccessToken'

Project.where(mirror: true).each do |project|
  import_url = project.import_url

  # The url we want is https://token@project/path.git
  repo_url = if import_url.include?('@')
               # Case 1: The url is something like https://23423432@project/path.git
               import_url.split('@').last
             elsif import_url.include?('//')
               # Case 2: The url is something like https://project/path.git
               import_url.split('//').last
             end

  next unless repo_url

  final_url = "https://#{token}@#{repo_url}"

  project.mirror_user = svc_user
  project.import_url = final_url
  project.username_only_import_url = final_url
  project.save
end
```

## Users

### Finding users

```ruby
# By username
user = User.find_by(username: '')

# By primary email
user = User.find_by(email: '')

# By any email (primary or secondary)
user = User.find_by_any_email('')

# Admins
User.admins
admin = User.admins.first
```

### Block

```ruby
User.find_by_username().block!
```

### Unblock

```ruby
User.find_by_username().active
```

### Skip reconfirmation

```ruby
user = User.find_by_username ''
user.skip_reconfirmation!
```

### Get an admin token

```ruby
# Get the first admin's first access token (no longer works on 11.9+. see: https://gitlab.com/gitlab-org/gitlab-foss/merge_requests/22743)
User.where(admin:true).first.personal_access_tokens.first.token

# Get the first admin's private token (no longer works on 10.2+)
User.where(admin:true).private_token
```

### Create personal access token

```ruby
personal_access_token = User.find(123).personal_access_tokens.create(
  name: 'apitoken',
  impersonation: false,
  scopes: [:api]
)

puts personal_access_token.token
```

You might also want to manually set the token string:

```ruby
User.find(123).personal_access_tokens.create(
  name: 'apitoken',
  token_digest: Gitlab::CryptoHelper.sha256('some-token-string-here'),
  impersonation: false,
  scopes: [:api]
)
```

### Disable 2FA on a user

```ruby
user = User.find_by_username('username')
user.disable_two_factor!
```

### Active users & Historical users

```ruby
# Active users on the instance, now
User.active.count

# The historical max on the instance as of the past year
::HistoricalData.max_historical_user_count
```

```bash
# Using curl and jq (up to a max 100, see pagination docs https://docs.gitlab.com/ee/api/#pagination
curl --silent --header "Private-Token: ********************" "https://gitlab.example.com/api/v4/users?per_page=100&active" | jq --compact-output '.[] | [.id,.name,.username]'
```

### Block or Delete Users that have no projects or groups

```ruby
users = User.where('id NOT IN (select distinct(user_id) from project_authorizations)')

# How many users will be removed?
users.count

# If that count looks sane:

# You can either block the users:
users.each { |user| user.block! }

# Or you can delete them:
  # need 'current user' (your user) for auditing purposes
current_user = User.find_by(username: '<your username>')

users.each do |user|
  DeleteUserWorker.perform_async(current_user.id, user.id)
end
```

### Block Users that have no recent activity

```ruby
days_inactive = 60
inactive_users = User.active.where("last_activity_on <= ?", days_inactive.days.ago)

inactive_users.each do |user|
    puts "user '#{user.username}': #{user.last_activity_on}"
    user.block!
end
```

### Find Max permissions for project/group

```ruby
user = User.find_by_username 'username'
project = Project.find_by_full_path 'group/project'
user.max_member_access_for_project project.id
```

```ruby
user = User.find_by_username 'username'
group = Group.find_by_full_path 'group'
user.max_member_access_for_group group.id
```

## Groups

### Count unique users in a group and sub-groups

```ruby
group = Group.find_by_path_or_name("groupname")
members = []
for member in group.members_with_descendants
   members.push(member.user_name)
end

members.uniq.length
```

```ruby
group = Group.find_by_path_or_name("groupname")

# Count users from subgroup and up (inherited)
group.members_with_parents.count

# Count users from parent group and down (specific grants)
parent.members_with_descendants.count
```

### Delete a group

```ruby
GroupDestroyWorker.perform_async(group_id, user_id)
```

### Modify group project creation

```ruby
# Project creation levels: 0 - No one, 1 - Maintainers, 2 - Developers + Maintainers
group = Group.find_by_path_or_name('group-name')
group.project_creation_level=0
```

## LDAP

### LDAP commands in the rails console

TIP: **TIP:**
Use the rails runner to avoid entering the rails console in the first place.
This is great when only a single command (such as a UserSync or GroupSync)
is needed.

```ruby
# Get debug output
Rails.logger.level = Logger::DEBUG

# Run a UserSync (normally performed once a day)
LdapSyncWorker.new.perform

# Run a GroupSync for all groups (9.3-)
LdapGroupSyncWorker.new.perform

# Run a GroupSync for all groups (9.3+)
LdapAllGroupsSyncWorker.new.perform

# Run a GroupSync for a single group (10.6-)
group = Group.find_by(name: 'my_gitlab_group')
EE::Gitlab::LDAP::Sync::Group.execute_all_providers(group)

# Run a GroupSync for a single group (10.6+)
group = Group.find_by(name: 'my_gitlab_group')
EE::Gitlab::Auth::LDAP::Sync::Group.execute_all_providers(group)

# Query an LDAP group directly (10.6-)
adapter = Gitlab::LDAP::Adapter.new('ldapmain') # If `main` is the LDAP provider
ldap_group = EE::Gitlab::LDAP::Group.find_by_cn('group_cn_here', adapter)
ldap_group.member_dns
ldap_group.member_uids

# Query an LDAP group directly (10.6+)
adapter = Gitlab::Auth::LDAP::Adapter.new('ldapmain') # If `main` is the LDAP provider
ldap_group = EE::Gitlab::Auth::LDAP::Group.find_by_cn('group_cn_here', adapter)
ldap_group.member_dns
ldap_group.member_uids

# Lookup a particular user (10.6+)
# This could expose potential errors connecting to and/or querying LDAP that may seem to
# fail silently in the GitLab UI
adapter = Gitlab::Auth::LDAP::Adapter.new('ldapmain') # If `main` is the LDAP provider
user = Gitlab::Auth::LDAP::Person.find_by_uid('<username>',adapter)

# Query the LDAP server directly (10.6+)
## For an example, see https://gitlab.com/gitlab-org/gitlab/blob/master/ee/lib/ee/gitlab/auth/ldap/adapter.rb
adapter = Gitlab::Auth::LDAP::Adapter.new('ldapmain')
options = {
    # the :base is required
    # use adapter.config.base for the base or .group_base for the group_base
    base: adapter.config.group_base,

    # :filter is optional
    # 'cn' looks for all "cn"s under :base
    # '*' is the search string - here, it's a wildcard
    filter: Net::LDAP::Filter.eq('cn', '*'),

    # :attributes is optional
    # the attributes we want to get returned
    attributes: %w(dn cn memberuid member submember uniquemember memberof)
}
adapter.ldap_search(options)
```

### Update user accounts when the `dn` and email change

The following will require that any accounts with the new email address are removed.
Emails have to be unique in GitLab. This is expected to work but unverified as of yet:

```ruby
# Here's an example with a couple users.
# Each entry will have to include the old username and the new email
emails = {
  'ORIGINAL_USERNAME' => 'NEW_EMAIL_ADDRESS',
  ...
}

emails.each do |username, email|
  user = User.find_by_username(username)
  user.email = email
  user.skip_reconfirmation!
  user.save!
end

# Run the UserSync to update the above users' data
LdapSyncWorker.new.perform
```

## Routes

### Remove redirecting routes

See <https://gitlab.com/gitlab-org/gitlab-foss/issues/41758#note_54828133>.

```ruby
path = 'foo'
conflicting_permanent_redirects = RedirectRoute.matching_path_and_descendants(path)

# Check that conflicting_permanent_redirects is as expected
conflicting_permanent_redirects.destroy_all
```

## Merge Requests

### Find Merge Request

```ruby
m = project.merge_requests.find_by(iid: <IID>)
m = MergeRequest.find_by_title('NEEDS UNIQUE TITLE!!!')
```

### Close a merge request properly (if merged but still marked as open)

```ruby
p = Project.find_by_full_path('')
m = project.merge_requests.find_by(iid: )
u = User.find_by_username('')
MergeRequests::PostMergeService.new(p, u).execute(m)
```

### Delete a merge request

```ruby
u = User.find_by_username('<username>')
p = Project.find_by_full_path('<group>/<project>')
m = p.merge_requests.find_by(iid: <IID>)
Issuable::DestroyService.new(m.project, u).execute(m)
```

### Rebase manually

```ruby
p = Project.find_by_full_path('')
m = project.merge_requests.find_by(iid: )
u = User.find_by_username('')
MergeRequests::RebaseService.new(m.target_project, u).execute(m)
```

## CI

### Cancel stuck pending pipelines

For more information, see the [confidential issue](../../user/project/issues/confidential_issues.md)
`https://gitlab.com/gitlab-com/support-forum/issues/2449#note_41929707`.

```ruby
Ci::Pipeline.where(project_id: p.id).where(status: 'pending').count
Ci::Pipeline.where(project_id: p.id).where(status: 'pending').each {|p| p.cancel if p.stuck?}
Ci::Pipeline.where(project_id: p.id).where(status: 'pending').count
```

### Manually modify runner minutes

```ruby
Namespace.find_by_full_path("user/proj").namespace_statistics.update(shared_runners_seconds: 27360)
```

### Remove artifacts more than a week old

```ruby
### SELECTING THE BUILDS TO CLEAR
# For a single project:
project = Project.find_by_full_path('')
builds_with_artifacts =  project.builds.with_artifacts_archive

# Instance-wide:
builds_with_artifacts = Ci::Build.with_artifacts_archive

# Prior to 10.6 the above lines would be:
# builds_with_artifacts =  project.builds.with_artifacts
# builds_with_artifacts = Ci::Build.with_artifacts

### CLEAR THEM OUT
# Note that this will also erase artifacts that developers marked to "Keep"
builds_to_clear = builds_with_artifacts.where("finished_at < ?", 1.week.ago)
builds_to_clear.each do |build|
  build.artifacts_expire_at = Time.now
  build.erase_erasable_artifacts!
end
```

### Find reason failure (for when build trace is empty) (Introduced in 10.3.0)

See <https://gitlab.com/gitlab-org/gitlab-foss/issues/41111>.

```ruby
build = Ci::Build.find(78420)

build.failure_reason

build.dependencies.each do |d| { puts "status: #{d.status}, finished at: #{d.finished_at},
  completed: #{d.complete?}, artifacts_expired: #{d.artifacts_expired?}, erased: #{d.erased?}" }
```

### Disable strict artifact checking (Introduced in GitLab 10.3.0)

See [job artifacts documentation](../job_artifacts.md#validation-for-dependencies).

```ruby
Feature.enable('ci_disable_validates_dependencies')
```

### Remove CI traces older than 6 months

```ruby
current_user = User.find_by_email('cindy@gitlap.com')
Ci::Build.where("finished_at < ?", 6.months.ago.to_date).each {|b| puts b.id; b.erase(erased_by: current_user) if b.erasable?};nil
```

### Try CI service

```ruby
p = Project.find_by_full_path('')
m = project.merge_requests.find_by(iid: )
m.project.try(:ci_service)
```

### Disable AutoDevOps on Existing Projects

```ruby
Project.all.each do |p|
  p.auto_devops_attributes={"enabled"=>"0"}
  p.save
end
```

## License

### See license plan name (since v9.3.0-ee)

```ruby
License.current.plan
```

### Check if a project feature is available on the instance

Features listed in <https://gitlab.com/gitlab-org/gitlab/blob/master/ee/app/models/license.rb>.

```ruby
License.current.feature_available?(:jira_dev_panel_integration)
```

### Check if a project feature is available in a project

Features listed in <https://gitlab.com/gitlab-org/gitlab/blob/master/ee/app/models/license.rb>.

```ruby
p = Project.find_by_full_path('<group>/<project>')
p.feature_available?(:jira_dev_panel_integration)
```

### Add a license through the console

```ruby
key = "<key>"
license = License.new(data: key)
license.save
License.current # check to make sure it applied
```

## Unicorn

From [Zendesk ticket #91083](https://gitlab.zendesk.com/agent/tickets/91083) (internal)

### Poll Unicorn requests by seconds

```ruby
require 'rubygems'
require 'unicorn'

# Usage for this program
def usage
  puts "ruby unicorn_status.rb <path to unix socket> <poll interval in seconds>"
  puts "Polls the given Unix socket every interval in seconds. Will not allow you to drop below 3 second poll intervals."
  puts "Example: /opt/gitlab/embedded/bin/ruby poll_unicorn.rb /var/opt/gitlab/gitlab-rails/sockets/gitlab.socket 10"
end

# Look for required args. Throw usage and exit if they don't exist.
if ARGV.count < 2
  usage
  exit 1
end

# Get the socket and threshold values.
socket = ARGV[0]
threshold = (ARGV[1]).to_i

# Check threshold - is it less than 3? If so, set to 3 seconds. Safety first!
if threshold.to_i < 3
  threshold = 3
end

# Check - does that socket exist?
unless File.exist?(socket)
  puts "Socket file not found: #{socket}"
  exit 1
end

# Poll the given socket every THRESHOLD seconds as specified above.
puts "Running infinite loop. Use CTRL+C to exit."
puts "------------------------------------------"
loop do
  Raindrops::Linux.unix_listener_stats([socket]).each do |addr, stats|
    puts DateTime.now.to_s + " Active: " + stats.active.to_s + " Queued: " + stats.queued.to_s
  end
  sleep threshold
end
```

## Sidekiq

### Size of a queue

```ruby
Sidekiq::Queue.new('background_migration').size
```

### Kill a worker's Sidekiq jobs

```ruby
queue = Sidekiq::Queue.new('repository_import')
queue.each { |job| job.delete if <condition>}
```

`<condition>` probably includes references to job arguments, which depend on the type of job in question.

| queue | worker | job args |
| ----- | ------ | -------- |
| repository_import | RepositoryImportWorker | project_id |
| update_merge_requests | UpdateMergeRequestsWorker | project_id, user_id, oldrev, newrev, ref |

**Example:** Delete all UpdateMergeRequestsWorker jobs associated with a merge request on project_id 125,
merging branch `ref/heads/my_branch`.

```ruby
queue = Sidekiq::Queue.new('update_merge_requests')
queue.each { |job| job.delete if job.args[0]==125 and job.args[4]=='ref/heads/my_branch'}
```

**Note:** Running jobs will not be killed. Stop Sidekiq before doing this, to get all matching jobs.

### Enable debug logging of Sidekiq

```ruby
gitlab_rails['env'] = {
  'SIDEKIQ_LOG_ARGUMENTS' => "1"
}
```

Then `gitlab-ctl reconfigure; gitlab-ctl restart sidekiq`.  The Sidekiq logs will now include additional data for troubleshooting.

### Sidekiq kill signals

See <https://github.com/mperham/sidekiq/wiki/Signals#ttin>.

## Redis

### Connect to Redis (omnibus)

```sh
/opt/gitlab/embedded/bin/redis-cli -s /var/opt/gitlab/redis/redis.socket
```

### Connect to Redis (HA)

```sh
/opt/gitlab/embedded/bin/redis-cli -h <host ip> -a <password>
```

## LFS

### Get info about LFS objects and associated project

```ruby
o=LfsObject.find_by(oid: "<oid>")
p=Project.find(LfsObjectsProject.find_by_lfs_object_id(o.id).project_id)
```

You can then delete these records from the database with:

```ruby
LfsObjectsProject.find_by_lfs_object_id(o.id).destroy
o.destroy
```

You would also want to combine this with deleting the LFS file in the LFS storage
area on disk. It remains to be seen exactly how or whether the deletion is useful, however.

## Decryption Problems

### Bad Decrypt Script (for encrypted variables)

See <https://gitlab.com/snippets/1730735/raw>.

This script will go through all the encrypted variables and count how many are not able
to be decrypted. Might be helpful to run on multiple nodes to see which `gitlab-secrets.json`
file is most up to date:

```bash
wget -O /tmp/bad-decrypt.rb https://gitlab.com/snippets/1730735/raw
gitlab-rails runner /tmp/bad-decrypt.rb
```

If `ProjectImportData Bad count:` is detected and the decision is made to delete the
encrypted credentials to allow manual reentry:

```ruby
  # Find the ids of the corrupt ProjectImportData objects
  total = 0
  bad = []
  ProjectImportData.find_each do |data|
    begin
      total += 1
      data.credentials
    rescue => e
      bad << data.id
    end
  end

  puts "Bad count: #{bad.count} / #{total}"

  # See the bad ProjectImportData ids
  bad

  # Remove the corrupted credentials
  import_data = ProjectImportData.where(id: bad)
  import_data.each do |data|
    data.update_columns({ encrypted_credentials: nil, encrypted_credentials_iv: nil, encrypted_credentials_salt: nil})
  end
```

If `User OTP Secret Bad count:` is detected. For each user listed disable/enable
two-factor authentication.

### Decrypt Script for encrypted tokens

This script will search for all encrypted tokens that are causing decryption errors,
and update or reset as needed:

```bash
wget -O /tmp/encrypted-tokens.rb https://gitlab.com/snippets/1876342/raw
gitlab-rails runner /tmp/encrypted-tokens.rb
```

## Geo

### Artifacts

#### Find failed artifacts

```ruby
Geo::JobArtifactRegistry.failed
```

#### Download artifact

```ruby
Gitlab::Geo::JobArtifactDownloader.new(:job_artifact, <artifact_id>).execute
```

#### Get a count of the synced artifacts

```ruby
Geo::JobArtifactRegistry.synced.count
```

#### Find `ID` of synced artifacts that are missing on primary

```ruby
Geo::JobArtifactRegistry.synced.missing_on_primary.pluck(:artifact_id)
```

### Repository verification failures

#### Get the number of verification failed repositories

```ruby
Geo::ProjectRegistryFinder.new.count_verification_failed_repositories
```

#### Find the verification failed repositories

```ruby
Geo::ProjectRegistry.verification_failed_repos
```

### Find repositories that failed to sync

```ruby
Geo::ProjectRegistryFinder.new.find_failed_project_registries('repository')
```

### Resync repositories

#### Queue up all repositories for resync. Sidekiq will handle each sync

```ruby
Geo::ProjectRegistry.update_all(resync_repository: true, resync_wiki: true)
```

#### Sync individual repository now

```ruby
project = Project.find_by_full_path('<group/project>')

Geo::RepositorySyncService.new(project).execute
```
