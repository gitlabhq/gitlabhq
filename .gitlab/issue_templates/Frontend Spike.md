<!--
This template offers a structured approach — Map, Architecture & Planning, Prototype (MAP) for frontend spikes. A spike is a time-boxed investigation intended to research a concept or build a simple prototype to better understand how to implement a feature.
-->

# Goal
<!-- Provide an overview of what this spike aims to achieve. Include as much detail as possible. -->
*This spike aims to investigate [feature/component] to determine the best approach for implementation.*

## Phase 1: Map
<!-- This phase is about understanding the current landscape - existing code and/or requirements for new features -->

### For existing features:
<!-- If working with an existing feature, complete these sections -->

#### UI discovery
- [ ] Observe the UI (note, some UI elements might be hidden) and list all of the features
- [ ] Observe user interactions (clicking, filtering, expanding components, etc.)
- [ ] Observe responsive behavior across different screen sizes
- [ ] Screenshot key UI states for reference during development

#### Code discovery
- [ ] Identify HTML/HAML entrypoint(s)
- [ ] Identify JavaScript entry point(s)
- [ ] Map out the current code responsibilities:
  - [ ] HTML/HAML (note any hidden partials or conditionally rendered elements)
  - [ ] JavaScript (list key modules/submodules with their purposes)
  - [ ] Vue components (if applicable)

#### Data flow mapping
- [ ] Identify server-side rendered (SSR) data
- [ ] Identify client-side loaded data (e.g., via API calls, GraphQL)
- [ ] Note any pagination, infinite scroll, or lazy loading mechanisms
- [ ] Identify API/GraphQL endpoint requirements and limitations

### For new features:
<!-- If working on a new feature, complete these sections -->

#### Requirements Mapping
- [ ] Identify core user requirements and expected behaviors
- [ ] Document technical constraints and integration points
- [ ] Map user journeys and interactions

## Phase 2: Architecture & Planning
<!-- Design the solution based on findings from the Map phase -->

### State Management
- [ ] Determine state management approach
- [ ] Identify local vs. global state needs
- [ ] Consider data sharing between components

### Component Architecture
- [ ] Identify potential Vue component structure
- [ ] Map component relationships and data flow
- [ ] Note reusability opportunities (e.g., existing GitLab UI components, re-usable partials, etc.)
- [ ] Create an architecture diagram showing component relationships

### Technical Considerations
- [ ] Note accessibility requirements
- [ ] Evaluate feature flag requirements for progressive rollout
- [ ] Identify potential performance bottlenecks
- [ ] Consider adding performance marks and/or Sitespeed monitoring
- [ ] Plan for data that is loaded async (e.g., paginated data, progressive disclosure, etc.) if appropriate

## Phase 3: Prototype
<!-- Build a minimal proof of concept to validate the architecture -->

### Implementation
- [ ] Implement core functionality
- [ ] Test key user flows
- [ ] Validate technical assumptions
- [ ] Measure performance impacts (if applicable)

### Documentation
- [ ] Document prototype limitations
- [ ] Outline any technical debt or future considerations
- [ ] Create implementation plan for full feature development

## Findings and Recommendations
<!-- Document your findings here as you complete the spike -->

### Summary of Findings
* 

### Recommended Approach
*

### Potential Challenges
*

### Open Questions
*

### Time Estimation
<!-- Add estimates for implementation based on spike findings -->
*

<!-- 
Remember that a spike is time-boxed. If you find yourself going down rabbit holes,
reconsider the scope of your investigation and focus on answering the core questions.
-->