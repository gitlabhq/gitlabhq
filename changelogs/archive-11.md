## 11.11.8

### Security (2 changes)

- Upgrade Gitaly to 1.42.7 to prevent revision flag injection exploits.
- Upgrade pages to 1.5.1 to prevent gitlab api token recovery from cookie.


## 11.11.7

### Security (9 changes)

- Restrict slash commands to users who can log in.
- Patch XSS issue in wiki links.
- Filter merge request params on the new merge request page.
- Fix Server Side Request Forgery mitigation bypass.
- Show badges if pipelines are public otherwise default to project permissions.
- Do not allow localhost url redirection in GitHub Integration.
- Do not show moved issue id for users that cannot read issue.
- Use source project as permissions reference for MergeRequestsController#pipelines.
- Drop feature to take ownership of trigger token.


## 11.11.4 (2019-06-26)

### Fixed (3 changes)

- Fix Fogbugz Importer not working. !29383
- Fix scrolling to top on assignee change. !29500
- Fix IDE commit using latest ref in branch and overriding contents. !29769


## 11.11.3 (2019-06-10)

### Fixed (5 changes)

- Fix invalid visibility string comparison in project import. !28612
- Remove a default git depth in Pipelines for merge requests. !28926
- Fix connection to Tiller error while uninstalling. !29131
- Fix label click scrolling to top. !29202
- Make OpenID Connect work without requiring a name. !29312


## 11.11.2 (2019-06-04)

### Fixed (7 changes)

- Update SAST.gitlab-ci.yml - Add SAST_GITLEAKS_ENTROPY_LEVEL. !28607
- Fix OmniAuth OAuth2Generic strategy not loading. !28680
- Use source ref in pipeline webhook. !28772
- Fix migration failure when groups are missing route. !29022
- Stop two-step rebase from hanging when errors occur. !29068
- Fix project settings not being able to update. !29097
- Fix display of 'Promote to group label' button.

### Other (1 change)

- Fix input group height.


## 11.11.0 (2019-05-22)

### Security (1 change)

- Destroy project remote mirrors instead of disabling. !27087

### Fixed (75 changes, 19 of them are from the community)

- Don't create a temp reference for branch comparisons within project. !24038
- Fix some label links not appearing on group labels page and label title being a link on project labels page. !24060 (Tanya Pazitny)
- Fix extra emails for custom notifications. !25607
- Rewind IID on Ci::Pipelines. !26490
- Fix duplicate merge request pipelines created by Sidekiq worker retry. !26643
- Catch and report OpenSSL exceptions while fetching external configuration files in CI::Config. !26750 (Drew Cimino)
- stop rendering download links for expired artifacts on the project tags page. !26753 (Drew Cimino)
- Format extra help page text like wiki. !26782 (Bastian Blank)
- Always show instance configuration link. !26783 (Bastian Blank)
- Display maximum artifact size from runtime config. !26784 (Bastian Blank)
- Resolve issue where list labels did not have the correct text color on creation. !26794 (Tucker Chapman)
- Set release name when adding release notes to an existing tag. !26807
- Fix the bug that the project statistics is not updated. !26854 (Hiroyuki Sato)
- Client side changes for ListLastCommitsForTree response update. !26880
- Fix api group visibility. !26896
- Require all templates to use default stages. !26954
- Remove a "reopen merge request button" on a "merged" merge request. !26965 (Hiroyuki Sato)
- Fix misaligned image diff swipe view. !26969 (ftab)
- Add badge-pill class on group member count. !27019
- Remove leading / trailing spaces from heading when generating header ids. !27025 (Willian Balmant)
- Respect updated_at attribute in notes produced by API calls. !27124 (Ben Gamari)
- Fix GitHub project import visibility. !27133 (Daniel Wyatt)
- Fixes actions dropdowns in environments page. !27160
- Fixes create button background for Environments form. !27161
- Display scoped labels in Issue Boards. !27164
- Align UrlValidator to validate_url gem implementation. !27194 (Horatiu Eugen Vlad)
- Resolve Web IDE template dropdown showing duplicates. !27237
- Update GitLab Workhorse to v8.6.0. !27260
- Only show in autocomplete when author active. !27292
- Remove deadline for Git fsck. !27299
- Show prioritized labels to guests. !27307
- Properly expire all pipeline caches when pipeline is deleted. !27334
- Replaced icon for external URL with doc-text icon. !27365
- Add auto direction for issue title. !27378 (Ahmad Haghighi)
- fix wiki search result links in titles. !27400 (khm)
- Fix system notes timestamp when creating issue in the past. !27406
- Fix approvals sometimes being reset after a merge request is rebased. !27446
- Fix empty block in MR widget when user doesn't have permission. !27462
- Fix wrong use of ActiveRecord in PoolRepository. !27464
- Show proper preview for uploaded images in Web IDE. !27471
- Resolve Renaming an image via Web IDE corrupts it. !27486
- Clean up CarrierWave's import/export files. !27487
- Fix autocomplete dropdown for usernames starting with period. !27533 (Jan Beckmann)
- Disable password autocomplete in mirror repository form. !27542
- Always use internal ID tables in development and production. !27544
- Only show the "target branch has advanced" message when the merge request is open. !27588
- Resolve Misalignment on suggested changes diff table. !27612
- Update Workhorse to v8.7.0. !27630
- Fix FE API and IDE handling of '/' relative_url_root. !27635
- Hide ScopedBadge overflow notes. !27651
- Fix base domain help text update. !27746
- Upgrade letter_opener_web to support Rails 5.1. !27829
- Fix webpack assets handling when relative url root is '/'. !27909
- Fix IDE get file data with '/' as relative root. !27911
- Allow a member to have an access level equal to parent group. !27913
- Fix issuables state_id nil when importing projects from GitHub. !28027
- Fix uploading of LFS tracked file through UI. !28052
- Render Next badge only for gitlab.com. !28056
- Fix update head pipeline process of Pipelines for merge requests. !28057
- Handle errors in successful notes reply. !28082
- Fix visual issues in set status modal. !28147
- Use a path for the related merge requests endpoint. !28171
- disable SSH key validation in key details view. !28180 (Roger Meier)
- Fix MR discussion border missing in chrome sometimes. !28185
- Fix Error 500 when inviting user already present. !28198
- Remove non-semantic use of `.row` in member listing controls. !28204
- Properly handle LFS Batch API response in project import. !28223
- Fix project visibility level validation. !28305 (Peter Marko)
- Fix incorrect prefix used in new uploads for personal snippets. !28337
- Fix Rugged get_tree_entries recursive flag not working. !28494
- Next badge must visible when canary flag is true.
- Vertically aligns the play button for stages.
- Fixes next badge being always visible.
- Adds arrow icons to select option in CI/CD settings.
- Allow replying to individual notes from API.

### Changed (19 changes, 3 of them are from the community)

- Sort by due date and popularity in both directions for Issues and Merge requests. !25502 (Nermin Vehabovic)
- Improve pipelines table spacing, add triggerer column. !26136
- Allow extra arguments in helm commands when deploying the application in Auto-DevOps.gitlab-ci.yml. !26171 (tortuetorche)
- Switch to sassc-rails for faster stylesheet compilation. !26224
- Reorganize project merge request settings. !26834
- Display a toast message when the Kubernetes runner has successfully upgraded. !27206
- Allow guests users to access project releases. !27247
- Add help texts to K8 form fields. !27274
- Support prometheus for group level clusters. !27280
- Include link to raw job log in plain-text emails. !27409
- Only escape Markdown emphasis characters in autocomplete when necessary. !27457
- Move location of charts/auto-deploy-app -> gitlab-org/charts/auto-deploy-app. !27477
- Make canceled jobs not retryable. !27503
- Upgrade to Gitaly v1.36.0. !27831
- Update deployment event chat notification message. !27972
- Upgrade to Gitaly v1.42.0. !28135
- Resolve discussion when apply suggestion. !28160
- Improve expanding diff to full file performance.
- Knative version bump 0.3 -> 0.5. (Chris Baumbauer <cab@cabnetworks.net>)

### Performance (5 changes)

- Added list_pages method to avoid loading all wiki pages content. !22801
- Add gitaly session id & catfile-cache feature flag. !27472
- Add improvements to global search of issues and merge requests. !27817
- Disable method replacement in avatar loading. !27866
- Fix Blob.lazy always loading all previously-requested blobs when a new request is made.

### Added (36 changes, 10 of them are from the community)

- Add time preferences for user. !25381
- Added write_repository scope for personal access token. !26021 (Horatiu Eugen Vlad)
- Mark disabled pages domains for removal, but don't remove them yet. !26212
- Remove pages domains if they weren't verified for 1 week. !26227
- Expose pipeline variables via API. !26501 (Agustin Henze <tin@redhat.com>)
- Download a folder from repository. !26532 (kiameisomabes)
- Remove cleaned up OIDs from database and cache. !26555
- Disables kubernetes resources creation if a cluster is not managed. !26565
- Add CI_COMMIT_REF_PROTECTED CI variable. !26716 (Jason van den Hurk)
- Add new API endpoint to expose a single environment. !26887
- Allow Sentry configuration to be passed on gitlab.yml. !27091 (Roger Meier)
- CI variables of type file. !27112
- Allow linking to a private helm repository by providing credentials, and customisation of repository name. !27123 (Stuart Moore @stjm-cc)
- Add time tracking information to Issue Boards sidebar. !27166
- Play all manual jobs in a stage. !27188
- Instance level kubernetes clusters. !27196
- Adds if InfluxDB and Prometheus metrics are enabled to usage ping data. !27238
- Autosave description in epics. !27296
- Add deployment events to chat notification services. !27338
- Add packages_size to ProjectStatistics. !27373
- Added OmniAuth OpenID Connect strategy. !27383 (Horatiu Eugen Vlad)
- Test using Git 2.21. !27418
- Use official Gitea logo in importer. !27424 (Matti Ranta (@techknowlogick))
- Add option to set access_level of runners upon registration. !27490 (Zelin L)
- Add initial GraphQL query for Groups. !27492
- Enable Sidekiq Reliable Fetcher for background jobs by default. !27530
- Add backend support for a External Dashboard URL setting. !27550
- Implement UI for uninstalling Cluster’s managed apps. !27559
- Resolve Salesforce.com omniauth support. !27834
- Leave project/group from access granted email. !27892
- Allow Sentry client-side DSN to be passed on gitlab.yml. !27967
- GraphQL: improve evaluation of query complexity based on arguments and query limits. !28017
- Support negative matches.
- Added Omniauth UltraAuth strategy to GitLab. (Kartikey Tanna)
- Adds badge for Canary environment and help link.
- Show category icons in user popover.

### Other (29 changes, 8 of them are from the community)

- Validate refs used in controllers don't have spaces. !24037
- Migrate correlation and tracing code to LabKit. !25379
- Update node.js to 10.15.3 in CI template for Hexo. !25943 (Takuya Noguchi)
- Improve icons and button order in project overview. !26796
- Add instructions on how to contribute a Built-In template for project. !26976
- Extract DiscussionNotes component from NoteableDiscussion. !27066
- Bump gRPC to 1.19.0 and protobuf to 3.7.1. !27086
- Extract DiscussionActions component from NoteableDiscussion. !27227
- Show disabled project repo mirrors in settings. !27326
- Add backtrace to Gitaly performance bar. !27345
- Moved EE/CE differences for dropdown_value_collapsed into CE. !27367
- Remove "You are already signed in" banner. !27377
- Move ee-specific code from boards/components/issue_card_inner.vue. !27394 (Roman Rodionov)
- Upgrade to Rails 5.1. !27480 (Jasper Maes)
- Update GitLab Runner Helm Chart to 0.4.0. !27508
- Update GitLab Runner Helm Chart to 0.4.1. !27627
- Refactored notes tests from Karma to Jest. !27648 (Martin Hobert)
- refactor(issue): Refactored issue tests from Karma to Jest. !27673 (Martin Hobert)
- Refactored Karma spec files to Jest. !27688 (Martin Hobert)
- Add CSS fix for <wbr> elements on IE11. !27846
- Update clair-local-scan to v2.0.8 for container scanning. !27977
- Use PostgreSQL 10.7 in tests. !28020
- Document EE License Auto Import During Install. !28106
- Remove the note in the docs that multi-line suggestions are not yet available. !28119 (hardysim)
- Update gitlab-shell to v9.1.0. !28184
- Add EE fixtures to SeedFu list. !28241
- Add some frozen string to spec/**/*.rb. (gfyoung)
- Replaces CSS with BS4 utility class for pipeline schedules.
- Creates a vendors folder for external CSS.

### Performance (1 change)

- Add improvements to global search of issues and merge requests. !27817


## 11.10.7 (2019-06-26)

### Fixed (3 changes)

- Remove a default git depth in Pipelines for merge requests. !28926
- Fix label click scrolling to top. !29202
- Fix scrolling to top on assignee change. !29500


## 11.10.8 (2019-06-27)

- No changes.
### Security (10 changes)

- Fix Denial of Service for comments when rendering issues/MR comments.
- Gate MR head_pipeline behind read_pipeline ability.
- Fix DoS vulnerability in color validation regex.
- Expose merge requests count based on user access.
- Persist tmp snippet uploads at users.
- Add missing authorizations in GraphQL.
- Disable Rails SQL query cache when applying service templates.
- Prevent Billion Laughs attack.
- Correctly check permissions when creating snippet notes.
- Prevent the detection of merge request templates by unauthorized users.

### Performance (1 change)

- Add improvements to global search of issues and merge requests. !27817


## 11.10.6 (2019-06-04)

### Fixed (7 changes, 1 of them is from the community)

- Allow a member to have an access level equal to parent group. !27913
- Fix uploading of LFS tracked file through UI. !28052
- Use 3-way merge for squashing commits. !28078
- Use a path for the related merge requests endpoint. !28171
- Fix project visibility level validation. !28305 (Peter Marko)
- Fix Rugged get_tree_entries recursive flag not working. !28494
- Use source ref in pipeline webhook. !28772

### Other (1 change)

- Fix input group height.

## 11.10.4 (2019-05-01)

### Fixed (12 changes)

- Fix MR popover on ToDos page. !27382
- Fix 500 in general pipeline settings when passing an invalid build timeout. !27416
- Fix bug where system note MR has no popover. !27589
- Fix bug when project export to remote url fails. !27614
- `on_stop` is not automatically triggered with pipelines for merge requests. !27618
- Update Workhorse to v8.5.2. !27631
- Show proper wiki links in search results. !27634
- Make `CI_COMMIT_REF_NAME` and `SLUG` variable idempotent. !27663
- Fix Kubernetes service template deployment jobs broken as of 11.10.0. !27687
- Prevent text selection when dragging in issue boards. !27724
- Fix pipelines for merge requests does not show pipeline page when source branch is removed. !27803
- Fix Metrics Environments dropdown.

### Performance (2 changes)

- Prevent concurrent execution of PipelineScheduleWorker. !27781
- Fix slow performance with compiling HAML templates. !27782


## 11.10.3 (2019-04-30)

### Security (1 change)

- Allow to see project events only with api scope token.


## 11.10.2 (2019-04-25)

### Security (4 changes)

- Loosen regex for exception sanitization. !3076
- Resolve: moving an issue to private repo leaks namespace and project name.
- Escape path in new merge request mail.
- Stop sending emails to users who can't read commit.


## 11.10.1 (2019-04-23)

### Fixed (2 changes)

- Upgrade Gitaly to 1.34.0. !27494
- Fix filtering of labels from system note link. !27507

### Changed (1 change)

- Disable just-in-time Kubernetes resource creation for project level clusters. !27352

### Performance (1 change)

- Bring back Rugged implementation of ListCommitsByOid. !27441

### Other (1 change)

- Bump required Ruby version check to 2.5.3. !27495


## 11.10.0 (2019-04-22)

### Security (9 changes)

- Update Rails to 5.0.7.2. !27022
- Disallow guest users from accessing Releases.
- Return cached languages if they've been detected before.
- Added rake task for removing EXIF data from existing uploads.
- Disallow updating namespace when updating a project.
- Fix XSS in resolve conflicts form.
- Hide "related branches" when user does not have permission.
- Fix PDF.js vulnerability.
- Use UntrustedRegexp for matching refs policy.

### Fixed (81 changes, 21 of them are from the community)

- Update `border-radius` of form controls and remove extra space above page titles. !24497
- Disallow reopening of a locked merge request. !24882 (Jan Beckmann)
- Align EmailValidator to validate_email gem implementation. !24971 (Horatiu Eugen Vlad)
- add a uniq constraints on issues and mrs labels. !25435 (Antoine Huret)
- Display draft when toggling replies. !25563
- Fix markdown table header and table content borders. !25666
- Fix authorized application count. !25715 (moyuru)
- Added "Add List" checkbox to create label dropdown to make creation of list optional. !25716 (Tucker Chapman)
- Makes emoji picker full width on mobile. !25883 (Jacopo Beschi @jacopo-beschi)
- Don't cutoff letters in MR and Issue links. !25910 (gfyoung)
- Fix unwanted character replacement on project members page caused by usage of sanitize function. !25946 (Elias Werberich)
- Fix UI for closed MR when source project is removed. !25967 (Takuya Noguchi)
- Keep inline as much as possible in system notes on issuable. !25968 (Takuya Noguchi)
- Fixes long review app subdomains. !25990 (walkafwalka)
- Fix counting of groups in admin dashboard. !26009
- Disable inaccessible navigation links upon archiving a project. !26020 (Elias Werberich)
- Fixed - Create project label window is cut off at the bottom. !26049
- Fix error shown when loading links to specific comments. !26092
- Fix group transfer selection possibilities. !26123 (Peter Marko)
- Fix UI layout on Commits on mobile. !26133 (Takuya Noguchi)
- Fix continuous bitbucket import loading spinner. !26175
- Resolves Branch name is lost if I change commit mode in Web IDE. !26180
- Fix removing remote mirror failure which leaves unnecessary refs behind. !26213
- Fix Error 500 when user commits Wiki page with no commit message. !26247
- Handle missing keys in sentry api response. !26264
- Implemented whitespace-trimming for file names in Web IDE. !26270
- Fix misalignment of group overview page buttons. !26292
- Reject HEAD requests to info/refs endpoint. !26334
- Prevent namespace dropdown in new project form from exceeding container. !26343
- Fix hover animation consistency in top navbar items. !26345
- Exclude system notes from commits in merge request discussions. !26396
- Resolve Code in other column of side-by-side diff is highlighted when selecting code on one side. !26423
- Prevent fade out transition on loading-button component. !26428
- Fix merge commits being used as default squash commit messages. !26445
- Expand resolved discussion when linking to a comment in the discussion. !26483
- Show statistics also when repository is disabled. !26509 (Peter Marko)
- Fix multiple series queries on metrics dashboard. !26514
- Releases will now be automatically deleted when deleting corresponding tag. !26530
- Make stylistic improvements to diff nav header. !26557
- Clear pipeline status cache after destruction of pipeline. !26575
- Update fugit which fixes a potential infinite loop. !26579
- Fixes job link in artifacts page breadcrumb. !26592
- Fix quick actions add label name middle word overlaps. !26602 (Jacopo Beschi @jacopo-beschi)
- Fix Auto DevOps missing domain error handling. !26627
- Fix jupyter rendering bug that ended in an infinite loop. !26656 (ROSPARS Benoit)
- Use a fixed git abbrev parameter when we fetch a git revision. !26707
- Enabled text selection highlighting in diffs in Web IDE. !26721 (Isaac Smith)
- Remove `path` and `branch` labels from metrics. !26744
- Resolve "Hide Kubernetes cluster warning if project has cluster related". !26749
- Fix long label overflow on metrics dashboard. !26775
- Group transfer now properly redirects to edit on failure. !26837
- Only execute system hooks once when pushing tags. !26888
- Fix UI anchor links after docs refactor. !26890
- Fix MWPS does not work for merge request pipelines. !26906
- Create pipelines for merge requests only when source branch is updated. !26921
- Fix notfication emails having wrong encoding. !26931
- Allow task lists that follow a blockquote to work correctly. !26937
- Fix image diff swipe view on commit and compare pages. !26968 (ftab)
- Fix IDE detection of MR from fork with same branch name. !26986
- Fix single string values for the 'include' keyword validation of gitlab-ci.yml. !26998 (Paul Bonaud (@paulrbr))
- Do not display Ingress IP help text when there isn’t an Ingress IP assigned. !27057
- Fix real-time updates for projects that contain a reserved word. !27060
- Remove duplicates from issue related merge requests. !27067
- Add to white-space nowrap to all buttons. !27069
- Handle possible HTTP exception for Sentry client. !27080
- Guard against nil dereferenced_target. !27192
- Update GitLab Workhorse to v8.5.1. !27217
- Fix long file header names bug in diffs. !27233
- Always return the deployment in the UpdateDeploymentService#execute method. !27322
- Fix remove_source_branch merge request API handling. !27392
- Fixed bug with hashes in urls in WebIDE. !54376 (Kieran Andrews)
- Fix bug where MR popover doesn't go away on mouse leave.
- Only consider active milestones when using the special Started milestone filter.
- Scroll to diff file content when clicking on file header name and it is not a link to other page.
- Remove non-functional add issue button on welcome list.
- Fixed expand full file button showing on images.
- Fixed Web IDE web workers not working with relative URLs.
- Fixed Web IDE not loading merge request files.
- Fixed duplicated diff too large error message.
- Fixed sticky headers in merge request creation diffs.
- Fix bug when reopening milestone from index page.

### Deprecated (1 change)

- Allow to use untrusted Regexp via feature flag. !26905

### Changed (35 changes, 4 of them are from the community)

- Create MR pipelines with `refs/merge-requests/:iid/head`. !25504
- Create Kubernetes resources for projects when their deployment jobs run. !25586
- Remove unnecessary folder prefix from environment name. !25600
- Update deploy boards to additionally select on "app.gitlab.com" annotations. !25623
- Allow failed custom hook script errors to safely appear in GitLab UI by filtering error messages by the prefix GL-HOOK-ERR:. !25625
- Add link on two-factor authorization settings page to leave group that enforces two-factor authorization. !25731
- Reduce height of instance system header and footer. !25752
- Unify behaviour of 'Copy commit SHA to clipboard' to use full commit SHA. !25829 (Max Winterstein)
- Show loading spinner while Ingress/Knative IP is being assigned. !25912
- Hashed Storage: Prevent a migration and rollback running at the same time. !25976
- Make time counters show 'just now' for everything under one minute. !25992 (Sergiu Marton)
- Allow filtering labels list by one or two characters. !26012
- Implements the creation strategy for multi-line suggestions. !26057
- Automate base domain help text on Clusters page. !26124
- Set user.name limit to 128 characters. !26146
- Update gitlab-markup to 1.7.0 which requies python3. !26246
- Update system message banner font size to 12px. !26293
- Extend timezone dropdown. !26311
- Upgrade to Gitaly v1.29.0. !26406
- Automatically set Prometheus step interval. !26441
- Knative version bump 0.2.2 -> 0.3.0. !26459 (Chris Baumbauer)
- Display cluster form validation error messages inline. !26502
- Split Auto-DevOps.gitlab-ci.yml into reusable templates. !26520
- Update spinners in group list component. !26572
- Allow removing last owner from subgroup if parent group has owners. !26718
- Check mergeability in MergeToRefService. !26757
- Show download diff links for closed MRs. !26772
- Fix Container Scanning in Kubernetes Runners. !26793
- Move "Authorize project access with external service" to Core. !26823
- Localize notifications dropdown. !26844
- Order labels alphabetically in issue boards. !26927
- Upgrade to Gitaly v1.32.0. !26989
- Upgrade to Gitaly v1.33.0. !27065
- collapse file tree by default if the merge request changes only one file. (Riccardo Padovani <riccardo@rpadovani.com>)
- Removes the undescriptive CI Charts header.

### Performance (17 changes)

- Drop legacy artifacts usage as there are no leftovers. !24294
- Cache Repository#root_ref within a request. !25903
- Allow ref name caching CommitService#find_commit. !26248
- Avoid loading pipeline status in project search. !26342
- Fix some N+1s in loading routes and counting members for groups in @-autocomplete. !26491
- GitHub import: Run housekeeping after initial import. !26600
- Add initial complexity limits to GraphQL queries. !26629
- Cache FindCommit results in pipelines view. !26776
- Fix and expand Gitaly FindCommit caching. !27018
- Enable FindCommit caching for project and commits pages. !27048
- Expand FindCommit caching to blob and refs. !27084
- Enable Gitaly FindCommit caching for TreeController. !27100
- Improve performance of PR import. !27121
- Process at most 4 pipelines during push. !27205
- Disable method instrumentation for diffs. !27235
- Speed up filtering issues in a project when searching.
- Speed up generation of avatar URLs when using object storage.

### Added (35 changes, 6 of them are from the community)

