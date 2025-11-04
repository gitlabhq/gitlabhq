---
stage: Plan
group: Knowledge
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Use wiki with your planning workflow
description: Use GitLab Wiki with your planning workflow. Connect documentation to epics, issues, and boards.
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

GitLab Wiki works with your planning tools. It's not a separate tool.
You can link wiki pages to epics, issues, and boards.
With embedded views powered by GitLab Query Language (GLQL), your wiki pages can display
live, auto-updating views of issues and work items - turning documentation into dynamic dashboards.
Learn how to connect wiki with issues, epics, and boards to create a smooth workflow where
documentation and planning work together.

A wiki helps your planning tools by giving you:

- Rich documentation space: Complex requirements, design decisions, and process documentation that don't fit in issue descriptions.
- Version-controlled knowledge: Track changes to specifications and decisions over time.
- Live data views: Embed GLQL queries to display real-time issue and work item data directly in wiki pages.
- Lasting context: Keep the "why" behind decisions after issues are closed.
- Central reference: Single source of truth for team processes, standards, and agreements.
- Flexible formatting: Tables, diagrams, and long-form content with full Markdown support.
- Integrated access control: Wikis use the existing roles and permissions system in GitLab, so team members automatically have appropriate wiki access based on their project roles without separate authentication.

## Prerequisites

To use this guide effectively, you should be familiar with:

- [GitLab Wiki basics](_index.md)
- [GitLab Flavored Markdown](../../markdown.md)
- Creating and managing various work items, such as [issues](../issues/_index.md) and [epics](../../group/epics/_index.md)

## Connect wiki pages to work items

Create links between wiki documentation and your planning items to build a connected knowledge network.

### Link wiki documentation to epics

Epics often need detailed specifications that are too long for an epic description.
Keep the full documentation in a wiki:

