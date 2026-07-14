---
stage: Tenant Scale
group: Tenant Services
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Exécuter plusieurs processus Sidekiq
---

{{< details >}}

- Niveau :  Free, Premium, Ultimate
- Offre :  GitLab Self-Managed

{{< /details >}}

GitLab vous permet de démarrer plusieurs processus Sidekiq pour traiter les jobs en arrière-plan à un taux plus élevé sur une seule instance. Par défaut, Sidekiq démarre un processus de worker et n'utilise qu'un seul cœur.

> [!note]
> Les informations de cette page s'appliquent uniquement aux installations de packages Linux.

## Démarrer plusieurs processus {#start-multiple-processes}

Lors du démarrage de plusieurs processus, le nombre de processus doit au maximum être égal (et **not** supérieur) au nombre de cœurs CPU que vous souhaitez dédier à Sidekiq. Le processus de worker Sidekiq n'utilise pas plus d'un cœur CPU.

Pour démarrer plusieurs processus, utilisez le paramètre de tableau `sidekiq['queue_groups']` pour spécifier combien de processus créer avec `sidekiq-cluster` et quelles files d'attente ils doivent gérer. Chaque élément du tableau correspond à un processus Sidekiq supplémentaire, et les valeurs de chaque élément déterminent les files d'attente sur lesquelles il travaille. Dans la grande majorité des cas, tous les processus doivent écouter toutes les files d'attente (voir [le traitement des classes de jobs spécifiques](processing_specific_job_classes.md) pour plus de détails).

Par exemple, pour créer quatre processus Sidekiq, chacun écoutant toutes les files d'attente disponibles :

1. Modifiez `/etc/gitlab/gitlab.rb` :

   ```ruby
   sidekiq['queue_groups'] = ['*'] * 4
   ```

1. Enregistrez le fichier et reconfigurez GitLab :

   ```shell
   sudo gitlab-ctl reconfigure
   ```

Pour afficher les processus Sidekiq dans GitLab :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Surveillance** > **Jobs en arrière-plan**.

## Concurrence {#concurrency}

Par défaut, chaque processus défini sous `sidekiq` démarre avec un nombre de threads égal au nombre de files d'attente, plus un thread de réserve, jusqu'à un maximum de 50. Par exemple, un processus qui gère toutes les files d'attente utilise 50 threads par défaut.

Ces threads s'exécutent dans un seul processus Ruby, et chaque processus ne peut utiliser qu'un seul cœur CPU. L'utilité du threading dépend du travail ayant des dépendances externes sur lesquelles attendre, comme des requêtes de base de données ou des requêtes HTTP. La plupart des déploiements Sidekiq bénéficient de ce threading.

## Planification des connexions à la base de données {#database-connection-planning}

Avant d'augmenter les processus Sidekiq ou la concurrence, tenez compte de l'impact des connexions à la base de données sur votre paramètre PostgreSQL `max_connections`.

Pour une planification et des calculs de connexion détaillés, consultez la page [Régler PostgreSQL](../postgresql/tune.md).

### Gérer explicitement le nombre de threads {#manage-thread-counts-explicitly}

Le nombre maximum correct de threads (également appelé concurrence) dépend de la charge de travail. Les valeurs typiques vont de `5` pour les tâches très liées au CPU à `15` ou plus pour les travaux mixtes à faible priorité. Une plage de départ raisonnable est de `15` à `25` pour un déploiement non spécialisé.

Les valeurs varient en fonction du travail effectué par chaque déploiement spécifique de Sidekiq. Tout autre déploiement spécialisé avec des processus dédiés à des files d'attente spécifiques doit avoir la concurrence ajustée selon :

- L'utilisation CPU de chaque type de processus.
- Le débit atteint.

