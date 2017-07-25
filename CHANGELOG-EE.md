Please view this file on the master branch, on stable branches it's out of date.

## 9.4.1 (2017-07-25)

- Cleans up mirror capacity in project destroy service if project is a scheduled mirror. !2445
- Fixes unscoping of imposed capacity limit by find_each method on Mirror scheduler. !2460
- Remove text underline from suggested approvers.

## 9.4.0 (2017-07-22)

- GeoLogCursor is part of a new experimental Geo replication system. !1988
- Add explicit licensing for Elasticsearch. !2108
- Add namespace license checks for Service Desk (EEP). !2109
- Add environment scope to secret variables to specify environments. !2112
- Namespace license checks for exporting issues (EES). !2164
- Retry Elasticsearch queries on failure. !2181
- Introduce namespace license checks for rebase before merge. !2200
- Geo: fix removal of repositories from disk on secondary nodes. !2210
- Add license checks for brundown charts. !2219
- Add namespace license checks for squash before merge. !2249
- Namespace license checks for fast-forward merge (EES). !2272
- Empty repository mirror no longer creates master branch with README automatically. !2276
- Introduce namespace licensing for issue weights (EES). !2291
- Add namespace license checks for Contribution Analytics. !2302
- Add license checks for focus mode on the issue board. !2303
- Add license checks for issue boards with milestones. !2315
- Add license checks for multiple issue boards. !2317
- Geo: Fix clone instructions in a secondary node for SSH protocol. !2319
- Namespace license checks Issue & MR template. !2321
- Introduce namespace license checks for merge request approvers (EES). !2324
- Introduce namespace license checks for Push Rules (EES). !2335
- Geo: Implement alternative to geo_{primary|secondary}_role in gitlab.yml. !2352
- Geo: Added extra SystemCheck checks. !2354
- Implement progressive elasticsearch indexing for project mirrors. !2393
- Fix undefined method quote when database load balancing is used. !2430
- Improve the performance of the project list API. !12679
- fix approver placeholder icon in ie11.
- Add public API for listing, creating and deleting Related Issues.
- All artifacts are now browsable.
- Escape symbols in exported CSV columns to prevent command execution in Microsoft Excel.
- Geo - Fix RepositorySyncService when cannot obtain a lease to sync a repository.
- Prevent mirror user to be assigned to users other than the current one.
- Geo - Makes the projects synchronization faster on secondaries nodes.
- Only show the LDAP sync banner on first login.
- Enable service desk be default.
- Fix creation of push rules via POST API.
- Fix Geo middleware to work properly with multiple requests.
- [GitLab.com only] Add Slack applicationq service.
- Speed up checking for approvers when approvers are specified on the MR.
- Allows manually adding bi-directional relationships between issues in the issue page (EES feature).
- Add Geo repository renamed event log.
- Merge states to allow realtime with deploy boards.
- Fix 500 error when approvals are enabled and editing an MR conflicts with another edit.
- add toggle for overriding approvers per MR.
- Add optional sha param when approving a merge request through the API.
- Allow updating shared_runners_minutes_limit on admin Namespace API.
- Allow to Store Artifacts on Object Storage.
- Adding support for AWS ec2 instance profile credentials with elasticsearch. (Matt Gresko)
- Fixed edit issue boards milestone action buttons not sticking to bottom of dropdown.
- Respect the external user setting in Elasticsearch.

## 9.3.9 (2017-07-20)

- No changes.

## 9.3.8 (2017-07-19)

- Escape symbols in exported CSV columns to prevent command execution in Microsoft Excel.
- Prevent mirror user to be assigned to users other than the current one.

## 9.3.7 (2017-07-18)

- No changes.

## 9.3.6 (2017-07-12)

- Geo: Fix clone instructions in a secondary node for SSH protocol. !2319
- Implement progressive elasticsearch indexing for project mirrors. !2393

## 9.3.5 (2017-07-05)

- Make admin mirror application setting Gitlab.com exclusive. !2307
- Make Geo::RepositorySyncService force create a repo.

## 9.3.4 (2017-07-03)

- Update gitlab-shell to 5.1.1 to fix Post Recieve errors

## 9.3.3 (2017-06-30)

- Add metrics to both remote and non remote mirroring. !2118
- Forces import worker with mirror to insert mirror in front of queue. !2231
- Fix locked and stale SSH keys file from 9.3.0 upgrade. !2240
- Fix crash in LDAP sync when user was removed. !2289
- allow rebase for unapproved merge requests.
- Geo - Fix path_with_namespace for instances of Geo::DeletedProject.

## 9.3.2 (2017-06-27)

- Fix GitLab check: Problem with Elastic Search. !2278

## 9.3.1 (2017-06-26)

- Geo: fix removal of repositories from disk on secondary nodes. !2210
- Fix Geo middleware to work properly with multiple requests.

## 9.3.0 (2017-06-22)

- Per user/group access levels for Protected Tags. !1629
- Add a user's memberships when logging in through LDAP. !1819
- Add server-wide Audit Log admin screen. !1852
- Move pull mirroring to adaptive scheduling. !1853
- Create a push rule to check the branch name. !1896 (Riccardo Padovani)
- Add shared_runners_minutes_limit to groups and users API. !1942
- Compare codeclimate artifacts on the merge request page. !1984
- Lookup users by email in LDAP if lookup by DN fails during sync. !2003
- Update mirror_user for project when mirror_user is deleted. !2013 (Athar Hameed)
- Geo: persist clone url prefix in the database. !2015
- Geo: prevent Gitlab::Git::Repository::NoRepository from stucking replication. !2115
- Geo: fixed Dynamic Backoff strategy that was not being used by workers. !2128
- [Elasticsearch] Improve code search for camel case.
- Fixed header being over issue boards when in focus mode.
- Fix: Approvals not reset if changing target branch.
- Fix bug where files over 2 GB would not be saved in Geo tracking DB.
- Add primary node clone URL to Geo secondary 'How to work faster with Geo' popover.
- Fix broken time sync leeway with Geo.
- Gracefully handle case when Geo secondary does not have the right db_key_base.
- Use the current node configuration to populate suggested new URL for Geo node.
- Check if a merge request is approved when merging from API or slash command.
- Add closed_at field to issue CSV export.
- Geo - Properly set tracking database connection and cron jobs on secondary nodes.
- Add push events to Geo event log.
- fix Rebase being disabled for unapproved MRs.
- Fix approvers dropdown when creating a merge request from a fork.
- Add relation between Pipelines.
- Allow to Trigger Pipeline using CI Job Token.
- Allow to view Personal pipelines quota.
- Geo - Use GeoNode#clone_url_prefix for the Geo::RepositorySyncService.
- Elasticsearch searches through the project description.
- Fix: /unassign by default unassigns everyone. Implement /reassign command.
- Speed up checking for approvers remaining.

