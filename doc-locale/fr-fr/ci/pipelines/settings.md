---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Personnaliser la configuration du pipeline
description: "Configurez les paramètres de pipeline pour la visibilité, les délais d'attente, la stratégie Git, le comportement d'annulation automatique et le nettoyage automatique."
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Vous pouvez personnaliser la façon dont les pipelines s'exécutent pour votre projet.

## Modifier les utilisateurs qui peuvent voir vos pipelines {#change-which-users-can-view-your-pipelines}

Pour les projets publics et internes, vous pouvez modifier qui peut voir vos :

- Pipelines
- Journaux de sortie de job
- Artefacts de job
- [Résultats de sécurité du pipeline](../../user/application_security/detect/security_scanning_results.md)

Pour modifier la visibilité de vos pipelines et des fonctionnalités associées :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **CI/CD**.
1. Développez **Pipelines généraux**.
1. Cochez ou décochez la case **Visibilité du pipeline basée sur les projets**. Lorsqu'elle est cochée, les pipelines et les fonctionnalités associées sont visibles :

   - Pour les projets [**Public**](../../user/public_access.md), par tout le monde.
   - Pour les projets **Interne**, par tous les utilisateurs authentifiés, à l'exception des [utilisateurs externes](../../administration/external_users.md).
   - Pour les projets **Privé**, par tous les membres du projet (Invité ou supérieur).

   Lorsqu'elle est décochée :

   - Pour les projets **Public**, les job logs, les artefacts de job, le tableau de bord de sécurité du pipeline et les éléments de menu **CI/CD** ne sont visibles que par les membres du projet (Reporter ou supérieur). Les autres utilisateurs, y compris les utilisateurs invités, ne peuvent consulter que le statut des pipelines et des jobs, et uniquement lors de la consultation des merge requests ou des commits.
   - Pour les projets **Interne**, les pipelines sont visibles par tous les utilisateurs authentifiés, à l'exception des [utilisateurs externes](../../administration/external_users.md). Les fonctionnalités associées ne sont visibles que par les membres du projet (Reporter ou supérieur).
   - Pour les projets **Privé**, les pipelines et les fonctionnalités associées ne sont visibles que par les membres du projet (Reporter ou supérieur).

### Modifier la visibilité des pipelines pour les non-membres dans les projets publics {#change-pipeline-visibility-for-non-project-members-in-public-projects}

Vous pouvez contrôler la visibilité des pipelines pour les non-membres du projet dans les [projets publics](../../user/public_access.md).

Ce paramètre n'a aucun effet lorsque :