- Add users search results to global search. !21197 (Alexis Reigel)
- Add target branch filter to merge requests search bar. !24380 (Hiroyuki Sato)
- Add Knative metrics to Prometheus. !24663 (Chris Baumbauer <cab@cabnetworks.net>)
- Support multi-line suggestions. !25211
- Allow to sort wiki pages by date and title. !25365
- Allow external diffs to be used conditionally. !25432
- Add usage counts for error tracking feature. !25472
- Enable/disable Auto DevOps at the Group level. !25533
- Update pipeline list view to accommodate post-merge pipeline information. !25690
- GraphQL Types can be made to always authorize access to resources of that Type. !25724
- Update clair-local-scan to 2.0.6. !25743 (Takuya Noguchi)
- Update pipeline block on merge request page to accommodate post-merge pipeline information. !25745
- Support multiple queries per chart on metrics dash. !25758
- Update pipeline detail view to accommodate post-merge pipelines. !25775
- Update job detail sidebar to accommodate post-merge pipeline information. !25777
- Add merge request pipeline flag to pipeline entity. !25846
- Expose group id on home panel. !25897 (Peter Marko)
- Move allow developers to create projects in groups to Core. !25975
- Add two new warning messages to the MR widget about merge request pipelines. !25983
- Support installing Group runner on group-level cluster. !26260
- Improve the Knative installation on Clusters. !26339
- Show error when namespace/svc account missing. !26362
- Add select by title to milestones API. !26573
- Implemented support for creation of new files from URL in Web IDE. !26622
- Add control for masking variable values in runner logs. !26751
- Allow merge requests to be created via git push options. !26752
- Create a shortcut for a new MR in the Web IDE. !26792
- Allow reactive caching to be used in services. !26839
- Add a Prometheus API per environment. !26841
- Allow merge requests to be set to merge when pipeline succeeds via git push options. !26842
- Use gitlabktl to build and deploy GitLab Serverless Functions. !26926
- Make touch events work on image diff swipe view and onion skin. !26971 (ftab)
- Add extended merge request tooltip.
- Added prometheus monitoring to GraphQL.
- Adding highest role property to admin's user details page.

### Other (29 changes, 6 of them are from the community)

- Update rack-oauth2 1.2.1 -> 1.9.3. !17868
- Merge the gitlab-shell "gitlab-keys" functionality into GitLab CE. !25598
- Refactor all_pipelines in Merge request. !25676
- Show error backtrace when logging errors to kubernetes.log. !25726
- Apply recaptcha API change in 4.0. !25921 (Praveen Arimbrathodiyil)
- Remove fake repository_path response. !25942 (Fabio Papa)
- Use curl silent/show-error options on Auto DevOps. !25954 (Takuya Noguchi)
- Explicitly set master_auth setting to enable basic auth and client certificate for new GKE clusters. !26018
- Project: Improve empty repository state UI. !26024
- Externalize strings from `/app/views/projects/pipelines`. !26035 (George Tsiolis)
- Prepare multi-line suggestions for rendering in Markdown. !26107
- Improve mobile UI on User Profile page. !26240 (Takuya Noguchi)
- Update GitLab Runner Helm Chart to 0.3.0/11.9.0. !26467
- Improve project merge request settings. !26495
- Bump kubectl to 1.11.9 and Helm to 2.13.1 in Auto-DevOps.gitlab-ci.yml. !26534
- Upgrade bootstrap_form Gem. !26568
- Add API access check to Graphql. !26570
- Change project avatar remove button to a link. !26589
- Log Gitaly RPC duration to api_json.log and production_json.log. !26652
- Add cluster domain to Project Cluster API. !26735
- Move project tags to separate line. !26797
- Changed button label at /pipelines/new. !26893 (antfobe,leonardofl)
- Update GitLab Shell to v9.0.0. !27002
- Migrate clusters tests to jest. !27013
- Rewrite related MRs widget with Vue. !27027
- Restore HipChat project service. !27172
- Externalize admin deploy keys strings.
- Removes EE differences for environments_table.vue.
- Removes EE differences for environment_item.vue.


## 11.9.12 (2019-05-30)

### Security (12 changes, 1 of them is from the community)

- Protect Gitlab::HTTP against DNS rebinding attack.
- Fix project visibility level validation. (Peter Marko)
- Update Knative version.
- Add DNS rebinding protection settings.
- Prevent XSS injection in note imports.
- Prevent invalid branch for merge request.
- Filter relative links in wiki for XSS.
- Fix confidential issue label disclosure on milestone view.
- Fix url redaction for issue links.
- Resolve: Milestones leaked via search API.
- Prevent bypass of restriction disabling web password sign in.
- Hide confidential issue title on unsubscribe for anonymous users.


## 11.9.10 (2019-04-26)

### Security (5 changes)

- Loosen regex for exception sanitization. !3077
- Resolve: moving an issue to private repo leaks namespace and project name.
- Escape path in new merge request mail.
- Stop sending emails to users who can't read commit.
- Upgrade Rails to 5.0.7.2.


## 11.9.9 (2019-04-23)

### Performance (1 change)

- Bring back Rugged implementation of ListCommitsByOid. !27441


## 11.9.8 (2019-04-11)

### Deprecated (1 change)

- Allow to use untrusted Regexp via feature flag. !26905

### Performance (2 changes)

- Improve performance of PR import. !27121
- Disable method instrumentation for diffs. !27235

### Other (1 change)

- Restore HipChat project service. !27172


## 11.9.7 (2019-04-09)

- No changes.

## 11.9.6 (2019-04-04)

### Fixed (3 changes)

- Force to recreate all MR diffs on import. !26480
- Fix API /project/:id/branches not returning correct merge status. !26785
- Avoid excessive recursive calls with Rugged TreeEntries. !26813

### Performance (1 change)

- Force a full GC after importing a project. !26803


## 11.9.5 (2019-04-03)

### Fixed (3 changes)

- Force to recreate all MR diffs on import. !26480
- Fix API /project/:id/branches not returning correct merge status. !26785
- Avoid excessive recursive calls with Rugged TreeEntries. !26813

### Performance (1 change)

- Force a full GC after importing a project. !26803


## 11.9.3 (2019-03-27)

- No changes.

## 11.9.2 (2019-03-26)

- No changes.

## 11.9.1 (2019-03-25)

### Fixed (7 changes)

- Fix issue that caused the "Show all activity" button to appear on top of the mini pipeline status dropdown on the merge request page. !26274
- Fix duplicated bottom match line on merge request parallel diff view. !26402
- Allow users who can push to protected branches to create protected branches via CLI. !26413
- Add missing .gitlab-ci.yml to Android template. !26415
- Refresh commit count after repository head changes. !26473
- Set proper default-branch for repository on GitHub Import. !26476
- GitHub importer: Use the project creator to create branches from forks. !26510

### Changed (1 change)

- Upgrade to Gitaly v1.27.1. !26533


## 11.9.0 (2019-03-22)

### Security (24 changes)

- Use encrypted runner tokens. !25532
- Stop linking to unrecognized package sources. !55518
- Disable issue boards API when issues are disabled.
- Forbid creating discussions for users with restricted access.
- Fix leaking private repository information in API.
- Fixed ability to see private groups by users not belonging to given group.
- Prevent releases links API to leak tag existence.
- Display the correct number of MRs a user has access to.
- Block local URLs for Kubernetes integration.
- Fix arbitrary file read via diffs during import.
- Check if desired milestone for an issue is available.
- Don't allow non-members to see private related MRs.
- Check snippet attached file to be moved is within designated directory.
- Fix blind SSRF in Prometheus integration by checking URL before querying.
- Fix git clone revealing private repo's presence.
- Remove project serialization in quick actions response.
- Don't show new issue link after move when a user does not have permissions.
- Limit mermaid rendering to 5K characters.
- Show only merge requests visible to user on milestone detail page.
- Display only information visible to current user on the Milestone page.
- Do not display impersonated sessions under active sessions and remove ability to revoke session.
- Validate session key when authorizing with GCP to create a cluster.
- Do not disclose milestone titles for unauthorized users.
- Remove the possibility to share a project with a group that a user is not a member of.

### Removed (1 change)

- Remove HipChat integration from GitLab. !22223

### Fixed (86 changes, 21 of them are from the community)

- Fixes issue with AWS V4 signatures not working with some S3 providers. !21788
- Validate 'include' keywords in gitlab-ci.yml configuration files. !24098 (Paul Bonaud)
- Close More Actions tooltip when menu opens. !24285
- API: Support Jira transition ID as string. !24400 (Robert Schilling)
- Fixed navigation sidebar flashing open on page load. !24555
- Fix username escaping when using assign to me for issues. !24673
- commit page info-well overflow fix #56436. !24799 (Gokhan Apaydin)
- Fix error tracking list page. !24806
- Fix overlapping empty-header logo. !24868 (Jonas L.)
- Resolve Jobs tab border top in pipeline's page is 1px off. !24878
- Require maintainer access to show pages domain settings. !24926
- Display error message when API call to list Sentry issues fails. !24936
- Fix rollout status for statefulsets and daemonsets. !24972 (Sergej Nikolaev <kinolaev@gmail.com>)
- Display job names consistently on pipelines and environments list. !24984
- Update new password breadcrumb. !25037 (George Tsiolis)
- Fixes functions finder for upgraded Knative app. !25067
- Provide expires_in in LFS authentication payload. !25082
- Fix validation of certain ed25519 keys. !25115 (Merlijn B. W. Wajer)
- Timer and action name aligned vertically for delayed jobs in pipeline actions. !25117 (Gokhan Apaydin)
- Fix the border style of CONTRIBUTING button when it exists. !25124 (Takuya Noguchi)
- Change badges.svg example to pipeline.svg. !25157 (Aviad Levy)
- API: Fix docs and parameters for hangouts-chat service. !25180 (Robert Schilling)
- API: Expose full commit title. !25189 (Robert Schilling)
- API: Require only one parameter when updating a wiki. !25191 (Robert Schilling)
- Hide pipeline status when pipelines are disabled on project. !25204
- Fix alignment of dropdown icon on issuable on mobile. !25205 (Takuya Noguchi)
- Add left margin to 1st time contributor badge. !25216 (Gokhan Apaydin)
- Use limited counter for runner build count in admin page. !25220
- API: Ensure that related merge requests are referenced cross-project. !25222 (Robert Schilling)
- Ensure the base pipeline of a Merge Request belongs to its target branch. !25226
- Fix import_jid error on project import. !25239
- Fix commenting on commits having SHA1 starting with a large number. !25278
- Allow empty values such as [] to be stored in reactive cache. !25283
- Remove vertical connecting line placeholder from diff discussion notes. !25292
- Fix hover and active state colors of award emoji button. !25295
- Fix author layouts in issuable meta line UIs on mobile. !25332 (Takuya Noguchi)
- Fix bug where project topics truncate. !25398
- Fix ETag caching not being used for AJAX requests. !25400
- Doc - fix the url of pipeline status badge. !25404 (Aviad Levy)
- Fix pipeline status icon mismatch. !25407
- Allow users to compare branches on a read-only instance. !25414
- Fix 404s when C++ .gitignore template selected. !25416
- Always fetch MR latest version when creating suggestions. !25441
- Only show borders for markdown images in notes. !25448
- Bring back Rugged implementation of find_commit. !25477
- Remove duplicate units from metrics graph. !25485
- Fix project import error importing releases. !25495
- Remove duplicate XHR request when requesting new pipeline page. !25506
- Properly handle multiple X-Forwarded-For addresses in runner IP. !25511
- Fix weekday shift in issue board cards for UTC+X timezones by removing local timezone to UTC conversion. !25512 (Elias Werberich)
- Fix large table horizontal scroll and prevent side-by-side tables. !25520 (Dany Jupille)
- Fix error when viewing group issue boards when user doesn't have explicit group permissions. !25524
- Respect the should_remove_source_branch parameter to the merge API. !25525
- Externalize markdown toolbar buttons tooltips. !25529
- Fix method to mark a project repository as writable. !25546
- fix group without owner after transfer. !25573 (Peter Marko)
- Fix pagination and duplicate requests in environments page. !25582
- Improve the JS pagination to handle the case when the `X-Total` and `X-Total-Pages` headers aren't present. !25601
- Add right padding to the repository mirror action buttons. !25606
- Use 'folder-open' from sprite icons for Browse Files button in Tag page. !25635
- Make merge to refs/merge-requests/:iid/merge not raise when FF-only enabled. !25653
- Fixed "Copying comment with ordered list includes extraneous newlines". !25695
- Fix bridge jobs only/except variables policy. !25710
- Allow GraphQL requests without CSRF token. !25719
- Skip Project validation during Hashed Storage migration or rollback. !25753
- Resolve showing squash commit edit issue when only single commit is present. !25807
- Fix the last-ditch memory killer pgroup SIGKILL. !25940
- Disable timeout on merge request merging poll. !25988
- Allow modifying squash commit message for fast-forward only merge method. !26017
- Fix bug in BitBucket imports with SHA shorter than 40 chars. !26050
- Fix health checks not working behind load balancers. !26055
- Fix 500 error caused by CODEOWNERS with no matches. !26072
- Fix notes being marked as edited after resolving. !26143
- Fix error creating a merge request when diff includes a null byte. !26190
- Fix undefined variable error on json project views. !26297
- GitHub import: Create new branches as project owner. !26335
- Gracefully handles excluded fields from attributes during serialization on JsonCache. !26368
- Admin section finds users case-insensitively.
- Fixes not working dropdowns in pipelines page.
- Do not show file templates when creating a new directory in WebIDE.
- Allow project members to see private group if the project is in the group namespace.
- Allow maintainers to remove pages.
- Fix inconsistent pagination styles.
- Fixed blob editor deleting file content for certain file paths.
- Fix upcoming milestone when there are milestones with far-future due dates.
- Fixed alignment of changed icon in Web IDE.

### Changed (31 changes, 10 of them are from the community)

- Improve snippets empty state. !18348 (George Tsiolis)
- Remove second primary button on wiki edit. !19959 (George Tsiolis)
- Allow raw `tls_options` to be passed in LDAP configuration. !20678
- Remove undigested token column from personal_access_tokens table from the database. !22743
- Update activity filter for issues. !23423 (George Tsiolis)
- Use auto-build-image for build job in Auto-DevOps.gitlab-ci.yml. !24279
- Error tracking configuration - add a Sentry project selection dropdown. !24701
- Move ChatOps to Core. !24780
- Implement new arguments `state`, `closed_before` and `closed_after` for `IssuesResolver` in GraphQL. !24910
- Validate kubernetes cluster CA certificate. !24990
- Review App Link to Changed Page if Only One Change Present. !25048
- Show pipeline ID, commit, and branch name on modal while stopping pipeline. !25059
- Improve empty state for starred projects. !25138
- Capture due date when importing milestones from Github. !25182 (dstanley)
- Add a spinner icon which is rendered using pure css. !25186
- Make emoji picker bigger. !25187 (Jacopo Beschi @jacopo-beschi)
- API: Sort tie breaker with id DESC. !25311 (Nermin Vehabovic)
- Add iOS-fastlane template for .gitlab-ci.yml. !25395
- Move language setting to preferences. !25427 (Fabian Schneider @fabsrc)
- Resolve Create Project Template for Netlify. !25453
- Sort labels alphabetically on issues and merge requests list. !25470
- Add Project template for .NET Core. !25486
- Update operations settings breadcrumb trail. !25539 (George Tsiolis)
- Add Project template for go-micro. !25553
- Jira: make issue links title compact. !25609 (Elan Ruusamäe @glensc)
- Project level filtering for JupyterHub. !25684 (Amit Rathi (amit1rrr))
- Clean up vendored templates. !25794
- Mask all TOKEN and PASSWORD CI variables. !25868
- Add project template for Android. !25870
- Add iOS project template. !25872
- Upgrade to Gitaly v1.26.0. !25890

### Performance (11 changes)

- Improve performance for diverging commit counts. !24287
- Optimize Redis usage in User::ActivityService. !25005
- Only load syntax highlight CSS of selected theme. !25232
- Improve label select rendering. !25281
- Enable persisted pipeline stages by default. !25347
- Speed up group issue search counts. !25411
- Load repository language from the database if detected before. !25518
- Remove N+1 query for tags in /admin/runners page. !25572
- Eliminate most N+1 queries loading UserController#calendar_activities. !25697
- Improve Web IDE launch performance. !25700
- Significantly reduce N+1 queries in /api/v4/todos endpoint. !25711

### Added (55 changes, 18 of them are from the community)

- Add a tag filter to the admin runners view. !19740 (Alexis Reigel)
- Add project fetch statistics. !23596 (Jacopo Beschi @jacopo-beschi)
- Hashed Storage rollback mechanism. !23955
- Allow to recursively expand includes. !24356
- Allow expanding a diff to display full file. !24406
- Support `only: changes:` on MR pipelines. !24490 (Hiroyuki Sato)
- Expose additional merge request pipeline variables. !24595 (Hiroyuki Sato)
- Add metadata about the GitLab server to GraphQL. !24636
- Support merge ref writing (without merging to target branch). !24692
- Add field mergeRequests for project in GraphQL. !24805
- API support for MR merge to temporary merge ref path. !24918
- Ability to filter confidential issues. !24960 (Robert Schilling)
- Allow creation of branches that match a wildcard protection, except directly through git. !24969
- Add related merge request count to api response. !24974
- Add realtime validation for user fullname and username on validation. !25017 (Ehsan Abdulqader @EhsanZ)
- Allow setting feature flags per GitLab group through the API. !25022
- Add API endpoint to get a commit's GPG signature. !25032
- Add support for FTP assets for releases. !25071 (Robert Schilling)
- Add Confirmation Modal to Rollback on Environment. !25110
- add title attribute to display file name. !25154 (Satoshi Nakamatsu @satoshicano)
- API: Expose text_color for project and group labels. !25172 (Robert Schilling)
- Added support for ingress hostnames. !25181 (walkafwalka)
- API: Promote project milestone to a group milestone. !25203 (Nermin Vehabovic)
- API: Expose if the current user can merge a MR. !25207 (Robert Schilling)
- add readme to changelogs directory. !25209 (@glensc)
- API: Indicate if label is a project label. !25219 (Robert Schilling)
- Expose refspecs and depth to runner. !25233
- Port System Header and Footer feature to Core. !25241
- Sort Environments by Last Updated. !25260
- Accept force option to overwrite branch on commit via API. !25286
- Add support for masking CI variables. !25293
- Add Link from Closed (moved) Issues to Moved Issue. !25300
- Next/previous navigation between files in MR review. !25355
- Add YouTrack integration service. !25361 (Yauhen Kotau @bessorion)
- Add ability to set path and name for project on fork using API. !25363
- Add project level config for merge pipelines. !25385
- Edit Knative domain after it has been deployed. !25386
- Add zoom and scroll to metrics dashboard. !25388
- Persist source sha and target sha for merge pipelines. !25417
- Add support for toggling discussion filter from notes section. !25426
- Resolve Move files in the Web IDE. !25431
- Show header and footer system messages in email. !25474
- Allow configuring POSTGRES_VERSION in Auto DevOps. !25500
- Add Saturday to Localization first day of the week. !25509 (Ahmad Haghighi)
- Extend the Gitlab API for deletion of job_artifacts of a single job. !25522 (rroger)
- Simplify CI/CD configuration on serverless projects. !25523
- Add button to start discussion from single comment. !25575
- sidekiq: terminate child processes at shutdown. !25669
- Expose merge request entity for pipelines. !25679
- Link to most recent MR from a branch. !25689
- Adds Auto DevOps build job for tags. !25718 (walkafwalka)
- Allow all snippets to be accessed by API. !25772
- Make file tree in merge requests resizable.
- Make the Web IDE the default editor.
- File uploads are deleted asynchronously when deleting a project or group.

### Other (28 changes, 6 of them are from the community)

- Improve GitHub and Gitea project import table UI. !24606
- Externalize strings from `/app/views/projects/commit`. !24668 (George Tsiolis)
- Correct non-standard unicode spaces to regular unicode. !24795 (Marcel Amirault)
- Provide a performance bar link to the Jaeger UI. !24902
- Remove BATCH_SIZE from WikiFileFinder. !24933
- Use export-import svgs from gitlab-svgs. !24954
- Fix N+1 query in Issues and MergeRequest API when issuable_metadata is present. !25042 (Alex Koval)
- Directly inheriting from ActiveRecord::Migration is deprecated. !25066 (Jasper Maes)
- Bump Helm and kubectl in Auto DevOps to 2.12.3 and 1.11.7 respectively. !25072
- Log queue duration in production_json.log. !25075
- Extracted ResolveWithIssueButton to its own component. !25093 (Martin Hobert)
- Add rectangular project and group avatars. !25098
- Include note in the Rails filter_parameters configuration. !25238
- Bump Helm and kubectl used in Kubernetes integration to 2.12.3 and 1.11.7 respectively. !25268
- Include gl_project_path in API /internal/allowed response. !25314
- Fix incorrect Pages Domains checkbox description. !25392 (Anton Melser)
- Update GitLab Runner Helm Chart to 0.2.0. !25493
- Add suffix (`_event`) to merge request source. !25508
- Creates a helper function to check if repo is EE. !25647
- If chpst is available, make fron-source installations run sidekiq as a process group leader. !25654
- Bring back Rugged implementation of GetTreeEntries. !25674
- Moves EE util into the CE file. !25680
- Bring back Rugged implementation of CommitIsAncestor. !25702
- Bring back Rugged implementation of TreeEntry. !25706
- Enable syntax highlighting to other supported markups. !25761
- Update GitLab Shell to v8.7.1. !25801
- Bring back Rugged implementation of commit_tree_entry. !25896
- Removes EE differences for jobs/getters.js.


## 11.8.10 (2019-04-30)

### Security (1 change)

- Allow to see project events only with api scope token.


## 11.8.8 (2019-04-23)

### Fixed (5 changes)

- Bring back Rugged implementation of find_commit. !25477
- Fix bug in BitBucket imports with SHA shorter than 40 chars. !26050
- Fix health checks not working behind load balancers. !26055
- Fix error creating a merge request when diff includes a null byte. !26190
- Avoid excessive recursive calls with Rugged TreeEntries. !26813

### Performance (1 change)

- Bring back Rugged implementation of ListCommitsByOid. !27441

### Other (4 changes)

- Bring back Rugged implementation of GetTreeEntries. !25674
- Bring back Rugged implementation of CommitIsAncestor. !25702
- Bring back Rugged implementation of TreeEntry. !25706
- Bring back Rugged implementation of commit_tree_entry. !25896


## 11.8.3 (2019-03-19)

### Security (1 change)

- Remove project serialization in quick actions response.


## 11.8.2 (2019-03-13)

### Security (1 change)

- Fixed ability to see private groups by users not belonging to given group.

### Fixed (5 changes)

- Fix import_jid error on project import. !25239
- Properly handle multiple X-Forwarded-For addresses in runner IP. !25511
- Fix error when viewing group issue boards when user doesn't have explicit group permissions. !25524
- Fix method to mark a project repository as writable. !25546
- Allow project members to see private group if the project is in the group namespace.


## 11.8.0 (2019-02-22)

### Security (7 changes, 1 of them is from the community)

- Sanitize user full name to clean up any URL to prevent mail clients from auto-linking URLs. !2793
- Update Helm to 2.12.2 to address Helm client vulnerability. !24418 (Takuya Noguchi)
- Use sanitized user status message for user popover.
- Validate bundle files before unpacking them.
- Alias GitHub and BitBucket OAuth2 callback URLs.
- Fixed XSS content in KaTex links.
- Disallows unauthorized users from accessing the pipelines section.

### Removed (2 changes, 1 of them is from the community)

- Removed deprecated Redcarpet markdown engine.
- Remove Cancel all jobs button in general jobs list view. (Jordi Llull)

### Fixed (84 changes, 20 of them are from the community)

