## 11.11.8

- No changes.

## 11.11.7

### Security (5 changes)

- Don't override approval rules if not allowed.
- Grant admin note permissions in epics for maintainers and owners.
- Prevent an XSS vector in the add approver email.
- Ensure the Insights configuration project is part of the group and is accessible to the current user.
- Make vulnerability feedback invisible if limited access to repo.


## 11.11.4 (2019-06-26)

### Fixed (1 change)

- Use quarantine size to check push size against repository size limit. !14269


## 11.11.3 (2019-06-10)

### Fixed (1 change)

- Fix create mr from vuln modal regression. !13524


## 11.11.2 (2019-06-04)

### Performance (1 change)

- Geo - Does not apply selective sync restrictions while counting registries on the tracking database. !13257


## 11.11.0 (2019-05-22)

### Security (1 change)

- Destroy project remote pull mirrors instead of disabling. !10355

### Fixed (26 changes)

- Add missing endpoint for user information to GitHub API. !10482
- Remove slack slash commands double up. !10555
- Display Scoped Labels on Issue Board. !10669
- Ensure custom group template feature is available only for groups on gold and silver. !10678
- Fix removing and updating insights config, and foreign key constraints. !11030
- Geo: Fix broken button to delete orphaned upload registries through Admin. !11156
- Resolve: Epic labels in system notes point to the epic itself. !11234
- Geo: Fix: Project sync failures usually double-increment *_retry_count. !11381
- Fix unauthenticated GET of public Epics API. !11485
- Hide ScopedBadge overflow notes. !11548
- Fixes a CI failure in jest. !11586
- Fix error when reordering/deleting subgroup epics. !11837
- Fix some filter bar tokens not showing up when multiple assignees are enabled. !11939
- Geo: Fix OAuth authentication with relative URLs. !11976
- Fix for not being able to remove the last namespace/project from elasticsearch limited namespaces/projects. !11989
- Fix approvals project settings section when merge requests disabled. !12070
- Enable alert bot to use quick actions. !12127
- Geo: Remove counts over geo_event_log table. !12146
- Geo: Prevent RegistryFinder calls on the primary. !12183
- Fix placement of LDAP icon in members list. !12304
- Use path instead of a URL for accessing approval settings. !12414
- Remove non-semantic use of `.row` in member listing controls. !12466
- Force tag overwrite on mirror update. !12491
- Fixes the feedback paths on the project security dashboard. !12849
- Fixed starting a review on images.
- Fix updating board attributes through API.

### Changed (13 changes)

- Group SAML enforcement requires active SSO session for group access. !10034
- Geo: Rename "Disable" to "Pause|Resume" (Admin > Geo Nodes). !10297
- Upgrade group security dashboard to use gitlab-ui line chart. !10479
- Geo - Implement selective sync support for the LFS objects FDW queries. !10757
- Documentation : Improve selective sync documentation. !11072
- Geo: Implement selective sync support for the FDW queries to count the number of attachments to sync. !11107
- Allowing Elasticsearch indexing gap recovering. !11408
- Geo - Implement selective sync support for the FDW queries to count attachments. !11518
- Geo - Implement selective sync support for the FDW queries to find attachments. !11544
- Geo - Add selective sync support for the job artifacts FDW queries. !11892
- Fetch all available groups when creating MR approval rule. !12096
- SSO enforcement requires active SAML session for web access to project resources. !12109
- Perform LDAP group sync on sign in only for new users.

### Performance (3 changes)

- Swap conditions to reduce frequency of database query. !11217
- Add index for mirror_user_id to projects table. !11422
- Geo - Improve performance of the selective sync cleanup worker. !11998

### Added (27 changes, 2 of them are from the community)

- Proxy websocket requests to build services. !9723
- Add dependency proxy for containers. !9750
- Added gitlab:elastic:projects_not_indexed rake task. !9854 (Jason Colyer)
- Added Snowplow tracking to notes. !10104
- Support multiple assignees for merge requests. !10161
- Add UI to enable/disable a dependency proxy on a group level. !10386
- Let the GitLab Alert bot open incident issues. !10460
- Remove feature flag `:incident_management`. !10569
- Allow multiple secondary nodes behind a load balancer. !10755
- Copy LFS objects from pull mirror. !10779
- Geo: Inform users about current replication lag in the UI on secondaries. !10807
- Autosave description in epics. !10844
- Keep track of packages_file in ProjectStatistics. !11020
- Adds a dismissal item to the vulnerability modal. !11028
- Add project level config for merge train. !11065
- Support pie charts in Insights. !11186
- Create ActiveRecordModel and table for Merge Train feature. !11204
- Allow adding GitLab license at installation time. !11244
- Added ZAP Full Scan support for DAST. !11269
- Add created_at and updated_at filters to Epics API. !11315 (jramsay)
- Add API to retrieve security vulnerabilities. !11539
- Basic Rails implementation for BOM. !11613
- Add Frontend Store and UI For Environments Dashboard MVC. !11702
- Track clicks on uninstall button for kubernetes implementation. !12048
- Add Vulnerabilities API scoping: severity, confidence, and dismissal. !12076
- Alert users that protected environments affects feature flags. !12168
- Support creating a new child epic from the API.

### Other (8 changes, 1 of them is from the community)

- Improve project settings page layout and UX. !10388
- Uses the more explicit vulnerability feedback endpoints on the front end. !10461
- Automatically enable multiple MR assignees feature flag. !10558
- Move geo_log_cursor binary to the ee folder. !10821
- Move sidekiq-cluster to ee/bin. !11001
- Move ee-specific code from boards/components/issue_card_inner.vue. !11032 (Roman Rodionov)
- Make all billing cards fit in view. !11602
- Extracted EE specific lines for spec/javascripts/vue_mr_widget/mock_data.js. !11847


## 11.10.8 (2019-06-27)

- No changes.
### Security (2 changes)

- Gate MR head_pipeline behind read_pipeline ability.
- Do not allow localhost urls in GitHub Integration.


## 11.10.7 (2019-06-26)

### Fixed (1 change)

- Use quarantine size to check push size against repository size limit. !14271


## 11.10.6 (2019-06-04)

### Fixed (5 changes, 1 of them is from the community)

- Fix removing and updating insights config, and foreign key constraints. !11030
- Fix the group's epic page. The Paste issue link placeholder shown as 'undefinedundefinedundefined' in Chinese environment. And the error message showed nothing. !11312 (wdmcheng)
- Fix approvals project settings section when merge requests disabled. !12070
- Use path instead of a URL for accessing approval settings. !12414
- Fix relative url root issues with license management. !12488


## 11.10.4 (2019-05-01)

### Fixed (1 change, 1 of them is from the community)

- Fix error retrieving licenses when relative URL in use. !11717 (Hiroyuki Sato)

### Changed (1 change)

- [Insights] Change the default weeks period limit to 12. !11498


## 11.10.3 (2019-04-30)

- No changes.

## 11.10.2 (2019-04-25)

### Security (1 change)

- Handle race condition when creating an MR approval.


## 11.10.1 (2019-04-23)

### Fixed (4 changes)

- Fix approval rules when used with relative url root. !10819
- Fix add/remove pipeline dashboard issue. !11029
- Fix JWT token check when repository does not exist. !11033
- Fix preventing approval of merge requests by an author. !11263

### Changed (2 changes)

- Improve SAML settings with validation, design, and help text. !10450
- Use a single color for the Insights time series bar charts. !11076


## 11.10.0 (2019-04-22)

### Security (3 changes)

- Check label_ids parent when updating issue board.
- Geo - Improve security while redirecting user back to the secondary after a logout & re-login via the primary.
- Expose only basic group attributes in boards API.

### Fixed (25 changes)

- User Statistics in Admin Dashboard now a button. !8807
- Fix misalignment of dropdowns in edit board modal of issue boards. !9909
- Geo: Support archive recovery or streaming replication types in health check. !9935
- Geo: Only display Geo-specific clone instructions button on a Geo Secondary node. !10007
- Resolve Deletion of vulnerability-associated issuables prevents security report from loading. !10016
- Elasticsearch API: Fix project_id showing as 0 for all blobs. A reindex will be required. !10020
- Make editing the filters in the Group Security Dashboard easier. !10138
- Geo - Reset the verification checksum after deployment refs are created. !10160
- Search snippets via elasticsearch. !10325
- Fixed bug preventing users from adding child epics with multiple children. !10331
- Fix merge requests being added to Jira Development Panel. !10342
- Fix authors of merge commits being excluded from approving an MR. !10359
- Fix ChatOps Slack responder for gitlab.com. !10416
- Fix sorting by priority with filtering by approvers. !10446
- Make UpdateRepositoryStorageService idempotent. !10457
- Fix broken links to protected environments on the CI/CD settings page. !10470
- Notify owner that group is invalid when LDAP "Sync now" fails. !10509
- Fix user agent string for Hosted Jira. !10545
- Fix query used to calculate number of users over license. !10556
- Fix pipeline bridge serialization error. !10565
- Correct path to cluster health partial. !10638
- Ensure Insights charts show all periods even if there are no data. !10733
- Hide scoped labels help text without corresponding license. !10737
- Fix merge request operation failure (e.g. assigning user) when project approvers required increases. !10766
- Include subgroups when finding Insights issuables. !10801

