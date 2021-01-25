## 12.10.14 (2020-07-06)

- No changes.

## 12.10.13 (2020-07-01)

### Security (15 changes)

- Do not show activity for users with private profiles.
- Fix stored XSS in markdown renderer.
- Upgrade swagger-ui to solve XSS issues.
- Fix group deploy token API authorizations.
- Check access when sending TODOs related to merge requests.
- Change from hybrid to JSON cookies serializer.
- Prevent XSS in group name validations.
- Disable caching for wiki attachments.
- Fix null byte error in upload path.
- Update permissions for time tracking endpoints.
- Update Kaminari gem.
- Fix note author name rendering.
- Sanitize bitbucket repo urls to mitigate XSS.
- Stored XSS on the Error Tracking page.
- Fix security issue when rendering issuable.


## 12.10.12 (2020-06-24)

### Fixed (1 change)

- Correctly count wiki pages in sidebar. !30508


## 12.10.11 (2020-06-10)

- No changes.

## 12.10.8 (2020-05-28)

### Fixed (2 changes)

- Fix Geo replication for design thumbnails. !32703
- Fix 404s downloading build artifacts. !32741


## 12.10.7 (2020-05-27)

### Security (14 changes)

- Add an extra validation to Static Site Editor payload.
- Hide EKS secret key in admin integrations settings.
- Added data integrity check before updating a deploy key.
- Display only verified emails on notifications and profile page.
- Disable caching on repo/blobs/[sha]/raw endpoint.
- Require confirmed email address for GitLab OAuth authentication.
- Kubernetes cluster details page no longer exposes Service Token.
- Fix confirming unverified emails with soft email confirmation flow enabled.
- Disallow user to control PUT request using mermaid markdown in issue description.
- Check forked project permissions before allowing fork.
- Limit memory footprint of a command that generates ZIP artifacts metadata.
- Fix file enuming using Group Import.
- Prevent XSS in the monitoring dashboard.
- Use `gsub` instead of the Ruby `%` operator to perform variable substitution in Prometheus proxy API.


## 12.10.6 (2020-05-15)

### Fixed (5 changes)

- Fix duplicate index removal on ci_pipelines.project_id. !31043
- Fix 500 on creating an invalid domains and verification. !31190
- Fix incorrect number of errors returned when querying sentry errors. !31252
- Add instance column to services table if it's missing. !31631
- Fix incorrect regex used in FileUploader#extract_dynamic_path. !32271


## 12.10.5 (2020-05-13)

### Added (1 change)

- Consider project group and group ancestors when processing CODEOWNERS entries. !31804


## 12.10.4 (2020-05-05)

### Fixed (1 change)

- Add a Project's group to list of groups when parsing for codeowner entries. !30934


## 12.10.2 (2020-04-30)

### Security (8 changes)

- Ensure MR diff exists before codeowner check.
- Apply CODEOWNERS validations to web requests.
- Prevent unauthorized access to default branch.
- Do not return private project ID without permission.
- Fix doorkeeper CVE-2020-10187.
- Change GitHub service integration token input to password.
- Return only safe urls for mirrors.
- Validate workhorse 'rewritten_fields' and properly use them during multipart uploads.


## 12.10.1 (2020-04-24)

### Fixed (5 changes)

- Fix bug creating project from git ssh. !29771
- Fix Web IDE handling of deleting newly added files. !29783
- Fix null dereference in /import status REST endpoint. !29886
- Fix Service Templates missing Active toggle. !29936
- Fix 500 error on accessing restricted levels. !30313

### Changed (1 change)

- Move Group Deploy Tokens to new Group-scoped Repository settings. !29290

### Other (1 change)

- Migration of dismissals to vulnerabilities. !29711


## 12.10.0 (2020-04-22)

### Removed (3 changes)

- Revert LDAP readonly attributes feature. !28541
- Remove deprecated /ci/lint page. !28562
- Remove open in file view link from Web IDE. !28705

### Fixed (118 changes, 26 of them are from the community)

- Return 202 for command only notes in REST API. !19624
- Run SAST using awk to pass env variables directly to docker without creating .env file. !21174 (Florian Gaultier)
- #42671: Project and group storage statistics now support values up to 8 PiB (up from 4GiB)
. !23131 (Matthias van de Meent)
- Fix 500 error on profile/chat_names for deleted projects. !24341
- Migrate the database to activate projects prometheus service integration for projects with prometheus installed on shared k8s cluster. !24684
- Fix archived corrupted projects not displaying in admin. !25171 (erickcspice)
- Fix some Web IDE bugs with empty projects. !25463
- Fix failing ci variable e2e test. !25924
- Fix new file not being created in non-ascii character folders. !26165
- Validate uniqueness of project_id and type when a new project service is created. !26308
- Fix assignee dropdown on new issue page. !26971
- Resolve Unable to expand multiple downstream pipelines. !27029
- Hide admin user actions for ghost and bot users. !27162
- Fix invalid ancestor group milestones when moving projects. !27262
- Fix right sidebar when scrollbars are always visible. !27314 (Shawn @CasualBot)
- Fix OpenAPI file detector. !27321 (Roger Meier)
- Fix managed_free_namespaces scope to only groups without a license or a free license. !27356
- Set commit status to failed if the TeamCity connection is refused. !27395
- Resolve Improve format support message in issue design. !27409
- Add tooltips with full path to file headers on file tree. !27437
- Scope WAF Statistics anomalies to environment.external_url. !27466
- Show the proper information in snippet edit form. !27479
- Fixes the repository Vue router not working with Chinese characters. !27494
- Fix smartcard config initialization. !27560
- Fix audit event that weren't being created for failed LDAP log-in tries. !27608
- Fix filtered search tokenization. !27648
- Fix processing of GrapqhQL query complexity based on used resolvers. !27652
- Update board scopes when promoting a label. !27662
- Reuse default generated snippet file name in repository. !27673
- Revert user bio back to non-italicized font to fix rendering of emojis. !27693
- Filter out Releases with missing tags. !27716
- Update detected languages for dependency scanning in no dind mode. !27723
- Fix logic for ingress can_uninstall?. !27729
- Fix dropped filter when paging groups. !27737 (Lee Tickett)
- Amend GraphQL merge requests resolver to check for project presence. !27783
- Fix bug issue template handling of markdown. !27808 (Lee Tickett)
- Update discord notifications to be a single embed and include log messages. !27812 (Sam Bingner)
- Update detected languages for sast in no dind mode. !27831
- Fix bug inviting members whose emails start with numbers. !27848 (Lee Tickett)
- Allow self monitoring project to query internal Prometheus even when "Allow local requests in webhooks and services" setting is false. !27865
- Add missing docstring to Prometheus metric. !27868
- Resolve Snippet creation failure bug. !27891
- Fix optional params for deploy token API. !27961 (Nejc Habjan)
- Use Ci::Pipeline#all_merge_requests.first as Ci::Build#merge_request. !27968
- Fix bug tracking snippet shard name. !27979
- Add `discussion_locked` to Webhook. !28018
- Fix invalid class option for ionice. !28023
- Improve SAST NO_DIND file detection with proper boundary conditions. !28036
- Detect skipped specs in JUnit reports and set TestCase status. !28053
- Allow 0 for pages size limit setting in admin settings. !28086
- Fix wrong colors displayed in charts. !28095
- Fix incorrect content returned on empty dotfile. !28144
- Include LDAP UID attribute in default attributes for all LDAP lookups. !28148
- Fix deploy token API to properly delete all associated deploy token records. !28156
- Fix Gitlab::Auth to handle orphaned oauth tokens. !28159
- Protect sidekiq admin UI with admin mode. !28164 (Diego Louzán)
- Prevent overriding the username when creating a Deploy Token via the API. !28175 (Ayoub Mrini)
- Resolve Snippet actions with binary data. !28191
- Make all HTTPS cookies set SameSite to none. !28205
- Don't send 'accept-encoding' in HttpIO requests. !28239
- Gracefully handle missing latest CI pipeline. !28263
- Fix error removing secondary email. !28267 (Lee Tickett)
- Fix name of approvals column in merge requests. !28274 (Steffen Köhler)
- Add management_project_id to group and project cluster creation, clarifies docs. !28289
- Check first if feature flag version_snippet is enabled. !28352
- Fix single stat panel percentile format support. !28365
- Use CTE optimization for searching board issues. !28430
- Fix missing synthetic milestone change notes for disabled milestone change event tracking feature flag. !28440
- Fix Releases page for Guest users of private projects. !28447
- Prevent ProjectUpdateRepositoryStorageWorker from moving to same filesystem. !28469
- Return error message for create_merge_request. !28482
- Include MR times in Milestone time overview. !28519 (Bob van de Vijver)
- Fix daily report result to use average of coverage values if there are multiple builds for a given group name. !28556
- Token creation uses HTTP status CREATED. !28587
- Allow award emoji same name & user duplicates when Importing. !28588
- Fix pagination in Merge Request GraphQL api. !28667 (briankabiro)
- Remove duplicate spec in web hook service spec. !28669 (Rajendra Kadam)
- Fix GraphQL SnippetType repo urls. !28673
- Add missing ON DELETE FK constraints referencing users table. !28720
- Update duplicate specs in notification service spec. !28742 (Rajendra Kadam)
- Fix styling of MR dropdown in Web IDE. !28746
- Better error message when importing a Github project and Github API rate limit is exceeded. !28785
- Prevent false positives in Ci::Pipeline#all_merge_requests. !28800
- Enable toggle all discussions button for logged out users. !28809 (Diego Louzán)
- Fix display of PyCharm generated Jupyter notebooks. !28810 (Jan Beckmann)
- Resolve Snippet update error with version flag disabled. !28815
- Show multimetric embeds on a single chart. !28841
- Fix race condition updating snippet without repository. !28851
- Normalize signature mime types when filtering attachments in emails. !28865 (Diego Louzán)
- Add autostop check to folder table. !28937
- Fix 500 error on create release API when providing an invalid tag_name. !28969 (Sashi Kumar)
- Fix missing group icons on profile page when screen < 576px. !28973
- Stringify Sidekiq job args in exception logs. !28996
- Ensure members are always added on Project Import when importing as admin. !29046
- Elasticsearch recommendation alert does not appears while screen is loaded. !29097
- Prevent wrong environment being used when processing Prometheus alert. !29119
- Fix Slack slash commands using relative URL. !29160
- Exclude 'trial_ends_on', 'shared_runners_minutes_limit' & 'extra_shared_runners_minutes_limit' from list of exported Group attributes. !29259
- Group level container registry show subgroups repos. !29263
- Move prepend to last line in finders files. !29274 (Rajendra Kadam)
- Remove 'error' from diff note error message. !29281
- Migrate legacy uploads out of deprecated paths. !29295
- Move prepend to last line in commit status presenter. !29328 (Rajendra Kadam)
- Move prepend to last line in app serializers. !29332 (Rajendra Kadam)
- Move prepend to last line in app workers and uploaders. !29379 (Rajendra Kadam)
- fix: Publish toolbar dissappears when submitting empty content. !29410
- Replace deprecated GlLoadingIcon sizes. !29417
- fix display head and base in version dropdowns. !29433
- Fix Web IDE not showing diff when opening commit tab. !29439
- Use music icon for files with .ogg extension. !29514
- Fix dashboard processing error which prevented dashboards with unknown attributes inside panels from being displayed. !29517
- Fix Deploy Token creation when no scope selected. !29614
- Update auto-build-image to v0.2.2 with fixes for docker caching. !29730
- Fix resolve WIP clearing merge request area. !29757
- Enable the Add metric button for CE users. !29769
- Fix Error 500 when inviting user to a few projects. !29778
- Fixed whitespace toggle not showing the correct diff.
- Fixed upload file creating a file in the wrong directory.

### Deprecated (1 change)

- Deprecate 'token' attribute from Runners API. !29481

### Changed (62 changes, 7 of them are from the community)

- Only enable searching of projects by full path / name on certain dropdowns. !21910
- Support wiki events in activity streams. !23869
- Fix for issue 26426: Details of runners of nested groups of an owned group are now available for users with enough permissions. !24169 (nachootal@gmail.com)
- Rename "Project Services" to "Integrations" in frontend and docs. !26244
- Support multiple Evidences for a Release. !26509
- Move some global routes to - scope. !27106
- Only display mirrored URL to users who can manage Repository settings. !27166
- Disable lookup of other ActiveSessions to determine admin mode status. !27318 (Diego Louzán)
- Extract X509::Signature from X509::Commit. !27327 (Roger Meier)
- Show user statistics in admin area also in CE, and use daily generated data for these statistics. !27345
- Update aws-ecs image location in CI template. !27382
- Update More Pages button on Wiki Page. !27499
- Update ApplicationLimits to prefer defaults. !27574
- Allow external diff files to be removed. !27602
- Add atomic and cleanup-on-fail parameters for Helm. !27721
- Change the url when the timeslider changes. !27726
- Add user_details.bio column and migrate data from users.bio. !27773
- WAF settings will be read-only if there is a new version of ingress available. !27845
- Add an helper to check if a notification_event is enabled. !27880 (Jacopo Beschi @jacopo-beschi)
- Ensure freshness of settings with snippet creation. !27897
- Update copies in Admin Panel > Repository Storage section. !27986
- Add event tracking to Container regstry quickstart. !27990
- Render snippet repository blobs. !28085
- Accept `author_username` as a param in Merge Requests API. !28100
- Use rich icons for thw rows on the file tree. !28112
- Renamed Contribution Charts as Repository Analytics. !28162
- Move Alerting feature to Core. !28196
- Add file-based pipeline conditions to default Auto DevOps CI template. !28242
- Make pipeline info in chat notifications concise. !28284
- Use different approval icon if current user approved. !28290 (Steffen Köhler)
- Remove repeated examples in user model specs. !28450 (Rajendra Kadam)
- Show only active environments in monitoring dropdown. !28456
- Enable container expiration policies by default for new projects. !28480
- Show snippet error update to the user. !28516
- Move 'Additional Metrics' feature to GitLab Core. !28527
- Add ability to search by environment state in environments GraphQL API. !28567
- Add correlation_id to project_mirror_data, expose in /import API endpoints. !28662
- Add status column to container_registry. !28682
- Cleanup the descriptions of some fields of GraphQL ProjectType. !28735
- Add Project template for Static Site Editor / Middleman. !28758
- Remove duplicate show spec in admin routing. !28790 (Rajendra Kadam)
- Add Fluentd model for cluster apps. !28846
- Add grab cursor for operations dashboard cards. !28868
- Update copy when snippet git feature disabled. !28913
- Expose relations that failed to import in /import endpoints. !28915
- Update informational text on Edit Release page. !28938
- Add support for dot (.) in variables masking. !29022
- Update Auto DevOps docker version to 19.03.8. !29081
- Make search redaction more robust. !29166
- Enable async delete in container repository list. !29175
- Make manual prometheus configuration section always editable. !29209
- Adjust label title applied to issues on import from Jira. !29246
- Track statistics per project for jira imported issues. !29406
- Display local timezone in log explorer. !29409
- Allow to retry submitting changes when an error occurs. !29434
- Define dashboard dropdowns layout in flex to improve support smaller screens. !29477
- Update auto-deploy-image to v0.13.0 for deploy job, enabling more granular control over service.enabled. !29524
- Do not display branch link in saved changes message UI. !29611
- Redesign Jira issue import UI. !29671
- Add support for /file_hooks directory. !29675
- Sort the project dropdown by star count when moving issues. !29766
- Increase the timing of polling for the merge request widget.

### Performance (45 changes)

- Limits issues displayed on milestones. !23102
- Optimize suggestions counters. !26443
- Prefetch DNS for asset host. !26868
- Move bots functionality to user_type column. !26981
- Optimize projects_service_active queries performance in usage data. !27093
- Optimize projects_mirrored_with_pipelines_enabled query performance in usage data. !27110
- Optimize ldap keys counters query performance in usage data. !27309
- Enable Workhorse upload acceleration for Project Import uploads via UI. !27332
- Cache ES enabled namespaces and projects. !27348
- Optimize template_repositories query by using batch counting. !27352
- Reduce SQL queries when rendering webhook settings. !27359
- Reduce number of SQL queries for service templates. !27396
- Improve Advanced global search performance by using routing. !27398
- Improve performance of the container repository cleanup tags service. !27441
- Optimize usage ping queries by using batch counting. !27455
- Fix redundant query execution when loading board issues. !27505
- Optimize projects_enforcing_code_owner_approval counter query performance for usage ping. !27526
- Optimize projects_reporting_ci_cd_back_to_github query performance for usage data. !27533
- Optimize service desk enabled projects counter. !27589
- Improve pagination in discussions API. !27697
- Improve API response for archived project searchs. !27717
- Optimize ci builds counters in usage data. !27770
- Enable streaming serializer feature flag by default. !27813
- Harden jira usage data. !27973
- Create merge request pipelines in background jobs. !28024
- Optimize ci builds non distinct counters in usage data. !28027
- Remove feature flag 'export_fast_serialize' and 'export_fast_serialize_with_raw_json'. !28037
- Improve API response for descending internal project searches. !28038
- Make Rails.cache and Gitlab::Redis::Cache share the same Redis connection pool. !28074
- Introduce rate limit for creating issues via web UI. !28129
- Introduce rate limit for creating issues via API. !28130
- Remove unnecessary index index_ci_builds_on_name_for_security_reports_values. !28224
- Disallow distinct count for regular batch count. !28518
- Resolve an N+1 in merge request CI variables. !28688
- Use faster streaming serializer for project exports. !28925
- Add index for created_at of resource_milestone_events. !28929
- Optimize issues with embedded grafana charts usage counter. !28936
- Avoid scheduling duplicate sidekiq jobs. !29116
- Optimize projects with repositories enabled usage data. !29117
- Use diff-stats for calculating raw diffs modified paths. !29134
- Optimize protected branches usage data. !29148
- Refresh only existing MRs on push. !29420
- Reduce SQL requests number for CreateCommitSignatureWorker. !29479
- Remove redundant index from projects table. !29507
- Add index on users.unlock_token. !276298

### Added (140 changes, 33 of them are from the community)

- New package list is enabled which includes filtering by type. !18860
- Create a rake task to cleanup unused LFS files. !21747
- Support Asciidoc docname attribute. !22313 (Jouke Witteveen)
- Adds features to delete stopped environments. !22629
- Highlight line which includes search term is code search results. !22914 (Alex Terekhov (terales))
- Allow embedded metrics charts to be hidden. !23929
- Add toggle all discussions button to MRs. !24670 (Martin Hobert & Diego Louzán)
- Store daily code coverages into ci_daily_report_results table. !24695
- Add cluster management project template. !25318
- Add limit metric to lists. !25532
- Add support for Okta as a SCIM provider. !25649
- Add grape custom validator for git reference params. !26102 (Rajendra Kadam)
- Add healthy column to clusters_applications_prometheus table. !26168
- Add API endpoint to list runners for a group. !26328
- Add unlock_membership_to_ldap boolean to Groups. !26474
- Adds wiki metadata models. !26529
- Create model to store Terraform state files. !26619
- Improve logs dropdown with more clear labels. !26635
- Add all pods view to logs explorer. !26883
- Add first_contribution to single merge request API. !26926
- Populate user_highest_roles table. !27127
- Add option for switching between blocking and logging for WAF. !27133
- Add bar chart support to monitoring dashboard. !27155
- Start merge request for custom dashboard if new branch is provided. !27189
- Update user's highest role to keep the users statistics up to date. !27231
- Make "Value Stream" the default page that appears when clicking the project-level "Analytics" sidebar item. !27279 (Gilang Gumilar)
- Add metric to derive new users count. !27351
- Display cluster type in cluster info page. !27366
- Improve logs filters on mobile, simplify kubernetes API logs filters. !27484
- Adds branch information to the package details title section. !27488
- Add forking_access_level to projects API. !27514 (Mathieu Parent)
- Add a DB column to track external issue and epic ids when importing from external sources. !27522
- Added Edit Title shared component. !27582
- Add metrics dashboard annotation model, relation, policy, create and delete services. To provide interface for create and delete operations. !27583
- Adds filter by name to the packages list. !27586
- Allow querying of Jira imports and their status via GraphQL. !27587
- Update Gitaly to 12.9.0-rc5. !27631
- Add filtered search for elastic search in logs. !27654
- Add cost factor fields to ci runners. !27666
- Add auto_ssl_failed to pages_domains. !27671
- Allow to start Jira import through graphql mutation. !27684
- Add terraform report to merge request widget. !27700
- Read metadata from Wiki front-matter. !27706
- Support custom graceful timeout for Sidekiq Cluster processes. !27710
- Show storage size on project page. !27724 (Roger Meier)
- Upload a design by copy/pasting the file into the Design Tab. !27776
- Update Active checkbox component to use toggle. !27778
- Add namespace_storage_size_limit to application settings. !27786
- Add issues to graphQL group endpoint. !27789
- Enable container registry at the group level. !27814
- Expose created_at property in Groups API. !27824
- Add an endpoint to allow group admin users to purge the dependency proxy for a group. !27843
- Filter health endpoint metrics. !27847
- Add support for system note metadata in project Import/Export. !27853 (Melvin Vermeeren)
- Add daily job to create users statistics. !27883
- Add DS_REMEDIATE env var to dependency scanning template. !27947
- Add Swift Dockerfile to GitLab templates. !28035
- Generate JWT and provide it to CI jobs for integration with other systems. !28063
- Update user's highest role to keep the users statistics up to date. !28087
- Add jira_imports table to track current jira import progress as well as historical imports data. !28108
- Add initial support for Cloud Native Buildpacks in Auto DevOps builds. !28165
- Add app server type to usage ping. !28189
- Add last_activity_before and last_activity_after filter to /api/projects endpoint. !28221 (Roger Meier)
- Expose basic project services attributes through GraphQL. !28234
- Add environment-state flag to metrics data. !28237
- Allow defining of metric step in dashboard yml. !28247
- Separate validators into own class files. !28266 (Rajendra Kadam)
- Refactor push rules and add push_rule_id columns in project settings and application settings. !28286
- Added support for single-token deletion via option/ctrl-backspace or search-filter clearing via command-backspace in filtered search. !28295 (James Becker)
- Enable log explorer to use the full height of the screen. !28312
- Automatically assign id to each panel within dashboard to support panel scoped annotations. !28341
- Add Praefect rake task to print out replica checksums. !28369
- Add rake task to update x509 signatures. !28406 (Roger Meier)
- Add application setting to enable container expiration and retention policies on pre 12.8 projects. !28479
- Add Prometheus alerts automatically after Prometheus Service was created. !28503
- Add ability to filter commits by author. !28509
- Add usage data metrics for instance level clusters and clusters with management projects. !28510
- Add slash command support for merge train. !28532
- Add metrics dashboard annotations to GraphQL API. !28550
- Refactor duplicate specs in wiki page specs. !28551 (Rajendra Kadam)
- Refactor duplicate member specs. !28574 (Rajendra Kadam)
- Remove design management as a license feature. !28589
- Add api endpoint to get x509 signature. !28590 (Roger Meier)
- Refactored Snippet edit form to Vue. !28600
- Add support for database-independent embedded metric charts. !28618
- Fix issuable duplicate spec. !28632 (Rajendra Kadam)
- Fix build duplicate spec. !28633 (Rajendra Kadam)
- Remove duplicate specs in ability model. !28644 (Rajendra Kadam)
- Remove duplicate specs in update service spec. !28650 (Rajendra Kadam)
- Add added_lines and removed_lines columns to merge_request_metrics table. !28658
- Remove duplicate specs in pipeline message spec. !28664 (Rajendra Kadam)
- Implement Terraform State API with locking. !28692
- Move export issues feature to core. !28703
- Add status endpoint to Pages Internal API. !28743
- Enable last user activity logging on the REST API. !28755
- Refresh metrics dashboard data without reloading the page. !28756
- Update duplicate specs in update large table spec. !28787 (Rajendra Kadam)
- Fix duplicate spec in factory relation spec. !28794 (Rajendra Kadam)
- Remove duplicate spec from changelog spec. !28801 (Rajendra Kadam)
- Remove duplicate spec from closing issue spec. !28803 (Rajendra Kadam)
- Allow Release links to be edited on the Edit Release page. !28816
- Create operations_user_lists table. !28822
- Added the clone button for Snippet view. !28840
- Add Fluentd table for cluster apps. !28844
- Fix duplicate spec from user helper spec. !28854 (Rajendra Kadam)
- Add missing spec for gitlab schema. !28855 (Rajendra Kadam)
- Fix duplciate spec in merge requests. !28856 (Rajendra Kadam)
- Fix duplicate spec in environment finder. !28857 (Rajendra Kadam)
- Fix duplicate spec in template dropdown spec. !28858 (Rajendra Kadam)
- Fix duplicate spec in user post diff notes. !28859 (Rajendra Kadam)
- Fix duplicate spec in filter issues. !28860 (Rajendra Kadam)
- Remove `ci_dag_support` feature flag. !28863 (Lee Tickett)
- Validate dependency on job generating a CI config when using dynamic child pipelines. !28901
- Add read_api scope to personal access tokens for granting read only API access. !28944
- Add a new default format(engineering notation) for yAxis labels in monitor charts. !28953
- Add write_registry scope to deploy tokens for container registry push access. !28958
- Add Nginx error percentage metric. !28983
- Provide configuration options for Static Site Editor. !29058
- Remove blobs_fetch_in_batches feature flag. !29069
- API endpoint to create annotations for environments dashboard. !29089
- Add graphQL interface to fetch metrics dashboard. !29112
- Add typed AWS environment variables for access keys & region. !29124
- Add line range to diff note position. !29135
- Add push rules association for groups. !29144
- Gather historical pod list from Elasticsearch. !29168
- Save changes in Static Site Editor using REST GitLab API. !29286
- Add temporary empty message when no result is found. !29306
- Add API endpoint to get users without projects. !29347
- Add status page url field to DB and setting model. !29357
- Add metrics_dashboard_access_level to project features. !29371
- Add a database column to enable or disable group owners from changing the default branch protection setting of a group. !29397
- Allow sorting of issue and MR discussions. !29492
- Update UI for project and group settings CI variables. !29584
- Add GRADLE_CLI_OPTS and SBT_CLI_OPTS env vars to dependency scanning orchestrator. !29595
- Add name_regex_keep to container_expiration_policies. !29618
- Adds Knative and Fluentd as CI/CD managed applications. !29637
- Add jira issues import feature.
- Add wildcard case in documentation for artifacts. (Fábio Matavelli)
- Add namespace storage size limit setting.
- Add placeholders to broadcast message notifications.

### Other (48 changes, 16 of them are from the community)

- Convert schema to plain SQL using structure.sql. !22808
- Provide link to a survey for Knative users. !23025
- Complete the migration of Job Artifact to Security Scan. !24244
- Migrate .fa-spinner to .spinner for app/views/shared/notes. !25028 (nuwe1)
- Migrate .fa-spinner to .spinner for app/views/ci/variables. !25030 (nuwe1)
- Migrate .fa-spinner to .spinner for ee/app/views/projects/settings. !25038 (nuwe1)
- Migrate .fa-spinner to .spinner for app/views/projects/mirrors. !25041 (nuwe1)
- Migrate .fa-spinner to .spinner for app/views/projects/network. !25050 (nuwe1)
- Migrate .fa-spinner to .spinner for app/views/groups. !25053 (nuwe1)
- Replace underscore with lodash for ./app/assets/javascripts/vue_shared. !25108 (Tobias Spagert)
- Remove health_status column from epics. !26302
- Show object access warning when disabling repo LFS. !26696
- Update icons in Sentry Error Tracking list for ignored/resolved errors. !27125
- Use Ruby 2.7 in specs to remove Ruby 2.1/2.2/2.3. !27269 (Takuya Noguchi)
- Fill user_type for ghost users. !27387
- Add Bitbucket Importer metrics. !27524
- Consume remaining LinkLFsObjectsProjects jobs. !27558
- Update GitLab Runner Helm Chart to 0.15.0. !27670
- Log Redis call count and duration to log files. !27735
- Use id instead of cve where possible when parsing remediations. !27815
- Log member additions when importing Project/Group. !27930
- Change project_export_worker urgency to throttled. !27941
- Add missing track_exception() call to Ci::CreateJobArtifactsService. !27954
- Add possibility to conigure additional rails hosts with env variable. !28133
- Remove new issue tooltip. !28261 (Victor Wu)
- Improve message when promoting project labels. !28265
- Change the link to chart copy text. !28371
- Conditional mocking of admin mode in specs by directory. !28420 (Diego Louzán)
- Align color and font-weight styles of heading elements and their typography classes. !28422
- Fix merge request thread’s icon buttons color. !28465
- Updated spinner next to forking message. !28506 (Victor Wu)
- Replaced old-style buttons with the new ones on Snippet view. !28614
- Change redo for retry icon in metrics dashboard. !28670
- Remove User's association max_access_level_membership. !28757
- Reduce urgency of EmailsOnPushWorker. !28783
- Use concern instead of service to update highest role. !28791
- Normalize error message between Gitea and Fogbugz importers. !28802
- Fix keyboard shortcut to navigate to your groups. !28873 (Victor Wu)
- Fix keyboard shortcut to navigate to dashboard activity. !28985 (Victor Wu)
- Remove unused index for vulnerability severity levels. !29023
- Update query labels dynamically for embedded charts. !29034
- Refactor projects/:id/packages API to supply only necessary params to PackagesFinder. !29052 (Sashi Kumar)
- Implement showing CI bridge error messages. !29123
- Update GitLab Shell to v12.1.0. !29167
- Update GitLab Elasticsearch Indexer. !29256
- Add Gitlab User-Agent to ContainerRegistry::Client. !29294 (Sashi Kumar)
- Improve error message in DAST CI template. !29388
- Remove store_mentions! in Snippets::CreateService. !29581 (Sashi Kumar)


## 12.9.10 (2020-06-10)

- No changes.

## 12.9.8 (2020-05-27)

### Security (13 changes)

- Hide EKS secret key in admin integrations settings.
- Added data integrity check before updating a deploy key.
- Display only verified emails on notifications and profile page.
- Disable caching on repo/blobs/[sha]/raw endpoint.
- Require confirmed email address for GitLab OAuth authentication.
- Kubernetes cluster details page no longer exposes Service Token.
- Fix confirming unverified emails with soft email confirmation flow enabled.
- Disallow user to control PUT request using mermaid markdown in issue description.
- Check forked project permissions before allowing fork.
- Limit memory footprint of a command that generates ZIP artifacts metadata.
- Fix file enuming using Group Import.
- Prevent XSS in the monitoring dashboard.
- Use `gsub` instead of the Ruby `%` operator to perform variable substitution in Prometheus proxy API.


## 12.9.6 (2020-05-05)

### Fixed (1 change)

- Add a Project's group to list of groups when parsing for codeowner entries. !30934


## 12.9.5 (2020-04-30)

### Security (9 changes)

- Ensure MR diff exists before codeowner check.
- Apply CODEOWNERS validations to web requests.
- Prevent unauthorized access to default branch.
- Do not return private project ID without permission.
- Fix doorkeeper CVE-2020-10187.
- Prevent ES credentials leak.
- Change GitHub service integration token input to password.
- Return only safe urls for mirrors.
- Validate workhorse 'rewritten_fields' and properly use them during multipart uploads.


## 12.9.4 (2020-04-16)

- No changes.
### Fixed (5 changes, 1 of them is from the community)

- Fix not working File upload from Project overview page. !26828 (Gilang Gumilar)
- Fix storage rollback regression caused by previous refactor. !28496
- Fix incorrect regex used in FileUploader#extract_dynamic_path. !28683
- Fully qualify id columns for keyset pagination (Projects API). !29026
- Fix Slack notifications when upgrading from old GitLab versions. !29111


