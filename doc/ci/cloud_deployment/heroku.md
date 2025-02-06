---
stage: Deploy
group: Environments
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Use GitLab CI/CD to deploy to Heroku
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

You can deploy an application to Heroku by using GitLab CI/CD.

## Prerequisites

- A [Heroku](https://id.heroku.com/login) account.
  Sign in with an existing Heroku account or create a new one.

## Deploy to Heroku

1. In Heroku:
   1. Create an application and copy the application name.
   1. Browse to **Account Settings** and copy the API key.
1. In your GitLab project, create two [variables](../variables/_index.md):
   - `HEROKU_APP_NAME` for the application name.
   - `HEROKU_PRODUCTION_KEY` for the API key
1. Edit your `.gitlab-ci.yml` file to add the Heroku deployment command. This example uses the `dpl` gem for Ruby:

   ```yaml
   heroku_deploy:
     stage: production
     script:
       - gem install dpl
       - dpl --provider=heroku --app=$HEROKU_APP_NAME --api-key=$HEROKU_PRODUCTION_KEY
   ```
