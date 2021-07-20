---
stage: Package
group: Package
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Publish npm packages to the GitLab Package Registry using semantic-release **(FREE)**

This guide demonstrates how to automatically publish npm packages to the [GitLab Package Registry](../../user/packages/npm_registry/index.md) by using [semantic-release](https://github.com/semantic-release/semantic-release).

You can also view or fork the complete [example source](https://gitlab.com/gitlab-examples/semantic-release-npm).

## Initialize the module

1. Open a terminal and navigate to the project's repository
1. Run `npm init`. Name the module according to [the Package Registry's naming conventions](../../user/packages/npm_registry/index.md#package-naming-convention). For example, if the project's path is `gitlab-examples/semantic-release-npm`, name the module `@gitlab-examples/semantic-release-npm`.

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

1. Update the `files` key with glob pattern(s) that selects all files that should be included in the published module. More information about `files` can be found [in npm's documentation](https://docs.npmjs.com/cli/v6/configuring-npm/package-json/#files).

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
      } | tee --append .npmrc
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

The default `before_script` generates a temporary `.npmrc` that is used to authenticate to the Package Registry during the `publish` job.

## Set up CI/CD variables

As part of publishing a package, semantic-release increases the version number in `package.json`. For semantic-release to commit this change and push it back to GitLab, the pipeline requires a custom CI/CD variable named `GITLAB_TOKEN`. To create this variable:

1. Navigate to **Project > Settings > Access Tokens**.
1. Give the token a name, and select the `api` scope.
1. Click **Create project access token** and copy its value.
1. Navigate to **Project > Settings > CI/CD > Variables**.
1. Click **Add Variable**.
1. In the **Key** field, enter `GITLAB_TOKEN`. In the **Value** field, paste the token created above. Check the **Mask variable** option and click **Add variable**.

## Configure semantic-release

semantic-release pulls its configuration information from a `.releaserc.json` file in the project. Create a `.releaserc.json` at the root of the repository:

```json
{
  "branches": ["master"],
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