- Fix ambiguous brackets in task lists. !18514 (Jared Deckard <jared.deckard@gmail.com>)
- Fix lost line number when navigating to a specific line in a protected file before authenticating. !19165 (Scott Escue)
- Fix suboptimal handling of checkbox and radio input events causing group general settings submit button to stay disabled after changing its visibility. !23022
- Fix upcoming milestones filter not including group milestones. !23098 (Heinrich Lee Yu)
- Update runner admin page to make description field larger. !23593 (Sascha Reynolds)
- Fix Bitbucket Server import not allowing personal projects. !23601
- Fix bug causing repository mirror settings UI to break. !23712
- Fix foreground color for labels to ensure consistency of label appearance. !23873 (Nathan Friend)
- Resolve In Merge Request diff screen, master is not a hyperlink. !23874
- Show the correct error page when access is denied. !23932
- Increase reliability and performance of toggling task items. !23938
- Modify file restore to rectify tar issue. !24000
- Fix default visibility_level for new projects. !24120 (Fabian Schneider @fabsrc)
- Footnotes now render properly in markdown. !24168
- Emoji and cancel button are taller than input in set user status modal. !24173 (Dhiraj Bodicherla)
- Adjusts duplicated line when commenting on unfolded diff lines (in the bottom). !24201
- Adjust height of "Add list" dropdown in issue boards. !24227
- Improves restriction of multiple Kubernetes clusters through API. !24251
- Fix files/blob api endpoints content disposition. !24267
- Cleanup stale +deleted repo paths on project removal (adjusts project removal bug). !24269
- Handle regular job dependencies next to parallelized job dependencies. !24273
- Proper align Projects dropdown on issue boards page. !24277 (Johann Hubert Sonntagbauer)
- Resolve When merging an MR, the squash checkbox isnt always supported. !24296
- Fix Bitbucket Server importer error handling. !24343
- Fix syntax highlighting for suggested changes preview. !24358
- API: Support dots in wiki slugs. !24383 (Robert Schilling)
- Show CI artifact file size with 3 significant digits on 'browse job artifacts' page. !24387
- API: Support username with dots. !24395 (Robert Schilling)
- API: Fix default_branch_protection admin setting. !24398 (Robert Schilling)
- Remove unwanted margin above suggested changes. !24419
- Prevent checking protected_ref? for ambiguous refs. !24437
- Update metrics environment dropdown to show complete option set. !24441
- Fix empty labels of CI builds for gitlab-pages on pipeline page. !24451
- Do not run spam checks on confidential issues. !24453
- Upgrade KaTeX to version 0.10.0. !24478 (Andrew Harmon)
- Avoid overwriting default jaeger values with nil. !24482
- Display SAML failure messages instead of expecting CSRF token. !24509
- Adjust vertical alignment for project visibility icons. !24511 (Martin Hobert)
- Load initUserInternalRegexPlaceholder only when required. !24522
- Hashed Storage: `AfterRenameService` was receiving the wrong `old_path` under some circumstances. !24526
- Resolve Runners IPv6 address overlaps other values. !24531
- Fix 404s with snippet uploads in object storage. !24550
- Fixed oversized custom project notification selector dropdown. !24557
- Allow users with full private access to read private personal snippets. !24560
- Resolve Pipeline stages job action button icon is not aligned. !24577
- Fix cluster page non-interactive on form validation error. !24583
- Fix 404s for snippet uploads when relative URL root used. !24588
- Fix markdown table border. !24601
- Fix CSS grid on a new Project/Group Milestone. !24614 (Takuya Noguchi)
- Prevent unload when Recaptcha is open. !24625
- Clean up unicorn sampler metric labels. !24626 (bjk-gitlab)
- Support bamboo api polymorphism. !24680 (Alex Lossent)
- Ensure Cert Manager works with Auto DevOps URLs greater than 64 bytes. !24683
- Fix failed LDAP logins when nil user_id present. !24749
- fix display comment avatars issue in IE 11. !24777 (Gokhan Apaydin)
- Fix template labels not being created on new projects. !24803
- Fix cluster installation processing spinner. !24814
- Append prioritized label before pagination. !24815
- Resolve UI bug adding group members with lower permissions. !24820
- Make `ActionController::Parameters` serializable for sidekiq jobs. !24864
- Fix Jira Service password validation on project integration services. !24896 (Daniel Juarez)
- Fix potential Addressable::URI::InvalidURIError. !24908
- Update Workhorse to v8.2.0. !24909
- Encode Content-Disposition filenames. !24919
- Avoid race conditions when creating GpgSignature. !24939
- Create the source branch for a GitHub import. !25064
- Fix suggested changes syntax highlighting. !25116
- Fix counts in milestones dashboard. !25230
- Fixes incorrect TLD validation errors for Kubernetes cluster domain. !25262
- Fix 403 errors when adding an assignee list in project boards. !25263
- Prevent Auto DevOps from trying to deploy without a domain name. !25308
- Fix uninitialized constant with GitLab Pages.
- Increase line height of project summaries. (gfyoung)
- Remove extra space between MR tab bar and sticky file headers.
- Correct spacing for comparison page.
- Update CI YAML param table with include.
- Return bottom border on MR Tabs.
- Fixes z-index and margins of archived alert in job page.
- Fixes archived sticky top bar without performance bar.
- Fixed rebase button not showing in merge request widget.
- Fixed double tooltips on note awards buttons.
- Allow suggestions to be copied and pasted as GFM.
- Fix bug that caused Suggestion Markdown toolbar button to insert snippet with leading +/-/<space>.
- Moved primary button for labels to follow the design patterns used on rest of the site. (Martin Hobert)

### Changed (37 changes, 11 of them are from the community)

- Change spawning of tooltips to be top by default. !21223
- Standardize filter value capitlization in filter bar in both issues and boards pages. !23846 (obahareth)
- Refresh group overview to match project overview. !23866
- Build number does not need to be tweaked anymore for the TeamCity integration to work properly. !23898
- Added empty project illustration and updated text to user profile overview. !23973 (Fernando Arias)
- Modified Knative list view to provide more details. !24072 (Chris Baumbauer)
- Move cancel & new issue button on job page. !24074
- Make issuable empty states actionable. !24077
- Fix code search when text is larger than max gRPC message size. !24111
- Update string structure for available group runners. !24187 (George Tsiolis)
- Remove multilingual translation from the word "in" in the job details sidebar. !24192 (Nathan Friend)
- Fix duplicate project disk path in BackfillLegacyProjectRepositories. !24213
- Ensured links to a comment or system note anchor resolves to the right note if a user has a discussion filter. !24228
- Remove expansion hover animation from pipeline status icon buttons. !24268 (Nathan Friend)
- Redesigned related merge requests in issue page. !24270
- Return the maximum group access level in the projects API. !24403
- Update project topics styling to use badges design. !24415
- Display "commented" only for commit discussions on merge requests. !24427
- Upgrade js-regex gem to version 3.1. !24433 (rroger)
- Prevent Sidekiq arguments over 10 KB in size from being logged to JSON. !24493
- Added Avatar in the settings sidebar. !24515 (Yoginth)
- Refresh empty states for profile page tabs. !24549
- remove red/green colors from diff view of no-color syntax theme. !24582 (khm)
- Get remote IP address of runner. !24624
- Update last_activity_on for Users on some main GET endpoints. !24642
- Update metrics dashboard graph design. !24653
- Update to GitLab SVG icon from Font Awesome in profile for location and work. !24671 (Yoginth)
- Add template for Android with Fastlane. !24722
- Display timestamps to messages printed by gitlab:backup:restore rake tasks. (Will Chandler)
- Show MR statistics in diff comparisons.
- Make possible to toggle file tree while scrolling through diffs.
- Use delete instead of remove when referring to `git branch -D`.
- Add folder header to files in merge request tree list.
- Added fuzzy file finder to merge requests.
- Collapse directory structure in merge request file tree.
- Adds skeleton loading to releases page.
- Support multiple outputs in jupyter notebooks.

### Performance (8 changes, 1 of them is from the community)

- Remove unused button classes `btn-create` and `comment-btn`. !23232 (George Tsiolis)
- [API] Omit `X-Total` and `X-Total-Pages` headers when items count is more than 10,000. !23931
- Improve efficiency of GitHub importer by reducing amount of locks needed. !24102
- Improve milestone queries using subqueries instead of separate queries for ids. !24325
- Efficiently remove expired artifacts in `ExpireBuildArtifactsWorker`. !24450
- Eliminate N+1 queries in /api/groups/:id. !24513
- Use deployment relation to get an environment name. !24890
- Do not reload daemon if configuration file of pages does not change.

### Added (35 changes, 18 of them are from the community)

- Add badge count to projects. !18425 (George Tsiolis)
- API: Add support for group labels. !21368 (Robert Schilling)
- Add setting for first day of the week. !22755 (Fabian Schneider @fabsrc)
- Pages for subgroups. !23505
- Add support for customer provided encryption keys for Amazon S3 remote backups. !23797 (Pepijn Van Eeckhoudt)
- Add Knative detailed view. !23863 (Chris Baumbauer)
- Add group full path to project's shared_with_groups. !24052 (Mathieu Parent)
- Added feature to specify a custom Auto DevOps chart repository. !24162 (walkafwalka)
- Add flat-square badge style. !24172 (Fabian Schneider @fabsrc)
- Display last activity and created at datetimes for users. !24181
- Allow setting of feature gates per project. !24184
- Save issues/merge request sorting options to backend. !24198
- Added support for custom hosts/domains to Auto DevOps. !24248 (walkafwalka)
- Adds milestone search. !24265 (Jacopo Beschi @jacopo-beschi)
- Allow merge request diffs to be placed into an object store. !24276
- Add Container Registry API with cleanup function. !24303
- GitLab now supports the profile and email scopes from OpenID Connect. !24335 (Goten Xiao)
- Add 'in' filter that modifies scope of 'search' filter to issues and merge requests API. !24350 (Hiroyuki Sato)
- Add `with_programming_language` filter for projects to API. !24377 (Dylan MacKenzie)
- API: Support searching for tags. !24385 (Robert Schilling)
- Document graphicsmagick installation for source installation. !24404 (Alexis Reigel)
- Redirect GET projects/:id to project page. !24467
- Indicate on Issue Status if an Issue was Moved. !24470
- Redeploy Auto DevOps deployment on variable updates. !24498 (walkafwalka)
- Don't create new merge request pipeline without commits. !24503 (Hiroyuki Sato)
- Add GitLab Pages predefined CI variables 'CI_PAGES_DOMAIN' and 'CI_PAGES_URL'. !24504 (Adrian Moisey)
- Moves domain setting from Auto DevOps to Cluster's page. !24580
- API allows setting the squash commit message when squashing a merge request. !24784
- Added ability to upgrade cluster applications. !24789
- Add argument iids for issues in GraphQL. !24802
- Add repositories count to usage ping data. !24823
- Add support for extensionless pages URLs. !24876
- Add templates for most popular Pages templates. !24906
- Introduce Internal API for searching environment names. !24923
- Allow admins to invalidate markdown texts by setting local markdown version.

### Other (50 changes, 18 of them are from the community)

- Externalize strings from `/app/views/projects/project_members`. !23227 (Tao Wang)
- Add CSS & JS global flags to represent browser and platform. !24017
- Fix deprecation: Passing an argument to force an association to reload is now deprecated. !24136 (Jasper Maes)
- Cleanup legacy artifact background migration. !24144
- Bump kubectl in Auto DevOps to 1.11.6. !24176
- Conditionally initialize the global opentracing tracer. !24186
- Remove horizontal whitespace on user profile overview on small breakpoints. !24189
- Bump nginx-ingress chart to 1.1.2. !24203
- Use monospace font for registry table tag id and tag name. !24205
- Rename project tags to project topics. !24219
- Add uniqueness validation to url column in Releases::Link model. !24223
- Update sidekiq-cron to 1.0.4 and use fugit to replace rufus-scheduler to parse cron syntax. !24235
- Adds inter-service OpenTracing propagation. !24239
- Fixes Auto DevOps title on CI/CD admin settings. !24249
- Upgrade kubeclient to 4.2.2 and swap out monkey-patch to disallow redirects. !24284
- i18n: externalize strings from 'app/views/search'. !24297 (Tao Wang)
- Fix several ActionController::Parameters deprecations. !24332 (Jasper Maes)
- Remove all `$theme-gray-{weight}` variables in favor of `$gray-{weight}`. !24333 (George Tsiolis)
- Update gitlab-styles to 2.5.1. !24336 (Jasper Maes)
- Modifies environment scope UI on cluster page. !24376
- Extract process_name from GitLab::Sentry. !24422
- Upgrade Gitaly to 1.13.0. !24429
- Actually set raise_on_unfiltered_parameters to true. !24443 (Jasper Maes)
- Refactored NoteableDiscussion by extracting ResolveDiscussionButton. !24505 (Martin Hobert)
- Extracted JumpToNextDiscussionButton to its own component. !24506 (Martin Hobert)
- Extracted ReplyPlaceholder to its own component. !24507 (Martin Hobert)
- Block emojis and symbol characters from users full names. !24523
- Update GitLab Runner Helm Chart to 0.1.45. !24564
- Updated docs for fields in pushing mirror from GitLab to GitHub. !24566 (Joseph Yu)
- Upgrade gitlab-workhorse to 8.1.0. !24571
- Externalize strings from `/app/views/sent_notifications`. !24576 (George Tsiolis)
- Adds tracing support for ActiveRecord notifications. !24604
- Externalize strings from `/app/views/projects/ci`. !24617 (George Tsiolis)
- Move permission check of manual actions of deployments. !24660
- Externalize strings from `/app/views/clusters`. !24666 (George Tsiolis)
- Update UI for admin appearance settings. !24685
- Externalize strings from `/app/views/projects/pages_domains`. !24723 (George Tsiolis)
- Externalize strings from `/app/views/projects/milestones`. !24726 (George Tsiolis)
- Add OpenTracing instrumentation for Action View Render events. !24728
- Expose version for each application in cluster_status JSON endpoint. !24791
- Externalize strings from `/app/views/instance_statistics`. !24809 (George Tsiolis)
- Update cluster application version on updated and installed status. !24810
- Project list UI improvements. !24855
- Externalize strings from `/app/views/email_rejection_mailer`. !24869 (George Tsiolis)
- Update Gitaly to v1.17.0. !24873
- Update Workhorse to v8.3.0. !24959
- Upgrade gitaly to 1.18.0. !24981
- Update Workhorse to v8.3.1.
- Upgraded Codesandbox smooshpack package.
- Creates mixin to reduce code duplication between CE and EE in graph component.


## 11.7.12 (2019-04-23)

### Fixed (2 changes)

- Bring back Rugged implementation of find_commit. !25477
- Avoid excessive recursive calls with Rugged TreeEntries. !26813

### Performance (1 change)

- Bring back Rugged implementation of ListCommitsByOid. !27441

### Other (4 changes)

- Bring back Rugged implementation of GetTreeEntries. !25674
- Bring back Rugged implementation of CommitIsAncestor. !25702
- Bring back Rugged implementation of TreeEntry. !25706
- Bring back Rugged implementation of commit_tree_entry. !25896


## 11.7.11 (2019-04-09)

- No changes.

## 11.7.10 (2019-03-28)

### Security (7 changes)

- Disallow guest users from accessing Releases.
- Fix PDF.js vulnerability.
- Hide "related branches" when user does not have permission.
- Fix XSS in resolve conflicts form.
- Added rake task for removing EXIF data from existing uploads.
- Disallow updating namespace when updating a project.
- Use UntrustedRegexp for matching refs policy.


## 11.7.8 (2019-03-26)

- No changes.

## 11.7.7 (2019-03-19)

### Security (2 changes)

- Remove project serialization in quick actions response.
- Fixed ability to see private groups by users not belonging to given group.


## 11.7.5 (2019-02-05)

### Fixed (8 changes)

- Fix import handling errors in Bitbucket Server importer. !24499
- Adjusts suggestions unable to be applied. !24603
- Fix 500 errors with legacy appearance logos. !24615
- Fix form functionality for edit tag page. !24645
- Update Workhorse to v8.0.2. !24870
- Downcase aliased OAuth2 callback providers. !24877
- Fix Detect Host Keys not working. !24884
- Changed external wiki query method to prevent attribute caching. !24907


## 11.7.2 (2019-01-29)

### Fixed (1 change)

- Fix uninitialized constant with GitLab Pages.


## 11.7.1 (2019-01-28)

### Security (24 changes)

- Make potentially malicious links more visible in the UI and scrub RTLO chars from links. !2770
- Don't process MR refs for guests in the notes. !2771
- Sanitize user full name to clean up any URL to prevent mail clients from auto-linking URLs. !2828
- Fixed XSS content in KaTex links.
- Disallows unauthorized users from accessing the pipelines section.
- Verify that LFS upload requests are genuine.
- Extract GitLab Pages using RubyZip.
- Prevent awarding emojis to notes whose parent is not visible to user.
- Prevent unauthorized replies when discussion is locked or confidential.
- Disable git v2 protocol temporarily.
- Fix showing ci status for guest users when public pipline are not set.
- Fix contributed projects info still visible when user enable private profile.
- Add subresources removal to member destroy service.
- Add more LFS validations to prevent forgery.
- Use common error for unauthenticated users when creating issues.
- Fix slow regex in project reference pattern.
- Fix private user email being visible in push (and tag push) webhooks.
- Fix wiki access rights when external wiki is enabled.
- Group guests are no longer able to see merge requests they don't have access to at group level.
- Fix path disclosure on project import error.
- Restrict project import visibility based on its group.
- Expose CI/CD trigger token only to the trigger owner.
- Notify only users who can access the project on project move.
- Alias GitHub and BitBucket OAuth2 callback URLs.


## 11.7.0 (2019-01-22)

### Security (14 changes, 1 of them is from the community)

- Escape label and milestone titles to prevent XSS in GFM autocomplete. !2693
- Bump Ruby on Rails to 5.0.7.1. !23396 (@blackst0ne)
- Delete confidential todos for user when downgraded to Guest.
- Project guests no longer are able to see refs page.
- Set URL rel attribute for broken URLs.
- Prevent leaking protected variables for ambiguous refs.
- Authorize before reading job information via API.
- Allow changing group CI/CD settings only for owners.
- Fix SSRF with import_url and remote mirror url.
- Don't expose cross project repositories through diffs when creating merge reqeusts.
- Validate bundle files before unpacking them.
- Issuable no longer is visible to users when project can't be viewed.
- Escape html entities in LabelReferenceFilter when no label found.
- Prevent private snippets from being embeddable.

### Removed (3 changes, 1 of them is from the community)

- Removes all instances of deprecated Gitlab Upgrader calls. !23603 (@jwolen)
- Removed discard draft comment button form notes. !24185
- Remove migration to backfill project_repositories for legacy storage projects. !24299

### Fixed (42 changes, 7 of them are from the community)

- Prevent awards emoji being updated when updating status. !23470
- Allow merge after rebase without page refresh on FF repositories. !23572
- Prevent admins from attempting hashed storage migration on read only DB. !23597
- Correct the ordering of metrics on the performance dashboard. !23630
- Display empty files properly on MR diffs. !23671 (Sean Nichols)
- Allow GitHub imports via token even if OAuth2 provider not configured. !23703
- Update header navigation theme colors. !23734 (George Tsiolis)
- Fix login box bottom margins on signin page. !23739 (@gear54)
- Return an ApplicationSetting in CurrentSettings. !23766
- Fix bug commenting on LFS images. !23812
- Only prompt user once when navigating away from file editor. !23820 (Sam Bigelow)
- Display commit ID for discussions made on merge request commits. !23837
- Stop autofocusing on diff comment after initial mount. !23849
- Fix object storage not working properly with Google S3 compatibility. !23858
- Fix project calendar feed when sorted by priority. !23870
- Fix edit button disappearing in issue title. !23948 (Ruben Moya)
- Aligns build loader animation with the job log. !23959
- Allow 'rake gitlab:cleanup:remote_upload_files' to read bucket files without having permissions to see all buckets. !23981
- Correctly externalize pipeline tags. !24028
- Fix error when creating labels in a new issue in the boards page. !24039 (Ruben Moya)
- Use 'parsePikadayDate' to parse due date string. !24045
- Fix commit SHA not showing in merge request compare dropdown. !24084
- Remove top margin in modal header titles. !24108
- Drop Webhooks from project import/export config. !24121
- Only validate project visibility when it has changed. !24142
- Resolve About this feature link should open in new window. !24149
- Add syntax highlighting to suggestion diff. !24156
- Fix Bitbucket Server import only including first 25 pull requests. !24178
- Enable caching for records which primary key is not `id`. !24245
- Adjust applied suggestion reverting previous changes. !24250
- Fix unexpected exception by failure of finding an actual head pipeline. !24257
- Fix broken templated "Too many changes to show" text. !24282
- Fix requests profiler in admin page not rendering HTML properly. !24291
- Fix no avatar not showing in user selection box. !24346
- Upgrade to gitaly 1.12.1. !24361
- Fix runner eternal loop when update job result. !24481
- Fix notification email for image diff notes.
- Fixed merge request diffs empty states.
- Fixed diff suggestions removing dashes.
- Don't hide CI dropdown behind diff summary. (gfyoung)
- Fix spacing on discussions.
- Fixes missing margin in releases block.

### Changed (22 changes, 8 of them are from the community)

- Show clusters of ancestors in cluster list page. !22996
- Remove unnecessary line before reply holder. !23092 (George Tsiolis)
- Make the Pages permission setting more clear. !23146
- Disable merging of labels with same names. !23265
- Allow basic authentication on go get middleware. !23497 (Morty Choi @mortyccp)
- No longer require email subaddressing for issue creation by email. !23523
- Adjust padding of .dropdown-title to comply with design specs. !23546
- Make commit IDs in merge request discussion header monospace. !23562
- Update environments breadcrumb. !23751 (George Tsiolis)
- Add date range in milestone change email notifications. !23762
- Require Knative to be installed only on an RBAC kubernetes cluster. !23807 (Chris Baumbauer)
- Fix label and header styles in the job details sidebar. !23816 (Nathan Friend)
- Add % prefix to milestone reference links. !23928
- Reorder sidebar menu item for group clusters. !24001 (George Tsiolis)
- Support CURD operation for Links as one of the Release assets. !24056
- Upgrade Omniauth and JWT gems to switch away from Google+ API. !24068
- Renames Milestone sort into Milestone due date. !24080 (Jacopo Beschi @jacopo-beschi)
- Discussion filter only displayed in discussions tab for merge requests. !24082
- Make RBAC enabled default for new clusters. !24119
- Hashed Storage: Only set as `read_only` when starting the per-project migration. !24128
- Knative version bump 0.1.3 -> 0.2.2. (Chris Baumbauer)
- Show message on non-diff discussions.

### Performance (7 changes)

- Fix some N+1 queries related to Admin Dashboard, User Dashboards and Activity Stream. !23034
- Add indexes to speed up CI query. !23188
- Improve the loading time on merge request's discussion page by caching diff highlight. !23857
- Cache avatar URLs and paths within a request. !23950
- Improve snippet search performance by removing duplicate counts. !23952
- Skip per-commit validations already evaluated. !23984
- Fix timeout issues retrieving branches via API. !24034

### Added (29 changes, 6 of them are from the community)

- Handle ci.skip push option. !15643 (Jonathon Reinhart)
- Add NGINX 0.16.0 and above metrics. !22133
- Add project milestone link. !22552
- Support tls communication in gitaly. !22602
- Add option to make ci variables protected by default. !22744 (Alexis Reigel)
- Add project identifier as List-Id email Header to ease filtering. !22817 (Olivier Crête)
- Add markdown helper buttons to file editor. !23480
- Allow to include templates in gitlab-ci.yml. !23495
- Extend override check to also check arity. !23498 (Jacopo Beschi @jacopo-beschi)
- Add importing of issues from CSV file. !23532
- Add submit feedback link to help dropdown. !23547
- Send a notification email to project maintainers when a mirror update fails. !23595
- Restore Object Pools when restoring an object pool. !23682
- Creates component for release block. !23697
- Configure Auto DevOps deployed applications with secrets from prefixed CI variables. !23719
- Add name, author_id, and sha to releases table. !23763
- Display a list of Sentry Issues in GitLab. !23770
- Releases API. !23795
- Creates frontend app for releases. !23796
- Add new pipeline variable CI_COMMIT_SHORT_SHA. !23822
- Create system notes on issue / MR creation when labels, milestone, or due date is set. !23859
- Adds API documentation for releases. !23901
- Add API Support for Kubernetes integration. !23922
- Expose CI/CD predefined variable `CI_API_V4_URL`. !23936
- Add Knative metrics to Prometheus. !23972 (Chris Baumbauer)
- Use reports syntax for Dependency scanning in Auto DevOps. !24081
- Allow to include files from another projects in gitlab-ci.yml. !24101
- User Popovers for Commit Infos, Member Lists and Snippets. !24132
- Add no-color theme for syntax highlighting. (khm)

### Other (45 changes, 30 of them are from the community)

- Redesign project lists UI. !22682
- [Rails5.1] Update functional specs to use new keyword format. !23095 (@blackst0ne)
- Update a condition to visibility a merge request collaboration message. !23104 (Harry Kiselev)
- Remove framework/mobile.scss. !23301 (Takuya Noguchi)
- Passing the separator argument as a positional parameter is deprecated. !23334 (Jasper Maes)
- Clarifies docs about CI `allow_failure`. !23367 (C.J. Jameson)
- Refactor issuable sidebar to use serializer. !23379
- Refactor the logic of updating head pipelines for merge requests. !23502
- Allow user to add Kubernetes cluster for clusterable when there are ancestor clusters. !23569
- Adds explanatory text to input fields on user profile settings page. !23673
- Externalize strings from `/app/views/shared/notes`. !23696 (Tao Wang)
- Remove rails 4 support in CI, Gemfiles, bin/ and config/. !23717 (Jasper Maes)
- Fix calendar events fetching error on private profile page. !23718 (Harry Kiselev)
- Update GitLab Workhorse to v8.0.0. !23740
- Hide confidential events in the API. !23746
- Changed Userpopover Fixtures and shadow color. !23768
- Fix deprecation: Passing conditions to delete_all is deprecated. !23817 (Jasper Maes)
- Fix deprecation: Passing ActiveRecord::Base objects to sanitize_sql_hash_for_assignment. !23818 (Jasper Maes)
- Remove rails4 specific code. !23847 (Jasper Maes)
- Remove deprecated ActionDispatch::ParamsParser. !23848 (Jasper Maes)
- Fix deprecation: Comparing equality between ActionController::Parameters and a Hash is deprecated. !23855 (Jasper Maes)
- Fix deprecation: Directly inheriting from ActiveRecord::Migration is deprecated. !23884 (Jasper Maes)
- Fix deprecation: alias_method_chain is deprecated. Please, use Module#prepend instead. !23887 (Jasper Maes)
- Update specs to exclude possible false positive pass. !23893 (@blackst0ne)
- Passing an argument to force an association to reload is now deprecated. !23894 (Jasper Maes)
- ActiveRecord::Migration -> ActiveRecord::Migration[5.0]. !23910 (Jasper Maes)
- Split bio into individual line in extended user tooltips. !23940
- Fix deprecation: redirect_to :back is deprecated. !23943 (Jasper Maes)
- Fix deprecation: insert_sql is deprecated and will be removed. !23944 (Jasper Maes)
- Upgrade @gitlab/ui to 1.16.2. !23946
- convert specs in javascripts/ and support/ to new syntax. !23947 (Jasper Maes)
- Remove deprecated xhr from specs. !23949 (Jasper Maes)
- Remove app/views/shared/issuable/_filter.html.haml. !24008 (Takuya Noguchi)
- Fix deprecation: Using positional arguments in integration tests. !24009 (Jasper Maes)
- UI improvements for redesigned project lists. !24011
- Update cert-manager chart from v0.5.0 to v0.5.2. !24025 (Takuya Noguchi)
- Hide spinner on empty activities list on user profile overview. !24063
- Don't show Auto DevOps enabled banner for projects with CI file or CI disabled. !24067
- Update GitLab Runner Helm Chart to 0.1.43. !24083
- Fix navigation style in docs. !24090 (Takuya Noguchi)
- Remove gem install bundler from Docker-based Ruby environments. !24093 (Takuya Noguchi)
- Fix deprecation: Using positional arguments in integration tests. !24110 (Jasper Maes)
- Fix deprecation: returning false in Active Record and Active Model callbacks will not implicitly halt a callback chain. !24134 (Jasper Maes)
- ActiveRecord::Migration -> ActiveRecord::Migration[5.0] for AddIndexesToCiBuildsAndPipelines. !24167 (Jasper Maes)
- Update url placeholder for the sentry configuration page. !24338


