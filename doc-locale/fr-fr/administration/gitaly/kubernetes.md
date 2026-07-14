---
stage: Tenant Scale
group: Gitaly
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Gitaly sur Kubernetes
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- Introduit dans GitLab 17.3 en tant qu'[expérimentation](../../policy/development_stages_support.md).
- Passage de l'expérimentation à la version bêta dans GitLab 17.10.
- Passage de la version bêta à la disponibilité limitée dans GitLab 18.2.
- Passage de la disponibilité limitée à la disponibilité générale dans GitLab 18.11.

{{< /history >}}

L'exécution de Gitaly sur Kubernetes implique des compromis en termes de disponibilité. Tenez compte de ces compromis lors de la planification d'un environnement de production et définissez les attentes en conséquence. Ce document décrit et fournit des conseils sur la façon de minimiser et de planifier les limitations existantes.

Gitaly sur Kubernetes a été évalué par l'équipe Gitaly et jugé comme étant un moyen sûr de déployer Gitaly. Le reste de ce document présente les meilleures pratiques pour ce faire.

## Calendrier {#timeline}

[Gitaly sur Kubernetes](kubernetes.md) est en disponibilité générale depuis GitLab 18.11. GitLab ne garantit pas la compatibilité avec des offres Kubernetes gérées spécifiques de fournisseurs cloud (tels qu'Amazon EKS, Google GKE ou Azure AKS). Vous devez valider votre environnement spécifique avant de déployer en production.

## Contexte {#context}

Par conception, Gitaly (non-Cluster) est un service à point unique de défaillance (SPoF). Les données sont sourcées et servies à partir d'une instance unique. Pour Kubernetes, lorsque le pod StatefulSet est remplacé (par exemple, lors de mises à niveau, de maintenance de nœud ou d'éviction), le remplacement provoque une interruption de service pour les données servies par le pod ou l'instance.

