---
stage: Growth
group: Conversion
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Product Qualified Lead (PQL) development guide

The Product Qualified Lead (PQL) funnel connects our users with our team members. Read more about [PQL product principles](https://about.gitlab.com/handbook/product/product-principles/#product-qualified-leads-pqls).

A hand-raise PQL is a user who requests to speak to sales from within the product.

## Embed a hand-raise lead form

[HandRaiseLeadButton](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/app/assets/javascripts/hand_raise_leads/hand_raise_lead/components/hand_raise_lead_button.vue) is a reusable component that adds a button and a hand-raise modal to any screen.

You can import a hand-raise lead button the following way.

```javascript
import HandRaiseLeadButton from 'ee/hand_raise_leads/hand_raise_lead/components/hand_raise_lead_button.vue';

export default {
  components: {
    HandRaiseLeadButton,
...
</script>

<template>

<hand-raise-lead-button />

```

The hand-raise lead form accepts the following parameters via provide or inject.

```javascript
    provide: {
      small,
      user: {
        namespaceId,
        userName,
        firstName,
        lastName,
        companyName,
        glmContent,
      },
      ctaTracking: {
        action,
        label,
        property,
        value,
        experiment,
      },
    },
```

The `ctaTracking` parameters follow [the `data-track` attributes](../snowplow/implementation.md#data-track-attributes) for implementing Snowplow tracking. The provided tracking attributes are attached to the button inside the `HandRaiseLeadButton` component, which triggers the hand-raise lead modal when selected.

### Monitor the lead location

When embedding a new hand raise form, use a unique `glmContent` or `glm_content` field that is different to any existing values.

We currently use the following `glm content` values:

| glm_content value | Notes |
| ------ | ------ |
| discover-group-security | This value is used in the group security feature discovery page. |
| discover-group-security-pqltest | This value is used in the group security feature discovery page [experiment with 3 CTAs](https://gitlab.com/gitlab-org/gitlab/-/issues/349799). |
| discover-project-security | This value is used in the project security feature discovery page. |
| discover-project-security-pqltest | This value is used in the project security feature discovery page [experiment with 3 CTAs](https://gitlab.com/gitlab-org/gitlab/-/issues/349799). |
| group-billing | This value is used in the group billing page. |
| trial-status-show-group | This value is used in the top left nav when a namespace has an active trial. |

### Test the component

In a jest test, you may test the presence of the component.

```javascript
expect(wrapper.findComponent(HandRaiseLeadButton).exists()).toBe(true);
```

## PQL lead flow

The flow of a PQL lead is as follows:

1. A user triggers a [`HandRaiseLeadButton` component](#embed-a-hand-raise-lead-form) on `gitlab.com`.
1. The `HandRaiseLeadButton` submits any information to the following API endpoint: `/-/trials/create_hand_raise_lead`.
1. That endpoint reposts the form to the CustomersDot `trials/create_hand_raise_lead` endpoint.
1. CustomersDot records the form data to the `leads` table and posts the form to [Platypus](https://gitlab.com/gitlab-com/business-technology/enterprise-apps/integrations/platypus).
1. Platypus posts the form to Workato (which is under the responsibility of the Business Operations team).
1. Workato sends the form to Marketo.
1. Marketo does scoring and sends the form to Salesforce.
1. Our Sales team uses Salesforce to connect to the leads.

## Monitor and manually test leads

- Check the application and Sidekiq logs on `gitlab.com` and CustomersDot to monitor leads.
- Check the `leads` table in CustomersDot.
- Set up staging credentials for Platypus, and track the leads on the [Platypus Dashboard](https://staging.ci.nexus.gitlabenvironment.cloud/admin/queues/queue/new-lead-queue).
- Ask for access to the Marketo Sandbox and validate the leads there.

## Trials

Trials follow the same flow as the PQL leads.