## 11.6.11 (2019-04-23)

### Security (1 change)

- Fixed ability to see private groups by users not belonging to given group.

### Fixed (2 changes)

- Bring back Rugged implementation of find_commit. !25477
- Avoid excessive recursive calls with Rugged TreeEntries. !26813

### Performance (1 change)

- Bring back Rugged implementation of ListCommitsByOid. !27441

### Other (4 changes)

- Bring back Rugged implementation of GetTreeEntries. !25674
- Bring back Rugged implementation of CommitIsAncestor. !25702
- Bring back Rugged implementation of TreeEntry. !25706
- Bring back Rugged implementation of commit_tree_entry. !25896


## 11.6.10 (2019-02-28)

### Security (21 changes)

- Stop linking to unrecognized package sources. !55518
- Check snippet attached file to be moved is within designated directory.
- Fix potential Addressable::URI::InvalidURIError.
- Do not display impersonated sessions under active sessions and remove ability to revoke session.
- Display only information visible to current user on the Milestone page.
- Show only merge requests visible to user on milestone detail page.
- Disable issue boards API when issues are disabled.
- Don't show new issue link after move when a user does not have permissions.
- Fix git clone revealing private repo's presence.
- Fix blind SSRF in Prometheus integration by checking URL before querying.
- Check if desired milestone for an issue is available.
- Don't allow non-members to see private related MRs.
- Fix arbitrary file read via diffs during import.
- Display the correct number of MRs a user has access to.
- Forbid creating discussions for users with restricted access.
- Do not disclose milestone titles for unauthorized users.
- Validate session key when authorizing with GCP to create a cluster.
- Block local URLs for Kubernetes integration.
- Limit mermaid rendering to 5K characters.
- Remove the possibility to share a project with a group that a user is not a member of.
- Fix leaking private repository information in API.


## 11.6.9 (2019-02-04)

### Security (1 change)

- Use sanitized user status message for user popover.


## 11.6.8 (2019-01-30)

- No changes.

## 11.6.5 (2019-01-17)

### Fixed (5 changes)

- Add syntax highlighting to suggestion diff. !24156
- Fix broken templated "Too many changes to show" text. !24282
- Fix requests profiler in admin page not rendering HTML properly. !24291
- Fix no avatar not showing in user selection box. !24346
- Fixed diff suggestions removing dashes.


## 11.6.4 (2019-01-15)

### Security (1 change)

- Validate bundle files before unpacking them.


## 11.6.3 (2019-01-04)

### Fixed (1 change)

- Fix clone URL not showing if protocol is HTTPS. !24131


## 11.6.2 (2019-01-02)

### Fixed (7 changes)

- Hide cluster features that don't work yet with Group Clusters. !23935
- Fix a 500 error that could occur until all migrations are done. !23939
- Fix missing Git clone button when protocol restriction setting enabled. !24015
- Fix clone dropdown parent inheritance issues in HAML. !24029
- Fix content-disposition in blobs and files API endpoint. !24078
- Fixed markdown toolbar buttons.
- Adjust line-height of blame view line numbers.


## 11.6.1 (2018-12-28)

### Security (15 changes)

- Escape label and milestone titles to prevent XSS in GFM autocomplete. !2740
- Prevent private snippets from being embeddable.
- Add subresources removal to member destroy service.
- Escape html entities in LabelReferenceFilter when no label found.
- Allow changing group CI/CD settings only for owners.
- Authorize before reading job information via API.
- Prevent leaking protected variables for ambiguous refs.
- Ensure that build token is only used when running.
- Issuable no longer is visible to users when project can't be viewed.
- Don't expose cross project repositories through diffs when creating merge reqeusts.
- Fix SSRF with import_url and remote mirror url.
- Fix persistent symlink in project import.
- Set URL rel attribute for broken URLs.
- Project guests no longer are able to see refs page.
- Delete confidential todos for user when downgraded to Guest.

### Other (1 change)

- Fix due date test. !23845


## 11.6.0 (2018-12-22)

### Security (24 changes, 1 of them is from the community)

- Fix possible XSS attack in Markdown urls with spaces. !2599
- Update rack to 2.0.6 (for QA environments). !23171 (Takuya Noguchi)
- Bump nokogiri, loofah, and rack gems for security updates. !23204
- Encrypt runners tokens. !23412
- Encrypt CI/CD builds authentication tokens. !23436
- Configure mermaid to not render HTML content in diagrams.
- Fix a possible symlink time of check to time of use race condition in GitLab Pages.
- Removed ability to see private group names when the group id is entered in the url.
- Fix stored XSS for Environments.
- Fix persistent symlink in project import.
- Fixed ability of guest users to edit/delete comments on locked or confidential issues.
- Fixed ability to comment on locked/confidential issues.
- Fix CRLF vulnerability in Project hooks.
- Fix SSRF in project integrations.
- Resolve reflected XSS in Ouath authorize window.
- Restrict Personal Access Tokens to API scope on web requests.
- Provide email notification when a user changes their email address.
- Don't expose confidential information in commit message list.
- Validate LFS hrefs before downloading them.
- Do not follow redirects in Prometheus service when making http requests to the configured api url.
- Escape user fullname while rendering autocomplete template to prevent XSS.
- Redact sensitive information on gitlab-workhorse log.
- Fix milestone promotion authorization check.
- Prevent a path traversal attack on global file templates.

### Removed (1 change)

- Remove obsolete gitlab_shell rake tasks. !22417

### Fixed (86 changes, 13 of them are from the community)

- Remove limit of 100 when searching repository code. !8671
- Show error message when attempting to reopen an MR and there is an open MR for the same branch. !16447 (Akos Gyimesi)
- Fix a bug where internal email pattern wasn't respected. !22516
- Fix project selector consistency in groups issues / MRs / boards pages. !22612 (Heinrich Lee Yu)
- Add empty state for graphs with no values. !22630
- Fix navigating by unresolved discussions on Merge Request page. !22789
- Fix "merged with [commit]" info for merge requests being merged automatically by other actions. !22794
- Fixing regression issues on pages settings and details. !22821
- Remove duplicate primary button in dashboard snippets on small viewports. !22902 (George Tsiolis)
- Fix API::Namespaces routing to accept namepaces with dots. !22912
- Switch kubernetes:active with checking in Auto-DevOps.gitlab-ci.yml. !22929
- Avoid Gitaly RPC errors when fetching diff stats. !22995
- Removes promote to group label for anonymous user. !23042 (Jacopo Beschi @jacopo-beschi)
- Fix enabling project deploy key for admins. !23043
- Align issue status label and confidential icon. !23046 (George Tsiolis)
- Fix default sorting for subgroups and projects list. !23058 (Jacopo Beschi @jacopo-beschi)
- Hashed Storage: allow migration to be retried in partially migrated projects. !23087
- Fix line height of numbers in file blame view. !23090 (Johann Hubert Sonntagbauer)
- Fixes an issue where default values from models would override values set in the interface (e.g. users would be set to external even though their emails matches the internal email address pattern). !23114
- Remove display of local Sidekiq process in /admin/sidekiq. !23118
- Fix unrelated deployment status in MR widget. !23175
- Respect confirmed flag on secondary emails. !23181
- Restrict member access level to be higher than that of any parent group. !23226
- Return real deployment status to frontend. !23270
- Handle force_remove_source_branch when creating merge request. !23281
- Avoid creating invalid refs using rugged, shelling out for writing refs. !23286
- Remove needless auto-capitalization on Wiki page titles. !23288
- Modify the wording for the knative cluster application to match upstream. !23289 (Chris Baumbauer)
- Change container width for project import. !23318 (George Tsiolis)
- Validate chunk size when persist. !23341
- Resolve Main navbar is broken in certain viewport widths. !23348
- Gracefully handle references with null bytes. !23365
- Display commit ID for commit diff discussion on merge request. !23370
- Pass commit when posting diff discussions. !23371
- Fix flash notice styling for fluid layout. !23382
- Add monkey patch to unicorn to fix eof? problem. !23385
- Commits API: Preserve file content in move operations if unspecified. !23387
- Disable password autocomplete in mirror form fill. !23402
- Fix "protected branches only" checkbox not set properly at init. !23409
- Support RSA and ECDSA algorithms in Omniauth JWT provider. !23411 (Michael Tsyganov)
- Make KUBECONFIG nil if KUBE_TOKEN is nil. !23414
- Allow search and sort users at same time on admin users page. !23439
- Fix: Unstar icon button is misaligned. !23444
- Fix error when searching for group issues with priority or popularity sort. !23445
- Fix Order By dropdown menu styling in tablet and mobile screens. !23446
- Fix collapsing discussion replies. !23462
- Gracefully handle unknown/invalid GPG keys. !23492
- Fix multiple commits shade overlapping vertical discussion line. !23515
- Use read_repository scope on read-only files API. !23534
- Avoid 500's when serializing legacy diff notes. !23544
- Fix web hook functionality when the database encryption key is too short. !23573
- Hide Knative from group cluster applications until supported. !23577
- Add top padding for nested environment items loading icon. !23580 (George Tsiolis)
- Improve help and validation sections of maximum build timeout inputs. !23586
- Fix milestone select in issue sidebar of issue boards. !23625
- Fix gitlab:web_hook tasks. !23635
- Avoid caching BroadcastMessage as an ActiveRecord object. !23662
- Only allow strings in URL::Sanitizer.valid?. !23675
- Fix a frozen string error in app/mailers/notify.rb. !23683
- Fix a frozen string error in lib/gitlab/utils.rb. !23690
- Fix MR resolved discussion counts being too low. !23710
- Fix a potential frozen string error in app/mailers/notify.rb. !23728
- Remove unnecessary div from MarkdownField to apply list styles correctly. !23733
- Display reply field if resolved discussion has no replies. !23801
- Restore kubernetes:active in Auto-DevOps.gitlab-ci.yml (reverts 22929). !23826
- Fix mergeUrlParams with fragment URL. !54218 (Thomas Holder)
- Fixed multiple diff line discussions not expanding.
- Fixed diff files expanding not loading commit content.
- Fixed styling of image comment badges on commits.
- Resolve possible cherry pick API race condition.
- When user clicks linenumber in MR changes, highlight that line.
- Remove old webhook logs after 90 days, as documented, instead of after 2.
- Add an external IP address to the knative cluster application page. (Chris Baumbauer)
- Fixed duplicate discussions getting added to diff lines.
- Fix deadlock on ChunkedIO.
- Show tree collapse button for merge request commit diffs.
- Use approximate count for big tables for usage statistics.
- Lock writes to trace stream.
- Ensure that SVG sprite icons are properly rendered in IE11.
- Make new branch form fields' fonts consistent.
- Open first 10 merge request files in IDE.
- Prevent user from navigating away from file edit without commit.
- Prevent empty button being rendered in empty state.
- Adds margins between tags when a job is stuck.
- Fix Image Lazy Loader for some older browsers.
- Correctly styles tags in sidebar for job page.

### Changed (34 changes, 9 of them are from the community)