### Changed (27 changes)

- Move project search bar into modal dialog on Operations Dashboard page. !9260
- Geo - Add selective sync support for the FDW queries to count synced registries. !9445
- Geo - Add selective sync support for the FDW queries to count failed registries. !9527
- Convert enable group authentication checkbox to toggle button. !9816
- Geo: Limit max backoff time by 1 hour, instead of 7 days. !9893
- Documented Guide to using Geo in HA with RDS cross-region replicas. !9985
- Dynamically resize security group dashboard vuln graph. !10028
- Add self approval of merge requests setting to merge requests approvals API. !10050
- elasticsearch: Switch from LZ4 to DEFLATE compression. !10072
- Geo - Store the invalid checksum when we have a mismatch. !10101
- Add requested resources to cluster health metrics. !10135
- Allow self-approvals in fallback approval rules. !10218
- Geo - Add selective sync support for FDW queries to find verified registries. !10255
- Add file line number to vuln modal. !10265
- Geo - Add selective sync support for FDW queries to find registries where verification has failed. !10266
- Enforce Geo JWT tokens scope for repository sync. !10303
- Display link to review note in text email, similar to HTML email. !10401
- Geo - Add selective sync support for the FDW queries to find mismatch registries. !10434
- Geo - Add selective sync support for queries to find registries retrying verification. !10436
- Geo - Add selective sync support for the FDW queries to find registries to verify. !10438
- Improve DAST location fingerprints. !10487
- Change order in dast location fingerprint. !10487
- Geo: Add selective sync support for the FDW queries to find unsynced projects. !10522
- Enrich container scanning with more data on the frontend. !10526
- [Geo] Don't mark sync as successful if repo does not exist because of some problems. !10578
- Move operations dashboard from Ultimate to Premium. !10586
- Support multiple chart per page for Insights.

### Performance (3 changes)

- Avoid a Gitaly N+1 when loading commits for Elasticsearch search results. !9760
- Geo: Optimize repository and wiki verification counts. !9939
- Avoid N+1 when loading Code search results with Elasticsearch enabled. !10394

### Added (31 changes, 1 of them is from the community)

- Add approval and unapproval webhooks. !8742
- Adding pipelines to the operations dashboard. !9197
- Add operations dashboard usage counts to usage data. !9291
- Automatically deprovision and update users from a configured identity via SCIM. !9388
- Add SCIM Token section to SAML SSO Settings. !9619
- Use merge request MERGE ref for attached merge request pipelines. !9622
- Geo: Support syncing over non-publicly accessible URLs. !9634
- Prevent merge if the merge request pipeline is stale. !9643
- Block possibility to change email for users with group managed account. !9712
- Geo admin panel for upload verification. !9720
- Geo: Create separate models for different registries. !9755
- Add ability to purchase extra CI minutes. !9815
- Update Web IDE config to accept ports. !9818
- Allow per-project and per-group enabling of Elasticsearch indexing. !9861
- Geo: Help admins diagnose configuration problems. !9988
- Added MAVEN_CLI_OPTS env var support to License Management CI job. !10012
- Show DAST vulnerabilities in the Group Security Dashboard. !10271
- Show DAST in Group Security Dashboard Back-End. !10277
- Removing pipeline dashboard feature flag. !10302
- Update user name upon LDAP sync. !10316 (@icode1)
- Collect usage of pod logs feature. !10370
- Added metrics reports widget to merge request page. !10380
- IP whitelisting for Geo-enabling functionality in the primary. !10383
- Persist in the URL the page and day range of vulnerabilities viewed in the Group Security Dashboard. !10402
- Add 'Metrics' job artifact report type. !10452
- Create a user via SCIM. !10456
- Geo: Display secondary replication lag on console (if lag > 0 seconds). !10471
- Add Roadmap to Epic page. !10488
- Expose merge request pipeline parameters for MR widget. !10502
- Allow instance admins to link all projects to Jira DVCS. !10541
- Added mutually exclusive key value labels.

### Other (4 changes)

- Simplify admin instance licenses page. !9785
- Extract EE specific files and externalize strings in admin application settings. !9930
- Add specs for coerced labels parameter in Epics API. !9932
- Improve project service desk settings. !10381


## 11.9.12 (2019-05-30)

### Security (3 changes, 1 of them is from the community)

- Filter relative links in wiki for XSS. (kerrizor)
- Fix XSS in Ancestor tooltip title.
- Ignore out of range epic IDs.


## 11.9.10 (2019-04-26)

### Security (1 change)

- Handle race condition when creating an MR approval.

### Fixed (1 change, 1 of them is from the community)

- Fix the group's epic page. The Paste issue link placeholder shown as 'undefinedundefinedundefined' in Chinese environment. And the error message showed nothing. !11312 (wdmcheng)


## 11.9.9 (2019-04-23)

### Fixed (1 change)

- Fix approval rules when used with relative url root. !10819


## 11.9.8 (2019-04-11)

### Fixed (1 change)

- Fix sorting by priority with filtering by approvers. !10446


## 11.9.7 (2019-04-09)

### Security (1 change)

- Expose only basic group attributes in boards API.


## 11.9.6 (2019-04-04)

### Fixed (3 changes)

- Fix project approval rule with only private group being considered as approved when override is allowed. !10356
- Fix approval rule sourcing from forked MR. !10474
- Guard against ldap_sync_last_sync_at being nil. !10505

### Added (1 change)

- Add Insights frontend to retrieve and render chart. !9856


## 11.9.5 (2019-04-03)

### Fixed (3 changes)

- Fix project approval rule with only private group being considered as approved when override is allowed. !10356
- Fix approval rule sourcing from forked MR. !10474
- Guard against ldap_sync_last_sync_at being nil. !10505

### Added (1 change)

- Add Insights frontend to retrieve and render chart. !9856


## 11.9.3 (2019-03-27)

### Security (1 change)

- Check label_ids parent when updating issue board.


## 11.9.2 (2019-03-26)

### Security (2 changes)

- Geo - Improve security while redirecting user back to the secondary after a logout & re-login via the primary.
- Check label_ids parent when updating issue board.


## 11.9.1 (2019-03-25)

### Fixed (1 change)

- Fix date save for Epic to reflect on UI immediately after save. !10321


## 11.9.0 (2019-03-22)

### Security (4 changes)

- Prevent Group SAML authorizing sign in without prior user approval.
- Respect group membership lock when importing a member from another group.
- Remove the possibility to share a project with a group that a user is not a member of.
- Prevent SAML access when disabled by group admin on GitLab.com.

### Fixed (22 changes)

- Allow assigning Prometheus alerts to multiple environments. !7361
- Fix repo pushes while initial Elasticsearch indexing not permitting initial indexing to complete. !9478
- Fix vulnerability occurrence scope to trailing 30 days. !9494
- Skip whitelisted vulnerabilities in Container Scanning reports. !9528
- Fix npm registry for yarn. !9599
- Renders inline downstream & upstream pipelines. !9627
- Prunes whole Geo event when there's only a primary. !9630
- Fix alert notifications for non-public projects. !9636
- Fix 500 error when visiting merged merge request. !9648
- Allow plus symbol in maven package version. !9657
- Show commands applied message when promoting issues to epics. !9669
- Ensure comments from merge request review is displayed in the same order as user commenting order. !9684
- Geo - Fix selective sync by namespace. !9732
- Fix bridge jobs than can be hidden keys too. !9796
- Fix approval-related UI showing up in free plan. !9819
- Add 'No approvals required' view to approval rules (behind feature flag). !9899
- Fix npm package install with a dot in the name. !9900
- GroupSAML for GitLab.com prevents blank NameID. !9907
- Fix protected environment initializer. !10150
- Fix SSH pull mirrors not working. !10272
- Fix HTML spew in Locked Files page.
- Fixes Broken new/edit feature flag form.

### Changed (9 changes, 1 of them is from the community)

