---
stage: AI-powered
group: AI Framework
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
---

# Working with AI prompts

This documentation provides some tips and guidelines for working with AI prompts, particularly aimed at GitLab engineers. The tips are:

1. Set the tone - Describe how the AI assistant should respond, e.g. "You're a helpful assistant specialized in DevSecOps". Giving context helps the AI provide better answers. This establishes expectations for how the AI should communicate.
1. Be specific - When describing a task, provide lots of details and context to help the AI understand. Give as much specific information as possible. For example, don't just say "summarize this text", provide context like "You are an AI assistant named GitLab Duo. Please read the following text and summarize it in 3 concise sentences focusing on the key points." The more details you provide, the better the AI will perform.
1. Give examples - Provide examples of potential questions and desired answers. This helps the AI give better responses. For instance, you can provide a sample question like "What is the main idea of this text?" and then give the ideal concise summary as an example response. Always give the instructions first, and then provide illustrative examples.
1. Guide the input - Use delimiters to clearly indicate where the user's input starts and ends. The AI needs to know what is input. Make it obvious to the model what text is the user input.
1. Consider wrapping your inputs (context) to LLMs in XML tags, because many LLMs were trained on XML data and can understand it better. This also helps to take advantage if needed in extracting data more easily, or help with stop sequencing.
1. Step-by-step reasoning - Ask the AI to explain its reasoning step-by-step. This produces more accurate results. You can get better responses by explicitly asking the model to think through its reasoning step-by-step and show the full explanation. Say something like "Please explain your reasoning step-by-step for how you arrived at your summary:"
1. Allow uncertainty - Tell the AI to say "I don't know" if it is unsure, to avoid hallucinating answers. Give the model an explicit way out if it does not know the answer to avoid false responses. Say "If you do not know the answer, please respond with 'I don't know'".
1. Use positive phrasing - Say what the AI should do, not what it shouldn't do, even when prohibiting actions. Although tricky, use positive language as much as possible, even when restricting behavior. For example, say "Please provide helpful, honest responses" rather than "Do not provide harmful or dishonest responses".
1. Correct language - Use proper English grammar, more bite-sized/non-academic language, and syntax to help the AI understand the language. Having technically accurate language and grammar will enable the model to better comprehend the prompt. This is why working with technical writers is very helpful for crafting prompts.
1. Test different models - Prompts are provider specific. Test new models before fully switching. It's important to recognize prompts do not work equally across different AI providers. Make sure to test performance carefully when changing to a new model, don't assume it will work the same.
1. Build quality control - Automate testing prompts with RSpec or Rake task to catch differences. Develop automated checks to regularly test prompts and catch regressions. Use frameworks like RSpec or Rake tasks to build test cases with sample inputs and desired outputs.
1. Iterate - Refine prompts gradually, testing changes to see their impact. Treat prompt engineering as an iterative process. Make small changes, then test results before continuing. Build up prompts incrementally while continually evaluating effects.
1. Use traditional code - if a task can be done in code outside of calling an LLM, for example with pre- or post- processing, then it is more reliable and efficient for code to create a deterministic output as opposed to iterating on your prompt until it is closer to a deterministic answer. As an example, if the data returned from an LLM can be parsed to JSON through code, it is more reliable to convert it with code as opposed to working on your prompt until it outputs in proper JSON reliably.

## Further Resources

For more comprehensive prompt engineering guides, see:

- [Prompt Engineering Guide 1](https://www.promptingguide.ai/)
- [Prompt Engineering Guide 2](https://www.deeplearning.ai/short-courses/chatgpt-prompt-engineering-for-developers/)
