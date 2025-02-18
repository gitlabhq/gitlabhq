---
stage: AI-powered
group: AI Framework
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Logged events
---

In addition to standard logging in the GitLab Rails Monolith instance, specialized logging is available for features based on large language models (LLMs).

## Events logged

<!-- markdownlint-disable -->
<!-- vale off -->

### Returning from Service due to validation

  - Description: user not permitted to perform action
  - Class: `Llm::BaseService`
  - Ai_event_name: permission_denied
  - Level: info
  - Arguments:
    - none
  - Part of the system: abstraction_layer
  - Expanded logging?: no
  - Rails: yes
  - Sidekiq: no

### Enqueuing CompletionWorker

  - Description: scheduling completion worker in sidekiq
  - Class: `Llm::BaseService`
  - Ai_event_name: worker_enqueued
  - Level: info
  - Arguments:
    - `user_id: message.user.id`
    - `resource_id: message.resource&.id`
    - `resource_class: message.resource&.class&.name`
    - `request_id: message.request_id`
    - `action_name: message.ai_action`
    - `options: job_options`
  - Part of the system: abstraction_layer
  - Expanded logging?: yes
  - Rails: yes
  - Sidekiq: no

### aborting: missing resource

  - Description: If there is no resource for slash command
  - Class: `Llm::ChatService`
  - Ai_event_name: missing_resource
  - Level: info
  - Arguments:
    - none
  - Part of the system: duo_chat
  - Expanded logging?: no
  - Rails: yes
  - Sidekiq: no

### Performing CompletionService

  - Description: performing completion
  - Class: `Llm::Internal::CompletionService`
  - Ai_event_name: completion_service_performed
  - Level: info
  - Arguments:
    - `user_id: prompt_message.user.to_gid`
    - `resource_id: prompt_message.resource&.to_gid`
    - `action_name: prompt_message.ai_action`
    - `request_id: prompt_message.request_id`
    - `client_subscription_id: prompt_message.client_subscription_id`
    - `completion_service_name: completion_class_name`
  - Part of the system: abstraction_layer
  - Expanded logging?: yes
  - Rails: no
  - Sidekiq: yes

### Answer from LLM response

  - Description: Get answer from response
  - Class: `Gitlab::Llm::Chain::Answer`
  - Ai_event_name: answer_received
  - Level: info
  - Arguments:
    - `llm_answer_content: content`
  - Part of the system: duo_chat
  - Expanded logging?: yes
  - Rails: no
  - Sidekiq: yes

### Final answer

  - Description: Get final answer from response
  - Class: `Gitlab::Llm::Chain::Answer`
  - Ai_event_name: final_answer_received
  - Level: info
  - Arguments:
    - `llm_answer_content: content`
  - Part of the system: duo_chat
  - Expanded logging?: yes
  - Rails: no
  - Sidekiq: yes

### Default final answer

  - Description: Default final answer: I'm sorry, I couldn't respond in time. Please try a more specific request or enter /clear to start a new chat.
  - Class: `Gitlab::Llm::Chain::Answer`
  - Ai_event_name: default_final_answer_received
  - Level: info
  - Arguments:
    - `error_code: "A6000"`
  - Part of the system: duo_chat
  - Expanded logging?: yes
  - Rails: no
  - Sidekiq: yes

### Error message/ "Error"

  - Description: when answering with an error
  - Class: `Gitlab::Llm::Chain::Answer`
  - Ai_event_name: error_returned
  - Level: error
  - Arguments:
    - `error: content`
    - `error_code: error_code`
    - `source: source`
  - Part of the system: duo_chat
  - Expanded logging?: no
  - Rails: no
  - Sidekiq: yes

### Received response from AI gateway

  - Description: when response from AIGW is returned
  - Class: `Gitlab::Llm::AiGateway::Client`
  - Ai_event_name: response_received
  - Level: info
  - Arguments:
    - `response_from_llm: response_body`
  - Part of the system: abstraction_layer
  - Expanded logging?: yes
  - Rails: no
  - Sidekiq: yes

