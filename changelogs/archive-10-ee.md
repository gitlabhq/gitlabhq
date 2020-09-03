## 10.8.6 (2018-07-17)

- No changes.

## 10.8.5 (2018-06-21)

- No changes.

## 10.8.4 (2018-06-06)

### Fixed (4 changes)

- Render a 403 when showing an access denied message. !5964
- Validate classification label on create & update. !5976
- Fix breadcrumbs being covered by System Header message.
- Treat external authorization service response status 403 as failure.


## 10.8.3 (2018-05-30)

- No changes.
- No changes.
### Fixed (1 change)

- Geo - Calculate the wiki checksum even when wiki is disabled. !5772

### Performance (1 change)

- Make Geo::PruneEventLogWorker delete rows more gently. !5835


## 10.8.2 (2018-05-28)

### Security (3 changes)

- Fixed XSS in protected branches & tags access dropdown.
- Escape name in merge request approvers dropdown.
- Fixes include directive to not allow SSRF requests.


## 10.8.1 (2018-05-23)

### Fixed (4 changes)

- Geo: Fix repo, wiki, and upload replication when renaming a namespace that has subgroups. !5704
- Shows the correct data in the verification information section for the primary node in Geo admin screen. !5722
- [Geo] Don't remove project registry records.
- Geo: Exclude tables that start with pg_ from FDW check.


## 10.8.0 (2018-05-22)

### Removed (1 change)

- Use of ENV['USE_SYSTEM_GIT_FOR_FETCH'] is no longer supported.

### Fixed (22 changes)

- Add missing fields to the API documentation for the status of Geo Nodes. !3865
- Large pushes were failing when max file size push rule was active. !4989
- Fix GITLAB_FEATURES CI/CD env var for public projects. !5242
- Reveal labels dropdown when labels icon is clicked on collapsed Epic sidebar. !5298
- Geo: Propagate broadcast messages to secondaries. !5303
- Geo: Exclude expired job artifacts from syncing and counts. !5380
- Exclude GroupSAML from sign in buttons. !5449
- Per-Group SAML (for GitLab.com) strips LRM chars from ADFS certificate fingerprints. !5466
- Refactor the Geo LogCursor Logger to make class more descriptive. !5483
- Geo - Returns a dummy checksum when there is no valid repository on disk. !5486
- ShaAttribute no longer stops startup if database is missing. !5502
- Fix network error message styling on Geo admin dashboard. !5530
- Fixes invalid link in html version of mirror was hard failed email. !5546
- During repository verification, ignore repositories/wikis that need to be resynced. !5568
- Group SAML skips forgery protection in production. !5621
- Does not log failed sign-in attempts when in a GitLab read-only instance. !5643
- [Geo] Fix rake geo:status when event_log is not found.
- Geo: Use a pre-built node status in admin area.
- [Geo] Mentioned in custom hooks doc that they won't be replicated to secondary.
- Fix: Geo: BaseSyncService should prune the @geo-temporary directory before fetching.
- Stop presenting burndown charts promotion for grouped by title milestones.
- Geo: When a repository or Wiki sync has failed, mark resync flag as true.

### Changed (13 changes, 1 of them is from the community)

- Shorten protected branch / tag access level dropdown text. !5091
- Improve tooltips on collapsible right sidebars. !5212
- Allow easier customization of included CI configurations. !5288 (King Chung Huang)
- Unprotect and update disabled in UI when prevented by branch unprotect rules. !5296
- Issues export CSV includes 'Weight' and 'Locked'. !5300
- Update item titles and add help text in Geo nodes admin dashboard. !5306
- Geo - Improve metrics for the checksum/verification feature. !5367
- Adds push mirrors to GitLab Community Edition. !5484
- Adds SSO page for GitLab.com per group SAML beta. !5508
- Adds authentication flow for GitLab.com per group SAML beta. !5575
- Add Geo information to console message. !5588
- Ability to edit, disable or remove Geo Nodes is now always available.
- Show pod name for each instance on deploy boards.

### Performance (4 changes)

- Port Group member contribution analytics table to Vue. !5269
- Improve performance of repository size limit check. !5476
- Improves database performance of mirrors, forks and imports. !5522
- Prevent Geo from unnecessarily syncing expired CI job artifacts.

### Added (11 changes)

- Geo: schedule a git repack after initial clone. !4266
- Present Burndown charts for group milestones. !5354
- Filtered search bar support for Roadmap view. !5417
- Allow user to dismiss a vulnerability or create an issue out of it. !5452
- Geo: enable housekeeping functionality when syncing repositories. !5461
- Enable username autocomplete inside Epics. !5475
- Present MRs on Jira development panel integration. !5534
- Run repository verification on Geo secondary. !5550
- Email notifications for epics.
- Add Epic count to usage pings.
- Add system note for weight change.

### Other (6 changes, 6 of them are from the community)

- Replace the `admin/license.feature` spinach test with an rspec analog. !5477 (@blackst0ne)
- Replace the `admin/push_rules.feature` spinach test with an rspec analog. !5512 (@blackst0ne)
- Replace the `admin/emails.feature` spinach test with an rspec analog. !5513 (@blackst0ne)
- Replace the `group_hooks.feature` spinach test with an rspec analog. !5515 (@blackst0ne)
- Replace the `groups_management.feature` spinach test with an rspec analog. !5516 (@blackst0ne)
- Remove `features/group_active_tab.feature`. !5554 (@blackst0ne)


## 10.7.7 (2018-07-17)

- No changes.

## 10.7.6 (2018-06-21)

- No changes.