- Remove authorization from /managed_licenses. !8541
- Consider dismissed items in security reports summary. !9275
- Add backend for cross-project pipeline dashboard MVC. !9396
- Create merge request approval rule for each code owner entry. !9455
- Split severity and confidence values for vulnerabilities. !9495
- Enforce Geo JWT tokens scope for file uploads and Geo API. !9502
- Update cluster health empty state. !9540 (George Tsiolis)
- Add extra graph spacing on the Security Dashboard Group Vulnerability Chart. !9780
- Add Kerberos URL back to clone panel. !9840

### Performance (1 change)

- Eliminate N+1 queries in Epics API. !9897

### Added (23 changes, 1 of them is from the community)

- Enabled setting the Security Dashboard as a default view for groups. !7889
- Add reordering of child epics. !9283
- Create MR from Vulnerability Solution. !9326
- Create pool repositories on Geo secondaries. !9428
- Add date range for security dashboard graph. !9446
- Add filtering merge requests by approvers. !9468
- Add audit log for managing feature flags. !9487
- Add DELETE package API endpoint. !9623
- Enrich container scanning report. !9641
- Adapt feedback for Container Scanning vulnerabilities. !9655
- Enforce merge request approvals from code owners. !9656
- Added vendored CI/CD template for Dependency Scanning job. !9660
- Add Insights config behind the "group_insights" feature flag. !9665
- Add single package API endpoint. !9667
- Added GET /licenses and DELETE /license/:id endpoints. !9733
- Add container scanning results to group security dashboard. !9736
- Add an incident management settings form and create issues from alertmanager alerts. !9773
- Add API for reordering child epics. !9781
- Allow guests to comment on epics. !9783
- Display Recent Boards in Board switcher. !9808
- Add Ancestors in Epic Sidebar. !9817
- Add vendored templates for SAST, DAST, Container Scanning and License Management job definitions. !9921
- Add realtime validation for user fullname and username on validation. !25017 (Ehsan Abdulqader @EhsanZ)

### Other (12 changes, 1 of them is from the community)

- Use export-import svg from gitlab-svgs. !9453
- Renames 'revert dismissal' to 'undo dismiss' on the Group security dashboard. !9500
- Using positional arguments in request specs have been deprecated. !9506 (Jasper Maes)
- Splits the severity and confidence constants in the group security dashboard frontend. !9535
- Add Gitlab.com gold trial callout to /billings. !9611
- Update project settings section titles and info. !9614
- Improve visual consistency of values in vulnerability modal. !9616
- Limit Group Security Dashboard to selected types of report. !9626
- Make related issues components reusable. !9730
- sidekiq-cluster: put each sidekiq in a new pgroup. !9775
- License Management: Load up to a 100 licenses per default. !9913
- Adds documentation for autoremediation. !10054


## 11.8.10 (2019-04-30)

- No changes.

## 11.8.3 (2019-03-19)

- No changes.

## 11.8.2 (2019-03-13)

### Fixed (4 changes)

- Fix 500 error when visiting merged merge request. !9648
- Fix bridge jobs than can be hidden keys too. !9796
- Fix approval-related UI showing up in free plan. !9819
- Add 'No approvals required' view to approval rules (behind feature flag). !9899


## 11.8.0 (2019-02-22)

### Security (2 changes)

- Sanitize user full name to clean up any URL to prevent mail clients from auto-linking URLs. !790
- Hide personal access tokens from other maintainers.

### Fixed (28 changes, 1 of them is from the community)

- Add keyboard navigation to issue board switcher and remove duplicate scroll bar. !8591
- Geo: Always update the default branch on the secondary. !9064
- Fix public group milestones not shown in epics autocomplete. !9068
- Check hosts file for nameserver IP. !9071
- Fixes the icon for fixed vulnerability in Container Scanning report. !9120
- Return 400 error instead of 500 when upload maven package with invalid version. !9125
- Fix mirrors that have invalid SSH public auth mode set. !9135
- Hide packages without version from UI. !9151
- Remove duplicate "Operations Dashboard" header/breadcrumb. !9152 (Nathan Friend)
- Create UTC date in subscription table. !9166
- Display epic icon in related epics list. !9166
- Don't validate Jenkins username if password is blank. !9198
- Don't show Alert widget for non-licensed users. !9224
- Group security dashboard: Fix overflow for Vulnerabilities with long titles. !9271
- Geo - Respect shard restriction while loading new resources to verify on the Geo secondary node. !9343
- When cleaning up repositories, ensure orphaned entries do not remain in the tracking database. !9344
- Geo - Make sure project does not meet selective sync rule before deleting it. !9345
- Fix alert notification emails are not being sent. !9393
- Fix alert notifications for managed Prometheus. !9402
- Replacing old blob methods in ElasticSerach module. !9418
- Add checks to prevent cycling hierarchy in epics structure. !9438
- Fix bug where users could not be added in protected branch rules. !9474
- Avoid SAML required_groups indiscriminately unblocking users on login. !9489
- Resolve Cannot scroll forwards in time for roadmap view. !9530
- Fix unleash server side cannot return feature flags. !9532
- Show alerts settings only for manual configuration. !9538
- Fix access to constant Gitlab::RepositorySizeError. !9579
- Clear our import data credentials when adding new mirrors. !24339

### Deprecated (1 change)

- Geo: Show hashed storage warnings on geo nodes page. !8433

### Changed (14 changes)

- Prevent commit authors from self approvaling merge requests. !9007
- Add docs link to explain legacy and new email format. !9020
- Recursively expands upstream and downstream pipelines. !9073
- Geo: Don't show external link icon on current node. !9130
- Issues created from vulnerabilities are now confidential by default. !9157
- Validate custom metrics. !9178
- Change paginate number to 20. !9213
- Convert buttons to button group on Group Security Dashboard. !9220
- Make it possible to edit Geo primary through API. !9328
- Geo: Handle repository and wiki sync separately in Geo::ProjectSyncWorker. !9360
- Geo: Add settings page empty state. !9415
- Renders New and Edit forms for feature flag in Vue and allow to define scopes.
- Improves title in feature flags empty states.
- Adds environment column to the feature flags page.

### Performance (5 changes)

- Solve a N+1 issue in Groups::AnalyticsController. !4508
- Refactored Epic app in Vuex for better performance and maintenance. !9361
- Optimize slow pipelines.js response. !9387
- Disable commit checks when no push rules are active. !9569
- Enable some frozen string in ee/lib.

### Added (22 changes, 1 of them is from the community)

- Elasticsearch: Support for Gitaly. !7434
- Canary deployment callout on the environments page. !8457
- Allow to filter notes in epics. !8978
- Multiple blocking merge request approval rules (behind feature flag). !9001
- Add support for auto-expanding Roadmap timeline on horizontal scroll. !9018
- Added Snowplow tracking to issues import. !9067
- Persist Group Level Security Dashboard state in URL. !9108
- Multiple environments support for feature flags (Unleash API standpoint). !9110
- Shows the approval given/required counts and its status for each MR when viewing the Merge Requests page. !9142 (Glavin Wiechert, Andy Steele)
- Support CURD operation for feature flag scopes. !9182
- Add epic links API endpoints. !9188
- Store DAST scan results in the database. !9192
- Add LDAP integration to smartcard authentication. !9235
- Allow SSO enforcement in group settings for GitLab.com. !9240
- Add API endpoint for project packages. !9259
- Add upvote/downvote information to epics API. !9264
- Resolve Implement access controls when SSO enforcement enabled. !9270
- Add package files API endpoint. !9305
- Support alerts from external Prometheus servers. !9334
- Cross-project pipelines support in .gitlab-ci.yml. !9374
- Enable mails for external alerts. !9457
- Moving repository across shards leaves the pool.

### Other (13 changes, 7 of them are from the community)

- Gather JIRA DVCS integration usage data. !8949
- ActiveRecord::Migration -> ActiveRecord::Migration[5.0] for AddAlertManagerTokenToClustersApplicationPrometheus and EnqueuePrometheusUpdates. !9049 (Jasper Maes)
- Track navbar links in Snowplow. !9059
- Adds snowplough tracking for the group security dashboard filters. !9119
- Support Ajax endpoints for FeatureFlagsController. !9127
- Fix deprecation: Passing an argument to force an association to reload is now deprecated. !9140 (Jasper Maes)
- Fix deprecation: #original_exception is deprecated. Use #cause instead. !9141 (Jasper Maes)
- Uses GLDropdown for licence management. !9237
- Replace deprecated render text. !9346 (Jasper Maes)
- Fix several ActionController::Parameters deprecations. !9347 (Jasper Maes)
- Fix deprecation: uniq is deprecated and will be removed from Rails 5.1. !9348 (Jasper Maes)
- Turn on rubocop for frozen string in ee/. (gfyoung)
- Creates an EE component for the pipeline graph.