## 9.2.9 (2017-07-20)

- No changes.

## 9.2.8 (2017-07-19)

- Escape symbols in exported CSV columns to prevent command execution in Microsoft Excel.
- Prevent mirror user to be assigned to users other than the current one.

## 9.2.7 (2017-06-21)

- Geo: fixed Dynamic Backoff strategy that was not being used by workers. !2128
- fix Rebase being disabled for unapproved MRs.

## 9.2.6 (2017-06-16)

- Geo: backported fix from 9.3 for big repository sync issues. !2000
- Geo - Properly set tracking database connection and cron jobs on secondary nodes.
- Fix approvers dropdown when creating a merge request from a fork.
- Fixed header being over issue boards when in focus mode.
- Fix bug where files over 2 GB would not be saved in Geo tracking DB.

## 9.2.5 (2017-06-07)

- No changes.

## 9.2.4 (2017-06-02)

- No changes.
- No changes.

## 9.2.3 (2017-05-31)

- No changes.
- No changes.
- Respect the external user setting in Elasticsearch.

## 9.2.2 (2017-05-25)

- No changes.

## 9.2.1 (2017-05-23)

- No changes.

## 9.2.0 (2017-05-22)

- Stop using sidekiq cron for push mirrors. !1616
- Inline RSS button with Export Issues button for mobile. !1637
- Highlight Contribution Analytics tab under groups when active, remove sub-nav items. !1677
- Uses etag polling for deployboards. !1713
- Support more elasticsearch versions. !1716
- Support advanced search queries using elasticsearch. !1770
- Remove superfluous wording on push rules. !1811
- Geo - Fix signing out from secondary node when "Remember me" option is checked. !1903
- Add global wiki search using Elasticsearch.
- Remove warning about protecting Service Desk email from form.
- Geo: Resync repositories that have been updated recently.
- Respect project features when searching alternative branches with elasticsearch enabled.
- Backfill projects where the last attempt to backfill failed.
- Fix MR approvals sentence when all approvers need to approve the MR.
- Fix for XSS in project mirror errors caused by Hamlit filter usage.
- Feature availability check using feature list AND license addons.
- Disable mirror workers for Geo secondaries.

## 9.1.9 (2017-07-20)

- No changes.

## 9.1.8 (2017-07-19)

- Escape symbols in exported CSV columns to prevent command execution in Microsoft Excel.
- Prevent mirror user to be assigned to users other than the current one.

## 9.1.7 (2017-06-07)

- No changes.

## 9.1.6 (2017-06-02)

- No changes.

## 9.1.5 (2017-05-31)

- Respect the external user setting in Elasticsearch.

## 9.1.4 (2017-05-12)

- Remove warning about protecting Service Desk email from form.
- Backfill projects where the last attempt to backfill failed.

## 9.1.3 (2017-05-05)

- No changes.
- No changes.
- No changes.
- Respect project features when searching alternative branches with elasticsearch enabled.
- Fix for XSS in project mirror errors caused by Hamlit filter usage.

## 9.1.2 (2017-05-01)

- No changes.
- No changes.
- No changes.
- Fix commit search on some elasticsearch indexes. !1745
- Fix emailing issues to projects when Service Desk is enabled.
- Fix bug where Geo secondary Sidekiq cron jobs would not be activated if settings changed.

## 9.1.1 (2017-04-26)

- No changes.

## 9.1.0 (2017-04-22)

- Fix rake gitlab:env:info elasticsearch datum. !1422
- Fix 500 errors caused by elasticsearch results referencing garbage-collected commits. !1430
- Adds timeout option to push mirrors. !1439
- elasticsearch: Add support for an experimental repository indexer. !1483
- Update color palette to a more harmonious and consistent one. !1500
- Cache Gitlab::Geo queries. !1507
- Add Service Desk feature. !1508
- Fix pre-receive hooks when using Git 2.11 or later. !1525
- Geo: Add support to sync avatars and attachments. !1562
- Fix Elasticsearch not working when URL ends with a forward slash. !1566
- Allow admins to perform global searches with Elasticsearch. !1578
- Periodically persists users activity to users.last_activity_on. !1597
- Removes duplicate count of LFS objects from repository_and_lfs_size method. !1599
- Fix searching notes and snippets as an auditor. !1674
- Fix searching for notes with elasticsearch when a user is a member of many projects. !1675
- Fix type declarations for spend/estimate values.
- Speed up suggested approvers on MR creation.
- Fix squashing MRs when the repository contains a ref named HEAD.
- Fix approver count reset when editing assignee or labels.
- Geo: handle git failures on GeoRepositoryFetchWorker.
- Give each elasticsearch worker its own sidekiq queue.
- Fixes broken link to pipeline quota.
- Prevent filtering issues by multiple Milestones or Authors.
- Fix 500 error when selecting a mirror user.
- Add index to approvals.merge_request_id.
- Added mock data for Deployboard.
- Add uuid to usage ping.
- Expose board project and milestone on boards API.
- Fix active user count to ignore internal users.
- Add warning when burndown data is not accurate.
- Check if incoming emails and email key are available for service desk.
- Add burndown chart to milestones.
- Make deployboard to be visible by default.
- Add a Rake task to make the current node the primary Geo node.
- Return 404 instead of a 500 error on API status endpoint if Geo tracking DB is not enabled.
- Remove N+1 queries for Groups::AnalyticsController.
- Show user cohorts data when usage ping is enabled.
- Visualise Canary Deployments.

## 9.0.12 (2017-07-20)

- No changes.

## 9.0.11 (2017-07-19)

- Escape symbols in exported CSV columns to prevent command execution in Microsoft Excel.
- Prevent mirror user to be assigned to users other than the current one.

## 9.0.10 (2017-06-07)

- No changes.

## 9.0.9 (2017-06-02)

- No changes.

## 9.0.8 (2017-05-31)

- Respect the external user setting in Elasticsearch.

## 9.0.7 (2017-05-05)

- Respect project features when searching alternative branches with elasticsearch enabled.
- Fix for XSS in project mirror errors caused by Hamlit filter usage.

## 9.0.6 (2017-04-21)

- Cache Gitlab::Geo queries. !1507
- Fix searching for notes with elasticsearch when a user is a member of many projects. !1675
- Fix 500 error when selecting a mirror user.
- Fix active user count to ignore internal users.

