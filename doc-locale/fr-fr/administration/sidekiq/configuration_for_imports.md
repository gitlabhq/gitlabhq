---
stage: Create
group: Import
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Configuration Sidekiq pour les importations
description: "Optimiser la configuration Sidekiq pour l'importation ou la migration vers GitLab."
---

{{< details >}}

- Niveau :  Free, Premium, Ultimate
- Offre :  GitLab Self-Managed

{{< /details >}}

Les importateurs s'appuient fortement sur les jobs Sidekiq pour gérer l'importation et l'exportation de groupes et de projets. Certains de ces jobs peuvent consommer des ressources importantes (CPU et mémoire) et prendre beaucoup de temps à s'exécuter, ce qui peut affecter l'exécution d'autres jobs.

Pour résoudre ce problème, vous devez acheminer les jobs des importateurs vers une file d'attente Sidekiq dédiée et assigner un processus Sidekiq dédié pour gérer cette file d'attente.

Par exemple, vous pouvez utiliser la configuration suivante :

```conf
sidekiq['concurrency'] = 20

sidekiq['routing_rules'] = [
  # Route import and export jobs to the importer queue
  ['feature_category=importers', 'importers'],

  # Route all other jobs to the default queue by using wildcard matching
  ['*', 'default']
]

sidekiq['queue_groups'] = [
  # Run a dedicated process for the importer queue
  'importers',

  # Run a separate process for the default and mailer queues
  'default,mailers'
]
```

Dans cette configuration :

- Un processus Sidekiq dédié gère les jobs d'importation et d'exportation via la file d'attente de l'importateur.
- Un autre processus Sidekiq gère tous les autres jobs (les files d'attente par défaut et mailer).
- Les deux processus Sidekiq sont configurés pour s'exécuter avec 20 fils d'exécution simultanés par défaut. Pour les environnements avec des contraintes de mémoire, vous pouvez réduire ce nombre.

## Configurer des processus supplémentaires {#configure-additional-processes}

Si votre instance dispose de suffisamment de ressources pour prendre en charge davantage de jobs simultanés, vous pouvez configurer des processus Sidekiq supplémentaires pour accélérer les migrations.

Pour le nombre maximum de processus Sidekiq, gardez les points suivants à l'esprit :

- Le nombre de processus ne doit pas dépasser le nombre de cœurs CPU disponibles.
- Chaque processus peut utiliser jusqu'à 2 Go de mémoire, assurez-vous donc que l'instance dispose de suffisamment de mémoire pour les processus supplémentaires.
- Chaque processus ajoute une connexion de base de données par fil d'exécution, telle que définie dans `sidekiq['concurrency']`.

Par exemple :

```conf
sidekiq['queue_groups'] = [
  # Run three processes for importer jobs
  'importers',
  'importers',
  'importers',

  # Run a separate process for the default and mailer queues
  'default,mailers'
]
```

Avec cette configuration, plusieurs processus Sidekiq gèrent les jobs d'importation et d'exportation simultanément, ce qui accélère la migration tant que l'instance dispose de ressources suffisantes.

## Sujets connexes {#related-topics}

- [Importer et migrer vers GitLab](../../user/import/_index.md).
- [Paramètres d'importation et d'exportation](../settings/import_and_export_settings.md).
- [Exécuter plusieurs processus Sidekiq](extra_sidekiq_processes.md).
- [Traitement de classes de jobs spécifiques](processing_specific_job_classes.md).