## 11.7.12 (2019-04-23)

- No changes.

## 11.7.11 (2019-04-09)

### Security (1 change)

- Expose only basic group attributes in boards API.


## 11.7.10 (2019-03-28)

### Security (1 change)

- Check label_ids parent when updating issue board.


## 11.7.8 (2019-03-26)

### Security (2 changes)

- Geo - Improve security while redirecting user back to the secondary after a logout & re-login via the primary.
- Check label_ids parent when updating issue board.


## 11.7.7 (2019-03-19)

- No changes.

## 11.7.5 (2019-02-05)

### Fixed (2 changes)

- Fix Kerberos authentication. !9390
- Fix background migration error when project repository is missing. !9392


## 11.7.2 (2019-01-29)

### Security (6 changes)

- Avoid leaking unauthorized approver group members. !766
- Sanitize user full name to clean up any URL to prevent mail clients from auto-linking URLs. !791
- Check access rights when creating/updating ProtectedRefs.
- Fix locked file visibility issue for private repositories.
- Filter out non-project member approvers.
- Remove HTTP POST in JIRA OAuth access_token endpoint.


## 11.7.1 (2019-01-28)

### Security (6 changes)

- Avoid leaking unauthorized approver group members. !766
- Sanitize user full name to clean up any URL to prevent mail clients from auto-linking URLs. !791
- Check access rights when creating/updating ProtectedRefs.
- Fix locked file visibility issue for private repositories.
- Filter out non-project member approvers.
- Remove HTTP POST in JIRA OAuth access_token endpoint.


## 11.7.0 (2019-01-22)

### Security (1 change)

- Add a shared secret to prevent abuse of the alert endpoint.

### Fixed (27 changes, 2 of them are from the community)

- Defaults to feature flags link for Operations entry. !8622
- Fix error on explore page when logged out due to gold trial callout. !8674
- Prevents the empty state from showing when the dashboard errors. !8703
- Allow matching only the repo-root for CODEOWNERS. !8708
- Fix adding labels to epics using quick actions. !8772
- Geo: Keep the minimum cursor last event. !8832
- Reinstate sorting issuable by weight. !8834
- Geo - Show the proper label for the last repository check run on Geo projects page. !8844
- Resolve Reorder gitlab:elastic:index rake tasks to ensure wikis and database are completed even if projects error out. !8852
- Remove dash on issue weight for unauthorized users. !8882 (George Tsiolis)
- Dismiss epic promotion and persist it across reloads. !8885
- Fix JIRA Development Panel links with subgroups. !8908
- Remove epic field in sidebar for projects without groups. !8919
- Remove duplicate padding from issue board switcher. !8928
- Resolve Ctrl+Enter immediately adds MR comment. !8932
- Geo: Ignore invalid attributes when updating Geo node status. !8957
- Fix border-radius for related issues. !8958 (Johann Hubert Sonntagbauer)
- Fix Security Dashboard Header font size. !9011
- Fix title and description for issue created from a vulnerability. !9022
- Pseudonymizer: Gracefully handle empty pseudo entries. !9044
- Fix permission check when creating an issue from a vulnerability. !9055
- Docfix - broken doc links for Secure/Autodevops features. !9058
- Fix Error 500 when deleting a pipeline via the API. !9104
- Uses project_id instead of project on the group security dashboard. !9109
- Recursively get all of a groups projects. !9205
- Fix data migration failure if approvals_before_merge is set to too high. !9217
- Don't remove milestones when moving issues to board backlog from non-milestone list.

### Changed (5 changes, 1 of them is from the community)

- Update Geo nodes empty state. !8576 (George Tsiolis)
- Add search field to issue board switcher. !8862
- Allow downloading package files from UI. !8888
- Changes to the data model for counts on the Group Security Dashboard. !9035
- Fix packages UI mentioned only Maven packages support. !9132

### Performance (2 changes, 1 of them is from the community)

- Fix timeout loading Open list when board contains assignee lists.
- Enable some frozen string in ee/lib. (gfyoung)

### Added (17 changes)

- Add an instance-level endpoint for downloading maven packages. !8274
- Add NPM registry support to GitLab packages. !8673
- Store container scanning CI jobs results into the database. !8797
- Add a group-level endpoint for downloading maven packages. !8798
- Add Filtering vulnerabilities in the Group Security Dashboard. !8817
- Allow to filter Feature Flags. !8821
- Geo - Show last verification time on Geo projects page. !8845
- Adds basic filtering to the Group Security Dashboard frontend. !8886
- Autocomplete issues and MRs in epics. !8936
- Adds project filtering to the GSD. !8944
- Allow using TCP for DB load balancing DNS lookups. !8961
- Add filtering for summary and history on security dashboard. !8972
- Add solution card to the vulnerability modal. !9030
- Allows the Group Security Dashboard to select multiple filters. !9031
- Added Snowplow tracking to issues export. !9045
- Add support for relationship between epics. !9051
- Added pagination to epics API endpoint.

### Other (13 changes, 3 of them are from the community)

- Promote starting a GitLab.com Gold trial on the dashboard. !6947
- Adds event tracking to navbar. !7787
- Update tracing settings to match error tracking settings. !8786
- Adapt subscriptions page for free plans and trials. !8838
- Support for new SAST and dependency scanning report format. !8869
- Remove deprecated ActionDispatch::ParamsParser. !8897 (Jasper Maes)
- Fix deprecation: Comparing equality between ActionController::Parameters and a Hash is deprecated. !8914 (Jasper Maes)
- Removes Notes from GitLab Pseudonymizer config. !8923
- Add count of projects with tracing enabled to usage ping data. !8940
- Adds dependency scanning to the report type filters on GSD. !9034
- Fix deprecation: Using positional arguments in specs for EE spes in spec/. !9040 (Jasper Maes)
- Pass issuable-type in AddIssuableForm. !9111
- Gather deepest epic relationship data.


## 11.6.11 (2019-04-23)

- No changes.

## 11.6.10 (2019-02-28)

### Security (5 changes)

- Remove the possibility to share a project with a group that a user is not a member of.
- Prevent Group SAML authorizing sign in without prior user approval.
- Prevent SAML access when disabled by group admin on GitLab.com.
- Respect group membership lock when importing a member from another group.
- Ignore out of range epic IDs.


## 11.6.9 (2019-02-04)

- No changes.

## 11.6.8 (2019-01-30)

- No changes.

## 11.6.5 (2019-01-17)

### Fixed (1 change)

- Fix Error 500 when deleting a pipeline via the API. !9104


## 11.6.4 (2019-01-15)

- No changes.

## 11.6.3 (2019-01-04)

### Fixed (1 change)

- Fix instance project templates no longer working. !9019


## 11.6.2 (2019-01-02)

### Fixed (1 change)

- Fix issue ID wrapping and avatar counter shrinking in Related Issues list. !8854


## 11.6.1 (2018-12-28)

### Security (1 change)

- Add a shared secret to prevent abuse of the alert endpoint.


## 11.6.0 (2018-12-22)

### Security (7 changes)

- Switch from CBC to GCM for Geo logout tokens. !8518
- Prevent reporter roles from viewing the Jaeger tracing settings page.
- Sanitize tracing external_urls before saving to DB and when displaying the URL to prevent XSS issues.
- Fix IDOR at /drafts/publish.
- Authorize users when listing board users and milestones.
- Resolve: Guest can set weight of a new issue.
- Fixes XSS with merge request approvers selection.

### Fixed (27 changes, 2 of them are from the community)

- Ensure that avatars in approvals have correct tooltip. !6269
- Geo: Fix push to secondary over SSH for LFS. !8044
- Don't show packages tab and settings for starter license. !8270
- Makes the vulnerability name on the Group Security Dashboard a button for better A11y. !8341
- Used the iid instead of the id for linked issues on the Group Security Dashboard. !8357
- Show navigation line separator when instance etrics is disabled. !8379 (George Tsiolis)
- Fix project deploy key creation and deletion as admin. !8432
- Changes initial state for disabled prometheus integrations. !8434
- Fix a typo in Admin: intergration -> integration. !8444 (Vincent AUBERT)
- Geo: Moving registry deletion into the job that deletes the files and project record. !8480
- Parameterize alerting rules with variables. !8481
- Fix PostReceive failing for project mirrors missing local branch. !8495
- Rails 5: Fix the check whether the database is in read-only mode. !8594
- Raisl 5: Fix Gitlab::Database::LoadBalancing#caught_up? check. !8595
- Renders upstream and downstream pipelines in the main pipeline graph. !8607
- Fix issue board api with special milestones. !8653
- fix pod dropdown not switching pod logs. !8660
- Geo - Respect the next retry time when re-verifying failed repositories. !8661
- Update elasticsearch system check to check for new supported versions. !8683
- Handle null start or due dates for dates sourcing milestone in Epics. !8689
- Fixed license managment path in MR widget for fork cases. !8700
- Fix gitlab:geo:check rake task. !8714
- Fix ability to choose shards for selective sync. !8717
- Add Rails.version to the Geo cache keys. !8775
- Support older NGINX version forwarding the client certificate for smartcard auth. !8784
- Remove duplicated smartcard login button. !8793
- Disable password autocomplete in mirror form fill.

