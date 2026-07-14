---
stage: Tenant Scale
group: Tenant Services
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: "Réduire l'utilisation de la mémoire"
---

Le memory killer Sidekiq gère automatiquement les processus de job en arrière-plan qui consomment trop de mémoire. Cette fonctionnalité surveille les processus worker et les redémarre avant que le memory killer Linux n'intervienne, ce qui permet aux jobs en arrière-plan de s'exécuter jusqu'à leur terme avant de s'arrêter progressivement. En journalisant ces événements, nous facilitons l'identification des jobs qui entraînent une utilisation élevée de la mémoire.

## Comment nous surveillons la mémoire Sidekiq {#how-we-monitor-sidekiq-memory}

GitLab surveille la limite RSS disponible par défaut uniquement pour les installations de packages Linux ou Docker. La raison en est que GitLab s'appuie sur runit pour redémarrer Sidekiq après un arrêt dû à la mémoire, et que les installations auto-compilées et les installations Helm chart n'utilisent pas runit ni un outil équivalent.

Avec les paramètres par défaut, Sidekiq redémarre au maximum une fois toutes les 15 minutes, le redémarrage entraînant environ une minute de délai pour les jobs en arrière-plan entrants.

Certains jobs en arrière-plan reposent sur des processus externes à longue durée d'exécution. Pour s'assurer que ces processus sont correctement terminés lors du redémarrage de Sidekiq, chaque processus Sidekiq doit être exécuté en tant que leader de groupe de processus (par exemple, en utilisant `chpst -P`). Si vous utilisez une installation de package Linux ou le script `bin/background_jobs` avec `runit` installé, cette opération est gérée automatiquement.

## Configuration des limites {#configuring-the-limits}

Les limites de mémoire Sidekiq sont contrôlées à l'aide des [variables d'environnement](https://docs.gitlab.com/omnibus/settings/environment-variables/#setting-custom-environment-variables)

- `SIDEKIQ_MEMORY_KILLER_MAX_RSS` (Ko) : définit la limite logicielle du processus Sidekiq pour le RSS autorisé. Si le RSS du processus Sidekiq (exprimé en kilo-octets) dépasse `SIDEKIQ_MEMORY_KILLER_MAX_RSS` pendant plus longtemps que `SIDEKIQ_MEMORY_KILLER_GRACE_TIME`, le redémarrage progressif est déclenché. Si `SIDEKIQ_MEMORY_KILLER_MAX_RSS` n'est pas défini, ou si sa valeur est 0, la limite logicielle n'est pas surveillée. `SIDEKIQ_MEMORY_KILLER_MAX_RSS` est défini par défaut à `2000000`.
- `SIDEKIQ_MEMORY_KILLER_GRACE_TIME` : définit la période de grâce en secondes pendant laquelle le processus Sidekiq est autorisé à s'exécuter au-dessus de la limite logicielle RSS autorisée. Si le processus Sidekiq repasse en dessous du RSS autorisé (limite logicielle) dans le délai `SIDEKIQ_MEMORY_KILLER_GRACE_TIME`, le redémarrage est annulé. La valeur par défaut est 900 secondes (15 minutes).
- `SIDEKIQ_MEMORY_KILLER_HARD_LIMIT_RSS` (Ko) : définit la limite matérielle du processus Sidekiq pour le RSS autorisé. Si le RSS du processus Sidekiq (exprimé en kilo-octets) dépasse `SIDEKIQ_MEMORY_KILLER_HARD_LIMIT_RSS`, un redémarrage progressif immédiat de Sidekiq est déclenché. Si cette valeur n'est pas définie, ou si elle est définie à 0, la limite matérielle n'est pas surveillée.

- `SIDEKIQ_MEMORY_KILLER_CHECK_INTERVAL` : définit la fréquence de vérification du RSS du processus. La valeur par défaut est 3 secondes.
- `SIDEKIQ_MEMORY_KILLER_SHUTDOWN_WAIT` : définit le délai maximum accordé à tous les jobs Sidekiq pour se terminer. Aucun nouveau job n'est accepté pendant cette période. La valeur par défaut est 30 secondes.

  Si le redémarrage du processus n'est pas effectué par Sidekiq, le processus Sidekiq est arrêté de force après le [délai d'arrêt de Sidekiq](https://github.com/mperham/sidekiq/wiki/Signals#term) (25 secondes par défaut) + 2 secondes. Si les jobs ne se terminent pas pendant ce délai, tous les jobs en cours d'exécution sont interrompus par un signal `SIGTERM` envoyé au processus Sidekiq.

- `GITLAB_MEMORY_WATCHDOG_ENABLED` : activé par défaut. Définissez `GITLAB_MEMORY_WATCHDOG_ENABLED` sur false pour désactiver l'exécution de Watchdog.

### Surveiller les redémarrages des workers {#monitor-worker-restarts}

GitLab émet des événements de journal si des workers sont redémarrés en raison d'une utilisation élevée de la mémoire.

Voici un exemple de l'un de ces événements de journal dans `/var/log/gitlab/gitlab-rails/sidekiq_client.log` :

```json
{
  "severity": "WARN",
  "time": "2023-02-04T09:45:16.173Z",
  "correlation_id": null,
  "pid": 2725,
  "worker_id": "sidekiq_1",
  "memwd_handler_class": "Gitlab::Memory::Watchdog::SidekiqHandler",
  "memwd_sleep_time_s": 3,
  "memwd_rss_bytes": 1079683247,
  "memwd_max_rss_bytes": 629145600,
  "memwd_max_strikes": 5,
  "memwd_cur_strikes": 6,
  "message": "rss memory limit exceeded",
  "running_jobs": [
    {
      jid: "83efb701c59547ee42ff7068",
      worker_class: "Ci::DeleteObjectsWorker"
    },
    {
      jid: "c3a74503dc2637f8f9445dd3",
      worker_class: "Ci::ArchiveTraceWorker"
    }
  ]
}
```

Où :

- `memwd_rss_bytes` est la quantité réelle de mémoire consommée.
- `memwd_max_rss_bytes` est la limite RSS définie via `per_worker_max_memory_mb`.
- `running jobs` liste les jobs qui étaient en cours d'exécution au moment où le processus a dépassé la limite RSS et a démarré un redémarrage progressif.