## 10.7.5 (2018-05-28)

### Security (3 changes)

- Fixed XSS in protected branches & tags access dropdown.
- Escape name in merge request approvers dropdown.
- Fixes include directive to not allow SSRF requests.


## 10.7.4 (2018-05-21)

### Fixed (2 changes)

- Does not log failed sign-in attempts when in a GitLab read-only instance. !5643
- Fix: Geo: BaseSyncService should prune the @geo-temporary directory before fetching.


## 10.7.3 (2018-05-02)

### Fixed (3 changes)

- Geo - Fix undefined method pending_delete for nil class. !5470
- Geo: Admin page will not crash with 500 because of InvalidSignatureTimeError. !5495
- Fix DB LB errors when escaping input.


## 10.7.2 (2018-04-25)

- No changes.

## 10.7.1 (2018-04-23)

### Fixed (4 changes)

- Geo: Fix enabled wiki counts with FDW (impacts synced and verified counts). !5352
- Fix Epic timeline bar misalignment when start date is in last timeframe month and end date is out of range. !5360
- Adds border top to codeclimate report in MR widget.
- Avoid wrong closing dates being caught by the query on Burndown charts.

### Performance (1 change)

- Geo - Improve the query performance to find unverified projects on primary node. !5348


## 10.7.0 (2018-04-22)

### Fixed (25 changes)

- Issue Boards: Ensure that horizontal scroll bars are shown on overflow. !4944
- Fix validation error message when historical data is empty. !4961
- Fixes incorrect assignation of cluster details. !5047
- Fixed personal snippets uploads when background upload is enabled. !5049
- Fixed incorrect count of verified wikis on a Geo secondary node. !5084
- Fix unapproved unassigned merge request emails failing to send. !5092
- Geo secondary repository verification messages now appear in geo.log. !5095
- Geo: Sync wiki when it is enabled. !5139
- Geo: Make synced/failed scopes more consistent. !5171
- Updates style of arrown in downstream pipeline. !5172
- Add better LDAP connection handling in EE and fixing some LDAP group syncing problems. !5173
- Fix an exception in the Geo repository sync worker. !5223
- Geo - Fix wiki repository verification on a secondary node. !5315
- Show repository checksum UI elements only when feature is enabled. !5341
- Fix a bug migrating CI job artifact registry entries to a separate table. !5345
- Render show all report for sast and dependency scanning. !5363
- Fix label and issuable referencing in epics and epic notes.
- Add icons to epic system notes issue actions.
- [Geo] Fix project rename when wiki does not exist.
- Catch errors in LoadBalancing::Host#online?.
- Fix Scoped Boards bug filtering by No Milestone.
- Skip repository-changing events on Geo secondaries if the repository hasn't been backfilled yet.
- Ensure Geo secondary nodes only run cron jobs appropriate for secondaries.
- Geo - Returns a dummy checksum when there is no repository on disk.
- Fix Elasticsearch missing terms with special characters.

### Deprecated (1 change)

- Rename SAST:container to Container Scannning.

### Changed (9 changes)

- Geo - Perform the repository verification per shard on a secondary node. !5068
- Allow enabling classification policy control without external authorization service. !5083
- Update Geo nodes layout for better usability. !5199
- Document manual disaster recovery process for systems with multiple secondaries.
- Don't send schedule confirmations for chat jobs.
- Geo - Switch from time-based checking of outdated checksums to the nil-checksum-based approach.
- Make /-/ delimiter optional for epics and search endpoints.
- Order boards dropdown alphabetically.
- Renders grouped security reports in MR widget & split security reports in CI view.

### Performance (3 changes)

- Geo - Improve the query performance to find unsynced job artifacts. !5350
- Reimplement Roadmap timeline rendering for better performance.
- Geo: Migrate CI job artifacts into their own registry table.

### Added (11 changes)

- Geo ensure files moved to object storage are cleaned up. !4689
- Timeout for external authorization is now configurable. !4971
- Add system header and footer as new appearance options. !4972
- Authenticate using TLS certificate for requests to external authorization service. !5028
- Add admin setting for custom additional text in emails. !5031
- Mark files missing on primary as synced, but retry them. !5050
- Log every access when external authorization is enabled. !5117
- Add total CPU/Memory metrics, adds weighting for proper sorting. !5260
- Add comment thread to Epics.
- Render dependency scanning in MR widget and CI view.
- Add a Go back button to WebIDE to allow returning to where it was launched from.

### Other (4 changes, 1 of them is from the community)

- Move default group project creation level to Starter. !5148
- Replace the `project/issues/weight.feature` spinach test with an rspec analog. !5194 (blackst0ne)
- [Geo] Log JID for sync related jobs.
- Breaks utils function to parse codeclimate and sast into separate functions.


## 10.6.6 (2018-05-28)

### Security (3 changes)

- Fixed XSS in protected branches & tags access dropdown.
- Escape name in merge request approvers dropdown.
- Fixes include directive to not allow SSRF requests.


## 10.6.5 (2018-04-24)

- No changes.

## 10.6.4 (2018-04-09)

### Fixed (4 changes)

- Fixes incorrect assignation of cluster details. !5047
- Geo: Make synced/failed scopes more consistent. !5171
- [Geo] Fix project rename when wiki does not exist.
- Fix Scoped Boards bug filtering by No Milestone.

### Other (1 change)

- [Geo] Log JID for sync related jobs.


## 10.6.3 (2018-04-03)

- No changes.

## 10.6.2 (2018-03-29)

- No changes.

## 10.6.1 (2018-03-27)

### Fixed (8 changes)