## 9.0.5 (2017-04-10)

- Return 404 instead of a 500 error on API status endpoint if Geo tracking DB is not enabled.

## 9.0.4 (2017-04-05)

- No changes.

## 9.0.3 (2017-04-05)

- Allow to edit pipelines quota for user.
- Fixed label resetting when sorting by weight. (James Clark)
- Fixed issue boards milestone toggle text not updating when filtering.
- Fixed mirror user dropdown not displaying.

## 9.0.2 (2017-03-29)

- No changes.

## 9.0.1 (2017-03-28)

- No changes.

## 9.0.0 (2017-03-22)

- Geo: Replicate repository creation in Geo secondary node. !952
- Make approval system notes lowercase. !1125
- Issues can be exported as CSV, via email. !1126
- Try to update mirrors again after 15 minutes if the previous update failed. !1183
- Adds abitlity to render deploy boards in the frontend side. !1233
- Add filtered search to MR page. !1243
- Update project list API returns with approvals_before_merge attribute. !1245 (Geoff Webster)
- Catch Net::LDAP::DN exceptions in EE::Gitlab::LDAP::Group. !1260
- API: Use `post ":id/#{type}/:subscribable_id/subscribe"` to subscribe and `post ":id/#{type}/:subscribable_id/unsubscribe"` to unsubscribe from a resource. !1274 (Robert Schilling)
- API: Remove deprecated fields Notes#upvotes and Notes#downvotes. !1275 (Robert Schilling)
- Deploy board backend. !1278
- API: Remove the ProjectGitHook API. !1301 (Robert Schilling)
- Expose elasticsearch client params for AWS signing and HTTPS. !1305 (Matt Gresko)
- Fix LDAP DN case-mismatch bug in LDAP group sync. !1337
- Remove es6 file extension from JavaScript files. !1344 (winniehell)
- Geo: Don't load dependent models when fetching an existing GeoNode from the database. !1348
- Parallelise the gitlab:elastic:index_database Rake task. !1361
- Robustify reading attributes for elasticsearch. !1365
- Introduce one additional thread into bin/elastic_repo_indexer. !1372
- Show hook errors for fast-forward merges. !1375
- Allow all parameters of group webhooks to be set through the UI. !1376
- Fix Elasticsearch queries when a group_id is specified. !1423
- Check the right index mapping based on Rails environment for rake gitlab:elastic:add_feature_visiblity_levels_to_project. !1473
- Fix issues with another milestone that has a matching list label could not be added to a board.
- Only admins or group owners can set LDAP overrides.
- Add support for load balancing database queries.
- Only replace non-approval mr-widget-footer on getMergeStatus.
- Remove repository_storage from V4 "/application/settings" settings API.
- Added headers to protected branches access dropdowns.
- Remove support for Git Annex.
- Repositioned multiple issue boards selector.
- Added back weight in issue rows on issue list.
- Add basic support for GitLab Geo file transfers over HTTP.
- Added weight slash command.
- Set deployment status invalid when the environments does not match a k8s label.
- Combined deploy keys, push rules, protect branches and mirror repository settings options into a single one called Repository.
- Rebase - fix commiter email & name.
- Adds a EE specific dev favicon.
- Elastic security fix: Respect feature visibility level.
- Update Elasticsearch to 5.1.
- [Elasticsearch] More efficient search.
- Get Geo secondaries nodes statuses over AJAX.

## 8.17.7 (2017-07-19)

- Prevent mirror user to be assigned to users other than the current one.

## 8.17.6 (2017-05-05)

- Respect project features when searching alternative branches with elasticsearch enabled.

## 8.17.5 (2017-04-05)

- No changes.

## 8.17.4 (2017-03-19)

- Elastic security fix: Respect feature visibility level.

## 8.17.3 (2017-03-07)

- No changes.

## 8.17.2 (2017-03-01)

- No changes.

## 8.17.1 (2017-02-28)

- Fix admin email notification recipient group select list.
- Add repository_storage field back to projects API for admin users.
- Don't try to update a project's external service caches on a secondary Geo node.
- Fixed merge request state not updating when approvals feature is active.
- Improve error messages when squashing fails.

## 8.17.0 (2017-02-22)

- Read-only "auditor" user role. !998
- Also reset approvals on push when merge request is closed. !1051
- Copy commit SHA to clipboard. !1066
- Pull EE specific Gitlab::Auth code in to its own module. !1112
- Geo: Added `gitlab:geo:check` and improved `gitlab:envinfo` rake tasks. !1120
- Geo: send the new event type with the backfill function. !1157
- Re-add removed params from projects and issues V3 API. !1209
- Add configurable minimum mirror sync time in admin section. !1217
- Move RepositoryUpdateRemoteMirrorWorker jobs to project_mirror Sidekiq queue. !1234
- Change Builds word to Pipelines in Mirror settings page.
- Fix bundle tag in anaytics page.
- Support v4 API for GitLab Geo endpoints.
- Fixed merge request environment link not displaying.
- Reduce queries needed to check if node is a primary or secondary Geo node.
- Allow squashing merge requests into a single commit.

## 8.16.9 (2017-04-05)

- No changes.

## 8.16.8 (2017-03-19)

- No changes.
- No changes.
- No changes.
- Elastic security fix: Respect feature visibility level.

## 8.16.7 (2017-02-27)

- Fixed merge request state not updating when approvals feature is active.

## 8.16.6 (2017-02-17)

- Geo: send the new event type with the backfill function. !1157
- Move RepositoryUpdateRemoteMirrorWorker jobs to project_mirror Sidekiq queue. !1234
- Fixed merge request environment link not displaying.
- Reduce queries needed to check if node is a primary or secondary Geo node.
- Read true-up info from license and validate it. !1159

## 8.16.5 (2017-02-14)

- No changes.

## 8.16.4 (2017-02-02)

- Disable all merge acceptance buttons pending MR approval.

## 8.16.3 (2017-01-27)

- Fix sidekiq cluster mishandling of queue names. !1117

## 8.16.2 (2017-01-25)

- Track Mattermost usage in usage ping. !1071
- Fix count of required approvals displayed on MR edit form. !1082
- Fix updating approvals count when editing an MR. !1106
- Don't try to show assignee in approved_merge_request_email if there's no assignee.

## 8.16.1 (2017-01-23)

- No changes.

## 8.16.0 (2017-01-22)

- Allow to limit shared runners minutes quota for group. !965
- About GitLab link in sidebar that links to help page. !1008
- Prevent 500 error when uploading/entering a blank license. !1016
- Add more push rules to the API. !1022 (Robert Schilling)
- Expose issue weight in the API. !1023 (Robert Schilling)
- Copy <some text> to clipboard. !1048

