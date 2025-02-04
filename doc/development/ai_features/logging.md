---
stage: AI-powered
group: AI Framework
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: LLM logging
---

In addition to standard logging in the GitLab Rails Monolith instance, specialized logging is available for features based on large language models (LLMs).

## Logged events

Currently logged events are documented [here](logged_events.md).

## Implementation

### Logger Class

To implement LLM-specific logging, use the `Gitlab::Llm::Logger` class.

### Privacy Considerations

**Important**: User inputs and complete prompts containing user data must not be logged unless explicitly permitted.

## Feature Flag

A feature flag named `expanded_ai_logging` controls the logging of sensitive data.
Use the `conditional_info` helper method for conditional logging based on the feature flag status:

- If the feature flag is enabled for the current user, it logs the information on `info` level (logs are accessible in Kibana).
- If the feature flag is disabled for the current user, it logs the information on `info` level, but without optional parameters (logs are accessible in Kibana, but only obligatory fields).

## Best Practices

When implementing logging for LLM features, consider the following:

- Identify critical information for debugging purposes.
- Ensure compliance with privacy requirements by not logging sensitive user data without proper authorization.
- Use the `conditional_info` helper method to respect the `expanded_ai_logging` feature flag.
- Structure your logs to provide meaningful insights for troubleshooting and analysis.

## Example Usage

```ruby
# including concern that handles logging
include Gitlab::Llm::Concerns::Logger

# Logging potentially sensitive information
log_conditional_info(user, message:"User prompt processed", event_name: 'ai_event', ai_component: 'abstraction_layer', prompt: sanitized_prompt)

# Logging application error information
log_error(user, message: "System application error", event_name: 'ai_event', ai_component: 'abstraction_layer', error_message: sanitized_error_message)
```

**Important**: Please familiarize yourself with our [Data Retention Policy](../../user/gitlab_duo/data_usage.md#data-retention) and remember
to make sure we are not logging user input and LLM-generated output.
