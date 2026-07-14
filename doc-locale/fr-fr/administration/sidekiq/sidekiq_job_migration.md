---
stage: Tenant Scale
group: Tenant Services
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Tâches Rake de migration des jobs Sidekiq
---

{{< details >}}

- Niveau :  Free, Premium, Ultimate
- Offre :  GitLab Self-Managed

{{< /details >}}

> [!warning]
> Cette opération devrait être très rare. Nous ne la recommandons pas pour la grande majorité des instances GitLab.

Les règles de routage Sidekiq permettent aux administrateurs de réacheminer certains jobs d'arrière-plan de leur file d'attente habituelle vers une file d'attente alternative. Par défaut, GitLab utilise une file d'attente par type de job d'arrière-plan. GitLab possède plus de 400 types de jobs d'arrière-plan, et dispose donc en conséquence de plus de 400 files d'attente.

La plupart des administrateurs n'ont pas besoin de modifier ce paramètre. Dans certains cas avec des charges de travail de traitement de jobs d'arrière-plan particulièrement importantes, les performances de Redis peuvent être affectées en raison du nombre de files d'attente écoutées par GitLab.

Si les règles de routage Sidekiq sont modifiées, les administrateurs doivent être prudents lors de la migration pour éviter de perdre des jobs entièrement. Les étapes de migration de base sont les suivantes :

1. Écouter à la fois les anciennes et les nouvelles files d'attente.
1. Mettre à jour les règles de routage.
1. [Reconfigurer GitLab](../restart_gitlab.md#reconfigure-a-linux-package-installation) pour que les modifications prennent effet.
1. Exécuter les [tâches Rake pour la migration des jobs en file d'attente et des jobs futurs](#migrate-queued-and-future-jobs).
1. Arrêter d'écouter les anciennes files d'attente.

## Migrer les jobs en file d'attente et les jobs futurs {#migrate-queued-and-future-jobs}

L'étape 4 implique la réécriture de certaines données de jobs Sidekiq pour les jobs déjà stockés dans Redis, mais devant s'exécuter dans le futur. Les deux ensembles de jobs devant s'exécuter dans le futur : les jobs planifiés et les jobs à relancer. Nous fournissons une tâche Rake distincte pour migrer chaque ensemble :

- `gitlab:sidekiq:migrate_jobs:retry` pour les jobs à relancer.
- `gitlab:sidekiq:migrate_jobs:schedule` pour les jobs planifiés.

Les jobs en file d'attente qui n'ont pas encore été exécutés peuvent également être migrés avec une tâche Rake ([disponible dans GitLab 15.6](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/101348) et versions ultérieures) :

- `gitlab:sidekiq:migrate_jobs:queued` pour les jobs en file d'attente à exécuter de manière asynchrone.

La plupart du temps, exécuter les trois en même temps est le bon choix. Trois tâches séparées permettent un contrôle plus précis lorsque nécessaire. Pour exécuter les trois à la fois ([disponible dans GitLab 15.6](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/101348) et versions ultérieures) :

```shell
# omnibus-gitlab
sudo gitlab-rake gitlab:sidekiq:migrate_jobs:retry gitlab:sidekiq:migrate_jobs:schedule gitlab:sidekiq:migrate_jobs:queued

# source installations
bundle exec rake gitlab:sidekiq:migrate_jobs:retry gitlab:sidekiq:migrate_jobs:schedule gitlab:sidekiq:migrate_jobs:queued RAILS_ENV=production
```
