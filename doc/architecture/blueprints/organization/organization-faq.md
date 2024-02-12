---
stage: enablement
group: Tenant Scale
description: 'Organization: FAQ'
---

# Organization: Frequently Asked Questions

## Do we expect large SaaS customers to be licensed at the Organization level, for example to have the ability to include multiple top-level Groups under on license?

Yes, this has been discussed with Fulfillment and is part of the post MVC roadmap for Organizations.
See also [Alignment between Organization and Fulfillment](index.md#alignment-between-organization-and-fulfillment).

## Do we expect to be able to configure alternate GitLab domain names for Organizations (such as `customer.gitlab.com`)?

There is no plan at this point to allow configuration of alternate GitLab domain names.
We have previously heard that sub-domains bring administrative challenges.
GitLab Dedicated will be a much better fit for that at this moment.

## Do we expect Organizations to have visibility settings (public/private) of their own? Will visibility remain a property of top-level Groups?

Organizations are public for now but will have their own independent visibility settings.
See also [When can Users see an Organization?](organization-users.md#when-can-users-see-an-organization).

## What would the migration of a feature from the top-level Group to the Organization look like?

One of our requirements is that everything needs to be mapped to an Organization.
Only that way will we achieve the isolation we are striving for.
For SaaS, all existing Groups and Projects are already mapped to `Org_ID = 1` in the backend.
`Org_ID = 1` corresponds to the `Default Organization`, meaning that upon Organization rollout, all existing Groups and Projects will be part of the default Organization and will be seen in that context.
Because we want to achieve as much parity as possible between SaaS and self-managed, self-managed customers would also get everything mapped to the default Organization.
The difference between SaaS and self-managed is that for SaaS we expect users to create many Organizations, and for self-managed we do not.
We will control this via a `can_create_organization` application setting that will be enabled by default on SaaS and disabled by default for self-managed users.

Consider whether your feature can support cascading, or in other words, whether the functionality is capable of existing on multiple nested levels without causing conflicts.
If your feature can support cascading:

- Today, you should add your feature to the top-level Group for both SaaS and self-managed, and to the instance for self-managed.
- Once the Organization is ready, you would migrate your instance level feature over the Organization object at which point it would be available at both the Organization and top-level Group for all customers.

If your feature cannot support cascading:

- Today, you should add your feature to the top-level Group for SaaS only, and to the instance for self-managed. The top-level Group functionality would be hidden for self-managed users.
- Once the Organization is ready, you would migrate instance functionality to the Organization for self-managed customers, but hide it at the Organization level for SaaS. On SaaS, users would continue to manage their functionality at the top-level Group, and not at the Organization level. At some point in the future when 99% of paying customers have moved to their own Organization, you could clean things up by introducing a breaking change and unhiding it from the Organization level for all customers (SaaS and self-managed) and removing the functionality from the top-level Group.
