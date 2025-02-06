---
stage: none
group: unassigned
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Acceptable Use of User Licenses
---

## User Licenses and Affiliates

### Affiliated companies' ability to separately purchase user licenses under one master agreement

Affiliated companies may each purchase user licenses directly from GitLab under one master agreement,
subject to the terms of an applicable transaction document between GitLab and the specific company.

A customer may also purchase user licenses and deploy those licenses to an affiliated company, subject to the requirements below.

### Customers' ability to purchase user licenses and deploy those licenses to an affiliated company

With some exceptions, a customer may purchase user licenses and deploy those licenses to an affiliated entity.
GitLab can accommodate affiliated companies' internal procurement requirements and billing policies,
provided these requirements are clearly communicated in advance of purchase and prior to billing.

GitLab is a global company and may use region-specific pricing. If a customer wants to deploy user licenses outside of
the Geographical Region (defined below) where the customer purchased the licenses, including to an affiliated company,
GitLab may require the customer or affiliated company to accept alternate pricing and conditions.

### Distinct geographical region: definition

The "Geographical Region" is defined as within 4,000 miles, or 6,437 kilometers, of the "Sold To" address set forth in the quote provided by GitLab.
Any use, access, or distribution of the licenses outside the Geographical Region is strictly prohibited unless approved by GitLab in writing.

## Use of Multiple Tiers

GitLab offers three tiers of its Software: (1) Free, (2) Premium, and (3) Ultimate. See <https://about.gitlab.com/pricing/feature-comparison/>.

Customers may use multiple tiers of the software, subject to the requirements in this section, Use of Multiple Tiers, and the section below, Use of Multiple Instances.

### Customers' ability use different tiers of GitLab Software

With some exceptions, a customer may use different tiers of GitLab Software. This requires multiple instances
(see below, Use of Multiple Instances). For example, a customer may have distinct business units or
affiliated companies that each require varying features of the GitLab Software. That customer may desire to deploy a Premium instance for
one business unit and an Ultimate instance for another business unit.

Customers should ensure that use of such multiple instances is kept separate and distinct to avoid prohibited commingling of features, as further discussed below in this section.

<!-- markdownlint-disable MD013 -->

### Customers' (or a customer's business unit or affiliates) ability to use features from its Premium (or Ultimate) instance with code developed in a Free instance

This is a prohibited commingling of features. While there are times a customer may legitimately require multiple instances of
different tiers of GitLab Software, customers are limited to the features of the specific tier of the instance in question.
In this case, while a customer may have a legitimate need for a Free and Premium (or Ultimate) instance, that customer is prohibited from
using features from the Premium (or Ultimate) instance with code developed in the Free instance.

<!-- markdownlint-enable MD013 -->

### Customers' ability to use features from an Ultimate instance with code developed in a Premium instance

This is a prohibited commingling of features. While there are times a customer may legitimately require multiple instances and
different tiers of GitLab Software, customers are limited to the features of the specific tier of the instance in question.
In this case, while a customer may have a legitimate need for a Premium and Ultimate instance, that customer is prohibited from
using features from the Ultimate instance (such as security scanning) with code developed in the Premium instance.

## Use of Multiple Instances

### Customers' ability to have multiple instances

Some customers may desire to have multiple, distinct GitLab instances for different teams, subsidiary companies, etc.
At times, customers may desire to have multiple GitLab instances with the same users on each instance.
Depending on their specific use case, this may require one or multiple subscriptions to accommodate.
Use of multiple instances is also subject to the restrictions above regarding Use of Multiple Tiers.

### Customers' ability to have multiple instances of Free tier (GitLab.com or self-managed)

Customers may have multiple instances of Free tier, subject to some exceptions.

For the Free tier of GitLab.com, [there is a five-user maximum on a top-level namespace with private visibility](../user/free_user_limit.md) per customer or entity.
This five-user maximum is in the aggregate of any Free tier instances. So, for example, if a customer has one Free tier instance with five users,
that customer is prohibited from activating an additional Free tier instance of any user level since the five-user maximum has been met.

For the Free tier of self-managed, there is no five-user maximum.

### Customers' ability to have multiple instances of GitLab.com or Dedicated

Customers may have multiple instances of GitLab.com or Dedicated, provided that the customer purchases a subscription for each of the desired instances.

### Customers' ability to have multiple instances of self-managed with the same Users