- Fix LDAP group sync permission override UI. !5003
- Hard failing a mirror no longer fails for a blocked user's personal project. !5063
- Geo - Avoid rescheduling the same project again in a backfill condition. !5069
- Mark disabled wikis as fully synced. !5104
- Fix excessive updates to file_registry when wiki is disabled. !5119
- Geo: Recovery from temporary directory doesn't work if the namespace directory doesn't exist.
- Define a chat responder for the Slack app.
- Resolve "undefined method 'log_transfer_error'".

### Added (1 change)

- Also log Geo Prometheus metrics from primary. !5058

### Other (1 change)

- Update Epic documentation to include labels.


## 10.6.0 (2018-03-22)

### Security (2 changes)

- Prevent new push rules from using non-RE2 regexes.
- Project can no longer be shared between groups when both member and group locks are active.

### Fixed (47 changes)

- Geo - Add a rake task to update Geo primary node URL. !4097
- Capture push rule regex errors and present them to user. !4102
- Fixed membership Lock should propagate from parent group to sub-groups. !4111
- Fix Epic sidebar toggle button icon positioning. !4138
- Update the Geo documentation to replicate all secrets to the secondary. !4188
- Update Geo documentation to reuse the primary node SSH host key on secondary node. !4198
- Improve Geo Disaster Recovery docs for systems in multi-secondary configurations. !4285
- Fix 500 errors caused by large replication slot wal retention. !4347
- Report the correct version and revision for Geo node status requests. !4353
- Don't show Member Lock setting for unlicensed system. !4355
- Fix the background_upload configuration being ignored. !4507
- Fix canary legends for single series charts. !4522
- Fixes and enhancements for Geo admin dashboard. !4536
- Fix license expiration duration to show trial info only for trial license. !4573
- File uploads in remote storage now support project renaming. !4597
- Use unique keys for token inputs while add same value twice to an epic. !4618
- Fix multiple assignees avatar alignment in issues list. !4664
- Improve security reports to handle big links and to work on mobile devices. !4671
- Supresses error being raised due to async remote removal being run outside a transaction. !4747
- Mark empty repos as synced in Geo. !4757
- Mirror owners now get assigned as mirror users when the assigned mirror users disable their accounts. !4827
- Geo: Ignore remote stored objects when calculating counts. !4864
- Fix Epics not getting created in a Group with existing Epics. !4865
- Generate ObjectStorage URL based on user provided schema. !4932
- Make Epic start and finish dates on Roadmap to be timezone neutral. !4964
- Support SendURL for performing indirect download of artifacts if clients does not specify that it supports that.
- Fix LDAP group sync no longer configurable for regular users.
- [Geo] Skip attachments that is stored in the object storage.
- Fix: Geo WikiSyncService attempts to sync projects that have no Wiki.
- Fix broken CSS in modal for DAST report.
- Improve SAST description for no new vulnerabilities.
- Fix 'Geo: Don't attempt to expire the cache after a failed clone'.
- Geo - Remove duplicated message on on geo:update_primary_node_url rake task.
- Fix the geo::db:seeds rake task.
- Geo - Fix repository synchronization order for projects updated recently.
- Geo - Respect backoff time when repository have never been synced successfully.
- Ensure mirror can transition out of the started state when last_update_started_at is nil.
- Fix bug causing 'Import in progress' to be shown while a mirror is updating.
- Include epics from subgroups on Epic index page.
- Fix proxy_download support for lfs controller.
- Fixed IDE command palette options being hidden.
- Fixed IDE file list when multiple files have same name but different paths.
- Fixed IDE not showing the correct changes and diff markers.
- Update epic issue reference when moving an issue.
- Fix Geo Log Cursor not reconnecting after pgbouncer dies.
- Fix audit and Geo project deletion events not being logged under certain conditions.
- Geo: Fix Wiki resync when Wiki repository does not exist.

### Changed (15 changes)

- Geo Logger will use the same log level defined in Rails. !4066
- Approve merge requests additionally. !4134
- Geo: sync .gitattributes to info/attributes in secondary nodes. !4159
- Update behavior of MR widgets that require pipeline artifacts to allow jobs with multiple artifacts. !4203
- Add details on how to disable GitLab to the DR documentation. !4239
- Add users stats page for admin area with per role amount. !4539
- Group Roadmap enhancements. !4651
- Adds support to show added, fixed and all vulnerabilties for SAST in merge request widget.
- Ports remote removal to a background job.
- Update UI for merge widget reports.
- Geo: Improve formatting of can't push to secondary warning message.
- Replace check_name key with description in codeclimate results for a more human readable description.
- Add license ID number to usage ping.
- Schedule mirror updates in parallel.
- Geo: Don't attempt to schedule a repository sync for downed Gitaly shards.

### Performance (8 changes, 3 of them are from the community)

- Move Assignees vue component. !4467 (George Tsiolis)
- Speed up approvals calculations. !4492
- Move BoardNewIssue vue component. !16947 (George Tsiolis)
- Move RecentSearchesDropdownContent vue component. !16951 (George Tsiolis)
- Bump Geo JWT timeout from 1 minute to 10 minutes.
- Cache column_exists? for Elasticsearch columns.
- FIx N+1 queries with /api/v4/groups endpoint.
- Properly memoize ChangeAccess#validate_path_locks? to avoid excessive queries.

### Added (39 changes, 1 of them is from the community)

