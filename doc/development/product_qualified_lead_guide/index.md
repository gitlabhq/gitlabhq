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
      user: {
        namespaceId,
        userName,
        firstName,
        lastName,
        companyName,
        glmContent,
      },
    },
```

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
