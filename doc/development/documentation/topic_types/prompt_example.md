---
stage: none
group: Documentation Guidelines
info: For assistance with this Style Guide page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments-to-other-projects-and-subjects.
title: Prompt example page type
---

A prompt example provides step-by-step instructions for using GitLab Duo to accomplish a specific development or business task.

A prompt example should answer the questions:

- What development challenge does this solve?
- How do you use GitLab Duo to solve it?

These pages should be precise and easy to scan. They do not replace
other documentation types on the site, but instead complement them.
They should not be full of links or related conceptual or task information.

## Format

Prompt examples should be in this format:

````markdown
title: Title (active verb + object, like "Refactor legacy code")
---

One-sentence description of when to use this approach.

- Time estimate: X-Y minutes
- Level: Beginner/Intermediate/Advanced
- Prerequisites: What users need before starting

(To populate these items, see the guidance that follows this example.)

## The challenge

1-2 sentence description of the specific problem this solves.

## The approach

Brief description of the overall strategy and which GitLab Duo tools to use (usually 2-4 key phrases).

### Step 1: [Action verb]

[Specify which GitLab Duo tool to use] Brief description of what this step accomplishes.

```plaintext
Prompt template with placeholders in [brackets]
```

Expected outcome: What should happen when this prompt is used.

### Step 2: [Action verb]

[Specify which GitLab Duo tool to use] Brief description of what this step accomplishes.

```plaintext
Next prompt template with placeholders in [brackets]
```

Expected outcome: What should happen when this prompt is used.

## Tips

- Specific actionable advice for better results
- Common pitfalls to avoid
- How to iterate if first attempt doesn't work

## Verify

Ensure that:

- Quality check 1 - specific and measurable
- Quality check 2 - specific and measurable
- Quality check 3 - specific and measurable
````

## Prompt example topic titles

For the title text, use the structure `active verb` + `noun`.
For example:

- `Refactor legacy code`
- `Debug failing tests`
- `Generate API documentation`

### Titles to avoid

Avoid these topic titles:

- `How to [do something]`. Instead, use the active verb structure.
- `Using GitLab Duo for [task]`. Instead, focus on the task itself.
- `Tips and tricks`. Instead, incorporate advice into specific examples.
- Generic titles like `Code generation` when you mean something specific like `Generate REST API endpoints`.

## Level guidelines

Use these guidelines to assign difficulty levels:

- **Beginner**: Copy-paste prompts with minimal customization needed. Users follow exact steps.
- **Intermediate**: Template prompts that require adaptation. Users need to understand context and modify placeholders.
- **Advanced**: Complex multi-step workflows requiring prompt iteration and refinement. Users create custom approaches.

## Prerequisites format

Be specific about which GitLab Duo tools are needed. Common prerequisites include:

- Code file open in IDE, GitLab Duo Chat available
- Development environment set up, project requirements defined
- Existing codebase with [specific technology or framework]
- At least the Developer role for the project
- GitLab Duo Code Suggestions enabled (if using auto-completion features)

## Time estimates

Provide realistic time ranges based on complexity:

- **Simple tasks**: 5-15 minutes
- **Moderate tasks**: 15-30 minutes
- **Complex tasks**: 30-60 minutes
- **Multi-session work**: 1-2 hours (split across sessions)

## Expected outcomes format

Expected outcomes should be specific and measurable. For example:

- Do: `Detailed analysis identifying 3-5 specific improvement areas with code examples`
- Do not: `Analysis of the code`

- Do: `Complete refactored class with improved method names and added tests`
- Do not: `Better code`

## Prompt template guidelines

### Placeholder format

Always use `[descriptive_name]` format for placeholders. Make placeholders specific:

- Do: `[ClassName]` or `[file_path]` or `[specific_framework]`
- Do not: `[name]` or `[thing]` or `[item]`

### Template structure

Structure prompts with:

1. **Clear instruction**: What you want GitLab Duo to do
1. **Specific context**: What to focus on or reference
1. **Expected format**: How to structure the response
1. **Success criteria**: What good output looks like

## Tips guidelines

Tips should provide:

- **Practical advice**: Techniques that improve results
- **Common pitfalls**: Mistakes to avoid based on user experience
- **Iteration strategies**: How to refine prompts that don't work initially
- **Context tips**: How to provide better information to GitLab Duo
- **Tool combination tips**: How to use Chat and Code Suggestions together effectively

Avoid generic advice. Be specific about what works for this particular use case.

## Verification checklist

Create 3-5 specific, measurable checks that users can perform to validate success. Focus on:

- **Quality indicators**: Does the output meet standards?
- **Functionality checks**: Does the solution work as intended?
- **Completeness validation**: Are all requirements addressed?
- **Integration verification**: Does it work with existing code/systems?

## Example

### Before

The following topic tried to cover too many different scenarios in one example. It was unclear when to use each approach and the prompts were too generic.

```markdown
title: Using GitLab Duo for Development Tasks
---

You can use GitLab Duo to help with coding. Here are some ways:

- Generate code
- Fix bugs
- Write tests
- Refactor code

Ask GitLab Duo to help you with your task.
```

### After

The information is clearer when split into a focused prompt example:

````markdown
title: Refactor legacy code
---

Follow these guidelines when you need to improve performance, readability,
or maintainability of existing code.

- Time estimate: 15-30 minutes
- Level: Intermediate
- Prerequisites: Code file open in IDE, GitLab Duo Chat available

## The challenge

Transform complex, hard-to-maintain code into clean, testable components
without breaking functionality.

## The approach

Analyze, plan, and implement using GitLab Duo Chat and Code Suggestions.

### Step 1: Analyze

Use GitLab Duo Chat to understand the current state. Select the code you want to refactor, then ask:

```plaintext
Analyze the [ClassName] in [file_path]. Focus on:
1. Current methods and their complexity
2. Performance bottlenecks
3. Areas where readability can be improved
4. Potential design patterns that could be applied

Provide specific examples from the code and suggest applicable refactoring patterns.
```

Expected outcome: Detailed analysis with specific improvement suggestions.

## Tips

- Start with analysis before jumping to implementation.
- Select specific code sections when asking Chat for analysis.
- Ask Chat for specific examples from your actual code.
- Reference your existing codebase patterns for consistency.
- Let Code Suggestions help with syntax as you implement Chat's recommendations.

## Verify

Ensure that:

- Generated code follows your team's style guide.
- New structure actually improves the identified issues.
- Tests cover the refactored functionality.
````