## 8.15.8 (2017-03-19)

- No changes.
- No changes.
- Elastic security fix: Respect feature visibility level.

## 8.15.7 (2017-02-15)

- No changes.

## 8.15.6 (2017-02-14)

- No changes.

## 8.15.5 (2017-01-20)

- No changes.

## 8.15.4 (2017-01-09)

- No changes.

## 8.15.3 (2017-01-06)

- Disable LDAP permission override in project members edit list.
- Perform only one fetch per push on Geo secondary nodes.

## 8.15.2 (2016-12-27)

- No changes.
- Fix ES search for non-default branches.

## 8.15.1 (2016-12-23)

- Fix 404/500 error while navigating to the 'show/destroy' pages. !993

## 8.15.0 (2016-12-22)

- Adds a check ensure only active, ie. non-blocked users can be emailed from the admin panel.
- Add user activities API.
- Add milestone total weight to the milestone summary.
- Allow master/owner to change permission levels when LDAP group sync is enabled. !822
- Geo: Improve project view UI to teach users how to clone from a secondary Geo node and push to a primary. !905
- Technical debt follow-up from restricting pushes / merges by group. !927
- Geo: Enables nodes to be removed even without proper license. !978
- Update validates_hostname to 1.0.6 to fix a bug in parsing hexadecimal-looking domain names. !982

## 8.14.10 (2017-02-15)

- No changes.

## 8.14.9 (2017-02-14)

- No changes.

## 8.14.8 (2017-01-25)

- No changes.

## 8.14.7 (2017-01-21)

- No changes.

## 8.14.6 (2017-01-10)

- No changes.

## 8.14.5 (2016-12-14)

- Add milestone total weight to the milestone summary.

## 8.14.4 (2016-12-08)

- No changes.

## 8.14.3 (2016-12-02)

- No changes.

## 8.14.2 (2016-12-01)

- No changes.

## 8.14.1 (2016-11-28)

- Fix: MergeRequestSerializer breaks on MergeRequest#rebase_dir_path when source_project doesn't exist anymore.

## 8.14.0 (2016-11-22)