## 12.9.3 (2020-04-14)

### Security (3 changes)

- Refresh ProjectAuthorization during Group deletion.
- Prevent filename bypass on artifact upload.
- Update rack and related gems to 2.0.9 to fix security issue.


## 12.9.2 (2020-03-31)

### Fixed (5 changes)

- Ensure import by URL works after a failed import. !27546
- Fix issue/MR state not being preserved when importing a project using Project Import/Export. !27816
- Leave upload Content-Type unchaged. !27864
- Disable archive rate limit by default. !28264
- Fix rake gitlab:setup failing on new installs. !28270

### Changed (1 change)

- Rename feature on the FE and locale.

### Performance (1 change)

- Index issues on sent_notifications table. !27034


## 12.9.1 (2020-03-26)

### Security (16 changes)

- Add permission check for pipeline status of MR.
- Ignore empty remote_id params from Workhorse accelerated uploads.
- External user can not create personal snippet through API.
- Prevent malicious entry for group name.
- Restrict mirroring changes to admins only when mirroring is disabled.
- Reject all container registry requests from blocked users.
- Deny localhost requests on fogbugz importer.
- Redact notes in moved confidential issues.
- Fix UploadRewriter Path Traversal vulnerability.
- Block hotlinking to repository archives.
- Restrict access to project pipeline metrics reports.
- vulnerability_feedback records should be restricted to a dev role and above.
- Exclude Carrierwave remote URL methods from import.
- Update Nokogiri to fix CVE-2020-7595.
- Prevent updating trigger by other maintainers.
- Fix XSS vulnerability in `admin/email` "Recipient Group" dropdown.

### Fixed (1 change)

- Fix updating the authorized_keys file. !27798


## 12.9.0 (2020-03-22)

### Security (1 change)

- Update Puma to 4.3.3. !27232

### Removed (3 changes)

- Remove staging from commit workflow in the Web IDE. !26151
- Remove and deprecate snippet content search. !26359
- Remove "Analytics" suffix from the sidebar menu items. !26415

### Fixed (117 changes, 19 of them are from the community)

- Set all NULL `lock_version` values to 0 for issuables. !18418
- Support finding namespace by ID or path on fork API. !20603 (leoleoasd)
- Fixes caret position after pasting an image 15011. !21382 (Carolina Carvalhosa)
- Use of sha instead of ref when creating a new ref on deployment creation. !23170
- Fix logic to determine project export state and add regeneration_in_progress state. !23664
- Create child pipelines dynamically using content from artifact as CI configuration. !23790
- Handle Gitaly failure when fetching license. !24310
- Fix error details layout and alignment for mobile view. !24390
- Added the multiSelect option to stop event propagation when clicking on the dropdown. !24611 (Gwen_)
- Activate Prometheus integration service for newly created project if this project has access to shared Prometheus application. !24676
- Fix Jump to next unresolved thread. !24728
- Require a logged in user to accept or decline a term. !24771
- Fix quick actions executing in multiline inline code when placed on its own line. !24933 (Pavlo Dudchenko)
- Fix timezones for popovers. !24942
- Prevent "Select project to create merge request" button from overflowing out of the viewport on mobile. !25195
- Add validation for updated_at parameter in update Issue API. !25201 (Filip Stybel)
- Elasticsearch: when index is absent warn users and disable index button. !25254
- Fix pipeline details page initialisation on invalid pipeline. !25302 (Fabio Huser)
- Fix bug with sidebar not expanding at certain resolutions. !25313 (Lee Tickett)
- Rescue elasticsearch server error in pod logs. !25367
- Fix project setting approval input in non-sequential order. !25391
- Add responsivity to cluster environments table. !25501
- Board issue due dates appear grey for closed past-due issues. !25507 (rachelfox)
- Fix self monitoring project link. !25516
- Don't track MR deployment multiple times. !25537
- Fix an issue with Group Import members with Owner access level being imported with Maintainer access level. Owner access level is now preserved. !25595
- Allow 0 to be set for pages maximum size per project/group to indicate unlimited size. !25677
- Fix variable passthrough in the SAST CI/CD template when using DinD. !25697
- Drop bridge if downstream pipeline has errors. !25706
- Clean stale background migration jobs. !25707
- Inject CSP values when repository static objects external caching is enabled. !25711
- Fix bug deleting internal project snippets by project maintainer. !25792
- Fix Insights displaying JSON on back navigation. !25801
- Don't show issue as blocked on the issue board if blocking issue is closed. !25817
- Return 503 to the Runner when the object storage is unavailable. !25822
- Ensure temp export data is removed if Group/Project export failed. !25828
- Fix Kubernetes namespace resolution for new DeploymentCluster records. !25853
- Fix links to exposed artifacts in MRs from forks. !25868 (Daniel Stone)
- Keep needs association on the retried build. !25888
- Remove unreachable link from embded dashboard context menu. !25892
- Fix issue importer so it matches issue export format. !25896
- Fix snippet blob viewers for rich and plain data. !25945
- Fix White syntax highlighting theme in Monaco to closely match the Pygments theme. !25966
- Markup tips for Markdown shown while editing wiki pages in other formats. !25974
- Fix code search pagination on a custom branch. !25984
- Fix Snippet content incorrectly caching. !25985
- Fix 500 error caused by Kubernetes logs not being encoded in UTF-8. !25999
- Fix "Add an epic" form. !26003
- Ensure weight changes no longer render duplicate system notes. !26014
- Geo: Show secondary-only setting on only on secondaries. !26029
- Fixes project import failures when user is not part of any groups. !26038
- Fix ImportFailure when restore ci_pipelines:external_pull_request relation. !26041
- Code Review Analytics: Fix review time display. !26057
- Allow to fork to the same namespace and different path via API call. !26062
- Change back internal api return code. !26063
- Create approval todos on update. !26077
- Fix issues missing on epic's page after project import. !26099
- Fix scoped labels rendering in To-Do List. !26146
- Fix 500 Error when using Gitea Importer. !26166
- Fix dev vulnerabilities seeder. !26169
- Use uncached SQL queries for Geo long-running workers. !26187
- Fix infinite spinner on error detail page. !26188
- Generate proper link for Pipeline tab. !26193
- Issue Analytics: Fix svg illustration path for empty state. !26219
- Fix dashboards dropdown if custom dashboard is broken. !26228
- Refresh widget after canceling "Merge When Pipeline Succeeds". !26232
- Fix package file finder for conan packages with a conan_package_reference filter. !26240
- Fixed bug where processing NuGet packages are returned from the Packages API. !26270
- Fix bug committing snippet content when creating the snippet. !26287
- Fix error messages for dashboard clonning process. !26290
- Fix saving preferences with unrelated changes when gitaly timeouts became invalid. !26292
- Allow creating default branch in snippet repositories. !26294
- Container expiration policy settings hide form on API error. !26303
- Prevent unauthorized users to lock an issue from the collapsed sidebar. !26324 (Gilang Gumilar)
- Mark existing LFS object for upload for forks. !26344
- Fix scoped labels rendering in emails. !26347
- Fix issues with non-ASCII plain text files being incorrectly uploaded as binary in the Web IDE. !26360
- Polyfill fetch for Internet Explorer 11. !26366
- Fix avg_cycle_analytics uncaught error and optimize query. !26381
- Fix reversed pipeline order on Project Import. !26390
- Display GitLab issues created via Sentry global integration. !26418
- Fix MergeToRefService raises Gitlab::Git::CommandError. !26465
- Render special references for releases. !26554
- Show git error message updating snippet. !26570
- Support Rails 6 `insert_all!`. !26595
- Fix evidence SHA clipboard hover text. !26608 (Gilang Gumilar)
- Prevent editing weight to scroll to the top. !26613 (Gilang Gumilar)
- Fix spinner in Create MR dropdown. !26679
- Added a padding-right to items in subgroup list. !26791
- Prevent default overwrite for theme and color ID in user API. !26792 (Fabio Huser)
- Fix user registration when smartcard authentication is enabled. !26800
- Correctly send notification on pipeline retry. !26803 (Jacopo Beschi @jacopo-beschi)
- Default to generating blob links for missing paths. !26817
- Fix Mermaid flowchart width. !26848 (julien MILLAU)
- Ensure valid mount point is used by attachments on notes. !26849
- Validate that users selects at least two subnets in EKS Form. !26936
- Fix embeds so that a chart appears only once. !26997
- Fix capybara screenshots path name for rails configuration. !27002
- Fix access to logs when multiple pods exist. !27008
- Fix installation of GitLab-managed crossplane chart. !27040
- Fix bug displaying snippet update error. !27082
- Fix WikiPage#title_changed for paths with spaces. !27087
- Fix backend validation of numeric emoji names. !27101
- Reorder exported relations by primary_key when using Project Export. !27117
- Ensure freshness of settings with project creation. !27156
- Fix bug setting hook env with personal snippets. !27235
- Fix Conan package download_urls and snapshot to return files based on requested conan_package_reference. !27250
- Fixes stop_review job upon expired artifacts from previous stages. !27258 (Jack Lei)
- Fix duplicate labels when moving projects within the same ancestor group. !27261
- Fix project moved message after git operation. !27341
- Fix submodule links to gist.github.com. !27346
- Fix remove special chars from snippet url_to_repo. !27390
- Validate actor against CODEOWNERS entries.
- Fix: tableflip quick action is interpreted even if inside code block. (Pavlo Dudchenko)
- Fix an error with concat method.
- Improved selection of multiple cards. (Gwen_)
- Resolves the disappearance of a ticket when it was moved from the closed list. (Gwen_)

### Deprecated (1 change)

- Remove state column from issues and merge_requests. !25561

### Changed (81 changes, 18 of them are from the community)

- Remove kubernetes workaround in container scanning. !21188
- New styles for scoped labels. !21377
- Update labels in Vue with GlLabel component. !21465
- Update Web IDE clientside preview bundler to use GitLab managed server. !21520
- Allow default time window on grafana embeds. !21884
- Default to first valid panel in unspecified Grafana embeds. !21932
- Correctly style scoped labels in sidebar after updating. !22071
- Add id and image_v432x230 columns to design_management_designs_versions. !22860
- Decouple Webhooks from Integrations within Project > Settings. !23136
- Sort closed issues on issue boards using time of closing. !23442 (briankabiro)
- Differentiate between errors and failures in xUnit result. !23476
- Add 'shard' label for 'job_queue_duration_seconds' metric. !23536
- Migrate mentions for design notes to design_user_mentions DB table. !23704
- Migrate mentions for commit notes to commit_user_mentions DB table. !23859
- Update files when snippet is updated. !23993
- Move issues routes under /-/ scope. !24791
- Migrated the sidebar label select dropdown title component spinner to utilize GlLoadingIcon. !24914 (Raihan Kabir)
- Migrated from .fa-spinner to .spinner in 'app/assets/javascripts/notes.js. !24916 (Raihan Kabir (gitlab/rk4bir))
- Migrated from .fa-spinner to .spinner in app/assets/javascripts/create_merge_request_dropdown.js. !24917 (Raihan Kabir (gitlab/rk4bir))
- Migrated from .fa-spinner to .spinner in app/assets/javascripts/sidebar/components/assignees/assignee_title.vue. !24919 (rk4bir)
- Replace underscore with lodash for ./app/assets/javascripts/deploy_keys. !24965 (Jacopo Beschi @jacopo-beschi)
- Replace underscore with lodash for ./app/assets/javascripts/badges. !24966 (Jacopo Beschi @jacopo-beschi)
- Add commits limit text at graphs page. !24990
- Migrated from .fa-spinner to .spinner in app/assets/javascripts/blob/template_selector.js. !25045 (Raihan Kabir (gitlab/rk4bir))
- Update iOS (Swift) project template logo. !25049
- Sessionless and API endpoints bypass session for admin mode. !25056 (Diego Louzán)
- New loading spinner for attachemnt uploads via discussion boxes. !25057 (Philip Jonas)
- Hide the private commit email in Notification email list. !25099 (briankabiro)
- Replace underscore with lodash in /app/assets/javascripts/blob/. !25113 (rkpattnaik780)
- Allow access to /version API endpoint with read_user scope. !25211
- Use only the first line of the commit message on chat service notification. !25224 (Takuya Noguchi)
- Include invalid directories in wiki title message. !25376
- Replace avatar and favicon upload type consistency validation with content whitelist validation. !25401
- Showing only "Next" button for snippet explore page. !25404
- Moved Deploy Keys from Repository to CI/CD settings. !25444
- Move pod logs to core. !25455
- Improve error messages of failed migrations. !25457
- Hides the "Allowed to fail" tag on jobs that are successful. !25458
- Disable CSRF protection on logout endpoint. !25521 (Diego Louzán)
- Ensure all errors are logged in Group Import. !25619
- Tweak wiki page title handling. !25647
- Add refresh dashboard button. !25716
- Disable draggable behavior on the epic tree chevron (collapse/expand) button. !25729
- Rate limit archive endpoint by user. !25750
- Improve audit log header layout. !25821
- Migrate mentions for merge requests to DB table. !25826
- Align git returned error codes. !25936
- Split cluster info page into tabs. !25940
- Remove visibility check from epic descendant counts. !25975
- Use colon to tokenize input in filtered search. !26072
- Add link to dependency proxy docs on the dependency proxy page. !26092
- Remove Puma notices from AdminArea banner. !26137
- Add airgap support to Dependency Scanning template. !26145
- 27880 Make release notes optional and do not delete release when they are removed. !26231 (Pavlo Dudchenko)
- Limit notification-type broadcast display to web interface. !26236 (Aleksandrs Ļedovskis)
- Update renewal banner link for clearer instructions. !26240
- Special handling for the rich viewer on specific file types. !26260
- Rename pod logs to logs. !26313
- Ensure checksums match when updating repository storage. !26334
- Bump Auto Deploy image to v0.12.1. !26336
- Use cert-manager 0.10 instead of 0.9 for new chart installations. !26345
- Use y-axis format configuration in column charts. !26356
- Add Prometheus metrics for Gitaly and database time in background jobs. !26384
- Batch processing LFS objects downloads. !26434
- Add edit custom metric link to metrics dashboard. !26511
- Remove unused file_type column from packages_package_files. !26527
- Enable client-side GRPC keepalive for Gitaly. !26536
- Use ReplicateRepository when moving repo storage. !26550
- Add functionality to render individual mermaids. !26564
- Sync snippet after Git action. !26565
- In single-file editor set syntax highlighting theme according to user's preference. !26606
- Introduce a feature flag for Notifications for when pipelines are fixed. !26682 (Jacopo Beschi @jacopo-beschi)
- Replace checkbox by toggle for ModSecurity on Cluster App Page. !26720
- Change capybara screenshots files names taken on tests failures. !26788
- Update cluster-applications image to v0.11 with a runner bugfix, updated cert-manager, and vault as a new app. !26842
- Store first commit's authored_date for value stream calculation on merge. !26885
- Group repository contributors by email instead of name. !26899 (Hilco van der Wilk)
- Move authorized_keys operations into their own Sidekiq queue. !26913
- Upgrade Elastic Stack helm chart to 1.9.0. !27011
- Enable customizable_cycle_analytics feature flag by default. !27418
- Deemphasized styles for inline code blocks.

### Performance (41 changes, 1 of them is from the community)

- Cache milestone issue counters and make them independent of user permissions. !21554
- Persist expanded environment name in ci build metadata. !22374
- Diffs load each view style separately, on demand. !24821
- Project repositories are no longer cloned by default when running DAST. !25320
- Enable Workhorse upload acceleration for Project Import API. !25361
- Add API pagination for deployed merge requests. !25733
- Upgrade to Bootsnap 1.4.6. !25844
- Improve performance of Repository#merged_branch_names. !26005
- Fix N+1 in Group milestone view. !26051
- Project Snippets API endpoints check feature status. !26064
- Memoize loading of CI variables. !26147
- Refactor workhorse passthrough URL checker. !26157 (Takuya Noguchi)
- Project Snippets GraphQL resolver checks feature status. !26158
- Improved MR toggle file performance by hiding instead of removing. !26181
- Use Workhorse acceleration for Project Import file upload via UI. !26278
- Improve SnippetsFinder performance with disabled project snippets. !26295
- Add trigram index on snippet description. !26341
- Optimize todos counters in usage data. !26442
- Optimize event counters query performance in usage data. !26444
- Ensure RepositoryLinkFilter handles Gitaly failures gracefully. !26531
- Fix N+1 queries for PipelinesController#index.json. !26643
- Optimize Project related count with slack service. !26686
- Optimize Project counters with respository enabled counter. !26698
- Optimize Deployment related counters. !26757
- Optimize ci_pipelines counters in usage data. !26774
- Improve performance of the "has this commit been reverted?" check. !26784
- Optimize Project counters with pipelines enabled counter. !26802
- Optimize notes counters in usage data. !26871
- Optimize clusters counters query performance in usage data. !26887
- Enable Workhorse upload acceleration for Project Import uploads via API. !26914
- Use process-wide memory cache for feature flags. !26935
- Optimize services usage counters using batch counters. !26973
- Optimize Project related count service desk enabled. !27115
- Swap to UNLINK for Redis set cache. !27116
- Optimize members counters query performance in usage data. !27197
- Use batch counters instead of approximate counters in usage data. !27218
- Enable Redis cache key compression. !27254
- Move feature flag list into process cache. !27511
- Remove duplicate authorization refresh for group members on project creation.
- Optimize project representation in large imports.
- Replace several temporary indexes with a single one to save time when running mentions migration.

### Added (115 changes, 16 of them are from the community)

- Notifications for when pipelines are fixed. !16951 (Jacopo Beschi @jacopo-beschi)
- Backport API support to move between repository storages/shards. !18721 (Ben Bodenmiller)
- Add ability to trigger pipelines when project is rebuilt. !20063
- Add user dismiss option to broadcast messages. !20665 (Fabio Huser)
- Show notices in Admin area when detected any of these cases: Puma, multi-threaded Puma, multi-threaded Puma + Rugged. !21403
- Update git workflows and routes to allow snippets. !21739
- Add Cobertura XML coverage visualization to merge request diff view. !21791 (Fabio Huser)
- Add 2FA support to admin mode feature. !22281 (Diego Louzán)
- GraphQL: Add Board type. !22497 (Alexander Koval)
- Add/update services to delete snippets repositories. !22672
- Render single snippet blob in repository. !23848
- Commit file when snippet is created. !23953
- Addition of the Group Deploy Token interface. !24102
- Allow multiple Slack channels for notifications. !24132
- Import/Export snippet repositories. !24150
- Add custom validator for validating file path. !24223 (Rajendra Kadam)
- Add a bulk processor for elasticsearch incremental updates. !24298
- Send alert emails for generic incident alerts. !24414
- Introduce default branch protection at the group level. !24426
- Add "New release" button to Releases page. !24516
- Nudge users to select a gitlab-ci.yml template. !24622
- Allow enabling/disabling modsecurity from UI. !24747
- Add possibility to track milestone changes on issues and merge requests. !24780
- Allow group/project board to be queried by ID via GraphQL. !24825
- Add functionality to revoke a X509Certificate and update related X509CommitSignatures. !24889 (Roger Meier)
- Update file content of an existing custom dashboard. !25024
- Add deploy tokens instance API endpoint. !25066
- Add support for alert-based metric embeds in GFM. !25075
- Add restrictions for signup email addresses. !25122
- Add accessibility scanning CI template. !25144
- Expose `plan` and `trial` to `/users/:id` endpoint. !25151
- Add "Job Title" field in user settings and display on profile. !25155
- Add endpoint for listing all deploy tokens for a project. !25186
- Add api endpoint for listing deploy tokens for a group. !25219
- Add API endpoint for deleting project deploy tokens. !25220
- Add API endpoint for deleting group deploy tokens. !25222
- Allow users to get Merge Trains entries via Public API. !25229
- Added CI_MERGE_REQUEST_CHANGED_PAGE_* to Predefined Variables reference. !25256
- Add missing arguments to UpdateIssue mutation. !25268
- Add api endpoint to create deploy tokens. !25270
- Automatically include embedded metrics for GitLab alert incidents. !25277
- Allow to create masked variable from group variables API. !25283 (Emmanuel CARRE)
- Add migration to create self monitoring project environment. !25289
- Add deploy and re-deploy buttons to deployments. !25427
- Replaced ACE with Monaco editor for Snippets. !25465
- Add support for user Job Title. !25483
- Add name_regex_keep param to container registry bulk delete API endpoint. !25484
- Add Project template for Gatsby. !24192
- Add filepath to ReleaseLink. !25512
- Added Drop older active deployments project setting. !25520
- Add filepath to release links API. !25533
- Adds new activity panel to package details page. !25534
- Add filepath redirect url. !25541
- Add version column to operations_feature_flags table. !25552
- Filter commits by author. !25597
- Add api endpoint for creating group deploy tokens. !25629
- Expose assets filepath URL on UI. !25635
- Update moved service desk issues notifications. !25640
- Allow chart descriptions for Insights. !25686
- Allow to disable inheritance of default job settings. !25690
- Support more query variables in custom dashboards per project. !25732
- All image diffs (except for renamed files) show the image file size in the diff. !25734
- Optional custom icon in the OmniAuth login labels. !25744 (Tobias Wawryniuk, Luca Leonardo Scorcia)
- Add avatar upload support for create and update group APIs. !25751 (Rajendra Kadam)
- Add properties to the dashboard definition to customize y-axis format. !25785
- Empty state for Code Review Analytics. !25793
- Search issues in GraphQL API by milestone title and assignees. !25794
- Add package_type as a filter option to the packages list API endpoint. !25816
- Add support for configuring remote mirrors via API. !25825 (Rajendra Kadam)
- Display base label in versions drop down. !25834
- Create table & setup operations endpoint for Status Page Settings. !25863
- Update Ingress chart version to 1.29.7. !25949
- Include snippet description as part of snippet title search (basic search). !25961
- Add admin API endpoint to delete Sidekiq jobs matching metadata. !25998
- Add documentation for create remote mirrors API. !26012 (Rajendra Kadam)
- Update charts documentation and common_metrics.yml to enable data formatting. !26048
- Allow issues/merge_requests as an issuable_type in Insights configuration. !26061
- Add migration for Requirement model. !26097
- Create scim_identities table in preparation for newer SCIM features in the future. !26124
- Add web_url attribute to API response for Commits. !26173
- Filter sentry error list by status (unresolved/ignored/resolved). !26205
- Add grape custom validator for sha params. !26220 (Rajendra Kadam)
- Update cluster-applications to v0.9.0. !26242
- Support DotEnv Variables through report type artifact. !26247
- More logs entries are loaded when logs are scrolled to the top. !26254
- Introduce db table to store users statistics. !26261
- Add title to Analytics sidebar menus. !26265
- Added package_name as filter parameter to packages API. !26291
- Added tracking to merge request jump to next thread buttons. !26319 (Martin Hobert)
- Introduce optional expiry date for SSH Keys. !26351
- Show cluster status (FE). !26368
- Add CI template to deploy to ECS. !26371
- Make hostname configurable for smartcard authentication. !26411
- Filter rules by target_branch in approval_settings. !26439
- Add CRUD for Instance-Level Integrations. !26454
- Add vars to allow air-gapped usage of Retire.js (Dependency Scanning). !26463
- Upgrade Pages to 1.17.0. !26478
- Add dedicated Release page for viewing a single Release. !26502
- Allow selecting all queues with sidekiq-cluster. !26594
- Enable feature Dynamic Child Pipeline creation via artifact. !26648
- Generate JSON-formatted a11y CI artifacts. !26687
- Add anchor tags to related issues and related merge requests. !26756 (Gilang Gumilar)
- Added Blob Description Edit component in Vue. !26762
- Added Edit Visibility Vue compoenent for Snippet. !26799
- Add package_type as a filter option to the group packages list API endpoint. !26833
- Update UI for project and group settings CI variables. !26901
- Track merge request cherry-picks. !26907
- Introduce database table for user highest roles. !26987
- Add ability to whitelist ports. !27025
- Add issue summary to Release blocks on the Releases page. !27032
- Support sidekiq-cluster supervision through bin/background_jobs. !27042
- Adds crossplane as CI/CD Managed App. !27374
- Update UI for project and group settings CI variables. !27411
- Add remote mirrors API.
- Add changed pages dropdown to visual review modal.

### Other (66 changes, 22 of them are from the community)

- Make design_management_versions.created_at not null. !20182 (Lee Tickett)
- Drop forked_project_links table. !20771 (Lee Tickett)
- Moves refreshData from issue model to board store. !21409 (nuwe1)
- Use DNT: 1 as an experiment opt-out mechanism. !22100
- Include full path to an upload in api response. !23500 (briankabiro)
- Update Ruby version in official CI templates. !23585 (Takuya Noguchi)
- Schedule worker to migrate security job artifacts to security scans. !24125
- Move namespace of Secure Sidekiq queues. !24340
- Remove spinner from app/views/projects/notes. !25015 (nuwe1)
- Migrate .fa-spinner to .spinner for ee/app/views/shared/members. !25019 (nuwe1)
- Migrate .fa-spinner to .spinner for app/views/ide. !25022 (nuwe1)
- Remove spinner from app/views/award_emoji. !25032 (nuwe1)
- Remove .fa-spinner from app/views/projects/forks. !25034 (nuwe1)
- Remove .fa-spinner from app/views/snippets/notes. !25036 (nuwe1)
- Migrate .fa-spinner to .spinner for app/views/help. !25037 (nuwe1)
- Replaced underscore with lodash for app/assets/javascripts/lib. !25042 (Shubham Pandey)
- Remove unused loading spinner from badge_settings partial. !25044 (nuwe1)
- Migrate .fa-spinner to .spinner for app/views/projects/find_file. !25051 (nuwe1)
- Migrate .fa-spinner to .spinner for app/assets/javascripts/notes/components/discussion_resolve_button.vue. !25055 (nuwe1)
- Change OmniAuth log format to JSON. !25086
- migrate fa spinner for notification_dropdown.js. !25141 (minghuan)
- Use new loading spinner in Todos dashboard buttons. !25142 (Tsegaselassie Tadesse)
- Refuse to start web server without a working ActiveRecord connection. !25160
- Simplifying colors in the Web IDE. !25304
- Clean up conditional `col-` classes in `nav_dropdown_button.vue`. !25312
- Only load usage ping cron schedule for Sidekiq. !25325
- Update rouge to v3.16.0. !25334 (Konrad Borowski)
- Update project's permission settings description to reflect actual permissions. !25523
- Use clearer error message for pages deploy job when the SHA is outdated. !25659
- Add index on LOWER(domain) for pages_domains. !25664
- Remove repository_storage column from snippets. !25699
- Add instance column to services table. !25714
- Update GitLab Runner Helm Chart to 0.14.0. !25749
- Update loader for various project views. !25755 (Phellipe K Ribeiro)
- Clarify private visibility for projects. !25852
- Do not parse undefined severity and confidence from reports. !25884
- Remove special chars from previous and next items in pagination. !25891
- Update Auto DevOps deployment template's auto-deploy-image to v0.10.0 (updates the included glibc). !25920
- Update DAST auto-deploy-image to v0.10.0. !25922
- Optimize storage usage for newly created ES indices. !25992
- Replace undefined severity with unknown severity for occurrences. !26085
- Replace undefined severity with unknown severity for vulnerabilities. !26305
- Remove unused Snippets#content_types method. !26306
- Change tooltip text for pipeline on last commit widget. !26315
- Resolve Change link-icons on security configuration page to follow design system. !26340
- Put System Metrics chart group first in default dashboard. !26355
- Validates only one service template per type. !26380
- update table layout for error tracking list on medium view ports. !26479
- Validate absence of project_id if service is a template. !26563
- Move sidekiq-cluster script to Core. !26703
- Update GitLab's codeclimate to 0.85.9. !26712 (Eddie Stubbington)
- Bump minimum node version to v10.13.0. !26831
- Remove promoted notes temporary index. !26896
- Update Project Import API rate limit. !26903
- Backfill LfsObjectsProject records of forks. !26964
- Add migration for creating open_project_tracker_data table. !26966
- Fixed SSH warning style. !26992
- Use new codequality docker image from ci-cd group. !27098
- Add tooltip to modification icon in the file tree. !27158
- Upgrade Gitaly gem and fix UserSquash RPC usage. !27372
- Replace issue-external icon with external-link. !208827
- Add keep_divergent_refs to remote_mirrors table.
- Replace issue-duplicate icon with duplicate icon.
- Add confidential attribute to notes table.
- Replace content_viewer_spec setTimeouts with semantic actions / events. (Oregand)
- Improvement in token reference.


## 12.8.10 (2020-04-30)

### Security (7 changes)

- Ensure MR diff exists before codeowner check.
- Prevent unauthorized access to default branch.
- Do not return private project ID without permission.
- Fix doorkeeper CVE-2020-10187.
- Prevent ES credentials leak.
- Return only safe urls for mirrors.
- Validate workhorse 'rewritten_fields' and properly use them during multipart uploads.


## 12.8.9 (2020-04-14)

### Security (3 changes)

- Refresh ProjectAuthorization during Group deletion.
- Prevent filename bypass on artifact upload.
- Update rack and related gems to 2.0.9 to fix security issue.


## 12.8.7 (2020-03-16)

### Fixed (1 change, 1 of them is from the community)

- Fix crl_url parsing and certificate visualization. !25876 (Roger Meier)


## 12.8.6 (2020-03-11)

### Security (1 change)

- Do not enable soft email confirmation by default.


## 12.8.5

### Fixed (8 changes)

- Fix Group Import API file upload when object storage is disabled. !25715
- Fix Web IDE fork modal showing no text. !25842
- Fixed regression when URL was encoded in a loop. !25849
- Fixed repository browsing for folders with non-ascii characters. !25877
- Fix search for Sentry error list. !26129
- Send credentials with GraphQL fetch requests. !26386
- Show CI status in project dashboards. !26403
- Rescue invalid URLs during badge retrieval in asset proxy. !26524

### Performance (2 changes)

- Disable Marginalia line backtrace in production. !26199
- Remove unnecessary Redis deletes for broadcast messages. !26541

### Other (1 change, 1 of them is from the community)

- Fix fixtures for Error Tracking Web UI. !26233 (Takuya Noguchi)


## 12.8.4

### Fixed (8 changes)

- Fix Group Import API file upload when object storage is disabled. !25715
- Fix Web IDE fork modal showing no text. !25842
- Fixed regression when URL was encoded in a loop. !25849
- Fixed repository browsing for folders with non-ascii characters. !25877
- Fix search for Sentry error list. !26129
- Send credentials with GraphQL fetch requests. !26386
- Show CI status in project dashboards. !26403
- Rescue invalid URLs during badge retrieval in asset proxy. !26524

### Performance (2 changes)

- Disable Marginalia line backtrace in production. !26199
- Remove unnecessary Redis deletes for broadcast messages. !26541

### Other (1 change, 1 of them is from the community)

- Fix fixtures for Error Tracking Web UI. !26233 (Takuya Noguchi)


## 12.8.3

### Fixed (8 changes)

- Fix Group Import API file upload when object storage is disabled. !25715
- Fix Web IDE fork modal showing no text. !25842
- Fixed regression when URL was encoded in a loop. !25849
- Fixed repository browsing for folders with non-ascii characters. !25877
- Fix search for Sentry error list. !26129
- Send credentials with GraphQL fetch requests. !26386
- Show CI status in project dashboards. !26403
- Rescue invalid URLs during badge retrieval in asset proxy. !26524

### Performance (2 changes)

- Disable Marginalia line backtrace in production. !26199
- Remove unnecessary Redis deletes for broadcast messages. !26541

### Other (1 change, 1 of them is from the community)

- Fix fixtures for Error Tracking Web UI. !26233 (Takuya Noguchi)


