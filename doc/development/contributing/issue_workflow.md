---
type: reference, dev
stage: none
group: Development
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Issues workflow

## Issue tracker guidelines

**[Search the issue tracker](https://gitlab.com/gitlab-org/gitlab/-/issues)** for similar entries before
submitting your own, there's a good chance somebody else had the same issue or
feature proposal. Show your support with an award emoji and/or join the
discussion.

Please submit bugs using the ['Bug' issue template](https://gitlab.com/gitlab-org/gitlab/-/blob/master/.gitlab/issue_templates/Bug.md) provided on the issue tracker.
The text in the parenthesis is there to help you with what to include. Omit it
when submitting the actual issue. You can copy-paste it and then edit as you
see fit.

## Issue triaging

Our issue triage policies are [described in our handbook](https://about.gitlab.com/handbook/engineering/quality/issue-triage/).
You are very welcome to help the GitLab team triage issues.
We also organize [issue bash events](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/17815)
once every quarter.

The most important thing is making sure valid issues receive feedback from the
development team. Therefore the priority is mentioning developers that can help
on those issues. Please select someone with relevant experience from the
[GitLab team](https://about.gitlab.com/company/team/).
If there is nobody mentioned with that expertise look in the commit history for
the affected files to find someone.

We also use [GitLab Triage](https://gitlab.com/gitlab-org/gitlab-triage) to automate
some triaging policies. This is currently set up as a scheduled pipeline
(`https://gitlab.com/gitlab-org/quality/triage-ops/pipeline_schedules/10512/editpipeline_schedules/10512/edit`,
must have at least Developer access to the project) running on [quality/triage-ops](https://gitlab.com/gitlab-org/quality/triage-ops)
project.

## Labels

To allow for asynchronous issue handling, we use [milestones](https://gitlab.com/groups/gitlab-org/-/milestones)
and [labels](https://gitlab.com/gitlab-org/gitlab/-/labels). Leads and product managers handle most of the
scheduling into milestones. Labeling is a task for everyone. (For some projects, labels can be set only by GitLab team members and not by community contributors).

Most issues will have labels for at least one of the following:

- Type: `~feature`, `~bug`, `~tooling`, `~documentation`, etc.
- Stage: `~"devops::plan"`, `~"devops::create"`, etc.
- Group: `~"group::source code"`, `~"group::knowledge"`, `~"group::editor"`, etc.
- Category: `~"Category:Code Analytics"`, `~"Category:DevOps Reports"`, `~"Category:Templates"`, etc.
- Feature: `~wiki`, `~ldap`, `~api`, `~issues`, `~"merge requests"`, etc.
- Department: `~UX`, `~Quality`
- Team: `~"Technical Writing"`, `~Delivery`
- Specialization: `~frontend`, `~backend`, `~documentation`
- Release Scoping: `~Deliverable`, `~Stretch`, `~"Next Patch Release"`
- Priority: `~"priority::1"`, `~"priority::2"`, `~"priority::3"`, `~"priority::4"`
- Severity: ~`"severity::1"`, `~"severity::2"`, `~"severity::3"`, `~"severity::4"`

All labels, their meaning and priority are defined on the
[labels page](https://gitlab.com/gitlab-org/gitlab/-/labels).

If you come across an issue that has none of these, and you're allowed to set
labels, you can _always_ add the type, stage, group, and often the category/feature labels.

### Type labels

Type labels are very important. They define what kind of issue this is. Every
issue should have one and only one.

The current type labels are:

- ~feature
- ~bug
- ~tooling
- ~"support request"
- ~meta
- ~documentation

A number of type labels have a priority assigned to them, which automatically
makes them float to the top, depending on their importance.

Type labels are always lowercase, and can have any color, besides blue (which is
already reserved for category labels).

The descriptions on the [labels page](https://gitlab.com/groups/gitlab-org/-/labels)
explain what falls under each type label.

The GitLab handbook documents [when something is a bug](https://about.gitlab.com/handbook/product/product-processes/#bug-issues) and [when it is a feature request](https://about.gitlab.com/handbook/product/product-processes/#feature-issues).

### Stage labels

Stage labels specify which [stage](https://about.gitlab.com/handbook/product/categories/#hierarchy) the issue belongs to.

#### Naming and color convention

Stage labels respects the `devops::<stage_key>` naming convention.
`<stage_key>` is the stage key as it is in the single source of truth for stages at
<https://gitlab.com/gitlab-com/www-gitlab-com/blob/master/data/stages.yml>
with `_` replaced with a space.

For instance, the "Manage" stage is represented by the `~"devops::manage"` label in
the `gitlab-org` group since its key under `stages` is `manage`.

The current stage labels can be found by [searching the labels list for `devops::`](https://gitlab.com/groups/gitlab-org/-/labels?search=devops::).

These labels are [scoped labels](../../user/project/labels.md#scoped-labels)
and thus are mutually exclusive.

The Stage labels are used to generate the [direction pages](https://about.gitlab.com/direction/) automatically.

### Group labels

Group labels specify which [groups](https://about.gitlab.com/company/team/structure/#product-groups) the issue belongs to.

It's highly recommended to add a group label, as it's used by our triage
automation to
[infer the correct stage label](https://about.gitlab.com/handbook/engineering/quality/triage-operations/#auto-labelling-of-issues).

#### Naming and color convention

Group labels respects the `group::<group_key>` naming convention and
their color is `#A8D695`.
`<group_key>` is the group key as it is in the single source of truth for groups at
<https://gitlab.com/gitlab-com/www-gitlab-com/blob/master/data/stages.yml>,
with `_` replaced with a space.

For instance, the "Continuous Integration" group is represented by the
~"group::continuous integration" label in the `gitlab-org` group since its key
under `stages.manage.groups` is `continuous_integration`.

The current group labels can be found by [searching the labels list for `group::`](https://gitlab.com/groups/gitlab-org/-/labels?search=group::).

These labels are [scoped labels](../../user/project/labels.md#scoped-labels)
and thus are mutually exclusive.

You can find the groups listed in the [Product Stages, Groups, and Categories](https://about.gitlab.com/handbook/product/categories/) page.

We use the term group to map down product requirements from our product stages.
As a team needs some way to collect the work their members are planning to be assigned to, we use the `~group::` labels to do so.

Normally there is a 1:1 relationship between Stage labels and Group labels. In
the spirit of "Everyone can contribute", any issue can be picked up by any group,
depending on current priorities. When picking up an issue belonging to a different
group, it should be relabeled. For example, if an issue labeled `~"devops::create"`
and `~"group::knowledge"` is picked up by someone in the Access group of the Plan stage,
the issue should be relabeled as `~"group::access"` while keeping the original
`~"devops::create"` unchanged.

We also use stage and group labels to help measure our [merge request rates](https://about.gitlab.com/handbook/engineering/metrics/#merge-request-rate).
Please read [Stage and Group labels](https://about.gitlab.com/handbook/engineering/metrics/#stage-and-group-labels) for more information on how the labels are used in this context.

### Category labels

From the handbook's
[Product stages, groups, and categories](https://about.gitlab.com/handbook/product/categories/#hierarchy)
page:

> Categories are high-level capabilities that may be a standalone product at
another company. e.g. Portfolio Management.

It's highly recommended to add a category label, as it's used by our triage
automation to
[infer the correct group and stage labels](https://about.gitlab.com/handbook/engineering/quality/triage-operations/#auto-labelling-of-issues).

If you are an expert in a particular area, it makes it easier to find issues to
work on. You can also subscribe to those labels to receive an email each time an
issue is labeled with a category label corresponding to your expertise.

#### Naming and color convention

Category labels respects the `Category:<Category Name>` naming convention and
their color is `#428BCA`.
`<Category Name>` is the category name as it is in the single source of truth for categories at
<https://gitlab.com/gitlab-com/www-gitlab-com/blob/master/data/categories.yml>.

For instance, the "DevOps Report" category is represented by the
~"Category:DevOps Reports" label in the `gitlab-org` group since its
`devops_reports.name` value is "DevOps Reports".

If a category's label doesn't respect this naming convention, it should be specified
with [the `label` attribute](https://about.gitlab.com/handbook/marketing/inbound-marketing/digital-experience/website/#category-attributes)
in <https://gitlab.com/gitlab-com/www-gitlab-com/blob/master/data/categories.yml>.

### Feature labels

From the handbook's
[Product stages, groups, and categories](https://about.gitlab.com/handbook/product/categories/#hierarchy)
page:

> Features: Small, discrete functionalities. e.g. Issue weights. Some common
features are listed within parentheses to facilitate finding responsible PMs by keyword.

It's highly recommended to add a feature label if no category label applies, as
it's used by our triage automation to
[infer the correct group and stage labels](https://about.gitlab.com/handbook/engineering/quality/triage-operations/#auto-labelling-of-issues).

If you are an expert in a particular area, it makes it easier to find issues to
work on. You can also subscribe to those labels to receive an email each time an
issue is labeled with a feature label corresponding to your expertise.

Examples of feature labels are `~wiki`, `~ldap`, `~api`, `~issues`, `~"merge requests"` etc.

#### Naming and color convention

Feature labels are all-lowercase.

### Facet labels

To track additional information or context about created issues, developers may
add _facet labels_. Facet labels are also sometimes used for issue prioritization
or for measurements (such as time to close). An example of a facet label is the
~customer label, which indicates customer interest.

### Department labels

The current department labels are:

- ~UX
- ~Quality

### Team labels

**Important**: Most of the historical team labels (e.g. Manage, Plan etc.) are
now deprecated in favor of [Group labels](#group-labels) and [Stage labels](#stage-labels).

Team labels specify what team is responsible for this issue.
Assigning a team label makes sure issues get the attention of the appropriate
people.

The current team labels are:

- ~Delivery
- ~"Technical Writing"

#### Naming and color convention

Team labels are always capitalized so that they show up as the first label for
any issue.

### Specialization labels

These labels narrow the [specialization](https://about.gitlab.com/company/team/structure/#specialist) on a unit of work.

- ~frontend
- ~backend
- ~documentation

### Release scoping labels

Release Scoping labels help us clearly communicate expectations of the work for the
release. There are three levels of Release Scoping labels:

- ~Deliverable: Issues that are expected to be delivered in the current
  milestone.
- ~Stretch: Issues that are a stretch goal for delivering in the current
  milestone. If these issues are not done in the current release, they will
  strongly be considered for the next release.
- ~"Next Patch Release": Issues to put in the next patch release. Work on these
  first, and add the `~"Pick into X.Y"` label to the merge request, along with the
  appropriate milestone.

Each issue scheduled for the current milestone should be labeled ~Deliverable
or ~"Stretch". Any open issue for a previous milestone should be labeled
~"Next Patch Release", or otherwise rescheduled to a different milestone.

### Priority labels

We have the following priority labels:

- ~"priority::1"
- ~"priority::2"
- ~"priority::3"
- ~"priority::4"

Please refer to the issue triage [priority label](https://about.gitlab.com/handbook/engineering/quality/issue-triage/#priority) section in our handbook to see how it's used.

### Severity labels

We have the following severity labels:

- ~"severity::1"
- ~"severity::2"
- ~"severity::3"
- ~"severity::4"

Please refer to the issue triage [severity label](https://about.gitlab.com/handbook/engineering/quality/issue-triage/#severity) section in our handbook to see how it's used.

### Label for community contributors

Issues that are beneficial to our users, 'nice to haves', that we currently do
not have the capacity for or want to give the priority to, are labeled as
~"Accepting merge requests", so the community can make a contribution.

Community contributors can submit merge requests for any issue they want, but
the ~"Accepting merge requests" label has a special meaning. It points to
changes that:

1. We already agreed on,
1. Are well-defined,
1. Are likely to get accepted by a maintainer.

We want to avoid a situation when a contributor picks an
~"Accepting merge requests" issue and then their merge request gets closed,
because we realize that it does not fit our vision, or we want to solve it in a
different way.

We automatically add the ~"Accepting merge requests" label to issues
that match the [triage policy](https://about.gitlab.com/handbook/engineering/quality/triage-operations/#accepting-merge-requests).

We recommend people that have never contributed to any open source project to
look for issues labeled `~"Accepting merge requests"` with a [weight of 1](https://gitlab.com/groups/gitlab-org/-/issues?state=opened&label_name[]=Accepting+merge+requests&assignee_id=None&sort=weight&weight=1) or the `~"Good for new contributors"` [label](https://gitlab.com/gitlab-org/gitlab/-/issues?scope=all&state=opened&label_name[]=good%20for%20new%20contributors&assignee_id=None) attached to it.
More experienced contributors are very welcome to tackle
[any of them](https://gitlab.com/groups/gitlab-org/-/issues?state=opened&label_name[]=Accepting+merge+requests&assignee_id=None).

For more complex features that have a weight of 2 or more and clear scope, we recommend looking at issues
with the [label `~"Community Challenge"`](https://gitlab.com/gitlab-org/gitlab/-/issues?scope=all&state=opened&label_name[]=Accepting%20merge%20requests&label_name[]=Community%20challenge).
If your MR for the `~"Community Challenge"` issue gets merged, you will also have a chance to win a custom
GitLab merchandise.

If you've decided that you would like to work on an issue, please @-mention
the [appropriate product manager](https://about.gitlab.com/handbook/product/#who-to-talk-to-for-what)
as soon as possible. The product manager will then pull in appropriate GitLab team
members to further discuss scope, design, and technical considerations. This will
ensure that your contribution is aligned with the GitLab product and minimize
any rework and delay in getting it merged into main.

GitLab team members who apply the ~"Accepting merge requests" label to an issue
should update the issue description with a responsible product manager, inviting
any potential community contributor to @-mention per above.

### Stewardship label

For issues related to the open source stewardship of GitLab,
there is the ~"stewardship" label.

This label is to be used for issues in which the stewardship of GitLab
is a topic of discussion. For instance if GitLab Inc. is planning to add
features from GitLab EE to GitLab CE, related issues would be labeled with
~"stewardship".

A recent example of this was the issue for
[bringing the time tracking API to GitLab CE](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/25517#note_20019084).

## Feature proposals

To create a feature proposal, open an issue on the
[issue tracker](https://gitlab.com/gitlab-org/gitlab/-/issues).

In order to help track the feature proposals, we have created a
[`feature`](https://gitlab.com/gitlab-org/gitlab/-/issues?label_name=feature) label. For the time being, users that are not members
of the project cannot add labels. You can instead ask one of the [core team](https://about.gitlab.com/community/core-team/)
members to add the label ~feature to the issue or add the following
code snippet right after your description in a new line: `~feature`.

Please keep feature proposals as small and simple as possible, complex ones
might be edited to make them small and simple.

Please submit Feature Proposals using the ['Feature Proposal' issue template](https://gitlab.com/gitlab-org/gitlab/-/blob/master/.gitlab/issue_templates/Feature%20proposal%20-%20detailed.md) provided on the issue tracker.

For changes in the interface, it is helpful to include a mockup. Issues that add to, or change, the interface should
be given the ~"UX" label. This will allow the UX team to provide input and guidance. You may
need to ask one of the [core team](https://about.gitlab.com/community/core-team/) members to add the label, if you do not have permissions to do it by yourself.

If you want to create something yourself, consider opening an issue first to
discuss whether it is interesting to include this in GitLab.

## Issue weight

Issue weight allows us to get an idea of the amount of work required to solve
one or multiple issues. This makes it possible to schedule work more accurately.

You are encouraged to set the weight of any issue. Following the guidelines
below will make it easy to manage this, without unnecessary overhead.

1. Set weight for any issue at the earliest possible convenience
1. If you don't agree with a set weight, discuss with other developers until
   consensus is reached about the weight
1. Issue weights are an abstract measurement of complexity of the issue. Do not
   relate issue weight directly to time. This is called [anchoring](https://en.wikipedia.org/wiki/Anchoring)
   and something you want to avoid.
1. Something that has a weight of 1 (or no weight) is really small and simple.
   Something that is 9 is rewriting a large fundamental part of GitLab,
   which might lead to many hard problems to solve. Changing some text in GitLab
   is probably 1, adding a new Git Hook maybe 4 or 5, big features 7-9.
1. If something is very large, it should probably be split up in multiple
   issues or chunks. You can simply not set the weight of a parent issue and set
   weights to children issues.

## Regression issues

Every monthly release has a corresponding issue on the CE issue tracker to keep
track of functionality broken by that release and any fixes that need to be
included in a patch release (see
[8.3 Regressions](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/4127) as an example).

As outlined in the issue description, the intended workflow is to post one note
with a reference to an issue describing the regression, and then to update that
note with a reference to the merge request that fixes it as it becomes available.

If you're a contributor who doesn't have the required permissions to update
other users' notes, please post a new note with a reference to both the issue
and the merge request.

The release manager will
[update the notes](https://gitlab.com/gitlab-org/release-tools/blob/master/doc/pro-tips.md#update-the-regression-issue)
in the regression issue as fixes are addressed.

## Technical and UX debt

In order to track things that can be improved in the GitLab codebase,
we use the ~"technical debt" label in the [GitLab issue tracker](https://gitlab.com/gitlab-org/gitlab/-/issues).
We use the ~"UX debt" label when we choose to deviate from the MVC, in a way that harms the user experience.

These labels should be added to issues that describe things that can be improved,
shortcuts that have been taken, features that need additional attention, and all
other things that have been left behind due to high velocity of development.
For example, code that needs refactoring should use the ~"technical debt" label,
something that didn't ship according to our Design System guidelines should
use the ~"UX debt" label.

Everyone can create an issue, though you may need to ask for adding a specific
label, if you do not have permissions to do it by yourself. Additional labels
can be combined with these labels, to make it easier to schedule
the improvements for a release.

Issues tagged with these labels have the same priority like issues
that describe a new feature to be introduced in GitLab, and should be scheduled
for a release by the appropriate person.

Make sure to mention the merge request that the ~"technical debt" issue or
~"UX debt" issue is associated with in the description of the issue.

## Technical debt in follow-up issues

It's common to discover technical debt during development of a new feature. In
the spirit of "minimum viable change", resolution is often deferred to a
follow-up issue. However, this cannot be used as an excuse to merge poor-quality
code that would otherwise not pass review, or to overlook trivial matters that
don't deserve to be scheduled independently, and would be best resolved in the
original merge request - or not tracked at all!

The overheads of scheduling, and rate of change in the GitLab codebase, mean
that the cost of a trivial technical debt issue can quickly exceed the value of
tracking it. This generally means we should resolve these in the original merge
request - or simply not create a follow-up issue at all.

For example, a typo in a comment that is being copied between files is worth
fixing in the same MR, but not worth creating a follow-up issue for. Renaming a
method that is used in many places to make its intent slightly clearer may be
worth fixing, but it should not happen in the same MR, and is generally not
worth the overhead of having an issue of its own. These issues would invariably
be labeled `~P4 ~S4` if we were to create them.

More severe technical debt can have implications for development velocity. If
it isn't addressed in a timely manner, the codebase becomes needlessly difficult
to change, new features become difficult to add, and regressions abound.

Discoveries of this kind of technical debt should be treated seriously, and
while resolution in a follow-up issue may be appropriate, maintainers should
generally obtain a scheduling commitment from the author of the original MR, or
the engineering or product manager for the relevant area. This may take the form
of appropriate Priority / Severity labels on the issue, or an explicit milestone
and assignee.

The maintainer must always agree before an outstanding discussion is resolved in
this manner, and will be the one to create the issue. The title and description
should be of the same quality as those created
[in the usual manner](#technical-and-ux-debt) - in particular, the issue title
**must not** begin with `Follow-up`! The creating maintainer should also expect
to be involved in some capacity when work begins on the follow-up issue.

---

[Return to Contributing documentation](index.md)
