---
stage: AI-powered
group: Custom Models
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: Enable logging for self-hosted models.
title: Enable logging for self-hosted models
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
- Ability to turn logging on and off through the UI added in GitLab 17.9.
- Changed to include Premium in GitLab 18.0.

{{< /history >}}

Monitor your self-hosted model performance and debug issues more effectively with detailed
logging for GitLab Duo Self-Hosted.

## Enable logging

Prerequisites:

- You must be an administrator.
- You must have a Premium or Ultimate subscription.
- You must have a GitLab Duo Enterprise add-on.

To enable logging:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **GitLab Duo**.
1. In the GitLab Duo section, select **Change configuration**.
1. Under **Enable AI logs**, select **Capture detailed information about AI-related activities and requests**.
1. Select **Save changes**.

You can now access the logs in your GitLab installation.

## Logs in your GitLab installation

The logging setup is designed to protect sensitive information while maintaining transparency about system operations, and is made up of the following components:

- Logs that capture requests to the GitLab instance.
- Logging control.
- The `llm.log` file.

### Logs that capture requests to the GitLab instance

Logging in the `application.json`, `production_json.log`, and `production.log` files, among others, capture requests to the GitLab instance:

- **Filtered Requests**: We log the requests in these files but ensure that sensitive data (such as input parameters) is **filtered**. This means that while the request metadata is captured (for example, the request type, endpoint, and response status), the actual input data (for example, the query parameters, variables, and content) is not logged to prevent the exposure of sensitive information.
- **Example 1**: In the case of a code suggestions completion request, the logs capture the request details while filtering sensitive information:

  ```json
  {
    "method": "POST",
    "path": "/api/graphql",
    "controller": "GraphqlController",
    "action": "execute",
    "status": 500,
    "params": [
      {"key": "query", "value": "[FILTERED]"},
      {"key": "variables", "value": "[FILTERED]"},
      {"key": "operationName", "value": "chat"}
    ],
    "exception": {
      "class": "NoMethodError",
      "message": "undefined method `id` for {:skip=>true}:Hash"
    },
    "time": "2024-08-28T14:13:50.328Z"
  }
  ```

  As shown, while the error information and general structure of the request are logged, the sensitive input parameters are marked as `[FILTERED]`.

- **Example 2**: In the case of a code suggestions completion request, the logs also capture the request details while filtering sensitive information:

  ```json
  {
    "method": "POST",
    "path": "/api/v4/code_suggestions/completions",
    "status": 200,
    "params": [
      {"key": "prompt_version", "value": 1},
      {"key": "current_file", "value": {"file_name": "/test.rb", "language_identifier": "ruby", "content_above_cursor": "[FILTERED]", "content_below_cursor": "[FILTERED]"}},
      {"key": "telemetry", "value": []}
    ],
    "time": "2024-10-15T06:51:09.004Z"
  }
  ```

  As shown, while the general structure of the request is logged, the sensitive input parameters such as `content_above_cursor` and `content_below_cursor` are marked as `[FILTERED]`.

### Logging Control

You control a subset of these logs by turning AI Logs on and off through the Duo settings page. Turning AI logs off disables logging for specific operations.

### The `llm.log` file