## 12.8.2

### Security (17 changes)

- Update container registry authentication to account for login request when checking permissions.
- Update ProjectAuthorization when deleting or updating GroupGroupLink.
- Prevent an endless checking loop for two merge requests targeting each other.
- Update user 2fa when accepting a group invite.
- Fix for XSS in branch names.
- Prevent directory traversal through FileUploader.
- Run project badge images through the asset proxy.
- Check merge requests read permissions before showing them in the pipeline widget.
- Respect member access level for group shares.
- Remove OID filtering during LFS imports.
- Protect against denial of service using pipeline webhook recursion.
- Expire account confirmation token.
- Prevent XSS in admin grafana URL setting.
- Don't require base_sha in DiffRefsType.
- Sanitize output by dependency linkers.
- Recalculate ProjectAuthorizations for all users.
- Escape special chars in Sentry error header.

### Other (1 change, 1 of them is from the community)

- Fix fixtures for Error Tracking Web UI. !26233 (Takuya Noguchi)


## 12.8.1

### Fixed (5 changes)

- Fix markdown layout of incident issues. !25352
- Time series extends axis options correctly. !25399
- Fix "Edit Release" page. !25469
- Fix upgrade failure in EE displaying license. !25788
- Fixed last commit widget when Gravatar is disabled. !25800


## 12.8.0

### Security (6 changes, 2 of them are from the community)

- Upgrade Doorkeeper to 4.4.3 to address CVE-2018-1000211. !20953
- Upgrade Doorkeeper to 5.0.2. !21173
- Update webpack related packages. !22456 (Takuya Noguchi)
- Update rubyzip gem in qa tests to 1.3.0 to fix CVE-2019-16892. !24119
- Update GraphicsMagick from 1.3.33 to 1.3.34. !24225 (Takuya Noguchi)
- Update handlebars to remove issues from dependency dashboard.

### Removed (2 changes, 1 of them is from the community)

- Remove temporary index at services on project_id. !24263
- Remove CI status from Projects Dashboard. !25225 (George Thomas @thegeorgeous)

### Fixed (136 changes, 21 of them are from the community)

- When a namespace GitLab Subscription expires, disable SSO enforcement. !21135
- Fix bug with snippet counts not being scoped to current authorisation. !21705
- Log user last activity on REST API. !21725
- Create LfsObjectsProject record for forks as well. !22418
- Limit size of diffs returned by /projects/:id/repository/compare API endpoint. !22658
- Fix spacing and UI on Recent Deliveries section of Project Services. !22666
- Improve error messages when adding a child epic. !22688
- Fixes a new line issue with suggestions in the last line of a file. !22732
- Use POSTGRES_VERSION variable in Auto DevOps Test stage. !22884 (Serban Marti)
- Include milestones from subgroups in the list of Group Milestones. !22922
- Authenticate user when scope is passed to events api. !22956 (briankabiro)
- Limit productivity analytics graph y-axis scale to whole numbers. !23140
- Fix GraphiQL when GitLab is installed under a relative URL. !23143 (Mathieu Parent)
- Stop NoMethodError happening for 1.16+ Kubernetes clusters. !23149
- Fix advanced global search permissions for guest users. !23177
- Fix JIRA DVCS retrieving repositories. !23180
- Fix logs api etag issues with elasticsearch. !23249
- Add border radius and remove blue outline on recent searches filter. !23266
- Fix premailer and S/MIME emailer hooks order. !23293 (Diego Louzán)
- Fix Web IDE alert message look and feel. !23300 (Sean Nichols)
- Ensure that error tracking frontend only polls when required. !23305
- Fixes spacing issue in modal footers. !23327
- Fix POST method in dashboard link for disabling admin mode. !23363 (Diego Louzán)
- Fix Markdown not rendering on releases page. !23370
- Fix pipeline status loading errors on project dashboard page caused by Gitaly connection failures. !23378
- Improve message UI on Microsoft Teams notification. !23385 (Takuya Noguchi)
- Use state machine in Merge Train to avoid race conditions. !23395
- Prevent DAG builds to run after skipped need build. !23405
- Fixes AutoMergeProcessWorker failing when merge train service is not available for a merge request. !23407
- Fix error when assigning an existing asignee. !23416
- Fix outdated MR security warning message. !23496
- Fix missing API notification argument for Microsoft Teams. !23571 (Seiji Suenaga)
- Support the bypass 2FA function with ADFS SAML. !23615
- Require other stages than .pre and .post. !23629
- Remove the OpenSSL include within SMIME email signing. !23642 (Roger Meier)
- Fix custom charts in monitoring dashboard shrinking. !23649
- Correctly render mermaid digrams inside details blocks. !23662
- Fix Pipeline failed notification email not being delivered if the failed job is a bridge job. !23668
- Call DetectRepositoryLanguagesWorker only for project repositories. !23696
- Fix emails on push integrations created before 12.7. !23699
- Fix hash parameter of Permalink and Blame button. !23713
- Task lists work correctly again on closed MRs. !23714
- Fix broken link to documentation. !23715
- Trim extra period when merge error displayed. !23737
- Skip squashing with only one commit in a merge request. !23744
- Fix 500 error when trying to unsubscribe from an already deleted entity. !23747
- Fix some of the file encoding issues when uploading in the Web IDE. !23761
- Remove keep button for non archive artifacts. !23762
- Ensure all Project records have a corresponding ProjectFeature record. !23766
- Fix design of snippet search results page. !23780
- Fix Merge Request comments when some notes are corrupt. !23786
- Add optional angle brackets in address_regex. !23797 (Max Winterstein)
- Eliminate statement timeouts when namespace is blank. !23839
- Remove unstaged and staged modification tooltip. !23847
- Allow Owner access level for sharing groups with groups. !23868
- Allow running child pipelines as merge request pipelines. !23884
- Fix user popover glitch. !23904
- Return 404 when repository archive cannot be retrieved. !23926
- Fix 503 errors caused by Gitaly failures during project_icon lookup. !23930
- Fix showing 'NaN files' when a MR diff does not have any changes. !24002
- Label MR test modal execution time as seconds. !24019
- Fix copy markdown with elements with no text content. !24020
- Disable pull mirror importing for archived projects. !24029
- Remove gray color from diff buttons. !24041
- Prevent project path namespace overflow during import. !24042 (George Tsiolis)
- Fix JIRA::HTTPError initialize parameter. !24060
- Fix multiline issue when loading env vars from DinD in SAST. !24108
- Clean backgroud_migration queue from ActivatePrometheusServicesForSharedCluster jobs. !24135
- Fix quoted-printable encoding for unicode and newlines in mails. !24153 (Diego Louzán)
- Replace artifacts via Runner API if already exist. !24165
- Port `trigger` keyword in CI config to Core. !24191
- Fix race condition bug in Prometheus managed app update process. !24228
- Hide label tooltips when dragging board cards. !24239
- Fix dropdown caret not being positioned correctly. !24273
- Enable recaptcha check on sign up. !24274
- Avoid loading user activity calendar on mobile. !24277 (Takuya Noguchi)
- Resolve Design discussion note preview is broken. !24288
- Query projects of subgroups in productivity analytics. !24335
- Query projects of subgroups in Cycle Analytics. !24392
- Fix backup restoration with pre-existing wiki. !24394
- Fix duplicated user popovers. !24405
- Fix inconditionally setting user profile to public when updating via API and private_profile parameter is not present in the request. !24456 (Diego Louzán)
- Enable Web IDE on projects without Merge Requests. !24508
- Avoid double encoding of credential while importing a Project by URL. !24514
- Redact push options from error logs. !24540
- Fix merge train unnecessarily retries pipeline by a race condition. !24566
- Show selected template type when clicked. !24596
- Don't leak entire objects into the error log when rendering markup fails. !24599
- Fix blobs search API degradation. !24607
- Sanitize request parameters in exceptions_json.log. !24625
- Add styles for board list labels when text is too long. !24627
- Show blocked status for all blocked issues on issue boards. !24631
- Ensure board lists are sorted consistently. !24637
- Geo: Fix GeoNode name in geo:update_primary_node_url rake task. !24649
- Fix link to base domain help in clusters view. !24658
- Fix false matches of substitution-based quick actions in text. !24699
- Fix pipeline icon background in Web IDE. !24707
- Fix job page not loading because kuberenetes/prometheus URL is blocked. !24743
- Fix signature badge popover on Firefox. !24756
- Avoid autolinking YouTrack issue numbers followed by letters. !24770 (Konrad Borowski)
- Fix 500 error while accessing Oauth::ApplicationsController without a valid session. !24775
- Ensure a valid mount_point is used by the AvatarUploader. !24800
- Fix k8s logs alert display state. !24802
- Squelch Snowplow tracker log messages. !24809
- Fix code line and line number alignment in Safari. !24820
- Fixed default-branch link under Pipeline Subscription settings. !24834 (James Johnson)
- Do not remove space from project name in Slack. !24851
- Drop etag cache on logs API. !24864
- Revert rename services template to instance migration. !24885
- Geo: Don't clean up files in object storage when Geo is responsible of syncing them. !24901
- Add missing colors on the monitoring dashboards. !24921
- Upgrade omniauth-github gem to fix GitHub API deprecation notice. !24928
- dragoon20. !24958 (Jordan Fernando)
- Fix bug rendering BlobType markdown data. !24960
- Use closest allowed visibility level on group creation when importing groups using Group Import/Export. !25026
- Extend the list of excluded_attributes for group on Group Import. !25031
- Update broken links to Cloud Run for Anthos documentation. !25159
- Fix autocomplete limitation bug. !25167
- Fix Group Import existing objects lookup when description attribute is an empty string. !25187
- Fix N+1 queries caused by loading job artifacts archive in pipeline details entity. !25250
- Fix sidekiq jobs not always getting a database connection when running with low concurrency. !25261
- Fix overriding the image pull policy from a values file for Auto Deploy. !25271 (robcalcroft)
- Pin Auto DevOps Docker-in-Docker service image to work around pull timeouts. !25286
- Remove name & path from list of excluded attributes during Group Import. !25342
- Time series extends axis options correctly. !25399
- Fix "Edit Release" page. !25469
- Ensure New Snippet button is displayed based on the :create_snippet permission in Project Snippets page and User profile > Snippets tab. !55240
- Fix wrong MR link is shown on pipeline failure email.
- Fix issue count wrapping on board list.
- Allow long milestone titles on board lists to be truncated.
- Update styles for pipeline status badge to be correctly vertically centered in project pipeline card. (Oregand)
- MVC for assignees avatar dissapearing when opening issue sidebar in board. (Oregand)
- Fix application settings not working with pending migrations.
- Rename too long migration filename to address gem packaging limitations.
- Add more accurate way of counting remaining background migrations before upgrading.
- update main javascript file to only apply right sidebar class when an aside is present. (Oregand)

### Deprecated (2 changes)

- Move repository routes under - scope. !20455
- Move merge request routes under /-/ scope. !21126

### Changed (82 changes, 13 of them are from the community)

- Move the clone button to the tree controls area. !17752 (Ablay Keldibek)
- Add experimental --queue-selector option to sidekiq-cluster. !18877
- Truncate related merge requests list in pipeline view. !19404
- Increase pipeline email notification from 10 to 30 lines. !21728 (Philipp Hasper)
- Sets size limits on data loaded async, like deploy boards and merge request reports. !21871
- Deprecate /admin/application_settings in favor of /admin/application_settings/general. The former path is to be removed in 13.0. !22252 (Alexander Oleynikov)
- Migrate epic, epic notes mentions to respective DB table. !22333
- Restyle changes header & file tree. !22364
- Let tie breaker order follow primary sort direction (API). !22795
- Allow SSH keys API endpoint to be requested for a given username. !22899 (Rajendra Kadam)
- Allow to deploy only forward deployments. !22959
- Add blob and blob_viewer fields to graphql snippet type. !22960
- Activate new project integrations by default. !23009
- Rename Custom hooks to Server hooks. !23064
- Reorder signup omniauth options. !23082
- Cycle unresolved threads. !23123
- Rename 'GitLab Instance Administration' project to 'GitLab self monitoring' project. !23182
- Update pipeline status copy in deploy footer. !23199
- Allow users to read broadcast messages via API. !23298 (Rajendra Kadam)
- Default the `creation of a Mattermost team` checkbox to false. !23329 (briankabiro)
- Makes the generic alerts endpoint available with the free tier. !23339
- Allow to switch between cloud providers in cluster creation screen. !23362
- Rename cycle analytics interfaces to value stream analytics. !23427
- Upgrade to Gitaly v1.83.0. !23431
- Groups::ImportExport::ExportService to require admin_group permission. !23434
- Bump ingress managed app chart to 1.29.3. !23461
- Add support for stacked column charts. !23474
- Remove kibana_hostname column from clusters_applications_elastic_stacks table. !23503
- Update rebasing to use the new two-phase Gitaly Rebase RPC. !23546
- Fetch merge request widget data asynchronous. !23594
- Include issues created in GitLab on error tracking details page. !23605
- Add Epics Activity information to Group Export. !23613
- Copy issues routing under - scope. !23779
- Make Explore Projects default to All. !23811
- Migrate CI CD statistics + duration chart to VueJS. !23840
- Use NodeUpdateService for updating Geo node. !23894 (Rajendra Kadam)
- Add support for column charts. !23903
- Update PagesDomains data model for serverless domains. !23943
- Upgrade to Gitaly v1.85.0. !23945
- Change vague copy to clipboard icon to a clearer icon. !23983
- Add award emoji information of Epics and Epic Notes to Group Import/Export. !24003
- Make name, email, and location attributes readonly for LDAP enabled instances. !24049
- Migrate CI CD pipelines charts to ECharts. !24057
- Include license_scanning to index_ci_builds_on_name_for_security_products_values. !24090
- Add mode field to snippet blob in GraphQL. !24157
- Switch order of tabs in Web IDE nav dropdown. !24199
- Hide comment button if on diff HEAD. !24207
- Move commit routes under - scope. !24279
- Move security routes under - scope. !24287
- Restyle Merge Request diffs file tree. !24342
- Limit length of wiki file/directory names. !24364
- Admin mode support in sidekiq jobs. !24388 (Diego Louzán)
- Expose theme and color scheme user preferences in API. !24409
- Remove username lookup when mapping users when importing projects using Project Import/Export and rely on email only. !24464
- Extend logs retention to period from 15 to 30 days. !24466
- Move analytics pages under the sidebar for projects and groups. !24470
- Rename 'Kubernetes configured' button. !24487
- Test reports in the pipeline details page will now load when clicking the tests tab. !24577
- Move Settings->Operations->Incidents to the Core. !24600
- Upgrade to Gitaly v1.86.0. !24610
- Conan packages are validated based on full recipe instead of name/version alone. !24692
- WebIDE: Support # in branch names. !24717
- Move Merge Request from right sidebar of Web IDE to bottom bar. !24746
- Updated cluster-applications to v0.7.0. !24754
- Add migration to save Instance Administrators group ID in application_settings table. !24796
- Add percentile value support to single stat panel types. !24813
- Parse filebeat modsec logs as JSON. !24836
- Add plain_highlighted_data field to SnippetBlobType. !24856
- Add Board Lists to Group Export. !24863
- Replace underscore with lodash for ./app/assets/javascripts/mirrors. !24967 (Jacopo Beschi @jacopo-beschi)
- Replace underscore with lodash in /app/assets/javascripts/helpers. !25014 (rkpattnaik780)
- Migrate from class .fa-spinner to .spinner in app/assets/javascripts/gfm_auto_complete.js. !25039 (rk4bir)
- Update cluster-applications to v0.8.0. !25138
- Limit size of params array in JSON logs to 10 KiB. !25158
- Omit error details from previous attempt in Sidekiq JSON logs. !25161
- Remove unnecessary milestone join tables. !25198
- Upgrade to Gitaly v1.87.0. !25370
- Drop signatures in email replies. !25389 (Diego Louzán)
- update service desk project to use GlLoadingIcon over font awesome spinner. (Oregand)
- Search group-level objects among all ancestors during project import.
- Add broadcast type to API.
- Changed color of allowed to fail badge from danger to warning.

### Performance (22 changes, 1 of them is from the community)

- Check mergeability of MR asynchronously. !21026
- Fix query performance in PipelinesFinder. !21092
- Fix usage ping timeouts with batch counters. !22705
- Remove N+1 query for profile notifications. !22845 (Ohad Dahan)
- Limit page number on explore/projects. !22876
- Prevent unnecessary Gitaly calls when rendering comment excerpts in todos and activity feed. !23100
- Eliminate Gitaly N+1 queries loading submodules. !23292
- Optimize page loading of Admin::RunnersController#show. !23309
- Improve performance of the Container Registry delete tags API. !23325
- Don't allow Gitaly calls to exceed the worker timeout set for unicorn or puma. !23510
- Use CTE optimization fence for loading projects in dashboard. !23754
- Optimize ref name lookups in archive downloads. !23890
- Change broadcast message index. !23986
- Add index to audit_events (entity_id, entity_type, id). !23998
- Remove unneeded indexes on projects table. !24086
- Load maximum 1mb blob data for a diff file. !24160
- Optimize issue search when sorting by weight. !24208
- Optimize issue search when sorting by due date and position. !24217
- Refactored repository browser to use Vue and GraphQL. !24450
- Improvement to merged_branch_names cache. !24504
- Destroy user associations in batches like we do with projects. !24641
- Cache repository merged branch names by default. !24986

### Added (137 changes, 46 of them are from the community)

- x509 signed commits using openssl. !17773 (Roger Meier)
- Allow keyboard shortcuts to be disabled. !18782
- Add API endpoints for 'soft-delete for groups' feature. !19430
- Add UI for 'soft-delete for groups' feature. !19483
- Introduce project_settings table. !19761
- Expose current and last IPs to /users endpoint. !19781
- Add Group Import API endpoint & update Group Import/Export documentation. !20353
- Show Kubernetes namespace on job show page. !20983
- Add admin settings panel for instance-level serverless domain (behind feature flag). !21222
- Filter merge requests by approvals (API). !21379
- Expose is_using_seat attribute for Member in API. !21496
- Add querying of Sentry errors to Graphql. !21802
- Extends 'Duplicate dashboard' feature, by including custom metrics added to GitLab-defined dashboards. !21923
- Add tab width option to user preferences. !22063 (Alexander Oleynikov)
- Add iid to operations_feature_flags and backfill. !22175
- Support retrieval of disk statistics from Gitaly. !22226 (Nels Nelson)
- Implement allowing empty needs for jobs in DAG pipelines. !22246
- Create snippet repository when it's created. !22269
- When switching to a file permalink, just change the URL instead of triggering a useless page reload. !22340
- Packages published to the package registry via CI/CD with a CI_JOB_TOKEN will display pipeline information on the details page. !22485
- Add users memberships endpoints for admins. !22518
- Add cilium to the managed cluster apps template. !22557
- Add WAF Anomaly Summary service. !22736
- Introduce license_scanning CI template. !22773
- Add extra fields to the application context. !22792
- Add selective sync support to Geo Nodes API update endpoint. !22828 (Rajendra Kadam)
- Add validation for custom PrometheusDashboard. !22893
- Sync GitLab issue back to Sentry when created in GitLab. !23007
- Add new Elastic Stack cluster application for pod log aggregation. !23058
- NPM dist tags will now be displayed on the package details page. !23061
- Add show routes for group and project repositories_controllers and add pagination to the index responses. !23151
- Add pages_access_level to projects API. !23176 (Mathieu Parent)
- Document CI job activity limit for pipeline creation. !23246
- Update Praefect docs for subcommand. !23255
- Add CI variables to provide GitLab port and protocol. !23296 (Aidin Abedi)
- Seprate 5 classes in separate files from entities. !23299 (Rajendra Kadam)
- Upgrade pages to 1.14.0. !23317
- Indicate Sentry error severity in GitLab. !23346
- Sync GitLab issues with Sentry plugin integration. !23355
- Backfill missing GraphQL API Group type properties. !23389 (Fabio Huser)
- Allow setting minimum concurrency for sidekiq-cluster processes. !23408
- Geo: Add tables to prepare to replicate package files. !23447
- Update deploy token architecture to introduce group-level deploy tokens. !23460
- Add tags, external_base_url, gitlab_issue to Sentry Detailed Error graphql. !23483
- Reverse actions for resolve/ignore Sentry issue. !23516
- Add deploy_token_type column to deploy_tokens table. !23530
- Add ability to hide GraphQL fields using GitLab Feature flags. !23563
- Add can_create_merge_request_in to /project/:id API response. !23577
- Close related GitLab issue on Sentry error resolve. !23610
- Add emails_disabled to projects API. !23616 (Mathieu Parent)
- Expose group milestones on GraphQL. !23635
- Add support for lsif artifact report. !23672
- Displays package tags next to the name on the new package list page. !23675
- Collect release evidence at release timestamp. !23697
- Create conditional Enable Review App button. !23703
- Add CI variables to configure bundler-audit advisory database (Dependency Scanning). !23717
- Add API to "Play" a scheduled pipeline immediately. !23718
- Add selective sync support to Geo Nodes API create endpoint. !23729 (Rajendra Kadam)
- Refactor user entities into own class files. !23730 (Rajendra Kadam)
- Replace Net::HTTP with Gitlab::HTTP in rake gitlab:geo:check. !23741 (Rajendra Kadam)
- Add separate classes for user related entities for email, membership, status. !23748 (Rajendra Kadam)
- Add Sentry error stack trace to GraphQL API. !23750
- Allow for relative time ranges in metrics dashboard URLs. !23765
- Add non_archived param to issues API endpoint to filter issues from archived projects. !23785
- Add separate classes for project hook, identity, export status. !23789 (Rajendra Kadam)
- Create snippet repository model. !23796
- Add non_archived param to group merge requests API endpoint to filter MRs from non archived projects. !23809
- Change `Rename` to `Rename/Move` in Web IDE Dropdown. !23877
- Add separate classes for project related classes. !23887 (Rajendra Kadam)
- Added search box to dashboards dropdown in monitoring dashboard. !23906
- Display operations feature flag internal ids. !23914
- Enable search and filter in environments dropdown in monitoring dashboard. !23942
- Add GraphQL mutation to restore multiple todos. !23950
- Add migration to create resource milestone events table. !23965
- Add cycle analytics duration chart with median line. !23971
- Support require_password_to_approve in project merge request approvals API. !24016
- Add updateImageDiffNote mutation. !24027
- Upgrade Pages to 1.15.0. !24043
- Updated package details page header to begin updating the page design. !24055
- Added migration which adds project_key column to service_desk_settings. !24063
- Separate project and group entities into own class files. !24070 (Rajendra Kadam)
- Separate commit entities into own class files. !24085 (Rajendra Kadam)
- Add delete identity endpoint on the users API. !24122
- Add search support for protected branches API. !24137
- Dark syntax highlighting theme for Web IDE. !24158
- Added NuGet package installation instructions to package details page. !24162
- Expose issue link type in REST API. !24175
- Separate snippet entities into own class files. !24183 (Rajendra Kadam)
- Support for table of contents tag in GitLab Flavored Markdown. !24196
- Add GET endpoint to LDAP group link API. !24216
- Add API to enable and disable error tracking settings. !24220 (Rajendra Kadam)
- Separate protected and issuable entities into own class files. !24221 (Rajendra Kadam)
- Separate issue entities into own class files. !24226 (Rajendra Kadam)
- Make smarter user suggestions for assign slash commands. !24294
- Add loading icon to clusters being created. !24370
- Allow a grace period for new users to confirm their email. !24371
- Separate merge request entities into own class files. !24373 (Rajendra Kadam)
- Create an environment for self monitoring project. !24403
- Add blocked icon on issue board card. !24420
- Add blocking issues feature. !24460
- Wait for elasticsearch to be green on install. !24489
- Separate key and other entities into own class files. !24495 (Rajendra Kadam)
- Implement support of allow_failure keyword for CI rules. !24605
- Adds path to edit custom metrics in dashboard response. !24645
- Add tooltip when dates in date picker are too long. !24664
- API: Ability to list commits in order (--topo-order). !24702
- Separate note entities into own class files. !24732 (Rajendra Kadam)
- Separate 5 classes into own entities files. !24745 (Rajendra Kadam)
- Set default dashboard for self monitoring project. !24814
- Create operations strategies and scopes tables. !24819
- Separate access entities into own class files. !24845 (Rajendra Kadam)
- Refactor error tracking specs and add validation to enabled field in error tracking model. !24892 (Rajendra Kadam)
- Separate service entities into own class files. !24936 (Rajendra Kadam)
- Separate label entities into own class files. !24938 (Rajendra Kadam)
- Separate board, list and other entities into own class files. !24939 (Rajendra Kadam)
- Separate entities into own class files. !24941 (Rajendra Kadam)
- Separate tag and release entities into own class files. !24943 (Rajendra Kadam)
- Separate job entities into own class files. !24948 (Rajendra Kadam)
- Separate entities into own class files. !24950 (Rajendra Kadam)
- Separate environment entities into own class files. !24951 (Rajendra Kadam)
- Display the y-axis on the range of data value in the chart. !24953
- Separate token and template entities into own class files. !24955 (Rajendra Kadam)
- Separate token entities into own class files. !24974 (Rajendra Kadam)
- Separate JobRequest entities into own class files. !24977 (Rajendra Kadam)
- Separate entities into own class files. !24985 (Rajendra Kadam)
- Separate page domain entities into own class files. !24987 (Rajendra Kadam)
- add avatar_url in job webhook, and email in pipeline webhook. !24992 (Guillaume Micouin)
- Separate Application and Blob entities into own class files. !24997 (Rajendra Kadam)
- Separate badge entities into own class files. !25116 (Rajendra Kadam)
- Separate provider, platform and post receive entities into own class files. !25119 (Rajendra Kadam)
- Separate cluster entities into own class files. !25121 (Rajendra Kadam)
- Container Registry tag expiration policy settings. !25123
- Upgrade pages to 1.16.0. !25238
- Added "Prohibit outer fork" setting for Group SAML. !25246
- Separate project entity into own class file. !25297 (Rajendra Kadam)
- Add license FAQ link to license expired message.
- Add broadcast types to broadcast messages.

### Other (55 changes, 15 of them are from the community)

- Upgrade to Rails 6. !19891
- refactoring gl_dropdown.js to use ES6 classes instead of constructor functions. !20488 (nuwe1)
- Creates a standalone vulnerability page. !20734
- Auto generated wiki commit message containing HTML encoded entities. !21371 (2knal)
- removes store logic from issue board models. !21391 (nuwe1)
- removes store logic from issue board models. !21404 (nuwe1)
- Reducing whitespace in group list to show more on screen and reduce vertical scrolling. !21584
- Geo: Include host when logging. !22203
- Add rate limiter to Project Imports. !22644
- Use consistent layout in cluster advanced settings. !22656
- Replace custom action array in CI header bar with <slot>. !22839 (Fabio Huser)
- Fix visibility levels of subgroups to be not higher than their parents' level. !22889
- Update pg gem to v1.2.2. !23237
- Remove milestone_id from epics. !23282 (Lee Tickett)
- Remove button group for edit and web ide in file header. !23291
- Update GitLab Runner Helm Chart to 0.13.0/12.7.0. !23308
- Remove storage_version column from snippets. !23315
- Upgrade acme-client to v2.0.5. !23498
- Make rake -T output more consistent. !23550
- Show security report outdated message for only Active MRs. !23575
- Update Kaminari templates to match gl-pagination's markup. !23582
- Update GitLab Runner Helm Chart to 0.13.1 (GitLab Runner 12.7.1). !23588
- Remove unused Code Hotspots database tables. !23590
- Remove self monitoring feature flag. !23631
- Store security scans run in CI jobs. !23669
- More verbose JiraService error logs. !23688
- Rename Cloud Run on GKE to Cloud Run for Anthos. !23694
- Update links related to MR approvals in UI. !23948
- Migrate issue tracker data to data field tables. !24076
- Updated icon for copy-to-clipboard button. !24146
- Add specialized index to packages_packages database table. !24182
- Bump auto-deploy-image for Auto DevOps deploy to 0.9.1. !24231
- Bump DAST deploy auto-deploy-image to 0.9.1. !24232
- Move contribution analytics chart to echarts. !24272
- Minor text update to IDE commit to branch disabled tooltip. !24521
- Promote stackprof into a production gem. !24564
- Replace unstructured application logs with structured (JSON) application logs in the admin interface. !24614
- Move insights charts to echarts. !24661
- Improve UX of optional fields in Snippets form. !24762
- Update snippets empty state and remove explore snippets button. !24764
- Backfill LfsObjectsProject records of forks. !24767
- Update button margin of various empty states. !24806
- Update loading icon in Value Stream Analytics view. !24861
- Replace underscore with lodash for ./app/assets/javascripts/serverless. !25011 (Tobias Spagert)
- Replaced underscore with lodash for spec/javascripts/vue_shared/components. !25018 (Shubham Pandey)
- Replaced underscore with lodash for spec/javascripts/badges. !25135 (Shubham Pandey)
- Replace underscore with lodash for ./app/assets/javascripts/error_tracking. !25143 (Tobias Spagert)
- Destroy the OAuth application when Geo secondary becomes a primary. !25154 (briankabiro)
- Refactored snippets view to Vue. !25188
- Updated ui elements in wiki page creation. !25197 (Marc Schwede)
- Internationalize messages for group audit events. !25233 (Takuya Noguchi)
- Add a link to the variable priority override section from triggers page. !25264 (DFredell)
- Track usage of merge request file header buttons. (Oregand)
- Switch dropdown operators to lowercase.
- Add clarifying content to account fields.


## 12.7.9 (2020-04-14)

### Security (3 changes)

- Refresh ProjectAuthorization during Group deletion.
- Prevent filename bypass on artifact upload.
- Update rack and related gems to 2.0.9 to fix security issue.


## 12.7.5

### Fixed (4 changes, 1 of them is from the community)

- Add accidentally deleted project config for custom apply suggestions. !23687 (Fabio Huser)
- Fix database permission check for triggers on Amazon RDS. !24035
- Fix applying the suggestions with an empty custom message. !24144
- Remove invalid data from issue_tracker_data table.


## 12.7.3

### Security (17 changes, 1 of them is from the community)

- Fix xss on frequent groups dropdown. !50
- Bump rubyzip to 2.0.0. (Utkarsh Gupta)
- Disable access to last_pipeline in commits API for users without read permissions.
- Add constraint to group dependency proxy endpoint param.
- Limit number of AsciiDoc includes per document.
- Prevent API access for unconfirmed users.
- Enforce permission check when counting activity events.
- Prevent gafana integration token from being displayed as a plain text to other project maintainers, by only displaying a masked version of it. GraphQL api deprecate token field in GrafanaIntegration type.
- Cleanup todos for users from a removed linked group.
- Fix XSS vulnerability on custom project templates form.
- Protect internal CI builds from external overrides.
- ImportExport::ExportService to require admin_project permission.
- Make sure that only system notes where all references are visible to user are exposed in GraphQL API.
- Disable caching of repository/files/:file_path/raw API endpoint.
- Make cross-repository comparisons happen in the source repository.
- Update excon to 0.71.1 to fix CVE-2019-16779.
- Add workhorse request verification to package upload endpoints.


## 12.7.1

### Fixed (6 changes)

- Fix loading of sub-epics caused by wrong subscription check. !23184
- Fix Bitbucket Server importer error handler. !23310
- Fixes random passwords generated not conforming to minimum_password_length setting. !23387
- Reverts MR diff redesign which fixes Web IDE visual bugs including file dropdown not showing up. !23428
- Allow users to sign out on a read-only instance. !23545
- Remove invalid data from jira_tracker_data table. !23621

### Added (1 change)

- Close Issue when resolving corresponding Sentry error. !22744


## 12.7.0

