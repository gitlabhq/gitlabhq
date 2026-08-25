---
stage: Solutions Architecture
group: Solutions Architecture
info: This page is owned by the Solutions Architecture team.
description: "Présentation de la solution GitLab de séparation des tâches utilisant le contrôle d'accès basé sur les rôles, y compris les composants clés, les workflows et les capacités d'audit."
title: Guide du tutoriel GitLab sur la séparation des tâches
---

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Ce document fournit une présentation de la solution GitLab de séparation des tâches (SoD) à travers le contrôle d'accès basé sur les rôles (RBAC). La solution garantit la conformité aux principes de sécurité en empêchant toute personne d'avoir un contrôle total sur les processus critiques du cycle de vie du développement logiciel.

## Premiers pas {#getting-started}

### Accéder au composant de la solution {#access-the-solution-component}

1. Obtenez le code d'invitation auprès de votre équipe de compte.
1. Accédez au composant de la solution depuis [la boutique en ligne du composant de la solution](https://cloud.gitlab-accelerator-marketplace.com) en utilisant votre code d'invitation.

## Qu'est-ce que la séparation des tâches {#what-is-separation-of-duties}

La séparation des tâches est un principe de sécurité fondamental qui garantit qu'aucune personne n'a un contrôle total sur les processus critiques. Dans le développement logiciel, la SoD empêche les releases de code non autorisées ou accidentelles dans les environnements de production en distribuant les responsabilités entre différents rôles et équipes.

L'approche GitLab pour implémenter la SoD via le contrôle d'accès basé sur les rôles (RBAC) fournit :

- Une séparation claire entre les rôles de développement et de déploiement
- Des environnements protégés pour contrôler l'accès au déploiement
- Des branches protégées pour empêcher les modifications de code non autorisées
- Des politiques d'approbation des merge requests pour imposer la revue de code
- Des capacités d'audit intégrées pour la vérification de la conformité

## Composants clés de la solution GitLab SoD {#key-components-of-gitlab-sod-solution}

### Contrôle d'accès basé sur les rôles (RBAC) {#role-based-access-control-rbac}

Le RBAC constitue le cadre de mise en œuvre et d'application de la SoD. Il régit les permissions et les responsabilités sur l'ensemble de la plateforme, garantissant la conformité aux principes du moindre privilège. Grâce au RBAC, les organisations peuvent :

- Mettre en œuvre une gestion globale des utilisateurs avec des contrôles granulaires basés sur les rôles
- Attribuer des rôles selon les principes d'accès au moindre privilège
- Maintenir la visibilité sur les rôles et les permissions grâce à l'audit et aux rapports

### Workflow de branche de fonctionnalité {#feature-branch-workflow}

Le workflow de branche de fonctionnalité soutient la SoD en définissant des limites claires entre les activités de développement et le déploiement en production :

- Les équipes de développement peuvent modifier le code et déclencher des pipelines de test dans les branches de fonctionnalité
- Les équipes de sécurité gèrent les politiques d'approbation pour les portes de qualité
- Les merge requests nécessitent une revue indépendante de la part de non-auteurs

### Branches & Environnements protégés {#protected-branches--environments}

La branche par défaut joue un rôle clé dans l'application de la SoD :

- Les environnements protégés limitent les déploiements aux équipes désignées
- Les équipes de déploiement ont la permission d'exécuter des déploiements, mais ne peuvent pas modifier le code source
- Les branches protégées empêchent les fusions et les pushs non autorisés

### Capacités d'audit et de conformité {#audit--compliance-capabilities}

GitLab fournit de solides capacités d'audit pour répondre aux exigences de conformité :

- Preuve de release générée automatiquement
- Journalisation des événements pour les activités de la branche par défaut

### Prérequis {#prerequisites}

Pour mettre pleinement en œuvre la solution GitLab SoD, les organisations ont besoin :

- Licence GitLab Ultimate
- Des pipelines CI/CD correctement configurés
- Des groupes d'utilisateurs avec une séparation claire entre les rôles de développement et de déploiement

### Ressources supplémentaires {#additional-resources}

Pour plus d'informations sur la mise en œuvre de la SoD GitLab, consultez :

- [Documentation sur les rôles et les permissions GitLab](../../user/permissions.md)
- [Documentation sur les branches protégées](../../user/project/repository/branches/protected.md)
- [Documentation sur les environnements protégés](../../ci/environments/protected_environments.md)
- [Documentation sur les approbations de merge requests](../../user/project/merge_requests/approvals/_index.md)
