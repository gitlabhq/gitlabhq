---
stage: AI-Powered
group: Custom Models
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: Troubleshooting tips for deploying GitLab Duo Self-Hosted
title: Troubleshooting GitLab Duo Self-Hosted
---

{{< details >}}

- Tier: Ultimate with GitLab Duo Enterprise - [Start a GitLab Duo Enterprise trial on a paid Ultimate subscription](https://about.gitlab.com/solutions/gitlab-duo-pro/sales/?type=free-trial)
- Offering: GitLab Self-Managed

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/12972) in GitLab 17.1 [with a flag](../feature_flags.md) named `ai_custom_model`. Disabled by default.
- [Enabled on GitLab Self-Managed](https://gitlab.com/groups/gitlab-org/-/epics/15176) in GitLab 17.6.
- Changed to require GitLab Duo add-on in GitLab 17.6 and later.
- Feature flag `ai_custom_model` removed in GitLab 17.8
- Generally available in GitLab 17.9

{{< /history >}}

When working with GitLab Duo Self-Hosted, you might encounter issues.

Before you begin troubleshooting, you should:

- Be able to access the [`gitlab-rails` console](../operations/rails_console.md).
- Open a shell in the AI gateway Docker image.
- Know the endpoint where your:
  - AI gateway is hosted.
  - Model is hosted.
- Enable the feature flag `expanded_ai_logging` on the `gitlab-rails` console:

  ```ruby
  Feature.enable(:expanded_ai_logging)
  ```

  Now, requests and responses from GitLab to the AI gateway are logged to [`llm.log`](../logs/_index.md#llmlog)

For more information on troubleshooting GitLab Duo, see:

- [Troubleshooting GitLab Duo](../../user/gitlab_duo/troubleshooting.md).
- [Troubleshooting Code Suggestions](../../user/project/repository/code_suggestions/troubleshooting.md).
- [GitLab Duo Chat troubleshooting](../../user/gitlab_duo_chat/troubleshooting.md).

## Use debugging scripts

We provide two debugging scripts to help administrators verify their self-hosted model configuration.

1. Debug the GitLab to AI gateway connection. From your GitLab instance, run the
   [Rake task](../../raketasks/_index.md):

   ```shell
   gitlab-rake "gitlab:duo:verify_self_hosted_setup[<username>]"
   ```

   Optional: Include a `<username>` that has an assigned seat.
   If you do not include a username parameter, the Rake task uses the root user.

1. Debug the AI gateway setup. For your AI gateway container:

   - Restart the AI gateway container with authentication disabled by setting:

     ```shell
     -e AIGW_AUTH__BYPASS_EXTERNAL=true
     ```

     This setting is required for the troubleshooting command to run the **System Exchange test**. You must remove this setting after troubleshooting is complete.

   - From your AI gateway container, run:

     ```shell
     docker exec -it <ai-gateway-container> sh
     poetry run troubleshoot [options]
     ```

      The `troubleshoot` command supports the following options:

      | Option | Description | Default | Example |
      |--------|-------------|---------|---------|
      | `--endpoint` | AI Gateway endpoint | `localhost:5052` | `--endpoint=localhost:5052` |
      | `--model-family` | Model family to test. Possible values are `mistral`, `mixtral`, `gpt`, or `claude_3` | - | `--model-family=mistral` |
      | `--model-endpoint` | Model endpoint. For models hosted on vLLM, add the `/v1` suffix. | - | `--model-endpoint=http://localhost:4000/v1` |
      | `--model-identifier` | Model identifier. | - | `--model-identifier=custom_openai/Mixtral-8x7B-Instruct-v0.1` |
      | `--api-key` | Model API key. | - | `--api-key=your-api-key` |

     **Examples:**

     For a `claude_3` model running on AWS Bedrock:

     ```shell
     poetry run troubleshoot \
       --model-family=claude_3 \
       --model-identifier=bedrock/anthropic.claude-3-7-sonnet-20250219-v1:0
     ```

     For a `mixtral` model running on vLLM:

     ```shell
     poetry run troubleshoot \
       --model-family=mixtral \
       --model-identifier=custom_openai/Mixtral-8x7B-Instruct-v0.1 \
       --api-key=your-api-key \
       --model-endpoint=http://<your-model-endpoint>/v1
     ```

After troubleshooting is complete, stop and restart the AI gateway container **without** `AIGW_AUTH__BYPASS_EXTERNAL=true`.

{{< alert type="warning" >}}

You must not bypass authentication in production.

{{< /alert >}}

Verify the output of the commands, and fix accordingly.

If both commands are successful, but GitLab Duo Code Suggestions is still not working,
raise an issue on the issue tracker.

## GitLab Duo health check is not working

When you [run a health check for GitLab Duo](../../user/gitlab_duo/setup.md#run-a-health-check-for-gitlab-duo), you might get an error like a `401 response from the AI gateway`.

To resolve, first check if GitLab Duo features are functioning correctly. For example, send a message to Duo Chat.

If this does not work, the error might be because of a known issue with GitLab Duo health check. For more information, see [issue 517097](https://gitlab.com/gitlab-org/gitlab/-/issues/517097).

## Check if GitLab can make a request to the model

From the GitLab Rails console, verify that GitLab can make a request to the model
by running:

```ruby
model_name = "<your_model_name>"
model_endpoint = "<your_model_endpoint>"
model_api_key = "<your_model_api_key>"
body = {:prompt_components=>[{:type=>"prompt", :metadata=>{:source=>"GitLab EE", :version=>"17.3.0"}, :payload=>{:content=>[{:role=>:user, :content=>"Hello"}], :provider=>:litellm, :model=>model_name, :model_endpoint=>model_endpoint, :model_api_key=>model_api_key}}]}
ai_gateway_url = Ai::Setting.instance.ai_gateway_url # Verify that the AI gateway URL is set in the database
client = Gitlab::Llm::AiGateway::Client.new(User.find_by_id(1), service_name: :self_hosted_models)
client.complete(url: "#{ai_gateway_url}/v1/chat/agent", body: body)
```

This should return a response from the model in the format:

```ruby
{"response"=> "<Model response>",
 "metadata"=>
  {"provider"=>"litellm",
   "model"=>"<>",
   "timestamp"=>1723448920}}
```

If that is not the case, this might means one of the following:

- The user might not have access to Code Suggestions. To resolve,
  [check if a user can request Code Suggestions](#check-if-a-user-can-request-code-suggestions).
- The GitLab environment variables are not configured correctly. To resolve, [check that the GitLab environment variables are set up correctly](#check-that-the-ai-gateway-environment-variables-are-set-up-correctly).
- The GitLab instance is not configured to use self-hosted models. To resolve, [check if the GitLab instance is configured to use self-hosted models](#check-if-gitlab-instance-is-configured-to-use-self-hosted-models).
- The AI gateway is not reachable. To resolve, [check if GitLab can make an HTTP request to the AI gateway](#check-if-gitlab-can-make-an-http-request-to-the-ai-gateway).
- When the LLM server is installed on the same instance as the AI gateway container, local requests may not work. To resolve, [allow local requests from the Docker container](#llm-server-is-not-available-inside-the-ai-gateway-container).

## Check if a user can request Code Suggestions

In the GitLab Rails console, check if a user can request Code Suggestions by running:

```ruby
User.find_by_id("<user_id>").can?(:access_code_suggestions)
```

If this returns `false`, it means some configuration is missing, and the user
cannot access Code Suggestions.

This missing configuration might be because of either of the following:

- The license is not valid. To resolve, [check or update your license](../license_file.md#see-current-license-information).
- GitLab Duo was not configured to use a self-hosted model. To resolve, [check if the GitLab instance is configured to use self-hosted models](#check-if-gitlab-instance-is-configured-to-use-self-hosted-models).

## Check if GitLab instance is configured to use self-hosted models

To check if GitLab Duo was configured correctly:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Self-hosted models**
1. Expand **AI-powered features**.
1. Under **Features**, check that **Code Suggestions** and **Code generation** are set to **Self-hosted model**.

## Check that the AI gateway URL is set up correctly

To check that the AI gateway URL is correct, run the following on the GitLab Rails console:

```ruby
Ai::Setting.instance.ai_gateway_url == "<your-ai-gateway-instance-url>"
```

If the AI gateway is not set up, [configure your GitLab instance to access the AI gateway](configure_duo_features.md#configure-your-gitlab-instance-to-access-the-ai-gateway).

## Check if GitLab can make an HTTP request to the AI gateway

In the GitLab Rails console, verify that GitLab can make an HTTP request to AI
Gateway by running:

```ruby
HTTParty.get('<your-aigateway-endpoint>/monitoring/healthz', headers: { 'accept' => 'application/json' }).code
```

If the response is not `200`, this means either of the following:

- The network is not properly configured to allow GitLab to reach the AI gateway container. Contact your network administrator to verify the setup.
- The AI gateway is not able to process requests. To resolve this issue, [check if the AI gateway can make a request to the model](#check-if-the-ai-gateway-can-make-a-request-to-the-model).

## Check if the AI gateway can make a request to the model

From the AI gateway container, make an HTTP request to the AI gateway API for a
Code Suggestion. Replace:

- `<your_model_name>` with the name of the model you are using. For example `mistral` or `codegemma`.
- `<your_model_endpoint>` with the endpoint where the model is hosted.

```shell
docker exec -it <ai-gateway-container> sh
curl --request POST "http://localhost:5052/v1/chat/agent" \
     --header 'accept: application/json' \
     --header 'Content-Type: application/json' \
     --data '{ "prompt_components": [ { "type": "string", "metadata": { "source": "string", "version": "string" }, "payload": { "content": "Hello", "provider": "litellm", "model": "<your_model_name>", "model_endpoint": "<your_model_endpoint>" } } ], "stream": false }'
```

If the request fails, the:

- AI gateway might not be configured properly to use self-hosted models. To resolve this,
  [check that the AI gateway URL is set up correctly](#check-that-the-ai-gateway-url-is-set-up-correctly).
- AI gateway might not be able to access the model. To resolve,
  [check if the model is reachable from the AI gateway](#check-if-the-model-is-reachable-from-ai-gateway).
- Model name or endpoint might be incorrect. Check the values, and correct them
  if necessary.

## Check if AI gateway can process requests

```shell
docker exec -it <ai-gateway-container> sh
curl '<your-aigateway-endpoint>/monitoring/healthz'
```

If the response is not `200`, this means that AI gateway is not installed correctly. To resolve, follow the [documentation on how to install the AI gateway](../../install/install_ai_gateway.md).

## Check that the AI gateway environment variables are set up correctly

To check that the AI gateway environment variables are set up correctly, run the
following in a console on the AI gateway container:

```shell
docker exec -it <ai-gateway-container> sh
echo $AIGW_CUSTOM_MODELS__ENABLED # must be true
```

If the environment variables are not set up correctly, set them by
[creating a container](../../install/install_ai_gateway.md#find-the-ai-gateway-release).

## Check if the model is reachable from AI gateway

Create a shell on the AI gateway container and make a curl request to the model.
If you find that the AI gateway cannot make that request, this might be caused by the:

1. Model server not functioning correctly.
1. Network settings around the container not being properly configured to allow
   requests to where the model is hosted.

To resolve this, contact your network administrator.

## Check if AI Gateway can make requests to your GitLab instance

The GitLab instance defined in `AIGW_GITLAB_URL` must be accessible from the AI Gateway container for request authentication.
If the instance is not reachable (for example, because of proxy configuration errors), requests can fail with errors, such as the following:

- ```shell
  jose.exceptions.JWTError: Signature verification failed
  ```

- ```shell
  gitlab_cloud_connector.providers.CompositeProvider.CriticalAuthError: No keys founds in JWKS; are OIDC providers up?
  ```

In this scenario, verify if  `AIGW_GITLAB_URL` and `$AIGW_GITLAB_API_URL` are properly set to the container and accessible.
The following commands should be successful when run from the container:

```shell
poetry run troubleshoot
curl "$AIGW_GITLAB_API_URL/projects"
```

If not successful, verify your network configurations.

## The image's platform does not match the host

When [finding the AI gateway release](../../install/install_ai_gateway.md#find-the-ai-gateway-release),
you might get an error that states `The requested image's platform (linux/amd64) does not match the detected host`.

To work around this error, add `--platform linux/amd64` to the `docker run` command:

```shell
docker run --platform linux/amd64 -e AIGW_GITLAB_URL=<your-gitlab-endpoint> <image>
```

## LLM server is not available inside the AI gateway container

If the LLM server is installed on the same instance as the AI gateway container, it may not be accessible through the local host.

To resolve this:

1. Include `--network host` in the `docker run` command to enable local requests from the AI gateway container.
1. Use the `-e AIGW_FASTAPI__METRICS_PORT=8083` flag to address the port conflicts.

```shell
docker run --network host -e AIGW_GITLAB_URL=<your-gitlab-endpoint> -e AIGW_FASTAPI__METRICS_PORT=8083 <image>
```

## vLLM 404 Error

If you encounter a **404 error** while using vLLM, follow these steps to resolve the issue:

1. Create a chat template file named `chat_template.jinja` with the following content:

   ```jinja
   {%- for message in messages %}
     {%- if message["role"] == "user" %}
       {{- "[INST] " + message["content"] + "[/INST]" }}
     {%- elif message["role"] == "assistant" %}
       {{- message["content"] }}
     {%- elif message["role"] == "system" %}
       {{- bos_token }}{{- message["content"] }}
     {%- endif %}
   {%- endfor %}
   ```

1. When running the vLLM command, ensure you specify the `--served-model-name`. For example:

   ```shell
   vllm serve "mistralai/Mistral-7B-Instruct-v0.3" --port <port> --max-model-len 17776 --served-model-name mistral --chat-template chat_template.jinja
   ```

1. Check the vLLM server URL in the GitLab UI to make sure that URL includes the `/v1` suffix. The correct format is:

   ```shell
   http(s)://<your-host>:<your-port>/v1
   ```

## Code Suggestions access error

If you are experiencing issues accessing Code Suggestions after setup, try the following steps:

1. In the Rails console, check and verify the license parameters:

   ```shell
   sudo gitlab-rails console
   user = User.find(id) # Replace id with the user provisioned with GitLab Duo Enterprise seat
   Ability.allowed?(user, :access_code_suggestions) # Must return true
   ```

1. Check if the necessary features are enabled and available:

   ```shell
   ::Ai::FeatureSetting.code_suggestions_self_hosted? # Should be true
   ```

## Verify GitLab setup

To verify your GitLab Self-Managed setup, run the following command:

```shell
gitlab-rake gitlab:duo:verify_self_hosted_setup
```

## No logs generated in the AI gateway server

If no logs are generated in the **AI gateway server**, follow these steps to troubleshoot:

1. Ensure the `expanded_ai_logging` feature flag is enabled:

   ```ruby
   Feature.enable(:expanded_ai_logging)
   ```

1. Run the following commands to view the GitLab Rails logs for any errors:

   ```shell
   sudo gitlab-ctl tail
   sudo gitlab-ctl tail sidekiq
   ```

1. Look for keywords like "Error" or "Exception" in the logs to identify any underlying issues.

## SSL certificate errors and key de-serialization issues in the AI gateway Container

When attempting to initiate a Duo Chat inside the AI gateway container, SSL certificate errors and key deserialization issues may occur.

The system might encounter issues loading the PEM file, resulting in errors like:

```plaintext
JWKError: Could not deserialize key data. The data may be in an incorrect format, the provided password may be incorrect, or it may be encrypted with an unsupported algorithm.
```

To resolve the SSL certificate error:

- Set the appropriate certificate bundle path in the Docker container using the following environment variables:
  - `SSL_CERT_FILE=/path/to/ca-bundle.pem`
  - `REQUESTS_CA_BUNDLE=/path/to/ca-bundle.pem`

## Troubleshooting common Duo Chat errors

### Error A1000

You might get an error that states
`I'm sorry, I couldn't respond in time. Please try again. Error code: A1000`.

This error occurs when there is a timeout during processing. Try your request again.

### Error A1001

You might get an error that states
`I'm sorry, I can't generate a response. Please try again. Error code: A1001`.

This error means there was a problem connecting to the AI gateway. You might need to check the network settings and ensure that the AI gateway is accessible from the GitLab instance.

Use the [self-hosted debugging script](#use-debugging-scripts) to verify if the AI gateway is accessible from the GitLab instance and is working as expected.

If problem persists, report the issue to the GitLab support team.

### Error A1002

You might get an error that states
`I'm sorry, I couldn't respond in time. Please try again. Error code: A1002`.

This error occurs when no events are returned from AI gateway or GitLab failed to parse the events. Check the [AI Gateway logs](logging.md) for any errors.

### Error A1003

You might get an error that states
`I'm sorry, I couldn't respond in time. Please try again. Error code: A1003`.

This error typically occurs due to issues with streaming from the model to the AI gateway. To resolve this issue:

1. In the AI gateway container, run the following command:

   ```shell
   curl --request 'POST' \
   'http://localhost:5052/v2/chat/agent' \
   --header 'accept: application/json' \
   --header 'Content-Type: application/json' \
   --header 'x-gitlab-enabled-feature-flags: expanded_ai_logging' \
   --data '{
     "messages": [
       {
         "role": "user",
         "content": "Hello",
         "context": null,
         "current_file": null,
         "additional_context": []
       }
     ],
     "model_metadata": {
       "provider": "custom_openai",
       "name": "mistral",
       "endpoint": "<change here>",
       "api_key": "<change here>",
       "identifier": "<change here>"
     },
     "unavailable_resources": [],
     "options": {
       "agent_scratchpad": {
         "agent_type": "react",
         "steps": []
       }
     }
   }'
   ```

   If streaming is working, chunked responses should be displayed. If it is not, it will likely show an empty response.

1. Check the [AI gateway logs](logging.md) for specific error messages, because this is usually a model deployment issue.

1. To validate the connection, disable the streaming by setting the `AIGW_CUSTOM_MODELS__DISABLE_STREAMING` environment variable in your AI gateway container:

   ```shell
   docker run .... -e AIGW_CUSTOM_MODELS__DISABLE_STREAMING=true ...
   ```

### Error A9999

You might get an error that states
`I'm sorry, I can't generate a response. Please try again. Error code: A9999`.

This error occurs when an unknown error occurs in ReAct agent. Try your request again. If the problem persists, report the issue to the GitLab support team.

## Related topics

- [GitLab Duo troubleshooting](../../user/gitlab_duo_chat/troubleshooting.md)
