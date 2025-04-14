---
stage: AI-powered
group: Duo Workflow
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLab Duo Workflow use cases
---

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com
- Status: Private beta

{{< /details >}}

{{< alert type="warning" >}}

This feature is [a private beta](../../policy/development_stages_support.md) and is not intended for customer usage outside of initial design partners. We expect major changes to this feature.

{{< /alert >}}

The following use case examples demonstrate some of the ways you might use GitLab Duo Workflow.

## Refactor existing code

Use this approach when you need to improve performance, readability, or maintainability of existing code.

### Analyze

Ask Workflow to analyze the current implementation.

- Request identification of complexity issues, performance bottlenecks, and readability concerns.
- Have Workflow suggest applicable design patterns.

Sample prompt:

```plaintext
Analyze the UserPermissions class in app/models/user_permissions.rb. Focus on:

1. Current methods and their complexity
2. Performance bottlenecks 
3. Areas where readability can be improved
4. Potential design patterns that could be applied

Provide a summary of your findings and suggestions for refactoring.
Reference any similar refactoring in our codebase if applicable (link existing files if any).
Document your analysis process.
```

### Plan

Then, request a structured refactoring proposal.

- Ask for clear documentation of proposed changes.
- Have Workflow outline potential risks and estimated effort.

Sample prompt:

```plaintext
Based on the analysis of UserPermissions, create a refactoring proposal:

1. Outline the new structure for UserPermissions
2. Suggest new method names and their purposes
3. Propose any new classes or modules if needed
4. Explain how this refactoring will improve performance and readability

Format the proposal as a GitLab issue template, including:

- Problem statement
- Proposed solution
- Potential risks
- Estimated effort
```

### Implement

Now, ask Workflow to create implementation files that follow your coding standards.

- Request detailed comments explaining the changes.
- Ask for test coverage of the new implementation.

Sample prompt:

```plaintext
Implement the refactoring of UserPermissions as proposed:

1. Create a new file app/models/user_permissions_refactored.rb
2. Implement the new UserPermissions class structure
3. Include detailed comments explaining the changes
4. Update one existing method in app/controllers/users_controller.rb to use the new UserPermissions class
5. Write RSpec tests for the new UserPermissions class in spec/models/user_permissions_spec.rb

Follow our Ruby style guide and best practices for testing.
Document any decisions made during implementation.
```

### Evaluate results

Finally, verify the changes work as expected through testing.

- If issues arise, provide specific feedback to guide improvement.
- Document performance gains or other improvements.

## Bootstrap a new project

Use this approach when you start a new application or service from scratch.

### Initialize the project

Request a project structure that follow best practices for your tech stack.

- Ask for recommended dependencies and configurations.
- Have Workflow generate initial documentation.

Sample prompt:

```plaintext
Initialize a new Ruby on Rails project for a team collaboration tool:

1. Generate a project structure following our best practices
2. Include recommended gems for development, testing, and production
3. Set up a basic CI/CD configuration
4. Create an initial README.md with project overview and setup instructions

Use our existing Rails projects as reference. Document your decisions and reasoning.
```

### Plan the feature

Now, ask Workflow to create feature definitions and user stories.

- Request technical approaches for each core feature.
- Have Workflow identify potential challenges.

Sample prompt:

```plaintext
Create an issue template for the core features of our team collaboration tool:

1. User authentication and authorization
2. Team creation and management
3. Task tracking and assignment
4. Real-time chat functionality
5. File sharing and version control

For each feature:

- Provide a brief description
- List key user stories
- Suggest potential technical approaches
- Identify any potential challenges or considerations

Format this as an epic with individual issues for each core feature.
```

### Set up a foundation

Now, ask Workflow to design initial data models and schemas.

- Request setup of testing frameworks and CI/CD configurations.
- Ask for implementation of authentication and core APIs.

Sample prompt:

```plaintext
Design an initial database schema for our team collaboration tool:

1. Create migrations for core models (User, Team, Task, Message, File)
2. Define associations between models
3. Include necessary indexes for performance
4. Add comments explaining design decisions

Use our database best practices and naming conventions.
Generate the migrations in db/migrate/ directory.
Provide a visual representation of the schema (for example, using Mermaid diagram syntax).
```

### Track progress

Finally, request a summary of implemented features.

- Ask for a prioritized list of remaining tasks.
- Have Workflow identify risks or challenges.

Sample prompt:

```plaintext
Create a progress report and next steps plan:

1. Summarize implemented features and their current status
2. Identify any deviations from the initial plan and explain reasons
3. List remaining tasks from the core features epic
4. Suggest a prioritized roadmap for the next development sprint
5. Identify any potential risks or challenges for upcoming work

Format this as an issue with appropriate labels and mentions.
Include relevant metrics (like test coverage and security scan results).
```

## Add a new feature

Use this approach to extend functionality in existing projects.

### Provision the context

First, specify the technology stack and relevant files.

- Clearly define the desired behavior and requirements.
- Point to similar implementations that can serve as reference.

Sample prompt:

```plaintext
In this project, let's add a new page for users to submit feedback.
The current implementation is in Vue and routes are served from a fastify HTTP server,
located at path/to/fastify/server.ts. The new route should be `/feedback` and serve
a new vue component called `feedback.vue`.

The feedback vue component should have 3 fields:

- User email as an input field
- A dropdown with 5 values to ask how they heard about us
- One textarea for the actual feedback

The dropdown field is optional. There should also be a submit button.
When the button is clicked, show a banner to tell users their feedback was sent.
```

### Request implementation

Now, ask for all necessary component parts (UI, logic, data models).

- Request test files for the new functionality.
- Specify expected output formats and integration points.

Sample prompt:

```plaintext
Please implement:

1. The new Vue component at src/components/feedback.vue
2. The route handling in the fastify server at path/to/fastify/server.ts
3. Any necessary backend API endpoints to handle the form submission
4. Unit tests for the Vue component and API endpoints

The implementation should follow our existing patterns for
form validation and API responses. Reference the contact form at
src/components/contact.vue for styling and error handling approaches.
```

### Review and refine

Finally, verify the implementation meets requirements.

- Check for adherence to code standards.
- Test the feature thoroughly.