- Add ability to add Custom Metrics to environment and deployment metrics dashboards. !3799
- Add object storage support for uploads. !3867
- Add support within Browser Performance Testing for metrics where smaller is better. !3891 (joshlambert)
- Add more endpoints for Geo Nodes API. !3923
- (EEP) Allow developers to create projects in group. !4046
- Integrate current File Locking feature with LFS File Locking. !4091
- Add Epic information for selected issue in Issue boards sidebar. !4104
- Update CI/CD secret variables list to be dynamic and save without reloading the page. !4110
- Add object storage migration task for uploads. !4215
- Filtered search support for Epics list page. !4223
- Add multi-file editor usage metrics. !4226
- Dry up CI/CD gitlab-ci.yml configuration by allowing inclusion of external files. !4262
- Geo: FDW issues are displayed in the Geo Node Admin UI. !4266
- Implement selective synchronization by repository shard for Geo. !4286
- Show Group level Roadmap. !4361
- Add Geo Prometheus metrics about the various number of events. !4413
- Geo - Calculate repositories checksum on primary node. !4428
- If admin note exists, display it in admin user view. !4546
- Add option to overwrite diverged branches for pull mirrors. !4559
- Adds GitHub Service to send status updates for pipelines. !4591
- Projects and MRs Approvers API. !4636
- Add CI/CD for external repositories. !4642
- Authorize project access with an external service. !4675
- GitHub CI/CD import sets up pipeline notification integration. !4687
- Add GitHub support to CI/CD for external repositories. !4688
- Repository mirroring notifies when hard failed. !4699
- Query cluster status. !4701
- Geo - Verify repository checksums on the secondary node. !4749
- Move support of external gitlab-ci files from Premium to Starter. !4841
- Geo - Improve node status report by adding one more indicator of health: last time when primary pulled the status of the secondary.
- Render SAST report in Pipeline page.
- Add system notes when moving issues between epics.
- Add rake task to print Geo node status.
- Add basic searching and sorting to Epics API.
- gitlab:geo:check checks connection to the Geo tracking DB.
- Added basic implementation of GitLab Chatops.
- Add discussions API for Epics.
- Add proxy_download to enable passing all data through Workhorse.
- Add support for direct uploading of LFS artifacts.

### Other (8 changes)

- Geo: Improve replication status. Using pg_stat_wal_receiver.
- Remove unaproved typo check in sast:container report.
- Allow clicking on Staged Files in WebIDE to open them in the Editor.
- Translate Locked files page.
- Increase minimum mirror update interval from 15 to 30 minutes.
- Geo - add documentation about using shared a S3 bucket with GitLab Container Registry.
- Allow use of system git for git fetch if USE_SYSTEM_GIT_FOR_FETCH is defined.
- Rename "Approve Additionally" to "Add approval".


## 10.5.8 (2018-04-24)

- No changes.

## 10.5.7 (2018-04-03)

- No changes.

## 10.5.6 (2018-03-16)

- No changes.

## 10.5.5 (2018-03-15)

### Fixed (1 change)

- Geo: Fix Wiki resync when Wiki repository does not exist.


## 10.5.4 (2018-03-08)

### Fixed (4 changes)

- Supresses error being raised due to async remote removal being run outside a transaction. !4747
- Mark empty repos as synced in Geo. !4757
- Fix: Geo WikiSyncService attempts to sync projects that have no Wiki.
- Geo - Fix repository synchronization order for projects updated recently.

### Other (1 change)

- Rename "Approve Additionally" to "Add approval".


## 10.5.3 (2018-03-01)

### Security (2 changes)

- Project can no longer be shared between groups when both member and group locks are active.
- Prevent new push rules from using non-RE2 regexes.

### Fixed (1 change)

- Fix LDAP group sync no longer configurable for regular users.


## 10.5.2 (2018-02-25)

- No changes.

## 10.5.1 (2018-02-22)

- No changes.

## 10.5.0 (2018-02-22)

### Fixed (23 changes, 1 of them is from the community)

- Geo - Add a rake task to update Geo primary node URL. !4097
- Capture push rule regex errors and present them to user. !4102
- Fixed membership Lock should propagate from parent group to sub-groups. !4111
- Fix Epic sidebar toggle button icon positioning. !4138
- Update the Geo documentation to replicate all secrets to the secondary. !4188
- Update Geo documentation to reuse the primary node SSH host key on secondary node. !4198
- Override group sidebar links. !4234 (George Tsiolis)
- Improve Geo Disaster Recovery docs for systems in multi-secondary configurations. !4285
- Fix 500 errors caused by large replication slot wal retention. !4347
- Report the correct version and revision for Geo node status requests. !4353
- Don't show Member Lock setting for unlicensed system. !4355
- Fix the background_upload configuration being ignored. !4507
- Geo: Reset force_redownload flag after successful sync.
- [Geo] Skip attachments that is stored in the object storage.
- [Geo] Fix redownload repository recovery when there is not local repo at all.
- Fix broken CSS in modal for DAST report.
- Improve SAST description for no new vulnerabilities.
- Geo - Remove duplicated message on on geo:update_primary_node_url rake task.
- Fix the geo::db:seeds rake task.
- Allow project to be set up to push to and pull from same mirror.
- Include epics from subgroups on Epic index page.
- Fix validation of environment scope of variables.
- Support SendURL for performing indirect download of artifacts if clients does not specify that it supports that.

### Changed (9 changes)

- Geo Logger will use the same log level defined in Rails. !4066
- Approve merge requests additionally. !4134
- Geo: sync .gitattributes to info/attributes in secondary nodes. !4159
- Update behavior of MR widgets that require pipeline artifacts to allow jobs with multiple artifacts. !4203
- Add details on how to disable GitLab to the DR documentation. !4239
- Ports remote removal to a background job.
- Adds support to show added, fixed and all vulnerabilties for SAST in merge request widget.
- Geo: Don't attempt to schedule a repository sync for downed Gitaly shards.
- Update UI for merge widget reports.

