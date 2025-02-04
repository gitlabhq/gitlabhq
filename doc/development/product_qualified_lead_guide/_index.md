---
stage: Growth
group: Acquisition
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: Product Qualified Lead (PQL) development guidelines
---

The Product Qualified Lead (PQL) funnel connects our users with our team members. Read more about [PQL product principles](https://handbook.gitlab.com/handbook/product/product-principles/#product-qualified-leads-pqls).

A hand-raise PQL is a user who requests to speak to sales from within the product.

## Set up your development environment

1. Set up GDK with a connection to your local CustomersDot instance.
1. Set up CustomersDot to talk to a staging instance of Workato.

1. Set up CustomersDot using the [standard install instructions](https://gitlab.com/gitlab-org/customers-gitlab-com/-/blob/staging/doc/setup/installation_steps.md).
1. Set the `CUSTOMER_PORTAL_URL` environment variable to your local URL of your CustomersDot instance.
1. Place `export CUSTOMER_PORTAL_URL=http://localhost:5000/` in your shell `rc` script (`~/.zshrc` or `~/.bash_profile` or `~/.bashrc`) and restart GDK.
1. Enter the credentials on CustomersDot development to Workato in your `/config/secrets.yml` and restart. Credentials for the Workato Staging are in the 1Password Subscription portal vault. The URL for staging is `https://apim.workato.com/gitlab-dev/services/marketo/lead`.

```yaml
  workato_url: "<%= ENV['WORKATO_URL'] %>"
  workato_client_id: "<%= ENV['WORKATO_CLIENT_ID'] %>"
  workato_client_secret: "<%= ENV['WORKATO_CLIENT_SECRET'] %>"
```

### Set up lead monitoring

1. Set up access for the Marketo sandbox, similar [to this example request](https://gitlab.com/gitlab-com/team-member-epics/access-requests/-/issues/13162).

### Manually test leads

1. Register a new user with a unique email on your local GitLab instance.
1. Send the PQL lead by submitting your new form or creating a new trial or a new hand raise lead.
1. Use easily identifiable values that can be easily seen in Workato staging.
1. Observe the entry in the staging instance of Workato and paste in the merge request comment and mention.

## Troubleshooting

- Check the application and Sidekiq logs on `gitlab.com` and CustomersDot to monitor leads.
- Check the `leads` table in CustomersDot.
- Ask for access to the Marketo Sandbox and validate the leads there, [to this example request](https://gitlab.com/gitlab-com/team-member-epics/access-requests/-/issues/13162).

## Embed a hand-raise lead form

[HandRaiseLeadButton](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/app/assets/javascripts/hand_raise_leads/hand_raise_lead/components/hand_raise_lead_button.vue) is a reusable component that adds a button and a hand-raise modal to any screen.

You can import a hand-raise lead button in the following ways:

For Haml:

```haml
.js-hand-raise-lead-trigger{ data: discover_page_hand_raise_lead_data(group) }
```

For Vue:

```vue
<script>
import HandRaiseLeadButton from 'ee/hand_raise_leads/hand_raise_lead/components/hand_raise_lead_button.vue';

export default {
  handRaiseLeadAttributes: {
    variant: 'confirm',
    category: 'tertiary',
    class: 'gl-sm-w-auto gl-w-full gl-sm-ml-3 gl-sm-mt-0 gl-mt-3',
    'data-testid': 'some-unique-hand-raise-lead-button',
  },
  ctaTracking: {
    action: 'click_button',
  },
  components: {
    HandRaiseLeadButton,
...
</script>

<template>

<hand-raise-lead-button
  :button-attributes="$options.handRaiseLeadAttributes"
  glm-content="some-unique-glm-content"
  :cta-tracking="$options.ctaTracking"
/>
...
</template>
```

The hand-raise lead form submission can send unique data on modal submission and customize the button by
providing the following props to the button:

```javascript
props: {
  ctaTracking: {
    type: Object,
    required: false,
    default: () => ({}),
  },
  buttonText: {
    type: String,
    required: false,
    default: PQL_BUTTON_TEXT,
  },
  buttonAttributes: {
    type: Object,
    required: true,
  },
  glmContent: {
    type: String,
    required: true,
  },
  productInteraction: {
    type: String,
    required: false,
    default: PQL_PRODUCT_INTERACTION,
  },
},
```

The `ctaTracking` parameters follow the `data-track` attributes for implementing Snowplow tracking.
The provided tracking attributes are attached to the button inside the `HandRaiseLeadButton` component,
which triggers the hand-raise lead modal when selected.

### Monitor the lead location

When embedding a new hand raise form, use a unique `glmContent` or `glm_content` field that is different to any existing values.

## PQL lead flow

The flow of a PQL lead is as follows:

1. A user triggers a [`HandRaiseLeadButton` component](#embed-a-hand-raise-lead-form) on `gitlab.com`.
1. The `HandRaiseLeadButton` submits any information to the following API endpoint: `/-/gitlab_subscriptions/hand_raise_leads`.
1. That endpoint reposts the form to the CustomersDot `trials/create_hand_raise_lead` endpoint.
1. CustomersDot records the form data to the `leads` table and posts the form to [Workato](https://handbook.gitlab.com/handbook/marketing/marketing-operations/workato/).
1. Workato sends the form to Marketo.
1. Marketo does scoring and sends the form to Salesforce.
1. Our Sales team uses Salesforce to connect to the leads.

### Trial lead flow

#### Trial lead flow on GitLab.com

```mermaid
sequenceDiagram
    Trial Frontend Forms ->>TrialsController#create_lead: GitLab.com frontend sends [lead] to backend
    TrialsController#create->>CreateLeadService: [lead]
    TrialsController#create->>ApplyTrialService: [lead] Apply the trial
    CreateLeadService->>SubscriptionPortalClient#generate_trial(sync_to_gl=false): [lead] Creates customer account on CustomersDot
    ApplyTrialService->>SubscriptionPortalClient#generate_trial(sync_to_gl=true): [lead] Asks CustomersDot to apply the trial on namespace
    SubscriptionPortalClient#generate_trial(sync_to_gl=false)->>CustomersDot|TrialsController#create(sync_to_gl=false): GitLab.com sends [lead] to CustomersDot
    SubscriptionPortalClient#generate_trial(sync_to_gl=true)->>CustomersDot|TrialsController#create(sync_to_gl=true): GitLab.com asks CustomersDot to apply the trial


```

#### Trial lead flow on CustomersDot (`sync_to_gl`)

```mermaid
sequenceDiagram
    CustomersDot|TrialsController#create->>HostedPlans|CreateTrialService#execute: Save [lead] to leads table for monitoring purposes
    HostedPlans|CreateTrialService#execute->>BaseTrialService#create_account: Creates a customer record in customers table
    HostedPlans|CreateTrialService#create_lead->>CreateLeadService: Creates a lead record in customers table
    HostedPlans|CreateTrialService#create_lead->>Workato|CreateLeadWorker: Async worker to submit [lead] to Workato
    Workato|CreateLeadWorker->>Workato|CreateLeadService: [lead]
    Workato|CreateLeadService->>WorkatoApp#create_lead: [lead]
    WorkatoApp#create_lead->>Workato: [lead] is sent to Workato
```

#### Applying the trial to a namespace on CustomersDot

```mermaid
sequenceDiagram
    HostedPlans|CreateTrialService->load_namespace#Gitlab api/namespaces: Load namespace details
    HostedPlans|CreateTrialService->create_order#: Creates an order in orders table
    HostedPlans|CreateTrialService->create_trial_history#: Creates a record in trial_histories table
```

### Hand raise lead flow

#### Hand raise flow on GitLab.com

```mermaid
sequenceDiagram
    HandRaiseForm Vue Component->>HandRaiseLeadsController#create: GitLab.com frontend sends [lead] to backend
    HandRaiseLeadsController#create->>CreateHandRaiseLeadService: [lead]
    CreateHandRaiseLeadService->>SubscriptionPortalClient: [lead]
    SubscriptionPortalClient->>CustomersDot|TrialsController#create_hand_raise_lead: GitLab.com sends [lead] to CustomersDot
```

#### Hand raise flow on CustomersDot

```mermaid
sequenceDiagram
    CustomersDot|TrialsController#create_hand_raise_lead->>CreateLeadService: Save [lead] to leads table for monitoring purposes
    CustomersDot|TrialsController#create_hand_raise_lead->>Workato|CreateLeadWorker: Async worker to submit [lead] to Workato
    Workato|CreateLeadWorker->>Workato|CreateLeadService: [lead]
    Workato|CreateLeadService->>WorkatoApp#create_lead: [lead]
    WorkatoApp#create_lead->>Workato: [lead] is sent to Workato
```

### PQL flow after Workato for all lead types

```mermaid
sequenceDiagram
    Workato->>Marketo: [lead]
    Marketo->>Salesforce(SFDC): [lead]
```
