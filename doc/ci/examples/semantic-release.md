---
stage: Package
group: Package Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Publish npm packages to the GitLab package registry using semantic-release
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

This guide demonstrates how to automatically publish npm packages to the [GitLab package registry](../../user/packages/npm_registry/_index.md) by using [semantic-release](https://github.com/semantic-release/semantic-release).

You can also view or fork the complete [example source](https://gitlab.com/gitlab-examples/semantic-release-npm).

## Initialize the module

1. Open a terminal and go to the project's repository.
1. Run `npm init`. Name the module according to [the package registry's naming conventions](../../user/packages/npm_registry/_index.md#naming-convention). For example, if the project's path is `gitlab-examples/semantic-release-npm`, name the module `@gitlab-examples/semantic-release-npm`.

1. Install the following npm packages:

   ```shell
   npm install semantic-release @semantic-release/git @semantic-release/gitlab @semantic-release/npm --save-dev
   ```

1. Add the following properties to the module's `package.json`:

   ```json
   {
     "scripts": {
       "semantic-release": "semantic-release"
     },
     "publishConfig": {
       "access": "public"
     },
     "files": [ <path(s) to files here> ]
   }
   ```

1. Update the `files` key with glob patterns that selects all files that should be included in the published module. More information about `files` can be found [in the npm documentation](https://docs.npmjs.com/cli/v6/configuring-npm/package-json/#files).

1. Add a `.gitignore` file to the project to avoid committing `node_modules`:

   ```plaintext
   node_modules
   ```

## Configure the pipeline

Create a `.gitlab-ci.yml` with the following content:

```yaml
default:
  image: node:latest
  before_script:
    - npm ci --cache .npm --prefer-offline
    - |
      {
        echo "@${CI_PROJECT_ROOT_NAMESPACE}:registry=${CI_API_V4_URL}/projects/${CI_PROJECT_ID}/packages/npm/"
        echo "${CI_API_V4_URL#https?}/projects/${CI_PROJECT_ID}/packages/npm/:_authToken=\${CI_JOB_TOKEN}"
      } | tee -a .npmrc
  cache:
    key: ${CI_COMMIT_REF_SLUG}
    paths:
      - .npm/

workflow:
  rules:
    - if: $CI_COMMIT_BRANCH

variables:
  NPM_TOKEN: ${CI_JOB_TOKEN}

stages:
  - release

publish:
  stage: release
  script:
    - npm run semantic-release
  rules:
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH
```

This example configures the pipeline with a single job, `publish`, which runs `semantic-release`. The semantic-release library publishes new versions of the npm package and creates new GitLab releases (if necessary).

The default `before_script` generates a temporary `.npmrc` that is used to authenticate to the package registry during the `publish` job.

## Set up CI/CD variables

As part of publishing a package, semantic-release increases the version number in `package.json`. For semantic-release to commit this change and push it back to GitLab, the pipeline requires a custom CI/CD variable named `GITLAB_TOKEN`. To create this variable:

<!-- markdownlint-disable MD044 -->

1. Open the left sidebar.
1. Select **Settings > Access tokens**.
1. In your project, select **Add new token**.
1. In the **Token name** box, enter a token name.
1. Under **Select scopes**, select the **api** checkbox.
1. Select **Create project access token**.
1. Copy the token value.
1. On the left sidebar, select **Settings > CI/CD**.
1. Expand **Variables**.
1. Select **Add variable**.
1. Under **Visibility**, select **Masked**.
1. In the **Key** box, enter `GITLAB_TOKEN`.
1. In the **Value** box, enter the token value.
1. Select **Add variable**.
<!-- markdownlint-enable MD044 -->

## Configure semantic-release

semantic-release pulls its configuration information from a `.releaserc.json` file in the project. Create a `.releaserc.json` at the root of the repository:

```json
{
  "branches": ["main"],
  "plugins": [
    "@semantic-release/commit-analyzer",
    "@semantic-release/release-notes-generator",
    "@semantic-release/gitlab",
    "@semantic-release/npm",
    [
      "@semantic-release/git",
      {
        "assets": ["package.json"],
        "message": "chore(release): ${nextRelease.version} [skip ci]\n\n${nextRelease.notes}"
      }
    ]
  ]
}
```

In the previous semantic-release configuration example, you can change the branch name to your project's default branch.

## Begin publishing releases

Test the pipeline by creating a commit with a message like:

```plaintext
fix: testing patch releases
```

Push the commit to the default branch. The pipeline should create a new release (`v1.0.0`) on the project's **Releases** page and publish a new version of the package to the project's **Package Registry** page.

To create a minor release, use a commit message like:

```plaintext
feat: testing minor releases
```

Or, for a breaking change:

```plaintext
feat: testing major releases

BREAKING CHANGE: This is a breaking change.
```

More information about how commit messages are mapped to releases can be found in [semantic-releases's documentation](https://github.com/semantic-release/semantic-release#how-does-it-work).

## Use the module in a project

To use the published module, add an `.npmrc` file to the project that depends on the module. For example, to use [the example project](https://gitlab.com/gitlab-examples/semantic-release-npm)'s module:

```plaintext
@gitlab-examples:registry=https://gitlab.com/api/v4/packages/npm/
```

Then, install the module:

```shell
npm install --save @gitlab-examples/semantic-release-npm
```

## Troubleshooting

### Deleted Git tags reappear

A [Git tag](../../user/project/repository/tags/_index.md) deleted from the repository
can sometimes be recreated by `semantic-release` when GitLab runners use a cached
version of the repository. If the job runs on a runner with a cached repository that
still has the tag, `semantic-release` recreates the tag in the main repository.

To avoid this behavior, you can either:

- Configure the runner with [`GIT_STRATEGY: clone`](../runners/configure_runners.md#git-strategy).
- Include the [`git fetch --prune-tags` command](https://git-scm.com/docs/git-fetch#Documentation/git-fetch.txt---prune-tags)
  in your CI/CD script.
