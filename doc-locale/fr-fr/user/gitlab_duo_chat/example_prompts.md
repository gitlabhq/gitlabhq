---
stage: AI Clients
group: Duo Chat
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Exemples de prompts GitLab Duo Chat
---

GitLab Duo Agentic Chat peut vous aider à répondre aux questions qui nécessitent des informations provenant de plusieurs fichiers ou ressources GitLab. Il peut répondre aux questions sur votre base de code, et vous n'avez pas besoin de spécifier les chemins de fichiers exacts. Il peut également comprendre le statut des tickets ou des merge requests, ainsi que créer et modifier des fichiers.

## En savoir plus sur vos projets {#learn-more-about-your-projects}

GitLab Duo Chat fonctionne de manière optimale avec des questions en langage naturel. Interrogez-le sur n'importe quel aspect de votre projet, du général au spécifique.

- `Read the project structure and explain it to me`, ou `Explain the project`.
- `Find the API endpoints that handle user authentication in this codebase`.
- `Please explain the authorization flow for <application name>`.
- `How do I add a GraphQL mutation in this repository?`
- `Show me how error handling is implemented across our application`.
- `Component <component name> has methods for <x> and <y>. Could you split it into two components?`
- `Do merge request <MR URL> and merge request <MR URL> fully address this issue <issue URL>?`

## Laisser Chat effectuer le travail à votre place {#have-chat-do-the-work-for-you}

Si vous savez déjà ce que vous souhaitez faire, Chat peut effectuer le travail à votre place.

- `Add a GraphQL mutation that lets users query my application.`
- `Implement error handling for my application`.
- `Component <component name> has methods for <x> and <y>. Split it into two components.`
- `Add inline documentation for all Java files in <directory>.`
- `Create a merge request to address this issue: <issue URL>.`

## Utiliser Chat pour traiter les vulnérabilités de sécurité {#use-chat-to-address-security-vulnerabilities}

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Dedicated

{{< /details >}}

Utilisez Chat pour trier, gérer et remédier aux vulnérabilités grâce à des commandes en langage naturel.

Pour les informations et l'analyse des vulnérabilités :

- `List all vulnerabilities in a project with filtering by severity and report types.`
- `Get detailed vulnerability information including CVE data, EPSS scores, and reachability analysis.`
- `Show me all critical vulnerabilities in my project.`
- `List vulnerabilities with EPSS scores above 0.7 that are reachable.`

Pour la gestion des vulnérabilités :

- `Mark this vulnerability as a genuine security issue.`
- `Revert vulnerability status back to detected for re-assessment.`
- `Dismiss all dependency scanning vulnerabilities marked as false positives with unreachable code.`
- `Show me vulnerabilities dismissed in the past week with their reasoning.`
- `Confirm all container scanning vulnerabilities with known exploits.`
- `Link vulnerability 123 to issue 456 for tracking remediation.`

Pour l'intégration de la gestion des tickets :

- `Create issues for all confirmed high-severity SAST vulnerabilities and assign them to recent committers.`
- `Update severity to HIGH for all vulnerabilities that cross trust boundaries.`

Pour plus d'informations sur les fonctionnalités de sécurité, consultez [l'epic 19639](https://gitlab.com/groups/gitlab-org/-/epics/19639).
