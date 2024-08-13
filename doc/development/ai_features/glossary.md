---
stage: AI-powered
group: AI Framework
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# GitLab Duo Glossary

This is a list of terms that may have a general meaning but also may have a
specific meaning at GitLab. If you encounter a piece of technical jargon related
to AI that you think could benefit from being in this list, add it!

- **Adapters**: A variation on Fine Tuning. Instead of opening the model and adjusting the layer weights, new trained layers are added onto the model or hosted in an upstream standalone model. Also known as Adapter-based Models. By selectively fine-tuning these specific modules rather than the entire model, Adapters facilitate the customisation of pre-trained models for distinct tasks, requiring only a minimal increase in parameters. This method enables precise, task-specific adjustments of the model without altering its foundational structure.
- **AI Gateway**: standalone service used to give access to AI features to
  non-SaaS GitLab users. This logic will be moved to Cloud Connector when that
  service is ready. Eventually, the AI Gateway will be used to host endpoints that
  proxy requests to AI providers, removing the need for the GitLab Rails monolith
  to integrate and communicate directly with third-party Large Language Models (LLMs).
  [Design document](https://handbook.gitlab.com/handbook/engineering/architecture/design-documents/ai_gateway/).
- **AI Gateway Prompt**: An encapsulation of prompt templates, model selection, and model parameters. As part of the [AI Gateway as the Sole Access Point for Monolith to Access Models](https://gitlab.com/groups/gitlab-org/-/epics/13024) effort we're migrating these components from the GitLab Rails monolith into [the `prompts` package in the AI Gateway](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/-/tree/main/ai_gateway/prompts).
- **AI Gateway Prompt Registry**: A component responsible for maintaining a list of AI Gateway Prompts available to perform specific actions. Currently, we use a [`LocalPromptRegistry`](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/-/blob/874e05281cab50012a53685e051583e620dac8c4/ai_gateway/prompts/registry.py#L18) that reads definitions from YAML files in the AI Gateway.
- **Air-Gapped Model**: A hosted model that is internal to an organisations intranet only. In the context of GitLab AI features, this could be connected to an air-gapped GitLab instance.
- **Bring Your Own Model (BYOM)**: A third-party model to be connected to one or more GitLab Duo features. Could be an off-the-shelf Open Source (OS) model, a fine-tuned model, or a closed source model. GitLab is planning to support specific, validated BYOMs for GitLab Duo features, but does not currently support or plan to support general BYOM use for GitLab Duo features.
- **Chat Evaluation**: automated mechanism for determining the helpfulness and
  accuracy of GitLab Duo Chat to various user questions. The MVC is an RSpec test
  run via GitLab CI that asks a set of questions to Chat and then has a
  two different third-party LLMs determine if the generated answer is accurate or not.
  [MVC](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/134610).
  [Design doc for next iteration](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/136127).
- **Cloud Connector**: Cloud Connector is a way to access services common to
  multiple GitLab deployments, instances, and cells. We use it as an umbrella term to refer to the
  set of technical solutions and APIs used to make such services available to all GitLab customers.
  For more information, see the [Cloud Connector architecture](../cloud_connector/architecture.md).
- **Closed Source Model**: A private model fine-tuned or built from scratch by an organisation. These may be hosted as cloud services, for example ChatGPT.
- **Consensus Filtering**: Consensus filtering is a method of LLM evaluation. An LLM judge is asked to rate and compare the output of multiple LLMs to sets of prompts. This is the method of evaluation being used for the Chat
  Evaluation MVC.
  [Issue from Model Validation team](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/prompt-library/-/issues/91#metric-2-consensus-filtering-with-llm-based-evaluation).
- **Context**: relevant information that surrounds a data point, an event, or a
  piece of information, which helps to clarify its meaning and implications.
  For GitLab Duo Chat, context is the attributes of the Issue or Epic being
  referenced in a user question.
- **Custom Model**: Any implementation of a GitLab Duo feature using a self-hosted model, BYOM, fine-tuned model, RAG-enhanced model, or adapter-based model.
- **Embeddings**: In the context of machine learning and large language models,
  embeddings refer to a technique used to represent words, phrases, or even
  entire documents as dense numerical vectors in a continuous vector space.
  At GitLab, [we use Vertex AI's Embeddings API](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/129930)
  to create a vector representation of GitLab documentation. These
  embeddings are stored in the `vertex_gitlab_docs` database table in the
  `embeddings` database. The embeddings search is done in Postgres using the
  `vector` extension. The vertex embeddings database is updated based on the
  latest version of GitLab documentation on a daily basis by running `Llm::Embedding::GitlabDocumentation::CreateEmbeddingsRecordsWorker` as a cronjob.
- **Fine Tuning**: Altering an existing model using a supervised learning process that utilizes a dataset of labeled examples to update the weights of the LLM, improving its output for specific tasks such as code completion or chat.
- **Frozen Model**: A LLM which cannot be fine-tuned (also Frozen LLM).
- **GitLab Duo**: AI-assisted features across the GitLab DevSecOps platform. These features aim to help increase velocity and solve key pain points across the software development lifecycle. See also the [GitLab Duo](../../user/ai_features.md) features page.
- **GitLab Managed Model**: A LLM that is managed by GitLab. Currently all [GitLab Managed Models](https://gitlab.com/gitlab-com/g**l-infra/scalability/-/issues/2864#note_1787040242) are hosted externally and accessed through the AI Gateway. GitLab-owned API keys are used to access the models.
- **Golden Questions**: a small subset of the types of questions we think a user
  should be able to ask GitLab Duo Chat. Used to generate data for Chat evaluation.
  [Questions for Chat Beta](https://gitlab.com/groups/gitlab-org/-/epics/10550#what-the-user-can-ask).
- **Ground Truth**: data that is determined to be the true
  output for a given input, representing the reality that the AI model aims to
  learn and predict. Ground truth data are often human-annotated, but may also be produced from a trusted source such as an LLM that has known good output for a given use case.
- **Local Model**: A LLM running on a user's workstation. [More information](https://gitlab.com/groups/gitlab-org/-/epics/12907).
- **LLM**: A Large Language Model, or LLM, is a very large-scale neural network trained to understand and generate human-like text. For [GitLab Duo features](../../user/ai_features.md), GitLab is currently working with frozen models hosted at [Google and Anthropic](https://gitlab.com/gitlab-com/gl-infra/scalability/-/issues/2864#note_1787040242)
- **Model Validation**: group within the AI-powered Stage working on the Prompt
  Library, supporting AI Validation of GitLab Duo features, and researching AI/ML models to support other use-cases for AI at GitLab.
  [Team handbook section](https://handbook.gitlab.com/handbook/product/categories/features/index.html#ai-powered-ai-model-validation-group)
- **Offline Model**: A model that runs without internet or intranet connection (for example, you are running a model on your laptop on a plane).
- **Open Source Model**: Models that are published with their source code and weights and are available for modifications and re-distribution. Examples: Llama / Llama 2, BLOOM, Falcon, Mistral, Gemma.
- **Prompt library**: The ["Prompt Library"](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/prompt-library) is a Python library that provides a CLI for testing different prompting techniques with LLMs. It enables data-driven improvements to LLM applications by facilitating hypothesis testing. Key features include the ability to manage and run dataflow pipelines using Apache Beam, and the execution of multiple evaluation experiments in a single pipeline run.
  on prompts with various third-party AI Services.
  [Code](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/prompt-library).
- **Prompt Registry**: stored, versioned prompts used to interact with third-party
  AI Services. [Design document proposal MR (closed)](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/135872).
- **Prompt**: Natural language instructions sent to an LLM to perform certain tasks. [Prompt guidelines](prompts.md).
- **RAG (Retrieval Augmented Generation)**: RAG provide contextual data to an LLM as part of a query to personalise results. RAG is used to inject additional context into a prompt to decrease hallucinations and improve the quality of outputs.
- **RAG Pipeline**: A mechanism used to take
  an input (such as a user question) into a system, retrieve any relevant data
  for that input, augment the input with additional context, and then
  synthesize the information to generate a coherent, contextualy-relevant answer.
  This design pattern is helpful in open-domain question answering with LLMs,
  which is why we use this design pattern for answering questions to GitLab Duo Chat.
- **Self-hosted model**: A LLM hosted externally to GitLab by an organisation and interacting with GitLab AI features.
- **Similarity Score**: A mathematical method to determine the likeness between answers produced by an LLM and the reference ground truth answers.
  See also the [Model Validation direction page](https://about.gitlab.com/direction/ai-powered/ai_model_validation/ai_evaluation/metrics/#similarity-scores)
- **Tool**: logic that performs a specific LLM-related task; each tool has a
  description and its own prompt. [How to add a new tool](duo_chat.md#adding-a-new-tool).
 **Unit Primitive**: GitLab-specific term that refers to the fundamental logical feature that a permission or access scope can control. Examples: [`duo_chat`](../../user/gitlab_duo_chat.md)  and [`code_suggestions`](../../api/code_suggestions.md). These features are both currently part of the GitLab Duo Pro license but we are building the concept of a Unit Primitive around each Duo feature so that Duo features are easily composable into different groupings to accommodate potential future product packaging needs.
- **Word-Level Metrics**: method for LLM evaluation that compares aspects of
  text at the granularity of individual words.
  [Issue from Model Validation team](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/prompt-library/-/issues/98#metric-3-word-level-metrics).
- **Zero-shot agent**: in the general world of AI, a learning model or system
  that can perform tasks without having seen any examples of that task during
  training. At GitLab, we use this term to refer specifically to a piece of our
  code that serves as a sort of LLM-powered air traffic controller for GitLab Duo Chat.
  The GitLab zero-shot agent has a system prompt that explains how an LLM should
  interpret user input from GitLab Duo Chat as well as a list of tool descriptions.
  Using this information, the agent determines which tool to use to answer a
  user's question. The agent may decide that no tools are required and answer the
  question directly. If a tool is used, the answer from the tool is fed back to
  the zero-shot agent to evaluate if the answer is sufficient or if an additional
  tool must be used to answer the question.
  [Code](https://gitlab.com/gitlab-org/gitlab/-/blob/6b747cbd7c6a71145a8bfb8201db3c857b5aed6a/ee/lib/gitlab/llm/chain/agents/zero_shot/executor.rb). [Zero-shot agent in action](https://gitlab.com/gitlab-org/gitlab/-/issues/427979).

## Duo Workflow Terminology

- **Agent**: A general term for a software entity that performs tasks. Agents can range from simple, rule-based systems to complex AI-driven entities that learn and adapt over time. For our purposes, we typically use "Agent" to refer to an AI-driven entity.
- **Autonomous Agents**: Agents that operate independently without direct input or supervision from humans. They make decisions and perform actions based on their programming and the data they perceive from their environment. These often receive instructions from a Supervisor Agent.
- **Frameworks**: These are platforms or environments that support the development and operation of multi-agent systems. Frameworks provide the necessary infrastructure, tools, and libraries that developers can use to build, deploy, and manage agents. Langchain, for example, is a framework that facilitates building language-based agents integrated with different AI technologies.
- **General Agent or Generic Agent**: An agent capable of performing a variety of tasks, not limited to a specific domain or set of actions. This type of agent usually has broader capabilities and can adapt to a wide range of scenarios.
- **Hand-crafted Agents**: These are agents specifically designed by developers with tailored rules and behaviors to perform specific tasks. They are usually fine-tuned to operate within well-defined scenarios.
- **Multi-agent Workflows**: A system or process where multiple agents interact or collaborate to complete tasks or solve problems. Each agent in the workflow might have a specific role or expertise, contributing to a collective outcome.
- **Specialized Agents**: Agents designed to perform specific, often complex tasks where specialized knowledge or skills are required. These agents are usually highly effective within their domain of expertise but may not perform well outside of it.
- **Subagent**: A term used to describe an agent that operates under the supervision of another agent. Subagents typically handle specific tasks or components of a larger process within a multi-agent system.
- **Supervisor Agent**: An agent tasked with overseeing and coordinating the actions of other agents within a workflow. This type of agent ensures that tasks are assigned appropriately, and that the workflow progresses smoothly and efficiently.
- **Tool**: In the context of multi-agent workflows, a tool is a utility or application that agents can use to perform tasks. Tools are used to communicate with the outside world, and are an interface to something other than an LLM, like reading GitLab issues, cloning a repository, or reading documentation.