### Performance (3 changes)

- Bump Geo JWT timeout from 1 minute to 10 minutes.
- FIx N+1 queries with /api/v4/groups endpoint.
- Properly memoize ChangeAccess#validate_path_locks? to avoid excessive queries.

### Added (17 changes, 1 of them is from the community)

- Add object storage support for uploads. !3867
- Add support within Browser Performance Testing for metrics where smaller is better. !3891 (joshlambert)
- Add more endpoints for Geo Nodes API. !3923
- (EEP) Allow developers to create projects in group. !4046
- Integrate current File Locking feature with LFS File Locking. !4091
- Add Epic information for selected issue in Issue boards sidebar. !4104
- Update CI/CD secret variables list to be dynamic and save without reloading the page. !4110
- Add object storage migration task for uploads. !4215
- Filtered search support for Epics list page. !4223
- Add multi-file editor usage metrics. !4226
- Dry up CI/CD gitlab-ci.yml configuration by allowing inclusion of external files. !4262
- Implement selective synchronization by repository shard for Geo. !4286
- Show Group level Roadmap. !4361
- Add Geo Prometheus metrics about the various number of events. !4413
- Geo - Improve node status report by adding one more indicator of health: last time when primary pulled the status of the secondary.
- Add rake task to print Geo node status.
- Add system notes when moving issues between epics.

### Other (3 changes)

- Activated the Web IDE Button also on the main project page. !4250
- Geo - add documentation about using shared a S3 bucket with GitLab Container Registry.
- Geo: Improve replication status. Using pg_stat_wal_receiver.
- Remove unaproved typo check in sast:container report.


## 10.4.7 (2018-04-03)

- No changes.

## 10.4.6 (2018-03-16)

- No changes.

## 10.4.5 (2018-03-01)

### Security (2 changes)

- Project can no longer be shared between groups when both member and group locks are active.
- Prevent new push rules from using non-RE2 regexes.

### Fixed (1 change)

- Fix LDAP group sync no longer configurable for regular users.


## 10.4.4 (2018-02-16)

### Fixed (4 changes)

- Handle empty event timestamp and larger memory units. !4206
- Geo: Reset force_redownload flag after successful sync.
- [Geo] Fix redownload repository recovery when there is not local repo at all.
- Allow project to be set up to push to and pull from same mirror.


## 10.4.3 (2018-02-05)

### Security (1 change)

- Restrict LDAP API to admins only.


## 10.4.2 (2018-01-30)

### Fixed (7 changes)

- Fix Epic issue item reordering to handle different scenarios. !4142
- Fix visually broken admin dashboard until license is added. !4196
- Handle empty event timestamp and larger memory units. !4206
- Use a fixed remote name for Geo mirrors. !4249
- Preserve updated issue order to store when reorder is completed. !4278
- Geo - Fix OPENSSH_EXPECTED_COMMAND in the geo:check rake task.
- Execute group hooks after-commit when moving an issue.


## 10.4.1 (2018-01-24)

### Fixed (1 change)

- Fix failed LDAP logins when sync_ssh_keys is included in config.


## 10.4.0 (2018-01-22)

### Security (2 changes)

- Fix LDAP external user/group bug on first sign in.
- Deny persisting milestones from outside project/group scope on boards.

### Fixed (19 changes, 1 of them is from the community)

- Issue count now refreshes quicker on geo secondary. !3639
- Prevent adding same role multiple times on repeated clicks. !3700
- Geo - Fix difference in FDW / non-FDW queries for Geo::FileRegistry queries. !3714
- Fix successful rebase throwing flash error message. !3727
- Fix Merge Rquest widget rebase action in Internet Explorer. !3732
- Geo - Use relative path for avatar images on a secondary node. !3857
- Add missing wiki counts to prometheus metrics. !3875
- Adjust content width for User Settings, Pipeline quota. !3895 (George Tsiolis)
- Fix a bug where branch could not be delete due to a push rule config. !3900
- Fix a few doc links to fast ssh key lookup. !3937
- Handle node details load failure gracefully on UI. !3992
- Use the fastest available method for various Geo status counts. !4024
- Fix neutralCount computation to prevent negative values. !4044
- Fix reordering of items when moved to top or bottom. !4050
- Geo - Fix repository clean up when selective replication changes with hashed storage enabled. !4059
- Fix JavaScript bundle running on Cluster update/destroy pages. !4112
- Record EE instances without a license correctly in usage ping.
- Fix export to CSV if a filter with multiple labels is used.
- Stop authorization attempts with instance profile when static credentials are provided for AWS Elasticsearch.

### Changed (6 changes)

- Change MR widget failed icons to warning icons. !3669
- Show clear message when set-geo-primary-node was successful. !3768
- More descriptive error when clocks between Geo nodes are out of sync. !3860
- Allow sidekiq to react to becoming a Geo primary or secondary without a restart. !3878
- Geo admin screen enhancements. !3902
- Geo UI polish.

### Added (13 changes)

- Split project repository and wiki repository status in Geo node status. !3560
- Add reset pipeline minutes button to admin overview of groups and users. !3656
- Show results from docker image scan in the merge request widget. !3672
- Geo: Added Authorized Keys specific checks. !3728
- Add some extra fields to Geo API node and status. !3858
- Show results from DAST scan in the merge request widget. !3885
- Add Geo support for CI job artifacts. !3935
- Make it possible to enable/disable PostgreSQL FDW for Geo. !4020
- Add support for reordering issues in epics.
- Check if shard configuration is same across Geo nodes.
- Add API for epics.
- Add group boards API endpoint.
- Add api for epic_issue associations.

