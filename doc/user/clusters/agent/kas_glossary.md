---
stage: Deploy
group: Environments
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Kubernetes integration glossary **(FREE ALL)**

This glossary provides definitions for terms related to the GitLab Kubernetes integration.

| Term | Definition | Scope |
| --- | --- | --- |
| GitLab agent for Kubernetes | The overall offering, including related features and the underlying components `agentk` and `kas`. | GitLab, Kubernetes, Flux |
| `agentk` | The cluster-side component that maintains a secure connection to GitLab for Kubernetes management and deployment automation. | GitLab |
| GitLab agent server for Kubernetes (`kas`) | The GitLab-side component of GitLab that handles operations and logic for the Kubernetes agent integration. Manages the connection and communication between GitLab and Kubernetes clusters. | GitLab |
| Pull-based deployment | A deployment method where Flux checks for changes in a Git repository and automatically applies these changes to the cluster. | GitLab, Kubernetes |
| Push-based deployment | A deployment method where updates are sent from GitLab CI/CD pipelines to the Kubernetes cluster. | GitLab |
| Flux | An open-source GitOps tool that integrates with the agent for pull-based deployments. | GitOps, Kubernetes |
| GitOps | A set of practices that involve using Git for version control and collaboration in the management and automation of cloud and Kubernetes resources. | DevOps, Kubernetes |
| Kubernetes namespace | A logical partition in a Kubernetes cluster that divides cluster resources between multiple users or environments. | Kubernetes |
