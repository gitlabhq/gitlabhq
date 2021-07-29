## 9.5.10 (2017-11-08)

- [SECURITY] Add SSRF protections for hostnames that will never resolve but will still connect to localhost
- [SECURITY] Include X-Content-Type-Options (XCTO) header into API responses

## 9.5.9 (2017-10-16)

- [SECURITY] Move project repositories between namespaces when renaming users.
- [SECURITY] Prevent an open redirect on project pages.
- [SECURITY] Prevent a persistent XSS in user-provided markup.
- [FIXED] Allow using newlines in pipeline email service recipients. !14250
- Escape user name in filtered search bar.

## 9.5.8 (2017-10-04)

- [FIXED] Fixed fork button being disabled for users who can fork to a group.

## 9.5.7 (2017-10-03)

- Fix gitlab rake:import:repos task.

## 9.5.6 (2017-09-29)

- [FIXED] Fix MR ready to merge buttons/controls at mobile breakpoint. !14242
- [FIXED] Fix errors thrown in merge request widget with external CI service/integration.
- [FIXED] Update x/x discussions resolved checkmark icon to be green when all discussions resolved.
- [FIXED] Fix 500 error on merged merge requests when GitLab is restored from a backup.

## 9.5.5 (2017-09-18)

- [SECURITY] Upgrade mail and nokogiri gems due to security issues. !13662 (Markus Koller)
- [FIXED] Fix division by zero error in blame age mapping. !13803 (Jeff Stubler)
- [FIXED] Fix problems sanitizing URLs with empty passwords. !14083
- [FIXED] Fix a wrong `X-Gitlab-Event` header when testing webhooks. !14108
- [FIXED] Fixes the 500 errors caused by a race condition in GPG's tmp directory handling. !14194 (Alexis Reigel)
- [FIXED] Fix Pipeline Triggers to show triggered label and predefined variables (e.g. CI_PIPELINE_TRIGGERED). !14244
- [FIXED] Fix project feature being deleted when updating project with invalid visibility level.
- [FIXED] Fix new navigation wrapping and causing height to grow.
- [FIXED] Fix buttons with different height in merge request widget.
- [FIXED] Normalize styles for empty state combo button.
- [FIXED] Fix broken svg in jobs dropdown for success status.
- [FIXED] Improve migrations using triggers.
- [FIXED] Disable GitLab Project Import Button if source disabled.
- [CHANGED] Update the GPG verification semantics: A GPG signature must additionally match the committer in order to be verified. !13771 (Alexis Reigel)
- [OTHER] Fix repository equality check and avoid fetching ref if the commit is already available. This affects merge request creation performance. !13685
- [OTHER] Update documentation for confidential issue. !14117

## 9.5.4 (2017-09-06)

- [SECURITY] Upgrade mail and nokogiri gems due to security issues. !13662 (Markus Koller)
- [SECURITY] Prevent a persistent XSS in the commit author block.
- Fix XSS issue in go-get handling.
- Resolve CSRF token leakage via pathname manipulation on environments page.
- Fixes race condition in project uploads.
- Disallow arbitrary properties in `th` and `td` `style` attributes.
- Disallow the `name` attribute on all user-provided markup.

## 9.5.3 (2017-09-03)

- [SECURITY] Filter additional secrets from Rails logs.
- [FIXED] Make username update fail if the namespace update fails. !13642
- [FIXED] Fix failure when issue is authored by a deleted user. !13807
- [FIXED] Reverts changes made to signin_enabled. !13956
- [FIXED] Fix Merge when pipeline succeeds button dropdown caret icon horizontal alignment.
- [FIXED] Fixed diff changes bar buttons from showing/hiding whilst scrolling.
- [FIXED] Fix events error importing GitLab projects.
- [FIXED] Fix pipeline trigger via API fails with 500 Internal Server Error in 9.5.
- [FIXED] Fixed fly-out nav flashing in & out.
- [FIXED] Remove closing external issues by reference error.
- [FIXED] Re-allow appearances.description_html to be NULL.
- [CHANGED] Update and fix resolvable note icons for easier recognition.
- [OTHER] Eager load head pipeline projects for MRs index.
- [OTHER] Instrument MergeRequest#fetch_ref.
- [OTHER] Instrument MergeRequest#ensure_ref_fetched.

## 9.5.2 (2017-08-28)

- [FIXED] Fix signing in using LDAP when attribute mapping uses simple strings instead of arrays.
- [FIXED] Show un-highlighted text diffs when we do not have references to the correct blobs.
- [FIXED] Fix display of push events for removed refs.
- [FIXED] Testing of some integrations were broken due to missing ServiceHook record.
- [FIXED] Fire system hooks when a user is created via LDAP.
- [FIXED] Fix new project form not resetting the template value.

## 9.5.1 (2017-08-23)

- [FIXED] Fix merge request pipeline status when pipeline has errors. !13664
- [FIXED] Commit rows would occasionally render with the wrong language.
- [FIXED] Fix caching of future broadcast messages.
- [FIXED] Only require Sidekiq throttling library when enabled, to reduce cache misses.
- Raise Housekeeping timeout to 24 hours. !13719

## 9.5.0 (2017-08-22)

- [FIXED] Fix timeouts when creating projects in groups with many members. !13508
- [FIXED] Improve API pagination headers when no record found. !13629 (Jordan Patterson)
- [FIXED] Fix deleting GitLab Pages files when a project is removed. !13631
- [FIXED] Fix commit list not loading the correct page when scrolling.
- [OTHER] Cache the number of forks of a project. !13535
- GPG signed commits integration. !9546 (Alexis Reigel)
- Alert the user if a Wiki page changed while they were editing it in order to prevent overwriting changes. !9707 (Hiroyuki Sato)
- Add custom linter for inline JavaScript to haml_lint. !9742 (winniehell)
- Add /shrug and /tableflip commands. !10068 (Alex Ives)
- Allow wiki pages to be renamed in the UI. !10069 (wendy0402)
- Insert user name directly without encoding. !10085 (Nathan Neulinger <nneul@neulinger.org>)
- Avoid plucking Todo ids in TodoService. !10845
- Handle errors while a project is being deleted asynchronously. !11088
- Decrease ABC threshold to 56.96. !11227 (Maxim Rydkin)
- Remove Mattermost team when deleting a group. !11362
- Block access to failing repository storage. !11449
- Add coordinator url to admin area runner page. !11603
- Allow testing any events for project hooks and system hooks. !11728 (Alexander Randa (@randaalex))
- Disallow running the pipeline if ref is protected and user cannot merge the branch or create the tag. !11910
- Remove project_key from the Jira configuration. !12050
- Add CSRF token verification to API. !12154 (Vitaliy @blackst0ne Klachkov)
- Fixes needed when GitLab sign-in is not enabled. !12491 (Robin Bobbitt)
- Lazy load images for better Frontend performance. !12503
- Replaces dashboard/event_filters.feature spinach with rspec. !12651 (Alexander Randa (@randaalex))
- Toggle import description with import_sources_enabled. !12691 (Brianna Kicia)
- Bump scss-lint to 0.54.0. !12733 (Takuya Noguchi)
- Enable SpaceAfterComma in scss-lint. !12734 (Takuya Noguchi)
- Remove CSS for nprogress removed. !12737 (Takuya Noguchi)
- Enable UnnecessaryParentReference in scss-lint. !12738 (Takuya Noguchi)
- Extract "@request.env[devise.mapping] = Devise.mappings[:user]" to a test helper. !12742 (Jacopo Beschi @jacopo-beschi)
- Enable ImportPath in scss-lint. !12749 (Takuya Noguchi)
- Enable PropertySpelling in scss-lint. !12752 (Takuya Noguchi)
- Add API for protected branches to allow for wildcard matching and no access restrictions. !12756 (Eric Yu)
- refactor initializations in dropzone_input.js. !12768 (Brandon Everett)
- Improve CSS for global nav dropdown UI. !12772 (Takuya Noguchi)
- Remove public/ci/favicon.ico. !12803 (Takuya Noguchi)
- Enable DeclarationOrder in scss-lint. !12805 (Takuya Noguchi)
- Increase width of dropdown menus automatically. !12809 (Thomas Wucher)
- Enable BangFormat in scss-lint [ci skip]. !12815 (Takuya Noguchi)
- Added /duplicate quick action to close a duplicate issue. !12845 (Ryan Scott)
- Make all application-settings accessible through the API. !12851
- Remove Inactive Personal Access Tokens list from Access Tokens page. !12866
- Replaces dashboard/dashboard.feature spinach with rspec. !12876 (Alexander Randa (@randaalex))
- Reduce memory usage of the GitHub importer. !12886
- Bump fog-core to 1.44.3 and fog providers' plugins to latest. !12897 (Takuya Noguchi)
- Use only CSS to truncate commit message in blame. !12900 (Takuya Noguchi)
- Protect manual actions against protected tag too. !12908
- Allow to configure automatic retry of a failed CI/CD job. !12909
- Remove help message about prioritized labels for non-members. !12912 (Takuya Noguchi)
- Add link to doc/api/ci/lint.md. !12914 (Takuya Noguchi)
- Add RequestCache which makes caching with RequestStore easier. !12920
- Free up some top level words, reject top level groups named like files in the public folder. !12932
- Extend API for Group Secret Variable. !12936
- Hide description about protected branches to non-member. !12945 (Takuya Noguchi)
- Support custom directory in gitlab:backup:create task. !12984 (Markus Koller)
- Raise guessed encoding confidence threshold to 50. !12990
- Add author_id & assignee_id param to /issues API. !13004
- Fix today day highlight in calendar. !13048
- Prevent LDAP login callback from being called with a GET request. !13059
- Add top-level merge_requests API endpoint. !13060
- Handle maximum pages artifacts size correctly. !13072
- Enable gitaly_post_upload_pack by default. !13078
- Add Prometheus metrics exporter to Sidekiq. !13082
- Fix improperly skipped backups of wikis. !13096
- Projects can be created from templates. !13108
- Fix the /projects/:id/repository/branches endpoint to handle dots in the branch name when the project full path contains a `/`. !13115
- Fix project logos that are not centered vertically on list pages. !13124 (Florian Lemaitre)
- Derive project path from import URL. !13131
- Fix deletion of deploy keys linked to other projects. !13162
- repository archive download url now ends with selected file extension. !13178 (haseebeqx)
- Show auto-generated avatars for Groups without avatars. !13188
- Allow any logged in users to read_users_list even if it's restricted. !13201
- Unlock stuck merge request and set the proper state. !13207
- Fix timezone inconsistencies in user contribution graph. !13208
- Fix Issue board when using Ruby 2.4. !13220
- Don't rename namespace called system when upgrading from 9.1.x to 9.5. !13228
- Fix encoding error for WebHook logging. !13230 (Alexander Randa (@randaalex))
- Uniquify reserved word usernames on OAuth user creation. !13244 (Robin Bobbitt)
- Expose target_iid in Events API. !13247 (sue445)
- Add star for action scope, in order to delete image from registry. !13248 (jean)
- Make Delete Merged Branches handle wildcard protected branches correctly. !13251
- Fix an order of operations for CI connection error message in merge request widget. !13252
- Don't send rejection mails for all auto-generated mails. !13254
- Expose noteable_iid in Note. !13265 (sue445)
- Fix pipeline_schedules pages when active schedule has an abnormal state. !13286
- Move some code from services to workers in order to improve performance. !13326
- Fix destroy of case-insensitive conflicting redirects. !13357
- Fix the /projects/:id/repository/tags endpoint to handle dots in the tag name when the project full path contains a `/`. !13368
- Fix the /projects/:id/repository/commits endpoint to handle dots in the ref name when the project full path contains a `/`. !13370
- Project pending delete no longer return 500 error in admins projects view. !13389
- Use full path of user's avatar in webhooks. !13401 (Vitaliy @blackst0ne Klachkov)
- Make GPGME temporary directory handling thread safe. !13481 (Alexis Reigel)
- Add support for kube_namespace in Metrics queries. !16169
- Fix bar chart does not display label at 0 hour. !35136 (Jason Dai)
- Use project_ref_path to create the link to a branch to fix links that 404.
- Declare related resources into V4 API entities.
- Add Slack and JIRA services counts to Usage Data.
- Prevent web hook and project service background jobs from going to the dead jobs queue.
- Display specific error message when JIRA test fails.
- clean up merge request widget UI.
- Associate Issues tab only with internal issues tracker.
- Remove events column from notification settings table.
- Clarifies and rearranges the input variables on the kubernetes integration page and adjusts the docs slightly to meet the same order.
- Respect blockquote line breaks in markdown.
- Update confidential issue UI - add confidential visibility and settings to sidebar.
- Add icons to contextual sidebars.
- Make contextual sidebar collapsible.
- Update Pipeline's badge count in Merge Request and Commits view to match real-time content.
- Added link to the MR widget that directs to the monitoring dashboard.
- Use jQuery to control scroll behavior in job log for cross browser consistency.
- move edit comment button outside of dropdown.
- Updates vue resource and code according to breaking changes.
- Add GitHub imported projects count to usage data.
- Rename about to overview for group and project page.
- Prevent disabled pagination button to be clicked.
- Remove coffee-rails gem. (Takuya Noguchi)
- Remove net-ssh gem. (Takuya Noguchi)
- Bump rubocop to 0.49.1 and rubocop-rspec to 1.15.1. (Takuya Noguchi)
- improve file upload/replace experience.
- allow closing Cycle Analytics intro box in firefox.
- Fix label creation from new list for subgroup projects.
- fix transient js error in rspec tests.
- fix jump to next discussion button.
- Fix translations for Star/Unstar in JS file.
- Improve mobile sidebar.
- Rename Pipelines tab to CI / CD in new navigation.
- Fix display of new diff comments after changing b between diff views.
- Store & use ConvDev percentages returned by the Version app.
- Fixes new issue button for failed job returning 404.
- Align OR separator to center in new project page.
- Add filtered search to group issue dashboard.
- Cache Appearance instances in Redis.
- Fixed breadcrumbs title aggressively collapsing.
- Better caching and indexing of broadcast messages.
- Moved diff changed files into a dropdown.
- Improve performance of large (initial) push into default branch.
- Improve performance of checking for projects on the projects dashboard.
- Eager load project creators for project dashboards.
- Modify if condition to be more readable.
- Fix links to group milestones from issue and merge request sidebar.
- Remove hidden symlinks from project import files.
- Fixed sign-in restrictions buttons not toggling active state.
- Fix replying to commit comments on merge requests created from forks.
- Support Markdown references, autocomplete, and quick actions for group milestones.
- Cache recent projects for group-level new resource creation.
- Fix API responses when dealing with txt files.
- Fix project milestones import when projects belongs to a group.
- Fix Mattermost integration.
- Memoize the number of personal projects a user has to reduce COUNT queries.
- Merge issuable "reopened" state into "opened".
- Migrate events into a new format to reduce the storage necessary and improve performance.
- MR branch link now links to tree instead of commits.
- Use Prev/Next pagination for exploring projects.
- Pass before_script and script as-is preserving arrays.
- Change project FK migration to skip existing FKs.
- Remove redundant query when retrieving the most recent push of a user.
- Re-organise "issues" indexes for faster ordering.
- Disallow Git URLs that include a username or hostname beginning with a non-alphanumeric character.
- Fix search box losing focus when typing.
- Add structured logging for Rails processes.
- Skip oAuth authorization for trusted applications.
- Use a specialized class for querying events to improve performance.
- Update build badges to be pipeline badges and display passing instead of success.

## 9.4.7 (2017-10-16)

- [SECURITY] Upgrade mail and nokogiri gems due to security issues. !13662 (Markus Koller)
- [SECURITY] Move project repositories between namespaces when renaming users.
- [SECURITY] Prevent an open redirect on project pages.
- [SECURITY] Prevent a persistent XSS in user-provided markup.
- [FIXED] Allow using newlines in pipeline email service recipients. !14250
- Escape user name in filtered search bar.

## 9.4.6 (2017-09-06)

- [SECURITY] Upgrade mail and nokogiri gems due to security issues. !13662 (Markus Koller)
- [SECURITY] Prevent a persistent XSS in the commit author block.
- Fix XSS issue in go-get handling.
- Remove hidden symlinks from project import files.
- Fixes race condition in project uploads.
- Disallow Git URLs that include a username or hostname beginning with a non-alphanumeric character.
- Disallow arbitrary properties in `th` and `td` `style` attributes.
- Resolve CSRF token leakage via pathname manipulation on environments page.
- Disallow the `name` attribute on all user-provided markup.

## 9.4.5 (2017-08-14)

- Fix deletion of deploy keys linked to other projects. !13162
- Allow any logged in users to read_users_list even if it's restricted. !13201
- Make Delete Merged Branches handle wildcard protected branches correctly. !13251
- Fix an order of operations for CI connection error message in merge request widget. !13252
- Fix pipeline_schedules pages when active schedule has an abnormal state. !13286
- Add missing validation error for username change with container registry tags. !13356
- Fix destroy of case-insensitive conflicting redirects. !13357
- Project pending delete no longer return 500 error in admins projects view. !13389
- Fix search box losing focus when typing.
- Use jQuery to control scroll behavior in job log for cross browser consistency.
- Use project_ref_path to create the link to a branch to fix links that 404.
- improve file upload/replace experience.
- fix jump to next discussion button.
- Fixes new issue button for failed job returning 404.
- Fix links to group milestones from issue and merge request sidebar.
- Fixed sign-in restrictions buttons not toggling active state.
- Fix Mattermost integration.
- Change project FK migration to skip existing FKs.

## 9.4.4 (2017-08-09)

- Remove hidden symlinks from project import files.
- Disallow Git URLs that include a username or hostname beginning with a non-alphanumeric character.

## 9.4.3 (2017-07-31)

- Fix Prometheus client PID reuse bug. !13130
- Improve deploy environment chatops slash command. !13150
- Fix asynchronous javascript paths when GitLab is installed under a relative URL. !13165
- Fix LDAP authentication to Git repository or container registry.
- Fixed new navigation breadcrumb title on help pages.
- Ensure filesystem metrics test files are deleted.
- Properly affixes nav bar in job view in microsoft edge.

## 9.4.2 (2017-07-28)

- Fix job merge request link to a forked source project. !12965
- Improve redirect route query performance. !13062
- Allow admin to read_users_list even if it's restricted. !13066
- Fixes 500 error caused by pending delete projects in admin dashboard. !13067
- Add instrumentation to MarkupHelper#link_to_gfm. !13069
- Pending delete projects should not show in deploy keys. !13088
- Fix sizing of custom header logo in new navigation.
- Fix crash on /help/ui.
- Fix creating merge request diffs when diff contains bytes that are invalid in UTF-8.
- fix vertical alignment of New Project button.
- Add LDAP SSL certificate verification option.
- Fix vertical alignment in firefox and safari for pipeline mini graph.

## 9.4.1 (2017-07-25)

- Fix pipeline_schedules pages throwing error 500 (when ref is empty). !12983
- Fix editing project with container images present. !13028
- Fix some invalid entries in PO files. !13032
- Fix cross site request protection when logging in as a regular user when LDAP is enabled. !13049
- Fix bug causing metrics files to be truncated. !35420
- Fix anonymous access to public projects in groups with pending invites.
- Fixed issue boards sidebar close icon size.
- Fixed duplicate new milestone buttons when new navigation is turned on.
- Fix margins in the mini graph for pipeline in commits box.

## 9.4.0 (2017-07-22)

- Add blame view age mapping. !7198 (Jeff Stubler)
- Add support for image and services configuration in .gitlab-ci.yml. !8578
- Fix an email parsing bug where brackets would be inserted in emails from some Outlook clients. !9045 (jneen)
- Use fa-chevron-down on dropdown arrows for consistency. !9659 (TM Lee)
- Update the devise mail templates to match the design of the pipeline emails. !10483 (Alexis Reigel)
- Handle renamed submodules in repository browser. !10798 (David Turner)
- Display all current broadcast messages, not just the last one. !11113 (rickettm)
- Fix CI/CD status in case there are only allowed to failed jobs in the pipeline. !11166
- Omit trailing / leading hyphens in CI_COMMIT_REF_SLUG variable to make it usable as a hostname. !11218 (Stefan Hanreich)
- Moved "Members in a project" menu entry and path locations. !11560
- Additional Prometheus metrics support. !11712
- Rename all reserved paths that could have been created. !11713
- Move uploads from `uploads/system` to `uploads/-/system` to free up `system` as a group name. !11713
- Fix offline runner detection. !11751 (Alessio Caiazza)
- Use authorize_update_pipeline_schedule in PipelineSchedulesController. !11846
- Rollback project repo move if there is an error in Projects::TransferService. !11877
- Help landing page customizations. !11878 (Robin Bobbitt)
- Fixes "sign in / Register" active state underline misalignment. !11890 (Frank Sierra)
- Honor the "Remember me" parameter for OAuth-based login. !11963
- Instruct user to use personal access token for Git over HTTP. !11986 (Robin Bobbitt)
- Accept image for avatar in project API. !11988 (Ivan Chernov)
- Supplement Simplified Chinese translation of Project Page & Repository Page. !11994 (Huang Tao)
- Supplement Traditional Chinese in Hong Kong translation of Project Page & Repository Page. !11995 (Huang Tao)
- Make the revision on the `/help` page clickable. !12016
- Display issue state in issue links section of merge request widget. !12021
- Enable support for webpack code-splitting by dynamically setting publicPath at runtime. !12032
- Replace PhantomJS with headless Chrome for karma test suite. !12036
- Prevent description change notes when toggling tasks. !12057 (Jared Deckard <jared.deckard@gmail.com>)
- Update QA Dockerfile to lock Chrome browser version. !12071
- Fix FIDO U2F for Opera browser. !12082 (Jakub Kramarz and Jonas Kalderstam)
- Supplement Bulgarian translation of Project Page & Repository Page. !12083 (Lyubomir Vasilev)
- Removes deleted_at and pending_delete occurrences in Project related queries. !12091
- Provide hint to create a personal access token for Git over HTTP. !12105 (Robin Bobbitt)
- Display own user id in account settings page. !12141 (Riccardo Padovani)
- Accept image for avatar in user API. !12143 (Ivan Chernov)
- Disable fork button on project limit. !12145 (Ivan Chernov)
- Added "created_after" and "created_before" params to issuables. !12151 (Kyle Bishop @kybishop)
- Supplement Portuguese Brazil translation of Project Page & Repository Page. !12156 (Huang Tao)
- Add review apps to usage metrics. !12185
- Adding French translations. !12200 (Erwan "Dremor" Georget)
- Ensures default user limits when external user is unchecked. !12218
- Provide KUBECONFIG from KubernetesService for runners. !12223
- Filter archived project in API v3 only if param present. !12245 (Ivan Chernov)
- Add explicit message when no runners on admin. !12266 (Takuya Noguchi)
- Split pipelines as internal and external in the usage data. !12277
- Fix API Scoping. !12300
- Remove registry image delete button if user cant delete it. !12317 (Ivan Chernov)
- Allow the feature flags to be enabled/disabled with more granularity. !12357
- Allow to enable the performance bar per user or Feature group. !12362
- Rename duplicated variables with the same key for projects. Add environment_scope column to variables and add unique constraint to make sure that no variables could be created with the same key within a project. !12363
- Add variables to pipelines schedules. !12372
- Add User#full_private_access? to check if user has access to all private groups & projects. !12373
- Change milestone endpoint for groups. !12374 (Takuya Noguchi)
- Improve performance of the pipeline charts page. !12378
- Add option to run Gitaly on a remote server. !12381
- #20628 Enable implicit grant in GitLab as OAuth Provider. !12384 (Mateusz Pytel)
- Replace 'snippets/snippets.feature' spinach with rspec. !12385 (Alexander Randa @randaalex)
- Add Simplified Chinese translations of Commits Page. !12405 (Huang Tao)
- Add Traditional Chinese in HongKong translations of Commits Page. !12406 (Huang Tao)
- Add Traditional Chinese in Taiwan translations of Commits Page. !12407 (Huang Tao)
- Add Portuguese Brazil translations of Commits Page. !12408 (Huang Tao)
- Add French translations of Commits Page. !12409 (Huang Tao)
- Add Esperanto translations of Commits Page. !12410 (Huang Tao)
- Add Bulgarian translations of Commits Page. !12411 (Huang Tao)
- Remove bin/ci/upgrade.rb as not working all. !12414 (Takuya Noguchi)
- Store merge request ref_fetched status in the database. !12424
- Replace 'dashboard/merge_requests' spinach with rspec. !12440 (Alexander Randa (@randaalex))
- Add Esperanto translations for Cycle Analytics, Project, and Repository pages. !12442 (Huang Tao)
- Allow unauthenticated access to the /api/v4/users API. !12445
- Drop GFM support for the title of Milestone/MergeRequest in template. !12451 (Takuya Noguchi)
- Replace 'dashboard/todos' spinach with rspec. !12453 (Alexander Randa (@randaalex))
- Cache open issue and merge request counts for project tabs to speed up project pages. !12457
- Introduce cache policies for CI jobs. !12483
- Improve support for external issue references. !12485
- Fix errors caused by attempts to report already blocked or deleted users. !12502 (Horacio Bertorello)
- Allow customize CI config path. !12509 (Keith Pope)
- Supplement Traditional Chinese in Taiwan translation of Project Page & Repository Page. !12514 (Huang Tao)
- Closes any open Autocomplete of the markdown editor when the form is closed. !12521
- Inserts exact matches of name, username and email to the top of the search list. !12525
- Use smaller min-width for dropdown-menu-nav only on mobile. !12528 (Takuya Noguchi)
- Hide archived project labels from group issue tracker. !12547 (Horacio Bertorello)
- Replace 'dashboard/new-project.feature' spinach with rspec. !12550 (Alexander Randa (@randaalex))
- Remove group modal like remove project modal (requires typing + confirmation). !12569 (Diego Souza)
- Add Italian translation of Cycle Analytics Page & Project Page & Repository Page. !12578 (Huang Tao)
- Add Group secret variables. !12582
- Update jobs page output to have a scrollable page. !12587
- Add user projects API. !12596 (Ivan Chernov)
- Allow creation of files and directories with spaces through Web UI. !12608
- Improve members view on mobile. !12619
- Fixed the chart legend not being set correctly. !12628
- Add Italian translations of Commits Page. !12645 (Huang Tao)
- Allow admins to disable all restricted visibility levels. !12649
- Allow admins to retrieve user agent details for an issue or snippet. !12655
- Update welcome page UX for new users. !12662
- N+1 problems on milestone page. !12670 (Takuya Noguchi)
- Upgrade GitLab Workhorse to v2.3.0. !12676
- Remove option to disable Gitaly. !12677
- Improve the performance of the project list API. !12679
- Add creation time filters to user search API for admins. !12682
- Add Japanese translations for Cycle Analytics & Project pages & Repository pages & Commits pages & Pipeline Charts. !12693 (Huang Tao)
- Undo adding the /reassign quick action. !12701
- Fix dashboard labels dropdown. !12708
- Username and password are no longer stripped from import url on mirror update. !12725
- Add Russian translations for Cycle Analytics & Project pages & Repository pages & Commits pages & Pipeline Charts. !12743 (Huang Tao)
- Add Ukrainian translations for Cycle Analytics & Project pages & Repository pages & Commits pages & Pipeline Charts. !12744 (Huang Tao)
- Prevent bad data being added to application settings when Redis is unavailable. !12750
- Do not show pipeline schedule button for non-member. !12757 (Takuya Noguchi)
- Return `is_admin` attribute in the GET /user endpoint for admins. !12811
- Recover from renaming project that has container images. !12840
- Exact matches of username and email are now on top of the user search. !12868
- Use Ghost user for last_edited_by and merge_user when original user is deleted. !12933
- Fix docker tag reference routing constraints. !12961
- Optimize creation of commit API by using Repository#commit instead of Repository#commits.
- Speed up used languages calculation on charts page.
- Make loading new merge requests (those created after the 9.4 upgrade) faster.
- Ensure participants for issues, merge requests, etc. are calculated correctly when sending notifications.
- Handle nameless legacy jobs.
- Bump Faraday and dependent OAuth2 gem version to support no_proxy variable.
- Renders 404 if given project is not readable by the user on Todos dashboard.
- Render CI statuses with warnings in orange.
- Document the Delete Merged Branches functionality.
- Add wells to admin dashboard overview to fix spacing problems.
- Removes hover style for nodes that are either links or buttons in the pipeline graph.
- more visual contrast in pagination widget.
- Deprecate Healthcheck Access Token in favor of IP whitelist.
- Drop GFM support for issuable title on milestone for consistency and performance. (Takuya Noguchi)
- fix left & right padding on sidebar.
- Cleanup minor UX issues in the performance dashboard.
- Remove two columned layout from project member settings.
- Make font size of contextual sub menu items 14px.
- Fix vertical space in job details sidebar.
- Fix alignment of controls in mr issuable list.
- Add wip message to new navigation preference section.
- Add group members counting and plan related data on namespaces API.
- Fix spacing on runner buttons.
- Remove uploads/appearance symlink. A leftover from a previous migration.
- Change order of monospace fonts to fix bug on some linux distros.
- Limit commit & snippets comments width.
- Fixed dashboard milestone tabs not loading.
- Detect if file that appears to be text in the first 1024 bytes is actually binary afer loading all data.
- Fix inconsistent display of the "Browse files" button in the commit list.
- Implement diff viewers.
- Fix 'New merge request' button for users who don't have push access to canonical project.
- Fix issues with non-UTF8 filenames by always fixing the encoding of tree and blob paths.
- Show group name instead of path on group page.
- Don't check if MailRoom is running on Omnibus.
- Limit OpenGraph image size to 64x64.
- Don't show auxiliary blob viewer for README when there is no wiki.
- Strip trailing whitespace in relative submodule URL.
- Update /target_branch slash command description to be more consistent.
- Remove unnecessary top padding on group MR index.
- Added printing_merge_requst_link_enabled to the API. (David Turner <dturner@twosigma.com>)
- Re-enable realtime for environments table.
- Create responsive mobile view for pipelines table.
- Adds realtime feature to job show view header and sidebar info. Updates UX.
- Use color inputs for broadcast messages.
- Center dropdown for mini graph.
- Users can subscribe to group labels on the group labels page.
- Add issuable-list class to shared mr/issue lists to fix new responsive layout design.
- Rename "Slash commands" to "Quick actions" and deprecate "chat commands" in favor of "slash commands".
- Don't mark empty MRs as merged on push to the target branch.
- Improve issue rendering performance with lots of notes from other users.
- Fixed overflow on mobile screens for the slash commands.
- Fix an infinite loop when handling user-supplied regular expressions.
- Fixed sidebar not collapsing on merge requests in mobile screens.
- Speed up project removals by adding foreign keys with cascading deletes to various tables.
- Fix mobile view of files view buttons.
- Fixed dropdown filter input not focusing after transition.
- Fixed GFM references not being included when updating issues inline.
- Remove issues/merge requests drag n drop and sorting from milestone view.
- Add native group milestones.
- Fix API bug accepting wrong parameter to create merge request.
- Clean up UI of issuable lists and make more responsive.
- Improve the overall UX for the new monitoring dashboard.
- Fixed the y_label not setting correctly for each graph on the monitoring dashboard.
- Changed utilities imports from ~ to relative paths.
- Remove unused space in sidebar todo toggle when not signed in.
- Limit the width of the projects README text.
- Add a simple mode to merge request API.
- Make Project#ensure_repository force create a repo.
- Use uploads/system directory for personal snippets.
- Defer project destroys within a namespace in Groups::DestroyService#async_execute.
- Log rescued exceptions to Sentry.
- Remove remaining N+1 queries in merge requests API with emojis and labels.

## 9.3.11 (2017-09-06)

- [SECURITY] Upgrade mail and nokogiri gems due to security issues. !13662 (Markus Koller)
- [SECURITY] Prevent a persistent XSS in the commit author block.
- Improve support for external issue references. !12485
- Use uploads/system directory for personal snippets.
- Remove uploads/appearance symlink. A leftover from a previous migration.
- Fix XSS issue in go-get handling.
- Remove hidden symlinks from project import files.
- Fix an infinite loop when handling user-supplied regular expressions.
- Fixes race condition in project uploads.
- Fixes race condition in project uploads.
- Disallow Git URLs that include a username or hostname beginning with a non-alphanumeric character.
- Disallow arbitrary properties in `th` and `td` `style` attributes.
- Resolve CSRF token leakage via pathname manipulation on environments page.
- Disallow the `name` attribute on all user-provided markup.
- Renders 404 if given project is not readable by the user on Todos dashboard.

## 9.3.10 (2017-08-09)

- Remove hidden symlinks from project import files.
- Disallow Git URLs that include a username or hostname beginning with a non-alphanumeric character.

## 9.3.9 (2017-07-20)

- Fix an infinite loop when handling user-supplied regular expressions.

## 9.3.8 (2017-07-19)

- Improve support for external issue references. !12485
- Renders 404 if given project is not readable by the user on Todos dashboard.
- Use uploads/system directory for personal snippets.
- Remove uploads/appearance symlink. A leftover from a previous migration.

## 9.3.7 (2017-07-18)

- Prevent bad data being added to application settings when Redis is unavailable. !12750
- Return `is_admin` attribute in the GET /user endpoint for admins. !12811

## 9.3.6 (2017-07-12)

- Fix API Scoping. !12300
- Username and password are no longer stripped from import url on mirror update. !12725
- Fix issues with non-UTF8 filenames by always fixing the encoding of tree and blob paths.
- Fixed GFM references not being included when updating issues inline.

## 9.3.5 (2017-07-05)

- Remove "Remove from board" button from backlog and closed list. !12430
- Do not delete protected branches when deleting all merged branches. !12624
- Set default for Remove source branch to false.
- Prevent accidental deletion of protected MR source branch by repeating checks before actual deletion.
- Expires full_path cache after a repository is renamed/transferred.

## 9.3.4 (2017-07-03)

- Update gitlab-shell to 5.1.1 !12615

## 9.3.3 (2017-06-30)

- Fix head pipeline stored in merge request for external pipelines. !12478
- Bring back branches badge to main project page. !12548
- Fix diff of requirements.txt file by not matching newlines as part of package names.
- Perform housekeeping only when an import of a fresh project is completed.
- Fixed issue boards closed list not showing all closed issues.
- Fixed multi-line markdown tooltip buttons in issue edit form.

## 9.3.2 (2017-06-27)

- API: Fix optional arguments for POST :id/variables. !12474
- Bump premailer-rails gem to 1.9.7 and its dependencies to prevent network retrieval of assets.

## 9.3.1 (2017-06-26)

- Fix reversed breadcrumb order for nested groups. !12322
- Fix 500 when failing to create private group. !12394
- Fix linking to line number on side-by-side diff creating empty discussion box.
- Don't match tilde and exclamation mark as part of requirements.txt package name.
- Perform project housekeeping after importing projects.
- Fixed ctrl+enter not submit issue edit form.

## 9.3.0 (2017-06-22)

- Refactored gitlab:app:check into SystemCheck liberary and improve some checks. !9173
- Add an ability to cancel attaching file and redesign attaching files UI. !9431 (blackst0ne)
- Add Aliyun OSS as the backup storage provider. !9721 (Yuanfei Zhu)
- Add support for find_local_branches GRPC from Gitaly. !10059
- Allow manual bypass of auto_sign_in_with_provider with a new param. !10187 (Maxime Besson)
- Redirect to user's keys index instead of user's index after a key is deleted in the admin. !10227 (Cyril Jouve)
- Changed Blame to Annotate in the UI to promote blameless culture. !10378 (Ilya Vassilevsky)
- Implement ability to update deploy keys. !10383 (Alexander Randa)
- Allow numeric values in gitlab-ci.yml. !10607 (blackst0ne)
- Add a feature test for Unicode trace. !10736 (dosuken123)
- Notes: Warning message should go away once resolved. !10823 (Jacopo Beschi @jacopo-beschi)
- Project authorizations are calculated much faster when using PostgreSQL, and nested groups support for MySQL has been removed
. !10885
- Fix long urls in the title of commit. !10938 (Alexander Randa)
- Update gem sidekiq-cron from 0.4.4 to 0.6.0 and rufus-scheduler from 3.1.10 to 3.4.0. !10976 (dosuken123)
- Use relative paths for group/project/user avatars. !11001 (blackst0ne)
- Enable cancelling non-HEAD pending pipelines by default for all projects. !11023
- Implement web hook logging. !11027 (Alexander Randa)
- Add indices for auto_canceled_by_id for ci_pipelines and ci_builds on PostgreSQL. !11034
- Add post-deploy migration to clean up projects in `pending_delete` state. !11044
- Limit User's trackable attributes, like `current_sign_in_at`, to update at most once/hour. !11053
- Disallow multiple selections for Milestone dropdown. !11084
- Link to commit author user page from pipelines. !11100
- Fix the last coverage in trace log should be extracted. !11128 (dosuken123)
- Remove redirect for old issue url containing id instead of iid. !11135 (blackst0ne)
- Backported new SystemHook event: `repository_update`. !11140
- Keep input data after creating a tag that already exists. !11155
- Fix support for external CI services. !11176
- Translate backend for Project & Repository pages. !11183
- Fix LaTeX formatting for AsciiDoc wiki. !11212
- Add foreign key for pipeline schedule owner. !11233
- Print Go version in rake gitlab:env:info. !11241
- Include the blob content when printing a blob page. !11247
- Sync email address from specified omniauth provider. !11268 (Robin Bobbitt)
- Disable reference prefixes in notes for Snippets. !11278
- Rename build_events to job_events. !11287
- Add API support for pipeline schedule. !11307 (dosuken123)
- Use route.cache_key for project list cache key. !11325
- Make environment table realtime. !11333
- Cache npm modules between pipelines with yarn to speed up setup-test-env. !11343
- Allow GitLab instance to start when InfluxDB hostname cannot be resolved. !11356
- Add ConvDev Index page to admin area. !11377
- Fix Git-over-HTTP error statuses and improve error messages. !11398
- Renamed users 'Audit Log'' to 'Authentication Log'. !11400
- Style people in issuable search bar. !11402
- Change /builds in the URL to /-/jobs. Backward URLs were also added. !11407
- Update password field label while editing service settings. !11431
- Add an optional performance bar to view performance metrics for the current page. !11439
- Update task_list to version 2.0.0. !11525 (Jared Deckard <jared.deckard@gmail.com>)
- Avoid resource intensive login checks if password is not provided. !11537 (Horatiu Eugen Vlad)
- Allow numeric pages domain. !11550
- Exclude manual actions when checking if pipeline can be canceled. !11562
- Add server uptime to System Info page in admin dashboard. !11590 (Justin Boltz)
- Simplify testing and saving service integrations. !11599
- Fixed handling of the `can_push` attribute in the v3 deploy_keys api. !11607 (Richard Clamp)
- Improve user experience around slash commands in instant comments. !11612
- Show current user immediately in issuable filters. !11630
- Add extra context-sensitive functionality for the top right menu button. !11632
- Reorder Issue action buttons in order of usability. !11642
- Expose atom links with an RSS token instead of using the private token. !11647 (Alexis Reigel)
- Respect merge, instead of push, permissions for protected actions. !11648
- Job details page update real time. !11651
- Improve performance of ProjectFinder used in /projects API endpoint. !11666
- Remove redundant data-turbolink attributes from links. !11672 (blackst0ne)
- Minimum postgresql version is now 9.2. !11677
- Add protected variables which would only be passed to protected branches or protected tags. !11688
- Introduce optimistic locking support via optional parameter last_commit_sha on File Update API. !11694 (electroma)
- Add $CI_ENVIRONMENT_URL to predefined variables for pipelines. !11695
- Simplify project repository settings page. !11698
- Fix pipeline_schedules pages throwing error 500. !11706 (dosuken123)
- Add performance deltas between app deployments on Merge Request widget. !11730
- Add feature toggles and API endpoints for admins. !11747
- Replace 'starred_projects.feature' spinach test with an rspec analog. !11752 (blackst0ne)
- Introduce an Events API. !11755
- Display Shared Runner status in Admin Dashboard. !11783 (Ivan Chernov)
- Persist pipeline stages in the database. !11790
- Revert the feature that would include the current user's username in the HTTP clone URL. !11792
- Enable Gitaly by default in installations from source. !11796
- Use zopfli compression for frontend assets. !11798
- Add tag_list param to project api. !11799 (Ivan Chernov)
- Add changelog for improved Registry description. !11816
- Automatically adjust project settings to match changes in project visibility. !11831
- Add slugify project path to CI environment variables. !11838 (Ivan Chernov)
- Add all pipeline sources as special keywords to 'only' and 'except'. !11844 (Filip Krakowski)
- Allow pulling of container images using personal access tokens. !11845
- Expose import_status in Projects API. !11851 (Robin Bobbitt)
- Allow admins to delete users from the admin users page. !11852
- Allow users to be hard-deleted from the API. !11853
- Fix hard-deleting users when they have authored issues. !11855
- Fix missing optional path parameter in "Create project for user" API. !11868
- Allow users to be hard-deleted from the admin panel. !11874
- Add a Rake task to aid in rotating otp_key_base. !11881
- Fix submodule link to then project under subgroup. !11906
- Fix binary encoding error on MR diffs. !11929
- Limit non-administrators to adding 100 members at a time to groups and projects. !11940
- add bulgarian translation of cycle analytics page to I18N. !11958 (Lyubomir Vasilev)
- Make backup task to continue on corrupt repositories. !11962
- Fix incorrect ETag cache key when relative instance URL is used. !11964
- Reinstate is_admin flag in users api when authenticated user is an admin. !12211 (rickettm)
- Fix edit button for deploy keys available from other projects. !12301 (Alexander Randa)
- Fix passing CI_ENVIRONMENT_NAME and CI_ENVIRONMENT_SLUG for CI_ENVIRONMENT_URL. !12344
- Disable environment list refresh due to bug https://gitlab.com/gitlab-org/gitlab/issues/2677. !12347
- Standardize timeline note margins across different viewport sizes. !12364
- Fix Ordered Task List Items. !31483 (Jared Deckard <jared.deckard@gmail.com>)
- Upgrade dependency to Go 1.8.3. !31943
- Add prometheus metrics on pipeline creation.
- Fix etag route not being a match for environments.
- Sort folder for environments.
- Support descriptions for snippets.
- Hide clone panel and file list when user is only a guest. (James Clark)
- Don’t create comment on JIRA if it already exists for the entity.
- Update Dashboard Groups UI with better support for subgroups.
- Confirm Project forking behaviour via the API.
- Add prometheus based metrics collection to gitlab webapp.
- Fix: Wiki is not searchable with Guest permissions.
- Center all empty states.
- Remove 'New issue' button when issues search returns no results.
- Add API URL to JIRA settings.
- animate adding issue to boards.
- Update session cookie key name to be unique to instance in development.
- Single click on filter to open filtered search dropdown.
- Makes header information of pipeline show page realtine.
- Creates a mediator for pipeline details vue in order to mount several vue apps with the same data.
- Scope issue/merge request recent searches to project.
- Increase individual diff collapse limit to 100 KB, and render limit to 200 KB.
- Fix Pipelines table empty state - only render empty state if we receive 0 pipelines.
- Make New environment empty state btn lowercase.
- Removes duplicate environment variable in documentation.
- Change links in issuable meta to black.
- Fix border-bottom for project activity tab.
- Adds new icon for CI skipped status.
- Create equal padding for emoji.
- Use briefcase icon for company in profile page.
- Remove overflow from comment form for confidential issues and vertically aligns confidential issue icon.
- Keep trailing newline when resolving conflicts by picking sides.
- Fix /unsubscribe slash command creating extra todos when you were already mentioned in an issue.
- Fix math rendering on blob pages.
- Allow group reporters to manage group labels.
- Use pre-wrap for commit messages to keep lists indented.
- Count badges depend on translucent color to better adjust to different background colors and permission badges now feature a pill shaped design similar to labels.
- Allow reporters to promote project labels to group labels.
- Enabled keyboard shortcuts on artifacts pages.
- Perform filtered search when state tab is changed.
- Remove duplication for sharing projects with groups in project settings.
- Change order of commits ahead and behind on divergence graph for branch list view.
- Creates CI Header component for Pipelines and Jobs details pages.
- Invalidate cache for issue and MR counters more granularly.
- disable blocked manual actions.
- Load tree readme asynchronously.
- Display extra info about files on .gitlab-ci.yml, .gitlab/route-map.yml and LICENSE blob pages.
- Fix replying to a commit discussion displayed in the context of an MR.
- Consistently use monospace font for commit SHAs and branch and tag names.
- Consistently display last push event widget.
- Don't copy empty elements that were not selected on purpose as GFM.
- Copy as GFM even when parts of other elements are selected.
- Autolink package names in Gemfile.
- Resolve N+1 query issue with discussions.
- Don't match email addresses or foo@bar as user references.
- Fix title of discussion jump button at top of page.
- Don't return nil for missing objects from parser cache.
- Make .gitmodules parsing more resilient to syntax errors.
- Add username parameter to gravatar URL.
- Autolink package names in more dependency files.
- Return nil when looking up config for unknown LDAP provider.
- Add system note with link to diff comparison when MR discussion becomes outdated.
- Don't wrap pasted code when it's already inside code tags.
- Revert 'New file from interface on existing branch'.
- Show last commit for current tree on tree page.
- Add documentation about adding foreign keys.
- add username field to push webhook. (David Turner)
- Rename CI/CD Pipelines to Pipelines in the project settings.
- Make environment tables responsive.
- Expand/collapse backlog & closed lists in issue boards.
- Fix GitHub importer performance on branch existence check.
- Fix counter cache for acts as taggable.
- Github - Fix token interpolation when cloning wiki repository.
- Fix token interpolation when setting the Github remote.
- Fix N+1 queries for non-members in comment threads.
- Fix terminals support for Kubernetes Service.
- Fix: A diff comment on a change at last line of a file shows as two comments in discussion.
- Instrument MergeRequestDiff#load_commits.
- Introduce source to Pipeline entity.
- Fixed create new label form in issue form not working for sub-group projects.
- Fixed style on unsubscribe page. (Gustav Ernberg)
- Enables inline editing for an issues title & description.
- Ask for an example project for bug reports.
- Add summary lines for collapsed details in the bug report template.
- Prevent commits from upstream repositories to be re-processed by forks.
- Avoid repeated queries for pipeline builds on merge requests.
- Preloads head pipeline for merge request collection.
- Handle head pipeline when creating merge requests.
- Migrate artifacts to a new path.
- Rescue OpenSSL::SSL::SSLError in JiraService & IssueTrackerService.
- Repository browser: handle in-repository submodule urls. (David Turner)
- Prevent project transfers if a new group is not selected.
- Allow 'no one' as an option for allowed to merge on a procted branch.
- Reduce time spent waiting for certain Sidekiq jobs to complete.
- Refactor ProjectsFinder#init_collection to produce more efficient queries for retrieving projects.
- Remove unused code and uses underscore.
- Restricts search projects dropdown to group projects when group is selected.
- Properly handle container registry redirects to fix metadata stored on a S3 backend.
- Fix LFS timeouts when trying to save large files.
- Set artifact working directory to be in the destination store to prevent unnecessary I/O.
- Strip trailing whitespaces in submodule URLs.
- Make sure reCAPTCHA configuration is loaded when spam checks are initiated.
- Fix up arrow not editing last discussion comment.
- Added application readiness endpoints to the monitoring health check admin view.
- Use wait_for_requests for both ajax and Vue requests.
- Cleanup ci_variables schema and table.
- Remove foreigh key on ci_trigger_schedules only if it exists.
- Allow translation of Pipeline Schedules.

## 9.2.10 (2017-08-09)

- Remove hidden symlinks from project import files.
- Disallow Git URLs that include a username or hostname beginning with a non-alphanumeric character.

## 9.2.9 (2017-07-20)

- Fix an infinite loop when handling user-supplied regular expressions.

## 9.2.8 (2017-07-19)

- Improve support for external issue references. !12485
- Renders 404 if given project is not readable by the user on Todos dashboard.
- Fix incorrect project authorizations.
- Remove uploads/appearance symlink. A leftover from a previous migration.

## 9.2.7 (2017-06-21)

- Reinstate is_admin flag in users api when authenticated user is an admin. !12211 (rickettm)

## 9.2.6 (2017-06-16)

- Fix the last coverage in trace log should be extracted. !11128 (dosuken123)
- Respect merge, instead of push, permissions for protected actions. !11648
- Fix pipeline_schedules pages throwing error 500. !11706 (dosuken123)
- Make backup task to continue on corrupt repositories. !11962
- Fix incorrect ETag cache key when relative instance URL is used. !11964
- Fix math rendering on blob pages.
- Invalidate cache for issue and MR counters more granularly.
- Fix terminals support for Kubernetes Service.
- Fix LFS timeouts when trying to save large files.
- Strip trailing whitespaces in submodule URLs.
- Make sure reCAPTCHA configuration is loaded when spam checks are initiated.
- Remove foreigh key on ci_trigger_schedules only if it exists.

## 9.2.5 (2017-06-07)

- No changes.

## 9.2.4 (2017-06-02)

- Fix visibility when referencing snippets.

## 9.2.3 (2017-05-31)

- Move uploads from 'public/uploads' to 'public/uploads/system'.
- Escapes html content before appending it to the DOM.
- Restrict API X-Frame-Options to same origin.
- Allow users autocomplete by author_id only for authenticated users.

## 9.2.2 (2017-05-25)

- Fix issue where real time pipelines were not cached. !11615
- Make all notes use equal padding.

## 9.2.1 (2017-05-23)

- Fix placement of note emoji on hover.
- Fix migration for older PostgreSQL versions.

## 9.2.0 (2017-05-22)

- API: Filter merge requests by milestone and labels. (10924)
- Reset New branch button when issue state changes. !5962 (winniehell)
- Frontend prevent authored votes. !6260 (Barthc)
- Change issues list in MR to natural sorting. !7110 (Jeff Stubler)
- Add animations to all the dropdowns. !8419
- Add update time to project lists. !8514 (Jeff Stubler)
- Remove view fragment caching for project READMEs. !8838
- API: Add parameters to allow filtering project pipelines. !9367 (dosuken123)
- Database SSL support for backup script. !9715 (Guillaume Simon)
- Fix UI inconsistency different files view (find file button missing). !9847 (TM Lee)
- Display slash commands outcome when previewing Markdown. !10054 (Rares Sfirlogea)
- Resolve "Add more tests for spec/controllers/projects/builds_controller_spec.rb". !10244 (dosuken123)
- Add keyboard edit shotcut for wiki. !10245 (George Andrinopoulos)
- Redirect old links after renaming a user/group/project. !10370
- Add system note on description change of issue/merge request. !10392 (blackst0ne)
- Improve validation of namespace & project paths. !10413
- Add board_move slash command. !10433 (Alex Sanford)
- Update all instances of the old loading icon. !10490 (Andrew Torres)
- Implement protected manual actions. !10494
- Implement search by extern_uid in Users API. !10509 (Robin Bobbitt)
- add support for .vue templates. !10517
- Only add newlines between multiple uploads. !10545
- Added balsamiq file viewer. !10564
- Remove unnecessary test helpers includes. !10567 (Jacopo Beschi @jacopo-beschi)
- Add tooltip to header of Done board. !10574 (Andy Brown)
- Fix redundant cache expiration in Repository. !10575 (blackst0ne)
- Add hashie-forbidden_attributes gem. !10579 (Andy Brown)
- Add spec for schema.rb. !10580 (blackst0ne)
- Keep webpack-dev-server process functional across branch changes. !10581
- Turns true value and false value database methods from instance to class methods. !10583
- Improve text on todo list when the todo action comes from yourself. !10594 (Jacopo Beschi @jacopo-beschi)
- Replace rake cache:clear:db with an automatic mechanism. !10597
- Remove heading and trailing spaces from label's color and title. !10603 (blackst0ne)
- Add webpack_bundle_tag helper to improve non-localhost GDK configurations. !10604
- Added quick-update (fade-in) animation to newly rendered notes. !10623
- Fix rendering emoji inside a string. !10647 (blackst0ne)
- Dockerfiles templates are imported from gitlab.com/gitlab-org/Dockerfile. !10663
- Add support for i18n on Cycle Analytics page. !10669
- Allow OAuth clients to push code. !10677
- Add configurable timeout for git fetch and clone operations. !10697
- Move labels of search results from bottom to title. !10705 (dr)
- Added build failures summary page for pipelines. !10719
- Expand/collapse button -> Change to make it look like a toggle. !10720 (Jacopo Beschi @jacopo-beschi)
- Decrease ABC threshold to 57.08. !10724 (Rydkin Maxim)
- Removed target blank from the metrics action inside the environments list. !10726
- Remove Repository#version method and tests. !10734
- Refactor Admin::GroupsController#members_update method and add some specs. !10735
- Refactor code that creates project/group members. !10735
- Add Slack slash command api to services documentation and rearrange order and cases. !10757 (TM Lee)
- Disable test settings on chat notification services when repository is empty. !10759
- Add support for instantly updating comments. !10760
- Show checkmark on current assignee in assignee dropdown. !10767
- Remove pipeline controls for last deployment from Environment monitoring page. !10769
- Pipeline view updates in near real time. !10777
- Fetch pipeline status in batch from redis. !10785
- Add username to activity atom feed. !10802 (winniehell)
- Support Markdown previews for personal snippets. !10810
- Implement ability to edit hooks. !10816 (Alexander Randa)
- Allow admins to sudo to blocked users via the API. !10842
- Don't display the is_admin flag in most API responses. !10846
- Refactor add_users method for project and group. !10850
- Pipeline schedules got a new and improved UI. !10853
- Fix updating merge_when_build_succeeds via merge API endpoint. !10873
- Add index on ci_builds.user_id. !10874 (blackst0ne)
- Improves test settings for chat notification services for empty projects. !10886
- Change Git commit command in Existing folder to git commit -m. !10900 (TM Lee)
- Show group name on flash container when group is created from Admin area. !10905
- Make markdown tables thinner. !10909 (blackst0ne)
- Ensure namespace owner is Master of project upon creation. !10910
- Updated CI status favicons to include the tanuki. !10923
- Decrease Cyclomatic Complexity threshold to 16. !10928 (Rydkin Maxim)
- Replace header merge request icon. !10932 (blackst0ne)
- Fix error on CI/CD Settings page related to invalid pipeline trigger. !10948 (dosuken123)
- rickettm Add repo parameter to gitaly:install and workhorse:install rake tasks. !10979 (M. Ricketts)
- Generate and handle a gl_repository param to pass around components. !10992
- Prevent 500 errors caused by testing the Prometheus service. !10994
- Disable navigation to Project-level pages configuration when Pages disabled. !11008
- Fix caching large snippet HTML content on MySQL databases. !11024
- Hide external environment URL button on terminal page if URL is not defined. !11029
- Always show the latest pipeline information in the commit box. !11038
- Fix misaligned buttons in wiki pages. !11043
- Colorize labels in search field. !11047
- Sort the network graph both by commit date and topographically. !11057
- Remove carriage returns from commit messages. !11077
- Add tooltips to user contribution graph key. !11138
- Add German translation for Cycle Analytics. !11161
- Fix skipped manual actions problem when processing the pipeline. !11164
- Fix cross referencing for private and internal projects. !11243
- Add state to MR widget that prevent merges when branch changes after page load. !11316
- Fixes the 500 when accessing customized appearance logos. !11479 (Alexis Reigel)
- Implement Users::BuildService. !30349 (George Andrinopoulos)
- Display comments for personal snippets.
- Support comments for personal snippets.
- Support uploaders for personal snippets comments.
- Handle incoming emails from aliases correctly.
- Re-rewrites pipeline graph in vue to support realtime data updates.
- Add issues/:iid/closed_by api endpoint. (mhasbini)
- Disallow merge requests from fork when source project have disabled merge requests. (mhasbini)
- Improved UX on project members settings view.
- Clear emoji search in awards menu after picking emoji.
- Cleanup markdown spacing.
- Separate CE params on Grape API.
- Allow to create new branch and empty WIP merge request from issue page.
- Prevent people from creating branches if they don't have persmission to push.
- Redesign auth 422 page.
- 29595 Update callout design.
- Detect already enabled DeployKeys in EnableDeployKeyService.
- Add transparent top-border to the hover state of done todos.
- Refactor all CI vue badges to use the same vue component.
- Update note edits in real-time.
- Add button to delete filters from filtered search bar.
- Added profile name to user dropdown.
- Display GitLab Pages status in Admin Dashboard.
- Fix label creation from issuable for subgroup projects.
- Vertically align mini pipeline stage container.
- prevent nav tabs from wrapping to new line.
- Fix environments vue architecture to match documentation.
- Enforce project features when searching blobs and wikis.
- fix inline diff copy in firefox.
- Note Ghost user and refer to user deletion documentation.
- Expose project statistics on single requests via the API.
- Job dropdown of pipeline mini graph updates in realtime when its opened.
- Add default margin-top to user request table on project members page.
- Add tooltips to note action buttons.
- Remove `#` being added on commit sha in MR widget.
- Remove spinner from loading comment.
- Fixes an issue preventing screen readers from reading some icons.
- Load milestone tabs asynchronously to increase initial load performance.
- [BB Importer] Save the error trace and the whole raw document to debug problems easier.
- Fixed branches dropdown rendering branch names as HTML.
- Make Asciidoc & other markup go through pipeline to prevent XSS.
- Validate URLs in markdown using URI to detect the host correctly.
- Side-by-side view in commits correcly expands full window width.
- Deploy keys load are loaded async.
- Fixed spacing of discussion submit buttons.
- Add hostname to usage ping.
- Allow usage ping to be disabled completely in gitlab.yml.
- Add artifact file page that uses the blob viewer.
- Add breadcrumb, build header and pipelines submenu to artifacts browser.
- Show Raw button as Download for binary files.
- Add Source/Rendered switch to blobs for SVG, Markdown, Asciidoc and other text files that can be rendered.
- Catch all URI errors in ExternalLinkFilter.
- Allow commenting on older versions of the diff and comparisons between diff versions.
- Paste a copied MR source branch name as code when pasted into a GFM form.
- Fix commenting on an existing discussion on an unchanged line that is no longer in the diff.
- Link to outdated diff in older MR version from outdated diff discussion.
- Bump Sidekiq to 5.0.0.
- Use blob viewers for snippets.
- Add download button to project snippets.
- Display video blobs in-line like images.
- Gracefully handle failures for incoming emails which do not match on the To header, and have no References header.
- Added title to award emoji buttons.
- Fixed alignment of empty task list items.
- Removed the target=_blank from the monitoring component to prevent opening a new tab.
- Fix new admin integrations not taking effect on existing projects.
- Prevent further repository corruption when resolving conflicts from a fork where both the fork and upstream projects require housekeeping.
- Add missing project attributes to Import/Export.
- Remove N+1 queries in processing MR references.
- Fixed wrong method call on notify_post_receive. (Luigi Leoni)
- Fixed search terms not correctly highlighting.
- Refactored the anchor tag to remove the trailing space in the target branch.
- Prevent user profile tabs to display raw json when going back and forward in browser history.
- Add index to webhooks type column.
- Change line-height on build-header so elements don't overlap. (Dino Maric)
- Fix dead link to GDK on the README page. (Dino Maric)
- Fixued preview shortcut focusing wrong preview tab.
- Issue assignees are now removed without loading unnecessary data into memory.
- Refactor backup/restore docs.
- Fixed group issues assignee dropdown loading all users.
- Fix for XSS in project import view caused by Hamlit filter usage.
- Fixed avatar not display on issue boards when Gravatar is disabled.
- Fixed create new label form in issue boards sidebar.
- Add realtime descriptions to issue show pages.
- Issue API change: assignee_id parameter and assignee object in a response have been deprecated.
- Fixed bug where merge request JSON would be displayed.
- Fixed Prometheus monitoring graphs not showing empty states in certain scenarios.
- Removed the milestone references from the milestone views.
- Show sizes correctly in merge requests when diffs overflow.
- Fix notify_only_default_branch check for Slack service.
- Make the `gitlab:gitlab_shell:check` task check that the repositories storage path are owned by the `root` group.
- Optimise pipelines.json endpoint.
- Pass docsUrl to pipeline schedules callout component.
- Fixed alignment of CI icon in issues related branches.
- Set the issuable sidebar to remain closed for mobile devices.
- Sanitize submodule URLs before linking to them in the file tree view.
- Upgrade Sidekiq to 4.2.10.
- Cache Routable#full_path in RequestStore to reduce duplicate route loads.
- Refactor snippets finder & dont return internal snippets for external users.
- Fix snippets visibility for show action - external users can not see internal snippets.
- Store retried in database for CI Builds.
- repository browser: handle submodule urls that don't end with .git. (David Turner)
- Fixed tags sort from defaulting to empty.
- Do not show private groups on subgroups page if user doesn't have access to.
- Make MR link in build sidebar bold.
- Unassign all Issues and Merge Requests when member leaves a team.
- Fix preemptive scroll bar on user activity calendar.
- Pipeline chat notifications convert seconds to minutes and hours.

## 9.1.10 (2017-08-09)

- Remove hidden symlinks from project import files.
- Disallow Git URLs that include a username or hostname beginning with a non-alphanumeric character.

## 9.1.9 (2017-07-20)

- Fix an infinite loop when handling user-supplied regular expressions.

## 9.1.8 (2017-07-19)

- Improve support for external issue references. !12485
- Renders 404 if given project is not readable by the user on Todos dashboard.
- Fix incorrect project authorizations.
- Remove uploads/appearance symlink. A leftover from a previous migration.

## 9.1.7 (2017-06-07)

- No changes.

## 9.1.6 (2017-06-02)

- Fix visibility when referencing snippets.

## 9.1.5 (2017-05-31)

- Move uploads from 'public/uploads' to 'public/uploads/system'.
- Restrict API X-Frame-Options to same origin.
- Allow users autocomplete by author_id only for authenticated users.

## 9.1.4 (2017-05-12)

- Fix error on CI/CD Settings page related to invalid pipeline trigger. !10948 (dosuken123)
- Sort the network graph both by commit date and topographically. !11057
- Fix cross referencing for private and internal projects. !11243
- Handle incoming emails from aliases correctly.
- Gracefully handle failures for incoming emails which do not match on the To header, and have no References header.
- Add missing project attributes to Import/Export.
- Fixed search terms not correctly highlighting.
- Fixed bug where merge request JSON would be displayed.

## 9.1.3 (2017-05-05)

- Do not show private groups on subgroups page if user doesn't have access to.
- Enforce project features when searching blobs and wikis.
- Fixed branches dropdown rendering branch names as HTML.
- Make Asciidoc & other markup go through pipeline to prevent XSS.
- Validate URLs in markdown using URI to detect the host correctly.
- Fix for XSS in project import view caused by Hamlit filter usage.
- Sanitize submodule URLs before linking to them in the file tree view.
- Refactor snippets finder & dont return internal snippets for external users.
- Fix snippets visibility for show action - external users can not see internal snippets.

## 9.1.2 (2017-05-01)

- Add index on ci_runners.contacted_at. !10876 (blackst0ne)
- Fix pipeline events description for Slack and Mattermost integration. !10908
- Fixed milestone sidebar showing incorrect number of MRs when collapsed. !10933
- Fix ordering of commits in the network graph. !10936
- Ensure the chat notifications service properly saves the "Notify only default branch" setting. !10959
- Lazily sets UUID in ApplicationSetting for new installations.
- Skip validation when creating internal (ghost, service desk) users.
- Use GitLab Pages v0.4.1.

## 9.1.1 (2017-04-26)

- Add a transaction around move_issues_to_ghost_user. !10465
- Properly expire cache for all MRs of a pipeline. !10770
- Add sub-nav for Project Integration Services edit page. !10813
- Fix missing duration for blocked pipelines. !10856
- Fix lastest commit status text on main project page. !10863
- Add index on ci_builds.updated_at. !10870 (blackst0ne)
- Fix 500 error due to trying to show issues from pending deleting projects. !10906
- Ensures that OAuth/LDAP/SAML users don't need to be confirmed.
- Ensure replying to an individual note by email creates a note with its own discussion ID.
- Fix OAuth, LDAP and SAML SSO when regular sign-ups are disabled.
- Fix usage ping docs link from empty cohorts page.
- Eliminate N+1 queries in loading namespaces for every issuable in milestones.

## 9.1.0 (2017-04-22)

- Add Jupyter notebook rendering !10017
- Added merge requests empty state. !7342
- Add option to start a new resolvable discussion in an MR. !7527
- Hide form inputs for group member without editing rights. !7816
- Create a new issue for a single discussion in a Merge Request. !8266 (Bob Van Landuyt)
- Adding non_archived scope for counting projects. !8305 (Naveen Kumar)
- Don't show links to tag a commit for users that are not permitted. !8407
- New file from interface on existing branch. !8427 (Jacopo Beschi @jacopo-beschi)
- Strip reference prefixes on branch creation. !8498 (Matthieu Tardy)
- Support 2FA requirement per-group. !8763 (Markus Koller)
- Add Undo to Todos in the Done tab. !8782 (Jacopo Beschi @jacopo-beschi)
- Shows 'Go Back' link only when browser history is available. !9017
- Implement user create service. !9220 (George Andrinopoulos)
- Incorporate Gitaly client for refs service. !9291
- Cancel pending pipelines if commits not HEAD. !9362 (Rydkin Maxim)
- Add indication for closed or merged issuables in GFM. !9462 (Adam Buckland)
- Periodically clean up temporary upload files to recover storage space. !9466 (blackst0ne)
- Use toggle button to expand / collapse mulit-nested groups. !9501
- Fixes dismissable error close is not visible enough. !9516
- Fixes an issue in the new merge request form, where a tag would be selected instead of a branch when they have the same names. !9535 (Weiqing Chu)
- Expose CI/CD status API endpoints with Gitlab::Ci::Status facility on pipeline, job and merge request for favicon. !9561 (dosuken123)
- Use Gitaly for CommitController#show. !9629
- Order milestone issues by position ascending in api. !9635 (George Andrinopoulos)
- Convert Issue into ES6 class. !9636 (winniehell)
- Link issuable reference to itself in meta-header. !9641 (mhasbini)
- Add ability to disable Merge Request URL on push. !9663 (Alex Sanford)
- ProjectsFinder should handle more options. !9682 (Jacopo Beschi @jacopo-beschi)
- Fix create issue form buttons are misaligned on mobile. !9706 (TM Lee)
- Labels support color names in backend. !9725 (Dongqing Hu)
- Standardize on core-js for es2015 polyfills. !9749
- Fix GitHub Import deleting branches for open PRs from a fork. !9758
- Do not show LFS object when LFS is disabled. !9779 (Christopher Bartz)
- Fix symlink icon in project tree. !9780 (mhasbini)
- Fix bug when system hook for deploy key. !9796 (billy.lb)
- Make authorized projects worker use a specific queue instead of the default one. !9813
- Simplify trigger_docs build job for CE and EE. !9820 (winniehell)
- Add `aria-label` for feature status accessibility. !9830
- Add dashboard and group milestones count badges. !9836 (Alex Braha Stoll)
- Use Gitaly for Repository#is_ancestor. !9864
- After copying a diff file or blob path, pasting it into a comment field will format it as Markdown. !9876
- Fix visibility level on new project page. !9885 (blackst0ne)
- Fix xml.updated field in rss/atom feeds. !9889 (blackst0ne)
- Add Undo mark all as done to Todos. !9890 (Jacopo Beschi @jacopo-beschi)
- Add a name field to the group form. !9891 (Douglas Lovell)
- Add custom attributes in factories. !9892 (George Andrinopoulos)
- Resolve project pipeline status caching problem on dashboard. !9895
- Display error message when deleting tag in web UI fails. !9906
- Add quick submit for snippet forms. !9911 (blackst0ne)
- New directory from interface on existing branch. !9921 (Jacopo Beschi @jacopo-beschi)
- Removes UJS from pipelines tables. !9929
- Fix project title validation, prevent clicking on disabled button. !9931
- Show correct user & creation time in heading of the pipeline page. !9936
- Include time tracking attributes in webhooks payload. !9942
- Add `requirements: { id: /.+/ }` for all projects and groups namespaced API routes. !9944
- Improved UX for the environments metrics view. !9946
- Remove whitespace in group links. !9947 (Xurxo Méndez Pérez)
- Adds Frontend Styleguide to documentation. !9961
- Add metadata to system notes. !9964
- When viewing old wiki page version, edit button should be disabled. !9966 (TM Lee)
- Added labels array to the issue web hook returned object. !9972
- Upgrade VueJS to v2.2.4 and disable dev mode warnings. !9981
- Only add code coverage instrumentation when generating coverage report. !9987
- Fix Project Wiki update. !9990 (Dongqing Hu)
- Fix trigger webhook for ref with a dot. !10001 (George Andrinopoulos)
- Fix quick submit short-cut on preview tab for comments. !10002
- Add option to receive email notifications about your own activity. !10032 (Richard Macklin)
- Rename 'All issues' to 'Open issues' in Add issues modal. !10042 (blackst0ne)
- Disable pipeline and environment actions that are not playable. !10052
- Added clarification to the Jira integration documentation. !10066 (Matthew Bender)
- Move milestone summary content into the sidebar. !10096
- Replace closing MR icon. !10103 (blackst0ne)
- Add support for multi-level container image repository names. !10109 (André Guede)
- Add ECMAScript polyfills for Symbol and Array.find. !10120
- Add tooltip to user's calendar activities. !10123 (Alex Argunov)
- Resolve "Run CI/CD pipelines on a schedule" - "Basic backend implementation". !10133 (dosuken123)
- Change hint on first row of filters dropdown to `Press Enter or click to search`. !10138
- Remove useless queries with false conditions (e.g 1=0). !10141 (mhasbini)
- Show CI status as Favicon on Pipelines, Job and MR pages. !10144
- Update color palette to a more harmonious and consistent one. !10154
- Add tooltip and accessibility for profile cover buttons. !10182
- Change Done column to Closed in issue boards. !10198 (blackst0ne)
- Add metrics button to environments overview page. !10234
- Force unlimited terminal size when checking processes via call to ps. !10246 (Sebastian Reitenbach)
- Fix sub-nav highlighting for `Environments` and `Jobs` pages. !10254
- Drop support for correctly processing legacy pipelines. !10266
- Fix project creation failure due to race condition in namespace directory creation. !10268 (Robin Bobbitt)
- Introduced error/empty states for the environments performance metrics. !10271
- Improve performance of GitHub importer for large repositories. !10273
- Introduce "polling_interval_multiplier" as application setting. !10280
- Prevent users from disconnecting GitLab account from CAS. !10282
- Clearly show who triggered the pipeline in email. !10283
- Make user mentions case-insensitive. !10285 (blackst0ne)
- Update rugged to 0.25.1.1. !10286 (Elan Ruusamäe)
- Handle parsing OpenBSD ps output properly to display sidekiq infos on admin->monitoring->background. !10303 (Sebastian Reitenbach)
- Log errors during generating of GitLab Pages to debug log. !10335 (Danilo Bargen)
- Update issue board cards design. !10353
- Tags can be protected, restricting creation of matching tags by user role. !10356
- Set GIT_TERMINAL_PROMPT env variable in initializer. !10372
- Remove index for users.current sign in at. !10401 (blackst0ne)
- Include reopened MRs when searching for opened ones. !10407
- Integrates Microsoft Teams webhooks with GitLab. !10412
- Fix subgroup repository disappearance if group was moved. !10414
- Add /-/readiness /-/liveness and /-/metrics endpoints to track application health. !10416
- Changed capitalisation of buttons across GitLab. !10418
- Fix blob highlighting in search. !10420
- Add remove_concurrent_index to database helper. !10441 (blackst0ne)
- Fix wiki commit message. !10464 (blackst0ne)
- Deleting a user should not delete associated records. !10467
- Include endpoint in metrics for ETag caching middleware. !10495
- Change project view default for existing users and anonymous visitors to files+readme. !10498
- Hide header counters for issue/mr/todos if zero. !10506
- Remove the User#is_admin? method. !10520 (blackst0ne)
- Removed Milestone#is_empty?. !10523 (Jacopo Beschi @jacopo-beschi)
- Add UI for Trigger Schedule. !10533 (dosuken123)
- Add foreign key for ci_trigger_requests on ci_triggers. !10537
- Upgrade webpack to v2.3.3 and webpack-dev-server to v2.4.2. !10552
- Bugfix: POST /projects/:id/hooks and PUT /projects/:id/hook/:hook_id no longer ignore the the job_events param in the V4 API. !10586
- Fix MR widget bug that merged a MR when Merge when pipeline succeeds was clicked via the dropdown. !10611
- Hide new subgroup button if user has no permission to create one. !10627
- Fix PlantUML integration in GFM. !10651
- Show sub-nav under Merge Requests when issue tracker is non-default. !10658
- Fix bad query for PostgreSQL showing merge requests list. !10666
- Fix invalid encoding when showing some traces. !10681
- Add lighter colors and fix existing light colors. !10690
- Fix another case where trace does not have proper encoding set. !10728
- Fix trace cannot be written due to encoding. !10758
- Replace builds_enabled with jobs_enabled in projects API v4. !10786 (winniehell)
- Add retry to system hook worker. !10801
- Fix error when an issue reference has a pending deleting project. !10843
- Update permalink/blame buttons with line number fragment hash.
- Limit line length for project home page.
- Fix filtered search input width for IE.
- Update wikis_controller.rb to use strong params.
- Fix API group/issues default state filter. (Alexander Randa)
- Prevent builds dropdown to close when the user clicks in a build.
- Display all closed issues in “done” board list.
- Remove no-new annotation from file_template_mediator.js.
- Changed dropdown style slightly.
- Change gfm textarea to use monospace font.
- Prevent filtering issues by multiple Milestones or Authors.
- Recent search history for issues.
- Remove duplicated tokens in issuable search bar.
- Adds empty and error state to pipelines.
- Allow admin to view all namespaces. (George Andrinopoulos)
- allow offset query parameter for infinite list pages.
- Fix wrong message on starred projects filtering. (George Andrinopoulos)
- Adds pipeline mini-graph to system information box in Commit View.
- Remove confusing placeholder for JIRA transition_id.
- Remove extra margin at bottom of todos page.
- Add back expandable folder behavior.
- Create todos only for new mentions.
- Linking to blob edit page handles anonymous users and users without enough permissions to edit directly.
- Fix projects_limit RangeError on user create. (Alexander Randa)
- Add helpful icons to profile events.
- Refactor dropdown_milestone_spec.rb. (George Andrinopoulos)
- Fix alignment of resolve button.
- Change label for name on sign up form.
- Don’t show source project name when user does not have access.
- Update toggle buttons to be <button>.
- Display full project name with namespace upon deletion.
- Spam check only when spammable attributes have changed.
- align Mark all as done with other Done buttons on Todos page.
- Adds polling utility function for vue resource.
- Allow unauthenticated access to some Branch API GET endpoints.
- Fix redirection after login when the referer have params. (mhasbini)
- fix sidebar padding for build and wiki pages.
- Correctly update paths when changing a child group.
- Add shortcuts and counters to MRs and issues in navbar.
- Remove forced scroll into view when switching to Changes MR tab.
- Fix link to Jira service documentation.
- consistent icons in vue and kaminari pagers.
- refocus textarea after attaching a file.
- Enable creation of deploy keys with write access via the API.
- Disable invalid service templates.
- Remove the class attribute from the whitelist for HTML generated from Markdown.
- Add search optional param and docs for V4.
- Fix issue's note cache expiration after delete. (mhasbini)
- Fixes HTML structure that was preventing the tooltip to disappear when hovering out of the button.
- fix Status icons overlapping sidebar on mobile.
- Add dropdown sort to project milestones. (George Andrinopoulos)
- Prevent more than one issue tracker to be active for the same project. (luisdgs19)
- Add copy button to blob header and use icon for Raw button.
- Add metrics events for incoming emails.
- Shows loading icon in issue boards modal when changing filters.
- Added tests for the w.gl.utils.backOff promise.
- Add `g t` global shortcut to go to todos.
- Fix conflict resolution when files contain valid UTF-8 characters.
- Added award emoji animation and improved active state.
- Fixes milestone/merge_requests endpoint to actually scope the result. (Joren De Groof)
- Added remaining_time method to milestoneish, specs and updated the milestone_helper milestone_remaining_days method to correctly return the correct remaining time. (Michael Robinson)
- Removed unnecessary 'add' text in additional award emoji button.
- adds todo functionality to closed issuable sidebar and changes todo bell icon to check-square.
- Copy code as GFM from diffs, blobs and GFM code blocks.
- Removed the duplicated search icon in the award emoji menu.
- Enable snippets for new projects by default.
- Add rake task to import GitHub projects from the command line.
- New rake task to reset all email and private tokens.
- Fix path disclosure in project import/export.
- Fix 'Object not found - no match for id (sha)' when importing GitHub Pull Requests.
- Display custom hook error messages when automatic merge is enabled.
- Fix layout of projects page on admin area.
- Fix encoding issue exporting a project.
- Periodically mark projects that are stuck in importing as failed.
- Skip groups validation on the client.
- Fix Import/Export MR diffs not showing and missing forked MRs.
- Create subgroups if they don't exist while importing projects.
- Fix Milestone name on show page. (Raveesh)
- Fix missing capitalisation on views.
- Removed orphaned notification settings without a namespace.
- Fix restricted project visibility setting available to users.
- Moved the gear settings dropdown to a tab in the groups view.
- Fixed group milestone date dropdowns not opening.
- Fixed bug in issue boards which stopped cards being able to be dragged.
- Added new filtered search bar to issue boards.
- Add closed_at field to issues.
- Do not set closed_at to nil when issue is reopened.
- Centered issues empty state.
- Fixed private group name disclosure via new/update forms.
- Add keyboard shortcuts to main menu.
- Moved the monitoring button inside the show view for the environments page.
- Speed up initial rendering of MR diffs page.
- Fixed tabs on new merge request page causing incorrect URLs.
- Fix for open redirect vulnerability using continue[to] in URL when requesting project import status.
- Fix for open redirect vulnerabilities in todos, issues, and MR controllers.
- Optimise builds endpoint.
- Fixed pipeline actions tooltips overflowing.
- Fixed job tooltip being cut-off.
- Fixed projects list lines breaking.
- Only email pipeline creators; only email for successful pipelines with custom settings.
- Reset users.authorized_projects_populated to automatically refresh user permissions.
- Corrected alignment for the remember-me checkbox in the login view.
- Fixed tabs not scrolling on mobile.
- Add unique index for notes_id to system note metadata table.
- Handle SSH keys that have multiple spaces between each marker.
- Don't delete a branch involved in an open merge request in "Delete all merged branches" service.
- Relax constraint on Wiki IDs, since subdirectories can contain spaces.
- Remove Tags filter from Projects Explore dropdown.
- Enable Style/Proc cop for rubocop. (mhasbini)
- Show the build/pipeline coverage if it is available.
- Corrected time tracking icon color in the issuable side bar.
- update test_bundle.js ignored files.
- Add usage ping to CE.
- User callout only shows on current users profile.
- Removed the hours & minutes from the users start date on their profile.
- Only send chat notifications for the default branch.
- Don't fill in the default kubernetes namespace.

## 9.0.13 (2017-08-09)

- Remove hidden symlinks from project import files.
- Disallow Git URLs that include a username or hostname beginning with a non-alphanumeric character.

## 9.0.12 (2017-07-20)

- Fix an infinite loop when handling user-supplied regular expressions.

## 9.0.11 (2017-07-19)

- Renders 404 if given project is not readable by the user on Todos dashboard.
- Fix incorrect project authorizations.
- Remove uploads/appearance symlink. A leftover from a previous migration.

## 9.0.10 (2017-06-07)

- No changes.

## 9.0.9 (2017-06-02)

- Fix visibility when referencing snippets.

## 9.0.8 (2017-05-31)

- Move uploads from 'public/uploads' to 'public/uploads/system'.
- Restrict API X-Frame-Options to same origin.
- Allow users autocomplete by author_id only for authenticated users.

## 9.0.7 (2017-05-05)

- Enforce project features when searching blobs and wikis.
- Fixed branches dropdown rendering branch names as HTML.
- Make Asciidoc & other markup go through pipeline to prevent XSS.
- Validate URLs in markdown using URI to detect the host correctly.
- Fix for XSS in project import view caused by Hamlit filter usage.
- Sanitize submodule URLs before linking to them in the file tree view.
- Refactor snippets finder & dont return internal snippets for external users.
- Fix snippets visibility for show action - external users can not see internal snippets.
- Do not show private groups on subgroups page if user doesn't have access to.

## 9.0.6 (2017-04-21)

- Bugfix: POST /projects/:id/hooks and PUT /projects/:id/hook/:hook_id no longer ignore the the job_events param in the V4 API. !10586
- Fix MR widget bug that merged a MR when Merge when pipeline succeeds was clicked via the dropdown. !10611
- Fix PlantUML integration in GFM. !10651
- Show sub-nav under Merge Requests when issue tracker is non-default. !10658
- Fix restricted project visibility setting available to users.
- Removed orphaned notification settings without a namespace.
- Fix issue's note cache expiration after delete. (mhasbini)
- Display custom hook error messages when automatic merge is enabled.
- Fix filtered search input width for IE.

## 9.0.5 (2017-04-10)

- Add shortcuts and counters to MRs and issues in navbar.
- Disable invalid service templates.
- Handle SSH keys that have multiple spaces between each marker.

## 9.0.4 (2017-04-05)

- Don’t show source project name when user does not have access.
- Remove the class attribute from the whitelist for HTML generated from Markdown.
- Fix path disclosure in project import/export.
- Fix for open redirect vulnerability using continue[to] in URL when requesting project import status.
- Fix for open redirect vulnerabilities in todos, issues, and MR controllers.

## 9.0.3 (2017-04-05)

- Fix name colision when importing GitHub pull requests from forked repositories. !9719
- Fix GitHub Importer for PRs of deleted forked repositories. !9992
- Fix environment folder route when special chars present in environment name. !10250
- Improve Markdown rendering when a lot of merge requests are referenced. !10252
- Allow users to import GitHub projects to subgroups.
- Backport API changes needed to fix sticking in EE.
- Remove unnecessary ORDER BY clause from `forked_to_project_id` subquery. (mhasbini)
- Make CI build to use optimistic locking only on status change.
- Fix race condition where a namespace would be deleted before a project was deleted.
- Fix linking to new issue with selected template via url parameter.
- Remove unnecessary ORDER BY clause when updating todos. (mhasbini)
- API: Make the /notes endpoint work with noteable iid instead of id.
- Fixes method not replacing URL parameters correctly and breaking pipelines pagination.
- Move issue, mr, todos next to profile dropdown in top nav.

## 9.0.2 (2017-03-29)

- Correctly update paths when changing a child group.
- Fixed private group name disclosure via new/update forms.

## 9.0.1 (2017-03-28)

- Resolve "404 when requesting build trace". !9759 (dosuken123)
- Simplify search queries for projects and merge requests. !10053 (mhasbini)
- Fix after_script processing for Runners APIv4. !10185
- Fix escaped html appearing in milestone page. !10224
- Fix bug that caused jobs that already had been retried to be retried again when retrying a pipeline. !10249
- Allow filtering by all started milestones.
- Allow sorting by due date and priority.
- Fixed branches pagination not displaying.
- Fixed filtered search not working in IE.
- Optimize labels finder query when searching for a project with a group. (mhasbini)

## 9.0.0 (2017-03-22)

- Fix inconsistent naming for services that delete things. !5803 (dixpac)
- UI: Allow a project variable to be set to an empty value. !6044 (Lukáš Nový)
- Align task list checkboxes. !6487 (Jared Deckard <jared.deckard@gmail.com>)
- SanitizationFilter allows html5 details and summary tags. !6568
- on branch deletion show loading icon and disabled the button. !6761 (wendy0402)
- Use an entity for RepoBranch commits and enhance RepoCommit. !7138 (Ben Boeckel)
- Deleting a user doesn't delete issues they've created/are assigned to. !7393
- Fix position of counter in milestone panels. !7842 (Andrew Smith (EspadaV8))
- Added a feature to create a 'directly addressed' Todo when mentioned in the beginning of a line. !7926 (Ershad Kunnakkadan)
- Implement OpenID Connect identity provider. !8018 (Markus Koller)
- Show directory hierarchy when listing wiki pages. !8133 (Alex Braha Stoll)
- Migrate SlackService and MattermostService from build_events to pipeline_events, and migrate BuildsEmailService to PipelinesEmailService. Update Hipchat to use pipeline events rather than build events. !8196
- Execute web hooks for WikiPage delete operation. !8198
- Added external environment link to web terminal view. !8303
- Responsive title in diffs inline, side by side, with and without sidebar. !8475
- Bypass email domain validation when a user is created by an admin. !8575 (Reza Mohammadi @remohammadi)
- API: Paginate all endpoints that return an array. !8606 (Robert Schilling)
- pass in current_user in MergeRequest and MergeRequestsHelper. !8624 (Dongqing Hu)
- Add user & build links in Slack Notifications. !8641 (Poornima M)
- Todo done clicking is kind of unusable. !8691 (Jacopo Beschi @jacopo-beschi)
- Filter todos by manual add. !8691 (Jacopo Beschi @jacopo-beschi)
- Add runner version to /admin/runners view. !8733 (Jonathon Reinhart)
- API: remove `public` param for projects. !8736
- Allow creating nested groups via UI. !8786
- API: Add environment stop action. !8808
- Add discussion events to contributions calendar. !8821
- Unify issues search behavior by always filtering when ALL labels matches. !8849
- V3 deprecated templates endpoints removal. !8853
- Expose pipelines as PipelineBasic `api/v3/projects/:id/pipelines`. !8875
- Alphabetically sort tags on runner list. !8922 (blackst0ne)
- Added documentation for permalinks to most recent build artifacts. !8934 (Christian Godenschwager)
- Standardize branch name params as branch on V4 API. !8936
- Move /projects/fork/:id to /projects/:id/fork. !8940
- Fix small height of activity header page. !8952 (Pavel Sorokin)
- Optionally make users created via the API set their password. !8957 (Joost Rijneveld)
- GitHub Importer - Find users based on GitHub email address. !8958
- API: Consolidate /projects endpoint. !8962
- Add filtered search visual tokens. !8969
- Store group and project full name and full path in routes table. !8979
- Add internal API to notify Gitaly of post receive. !8983
- Remove inactive default email services. !8987
- Option to prevent signing in from multiple ips. !8998
- Download snippets with LF line-endings by default. !8999
- Fixes dropdown width in admin project page. !9002
- fixes issue number alignment problem in MR and issue list. !9020
- Fix CI/CD pipeline retry and take stages order into account. !9021
- Make stuck builds detection more performant. !9025
- Filter by projects in the end of search. !9030
- Add nested groups to the API. !9034
- Use ETag to improve performance of issue notes polling. !9036
- Add the oauth2_generic OmniAuth strategy. !9048 (Joe Marty)
- Brand header logo for pipeline emails. !9049 (Alexis Reigel)
- replace npm with yarn and add yarn.lock. !9055
- Fix displaying error messages for create label dropdown. !9058 (Tom Koole)
- Set dropdown height fixed to 250px and make it scrollable. !9063
- Update API docs for new namespace format. !9073 (Markus Koller)
- Replace static fixture for behaviors/quick_submit_spec.js. !9086 (winniehell)
- Use iids as filter parameter. !9096
- Manage user personal access tokens through api and add impersonation tokens. !9099 (Simon Vocella)
- Added the ability to copy a branch name to the clipboard. !9103 (Glenn Sayers)
- Rename Files::DeleteService to Files::DestroyService. !9110 (dixpac)
- Fixes FE Doc broken link. !9120
- Add git version to gitlab:env:info. !9128 (Semyon Pupkov)
- Replace static fixture for new_branch_spec.js. !9131 (winniehell)
- Reintroduce coverage report for JavaScript. !9133 (winniehell)
- Fix MR widget jump. !9146
- Avoid calling Build#trace_with_state for performance. !9149 (Takuya Noguchi)
- fix background color for labels mention in todo. !9155 (mhasbini)
- Replace static fixture for behaviors/requires_input_spec.js. !9162 (winniehell)
- Added AsciiDoc Snippet to CI/CD Badges. !9164 (Jan Christophersen)
- Make Karma output look nicer for CI. !9165 (winniehell)
- show 99+ for large count in todos notification bell. !9171 (mhasbini)
- Replace static fixture for header_spec.js. !9174 (winniehell)
- Replace static fixture for project_title_spec.js. !9175 (winniehell)
- Fixes markdown in activity-feed is gray. !9179
- Show notifications settings dropdown even if repository feature is disabled. !9180
- Fixes job dropdown action throws error in js console. !9182
- Set maximum width for mini pipeline graph text so it is not truncated to early. !9188
- Added 'Most Recent Activity' header to the User Profile page. !9189 (Jan Christophersen)
- Show Issues mentioned / being closed from a Merge Requests title below the 'Accept Merge Request' button. !9194 (Jan Christophersen)
- Stop linking to deleted Branches in Activity tabs. !9203 (Jan Christophersen)
- Make it possible to pass coverage value to commit status API. !9214 (wendy0402)
- Add admin setting for default artifacts expiration. !9219
- add :iids param to IssuableFinder (resolve technical dept). !9222 (mhasbini)
- Add Links to Branches in Calendar Activity. !9224 (Jan Christophersen)
- Fix pipeline retry and cancel buttons on pipeline details page. !9225
- Remove es6 file extension from JavaScript files. !9241 (winniehell)
- Add Runner's registration/deletion v4 API. !9246
- Add merge request count to each issue on issues list. !9252 (blackst0ne)
- Fix error in MR widget after /merge slash command. !9259
- Clean-up Project navigation order. !9272
- Add Runner's jobs v4 API. !9273
- Add pipeline trigger API with user permissions. !9277
- Enhanced filter issues layout for better mobile experience. !9280 (Pratik Borsadiya)
- Move babel config for instanbul to karma config. !9286 (winniehell)
- Document U2F limitations with multiple URLs. !9300
- Wrap long Project and Group titles. !9301
- Clean-up Groups navigation order. !9309
- Truncate long Todo titles for non-mobile screens. !9311
- add rake tasks to handle yarn dependencies and update documentation. !9316
- API: - Make subscription API more RESTful. Use `post ":project_id/:subscribable_type/:subscribable_id/subscribe"` to subscribe and `post ":project_id/:subscribable_type/:subscribable_id/unsubscribe"` to unsubscribe from a resource. !9325 (Robert Schilling)
- API: Moved `DELETE /projects/:id/star` to `POST /projects/:id/unstar`. !9328 (Robert Schilling)
- API: Use `visibility` as string parameter everywhere. !9337
- Add the Username to the HTTP(S) clone URL of a Repository. !9347 (Jan Christophersen)
- Add spec for todo with target_type Commit. !9351 (George Andrinopoulos)
- API: Remove `DELETE projects/:id/deploy_keys/:key_id/disable`. !9365 (Robert Schilling)
- Fixes includes line number during unfold copy n paste in parallel diff view. !9365
- API: Use POST to (un)block a user. !9371 (Robert Schilling)
- Remove markup that was showing in tooltip for renamed files. !9374
- Drop unused ci_projects table and some unused project_id columns, then rename gl_project_id to project_id. Stop exporting job trace when exporting projects. !9378 (David Wagner)
- Adds remote logout functionality to the Authentiq OAuth provider. !9381 (Alexandros Keramidas)
- Introduce /award slash command; Allow posting of just an emoji in comment. !9382 (mhasbini)
- API: Remove deprecated fields Notes#upvotes and Notes#downvotes. !9384 (Robert Schilling)
- Redo internals of Incoming Mail Support. !9385
- update Vue to v2.1.10. !9386
- Add button to create issue for failing build. !9391 (Alex Sanford)
- test compiling production assets and generate webpack bundle report in CI. !9396
- API: Return 204 for all delete endpoints. !9397 (Robert Schilling)
- Add KUBE_CA_PEM_FILE, deprecate KUBE_CA_PEM. !9398
- API: Use POST requests to mark todos as done. !9410 (Robert Schilling)
- API project create: Make name or path required. !9416
- Add housekeeping endpoint for Projects API. !9421
- Fixes delimiter removes when todo marked as done. !9435
- Document when current coverage configuration option was introduced. !9443
- Uploaded files which content can change now require revalidation on each page load. !9453
- Only add a newline in the Markdown Editor if the current line is not empty. !9455 (Jan Christophersen)
- Rename builds to job for the v4 API. !9463
- API: Remove /groups/owned endpoint. !9505 (Robert Schilling)
- API: Return 400 for all validation erros in the mebers API. !9523 (Robert Schilling)
- Fixes large file name tooltip cutoff in diff header. !9529
- Keep consistent in handling indexOf results. !9531 (Takuya Noguchi)
- Make documentation of list repository tree API call more detailed. !9532 (Marius Kleiner)
- Fix Sort dropdown reflow issue. !9533 (Jarkko Tuunanen)
- Improve grammar in GitLab flow documentation. !9552 (infogrind)
- Change default project view for user from readme to files view. !9584
- Make it possible to configure blocking manual actions. !9585
- Show public RSS feeds to anonymous users. !9596 (Michael Kozono)
- Update storage settings to allow extra values per repository storage. !9597
- Enable filtering milestones by search criteria in the API. !9606
- Ensure archive download is only one directory deep. !9616
- Fix updaing commit status when using optional attributes. !9618
- Add filter and sorting to dashboard groups page. !9619
- Remove deprecated build status badge and related services. !9620
- Remove the newrelic gem. !9622 (Robert Schilling)
- Rename table ci_commits to ci_pipelines. !9638
- Remove various unused CI tables and columns. !9639
- Use webpack CommonsChunkPlugin to place common javascript libraries in their own bundles. !9647
- CORS: Whitelist pagination headers. !9651 (Robert Schilling)
- Remove "subscribed" field from API responses returning list of issues or merge requests. !9661
- Highlight line number if specified on diff pages when page loads. !9664
- Set default cache key to "default" for jobs. !9666
- Set max height to screen height for Zen mode. !9667
- GET 'projects/:id/repository/commits' endpoint improvements. !9679 (George Andrinopoulos, Jordan Ryan Reuter)
- Restore keyboard shortcuts for "Activity" and "Charts". !9680
- Added commit array to Syshook json. !9685 (Gabriele Pongelli)
- Document ability to list issues with no labels using API. !9697 (Vignesh Ravichandran)
- Fix typo in GitLab config file. !9702 (medied)
- Fix json response in branches controller. !9710 (George Andrinopoulos)
- Refactor dropdown_assignee_spec. !9711 (George Andrinopoulos)
- Delete artifacts for pages unless expiry date is specified. !9716
- Use gitlab-workhorse 1.4.0. !9724
- Add GET /projects/:id/pipelines/:pipeline_id/jobs endpoint. !9727
- Restrict nested group names to prevent ambiguous routes. !9738
- Rename job environment variables to new terminology. !9756
- Deprecate usage of `types` configuration entry to describe CI/CD stages. !9766
- Moved project settings from the gear drop-down menu to a tab. !9786
- Fix "passed with warnings" stage status on MySQL installations. !9802
- Fix for creating a project through API when import_url is nil. !9841
- Use GitLab Pages v0.4.0. !9896
- Reserve few project and nested group paths that have wildcard routes associated. !9898
- Speed up project dashboard by caching pipeline status and eager loading routes. !9903
- Fixes n+1 query for tags and branches index page. !9905
- Hide ancestor groups in the share group dropdown list. !9965
- Allow creating merge request even if target branch is not specified in query params. !9968
- Removed d3 from the main application.js bundle. !10062
- Return 404 in project issues API endpoint when project cannot be found. !10093
- Fix positioning of `Scroll to top` button.
- Add limit to the number of events showed in cycle analytics.
- Only run timeago loops after rendering timeago components.
- Increase right side of file header to button stays on same line.
- Centers loading icon vertically and horizontally in pipelines table in commit view.
- Fix issues mentioned but not closed for external issue trackers.
- fix milestone does not automatically assign when create issue from milestone.
- Re-add Assign to me link to Merge Request and Issues.
- Format timeago date to short format.
- Fix errors in slash commands matcher, add simple test coverage. (YarNayar)
- Make Git history follow renames again by performing the --skip in Ruby.
- Added option to update to owner for group members.
- Pick up option from GDK to disable webpack dev server livereload.
- Introduce Pipeline Triggers that are user-aware.
- Fixed loading spinner position on issue template toggle.
- Removed duplicate "Visibility Level" label on New Project page. (Robert Marcano)
- Fix 'New Tag' layout on Tags page. (Robert Marcano)
- Update API endpoints for raw files.
- Fix issuable stale object error handler for js when updating tasklists.
- Gather issuable metadata to avoid n+1 queries on index view.
- Remove JIRA closed status icon.
- Fix z index issues with sidebar.
- Fixed long file names overflowing under action buttons.
- Only show public emails in atom feeds.
- Add Mock CI service/integration for development.
- Move tag services to Tags namespace. (dixpac)
- Set Auto-Submitted header to mails. (Semyon Pupkov)
- Improved diff comment button UX.
- Adds API endpoint to fetch all merge request for a single milestone. (Joren De Groof)
- Only create unmergeable todos once when MR fails to merge.
- Only yield valid references in ReferenceFilter.references_in.
- Add member: Always return 409 when a member exists.
- Remove plus icon from MR button on compare view.
- Re-add the New Project button in nav bar.
- Default to subtle MR mege button until CI status is available.
- Rename priority sorting option to label priority.
- Added headers to protected branch access dropdowns.
- Hide issue info when project issues are disabled. (George Andrinopoulos)
- removed unused parameter 'status_only: true'.
- Left align logo.
- Replaced jQuery UI datepicker.
- Removed jQuery UI highlight & autocomplete.
- Replaced jQuery UI sortable.
- Remove readme-only project view preference.
- Remove tooltips from label subscription buttons.
- Rename retry failed button on pipeline page to just retry.
- Align bulk update issues button to the right.
- Remove remnants of git annex support.
- Dispatch needed JS when creating a new MR in diff view.
- Change project count limit from 10 to 100000.
- Remove repeated routes.path check for postgresql database. (mhasbini)
- Fixed RSS button alignment on activity pages.
- Seed abuse reports for development.
- Bump Hashie to 3.5.5 and omniauth to 1.4.2 to eliminate warning noise.
- Add user deletion permission check in `Users::DestroyService`.
- Fix snippets search result spacing.
- Sort builds in stage dropdown.
- SSH key field updates title after pasting key.
- To protect against Server-side Request Forgery project import URLs are now prohibited against localhost or the server IP except for the assigned instance URL and port. Imports are also prohibited from ports below 1024 with the exception of ports 22, 80, and 443.
- Remove fixed positioning from top nav.
- Deduplicate markdown task lists.
- update issue count when closing/reopening an issue.
- Update code editor (ACE) to 1.2.6, to fix input problems with compose key.
- Improves a11y in sidebar by adding aria-hidden attributes in i tags and by fixing two broken aria-hidden attributes.
- Use redis channel to post notifications.
- Removed top border from user contribution calendar.
- Added user callouts to the projects dashboard and user profile.
- Removes label when moving issue to another list that it is currently in.
- Return 202 with JSON body on async removals on V4 API.
- Add filtered search to MR page.
- Add frequently used emojis back to awards menu.
- don't animate logo when downloading files.
- Stop setting Strict-Transport-Securty header from within the app.
- Use "branch_name" instead "branch" on V3 branch creation API.
- Fix archive prefix bug for refs containing dots.
- ensure MR widget dropdown is same color as button.
- Adds Pending and Finished tabs to pipelines page.
- Decrease tanuki logo size.
- Add all available statuses to scope filter for project builds endpoint. (George Andrinopoulos)
- Add filter param for project membership for current_user in API v4.
- Remove help link from right dropdown.
- Fix jobs table header height.
- Combined deploy keys, push rules, protect branches and mirror repository settings options into a single one called Repository.
- Add storage class configuration option for Amazon S3 remote backups. (Jon Keys)
- Specify in the documentation that only projects owners can transfer projects.
- Use native unicode emojis.
- Clear ActiveRecord connections before starting Sidekiq.
- Update account view to display new username.
- Narrow environment payload by using basic project details resource.
- Creating a new branch from an issue will automatically initialize a repository if one doesn't already exist.
- Dashboard project search keeps selected sort & filters.
- Visually show expanded diff lines cant have comments.
- Use full group name in GFM group reference title.
- Make a default namespace of Kubernetes service to contain project ID.
- Present GitLab version for each V3 to V4 API change on v3_to_v4.md.
- Add badges to global dropdown.
- Changed coverage reg expression placeholder text to be more like a placeholder.
- Show members of parent groups on project members page.
- Fix grammar issue in admin/runners.
- Allow slashes in slash command arguments.
- Adds paginationd and folders view to environments table.
- hide loading spinners for server-rendered sidebar fields.
- Change development tanuki favicon colors to match logo color order.
- API issues - support filtering by iids.

## 8.17.8 (2017-08-09)

- Remove hidden symlinks from project import files.
- Disallow Git URLs that include a username or hostname beginning with a non-alphanumeric character.

## 8.17.7 (2017-07-19)

- Renders 404 if given project is not readable by the user on Todos dashboard.
- Fix incorrect project authorizations.

## 8.17.6 (2017-05-05)

- Enforce project features when searching blobs and wikis.
- Fixed branches dropdown rendering branch names as HTML.
- Make Asciidoc & other markup go through pipeline to prevent XSS.
- Validate URLs in markdown using URI to detect the host correctly.
- Fix for XSS in project import view caused by Hamlit filter usage.
- Sanitize submodule URLs before linking to them in the file tree view.
- Refactor snippets finder & dont return internal snippets for external users.
- Fix snippets visibility for show action - external users can not see internal snippets.

## 8.17.5 (2017-04-05)

- Don’t show source project name when user does not have access.
- Remove the class attribute from the whitelist for HTML generated from Markdown.
- Fix path disclosure in project import/export.
- Fix for open redirect vulnerability using continue[to] in URL when requesting project import status.
- Fix for open redirect vulnerabilities in todos, issues, and MR controllers.

## 8.17.4 (2017-03-19)

- Only show public emails in atom feeds.
- To protect against Server-side Request Forgery project import URLs are now prohibited against localhost or the server IP except for the assigned instance URL and port. Imports are also prohibited from ports below 1024 with the exception of ports 22, 80, and 443.

## 8.17.3 (2017-03-07)

- Fix the redirect to custom home page URL. !9518
- Fix broken migration when upgrading straight to 8.17.1. !9613
- Make projects dropdown only show projects you are a member of. !9614
- Fix creating a file in an empty repo using the API. !9632
- Don't copy tooltip when copying GFM.
- Fix cherry-picking or reverting through an MR.

## 8.17.2 (2017-03-01)

- Expire all webpack assets after 8.17.1 included a badly compiled asset. !9602

## 8.17.1 (2017-02-28)

- Replace setInterval with setTimeout to prevent highly frequent requests. !9271 (Takuya Noguchi)
- Disable unused tags count cache for Projects, Builds and Runners.
- Spam check and reCAPTCHA improvements.
- Allow searching issues for strings containing colons.
- Disabled tooltip on add issues button in usse boards.
- Fixed commit search UI.
- Fix MR changes tab size count when there are over 100 files in the diff.
- Disable invalid service templates.
- Use default branch as target_branch when parameter is missing.
- Upgrade GitLab Pages to v0.3.2.
- Add performance query regression fix for !9088 affecting #27267.
- Chat slash commands show labels correctly.

## 8.17.0 (2017-02-22)

- API: Fix file downloading. !0 (8267)
- Changed composer installer script in the CI PHP example doc. !4342 (Jeffrey Cafferata)
- Display fullscreen button on small screens. !5302 (winniehell)
- Add system hook for when a project is updated (other than rename/transfer). !5711 (Tommy Beadle)
- Fix notifications when set at group level. !6813 (Alexandre Maia)
- Project labels can now be promoted to group labels. !7242 (Olaf Tomalka)
- use webpack to bundle frontend assets and use karma for frontend testing. !7288
- Adds back ability to stop all environments. !7379
- Added labels empty state. !7443
- Add ability to define a coverage regex in the .gitlab-ci.yml. !7447 (Leandro Camargo)
- Disable automatic login after clicking email confirmation links. !7472
- Search feature: redirects to commit page if query is commit sha and only commit found. !8028 (YarNayar)
- Create a TODO for user who set auto-merge when a build fails, merge conflict occurs. !8056 (twonegatives)
- Don't group issues by project on group-level and dashboard issue indexes. !8111 (Bernardo Castro)
- Mark MR as WIP when pushing WIP commits. !8124 (Jurre Stender @jurre)
- Flag multiple empty lines in eslint, fix offenses. !8137
- Add sorting pipeline for a commit. !8319 (Takuya Noguchi)
- Adds service trigger events to api. !8324
- Update pipeline and commit links when CI status is updated. !8351
- Hide version check image if there is no internet connection. !8355 (Ken Ding)
- Prevent removal of input fields if it is the parent dropdown element. !8397
- Introduce maximum session time for terminal websocket connection. !8413
- Allow creating protected branches when user can merge to such branch. !8458
- Refactor MergeRequests::BuildService. !8462 (Rydkin Maxim)
- Added GitLab Pages to CE. !8463
- Support notes when a project is not specified (personal snippet notes). !8468
- Use warning icon in mini-graph if stage passed conditionally. !8503
- Don’t count tasks that are not defined as list items correctly. !8526
- Reformat messages ChatOps. !8528
- Copy commit SHA to clipboard. !8547
- Improve button accessibility on pipelines page. !8561
- Display project ID in project settings. !8572 (winniehell)
- PlantUML support for Markdown. !8588 (Horacio Sanson)
- Fix reply by email without sub-addressing for some clients from Microsoft and Apple. !8620
- Fix nested tasks in ordered list. !8626
- Fix Sort by Recent Sign-in in Admin Area. !8637 (Poornima M)
- Avoid repeated dashes in $CI_ENVIRONMENT_SLUG. !8638
- Only show Merge Request button when user can create a MR. !8639
- Prevent copying of line numbers in parallel diff view. !8706
- Improve build policy and access abilities. !8711
- API: Remove /projects/:id/keys/.. endpoints. !8716 (Robert Schilling)
- API: Remove deprecated 'expires_at' from project snippets. !8723 (Robert Schilling)
- Add `copy` backup strategy to combat file changed errors. !8728
- adds avatar for discussion note. !8734
- Add link verification to badge partial in order to render a badge without a link. !8740
- Reduce hits to LDAP on Git HTTP auth by reordering auth mechanisms. !8752
- prevent diff unfolding link from appearing when there are no more lines to show. !8761
- Redesign searchbar in admin project list. !8776
- Rename Builds to Pipelines, CI/CD Pipelines, or Jobs everywhere. !8787
- dismiss sidebar on repo buttons click. !8798 (Adam Pahlevi)
- fixed small mini pipeline graph line glitch. !8804
- Make all system notes lowercase. !8807
- Support unauthenticated LFS object downloads for public projects. !8824 (Ben Boeckel)
- Add read-only full_path and full_name attributes to Group API. !8827
- allow relative url change without recompiling frontend assets. !8831
- Use vue.js Pipelines table in commit and merge request view. !8844
- Use reCaptcha when an issue is identified as a spam. !8846
- resolve deprecation warnings. !8855 (Adam Pahlevi)
- Cop for gem fetched from a git source. !8856 (Adam Pahlevi)
- Remove flash warning from login page. !8864 (Gerald J. Padilla)
- Adds documentation for how to use Vue.js. !8866
- Add 'View on [env]' link to blobs and individual files in diffs. !8867
- Replace word user with member. !8872
- Change the reply shortcut to focus the field even without a selection. !8873 (Brian Hall)
- Unify MR diff file button style. !8874
- Unify projects search by removing /projects/:search endpoint. !8877
- Fix disable storing of sensitive information when importing a new repo. !8885 (Bernard Pietraga)
- Fix pipeline graph vertical spacing in Firefox and Safari. !8886
- Fix filtered search user autocomplete for gitlab instances that are hosted on a subdirectory. !8891
- Fix Ctrl+Click support for Todos and Merge Request page tabs. !8898
- Fix wrong call to ProjectCacheWorker.perform. !8910
- Don't perform Devise trackable updates on blocked User records. !8915
- Add ability to export project inherited group members to Import/Export. !8923
- replace `find_with_namespace` with `find_by_full_path`. !8949 (Adam Pahlevi)
- Fixes flickering of avatar border in mention dropdown. !8950
- Remove unnecessary queries for .atom and .json in Dashboard::ProjectsController#index. !8956
- Fix deleting projects with pipelines and builds. !8960
- Fix broken anchor links when special characters are used. !8961 (Andrey Krivko)
- Ensure autogenerated title does not cause failing spec. !8963 (brian m. carlson)
- Update doc for enabling or disabling GitLab CI. !8965 (Takuya Noguchi)
- Remove deprecated MR and Issue endpoints and preserve V3 namespace. !8967
- Fixed "substract" typo on /help/user/project/slash_commands. !8976 (Jason Aquino)
- Preserve backward compatibility CI/CD and disallow setting `coverage` regexp in global context. !8981
- use babel to transpile all non-vendor javascript assets regardless of file extension. !8988
- Fix MR widget url. !8989
- Fixes hover cursor on pipeline pagenation. !9003
- Layer award emoji dropdown over the right sidebar. !9004
- Do not display deploy keys in user's own ssh keys list. !9024
- upgrade babel 5.8.x to babel 6.22.x. !9072
- upgrade to webpack v2.2. !9078
- Trigger autocomplete after selecting a slash command. !9117
- Add space between text and loading icon in Megre Request Widget. !9119
- Fix job to pipeline renaming. !9147
- Replace static fixture for merge_request_tabs_spec.js. !9172 (winniehell)
- Replace static fixture for right_sidebar_spec.js. !9211 (winniehell)
- Show merge errors in merge request widget. !9229
- Increase process_commit queue weight from 2 to 3. !9326 (blackst0ne)
- Don't require lib/gitlab/request_profiler/middleware.rb in config/initializers/request_profiler.rb.
- Force new password after password reset via API. (George Andrinopoulos)
- Allows to search within project by commit hash. (YarNayar)
- Show organisation membership and delete comment on smaller viewports, plus change comment author name to username.
- Remove turbolinks.
- Convert pipeline action icons to svg to have them properly positioned.
- Remove rogue scrollbars for issue comments with inline elements.
- Align Segoe UI label text.
- Color + and - signs in diffs to increase code legibility.
- Fix tab index order on branch commits list page. (Ryan Harris)
- Add hover style to copy icon on commit page header. (Ryan Harris)
- Remove hover animation from row elements.
- Improve pipeline status icon linking in widgets.
- Fix commit title bar and repository view copy clipboard button order on last commit in repository view.
- Fix mini-pipeline stage tooltip text wrapping.
- Updated builds info link on the project settings page. (Ryan Harris)
- 27240 Make progress bars consistent.
- Only render hr when user can't archive project.
- 27352-search-label-filter-header.
- Include :author, :project, and :target in Event.with_associations.
- Don't instantiate AR objects in Event.in_projects.
- Don't capitalize environment name in show page.
- Update and pin the `jwt` gem to ~> 1.5.6.
- Edited the column header for the environments list from created to updated and added created to environments detail page colum header titles.
- Give ci status text on pipeline graph a better font-weight.
- Add default labels to bulk assign dropdowns.
- Only return target project's comments for a commit.
- Fixes Pipelines table is not showing branch name for commit.
- Fix regression where cmd-click stopped working for todos and merge request tabs.
- Fix stray pipelines API request when showing MR.
- Fix Merge request pipelines displays JSON.
- Fix current build arrow indicator.
- Fix contribution activity alignment.
- Show Pipeline(not Job) in MR desktop notification.
- Fix tooltips in mini pipeline graph.
- Display loading indicator when filtering ref switcher dropdown.
- Show pipeline graph in MR widget if there are any stages.
- Fix icon colors in merge request widget mini graph.
- Improve blockquote formatting in notification emails.
- Adds container to tooltip in order to make it work with overflow:hidden in parent element.
- Restore pagination to admin abuse reports.
- Ensure export files are removed after a namespace is deleted.
- Add `y` keyboard shortcut to move to file permalink.
- Adds /target_branch slash command functionality for merge requests. (YarNayar)
- Patch Asciidocs rendering to block XSS.
- contribution calendar scrolls from right to left.
- Copying a rendered issue/comment will paste into GFM textareas as actual GFM.
- Don't delete assigned MRs/issues when user is deleted.
- Remove new branch button for confidential issues.
- Don't allow project guests to subscribe to merge requests through the API. (Robert Schilling)
- Don't connect in Gitlab::Database.main.adapter_name.
- Prevent users from creating notes on resources they can't access.
- Ignore encrypted attributes in Import/Export.
- Change rspec test to guarantee window is resized before visiting page.
- Prevent users from deleting system deploy keys via the project deploy key API.
- Fix XSS vulnerability in SVG attachments.
- Make MR-review-discussions more reliable.
- fix incorrect sidekiq concurrency count in admin background page. (wendy0402)
- Make notification_service spec DRYer by making test reusable. (YarNayar)
- Redirect http://someproject.git to http://someproject. (blackst0ne)
- Fixed group label links in issue/merge request sidebar.
- Improve gl.utils.handleLocationHash tests.
- Fixed Issuable sidebar not closing on smaller/mobile sized screens.
- Resets assignee dropdown when sidebar is open.
- Disallow system notes for closed issuables.
- Fix timezone on issue boards due date.
- Remove unused js response from refs controller.
- Prevent the GitHub importer from assigning labels and comments to merge requests or issues belonging to other projects.
- Fixed merge requests tab extra margin when fixed to window.
- Patch XSS vulnerability in RDOC support.
- Refresh authorizations when transferring projects.
- Remove issue and MR counts from labels index.
- Don't use backup Active Record connections for Sidekiq.
- Add index to ci_trigger_requests for commit_id.
- Add indices to improve loading of labels page.
- Reduced query count for snippet search.
- Update GitLab Pages to v0.3.1.
- Upgrade omniauth gem to 1.3.2.
- Remove deprecated GitlabCiService.
- Requeue pending deletion projects.

## 8.16.9 (2017-04-05)

- Don’t show source project name when user does not have access.
- Remove the class attribute from the whitelist for HTML generated from Markdown.
- Fix path disclosure in project import/export.
- Fix for open redirect vulnerability using continue[to] in URL when requesting project import status.
- Fix for open redirect vulnerabilities in todos, issues, and MR controllers.

## 8.16.8 (2017-03-19)

- Only show public emails in atom feeds.
- To protect against Server-side Request Forgery project import URLs are now prohibited against localhost or the server IP except for the assigned instance URL and port. Imports are also prohibited from ports below 1024 with the exception of ports 22, 80, and 443.

## 8.16.7 (2017-02-27)

- Fix MR changes tab size count when there are over 100 files in the diff.

## 8.16.6 (2017-02-17)

- API: Fix file downloading. !0 (8267)
- Reduce hits to LDAP on Git HTTP auth by reordering auth mechanisms. !8752
- Fix filtered search user autocomplete for gitlab instances that are hosted on a subdirectory. !8891
- Fix wrong call to ProjectCacheWorker.perform. !8910
- Remove unnecessary queries for .atom and .json in Dashboard::ProjectsController#index. !8956
- Fix broken anchor links when special characters are used. !8961 (Andrey Krivko)
- Do not display deploy keys in user's own ssh keys list. !9024
- Show merge errors in merge request widget. !9229
- Don't delete assigned MRs/issues when user is deleted.
- backport of EE fix !954.
- Refresh authorizations when transferring projects.
- Don't use backup Active Record connections for Sidekiq.
- Check public snippets for spam.

## 8.16.5 (2017-02-14)

- Patch Asciidocs rendering to block XSS.
- Fix XSS vulnerability in SVG attachments.
- Prevent the GitHub importer from assigning labels and comments to merge requests or issues belonging to other projects.
- Patch XSS vulnerability in RDOC support.

## 8.16.4 (2017-02-02)

- Support non-ASCII characters in GFM autocomplete. !8729
- Fix search bar search param encoding. !8753
- Fix project name label's for reference in project settings. !8795
- Fix filtering with multiple words. !8830
- Fixed services form cancel not redirecting back the integrations settings view. !8843
- Fix filtering usernames with multiple words. !8851
- Improve performance of slash commands. !8876
- Remove old project members when retrying an export.
- Fix permalink discussion note being collapsed.
- Add project ID index to `project_authorizations` table to optimize queries.
- Check public snippets for spam.
- 19164 Add settings dropdown to mobile screens.

## 8.16.3 (2017-01-27)

- Add caching of droplab ajax requests. !8725
- Fix access to the wiki code via HTTP when repository feature disabled. !8758
- Revert 3f17f29a. !8785
- Fix race conditions for AuthorizedProjectsWorker.
- Fix autocomplete initial undefined state.
- Fix Error 500 when repositories contain annotated tags pointing to blobs.
- Fix /explore sorting.
- Fixed label dropdown toggle text not correctly updating.

## 8.16.2 (2017-01-25)

- allow issue filter bar to be operated with mouse only. !8681
- Fix CI requests concurrency for newer runners that prevents from picking pending builds (from 1.9.0-rc5). !8760
- Add some basic fixes for IE11/Edge.
- Remove blue border from comment box hover.
- Fixed bug where links in merge dropdown wouldn't work.

## 8.16.1 (2017-01-23)

- Ensure export files are removed after a namespace is deleted.
- Don't allow project guests to subscribe to merge requests through the API. (Robert Schilling)
- Prevent users from creating notes on resources they can't access.
- Prevent users from deleting system deploy keys via the project deploy key API.
- Upgrade omniauth gem to 1.3.2.

## 8.16.0 (2017-01-22)

- Add LDAP Rake task to rename a provider. !2181
- Validate label's title length. !5767 (Tomáš Kukrál)
- Allow to add deploy keys with write-access. !5807 (Ali Ibrahim)
- Allow to use + symbol in filenames. !6644 (blackst0ne)
- Search bar redesign first iteration. !7345
- Fix date inconsistency on due date picker. !7422 (Giuliano Varriale)
- Add email confirmation field to registration form. !7432
- Updated project visibility settings UX. !7645
- Go to a project order. !7737 (Jacopo Beschi @jacopo-beschi)
- Support slash comand `/merge` for merging merge requests. !7746 (Jarka Kadlecova)
- Add more storage statistics. !7754 (Markus Koller)
- Add support for PlantUML diagrams in AsciiDoc documents. !7810 (Horacio Sanson)
- Remove extra orphaned rows when removing stray namespaces. !7841
- Added lighter count badge background-color for on white backgrounds. !7873
- Fixes issue boards list colored top border visual glitch. !7898 (Pier Paolo Ramon)
- change 'gray' color theme name to 'black' to match the actual color. !7908 (BM5k)
- Remove trailing whitespace when generating changelog entry. !7948
- Remove checking branches state in issue new branch button. !8023
- Log LDAP blocking/unblocking events to application log. !8042 (Markus Koller)
- ensure permalinks scroll to correct position on multiple clicks. !8046
- Allow to use ENV variables in redis config. !8073 (Semyon Pupkov)
- fix button layout issue on branches page. !8074
- Reduce DB-load for build-queues by storing last_update in Redis. !8084
- Record and show last used date of SSH Keys. !8113 (Vincent Wong)
- Resolves overflow in compare branch and tags dropdown. !8118
- Replace wording for slash command confirmation message. !8123
- remove build_user. !8162 (Arsenev Vladislav)
- Prevent empty pagination when list is not empty. !8172
- Make successful pipeline emails off for watchers. !8176
- Improve copy in Issue Tracker empty state. !8202
- Adds CSS class to status icon on MR widget to prevent non-colored icon. !8219
- Improve visibility of "Resolve conflicts" and "Merge locally" actions. !8229
- Add Gitaly to the architecture documentation. !8264 (Pablo Carranza <pablo@gitlab.com>)
- Sort numbers in build names more intelligently. !8277
- Show nested groups tab on group page. !8308
- Rename users with namespace ending with .git. !8309
- Rename filename to file path in tooltip of file header in merge request diff. !8314
- About GitLab link in sidebar that links to help page. !8316
- Merged the 'Groups' and 'Projects' tabs when viewing user profiles. !8323 (James Gregory)
- re-enable change username button after failure. !8332
- Darkened hr border color in descriptions because of update of bootstrap. !8333
- display merge request discussion tab for empty branches. !8347
- Fix double spaced CI log. !8349 (Jared Deckard <jared.deckard@gmail.com>)
- Refactored note edit form to improve frontend performance on MR and Issues pages, especially pages with has a lot of discussions in it. !8356
- Make CTRL+Enter submits a new merge request. !8360 (Saad Shahd)
- Fixes too short input for placeholder message in commit listing page. !8367
- Fix typo: seach to search. !8370
- Adds label to Environments "Date Created". !8376 (Saad Shahd)
- Convert project setting text into protected branch path link. !8377 (Ken Ding)
- Precompile all JavaScript fixtures. !8384
- Use original casing for build action text. !8387
- Scroll to bottom on build completion if autoscroll was active. !8391
- Properly handle failed reCAPTCHA on user registration. !8403
- Changed alerts to be responsive, centered text on smaller viewports. !8424 (Connor Smallman)
- Pass Gitaly resource path to gitlab-workhorse if Gitaly is enabled. !8440
- Fixes and Improves CSS and HTML problems in mini pipeline graph and builds dropdown. !8443
- Don't instrument 405 Grape calls. !8445
- Change CI template linter textarea with Ace Editor. !8452 (Didem Acet)
- Removes unneeded `window` declaration in environments related code. !8456
- API: fix query response for `/projects/:id/issues?milestone="No%20Milestone"`. !8457 (Panagiotis Atmatzidis, David Eisner)
- Fix broken url on group avatar. !8464 (hogewest)
- Fixes buttons not being accessible via the keyboard when creating new group. !8469
- Restore backup correctly when "BACKUP" environment variable is passed. !8477
- Add new endpoints for Time Tracking. !8483
- Fix Compare page throws 500 error when any branch/reference is not selected. !8492 (Martin Cabrera)
- Treat environments matching `production/*` as Production. !8500
- Hide build artifacts keep button if operation is not allowed. !8501
- Update the gitlab-markup gem to the version 1.5.1. !8509
- Remove Lock Icon on Protected Tag. !8513 (Sergey Nikitin)
- Use cached values to compute total issues count in milestone index pages. !8518
- Speed up dashboard milestone index by scoping IssuesFinder to user authorized projects. !8524
- Copy <some text> to clipboard. !8535
- Check for env[Grape::Env::GRAPE_ROUTING_ARGS] instead of endpoint.route. !8544
- Fixes builds dropdown making request when clicked to be closed. !8545
- Fixes pipeline status cell is too wide by adding missing classes in table head cells. !8549
- Mutate the attribute instead of issuing a write operation to the DB in `ProjectFeaturesCompatibility` concern. !8552
- Fix links to commits pages on pipelines list page. !8558
- Ensure updating project settings shows a flash message on success. !8579 (Sandish Chen)
- Fixes big pipeline and small pipeline width problems and tooltips text being outside the tooltip. !8593
- Autoresize markdown preview. !8607 (Didem Acet)
- Link external build badge to its target URL. !8611
- Adjust ProjectStatistic#repository_size with values saved as MB. !8616
- Correct User-agent placement in robots.txt. !8623 (Eric Sabelhaus)
- Record used SSH keys only once per day. !8655
- Do not generate pipeline branch/tag path if not present. !8658
- Fix Merge When Pipeline Succeeds immediate merge bug. !8685
- Fix blame 500 error on invalid path. !25761 (Jeff Stubler)
- Added animations to issue boards interactions.
- Check if user can read project before being assigned to issue.
- Show 'too many changes' message for created merge requests when they are too large.
- Fix redirect after update file when user has forked project.
- Parse JIRA issue references even if Issue Tracker is disabled.
- Made download artifacts button accessible via keyboard by changing it from an anchor tag to an actual button. (Ryan Harris)
- Make play button on Pipelines page accessible via keyboard. (Ryan Harris)
- Decreases font-size on login page.
- Fixed merge request tabs dont move when opening collapsed sidebar.
- Display project avatars on Admin Area and Projects pages for mobile views. (Ryan Harris)
- Fix participants margins to fit on one line.
- 26352 Change Profile settings to User / Settings.
- Fix Commits API to accept a Project path upon POST.
- Expire related caches after changing HEAD. (Minqi Pan)
- Add various hover animations throughout the application.
- Re-order update steps in the 8.14 -> 8.15 upgrade guide.
- Move award emoji's out of the discussion tab for merge requests.
- Synchronize all project authorization refreshing work to prevent race conditions.
- Remove the project_authorizations.id column.
- Combined the settings options project members and groups into a single one called members.
- Change earlier to task_status_short to avoid titlebar line wraps.
- 25701 standardize text colors.
- Handle HTTP errors in environment list.
- Re-add Google Cloud Storage as a backup strategy.
- Change status colors of runners to better defaults.
- Added number_with_delimiter to counter on milestone panels. (Ryan Harris)
- Query external CI statuses in the background.
- Allow group and project paths when transferring projects via the API.
- Don't validate environment urls on .gitlab-ci.yml.
- Fix a Grape deprecation, use `#request_method` instead of `#route_method`.
- Fill missing authorized projects rows.
- Allow API query to find projects with dots in their name. (Bruno Melli)
- Fix import/export wrong user mapping.
- Removed bottom padding from merge manually from CLI because of repositioning award emoji's.
- Fix project queued for deletion re-creation tooltip.
- Fix search group/project filtering to show results.
- Fix 500 error when POSTing to Users API with optional confirm param.
- 26504 Fix styling of MR jump to discussion button.
- Add margin to markdown math blocks.
- Add hover state to MR comment reply button.


## 8.15.8 (2017-03-19)

- Only show public emails in atom feeds.
- To protect against Server-side Request Forgery project import URLs are now prohibited against localhost or the server IP except for the assigned instance URL and port. Imports are also prohibited from ports below 1024 with the exception of ports 22, 80, and 443.

## 8.15.7 (2017-02-15)

- No changes.

## 8.15.6 (2017-02-14)

- Patch Asciidocs rendering to block XSS.
- Fix XSS vulnerability in SVG attachments.
- Prevent the GitHub importer from assigning labels and comments to merge requests or issues belonging to other projects.
- Patch XSS vulnerability in RDOC support.

## 8.15.5 (2017-01-20)

- Ensure export files are removed after a namespace is deleted.
- Don't allow project guests to subscribe to merge requests through the API. (Robert Schilling)
- Prevent users from creating notes on resources they can't access.
- Prevent users from deleting system deploy keys via the project deploy key API.
- Upgrade omniauth gem to 1.3.2.

## 8.15.4 (2017-01-09)

- Make successful pipeline emails off for watchers. !8176
- Speed up group milestone index by passing group_id to IssuesFinder. !8363
- Don't instrument 405 Grape calls. !8445
- Update the gitlab-markup gem to the version 1.5.1. !8509
- Updated Turbolinks to mitigate potential XSS attacks.
- Re-order update steps in the 8.14 -> 8.15 upgrade guide.
- Re-add Google Cloud Storage as a backup strategy.

## 8.15.3 (2017-01-06)

- Rename wiki_events to wiki_page_events in project hooks API to avoid errors. !8425
- Rename projects wth reserved names. !8234
- Cache project authorizations even when user has access to zero projects. !8327
- Fix a minor grammar error in merge request widget. !8337
- Fix unclear closing issue behaviour on Merge Request show page. !8345 (Gabriel Gizotti)
- fix border in login session tabs. !8346
- Copy, don't move uploaded avatar files. !8396
- Increases width of mini-pipeline-graph dropdown to prevent wrong position on chrome on ubuntu. !8399
- Removes invalid html and unneed CSS to prevent shaking in the pipelines tab. !8411
- Gitlab::LDAP::Person uses LDAP attributes configuration. !8418
- Fix 500 errors when creating a user with identity via API. !8442
- Whitelist next project names: assets, profile, public. !8470
- Fixed regression of note-headline-light where it was always placed on 2 lines, even on wide viewports.
- Fix 500 error when visit group from admin area if group name contains dot.
- Fix cross-project references copy to include the project reference.
- Fix 500 error renaming group.
- Fixed GFM dropdown not showing on new lines.

## 8.15.2 (2016-12-27)

- Fix finding the latest pipeline. !8301
- Fix mr list timestamp alignment. !8271
- Fix discussion overlap text in regular screens. !8273
- Fixes mini-pipeline-graph dropdown animation and stage position in chrome, firefox and safari. !8282
- Fix line breaking in nodes of the pipeline graph in firefox. !8292
- Fixes confendential warning text alignment. !8293
- Hide Scroll Top button for failed build page. !8295
- Fix finding the latest pipeline. !8301
- Disable PostgreSQL statement timeouts when removing unneeded services. !8322
- Fix timeout when MR contains large files marked as binary by .gitattributes.
- Rename "autodeploy" to "auto deploy".
- Fixed GFM autocomplete error when no data exists.
- Fixed resolve discussion note button color.

## 8.15.1 (2016-12-23)

- Push payloads schedule at most 100 commits, instead of all commits.
- Fix Mattermost command creation by specifying username.
- Do not override incoming webhook for mattermost and slack.
- Adds background color for disabled state to merge when succeeds dropdown. !8222
- Standardises font-size for titles in Issues, Merge Requests and Merge Request widget. !8235
- Fix Pipeline builds list blank on MR. !8255
- Do not show retried builds in pipeline stage dropdown. !8260

## 8.15.0 (2016-12-22)

- Whitelist next project names: notes, services.
- Use Grape's new Route methods.
- Fixed issue boards scrolling with a lot of lists & issues.
- Remove unnecessary sentences for status codes in the API documentation. (Luis Alonso Chavez Armendariz)
- Allow unauthenticated access to Repositories Files API GET endpoints.
- Add note to the invite page when the logged in user email is not the same as the invitation.
- Don't accidentally mark unsafe diff lines as HTML safe.
- Add git diff context to notifications of new notes on merge requests. (Heidi Hoopes)
- Shows group members in project members list.
- Gem update: Update grape to 0.18.0. (Robert Schilling)
- API: Expose merge status for branch API. (Robert Schilling)
- Displays milestone remaining days only when it's present.
- API: Expose committer details for commits. (Robert Schilling)
- API: Ability to set 'should_remove_source_branch' on merge requests. (Robert Schilling)
- Fix project import label priorities error.
- Fix Import/Export merge requests error while importing.
- Refactor Bitbucket importer to use BitBucket API Version 2.
- Fix Import/Export duplicated builds error.
- Ci::Builds have same ref as Ci::Pipeline in dev fixtures. (twonegatives)
- For single line git commit messages, the close quote should be on the same line as the open quote.
- Use authorized projects in ProjectTeam.
- Destroy a user's session when they delete their own account.
- Edit help text to clarify annotated tag creation. (Liz Lam)
- Fixed file template dropdown for the "New File" editor for smaller/zoomed screens.
- Fix Route#rename_children behavior.
- Add nested groups support on data level.
- Allow projects with 'dashboard' as path.
- Disabled emoji buttons when user is not logged in.
- Remove unused and void services from the database.
- Add issue search slash command.
- Accept issue new as command to create an issue.
- Non members cannot create labels through the API.
- API: expose pipeline coverage.
- Validate state param when filtering issuables.
- Username exists check respects relative root path.
- Bump Git version requirement to 2.8.4.
- Updates the font weight of button styles because of the change to system fonts.
- Update API spec files to describe the correct class. (Livier)
- Fixed timeago re-rendering every timeago.
- Enable ColorVariable in scss-lint. (Sam Rose)
- Various small emoji positioning adjustments.
- Add shortcuts for adding users to a project team with a specific role. (Nikolay Ponomarev and Dino M)
- Additional rounded label fixes.
- Remove unnecessary database indices.
- 24726 Remove Across GitLab from side navigation.
- Changed cursor icon to pointer when mousing over stages on the Cycle Analytics pages. (Ryan Harris)
- Add focus state to dropdown items.
- Fixes Environments displaying incorrect date since 8.14 upgrade.
- Improve bulk assignment for issuables.
- Stop supporting Google and Azure as backup strategies.
- Fix broken README.md UX guide link.
- Allow public access to some Tag API endpoints.
- Encode input when migrating ProcessCommitWorker jobs to prevent migration errors.
- Adjust the width of project avatars to fix alignment within their container. (Ryan Harris)
- Sentence cased the nav tab headers on the project dashboard page. (Ryan Harris)
- Adds hoverstates for collapsed Issue/Merge Request sidebar.
- Make CI badge hitboxes match parent.
- Add a starting date to milestones.
- Adjusted margins for Build Status and Coverage Report rows to match those of the CI/CD Pipeline row. (Ryan Harris)
- Updated members dropdowns.
- Move all action buttons to project header.
- Replace issue access checks with use of IssuableFinder.
- Fix missing Note access checks by moving Note#search to updated NoteFinder.
- Centered Accept Merge Request button within MR widget and added padding for viewports smaller than 768px. (Ryan Harris)
- Fix missing access checks on issue lookup using IssuableFinder.
- Added top margin to Build status page header for mobile views. (Ryan Harris)
- Fixes "ActionView::Template::Error: undefined method `text?` for nil:NilClass" on MR pages.
- Issue#visible_to_user moved to IssuesFinder to prevent accidental use.
- Replace MR access checks with use of MergeRequestsFinder.
- Fix information disclosure in `Projects::BlobController#update`.
- Allow branch names with dots on API endpoint.
- Changed Housekeeping button on project settings page to default styling. (Ryan Harris)
- Ensure issuable state changes only fire webhooks once.
- Fix bad selection on dropdown menu for tags filter. (Luis Alonso Chavez Armendariz)
- Fix title case to sentence case. (Luis Alonso Chavez Armendariz)
- Fix appearance in error pages. (Luis Alonso Chavez Armendariz)
- Create mattermost service.
- 25617 Fix placeholder color of todo filters.
- Made the padding on the plus button in the breadcrumb menu even. (Ryan Harris)
- Allow to delete tag release note.
- Ensure nil User-Agent doesn't break the CI API.
- Replace Rack::Multipart with GitLab-Workhorse based solution. !5867
- Add scopes for personal access tokens and OAuth tokens. !5951
- API: Endpoint to expose personal snippets as /snippets. !6373 (Bernard Guyzmo Pratz)
- New `gitlab:workhorse:install` rake task. !6574
- Filter protocol-relative URLs in ExternalLinkFilter. Fixes issue #22742. !6635 (Makoto Scott-Hinkle)
- Add support for setting the GitLab Runners Registration Token during initial database seeding. !6642
- Guests can read builds when public. !6842
- Made comment autocomplete more performant and removed some loading bugs. !6856
- Add GitLab host to 2FA QR code and manual info. !6941
- Add sorting functionality for group/project members. !7032
- Rename Merge When Build Succeeds to Merge When Pipeline Succeeds. !7135
- Resolve all discussions in a merge request by creating an issue collecting them. !7180 (Bob Van Landuyt)
- Add Human Readable format for rake backup. !7188 (David Gerő)
- post_receive: accept any user email from last commit. !7225 (Elan Ruusamäe)
- Add support for Dockerfile templates. !7247
- Add shorthand support to gitlab markdown references. !7255 (Oswaldo Ferreira)
- Display error code for U2F errors. !7305 (winniehell)
- Fix wrong tab selected when loggin fails and multiple login tabs exists. !7314 (Jacopo Beschi @jacopo-beschi)
- Clean up common_utils.js. !7318 (winniehell)
- Show commit status from latest pipeline. !7333
- Remove the help text under the sidebar subscribe button and style it inline. !7389
- Update wiki page design. !7429
- Add nested groups support to the routing. !7459
- Changed eslint airbnb config to the base airbnb config and corrected eslintrc plugins and envs. !7470 (Luke "Jared" Bennett)
- Fix cancelling created or external pipelines. !7508
- Allow admins to stop impersonating users without e-mail addresses. !7550 (Oren Kanner)
- Remove unnecessary self from user model. !7551 (Semyon Pupkov)
- Homogenize filter and sort dropdown look'n'feel. !7583 (David Wagner)
- Create dynamic fixture for build_spec. !7589 (winniehell)
- Moved Leave Project and Leave Group buttons to access_request_buttons from the settings dropdown. !7600
- Remove unnecessary require_relative calls from service classes. !7601 (Semyon Pupkov)
- Simplify copy on "Create a new list" dropdown in Issue Boards. !7605 (Victor Rodrigues)
- Refactor create service spec. !7609 (Semyon Pupkov)
- Shows unconfirmed email status in profile. !7611
- The admin user projects view now has a clickable group link. !7620 (James Gregory)
- Prevent DOM ID collisions resulting from user-generated content anchors. !7631
- Replace static fixture for abuse_reports_spec. !7644 (winniehell)
- Define common helper for describe pagination params in api. !7646 (Semyon Pupkov)
- Move abuse report spinach test to rspec. !7659 (Semyon Pupkov)
- Replace static fixture for awards_handler_spec. !7661 (winniehell)
- API: Add ability to unshare a project from a group. !7662 (Robert Schilling)
- Replace references to MergeRequestDiff#commits with st_commits when we care only about the number of commits. !7668
- Add issue events filter and make all really show all events. !7673 (Oxan van Leeuwen)
- Replace static fixture for notes_spec. !7683 (winniehell)
- Replace static fixture for shortcuts_issuable_spec. !7685 (winniehell)
- Replace static fixture for zen_mode_spec. !7686 (winniehell)
- Replace static fixture for right_sidebar_spec. !7687 (winniehell)
- Add online terminal support for Kubernetes. !7690
- Move admin abuse report spinach test to rspec. !7691 (Semyon Pupkov)
- Move admin spam spinach test to Rspec. !7708 (Semyon Pupkov)
- Make API::Helpers find a project with only one query. !7714
- Create builds in transaction to avoid empty pipelines. !7742
- Render SVG images in diffs and notes. !7747 (andrebsguedes)
- Add setting to enable/disable HTML emails. !7749
- Use SmartInterval for MR widget and improve visibilitychange functionality. !7762
- Resolve "Remove Builds tab from Merge Requests and Commits". !7763
- Moved new projects button below new group button on the welcome screen. !7770
- fix display hook error message. !7775 (basyura)
- Refactor issuable_filters_present to reduce duplications. !7776 (Semyon Pupkov)
- Redirect to sign-in page when unauthenticated user tries to create a snippet. !7786
- Fix Archived project merge requests add to group's Merge Requests. !7790 (Jacopo Beschi @jacopo-beschi)
- Update generic/external build status to match normal build status template. !7811
- Enable AsciiDoctor admonition icons. !7812 (Horacio Sanson)
- Do not raise error in AutocompleteController#users when not authorized. !7817 (Semyon Pupkov)
- fix: 24982- Remove'Signed in successfully' message After this change the sign-in-success flash message will not be shown. !7837 (jnoortheen)
- Fix Latest deployment link is broken. !7839
- Don't display prompt to add SSH keys if SSH protocol is disabled. !7840 (Andrew Smith (EspadaV8))
- Allow unauthenticated access to some Project API GET endpoints. !7843
- Refactor presenters ChatCommands. !7846
- Improve help message for issue create slash command. !7850
- change text around timestamps to make it clear which timestamp is displayed. !7860 (BM5k)
- Improve Build Log scrolling experience. !7895
- Change ref property to commitRef in vue commit component. !7901
- Prevent user creating issue or MR without signing in for a group. !7902
- Provides a sensible default message when adding a README to a project. !7903
- Bump ruby version to 2.3.3. !7904
- Fix comments activity tab visibility condition. !7913 (Rydkin Maxim)
- Remove unnecessary target branch link from MR page in case of deleted target branch. !7916 (Rydkin Maxim)
- Add image controls to MR diffs. !7919
- Remove wrong '.builds-feature' class from the MR settings fieldset. !7930
- Resolve "Manual actions on pipeline graph". !7931
- Avoid escaping relative links in Markdown twice. !7940 (winniehell)
- Move admin hooks spinach to rspec. !7942 (Semyon Pupkov)
- Move admin logs spinach test to rspec. !7945 (Semyon Pupkov)
- fix: removed signed_out notification. !7958 (jnoortheen)
- Accept environment variables from the `pre-receive` script. !7967
- Do not reload diff for merge request made from fork when target branch in fork is updated. !7973
- Fixes left align issue for long system notes. !7982
- Add a slug to environments. !7983
- Fix lookup of project by unknown ref when caching is enabled. !7988
- Resolve "Provide SVG as a prop instead of hiding and copy them in environments table". !7992
- Introduce deployment services, starting with a KubernetesService. !7994
- Adds tests for custom event polyfill. !7996
- Allow all alphanumeric characters in file names. !8002 (winniehell)
- Added support for math rendering, using KaTeX, in Markdown and asciidoc. !8003 (Munken)
- Remove unnecessary commits order message. !8004
- API: Memoize the current_user so that sudo can work properly. !8017
- group authors in contribution graph with case insensitive email handle comparison. !8021
- Move admin active tab spinach tests to rspec. !8037 (Semyon Pupkov)
- Add Authentiq as Oauth provider. !8038 (Alexandros Keramidas)
- API: Ability to cherry pick a commit. !8047 (Robert Schilling)
- Fix Slack pipeline message from pipelines made by API. !8059
- API: Simple representation of group's projects. !8060 (Robert Schilling)
- Prevent overflow with vertical scroll when we have space to show content. !8061
- Allow to auto-configure Mattermost. !8070
- Introduce $CI_BUILD_REF_SLUG. !8072
- Added go back anchor on error pages. !8087
- Convert CI YAML variables keys into strings. !8088
- Adds Direct link from pipeline list to builds. !8097
- Cache last commit id for path. !8098 (Hiroyuki Sato)
- Pass variables from deployment project services to CI runner. !8107
- New Gitea importer. !8116
- Introduce "Set up autodeploy" button to help configure GitLab CI for deployment. !8135
- Prevent environment table to overflow when name has underscores. !8142
- Fix missing service error importing from EE to CE. !8144
- Milestoneish SQL performance partially improved and memoized. !8146
- Allow unauthenticated access to Repositories API GET endpoints. !8148
- fix colors and margins for adjacent alert banners. !8151
- Hides new issue button for non loggedin user. !8175
- Fix N+1 queries on milestone show pages. !8185
- Rename groups with .git in the end of the path. !8199
- Whitelist next project names: help, ci, admin, search. !8227
- Adds back CSS for progress-bars. !8237

## 8.14.10 (2017-02-15)

- No changes.

## 8.14.9 (2017-02-14)

- Patch Asciidocs rendering to block XSS.
- Fix XSS vulnerability in SVG attachments.
- Prevent the GitHub importer from assigning labels and comments to merge requests or issues belonging to other projects.
- Patch XSS vulnerability in RDOC support.

## 8.14.8 (2017-01-25)

- Accept environment variables from the `pre-receive` script. !7967
- Milestoneish SQL performance partially improved and memoized. !8146
- Fix N+1 queries on milestone show pages. !8185
- Speed up group milestone index by passing group_id to IssuesFinder. !8363
- Ensure issuable state changes only fire webhooks once.

## 8.14.7 (2017-01-21)

- Ensure export files are removed after a namespace is deleted.
- Don't allow project guests to subscribe to merge requests through the API. (Robert Schilling)
- Prevent users from creating notes on resources they can't access.
- Prevent users from deleting system deploy keys via the project deploy key API.
- Upgrade omniauth gem to 1.3.2.

## 8.14.6 (2017-01-10)

- Update the gitlab-markup gem to the version 1.5.1. !8509
- Updated Turbolinks to mitigate potential XSS attacks.

## 8.14.5 (2016-12-14)

- Moved Leave Project and Leave Group buttons to access_request_buttons from the settings dropdown. !7600
- fix display hook error message. !7775 (basyura)
- Remove wrong '.builds-feature' class from the MR settings fieldset. !7930
- Avoid escaping relative links in Markdown twice. !7940 (winniehell)
- API: Memoize the current_user so that sudo can work properly. !8017
- Displays milestone remaining days only when it's present.
- Allow branch names with dots on API endpoint.
- Issue#visible_to_user moved to IssuesFinder to prevent accidental use.
- Shows group members in project members list.
- Encode input when migrating ProcessCommitWorker jobs to prevent migration errors.
- Fixed timeago re-rendering every timeago.
- Fix missing Note access checks by moving Note#search to updated NoteFinder.

## 8.14.4 (2016-12-08)

- Fix diff view permalink highlighting. !7090
- Fix pipeline author for Slack and use pipeline id for pipeline link. !7506
- Fix compatibility with Internet Explorer 11 for merge requests. !7525 (Steffen Rauh)
- Reenables /user API request to return private-token if user is admin and request is made with sudo. !7615
- Fix Cicking on tabs on pipeline page should set URL. !7709
- Authorize users into imported GitLab project.
- Destroy a user's session when they delete their own account.
- Don't accidentally mark unsafe diff lines as HTML safe.
- Replace MR access checks with use of MergeRequestsFinder.
- Remove visible content caching.

## 8.14.3 (2016-12-02)

- Pass commit data to ProcessCommitWorker to reduce Git overhead. !7744
- Speed up issuable dashboards.
- Don't change relative URLs to absolute URLs in the Help page.
- Fixes "ActionView::Template::Error: undefined method `text?` for nil:NilClass" on MR pages.
- Fix branch validation for GitHub PR where repo/fork was renamed/deleted.
- Validate state param when filtering issuables.

## 8.14.2 (2016-12-01)

- Remove caching of events data. !6578
- Rephrase some system notes to be compatible with new system note style. !7692
- Pass tag SHA to post-receive hook when tag is created via UI. !7700
- Prevent error when submitting a merge request and pipeline is not defined. !7707
- Fixes system note style in commit discussion. !7721
- Use a Redis lease for updating authorized projects. !7733
- Refactor JiraService by moving code out of JiraService#execute method. !7756
- Update GitLab Workhorse to v1.0.1. !7759
- Fix pipelines info being hidden in merge request widget. !7808
- Fixed commit timeago not rendering after initial page.
- Fix for error thrown in cycle analytics events if build has not started.
- Fixed issue boards issue sorting when dragging issue into list.
- Allow access to the wiki with git when repository feature disabled.
- Fixed timeago not rendering when resolving a discussion.
- Update Sidekiq-cron to fix compatibility issues with Sidekiq 4.2.1.
- Timeout creating and viewing merge request for binary file.
- Gracefully recover from Redis connection failures in Sidekiq initializer.

## 8.14.1 (2016-11-28)

- Fix deselecting calendar days on contribution graph. !6453 (ClemMakesApps)
- Update grape entity to 0.6.0. !7491
- If Build running change accept merge request when build succeeds button from orange to blue. !7577
- Changed import sources buttons to checkboxes. !7598 (Luke "Jared" Bennett)
- Last minute CI Style tweaks for 8.14. !7643
- Fix exceptions when loading build trace. !7658
- Fix wrong template rendered when CI/CD settings aren't update successfully. !7665
- fixes last_deployment call environment is nil. !7671
- Sort builds by name within pipeline graph. !7681
- Correctly determine mergeability of MR with no discussions.
- Sidekiq stats in the admin area will now show correctly on different platforms. (blackst0ne)
- Fixed issue boards dragging card removing random issues.
- Fix information disclosure in `Projects::BlobController#update`.
- Fix missing access checks on issue lookup using IssuableFinder.
- Replace issue access checks with use of IssuableFinder.
- Non members cannot create labels through the API.
- Fix cycle analytics plan stage when commits are missing.

## 8.14.0 (2016-11-22)

- Use separate email-token for incoming email and revert back the inactive feature. !5914
- API: allow recursive tree request. !6088 (Rebeca Mendez)
- Replace jQuery.timeago with timeago.js. !6274 (ClemMakesApps)
- Add CI notifications. Who triggered a pipeline would receive an email after the pipeline is succeeded or failed. Users could also update notification settings accordingly. !6342
- Add button to delete all merged branches. !6449 (Toon Claes)
- Finer-grained Git gargage collection. !6588
- Introduce better credential and error checking to `rake gitlab:ldap:check`. !6601
- Centralize LDAP config/filter logic. !6606
- Make system notes less intrusive. !6755
- Process commits using a dedicated Sidekiq worker. !6802
- Show random messages when the To Do list is empty. !6818 (Josep Llaneras)
- Precalculate user's authorized projects in database. !6839
- Fix record not found error on NewNoteWorker processing. !6863 (Oswaldo Ferreira)
- Show avatars in mention dropdown. !6865
- Fix expanding a collapsed diff when converting a symlink to a regular file. !6953
- Defer saving project services to the database if there are no user changes. !6958
- Omniauth auto link LDAP user falls back to find by DN when user cannot be found by UID. !7002
- Display "folders" for environments. !7015
- Make it possible to trigger builds from webhooks. !7022 (Dmitry Poray)
- Fix showing pipeline status for a given commit from correct branch. !7034
- Add link to build pipeline within individual build pages. !7082
- Add api endpoint `/groups/owned`. !7103 (Borja Aparicio)
- Add query param to filter users by external & blocked type. !7109 (Yatish Mehta)
- Issues atom feed url reflect filters on dashboard. !7114 (Lucas Deschamps)
- Add setting to only allow merge requests to be merged when all discussions are resolved. !7125 (Rodolfo Arruda)
- Remove an extra leading space from diff paste data. !7133 (Hiroyuki Sato)
- Fix trace patching feature - update the updated_at value. !7146
- Fix 404 on network page when entering non-existent git revision. !7172 (Hiroyuki Sato)
- Rewrite git blame spinach feature tests to rspec feature tests. !7197 (Lisanne Fellinger)
- Add api endpoint for creating a pipeline. !7209 (Ido Leibovich)
- Allow users to subscribe to group labels. !7215
- Reduce API calls needed when importing issues and pull requests from GitHub. !7241 (Andrew Smith (EspadaV8))
- Only skip group when it's actually a group in the "Share with group" select. !7262
- Introduce round-robin project creation to spread load over multiple shards. !7266
- Ensure merge request's "remove branch" accessors return booleans. !7267
- Fix no "Register" tab if ldap auth is enabled (#24038). !7274 (Luc Didry)
- Expose label IDs in API. !7275 (Rares Sfirlogea)
- Fix invalid filename validation on eslint. !7281
- API: Ability to retrieve version information. !7286 (Robert Schilling)
- Added ability to throttle Sidekiq Jobs. !7292
- Set default Sidekiq retries to 3. !7294
- Fix double event and ajax request call on MR page. !7298 (YarNayar)
- Unify anchor link format for MR diff files. !7298 (YarNayar)
- Require projects before creating milestone. !7301 (gfyoung)
- Fix error when using invalid branch name when creating a new pipeline. !7324
- Return 400 when creating a system hook fails. !7350 (Robert Schilling)
- Auto-close environment when branch is deleted. !7355
- Rework cache invalidation so only changed data is refreshed. !7360
- Navigation bar issuables counters reflects dashboard issuables counters. !7368 (Lucas Deschamps)
- Fix cache for commit status in commits list to respect branches. !7372
- fixes 500 error on project show when user is not logged in and project is still empty. !7376
- Removed gray button styling from todo buttons in sidebars. !7387
- Fix project records with invalid visibility_level values. !7391
- Use 'Forking in progress' title when appropriate. !7394 (Philip Karpiak)
- Fix error links in help index page. !7396 (Fu Xu)
- Add support for reply-by-email when the email only contains HTML. !7397
- [Fix] Extra divider issue in dropdown. !7398
- Project download buttons always show. !7405 (Philip Karpiak)
- Give search-input correct padding-right value. !7407 (Philip Karpiak)
- Remove additional padding on right-aligned items in MR widget. !7411 (Didem Acet)
- Fix issue causing Labels not to appear in sidebar on MR page. !7416 (Alex Sanford)
- Allow mail_room idle_timeout option to be configurable. !7423
- Fix misaligned buttons on admin builds page. !7424 (Didem Acet)
- Disable "Request Access" functionality by default for new projects and groups. !7425
- fix shibboleth misconfigurations resulting in authentication bypass. !7428
- Added Mattermost slash command. !7438
- Allow to connect Chat account with GitLab. !7450
- Make New Group form respect default visibility application setting. !7454 (Jacopo Beschi @jacopo-beschi)
- Fix Error 500 when creating a merge request that contains an image that was deleted and added. !7457
- Fix labels API by adding missing current_user parameter. !7458 (Francesco Coda Zabetta)
- Changed restricted visibility admin buttons to checkboxes. !7463
- Send credentials (currently for registry only) with build data to GitLab Runner. !7474
- Fix POST /internal/allowed to cope with gitlab-shell v4.0.0 project paths. !7480
- Adds es6-promise Polyfill. !7482
- Added colored labels to related MR list. !7486 (Didem Acet)
- Use setter for key instead AR callback. !7488 (Semyon Pupkov)
- Limit labels returned for a specific project as an administrator. !7496
- Change slack notification comment link. !7498 (Herbert Kagumba)
- Allow registering users whose username contains dots. !7500 (Timothy Andrew)
- Fix race condition during group deletion and remove stale records present due to this bug. !7528 (Timothy Andrew)
- Check all namespaces on validation of new username. !7537
- Pass correct tag target to post-receive hook when creating tag via UI. !7556
- Add help message for configuring Mattermost slash commands. !7558
- Fix typo in Build page JavaScript. !7563 (winniehell)
- Make job script a required configuration entry. !7566
- Fix errors happening when source branch of merge request is removed and then restored. !7568
- Fix a wrong "The build for this merge request failed" message. !7579
- Fix Margins look weird in Project page with pinned sidebar in project stats bar. !7580
- Fix regression causing bad error message to appear on Merge Request form. !7599 (Alex Sanford)
- Fix activity page endless scroll on large viewports. !7608
- Fix 404 on some group pages when name contains dot. !7614
- Do not create a new TODO when failed build is allowed to fail. !7618
- Add deployment command to ChatOps. !7619
- Fix 500 error when group name ends with git. !7630
- Fix undefined error in CI linter. !7650
- Show events per stage on Cycle Analytics page. !23449
- Add JIRA remotelinks and prevent duplicated closing messages.
- Fixed issue boards counter border when unauthorized.
- Add placeholder for the example text for custom hex color on label creation popup. (Luis Alonso Chavez Armendariz)
- Add an index for project_id in project_import_data to improve performance.
- Fix broken commits search.
- Assignee dropdown now searches author of issue or merge request.
- Clicking "force remove source branch" label now toggles the checkbox again.
- More aggressively preload on merge request and issue index pages.
- Fix broken link to observatory cli on Frontend Dev Guide. (Sam Rose)
- Fixing the issue of the project fork url giving 500 when not signed instead of being redirected to sign in page. (Cagdas Gerede)
- Fix: Guest sees some repository details and gets 404.
- Add logging for rack attack events to production.log.
- Add environment info to builds page.
- Allow commit note to be visible if repo is visible.
- Bump omniauth-gitlab to 1.0.2 to fix incompatibility with omniauth-oauth2.
- Redesign pipelines page.
- Faster search inside Project.
- Search for a filename in a project.
- Allow sorting groups in the API.
- Fix: Todos Filter Shows All Users.
- Use the Gitlab Workhorse HTTP header in the admin dashboard. (Chris Wright)
- Fixed multiple requests sent when opening dropdowns.
- Added permissions per stage to cycle analytics endpoint.
- Fix project Visibility Level selector not using default values.
- Add events per stage to cycle analytics.
- Allow to test JIRA service settings without having a repository.
- Fix JIRA references for project snippets.
- Allow enabling and disabling commit and MR events for JIRA.
- simplify url generation. (Jarka Kadlecova)
- Show correct environment log in admin/logs (@duk3luk3 !7191)
- Fix Milestone dropdown not stay selected for `Upcoming` and `No Milestone` option !7117
- Diff collapse won't shift when collapsing.
- Backups do not fail anymore when using tar on annex and custom_hooks only. !5814
- Adds user project membership expired event to clarify why user was removed (Callum Dryden)
- Trim leading and trailing whitespace on project_path (Linus Thiel)
- Prevent award emoji via notes for issues/MRs authored by user (barthc)
- Adds support for the `token` attribute in project hooks API (Gauvain Pocentek)
- Change auto selection behaviour of emoji and slash commands to be more UX/Type friendly (Yann Gravrand)
- Adds an optional path parameter to the Commits API to filter commits by path (Luis HGO)
- Fix Markdown styling inside reference links (Jan Zdráhal)
- Create new issue board list after creating a new label
- Fix extra space on Build sidebar on Firefox !7060
- Fail gracefully when creating merge request with non-existing branch (alexsanford)
- Fix mobile layout issues in admin user overview page !7087
- Fix HipChat notifications rendering (airatshigapov, eisnerd)
- Removed unneeded "Builds" and "Environments" link from project titles
- Remove 'Edit' button from wiki edit view !7143 (Hiroyuki Sato)
- Cleaned up global namespace JS !19661 (Jose Ivan Vargas)
- Refactor Jira service to use jira-ruby gem
- Improved todos empty state
- Add hover to trash icon in notes !7008 (blackst0ne)
- Hides project activity tabs when features are disabled
- Only show one error message for an invalid email !5905 (lycoperdon)
- Added guide describing how to upgrade PostgreSQL using Slony
- Fix sidekiq stats in admin area (blackst0ne)
- Added label description as tooltip to issue board list title
- Created cycle analytics bundle JavaScript file
- Make the milestone page more responsive (yury-n)
- Hides container registry when repository is disabled
- API: Fix booleans not recognized as such when using the `to_boolean` helper
- Removed delete branch tooltip !6954
- Stop unauthorized users dragging on milestone page (blackst0ne)
- Restore issue boards welcome message when a project is created !6899
- Check that JavaScript file names match convention !7238 (winniehell)
- Do not show tooltip for active element !7105 (winniehell)
- Escape ref and path for relative links !6050 (winniehell)
- Fixed link typo on /help/ui to Alerts section. !6915 (Sam Rose)
- Fix broken issue/merge request links in JIRA comments. !6143 (Brian Kintz)
- Fix filtering of milestones with quotes in title (airatshigapov)
- Fix issue boards dragging bug in Safari
- Refactor less readable existence checking code from CoffeeScript !6289 (jlogandavison)
- Update mail_room and enable sentinel support to Reply By Email (!7101)
- Add task completion status in Issues and Merge Requests tabs: "X of Y tasks completed" (!6527, @gmesalazar)
- Simpler arguments passed to named_route on toggle_award_url helper method
- Fix typo in framework css class. !7086 (Daniel Voogsgerd)
- New issue board list dropdown stays open after adding a new list
- Fix: Backup restore doesn't clear cache
- Optimize Event queries by removing default order
- Add new icon for skipped builds
- Show created icon in pipeline mini-graph
- Remove duplicate links from sidebar
- API: Fix project deploy keys 400 and 500 errors when adding an existing key. !6784 (Joshua Welsh)
- Add Rake task to create/repair GitLab Shell hooks symlinks !5634
- Add job for removal of unreferenced LFS objects from both the database and the filesystem (Frank Groeneveld)
- Replace jquery.cookie plugin with js.cookie !7085
- Use MergeRequestsClosingIssues cache data on Issue#closed_by_merge_requests method
- Fix Sign in page 'Forgot your password?' link overlaps on medium-large screens
- Show full status link on MR & commit pipelines
- Fix documents and comments on Build API `scope`
- Initialize Sidekiq with the list of queues used by GitLab
- Refactor email, use setter method instead AR callbacks for email attribute (Semyon Pupkov)
- Shortened merge request modal to let clipboard button not overlap
- Adds JavaScript validation for group path editing field
- In all filterable drop downs, put input field in focus only after load is complete (Ido @leibo)
- Improve search query parameter naming in /admin/users !7115 (YarNayar)
- Fix table pagination to be responsive
- Fix applying GitHub-imported labels when importing job is interrupted
- Allow to search for user by secondary email address in the admin interface(/admin/users) !7115 (YarNayar)
- Updated commit SHA styling on the branches page.
- Fix "Without projects" filter. !6611 (Ben Bodenmiller)
- Fix 404 when visit /projects page

## 8.13.12 (2017-01-21)

- Ensure export files are removed after a namespace is deleted.
- Don't allow project guests to subscribe to merge requests through the API. (Robert Schilling)
- Prevent users from creating notes on resources they can't access.
- Prevent users from deleting system deploy keys via the project deploy key API.
- Upgrade omniauth gem to 1.3.2.

## 8.13.11 (2017-01-10)

- Update the gitlab-markup gem to the version 1.5.1. !8509
- Updated Turbolinks to mitigate potential XSS attacks.

## 8.13.10 (2016-12-14)

- API: Memoize the current_user so that sudo can work properly. !8017
- Filter `authentication_token`, `incoming_email_token` and `runners_token` parameters.
- Issue#visible_to_user moved to IssuesFinder to prevent accidental use.
- Fix missing Note access checks by moving Note#search to updated NoteFinder.

## 8.13.9 (2016-12-08)

- Reenables /user API request to return private-token if user is admin and request is made with sudo. !7615
- Replace MR access checks with use of MergeRequestsFinder.

## 8.13.8 (2016-12-02)

- Pass tag SHA to post-receive hook when tag is created via UI. !7700
- Validate state param when filtering issuables.

## 8.13.7 (2016-11-28)

- fixes 500 error on project show when user is not logged in and project is still empty. !7376
- Update grape entity to 0.6.0. !7491
- Fix information disclosure in `Projects::BlobController#update`.
- Fix missing access checks on issue lookup using IssuableFinder.
- Replace issue access checks with use of IssuableFinder.
- Non members cannot create labels through the API.

## 8.13.6 (2016-11-17)

- Omniauth auto link LDAP user falls back to find by DN when user cannot be found by UID. !7002
- Fix Milestone dropdown not stay selected for `Upcoming` and `No Milestone` option. !7117
- Fix relative links in Markdown wiki when displayed in "Project" tab. !7218
- Fix no "Register" tab if ldap auth is enabled (#24038). !7274 (Luc Didry)
- Fix cache for commit status in commits list to respect branches. !7372
- Fix issue causing Labels not to appear in sidebar on MR page. !7416 (Alex Sanford)
- Limit labels returned for a specific project as an administrator. !7496
- Clicking "force remove source branch" label now toggles the checkbox again.
- Allow commit note to be visible if repo is visible.
- Fix project Visibility Level selector not using default values.

## 8.13.5 (2016-11-08)

- Restore unauthenticated access to public container registries
- Fix showing pipeline status for a given commit from correct branch. !7034
- Only skip group when it's actually a group in the "Share with group" select. !7262
- Introduce round-robin project creation to spread load over multiple shards. !7266
- Ensure merge request's "remove branch" accessors return booleans. !7267
- Ensure external users are not able to clone disabled repositories.
- Fix XSS issue in Markdown autolinker.
- Respect event visibility in Gitlab::ContributionsCalendar.
- Honour issue and merge request visibility in their respective finders.
- Disable reference Markdown for unavailable features.
- Fix lightweight tags not processed correctly by GitTagPushService. !6532
- Allow owners to fetch source code in CI builds. !6943
- Return conflict error in label API when title is taken by group label. !7014
- Reduce the overhead to calculate number of open/closed issues and merge requests within the group or project. !7123
- Fix builds tab visibility. !7178
- Fix project features default values. !7181

## 8.13.4

- Pulled due to packaging error.

## 8.13.3 (2016-11-02)

- Removes any symlinks before importing a project export file. CVE-2016-9086
- Fixed Import/Export foreign key issue to do with project members.
- Changed build dropdown list length to be 6,5 builds long in the pipeline graph

## 8.13.2 (2016-10-31)

- Fix encoding issues on pipeline commits. !6832
- Use Hash rocket syntax to fix cycle analytics under Ruby 2.1. !6977
- Modify GitHub importer to be retryable. !7003
- Fix refs dropdown selection with special characters. !7061
- Fix horizontal padding for highlight blocks. !7062
- Pass user instance to `Labels::FindOrCreateService` or `skip_authorization: true`. !7093
- Fix builds dropdown overlapping bug. !7124
- Fix applying labels for GitHub-imported MRs. !7139
- Fix importing MR comments from GitHub. !7139
- Fix project member access for group links. !7144
- API: Fix booleans not recognized as such when using the `to_boolean` helper. !7149
- Fix and improve `Sortable.highest_label_priority`. !7165
- Fixed sticky merge request tabs when sidebar is pinned. !7167
- Only remove right connector of first build of last stage. !7179

## 8.13.1 (2016-10-25)

- Fix branch protection API. !6215
- Fix hidden pipeline graph on commit and MR page. !6895
- Fix Cycle analytics not showing correct data when filtering by date. !6906
- Ensure custom provider tab labels don't break layout. !6993
- Fix issue boards user link when in subdirectory. !7018
- Refactor and add new environment functionality to CI yaml reference. !7026
- Fix typo in project settings that prevents users from enabling container registry. !7037
- Fix events order in `users/:id/events` endpoint. !7039
- Remove extra line for empty issue description. !7045
- Don't append issue/MR templates to any existing text. !7050
- Fix error in generating labels. !7055
- Stop clearing the database cache on `rake cache:clear`. !7056
- Only show register tab if signup enabled. !7058
- Fix lightweight tags not processed correctly by GitTagPushService
- Expire and build repository cache after project import. !7064
- Fix bug where labels would be assigned to issues that were moved. !7065
- Fix reply-by-email not working due to queue name mismatch. !7068
- Fix 404 for group pages when GitLab setup uses relative url. !7071
- Fix `User#to_reference`. !7088
- Reduce overhead of `LabelFinder` by avoiding `#presence` call. !7094
- Fix unauthorized users dragging on issue boards. !7096
- Only schedule `ProjectCacheWorker` jobs when needed. !7099

## 8.13.0 (2016-10-22)

- Fix save button on project pipeline settings page. (!6955)
- All Sidekiq workers now use their own queue
- Avoid race condition when asynchronously removing expired artifacts. (!6881)
- Improve Merge When Build Succeeds triggers and execute on pipeline success. (!6675)
- Respond with 404 Not Found for non-existent tags (Linus Thiel)
- Truncate long labels with ellipsis in labels page
- Improve tabbing usability for sign in page (ClemMakesApps)
- Enforce TrailingSemicolon and EmptyLineBetweenBlocks in scss-lint
- Adding members no longer silently fails when there is extra whitespace
- Update runner version only when updating contacted_at
- Add link from system note to compare with previous version
- Use gitlab-shell v3.6.6
- Ignore references to internal issues when using external issues tracker
- Ability to resolve merge request conflicts with editor !6374
- Add `/projects/visible` API endpoint (Ben Boeckel)
- Fix centering of custom header logos (Ashley Dumaine)
- Keep around commits only pipeline creation as pipeline data doesn't change over time
- Update duration at the end of pipeline
- ExpireBuildArtifactsWorker query builds table without ordering enqueuing one job per build to cleanup
- Add group level labels. (!6425)
- Add an example for testing a phoenix application with GitLab CI in the docs (Manthan Mallikarjun)
- Cancelled pipelines could be retried. !6927
- Updating verbiage on git basics to be more intuitive
- Fix project_feature record not generated on project creation
- Clarify documentation for Runners API (Gennady Trafimenkov)
- Use optimistic locking for pipelines and builds
- The instrumentation for Banzai::Renderer has been restored
- Change user & group landing page routing from /u/:username to /:username
- Added documentation for .gitattributes files
- Move Pipeline Metrics to separate worker
- AbstractReferenceFilter caches project_refs on RequestStore when active
- Replaced the check sign to arrow in the show build view. !6501
- Add a /wip slash command to toggle the Work In Progress status of a merge request. !6259 (tbalthazar)
- ProjectCacheWorker updates caches at most once per 15 minutes per project
- Fix Error 500 when viewing old merge requests with bad diff data
- Create a new /templates namespace for the /licenses, /gitignores and /gitlab_ci_ymls API endpoints. !5717 (tbalthazar)
- Fix viewing merged MRs when the source project has been removed !6991
- Speed-up group milestones show page
- Fix inconsistent options dropdown caret on mobile viewports (ClemMakesApps)
- Extract project#update_merge_requests and SystemHooks to its own worker from GitPushService
- Fix discussion thread from emails for merge requests. !7010
- Don't include archived projects when creating group milestones. !4940 (Jeroen Jacobs)
- Add tag shortcut from the Commit page. !6543
- Keep refs for each deployment
- Close open tooltips on page navigation (Linus Thiel)
- Allow browsing branches that end with '.atom'
- Log LDAP lookup errors and don't swallow unrelated exceptions. !6103 (Markus Koller)
- Replace unique keyframes mixin with keyframe mixin with specific names (ClemMakesApps)
- Add more tests for calendar contribution (ClemMakesApps)
- Update GitLab Shell to fix some problems with moving projects between storages
- Cache rendered markdown in the database, rather than Redis
- Add todo toggle event (ClemMakesApps)
- Avoid database queries on Banzai::ReferenceParser::BaseParser for nodes without references
- Simplify Mentionable concern instance methods
- API: Ability to retrieve version information (Robert Schilling)
- Fix permission for setting an issue's due date
- API: Multi-file commit !6096 (mahcsig)
- Unicode emoji are now converted to images
- Revert "Label list shows all issues (opened or closed) with that label"
- Expose expires_at field when sharing project on API
- Fix VueJS template tags being rendered in code comments
- Added copy file path button to merge request diff files
- Fix issue with page scrolling to top when closing or pinning sidebar (lukehowell)
- Add Issue Board API support (andrebsguedes)
- Allow the Koding integration to be configured through the API
- Add new issue button to each list on Issues Board
- Execute specific named route method from toggle_award_url helper method
- Added soft wrap button to repository file/blob editor
- Update namespace validation to forbid reserved names (.git and .atom) (Will Starms)
- Show the time ago a merge request was deployed to an environment
- Add RTL support to markdown renderer (Ebrahim Byagowi)
- Add word-wrap to issue title on issue and milestone boards (ClemMakesApps)
- Fix todos page mobile viewport layout (ClemMakesApps)
- Make issues search less finicky
- Fix inconsistent highlighting of already selected activity nav-links (ClemMakesApps)
- Remove redundant mixins (ClemMakesApps)
- Added 'Download' button to the Snippets page (Justin DiPierro)
- Add visibility level to project repository
- Fix robots.txt disallowing access to groups starting with "s" (Matt Harrison)
- Close open merge request without source project (Katarzyna Kobierska Ula Budziszewska)
- Fix showing commits from source project for merge request !6658
- Fix that manual jobs would no longer block jobs in the next stage. !6604
- Add configurable email subject suffix (Fu Xu)
- Use defined colour for a language when available !6748 (nilsding)
- Added tooltip to fork count on project show page. (Justin DiPierro)
- Use a ConnectionPool for Rails.cache on Sidekiq servers
- Replace `alias_method_chain` with `Module#prepend`
- Enable GitLab Import/Export for non-admin users.
- Preserve label filters when sorting !6136 (Joseph Frazier)
- MergeRequest#new form load diff asynchronously
- Only update issuable labels if they have been changed
- Take filters in account in issuable counters. !6496
- Use custom Ruby images to test builds (registry.dev.gitlab.org/gitlab/gitlab-build-images:*)
- Replace static issue fixtures by script !6059 (winniehell)
- Append issue template to existing description !6149 (Joseph Frazier)
- Trending projects now only show public projects and the list of projects is cached for a day
- Memoize GitLab Shell's secret token (!6599, Justin DiPierro)
- Revoke button in Applications Settings underlines on hover.
- Use higher size on Gitlab::Redis connection pool on Sidekiq servers
- Add missing values to linter !6276 (Katarzyna Kobierska Ula Budziszewska)
- Revert avoid touching file system on Build#artifacts?
- Stop using a Redis lease when updating the project activity timestamp whenever a new event is created
- Add disabled delete button to protected branches (ClemMakesApps)
- Add broadcast messages and alerts below sub-nav
- Better empty state for Groups view
- API: New /users/:id/events endpoint
- Update ruby-prof to 0.16.2. !6026 (Elan Ruusamäe)
- Replace bootstrap caret with fontawesome caret (ClemMakesApps)
- Fix unnecessary escaping of reserved HTML characters in milestone title. !6533
- Add organization field to user profile
- Change user pages routing from /u/:username/PATH to /users/:username/PATH. Old routes will redirect to the new ones for the time being.
- Fix enter key when navigating search site search dropdown. !6643 (Brennan Roberts)
- Fix deploy status responsiveness error !6633
- Make searching for commits case insensitive
- Fix resolved discussion display in side-by-side diff view !6575
- Optimize GitHub importing for speed and memory
- API: expose pipeline data in builds API (!6502, Guilherme Salazar)
- Notify the Merger about merge after successful build (Dimitris Karakasilis)
- Reduce queries needed to find users using their SSH keys when pushing commits
- Prevent rendering the link to all when the author has no access (Katarzyna Kobierska Ula Budziszewska)
- Fix broken repository 500 errors in project list
- Fix the diff in the merge request view when converting a symlink to a regular file
- Fix Pipeline list commit column width should be adjusted
- Close todos when accepting merge requests via the API !6486 (tonygambone)
- Ability to batch assign issues relating to a merge request to the author. !5725 (jamedjo)
- Changed Slack service user referencing from full name to username (Sebastian Poxhofer)
- Retouch environments list and deployments list
- Add multiple command support for all label related slash commands !6780 (barthc)
- Add Container Registry on/off status to Admin Area !6638 (the-undefined)
- Add Nofollow for uppercased scheme in external urls !6820 (the-undefined)
- Allow empty merge requests !6384 (Artem Sidorenko)
- Grouped pipeline dropdown is a scrollable container
- Cleanup Ci::ApplicationController. !6757 (Takuya Noguchi)
- Fixes padding in all clipboard icons that have .btn class
- Fix a typo in doc/api/labels.md
- Fix double-escaping in activities tab (Alexandre Maia)
- API: all unknown routing will be handled with 404 Not Found
- Add docs for request profiling
- Delete dynamic environments
- Fix buggy iOS tooltip layering behavior.
- Make guests unable to view MRs on private projects
- Fix broken Project API docs (Takuya Noguchi)
- Migrate invalid project members (owner -> master)

## 8.12.12 (2016-12-08)

- Replace MR access checks with use of MergeRequestsFinder
- Reenables /user API request to return private-token if user is admin and request is made with sudo

## 8.12.11 (2016-12-02)

- No changes

## 8.12.10 (2016-11-28)

- Fix information disclosure in `Projects::BlobController#update`
- Fix missing access checks on issue lookup using IssuableFinder
- Replace issue access checks with use of IssuableFinder

## 8.12.9 (2016-11-07)

- Fix XSS issue in Markdown autolinker

## 8.12.8 (2016-11-02)

- Removes any symlinks before importing a project export file. CVE-2016-9086
- Fixed Import/Export foreign key issue to do with project members.

## 8.12.7

  - Prevent running `GfmAutocomplete` setup for each diff note. !6569
  - Fix long commit messages overflow viewport in file tree. !6573
  - Use `gitlab-markup` gem instead of `github-markup` to fix `.rst` file rendering. !6659
  - Prevent flash alert text from being obscured when container is fluid. !6694
  - Fix due date being displayed as `NaN` in Safari. !6797
  - Fix JS bug with select2 because of missing `data-field` attribute in select box. !6812
  - Do not alter `force_remove_source_branch` options on MergeRequest unless specified. !6817
  - Fix GFM autocomplete setup being called several times. !6840
  - Handle case where deployment ref no longer exists. !6855

## 8.12.6

  - Update mailroom to 0.8.1 in Gemfile.lock  !6814

## 8.12.5

  - Switch from request to env in ::API::Helpers. !6615
  - Update the mail_room gem to 0.8.1 to fix a race condition with the mailbox watching thread. !6714
  - Improve issue load time performance by avoiding ORDER BY in find_by call. !6724
  - Add a new gitlab:users:clear_all_authentication_tokens task. !6745
  - Don't send Private-Token (API authentication) headers to Sentry
  - Share projects via the API only with groups the authenticated user can access

## 8.12.4

  - Fix "Copy to clipboard" tooltip to say "Copied!" when clipboard button is clicked. !6294 (lukehowell)
  - Fix padding in build sidebar. !6506
  - Changed compare dropdowns to dropdowns with isolated search input. !6550
  - Fix race condition on LFS Token. !6592
  - Fix type mismatch bug when closing Jira issue. !6619
  - Fix lint-doc error. !6623
  - Skip wiki creation when GitHub project has wiki enabled. !6665
  - Fix issues importing services via Import/Export. !6667
  - Restrict failed login attempts for users with 2FA enabled. !6668
  - Fix failed project deletion when feature visibility set to private. !6688
  - Prevent claiming associated model IDs via import.
  - Set GitLab project exported file permissions to owner only
  - Improve the way merge request versions are compared with each other

## 8.12.3

  - Update GitLab Shell to support low IO priority for storage moves

## 8.12.2

  - Fix Import/Export not recognising correctly the imported services.
  - Fix snippets pagination
  - Fix "Create project" button layout when visibility options are restricted
  - Fix List-Unsubscribe header in emails
  - Fix IssuesController#show degradation including project on loaded notes
  - Fix an issue with the "Commits" section of the cycle analytics summary. !6513
  - Fix errors importing project feature and milestone models using GitLab project import
  - Make JWT messages Docker-compatible
  - Fix duplicate branch entry in the merge request version compare dropdown
  - Respect the fork_project permission when forking projects
  - Only update issuable labels if they have been changed
  - Fix bug where 'Search results' repeated many times when a search in the emoji search form is cleared (Xavier Bick) (@zeiv)
  - Fix resolve discussion buttons endpoint path
  - Refactor remnants of CoffeeScript destructured opts and super !6261

## 8.12.1

  - Fix a memory leak in HTML::Pipeline::SanitizationFilter::WHITELIST
  - Fix issue with search filter labels not displaying

## 8.12.0 (2016-09-22)

  - Removes inconsistency regarding tagging immediately as merged once you create a new branch. !6408
  - Update the rouge gem to 2.0.6, which adds highlighting support for JSX, Prometheus, and others. !6251
  - Only check :can_resolve permission if the note is resolvable
  - Bump fog-aws to v0.11.0 to support ap-south-1 region
  - Add ability to fork to a specific namespace using API. (ritave)
  - Allow to set request_access_enabled for groups and projects
  - Cleanup misalignments in Issue list view !6206
  - Only create a protected branch upon a push to a new branch if a rule for that branch doesn't exist
  - Add Pipelines for Commit
  - Prune events older than 12 months. (ritave)
  - Prepend blank line to `Closes` message on merge request linked to issue (lukehowell)
  - Fix issues/merge-request templates dropdown for forked projects
  - Filter tags by name !6121
  - Update gitlab shell secret file also when it is empty. !3774 (glensc)
  - Give project selection dropdowns responsive width, make non-wrapping.
  - Fix note form hint showing slash commands supported for commits.
  - Make push events have equal vertical spacing.
  - API: Ensure invitees are not returned in Members API.
  - Preserve applied filters on issues search.
  - Add two-factor recovery endpoint to internal API !5510
  - Pass the "Remember me" value to the U2F authentication form
  - Display stages in valid order in stages dropdown on build page
  - Only update projects.last_activity_at once per hour when creating a new event
  - Cycle analytics (first iteration) !5986
  - Remove vendor prefixes for linear-gradient CSS (ClemMakesApps)
  - Move pushes_since_gc from the database to Redis
  - Limit number of shown environments on Merge Request: show only environments for target_branch, source_branch and tags
  - Add font color contrast to external label in admin area (ClemMakesApps)
  - Fix find file navigation links (ClemMakesApps)
  - Change logo animation to CSS (ClemMakesApps)
  - Instructions for enabling Git packfile bitmaps !6104
  - Use Search::GlobalService.new in the `GET /projects/search/:query` endpoint
  - Fix long comments in diffs messing with table width
  - Add spec covering 'Gitlab::Git::committer_hash' !6433 (dandunckelman)
  - Fix pagination on user snippets page
  - Honor "fixed layout" preference in more places !6422
  - Run CI builds with the permissions of users !5735
  - Fix sorting of issues in API
  - Fix download artifacts button links !6407
  - Sort project variables by key. !6275 (Diego Souza)
  - Ensure specs on sorting of issues in API are deterministic on MySQL
  - Added ability to use predefined CI variables for environment name
  - Added ability to specify URL in environment configuration in gitlab-ci.yml
  - Escape search term before passing it to Regexp.new !6241 (winniehell)
  - Fix pinned sidebar behavior in smaller viewports !6169
  - Fix file permissions change when updating a file on the GitLab UI !5979
  - Added horizontal padding on build page sidebar on code coverage block. !6196 (Vitaly Baev)
  - Change merge_error column from string to text type
  - Fix issue with search filter labels not displaying
  - Reduce contributions calendar data payload (ClemMakesApps)
  - Show all pipelines for merge requests even from discarded commits !6414
  - Replace contributions calendar timezone payload with dates (ClemMakesApps)
  - Changed MR widget build status to pipeline status !6335
  - Add `web_url` field to issue, merge request, and snippet API objects (Ben Boeckel)
  - Enable pipeline events by default !6278
  - Add pipeline email service !6019
  - Move parsing of sidekiq ps into helper !6245 (pascalbetz)
  - Added go to issue boards keyboard shortcut
  - Expose `sha` and `merge_commit_sha` in merge request API (Ben Boeckel)
  - Emoji can be awarded on Snippets !4456
  - Set path for all JavaScript cookies to honor GitLab's subdirectory setting !5627 (Mike Greiling)
  - Fix blame table layout width
  - Spec testing if issue authors can read issues on private projects
  - Fix bug where pagination is still displayed despite all todos marked as done (ClemMakesApps)
  - Request only the LDAP attributes we need !6187
  - Center build stage columns in pipeline overview (ClemMakesApps)
  - Fix bug with tooltip not hiding on discussion toggle button
  - Rename behaviour to behavior in bug issue template for consistency (ClemMakesApps)
  - Fix bug stopping issue description being scrollable after selecting issue template
  - Remove suggested colors hover underline (ClemMakesApps)
  - Fix jump to discussion button being displayed on commit notes
  - Shorten task status phrase (ClemMakesApps)
  - Fix project visibility level fields on settings
  - Add hover color to emoji icon (ClemMakesApps)
  - Increase ci_builds artifacts_size column to 8-byte integer to allow larger files
  - Add textarea autoresize after comment (ClemMakesApps)
  - Do not write SSH public key 'comments' to authorized_keys !6381
  - Add due date to issue todos
  - Refresh todos count cache when an Issue/MR is deleted
  - Fix branches page dropdown sort alignment (ClemMakesApps)
  - Hides merge request button on branches page is user doesn't have permissions
  - Add white background for no readme container (ClemMakesApps)
  - API: Expose issue confidentiality flag. (Robert Schilling)
  - Fix markdown anchor icon interaction (ClemMakesApps)
  - Test migration paths from 8.5 until current release !4874
  - Replace animateEmoji timeout with eventListener (ClemMakesApps)
  - Show badges in Milestone tabs. !5946 (Dan Rowden)
  - Optimistic locking for Issues and Merge Requests (title and description overriding prevention)
  - Require confirmation when not logged in for unsubscribe links !6223 (Maximiliano Perez Coto)
  - Add `wiki_page_events` to project hook APIs (Ben Boeckel)
  - Remove Gitorious import
  - Loads GFM autocomplete source only when required
  - Fix issue with slash commands not loading on new issue page
  - Fix inconsistent background color for filter input field (ClemMakesApps)
  - Remove prefixes from transition CSS property (ClemMakesApps)
  - Add Sentry logging to API calls
  - Add BroadcastMessage API
  - Merge request tabs are fixed when scrolling page
  - Use 'git update-ref' for safer web commits !6130
  - Sort pipelines requested through the API
  - Automatically expand hidden discussions when accessed by a permalink !5585 (Mike Greiling)
  - Fix issue boards loading on large screens
  - Change pipeline duration to be jobs running time instead of simple wall time from start to end !6084
  - Show queued time when showing a pipeline !6084
  - Remove unused mixins (ClemMakesApps)
  - Fix issue board label filtering appending already filtered labels
  - Add search to all issue board lists
  - Scroll active tab into view on mobile
  - Fix groups sort dropdown alignment (ClemMakesApps)
  - Add horizontal scrolling to all sub-navs on mobile viewports (ClemMakesApps)
  - Use JavaScript tooltips for mentions !5301 (winniehell)
  - Add hover state to todos !5361 (winniehell)
  - Fix icon alignment of star and fork buttons !5451 (winniehell)
  - Fix alignment of icon buttons !5887 (winniehell)
  - Added Ubuntu 16.04 support for packager.io (JonTheNiceGuy)
  - Fix markdown help references (ClemMakesApps)
  - Add last commit time to repo view (ClemMakesApps)
  - Fix accessibility and visibility of project list dropdown button !6140
  - Fix missing flash messages on service edit page (airatshigapov)
  - Added project-specific enable/disable setting for LFS !5997
  - Added group-specific enable/disable setting for LFS !6164
  - Add optional 'author' param when making commits. !5822 (dandunckelman)
  - Don't expose a user's token in the `/api/v3/user` API (!6047)
  - Remove redundant js-timeago-pending from user activity log (ClemMakesApps)
  - Ability to manage project issues, snippets, wiki, merge requests and builds access level
  - Remove inconsistent font weight for sidebar's labels (ClemMakesApps)
  - Align add button on repository view (ClemMakesApps)
  - Fix contributions calendar month label truncation (ClemMakesApps)
  - Import release note descriptions from GitHub (EspadaV8)
  - Added tests for diff notes
  - Add pipeline events to Slack integration !5525
  - Add a button to download latest successful artifacts for branches and tags !5142
  - Remove redundant pipeline tooltips (ClemMakesApps)
  - Expire commit info views after one day, instead of two weeks, to allow for user email updates
  - Add delimiter to project stars and forks count (ClemMakesApps)
  - Fix badge count alignment (ClemMakesApps)
  - Remove green outline from `New branch unavailable` button on issue page !5858 (winniehell)
  - Fix repo title alignment (ClemMakesApps)
  - Change update interval of contacted_at
  - Add LFS support to SSH !6043
  - Fix branch title trailing space on hover (ClemMakesApps)
  - Don't include 'Created By' tag line when importing from GitHub if there is a linked GitLab account (EspadaV8)
  - Award emoji tooltips containing more than 10 usernames are now truncated !4780 (jlogandavison)
  - Fix duplicate "me" in award emoji tooltip !5218 (jlogandavison)
  - Order award emoji tooltips in order they were added (EspadaV8)
  - Fix spacing and vertical alignment on build status icon on commits page (ClemMakesApps)
  - Update merge_requests.md with a simpler way to check out a merge request. !5944
  - Fix button missing type (ClemMakesApps)
  - Gitlab::Checks is now instrumented
  - Move to project dropdown with infinite scroll for better performance
  - Fix leaking of submit buttons outside the width of a main container !18731 (originally by @pavelloz)
  - Load branches asynchronously in Cherry Pick and Revert dialogs.
  - Convert datetime coffeescript spec to ES6 (ClemMakesApps)
  - Add merge request versions !5467
  - Change using size to use count and caching it for number of group members. !5935
  - Replace play icon font with svg (ClemMakesApps)
  - Added 'only_allow_merge_if_build_succeeds' project setting in the API. !5930 (Duck)
  - Reduce number of database queries on builds tab
  - Wrap text in commit message containers
  - Capitalize mentioned issue timeline notes (ClemMakesApps)
  - Fix inconsistent checkbox alignment (ClemMakesApps)
  - Use the default branch for displaying the project icon instead of master !5792 (Hannes Rosenögger)
  - Adds response mime type to transaction metric action when it's not HTML
  - Fix hover leading space bug in pipeline graph !5980
  - Avoid conflict with admin labels when importing GitHub labels
  - User can edit closed MR with deleted fork (Katarzyna Kobierska Ula Budziszewska) !5496
  - Fix repository page ui issues
  - Avoid protected branches checks when verifying access without branch name
  - Add information about user and manual build start to runner as variables !6201 (Sergey Gnuskov)
  - Fixed invisible scroll controls on build page on iPhone
  - Fix error on raw build trace download for old builds stored in database !4822
  - Refactor the triggers page and documentation !6217
  - Show values of CI trigger variables only when clicked (Katarzyna Kobierska Ula Budziszewska)
  - Use default clone protocol on "check out, review, and merge locally" help page URL
  - Let the user choose a namespace and name on GitHub imports
  - API for Ci Lint !5953 (Katarzyna Kobierska Urszula Budziszewska)
  - Allow bulk update merge requests from merge requests index page
  - Ensure validation messages are shown within the milestone form
  - Add notification_settings API calls !5632 (mahcsig)
  - Remove duplication between project builds and admin builds view !5680 (Katarzyna Kobierska Ula Budziszewska)
  - Fix URLs with anchors in wiki !6300 (houqp)
  - Deleting source project with existing fork link will close all related merge requests !6177 (Katarzyna Kobierska Ula Budziszeska)
  - Return 204 instead of 404 for /ci/api/v1/builds/register.json if no builds are scheduled for a runner !6225
  - Fix Gitlab::Popen.popen thread-safety issue
  - Add specs to removing project (Katarzyna Kobierska Ula Budziszewska)
  - Clean environment variables when running git hooks
  - Fix Import/Export issues importing protected branches and some specific models
  - Fix non-master branch readme display in tree view
  - Add UX improvements for merge request version diffs

## 8.11.11 (2016-11-07)

- Fix XSS issue in Markdown autolinker

## 8.11.10 (2016-11-02)

- Removes any symlinks before importing a project export file. CVE-2016-9086

## 8.11.9

  - Don't send Private-Token (API authentication) headers to Sentry
  - Share projects via the API only with groups the authenticated user can access

## 8.11.8

  - Respect the fork_project permission when forking projects
  - Set a restrictive CORS policy on the API for credentialed requests
  - API: disable rails session auth for non-GET/HEAD requests
  - Escape HTML nodes in builds commands in CI linter

## 8.11.7

  - Avoid conflict with admin labels when importing GitHub labels. !6158
  - Restores `fieldName` to allow only string values in `gl_dropdown.js`. !6234
  - Allow the Rails cookie to be used for API authentication.
  - Login/Register UX upgrade !6328

## 8.11.6

  - Fix unnecessary horizontal scroll area in pipeline visualizations. !6005
  - Make merge conflict file size limit 200 KB, to match the docs. !6052
  - Fix an error where we were unable to create a CommitStatus for running state. !6107
  - Optimize discussion notes resolving and unresolving. !6141
  - Fix GitLab import button. !6167
  - Restore SSH Key title auto-population behavior. !6186
  - Fix DB schema to match latest migration. !6256
  - Exclude some pending or inactivated rows in Member scopes.

## 8.11.5

  - Optimize branch lookups and force a repository reload for Repository#find_branch. !6087
  - Fix member expiration date picker after update. !6184
  - Fix suggested colors options for new labels in the admin area. !6138
  - Optimize discussion notes resolving and unresolving
  - Fix GitLab import button
  - Fix confidential issues being exposed as public using gitlab.com export
  - Remove gitorious from import_sources. !6180
  - Scope webhooks/services that will run for confidential issues
  - Remove gitorious from import_sources
  - Fix confidential issues being exposed as public using gitlab.com export
  - Use oj gem for faster JSON processing

## 8.11.4

  - Fix resolving conflicts on forks. !6082
  - Fix diff commenting on merge requests created prior to 8.10. !6029
  - Fix pipelines tab layout regression. !5952
  - Fix "Wiki" link not appearing in navigation for projects with external wiki. !6057
  - Do not enforce using hash with hidden key in CI configuration. !6079
  - Fix hover leading space bug in pipeline graph !5980
  - Fix sorting issues by "last updated" doesn't work after import from GitHub
  - GitHub importer use default project visibility for non-private projects
  - Creating an issue through our API now emails label subscribers !5720
  - Block concurrent updates for Pipeline
  - Don't create groups for unallowed users when importing projects
  - Fix issue boards leak private label names and descriptions
  - Fix broken gitlab:backup:restore because of bad permissions on repo storage !6098 (Dirk Hörner)
  - Remove gitorious. !5866
  - Allow compare merge request versions

## 8.11.3

  - Allow system info page to handle case where info is unavailable
  - Label list shows all issues (opened or closed) with that label
  - Don't show resolve conflicts link before MR status is updated
  - Fix IE11 fork button bug !5982
  - Don't prevent viewing the MR when git refs for conflicts can't be found on disk
  - Fix external issue tracker "Issues" link leading to 404s
  - Don't try to show merge conflict resolution info if a merge conflict contains non-UTF-8 characters
  - Automatically expand hidden discussions when accessed by a permalink !5585 (Mike Greiling)
  - Issues filters reset button

## 8.11.2

  - Show "Create Merge Request" widget for push events to fork projects on the source project. !5978
  - Use gitlab-workhorse 0.7.11 !5983
  - Does not halt the GitHub import process when an error occurs. !5763
  - Fix file links on project page when default view is Files !5933
  - Fixed enter key in search input not working !5888

## 8.11.1

  - Pulled due to packaging error.

## 8.11.0 (2016-08-22)

  - Use test coverage value from the latest successful pipeline in badge. !5862
  - Add test coverage report badge. !5708
  - Remove the http_parser.rb dependency by removing the tinder gem. !5758 (tbalthazar)
  - Add Koding (online IDE) integration
  - Ability to specify branches for Pivotal Tracker integration (Egor Lynko)
  - Fix don't pass a local variable called `i` to a partial. !20510 (herminiotorres)
  - Fix rename `add_users_into_project` and `projects_ids`. !20512 (herminiotorres)
  - Fix adding line comments on the initial commit to a repo !5900
  - Fix the title of the toggle dropdown button. !5515 (herminiotorres)
  - Rename `markdown_preview` routes to `preview_markdown`. (Christopher Bartz)
  - Update to Ruby 2.3.1. !4948
  - Add Issues Board !5548
  - Allow resolving merge conflicts in the UI !5479
  - Improve diff performance by eliminating redundant checks for text blobs
  - Ensure that branch names containing escapable characters (e.g. %20) aren't unescaped indiscriminately. !5770 (ewiltshi)
  - Convert switch icon into icon font (ClemMakesApps)
  - API: Endpoints for enabling and disabling deploy keys
  - API: List access requests, request access, approve, and deny access requests to a project or a group. !4833
  - Use long options for curl examples in documentation !5703 (winniehell)
  - Added tooltip listing label names to the labels value in the collapsed issuable sidebar
  - Remove magic comments (`# encoding: UTF-8`) from Ruby files. !5456 (winniehell)
  - GitLab Performance Monitoring can now track custom events such as the number of tags pushed to a repository
  - Add support for relative links starting with ./ or / to RelativeLinkFilter (winniehell)
  - Allow naming U2F devices !5833
  - Ignore URLs starting with // in Markdown links !5677 (winniehell)
  - Fix CI status icon link underline (ClemMakesApps)
  - The Repository class is now instrumented
  - Fix commit mention font inconsistency (ClemMakesApps)
  - Do not escape URI when extracting path !5878 (winniehell)
  - Fix filter label tooltip HTML rendering (ClemMakesApps)
  - Cache the commit author in RequestStore to avoid extra lookups in PostReceive
  - Expand commit message width in repo view (ClemMakesApps)
  - Cache highlighted diff lines for merge requests
  - Pre-create all builds for a Pipeline when the new Pipeline is created !5295
  - Allow merge request diff notes and discussions to be explicitly marked as resolved
  - API: Add deployment endpoints
  - API: Add Play endpoint on Builds
  - Fix of 'Commits being passed to custom hooks are already reachable when using the UI'
  - Show wall clock time when showing a pipeline. !5734
  - Show member roles to all users on members page
  - Project.visible_to_user is instrumented again
  - Fix awardable button mutuality loading spinners (ClemMakesApps)
  - Sort todos by date and priority
  - Add support for using RequestStore within Sidekiq tasks via SIDEKIQ_REQUEST_STORE env variable
  - Optimize maximum user access level lookup in loading of notes
  - Send notification emails to users newly mentioned in issue and MR edits !5800
  - Add "No one can push" as an option for protected branches. !5081
  - Improve performance of AutolinkFilter#text_parse by using XPath
  - Add experimental Redis Sentinel support !1877
  - Rendering of SVGs as blobs is now limited to SVGs with a size smaller or equal to 2MB
  - Fix branches page dropdown sort initial state (ClemMakesApps)
  - Environments have an url to link to
  - Various redundant database indexes have been removed
  - Update `timeago` plugin to use multiple string/locale settings
  - Remove unused images (ClemMakesApps)
  - Get issue and merge request description templates from repositories
  - Enforce 2FA restrictions on API authentication endpoints !5820
  - Limit git rev-list output count to one in forced push check
  - Show deployment status on merge requests with external URLs
  - Clean up unused routes (Josef Strzibny)
  - Fix issue on empty project to allow developers to only push to protected branches if given permission
  - API: Add enpoints for pipelines
  - Add green outline to New Branch button. !5447 (winniehell)
  - Optimize generating of cache keys for issues and notes
  - Fix repository push email formatting in Outlook
  - Improve performance of syntax highlighting Markdown code blocks
  - Update to gitlab_git 10.4.1 and take advantage of preserved Ref objects
  - Remove delay when hitting "Reply..." button on page with a lot of discussions
  - Retrieve rendered HTML from cache in one request
  - Fix renaming repository when name contains invalid chararacters under project settings
  - Upgrade Grape from 0.13.0 to 0.15.0. !4601
  - Trigram indexes for the "ci_runners" table have been removed to speed up UPDATE queries
  - Fix devise deprecation warnings.
  - Check for 2FA when using Git over HTTP and only allow PersonalAccessTokens as password in that case !5764
  - Update version_sorter and use new interface for faster tag sorting
  - Optimize checking if a user has read access to a list of issues !5370
  - Store all DB secrets in secrets.yml, under descriptive names !5274
  - Fix syntax highlighting in file editor
  - Support slash commands in issue and merge request descriptions as well as comments. !5021
  - Nokogiri's various parsing methods are now instrumented
  - Add archived badge to project list !5798
  - Add simple identifier to public SSH keys (muteor)
  - Admin page now references docs instead of a specific file !5600 (AnAverageHuman)
  - Fix filter input alignment (ClemMakesApps)
  - Include old revision in merge request update hooks (Ben Boeckel)
  - Add build event color in HipChat messages (David Eisner)
  - Make fork counter always clickable. !5463 (winniehell)
  - Document that webhook secret token is sent in X-Gitlab-Token HTTP header !5664 (lycoperdon)
  - Gitlab::Highlight is now instrumented
  - All created issues, API or WebUI, can be submitted to Akismet for spam check !5333
  - Allow users to import cross-repository pull requests from GitHub
  - The overhead of instrumented method calls has been reduced
  - Remove `search_id` of labels dropdown filter to fix 'Missleading URI for labels in Merge Requests and Issues view'. !5368 (Scott Le)
  - Load project invited groups and members eagerly in `ProjectTeam#fetch_members`
  - Add pipeline events hook
  - Bump gitlab_git to speedup DiffCollection iterations
  - Rewrite description of a blocked user in admin settings. (Elias Werberich)
  - Make branches sortable without push permission !5462 (winniehell)
  - Check for Ci::Build artifacts at database level on pipeline partial
  - Convert image diff background image to CSS (ClemMakesApps)
  - Remove unnecessary index_projects_on_builds_enabled index from the projects table
  - Make "New issue" button in Issue page less obtrusive !5457 (winniehell)
  - Gitlab::Metrics.current_transaction needs to be public for RailsQueueDuration
  - Fix search for notes which belongs to deleted objects
  - Allow Akismet to be trained by submitting issues as spam or ham !5538
  - Add GitLab Workhorse version to admin dashboard (Katarzyna Kobierska Ula Budziszewska)
  - Allow branch names ending with .json for graph and network page !5579 (winniehell)
  - Add the `sprockets-es6` gem
  - Improve OAuth2 client documentation (muteor)
  - Fix diff comments inverted toggle bug (ClemMakesApps)
  - Multiple trigger variables show in separate lines (Katarzyna Kobierska Ula Budziszewska)
  - Profile requests when a header is passed
  - Avoid calculation of line_code and position for _line partial when showing diff notes on discussion tab.
  - Speedup DiffNote#active? on discussions, preloading noteables and avoid touching git repository to return diff_refs when possible
  - Add commit stats in commit api. !5517 (dixpac)
  - Add CI configuration button on project page
  - Fix merge request new view not changing code view rendering style
  - edit_blob_link will use blob passed onto the options parameter
  - Make error pages responsive (Takuya Noguchi)
  - The performance of the project dropdown used for moving issues has been improved
  - Fix skip_repo parameter being ignored when destroying a namespace
  - Add all builds into stage/job dropdowns on builds page
  - Change requests_profiles resource constraint to catch virtually any file
  - Bump gitlab_git to lazy load compare commits
  - Reduce number of queries made for merge_requests/:id/diffs
  - Add the option to set the expiration date for the project membership when giving a user access to a project. !5599 (Adam Niedzielski)
  - Sensible state specific default sort order for issues and merge requests !5453 (tomb0y)
  - Fix bug where destroying a namespace would not always destroy projects
  - Fix RequestProfiler::Middleware error when code is reloaded in development
  - Allow horizontal scrolling of code blocks in issue body
  - Catch what warden might throw when profiling requests to re-throw it
  - Avoid commit lookup on diff_helper passing existing local variable to the helper method
  - Add description to new_issue email and new_merge_request_email in text/plain content type. !5663 (dixpac)
  - Speed up and reduce memory usage of Commit#repo_changes, Repository#expire_avatar_cache and IrkerWorker
  - Add unfold links for Side-by-Side view. !5415 (Tim Masliuchenko)
  - Adds support for pending invitation project members importing projects
  - Add pipeline visualization/graph on pipeline page
  - Update devise initializer to turn on changed password notification emails. !5648 (tombell)
  - Avoid to show the original password field when password is automatically set. !5712 (duduribeiro)
  - Fix importing GitLab projects with an invalid MR source project
  - Sort folders with submodules in Files view !5521
  - Each `File::exists?` replaced to `File::exist?` because of deprecate since ruby version 2.2.0
  - Add auto-completition in pipeline (Katarzyna Kobierska Ula Budziszewska)
  - Add pipelines tab to merge requests
  - Fix notification_service argument error of declined invitation emails
  - Fix a memory leak caused by Banzai::Filter::SanitizationFilter
  - Speed up todos queries by limiting the projects set we join with
  - Ensure file editing in UI does not overwrite committed changes without warning user
  - Eliminate unneeded calls to Repository#blob_at when listing commits with no path
  - Update gitlab_git gem to 10.4.7
  - Simplify SQL queries of marking a todo as done

## 8.10.13 (2016-11-02)

- Removes any symlinks before importing a project export file. CVE-2016-9086

## 8.10.12

  - Don't send Private-Token (API authentication) headers to Sentry
  - Share projects via the API only with groups the authenticated user can access

## 8.10.11

  - Respect the fork_project permission when forking projects
  - Set a restrictive CORS policy on the API for credentialed requests
  - API: disable rails session auth for non-GET/HEAD requests
  - Escape HTML nodes in builds commands in CI linter

## 8.10.10

  - Allow the Rails cookie to be used for API authentication.

## 8.10.9

  - Exclude some pending or inactivated rows in Member scopes

## 8.10.8

  - Fix information disclosure in issue boards.
  - Fix privilege escalation in project import.

## 8.10.7

  - Upgrade Hamlit to 2.6.1. !5873
  - Upgrade Doorkeeper to 4.2.0. !5881

## 8.10.6

  - Upgrade Rails to 4.2.7.1 for security fixes. !5781
  - Restore "Largest repository" sort option on Admin > Projects page. !5797
  - Fix privilege escalation via project export.
  - Require administrator privileges to perform a project import.

## 8.10.5

  - Add a data migration to fix some missing timestamps in the members table. !5670
  - Revert the "Defend against 'Host' header injection" change in the source NGINX templates. !5706
  - Cache project count for 5 minutes to reduce DB load. !5746 & !5754

## 8.10.4

  - Don't close referenced upstream issues from a forked project.
  - Fixes issue with dropdowns `enter` key not working correctly. !5544
  - Fix Import/Export project import not working in HA mode. !5618
  - Fix Import/Export error checking versions. !5638

## 8.10.3

  - Fix Import/Export issue importing milestones and labels not associated properly. !5426
  - Fix timing problems running imports on production. !5523
  - Add a log message when a project is scheduled for destruction for debugging. !5540
  - Fix hooks missing on imported GitLab projects. !5549
  - Properly abort a merge when merge conflicts occur. !5569
  - Fix importer for GitHub Pull Requests when a branch was removed. !5573
  - Ignore invalid IPs in X-Forwarded-For when trusted proxies are configured. !5584
  - Trim extra displayed carriage returns in diffs and files with CRLFs. !5588
  - Fix label already exist error message in the right sidebar.

## 8.10.2

  - User can now search branches by name. !5144
  - Page is now properly rendered after committing the first file and creating the first branch. !5399
  - Add branch or tag icon to ref in builds page. !5434
  - Fix backup restore. !5459
  - Use project ID in repository cache to prevent stale data from persisting across projects. !5460
  - Fix issue with autocomplete search not working with enter key. !5466
  - Add iid to MR API response. !5468
  - Disable MySQL foreign key checks before dropping all tables. !5472
  - Ensure relative paths for video are rewritten as we do for images. !5474
  - Ensure current user can retry a build before showing the 'Retry' button. !5476
  - Add ENV variable to skip repository storages validations. !5478
  - Added `*.js.es6 gitlab-language=javascript` to `.gitattributes`. !5486
  - Don't show comment button in gutter of diffs on MR discussion tab. !5493
  - Rescue Rugged::OSError (lock exists) when creating references. !5497
  - Fix expand all diffs button in compare view. !5500
  - Show release notes in tags list. !5503
  - Fix a bug where forking a project from a repository storage to another would fail. !5509
  - Fix missing schema update for `20160722221922`. !5512
  - Update `gitlab-shell` version to 3.2.1 in the 8.9->8.10 update guide. !5516

## 8.10.1

  - Refactor repository storages documentation. !5428
  - Gracefully handle case when keep-around references are corrupted or exist already. !5430
  - Add detailed info on storage path mountpoints. !5437
  - Fix Error 500 when creating Wiki pages with hyphens or spaces. !5444
  - Fix bug where replies to commit notes displayed in the MR discussion tab wouldn't show up on the commit page. !5446
  - Ignore invalid trusted proxies in X-Forwarded-For header. !5454
  - Add links to the real markdown.md file for all GFM examples. !5458

## 8.10.0 (2016-07-22)

  - Fix profile activity heatmap to show correct day name (eanplatter)
  - Speed up ExternalWikiHelper#get_project_wiki_path
  - Expose {should,force}_remove_source_branch (Ben Boeckel)
  - Add the functionality to be able to rename a file. !5049
  - Disable PostgreSQL statement timeout during migrations
  - Fix projects dropdown loading performance with a simplified api cal. !5113
  - Fix commit builds API, return all builds for all pipelines for given commit. !4849
  - Replace Haml with Hamlit to make view rendering faster. !3666
  - Refresh the branch cache after `git gc` runs
  - Allow to disable request access button on projects/groups
  - Refactor repository paths handling to allow multiple git mount points
  - Optimize system note visibility checking by memoizing the visible reference count. !5070
  - Add Application Setting to configure default Repository Path for new projects
  - Delete award emoji when deleting a user
  - Remove pinTo from Flash and make inline flash messages look nicer. !4854 (winniehell)
  - Add an API for downloading latest successful build from a particular branch or tag. !5347
  - Avoid data-integrity issue when cleaning up repository archive cache.
  - Add link to profile to commit avatar. !5163 (winniehell)
  - Wrap code blocks on Activies and Todos page. !4783 (winniehell)
  - Align flash messages with left side of page content. !4959 (winniehell)
  - Display tooltip for "Copy to Clipboard" button. !5164 (winniehell)
  - Use default cursor for table header of project files. !5165 (winniehell)
  - Store when and yaml variables in builds table
  - Display last commit of deleted branch in push events. !4699 (winniehell)
  - Escape file extension when parsing search results. !5141 (winniehell)
  - Add "passing with warnings" to the merge request pipeline possible statuses, this happens when builds that allow failures have failed. !5004
  - Add image border in Markdown preview. !5162 (winniehell)
  - Apply the trusted_proxies config to the rack request object for use with rack_attack
  - Added the ability to block sign ups using a domain blacklist. !5259
  - Upgrade to Rails 4.2.7. !5236
  - Extend exposed environment variables for CI builds
  - Deprecate APIs "projects/:id/keys/...". Use "projects/:id/deploy_keys/..." instead
  - Add API "deploy_keys" for admins to get all deploy keys
  - Allow to pull code with deploy key from public projects
  - Use limit parameter rather than hardcoded value in `ldap:check` rake task (Mike Ricketts)
  - Add Sidekiq queue duration to transaction metrics.
  - Add a new column `artifacts_size` to table `ci_builds`. !4964
  - Let Workhorse serve format-patch diffs
  - Display tooltip for mentioned users and groups. !5261 (winniehell)
  - Allow build email service to be tested
  - Added day name to contribution calendar tooltips
  - Refactor user authorization check for a single project to avoid querying all user projects
  - Make images fit to the size of the viewport. !4810
  - Fix check for New Branch button on Issue page. !4630 (winniehell)
  - Fix GFM autocomplete not working on wiki pages
  - Fixed enter key not triggering click on first row when searching in a dropdown
  - Updated dropdowns in issuable form to use new GitLab dropdown style
  - Make images fit to the size of the viewport !4810
  - Fix check for New Branch button on Issue page !4630 (winniehell)
  - Fix MR-auto-close text added to description. !4836
  - Support U2F devices in Firefox. !5177
  - Fix issue, preventing users w/o push access to sort tags. !5105 (redetection)
  - Add Spring EmojiOne updates.
  - Added Rake task for tracking deployments. !5320
  - Fix fetching LFS objects for private CI projects
  - Add the new 2016 Emoji! Adds 72 new emoji including bacon, facepalm, and selfie. !5237
  - Add syntax for multiline blockquote using `>>>` fence. !3954
  - Fix viewing notification settings when a project is pending deletion
  - Updated compare dropdown menus to use GL dropdown
  - Redirects back to issue after clicking login link
  - Eager load award emoji on notes
  - Allow to define manual actions/builds on Pipelines and Environments
  - Fix pagination when sorting by columns with lots of ties (like priority)
  - The Markdown reference parsers now re-use query results to prevent running the same queries multiple times. !5020
  - Updated project header design
  - Issuable collapsed assignee tooltip is now the users name
  - Fix compare view not changing code view rendering style
  - Exclude email check from the standard health check
  - Updated layout for Projects, Groups, Users on Admin area. !4424
  - Fix changing issue state columns in milestone view
  - Update health_check gem to version 2.1.0
  - Add notification settings dropdown for groups
  - Render inline diffs for multiple changed lines following eachother
  - Wildcards for protected branches. !4665
  - Allow importing from Github using Personal Access Tokens. (Eric K Idema)
  - API: Expose `due_date` for issues (Robert Schilling)
  - API: Todos. !3188 (Robert Schilling)
  - API: Expose shared groups for projects and shared projects for groups. !5050 (Robert Schilling)
  - API: Expose `developers_can_push` and `developers_can_merge` for branches. !5208 (Robert Schilling)
  - Add "Enabled Git access protocols" to Application Settings
  - Diffs will create button/diff form on demand no on server side
  - Reduce size of HTML used by diff comment forms
  - Protected branches have a "Developers can Merge" setting. !4892 (original implementation by Mathias Vestergaard)
  - Fix user creation with stronger minimum password requirements. !4054 (nathan-pmt)
  - Only show New Snippet button to users that can create snippets.
  - PipelinesFinder uses git cache data
  - Track a user who created a pipeline
  - Actually render old and new sections of parallel diff next to each other
  - Throttle the update of `project.pushes_since_gc` to 1 minute.
  - Allow expanding and collapsing files in diff view. !4990
  - Collapse large diffs by default (!4990)
  - Fix mentioned users list on diff notes
  - Add support for inline videos in GitLab Flavored Markdown. !5215 (original implementation by Eric Hayes)
  - Fix creation of deployment on build that is retried, redeployed or rollback
  - Don't parse Rinku returned value to DocFragment when it didn't change the original html string.
  - Check for conflicts with existing Project's wiki path when creating a new project.
  - Show last push widget in upstream after push to fork
  - Fix stage status shown for pipelines
  - Cache todos pending/done dashboard query counts.
  - Don't instantiate a git tree on Projects show default view
  - Bump Rinku to 2.0.0
  - Remove unused front-end variable -> default_issues_tracker
  - ObjectRenderer retrieve renderer content using Rails.cache.read_multi
  - Better caching of git calls on ProjectsController#show.
  - Avoid to retrieve MR closes_issues as much as possible.
  - Hide project name in project activities. !5068 (winniehell)
  - Add API endpoint for a group issues. !4520 (mahcsig)
  - Add Bugzilla integration. !4930 (iamtjg)
  - Fix new snippet style bug (elliotec)
  - Instrument Rinku usage
  - Be explicit to define merge request discussion variables
  - Use cache for todos counter calling TodoService
  - Metrics for Rouge::Plugins::Redcarpet and Rouge::Formatters::HTMLGitlab
  - RailsCache metris now includes fetch_hit/fetch_miss and read_hit/read_miss info.
  - Allow [ci skip] to be in any case and allow [skip ci]. !4785 (simon_w)
  - Made project list visibility icon fixed width
  - Set import_url validation to be more strict
  - Memoize MR merged/closed events retrieval
  - Don't render discussion notes when requesting diff tab through AJAX
  - Add basic system information like memory and disk usage to the admin panel
  - Don't garbage collect commits that have related DB records like comments
  - Allow to setup event by channel on slack service
  - More descriptive message for git hooks and file locks
  - Aliases of award emoji should be stored as original name. !5060 (dixpac)
  - Handle custom Git hook result in GitLab UI
  - Allow to access Container Registry for Public and Internal projects
  - Allow '?', or '&' for label names
  - Support redirected blobs for Container Registry integration
  - Fix importer for GitHub Pull Requests when a branch was reused across Pull Requests
  - Add date when user joined the team on the member page
  - Fix 404 redirect after validation fails importing a GitLab project
  - Added setting to set new users by default as external. !4545 (Dravere)
  - Add min value for project limit field on user's form. !3622 (jastkand)
  - Reset project pushes_since_gc when we enqueue the git gc call
  - Add reminder to not paste private SSH keys. !4399 (Ingo Blechschmidt)
  - Collapsed diffs lines/size don't acumulate to overflow diffs.
  - Remove duplicate `description` field in `MergeRequest` entities (Ben Boeckel)
  - Style of import project buttons were fixed in the new project page. !5183 (rdemirbay)
  - Fix GitHub client requests when rate limit is disabled
  - Optimistic locking for Issues and Merge Requests (Title and description overriding prevention)
  - Redesign Builds and Pipelines pages
  - Change status color and icon for running builds
  - Fix commenting issue in side by side diff view for unchanged lines
  - Fix markdown rendering for: consecutive labels references, label references that begin with a digit or contains `.`
  - Project export filename now includes the project and namespace path
  - Fix last update timestamp on issues not preserved on gitlab.com and project imports
  - Fix issues importing projects from EE to CE
  - Fix creating group with space in group path
  - Improve cron_jobs loading error messages. !5318 / !5360
  - Prevent toggling sidebar when clipboard icon clicked
  - Create Todos for Issue author when assign or mention himself (Katarzyna Kobierska)
  - Limit the number of retries on error to 3 for exporting projects
  - Allow empty repositories on project import/export
  - Render only commit message title in builds (Katarzyna Kobierska Ula Budziszewska)
  - Allow bulk (un)subscription from issues in issue index
  - Fix MR diff encoding issues exporting GitLab projects
  - Move builds settings out of project settings and rename Pipelines
  - Add builds badge to Pipelines settings page
  - Export and import avatar as part of project import/export
  - Fix migration corrupting import data for old version upgrades
  - Show tooltip on GitLab export link in new project page
  - Fix import_data wrongly saved as a result of an invalid import_url !5206

## 8.9.11

  - Respect the fork_project permission when forking projects
  - Set a restrictive CORS policy on the API for credentialed requests
  - API: disable rails session auth for non-GET/HEAD requests
  - Escape HTML nodes in builds commands in CI linter

## 8.9.10

  - Allow the Rails cookie to be used for API authentication.

## 8.9.9

  - Exclude some pending or inactivated rows in Member scopes

## 8.9.8

  - Upgrade Doorkeeper to 4.2.0. !5881

## 8.9.7

  - Upgrade Rails to 4.2.7.1 for security fixes. !5781
  - Require administrator privileges to perform a project import.

## 8.9.6

  - Fix importing of events under notes for GitLab projects. !5154
  - Fix log statements in import/export. !5129
  - Fix commit avatar alignment in compare view. !5128
  - Fix broken migration in MySQL. !5005
  - Overwrite Host and X-Forwarded-Host headers in NGINX !5213
  - Keeps issue number when importing from GitLab.com
  - Add Pending tab for Builds (Katarzyna Kobierska, Urszula Budziszewska)

## 8.9.5

  - Add more debug info to import/export and memory killer. !5108
  - Fixed avatar alignment in new MR view. !5095
  - Fix diff comments not showing up in activity feed. !5069
  - Add index on both Award Emoji user and name. !5061
  - Downgrade to Redis 3.2.2 due to massive memory leak with Sidekiq. !5056
  - Re-enable import button when import process fails due to namespace already being taken. !5053
  - Fix snippets comments not displayed. !5045
  - Fix emoji paths in relative root configurations. !5027
  - Fix issues importing events in Import/Export. !4987
  - Fixed 'use shortcuts' button on docs. !4979
  - Admin should be able to turn shared runners into specific ones. !4961
  - Update RedCloth to 4.3.2 for CVE-2012-6684. !4929 (Takuya Noguchi)
  - Improve the request / withdraw access button. !4860

## 8.9.4

  - Fix privilege escalation issue with OAuth external users.
  - Ensure references to private repos aren't shown to logged-out users.
  - Fixed search field blur not removing focus. !4704
  - Resolve "Sub nav isn't showing on file view". !4890
  - Fixes middle click and double request when navigating through the file browser. !4891
  - Fixed URL on label button when filtering. !4897
  - Fixed commit avatar alignment. !4933
  - Do not show build retry link when build is active. !4967
  - Fix restore Rake task warning message output. !4980
  - Handle external issues in IssueReferenceFilter. !4988
  - Expiry date on pinned nav cookie. !5009
  - Updated breakpoint for sidebar pinning. !5019

## 8.9.3

  - Fix encrypted data backwards compatibility after upgrading attr_encrypted gem. !4963
  - Fix rendering of commit notes. !4953
  - Resolve "Pin should show up at 1280px min". !4947
  - Switched mobile button icons to ellipsis and angle. !4944
  - Correctly returns todo ID after creating todo. !4941
  - Better debugging for memory killer middleware. !4936
  - Remove duplicate new page btn from edit wiki. !4904
  - Use clock_gettime for all performance timestamps. !4899
  - Use memorized tags array when searching tags by name. !4859
  - Fixed avatar alignment in new MR view. !4901
  - Removed fade when filtering results. !4932
  - Fix missing avatar on system notes. !4954
  - Reduce overhead and optimize ProjectTeam#max_member_access performance. !4973
  - Use update_columns to bypass all the dirty code on active_record. !4985
  - Fix restore Rake task warning message output !4980

## 8.9.2

  - Fix visibility of snippets when searching.
  - Fix an information disclosure when requesting access to a group containing private projects.
  - Update omniauth-saml to 1.6.0 !4951

## 8.9.1

  - Refactor labels documentation. !3347
  - Eager load award emoji on notes. !4628
  - Fix some CI wording in documentation. !4660
  - Document `GIT_STRATEGY` and `GIT_DEPTH`. !4720
  - Add documentation for the export & import features. !4732
  - Add some docs for Docker Registry configuration. !4738
  - Ensure we don't send the "access request declined" email to access requesters on project deletion. !4744
  - Display group/project access requesters separately in the admin area. !4798
  - Add documentation and examples for configuring cloud storage for registry images. !4812
  - Clarifies documentation about artifact expiry. !4831
  - Fix the Network graph links. !4832
  - Fix MR-auto-close text added to description. !4836
  - Add documentation for award emoji now that comments can be awarded with emojis. !4839
  - Fix typo in export failure email. !4847
  - Fix header vertical centering. !4170
  - Fix subsequent SAML sign ins. !4718
  - Set button label when picking an option from status dropdown. !4771
  - Prevent invalid URLs from raising exceptions in WikiLink Filter. !4775
  - Handle external issues in IssueReferenceFilter. !4789
  - Support for rendering/redacting multiple documents. !4828
  - Update Todos documentation and screenshots to include new functionality. !4840
  - Hide nav arrows by default. !4843
  - Added bottom padding to label color suggestion link. !4845
  - Use jQuery objects in ref dropdown. !4850
  - Fix GitLab project import issues related to notes and builds. !4855
  - Restrict header logo to 36px so it doesn't overflow. !4861
  - Fix unwanted label unassignment. !4863
  - Fix mobile Safari bug where horizontal nav arrows would flicker on scroll. !4869
  - Restore old behavior around diff notes to outdated discussions. !4870
  - Fix merge requests project settings help link anchor. !4873
  - Fix 404 when accessing pipelines as guest user on public projects. !4881
  - Remove width restriction for logo on sign-in page. !4888
  - Bump gitlab_git to 10.2.3 to fix false truncated warnings with ISO-8559 files. !4884
  - Apply selected value as label. !4886
  - Change Retry to Re-deploy on Deployments page
  - Fix temp file being deleted after the request while importing a GitLab project. !4894
  - Fix pagination when sorting by columns with lots of ties (like priority)
  - Implement Subresource Integrity for CSS and JavaScript assets. This prevents malicious assets from loading in the case of a CDN compromise.
  - Fix user creation with stronger minimum password requirements !4054 (nathan-pmt)
  - Fix a wrong MR status when merge_when_build_succeeds & project.only_allow_merge_if_build_succeeds are true. !4912
  - Add SMTP as default delivery method to match gitlab-org/omnibus-gitlab!826. !4915
  - Remove duplicate 'New Page' button on edit wiki page

## 8.9.0 (2016-06-22)

  - Fix group visibility form layout in application settings
  - Fix builds API response not including commit data
  - Fix error when CI job variables key specified but not defined
  - Fix pipeline status when there are no builds in pipeline
  - Fix Error 500 when using closes_issues API with an external issue tracker
  - Add more information into RSS feed for issues (Alexander Matyushentsev)
  - Bulk assign/unassign labels to issues.
  - Ability to prioritize labels !4009 / !3205 (Thijs Wouters)
  - Show Star and Fork buttons on mobile.
  - Performance improvements on RelativeLinkFilter
  - Fix endless redirections when accessing user OAuth applications when they are disabled
  - Allow enabling wiki page events from Webhook management UI
  - Bump rouge to 1.11.0
  - Fix issue with arrow keys not working in search autocomplete dropdown
  - Fix an issue where note polling stopped working if a window was in the
    background during a refresh.
  - Pre-processing Markdown now only happens when needed
  - Make EmailsOnPushWorker use Sidekiq mailers queue
  - Redesign all Devise emails. !4297
  - Don't show 'Leave Project' to group members
  - Fix wiki page events' webhook to point to the wiki repository
  - Add a border around images to differentiate them from the background.
  - Don't show tags for revert and cherry-pick operations
  - Show image ID on registry page
  - Fix issue todo not remove when leave project !4150 (Long Nguyen)
  - Allow customisable text on the 'nearly there' page after a user signs up
  - Bump recaptcha gem to 3.0.0 to remove deprecated stoken support
  - Fix SVG sanitizer to allow more elements
  - Allow forking projects with restricted visibility level
  - Added descriptions to notification settings dropdown
  - Improve note validation to prevent errors when creating invalid note via API
  - Reduce number of fog gem dependencies
  - Add number of merge requests for a given milestone to the milestones view.
  - Implement a fair usage of shared runners
  - Remove project notification settings associated with deleted projects
  - Fix 404 page when viewing TODOs that contain milestones or labels in different projects
  - Add a metric for the number of new Redis connections created by a transaction
  - Fix Error 500 when viewing a blob with binary characters after the 1024-byte mark
  - Redesign navigation for project pages
  - Fix images in sign-up confirmation email
  - Added shortcut 'y' for copying a files content hash URL #14470
  - Fix groups API to list only user's accessible projects
  - Fix horizontal scrollbar for long commit message.
  - GitLab Performance Monitoring now tracks the total method execution time and call count per method
  - Add Environments and Deployments
  - Redesign account and email confirmation emails
  - Don't fail builds for projects that are deleted
  - Support Docker Registry manifest v1
  - `git clone https://host/namespace/project` now works, in addition to using the `.git` suffix
  - Bump nokogiri to 1.6.8
  - Use gitlab-shell v3.0.0
  - Fixed alignment of download dropdown in merge requests
  - Upgrade to jQuery 2
  - Adds selected branch name to the dropdown toggle
  - Add API endpoint for Sidekiq Metrics !4653
  - Refactoring Award Emoji with API support for Issues and MergeRequests
  - Use Knapsack to evenly distribute tests across multiple nodes
  - Add `sha` parameter to MR merge API, to ensure only reviewed changes are merged
  - Don't allow MRs to be merged when commits were added since the last review / page load
  - Add DB index on users.state
  - Limit email on push diff size to 30 files / 150 KB
  - Add rake task 'gitlab:db:configure' for conditionally seeding or migrating the database
  - Changed the Slack build message to use the singular duration if necessary (Aran Koning)
  - Fix race condition on merge when build succeeds
  - Added shortcut to focus filter search fields and added documentation #18120
  - Links from a wiki page to other wiki pages should be rewritten as expected
  - Add option to project to only allow merge requests to be merged if the build succeeds (Rui Santos)
  - Added navigation shortcuts to the project pipelines, milestones, builds and forks page. !4393
  - Fix issues filter when ordering by milestone
  - Disable SAML account unlink feature
  - Added artifacts:when to .gitlab-ci.yml - this requires GitLab Runner 1.3
  - Bamboo Service: Fix missing credentials & URL handling when base URL contains a path (Benjamin Schmid)
  - TeamCity Service: Fix URL handling when base URL contains a path
  - Todos will display target state if issuable target is 'Closed' or 'Merged'
  - Validate only and except regexp
  - Fix bug when sorting issues by milestone due date and filtering by two or more labels
  - POST to API /projects/:id/runners/:runner_id would give 409 if the runner was already enabled for this project
  - Add support for using Yubikeys (U2F) for two-factor authentication
  - Link to blank group icon doesn't throw a 404 anymore
  - Remove 'main language' feature
  - Toggle whitespace button now available for compare branches diffs #17881
  - Pipelines can be canceled only when there are running builds
  - Allow authentication using personal access tokens
  - Use downcased path to container repository as this is expected path by Docker
  - Allow to use CI token to fetch LFS objects
  - Custom notification settings
  - Projects pending deletion will render a 404 page
  - Measure queue duration between gitlab-workhorse and Rails
  - Added Gfm autocomplete for labels
  - Added edit note 'up' shortcut documentation to the help panel and docs screenshot #18114
  - Make Omniauth providers specs to not modify global configuration
  - Remove unused JiraIssue class and replace references with ExternalIssue. !4659 (Ilan Shamir)
  - Make authentication service for Container Registry to be compatible with < Docker 1.11
  - Make it possible to lock a runner from being enabled for other projects
  - Add Application Setting to configure Container Registry token expire delay (default 5min)
  - Cache assigned issue and merge request counts in sidebar nav
  - Use Knapsack only in CI environment
  - Updated project creation page to match new UI #2542
  - Cache project build count in sidebar nav
  - Add milestone expire date to the right sidebar
  - Manually mark a issue or merge request as a todo
  - Fix markdown_spec to use before instead of before(:all) to properly cleanup database after testing
  - Reduce number of queries needed to render issue labels in the sidebar
  - Improve error handling importing projects
  - Remove duplicated notification settings
  - Put project Files and Commits tabs under Code tab
  - Decouple global notification level from user model
  - Replace Colorize with Rainbow for coloring console output in Rake tasks.
  - Add workhorse controller and API helpers
  - An indicator is now displayed at the top of the comment field for confidential issues.
  - Show categorised search queries in the search autocomplete
  - RepositoryCheck::SingleRepositoryWorker public and private methods are now instrumented
  - Dropdown for `.gitlab-ci.yml` templates
  - Improve issuables APIs performance when accessing notes !4471
  - Add sorting dropdown to tags page !4423
  - External links now open in a new tab
  - Prevent default actions of disabled buttons and links
  - Markdown editor now correctly resets the input value on edit cancellation !4175
  - Toggling a task list item in a issue/mr description does not creates a Todo for mentions
  - Improved UX of date pickers on issue & milestone forms
  - Cache on the database if a project has an active external issue tracker.
  - Put project Labels and Milestones pages links under Issues and Merge Requests tabs as subnav
  - GitLab project import and export functionality
  - All classes in the Banzai::ReferenceParser namespace are now instrumented
  - Remove deprecated issues_tracker and issues_tracker_id from project model
  - Allow users to create confidential issues in private projects
  - Measure CPU time for instrumented methods
  - Instrument private methods and private instance methods by default instead just public methods
  - Only show notes through JSON on confidential issues that the user has access to
  - Updated the allocations Gem to version 1.0.5
  - The background sampler now ignores classes without names
  - Update design for `Close` buttons
  - New custom icons for navigation
  - Horizontally scrolling navigation on project, group, and profile settings pages
  - Hide global side navigation by default
  - Fix project Star/Unstar project button tooltip
  - Remove tanuki logo from side navigation; center on top nav
  - Include user relationships when retrieving award_emoji
  - Various associations are now eager loaded when parsing issue references to reduce the number of queries executed
  - Set inverse_of for Project/Service association to reduce the number of queries
  - Update tanuki logo highlight/loading colors
  - Remove explicit Gitlab::Metrics.action assignments, are already automatic.
  - Use Git cached counters for branches and tags on project page
  - Cache participable participants in an instance variable.
  - Filter parameters for request_uri value on instrumented transactions.
  - Remove duplicated keys add UNIQUE index to keys fingerprint column
  - ExtractsPath get ref_names from repository cache, if not there access git.
  - Show a flash warning about the error detail of XHR requests which failed with status code 404 and 500
  - Cache user todo counts from TodoService
  - Ensure Todos counters doesn't count Todos for projects pending delete
  - Add left/right arrows horizontal navigation
  - Add tooltip to pin/unpin navbar
  - Add new sub nav style to Wiki and Graphs sub navigation

## 8.8.9

  - Upgrade Doorkeeper to 4.2.0. !5881

## 8.8.8

  - Upgrade Rails to 4.2.7.1 for security fixes. !5781

## 8.8.7

  - Fix privilege escalation issue with OAuth external users.
  - Ensure references to private repos aren't shown to logged-out users.

## 8.8.6

  - Fix visibility of snippets when searching.
  - Update omniauth-saml to 1.6.0 !4951

## 8.8.5

  - Import GitHub repositories respecting the API rate limit !4166
  - Fix todos page throwing errors when you have a project pending deletion !4300
  - Disable Webhooks before proceeding with the GitHub import !4470
  - Fix importer for GitHub comments on diff !4488
  - Adjust the SAML control flow to allow LDAP identities to be added to an existing SAML user !4498
  - Fix incremental trace upload API when using multi-byte UTF-8 chars in trace !4541
  - Prevent unauthorized access for projects build traces
  - Forbid scripting for wiki files
  - Only show notes through JSON on confidential issues that the user has access to
  - Banzai::Filter::UploadLinkFilter use XPath instead CSS expressions
  - Banzai::Filter::ExternalLinkFilter use XPath instead CSS expressions

## 8.8.4

  - Fix LDAP-based login for users with 2FA enabled. !4493
  - Added descriptions to notification settings dropdown
  - Due date can be removed from milestones

## 8.8.3

  - Fix 404 page when viewing TODOs that contain milestones or labels in different projects. !4312
  - Fixed JS error when trying to remove discussion form. !4303
  - Fixed issue with button color when no CI enabled. !4287
  - Fixed potential issue with 2 CI status polling events happening. !3869
  - Improve design of Pipeline view. !4230
  - Fix gitlab importer failing to import new projects due to missing credentials. !4301
  - Fix import URL migration not rescuing with the correct Error. !4321
  - Fix health check access token changing due to old application settings being used. !4332
  - Make authentication service for Container Registry to be compatible with Docker versions before 1.11. !4363
  - Add Application Setting to configure Container Registry token expire delay (default 5 min). !4364
  - Pass the "Remember me" value to the 2FA token form. !4369
  - Fix incorrect links on pipeline page when merge request created from fork.  !4376
  - Use downcased path to container repository as this is expected path by Docker. !4420
  - Fix wiki project clone address error (chujinjin). !4429
  - Fix serious performance bug with rendering Markdown with InlineDiffFilter.  !4392
  - Fix missing number on generated ordered list element. !4437
  - Prevent disclosure of notes on confidential issues in search results.

## 8.8.2

  - Added remove due date button. !4209
  - Fix Error 500 when accessing application settings due to nil disabled OAuth sign-in sources. !4242
  - Fix Error 500 in CI charts by gracefully handling commits with no durations. !4245
  - Fix table UI on CI builds page. !4249
  - Fix backups if registry is disabled. !4263
  - Fixed issue with merge button color. !4211
  - Fixed issue with enter key selecting wrong option in dropdown. !4210
  - When creating a .gitignore file a dropdown with templates will be provided. !4075
  - Fix concurrent request when updating build log in browser. !4183

## 8.8.1

  - Add documentation for the "Health Check" feature
  - Allow anonymous users to access a public project's pipelines !4233
  - Fix MySQL compatibility in zero downtime migrations helpers
  - Fix the CI login to Container Registry (the gitlab-ci-token user)

## 8.8.0 (2016-05-22)

  - Implement GFM references for milestones (Alejandro Rodríguez)
  - Snippets tab under user profile. !4001 (Long Nguyen)
  - Fix error when using link to uploads in global snippets
  - Fix Error 500 when attempting to retrieve project license when HEAD points to non-existent ref
  - Assign labels and milestone to target project when moving issue. !3934 (Long Nguyen)
  - Use a case-insensitive comparison in sanitizing URI schemes
  - Toggle sign-up confirmation emails in application settings
  - Make it possible to prevent tagged runner from picking untagged jobs
  - Added `InlineDiffFilter` to the markdown parser. (Adam Butler)
  - Added inline diff styling for `change_title` system notes. (Adam Butler)
  - Project#open_branches has been cleaned up and no longer loads entire records into memory.
  - Escape HTML in commit titles in system note messages
  - Improve design of Pipeline View
  - Fix scope used when accessing container registry
  - Fix creation of Ci::Commit object which can lead to pending, failed in some scenarios
  - Improve multiple branch push performance by memoizing permission checking
  - Log to application.log when an admin starts and stops impersonating a user
  - Changing the confidentiality of an issue now creates a new system note (Alex Moore-Niemi)
  - Updated gitlab_git to 10.1.0
  - GitAccess#protected_tag? no longer loads all tags just to check if a single one exists
  - Reduce delay in destroying a project from 1-minute to immediately
  - Make build status canceled if any of the jobs was canceled and none failed
  - Upgrade Sidekiq to 4.1.2
  - Added /health_check endpoint for checking service status
  - Make 'upcoming' filter for milestones work better across projects
  - Sanitize repo paths in new project error message
  - Bump mail_room to 0.7.0 to fix stuck IDLE connections
  - Remove future dates from contribution calendar graph.
  - Support e-mail notifications for comments on project snippets
  - Fix API leak of notes of unauthorized issues, snippets and merge requests
  - Use ActionDispatch Remote IP for Akismet checking
  - Fix error when visiting commit builds page before build was updated
  - Add 'l' shortcut to open Label dropdown on issuables and 'i' to create new issue on a project
  - Update SVG sanitizer to conform to SVG 1.1
  - Speed up push emails with multiple recipients by only generating the email once
  - Updated search UI
  - Added authentication service for Container Registry
  - Display informative message when new milestone is created
  - Sanitize milestones and labels titles
  - Support multi-line tag messages. !3833 (Calin Seciu)
  - Force users to reset their password after an admin changes it
  - Allow "NEWS" and "CHANGES" as alternative names for CHANGELOG. !3768 (Connor Shea)
  - Added button to toggle whitespaces changes on diff view
  - Backport GitHub Enterprise import support from EE
  - Create tags using Rugged for performance reasons. !3745
  - Allow guests to set notification level in projects
  - API: Expose Issue#user_notes_count. !3126 (Anton Popov)
  - Don't show forks button when user can't view forks
  - Fix atom feed links and rendering
  - Files over 5MB can only be viewed in their raw form, files over 1MB without highlighting !3718
  - Add support for suppressing text diffs using .gitattributes on the default branch (Matt Oakes)
  - Add eager load paths to help prevent dependency load issues in Sidekiq workers. !3724
  - Added multiple colors for labels in dropdowns when dups happen.
  - Show commits in the same order as `git log`
  - Improve description for the Two-factor Authentication sign-in screen. (Connor Shea)
  - API support for the 'since' and 'until' operators on commit requests (Paco Guzman)
  - Fix Gravatar hint in user profile when Gravatar is disabled. !3988 (Artem Sidorenko)
  - Expire repository exists? and has_visible_content? caches after a push if necessary
  - Fix unintentional filtering bug in Issue/MR sorted by milestone due (Takuya Noguchi)
  - Fix adding a todo for private group members (Ahmad Sherif)
  - Bump ace-rails-ap gem version from 2.0.1 to 4.0.2 which upgrades Ace Editor from 1.1.2 to 1.2.3
  - Total method execution timings are no longer tracked
  - Allow Admins to remove the Login with buttons for OAuth services and still be able to import !4034. (Andrei Gliga)
  - Add API endpoints for un/subscribing from/to a label. !4051 (Ahmad Sherif)
  - Hide left sidebar on phone screens to give more space for content
  - Redesign navigation for profile and group pages
  - Add counter metrics for rails cache
  - Import pull requests from GitHub where the source or target branches were removed
  - All Grape API helpers are now instrumented
  - Improve Issue formatting for the Slack Service (Jeroen van Baarsen)
  - Fixed advice on invalid permissions on upload path !2948 (Ludovic Perrine)
  - Allows MR authors to have the source branch removed when merging the MR. !2801 (Jeroen Jacobs)
  - When creating a .gitignore file a dropdown with templates will be provided
  - Shows the issue/MR list search/filter form and corrects the mobile styling for guest users. #17562

## 8.7.9

  - Fix privilege escalation issue with OAuth external users.
  - Ensure references to private repos aren't shown to logged-out users.

## 8.7.8

  - Fix visibility of snippets when searching.
  - Update omniauth-saml to 1.6.0 !4951

## 8.7.7

  - Fix import by `Any Git URL` broken if the URL contains a space
  - Prevent unauthorized access to other projects build traces
  - Forbid scripting for wiki files
  - Only show notes through JSON on confidential issues that the user has access to

## 8.7.6

  - Fix links on wiki pages for relative url setups. !4131 (Artem Sidorenko)
  - Fix import from GitLab.com to a private instance failure. !4181
  - Fix external imports not finding the import data. !4106
  - Fix notification delay when changing status of an issue
  - Bump Workhorse to 0.7.5 so it can serve raw diffs

## 8.7.5

  - Fix relative links in wiki pages. !4050
  - Fix always showing build notification message when switching between merge requests !4086
  - Fix an issue when filtering merge requests with more than one label. !3886
  - Fix short note for the default scope on build page (Takuya Noguchi)

## 8.7.4

  - Links for Redmine issue references are generated correctly again !4048 (Benedikt Huss)
  - Fix setting trusted proxies !3970
  - Fix BitBucket importer bug when throwing exceptions !3941
  - Use sign out path only if not empty !3989
  - Running rake gitlab:db:drop_tables now drops tables with cascade !4020
  - Running rake gitlab:db:drop_tables uses "IF EXISTS" as a precaution !4100
  - Use a case-insensitive comparison in sanitizing URI schemes

## 8.7.3

  - Emails, Gitlab::Email::Message, Gitlab::Diff, and Premailer::Adapter::Nokogiri are now instrumented
  - Merge request widget displays TeamCity build state and code coverage correctly again.
  - Fix the line code when importing PR review comments from GitHub. !4010
  - Wikis are now initialized on legacy projects when checking repositories
  - Remove animate.css in favor of a smaller subset of animations. !3937 (Connor Shea)

## 8.7.2

  - The "New Branch" button is now loaded asynchronously
  - Fix error 500 when trying to create a wiki page
  - Updated spacing between notification label and button
  - Label titles in filters are now escaped properly

## 8.7.1

  - Throttle the update of `project.last_activity_at` to 1 minute. !3848
  - Fix .gitlab-ci.yml parsing issue when hidde job is a template without script definition. !3849
  - Fix license detection to detect all license files, not only known licenses. !3878
  - Use the `can?` helper instead of `current_user.can?`. !3882
  - Prevent users from deleting Webhooks via API they do not own
  - Fix Error 500 due to stale cache when projects are renamed or transferred
  - Update width of search box to fix Safari bug. !3900 (Jedidiah)
  - Use the `can?` helper instead of `current_user.can?`

## 8.7.0 (2016-04-22)

  - Gitlab::GitAccess and Gitlab::GitAccessWiki are now instrumented
  - Fix vulnerability that made it possible to gain access to private labels and milestones
  - The number of InfluxDB points stored per UDP packet can now be configured
  - Fix error when cross-project label reference used with non-existent project
  - Transactions for /internal/allowed now have an "action" tag set
  - Method instrumentation now uses Module#prepend instead of aliasing methods
  - Repository.clean_old_archives is now instrumented
  - Add support for environment variables on a job level in CI configuration file
  - SQL query counts are now tracked per transaction
  - The Projects::HousekeepingService class has extra instrumentation
  - All service classes (those residing in app/services) are now instrumented
  - Developers can now add custom tags to transactions
  - Loading of an issue's referenced merge requests and related branches is now done asynchronously
  - Enable gzip for assets, makes the page size significantly smaller. !3544 / !3632 (Connor Shea)
  - Add support to cherry-pick any commit into any branch in the web interface (Minqi Pan)
  - Project switcher uses new dropdown styling
  - Load award emoji images separately unless opening the full picker. Saves several hundred KBs of data for most pages. (Connor Shea)
  - Do not include award_emojis in issue and merge_request comment_count !3610 (Lucas Charles)
  - Restrict user profiles when public visibility level is restricted.
  - Add ability set due date to issues, sort and filter issues by due date (Mehmet Beydogan)
  - All images in discussions and wikis now link to their source files !3464 (Connor Shea).
  - Return status code 303 after a branch DELETE operation to avoid project deletion (Stan Hu)
  - Add setting for customizing the list of trusted proxies !3524
  - Allow projects to be transferred to a lower visibility level group
  - Fix `signed_in_ip` being set to 127.0.0.1 when using a reverse proxy !3524
  - Improved Markdown rendering performance !3389
  - Make shared runners text in box configurable
  - Don't attempt to look up an avatar in repo if repo directory does not exist (Stan Hu)
  - API: Ability to subscribe and unsubscribe from issues and merge requests (Robert Schilling)
  - Expose project badges in project settings
  - Make /profile/keys/new redirect to /profile/keys for back-compat. !3717
  - Preserve time notes/comments have been updated at when moving issue
  - Make HTTP(s) label consistent on clone bar (Stan Hu)
  - Add support for `after_script`, requires Runner 1.2 (Kamil Trzciński)
  - Expose label description in API (Mariusz Jachimowicz)
  - API: Ability to update a group (Robert Schilling)
  - API: Ability to move issues (Robert Schilling)
  - Fix Error 500 after renaming a project path (Stan Hu)
  - Fix a bug with trailing slash in teamcity_url (Charles May)
  - Allow back dating on issues when created or updated through the API
  - Allow back dating on issue notes when created through the API
  - Propose license template when creating a new LICENSE file
  - API: Expose /licenses and /licenses/:key
  - Fix avatar stretching by providing a cropping feature
  - API: Expose `subscribed` for issues and merge requests (Robert Schilling)
  - Allow SAML to handle external users based on user's information !3530
  - Allow Omniauth providers to be marked as `external` !3657
  - Add endpoints to archive or unarchive a project !3372
  - Fix a bug with trailing slash in bamboo_url
  - Add links to CI setup documentation from project settings and builds pages
  - Display project members page to all members
  - Handle nil descriptions in Slack issue messages (Stan Hu)
  - Add automated repository integrity checks (OFF by default)
  - API: Expose open_issues_count, closed_issues_count, open_merge_requests_count for labels (Robert Schilling)
  - API: Ability to star and unstar a project (Robert Schilling)
  - Add default scope to projects to exclude projects pending deletion
  - Allow to close merge requests which source projects(forks) are deleted.
  - Ensure empty recipients are rejected in BuildsEmailService
  - Use rugged to change HEAD in Project#change_head (P.S.V.R)
  - API: Ability to filter milestones by state `active` and `closed` (Robert Schilling)
  - API: Fix milestone filtering by `iid` (Robert Schilling)
  - Make before_script and after_script overridable on per-job (Kamil Trzciński)
  - API: Delete notes of issues, snippets, and merge requests (Robert Schilling)
  - Implement 'Groups View' as an option for dashboard preferences !3379 (Elias W.)
  - Better errors handling when creating milestones inside groups
  - Fix high CPU usage when PostReceive receives refs/merge-requests/<id>
  - Hide `Create a group` help block when creating a new project in a group
  - Implement 'TODOs View' as an option for dashboard preferences !3379 (Elias W.)
  - Allow issues and merge requests to be assigned to the author !2765
  - Make Ci::Commit to group only similar builds and make it stateful (ref, tag)
  - Gracefully handle notes on deleted commits in merge requests (Stan Hu)
  - Decouple membership and notifications
  - Fix creation of merge requests for orphaned branches (Stan Hu)
  - API: Ability to retrieve a single tag (Robert Schilling)
  - While signing up, don't persist the user password across form redisplays
  - Fall back to `In-Reply-To` and `References` headers when sub-addressing is not available (David Padilla)
  - Remove "Congratulations!" tweet button on newly-created project. (Connor Shea)
  - Fix admin/projects when using visibility levels on search (PotHix)
  - Build status notifications
  - Update email confirmation interface
  - API: Expose user location (Robert Schilling)
  - API: Do not leak group existence via return code (Robert Schilling)
  - ClosingIssueExtractor regex now also works with colons. e.g. "Fixes: #1234" !3591
  - Update number of Todos in the sidebar when it's marked as "Done". !3600
  - Sanitize branch names created for confidential issues
  - API: Expose 'updated_at' for issue, snippet, and merge request notes (Robert Schilling)
  - API: User can leave a project through the API when not master or owner. !3613
  - Fix repository cache invalidation issue when project is recreated with an empty repo (Stan Hu)
  - Fix: Allow empty recipients list for builds emails service when pushed is added (Frank Groeneveld)
  - Improved markdown forms
  - Diff design updates (colors, button styles, etc)
  - Copying and pasting a diff no longer pastes the line numbers or +/-
  - Add null check to formData when updating profile content to fix Firefox bug
  - Disable spellcheck and autocorrect for username field in admin page
  - Delete tags using Rugged for performance reasons (Robert Schilling)
  - Add Slack notifications when Wiki is edited (Sebastian Klier)
  - Diffs load at the correct point when linking from number
  - Selected diff rows highlight
  - Fix emoji categories in the emoji picker
  - API: Properly display annotated tags for GET /projects/:id/repository/tags (Robert Schilling)
  - Add encrypted credentials for imported projects and migrate old ones
  - Properly format all merge request references with ! rather than # !3740 (Ben Bodenmiller)
  - Author and participants are displayed first on users autocompletion
  - Show number sign on external issue reference text (Florent Baldino)
  - Updated print style for issues
  - Use GitHub Issue/PR number as iid to keep references
  - Import GitHub labels
  - Add option to filter by "Owned projects" on dashboard page
  - Import GitHub milestones
  - Execute system web hooks on push to the project
  - Allow enable/disable push events for system hooks
  - Fix GitHub project's link in the import page when provider has a custom URL
  - Add RAW build trace output and button on build page
  - Add incremental build trace update into CI API

## 8.6.9

  - Prevent unauthorized access to other projects build traces
  - Forbid scripting for wiki files
  - Only show notes through JSON on confidential issues that the user has access to

## 8.6.8

  - Prevent privilege escalation via "impersonate" feature
  - Prevent privilege escalation via notes API
  - Prevent privilege escalation via project webhook API
  - Prevent XSS via Git branch and tag names
  - Prevent XSS via custom issue tracker URL
  - Prevent XSS via `window.opener`
  - Prevent XSS via label drop-down
  - Prevent information disclosure via milestone API
  - Prevent information disclosure via snippet API
  - Prevent information disclosure via project labels
  - Prevent information disclosure via new merge request page

## 8.6.7

  - Fix persistent XSS vulnerability in `commit_person_link` helper
  - Fix persistent XSS vulnerability in Label and Milestone dropdowns
  - Fix vulnerability that made it possible to enumerate private projects belonging to group

## 8.6.6

  - Expire the exists cache before deletion to ensure project dir actually exists (Stan Hu). !3413
  - Fix error on language detection when repository has no HEAD (e.g., master branch) (Jeroen Bobbeldijk). !3654
  - Fix revoking of authorized OAuth applications (Connor Shea). !3690
  - Fix error on language detection when repository has no HEAD (e.g., master branch). !3654 (Jeroen Bobbeldijk)
  - Issuable header is consistent between issues and merge requests
  - Improved spacing in issuable header on mobile

## 8.6.5

  - Fix importing from GitHub Enterprise. !3529
  - Perform the language detection after updating merge requests in `GitPushService`, leading to faster visual feedback for the end-user. !3533
  - Check permissions when user attempts to import members from another project. !3535
  - Only update repository language if it is not set to improve performance. !3556
  - Return status code 303 after a branch DELETE operation to avoid project deletion (Stan Hu). !3583
  - Unblock user when active_directory is disabled and it can be found !3550
  - Fix a 2FA authentication spoofing vulnerability.

## 8.6.4

  - Don't attempt to fetch any tags from a forked repo (Stan Hu)
  - Redesign the Labels page

## 8.6.3

  - Mentions on confidential issues doesn't create todos for non-members. !3374
  - Destroy related todos when an Issue/MR is deleted. !3376
  - Fix error 500 when target is nil on todo list. !3376
  - Fix copying uploads when moving issue to another project. !3382
  - Ensuring Merge Request API returns boolean values for work_in_progress (Abhi Rao). !3432
  - Fix raw/rendered diff producing different results on merge requests. !3450
  - Fix commit comment alignment (Stan Hu). !3466
  - Fix Error 500 when searching for a comment in a project snippet. !3468
  - Allow temporary email as notification email. !3477
  - Fix issue with dropdowns not selecting values. !3478
  - Update gitlab-shell version and doc to 2.6.12. gitlab-org/gitlab-ee!280

## 8.6.2

  - Fix dropdown alignment. !3298
  - Fix issuable sidebar overlaps on tablet. !3299
  - Make dropdowns pixel perfect. !3337
  - Fix order of steps to prevent PostgreSQL errors when running migration. !3355
  - Fix bold text in issuable sidebar. !3358
  - Fix error with anonymous token in applications settings. !3362
  - Fix the milestone 'upcoming' filter. !3364 + !3368
  - Fix comments on confidential issues showing up in activity feed to non-members. !3375
  - Fix `NoMethodError` when visiting CI root path at `/ci`. !3377
  - Add a tooltip to new branch button in issue page. !3380
  - Fix an issue hiding the password form when signed-in with a linked account. !3381
  - Add links to CI setup documentation from project settings and builds pages. !3384
  - Fix an issue with width of project select dropdown. !3386
  - Remove redundant `require`s from Banzai files. !3391
  - Fix error 500 with cancel button on issuable edit form. !3392 + !3417
  - Fix background when editing a highlighted note. !3423
  - Remove tabstop from the WIP toggle links. !3426
  - Ensure private project snippets are not viewable by unauthorized people.
  - Gracefully handle notes on deleted commits in merge requests (Stan Hu). !3402
  - Fixed issue with notification settings not saving. !3452

## 8.6.1

  - Add option to reload the schema before restoring a database backup. !2807
  - Display navigation controls on mobile. !3214
  - Fixed bug where participants would not work correctly on merge requests. !3329
  - Fix sorting issues by votes on the groups issues page results in SQL errors. !3333
  - Restrict notifications for confidential issues. !3334
  - Do not allow to move issue if it has not been persisted. !3340
  - Add a confirmation step before deleting an issuable. !3341
  - Fixes issue with signin button overflowing on mobile. !3342
  - Auto collapses the navigation sidebar when resizing. !3343
  - Fix build dependencies, when the dependency is a string. !3344
  - Shows error messages when trying to create label in dropdown menu. !3345
  - Fixes issue with assign milestone not loading milestone list. !3346
  - Fix an issue causing the Dashboard/Milestones page to be blank. !3348

## 8.6.0 (2016-03-22)

  - Add ability to move issue to another project
  - Prevent tokens in the import URL to be showed by the UI
  - Fix bug where wrong commit ID was being used in a merge request diff to show old image (Stan Hu)
  - Add confidential issues
  - Bump gitlab_git to 9.0.3 (Stan Hu)
  - Fix diff image view modes (2-up, swipe, onion skin) not working (Stan Hu)
  - Support Golang subpackage fetching (Stan Hu)
  - Bump Capybara gem to 2.6.2 (Stan Hu)
  - New branch button appears on issues where applicable
  - Contributions to forked projects are included in calendar
  - Improve the formatting for the user page bio (Connor Shea)
  - Easily (un)mark merge request as WIP using link
  - Use specialized system notes when MR is (un)marked as WIP
  - Removed the default password from the initial admin account created during
    setup. A password can be provided during setup (see installation docs), or
    GitLab will ask the user to create a new one upon first visit.
  - Fix issue when pushing to projects ending in .wiki
  - Properly display YAML front matter in Markdown
  - Add support for wiki with UTF-8 page names (Hiroyuki Sato)
  - Fix wiki search results point to raw source (Hiroyuki Sato)
  - Don't load all of GitLab in mail_room
  - Add information about `image` and `services` field at `job` level in the `.gitlab-ci.yml` documentation (Pat Turner)
  - HTTP error pages work independently from location and config (Artem Sidorenko)
  - Update `omniauth-saml` to 1.5.0 to allow for custom response attributes to be set
  - Memoize @group in Admin::GroupsController (Yatish Mehta)
  - Indicate how much an MR diverged from the target branch (Pierre de La Morinerie)
  - Added omniauth-auth0 Gem (Daniel Carraro)
  - Add label description in tooltip to labels in issue index and sidebar
  - Strip leading and trailing spaces in URL validator (evuez)
  - Add "last_sign_in_at" and "confirmed_at" to GET /users/* API endpoints for admins (evuez)
  - Return empty array instead of 404 when commit has no statuses in commit status API
  - Decrease the font size and the padding of the `.anchor` icons used in the README (Roberto Dip)
  - Rewrite logo to simplify SVG code (Sean Lang)
  - Allow to use YAML anchors when parsing the `.gitlab-ci.yml` (Pascal Bach)
  - Ignore jobs that start with `.` (hidden jobs)
  - Hide builds from project's settings when the feature is disabled
  - Allow to pass name of created artifacts archive in `.gitlab-ci.yml`
  - Refactor and greatly improve search performance
  - Add support for cross-project label references
  - Ensure "new SSH key" email do not ends up as dead Sidekiq jobs
  - Update documentation to reflect Guest role not being enforced on internal projects
  - Allow search for logged out users
  - Allow to define on which builds the current one depends on
  - Allow user subscription to a label: get notified for issues/merge requests related to that label (Timothy Andrew)
  - Fix bug where Bitbucket `closed` issues were imported as `opened` (Iuri de Silvio)
  - Don't show Issues/MRs from archived projects in Groups view
  - Fix wrong "iid of max iid" in Issuable sidebar for some merged MRs
  - Fix empty source_sha on Merge Request when there is no diff (Pierre de La Morinerie)
  - Increase the notes polling timeout over time (Roberto Dip)
  - Add shortcut to toggle markdown preview (Florent Baldino)
  - Show labels in dashboard and group milestone views
  - Fix an issue when the target branch of a MR had been deleted
  - Add main language of a project in the list of projects (Tiago Botelho)
  - Add #upcoming filter to Milestone filter (Tiago Botelho)
  - Add ability to show archived projects on dashboard, explore and group pages
  - Remove fork link closes all merge requests opened on source project (Florent Baldino)
  - Move group activity to separate page
  - Create external users which are excluded of internal and private projects unless access was explicitly granted
  - Continue parameters are checked to ensure redirection goes to the same instance
  - User deletion is now done in the background so the request can not time out
  - Canceled builds are now ignored in compound build status if marked as `allowed to fail`
  - Trigger a todo for mentions on commits page
  - Let project owners and admins soft delete issues and merge requests

## 8.5.13

  - Prevent unauthorized access to other projects build traces
  - Forbid scripting for wiki files

## 8.5.12

  - Prevent privilege escalation via "impersonate" feature
  - Prevent privilege escalation via notes API
  - Prevent privilege escalation via project webhook API
  - Prevent XSS via Git branch and tag names
  - Prevent XSS via custom issue tracker URL
  - Prevent XSS via `window.opener`
  - Prevent information disclosure via snippet API
  - Prevent information disclosure via project labels
  - Prevent information disclosure via new merge request page

## 8.5.11

  - Fix persistent XSS vulnerability in `commit_person_link` helper

## 8.5.10

  - Fix a 2FA authentication spoofing vulnerability.

## 8.5.9

  - Don't attempt to fetch any tags from a forked repo (Stan Hu).

## 8.5.8

  - Bump Git version requirement to 2.7.4

## 8.5.7

  - Bump Git version requirement to 2.7.3

## 8.5.6

  - Obtain a lease before querying LDAP

## 8.5.5

  - Ensure removing a project removes associated Todo entries
  - Prevent a 500 error in Todos when author was removed
  - Fix pagination for filtered dashboard and explore pages
  - Fix "Show all" link behavior

## 8.5.4

  - Do not cache requests for badges (including builds badge)

## 8.5.3

  - Flush repository caches before renaming projects
  - Sort starred projects on dashboard based on last activity by default
  - Show commit message in JIRA mention comment
  - Makes issue page and merge request page usable on mobile browsers.
  - Improved UI for profile settings

## 8.5.2

  - Fix sidebar overlapping content when screen width was below 1200px
  - Don't repeat labels listed on Labels tab
  - Bring the "branded appearance" feature from EE to CE
  - Fix error 500 when commenting on a commit
  - Show days remaining instead of elapsed time for Milestone
  - Fix broken icons on installations with relative URL (Artem Sidorenko)
  - Fix issue where tag list wasn't refreshed after deleting a tag
  - Fix import from gitlab.com (KazSawada)
  - Improve implementation to check read access to forks and add pagination
  - Don't show any "2FA required" message if it's not actually required
  - Fix help keyboard shortcut on relative URL setups (Artem Sidorenko)
  - Update Rails to 4.2.5.2
  - Fix permissions for deprecated CI build status badge
  - Don't show "Welcome to GitLab" when the search didn't return any projects
  - Add Todos documentation

## 8.5.1

  - Fix group projects styles
  - Show Crowd login tab when sign in is disabled and Crowd is enabled (Peter Hudec)
  - Fix a set of small UI glitches in project, profile, and wiki pages
  - Restrict permissions on public/uploads
  - Fix the merge request side-by-side view after loading diff results
  - Fix the look of tooltip for the "Revert" button
  - Add when the Builds & Runners API changes got introduced
  - Fix error 500 on some merged merge requests
  - Fix an issue causing the content of the issuable sidebar to disappear
  - Fix error 500 when trying to mark an already done todo as "done"
  - Fix an issue where MRs weren't sortable
  - Issues can now be dragged & dropped into empty milestone lists. This is also
    possible with MRs
  - Changed padding & background color for highlighted notes
  - Re-add the newrelic_rpm gem which was removed without any deprecation or warning (Stan Hu)
  - Update sentry-raven gem to 0.15.6
  - Add build coverage in project's builds page (Steffen Köhler)
  - Changed # to ! for merge requests in activity view

## 8.5.0 (2016-02-22)

  - Fix duplicate "me" in tooltip of the "thumbsup" awards Emoji (Stan Hu)
  - Cache various Repository methods to improve performance
  - Fix duplicated branch creation/deletion Webhooks/service notifications when using Web UI (Stan Hu)
  - Ensure rake tasks that don't need a DB connection can be run without one
  - Update New Relic gem to 3.14.1.311 (Stan Hu)
  - Add "visibility" flag to GET /projects api endpoint
  - Add an option to supply root email through an environmental variable (Koichiro Mikami)
  - Ignore binary files in code search to prevent Error 500 (Stan Hu)
  - Render sanitized SVG images (Stan Hu)
  - Support download access by PRIVATE-TOKEN header (Stan Hu)
  - Upgrade gitlab_git to 7.2.23 to fix commit message mentions in first branch push
  - Add option to include the sender name in body of Notify email (Jason Lee)
  - New UI for pagination
  - Don't prevent sign out when 2FA enforcement is enabled and user hasn't yet
    set it up
  - API: Added "merge_requests/:merge_request_id/closes_issues" (Gal Schlezinger)
  - Fix diff comments loaded by AJAX to load comment with diff in discussion tab
  - Fix relative links in other markup formats (Ben Boeckel)
  - Whitelist raw "abbr" elements when parsing Markdown (Benedict Etzel)
  - Fix label links for a merge request pointing to issues list
  - Don't vendor minified JS
  - Increase project import timeout to 15 minutes
  - Be more permissive with email address validation: it only has to contain a single '@'
  - Display 404 error on group not found
  - Track project import failure
  - Support Two-factor Authentication for LDAP users
  - Display database type and version in Administration dashboard
  - Allow limited Markdown in Broadcast Messages
  - Fix visibility level text in admin area (Zeger-Jan van de Weg)
  - Warn admin during OAuth of granting admin rights (Zeger-Jan van de Weg)
  - Update the ExternalIssue regex pattern (Blake Hitchcock)
  - Remember user's inline/side-by-side diff view preference in a cookie (Kirill Katsnelson)
  - Optimized performance of finding issues to be closed by a merge request
  - Add `avatar_url`, `description`, `git_ssh_url`, `git_http_url`, `path_with_namespace`
    and `default_branch` in `project` in push, issue, merge-request and note webhooks data (Kirill Zaitsev)
  - Deprecate the `ssh_url` in favor of `git_ssh_url` and `http_url` in favor of `git_http_url`
    in `project` for push, issue, merge-request and note webhooks data (Kirill Zaitsev)
  - Deprecate the `repository` key in push, issue, merge-request and note webhooks data, use `project` instead (Kirill Zaitsev)
  - API: Expose MergeRequest#merge_status (Andrei Dziahel)
  - Revert "Add IP check against DNSBLs at account sign-up"
  - Actually use the `skip_merges` option in Repository#commits (Tony Chu)
  - Fix API to keep request parameters in Link header (Michael Potthoff)
  - Deprecate API "merge_request/:merge_request_id/comments". Use "merge_requests/:merge_request_id/notes" instead
  - Deprecate API "merge_request/:merge_request_id/...". Use "merge_requests/:merge_request_id/..." instead
  - Prevent parse error when name of project ends with .atom and prevent path issues
  - Discover branches for commit statuses ref-less when doing merge when succeeded
  - Mark inline difference between old and new paths when a file is renamed
  - Support Akismet spam checking for creation of issues via API (Stan Hu)
  - API: Allow to set or update a merge-request's milestone (Kirill Skachkov)
  - Improve UI consistency between projects and groups lists
  - Add sort dropdown to dashboard projects page
  - Fixed logo animation on Safari (Roman Rott)
  - Fix Merge When Succeeded when multiple stages
  - Hide remove source branch button when the MR is merged but new commits are pushed (Zeger-Jan van de Weg)
  - In search autocomplete show only groups and projects you are member of
  - Don't process cross-reference notes from forks
  - Fix: init.d script not working on OS X
  - Faster snippet search
  - Added API to download build artifacts
  - Title for milestones should be unique (Zeger-Jan van de Weg)
  - Validate correctness of maximum attachment size application setting
  - Replaces "Create merge request" link with one to the "Merge Request" when one exists
  - Fix CI builds badge, add a new link to builds badge, deprecate the old one
  - Fix broken link to project in build notification emails
  - Ability to see and sort on vote count from Issues and MR lists
  - Fix builds scheduler when first build in stage was allowed to fail
  - User project limit is reached notice is hidden if the projects limit is zero
  - Add API support for managing runners and project's runners
  - Allow SAML users to login with no previous account without having to allow
    all Omniauth providers to do so.
  - Allow existing users to auto link their SAML credentials by logging in via SAML
  - Make it possible to erase a build (trace, artifacts) using UI and API
  - Ability to revert changes from a Merge Request or Commit
  - Emoji comment on diffs are not award emoji
  - Add label description (Nuttanart Pornprasitsakul)
  - Show label row when filtering issues or merge requests by label (Nuttanart Pornprasitsakul)
  - Add Todos

## 8.4.11

  - Prevent unauthorized access to other projects build traces
  - Forbid scripting for wiki files

## 8.4.10

  - Prevent privilege escalation via "impersonate" feature
  - Prevent privilege escalation via notes API
  - Prevent privilege escalation via project webhook API
  - Prevent XSS via Git branch and tag names
  - Prevent XSS via custom issue tracker URL
  - Prevent XSS via `window.opener`
  - Prevent information disclosure via snippet API
  - Prevent information disclosure via project labels
  - Prevent information disclosure via new merge request page

## 8.4.9

  - Fix persistent XSS vulnerability in `commit_person_link` helper

## 8.4.8

  - Fix a 2FA authentication spoofing vulnerability.

## 8.4.7

  - Don't attempt to fetch any tags from a forked repo (Stan Hu).

## 8.4.6

  - Bump Git version requirement to 2.7.4

## 8.4.5

  - No CE-specific changes

## 8.4.4

  - Update omniauth-saml gem to 1.4.2
  - Prevent long-running backup tasks from timing out the database connection
  - Add a Project setting to allow guests to view build logs (defaults to true)
  - Sort project milestones by due date including issue editor (Oliver Rogers / Orih)

## 8.4.3

  - Increase lfs_objects size column to 8-byte integer to allow files larger
    than 2.1GB
  - Correctly highlight MR diff when MR has merge conflicts
  - Fix highlighting in blame view
  - Update sentry-raven gem to prevent "Not a git repository" console output
    when running certain commands
  - Add instrumentation to additional Gitlab::Git and Rugged methods for
    performance monitoring
  - Allow autosize textareas to also be manually resized

## 8.4.2

  - Bump required gitlab-workhorse version to bring in a fix for missing
    artifacts in the build artifacts browser
  - Get rid of those ugly borders on the file tree view
  - Fix updating the runner information when asking for builds
  - Bump gitlab_git version to 7.2.24 in order to bring in a performance
    improvement when checking if a repository was empty
  - Add instrumentation for Gitlab::Git::Repository instance methods so we can
    track them in Performance Monitoring.
  - Increase contrast between highlighted code comments and inline diff marker
  - Fix method undefined when using external commit status in builds
  - Fix highlighting in blame view.

## 8.4.1

  - Apply security updates for Rails (4.2.5.1), rails-html-sanitizer (1.0.3),
    and Nokogiri (1.6.7.2)
  - Fix redirect loop during import
  - Fix diff highlighting for all syntax themes
  - Delete project and associations in a background worker

## 8.4.0 (2016-01-22)

  - Allow LDAP users to change their email if it was not set by the LDAP server
  - Ensure Gravatar host looks like an actual host
  - Consider re-assign as a mention from a notification point of view
  - Add pagination headers to already paginated API resources
  - Properly generate diff of orphan commits, like the first commit in a repository
  - Improve the consistency of commit titles, branch names, tag names, issue/MR titles, on their respective project pages
  - Autocomplete data is now always loaded, instead of when focusing a comment text area
  - Improved performance of finding issues for an entire group
  - Added custom application performance measuring system powered by InfluxDB
  - Add syntax highlighting to diffs
  - Gracefully handle invalid UTF-8 sequences in Markdown links (Stan Hu)
  - Bump fog to 1.36.0 (Stan Hu)
  - Add user's last used IP addresses to admin page (Stan Hu)
  - Add housekeeping function to project settings page
  - The default GitLab logo now acts as a loading indicator
  - Fix caching issue where build status was not updating in project dashboard (Stan Hu)
  - Accept 2xx status codes for successful Webhook triggers (Stan Hu)
  - Fix missing date of month in network graph when commits span a month (Stan Hu)
  - Expire view caches when application settings change (e.g. Gravatar disabled) (Stan Hu)
  - Don't notify users twice if they are both project watchers and subscribers (Stan Hu)
  - Remove gray background from layout in UI
  - Fix signup for OAuth providers that don't provide a name
  - Implement new UI for group page
  - Implement search inside emoji picker
  - Let the CI runner know about builds that this build depends on
  - Add API support for looking up a user by username (Stan Hu)
  - Add project permissions to all project API endpoints (Stan Hu)
  - Link to milestone in "Milestone changed" system note
  - Only allow group/project members to mention `@all`
  - Expose Git's version in the admin area (Trey Davis)
  - Add "Frequently used" category to emoji picker
  - Add CAS support (tduehr)
  - Add link to merge request on build detail page
  - Fix: Problem with projects ending with .keys (Jose Corcuera)
  - Revert back upvote and downvote button to the issue and MR pages
  - Swap position of Assignee and Author selector on Issuables (Zeger-Jan van de Weg)
  - Add system hook messages for project rename and transfer (Steve Norman)
  - Fix version check image in Safari
  - Show 'All' tab by default in the builds page
  - Add Open Graph and Twitter Card data to all pages
  - Fix API project lookups when querying with a namespace with dots (Stan Hu)
  - Enable forcing Two-factor authentication sitewide, with optional grace period
  - Import GitHub Pull Requests into GitLab
  - Change single user API endpoint to return more detailed data (Michael Potthoff)
  - Update version check images to use SVG
  - Validate README format before displaying
  - Enable Microsoft Azure OAuth2 support (Janis Meybohm)
  - Properly set task-list class on single item task lists
  - Add file finder feature in tree view (Kyungchul Shin)
  - Ajax filter by message for commits page
  - API: Add support for deleting a tag via the API (Robert Schilling)
  - Allow subsequent validations in CI Linter
  - Show referenced MRs & Issues only when the current viewer can access them
  - Fix Encoding::CompatibilityError bug when markdown content has some complex URL (Jason Lee)
  - Add API support for managing project's builds
  - Add API support for managing project's build triggers
  - Add API support for managing project's build variables
  - Allow broadcast messages to be edited
  - Autosize Markdown textareas
  - Import GitHub wiki into GitLab
  - Add reporters ability to download and browse build artifacts (Andrew Johnson)
  - Autofill referring url in message box when reporting user abuse.
  - Remove leading comma on award emoji when the user is the first to award the emoji (Zeger-Jan van de Weg)
  - Add build artifacts browser
  - Improve UX in builds artifacts browser
  - Increase default size of `data` column in `events` table when using MySQL
  - Expose button to CI Lint tool on project builds page
  - Fix: Creator should be added as a master of the project on creation
  - Added X-GitLab-... headers to emails from CI and Email On Push services (Anton Baklanov)
  - Add IP check against DNSBLs at account sign-up
  - Added cache:key to .gitlab-ci.yml allowing to fine tune the caching

## 8.3.10

  - Prevent unauthorized access to other projects build traces
  - Forbid scripting for wiki files

## 8.3.9

  - Prevent privilege escalation via "impersonate" feature
  - Prevent privilege escalation via notes API
  - Prevent privilege escalation via project webhook API
  - Prevent XSS via custom issue tracker URL
  - Prevent XSS via `window.opener`
  - Prevent information disclosure via project labels
  - Prevent information disclosure via new merge request page

## 8.3.8

  - Fix persistent XSS vulnerability in `commit_person_link` helper

## 8.3.7

  - Fix a 2FA authentication spoofing vulnerability.

## 8.3.6

  - Don't attempt to fetch any tags from a forked repo (Stan Hu).

## 8.3.5

  - Bump Git version requirement to 2.7.4

## 8.3.4

  - Use gitlab-workhorse 0.5.4 (fixes API routing bug)

## 8.3.3

  - Preserve CE behavior with JIRA integration by only calling API if URL is set
  - Fix duplicated branch creation/deletion events when using Web UI (Stan Hu)
  - Add configurable LDAP server query timeout
  - Get "Merge when build succeeds" to work when commits were pushed to MR target branch while builds were running
  - Suppress e-mails on failed builds if allow_failure is set (Stan Hu)
  - Fix project transfer e-mail sending incorrect paths in e-mail notification (Stan Hu)
  - Better support for referencing and closing issues in Asana service (Mike Wyatt)
  - Enable "Add key" button when user fills in a proper key (Stan Hu)
  - Fix error in processing reply-by-email messages (Jason Lee)
  - Fix Error 500 when visiting build page of project with nil runners_token (Stan Hu)
  - Use WOFF versions of SourceSansPro fonts
  - Fix regression when builds were not generated for tags created through web/api interface
  - Fix: maintain milestone filter between Open and Closed tabs (Greg Smethells)
  - Fix missing artifacts and build traces for build created before 8.3

## 8.3.2

  - Disable --follow in `git log` to avoid loading duplicate commit data in infinite scroll (Stan Hu)
  - Add support for Google reCAPTCHA in user registration

## 8.3.1

  - Fix Error 500 when global milestones have slashes (Stan Hu)
  - Fix Error 500 when doing a search in dashboard before visiting any project (Stan Hu)
  - Fix LDAP identity and user retrieval when special characters are used
  - Move Sidekiq-cron configuration to gitlab.yml

## 8.3.0 (2015-12-22)

  - Bump rack-attack to 4.3.1 for security fix (Stan Hu)
  - API support for starred projects for authorized user (Zeger-Jan van de Weg)
  - Add open_issues_count to project API (Stan Hu)
  - Expand character set of usernames created by Omniauth (Corey Hinshaw)
  - Add button to automatically merge a merge request when the build succeeds (Zeger-Jan van de Weg)
  - Add unsubscribe link in the email footer (Zeger-Jan van de Weg)
  - Provide better diagnostic message upon project creation errors (Stan Hu)
  - Bump devise to 3.5.3 to fix reset token expiring after account creation (Stan Hu)
  - Remove api credentials from link to build_page
  - Deprecate GitLabCiService making it to always be inactive
  - Bump gollum-lib to 4.1.0 (Stan Hu)
  - Fix broken group avatar upload under "New group" (Stan Hu)
  - Update project repositorize size and commit count during import:repos task (Stan Hu)
  - Fix API setting of 'public' attribute to false will make a project private (Stan Hu)
  - Handle and report SSL errors in Webhook test (Stan Hu)
  - Bump Redis requirement to 2.8 for Sidekiq 4 (Stan Hu)
  - Fix: Assignee selector is empty when 'Unassigned' is selected (Jose Corcuera)
  - WIP identifier on merge requests no longer requires trailing space
  - Add rake tasks for git repository maintenance (Zeger-Jan van de Weg)
  - Fix 500 error when update group member permission
  - Fix: As an admin, cannot add oneself as a member to a group/project
  - Trim leading and trailing whitespace of milestone and issueable titles (Jose Corcuera)
  - Recognize issue/MR/snippet/commit links as references
  - Backport JIRA features from EE to CE
  - Add ignore whitespace change option to commit view
  - Fire update hook from GitLab
  - Allow account unlock via email
  - Style warning about mentioning many people in a comment
  - Fix: sort milestones by due date once again (Greg Smethells)
  - Migrate all CI::Services and CI::WebHooks to Services and WebHooks
  - Don't show project fork event as "imported"
  - Add API endpoint to fetch merge request commits list
  - Don't create CI status for refs that doesn't have .gitlab-ci.yml, even if the builds are enabled
  - Expose events API with comment information and author info
  - Fix: Ensure "Remove Source Branch" button is not shown when branch is being deleted. #3583
  - Run custom Git hooks when branch is created or deleted.
  - Fix bug when simultaneously accepting multiple MRs results in MRs that are of "merged" status, but not merged to the target branch
  - Add languages page to graphs
  - Block LDAP user when they are no longer found in the LDAP server
  - Improve wording on project visibility levels (Zeger-Jan van de Weg)
  - Fix editing notes on a merge request diff
  - Automatically select default clone protocol based on user preferences (Eirik Lygre)
  - Make Network page as sub tab of Commits
  - Add copy-to-clipboard button for Snippets
  - Add indication to merge request list item that MR cannot be merged automatically
  - Default target branch to patch-n when editing file in protected branch
  - Add Builds tab to merge request detail page
  - Allow milestones, issues and MRs to be created from dashboard and group indexes
  - Use new style for wiki
  - Use new style for milestone detail page
  - Fix sidebar tooltips when collapsed
  - Prevent possible XSS attack with award-emoji
  - Upgraded Sidekiq to 4.x
  - Accept COPYING,COPYING.lesser, and licence as license file (Zeger-Jan van de Weg)
  - Fix emoji aliases problem
  - Fix award-emojis Flash alert's width
  - Fix deleting notes on a merge request diff
  - Display referenced merge request statuses in the issue description (Greg Smethells)
  - Implement new sidebar for issue and merge request pages
  - Emoji picker improvements
  - Suppress warning about missing `.gitlab-ci.yml` if builds are disabled
  - Do not show build status unless builds are enabled and `.gitlab-ci.yml` is present
  - Persist runners registration token in database
  - Fix online editor should not remove newlines at the end of the file
  - Expose Git's version in the admin area
  - Show "New Merge Request" buttons on canonical repos when you have a fork (Josh Frye)

## 8.2.6

  - Prevent unauthorized access to other projects build traces
  - Forbid scripting for wiki files

## 8.2.5

  - Prevent privilege escalation via "impersonate" feature
  - Prevent privilege escalation via notes API
  - Prevent privilege escalation via project webhook API
  - Prevent XSS via `window.opener`
  - Prevent information disclosure via project labels
  - Prevent information disclosure via new merge request page

## 8.2.4

  - Bump Git version requirement to 2.7.4

## 8.2.3

  - Fix application settings cache not expiring after changes (Stan Hu)
  - Fix Error 500s when creating global milestones with Unicode characters (Stan Hu)
  - Update documentation for "Guest" permissions
  - Properly convert Emoji-only comments into Award Emojis
  - Enable devise paranoid mode to prevent user enumeration attack
  - Webhook payload has an added, modified and removed properties for each commit
  - Fix 500 error when creating a merge request that removes a submodule

## 8.2.2

  - Fix 404 in redirection after removing a project (Stan Hu)
  - Ensure cached application settings are refreshed at startup (Stan Hu)
  - Fix Error 500 when viewing user's personal projects from admin page (Stan Hu)
  - Fix: Raw private snippets access workflow
  - Prevent "413 Request entity too large" errors when pushing large files with LFS
  - Fix invalid links within projects dashboard header
  - Make current user the first user in assignee dropdown in issues detail page (Stan Hu)
  - Fix: duplicate email notifications on issue comments

## 8.2.1

  - Forcefully update builds that didn't want to update with state machine
  - Fix: saving GitLabCiService as Admin Template

## 8.2.0 (2015-11-22)

  - Improved performance of finding projects and groups in various places
  - Improved performance of rendering user profile pages and Atom feeds
  - Expose build artifacts path as config option
  - Fix grouping of contributors by email in graph.
  - Improved performance of finding issues with/without labels
  - Fix Drone CI service template not saving properly (Stan Hu)
  - Fix avatars not showing in Atom feeds and project issues when Gravatar disabled (Stan Hu)
  - Added a GitLab specific profiling tool called "Sherlock" (see GitLab CE merge request #1749)
  - Upgrade gitlab_git to 7.2.20 and rugged to 0.23.3 (Stan Hu)
  - Improved performance of finding users by one of their Email addresses
  - Add allow_failure field to commit status API (Stan Hu)
  - Commits without .gitlab-ci.yml are marked as skipped
  - Save detailed error when YAML syntax is invalid
  - Since GitLab CI is enabled by default, remove enabling it by pushing .gitlab-ci.yml
  - Added build artifacts
  - Improved performance of replacing references in comments
  - Show last project commit to default branch on project home page
  - Highlight comment based on anchor in URL
  - Adds ability to remove the forked relationship from project settings screen. (Han Loong Liauw)
  - Improved performance of sorting milestone issues
  - Allow users to select the Files view as default project view (Cristian Bica)
  - Show "Empty Repository Page" for repository without branches (Artem V. Navrotskiy)
  - Fix: Inability to reply to code comments in the MR view, if the MR comes from a fork
  - Use git follow flag for commits page when retrieve history for file or directory
  - Show merge request CI status on merge requests index page
  - Send build name and stage in CI notification e-mail
  - Extend yml syntax for only and except to support specifying repository path
  - Enable shared runners to all new projects
  - Bump GitLab-Workhorse to 0.4.1
  - Allow to define cache in `.gitlab-ci.yml`
  - Fix: 500 error returned if destroy request without HTTP referer (Kazuki Shimizu)
  - Remove deprecated CI events from project settings page
  - Use issue editor as cross reference comment author when issue is edited with a new mention.
  - Add graphs of commits ahead and behind default branch (Jeff Stubler)
  - Improve personal snippet access workflow (Douglas Alexandre)
  - [API] Add ability to fetch the commit ID of the last commit that actually touched a file
  - Fix omniauth documentation setting for omnibus configuration (Jon Cairns)
  - Add "New file" link to dropdown on project page
  - Include commit logs in project search
  - Add "added", "modified" and "removed" properties to commit object in webhook
  - Rename "Back to" links to "Go to" because its not always a case it point to place user come from
  - Allow groups to appear in the search results if the group owner allows it
  - Add email notification to former assignee upon unassignment (Adam Lieskovský)
  - New design for project graphs page
  - Remove deprecated dumped yaml file generated from previous job definitions
  - Show specific runners from projects where user is master or owner
  - MR target branch is now visible on a list view when it is different from project's default one
  - Improve Continuous Integration graphs page
  - Make color of "Accept Merge Request" button consistent with current build status
  - Add ignore white space option in merge request diff and commit and compare view
  - Ability to add release notes (markdown text and attachments) to git tags (aka Releases)
  - Relative links from a repositories README.md now link to the default branch
  - Fix trailing whitespace issue in merge request/issue title
  - Fix bug when milestone/label filter was empty for dashboard issues page
  - Add ability to create milestone in group projects from single form
  - Add option to create merge request when editing/creating a file (Dirceu Tiegs)
  - Prevent the last owner of a group from being able to delete themselves by 'adding' themselves as a master (James Lopez)
  - Add Award Emoji to issue and merge request pages

## 8.1.4

  - Fix bug where manually merged branches in a MR would end up with an empty diff (Stan Hu)
  - Prevent redirect loop when home_page_url is set to the root URL
  - Fix incoming email config defaults
  - Remove CSS property preventing hard tabs from rendering in Chromium 45 (Stan Hu)

## 8.1.3

  - Force update refs/merge-requests/X/head upon a push to the source branch of a merge request (Stan Hu)
  - Spread out runner contacted_at updates
  - Use issue editor as cross reference comment author when issue is edited with a new mention
  - Add Facebook authentication

## 8.1.2

  - Fix cloning Wiki repositories via HTTP (Stan Hu)
  - Add migration to remove satellites directory
  - Fix specific runners visibility
  - Fix 500 when editing CI service
  - Require CI jobs to be named
  - Fix CSS for runner status
  - Fix CI badge
  - Allow developer to manage builds

## 8.1.1

  - Removed, see 8.1.2

## 8.1.0 (2015-10-22)

  - Ensure MySQL CI limits DB migrations occur after the fields have been created (Stan Hu)
  - Fix duplicate repositories in GitHub import page (Stan Hu)
  - Redirect to a default path if HTTP_REFERER is not set (Stan Hu)
  - Adds ability to create directories using the web editor (Ben Ford)
  - Cleanup stuck CI builds
  - Send an email to admin email when a user is reported for spam (Jonathan Rochkind)
  - Show notifications button when user is member of group rather than project (Grzegorz Bizon)
  - Fix bug preventing mentioned issued from being closed when MR is merged using fast-forward merge.
  - Fix nonatomic database update potentially causing project star counts to go negative (Stan Hu)
  - Don't show "Add README" link in an empty repository if user doesn't have access to push (Stan Hu)
  - Fix error preventing displaying of commit data for a directory with a leading dot (Stan Hu)
  - Speed up load times of issue detail pages by roughly 1.5x
  - Fix CI rendering regressions
  - If a merge request is to close an issue, show this on the issue page (Zeger-Jan van de Weg)
  - Add a system note and update relevant merge requests when a branch is deleted or re-added (Stan Hu)
  - Make diff file view easier to use on mobile screens (Stan Hu)
  - Improved performance of finding users by username or Email address
  - Fix bug where merge request comments created by API would not trigger notifications (Stan Hu)
  - Add support for creating directories from Files page (Stan Hu)
  - Allow removing of project without confirmation when JavaScript is disabled (Stan Hu)
  - Support filtering by "Any" milestone or issue and fix "No Milestone" and "No Label" filters (Stan Hu)
  - Improved performance of the trending projects page
  - Remove CI migration task
  - Improved performance of finding projects by their namespace
  - Add assignee data to Issuables' hook_data (Bram Daams)
  - Fix bug where transferring a project would result in stale commit links (Stan Hu)
  - Fix build trace updating
  - Include full path of source and target branch names in New Merge Request page (Stan Hu)
  - Add user preference to view activities as default dashboard (Stan Hu)
  - Add option to admin area to sign in as a specific user (Pavel Forkert)
  - Show CI status on all pages where commits list is rendered
  - Automatically enable CI when push .gitlab-ci.yml file to repository
  - Move CI charts to project graphs area
  - Fix cases where Markdown did not render links in activity feed (Stan Hu)
  - Add first and last to pagination (Zeger-Jan van de Weg)
  - Added Commit Status API
  - Added Builds View
  - Added when to .gitlab-ci.yml
  - Show CI status on commit page
  - Added CI_BUILD_TAG, _STAGE, _NAME and _TRIGGERED to CI builds
  - Show CI status on Your projects page and Starred projects page
  - Remove "Continuous Integration" page from dashboard
  - Add notes and SSL verification entries to hook APIs (Ben Boeckel)
  - Fix grammar in admin area "labels" .nothing-here-block when no labels exist.
  - Move CI runners page to project settings area
  - Move CI variables page to project settings area
  - Move CI triggers page to project settings area
  - Move CI project settings page to CE project settings area
  - Fix bug when removed file was not appearing in merge request diff
  - Show warning when build cannot be served by any of the available CI runners
  - Note the original location of a moved project when notifying users of the move
  - Improve error message when merging fails
  - Add support of multibyte characters in LDAP UID (Roman Petrov)
  - Show additions/deletions stats on merge request diff
  - Remove footer text in emails (Zeger-Jan van de Weg)
  - Ensure code blocks are properly highlighted after a note is updated
  - Fix wrong access level badge on MR comments
  - Hide password in the service settings form
  - Move CI webhooks page to project settings area
  - Fix User Identities API. It now allows you to properly create or update user's identities.
  - Add user preference to change layout width (Peter Göbel)
  - Use commit status in merge request widget as preferred source of CI status
  - Integrate CI commit and build pages into project pages
  - Move CI services page to project settings area
  - Add "Quick Submit" behavior to input fields throughout the application. Use
    Cmd+Enter on Mac and Ctrl+Enter on Windows/Linux.
  - Fix position of hamburger in header for smaller screens (Han Loong Liauw)
  - Fix bug where Emojis in Markdown would truncate remaining text (Sakata Sinji)
  - Persist filters when sorting on admin user page (Jerry Lukins)
  - Update style of snippets pages (Han Loong Liauw)
  - Allow dashboard and group issues/MRs to be filtered by label
  - Add spellcheck=false to certain input fields
  - Invalidate stored service password if the endpoint URL is changed
  - Project names are not fully shown if group name is too big, even on group page view
  - Apply new design for Files page
  - Add "New Page" button to Wiki Pages tab (Stan Hu)
  - Only render 404 page from /public
  - Hide passwords from services API (Alex Lossent)
  - Fix: Images cannot show when projects' path was changed
  - Let gitlab-git-http-server generate and serve 'git archive' downloads
  - Optimize query when filtering on issuables (Zeger-Jan van de Weg)
  - Fix padding of outdated discussion item.
  - Animate the logo on hover

## 8.0.5

  - Correct lookup-by-email for LDAP logins
  - Fix loading spinner sometimes not being hidden on Merge Request tab switches

## 8.0.4

  - Fix Message-ID header to be RFC 2111-compliant to prevent e-mails being dropped (Stan Hu)
  - Fix referrals for :back and relative URL installs
  - Fix anchors to comments in diffs
  - Remove CI token from build traces
  - Fix "Assign All" button on Runner admin page
  - Fix search in Files
  - Add full project namespace to payload of system webhooks (Ricardo Band)

## 8.0.3

  - Fix URL shown in Slack notifications
  - Fix bug where projects would appear to be stuck in the forked import state (Stan Hu)
  - Fix Error 500 in creating merge requests with > 1000 diffs (Stan Hu)
  - Add work_in_progress key to MR webhooks (Ben Boeckel)

## 8.0.2

  - Fix default avatar not rendering in network graph (Stan Hu)
  - Skip check_initd_configured_correctly on omnibus installs
  - Prevent double-prefixing of help page paths
  - Clarify confirmation text on user deletion
  - Make commit graphs responsive to window width changes (Stan Hu)
  - Fix top margin for sign-in button on public pages
  - Fix LDAP attribute mapping
  - Remove git refs used internally by GitLab from network graph (Stan Hu)
  - Use standard Markdown font in Markdown preview instead of fixed-width font (Stan Hu)
  - Fix Reply by email for non-UTF-8 messages.
  - Add option to use StartTLS with Reply by email IMAP server.
  - Allow AWS S3 Server-Side Encryption with Amazon S3-Managed Keys for backups (Paul Beattie)

## 8.0.1

  - Improve CI migration procedure and documentation

## 8.0.0 (2015-09-22)

  - Fix Markdown links not showing up in dashboard activity feed (Stan Hu)
  - Remove milestones from merge requests when milestones are deleted (Stan Hu)
  - Fix HTML link that was improperly escaped in new user e-mail (Stan Hu)
  - Fix broken sort in merge request API (Stan Hu)
  - Bump rouge to 1.10.1 to remove warning noise and fix other syntax highlighting bugs (Stan Hu)
  - Gracefully handle errors in syntax highlighting by leaving the block unformatted (Stan Hu)
  - Add "replace" and "upload" functionalities to allow user replace existing file and upload new file into current repository
  - Fix URL construction for merge requests, issues, notes, and commits for relative URL config (Stan Hu)
  - Fix emoji URLs in Markdown when relative_url_root is used (Stan Hu)
  - Omit filename in Content-Disposition header in raw file download to avoid RFC 6266 encoding issues (Stan HU)
  - Fix broken Wiki Page History (Stan Hu)
  - Import forked repositories asynchronously to prevent large repositories from timing out (Stan Hu)
  - Prevent anchors from being hidden by header (Stan Hu)
  - Fix bug where only the first 15 Bitbucket issues would be imported (Stan Hu)
  - Sort issues by creation date in Bitbucket importer (Stan Hu)
  - Prevent too many redirects upon login when home page URL is set to external_url (Stan Hu)
  - Improve dropdown positioning on the project home page (Hannes Rosenögger)
  - Upgrade browser gem to 1.0.0 to avoid warning in IE11 compatibility mode (Stan Hu)
  - Remove user OAuth tokens from the database and request new tokens each session (Stan Hu)
  - Restrict users API endpoints to use integer IDs (Stan Hu)
  - Only show recent push event if the branch still exists or a recent merge request has not been created (Stan Hu)
  - Remove satellites
  - Better performance for web editor (switched from satellites to rugged)
  - Faster merge
  - Ability to fetch merge requests from refs/merge-requests/:id
  - Allow displaying of archived projects in the admin interface (Artem Sidorenko)
  - Allow configuration of import sources for new projects (Artem Sidorenko)
  - Search for comments should be case insensitive
  - Create cross-reference for closing references on commits pushed to non-default branches (Maël Valais)
  - Ability to search milestones
  - Gracefully handle SMTP user input errors (e.g. incorrect email addresses) to prevent Sidekiq retries (Stan Hu)
  - Move dashboard activity to separate page (for your projects and starred projects)
  - Improve performance of git blame
  - Limit content width to 1200px for most of pages to improve readability on big screens
  - Fix 500 error when submit project snippet without body
  - Improve search page usability
  - Bring more UI consistency in way how projects, snippets and groups lists are rendered
  - Make all profiles and group public
  - Fixed login failure when extern_uid changes (Joel Koglin)
  - Don't notify users without access to the project when they are (accidentally) mentioned in a note.
  - Retrieving oauth token with LDAP credentials
  - Load Application settings from running database unless env var USE_DB=false
  - Added Drone CI integration (Kirill Zaitsev)
  - Allow developers to retry builds
  - Hide advanced project options for non-admin users
  - Fail builds if no .gitlab-ci.yml is found
  - Refactored service API and added automatically service docs generator (Kirill Zaitsev)
  - Added web_url key project hook_attrs (Kirill Zaitsev)
  - Add ability to get user information by ID of an SSH key via the API
  - Fix bug which IE cannot show image at markdown when the image is raw file of gitlab
  - Add support for Crowd
  - Global Labels that are available to all projects
  - Fix highlighting of deleted lines in diffs.
  - Project notification level can be set on the project page itself
  - Added service API endpoint to retrieve service parameters (Petheő Bence)
  - Add FogBugz project import (Jared Szechy)
  - Sort users autocomplete lists by user (Allister Antosik)
  - Webhook for issue now contains repository field (Jungkook Park)
  - Add ability to add custom text to the help page (Jeroen van Baarsen)
  - Add pg_schema to backup config
  - Fix references to target project issues in Merge Requests markdown preview and textareas (Francesco Levorato)
  - Redirect from incorrectly cased group or project path to correct one (Francesco Levorato)
  - Removed API calls from CE to CI

## 7.14.3

- No changes

## 7.14.2

- Upgrade gitlab_git to 7.2.15 to fix `git blame` errors with ISO-encoded files (Stan Hu)
- Allow configuration of LDAP attributes GitLab will use for the new user account.

## 7.14.1

- Improve abuse reports management from admin area
- Fix "Reload with full diff" URL button in compare branch view (Stan Hu)
- Disabled DNS lookups for SSH in docker image (Rowan Wookey)
- Only include base URL in OmniAuth full_host parameter (Stan Hu)
- Fix Error 500 in API when accessing a group that has an avatar (Stan Hu)
- Ability to enable SSL verification for Webhooks

## 7.14.0

- Fix bug where non-project members of the target project could set labels on new merge requests.
- Update default robots.txt rules to disallow crawling of irrelevant pages (Ben Bodenmiller)
- Fix redirection after sign in when using auto_sign_in_with_provider
- Upgrade gitlab_git to 7.2.14 to ignore CRLFs in .gitmodules (Stan Hu)
- Clear cache to prevent listing deleted branches after MR removes source branch (Stan Hu)
- Provide more feedback what went wrong if HipChat service failed test (Stan Hu)
- Fix bug where backslashes in inline diffs could be dropped (Stan Hu)
- Disable turbolinks when linking to Bitbucket import status (Stan Hu)
- Fix broken code import and display error messages if something went wrong with creating project (Stan Hu)
- Fix corrupted binary files when using API files endpoint (Stan Hu)
- Bump Haml to 4.0.7 to speed up textarea rendering (Stan Hu)
- Show incompatible projects in Bitbucket import status (Stan Hu)
- Fix coloring of diffs on MR Discussion-tab (Gert Goet)
- Fix "Network" and "Graphs" pages for branches with encoded slashes (Stan Hu)
- Fix errors deleting and creating branches with encoded slashes (Stan Hu)
- Always add current user to autocomplete controller to support filter by "Me" (Stan Hu)
- Fix multi-line syntax highlighting (Stan Hu)
- Fix network graph when branch name has single quotes (Stan Hu)
- Add "Confirm user" button in user admin page (Stan Hu)
- Upgrade gitlab_git to version 7.2.6 to fix Error 500 when creating network graphs (Stan Hu)
- Add support for Unicode filenames in relative links (Hiroyuki Sato)
- Fix URL used for refreshing notes if relative_url is present (Bartłomiej Święcki)
- Fix commit data retrieval when branch name has single quotes (Stan Hu)
- Check that project was actually created rather than just validated in import:repos task (Stan Hu)
- Fix full screen mode for snippet comments (Daniel Gerhardt)
- Fix 404 error in files view after deleting the last file in a repository (Stan Hu)
- Fix the "Reload with full diff" URL button (Stan Hu)
- Fix label read access for unauthenticated users (Daniel Gerhardt)
- Fix access to disabled features for unauthenticated users (Daniel Gerhardt)
- Fix OAuth provider bug where GitLab would not go return to the redirect_uri after sign-in (Stan Hu)
- Fix file upload dialog for comment editing (Daniel Gerhardt)
- Set OmniAuth full_host parameter to ensure redirect URIs are correct (Stan Hu)
- Return comments in created order in merge request API (Stan Hu)
- Disable internal issue tracker controller if external tracker is used (Stan Hu)
- Expire Rails cache entries after two weeks to prevent endless Redis growth
- Add support for destroying project milestones (Stan Hu)
- Allow custom backup archive permissions
- Add project star and fork count, group avatar URL and user/group web URL attributes to API
- Show who last edited a comment if it wasn't the original author
- Send notification to all participants when MR is merged.
- Add ability to manage user email addresses via the API.
- Show buttons to add license, changelog and contribution guide if they're missing.
- Tweak project page buttons.
- Disabled autocapitalize and autocorrect on login field (Daryl Chan)
- Mention group and project name in creation, update and deletion notices (Achilleas Pipinellis)
- Update gravatar link on profile page to link to configured gravatar host (Ben Bodenmiller)
- Remove redis-store TTL monkey patch
- Add support for CI skipped status
- Fetch code from forks to refs/merge-requests/:id/head when merge request created
- Remove comments and email addresses when publicly exposing ssh keys (Zeger-Jan van de Weg)
- Add "Check out branch" button to the MR page.
- Improve MR merge widget text and UI consistency.
- Improve text in MR "How To Merge" modal.
- Cache all events
- Order commits by date when comparing branches
- Fix bug causing error when the target branch of a symbolic ref was deleted
- Include branch/tag name in archive file and directory name
- Add dropzone upload progress
- Add a label for merged branches on branches page (Florent Baldino)
- Detect .mkd and .mkdn files as markdown (Ben Boeckel)
- Fix: User search feature in admin area does not respect filters
- Set max-width for README, issue and merge request description for easier read on big screens
- Update Flowdock integration to support new Flowdock API (Boyan Tabakov)
- Remove author from files view (Sven Strickroth)
- Fix infinite loop when SAML was incorrectly configured.

## 7.13.5

- Satellites reverted

## 7.13.4

- Allow users to send abuse reports

## 7.13.3

- Fix bug causing Bitbucket importer to crash when OAuth application had been removed.
- Allow users to send abuse reports
- Remove satellites
- Link username to profile on Group Members page (Tom Webster)

## 7.13.2

- Fix randomly failed spec
- Create project services on Project creation
- Add admin_merge_request ability to Developer level and up
- Fix Error 500 when browsing projects with no HEAD (Stan Hu)
- Fix labels / assignee / milestone for the merge requests when issues are disabled
- Show the first tab automatically on MergeRequests#new
- Add rake task 'gitlab:update_commit_count' (Daniel Gerhardt)
- Fix Gmail Actions

## 7.13.1

- Fix: Label modifications are not reflected in existing notes and in the issue list
- Fix: Label not shown in the Issue list, although it's set through web interface
- Fix: Group/project references are linked incorrectly
- Improve documentation
- Fix of migration: Check if session_expire_delay column exists before adding the column
- Fix: ActionView::Template::Error
- Fix: "Create Merge Request" isn't always shown in event for newly pushed branch
- Fix bug causing "Remove source-branch" option not to work for merge requests from the same project.
- Render Note field hints consistently for "new" and "edit" forms

## 7.13.0

- Remove repository graph log to fix slow cache updates after push event (Stan Hu)
- Only enable HSTS header for HTTPS and port 443 (Stan Hu)
- Fix user autocomplete for unauthenticated users accessing public projects (Stan Hu)
- Fix redirection to home page URL for unauthorized users (Daniel Gerhardt)
- Add branch switching support for graphs (Daniel Gerhardt)
- Fix external issue tracker hook/test for HTTPS URLs (Daniel Gerhardt)
- Remove link leading to a 404 error in Deploy Keys page (Stan Hu)
- Add support for unlocking users in admin settings (Stan Hu)
- Add Irker service configuration options (Stan Hu)
- Fix order of issues imported from GitHub (Hiroyuki Sato)
- Bump rugments to 1.0.0beta8 to fix C prototype function highlighting (Jonathon Reinhart)
- Fix Merge Request webhook to properly fire "merge" action when accepted from the web UI
- Add `two_factor_enabled` field to admin user API (Stan Hu)
- Fix invalid timestamps in RSS feeds (Rowan Wookey)
- Fix downloading of patches on public merge requests when user logged out (Stan Hu)
- Fix Error 500 when relative submodule resolves to a namespace that has a different name from its path (Stan Hu)
- Extract the longest-matching ref from a commit path when multiple matches occur (Stan Hu)
- Update maintenance documentation to explain no need to recompile asssets for omnibus installations (Stan Hu)
- Support commenting on diffs in side-by-side mode (Stan Hu)
- Fix JavaScript error when clicking on the comment button on a diff line that has a comment already (Stan Hu)
- Return 40x error codes if branch could not be deleted in UI (Stan Hu)
- Remove project visibility icons from dashboard projects list
- Rename "Design" profile settings page to "Preferences".
- Allow users to customize their default Dashboard page.
- Update ssl_ciphers in Nginx example to remove DHE settings. This will deny forward secrecy for Android 2.3.7, Java 6 and OpenSSL 0.9.8
- Admin can edit and remove user identities
- Convert CRLF newlines to LF when committing using the web editor.
- API request /projects/:project_id/merge_requests?state=closed will return only closed merge requests without merged one. If you need ones that were merged - use state=merged.
- Allow Administrators to filter the user list by those with or without Two-factor Authentication enabled.
- Show a user's Two-factor Authentication status in the administration area.
- Explicit error when commit not found in the CI
- Improve performance for issue and merge request pages
- Users with guest access level can not set assignee, labels or milestones for issue and merge request
- Reporter role can manage issue tracker now: edit any issue, set assignee or milestone and manage labels
- Better performance for pages with events list, issues list and commits list
- Faster automerge check and merge itself when source and target branches are in same repository
- Correctly show anonymous authorized applications under Profile > Applications.
- Query Optimization in MySQL.
- Allow users to be blocked and unblocked via the API
- Use native Postgres database cleaning during backup restore
- Redesign project page. Show README as default instead of activity. Move project activity to separate page
- Make left menu more hierarchical and less contextual by adding back item at top
- A fork can’t have a visibility level that is greater than the original project.
- Faster code search in repository and wiki. Fixes search page timeout for big repositories
- Allow administrators to disable 2FA for a specific user
- Add error message for SSH key linebreaks
- Store commits count in database (will populate with valid values only after first push)
- Rebuild cache after push to repository in background job
- Fix transferring of project to another group using the API.

## 7.12.2

- Correctly show anonymous authorized applications under Profile > Applications.
- Faster automerge check and merge itself when source and target branches are in same repository
- Audit log for user authentication
- Allow custom label to be set for authentication providers.

## 7.12.1

- Fix error when deleting a user who has projects (Stan Hu)
- Fix post-receive errors on a push when an external issue tracker is configured (Stan Hu)
- Add SAML to list of social_provider (Matt Firtion)
- Fix merge requests API scope to keep compatibility in 7.12.x patch release (Dmitriy Zaporozhets)
- Fix closed merge request scope at milestone page (Dmitriy Zaporozhets)
- Revert merge request states renaming
- Fix hooks for web based events with external issue references (Daniel Gerhardt)
- Improve performance for issue and merge request pages
- Compress database dumps to reduce backup size

## 7.12.0

- Fix Error 500 when one user attempts to access a personal, internal snippet (Stan Hu)
- Disable changing of target branch in new merge request page when a branch has already been specified (Stan Hu)
- Fix post-receive errors on a push when an external issue tracker is configured (Stan Hu)
- Update oauth button logos for Twitter and Google to recommended assets
- Update browser gem to version 0.8.0 for IE11 support (Stan Hu)
- Fix timeout when rendering file with thousands of lines.
- Add "Remember me" checkbox to LDAP signin form.
- Add session expiration delay configuration through UI application settings
- Don't notify users mentioned in code blocks or blockquotes.
- Omit link to generate labels if user does not have access to create them (Stan Hu)
- Show warning when a comment will add 10 or more people to the discussion.
- Disable changing of the source branch in merge request update API (Stan Hu)
- Shorten merge request WIP text.
- Add option to disallow users from registering any application to use GitLab as an OAuth provider
- Support editing target branch of merge request (Stan Hu)
- Refactor permission checks with issues and merge requests project settings (Stan Hu)
- Fix Markdown preview not working in Edit Milestone page (Stan Hu)
- Fix Zen Mode not closing with ESC key (Stan Hu)
- Allow HipChat API version to be blank and default to v2 (Stan Hu)
- Add file attachment support in Milestone description (Stan Hu)
- Fix milestone "Browse Issues" button.
- Set milestone on new issue when creating issue from index with milestone filter active.
- Make namespace API available to all users (Stan Hu)
- Add webhook support for note events (Stan Hu)
- Disable "New Issue" and "New Merge Request" buttons when features are disabled in project settings (Stan Hu)
- Remove Rack Attack monkey patches and bump to version 4.3.0 (Stan Hu)
- Fix clone URL losing selection after a single click in Safari and Chrome (Stan Hu)
- Fix git blame syntax highlighting when different commits break up lines (Stan Hu)
- Add "Resend confirmation e-mail" link in profile settings (Stan Hu)
- Allow to configure location of the `.gitlab_shell_secret` file. (Jakub Jirutka)
- Disabled expansion of top/bottom blobs for new file diffs
- Update Asciidoctor gem to version 1.5.2. (Jakub Jirutka)
- Fix resolving of relative links to repository files in AsciiDoc documents. (Jakub Jirutka)
- Use the user list from the target project in a merge request (Stan Hu)
- Default extension for wiki pages is now .md instead of .markdown (Jeroen van Baarsen)
- Add validation to wiki page creation (only [a-zA-Z0-9/_-] are allowed) (Jeroen van Baarsen)
- Fix new/empty milestones showing 100% completion value (Jonah Bishop)
- Add a note when an Issue or Merge Request's title changes
- Consistently refer to MRs as either Merged or Closed.
- Add Merged tab to MR lists.
- Prefix EmailsOnPush email subject with `[Git]`.
- Group project contributions by both name and email.
- Clarify navigation labels for Project Settings and Group Settings.
- Move user avatar and logout button to sidebar
- You can not remove user if he/she is an only owner of group
- User should be able to leave group. If not - show him proper message
- User has ability to leave project
- Add SAML support as an omniauth provider
- Allow to configure a URL to show after sign out
- Add an option to automatically sign-in with an Omniauth provider
- GitLab CI service sends .gitlab-ci.yml in each push call
- When remove project - move repository and schedule it removal
- Improve group removing logic
- Trigger create-hooks on backup restore task
- Add option to automatically link omniauth and LDAP identities
- Allow special character in users bio. I.e.: I <3 GitLab

## 7.11.4

- Fix missing bullets when creating lists
- Set rel="nofollow" on external links

## 7.11.3

- no changes
- Fix upgrader script (Martins Polakovs)

## 7.11.2

- no changes

## 7.11.1

- no changes

## 7.11.0

- Fall back to Plaintext when Syntaxhighlighting doesn't work. Fixes some buggy lexers (Hannes Rosenögger)
- Get editing comments to work in Chrome 43 again.
- Fix broken view when viewing history of a file that includes a path that used to be another file (Stan Hu)
- Don't show duplicate deploy keys
- Fix commit time being displayed in the wrong timezone in some cases (Hannes Rosenögger)
- Make the first branch pushed to an empty repository the default HEAD (Stan Hu)
- Fix broken view when using a tag to display a tree that contains git submodules (Stan Hu)
- Make Reply-To config apply to change e-mail confirmation and other Devise notifications (Stan Hu)
- Add application setting to restrict user signups to e-mail domains (Stan Hu)
- Don't allow a merge request to be merged when its title starts with "WIP".
- Add a page title to every page.
- Allow primary email to be set to an email that you've already added.
- Fix clone URL field and X11 Primary selection (Dmitry Medvinsky)
- Ignore invalid lines in .gitmodules
- Fix "Cannot move project" error message from popping up after a successful transfer (Stan Hu)
- Redirect to sign in page after signing out.
- Fix "Hello @username." references not working by no longer allowing usernames to end in period.
- Fix "Revspec not found" errors when viewing diffs in a forked project with submodules (Stan Hu)
- Improve project page UI
- Fix broken file browsing with relative submodule in personal projects (Stan Hu)
- Add "Reply quoting selected text" shortcut key (`r`)
- Fix bug causing `@whatever` inside an issue's first code block to be picked up as a user mention.
- Fix bug causing `@whatever` inside an inline code snippet (backtick-style) to be picked up as a user mention.
- When use change branches link at MR form - save source branch selection instead of target one
- Improve handling of large diffs
- Added GitLab Event header for project hooks
- Add Two-factor authentication (2FA) for GitLab logins
- Show Atom feed buttons everywhere where applicable.
- Add project activity atom feed.
- Don't crash when an MR from a fork has a cross-reference comment from the target project on one of its commits.
- Explain how to get a new password reset token in welcome emails
- Include commit comments in MR from a forked project.
- Group milestones by title in the dashboard and all other issue views.
- Query issues, merge requests and milestones with their IID through API (Julien Bianchi)
- Add default project and snippet visibility settings to the admin web UI.
- Show incompatible projects in Google Code import status (Stan Hu)
- Fix bug where commit data would not appear in some subdirectories (Stan Hu)
- Task lists are now usable in comments, and will show up in Markdown previews.
- Fix bug where avatar filenames were not actually deleted from the database during removal (Stan Hu)
- Fix bug where Slack service channel was not saved in admin template settings. (Stan Hu)
- Protect OmniAuth request phase against CSRF.
- Don't send notifications to mentioned users that don't have access to the project in question.
- Add search issues/MR by number
- Change plots to bar graphs in commit statistics screen
- Move snippets UI to fluid layout
- Improve UI for sidebar. Increase separation between navigation and content
- Improve new project command options (Ben Bodenmiller)
- Add common method to force UTF-8 and use it to properly handle non-ascii OAuth user properties (Onur Küçük)
- Prevent sending empty messages to HipChat (Chulki Lee)
- Improve UI for mobile phones on dashboard and project pages
- Add room notification and message color option for HipChat
- Allow to use non-ASCII letters and dashes in project and namespace name. (Jakub Jirutka)
- Add footnotes support to Markdown (Guillaume Delbergue)
- Add current_sign_in_at to UserFull REST api.
- Make Sidekiq MemoryKiller shutdown signal configurable
- Add "Create Merge Request" buttons to commits and branches pages and push event.
- Show user roles by comments.
- Fix automatic blocking of auto-created users from Active Directory.
- Call merge request webhook for each new commits (Arthur Gautier)
- Use SIGKILL by default in Sidekiq::MemoryKiller
- Fix mentioning of private groups.
- Add style for <kbd> element in markdown
- Spin spinner icon next to "Checking for CI status..." on MR page.
- Fix reference links in dashboard activity and ATOM feeds.
- Ensure that the first added admin performs repository imports

## 7.10.4

- Fix migrations broken in 7.10.2
- Make tags for GitLab installations running on MySQL case sensitive
- Get Gitorious importer to work again.
- Fix adding new group members from admin area
- Fix DB error when trying to tag a repository (Stan Hu)
- Fix Error 500 when searching Wiki pages (Stan Hu)
- Unescape branch names in compare commit (Stan Hu)
- Order commit comments chronologically in API.

## 7.10.2

- Fix CI links on MR page

## 7.10.0

- Ignore submodules that are defined in .gitmodules but are checked in as directories.
- Allow projects to be imported from Google Code.
- Remove access control for uploaded images to fix broken images in emails (Hannes Rosenögger)
- Allow users to be invited by email to join a group or project.
- Don't crash when project repository doesn't exist.
- Add config var to block auto-created LDAP users.
- Don't use HTML ellipsis in EmailsOnPush subject truncated commit message.
- Set EmailsOnPush reply-to address to committer email when enabled.
- Fix broken file browsing with a submodule that contains a relative link (Stan Hu)
- Fix persistent XSS vulnerability around profile website URLs.
- Fix project import URL regex to prevent arbitrary local repos from being imported.
- Fix directory traversal vulnerability around uploads routes.
- Fix directory traversal vulnerability around help pages.
- Don't leak existence of project via search autocomplete.
- Don't leak existence of group or project via search.
- Fix bug where Wiki pages that included a '/' were no longer accessible (Stan Hu)
- Fix bug where error messages from Dropzone would not be displayed on the issues page (Stan Hu)
- Add a rake task to check repository integrity with `git fsck`
- Add ability to configure Reply-To address in gitlab.yml (Stan Hu)
- Move current user to the top of the list in assignee/author filters (Stan Hu)
- Fix broken side-by-side diff view on merge request page (Stan Hu)
- Set Application controller default URL options to ensure all url_for calls are consistent (Stan Hu)
- Allow HTML tags in Markdown input
- Fix code unfold not working on Compare commits page (Stan Hu)
- Fix generating SSH key fingerprints with OpenSSH 6.8. (Sašo Stanovnik)
- Fix "Import projects from" button to show the correct instructions (Stan Hu)
- Fix dots in Wiki slugs causing errors (Stan Hu)
- Make maximum attachment size configurable via Application Settings (Stan Hu)
- Update poltergeist to version 1.6.0 to support PhantomJS 2.0 (Zeger-Jan van de Weg)
- Fix cross references when usernames, milestones, or project names contain underscores (Stan Hu)
- Disable reference creation for comments surrounded by code/preformatted blocks (Stan Hu)
- Reduce Rack Attack false positives causing 403 errors during HTTP authentication (Stan Hu)
- enable line wrapping per default and remove the checkbox to toggle it (Hannes Rosenögger)
- Fix a link in the patch update guide
- Add a service to support external wikis (Hannes Rosenögger)
- Omit the "email patches" link and fix plain diff view for merge commits
- List new commits for newly pushed branch in activity view.
- Add sidetiq gem dependency to match EE
- Add changelog, license and contribution guide links to project tab bar.
- Improve diff UI
- Fix alignment of navbar toggle button (Cody Mize)
- Fix checkbox rendering for nested task lists
- Identical look of selectboxes in UI
- Upgrade the gitlab_git gem to version 7.1.3
- Move "Import existing repository by URL" option to button.
- Improve error message when save profile has error.
- Passing the name of pushed ref to CI service (requires GitLab CI 7.9+)
- Add location field to user profile
- Fix print view for markdown files and wiki pages
- Fix errors when deleting old backups
- Improve GitLab performance when working with git repositories
- Add tag message and last commit to tag hook (Kamil Trzciński)
- Restrict permissions on backup files
- Improve oauth accounts UI in profile page
- Add ability to unlink connected accounts
- Replace commits calendar with faster contribution calendar that includes issues and merge requests
- Add inifinite scroll to user page activity
- Don't include system notes in issue/MR comment count.
- Don't mark merge request as updated when merge status relative to target branch changes.
- Link note avatar to user.
- Make Git-over-SSH errors more descriptive.
- Fix EmailsOnPush.
- Refactor issue filtering
- AJAX selectbox for issue assignee and author filters
- Fix issue with missing options in issue filtering dropdown if selected one
- Prevent holding Control-Enter or Command-Enter from posting comment multiple times.
- Prevent note form from being cleared when submitting failed.
- Improve file icons rendering on tree (Sullivan Sénéchal)
- API: Add pagination to project events
- Get issue links in notification mail to work again.
- Don't show commit comment button when user is not signed in.
- Fix admin user projects lists.
- Don't leak private group existence by redirecting from namespace controller to group controller.
- Ability to skip some items from backup (database, repositories or uploads)
- Archive repositories in background worker.
- Import GitHub, Bitbucket or GitLab.com projects owned by authenticated user into current namespace.
- Project labels are now available over the API under the "tag_list" field (Cristian Medina)
- Fixed link paths for HTTP and SSH on the admin project view (Jeremy Maziarz)
- Fix and improve help rendering (Sullivan Sénéchal)
- Fix final line in EmailsOnPush email diff being rendered as error.
- Prevent duplicate Buildkite service creation.
- Fix git over ssh errors 'fatal: protocol error: bad line length character'
- Automatically setup GitLab CI project for forks if origin project has GitLab CI enabled
- Bust group page project list cache when namespace name or path changes.
- Explicitly set image alt-attribute to prevent graphical glitches if gravatars could not be loaded
- Allow user to choose a public email to show on public profile
- Remove truncation from issue titles on milestone page (Jason Blanchard)
- Fix stuck Merge Request merging events from old installations (Ben Bodenmiller)
- Fix merge request comments on files with multiple commits
- Fix Resource Owner Password Authentication Flow
- Add icons to Add dropdown items.
- Allow admin to create public deploy keys that are accessible to any project.
- Warn when gitlab-shell version doesn't match requirement.
- Skip email confirmation when set by admin or via LDAP.
- Only allow users to reference groups, projects, issues, MRs, commits they have access to.

## 7.9.4

- Security: Fix project import URL regex to prevent arbitrary local repos from being imported
- Fixed issue where only 25 commits would load in file listings
- Fix LDAP identities  after config update

## 7.9.3

- Contains no changes

## 7.9.2

- Contains no changes

## 7.9.1

- Include missing events and fix save functionality in admin service template settings form (Stan Hu)
- Fix "Import projects from" button to show the correct instructions (Stan Hu)
- Fix OAuth2 issue importing a new project from GitHub and GitLab (Stan Hu)
- Fix for LDAP with commas in DN
- Fix missing events and in admin Slack service template settings form (Stan Hu)
- Don't show commit comment button when user is not signed in.
- Downgrade gemnasium-gitlab-service gem

## 7.9.0

- Add HipChat integration documentation (Stan Hu)
- Update documentation for object_kind field in Webhook push and tag push Webhooks (Stan Hu)
- Fix broken email images (Hannes Rosenögger)
- Automatically config git if user forgot, where possible (Zeger-Jan van de Weg)
- Fix mass SQL statements on initial push (Hannes Rosenögger)
- Add tag push notifications and normalize HipChat and Slack messages to be consistent (Stan Hu)
- Add comment notification events to HipChat and Slack services (Stan Hu)
- Add issue and merge request events to HipChat and Slack services (Stan Hu)
- Fix merge request URL passed to Webhooks. (Stan Hu)
- Fix bug that caused a server error when editing a comment to "+1" or "-1" (Stan Hu)
- Fix code preview theme setting for comments, issues, merge requests, and snippets (Stan Hu)
- Move labels/milestones tabs to sidebar
- Upgrade Rails gem to version 4.1.9.
- Improve error messages for file edit failures
- Improve UI for commits, issues and merge request lists
- Fix commit comments on first line of diff not rendering in Merge Request Discussion view.
- Allow admins to override restricted project visibility settings.
- Move restricted visibility settings from gitlab.yml into the web UI.
- Improve trigger merge request hook when source project branch has been updated (Kirill Zaitsev)
- Save web edit in new branch
- Fix ordering of imported but unchanged projects (Marco Wessel)
- Mobile UI improvements: make aside content expandable
- Expose avatar_url in projects API
- Fix checkbox alignment on the application settings page.
- Generalize image upload in drag and drop in markdown to all files (Hannes Rosenögger)
- Fix mass-unassignment of issues (Robert Speicher)
- Fix hidden diff comments in merge request discussion view
- Allow user confirmation to be skipped for new users via API
- Add a service to send updates to an Irker gateway (Romain Coltel)
- Add brakeman (security scanner for Ruby on Rails)
- Slack username and channel options
- Add grouped milestones from all projects to dashboard.
- Webhook sends pusher email as well as commiter
- Add Bitbucket omniauth provider.
- Add Bitbucket importer.
- Support referencing issues to a project whose name starts with a digit
- Condense commits already in target branch when updating merge request source branch.
- Send notifications and leave system comments when bulk updating issues.
- Automatically link commit ranges to compare page: sha1...sha4 or sha1..sha4 (includes sha1 in comparison)
- Move groups page from profile to dashboard
- Starred projects page at dashboard
- Blocking user does not remove him/her from project/groups but show blocked label
- Change subject of EmailsOnPush emails to include namespace, project and branch.
- Change subject of EmailsOnPush emails to include first commit message when multiple were pushed.
- Remove confusing footer from EmailsOnPush mail body.
- Add list of changed files to EmailsOnPush emails.
- Add option to send EmailsOnPush emails from committer email if domain matches.
- Add option to disable code diffs in EmailOnPush emails.
- Wrap commit message in EmailsOnPush email.
- Send EmailsOnPush emails when deleting commits using force push.
- Fix EmailsOnPush email comparison link to include first commit.
- Fix highliht of selected lines in file
- Reject access to group/project avatar if the user doesn't have access.
- Add database migration to clean group duplicates with same path and name (Make sure you have a backup before update)
- Add GitLab active users count to rake gitlab:check
- Starred projects page at dashboard
- Make email display name configurable
- Improve json validation in hook data
- Use Emoji One
- Updated emoji help documentation to properly reference EmojiOne.
- Fix missing GitHub organisation repositories on import page.
- Added blue theme
- Remove annoying notice messages when create/update merge request
- Allow smb:// links in Markdown text.
- Filter merge request by title or description at Merge Requests page
- Block user if he/she was blocked in Active Directory
- Fix import pages not working after first load.
- Use custom LDAP label in LDAP signin form.
- Execute hooks and services when branch or tag is created or deleted through web interface.
- Block and unblock user if he/she was blocked/unblocked in Active Directory
- Raise recommended number of unicorn workers from 2 to 3
- Use same layout and interactivity for project members as group members.
- Prevent gitlab-shell character encoding issues by receiving its changes as raw data.
- Ability to unsubscribe/subscribe to issue or merge request
- Delete deploy key when last connection to a project is destroyed.
- Fix invalid Atom feeds when using emoji, horizontal rules, or images (Christian Walther)
- Backup of repositories with tar instead of git bundle (only now are git-annex files included in the backup)
- Add canceled status for CI
- Send EmailsOnPush email when branch or tag is created or deleted.
- Faster merge request processing for large repository
- Prevent doubling AJAX request with each commit visit via Turbolink
- Prevent unnecessary doubling of js events on import pages and user calendar

## 7.8.4

- Fix issue_tracker_id substitution in custom issue trackers
- Fix path and name duplication in namespaces

## 7.8.3

- Bump version of gitlab_git fixing annotated tags without message

## 7.8.2

- Fix service migration issue when upgrading from versions prior to 7.3
- Fix setting of the default use project limit via admin UI
- Fix showing of already imported projects for GitLab and Gitorious importers
- Fix response of push to repository to return "Not found" if user doesn't have access
- Fix check if user is allowed to view the file attachment
- Fix import check for case sensetive namespaces
- Increase timeout for Git-over-HTTP requests to 1 hour since large pulls/pushes can take a long time.
- Properly handle autosave local storage exceptions.
- Escape wildcards when searching LDAP by username.

## 7.8.1

- Fix run of custom post receive hooks
- Fix migration that caused issues when upgrading to version 7.8 from versions prior to 7.3
- Fix the warning for LDAP users about need to set password
- Fix avatars which were not shown for non logged in users
- Fix urls for the issues when relative url was enabled

## 7.8.0

- Fix access control and protection against XSS for note attachments and other uploads.
- Replace highlight.js with rouge-fork rugments (Stefan Tatschner)
- Make project search case insensitive (Hannes Rosenögger)
- Include issue/mr participants in list of recipients for reassign/close/reopen emails
- Expose description in groups API
- Better UI for project services page
- Cleaner UI for web editor
- Add diff syntax highlighting in email-on-push service notifications (Hannes Rosenögger)
- Add API endpoint to fetch all changes on a MergeRequest (Jeroen van Baarsen)
- View note image attachments in new tab when clicked instead of downloading them
- Improve sorting logic in UI and API. Explicitly define what sorting method is used by default
- Fix overflow at sidebar when have several items
- Add notes for label changes in issue and merge requests
- Show tags in commit view (Hannes Rosenögger)
- Only count a user's vote once on a merge request or issue (Michael Clarke)
- Increase font size when browse source files and diffs
- Service Templates now let you set default values for all services
- Create new file in empty repository using GitLab UI
- Ability to clone project using oauth2 token
- Upgrade Sidekiq gem to version 3.3.0
- Stop git zombie creation during force push check
- Show success/error messages for test setting button in services
- Added Rubocop for code style checks
- Fix commits pagination
- Async load a branch information at the commit page
- Disable blacklist validation for project names
- Allow configuring protection of the default branch upon first push (Marco Wessel)
- Add gitlab.com importer
- Add an ability to login with gitlab.com
- Add a commit calendar to the user profile (Hannes Rosenögger)
- Submit comment on command-enter
- Notify all members of a group when that group is mentioned in a comment, for example: `@gitlab-org` or `@sales`.
- Extend issue clossing pattern to include "Resolve", "Resolves", "Resolved", "Resolving" and "Close" (Julien Bianchi and Hannes Rosenögger)
- Fix long broadcast message cut-off on left sidebar (Visay Keo)
- Add Project Avatars (Steven Thonus and Hannes Rosenögger)
- Password reset token validity increased from 2 hours to 2 days since it is also send on account creation.
- Edit group members via API
- Enable raw image paste from clipboard, currently Chrome only (Marco Cyriacks)
- Add action property to merge request hook (Julien Bianchi)
- Remove duplicates from group milestone participants list.
- Add a new API function that retrieves all issues assigned to a single milestone (Justin Whear and Hannes Rosenögger)
- API: Access groups with their path (Julien Bianchi)
- Added link to milestone and keeping resource context on smaller viewports for issues and merge requests (Jason Blanchard)
- Allow notification email to be set separately from primary email.
- API: Add support for editing an existing project (Mika Mäenpää and Hannes Rosenögger)
- Don't have Markdown preview fail for long comments/wiki pages.
- When test webhook - show error message instead of 500 error page if connection to hook url was reset
- Added support for firing system hooks on group create/destroy and adding/removing users to group (Boyan Tabakov)
- Added persistent collapse button for left side nav bar (Jason Blanchard)
- Prevent losing unsaved comments by automatically restoring them when comment page is loaded again.
- Don't allow page to be scaled on mobile.
- Clean the username acquired from OAuth/LDAP so it doesn't fail username validation and block signing up.
- Show assignees in merge request index page (Kelvin Mutuma)
- Link head panel titles to relevant root page.
- Allow users that signed up via OAuth to set their password in order to use Git over HTTP(S).
- Show users button to share their newly created public or internal projects on twitter
- Add quick help links to the GitLab pricing and feature comparison pages.
- Fix duplicate authorized applications in user profile and incorrect application client count in admin area.
- Make sure Markdown previews always use the same styling as the eventual destination.
- Remove deprecated Group#owner_id from API
- Show projects user contributed to on user page. Show stars near project on user page.
- Improve database performance for GitLab
- Add Asana service (Jeremy Benoist)
- Improve project webhooks with extra data

## 7.7.2

- Update GitLab Shell to version 2.4.2 that fixes a bug when developers can push to protected branch
- Fix issue when LDAP user can't login with existing GitLab account

## 7.7.1

- Improve mention autocomplete performance
- Show setup instructions for GitHub import if disabled
- Allow use http for OAuth applications

## 7.7.0

- Import from GitHub.com feature
- Add Jetbrains Teamcity CI service (Jason Lippert)
- Mention notification level
- Markdown preview in wiki (Yuriy Glukhov)
- Raise group avatar filesize limit to 200kb
- OAuth applications feature
- Show user SSH keys in admin area
- Developer can push to protected branches option
- Set project path instead of project name in create form
- Block Git HTTP access after 10 failed authentication attempts
- Updates to the messages returned by API (sponsored by O'Reilly Media)
- New UI layout with side navigation
- Add alert message in case of outdated browser (IE < 10)
- Added API support for sorting projects
- Update gitlab_git to version 7.0.0.rc14
- Add API project search filter option for authorized projects
- Fix File blame not respecting branch selection
- Change some of application settings on fly in admin area UI
- Redesign signin/signup pages
- Close standard input in Gitlab::Popen.popen
- Trigger GitLab CI when push tags
- When accept merge request - do merge using sidaekiq job
- Enable web signups by default
- Fixes for diff comments: drag-n-drop images, selecting images
- Fixes for edit comments: drag-n-drop images, preview mode, selecting images, save & update
- Remove password strength indicator

## 7.6.0

- Fork repository to groups
- New rugged version
- Add CRON=1 backup setting for quiet backups
- Fix failing wiki restore
- Add optional Sidekiq MemoryKiller middleware (enabled via SIDEKIQ_MAX_RSS env variable)
- Monokai highlighting style now more faithful to original design (Mark Riedesel)
- Create project with repository in synchrony
- Added ability to create empty repo or import existing one if project does not have repository
- Reactivate highlight.js language autodetection
- Mobile UI improvements
- Change maximum avatar file size from 100KB to 200KB
- Strict validation for snippet file names
- Enable Markdown preview for issues, merge requests, milestones, and notes (Vinnie Okada)
- In the docker directory is a container template based on the Omnibus packages.
- Update Sidekiq to version 2.17.8
- Add author filter to project issues and merge requests pages
- Atom feed for user activity
- Support multiple omniauth providers for the same user
- Rendering cross reference in issue title and tooltip for merge request
- Show username in comments
- Possibility to create Milestones or Labels when Issues are disabled
- Fix bug with showing gpg signature in tag

## 7.5.3

- Bump gitlab_git to 7.0.0.rc12 (includes Rugged 0.21.2)

## 7.5.2

- Don't log Sidekiq arguments by default
- Fix restore of wiki repositories from backups

## 7.5.1

- Add missing timestamps to 'members' table

## 7.5.0

- API: Add support for Hipchat (Kevin Houdebert)
- Add time zone configuration in gitlab.yml (Sullivan Senechal)
- Fix LDAP authentication for Git HTTP access
- Run 'GC.start' after every EmailsOnPushWorker job
- Fix LDAP config lookup for provider 'ldap'
- Drop all sequences during Postgres database restore
- Project title links to project homepage (Ben Bodenmiller)
- Add Atlassian Bamboo CI service (Drew Blessing)
- Mentioned @user will receive email even if he is not participating in issue or commit
- Session API: Use case-insensitive authentication like in UI (Andrey Krivko)
- Tie up loose ends with annotated tags: API & UI (Sean Edge)
- Return valid json for deleting branch via API (sponsored by O'Reilly Media)
- Expose username in project events API (sponsored by O'Reilly Media)
- Adds comments to commits in the API
- Performance improvements
- Fix post-receive issue for projects with deleted forks
- New gitlab-shell version with custom hooks support
- Improve code
- GitLab CI 5.2+ support (does not support older versions)
- Fixed bug when you can not push commits starting with 000000 to protected branches
- Added a password strength indicator
- Change project name and path in one form
- Display renamed files in diff views (Vinnie Okada)
- Fix raw view for public snippets
- Use secret token with GitLab internal API.
- Add missing timestamps to 'members' table

## 7.4.5

- Bump gitlab_git to 7.0.0.rc12 (includes Rugged 0.21.2)

## 7.4.4

- No changes

## 7.4.3

- Fix raw snippets view
- Fix security issue for member api
- Fix buildbox integration

## 7.4.2

- Fix internal snippet exposing for unauthenticated users

## 7.4.1

- Fix LDAP authentication for Git HTTP access
- Fix LDAP config lookup for provider 'ldap'
- Fix public snippets
- Fix 500 error on projects with nested submodules

## 7.4.0

- Refactored membership logic
- Improve error reporting on users API (Julien Bianchi)
- Refactor test coverage tools usage. Use SIMPLECOV=true to generate it locally
- Default branch is protected by default
- Increase unicorn timeout to 60 seconds
- Sort search autocomplete projects by stars count so most popular go first
- Add README to tab on project show page
- Do not delete tmp/repositories itself during clean-up, only its contents
- Support for backup uploads to remote storage
- Prevent notes polling when there are not notes
- Internal ForkService: Prepare support for fork to a given namespace
- API: Add support for forking a project via the API (Bernhard Kaindl)
- API: filter project issues by milestone (Julien Bianchi)
- Fail harder in the backup script
- Changes to Slack service structure, only webhook url needed
- Zen mode for wiki and milestones (Robert Schilling)
- Move Emoji parsing to html-pipeline-gitlab (Robert Schilling)
- Font Awesome 4.2 integration (Sullivan Senechal)
- Add Pushover service integration (Sullivan Senechal)
- Add select field type for services options (Sullivan Senechal)
- Add cross-project references to the Markdown parser (Vinnie Okada)
- Add task lists to issue and merge request descriptions (Vinnie Okada)
- Snippets can be public, internal or private
- Improve danger zone: ask project path to confirm data-loss action
- Raise exception on forgery
- Show build coverage in Merge Requests (requires GitLab CI v5.1)
- New milestone and label links on issue edit form
- Improved repository graphs
- Improve event note display in dashboard and project activity views (Vinnie Okada)
- Add users sorting to admin area
- UI improvements
- Fix ambiguous sha problem with mentioned commit
- Fixed bug with apostrophe when at mentioning users
- Add active directory ldap option
- Developers can push to wiki repo. Protected branches does not affect wiki repo any more
- Faster rev list
- Fix branch removal

## 7.3.2

- Fix creating new file via web editor
- Use gitlab-shell v2.0.1

## 7.3.1

- Fix ref parsing in Gitlab::GitAccess
- Fix error 500 when viewing diff on a file with changed permissions
- Fix adding comments to MR when source branch is master
- Fix error 500 when searching description contains relative link

## 7.3.0

- Always set the 'origin' remote in satellite actions
- Write authorized_keys in tmp/ during tests
- Use sockets to connect to Redis
- Add dormant New Relic gem (can be enabled via environment variables)
- Expire Rack sessions after 1 week
- Cleaner signin/signup pages
- Improved comments UI
- Better search with filtering, pagination etc
- Added a checkbox to toggle line wrapping in diff (Yuriy Glukhov)
- Prevent project stars duplication when fork project
- Use the default Unicorn socket backlog value of 1024
- Support Unix domain sockets for Redis
- Store session Redis keys in 'session:gitlab:' namespace
- Deprecate LDAP account takeover based on partial LDAP email / GitLab username match
- Use /bin/sh instead of Bash in bin/web, bin/background_jobs (Pavel Novitskiy)
- Keyboard shortcuts for productivity (Robert Schilling)
- API: filter issues by state (Julien Bianchi)
- API: filter issues by labels (Julien Bianchi)
- Add system hook for ssh key changes
- Add blob permalink link (Ciro Santilli)
- Create annotated tags through UI and API (Sean Edge)
- Snippets search (Charles Bushong)
- Comment new push to existing MR
- Add 'ci' to the blacklist of forbidden names
- Improve text filtering on issues page
- Comment & Close button
- Process git push --all much faster
- Don't allow edit of system notes
- Project wiki search (Ralf Seidler)
- Enabled Shibboleth authentication support (Matus Banas)
- Zen mode (fullscreen) for issues/MR/notes (Robert Schilling)
- Add ability to configure webhook timeout via gitlab.yml (Wes Gurney)
- Sort project merge requests in asc or desc order for updated_at or created_at field (sponsored by O'Reilly Media)
- Add Redis socket support to 'rake gitlab:shell:install'

## 7.2.1

- Delete orphaned labels during label migration (James Brooks)
- Security: prevent XSS with stricter MIME types for raw repo files

## 7.2.0

- Explore page
- Add project stars (Ciro Santilli)
- Log Sidekiq arguments
- Better labels: colors, ability to rename and remove
- Improve the way merge request collects diffs
- Improve compare page for large diffs
- Expose the full commit message via API
- Fix 500 error on repository rename
- Fix bug when MR download patch return invalid diff
- Test gitlab-shell integration
- Repository import timeout increased from 2 to 4 minutes allowing larger repos to be imported
- API for labels (Robert Schilling)
- API: ability to set an import url when creating project for specific user

## 7.1.1

- Fix cpu usage issue in Firefox
- Fix redirect loop when changing password by new user
- Fix 500 error on new merge request page

## 7.1.0

- Remove observers
- Improve MR discussions
- Filter by description on Issues#index page
- Fix bug with namespace select when create new project page
- Show README link after description for non-master members
- Add @all mention for comments
- Dont show reply button if user is not signed in
- Expose more information for issues with webhook
- Add a mention of the merge request into the default merge request commit message
- Improve code highlight, introduce support for more languages like Go, Clojure, Erlang etc
- Fix concurrency issue in repository download
- Dont allow repository name start with ?
- Improve email threading (Pierre de La Morinerie)
- Cleaner help page
- Group milestones
- Improved email notifications
- Contributors API (sponsored by Mobbr)
- Fix LDAP TLS authentication (Boris HUISGEN)
- Show VERSION information on project sidebar
- Improve branch removal logic when accept MR
- Fix bug where comment form is spawned inside the Reply button
- Remove Dir.chdir from Satellite#lock for thread-safety
- Increased default git max_size value from 5MB to 20MB in gitlab.yml. Please update your configs!
- Show error message in case of timeout in satellite when create MR
- Show first 100 files for huge diff instead of hiding all
- Change default admin email from admin@local.host to admin@example.com

## 7.0.0

- The CPU no longer overheats when you hold down the spacebar
- Improve edit file UI
- Add ability to upload group avatar when create
- Protected branch cannot be removed
- Developers can remove normal branches with UI
- Remove branch via API (sponsored by O'Reilly Media)
- Move protected branches page to Project settings area
- Redirect to Files view when create new branch via UI
- Drag and drop upload of image in every markdown-area (Earle Randolph Bunao and Neil Francis Calabroso)
- Refactor the markdown relative links processing
- Make it easier to implement other CI services for GitLab
- Group masters can create projects in group
- Deprecate ruby 1.9.3 support
- Only masters can rewrite/remove git tags
- Add X-Frame-Options SAMEORIGIN to Nginx config so Sidekiq admin is visible
- UI improvements
- Case-insensitive search for issues
- Update to rails 4.1
- Improve performance of application for projects and groups with a lot of members
- Formally support Ruby 2.1
- Include Nginx gitlab-ssl config
- Add manual language detection for highlight.js
- Added example.com/:username routing
- Show notice if your profile is public
- UI improvements for mobile devices
- Improve diff rendering performance
- Drag-n-drop for issues and merge requests between states at milestone page
- Fix '0 commits' message for huge repositories on project home page
- Prevent 500 error page when visit commit page from large repo
- Add notice about huge push over http to unicorn config
- File action in satellites uses default 30 seconds timeout instead of old 10 seconds one
- Overall performance improvements
- Skip init script check on omnibus-gitlab
- Be more selective when killing stray Sidekiqs
- Check LDAP user filter during sign-in
- Remove wall feature (no data loss - you can take it from database)
- Dont expose user emails via API unless you are admin
- Detect issues closed by Merge Request description
- Better email subject lines from email on push service (Alex Elman)
- Enable identicon for gravatar be default

## 6.9.2

- Revert the commit that broke the LDAP user filter

## 6.9.1

- Fix scroll to highlighted line
- Fix the pagination on load for commits page

## 6.9.0

- Store Rails cache data in the Redis `cache:gitlab` namespace
- Adjust MySQL limits for existing installations
- Add db index on project_id+iid column. This prevents duplicate on iid (During migration duplicates will be removed)
- Markdown preview or diff during editing via web editor (Evgeniy Sokovikov)
- Give the Rails cache its own Redis namespace
- Add ability to set different ssh host, if different from http/https
- Fix syntax highlighting for code comments blocks
- Improve comments loading logic
- Stop refreshing comments when the tab is hidden
- Improve issue and merge request mobile UI (Drew Blessing)
- Document how to convert a backup to PostgreSQL
- Fix locale bug in backup manager
- Fix can not automerge when MR description is too long
- Fix wiki backup skip bug
- Two Step MR creation process
- Remove unwanted files from satellite working directory with git clean -fdx
- Accept merge request via API (sponsored by O'Reilly Media)
- Add more access checks during API calls
- Block SSH access for 'disabled' Active Directory users
- Labels for merge requests (Drew Blessing)
- Threaded emails by setting a Message-ID (Philip Blatter)

## 6.8.0

- Ability to at mention users that are participating in issue and merge req. discussion
- Enabled GZip Compression for assets in example Nginx, make sure that Nginx is compiled with --with-http_gzip_static_module flag (this is default in Ubuntu)
- Make user search case-insensitive (Christopher Arnold)
- Remove omniauth-ldap nickname bug workaround
- Drop all tables before restoring a Postgres backup
- Make the repository downloads path configurable
- Create branches via API (sponsored by O'Reilly Media)
- Changed permission of gitlab-satellites directory not to be world accessible
- Protected branch does not allow force push
- Fix popen bug in `rake gitlab:satellites:create`
- Disable connection reaping for MySQL
- Allow oauth signup without email for twitter and github
- Fix faulty namespace names that caused 500 on user creation
- Option to disable standard login
- Clean old created archives from repository downloads directory
- Fix download link for huge MR diffs
- Expose event and mergerequest timestamps in API
- Fix emails on push service when only one commit is pushed

## 6.7.3

- Fix the merge notification email not being sent (Pierre de La Morinerie)
- Drop all tables before restoring a Postgres backup
- Remove yanked modernizr gem

## 6.7.2

- Fix upgrader script

## 6.7.1

- Fix GitLab CI integration

## 6.7.0

- Increased the example Nginx client_max_body_size from 5MB to 20MB, consider updating it manually on existing installations
- Add support for Gemnasium as a Project Service (Olivier Gonzalez)
- Add edit file button to MergeRequest diff
- Public groups (Jason Hollingsworth)
- Cleaner headers in Notification Emails (Pierre de La Morinerie)
- Blob and tree gfm links to anchors work
- Piwik Integration (Sebastian Winkler)
- Show contribution guide link for new issue form (Jeroen van Baarsen)
- Fix CI status for merge requests from fork
- Added option to remove issue assignee on project issue page and issue edit page (Jason Blanchard)
- New page load indicator that includes a spinner that scrolls with the page
- Converted all the help sections into markdown
- LDAP user filters
- Streamline the content of notification emails (Pierre de La Morinerie)
- Fixes a bug with group member administration (Matt DeTullio)
- Sort tag names using VersionSorter (Robert Speicher)
- Add GFM autocompletion for MergeRequests (Robert Speicher)
- Add webhook when a new tag is pushed (Jeroen van Baarsen)
- Add button for toggling inline comments in diff view
- Add retry feature for repository import
- Reuse the GitLab LDAP connection within each request
- Changed markdown new line behaviour to conform to markdown standards
- Fix global search
- Faster authorized_keys rebuilding in `rake gitlab:shell:setup` (requires gitlab-shell 1.8.5)
- Create and Update MR calls now support the description parameter (Greg Messner)
- Markdown relative links in the wiki link to wiki pages, markdown relative links in repositories link to files in the repository
- Added Slack service integration (Federico Ravasio)
- Better API responses for access_levels (sponsored by O'Reilly Media)
- Requires at least 2 unicorn workers
- Requires gitlab-shell v1.9+
- Replaced gemoji(due to closed licencing problem) with Phantom Open Emoji library(combined SIL Open Font License, MIT License and the CC 3.0 License)
- Fix `/:username.keys` response content type (Dmitry Medvinsky)

## 6.6.5

- Added option to remove issue assignee on project issue page and issue edit page (Jason Blanchard)
- Hide mr close button for comment form if merge request was closed or inline comment
- Adds ability to reopen closed merge request

## 6.6.4

- Add missing html escape for highlighted code blocks in comments, issues

## 6.6.3

- Fix 500 error when edit yourself from admin area
- Hide private groups for public profiles

## 6.6.2

- Fix 500 error on branch/tag create or remove via UI

## 6.6.1

- Fix 500 error on files tab if submodules presents

## 6.6.0

- Retrieving user ssh keys publically(github style): http://__HOST__/__USERNAME__.keys
- Permissions: Developer now can manage issue tracker (modify any issue)
- Improve Code Compare page performance
- Group avatar
- Pygments.rb replaced with highlight.js
- Improve Merge request diff store logic
- Improve render performances for MR show page
- Fixed Assembla hardcoded project name
- Jira integration documentation
- Refactored app/services
- Remove snippet expiration
- Mobile UI improvements (Drew Blessing)
- Fix block/remove UI for admin::users#show page
- Show users' group membership on users' activity page (Robert Djurasaj)
- User pages are visible without login if user is authorized to a public project
- Markdown rendered headers have id derived from their name and link to their id
- Improve application to work faster with large groups (100+ members)
- Multiple emails per user
- Show last commit for file when view file source
- Restyle Issue#show page and MR#show page
- Ability to filter by multiple labels for Issues page
- Rails version to 4.0.3
- Fixed attachment identifier displaying underneath note text (Jason Blanchard)

## 6.5.1

- Fix branch selectbox when create merge request from fork

## 6.5.0

- Dropdown menus on issue#show page for assignee and milestone (Jason Blanchard)
- Add color custimization and previewing to broadcast messages
- Fixed notes anchors
- Load new comments in issues dynamically
- Added sort options to Public page
- New filters (assigned/authored/all) for Dashboard#issues/merge_requests (sponsored by Say Media)
- Add project visibility icons to dashboard
- Enable secure cookies if https used
- Protect users/confirmation with rack_attack
- Default HTTP headers to protect against MIME-sniffing, force https if enabled
- Bootstrap 3 with responsive UI
- New repository download formats: tar.bz2, zip, tar (Jason Hollingsworth)
- Restyled accept widgets for MR
- SCSS refactored
- Use jquery timeago plugin
- Fix 500 error for rdoc files
- Ability to customize merge commit message (sponsored by Say Media)
- Search autocomplete via ajax
- Add website url to user profile
- Files API supports base64 encoded content (sponsored by O'Reilly Media)
- Added support for Go's repository retrieval (Bruno Albuquerque)

## 6.4.3

- Don't use unicorn worker killer if PhusionPassenger is defined

## 6.4.2

- Fixed wrong behaviour of script/upgrade.rb

## 6.4.1

- Fixed bug with repository rename
- Fixed bug with project transfer

## 6.4.0

- Added sorting to project issues page (Jason Blanchard)
- Assembla integration (Carlos Paramio)
- Fixed another 500 error with submodules
- UI: More compact issues page
- Minimal password length increased to 8 symbols
- Side-by-side diff view (Steven Thonus)
- Internal projects (Jason Hollingsworth)
- Allow removal of avatar (Drew Blessing)
- Project webhooks now support issues and merge request events
- Visiting project page while not logged in will redirect to sign-in instead of 404 (Jason Hollingsworth)
- Expire event cache on avatar creation/removal (Drew Blessing)
- Archiving old projects (Steven Thonus)
- Rails 4
- Add time ago tooltips to show actual date/time
- UI: Fixed UI for admin system hooks
- Ruby script for easier GitLab upgrade
- Do not remove Merge requests if fork project was removed
- Improve sign-in/signup UX
- Add resend confirmation link to sign-in page
- Set noreply@HOSTNAME for reply_to field in all emails
- Show GitLab API version on Admin#dashboard
- API Cross-origin resource sharing
- Show READMe link at project home page
- Show repo size for projects in Admin area

## 6.3.0

- API for adding gitlab-ci service
- Init script now waits for pids to appear after (re)starting before reporting status (Rovanion Luckey)
- Restyle project home page
- Grammar fixes
- Show branches list (which branches contains commit) on commit page (Andrew Kumanyaev)
- Security improvements
- Added support for GitLab CI 4.0
- Fixed issue with 500 error when group did not exist
- Ability to leave project
- You can create file in repo using UI
- You can remove file from repo using UI
- API: dropped default_branch attribute from project during creation
- Project default_branch is not stored in db any more. It takes from repo now.
- Admin broadcast messages
- UI improvements
- Dont show last push widget if user removed this branch
- Fix 500 error for repos with newline in file name
- Extended html titles
- API: create/update/delete repo files
- Admin can transfer project to any namespace
- API: projects/all for admin users
- Fix recent branches order

## 6.2.4

- Security: Cast API private_token to string (CVE-2013-4580)
- Security: Require gitlab-shell 1.7.8 (CVE-2013-4581, CVE-2013-4582, CVE-2013-4583)
- Fix for Git SSH access for LDAP users

## 6.2.3

- Security: More protection against CVE-2013-4489
- Security: Require gitlab-shell 1.7.4 (CVE-2013-4490, CVE-2013-4546)
- Fix sidekiq rake tasks

## 6.2.2

- Security: Update gitlab_git (CVE-2013-4489)

## 6.2.1

- Security: Fix issue with generated passwords for new users

## 6.2.0

- Public project pages are now visible to everyone (files, issues, wik, etc.)
  THIS MEANS YOUR ISSUES AND WIKI FOR PUBLIC PROJECTS ARE PUBLICLY VISIBLE AFTER THE UPGRADE
- Add group access to permissions page
- Require current password to change one
- Group owner or admin can remove other group owners
- Remove group transfer since we have multiple owners
- Respect authorization in Repository API
- Improve UI for Project#files page
- Add more security specs
- Added search for projects by name to api (Izaak Alpert)
- Make default user theme configurable (Izaak Alpert)
- Update logic for validates_merge_request for tree of MR (Andrew Kumanyaev)
- Rake tasks for webhooks management (Jonhnny Weslley)
- Extended User API to expose admin and can_create_group for user creation/updating (Boyan Tabakov)
- API: Remove group
- API: Remove project
- Avatar upload on profile page with a maximum of 100KB (Steven Thonus)
- Store the sessions in Redis instead of the cookie store
- Fixed relative links in markdown
- User must confirm their email if signup enabled
- User must confirm changed email

## 6.1.0

- Project specific IDs for issues, mr, milestones
  Above items will get a new id and for example all bookmarked issue urls will change.
  Old issue urls are redirected to the new one if the issue id is too high for an internal id.
- Description field added to Merge Request
- API: Sudo api calls (Izaak Alpert)
- API: Group membership api (Izaak Alpert)
- Improved commit diff
- Improved large commit handling (Boyan Tabakov)
- Rewrite: Init script now less prone to errors and keeps better track of the service (Rovanion Luckey)
- Link issues, merge requests, and commits when they reference each other with GFM (Ash Wilson)
- Close issues automatically when pushing commits with a special message
- Improve user removal from admin area
- Invalidate events cache when project was moved
- Remove deprecated classes and rake tasks
- Add event filter for group and project show pages
- Add links to create branch/tag from project home page
- Add public-project? checkbox to new-project view
- Improved compare page. Added link to proceed into Merge Request
- Send an email to a user when they are added to group
- New landing page when you have 0 projects

## 6.0.0

- Feature: Replace teams with group membership
  We introduce group membership in 6.0 as a replacement for teams.
  The old combination of groups and teams was confusing for a lot of people.
  And when the members of a team where changed this wasn't reflected in the project permissions.
  In GitLab 6.0 you will be able to add members to a group with a permission level for each member.
  These group members will have access to the projects in that group.
  Any changes to group members will immediately be reflected in the project permissions.
  You can even have multiple owners for a group, greatly simplifying administration.
- Feature: Ability to have multiple owners for group
- Feature: Merge Requests between fork and project (Izaak Alpert)
- Feature: Generate fingerprint for ssh keys
- Feature: Ability to create and remove branches with UI
- Feature: Ability to create and remove git tags with UI
- Feature: Groups page in profile. You can leave group there
- API: Allow login with LDAP credentials
- Redesign: project settings navigation
- Redesign: snippets area
- Redesign: ssh keys page
- Redesign: buttons, blocks and other ui elements
- Add comment title to rss feed
- You can use arrows to navigate at tree view
- Add project filter on dashboard
- Cache project graph
- Drop support of root namespaces
- Default theme is classic now
- Cache result of methods like authorize_projects, project.team.members etc
- Remove $.ready events
- Fix onclick events being double binded
- Add notification level to group membership
- Move all project controllers/views under Projects:: module
- Move all profile controllers/views under Profiles:: module
- Apply user project limit only for personal projects
- Unicorn is default web server again
- Store satellites lock files inside satellites dir
- Disabled threadsafety mode in rails
- Fixed bug with loosing MR comments
- Improved MR comments logic
- Render readme file for projects in public area

## 5.4.2

- Security: Cast API private_token to string (CVE-2013-4580)
- Security: Require gitlab-shell 1.7.8 (CVE-2013-4581, CVE-2013-4582, CVE-2013-4583)

## 5.4.1

- Security: Fixes for CVE-2013-4489
- Security: Require gitlab-shell 1.7.4 (CVE-2013-4490, CVE-2013-4546)

## 5.4.0

- Ability to edit own comments
- Documentation improvements
- Improve dashboard projects page
- Fixed nav for empty repos
- GitLab Markdown help page
- Misspelling fixes
- Added support of unicorn and fog gems
- Added client list to API doc
- Fix PostgreSQL database restoration problem
- Increase snippet content column size
- allow project import via git:// url
- Show participants on issues, including mentions
- Notify mentioned users with email

## 5.3.0

- Refactored services
- Campfire service added
- HipChat service added
- Fixed bug with LDAP + git over http
- Fixed bug with google analytics code being ignored
- Improve sign-in page if ldap enabled
- Respect newlines in wall messages
- Generate the Rails secret token on first run
- Rename repo feature
- Init.d: remove gitlab.socket on service start
- Api: added teams api
- Api: Prevent blob content being escaped
- Api: Smart deploy key add behaviour
- Api: projects/owned.json return user owned project
- Fix bug with team assignation on project from #4109
- Advanced snippets: public/private, project/personal (Andrew Kulakov)
- Repository Graphs (Karlo Nicholas T. Soriano)
- Fix dashboard lost if comment on commit
- Update gitlab-grack. Fixes issue with --depth option
- Fix project events duplicate on project page
- Fix postgres error when displaying network graph.
- Fix dashboard event filter when navigate via turbolinks
- init.d: Ensure socket is removed before starting service
- Admin area: Style teams:index, group:show pages
- Own page for failed forking
- Scrum view for milestone

## 5.2.0

- Turbolinks
- Git over http with ldap credentials
- Diff with better colors and some spacing on the corners
- Default values for project features
- Fixed huge_commit view
- Restyle project clone panel
- Move Gitlab::Git code to gitlab_git gem
- Move update docs in repo
- Requires gitlab-shell v1.4.0
- Fixed submodules listing under file tab
- Fork feature (Angus MacArthur)
- git version check in gitlab:check
- Shared deploy keys feature
- Ability to generate default labels set for issues
- Improve gfm autocomplete (Harold Luo)
- Added support for Google Analytics
- Code search feature (Javier Castro)

## 5.1.0

- You can login with email or username now
- Corrected project transfer rollback when repository cannot be moved
- Move both repo and wiki when project transfer requested
- Admin area: project editing was removed from admin namespace
- Access: admin user has now access to any project.
- Notification settings
- Gitlab::Git set of objects to abstract from grit library
- Replace Unicorn web server with Puma
- Backup/Restore refactored. Backup dump project wiki too now
- Restyled Issues list. Show milestone version in issue row
- Restyled Merge Request list
- Backup now dump/restore uploads
- Improved performance of dashboard (Andrew Kumanyaev)
- File history now tracks renames (Akzhan Abdulin)
- Drop wiki migration tools
- Drop sqlite migration tools
- project tagging
- Paginate users in API
- Restyled network graph (Hiroyuki Sato)

## 5.0.1

- Fixed issue with gitlab-grit being overridden by grit

## 5.0.0

- Replaced gitolite with gitlab-shell
- Removed gitolite-related libraries
- State machine added
- Setup gitlab as git user
- Internal API
- Show team tab for empty projects
- Import repository feature
- Updated rails
- Use lambda for scopes
- Redesign admin area -> users
- Redesign admin area -> user
- Secure link to file attachments
- Add validations for Group and Team names
- Restyle team page for project
- Update capybara, rspec-rails, poltergeist to recent versions
- Wiki on git using Gollum
- Added Solarized Dark theme for code review
- Don't show user emails in autocomplete lists, profile pages
- Added settings tab for group, team, project
- Replace user popup with icons in header
- Handle project moving with gitlab-shell
- Added select2-rails for selectboxes with ajax data load
- Fixed search field on projects page
- Added teams to search autocomplete
- Move groups and teams on dashboard sidebar to sub-tabs
- API: improved return codes and docs. (Felix Gilcher, Sebastian Ziebell)
- Redesign wall to be more like chat
- Snippets, Wall features are disabled by default for new projects

## 4.2.0

- Teams
- User show page. Via /u/username
- Show help contents on pages for better navigation
- Async gitolite calls
- added satellites logs
- can_create_group, can_create_team booleans for User
- Process webhooks async
- GFM: Fix images escaped inside links
- Network graph improved
- Switchable branches for network graph
- API: Groups
- Fixed project download

## 4.1.0

- Optional Sign-Up
- Discussions
- Satellites outside of tmp
- Line numbers for blame
- Project public mode
- Public area with unauthorized access
- Load dashboard events with ajax
- remember dashboard filter in cookies
- replace resque with sidekiq
- fix routing issues
- cleanup rake tasks
- fix backup/restore
- scss cleanup
- show preview for note images
- improved network-graph
- get rid of app/roles/
- added new classes Team, Repository
- Reduce amount of gitolite calls
- Ability to add user in all group projects
- remove deprecated configs
- replaced Korolev font with open font
- restyled admin/dashboard page
- restyled admin/projects page

## 4.0.0

- Remove project code and path from API. Use id instead
- Return valid cloneable url to repo for webhook
- Fixed backup issue
- Reorganized settings
- Fixed commits compare
- Refactored scss
- Improve status checks
- Validates presence of User#name
- Fixed postgres support
- Removed sqlite support
- Modified post-receive hook
- Milestones can be closed now
- Show comment events on dashboard
- Quick add team members via group#people page
- [API] expose created date for hooks and SSH keys
- [API] list, create issue notes
- [API] list, create snippet notes
- [API] list, create wall notes
- Remove project code - use path instead
- added username field to user
- rake task to fill usernames based on emails create namespaces for users
- STI Group < Namespace
- Project has namespace_id
- Projects with namespaces also namespaced in gitolite and stored in subdir
- Moving project to group will move it under group namespace
- Ability to move project from namespaces to another
- Fixes commit patches getting escaped (see #2036)
- Support diff and patch generation for commits and merge request
- MergeReqest doesn't generate a temporary file for the patch any more
- Update the UI to allow downloading Patch or Diff

## 3.1.0

- Updated gems
- Services: GitLab CI integration
- Events filter on dashboard
- Own namespace for redis/resque
- Optimized commit diff views
- add alphabetical order for projects admin page
- Improved web editor
- Commit stats page
- Documentation split and cleanup
- Link to commit authors everywhere
- Restyled milestones list
- added Milestone to Merge Request
- Restyled Top panel
- Refactored Satellite Code
- Added file line links
- moved from capybara-webkit to poltergeist + phantomjs

## 3.0.3

- Fixed bug with issues list in Chrome
- New Feature: Import team from another project

## 3.0.2

- Fixed gitlab:app:setup
- Fixed application error on empty project in admin area
- Restyled last push widget

## 3.0.1

- Fixed git over http

## 3.0.0

- Projects groups
- Web Editor
- Fixed bug with gitolite keys
- UI improved
- Increased performance of application
- Show user avatar in last commit when browsing Files
- Refactored Gitlab::Merge
- Use Font Awesome for icons
- Separate observing of Note and MergeRequests
- Milestone "All Issues" filter
- Fix issue close and reopen button text and styles
- Fix forward/back while browsing Tree hierarchy
- Show number of notes for commits and merge requests
- Added support pg from box and update installation doc
- Reject ssh keys that break gitolite
- [API] list one project hook
- [API] edit project hook
- [API] list project snippets
- [API] allow to authorize using private token in HTTP header
- [API] add user creation

## 2.9.1

- Fixed resque custom config init

## 2.9.0

- fixed inline notes bugs
- refactored rspecs
- refactored gitolite backend
- added factory_girl
- restyled projects list on dashboard
- ssh keys validation to prevent gitolite crash
- send notifications if changed permission in project
- scss refactoring. gitlab_bootstrap/ dir
- fix git push http body bigger than 112k problem
- list of labels  page under issues tab
- API for milestones, keys
- restyled buttons
- OAuth
- Comment order changed

## 2.8.1

- ability to disable gravatars
- improved MR diff logic
- ssh key help page

## 2.8.0

- GitLab Flavored Markdown
- Bulk issues update
- Issues API
- Cucumber coverage increased
- Post-receive files fixed
- UI improved
- Application cleanup
- more cucumber
- capybara-webkit + headless

## 2.7.0

- Issue Labels
- Inline diff
- Git HTTP
- API
- UI improved
- System hooks
- UI improved
- Dashboard events endless scroll
- Source performance increased

## 2.6.0

- UI polished
- Improved network graph + keyboard nav
- Handle huge commits
- Last Push widget
- Bugfix
- Better performance
- Email in resque
- Increased test coverage
- Ability to remove branch with MR accept
- a lot of code refactored

## 2.5.0

- UI polished
- Git blame for file
- Bugfix
- Email in resque
- Better test coverage

## 2.4.0

- Admin area stats page
- Ability to block user
- Simplified dashboard area
- Improved admin area
- Bootstrap 2.0
- Responsive layout
- Big commits handling
- Performance improved
- Milestones

## 2.3.1

- Issues pagination
- ssl fixes
- Merge Request pagination

## 2.3.0

- Dashboard r1
- Search r1
- Project page
- Close merge request on push
- Persist MR diff after merge
- mysql support
- Documentation

## 2.2.0

- We’ve added support of LDAP auth
- Improved permission logic (4 roles system)
- Protected branches (now only masters can push to protected branches)
- Usability improved
- twitter bootstrap integrated
- compare view between commits
- wiki feature
- now you can enable/disable issues, wiki, wall features per project
- security fixes
- improved code browsing (ajax branch switch etc)
- improved per-line commenting
- git submodules displayed
- moved to rails 3.2
- help section improved

## 2.1.0

- Project tab r1
- List branches/tags
- per line comments
- mass user import

## 2.0.0

- gitolite as main git host system
- merge requests
- project/repo access
- link to commit/issue feed
- design tab
- improved email notifications
- restyled dashboard
- bugfix

## 1.2.2

- common config file gitlab.yml
- issues restyle
- snippets restyle
- clickable news feed header on dashboard
- bugfix

## 1.2.1

- bugfix

## 1.2.0

- new design
- user dashboard
- network graph
- markdown support for comments
- encoding issues
- wall like twitter timeline

## 1.1.0

- project dashboard
- wall redesigned
- feature: code snippets
- fixed horizontal scroll on file preview
- fixed app crash if commit message has invalid chars
- bugfix & code cleaning

## 1.0.2

- fixed bug with empty project
- added adv validation for project path & code
- feature: issues can be sortable
- bugfix
- username displayed on top panel

## 1.0.1

- fixed: with invalid source code for commit
- fixed: lose branch/tag selection when use tree navigation
- when history clicked - display path
- bug fix & code cleaning

## 1.0.0

- bug fix
- projects preview mode

## 0.9.6

- css fix
- new repo empty tree until restart server - fixed

## 0.9.4

- security improved
- authorization improved
- html escaping
- bug fix
- increased test coverage
- design improvements

## 0.9.1

- increased test coverage
- design improvements
- new issue email notification
- updated app name
- issue redesigned
- issue can be edit

## 0.8.0

- syntax highlight for main file types
- redesign
- stability
- security fixes
- increased test coverage
- email notification