- Added Backfill service for Geo. !861
- Fix for autosuggested approvers(https://gitlab.com/gitlab-org/gitlab-ee/issues/1273).
- Gracefully recover from previously failed rebase.
- Disable retries for remote mirror update worker. !848
- Fix Approvals API documentation.
- Add ability to set approvals_before_merge for project through the API.
- gitlab:check rake task checks ES version according to requirements
- Convert ASCII-8BIT LDAP DNs to UTF-8 to avoid unnecessary user deletions
- [Fix] Only owner can see "Projects" button in group edit menu

## 8.13.12 (2017-01-21)

- No changes.

## 8.13.11 (2017-01-10)

- No changes.

## 8.13.10 (2016-12-14)

- No changes.

## 8.13.9 (2016-12-08)

- No changes.

## 8.13.8 (2016-12-02)

- No changes.

## 8.13.7 (2016-11-28)

- No changes.

## 8.13.6 (2016-11-17)

- Disable retries for remote mirror update worker. !848
- Fixed cache clearing on secondary Geo nodes. !869
- Geo: fix a problem that prevented git cloning from secondary node. !873

## 8.13.5 (2016-11-08)

- No changes

## 8.13.4 (2016-11-07)

- Weight dropdown in issue filter form does not stay selected. !826

## 8.13.3 (2016-11-02)

- No changes

## 8.13.2 (2016-10-31)

- Don't pass a current user to Member#add_user in LDAP group sync. !830

## 8.13.1 (2016-10-25)

- Hide multiple board actions if user doesnt have permissions. !816
- Fix Elasticsearch::Transport::Transport::Errors::BadRequest when ES is enabled. !818

## 8.13.0 (2016-10-22)

- Cache the last usage data to avoid unicorn timeouts
- Add user activity table and service to query for active users
- Fix 500 error updating mirror URLs for projects
- Restrict protected branch access to specific groups !645
- Fix validations related to mirroring settings form. !773
- Add multiple issue boards. !782
- Fix Git access panel for Wikis when Kerberos authentication is enabled (Borja Aparicio)
- Decrease maximum time that GitLab waits for a mirror to finish !791 (Borja Aparicio)
- User groups (that can be assigned as approvers)
- Fix a search for non-default branches when ES is enabled
- Re-organized the Sidekiq queues for EE specific workers

## 8.12.12 (2016-12-08)

- No changes.

## 8.12.11 (2016-12-02)

- No changes.

## 8.12.10 (2016-11-28)

- No changes.

## 8.12.9 (2016-11-07)

- No changes

## 8.12.8 (2016-11-02)

- No changes

## 8.12.7

  - No EE-specific changes

## 8.12.6

  - No EE-specific changes

## 8.12.5

  - No EE-specific changes

## 8.12.4

  - [ES] Indexer works with smaller batches of repositories to not exceed NOFILE limit. !774

## 8.12.3

  - Fix prevent_secrets checkbox on admin view

## 8.12.2

  - Fix bug when protecting a branch due to missing url paramenter in request !760
  - Ignore unknown project ID in RepositoryUpdateMirrorWorker

## 8.12.1

  - Prevent secrets to be pushed to the repository
  - Prevent secrets to be pushed to the repository

## 8.12.0 (2016-09-22)

  - Include more data in EE usage ping
  - Reduce UPDATE queries when moving between import states on projects
  - [ES] Instrument Elasticsearch::Git::Repository
  - Request only the LDAP attributes we need
  - Add 'Sync now' to group members page !704
  - Add repository size limits and enforce them !740
  - [ES] Instrument other Gitlab::Elastic classes
  - [ES] Fix: Elasticsearch does not find partial matches in project names
  - Faster Active Directory group membership resolution !719
  - [ES] Global code search
  - [ES] Improve logging
  - Fix projects with remote mirrors asynchronously destruction

## 8.11.11 (2016-11-07)

- No changes

## 8.11.10 (2016-11-02)

- No changes

## 8.11.9

  - No EE-specific changes

## 8.11.8

  - No EE-specific changes

## 8.11.7

  - Refactor Protected Branches dropdown. !687
  - Fix mirrored projects allowing empty import urls. !700

## 8.11.6

  - Exclude blocked users from potential MR approvers.

## 8.11.5

  - API: Restore backward-compatibility for POST /projects/:id/members when membership is locked

## 8.11.4

  - No EE-specific changes

## 8.11.3

  - [ES] Add logging to indexer
  - Fix missing EE-specific service parameters for Jenkins CI
  - Set the correct `GL_PROTOCOL` when rebasing !691
  - [ES] Elasticsearch workers checks ES settings before running

## 8.11.2

  - Additional documentation on protected branches for EE
  - Change slash commands docs location

## 8.11.1

  - Pulled due to packaging error.

## 8.11.0 (2016-08-22)

  - Allow projects to be moved between repository storages
  - Add rake task to remove old repository copies from repositories moved to another storage
  - Performance improvement of push rules
  - Temporary fix for #825 - LDAP sync converts access requests to members. !655
  - Optimize commit and diff changes access check to reduce git operations
  - Allow syncing a group against all providers at once
  - Change LdapGroupSyncWorker to use new LDAP group sync classes
  - Allow LDAP `sync_ssh_keys` setting to be set to `true`
  - Removed unused GitLab GEO database index
  - Restrict protected branch access to specific users !581
  - Enable monitoring for ES classes
  - [Elastic] Improve code search
  - [Elastic] Significant improvement of global search performance
  - [Fix] Push rules check existing commits in some cases
  - [ES] Limit amount of retries for sidekiq jobs
  - Fix Projects::UpdateMirrorService to allow tags pointing to blob objects

## 8.10.12

  - No EE-specific changes

## 8.10.11

  - No EE-specific changes

## 8.10.10

  - No EE-specific changes

## 8.10.9

  - Exclude blocked users from potential MR approvers.

## 8.10.8

  - No EE-specific changes

## 8.10.7

  - No EE-specific changes

## 8.10.6

  - Fix race condition with UpdateMirrorWorker Lease. !641

## 8.10.5

  - Used cached value of project count in `Elastic::RepositoriesSearch` to reduce DB load. !637

## 8.10.4

  - Fix available users in userselect dropdown when there is more than one userselect on the page. !604 (Rik de Groot)
  - Fix updating skipped approvers in search list on removal. !604 (Rik de Groot)

## 8.10.3

  - Fix regression in Git Annex permission check. !599
  - [Elastic] Fix commit search for some URLs. !605
  - [Elastic][Fix] Commit search breaks for some URLs on gitlab-ce project

## 8.10.2

  - Fix pagination on search result page when ES search is enabled. !592
  - Decouple an ES index update from `RepositoryUpdateMirrorWorker`. !593
  - Fix broken `user_allowed?` check in Git Annex push. !597

## 8.10.1

  - No EE-specific changes

## 8.10.0 (2016-07-22)

  - Add EE license usage ping !557
  - Rename Git Hooks to Push Rules
  - Fix EE keys fingerprint add index migration if came from CE
  - Add todos for MR approvers !547
  - Replace LDAP group sync exclusive lease with state machine
  - Prevent the author of an MR from being on the approvers list
  - Isolate EE LDAP library code in EE module (Part 1) !511
  - Make Elasticsearch indexer run as an async task
  - Fix of removing wiki data from index when project is deleted
  - Ticket-based Kerberos authentication (SPNEGO)
  - [Elastic] Suppress ActiveRecord::RecordNotFound error in ElasticIndexWorker

## 8.9.10

  - No EE-specific changes

## 8.9.9

  - No EE-specific changes

## 8.9.8

  - No EE-specific changes

## 8.9.7

  - No EE-specific changes

## 8.9.6

  - Avoid adding index for key fingerprint if it already exists. !539

## 8.9.5

  - Fix of quoted text in lock tooltip. !518

## 8.9.4

  - Improve how File Lock feature works with nested items. !497

## 8.9.3

  - Fix encrypted data backwards compatibility after upgrading attr_encrypted gem. !502
  - Fix creating MRs on forks of deleted projects. !503
  - Roll back Grack::Auth to fix Git HTTP SPNEGO. !504

## 8.9.2

  - [Elastic] Fix visibility of snippets when searching.

## 8.9.1

  - Improve Geo documentation. !431
  - Fix remote mirror stuck on started issue. !491
  - Fix MR creation from forks where target project has approvals enabled. !496
  - Fix MR edit where target project has approvals enabled. !496
  - Fix vertical alignment of git-hooks page. !499

## 8.9.0 (2016-06-22)

  - Fix JenkinsService test button
  - Fix nil user handling in UpdateMirrorService
  - Allow overriding the number of approvers for a merge request
  - Allow LDAP to mark users as external based on their group membership. !432
  - Instrument instance methods of Gitlab::InsecureKeyFingerprint class
  - Add API endpoint for Merge Request Approvals !449
  - Send notification email when merge request is approved
  - Distribute RepositoryUpdateMirror jobs in time and add exclusive lease on them by project_id
  - [Elastic] Move ES settings to application settings
  - Always allow merging a merge request whenever fast-forward is possible. !454
  - Disable mirror flag for projects without import_url
  - UpdateMirror service return an error status when no mirror
  - Don't reset approvals when rebasing an MR from the UI
  - Show flash notice when Git Hooks are updated successfully
  - Remove explicit Gitlab::Metrics.action assignments, are already automatic.
  - [Elastic] Project members with guest role can't access confidential issues
  - Ability to lock file or folder in the repository
  - Fix: Git hooks don't fire when committing from the UI

## 8.8.9

  - No EE-specific changes

## 8.8.8

  - No EE-specific changes

## 8.8.7

  - No EE-specific changes

## 8.8.6

  - [Elastic] Fix visibility of snippets when searching.

## 8.8.5

  - Make sure OAuth routes that we generate for Geo matches with the ones in Rails routes !444

## 8.8.4

  - Remove license overusage message

## 8.8.3

  - Add standard web hook headers to Jenkins CI post. !374
  - Gracefully handle malformed DNs in LDAP group sync. !392
  - Reduce load on DB for license upgrade check. !421
  - Make it clear the license overusage message is visible only to admins. !423
  - Fix Git hook validations for fast-forward merges. !427
  - [Elastic] In search results, only show notes on confidential issues that the user has access to.

## 8.8.2

  - Fix repository mirror updates for new imports stuck in started
  - [Elastic] Search through the filenames. !409
  - Fix repository mirror updates for new imports stuck in "started" state. !416

## 8.8.1

  - No EE-specific changes

## 8.8.0 (2016-05-22)

  - [Elastic] Database indexer prints its status
  - [Elastic][Fix] Database indexer skips projects with invalid HEAD reference
  - Fix skipping pages when restoring backups
  - Add EE license via API !400
  - [Elastic] More efficient snippets search
  - [Elastic] Add rake task for removing all indexes
  - [Elastic] Add rake task for clearing indexing status
  - [Elastic] Improve code search
  - [Elastic] Fix encoding issues during indexing
  - Warn admin if current active count exceeds license
  - [Elastic] Search through the filenames
  - Set KRB5 as default clone protocol when Kerberos is enabled and user is logged in (Borja Aparicio)
  - Add support for Admin Groups to SAML
  - Reduce emails-on-push HTML size by using a simple monospace font
  - API requests to /internal/authorized_keys are now tagged properly
  - Geo: Single Sign Out support !380

## 8.7.9

  - No EE-specific changes

## 8.7.8

  - [Elastic] Fix visibility of snippets when searching.

## 8.7.7

  - No EE-specific changes

## 8.7.6

  - Bump GitLab Pages to 0.2.4 to fix Content-Type for predefined 404

## 8.7.5

  - No EE-specific changes

## 8.7.4

  - Delete ProjectImportData record only if Project is not a mirror !370
  - Fixed typo in GitLab GEO license check alert !379
  - Fix LDAP access level spillover bug !499

## 8.7.3

  - No EE-specific changes

## 8.7.2

  - Fix MR notifications for slack and hipchat when approvals are fullfiled. !325
  - GitLab Geo: Merge requests on Secondary should not check mergeable status

## 8.7.1

  - No EE-specific changes

## 8.7.0 (2016-04-22)

  - Update GitLab Pages to 0.2.1: support user-defined 404 pages
  - Refactor group sync to pull access level logic to its own class. !306
  - [Elastic] Stabilize database indexer if database is inconsistent
  - Add ability to sync to remote mirrors. !249
  - GitLab Geo: Many replication improvements and fixes !354

## 8.6.9

  - No EE-specific changes

## 8.6.8

  - No EE-specific changes

## 8.6.7

  - No EE-specific changes

## 8.6.6

  - Concat AD group recursive member results with regular member results. !333
  - Fix LDAP group sync regression for groups with member value `uid=<username>`. !335
  - Don't attempt to include too large diffs in e-mail-on-push messages (Stan Hu). !338

## 8.6.5

  - No EE-specific changes

## 8.6.4

  - No EE-specific changes

## 8.6.3

  - Fix other cases where git hooks would fail due to old commits. !310
  - Exit ElasticIndexerWorker's job happily if record cannot be found. !311
  - Fix "Reload with full diff" button not working (Stan Hu). !313

## 8.6.2

  - Fix old commits triggering git hooks on new branches branched off another branch. !281
  - Fix issue with deleted user in audit event (Stan Hu). !284
  - Mark pending todos as done when approving a merge request. !292
  - GitLab Geo: Display Attachments from Primary node. !302

## 8.6.1

  - Only rename the `light_logo` column in the `appearances` table if its not there yet. !290
  - Fix diffs in text part of email-on-push messages (Stan Hu). !293
  - Fix an issue with methods not accessible in some controllers. !295
  - Ensure Projects::ApproversController inherits from Projects::ApplicationController. !296

## 8.6.0 (2016-03-22)

  - Handle duplicate appearances table creation issue with upgrade from CE to EE
  - Add confidential issues
  - Improve weight filter for issues
  - Update settings and documentation for per-install LDAP sync time
  - Fire merge request webhooks when a merge request is approved
  - Add full diff highlighting to Email on push
  - Clear "stuck" mirror updates before periodically updating all mirrors
  - LDAP: Don't render Linked LDAP groups forms when LDAP is disabled
  - [Elastic] Add elastic checker to gitlab:check
  - [Elastic] Added UPDATE_INDEX option to rake task
  - [Elastic] Removing repository and wiki index after removing project
  - [Elastic] Update index on push to wiki
  - [Elastic] Use subprocesses for ElasticSearch index jobs
  - [Elastic] More accurate as_indexed_json (More stable database indexer)
  - [Elastic] Fix: Don't index newly created system messages and awards
  - [Elastic] Fixed exception on branch removing
  - [Elastic] Fix bin/elastic_repo_indexer to follow config
  - GitLab Geo: OAuth authentication
  - GitLab Geo: Wiki synchronization
  - GitLab Geo: ReadOnly Middleware improvements
  - GitLab Geo: SSH Keys synchronization
  - Allow SSL verification to be configurable when importing GitHub projects
  - Disable git-hooks for git annex commits

## 8.5.13

  - No EE-specific changes

## 8.5.12

  - No EE-specific changes

## 8.5.11

  - Fix vulnerability that made it possible to enumerate private projects belonging to group

## 8.5.10

  - No EE-specific changes

## 8.5.9

  - No EE-specific changes

## 8.5.8

  - GitLab Geo: Documentation

## 8.5.7

  - No EE-specific changes

## 8.5.6

  - No EE-specific changes

## 8.5.5

  - GitLab Geo: Repository synchronization between primary and secondary nodes
  - Add documentation for GitLab Pages
  - Fix importing projects from GitHub Enterprise Edition
  - Fix syntax error in init file
  - Only show group member roles if explicitly requested
  - GitLab Geo: Improve GeoNodes Admin screen
  - GitLab Geo: Avoid locking yourself out when adding a GeoNode

## 8.5.4

  - [Elastic][Security] Notes exposure

## 8.5.3

  - Prevent LDAP from downgrading a group's last owner
  - Update gitlab-elastic-search gem to 0.0.11

## 8.5.2

  - Update LDAP groups asynchronously
  - Fix an issue when weight text was displayed in Issuable collapsed sidebar
## 8.5.2

  - Fix importing projects from GitHub Enterprise Edition.

## 8.5.1

  - Fix adding pages domain to projects in groups

## 8.5.0 (2016-02-22)

  - Fix Elasticsearch blob results linking to the wrong reference ID (Stan Hu)
  - Show warning when mirror repository default branch could not be updated because it has diverged from upstream.
  - More reliable wiki indexer
  - GitLab Pages gets support for custom domain and custom certificate
  - Fix of Elastic indexer. It should not trigger record validation for projects
  - Fix of Elastic indexer. Stabilze indexer when serialized data is corrupted
  - [Elastic] Don't index unnecessary data into elastic

## 8.4.11

  - No EE-specific changes

## 8.4.10

  - No EE-specific changes

## 8.4.9

  - Fix vulnerability that made it possible to enumerate private projects belonging to group

## 8.4.8

  - No EE-specific changes

## 8.4.7

  - No EE-specific changes

## 8.4.6

  - No EE-specific changes

## 8.4.5

  - Update LDAP groups asynchronously

## 8.4.4

  - Re-introduce "Send email to users" link in Admin area
  - Fix category values for Jenkins and JenkinsDeprecated services
  - Fix Elasticsearch indexing for newly added snippets
  - Make Elasticsearch indexer more stable
  - Update gitlab-elasticsearch-git to 0.0.10 which contain a few important fixes

## 8.4.3

  - Elasticsearch: fix partial blob indexing on push
  - Elasticsearch: added advanced indexer for repositories
  - Fix Mirror User dropdown

## 8.4.2

  - Elasticsearch indexer performance improvements
  - Don't redirect away from Mirror Repository settings when repo is empty
  - Fix updating of branches in mirrored repository
  - Fix a 500 error preventing LDAP users with 2FA enabled from logging in
  - Rake task gitlab:elastic:index_repositories handles errors and shows progress
  - Partial indexing of repo on push (indexing changes only)

## 8.4.1

  - No EE-specific changes

## 8.4.0 (2016-01-22)

  - Add ability to create a note for user by admin
  - Fix "Commit was rejected by git hook", when max_file_size was set null in project's Git hooks
  - Fix "Approvals are not reset after a new push is made if the request is coming from a fork"
  - Fix "User is not automatically removed from suggested approvers list if user is deleted"
  - Add option to enforce a semi-linear history by only allowing merge requests to be merged that have been rebased
  - Add option to trigger builds when branches or tags are updated from a mirrored upstream repository
  - Ability to use Elasticsearch as a search engine

## 8.3.10

  - No EE-specific changes

## 8.3.9

  - No EE-specific changes

## 8.3.8

  - Fix vulnerability that made it possible to enumerate private projects belonging to group

## 8.3.7

  - No EE-specific changes

## 8.3.6

  - No EE-specific changes

## 8.3.5

  - No EE-specific changes

## 8.3.4

  - No EE-specific changes

## 8.3.3

  - Fix undefined method call in Jenkins integration service

## 8.3.2

  - No EE-specific changes

## 8.3.1

  - Rename "Group Statistics" to "Contribution Analytics"

## 8.3.0 (2015-12-22)

  - License information can now be retrieved via the API
  - Show Kerberos clone url when Kerberos enabled and url different than HTTP url (Borja Aparicio)
  - Fix bug with negative approvals required
  - Add group contribution analytics page
  - Add GitLab Pages
  - Add group contribution statistics page
  - Automatically import Kerberos identities from Active Directory when Kerberos is enabled (Alex Lossent)
  - Canonicalization of Kerberos identities to always include realm (Alex Lossent)

## 8.2.6

  - No EE-specific changes

## 8.2.5

  - No EE-specific changes

## 8.2.4

  - No EE-specific changes

## 8.2.3

  - No EE-specific changes

## 8.2.2

  - Fix 404 in redirection after removing a project (Stan Hu)
  - Ensure cached application settings are refreshed at startup (Stan Hu)
  - Fix Error 500 when viewing user's personal projects from admin page (Stan Hu)
  - Fix: Raw private snippets access workflow
  - Prevent "413 Request entity too large" errors when pushing large files with LFS
  - Ensure GitLab fires custom update hooks after commit via UI

## 8.2.1

  - Forcefully update builds that didn't want to update with state machine
  - Fix: saving GitLabCiService as Admin Template

## 8.2.0 (2015-11-22)

  - Invalidate stored jira password if the endpoint URL is changed
  - Fix: Page is not reloaded periodically to check if rebase is finished
  - When someone as marked as a required approver for a merge request, an email should be sent
  - Allow configuring the Jira API path (Alex Lossent)
  - Fix "Rebase onto master"
  - Ensure a comment is properly recorded in JIRA when a merge request is accepted
  - Allow groups to appear in the `Share with group` share if the group owner allows it
  - Add option to mirror an upstream repository.

## 8.1.4

  - Fix bug in JIRA integration which prevented merge requests from being accepted when using issue closing pattern

## 8.1.3

  - Fix "Rebase onto master"

## 8.1.2

  - Prevent a 500 error related to the JIRA external issue tracker service

## 8.1.1

  - Removed, see 8.1.2

## 8.1.0 (2015-10-22)

  - Add documentation for "Share project with group" API call
  - Added an issues template (Hannes Rosenögger)
  - Add documentation for "Share project with group" API call
  - Ability to disable 'Share with Group' feature (via UI and API)

## 8.0.6

  - No EE-specific changes

## 8.0.5

  - "Multi-project" and "Treat unstable builds as passing" parameters for
    the Jenkins CI service are now correctly persisted.
  - Correct the build URL when "Multi-project" is enabled for the Jenkins CI
    service.

## 8.0.4

  - Fix multi-project setup for Jenkins

## 8.0.3

  - No EE-specific changes

## 8.0.2

  - No EE-specific changes

## 8.0.1

  - Correct gem dependency versions
  - Re-add the "Help Text" feature that was inadvertently removed

## 8.0.0 (2015-09-22)

  - Fix navigation issue when viewing Group Settings pages
  - Guests and Reporters can approve merge request as well
  - Add fast-forward merge option in project settings
  - Separate rebase & fast-forward merge features

## 7.14.3

  - No changes

## 7.14.2

  - Fix the rebase before merge feature

## 7.14.1

  - Fix sign in form when just Kerberos is enabled

## 7.14.0 (2015-08-22)

  - Disable adding, updating and removing members from a group that is synced with LDAP
  - Don't send "Added to group" notifications when group is LDAP synched
  - Fix importing projects from GitHub Enterprise Edition.
  - Automatic approver suggestions (based on an authority of the code)
  - Add support for Jenkins unstable status
  - Automatic approver suggestions (based on an authority of the code)
  - Support Kerberos ticket-based authentication for Git HTTP access

## 7.13.3

  - Merge community edition changes for version 7.13.3
  - Improved validation for an approver
  - Don't resend admin email to everyone if one delivery fails
  - Added migration for removing of invalid approvers

## 7.13.2

  - Fix group web hook
  - Don't resend admin email to everyone if one delivery fails

## 7.13.1

  - Merge community edition changes for version 7.13.1
  - Fix: "Rebase before merge" doesn't work when source branch is in the same project

## 7.13.0 (2015-07-22)

  - Fix git hook validation on initial push to master branch.
  - Reset approvals on push
  - Fix 500 error when the source project of an MR is deleted
  - Ability to define merge request approvers

## 7.12.2

  - Fixed the alignment of project settings icons

## 7.12.1

  - No changes specific to EE

## 7.12.0 (2015-06-22)

  - Fix error when viewing merge request with a commit that includes "Closes #<issue id>".
  - Enhance LDAP group synchronization to check also for member attributes that only contain "uid=<username>"
  - Enhance LDAP group synchronization to check also for submember attributes
  - Prevent LDAP group sync from removing a group's last owner
  - Add Git hook to validate maximum file size.
  - Project setting: approve merge request by N users before accept
  - Support automatic branch jobs created by Jenkins in CI Status
  - Add API support for adding and removing LDAP group links

## 7.11.4

  - no changes specific to EE

## 7.11.3

  - Fixed an issue with git annex

## 7.11.2

  - Fixed license upload and verification mechanism

## 7.11.0 (2015-05-22)

  - Skip git hooks commit validation when pushing new tag.
  - Add Two-factor authentication (2FA) for LDAP logins

## 7.10.1

  - Check if comment exists in Jira before sending a reference

## 7.10.0 (2015-04-22)

  - Improve UI for next pages: Group LDAP sync, Project git hooks, Project share with groups, Admin -> Appearance settigns
  - Default git hooks for new projects
  - Fix LDAP group links page by using new group members route.
  - Skip email confirmation when updated via LDAP.

## 7.9.0 (2015-03-22)

  - Strip prefixes and suffixes from synced SSH keys:
    `SSHKey:ssh-rsa keykeykey` and `ssh-rsa keykeykey (SSH key)` will now work
  - Check if LDAP admin group exists before querying for user membership
  - Use one custom header logo for all GitLab themes in appearance settings
  - Escape wildcards when searching LDAP by group name.
  - Group level Web Hooks
  - Don't allow project to be shared with the group it is already in.

## 7.8.0 (2015-02-22)

  - Improved Jira issue closing integration
  - Improved message logging for Jira integration
  - Added option of referencing JIRA issues from GitLab
  - Update Sidetiq to 0.6.3
  - Added Github Enterprise importer
  - When project has MR rebase enabled, MR will have rebase checkbox selected by default
  - Minor UI fixes for sidebar navigation
  - Manage large binaries with git annex

## 7.7.0 (2015-01-22)

  - Added custom header logo support (Drew Blessing)
  - Fixed preview appearance bug
  - Improve performance for selectboxes: project share page, admin email users page

## 7.6.2

  - Fix failing migrations for MySQL, LDAP

## 7.6.1

  - No changes

## 7.6.0 (2014-12-22)

  - Added Audit events related to membership changes for groups and projects
  - Added option to attempt a rebase before merging merge request
  - Dont show LDAP groups settings if LDAP disabled
  - Added member lock for groups to disallow membership additions on project level
  - Rebase on merge request. Introduced merge request option to rebase before merging
  - Better message for failed pushes because of git hooks
  - Kerberos support for web interface and git HTTP

## 7.5.3

  - Only set up Sidetiq from a Sidekiq server process (fixes Redis::InheritedError)

## 7.5.0 (2014-11-22)

  - Added an ability to check each author commit's email by regex
  - Added an ability to restrict commit authors to existing Gitlab users
  - Add an option for automatic daily LDAP user sync
  - Added git hook for preventing tag removal to API
  - Added git hook for setting commit message regex to API
  - Added an ability to block commits with certain filenames by regex expression
  - Improved a jenkins parser

## 7.4.4

  - Fix broken ldap migration

## 7.4.0 (2014-10-22)

  - Support for multiple LDAP servers
  - Skip AD specific LDAP checks
  - Do not show ldap users in dropdowns for groups with enabled ldap-sync
  - Update the JIRA integration documentation
  - Reset the homepage to show the GitLab logo by deleting the custom logo.

## 7.3.0 (2014-09-22)

  - Add an option to change the LDAP sync time from default 1 hour
  - User will receive an email when unsubscribed from admin notifications
  - Show group sharing members on /my/project/team
  - Improve explanation of the LDAP permission reset
  - Fix some navigation issues
  - Added support for multiple LDAP groups per Gitlab group

## 7.2.0 (2014-08-22)

  - Improve Redmine integration
  - Better logging for the JIRA issue closing service
  - Administrators can now send email to all users through the admin interface
  - JIRA issue transition ID is now customizable
  - LDAP group settings are now visible in admin group show page and group members page

## 7.1.0 (2014-07-22)

  - Synchronize LDAP-enabled GitLab administrators with an LDAP group (Marvin Frick, sponsored by SinnerSchrader)
  - Synchronize SSH keys with LDAP (Oleg Girko (Jolla) and Marvin Frick (SinnerSchrader))
  - Support Jenkins jobs with multiple modules (Marvin Frick, sponsored by SinnerSchrader)

## 7.0.0 (2014-06-22)

  - Fix: empty brand images are displayed as empty image_tag on login page (Marvin Frick, sponsored by SinnerSchrader)

## 6.9.4

  - Fix bug in JIRA Issue closing triggered by commit messages
  - Fix JIRA issue reference bug

## 6.9.3

  - Fix check CI status only when CI service is enabled(Daniel Aquino)

## 6.9.2

  - Merge community edition changes for version 6.9.2

## 6.9.1

  - Merge community edition changes for version 6.9.1

## 6.9.0 (2014-05-22)

  - Add support for closing Jira tickets with commits and MR
  - Template for Merge Request description can be added in project settings
  - Jenkins CI service
  - Fix LDAP email upper case bug

## 6.8.0 (2014-04-22)

  - Customise sign-in page with custom text and logo

## 6.7.1

  - Handle LDAP errors in Adapter#dn_matches_filter?

## 6.7.0 (2014-03-22)

  - Improve LDAP sign-in speed by reusing connections
  - Add support for Active Directory nested LDAP groups
  - Git hooks: Commit message regex
  - Git hooks: Deny git tag removal
  - Fix group edit in admin area

## 6.6.0 (2014-02-22)

  - Permission reset button for LDAP groups
  - Better performance with large numbers of users with access to one project

## 6.5.0 (2014-01-22)

  - Add reset permissions button to Group#members page

## 6.4.0 (2013-12-22)

  - Respect existing group permissions during sync with LDAP group (d3844662ec7ce816b0a85c8b40f66ee6c5ae90a1)

## 6.3.0 (2013-11-22)

  - When looking up a user by DN, use single scope (bc8a875df1609728f1c7674abef46c01168a0d20)
  - Try sAMAccountName if omniauth nickname is nil (9b7174c333fa07c44cc53b80459a115ef1856e38)

## 6.2.0 (2013-10-22)

  - API: expose ldap_cn and ldap_access group attributes
  - Use omniauth-ldap nickname attribute as GitLab username
  - Improve group sharing UI for installation with many groups
  - Fix empty LDAP group raises exception
  - Respect LDAP user filter for git access