### Other (6 changes)

- Document GitLab Geo with Object Storage. !3760
- Update disaster recovery documentation with detailed steps. !3845
- Fix broken alignment of database password in geo docs. !3939
- Remove unnecessary NTP checks now included in gitlab:geo:check. !3940
- Move geo status check after db replication to avoid anticipated failures. !3941
- Make scoped issue board specs more reliable.


## 10.3.9 (2018-03-16)

- No changes.

## 10.3.8 (2018-03-01)

### Security (2 changes)

- Project can no longer be shared between groups when both member and group locks are active.
- Prevent new push rules from using non-RE2 regexes.

### Fixed (1 change)

- Fix LDAP group sync no longer configurable for regular users.


## 10.3.7 (2018-02-05)

### Security (1 change)

- Restrict LDAP API to admins only.

### Fixed (1 change)

- Fix JavaScript bundle running on Cluster update/destroy pages.


## 10.3.6 (2018-01-22)

### Fixed (3 changes)

- Geo - Fix repository clean up when selective replication changes with hashed storage enabled. !4059
- Fix JavaScript bundle running on Cluster update/destroy pages. !4112
- Fix export to CSV if a filter with multiple labels is used.


## 10.3.5 (2018-01-18)

- No changes.

## 10.3.4 (2018-01-10)

### Security (2 changes)

- Fix LDAP external user/group bug on first sign in.
- Deny persisting milestones from outside project/group scope on boards.


## 10.3.3 (2018-01-02)

- No changes.

## 10.3.2 (2017-12-28)

- No changes.

## 10.3.1 (2017-12-27)

### Changed (1 change)

- Geo: Show sync percent on bar graph and count within tooltips. !3794


## 10.3.0 (2017-12-22)

### Removed (2 changes)

- Remove the full-scan option from the Geo log cursor. !3412
- Remove Geo SSH repo sync support. !3553

### Fixed (14 changes)

- Hide Approvals section when Merge Request Widget is showing the empty state. !3376
- Fix error when entering an invalid url to push to or pull from a remote repository. !3389
- Update gitlab.yml.example to match the default settings for Geo sync workers. !3488
- Remove duplicate read-only flash message on admin pages. !3495
- Strip leading & trailing whitespaces in CI/CD secret variable's environment scope. !3563
- Fix Advanced Search Syntax documentation. !3571
- Fix Git message when pushing to Geo secondary. !3616
- Fix a bug in the Geo metrics update service. !3623
- Fix validation of environment scope for Ci::Variable. !3641
- Fix an exception in Geo scheduler workers. !3740
- Fix Merge Request Widget Approvals responsiveness on mobile.
- Geo - Does not sync repositories on unhealthy shards in non-backfill conditions.
- Record EE Ultimate usage pings correctly.
- Fix board filter for predefined milestones.

### Changed (4 changes)

- Improve Geo logging of repository errors. !3402
- ProtectedBranches API allows individual users and group to be specified. !3516
- EE Protected Branches API access levels include user_id/group_id where relevant. !3535
- Enhancements for Geo admin screen. !3545

### Performance (1 change)

- Geo - Improve performance when calculating the node status. !3595

### Added (20 changes)

- Show SAST results in MR widget. !3207
- Add option for projects to only mirror protected branches. !3326
- Add option to remote mirrors to only push protected branches. !3350
- Add warning when Geo is configured insecurely. !3368
- Added enpoint that triggers the pull mirroring process. !3453
- Add performance metrics to the merge request widget. !3507
- Geo: replicate Attachments migration to Hashed Storage in secondary node. !3544
- View, add, and edit weight on Issue from the Issue Board contextual sidebar. !3566
- Decrease scheduling delay and add rate limiting to push mirror. !3575
- Allow admins to disable mirroring. !3586
- Support multiple Kubernetes cluster per project. !3603
- Geo: Increase parallelism by scheduling project repositories by shard. !3606
- Geo: rake task to refresh foreign table schema (FDW support). !3626
- Support mentioning epics.
- Handle outdated replicas in the DB load balancer.
- Add geo:set_secondary_as_primary rake task.
- Transfer job archives to object storage after creation.
- Geo - Show GitLab version for each node in the Geo status page.
- Add epic information to issue sidebar.
- Add system notes for issue - epic association.

### Other (3 changes)

- Add fade mask to the bottom of the boards selector dropdown list if it can be scrolled down. !3384
- Document how to set up GitLab Geo for HA. !3468
- Add border for epic edit button.


## 10.2.8 (2018-02-07)

### Security (1 change)

- Restrict LDAP API to admins only.


## 10.2.7 (2018-01-18)

- No changes.

## 10.2.6 (2018-01-11)

### Security (2 changes)

- Fix LDAP external user/group bug on first sign in.
- Deny persisting milestones from outside project/group scope on boards.


## 10.2.5 (2017-12-15)

### Fixed (1 change)

- Fix board filter for predefined milestones.


## 10.2.4 (2017-12-07)

- No changes.

## 10.2.3 (2017-11-30)

### Fixed (5 changes)

- Fix viewing default push rules on a Geo secondary. !3559
- Disable autocomplete for epics.
- Fix epic fullscreen editing.
- Fix tasklist for epics.
- Fix Geo wiki sync error not increasing retry count.


