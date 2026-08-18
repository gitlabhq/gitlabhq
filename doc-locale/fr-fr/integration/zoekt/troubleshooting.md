---
stage: AI-powered
group: Global Search
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Dépannage de Zoekt
---

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Statut : disponibilité limitée

{{< /details >}}

Lorsque vous utilisez Zoekt, vous pouvez rencontrer les problèmes suivants. Pour un débogage préliminaire :

- [Exécutez un bilan de santé](_index.md#run-a-health-check) pour comprendre le statut de votre infrastructure Zoekt.
- [Vérifiez le statut d'indexation](_index.md#check-indexing-status) avec la tâche Rake `gitlab-rake gitlab:zoekt:info`.

## L'espace de nommage n'est pas indexé {#namespace-is-not-indexed}

Lorsque vous [activez le paramètre](_index.md#index-root-namespaces-automatically), les nouveaux espaces de nommage sont indexés automatiquement. Si un espace de nommage n'est pas indexé automatiquement, inspectez les journaux Sidekiq pour vérifier si les jobs sont en cours de traitement. `Search::Zoekt::SchedulingWorker` est responsable de l'indexation des espaces de nommage.

Dans une [session de console Rails](../../administration/operations/rails_console.md#starting-a-rails-console-session), vous pouvez vérifier :

- Les espaces de nommage pour lesquels Zoekt n'est pas activé :

  ```ruby
  Namespace.group_namespaces.root_namespaces_without_zoekt_enabled_namespace
  ```

- Le statut des index Zoekt :

  ```ruby
  Search::Zoekt::Index.all.pluck(:state, :namespace_id)
  ```

Pour indexer un espace de nommage manuellement, consultez [configurer l'indexation](https://docs.gitlab.com/charts/charts/gitlab/gitlab-zoekt/#configure-zoekt-in-gitlab).

## Erreur : `SilentModeBlockedError` {#error-silentmodeblockederror}

Vous pouvez obtenir une erreur `SilentModeBlockedError` lorsque vous essayez d'exécuter une recherche de code exacte. Ce problème survient lorsque le [mode silencieux](../../administration/silent_mode) est activé sur l'instance GitLab.

Pour résoudre ce problème, assurez-vous que le mode silencieux est désactivé.

## Erreur : `connections to all backends failing` {#error-connections-to-all-backends-failing}

Dans `application_json.log`, vous pouvez obtenir l'erreur suivante :

```plaintext
connections to all backends failing; last error: UNKNOWN: ipv4:1.2.3.4:5678: Trying to connect an http1.x server
```

Pour résoudre ce problème, vérifiez si vous utilisez des proxies. Si c'est le cas, définissez l'adresse IP du serveur GitLab sur `no_proxy` :

```ruby
gitlab_rails['env'] = {
  "http_proxy" => "http://proxy.domain.com:1234",
  "https_proxy" => "http://proxy.domain.com:1234",
  "no_proxy" => ".domain.com,IP_OF_GITLAB_INSTANCE,127.0.0.1,localhost"
}
```

`proxy.domain.com:1234` est le domaine de l'instance proxy et le port. `IP_OF_GITLAB_INSTANCE` pointe vers l'adresse IP publique de l'instance GitLab.

Vous pouvez obtenir ces informations en exécutant `ip a` et en vérifiant l'un des éléments suivants :

- L'adresse IP de l'interface réseau appropriée
- L'adresse IP publique de tout équilibreur de charge que vous utilisez

## Erreurs de mémoire insuffisante {#out-of-memory-errors}

Les nœuds Zoekt peuvent manquer de mémoire pendant la recherche ou l'indexation. Les erreurs de mémoire insuffisante (OOM) sont plus fréquentes dans le serveur web. Le serveur web mappe en mémoire les fragments d'index dans la mémoire physique au fur et à mesure que les recherches sont traitées, de sorte que la mémoire résidente augmente avec la taille de l'index et le volume de requêtes. Les symptômes d'une erreur OOM et les étapes de récupération requises diffèrent selon les deux composants. Pour plus d'informations, consultez [l'architecture mémoire](_index.md#memory-architecture).

### Détecter un événement de mémoire insuffisante {#detect-an-out-of-memory-event}

Pour les déploiements Kubernetes, vérifiez si un conteneur a été arrêté en raison d'une erreur OOM :

```shell
kubectl describe pod <your_pod_name> -n <your_namespace>
```

Recherchez `OOMKilled` dans la section `Last State` et un `Exit Code` non nul (généralement `137`) :

```plaintext
Last State: Terminated
  Reason: OOMKilled
  Exit Code: 137
```

Vous pouvez également vérifier le nombre de redémarrages sur tous les pods Zoekt :

```shell
kubectl get pods -n <your_namespace> -l app=gitlab-zoekt
```

Un nombre élevé de `RESTARTS` sur un pod indique des arrêts OOM répétés. Le sélecteur de label `app=gitlab-zoekt` peut différer selon la version de votre chart ou la configuration de l'opérateur.

Si vous avez installé [kube-state-metrics](https://github.com/kubernetes/kube-state-metrics), vous pouvez également surveiller ces métriques dans Prometheus ou Grafana :

- `kube_pod_container_status_last_terminated_reason{reason="OOMKilled"}` : pods arrêtés en raison d'une erreur OOM.
- `kube_pod_container_status_waiting_reason{reason="CrashLoopBackOff"}` : pods en boucle de crash.
- `kube_pod_container_status_restarts_total` : nombre cumulatif de redémarrages par conteneur. Des augmentations rapides indiquent des crashes répétés.

Le serveur web expose `process_resident_memory_bytes` sur `/metrics` au port `6070`. Si vous avez configuré Prometheus pour extraire directement les pods du serveur web, vous pouvez utiliser cette métrique pour surveiller l'utilisation de la mémoire résidente du serveur web au fil du temps.

Pour les déploiements sur VM et sur bare metal, vérifiez le journal système pour les événements OOM :

```shell
sudo journalctl -k | grep -i "oom\|killed process"
```

### Récupérer après un événement de mémoire insuffisante {#recover-from-an-out-of-memory-event}

Les étapes de récupération diffèrent selon le composant qui rencontre des erreurs OOM.

#### Erreurs de mémoire insuffisante de l'indexeur {#indexer-out-of-memory-errors}

Si l'indexeur est arrêté de manière répétée en raison d'une erreur OOM, suspendez l'indexation globalement pour arrêter tout nouveau travail d'indexation sur tous les nœuds pendant votre investigation :

```shell
gitlab-rake gitlab:zoekt:pause_indexing
```

Ou suspendez l'indexation depuis l'interface utilisateur :

Prérequis :

- Accès administrateur.

1. dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Rechercher**.
1. Développez **Recherche de code spécifique**.
1. Cochez la case **Interrompre l'indexation**.
1. Sélectionnez **Enregistrer les modifications**.

Une fois le nœud stabilisé, reprenez l'indexation :

```shell
gitlab-rake gitlab:zoekt:resume_indexing
```

#### Erreurs de mémoire insuffisante du serveur web {#webserver-out-of-memory-errors}

Si le serveur web est arrêté de manière répétée en raison d'une erreur OOM, désactivez la recherche Zoekt pendant votre investigation. Cela arrête le trafic de recherche vers le nœud défaillant sans affecter l'indexation.

> [!note]
> Lorsque la recherche Zoekt est désactivée, la recherche de code bascule vers le mode de recherche basique. Si Elasticsearch n'est pas disponible, seule la recherche de code à portée de projet est possible en mode de recherche basique, ce qui augmente la charge sur Gitaly.

Prérequis :

- Accès administrateur.

1. dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Rechercher**.
1. Développez **Recherche de code spécifique**.
1. Décochez la case **Activer la recherche**.
1. Sélectionnez **Enregistrer les modifications**.

Une fois le nœud stabilisé, réactivez la recherche :

1. dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Rechercher**.
1. Développez **Recherche de code spécifique**.
1. Cochez la case **Activer la recherche**.
1. Sélectionnez **Enregistrer les modifications**.

### Réduire la pression mémoire {#reduce-memory-pressure}

Si vos nœuds sont correctement dimensionnés mais subissent toujours une pression mémoire, ajustez les paramètres suivants pour réduire l'utilisation de la mémoire.

#### Réduire les processus d'indexation parallèles {#reduce-parallel-indexing-processes}

Prérequis :

- Accès administrateur.

Pour réduire la mémoire maximale de l'indexeur, diminuez le nombre de processus parallèles par tâche d'indexation :

1. dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Rechercher**.
1. Développez **Recherche de code spécifique**.
1. Définissez **Nombre de processus parallèles par tâche d'indexation** sur `1`.
1. Sélectionnez **Enregistrer les modifications**.

#### Réduire les tâches d'indexation simultanées {#reduce-concurrent-indexing-tasks}

Prérequis :

- Accès administrateur.

Pour réduire le nombre de tâches d'indexation s'exécutant simultanément, diminuez la valeur de **Indexation du processeur sur le multiplicateur de tâches** :

1. dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Rechercher**.
1. Développez **Recherche de code spécifique**.
1. Diminuez la valeur de **Indexation du processeur sur le multiplicateur de tâches** (par exemple, à `0.5`).
1. Sélectionnez **Enregistrer les modifications**.

#### Augmenter la probabilité de réindexation forcée {#increase-force-reindexing-probability}

Le serveur web Zoekt mappe en mémoire les fragments d'index. Au fil du temps, l'indexation incrémentielle accumule de nombreux petits fragments, augmentant le nombre de handles mmap ouverts. La réindexation forcée reconstruit les index complètement, en consolidant les fragments en moins de fichiers plus volumineux, ce qui réduit la surcharge mémoire.

Prérequis :

- Accès administrateur.

Pour réduire l'accumulation de fragments, augmentez la probabilité de réindexation forcée :

1. dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Rechercher**.
1. Développez **Recherche de code spécifique**.
1. Augmentez la valeur de **Probabilité de réindexation forcée aléatoire (pourcentage)**. La valeur par défaut est `0.25` (0,25 %). Par exemple, définissez-la sur `1` pour forcer la réindexation d'environ 1 tâche d'indexation incrémentielle sur 100.
1. Sélectionnez **Enregistrer les modifications**.

### Dimensionner correctement le nœud {#right-size-the-node}

Si l'ajustement des paramètres ne résout pas les événements OOM répétés, le nœud a besoin de plus de mémoire. Pour obtenir des conseils sur l'allocation de mémoire en fonction de la taille de votre index, consultez les [recommandations de dimensionnement](_index.md#sizing-recommendations).

Pour les déploiements Kubernetes, augmentez la requête et la limite de mémoire dans votre fichier `values.yaml` du chart Helm. Assurez-vous que la limite de mémoire est égale ou supérieure à la valeur indiquée dans le tableau de dimensionnement pour votre édition de disque.

Pour les déploiements sur VM et sur bare metal, passez à un type d'instance plus grand à partir du tableau de dimensionnement, ou ajoutez des nœuds supplémentaires pour distribuer l'index sur davantage de machines.

Après le redimensionnement, exécutez le bilan de santé pour confirmer la récupération des nœuds :

```shell
gitlab-rake gitlab:zoekt:health
```

## Vérifier les connexions des nœuds Zoekt {#verify-zoekt-node-connections}

Pour vérifier que vos nœuds Zoekt sont correctement configurés et connectés, dans une [session de console Rails](../../administration/operations/rails_console.md#starting-a-rails-console-session) :

- Vérifiez le nombre total de nœuds Zoekt configurés :

  ```ruby
  Search::Zoekt::Node.count
  ```

- Vérifiez combien de nœuds sont en ligne :

  ```ruby
  Search::Zoekt::Node.online.count
  ```

Vous pouvez également utiliser la tâche Rake `gitlab:zoekt:info`.

Si le nombre de nœuds en ligne est inférieur au nombre de nœuds configurés ou est nul alors que des nœuds sont configurés, vous pourriez avoir des problèmes de connectivité entre GitLab et vos nœuds Zoekt.

## Déboguer les erreurs de connexion Zoekt {#debug-zoekt-connection-errors}

Lorsque vous rencontrez des problèmes de connexion avec Zoekt, il est important de comprendre le flux de requêtes et de vérifier systématiquement chaque composant de l'architecture.

### Architecture Zoekt {#zoekt-architecture}

Zoekt utilise un binaire unifié (`gitlab-zoekt`) pouvant fonctionner dans deux modes :

- Mode indexeur pour l'indexation des dépôts depuis Gitaly
- Mode serveur web pour traiter les requêtes de recherche

Le flux de recherche basique est :

```plaintext
GitLab Rails → Zoekt webserver
```

Pour les déploiements avec chart Helm (Kubernetes), l'architecture inclut des composants de passerelle supplémentaires pour l'équilibrage de charge :

```plaintext
GitLab Rails → external gateway (NGINX) → internal gateway (NGINX) → Zoekt webserver
```

Ces composants de passerelle font partie du déploiement du chart Helm, et non des composants internes de Zoekt. Il s'agit de proxies NGINX qui distribuent les requêtes sur plusieurs instances du serveur web Zoekt et gèrent le routage, l'équilibrage de charge et la terminaison TLS optionnelle.

Pour plus d'informations sur la conception de l'architecture Zoekt, consultez [utiliser Zoekt pour la recherche de code](https://handbook.gitlab.com/handbook/engineering/architecture/design-documents/code_search_with_zoekt/).

### Vérifier l'accessibilité réseau {#verify-network-reachability}

Pour vérifier que la passerelle Zoekt est accessible depuis vos pods GitLab Rails, [exécutez un bilan de santé](_index.md#run-a-health-check) :

```shell
gitlab-rake gitlab:zoekt:health
```

Cette tâche vérifie la connectivité de Rails vers Zoekt et indique le statut global comme `HEALTHY`, `DEGRADED` ou `UNHEALTHY`. Si le bilan de santé échoue, des problèmes de connectivité réseau peuvent exister entre GitLab et votre infrastructure Zoekt.

Pour vérifier le statut et la configuration du nœud, exécutez la tâche Rake suivante :

```shell
gitlab-rake gitlab:zoekt:info
```

Pour afficher des informations détaillées sur les nœuds, y compris les URL, dans une [console Rails](../../administration/operations/rails_console.md#starting-a-rails-console-session), exécutez la commande suivante :

```ruby
# View all node attributes including URLs
Search::Zoekt::Node.all.map(&:attributes)
```

- `search_base_url` doit pointer vers le serveur web Zoekt ou la passerelle externe dans Kubernetes (par exemple, `http://gitlab-zoekt:8080/`).
- `index_base_url` doit pointer vers l'indexeur Zoekt.

Si vous obtenez une réponse `404` lors d'une recherche, les requêtes pourraient ne pas être correctement routées. Cette erreur indique que le problème est probablement lié à la configuration de la passerelle plutôt qu'à la connectivité réseau.

### Surveiller les journaux Zoekt {#monitor-zoekt-logs}

Pour les déploiements avec chart Helm (Kubernetes), surveillez les journaux des composants Zoekt pour identifier les problèmes de connexion.

`StatefulSet` contient trois conteneurs :

```shell
# Monitor webserver logs (search requests from Rails)
kubectl logs -f statefulset/gitlab-zoekt -c zoekt-webserver -n <your_namespace>

# Monitor indexer logs (repository indexing)
kubectl logs -f statefulset/gitlab-zoekt -c zoekt-indexer -n <your_namespace>

# Monitor internal gateway logs (NGINX proxy between the external gateway and webserver)
kubectl logs -f statefulset/gitlab-zoekt -c zoekt-internal-gateway -n <your_namespace>
```

Si vous utilisez le déploiement avec passerelle externe, vous pouvez également surveiller les journaux de la passerelle externe :

```shell
# Monitor external gateway logs (NGINX proxy for incoming requests from Rails)
kubectl logs -f deployment/gitlab-zoekt-gateway -c zoekt-external-gateway -n <your_namespace>
```

Pendant que vous surveillez ces journaux, effectuez des recherches de test depuis l'interface GitLab. Les journaux doivent afficher la requête en cours de traitement. Si les requêtes n'apparaissent pas dans les journaux, un problème de routage réseau pourrait exister entre Rails et Zoekt.

### Effectuer des recherches de test depuis l'interface utilisateur {#run-test-searches-from-the-ui}

Pendant que vous surveillez les journaux Zoekt, vous pouvez effectuer des recherches de test depuis l'interface GitLab :

- Effectuez une recherche dans un projet pour des nœuds spécifiques.
- Effectuez une recherche dans un groupe pour interroger plusieurs nœuds.
- Effectuez une recherche globale pour interroger tous les nœuds.

Si les recherches échouent, consultez les journaux de l'application Rails pour obtenir des messages d'erreur détaillés :

```shell
# For installations that use the Linux package
tail -f /var/log/gitlab/gitlab-rails/application_json.log | grep -i zoekt

# For self-compiled installations
tail -f log/application_json.log | grep -i zoekt
```

Recherchez des erreurs de connexion, des délais d'expiration ou des échecs d'authentification susceptibles d'indiquer des problèmes réseau entre GitLab et votre infrastructure Zoekt.

### Vérifier le statut des pods et des services {#verify-pod-and-service-status}

Pour les déploiements avec chart Helm (Kubernetes), vérifiez le statut de vos pods et services Zoekt :

```shell
# Check pod status
kubectl get pods -n <your_namespace> -l app=gitlab-zoekt

# Check `StatefulSet` status
kubectl get statefulset gitlab-zoekt -n <your_namespace>

# Check service endpoints
kubectl get endpoints gitlab-zoekt -n <your_namespace>

# Describe the service to see the configuration
kubectl describe service gitlab-zoekt -n <your_namespace>
```

Assurez-vous que tous les pods sont en état d'exécution et que le service dispose de points de terminaison valides. Si les pods ne sont pas en cours d'exécution ou si les points de terminaison sont manquants, votre déploiement Zoekt pourrait avoir des problèmes de configuration.

Pour plus d'informations sur l'architecture de déploiement, consultez :

- [Configuration du déploiement de la passerelle externe](https://gitlab.com/gitlab-org/cloud-native/charts/gitlab-zoekt/-/blob/main/templates/deployment.yaml)
- [Configuration `StatefulSet` (indexeur, serveur web et passerelle interne)](https://gitlab.com/gitlab-org/cloud-native/charts/gitlab-zoekt/-/blob/main/templates/stateful_sets.yaml)

## Erreur : `TaskRequest responded with [401]` {#error-taskrequest-responded-with-401}

Dans vos journaux d'indexeur Zoekt, vous pouvez voir `TaskRequest responded with [401]`. Cette erreur indique que l'indexeur Zoekt ne parvient pas à s'authentifier auprès de GitLab.

Pour résoudre ce problème, vérifiez que `gitlab-shell-secret` est correctement configuré et correspond entre votre instance GitLab et l'indexeur Zoekt. Par exemple, la sortie de la commande suivante doit correspondre à `gitlab-shell-secret` dans votre `gitlab.rb` :

```shell
kubectl get secret gitlab-shell-secret -o jsonpath='{.data.secret}' -n your_zoekt_namespace | base64 -d
```

## Erreur : `missing selected ALPN property` {#error-missing-selected-alpn-property}

Lorsque vous utilisez un équilibreur de charge externe devant la passerelle Zoekt, vous pouvez voir l'erreur suivante dans vos journaux GitLab :

```plaintext
rpc error: code = Unavailable desc = connection error: desc = "transport: authentication handshake failed: credentials: cannot check peer: missing selected ALPN property"
```

Cette erreur survient lorsque l'équilibreur de charge ne prend pas en charge ou n'annonce pas ALPN (Application-Layer Protocol Negotiation) avec HTTP/2. Zoekt s'appuie sur gRPC pour la communication entre les nœuds, ce qui nécessite la prise en charge de HTTP/2.

Pour résoudre ce problème, effectuez l'une des opérations suivantes :

- Activez la prise en charge de HTTP/2 sur votre équilibreur de charge (recommandé) :

  1. Configurez votre équilibreur de charge pour prendre en charge et annoncer HTTP/2 via ALPN :
     - Pour HAProxy, dans votre backend, assurez-vous que `alpn h2,http/1.1` est configuré.
     - Pour NGINX, dans votre bloc de serveur, utilisez :
       - Dans NGINX 1.25.1 et versions ultérieures, `http2 on;`.
       - Dans NGINX 1.25.0 et versions antérieures, `listen 443 ssl http2;`.
  1. Vérifiez la prise en charge de HTTP/2 :

     ```shell
     curl --verbose --http2 "https://your-zoekt-gateway-url/health" 2>&1 | grep ALPN
     ```

     Vous devriez voir une sortie similaire à :

     ```plaintext
     * ALPN, server accepted to use h2
     ```

- Utilisez le passthrough TLS :

  Si votre équilibreur de charge ne peut pas prendre en charge HTTP/2, configurez-le pour le passthrough TLS. La passerelle Zoekt peut alors gérer directement la terminaison TLS, ce qui garantit une négociation ALPN correcte. Pour utiliser le passthrough TLS, configurez un certificat TLS valide sur la passerelle Zoekt :

  1. Pour les déploiements avec chart Helm, dans votre `values.yaml`, configurez le certificat :

     ```yaml
     gateway:
       tls:
         certificate:
           enabled: true
           secretName: zoekt-gateway-cert
     ```

  1. Configurez votre équilibreur de charge pour laisser passer le trafic chiffré sans terminer le TLS.
