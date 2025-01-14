<!--
HOW TO USE THIS TEMPLATE
To propose an AI experiment, focus on completing the “Experiment” section first. As you refine the idea and gather feedback on your experiment, progress to the Beta section to define how it will evolve, when ready, progress to the “Generally Available release” section to define how it will evolve GA capability. It's important that we link Experiment to Beta to GA release. Feel free to add sections, but the existing ones must be kept and completed.

You can choose how to get started with this template. For example, the proposal can start as an issue, and then be promoted to an epic to house all the work related to the Experiment, Beta, and GA release. If you prefer to start with an epic, you have to manually apply the proposal template. Regardless, if the experiment is eventually prioritized for development, the template content will need to appear in a top-level epic so it can be tracked alongside other prioritized AI experiments.

TITLE FORMAT
🤖 [AI Proposal] {Need/outcome} {Beneficiary} {Job/Small Job}

The title should be something that is easily understood that quickly communicates the intent of the project allowing team members to easily understand and recognize the expected work that will be done. A proposal title should combine the beneficiary of the feature/UI, the job it will allow them to accomplish (see https://about.gitlab.com/handbook/product/ux/jobs-to-be-done/#how-to-write-a-jtbd), and their expected outcome when the work is delivered. Well-defined statements are concise without sacrificing the substance of the proposal so that anyone can understand it at a glance. (e.g. {Reduce the effort} {for security teams} {when prioritizing business-critical risks in their assets}).
-->

# [Experiment](https://docs.gitlab.com/ee/policy/alpha-beta-support.html#experiment)
_This section should be completed prior to beginning work on the Experiment._

## Problem to be solved
### User problem
_What user problem will this solve?_

### Solution hypothesis
_Why do you believe this AI solution is a good way to solve this problem?_

### Assumption
_What assumptions are you making about this problem and the solution?_

### Personas
_What [personas](https://handbook.gitlab.com/handbook/product/personas/#list-of-user-personas) have this problem, who is the intended user?_

## Proposal
<!-- Explain the proposed changes, including details around usage and business drivers. -->

### Success
_How will you measure whether this experiment is a success?_

**UX maturity requirements** _[Experiment to Beta](https://about.gitlab.com/handbook/product/ai/ux-maturity/#criteria-and-requirements)_
| Criteria | Minimum Requirement | Assessment for Beta |
| -------- | ------------------- | ------------------- |
| [Problem validation](https://about.gitlab.com/handbook/product/ai/ux-maturity/#validation-problem-validation)<br>How well do we understand the problem? | [Mix of evidence and assumptions](https://about.gitlab.com/handbook/product/ai/ux-maturity/#questions-to-ask) | <!-- Acceptable answers: Yes, Somewhat or Somewhat, Somewhat --> |
| [Solution validation](https://about.gitlab.com/handbook/product/ai/ux-maturity/#validation-solution-validation)<br>How usable is the solution? | [Usability testing](https://about.gitlab.com/handbook/product/ux/ux-scorecards/#option-b-perform-a-formative-evaluation), Grade C | <!-- Acceptable: >80% and grade C --> |
| [Improve](https://about.gitlab.com/handbook/product/ai/ux-maturity/#build-improve)<br>How successful is the solution? | Quality goals set by the team are reached. | <!-- Acceptable answers: :white_check_mark: Reached all quality goals for this phase. --> |
| [Design standards](https://about.gitlab.com/handbook/product/ai/ux-maturity/#design-standards) adherence<br>How compliant is the solution with our design standards? |  Should adhere to ([Pajamas](https://design.gitlab.com/), [checklist](https://docs.gitlab.com/ee/development/contributing/design.html#checklist)) | <!-- Acceptable: Mostly adheres to design standards --> |

# [Beta](https://docs.gitlab.com/ee/policy/alpha-beta-support.html#beta)
_This section should be completed prior to beginning work on the Beta experience._
<!-- DO NOT REMOVE THIS SECTION
Although the initial focus is on the “Experiment” section, do not remove this “Beta” section. It's important that we link Experiment to Beta release. Fill this section in as you progress.
-->

### [Main Job story](https://about.gitlab.com/handbook/product/ux/jobs-to-be-done/#how-to-write-a-jtbd)
_What job to be done will this solve?_
<!-- What is the [Main Job story](https://about.gitlab.com/handbook/product/ux/jobs-to-be-done/#how-to-write-a-jtbd) that this proposal was derived from? (e.g. When I am on triage rotation, I want to address all the business-critical risks in my assets, So I can minimize the likelihood of my organization being compromised by a security breach.) -->

##### [Small Jobs](https://about.gitlab.com/handbook/product/ux/jobs-to-be-done/#small-jobs)
_What are the small jobs this feature is solving for?_

### Assumption
_What assumptions are you making about this problem and the solution?_

### Proposal updates/additions
<!-- Explain any changes or updates to the original proposal from the Experiment, including details around usage, business drivers, and reasonings that drove the updates/additions. -->

### Problem validation
_What validation exists that customers have this problem?_
<!-- Refer to https://about.gitlab.com/handbook/product/ux/ux-research/research-in-the-AI-space/#guideline-1-problem-validation---identify-and-understand-user-needs --- to help identify and understand user needs -->

### Business objective
_What business objective will be achieved with this proposal?_
<!-- Objectives (from a business point of view) that will be achieved upon completion. (For instance, Increase engagement by making the experience efficient while reducing the chances of users overlooking high-priority items. -->

### Requirements
_What tasks or actions should the user be capable of performing with this feature?_
<!-- Requirements can be taken from existing features or design issues used to build this proposal. Any related issues should be linked with this issue in the Feature/solution issues section below. They are more granular validated needs, goals, and additional details that the proposal encompasses. -->


### The user needs to be able to:
- ...
- ...

#### Success
_How will you measure whether this Beta is a success?_
<!-- Consider how successful the solution is by looking beyond feature usage as the success metric. Instead consider how useful, efficient, effective, satisfying, and learnable was the feature. The Product Development Flow recommends outcomes and potential activities to create a combined and ongoing quantitative and qualitative feedback loop to evaluate feature success. -->

**UX maturity requirements** _[Beta to GA](https://about.gitlab.com/handbook/product/ai/ux-maturity/#criteria-and-requirements)_
| Criteria | Minimum Requirement | Assessment for GA |
| -------- | ------------------- | ------------------- |
| [Problem validation](https://about.gitlab.com/handbook/product/ai/ux-maturity/#validation-problem-validation)<br>How well do we understand the problem? | [Mix of evidence and assumptions](https://about.gitlab.com/handbook/product/ai/ux-maturity/#questions-to-ask) | <!-- Acceptable answers: Yes, Yes --> |
| [Solution validation](https://about.gitlab.com/handbook/product/ai/ux-maturity/#validation-solution-validation)<br>How usable is the solution? | [Usability testing](https://about.gitlab.com/handbook/product/ux/ux-scorecards/#option-b-perform-a-formative-evaluation) and [Heuristic evaluation](https://about.gitlab.com/handbook/product/ux/ux-scorecards/#option-a-conduct-a-heuristic-evaluation), Avg. task pass rate >80%, Grade B | <!-- Acceptable: >80% and grade B --> |
| [Improve](https://about.gitlab.com/handbook/product/ai/ux-maturity/#build-improve)<br>How successful is the solution? | Quality goals set by the team are reached. | <!-- Acceptable answers: :white_check_mark: Reached all quality goals for this phase. -->  |
| [Design standards](https://about.gitlab.com/handbook/product/ai/ux-maturity/#design-standards) adherence<br>How compliant is the solution with our design standards? |  Should adhere to ([Pajamas](https://design.gitlab.com/), [checklist](https://docs.gitlab.com/ee/development/contributing/design.html#checklist)) | <!-- Acceptable: Completely adheres to design standards --> |

# [Generally Available](https://docs.gitlab.com/ee/policy/alpha-beta-support.html#generally-available-ga)
<!-- DO NOT REMOVE THIS SECTION
Although the initial focus is on the “Experiment” section, do not remove this “Generally Available” section. It's important that we link Beta to GA release. Fill this section in as you progress.
-->

### Assumption
_What assumptions are you making about this problem and the solution?_

### Proposal updates/additions
<!-- Explain any changes or updates to the original proposal from the experiment, including details around usage, business drivers, and reasonings that drove the updates/additions. -->

### Problem validation
_What validation exists that customers have this problem?_
<!-- Refer to https://about.gitlab.com/handbook/product/ux/ux-research/research-in-the-AI-space/#guideline-1-problem-validation --- to help identify and understand user needs -->

### Requirements
_What tasks or actions should the user be capable of performing with this feature?_
<!-- Requirements can be taken from existing features or design issues used to build this proposal. Any related issues should be linked with this issue in the Feature/solution issues section below. They are more granular validated needs, goals, and additional details that the proposal encompasses. -->

> ⚠️ Related feature and research issues should be linked in the related issues section (Delete this line when this is done)

#### The user needs to be able to:
- ...
- ...

## Checklist
### Experiment
<details> <summary> Issue information </summary>

- [ ] Add information to the issue body about:
    - [ ] The user problem being solved
    - [ ] Why the solution hypothesis solves this problem
    - [ ] Your assumptions have been defined
    - [ ] Who it's for, list of personas impacted
    - [ ] Your proposal has been defined
    - [ ] Your success metrics have been defined
    - [ ] UX maturity requirements have been measured
- [ ] Add relevant designs to the Design Management area of the issue if available
- [ ] Confirm that an unexpected outage of this feature will not negatively impact the application or other features
- [ ] Add a feature flag so that this feature can be quickly disabled if/when needed
- [ ] If this experiment introduces a new service or data store, ensure it is not processing or storing [red data](https://about.gitlab.com/handbook/security/data-classification-standard.html#data-classification-levels) without a security and if needed legal review
  - *NOTE*: We recommend using one of the already adopted models or data stores. If you need to use something else, be aware that using other models or data stores will require additional review during the feature stage for operational fitness and compliance.
- [ ] Completed the necessary steps to move from Experiment to Beta
- [ ] Ensure this issue has the ~wg-ai-integration label to ensure visibility to various teams working on this

</details>

### Beta
<details> <summary> Issue information </summary>

- [ ] Add information to the issue body about:
    - [ ] The Main Job story and Small Jobs it's expected to satisfy have been stated
    - [ ] Your assumptions have been defined
    - [ ] Proposal has been updated as necessary
    - [ ] Problem validation inforamtion has been added
    - [ ] Business objective has been defined
    - [ ] Requirements have been defined
    - [ ] Success metrics have been defined
    - [ ] UX maturity requirements have been measured
- [ ] Add all related feature issues to the Linked items section
- [ ] Add all relevant solution validation issues to the Linked items section that shows this proposal will solve the customer problem, or details explaining why it's not possible to provide that validation.
- [ ] Add relevant designs to the Design Management area of the issue.
- [ ] You have adhered to our [Definition of Done](https://docs.gitlab.com/ee/development/contributing/merge_request_workflow.html#definition-of-done) standards
- [ ] Completed the necessary steps to move from Beta to GA

</details>

#### Generally available
<details> <summary> Issue information </summary>

- [ ] Add information to the issue body about:
    - [ ] Your assumptions have been defined
    - [ ] Your proposal has been defined
    - [ ] Problem validation inforamtion has been added
    - [ ] Business objective has been defined
    - [ ] Confidence about this feature has been assessed and defined
    - [ ] Requirements have been defined
- [ ] Add all relevant solution validation issues to the Linked items section that shows this proposal will solve the customer problem, or details explaining why it's not possible to provide that validation.
- [ ] Add relevant designs to the Design Management area of the issue.
- [ ] You have adhered to our [Definition of Done](https://docs.gitlab.com/ee/development/contributing/merge_request_workflow.html#definition-of-done) standards
- [ ] Ensure this issue has the ~wg-ai-integration label to ensure visibility to various teams working on this

</details>

<details> <summary> Technical needs </summary>

- [ ] Please consider the operational aspects of the feature you are creating. A list of things to think about is in: https://gitlab.com/gitlab-org/gitlab/-/issues/403859. We will be improving this process in the future: https://gitlab.com/gitlab-org/gitlab/-/merge_requests/117637#note_1353253349. 
- [ ] @ mention your [AppSec Stable Counterpart](https://about.gitlab.com/handbook/product/categories/) and read the [AI secure coding guidelines](https://docs.gitlab.com/ee/development/secure_coding_guidelines.html#artificial-intelligence-ai-features)

1. Work estimate and skills needs to build an ML viable feature: To build any ML feature depending on the work, there are many personas that contribute including Data Scientist, NLP engineer, ML Engineer, MLOps Engineer, ML Infra engineers, Fullstack engineer to integrate the ML Services with Gitlab. Post-prototype we would assess the skills needed to build a production-grade ML feature for the prototype.
2. Data Limitation: We would like to upfront validate if we have viable data for the feature including whether we can use the DataOps pipeline of ModelOps or create a custom one. We would want to understand the training data, test data, and feedback data to dial up the accuracy and the limitations of the data.
3. Model Limitation: We would want to understand if we can use an open-source pre-trained model, tune and customize it or start a model from scratch as well. Further, we would assess based on the ModelOps model evaluation framework which would be the right model to use based on the use case.
4. Cost, Scalability, Reliability: We would want to estimate the cost of hosting, serving, inference of the model, and the full end-to-end infrastructure including monitoring and observability.
5. Legal and Ethical Framework: We would want to align with legal and ethical framework like any other ModelOps features to cover the nine principles of responsible ML and any legal support needed.

</details>

<details> <summary> Dependency needs </summary>

- [ ] Please consider the operational aspects of the service you are creating. A list of things to think about is in: https://gitlab.com/gitlab-org/gitlab/-/issues/403859. We will be improving this process in the future: https://gitlab.com/gitlab-org/gitlab/-/merge_requests/117637#note_1353253349. 

</details>

<details> <summary> Legal needs </summary>

- [ ]  TBD

</details>

## Additional resources
- If you'd like help with technical validation, or would like to discuss UX considerations for AI mention the AI Assisted group using `@gitlab-org/modelops/applied-ml`.
- Read about our [AI Integration strategy](https://internal-handbook.gitlab.io/handbook/product/ai-strategy/ai-integration-effort/)
- [AI-human interaction guidelines](https://design.gitlab.com/usability/ai-human-interaction)
- [Highlighting feature versions guidelines](https://design.gitlab.com/usability/feature-management#highlighting-feature-versions)
- [UX maturity requirements](https://about.gitlab.com/handbook/product/ai/ux-maturity/)
- **Slack channels**
    - `#wg_ai_integration` - Slack channel for the working group and the high-level alignment on getting AI ready for Production (Development, Product, UX, Legal, etc.) But from the other channels feel free to reach out and post progress here
    - `#ai_integration_dev_lobby` - Channel for all implementation-related topics and discussions of actual AI features (e.g. explain the code)
    - `#ai_enablement_team` - Channel for the AI Enablement Team which is building the base for all features (experimentation API, Abstraction Layer, Embeddings, etc.)

/label ~"AI Feature Proposal" ~"AI-Seeking community feedback" 
/cc @rogerwoo @oregand @jackib
/parent_epic &9997
