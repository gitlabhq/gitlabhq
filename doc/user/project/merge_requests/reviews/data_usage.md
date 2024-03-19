---
stage: AI-powered
group: AI Model Validation
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Suggested Reviewers Data Usage

DETAILS:
**Tier:** Ultimate
**Offering:** GitLab.com

## How it works

GitLab Duo Suggested Reviewers is the first user-facing GitLab machine learning (ML) powered feature. It leverages a project's contribution graph to generate suggestions. This data already exists within GitLab including merge request metadata, source code files, and GitLab user account metadata.

### Enabling the feature

When a Project Maintainer or Owner enables Suggested Reviewers in project settings, GitLab kicks off a data extraction job for the project which leverages the Merge Request API to understand pattern of review including recency, domain experience, and frequency to suggest an appropriate reviewer. If projects do not use the [merge request approval process](../approvals/index.md) or do not have any historical merge request data, Suggested Reviewers cannot suggest reviewers.

This data extraction job can take a few hours to complete (possibly up to a day), which is largely dependent on the size of the project. The process is automated and no action is needed during this process. Once data extraction is complete, you start getting suggestions in merge requests.

### Generating suggestions

Once Suggested Reviewers is enabled and the data extraction is complete, new merge requests or new commits to existing merge requests automatically trigger a Suggested Reviewers ML model inference and generate up to 5 suggested reviewers. These suggestions are contextual to the changes in the merge request. Additional commits to merge requests may change the reviewer suggestions, which are automatically updated in the reviewer dropdown list.

## Progressive enhancement

This feature is designed as a progressive enhancement to the existing GitLab Reviewers functionality. The GitLab Reviewer UI only offers suggestions if the ML engine is able to provide a recommendation. In the event of an issue or model inference failure, the feature gracefully degrades. At no point with the usage of Suggested Reviewers prevent a user from being able to manually set a reviewer.

## Model Accuracy

Organizations use many different processes for code review. Some focus on senior engineers reviewing junior engineer's code, others have hierarchical organizational structure based reviews. Suggested Reviewers is focused on contextual reviewers based on historical merge request activity by users. While we continue evolving the underlying ML model to better serve various code review use cases and processes Suggested Reviewers does not replace the usage of other code review features like Code Owners and [Approval Rules](../approvals/rules.md). Reviewer selection is highly subjective therefore, we do not expect Suggested Reviewers to provide perfect suggestions every time.

Through analysis of beta customer usage, we find that the Suggested Reviewers ML model provides suggestions that are adopted in 60% of cases. We plan to introduce a feedback mechanism into the Suggested Reviewers feature in the future to allow users to flag bad reviewer suggestions to help improve the model. Additionally we plan to offer an opt-in feature in the future which allows the model to use your project's data for training the underlying model.

## Off by default

Suggested Reviewers is off by default and requires a Project Owner or Admin to enable the feature.

## Data privacy

Suggested Reviewers operates completely within the GitLab.com infrastructure providing the same level of [privacy](https://about.gitlab.com/privacy/) and [security](https://about.gitlab.com/security/) of any other feature of GitLab.com.

No new additional data is collected to enable this feature. GitLab infers your merge request against a trained machine learning model. The content of your source code is not used as training data. Your data also never leaves GitLab.com, all training and inference is done within GitLab.com infrastructure.

[Read more about the security of GitLab.com](https://about.gitlab.com/security/faq/)
