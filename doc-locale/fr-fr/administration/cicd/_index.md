---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: "Configuration de l'instance GitLab CI/CD"
description: Gérer la configuration de GitLab CI/CD.
---

{{< details >}}

- Niveau : Free, Premium, Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

Les administrateurs GitLab peuvent gérer la configuration de GitLab CI/CD pour leur instance.

## Désactiver GitLab CI/CD dans les nouveaux projets {#disable-gitlab-cicd-in-new-projects}

GitLab CI/CD est activé par défaut dans tous les nouveaux projets d'une instance. Vous pouvez définir CI/CD comme désactivé par défaut dans les nouveaux projets en modifiant les paramètres dans :

- `gitlab.yml` pour les installations auto-compilées.
- `gitlab.rb` pour les installations avec le package Linux.

Les projets existants pour lesquels CI/CD était déjà activé ne sont pas modifiés. De plus, ce paramètre ne modifie que la valeur par défaut du projet, ainsi les propriétaires de projets [peuvent toujours activer CI/CD dans les paramètres du projet](../../ci/pipelines/settings.md#disable-gitlab-cicd-pipelines).

Pour les installations auto-compilées :

1. Ouvrez `gitlab.yml` avec votre éditeur et définissez `builds` sur `false` :

   ```yaml
   ## Default project features settings
   default_projects_features:
     issues: true
     merge_requests: true
     wiki: true
     snippets: false
     builds: false
   ```

1. Enregistrez le fichier `gitlab.yml`.
1. Redémarrez GitLab :

   ```shell
   sudo service gitlab restart
   ```

Pour les installations avec le package Linux :

1. Modifiez `/etc/gitlab/gitlab.rb` et ajoutez cette ligne :

   ```ruby
   gitlab_rails['gitlab_default_projects_features_builds'] = false
   ```

1. Enregistrez le fichier `/etc/gitlab/gitlab.rb`.
1. Reconfigurez GitLab :

   ```shell
   sudo gitlab-ctl reconfigure
   ```

## Définir la limite de jobs `needs` {#set-the-needs-job-limit}

{{< details >}}

- Niveau : Free, Premium, Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

Le nombre maximum de jobs pouvant être définis dans `needs` est de 50 par défaut.

Un administrateur GitLab disposant d'un [accès à la console Rails de GitLab](../operations/rails_console.md#starting-a-rails-console-session) peut choisir une limite personnalisée. Par exemple, pour définir la limite à `100` :

```ruby
Plan.default.actual_limits.update!(ci_needs_size_limit: 100)
```

Pour désactiver les dépendances `needs`, définissez la limite sur `0`. Les pipelines avec des jobs configurés pour utiliser `needs` renvoient alors l'erreur `job can only need 0 others`.

## Modifier la fréquence maximale des pipelines planifiés {#change-maximum-scheduled-pipeline-frequency}

Les [pipelines planifiés](../../ci/pipelines/schedules.md) peuvent être configurés avec n'importe quelle [valeur cron](../../topics/cron/_index.md), mais ils ne s'exécutent pas toujours exactement au moment planifié. Un processus interne, appelé le _pipeline schedule worker_, met en file d'attente tous les pipelines planifiés, mais ne s'exécute pas en continu. Le worker s'exécute selon son propre planning, et les pipelines planifiés prêts à démarrer ne sont mis en file d'attente qu'à la prochaine exécution du worker. Les pipelines planifiés ne peuvent pas s'exécuter plus fréquemment que le worker.

La fréquence par défaut du pipeline schedule worker est `3-59/10 * * * *` (toutes les dix minutes, en commençant par `0:03`, `0:13`, `0:23`, et ainsi de suite). La fréquence par défaut pour GitLab.com est répertoriée dans les [paramètres de GitLab.com](../../user/gitlab_com/_index.md#cicd).

Pour modifier la fréquence du pipeline schedule worker :

1. Modifiez la valeur `gitlab_rails['pipeline_schedule_worker_cron']` dans le fichier `gitlab.rb` de votre instance.
1. [Reconfigurez GitLab](../restart_gitlab.md#reconfigure-a-linux-package-installation) pour que les modifications prennent effet.

Par exemple, pour définir la fréquence maximale des pipelines à deux fois par jour, définissez `pipeline_schedule_worker_cron` sur une valeur cron de `0 */12 * * *` (`00:00` et `12:00` chaque jour).

Lorsque de nombreuses planifications de pipeline s'exécutent en même temps, des délais supplémentaires peuvent survenir. Le pipeline schedule worker traite les pipelines par [lots](https://gitlab.com/gitlab-org/gitlab/-/blob/3426be1b93852c5358240c5df40970c0ddfbdb2a/app/workers/pipeline_schedule_worker.rb#L13-14) avec un petit délai entre chaque lot pour distribuer la charge système. Cela peut entraîner le démarrage des planifications de pipeline plusieurs minutes voire plus d'une heure après leur heure planifiée, selon la charge système.

## Reprise après sinistre {#disaster-recovery}

Vous pouvez désactiver certaines parties importantes mais coûteuses en calcul de l'application pour soulager la base de données pendant une indisponibilité en cours.

### Désactiver la planification équitable sur les runners d'instance {#disable-fair-scheduling-on-instance-runners}

Lors du traitement d'un grand nombre de jobs en attente, vous pouvez activer temporairement le `ci_queueing_disaster_recovery_disable_fair_scheduling` [feature flag](../feature_flags/_index.md). Ce flag désactive la planification équitable sur les runners d'instance, ce qui réduit l'utilisation des ressources système sur le point de terminaison `jobs/request`.

Lorsqu'il est activé, les jobs sont traités dans l'ordre dans lequel ils ont été introduits dans le système, au lieu d'être répartis sur plusieurs projets.

### Désactiver l'application du quota de calcul {#disable-compute-quota-enforcement}

Pour désactiver l'application des [quotas de minutes de calcul](compute_minutes.md) sur les runners d'instance, vous pouvez activer temporairement le `ci_queueing_disaster_recovery_disable_quota` [feature flag](../feature_flags/_index.md). Ce flag réduit l'utilisation des ressources système sur le point de terminaison `jobs/request`.

Lorsqu'il est activé, les jobs créés au cours de la dernière heure peuvent s'exécuter dans des projets dont le quota est dépassé. Les jobs antérieurs sont déjà annulés par un worker de fond périodique (`StuckCiJobsWorker`).