## 10.2.2 (2017-11-23)

### Fixed (6 changes)

- Fix in-progress repository syncs counting as failed. !3424
- Don't user issuable_sort cookie for epics collection.
- Enable scoped boards for Early Adopters.
- Account shared runner minutes to top-level namespace.
- Geo - Ensure that LFS object deletions are communicated to the secondary.
- Disable file attachments for epics.

### Other (1 change)

- Document a failure mode for large repositories in Geo. !3500


## 10.2.1 (2017-11-22)

- No changes.

## 10.2.0 (2017-11-22)

### Fixed (17 changes)

- Geo - Does not move projects backed by hashed storage when handling renamed events. !3066
- Geo: Don't sync disabled project wikis. !3109
- Reconfigure the Geo tracking database pool size when running as Sidekiq. !3181
- Geo - Ensures that leases were returned. !3241
- Fix (un)approver names not being shown in plaintext emails. !3266
- Add post-migration to drain all Geo related redis queues. !3289
- Prevent the Geo log cursor from running on primary nodes. !3411
- Reduce the number of Elasticsearch client instances that are created. !3432
- Fix generated clone URLs for wikis on Geo secondaries. !3448
- Remove duplicate delete button in epic.
- Fix: Failed to rebase MR from forked repo.
- Fix: Geo API bug. Statistic is not collected when prometheus is disabled.
- Geo - Ensure that repository deletions in a primary node are correctly deleted in a secondary node.
- Geo: Fix handling of nil values on advanced section in admin screen.
- Redirect to existing group boards using old URL if there is no subgroup called 'boards'.
- Geo - Allow Sidekiq to retry failed jobs to rename project repositories.
- Geo: Ensure database is connected before attempting to check for secondary status.

### Changed (4 changes)

- Add project actions in Audit events. !3160
- Add group actions in Audit events. !3176
- Geo: Don't retry repositories or files until everything has been backfilled. !3182
- Improve Codeclimate UI.

### Performance (1 change)

- Reduce the quiet times between scheduler runs on Geo secondaries. !3185

### Added (20 changes, 1 of them is from the community)

- Add new push rule to enforce that only the author of a commit can push to the repository. !3086
- Make the maximum capacity of Geo backfill operations configurable. !3107
- Mirrors can now hard fail, keeping them from being retried until a project admin takes action. !3117
- View/edit epic at group level. !3126
- Add worker to prune the Geo Event Log. !3172
- julian7 Add required_groups option to SAML config, to restrict access to GitLab to specific SAML groups. !3223 (Balazs Nagy)
- Geo: Expire and resync attachments from renamed projects in secondary nodes when using legacy storage. !3259
- On Secondary read-only Geo Nodes now a flash banner is shown on all pages. !3260
- Make GeoLogCursor Highly Available. !3305
- Allow Geo repository sync over HTTPS. !3341
- Allow persisting board configuration in order to automatically filter issues.
- Improve error handling.
- Add epics list and add epics to nav sidebar.
- Introduce EEU lincese with epics as the first feature.
- Add ability to create new epics.
- Add sidebar for epic.
- Add delete epic button.
- Allow admins to globally disable all remote mirrors from application settings page.
- Add support for logging Prometheus metrics for Geo.
- Use PostgreSQL FDW for Geo downloads.

### Other (2 changes, 1 of them is from the community)

- Suppress MergeableSelector warning candidates in EE-only files. !3225 (Takuya Noguchi)
- Enhance the documentation for gitlab-ctl replicate-geo-database. !3268


## 10.1.7 (2018-01-18)

- No changes.

## 10.1.6 (2018-01-11)

### Security (2 changes)

- Fix LDAP external user/group bug on first sign in.
- Deny persisting milestones from outside project/group scope on boards.


## 10.1.5 (2017-12-07)

- No changes.

## 10.1.4 (2017-11-14)

- No changes.

## 10.1.3 (2017-11-10)

- [FIXED] Fix: Failed to rebase MR from forked repo.

## 10.1.2 (2017-11-08)

- [SECURITY] Fix vulnerability that could allow any user of a Geo instance to clone any repository on the secondary instance.
- [SECURITY] Geo JSON web tokens now expire after two minutes to reduce risk of compromise.

## 10.1.1 (2017-10-31)

- [FIXED] Fix LDAP group sync for nested groups e.g. when base has uppercase or extraneous spaces. !3217
- [FIXED] Geo: read-only safeguards was not working on Secondary node. !3227
- [FIXED] fix height of rebase and approve buttons.
- [FIXED] Move group boards routes under - and remove "boards" from reserved paths.

## 10.1.0 (2017-10-22)

