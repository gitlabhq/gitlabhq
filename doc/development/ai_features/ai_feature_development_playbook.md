---
stage: AI-powered
group: AI Framework
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: AI feature development playbook
---

This playbook outlines the key aspects of working with Large Language Models (LLMs),
prompts, data, evaluation, and system architecture.
It serves as a playbook for AI feature development and operational considerations.

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
  - The effectiveness of a prompt depends on the specific task
  - There's no one-size-fits-all approach to prompt writing

- **Characteristics of effective prompts:**
  - Clear and explanatory of the task and expected outcomes
  - Direct and detailed
  - Specific about the desired output

- **Key elements to consider:**
  - Understand the task, audience, and end goal
  - Explain these elements clearly in the prompt

- **Strategies for improving prompt performance:**
  - Add instructions in sequential steps
  - Include relevant examples
  - Ask the model to think in steps (chain of thought)
  - Request reasoning before providing answers
  - Guide the input - use delimiters to clearly indicate where the user's input starts and ends

- **Adapting to model preferences:**
  - Adjust prompts to suit the preferred data structure of the model
  - For example, Anthropic models work well with XML tags

- **Importance of system prompts:**
  - Set the role for the language model
  - Placed at the beginning of the interaction
  - Can include awareness of tools or long context

- **Iteration is crucial:**
  - Emphasized as the most important part of working with prompts
  - Continual refinement leads to better results
  - Build quality control - automate testing prompts with RSpec or Rake tasks to catch differences

- **Use traditional code:**
  - If a task can be done efficiently outside of calling an LLM, use code for more reliable and deterministic outputs

## Tuning and optimizing workflows for prompts

### Prompt tuning for LLMs using Langsmith and Anthropic Workbench together + CEF