- La visibilité du projet est définie sur [**Interne** ou **Privé**](../../user/public_access.md), car les non-membres du projet ne peuvent pas accéder aux projets internes ou privés.
- Le paramètre [**Visibilité du pipeline basée sur les projets**](#change-which-users-can-view-your-pipelines) est désactivé.

Pour modifier la visibilité des pipelines pour les non-membres du projet :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Général**.
1. Développez **Visibilité, fonctionnalités du projet, autorisations**.
1. Pour **CI/CD**, choisissez :
   - **Uniquement les membres du projet** : Seuls les membres du projet peuvent voir les pipelines.
   - **Toute personne ayant accès** : Les non-membres du projet peuvent également voir les pipelines.
1. Sélectionnez **Sauvegarder les modifications**.

Le [tableau des autorisations CI/CD](../../user/permissions.md#project-cicd) répertorie les fonctionnalités de pipeline auxquelles les non-membres du projet peuvent accéder lorsque **Toute personne ayant accès** est sélectionné.

## Annulation automatique des pipelines redondants {#auto-cancel-redundant-pipelines}

Vous pouvez configurer l'annulation automatique des pipelines en attente ou en cours d'exécution lorsqu'un pipeline pour de nouvelles modifications s'exécute sur la même branche. Vous pouvez activer cette option dans les paramètres du projet :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **CI/CD**.
1. Développez **Pipelines généraux**.
1. Cochez la case **Annulation automatique des pipelines redondants**.
1. Sélectionnez **Sauvegarder les modifications**.

Utilisez le mot-clé [`interruptible`](../yaml/_index.md#interruptible) pour indiquer si un job en cours d'exécution peut être annulé avant la fin de son exécution. Une fois qu'un job avec `interruptible: false` démarre, l'ensemble du pipeline n'est plus considéré comme interruptible.

## Empêcher les jobs de déploiement obsolètes {#prevent-outdated-deployment-jobs}

Votre projet peut avoir plusieurs jobs de déploiement simultanés planifiés pour s'exécuter dans le même délai.

Cela peut conduire à une situation où un ancien job de déploiement s'exécute après un plus récent, ce qui n'est peut-être pas ce que vous souhaitez.

Pour éviter ce scénario :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **CI/CD**.
1. Développez **Pipelines généraux**.
1. Cochez la case **Empêcher les jobs de déploiement obsolètes**.
1. Facultatif. Décochez la case **Autoriser les tentatives de job pour les déploiements de retours en arrière**.
1. Sélectionnez **Sauvegarder les modifications**.

Pour plus d'informations, consultez [Sécurité du déploiement](../environments/deployment_safety.md#prevent-outdated-deployment-jobs).

## Restreindre les rôles pouvant annuler des pipelines ou des jobs {#restrict-roles-that-can-cancel-pipelines-or-jobs}

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Vous pouvez personnaliser les rôles autorisés à annuler des pipelines ou des jobs.

Par défaut, les utilisateurs disposant du rôle Developer, Maintainer ou Owner peuvent annuler des pipelines ou des jobs. Vous pouvez restreindre l'autorisation d'annulation aux seuls utilisateurs disposant du rôle Maintainer ou Owner, ou empêcher complètement l'annulation de tout pipeline ou job.

Pour modifier les autorisations d'annulation des pipelines ou des jobs :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **CI/CD**.
1. Développez **Pipelines généraux**.
1. Sélectionnez une option dans **Rôle minimum requis pour annuler un pipeline ou un job**.
1. Sélectionnez **Sauvegarder les modifications**.

## Spécifier un fichier de configuration CI/CD personnalisé {#specify-a-custom-cicd-configuration-file}

GitLab s'attend à trouver le fichier de configuration CI/CD (`.gitlab-ci.yml`) dans le répertoire racine du projet. Cependant, vous pouvez spécifier un autre chemin de nom de fichier, y compris des emplacements extérieurs au projet.

Pour personnaliser le chemin :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **CI/CD**.
1. Développez **Pipelines généraux**.
1. Dans le champ **Fichier de configuration CI/CD**, saisissez le nom du fichier. Si le fichier :
   - Ne se trouve pas dans le répertoire racine, incluez le chemin.
   - Se trouve dans un projet différent, incluez le nom du groupe et du projet.
   - Se trouve sur un site externe, saisissez l'URL complète.
1. Sélectionnez **Sauvegarder les modifications**.

> [!note]
> Vous ne pouvez pas utiliser l'[éditeur de pipeline](../pipeline_editor/_index.md) de votre projet pour modifier des fichiers de configuration CI/CD dans d'autres projets ou sur un site externe.

### Exemples de fichiers de configuration CI/CD personnalisés {#custom-cicd-configuration-file-examples}

Si le fichier de configuration CI/CD ne se trouve pas dans le répertoire racine, le chemin doit être relatif à celui-ci. Par exemple :

- `my/path/.gitlab-ci.yml`
- `my/path/.my-custom-file.yml`

Si le fichier de configuration CI/CD se trouve sur un site externe, l'URL doit se terminer par `.yml` :

- `http://example.com/generate/ci/config.yml`

Si le fichier de configuration CI/CD se trouve dans un projet différent :

- Le fichier doit exister sur sa branche par défaut, ou spécifiez la branche comme refname.
- Le chemin doit être relatif au répertoire racine dans l'autre projet.
- Le chemin doit être suivi d'un symbole `@` et du chemin complet du groupe et du projet.

Par exemple :

- `.gitlab-ci.yml@namespace/another-project`
- `my/path/.my-custom-file.yml@namespace/subgroup/another-project`
- `my/path/.my-custom-file.yml@namespace/subgroup1/subgroup2/another-project:refname`

Si le fichier de configuration se trouve dans un projet distinct, vous pouvez définir des autorisations plus granulaires. Par exemple :

- Créez un projet public pour héberger le fichier de configuration.
- Accordez des autorisations d'écriture sur le projet uniquement aux utilisateurs autorisés à modifier le fichier.

Les autres utilisateurs et projets peuvent alors accéder au fichier de configuration sans pouvoir le modifier.

## Choisir la stratégie Git par défaut {#choose-the-default-git-strategy}

Vous pouvez choisir la façon dont votre dépôt est récupéré depuis GitLab lors de l'exécution d'un job.

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **CI/CD**.
1. Développez **Pipelines généraux**.
1. Sous **Stratégie Git**, sélectionnez une option :
   - `git clone` est plus lent car il clone le dépôt depuis le début pour chaque job. Cependant, la copie de travail locale est toujours intacte.
   - `git fetch` est plus rapide car il réutilise la copie de travail locale (et revient au clone si elle n'existe pas). Cette option est recommandée, en particulier pour les [grands dépôts](../../user/project/repository/monorepos/_index.md#use-git-fetch-in-cicd-operations).

La stratégie Git configurée peut être remplacée par la [variable `GIT_STRATEGY`](../runners/configure_runners.md#git-strategy) dans le fichier `.gitlab-ci.yml`.

## Limiter le nombre de modifications récupérées lors du clonage {#limit-the-number-of-changes-fetched-during-clone}

Vous pouvez limiter le nombre de modifications que GitLab CI/CD récupère lors du clonage d'un dépôt.

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **CI/CD**.
1. Développez **Pipelines généraux**.
1. Sous **Stratégie Git**, sous **Clone Git superficiel**, saisissez une valeur. La valeur maximale est `1000`. Pour désactiver le clone superficiel et faire en sorte que GitLab CI/CD récupère toutes les branches et tous les tags à chaque fois, laissez la valeur vide ou définissez-la sur `0`.

Les projets nouvellement créés ont une valeur `git depth` par défaut de `20`.

Cette valeur peut être remplacée par la [variable `GIT_DEPTH`](../../user/project/repository/monorepos/_index.md#use-shallow-clones-and-filters-in-cicd-processes) dans le fichier `.gitlab-ci.yml`.

## Définir une limite pour la durée d'exécution des jobs {#set-a-limit-for-how-long-jobs-can-run}

Vous pouvez définir la durée pendant laquelle un job peut s'exécuter avant d'expirer.

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **CI/CD**.
1. Développez **Pipelines généraux**.
1. Dans le champ **Délai d'attente**, saisissez le nombre de minutes ou une valeur lisible telle que `2 hours`. La durée doit être d'au moins 10 minutes et inférieure à un mois. La valeur par défaut est de 60 minutes. Les jobs en attente sont abandonnés après 24 heures d'inactivité.

Les jobs qui dépassent le délai d'attente sont marqués comme ayant échoué.

Lorsqu'un délai d'attente de projet et un [délai d'attente de runner](../runners/configure_runners.md#set-the-maximum-job-timeout) sont tous deux définis, la valeur la plus faible est prioritaire.

Les jobs sans sortie pendant une heure sont abandonnés, quel que soit le délai d'attente. Pour éviter que cela se produise, ajoutez un script pour afficher en continu la progression. Pour plus d'informations, consultez le [ticket 25359](https://gitlab.com/gitlab-org/gitlab/-/issues/25359#workaround).

## Badges de pipeline {#pipeline-badges}

Vous pouvez utiliser des [badges de pipeline](../../user/project/badges.md) pour indiquer le statut du pipeline et la couverture des tests de vos projets. Ces badges sont déterminés par le dernier pipeline réussi.

## Désactiver les pipelines GitLab CI/CD {#disable-gitlab-cicd-pipelines}

Les pipelines GitLab CI/CD sont activés par défaut sur tous les nouveaux projets. Si vous utilisez un serveur CI/CD externe comme Jenkins ou Drone CI, vous pouvez désactiver GitLab CI/CD pour éviter les conflits avec l'API de statut des commits.

Vous pouvez désactiver GitLab CI/CD par projet ou [pour tous les nouveaux projets d'une instance](../../administration/cicd/_index.md).

Lorsque vous désactivez GitLab CI/CD :

- L'élément **CI/CD** dans la barre latérale gauche est supprimé.
- Les pages `/pipelines` et `/jobs` ne sont plus disponibles.
- Les jobs et pipelines existants sont masqués, et non supprimés.

Pour désactiver GitLab CI/CD dans votre projet :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Général**.
1. Développez **Visibilité, fonctionnalités du projet, autorisations**.
1. Dans la section **Dépôt**, désactivez **CI/CD**.
1. Sélectionnez **Sauvegarder les modifications**.

Ces modifications ne s'appliquent pas aux projets faisant partie d'une [intégration externe](../../user/project/integrations/_index.md#available-integrations).

## Nettoyage de pipeline automatique {#automatic-pipeline-cleanup}

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/498969) dans GitLab 17.7 [avec un flag](../../administration/feature_flags/_index.md) nommé `ci_delete_old_pipelines`. Désactivé par défaut.
- [Feature flag `ci_delete_old_pipelines`](https://gitlab.com/gitlab-org/gitlab/-/issues/503153) supprimé dans GitLab 17.9.

{{< /history >}}

Définissez une période de rétention pour faciliter la gestion du stockage des pipelines et améliorer les performances du système. Les pipelines plus anciens que la durée configurée sont supprimés automatiquement par un job en arrière-plan. Le nettoyage s'exécute périodiquement en arrière-plan, et non immédiatement lorsqu'un pipeline devient éligible. Les projets présentant un grand arriéré d'anciens pipelines sont nettoyés progressivement au fil de plusieurs exécutions.

Lorsqu'un pipeline est supprimé, ses jobs, job logs et artefacts sont également définitivement supprimés. Tous les pipelines plus anciens que la période de rétention configurée sont éligibles à la suppression, quel que soit leur statut ou s'ils constituent le pipeline le plus récent pour une branche ou un tag donné.

Prérequis :

- Le rôle Owner pour le projet.

Pour configurer le nettoyage de pipeline automatique :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **CI/CD**.
1. Développez **Pipelines généraux**.
1. Dans le champ **Nettoyage de pipeline automatique**, saisissez une durée, par exemple `2 weeks` ou `30 days`. La valeur doit être d'au moins un jour et ne pas dépasser le maximum de l'instance (1 an par défaut). Laissez ce champ vide pour ne jamais supprimer automatiquement les pipelines.
1. Sélectionnez **Sauvegarder les modifications**.

Pour GitLab Self-Managed, les administrateurs peuvent augmenter la limite supérieure pour le [nettoyage de pipeline automatique](../../administration/cicd/limits.md#maximum-retention-period-for-automatic-pipeline-cleanup).
