---
status: proposed
creation-date: "2023-10-10"
authors: [ "@thomasrandolph", "@patrickbajao", "@igor.drozdov", "@jerasmus", "@iamphill", "@slashmanov", "@psjakubowska" ]
coach: [ "@ntepluhina" ]
approvers: [ ]
owning-stage: "~devops::create"
participating-stages: []
---

<!-- Blueprints often contain forward-looking statements -->
<!-- vale gitlab.FutureTense = NO -->

# Reusable Rapid Diffs (RRD)

## Summary

Diffs at GitLab are spread across several places with each area using their own method. We are aiming
to develop a single, performant way for diffs to be rendered across the application. Our aim here is
to improve all areas of diff rendering, from the backend creation of diffs to the frontend rendering
the diffs.

All the diffs features related to this document are [listed on a dedicated page](features.md).

## Motivation

### Goals

- improved perceived performance
- improved maintainability
- consistent coverage of all scenarios

### Non-Goals

<!--
Listing non-goals helps to focus discussion and make progress. This section is
optional.

- What is out of scope for this blueprint?
-->

This effort will not:

- Identify improvements for the current implementation of diffs both in Merge Requests or in the Repository Commits

### Priority of Goals

In an effort to provide guidance on which goals are more important than others to assist in making
consistent choices, despite all goals being important, we defined the following order.

**Perceived performance** is above **improved maintainability** is above **consistent coverage**.

Examples:

- a proposal improves maintainability at the cost of perceived performance: ❌ we should consider an alternative.
- a proposal removes a feature from certain contexts, hurting coverage, and has no impact on perceived performance or maintainability: ❌ we should re-consider.
- a proposal improves perceived performance but removes features from certain contexts of usage: ✅ it's valid and should be discussed with Product/UX.
- a proposal guarantees consistent coverage and has no impact on perceived performance or maintainability: ✅ it's valid.

In essence, we'll strive to meet every goal at each decision but prioritise the higher ones.

## Process

### Workspace & Artifacts