### Received error from AI gateway

  - Description: when error is returned from AIGW for streaming command
  - Class: `Gitlab::Llm::AiGateway::Client`
  - Ai_event_name: error_response_received
  - Level: error
  - Arguments:
    - `response_from_llm: parsed_response.dig('detail', 0, 'msg')`
  - Part of the system: abstraction_layer
  - Expanded logging?: no
  - Rails: no
  - Sidekiq: yes

### Performing request to AI gateway

  - Description: before performing request to the AI GW
  - Class: `Gitlab::Llm::AiGateway::Client`
  - Ai_event_name: performing_request
  - Level: info
  - Arguments:
    - `url: url`
    - `body: body`
    - `timeout: timeout`
    - `stream: stream`
  - Part of the system: abstraction_layer
  - Expanded logging?: yes
  - Rails: no
  - Sidekiq: yes

### Creating user access token

  - Description: creating short-lived token in AIGW
  - Class: `Gitlab::Llm::AiGateway::CodeSuggestionsClient`
  - Ai_event_name: user_token_created
  - Level: info
  - Arguments:
    - none
  - Part of the system: code suggestions
  - Expanded logging?: no
  - Rails: yes
  - Sidekiq: no

### Received response from Anthropic

  - Description: Received response
  - Class: `Gitlab::Llm::Anthropic::Client`
  - Ai_event_name: response_received
  - Level: info
  - Arguments:
    - `ai_request_type: request_type`
    - `unit_primitive: unit_primitive`
  - Part of the system: abstraction_layer
  - Expanded logging?: no
  - Rails: no
  - Sidekiq: yes

### Response content

  - Description: Content of response
  - Class: `Gitlab::Llm::Anthropic::Client`
  - Ai_event_name: response_received
  - Level: info
  - Arguments:
    - `ai_request_type: request_type`
    - `unit_primitive: unit_primitive`
    - `response_from_llm: response_body`
  - Part of the system: abstraction_layer
  - Expanded logging?: yes
  - Rails: no
  - Sidekiq: yes

### Performing request to Anthropic

  - Description: performing completion request
  - Class: `Gitlab::Llm::Anthropic::Client`
  - Ai_event_name: performing_request
  - Level: info
  - Arguments:
    - `options: options`
    - `ai_request_type: request_type`
    - `unit_primitive: unit_primitive`
  - Part of the system: abstraction_layer
  - Expanded logging?: no
  - Rails: no
  - Sidekiq: yes

### Searching docs from AI gateway

  - Description: performing search docs request
  - Class: `Gitlab::Llm::AiGateway::DocsClient`
  - Ai_event_name: performing_request
  - Level: info
  - Arguments:
    - `options: options`
  - Part of the system: duo_chat
  - Expanded logging?: no
  - Rails: no
  - Sidekiq: yes

### Searched docs content from AI gateway

  - Description: response from AIGW with docs
  - Class: `Gitlab::Llm::AiGateway::DocsClient`
  - Ai_event_name: response_received
  - Level: info
  - Arguments:
    - `response_from_llm: response`
  - Part of the system: duo_chat
  - Expanded logging?: yes
  - Rails: no
  - Sidekiq: yes

### Json parsing error during Question Categorization

  - Description: logged when json is not parsable
  - Class: `Gitlab::Llm::AiGateway::Completions::CategorizeQuestions`
  - Ai_event_name: error
  - Level: error
  - Arguments:
    - none
  - Part of the system: duo_chat
  - Expanded logging?: no
  - Rails: no
  - Sidekiq: yes

### Response did not contain defined categories

  - Description: logged when response is not containing one of the defined categories
  - Class: `Gitlab::Llm::AiGateway::Completions::CategorizeQuestions`
  - Ai_event_name: error
  - Level: error
  - Arguments:
    - none
  - Part of the system: duo_chat
  - Expanded logging?: no
  - Rails: no
  - Sidekiq: yes

### Error response received while categorizing question

  - Description: logged when response returned is not succesful
  - Class: `Gitlab::Llm::AiGateway::Completions::CategorizeQuestions`
  - Ai_event_name: error
  - Level: error
  - Arguments:
    - `error_type: response.dig('error', 'type')`
  - Part of the system: duo_chat
  - Expanded logging?: no
  - Rails: no
  - Sidekiq: yes

