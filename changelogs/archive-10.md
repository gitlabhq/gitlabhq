## 10.8.6 (2018-07-17)

### Security (2 changes)

- Fix symlink vulnerability in project import.
- Merge branch 'fix-mr-widget-border' into 'master'.


## 10.8.5 (2018-06-21)

### Security (5 changes)

- Fix XSS vulnerability for table of content generation.
- Update sanitize gem to 4.6.5 to fix HTML injection vulnerability.
- HTML escape branch name in project graphs page.
- HTML escape the name of the user in ProjectsHelper#link_to_member.
- Don't show events from internal projects for anonymous users in public feed.


## 10.8.4 (2018-06-06)

- No changes.

## 10.8.3 (2018-05-30)

### Fixed (4 changes)

- Replace Gitlab::REVISION with Gitlab.revision and handle installations without a .git directory. !19125
- Fix encoding of branch names on compare and new merge request page. !19143
- Fix remote mirror database inconsistencies when upgrading from EE to CE. !19196
- Fix local storage not being cleared after creating a new issue.

### Performance (1 change)

- Memoize Gitlab::Database.main.version.


## 10.8.2 (2018-05-28)

### Security (3 changes)

- Prevent user passwords from being changed without providing the previous password.
- Fix API to remove deploy key from project instead of deleting it entirely.
- Fixed bug that allowed importing arbitrary project attributes.


## 10.8.1 (2018-05-23)

### Fixed (9 changes)

- Allow CommitStatus class to use presentable methods. !18979
- Fix corrupted environment pages with unathorized proxy url. !18989
- Fixes deploy token variables on Ci::Build. !19047
- Fix project mirror database inconsistencies when upgrading from EE to CE. !19109
- Render 404 when prometheus adapter is disabled in Prometheus metrics controller. !19110
- Fix error when deleting an empty list of refs.
- Fixed U2F login when used with LDAP.
- Bump prometheus-client-mmap to 0.9.3 to fix nil exception error.
- Fix system hook not firing for blocked users when LDAP sign-in is used.


## 10.8.0 (2018-05-22)

### Security (3 changes, 1 of them is from the community)

- Update faraday_middlewar to 0.12.2. !18397 (Takuya Noguchi)
- Serve archive requests with the correct file in all cases.
- Sanitizes user name to avoid XSS attacks.

### Fixed (47 changes, 11 of them are from the community)