### Security (6 changes, 2 of them are from the community)

- Ensure content matches extension on image uploads. !20697
- Update set-value from 2.0.0 to 2.0.1. !22366 (Takuya Noguchi)
- Update rdoc to 6.1.2. !22434
- Upgrade json-jwt to v1.11.0. !22440
- Update webpack from 4.40.2 to 4.41.5. !22452 (Takuya Noguchi)
- Update rack-cors to 1.0.6. !22809

### Removed (2 changes)

- Remove feature flag 'use_legacy_pipeline_triggers' and remove legacy tokens. !21732
- Add deprecation warning to Rake tasks in sidekiq namespace.

### Fixed (91 changes, 7 of them are from the community)

- Remove extra whitespace in user popover. !19938
- Migrate the database to activate projects prometheus service integration for projects with prometheus installed on shared k8s cluster. !19956
- Fix pages size limit setting in database if it is above the hard limit. !20154
- Support dashes in LDAP group CN for sync on users first log in. !20402
- Users without projects use a license seat in a non-premium license. !20664
- Add fallbacks and proper errors for diff file creation. !21034
- Authenticate API requests with job tokens for Rack::Attack. !21412
- Tasks in HTML comments are no longer incorrectly detected. !21434
- Hide mirror admin actions from developers. !21569
- !21542 Part 3: Handle edge cases in stage and unstage mutations. !21676
- Web IDE: Fix Incorrect diff of deletion and addition of the same file. !21680
- Fix bug when clicking on same note twice in Firefox. !21699 (Jan Beckmann)
- Fix "No changes" empty state showing up in changes tab, despite there being changes. !21713
- Require group owner to have linked SAML before enabling Group Managed Accounts. !21721
- Fix README.txt not showing up on a project page. !21763 (Alexander Oleynikov)
- Fix MR diffs file count increments while batch loading. !21764
- When sidekiq-cluster is asked to shutdown, actively terminate any sidekiq processes that don't finish cleanly in short order. !21796
- Prevent MergeRequestsController#ci_environment_status.json from making HTTP requests. !21812
- Fix issue: Discard button in Web IDE does nothing. !21902
- Fix "Discard" for newly-created and renamed files. !21905
- Add epic milestone sourcing foreign key. !21907
- Fix transferring groups to root when EE features are enabled. !21915
- Show regular rules without approvers. !21918
- Resolve "Merge request discussions API doesn't reject an error input in some case". !21936
- fix CSS when board issue is collapsed. !21940 (allenlai18)
- Properly check a task embedded in a list with no text. !21947
- Process quick actions when using Service Desk templates. !21948
- Sidebar getting partially hidden behind the content block. !21978 (allenlai18)
- Fix bug in Container Scanning report remediations. !21980
- Return empty body for 204 responses in API. !22086
- Limit the amount of time ChatNotificationWorker waits for the build trace. !22132
- Return 503 error when metrics dashboard has no connectivity. !22140
- Cancel running pipelines when merge request is dropped from merge train. !22146
- Fix: undefined background migration classes for EE-CE downgrades. !22160
- Check both SAST_DISABLE and SAST_DISABLE_DIND when executing SAST job template. !22166
- Check both DEPENDENCY_SCANNING_DISABLED and DS_DISABLE_DIND when executing Dependency Scanning job template. !22172
- Stop exposing MR refs in favor of persistent pipeline refs. !22198
- Display login or register widget only if user is not logged in. !22211
- Fix milestone quick action to handle ancestor group milestones. !22231
- Fix RefreshMergeRequestsService raises an exception and unnecessary sidekiq retry. !22262
- Make BackgroundMigrationWorker backward compatible. !22271
- Update foreign key constraint for personal access tokens. !22305
- Fix markdown table border colors. !22314
- Retry obtaining Let's Encrypt certificates every 2 hours if it wasn't successful. !22336
- Disable Prometheus metrics if initialization fails. !22355
- Make jobs with resource group cancellable. !22356
- Fix bug when trying to expose artifacts and no artifacts are produced by the job. !22378
- Gracefully error handle CI lint errors in artifacts section. !22388
- Fix GitLab plugins not working without hooks configured. !22409
- Prevent omniauth signup redirect loop. !22432 (Balazs Nagy)
- Fix deploy tokens erroneously triggering unique IP limits. !22445
- Add support to export and import award emojis for issues, issue notes, MR, MR notes and snippet notes. !22493
- Fix Delete Selected button being active after uploading designs after a deletion. !22516
- Fix releases page when tag contains a slash. !22527
- Reverts Add RBAC permissions for getting knative version. !22560
- Fix error in Wiki when rendering the AsciiDoc include directive. !22565
- Fix Error 500 in parsing invalid CI needs and dependencies. !22567
- Fix discard all to behave like discard single file in Web IDE. !22572
- Update IDE discard of renamed entry to also discard file changes. !22573
- Avoid pre-populating form for MR resolve issues. !22593
- Fix relative links in Slack message. !22608
- Hide merge request tab popover for anonymous users. !22613
- Remove unused keyword from EKS provision service. !22633
- Prevent job log line numbers from being selected. !22691
- Fix CAS users being signed out repeatedly. !22704
- Make Sidekiq timestamps consistently ISO 8601. !22750
- Merge a merge request immediately when passing merge when pipeline succeeds to the merge API when the head pipeline already succeeded. !22777
- Fix Issue API: creating with manual IID returns conflict when IID already in use. !22788 (Mara Sophie Grosch)
- Project issue board names now sorted correctly in FOSS. !22807
- Fix upload redirections when project has moved. !22822
- Update Mermaid to v8.4.5. !22830
- Prevent builds from halting unnecessarily when completing prerequisites. !22938
- Fix discarding renamed directories in Web IDE. !22943
- Gracefully handle marking a project deletion multiple times. !22949
- Fix: WebIDE doesn't work on empty repositories again. !22950
- Fix rebase error message translation in merge requests. !22952 (briankabiro)
- Geo: Fix Docker repository synchronization for local storage. !22981
- Include subgroups when searching inside a group. !22991
- Geo: Handle repositories in Docker Registry with no tags gracefully. !23022
- Fix group issue list and group issue board filters not showing ancestor group milestones. !23038
- Add returning relation from GroupMembersFinder if called on root group with only inherited param. !23161
- Fix extracting Sentry external URL when URL is nil. !23162
- Fix issue CSV export failing for some projects. !23223
- Fix unexpected behaviour of the commit form after committing in Web IDE. !23238
- Fix analytics tracking for new merge request notes. !23273
- Identify correct sentry id in error tracking detail. !23280
- Fix for 500 when error stack trace is empty. !119205
- Removes incorrect help text from EKS Kubernetes version field.
- Exclude snippets from external caching handling.
- Validate deployment SHAs and refs.
- Increase size of issue boards sidebar collapse button.

### Changed (42 changes, 4 of them are from the community)

- Restores user's ability to revoke sessions from the active sessions page. !17462 (Jesse Hall @jessehall3)
- Add documentation & helper text information regarding securing a GitLab instance. !18987
- Add activity across all projects to /events endpoint. !19816 (briankabiro)
- Don't run Auto DevOps when no dockerfile or matching buildpack exists. !20267
- Expose full reference path for issuables in API. !20354
- Add measurement details for programming languages graph. !20592
- Move instance statistics into analytics namespace. !21112
- Improve warning for Promote issue to epic. !21158
- Added Conan recipe in place of the package name on the package details page. !21247
- Expose description_html for labels. !21413
- Add audit events to the adding members to project or group API endpoint. !21633
- Include commit message instead of entire page content in Wiki chat notifications. !21722 (Ville Skyttä)
- Add fetching of Grafana Auth via the GraphQL API. !21756
- Update prometheus chart version to 9.5.2. !21935
- Turns on backend MR reports for DAST by default. !22001
- Changes to template dropdown location. !22049
- Copy merge request routes to the - scope. !22082
- Copy repository route under - scope. !22092
- Add back feature flag for cache invalidator. !22106
- Update jupyterhub chart. !22127
- Enable ability to install Crossplane app by default. !22141
- Apply word-diff highlighting to Suggestions. !22182
- Update auto-deploy-image to v0.8.3 for DAST default branch deploy. !22227
- Restyle changes header & file tree. !22364
- Upgrade to Gitaly v1.79.0. !22515
- Save Instance Administrators group ID in DB. !22600
- Resolve Create new project: Auto-populate project slug string to project name if name is empty. !22627
- Bump cluster-applications image to v0.4.0, adding support to install cert-manager. !22657
- Pass log source to the frontend. !22694
- Allow Unicode 11 emojis in project names. !22776 (Harm Berntsen)
- Update name max length. !22840
- Update button label in MR widget pipeline footer. !22900
- Exposes tiller.log as artifact in Managed-Cluster-Applications GitLab CI template. !22940
- Rename GitLab Plugins feature to GitLab File Hooks. !22979
- Allow to share groups with other groups. !23185
- Upgrade to Gitaly v1.81.0. !23198
- Enable Code Review Analytics by default. !23285
- Add JSON error context to extends error in CI lint. !30066
- Fix embedded snippets UI polish issues.
- Align embedded snippet mono space font with GitLab mono space font.
- Updates AWS EKS service role name help text to clarify it is distinct from provision role.
- Adds quickstart doc link to ADO CICD settings.

### Performance (27 changes)

- Reduce redis key size for the Prometheus proxy and the amount of queries by half. !20006
- Implement Atomic Processing that updates status of builds, stages and pipelines in one go. !20229
- Request less frequent updates from Runner when job log is not being watched. !20841
- Don't let Gitaly calls exceed a request time of 55 seconds. !21492
- Reduce CommitIsAncestor RPCs with environments. !21778
- LRU object caching for GroupProjectObjectBuilder. !21823
- Preload project, user and group to reuse objects during project import. !21853
- Fix slow query on blob search when doing path filtering. !21996
- Add index to optimize loading pipeline charts. !22052
- Avoid Gitaly RPCs in rate-limited raw blob requests. !22123
- Remove after_initialize and before_validation for Note. !22128
- Execute Gitaly LFS call once when Vue file enabled. !22168
- Speed up path generation with build artifacts. !22257
- Performance improvements on milestone burndown chart. !22380
- Added smart virtual list component to test reports to enhance rendering performance. !22381
- Add Index to help Hashed Storage migration on big instances. !22391
- Use GraphQL to load error tracking detail page content. !22422
- Improve link generation performance. !22426
- Create optimal indexes for created_at order (Projects API). !22623
- Avoid making Gitaly calls when some Markdown text links to an uploaded file. !22631
- Remove unused index on project_mirror_data. !22647
- Add more indexes for other order_by options (Projects API). !22784
- Add indexes for authenticated Project API calls. !22886
- Enable redis HSET diff caching by default. !23105
- Add `importing?` to disable some callbacks.
- Remove N+1 query issue when checking group root ancestor.
- Reduce Gitaly calls needed for issue discussions.

### Added (95 changes, 18 of them are from the community)

- Add previous revision link to blame. !17088 (Hiroyuki Sato)
- Render whitespaces in code. !17244 (Mathieu Parent)
- Add an option to configure forking restriction. !17988
- Add support for operator in filter bar. !19011
- Add epics to project import/export. !19883
- Load MR diff types lazily to reduce initial diff payload size. !19930
- Metrics and network referee artifact types added to job artifact types. !20181
- Auto stop environments after a certain period. !20372
- Implement application appearance API endpoint. !20674 (Fabio Huser)
- Add build metadata to package API. !20682
- Add support for Liquid format in Prometheus queries. !20793
- Adds created_at object to package api response. !20816
- Stage all changes by default in Web IDE. !21067
- 25968-activity-filter-to-notes-api. !21159 (jhenkens)
- Improve error list UI on mobile viewports. !21192
- New API endpoint GET /projects/:id/services. !21330
- Add child and parent labels to pipelines. !21332
- Add release count to project homepage. !21350
- Add pipeline deletion button to pipeline details page. !21365 (Fabio Huser)
- Add support for Rust Cargo.toml dependency vizualisation and linking. !21374 (Fabio Huser)
- Expose issue link type in REST API. !21375
- Implement customizable commit messages for applied suggested changes. !21411 (Fabio Huser)
- Add stacktrace to issue created from the sentry error detail page. !21438
- add background migration for sha256 fingerprints of ssh keys. !21579 (Roger Meier)
- Add a cron job and worker to run the Container Expiration Policies. !21593
- Add feature flag override toggle. !21598
- Add 'resource_group' keyword to .gitlab-ci.yml for pipeline job concurrency limitation. !21617
- Add full text search to pod logs. !21656
- Add capability to disable issue auto-close feature per project. !21704 (Fabio Huser)
- Add API for getting sentry error tracking settings of a project. !21788 (raju249)
- Allow a pipeline (parent) to create a child pipeline as downstream pipeline within the same project. !21830
- Add API support for retrieving merge requests deployed in a deployment. !21837
- Add remaining project services to usage ping. !21843
- Add ability to duplicate the common metrics dashboard. !21929
- Custom snowplow events for monitoring alerts. !21963
- Add enable_modsecurity setting to managed ingress. !21966
- Add modsecurity_enabled setting to managed ingress. !21968
- Allow admins to disable users ability to change profile name. !21987
- Allow administrators to enforce access control for all pages web-sites. !22003
- Setup storage for multiple milestones. !22043
- Generate Prometheus sample metrics over pre-set intervals. !22066
- Add tags to sentry detailed error response. !22068
- Extend Design view sidebar with issue link and a list of participants. !22103
- Add Gitlab version and revision to export. !22108
- Add language and error urgency level for Sentry issue details page. !22122
- Document MAVEN_CLI_OPTS defaults for maven project dependency scanning and update when the variable is used. !22126
- Show sample metrics for an environment without prometheus configured. !22133
- Download cross-project artifacts by using needs keyword in the CI file. !22161
- Add GitLab commit to error detail endpoint. !22174
- Container expiration policies can be updated with the project api. !22180
- Allow CI_JOB_TOKENS for Conan package registry authentication. !22184
- Add option to configure branches for which to send emails on push. !22196
- Add a config for disabling CSS and jQuery animations. !22217
- Add API for rollout Elasticsearch per plan level. !22240
- Add retry logic for failures during import. !22265
- Add migrations for version control snippets. !22275
- Update tooltip content for deployment instances. !22289 (Rajendra Kadam)
- Cut and paste Markdown table from a spreadsheet. !22290
- Add CI variable to provide GitLab base URL. !22327 (Aidin Abedi)
- Bump kubeclient version from 4.4.0 to 4.6.0. !22347
- Accept `Envelope-To` as possible location for Service Desk key. !22354 (Max Winterstein)
- Added Conan installation instructions to Conan package details page. !22390
- Add API endpoint for creating a Geo node. !22392 (Rajendra Kadam)
- Link to GitLab commit in Sentry error details page. !22431
- Geo: Check current node in gitlab:geo:check Rake task. !22436
- Add internal API to update Sentry error status. !22454
- Add ability to ignore/resolve errors from error tracking detail page. !22475
- Add informational message about page limits to environments dashboard. !22489
- Add slug to services API response. !22518
- Allow an upstream pipeline to create a downstream pipeline in the same project. !22663
- Display SHA fingerprint for Deploy Keys and extend api to query those. !22665 (Roger Meier <r.meier@siemens.com>)
- Add getDateInFuture util method. !22671
- Detect go when doing dependency scanning. !22712
- Fix aligment for icons on alerts. !22760 (Rajendra Kadam)
- Allow "skip_ci" flag to be passed to rebase operation. !22800
- Add gitlab_commit_path to Sentry Error Details Response. !22803
- Document go support for dependency scanning. !22806
- Implement ability to ignore Sentry errrors from the list view. !22819
- Add ability to create an issue in an epic. !22833
- Drop support for ES5 add support for ES7. !22859
- Add View Issue button to error tracking details page. !22862
- Resolve Design View: Left/Right keyboard arrows through Designs. !22870
- Add Org to the list of available markups for project wikis. !22898 (Alexander Oleynikov)
- Backend for allowing sample metrics to be toggled from ui. !22901
- Display fn, line num and column in stacktrace entry caption. !22905
- Get Project's environment names via GraphQL. !22932
- Filter deployments using the environment & status. !22996
- Assign labels to the GMA and project k8s namespaces. !23027
- Expose mentions_disabled value via group API. !23070 (Fabio Huser)
- Bump cluster-applications image to v0.5.0 (Adds GitLab Runner support). !23110
- Resolve Sentry errors from error tracking list. !23135
- Expose `active` field in the Error Tracking API. !23150
- Track deployed merge requests using GitLab environments and deployments.
- Enable the linking of merge requests to all non review app deployments.
- Add comment_on_event_enabled to services API.

### Other (31 changes, 7 of them are from the community)

- Migrate issue trackers data. !18639
- refactor javascript to remove Immediately Invoked Function Expression from project file search. !19192 (Brian Luckenbill)
- Remove IIFEs from users_select.js. !19290 (minghuan lei)
- Remove milestone_id from epics. !20539 (Lee Tickett)
- Update d3 to 5.12. !20627 (Praveen Arimbrathodiyil)
- Add Ci Resource Group models. !20950
- Display in MR if security report is outdated. !20954
- Fix CI job's scroll down icon and update animation. !21442
- Implement saving config content for pipelines in a new table 'ci_pipelines_config'. !21827
- Display SSL limitations warning for project's pages under namespace that contains dot. !21874
- Updated monaco-editor dependency. !21938
- fix: EKS credentials form does not reset after error. !21958
- Fix regex matching for gemnasium dependency scanning jobs. !22025 (Maximilian Stendler)
- User signout and admin mode disable use now POST instead of GET. !22113 (Diego Louzán)
- Update to clarify slightly misleading tool tip. !22222
- Replace Font Awesome cog icon with GitLab settings icon. !22259
- Drop redundant index on ci_pipelines.project_id. !22325
- Display location in the Security Project Dashboard. !22376
- Add structured logging for application logs. !22379
- Remove ActiveRecord patch to ignore limit on text columns. !22406
- Update Ruby to 2.6.5. !22417
- Log database time in Sidekiq JSON logs. !22548
- Update GitLab Runner Helm Chart to 0.12.0. !22566
- Update project hooks limits to 100 for all plans. !22604
- Update Gitaly to v1.80.0. !22654
- Update GitLab's codeclimate to 0.85.6. !22659 (Takuya Noguchi)
- Updated no commit verbiage. !22765
- Use IS08601.3 format for app level logging of timestamps. !22793
- Upgrade octokit and its dependencies. !22946
- Remove feature flag for import graceful failures.
- Update the Net-LDAP gem to 0.16.2.


## 12.6.7

### Security (1 change)

- Fix ProjectAuthorization calculation for shared groups.


## 12.6.6

### Security (1 change)

- Update workhorse to v8.20.0.


## 12.6.5

### Security (19 changes, 1 of them is from the community)

- Update rack-cors to 1.0.6.
- Update rdoc to 6.1.2.
- Bump rubyzip to 2.0.0. (Utkarsh Gupta)
- Cleanup todos for users from a removed linked group.
- Disable access to last_pipeline in commits API for users without read permissions.
- Add constraint to group dependency proxy endpoint param.
- Limit number of AsciiDoc includes per document.
- Prevent API access for unconfirmed users.
- Enforce permission check when counting activity events.
- Prevent gafana integration token from being displayed as a plain text to other project maintainers, by only displaying a masked version of it.
- Fix xss on frequent groups dropdown.
- Fix XSS vulnerability on custom project templates form.
- Protect internal CI builds from external overrides.
- ImportExport::ExportService to require admin_project permission.
- Make sure that only system notes where all references are visible to user are exposed in GraphQL API.
- Disable caching of repository/files/:file_path/raw API endpoint.
- Make cross-repository comparisons happen in the source repository.
- Update excon to 0.71.1 to fix CVE-2019-16779.
- Add workhorse request verification to package upload endpoints.


## 12.6.4

### Security (1 change)

- Fix private objects exposure when using Project Import functionality.


## 12.6.2

### Security (6 changes)

- GraphQL: Add timeout to all queries.
- Filter out notification settings for projects that a user does not have at least read access.
- Hide project name and path when unsusbcribing from an issue or merge request.
- Fix 500 error caused by invalid byte sequences in uploads links.
- Return only runners from groups where user is owner for user CI owned runners.
- Fix Vulnerability of Release Evidence.


## 12.6.1

### Fixed (2 changes)

- Handle forbidden error when checking for knative. !22170
- Fix stack trace highlight for PHP. !22258

### Performance (1 change)

- Eliminate N+1 queries in PipelinesController#index. !22189


## 12.6.0

### Security (4 changes)

- Update Rugged to v0.28.4.1. !21869
- Update maven_file_name_regex for full string match.
- Add maven file_name regex validation on incoming files.
- Update Workhorse and Gitaly to fix a security issue.

### Removed (1 change)

- Remove downstream pipeline connecting lines. !21196

### Fixed (101 changes, 16 of them are from the community)

- Fix delete user dialog bypass caused by hitting enter. !17343
- Fix broken UI on Environment folder. !17427 (Takuya Noguchi)
- Fix award emoji tooltip being escaped twice if multiple people voted. !19273 (Brian T)
- Use cascading deletes for deleting oauth_openid_requests upon deleting an oauth_access_grant. !19617
- Update merging an MR behavior on the API when pipeline fails. !19641 (briankabiro)
- Vertically align collapse button on epic sidebar. !19656
- Fix projects list to show info in user's locale. !20015 (Arun Kumar Mohan)
- Update padding for cluster alert warning. !20036 (George Tsiolis)
- Show correct warning on issue when project is archived. !20078
- Resets aria-describedby on mouseleave. !20092 (carolcarvalhosa)
- Allow patch notes on repo tags page to word wrap. !20135
- Remove Release edit url for users not allowed to update a release. !20136
- Fix group managed accounts members cleanup. !20157
- Epic tree bug fixes. !20209
- Add missing external-link icon for Crossplane managed app. !20283
- Fixes MR approvers tooltip wrong color. !20287 (Dheeraj Joshi)
- Ignore empty MR diffs when migrating to external storage. !20296
- Add link color to design comments. !20302
- Fix graph groups in monitor dashboard that are hidden on load. !20312
- Update Container Registry naming restrictions to allow for sequential '-'. !20318
- Fixed monitor charts from throwing error when zoomed. !20331
- Validate the merge sha before merging, confirming that the merge will only contain what the user saw. !20348
- Change container registry column name from Tag ID to Image ID. !20349
- Fix dropdown location on the monitoring charts. !20400
- Fixed project import from export ignoring namespace selection. !20405
- Backup: Disable setting of ACL for Google uploads. !20407
- Fix documentation link from empty environment dashboard. !20415
- Move persistent_ref.create into run_after_commit. !20422
- Update external link to provider in cluster settings. !20425
- Fix issue trying to edit weight with collapsed sidebar as guest. !20431
- Handle empty stacktrace and entries with no code. !20458
- Refactor the Deployment model so state machine events are used by both CI and the API. !20474
- Guest users should not delete project snippets they created. !20477
- Accept user-defined dashboard uids in Grafana embeds. !20486
- Fix multi select input padding in project and group user select. !20520 (Kevin Lee)
- Use correct fragment identifier for vulnerability help path. !20524
- Fix group search in groups dropdown. !20535
- Fix removing of child epics that belong to subgroups. !20610
- Fix opening Sentry error details in new tab. !20611
- Ensure next unresolved discussion button takes user to the right place. !20620
- Allow Gitlab GKE clusters to access Google Cloud Registry private images. !20662 (Tan Yee Jian)
- Fix cron parsing for Daylight Savings. !20667
- Fix incorrect new branch name from issue. !20677 (Lee Tickett)
- Improve the way the metrics dashboard waits for data. !20687
- Remove destroy_personal_snippet ability. !20717
- Try longer to clean up after using a gpg-keychain and raise exption if the cleanup fails. !20718
- Fix tooltip hovers in environments table. !20737
- Remove DB transaction from Rebase operation. !20739
- Improve UX for vulnerability dismissal note. !20768
- Fix change to default foreground and backgorund colors in job log. !20787
- Display Labels item in sidebar when Issues are disabled. !20817
- Junit success percentage no longer displays 100% if there are failures. !20835
- Ensure to check create_personal_snippet ability. !20838
- Fix a display bug in the fork removal description message. !20843
- Validate unique environment scope for instance clusters. !20886
- Add empty region when group metrics are missing. !20900
- Adjust issue metrics first_mentioned_in_commit_at calculation. !20923
- Update copy on managed namespace prefixes. !20935
- Add protected branch permission check to run downstream pipelines. !20964
- Fix assignee url in issue board sidebar. !20992 (Lee Tickett)
- Retrieve issues from subgroups when rendering group milestone. !21024
- Adds 409 when user cannot be soft deleted through the API. !21037
- Respect the timezone reported from Gitaly. !21066
- Fix Container repositories can not be replicated when s3 is used. !21068
- Remove redundant toast.scss file and variables. !21105
- Respect snippet query params when displaying embed urls. !21131
- Remove action buttons from designs tab if there are no designs. !21186
- Correctly return stripped PGP text. !21187 (Roger Meier)
- Fix error when linking already linked issue to epic. !21213
- Do not attribute unverified commit e-mails to GitLab users. !21214
- Add nonunique indexes to Labels. !21230
- Fix snippet routes. !21248
- Fix Zoom Quick Action server error when creating a GitLab Issue. !21262
- Rename snippet refactored routes. !21267
- Validate connection section in direct upload config. !21270
- Fix pipeline retry in a CI DAG. !21296
- Authenticate runner requests in Rack::Attack. !21311
- Fix top border of README file header in file list. !21314
- Fix forking a deduplicated project after it was moved to a different shard. !21339
- Fix misaligned approval tr. !21368 (Lee Tickett)
- Fix crash registry contains helm charts. !21381
- Web IDE: Fix the console error that happens when discarding a newly added/uploaded file. !21537
- Authenticate requests with job token as basic auth header for request limiting. !21562
- Fix Single-File-Editor-Layout breaking when branch name is too long. !21577 (Roman Kuba)
- Fix top border of README in vue_file_list. !21578 (Hector Bustillos)
- Stage dropdown lists style corrections. !21607 (Hector Bustillos)
- Change commit_id type on commit_user_mentions table. !21651
- Do not clean the prometheus metrics directory for sidekiq. !21671
- !21542 Part 1: Add new utils for Web IDE store. !21673
- Update auto-deploy-image to v0.8.3. !21696
- Match external user new snippet button visibility to permissions. !21718
- Links to design comments now lead to specific note. !21724
- Re-enable the cloud run feature. !21762
- Ensure forks count cache refresh for source project. !21771
- Fix padding on the design comments. !21839
- Fix "Discard all" for new and renamed files. !21854
- Fix project file finder url encoding file path separators. !21861
- Ensure namespace is present for Managed-Cluster-Applications CI template. !21903
- Rename common template jobs in sast and ds. !22084
- Fixed query behind release filter on merge request search page. !38244
- Activate projects Prometheus service integration when Prometheus managed application is installed on shared cluster.

### Deprecated (4 changes)

- Drop deprecated column from projects table. !18914
- Limit number of projects displayed in GET /groups/:id API. !20023
- Move operations project routes under - scope. !20456
- Move wiki routing under /-/ scope. !21185

### Changed (60 changes, 10 of them are from the community)

- Use better context-specific empty state screens for the Security Dashboards. !18382
- Add evidence collection for Releases. !18874
- Update information and button text for deployment footer. !18918
- Move merge request description into discussions tab. !18940
- Keep details in MR when changing target branch. !19138
- Make internal projects poolable. !19295 (briankabiro)
- Enable support for multiple content query in GraphQL Todo API. !19576
- Allow merge without refresh when new commits are pushed. !19725
- Correct link to Merge trains documentation on MR widget. !19726
- Preserve merge train history. !19864
- Support go-source meta tag for godoc.org. !19888 (Ethan Reesor (@firelizzard))
- Display a better message when starting a discussion on a deleted comment. !20031 (Jacopo Beschi @jacopo-beschi)
- Add sort param to error tracking issue index. !20101
- Add template repository usage to the usage ping. !20126 (minghuan lei)
- Convert flash epic error to form validation error. !20130
- Add 'download' button to Performance Bar. !20205 (Will Chandler)
- SaaS trial copy shows plan. !20207
- Add rbac access to knative-serving namespace deployments to get knative version information. !20244
- Unlock button changed from Icon to String. !20307
- Upgrade to Gitaly v1.72.0. !20313
- Increase upper limit of start_in attribute to 1 week. !20323 (Will Layton)
- Add CI variable to show when Auto-DevOps is explicitly enabled. !20332
- Hashed Storage attachments migration: exclude files in object storage as they are all hashed already. !20338
- Removes caching for design tab discusisons. !20374
- Fixes to inconsistent margins/sapcing in the project detail page. !20395
- Changes to how the search term is styled in the results. !20416
- Move confidence column in the security dashboard. !20435 (Dheeraj Joshi)
- Upgrade to Gitaly v1.73.0. !20443
- Replacing incorrect icon in security dashboard. !20510
- Rework pod logs navigation scheme. !20578
- Reduce start a trial rocket emoji size. !20579
- Upgrade auto-deploy-image for helm default values file. !20588
- Exposed deployment build manual actions for merge request page. !20615
- Upgrade to Gitaly v1.74.0. !20706
- Fetches initial merge request widget data async. !20719
- Add service desk information to project graphQL endpoint. !20722
- Add admin mode controller path to Rack::Attack defaults. !20735 (Diego Louzán)
- Add more filters to SnippetsFinder. !20767
- Clean up the cohorts table. !20779
- Remove vulnerability counter from security tab. !20800
- Only blacklist IPs from Git requests. !20828
- Optimize Deployments endpoint by preloading associations and make record ordering more consistent. !20848
- Update deploy instances color scheme. !20890
- Add service desk information to projects API endpoint. !20913
- Added event tracking to the package details installation components. !20967
- Hide Merge Request information on milestones when MRs are disabled for project. !20985 (Wolfgang Faust)
- Upgrade to Gitaly v1.75.0. !21045
- Evidence - Added restriction for guest on Release page. !21102
- Increase lower DAG `needs` limit from five to ten. !21237
- Add doc links to features on admin dashboard. !21419
- Autofocus cluster dropdown search input. !21440
- Add autofocus to label search fields. !21508
- When a forked project is less visible than its source, merge requests opened in the fork now target the less visible project by default. !21517
- UI improvements in the views for new project from template and the user groups and snippets. !21524 (Hector Bustillos)
- Show merge immediately dialog even if the MR's pipeline hasn't finished. !21556
- Support toggling service desk from API. !21627
- Make `workflow:rules` to work well with Merge Requests. !21742
- Upgrade to Gitaly v1.76.0. !21857
- Remove authentication step from visual review tools instructions.
- Fixes wording on runner admin.

### Performance (22 changes)

- Optimize query for CI pipelines of merge request. !19653
- Replace index on environments table project_id and state with project_id, state, and environment_type. !19902
- Remove reactive caching value keys once the alive key has expired. !20111
- Suggest squash commit messages based on recent commits. !20231
- Improve performance of /api/:version/snippets/public API and only return public personal snippets. !20339
- Add limit for snippet content size. !20346
- Reduce Gitaly calls in BuildHooksWorker. !20365
- Enable ETag caching for MR notes polling. !20440
- Disable public project counts on welcome page. !20517
- Optimize query when Projects API requests private visibility level. !20594
- Improve issues search performance on GraphQL. !20784
- UpdateProjectStatistics updates after commit. !20852
- Run housekeeping after moving a repository between shards. !20863
- Require group_id or project_id for MR target branch autocomplete action. !20933
- Cache the ancestor? Gitaly call to speed up polling for the merge request widget. !20958
- Optimize loading the repository deploy keys page. !20970
- Added lightweight check when retrieving Prometheus metrics. !21099
- Limit max metrics embeds in GFM to 100. !21356
- Fork Puma to validate scheduler fixes. !21547
- Remove an N+1 call rendering projects search results. !21626
- Skip updating LFS objects in mirror updates if repository has not changed. !21744
- Add indexes on deployments to improve environments search. !21789