### Deprecated (1 change)

- Deprecate non-hashed repository storage for Geo installations. !8739

### Changed (17 changes, 1 of them is from the community)

- Adds Group SAML metadata endpoint. !5782
- Group SAML SSO page warns when linking account. !8295
- Change the delete custom metric alert. !8430
- Replace weight icon. !8448 (George Tsiolis)
- Switch snowplows stateStorageStrategy to cookie. !8461
- Move merge request approval settings. !8493
- Geo: Constantly reverify repositories. !8550
- Add file and line numbers to issues created from SAST vulnerabilities. !8578
- Redesign MR header sections and approvals (EE). !8593
- Add packages_enabled attribute to Projects API. !8604
- Run geo check task from gitlab check. !8616
- Change issue create weight dropdown to an input. !8648
- Add epics state filtering in roadmap view. !8658
- Users can unlink Group SAML from accounts page. !8682
- Update casing in Built-in on project templates tab. !8688
- Epic issue list and related issue list re-design.
- Add sort direction button with sort dropdown for Epics and Roadmap.

### Performance (5 changes, 3 of them are from the community)

- Remove partial index for projects on mirror and mirror_last_update_at. !8585
- Enable some frozen string in ee/app. !8667 (gfyoung)
- Remove redundant indices for is_sample on push_rules and next_execution_timestamp on project_mirror_data. !8695
- Enable some frozen string in ee/app. (gfyoung)
- Enable some frozen string in ee/app. (gfyoung)

### Added (10 changes)

- Add support for Group-level project templates. !6878
- Added web terminals to Web IDE. !7386
- Promote an Issue to an Epic using quick action. !8051
- Smartcard authentication. !8120
- Adds Security dashboard empty state. !8443
- Add vulnerability history at group level. !8603
- Adds group security dashboard metrics chart. !8631
- Add milestones autocomplete for epics. !8632
- Parse and store dependency scanning reports in database. !8642
- Adds EE store to handle upstream & downstream pipelines.

### Other (13 changes, 4 of them are from the community)

- Add subscription table to GitLab.com billing areas. !7885
- UX improvements for the group security dashboard. !8217
- Restyles the dismissed vulnerabilities. !8401
- Adds PHILOSOPHY.md and references GitLab Product Handbook. !8515
- Make sidekiq-cluster play well with Sidekiq 5.2.2+. !8522
- Rails5: Passing a class as a value in an Active Record query is deprecated. !8540 (Jasper Maes)
- render :nothing option is deprecated, Use head method to respond with empty response body. !8560 (Jasper Maes)
- Add help page link for licence management in CI/CD settings. !8561 (George Tsiolis)
- Re-orders the Group Security Dashboard. !8624
- Move EE only differences for finders. !8629 (George Tsiolis)
- Add count of projects with at least one package to a usage ping data. !8641
- Added recommendations for handling deleted documents in Elasticsearch.
- Use new information-o icon for Security Dashboard.


## 11.5.11 (2019-04-23)

### Security (1 change)

- Respect group membership lock when importing a member from another group.


## 11.5.8 (2019-01-28)

### Security (6 changes)

- Avoid leaking unauthorized approver group members. !766
- Sanitize user full name to clean up any URL to prevent mail clients from auto-linking URLs. !793
- Check access rights when creating/updating ProtectedRefs.
- Fix locked file visibility issue for private repositories.
- Filter out non-project member approvers.
- Remove HTTP POST in JIRA OAuth access_token endpoint.


## 11.5.5 (2018-12-20)

- No changes.

## 11.5.3 (2018-12-06)

- No changes.

## 11.5.2 (2018-12-03)

### Fixed (2 changes)

- Fix inability to scroll dashboard. !8459
- Fix issues analytics query when ordering issues by priority. !8509


## 11.5.1 (2018-11-26)

### Security (6 changes)

- Sanitize tracing external_urls before saving to DB and when displaying the URL to prevent XSS issues.
- Prevent reporter roles from viewing the Jaeger tracing settings page.
- Fix IDOR at /drafts/publish.
- Authorize users when listing board users and milestones.
- Resolve: Guest can set weight of a new issue.
- Fixes XSS with merge request approvers selection.


## 11.5.0 (2018-11-22)

### Security (2 changes)

- Escape entity title while autocomplete template rendering to prevent XSS. !696
- Prevent templated services from being imported.

### Removed (1 change)

- Remove security report summary from pipelines view. !7844

### Fixed (25 changes, 3 of them are from the community)

- Geo: Remove connectivity check from primary to secondary from gitlab:geo:check rake task. !7821
- Include (closed) for closed epics in parsed text. !7946
- Add new state to the cluster application vue app. !7954
- Do not allow to assign an issue to an epic twice. !8004
- [Geo] Fix: Deleting a project leaves orphaned LFS objects and CI Job artifacts around. !8031
- Support `/client/features` Unleash endpoint. !8045
- Fix button rendering in license management in FF. !8046
- Geo: Handle orphaned Uploads records. !8054
- Geo - Redirect user back to the secondary after a logout & re-login via the primary. !8157
- Fix approver removal still being conducted even when "Cancel" is clicked in confirmation prompt. !8178
- Link project short SHA to commit url. !8214
- Update ops dashboard remove dropdown button. !8236 (George Tsiolis)
- Clear ops dashboard project search input on submit. !8239 (George Tsiolis)
- Fixes a dismissed vulnerability bug on the group security dashboard. !8343
- Fixes missing fields on the group security dashboard. !8360
- Fixes the view issue button in the Group Security Dashboard. !8385
- Ops Dashboard should be available for public projects on GitLab.com. !8399
- Update draft comments design to match new design. !8405
- Change issues analytics breadcrumb. !8414 (George Tsiolis)
- Include classification label in project API. !8426
- Fix Pod Log topbar position when perf bar is disabled.
- Always proxy reports downloads.
- Removes extra rigth margin from job page.
- Geo: Rails console message display primary/secondary state incorrectly.
- Disable Feature Flags and Packages if repository is disabled.

### Changed (13 changes, 1 of them is from the community)

- Add test button to Group SAML settings. !5622
- Group SAML status badges on members page. !5807
- Update related issues list styling to be more space efficient. !7784
- Refactor test reports to use new artifact architecture. !7827
- Add timeline icon for issue weights. !7847 (George Tsiolis)
- Added a search bar to `Admin > Geo > Projects`. !8079
- Geo: Deprecate source installations instructions. !8134
- Does not synchronize default branch for pull mirrors. !8138
- Adds split error states for the group security dashboard. !8208
- Geo: Improve read-only message in secondary nodes for actionable screens. !8238
- Improve error messages for operations dashboard. !8244
- Add documentation link to ops dashboard. !8296
- Issue board card design. !21229

### Added (24 changes, 1 of them is from the community)

- Group-level file templates. !7391
- Adds group-level Security Dashboard counts. !7564
- Parse SAST reports and store vulnerabilities in database. !7578
- elasticsearch 6 support - migrate from parent/child relationships to join. !7618
- Geo: Admin > Geo > Projects support for batch operations. !7806
- Create system notes for epic close and reopen. !7850
- Add Tracing landing and settings page. !7903
- Add modals and actions to the vulnerabilities in the Group security dashboard. !7910
- Assign code owner as approver. !7933
- Enable previewing of draft review comments. !7936
- Audit log: Add logging for project feature changes. !7962
- Add project operations dashboard. !7973
- Audit log: Add audit events for group setting changes. !7987
- Add approve quick action. !7989
- Show actual Milestone dates within tooltips for Milestones in Epics sidebar. !8048
- Allow filtering by weight in issues API. !8140 (Heinrich Lee Yu)
- Filter epics by state in API. !8179
- Support epics autocomplete for project objects. !8180
- Add 'l', 'r' and 'e' keyboard shortcuts support in Epic. !8203
- Configurable GitHub static context for statuses integration. !8235
- Send notifications for epic status change. !8247
- Support license management and performance using new reports syntax.
- Support reports: for project security dashboard.
- Add chart of issues created per month.

### Other (17 changes, 11 of them are from the community)