- Refactor CSS to eliminate vertical misalignment of login nav. !16275 (Takuya Noguchi)
- Fix pipeline status in branch/tag tree page. !17995
- Allow group owner to enable runners from subgroups (#41981). !18009
- Fix template selector menu visibility when toggling preview mode in file edit view. !18118 (Fabian Schneider)
- Fix confirmation modal for deleting a protected branch. !18176 (Paul Bonaud @PaulRbR)
- Triggering custom hooks by Wiki UI edit. !18251
- Now `rake cache:clear` will also clear pipeline status cache. !18257
- Fix `joined` information on project members page. !18290 (Fabian Schneider)
- Fix missing namespace for some internal users. !18357
- Show shared projects on group page. !18390
- Restore label underline color. !18407 (George Tsiolis)
- Fix undefined `html_escape` method during markdown rendering. !18418
- Fix unassign slash command preview. !18447
- Correct text and functionality for delete user / delete user and contributions modal. !18463 (Marc Schwede)
- Fix discussions API setting created_at for notable in a group or notable in a project in a group with owners. !18464
- Don't include lfs_file_locks data in export bundle. !18495
- Reset milestone filter when clicking "Any Milestone" in dashboard. !18531
- Ensure member notifications are sent after the member actual creation/update in the DB. !18538
- Update links to /ci/lint with ones to project ci/lint. !18539 (Takuya Noguchi)
- Fix tabs container styles to make RSS button clickable. !18559
- Raise NoRepository error for non-valid repositories when calculating repository checksum. !18594
- Don't automatically remove artifacts for pages jobs after pages:deploy has run. !18628
- Increase new issue metadata form margin. !18630 (George Tsiolis)
- Add loading icon padding for pipeline environments. !18631 (George Tsiolis)
- ShaAttribute no longer stops startup if database is missing. !18726
- Fix close keyboard shortcuts dialog using the keyboard shortcut. !18783 (Lars Greiss)
- Fixes database inconsistencies between Community and Enterprise Edition on import state. !18811
- Add database foreign key constraint between pipelines and build. !18822
- Fix finding wiki pages when they have invalidly-encoded content. !18856
- Fix outdated Web IDE welcome copy. !18861
- fixed copy to blipboard button in embed bar of snippets. !18923 (haseebeqx)
- Disables RBAC on nginx-ingress. !18947
- Correct skewed Kubernetes popover illustration. !18949
- Resolve Import/Export ci_cd_settings error updating the project. !46049
- Fix project creation for user endpoint when jobs_enabled parameter supplied.
- 46210 Display logo and user dropdown on mobile for terms page and fix styling.
- Adds illustration for when job log was erased.
- Ensure web hook 'blocked URL' errors are stored in web hook logs and properly surfaced to the user.
- Make toggle markdown preview shortcut only toggle selected field.
- Verifiy if pipeline has commit idetails and render information in MR widget when branch is deleted.
- Fixed inconsistent protected branch pill baseline.
- Fix setting GitLab metrics content types.
- Display only generic message on merge error to avoid exposing any potentially sensitive or user unfriendly backend messages.
- Fix label links update on project transfer.
- Breaks commit not found message in pipelines table.
- Adjust issue boards list header label text color.
- Prevent pipeline actions in dropdown to redirct to a new page.

### Changed (35 changes, 15 of them are from the community)

- Improve tooltips in collapsed right sidebar. !17714
- Partition job_queue_duration_seconds with jobs_running_for_project. !17730
- For group dashboard, we no longer show groups which the visitor is not a member of (this applies to admins and auditors). !17884 (Roger Rüttimann)
- Use RFC 3676 mail signature delimiters. !17979 (Enrico Scholz)
- Add sha filter to pipelines list API. !18125
- New CI Job live-trace architecture. !18169
- Make project deploy keys table more clearly structured. !18279
- Remove green background from unlock button in admin area. !18288
- Renamed Overview to Project in the contextual navigation at a project level. !18295 (Constance Okoghenun)
- Load branches on new merge request page asynchronously. !18315
- Create settings section for autodevops. !18321
- Add a comma to the time estimate system notes. !18326
- Enable specifying variables when executing a manual pipeline. !18440
- Fix size and position for fork icon. !18449 (George Tsiolis)
- Refactored activity calendar. !18469 (Enrico Scholz)
- Small improvements to repository checks. !18484
- Add 2FA filter to users API for admins only. !18503
- Align project avatar on small viewports. !18513 (George Tsiolis)
- Show group and project LFS settings in the interface to Owners and Masters. !18562
- Update environment item action buttons icons. !18632 (George Tsiolis)
- Update timeline icon for description edit. !18633 (George Tsiolis)
- Revert discussion counter height. !18656 (George Tsiolis)
- Improve quick actions summary preview. !18659 (George Tsiolis)
- Change font for tables inside diff discussions. !18660 (George Tsiolis)
- Add padding to profile description. !18663 (George Tsiolis)
- Break issue title for board card title and issuable header text. !18674 (George Tsiolis)
- Adds push mirrors to GitLab Community Edition. !18715
- Inform the user when there are no project import options available. !18716 (George Tsiolis)
- Improve commit message body rendering and fix responsive compare panels. !18725 (Constance Okoghenun)
- Reconcile project templates with Auto DevOps. !18737
- Remove branch name from the status bar of WebIDE.
- Clean up WebIDE status bar and add useful info.
- Improve interaction on WebIDE commit panel.
- Keep current labels visible when editing them in the sidebar.
- Use VueJS for rendering pipeline stages.

### Performance (26 changes, 11 of them are from the community)

- Move WorkInProgress vue component. !17536 (George Tsiolis)
- Move ReadyToMerge vue component. !17545 (George Tsiolis)
- Move BoardBlankState vue component. !17666 (George Tsiolis)
- Improve DB performance of calculating total artifacts size. !17839
- Add i18n and update specs for UnresolvedDiscussions vue component. !17866 (George Tsiolis)
- Introduce new ProjectCiCdSetting model with group_runners_enabled. !18144
- Move PipelineFailed vue component. !18277 (George Tsiolis)
- Move TimeTrackingEstimateOnlyPane vue component. !18318 (George Tsiolis)
- Move TimeTrackingHelpState vue component. !18319 (George Tsiolis)
- Reduce queries on merge requests list page for merge requests from forks. !18561
- Destroy build_chunks efficiently with FastDestroyAll module. !18575
- Improve performance of a service responsible for creating a pipeline. !18582
- Replace time_ago_in_words with JS-based one. !18607 (Takuya Noguchi)
- Move TimeTrackingNoTrackingPane vue component. !18676 (George Tsiolis)
- Move SidebarTimeTracking vue component. !18677 (George Tsiolis)
- Move TimeTrackingSpentOnlyPane vue component. !18710 (George Tsiolis)
- Detecting tags containing a commit uses Gitaly by default.
- Increase cluster applications installer availability using alpine linux mirrors.
- Compute notification recipients in background jobs.
- Use persisted diff data instead fetching Git on discussions.
- Detecting branchnames containing a commit uses Gitaly by default.
- Detect repository license on Gitaly by default.
- Finish NamespaceService migration to Gitaly.
- Check if a ref exists is done by Gitaly by default.
- Compute Gitlab::Git::Repository#checksum on Gitaly by default.
- Repository#exists? is always executed through Gitaly.

### Added (22 changes, 10 of them are from the community)

- Allow group masters to configure runners for groups. !9646 (Alexis Reigel)
- Adds Embedded Snippets Support. !15695 (haseebeqx)
- Add Copy metadata quick action. !16473 (Mateusz Bajorski)
- Show Runner's description on job's page. !17321
- Add deprecation message to dynamic milestone pages. !17505
- Show new branch/mr button even when branch exists. !17712 (Jacopo Beschi @jacopo-beschi)
- API: add languages of project GET /projects/:id/languages. !17770 (Roger Rüttimann)
- Display active sessions and allow the user to revoke any of it. !17867 (Alexis Reigel)
- Add cron job to email users on issue due date. !17985 (Stuart Nelson)
- Rubocop rule to avoid returning from a block. !18000 (Jacopo Beschi @jacopo-beschi)
- Add the signature verification badge to the compare view. !18245 (Marc Shaw)
- Expose Deploy Token data as environment varialbes on CI/CD jobs. !18414
- Show group id in group settings. !18482 (George Tsiolis)
- Allow admins to enforce accepting Terms of Service on an instance. !18570
- Add CI_COMMIT_MESSAGE, CI_COMMIT_TITLE and CI_COMMIT_DESCRIPTION predefined variables. !18672
- Add GCP signup offer to cluster index / create pages. !18684
- Output some useful information when running the rails console. !18697
- Display merge commit SHA in merge widget after merge. !18722
- git SHA is now displayed alongside the GitLab version on the Admin Dashboard.
- Expose the target commit ID through the tag API.
- Added fuzzy file finder to web IDE.
- Add discussion API for merge requests and commits.

### Other (22 changes, 8 of them are from the community)

- Replace the `project/issues/milestones.feature` spinach test with an rspec analog. !18300 (@blackst0ne)
- Replace the `project/commits/branches.feature` spinach test with an rspec analog. !18302 (@blackst0ne)
- Replacing gollum libraries for gitlab custom libs. !18343
- Replace the `project/commits/comments.feature` spinach test with an rspec analog. !18356 (@blackst0ne)
- Replace "Click" with "Select" to be more inclusive of people with accessibility requirements. !18386 (Mark Lapierre)
- Remove ahead/behind graphs on project branches on mobile. !18415 (Takuya Noguchi)
- Replace the `project/source/markdown_render.feature` spinach test with an rspec analog. !18525 (@blackst0ne)
- Add missing changelog type to docs. !18526 (@blackst0ne)
- Added Webhook SSRF prevention to documentation. !18532
- Upgrade underscore.js to 1.9.0. !18578
- Add documentation about how to use variables to define deploy policies for staging/production environments. !18675
- Replace the `project/builds/artifacts.feature` spinach test with an rspec analog. !18729 (@blackst0ne)
- Block access to the API & git for users that did not accept enforced Terms of Service. !18816
- Transition to atomic internal ids for all models. !44259
- Removes modal boards store and mixins from global scope.
- Replace GKE acronym with Google Kubernetes Engine.
- Replace vue resource with axios for pipelines details page.
- Enable prometheus monitoring by default.
- Replace vue resource with axios in pipelines table.
- Bump lograge to 0.10.0 and remove monkey patch.
- Improves wording in new pipeline page.
- Gitaly handles repository forks by default.


## 10.7.7 (2018-07-17)

### Security (1 change)

- Fix symlink vulnerability in project import.


## 10.7.6 (2018-06-21)

### Security (6 changes)

- Fix XSS vulnerability for table of content generation.
- Update sanitize gem to 4.6.5 to fix HTML injection vulnerability.
- HTML escape branch name in project graphs page.
- HTML escape the name of the user in ProjectsHelper#link_to_member.
- Don't show events from internal projects for anonymous users in public feed.
- XSS fix to use safe_params instead of params in url_for helpers.

### Other (1 change)

- Replacing gollum libraries for gitlab custom libs. !18343


## 10.7.5 (2018-05-28)

### Security (3 changes)

- Prevent user passwords from being changed without providing the previous password.
- Fix API to remove deploy key from project instead of deleting it entirely.
- Fixed bug that allowed importing arbitrary project attributes.


## 10.7.4 (2018-05-21)

### Fixed (1 change)

- Fix error when deleting an empty list of refs.


## 10.7.3 (2018-05-02)

### Fixed (8 changes)

- Fixed wrong avatar URL when the avatar is on object storage. !18092
- Fix errors on pushing to an empty repository. !18462
- Update doorkeeper to 4.3.2 to fix GitLab OAuth authentication. !18543
- Ports omniauth-jwt gem onto GitLab OmniAuth Strategies suite. !18580
- Fix redirection error for applications using OpenID. !18599
- Fix commit trailer rendering when Gravatar is disabled.
- Fix file_store for artifacts and lfs when saving.
- Fix users not seeing labels from private groups when being a member of a child project.


## 10.7.2 (2018-04-25)

### Security (2 changes)

- Serve archive requests with the correct file in all cases.
- Sanitizes user name to avoid XSS attacks.


## 10.7.1 (2018-04-23)

### Fixed (11 changes)

- [API] Fix URLs in the `Link` header for `GET /projects/:id/repository/contributors` when no value is passed for `order_by` or `sort`. !18393
- Fix a case with secret variables being empty sometimes. !18400
- Fix `Trace::HttpIO` can not render multi-byte chars. !18417
- Fix specifying a non-default ref when requesting an archive using the legacy URL. !18468
- Respect visibility options and description when importing project from template. !18473
- Removes 'No Job log' message from build trace. !18523
- Align action icons in pipeline graph.
- Fix direct_upload when records with null file_store are used.
- Removed alert box in IDE when redirecting to new merge request.
- Fixed IDE not loading for sub groups.
- Fixed IDE not showing loading state when tree is loading.

### Performance (4 changes)

- Validate project path prior to hitting the database. !18322
- Add index to file_store on ci_job_artifacts. !18444
- Fix N+1 queries when loading participants for a commit note.
- Support Markdown rendering using multiple projects.

### Added (1 change)

- Add an API endpoint to download git repository snapshots. !18173


## 10.7.0 (2018-04-22)

### Security (6 changes, 2 of them are from the community)

- Fixed some SSRF vulnerabilities in services, hooks and integrations. !2337
- Update ruby-saml to 1.7.2 and omniauth-saml to 1.10.0. !17734 (Takuya Noguchi)
- Update rack-protection to 2.0.1. !17835 (Takuya Noguchi)
- Adds confidential notes channel for Slack/Mattermost.
- Fix XSS on diff view stored on filenames.
- Fix GitLab Auth0 integration signing in the wrong user.

### Fixed (65 changes, 20 of them are from the community)

- File uploads in remote storage now support project renaming. !4597
- Fixed bug in dropdown selector when selecting the same selection again. !14631 (bitsapien)
- Fixed group deletion linked to Mattermost. !16209 (Julien Millau)
- Create commit API and Web IDE obey LFS filters. !16718
- Set breadcrumb for admin/runners/show. !17431 (Takuya Noguchi)
- Enable restore rake task to handle nested storage directories. !17516 (Balasankar C)
- Fix hover style of dropdown items in the right sidebar. !17519
- Improve empty state for canceled job. !17646
- Fix generated URL when listing repoitories for import. !17692
- Use singular in the diff stats if only one line has been changed. !17697 (Jan Beckmann)
- Long instance urls do not overflow anymore during project creation. !17717
- Fix importing multiple assignees from GitLab export. !17718
- Correct copy text for the promote milestone and label modals. !17726
- Fix search results stripping last endline when parsing the results. !17777 (Jasper Maes)
- Add read-only banner to all pages. !17798
- Fix viewing diffs on old merge requests. !17805
- Fix forking to subgroup via API when namespace is given by name. !17815 (Jan Beckmann)
- Fix UI breakdown for Create merge request button. !17821 (Takuya Noguchi)
- Unify format for nested non-task lists. !17823 (Takuya Noguchi)
- UX re-design branch items with flexbox. !17832 (Takuya Noguchi)
- Use porcelain commit lookup method on CI::CreatePipelineService. !17911
- Update dashboard milestones breadcrumb link. !17933 (George Tsiolis)
- Deleting a MR you are assigned to should decrements counter. !17951 (m b)
- Update no repository placeholder. !17964 (George Tsiolis)
- Drop JSON response in Project Milestone along with avoiding error. !17977 (Takuya Noguchi)
- Fix personal access token clipboard button style. !17978 (Fabian Schneider)
- Avoid validation errors when running the Pages domain verification service. !17992
- Project creation will now raise an error if a service template is invalid. !18013
- Add better LDAP connection handling. !18039
- Fix autolinking URLs containing ampersands. !18045
- Fix exceptions raised when migrating pipeline stages in the background. !18076
- Always display Labels section in issuable sidebar, even when the project has no labels. !18081 (Branka Martinovic)
- Fixed gitlab:uploads:migrate task ignoring some uploads. !18082
- Fixed gitlab:uploads:migrate task failing for Groups' avatar. !18088
- Increase dropdown width in pipeline graph & center action icon. !18089
- Fix `JobsController#raw` endpoint can not read traces in database. !18101
- Fix `gitlab-rake gitlab:two_factor:disable_for_all_users`. !18154
- Adjust 404's for LegacyDiffNote discussion rendering. !18201
- Work around Prometheus Helm chart name changes to fix integration. !18206 (joshlambert)
- Prioritize weight over title when sorting charts. !18233
- Verify that deploy token has valid access when pulling container registry image. !18260
- Stop redirecting the page in pipeline main actions.
- Fixed IDE button opening the wrong URL in tree list.
- Ensure hooks run when a deploy key without a user pushes.
- Fix 404 in group boards when moving issue between lists.
- Display state indicator for issuable references in non-project scope (e.g. when referencing issuables from group scope).
- Add missing port to artifact links.
- Fix data race between ObjectStorage background_upload and Pages publishing.
- Fixes unresolved discussions rendering the error state instead of the diff.
- Don't show Jump to Discussion button on Issues.
- Fix bug rendering group icons when forking.
- Automatically cleanup stale worktrees and lock files upon a push.
- Use the GitLab version as part of the appearances cache key.
- Fix Firefox stealing formatting characters on issue notes.
- Include matching branches and tags in protected branches / tags count. (Jan Beckmann)
- Fix 500 error when a merge request from a fork has conflicts and has not yet been updated.
- Test if remote repository exists when importing wikis.
- Hide emoji popup after multiple spaces. (Jan Beckmann)
- Fix relative uri when "#" is in branch name. (Jan)
- Escape Markdown characters properly when using autocomplete.
- Ignore project internal references in group context.
- Fix finding wiki file when Gitaly is enabled.
- Fix listing commit branch/tags that contain special characters.
- Ensure internal users (ghost, support bot) get assigned a namespace.
- Fix links to subdirectories of a directory with a plus character in its path.

### Deprecated (1 change)

- Remove support for legacy tar.gz pages artifacts. !18090

### Changed (22 changes, 2 of them are from the community)

- Add yellow favicon when `CANARY=true` to differientate canary environment. !12477
- Use human readable value build_timeout in Project. !17386
- Improved visual styles and consistency for commit hash and possible actions across commit lists. !17406
- Don't create permanent redirect routes. !17521
- Add empty repo check before running AutoDevOps pipeline. !17605
- Update wording to specify create/manage project vs group labels in labels dropdown. !17640
- Add tooltips to icons in lists of issues and merge requests. !17700
- Change avatar error message to include allowed file formats. !17747 (Fabian Schneider)
- Polish design for verifying domains. !17767
- Move email footer info to a single line. !17916
- Add average and maximum summary statistics to the prometheus dashboard. !17921
- Add additional cluster usage metrics to usage ping. !17922
- Move 'Registry' after 'CI/CD' in project navigation sidebar. !18018 (Elias Werberich)
- Redesign application settings to match project settings. !18019
- Allow HTTP(s) when git request is made by GitLab CI. !18021
- Added hover background color to IDE file list rows.
- Make project avatar in IDE consistent with the rest of GitLab.
- Show issues of subgroups in group-level issue board.
- Repository checksum calculation is handled by Gitaly when feature is enabled.
- Allow viewing timings for AJAX requests in the performance bar.
- Fixes remove source branch checkbox being visible when user cannot remove the branch.
- Make /-/ delimiter optional for search endpoints.

### Performance (24 changes, 11 of them are from the community)

- Move AssigneeTitle vue component. !17397 (George Tsiolis)
- Move TimeTrackingCollapsedState vue component. !17399 (George Tsiolis)
- Move MemoryGraph and MemoryUsage vue components. !17533 (George Tsiolis)
- Move UnresolvedDiscussions vue component. !17538 (George Tsiolis)
- Move NothingToMerge vue component. !17544 (George Tsiolis)
- Move ShaMismatch vue component. !17546 (George Tsiolis)
- Stop caching highlighted diffs in Redis unnecessarily. !17746
- Add i18n and update specs for ShaMismatch vue component. !17870 (George Tsiolis)
- Update spec import path for vue mount component helper. !17880 (George Tsiolis)
- Move TimeTrackingComparisonPane vue component. !17931 (George Tsiolis)
- Improves the performance of projects list page. !17934
- Remove N+1 query for Noteable association. !17956
- Improve performance of loading issues with lots of references to merge requests. !17986
- Reuse root_ref_hash for performance on Branches. !17998 (Takuya Noguchi)
- Update asciidoctor-plantuml to 0.0.8. !18022 (Takuya Noguchi)
- Cache personal projects count. !18197
- Reduce complexity of issuable finder query. !18219
- Reduce number of queries when viewing a merge request.
- Free open file descriptors and libgit2 buffers in UpdatePagesService.
- Memoize Git::Repository#has_visible_content?.
- Require at least one filter when listing issues or merge requests on dashboard page.
- lazy load diffs on merge request discussions.
- Bulk deleting refs is handled by Gitaly by default.
- ListCommitsByOid is executed by Gitaly by default.

### Added (38 changes, 7 of them are from the community)

- Add HTTPS-only pages. !16273 (rfwatson)
- adds closed by informations in issue api. !17042 (haseebeqx)
- Projects and groups badges settings UI. !17114
- Add per-runner configured job timeout. !17221
- Add alternate archive route for simplified packaging. !17225
- Add support for pipeline variables expressions in only/except. !17316
- Add object storage support for LFS objects, CI artifacts, and uploads. !17358
- Added confirmation modal for changing username. !17405
- Implement foreground verification of CI artifacts. !17578
- Extend API for exporting a project with direct upload URL. !17686
- Move ci/lint under project's namespace. !17729
- Add Total CPU/Memory consumption metrics for Kubernetes. !17731
- Adds the option to the project export API to override the project description and display GitLab export description once imported. !17744
- Port direct upload of LFS artifacts from EE. !17752
- Adds support for OmniAuth JWT provider. !17774
- Display error message on job's tooltip if this one fails. !17782
- Add 'Assigned Issues' and 'Assigned Merge Requests' as dashboard view choices for users. !17860 (Elias Werberich)
- Extend API for importing a project export with overwrite support. !17883
- Create Deploy Tokens to allow permanent access to repository and registry. !17894
- Detect commit message trailers and link users properly to their accounts on GitLab. !17919 (cousine)
- Adds cancel btn to new pages domain page. !18026 (Jacopo Beschi @jacopo-beschi)
- API: Add parameter merge_method to projects. !18031 (Jan Beckmann)
- Introduce simpler env vars for auto devops REPLICAS and CANARY_REPLICAS #41436. !18036
- Allow overriding params on project import through API. !18086
- Support LFS objects when importing/exporting GitLab project archives. !18115
- Store sha256 checksum of artifact metadata. !18149
- Limit the number of failed logins when using LDAP for authentication. !43525
- Allow assigning and filtering issuables by ancestor group labels.
- Include subgroup issues when searching for group issues using the API.
- Allow to store uploads by default on Object Storage.
- Add slash command for moving issues. (Adam Pahlevi)
- Render MR commit SHA instead "diffs" when viable.
- Send @mention notifications even if a user has explicitly unsubscribed from item.
- Add support for Sidekiq JSON logging.
- Add Gitaly call details to performance bar.
- Add support for patch link extension for commit links on GitLab Flavored Markdown.
- Allow feature gates to be removed through the API.
- Allow merge requests related to a commit to be found via API.

### Other (27 changes, 11 of them are from the community)

- Send notification emails when push to a merge request. !7610 (YarNayar)
- Rename modal.vue to deprecated_modal.vue. !17438
- Atomic generation of internal ids for issues. !17580
- Use object ID to prevent duplicate keys Vue warning on Issue Boards page during development. !17682
- Update foreman from 0.78.0 to 0.84.0. !17690 (Takuya Noguchi)
- Add realtime pipeline status for adding/viewing files. !17705
- Update documentation to reflect current minimum required versions of node and yarn. !17706
- Update knapsack to 1.16.0. !17735 (Takuya Noguchi)
- Update CI services documnetation. !17749
- Added i18n support for the prometheus memory widget. !17753
- Use specific names for filtered CI variable controller parameters. !17796
- Apply NestingDepth (level 5) (framework/dropdowns.scss). !17820 (Takuya Noguchi)
- Clean up selectors in framework/header.scss. !17822 (Takuya Noguchi)
- Bump `state_machines-activerecord` to 0.5.1. !17924 (blackst0ne)
- Increase the memory limits used in the unicorn killer. !17948
- Replace the spinach test with an rspec analog. !17950 (blackst0ne)
- Remove unused index from events table. !18014
- Make all workhorse gitaly calls opt-out, take 2. !18043
- Update brakeman 3.6.1 to 4.2.1. !18122 (Takuya Noguchi)
- Replace the `project/issues/labels.feature` spinach test with an rspec analog. !18126 (blackst0ne)
- Bump html-pipeline to 2.7.1. !18132 (@blackst0ne)
- Remove test_ci rake task. !18139 (Takuya Noguchi)
- Add documentation for Pipelines failure reasons. !18352
- Improve JIRA event descriptions.
- Add query counts to profiler output.
- Move Sidekiq exporter logs to log/sidekiq_exporter.log.
- Upgrade Gitaly to upgrade its charlock_holmes.


## 10.6.6 (2018-05-28)

### Security (4 changes)

- Do not allow non-members to create MRs via forked projects when MRs are private.
- Prevent user passwords from being changed without providing the previous password.
- Fix API to remove deploy key from project instead of deleting it entirely.
- Fixed bug that allowed importing arbitrary project attributes.


## 10.6.5 (2018-04-24)

### Security (1 change)

- Sanitizes user name to avoid XSS attacks.


## 10.6.4 (2018-04-09)

### Fixed (8 changes, 1 of them is from the community)

- Correct copy text for the promote milestone and label modals. !17726
- Avoid validation errors when running the Pages domain verification service. !17992
- Fix autolinking URLs containing ampersands. !18045
- Fix exceptions raised when migrating pipeline stages in the background. !18076
- Work around Prometheus Helm chart name changes to fix integration. !18206 (joshlambert)
- Don't show Jump to Discussion button on Issues.
- Fix listing commit branch/tags that contain special characters.
- Fix 404 in group boards when moving issue between lists.

### Performance (1 change)

- Free open file descriptors and libgit2 buffers in UpdatePagesService.


## 10.6.3 (2018-04-03)

### Security (2 changes)

- Fix XSS on diff view stored on filenames.
- Adds confidential notes channel for Slack/Mattermost.


## 10.6.2 (2018-03-29)

### Fixed (2 changes, 1 of them is from the community)

- Don't capture trailing punctuation when autolinking. !17965
- Cloning a repository over HTTPS with LDAP credentials causes a HTTP 401 Access denied. (Horatiu Eugen Vlad)


## 10.6.1 (2018-03-27)

### Security (1 change)

- Bump rails-html-sanitizer to 1.0.4.

### Fixed (2 changes)

- Prevent auto-retry AccessDenied error from stopping transition to failed. !17862
- Fix 500 error when trying to resolve non-ASCII conflicts in the editor. !17962

### Performance (1 change)

- Add indexes for user activity queries. !17890

### Other (1 change)

- Add documentation for runner IP address (#44232). !17837


## 10.6.0 (2018-03-22)

### Security (4 changes)

- Fixed some SSRF vulnerabilities in services, hooks and integrations. !2337
- Ensure that OTP backup codes are always invalidated.
- Add verification for GitLab Pages custom domains.
- Fix GitLab Auth0 integration signing in the wrong user.

### Fixed (75 changes, 17 of them are from the community)

- Ensure users cannot create environments with leading or trailing slashes (Fixes #39885). !15273
- Fix new project path input overlapping. !16755 (George Tsiolis)
- Respect description and visibility when creating project from template. !16820 (George Tsiolis)
- Remove user notification settings for groups and projects when user leaves. !16906 (Jacopo Beschi @jacopo-beschi)
- Fix Teleporting Emoji. !16963 (Jared Deckard <jared.deckard@gmail.com>)
- Fix duplicate system notes when merging a merge request. !17035
- Fix breadcrumb on labels page for groups. !17045 (Onuwa Nnachi Isaac)
- Fix user avatar's vertical align on the issues and merge requests pages. !17072 (Laszlo Karpati)
- Fix settings panels not expanding when fragment hash linked. !17074
- Fix 404 when listing archived projects in a group where all projects have been archived. !17077 (Ashley Dumaine)
- Allow to call PUT /projects/:id API with only ci_config_path specified. !17105 (Laszlo Karpati)
- Fix long list of recipients on group request membership email. !17121 (Jacopo Beschi @jacopo-beschi)
- Remove duplicated error message on duplicate variable validation. !17135
- Keep "Import project" tab/form active when validation fails trying to import "Repo by URL". !17136
- Fixed bug with unauthenticated requests through git ssh. !17149
- Allows project rename after validation error. !17150
- Fix "Remove source branch" button in Merge request widget during merge when pipeline succeeds state. !17192
- Add missing pagination on the commit diff endpoint. !17203 (Maxime Roussin-Bélanger)
- Fix get a single pages domain when project path contains a period. !17206 (Travis Miller)
- remove avater underline. !17219 (Ken Ding)
- Allows the usage of /milestone quick action for group milestones. !17239 (Jacopo Beschi @jacopo-beschi)
- Encode branch name as binary before creating a RPC request to copy attributes. !17291
- Restart Unicorn and Sidekiq when GRPC throws 14:Endpoint read failed. !17293
- Do not persist Google Project verification flash errors after a page reload. !17299
- Ensure group issues and merge requests pages show results from subgroups when there are no results from the current group. !17312
- Prevent trace artifact migration to incur data loss. !17313
- Fixes gpg popover layout. !17323
- Return a 404 instead of 403 if the repository does not exist on disk. !17341
- Fix Slack/Mattermost notifications not respecting `notify_only_default_branch` setting for pushes. !17345
- Fix Group labels load failure when there are duplicate labels present. !17353
- Allow Prometheus application to be installed from Cluster applications. !17372
- Fixes Prometheus admin configuration page. !17377
- Enable filtering MR list based on clicked label in MR sidebar. !17390
- Fix code and wiki search results pages when non-ASCII text is displayed. !17413
- Count comments on diffs and discussions as contributions for the contributions calendar. !17418 (Riccardo Padovani)
- Add Assignees vue component missing data container. !17426 (George Tsiolis)
- Update tooltip on pipeline cancel to Stop (#42946). !17444
- Removing the two factor check when the user sets a new password. !17457
- Fix quick actions for users who cannot update issues and merge requests. !17482
- Stop loading spinner on error of milestone update on issue. !17507 (Takuya Noguchi)
- Set margins around dropdown dividers to 4px. !17517
- Fix pages flaky failure by reloading stale object. !17522
- Remove extra breadcrumb on tags. !17562 (Takuya Noguchi)
- Fix missing uploads after group transfer. !17658
- Fix markdown table showing extra column. !17669
- Ensure the API returns https links when https is configured. !17681
- Sanitize extra blank spaces used when uploading a SSH key. !40552
- Render htmlentities correctly for links not supported by Rinku.
- Keep link when redacting unauthorized object links.
- Handle empty state in Pipelines page.
- Revert Project.public_or_visible_to_user changes and only apply to snippets.
- Release libgit2 cache and open file descriptors after `git gc` run.
- Fix project dashboard showing the wrong timestamps.
- Fix "Can't modify frozen hash" error when project is destroyed.
- Fix Error 500 when viewing a commit with a GPG signature in Geo.
- Don't error out in system hook if user has `nil` datetime columns.
- Remove double caching of Repository#empty?.
- Don't delete todos or unassign issues and MRs when a user leaves a project.
- Don't cache a nil repository root ref to prevent caching issues.
- Escape HTML entities in commit messages.
- Verify project import status again before marking as failed.
- [GitHub Import] Create an empty wiki if wiki import failed.
- Create empty wiki when import from GitLab and wiki is not there.
- Make sure wiki exists when it's enabled.
- Fix broken loading state for close issue button.
- Fix code and wiki search results when filename is non-ASCII.
- Fix file upload on project show page.
- Fix squashing when a file is renamed.
- Show loading button inline in refresh button in MR widget.
- Fix close button on issues not working on mobile.
- Adds tooltip in environment names to increase readability.
- Fixed issue edit shortcut not opening edit form.
- Fix 500 error being shown when diff has context marker with invalid encoding.
- Render modified icon for moved file in changes dropdown.
- Remember assignee when moving an issue.

### Changed (16 changes, 9 of them are from the community)

- Allow including custom attributes in API responses. !16526 (Markus Koller)
- Apply new default and inline label design. !16956 (George Tsiolis)
- Remove whitespace from the username/email sign in form field. !17020 (Peter lauck)
- CI charts now include the current day. !17032 (Dakkaron)
- Hide CI secret variable values after saving. !17044
- Add new modal Vue component. !17108
- Asciidoc now support inter-document cross references between files in repository. !17125 (Turo Soisenniemi)
- Update issue closing pattern to allow variations in punctuation. !17198 (Vicky Chijwani)
- Add a button to deploy a runner to a Kubernetes cluster in the settings page. !17278
- Pages custom domain: allow update of key/certificate. !17376 (rfwatson)
- Clear the Labels dropdown search filter after a selection is made. !17393 (Andrew Torres)
- Hook data for pipelines includes detailed_status. !17607
- Avoid showing unnecessary Trigger checkboxes for project Integrations with only one event. !17607
- Display a link to external issue tracker when enabled.
- Allow token authentication on go-get request.
- Update SSH key link to include existing keys. (Brendan O'Leary)

### Performance (24 changes, 5 of them are from the community)

- Add catch-up background migration to migrate pipeline stages. !15741
- Move BoardNewIssue vue component. !16947 (George Tsiolis)
- Move IssuableTimeTracker vue component. !16948 (George Tsiolis)
- Move RecentSearchesDropdownContent vue component. !16951 (George Tsiolis)
- Move Assignees vue component. !16952 (George Tsiolis)
- Improve performance of pipeline page by reducing DB queries. !17168
- Store sha256 checksum to job artifacts. !17354
- Move SidebarAssignees vue component. !17398 (George Tsiolis)
- Improve database response time for user activity listing. !17454
- Use persisted/memoized value for MRs shas instead of doing git lookups. !17555
- Cache MergeRequests can_be_resolved_in_ui? git operations. !17589
- Prevent the graphs page from generating unnecessary Gitaly requests. !37602
- Use a user object in ApplicationHelper#avatar_icon where possible to avoid N+1 queries. !42800
- Submit a single batch blob RPC to Gitaly per HTTP request when viewing diffs.
- Avoid re-fetching merge-base SHA from Gitaly unnecessarily.
- Don't use ProjectsFinder in TodosFinder.
- Adding missing indexes on taggings table.
- Add index on section_name_id on ci_build_trace_sections table.
- Cache column_exists? for application settings.
- Cache table_exists?('application_settings') to reduce repeated schema reloads.
- Make --prune a configurable parameter in fetching a git remote.
- Fix timeouts loading /admin/projects page.
- Add partial indexes on todos to handle users with many todos.
- Optimize search queries on the search page by setting a limit for matching records in project scope.

### Added (30 changes, 9 of them are from the community)

- Add CommonMark markdown engine (experimental). !14835 (blackst0ne)
- API: Get references a commit is pushed to. !15026 (Robert Schilling)
- Add overview of branches and a filter for active/stale branches. !15402 (Takuya Noguchi)
- Add project export API. !15860 (Travis Miller)
- expose more metrics in merge requests api. !16589 (haseebeqx)
- #28481: Display time tracking totals on milestone page. !16753 (Riccardo Padovani)
- Add a button on the project page to set up a Kubernetes cluster and enable Auto DevOps. !16900
- Include cycle time in usage ping data. !16973
- Add ability to use external plugins as an alternative to system hooks. !17003
- Add search param to Branches API. !17005 (bunufi)
- API endpoint for importing a project export. !17025
- Display ingress IP address in the Kubernetes page. !17052
- Implemented badge API endpoints. !17082
- Allow installation of GitLab Runner with a single click. !17134
- Allow commits endpoint to work over all commits of a repository. !17182
- Display Runner IP Address. !17286
- Add archive feature to trace. !17314
- Allow maintainers to push to forks of their projects when a merge request is open. !17395
- Foreground verification of uploads and LFS objects. !17402
- Adds updated_at filter to issues and merge_requests API. !17417 (Jacopo Beschi @jacopo-beschi)
- Port /wip quick action command to Merge Request creation (on description). !17463 (Adam Pahlevi)
- Add a paragraph about security implications on Cluster's page. !17486
- Add plugins list to the system hooks page. !17518
- Enable privileged mode for GitLab Runner. !17528
- Expose GITLAB_FEATURES as CI/CD variable (fixes #40994).
- Upgrade GitLab Workhorse to 4.0.0.
- Add discussions API for Issues and Snippets.
- Add one group board to Libre.
- Add support for filtering by source and target branch to merge requests API.

### Other (18 changes, 7 of them are from the community)

- Group MRs on issue page by project and namespace. !8494 (Jeff Stubler)
- Make oauth provider login generic. !8809 (Horatiu Eugen Vlad)
- Add email button to new issue by email. !10942 (Islam Wazery)
- Update vue component naming guidelines. !17018 (George Tsiolis)
- Added new design for promotion modals. !17197
- Update to github-linguist 5.3.x. !17241 (Ken Ding)
- update toml-rb to 1.0.0. !17259 (Ken Ding)
- Keep track of projects a user interacted with. !17327
- Moved o_auth/saml/ldap modules under gitlab/auth. !17359 (Horatiu Eugen Vlad)
- Enables eslint in codeclimate job. !17392
- Port Labels Select dropdown to Vue. !17411
- Add NOT NULL constraint to projects.namespace_id. !17448
- Ensure foreign keys on clusters applications. !17488
- Started translation into Turkish, Indonesian and Filipino. !17526
- Add documentation for displayed K8s Ingress IP address (#44330). !17836
- Move Ruby endpoints to OPT_OUT.
- Upgrade Workhorse to version 3.8.0 to support structured logging.
- Use host URL to build JIRA remote link icon.


## 10.5.8 (2018-04-24)

### Security (1 change)

- Sanitizes user name to avoid XSS attacks.


## 10.5.7 (2018-04-03)

### Security (2 changes)

- Fix XSS on diff view stored on filenames.
- Adds confidential notes channel for Slack/Mattermost.


## 10.5.6 (2018-03-16)

### Security (2 changes)

- Fixed some SSRF vulnerabilities in services, hooks and integrations. !2337
- Fix GitLab Auth0 integration signing in the wrong user.


## 10.5.5 (2018-03-15)

### Fixed (3 changes)

- Fix missing uploads after group transfer. !17658
- Fix code and wiki search results when filename is non-ASCII.
- Remove double caching of Repository#empty?.

### Performance (2 changes)

- Adding missing indexes on taggings table.
- Add index on section_name_id on ci_build_trace_sections table.


## 10.5.4 (2018-03-08)

### Fixed (11 changes)

- Encode branch name as binary before creating a RPC request to copy attributes. !17291
- Restart Unicorn and Sidekiq when GRPC throws 14:Endpoint read failed. !17293
- Ensure group issues and merge requests pages show results from subgroups when there are no results from the current group. !17312
- Prevent trace artifact migration to incur data loss. !17313
- Return a 404 instead of 403 if the repository does not exist on disk. !17341
- Allow Prometheus application to be installed from Cluster applications. !17372
- Fixes Prometheus admin configuration page. !17377
- Fix code and wiki search results pages when non-ASCII text is displayed. !17413
- Fix pages flaky failure by reloading stale object. !17522
- Fixed issue edit shortcut not opening edit form.
- Revert Project.public_or_visible_to_user changes and only apply to snippets.

### Performance (1 change)

- Don't use ProjectsFinder in TodosFinder.


## 10.5.3 (2018-03-01)

### Security (1 change)

- Ensure that OTP backup codes are always invalidated.


## 10.5.2 (2018-02-25)

### Fixed (7 changes)

- Fix single digit value clipping for stacked progress bar. !17217
- Fix issue with cache key being empty when variable used as the key. !17260
- Enable Legacy Authorization by default on Cluster creations. !17302
- Allow branch names to be named the same as the sha it points to.
- Fix 500 error when loading an invalid upload URL.
- Don't attempt to update user tracked fields if database is in read-only.
- Prevent MR Widget error when no CI configured.

### Performance (5 changes)

- Improve query performance for snippets dashboard. !17088
- Only check LFS integrity for first ref in a push to avoid timeout. !17098
- Improve query performance of MembersFinder. !17190
- Increase feature flag cache TTL to one hour.
- Improve performance of searching for and autocompleting of users.


## 10.5.1 (2018-02-22)

- No changes.

## 10.5.0 (2018-02-22)

### Security (3 changes, 1 of them is from the community)

- Update marked from 0.3.6 to 0.3.12. !16480 (Takuya Noguchi)
- Update nokogiri to 1.8.2. !16807
- Add verification for GitLab Pages custom domains.

### Fixed (77 changes, 25 of them are from the community)

- Fix the Projects API with_issues_enabled filter behaving incorrectly any user. !12724 (Jan Christophersen)
- Hide pipeline schedule take ownership for current owner. !12986
- Handle special characters on API request of issuable templates. !15323 (Takuya Noguchi)
- Shows signin tab after new user email confirmation. !16174 (Jacopo Beschi @jacopo-beschi)
- Make project README containers wider on fixed layout. !16181 (Takuya Noguchi)
- Fix dashboard projects nav links height. !16204 (George Tsiolis)
- Fix error on empty query for Members API. !16235
- Issue board: fix for dragging an issue to the very bottom in long lists. !16250 (David Kuri)
- Make rich blob viewer wider for PC. !16262 (Takuya Noguchi)
- Substitute deprecated ui_charcoal with new default ui_indigo. !16271 (Takuya Noguchi)
- Generate HTTP URLs for custom Pages domains when appropriate. !16279
- Make modal dialog common for Groups tree app. !16311
- Allow moving wiki pages from the UI. !16313
- Filter groups and projects dropdowns of search page on backend. !16336
- Adjust layout width for fixed layout. !16337 (George Tsiolis)
- Fix custom header logo design nitpick: Remove unneeded margin on empty logo text. !16383 (Markus Doits)
- File Upload UI can create LFS pointers based on .gitattributes. !16412
- Fix Ctrl+Enter keyboard shortcut saving comment/note edit. !16415
- Fix file search results when they match file contents with a number between two colons. !16462
- Fix tooltip displayed for running manual actions. !16489
- Allow trailing + on labels in board filters. !16490
- Prevent JIRA issue identifier from being humanized. !16491 (Andrew McCallum)
- Add horizontal scroll to wiki tables. !16527 (George Tsiolis)
- Fix a bug calculating artifact size for project statistics. !16539
- Stop loading spinner on error of issuable templates. !16600 (Takuya Noguchi)
- Allows html text in commits atom feed. !16603 (Jacopo Beschi @jacopo-beschi)
- Disable MR check out button when source branch is deleted. !16631 (Jacopo Beschi @jacopo-beschi)
- Fix export removal for hashed-storage projects within a renamed or deleted namespace. !16658
- Default to HTTPS for all Gravatar URLs. !16666
- Login via OAuth now only marks new users as external. !16672
- Fix default avatar icon missing when Gravatar is disabled. !16681 (Felix Geyer)
- Change button group width on mobile. !16726 (George Tsiolis)
- Fix version information not showing on help page if commercial content display was disabled. !16743
- Adds spacing between edit and delete tag btn in tag list. !16757 (Jacopo Beschi @jacopo-beschi)
- Fix 500 error when loading a merge request with an invalid comment. !16795
- Deleting an upload will correctly clean up the filesystem. !16799
- Cleanup new branch/merge request form in issues. !16854
- Fix GitLab import leaving group_id on ProjectLabel. !16877
- Fix forking projects when no restricted visibility levels are defined applicationwide. !16881
- Trigger change event on filename input when file template is applied. !16911 (Sebastian Klingler)
- Fixes different margins between buttons in tag list. !16927 (Jacopo Beschi @jacopo-beschi)
- Close low level rugged repository in project cache worker. !16930 (Bastian Blank)
- Override group sidebar links. !16942 (George Tsiolis)
- Avoid running `PopulateForkNetworksRange`-migration multiple times. !16988
- Resolve PrepareUntrackedUploads PostgreSQL syntax error. !17019
- Fix monaco editor features which were incompatible with GitLab CDN settings. !17021
- Fixed error 500 when removing an identity with synced attributes and visiting the profile page. !17054
- Fix cnacel edit note button reverting changes. !42462
- For issues display time of last edit of title or description instead of time of any attribute change.
- Handle all Psych YAML parser exceptions (fixes #41209).
- Fix validation of environment scope of variables.
- Display user friendly error message if rebase fails.
- Hide new branch and tag links for projects with an empty repo.
- Fix protected branches API to accept name parameter with dot.
- Closes #38540 - Remove .ssh/environment file that now breaks the gitlab:check rake task.
- Keep subscribers when promoting labels to group labels.
- Replace verified badge icons and uniform colors.
- Fix error on changes tab when merge request cannot be created.
- Ignore leading slashes when searching for files within context of repository. (Andrew McCallum)
- Close and do not reload MR diffs when source branch is deleted.
- Bypass commits title markdown on notes.
- Reload MRs memoization after diffs creation.
- Return more consistent values for merge_status on MR APIs.
- Contribution calendar label was cut off. (Branka Martinovic)
- LDAP Person no longer throws exception on invalid entry.
- Fix bug where award emojis would be lost when moving issues between projects.
- Fix not all events being shown in group dashboard.
- Fix JIRA not working when a trailing slash is included.
- Fix squash not working when diff contained non-ASCII data.
- Remove erroneous text in shared runners page that suggested more runners available.
- Execute system hooks after-commit when executing project hooks.
- Makes forking protect default branch on completion.
- Validate user, group and project paths consistently, and only once.
- Validate user namespace before saving so that errors persist on model.
- Permits 'password_authentication_enabled_for_git' parameter for ApplicationSettingsController.
- Fix duplicate item in protected branch/tag dropdown.
- Open visibility level help in a new tab. (Jussi Räsänen)

### Deprecated (1 change)

- Add note within ux documentation that further changes should be made within the design.gitlab project.

### Changed (20 changes, 7 of them are from the community)

- Show coverage to two decimal points in coverage badge. !10083 (Jeff Stubler)
- Update 'removed assignee' note to include old assignee reference. !16301 (Maurizio De Santis)
- Move row containing Projects, Users and Groups count to the top in admin dashboard. !16421
- Add Auto DevOps Domain application setting. !16604
- Changes Revert this merge request text. !16611 (Jacopo Beschi @jacopo-beschi)
- Link Auto DevOps settings to Clusters page. !16641
- Internationalize charts page. !16687 (selrahman)
- Internationalize graph page selrahman. !16688 (Shah El-Rahman)
- Save traces as artifacts. !16702
- Hide variable values on pipeline schedule edit page. !16729
- Update runner info on all authenticated requests. !16756
- Improve issue note dropdown and mr button. !16758 (George Tsiolis)
- Replace "cluster" with "Kubernetes cluster". !16778
- Enable Prometheus metrics for deployed Ingresses. !16866 (joshlambert)
- Rename button to enable CI/CD configuration to "Set up CI/CD". !16870
- Double padding for file-content wiki class on larger screens.
- Improve wording about additional costs for Ingress on custom clusters.
- Last push widget will show banner for new pushes to previously merged branch.
- Save user ID and username in Grape API log (api_json.log).
- Include subgroup issues and merge requests on the group page.

### Performance (14 changes, 1 of them is from the community)

- Fix double query execution on groups page. !16314
- Speed up loading merged merge requests when they contained a lot of commits before merging. !16320
- Properly memoize some predicate methods. !16329
- Reduce the number of Prometheus metrics. !16443
- Only highlight search results under the highlighting size limit. !16462
- Add fast-blank. !16468
- Move BoardList vue component to vue file. !16888 (George Tsiolis)
- Fix N+1 query problem for snippets dashboard. !16944
- Optimize search queries on the search page by setting a limit for matching records.
- Store number of commits in merge_request_diffs table.
- Improve performance of target branch dropdown.
- Remove duplicate calls of MergeRequest#can_be_reverted?.
- Stop checking if discussions are in a mergeable state if the MR isn't.
- Remove N+1 queries with /projects/:project_id/{access_requests,members} API endpoints.

### Added (28 changes, 10 of them are from the community)

- Add link on commit page to merge request that introduced that commit. !13713 (Hiroyuki Sato)
- System hooks for Merge Requests. !14387 (Alexis Reigel)
- Add `pipelines` endpoint to merge requests API. !15454 (Tony Rom <thetonyrom@gmail.com>)
- Adds Rubocop rule for line break around conditionals. !15739 (Jacopo Beschi @jacopo-beschi)
- Add Colors to GitLab Flavored Markdown. !16095 (Tony Rom <thetonyrom@gmail.com>)
- Initial work to add notification reason to emails. !16160 (Mario de la Ossa)
- Implement multi server support and use kube proxy to connect to Prometheus servers inside K8S cluster. !16182
- Add ability to transfer a group into another group. !16302
- Add blue dot feature highlight to make GKE Clusters more visible to users. !16379
- Add section headers to plus button dropdown. !16394 (George Tsiolis)
- Support PostgreSQL 10. !16471
- Enables Project Milestone Deletion via the API. !16478 (Jacopo Beschi @jacopo-beschi)
- Add realtime ci status for the repository -> files view. !16523
- User can now git push to create a new project. !16547
- Improve empty project overview. !16617 (George Tsiolis)
- Added uploader metadata to the uploads. !16779
- Added ldap config setting to lower case the username. !16791
- Add search support into the API. !16878
- Backport of LFS File Locking API. !16935
- Add a link to documentation on how to get external ip in the Kubernetes cluster details page. !16937
- Add sorting options for /users API (admin only). !16945
- Adds sorting to deployments API. (Jacopo Beschi @jacopo-beschi)
- Add rake task to check integrity of uploaded files.
- Add backend for persistently dismissably callouts.
- Track and act upon the number of executed queries.
- Add a gRPC health check to ensure Gitaly is up.
- Log and send a system hook if a blocked user attempts to login.
- Add Gitaly Servers admin dashboard.

### Other (25 changes, 7 of them are from the community)

- Updated the katex library. !15864
- Add modal for deleting a milestone. !16229
- Remove unused CSS selectors for Cycle Analytics. !16270 (Takuya Noguchi)
- Add reason to keep postgresql 9.2 for CI. !16277 (Takuya Noguchi)
- Adjust modal style to new design. !16310
- Default to Gitaly for 'git push' HTTP/SSH, and make Gitaly mandatory for SSH pull. !16586
- Set timezone for karma to UTC. !16602 (Takuya Noguchi)
- Make Gitaly RepositoryExists opt-out. !16680
- Update minimum git version to 2.9.5. !16683
- Disable throwOnError in KaTeX to reveal user where is the problem. !16684 (Jakub Jirutka)
- fix documentation about node version. !16720 (Tobias Gurtzick)
- Enable RuboCop Style/RegexpLiteral. !16752 (Takuya Noguchi)
- Add confirmation-input component. !16816
- Add unique constraint to trending_projects#project_id. !16846
- Add foreign key and NOT NULL constraints to todos table. !16849
- Include branch in mobile view for pipelines. !16910 (George Tsiolis)
- Downgrade google-protobuf gem. !16941
- Refactors mr widget components into vue files and adds i18n.
- increase-readability-of-colored-text-in-job-output-log.
- Finish any remaining jobs for issues.closed_at.
- Translate issuable sidebar.
- Set standard disabled state for all buttons.
- Upgrade GitLab Workhorse to v3.6.0.
- Improve readability of underlined links for dyslexic users.
- Adds empty state illustration for pending job.


## 10.4.7 (2018-04-03)

### Security (2 changes)

- Fix XSS on diff view stored on filenames.
- Adds confidential notes channel for Slack/Mattermost.


## 10.4.6 (2018-03-16)

### Security (2 changes)

- Fixed some SSRF vulnerabilities in services, hooks and integrations. !2337
- Fix GitLab Auth0 integration signing in the wrong user.


## 10.4.5 (2018-03-01)

### Security (1 change)

- Ensure that OTP backup codes are always invalidated.


## 10.4.4 (2018-02-16)

### Security (1 change)

- Update nokogiri to 1.8.2. !16807

### Fixed (9 changes)

- Fix 500 error when loading a merge request with an invalid comment. !16795
- Cleanup new branch/merge request form in issues. !16854
- Fix GitLab import leaving group_id on ProjectLabel. !16877
- Fix forking projects when no restricted visibility levels are defined applicationwide. !16881
- Resolve PrepareUntrackedUploads PostgreSQL syntax error. !17019
- Fixed error 500 when removing an identity with synced attributes and visiting the profile page. !17054
- Validate user namespace before saving so that errors persist on model.
- LDAP Person no longer throws exception on invalid entry.
- Fix JIRA not working when a trailing slash is included.


## 10.4.3 (2018-02-05)

### Security (4 changes)

- Fix namespace access issue for GitHub, BitBucket, and GitLab.com project importers.
- Fix stored XSS in code blocks that ignore highlighting.
- Fix wilcard protected tags protecting all branches.
- Restrict Todo API mark_as_done endpoint to the user's todos only.


## 10.4.2 (2018-01-30)

### Fixed (6 changes)

- Fix copy/paste on iOS devices due to a bug in webkit. !15804
- Fix missing "allow users to request access" option in public project permissions. !16485
- Fix encoding issue when counting commit count. !16637
- Fixes destination already exists, and some particular service errors on Import/Export error. !16714
- Fix cache clear bug withg using : on Windows. !16740
- Use has_table_privilege for TRIGGER on PostgreSQL.

### Changed (1 change)

- Vendor Auto DevOps template with DAST security checks enabled. !16691


## 10.4.1 (2018-01-24)

### Fixed (4 changes)

- Ensure that users can reclaim a namespace or project path that is blocked by an orphaned route. !16242
- Correctly escape UTF-8 path elements for uploads. !16560
- Fix issues when rendering groups and their children. !16584
- Fix bug in which projects with forks could not change visibility settings from Private to Public. !16595

### Performance (2 changes)

- rework indexes on redirect_routes.
- Remove unnecessary query from labels filter.


## 10.4.0 (2018-01-22)

### Security (8 changes, 1 of them is from the community)

- Upgrade Ruby to 2.3.6 to include security patches. !16016
- Prevent a SQL injection in the MilestonesFinder.
- Check user authorization for source and target projects when creating a merge request.
- Fix path traversal in gitlab-ci.yml cache:key.
- Fix writable shared deploy keys.
- Filter out sensitive fields from the project services API. (Robert Schilling)
- Fix RCE via project import mechanism.
- Prevent OAuth login POST requests when a provider has been disabled.

### Fixed (68 changes, 24 of them are from the community)

- Update comment on image cursor and icons. !15760
- Fixes the wording of headers in system info page. !15802 (Gilbert Roulot)
- Reset todo counters when the target is deleted. !15807
- Execute quick actions (if present) when creating MR from issue. !15810
- fix build count in pipeline success mail. !15827 (Christiaan Van den Poel)
- Fix error that was preventing users to change the access level of access requests for Groups or Projects. !15832
- Last push event widget width for fixed layout. !15862 (George Tsiolis)
- Hide link to issues/MRs from labels list if issues/MRs are disabled. !15863 (Sophie Herold)
- Use relative URL for projects to avoid storing domains. !15876
- Fix gitlab-rake gitlab:import:repos import schedule. !15931
- Removed incorrect guidance stating blocked users will be removed from groups and project as members. !15947 (CesarApodaca)
- Fix some POST/DELETE requests in IE by switching some bundles to Axios for Ajax requests. !15951
- Fixing error 500 when member exist but not the user. !15970
- show None when issue is in closed list and no labels assigned. !15976 (Christiaan Van den Poel)
- Fix tags in the Activity tab not being clickable. !15996 (Mario de la Ossa)
- Disable Vue pagination when only one page of content is available. !15999 (Mario de la Ossa)
- disables shortcut to issue boards when issues are not enabled. !16020 (Christiaan Van den Poel)
- Ignore lost+found folder during backup on a volume. !16036 (Julien Millau)
- Fix abuse reports link url in admin area navbar. !16068 (megos)
- Keep typographic hierarchy in User Settings. !16090 (George Tsiolis)
- Adjust content width for User Settings, GPG Keys. !16093 (George Tsiolis)
- Fix gitlab-rake gitlab:import:repos import schedule. !16115
- Fix import project url not updating project name. !16120
- Fix activity inline event line height on mobile. !16121 (George Tsiolis)
- Fix slash commands dropdown description mis-alignment on Firefox. !16125 (Maurizio De Santis)
- Remove unnecessary sidebar element realignment. !16159 (George Tsiolis)
- User#projects_limit remove DB default and added NOT NULL constraint. !16165 (Mario de la Ossa)
- Fix API endpoints to edit wiki pages where project belongs to a group. !16170
- Fix breadcrumbs in User Settings. !16172 (rfwatson)
- Move 2FA disable button. !16177 (George Tsiolis)
- Fixing bug when wiki last version. !16197
- Protected branch is now created for default branch on import. !16198
- Prevent excessive DB load due to faulty DeleteConflictingRedirectRoutes background migration. !16205
- Force Auto DevOps kubectl version to 1.8.6. !16218
- Fix missing references to pipeline objects when restoring project with import/export feature. !16221
- Fix inconsistent downcase of filenames in prefilled `Add` commit messages. !16232 (James Ramsay)
- Default merge request title is set correctly again when external issue tracker is activated. !16356 (Ben305)
- Ensure that emails contain absolute, rather than relative, links to user uploads. !16364
- Prevent invalid Route path if path is unchanged. !16397
- Fixing rack request mime type when using rack attack. !16427
- Prevent RevList failing on non utf8 paths. !16440
- Fix giant fork icons on forks page. !16474
- Fix links to uploaded files on wiki pages. !16499
- Modify `LDAP::Person` to return username value based on attributes.
- Fixed merge request status badge not updating after merging.
- Remove related links in MR widget when empty state.
- Gracefully handle garbled URIs in Markdown.
- Fix hooks not being set up properly for bare import Rake task.
- Fix Mermaid drawings not loading on some browsers.
- Humanize the units of "Showing last X KiB of log" in job trace.
- Avoid leaving a push event empty if payload cannot be created.
- Show authored date rather than committed date on the commit list.
- Fix when branch creation fails don't post system note. (Mateusz Bajorski)
- Fix viewing merge request diffs where the underlying blobs are unavailable.
- Fix 500 error when visiting a commit where the blobs do not exist.
- Set target_branch to the ref branch when creating MR from issue.
- Fix closed text for issues on Todos page.
- [API] Fix creating issue when assignee_id is empty.
- Fix false positive issue references in merge requests caused by header anchor links.
- Fixed chanages dropdown ellipsis positioning.
- Fix shortcut links on help page.
- Clears visual token on second backspace. (Martin Wortschack)
- Fix onion-skin re-entering state.
- fix button alignment on MWPS component.
- Add optional search param for Merge Requests API.
- Normalizing Identity extern_uid when saving the record.
- Fixed typo for issue description field declaration. (Marcus Amargi)
- Fix ANSI 256 bold colors in pipelines job output.

### Changed (18 changes, 3 of them are from the community)

- Make mail notifications of discussion notes In-Reply-To of each other. !14289
- Migrate existing data from KubernetesService to Clusters::Platforms::Kubernetes. !15589
- Implement checking GCP project billing status in cluster creation form. !15665
- Present multiple clusters in a single list instead of a tabbed view. !15669
- Remove soft removals related code. !15789
- Only mark import and fork jobs as failed once all Sidekiq retries get exhausted. !15844
- Translate date ranges on contributors page. !15846
- Update issuable status icons. !15898
- Update feature toggle design to use icons and make it i18n friendly. !15904
- Update groups tree to use GitLab SVG icons, add last updated at information for projects. !15980
- Allow forking a public project to a private group. !16050
- Expose project_id on /api/v4/pages/domains. !16200 (Luc Didry)
- Display graph values on hover within monitoring page. !16261
- removed tabindexes from tag form. (Marcus Amargi)
- Move edit button to second row on issue page (and change it to a pencil icon).
- Run background migrations with a minimum interval.
- Provide additional cookies to JIRA service requests to allow Oracle WebGates Basic Auth. (Stanislaw Wozniak)
- Hide markdown toolbar in preview mode.

### Performance (11 changes)

- Improve the performance for counting diverging commits. Show 999+ if it is more than 1000 commits. !15963
- Treat empty markdown and html strings as valid cached text, not missing cache that needs to be updated.
- Cache merged and closed events data in merge_request_metrics table.
- Speed up generation of commit stats by using Rugged native methods.
- Improve search query for issues.
- Improve search query for merge requests.
- Eager load event target authors whenever possible.
- Use simple Next/Prev paging for jobs to avoid large count queries on arbitrarily large sets of historical jobs.
- Improve performance of MR discussions on large diffs.
- Add index on namespaces lower(name) for UsersController#exists.
- Fix timeout when filtering issues by label.

### Added (26 changes, 8 of them are from the community)

- Support new chat notifications parameters in Services API. !11435
- Add online and status attribute to runner api entity. !11750
- Adds ordering to projects contributors in API. !15469 (Jacopo Beschi @jacopo-beschi)
- Add assets_sync gem to Gemfile. !15734
- Add a gitlab:tcp_check rake task. !15759
- add support for sorting in tags api. !15772 (haseebeqx)
- Add Prometheus to available Cluster applications. !15895
- Validate file status when committing multiple files. !15922
- List of avatars should never show +1. !15972 (Jacopo Beschi @jacopo-beschi)
- Do not generate NPM links for private NPM modules in blob view. !16002 (Mario de la Ossa)
- Backport fast database lookup of SSH authorized_keys from EE. !16014
- Add i18n helpers to branch comparison view. !16031 (James Ramsay)
- Add pause/resume button to project runners. !16032 (Mario de la Ossa)
- Added option to user preferences to enable the multi file editor. !16056
- Implement project jobs cache reset. !16067
- Rendering of emoji's in Group-Overview. !16098 (Jacopo Beschi @jacopo-beschi)
- Allow automatic creation of Kubernetes Integration from template. !16104
- API: get participants from merge_requests & issues. !16187 (Brent Greeff)
- Added option to disable commits stats in the commit endpoint. !16309
- Disable creation of new Kubernetes Integrations unless they're active or created from template. !41054
- Added badge to tree & blob views to indicate LFS tracked files.
- Enable ordering of groups and their children by name.
- Add button to run scheduled pipeline immediately.
- Allow user to rebase merge requests.
- Handle GitLab hashed storage repositories using the repo import task.
- Hide runner token in CI/CD settings page.

### Other (12 changes, 3 of them are from the community)

- Adds the multi file editor as a new beta feature. !15430
- Use relative URLs when linking to uploaded files. !15751
- Add docs for why you might be signed out when using the Remember me token. !15756
- Replace '.team << [user, role]' with 'add_role(user)' in specs. !16069 (@blackst0ne)
- Add id to modal.vue to support data-toggle="modal". !16189
- Update scss-lint to 0.56.0. !16278 (Takuya Noguchi)
- Fix web ide user preferences copy and buttons. !41789
- Update redis-rack to 2.0.4.
- Import some code and functionality from gitlab-shell to improve subprocess handling.
- Update Browse file to Choose file in all occurrences.
- Bump mysql2 gem version from 0.4.5 to 0.4.10. (asaparov)
- Use a background migration for issues.closed_at.


## 10.3.9 (2018-03-16)

### Security (3 changes)

- Fixed some SSRF vulnerabilities in services, hooks and integrations. !2337
- Update nokogiri to 1.8.2. !16807
- Fix GitLab Auth0 integration signing in the wrong user.


## 10.3.8 (2018-03-01)

### Security (1 change)

- Ensure that OTP backup codes are always invalidated.


## 10.3.7 (2018-02-05)

### Security (4 changes)

- Fix namespace access issue for GitHub, BitBucket, and GitLab.com project importers.
- Fix stored XSS in code blocks that ignore highlighting.
- Fix wilcard protected tags protecting all branches.
- Restrict Todo API mark_as_done endpoint to the user's todos only.


## 10.3.6 (2018-01-22)

### Fixed (17 changes, 2 of them are from the community)

- Fix abuse reports link url in admin area navbar. !16068 (megos)
- Fix gitlab-rake gitlab:import:repos import schedule. !16115
- Fixing bug when wiki last version. !16197
- Prevent excessive DB load due to faulty DeleteConflictingRedirectRoutes background migration. !16205
- Default merge request title is set correctly again when external issue tracker is activated. !16356 (Ben305)
- Prevent invalid Route path if path is unchanged. !16397
- Fixing rack request mime type when using rack attack. !16427
- Prevent RevList failing on non utf8 paths. !16440
- Fix 500 error when visiting a commit where the blobs do not exist.
- Fix viewing merge request diffs where the underlying blobs are unavailable.
- Gracefully handle garbled URIs in Markdown.
- Fix hooks not being set up properly for bare import Rake task.
- Fix Mermaid drawings not loading on some browsers.
- Fixed chanages dropdown ellipsis positioning.
- Avoid leaving a push event empty if payload cannot be created.
- Set target_branch to the ref branch when creating MR from issue.
- Fix shortcut links on help page.


## 10.3.5 (2018-01-18)

- Fix error that prevented the 'deploy_keys' migration from working in MySQL databases.

## 10.3.4 (2018-01-10)

### Security (7 changes, 1 of them is from the community)

- Prevent a SQL injection in the MilestonesFinder.
- Fix RCE via project import mechanism.
- Prevent OAuth login POST requests when a provider has been disabled.
- Filter out sensitive fields from the project services API. (Robert Schilling)
- Check user authorization for source and target projects when creating a merge request.
- Fix path traversal in gitlab-ci.yml cache:key.
- Fix writable shared deploy keys.


## 10.3.3 (2018-01-02)

### Fixed (3 changes)

- Fix links to old commits in merge request comments.
- Fix 404 errors after a user edits an issue description and solves the reCAPTCHA.
- Gracefully handle orphaned write deploy keys in /internal/post_receive.


## 10.3.2 (2017-12-28)

### Fixed (1 change)

- Fix migration for removing orphaned issues.moved_to_id values in MySQL and PostgreSQL.


## 10.3.1 (2017-12-27)

### Fixed (3 changes)

- Don't link LFS objects to a project when unlinking forks when they were already linked. !16006
- Execute project hooks and services after commit when moving an issue.
- Fix Error 500s with anonymous clones for a project that has moved.

### Changed (1 change)

- Reduce the number of buckets in gitlab_cache_operation_duration_seconds metric. !15881


## 10.3.0 (2017-12-22)

### Security (1 change, 1 of them is from the community)

- Upgrade jQuery to 2.2.4. !15570 (Takuya Noguchi)

### Fixed (55 changes, 8 of them are from the community)

- Fail jobs if its dependency is missing. !14009
- Fix errors when selecting numeric-only labels in the labels autocomplete selector. !14607 (haseebeqx)
- Fix pipeline status transition for single manual job. This would also fix pipeline duration becuse it is depending on status transition. !15251
- Fix acceptance of username for Mattermost service update. !15275
- Set the default gitlab-shell timeout to 3 hours. !15292
- Make sure a user can add projects to subgroups they have access to. !15294
- OAuth identity lookups case-insensitive. !15312
- Fix filter by my reaction is not working. !15345 (Hiroyuki Sato)
- Avoid deactivation when pipeline schedules execute a branch includes `[ci skip]` comment. !15405
- Add recaptcha modal to issue updates detected as spam. !15408
- Fix item name and namespace text overflow in Projects dropdown. !15451
- Removed unused rake task, 'rake gitlab:sidekiq:drop_post_receive'. !15493
- Fix commits page throwing 500 when the multi-file editor was enabled. !15502
- Fix Issue comment submit button being disabled when pasting content from another GFM note. !15530
- Reenable Prometheus metrics, add more control over Prometheus method instrumentation. !15558
- Fix broadcast message not showing up on login page. !15578
- Initializes the branches dropdown when the 'Start new pipeline' failed due to validation errors. !15588 (Christiaan Van den Poel)
- Fix merge requests where the source or target branch name matches a tag name. !15591
- Create a fork network for forks with a deleted source. !15595
- Fix search results when a filename would contain a special character. !15606 (haseebeqx)
- Strip leading & trailing whitespaces in CI/CD secret variable keys. !15615
- Correctly link to a forked project from the new fork page. !15653
- Fix the fork project functionality for projects with hashed storage. !15671
- Added default order to UsersFinder. !15679
- Fix graph notes number duplication. !15696 (Vladislav Kaverin)
- Fix updateEndpoint undefined error for issue_show app root. !15698
- Change boards page boards_data absolute urls to paths. !15703
- Using appropriate services in the API for managing forks. !15709
- Confirming email with invalid token should no longer generate an error. !15726
- fix #39233 - 500 in merge request. !15774 (Martin Nowak)
- Use Markdown styling for new project guidelines. !15785 (Markus Koller)
- Fix error during schema dump. !15866
- Fix broken illustration images for monitoring page empty states. !15889
- Make sure user email is read only when synced with LDAP. !15915
- Fixed outdated browser flash positioning.
- Fix gitlab:import:repos Rake task moving repositories into the wrong location.
- Gracefully handle case when repository's root ref does not exist.
- Fix GitHub importer using removed interface.
- Align retry button with job title with new grid size.
- Fixed admin welcome screen new group path.
- Fix related branches/Merge requests failing to load when the hostname setting is changed.
- Init zen mode in snippets pages.
- Remove extra margin from wordmark in header.
- Fixed long commit links not wrapping correctly.
- Fixed deploy keys remove button loading state not resetting.
- Use app host instead of asset host when rendering image blob or diff.
- Hide log size for mobile screens.
- Fix sending notification emails to users with the mention level set who were mentioned in an issue or merge request description.
- Changed validation error message on wrong milestone dates. (Xurxo Méndez Pérez)
- Fix access to the final page of todos.
- Fixed new group milestone breadcrumbs.
- Fix image diff notification email from showing wrong content.
- Fixed merge request lock icon size.
- Make sure head pippeline always corresponds with the head sha of an MR.
- Prevent 500 error when inspecting job after trigger was removed.

### Changed (14 changes, 2 of them are from the community)

- Only owner or master can erase jobs. !15216
- Allow password authentication to be disabled entirely. !15223 (Markus Koller)
- Add the option to automatically run a pipeline after updating AutoDevOps settings. !15380
- Add total_time_spent to the `changes` hash in issuable Webhook payloads. !15381
- Monitor NFS shards for circuitbreaker in a separate process. !15426
- Add inline editing to issues on mobile. !15438
- Add custom brand text on new project pages. !15541 (Markus Koller)
- Show only group name by default and put full namespace in tooltip in Groups tree. !15650
- Use custom user agent header in all GCP API requests. !15705
- Changed the deploy markers on the prometheus dashboard to be more verbose. !38032
- Animate contextual sidebar on collapse/expand.
- Update emojis. Add :gay_pride_flag: and :speech_left:. Remove extraneous comma in :cartwheel_tone4:.
- When a custom header logo is present, don't show GitLab type logo.
- Improved diff changed files dropdown design.

### Performance (19 changes)

- Add timeouts for Gitaly calls. !15047
- Performance issues when loading large number of wiki pages. !15276
- Add performance logging to UpdateMergeRequestsWorker. !15360
- Keep track of all circuitbreaker keys in a set. !15613
- Improve the performance for counting commits. !15628
- Reduce requests for project forks on show page of projects that have forks. !15663
- Perform SQL matching of Build&Runner tags to greatly speed-up job picking.
- Only load branch names for protected branch checks.
- Optimize API /groups/:id/projects by preloading associations.
- Remove allocation tracking code from InfluxDB sampler for performance.
- Throttle the number of UPDATEs triggered by touch.
- Make finding most recent merge request diffs more efficient.
- Fetch blobs in bulk when generating diffs.
- Cache commits for MergeRequest diffs.
- Use fuzzy search with minimum length of 3 characters where appropriate.
- Add axios to common file.
- Remove template selector from global namespace.
- check the import_status field before doing SQL operations to check the import url.
- Stop sending milestone and labels data over the wire for MR widget requests.

### Added (22 changes, 15 of them are from the community)

- Limit autocomplete menu to applied labels. !11110 (Vitaliy @blackst0ne Klachkov)
- Make diff notes created on a commit in a merge request to persist a rebase. !12148
- Allow creation of merge request from email. !13817 (janp)
- Add an ability to use a custom branch name on creation from issues. !13884 (Vitaliy @blackst0ne Klachkov)
- Add anonymous rate limit per IP, and authenticated (web or API) rate limits per user. !14708
- Create a new form to add Existing Kubernetes Cluster. !14805
- Add support of Mermaid (generation of diagrams and flowcharts from text). !15107 (Vitaliy @blackst0ne Klachkov)
- Add total time spent to milestones. !15116 (George Andrinopoulos)
- Add /groups/:id/subgroups endpoint to API. !15142 (marbemac)
- Add administrative endpoint to list all pages domains. !15160 (Travis Miller)
- Adds Rubocop rule for line break after guard clause. !15188 (Jacopo Beschi @jacopo-beschi)
- Add edit button to mobile file view. !15199 (Travis Miller)
- Add dropdown sort to group milestones. !15230 (George Andrinopoulos)
- added support for ordering and sorting in notes api. !15342 (haseebeqx)
- Hashed Storage migration script now supports migrating project attachments. !15352
- New API endpoint - list jobs for a specified runner. !15432
- Add new API endpoint - get a namespace by ID. !15442
- Disables autocomplete in filtered searc. !15477 (Jacopo Beschi @jacopo-beschi)
- Update empty state page of merge request 'changes' tab. !15611 (Vitaliy @blackst0ne Klachkov)
- Allow git pull/push on group/user/project redirects. !15670
- show status of gitlab reference links in wiki. !15694 (haseebeqx)
- Add email confirmation parameters for user creation and update via API. (Daniel Juarez)

### Other (17 changes, 7 of them are from the community)

- Enable UnnecessaryMantissa in scss-lint. !15255 (Takuya Noguchi)
- Add untracked files to uploads table. !15270
- Move update_project_counter_caches? out of issue and merge request. !15300 (George Andrinopoulos)
- Removed tooltip from clone dropdown. !15334
- Clean up empty fork networks. !15373
- Create issuable destroy service. !15604 (George Andrinopoulos)
- Upgrade seed-fu to 2.3.7. !15607 (Takuya Noguchi)
- Rename GKE as Kubernetes Engine. !15608 (Takuya Noguchi)
- Prefer ci_config_path validation for leading slashes instead of sanitizing the input. !15672 (Christiaan Van den Poel)
- Fix typo in docs about Elasticsearch. !15699 (Takuya Noguchi)
- Add internationalization support for the prometheus integration. !33338
- Export text utils functions as es6 module and add tests.
- Stop reloading the page when using pagination and tabs - use API calls - in Pipelines table.
- Clean up schema of the "issues" table.
- Clarify wording of protected branch settings for the default branch.
- Update svg external dependency.
- Clean up schema of the "merge_requests" table.


## 10.2.8 (2018-02-07)

### Security (4 changes)

- Fix namespace access issue for GitHub, BitBucket, and GitLab.com project importers.
- Fix stored XSS in code blocks that ignore highlighting.
- Fix wilcard protected tags protecting all branches.
- Restrict Todo API mark_as_done endpoint to the user's todos only.


## 10.2.7 (2018-01-18)

- No changes.

## 10.2.6 (2018-01-11)

### Security (9 changes, 1 of them is from the community)

- Fix writable shared deploy keys.
- Filter out sensitive fields from the project services API. (Robert Schilling)
- Fix RCE via project import mechanism.
- Fixed IPython notebook output not being sanitized.
- Prevent OAuth login POST requests when a provider has been disabled.
- Prevent a SQL injection in the MilestonesFinder.
- Check user authorization for source and target projects when creating a merge request.
- Fix path traversal in gitlab-ci.yml cache:key.
- Fix XSS vulnerability in pipeline job trace.


## 10.2.5 (2017-12-15)

### Fixed (8 changes)

- Create a fork network for forks with a deleted source. !15595
- Correctly link to a forked project from the new fork page. !15653
- Fix the fork project functionality for projects with hashed storage. !15671
- Fix updateEndpoint undefined error for issue_show app root. !15698
- Fix broken illustration images for monitoring page empty states. !15889
- Fix related branches/Merge requests failing to load when the hostname setting is changed.
- Fix gitlab:import:repos Rake task moving repositories into the wrong location.
- Gracefully handle case when repository's root ref does not exist.

### Performance (3 changes)

- Keep track of all circuitbreaker keys in a set. !15613
- Only load branch names for protected branch checks.
- Optimize API /groups/:id/projects by preloading associations.


## 10.2.4 (2017-12-07)

### Security (5 changes)

- Fix e-mail address disclosure through member search fields
- Prevent creating issues through API when user does not have permissions
- Prevent an information disclosure in the Groups API
- Fix user without access to private Wiki being able to see it on the project page
- Fix Cross-Site Scripting (XSS) vulnerability while editing a comment


## 10.2.3 (2017-11-30)

### Fixed (7 changes)

- Fix hashed storage for Import/Export uploads. !15482
- Ensure that rake gitlab:cleanup:repos task does not mess with hashed repositories. !15520
- Ensure that rake gitlab:cleanup:dirs task does not mess with hashed repositories. !15600
- Fix WIP system note not being created.
- Fix link text from group context.
- Fix defaults for MR states and merge statuses.
- Fix pulling and pushing using a personal access token with the sudo scope.

### Performance (3 changes)

- Drastically improve project search performance by no longer searching namespace name.
- Reuse authors when rendering event Atom feeds.
- Optimise StuckCiJobsWorker using cheap SQL query outside, and expensive inside.


## 10.2.2 (2017-11-23)

### Fixed (5 changes)

- Label addition/removal are not going to be redacted wrongfully in the API. !15080
- Fix bitbucket wiki import with hashed storage enabled. !15490
- Impersonation no longer gets stuck on password change. !15497
- Fix blank states using old css.
- Fix promoting milestone updating all issuables without milestone.

### Performance (3 changes)

- Update Issue Boards to fetch the notification subscription status asynchronously.
- Update composite pipelines index to include "id".
- Use arrays in Pipeline#latest_builds_with_artifacts.

### Other (2 changes)

- Don't move repositories and attachments for projects using hashed storage. !15479
- Add logs for monitoring the merge process.


## 10.2.1 (2017-11-22)

### Fixed (1 change)

- Force disable Prometheus metrics.


## 10.2.0 (2017-11-22)

### Security (4 changes)

- Upgrade Ruby to 2.3.5 to include security patches. !15099
- Prevent OAuth phishing attack by presenting detailed wording about app to user during authorization.
- Convert private tokens to Personal Access Tokens with sudo scope.
- Remove private tokens from web interface and API.

### Removed (5 changes)

- Remove help text from group issues page and group merge requests page. !14963
- Remove overzealous tooltips in projects page tabs. !15017
- Stop merge requests from fetching their refs when the data is already available. !15129
- Remove update merge request worker tagging.
- Remove Session API now that private tokens are removed from user API endpoints.

### Fixed (75 changes, 18 of them are from the community)

- Fix 404 errors in API caused when the branch name had a dot. !14462 (gvieira37)
- Remove unnecessary alt-texts from pipeline emails. !14602 (gernberg)
- Renders 404 in commits controller if no commits are found for a given path. !14610 (Guilherme Vieira)
- Cleanup data-page attribute after each Karma test. !14742
- Removed extra border radius from .file-editor and .file-holder when editing a file. !14803 (Rachel Pipkin)
- Add support for markdown preview to group milestones. !14806 (Vitaliy @blackst0ne Klachkov)
- Fixed 'Removed source branch' checkbox in merge widget being ignored. !14832
- Fix unnecessary ajax requests in admin broadcast message form. !14853
- Make NamespaceSelect change URL when filtering. !14888
- Get true failure from evalulate_script by checking for element beforehand. !14898
- Fix SAML error 500 when no groups are defined for user. !14913
- Fix 500 errors caused by empty diffs in some discussions. !14945 (Alexander Popov)
- Fix the atom feed for group events. !14974
- Hides pipeline duration in commit box when it is zero (nil). !14979 (gvieira37)
- Add new diff discussions on MR diffs tab in "realtime". !14981
- Returns a ssh url for go-get=1. !14990 (gvieira37)
- Case insensitive search for branches. !14995 (George Andrinopoulos)
- Fixes 404 error to 'Issues assigned to me' and 'Issues I've created' when issues are disabled. !15021 (Jacopo Beschi @jacopo-beschi)
- Update the groups API documentation. !15024 (Robert Schilling)
- Validate username/pw for Jiraservice, require them in the API. !15025 (Robert Schilling)
- Update Merge Request polling so there is only one request at a time. !15032
- Use project select dropdown not only as a combobutton. !15043
- Remove create MR button from issues when MRs are disabled. !15071 (George Andrinopoulos)
- Tighten up whitelisting of certain Geo routes. !15082
- Allow to disable the Performance Bar. !15084
- Refresh open Issue and Merge Request project counter caches when re-opening. !15085 (Rob Ede @robjtede)
- Fix markdown form tabs toggling preview mode from double clicking write mode button. !15119
- Fix cancel button not working while uploading on the new issue page. !15137
- Fix webhooks recent deliveries. !15146 (Alexander Randa (@randaalex))
- Fix issues with forked projects of which the source was deleted. !15150
- Fix GPG signature popup info in Safari and Firefox. !15228
- Fix GFM reference links for closed milestones. !15234 (Vitaliy @blackst0ne Klachkov)
- When deleting merged branches, ignore protected tags. !15252
- Revert a regression on runners sorting (!15134). !15341 (Takuya Noguchi)
- Don't use JS to delete memberships from projects and groups. !15344
- Don't try to create fork network memberships for forks with a missing source. !15366
- Fix gitlab:backup rake for hashed storage based repositories. !15400
- Fix issue where clicking a GPG verification badge would scroll to the top of the page. !15407
- Update container repository path reference and allow using double underscore. !15417
- Fix crash when navigating to second page of the group dashboard when there are projects and groups on the first page. !15456
- Fix flash errors showing up on a non configured prometheus integration. !35652
- Fix timezone bug in Pikaday and upgrade Pikaday version.
- Fix arguments Import/Export error importing project merge requests.
- Moves mini graph of pipeline to the end of sentence in MR widget. Cleans HTML and tests.
- Fix user autocomplete in subgroups.
- Fixed user profile activity tab being off-screen on mobile.
- Fix diff parser so it tolerates to diff special markers in the content.
- Fix a migration that adds merge_requests_ff_only_enabled column to MR table.
- Don't create build failed todos when the job is automatically retried.
- Render 404 when polling commit notes without having permissions.
- Show error message when fast-forward merge is not possible.
- Prevents position update for image diff notes.
- Mobile-friendly table on Admin Runners. (Takuya Noguchi)
- Decreases z-index of select2 to a lower number of our navigation bar.
- Fix broken Members link when relative URL root paths are used.
- Avoid regenerating the ref path for the environment.
- Memoize GitLab logger to reduce open file descriptors.
- Fix hashed storage with project transfers to another namespace.
- Fix bad type checking to prevent 0 count badge to be shown.
- Fix problem with issuable header wrapping when content is too long.
- Move retry button in job page to sidebar.
- Formats bytes to human reabale number in registry table.
- Fix commit pipeline showing wrong status.
- Include link to issue in reopen message for Slack and Mattermost notifications.
- Fix double border UI bug on pipelines/environments table and pagination.
- Remove native title tooltip in pipeline jobs dropdown in Safari.
- Fix namespacing for MergeWhenPipelineSucceedsService in MR API.
- Prevent error when authorizing an admin-created OAauth application without a set owner.
- Always return full avatar URL for private/internal groups/projects when asset host is set.
- Make sure group and project creation is blocked for new users that are external by default.
- Make sure NotesActions#noteable returns a Noteable in the update action.
- Reallow project paths ending in periods.
- Only set Auto-Submitted header once for emails on push.
- Fix overlap of right-sidebar and main content when creating a Wiki page.
- Enables scroll to bottom once user has scrolled back to bottom in job log.

### Changed (21 changes, 7 of them are from the community)

- Added possibility to enter past date in /spend command to log time in the past. !3044 (g3dinua, LockiStrike)
- Add Prometheus equivalent of all InfluxDB metrics. !13891
- Show collapsible project lists. !14055
- Make Prometheus metrics endpoint return empty response when metrics are disabled. !14490
- Support custom attributes on groups and projects. !14593 (Markus Koller)
- Avoid fetching all branches for branch existence checks. !14778
- Update participants and subscriptions button in issuable sidebar to be async. !14836
- Replace WikiPage::CreateService calls with wiki_page factory in specs. !14850 (Jacopo Beschi @jacopo-beschi)
- Add lazy option to UserAvatarImage. !14895
- Add readme only option as project view. !14900
- Todos spelled correctly on Todos list page. !15015
- Support uml:: and captions in reStructuredText. !15120 (Markus Koller)
- Add system hooks user_rename and group_rename. !15123
- Change tags order in refs dropdown. !15235 (Vitaliy @blackst0ne Klachkov)
- Change default cluster size to n1-default-2. !39649 (Fabio Busatto)
- Change 'Sign Out' route from a DELETE to a GET. !39708 (Joe Marty)
- Change background color of nav sidebar to match other gl sidebars.
- Update i18n section in FE docs for marking and interpolation.
- Add a count of changes to the merge requests API.
- Improve GitLab Import rake task to work with Hashed Storage and Subgroups.
- 14830 Move GitLab export option to top of import list when creating a new project.

### Performance (14 changes)

- Improve branch listing page performance. !14729
- Improve DashboardController#activity.json performance. !14985
- Add a latest_merge_request_diff_id column to merge_requests. !15035
- Improve performance of the /projects/:id/repository/branches API endpoint. !15215
- Ensure merge requests with lots of version don't time out when searching for pipelines.
- Speed up issues list APIs.
- Remove Filesystem check metrics that use too much CPU to handle requests.
- Disable Unicorn sampling in Sidekiq since there are no Unicorn sockets to monitor.
- Truncate tree to max 1,000 items and display notice to users.
- Add Performance improvement as category on the changelog.
- Cache commits fetched from the repository.
- Cache the number of user SSH keys.
- Optimise getting the pipeline status of commits.
- Improve performance of commits list by fully using DB index when getting commit note counts.

### Added (26 changes, 10 of them are from the community)

- Expose duration in Job entity. !13644 (Mehdi Lahmam (@mehlah))
- Prevent git push when LFS objects are missing. !13837
- Automatic configuration settings page. !13850 (Francisco Lopez)
- Add API endpoints for Pages Domains. !13917 (Travis Miller)
- Include the changes in issuable webhook payloads. !14308
- Add Packagist project service. !14493 (Matt Coleman)
- Add sort runners on admin runners. !14661 (Takuya Noguchi)
- Repo Editor: Add option to start a new MR directly from comit section. !14665
- Issue JWT token with registry:catalog:* scope when requested by GitLab admin. !14751 (Vratislav Kalenda)
- Support show-all-refs for git over HTTP. !14834
- Add loading button for new UX paradigm. !14883
- Get Project Branch API shows an helpful error message on invalid refname. !14884 (Jacopo Beschi @jacopo-beschi)
- Refactor have_http_status into have_gitlab_http_status. !14958 (Jacopo Beschi @jacopo-beschi)
- Suggest to rename the remote for existing repository instructions. !14970 (helmo42)
- Adds project_id to pipeline hook data. !15044 (Jacopo Beschi @jacopo-beschi)
- Hashed Storage support for Attachments. !15068
- Add metric tagging for sidekiq workers. !15111
- Expose project visibility as CI variable - CI_PROJECT_VISIBILITY. !15193
- Allow multiple queries in a single Prometheus graph to support additional environments (Canary, Staging, et al.). !15201
- Allow promoting project milestones to group milestones.
- Added submodule support in multi-file editor.
- Add applications section to GKE clusters page to easily install Helm Tiller, Ingress.
- Allow files to uploaded in the multi-file editor.
- Add Ingress to available Cluster applications.
- Adds typescript support.
- Add sudo scope for OAuth and Personal Access Tokens to be used by admins to impersonate other users on the API.

### Other (18 changes, 8 of them are from the community)

- Decrease Perceived Complexity threshold to 14. !14231 (Maxim Rydkin)
- Replace the 'features/explore/projects.feature' spinach test with an rspec analog. !14755 (Vitaliy @blackst0ne Klachkov)
- While displaying a commit, do not show list of related branches if there are thousands of branches. !14812
- Removed d3.js from the graph and users bundles and used the common_d3 bundle instead. !14826
- Make contributors page translatable. !14915
- Decrease ABC threshold to 54.28. !14920 (Maxim Rydkin)
- Clarify system_hook triggers in documentation. !14957 (Joe Marty)
- Free up some reserved group names. !15052
- Bump carrierwave to 1.2.1. !15072 (Takuya Noguchi)
- Enable NestingDepth (level 6) on scss-lint. !15073 (Takuya Noguchi)
- Enable BorderZero rule in scss-lint. !15168 (Takuya Noguchi)
- Internationalized tags page. !38589
- Moves placeholders components into shared folder with documentation. Makes them easier to reuse in MR and Snippets comments.
- Reorganize welcome page for new users.
- Refactor GroupLinksController. (15121)
- Remove filter icon from search bar.
- Use title as placeholder instead of issue title for reusability.
- Add Gitaly metrics to the performance bar.


## 10.1.7 (2018-01-18)

- No changes.

## 10.1.6 (2018-01-11)

### Security (8 changes, 1 of them is from the community)

- Fix writable shared deploy keys.
- Filter out sensitive fields from the project services API. (Robert Schilling)
- Fix RCE via project import mechanism.
- Prevent OAuth login POST requests when a provider has been disabled.
- Prevent a SQL injection in the MilestonesFinder.
- Check user authorization for source and target projects when creating a merge request.
- Fix path traversal in gitlab-ci.yml cache:key.
- Fix XSS vulnerability in pipeline job trace.


## 10.1.5 (2017-12-07)

### Security (5 changes)

- Fix e-mail address disclosure through member search fields
- Prevent creating issues through API when user does not have permissions
- Prevent an information disclosure in the Groups API
- Fix user without access to private Wiki being able to see it on the project page
- Fix Cross-Site Scripting (XSS) vulnerability while editing a comment


## 10.1.4 (2017-11-14)

### Fixed (4 changes)

- Don't try to create fork network memberships for forks with a missing source. !15366
- Formats bytes to human reabale number in registry table.
- Prevent error when authorizing an admin-created OAauth application without a set owner.
- Prevents position update for image diff notes.


## 10.1.3 (2017-11-10)

- [SECURITY] Prevent OAuth phishing attack by presenting detailed wording about app to user during authorization.
- [FIXED] Fix cancel button not working while uploading on the new issue page. !15137
- [FIXED] Fix webhooks recent deliveries. !15146 (Alexander Randa (@randaalex))
- [FIXED] Fix issues with forked projects of which the source was deleted. !15150
- [FIXED] Fix GPG signature popup info in Safari and Firefox. !15228
- [FIXED] Make sure group and project creation is blocked for new users that are external by default.
- [FIXED] Fix arguments Import/Export error importing project merge requests.
- [FIXED] Fix diff parser so it tolerates to diff special markers in the content.
- [FIXED] Fix a migration that adds merge_requests_ff_only_enabled column to MR table.
- [FIXED] Render 404 when polling commit notes without having permissions.
- [FIXED] Show error message when fast-forward merge is not possible.
- [FIXED] Avoid regenerating the ref path for the environment.
- [PERFORMANCE] Remove Filesystem check metrics that use too much CPU to handle requests.

## 10.1.2 (2017-11-08)

- [SECURITY] Add X-Content-Type-Options header in API responses to make it more difficult to find other vulnerabilities.
- [SECURITY] Properly translate IP addresses written in decimal, octal, or other formats in SSRF protections in project imports.
- [FIXED] Fix TRIGGER checks for MySQL.

## 10.1.1 (2017-10-31)

- [FIXED] Auto Devops kubernetes default namespace is now correctly built out of gitlab project group-name. !14642 (Mircea Danila Dumitrescu)
- [FIXED] Forbid the usage of `Redis#keys`. !14889
- [FIXED] Make the circuitbreaker more robust by adding higher thresholds, and multiple access attempts. !14933
- [FIXED] Only cache last push event for existing projects when pushing to a fork. !14989
- [FIXED] Fix bug preventing secondary emails from being confirmed. !15010
- [FIXED] Fix broken wiki pages that link to a wiki file. !15019
- [FIXED] Don't rename paths that were freed up when upgrading. !15029
- [FIXED] Fix bitbucket login. !15051
- [FIXED] Update gitaly in GitLab 10.1 to 0.43.1 for temp file cleanup. !15055
- [FIXED] Use the correct visibility attribute for projects in system hooks. !15065
- [FIXED] Normalize LDAP DN when looking up identity.
- [FIXED] Adds callback functions for initial request in clusters page.
- [FIXED] Fix missing Import/Export issue assignees.
- [FIXED] Allow boards as top level route.
- [FIXED] Fix widget of locked merge requests not being presented.
- [FIXED] Fix editing issue description in mobile view.
- [FIXED] Fix deletion of container registry or images returning an error.
- [FIXED] Fix the writing of invalid environment refs.
- [CHANGED] Store circuitbreaker settings in the database instead of config. !14842
- [CHANGED] Update default disabled merge request widget message to reflect a general failure. !14960
- [PERFORMANCE] Stop merge requests with thousands of commits from timing out. !15063

## 10.1.0 (2017-10-22)

- [SECURITY] Use a timeout on certain git operations. !14872
- [SECURITY] Move project repositories between namespaces when renaming users.
- [SECURITY] Prevent an open redirect on project pages.
- [SECURITY] Prevent a persistent XSS in user-provided markup.
- [REMOVED] Remove the ability to visit the issue edit form directly. !14523
- [REMOVED] Remove animate.js and label animation.
- [FIXED] Perform prometheus data endpoint requests in parallel. !14003
- [FIXED] Escape quotes in git username. !14020 (Brandon Everett)
- [FIXED] Fixed non-UTF-8 valid branch names from causing an error. !14090
- [FIXED] Read import sources from setting at first initialization. !14141 (Visay Keo)
- [FIXED] Display full pre-receive and post-receive hook output in GitLab UI. !14222 (Robin Bobbitt)
- [FIXED] Fix incorrect X-axis labels in Prometheus graphs. !14258
- [FIXED] Fix the default branches sorting to actually be 'Last updated'. !14295
- [FIXED] Fixes project denial of service via gitmodules using Extended ASCII. !14301
- [FIXED] Fix the filesystem shard health check to check all configured shards. !14341
- [FIXED] Compare email addresses case insensitively when verifying GPG signatures. !14376 (Tim Bishop)
- [FIXED] Allow the git circuit breaker to correctly handle missing repository storages. !14417
- [FIXED] Fix `rake gitlab:incoming_email:check` and make it report the actual error. !14423
- [FIXED] Does not check if an invariant hashed storage path exists on disk when renaming projects. !14428
- [FIXED] Also reserve refs/replace after importing a project. !14436
- [FIXED] Fix profile image orientation based on EXIF data gvieira37. !14461 (gvieira37)
- [FIXED] Move the deployment flag content to the left when deployment marker is near the end. !14514
- [FIXED] Fix notes type created from import. This should fix some missing notes issues from imported projects. !14524
- [FIXED] Fix bottom spacing for dropdowns that open upwards. !14535
- [FIXED] Adjusts tag link to avoid underlining spaces. !14544 (Guilherme Vieira)
- [FIXED] Add missing space in Sidekiq memory killer log message. !14553 (Benjamin Drung)
- [FIXED] Ensure no exception is raised when Raven tries to get the current user in API context. !14580
- [FIXED] Fix edit project service cancel button position. !14596 (Matt Coleman)
- [FIXED] Fix case sensitive email confirmation on signup. !14606 (robdel12)
- [FIXED] Whitelist authorized_keys.lock in the gitlab:check rake task. !14624
- [FIXED] Allow merge in MR widget with no pipeline but using "Only allow merge requests to be merged if the pipeline succeeds". !14633
- [FIXED] Fix navigation dropdown close animation on mobile screens. !14649
- [FIXED] Fix the project import with issues and milestones. !14657
- [FIXED] Use explicit boolean true attribute for show-disabled-button in Vue files. !14672
- [FIXED] Make tabs on top scrollable on admin dashboard. !14685 (Takuya Noguchi)
- [FIXED] Fix broken Y-axis scaling in some Prometheus graphs. !14693
- [FIXED] Search or compare LDAP DNs case-insensitively and ignore excess whitespace. !14697
- [FIXED] Allow prometheus graphs to correctly handle NaN values. !14741
- [FIXED] Don't show an "Unsubscribe" link in snippet comment notifications. !14764
- [FIXED] Fixed duplicate notifications when added multiple labels on an issue. !14798
- [FIXED] Fix alignment for indeterminate marker in dropdowns. !14809
- [FIXED] Fix error when updating a forked project with deleted `ForkedProjectLink`. !14916
- [FIXED] Correctly render asset path for locales with a region. !14924
- [FIXED] Fix the external URLs generated for online view of HTML artifacts. !14977
- [FIXED] Reschedule merge request diff background migrations to catch failures from 9.5 run.
- [FIXED] fix merge request widget status icon for failed CI.
- [FIXED] Fix the number representing the amount of commits related to a push event.
- [FIXED] Sync up hover and legend data across all graphs for the prometheus dashboard.
- [FIXED] Fixes mini pipeline graph in commit view.
- [FIXED] Fix comment deletion confirmation dialog typo.
- [FIXED] Fix project snippets breadcrumb link.
- [FIXED] Make usage ping scheduling more robust.
- [FIXED] Make "merge ongoing" check more consistent.
- [FIXED] Add 1000+ counters to job page.
- [FIXED] Fixed issue/merge request breadcrumb titles not having links.
- [FIXED] Fixed commit avatars being centered vertically.
- [FIXED] Tooltips in the commit info box now all face the same direction. (Jedidiah Broadbent)
- [FIXED] Fixed navbar title colors leaking out of the navbar.
- [FIXED] Fix bug that caused merge requests with diff notes imported from Bitbucket to raise errors.
- [FIXED] Correctly detect multiple issue URLs after 'Closes...' in MR descriptions.
- [FIXED] Set default scope on PATs that don't have one set to allow them to be revoked.
- [FIXED] Fix application setting to cache nil object.
- [FIXED] Fix image diff swipe handle offset to correctly align with the frame.
- [FIXED] Force non diff resolved discussion to display when collapse toggled.
- [FIXED] Fix resolved discussions not expanding on side by side view.
- [FIXED] Fixed the sidebar scrollbar overlapping links.
- [FIXED] Issue board tooltips are now the correct width when the column is collapsed. (Jedidiah Broadbent)
- [FIXED] Improve autodevops banner UX and render it only in project page.
- [FIXED] Fix typo in cycle analytics breaking time component.
- [FIXED] Force two up view to load by default for image diffs.
- [FIXED] Fixed milestone breadcrumb links.
- [FIXED] Fixed group sort dropdown defaulting to empty.
- [FIXED] Fixed notes not being scrolled to in merge requests.
- [FIXED] Adds Event polyfill for IE11.
- [FIXED] Update native unicode emojis to always render as normal text (previously could render italicized). (Branka Martinovic)
- [FIXED] Sort JobsController by id, not created_at.
- [FIXED] Fix revision and total size missing for Container Registry.
- [FIXED] Fixed milestone issuable assignee link URL.
- [FIXED] Fixed breadcrumbs container expanding in side-by-side diff view.
- [FIXED] Fixed merge request widget merged & closed date tooltip text.
- [FIXED] Prevent creating multiple ApplicationSetting instances.
- [FIXED] Fix username and ID not logging in production_json.log for Git activity.
- [FIXED] Make Redcarpet Markdown renderer thread-safe.
- [FIXED] Two factor auth messages in settings no longer overlap the button. (Jedidiah Broadbent)
- [FIXED] Made the "remember me" check boxes have consistent styles and alignment. (Jedidiah Broadbent)
- [FIXED] Prevent branches or tags from starting with invalid characters (e.g. -, .).
- [DEPRECATED] Removed two legacy config options. (Daniel Voogsgerd)
- [CHANGED] Show notes number more user-friendly in the graph. !13949 (Vladislav Kaverin)
- [CHANGED] Link SAML users to LDAP by email. !14216
- [CHANGED] Display whether branch has been merged when deleting protected branch. !14220
- [CHANGED] Make the labels in the Compare form less confusing. !14225
- [CHANGED] Confirmation email shows link as text instead of human readable text. !14243 (bitsapien)
- [CHANGED] Return only group's members in user dropdowns on issuables list pages. !14249
- [CHANGED] Added defaults for protected branches dropdowns on the repository settings. !14278
- [CHANGED] Show confirmation modal before deleting account. !14360
- [CHANGED] Allow creating merge requests across a fork network. !14422
- [CHANGED] Re-arrange script HTML tags before template HTML tags in .vue files. !14671
- [CHANGED] Create idea of read-only database. !14688
- [CHANGED] Add active states to nav bar counters.
- [CHANGED] Add view replaced file link for image diffs.
- [CHANGED] Adjust tooltips to adhere to 8px grid and make them more readable.
- [CHANGED] breadcrumbs receives padding when double lined.
- [CHANGED] Allow developer role to admin milestones.
- [CHANGED] Stop using Sidekiq for updating Key#last_used_at.
- [CHANGED] Include GitLab full name in Slack messages.
- [ADDED] Expose last pipeline details in API response when getting a single commit. !13521 (Mehdi Lahmam (@mehlah))
- [ADDED] Allow to use same periods for different housekeeping tasks (effectively skipping the lesser task). !13711 (cernvcs)
- [ADDED] Add GitLab-Pages version to Admin Dashboard. !14040 (travismiller)
- [ADDED] Commenting on image diffs. !14061
- [ADDED] Script to migrate project's repositories to new Hashed Storage. !14067
- [ADDED] Hide close MR button after merge without reloading page. !14122 (Jacopo Beschi @jacopo-beschi)
- [ADDED] Add Gitaly version to Admin Dashboard. !14313 (Jacopo Beschi @jacopo-beschi)
- [ADDED] Add 'closed_at' attribute to Issues API. !14316 (Vitaliy @blackst0ne Klachkov)
- [ADDED] Add tooltip for milestone due date to issue and merge request lists. !14318 (Vitaliy @blackst0ne Klachkov)
- [ADDED] Improve list of sorting options. !14320 (Vitaliy @blackst0ne Klachkov)
- [ADDED] Add client and call site metadata to Gitaly calls for better traceability. !14332
- [ADDED] Strip gitlab-runner section markers in build trace HTML view. !14393
- [ADDED] Add online view of HTML artifacts for public projects. !14399
- [ADDED] Create Kubernetes cluster on GKE from k8s service. !14470
- [ADDED] Add support for GPG subkeys in signature verification. !14517
- [ADDED] Parse and store gitlab-runner timestamped section markers. !14551
- [ADDED] Add "implements" to the default issue closing message regex. !14612 (Guilherme Vieira)
- [ADDED] Replace `tag: true` into `:tag` in the specs. !14653 (Jacopo Beschi @jacopo-beschi)
- [ADDED] Discussion lock for issues and merge requests.
- [ADDED] Add an API endpoint to determine the forks of a project.
- [ADDED] Add help text to runner edit: tags should be separated by commas. (Brendan O'Leary)
- [ADDED] Only copy old/new code when selecting left/right side of parallel diff.
- [ADDED] Expose avatar_url when requesting list of projects from API with simple=true.
- [ADDED] A confirmation email is now sent when adding a secondary email address. (digitalmoksha)
- [ADDED] Move Custom merge methods from EE.
- [ADDED] Makes @mentions links have a different styling for better separation.
- [ADDED] Added tabs to dashboard/projects to easily switch to personal projects.
- [OTHER] Extract AutocompleteController#users into finder. !13778 (Maxim Rydkin, Mayra Cabrera)
- [OTHER] Replace 'project/wiki.feature' spinach test with an rspec analog. !13856 (Vitaliy @blackst0ne Klachkov)
- [OTHER] Expand docs for changing username or group path. !13914
- [OTHER] Move `lib/ci` to `lib/gitlab/ci`. !14078 (Maxim Rydkin)
- [OTHER] Decrease Cyclomatic Complexity threshold to 13. !14152 (Maxim Rydkin)
- [OTHER] Decrease Perceived Complexity threshold to 15. !14160 (Maxim Rydkin)
- [OTHER] Replace project/group_links.feature spinach test with an rspec analog. !14169 (Vitaliy @blackst0ne Klachkov)
- [OTHER] Replace the project/milestone.feature spinach test with an rspec analog. !14171 (Vitaliy @blackst0ne Klachkov)
- [OTHER] Replace the profile/emails.feature spinach test with an rspec analog. !14172 (Vitaliy @blackst0ne Klachkov)
- [OTHER] Replace the project/team_management.feature spinach test with an rspec analog. !14173 (Vitaliy @blackst0ne Klachkov)
- [OTHER] Replace the 'project/merge_requests/accept.feature' spinach test with an rspec analog. !14176 (Vitaliy @blackst0ne Klachkov)
- [OTHER] Replace the 'project/builds/summary.feature' spinach test with an rspec analog. !14177 (Vitaliy @blackst0ne Klachkov)
- [OTHER] Optimize the boards' issues fetching. !14198
- [OTHER] Replace the 'project/merge_requests/revert.feature' spinach test with an rspec analog. !14201 (Vitaliy @blackst0ne Klachkov)
- [OTHER] Replace the 'project/issues/award_emoji.feature' spinach test with an rspec analog. !14202 (Vitaliy @blackst0ne Klachkov)
- [OTHER] Replace the 'profile/active_tab.feature' spinach test with an rspec analog. !14239 (Vitaliy @blackst0ne Klachkov)
- [OTHER] Replace the 'search.feature' spinach test with an rspec analog. !14248 (Vitaliy @blackst0ne Klachkov)
- [OTHER] Load sidebar participants avatars only when visible. !14270
- [OTHER] Adds gitlab features and components to usage ping data. !14305
- [OTHER] Replace the 'project/archived.feature' spinach test with an rspec analog. !14322 (Vitaliy @blackst0ne Klachkov)
- [OTHER] Replace the 'project/commits/revert.feature' spinach test with an rspec analog. !14325 (Vitaliy @blackst0ne Klachkov)
- [OTHER] Replace the 'project/snippets.feature' spinach test with an rspec analog. !14326 (Vitaliy @blackst0ne Klachkov)
- [OTHER] Add link to OpenID Connect documentation. !14368 (Markus Koller)
- [OTHER] Upgrade doorkeeper-openid_connect. !14372 (Markus Koller)
- [OTHER] Upgrade gitlab-markup gem. !14395 (Markus Koller)
- [OTHER] Index projects on repository storage. !14414
- [OTHER] Replace the 'project/shortcuts.feature' spinach test with an rspec analog. !14431 (Vitaliy @blackst0ne Klachkov)
- [OTHER] Replace the 'project/service.feature' spinach test with an rspec analog. !14432 (Vitaliy @blackst0ne Klachkov)
- [OTHER] Improve GitHub import performance. !14445
- [OTHER] Add basic sprintf implementation to JavaScript. !14506
- [OTHER] Replace the 'project/merge_requests.feature' spinach test with an rspec analog. !14621 (Vitaliy @blackst0ne Klachkov)
- [OTHER] Update GitLab Pages to v0.6.0. !14630
- [OTHER] Add documentation to summarise project archiving. !14650
- [OTHER] Remove 'Repo' prefix from API entites. !14694 (Vitaliy @blackst0ne Klachkov)
- [OTHER] Removes cycle analytics service and store from global namespace.
- [OTHER] Improves i18n for Auto Devops callout.
- [OTHER] Exports common_utils utility functions as modules.
- [OTHER] Use `simple=true` for projects API in Projects dropdown for better search performance.
- [OTHER] Change index on ci_builds to optimize Jobs Controller.
- [OTHER] Add index for merge_requests.merge_commit_sha.
- [OTHER] Add (partial) index on Labels.template.
- [OTHER] Cache issue and MR template names in Redis.
- [OTHER] changed dashed border button color to be darker.
- [OTHER] Speed up permission checks.
- [OTHER] Fix docs for lightweight tag creation via API.
- [OTHER] Clarify artifact download via the API only accepts branch or tag name for ref.
- [OTHER] Change recommended MySQL version to 5.6.
- [OTHER] Bump google-api-client Gem from 0.8.6 to 0.13.6.
- [OTHER] Detect when changelog entries are invalid.
- [OTHER] Use a UNION ALL for getting merge request notes.
- [OTHER] Remove an index on ci_builds meant to be only temporary.
- [OTHER] Remove a SQL query from the todos index page.
- Support custom attributes on users. !13038 (Markus Koller)
- made read-only APIs for public merge requests available without authentication. !13291 (haseebeqx)
- Hide read_registry scope when registry is disabled on instance. !13314 (Robin Bobbitt)
- creation of keys moved to services. !13331 (haseebeqx)
- Add username as GL_USERNAME in hooks.

## 10.0.7 (2017-12-07)

### Security (5 changes)

- Fix e-mail address disclosure through member search fields
- Prevent creating issues through API when user does not have permissions
- Prevent an information disclosure in the Groups API
- Fix user without access to private Wiki being able to see it on the project page
- Fix Cross-Site Scripting (XSS) vulnerability while editing a comment


## 10.0.5 (2017-11-03)

- [FIXED] Fix incorrect X-axis labels in Prometheus graphs. !14258
- [FIXED] Fix `rake gitlab:incoming_email:check` and make it report the actual error. !14423
- [FIXED] Does not check if an invariant hashed storage path exists on disk when renaming projects. !14428
- [FIXED] Fix bottom spacing for dropdowns that open upwards. !14535
- [FIXED] Fix the project import with issues and milestones. !14657
- [FIXED] Fix broken Y-axis scaling in some Prometheus graphs. !14693
- [FIXED] Fixed duplicate notifications when added multiple labels on an issue. !14798
- [FIXED] Don't rename paths that were freed up when upgrading. !15029
- [FIXED] Fixed issue/merge request breadcrumb titles not having links.
- [FIXED] Fix application setting to cache nil object.
- [FIXED] Fix missing Import/Export issue assignees.
- [FIXED] Allow boards as top level route.
- [FIXED] Fixed milestone breadcrumb links.
- [FIXED] Fixed merge request widget merged & closed date tooltip text.
- [FIXED] fix merge request widget status icon for failed CI.

## 10.0.4 (2017-10-16)

- [SECURITY] Move project repositories between namespaces when renaming users.
- [SECURITY] Prevent an open redirect on project pages.
- [SECURITY] Prevent a persistent XSS in user-provided markup.

## 10.0.3 (2017-10-05)

- [FIXED] find_user Users helper method no longer overrides find_user API helper method. !14418
- [FIXED] Fix CSRF validation issue when closing/opening merge requests from the UI. !14555
- [FIXED] Kubernetes integration: ensure v1.8.0 compatibility. !14635
- [FIXED] Fixes data parameter not being sent in ajax request for jobs log.
- [FIXED] Improves UX of autodevops popover to match gpg one.
- [FIXED] Fixed commenting on side-by-side commit diff.
- [FIXED] Make sure API responds with 401 when invalid authentication info is provided.
- [FIXED] Fix merge request counter updates after merge.
- [FIXED] Fix gitlab-rake gitlab:import:repos task failing.
- [FIXED] Fix pushes to an empty repository not invalidating has_visible_content? cache.
- [FIXED] Ensure all refs are restored on a restore from backup.
- [FIXED] Gitaly RepositoryExists remains opt-in for all method calls.
- [FIXED] Fix 500 error on merged merge requests when GitLab is restored from a backup.
- [FIXED] Adjust MRs being stuck on "process of being merged" for more than 2 hours.

## 10.0.2 (2017-09-27)

- [FIXED] Notes will not show an empty bubble when the author isn't a member. !14450
- [FIXED] Some checks in `rake gitlab:check` were failling with 'undefined method `run_command`'. !14469
- [FIXED] Make locked setting of Runner to not affect jobs scheduling. !14483
- [FIXED] Re-allow `name` attribute on user-provided anchor HTML.

## 10.0.1 (2017-09-23)

- [FIXED] Fix duplicate key errors in PostDeployMigrateUserExternalMailData migration.

## 10.0.0 (2017-09-22)

- [SECURITY] Upgrade brace-expansion NPM package due to security issue. !13665 (Markus Koller)
- [REMOVED] Remove CI API v1.
- [FIXED] Ensure correct visibility level options shown on all Project, Group, and Snippets forms. !13442
- [FIXED] Fix the /projects/:id/repository/files/:file_path/raw endpoint to handle dots in the file_path. !13512 (mahcsig)
- [FIXED] Merge request reference in merge commit changed to full reference. !13518 (haseebeqx)
- [FIXED] Removes Sortable default scope. !13558
- [FIXED] Wiki table of contents are now properly nested to reflect header level. !13650 (Akihiro Nakashima)
- [FIXED] Improve bare project import: Allow subgroups, take default visibility level into account. !13670
- [FIXED] Fix group and project search for anonymous users. !13745
- [FIXED] Fix searching for files by path. !13798
- [FIXED] Fix division by zero error in blame age mapping. !13803 (Jeff Stubler)
- [FIXED] Fix incorrect date/time formatting on prometheus graphs. !13865
- [FIXED] Changes the password change workflow for admins. !13901
- [FIXED] API: Respect default group visibility when creating a group. !13903 (Robert Schilling)
- [FIXED] Unescape HTML characters in Wiki title. !13942 (Jacopo Beschi @jacopo-beschi)
- [FIXED] Make blob viewer for rich contents wider for mobile. !14011 (Takuya Noguchi)
- [FIXED] Fix typo in the API Deploy Keys documentation page. !14014 (Vitaliy @blackst0ne Klachkov)
- [FIXED] Hide admin link from default search results for non-admins. !14015
- [FIXED] Fix problems sanitizing URLs with empty passwords. !14083
- [FIXED] Fix stray OR in New Project page. !14096 (Robin Bobbitt)
- [FIXED] Fix a wrong `X-Gitlab-Event` header when testing webhooks. !14108
- [FIXED] Fix the diff file header from being html escaped for renamed files. !14121
- [FIXED] Image attachments are properly displayed in notification emails again. !14161
- [FIXED] Fixes the 500 errors caused by a race condition in GPG's tmp directory handling. !14194 (Alexis Reigel)
- [FIXED] Fix MR ready to merge buttons/controls at mobile breakpoint. !14242
- [FIXED] Fix Pipeline Triggers to show triggered label and predefined variables (e.g. CI_PIPELINE_TRIGGERED). !14244
- [FIXED] Allow using newlines in pipeline email service recipients. !14250
- [FIXED] Fix errors when moving issue with reference to a group milestone. !14294
- [FIXED] Fix the "resolve discussion in a new issue" button. !14357
- [FIXED] File uploaders do not perform hard check, only soft check.
- [FIXED] Add to_project_id parameter to Move Issue via API example.
- [FIXED] Update x/x discussions resolved checkmark icon to be green when all discussions resolved.
- [FIXED] Fixed add diff note button not showing after deleting a comment.
- [FIXED] Fix broken svg in jobs dropdown for success status.
- [FIXED] Fix buttons with different height in merge request widget.
- [FIXED] Removes disabled state from dashboard project button.
- [FIXED] Better align fallback image emojis.
- [FIXED] Remove focus styles from dropdown empty links.
- [FIXED] Fix inconsistent spacing for edit buttons on issues and merge request page.
- [FIXED] Fix edit merge request and issues button inconsistent letter casing.
- [FIXED] Improve Import/Export memory usage.
- [FIXED] Fix Import/Export issue to do with fork merge requests.
- [FIXED] Fix invite by email address duplication.
- [FIXED] Adds tooltip to the branch name and improves performance.
- [FIXED] Disable GitLab Project Import Button if source disabled.
- [FIXED] Migrate issues authored by deleted user to the Ghost user.
- [FIXED] Fix new navigation wrapping and causing height to grow.
- [FIXED] Normalize styles for empty state combo button.
- [FIXED] Fix external link to Composer website.
- [FIXED] Prevents jobs dropdown from closing in pipeline graph.
- [FIXED] Include the `is_admin` field in the `GET /users/:id` API when current user is an admin.
- [FIXED] Fix breadcrumbs container in issue boards.
- [FIXED] Fix project feature being deleted when updating project with invalid visibility level.
- [FIXED] Truncate milestone title if sidebar is collapsed.
- [FIXED] Prevents rendering empty badges when request fails.
- [FIXED] Fixes margins on the top buttons of the pipeline table.
- [FIXED] Bump jira-ruby gem to 1.4.1 to fix issues with HTTP proxies.
- [FIXED] Eliminate N+1 queries in loading discussions.json endpoint.
- [FIXED] Eliminate N+1 queries referencing issues.
- [FIXED] Remove unnecessary loading of discussions in `IssuesController#show`.
- [FIXED] Fix errors thrown in merge request widget with external CI service/integration.
- [FIXED] Do not show the Auto DevOps banner when the project has a .gitlab-ci.yml on master.
- [FIXED] Reword job to pipeline to reflect what the graphs are really about.
- [FIXED] Sort templates in the dropdown.
- [FIXED] Fix Auto DevOps banner to be shown on empty projects.
- [FIXED] Resolve Image onion skin + swipe does not work anymore.
- [FIXED] Fix mini graph pipeline breakin in merge request view.
- [FIXED] Fixed merge request changes bar jumping.
- [FIXED] Improve migrations using triggers.
- [FIXED] Fix ConvDev Index nav item and Monitoring submenu regression.
- [FIXED] disabling notifications globally now properly turns off group/project added
  emails !13325
- [DEPRECATED] Deprecate custom SSH client configuration for the git user. !13930
- [CHANGED] allow all users to delete their account. !13636 (Jacopo Beschi @jacopo-beschi)
- [CHANGED] Use full path of project's avatar in webhooks. !13649 (Vitaliy @blackst0ne Klachkov)
- [CHANGED] Add filtered search to group merge requests dashboard. !13688 (Hiroyuki Sato)
- [CHANGED] Fire hooks asynchronously when creating a new job to improve performance. !13734
- [CHANGED] Improve performance for AutocompleteController#users.json. !13754 (Hiroyuki Sato)
- [CHANGED] Update the GPG verification semantics: A GPG signature must additionally match the committer in order to be verified. !13771 (Alexis Reigel)
- [CHANGED] Support a multi-word fuzzy search issues/merge requests on search bar. !13780 (Hiroyuki Sato)
- [CHANGED] Default LDAP config "verify_certificates" to true for security. !13915
- [CHANGED] "Share with group lock" now applies to subgroups, but owner can override setting on subgroups. !13944
- [CHANGED] Make Gitaly PostUploadPack mandatory. !13953
- [CHANGED] Remove project select dropdown from breadcrumb. !14010
- [CHANGED] Redesign project feature permissions settings. !14062
- [CHANGED] Document version Group Milestones API introduced.
- [CHANGED] Finish migration to the new events setup.
- [CHANGED] restyling of OAuth authorization confirmation. (Jacopo Beschi @jacopo-beschi)
- [CHANGED] Added support for specific labels and colors.
- [CHANGED] Move "Move issue" controls to right-sidebar.
- [CHANGED] Remove pages settings when not available.
- [CHANGED] Allow all AutoDevOps banners to be turned off.
- [CHANGED] Update Rails project template to use Postgresql by default.
- [CHANGED] Added support the multiple time series for prometheus monitoring.
- [ADDED] API: Respect the "If-Unmodified-Since" header when delting a resource. !9621 (Robert Schilling)
- [ADDED] Protected runners. !13194
- [ADDED] Add support for copying permalink to notes via more actions dropdown. !13299
- [ADDED] Add API support for wiki pages. !13372 (Vitaliy @blackst0ne Klachkov)
- [ADDED] Add a `Last 7 days` option for Cycle Analytics view. !13443 (Mehdi Lahmam (@mehlah))
- [ADDED] inherits milestone and labels when a merge request is created from issue. !13461 (haseebeqx)
- [ADDED] Add 'from commit' information to cherry-picked commits. !13475 (Saverio Miroddi)
- [ADDED] Add an option to list only archived projects. !13492 (Mehdi Lahmam (@mehlah))
- [ADDED] Extend API: Pipeline Schedule Variable. !13653
- [ADDED] Add settings for minimum SSH key strength and allowed key type. !13712 (Cory Hinshaw)
- [ADDED] Add div id to the readme in the project overview. !13735 (Riccardo Padovani @rpadovani)
- [ADDED] Add CI/CD job predefined variables with user name and login. !13824
- [ADDED] API: Add GPG key management. !13828 (Robert Schilling)
- [ADDED] Add CI/CD active kubernetes job policy. !13849
- [ADDED] Add dropdown to Projects nav item. !13866
- [ADDED] Allow users and administrator to configure Auto-DevOps. !13923
- [ADDED] Implement `failure_reason` on `ci_builds`. !13937
- [ADDED] Add branch existence check to the APIv4 branches via HEAD request. !13979 (Vitaliy @blackst0ne Klachkov)
- [ADDED] Add quick submission on user settings page. !14007 (Vitaliy @blackst0ne Klachkov)
- [ADDED] Add my_reaction_emoji param to /issues and /merge_requests API. !14016 (Hiroyuki Sato)
- [ADDED] Make it possible to download a single job artifact file using the API. !14027
- [ADDED] Add repository toggle for automatically resolving outdated diff discussions. !14053 (AshleyDumaine)
- [ADDED] Scripts to detect orphaned repositories. !14204
- [ADDED] Created callout for auto devops.
- [ADDED] Add option in preferences to change navigation theme color.
- [ADDED] Add JSON logger in `log/api_json.log` for Grape API endpoints.
- [ADDED] Add CI_PIPELINE_SOURCE variable on CI Jobs.
- [ADDED] Changed message and title on the 404 page. (Branka Martinovic)
- [ADDED] Handle if Auto DevOps domain is not set in project settings.
- [ADDED] Add collapsable sections for Pipeline Settings.
- [OTHER] Add badge for dependency status. !13588 (Markus Koller)
- [OTHER] Migration to remove pending delete projects with non-existing namespace. !13598
- [OTHER] Bump rouge to v2.2.0. !13633
- [OTHER] Fix repository equality check and avoid fetching ref if the commit is already available. This affects merge request creation performance. !13685
- [OTHER] Replace 'source/search_code.feature' spinach test with an rspec analog. !13697 (blackst0ne)
- [OTHER] Remove unwanted refs after importing a project. !13766
- [OTHER] Never wait for sidekiq jobs when creating projects. !13775
- [OTHER] Gitaly feature toggles are on by default in development. !13802
- [OTHER] Remove `is_` prefix from predicate method names. !13810 (Maxim Rydkin)
- [OTHER] Update 'Using Docker images' documentation. !13848
- [OTHER] Update gpg documentation with gpg2. !13851 (M M Arif)
- [OTHER] Replace 'project/star.feature' spinach test with an rspec analog. !13855 (Vitaliy @blackst0ne Klachkov)
- [OTHER] Replace 'project/user_lookup.feature' spinach test with an rspec analog. !13863 (Vitaliy @blackst0ne Klachkov)
- [OTHER] Bump rouge to v2.2.1. !13887
- [OTHER] Add documentation for PlantUML in reStructuredText. !13900 (Markus Koller)
- [OTHER] Decrease ABC threshold to 55.25. !13904 (Maxim Rydkin)
- [OTHER] Decrease Cyclomatic Complexity threshold to 14. !13972 (Maxim Rydkin)
- [OTHER] Update documentation for confidential issue. !14117
- [OTHER] Remove redundant WHERE from event queries.
- [OTHER] Memoize the latest builds of a pipeline on a project's homepage.
- [OTHER] Re-use issue/MR counts for the pagination system.
- [OTHER] Memoize pipelines for project download buttons.
- [OTHER] Reorganize indexes for the "deployments" table.
- [OTHER] Improves markdown rendering performance for commit lists.
- [OTHER] Only update the sidebar count caches when needed.
- [OTHER] Improves performance of vue code by using vue files and moving svg out of data function in pipeline schedule callout.
- [OTHER] Rework how recent push events are retrieved.
- [OTHER] Restyle dropdown menus to make them look consistent.
- [OTHER] Upgrade grape to 1.0.
- [OTHER] Add usage data for Auto DevOps.
- [OTHER] Cache the number of open issues and merge requests.
- [OTHER] Constrain environment deployments to project IDs.
- [OTHER] Eager load namespace owners for project dashboards.
- [OTHER] Add description template examples to documentation.
- [OTHER] Disallow NULL values for environments.project_id.
- Add my reaction filter to search bar. !12962 (Hiroyuki Sato)
- Generalize profile updates from providers. !12968 (Alexandros Keramidas)
- Validate PO-files in static analysis. !13000
- First-time contributor badge. !13143 (Micaël Bergeron <micaelbergeron@gmail.com>)
- Add option to disable project export on instance. !13211 (Robin Bobbitt)
- Hashed Storage support for Repositories (EXPERIMENTAL). !13246
- Added tests for commits API unauthenticated user and public/private project. !13287 (Jacopo Beschi @jacopo-beschi)
- Fix CI_PROJECT_PATH_SLUG slugify. !13350 (Ivan Chernov)
- Add checks for branch existence before changing HEAD. !13359 (Vitaliy @blackst0ne Klachkov)
- Fix the alignment of line numbers to lines of code in code viewer. !13403 (Trevor Flynn)
- Allow users to move issues to other projects using a / command. !13436 (Manolis Mavrofidis)
- Bumps omniauth-ldap gem version to 2.0.4. !13465
- Implement the Gitaly RefService::RefExists endpoint. !13528 (Andrew Newdigate)
- Changed all font-weight values to 400 and 600 and introduced 2 variables to manage them.
- Simplify checking if objects exist code in new issaubles workers.
- Present enqueued merge jobs as Merging as well.
- Don't escape html entities in InlineDiffMarkdownMarker.
- Move ConvDev Index location to after Cohorts.
- Added type to CHANGELOG entries. (Jacopo Beschi @jacopo-beschi)
- [BUGIFX] Improves subgroup creation permissions. !13418