Dans une configuration [Cloud Native Hybrid](../reference_architectures/1k_users.md#cloud-native-hybrid-reference-architecture-with-helm-charts) (Gitaly VM), le paquet Linux (Omnibus) masque le problème en :

1. Mettant à niveau le binaire Gitaly en place.
1. Effectuant un rechargement progressif.

La même approche ne convient pas à un cycle de vie basé sur des conteneurs, où un conteneur ou un pod doit s'arrêter complètement et démarrer en tant que nouveau conteneur ou pod.

Gitaly Cluster (Praefect) résout l'aspect de haute disponibilité des données et du service en répliquant les données entre les instances. Cependant, Gitaly Cluster (Praefect) ne convient pas pour s'exécuter dans Kubernetes en raison des [problèmes existants et des contraintes de conception](praefect/_index.md#known-issues) qui sont amplifiés par une plateforme basée sur des conteneurs.

Pour prendre en charge un déploiement Cloud Native, Gitaly (non-Cluster) est la seule option. En tirant parti des bonnes fonctionnalités et configurations de Kubernetes et de Gitaly, vous pouvez minimiser les interruptions de service et offrir une bonne expérience utilisateur.

## Prérequis {#requirements}

Les informations sur cette page supposent :

- Version de Kubernetes égale ou supérieure à `1.29`.
- Version `runc` du nœud Kubernetes égale ou supérieure à `1.1.9`.
- Nœud Kubernetes cgroup v2. Le mode hybride natif v1 n'est pas pris en charge. Seule la [structure cgroup de style `systemd`](https://kubernetes.io/docs/setup/production-environment/container-runtimes/#systemd-cgroup-driver) est prise en charge (valeur par défaut de Kubernetes).
- Accès du pod au point de montage du nœud `/sys/fs/cgroup`.
- containerd version 2.1.0 ou ultérieure.
- Accès du conteneur init du pod (`init-cgroups`) aux permissions du système de fichiers de l'utilisateur `root` sur `/sys/fs/cgroup`. Utilisé pour déléguer le cgroup du pod au conteneur Gitaly (utilisateur `git`, UID `1000`).
- Le système de fichiers cgroups n'est pas monté avec l'indicateur `nsdelegate`. Pour plus d'informations, consultez le ticket Gitaly [6480](https://gitlab.com/gitlab-org/gitaly/-/issues/6480).

## Guide {#guidance}

Lors de l'exécution de Gitaly dans Kubernetes, vous devez :

- [Gérer les perturbations des pods](#address-pod-disruption).
- [Gérer la contention et la saturation des ressources](#address-resource-contention-and-saturation).
- [Optimiser le temps de rotation des pods](#optimize-pod-rotation-time).
- [Surveiller l'utilisation du disque](#monitor-disk-usage)

### Activer le champ `cgroup_writable` dans containerd {#enable-cgroup_writable-field-in-containerd}

La prise en charge des cgroups dans Gitaly nécessite un accès en écriture aux cgroups pour les conteneurs non privilégiés. containerd v2.1.0 a introduit l'option de configuration `cgroup_writable`. Lorsque cette option est activée, elle garantit que le système de fichiers cgroups est monté avec des permissions de lecture/écriture.

Pour activer ce champ, effectuez les étapes suivantes sur les nœuds où Gitaly sera déployé. Si Gitaly est déjà déployé, les pods doivent être recréés après la modification de la configuration.

1. Modifiez le fichier de configuration containerd situé à `/etc/containerd/config.toml` pour inclure le champ `cgroup_writable` :

   ```toml
   [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc]
   runtime_type = "io.containerd.runc.v2"
   cgroup_writable = true
   ```

1. Redémarrez les services Kubelet et containerd :

   ```shell
   sudo systemctl restart kubelet
   sudo systemctl restart containerd
   ```

   Ces commandes peuvent marquer le nœud comme NotReady si les services mettent un certain temps à redémarrer.

### Gérer les perturbations des pods {#address-pod-disruption}

Un pod peut être remplacé pour de nombreuses raisons. Comprendre et planifier le cycle de vie du service aide à minimiser les perturbations.

Par exemple, avec Gitaly, un `StatefulSet` Kubernetes effectue une rotation lors des modifications de l'objet `spec.template`, ce qui peut se produire lors des mises à niveau du Helm Chart (labels ou tags d'image) ou des mises à jour des demandes ou limites de ressources du pod.

Cette section se concentre sur les cas courants de perturbation des pods et sur la manière de les gérer.

#### Planifier des fenêtres de maintenance {#schedule-maintenance-windows}

Étant donné que le service n'est pas hautement disponible, certaines opérations peuvent provoquer de brèves interruptions de service. La planification de fenêtres de maintenance signale les perturbations de service potentielles et aide à définir les attentes. Vous devez utiliser des fenêtres de maintenance pour :

- Les mises à niveau et reconfigurations du Helm chart GitLab.
- Les modifications de configuration de Gitaly.
- Les fenêtres de maintenance des nœuds Kubernetes. Par exemple, les mises à niveau et les correctifs. L'isolation de Gitaly dans son propre pool de nœuds dédié peut être utile.

#### Utiliser `PriorityClass` {#use-priorityclass}

Utilisez [PriorityClass](https://kubernetes.io/docs/concepts/scheduling-eviction/pod-priority-preemption/#priorityclass) pour attribuer aux pods Gitaly une priorité plus élevée par rapport aux autres pods, afin d'aider à gérer la pression de saturation des nœuds, la priorité d'éviction et la latence de planification :

1. Créez une classe de priorité :

   ```yaml
   apiVersion: scheduling.k8s.io/v1
   kind: PriorityClass
   metadata:
     name: gitlab-gitaly
   value: 1000000
   globalDefault: false
   description: "GitLab Gitaly priority class"
   ```

1. Attribuez la classe de priorité aux pods Gitaly :

   ```yaml
   gitlab:
     gitaly:
       priorityClassName: gitlab-gitaly
   ```

#### Signaler la mise à l'échelle automatique des nœuds pour prévenir l'éviction {#signal-node-autoscaling-to-prevent-eviction}

Les outils de mise à l'échelle automatique des nœuds ajoutent et suppriment des nœuds Kubernetes selon les besoins pour planifier les pods et optimiser les coûts.

Lors des événements de réduction d'échelle, le pod Gitaly peut être évincé pour optimiser l'utilisation des ressources. Des annotations sont généralement disponibles pour contrôler ce comportement et exclure des charges de travail. Par exemple, avec Cluster Autoscaler :

```yaml
gitlab:
  gitaly:
    annotations:
      cluster-autoscaler.kubernetes.io/safe-to-evict: "false"
```

### Gérer la contention et la saturation des ressources {#address-resource-contention-and-saturation}

L'utilisation des ressources du service Gitaly peut être imprévisible en raison de la nature indéterminable des opérations Git. Tous les dépôts ne sont pas identiques et la taille influence fortement les performances et l'utilisation des ressources, en particulier pour les [monorepos](../../user/project/repository/monorepos/_index.md).

Dans Kubernetes, une utilisation non contrôlée des ressources peut entraîner des événements Out Of Memory (OOM), ce qui force la plateforme à terminer le pod et à arrêter tous ses processus. La terminaison d'un pod soulève deux préoccupations importantes :

- Corruption des données/dépôt
- Interruption de service

Cette section se concentre sur la réduction de la portée de l'impact et la protection du service dans son ensemble.

#### Limiter l'utilisation des ressources des processus Git {#constrain-git-processes-resource-usage}

L'isolation des processus Git garantit qu'un seul appel Git ne peut pas consommer toutes les ressources du service et du pod.

Gitaly peut utiliser les [Control Groups Linux (cgroups)](cgroups.md) pour imposer des quotas d'utilisation des ressources plus petits, par dépôt.

Vous devez maintenir les quotas cgroup en dessous de l'allocation globale des ressources du pod. Le CPU n'est pas critique car il ne fait que ralentir le service. Cependant, la saturation de la mémoire peut entraîner la terminaison du pod. Un tampon mémoire de 1 Gio entre la demande du pod et l'allocation cgroup Git est un bon point de départ. Le dimensionnement du tampon dépend des schémas de trafic et des données du dépôt.

Par exemple, avec une demande de mémoire de pod de 15 Gio, 14 Gio sont alloués aux appels Git :

```yaml
gitlab:
  gitaly:
    cgroups:
      enabled: true
      # Total limit across all repository cgroups, excludes Gitaly process
      memoryBytes: 15032385536 # 14GiB
      cpuShares: 1024
      cpuQuotaUs: 400000 # 4 cores
      # Per repository limits, 50 repository cgroups
      repositories:
        count: 50
        memoryBytes: 7516192768 # 7GiB
        cpuShares: 512
        cpuQuotaUs: 200000 # 2 cores
```

Pour plus d'informations, consultez la [documentation de configuration de Gitaly](configure_gitaly.md#control-groups).

#### Dimensionner correctement les ressources du pod {#right-size-pod-resources}

Le dimensionnement du pod Gitaly est critique et les [architectures de référence](../reference_architectures/_index.md#cloud-native-hybrid) fournissent quelques conseils comme point de départ. Cependant, les différents dépôts et les modèles d'utilisation consomment des degrés variables de ressources. Vous devez surveiller l'utilisation des ressources et l'ajuster en conséquence au fil du temps.

La mémoire est la ressource la plus sensible dans Kubernetes car un manque de mémoire peut déclencher la terminaison du pod. [L'isolation des appels Git avec les cgroups](#constrain-git-processes-resource-usage) aide à restreindre l'utilisation des ressources pour les opérations sur les dépôts, mais cela n'inclut pas le service Gitaly lui-même. Conformément à la recommandation précédente sur les quotas cgroup, ajoutez un tampon entre l'allocation mémoire cgroup Git globale et la demande de mémoire du pod pour améliorer la sécurité.

Une classe `Guaranteed` de [qualité de service](https://kubernetes.io/docs/tasks/configure-pod-container/quality-service-pod/) du pod est préférable (les demandes de ressources correspondent aux limites). Avec ce paramètre, le pod est moins susceptible d'être affecté par la contention des ressources et ne sera jamais évincé en raison de la consommation d'autres pods.

Exemple de configuration des ressources :

```yaml
gitlab:
  gitaly:
    resources:
      requests:
        cpu: 4000m
        memory: 15Gi
      limits:
        cpu: 4000m
        memory: 15Gi

    init:
      resources:
        requests:
          cpu: 50m
          memory: 32Mi
        limits:
          cpu: 50m
          memory: 32Mi
```

#### Configurer la limitation de la concurrence {#configure-concurrency-limiting}

Vous pouvez utiliser des limites de concurrence pour aider à protéger le service contre les schémas de trafic anormaux. Pour plus d'informations, consultez la [documentation de configuration de la concurrence](concurrency_limiting.md) et [comment surveiller les limites](monitoring.md#monitor-gitaly-concurrency-limiting).

#### Isoler les pods Gitaly {#isolate-gitaly-pods}

Lors de l'exécution de plusieurs pods Gitaly, vous devez les planifier sur différents nœuds pour répartir le domaine de défaillance. Cela peut être appliqué à l'aide de l'anti-affinité des pods. Par exemple :

```yaml
gitlab:
  gitaly:
    antiAffinity: hard
```

### Optimiser le temps de rotation des pods {#optimize-pod-rotation-time}

Cette section couvre les domaines d'optimisation pour réduire les temps d'arrêt lors d'événements de maintenance ou d'événements d'infrastructure non planifiés, en réduisant le temps nécessaire au pod pour commencer à servir le trafic.

#### Permissions des volumes persistants {#persistent-volume-permissions}

À mesure que la taille des données augmente (historique Git et davantage de dépôts), le pod prend de plus en plus de temps à démarrer et à devenir prêt.

Lors de l'initialisation du pod, dans le cadre du montage du volume persistant, les permissions du système de fichiers et la propriété sont explicitement définies sur le `uid` et le `gid` du conteneur. Cette opération s'exécute par défaut et peut considérablement ralentir le temps de démarrage du pod car les données Git stockées contiennent de nombreux petits fichiers.

Ce comportement est configurable avec l'attribut [`fsGroupChangePolicy`](https://kubernetes.io/docs/tasks/configure-pod-container/security-context/#configure-volume-permission-and-ownership-change-policy-for-pods). Utilisez cet attribut pour effectuer l'opération uniquement si le `uid` ou le `gid` racine du volume ne correspond pas aux spécifications du conteneur :

```yaml
gitlab:
  gitaly:
    securityContext:
      fsGroupChangePolicy: OnRootMismatch
```

#### Sondes de disponibilité {#health-probes}

Le pod Gitaly commence à servir le trafic une fois que la sonde de disponibilité réussit. Les délais de sonde par défaut sont conservateurs pour couvrir la plupart des cas d'utilisation. La réduction de l'attribut `readinessProbe` `initialDelaySeconds` déclenche les sondes plus tôt, ce qui accélère la disponibilité du pod. Par exemple :

```yaml
gitlab:
  gitaly:
    statefulset:
      readinessProbe:
        initialDelaySeconds: 2
        periodSeconds: 10
        timeoutSeconds: 3
        successThreshold: 1
        failureThreshold: 3
```

#### Délai d'arrêt progressif de Gitaly {#gitaly-graceful-shutdown-timeout}

Par défaut, lors de la terminaison, Gitaly accorde un délai d'attente de 1 minute pour que les requêtes en cours se terminent. Bien que bénéfique à première vue, ce délai d'attente :

- Ralentit la rotation des pods.
- Réduit la disponibilité en rejetant les requêtes pendant le processus d'arrêt.

Une meilleure approche dans un déploiement basé sur des conteneurs consiste à s'appuyer sur la logique de nouvelle tentative côté client. Vous pouvez reconfigurer le délai d'attente en utilisant le champ `gracefulRestartTimeout`. Par exemple, pour accorder un délai d'arrêt progressif de 1 seconde :

```yaml
gitlab:
  gitaly:
    gracefulRestartTimeout: 1
```

### Surveiller l'utilisation du disque {#monitor-disk-usage}

Surveillez régulièrement l'utilisation du disque pour les conteneurs Gitaly à longue durée d'exécution, car la croissance des fichiers journaux peut causer des problèmes de stockage si la [rotation des journaux n'est pas activée](https://docs.gitlab.com/charts/charts/globals/#log-rotation).

## Migrer vers Gitaly sur Kubernetes {#migrate-to-gitaly-on-kubernetes}

Pour migrer les dépôts existants depuis des nœuds Gitaly non-Kubernetes vers Gitaly sur Kubernetes :

1. Déployez vos nœuds Gitaly sur Kubernetes et [ajoutez-les comme nouveaux stockages de dépôts](../repository_storage_paths.md#configure-where-new-repositories-are-stored) dans la zone d'administration GitLab. Configurez les pondérations de stockage afin que tous les nouveaux dépôts soient créés sur les nouveaux stockages de dépôts. Cela empêche la création de nouveaux projets sur les anciens stockages de dépôts pendant que la migration est en cours.
1. Utilisez l'API de déplacement de dépôt pour déplacer les dépôts existants vers les nouveaux stockages. Les dépôts GitLab peuvent être associés à des projets, des groupes et des extraits de code, et chaque type possède une API distincte. Pour des instructions complètes, consultez [déplacement des dépôts gérés par GitLab](../operations/moving_repositories.md).

Chaque dépôt est mis en lecture seule pendant toute la durée du déplacement et n'est pas accessible en écriture jusqu'à ce que le déplacement soit terminé.
