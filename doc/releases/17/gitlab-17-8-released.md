---
stage: Release Notes
group: Monthly Release
date: 2025-01-16
title: "GitLab 17.8 release notes"
description: "GitLab 17.8 released with Enhance security with protected container repositories"
---

<!-- markdownlint-disable -->
<!-- vale off -->

On January 16, 2025, GitLab 17.8 was released with the following features.

In addition, we want to thank all of our contributors, including this month's notable contributor.

## This month’s Notable Contributor

Everyone can [nominate GitLab’s community contributors](https://gitlab.com/gitlab-org/developer-relations/contributor-success/team-task/-/issues/490)!
Show your support for our active candidates or add a new nomination! 🙌

Through the Co-Create Program, [Océane Legrand](https://gitlab.com/oceane_scania) has been leading efforts to enhance the Conan package registry feature set, collaborating with Juan Pablo Gonzalez.
Their work has focused on bringing the feature closer to GA readiness while implementing Conan version 2 support.
This collaboration demonstrates how the Co-Create Program can drive significant improvements to GitLab’s package registry capabilities.

They were nominated by [Raimund Hook](https://gitlab.com/stingrayza), Senior Fullstack Engineer, Contributor Success at GitLab, who highlighted their persistent collaboration and continuous iteration on the Conan Package Registry features.
Their work exemplifies GitLab values and will benefit all Conan users on the platform.

Océane Legrand is a Full Stack Developer at Scania where she works on maintaining their self-hosted GitLab instance on AWS.
“The work I’m doing in open source impacts both GitLab and Scania,” says Océane.
“Contributing through the Co-Create Program has given me new skills, like experience with Ruby and background migrations. When my team at Scania faced an issue during an upgrade, I was able to help troubleshoot because I’d already encountered it through the program.”

[Learn more about GitLab’s Co-Create Program](https://about.gitlab.com/community/co-create/) where customers work directly with our product and engineering teams to develop new features and enhance existing ones.

## Primary features

### Enhance security with protected container repositories

<!-- categories: Container Registry -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed
- Links: [Documentation](../../user/packages/container_registry/container_repository_protection_rules.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/480385)

{{< /details >}}

We’re thrilled to announce the rollout of protected container repositories, a new feature in GitLab’s container registry that addresses security and control challenges in managing container images. Organizations often struggle with unauthorized access to sensitive container repositories, accidental modifications, lack of granular control, and difficulties in maintaining compliance. This solution provides enhanced security through strict access controls, granular permissions for push, pull, and management operations, and seamless integration with GitLab CI/CD pipelines.

Protected container repositories offers value to users by reducing the risk of security breaches and accidental changes to critical assets. This feature streamlines workflows by maintaining security without sacrificing development speed, improves overall governance of the container registry, and provides peace of mind knowing that important container assets are protected according to organizational needs.

This feature and the [protected packages](https://gitlab.com/groups/gitlab-org/-/epics/5574) feature are both community contributions from `gerardo-navarro` and the Siemens crew. Thank you Gerardo and the rest of the crew from Siemens for their many contributions to GitLab! If you are interesting in learning more about how Gerardo and the Siemens crew contributed this change, check out this [video](https://www.youtube.com/watch?v=5-nQ1_Mi7zg) in which Gerardo shares his learnings and best practices for contributing to GitLab based on his experience as an external contributor.

### List the deployments related to a release

<!-- categories: Environment Management, Deployment Management -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/project/releases/_index.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/501169)

{{< /details >}}

While GitLab has long supported creating releases from Git tags and tracking deployments, this information previously lived in multiple separate places that were difficult to piece together. Now, you can see all deployments related to a release directly on the release page. Release managers can quickly verify where a release has been deployed and which environments are pending deployment. This complements the existing deployment page integration that shows release notes for tagged deployments.

We would like to express our gratitude to [Anton Kalmykov](https://gitlab.com/antonkalmykov) for contributing both features to GitLab.

### Machine learning model experiments tracking in GA

<!-- categories: MLOps -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed
- Links: [Documentation](../../user/project/ml/experiment_tracking/_index.md) | [Related epic](https://gitlab.com/groups/gitlab-org/-/epics/9341)

{{< /details >}}

When creating machine learning models, data scientists often experiment with different parameters, configurations, and feature engineering to improve the performance of the model. Keeping track of all this metadata and the associated artifacts so that the data scientist can later replicate the experiment is not trivial. Machine learning experiment tracking enables them to log parameters, metrics, and artifacts directly into GitLab, giving easy access later on while also keeping all experimental data within your GitLab environment. This feature is now generally available with enhanced data displays, enhanced permissions, deeper integration with GitLab, and bug fixes.

### Hosted runners on Linux for GitLab Dedicated now in limited availability

<!-- categories: GitLab Dedicated, GitLab Hosted Runners -->

{{< details >}}

- Tier: Gold
- Links: [Documentation](../../administration/dedicated/hosted_runners.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/509142)

{{< /details >}}

We are excited to introduce the limited availability of hosted runners on Linux for GitLab Dedicated.

Managing fleets of runners can be complex and require significant experience to ensure all CI/CD jobs can
scale to meet the demands of developers.

Hosted runners for GitLab Dedicated allow you to use fully managed runners for CI/CD jobs.
They eliminate the need to maintain your own runner infrastructure, and provide the same
security, flexibility, and efficiency of GitLab Dedicated to runners.

Hosted runners scale automatically to meet your CI/CD demands to ensure
optimal performance during peak times and for large projects.
The limited availability release includes Linux runners in various sizes,
ranging from 2 to 32 vCPUs, with 8 to 128 GB of memory.

To request access to hosted runners for GitLab Dedicated during the limited availability phase,
contact your GitLab representative.

### Large M2 Pro hosted runners on macOS (Beta)

<!-- categories: GitLab Hosted Runners -->

{{< details >}}

- Tier: Silver, Gold
- Offering: GitLab.com
- Links: [Documentation](../../ci/runners/hosted_runners/macos.md) | [Related epic](https://gitlab.com/groups/gitlab-org/ci-cd/shared-runners/-/epics/19)

{{< /details >}}

We bring M2 Pro performance to mobile DevOps teams!

With up to 2 times the performance of M1 runners and 6 times the performance of x86-64 macOS runners,
you can increase your development team’s velocity when building and deploying applications.

Fully integrated to GitLab CI/CD and available on-demand, teams can now seamlessly create, test,
and deploy applications faster for the Apple ecosystem.

Try out the new M2 Pro runners today by using `saas-macos-large-m2pro` as the tag in your `.gitlab-ci.yml` file.

## Agentic Core

### GitLab MLOps Python Client Beta

<!-- categories: MLOps -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed
- Links: [Documentation](https://gitlab.com/gitlab-org/modelops/mlops/gitlab-mlops) | [Related issue](https://gitlab.com/groups/gitlab-org/-/epics/16193)

{{< /details >}}

Data scientists and Machine Learning engineers primarily work in Python environments, but integrating their machine learning workflows with GitLab’s MLOps features often requires context switching and understanding of GitLab’s API structure. This can create friction in their development process and slow down their ability to track experiments, manage model artifacts, and collaborate with team members.

The new GitLab MLOps Python client provides a seamless, Pythonic interface to GitLab’s MLOps features. Data scientists can now interact with GitLab’s [experiment tracking](../../user/project/ml/experiment_tracking/_index.md) and [model registry](../../user/project/ml/model_registry/_index.md) capabilities directly from their Python scripts and notebooks. The client includes:

- **GitLab Experiment Tracking**: Easily track machine learning experiments within GitLab.
- **Model Registry Integration**: Register and manage models in GitLab’s model registry.
- **Experiment Management**: Create and manage experiments directly from the client.
- **Run Tracking**: Initiate and monitor training runs with ease.

This integration allows data scientists to focus on model development while automatically capturing their ML lifecycle metadata in GitLab. The Python client works seamlessly with existing ML workflows and requires minimal setup, making GitLab’s MLOps features more accessible to the data science community.

We welcome the wider Python and data science community to contributions and share feedback directly in our [project’s repository](https://gitlab.com/gitlab-org/modelops/mlops/gitlab-mlops)

## Scale and Deployments

### View subgroups and projects pending deletion

<!-- categories: Groups & Projects -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/group/_index.md#view-inactive-groups) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/457718)

{{< /details >}}

When you mark a group for deletion, you need visibility into all affected subgroups and projects. Previously, only the group marked for deletion displayed a “Pending deletion” label, but not their subgroups and projects, making it difficult to identify which content was scheduled for deletion.

Now, when a group is marked for deletion, all of its subgroups and projects will display a “Pending deletion” label. This improved visibility helps you quickly distinguish between active and soon-to-be deleted content across your entire group hierarchy.

### Track multiple to-do items in an issue or merge request

<!-- categories: Notifications -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/todos.md#actions-that-create-to-do-items) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/28355)

{{< /details >}}

You can now keep track of multiple discussions and mentions within a single issue or merge request. With the new multiple to-do items feature, you’ll receive separate to-do items for each mention or action, ensuring you don’t miss important updates or requests for your attention. This enhancement helps you manage your work more effectively and respond to your team’s needs more efficiently.

### Project creation protection for groups now includes Owners

<!-- categories: Groups & Projects -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/group/_index.md#specify-who-can-add-projects-to-a-group) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/354355)

{{< /details >}}

Project creation can be restricted to specific roles in a group using the **Allowed to create projects** setting. The Owner role is now available as an option, enabling you to restrict new project creation to users with the Owner role for the group. This role was previously unavailable in the selection options.

Thank you [@yasuk](https://gitlab.com/yasuk) for this community contribution!

## Unified DevOps and Security

### Secret detection now includes remediation steps

<!-- categories: Secret Detection -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/application_security/secret_detection/_index.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/505757)

{{< /details >}}

It’s important to fix exposed secrets quickly to minimize the risk of attackers using exposed credentials to break into your systems. Proper remediation requires multiple steps beyond just removing the secret, such as rotating credentials and investigating potential unauthorized access. To help keep your systems secure, secret detection now includes specific remediation steps for each type of detected secret. This guidance helps you systematically address exposures and reduce the risk of security breaches. Remediation steps will appear on all vulnerabilities upon the completion of a pipeline.

### Find the commit that resolved a vulnerability

<!-- categories: Vulnerability Management -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/application_security/vulnerabilities/_index.md#vulnerability-resolution) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/372799)

{{< /details >}}

Previously, when a vulnerability was no longer detected, we did not provide users a way to see when or where a vulnerability was resolved.
Now, we display a link to the commit SHA where the vulnerability was resolved, providing better traceability and insight into the resolution process. This makes it easier for security and development teams to collaborate and manage vulnerabilities more effectively.

### Use roles to define project members as Code Owners

<!-- categories: Source Code Management -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/project/codeowners/reference.md#add-a-role-as-a-code-owner) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/282438)

{{< /details >}}

You can now use roles as Code Owners in your `CODEOWNERS` file to manage role-based expertise and approvals more efficiently. Instead of listing individual users or creating groups, you can use the following syntax:

- `@@developers` - References all users with the Developer role.
- `@@maintainers` - References all users with the Maintainer role.
- `@@owners` - References all users with the Owner role.

For example, add `* @@maintainers` to require approval from any maintainer for all changes in the repository.

This simplifies Code Owner management as team members join, leave, or change roles in your project. The `CODEOWNERS` file remains current without manual updates, because GitLab automatically includes all users who have the specified role.

### View paused Flux reconciliations on the dashboard for Kubernetes

<!-- categories: Deployment Management -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../ci/environments/kubernetes_dashboard.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/501339)

{{< /details >}}

Previously, when you suspended Flux reconciliation from the dashboard for Kubernetes, there was no clear indicator of the suspended state. We’ve added a new “Paused” status to the existing set of status indicators, making it clear when Flux reconciliation is suspended and providing better visibility into the state of your deployments.

### Search for pods on the dashboard for Kubernetes

<!-- categories: Environment Management, Deployment Management -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../ci/environments/kubernetes_dashboard.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/508010)

{{< /details >}}

On the dashboard for Kubernetes, finding specific pods in large deployments can be time-consuming. A new search bar lets you quickly filter pods by name. The search works across all available pods, and you can combine it with status filters to find exactly the pods you need to monitor or troubleshoot.

### Support multiple distinct approval actions in merge request approval policies

<!-- categories: Security Policy Management -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/application_security/policies/merge_request_approval_policies.md) | [Related epic](https://gitlab.com/groups/gitlab-org/-/epics/12319)

{{< /details >}}

Previously, merge request approval policies supported only a single approval rule per policy, allowing for one set of approvers stacked with an “OR” condition. As a result, it was more challenging to enforce layered security approvals from varied roles, individual approvers, or separate groups.

With this update, you can create up to five approval rules for each merge request approval policy, allowing for more flexible and robust approval policies. Each rule can specify different approvers or roles and each rule is evaluated independently. For example, security teams can define complex approval workflows such as requiring one approver from Group A and one from Group B, or one from a specific role and another from a specified group, ensuring compliance and enhanced control in sensitive workflows.

Example uses of this improvement include:

- **Distinct role approvals:** One approval from a Developer role and another from a Maintainer role.
- **Role and group approvals**: One approval from Developer or Maintainer and a separate approval from a member of the Security Group.
- **Distinct group approvals:** One approval from a member of the Python Experts Group and another separate approval from a member of the Security Group.

### Primary domain redirect for GitLab Pages

<!-- categories: Pages -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/project/pages/_index.md#primary-domain)

{{< /details >}}

You can now set a primary domain in GitLab Pages to automatically redirect all requests from custom domains to your primary domain. This helps maintain SEO rankings and provides a consistent brand experience by directing visitors to your preferred domain, regardless of which URL they initially use to access your site.

### Safeguard your dependencies with protected packages

<!-- categories: Package Registry -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/packages/package_registry/package_protection_rules.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/323971)

{{< /details >}}

We’re thrilled to introduce support for protected PyPI packages, a new feature designed to enhance the security and stability of your GitLab package registry. In the fast-paced world of software development, accidental modification or deletion of packages can disrupt entire development processes. Protected packages address this issue by allowing you to safeguard your most important dependencies against unintended changes.

From GitLab 17.8, you can protect PyPI packages by creating protection rules. If a package is matched by a protection rule, only specified users can update or delete the package. With this feature, you can prevent accidental changes, improve compliance with regulatory requirements, and streamline your workflows by reducing the need for manual oversight.

### Customizable colors for epics

<!-- categories: Portfolio Management -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/group/epics/manage_epics.md#epic-color) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/509924)

{{< /details >}}

You now have more flexibility in categorizing your epics with an expanded set of color options, including pre-existing values and custom RGB or hex codes. This enhanced visual customization allows you to easily associate epics with squads, company initiatives, or hierarchy levels, making it simpler to prioritize and organize your work on roadmaps and epic boards.

Your administrator must enable [the new look for epics](../../user/group/epics/_index.md#epics-as-work-items).

### Epic ancestors

<!-- categories: Portfolio Management -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/group/epics/_index.md#relationships-between-epics-and-other-items) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/509920)

{{< /details >}}

Navigating your [epic hierarchy](../../user/group/epics/_index.md#relationships-between-epics-and-other-items) just got easier with the redesigned Ancestry widget, now prominently displayed at the top of each epic in a breadcrumb-like format. You can quickly grasp the relationships between epics by seeing both immediate and ultimate parents at a glance, helping you maintain a clear overview of your project structure and easily move between related epics.

Your administrator must enable [the new look for epics](../../user/group/epics/_index.md#epics-as-work-items).

### Epic health status

<!-- categories: Portfolio Management -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/group/epics/manage_epics.md#health-status) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/509922)

{{< /details >}}

You can now easily communicate the progress of your projects with the new health status feature for epics. By setting the status to “On track,” “Needs attention,” or “At risk,” you’ll have a quick visual indicator of your epic’s health, allowing you to manage risk and keep stakeholders informed about the project’s overall status.

Your administrator must enable [the new look for epics](../../user/group/epics/_index.md#epics-as-work-items).

### Epic parent

<!-- categories: Portfolio Management -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/group/epics/_index.md#relationships-between-epics-and-other-items) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/509923)

{{< /details >}}

You can now easily manage your epic hierarchy by adding a parent directly from an epic, just as you would for an issue. This streamlined process gives you more flexibility in organizing your work, allowing you to quickly establish relationships between epics and maintain a clear structure for your projects.

Your administrator must enable [the new look for epics](../../user/group/epics/_index.md#epics-as-work-items).

### Track time spent on epics

<!-- categories: Portfolio Management -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/project/time_tracking.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/509930)

{{< /details >}}

You can now track time directly in epics, giving you more granular control over your project’s time management. This new feature allows you to log time spent on different aspects of your project, helping you monitor progress, stay on schedule, and keep your budget in check as you work through sprints and milestones.

### Show iteration field on child items in epics, issues, and objectives

<!-- categories: Portfolio Management -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/group/iterations/_index.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/510005)

{{< /details >}}

When viewing epic detail, planners need to be able to see which child issues are planned into iterations (sprints) and which are not yet planned. This will allow teams to more easily make sure that all defined work is slated into sprints.

For epics, your administrator must enable [the new look for epics](../../user/group/epics/_index.md#epics-as-work-items).

### Webhooks for epics

<!-- categories: Portfolio Management -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/project/integrations/webhook_events.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/509928)

{{< /details >}}

Supercharge your workflow automation with the epic webhooks, allowing you to receive real-time updates in your preferred tools whenever changes occur in your epics. By integrating GitLab with your other services, you can enhance collaboration, stay on top of project developments, and streamline your processes without constantly switching between applications.

Your administrator must enable [the new look for epics](../../user/group/epics/_index.md#epics-as-work-items).

### Add vulnerabilities as supported webhook events

<!-- categories: Notifications, Vulnerability Management -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/project/integrations/webhook_events.md#vulnerability-events) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/366770)

{{< /details >}}

Introducing a webhook integration that generates events for actions related to vulnerabilities to allow you to automate and integrate with external resources. For example, events are generated when vulnerabilities are created or the status of a vunerability changes.

### Enforce centralized workflow rules for the `override_ci` strategy

<!-- categories: Security Policy Management -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/application_security/policies/pipeline_execution_policies.md#override_project_ci) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/512123)

{{< /details >}}

In pipeline execution policies, the `override_ci` strategy now supports the use of workflow rules to aid in policy enforcement for jobs defined in the policy, as well as jobs defined in the project’s configuration when using `include:project`. By defining workflow rules in the policy, you can filter out jobs executed by the pipeline execution policy based on particular rules, such as by configuring rules that prevent the use of branch pipelines in projects.

To isolate the use of workflow rules to target only jobs defined in your policy, the best practice is to define the rules for the job instead of globally in the policy. Alternatively, you can group jobs and rules using a separate `include` field.

Previously, when using the `override_ci` strategy, workflow rules could only be applied to jobs defined in the pipeline execution policy.

The `inject_ci` strategy remains unchanged and workflow rules can only be used to control when policy jobs are enforced, without affecting the project’s workflow rules.

### Make `skip_ci` configurable for pipeline execution policies

<!-- categories: Security Policy Management -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/application_security/policies/pipeline_execution_policies.md#skip_ci-type) | [Related epic](https://gitlab.com/groups/gitlab-org/-/epics/15647)

{{< /details >}}

We’ve introduced a new configuration option for Pipeline Execution Policies (PEPs) that allows for more flexibility in handling the `[skip ci]` directive. This feature addresses scenarios where certain automated processes, such as semantic releases, where it’s necessary to bypass pipeline execution while still ensuring critical security and compliance checks are performed.

To use this feature, set `skip_ci` to `allowed: false` in the pipeline execution policy YAML configuration or enable **Prevent users from skipping pipelines** in the policy editor. Then, specify the users or service accounts that are allowed to use `[skip ci]`. By default all users will be blocked from skipping pipeline execution jobs unless they are excluded within the `skip_ci` configuration as an exception.

### Manage concurrency of scheduled scan execution pipelines

<!-- categories: Security Policy Management -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/application_security/policies/scan_execution_policies.md#concurrency-control) | [Related epic](https://gitlab.com/groups/gitlab-org/-/epics/13997)

{{< /details >}}

To improve the scalability of global scheduled scan execution policies, we have introduced a new capability to configure a time window in a scan execution policy. The `time_window` property defines the time period in which the policy creates and executes new schedules to ensure optimal performance.

To use the new property, update your policy using YAML mode and follow the [`time_window` schema](../../user/application_security/policies/scan_execution_policies.md#time_window-schema). You can provide a value in seconds for the window of time in which the schedules should run. For example, `86400` for a 24 hour time window. Then supply the `distribution: random` field and value to enforce the schedules to execute at random times across the defined time window.

### Scaling UI performance for the 'Frameworks' report tab in the Compliance Center

<!-- categories: Compliance Management -->

{{< details >}}

- Tier: Ultimate, Premium
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/compliance/compliance_center/compliance_frameworks_report.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/477394)

{{< /details >}}

With GitLab 17.8, we have made changes to the backend to ensure the compliance center remains quick and responsive,
even if you have 1,000’s of compliance frameworks in the **Frameworks** report tab of the compliance center.

Additionally, when looking for more information and clicking on a framework in the **Frameworks** tab, GitLab
returns up to 1,000 projects that are attached to that particular framework as part of the information in the
right-hand side pop up menu.

### Pipeline limits available in GitLab Community Edition

<!-- categories: Continuous Integration (CI) -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed
- Links: [Documentation](../../administration/settings/continuous_integration.md#set-cicd-limits) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/287669)

{{< /details >}}

Administrators can now control pipeline resource usage by setting CI/CD limits for their GitLab Community Edition installations. Previously, this feature was only available in GitLab Enterprise Edition.

## Related topics

- [Bug fixes](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=type%3A%3Abug&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=17.8)
- [Performance improvements](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=bug%3A%3Aperformance&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=17.8)
- [UI improvements](https://papercuts.gitlab.com/?milestone=17.8)
- [Deprecations and removals](../../update/deprecations.md)
- [Upgrade notes](../../update/versions/_index.md)
