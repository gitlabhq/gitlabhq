---
stage: none
group: unassigned
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Single Table Inheritance

**Summary:** don't use Single Table Inheritance (STI), use separate tables
instead.

Rails makes it possible to have multiple models stored in the same table and map
these rows to the correct models using a `type` column. This can be used to for
example store two different types of SSH keys in the same table.

While tempting to use one should avoid this at all costs for the same reasons as
outlined in the document ["Polymorphic Associations"](polymorphic_associations.md).

## Solution

The solution is very simple: just use a separate table for every type you'd
otherwise store in the same table. For example, instead of having a `keys` table
with `type` set to either `Key` or `DeployKey` you'd have two separate tables:
`keys` and `deploy_keys`.
