---
stage: Tenant Scale
group: Gitaly
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: "Délais d'expiration et nouvelles tentatives de Gitaly"
---

{{< details >}}

- Niveau :  Free, Premium, Ultimate
- Offre :  GitLab Self-Managed

{{< /details >}}

[Gitaly](../gitaly/_index.md) fournit deux types de délais d'expiration configurables :

- Délais d'expiration des appels, configurés à l'aide de l'interface utilisateur de GitLab.
- Délais d'expiration de négociation, configurés à l'aide des fichiers de configuration de Gitaly.

## Configurer les délais d'expiration des appels {#configure-the-call-timeouts}

Configurez les délais d'expiration des appels suivants pour vous assurer que les appels Gitaly de longue durée ne consomment pas inutilement des ressources.

Prérequis :

- Accès administrateur.

Pour configurer les délais d'expiration des appels :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Préférences**.
1. Développez la section **Délais d'expiration de Gitaly**.
1. Définissez chaque délai d'expiration selon les besoins.

### Délais d'expiration des appels disponibles {#available-call-timeouts}

Différents délais d'expiration des appels sont disponibles pour différentes opérations Gitaly.

| Délai d'expiration | Valeur par défaut    | Description |
|:--------|:-----------|:------------|
| Valeur par défaut | 55 secondes | Délai d'expiration pour la plupart des appels Gitaly (non appliqué pour les opérations `git` `fetch` et `push`, ni pour les jobs Sidekiq). Par exemple, vérifier si un dépôt existe sur le disque. Garantit que les appels Gitaly effectués dans une requête web ne peuvent pas dépasser le délai d'expiration total de la requête. Il doit être inférieur au [délai d'expiration du worker](../operations/puma.md#change-the-worker-timeout) qui peut être configuré pour [Puma](../../install/requirements.md#puma). Si un délai d'expiration d'appel Gitaly dépasse le délai d'expiration du worker, le temps restant du délai d'expiration du worker est utilisé pour éviter de devoir terminer le worker. |
| Fast    | 10 secondes | Délai d'expiration pour les opérations Gitaly rapides utilisées dans les requêtes, parfois plusieurs fois. Par exemple, vérifier si un dépôt existe sur le disque. Si les opérations rapides dépassent ce seuil, il peut y avoir un problème avec un fragment de stockage. Un échec rapide peut aider à maintenir la stabilité de l'instance GitLab. |
| Medium  | 30 secondes | Délai d'expiration pour les opérations Gitaly qui devraient être rapides (éventuellement dans les requêtes) mais de préférence pas utilisées plusieurs fois dans une requête. Par exemple, le chargement de blobs. Délai d'expiration qui doit être défini entre Par défaut et Fast. |

Par défaut, le délai d'expiration **Par défaut** ne peut pas être défini au-delà de `57` secondes. Pour plus d'informations, consultez [Impossible d'augmenter le délai d'expiration par défaut de Gitaly au-delà de 57 secondes](#unable-to-raise-gitaly-default-timeout-above-57-seconds).

## Configurer les délais d'expiration de négociation {#configure-the-negotiation-timeouts}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitaly/-/issues/5574) dans GitLab 16.5.

{{< /history >}}

Vous pourriez avoir besoin d'augmenter le délai d'expiration de négociation :

- Pour les dépôts particulièrement volumineux.
- Lors de l'exécution de ces commandes en parallèle.

Vous pouvez configurer des délais d'expiration de négociation pour :

- `git-upload-pack(1)`, qui est invoqué par un nœud Gitaly lorsque vous exécutez `git fetch`.
- `git-upload-archive(1)`, qui est invoqué par un nœud Gitaly lorsque vous exécutez `git archive --remote`.

Pour configurer ces délais d'expiration :

{{< tabs >}}

{{< tab title="Linux package (Omnibus)" >}}

Modifiez `/etc/gitlab/gitlab.rb` :

```ruby
gitaly['configuration'] = {
    timeout: {
        upload_pack_negotiation: '10m',      # 10 minutes
        upload_archive_negotiation: '20m',   # 20 minutes
    }
}
```

{{< /tab >}}

{{< tab title="Self-compiled (source)" >}}

Modifiez `/home/git/gitaly/config.toml` :

```toml
[timeout]
upload_pack_negotiation = "10m"
upload_archive_negotiation = "20m"
```

{{< /tab >}}

{{< /tabs >}}

Pour les valeurs, utilisez le format de [`ParseDuration`](https://pkg.go.dev/time#ParseDuration) en Go.

Ces délais d'expiration n'affectent que la [phase de négociation](https://git-scm.com/docs/pack-protocol/2.2.3#_packfile_negotiation) des opérations Git distantes, pas le transfert entier.

## Nouvelles tentatives du client Gitaly {#gitaly-client-retries}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/cluster-integration/gitlab-agent/-/work_items/811) dans GitLab 18.10.

{{< /history >}}

Gitaly peut parfois être brièvement indisponible. Par exemple, lors des mises à niveau de GitLab. En particulier avec Gitaly sur Kubernetes, où le démarrage et le redémarrage d'un Pod prennent quelques secondes.

Pour empêcher GitLab de renvoyer des erreurs aux clients lors d'une indisponibilité brève, configurez les nouvelles tentatives du client Gitaly. Lorsque les nouvelles tentatives du client Gitaly sont configurées et que Gitaly est indisponible, les clients Gitaly tels que Rails (application GitLab), Workhorse et GitLab Shell réessaient les requêtes selon un mécanisme d'attente exponentielle.

Deux paramètres peuvent être configurés :

- `max_attempts` :  Nombre maximum de tentatives entre 2 et 5.
- `max_backoff` :  Durée maximale avant que le client cesse de réessayer. La valeur doit être une chaîne de durée, telle que `1.4s` ou `10s`.

Le multiplicateur d'attente est défini sur `2` et l'attente initiale est dérivée des deux paramètres.

### Directives de configuration {#configuration-guidelines}

La configuration appropriée dépend de la configuration de votre instance GitLab et de la durée pendant laquelle Gitaly reste indisponible lors d'un tel événement :

- Sur Kubernetes, un Pod Gitaly peut prendre environ 10 à 12 secondes pour démarrer, selon le fournisseur Cloud. Ce temps inclut la durée nécessaire pour que le volume soit attaché et monté sur le Pod.
- Pour les instances du package Linux, Gitaly peut redémarrer beaucoup plus rapidement car le redémarrage de Gitaly est un redémarrage de processus.

Gardez également à l'esprit que Gitaly peut être configuré avec un délai d'expiration d'arrêt progressif. Lorsque Gitaly s'arrête, les nouvelles requêtes sont rejetées mais le serveur gRPC continue de traiter les requêtes en cours jusqu'à ce que :

- Toutes soient traitées.
- Le délai d'expiration d'arrêt expire.

Ce délai d'expiration d'arrêt progressif peut jouer un rôle dans la durée pendant laquelle Gitaly reste indisponible pour les nouvelles requêtes.

Vous devez configurer les nouvelles tentatives du client avec un `max_backoff` égal ou supérieur à la somme du délai d'arrêt progressif et du temps de (re)démarrage.

### Configurer les nouvelles tentatives du client {#configure-client-retries}

La configuration suivante s'applique à Rails (application GitLab), Workhorse et GitLab Shell, et la même configuration s'applique à tous les clients.

Les valeurs fournies sont des exemples et ne doivent pas être utilisées comme directives.

{{< tabs >}}

{{< tab title="Linux package (Omnibus)" >}}

Mettez à jour votre fichier `gitlab.rb` avec ces configurations :

```ruby
gitlab_rails['gitaly_client_max_attempts'] = 5
gitlab_rails['gitaly_client_max_backoff'] = '1.4s'
```

{{< /tab >}}

{{< tab title="Helm chart (Kubernetes)" >}}

Mettez à jour votre fichier `values.yml` avec ces configurations :

```yaml
global:
  gitaly:
    client:
      maxAttempts: 5
      maxBackoff: '1.4s'
```

{{< /tab >}}

{{< /tabs >}}

## Dépannage {#troubleshooting}

Lorsque vous travaillez avec les délais d'expiration de Gitaly, vous pouvez rencontrer les problèmes suivants.

### Impossible d'augmenter le délai d'expiration par défaut de Gitaly au-delà de 57 secondes {#unable-to-raise-gitaly-default-timeout-above-57-seconds}

> [!warning]
> N'augmentez ces valeurs que si nécessaire. Un délai d'expiration de worker plus élevé signifie que les requêtes lentes ou bloquées mobilisent un worker Puma plus longtemps, réduisant ainsi la capacité de l'instance. Les raisons courantes d'augmenter le délai d'expiration **Par défaut** de Gitaly incluent les dépôts très volumineux sur un stockage lent, les vues de diff ou de comparaison coûteuses, ou les nœuds de cluster Gitaly dégradés. Pour les tâches en arrière-plan telles que les importations, les miroirs ou la maintenance, préférez le déchargement vers Sidekiq, qui n'est pas limité par ce plafond.

Par défaut, le [**Par défaut**](#available-call-timeouts) ne peut pas être augmenté au-delà de `57` secondes. Toute tentative de définir le délai d'expiration à une valeur plus élevée produit l'erreur de validation :

```plaintext
Gitaly timeout default must be less than or equal to 57
```

Cette limite est imposée par trois délais d'expiration interdépendants :

- `puma['worker_timeout']` :  Délai d'expiration Puma par worker. La valeur par défaut est `60` secondes. Pour plus d'informations, consultez [modifier le délai d'expiration du worker](../operations/puma.md#change-the-worker-timeout).
- `gitlab_rails['max_request_duration_seconds']` : paramètre de l'application GitLab qui limite le délai d'expiration **Par défaut** de Gitaly. La valeur par défaut est `(worker_timeout * 0.95).ceil` = `57` secondes. Ce paramètre doit être strictement inférieur à `puma['worker_timeout']`.
- `GITLAB_RAILS_RACK_TIMEOUT` : middleware `Rack::Timeout` `service_timeout`. La valeur par défaut est `60` secondes. Ce délai d'expiration est indépendant des deux autres et il met fin à la requête à cette valeur quelle que soit la configuration des autres.

Pour augmenter le délai d'expiration **Par défaut** de Gitaly au-delà de 57 secondes, les trois valeurs doivent être augmentées ensemble. Par exemple, pour autoriser un délai d'expiration **Par défaut** de Gitaly de `110` secondes :

1. Modifiez `/etc/gitlab/gitlab.rb` :

   ```ruby
   puma['worker_timeout'] = 120
   gitlab_rails['max_request_duration_seconds'] = 114
   gitlab_rails['env'] = {
     'GITLAB_RAILS_RACK_TIMEOUT' => 120
   }
   ```

1. Reconfigurer GitLab :

   ```shell
   sudo gitlab-ctl reconfigure
   ```

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Préférences**.
1. Développez **Délais d'expiration de Gitaly**.
1. Définissez **Délai d'expiration par défaut** sur la nouvelle valeur souhaitée (jusqu'à `max_request_duration_seconds`).

   Il est recommandé de laisser une petite marge. La valeur par défaut intégrée utilise un écart de 5 % (`max_request_duration_seconds = (worker_timeout * 0.95).ceil`), de sorte que la date limite de requête Rails est atteinte avant que Puma n'atteigne son délai d'expiration de worker.

   `GITLAB_RAILS_RACK_TIMEOUT` n'augmente **pas** le plafond de Gitaly à lui seul. `Settings.gitlab.max_request_duration_seconds` est ce que le validateur des paramètres de l'application consulte, et c'est défini par `gitlab_rails['max_request_duration_seconds']`. Cependant, laisser `GITLAB_RAILS_RACK_TIMEOUT` à sa valeur par défaut de `60` entraîne la fin par le middleware Rack de toute requête dépassant 60 secondes, y compris les appels Gitaly longs, avant qu'ils ne puissent se terminer.