- Update boards list selector specs. !6266 (George Tsiolis)
- Write some Geo development documentation. !7452
- Connects the Group Security Dashboard API and Frontend. !7793
- Rails5: Fix epics finder count_key method In Rails5, the state enum value is passed instead of the database integer. !7822 (Jasper Maes)
- Rails 5: fix presence message validation for prometheus_alert. !7823 (Jasper Maes)
- Rails 5: fix mysql milliseconds problem in prometheus alert event spec. !7828 (Jasper Maes)
- Rails5: fix VulnerabilitySummaryEntity. !7893 (Jasper Maes)
- Update feature flags empty state. !7967 (George Tsiolis)
- Adds the security dashboard link. !7974
- Remove tooltip on sidebar text buttons. !8021 (George Tsiolis)
- Add a metric to the usage ping data to track the number of projects with at least one alert. !8058
- Remove unneeded permission checks from the mirror repositories partial. !8077
- Rails5: fix flaky mysql reset pipeline minutes spec. !8122 (Jasper Maes)
- Move `prepend` outside the `class` block for finders. !8192 (George Tsiolis)
- Rails5: fix operations controller spec nil parameter. !8209 (Jasper Maes)
- Update related issues title typography. !8267 (George Tsiolis)
- Geo: Clarify Geo HA documentation.


## 11.4.9 (2018-12-03)

- No changes.

## 11.4.8 (2018-11-27)

### Security (5 changes)

- Escape entity title while autocomplete template rendering to prevent XSS. !707
- Authorize users when listing board users and milestones.
- Fix IDOR at /drafts/publish.
- Resolve: Guest can set weight of a new issue.
- Fixes XSS with merge request approvers selection.


## 11.4.7 (2018-11-20)

### Fixed (1 change)

- Fix code owner as merge request suggestion not available under Starter plan. !8248


## 11.4.6 (2018-11-18)

### Security (1 change)

- Prevent templated services from being imported.


## 11.4.5 (2018-11-04)

### Fixed (1 change)

- Stops showing review actions on commit discussions in merge requests. !8007

### Performance (1 change)

- Add indexes to all geo event foreign keys. !7990


## 11.4.4 (2018-10-30)

- No changes.

## 11.4.3 (2018-10-26)

- No changes.

## 11.4.2 (2018-10-25)

### Security (1 change)

- Escape entity title while autocomplete template rendering to prevent XSS. !707


## 11.4.1 (2018-10-23)

- No changes.

## 11.4.0 (2018-10-22)

### Security (3 changes)

- Properly filter private references from system notes.
- Project groups approvers no longer leak private groups info.
- Protect against CSRF attacks when adding Slack app.

### Removed (1 change)

- remove unnecessary help text from container scanning results. !7304

### Fixed (18 changes, 1 of them is from the community)

- Prune all the Geo event log tables correctly. !6175
- Synchronize the default branch when updating a pull mirror. !7242
- Pushing to a merge request clears the approvals list even if the respective project setting is enabled and there is no fixed required number of approvals configured. !7328
- Align epics and roadmap empty state buttons to the center. !7358 (George Tsiolis)
- Add link to issue on epic. !7407
- Check for force env var when rebuilding auth_keys. !7419
- Update popover URL to point to help page of same domain. !7446
- Geo - Does not raise error 500 on Geo projects list page for orphaned entries. !7565
- Show promotion for epics on issues. !7602
- Fix Epic subscription toggle behaviour. !7723
- Geo - Send a cache invalidation event via the log cursor whenever features are changed on the primary. !7738
- Fix epic milestone dates incorrect after issue is linked to another epic. !7809
- Fixes warning for used minutes in runner showing when user still has minutes. !7843
- Fix disappearing weight input in Firefox. !7869
- Don't synchronize default branch when updating a SSH mirror. !7891
- Fix broken tokenization for filtered search bar in Epics. !7972
- Fix bug when resolving a discussion via a batch comment published right away.
- Fix wrong color in resolve/unresolve checkbox when using MR reviews.

### Changed (14 changes)

- Geo: Decrease frequency of project shard schedulers when few projects to schedule. !7287
- Added placeholder to weight input for issue sidebar. !7346
- updated icons used in filtered search dropdowns. !7356
- Geo: Display helpful feedback when proxying an SSH git push to secondary request. !7357
- Geo - Include keep-around and other Gitlab-specific references in the checksum calculation. !7367
- Polish security report externalizations. !7373
- Listen for resolved Prometheus alerts. !7382
- Rename date related labels for Epics. !7447
- Add reports CI syntax for Code Quality reports. !7465
- Support short reference to epics from project entities. !7475
- Geo: Downgrade Exclusive Lease warnings from Log Cursor to debug. !7476
- Geo: Allow nodes to be editable in more scenarios. !7832
- Account for issues created in the middle of a milestone in burndown chart.
- [Geo] Add CI job artifact numbers to rake geo:status.

### Performance (1 change)

- Update DB model for security reports.

### Added (20 changes, 1 of them is from the community)

- Batch comments on merge requests. !4213
- Use Geo log to remove files when migrated to object storage. !5966
- Add support for closing epics. !7302
- Add `auditor_groups` configuration so Audit users can be specified using SAML groups. !7340 (St. John Johnson)
- Geo - Add an event to reset checksums on Geo secondary nodes. !7394
- Starts adding the dashboard page view. !7400
- Add `Manage licenses` button to MR widget and pipelines view. !7411
- Add Open/Closed epics tabs in list view. !7424
- Add Feature Flags MVC. !7433
- Suggest approvers based on code owners. !7437
- Geo: Add a backoff time to few Geo workers to save resources. !7470
- Persist Prometheus alert events. !7493
- Geo: Added a button to Admin UI > Geo Nodes to open Geo Projects screen of any secondary node. !7512
- Show Alert Thresholds on monitoring dashboards. !7538
- Support autocomplete for commands in epics. !7588
- Add form to enter licenses manually. !7603
- Geo: Added `All` tab in Geo Nodes > Projects. !7745
- Geo: Add a Geo Status Widget to Admin > Projects. !7789
- Add data model and migration for vulnerabilities.
- Adds Batch Comments to Merge Requests [EEP].

### Other (8 changes, 1 of them is from the community)

- Add runner quota information to job API. !7233
- Resolve "ee:geo QA specs are failing as of !7210". !7315
- remove readme checkbox from "create project" page. !7332
- Create a generic JS function that we can apply to being able to track arbitrary events. !7403
- Rename Admin Area Geo Nodes nav item to Geo. !7466
- Group weight icon and text on issue list and issue boards. !7484 (George Tsiolis)
- Adds expandable/collapsable section for Snowplow. !7798
- API: Allow issue weight parameter to be greater than or equal to zero.


## 11.3.14 (2018-12-20)

- No changes.

## 11.3.13 (2018-12-13)

- No changes.

## 11.3.11 (2018-11-26)

### Security (7 changes)

- Escape entity title while autocomplete template rendering to prevent XSS. !697
- Properly filter private references from system notes.
- Authorize users when listing board users and milestones.
- Project groups approvers no longer leak private groups info.
- Resolve: Guest can set weight of a new issue.
- Fixes XSS with merge request approvers selection.
- Protect against CSRF attacks when adding Slack app.


## 11.3.10 (2018-11-18)

- No changes.

## 11.3.9 (2018-10-31)

- No changes.

## 11.3.8 (2018-10-27)

- No changes.

## 11.3.7 (2018-10-26)

### Security (1 change)

- Escape entity title while autocomplete template rendering to prevent XSS. !697


## 11.3.6 (2018-10-17)

### Fixed (1 change)

- Don't reset the default branch when repository mirroring is enabled. !7944


## 11.3.5 (2018-10-15)

### Fixed (1 change)

- Fix epic milestone dates incorrect after issue is linked to another epic. !7809


## 11.3.4 (2018-10-05)

### Security (1 change)

- Properly filter private references from system notes.


## 11.3.3 (2018-10-04)

- No changes.

## 11.3.2 (2018-10-03)

### Fixed (1 change)

- Geo: repository shard verification job should have unique lease keys per shard name. !7474


## 11.3.1 (2018-09-26)

### Security (2 changes)

- Project groups approvers no longer leak private groups info.
- Protect against CSRF attacks when adding Slack app.


## 11.3.0 (2018-09-22)

### Security (1 change)

- Prevent regular users from moving projects to different storage shards.

### Fixed (29 changes, 11 of them are from the community)