This is technically possible, subject to certain conditions:

Subject to the terms of a written agreement between customer and GitLab, one Cloud Licensing activation code (or license key) may
be applied to multiple self-managed instances provided that the users on the instances:

- Are the same, or
- Are a subset of the customer's licensed production instance.

For example, if the customer has a licensed production instance of GitLab, and the customer has other instances with the same list of users,
the production activation code (or license key) will apply. Even if these users are configured in different groups and projects,
as long as the user list is the same, the activation code (or license key) will apply.

However, if either of the conditions above are not met, customer will need to purchase an additional subscription for a separate instance for those users.

## Use of multiple self-managed instances with a single license key or activation code

### Validating when one license or activation code is applied to multiple instances

GitLab requires a written agreement with its customers regarding its right to audit and verify customer compliance with the terms of this Documentation.

### Calculating billable users when one license key or activation code is applied to multiple instances

When a single license file or activation code is applied to more than one instance, GitLab checks across all of the instances associated with
the subscription to identify the instance with the **highest billable user count**. This will be the instance used for calculating values such as
`billable users` and `max users`, and will be used for Quarterly Subscription Reconciliation and Auto-renewal (if enabled).

With this approach, GitLab makes the assumption that all other lower user count instances contain the same or a subset of users of this main instance.

<!-- markdownlint-disable MD013 -->

### Visibility into latest usage data, and how to identify which of the customer's instances the data is for

Self-managed usage data shared is stored in CustomersDot under `License seat links`. Data is recorded daily for customers on
Cloud Licensing and whenever customers on Offline licenses share their usage data via email (requested monthly).
To view this data, the customer can search by `Company` name or `Subscription` name. Also recorded with this data is `Hostname` and `Instance identifier` ID,
which can help to indicate if the data is from a production or development instance.

<!-- markdownlint-enable MD013 -->

### Ability to have some instances using Cloud Licensing, and others air-gapped or offline

If any of the customer's instances require a legacy or offline license file, the customer will need to request a [Cloud Licensing opt out](https://docs.google.com/presentation/d/1gbdHGCLTc0yis0VFyBBZkriMomNo8audr0u8XXTY2iI/edit#slide=id.g137e73c15b5_0_298) during quoting for VP approval.
This will provide the customer with the relevant license file, but also with an activation code that the customer can apply to the Cloud Licensing-eligible instances. Note that in this scenario, GitLab will receive seat count data only for the Cloud Licensing instance, and this is what will be used for calculating overages.

### Scenarios when one or more of the instances are a dev environment

Customers are welcome to apply their production license key or activation code to a development environment. The same user restrictions will apply.

### Using a single subscription for a GitLab.com, Dedicated, and self-managed instance

If the customer wants to have GitLab.com, Dedicated, and self-managed instances, the customer will need to purchase separate subscriptions for each instance.

### Example Scenarios

The following scenarios reflect questions a customer may ask related to multiple instances.

#### Example 1

- Q: I want to buy a license for 50 total users, but want to split these users into two instances. Can I do this?
- A: Yes, provided it is for two self-managed instances, you can apply one Cloud Licensing activation code (or license key) to multiple self-managed instances,
  provided that the users on the instances are the same, or are a subset of the total users. In this case, since there are 50 total or unique users, you may split
  those users into two subset instances.

#### Example 2

- Q: I have 2 different groups, 20 users and 30 users, who will each need their own instance. Can I buy a subscription for 30 users?
- A: No. In this scenario, the customer should purchase two unique subscriptions, for 20 seats and 30 seats so overages in each instance can be managed separately.
  A second option would be for the customer to buy a single subscription for 50 users and apply it to both instances.

#### Example 3

- Q: I have 30 users that require a Free GitLab.com instance. Can I activate a Free GitLab.com instance for all 30 users?
- A. No. The Free tier of GitLab.com is limited to five maximum users in the aggregate for each customer. Please contact your account representative to start a trial or evaluation period.

#### Example 4

- Q: I purchased 100 licenses in India but only need to deploy 75. Can I deploy the remaining 25 licenses to my team in the US?
- A: No. California is outside of the Geographical Region of India, so you are unable to deploy the remaining 25 licenses in this manner.

#### Example 5

- Q: I have an Ultimate instance with five users and a Premium instance with 100 users. Can I leverage Ultimate features on the code developed in my Premium instance?
- A: No. This is a prohibited commingling of features.