### Added (119 changes, 18 of them are from the community)

- Add upvote/downvotes attributes to GraphQL Epic query. !14311
- Delete kubernetes cluster association and resources. !16954
- Add badge name field. !16998 (Lee Tickett)
- Add OmniAuth authentication support to admin mode feature. !18214 (Diego Louzán)
- Creates DB tables for storing mentioned users, groups, projects referenced in a note or issuable description. !18316
- Add body data elements for pageview context. !18450
- Added filtering of inherited members for subgroups. !18842
- Added responsiveness to audit events table. !18859
- Add ability to make Jira comments optional. !19004
- Store users, groups, projects mentioned in Markdown to DB tables. !19088
- Upgrade `mail_room` gem to 0.10.0 and enable structured logging. !19186
- Add possibility to save max issue weight on lists. !19220
- Return 422 status code in case of error in submitting comments. !19276 (raju249)
- Add Personal Access Token expiration reminder. !19296
- Add recent search to error tracking. !19301
- Resolve Limit the number of stored sessions per user. !19325
- Add services for 'soft-delete for groups' feature. !19358
- Notify user when over 1000 epics in roadmap. !19419
- Search list of Sentry errors by title in GitLab. !19439
- Add issue statistics to releases on the Releases page. !19448
- Add snowplow events for monitoring dashboard. !19455
- Add snowplow events for APM. !19463
- Add GraphQL mutation to mark all todos done for a user. !19482
- Added rules configuration for Ci::Bridge. !19605
- Add workers for 'soft-delete for groups' feature. !19679
- add tagger within tag view. !19681 (Roger Meier)
- Strong validate import export references. !19682
- Update Release API with evidence related data. !19706
- Graphql query for issues can now be sorted by weight. !19721
- GraphQL for Sentry rror details. !19733
- View closed issues in epic. !19741
- Add API endpoint to unpublish GitLab Pages. !19781
- Add Pipeline Metadata to Packages. !19796
- Create data model for serverless domains. !19835
- Add Unify Circuit project integration service. !19849 (Fabio Huser)
- add sha256 fingerprint to keys model, view and extend users API to search user via fingerprint. !19860 (Roger Meier)
- Allow order_by updated_at in Pipelines API. !19886
- Implement pagination for project releases page. !19912 (Fabio Huser)
- Add migrations for secret snippets. !19939
- Control passing artifacts from CI DAG needs. !19943
- Genereate a set of sample prometheus metrics and route to the sample metrics when enabled. !19987
- Add warning dialog when users click the "Merge immediately" merge train option. !20054
- Expose moved_to_id in issues API. !20083 (Lee Tickett)
- Relate issues when they are marked as duplicated. !20161 (minghuan lei)
- Asks for confirmation before changing project visibility level. !20170
- Allow CI config path to point to a URL or file in a different repository. !20179
- Allow groups to disable mentioning their members, if the group is mentioned. !20184 (Fabio Huser)
- Add modsecurity deployment counts to usage ping. !20196
- Added legend to deploy boards. !20208
- Support passing CI variables via git push options. !20255
- Add GraphQL mutation to restore a Todo. !20261
- Allow specifying Kubernetes namespace for an environment in gitlab-ci.yml. !20270
- Add migrations for 'soft-delete for groups' feature. !20276
- Add Maven installation commands to package detail page for Maven packages. !20300
- Add feature to allow specifying userWithId strategies per environment spec. !20325
- Enable creating Amazon EKS clusters from GitLab. !20333
- Add ability to create new issue from sentry error detail page. !20337
- Convert flash alerts to toasts. !20356
- Return project commit url instead of commits url. !20369 (raju249)
- Collect the date a SaaS trial starts on. !20384
- Add option to delete cached Kubernetes namespaces. !20411
- Create container expiration policies for projects. !20412
- Adjust fork network relations upon project visibility change. !20466
- Create a license info rake task. !20501 (Jason Colyer)
- Add GraphQL mutation for changing due date of an issue. !20577
- Add Snippet GraphQL resolver endpoints. !20613
- Allow Job-Token authentication on Releases creation API. !20632
- Add created_before/after filter to group/project audit events. !20641
- Allow searching of projects by full path. !20659
- Allow administrators to set a minimum password length. !20661
- Update helper text for sentry error tracking settings. !20663 (Rajendra Kadam)
- Adds ability to create issues from sentry details page. !20666
- Add coverage difference visualization to merge request page. !20676 (Fabio Huser)
- Use CI configured namespace for deployments to unmanaged clusters. !20686
- Resolve Design view: Download single issue design image. !20703
- Import large gitlab_project exports via rake task. !20724
- Added Total/Frontend metrics to the performance bar. !20725
- Add dependency scanning flag for skipping automatic bundler audit update. !20743
- Add GraphQL mutation for setting an issue as confidential. !20785
- Track adding metric via monitoring dashboard. !20818
- Add _links object to package api response. !20820
- CI template for installing cluster applications. !20822
- Add SalesforceDX project template. !20831
- Allow NPM package downloads with CI_JOB_TOKEN. !20868
- Allow raw blobs to be served from an external storage. !20936
- Added Snippets GraphQL mutations. !20956
- Added WebHookLogs for ServiceHooks. !20976
- Surface GitLab issue in error detail page. !21019
- Add type to broadcast messages. !21038
- add OpenAPI file viewer. !21106 (Roger Meier)
- Add updated_before and updated_after filters to the Pipelines API endpoint. !21133
- Implement pagination for sentry errors. !21136
- Add support for Conan package management in the package registry. !21152
- Add syntax highlight for Sentry error stack trace. !21182
- Keyset pagination for REST API (Project endpoint). !21194
- CI template for Sentry managed app. !21208
- Add CI variable to set the version of pip when scanning dependencies of Python projects. !21218
- Add dependency scanning flag for specifying pip requirements file for scanning. !21219
- Do not allow specifying a Kubernetes namespace via CI template for managed clusters. !21223
- Sort Sentry error list by first seen, last seen or frequency. !21250
- Add documentation about dependency scanning gradle support. !21253
- Allow PDF attachments to be opened on browser. !21272
- Add child label to commit box. !21323
- Update Knative to 0.9.0. !21361 (cab105)
- Add target_path to broadcast message API. !21430
- Allow Kubernetes namespaces specified via CI template to be used for terminals, pod logs and deploy boards. !21460
- Allow styling broadcast messages. !21522
- Enable new job log by default. !21543
- Document support for sbt dependency scanning. !21588
- Return multiple errors from CI linter. !21589
- Add specific error states to dashboard. !21618
- Add timestamps to pod logs. !21663
- Hide profile information when user is blocked. !21706
- link to group on group admin page. !21709
- Added migration which adds service desk username column. !21733
- Add SentryIssue table to store a link between issue and sentry issue. !37026
- Add path based targeting to broadcast messages.
- Add allow failure in pipeline webhook event. !20978 (Gaetan Semet)
- Add runner information in build web hook event. !20709 (Gaetan Semet)

### Other (51 changes, 28 of them are from the community)

- Remove done callbacks from vue_shared/components/markdown. !16842 (Lee Tickett)
- Update timeago to the latest release. !19407
- Improve job tokens and provide access helper. !19793
- Add post deployment migration to complete pages metadata migration. !19928
- Resolve Document - Make using GitLab auth with Vault easy. !19980
- Remove IIFEs from gl_dropdown.js. !19983 (nuwe1)
- Improve sparkline chart in MR widget deployment. !20085
- Updated jekyll project_template. !20090 (Marc Schwede)
- Updated hexo project_template. !20105 (Marc Schwede)
- Updated hugo project_template. !20109 (Marc Schwede)
- Resolve environment rollback was not friendly. !20121
- Removed all references of BoardService. !20144 (nuwe1)
- Removes references of BoardService in list file. !20145 (nuwe1)
- replace var gl_dropdown.js. !20166 (nuwe1)
- delete board_service.js. !20168 (nuwe1)
- Improve create confidential MR dropdown styling. !20176 (Lee Tickett)
- Remove milestone_id from epics. !20187 (Lee Tickett)
- Remove build badge path from route. !20188 (Lee Tickett)
- Add worker attributes to Sidekiq metrics. !20292
- Update GitLab Runner Helm Chart to 0.11.0. !20461
- add missing test for add_index rubocop rule. !20464 (Eric Thomas)
- Suppress progress on pulling image on Code Quality of Auto DevOps. !20604 (Takuya Noguchi)
- Increase margin between project stats. !20606
- Remove extra spacing below sidebar time tracking info. !20657 (Lee Tickett)
- Add e2e qa test for email delivery. !20675 (Diego Louzán)
- Collect project import failures instead of failing fast. !20727
- Removed unused methods in monitoring dashboard. !20819
- removes references of BoardService. !20872 (nuwe1)
- removes references of BoardService. !20874 (nuwe1)
- removes references of BoardService. !20875 (nuwe1)
- removes references of BoardService. !20876 (nuwe1)
- removes references of BoardService. !20877 (nuwe1)
- removes references of BoardService. !20879 (nuwe1)
- removes references of BoardService. !20880 (nuwe1)
- removes references of BoardService. !20881 (nuwe1)
- Remove whitespaces between tree-controls elements. !20952
- Add Project Export request/download rate limits. !20962
- Remove feature flag for limiting diverging commit counts. !20999
- Changed 'Add approvers' to 'Approval rules'. !21079
- Resolve Add missing popover and remove none in MR widget. !21095
- Change Puma log format to JSON. !21101
- Update GitLab Shell to v10.3.0. !21151
- Improve diff expansion text. !21616
- Remove var from app/assets/javascripts/commit/image_file.js. !21649 (Abubakar Hassan)
- Rename User#full_private_access? to User#can_read_all_resources?. !21668 (Diego Louzán)
- Replace CI_COMMIT_REF with CI_COMMIT_SHA on CI docs. !21781 (Takuya Noguchi)
- Add reportSnippet permission to Snippet GraphQL. !21836
- Harmonize capitalization on cluster UI. !21878 (Evan Read)
- Add mark as spam snippet mutation. !21912
- Update Workhorse to v8.18.0. !22091
- Replace Font Awesome bullhorn icon with GitLab bullhorn icon.


## 12.5.8

### Security (19 changes, 1 of them is from the community)

- Prevent gafana integration token from being displayed as a plain text to other project maintainers, by only displaying a masked version of it.
- Update rdoc to 6.1.2.
- Bump rubyzip to 2.0.0. (Utkarsh Gupta)
- Cleanup todos for users from a removed linked group.
- Disable access to last_pipeline in commits API for users without read permissions.
- Add constraint to group dependency proxy endpoint param.
- Limit number of AsciiDoc includes per document.
- Prevent API access for unconfirmed users.
- Enforce permission check when counting activity events.
- Update rack-cors to 1.0.6.
- Fix xss on frequent groups dropdown.
- Fix XSS vulnerability on custom project templates form.
- Protect internal CI builds from external overrides.
- ImportExport::ExportService to require admin_project permission.
- Make sure that only system notes where all references are visible to user are exposed in GraphQL API.
- Disable caching of repository/files/:file_path/raw API endpoint.
- Make cross-repository comparisons happen in the source repository.
- Update excon to 0.71.1 to fix CVE-2019-16779.
- Add workhorse request verification to package upload endpoints.

### Changed (1 change, 1 of them is from the community)

- Add template repository usage to the usage ping. !20126 (minghuan lei)


## 12.5.5

### Security (1 change)

- Upgrade Akismet gem to v3.0.0. !21786

### Fixed (2 changes)

- Fix error in updating runner session. !20902
- Fix Asana integration. !21501


## 12.5.4

### Security (1 change)

- Update maven_file_name_regex for full string match.


## 12.5.3

### Fixed (4 changes)

- Fix project creation with templates using /projects/user/:id API. !20590
- Fix merging merge requests from push options. !20639
- Fix Crossplane help link in cluster applications page. !20668
- Fixes job log not scrolling to the bottom.

### Changed (1 change)

- Flatten exception details in API and controller logs. !20434


## 12.5.1

### Security (11 changes)

- Do not create todos for approvers without access. !1442
- Hide commit counts from guest users in Cycle Analytics.
- Encrypt application setting tokens.
- Update Workhorse and Gitaly to fix a security issue.
- Add maven file_name regex validation on incoming files.
- Check permissions before showing a forked project's source.
- Limit potential for DNS rebind SSRF in chat notifications.
- Ensure are cleaned by ImportExport::AttributeCleaner.
- Remove notes regarding Related Branches from Issue activity feeds for guest users.
- Escape namespace in label references to prevent XSS.
- Add authorization to using filter vulnerable in Dependency List.


## 12.5.0

### Security (15 changes)

- Enable the HttpOnly flag for experimentation_subject_id cookie. !19189
- Update incrementing of failed logins to be thread-safe. !19614
- Sanitize all wiki markup formats with GitLab sanitization pipelines.
- Sanitize search text to prevent XSS.
- Remove deploy access level when project/group link is deleted.
- Mask sentry auth token in Error Tracking dashboard.
- Return 404 on LFS request if project doesn't exist.
- Don't leak private members in project member autocomplete suggestions.
- Require Maintainer permission on group where project is transferred to.
- Don't allow maintainers of a target project to delete the source branch of a merge request from a fork.
- Disallow unprivileged users from commenting on private repository commits.
- Analyze incoming GraphQL queries and check for recursion.
- Show cross-referenced label and milestones in issues' activities only to authorized users.
- Do not display project labels that are not visible for user accessing group labels.
- Standardize error response when route is missing.

### Fixed (100 changes, 15 of them are from the community)

- Fix incorrect selection of custom templates. !17205
- Smaller width for design comments layout, truncate image title. !17547
- Correctly cleanup orphan job artifacts. !17679 (Adam Mulvany)
- Add Infinite scroll to Add Projects modal in the operations dashboard. !17842
- Allow emojis to be linkable. !18014
- Enable image link and lazy loading in AsciiDoc documents. !18164 (Guillaume Grossetie)
- Expose prometheus status to monitor dashboard. !18289
- Time limit the database lock when rebasing a merge request. !18481
- Fix missing admin mode UI buttons on bigger screen sizes. !18585 (Diego Louzán)
- Abort only MWPS when FF only merge is impossible. !18591
- Remove pointer cursor from MemoryUsage chart on MR widget deployment. !18599
- Fix keyboard shortcuts in header search autocomplete. !18685
- Fix empty chart in collapsed sections. !18699
- Fix error when viewing group billing page. !18740
- Fix query validation in custom metrics form. !18769
- Fix Gitaly call duration measurements. !18785
- Resolve Error when uploading a few designs in a row. !18811
- Block MR with OMIPS on skipped pipelines. !18838
- Pipeline vulnerability dashboard sort vulnerabilities by severity then confidence. !18863
- Remove empty Github service templates from database. !18868
- Fix broken images when previewing markdown files in Web IDE. !18899
- fixed #27164 Image cannot be collapsed on merge request changes tab. !18917 (Jannik Lehmann)
- Let ANSI \r code replace the current job log line. !18933
- Fix serverless function descriptions not showing on Knative 0.7. !18973
- Fix "project or group was moved" alerts showing up in the wrong pages. !18985
- Add missing breadcrumb in Project > Settings > Integrations. !18990
- Fixed admin geo collapsed sidebar fly out not showing. !19012
- Serialize short sha as nil if head commit is blank. !19014
- Add max width on manifest file attachment input. !19028
- Do not generate To-Dos additional when editing group mentions. !19037
- Fix previewing quick actions for epics. !19042
- Fix errors in GraphQL Todos API due to missing TargetTypeEnum values. !19052
- Hashed Storage Migration: Handle failed attachment migrations with existing target path. !19061
- Set shorter TTL for all unauthenticated requests. !19064
- Fix Todo IDs in GraphQL API. !19068
- Triggers the correct endpoint on licence approval. !19078
- Fix search button height on 404 page. !19080
- Fix Kubernetes help text link. !19121
- Make `jobs/request` to be resillient. !19150
- Disable pull mirror if repository is in read-only state. !19182
- Only enable protected paths for POST requests. !19184
- Enforce default, global project and snippet visibilities. !19188
- Make Bitbucket Cloud superseded pull requests as closed. !19193
- Fix crash when docker fails deleting tags. !19208
- Fix environment name in rollback dialog. !19209
- Fixed a typo in the "Keyboard Shortcuts" pop-up. !19217 (Manuel Stein)
- Fix unable to expand or collapse files in merge request by clicking caret. !19222 (Brian T)
- Allow release block edit button to be visible. !19226
- Fix double escaping in /tableflip quick action. !19271 (Brian T)
- Add missing bottom padding in CI/CD settings. !19284 (George Tsiolis)
- Prevents console warning on design upload. !19297
- Resolve: Web IDE does not create POSIX Compliant Files. !19339
- Use initial commit SHA instead of branch id to request IDE files and contents. !19348 (David Palubin)
- Resolve: Web IDE Throws Error When Viewing Diff for Renamed Files. !19348
- Fix project service API 500 error. !19367
- Fix cluster feature highlight popover image. !19372
- Fix template selector filename bug. !19376
- Fixes mobile styling issues on security modals. !19391
- Only move repos for legacy project storage. !19410
- Show correct total number of commit diff's changes. !19424
- Increase the timeout for GitLab-managed cert-manager installation to 90 seconds (was 30 seconds). !19447
- Fix uninitialized constant SystemDashboardService. !19453
- Properly handle exceptions in StuckCiJobsWorker. !19465
- Fix user popover not being displayed when the user has a status message. !19519
- Update omniauth_openid_connect to v0.3.3. !19525
- Fix project clone dropdown button width. !19551 (George Tsiolis)
- Do not escape HTML tags in Ansi2json as they are escaped in the frontend. !19610
- [Geo] Fix: undefined Gitlab::BackgroundMigration::PruneOrphanedGeoEvents. !19638
- Revert btn-xs styling in projects scss. !19640
- Fix canary badge and favicon inconsistency. !19645
- Use fingerprint when comparing security reports in MR widget. !19654
- Update GCP credit URLs. !19683
- Update squash_commit_sha only on successful merge. !19688
- Fix import of snippets having `award_emoji` (Project Export/Import). !19690
- Allow admins to administer personal snippets. !19693 (Oren Kanner)
- Re-add missing file sizes in 2-Up diff file viewer. !19710
- Fix checking task item when previous tasks contain only spaces. !19724
- Fix Bitbucket Cloud importer pull request state. !19734
- Fix merge train is not refreshed when the system aborts/drops a merge request. !19763
- Resolve Hide Delete selected in designs when viewing an old version. !19889
- Use new trial registration URL in billing. !19978
- Helm v2.16.1. !19981
- Ensure milestone titles are never empty. !19985
- Remove unused image/screenshot. !20030 (Lee Tickett)
- Remove local qualifier from geo sync indicators. !20034 (Lee Tickett)
- Fixed the scale of embedded videos to fit the page. !20056
- Fix broken monitor cluster health dashboard. !20120
- Fix expanding collapsed threads when reference link clicked. !20148
- Fix sub group export to export direct children. !20172
- Remove update hook from date filter to prevent js from getting stuck. !20215
- Prevent Dropzone.js initialisation error by checking target element existence. !20256 (Fabio Huser)
- Fix style reset in job log when empty ANSI sequence is encoutered. !20367
- Add productivity analytics merge date filtering limit. !32052
- Fix productivity analytics listing with multiple labels. !33182
- Fix closed board list loading issue.
- Apply correctly the limit of 10 designs per upload.
- Only allow confirmed users to run pipelines.
- Fix scroll to bottom with new job log.
- Fixed protected branches flash styling.
- Show tag link whenever it's a tag in chat message integration for push events and pipeline events. !18126 (Mats Estensen)

### Deprecated (2 changes)

- Ignore deprecated column and remove references to it. !18911
- Move some project routes under - scope. !19954

### Changed (56 changes, 6 of them are from the community)

- Upgrade design/copy for issue weights locked feature. !17352
- Reduce new MR page redundancy by moving the source/target branch selector to the top. !17559
- Replace raven-js with @sentry/browser. !17715
- Ask if the user is setting up GitLab for a company during signup. !17999
- When a user views a file's blame or blob and switches to a branch where the current file does not exist, they will now be redirected to the root of the repository. !18169 (Jesse Hall @jessehall3)
- Propagate custom environment variables to SAST analyzers. !18193
- Fix any approver project rule records. !18265
- Minor UX improvements to Environments Dashboard page. !18280
- Reduce the allocated IP for Cluster and Services. !18341
- Update flash messages color sitewide. !18369
- Add modsecurity template for ingress-controller. !18485
- Hide projects without access to admin user when admin mode is disabled. !18530 (Diego Louzán)
- Update Runners Settings Text + Link to Docs. !18534
- Store Zoom URLs in a table rather than in the issue description. !18620
- Improve admin dashboard features. !18666
- Drop `id` column from `ci_build_trace_sections` table. !18741
- Truncate recommended branch name to a sane length. !18821
- Add support for YAML anchors in CI scripts. !18849
- Save dashboard changes by the user into the vuex store. !18862
- Update expired trial status copy. !18962
- Can directly add approvers to approval rule. !18965
- Rename Vulnerabilities API to Vulnerability Findings API. !19029
- Improve clarity of text for merge train position. !19031
- Updated Auto-DevOps to kubectl v1.13.12 and helm v2.15.1. !19054 (Leo Antunes)
- Refactor maximum user counts in license. !19071 (briankabiro)
- Change return type of getDateInPast to Date. !19081
- Show approval required status in license compliance. !19114
- Handle new Container Scanning report format. !19123
- Allow container scanning to run offline by specifying the Clair DB image to use. !19161
- Add maven cli opts flag to maven security analyzer (part of dependency scanning). !19174
- Added report_type attribute to Vulnerabilities. !19179
- Migrate enabled flag on grafana_integrations table. !19234
- Improve handling of gpg-agent processes. !19311
- Update help text of "Tag name" field on Edit Release page. !19321
- Add user filtering to abuse reports page. !19365
- Move add license button to project buttons. !19370
- Update to Mermaid v8.4.2 to support more graph types. !19444
- Move release meta-data into footer on Releases page. !19451
- Expose subscribed field in issue lists queried with GraphQL. !19458 (briankabiro)
- [Geo] Fix: rake gitlab:geo:check on the primary is cluttered. !19460
- Hide trial banner for namespaces with expired trials. !19510
- Hide repeated trial offers on self-hosted instances. !19511
- Add loading icon to error tracking settings page. !19539
- Upgrade to Gitaly v1.71.0. !19611
- Make role required when editing profile. !19636
- Made `name` optional parameter of Release entity. !19705
- Vulnerabilities history chart - use sparklines. !19745
- Add event tracking to container registry. !19772
- Update SaaS trial header to include the tier Gold. !19970
- Update start a trial option in top right drop down to include Gold. !19971
- Improve merge request description placeholder. !20032 (Jacopo Beschi @jacopo-beschi)
- Add backtrace to production_json.log. !20122
- Change the default concurrency factor of merge train to 20. !20201
- Upgrade to Gitaly v1.72.0.
- Require explicit null parameters to remove pages domain certificate and allow to use Let's Encrypt certificates through API.
- Replace wording trace with log.

### Performance (13 changes)

- Record latencies for Sidekiq failures. !18909
- Fix N+1 for group container repositories view. !18979
- Do not render links in commit message on blame page. !19128
- Puma only: database connection pool now always >= number of worker threads. !19286
- Run check_mergeability only if merge status requires it. !19364
- Execute limited request for diff commits instead of preloading. !19485
- Improve performance of admin/abuse_reports page. !19630
- Remove N+1 DB calls from branches API. !19661
- Improve performance of linking LFS objects during import. !19709
- Optimize MergeRequest#mergeable_discussions_state? method. !19988
- Add index for unauthenticated requests to projects API default endpoint. !19989
- Add index for authenticated requests to projects API default endpoint. !19993
- Increase PumaWorkerKiller memory limit in development environment. !20039

### Added (83 changes, 8 of them are from the community)

- Adds Application Settings and ui settings in the integration admin area for Pendo. !15086
- Add endpoint for a group's vulnerable projects. !15317
- Added new chart component to display an anomaly boundary. !16530
- Add links to associated releases on the Milestones page. !16558
- Merge Details Page and Edit Page for Page Domains. !16687
- Share groups with groups. !17117
- Add links to associated release(s) to the milestone detail page. !17278
- New group path uniqueness check. !17394
- Unify html email layout for member html emails. !17699 (Diego Louzán)
- The Security Dashboard displays DAST vulnerabilities for all the scanned sites, not just the first. !17779
- Create table for elastic stack. !18015
- Allow to define a default CI configuration path for new projects. !18073 (Mathieu Parent)
- Issues queried in GraphQL now sortable by due date. !18094
- Add cleanup status to clusters. !18144
- Added Tests tab to pipeline detail that contains a UI for browsing test reports produced by JUnit. !18255
- Users can verify SAML configuration and view SamlResponse XML. !18362
- Support Enable/Disable operations in Feature Flag API. !18368
- Expose arbitrary job artifacts in Merge Request widget. !18385
- Add project option for deleting source branch. !18408 (Zsolt Kovari)
- Adds ability to set management project for cluster via API. !18429
- Close issues on Prometheus alert recovery. !18431
- Add ApplicationSetting for snowplow_iglu_registry_url. !18449
- Allow Grafana charts to be embedded in Gitlab Flavored Markdown. !18486
- Mark todo done by GraphQL API. !18581
- Create a users_security_dashboard_projects table to store the projects a user has added to their personal security dashboard. !18708
- New API endpoint for creating anonymous merge request discussions from Visual Review Tools. !18710
- Enable the color chip in AsciiDoc documents. !18723
- Add prevent_ldap_sign_in option so LDAP can be used exclusively for sync. !18749
- Show inherited group variables in project view. !18759
- Add "release" filter to issue search page. !18761
- Search list of Sentry errors by title in Gitlab. !18772
- Add migrations and changes for soft-delete for projects. !18791
- Support for Crossplane as a managed app. !18797 (Mahendra Bagul)
- Bump Auto-Deploy image to v0.3.0. !18809
- Set X-GitLab-NotificationReason header if notification reason is explicit subscription. !18812
- Add issues, MRs, participants, and labels tabs in group milestone page. !18818
- Add ability to reorder projects on operations dashboard. !18855
- Make `Job`, `Bridge` and `Default` inheritable. !18867
- Show epic events on group activity page. !18869
- Detail view of Sentry error in GitLab. !18878
- Expose mergeable state of a merge request. !18888 (briankabiro)
- Add ability to select a Cluster management project. !18928
- Add a Slack slash command to add a comment to an issue. !18946
- Added installation commands for npm and yarn packages to package detail page. !18999
- Show start and end dates in Epics list page. !19006
- Populate new pipeline CI vars from params. !19023
- Add warnings about pages access control settings. !19067
- Graphql mutation for (un)subscribing to an epic. !19083
- API for stack trace & detail view of Sentry error in GitLab. !19137
- Add grafana integration active status checkbox. !19255
- GraphQL: Add Merge Request milestone mutation. !19257
- Add MergeRequestSetAssignees GraphQL mutation. !19272
- Add edit button to metrics dashboard. !19279
- Add "release" filter to merge request search page. !19315
- Add dead jobs to Sidekiq metrics API. !19350 (Marco Peterseil)
- Add pipeline information to dependency list header. !19352
- Build CI cache key from commit SHAs that changed given files. !19392
- Adding support for searching tags using '^' and '$'. !19435 (Cauhx Milloy)
- Sentry error stacktrace. !19492
- Add an `error_code` attribute to the API response when a cherry-pick or revert fails. !19518
- Add documentation for sign-in application setting. !19561 (Horatiu Eugen Vlad)
- Create AWS EKS cluster. !19578
- Add modsecurity logging sidecar to ingress controller. !19600
- Add start a trial option in the top-right user dropdown. !19632
- Manage and display labels from epic in the GraphQL API. !19642
- Allow order_by updated_at in Deployments API. !19658
- Add can_edit and project_blob_path to metrics_dashboard endpoint. !19663
- Add usage ping data for project services. !19687
- Graphql query for issues can now be sorted by relative_position. !19713
- Add API endpoint to trigger Group Structure Export. !19779
- Show Tree UI containing child Epics and Issues within an Epic. !19812
- Enable environments dashboard by default. !19838
- Update the DB schema to allow linking between Vulnerabilities and Issues. !19852
- Add Group Audit Events API. !19868
- Adds a copy button next to package metadata on the details page. !19881
- GraphQL: Create MR mutations needed for the sidebar. !19913
- Add id_before, id_after filter param to projects API. !19949
- Add modsecurity feature flag to usage ping. !20194
- Specify management project for a Kubernetes cluster. !20216
- Upgrade pages to 1.12.0. !20217
- Support template_project_id parameter in project creation API. !20258
- Add heatmap chart support. !32424
- Add template for Serverless Framework/JS. !33805

### Other (59 changes, 26 of them are from the community)

- Add EKS cluster count to usage data. !17059
- Track the starting and stopping of the current signup flow and the experimental signup flow. !17521
- Attribute Sidekiq workers according to their workloads. !18066
- Add ApplicationSetting entries for EKS integration. !18307
- Geo: Add resigns-related fields to Geo Node Status table. !18379
- Allow adding requests to performance bar manually. !18464
- Removes `export_designs` feature flag. !18507 (nate geslin)
- Update AWS SDK to 2.11.374. !18601
- Remove required dependecy of Postgresql for Gitaly. !18659
- Add deployment_merge_requests table. !18755
- Bump Gitaly to 1.70.0 and remove cache invalidation feature flag. !18766
- Update gRPC to v1.24.0. !18837
- Update GitLab Runner Helm Chart to 0.10.0. !18879
- Adds a Sidekiq queue duration metric. !19005
- Create explicit Default and Free plans. !19033
- Improve instance mirroring help text. !19047
- Add Codesandbox metrics to usage ping. !19075
- Add internal_socket_dir to gitaly config in setup helper. !19170
- Use Rails 5.2 Redis caching store. !19202
- Update GitLab Runner Helm Chart to 0.10.1. !19232
- Rename snowplow_site_id to snowplow_app_id in application_settings table. !19252
- Removed IIFEs from network.js file. !19254 (nuwe1)
- Remove IIFEs from project_select.js. !19288 (minghuan lei)
- Remove IIFEs from merge_request.js. !19294 (minghuan lei)
- Make snippet list easier to scan. !19490
- Removed IIFEs from image_file.js. !19548 (nuwe1)
- Fix api docs for deleting project cluster. !19558
- Change blob edit view button styling. !19566
- Include exception and backtrace in API logs. !19671
- Add index on marked_for_deletion_at in projects table. !19788
- Visual design for edit buttons in blob view. !19932
- Refactor disabled sidebar notifications to Vue. !20007 (minghuan lei)
- Remove IIFEs from branch_graph.js. !20008 (minghuan lei)
- Remove IIFEs from new_branch_form.js. !20009 (minghuan lei)
- Remove duplication from slugifyWithUnderscore function. !20016 (Arun Kumar Mohan)
- Update registry.gitlab.com/gitlab-org/security-products/codequality to 12-5-stable. !20046 (Takuya Noguchi)
- Add mb-2 class to global alerts. !20081 (2knal)
- Remove var from syntax_highlight_spec.js. !20086 (Lee Tickett)
- Remove var from merge_request_tabs_spec.js. !20087 (Lee Tickett)
- Remove var from bootstrap_jquery_spec.js. !20089 (Lee Tickett)
- Remove var from project_select.js. !20091 (Lee Tickett)
- Remove var from new_commit_form.js. !20095 (Lee Tickett)
- Remove var from issue.js. !20098 (Lee Tickett)
- Remove var from new_branch_form.js. !20099 (Lee Tickett)
- Remove var from tree.js. !20103 (Lee Tickett)
- Remove var from line_highlighter.js. !20108 (Lee Tickett)
- Remove var from preview_markdown.js. !20115 (Lee Tickett)
- remove all references of BoardService in boards_selector.vue. !20147 (nuwe1)
- Remove all references to BoardsService in index.vue. !20152 (nuwe1)
- Remove var from labels_select.js. !20153 (Lee Tickett)
- Remove all reference to BoardService in board_form.vue. !20158 (nuwe1)
- Remove calendar icon from personal access tokens. !20183
- Move margin-top from flash container to flash. !20211
- Bump Auto DevOps deploy image to v0.7.0. !20250
- Make 'Sidekiq::Testing.fake!' mode as default. !31662 (@blackst0ne)
- Replace task-done icon with list-task icon to better align with other toolbar list icons.
- Dependency Scanning template that doesn't rely on Docker-in-Docker.
- Adding dropdown arrow icon and updated text alignment.
- Change selects from default browser style to custom style.


