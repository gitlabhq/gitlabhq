---
stage: Plan
group: Knowledge
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: 'Tutorial: Build, test, and deploy your Hugo site with GitLab'
---

<!-- vale gitlab_base.FutureTense = NO -->

This tutorial walks you through creating a CI/CD pipeline to build, test, and deploy a Hugo site.

By the end of the tutorial, you'll have a working pipeline and a Hugo site deployed on GitLab Pages.

Here's an overview of what you're going to do:

1. Prepare your Hugo site.
1. Create a GitLab project.
1. Push your Hugo site to GitLab.
1. Build your Hugo site with a CI/CD pipeline.
1. Deploy and view your Hugo site with GitLab Pages.

## Before you begin

- An account on GitLab.com.
- Familiarity with Git.
- A Hugo site (if you don't already have one, you can follow the [Hugo Quick Start](https://gohugo.io/getting-started/quick-start/)).

## Prepare your Hugo site

First, make sure your Hugo site is ready to push to GitLab. You need to have your content, a theme, and a configuration file.

Don't *build* your site, as GitLab does that for you. In fact, it's important to **not** upload your `public` folder, as this can cause conflicts later on.

The easiest way to exclude your `public` folder is by creating a `.gitignore` file and adding your `public` folder to it.

You can do this with the following command at the top level of your Hugo project:

```shell
echo "/public/" >> .gitignore
```

This either adds `/public/` to a new `.gitignore` file or appends it to an existing file.

OK, your Hugo site is ready to push, after you create a GitLab project.

## Create a GitLab project

If you haven't done so already, create a blank GitLab project for your Hugo site.

To create a blank project, in GitLab:

1. On the left sidebar, at the top, select **Create new** (**{plus}**) and **New project/repository**.
1. Select **Create blank project**.
1. Enter the project details:
   - In the **Project name** field, enter the name of your project. The name must start with a lowercase or uppercase letter (`a-zA-Z`), digit (`0-9`), emoji, or underscore (`_`). It can also contain dots (`.`), pluses (`+`), dashes (`-`), or spaces.
   - In the **Project slug** field, enter the path to your project. The GitLab instance uses the slug as the URL path to the project. To change the slug, first enter the project name, then change the slug.
   - The **Visibility Level** can be either Private or Public. If you choose Private, your website is still publicly available, but your code remains private.
   - Because you're pushing an existing repository, clear the box to **Initialize repository with a README**.
1. When you're ready, select **Create project**.
1. You should see instructions for pushing your code to this new project. You'll need those instructions in the next step.

You now have a home for your Hugo site!

## Push your Hugo site to GitLab

Next you need to push your local Hugo site to your remote GitLab project.

If you created a new GitLab project in the previous step, you'll see the instructions for initializing your repository, then committing and pushing your files.

Otherwise, make sure the remote origin for your local Git repository matches your GitLab project.

Assuming your default branch is `main`, you can push your Hugo site with the following command:

```shell
git push origin main
```

After you've pushed your site, you should see all the content except the `public` folder. The `public` folder was excluded by the `.gitignore` file.

In the next step, you'll use a CI/CD pipeline to build your site and recreate that `public` folder.

## Build your Hugo site

To build a Hugo site with GitLab, you first need to create a `.gitlab-ci.yml` file to specify instructions for the CI/CD pipeline. If you've not done this before, it might sound daunting. However, GitLab provides everything you need.

### Add your configuration options

You specify your configuration options in a special file called `.gitlab-ci.yml`. To create a `.gitlab-ci.yml` file:

1. On the left sidebar, select **Code > Repository**.
1. Above the file list, select the plus icon ( + ), then select **New file** from the dropdown list.
1. For the filename, enter `.gitlab-ci.yml`. Don't omit the period at the beginning.
1. Select the **Apply a template** dropdown list, then enter "Hugo" in the filter box.
1. Select the result **Hugo**, and your file is populated with all the code you need to build your Hugo site using CI/CD.

Let's take a closer look at what's happening in this `.gitlab-ci.yml` file.

```yaml
default:
  image: "${CI_TEMPLATE_REGISTRY_HOST}/pages/hugo:latest"

variables:
  GIT_SUBMODULE_STRATEGY: recursive

test:  # builds and tests your site
  script:
    - hugo
  rules:
    - if: $CI_COMMIT_BRANCH != $CI_DEFAULT_BRANCH

deploy-pages:  # a user-defined job that builds your pages and saves them to the specified path.
  script:
    - hugo
  pages: true  # specifies that this is a Pages job
  artifacts:
    paths:
      - public
  rules:
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH
  environment: production
```

- `image` specifies an image from the GitLab Registry that contains Hugo. This image is used to create the environment where your site is built.
- The `GIT_SUBMODULE_STRATEGY` variable ensures GitLab also looks at your Git submodules, which are sometimes used for Hugo themes.
- `test` is a job where you can run tests on your Hugo site before it's deployed. The test job runs in all cases, *except* if you're committing a change to your default branch. You place any commands under `script`. The command in this job - `hugo`- builds your site so it can be tested.
- `deploy-pages` is a user-defined job for creating pages from Static Site Generators. Again, this job uses
  [user-defined job names](../../user/project/pages/_index.md#user-defined-job-names) and runs the `hugo` command to
  build your site. Then `pages: true` specifies that this is a Pages job and `artifacts` specifies that those resulting pages are added to a directory called `public`. With
  `rules`, you're checking that this commit was made on the default branch. Typically, you wouldn't want to build and
  deploy the live site from another branch.

You don't need to add anything else to this file. When you're ready, select **Commit changes** at the top of the page.

You've just triggered a pipeline to build your Hugo site!

## Deploy and view your Hugo site

If you're quick, you can see GitLab build and deploy your site.

From the left-hand navigation, select **Build > Pipelines**.

You'll see that GitLab has run your `test` and `deploy-pages` jobs.

To view your site, on the left-hand navigation, select **Deploy > Pages**

The `pages` job in your pipeline has deployed the contents of your `public` directory to GitLab Pages. Under **Access pages**, you should see the link in the format: `https://<your-namespace>.gitlab.io/<project-path>`.

You won't see this link if you haven't yet run your pipeline.

Select the displayed link to view your site.

When you first view your Hugo site, the stylesheet won't work. Don't worry, you need to make a small change in your Hugo configuration file. Hugo needs to know the URL of your GitLab Pages site so it can build relative links to stylesheets and other assets:

1. In your local Hugo site, pull the latest changes, and open your `config.yaml` or `config.toml` file.
1. Change the value of the `BaseURL` parameter to match the URL that appears in your GitLab Pages settings.
1. Push your changed file to GitLab, and your pipeline is triggered again.

When the pipeline has finished, your site should be working at the URL you just specified.

If your Hugo site is stored in a private repository, you'll need to change your permissions so the Pages site is visible. Otherwise, it's visible only to authorized users. To change your permissions:

1. Go to **Settings > General > Visibility, project features, permissions**.
1. Scroll down to the **Pages** section and select **Everyone** from the dropdown list.
1. Select **Save changes**.

Now everyone can see it.

You've built, tested, and deployed your Hugo site with GitLab. Great work!

Every time you change your site and push it to GitLab, your site is built, tested, and deployed automatically.

To learn more about CI/CD pipelines, try [this tutorial on how to create a complex pipeline](../../ci/quick_start/tutorial.md). You can also learn more about the [different types of testing available](../../ci/testing/_index.md).