- We will store implementation details like metrics, budgets, and development & architectural patterns here in the docs
- We will store large bodies of research, the results of audits, etc. in the [wiki](https://gitlab.com/gitlab-com/create-stage/new-diffs/-/wikis/home) of the [RRD project](https://gitlab.com/gitlab-com/create-stage/new-diffs)
- We will store audio & video recordings on the public YouTube channel in the [Code Review / RRD playlist](https://www.youtube.com/playlist?list=PL05JrBw4t0KpZ3yR2eN0Sh9Bn073HU093)
- We will store drafts, meeting notes, and other temporary documents in public Google docs

## Proposal

<!--
This is where we get down to the specifics of what the proposal actually is,
but keep it simple!  This should have enough detail that reviewers can
understand exactly what you're proposing, but should not include things like
API designs or implementation. The "Design Details" section below is for the
real nitty-gritty.

You might want to consider including the pros and cons of the proposed solution so that they can be
compared with the pros and cons of alternatives.
-->

The new approach proposed here changes what [we have done in the past](#alternative-solutions) by doing the following:

1. Stop using virtualized scrolling for rendering diffs.
1. Move most of the rendering work to the server.
1. Enhance server-rendered HTML on the client.
1. Unify diffs codebase across all pages rendering diffs (merge request, repository commits, compare revisions and any other).

## Definitions

### Maintainability

Maintainable projects are _simple_ projects.

Simplicity is the opposite of complexity. This uses a definition of simple and complex [described by Rich Hickey in "Simple Made Easy"](https://www.infoq.com/presentations/Simple-Made-Easy/) (Strange Loop, 2011).

- Maintainable code is simple (single task, single concept, separate from other things).
- Maintainable projects expand on simple code by having simple structure (folders define classes of behaviors, e.g. you can be assured that a component directory will never initiate a network call, because that would be conflating visual display with data access)
- Maintainable applications flow out of simple organization and simple code. The old saying is a cluttered desk is representative of a cluttered mind. Rigorous discipline on simplicity will be represented in our output (the product). By being strict about working simply, we will naturally produce applications where our users can more easily reason about their behavior.

### Done

GitLab has an existing [definition of done](/ee/development/contributing/merge_request_workflow.md#definition-of-done) which is geared primarily toward identifying when an MR is ready to be merged.

In addition to the items in the GitLab definition of done, work on RRD should also adhere to the following requirements:

- Meets or exceeds all metrics
  - Meets or exceeds our minimum accessibility metrics (these are explicitly not part of our defined priorities, because they are non-negotiable)
- All work is fully documented for engineers (user documentation is a requirement of the standard definition of done)

## Acceptance Criteria

To measure our success, we need to set meaningful metrics. These metrics should meaningfully and positively impact the end user.

1. Meets or exceeds [WCAG 2.2 AA](https://www.w3.org/TR/WCAG22/).
1. Meets or exceeds [ATAG 2.0 AA](https://www.w3.org/TR/ATAG20/).
1. The RRD app loads less than or equal to 300 KiB of JavaScript (compressed / "across-the-wire")<sup>1</sup>.
1. The RRD app loads less than or equal to 150 KiB of markup, images, styles, fonts, etc. (compressed / "across-the-wire")<sup>1</sup>.
1. The Time to First Diff (`mr-diffs-mark-first-diff-file-shown`) happens before 3 seconds mark.
1. The RRD app can execute in total isolation from the rest of the GitLab product:
    1. "Execute" means the app can load, display data, and allows user interaction ("read-only").
    1. If a part of the application is only used in merge requests or diffs, it is considered part of the Diffs application.
    1. If a part of the application must be brought in from the rest of the product, it is not considered part of the Diffs load (as defined in metrics 3 and 4).
    1. If a part of the application must be brought in from the rest of the product, it may not block functionality of the Diffs application.
    1. If a part of the application must be brought in from the rest of the product, it must be loaded asynchronously.
    1. If a part of the application meets 5.1-5.5 _(such as: the Markdown editor is loaded asynchronously when the user would like to leave a comment on a diff)_ and its inclusion causes a budget overflow:
       - It must be added to a list of documented exceptions that we accept are out of bounds and out of our control.
       - The exceptions list should be addressed on a regular basis to determine the ongoing value of overflowing our budget.

---
<sup>1</sup>: [The Performance Inequality Gap, 2023](https://infrequently.org/2022/12/performance-baseline-2023/)

### Frontend

Ideally, we would meet our definition of done and our accountability metrics on our first try.
We also need to continue to stay within those boundaries as we move forward. To ensure this,
we need to design an application architecture that:

1. Is:
   1. Scalable.
   1. Malleable.
   1. Flexible.
1. Considers itself a mission-critical part of the overall GitLab product.
1. Treats itself as a complex, unique application with concerns that cannot be addressed
   as side effects of other parts of the product.
1. Can handle data access/format changes without making UI changes.
1. Can handle UI changes without making data access/format changes.
1. Provides a hookable, inspectable API and avoids code coupling.
1. Separates:
    - State and application data.
    - Application behavior and UI.
    - Data access and network access.

## Design and implementation details

### Overview

Reusable Rapid Diffs introduce a change in responsibilities for both frontend and backend.

The backend will:

1. Prepare diffs data.
1. Highlight diff lines.
1. Render diffs as HTML and stream them to the browser.
1. Embed diffs metadata into the final response.

The frontend will:

1. Enhance existing and future diffs HTML.
1. Handle streamed diffs HTML.
1. Enhance diffs HTML with dynamic controls to enable user interaction.

#### Static and dynamic separation

To achieve the separation of concerns, we should distinguish between static and dynamic UI on the page:

- Everything that is static should always be rendered on the server.
- Everything dynamic should be enhanced on the client.

As an example: a highlighted diff line doesn't change with user input, so we should consider rendering it on the server.

#### Performance optimizations

To improve the perceived performance of the page we should implement the following techniques:

1. Limit the number of diffs rendered on the page at first.
1. Use [HTML streaming](https://gitlab.com/gitlab-org/frontend/rfcs/-/issues/101)
   to render the rest of the diffs.
    1. Use Web Components to hook into diff files appearing on the page.
1. Apply `content-visibility` whenever possible to reduce redraw overhead.
1. Render diff discussions asynchronously.

#### Page & Data Flows

These diagrams document the flows necessary to display diffs and to allow user interactions and user-submitted data to be gathered and stored.
In other words: this page documents the bi-directional data flow for a complete, interactive application that allows diffs to display and users to collaborate on diffs.

##### Critical Phases

1. Gitaly
1. Database
1. Diff Storage
1. Cache
1. Back end
1. Web API
1. Front end*

```mermaid

flowchart LR
    Gitaly
    DB[Database]
    Cache
    DS[Diff Storage]
    FE[Front End]
    Display

    Gitaly <--> BE
    DB <--> BE
    Cache <--> BE
    DS <--> BE
    BE <--> API
    API <--> FE
    FE --> Display

    subgraph Rails
    direction LR
        BE[Back End]
        API[Web API]
    end

```

<sup>*</sup>: Front end obscures many unexplored phases. It is likely that the front end will need caches, databases, API abstractions (over sub-modules like network connectivity, etc.), and more. While these have not been expanded on, "Front end" stands in for all of that complexity here.

###### Gitaly

For fetching Diffs, Gitaly provides two basic utilities:

1. Retrieve a list of modified files with associated pre- and post-image blob IDs for a set of revisions.
1. Retrieve a set of Git diffs for an arbitrary set of specified files using pre- and post-image blob IDs.

```mermaid
sequenceDiagram
    Back end ->> Gitaly: "What files were modified between<br />this pair of/in this single revision?"
    Gitaly ->> Back end: List of paths
    Back end ->> Gitaly: "What are the diffs for this set of paths<br /> between this pair of/in this single revision?"
    Gitaly ->> Back end: List of diffs
```

###### Database

```mermaid
sequenceDiagram
    Back end ->> Database: What are the file paths for a known MR version?
    Database ->> Back end: List of paths
```

###### Cache

- Fresh render of a diff

```mermaid
sequenceDiagram
    Back end ->> Cache: Give me the diff template for scenario XYZ
    Cache ->> Back end: Static template to render diff in scenario XYZ
```

- Repeated render of a diff

```mermaid
sequenceDiagram
    Back end ->> Cache: Give me the compiled UI for diff ABC123
    alt Cache miss
        Cache ->> Back end: ☹️
        Back end ->> Cache: Cache the compiled UI for diff ABC123
    else
        Cache ->> Back end: Existing compiled diff UI
    end
```

###### Diff Storage

```mermaid
sequenceDiagram
    Back end ->> Diff Storage: Give me the raw diff of this file
    Diff Storage ->> Back end: Raw diff
```

### Accessibility

Reusable Rapid Diffs should be displayed in a way that is compliant with [Web Content Accessibility Guidelines 2.1](https://www.w3.org/TR/WCAG21/) level AA for web-based content and [Authoring Tool Accessibility Guidelines 2.0](https://www.w3.org/TR/ATAG20/) level AA for user interface.

We recognize that in order to have an accessible experience using diffs in the context of GitLab, we need to ensure the compliance both for displaying and interacting with diffs. That's why the accessibility
audit and further recommendation will also consider Content Editor used feature for reviewing changes.

#### ATAG 2.0 AA

Giving the nature of diffs, the following guidelines will be our main focus:

1. [Guideline A.2.1: (For the authoring tool user interface) Make alternative content available to authors](https://www.w3.org/TR/ATAG20/#gl_a21)
1. [Guideline A.3.1: (For the authoring tool user interface) Provide keyboard access to authoring features](https://www.w3.org/TR/ATAG20/#gl_a31)
1. [Guideline A.3.4: (For the authoring tool user interface) Enhance navigation and editing via content structure](https://www.w3.org/TR/ATAG20/#gl_a34)
1. [Guideline A.3.6: (For the authoring tool user interface) Manage preference settings](https://www.w3.org/TR/ATAG20/#gl_a36)

#### HTML structure

The HTML structure of a diff should have support for assistive technology.
For this reason, a table could be a preferred solution as it allows to indicate
logical relationship between the presented data and is easier to navigate for
screen reader users with keyboard. Labeled columns will make sure that information
such as line numbers can be associated with the edited piece of code.

Possible structure could include:

```html
<table>
  <caption class="gl-sr-only">Changes for file index.js. 10 lines changed: 5 deleted, 5 added.</caption>
  <tr hidden>
    <th>Original line number: </th>
    <th>Diff line number: </th>
    <th>Line change:</th>
  </tr>
  <tr>
    <td>1234</td>
    <td></td>
    <td>.tree-time-ago ,</td>
  </tr>
  […]
</table>
```

See [WAI tutorial on tables](https://www.w3.org/WAI/tutorials/tables) for
more implementation guidelines.

Each file table should include a short summary of changes that will read out:

- total number of lines changed,
- number of added lines,
- number of removed lines.

The summary of the table content can be placed either within `<caption>` element, or before the table within an element referred as `aria-describedby`.
See <abbr>WAI</abbr> (Web Accessibility Initiative) for more information on both approaches:

- [Nesting summary inside the `<caption>` element](https://www.w3.org/WAI/tutorials/tables/caption-summary/#nesting-summary-inside-the-caption-element)
- [Using `aria-describedby` to provide a table summary](https://www.w3.org/WAI/tutorials/tables/caption-summary/#using-aria-describedby-to-provide-a-table-summary)

However, if such a structure will compromise other functional aspects of displaying a diff,
more generic elements together with ARIA support can be used.

#### Visual indicators

It is important that each visual indicator should have a screen reader text
denoting the meaning of that indicator. When needed, use `gl-sr-only` or `gl-sr-only-focusable`
class to make the element accessible by screen readers, but not by sighted users.

Some of the visual indicators that require alternatives for assistive technology are:

- `+` or red highlighting to be read as `added`
- `-` or green highlighting to be read as `removed`

### High-level implementation

<!--
This section should contain enough information that the specifics of your
change are understandable. This may include API specs (though not always
required) or even code snippets. If there's any ambiguity about HOW your
proposal will be implemented, this is the place to discuss them.

If you are not sure how many implementation details you should include in the
blueprint, the rule of thumb here is to provide enough context for people to
understand the proposal. As you move forward with the implementation, you may
need to add more implementation details to the blueprint, as those may become
an important context for important technical decisions made along the way. A
blueprint is also a register of such technical decisions. If a technical
decision requires additional context before it can be made, you probably should
document this context in a blueprint. If it is a small technical decision that
can be made in a merge request by an author and a maintainer, you probably do
not need to document it here. The impact a technical decision will have is
another helpful information - if a technical decision is very impactful,
documenting it, along with associated implementation details, is advisable.

If it's helpful to include workflow diagrams or any other related images.
Diagrams authored in GitLab flavored markdown are preferred. In cases where
that is not feasible, images should be placed under `images/` in the same
directory as the `index.md` for the proposal.
-->

## Alternative Solutions

<!--
It might be a good idea to include a list of alternative solutions or paths considered, although it is not required. Include pros and cons for
each alternative solution/path.

"Do nothing" and its pros and cons could be included in the list too.
-->

### Historical context

Reusable Rapid Diffs introduce a paradigm shift in our approach to rendering diffs. Before this proposed architecture, we had two different approaches to rendering diffs:

1. Merge requests heavily utilized client-side rendering.
1. All other pages mainly used server-side rendering with additional behavior implemented in JavaScript.

In merge requests, most of the rendering work was done on the client:

- The backend would only generate a JSON response with diffs data.
- The client would be responsible for both drawing the diffs and reacting to user input.

This led to us adopting a
[virtualized scrolling solution](https://github.com/Akryum/vue-virtual-scroller/tree/v1/packages/vue-virtual-scroller)
for client-side rendering, which sped up drawing large diff file lists significantly.

Unfortunately, this came with downsides of a very high maintenance cost and
[constant bugs](https://gitlab.com/gitlab-org/gitlab/-/issues/427155#note_1607184794).
The user experience also suffered because we couldn't show diffs right away
when you visited a page, and had to wait for the JSON response first.
Lastly, this approach went completely parallel to the server-rendered diffs used on other pages,
which resulted in two completely separate codebases for the diffs.

### Summary of the alternative solutions attempted

Here is a list of the strategies we have adopted or simply tested in the past:

- Full Server Side Rendering (adopted and replaced by Vue app): before the Vue refactor of the Merge Request Changes tab, diffs were fully rendered on the server. This resulted in long waits before the page started to render.
- Frontend templates (Vue) Server Side Rendered ([tested](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/33052#note_350101205)): results and impact weren't compelling and pointed in the direction of partial SSR. ([PoC MR](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/33052))
- Batch diffing (adopted): Break up the diffs into async paginated requests, increasing in size (slow start). Bootstrapping time unsatisfactory, perceived performance still involved a long time of a page without content.
- Virtual Scrolling (adopted): several known side-effects like inability to fully use native search functionality, interferences and weird behavior while scrolling to elements, overall strain on the browser to keep reflowing and painting. ([Comparison with the proposed approach in this blueprint](https://gitlab.com/gitlab-org/gitlab/-/issues/433015#note_1671675884))
- Repository Commits details paginated if too large (adopted): As an interim solution, really large commit diffs in the repository are now paginated with negative impact in UX, hiding away files and changes through multiple pages.
- Micro Code Review Frontend PoC (tested): This approach was significantly different from the application design used in the past, so it was never seriously explored as a way forward. Parts of this design - like custom elements and a reliance on events - have been incorporated into alternative approaches. ([Micro Code Review Frontend PoC](https://gitlab.com/gitlab-org/gitlab/-/issues/389282))
- Streaming Diffs using a node server (tested): Combines streaming with a dedicated nodejs server. Percursor to the proposed SSR approach in this blueprint. ([PoC: Streaming diffs app](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/84563))

## Proposed changes

These changes (indicated by an arbitrary name like "Design A") suggest a proposed final path forward for this blueprint, but have not yet been accepted as the authoritative content.

- Mark the highest hierarchical heading with your design name. If you are changing multiple headings at the same level, make sure to mark them all with the same name. This will create a high-level table of contents that is easier to reason about.

### Front end (Design A)

#### High-level implementation

NOTE:
This draft proposal suggests one potential front end architecture which may not be chosen. It is not necessarily mutually exclusive with other proposed designs.

(See [New Diffs: Technical Architecture Design](https://gitlab.com/gitlab-org/gitlab/-/issues/431276) for nicer visuals of this chart)

```mermaid
flowchart TB
    classDef sticky fill:#d0cabf, color:black
    stickyMetricsA>"Metrics 3, 4, & 5 apply to<br>the entire front end application"]

    stickyMetricsA -.- fe
    fe

    Socket((WebSocket))

    be

subgraph fe [Front End]
    stickyMetricsB>"Metrics 1 & 2 apply<br>to all UI elements"]
    stickyInbound>"All data is formatted precisely<br>how the UI needs to interact with it"]
    stickyOutbound>"All data is formatted precisely<br>how the back end expects it"]
    stickyIdb>"Long-term.

    e.g. diffs, MRs, emoji, notes, drafts, user-only data<br>like file reviews, collapse states, etc."]
    stickySession>"Session-term.

    e.g. selected tab, scroll position,<br>temporary changes to user settings, etc."]

    Events([Event Hub])
    UI[UI]
    uiState((Local State))
    Logic[Application Logic]
    Normalizer[Data Normalizer]
    Inbound{{Inbound Contract}}
    Outbound{{Outbound Contract}}
    Data[Data Access]
    idb((indexedDB))
    session((sessionStorage))
    Network[Network Access]
end

subgraph be [Back End]
    stickyApi>"A large list of defined actions a<br>Diffs/Merge Request UI could perform.

    e.g.: <code>mergeRequest:notes:saveDraft</code> or<br><code>mergeRequest:changeStatus</code> (with <br><code>status: 'draft'</code> or <code>status: 'ready'</code>, etc.).

    Must not expose any implementation detail,<br>like models, storage structure, etc."]
    API[Activities API]
    unk[\"?"/]

    API -.- stickyApi
end

    %% Make stickies look like paper sort of?
    class stickyMetricsA,stickyMetricsB,stickyInbound,stickyOutbound,stickyIdb,stickySession,stickyApi sticky

    UI <--> uiState
    stickyMetricsB -.- UI
    Network ~~~ stickyMetricsB

    Logic <--> Normalizer

    Normalizer --> Outbound
    Outbound --> Data
    Inbound --> Normalizer
    Data --> Inbound

    Inbound -.- stickyInbound
    Outbound -.- stickyOutbound

    Data <--> idb
    Data <--> session
    idb -.- stickyIdb
    session -.- stickySession

    Events <--> UI
    Events <--> Logic
    Events <--> Data
    Events <--> Network

    Network --> Socket --> API --> unk
```
