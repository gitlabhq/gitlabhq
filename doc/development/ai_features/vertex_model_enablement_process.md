---
stage: AI-powered
group: AI Framework
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/development/development_processes/#development-guidelines-review.
title: Vertex AI Model Enablement Process
---

## Production Environment Setup

### 1. Request Initiation

- Create an issue in the [GitLab project](https://gitlab.com/gitlab-org/gitlab/-/issues)
  - Use the Model Enablement Request template - see below
  - Specify the model(s) to be enabled (e.g., Codestral)
- Share the issue link in the `#ai-infrastructure` channel for visibility

### 2. Request Processing

- Request is handled by either:
  - Infrastructure team (Infra)
  - AI Framework team (AIF)

### 3. Model Enablement

- For Vertex AI managed models:
  - Team enables the model via the Vertex AI console ("click on enable")
- For custom configurations:
  - AIF team opens a ticket with Google for customization needs

### 4. Quota Management

- Monitoring for existing quota is available from the [AI-gateway dashboard](https://dashboards.gitlab.net/d/ai-gateway-main/ai-gateway3a-overview?from=now-6h%2Fm&orgId=1&timezone=utc&to=now%2Fm&var-PROMETHEUS_DS=mimir-runway&var-environment=gprd&viewPanel=panel-1217942947). Use the little arrow on the upper left to drill down and see quota usage per model.
- Not all quota are available in our monitoring, all visible quota are available in the [GCP console for the `gitlab-ai-framework-prod` project](https://console.cloud.google.com/iam-admin/quotas?referrer=search&inv=1&invt=Abs5YQ&project=gitlab-ai-framework-prod)
- Quota capacity forecasting is available in [tamland](https://gitlab-com.gitlab.io/gl-infra/capacity-planning-trackers/gitlab-com/service_groups/ai-gateway/)
- Quota increases to shared resources need to be requested from Google
- Provisioned throughput could be purchased from Google if justifiable.
- Even when quota is available, requests may be throttled during high demand periods due to Anthropic's resource provisioning model. Unlike direct Google services which over-provision resources, Anthropic provisions based on actual demand. To ensure consistent throughput without throttling, dedicated provisioned throughput can be purchased through Anthropic.

## Load Testing Environment Setup

### 1. Environment Selection

- Options include:
  - ai-framework-dev
  - ai-framework-stage
  - Dedicated load test environment (e.g., sandbox project)

### 2. Access Request

- Create an access request using the [template](https://gitlab.com/gitlab-com/team-member-epics/access-requests/-/issues/new?description_template=Individual_Bulk_Access_Request)
- Request roles/writer role for the project

### 3. Environment Configuration

- Replicate the exact same model configuration from production
- Ensure isolation from production to prevent:
  - Load test interrupting production traffic
  - External traffic skewing load test results

### 4. Model Verification

- Verify model specs match production environment
- Validate quotas and capacity before running tests

## Best Practices

- Test new models or model versions before deploying to production
- Use isolated environments for load testing to prevent impacting users
- Monitor for GPU capacity issues and rate limits during testing
- Document configuration changes for future reference

## Model Enablement Request Template

```markdown
### Model Details

- **Model Name**: [e.g., Codestral, Claude 3 Opus, etc.]
- **Provider**: [e.g., Google Vertex AI, Anthropic, etc.]
- **Model Version/Edition**: [e.g., v1, Sonnet, Haiku, etc.]

### Business Justification

- **Purpose**: [Brief description of how this model will be used]
- **Features/Capabilities Required**: [Specific capabilities needed from this model]
- **Expected Impact**: [How this model will improve GitLab features/services]

### Technical Requirements

- **Environment(s)**: [Production, Staging, Dev, etc.]
- **Expected Traffic/Usage**: [Estimated QPS, daily usage, etc.]
- **Required Quotas**: [TPU/GPU hours, tokens per minute, etc. if known]
- **Integration Point**: [Which GitLab service(s) will use this model]

### Timeline

- **Requested By Date**: [When you need this model to be available]
- **Testing Period**: [Planned testing dates before full deployment]

### Additional Information

- **Special Configuration Needs**: [Any custom settings needed]
- **Similar Models Already Enabled**: [For reference/comparison]
- **Links to Relevant Documentation**: [Model documentation, internal specs, etc.]

/label ~"group::ai framework"
```
