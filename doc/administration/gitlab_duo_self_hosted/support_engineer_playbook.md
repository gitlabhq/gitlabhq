---
stage: AI-powered
group: Custom Models
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: Troubleshooting tips for GitLab Duo Self-Hosted
title: GitLab Duo Self-Hosted Support Engineer Playbook
---

{{< details >}}

- Tier: Premium, Ultimate
- Add-on: GitLab Duo Enterprise
- Offering: GitLab Self-Managed

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/12972) in GitLab 17.1 [with a flag](../feature_flags/_index.md) named `ai_custom_model`. Disabled by default.
- [Enabled on GitLab Self-Managed](https://gitlab.com/groups/gitlab-org/-/epics/15176) in GitLab 17.6.
- Changed to require GitLab Duo add-on in GitLab 17.6 and later.
- Feature flag `ai_custom_model` removed in GitLab 17.8.
- Generally available in GitLab 17.9.
- Changed to include Premium in GitLab 18.0.

{{< /history >}}

## Support Engineer Playbook and Common Issues

This section provides Support Engineers with essential commands and troubleshooting steps for debugging GitLab Duo Self-Hosted issues.

## Essential Debugging Commands

### Display AI Gateway Environment Variables

Check all AI Gateway environment variables to verify configuration:

```shell
docker exec -it <ai-gateway-container> env | grep AIGW
```

Key variables to verify:

- `AIGW_CUSTOM_MODELS__ENABLED` - must be `true`
- `AIGW_GITLAB_URL` - should match your GitLab instance URL
- `AIGW_GITLAB_API_URL` - should be accessible from the container
- `AIGW_AUTH__BYPASS_EXTERNAL` - should only be `true` during troubleshooting

### Verify User Permissions

Check if a user has the correct permissions for Code Suggestions with self-hosted models:

```ruby
# In GitLab Rails console
user = User.find_by_id("<user_id>")
user.allowed_to_use?(:code_suggestions, service_name: :self_hosted_models)
```

### Examine AI Gateway Client Logs

View AI Gateway client logs to identify connection issues:

```shell
docker logs <ai-gateway-container> | grep "Gitlab::Llm::AiGateway::Client"
```

### View GitLab Logs for AI Gateway Requests

To see the actual requests made to the AI Gateway, use:

```shell
# View live logs
sudo gitlab-ctl tail | grep -E "(ai_gateway|llm\.log)"

# View specific log file with JSON formatting
sudo cat /var/log/gitlab/gitlab-rails/llm.log | jq '.'

# Filter for specific request types
 sudo cat /var/log/gitlab/gitlab-rails/llm.log | jq 'select(.message)'

 sudo cat /var/log/gitlab/gitlab-rails/llm.log | grep Llm::CompletionWorker | jq '.'
```

### View AI Gateway Logs for Model Requests

To see the actual requests sent to the model:

```shell
# View AI Gateway container logs
docker logs <ai-gateway-container> 2>&1 | grep -E "(model|litellm|custom_openai)"

# For structured logs, if available
docker logs <ai-gateway-container> 2>&1 | grep "model_endpoint"
```

## Common Configuration Issues and Solutions

### Missing `/v1` Suffix in Model Endpoint

**Symptom**: 404 errors when making requests to vLLM or OpenAI-compatible models

**How to spot in logs**:

```shell
# Look for 404 errors in AI Gateway logs
docker logs <ai-gateway-container> | grep "404"
```

**Solution**: Ensure the model endpoint includes the `/v1` suffix:

- Incorrect: `http://localhost:4000`
- Correct: `http://localhost:4000/v1`

### Certificate Validation Issues

**Symptom**: SSL certificate errors or connection failures

**How to spot in logs**:

```shell
# Look for SSL/TLS errors
sudo cat /var/log/gitlab/gitlab-rails/llm.log | grep -i "ssl\|certificate\|tls"
```

**Validation**: Verify certificate status - GitLab server must use a trusted certificate, as self-signed certificates are not supported.

**Solution**:

- Use trusted certificates for GitLab instance
- If using self-signed certificates, configure proper certificate paths in the AI Gateway container

### Network Connectivity Issues

**Symptom**: Timeouts or connection refused errors

**How to spot in logs**:

```shell
# Look for network-related errors
docker logs <ai-gateway-container> | grep -E "(timeout|connection|refused|unreachable)"
```

**Validation commands**:

```shell
# Test from AI Gateway container to GitLab
docker exec -it <ai-gateway-container> curl "$AIGW_GITLAB_API_URL/projects"

# Test from AI Gateway container to model endpoint
docker exec -it <ai-gateway-container> curl "<model_endpoint>/health"
```

### Authentication and Authorization Issues

**Symptom**: 401 Unauthorized or 403 Forbidden errors

**How to spot in logs**:

```shell
# Look for authentication errors
sudo cat /var/log/gitlab/gitlab-rails/llm.log | jq 'select(.status == 401 or .status == 403)'
```

**Common causes**:

- User doesn't have GitLab Duo Enterprise seat assigned
- License issues
- Incorrect AI Gateway URL configuration

### Model Configuration Issues

**Symptom**: Model not responding or returning errors

**How to spot in logs**:

```shell
# Look for model-specific errors
docker logs <ai-gateway-container> | grep -E "(model_name|model_endpoint|litellm)"
```

**Validation**:

```shell
# Test model directly from AI Gateway container
docker exec -it <ai-gateway-container> sh
curl --request POST "<model_endpoint>/v1/chat/completions" \
     --header 'Content-Type: application/json' \
     --data '{"model": "<model_name>", "messages": [{"role": "user", "content": "Hello"}]}'
```

## Log Analysis Workflow

### Step 1: Enable Verbose Logging

Check if the `expanded_ai_logging` feature flag is enabled, in GitLab Rails console:

```ruby
Feature.enabled?(:expanded_ai_logging)
```

If it returns `false`, enable the flag using:

```ruby
Feature.enable(:expanded_ai_logging)
```

### Step 2: Reproduce the Issue

Have the user reproduce the issue while monitoring logs:

```shell
# Terminal 1: Monitor GitLab logs
sudo gitlab-ctl tail | grep -E "(ai_gateway|llm\.log)"

# Terminal 2: Monitor AI Gateway logs
docker logs -f <ai-gateway-container>
```

### Step 3: Analyze Request Flow

1. **GitLab to AI Gateway**: Check if request reaches AI Gateway
1. **AI Gateway to Model**: Verify model endpoint is called
1. **Response Path**: Ensure response is properly formatted and returned

### Step 4: Common Error Patterns

| Error Pattern | Location | Likely Cause |
|---------------|----------|--------------|
| `Connection refused` | GitLab logs | AI Gateway not accessible |
| `404 Not Found` | AI Gateway logs | Missing `/v1` in model endpoint |
| `401 Unauthorized` | GitLab logs | Authentication/license issues |
| `Timeout` | Either | Network or model performance issues |
| `SSL certificate verify failed` | GitLab logs | Certificate validation issues |

## Quick Diagnostic Commands

## **AI Gateway Instance Commands:**

**1. Test AI Gateway health:**

```shell
curl --silent --output /dev/null --write-out "%{http_code}" "<ai-gateway-url>/monitoring/healthz"
```

**2. Check AI Gateway environment variables:**

```shell
docker exec <ai-gateway-container> env | grep AIGW
```

**3. Check AI Gateway logs for errors:**

```shell
docker logs <ai-gateway-container> 2>&1 | grep --ignore-case error | tail --lines=20
```

## **GitLab Self-Managed Instance Commands:**

**4. Check user permissions (GitLab Rails console):**

```shell
sudo gitlab-rails console
```

Then in the console:

```ruby
User.find_by_id('<user_id>').can?(:access_code_suggestions)
```

**5. Check GitLab LLM logs for errors:**

```shell
sudo tail --lines=100 /var/log/gitlab/gitlab-rails/llm.log | grep --ignore-case error
```

**6. Check feature flags:**

```shell
sudo gitlab-rails console
```

Then:

```ruby
Feature.enabled?(:expanded_ai_logging)
```

**7. Test connectivity from GitLab to AI Gateway:**

```shell
curl --verbose "<ai-gateway-url>/monitoring/healthz"
```

### Emergency Diagnostic One-liner

For quick issue identification:

```shell
# Check all critical components at once
docker exec <ai-gateway-container> env | grep AIGW_CUSTOM_MODELS__ENABLED && \
curl --silent "<ai-gateway-url>/monitoring/healthz" && \
sudo tail --lines=10 /var/log/gitlab/gitlab-rails/llm.log | jq '.level'
```

## Escalation Criteria

Escalate to Custom Models team when:

1. **All basic troubleshooting steps completed** without resolution
1. **Model integration issues** that require deep technical knowledge
1. **Feature not listed** in self-hosted models unit primitives
1. **Suspected GitLab Duo platform bugs** affecting multiple users
1. **Performance issues** with specific model configurations

## Additional Resources

- [AI Gateway Installation Guide](../../install/install_ai_gateway.md)
- [GitLab Duo Self-Hosted Troubleshooting](troubleshooting.md)
