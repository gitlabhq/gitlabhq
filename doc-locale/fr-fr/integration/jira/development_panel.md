---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Panneau de développement Jira
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Vous pouvez utiliser le panneau de développement Jira pour afficher l'activité GitLab pour un ticket Jira directement dans Jira. Pour configurer le panneau de développement Jira :

- **Pour Jira Cloud**, utilisez l'[application GitLab for Jira Cloud](connect-app.md) développée et maintenue par GitLab.
- **Pour Jira Data Center ou Jira Server**, utilisez le [connecteur Jira DVCS](dvcs/_index.md) développé et maintenu par Atlassian.

<i class="fa-youtube-play" aria-hidden="true"></i> Pour une présentation générale, consultez [Intégration du panneau de développement Jira](https://www.youtube.com/watch?v=VjVTOmMl85M).

## Disponibilité des fonctionnalités {#feature-availability}

{{< history >}}

- Possibilité de supprimer des branches [introduite](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/148712) dans GitLab 17.1 [avec un feature flag](../../administration/feature_flags/_index.md) nommé `jira_connect_remove_branches`. Désactivée par défaut.
- Possibilité de supprimer des branches rendue [généralement disponible](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/158224) dans GitLab 17.2. Feature flag `jira_connect_remove_branches` supprimé.

{{< /history >}}

Ce tableau présente les fonctionnalités disponibles avec le connecteur Jira DVCS et l'application GitLab for Jira Cloud :

| Fonctionnalité                              | Connecteur Jira DVCS | Application GitLab for Jira Cloud |
|:-------------------------------------|:--------------------|:--------------------------|
| Smart Commits                        | {{< yes >}}         | {{< yes >}}               |
| Synchroniser les merge requests                  | {{< yes >}}         | {{< yes >}}               |
| Synchroniser les branches                        | {{< yes >}}         | {{< yes >}}               |
| Synchroniser les commits                         | {{< yes >}}         | {{< yes >}}               |
| Synchroniser les données existantes                   | {{< yes >}}         | {{< yes >}} (voir [Données GitLab synchronisées avec Jira](connect-app.md#gitlab-data-synced-to-jira)) |
| Synchroniser les builds                          | {{< no >}}          | {{< yes >}}               |
| Synchroniser les déploiements                     | {{< no >}}          | {{< yes >}}               |
| Synchroniser les feature flags                   | {{< no >}}          | {{< yes >}}               |
| Intervalle de synchronisation                        | Jusqu'à 60 minutes    | Temps réel                 |
| Supprimer des branches                      | {{< no >}}          | {{< yes >}}               |
| Créer une merge request depuis une branche | {{< yes >}}         | {{< yes >}}               |
| Créer une branche depuis un ticket Jira    | {{< no >}}          | {{< yes >}}               |

## Projets connectés dans GitLab {#connected-projects-in-gitlab}

Le panneau de développement Jira connecte une instance Jira avec tous ses projets aux éléments suivants :

- **Pour l'[application GitLab for Jira Cloud](connect-app.md)**, les groupes ou sous-groupes GitLab liés et leurs projets
- **Pour le [connecteur Jira DVCS](dvcs/_index.md)**, les groupes, sous-groupes ou espaces de nommage personnels GitLab liés et leurs projets

## Informations affichées dans le panneau de développement {#information-displayed-in-the-development-panel}

Vous pouvez [afficher l'activité GitLab pour un ticket Jira](https://support.atlassian.com/jira-software-cloud/docs/view-development-information-for-an-issue/) dans le panneau de développement Jira en faisant référence au ticket Jira par son identifiant dans GitLab. Les informations affichées dans le panneau de développement dépendent de l'endroit où vous mentionnez l'identifiant du ticket Jira dans GitLab.

Pour l'[application GitLab for Jira Cloud](connect-app.md), les informations suivantes sont affichées.

| GitLab : où vous mentionnez l'identifiant du ticket Jira | Panneau de développement Jira : quelles informations sont affichées |
|---------------------------------------------|-------------------------------------------------------|
| Titre ou description de la merge request          | Lien vers la merge request<br>Lien vers le déploiement<br>Lien vers le pipeline via le titre de la merge request<br>Lien vers le pipeline via la description de la merge request ([introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/390888) dans GitLab 15.10)<br>Lien vers la branche ([introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/354373) dans GitLab 15.11)<br>Informations sur le relecteur et statut d'approbation ([introduites](https://gitlab.com/gitlab-org/gitlab/-/issues/364273) dans GitLab 16.5) |
| Nom de la branche                                 | Lien vers la branche<br>Lien vers le déploiement          |
| Message de commit                              | Lien vers le commit<br>Lien vers le déploiement à partir de 2 000 commits maximum après le dernier déploiement réussi dans l'environnement <sup>1</sup> <sup>2</sup> |
| [Jira Smart Commit](#jira-smart-commits)    | Commentaire personnalisé, temps enregistré ou transition de workflow   |

**Notes de bas de page** :

1. [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/300031) dans GitLab 16.2 [avec un feature flag](../../administration/feature_flags/_index.md) nommé `jira_deployment_issue_keys`. Activé par défaut.
1. [Généralement disponible](https://gitlab.com/gitlab-org/gitlab/-/issues/415025) dans GitLab 16.3. Feature flag `jira_deployment_issue_keys` supprimé.

## Jira Smart Commits {#jira-smart-commits}

Prérequis :

- Vous devez disposer de comptes utilisateur GitLab et Jira avec la même adresse e-mail ou le même nom d'utilisateur.
- Les commandes doivent se trouver sur la première ligne du message de commit.
- Le message de commit ne doit pas s'étendre sur plus d'une ligne.

Les Jira Smart Commits sont des commandes spéciales permettant de traiter un ticket Jira. Grâce à ces commandes, vous pouvez utiliser GitLab pour :

- Ajouter un commentaire personnalisé à un ticket Jira.
- Enregistrer du temps sur un ticket Jira.
- Faire passer un ticket Jira à n'importe quel statut défini dans le workflow du projet.

Les Smart Commits doivent suivre cette syntaxe :

```plaintext
<ISSUE_KEY> <ignored text> #<command> <optional command parameters>
```

Vous pouvez exécuter une ou plusieurs commandes dans un seul commit.

### Syntaxe des Smart Commits {#smart-commit-syntax}

| Commandes                                        | Syntaxe                                                       |
|-------------------------------------------------|--------------------------------------------------------------|
| Ajouter un commentaire                                   | `KEY-123 #comment Bug is fixed`                              |
| Enregistrer du temps                                        | `KEY-123 #time 2w 4d 10h 52m Tracking work time`             |
| Fermer un ticket                                  | `KEY-123 #close Closing issue`                               |
| Enregistrer du temps et fermer un ticket                     | `KEY-123 #time 2d 5h #close`                                 |
| Ajouter un commentaire et passer à **In-progress** | `KEY-123 #comment Started working on the issue #in-progress` |

Pour plus d'informations sur le fonctionnement des Smart Commits et sur les commandes disponibles, consultez :

- [Traitement des tickets avec les Smart Commits](https://support.atlassian.com/jira-software-cloud/docs/process-issues-with-smart-commits/)
- [Utilisation des Smart Commits](https://confluence.atlassian.com/fisheye/using-smart-commits-960155400.html)

## Déploiements Jira {#jira-deployments}

Vous pouvez utiliser les déploiements Jira pour suivre et visualiser la progression des releases de logiciels directement dans Jira.

GitLab envoie des informations sur vos environnements et déploiements à Jira si :

- Le fichier `.gitlab-ci.yml` de votre projet contient le mot-clé [`environment`](../../ci/yaml/_index.md#environment).
- Un identifiant de ticket Jira est [mentionné dans certaines parties de GitLab](#information-displayed-in-the-development-panel) et un pipeline est déclenché.

Pour plus d'informations, consultez [les environnements et les déploiements](../../ci/environments/_index.md).

## Sujets connexes {#related-topics}

- [Résoudre les problèmes du panneau de développement dans Jira Server](https://confluence.atlassian.com/jirakb/troubleshoot-the-development-panel-in-jira-server-574685212.html)