## 12.4.8

### Security (1 change)

- Fix private objects exposure when using Project Import functionality.


## 12.4.5

- No changes.

## 12.4.3

### Fixed (2 changes)

- Only enable protected paths for POST requests. !19184
- Fix Bitbucket Cloud importer pull request state. !19734


## 12.4.2

### Fixed (10 changes)

- Increase timeout for FetchInternalRemote RPC call. !18908
- Clean up duplicate indexes on ci_trigger_requests. !19053
- Fix project imports not working with serialized data. !19124
- Fixed welcome screen icons not showing. !19148
- Disable protected path throttling by default. !19185
- Fix Prometheus duplicate metrics. !19327
- Fix ref switcher not working on Microsoft Edge. !19335
- Extend gRPC timeouts for Rake tasks. !19461
- Disable upload HTTP caching to fix case when object storage is enabled and proxy_download is disabled. !19494
- Removes arrow icons for old collapsible sections.

### Changed (2 changes)

- Increased deactivation threshold to 180 days. !18902
- Add extra sentence about registry to AutoDevOps popup. !19092


## 12.4.1

### Security (14 changes)

- Standardize error response when route is missing.
- Do not display project labels that are not visible for user accessing group labels.
- Show cross-referenced label and milestones in issues' activities only to authorized users.
- Show cross-referenced label and milestones in issues' activities only to authorized users.
- Analyze incoming GraphQL queries and check for recursion.
- Disallow unprivileged users from commenting on private repository commits.
- Don't allow maintainers of a target project to delete the source branch of a merge request from a fork.
- Require Maintainer permission on group where project is transferred to.
- Don't leak private members in project member autocomplete suggestions.
- Return 404 on LFS request if project doesn't exist.
- Mask sentry auth token in Error Tracking dashboard.
- Fixes a Open Redirect issue in `InternalRedirect`.
- Remove deploy access level when project/group link is deleted.
- Sanitize all wiki markup formats with GitLab sanitization pipelines.


## 12.4.0

### Security (14 changes)

- HTML-escape search term in empty message. !18319
- Fix private feature Elasticsearch leak.
- Prevent bypassing email verification using Salesforce.
- Fix new project path being disclosed through unsubscribe link of issue/merge requests.
- Do not show resource label events referencing not accessible labels.
- Check permissions before showing head pipeline blocking merge requests.
- Cancel all running CI jobs triggered by the user who is just blocked.
- Do not disclose project milestones on group milestones page when project milestones access is disabled in project settings.
- Display only participants that user has permission to see on milestone page.
- Fix Gitaly SearchBlobs flag RPC injection.
- Add a policy check for system notes that may not be visible due to cross references to private items.
- Limit search for IID to a type to avoid leaking records with the same IID that the user does not have access to.
- Prevent GitLab accounts takeover if SAML is configured.
- Only render fixed number of mermaid blocks.

### Fixed (103 changes, 12 of them are from the community)

- When user toggles task list item, keep details open until user closes the details manually. !16153
- Fix formatting welcome screen external users. !16667
- Fix signup link in admin area not being disabled. !16726 (Illya Klymov)
- Fix routing bugs in security dashboards. !16738
- Fix Jira integration favicon image with relative URL. !16802
- Add timeout mechanism for CI config validation. !16807
- Fix for count in todo badge when user has over 1,000 todos. Will now correctly display todo count after user marks some todos as done. !16844 (Jesse Hall @jessehall3)
- Naming a project "shared" will no longer automatically open the "Shared Projects" tab. !16847 (Jesse Hall @jessehall3)
- Adds the ability to delete single tags from the docker registry. Fix the issue that caused all related tags and image to be deleted at the same time. !16886
- Changed confidential quick action to only be available on non confidential issues. !16902 (Marc Schwede)
- Stop sidebar icons from jumping when expanded & collapsed. !16971
- Set name and updated_at properly in GitHub ReleaseImporter. !17020
- Remove thin white line at top of diff view code blocks. !17026
- Show correct CI indicator when build succeeded with warnings. !17034
- Create a persistent ref per pipeline for keeping pipelines run from force-push and merged results. !17043
- Move SMAU usage counters to the UsageData count field. !17074
- Allow maintainers to toggle write permission for public deploy keys. !17210
- Fix GraphQL for read-only instances. !17225
- Fix visibility level error when updating group from API. !17227 (Mathieu Parent)
- Fix stylelint errors in epics.scss. !17243
- Fix new discussion replies sometimes showing up twice. !17255
- Adjust unnapliable suggestions in expanded lines. !17286
- Show all groups user belongs to in Notification settings. !17303
- Alphabetically sorts selected sidebar labels. !17309
- Show issue weight when weight is 0. !17329 (briankabiro)
- Generate LFS token authorization for user LFS requests. !17332
- Backfill releases table updated_at column and add not null constraints to created_at and updated_at. !17400
- Log Sidekiq exceptions properly in JSON format. !17412
- Redo fix for related issues border radius. !17480
- Show the original branch name and link of merge request in pipeline emails. !17513
- Fixes issues with the security reports migration. !17519
- Users can view the blame or history of a file with newlines in its filename. !17543 (Jesse Hall @jessehall3)
- Display reCAPTCHA modal when making issue public. !17553
- Fix css selector for details in issue description. !17557
- Prevents a group path change when a project inside the group has container registry images. !17583
- Show 20 labels in dropdown instead of 5. !17596
- Nullify platform Kubernetes namespace if blank. !17657
- Fix Issue: WebIDE asks for confirmation to leave the page when committing and creating a new MR. !17671
- Catch unhandled exceptions in health checks. !17694
- Suppress error messages shown when navigating to a new page. !17706
- Specify sort order explicitly for Group and Project audit events. !17739
- Merge Request: Close JIRA issues when issues are disabled. !17743
- Disable gitlab-workhorse static error page on health endpoints. !17770
- Fix notes race condition when linking to specific note. !17777
- Fix relative positioning when moving items down and there is no space. !17781
- Fix project imports for pipelines for merge requests. !17799
- Increase the limit of includes in CI file to 100. !17807
- Geo: Fix race condition for container synchronization. !17823
- Geo: Invalidate cache after refreshing foreign tables. !17885
- Abort Merge When Pipeline Succeeds when Fast Forward merge is impossible. !17886
- Fix viewing merge reqeust from a fork that's being deleted. !17894
- Fix empty security dashboard for public projects. !17915
- Fix inline rendering of videos for uploads with uppercase file extensions. !17924
- Hide redundant labels in issue boards. !17937
- Time window filter in monitor dashboard gets reset. !17972
- Use cache_method_asymmetrically with Repository#has_visible_content?. !17975
- Allow users to compare Git revisions on a read-only instance. !18038
- Enable Google API retries for uploads. !18040
- Fix bug with new wiki not being indexed. !18051
- Stops the expand button in reports from expanding. !18064
- Make sure project insights stick on its own. !18082
- Embed metrics time window scroll no longer affects other embeds. !18109
- Fix broken notes avatar rendering in Chrome 77. !18110
- Ignore incoming emails with X-Autoreply header. !18118
- Enable grid, frame and stripes styling on AsciiDoc tables. !18165 (Guillaume Grossetie)
- Add backend support for selecting custom templates by ID. !18178
- Fix notifications for private group mentions in Notes, Issues, and Merge Requests. !18183
- Do not strip forwarded message body when creating an issue from Service Desk email. !18196
- Fix protected branch detection used by notification service. !18221
- Fix error where helper was incorrectly returning `true`. !18231
- Adjust placeholder to solve misleading regex. !18235
- Fix Flaky spec/finders/members_finder_spec.rb:85. !18257 (Jacopo Beschi @jacopo-beschi)
- Fix 500 error on clicking to LetsEncrypt Terms of Service. !18263
- Fix error tracking table layout on small screens. !18325
- GitHub import: Handle nil published_at dates. !18355
- Do not allow deactivated users to use slash commands. !18365
- Fix creating epics with dates from api. !18393
- JIRA Service: Improve username/email validation. !18397
- Stopped CRD apply retrying from allowing silent failures. !18421
- Fix erroneous "No activities found" message. !18434
- Support ES searches for project snippets. !18459
- Fix styling of set status emoji picker. !18509
- Fix showing diff when it has legacy diff notes. !18510
- JIRA Integration API URL works having a trailing slash. !18526
- Fixes embedded metrics chart tooltip spacing. !18543
- Bump GITLAB_ELASTICSEARCH_INDEXER_VERSION=v1.4.0. !18558
- Fix pod logs failure when pod contains more than 1 container. !18574
- Prevent the slash command parser from removing leading whitespace from content that is unrelated to slash commands. !18589 (Jared Deckard)
- Fix inability to set snippet visibility via API. !18612
- Fix Web IDE tree not updating modified status. !18647
- Fix button link foreground color. !18669
- Resolve missing design system notes icons. !18693
- Remove duplicate primary button in dashboard snippets. !32048 (George Tsiolis)
- Allow to view productivity analytics page without a license. !33876
- Fix container registry delete tag modal title and button. !34032
- Fixes variables overflowing in sm screens.
- Update top nav bar to fit all content in at all screen sizes.
- Fix permissions for group milestones.
- Removes Collapsible Sections from Job Log.
- Fixes job overflow in stages dropdown.
- Fix moved help URL for monitoring performance.
- Fix issue with wiki TOC links being treated as external links. (Oren Kanner)
- Show error message when setting an invalid group ID for the performance bar.

### Deprecated (1 change)

- Removing cleanup:repo, cleanup:dirs. !18087

### Changed (51 changes, 3 of them are from the community)

- Links on Releases page to commits and tags. !16128
- Add status to deployments and state to environments in API responses. !16242
- Use search scope label in empty results message. !16324
- Add step 2 of the experimental signup flow. !16583
- Add property to enable metrics dashboards to be rearranged. !16605
- Allow intra-project MR dependencies. !16799
- Use scope param instead of hide_dismissed. !16834
- Add empty state in file search. !16851
- Warn before applying issue templates. !16865
- MR Test Summary now shows errors as failures. !17039
- Add support for the association of multiple milestones to the Releases page. !17091
- Display if an issue was moved in issue list. !17102
- Improve UI for admin/projects and group/settings/projects pages. !17247
- Update registry tag delete popup message. !17257
- Show the "Set up CI/CD" prompt in empty repositories when applicable. !17274 (Ben McCormick)
- Knative version bump 0.6 -> 0.7. !17367 (Chris Baumbauer)
- Fix usability problems with the file template picker. !17522
- Make commit status created for any pipelines. !17524 (Aufar Gilbran)
- Add warnings to performance bar when page shows signs of poor performance. !17612
- Banners should only be dismissable by clicking x button. !17642
- Changes response body of liveness check to be more accurate. !17655
- Enable Request Access functionality by default for new projects and groups. !17662
- Add more attributes to issues GraphQL endpoint. !17802
- Improve admin/system_info page ui. !17829
- Adds management project for a cluster. !17866
- Upgrade gitlab-workhorse to 8.12.0. !17892
- Geo: Fix instruction from rake geo:gitlab:check. !17895
- Upgrade to Gitaly v1.66.0. !17900
- Do not start mirroring via API when paused. !17930
- Use MR links in PipelinePresenter#ref_text for branch pipelines. !17947
- Avoid knative and prometheus uninstall race condition. !18020
- Deprecate usage of state column for issues and merge requests. !18099
- Add missing page title to projects/container-registry. !18114
- Port over EE pipeline functionality to CE. !18136
- Aggregate push events when there are too many. !18239
- Cleanup background migrations for any approval rules. !18256
- Container registry tag(s) delete button pluralization. !18260
- Create clusters with VPC-Native enabled. !18284
- Update cluster link text. !18322
- Upgrade to Gitaly v1.67.0. !18326
- Improve UI of documentation under /help. !18331
- Cross-link unreplicated Geo types to issues. !18443
- Make designs read-only if the issue has been moved, or if its discussion has been locked. !18551
- Do not show new issue button on archived projects. !18590
- Increase group avatar size to 40px. !18654
- Sort vulnerabilities by severity then confidence for dashboard and pipeline views. !18675
- Add timeouts for each RPC call. !31766
- Add more specific message to clarify the role of empty images in container registry. !32919
- Embed Jaeger in Gitlab UI.
- Use text instead of icon for recent searches dropdown.
- Export liveness and readiness probes.

### Performance (25 changes, 1 of them is from the community)

- Limit diverging commit counts requests. !16737
- Use GetBlobs RPC for uri type. !16824
- Reduce Gitaly calls when viewing a commit. !17095
- Limit snippets search count. !17585
- Narrow snippet search scope in GitLab.com. !17625
- Handle wiki and graphql attachments in gitlab-workhorse. !17690
- Reduce lock contention of deployment creation by allocating IID outside of the pipeline transaction. !17696
- Update PumaWorkerKiller defaults. !17758
- Add trigram index on snippet content. !17806
- Fix Gitaly N+1 queries in related merge requests API. !17850
- Don't execute webhooks/services when above limit. !17874
- Only schedule updating push-mirrors once per push. !17902
- Show only personal snippets on explore page. !18092
- Priority bump authorized_projects sidekiq queue. !18125
- Avoid dumping files on disk when direct_upload is enabled. !18135
- Check if mapping is empty before caching in File Collections. !18290 (briankabiro)
- Avoid unnecessary locks on internal_ids. !18328
- Fix N+1 queries in Jira Development Panel API endpoint. !18329
- Optimize SQL requests for BlameController and CommitsController. !18342
- Remove N+1 for fetching commits signatures. !18389
- Reduce idle in transaction time when updating a merge request. !18493
- Use cascading deletes for deleting logs upon deleting a webhook. !18642
- Replace index on ci_triggers. !18652
- Hide license breakdown in /admin if user count is high. !18825
- Cache branch and tag names as Redis sets. !30476

### Added (78 changes, 12 of them are from the community)

- Adds sorting of packages at the project level. !15448
- Add projects.only option to Insights. !15930
- Add kubernetes section to group runner settings. !16338
- Enable Cloud Run on GKE cluster creation. !16566
- Add file matching rule to flexible CI rules. !16574
- Enable preview of private artifacts. !16675 (Tuomo Ala-Vannesluoma)
- Upgrade Gitaly to v1.64. !16788
- Render xml artifact files in GitLab. !16790
- Add GitHub & Gitea importers project filtering. !16823
- Add project filtering to Bitbucket Cloud import. !16828
- Provides internationalization support to chart legends. !16832
- Expose name property in imports API. !16848
- Add allowFilter and allowAnySHA1InWant for partial clones. !16850
- [ObjectStorage] Allow migrating back to local storage. !16868
- Require admins to enter admin-mode by re-authenticating before performing administrative operations. !16981 (Roger Rüttimann & Diego Louzán)
- Deactivate a user (with self-service reactivation). !17037
- Add database tables to store AWS roles and cluster providers. !17057
- Collect docker registry related metrics. !17063
- Allow releases to be targeted by URL anchor links on the Releases page. !17150
- Add project_pages_metadata DB table. !17197
- Add index on ci_builds for successful Pages deploys. !17204
- Creation of Evidence collection of new releases. !17217
- API: Add missing group parameters. !17220 (Mathieu Parent)
- Allow to exclude ancestor groups on group labels API. !17221 (Mathieu Parent)
- Added 'copy link' in epic comment dropdown. !17224
- Add columns for per project/group max pages/artifacts sizes. !17231
- Create table for grafana api token for metrics embeds. !17234
- Add proper label REST API for update, delete and promote. !17239 (Mathieu Parent)
- Allow cross-project pipeline triggering with CI_JOB_TOKEN in core. !17251
- Add user_id and created_at columns to design_management_versions table. !17316
- Add pull_mirror_branch_prefix column on projects table. !17368
- Expose web_url for epics on API. !17380
- Improve time window filtering on metrics dashboard. !17554
- Group level Container Registry browser. !17615
- Add API for manually creating and updating deployments. !17620
- Introduce diffs_batch JSON endpoint for paginated diffs. !17651
- Web IDE button should fork and open forked project when selected from read-only project. !17672
- Allow users to be searched with a @ prefix. !17742
- Add individual inherited member lookup API. !17744
- Preserve custom .gitlab-ci.yml config path when forking. !17817 (Mathieu Parent)
- Introduce CI_PROJECT_TITLE as predefined environment variable. !17849 (Nejc Habjan)
- Feature enabling embedded audio elements in markdown. !17860 (Jesse Hall @jessehall3)
- Add 'New release' to the project custom notifications. !17877
- Added timestamps (created_at and updated_at) to API pipelines response. !17911
- Added timestamp (updated_at) to API deployments response. !17913
- Add pipeline preparing status icons. !17923
- Creates Vue and Vuex app to render exposed artifacts. !17934
- Add web_exporter to expose Prometheus metrics. !17943
- Schedule background migration to populate pages metadata. !17993
- Add "Edit Release" page. !18033
- Unpin ingress image version, upgrade chart to 1.22.1. !18047
- Adds sorting of packages at the group level. !18062
- Introduce a lightweight diffs_metadata endpoint. !18104
- Limit the number of comments on an issue, MR, or commit. !18111
- Introduce new Ansi2json parser to convert job logs to JSON. !18133
- Use new Ansi2json job log converter via feature flag. !18134
- Snowplow custom events for Monitor: Health Product Categories. !18157
- Support Create/Read/Destroy operations in Feature Flag API. !18198
- Add two new predefined stages to pipelines. !18205
- Add endpoint to proxy requests to grafana's proxy endpoint. !18210
- Add ability to query todos using GraphQL. !18218
- Include in the callout message a list of jobs that caused missing dependencies failure. !18219
- Adds login input with copy box and supporting copy to empty container registry view. !18244 (nate geslin)
- Add max_artifacts_size fields under project and group settings. !18286
- Provide Merge requests and Issue links through the Release API. !18311
- Adds separate parsers for mentions of users, groups, projects in markdown content. !18318
- Add matching branch info to branch column. !18352
- Users can preview audio files in a repository. !18354 (Jesse Hall @jessehall3)
- Add edit button to release blocks on Releases page. !18411
- Add "Custom HTTP Git clone URL root" setting. !18422
- Add support for epic update through GraphQL API. !18440
- Expose subscribed attribute for epic on API. !18475
- Geo: Enable replicating uploads, LFS objects, and artifacts in Object Storage. !18482
- Show related merge requests in pipeline view. !18697
- Allow users to configure protected paths from Admin panel. !31246
- persist the refs when open the link of refs in a new tab of browser. !31998 (minghuan lei)
- Add first_parent option to list commits api. !32410 (jhenkens)
- Allow users to add and remove zoom rooms on an issue using quick action commands.

### Other (23 changes, 5 of them are from the community)

- Sync issuables state_id with null values. !16480
- Experimental separate sign up flow. !16482
- Upgrade Rouge to v3.11.0. !17011
- Better job naming for Docker.gitlab-ci.yml. !17218 (luca.orlandi@gmail.com)
- Update GitLab Runner Helm Chart to 0.9.0. !17326
- Change welcome message and make translatable. !17391
- Remove map-get($grid-breakpoints, xs) for max-width. !17420 (Takuya Noguchi)
- Document Git LFS and max file size interaction. !17609
- Refactor email notification code. !17741 (briankabiro)
- Ignore id column of ci_build_trace_sections table. !17805
- Extend graphql query endpoint for merge requests to return more attributes to support sidebar implementation. !17813
- Project list: Align star icons. !17833
- Moves the license compliance reports to the Backend. !17905
- Fixes wrong link on Protected paths admin settings. !17945
- Update Pages to v1.11.0. !18010
- Refactor checksum code in uploads. !18065 (briankabiro)
- Make instance configuration user friendly. !18363 (Takuya Noguchi)
- Update Workhorse to v8.14.0. !18391
- Attribute each Sidekiq worker to a feature category. !18462
- Update GitLab Shell to v10.2.0. !18735
- Use correct icons for issue actions.
- Increase color contrast of select option path.
- Remove Postgresql specific setup tasks and move to schema.rb.


## 12.3.9

### Security (1 change)

- Update maven_file_name_regex for full string match.


## 12.3.7

### Security (12 changes)

- Do not create todos for approvers without access. !1442
- Limit potential for DNS rebind SSRF in chat notifications.
- Encrypt application setting tokens.
- Update Workhorse and Gitaly to fix a security issue.
- Add maven file_name regex validation on incoming files.
- Hide commit counts from guest users in Cycle Analytics.
- Check permissions before showing a forked project's source.
- Fix 500 error caused by invalid byte sequences in links.
- Ensure are cleaned by ImportExport::AttributeCleaner.
- Remove notes regarding Related Branches from Issue activity feeds for guest users.
- Escape namespace in label references to prevent XSS.
- Add authorization to using filter vulnerable in Dependency List.


## 12.3.4

### Fixed (2 changes)

- Fix cannot merge icon showing in dropdown for users who can merge. !17306
- Fix pipelines for merge requests in project exports. !17844


## 12.3.2

### Security (12 changes)

- Fix Gitaly SearchBlobs flag RPC injection.
- Add a policy check for system notes that may not be visible due to cross references to private items.
- Display only participants that user has permission to see on milestone page.
- Do not disclose project milestones on group milestones page when project milestones access is disabled in project settings.
- Check permissions before showing head pipeline blocking merge requests.
- Fix new project path being disclosed through unsubscribe link of issue/merge requests.
- Prevent bypassing email verification using Salesforce.
- Do not show resource label events referencing not accessible labels.
- Cancel all running CI jobs triggered by the user who is just blocked.
- Fix Gitaly SearchBlobs flag RPC injection.
- Only render fixed number of mermaid blocks.
- Prevent GitLab accounts takeover if SAML is configured.


## 12.3.1

### Fixed (4 changes)

- Fix ordering of issue board lists not being persisted. !17356
- Fix error when duplicate users are merged in approvers list. !17406
- Fix bug that caused a merge to show an error message. !17466
- Fix CSS leak in job log.


## 12.3.0

### Security (23 changes)

- Filter out old system notes for epics in notes api endpoint response.
- Fix SSRF via DNS rebinding in Kubernetes Integration.
- Fix project import restricted visibility bypass via API.
- Prevent disclosure of merge request ID via email.
- Use admin_group authorization in Groups::RunnersController.
- Gitaly: ignore git redirects.
- Prevent DNS rebind on JIRA service integration.
- Make sure HTML text is always escaped when replacing label/milestone references.
- Fix HTML injection for label description.
- Avoid exposing unaccessible repo data upon GFM post processing.
- Remove EXIF from users/personal snippet uploads.
- Fix weak session management by clearing password reset tokens after login (username/email) are updated.
- Added image proxy to mitigate potential stealing of IP addresses.
- Restrict MergeRequests#test_reports to authenticated users with read-access on Builds.
- Ensure only authorised users can create notes on Merge Requests and Issues.
- Send TODOs for comments on commits correctly.
- Check permissions before responding in MergeController#pipeline_status.
- Limit the size of issuable description and comments.
- Enforce max chars and max render time in markdown math.
- Speed up regexp in namespace format by failing fast after reaching maximum namespace depth.
- Add :login_recaptcha_protection_enabled setting to prevent bots from brute-force attacks.
- Upgrade pages to 1.8.1.
- Show cross-referenced MR-id in issues' activities only to authorized users.

### Removed (1 change)

- Removed redundant index on releases table. !31487

### Fixed (78 changes, 25 of them are from the community)

- Avoid Devise "401 Unauthorized" responses. !16519
- Allow close status to be shown on locked issues. !16685
- Changed todo/done quick actions to work not only for first usage. !16837 (Marc Schwede)
- Adds missing error handling. !16896 (toptalo)
- Prevent the user from seeing an invalid "Purchase more minutes" prompt. !16979
- Fix missing board lists when other users collapse / expand the list. !17318
- Uses projects_authorizations.access_level in MembersFinder. !28887 (Jacopo Beschi @jacopo-beschi)
- Let project reporters create issue from group boards. !29866
- Remove margin from user header. !30878 (lucyfox)
- Improve application settings API. !31149 (Mathieu Parent)
- Fix encoding of special characters in "Find File". !31311 (Jan Beckmann)
- Avoid conflicts between ArchiveTracesCronWorker and ArchiveTraceWorker. !31376
- Disable "Transfer group" button when no group is selected. !31387 (Jan Beckmann)
- Prevent archived projects from showing up in global search. !31498 (David Palubin)
- Fixed embeded metrics tooltip inconsistent styling. !31517
- Fix 500 errors caused by pattern matching with variables in CI Lint. !31719
- Fixed removing directories in Web IDE. !31727
- All of discussion expand/collapse button is clickable. !31730
- Only show /copy_metadata quick action when usable. !31735 (Lee Tickett)
- Read pipelines from public projects through API without an access token. !31816
- fix charts scroll handle icon to use gitlab svg. !31825
- Remove "Commit" from pipeline status tooltips. !31861
- Fix top-nav search bar dropdown on xl displays. !31864 (Kemais Ehlers)
- Fix loading icon causing text to jump in file row of Web IDE. !31884
- Fix MR reports section loading icon alignment. !31897
- Fix broken git clone box on wiki git access page. !31898
- Exempt user gitlab-ci-token from rate limiting. !31909
- Fix search preserving space when change branch. !31973 (minghuan lei)
- Fix file header style and position during scroll in a merge conflict resolution. !31991
- Allow latency measurements of sidekiq jobs taking > 2.5s. !32001
- Return correct user for manual deployments. !32004
- Fix style of secondary profile tab buttons. !32010 (Wolfgang Faust)
- Fix serverless entry page layout. !32029
- Fix HTML rendering for fast-forward rebases in merge request widget. !32032
- Update the timestamp in Operations > Environments to show correct deployment date for manual deploy jobs. !32072
- Fix dropdowns closing when click is released outside the dropdown. !32084
- Hide duplicate board list while dragging. !32099
- Don't check external authorization when disabling the service. !32102 (Robert Schilling)
- Makes custom Pages domain open as external link in new tab. !32130 (jakeburden)
- Change default visibility level for FogBugz imported projects to Private. !32142
- Move visual review toolbar code to NPM. !32159
- Fix parsing of months in time tracking commands. !32165
- Wrong format on MS teams integration push events with multi line commit messages. !32180 (Massimeddu Cireddu)
- Guard against deleted project feature entry in project permissions. !32187
- Fix ref switcher separators from conflicting with branch names. !32198
- Fix performance bar on Puma. !32213
- Remove token field from runners edit form. !32231
- Fix 500 error in CI lint when included templates are an array. !32232
- Fix users cannot access job detail page when deployable does not exist. !32247
- Do not translate system notes into author's language. !32264
- Fix moving issues API failing when text includes commit URLs. !32317
- Fix issue due notification emails not being threaded correctly. !32325
- Allow project feature permissions to be overridden during import with override_params. !32348
- Handle invalid mirror url. !32353 (Lee Tickett)
- New project milestone primary button. !32355 (Lee Tickett)
- Display `more information` docs link on error tracking page when users do not have permissions to enable that feature. !32365 (Romain Maneschi)
- Quick action label must be first in issue comment. !32367 (Romain Maneschi)
- Fix for missing avatar images dislpayed in commit trailers. !32374 (Jesse Hall @jessehall3)
- Make it harder to delete issuables accidentally. !32376
- Replaced vue resource to axios in the  Markdown field preview component. !32386 (Prakash Chokalingam @prakash_Chokalingam)
- Fix create MR from issue using a tag as ref. !32392 (Jacopo Beschi @jacopo-beschi)
- Add X-GitLab-NotificationReason header to note emails. !32422
- Expand textarea for CA cert in cluster form. !32508
- Prevent empty external authorization classification labels from overriding the default label. !32517 (Will Chandler)
- Allow not resolvable urls when dns rebind protection is disabled. !32523
- Avoid checking dns rebind protection when validating. !32577
- Passing job rules downstream and E2E specs for job:rules configuration. !32609
- Quote branch names in how to merge instructions. !32639 (Lee Tickett)
- Fix removal of install pods. !32667
- Fix sharing localStorage with all MRs. !32699
- Default the asset proxy whitelist to the installation domain. !32703
- Add some padding to details markdown element. !32716
- Use `ChronicDuration` in a thread-safe way. !32817
- Fix watch button styling and notifications buttons consistency. !32827
- Fix encoding error in MR diffs when using external diffs. !32862 (Hiroyuki Sato)
- Add bottom margin to snippet title. !32877
- Bump markdown cache version to fix any incorrect links from asset proxy defaults.
- Persist `needs:` validation as config error.

### Changed (39 changes, 6 of them are from the community)

- Extend pipeline graph scroll area to full width. !14870
- Frontend support for saving issue board preferences on the current user. !16421
- Switch Milestone and Release to a many-to-many relationship. !16517
- Align project selector search box better with design system. !16795
- Adds the runners_token of the group if the user that requests the group info is admin of it. !16831 (Ignacio Lorenzo Subirá Otal nachootal@gmail.com)
- Upgrade to Gitaly v1.65.0. !17135
- Make flash notifications sticky. !30141
- Add Issue and Merge Request titles to Todo items. !30435 (Arun Kumar Mohan)
- Remove wiki page slug dialog step when creating wiki page. !31362
- Improve system notes for Zoom links. !31410 (Jacopo Beschi @jacopo-beschi)
- Updated WebIDE default commit options. !31449
- Remove oauth form from GitHub CI/CD only import authentication. !31488
- Update assignee (cannot merge) style. !31545
- Updated latest pipeline tag tooltip to be more descriptive. !31624
- Add optional label_id parameter to label API for PUT and DELETE. !31804
- Updates issues REST API to allow extended sort options. !31849
- Fix to show renamed file in mr. !31888
- Replaced expand diff icons. !31907
- Upgrade to Gitaly 1.60.0. !31981
- Make MR pipeline widget text more descriptive. !32025
- Fix wording on milestone due date when milestone is due today. !32096
- Improve search result labels. !32101
- Limit access request emails to ten most recently active owners or maintainers. !32141
- Improve chatops help output. !32208
- Update merge train documentation. !32218
- Add caret icons to the monitoring dashboard. !32239
- Install cert-manager v0.9.1. !32243
- Bring text mail for new issue & MR more in line. !32254
- Add cluster domain warning. !32260
- Rename epic column state to state_id. !32270
- Use moved instead of closed in issue references. !32277 (juliette-derancourt)
- Standardize use of `content` parameter in snippets API. !32296
- Show meaningful message on /due quick action with invalid date. !32349 (Jacopo Beschi @jacopo-beschi)
- Remove dynamically constructed feature flags starting with prometheus_transaction_. !32395 (Jacopo Beschi @jacopo-beschi)
- Indicate on Issue Status if an Issue was Duplicated. !32472
- Avoid dns rebinding checks when the domain is whitelisted. !32603
- Upgrade to Gitaly v1.62.0. !32608
- Unified presentation of the filter input field for projects listings. !32706
- Hide resolve thread button from guest. !32859

