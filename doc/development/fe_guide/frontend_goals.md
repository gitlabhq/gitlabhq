---
stage: none
group: unassigned
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: Frontend Goals
---

This section defines the _desired state_ of the GitLab frontend and how we see it over the next few years. It is a living document and will adapt as technologies and team dynamics evolve.

## Technologies

### Vue@latest

Keeping up with the latest version of Vue ensures that the GitLab frontend leverages the most efficient, secure, and feature-rich framework capabilities. The latest Vue (3) offers improved performance and a more intuitive API, which collectively enhance the developer experience and application performance.

**Current Status**

- **As of December 2023**: GitLab is currently using Vue 2.x.
- **Progress**: (Brief description of progress)

**Responsible Team**

- **Working Group**: [Vue.js 3 Migration Working Group](https://handbook.gitlab.com/handbook/company/working-groups/vuejs-3-migration/)
- **Facilitator**: Sam Beckham, Engineering Manager, Manage:Foundations

**Milestones and Timelines**

- (Key milestones, expected completions)

**Challenges and Dependencies**

- (Any major challenges)

**Success Metrics**

- Using @vue/compat in Monolith

### State Management

When global state management is needed, it should happen in Apollo instead of Vuex or other state management libraries. See [Migrating from Vuex](migrating_from_vuex.md) for more details regarding why and how we plan on migrating.

**Current Status**

- **As of December 2023**: (Status)
- **Progress**: (Brief description of progress)

**Responsible Team**

- **Task Group**:
- **Facilitator**:

**Milestones and Timelines**

- (Key milestones, expected completions)

**Challenges and Dependencies**

- (Any major challenges)

**Success Metrics**

- (Potential metrics)

### HAML by default

We'll continue using HAML over Vue when appropriate. See [when to add Vue application](vue.md#when-to-add-vue-application) on how to decide when Vue should be chosen.

**Current Status**

- **As of December 2023**: (Status)
- **Progress**: (Brief description of progress)

**Responsible Team**

- **Task Group**:
- **Facilitator**:

**Milestones and Timelines**

- (Key milestones, expected completions)

**Challenges and Dependencies**

- (Any major challenges)

**Success Metrics**

- (Potential metrics)

### Complete removal of jQuery

In 2019 we committed to no longer use jQuery, however we have not prioritized full removal. Our goal here is to no longer have any references to it in the primary GitLab codebase.

**Current Status**

- **As of December 2023**: (Status)
- **Progress**: (Brief description of progress)

**Responsible Team**

- **Task Group**:
- **Facilitator**:

**Milestones and Timelines**

- (Key milestones, expected completions)

**Challenges and Dependencies**

- (Any major challenges)

**Success Metrics**

- (Potential metrics)

### Dependencies management

Similar to keeping on the latest major version of Vue, we should try to keep as close as possible to the latest version of our dependencies, unless not upgrading outweighs the benefits of upgrading. At a minimum, we will audit the dependencies annually to evaluate whether or not they should be upgraded.

**Current Status**

- **As of December 2023**: (Status)
- **Progress**: (Brief description of progress)

**Responsible Team**

- **Task Group**:
- **Facilitator**:

**Milestones and Timelines**

- (Key milestones, expected completions)

**Challenges and Dependencies**

- (Any major challenges)

**Success Metrics**

- (Potential metrics)

## Best Practices

## Scalability and Performance

### Cluster SPAs

Currently, GitLab mostly follows Rails architecture and Rails routing which means every single time we're changing route, we have page reload. This results in long loading times because we are:

- rendering HAML page;
- mounting Vue applications if we have any;
- fetching data for these applications

Ideally, we should reduce the number of times user needs to go through this long process. This would be possible with converting GitLab into a single-page application but this would require significant refactoring and is not an achievable short/mid-term goal.

The realistic goal is to move to _multiple SPAs_ experience where we define the _clusters_ of pages that form the user flow, and move this cluster from Rails routing to a single-page application with client-side routing. This way, we can load all the relevant context from HAML only once, and fetch all the additional data from the API depending on the route. An example of a cluster could be the following pages:

- **Issues** page
- **Issue boards** page
- **Issue details** page
- **New issue** page
- editing an issue

All of them have the same context (project path, current user etc.), we could easily fetch more data with issue-specific parameter (issue `iid`) and store the results on the client (so that opening the same issue won't require more API calls). This leads to a smooth user experience for navigating through issues.

For navigation between clusters, we can still rely on Rails routing. These cases should be relatively more scarce than navigation within clusters.

**Current Status**

- **As of December 2023**: (Status)
- **Progress**: (Brief description of progress)

**Responsible Team**

- **Task Group**:
- **Facilitator**:

**Milestones and Timelines**

- (Key milestones, expected completions)

**Challenges and Dependencies**

- (Any major challenges)

**Success Metrics**

- (Potential metrics)

### Reusable components

Currently, we keep generically reusable components in two main places:

- GitLab UI
- `vue_shared` folder

While GitLab UI is well-documented and components are abstract enough to be reused anywhere in Vue applications, our `vue_shared` components are somewhat chaotic, often can be used only in certain context (for example, they can be bound to an existing Vuex store) and have duplicates (we have multiple components for notes).

We should perform an audit of `vue_shared`, find out what can and what cannot be moved to GitLab UI, and refactor existing components to remove duplicates and increase reusability. The ideal outcome would be having application-specific components moved to application folders, and keep reusable "smart" components in the shared folder/library, ensuring that every single piece of reusable functionality has _only one implementation_.

This is currently under development. Follow the [GitLab Modular Monolith for FE](https://gitlab.com/gitlab-org/gitlab/-/issues/422903) for updates on how we will enforce encapsulation on top-level folders like `vue_shared`.

**Current Status**

- **As of December 2023**: (Status)
- **Progress**: (Brief description of progress)

**Responsible Team**

- **Task Group**:
- **Facilitator**:

**Milestones and Timelines**

- (Key milestones, expected completions)

**Challenges and Dependencies**

- (Any major challenges)

**Success Metrics**

- (Potential metrics)

### Migrate to PostCSS

SASS compilation takes almost half of the total frontend compilation time. This makes our pipelines run longer than they should. Migrating to PostCSS should [significantly improve compilation times](https://github.com/postcss/benchmark#preprocessors).

**Current Status**

- **As of December 2023**: (Status)
- **Progress**: (Brief description of progress)

**Responsible Team**

- **Task Group**:
- **Facilitator**:

**Milestones and Timelines**

- (Key milestones, expected completions)

**Challenges and Dependencies**

- (Any major challenges)

**Success Metrics**

- (Potential metrics)

## Collaboration and Tooling

### Visual Testing

We're early in the process of adding visual testing, but we should have a framework established. Once implementation is determined, we'll update this doc to include the specifics.

**Current Status**

- **As of December 2023**: (Status)
- **Progress**: (Brief description of progress)

**Responsible Team**

- **Task Group**:
- **Facilitator**:

**Milestones and Timelines**

- (Key milestones, expected completions)

**Challenges and Dependencies**

- (Any major challenges)

**Success Metrics**

- (Potential metrics)

### Accessibility testing

In 2023 we determined the tooling for accessibility testing. We opted for axe-core gem used in feature tests, to test the whole views rather then components in isolation. [See documentation on Automated accessibility testing](accessibility/automated_testing.md) to learn when and how to include it. You can check out our progress with [Accessibility scanner](https://gitlab-org.gitlab.io/frontend/playground/accessibility-scanner/) that uses Semgrep to find out if tests are present.

**Current Status**

- **As of December 2023**: (Status)
- **Progress**: (Brief description of progress)

**Responsible Team**

- **Working Group**: [Product Accessibility Group](https://handbook.gitlab.com/handbook/company/working-groups/product-accessibility/)
- **Facilitator**: Paulina Sędłak-Jakubowska

**Milestones and Timelines**

- (Key milestones, expected completions)

**Challenges and Dependencies**

- (Any major challenges)

**Success Metrics**

- (Potential metrics)
