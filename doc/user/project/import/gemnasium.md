# Gemnasium

## Why is Gemnasium.com closed?

Gemnasium has been [acquired by GitLab](https://about.gitlab.com/press/releases/2018-01-30-gemnasium-acquisition.html)
in January 2018. Since May 15, 2018, the services provided by Gemnasium are no longer available.
The team behind Gemnasium has joined GitLab as the new Security Products team
and is working on a wider range of tools than just Dependency Scanning:
[SAST](../merge_requests/sast.md),
[DAST](../merge_requests/dast.md),
[Container Scanning](../merge_requests/container_scanning.md) and more.
If you want to continue monitoring your dependencies, see the "Migrating to GitLab"
section below.

## What happened to my account?

Your account has been automatically closed on May 15th, 2018. If you had a paid
subscription at that time your card will be refunded on a pro rata temporis basis.
You may contact us regarding your closed account at gemnasium@gitlab.com.

## Will my account/data be transferred to GitLab?

All accounts and data have been deleted on May 15th. GitLab doesn't know anything
about your private data, nor your projects, and therefore if they were vulnerable
or not. GitLab takes personal information very seriously.

## What happened to my badge?

To avoid broken 404 images, all badges pointing to gemnasium.com will be a
placeholder, inviting you to migrate to GitLab (and pointing to this page).

# Migrating to GitLab

Gemnasium has been ported and integrated directly into GitLab CI/CD.
You can still benefit from our dependency monitoring features, and it requires
some steps to migrate your projects. There is no automatic import since GitLab
doesn't know anything about any projects which existed on Gemnasium.com.
Security features are free for public (open-source) projects hosted on GitLab.com.

## If your project is hosted on GitLab (https://gitlab.com / self-hosted)

You almost set! If you are already using
[Auto DevOps](https://docs.gitlab.com/ee/topics/autodevops/), you are already covered.
Otherwise, you must configure your `.gitlab-ci.yml` according to the
[dependency scanning page](../merge_requests/dependency_scanning.md).


## If your project is hosted on GitHub (https://github.com / GitHub Enterprise)

Since [10.6 coming with GitHub integration](https://about.gitlab.com/features/github/),
GitLab users can now create a CI/CD project in GitLab connected to an external
GitHub.com or GitHub Enterprise code repository. This will automatically prompt
GitLab CI/CD to run whenever code is pushed to GitHub and post CI/CD results
back to both GitLab and GitHub when completed.

### Getting started

Create a new project, and select the "CI/CD for external repo" tab:

![Create new Project](img/gemnasium/create_project.png)

Use the "GitHub" button to connect your repositories.

![Connect from GitHub](img/gemnasium/connect_github.png)

Select the project(s) to be set up with GitLab CI/CD:

![Select projects](img/gemnasium/select_project.png)

and chose "Connect". Once the configuration is done, you may click on your new
project on GitLab:

![click on connected project](img/gemnasium/project_connected.png)

Your project is now mirrored on GitLab, where the runners will be able to access
your source code and run your tests.

Optional step: Make sure the project is public (in the project settings) if your
GitHub project is public unless the security feature will be available only for paid accounts.

To set up the dependency scanning job, corresponding to what Gemnasium what doing,
you must create a `.gitlab-ci.yml` file, or update it according to
https://docs.gitlab.com/ee/user/project/merge_requests/dependency_scanning.html.
The mirroring is pull-only by default, so you may create or update the file on GitHub:

![Edit gitlab-ci.yml file](img/gemnasium/edit_gitlab-ci.png)

Once your file has been committed, a new pipeline will be automatically
triggered if your file is valid:

![pipeline](img/gemnasium/pipeline.png)

The result of the job will be visible directly from the pipeline view:

![security report](img/gemnasium/report.png)

If you don't commit very often to your project, you may want to use
[Scheduled pipelines](../pipelines/schedules.html)
to run the job on a regular basis.
