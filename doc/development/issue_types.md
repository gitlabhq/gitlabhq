# Issue Types

Sometimes when a new resource type is added it's not clear if it should be only an
"extension" of Issue (Issue Type) or if it should be a new first-class resource type
(similar to Issue, Epic, Merge Request, Snippet).

The idea of Issue Types was first proposed in [this
issue](https://gitlab.com/gitlab-org/gitlab/issues/8767) and its usage was
discussed few times since then, for example in [incident
management](https://gitlab.com/gitlab-org/gitlab-foss/issues/55532).

## What is an Issue Type

Issue Type is a resource type which extends the existing Issue type and can be
used anywhere where Issue is used - for example when listing or searching
issues or when linking objects of the type from Epics. It should use the same
`issues` table, additional fields can be stored in a separate table.

## When an Issue Type should be used

- When the new type only adds new fields to the basic Issue type without
  removing existing fields (but it's OK if some fields from the basic Issue
  type are hidden in user interface/API).
- When the new type can be used anywhere where the basic Issue type is used.

## When a first-class resource type should be used

- When a separate model and table is used for the new resource.
- When some fields of the basic Issue type need to be removed - hiding in the UI
  is OK, but not complete removal.
- When the new resource cannot be used instead of the basic Issue type,
  for example:

  - You can't add it to an epic.
  - You can't close it from a commit or a merge request.
  - You can't mark it as related to another issue.

If an Issue type can not be used you can still define a first-class type and
then include concerns such as `Issuable` or `Noteable` to reuse functionality
which is common for all our issue-related resources. But you still need to
define the interface for working with the new resource and update some other
components to make them work with the new type.

Usage of the Issue type limits what fields, functionality, or both is available
for the type. However, this functionality is provided by default.
