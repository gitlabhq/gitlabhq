---
stage: AI-powered
group: AI Framework
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/development/development_processes/#development-guidelines-review.
title: Prompt Engineering Guide
---

This guide outlines the key aspects of prompt engineering when working with Large Language Models (LLMs),
including prompt design, optimization, evaluation, and monitoring.

## Understanding prompt engineering

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>
For an overview, see [this video](https://youtu.be/bOA6BtBaMTQ).

Most important takeaways:

- **Definition of a prompt:**
  - An instruction sent to a language model to solve a task
  - Forms the core of AI features in user interfaces

- **Importance of prompt quality:**
  - Greatly influences the quality of the language model's response
  - Iterating on prompts is crucial for optimal results

- **Key considerations when crafting prompts:**
  - Understand the task you're asking the model to perform
  - Know what kind of response you're expecting
  - Prepare a dataset to test the prompts
  - Be specific - provide lots of details and context to help the AI understand
  - Give examples of potential questions and desired answers

- **Prompt universality:**
  - Prompts are not universal across different language models
  - When changing models, prompts need to be adjusted
  - Consult the language model provider's documentation for specific tips
  - Test new models before fully switching

- **Tools for working with prompts:**
  - Anthropic Console: A platform for writing and testing prompts
  - Generator Prompt: A tool that creates crafted prompts based on task descriptions

- **Prompt structure:**
  - Typically includes a general task description
  - Contains placeholders for input text
  - May include specific instructions and suggested output formats
  - Consider wrapping inputs in XML tags for better understanding and data extraction

- **System prompts:**
  - Set the general tone and role for the AI
  - Can improve the model's performance
  - Usually placed at the beginning of the prompt
  - Set the role for the language model

- **Best practices:**
  - Invest time in understanding the assignment
  - Use prompt generation tools as a starting point
  - Test and iterate on prompts to improve results
  - Use proper English grammar and syntax to help the AI understand
  - Allow uncertainty - tell the AI to say "I don't know" if it is unsure
  - Use positive phrasing - say what the AI should do, not what it shouldn't do

### Best practices for writing effective prompts

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>
For an overview, see [this video about writing effective prompts](https://youtu.be/xL-zj-Z4Mh4).

Here are the key takeaways from this video:

- **No universal "good" prompt:**
  - The effectiveness of a prompt depends on the specific task.
  - There's no one-size-fits-all approach to prompt writing.

- **Characteristics of effective prompts:**
  - Clear and explanatory of the task and expected outcomes.
  - Direct and detailed.
  - Specific about the desired output.

- **Key elements to consider:**
  - Understand the task, audience, and end goal.
  - Explain these elements clearly in the prompt.

- **Strategies for improving prompt performance:**
  - Add instructions in sequential steps.
  - Include relevant examples.
  - Ask the model to think in steps (chain of thought).
  - Request reasoning before providing answers.
  - Guide the input - use delimiters to clearly indicate where the user's input starts and ends.

- **Adapting to model preferences:**
  - Adjust prompts to suit the preferred data structure of the model.
  - For example, Anthropic models work well with XML tags.

- **Importance of system prompts:**
  - Set the role for the language model.
  - Placed at the beginning of the interaction.
  - Can include awareness of tools or long context.

- **Iteration is crucial:**
  - Emphasized as the most important part of working with prompts.
  - Continual refinement leads to better results.
  - Build quality control - automate testing prompts with RSpec or Rake tasks to catch differences.

- **Use traditional code:**
  - If a task can be done efficiently outside of calling an LLM, use code for more reliable and deterministic outputs.

## Tuning and optimizing workflows for prompts

### Prompt tuning for LLMs using LangSmith and Anthropic Workbench together + CEF

#### Iterating on the prompt using Anthropic console

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>
For an overview, see [this video](https://youtu.be/03nOKxr8BS4).

#### Iterating on the prompt using LangSmith

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>
For an overview, see [this video](https://youtu.be/9WXT0licAdg).

#### Using Datasets for prompt tuning with LangSmith

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>
For an overview, see [this video](https://www.youtube.com/watch?v=kUnm0c2LMlQ).

#### Using automated evaluation in LangSmith

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>
For an overview, see [this video](https://youtu.be/MT6SK4y47Zw).

#### Using pairwise experiments in LangSmith

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>
For an overview, see [this video](https://youtu.be/mhpY7ddjXqc).

[View the CEF documentation](https://gitlab.com/gitlab-org/modelops/ai-model-validation-and-research/ai-evaluation/prompt-library/-/blob/main/doc/running_evaluation_locally/pairwise_evaluation.md).

#### When to use LangSmith and when CEF

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>
For an overview, see [this video](https://youtu.be/-DK-XFFllwg).

##### Key Points on CEF (Centralized Evaluation Framework) Project

1. Initial Development
   - Start with pure LangSmith for prompt iteration
   - Easier and quicker to set up
   - More cost-effective for early stages

1. When to Transition to CEF
   - When investing more in the feature
   - For working with larger datasets
   - For repeated, long-term use

1. CEF Setup Considerations
   - Requires upfront time investment
   - Need to adjust evaluations for specific features
   - Set up input data (for example, local GDK for chat features)

1. Challenges
   - Ensuring consistent data across different users
   - Exploring options like seats and imports for data sharing

1. Current CEF Capabilities
   - Supports chat questions about code
   - Handles documentation-related queries
   - Includes evaluations for code suggestions

1. Advantages of CEF
   - Allows running evaluations on local GDK
   - Results viewable in LangSmith UI
   - Enables use of larger datasets

1. Flexibility
   - Requires customization for specific use cases
   - Not a one-size-fits-all solution

1. Documentation
   - CEF has extensive documentation available.

1. Adoption
   - Already in use by some teams, including code suggestions and create teams

## Further resources

For more comprehensive prompt engineering guides, see:

- [Prompt Engineering Guide 1](https://www.promptingguide.ai/)
- [Prompt Engineering Guide 2](https://www.deeplearning.ai/short-courses/chatgpt-prompt-engineering-for-developers/)