### Performance (20 changes)

- Lower search counters. !11777
- Considerably improve the query performance for MR discussions load. !16635
- Eliminate Gitaly N+1 queries with notes API. !32089
- Optimise UpdateBuildQueueService. !32095
- Remove N+1 SQL query loading project feature in dashboard. !32169
- Reduce the number of SQL requests on MR-show. !32192
- Makes LFS object linker process OIDs in batches. !32268
- Preload routes information to fix N+1 issue. !32352
- Reduce N+1 when doing project export. !32423
- Skip requesting diverging commit counts if no branches are listed. !32496
- Support selective highlighting of lines. !32514
- Replace indexes for counting active users. !32538
- Create partial index for gitlab-monitor CI metrics. !32546
- Optimize queries for snippet listings. !32576
- Preprocess wiki attachments with GitLab-Workhorse. !32663
- Create index for users.unconfirmed_email. !32664
- Optimize /admin/applications so that it does not timeout. !32852
- Replace events index with partial one. !32874
- Partial index for namespaces.type. !32876
- Fix member expiration not always working. !32951

### Added (42 changes, 10 of them are from the community)

- Enable modsecurity in nginx-ingress apps. !15774
- Database table for tracking programming language trends over time. !16491
- Add DAST full scan domain validation. !16680
- Add not param to Issues API endpoint. !16748
- Allow specifying timeout per-job in .gitlab-ci.yml. !16777 (Michał Siwek)
- Document forwarding CI variables to docker build in Auto DevOps. !16783
- Add links for latest pipelines. !20865 (Alex Ives)
- New interruptible attribute for CI/CD jobs. !23464 (Cédric Tabin)
- API: Promote project labels to group labels. !25218 (Robert Schilling)
- Introduced Build::Rules configuration for Ci::Build. !29011
- Notification emails can be signed with SMIME. !30644 (Diego Louzán)
- Allow milestones to be associated with a release (backend). !30816
- Enable serving static objects from an external storage. !31025
- Save collapsed option for board lists in database. !31069
- Apply quickactions when modifying comments. !31136
- Add SwaggerUI Pages template for .gitlab-ci.yml. !31183 (mdhtr)
- Add ability to see project deployments at cluster level (FE). !31575
- Create component to display area and line charts in monitor dashboards. !31639
- Add persistance to last choice of projects sorting on projects dashboard page. !31669
- Run Pipeline button & API for MR Pipelines. !31722
- Add service to transfer Group Milestones when transferring a Project. !31778
- Allow $CI_REGISTRY_USER to delete tags. !31796
- Support adding and removing labels w/ push opts. !31831
- Enable line charts in dashbaord panels and embedded charts. !31920
- Add First and Last name columns to User model. !31985
- Add option to allow OAuth providers to bypass two factor. !31996 (Dodocat)
- Expose namespace storage statistics with GraphQL. !32012
- Add usage pings for merge request creating. !32059
- Add warning about initial deployment delay for GitLab Pages sites. !32122
- Allow Knative to be installed on group and instance level clusters. !32128
- Add a close issue slack slash command. !32150
- Support chat notifications to be fired for protected branches. !32176
- Add system hooks for project/group membership updates. !32371 (Brandon Williams)
- Add source and merge_request fields to pipeline event webhook. !32373 (Bian Jiaping)
- Allow ECDSA certificates for pages domains. !32393
- Show link to cluster used on job page. !32446
- Group level JupyterHub. !32512
- Creates utility parser for the job log. !32555
- Expose update project service endpoint JSON. !32759
- Expose 'protected' field for Tag API endpoint. !32790 (Andrea Leone)
- Create table `alerts_service_data`. !32860
- Creates base components for the new job log.

### Other (42 changes, 13 of them are from the community)

- Setting NOT NULL constraint to users.private_profile column. !14838
- Schedule productivity analytics recalculation for EE. !15137
- Document Lambda deploys via GitLab CI/CD. !16858
- Add Redis interceptor tracing. !30238
- Encrypt existing and new deploy tokens. !30679
- Clean up keyboard shortcuts help modal, removing and adding as needed. !31642
- Add warning to pages domains that obtaining/deploying SSL certificates through Let's Encrypt can take some time. !31765
- Add new API method in Api.js: projectUsers. !31801
- Upgrade babel to 7.5.5. !31819 (Takuya Noguchi)
- Update docs to reflect the rename of gitlab-monitor to gitlab-exporter. !31901
- Count comments on commits and merge requests. !31912
- Resolve Badge counter: Very low contrast between foreground and background colors. !31922
- Add index to improve group cluster deployments query performance. !31988
- Replace finished_at with deployed_at for the internal API Deployment entity. !32000
- Update to GitLab Shell v9.4.0. !32009
- Default clusters namespace_per_environment column to true. !32139
- Remove deprecation message for milestone tabs. !32252
- Refactored Karma spec to Jest for mr_widget_auto_merge_failed. !32282 (Illya Klymov)
- Update GitLab Runner Helm Chart to 0.8.0. !32289
- Refactor showStagedIcon property to reflect the behavior its name represents. !32333 (Arun Kumar Mohan)
- Upgrade pages to 1.8.0. !32334
- Change prioritized labels empty state message. !32338 (Lee Tickett)
- make test of note app with comments disabled dry. !32383 (Romain Maneschi)
- Use new location for gitlab-runner helm charts. !32384
- Mention in docs how to disable project snippets. !32391 (Jacopo Beschi @jacopo-beschi)
- delete animation width on global search input. !32399 (Romain Maneschi)
- Remove vue resource from sidebar service. !32400 (Lee Tickett)
- Remove vue resource from issue. !32421 (Lee Tickett)
- Remove vue resource from remove issue. !32425 (Lee Tickett)
- Remove vue-resource from PerformanceBarService. !32428 (Lee Tickett)
- Added warning note on the project container registry setting informing users that the registry is public for public projects. !32447
- Admin dashboard: Fetch and render statistics async. !32449
- Update GitLab Workhorse to v8.10.0. !32501
- Remove Users.support_bot column. !32554
- Add padding to left of "Sort by" in members dropdown. !32602
- Log errors for failed pipeline creation in PostReceive. !32633
- Avoid prefilling target branch when source branch is the default one. !32701
- Bump Kubeclient to 4.4.0. !32811
- Remove vue-resource from notes service. !32934 (Lee Tickett)
- Added board name to page title in boards view.
- Remove vue resource from group service. (Lee Tickett)
- Updates tooltip of 'detached' label/state.


## 12.2.11

- No changes.

## 12.2.8

### Security (1 change)

- Limit search for IID to a type to avoid leaking records with the same IID that the user does not have access to.


## 12.2.7

### Security (1 change)

- Fix private feature Elasticsearch leak.


## 12.2.6

### Security (11 changes)

- Add a policy check for system notes that may not be visible due to cross references to private items.
- Display only participants that user has permission to see on milestone page.
- Do not disclose project milestones on group milestones page when project milestones access is disabled in project settings.
- Check permissions before showing head pipeline blocking merge requests.
- Fix new project path being disclosed through unsubscribe link of issue/merge requests.
- Prevent bypassing email verification using Salesforce.
- Do not show resource label events referencing not accessible labels.
- Cancel all running CI jobs triggered by the user who is just blocked.
- Fix Gitaly SearchBlobs flag RPC injection [Gitaly v1.59.3].
- Only render fixed number of mermaid blocks.
- Prevent GitLab accounts takeover if SAML is configured.


## 12.2.5

### Security (1 change)

- Upgrade pages to 1.7.2.


## 12.2.4

### Fixed (7 changes)

- Add syntax highlighting for line expansion. !31821
- Fix issuable sidebar icon on notification disabled. !32134
- Upgrade Mermaid to v8.2.4. !32186
- Fix Piwik not working. !32234
- Fix snippets API not working with visibility level. !32286
- Fix upload URLs in Markdown for users without access to project repository. !32448
- Update Mermaid to v8.2.6. !32502

### Performance (1 change)

- Fix N+1 Gitaly calls in /api/v4/projects/:id/issues. !32171


## 12.2.3

- No changes.

## 12.2.2

### Security (22 changes)

- Ensure only authorised users can create notes on Merge Requests and Issues.
- Gitaly: ignore git redirects.
- Add :login_recaptcha_protection_enabled setting to prevent bots from brute-force attacks.
- Speed up regexp in namespace format by failing fast after reaching maximum namespace depth.
- Limit the size of issuable description and comments.
- Send TODOs for comments on commits correctly.
- Restrict MergeRequests#test_reports to authenticated users with read-access on Builds.
- Added image proxy to mitigate potential stealing of IP addresses.
- Filter out old system notes for epics in notes api endpoint response.
- Avoid exposing unaccessible repo data upon GFM post processing.
- Fix HTML injection for label description.
- Make sure HTML text is always escaped when replacing label/milestone references.
- Prevent DNS rebind on JIRA service integration.
- Use admin_group authorization in Groups::RunnersController.
- Prevent disclosure of merge request ID via email.
- Show cross-referenced MR-id in issues' activities only to authorized users.
- Enforce max chars and max render time in markdown math.
- Check permissions before responding in MergeController#pipeline_status.
- Remove EXIF from users/personal snippet uploads.
- Fix project import restricted visibility bypass via API.
- Fix weak session management by clearing password reset tokens after login (username/email) are updated.
- Fix SSRF via DNS rebinding in Kubernetes Integration.


## 12.2.1

### Fixed (2 changes)

- Fix for embedded metrics undefined params. !31975
- Fix "ERR value is not an integer or out of range" errors. !32126

### Performance (1 change)

- Fix Gitaly N+1 calls with listing issues/MRs via API. !31938

### Fixed (3 changes)

- Fix for embedded metrics undefined params. !31975
- Fix "ERR value is not an integer or out of range" errors. !32126
- Prevent duplicated trigger action button.

### Performance (1 change)

- Fix Gitaly N+1 calls with listing issues/MRs via API. !31938


## 12.2.0

### Security (4 changes, 1 of them is from the community)

- Update mini_magick to 4.9.5. !31505 (Takuya Noguchi)
- Upgrade Rugged to 0.28.3. !31794
- Queries for Upload should be scoped by model.
- Restrict slash commands to users who can log in.

### Removed (3 changes)

- Remove Kubernetes service integration page. !31365
- Remove line profiler from performance bar.
- Remove GC metrics from performance bar.

### Fixed (74 changes, 4 of them are from the community)

- Resolve Incorrect empty state message on Explore projects. !25578
- Search issuables by iids. !28302 (Riccardo Padovani)
- Make it easier to find invited group members. !28436
- fix: updates to include units for the y axis label. !30330
- Align access permissions for wiki history to those of wiki pages. !30470
- Add index for issues on relative position, project, and state for manual sorting. !30542
- Fix suggestion on lines that are not part of an MR. !30606
- Add empty chart component. !30682
- Remove blank block from job sidebar. !30754
- Remove duplicate buttons in diff discussion. !30757
- Order projects in 'Move issue' dropdown by name. !30778
- Fix bug in dashboard display of closed milestones. !30820
- Fixes alignment issues with reports. !30839
- Ensure visibility icons in group/project listings are grey. !30858
- Fix admin labels page when there are invalid records. !30885
- Extra logging for new live trace architecture. !30892
- Fix pipeline emails not respecting group notification email setting. !30907
- Handle trailing slashes when generating Jira issue URLs. !30911
- Optimize relative re-positioning when moving issues. !30938
- Better support clickable tasklists inside blockquotes. !30952
- Add space to "merged by" widget. !30972
- Remove duplicated mapping key in config/locales/en.yml. !30980 (Peter Dave Hello)
- Update Mermaid to v8.2.3. !30985
- Use persistent Redis cluster for Workhorse pub/sub notifications. !30990
- Remove :livesum from RubySampler metrics. !31047
- Fix pid discovery for Unicorn processes in `PidProvider`. !31056
- Respect group notification email when sending group access notifications. !31089
- Default dependency job stage index to Infinity, and correctly report it as undefined in prior stages. !31116
- Fix incorrect use of message interpolation. !31121
- Moved labels out of fields on Search page. !31137
- Ensure Warden triggers after_authentication callback. !31138
- Fix admin area user access level radio button labels. !31154
- Ignore Gitaly errors if cache flushing fails on project destruction. !31164
- Prevent double slash in review apps path. !31212
- Make pdf.js render CJK characters. !31220
- Prevent discussion filter from persisting to `Show all activity` when opening links to notes. !31229
- Improve layout of dropdowns in the metrics dashboard page. !31239
- Remove pdf.js deprecation warnings. !31253
- Fix GC::Profiler metrics fetching. !31331
- Jupyter fixes. !31332 (Amit Rathi)
- Fix first-time contributor notes not rendering. !31340
- Fix inline rendering of relative paths to SVGs from the current repository. !31352
- Make `bin/web_puma` consider RAILS_ENV. !31378
- Removed extrenal dashboard legend border. !31407
- Fix visual review app storage keys. !31427
- Fix flashing conflict warning when editing issues. !31469
- Fix broken issue links and possible 500 error on cycle analytics page when project name and path are different. !31471
- Prevent turning plain links into embedded when moving issues. !31489
- Add a field for released_at to GH importer. !31496
- Adjust size and align MR-widget loading icon. !31503
- Fix an issue where clicking outside the MR/branch search box in WebIDE closed the dropdown. !31523
- Don't attempt to contact registry if it is disabled. !31553
- Fix IDE new files icon in tree. !31560
- Fix missing author line (`Created by: <user>`) in MRs/issues/comments of imported Bitbucket Cloud project. !31579
- Add missing report-uri to CSP config. !31593
- Fixed display of some sections and externalized all text in the shortcuts modal overlay. !31594
- Remove extra padding from disabled comment box. !31603
- Allow CI to clone public projects when HTTP protocol is disabled. !31632
- error message for general settings. !31636 (Mesut Güneş)
- Invalidate branches cache on PostReceive. !31653
- Fix active metric files being wiped after the app starts. !31668
- Fix :wiki_can_not_be_created_total counter. !31673
- Fix job logs where style changes were broken down into separate lines. !31674
- Properly save suggestions in project exports. !31690
- Fix project avatar image in Slack pipeline notifications. !31788
- Fix empty error flash message on profile:account page when updating username with username that has already been taken. !31809
- Fix starrers counts after searching. !31823
- Fix pipelines not always being created after a push. !31927
- Fix 500 errors in commits api caused by empty ref_name parameter.
- Center loading icon in CI action component.
- Prevents showing 2 tooltips in pipelines table.
- Fix tag page layout.
- Prevent duplicated trigger action button.
- Hides loading spinner in pipelines actions after request has been fullfiled.

### Changed (31 changes, 5 of them are from the community)

- Update cluster page automatically when cluster is created. !27189
- Add branch/tags/commits dropdown filter on the search page for searching codes. !28282 (minghuan lei)
- Add support for start_sha to commits API. !29598
- Maintainers can create subgroups. !29718 (Fabio Papa)
- Extract Auto DevOps deploy functions into a base image. !30404
- Add MR form to Visual Review (EE) runtime configuration. !30481
- Adjust redis cache metrics. !30572
- Add DS_PIP_DEPENDENCY_PATH option to configure Dependency Scanning for projects using pip. !30762
- Bring scoped environment variables to core. !30779
- Add Web IDE Usage Ping for Create SMAU. !30800
- Update the container scanning CI template to use v12 of the clair scanner. !30809
- Multiple pipeline support for Commit status. !30828 (Gaetan Semet)
- Add support for exporting repository type data for LFS objects. !30830
- Avoid increasing redis counters when usage_ping is disabled. !30949
- Added navbar searches usage ping counter. !30953
- Convert githost.log to JSON format. !30967
- Adjusted the clickable area of collapsed sidebar elements. !30974 (Michel Engelen)
- Mark push mirrors as failed after 1 hour. !30999
- Allows masking @ and : characters. !31065
- Remove incorrect fallback when determining which cluster to use when retrieving MR performance metrics. !31126
- Retry push mirrors faster when running concurrently, improve error handling when push mirrors fail. !31247
- Make issue boards importable. !31434 (Jason Colyer)
- Allow users to resend a confirmation link when the grace period has expired. !31476
- Remove counts from default labels API responses. !31543
- Upgrade to Gitaly v1.57.0. !31568
- Rename githost.log -> git_json.log. !31634
- Load search result counts asynchronously. !31663
- feat: adds a download to csv functionality to the dropdown in prometheus metrics. !31679
- Adjust copy for adding additional members. !31726
- Upgrade to Gitaly v1.59.0. !31743
- Filter title, description, and body parameters from logs.

### Performance (17 changes, 1 of them is from the community)

- Add partial index on identities table to speed up LDAP lookups. !26710
- Improve MembersFinder query performance using UNION. !30451 (Jacopo Beschi @jacopo-beschi)
- Rake task to cleanup expired ActiveSession lookup keys. !30668
- Update usage ping cron behavior. !30842
- Make Bootsnap available via ENABLE_BOOTSNAP=1. !30963
- Batch processing of commit refs in markdown processing. !31037
- Use tablesample approximate counting by default. !31048
- Create index on environments by state. !31231
- Split MR widget into etag-cached and non-cached serializers. !31354
- Speed up loading and filtering deploy keys and their projects. !31384
- Only track Redis calls if Peek is enabled. !31438
- Only expire tag cache once per push. !31641
- Reduce Gitaly calls in PostReceive. !31741
- Eliminate many Gitaly calls in discussions API. !31834
- Optimize DB indexes for ES indexing of notes. !31846
- Expire project caches once per push instead of once per ref. !31876
- Look up upstream commits once before queuing ProcessCommitWorkers.

### Added (51 changes, 11 of them are from the community)

- Make starred projects and starrers of a project publicly visible. !24690
- Make quick action commands applied banner more useful. !26672 (Jacopo Beschi @jacopo-beschi)
- Allow Helm to be uninstalled from the UI. !27359
- Improve pipeline status Slack notifications. !27683
- Add links to relevant configuration areas in admin area overview. !29306
- Display project id on project admin page. !29734 (Zsolt Kovari)
- Display group id on group admin page. !29735 (Zsolt Kovari)
- Resolve Keyboard shortcut for jump to NEXT unresolved discussion. !30144
- Personal access tokens are accepted using OAuth2 header format. !30277
- Add Outbound requests whitelist for local networks. !30350 (Istvan Szalai)
- Allow multiple Auto DevOps projects to deploy to a single namespace within a k8s cluster. !30360 (James Keogh)
- Allow Knative to be uninstalled from the UI. !30458
- Add admin-configurable "Support page URL" link to top Help dropdown menu. !30459 (Diego Louzán)
- Allow specifying variables when running manual jobs. !30485
- Use predictable environment slugs. !30551
- Return an ETag header for the archive endpoint. !30581
- Add Rate Request Limiter to RawController#show endpoint. !30635
- Add git blame to GitLab API. !30675 (Oleg Zubchenko)
- Use separate Kubernetes namespaces per environment. !30711
- Support remove source branch on merge w/ push options. !30728
- Deploy serverless apps with gitlabktl. !30740
- Adjust group level analytics to accept multiple ids. !30744
- Adds event enum column to DesignsVersions join table. !30745
- Allow email notifications to be disabled for all members of a group or project. !30755 (Dustin Spicuzza)
- Export and download CSV from metrics charts. !30760
- Add API endpoints to return container repositories and tags from the group level. !30817
- Add support for deferred links in persistent user callouts. !30818
- Add system notes for when a Zoom call was added/removed from an issue. !30857 (Jacopo Beschi @jacopo-beschi)
- Count wiki creation, update and delete events. !30864
- Add new expansion options for merge request diffs. !30927
- Count snippet creation, update and comment events. !30930
- Update namespace label for GitLab-managed clusters. !30935
- UI for disabling group/project email notifications. !30961 (Dustin Spicuzza)
- Support setting of merge request title and description using git push options. !31068
- Add new table to store email domain per group. !31071
- Redirect from a project wiki git route to the project wiki home. !31085
- Link and embed metrics in GitLab Flavored Markdown. !31106
- Moves snowplow tracking from ee to ce. !31160 (jejacks0n)
- Allow Cert-Manager to be uninstalled. !31166
- Add new outbound network requests application setting for system hooks. !31177
- Allow links to metrics dashboard at a specific time. !31283
- Enable embedding of specific metrics charts in GFM. !31304
- Support creating DAGs in CI config through the `needs` key. !31328
- Generate shareable link for specific metric charts. !31339
- Add support for Content-Security-Policy. !31402
- Add BitBucketServer project import filtering. !31420
- Embed specific metrics chart in issue. !31644
- Track page views for cycle analytics show page. !31717
- Add usage pings for source code pushes. !31734
- Makes collapsible title clickable in job log.
- Adds highlight to the collapsible section.

### Other (36 changes, 9 of them are from the community)

- Rewrite `if:` argument in before_action and alike when `only:` is also used. !24412 (George Thomas @thegeorgeous)
- Create rake tasks for migrating legacy uploads out of deprecated paths. !29409
- Remove the warning style from the U2F device message in user settings > account. !30119 (matejlatin)
- Set visibility level 'Private' for restricted 'Internal' imported projects when 'Internal' visibility setting is restricted in admin settings. !30522
- Change BoardService in favor of boardsStore on board blank state of the component board. !30546 (eduarmreyes)
- Adds Sidekiq scheduling latency structured logging field. !30784
- Adds chaos endpoints to Sidekiq. !30814
- Added multi-select deletion of container registry images. !30837
- When GitLab import fails during importer user mapping step, add an explicit error message mentioning importer. !30838
- Add Rugged calls and duration to API and Rails logs. !30871
- Fixed distorted avatars when resource not reachable. !30904 (Marc Schwede)
- Update GitLab Runner Helm Chart to 0.7.0. !30950
- Use Rails 5.2 Redis caching store. !30966
- Add Rugged calls to performance bar. !30983
- add color selector to broadcast messages form. !30988
- Harmonize selections in user settings. !31110 (Marc Schwede)
- Update rouge to v3.7.0. !31254
- Update 'Ruby on Rails' project template. !31310
- Fix mirroring help text. !31348 (jramsay)
- Enhance style of the shared runners limit. !31386
- Enables storage statistics for root namespaces on database. !31392
- Improve quick action error messages. !31451
- Enable authenticated cookie encryption. !31463
- Update karma to 4.2.0. !31495 (Takuya Noguchi)
- Add max_replication_slots to PG HA documentation. !31534
- Create database tables for the new cycle analytics backend. !31621
- Updated the detached pipeline badge tooltip text to offer a better explanation. !31626
- Add Gitaly and Rugged call timing in Sidekiq logs. !31651
- Fix the style-lint errors and warnings for `app/assets/stylesheets/pages/wiki.scss`. !31656
- Update GraphicsMagick from 1.3.29 to 1.3.33 for CI tests. !31692 (Takuya Noguchi)
- Migrate remaining users with null private_profile. !31708
- Bump Helm to 2.14.3 and kubectl to 1.11.10 for Kubernetes integration. !31716
- Updated the personal access token api scope description to reflect the permissions it grants. !31759
- Add finished_at to the internal API Deployment entity. !31808
- Remove Security Dashboard feature flag. !31820
- Update Packer.gitlab-ci.yml to use latest image. (Kelly Hair)


## 12.1.14

### Security (1 change)

- Limit search for IID to a type to avoid leaking records with the same IID that the user does not have access to.


## 12.1.12

### Security (12 changes)

- Add a policy check for system notes that may not be visible due to cross references to private items.
- Display only participants that user has permission to see on milestone page.
- Do not disclose project milestones on group milestones page when project milestones access is disabled in project settings.
- Check permissions before showing head pipeline blocking merge requests.
- Fix new project path being disclosed through unsubscribe link of issue/merge requests.
- Prevent bypassing email verification using Salesforce.
- Do not show resource label events referencing not accessible labels.
- Cancel all running CI jobs triggered by the user who is just blocked.
- Fix Gitaly SearchBlobs flag RPC injection.
- Only render fixed number of mermaid blocks.
- Prevent GitLab accounts takeover if SAML is configured.
- Upgrade mermaid to prevent XSS.


## 12.1.10

- No changes.

## 12.1.5

### Security (2 changes)

- Upgrade Gitaly to 1.53.2 to prevent revision flag injection exploits.
- Upgrade pages to 1.7.1 to prevent gitlab api token recovery from cookie.


## 12.1.4

### Fixed (3 changes, 1 of them is from the community)

- Properly translate term in projects list. !30958
- Add exclusive lease to mergeability check process. !31082
- Fix Docker in Docker (DIND) listen port behavior change by adding DOCKER_TLS_CERTDIR in CI job templates. !31201 (Cameron Boulton)

### Performance (1 change)

- Improve job log rendering performance. !31262


## 12.1.3

### Fixed (11 changes)

- Prevent multiple confirmation modals from opening when deleting a repository. !30532
- Fix the project auto devops API. !30946
- Fix "Certificate misses intermediates" UI error when enabling Let's Encrypt integration for pages domain. !30995
- Fix xterm css not loading for environment terminal. !31023
- Set DOCKER_TLS_CERTDIR in Auto Dev-Ops CI template to fix jobs using Docker-in-Docker. !31078
- Set DOCKER_TLS_CERTDIR in CI job templates to fix Docker-in-Docker service. !31080
- Support Docker OCI images. !31127
- Fix error rendering submodules in MR diffs when there is no .gitmodules. !31162
- Fix pdf.js rendering pages in the wrong order. !31222
- Fix exception handling in Gitaly autodetection. !31285
- Fix bug that caused diffs not to show on MRs with changes to submodules.

### Performance (1 change)

- Optimise import performance. !31045


## 12.1.2

### Security (1 change)

- Use source project as permissions reference for MergeRequestsController#pipelines.

### Security (9 changes)

- Restrict slash commands to users who can log in.
- Patch XSS issue in wiki links.
- Queries for Upload should be scoped by model.
- Filter merge request params on the new merge request page.
- Fix Server Side Request Forgery mitigation bypass.
- Show badges if pipelines are public otherwise default to project permissions.
- Do not allow localhost url redirection in GitHub Integration.
- Do not show moved issue id for users that cannot read issue.
- Drop feature to take ownership of trigger token.


## 12.1.1

- No changes.

## 12.1.0

### Security (11 changes, 2 of them are from the community)

- Update tar to 2.2.2. !29949 (Takuya Noguchi)
- Update lodash to 4.7.14 and lodash.mergewith to 4.6.2. !30602 (Takuya Noguchi)
- Correctly check permissions when creating snippet notes.
- Gate MR head_pipeline behind read_pipeline ability.
- Prevent Billion Laughs attack.
- Add missing authorizations in GraphQL.
- Fix Denial of Service for comments when rendering issues/MR comments.
- Expose merge requests count based on user access.
- Fix DoS vulnerability in color validation regex.
- Prevent the detection of merge request templates by unauthorized users.
- Persist tmp snippet uploads at users.

### Removed (7 changes)

- Disable Kubernetes credential passthrough for managed project-level clusters. !29262
- Remove deprecated group routes. !29351
- Remove support for creating non-RBAC kubernetes clusters. !29614
- Remove Kubernetes service integration and Kubernetes service template from available deployment platforms. !29786
- Remove MySQL support. !29790
- Remove depreated /u/:username routing. !30044
- Remove support for legacy pipeline triggers. !30133

### Fixed (84 changes, 14 of them are from the community)

- Update a user's routes after updating their name. !23272
- Show poper panel when validation error occurs in admin settings panels. !25434
- Expect bytes from Gitaly RPC GetRawChanges. !28164
- Sanitize LDAP output in Rake tasks. !28427
- Left align mr widget icons and text. !28561
- Keep the empty folders in the tree. !29196
- Fix incorrect emoji placement in commit diff discussion. !29445
- Fix favicon path with uploads of object store. !29482 (Roger Meier)
- Remove duplicate trailing +/- char in merge request discussions. !29518
- Fix the signup form's username validation messages not displaying. !29678 (Jiaan Louw)
- Fix broken environment selector and always display it on monitoring dashboard. !29705
- Fix Container Scanning job timeout when using the kubernetes executor. !29706
- Look for new branches more carefully. !29761
- Fix nested lists unnecessary margin. !29775 (Kuba Kopeć)
- Fix reports jobs timing out because of cache. !29780
- Fix Double Border in Profile Page. !29784 (Yoginth <@yo>)
- Remove minimum character limits for fuzzy searches when using a CTE. !29810
- Set default sort method for dashboard projects list. !29830 (David Palubin)
- Protect TeamCity builds from triggering when a branch has been deleted. And a MR-option. !29836 (Nikolay Novikov, Raphael Tweitmann)
- Fix pipeline schedule does not run correctly when it's scheduled at the same time with the cron worker. !29848
- Always shows author of created issue/started discussion/comment in HTML body and text of email. !29886 (Frank van Rest)
- Build correct basenames for title search results. !29898
- Resolve "500 error when forking via the web IDE button". !29909
- Turn commit sha in monitor charts popover to link. !29914
- Fix broken URLs for uploads with a plus in the filename. !29915
- Retry fetching Kubernetes Secret#token (#63507). !29922
- Enforce presence of pipeline when "Pipeline must succeed" project setting is enabled. !29926
- Fix unresponsive reply button in discussions. !29936
- Allow asynchronous rebase operations to be monitored. !29940
- Resolve Avatar in Please sign in pattern too large. !29944
- Persist the cluster a deployment was deployed to. !29960
- Fix runner tags search dropdown being empty when there are tags. !29985
- Display the correct amount of projects being migrated/rolled-back to Hashed Storage when specifying ranges. !29996
- Resolve Environment details header border misaligned. !30011
- Correct link to docs for External Dashboard. !30019
- Fix Jupyter-Git integration. !30020 (Amit Rathi)
- Update Mermaid to 8.1.0. !30036
- Fix background migrations failing with unused replication slot. !30042
- Disable Rails SQL query cache when applying service templates. !30060
- Set higher TTL for write lock of trace to prevent concurrent archiving. !30064
- Fix charts on Cluster health page. !30073
- Display boards filter bar on mobile. !30120
- Fix IDE editor not showing when switching back from preview. !30135
- Support note position tracing on an image. !30158
- Replace slugifyWithHyphens with improved slugify function. !30172 (Luke Ward)
- 'Open' and 'Closed' issue board lists no longer display a redundant tooltip. !30187
- Fix pipelines table to update without refreshing after action. !30190
- Change ruby_process_start_time_seconds metric to unix timestamp instead of seconds from boot. !30195
- Fix attachments using the wrong URLs in e-mails. !30197
- Make sure UnicornSampler is started only in master process. !30215
- Don't show image diff note on text file. !30221
- Fix median counting for cycle analytics. !30229
- In WebIDE allow adding new entries of the same name as deleted entry. !30239
- Don't let logged out user do manual order. !30264
- Skip spam check for task list updates. !30279
- Make Housekeeping button do a full garbage collection. !30289
- Removing an image should not output binary data. !30314
- Fix spacing issues for toasts. !30345
- Fix race in forbid_sidekiq_in_transactions.rb. !30359
- Fixed back navigation for projects filter. !30373
- Fix environments broken terminal. !30401
- Fix invalid SSL certificate errors on Drone CI service. !30422
- Fix subgroup url in search drop down. !30457
- Make unicorn_workers to return meaningful results. !30506
- Fix wrong URL when creating milestones from instance milestones dashboard. !30512
- Fixed incorrect line wrap for assignee label in issues. !30523 (Marc Schwede)
- Improves section header whitespace on the CI/CD Charts page. !30531
- Prevent multiple confirmation modals from opening when deleting a repository. !30532
- Aligns CI icon in Merge Request dashboard. !30558
- Add text-secondary to controls in project list. !30567
- Review Tools: Add large z-index to toolbar. !30583
- Hide restricted and disallowed visibility radios. !30590
- Resolve Label picker: Line break on long label titles. !30610
- Fix a bug that prevented projects containing merge request diff comments from being imported. !30630
- I fixed z index bug in diff page. !30657 (Faruk Can)
- Allow client authentication method to be configured for OpenID Connect. !30683 (Vincent Fazio)
- Fix commenting before discussions are loaded. !30724
- Fix linebreak rendering in Mermaid flowcharts. !30730
- Make httpclient respect system SSL configuration. !30749
- Bump fog-aws to v3.5.2. !30803
- API: Allow changing only ci_default_git_depth. !30888 (Mathieu Parent)
- Search issuables by iids. (Riccardo Padovani)
- Fix broken warnings while Editing Issues and Edit File on MR.
- Make sure we are receiving the proper information on the MR Popover by updating the IID in the graphql query.