#### Iterating on the prompt using Anthropic console

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>
For an overview, see [this video](https://youtu.be/03nOKxr8BS4).

#### Iterating on the prompt using Langsmith

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>
For an overview, see [this video](https://youtu.be/9WXT0licAdg).

#### Using Datasets for prompt tuning with Langsmith

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>
For an overview, see [this video](https://www.youtube.com/watch?v=kUnm0c2LMlQ).

#### Using automated evaluation in Langsmith

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>
For an overview, see [this video](https://youtu.be/MT6SK4y47Zw).

#### Using pairwise experiments in Langsmith

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>
For an overview, see [this video](https://youtu.be/mhpY7ddjXqc).

[View the ELI5 documentation](https://gitlab.com/gitlab-org/ai-powered/eli5/-/blob/main/doc/running_evaluation_locally/pairwise_evaluation.md).

#### When to use Langsmith and when ELI5

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>
For an overview, see [this video](https://youtu.be/-DK-XFFllwg).

##### Key Points on ELI5 (Eval like I'm 5) Project

1. Initial Development
   - Start with pure Langsmith for prompt iteration
   - Easier and quicker to set up
   - More cost-effective for early stages

1. When to Transition to ELI5
   - When investing more in the feature
   - For working with larger datasets
   - For repeated, long-term use

1. ELI5 Setup Considerations
   - Requires upfront time investment
   - Need to adjust evaluations for specific features
   - Set up input data (e.g., local GDK for chat features)

1. Challenges
   - Ensuring consistent data across different users
   - Exploring options like seats and imports for data sharing

1. Current ELI5 Capabilities
   - Supports chat questions about code
   - Handles documentation-related queries
   - Includes evaluations for code suggestions

1. Advantages of ELI5
   - Allows running evaluations on local GDK
   - Results viewable in Langsmith UI
   - Enables use of larger datasets

1. Flexibility
   - Requires customization for specific use cases
   - Not a one-size-fits-all solution

1. Documentation
   - ELI5 has extensive documentation available

1. Adoption
   - Already in use by some teams, including code suggestions and create teams

## Evaluation & Monitoring

### Building Datasets for Eval

#### Why Do I Need A Dataset?

A dataset in its most simple form as a bunch of inputs with roughly expected outputs. Now there are cases (such as chat applications) where having a defined expected output is impossible, in which case a dataset is still very useful but the evaluation technique would change. For now as we are all more or less comfortable with the idea of testing code, let's keep it simple and work with datasets that have expected outputs.

Once we decide to start making an application, thinking about ways in which it could break and ways in which it should succeed is paramount. Having those potential input and their expected outputs collected in a dataset that we can run through our application is highly useful in both early and late development.

Once we have developed our application being able to assure that it behaves as expected across a broad range of inputs is paramount. It is preferable to have as broad a range of prompts as we can achieve within reason. When we want to make a change to our prompt, tool selection, or choose a new model being able to compare how successful our changes are requires a dataset to evaluate against that possesses a large number of inputs paired with expected outputs.

#### Key Considerations When Making a Dataset

When first starting out building applications on top of LLMs we will want to do evaluation. A common first question to ask is how many records should we have in our dataset. This question is a little premature for reasons that should be clear soon.

First things first, before thinking about how much data, lets think about how representative our data needs to be of the problem your app needs to solve and where we can get that.

As an example where we are constantly iterating on this at GitLab, let's consider the evaluation of our code completion offering. What we use in practice for evaluation is a dataset made up of functions taken from GitLab codebase that have been split in half. The first half is the prompt (input) the second half is the part we will compare to what the model produces (expected output).

As said we evaluate our code completion application with a dataset that was created from GitLab code, this means a lot of Ruby, Go, Python, and several other languages. Let's remember many of our customers write their code in Java. At this point a worth while question to ask is, would you characterise our dataset as representative? Honestly, in the beginning probably not. There are times where we must accept in the beginning that the best we can do is the best we can do, but keeping this in mind and trying to improve the alignment between what we evaluate against and what our application is the best thing to focus on when creating / improving a dataset. As part of this dataset creation / improvement effort we also want to keep a diverse spread of types of prompts. Following our code
completion example, as mentioned before we probalby want to have more Java prompts but we don't just want leet-code style interview questions. We also want examples that would be in enterprise backend applications, android applications, gradle plugins, yes even some basic interview questions, and any more diverse places where Java would be used.

Now that we have thought about having representative data, let's think about how many datapoints we need. In evaluation we are trying to make an assessment of how well our application is doing. If you could imagine flipping a coin that may be unfair, flipping it 10 times wouldn't give you a lot of confidence but flipping it 10,000 times probably would. That said similarly to how flipping a coin 10,000 times would take a while to do, running 10,000 prompts would take longer than running about a 100 or so. In the early stages of development we would want to balance iteration speed and accuracy, and to that end we recommend 70 to 120 prompts, but if you can add more without compromising your iteration time this is strongly encouraged. As you move toward an internal beta and definitely as you
move toward general availability, we recommend running evaluation with several thousand prompts.

#### What is an output, ground truth, or expected answer?

**Output**: The result of sending a message to your chosen LLM. If I ask "In *The Hitchhiker's Guide to the Galaxy* what is the number that was the meaning of life?" the output could be something like "In *The Hitchhiker's Guide to the Galaxy*, the number that represents the meaning of life is **42**".

**Ground Truth** or **Expected Result**: The examples from our real would situation that we know to be true. Let's imagine we are trying to predict housing prices and we have a bunch of validation data that we pulled from a realtor listing sight. This data contains information about the house, and how much the houses cost. That data could be called our ground truth.

### Using CEF dashboard and troubleshooting

### Using automated evaluation pipelines for CEF

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>
For an overview of using promptlib in a Docker container, see [this video](https://www.youtube.com/watch?v=ZGKXQYZTBFg).

### Continuous monitoring and applying as guidance for Prompt Tuning

### A/B testing strategies for Gen AI features

## Further resources

For more comprehensive prompt engineering guides, see:

- [Prompt Engineering Guide 1](https://www.promptingguide.ai/)
- [Prompt Engineering Guide 2](https://www.deeplearning.ai/short-courses/chatgpt-prompt-engineering-for-developers/)
