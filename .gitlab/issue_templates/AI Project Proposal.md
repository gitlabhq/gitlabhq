<!--
HOW TO USE THIS TEMPLATE
To propose an AI experiment, focus on completing the “Experiment” section first. As you refine the idea and gather feedback on your experiment, use the “Feature release” section to define how it will evolve as a Beta or GA capability. It's important that we link experiment to feature release. Feel free to add sections, but keep the existing ones.

You can choose how to get started with this template. For example, the proposal can start as an issue, and then be promoted to an epic to house all the work related to the experiment/prototype and feature release. If you prefer to start with an epic, you have to manually apply the proposal template. Regardless, if the experiment is eventually prioritized for development, the template content will need to appear in a top-level epic so it can be tracked alongside other prioritized AI experiments.

TITLE FORMAT
🤖 [AI Proposal] {Need/outcome} {Beneficiary} {Job/Small Job}

The title should be something that is easily understood that quickly communicates the intent of the project allowing team members to easily understand and recognize the expected work that will be done. A proposal title should combine the beneficiary of the feature/UI, the job it will allow them to accomplish (see https://about.gitlab.com/handbook/product/ux/jobs-to-be-done/#how-to-write-a-jtbd), and their expected outcome when the work is delivered. Well-defined statements are concise without sacrificing the substance of the proposal so that anyone can understand it at a glance. (e.g. {Reduce the effort} {for security teams} {when prioritizing business-critical risks in their assets}).
-->

# Experiment

This section should be completed prior to work on the Experiment beginning.

# [Experiment](https://docs.gitlab.com/ee/policy/alpha-beta-support.html#experiment)

##  Problem to be solved

### User problem
_What user problem will this solve?_

### Solution hypothesis
_Why do you believe this AI solution is a good way to solve this problem?_

### Assumption
_What assumptions are you making about this problem and the solution?_

### Personas
_What [personas](https://about.gitlab.com/handbook/product/personas/#list-of-user-personas) have this problem, who is the intended user?_

## Proposal
<!-- Explain the proposed changes, including details around usage and business drivers. -->

### Success
_How will you measure whether this experiment is a success?_


# Feature release
<!-- DO NOT REMOVE THIS SECTION
Although the initial focus is on the “Experiment” section, do not remove this “Feature release” section. It's important that we link experiment to feature release. Fill this section as you progress.
-->
### Main Job story
_What job to be done will this solve?_
<!-- What is the [Main Job story](https://about.gitlab.com/handbook/product/ux/jobs-to-be-done/#how-to-write-a-jtbd) that this proposal was derived from? (e.g. When I am on triage rotation, I want to address all the business-critical risks in my assets, So I can minimize the likelihood of my organization being compromised by a security breach.) -->

## Proposal updates/additions
<!-- Explain any changes or updates to the original proposal from the experiment, including details around usage, business drivers, and reasonings that drove the updates/additions. -->

### Problem validation
_What validation exists that customers have this problem?_
<!-- Refer to https://about.gitlab.com/handbook/product/ux/ux-research/research-in-the-AI-space/#guideline-1-problem-validation --- to help identify and understand user needs -->

### Business objective
_What business objective will be achieved with this proposal?_
<!-- Objectives (from a business point of view) that will be achieved upon completion. (For instance, Increase engagement by making the experience efficient while reducing the chances of users overlooking high-priority items. -->

### Confidence
_Has this proposal been derived from research?_
<!-- How well do we understand the user's problem and their need? Refer to https://about.gitlab.com/handbook/product/ux/product-design/ux-roadmaps/#confidence to assess confidence -->

| Confidence        | Research                       |
| ----------------- | ------------------------------ |
| [High/Medium/Low] | [research/insight issue](Link) |

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
    - [ ] Your assumptions
    - [ ] Who it's for, list of personas impacted
    - [ ] Your proposal
- [ ] Add relevant designs to the Design Management area of the issue if available
- [ ] Confirm that an unexpected outage of this feature will not negatively impact the application or other features
- [ ] Add a feature flag so that this feature can be quickly disabled if/when needed
- [ ] If this experiment introduces a new service or data store, ensure it is not processing or storing [red data](https://about.gitlab.com/handbook/security/data-classification-standard.html#data-classification-levels) without a security and if needed legal review
  - *NOTE*: We recommend using one of the already adopted models or data stores. If you need to use something else, be aware that using other models or data stores will require additional review during the feature stage for operational fitness and compliance.
- [ ] Ensure this issue has the ~wg-ai-integration label to ensure visibility to various teams working on this

</details>

### Feature release
<details> <summary> Issue information </summary>

- [ ] Add information to the issue body about:
    - [ ] Your proposal
    - [ ] The Job Statement it's expected to satisfy
    - [ ] Details about the user problem and provide any research or problem validation
    - [ ] List the personas impacted by the proposal.
- [ ] Add all relevant solution validation issues to the Linked items section that shows this proposal will solve the customer problem, or details explaining why it's not possible to provide that validation.
- [ ] Add relevant designs to the Design Management area of the issue.
- [ ] You have adhered to our [Definition of Done](https://docs.gitlab.com/ee/development/contributing/merge_request_workflow.html#definition-of-done) standards
- [ ] Ensure this issue has the ~wg-ai-integration label to ensure visibility to various teams working on this

</details>

<details> <summary> Technical needs </summary>

- [ ] Please consider the operational aspects of the feature you are creating. A list of things to think about is in: https://gitlab.com/gitlab-org/gitlab/-/issues/403859. We will be improving this process in the future: https://gitlab.com/gitlab-org/gitlab/-/merge_requests/117637#note_1353253349. 
- [ ] @ mention your [AppSec Stable Counterpart](https://about.gitlab.com/handbook/product/categories/) and read the [AI secure coding guidelines](https://docs.gitlab.com/ee/development/secure_coding_guidelines.html#artificial-intelligence-ai-features)

1. Work estimate and skills needs to build an ML viable feature: To build any ML feature depending on the work, there are many personas that contribute including, Data Scientist, NLP engineer, ML Engineer, MLOps Engineer, ML Infra engineers, and Fullstack engineer to integrate the ML Services with Gitlab. Post-prototype we would assess the skills needed to build a production-grade ML feature for the prototype.
2. Data Limitation: We would like to upfront validate if we have viable data for the feature including whether we can use the DataOps pipeline of ModelOps or create a custom one. We would want to understand the training data, test data, and feedback data to dial up the accuracy and the limitations of the data.
3. Model Limitation: We would want to understand if we can use an open-source pre-trained model, tune and customize it or start a model from scratch as well. Further, we would assess based on the ModelOps model evaluation framework which would be the right model to use based on the use case.
4. Cost, Scalability, Reliability: We would want to estimate the cost of hosting, serving, inference of the model, and the full end-to-end infrastructure including monitoring and observability.
5. Legal and Ethical Framework: We would want to align with legal and ethical framework like any other ModelOps features to cover across the nine principles of responsible ML and any legal support needed.

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
- Slack channels
    - `#wg_ai_integration` - Slack channel for the working group and the high level alignment on getting AI ready for Production (Development, Product, UX, Legal, etc.) But from the other channels fell free to reach out and post progress here
    - `#ai_integration_dev_lobby` - Channel for all implementation related topics and discussions of actual AI features (e.g. explain the code)
    - `#ai_enablement_team` - Channel for the AI Enablement Team which is building the base for all features (experimentation API, Abstraction Layer, Embeddings, etc.)


/label ~wg-ai-integration
/cc @tmccaslin @hbenson @wayne @pedroms @jmandell
/confidential
