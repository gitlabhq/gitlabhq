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
- Default extention for wiki pages is now .md instead of .markdown (Jeroen van Baarsen)
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
- Fix project import URL regex to prevent arbitary local repos from being imported.
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
- Ability to skip some items from backup (database, respositories or uploads)
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

- Security: Fix project import URL regex to prevent arbitary local repos from being imported
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
- Case-insensetive search for issues
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
- Improve render performnace for MR show page
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
- Services: Gitlab CI integration
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

- Gitlab Flavored Markdown
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
