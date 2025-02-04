---
stage: none
group: unassigned
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: Labels
---

To allow for asynchronous issue handling, we use [milestones](https://gitlab.com/groups/gitlab-org/-/milestones)
and [labels](https://gitlab.com/gitlab-org/gitlab/-/labels). Leads and product managers handle most of the
scheduling into milestones. Labeling is a task for everyone. (For some projects, labels can be set only by GitLab team members and not by community contributors).

Most issues will have labels for at least one of the following:

- Type. For example: `~"type::feature"`, `~"type::bug"`, or `~"type::maintenance"`.
- Stage. For example: `~"devops::plan"` or `~"devops::create"`.
- Group. For example: `~"group::source code"`, `~"group::knowledge"`, or `~"group::editor"`.
- Category. For example: `~"Category:Code Analytics"`, `~"Category:DevOps Reports"`, or `~"Category:Templates"`.
- Feature. For example: `~wiki`, `~ldap`, `~api`, `~issues`, or `~"merge requests"`.
- Department: `~UX`, `~Quality`
- Team: `~"Technical Writing"`, `~Delivery`
- Specialization: `~frontend`, `~backend`, `~documentation`
- Release Scoping: `~Deliverable`, `~Stretch`, `~"Next Patch Release"`
- Priority: `~"priority::1"`, `~"priority::2"`, `~"priority::3"`, `~"priority::4"`
- Severity: `~"severity::1"`, `~"severity::2"`, `~"severity::3"`, `~"severity::4"`

Add `~"breaking change"` label if the issue can be considered as a [breaking change](../deprecation_guidelines/_index.md).

Add `~security` label if the issue is related to application security.

All labels, their meaning and priority are defined on the
[labels page](https://gitlab.com/gitlab-org/gitlab/-/labels).

If you come across an issue that has none of these, and you're allowed to set
labels, you can _always_ add the type, stage, group, and often the category/feature labels.

## Type labels

Type labels are very important. They define what kind of issue this is. Every
issue should have one and only one.

The SSOT for type and subtype labels is [available in the handbook](https://handbook.gitlab.com/handbook/product/groups/product-analysis/engineering/metrics/#work-type-classification).

A number of type labels have a priority assigned to them, which automatically
makes them float to the top, depending on their importance.

Type labels are always lowercase, and can have any color, besides blue (which is
already reserved for category labels).

The descriptions on the [labels page](https://gitlab.com/groups/gitlab-org/-/labels)
explain what falls under each type label.

The GitLab handbook documents [when something is a bug](https://handbook.gitlab.com/handbook/product/product-processes/#bug-issues) and [when it is a feature request](https://handbook.gitlab.com/handbook/product/product-processes/#feature-issues).

## Stage labels

Stage labels specify which [stage](https://handbook.gitlab.com/handbook/product/categories/#hierarchy) the issue belongs to.

### Naming and color convention

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

## Group labels

Group labels specify which [groups](https://handbook.gitlab.com/handbook/company/structure/#product-groups) the issue belongs to.

It's highly recommended to add a group label, as it's used by our triage
automation to
[infer the correct stage label](https://handbook.gitlab.com/handbook/engineering/infrastructure/engineering-productivity/triage-operations/#auto-labelling-of-issues-and-merge-requests).

### Naming and color convention

Group labels respects the `group::<group_key>` naming convention and
their color is `#A8D695`.
`<group_key>` is the group key as it is in the single source of truth for groups at
<https://gitlab.com/gitlab-com/www-gitlab-com/blob/master/data/stages.yml>,
with `_` replaced with a space.

For instance, the "Pipeline Execution" group is represented by the
`~"group::pipeline execution"` label in the `gitlab-org` group since its key
under `stages.manage.groups` is `pipeline_execution`.

The current group labels can be found by [searching the labels list for `group::`](https://gitlab.com/groups/gitlab-org/-/labels?search=group::).

These labels are [scoped labels](../../user/project/labels.md#scoped-labels)
and thus are mutually exclusive.

You can find the groups listed in the [Product Stages, Groups, and Categories](https://handbook.gitlab.com/handbook/product/categories/) page.

We use the term group to map down product requirements from our product stages.
As a team needs some way to collect the work their members are planning to be assigned to, we use the `~group::` labels to do so.

## Category labels

From the handbook's
[Product stages, groups, and categories](https://handbook.gitlab.com/handbook/product/categories/#hierarchy)
page:

> Categories are high-level capabilities that may be a standalone product at
another company, such as Portfolio Management, for example.

It's highly recommended to add a category label, as it's used by our triage
automation to
[infer the correct group and stage labels](https://handbook.gitlab.com/handbook/engineering/infrastructure/engineering-productivity/triage-operations/#auto-labelling-of-issues).

If you are an expert in a particular area, it makes it easier to find issues to
work on. You can also subscribe to those labels to receive an email each time an
issue is labeled with a category label corresponding to your expertise.

### Naming and color convention

Category labels respects the `Category:<Category Name>` naming convention and
their color is `#428BCA`.
`<Category Name>` is the category name as it is in the single source of truth for categories at
<https://gitlab.com/gitlab-com/www-gitlab-com/blob/master/data/categories.yml>.

For instance, the "DevOps Reports" category is represented by the
`~"Category:DevOps Reports"` label in the `gitlab-org` group since its
`devops_reports.name` value is "DevOps Reports".

If a category's label doesn't respect this naming convention, it should be specified
with [the `label` attribute](https://handbook.gitlab.com/handbook/marketing/digital-experience/website/#category-attributes)
in <https://gitlab.com/gitlab-com/www-gitlab-com/blob/master/data/categories.yml>.

## Feature labels

From the handbook's
[Product stages, groups, and categories](https://handbook.gitlab.com/handbook/product/categories/#hierarchy)
page:

> Features: Small, discrete functionalities, for example Issue weights. Some common
features are listed within parentheses to facilitate finding responsible PMs by keyword.

It's highly recommended to add a feature label if no category label applies, as
it's used by our triage automation to
[infer the correct group and stage labels](https://handbook.gitlab.com/handbook/engineering/infrastructure/engineering-productivity/triage-operations/#auto-labelling-of-issues).

If you are an expert in a particular area, it makes it easier to find issues to
work on. You can also subscribe to those labels to receive an email each time an
issue is labeled with a feature label corresponding to your expertise.

Examples of feature labels are `~wiki`, `~ldap`, `~api`, `~issues`, and `~"merge requests"`.

### Naming and color convention

Feature labels are all-lowercase.

## Workflow labels

Issues use the following workflow labels to specify the current issue status:

- `~"workflow::awaiting security release"`
- `~"workflow::blocked"`
- `~"workflow::complete"`
- `~"workflow::design"`
- `~"workflow::feature-flagged"`
- `~"workflow::in dev"`
- `~"workflow::in review"`
- `~"workflow::planning breakdown"`
- `~"workflow::problem validation"`
- `~"workflow::production"`
- `~"workflow::ready for design"`
- `~"workflow::ready for development"`
- `~"workflow::refinement"`
- `~"workflow::scheduling"`
- `~"workflow::solution validation"`
- `~"workflow::start"`
- `~"workflow::validation backlog"`
- `~"workflow::verification"`

## Facet labels

To track additional information or context about created issues, developers may
add _facet labels_. Facet labels are also sometimes used for issue prioritization
or for measurements (such as time to close). An example of a facet label is the
`~"customer"` label, which indicates customer interest.

## Department labels

The current department labels are:

- `~"UX"`
- `~"Quality"`
- `~"infrastructure"`
- `~"security"`

## Team labels

**Important**: Most of the historical team labels (like Manage or Plan) are
now deprecated in favor of [Group labels](#group-labels) and [Stage labels](#stage-labels).

Team labels specify what team is responsible for this issue.
Assigning a team label makes sure issues get the attention of the appropriate
people.

The current team labels are:

- `~"Delivery"`
- `~"Technical Writing"`
- `~"Engineering Productivity"`
- `~"Contributor Success"`

### Naming and color convention

Team labels are always capitalized so that they show up as the first label for
any issue.

## Specialization labels

These labels narrow the [specialization](https://handbook.gitlab.com/handbook/company/structure/#specialist) on a unit of work.

- `~"frontend"`
- `~"backend"`
- `~"documentation"`

## Release scoping labels

Release Scoping labels help us clearly communicate expectations of the work for the
release. There are three levels of Release Scoping labels:

- `~"Deliverable"`: Issues that are expected to be delivered in the current
  milestone.
- `~"Stretch"`: Issues that are a stretch goal for delivering in the current
  milestone. If these issues are not done in the current release, they will
  strongly be considered for the next release.
- `~"Next Patch Release"`: Issues to put in the next patch release. Work on these
  first, and follow the [patch release runbook](https://gitlab.com/gitlab-org/release/docs/-/blob/master/general/patch/engineers.md) to backport the bug fix to the current version.

Each issue scheduled for the current milestone should be labeled `~"Deliverable"~`
or `~"Stretch"`. Any open issue for a previous milestone should be labeled
`~"Next Patch Release"`, or otherwise rescheduled to a different milestone.

## Priority labels

We have the following priority labels:

- `~"priority::1"`
- `~"priority::2"`
- `~"priority::3"`
- `~"priority::4"`

Refer to the issue triage [priority label](https://handbook.gitlab.com/handbook/engineering/infrastructure/engineering-productivity/issue-triage/#priority) section in our handbook to see how it's used.

## Severity labels

We have the following severity labels:

- `~"severity::1"`
- `~"severity::2"`
- `~"severity::3"`
- `~"severity::4"`

Refer to the issue triage [severity label](https://handbook.gitlab.com/handbook/engineering/infrastructure/engineering-productivity/issue-triage/#severity) section in our handbook to see how it's used.

## Label for community contributors

There are many issues that have a clear solution with uncontroversial benefit to GitLab users.
However, GitLab might not have the capacity for all these proposals in the current roadmap.
These issues are labeled `~"Seeking community contributions"` because we welcome merge requests to resolve them.

Community contributors can submit merge requests for any issue they want, but
the `~"Seeking community contributions"` label has a special meaning. It points to
changes that:

1. We already agreed on,
1. Are well-defined,
1. Are likely to get accepted by a maintainer.

We want to avoid a situation when a contributor picks an
~"Seeking community contributions" issue and then their merge request gets closed,
because we realize that it does not fit our vision, or we want to solve it in a
different way.

We manually add the `~"Seeking community contributions"` label to issues
that fit the criteria described above.
We do not automatically add this label, because it requires human evaluation.

We recommend people that have never contributed to any open source project to
look for issues labeled `~"Seeking community contributions"` with a
[weight of 1](https://gitlab.com/groups/gitlab-org/-/issues?sort=created_date&state=opened&label_name[]=Seeking+community+contributions&assignee_id=None&weight=1) or the `~"quick win"`
[label](https://gitlab.com/gitlab-org/gitlab/-/issues?scope=all&state=opened&label_name[]=quick%20win&assignee_id=None)
attached to it.
More experienced contributors are very welcome to tackle
[any of them](https://gitlab.com/groups/gitlab-org/-/issues?sort=created_date&state=opened&label_name[]=Seeking+community+contributions&assignee_id=None).

For more complex features that have a weight of 2 or more and clear scope, we recommend looking at issues
with the [label `~"Community Challenge"`](https://gitlab.com/gitlab-org/gitlab/-/issues?sort=created_date&state=opened&label_name[]=Seeking+community+contributions&label_name[]=Community+challenge).
If your MR for the `~"Community Challenge"` issue gets merged, you will also have a chance to win a custom
GitLab merchandise.

If you've decided that you would like to work on an issue, @-mention
the [appropriate product manager](https://handbook.gitlab.com/handbook/product/how-to-engage/)
as soon as possible. The product manager will then pull in appropriate GitLab team
members to further discuss scope, design, and technical considerations. This will
ensure that your contribution is aligned with the GitLab product and minimize
any rework and delay in getting it merged into main.

GitLab team members who apply the `~"Seeking community contributions"` label to an issue
should update the issue description with a responsible product manager, inviting
any potential community contributor to @-mention per above.

## Stewardship label

For issues related to the open source stewardship of GitLab,
there is the `~"stewardship"` label.

This label is to be used for issues in which the stewardship of GitLab
is a topic of discussion. For instance if GitLab Inc. is planning to add
features from GitLab EE to GitLab CE, related issues would be labeled with
`~"stewardship"`.

A recent example of this was the issue for
[bringing the time tracking API to GitLab CE](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/25517#note_20019084).

## Technical debt and Deferred UX

In order to track things that can be improved in the GitLab codebase,
we use the `~"technical debt"` label in the [GitLab issue tracker](https://gitlab.com/gitlab-org/gitlab/-/issues).
We use the `~"Deferred UX"` label when we choose to deviate from the MVC, in a way that harms the user experience.

These labels should be added to issues that describe things that can be improved,
shortcuts that have been taken, features that need additional attention, and all
other things that have been left behind due to high velocity of development.
For example, code that needs refactoring should use the `~"technical debt"` label,
something that didn't ship according to our Design System guidelines should
use the `~"Deferred UX"` label.

Everyone can create an issue, though you may need to ask for adding a specific
label, if you do not have permissions to do it by yourself. Additional labels
can be combined with these labels, to make it easier to schedule
the improvements for a release.

Issues tagged with these labels have the same priority like issues
that describe a new feature to be introduced in GitLab, and should be scheduled
for a release by the appropriate person.

Make sure to mention the merge request that the `~"technical debt"` issue or
`~"Deferred UX"` issue is associated with in the description of the issue.