Chaque thread nécessite une connexion Redis, donc l'ajout de threads peut augmenter la latence Redis et potentiellement entraîner des délais d'attente côté client. Consultez la [documentation Sidekiq sur Redis](https://github.com/mperham/sidekiq/wiki/Using-Redis) pour plus de détails.

#### Gérer le nombre de threads avec le champ de concurrence {#manage-thread-counts-with-concurrency-field}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/439687) dans GitLab 16.9.

{{< /history >}}

Dans GitLab 16.9 et versions ultérieures, vous pouvez définir la concurrence en configurant `concurrency`. Cette valeur définit explicitement chaque processus avec ce niveau de concurrence.

Par exemple, pour définir la concurrence à `20` :

1. Modifiez `/etc/gitlab/gitlab.rb` :

   ```ruby
   sidekiq['concurrency'] = 20
   ```

1. Enregistrez le fichier et reconfigurez GitLab :

   ```shell
   sudo gitlab-ctl reconfigure
   ```

## Modifier l'intervalle de vérification {#modify-the-check-interval}

Pour modifier l'intervalle de vérification de l'état de Sidekiq pour les processus Sidekiq supplémentaires :

1. Modifiez `/etc/gitlab/gitlab.rb` :

   ```ruby
   sidekiq['interval'] = 5
   ```

   La valeur peut être n'importe quel nombre entier de secondes.

1. Enregistrez le fichier et reconfigurez GitLab :

   ```shell
   sudo gitlab-ctl reconfigure
   ```

## Résoudre les problèmes à l'aide de la CLI {#troubleshoot-using-the-cli}

> [!warning]
> Il est recommandé d'utiliser `/etc/gitlab/gitlab.rb` pour configurer les processus Sidekiq. Si vous rencontrez un problème, vous devez contacter le support GitLab. Utilisez la ligne de commande à vos propres risques.

À des fins de débogage, vous pouvez démarrer des processus Sidekiq supplémentaires en utilisant la commande `/opt/gitlab/embedded/service/gitlab-rails/bin/sidekiq-cluster`. Cette commande prend des arguments selon la syntaxe suivante :

```shell
/opt/gitlab/embedded/service/gitlab-rails/bin/sidekiq-cluster [QUEUE,QUEUE,...] [QUEUE, ...]
```

L'argument `--dryrun` permet de visualiser la commande à exécuter sans réellement la démarrer.

Chaque argument distinct désigne un groupe de files d'attente devant être traitées par un processus Sidekiq. Plusieurs files d'attente peuvent être traitées par le même processus en les séparant par une virgule au lieu d'un espace.

Au lieu d'une file d'attente, un espace de nommage de file d'attente peut également être fourni, pour que le processus écoute automatiquement toutes les files d'attente dans cet espace de nommage sans avoir besoin de lister explicitement tous les noms de files d'attente. Pour plus d'informations sur les espaces de nommage de files d'attente, consultez la section correspondante dans la partie développement Sidekiq de la documentation de développement GitLab.

### Surveiller la commande `sidekiq-cluster` {#monitor-the-sidekiq-cluster-command}

La commande `sidekiq-cluster` ne se termine pas une fois qu'elle a démarré le nombre souhaité de processus Sidekiq. Au lieu de cela, le processus continue de s'exécuter et transmet tous les signaux aux processus enfants. Cela vous permet d'arrêter tous les processus Sidekiq en envoyant un signal au processus `sidekiq-cluster`, au lieu d'avoir à l'envoyer aux processus individuels.

Si le processus `sidekiq-cluster` plante ou reçoit un `SIGKILL`, les processus enfants se terminent eux-mêmes après quelques secondes. Cela garantit que vous ne vous retrouvez pas avec des processus Sidekiq zombies.

Cela vous permet de surveiller les processus en connectant `sidekiq-cluster` à votre superviseur de choix (par exemple, runit).

Si un processus enfant est mort, la commande `sidekiq-cluster` signale à tous les processus restants de se terminer, puis se termine elle-même. Cela supprime le besoin pour `sidekiq-cluster` de réimplémenter un code complexe de surveillance/redémarrage de processus. À la place, vous devez vous assurer que votre superviseur redémarre le processus `sidekiq-cluster` chaque fois que nécessaire.

### Fichiers PID {#pid-files}

La commande `sidekiq-cluster` peut stocker son PID dans un fichier. Par défaut, aucun fichier PID n'est écrit, mais cela peut être modifié en passant l'option `--pidfile` à `sidekiq-cluster`. Par exemple :

```shell
/opt/gitlab/embedded/service/gitlab-rails/bin/sidekiq-cluster --pidfile /var/run/gitlab/sidekiq_cluster.pid process_commit
```

Gardez à l'esprit que le fichier PID contient le PID de la commande `sidekiq-cluster` et non les PID des processus Sidekiq démarrés.

### Environnement {#environment}

L'environnement Rails peut être défini en passant le drapeau `--environment` à la commande `sidekiq-cluster`, ou en définissant `RAILS_ENV` à une valeur non vide. La valeur par défaut est disponible dans `/opt/gitlab/etc/gitlab-rails/env/RAILS_ENV`.
