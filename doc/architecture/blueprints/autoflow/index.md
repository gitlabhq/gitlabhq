---
status: proposed
creation-date: "2024-02-16"
authors: [ "@ash2k", "@ntepluhina" ]
coach: "@grzesiek"
approvers: [ "@nagyv-gitlab", "@nmezzopera" ]
owning-stage: "~devops::deploy"
participating-stages: [ "~devops::plan" ]
---

<!-- Blueprints often contain forward-looking statements -->
<!-- vale gitlab.FutureTense = NO -->

# AutoFlow - workflows for automation

Automation + Workflow = AutoFlow.

## Summary

GitLab offers a single application for the whole DevSecOps cycle, and we aim to become the AllOps platform.
Being a platform means to provide users with tools to solve various problems in the corresponding domain.
There is a huge number of use cases that boil down to letting users automate interactions between the DevSecOps domain
objects.
Automation is key to increasing productivity and reducing cost in most businesses so those use cases are a big deal for
our customers.
We don't provide a comprehensive way to automate processes across the domain at the moment.

GitLab AutoFlow allows users to encode workflows of interactions between DevSecOps domain objects and external systems.
Users are able to share, reuse, and collaborate on workflow blocks.

## Motivation

### Goals

- Let users build workflows that automate tasks in the DevSecOps domain.
- Workflows should be able to interact with GitLab, users (via UI), and with external systems. Interactions are via API
  calls and emitting/receiving events.
- Users should be able to share and reuse parts of a workflow on a self-serve basis.
- Workflow definitions should be testable without having to run them in a real environment.
- Security of customer data and GitLab platform should be kept in mind at all times.
- Workflows have to be executed in a durable way. Put differently, the automated show must go on even if a server
  crashes or network connectivity is disrupted.

### Example use cases

#### Trivial

- When milestone on an issue is `Backlog`, set label `workflow::backlog`. When it's set to a milestone, set label to
  `workflow::ready for dev`.