### Picked tool

  - Description: information about tool picked by chat
  - Class: `Gitlab::Llm::Chain::Agents::ZeroShot::Executor`
  - Ai_event_name: picked_tool
  - Level: info
  - Arguments:
    - `duo_chat_tool: tool_class.to_s`
  - Part of the system: duo_chat
  - Expanded logging?: no
  - Rails: no
  - Sidekiq: yes

### Made request to AI Client

  - Description: making request for chat
  - Class: `Gitlab::Llm::Chain::Requests::AiGateway`
  - Ai_event_name: response_received
  - Level: info
  - Arguments:
    - `prompt: prompt[:prompt]`
    - `response_from_llm: response`
    - `unit_primitive: unit_primitive`
  - Part of the system: duo_chat
  - Expanded logging?: yes
  - Rails: no
  - Sidekiq: yes

### Streaming error

  - Description: Error returned when streaming
  - Class: `Gitlab::Llm::Chain::Requests::Anthropic`
  - Ai_event_name: error_response_received
  - Level: error
  - Arguments:
    - `error: data&.dig("error")`
  - Part of the system: abstraction_layer
  - Expanded logging?: no
  - Rails: no
  - Sidekiq: yes

### Got Final Result for documentation question content

  - Description: got result for documentation question - content
  - Class: `Gitlab::Llm::Chain::Tools::EmbeddingsCompletion`
  - Ai_event_name: response_received
  - Level: info
  - Arguments:
    - `prompt: final_prompt[:prompt]`
    - `response_from_llm: final_prompt_result`
  - Part of the system: duo_chat
  - Expanded logging?: yes
  - Rails: no
  - Sidekiq: yes

### Streaming error

  - Description: when error is returned from AIGW for streaming command in docs question
  - Class: `Gitlab::Llm::Chain::Tools::EmbeddingsCompletion`
  - Ai_event_name: error_response_received
  - Level: error
  - Arguments:
    - `error: error.message`
  - Part of the system: duo_chat
  - Expanded logging?: no
  - Rails: no
  - Sidekiq: yes

