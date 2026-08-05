---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "Calculs, quotas, informations d'achat."
title: Minutes de calcul
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

L'utilisation des runners d'instance par les projets exécutant des jobs CI/CD est mesurée en minutes de calcul.

Pour certains types d'installation, votre [espace de nommage](../../user/namespace/_index.md) dispose d'un [quota de calcul](instance_runner_compute_minutes.md#compute-quota-enforcement), qui limite les minutes de calcul disponibles que vous pouvez utiliser.

Un quota de calcul peut être appliqué à tous les [runners d'instance gérés par l'administrateur](instance_runner_compute_minutes.md) :

- Tous les runners d'instance sur GitLab.com ou GitLab Self-Managed
- Tous les runners d'instance auto-hébergés sur GitLab Dedicated

Le quota de calcul est désactivé par défaut, mais peut être activé pour les groupes principaux et les espaces de nommage utilisateur. Sur GitLab.com, le quota est activé par défaut pour limiter l'utilisation sur les espaces de nommage Gratuite. La limite est augmentée si un abonnement payant est souscrit.

Les runners d'instance hébergés par GitLab sur GitLab Dedicated ne peuvent pas se voir appliquer le quota de calcul des runners d'instance.

## Runners d'instance {#instance-runners}

Pour les runners d'instance sur GitLab.com, GitLab Self-Managed et les runners d'instance auto-hébergés sur GitLab Dedicated :

- Vous pouvez consulter votre utilisation dans le [tableau de bord d'utilisation des runners d'instance](instance_runner_compute_minutes.md#view-usage).
- Lorsqu'un quota est activé :
  - Vous recevez des notifications lorsque vous approchez de vos limites de quota.
  - Des mesures d'application sont appliquées lorsque vous dépassez votre quota.

Pour GitLab.com :

- Le quota de calcul mensuel de base est déterminé par votre édition d'abonnement. Les espaces de nommage de l'édition Gratuite reçoivent 400 minutes de calcul par mois. Les éditions payantes reçoivent un quota mensuel plus élevé.
- Vous pouvez [acheter des minutes de calcul supplémentaires](../../subscriptions/gitlab_com/compute_minutes.md) si vous en avez besoin.

## Utilisation des minutes de calcul {#compute-minute-usage}

### Calcul de l'utilisation des ressources de calcul {#compute-usage-calculation}

L'utilisation des minutes de calcul pour chaque job est calculée à l'aide de cette formule :

```plaintext
Job duration / 60 * Cost factor
```

- **Job duration** : Le temps, en secondes, qu'un job a mis pour s'exécuter, sans inclure le temps passé dans les statuts `created` ou `pending`.
- **Cost factor** : Un nombre basé sur le [type de runner](#cost-factors) et le [type de projet](#cost-factors).

La valeur est convertie en minutes de calcul et ajoutée au décompte des unités utilisées dans l'espace de nommage de niveau supérieur du job.

Par exemple, si un utilisateur `alice` exécute un pipeline :

- Dans un projet de l'espace de nommage `gitlab-org`, les minutes de calcul utilisées par chaque job dans le pipeline sont ajoutées à l'utilisation globale de l'espace de nommage `gitlab-org`, et non de l'espace de nommage `alice`.
- Dans un projet personnel dans leur espace de nommage `alice`, les minutes de calcul sont ajoutées à l'utilisation globale de leur espace de nommage.

Les ressources de calcul utilisées par un pipeline correspondent au total des minutes de calcul utilisées par tous les jobs qui se sont exécutés dans le pipeline. Les jobs peuvent s'exécuter simultanément, de sorte que l'utilisation totale des ressources de calcul peut être supérieure à la durée de bout en bout d'un pipeline.

Les [jobs de déclenchement](../yaml/_index.md#trigger) ne s'exécutent pas sur des runners, ils ne consomment donc pas de minutes de calcul, même lors de l'utilisation de [`strategy:depend`](../yaml/_index.md#triggerstrategy) pour attendre le statut du [pipeline downstream](downstream_pipelines.md). Le pipeline downstream déclenché consomme des minutes de calcul de la même manière que les autres pipelines.

L'utilisation est suivie sur une base mensuelle. Le premier jour du mois, l'utilisation est `0` pour ce mois pour tous les espaces de nommage.

### Facteurs de coût {#cost-factors}

Le taux auquel les minutes de calcul sont consommées varie en fonction du type de runner et des paramètres du projet.

#### Facteurs de coût des runners hébergés pour GitLab.com {#cost-factors-of-hosted-runners-for-gitlabcom}

Les runners hébergés par GitLab ont des facteurs de coût différents selon le type de runner (Linux, Windows, macOS) et la configuration de la machine virtuelle :

| Type de runner                | Taille de la machine           | Facteur de coût             |
|:---------------------------|:-----------------------|:------------------------|
| Linux x86-64 (par défaut)     | `small`                | `1`                     |
| Linux x86-64               | `medium`               | `2`                     |
| Linux x86-64               | `large`                | `3`                     |
| Linux x86-64               | `xlarge`               | `6`                     |
| Linux x86-64               | `2xlarge`              | `12`                    |
| Linux x86-64 + GPU activé | `medium`, GPU standard | `7`                     |
| Linux Arm64                | `small`                | `1`                     |
| Linux Arm64                | `medium`               | `2`                     |
| Linux Arm64                | `large`                | `3`                     |
| macOS M1                   | `medium`               | `6` (**Statut** : Bêta)  |
| macOS M2 Pro               | `large`                | `12` (**Statut** : Bêta) |
| Windows                    | `medium`               | `1` (**Statut** : Bêta)  |

Ces facteurs de coût s'appliquent aux runners hébergés pour GitLab.com.

Certaines remises s'appliquent en fonction du type de projet :

| Type de projet | Facteur de coût | Minutes de calcul utilisées |
|--------------|-------------|---------------------|
| Projets standard | [Basé sur le type de runner](#cost-factors-of-hosted-runners-for-gitlabcom) | 1 minute par (durée du job / 60 × facteur de coût) |
| Projets publics dans le [programme GitLab for Open Source](../../subscriptions/community_programs.md#gitlab-for-open-source) | `0.5` | 1 minute par 2 minutes de temps de job |
| Duplications publiques de [projets du programme GitLab Open Source](../../subscriptions/community_programs.md#gitlab-for-open-source) | `0.008` | 1 minute par 125 minutes de temps de job |
| [Contributions de la communauté aux projets GitLab](#community-contributions-to-gitlab-projects) | Remise dynamique | Voir la section suivante |

#### Contributions de la communauté aux projets GitLab {#community-contributions-to-gitlab-projects}

Les contributeurs de la communauté peuvent utiliser jusqu'à 300 000 minutes sur les runners d'instance lorsqu'ils contribuent à des projets open source gérés par GitLab. Le maximum de 300 000 minutes ne serait possible qu'en contribuant exclusivement à des projets faisant partie du produit GitLab.

Le nombre total de minutes disponibles sur les runners d'instance est réduit par les minutes de calcul utilisées par les pipelines d'autres projets. Les 300 000 minutes s'appliquent à toutes les éditions de GitLab.com.

Le calcul du facteur de coût est le suivant :

- `Monthly compute quota / 300,000 job duration minutes = Cost factor`

Par exemple, avec un quota de calcul mensuel de 10 000 pour l'édition GitLab Premium :

- 10 000 / 300 000 = 0,03333333333 facteur de coût.

Pour ce facteur de coût réduit :

- Le projet source de la merge request doit être une duplication d'un projet géré par GitLab, tel que [`gitlab-com/www-gitlab-com`](https://gitlab.com/gitlab-com/www-gitlab-com) ou [`gitlab-org/gitlab`](https://gitlab.com/gitlab-org/gitlab).
- Le projet cible de la merge request doit être le projet parent de la duplication.
- Le pipeline doit être un pipeline de merge request, de résultats fusionnés ou de merge train.

### Réduire l'utilisation des minutes de calcul {#reduce-compute-minute-usage}

Si votre projet consomme trop de minutes de calcul, essayez ces stratégies pour réduire votre utilisation :

- Si vous utilisez des miroirs de projet, assurez-vous que les [pipelines pour les mises à jour de miroir](../../user/project/repository/mirror/pull.md#trigger-pipelines-for-mirror-updates) sont désactivés.
- Réduisez la fréquence des [pipelines planifiés](schedules.md).
- [Ignorez les pipelines](_index.md#skip-a-pipeline) si nécessaire.
- Utilisez des jobs [interruptibles](../yaml/_index.md#interruptible) qui peuvent être annulés automatiquement si un nouveau pipeline démarre.
- Si un job n'a pas à s'exécuter dans chaque pipeline, utilisez [`rules`](../jobs/job_control.md) pour qu'il ne s'exécute que lorsque c'est nécessaire.
- [Utilisez des runners privés](../runners/runners_scope.md#group-runners) pour certains jobs.
- Si vous travaillez à partir d'une duplication et que vous soumettez une merge request au projet parent, vous pouvez demander à un mainteneur d'exécuter un pipeline [dans le projet parent](merge_request_pipelines.md#run-pipelines-in-the-parent-project).

Si vous gérez un projet open source, ces améliorations peuvent également réduire l'utilisation des minutes de calcul pour les projets de duplication des contributeurs, permettant ainsi davantage de contributions.

Consultez le [guide d'efficacité des pipelines](pipeline_efficiency.md) pour plus de détails.
