---
stage: AI-powered
group: AI Framework
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# GitLab Duo Glossary

This is a list of terms that may have a general meaning but also may have a
specific meaning at GitLab. If you encounter a piece of technical jargon related
to AI that you think could benefit from being in this list, add it!

- **AI Gateway**: standalone service used to give access to AI features to
  non-SaaS GitLab users. This logic will be moved to Cloud Connector when that
  service is ready. Eventually, the AI Gateway will be used to host endpoints that
  proxy requests to AI providers, removing the need for the GitLab Rails monolith
  to integrate and communicate directly with third-party LLMs.
  [Blueprint](../../architecture/blueprints/ai_gateway/index.md).
- **Chat Evaluation**: automated mechanism for determining the helpfulness and
  accuracy of GitLab Duo Chat to various user questions. The MVC is an RSpec test
  run via GitLab CI that asks a set of questions to Chat and then has a
  two different third-party LLMs determine if the generated answer is accurate or not.
  [MVC](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/134610).
  [Design doc for next iteration](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/136127).
- **Cloud Connector**: Today, Cloud Connector is not a system. It is an umbrella
  term for all the projects we engage in that make existing SaaS-only features
  available to self-managed and GitLab Dedicated customers. Today, the only
  feature available through Cloud Connector is Code Suggestions.
  Cloud Connector also refer to a planned GitLab-hosted edge service which would
  act as a way for non-SaaS GitLab instances to access SaaS offerings.
  [Cloud Connector MVC](../cloud_connector/code_suggestions_for_sm.md).
  [Blueprint for future Cloud Connector service](../../architecture/blueprints/cloud_connector/index.md).
- **Consensus Filtering**: method for LLM evaluation where you instruct an LLM
  to evaluate the output of another LLM based on the question and context that
  resulted in the output. This is the method of evaluation being used for the Chat
  Evaluation MVC.
  [Issue from Model Validation team](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/prompt-library/-/issues/91#metric-2-consensus-filtering-with-llm-based-evaluation).
- **Context**: relevant information that surrounds a data point, an event, or a
  piece of information, which helps to clarify its meaning and implications.
  For GitLab Duo Chat, context is the attributes of the Issue or Epic being
  referenced in a user question.
- **Golden Questions**: a small subset of the types of questions we think a user
  should be able to ask GitLab Duo Chat. Used to generate data for Chat evaluation.
  [Questions for Chat Beta](https://gitlab.com/groups/gitlab-org/-/epics/10550#what-the-user-can-ask).
- **Ground Truth**: data that is determined to be the true
  output for a given input, representing the reality that the AI model aims to
  learn and predict. Ground truth data is usually human-annotated.
- **Model Validation**: group within the AI-powered Stage working on the Prompt
  Library and researching AI/ML models to support other use-cases for AI at GitLab.
  [Team handbook section](https://about.gitlab.com/handbook/product/categories/features/#ai-poweredai-model-validation-group).
- **Prompt library**: The ["Prompt Library"](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/prompt-library) is a Python library that provides a CLI for testing different prompting techniques with LLMs. It enables data-driven improvements to LLM applications by facilitating hypothesis testing. Key features include the ability to manage and run dataflow pipelines using Apache Beam, and the execution of multiple evaluation experiments in a single pipeline run.
  on prompts with various third-party AI Services.
  [Code](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/prompt-library).
- **Prompt Registry**: stored, versioned prompts used to interact with third-party
  AI Services. [Blueprint](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/135872).
- **Prompt**: instructions sent to an LLM to perform certain tasks. [Prompt guidelines](prompts.md).
- **RAG Pipeline**: (Retrieval-Augmented Generation) is a mechanism used to take
  an input (such as a user question) into a system, retrieve any relevant data
  for that input, augment the input with additional context, and then
  synthesize the information to generate a coherent, contextualy-relevant answer.
  This design pattern is helpful in open-domain question answering with LLMs,
  which is why we use this design pattern for answering questions to GitLab Duo Chat.
- **Similarity Score**: method to determine the likeness between answers produced by an LLM and the reference ground truth answers.
  [Issue from Model Validation team](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/prompt-library/-/issues/91#metric-1-similarity-score-as-comparisons-for-llms).
- **Tool**: logic that performs a specific LLM-related task; each tool has a
  description and its own prompt. [How to add a new tool](duo_chat.md#adding-a-new-tool).
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
