---
stage: AI-powered
group: AI Framework
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLab Duo Glossary
---

This is a list of terms that may have a general meaning but also may have a
specific meaning at GitLab. If you encounter a piece of technical jargon related
to AI that you think could benefit from being in this list, add it!

## General terminology

### Adapters

A variation on Fine Tuning. Instead of opening the model and adjusting the layer weights, new trained layers are added onto the model or hosted in an upstream standalone model. Also known as Adapter-based Models. By selectively fine-tuning these specific modules rather than the entire model, Adapters facilitate the customisation of pre-trained models for distinct tasks, requiring only a minimal increase in parameters. This method enables precise, task-specific adjustments of the model without altering its foundational structure.

### AI Catalog

A central registry of available agents and flows in the Duo Agent Platform.
Shared across the instance. The Catalog functions as both a marketplace and
control plane, enabling safe, observable, and scalable AI deployment across
GitLab.

It provides:

- **Discovery**: Users can browse, search, and understand what AI capabilities exist.
- **Governance**: Admins can manage access, usage policies, and audit logs.
- **Extensibility**: Developers can register new agents or flows with metadata, inputs/outputs, and
  performance metrics.

### AI gateway

Standalone service used to give access to AI features to non-SaaS GitLab users. This logic will be moved to Cloud Connector when that service is ready. Eventually, the AI gateway will be used to host endpoints that proxy requests to AI providers, removing the need for the GitLab Rails monolith to integrate and communicate directly with third-party Large Language Models (LLMs). [Design document](https://handbook.gitlab.com/handbook/engineering/architecture/design-documents/ai_gateway/).

### AI gateway prompt

An encapsulation of prompt templates, model selection, and model parameters. As part of the [AI gateway as the Sole Access Point for Monolith to Access Models](https://gitlab.com/groups/gitlab-org/-/epics/13024) effort we're migrating these components from the GitLab Rails monolith into [the `prompts` package in the AI gateway](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/-/tree/main/ai_gateway/prompts).

### AI gateway prompt registry

A component responsible for maintaining a list of AI gateway Prompts available to perform specific actions. Currently, we use a [`LocalPromptRegistry`](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/-/blob/874e05281cab50012a53685e051583e620dac8c4/ai_gateway/prompts/registry.py#L18) that reads definitions from YAML files in the AI gateway.

### air-gapped model

A hosted model that is internal to an organization's intranet only. In the context of GitLab AI features, this could be connected to an air-gapped GitLab instance.

### Bring Your Own Model (BYOM)

A third-party model to be connected to one or more GitLab Duo features. Could be an off-the-shelf Open Source (OS) model, a fine-tuned model, or a closed source model. GitLab is planning to support specific, validated BYOMs for GitLab Duo features, but does not plan to support general BYOM use for GitLab Duo features.

### Chat evaluation

Automated mechanism for determining the helpfulness and accuracy of GitLab Duo Chat to various user questions. The MVC is an RSpec test run via GitLab CI that asks a set of questions to Chat and then has a two different third-party LLMs determine if the generated answer is accurate or not. [MVC](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/134610). [Design doc for next iteration](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/136127).

### Cloud Connector

Cloud Connector is a way to access services common to multiple GitLab deployments, instances, and cells. We use it as an umbrella term to refer to the set of technical solutions and APIs used to make such services available to all GitLab customers. For more information, see the [Cloud Connector architecture](../cloud_connector/architecture.md).

### Closed source model

A private model fine-tuned or built from scratch by an organisation. These may be hosted as cloud services, for example ChatGPT.

### Consensus filtering

Consensus filtering is a method of LLM evaluation. An LLM judge is asked to rate and compare the output of multiple LLMs to sets of prompts. This is the method of evaluation being used for the Chat Evaluation MVC. [Issue from Model Validation team](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/prompt-library/-/issues/91#metric-2-consensus-filtering-with-llm-based-evaluation).

### Context

Relevant information that surrounds a data point, an event, or a piece of information, which helps to clarify its meaning and implications. For GitLab Duo Chat, context is the attributes of the Issue or Epic being referenced in a user question.

### Custom model

Any implementation of a GitLab Duo feature using a self-hosted model, BYOM, fine-tuned model, RAG-enhanced model, or adapter-based model.

### Embeddings

In the context of machine learning and large language models, embeddings refer to a technique used to represent words, phrases, or even entire documents as dense numerical vectors in a continuous vector space. At GitLab, [we use Vertex AI's Embeddings API](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/129930) to create a vector representation of GitLab documentation. These embeddings are stored in the `vertex_gitlab_docs` database table in the `embeddings` database. The embeddings search is done in Postgres using the `vector` extension. The vertex embeddings database is updated based on the latest version of GitLab documentation on a daily basis by running `Llm::Embedding::GitlabDocumentation::CreateEmbeddingsRecordsWorker` as a cronjob.

### Fine-tuning

Altering an existing model using a supervised learning process that utilizes a dataset of labeled examples to update the weights of the LLM, improving its output for specific tasks such as code completion or Chat.

### Foundational model

A general purpose LLM trained using a generic objective, typically next token prediction. These models are capable and flexible, and can be adjusted to solved many domain-specific tasks (through finetuning or prompt engineering). This means that these general purpose models are ideal to serve as the foundation of many downstream models. Examples of foundational models are: GPT-4o, Claude 3.7 Sonnet.

### Frozen model

A LLM which cannot be fine-tuned (also Frozen LLM).

### GitLab Duo

AI-assisted features across the GitLab DevSecOps platform. These features aim to help increase velocity and solve key pain points across the software development lifecycle. See also the [GitLab Duo](../../user/gitlab_duo/_index.md) features page.

### GitLab-managed model

A LLM that is managed by GitLab. Currently all [GitLab Managed Models](https://gitlab.com/gitlab-com/gl-infra/scalability/-/issues/2864#note_1787040242) are hosted externally and accessed through the AI gateway. GitLab-owned API keys are used to access the models.

### Golden questions

A small subset of the types of questions we think a user should be able to ask GitLab Duo Chat. Used to generate data for Chat evaluation. [Questions for Chat Beta](https://gitlab.com/groups/gitlab-org/-/epics/10550#what-the-user-can-ask).

### Ground truth

Data that is determined to be the true output for a given input, representing the reality that the AI model aims to learn and predict. Ground truth data are often human-annotated, but may also be produced from a trusted source such as an LLM that has known good output for a given use case.

### Local model

A LLM running on a user's workstation. [More information](https://gitlab.com/groups/gitlab-org/-/epics/12907).

### LLM

A Large Language Model, or LLM, is a very large-scale neural network trained to understand and generate human-like text. For [GitLab Duo features](../../user/gitlab_duo/_index.md), GitLab is currently working with frozen models hosted at [Google and Anthropic](https://gitlab.com/gitlab-com/gl-infra/scalability/-/issues/2864#note_1787040242)

### Offline model

A model that runs without internet or intranet connection (for example, you are running a model on your laptop on a plane).

### Open-source model

Models that are published with their source code and weights and are available for modifications and re-distribution. Examples: Llama / Llama 2, BLOOM, Falcon, Mistral, Gemma.

### Centralized Evaluation Framework

The ["Centralized Evaluation Framework"](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/prompt-library) is a Python library that provides a CLI for evaluating GitLab AI features. It enables data-driven improvements to LLM applications by facilitating hypothesis testing. [Code](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/prompt-library).

### Prompt registry

Stored, versioned prompts used to interact with third-party AI Services. [Design document proposal MR (closed)](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/135872).

### Prompt

Natural language instructions sent to an LLM to perform certain tasks. [Prompt guidelines](ai_feature_development_playbook.md).

### RAG (Retrieval Augmented Generation)

RAG provide contextual data to an LLM as part of a query to personalise results. RAG is used to inject additional context into a prompt to decrease hallucinations and improve the quality of outputs.

### RAG pipeline

A mechanism used to take an input (such as a user question) into a system, retrieve any relevant data for that input, augment the input with additional context, and then synthesize the information to generate a coherent, contextualy-relevant answer. This design pattern is helpful in open-domain question answering with LLMs, which is why we use this design pattern for answering questions to GitLab Duo Chat.

### Self-hosted model

A LLM hosted externally to GitLab by an organisation and interacting with GitLab AI features. See also the [style guide reference](../documentation/styleguide/word_list.md#self-hosted-model).

### Similarity score

A mathematical method to determine the likeness between answers produced by an LLM and the reference ground truth answers. See also the [Model Validation direction page](https://about.gitlab.com/direction/ai-powered/ai_model_validation/ai_evaluation/metrics/#similarity-scores)

### Tool

Logic that performs a specific LLM-related task; each tool has a description and its own prompt. [How to add a new tool](duo_chat.md#adding-a-new-tool).

### Unit primitive

GitLab-specific term that refers to the fundamental logical feature that a permission or access scope can control. Examples: [`duo_chat`](../../user/gitlab_duo_chat/_index.md) and [`code_suggestions`](../../api/code_suggestions.md). These features are both currently part of the GitLab Duo Pro license but we are building the concept of a Unit Primitive around each Duo feature so that Duo features are easily composable into different groupings to accommodate potential future product packaging needs.

### Word-level metrics

Method for LLM evaluation that compares aspects of text at the granularity of individual words. [Issue from Model Validation team](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/prompt-library/-/issues/98#metric-3-word-level-metrics).

### Zero-shot agent

In the general world of AI, a learning model or system that can perform tasks without having seen any
examples of that task during training. At GitLab, we use this term to refer specifically to a piece of our code that serves
as a sort of LLM-powered air traffic controller for GitLab Duo Chat. The GitLab zero-shot agent has a
system prompt that explains how an LLM should interpret user input from GitLab Duo Chat as well as a
list of tool descriptions. Using this information, the agent determines which tool to use to answer a user's question.
The agent may decide that no tools are required and answer the question directly.
If a tool is used, the answer from the tool is fed back to the zero-shot agent to evaluate if the answer is
sufficient or if an additional tool must be used to answer the question.

[Code](https://gitlab.com/gitlab-org/gitlab/-/blob/6b747cbd7c6a71145a8bfb8201db3c857b5aed6a/ee/lib/gitlab/llm/chain/agents/zero_shot/executor.rb).

[Zero-shot agent in action](https://gitlab.com/gitlab-org/gitlab/-/issues/427979).

## GitLab Duo Agent Platform

### Flow

A predefined, structured sequence of steps that orchestrates a team of agents to execute actions
(either agentic or deterministic) to complete a task. Flows are initiated by triggers or manually.
Inputs can be natural language or predefined key-values (for example, project name, feature flag to
remove).

Example: "Generate test cases → Update CI pipeline file → Commit changes → Notify user in MR."

#### Flow types

- **Foundational**: Defined in the Duo Workflow Service, shipped and maintained by GitLab (for example, issue-to-MR flow).
- **Custom**: Built by users through the AI Catalog.

#### Flow execution

- **Runner job**: Sometimes called "remote execution." Asynchronous execution in
  the platform using GitLab Runner.
- **Local (IDE or CLI)**: Synchronous execution. Can interact directly with the file system
  (for example, Software Development Flow).

#### When to use flows

Flows are best used for repeatable, multi-step automations that need to run reliably and
consistently across projects. Flows are ideal when a task follows a predictable pattern, such as
fixing failing pipelines, updating dependencies, or applying policy checks. Flows can be
executed without continuous human input.

### Agent

An Agent is an autonomous, persona-like software component powered by an AI
model. Agents perform a specific task or set of tasks on behalf of the user or
system in the GitLab ecosystem

#### Agent types

- **Foundational**: A GitLab-maintained, platform-native agent that provides general or cross-workflow intelligence.
  - Purpose: Serves as a baseline capability accessible across the product,
    ensuring consistent quality, safety, and governance.
  - How to invoke: Foundational Agents can be invoked in Duo Chat only
  - Example: Duo Security Analyst Chat Agent for answering questions about
    vulnerabilities in chat.
- **Custom**: Built by users through the AI Catalog.
  - Purpose: Enables teams to leverage proprietary knowledge, tools, and decision logic in GitLab guardrails.
  - How to invoke: Custom Agents can be invoked in Duo Chat only
  - Example: An agent created specifically answering a questions about a codebase
- **External**: Also known as "Third-Party Flows" or "CLI Agents." An externally developed agent integrated into the Duo Agent Platform
  - Purpose: Expands platform capability by allowing external vendors to operate
    in the GitLab workflow orchestration and policy layer.
  - How to invoke: External Agents are invoked through `@` mentions in comments OR through
    assignment to issues, epics, or merge requests. They cannot be invoked through Duo
    Chat.
  - Example: Amazon Q or Claude integrated for code generation or review.

#### Agent Execution

Custom and foundational agents can be executed in the Duo Chat interface.

External agents can be configured with triggers.

#### When to use agents

Agents are best used for on-demand, interactive, or context-specific tasks that benefit from
reasoning and natural-language interaction, such as explaining code, summarizing issues, generating
content, or providing recommendations. They are ideal when the task requires flexibility and
human-in-the-loop decision-making rather than a predefined, repeatable workflow.

### Session

The contextual runtime state of an agent or flow that begins after an agent or
flow is triggered. During a session, agents perform actions to complete tasks.
Agents reason over evolving context and maintain continuity across interactions.
For example, remembering prior steps in a refactor sequence or the rationale
behind a code fix.

In the GitLab UI, sessions capture:

- Status (for example: running, complete, waiting for input, etc.)
- Conversation history
- System state (e.g., project metadata, MR content)

### Tool

A **discrete, deterministic capability** an agent (or flow step) invokes to perform read or write
actions. Tools can be used to perform these in GitLab or in third-party applications through MCP
or other protocols.

*Examples:* read GitLab issues, clone a repository, commit and push changes, call a REST API.
Tools expose data or side-effects; they themselves perform **no reasoning**.

### Trigger

An event that starts a Flow or activates an External Agent. Triggers are created
for each External Agent or Flow on a per-project basis. To run a flow,
there must be a trigger configured for that External Agent or Flow in that project.

Events include:

- System events (for example, new merge request opened, CI job failed)
- User prompts or actions (for example, `@` mention on an issue, issue assignment “)
- Time-based (for example, daily at 18:00, every Monday) (planned)

Many Triggers can be created to start Flows, however, there are only two available
Triggers (`@` mention and issue assignment) for External Agents.

### Supporting terminology

| Term | Definition |
| ---- | ---------- |
| **Node (Flow node)** | A single step in the flow graph. GitLab currently supports *Agent*, *Tool Executor*, *Agent Handover*, *Supervisor*, and *Terminator* nodes. |
| **Task** | A formal object representing a unit of work inside a run. At present only the *Executor* agent persists tasks, but the concept is extensible. |
| **Agent handover** | Node type that packages context from one agent and passes it to another. |
| **Supervisor agent** | An agent node that monitors other agents' progress and enforces run-level constraints (timeout, max tokens, etc.). |
| **Subagent** | Shorthand for an agent that operates under a Supervisor within the same run. |
| **Autonomous agent** | Historical term for an agent that can loop without human approval. In GitLab, autonomy level is governed by flow design, not by a separate agent type. |
| **Framework** | A platform for building multi-agent systems. GitLab Duo Agent Platform uses **LangGraph**, an extension to LangChain that natively models agent graphs. |

## Quick Reference Matrix

| Layer | Human Analogy | Key Question Answered |
| ----- | ------------- | --------------------- |
| **Tool** | Capability | "What concrete action can I perform?" |
| **Agent** | Skill / Specialist | "How do I use my tools to reach my goal?" |
| **Flow** | Competency / Job | "When and in what order should skills be applied to deliver value?" |

## AI context terminology

### Advanced context resolver

Advanced context is a comprehensive set of code-related information extending
beyond a single file, including open file tabs, imports, dependencies,
cross-file symbols and definitions, and project-wide relevant code snippets.

Advanced context *resolver* is a system designed to gather the above advanced context.
By providing advanced context, the resolver providers the LLM with a more
holistic understanding of the project structure, enabling more accurate and
context-aware code suggestions and generation.

### AI context abstraction layer

A [Ruby gem](https://gitlab.com/gitlab-org/gitlab/-/tree/master/gems/gitlab-active-context) that provides a unified interface for Retrieval Augmented Generation (RAG) across multiple vector databases in GitLab. The system abstracts away the differences between Elasticsearch, OpenSearch, and PostgreSQL with pgvector, enabling AI features to work regardless of the underlying storage solution.

Key components include collections that define data schemas and reference classes that handle serialization, migrations for schema management, and preprocessors for embedding generation. The layer supports automatic model migration between different LLMs without downtime, asynchronous processing through Redis-backed queues, and permission-aware search with automatic redaction.

This [architecture](https://handbook.gitlab.com/handbook/engineering/architecture/design-documents/ai_context_abstraction_layer/) prevents vendor lock-in and enables GitLab customers without Elasticsearch to access RAG-powered features through pgvector.

### AI context policies

A user-defined and user-managed mechanism allowing precise control over the
content that can be sent to LLMs as contextual information.
GitLab has an [architecture document](https://handbook.gitlab.com/handbook/engineering/architecture/design-documents/ai_context_management/)
that proposes a format for AI Context Policies.

### Codebase as chat context

This refers to a repository that the user explicitly provides using the `/include` command. The user may narrow the scope by choosing a directory within a repository.
This feature allows the user to ask questions about an entire repository, or a subset of that repository by selecting specific directories.

This is automatically enhanced by performing a semantic search of the user's question over the [Code Embeddings](#code-embeddings) of the included repository,
with the search results then added to the context sent to the LLM. This gives the LLM information about the included repository or directory that is specifically
targeted to the user's question, allowing the LLM to generate a more helpful response.

This [architecture document](https://handbook.gitlab.com/handbook/engineering/architecture/design-documents/codebase_as_chat_context/) proposes
Codebase as Chat Context enhanced by semantic search over Code Embeddings.

In the future, the repository or directory context may also be enhanced by a [Knowledge Graph](#knowledge-graph) search.

### Code embeddings

The [Code Embeddings initiative](https://handbook.gitlab.com/handbook/engineering/architecture/design-documents/codebase_as_chat_context/code_embeddings/)
aims to build vector embeddings representation of files in a repository. The file contents are chunked into logical segments, then embeddings are generated
for the chunked content and stored in a vector store.

With Code Embeddings, we can perform a semantic search over a given repository, with the search results then used as additional context for an LLM.
(See [Codebase as Chat Context](#codebase-as-chat-context) for how Code Embeddings will be used in Duo Chat.)

### GitLab Zoekt

A scalable exact code search service and file-based database system, with flexible architecture supporting various AI context use cases beyond traditional search. It's built on top of open-source code search engine Zoekt.

The system consists of a unified `gitlab-zoekt` binary that can operate in both indexer and webserver modes, managing index files on persistent storage for fast searches. Key features include bi-directional communication with GitLab and self-registering node [architecture](https://handbook.gitlab.com/handbook/engineering/architecture/design-documents/code_search_with_zoekt/) for easy scaling.

The system is designed to handle enterprise-scale deployments, with GitLab.com successfully operating over 48 TiB of indexed data.

Most likely, this distributed database system will be used to power [Knowledge Graph](#knowledge-graph). Also, we might leverage Exact Code Search to provide additional context and/or tools for GitLab Duo.

### Knowledge graph

The [Knowledge Graph](https://gitlab.com/gitlab-org/rust/knowledge-graph) project aims to create a structured, queryable graph database from code repositories to power AI features and enhance developer productivity within GitLab.

Think of it like creating a detailed blueprint that shows which functions call other functions, how classes relate to each other, and where variables are used throughout the codebase. Instead of GitLab Duo having to read through thousands of files every time you ask it something, it can quickly navigate this pre-built map to give you better code suggestions, find related code snippets, or help debug issues. It gives Duo a much smarter way to understand your codebase so it can assist you more effectively with things like code reviews, refactoring, or finding where to make changes when you're working on a feature.

### One parser (GitLab Code Parser)

The [GitLab Code Parser](https://gitlab.com/gitlab-org/code-creation/gitlab-code-parser#) establishes a single, efficient, and reliable static code analysis library. This library will serve as the foundation for diverse code intelligence features across GitLab, from server-side indexing (Knowledge Graph, Embeddings) to client-side analysis (Language Server, Web IDE). Initially scoped to AI and Editor Features.

### Supplementary user context

Information, such as open tabs in their IDE, files, and folders,
that the user provides from their local environment to extend the default AI
Context. This is sometimes called "pinned context" internally. GitLab Duo Chat users
can provide supplementary user context with the `/include` command (IDE only).

## GitLab Licensing and Subscription Terminology

### Add-on

Additional features or services that can be purchased and added to a GitLab subscription. Examples include:

- **Duo Core**: Basic AI-powered features assigned at the namespace level
- **Duo Pro**: Advanced AI-powered features for individual users
- **Duo Enterprise**: Enterprise-level AI features with additional security and compliance capabilities

### User add-on assignment

The process of assigning add-on features to individual users. For most add-ons like Duo Pro and Duo Enterprise, this creates a direct user-to-add-on relationship.

However, Duo Core is an exception as it's assigned at the namespace level. On GitLab.com, Duo Core user access is determined by checking if the user has membership in any namespace with the Duo Core [turned on](../../user/gitlab_duo/turn_on_off.md#turn-gitlab-duo-core-on-or-off). On other instances, Duo Core user access is determined by checking if the instance has Duo Core turned on.

### License

Specifically refers to the license file used for **Self-Managed GitLab instances**. The license file is uploaded to activate paid-tier features (Premium or Ultimate) on self-managed installations. Self-managed customers have both a subscription (what they pay for) and a license file (what they upload to activate features).

### Subscription

Refers to the tier level a customer is using, which determines available features:

- **Free**: Basic GitLab features at no cost
- **Premium**: Mid-tier features for teams and organizations
- **Ultimate**: Full-featured tier with advanced security, compliance, and planning tools

The implementation differs by deployment type:

- **SaaS (GitLab.com)**: Only requires a subscription - no license file needed since GitLab manages everything
- **Self-managed**: Requires both a subscription (billing) and a license file (feature activation)
- **Community/Education**: Special free subscriptions for qualifying organizations (schools, open source projects) that provide paid-tier features at no cost
