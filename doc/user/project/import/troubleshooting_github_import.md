---
stage: Foundations
group: Import and Integrate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Troubleshooting importing a project from GitHub to GitLab
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

When importing a project from GitHub to GitLab, you might encounter the following issues.

## Manually continue a previously failed import process

In some cases, the GitHub import process can fail to import the repository. This causes GitLab to abort the project import process and requires the
repository to be imported manually. Administrators can manually import the repository for a failed import process:

1. Open a Rails console.
1. Run the following series of commands in the console:

   ```ruby
   project_id = <PROJECT_ID>
   github_access_token =  <GITHUB_ACCESS_TOKEN>
   github_repository_path = '<GROUP>/<REPOSITORY>'

   github_repository_url = "https://#{github_access_token}@github.com/#{github_repository_path}.git"

   # Find project by ID
   project = Project.find(project_id)
   # Set import URL and credentials
   project.import_url = github_repository_url
   project.import_type = 'github'
   project.import_source = github_repository_path
   project.save!
   # Create an import state if the project was created manually and not from a failed import
   project.create_import_state if project.import_state.blank?
   # Set state to start
   project.import_state.force_start

   # Optional: If your import had certain optional stages selected or a timeout strategy
   # set, you can reset them here. Below is an example.
   # The params follow the format documented in the API:
   # https://docs.gitlab.com/ee/api/import.html#import-repository-from-github
   Gitlab::GithubImport::Settings
   .new(project)
   .write(
     timeout_strategy: "optimistic",
     optional_stages: {
       single_endpoint_issue_events_import: true,
       single_endpoint_notes_import: true,
       attachments_import: true,
       collaborators_import: true
     }
   )

   # Trigger import from second step
   Gitlab::GithubImport::Stage::ImportRepositoryWorker.perform_async(project.id)
   ```

## Import fails due to missing prefix

In GitLab 16.5 and later, you might get an error that states `Import failed due to a GitHub error: (HTTP 406)`.

This issue occurs because, in GitLab 16.5, the path prefix `api/v3` was removed from the GitHub importer. This happened because the importer stopped using the `Gitlab::LegacyGithubImport::Client`. This client automatically added the `api/v3` prefix on imports from a GitHub Enterprise URL.

To work around this error, [add the `api/v3` prefix](https://gitlab.com/gitlab-org/gitlab/-/issues/438358#note_1978902725) when importing from a GitHub Enterprise URL.

## Errors when importing large projects

The GitHub importer might encounter some errors when importing large projects.

### Missing comments

The GitHub API has a limit that prevents more than approximately 30,000 notes or diff notes from being imported.
When this limit is reached, the GitHub API instead returns the following error:

```plaintext
In order to keep the API fast for everyone, pagination is limited for this resource. Check the rel=last link relation in the Link response header to see how far back you can traverse.
```

When importing GitHub projects with a large number of comments, select the **Use alternative comments import method**
[additional item to import](github.md#select-additional-items-to-import) checkbox. This setting makes the import process take longer because it increases the number of network requests
required to perform the import.

## GitLab instance cannot connect to GitHub

Self-managed instances that run GitLab 15.10 or earlier, and are behind proxies, cannot resolve DNS for `github.com` or `api.github.com`.
The GitLab instance fails to connect to GitHub during the import and you must add `github.com` and `api.github.com`
entries in the [allowlist for local requests](../../../security/webhooks.md#allow-outbound-requests-to-certain-ip-addresses-and-domains).
