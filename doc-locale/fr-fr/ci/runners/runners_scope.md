---
stage: Verify
group: Runner Core
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "Découvrez les types de runners, leur disponibilité et comment les gérer."
title: Gérer les runners
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

GitLab Runner propose les types de runners suivants, disponibles selon les personnes auxquelles vous souhaitez accorder l'accès :

- [Les runners d'instance](#instance-runners) sont disponibles pour tous les groupes et projets d'une instance GitLab.
- [Les runners de groupe](#group-runners) sont disponibles pour tous les projets et sous-groupes d'un groupe.
- [Les runners de projet](#project-runners) sont associés à des projets spécifiques. En général, les runners de projet sont utilisés par un seul projet à la fois.

## Runners d'instance {#instance-runners}

*Les runners d'instance* sont disponibles pour chaque projet d'une instance GitLab.

Utilisez des runners d'instance lorsque vous avez plusieurs jobs avec des exigences similaires. Plutôt que d'avoir plusieurs runners inactifs pour de nombreux projets, vous pouvez avoir quelques runners qui gèrent plusieurs projets.

Si vous utilisez GitLab Self-Managed, les administrateurs peuvent :

- [Installer GitLab Runner](https://docs.gitlab.com/runner/install/) et enregistrer un runner d'instance.
- Configurer un nombre maximum de [minutes de calcul pour chaque groupe](../../administration/cicd/compute_minutes.md#set-the-compute-quota-for-a-group) pour les runners d'instance.

Si vous utilisez GitLab.com :

- Vous pouvez sélectionner dans une liste de [runners d'instance gérés par GitLab](_index.md).
- Les runners d'instance consomment les [minutes de calcul](../pipelines/compute_minutes.md) incluses avec votre compte.

### Créer un runner d'instance avec un token d'authentification de runner {#create-an-instance-runner-with-a-runner-authentication-token}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/383139) dans GitLab 15.10. Déployé derrière le `create_runner_workflow_for_admin` [flag](../../administration/feature_flags/_index.md)
- [Activé par défaut](https://gitlab.com/gitlab-org/gitlab/-/issues/389269) dans GitLab 16.0.
- [Généralement disponible](https://gitlab.com/gitlab-org/gitlab/-/issues/415447) dans GitLab 16.2. L'indicateur de fonctionnalité `create_runner_workflow_for_admin` a été supprimé.

{{< /history >}}

Prérequis :

- Vous devez être un administrateur.

Lorsque vous créez un runner, un token d'authentification de runner lui est attribué, que vous utilisez pour l'enregistrer. Le runner utilise le token pour s'authentifier auprès de GitLab lors de la récupération des jobs dans la file d'attente des jobs.

Pour créer un runner d'instance :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **CI/CD** > **Runners**.
1. Sélectionnez **Créer un runner d'instance**.
1. Sélectionnez le système d'exploitation sur lequel GitLab Runner est installé.
1. Dans la section **Étiquettes**, dans le champ **Étiquettes**, saisissez les étiquettes de job pour spécifier les jobs que le runner peut exécuter. S'il n'y a pas d'étiquettes de job pour ce runner, sélectionnez **Run untagged**.
1. facultatif. Dans le champ **Description du runner**, pour ajouter une description de runner qui s'affiche dans GitLab, saisissez une description de runner.
1. facultatif. Dans la section **Configuration**, ajoutez des configurations supplémentaires.
1. Sélectionnez **Créer un runner**.
1. Suivez les instructions à l'écran pour enregistrer le runner depuis la ligne de commande. Lorsque vous y êtes invité par la ligne de commande :
   - Pour le `GitLab instance URL`, utilisez l'URL de votre instance GitLab. Par exemple, si votre projet est hébergé sur `gitlab.example.com/yourname/yourproject`, l'URL de votre instance GitLab est `https://gitlab.example.com`.
   - Pour le `executor`, entrez le type d'[exécuteur](https://docs.gitlab.com/runner/executors/). L'exécuteur est l'environnement dans lequel le runner exécute le job.

Vous pouvez également [utiliser l'API](../../api/users.md#create-a-runner-linked-to-a-user) pour créer un runner.

> [!note]
> Le token d'authentification du runner s'affiche dans l'interface utilisateur pendant une durée limitée lors de l'enregistrement. Après avoir enregistré le runner, le token d'authentification est stocké dans le fichier `config.toml`.

### Créer un runner d'instance avec un token d'enregistrement (obsolète) {#create-an-instance-runner-with-a-registration-token-deprecated}

> [!warning]
> L'option de transmission des tokens d'enregistrement de runner et la prise en charge de certains arguments de configuration sont considérées comme héritées et ne sont pas recommandées. Utilisez le [workflow de création de runner](https://docs.gitlab.com/runner/register/#register-with-a-runner-authentication-token) pour générer un token d'authentification afin d'enregistrer des runners. Ce processus assure une traçabilité complète de la propriété des runners et renforce la sécurité de votre flotte de runners. Pour plus d'informations, consultez [Migration vers le nouveau workflow d'enregistrement de runner](new_creation_workflow.md).

Prérequis :

- Les tokens d'enregistrement de runner doivent être [activés](../../administration/settings/continuous_integration.md#control-runner-registration) dans la zone **Admin**.
- Vous devez être un administrateur.

Pour créer un runner d'instance :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **CI/CD** > **Runners**.
1. Sélectionnez **Enregistrer un runner d'instance**.
1. Copiez le token d'enregistrement.
1. [Enregistrez le runner](https://docs.gitlab.com/runner/register/#register-with-a-runner-registration-token-legacy).

### Mettre en pause ou reprendre un runner d'instance {#pause-or-resume-an-instance-runner}

Prérequis :

- Vous devez être un administrateur.

Vous pouvez mettre en pause un runner afin qu'il n'accepte pas les jobs des groupes et des projets de l'instance GitLab.

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **CI/CD** > **Runners**.
1. Dans la zone de recherche, saisissez la description du runner ou filtrez la liste des runners.
1. Dans la liste des runners, à droite du runner :
   - Pour mettre en pause le runner, sélectionnez **Pause** ({{< icon name="pause" >}}).
   - Pour reprendre le runner, sélectionnez **Reprendre** ({{< icon name="play" >}}).

### Supprimer des runners d'instance {#delete-instance-runners}

Prérequis :

- Vous devez être un administrateur.

Lorsque vous supprimez un runner d'instance, il est définitivement supprimé de l'instance GitLab et ne peut plus être utilisé par les groupes et les projets. Si vous souhaitez arrêter temporairement le runner d'accepter des jobs, vous pouvez à la place [le mettre en pause](#pause-or-resume-an-instance-runner).

Pour supprimer un ou plusieurs runners d'instance :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **CI/CD** > **Runners**.
1. Dans la zone de recherche, saisissez la description du runner ou filtrez la liste des runners.
1. Supprimez le runner d'instance :
   - Pour supprimer un seul runner, à côté du runner, sélectionnez **Supprimer le runner** ({{< icon name="remove" >}}).
   - Pour supprimer plusieurs runners d'instance, cochez la case de chaque runner et sélectionnez **Supprimer la sélection**.
   - Pour supprimer tous les runners, cochez la case en haut de la liste des runners et sélectionnez **Supprimer la sélection**.
1. Sélectionnez **Supprimer définitivement le runner**.

### Activer les runners d'instance pour un projet {#enable-instance-runners-for-a-project}

Sur GitLab.com, les [runners d'instance](_index.md) sont activés dans tous les projets par défaut.

Sur GitLab Self-Managed, un administrateur peut [les activer pour tous les nouveaux projets](../../administration/settings/continuous_integration.md#enable-instance-runners-for-new-projects).

Pour les projets existants, un administrateur doit [les installer](https://docs.gitlab.com/runner/install/) et [les enregistrer](https://docs.gitlab.com/runner/register/).

Pour activer les runners d'instance pour un projet :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **CI/CD**.
1. Développez **Runners**.
1. Activez le bouton bascule **Activer les runners d'instance pour ce projet**.

### Activer les runners d'instance pour un groupe {#enable-instance-runners-for-a-group}

Pour activer les runners d'instance pour un groupe :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre groupe.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **CI/CD**.
1. Développez **Runners**.
1. Activez le bouton bascule **Turn on instance runners for this group**.

### Désactiver les runners d'instance pour un projet {#disable-instance-runners-for-a-project}

Vous pouvez désactiver les runners d'instance pour des projets individuels ou pour des groupes. Vous devez disposer du rôle Propriétaire pour le projet ou le groupe.

Pour désactiver les runners d'instance pour un projet :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **CI/CD**.
1. Développez **Runners**.
1. Dans la zone **Instance runners**, désactivez le bouton bascule **Turn on runners for this project**.

Les runners d'instance sont automatiquement désactivés pour un projet :

- Si le paramètre des runners d'instance du groupe parent est désactivé, et
- Si la modification de ce paramètre n'est pas autorisée pour les projets.

### Désactiver les runners d'instance pour un groupe {#disable-instance-runners-for-a-group}

Pour désactiver les runners d'instance pour un groupe :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre groupe.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **CI/CD**.
1. Développez **Runners**.
1. Désactivez le bouton bascule **Activer les runners d'instance pour ce groupe**.
1. facultatif. Pour autoriser l'activation des runners d'instance pour des projets ou sous-groupes individuels, sélectionnez **Autoriser les projets et les sous-groupes à outrepasser le paramètre du groupe**.

### Comment les runners d'instance récupèrent les jobs {#how-instance-runners-pick-jobs}

Les runners d'instance traitent les jobs en utilisant une file d'attente à usage équitable. Cette file d'attente empêche les projets de créer des centaines de jobs et d'utiliser toutes les ressources disponibles des runners d'instance.

L'algorithme de file d'attente à usage équitable attribue les jobs en fonction des projets qui ont le moins de jobs déjà en cours d'exécution sur les runners d'instance.

Par exemple, si ces jobs sont dans la file d'attente :

- Job 1 pour le Projet 1
- Job 2 pour le Projet 1
- Job 3 pour le Projet 1
- Job 4 pour le Projet 2
- Job 5 pour le Projet 2
- Job 6 pour le Projet 3

Lorsque plusieurs jobs CI/CD s'exécutent simultanément, l'algorithme à usage équitable attribue les jobs dans cet ordre :

1. Le Job 1 est le premier, car il a le numéro de job le plus bas parmi les projets sans jobs en cours d'exécution (c'est-à-dire tous les projets).
1. Le Job 4 est le suivant, car 4 est désormais le numéro de job le plus bas parmi les projets sans jobs en cours d'exécution (le Projet 1 a un job en cours).
1. Le Job 6 est le suivant, car 6 est désormais le numéro de job le plus bas parmi les projets sans jobs en cours d'exécution (les Projets 1 et 2 ont des jobs en cours).
1. Le Job 2 est le suivant, car parmi les projets ayant le moins de jobs en cours d'exécution (chacun en a 1), c'est le numéro de job le plus bas.
1. Le Job 5 est le suivant, car le Projet 1 a maintenant 2 jobs en cours et le Job 5 est le numéro de job restant le plus bas entre les Projets 2 et 3.
1. Enfin vient le Job 3 car c'est le seul job restant.

Lorsqu'un seul job s'exécute à la fois, l'algorithme à usage équitable attribue les jobs dans cet ordre :

1. Le Job 1 est choisi en premier, car il a le numéro de job le plus bas parmi les projets sans jobs en cours d'exécution (c'est-à-dire tous les projets).
1. Le Job 1 se termine.
1. Le Job 2 est le suivant, car après la fin du Job 1, tous les projets ont à nouveau 0 jobs en cours, et 2 est le numéro de job disponible le plus bas.
1. Le Job 4 est le suivant, car avec le Projet 1 exécutant un job, 4 est le numéro le plus bas parmi les projets n'exécutant aucun job (Projets 2 et 3).
1. Le Job 4 se termine.
1. Le Job 5 est le suivant, car après la fin du Job 4, le Projet 2 n'a à nouveau aucun job en cours.
1. Le Job 6 est le suivant, car le Projet 3 est le seul projet restant sans jobs en cours.
1. Enfin, le Job 3 est le suivant car c'est le seul job restant.

## Runners de groupe {#group-runners}

Utilisez des runners de groupe lorsque vous souhaitez que tous les projets d'un groupe aient accès à une flotte de runners.

Les runners de groupe traitent les jobs en utilisant une file d'attente de type premier entré, premier sorti.

### Créer un runner de groupe avec un token d'authentification de runner {#create-a-group-runner-with-a-runner-authentication-token}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/383143) dans GitLab 15.10. Déployé derrière le `create_runner_workflow_for_namespace` [flag](../../administration/feature_flags/_index.md). Désactivé par défaut.
- [Activé par défaut](https://gitlab.com/gitlab-org/gitlab/-/issues/393919) dans GitLab 16.0.
- [Généralement disponible](https://gitlab.com/gitlab-org/gitlab/-/issues/415447) dans GitLab 16.2. L'indicateur de fonctionnalité `create_runner_workflow_for_admin` a été supprimé.

{{< /history >}}

Prérequis :

- Vous devez avoir le rôle Propriétaire pour le groupe.

Vous pouvez créer un runner de groupe pour GitLab Self-Managed ou pour GitLab.com. Lorsque vous créez un runner, un token d'authentification de runner lui est attribué, que vous utilisez pour l'enregistrer. Le runner utilise le token pour s'authentifier auprès de GitLab lorsqu'il récupère des jobs dans la file d'attente des jobs.

Pour créer un runner de groupe :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre groupe.
1. Dans la barre latérale gauche, sélectionnez **Version** > **Runners**.
1. Sélectionnez **Créer un runner de groupe**.
1. Dans la section **Étiquettes**, dans le champ **Étiquettes**, saisissez les étiquettes de job pour spécifier les jobs que le runner peut exécuter. S'il n'y a pas d'étiquettes de job pour ce runner, sélectionnez **Run untagged**.
1. facultatif. Dans le champ **Description du runner**, ajoutez une description de runner qui s'affiche dans GitLab.
1. facultatif. Dans la section **Configuration**, ajoutez des configurations supplémentaires.
1. Sélectionnez **Créer un runner**.
1. Sélectionnez la plateforme sur laquelle GitLab Runner est installé.
1. Complétez les instructions à l'écran :
   - Pour Linux, macOS et Windows, lorsque vous y êtes invité par la ligne de commande :
     - Pour le `GitLab instance URL`, utilisez l'URL de votre instance GitLab. Par exemple, si votre projet est hébergé sur `gitlab.example.com/yourname/yourproject`, l'URL de votre instance GitLab est `https://gitlab.example.com`.
     - Pour le `executor`, entrez le type d'[exécuteur](https://docs.gitlab.com/runner/executors/). L'exécuteur est l'environnement dans lequel le runner exécute le job.
   - Pour Google Cloud, consultez [Provisionnement des runners dans Google Cloud](provision_runners_google_cloud.md).

Vous pouvez également [utiliser l'API](../../api/users.md#create-a-runner-linked-to-a-user) pour créer un runner.

> [!note]
> Le token d'authentification du runner s'affiche dans l'interface utilisateur pendant une courte période seulement lors de l'enregistrement.

### Créer un runner de groupe avec un token d'enregistrement (obsolète) {#create-a-group-runner-with-a-registration-token-deprecated}

{{< history >}}

- Chemin modifié depuis **Paramètres** > **CI/CD** > **Runners**.

{{< /history >}}

> [!warning]
> L'option de transmission des tokens d'enregistrement de runner et la prise en charge de certains arguments de configuration sont considérées comme héritées et ne sont pas recommandées. Utilisez le [workflow de création de runner](https://docs.gitlab.com/runner/register/#register-with-a-runner-authentication-token) pour générer un token d'authentification afin d'enregistrer des runners. Ce processus assure une traçabilité complète de la propriété des runners et renforce la sécurité de votre flotte de runners. Pour plus d'informations, consultez [Migration vers le nouveau workflow d'enregistrement de runner](new_creation_workflow.md).

Prérequis :

- Les tokens d'enregistrement de runner doivent être [activés](#enable-use-of-runner-registration-tokens-in-projects-and-groups) dans le groupe principal.
- Vous devez avoir le rôle Propriétaire pour le groupe.

Pour créer un runner de groupe :

1. [Installez GitLab Runner](https://docs.gitlab.com/runner/install/).
1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre groupe.
1. Dans la barre latérale gauche, sélectionnez **Version** > **Runners**.
1. Dans le coin supérieur droit, sélectionnez **Enregistrer un runner de groupe**.
1. Sélectionnez **Afficher les instructions d'installation et d'enregistrement de runner**. Ces instructions incluent le token, l'URL et une commande pour enregistrer un runner.

Vous pouvez également copier le token d'enregistrement et suivre la documentation sur la façon d'[enregistrer un runner](https://docs.gitlab.com/runner/register/#register-with-a-runner-registration-token-legacy).

### Afficher les runners de groupe {#view-group-runners}

{{< history >}}

- Possibilité pour les utilisateurs disposant du rôle Responsable de visualiser les runners de groupe [introduite](https://gitlab.com/gitlab-org/gitlab/-/issues/384179) dans GitLab 16.4.

{{< /history >}}

Prérequis :

- Vous devez disposer du rôle Responsable ou Propriétaire pour le groupe.

Vous pouvez afficher tous les runners d'un groupe, de ses sous-groupes et de ses projets. Vous pouvez effectuer cette opération pour GitLab Self-Managed ou pour GitLab.com.

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre groupe.
1. Dans la barre latérale gauche, sélectionnez **Version** > **Runners**.

#### Filtrer les runners de groupe pour n'afficher que les runners hérités {#filter-group-runners-to-show-only-inherited}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/337838/) dans GitLab 15.5.
- [Généralement disponible](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/101099) dans GitLab 15.5. L'indicateur de fonctionnalité `runners_finder_all_available` a été supprimé.

{{< /history >}}

Vous pouvez choisir d'afficher tous les runners dans la liste, ou d'afficher uniquement ceux qui sont hérités de l'instance ou d'autres groupes.

Par défaut, seuls les runners hérités sont affichés.

Pour afficher tous les runners disponibles dans l'instance, y compris les runners d'instance et ceux des autres groupes :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre groupe.
1. Dans la barre latérale gauche, sélectionnez **Version** > **Runners**.
1. Au-dessus de la liste, désactivez le bouton bascule **N'afficher que ceux hérités**.

### Mettre en pause ou reprendre un runner de groupe {#pause-or-resume-a-group-runner}

Prérequis :

- Vous devez être administrateur ou disposer du rôle Propriétaire pour le groupe.

Vous pouvez mettre en pause un runner afin qu'il n'accepte pas les jobs des sous-groupes et des projets de l'instance GitLab. Si vous mettez en pause un runner de groupe utilisé par plusieurs projets, le runner est mis en pause pour tous les projets.

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre groupe.
1. Dans la barre latérale gauche, sélectionnez **Version** > **Runners**.
1. Dans la zone de recherche, saisissez la description du runner ou filtrez la liste des runners.
1. Dans la liste des runners, à droite du runner :
   - Pour mettre en pause le runner, sélectionnez **Pause** ({{< icon name="pause" >}}).
   - Pour reprendre le runner, sélectionnez **Reprendre** ({{< icon name="play" >}}).

### Supprimer un runner de groupe {#delete-a-group-runner}

{{< history >}}

- Suppression de plusieurs runners [introduite](https://gitlab.com/gitlab-org/gitlab/-/issues/361721/) dans GitLab 15.6.

{{< /history >}}

Prérequis :

- Vous devez être administrateur ou disposer du rôle Propriétaire pour le groupe.

Lorsque vous supprimez un runner de groupe, il est définitivement supprimé de l'instance GitLab et ne peut plus être utilisé par les sous-groupes et les projets. Si vous souhaitez arrêter temporairement le runner d'accepter des jobs, vous pouvez à la place [le mettre en pause](#pause-or-resume-a-group-runner).

Pour supprimer un ou plusieurs runners de groupe :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre groupe.
1. Dans la barre latérale gauche, sélectionnez **Version** > **Runners**.
1. Dans la zone de recherche, saisissez la description du runner ou filtrez la liste des runners.
1. Supprimez le runner de groupe :
   - Pour supprimer un seul runner, à côté du runner, sélectionnez **Supprimer le runner** ({{< icon name="remove" >}}).
   - Pour supprimer plusieurs runners d'instance, cochez la case de chaque runner et sélectionnez **Supprimer la sélection**.
   - Pour supprimer tous les runners, cochez la case en haut de la liste des runners et sélectionnez **Supprimer la sélection**.
1. Sélectionnez **Supprimer définitivement le runner**.

### Nettoyer les runners de groupe périmés {#clean-up-stale-group-runners}

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/363012) dans GitLab 15.1.

{{< /history >}}

Prérequis :

- Vous devez avoir le rôle Propriétaire pour le groupe.

Vous pouvez nettoyer les runners de groupe qui ont été inactifs pendant plus de sept jours.

Les runners de groupe sont ceux qui ont été créés dans un groupe spécifique.

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre groupe.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **CI/CD**.
1. Développez **Runners**.
1. Activez le bouton bascule **Activer le nettoyage des runners périmés**.

#### Afficher les journaux de nettoyage des runners périmés {#view-stale-runner-cleanup-logs}

Vous pouvez consulter les [journaux Sidekiq](../../administration/logs/_index.md#sidekiq-logs) pour voir le résultat du nettoyage. Dans Kibana, vous pouvez utiliser la requête suivante :

```json
{
  "query": {
    "match_phrase": {
      "json.class.keyword": "Ci::Runners::StaleGroupRunnersPruneCronWorker"
    }
  }
}
```

Filtrez les entrées où les runners périmés ont été supprimés :

```json
{
  "query": {
    "range": {
      "json.extra.ci_runners_stale_group_runners_prune_cron_worker.total_pruned": {
        "gte": 1,
        "lt": null
      }
    }
  }
}
```

## Runners de projet {#project-runners}

Utilisez des runners de projet lorsque vous souhaitez utiliser des runners pour des projets spécifiques. Par exemple, lorsque vous avez :

- Des jobs avec des exigences spécifiques, comme un job de déploiement nécessitant des identifiants.
- Des projets avec beaucoup d'activité CI pouvant bénéficier d'une séparation des autres runners.

Vous pouvez configurer un runner de projet pour qu'il soit utilisé par plusieurs projets. Les runners de projet doivent être activés explicitement pour chaque projet.

Les runners de projet traitent les jobs en utilisant une file d'attente de type premier entré, premier sorti ([FIFO](https://en.wikipedia.org/wiki/FIFO_(computing_and_electronics))).

> [!note]
> Les runners de projet ne sont pas automatiquement associés aux projets dupliqués. Une duplication copie bien les paramètres CI/CD du dépôt cloné.

### Propriété du runner de projet {#project-runner-ownership}

Lorsqu'un runner se connecte pour la première fois à un projet, ce projet devient le propriétaire du runner.

Si vous supprimez le projet propriétaire :

1. GitLab trouve tous les autres projets qui partagent le runner.
1. GitLab attribue la propriété au projet ayant l'association la plus ancienne.
1. Si aucun autre projet ne partage le runner, GitLab supprime automatiquement le runner.

Vous ne pouvez pas désassigner un runner du projet propriétaire. Supprimez plutôt le runner.

### Créer un runner de projet avec un token d'authentification de runner {#create-a-project-runner-with-a-runner-authentication-token}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/383143) dans GitLab 15.10. Déployé derrière le `create_runner_workflow_for_namespace` [flag](../../administration/feature_flags/_index.md). Désactivé par défaut.
- [Activé par défaut](https://gitlab.com/gitlab-org/gitlab/-/issues/393919) dans GitLab 16.0.
- [Généralement disponible](https://gitlab.com/gitlab-org/gitlab/-/issues/415447) dans GitLab 16.2. L'indicateur de fonctionnalité `create_runner_workflow_for_admin` a été supprimé.

{{< /history >}}

Prérequis :

- Vous devez avoir le rôle Maintainer pour le projet.

Vous pouvez créer un runner de projet pour GitLab Self-Managed ou pour GitLab.com. Lorsque vous créez un runner, un token d'authentification de runner lui est attribué, que vous utilisez pour vous enregistrer auprès du runner. Le runner utilise le token pour s'authentifier auprès de GitLab lorsqu'il récupère des jobs dans la file d'attente des jobs.

Pour créer un runner de projet :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **CI/CD**.
1. Développez la section **Runners**.
1. Sélectionnez **Créer un runner de projet**.
1. Sélectionnez le système d'exploitation sur lequel GitLab Runner est installé.
1. Dans la section **Étiquettes**, dans le champ **Étiquettes**, saisissez les étiquettes de job pour spécifier les jobs que le runner peut exécuter. S'il n'y a pas d'étiquettes de job pour ce runner, sélectionnez **Run untagged**.
1. facultatif. Dans le champ **Description du runner**, ajoutez une description pour le runner qui s'affiche dans GitLab.
1. facultatif. Dans la section **Configuration**, ajoutez des configurations supplémentaires.
1. Sélectionnez **Créer un runner**.
1. Sélectionnez la plateforme sur laquelle GitLab Runner est installé.
1. Complétez les instructions à l'écran :
   - Pour Linux, macOS et Windows, lorsque vous y êtes invité par la ligne de commande :
     - Pour le `GitLab instance URL`, utilisez l'URL de votre instance GitLab. Par exemple, si votre projet est hébergé sur `gitlab.example.com/yourname/yourproject`, l'URL de votre instance GitLab est `https://gitlab.example.com`.
     - Pour le `executor`, entrez le type d'[exécuteur](https://docs.gitlab.com/runner/executors/). L'exécuteur est l'environnement dans lequel le runner exécute le job.
   - Pour Google Cloud, consultez [Provisionnement des runners dans Google Cloud](provision_runners_google_cloud.md).

Vous pouvez également [utiliser l'API](../../api/users.md#create-a-runner-linked-to-a-user) pour créer un runner.

> [!note]
> Le token d'authentification du runner s'affiche dans l'interface utilisateur pendant une courte période seulement lors de l'enregistrement.

### Créer un runner de projet avec un token d'enregistrement (obsolète) {#create-a-project-runner-with-a-registration-token-deprecated}

> [!warning]
> L'option de transmission des tokens d'enregistrement de runner et la prise en charge de certains arguments de configuration sont considérées comme héritées et ne sont pas recommandées. Utilisez le [workflow de création de runner](https://docs.gitlab.com/runner/register/#register-with-a-runner-authentication-token) pour générer un token d'authentification afin d'enregistrer des runners. Ce processus assure une traçabilité complète de la propriété des runners et renforce la sécurité de votre flotte de runners. Pour plus d'informations, consultez [Migration vers le nouveau workflow d'enregistrement de runner](new_creation_workflow.md).

Prérequis :

- Les tokens d'enregistrement de runner doivent être [activés](#enable-use-of-runner-registration-tokens-in-projects-and-groups) dans le groupe principal.
- Vous devez avoir le rôle Maintainer ou Owner pour le projet.

Pour créer un runner de projet :

1. [Installez GitLab Runner](https://docs.gitlab.com/runner/install/).
1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **CI/CD**.
1. Développez **Runners**.
1. Dans la section **Project runners**, notez l'URL et le token.
1. [Enregistrez le runner](https://docs.gitlab.com/runner/register/#register-with-a-runner-registration-token-legacy).

Le runner est maintenant activé pour le projet.

### Mettre en pause ou reprendre un runner de projet {#pause-or-resume-a-project-runner}

Prérequis :

- Vous devez être administrateur ou disposer du rôle Responsable pour le projet.

Vous pouvez mettre en pause un runner de projet afin qu'il n'accepte pas les jobs des projets auxquels il est assigné dans l'instance GitLab.

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **CI/CD**.
1. Développez **Runners**.
1. Dans la section **Runners de projet assignés**, trouvez le runner.
1. À droite du runner :
   - Pour mettre en pause le runner, sélectionnez **Pause** ({{< icon name="pause" >}}), puis sélectionnez **Pause**.
   - Pour reprendre le runner, sélectionnez **Reprendre** ({{< icon name="play" >}}).

### Supprimer un runner de projet {#delete-a-project-runner}

Prérequis :

- Vous devez être administrateur ou disposer du rôle Responsable pour le projet.
- Vous ne pouvez pas supprimer un runner de projet assigné à plus d'un projet. Avant de pouvoir supprimer le runner, vous devez le [désactiver](#enable-a-project-runner-for-a-different-project) dans tous les projets où il est activé.

Lorsque vous supprimez un runner de projet, il est définitivement supprimé de l'instance GitLab et ne peut plus être utilisé par les projets. Si vous souhaitez arrêter temporairement le runner d'accepter des jobs, vous pouvez à la place [le mettre en pause](#pause-or-resume-a-project-runner).

Lorsque vous supprimez un runner, sa configuration existe toujours dans le fichier `config.toml` de l'hôte du runner. Si la configuration du runner supprimé est toujours présente dans ce fichier, l'hôte du runner continue de contacter GitLab. Pour éviter un trafic API inutile, vous devez également [désinscrire le runner supprimé](https://docs.gitlab.com/runner/commands/#gitlab-runner-unregister).

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez le projet.
1. Sélectionnez **Paramètres** > **CI/CD**.
1. Développez **Runners**.
1. Dans la section **Runners de projet assignés**, trouvez le runner.
1. À droite du runner, sélectionnez **Remove runner**.
1. Pour supprimer le runner, sélectionnez **Supprimer**.

### Activer un runner de projet pour un autre projet {#enable-a-project-runner-for-a-different-project}

Une fois un runner de projet créé, vous pouvez l'activer pour d'autres projets.

Prérequis : Vous devez disposer du rôle Responsable ou Propriétaire pour :

- Le projet pour lequel le runner est déjà activé.
- Le projet pour lequel vous souhaitez activer le runner.
- Le runner de projet ne doit pas être [verrouillé](#prevent-a-project-runner-from-being-enabled-for-other-projects).

Pour activer un runner de projet pour un projet :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **CI/CD**.
1. Développez **Runners**.
1. Dans la zone **Project runners**, à côté du runner souhaité, sélectionnez **Enable for this project**.

Vous pouvez modifier un runner de projet depuis n'importe lequel des projets pour lesquels il est activé. Les modifications, qui incluent le déverrouillage et la modification des étiquettes et de la description, affectent tous les projets qui utilisent le runner.

Un administrateur peut [activer le runner pour plusieurs projets](../../administration/settings/continuous_integration.md#share-project-runners-with-multiple-projects).

### Empêcher l'activation d'un runner de projet pour d'autres projets {#prevent-a-project-runner-from-being-enabled-for-other-projects}

Vous pouvez configurer un runner de projet afin qu'il soit « verrouillé » et ne puisse pas être activé pour d'autres projets. Ce paramètre peut être activé lors du premier [enregistrement d'un runner](https://docs.gitlab.com/runner/register/), mais peut également être modifié ultérieurement.

Pour verrouiller ou déverrouiller un runner de projet :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **CI/CD**.
1. Développez **Runners**.
1. Trouvez le runner de projet que vous souhaitez verrouiller ou déverrouiller. Assurez-vous qu'il est activé. Vous ne pouvez pas verrouiller les runners d'instance ou les runners de groupe.
1. Sélectionnez **Éditer** ({{< icon name="pencil" >}}).
1. Cochez la case **Verrouiller aux projets en cours**.
1. Sélectionnez **Sauvegarder les modifications**.

## Statuts des runners {#runner-statuses}

Un runner peut avoir l'un des statuts suivants.

| Statut  | Description |
|---------|-------------|
| `online`  | Le runner a contacté GitLab au cours des 2 dernières heures et est disponible pour exécuter des jobs. |
| `offline` | Le runner n'a pas contacté GitLab depuis plus de 2 heures et n'est pas disponible pour exécuter des jobs. Vérifiez le runner pour voir si vous pouvez le remettre en ligne. |
| `stale`   | Le runner n'a pas contacté GitLab depuis plus de 7 jours. Si le runner a été créé il y a plus de 7 jours, mais n'a jamais contacté l'instance, il est également considéré comme **stale**. |
| `never_contacted` | Le runner n'a jamais contacté GitLab. Pour que le runner contacte GitLab, exécutez `gitlab-runner run`. |

## Nettoyage du gestionnaire de runners périmés {#stale-runner-manager-cleanup}

GitLab supprime régulièrement les gestionnaires de runners périmés pour maintenir une base de données légère. Si un runner contacte l'instance GitLab, la connexion est recréée.

## Afficher les statistiques de performance des runners {#view-statistics-for-runner-performance}

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/377963) dans GitLab 15.8.

{{< /history >}}

En tant qu'administrateur, vous pouvez consulter les statistiques des runners pour en savoir plus sur les performances de votre flotte de runners.

La valeur **Median job queued time** est calculée en échantillonnant la durée d'attente dans la file des 100 jobs les plus récents exécutés par les runners d'instance. Seuls les jobs des 5 000 runners les plus récents sont pris en compte.

La médiane est une valeur qui correspond au 50e percentile. La moitié des jobs attendent plus longtemps que la valeur médiane, et l'autre moitié attend moins longtemps que la valeur médiane.

Pour afficher les statistiques des runners :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **CI/CD** > **Runners**.
1. Sélectionnez **Voir les métriques**.

## Déterminer quels runners doivent être mis à niveau {#determine-which-runners-need-to-be-upgraded}

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/365078) dans GitLab 15.3.

{{< /history >}}

Prérequis :

- Accès administrateur pour afficher les runners d'instance.
- Le rôle Responsable ou Propriétaire pour afficher les runners de groupe.

La version de GitLab Runner utilisée par vos runners doit être [maintenue à jour](https://docs.gitlab.com/runner/#gitlab-runner-versions).

Pour déterminer quels runners doivent être mis à niveau :

1. Affichez la liste des runners :
   - Pour un groupe :
     1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre groupe.
     1. Sélectionnez **Version** > **Runners**.
   - Pour l'instance :
     1. Dans le coin supérieur droit, sélectionnez **Admin**.
     1. Sélectionnez **CI/CD** > **Runners**.

1. Au-dessus de la liste des runners, consultez le statut :
   - **Outdated - recommended** : Le runner ne dispose pas de la dernière version `PATCH`, ce qui peut le rendre vulnérable à des failles de sécurité ou à des bugs de haute gravité. Ou bien, le runner est en retard d'une ou plusieurs versions `MAJOR` par rapport à votre instance GitLab, de sorte que certaines fonctionnalités peuvent ne pas être disponibles ou ne pas fonctionner correctement.
   - **Outdated - available** : Des versions plus récentes sont disponibles, mais la mise à niveau n'est pas critique.

1. Filtrez la liste par statut pour voir quels runners individuels doivent être mis à niveau.

## Déterminer l'adresse IP d'un runner {#determine-the-ip-address-of-a-runner}

Pour résoudre les problèmes liés aux runners, vous devrez peut-être connaître l'adresse IP du runner. GitLab stocke et affiche l'adresse IP en consultant la source des requêtes HTTP lorsque le runner interroge pour obtenir des jobs. GitLab met automatiquement à jour l'adresse IP du runner chaque fois qu'elle est mise à jour.

L'adresse IP des runners d'instance et des runners de projet peut être trouvée à différents endroits.

### Déterminer l'adresse IP d'un runner d'instance {#determine-the-ip-address-of-an-instance-runner}

Prérequis :

- Vous devez avoir un accès administrateur à l'instance.

Pour déterminer l'adresse IP d'un runner d'instance :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **CI/CD** > **Runners**.
1. Trouvez le runner dans le tableau et consultez la colonne **Adresse IP**.

![Zone d'administration affichant la colonne d'adresse IP pour un runner d'instance](img/shared_runner_ip_address_v14_5.png)

### Déterminer l'adresse IP d'un runner de projet {#determine-the-ip-address-of-a-project-runner}

Pour trouver l'adresse IP d'un runner pour un projet, vous devez disposer du rôle Propriétaire pour le projet.

1. Accédez aux **Paramètres** > **CI/CD** du projet et développez la section **Runners**.
1. Sélectionnez le nom du runner et trouvez la ligne **Adresse IP**.

![Page de détails du runner affichant le champ d'adresse IP pour un runner de projet](img/project_runner_ip_address_v17_6.png)

## Ajouter des notes de maintenance à la configuration du runner {#add-maintenance-notes-to-runner-configuration}

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Introduit pour les administrateurs](https://gitlab.com/gitlab-org/gitlab/-/issues/348299) dans GitLab 15.1.
- [Rendu disponible pour les groupes et les projets](https://gitlab.com/gitlab-org/gitlab/-/issues/422621) dans GitLab 18.2.

{{< /history >}}

Vous pouvez ajouter une note de maintenance pour documenter le runner. Les utilisateurs pouvant modifier le runner voient la note lorsqu'ils consultent les détails du runner.

Utilisez cette fonctionnalité pour informer les autres des conséquences ou des problèmes liés à la modification de la configuration du runner.

## Activer l'utilisation des tokens d'enregistrement de runner dans les projets et les groupes {#enable-use-of-runner-registration-tokens-in-projects-and-groups}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/148557) dans GitLab 16.11

{{< /history >}}

> [!warning]
> L'option de transmission des tokens d'enregistrement de runner et la prise en charge de certains arguments de configuration sont considérées comme héritées et ne sont pas recommandées. Utilisez le [workflow de création de runner](https://docs.gitlab.com/runner/register/#register-with-a-runner-authentication-token) pour générer un token d'authentification afin d'enregistrer des runners. Ce processus assure une traçabilité complète de la propriété des runners et renforce la sécurité de votre flotte de runners. Pour plus d'informations, consultez [Migration vers le nouveau workflow d'enregistrement de runner](new_creation_workflow.md).

Dans GitLab 17.0, l'utilisation des tokens d'enregistrement de runner est désactivée dans toutes les instances GitLab.

Prérequis :

- Les tokens d'enregistrement de runner doivent être [activés](../../administration/settings/continuous_integration.md#control-runner-registration) dans la zone **Admin**.

Pour activer l'utilisation du token d'enregistrement de runner dans les projets et les groupes :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre groupe.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **CI/CD**.
1. Développez **Runners**.
1. Activez le bouton bascule **Permettre aux membres de projets et de groupes de créer des runners avec des tokens d'enregistrement de runner**.