### Answer already received from tool

  - Description: when tool was already picked up (content: You already have the answer from #{self.class::NAME} tool, read carefully.)
  - Class: `Gitlab::Llm::Chain::Tools::Tool`
  - Ai_event_name: incorrect_response_received
  - Level: info
  - Arguments:
    - `error_message: content`
  - Part of the system: duo_chat
  - Expanded logging?: yes
  - Rails: no
  - Sidekiq: yes

### Tool cycling detected

  - Description: When tool is picked up again
  - Class: `Gitlab::Llm::Chain::Tools::Tool`
  - Ai_event_name: incorrect_response_received
  - Level: info
  - Arguments:
    - `picked_tool: cls.class.to_s`
  - Part of the system: duo_chat
  - Expanded logging?: no
  - Rails: no
  - Sidekiq: yes

### Calling TanukiBot

  - Description: performing documentation request
  - Class: `Gitlab::Llm::Chain::Tools::GitlabDocumentation::Executor`
  - Ai_event_name: documentation_question_initial_request
  - Level: info
  - Arguments:
    - none
  - Part of the system: duo_chat
  - Expanded logging?: no
  - Rails: no
  - Sidekiq: yes

### Error finding #{resource_name}

  - Description: when resource (issue/epic/mr) is not found
  - Class: `Gitlab::Llm::Chain::Tools::Identifier`
  - Ai_event_name: incorrect_response_received
  - Level: error
  - Arguments:
    - `error_message: authorizer.message`
  - Part of the system: duo_chat
  - Expanded logging?: no
  - Rails: no
  - Sidekiq: yes

### Answer received from LLM

  - Description: response from identifier
  - Class: `Gitlab::Llm::Chain::Tools::Identifier`
  - Ai_event_name: response_received
  - Level: info
  - Arguments:
    - `response_from_llm: content`
  - Part of the system: duo_chat
  - Expanded logging?: yes
  - Rails: no
  - Sidekiq: yes

### Json parsing error

  - Description: when json is malformed (Observation: JSON has an invalid format. Please retry)
  - Class: `Gitlab::Llm::Chain::Tools::Identifier`
  - Ai_event_name: error
  - Level: error
  - Arguments:
    - none
  - Part of the system: duo_chat
  - Expanded logging?: no
  - Rails: no
  - Sidekiq: yes

### Resource already identified

  - Description: already identified resource (You already have identified the #{resource_name} #{resource.to_global_id}, read carefully.)
  - Class: `Gitlab::Llm::Chain::Tools::Identifier`
  - Ai_event_name: incorrect_response_received
  - Level: info
  - Arguments:
    - `error_message: content`
  - Part of the system: duo_chat
  - Expanded logging?: yes
  - Rails: no
  - Sidekiq: yes

### Supported Issuable Typees Ability Allowed

  - Description: logging the ability (policy.can?) for the issue/epic
  - Class: `Gitlab::Llm::Chain::Tools::SummarizeComments::Executor`
  - Ai_event_name: permission
  - Level: info
  - Arguments:
    - `allowed: ability`
  - Part of the system: feature
  - Expanded logging?: yes
  - Rails: no
  - Sidekiq: yes

### Supported Issuable Typees Ability Allowed

  - Description: logging the ability (policy.can?) for the issue/epic
  - Class: `Gitlab::Llm::Chain::Tools::SummarizeComments::ExecutorOld`
  - Ai_event_name: permission
  - Level: info
  - Arguments:
    - `allowed: ability`
  - Part of the system: feature
  - Expanded logging?: yes
  - Rails: no
  - Sidekiq: yes

### Answer content for summarize_comments

  - Description: Answer for summarize comments feature
  - Class: `Gitlab::Llm::Chain::Tools::SummarizeComments::ExecutorOld`
  - Ai_event_name: response_received
  - Level: info
  - Arguments:
    - `response_from_llm: content`
  - Part of the system: feature
  - Expanded logging?: yes
  - Rails: no
  - Sidekiq: yes

### Content of the prompt from chat request

  - Description: chat-related request
  - Class: `Gitlab::Llm::Chain::Concerns::AiDependent`
  - Ai_event_name: prompt_content
  - Level: info
  - Arguments:
    - `prompt: prompt_text`
  - Part of the system: duo_chat
  - Expanded logging?: yes
  - Rails: no
  - Sidekiq: yes

### "Too many requests, will retry in #{delay} seconds"

  - Description: When entered in exponential backoff loop
  - Class: `Gitlab::Llm::Chain::Concerns::ExponentialBackoff`
  - Ai_event_name: retrying_request
  - Level: info
  - Arguments:
    - none
  - Part of the system: abstraction_layer
  - Expanded logging?: no
  - Rails: no
  - Sidekiq: yes

### Resource not found

  - Description: Resource not found/not authorized
  - Class: `Gitlab::Llm::Utils::Authorizer`
  - Ai_event_name: permission_denied
  - Level: info
  - Arguments:
    - `error_code: "M3003"`
  - Part of the system: abstraction_layer
  - Expanded logging?: no
  - Rails: no
  - Sidekiq: yes

### No access to Duo Chat

  - Description: No access to duo chat
  - Class: `Gitlab::Llm::Utils::Authorizer`
  - Ai_event_name: permission_denied
  - Level: info
  - Arguments:
    - `error_code: "M3004"`
  - Part of the system: abstraction_layer
  - Expanded logging?: no
  - Rails: no
  - Sidekiq: yes

### AI is disabled

  - Description: AI is not enabled for container
  - Class: `Gitlab::Llm::Utils::Authorizer`
  - Ai_event_name: permission_denied
  - Level: info
  - Arguments:
    - `error_code: "M3002"`
  - Part of the system: abstraction_layer
  - Expanded logging?: no
  - Rails: no
  - Sidekiq: yes

### Performing request to Vertex

  - Description: performing request
  - Class: `Gitlab::Llm::VertexAi::Client`
  - Ai_event_name: performing_request
  - Level: info
  - Arguments:
    - `unit_primitive: unit_primitive`
    - `options: config`
  - Part of the system: abstraction_layer
  - Expanded logging?: no
  - Rails: no
  - Sidekiq: yes

### Response content

  - Description: response from aigw - vertex -content
  - Class: `Gitlab::Llm::VertexAi::Client`
  - Ai_event_name: response_received
  - Level: info
  - Arguments:
    - `unit_primitive: unit_primitive`
    - `response_from_llm: response.to_json`
  - Part of the system: abstraction_layer
  - Expanded logging?: yes
  - Rails: no
  - Sidekiq: yes

### Received response from Vertex

  - Description: response from aigw - vertex
  - Class: `Gitlab::Llm::VertexAi::Client`
  - Ai_event_name: response_received
  - Level: info
  - Arguments:
    - `unit_primitive: unit_primitive`
  - Part of the system: abstraction_layer
  - Expanded logging?: no
  - Rails: no
  - Sidekiq: yes

### Empty response from Vertex

  - Description: empty response from aigw - vertex
  - Class: `Gitlab::Llm::VertexAi::Client`
  - Ai_event_name: empty_response_received
  - Level: error
  - Arguments:
    - `unit_primitive: unit_primitive`
  - Part of the system: abstraction_layer
  - Expanded logging?: no
  - Rails: no
  - Sidekiq: yes

### Surface an unknown event as a final answer to the user

  - Description: unknown event
  - Class: `Gitlab::Llm::Chain::Agents::SingleActionExecutor`
  - Ai_event_name: unknown_event
  - Level: warn
  - Arguments:
    - none
  - Part of the system: duo_chat
  - Expanded logging?: no
  - Rails: no
  - Sidekiq: yes

### Failed to find a tool in GitLab Rails

  - Description: failed to find a tool
  - Class: `Gitlab::Llm::Chain::Agents::SingleActionExecutor`
  - Ai_event_name: tool_not_find
  - Level: error
  - Arguments:
    - `tool_name: tool_name`
  - Part of the system: duo_chat
  - Expanded logging?: no
  - Rails: no
  - Sidekiq: yes

### Received an event from v2/chat/agent

  - Description: Received event
  - Class: `Gitlab::Duo::Chat::StepExecutor`
  - Ai_event_name: event_received
  - Level: info
  - Arguments:
    - `event: event`
  - Part of the system: duo_chat
  - Expanded logging?: yes
  - Rails: no
  - Sidekiq: yes

### Failed to update observation

  - Description: Failed to update observation
  - Class: `Gitlab::Duo::Chat::StepExecutor`
  - Ai_event_name: agent_steps_empty
  - Level: error
  - Arguments:
    - none
  - Part of the system: duo_chat
  - Expanded logging?: no
  - Rails: no
  - Sidekiq: yes

### Request to v2/chat/agent

  - Description: request
  - Class: `Gitlab::Duo::Chat::StepExecutor`
  - Ai_event_name: performing_request
  - Level: info
  - Arguments:
    - `params: params`
  - Part of the system: duo_chat
  - Expanded logging?: yes
  - Rails: no
  - Sidekiq: yes

### Finished streaming from v2/chat/agent

  - Description: finished streaming
  - Class: `Gitlab::Duo::Chat::StepExecutor`
  - Ai_event_name: streaming_finished
  - Level: info
  - Arguments:
    - none
  - Part of the system: duo_chat
  - Expanded logging?: no
  - Rails: no
  - Sidekiq: yes

### Received error from Duo Chat Agent

  - Description: Error returned when streaming
  - Class: `Gitlab::Duo::Chat::StepExecutor`
  - Ai_event_name: error_returned
  - Level: error
  - Arguments:
    - `status: response.code`
  - Part of the system: duo_chat
  - Expanded logging?: no
  - Rails: no
  - Sidekiq: yes

### Failed to parse a chunk from Duo Chat Agent

  - Description: failed to parse a chunk
  - Class: `Gitlab::Duo::Chat::AgentEventParser`
  - Ai_event_name: parsing_error
  - Level: warn
  - Arguments:
    - `event_json_size: event_json.length`
  - Part of the system: duo_chat
  - Expanded logging?: no
  - Rails: no
  - Sidekiq: yes

### Failed to find the event class in GitLab-Rails

  - Description: no event class
  - Class: `Gitlab::Duo::Chat::AgentEventParser`
  - Ai_event_name: parsing_error
  - Level: error
  - Arguments:
    - `event_type: event['type']`
  - Part of the system: duo_chat
  - Expanded logging?: no
  - Rails: no
  - Sidekiq: yes

<!-- markdownlint-enable -->
<!-- vale on -->