When AI Logs are enabled, the [`llm.log` file](../logs/_index.md#llmlog) in your GitLab Self-Managed instance, code generation and Chat events that occur through your instance are captured. The log file does not capture anything when it is not enabled. Code completion logs are captured directly in the AI gateway. These logs are not transmitted to GitLab, and are only visible on your GitLab Self-Managed infrastructure.

- [Rotate, manage, export, and visualize the logs in `llm.log`](../logs/_index.md).
- [View the log file location (for example, so you can delete logs)](../logs/_index.md#llm-input-and-output-logging).

### Logs in your AI gateway container

To specify the location of logs generated by AI gateway, run:

```shell
docker run -e AIGW_GITLAB_URL=<your_gitlab_instance> \
 -e AIGW_GITLAB_API_URL=https://<your_gitlab_domain>/api/v4/ \
 -e AIGW_LOGGING__TO_FILE="aigateway.log" \
 -v <your_file_path>:"aigateway.log"
 <image>
```

If you do not specify a filename, logs are streamed to the output and can also be managed using Docker logs.
For more information, see the [Docker Logs documentation](https://docs.docker.com/reference/cli/docker/container/logs/).

Additionally, the outputs of the AI gateway execution can help with debugging issues. To access them:

- When using Docker:

  ```shell
  docker logs <container-id>
  ```

- When using Kubernetes:

  ```shell
  kubectl logs <container-name>
  ```

To ingest these logs into the logging solution, see your logging provider documentation.

### Logs structure

When a POST request is made (for example, to the `/chat/completions` endpoint), the server logs the request:

- Payload
- Headers
- Metadata

#### 1. Request payload

The JSON payload typically includes the following fields:

- `messages`: An array of message objects.
  - Each message object contains:
    - `content`: A string representing the user's input or query.
    - `role`: Indicates the role of the message sender (for example, `user`).
- `model`: A string specifying the model to be used (for example, `mistral`).
- `max_tokens`: An integer specifying the maximum number of tokens to generate in the response.
- `n`: An integer indicating the number of completions to generate.
- `stop`: An array of strings denoting stop sequences for the generated text.
- `stream`: A boolean indicating whether the response should be streamed.
- `temperature`: A float controlling the randomness of the output.

##### Example request

```json
{
    "messages": [
        {
            "content": "<s>[SUFFIX]None[PREFIX]# # build a hello world ruby method\n def say_goodbye\n    puts \"Goodbye, World!\"\n  end\n\ndef main\n  say_hello\n  say_goodbye\nend\n\nmain",
            "role": "user"
        }
    ],
    "model": "mistral",
    "max_tokens": 128,
    "n": 1,
    "stop": ["[INST]", "[/INST]", "[PREFIX]", "[MIDDLE]", "[SUFFIX]"],
    "stream": false,
    "temperature": 0.0
}
```

#### 2. Request headers

The request headers provide additional context about the client making the request. Key headers might include:

- `Authorization`: Contains the Bearer token for API access.
- `Content-Type`: Indicates the media type of the resource (for example, `JSON`).
- `User-Agent`: Information about the client software making the request.
- `X-Stainless-` headers: Various headers providing additional metadata about the client environment.

##### Example request headers

```json
{
    "host": "0.0.0.0:4000",
    "accept-encoding": "gzip, deflate",
    "connection": "keep-alive",
    "accept": "application/json",
    "content-type": "application/json",
    "user-agent": "AsyncOpenAI/Python 1.51.0",
    "authorization": "Bearer <TOKEN>",
    "content-length": "364"
}
```

#### 3. Request metadata

The metadata includes various fields that describe the context of the request:

- `requester_metadata`: Additional metadata about the requester.
- `user_api_key`: The API key used for the request (anonymized).
- `api_version`: The version of the API being used.
- `request_timeout`: The timeout duration for the request.
- `call_id`: A unique identifier for the call.

##### Example metadata

```json
{
    "user_api_key": "<ANONYMIZED_KEY>",
    "api_version": "1.48.18",
    "request_timeout": 600,
    "call_id": "e1aaa316-221c-498c-96ce-5bc1e7cb63af"
}
```

### Example response

The server responds with a structured model response. For example:

```python
Response: ModelResponse(
    id='chatcmpl-5d16ad41-c130-4e33-a71e-1c392741bcb9',
    choices=[
        Choices(
            finish_reason='stop',
            index=0,
            message=Message(
                content=' Here is the corrected Ruby code for your function:\n\n```ruby\ndef say_hello\n  puts "Hello, World!"\nend\n\ndef say_goodbye\n    puts "Goodbye, World!"\nend\n\ndef main\n  say_hello\n  say_goodbye\nend\n\nmain\n```\n\nIn your original code, the method names were misspelled as `say_hell` and `say_gobdye`. I corrected them to `say_hello` and `say_goodbye`. Also, there was no need for the prefix',
                role='assistant',
                tool_calls=None,
                function_call=None
            )
        )
    ],
    created=1728983827,
    model='mistral',
    object='chat.completion',
    system_fingerprint=None,
    usage=Usage(
        completion_tokens=128,
        prompt_tokens=69,
        total_tokens=197,
        completion_tokens_details=None,
        prompt_tokens_details=None
    )
)
```

### Logs in your inference service provider

GitLab does not manage logs generated by your inference service provider. See the documentation of your inference service
provider on how to use their logs.

## Logging behavior in GitLab and AI gateway environments

GitLab provides logging functionality for AI-related activities through the use of `llm.log`, which captures inputs, outputs, and other relevant information. However, the logging behavior differs depending on whether the GitLab instance and AI gateway are **self-hosted** or **cloud-connected**.

By default, the log does not contain LLM prompt input and response output to support [data retention policies](../../user/gitlab_duo/data_usage.md#data-retention) of AI feature data.

## Logging Scenarios

### GitLab Self-Managed and self-hosted AI gateway

In this configuration, both GitLab and the AI gateway are hosted by the customer.

- **Logging Behavior**: Full logging is enabled, and all prompts, inputs, and outputs are logged to `llm.log` on the instance.
- When AI logs are enabled, extra debugging information is logged, including:
  - Preprocessed prompts.
  - Final prompts.
  - Additional context.
- **Privacy**: Because both GitLab and the AI gateway are self-hosted:
  - The customer has full control over data handling.
  - Logging of sensitive information can be enabled or disabled at the customer's discretion.

### GitLab Self-Managed and GitLab-managed AI gateway (cloud-connected)

In this scenario, the customer hosts GitLab but relies on the GitLab-managed AI gateway for AI processing.

- **Logging Behavior**: Prompts and inputs sent to the AI gateway are **not logged** in the cloud-connected AI gateway to prevent exposure of sensitive information such as personally identifiable information (PII).
- **Expanded Logging**: Even if [AI logs are enabled](#enable-logging), no detailed logs are generated in the GitLab-managed AI gateway to avoid unintended leaks of sensitive information.
  - Logging remains **minimal** in this setup, and the expanded logging features are disabled by default.
- **Privacy**: This configuration is designed to ensure that sensitive data is not logged in a cloud environment.

## AI logs

The AI logs control whether additional debugging information, including prompts and inputs, is logged. This configuration is essential for monitoring and debugging AI-related activities.

### Behavior by Deployment Setup

- **GitLab Self-Managed and self-hosted AI gateway**: The feature flag enables detailed logging to `llm.log` on the self-hosted instance, capturing inputs and outputs for AI models.
- **GitLab Self-Managed and GitLab-managed AI gateway**: The feature flag enables logging on your GitLab Self-Managed instance. However, the flag does **not** activate expanded logging for the GitLab-managed AI gateway side. Logging remains disabled for the cloud-connected AI gateway to protect sensitive data.

### Logging in cloud-connected AI gateways

To prevent potential data leakage of sensitive information, expanded logging (including prompts and inputs) is intentionally disabled when using a cloud-connected AI gateway. Preventing the exposure of PII is a priority.

### Cross-referencing logs between the AI gateway and GitLab

The property `correlation_id` is assigned to every request and is carried across different components that respond to a
request. For more information, see the [documentation on finding logs with a correlation ID](../logs/tracing_correlation_id.md).

The Correlation ID can be found in your AI gateway and GitLab logs. However, it is not present in your model provider logs.

#### Related topics

- [Parsing GitLab logs with jq](../logs/log_parsing.md)
- [Searching your logs for the correlation ID](../logs/tracing_correlation_id.md#searching-your-logs-for-the-correlation-id)
