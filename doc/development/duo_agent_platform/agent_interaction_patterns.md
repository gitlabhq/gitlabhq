---
stage: AI-powered
group: Agent Foundations
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/development/development_processes/#development-guidelines-review.
title: Agent interaction patterns for developing on GitLab Duo Agent Platform
---
This guide establishes interaction patterns and rules for agents and flows within GitLab. These patterns ensure consistent, user-friendly behavior while managing infrastructure load and maintaining a high-quality user experience.

This guide targets GitLab-managed agents and flows. The patterns should also extend to custom agents created in the AI Catalog.

### Core User Experience Principles

1. Minimize notification noise: Agents should provide necessary updates without overwhelming users with notifications and comments.
1. Maintain transparency: Users should be able to track agent progress and understand what actions are being taken.
1. Respect infrastructure constraints: Agent behavior should be designed with scalability in mind, avoiding patterns that create excessive database load.
1. Enable human oversight: Users need clear entry points to review, approve, or intervene in agent work.

## Interaction Patterns

### Comment Management

#### Initial Comment on an Issue or MR: Create an Initial Comment

Behavior Pattern: When a flow or agent begins work on an issue or MR, create an initial comment to signal activity. 

- Makes agent activity visible to all collaborators on the item
- Provides a persistent record beyond the sessions UI
- Establishes a comment that can be updated with progress

Resources: 

- To do: add example template
- To do: add example how-to in the prompt
- To do: add screenshot (design)

#### Adding Updates While Session is In Progress: Work in the Same Comment

Behavior Pattern: While an agent is actively working on a task, it should update a single comment rather than creating multiple new comments.

- Reduces database load and notification spam
- Provides a clean, consolidated view of agent progress
- Prevents issues and MRs from becoming cluttered with AI-generated content

Resources: 

- To do: add example template
- To do: add example how-to in the prompt
- To do: add screenshot (design)

#### Adding Update When Flow is Complete or Review Needed: Add a New Comment

Behavior Pattern: When an agent completes its work or requires human review and follow-up actions, create a new comment with a summary and next steps, and @mention the relevant user.

- New comments with @mentions create to-dos or emails for users, engaging them on their familiar notification pattern
- Signals a clear transition from "agent working" to "human action required"
- Ensures important milestones don't get lost in updated content

Resources: 

- To do: add example template
- To do: add example how-to in the prompt
- To do: add screenshot (design)

#### When Flow Is Completed: Always Provide a Final Summary

Behavior Pattern: When a flow completes (successfully or with errors), always post a summary comment to the work item.

Resources: 

- To do: add example template for success and failure
- To do: add example how-to in the prompt
- To do: add screenshot (design) for success and failure

### Mentioning Users

Behavior Pattern: Agents use @mentions the way a human would: to communicate important information to team members who they are collaborating with, while taking care not to create unnecessary noise for others.

- @mention the user who triggered the flow in the initial comment
- @mention users who need to respond when requesting review or approval
- Avoid @mentioning in progress updates

Rationale:

- Ensures the triggering user is aware the agent has started
- Creates to-dos only when human action is needed
- Prevents notification fatigue from progress updates

## Using the Session Tab in the AI Panel

Behavior Pattern: Agents should rely on the Sessions section for logging detailed, real-time progress tracking, while using comments for milestone notifications and summaries. Users shouldn't have to go into the Sessions tab for all of their flows. They will use the Sessions tab for troubleshooting and other deeper analysis activities, as well as for managing Sessions asynchronously when they are no longer on the work item or MR related to the Session.

Content to Show In Sessions tab:

- Detailed step-by-step progress
- Tool invocations and responses
- Reasoning and decision-making process
- Real-time status updates

Content to Show In Work Item and MR Comments:

- Agent started working
- Major milestone updates (if needed)
- Follow-up requests needing human intervention
- Final summary

## Summary of Best Practices

### For Development

- Use comment IDs: Store the initial comment ID and update it rather than creating new comments
- Timestamp updates: Always include timestamps in progress updates
- Clear state transitions: Make it obvious when transitioning from "working" to "review needed"
- Graceful failures: Always post a summary comment even when errors occur
- Link to sessions: Include links to the full session details for users who want more information

### For Prompt Engineering

This is an example on how this could look like in a single agent's prompt:

```plaintext
COMMENT BEHAVIOR:
* Create ONE initial status comment when you start
* Update that same comment with your progress
* Create a NEW comment when you complete or need review
* Always @mention users in completion/review comments
* Never @mention users in progress updates

FINAL SUMMARY:
* Always post a final summary when done
* Include what you did, results, and next steps
* Link to the full session details
```

### For Infrastructure Considerations

These patterns help manage load by:

- Updating vs. creating: Reduces database writes and notification volume
- Consolidated status: One comment per active session vs. many
- Selective @mentions: Reduces to-do item creation to meaningful moments
- Session UI for details: Keeps detailed logs out of the primary work item

### Other Considerations

As the Agent Platform evolves, we may need to address:

- Collapsible progress: UI patterns for hiding detailed progress while preserving summaries
- Multi-agent coordination: How agents should communicate when multiple agents work on the same item
- User preferences: Allowing users to customize notification levels
- Enhanced session links: Making session details more discoverable from comments
- And many more things we may not have thought of yet.

If you need help extending these patterns or introducing new ones, you should reach out to the Product Design team and the Agent Foundations team, so that you can design a new pattern together and add it into this document for future use.
