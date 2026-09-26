---
stage: AI Coding
group: Code Review
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "Fonctionnalités et caractéristiques natives de l'IA."
title: Fonctionnalités non agentiques de GitLab Duo
---

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Module d'extension : GitLab Duo Pro ou Enterprise
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Les fonctionnalités suivantes sont généralement disponibles sur GitLab.com, GitLab Self-Managed et GitLab Dedicated. Elles nécessitent un abonnement Premium ou Ultimate et l'un des modules complémentaires disponibles.

Les fonctionnalités GitLab Duo with Amazon Q sont disponibles en tant que module complémentaire distinct et sont disponibles uniquement sur GitLab Self-Managed.

| Fonctionnalité | GitLab Duo Pro | GitLab Duo Enterprise | GitLab Duo with Amazon Q |
|---------|----------------|----------------------|--------------------------|
| [Code Suggestions](../project/repository/code_suggestions/_index.md) <sup>1</sup> | {{< yes >}} | {{< yes >}} | {{< yes >}} |
| [GitLab Duo Non-Agentic Chat](../gitlab_duo_chat/_index.md) | {{< yes >}} | {{< yes >}} | {{< yes >}} |
| [Code Explanation](../gitlab_duo_chat/examples.md#explain-selected-code) dans les IDE | {{< yes >}} | {{< yes >}} | {{< yes >}} |
| [Refactor Code](../gitlab_duo_chat/examples.md#refactor-code-in-the-ide) dans les IDE | {{< yes >}} | {{< yes >}} | {{< yes >}} |
| [Fix Code](../gitlab_duo_chat/examples.md#fix-code-in-the-ide) dans les IDE | {{< yes >}} | {{< yes >}} | {{< yes >}} |
| [Test Generation](../gitlab_duo_chat/examples.md#write-tests-in-the-ide) dans les IDE | {{< yes >}} | {{< yes >}} | {{< yes >}} |
| [Code Explanation](../project/repository/code_explain.md) dans l'interface GitLab | {{< yes >}} | {{< yes >}} | {{< yes >}} |
| [Discussion Summary](../discussions/_index.md#summarize-issue-discussions-with-gitlab-duo-chat) | {{< no >}} | {{< yes >}} | {{< yes >}} |
| [Code Review](code_review.md) <sup>2</sup> | {{< no >}} | {{< yes >}} | {{< yes >}} |
| [Root Cause Analysis](../gitlab_duo_chat/examples.md#troubleshoot-failed-cicd-jobs-with-root-cause-analysis) | {{< no >}} | {{< yes >}} | {{< yes >}} |
| [Vulnerability Explanation](../application_security/analyze/duo.md) | {{< no >}} | {{< yes >}} | {{< yes >}} |
| [Résolution des vulnérabilités](../application_security/remediate/duo.md) | {{< no >}} | {{< yes >}} | {{< yes >}} |
| [Merge Commit Message Generation](../project/merge_requests/duo_in_merge_requests.md#generate-a-merge-commit-message) | {{< no >}} | {{< yes >}} | {{< yes >}} |

**Notes de bas de page** :

1. Code Suggestions est également disponible dans le cadre de la plateforme GitLab Duo Agent Platform, sans module complémentaire supplémentaire.
1. Amazon Q prend en charge une version différente de cette fonctionnalité. [Découvrir comment utiliser Amazon Q pour effectuer une revue de code](../duo_amazon_q/_index.md#review-a-merge-request).

## Fonctionnalités en version bêta et expérimentale {#beta-and-experimental-features}

Les fonctionnalités suivantes ne sont pas encore généralement disponibles.

Elles nécessitent un abonnement Premium ou Ultimate et le module complémentaire GitLab Duo Enterprise.

| Fonctionnalité | GitLab Duo Pro | GitLab Duo Enterprise | GitLab Duo with Amazon Q |
|---------|----------------|----------------------|--------------------------|
| [Merge Request Summary](../project/merge_requests/duo_in_merge_requests.md#generate-a-description-by-summarizing-code-changes) | {{< no >}} | {{< yes >}} | {{< no >}} |
| [Code Review Summary](../project/merge_requests/duo_in_merge_requests.md#summarize-a-code-review) | {{< no >}} | {{< yes >}} | {{< no >}} |
| [Issue Description Generation](../project/issues/managing_issues.md#populate-an-issue-with-issue-description-generation) | {{< no >}} | {{< yes >}} | {{< no >}} |

## Fonctionnalités disponibles dans GitLab Duo Self-Hosted {#features-available-in-gitlab-duo-self-hosted}

Votre organisation peut héberger elle-même ses modèles de langage.

Pour savoir quelles fonctionnalités GitLab Duo sont disponibles avec GitLab Duo Self-Hosted, consultez la [liste des fonctionnalités prises en charge](../../administration/gitlab_duo_self_hosted/_index.md#feature-versions-and-status).

## Amazon Q Developer Pro inclus avec GitLab Duo With Amazon Q {#amazon-q-developer-pro-included-with-gitlab-duo-with-amazon-q}

Les crédits de licence pour [Amazon Q Developer Pro](https://aws.amazon.com/q/developer/) sont inclus avec un abonnement à GitLab Duo with Amazon Q.

Cet abonnement inclut l'accès au chat agentique et aux outils de ligne de commande, notamment :

- [Amazon Q Developer dans l'IDE](https://docs.aws.amazon.com/amazonq/latest/qdeveloper-ug/q-in-IDE.html), notamment Visual Studio, VS Code, JetBrains et Eclipse.
- [Amazon Q Developer en ligne de commande](https://docs.aws.amazon.com/amazonq/latest/qdeveloper-ug/command-line.html).
- [Amazon Q Developer dans la console de gestion AWS](https://aws.amazon.com/q/developer/operate/).

Pour plus d'informations sur les capacités d'Amazon Q Developer, consultez le [site web AWS](https://aws.amazon.com/q/developer/).