- When label on an issue is `group::environments`, set labels `devops::deploy` and `section::cd`.
- All what [GitLab Triage](https://gitlab.com/gitlab-org/ruby/gems/gitlab-triage) can do.

#### Interesting

- **Retro bot**: when a milestone expires or is closed, wait for the next Monday. Get a list of members of a group.
  For each member open an issue in a project.
  In the issue add a form with fields (a new UI component that we don't have now) to enter what went well in this
  milestone, what didn't, and praise for the team. If an issue stays open for more than two days, ping the assigned team
  member.
  Once all opened issues have been closed or a week later, whatever happens first, collect form data from them
  and open a new issue with that data aggregated.
  Assign to the group's manager, mention all group members.
- **Project compliance**: when project settings change, trigger a "pre-commit" flow that allows for programmatic
  validation of the intended changes. Restricting project settings is a common compliance requirement. Today, GitLab
  role model does not allow for much customization, and users work around this functionality with code-based automations
  like Terraform. An alternative, often requested approach is to restrict project settings at higher levels. Given the
  wide variety of project settings, this would likely either have only partial support or would require re-implementing
  all the project settings in the compliance settings. Overall, most single use-case solutions will likely have serious
  maintenance and scalability issues. Implementing validation as code could provide a simple interface.

#### Sophisticated

- **Deployments**: when a commit is merged into the main branch:
  - A build should run.
  - On success, certain artifacts should be combined into a release.
  - The release then should be rolled out to pre-production environment using a certain deployment method.
  - The deployment should be soaked there under synthetic load for 1 day.
  - Then promoted to staging.
  - After 1 more day in staging, the release should be gradually rolled out to production.
  - Production rollout should start with a canary deployment.
  - Then it should be scaled up in 10% increments each hour.
  - For that deployment, anomaly detection system should be monitoring certain metrics.
  - It should stop the rollout if something unusual is detected (we don't have this mechanism yet, but it'd be
    great), notify the SRE team.
  - If things are "really bad" (i.e. certain metrics breach certain thresholds), create an incident issue and start
    rolling the deployment back.
  - Keep the incident issue up to date with what's happening with the deployment.
  - Get information about the Deployment object (let's assume we are deploying to Kubernetes), events in
    the namespace, and Pod logs from the GitLab agent for Kubernetes.
  - Feed that into GitLab Duo to get advice on what the problem might be and how to fix it. Post the reply as a comment.
- **Compliance in workflows**: any of the automated workflows, e.g. the one above, can have one or more steps where
  a manual interaction from a user is awaited.
  - If we let workflows generate UI elements, they could wait for those forms
    to be filled, for buttons pushed, etc and take further actions based on user input (or lack of - timeouts).
  - We could have a workflow request an approval from the risk management team if the deployment is happening during
    a [PCL](https://handbook.gitlab.com/handbook/engineering/infrastructure/change-management/#production-change-lock-pcl).
  - Because the process is automated, automation is code that is version-controlled, passing an audit becomes easier. No
    chance to forget to follow the process if it's automated and there is no way around it.
- **Access requests**: most (?) of
  our [access requests](https://gitlab.com/gitlab-com/team-member-epics/access-requests/)
  can probably be automated.
  - Team member creates an issue, fills in a form, assigns to their manager, they approve by setting a
    label or pressing a special button, automation takes it from there - most systems have APIs that can be used to make
    the requested changes.
  - Consider how much time is wasted here - people have to wait, people have to do repetitive work.
  - Manual actions mean there is a chance of making a mistake while making an important change.
  - It's not only us, most of the businesses have a need to automate such processes.

### Related issues

Over the years we've accumulated many issues, epics, ideas, use cases on the topic of automation. Here are some of the
more interesting ones.

---

[Improved Work Item lifecycle management & native automations](https://gitlab.com/groups/gitlab-org/-/epics/364),
[GitLab Automations](https://gitlab.com/groups/gitlab-org/-/epics/218), [Workflows Solution Validation](https://gitlab.com/gitlab-org/gitlab/-/issues/344136).
These look at the problem from the `devops::plan` point of view:

> Customers and prospects frequently lament that there is no way to easily manage end-to-end workflows (Epic, Issue,
> MR...) within GitLab.
>
> Officially requested by 14 distinct accounts and is the third most requested / highest value capability from the Plan
> stage.

See the linked issues from the epics too.

[Configure label to be removed when issue is closed](https://gitlab.com/gitlab-org/gitlab/-/issues/17461) is yet
another example. 283 upvotes.

---

[Automatable DevOps](https://gitlab.com/gitlab-org/gitlab/-/issues/330084) is Mikhail's previous attempt to provide the
automation capability. It inspired lots of thinking and lead to this proposal.

---

[Add the ability to define an issue/MR event and an action to take as a result of that event](https://gitlab.com/gitlab-org/gitlab/-/issues/242194).
Customer [quote](https://gitlab.com/gitlab-org/gitlab/-/issues/242194#note_1785436689):

> I'm in agreement. I'm having a hard enough time bringing a development team on board to GitLab, adding manual label
> management to the process when parts of it should be done via automation adds to the challenge.
>
> We don't want to auto-close issues on merge and have defined a QA role to perform that step. The problem I'm working
> on figuring out now is how to automate label management on an issue when the associated MR is closed, while leaving
> the
> Issue open but updating the workflow labels on it automatically.
>
> We're a smallish team and I need to be focused on product development, not how to build GitLab automation scripts.
>
> Having the ability to trigger some events as a part of an MR merging to manage other aspects of the system would be
> extremely helpful.

---

Some use cases from `group::delivery` (from
[this comment](https://gitlab.com/gitlab-org/ci-cd/section-showcases/-/issues/54#note_1663194580)):

- If we have events from when certain files are added/changed in Git for a project, we could use this to automate the
  Provisioner in the Runway platform (and deprovision when people want to).
- Automating certain tasks when a new backport request issue is created.
- Automated tasks when we want to start a new monthly release.
- Moving to a "GitLab deployment Engine" that is more powerful than GitLab CI alone. This is perhaps the most
  interesting use case to me, but I do wonder how complicated it would be to manage these workflows.

---

Some use cases from the Remote Development team (from
[this comment](https://gitlab.com/gitlab-org/ci-cd/section-showcases/-/issues/54#note_1658464245)):

> A real world example of this is the Remote Development Teams work to implement
> [a standard XP/Scrum style velocity-based process and workflow](https://about.gitlab.com/handbook/engineering/development/dev/create/ide/#remote-development-planning-process-overview)
> in GitLab.
>
> There's
> [multiple limitations in GitLab the product itself](https://gitlab.com/cwoolley-gitlab/gl-velocity-board-extension#why-doesnt-standard-gitlab-support-this)
> which make it difficult to use this common process, and we have to work around them.
>
> To avoid the manual toil of making this process work in GitLab, we would like to automate it. However our efforts to
> set up the
> [several desired automations](https://about.gitlab.com/handbook/engineering/development/dev/create/ide/#automations)
> have been limited because of the barriers to implementing and testing them in
> Triage Bot, especially for ones that contain more complex logic, or can't be implemented solely via quick actions.
>
> I believe a tool like GitLab Flow would make it much easier for us and our customers to implement common but
> non-supported processes and workflows such as this on top of GitLab, without having to wait months or years for a
> given feature to be shipped which unblocks the effort.

## Proof of concept, demos

- [Implementation issue](https://gitlab.com/gitlab-org/cluster-integration/gitlab-agent/-/issues/473)
- Video with [conceptual and technical details, fist demo](https://www.youtube.com/watch?v=g9HSPV3GKas). It's a long
  video, **watch on 1.5x**. [Skip right to the demo](https://youtu.be/g9HSPV3GKas?t=1325) at 22:05.
- [Slides](https://docs.google.com/presentation/d/1doMdiyusAjzHq-hlqHqHr0y4WZN2EiJZHFS_PVrTfJ8/edit?usp=sharing). Please
  see speaker notes for links and code.
- Demo project: N/A See speaker notes for code (as text, not video)
- Implementation MRs:
  [kas part](https://gitlab.com/gitlab-org/cluster-integration/gitlab-agent/-/merge_requests/1173), [Rails part](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/136696).

Since the above demo went well, [GitLab AutoFlow for internal use](https://gitlab.com/groups/gitlab-org/-/epics/12120)
epic was opened. Then we tried to address a concrete use case
in [AutoFlow PoC: configurable automation for issue status updates](https://gitlab.com/groups/gitlab-org/-/epics/12571).
We recorded two more demos as part of that (see the epic for more details):

- [GitLab AutoFlow PoC, iteration 1](https://www.youtube.com/watch?v=2Ntdnv2LY6I)
- [AutoFlow UI for issues triaging (Iteration 3 demo)](https://www.youtube.com/watch?v=bIBWxcJ1YTg&list=PL05JrBw4t0Kqgx_Pzuum5GeyNkMMcf2Bp&index=6)

## Links to related documents

- [Relation of GitLab AutoFlow to GitLab CI](relation_to_ci.md)
