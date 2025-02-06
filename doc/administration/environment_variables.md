---
stage: Systems
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Environment variables
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab Self-Managed

GitLab exposes certain environment variables which can be used to override
their defaults values.

People usually configure GitLab with:

- `/etc/gitlab/gitlab.rb` for Linux package installations.
- `gitlab.yml` for self-compiled installations.

You can use the following environment variables to override certain values:

## Supported environment variables

| Variable                                   | Type    | Description |
|--------------------------------------------|---------|-------------|
| `DATABASE_URL`                             | string  | The database URL; is of the form: `postgresql://localhost/blog_development`. |
| `ENABLE_BOOTSNAP`                          | string  | Toggles [Bootsnap](https://github.com/Shopify/bootsnap) for speeding up initial Rails boot. Enabled by default for non-production environments. Set to `0` to disable. |
| `EXTERNAL_URL`                             | string  | Specify the external URL at the [time of installation](https://docs.gitlab.com/omnibus/settings/configuration.html#specifying-the-external-url-at-the-time-of-installation). |
| `EXTERNAL_VALIDATION_SERVICE_TIMEOUT`      | integer | Timeout, in seconds, for an [external CI/CD pipeline validation service](cicd/external_pipeline_validation.md). Default is `5`. |
| `EXTERNAL_VALIDATION_SERVICE_URL`          | string  | URL to an [external CI/CD pipeline validation service](cicd/external_pipeline_validation.md). |
| `EXTERNAL_VALIDATION_SERVICE_TOKEN`        | string  | The `X-Gitlab-Token` for authentication with an [external CI/CD pipeline validation service](cicd/external_pipeline_validation.md). |
| `GITLAB_CDN_HOST`                          | string  | Sets the base URL for a CDN to serve static assets (for example, `https://mycdnsubdomain.fictional-cdn.com`). |
| `GITLAB_EMAIL_DISPLAY_NAME`                | string  | The name used in the **From** field in emails sent by GitLab. |
| `GITLAB_EMAIL_FROM`                        | string  | The email address used in the **From** field in emails sent by GitLab. |
| `GITLAB_EMAIL_REPLY_TO`                    | string  | The email address used in the **Reply-To** field in emails sent by GitLab. |
| `GITLAB_EMAIL_SUBJECT_SUFFIX`              | string  | The email subject suffix used in emails sent by GitLab. |
| `GITLAB_HOST`                              | string  | The full URL of the GitLab server (including `http://` or `https://`). |
| `GITLAB_MARKUP_TIMEOUT`                    | string  | Timeout, in seconds, for `rest2html` and `pod2html` commands executed by the [`gitlab-markup` gem](https://gitlab.com/gitlab-org/gitlab-markup/). Default is `10`. |
| `GITLAB_ROOT_PASSWORD`                     | string  | Sets the password for the `root` user on installation. |
| `GITLAB_SHARED_RUNNERS_REGISTRATION_TOKEN` | string  | Sets the initial registration token used for runners. [Deprecated in GitLab 16.11](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/148310). |
| `RAILS_ENV`                                | string  | The Rails environment; can be one of `production`, `development`, `staging`, or `test`. |
| `GITLAB_RAILS_CACHE_DEFAULT_TTL_SECONDS`   | integer | The default TTL used for entries stored in the Rails-cache. Default is `28800`. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/95042) in 15.3. |
| `GITLAB_CI_CONFIG_FETCH_TIMEOUT_SECONDS`   | integer | Timeout for resolving remote includes in CI config in seconds. Must be between `0` and `60`. Default is `30`. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/116383) in 15.11. |
| `GITLAB_DISABLE_MARKDOWN_TIMEOUT`          | string  | If set to `true`, `1`, or `yes`, Markdown rendering on the backend does not time out. Default is `false`. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/163662) in 17.4. |
| `GITLAB_LFS_LINK_BATCH_SIZE`               | integer | Sets the batch size for linking LFS files. Default is `1000`. |
| `GITLAB_LFS_MAX_OID_TO_FETCH`              | integer | Sets the maximum number of LFS objects to link. Default is `100,000`. |
| `SIDEKIQ_SEMI_RELIABLE_FETCH_TIMEOUT`      | integer | Sets the timeout for Sidekiq semi-reliable fetch. Default is `5`. [Before GitLab 16.7](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/139583), default was `3`. If you experience high Redis CPU consumption on GitLab 16.6 and earlier, or if you have customized this variable, you should update this variable to `5`. |

## Adding more variables

We welcome merge requests to make more settings configurable by using variables.
Make changes to the `config/initializers/1_settings.rb` file, and use the
naming scheme `GITLAB_#{name in 1_settings.rb in upper case}`.

## Linux package installation configuration

To set environment variables, follow [these instructions](https://docs.gitlab.com/omnibus/settings/environment-variables.html).

It's possible to preconfigure the GitLab Docker image by adding the environment
variable `GITLAB_OMNIBUS_CONFIG` to the `docker run` command.
For more information, see [Pre-configure Docker container](../install/docker/configuration.md#pre-configure-docker-container).