### Changed (39 changes, 8 of them are from the community)

- Improve group list UI. !26542
- Backport and Docs for Paginate license management and add license search. !27602
- Update merge requests section description text on project settings page. !27838
- Knative version bump 0.5 -> 0.6. !28798 (Chris Baumbauer)
- Add salesforce logo for salesforce SSO. !28857
- Enforced requirements for UltraAuth users. !28941 (Kartikey Tanna)
- Return 400 when deleting tags more often than once per hour. !29448
- Add identity information to external authorization requests. !29461
- Enable just-in-time Kubernetes resource creation for project-level clusters. !29515
- renamed discussion to thread in merge-request and issue timeline. !29553 (Michel Engelen)
- Changed HTTP Status Code for disabled repository on /branches and /commits to 404. !29585 (Sam Battalio)
- Enable Git object pools. !29595 (jramsay)
- Updated container registry to display error message when special characters in path. Documentation has also been updated. !29616
- Allow developers to delete tags. !29668
- Will not update issue timestamps when changing positions in a list. !29677
- Include a link back to the MR for Visual Review feedback form. !29719
- Improve discussion reply buttons layout and how jump to next discussion button appears. !29779
- Renders a pre-release tag for releases. !29797
- Migrate NULL values for users.private_profile column and update users API to reject null value for private_profile. !29888
- Re-name files in Web IDE in a more natural way. !29948
- Include events from subgroups in group's activity. !29953 (Fabian Schneider @fabsrc)
- Upgrade to Gitaly v1.49.0. !29990
- Remove group and instance clusters feature flag. !30124
- Add support for creating random passwords in user creation API. !30138
- Support CIDR notation in IP rate limiter. !30146
- Add Redis call details in Peek performance bar. !30191
- Create Knative role and binding with service account. !30235
- Add cleanup migration for MR's multiple assignees. !30261
- Updates PHP template to php:latest to ensure always targeting latest stable. !30319 (Paul Giberson)
- Format `from` and `to` fields in JSON audit log. !30333
- Upgrade to Gitaly v1.51.0. !30353
- Modify cycle analytics on project level. !30356
- Extract clair version as CLAIR_EXECUTABLE_VERSION variable and update clair executable from v8 to v11. !30396
- Upgrade Rouge to 3.5.1. !30431
- Move multiple issue boards to core. !30503
- Upgrade to Gitaly v1.52.0. !30568
- Upgrade to Gitaly v1.53.0. !30614
- Open WebIDE in fork when user doesn't have access. !30642
- Propagate python version variable. (Can Eldem)

### Performance (25 changes, 1 of them is from the community)

- Remove tooltip directive on project avatar image component. !29631 (George Tsiolis)
- Use Rugged if we detect storage is NFS and we can access the disk. !29725
- Add endpoint for fetching diverging commit counts. !29802
- Cache feature flag names in Redis for a minute. !29816
- Avoid storing backtraces from Bitbucket Cloud imports in the database. !29862
- Remove import columns from projects table. !29863
- Enable Gitaly ref name caching for discussions.json. !29951
- Allow caching of negative FindCommit matches. !29952
- Eliminate N+1 queries in Dashboard::TodosController. !29954
- Memoize non-existent custom appearances. !29957
- Add a separate endpoint for fetching MRs serialized as widgets. !29979
- Use CTE to fetch clusters hierarchy in single query. !30063
- Enable Gitaly ref caching for SearchController. !30105
- Avoid loading pipeline status in search results. !30111
- Improve performance of MergeRequestsController#ci_environment_status endpoint. !30224
- Add a memory cache local to the thread to reduce Redis load. !30233
- Cache Flipper persisted names directly to local memory storage. !30265
- Limit amount of JUnit tests returned. !30274
- Cache Flipper feature flags in L1 and L2 caches. !30276
- Prevent amplification of ReactiveCachingWorker jobs upon failures. !30432
- Allow ReactiveCaching to support nil value. !30456
- Improve performance of fetching environments statuses. !30560
- Do Redis lookup in batches in ActiveSession.sessions_from_ids. !30561
- Remove catfile cache feature flag. !30750
- Fix Gitaly auto-detection caching. !30954

### Added (46 changes, 12 of them are from the community)

- Document the negative commit message push rule for the API. !14004 (Maikel Vlasman)
- Expose saml_provider_id in the users API. !14045
- Improve Project API. !28327 (Mathieu Parent)
- Remove Sentry from application settings. !28447 (Roger Meier)
- Implement borderless discussion design with new reply field. !28580
- Enable terminals for instance and group clusters. !28613
- Resolve Multiple discussions per line in merge request diffs. !28748
- Adds link to Grafana in Admin > Monitoring settings when grafana is enabled in config. !28937 (Romain Maneschi)
- Bring Manual Ordering on Issue List. !29410
- Added commit type to tree GraphQL response. !29412
- New API for User Counts, updates on success of an MR the count on top and in other tabs. !29441
- Add option to limit time tracking units to hours. !29469 (Jon Kolb)
- Add confirmation for registry image deletion. !29505
- Sync merge ref upon mergeability check. !29569
- Show an Upcoming Status for Releases. !29577
- Add order_by and sort params to list runner jobs api. !29629 (Sujay Patel)
- Allow custom username for deploy tokens. !29639
- Add a verified pill next to email addresses under the admin users section. !29669
- Add rake task to clean orphan artifact files. !29681
- Render GFM in GraphQL. !29700
- Upgrade asciidoctor version to 2.0.10. !29741 (Rajendra Kadam)
- Allow auto-completing scoped labels. !29749
- Enable syntax highlighting for AsciiDoc. !29835 (Guillaume Grossetie)
- Expose placeholder element for metrics charts in GFM. !29861
- Added a min schema version check to db:migrate. !29882
- Extract zoom link from issue and pass to frontend. !29910 (raju249)
- GraphQL mutations for add, remove and toggle emoji. !29919
- Labeled issue boards can now collapse. !29955
- Allow Ingress to be uninstalled from the UI. !29977
- Add permission check to metrics dashboards endpoint. !30017
- Allow JupyterHub to be uninstalled from the UI. !30097
- Allow GitLab Runner to be uninstalled from the UI. !30176
- GraphQL mutations for managing Notes. !30210
- Add API for CRUD group clusters. !30213
- Add endpoint to move multiple issues in boards. !30216
- Enable terminals button for group clusters. !30255
- Prevent excessive sanitization of AsciiDoc ouptut. !30290 (Guillaume Grossetie)
- Extend `MergeToRefService` to create merge ref from an arbitrary ref. !30361
- Add CI variable to provide GitLab HOST. !30417
- Add migration for adding rule_type to approval_project_rules. !30575
- Enable section anchors in Asciidoctor. !30666 (Guillaume Grossetie)
- Preserve footnote link ids in Asciidoctor. !30790 (Guillaume Grossetie)
- Add support for generating SSL certificates for custon pages domains through Let's Encrypt.
- Introduce default: for gitlab-ci.yml.
- Move Multiple Issue Boards for Projects to Core.
- Add Gitaly data to the usage ping.

### Other (35 changes, 15 of them are from the community)

- Remove unresolved class and fixed height in discussion header. !28440 (David Palubin)
- Moved EE/CE code differences for file `app/views/search/_category.html.haml` into CE. !28755 (Michel Engelen)
- Changes "Todo" to "To Do" in the UI for clarity. !28844
- Migrate GitLab managed project-level clusters to unmanaged if a Kubernetes namespace was unable to be created. !29251
- Migrate GitLab managed project-level clusters to unmanaged if they are missing a Kubernetes service account token. !29648
- Add strategies column to operations_feature_flag_scopes table. !29808
- Disallow `NULL` values for `geo_nodes.primary` column. !29818 (Arun Kumar Mohan)
- Replace 'JIRA' with 'Jira'. !29849 (Takuya Noguchi)
- Support jsonb default in add_column_with_default migration helper. !29871
- Update pagination prev and next texts. !29911
- Adds metrics to measure cost of expensive operations. !29928
- Always allow access to health endpoints from localhost in dev. !29930
- Update GitLab Runner Helm Chart to 0.6.0. !29982
- Use darker gray color for system note metadata and edited text. !30054
- Fix typo in docs about Elasticsearch. !30162 (Takuya Noguchi)
- Fix typo in code comments about Elasticsearch. !30163 (Takuya Noguchi)
- Update mixin-deep to 1.3.2. !30223 (Takuya Noguchi)
- Migrate markdown header_spec.js to Jest. !30228 (Martin Hobert)
- Remove istanbul JavaScript package. !30232 (Takuya Noguchi)
- Centralize markdownlint configuration. !30263
- Use PostgreSQL 9.6.11 in CI tests. !30270 (Takuya Noguchi)
- Fix typo in updateResolvableDiscussionsCounts action. !30278 (Frank van Rest)
- Change color for namespace in commit search. !30312
- Remove applySuggestion from notes service. !30399 (Frank van Rest)
- Improved readability of storage statistics in group / project admin area. !30406
- Alignign empty container registry message with design guidelines. !30502
- Remove toggleAward from notes service. !30536 (Frank van Rest)
- Remove deleteNote from notes service. !30537 (Frank van Rest)
- change the use of boardService in favor of boardsStore on footer for the board component. !30616 (eduarmreyes)
- Update example Prometheus scrape config. !30739
- Update GitLab Pages to v1.7.0.
- Add token_encrypted column to operations_feature_flags_clients table.
- Removes EE diff for app/views/profiles/preferences/show.html.haml.
- Removes EE differences for app/views/layouts/fullscreen.html.haml.
- Removes EE differences for app/views/admin/users/show.html.haml.


## 12.0.12

- No changes.

## 12.0.10

- No changes.
- No changes.

## 12.0.7

### Security (22 changes)

- Ensure only authorised users can create notes on Merge Requests and Issues.
- Add :login_recaptcha_protection_enabled setting to prevent bots from brute-force attacks.
- Queries for Upload should be scoped by model.
- Speed up regexp in namespace format by failing fast after reaching maximum namespace depth.
- Limit the size of issuable description and comments.
- Send TODOs for comments on commits correctly.
- Restrict MergeRequests#test_reports to authenticated users with read-access on Builds.
- Added image proxy to mitigate potential stealing of IP addresses.
- Filter out old system notes for epics in notes api endpoint response.
- Avoid exposing unaccessible repo data upon GFM post processing.
- Fix HTML injection for label description.
- Make sure HTML text is always escaped when replacing label/milestone references.
- Prevent DNS rebind on JIRA service integration.
- Use admin_group authorization in Groups::RunnersController.
- Prevent disclosure of merge request ID via email.
- Show cross-referenced MR-id in issues' activities only to authorized users.
- Enforce max chars and max render time in markdown math.
- Check permissions before responding in MergeController#pipeline_status.
- Remove EXIF from users/personal snippet uploads.
- Fix project import restricted visibility bypass via API.
- Fix weak session management by clearing password reset tokens after login (username/email) are updated.
- Fix SSRF via DNS rebinding in Kubernetes Integration.


## 12.0.6

- No changes.

## 12.0.3 (2019-06-27)

- No changes.
### Security (10 changes)

- Persist tmp snippet uploads at users.
- Gate MR head_pipeline behind read_pipeline ability.
- Fix DoS vulnerability in color validation regex.
- Expose merge requests count based on user access.
- Fix Denial of Service for comments when rendering issues/MR comments.
- Add missing authorizations in GraphQL.
- Disable Rails SQL query cache when applying service templates.
- Prevent Billion Laughs attack.
- Correctly check permissions when creating snippet notes.
- Prevent the detection of merge request templates by unauthorized users.


## 12.0.2 (2019-06-25)

### Fixed (7 changes, 1 of them is from the community)

- Fix missing API notification flags for Microsoft Teams. !29824 (Seiji Suenaga)
- Fixed 'diff version changes' link not working. !29825
- Fix label serialization in issue and note hooks. !29850
- Include the GitLab version in the cache key for Gitlab::JsonCache. !29938
- Prevent EE backport migrations from running if CE is not migrated. !30002
- Silence backup warnings when CRON=1 in use. !30033
- Fix comment emails not respecting group-level notification email.

### Performance (1 change)

- Omit issues links in merge request entity API response. !29917


## 12.0.1 (2019-06-24)

- No changes.

## 12.0.0 (2019-06-22)

### Security (10 changes)

- Prevent bypass of restriction disabling web password sign in.
- Hide confidential issue title on unsubscribe for anonymous users.
- Resolve: Milestones leaked via search API.
- Fix url redaction for issue links.
- Add extra fields for handling basic auth on import by url page.
- Fix confidential issue label disclosure on milestone view.
- Filter relative links in wiki for XSS.
- Prevent invalid branch for merge request.
- Prevent XSS injection in note imports.
- Protect Gitlab::HTTP against DNS rebinding attack.

### Removed (5 changes, 1 of them is from the community)

- Remove ability for group clusters to be automatically configured on creation. !27245
- Removes support for AUTO_DEVOPS_DOMAIN. !28460
- Remove the circuit breaker API. !28669
- Make Kubernetes service templates readonly. !29044
- Remove Content-Type override for Mattermost OAuth login. (Harrison Healey)

### Fixed (115 changes, 28 of them are from the community)

- Fix col-sm-* in forms to keep layout. !24885 (Takuya Noguchi)
- Avoid 500 when rendering users ATOM data. !25408
- Fix flyout nav on small viewports. !25998
- Fix proxy support in Container Scanning. !27246
- preventing blocked users and their PipelineSchdules from creating new Pipelines. !27318
- Fix yaml linting for GitLab CI inside project (.gitlab/ci) *.yml files and CI template files. !27576 (Will Hall)
- Fix yaml linting for project root *.yml files. !27579 (Will Hall)
- Added a content field to atom feed. !27652
- Bring secondary button styles up to design standard. !27920
- Use FindOrCreateService to create labels and check for existing ones. !27987 (Matt Duren)
- Fix "too many loops" error by handling gracefully cron schedules for non existent days. !28002
- Fix 500 error when accessing charts with an anonymous user. !28091 (Diego Silva)
- Allow user to set primary email first when 2FA is required. !28097 (Kartikey Tanna)
- Auto-DevOps: allow to disable rollout status check. !28130 (Sergej Nikolaev <kinolaev@gmail.com>)
- Resolved JIRA service: NoMethodError: undefined method 'find' for nil:NilClass. !28206
- Supports Matomo/Piwik string website ID ("Protect Track ID" plugin). !28214 (DUVERGIER Claude)
- Fix loading.. dropdown at search field. !28275 (Pavel Chausov)
- Remove unintended error message shown when moving issues. !28317
- Properly clear the merge error upon rebase failure. !28319
- Upgrade dependencies for node 12 compatibility. !28323
- Fix. `db:migrate` is failed on MySQL 8. !28351 (sue445)
- Fix an error in projects admin when statistics are missing. !28355
- Fix emojis URLs. !28371
- Prevent common name collisions when requesting multiple Let's Encrypt certificates concurrently. !28373
- Fix issue that causes "Save changes" button in project settings pages to be enabled/disabled incorrectly when changes are made to the form. !28377
- Fix diff notes and discussion notes being exported as regular notes. !28401
- Fix padding in MR widget. !28472
- Updates loading icon in commits page. !28475
- Fix border radius of discussions. !28490
- Update broadcast message action icons. !28496 (Jarek Ostrowski @jareko)
- Update icon color to match design system, pass accessibility. !28498 (Jarek Ostrowski @jareko)
- Show data on Cycle Analytics page when value is less than a second. !28507
- Fix dropdown position when loading remote data. !28526
- Delete unauthorized Todos when project is made private. !28560
- Change links in system notes to use relative paths. !28588 (Luke Picciau)
- Update favicon from next. !28601 (Jarek Ostrowski @jareko)
- Open visibility help link in a new tab. !28603 (George Tsiolis)
- Fix issue importing members with owner access. !28636
- Fix the height of the page headers on issues/merge request/snippets pages. !28650 (Erik van der Gaag)
- Always show "Pipelines must succeed" checkbox. !28651
- Resolve moving an issue results in broken image links in comments. !28654
- Fix milestone references containing &, <, or >. !28667
- Add hover and focus to Attach a file. !28682
- Correctly word-wrapping project descriptions with very long words. !28695 (Erik van der Gaag)
- Prevent icons from shrinking in User popover when contents exceed container. !28696
- Allow removal of empty lines via suggestions. !28703
- Throw an error when formatDate's input is invalid. !28713
- Fix order dependency with user params during imports. !28719
- Fix search dropdown not closing on blur if empty. !28730
- Fixed ignored postgres version that occurs after the first autodevops deploy when specifying custom $POSTGRES_VERSION. !28735 (Brandon Dimcheff)
- Limit milestone dates to before year 9999. !28742 (Luke Picciau)
- Set project default visibility to max allowed. !28754
- Cancel auto merge when merge request is closed. !28782
- Fixes Ref link being displayed as raw HTML in the Pipelines page. !28823
- Fix job name in graph dropdown overflowing. !28824
- Add style to disable webkit icons for search inputs. !28833 (Jarek Ostrowski @jareko)
- Fix email notifications for user excluded actions. !28835
- Resolve Tooltip Consistency. !28839
- Fix Merge Request merge checkbox alignment on mobile view. !28845
- Add referenced-commands in no overflow list. !28858
- Fix participants list wrapping. !28873
- Excludes MR author from Review roulette. !28886 (Jacopo Beschi @jacopo-beschi)
- Give labels consistent weight. !28895
- Added padding to time window dropdown in monitor dashboard. !28897
- Move text under p tag. !28901
- Resolve Position is off when visiting files with anchors. !28913
- Fix whitespace changes visibility when the related file was initially collapsed. !28950 (Ondřej Budai)
- Fix emoji picker visibility issue. !28984
- Resolve Merge request discussion text jumps when resolved. !28995
- Allow lowercase prefix for Youtrack issue ids. !29057 (Matthias Baur)
- Add support to view entirety of long branch name in dropdown instead of it being cut off. !29069
- Fix inconsistent option dropdown button height to match adjacent button. !29096
- Improve new user email markup unconsistency between text and html parts. !29111 (Haunui Saint-sevin)
- Eliminate color inconsistencies in metric graphs. !29127
- Avoid setting Gitlab::Session on sessionless requests and Git HTTP. !29146
- Use the selected time window for metrics dashboard. !29152
- Remove build policies from serverless app template. !29253
- Fix serverless apps deployments by bumping 'tm' version. !29254
- Include the port in the URLs of the API Link headers. !29267
- Fix Fogbugz Importer not working. !29383
- Fix GPG signature verification with recent GnuPG versions. !29388 (David Palubin)
- Cancel Auto Merge when target branch is changed. !29416
- Fix nil coercion updating storage size on project statistics. !29425
- Ignore legacy artifact columns in Project Import/Export. !29427
- Avoid DB timeouts when scheduling migrations. !29437
- Handle encoding errors for MergeToRefService. !29440
- Fix UTF-8 conversion issues when resolving conflicts. !29453
- Enlarge metrics time-window dropdown links. !29458
- Remove unnecessary decimals on Metrics chart axis. !29468
- Fix scrolling to top on assignee change. !29500
- Allow command/control click to open link in new tab on Merge Request tabs. !29506
- Omit blocked admins from repository check e-mails. !29507
- Fix diverged branch locals. !29508
- Process up to 100 commit messages for references when pushing to a new default branch. !29511 (Fabio Papa)
- Allow developer role to delete docker tags via container registry API. !29512
- Fix "Resolve conflicts" button not appearing for some users. !29535
- Fix: propagate all documented ENV vars to CI when using SAST. !29564
- AutoDevops function ensure_namespace() now explicitly tests the namespace. !29567 (Jack Lei)
- Fix sidebar flyout navigation. !29571
- Fix missing deployment rockets in monitor dashboard. !29574
- Fix inability to set visibility_level on project via API. !29578
- Ensure a Kubernetes namespace is not used for deployments if there is no service account token associated with it. !29643
- Refresh service_account_token for kubernetes_namespaces. !29657
- Expose all current events properly on services API. !29736 (Zsolt Kovari)
- Move Dropdown to Stick to MR View App Button. !29767
- Fix IDE commit using latest ref in branch and overriding contents. !29769
- Revert concurrent pipeline creation for pipeline schedules. !29794
- Fix border radii on diff files and repo files.
- Fix padding of unclickable pipeline dropdown items to match links.
- Fix pipeline schedules when owner is nil.
- Fix remote mirrors not updating after tag push.
- Fix layout of group milestone header.
- Fixed show whitespace button not refetching diff content.
- Change resolve button text to mark comment as resolved.
- Align system note within discussion with other notes.

### Changed (35 changes, 13 of them are from the community)

- Include information if issue was clossed via merge request or commit. !15610 (Michał Zając)
- Removes duplicated members from api/projects/:id/members/all. !24005 (Jacopo Beschi @jacopo-beschi)
- Apply the group setting "require 2FA" across all subgroup members as well when changing the group setting. !24965 (rroger)
- Enable function features for external Knative installations. !27173
- Remove dind from DAST template. !28083
- Update registration form to indicate invalid name or username length on input. !28095 (Jiaan Louw)
- Default masked to false for new variables. !28186
- Better isolated `Docker.gitlab-ci.yml` to avoid interference with other job configurations. !28213 (lrkwz)
- Remove the mr_push_options feature flag. !28278
- Replace Oxygen-Sans font with Noto Sans. !28322
- Update new smiley icons, find n replace old names with new ones. !28338 (Jarek Ostrowski)
- Adds a text label to color pickers to improve accessibility. !28343 (Chris Toynbee)
- Prioritize login form on mobile breakpoint. !28360
- Move some project routes under /-/ scope. !28435
- I18n for issue closure reason in emails. !28489 (Michał Zając)
- Geo: Remove Gitlab::LfsToken::LegacyRedisDeviseToken implementation and usage. !28546
- Add check circle filled icon for resolved comments. !28663
- Update project security dashboard documentation. !28681
- Remove `docker pull` prefix when copying a tag from the registry. !28757 (Benedikt Franke)
- Adjust milestone completion rate to be based on issues count. !28777
- Enhance line-height of Activity feed UI. !28856 (Jacopo Beschi @jacopo-beschi)
- Upgrade to Gitaly v1.43.0. !28867
- Do not display Update app button when saving Knative domain name. !28904
- Rebrush of flash-warning according to the new design (brighter background and darker font). !28916 (Michel Engelen)
- Added reference, web_path, and relative_position fields to GraphQL Issue. !28998
- Change logic behind cycle analytics. !29018
- Add documentation links for confidental and locked discussions. !29073
- Update GITALY_SERVER_VERSION to 1.45.0. !29109
- Allow masking if 8 or more characters in base64. !29143 (thomas-nilsson-irfu)
- Replaces sidekiq mtail metrics with ruby instrumentation metrics. !29215
- Allow references to labels and milestones to contain emoji. !29284
- changed the styles on `Add List` dropdown to look more like the EE vesion. !29338 (Michel Engelen)
- Hashed Storage is enabled by default on new installations. !29586
- Upgrade to Gitaly v1.47.0. !29789
- Default MR checkbox to true in most cases.

### Performance (11 changes)

- Improve performance of jobs controller. !28093
- Upgrade Ruby version to 2.6.3. !28117
- Make pipeline schedule worker resilient. !28407
- Fix performance issue with large Markdown content in issue or merge request description. !28597
- Improve clone performance by using delta islands. !28871
- Reduce Gitaly calls to improve performance when rendering suggestions. !29027
- Use Redis for CacheMarkDownField on non AR models. !29054
- Add index on public_email for users. !29430
- Speed up commit loads by disabling BatchLoader replace_methods. !29633
- Add index on invite_email for members. !29768
- Improve performance of users autocomplete when there are lots of results.

### Added (47 changes, 12 of them are from the community)

- Added option to filter jobs by age in the /job/request API endpoint. !1340 (Dmitry Chepurovskiy)
- Add ability to define notification email addresses for groups you belong to. !25299
- Add wiki size to project statistics. !25321 (Peter Marko)
- 58404 - setup max depth for GraphQL. !25737 (Ken Ding)
- Add auto SSL toggle option to Pages domain settings page. !26438
- Empty project state for Web IDE. !26556
- Add support for multiple job parents in GitLab CI YAML. !26801 (Wolphin (Nikita))
- Pass user's identity and token from JupyterHub to user's Jupyter environment. !27314 (Amit Rathi)
- Add issues_statistics api endpoints and extend issues search api. !27366
- Validate Kubernetes credentials at cluster creation. !27403
- Update the merge request widget's "Merge" button to support merge trains. !27594
- Style the toast component according to design specs. !27734
- Add API support for committing changes to different projects in same fork network. !27915
- Add support for && and || to CI Pipeline Expressions. Change CI variable expression matching for Lexeme::Pattern to eagerly return tokens. !27925 (Martin Manelli)
- Added ref querystring parameter to project search API to allow searching on branches/tags other than the default. !28069 (Lee Tickett)
- Add notify_only_default_branch option to PipelinesEmailService. !28271 (Peter Marko)
- Support multiplex GraphQL queries. !28273
- Add Namespace and ProjectStatistics to GraphQL API. !28277
- Display classname JUnit attribute in report modal. !28376
- API: Allow to get and set "masked" attribute for variables. !28381 (Mathieu Parent)
- Add allow_failure attribute to Job API. !28406
- Add support for AsciiDoc include directive. !28417 (Jakub Jirutka & Guillaume Grossetie)
- Migrate Kubernetes service integration templates to clusters. !28534
- Allow issue list to be sorted by relative order. !28566
- Implement borderless discussion design with new reply field. !28580
- Add expand/collapse to error tracking settings. !28619
- Adds collapsible sections for job log. !28642
- Add LFS oid to GraphQL blob type. !28666
- Allow users to specify a time range on metrics dashboard. !28670
- Add a New Copy Button That Works in Modals. !28676
- Add Kubernetes logs to Admin Logs UI. !28685
- Set up git client in Jupyter installtion. !28783 (Amit Rathi)
- Add task count and completed count to responses of Issue and MR. !28859
- Add project level git depth CI/CD setting. !28919
- Use global IDs when exposing GraphQL resources. !29080
- Expose wiki_size on GraphQL API. !29123
- Expose notes and discussions in GraphQL. !29212
- Use to 'gitlabktl' build serverless applications. !29258
- Adds pagination component for graphql api. !29277
- Allow switching clusters between managed and unmanaged. !29322
- Get and edit ci_default_git_depth via project API. !29353
- Link to an external dashboard from metrics dashboard. !29369
- Add labels to note event payload. !29384 (Sujay Patel)
- Add Join meeting button to issues with Zoom links. !29454
- Add backtraces to Peek performance bar for SQL calls.
- Added diff suggestion feature discovery popover.
- Make task completion status available via GraphQL.

### Other (62 changes, 14 of them are from the community)

- Unified EE/CS differences in repository/show.html. !13562
- Remove legacy artifact related code. !26475
- Backport the EE schema and migrations to CE. !26940 (Yorick Peterse)
- Add dedicated logging for GraphQL queries. !27885
- i18n: externalize strings from user profile settings. !28088 (Antony Liu)
- Omit max-count for diverging_commit_counts behind feature flag. !28157
- Fix alignment of resend button in members page. !28202
- Update indirect dependency fsevents from 1.2.4 to 1.2.9. !28220 (Takuya Noguchi)
- Update get_process_mem to 0.2.3. !28248
- Add Pool repository to the usage ping. !28267
- Forbid NULL in project_statistics.packages_size. !28400
- Update Gitaly to v1.42.1. !28425
- Upgrade babel to 7.4.4. !28437 (Takuya Noguchi)
- Externalize profiles preferences. !28470 (George Tsiolis)
- Update GitLab Runner Helm Chart to 0.5.0. !28497
- Change collapse icon size to size of profile picture. !28512
- Resolve Snippet icon button is misaligned. !28522
- Bumps Kubernetes in Auto DevOps to 1.11.10. !28525
- Bump Helm version in Auto-DevOps.gitlab-ci.yml to 2.14.0. !28527
- Migrate the monitoring dashboard store to vuex. !28555
- Give New Snippet button green outline. !28559
- Removes project_auto_devops#domain column. !28574
- Externalize strings of email page in user profile. !28587 (antony liu)
- Externalize strings of active sessions page in user profile. !28590 (antony liu)
- Refactor and abstract Auto Merge Processes. !28595
- Add section to dev docs on accessing chatops. !28623
- Externalize strings of chat page in user profile. !28632
- Externalize strings of PGP Keys and SSH Keys page in user profile. !28653 (Antony Liu)
- Added the `.extended-height` class to the labels-dropdown. !28659 (Michel Engelen)
- Moved EE/CE code differences for `app/assets/javascripts/gl_dropdown.js` into CE. !28711 (Michel Engelen)
- Update GitLab Runner Helm Chart to 0.5.1. !28720
- Remove support for using Geo with an installation from source. !28737
- API: change masked attribute type to Boolean. !28758
- API: change protected attribute type to Boolean. !28766
- Add a column header to admin/jobs page. !28837
- Reset merge status from mergeable MRs. !28843
- Show tooltip on truncated commit title. !28865 (Timofey Trofimov)
- Added conditional rendering to `app/views/search/_form.html.haml` for CE/EE code base consistency. !28883 (Michel Engelen)
- Change "Report abuse to GitLab" to more generic wording. !28884 (Marc Schwede)
- Update GitLab Pages to v1.6.0. !29048
- Update GitLab Runner Helm Chart to 0.5.2. !29050
- User link styling for commits. !29150
- Fix null source_project_id in pool_repositories. !29157
- Add deletion protection setting column to application_settings table. !29268
- Added code differnces from EE in file 'app/assets/javascripts/pages/projects/project.js' to CE. !29271 (Michel Engelen)
- Update to GitLab Shell v9.3.0. !29283
- Document when milestones and labels links are missing. !29355
- Make margin between buttons consistent. !29378
- Changed the 'Created' label to 'Last Updated' on the container registry table to more accurately reflect what the date represents. !29464
- Update GitLab Pages to v1.6.1. !29559
- Indent collapsible sections. !29804
- Use grid and correct border radius for status badge.
- Remove fixed height from MR diff headers.
- Use blue for activity stream links; use monospace font for commit sha.
- Moves snowplow to CE repo.
- Reduce height of issue board input to align with buttons.
- Change default color of award emoji button.
- Group download buttons into a .btn-group.
- Add warning that gitlab-secrets isn't included in backup.
- Increase height of move issue dropdown.
- Update merge request tabs so they no longer scroll.
- Moves the table pagination shared component.
