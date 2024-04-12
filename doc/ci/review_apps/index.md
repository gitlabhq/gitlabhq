---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Review apps

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, Self-managed, GitLab Dedicated

Review apps are a collaboration tool that provide an environment to showcase product changes.

NOTE:
If you have a Kubernetes cluster, you can automate this feature in your applications
by using [Auto DevOps](../../topics/autodevops/index.md).

Review apps:

- Provide an automatic live preview of changes made in a feature branch by spinning up a dynamic environment for your merge requests.
- Allow designers and product managers to see your changes without needing to check out your branch and run your changes in a sandbox environment.
- Are fully integrated with the [GitLab DevOps LifeCycle](https://about.gitlab.com/stages-devops-lifecycle/).
- Allow you to deploy your changes wherever you want.

![review apps workflow](img/continuous-delivery-review-apps.svg)

In the previous example:

- A review app is built every time a commit is pushed to `topic branch`.
- The reviewer fails two reviews before passing the third review.
- After the review passes, `topic branch` is merged into the default branch, where it's deployed to staging.
- After its approval in staging, the changes that were merged into the default branch are deployed to production.

## How review apps work

A review app is a mapping of a branch with an [environment](../environments/index.md).
Access to the review app is made available as a link on the [merge request](../../user/project/merge_requests/index.md) relevant to the branch.

The following is an example of a merge request with an environment set dynamically.

![review app in merge request](img/review_apps_preview_in_mr_v16_0.png)

In this example, a branch was:

- Successfully built.
- Deployed under a dynamic environment that can be reached by selecting **View app**.

After adding review apps to your workflow, you follow the branched Git flow. That is:

1. Push a branch and let the runner deploy the review app based on the `script` definition of the dynamic environment job.
1. Wait for the runner to build and deploy your web application.
1. To view the changes live, select the link in the merge request related to the branch.

## Configuring review apps

Review apps are built on [dynamic environments](../environments/index.md#create-a-dynamic-environment), which allow you to dynamically create a new environment for each branch.

The process of configuring review apps is as follows:

1. Set up the infrastructure to host and deploy the review apps (check the [examples](#review-apps-examples) below).
1. [Install](https://docs.gitlab.com/runner/install/) and [configure](https://docs.gitlab.com/runner/commands/) a runner to do deployment.
1. Set up a job in `.gitlab-ci.yml` that uses the [predefined CI/CD variable](../variables/index.md) `${CI_COMMIT_REF_SLUG}`
   to create dynamic environments and restrict it to run only on branches.
   Alternatively, you can get a YAML template for this job by [enabling review apps](#enable-review-apps-button) for your project.
1. Optionally, set a job that [manually stops](../environments/index.md#stopping-an-environment) the review apps.

### Enable review apps button

When configuring review apps for a project, you add a new job to the `.gitlab-ci.yml` file,
as mentioned above. To facilitate this, and if you are using Kubernetes, you can select
**Enable review apps** and GitLab prompts you with a template code block that
you can copy and paste into `.gitlab-ci.yml` as a starting point.

Prerequisites:

- You need at least the Developer role for the project.

To use the review apps template:

1. On the left sidebar, select **Search or go to** and
   find the project you want to create a review app job for.
1. Select **Operate > Environments**.
1. Select **Enable review apps**.
1. Copy the provided code snippet and paste it into your
   `.gitlab-ci.yml` file:

   ![enable review apps modal](img/enable_review_app_v16.png)

You can edit this template as needed.

## Review apps auto-stop

See how to [configure review apps environments to expire and auto-stop](../environments/index.md#stop-an-environment-after-a-certain-time-period)
after a given period of time.

## Review apps examples

The following are example projects that demonstrate review app configuration:

| Project                                                                 | Configuration file |
|-------------------------------------------------------------------------|--------------------|
| [NGINX](https://gitlab.com/gitlab-examples/review-apps-nginx)           | [`.gitlab-ci.yml`](https://gitlab.com/gitlab-examples/review-apps-nginx/-/blob/b9c1f6a8a7a0dfd9c8784cbf233c0a7b6a28ff27/.gitlab-ci.yml#L20) |
| [OpenShift](https://gitlab.com/gitlab-examples/review-apps-openshift)   | [`.gitlab-ci.yml`](https://gitlab.com/gitlab-examples/review-apps-openshift/-/blob/82ebd572334793deef2d5ddc379f38942f3488be/.gitlab-ci.yml#L42) |
| [HashiCorp Nomad](https://gitlab.com/gitlab-examples/review-apps-nomad) | [`.gitlab-ci.yml`](https://gitlab.com/gitlab-examples/review-apps-nomad/-/blob/ca372c778be7aaed5e82d3be24e98c3f10a465af/.gitlab-ci.yml#L110) |
| [GitLab Documentation](https://gitlab.com/gitlab-org/gitlab-docs/)      | [`build-and-deploy.gitlab-ci.yml`](https://gitlab.com/gitlab-org/gitlab-docs/-/blob/a715625496303cbd90ff89f3d3658ea8d36ce0f3/.gitlab/ci/build-and-deploy.gitlab-ci.yml#L59) |
| [`https://about.gitlab.com/`](https://gitlab.com/gitlab-com/www-gitlab-com/)       | [`.gitlab-ci.yml`](https://gitlab.com/gitlab-com/www-gitlab-com/-/blob/6ffcdc3cb9af2abed490cbe5b7417df3e83cd76c/.gitlab-ci.yml#L332) |
| [GitLab Insights](https://gitlab.com/gitlab-org/gitlab-insights/)       | [`.gitlab-ci.yml`](https://gitlab.com/gitlab-org/gitlab-insights/-/blob/9e63f44ac2a5a4defc965d0d61d411a768e20546/.gitlab-ci.yml#L234) |

Other examples of review apps:

- <i class="fa fa-youtube-play youtube" aria-hidden="true"></i>
  [Cloud Native Development with GitLab](https://www.youtube.com/watch?v=jfIyQEwrocw).
- [Review apps for Android](https://about.gitlab.com/blog/2020/05/06/how-to-create-review-apps-for-android-with-gitlab-fastlane-and-appetize-dot-io/).

## Route Maps

Route Maps allows you to go directly from source files
to public pages on the [environment](../environments/index.md) defined for
review apps.

Once set up, the review app link in the merge request
widget can take you directly to the pages changed, making it easier
and faster to preview proposed modifications.

Configuring Route Maps involves telling GitLab how the paths of files
in your repository map to paths of pages on your website using a Route Map.
When you configure Route Maps, **View on** buttons are displayed.
Select these buttons to go to the pages changed directly from merge requests.

To set up a route map, add a file inside the repository at `.gitlab/route-map.yml`,
which contains a YAML array that maps `source` paths (in the repository) to `public`
paths (on the website).

### Route Maps example

The following is an example of a route map for [Middleman](https://middlemanapp.com),
a static site generator (SSG) used to build the [GitLab website](https://about.gitlab.com),
deployed from its [project on GitLab.com](https://gitlab.com/gitlab-com/www-gitlab-com):

```yaml
# Team data
- source: 'data/team.yml'  # data/team.yml
  public: 'team/'  # team/

# Blogposts
- source: /source\/posts\/([0-9]{4})-([0-9]{2})-([0-9]{2})-(.+?)\..*/  # source/posts/2017-01-30-around-the-world-in-6-releases.html.md.erb
  public: '\1/\2/\3/\4/'  # 2017/01/30/around-the-world-in-6-releases/

# HTML files
- source: /source\/(.+?\.html).*/  # source/index.html.haml
  public: '\1'  # index.html

# Other files
- source: /source\/(.*)/  # source/images/blogimages/around-the-world-in-6-releases-cover.png
  public: '\1'  # images/blogimages/around-the-world-in-6-releases-cover.png
```

Mappings are defined as entries in the root YAML array, and are identified by a `-` prefix. Within an entry, there is a hash map with two keys:

- `source`
  - A string, starting and ending with `'`, for an exact match.
  - A regular expression, starting and ending with `/`, for a pattern match:
    - The regular expression needs to match the entire source path - `^` and `$` anchors are implied.
    - Can include capture groups denoted by `()` that can be referred to in the `public` path.
    - Slashes (`/`) can, but don't have to, be escaped as `\/`.
    - Literal periods (`.`) should be escaped as `\.`.
- `public`, a string starting and ending with `'`.
  - Can include `\N` expressions to refer to capture groups in the `source` regular expression in order of their occurrence, starting with `\1`.

The public path for a source path is determined by finding the first
`source` expression that matches it, and returning the corresponding
`public` path, replacing the `\N` expressions with the values of the
`()` capture groups if appropriate.

In the example above, the fact that mappings are evaluated in order
of their definition is used to ensure that `source/index.html.haml`
matches `/source\/(.+?\.html).*/` instead of `/source\/(.*)/`,
and results in a public path of `index.html`, instead of
`index.html.haml`.

After you have the route mapping set up, it takes effect in the following locations:

- In the merge request widget:
  - The **View app** button takes you to the environment URL set in the `.gitlab-ci.yml` file.
  - The list shows the first 5 matched items from the route map, but you can filter them if more
    than 5 are available.

    ![View app file list in merge request widget](img/view_on_mr_widget.png)

- In the diff for a comparison or commit, by selecting **View** (**{external-link}**) next to the file.

- In the blob file view, by selecting **View** (**{external-link}**) next to the file.

<!--- start_remove The following content will be removed on remove_date: '2024-05-22' -->
## Visual Reviews (deprecated)

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** Self-managed

> - It's [deployed behind a feature flag](../../user/feature_flags.md), `anonymous_visual_review_feedback`, disabled by default.
> - It's disabled on GitLab.com.

WARNING:
This feature was [deprecated](https://gitlab.com/gitlab-org/gitlab/-/issues/387751) in GitLab 15.8
and is planned for removal in 17.0. This change is a breaking change.

FLAG:
On self-managed GitLab, by default this feature is not available. To make it available,
an administrator can [enable the feature flag](../../administration/feature_flags.md) named `anonymous_visual_review_feedback`.

With Visual Reviews, members of any team (Product, Design, Quality, and so on) can provide feedback comments through a form in your review apps. The comments are added to the merge request that triggered the review app.

### Using Visual Reviews

After Visual Reviews has been [configured](#configure-review-apps-for-visual-reviews) for the
review app, the Visual Reviews feedback form is overlaid on the right side of every page.

![Visual review feedback form](img/toolbar_feedback_form_v13_5.png)

To use the feedback form to make a comment in the merge request:

1. On the right side of a page, select the **Review** tab.
1. Make a comment on the visual review. You can make use of all the
   [Markdown annotations](../../user/markdown.md) that are also available in
   merge request comments.
1. Enter your personal information:
   - If [`data-require-auth`](#authentication-for-visual-reviews) is `true`, you must enter your [personal access token](../../user/profile/personal_access_tokens.md).
   - Otherwise, enter your name, and optionally your email.
1. Select **Send feedback**.

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>
To see Visual reviews in action, see the [Visual Reviews Walk through](https://youtu.be/1_tvWTlPfM4).

### Configure review apps for Visual Reviews

The feedback form is served through a script you add to pages in your review app.
It should be added to the `<head>` of your application and
consists of some project and merge request specific values. Here's how it
looks for a project with code hosted in a project on GitLab.com:

```html
<script
  data-project-id='11790219'
  data-merge-request-id='1'
  data-mr-url='https://gitlab.com'
  data-project-path='sarah/review-app-tester'
  data-require-auth='true'
  id='review-app-toolbar-script'
  src='https://gitlab.com/assets/webpack/visual_review_toolbar.js'>
</script>
```

Ideally, you should use [CI/CD variables](../variables/predefined_variables.md)
to replace those values at runtime when each review app is created:

- `data-project-id` is the project ID, which can be found by the `CI_PROJECT_ID`
  variable or on the [project overview page](../../user/project/working_with_projects.md#access-the-project-overview-page-by-using-the-project-id).
- `data-merge-request-id` is the merge request ID, which can be found by the
  `CI_MERGE_REQUEST_IID` variable. `CI_MERGE_REQUEST_IID` is available only if
  [`rules:if: $CI_PIPELINE_SOURCE == "merge_request_event`](../pipelines/merge_request_pipelines.md#add-jobs-to-merge-request-pipelines)
  is used and the merge request is created.
- `data-mr-url` is the URL of the GitLab instance and is the same for all
  review apps.
- `data-project-path` is the project's path, which can be found by `CI_PROJECT_PATH`.
- `data-require-auth` is optional for public projects but required for [private and internal ones](#authentication-for-visual-reviews). If this is set to `true`, the user is required to enter their [personal access token](../../user/profile/personal_access_tokens.md) instead of their name and email.
- `id` is always `review-app-toolbar-script`, you don't need to change that.
- `src` is the source of the review toolbar script, which resides in the
  respective GitLab instance and is the same for all review apps.

For example, in a Ruby application with code hosted on in a project GitLab.com, you would need to have this script:

```html
<script
  data-project-id="ENV['CI_PROJECT_ID']"
  data-merge-request-id="ENV['CI_MERGE_REQUEST_IID']"
  data-mr-url='https://gitlab.com'
  data-project-path="ENV['CI_PROJECT_PATH']"
  id='review-app-toolbar-script'
  src='https://gitlab.com/assets/webpack/visual_review_toolbar.js'>
</script>
```

Then, when your app is deployed via GitLab CI/CD, those variables should get
replaced with their real values.

### Determining merge request ID

The visual review tools retrieve the merge request ID from the `data-merge-request-id`
data attribute included in the `script` HTML tag used to add the visual review tools
to your review app.

After determining the ID for the merge request to link to a visual review app, you
can supply the ID by either:

- Hard-coding it in the script tag via the data attribute `data-merge-request-id` of the app.
- Dynamically adding the `data-merge-request-id` value during the build of the app.
- Supplying it manually through the visual review form in the app.

If the ID is missing from the `script`, the visual review tool prompts you to enter the
merge request ID before you can provide feedback.

### Authentication for Visual Reviews

To enable visual reviews for private and internal projects, set the
[`data-require-auth` variable](#configure-review-apps-for-visual-reviews) to `true`. When enabled,
the user must enter a [personal access token](../../user/profile/personal_access_tokens.md)
with `api` scope before submitting feedback.

This same method can be used to require authentication for any public projects.

<!--- end_remove -->