- don't add empty query params to boards. !4441
- Geo: sync disabled wikis. !6420
- Rails 5 fix alerts controller spec for post json parameters. !6795 (Jasper Maes)
- Fixes 500 error on user creation from admin panel with spaced username. !6804 (Jacopo Beschi @jacopo-beschi)
- Don't show search results for projects that have been deleted when using elastic search. !6830
- Geo: Use database-cached status if redis-cached status is unavailable. !6854
- [Geo] Fix: Custom favicons not being replicated by Geo. !6860
- Rails5 fix AddMilestoneToLists migration rollback deleting wrong foreign key. !6865 (Jasper Maes)
- Rails5 fix passing Group objects array into for_projects_and_groups milestone scope. !6873 (Jasper Maes)
- Rails5: fix mysql milliseconds problem in project_import_state_spec. !6874 (Jasper Maes)
- Fix Jira integration duplicating branches and MRs. !6876
- Rails5: fix mysql milliseconds problem in project_spec. !6880 (Jasper Maes)
- Remove https from Snowplow Collector URI placeholder in Admin Areawq. !6886
- Geo: Replicate keep around refs. !6922
- Fixes bug that prevented a user from seeing the system header and footer settings on the admin dashboard. !6926
- Rails5 fix duplicate gpg signature in path lock spec. !6939 (Jasper Maes)
- Rails5: Fix audit event spec. !6940 (Jasper Maes)
- Rails5: fix mysql milliseconds problem in project registry spec. !6943 (Jasper Maes)
- LDAP - Does not update permissions on a read-only database. !6965
- Rails5 fix project import spec. !6981 (Jasper Maes)
- Geo: Resolve sticky failures when attachments are missing on primary. !6991
- Geo: LFS batch downloads are OK to be handled by secondary. !7209
- Geo - Synchronize the default branch in secondary nodes. !7218
- Handle fixed dates seperately from selected dates in Epics. !7227
- Fix tooltip string to support dynamic date type in Epic sidebar. !7243
- Fix an error in docs about fetching artifacts using API. !7244
- Return proper status code when creation of an alert fails. !7360 (Peter Leitzen)
- Geo - Find the remote root ref using a JWT header for authentication. !7405
- Add weight to issue hook.

### Changed (3 changes, 1 of them is from the community)

- Allow push_code when auth'd via Geo JWT. !6455
- Prefer From address over Sender for Service Desk emails. !7006 (Andreas Josephson)
- Add CI Job token support to Maven packages API. !7249

### Performance (3 changes)

- Reduce queries needed for CI artifacts on merge request widget. !6978
- Use limited count approach on Protected Environments view. !6987
- Limit sidekiq-cluster concurrency to a maximum of 50. !7025

### Added (15 changes, 2 of them are from the community)

- Allow custom notification for new epic event. !5863
- Geo: SSH git push to secondary -> proxy to Primary. !6456
- Allow epic start/due dates to be sourceable from issue milestones. !6470
- Add ability to upload and download maven packages from/to GitLab. !6607
- Added an instance-level license template project. !6631 (Dan Barker)
- Add backend structure for ProtectedEnvironments. !6672
- Add UI for GitLab private Maven repository feature. !6781
- Add support for sorting epics. !6885
- Allow specifying code owners in a CODEOWNERS file. !6916
- Quick action for adding/removing epic to issues. !6934
- Show total and completed instances deployed on deploy boards. !6955
- Show security analysis status on the environments page. !6987
- Add Instance Review for Core users. !6995
- Introduce custom instance-level templates for Dockerfile, .gitignore, and .gitlab-ci.yml files. !7000
- Adds Rubocop rule to enforce class_methods over module ClassMethods. !7044 (Jacopo Beschi @jacopo-beschi)

### Other (4 changes)

- Removes feature flag code surrounding Protected Environments feature. !7338
- Creates vue component for shared runner limit.
- Allow MR authors to approve their MRs.
- Remove differences between CE and EE settings panel component.


## 11.2.8 (2018-10-31)

- No changes.

## 11.2.7 (2018-10-27)

- No changes.

## 11.2.6 (2018-10-26)

### Security (1 change)

- Escape entity title while autocomplete template rendering to prevent XSS. !698


## 11.2.5 (2018-10-05)

### Security (1 change)

- Properly filter private references from system notes.


## 11.2.4 (2018-09-26)

### Security (2 changes)

- Project groups approvers no longer leak private groups info.
- Protect against CSRF attacks when adding Slack app.


## 11.2.3 (2018-08-28)

- No changes.

## 11.2.2 (2018-08-27)

### Security (1 change)

- Prevent regular users from moving projects to different storage shards.


## 11.2.1 (2018-08-22)

- No changes.

## 11.2.0 (2018-08-22)

### Security (1 change)

- Don't expose project names in EE counters.

### Fixed (32 changes, 11 of them are from the community)

- Allow Geo node to be edited once the database is failed over. !6248
- Fix a bug where user was unable to delete a branch when repo size was above the limit. !6373
- Rails5 fix AttachmentRegistryFinder arel queries. !6396 (Jasper Maes)
- Add Premium license checks for system messages. !6460
- Fixes arrow-icon color and alignment in linked pipeline in merge request widget. !6479
- Rails 5 fix the matcher expected the ApplicationSetting to be invalid, but it was valid instead. !6488 (Jasper Maes)
- Geo: Gracefully handle deleted events from Geo event log. !6506
- Rails5 fix NoMethodError: undefined method 'message' for nil:NilClass. !6507 (Jasper Maes)
- Fix billing card title colors. !6563
- Rails5 fix undefined method 'namespace_project_settings_repository_path'. !6581 (Jasper Maes)
- Rails5 fix no implicit conversion of Symbol into Integer. !6582 (Jasper Maes)
- Rails 5 fix NoMethodError: undefined method 'message' for nil:NilClass in host_spec.rb. !6589 (Jasper Maes)
- Fix mobile view of pod logs. !6597
- Add left-padding to diverged-from-upstream label. !6647
- List groups with developer maintainer access on project creation. !6678
- no longer fail when setting up Geo database with GDK. !6680
- Allow Pseudonymizer to write to a bucket without having permissions to see all buckets. !6682
- Hide Expand button on empty MR widget Performance section. !6685
- Ensure that Create issue button is shown in vulnerability dialog. !6708
- Use same gem versions for Rails 5 as for Rails 4. !6712 (Jasper Maes)
- Rails5 correct wrong geo job name. !6713 (Jasper Maes)
- Elasticsearch: Fix a bug causing some types of note to miss being indexed. !6736
- Rails 5 fix product array method delagation by manually calling .to_a in NotificationService. !6753 (Jasper Maes)
- Adjust self-hosted Jira development panel integration. !6756
- Ensure that push size checks only count the size of newly-pushed files. !6767
- Fix the UI for listing system-level labels. !6805
- Rails5: fix slice in burndown fixture. !6813 (Jasper Maes)
- Rails5: fix Arel::UpdateManager in MigrateOldElasticsearchSettings migration. !6815 (Jasper Maes)
- Corrected URL for snowplow client side JS. !6899
- [Geo] Fix the Storage config parameter in Geo nodes admin page.
- Fix exporting issues to CSV when sorting by label priority is used.
- Fix handling of annotated tags when Gitaly is not in use.

### Changed (9 changes, 2 of them are from the community)

- Add related issues loading icon top margin. !6527 (George Tsiolis)
- Add security products to usage ping. !6602
- Changed copy for "Approved" state in merge request widget. !6635 (Constance Okoghenun)
- Track the Geo event log gaps in redis and handle them later. !6640
- Replace clipboard icon in Service Desk settings. !6643
- Removes "show all" on security reports and adds a button to take you to the pipeline page. !6675
- Shows license reports when there are no reports in the source branch. !6720
- Removes status text from licence reports. !6802
- Opens "view full report" links in a new window. !6806

### Performance (2 changes)

- Geo: Improve Geo Status API performance with cached counters in SiteStatistic. !6328
- Geo: Improve performance in Log Cursor gap tracking. !6754

### Added (19 changes)

- Geo: Add repository verification failures to API. !6137
- Add support for todos on epics. !6142
- Summed issue weights in board columns. !6218
- Add an API endpoint for managed licenses of a project. !6246
- Implement custom project templates. !6436
- Projects page under Admin > Geo Nodes to display detailed synchronization information. !6452
- Enables configuration of pull mirroring through API. !6485
- Adds SLI alerts to custom prometheus metrics. !6590
- Add support for milestones lists on the issue boards. !6615
- Persist Epic Roadmap timescale choice. !6637
- Add license management frontend. !6638
- Add Snowplow integration. !6642
- Add Security Dashboard to project quick links. !6652
- Show License Management at pipeline level. !6688
- Add Frontend for Instance-level project templates. !6740
- Geo - Actively try to correct verification failures on the secondary. !6759
- Add Prometheus metrics to track Geo autocorrect numbers. !6778
- Link the License Management report in the MR widget with the pipeline level one. !6800
- Allow creating assignee lists via API.

