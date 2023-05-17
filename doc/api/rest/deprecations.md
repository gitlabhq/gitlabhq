---
stage: Manage
group: Import and Integrate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# REST API deprecations and removals

The following API changes will occur when the v4 API is removed.

The date of this change is unknown.
For details, see [issue 216456](https://gitlab.com/gitlab-org/gitlab/-/issues/216456)
and [issue 387485](https://gitlab.com/gitlab-org/gitlab/-/issues/387485).

## `geo_nodes` API endpoints

Breaking change. [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/369140).

The [`geo_nodes` API endpoints](../geo_nodes.md) are deprecated and are replaced by [`geo_sites`](../geo_sites.md).
It is a part of the global change on [how to refer to Geo deployments](../../administration/geo/glossary.md).
Nodes are renamed to sites across the application. The functionality of both endpoints remains the same.

## `merged_by` API field

Breaking change. [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/350534).

The `merged_by` field in the [merge request API](../merge_requests.md#list-merge-requests)
has been deprecated in favor of the `merge_user` field which more correctly identifies who merged a merge request when
performing actions (merge when pipeline succeeds, add to merge train) other than a simple merge.

API users are encouraged to use the new `merge_user` field instead. The `merged_by` field will be removed in v5 of the GitLab REST API.

## `merge_status` API field

Breaking change. [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/382032).

The `merge_status` field in the [merge request API](../merge_requests.md#merge-status)
has been deprecated in favor of the `detailed_merge_status` field which more correctly identifies
all of the potential statuses that a merge request can be in. API users are encouraged to use the
new `detailed_merge_status` field instead. The `merge_status` field will be removed in v5 of the GitLab REST API.

### Null value for `private_profile` attribute in User API

Breaking change. [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/387005).

When creating and updating users through the API, `null` was a valid value for the `private_profile` attribute, which would internally be converted to the default value. In v5 of the GitLab REST API, `null` will no longer be a valid value for this parameter, and the response will be a 400 if used. After this change, the only valid values will be `true` and `false`.

## Single merge request changes API endpoint

Breaking change. [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/322117).

The endpoint to get
[changes from a single merge request](../merge_requests.md#get-single-merge-request-changes)
has been deprecated in favor the
[list merge request diffs](../merge_requests.md#list-merge-request-diffs) endpoint.
API users are encouraged to switch to the new diffs endpoint instead.

The `changes from a single merge request` endpoint will be removed in v5 of the GitLab REST API.

## Managed Licenses API endpoint

Breaking change. [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/397067).

The endpoint to get
[all managed licenses for a given project](../managed_licenses.md)
has been deprecated in favor the
[License Approval policy](../../user/compliance/license_approval_policies.md) feature.
Users who wish to continue to enforce approvals based on detected licenses are encouraged to create a new [License Approval policy](../../user/compliance/license_approval_policies.md) instead.

The `managed licenses` endpoint will be removed in v5 of the GitLab REST API.

## Approvers and Approver Group fields in Merge Request Approval API

Breaking change. [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/353097).

The endpoint to get the configuration of approvals for a project returns
empty arrays for `approvers` and `approval_groups`.
These fields were deprecated in favor of the endpoint to
[get project-level rules](../merge_request_approvals.md#get-project-level-rules)
for a merge request. API users are encouraged to switch to this endpoint instead.

These fields will be removed from the `get configuration` endpoint in v5 of the GitLab REST API.

## Runner usage of `active` replaced by `paused`

Breaking change. [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/351109).

Occurrences of the `active` identifier in the GitLab Runner GraphQL API endpoints will be
renamed to `paused` in GitLab 16.0.

- In v4 of the REST API, starting in GitLab 14.8, you can use the `paused` property in place of `active`
- In v5 of the REST API, this change will affect endpoints taking or returning `active` property, such as:
  - `GET /runners`
  - `GET /runners/all`
  - `GET /runners/:id` / `PUT /runners/:id`
  - `PUT --form "active=false" /runners/:runner_id`
  - `GET /projects/:id/runners` / `POST /projects/:id/runners`
  - `GET /groups/:id/runners`

The 16.0 release of GitLab Runner will start using the `paused` property when registering runners.

## Runner status will not return `paused`

Breaking change. [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/344648).

In a future v5 of the REST API, the endpoints for GitLab Runner will not return `paused` or `active`.

A runner's status will only relate to runner contact status, such as:
`online`, `offline`, or `not_connected`. Status `paused` or `active` will no longer appear.

When checking if a runner is `paused`, API users are advised to check the boolean attribute
`paused` to be `true` instead. When checking if a runner is `active`, check if `paused` is `false`.