1. On the left sidebar, select **Search or go to** and find your project. If you've [turned on the new navigation](../../interface_redesign.md#turn-new-navigation-on-or-off), this field is on the top bar.
1. Select **Plan** > **Wiki**.
1. Create a wiki page with your detailed requirements (for example, with slug `product-requirements`).
1. On the left sidebar, select **Search or go to** and find your project's group. If you've [turned on the new navigation](../../interface_redesign.md#turn-new-navigation-on-or-off), this field is on the top bar.
1. Select **Plan** > **Epics** and find your epic.
1. In the epic description, link to the wiki page:

   ```markdown
   ## Requirements

   See full specification: [[product-requirements]]

   Or with custom text: [[Full PRD|product-requirements]]

   Or use the full URL:
   [Full PRD](https://gitlab.example.com/group/project/-/wikis/product-requirements)
   ```

1. In the wiki page, link back to the epic:

   ```markdown
   Related epic: &123
   ```

Example use cases:

- Product requirement documents (PRDs)
- Technical design specifications
- User research findings
- Competitive analysis
- Success metrics and KPIs

### Reference wiki from issues

Link issues to wiki pages for implementation details, standards, and guides:

```markdown
## Implementation notes

Follow our [[API-design-standards]] when implementing this endpoint.

For local setup, see [[Development Setup Guide|development-environment-setup]].

Definition of Done: [[team-dod]]
```

Example use cases:

- Coding standards and style guides
- Development environment setup
- Testing procedures
- Deployment runbooks
- Troubleshooting guides
- Onboarding documentation

### Link from wiki to work items

Reference issues and epics directly in wiki pages:

```markdown
## Current sprint goals

- Implement user authentication: #1234
- Fix performance regression: #1235
- Update API documentation: #1236

## Q3 roadmap

Major initiatives:
- Authentication overhaul: &10
- Performance improvements: &11
- API v2 release: &12
```

### Cross-project wiki references

Link to wiki pages in other projects:

```markdown
## Related documentation

See the backend team's API guide: [[backend/api:api-standards]]

Or use the alternative syntax: [wiki_page:backend/api:api-standards]

With custom text: [[Backend API Standards|backend/api:api-standards]]
```

## Create dynamic dashboards with embedded views

{{< history >}}

- [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/14767) in GitLab 17.4 [with a flag](../../../administration/feature_flags/_index.md) named `glql_integration`. Disabled by default.
- Enabled on GitLab.com in GitLab 17.4 for a subset of groups and projects.
- [Changed](https://gitlab.com/gitlab-org/gitlab/-/issues/476990) from experiment to beta in GitLab 17.10.
- Enabled on GitLab.com, GitLab Self-Managed, and GitLab Dedicated in GitLab 17.10.
- [Generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/554870) in GitLab 18.3. Feature flag `glql_integration` removed.

{{< /history >}}

Transform your wiki pages into live dashboards using [GitLab Query Language](../../glql/_index.md) (GLQL).
Embedded views automatically update when data changes, providing real-time visibility into your planning data
without leaving the wiki.

<!-- Other types: flag, warning, disclaimer -->
{{< alert type="note" >}}

Embedded views have performance considerations. Large queries may time out or be rate-limited.
If you encounter timeouts, reduce the scope of your query by adding more filters or reducing the `limit` parameter.

{{< /alert >}}

### Basic embedded view syntax

To embed a GLQL query, use a code block with `glql` as the language identifier:

````yaml
```glql
display: table
title: Sprint 18.5 Dashboard
description: Current sprint work items
fields: title, assignee, state, health, labels, milestone, updated
limit: 20
sort: updated desc
query: project = "gitlab-org/gitlab" and milestone = "18.5" and opened = true
```
````

This creates a live table showing all open issues in the current milestone, automatically updating
as issues are created, modified, or closed.

### Planning dashboard examples

Create comprehensive planning dashboards directly in your wiki pages.

{{< alert type="note" >}}

In the examples throughout this section, replace `project = "group/project"` with your actual project path,
such as `project = "gitlab-org/gitlab"` or `project = "my-team/my-project"`.

{{< /alert >}}

Prerequisites:

- You must have permissions to view the queried issues and work items.

Sprint overview dashboard:

````yaml
```glql
display: table
title: Sprint Overview
description: All work for the current sprint
fields: title, assignee, state, labels("priority::*") as "Priority", health, due
limit: 30
sort: due asc
query: project = "group/project" and milestone = "Current Sprint" and opened = true
```
````

Critical bugs tracker:

````yaml
```glql
display: table
title: Critical Bugs
description: High-priority bugs requiring immediate attention
fields: title, assignee, labels, created, updated
limit: 10
query: project = "group/project" and label = "bug" and label = "severity::1" and opened = true
```
````

Team workload view:

````yaml
```glql
display: list
title: Team Work In Progress
description: Active work items by team member
fields: title, assignee, milestone, due
limit: 15
sort: assignee asc
query: project = "group/project" and assignee in (alice, bob, charlie) and label = "workflow::in dev"
```
````

Personal task list:

````yaml
```glql
display: orderedList
title: My Tasks
description: Tasks assigned to me, sorted by priority
fields: title, labels("priority::*") as "Priority", due
limit: 10
sort: due asc
query: type = Task and assignee = currentUser() and opened = true
```
````

The embedded views support:

- Multiple display formats: `table`, `list`, or `orderedList`
- Custom fields: Choose which fields to display
- Sorting: Sort by any field in ascending or descending order
- Filtering: Use complex queries with multiple conditions
- Pagination: Load additional results with **Load more**
- Dynamic functions: Use `currentUser()` for personalized views and `today()` for date-based queries

## Planning workflows with wiki

### Sprint planning and execution

Create a connected documentation flow throughout your sprint:

#### Pre-sprint planning

1. Requirements gathering: Document detailed requirements in wiki
1. Epic creation: Create epics that reference wiki specifications
1. Story breakdown: Link issues to relevant wiki documentation
1. Estimation notes: Document estimation reasoning in wiki

#### During sprint

- Daily standups: Create daily wiki pages with links to blocked issues
- Technical decisions: Document design decisions with links to implementation issues
- Impediments: Track blockers in wiki with issue references

#### Post-sprint

- Retrospectives: Create wiki retrospective pages that reference:
  - Completed issues
  - Velocity metrics
  - Action items (as new issues)
  - Lessons learned

### Long-term planning documentation

Maintain strategic documentation that connects to your roadmap:

#### Roadmap documentation structure

```plaintext
roadmap/
├── 2025-strategy
├── q1-okrs
├── q2-okrs
├── architecture-decisions/
│   ├── adr-001-microservices
│   ├── adr-002-authentication
└── technical-debt-registry
```

Each page links to relevant epics and tracks progress through issue references.

#### Architecture decision records

Document technical decisions with traceability.
You can use a template similar to this:

```markdown
# ADR-001: Adopt microservices architecture

## Status

Accepted

## Context

[Detailed context...]

## Decision

[Decision details...]

## Consequences

[Impact analysis...]

## Implementation

- Infrastructure epic: &50
- Service extraction: #2001, #2002, #2003
- Monitoring setup: #2004
```

### Cross-functional collaboration

Use wiki as a collaboration hub for cross-functional teams:

#### Design documentation

- Link design specifications to implementation issues
- Maintain component libraries with usage examples
- Document design decisions with epic references

#### API documentation

- Generate API documentation that links to implementation issues
- Maintain versioning information with milestone references
- Include example code linked to test issues

#### QA test plans

- Test strategies linked to epic requirements
- Test case repositories with issue traceability
- Bug patterns documentation with issue examples

## Navigation and discovery patterns

### Make wiki discoverable from issues and boards

#### Issue and epic templates

Include wiki references in your templates:

```markdown
## Prerequisites

- [ ] Review [[contribution-guidelines]]
- [ ] Check [[security-checklist]]
- [ ] Read relevant documentation in [[project-wiki-home]]

## Implementation

- [ ] Follow [[coding-standards]]
- [ ] Update [[api-documentation]] if needed
- [ ] Add tests per [[testing-guidelines]]
```

#### Milestone descriptions

Link to wiki planning documents:

```markdown
## Milestone 18.5

Sprint dates: 2025-02-01 to 2025-02-14

- [[Sprint 18.5 Goals|sprint-18-5-goals]]
- [[Sprint 18.5 Capacity|sprint-18-5-capacity]]
- [[Known Issues|known-issues-and-workarounds]]
```

#### Board descriptions

Reference wiki workflow documentation:

```markdown
This board follows our [[Kanban Workflow Guide|kanban-workflow-guide]].

For column definitions, see [[Board Column Definitions|board-column-definitions]].
```

### Surface work items in wiki

#### Create index pages

Build wiki pages that collect related issues:

```markdown
# Open bugs dashboard

## Critical (P1)

- #1001 - Database connection timeout
- #1002 - Authentication bypass

## High (P2)

- #1003 - Performance degradation
- #1004 - UI rendering issue

## By component

### Authentication

- #1001, #1005, #1009

### API

- #1002, #1006, #1010
```

#### Use hierarchical wiki structure

Organize wiki pages with folders and relative links:

```markdown
# Team handbook

## Processes

- [Sprint Planning](processes/sprint-planning) - How we plan sprints
- [Code Review](processes/code-review) - Review standards and SLAs
- [Incident Response](processes/incident-response) - On-call procedures

## Go up to parent page

[Back to Documentation](../documentation)
```

## Practical examples

### Example 1: Feature development workflow

A complete feature development cycle using wiki integration:

1. Product Manager:

   - Creates `feature-x-prd` wiki page with market research.
   - Creates epic &100 with link: `[[Feature X PRD|feature-x-prd]]`.
   - Adds acceptance criteria in wiki.

1. Engineering Lead:

   - Creates `feature-x-technical-design` wiki page.
   - Links design doc to epic &100.
   - Creates implementation issues #201-205 with wiki references.

1. Engineers:

   - Reference wiki design doc in MR descriptions.
   - Update wiki with decision changes.
   - Link issues to wiki troubleshooting guides.

1. QA Engineer:

   - Creates `feature-x-test-plan` wiki page.
   - Links test issues #301-305 to test plan.
   - Documents test results in wiki with issue references.

1. Technical Writer:

   - Updates user documentation in wiki.
   - Creates documentation issue #401.
   - Links wiki changes to feature epic.

### Example 2: Team knowledge base with live dashboards

Structure your team handbook with embedded views for real-time insights:

````markdown
# Engineering team handbook

## Current sprint status

```glql
display: table
title: Sprint Progress
fields: title, assignee, state, labels("workflow::*") as "Status"
limit: 20
query: project = "team/project" and milestone = "Sprint 23" and opened = true
```

## Processes

- [[Sprint Planning Process|sprint-planning-process]] - How we plan sprints
- [[Code Review Guidelines|code-review-guidelines]] - Review standards and SLAs
- [[Incident Response|incident-response]] - On-call procedures

## Technical standards

- [[API Design Standards|API-design-standards]] - REST API conventions
- [[Database Schema Guide|database-schema-guide]] - Schema design rules
- [[Security Checklist|security-checklist]] - Security requirements

## Work management

- [Issue Board](https://gitlab.example.com/group/project/-/boards/123)
- [Current Milestone](https://gitlab.example.com/group/project/-/milestones/45)
- Label taxonomy: [[Label Definitions|label-definitions]]

## Onboarding

- [[New Developer Setup|new-developer-setup]] - Environment setup
- [[First Week Issues|first-week-issues]] - Good first issues: #101, #102, #103
- [[Team Contacts|team-contacts]] - Who to ask for what
````

## Quick reference

### Wiki linking syntax

| Purpose                          | Syntax                                    | Example |
| -------------------------------- | ----------------------------------------- | ------- |
| Link to wiki page (same project) | `[[page-slug]]`                           | `[[api-standards]]` |
| Link with custom text            | `[[Display Text\|page-slug]]`             | `[[our API guide\|api-standards]]` |
| Cross-project wiki link          | `[[group/project:page-slug]]`             | `[[backend/api:rest-guide]]` |
| Alternative wiki syntax          | `[wiki_page:page-slug]`                   | `[wiki_page:home]` |
| Cross-project alternative        | `[wiki_page:namespace/project:page-slug]` | `[wiki_page:backend/api:home]` |
| Hierarchical link (same level)   | `[Link text](page-slug)`                  | `[Related](related-page)` |
| Hierarchical link (parent)       | `[Link text](../parent-page)`             | `[Up](../main)` |
| Hierarchical link (child)        | `[Link text](child-page)`                 | `[Details](details)` |
| Root link                        | `[Link text](/page-from-root)`            | `[Home](/home)` |
| Full URL                         | Standard Markdown                         | `[API Guide](https://gitlab.example.com/.../wikis/api-standards)` |

<!-- The `page-from-root` example is added as exception in doc/.vale/gitlab_docs/InternalLinkFormat.yml -->

### Referencing work items

| Item type                 | Syntax              | Example |
| ------------------------- | ------------------- | ------- |
| Issue (same project)      | `#123`              | `#123`  |
| Issue (different project) | `group/project#123` | `gitlab-org/gitlab#123` |
| Merge request             | `!123`              | `!123`  |
| Epic                      | `&123`              | `&123`  |
| Milestone                 | `%"Milestone Name"` | `%"18.5"` |

### Creating issues from wiki

Use task lists in wiki that can be converted to issues:

```markdown
## Action items from retrospective

- [ ] Improve CI pipeline performance
- [ ] Update documentation
- [ ] Add monitoring for API endpoints
```

Select the checkboxes and use **Create issue** to convert tasks to tracked issues.

## Tips for effective integration

### Use page slugs correctly

- Wiki links use page slugs (URL-friendly versions): `api-standards` not `API Standards`.
- When a page doesn't exist, selecting the link lets you create it.
- Pasted wiki URLs automatically convert to readable text (hyphens become spaces).

### Maintain bidirectional links

- When linking from wiki to an issue, also update the issue to reference the wiki page.
- Use consistent naming conventions for easier discovery.
- Consider automating link creation with webhooks or CI/CD.

### Organize for discovery

- Create a wiki home page that indexes all planning documentation.
- Use consistent page naming: `sprint-2025-01`, `adr-001`, `feature-name`.
- Use hierarchical structure with folders for large wikis.
- Tag wiki pages with categories matching your label taxonomy.

### Keep documentation current

- Include documentation updates in your Definition of Done.
- Review wiki pages during sprint planning.
- Archive outdated pages to an `archive/` folder.

### Use templates

Create wiki templates for common documents:

- Sprint planning template
- Retrospective template
- Feature specification template
- Architecture decision record template

## Related topics

- [Wiki](_index.md)
- [Issues](../issues/_index.md)
- [Issue boards](../issue_board.md)
- [Epics](../../group/epics/_index.md)
- [GitLab Query Language](../../glql/_index.md)
- [GitLab Flavored Markdown](../../markdown.md)