### Other (8 changes, 1 of them is from the community)

- Move merge requests EE helper methods. !6461 (George Tsiolis)
- Add additional logging for Geo Log Cursor. !6513
- Ensure no weight change system notes end with a superfluous comma. !6571
- Track registries marked as synced when repository does not found. !6694
- Removes EE specific CSS that was moved to CE. !6723
- Geo: Add rake task to resync projects where verification has failed. !6727
- updates column sizes in licence and security modals. !6808
- Geo: Log to geo.log when the Log Cursor skips an event.


## 11.1.7 (2018-09-26)

### Security (2 changes)

- Project groups approvers no longer leak private groups info.
- Protect against CSRF attacks when adding Slack app.


## 11.1.6 (2018-08-28)

- No changes.

## 11.1.5 (2018-08-27)

- No changes.
### Security (1 change)

- Prevent regular users from moving projects to different storage shards.


## 11.1.4 (2018-07-30)

- No changes.

## 11.1.3 (2018-07-27)

### Fixed (1 change)

- Resolve Environments dropdown is showing on the cluster health page. !6528


## 11.1.2 (2018-07-26)

### Security (1 change)

- Don't expose project names in EE counters.


## 11.1.1 (2018-07-23)

### Fixed (2 changes)

- Fix geo download service ImportExportDownloader unitialized constant. !6567
- Geo - Allow repository verification to be disabled on a secondary node. !6599


## 11.1.0 (2018-07-22)

### Removed (1 change)

- Drop ignored Geo repository_storage_path columns. !5468

### Fixed (19 changes, 7 of them are from the community)

- Log audit and Geo events within a project destroy transaction. !6059
- Do not pre-select previous user(s) when creating protected branches. !6112
- Group SAML settings link hidden when unlicensed. !6147
- Geo: Fix repository/wiki sync race condition with multiple updates, especially in quick succession. !6161
- [Rails5] Fix error on missed :authenticate_user callback. !6257 (@blackst0ne)
- Rails5 fix  expected: ({...}) got: (<ActionController::Parameters {...}). !6271 (Jasper Maes)
- Rails5 fix ArgumentError: wrong number of arguments (given 1, expected 2). !6272 (Jasper Maes)
- Rails5 fix NoMethodError: undefined method `join' for "":String. !6278 (Jasper Maes)
- [Rails5] fix Boards::ListsController expected the response to have status code 200 but it was 403. !6318 (Jasper Maes)
- [Rails5] fix NoMethodError: undefined method 'downcase' for Hash. !6319 (Jasper Maes)
- [Rails5] fix Projects::VulnerabilityFeedbackController didn't match the schema. !6320 (Jasper Maes)
- Fix CI/CD pipelines when repository HEAD points to an invalid branch. !6325
- Geo - Recalculates the checksum for projects up to date. !6333
- Fixes an issue with security reports footers. !6450
- Add missing sourceBranchLink prop to CI widget. !6493
- Resync project repositories on secondaries nodes when import finishes. !6529
- Adds permission checks to dismiss issue in security reports.
- Allow all but "/" chars for groups and projects paths on Jira dev panel integration.
- Fix weight system notes ending in commas.

### Changed (6 changes)

- [Geo] Invert the direction of Geo metrics acquisition. !5934
- Update read-only message banner styling for Geo secondary node. !6135
- Removes action buttons from resolved vulnerability modal. !6155
- Redesign contribution analytics graphs. !6194
- Geo - Retry checksum calculation for failures on the primary node. !6295
- Don't show 'Contribute to GitLab' link on self-hosted Enterprise Edition instances. !6297

### Performance (5 changes, 1 of them is from the community)

- Geo - Optimize query to return outdated projects that need to be reverified. !5879
- Boost Geo prune worker to run every 2 hours instead of 6. !6074
- Use tooltip component in MrWidgetSecondaryGeoNode vue component. !6078 (George Tsiolis)
- Eliminate N+1 queries in path lock checks during a push.
- Memoize the global default for push rules within the request.

### Added (13 changes, 1 of them is from the community)

- Add a new push rule to allow negative matching of commit messages. !5453 (Hannes Rosenögger)
- Pseudonymizer to safely export data for analytics. !5532
- Add filename filtering to code search with Elasticsearch. !5590
- Add API endpoint for viewing and editing board config. !5954
- Log repository check and failed count to Prometheus. !5984
- Allow repository verification concurrency to be controlled on primary and secondary. !6102
- Geo: HTTP git-lfs push (upload) and locks (verify, lock and unlock) to secondary now redirects to the primary. !6109
- Adds pod selection dropdown to pod logs screen. !6111
- Add support for autocompleting Epics and Labels within Epics. !6195
- Add project Security Dashboard. !6197
- Support GitLab subgroups in Jira development panel. !6290
- Render container scanning and dast reports in pipeline view.
- Add link to Jenkins documentation within integration and service template.

### Other (2 changes)

- Enable Geo snapshot synchronization for everyone. !6286
- Geo - Make Geo repository verification flag opt-out by default. !6369


## 11.0.6 (2018-08-27)

### Security (1 change)

- Prevent regular users from moving projects to different storage shards.


## 11.0.5 (2018-07-26)

### Security (1 change)

- Don't expose project names in EE counters.


## 11.0.4 (2018-07-17)

- No changes.

## 11.0.3 (2018-07-05)

- No changes.

## 11.0.2 (2018-06-26)

- No changes.

## 11.0.1 (2018-06-21)

- No changes.

## 11.0.0 (2018-06-22)

### Security (2 changes)

- Escape name in merge request approvers dropdown.
- Fixes include directive to not allow SSRF requests.

### Fixed (15 changes)

- Hide Lock button if File Locking feature is not available in license. !5656
- Geo - Move out the replication slots items from verification section in Geo admin screen. !5723
- Fix approvers API not accepting empty form-encoded params. !5784
- Fix error when locking/unlocking directories. !5862
- Geo: Formatting fix for geo:status rake task. !6020
- Geo: Automatically clean up stale lock files on Geo secondary. !6034
- Remove LFS object warning from import UI. !6083
- Fix Web IDE status bar if System Footer message is present.
- [Geo] Fix: Deleted project events may be skipped on the secondary when selective sync is used.
- [Geo] Fix: Unauthenticated rate limits should not block Geo requests.
- Perform gitlab-ci-token authentication always using primary.
- Geo: Gracefully handle a non-JSON response from the node status.
- Geo: Fix FDW schema check when tables and columns are not in the same order.
- Fix sticking of runner to primary if new job is scheduled.
- When last Geo::EventLog is not available, geo:status rake task fails.

### Deprecated (2 changes)

- Rename Container Scanning job and artifact. !5770
- Rename Code Quality job and artifact. !5773

### Changed (7 changes)

- Removed "(Beta)" from "Auto DevOps" messages. !5583
- Make issue weight promotion in issuable sidebar dismissable. !5601
- Remove the comma from the weight system notes. !5854
- Enrich Security Reports with more data. !5878
- Truncate Geo event log with a delay. !5897
- Add support for non-negative integer weight values in issuable sidebar.
- Improve Failed Jobs tab in the Pipeline detail page.

### Performance (5 changes, 2 of them are from the community)

- Reorder LinkToMemberAvatar vue component props values. !5692 (George Tsiolis)
- Rename merge request widget author component. !5693 (George Tsiolis)
- Geo - Fix index for outdated projects on the project_repository_states table. !5986
- Preload Group plans in EpicsFinder.
- Only process Geo::EventLog events if associated shard is queryable and healthy.

### Added (12 changes)

- Allows the review of kubernetes pod logs within GitLab. !4752
- Geo: Rake task to force housekeeping on next sync. !5623
- Add ability to have zero approvers. !5635
- Show status information stale icon in Geo admin dashboard. !5653
- Add assignee board list type. !5743
- Geo: HTTP git push to secondary now redirects to the primary. !5785
- Add presets for navigating Epic Roadmap. !5798
- Guest users will not consume seats quote in Ultimate plan. !5816
- Create system note on epic date change.
- Add License Management results in the MR widget.
- Extract EE specific files.
- Add service discovery for the DB load balancer.

### Other (4 changes, 1 of them is from the community)

- Add promotion for epics to issuable sidebar. !5601
- Remove confusing statement in the message shown for Epics list empty state when filters are applied. !5630
- Fixed illustration alignment for group milestones promotion. !5677 (Constance Okoghenun)
- Allow viewing only one when multiple issue boards is not enabled.
