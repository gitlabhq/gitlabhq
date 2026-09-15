---
stage: Solutions Architecture
group: Solutions Architecture
info: This page is owned by the Solutions Architecture team.
description: "Guide d'intégration de Snyk avec GitLab CI/CD pour la sécurité des applications, incluant la configuration du workflow, l'analyse SARIF et le reporting des vulnérabilités."
title: Workflow de sécurité des applications GitLab intégré avec Snyk
---

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

## Premiers pas {#getting-started}

### Télécharger le composant de solution {#download-the-solution-component}

1. Obtenez le code d'invitation auprès de votre équipe de compte.
1. Téléchargez le composant de solution depuis [la boutique en ligne de composants de solution](https://cloud.gitlab-accelerator-marketplace.com) en utilisant votre code d'invitation.

## Intégration Snyk {#snyk-integration}

Il s'agit d'une intégration entre Snyk et GitLab CI via un composant CI/CD GitLab.

## Workflow Snyk {#snyk-workflow}

Ce projet dispose d'un composant qui exécute le CLI Snyk et génère le rapport d'analyse au format SARIF. Il appelle un composant distinct qui convertit le SARIF au format d'enregistrement de vulnérabilité GitLab en utilisant un job basé sur l'image de base semgrep.

Un conteneur versionné dans le registre de conteneurs dispose d'une image de base node avec le CLI Snyk installé par-dessus. Il s'agit de l'image utilisée dans le job du composant Snyk. Le fichier `.gitlab-ci.yml` génère l'image de conteneur, effectue les tests et versionne le composant.

### Versionnage {#versioning}

Ce projet suit la gestion sémantique de version.