- [SECURITY] Prevent Related Issues from leaking confidential issues. !541
- [FIXED] Geo - Selective replication allows admins to select any groups. !2779
- [FIXED] Fix CSV export when filtering issues by multiple labels. !2852
- [FIXED] Impersonation no longer gets stuck on password change. !2904
- [FIXED] Mirroring to remote repository no longer fails after a force push. !2919
- [FIXED] Fix a merge request validation error on forked projects. !2932
- [FIXED] Fix an error reporting some failures in the elasticsearch indexer. !2998
- [FIXED] Fix a Geo node validation, preventing admins from locking themselves out. !3040
- [FIXED] Find stuck scheduled import jobs and also mark them as failed. !3055
- [FIXED] Fix removing the username from the git repository URL for pull mirroring. !3060
- [FIXED] Prevent failed file syncs from stalling Geo backfill. !3101
- [FIXED] Fix reading the status of a secondary Geo node from the primary. !3140
- [FIXED] Always allow the default branch as a branch name. !3154
- [FIXED] Show errors when rebase onto target branch fails in the UI.
- [FIXED] Fix base link for issues on group boards.
- [FIXED] Don't create todos for old issue assignees.
- [FIXED] Geo: Fix attachments/avatars saving to the wrong directory.
- [FIXED] Save Geo files to a temporary file and rename after success.
- [FIXED] Fix personal snippets not downloading in Geo secondaries.
- [FIXED] Geo: Limit the huge cross-database pluck for LFS objects and attachments.
- [CHANGED] Schedule repository synchronization when processing events on a Geo secondary node. !2838
- [CHANGED] Create idea of read-only database and add method to check for it. !2954
- [CHANGED] Remove the backoff delay from Geo repository sync. !3009
- [CHANGED] Improves visibility of deploy boards.
- [CHANGED] Improve performance of rebasing by using worktree.
- [ADDED] Add suport for CI/CD pipeline policy management. !2986
- [ADDED] Add LDAP synchronization based on filter for GitLab groups.
- [OTHER] Add Geo rake task descriptions. !2925
- [OTHER] Improve logging output for several Geo background workers. !2961
- [OTHER] Add partial index on push_rules.is_sample.
- Add new push rule to reject unsigned commits. !2913

## 10.0.7 (2017-12-07)

- No changes.

## 10.0.5 (2017-11-03)

- [FIXED] Find stuck scheduled import jobs and also mark them as failed. !3055
- [FIXED] Fix removing the username from the git repository URL for pull mirroring. !3060
- [FIXED] Fix base link for issues on group boards.
- [FIXED] Move group boards routes under - and remove "boards" from reserved paths.
- [FIXED] Geo: Fix attachments/avatars saving to the wrong directory.

## 10.0.4 (2017-10-16)

- [SECURITY] Prevent Related Issues from leaking confidential issues. !541
- [SECURITY] Escape user name in filtered search bar.

## 10.0.3 (2017-10-05)

- [FIXED] Rewrite Geo database rake tasks so they operate on the correct database. !3052
- [FIXED] Show group tab if member lock is enabled.
- [FIXED] File uploaders do not perform hard check, only soft check.
- [FIXED] Only show Turn on Service Desk button when user has permissions.
- [FIXED] Fix EE delta size check handling with annotated tags.

## 10.0.2 (2017-09-27)

- [FIXED] Send valid project path as name for Jira dev panel.
- [FIXED] Fix delta size check to handle commit or nil objects.

## 10.0.1 (2017-09-23)

- No changes.

## 10.0.0 (2017-09-22)

- [SECURITY] Check if LDAP users are in external groups on login. !2720
- [FIXED] Fix typo for `required` attribute. !2659
- [FIXED] Fix global code search when using negation queries. !2709
- [FIXED] Fixes activation of project mirror when new project is created. !2756
- [FIXED] Geo - Whitelist LFS requests to download objects on a secondary node. !2758
- [FIXED] Fix Geo::RepositorySyncWorker so attempts to sync all projects if some are failing. !2796
- [FIXED] Fix unsetting credentials data for pull mirrors. !2810
- [FIXED] Geo: Gracefully catch incorrect db key on primary. !2819
- [FIXED] Fix a regression breaking projects with an empty import URL. !2824
- [FIXED] Fix a 500 error in the SSH host keys lookup action. !2827
- [FIXED] Handle Geo DB replication lag as 24h/day & 7d/week. !2833
- [FIXED] Geo - Add a unique index on project_id to the Geo project_registry table. !2850
- [FIXED] Improve Geo repository sync performance for larger databases. !2887
- [FIXED] Ensure #route_setting is available before calling it. !2908
- [FIXED] Fix searching by assignee in the service desk. !2969
- [FIXED] Fix approvals before merge error while importing projects.
- [FIXED] Fix the gap in approvals in merge request widget.
- [FIXED] Fix branch name regex not saving in /admin/push_rule config.
- [FIXED] Fix merges not working when project is not licensed for squash.
- [CHANGED] Add Time estimate and Time spend fields in csv export. !2627 (g3dinua, LockiStrike)
- [CHANGED] Improve copy so users will set up SSH from DB for Geo. !2644
- [CHANGED] Support `codequality` job name for Code Quality feature. !2704
- [CHANGED] Support Elasticsearch v5.1 - v5.5. !2751
- [CHANGED] Geo primary nodes no longer require SSH keys. !2861
- [CHANGED] Show Geo event log and cursor data in node status page.
- [CHANGED] Use a logger for the artifacts migration rake task.
- [ADDED] LFS files can be stored in remote object storage such as S3. !2760
- [ADDED] Add LDAP sync endpoint to Groups API. !2785
- [ADDED] Geo - Log a repository created event when a project is created. !2807
- [ADDED] Show geo.log in the Admin area. !2845
- [ADDED] Commits integration with Jira development panel.
- [OTHER] Add missing indexes to geo_event_log table. !2836
- [OTHER] Geo - Ignore S3-backed LFS objects on secondary nodes. !2889
- Fix a bug searching private projects with Elasticsearch as an admin or auditor. !2613
- Don't put the password in the SSH remote if using public-key authentication. !2837
- Support handling of rename events in Geo Log Cursor.
- Update delete board button text color to red and fix hover color.
- Search for issues with multiple assignees.
- Fix: When MR approvals are disabled, but approvers were previously assigned, all approvers receive a notification on every MR.
- Add group issue boards.
- Ports style changes fixed in a conflict in ce to ee upstream to master for new projects page.
