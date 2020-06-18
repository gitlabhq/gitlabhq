# Secure Partner Integration - Onboarding Process

If you want to integrate your product with the [Secure Stage](https://about.gitlab.com/direction/secure/),
this page will help you understand the developer workflow GitLab intends for
our users to follow with regards to security results. These should be used as
guidelines so you can build an integration that fits with the workflow GitLab
users are already familiar with.

This page also provides resources for the technical work associated
with [onboarding as a partner](https://about.gitlab.com/partners/integrate/).
The steps below are a high-level view of what needs to be done to complete an
integration as well as linking to more detailed resources for how to do so.

## What is the GitLab Developer Workflow?

This workflow is how GitLab users interact with our product and expect it to
function. Understanding how users use GitLab today will help you choose the
best place to integrate your own product and its results into GitLab.

- Developers want to write code without using a new tool to consume results
  or address feedback about the item they are working on. Staying inside a
  single tool, GitLab, helps them to stay focused on finishing the code and
  projects they are working on.
- Developers commit code to a Git branch. The developer creates a merge request (MR)
  inside GitLab where these changes can be reviewed. The MR triggers a GitLab
  pipeline to run associated jobs, including security checks, on the code.
- Pipeline jobs serve a variety of purposes. Jobs can do scanning for and have
  implications for app security, corporate policy, or compliance. When complete,
  the job reports back on its status and creates a
  [job artifact](../../user/project/pipelines/job_artifacts.md) as a result.
- The [Merge Request Security Widget](../../user/project/merge_requests/testing_and_reports_in_merge_requests.md#security-reports-ultimate)
  displays the results of the pipeline's security checks and the developer can
  review them. The developer can review both a summary and a detailed version
  of the results.
- If certain policies (such as [merge request approvals](../../user/project/merge_requests/merge_request_approvals.md))
  are in place for a project, developers must resolve specific findings or get
  an approval from a specific list of people.
- The [security dashboard](../../user/application_security/security_dashboard/index.md#gitlab-security-dashboard-ultimate)
  also shows results which can developers can use to quickly see all the
  vulnerabilities that need to be addressed in the code.
- When the developer reads the details about a vulnerability, they are
  presented with additional information and choices on next steps:
    1. Create Issue (Confirm finding): Creates a new issue to be prioritized.
    1. Add Comment and Dismiss Vulnerability: When dismissing a finding, users
       can comment to note items that they
       have mitigated, that they accept the vulnerability, or that the
       vulnerability is a false positive.
    1. Auto-Remediation / Create Merge Request: A fix for the vulnerability can
       be offered, allowing an easy solution that does not require extra effort
       from users. This should be offered whenever possible.
    1. Links: Vulnerabilities can link out external sites or sources for users
       to get more data around the vulnerability.

## How to onboard

This section describes the steps you need to complete to onboard as a partner
and complete an integration with the Secure stage.

1. Read about our [partnerships](https://about.gitlab.com/partners/integrate/).
1. [Create an issue](https://gitlab.com/gitlab-com/alliances/alliances/-/issues/new?issuable_template=new_partner)
   using our new partner issue template to begin the discussion.
1. Get a test account to begin developing your integration. You can
   request a [GitLab.com Gold Subscription Sandbox](https://about.gitlab.com/partners/integrate/#gitlabcom-gold-subscription-sandbox-request)
   or an [EE Developer License](https://about.gitlab.com/partners/integrate/#requesting-ee-dev-license-for-rd).
1. Provide a [pipeline job](../../development/pipelines.md)
   template that users could integrate into their own GitLab pipelines.
1. Create a report artifact with your pipeline jobs.
1. Ensure your pipeline jobs create a report artifact that GitLab can process
   to successfully display your own product's results with the rest of GitLab.
   - See detailed [technical directions](secure.md) for this step.
   - Read more about [job report artifacts](../../ci/pipelines/job_artifacts.md#artifactsreports).
   - Read about [job artifacts](../../user/project/pipelines/job_artifacts.md).
   - Your report artifact must be in one of our currently supported formats.
     For more information, see the [documentation on reports](secure.md#report).
     - Documentation for [SAST reports](../../user/application_security/sast/index.md#reports-json-format).
     - Documentation for [Dependency Scanning reports](../../user/application_security/dependency_scanning/index.md#reports-json-format).
     - Documentation for [Container Scanning reports](../../user/application_security/container_scanning/index.md#reports-json-format).
     - See this [example secure job definition that also defines the artifact created](https://gitlab.com/gitlab-org/gitlab/blob/master/lib/gitlab/ci/templates/Security/Container-Scanning.gitlab-ci.yml).
     - If you need a new kind of scan or report, [create an issue](https://gitlab.com/gitlab-org/gitlab/-/issues/new#)
       and add the label `devops::secure`.
   - Once the job is completed, the data can be seen:
      - In the [Merge Request Security Report](../../user/project/merge_requests/testing_and_reports_in_merge_requests.md#security-reports-ultimate) ([MR Security Report data flow](https://gitlab.com/snippets/1910005#merge-request-view)).
      - While [browsing a Job Artifact](../../user/project/pipelines/job_artifacts.md).
      - In the [Security Dashboard](../../user/application_security/security_dashboard/index.md) ([Dashboard data flow](https://gitlab.com/snippets/1910005#project-and-group-dashboards)).
1. Optional: Provide a way to interact with results as Vulnerabilities:
   - Users can interact with the findings from your artifact within their workflow. They can dismiss the findings or accept them and create a backlog issue.
   - To automatically create issues without user interaction, use the [issue API](../../api/issues.md). This will be replaced by [Standalone Vulnerabilities](https://gitlab.com/groups/gitlab-org/-/epics/634) in the future.
1. Optional: Provide auto-remediation steps:
   - If you specified `remediations` in your artifact, it is proposed through our [auto-remediation](../../user/application_security/index.md#solutions-for-vulnerabilities-auto-remediation)
     interface.
1. Demo the integration to GitLab:
   - After you have tested and are ready to demo your integration please
     [reach out](https://about.gitlab.com/partners/integrate/) to us. If you
     skip this step you won’t be able to do supported marketing.
1. Begin doing supported marketing of your GitLab integration.
   - Work with our [partner team](https://about.gitlab.com/partners/integrate/)
     to support your go-to-market as appropriate.
   - Examples of supported marketing could include being listed on our [Security Partner page](https://about.gitlab.com/partners/#security),
     doing an [Unfiltered blog post](https://about.gitlab.com/handbook/marketing/blog/unfiltered/),
     doing a co-branded webinar, or producing a co-branded whitepaper.

We have a [video playlist](https://www.youtube.com/playlist?list=PL05JrBw4t0KpMqYxJiOLz-uBIr5w-yP4A)
that may be helpful as part of this process. This covers various topics related to integrating your
tool.

If you have any issues while working through your integration or the steps
above, please create an issue to discuss with us further.