- Include new link in breadcrumb for issues, merge requests, milestones, and labels. !18515 (George Tsiolis)
- Allow sorting issues and MRs in reverse order. !21438
- Design improvements to project overview page. !22196
- Remove auto deactivation when failed to create a pipeline via pipeline schedules. !22243
- Use group clusters when deploying (DeploymentPlatform). !22308
- Improve initial discussion rendering performance. !22607
- removes partially matching of No Label filter and makes it case-insensitive. !22622 (Jacopo Beschi @jacopo-beschi)
- Use search bar for filtering in dashboard issues / MRs. !22641 (Heinrich Lee Yu)
- Show different empty state for filtered issues and MRs. !22775 (Heinrich Lee Yu)
- Relocate JSONWebToken::HMACToken from EE. !22906
- Resolve Add border around the repository file tree. !23018
- Change breadcrumb title for contribution charts. !23071 (George Tsiolis)
- Update environments metrics empty state. !23074 (George Tsiolis)
- Refine cursor positioning in Markdown Editor for wrap tags. !23085 (Johann Hubert Sonntagbauer)
- Use reports syntax for SAST in Auto DevOps. !23163
- SystemCheck: Use a more reliable way to detect current Ruby version. !23291
- Changed frontmatter filtering to support YAML, JSON, TOML, and arbitrary languages. !23331 (Travis Miller)
- Don't remove failed install pods after installing GitLab managed applications. !23350
- Expose merge request pipeline variables. !23398
- Scope default MR search in WebIDE dropdown to current project. !23400
- Show user contributions in correct timezone within user profile. !23419
- Redesign of MR header sections (CE). !23465
- Auto DevOps: Add echo for each branch of the deploy() function where we run helm upgrade. !23499
- Updates service to update Kubernetes project namespaces and restricted service account if present. !23525
- Adjust divider margin to comply with design specs. !23548
- Adjust dropdown item and header padding to comply with design specs. !23552
- Truncate merge request titles with periods instead of ellipsis. !23558
- Remove close icon from projects dropdown in issue boards. !23567
- Change dropdown divider color to gray-200 (#dfdfdf). !23592
- Define the default value for only/except policies. !23765
- Don't show Memory Usage for unmerged MRs.
- reorder notification settings by noisy-ness. (C.J. Jameson)
- Changed merge request filtering to be by path instead of name.
- Make diff file headers sticky.

### Performance (22 changes, 6 of them are from the community)

- Upgrade to Ruby 2.5.3. !2806
- Removes all the irrelevant code and columns that were migrated from the Project table over to the ProjectImportState table. !21497
- Approximate counting strategy with TABLESAMPLE. !22650
- Replace tooltip directive with gl-tooltip diretive in badges, cycle analytics, and diffs. !22770 (George Tsiolis)
- Validate foreign keys being created and indexed for column with _id. !22808
- Remove monospace extend. !23089 (George Tsiolis)
- Use Nokogiri as the ActiveSupport XML backend. !23136
- Improve memory performance by reducing dirty pages after fork(). !23169
- Add partial index for ci_builds on project_id and status. !23268
- Reduce Gitaly calls in projects dashboard. !23307
- Batch load only data from same repository when lazy object is accessed. !23309
- Add index for events on project_id and created_at. !23354
- Remove index for notes on updated_at. !23356
- Improves performance of Project#readme_url by caching the README path. !23357
- Populate MR metrics with events table information (migration). !23564
- Remove unused data from discussions endpoint. !23570
- Speed up issue board lists in groups with many projects.
- Use cached size when passing artifacts to Runner.
- Enable even more frozen string for lib/gitlab. (gfyoung)
- Enable even more frozen string in lib/gitlab/**/*.rb. (gfyoung)
- Enable even more frozen string in lib/gitlab/**/*.rb. (gfyoung)
- Enable even more frozen string for lib/gitlab. (gfyoung)

### Added (32 changes, 13 of them are from the community)

- Add ability to create group level clusters and install gitlab managed applications. !22450
- Creates /create_merge_request quickaction. !22485 (Jacopo Beschi @jacopo-beschi)
- Filter by None/Any for labels in issues/mrs API. !22622 (Jacopo Beschi @jacopo-beschi)
- Chat message push notifications now include links back to GitLab branches. !22651 (Tony Castrogiovanni)
- Added feature flag to signal content headers detection by Workhorse. !22667
- Add Discord integration. !22684 (@blackst0ne)
- Upgrade helm to 2.11.0 and upgrade on every install. !22693
- Add knative client to kubeclient library. !22968 (cab105)
- Allow SSH public-key authentication for push mirroring. !22982
- Allow deleting a Pipeline via the API. !22988
- #40635: Adds support for cert-manager. !23036 (Amit Rathi)
- WebIDE: Pressing Ctrl-Enter while typing on the commit message now performs the commit action. !23049 (Thomas Pathier)
- Adds Any option to label filters. !23111 (Jacopo Beschi @jacopo-beschi)
- Added glob for CI changes detection. !23128 (Kirill Zaitsev)
- Add model and relation to store repo full path in database. !23143
- Add ability to render suggestions. !23147
- Introduce Knative and Serverless Components. !23174 (Chris Baumbauer)
- Use BFG object maps to clean projects. !23189
- Merge request pipelines. !23217
- Extended user centric tooltips on issue and MR page. !23231
- Add a rebase API endpoint for merge requests. !23296
- Add config to prohibit impersonation. !23338
- Merge request pipeline tag, and adds tags to pipeline view. !23364
- #52753: HTTPS for JupyterHub installation. !23479 (Amit Rathi)
- Fill project_repositories for hashed storage projects. !23482
- Ability to override email for cert-manager. !23503 (Amit Rathi)
- Allow public forks to be deduplicated. !23508
- Pipeline trigger variable values are hidden in the UI by default. Maintainers have the option to reveal them. !23518 (jhampton)
- Add new endpoint to download single artifact file for a ref. !23538
- Log and pass correlation-id between Unicorn, Sidekiq and Gitaly.
- Allow user to scroll to top of tab on MR page.
- Adds states to the deployment widget.

### Other (54 changes, 30 of them are from the community)

- Switch to Rails 5. !21492
- Migration to write fullpath in all repository configs. !22322
- Rails5: env is deprecated and will be removed from Rails 5.1. !22626 (Jasper Maes)
- Update haml_lint to 0.28.0. !22660 (Takuya Noguchi)
- Update ffaker to 2.10.0. !22661 (Takuya Noguchi)
- Drop gcp_clusters table. !22713
- Upgrade minimum required Git version to 2.18.0. !22803
- Adds new icon size to Vue icon component. !22899
- Make sure there's only one slash as path separator. !22954
- Show HTTP response code for Kubernetes errors. !22964
- Update config map for gitlab managed application if already present on install. !22969
- Drop default value on status column in deployments table. !22971
- UI improvements to user's profile. !22977
- Update asana to 0.8.1. !23039 (Takuya Noguchi)
- Update asciidoctor to 1.5.8. !23047 (Takuya Noguchi)
- Make auto-generated icons for subgroups in the breadcrumb dropdown display as a circle. !23062 (Thomas Pathier)
- Make reply shortcut only quote selected discussion text. !23096 (Thomas Pathier)
- Fix typo in notebook props. !23103 (George Tsiolis)
- Fix typos in lib. !23106 (George Tsiolis)
- Rename diffs store variable. !23123 (George Tsiolis)
- Fix overlapping navbar separator and overflowing navbar dropdown on small displays. !23126 (Thomas Pathier)
- Show what RPC is called in the performance bar. !23140
- Updated Gitaly to v0.133.0. !23148
- Rails5: Passing a class as a value in an Active Record query is deprecated. !23164 (Jasper Maes)
- Fix project identicon aligning Harry Kiselev. !23166 (Harry Kiselev)
- Fix horizontal scrollbar overlapping on horizontal scrolling-tabs. !23167 (Harry Kiselev)
- Fix bottom paddings of profile header and some markup updates of profile. !23168 (Harry Kiselev)
- Fixes to AWS documentation spelling and grammar. !23198 (Brendan O'Leary)
- Adds a PHILOSOPHY.md which references GitLab Product Handbook. !23200
- Externalize strings from `/app/views/invites`. !23205 (Tao Wang)
- Externalize strings from `/app/views/project/runners`. !23208 (Tao Wang)
- Fix typo for scheduled pipeline. !23218 (Davy Defaud)
- Force content disposition attachment to several endpoints. !23223
- Upgrade kubeclient to 4.0.0. !23261 (Praveen Arimbrathodiyil @pravi)
- Update used version of Runner Helm Chart to 0.1.38. !23304
- render :nothing option is deprecated, Use head method to respond with empty response body. !23311 (Jasper Maes)
- Passing an argument to force an association to reload is now deprecated. !23334 (Jasper Maes)
- Externalize strings from `/app/views/snippets`. !23351 (Tao Wang)
- Fix deprecation: You are passing an instance of ActiveRecord::Base to. !23369 (Jasper Maes)
- Resolve status emoji being replaced by avatar on mobile. !23408
- Fix deprecation: render :text is deprecated because it does not actually render a text/plain response. !23425 (Jasper Maes)
- Fix lack of documentation on how to fetch a snippet's content using API. !23448 (Colin Leroy)
- Upgrade GitLab Workhorse to v7.3.0. !23489
- Fallback to admin KUBE_TOKEN for project clusters only. !23527
- Update used version of Runner Helm Chart to 0.1.39. !23633
- Show primary button when all labels are prioritized. !23648 (George Tsiolis)
- Upgrade workhorse to 7.6.0. !23694
- Upgrade Gitaly to v1.7.1 for correlation-id logging. !23732
- Fix due date test. !23845
- Remove unused project method. !54103 (George Tsiolis)
- Uses new gitlab-ui components in Jobs and Pipelines components.
- Replaces tooltip directive with the new gl-tooltip directive for consistency in some ci/cd code.
- Bump gpgme gem version from 2.0.13 to 2.0.18. (asaparov)
- Enable Rubocop on lib/gitlab. (gfyoung)


## 11.5.11 (2019-04-23)

### Fixed (2 changes)

- Bring back Rugged implementation of find_commit. !25477
- Avoid excessive recursive calls with Rugged TreeEntries. !26813

### Performance (1 change)

- Bring back Rugged implementation of ListCommitsByOid. !27441

### Other (4 changes)

- Bring back Rugged implementation of GetTreeEntries. !25674
- Bring back Rugged implementation of CommitIsAncestor. !25702
- Bring back Rugged implementation of TreeEntry. !25706
- Bring back Rugged implementation of commit_tree_entry. !25896


## 11.5.8 (2019-01-28)

### Security (21 changes)

- Make potentially malicious links more visible in the UI and scrub RTLO chars from links. !2770
- Don't process MR refs for guests in the notes. !2771
- Fixed XSS content in KaTex links.
- Verify that LFS upload requests are genuine.
- Extract GitLab Pages using RubyZip.
- Prevent awarding emojis to notes whose parent is not visible to user.
- Prevent unauthorized replies when discussion is locked or confidential.
- Disable git v2 protocol temporarily.
- Fix showing ci status for guest users when public pipline are not set.
- Fix contributed projects info still visible when user enable private profile.
- Disallows unauthorized users from accessing the pipelines section.
- Add more LFS validations to prevent forgery.
- Use common error for unauthenticated users when creating issues.
- Fix slow regex in project reference pattern.
- Fix private user email being visible in push (and tag push) webhooks.
- Fix wiki access rights when external wiki is enabled.
- Fix path disclosure on project import error.
- Restrict project import visibility based on its group.
- Expose CI/CD trigger token only to the trigger owner.
- Notify only users who can access the project on project move.
- Alias GitHub and BitBucket OAuth2 callback URLs.


## 11.5.5 (2018-12-20)

### Security (1 change)

- Fix persistent symlink in project import.


## 11.5.3 (2018-12-06)

### Security (1 change)

- Prevent a path traversal attack on global file templates.


## 11.5.2 (2018-12-03)

### Removed (1 change)

- Removed Site Statistics optimization as it was causing problems. !23314

### Fixed (6 changes, 1 of them is from the community)

- Display impersonation token value only after creation. !22916
- Fix not render emoji in filter dropdown. !23112 (Hiroyuki Sato)
- Fixes stuck tooltip on stop env button. !23244
- Correctly handle data-loss scenarios when encrypting columns. !23306
- Clear BatchLoader context between Sidekiq jobs. !23308
- Fix handling of filenames with hash characters in tree view. !23368


## 11.5.1 (2018-11-26)

### Security (17 changes)

- Escape user fullname while rendering autocomplete template to prevent XSS.
- Fix CRLF vulnerability in Project hooks.
- Fix possible XSS attack in Markdown urls with spaces.
- Redact sensitive information on gitlab-workhorse log.
- Do not follow redirects in Prometheus service when making http requests to the configured api url.
- Don't expose confidential information in commit message list.
- Provide email notification when a user changes their email address.
- Restrict Personal Access Tokens to API scope on web requests.
- Resolve reflected XSS in Ouath authorize window.
- Fix SSRF in project integrations.
- Fixed ability to comment on locked/confidential issues.
- Fixed ability of guest users to edit/delete comments on locked or confidential issues.
- Fix milestone promotion authorization check.
- Configure mermaid to not render HTML content in diagrams.
- Fix a possible symlink time of check to time of use race condition in GitLab Pages.
- Removed ability to see private group names when the group id is entered in the url.
- Fix stored XSS for Environments.


## 11.5.0 (2018-11-22)

### Security (10 changes, 1 of them is from the community)

- Escape entity title while autocomplete template rendering to prevent XSS. !2556
- Update moment to 2.22.2. !22648 (Takuya Noguchi)
- Redact personal tokens in unsubscribe links.
- Escape user fullname while rendering autocomplete template to prevent XSS.
- Persist only SHA digest of PersonalAccessToken#token.
- Monkey kubeclient to not follow any redirects.
- Prevent SSRF attacks in HipChat integration.
- Prevent templated services from being imported.
- Validate Wiki attachments are valid temporary files.
- Fix XSS in merge request source branch name.

### Removed (2 changes)

- Remove Git circuit breaker. !22212
- Remove Koding integration and documentation. !22334

### Fixed (74 changes, 15 of them are from the community)

- Hide all tables on Pipeline when no Jobs for the Pipeline. !18540 (Takuya Noguchi)
- Fixing count on Milestones. !21446
- Use case insensitive username lookups. !21728 (William George)
- Correctly process Bamboo API result array. !21970 (Alex Lossent)
- Fix 'merged with' UI being displayed when merge request has no merge commit. !22022
- Fix broken file name navigation on MRs. !22109
- Fix incorrect spacing between buttons when commenting on a MR. !22135
- Vertical align Pipeline Graph in Commit Page. !22173 (Johann Hubert Sonntagbauer)
- Reject invalid branch names in repository compare controller. !22186
- Fix size of emojis of user status in user menu. !22194
- Use the standard PIP_CACHE_DIR for Python dependency caching template. !22211 (Takuya Noguchi)
- Fix bug with wiki attachments content disposition. !22220
- Does not allow a SSH URI when importing new projects. !22309
- fix duplicated key in license management job auto devops gitlab ci template. !22311 (Adam Lemanski)
- Fix commit signature error when project is disabled. !22344
- Show available clusters when installed or updated. !22356
- Fix auto-corrected upload URLs in webhooks. !22361
- Fix a bug displaying certain wiki pages. !22377
- Fix prometheus graphs in firefox. !22400
- Resolve assign-me quick action doesn't work if there is extra white space. !22402
- Remove base64 encoding from files that contain plain text. !22425
- Strip whitespace around GitHub personal access tokens. !22432
- Fix 500 error when testing webhooks with redirect loops. !22447 (Heinrich Lee Yu)
- Fix rendering of 'Protected' value on Runner details page. !22459
- Fix bug stopping non-admin users from changing visibility level on group creation. !22468
- Make Issue Board sidebar show project-specific labels based on selected Issue. !22475
- Fix EOF detection with CI artifacts metadata. !22479
- Fix transient spec error in the bar_chart component. !22495
- Resolve LFS not correctly showing enabled. !22501
- If user was not found, service hooks won't run on post receive background job. !22519
- Fix broken "Show whitespace changes" button on MRs. !22539
- Always show new issue button in boards' Open list. !22557 (Heinrich Lee Yu)
- Add transparent background to markdown header tabs. !22565 (George Tsiolis)
- Use gitlab_environment for ldap rake task. !22582
- Add commit message to commit tree anchor title. !22585
- Cache pipeline status per SHA. !22589
- Change HELM_HOST in Auto-DevOps template to work behind proxy. !22596 (Sergej Nikolaev <kinolaev@gmail.com>)
- Show user status for label events in system notes. !22609
- Fix extra merge request versions created from forked merge requests. !22611
- Remove PersonalAccessTokensFinder#find_by method. !22617
- Fix search "all in GitLab" not working with relative URLs. !22644
- Fix quick links button styles. !22657 (George Tsiolis)
- Fix #53298: JupyterHub restarts should work without errors. !22671 (Amit Rathi)
- Fix incompatibility with IE11 due to non-transpiled gitlab-ui components. !22695
- Fix bug when links in tabs of the labels index pages ends with .html. !22716
- Fixed label removal from issue. !22762
- Align toggle sidebar button across all browsers and OSs. !22771
- Disable replication lag check for Aurora PostgreSQL databases. !22786
- Render unescaped link for failed pipeline status. !22807
- Fix misaligned approvers dropdown. !22832
- Fix bug with wiki page create message. !22849
- Fix rendering of filter bar tokens for special values. !22865 (Heinrich Lee Yu)
- Align sign in button. !22888 (George Tsiolis)
- Fix error handling bugs in kubernetes integration. !22922
- Fix deployment jobs using nil KUBE_TOKEN due to migration issue. !23009
- Avoid returning deployment metrics url to MR widget when the deployment is not successful. !23010
- Fix a race condition intermittently breaking GitLab startup. !23028
- Adds margin after a deleted branch name in the activity feed. !23038
- Ignore environment validation failure. !23100
- Adds CI favicon back to jobs page.
- Redirect to the pipeline builds page when a build is canceled. (Eva Kadlecova)
- Fixed diff stats not showing when performance bar is enabled.
- Show expand all diffs button when a single diff file is collapsed.
- Clear fetched file templates when changing template type in Web IDE.
- Fix bug causing not all emails to show up in commit email selectbox.
- Remove duplicate escape in job sidebar.
- Fixing styling issues on the scheduled pipelines page.
- Fixes broken test in master.
- Renders stuck block when runners are stuck.
- Removes extra border from test reports in the merge request widget.
- Fixes broken borders for reports section in MR widget.
- Only render link to branch when branch still exists in pipeline page.
- Fixed source project not filtering in merge request creation compare form.
- Do not reload self on hooks when creating deployment.

### Changed (38 changes, 12 of them are from the community)

- Link button in markdown editor recognize URLs. !1983 (Johann Hubert Sonntagbauer)
- Replace i to icons in vue components. !20748 (George Tsiolis)
- Remove Linguist gem, reducing Rails memory usage by 128MB per process. !21008
- Issue board card design. !21229
- On deletion of a file in sub directory in web IDE redirect to the sub directory instead of project root. !21465 (George Thomas @thegeorgeous)
- Change single-item breadcrumbs to page titles. !22155
- Improving branch filter sorting by listing exact matches first and added support for begins_with (^) and ends_with ($) matching. !22166 (Jason Rutherford)
- Remove legacy unencrypted webhook columns from the database. !22199
- Show canary status in the performance bar. !22222
- Add failure reason for execution timeout. !22224
- Rename "scheduled" label/badge of delayed jobs to "delayed". !22245
- Update the empty state on wiki-only projects to display an empty state that is more consistent with the rest of the system. !22262
- Add IID headers to E-Mail notifications. !22263
- Allow finding the common ancestor for multiple revisions through the API. !22295
- Add status to Deployment. !22380
- Add dynamic timer to delayed jobs. !22382
- No longer require a deploy to start Prometheus monitoring. !22401
- Secret Variables renamed to CI Variables in the codebase, to match UX. !22414 (Marcel Amirault @ravlen)
- Automatically navigate to last board visited. !22430
- Use merge request prefix symbol in event feed title. !22449 (George Tsiolis)
- Update Ruby version in README. !22466 (J.D. Bean)
- Reword error message for internal CI unknown pipeline status. !22474
- Bump mermaid to 8.0.0-rc.8. !22509 (@blackst0ne)
- Update Todo icons in collapsed sidebar for Issues and MRs. !22534
- Support backward compatibility when introduce new failure reason. !22566
- Add dynamic timer for delayed jobs in pipelines list. !22621
- Truncate milestone title on collapsed sidebar. !22624 (George Tsiolis)
- Standardize milestones filter in APIs to None / Any. !22637 (Heinrich Lee Yu)
- Add dynamic timer for delayed jobs in job list. !22656
- Allowing issues with single letter identifiers to be linked to external issue tracker (f.ex T-123). !22717 (Dídac Rodríguez Arbonès)
- Update project and group labels empty state. !22745 (George Tsiolis)
- Fix environment status in merge request widget. !22799
- Paginate Bitbucket Server importer projects. !22825
- Drop `allow_overflow` option in `TimeHelper.duration_in_numbers`. !52284
- Add 'only history' option to notes filter.
- Adds filtered dropdown with changed files in review.
- Expose {closed,merged}_{at,by} in merge requests API index.
- Make all legacy security reports to use raw format.

### Performance (27 changes, 6 of them are from the community)

- Add preload for routes and namespaces for issues controller. !21651
- Enhance performance of counting local LFS objects. !22143
- Use cached readme contents when available. !22325
- Experimental support for running Puma multithreaded web-server. !22372
- Enhance performance of counting local Uploads. !22522
- Reduce SQL queries needed to load open merge requests. !22709
- Significantly cut memory usage and SQL queries when reloading diffs. !22725
- Optimize merge request refresh by using the database to check commit SHAs. !22731
- Remove dind from license_management auto-devops job definition. !22732
- Add index to find stuck merge requests. !22749
- Allow Rails concurrency when running in Puma. !22751
- Improve performance of rendering large reports. !22835
- Improves performance of stuck import jobs detection. !22879
- Rewrite SnippetsFinder to improve performance by a factor of 1500.
- Enable more frozen string in lib/**/*.rb. (gfyoung)
- Enable some frozen string in lib/gitlab. (gfyoung)
- Enable even more frozen string in lib/**/*.rb. (gfyoung)
- Improve performance of tree rendering in repositories with lots of items.
- Remove gitlab-ui's tooltip from global.
- Remove gitlab-ui's progress bar from global.
- Remove gitlab-ui's pagination from global.
- Remove gitlab-ui's modal from global.
- Remove gitlab-ui's loading icon from global.
- Enable frozen string for lib/gitlab/*.rb. (gfyoung)
- Enable frozen string for lib/gitlab/ci. (gfyoung)
- Enable frozen string for remaining lib/gitlab/ci/**/*.rb. (gfyoung)
- Adds pagination to pipelines table in merge request page.

### Added (33 changes, 11 of them are from the community)

- Add endpoint to update a git submodule reference. !20949
- Add license data to projects endpoint. !21606 (J.D. Bean (@jdbean))
- Allow to configure when to retry failed CI jobs. !21758 (Markus Doits)
- Add API endpoint to list issue related merge requests. !21806 (Helmut Januschka)
- Add the Play button for delayed jobs in environment page. !22106
- Switch between tree list & file list in diffs file browser. !22191
- Re-arrange help-related user menu items into new Help menu. !22195
- Adds trace of each access check when git push times out. !22265
- Add email for milestone change. !22279
- Show post-merge pipeline in merge request page. !22292
- Add Applications API endpoints for listing and deleting entries. !22296 (Jean-Baptiste Vasseur)
- Added `Any` option to milestones filter. !22351 (Heinrich Lee Yu)
- Improve validation errors for external CI/CD configuration. !22394
- Introduce new model to persist specific cluster information. !22404
- Add background migration to populate Kubernetes namespaces. !22433
- Add support for JSON logging for audit events. !22471
- Adds option to override commit email with a noreply private email. !22560
- Add None/Any option for assignee_id in Issues and Merge Requests API. !22598 (Heinrich Lee Yu)
- Add None/Any option for assignee_id in search bar. !22599 (Heinrich Lee Yu)
- Implement parallel job keyword. !22631
- Add None / Any options to reactions filter. !22638 (Heinrich Lee Yu)
- Make index.* render like README.* when it's present in a repository. !22639 (Jakub Jirutka)
- Allow adding patches when creating a merge request via email. !22723 (Serdar Dogruyol)
- Bump Gitaly to 0.129.0. !22868
- Allow commenting on any diff line in Merge Requests. !22914
- Add revert to commits API. !22919
- Introduce Knative support. !43959 (Chris Baumbauer)
- Reimplemented image commenting in merge request diffs.
- Soft-archive old jobs.
- Renders warning info when job is archieved.
- Support licenses and performance.
- Filter notes by comments or activity for issues and merge requests.
- Bump Gitaly to 0.128.0.

### Other (54 changes, 18 of them are from the community)

- Remove .card-title from .card-header for BS4 migration. !19335 (Takuya Noguchi)
- Update group settings/edit page to new design. !21115
- Change markdown header tab anchor links to buttons. !21988 (George Tsiolis)
- Replace tooltip in markdown component with gl-tooltip. !21989 (George Tsiolis)
- Extend RBAC by having a service account restricted to project's namespace. !22011
- Update images in group docs. !22031 (Marc Schwede)
- Add gitlab:gitaly:check task for Gitaly health check. !22063
- Add new sort option "most_stars" to "Group > Children" pages. !22121 (Rene Hennig)
- Fix inaccessible dropdown for code-less projects. !22137
- Rails5: fix user edit profile clear status spec. !22169 (Jasper Maes)
- Rails 5: fix mysql milliseconds problems in scheduled build specs. !22170 (Jasper Maes)
- Focus project slug on tab navigation. !22198
- Redesign activity feed. !22217
- Update used version of Runner Helm Chart to 0.1.34. !22274
- Update environments empty state. !22297 (George Tsiolis)
- Adds model and migrations to enable group level clusters. !22307
- Use literal instead of constructor for creating regex. !22367
- Remove prometheus configuration help text. !22413 (George Tsiolis)
- Rails5: fix deployment model spec. !22428 (Jasper Maes)
- Change to top level controller for clusters so that we can use it for project clusters (now) and group clusters (later). !22438
- Remove empty spec describe blocks. !22451 (George Tsiolis)
- Change branch font type in tag creation. !22454 (George Tsiolis)
- Rails5: fix delete blob. !22456 (Jasper Maes)
- Start tracking shards and pool repositories in the database. !22482
- Allow kubeclient to call RoleBinding methods. !22524
- Introduce new kubernetes helpers. !22525
- Adds container to pager to enable scoping. !22529
- Update used version of Runner Helm Chart to 0.1.35. !22541
- Removes experimental labels from cluster views. !22550
- Combine all datetime library functions into 'datetime_utility.js'. !22570
- Upgrade Prometheus to 2.4.3 and Alertmanager to 0.15.2. !22600
- Fix stage dropdown not rendering in different languages. !22604
- Remove asset_sync gem from Gemfile and related code from codebase. !22610
- Use key-value pair arrays for API query parameter logging instead of hashes. !22623
- Replace deprecated uniq on a Relation with distinct. !22625 (Jasper Maes)
- Remove mousetrap-rails gem. !22647 (Takuya Noguchi)
- Fix IDE typos in props. !22685 (George Tsiolis)
- Add scheduled flag to job entity. !22710
- Remove `ci_enable_scheduled_build` feature flag. !22742
- Add endpoints for simulating certain failure modes in the application. !22746
- Bump KUBERNETES_VERSION for Auto DevOps to latest 1.10 series. !22757
- Fix statement timeouts in RemoveRestrictedTodos migration. !22795
- Rails5: fix mysql milliseconds issue in deployment model specs. !22850 (Jasper Maes)
- Update GitLab-Workhorse to v7.1.0. !22883
- Update JIRA service UI to accept email and API token.
- Update wiki empty state. (George Tsiolis)
- Only renders dropdown for review app changes when we have a list of files to show. Otherwise will render the regular review app button.
- Associate Rakefile with Ruby icon in diffs.
- Uses gitlab-ui components in jobs components.
- Create new group: Rename form fields and update UI.
- Transform job page into a single Vue+Vuex application.
- Updates svg dependency.
- Adds missing i18n to pipelines table.
- Disables stop environment button while the deploy is in progress.


## 11.4.9 (2018-12-03)

### Fixed (2 changes)

- Display impersonation token value only after creation. !22916
- Correctly handle data-loss scenarios when encrypting columns. !23306


## 11.4.8 (2018-11-27)

### Security (24 changes)

- Escape entity title while autocomplete template rendering to prevent XSS. !2571
- Resolve reflected XSS in Ouath authorize window.
- Fix XSS in merge request source branch name.
- Escape user fullname while rendering autocomplete template to prevent XSS.
- Fix CRLF vulnerability in Project hooks.
- Fix possible XSS attack in Markdown urls with spaces.
- Redact sensitive information on gitlab-workhorse log.
- Do not follow redirects in Prometheus service when making http requests to the configured api url.
- Persist only SHA digest of PersonalAccessToken#token.
- Don't expose confidential information in commit message list.
- Provide email notification when a user changes their email address.
- Restrict Personal Access Tokens to API scope on web requests.
- Redact personal tokens in unsubscribe links.
- Fix SSRF in project integrations.
- Fixed ability to comment on locked/confidential issues.
- Fixed ability of guest users to edit/delete comments on locked or confidential issues.
- Fix milestone promotion authorization check.
- Monkey kubeclient to not follow any redirects.
- Configure mermaid to not render HTML content in diagrams.
- Fix a possible symlink time of check to time of use race condition in GitLab Pages.
- Removed ability to see private group names when the group id is entered in the url.
- Fix stored XSS for Environments.
- Prevent SSRF attacks in HipChat integration.
- Validate Wiki attachments are valid temporary files.


## 11.4.7 (2018-11-20)

- No changes.

## 11.4.6 (2018-11-18)

### Security (1 change)

- Escape user fullname while rendering autocomplete template to prevent XSS.


## 11.4.5 (2018-11-04)

### Fixed (4 changes, 1 of them is from the community)

- fix link to enable usage ping from convdev index. !22545 (Anand Capur)
- Update gitlab-ui dependency to 1.8.0-hotfix.1 to fix IE11 bug.
- Remove duplicate escape in job sidebar.
- Fixed merge request fill tree toggling not respecting fluid width preference.

### Other (1 change)

- Fix stage dropdown not rendering in different languages.


## 11.4.4 (2018-10-30)

### Security (1 change)

- Monkey kubeclient to not follow any redirects.


## 11.4.3 (2018-10-26)

- No changes.

## 11.4.2 (2018-10-25)

### Security (5 changes)

- Escape entity title while autocomplete template rendering to prevent XSS. !2571
- Persist only SHA digest of PersonalAccessToken#token.
- Redact personal tokens in unsubscribe links.
- Block loopback addresses in UrlBlocker.
- Validate Wiki attachments are valid temporary files.


## 11.4.1 (2018-10-23)

### Security (2 changes)

- Fix XSS in merge request source branch name.
- Prevent SSRF attacks in HipChat integration.


## 11.4.0 (2018-10-22)

### Security (9 changes)

- Filter user sensitive data from discussions JSON. !2536
- Encrypt webhook tokens and URLs in the database. !21645
- Redact confidential events in the API.
- Set timeout for syntax highlighting.
- Sanitize JSON data properly to fix XSS on Issue details page.
- Markdown API no longer displays confidential title references unless authorized.
- Properly filter private references from system notes.
- Fix stored XSS in merge requests from imported repository.
- Fix xss vulnerability sourced from package.json.

### Removed (2 changes)

- Remove background job throttling feature. !21748
- Remove sidekiq info from performance bar.

### Fixed (68 changes, 18 of them are from the community)

- Fixes 500 for cherry pick API with empty branch name. !21501 (Jacopo Beschi @jacopo-beschi)
- Fix sorting by priority or popularity on group issues page, when also searching issue content. !21521
- Fix vertical alignment of text in diffs. !21573
- Fix performance bar modal position. !21577
- Bump KaTeX version to 0.9.0. !21625
- Correctly show legacy diff notes in the merge request changes tab. !21652
- Synchronize the default branch when updating a remote mirror. !21653
- Filter group milestones based on user membership. !21660
- Fix double title in merge request chat messages. !21670 (Kukovskii Vladimir)
- Delete container repository tags outside of transaction. !21679
- Images are no longer displayed in Todo descriptions. !21704
- Fixed merge request widget discussion state not updating after resolving discussions. !21705
- Vendor Auto-DevOps.gitlab-ci.yml to fix bug where the deploy job does not wait for Deployment to complete. !21713
- Use Reliable Sidekiq fetch. !21715
- No longer show open issues from archived projects in group issue board. !21721
- Issue and MR count now ignores archived projects. !21721
- Fix resizing of monitoring dashboard. !21730
- Fix object storage uploads not working with AWS v2. !21731
- Don't ignore first action when assign and unassign quick actions are used in the same comment. !21749
- Align form labels following Bootstrap 4 docs. !21752
- Respect the user commit email in more places. !21773
- Use stats RPC when comparing diffs. !21778
- Show commit details for selected commit in MR diffs. !21784
- Resolve "Geo: Does not mark repositories as missing on primary due to stale cache". !21789
- Fix leading slash in redirects and add rubocop cop. !21828 (Sanad Liaquat)
- Fix activity titles for MRs in chat notification services. !21834
- Hides Close Merge request btn on merged Merge request. !21840 (Jacopo Beschi @jacopo-beschi)
- Doesn't synchronize the default branch for push mirrors. !21861
- Fix broken styling when issue board is collapsed. !21868 (Andrea Leone)
- Set a header for custom error pages to prevent them from being intercepted by gitlab-workhorse. !21870 (David Piegza)
- Fix resolved discussions being unresolved when commented on. !21881
- Fix timeout when running the RemoveRestrictedTodos background migration. !21893
- Enable the ability to use the force env for rebuilding authorized_keys during a restore. !21896
- Fix link handling for issue cards to avoid too sensitive drag events. !21910 (Johann Hubert Sonntagbauer)
- Guard against a login attempt with invalid CSRF token. !21934
- Allow setting user's organization and location attributes through the API by adding them to the list of allowed parameters. !21938 (Alexis Reigel)
- Includes commit stats in POST project commits API. !21968 (Jacopo Beschi @jacopo-beschi)
- Fix loading issue on some merge request discussion. !21982
- Prevent Error 500s with invalid relative links. !22001
- Fix stale issue boards after browser back. !22006 (Johann Hubert Sonntagbauer)
- Filter issues without an Assignee via the API. !22009 (Eva Kadlecová)
- Fixes modal button alignment. !22024 (Jacopo Beschi @jacopo-beschi)
- Fix rendering placeholder notes. !22078
- Instance Configuration page now displays correct SSH fingerprints. !22081
- Fix showing diff file header for renamed files. !22089
- Fix LFS uploaded images not being rendered. !22092
- Fix the issue where long environment names aren't being truncated, causing the environment name to overlap into the column next to it. !22104
- Trim whitespace when inviting a new user by email. !22119 (Jacopo Beschi @jacopo-beschi)
- Fix incorrect parent path on group settings page. !22142
- Update copy to clipboard button data for application secret. !22268 (George Tsiolis)
- Improve MR file tree in smaller screens. !22273
- Fix project deletion when there is a export available. !22276
- Fixes stuck block URL linking to documentation instead of settings page. !22286
- Fix caching issue with pipelines URL. !22293
- Fix erased block not being rendered when job was erased. !22294
- Load correct stage in the stages dropdown. !22317
- Fixes close/reopen quick actions preview for issues and merge_requests. !22343 (Jacopo Beschi @jacopo-beschi)
- Allow Issue and Merge Request sidebar to be toggled from collapsed state. !22353
- Fix filter bar height bug when a tag is added.
- Fix the state of the Done button when there is an error in the GitLab Todos section. (marcos8896)
- Fix wrong text color of help text in merge request creation. (Gerard Montemayor)
- Add borders and white background to markdown tables.
- Fixed mention autocomplete in edit merge request.
- Fix long webhook URL overflow for custom integration. (Kukovskii Vladimir)
- Fixed file templates not fully being fetched in Web IDE.
- Fixes performance bar looking for a key in a undefined prop.
- Hides sidebar for job page in mobile.
- Fixes triggered/created labeled in job header.

### Changed (26 changes, 4 of them are from the community)

- Enable unauthenticated access to public SSH keys via the API. !20118 (Ronald Claveau)
- Support Kubernetes RBAC for GitLab Managed Apps when creating new clusters. !21401
- Highlight current user in comments. !21406
- Excludes project marked from deletion to projects API. !21542 (Jacopo Beschi @jacopo-beschi)
- Improve install flow of Kubernetes cluster apps. !21567
- Move including external files in .gitlab-ci.yml from Starter to Libre. !21603
- Simplify runner registration token resetting. !21658
- Filter any parameters ending with "key" in logs. !21688
- Ensure the schema is loaded with post_migrations included. !21689
- Updated icons used in filtered search dropdowns. !21694
- Enable omniauth by default. !21700
- Vendor Auto-DevOps.gitlab-ci.yml to refactor registry_login. !21714 (Laurent Goderre @LaurentGoderre)
- Add Gitaly diff stats RPC client. !21732
- Allow user to revoke an authorized application even if User OAuth applications setting is disabled in admin settings. !21835
- Change vertical margin of page titles to 16px. !21888
- Preserve order of project tags list. !21897
- Avoid close icon leaving the modal header. !21904
- Allow /copy_metadata for new issues and MRs. !21953
- Link to the tag for a version on the help page instead of to the commit. !22015
- Show SHA for pre-release versions on the help page. !22026
- Use local tiller for Auto DevOps. !22036
- Remove 'rbac_clusters' feature flag. !22096
- Increased retained event data by extending events pruner timeframe to 2 years. !22145
- Add installation type to backup information file. !22150
- Remove duplicate button from the markdown header toolbar. !22192 (George Tsiolis)
- Update to Rouge 3.3.0 including frozen string literals for improved memory usage.

### Performance (17 changes, 6 of them are from the community)

- Enable frozen string in app/controllers/**/*.rb.
- Improve lazy image loading performance by using IntersectionObserver where available. !21565
- Adds support for Gitaly ListLastCommitsForTree RPC in order to make bulk-fetch of commits more performant. !21921
- Dont create license_management build when not included in license. !21958
- Skip creating auto devops jobs for sast, container_scanning, dast, dependency_scanning when not licensed. !21959
- Reduce queries needed to compute notification recipients. !22050
- Banzai label ref finder - minimize SQL calls by sharing context more aggresively. !22070
- Removes expensive dead code on main MR page request. !22153
- Lazy load xterm custom colors css.
- Mitigate N+1 queries when parsing commit references in comments.
- Enable more frozen string in app/controllers/. (gfyoung)
- Increase performance when creating discussions on diff.
- Enable frozen string in lib/api and lib/backup. (gfyoung)
- Enable frozen string in vestigial files. (gfyoung)
- Enable frozen string for app/helpers/**/*.rb. (gfyoung)
- Enable frozen string in app/graphql + app/finders. (gfyoung)
- Enable even more frozen string in app/controllers. (gfyoung)

### Added (37 changes, 21 of them are from the community)

- Allow file templates to be requested at the project level. !7776
- Add /lock and /unlock quick actions. !15197 (Mehdi Lahmam (@mehlah))
- Added search functionality for Work In Progress (WIP) merge requests. !18119 (Chantal Rollison)
- pipeline webhook event now contain pipeline variables. !18171 (Pierre Tardy)
- Add markdown header toolbar button to insert table. !18480 (George Tsiolis)
- Add link button to markdown editor toolbar. !18579 (Jan Beckmann)
- Add access control to GitLab pages and make it possible to enable/disable it in project settings. !18589 (Tuomo Ala-Vannesluoma)
- Add a filter bar to the admin runners view and add a state filter. !19625 (Alexis Reigel)
- Add a type filter to the admin runners view. !19649 (Alexis Reigel)
- Allow user to choose the email used for commits made through GitLab's UI. !21213 (Joshua Campbell)
- Add autocomplete drop down filter for project snippets. !21458 (Fabian Schneider)
- Allow events filter to be set in the URL in addition to cookie. !21557 (Igor @igas)
- Adds a initialize_with_readme parameter to POST /projects. !21617 (Steve)
- Add ability to skip user email confirmation with API. !21630
- Add sorting for labels on labels page. !21642
- Set user status from within user menu. !21643
- Copy nurtch demo notebooks at Jupyter startup. !21698 (Amit Rathi)
- Allows to sort projects by most stars. !21762 (Jacopo Beschi @jacopo-beschi)
- Allow pipelines to schedule delayed job runs. !21767
- Added tree of changed files to merge request diffs. !21833
- Add GitLab version components to CI environment variables. !21853
- Allows to chmod file with commits API. !21866 (Jacopo Beschi @jacopo-beschi)
- Make single diff patch limit configurable. !21886
- Extend reports feature to support Security Products. !21892
- Adds the user's public_email attribute to the API. !21909 (Alexis Reigel)
- Update all gitlab CI templates from gitlab-org/gitlab-ci-yml. !21929
- Add support for setting the public email through the api. !21938 (Alexis Reigel)
- Support db migration and initialization for Auto DevOps. !21955
- Add subscribe filter to group and project labels pages. !21965
- Add support for pipeline only/except policy for modified paths. !21981
- Docs for Project/Groups members API with inherited members. !21984 (Jacopo Beschi @jacopo-beschi)
- Adds Web IDE commits to usage ping. !22007
- Add timed incremental rollout to Auto DevOps. !22023
- Show percentage of language detection on the language bar. !22056 (Johann Hubert Sonntagbauer)
- Allows to filter issues by Any milestone in the API. !22080 (Jacopo Beschi @jacopo-beschi)
- Add button to download 2FA codes. (Luke Picciau)
- Render log artifact files in GitLab.

### Other (42 changes, 16 of them are from the community)

- Send deployment information in job API. !21307
- Split admin settings into multiple sub pages. !21467
- Remove Rugged and shell code from Gitlab::Git. !21488
- Add trigger information in job API. !21495
- Add empty state illustration information in job API. !21532
- Add retried jobs to pipeline stage. !21558
- Rails 5: fix issue move service In rails 5, the attributes method for an enum returns the name instead of the database integer. !21616 (Jasper Maes)
- Expose project runners in job API. !21618
- create from template: hide checkbox for initializing repository with readme. !21646
- Adds new 'Overview' tab on user profile page. !21663
- Add clean-up phase for ScheduleDiffFilesDeletion migration. !21734
- Prevents private profile help link from toggling checkbox. !21757
- Make AutoDevOps work behind proxy. !21775 (Sergej - @kinolaev)
- Use Vue components and new API to render Artifacts, Trigger Variables and Commit blocks on Job page. !21777
- Add wrapper rake task to migrate all uploads to OS. !21779
- Retroactively fill pipeline source for external pipelines. !21814
- Rename squash before merge vue component. !21851 (George Tsiolis)
- Fix merge request header margins. !21878
- Fix committer typo. !21899 (George Tsiolis)
- Adds an extra width to the responsive tables. !21928
- Expose has_trace in job API. !21950
- Rename block scope local variable in table pagination spec. !21969 (George Tsiolis)
- Fix blue, orange, and red color inconsistencies. !21972
- Update operations metrics empty state. !21974 (George Tsiolis)
- Improve empty project placeholder for non-members and members without write access. !21977 (George Tsiolis)
- Add copy to clipboard button for application id and secret. !21978 (George Tsiolis)
- Add link component to UserAvatarLink component. !21986 (George Tsiolis)
- Add link component to DownloadViewer component. !21987 (George Tsiolis)
- Rephrase 2FA and TOTP documentation and view. !21998 (Marc Schwede)
- Update project path on project name autofill. !22016
- Improve logging when username update fails due to registry tags. !22038
- Align collapsed sidebar avatar container. !22044 (George Tsiolis)
- Rails5: fix artifacts controller download spec Rails5 has params[:file_type] as '' if file_type is included as nil in the request. !22123 (Jasper Maes)
- Hide pagination for personal projects on profile overview tab. !22321
- Extracts scroll position check into reusable functions.
- Uses Vuex store in job details page and removes old mediator pattern.
- Render 412 when invalid UTF-8 parameters are passed to controller.
- Renders Job show page in new Vue app.
- Add link to User Snippets in breadcrumbs of New User Snippet page. (J.D. Bean)
- Log project services errors when executing async.
- Update docs regarding frozen string. (gfyoung)
- Check frozen string in style builds. (gfyoung)


## 11.3.14 (2018-12-20)

### Security (1 change)

- Fix persistent symlink in project import.


## 11.3.13 (2018-12-13)

### Security (1 change)

- Validate LFS hrefs before downloading them.


## 11.3.12 (2018-12-06)

### Security (1 change)

- Prevent a path traversal attack on global file templates.


## 11.3.11 (2018-11-26)

### Security (33 changes)

- Filter user sensitive data from discussions JSON. !2537
- Escape entity title while autocomplete template rendering to prevent XSS. !2557
- Restrict Personal Access Tokens to API scope on web requests.
- Fix XSS in merge request source branch name.
- Escape user fullname while rendering autocomplete template to prevent XSS.
- Fix CRLF vulnerability in Project hooks.
- Fix possible XSS attack in Markdown urls with spaces.
- Redact sensitive information on gitlab-workhorse log.
- Set timeout for syntax highlighting.
- Do not follow redirects in Prometheus service when making http requests to the configured api url.
- Persist only SHA digest of PersonalAccessToken#token.
- Sanitize JSON data properly to fix XSS on Issue details page.
- Don't expose confidential information in commit message list.
- Markdown API no longer displays confidential title references unless authorized.
- Provide email notification when a user changes their email address.
- Properly filter private references from system notes.
- Redact personal tokens in unsubscribe links.
- Resolve reflected XSS in Ouath authorize window.
- Fix SSRF in project integrations.
- Fix stored XSS in merge requests from imported repository.
- Fixed ability to comment on locked/confidential issues.
- Fixed ability of guest users to edit/delete comments on locked or confidential issues.
- Fix milestone promotion authorization check.
- Monkey kubeclient to not follow any redirects.
- Configure mermaid to not render HTML content in diagrams.
- Redact confidential events in the API.
- Fix xss vulnerability sourced from package.json.
- Fix a possible symlink time of check to time of use race condition in GitLab Pages.
- Removed ability to see private group names when the group id is entered in the url.
- Fix stored XSS for Environments.
- Block loopback addresses in UrlBlocker.
- Prevent SSRF attacks in HipChat integration.
- Validate Wiki attachments are valid temporary files.


## 11.3.10 (2018-11-18)

### Security (1 change)

- Escape user fullname while rendering autocomplete template to prevent XSS.


## 11.3.9 (2018-10-31)

### Security (1 change)

- Monkey kubeclient to not follow any redirects.


## 11.3.8 (2018-10-27)

- No changes.

## 11.3.7 (2018-10-26)

### Security (6 changes)

- Escape entity title while autocomplete template rendering to prevent XSS. !2557
- Persist only SHA digest of PersonalAccessToken#token.
- Fix XSS in merge request source branch name.
- Redact personal tokens in unsubscribe links.
- Prevent SSRF attacks in HipChat integration.
- Validate Wiki attachments are valid temporary files.


## 11.3.6 (2018-10-17)

- No changes.

## 11.3.5 (2018-10-15)

### Fixed (2 changes)

- Fix loading issue on some merge request discussion. !21982
- Fix project deletion when there is a export available. !22276


## 11.3.3 (2018-10-04)

- No changes.

## 11.3.2 (2018-10-03)

### Fixed (4 changes)

- Fix NULL pipeline import problem and pipeline user mapping issue. !21875
- Fix migration to avoid an exception during upgrade. !22055
- Fixes admin runners table not wrapping content.
- Fix Error 500 when forking projects with Gravatar disabled.

### Other (1 change)

- Removes the 'required' attribute from the 'project name' field. !21770


## 11.3.1 (2018-09-26)

### Security (6 changes)

- Redact confidential events in the API.
- Set timeout for syntax highlighting.
- Sanitize JSON data properly to fix XSS on Issue details page.
- Fix stored XSS in merge requests from imported repository.
- Fix xss vulnerability sourced from package.json.
- Block loopback addresses in UrlBlocker.


## 11.3.0 (2018-09-22)

### Security (5 changes, 1 of them is from the community)

- Disable the Sidekiq Admin Rack session. !21441
- Set issuable_sort, diff_view, and perf_bar_enabled cookies to secure when possible. !21442
- Update rubyzip to 1.2.2 (CVE-2018-1000544). !21460 (Takuya Noguchi)
- Fixed persistent XSS rendering/escaping of diff location lines.
- Block link-local addresses in URLBlocker.

### Removed (1 change)

- Remove Gemnasium service. !21185

### Fixed (83 changes, 24 of them are from the community)

- Hide PAT creation advice for HTTP clone if PAT exists. !18208 (George Thomas @thegeorgeous)
- Allow spaces in wiki markdown links when using CommonMark. !20417
- disable_statement_timeout no longer leak to other migrations. !20503
- Events API now requires the read_user or api scope. !20627 (Warren Parad)
- Fix If-Check the result that a function was executed several times. !20640 (Max Dicker)
- Add migration to cleanup internal_ids inconsistency. !20926
- Fix fallback logic for automatic MR title assignment. !20930 (Franz Liedke)
- Fixed bug when the project logo file is stored in LFS. !20948
- Fix buttons on the new file page wrapping outside of the container. !21015
- Solve tooltip appears under modal. !21017
- Fix Bitbucket Cloud importer omitting replies. !21076
- Fix pipeline fixture seeder. !21088
- Fix blocked user card style. !21095
- Fix empty merge requests not opening in the Web IDE. !21102
- Fix label list item container height when there is no label description. !21106
- Fixes input alignment in user admin form with errors. !21108 (Jacopo Beschi @jacopo-beschi)
- Rails5 fix specs duplicate key value violates unique constraint 'index_gpg_signatures_on_commit_sha'. !21119 (Jasper Maes)
- Add gitlab theme to spam logs pagination. !21145
- Split remembering sorting for issues and merge requests. !21153 (Jacopo Beschi @jacopo-beschi)
- Fix git submodule link for subgroup projects with relative path. !21154
- Fix: Project deletion may not log audit events during group deletion. !21162
- Fix 1px cutoff of emojis. !21180 (gfyoung)
- Auto-DevOps.gitlab-ci.yml: update glibc package to 2.28. !21191 (sgerrand)
- Show google icon in audit log. !21207 (Jan Beckmann)
- Fix bin/secpick error and security branch prefixing. !21210
- Importing a project no longer fails when visibility level holds a string value type. !21242
- Fix attachments not displaying inline with Google Cloud Storage. !21265
- Fix IDE issues with persistent banners. !21283
- Fix "Confidential comments" button not saving in project hooks. !21289
- Bump fog-google to 1.7.0 and google-api-client to 0.23.0. !21295
- Don't use arguments keyword in gettext script. !21296 (gfyoung)
- Fix breadcrumb link to issues on new issue page. !21305 (J.D. Bean)
- Show '< 1%' when percent value evaluated is less than 1 on Stacked Progress Bar. !21306
- API: Catch empty commit messages. !21322 (Robert Schilling)
- Fix SQL error when sorting 2FA-enabled users by name in admin area. !21324
- API: Catch empty code content for project snippets. !21325 (Robert Schilling)
- Avoid nil safe message. !21326 (Yi Siliang)
- Allow date parameters on Issues, Notes, and Discussions API for group owners. !21342 (Florent Dubois)
- Fix remote mirrors failing if Git remotes have not been added. !21351
- Removing a group no longer triggers hooks for project deletion twice. !21366
- Use slugs for default project path and sanitize names before import. !21367
- Vertically centres landscape avatars. !21371 (Vicary Archangel)
- Fix Web IDE unable to commit to same file twice. !21372
- Fix project transfer name validation issues causing a redirect loop. !21408
- Fix Error 500s due to encoding issues when Wiki hooks fire. !21414
- Rails 5: include opclasses in rails 5 schema dump. !21416 (Jasper Maes)
- Bump GitLab Pages to v1.1.0. !21419
- Fix links in RSS feed elements. !21424 (Marc Schwede)
- Allow gaps in multiseries metrics charts. !21427
- Auto-DevOps.gitlab-ci.yml: fix redeploying deleted app gives helm error. !21429
- Use sample data for push event when no commits created. !21440 (Takuya Noguchi)
- Fix importers not assigning a new default group. !21456
- Fix edge cases of JUnitParser. !21469
- Fix breadcrumb link to merge requests on new merge request page. !21502 (J.D. Bean)
- Handle database statement timeouts in usage ping. !21523
- Handles exception during file upload - replaces the stack trace with a small error message. !21528
- Fix closing issue default pattern. !21531 (Samuele Kaplun)
- Fix outdated discussions being shown on Merge Request Changes tab. !21543
- Remove orphaned label links. !21552
- Delete a container registry asynchronously. !21553
- Make MR diff file filter input Clear button functional. !21556
- Replace white spaces in wiki attachments file names. !21569
- API: Use find_branch! in all places. !21614 (Robert Schilling)
- Fixes double +/- on inline diff view. !21634
- Fix broken exports when they include a projet avatar. !21649
- Fix workhorse temp path for namespace uploads. !21650
- Fixed resolved discussions not toggling expanded state on changes tab. !21676
- Update GitLab Shell to v8.3.2. !21701
- Fix absent Click to Expand link on diffs not rendered on first load of Merge Requests Changes tab. !21716
- Update GitLab Shell to v8.3.3. !21750
- Fix import error when archive does not have the correct extension. !21765
- Fixed IDE deleting new files creating wrong state.
- Does not collapse runners section when using pagination.
- Fix Emojis cutting in the right way. (Alexander Popov)
- Fix NamespaceUploader.base_dir for remote uploads.
- Increase width of checkout branch modal box.
- Fixes SVGs for empty states in job page overflowing on mobile.
- Fix checkboxes on runner admin settings - The labels are now clickable.
- Fixed IDE file row scrolling into view when hovering.
- Accept upload files in public/uploads/tmp when using accelerated uploads.
- Include correct CSS file for xterm in environments page.
- Increase padding in code blocks.
- Fix: Project deletion may not log audit events during user deletion.

### Changed (32 changes, 5 of them are from the community)

- Add default avatar to group. !17271 (George Tsiolis)
- Allow project owners to set up forking relation through API. !18104
- Limit navbar search for current project or group for small viewports. !18634 (George Tsiolis)
- Add Noto Color Emoji font support. !19036 (Alexander Popov)
- Update design of project overview page. !20536
- Improve visuals of language bar on projects. !21006
- Migrate NULL wiki_access_level to correct number so we count active wikis correctly. !21030
- Support a custom action, such as proxying to another server, after /api/v4/internal/allowed check succeeds. !21034
- Remove storage path dependency of gitaly install task. !21101
- Support Kubernetes RBAC for GitLab Managed Apps when adding a existing cluster. !21127
- Change 'Backlog' list title to 'Open' in Issue Boards. !21131
- Enable Auto DevOps Instance Wide Default. !21157
- Allow author to vote on their own issue and MRs. !21203
- Truncate branch names and update "commits behind" text in MR page. !21206
- Adds count for different board list types (label lists, assignee lists, and milestone lists) to usage statistics. !21208
- Render files (`.md`) and wikis using CommonMark. !21228
- Show deprecation message on project milestone page for category tabs. !21236
- Remove redundant header from metrics page. !21282
- Add default parameter to branches API. !21294 (Riccardo Padovani)
- Restrict reopening locked issues for non authorized issue authors. !21299
- Send back required object storage PUT headers in /uploads/authorize API. !21319
- Display default status emoji if only message is entered. !21330
- Move badge settings to general settings. !21333
- Move project settings for default branch under "Repository". !21380
- Import all common metrics into database. !21459
- Improved commit panel in Web IDE. !21471
- Administrative cleanup rake tasks now leverage Gitaly. !21588
- Remove health check feature flag in BackgroundMigrationWorker.
- Expose user's id in /admin/users/ show page. (Eva Kadlecova)
- Improved styling of top bar in IDE job trace pane.
- Make terminal button more visible.
- Shows download artifacts button for pipelines on small screens.

### Performance (13 changes, 2 of them are from the community)

- Enable frozen string in rest of app/models/**/*.rb.
- Add background migrations for legacy artifacts. !18615
- Optimize querying User#manageable_groups. !21050
- Incremental rendering with Vue on merge request page. !21063
- Remove redundant ci_builds (status) index. !21070
- Enable frozen in app/mailers/**/*.rb. !21147 (gfyoung)
- Improve performance when fetching related merge requests for an issue. !21237
- Speed up diff comparisons by limiting number of commit messages rendered. !21335
- Write diff highlighting cache upon MR creation (refactors caching). !21489
- Bulk-render commit titles in the tree view to improve performance. !21500
- Enable frozen string in vestigial app files. (gfyoung)
- Disable project avatar validation if avatar has not changed.
- Bitbucket Server importer: Eliminate most idle-in-transaction issues.

### Added (41 changes, 17 of them are from the community)

- API: Protected tags. !14986 (Robert Schilling)
- Include private contributions to contributions calendar. !17296 (George Tsiolis)
- Add an option to whitelist users based on email address as internal when the "New user set to external" setting is enabled. !17711 (Roger Rüttimann)
- Overhaul listing of projects in the group overview page. !20262
- Add the ability to reference projects in comments and other markdown text. !20285 (Reuben Pereira)
- Add branch filter to project webhooks. !20338 (Duana Saskia)
- Allows to cancel a Created job. !20635 (Jacopo Beschi @jacopo-beschi)
- First Improvements made to the contributor on-boarding experience. !20682 (Eddie Stubbington)
- `/tag` quick action on Commit comments. !20694 (Peter Leitzen)
- Allow admins to configure the maximum Git push size. !20758
- Expose all artifacts sizes in jobs api. !20821 (Peter Marko)
- Get the merge base of two refs through the API. !20929
- Add ability to suppress the global "You won't be able to use SSH" message. !21027 (Ævar Arnfjörð Bjarmason)
- API: Add expiration date for shared projects to the project entity. !21104 (Robert Schilling)
- Added tooltips to tree list header. !21138
- #47845 Add failure_reason to job webhook. !21143 (matemaciek)
- Vendor Auto-DevOps.gitlab-ci.yml with new proxy env vars passed through to docker. !21159 (kinolaev)
- Disable Auto DevOps for project upon first pipeline failure. !21172
- Add rake command to migrate archived traces from local storage to object storage. !21193
- Add Czech as an available language. !21201
- Add Galician as an available language. !21202
- Add support for extendable CI/CD config with. !21243
- Disable Web IDE button if user is not allowed to push the source branch. !21288
- Feature flag to disable Hashed Storage migration when renaming a repository. !21291
- Store wiki uploads inside git repository. !21362
- Adds Rubocop rule to enforce class_methods over module ClassMethods. !21379 (Jacopo Beschi @jacopo-beschi)
- Merge request copies all associated issue labels and milestone on creation. !21383
- Add group name badge under group milestone. !21384
- Adds diverged_commits_count field to GET api/v4/projects/:project_id/merge_requests/:merge_request_iid. !21405 (Jacopo Beschi @jacopo-beschi)
- Update Import/Export to only use new storage uploaders logic. !21409
- Ask user explicitly about usage stats agreement on single user deployments. !21423
- Added atom feed for tags. !21428
- Add search to a group labels page. !21480
- Display banner on project page if AutoDevOps is implicitly enabled. !21503
- Recognize 'UNLICENSE' license files. !21508 (J.D. Bean)
- Add git_v2 feature flag. !21520
- Added file templates to the Web IDE.
- Enabled multiple file uploads in the Web IDE.
- Allow to delete group milestones.
- Use separate model for tracking resource label changes and render label system notes based on data from this model.
- Add system note when due date is changed. (Eva Kadlecova)

### Other (48 changes, 16 of them are from the community)

- Remove extra spaces from MR discussion notes. !18946 (Takuya Noguchi)
- Add an example of the configuration of archive trace cron worker in gitlab.yml.example. !20583
- Add target branch name to cherrypick confirmation message. !20846 (George Andrinopoulos)
- CE Port of Protected Environments backend. !20859
- Added missing i18n strings to issue boards lables dropdown. !21081
- Combines emoji award spec files into single user_interacts_with_awards_in_issue_spec.rb file. !21126 (Nate Geslin)
- Clarify current runners online text. !21151 (Ben Bodenmiller)
- Rails5: Enable verbose query logs. !21231 (Jasper Maes)
- Update presentation for SSO providers on log in page. !21233
- Make margin of user status emoji consistent. !21268
- Move usage ping payload from User Cohorts page to admin application settings. !21343
- Add JSON logging for Bitbucket Server importer. !21378
- Re-add project name field on "Create new project" page. !21386
- Rails 5: replace removed silence_stream. !21387 (Jasper Maes)
- Rails5 update Gemfile.rails5.lock. !21388 (Jasper Maes)
- Rails5: fix can't quote ActiveSupport::HashWithIndifferentAccess. !21397 (Jasper Maes)
- Don't show flash messages for performance bar errors. !21411
- Backport schema_changed.sh from EE which prints the diff if the schema is different. !21422 (Jasper Maes)
- Remove unused CSS part in mobile framework. !21439 (Takuya Noguchi)
- Bump unauthenticated session time from 1 hour to 2 hours. !21453
- Run review-docs-cleanup job for gitlab-org repos only. !21463 (Takuya Noguchi)
- Rails 5: support schema t.index for mysql. !21485 (Jasper Maes)
- Add route information to lograge structured logging for API logs. !21487
- Add gitaly_calls attribute to API logs. !21496
- Ignore irrelevant sql commands in metrics. !21498
- Rails 5: fix hashed_path? method that looks up file_location that doesn't exist when running certain migration specs. !21510 (Jasper Maes)
- Explicit hashed path check for trace, prevents background migration from accessing file_location column that doesn't exist. !21533 (Jasper Maes)
- Add terminal_path to job API response. !21537
- Add User-Agent to production_json.log. !21546
- Make cluster page settings easier to read. !21550
- Remove striped table styling of Find files and Admin Area Applications views. !21560 (Andreas Kämmerle)
- Update ffi to 1.9.25. !21561 (Takuya Noguchi)
- Send max_patch_bytes to Gitaly via Gitaly::CommitDiffRequest. !21575
- Add margin between username and subsequent text in issuable header. !21697
- Send artifact information in job API. !50460
- Reduce differences between CE and EE code base in reports components.
- Move project services log to a separate file.
- Creates vue component for job log top bar with controllers.
- Creates Vue component for trigger variables block in job log page.
- Creates Vvue component for warning block about stuck runners.
- Creates vue component for job log trace.
- Creates vue component for erased block on job view.
- Creates vue component for environments information in job log view.
- Upgrade Monaco editor.
- Creates empty state vue component for job view.
- Creates vue component for commit block in job log page.
- Creates vue components for stage dropdowns and job list container for job log view.
- Creates Vue component for artifacts block on job page.


## 11.2.8 (2018-10-31)

### Security (1 change)

- Monkey kubeclient to not follow any redirects.


## 11.2.7 (2018-10-27)

- No changes.

## 11.2.6 (2018-10-26)

### Security (5 changes)

- Escape entity title while autocomplete template rendering to prevent XSS. !2558
- Fix XSS in merge request source branch name.
- Redact personal tokens in unsubscribe links.
- Persist only SHA digest of PersonalAccessToken#token.
- Prevent SSRF attacks in HipChat integration.


## 11.2.5 (2018-10-05)

### Security (3 changes)

- Filter user sensitive data from discussions JSON. !2538
- Properly filter private references from system notes.
- Markdown API no longer displays confidential title references unless authorized.


## 11.2.4 (2018-09-26)

### Security (6 changes)

- Redact confidential events in the API.
- Set timeout for syntax highlighting.
- Sanitize JSON data properly to fix XSS on Issue details page.
- Fix stored XSS in merge requests from imported repository.
- Fix xss vulnerability sourced from package.json.
- Block loopback addresses in UrlBlocker.


## 11.2.3 (2018-08-28)

### Fixed (1 change)

- Fixed cache invalidation issue with diff lines from 11.2.2.

## 11.2.2 (2018-08-27)

### Security (3 changes)

- Fixed persistent XSS rendering/escaping of diff location lines.
- Adding CSRF protection to Hooks resend action.
- Block link-local addresses in URLBlocker.


## 11.2.1 (2018-08-22)

### Fixed (2 changes)

- Fix wrong commit count in push event payload. !21338
- Fix broken Git over HTTP clones with LDAP users. !21352

### Performance (1 change)

- Eliminate unnecessary and duplicate system hook fires. !21337


## 11.2.0 (2018-08-22)

### Security (5 changes)

- Bump Gitaly to 0.117.1 for Rouge update. !21277
- Fix symlink vulnerability in project import.
- Bump rugged to 0.27.4 for security fixes.
- Fixed XSS in branch name in Web IDE.
- Adding CSRF protection to Hooks test action.

### Removed (1 change)

- Remove gitlab:user:check_repos, gitlab:check_repo, gitlab:git:prune, gitlab:git:gc, and gitlab:git:repack. !20806

### Fixed (81 changes, 26 of them are from the community)

- Fix namespace move callback behavior, especially to fix Geo replication of namespace moves during certain exceptions. !19297
- Fix breadcrumbs in Admin/User interface. !19608 (Robin Naundorf)
- Remove changes_count from MR API documentation where necessary. !19745 (Jan Beckmann)
- Fix email confirmation bug when user adds additional email to account. !20084 (muhammadn)
- Add support for daylight savings time to pipleline schedules. !20145
- Fixing milestone date change when editing. !20279 (Orlando Del Aguila)
- Add missing maximum_timeout parameter. !20355 (gfyoung)
- [Rails5] Fix 'Invalid single-table inheritance type: Group is not a subclass of Gitlab::BackgroundMigration::FixCrossProjectLabelLinks::Namespace'. !20462 (@blackst0ne)
- Rails5 fix mysql milliseconds problem in specs. !20464 (Jasper Maes)
- Update Gemfile.rails5.lock with latest Gemfile.lock changes. !20466 (Jasper Maes)
- Rails5 mysql fix milliseconds problem in pull request importer spec. !20475 (Jasper Maes)
- Rails5 MySQL fix rename_column as part of cleanup_concurrent_column_type_change. !20514 (Jasper Maes)
- Process commits as normal in forks when the upstream project is deleted. !20534
- Fix project visibility tooltip. !20535 (Jamie Schembri)
- Fix archived parameter for projects API. !20566 (Peter Marko)
- Limit maximum project build timeout setting to 1 month. !20591
- Fix GitLab project imports not loading due to API timeouts. !20599
- Avoid process deadlock in popen by consuming input pipes. !20600
- Disable SAML and Bitbucket if OmniAuth is disabled. !20608
- Support multiple scopes when authing container registry scopes. !20617
- Adds the ability to view group milestones on the dashboard milestone page. !20618
- Allow issues API to receive an internal ID (iid) on create. !20626 (Jamie Schembri)
- Fix typo in CSS transform property for Memory Graph component. !20650
- Update design for system metrics popovers. !20655
- Toggle Show / Hide Button for Kubernetes Password. !20659 (gfyoung)
- Board label edit dropdown shows incorrect selected labels summary. !20673
- Resolve "Unable to save user profile update with Safari". !20676
- Escape username and password in UrlSanitizer#full_url. !20684
- Remove background color from card-body style. !20689 (George Tsiolis)
- Update total storage size when changing size of artifacts. !20697 (Peter Marko)
- Rails5 fix user sees revert modal spec. !20706 (Jasper Maes)
- Fix Web IDE crashing on directories named 'blob'. !20712
- Fix accessing imported pipeline builds. !20713
- Fixed bug with invalid repository reference using the wiki search. !20722
- Resolve Copy diff file path as GFM is broken. !20725
- Chart versions for applications installed by one click install buttons should be version locked. !20765
- Fix misalignment of broadcast message on login page. !20794 (Robin Naundorf)
- Fix Vue datatype errors for markdownVersion parsing. !20800
- Fix authorization for interactive web terminals. !20811
- Increase width of Web IDE sidebar resize handles. !20818
- Fix new MR card styles. !20822
- Fix link color in markdown code brackets. !20841
- Rails5 update Gemfile.rails5.lock. !20858 (Jasper Maes)
- fix height of full-width Metrics charts on large screens. !20866
- Fix sorting by name on milestones page. !20881
- Permit concurrent loads in gpg keychain mutex. !20894 (Jasper Maes)
- Prevent editing and updating wiki pages with non UTF-8 encoding via web interface. !20906
- Retrieve merge request closing issues from database cache. !20911
- Fix LFS uploads not working with git-lfs 2.5.0. !20923
- Fix bug setting http headers in Files API. !20938
- Rails5: fix flaky spec. !20953 (Jasper Maes)
- Fixed list of projects not loading in group boards. !20955
- Fix autosave and ESC confirmation issues for MR discussions. !20968
- Fix navigation to First and Next discussion on MR Changes tab. !20968
- Fix rendering of the context lines in MR diffs page. !20968
- fix error caused when using the search bar while unauthenticated. !20970
- Fix GPG status badge loading regressions. !20987
- Ensure links in notifications footer are not escaped. !21000
- Rails5: update Rails5 lock for forgotten gem rouge. !21010 (Jasper Maes)
- Fix UI error whereby prometheus application status is updated. !21029
- Solves group dashboard line height is too tall for group names. !21033
- Fix rendering of pipeline failure view when directly navigationg to it. !21043
- Fix missing and duplicates on project milestone listing page. !21058
- Fix merge requests not showing any diff files for big patches. !21125
- Auto-DevOps.gitlab-ci.yml: Update glibc package signing key URL. !21182 (sgerrand)
- Fix issue stopping Instance Statistics javascript to be executed. !21211
- Fix broken JavaScript in IE11. !21214
- Improve JUnit test reports in merge request widgets. !49966
- Properly handle colons in URL passwords.
- Renders test reports for resolved failures and resets error state.
- Fix handling of annotated tags when Gitaly is not in use.
- Fix serialization of LegacyDiffNote.
- Escapes milestone and label's names on flash notice when promoting them.
- Allow to toggle notifications for issues due soon.
- Sanitize git URL in import errors. (Jamie Schembri)
- Add missing predefined variable and fix docs.
- Allow updating a project's avatar without other params. (Jamie Schembri)
- Fix the UI for listing system-level labels.
- Update hamlit to fix ruby 2.5 incompatibilities, fixes #42045. (Matthew Dawson)
- Fix updated_at if created_at is set for Note API.
- Fix search bar text input alignment.

### Changed (32 changes, 7 of them are from the community)

- Rack attack is now disabled by default. !16669
- Include full image URL in webhooks for uploaded images. !18109 (Satish Perala)
- Enable hashed storage for all newly created or renamed projects. !19747
- Support manually stopping any environment from the UI. !20077
- Close revert and cherry pick modal on escape keypress. !20341 (George Tsiolis)
- Adds with_projects optional parameter to GET /groups/:id API endpoint. !20494
- Improve feedback when a developer is unable to push to an empty repository. !20519
- Display GPG status on repository and blob pages. !20524
- Updated design of new entry dropdown in Web IDE. !20526
- UX improvements to top nav search bar. !20537
- Update issue closing pattern. !20554 (George Tsiolis)
- Add merge request header branch actions left margin. !20643 (George Tsiolis)
- Rubix, scikit-learn, tensorflow & other useful libraries pre-installed with JupyterHub. !20714 (Amit Rathi)
- Show decimal place up to single digit in Stacked Progress Bar. !20776
- Wrap job name on pipeline job sidebar. !20804 (George Tsiolis)
- Redesign Web IDE back button and context header. !20850
- Removes "show all" on reports and adds an actionButtons slot. !20855
- Put fallback reply-key address first in the References header. !20871
- Allow non-admins to view instance statistics (if permitted by the instance admins). !20874
- Adds the project and group name to the return type for project and group milestones. !20890
- Restyle status message input on profile settings. !20903
- Ensure installed Helm Tiller For GitLab Managed Apps Is protected by mutual auth. !20928
- Allow multiple JIRA transition ids. !20939
- Use Helm 2.7.2 for GitLab Managed Apps. !20956
- Create branch and MR picker for Web IDE. !20978
- Update commit message styles with monospace font and overflow-x. !20988
- Update to Rouge 3.2.0, including Terraform and Crystal lexer and bug fixes. !20991
- Update design of project templates. !21012
- Update to Rouge 3.2.1, which includes a critical fix to the Perl Lexer. !21263
- Add a 10 ms bucket for SQL timings.
- Show one digit after dot in commit_per_day value in charts page. (msdundar)
- Redesign GCP offer banner.

### Performance (30 changes, 10 of them are from the community)

- Stop dynamically creating project and namespace routes. !20313
- Tracking the number of repositories and wikis with a cached counter for site-wide statistics. !20413
- Optimize ProjectWiki#empty? check. !20573
- Delete UserActivities and related workers. !20597
- Enable frozen string in app/services/**/*.rb. !20656 (gfyoung)
- Enable more frozen string in app/services/**/*.rb. !20677 (gfyoung)
- Limit the TTL for anonymous sessions to 1 hour. !20700
- Enable even more frozen string in app/services/**/*.rb. !20702 (gfyoung)
- Enable frozen string in app/serializers/**/*.rb. !20726 (gfyoung)
- Enable frozen string in newly added files to previously processed directories. !20763 (gfyoung)
- Use limit parameter to retrieve Wikis from Gitaly. !20764
- Add Dangerfile for frozen_string_literal. !20767 (gfyoung)
- Remove method instrumentation for Banzai filters and reference parsers. !20770
- Enable frozen strings in lib/banzai/filter/*.rb. !20775
- Enable frozen strings in remaining lib/banzai/filter/*.rb files. !20777
- DNS prefetching if asset_host for CDN hosting is set. !20781
- Bump nokogiri to 1.8.4 and sanitize to 4.6.6 for performance. !20795
- Enable frozen string in app/presenters and app/policies. !20819 (gfyoung)
- Bump haml gem to 5.0.4. !20847
- Enable frozen string in app/models/*.rb. !20851 (gfyoung)
- Performing Commit GPG signature calculation in bulk. !20870
- Fix /admin/jobs failing to load due to statement timeout. !20909
- refactor pipeline job log animation to reduce CPU usage. !20915
- Improve performance when fetching collapsed diffs and commenting in merge requests. !20940
- Enable frozen string for app/models/**/*.rb. !21001 (gfyoung)
- Don't set gon variables in JSON requests. !21016 (Peter Leitzen)
- Improve performance and memory footprint of Changes tab of Merge Requests. !21028
- Avoid N+1 on MRs page when metrics merging date cannot be found. !21053
- Bump Gitaly to 0.117.0. !21055
- Access metadata directly from Object Storage.

### Added (41 changes, 18 of them are from the community)

- Show repository languages for projects. !19480
- Adds API endpoint /api/v4/(project/group)/:id/members/all to list also inherited members. !19748 (Jacopo Beschi @jacopo-beschi)
- Added live preview for JavaScript projects in the Web IDE. !19764
- Add support for SSH certificate authentication. !19911 (Ævar Arnfjörð Bjarmason)
- Add Hangouts Chat integration. !20290 (Kukovskii Vladimir)
- Add ability to import multiple repositories by uploading a manifest file. !20304
- Show Project ID on project home panel. !20305 (Tuğçe Nur Taş)
- Add an option to have a private profile on GitLab. !20387 (jxterry)
- Extend gitlab-ci.yml to request junit.xml test reports. !20390
- Add the first mutations for merge requests to GraphQL. !20443
- Add /-/health basic health check endpoint. !20456
- Add filter for minimal access level in groups and projects API. !20478 (Marko, Peter)
- Add download button for single file (including raw files) in repository. !20480 (Kia Mei Somabes)
- Gitaly Servers link into Admin > Overview navigation menu. !20550
- Adds foreign key to notification_settings.user_id. !20567 (Jacopo Beschi @jacopo-beschi)
- JUnit XML Test Summary In MR widget. !20576
- Cleans up display of Deploy Tokens to match Personal Access Tokens. !20578 (Marcel Amirault)
- Users can set a status message and emoji. !20614 (niedermyer & davamr)
- Add emails delivery Prometheus metrics. !20638
- Verify runner feature set. !20664
- Add more comprehensive metrics tracking authentication activity. !20668
- Add support for tar.gz AUTO_DEVOPS_CHART charts (#49324). !20691 (@kondi1)
- Adds Vuex store for reports section in MR widget. !20709
- Redirect commits to root if no ref is provided (31576). !20738 (Kia Mei Somabes)
- Search for labels by title or description on project labels page. !20749
- Add object storage logic to project import. !20773
- Enable renaming files and folders in Web IDE. !20835
- Warn user when reload IDE with staged changes. !20857
- Add local project uploads cleanup task. !20863
- Improve error message when adding invalid user to a project. !20885 (Jacopo Beschi @jacopo-beschi)
- Add link to homepage on static http status pages (404, 500, etc). !20898 (Jason Funk)
- Clean orphaned files in object storage. !20918
- Adds frontend support to render test reports on the MR widget. !20936
- Trigger system hooks when project is archived/unarchived. !20995
- Custom Wiki Sidebar Support Issue 14995. (Josh Sooter)
- Emails on push recipients now accepts formats like John Doe <johndoe@example.com>. (George Thomas)
- Add new model for tracking label events.
- Improve danger confirmation modals by focusing input field. (Jamie Schembri)
- Clicking CI icon in Web IDE now opens up pipelines panel.
- Enabled deletion of files in the Web IDE.
- Added button to regenerate 2FA codes. (Luke Picciau)

### Other (26 changes, 7 of them are from the community)

- Update specific runners help URL. !20213 (George Tsiolis)
- Enable frozen string in apps/uploaders/*.rb. !20401 (gfyoung)
- Update docs of Helm Tiller. !20515 (Takuya Noguchi)
- Persist 'Auto DevOps' banner dismissal globally. !20540
- Move xterm to a node dependency and remove it from vendor's folder. !20588
- Upgrade grape-path-helpers to 1.0.6. !20601
- Delete todos when user loses access to read the target. !20665
- Remove tooltips from commit author avatar and name in commit lists. !20674
- Allow cloning LFS repositories through DeployTokens. !20729
- Replace 'Sidekiq::Testing.inline!' with 'perform_enqueued_jobs'. !20768 (@blackst0ne)
- Replace author_link snake case in stylesheets, specs, and helpers. !20797 (George Tsiolis)
- Replace snake case in SCSS variables. !20799 (George Tsiolis)
- Add rbtrace to Gemfile. !20831
- Add support for searching users by confirmed e-mails. !20893
- Changes poll.js to keep polling on any 2xx http status code. !20904
- Remove todos of users without access to targets migration. !20927
- Improve and simplify Auto DevOps settings flow. !20946
- Keep admin settings sections open after submitting forms. !21040
- CE port of "List groups with developer maintainer access on project creation". !21051
- Update git rerere link in docs. !21060 (gfyoung)
- Add 'tabindex' attribute support on Icon component to show BS4 popover on trigger type 'focus'. !21066
- Add a Gitlab::Profiler.print_by_total_time convenience method for profiling from a Rails console.
- Automatically expand runner's settings block when linking to the runner's settings page.
- Increases title column on modal for reports.
- Disables toggle comments button if diff has no discussions.
- Moves help_popover component to a common location.


## 11.1.8 (2018-10-05)

### Security (3 changes)

- Filter user sensitive data from discussions JSON. !2539
- Properly filter private references from system notes.
- Markdown API no longer displays confidential title references unless authorized.


## 11.1.7 (2018-09-26)

### Security (6 changes)

- Redact confidential events in the API.
- Set timeout for syntax highlighting.
- Sanitize JSON data properly to fix XSS on Issue details page.
- Fix stored XSS in merge requests from imported repository.
- Fix xss vulnerability sourced from package.json.
- Block loopback addresses in UrlBlocker.


## 11.1.6 (2018-08-28)

### Fixed (1 change)

- Fixed cache invalidation issue with diff lines from 11.2.2.

## 11.1.5 (2018-08-27)

### Security (3 changes)

- Fixed persistent XSS rendering/escaping of diff location lines.
- Adding CSRF protection to Hooks resend action.
- Block link-local addresses in URLBlocker.

### Fixed (1 change, 1 of them is from the community)

- Sanitize git URL in import errors. (Jamie Schembri)


## 11.1.4 (2018-07-30)

### Fixed (4 changes, 1 of them is from the community)

- Rework some projects table indexes around repository_storage field. !20377
- Don't overflow project/group dropdown results. !20704 (gfyoung)
- Fixed IDE not opening JSON files. !20798
- Disable Gitaly timeouts when creating or restoring backups. !20810

## 11.1.3 (2018-07-27)

- Not released.

## 11.1.2 (2018-07-26)

### Security (4 changes)

- Adding CSRF protection to Hooks test action.
- Don't expose project names in GitHub counters.
- Don't expose project names in various counters.
- Fixed XSS in branch name in Web IDE.

### Fixed (1 change)

- Escapes milestone and label's names on flash notice when promoting them.

### Performance (1 change)

- Fix slow Markdown rendering. !20820


## 11.1.1 (2018-07-23)

### Fixed (2 changes)

- Add missing Gitaly branch_update nil checks. !20711
- Fix filename for accelerated uploads.

### Added (1 change)

- Add uploader support to Import/Export uploads. !20484


## 11.1.0 (2018-07-22)

### Security (6 changes)

- Fix XSS vulnerability for table of content generation.
- Update sanitize gem to 4.6.5 to fix HTML injection vulnerability.
- HTML escape branch name in project graphs page.
- HTML escape the name of the user in ProjectsHelper#link_to_member.
- Don't show events from internal projects for anonymous users in public feed.
- Fix symlink vulnerability in project import.

### Removed (1 change)

- Remove deprecated object_storage_upload queue.

### Fixed (98 changes, 52 of them are from the community)

- Keep lists ordered when copying only list items. !18522 (Jan Beckmann)
- Fix bug where maintainer would not be allowed to push to forks with merge requests that have `Allow maintainer edits` enabled. !18968
- mergeError message has been binded using v-html directive. !19058 (Murat Dogan)
- Set MR target branch to default branch if target branch is not valid. !19067
- Fix CSS for buttons not to be hidden on issues/MR title. !19176 (Takuya Noguchi)
- Use same gem versions for rails5 as for rails4 where possible. !19498 (Jasper Maes)
- Fix extra blank line at start of rendered reStructuredText code block. !19596
- Fix username validation order on signup, resolves #45575. !19610 (Jan Beckmann)
- Make quick commands case insensitive. !19614 (Jan Beckmann)
- Remove incorrect CI doc re: PowerShell. !19622 (gfyoung)
- Fixes Microsoft Teams notifications for pipeline events. !19632 (Jeff Brown)
- Fix branch name encoding for dropdown on issue page. !19634
- Rails5 fix expected `issuable.reload.updated_at` to have changed. !19733 (Jasper Maes)
- Rails5 fix stack level too deep. !19762 (Jasper Maes)
- Rails5 ActionController::ParameterMissing: param is missing or the value is empty: application_setting. !19763 (Jasper Maes)
- Invalidate cache with project details when repository is updated. !19774
- Rails5 fix no implicit conversion of Hash into String. ActionController::Parameters no longer returns an hash in Rails 5. !19792 (Jasper Maes)
- [Rails5] Fix snippets_finder arel queries. !19796 (@blackst0ne)
- Fix fields for author & assignee in MR API docs. !19798 (gfyoung)
- Remove scrollbar in Safari in repo settings page. !19809 (gfyoung)
- Omits operartions and kubernetes item from project sidebar when repository or builds are disabled. !19835
- Rails5 fix passing Group objects array into for_projects_and_groups milestone scope. !19863 (Jasper Maes)
- Fix chat service tag notifications not sending when only default branch enabled. !19864
- Only show new issue / new merge request on group page when issues / merge requests are enabled. !19869 (Jan Beckmann)
- [Rails5] Explicitly set request.format for blob_controller. !19876 (@blackst0ne)
- [Rails5] Fix optimistic lock value. !19878 (@blackst0ne)
- Rails5 fix update_attribute usage not causing a save. !19881 (Jasper Maes)
- Rails5 fix connection execute return integer instead of string. !19901 (Jasper Maes)
- Rails5 fix format in uploads actions. !19907 (Jasper Maes)
- [Rails5] Fix "-1 is not a valid data_store". !19917 (@blackst0ne)
- [Rails5] Invalid single-table inheritance type: Group is not a subclass of Namespace. !19918 (@blackst0ne)
- [Rails5] Fix pipeline_schedules_controller_spec. !19919 (@blackst0ne)
- Rails5 fix passing Group objects array into for_projects_and_groups milestone scope. !19920 (Jasper Maes)
- Rails5 update Gemfile.rails5.lock. !19921 (Jasper Maes)
- [Rails5] Fix sessions_controller_spec. !19936 (@blackst0ne)
- [Rails5] Set request.format for artifacts_controller. !19937 (@blackst0ne)
- Fix webhook error when password is not present. !19945 (Jan Beckmann)
- Fix label and milestone duplicated records and IID errors. !19961
- Rails5 fix expected: 1 time with arguments: (97, anything, {"squash"=>false}) received: 0 times. !20004 (Jasper Maes)
- Rails5 fix Projects::PagesController spec. !20007 (Jasper Maes)
- [Rails5] Fix ActionCable '/cable' mountpoint conflict. !20015 (@blackst0ne)
- Fix branches are not shown in Merge Request dropdown when preferred language is not English. !20016 (Hiroyuki Sato)
- Rails5 fix Admin::HooksController. !20017 (Jasper Maes)
- Rails5 fix  expected: 0 times with any arguments received: 1 time with arguments: DashboardController. !20018 (Jasper Maes)
- [Rails5] Set request.format in commits_controller. !20023 (@blackst0ne)
- Keeps the label on an issue when the issue is moved. !20036
- Cleanup Prometheus ruby metrics. !20039 (Ben Kochie)
- Rails 5 fix Capybara::ElementNotFound: Unable to find visible css #modal-revert-commit and expected: "/bar" got: "/foo". !20044 (Jasper Maes)
- [Rails5] Force the callback run first. !20055 (@blackst0ne)
- Add readme button to non-empty project page. !20104
- Fixed bug when editing a comment in an issue,the preview mode is toggled in the main textarea. !20112 (Constance Okoghenun)
- Ignore unknown OAuth sources in ApplicationSetting. !20129
- Fix paragraph line height for emoji. !20137 (George Tsiolis)
- Fixes issue with uploading same image to Profile Avatar twice. !20161 (Chirag Bhatia)
- Rails5 fix arel from in mysql_median_datetime_sql. !20167 (Jasper Maes)
- Adds the `locked` state to the merge request API so that it can be used as a search filter. !20186
- Enable Doorkeeper option to avoid generating new tokens when users login via oauth. !20200
- Fix OAuth Application Authorization screen to appear with each access. !20216
- Rails5 fix MySQL milliseconds problem in specs. !20221 (Jasper Maes)
- Rails5 fix Mysql comparison failure caused by milliseconds problem. !20222 (Jasper Maes)
- Updated last commit link color. !20234 (Constance Okoghenun)
- Fixed Merge request changes dropdown displays incorrectly. !20237 (Constance Okoghenun)
- Show jobs from same pipeline in sidebar in job details view. !20243
- [Rails5] Fix milestone GROUP BY query. !20256 (@blackst0ne)
- Line separator to the left of the 'Admin area' wrench icon had vanished. !20282 (bitsapien)
- Check if archived trace exist before archive it. !20297
- Load Devise with Omniauth when auto_sign_in_with_provider is configured. !20302
- Fix link to job when creating a new issue from a failed job. !20328
- Fix double "in" in time to artifact deletion message. !20357 (@bbodenmiller)
- Fix wrong role badge displayed in projects dashboard. !20374
- Stop relying on migrations in the CacheableAttributes cache key and cache attributes for 1 minute instead. !20389
- Fixes toggle discussion button not expanding collapsed discussions. !20452
- Resolve compatibility issues with node 6. !20461
- Fixes base command used in Helm installations. !20471
- Fix RSS button interaction on Dashboard, Project and Group activities. !20549
- Use appropriate timeout on Gitaly server info checks, avoid error on timeout. !20552
- Remove healthchecks from prometheus endpoint. !20565
- Render MR page when diffs cannot be fetched from the database or the git repository. !20680
- Expire correct method caches after HEAD changed.
- Ensure MR diffs always exist in the PR importer.
- Fix overlapping file title and file actions in MR changes tag.
- Mark MR as merged regardless of errors when closing issues.
- Fix performance bar modal visibility in Safari.
- Prevent browser autocomplete for milestone date fields.
- Limit the action suffixes in transaction metrics.
- Add /uploads subdirectory to allowed upload paths.
- Fix cross-project label references.
- Invalidate merge request diffs cache if diff data change.
- Don't show context button for diffs of deleted files.
- Structure getters for diff Store properly and adds specs.
- Bump rugged to 0.27.2.
- Fix Bamboo CI status not showing for branch plans.
- Fixed bug that allowed to remove other wiki pages if the title had wildcard characters.
- Disabled Web IDE autocomplete suggestions for Markdown files. (Isaac Smith)
- Fix merge request diffs when created with gitaly_diff_between enabled.
- Properly detect label reference if followed by period or question mark.
- Deactivate new KubernetesService created from active template to prevent project creation from failing.
- Allow trailing whitespace on blockquote fence lines.

### Deprecated (1 change)

- Removes unused bootstrap 4 scss files. !19423

### Changed (33 changes, 16 of them are from the community)

- Change label link vertical alignment property. !18777 (George Tsiolis)
- Updated the icon for expand buttons to ellipsis. !18793 (Constance Okoghenun)
- Create new or add existing Kubernetes cluster from a single page. !18963
- Use object storage as the first class persistable store for new live trace architecture. !19515
- Hide project name if searching against a project. !19595
- Allows you to create another deploy token dimmediately after creating one. !19639
- Removes the environment scope field for users that cannot edit it. !19643
- Don't hash user ID in OIDC subject claim. !19784 (Markus Koller)
- Milestone page list redesign. !19832 (Constance Okoghenun)
- Add environment dropdown for the metrics page. !19833
- Allow querying a single merge request within a project. !19853
- Update WebIDE to show file in tree on load. !19887
- Remove small container width. !19893 (George Tsiolis)
- Improve U2F workflow when using unsupported browsers. !19938 (Jan Beckmann)
- Update Web IDE file tree styles. !19969
- Highlight cluster settings message. !19996 (George Tsiolis)
- Fade uneditable area in Web IDE. !20008
- Update pipeline icon in web ide sidebar. !20058 (George Tsiolis)
- Revert merge request discussion buttons padding. !20060 (George Tsiolis)
- Fix boards issue highlight. !20063 (George Tsiolis)
- Update external link icon in header user dropdown. !20150 (George Tsiolis)
- Update external link icon in merge request widget. !20154 (George Tsiolis)
- Update environments nav controls icons. !20199 (George Tsiolis)
- Update integrations external link icons. !20205 (George Tsiolis)
- Fixes an issue where migrations instead of schema loading were run. !20227
- Add title placeholder for new issues. !20271 (George Tsiolis)
- Close revoke deploy token modal on escape keypress. !20347 (George Tsiolis)
- Change environment scope text depending on number of project clusters. Update form to only include form-groups.
- Improve Web IDE commit flow.
- Add machine type and pricing documentation links, add class to labels to make bold.
- Remove remaining traces of the Allocations Gem.
- Use one column form layout on Admin Area Settings page.
- Add back copy for existing gcp accounts within offer banner.

### Performance (16 changes, 4 of them are from the community)

- Fully migrate pipeline stages position. !19369
- Use Tooltip component in MrWidgetAuthorTime vue comonent. !19635 (George Tsiolis)
- Move boards modal EmptyState vue component. !20068 (George Tsiolis)
- Bump carrierwave gem verion to 1.2.3. !20287
- Remove redundant query when removing trace. !20324
- Improves performance of mr code, by fixing the state being mutated outside of the store in the util function trimFirstCharOfLineContent and in map operations. Avoids map operation in an empty array. Adds specs to the trimFirstCharOfLineContent function. !20380 (filipa)
- Reduce the number of queries when searching for groups. !20398
- Improve render performance of large wiki pages. !20465 (Peter Leitzen)
- Improves performance on Merge Request diff tab by removing the scroll event listeners being added to every file.
- Remove the ci_job_request_with_tags_matcher.
- Updated Gitaly fail-fast timeout values.
- Add index on deployable_type/id for deployments.
- Eliminate N+1 queries in LFS file locks checks during a push.
- Fix performance problem of accessing tag list for projects api endpoints.
- Improve performance of listing users without projects.
- Fixed pagination of web hook logs.

### Added (29 changes, 9 of them are from the community)

- Add dropdown to Groups link in top bar. !18280
- Web IDE supports now Image + Download Diff Viewing. !18768
- Use CommonMark syntax and rendering for new Markdown content. !19331
- Add SHA256 and HEAD on File API. !19439 (ahmet2mir)
- Add filename filtering to code search. !19509
- Add CI_PIPELINE_URL and CI_JOB_URL. !19618
- Expose visibility via Snippets API. !19620 (Jan Beckmann)
- Fixed pagination of groups API. !19665 (Marko, Peter)
- Added id sorting option to GET groups and subgroups API. !19665 (Marko, Peter)
- Add a link to the contributing page in the user dropdown. !19708
- Add Object Storage to project export. !20105
- Change avatar image in the header when user updates their avatar. !20119 (Jamie Schembri)
- Allow straight diff in Compare API. !20120 (Maciej Nowak)
- Add transfer project API endpoint. !20122 (Aram Visser)
- Expose permissions of the current user on resources in GraphQL. !20152
- Run repository checks in parallel for each shard. !20179
- Add pipeline lists to GraphQL. !20249
- Add option to add README when creating a project. !20335
- Add option to hide third party offers in admin application settings. !20379
- Add /confidential quick action. (Jan Beckmann)
- Support direct_upload for generic uploads.
- Display merge request title & description in Web IDE.
- Prune web hook logs older than 90 days.
- Add Web Terminal for Ci Builds. (Vicky Chijwani)
- Expose whether current user can push into a branch on branches API.
- Present state indication on GFM preview.
- migrate backup rake task to gitaly.
- Add Gitlab::SQL:CTE for easily building CTE statements.
- Added with_statsoption for GET /projects/:id/repository/commits.

### Other (28 changes, 11 of them are from the community)

- Move some Gitaly RPC's to opt-out. !19591
- Bump grape-path-helpers to 1.0.5. !19604 (@blackst0ne)
- Add CI job to check Gemfile.rails5.lock. !19605 (@blackst0ne)
- Move Gitaly branch/tag/ref RPC's to opt-out. !19644
- CE port gitlab-ee!6112. !19714
- Enable no-multi-assignment in JS files. !19808 (gfyoung)
- Enable no-restricted globals in JS files. !19877 (gfyoung)
- Improve no-multi-assignment fixes after enabling rule. !19915 (gfyoung)
- Enable prefer-structuring in JS files. !19943 (gfyoung)
- Enable frozen string in app/workers/*.rb. !19944 (gfyoung)
- Uses long sha version of the merged commit in MR widget copy to clipboard button. !19955
- Update new group page to better explain what groups are. !19991
- Update new SSH key page to improve copy. !19994
- Update new SSH key page to improve key input validation. !19997
- Gitaly metrics check for read/writeability. !20022
- Add ellispsis to web ide commit button. !20030
- Minor style changes to personal access token form and scope checkboxes. !20052
- Finish enabling frozen string for app/workers/*.rb. !20197 (gfyoung)
- Allows settings sections to expand by default when linking to them. !20211
- Enable frozen string in apps/validators/*.rb. !20220 (gfyoung)
- update bcrypt to also support libxcrypt. !20260 (muhammadn)
- Enable frozen string in apps/validators/*.rb. !20382 (gfyoung)
- Removes unused vuex code in mr refactor and removes unneeded dependencies. !20499
- Delete non-latest merge request diff files upon merge.
- Schedule workers to delete non-latest diffs in post-migration.
- Remove the use of `is_shared` of `Ci::Runner`.
- Add more detailed logging to githost.log when rebasing.
- Use monospaced font for MR diff commit link ref on GFM.


## 11.0.6 (2018-08-27)

### Security (3 changes)

- Fixed persistent XSS rendering/escaping of diff location lines.
- Adding CSRF protection to Hooks resend action.
- Block link-local addresses in URLBlocker.

### Fixed (1 change, 1 of them is from the community)

- Sanitize git URL in import errors. (Jamie Schembri)


## 11.0.5 (2018-07-26)

### Security (4 changes)

- Don't expose project names in various counters.
- Don't expose project names in GitHub counters.
- Adding CSRF protection to Hooks test action.
- Fixed XSS in branch name in Web IDE.

### Fixed (1 change)

- Escapes milestone and label's names on flash notice when promoting them.


## 11.0.4 (2018-07-17)

### Security (1 change)

- Fix symlink vulnerability in project import.


## 11.0.3 (2018-07-05)

### Fixed (14 changes, 1 of them is from the community)

- Revert merge request widget button max height. !20175 (George Tsiolis)
- Implement upload copy when moving an issue with upload on object storage. !20191
- Fix broken '!' support to autocomplete MRs in GFM fields. !20204
- Restore showing Elasticsearch and Geo status on dashboard. !20276
- Fix merge request page rendering error when its target/source branch is missing. !20280
- Fix sidebar collapse breapoints for job and wiki pages.
- fix size of code blocks in headings.
- Fix loading screen for search autocomplete dropdown.
- Fix ambiguous due_date column for Issue scopes.
- Always serve favicon from main GitLab domain so that CI badge can be drawn over it.
- Fix tooltip flickering bug.
- Fix refreshing cache keys for open issues count.
- Replace deprecated bs.affix in merge request tabs with sticky polyfill.
- Prevent pipeline job tooltip from scrolling off dropdown container.


## 11.0.2 (2018-06-26)

### Fixed (8 changes, 1 of them is from the community)

- Serve favicon image always from the main GitLab domain to avoid issues with CORS. !19810 (Alexis Reigel)
- Specify chart version when installing applications on Clusters. !20010
- Fix invalid fuzzy translations being generated during installation. !20048
- Fix incremental rollouts for Auto DevOps. !20061
- Notify conflict for only open merge request. !20125
- Only load Omniauth if enabled. !20132
- Fix sorting by name on explore projects page. !20162
- Fix alert button styling so that they don't show up white.

### Performance (1 change)

- Remove performance bottleneck preventing large wiki pages from displaying. !20174

### Added (1 change)

- Add support for verifying remote uploads, artifacts, and LFS objects in check rake tasks. !19501


## 11.0.1 (2018-06-21)

### Security (5 changes)

- Fix XSS vulnerability for table of content generation.
- Update sanitize gem to 4.6.5 to fix HTML injection vulnerability.
- HTML escape branch name in project graphs page.
- HTML escape the name of the user in ProjectsHelper#link_to_member.
- Don't show events from internal projects for anonymous users in public feed.


## 11.0.0 (2018-06-22)

### Security (3 changes)

- Fix API to remove deploy key from project instead of deleting it entirely.
- Fixed bug that allowed importing arbitrary project attributes.
- Prevent user passwords from being changed without providing the previous password.

### Removed (2 changes)

- Removed API v3 from the codebase. !18970
- Removes outdated `g t` shortcut for TODO in favor of `Shift+T`. !19002

### Fixed (69 changes, 23 of them are from the community)

- Optimize the upload migration process. !15947
- Import bitbucket issues that are reported by an anonymous user. !18199 (bartl)
- Fix an issue where the notification email address would be set to an unconfirmed email address. !18474
- Stop logging email information when emails are disabled. !18521 (Marc Shaw)
- Fix double-brackets being linkified in wiki markdown. !18524 (brewingcode)
- Use case in-sensitive ordering by name for dashboard. !18553 (@vedharish)
- Fix width of contributors graphs. !18639 (Paul Vorbach)
- Fix modal width of shorcuts help page. !18766 (Lars Greiss)
- Add missing tooltip to creation date on container registry overview. !18767 (Lars Greiss)
- Add missing migration for minimal Project build_timeout. !18775
- Update commit status from external CI services less aggressively. !18802
- Fix Runner contacted at tooltip cache. !18810
- Added support for LFS Download in the importing process. !18871
- Fix issue board bug with long strings in titles. !18924
- Does not log failed sign-in attempts when the database is in read-only mode. !18957
- Fixes 500 error on /estimate BIG_VALUE. !18964 (Jacopo Beschi @jacopo-beschi)
- Forbid to patch traces for finished jobs. !18969
- Do not allow to trigger manual actions that were skipped. !18985
- Renamed 'Overview' to 'Project' in collapsed contextual navigation at a project level. !18996 (Constance Okoghenun)
- Fixed bug where generated api urls didn't add the base url if set. !19003
- Fixed badge api endpoint route when relative url is set. !19004
- Fixes: Runners search input placeholder is cut off. !19015 (Jacopo Beschi @jacopo-beschi)
- Exclude CI_PIPELINE_ID from variables supported in dynamic environment name. !19032
- Updates updated_at on label changes. !19065 (Jacopo Beschi @jacopo-beschi)
- Disallow updating job status if the job is not running. !19101
- Fix FreeBSD can not upload artifacts due to wrong tmp path. !19148
- Check for nil AutoDevOps when saving project CI/CD settings. !19190
- Missing timeout value in object storage pre-authorization. !19201
- Use strings as properties key in kubernetes service spec. !19265 (Jasper Maes)
- Fixed HTTP_PROXY environment not honored when reading remote traces. !19282 (NLR)
- Updates ReactiveCaching clear_reactive_caching method to clear both data and alive caching. !19311
- Fixes the styling on the modal headers. !19312 (samdbeckham)
- Fixes a spelling error on the new label page. !19316 (samdbeckham)
- Rails5 fix arel from. !19340 (Jasper Maes)
- Support rails5 in postgres indexes function and fix some migrations. !19400 (Jasper Maes)
- Fix repository archive generation when hashed storage is enabled. !19441
- Rails 5 fix unknown keywords: changes, key_id, project, gl_repository, action, secret_token, protocol. !19466 (Jasper Maes)
- Rails 5 fix glob spec. !19469 (Jasper Maes)
- Showing project import_status in a humanized form no longer gives an error. !19470
- Make avatars/icons hidden on mobile. !19585 (Takuya Noguchi)
- Fix active tab highlight when creating new merge request. !19781 (Jan Beckmann)
- Fixes Web IDE button on merge requests when GitLab is installed with relative URL.
- Unverified hover state color changed to black.
- Fix &nbsp; after sign-in with Google button.
- Don't trim incoming emails that create new issues. (Cameron Crockett)
- Wrapping problem on the issues page has been fixed.
- Fix resolvable check if note's commit could not be found.
- Fix filename matching when processing file or blob search results.
- Allow maintainers to retry pipelines on forked projects (if allowed in merge request).
- Fix deletion of Object Store uploads.
- Fix overflowing Failed Jobs table in sm viewports on IE11.
- Adjust insufficient diff hunks being persisted on NoteDiffFile.
- Render calendar feed inline when accessed from GitLab.
- Line height fixed. (Murat Dogan)
- Use upload ID for creating lease key for file uploaders.
- Use Github repo visibility during import while respecting restricted visibility levels.
- Adjust permitted params filtering on merge scheduling.
- Fix unscrollable Markdown preview of WebIDE on Firefox.
- Enforce UTF-8 encoding on user input in LogrageWithTimestamp formatter and filter out file content from logs.
- Fix project destruction failing due to idle in transaction timeouts.
- Add a unique and not null constraint on the project_features.project_id column.
- Expire Wiki content cache after importing a repository.
- Fix admin counters not working when PostgreSQL has secondaries.
- Fix backup creation and restore for specific Rake tasks.
- Fix cross-origin errors when attempting to download JavaScript attachments.
- Fix api_json.log not always reporting the right HTTP status code.
- Fix attr_encryption key settings.
- Remove gray button styles.
- Fix print styles for markdown pages.

### Deprecated (4 changes)

- Deprecate Gemnasium project service. !18954
- Rephrasing Merge Request's 'allow edits from maintainer' functionality. !19061
- Rename issue scope created-by-me to created_by_me, and assigned-to-me to assigned_to_me. !44799
- Migrate any remaining jobs from deprecated `object_storage_upload` queue.

### Changed (42 changes, 11 of them are from the community)

- Add support for smarter system notes. !17164
- Automatically accepts project/group invite by email after user signup. !17634 (Jacopo Beschi @jacopo-beschi)
- Dynamically fetch GCP cluster creation parameters. !17806
- Label list page redesign. !18466
- Move discussion actions to the right for small viewports. !18476 (George Tsiolis)
- Add 2FA filter to the group members page. !18483
- made listing and showing public issue apis available without authentication. !18638 (haseebeqx)
- Refactoring UrlValidators to include url blocking. !18686
- Removed "(Beta)" from "Auto DevOps" messages. !18759
- Expose runner ip address to runners API. !18799 (Lars Greiss)
- Moves MR widget external link icon to the right. !18828 (Jacopo Beschi @jacopo-beschi)
- Add support for 'active' setting on Runner Registration API endpoint. !18848
- Add dot to separate system notes content. !18864
- Remove modalbox confirmation when retrying a pipeline. !18879
- Remove docker pull prefix from registry clipboard feature. !18933 (Lars Greiss)
- Move project sidebar sub-entries 'Environments' and 'Kubernetes' from 'CI/CD' to a new entry 'Operations'. !18941
- Updated icons for branch and tag names in commit details. !18953 (Constance Okoghenun)
- Expose readme url in Project API. !18960 (Imre Farkas)
- Changes keyboard shortcut of Activity feed to `g v`. !19002
- Updated Mattermost integration to use API v4 and only allow creation of Mattermost slash commands in the current user's teams. !19043 (Harrison Healey)
- Add shortcuts to Web IDE docs and modal. !19044
- Rename merge request widget author component. !19079 (George Tsiolis)
- Rename the Master role to Maintainer. !19080
- Use "right now" for short time periods. !19095
- Update 404 and 403 pages with helpful actions. !19096
- Add username to terms message in git and API calls. !19126
- Change the IDE file buttons for an "Open in file view" button. !19129 (Sam Beckham)
- Removes redundant script failure message from Job page. !19138
- Add flash notice if user has already accepted terms and allow users to continue to root path. !19156
- Redesign group settings page into expandable sections. !19184
- Hashed Storage: migration rake task now can be executed to specific project. !19268
- Make CI job update entrypoint to work as keep-alive endpoint. !19543
- Avoid checking the user format in every url validation. !19575
- Apply notification settings level of groups to all child objects.
- Support restoring repositories into gitaly.
- Bump omniauth-gitlab to 1.0.3.
- Move API group deletion to Sidekiq.
- Improve Failed Jobs tab in the Pipeline detail page.
- Add additional theme color options.
- Include milestones from parent groups when assigning a milestone to an issue or merge request.
- Restore API v3 user endpoint.
- Hide merge request option in IDE when disabled.

### Performance (28 changes, 1 of them is from the community)

- Add backgound migration for filling nullfied file_store columns. !18557
- Add a cronworker to rescue stale live traces. !18680
- Move SquashBeforeMerge vue component. !18813 (George Tsiolis)
- Add index on runner_type for ci_runners. !18897
- Fix CarrierWave reads local files into memory when migrates to ObjectStorage. !19102
- Remove double-checked internal id generation. !19181
- Throttle updates to Project#last_repository_updated_at. !19183
- Add background migrations for archiving legacy job traces. !19194
- Use NPM provided version of SortableJS. !19274
- Improve performance of group issues filtering on GitLab.com. !19429
- Improve performance of LFS integrity check. !19494
- Fix an N+1 when loading user avatars.
- Only preload member records for the relevant projects/groups/user in projects API.
- Fix some sources of excessive query counts when calculating notification recipients.
- Optimise PagesWorker usage.
- Optimise paused runners to reduce amount of used requests.
- Update runner cached informations without performing validations.
- Improve performance of project pipelines pages.
- Persist truncated note diffs on a new table.
- Remove unused running_or_pending_build_count.
- Remove N+1 query for author in issues API.
- Eliminate N+1 queries with authors and push_data_payload in Events API.
- Eliminate cached N+1 queries for projects in Issue API.
- Eliminate N+1 queries for CI job artifacts in /api/prjoects/:id/pipelines/:pipeline_id/jobs.
- Fix N+1 with source_projects in merge requests API.
- Replace grape-route-helpers with our own grape-path-helpers.
- Move PR IO operations out of a transaction.
- Improve performance of GroupsController#show.

### Added (25 changes, 10 of them are from the community)

- Closes MR check out branch modal with escape. (19050)
- Allow changing the default favicon to a custom icon. !14497 (Alexis Reigel)
- Export assigned issues in iCalendar feed. !17783 (Imre Farkas)
- When MR becomes unmergeable, notify and create todo for author and merge user. !18042
- Display help text below auto devops domain with nip.io domain name (#45561). !18496
- Add per-project pipeline id. !18558
- New design for wiki page deletion confirmation. !18712 (Constance Okoghenun)
- Updates updated_at on issuable when setting time spent. !18757 (Jacopo Beschi @jacopo-beschi)
- Expose artifacts_expire_at field for job entity in api. !18872 (Semyon Pupkov)
- Add support for variables expression pattern matching syntax. !18902
- Add API endpoint to render markdown text. !18926 (@blackst0ne)
- Add `Squash and merge` to GitLab Core (CE). !18956 (@blackst0ne)
- Adds keyboard shortcut `g k` for Kubernetes on Project pages. !19002
- Adds keyboard shortcut `g e` for Environments on Project pages. !19002
- Setup graphql with initial project & merge request query. !19008
- Adds JupyterHub to cluster applications. !19019
- Added ability to search by wiki titles. !19112
- Add Avatar API. !19121 (Imre Farkas)
- Add variables to POST api/v4/projects/:id/pipeline. !19124 (Jacopo Beschi @jacopo-beschi)
- Add deploy strategies to the Auto DevOps settings. !19172
- Automatize Deploy Token creation for Auto Devops. !19507
- Add anchor for incoming email regex.
- Support direct_upload with S3 Multipart uploads.
- Add Open in Xcode link for xcode repositories.
- Add pipeline status to the status bar of the Web IDE.

### Other (40 changes, 17 of them are from the community)

- Expand documentation for Runners API. !16484
- Order UsersController#projects.json by updated_at. !18227 (Takuya Noguchi)
- Replace the `project/issues/references.feature` spinach test with an rspec analog. !18769 (@blackst0ne)
- Replace the `project/merge_requests/references.feature` spinach test with an rspec analog. !18794 (@blackst0ne)
- Replace the `project/deploy_keys.feature` spinach test with an rspec analog. !18796 (@blackst0ne)
- Replace the `project/ff_merge_requests.feature` spinach test with an rspec analog. !18800 (@blackst0ne)
- Apply NestingDepth (level 5) (pages/pipelines.scss). !18830 (Takuya Noguchi)
- Replace the `project/forked_merge_requests.feature` spinach test with an rspec analog. !18867 (@blackst0ne)
- Remove Spinach. !18869 (@blackst0ne)
- Add NOT NULL constraints to project_authorizations. !18980
- Add helpful messages to empty wiki view. !19007
- Increase text limit for GPG keys (mysql only). !19069
- Take two for MR metrics population background migration. !19097
- Remove Gemnasium badge from project README.md. !19136 (Takuya Noguchi)
- Update awesome_print to 1.8.0. !19163 (Takuya Noguchi)
- Update email_spec to 2.2.0. !19164 (Takuya Noguchi)
- Update redis-namespace to 1.6.0. !19166 (Takuya Noguchi)
- Update rdoc to 6.0.4. !19167 (Takuya Noguchi)
- Updates the version of kubeclient from 3.0 to 3.1.0. !19199
- Fix UI broken in line profiling modal due to Bootstrap 4. !19253 (Takuya Noguchi)
- Add migration to disable the usage of DSA keys. !19299
- Use the default strings of timeago.js for timeago. !19350 (Takuya Noguchi)
- Update selenium-webdriver to 3.12.0. !19351 (Takuya Noguchi)
- Include username in output when testing SSH to GitLab. !19358
- Update screenshot in GitLab.com integration documentation. !19433 (Tuğçe Nur Taş)
- Users can accept terms during registration. !19583
- Fix issue count on sidebar.
- Add merge requests list endpoint for groups.
- Upgrade GitLab from Bootstrap 3 to 4.
- Make ActiveRecordSubscriber rails 5 compatible.
- Show a more helpful error for import status.
- Log response body to production_json.log when a controller responds with a 422 status.
- Log Workhorse queue duration for Grape API calls.
- Adjust SQL and transaction Prometheus buckets.
- Adding branches through the WebUI is handled by Gitaly.
- Remove shellout implementation for Repository checksums.
- Refs containing sha checks are done by Gitaly.
- Finding a wiki page is done by Gitaly by default.
- Workhorse will use Gitaly to create archives.
- Workhorse to send raw diff and patch for commits.
