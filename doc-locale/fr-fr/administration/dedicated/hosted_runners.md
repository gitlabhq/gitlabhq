---
stage: Production Engineering
group: Runners Platform
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Utilisez des runners hébergés pour exécuter vos jobs CI/CD sur GitLab Dedicated.
title: Runners hébergés pour GitLab Dedicated
---

{{< details >}}

- Niveau : Ultimate
- Offre : GitLab Dedicated
- Statut :  Disponibilité limitée

{{< /details >}}

> [!note]
> Pour utiliser cette fonctionnalité, vous devez acheter un abonnement pour les Runners hébergés pour GitLab Dedicated. Pour participer à la disponibilité limitée des Runners hébergés pour Dedicated, contactez votre responsable Customer Success ou votre représentant de compte.

Vous pouvez exécuter vos jobs CI/CD sur des [runners](../../ci/runners/_index.md) hébergés par GitLab. Ces runners sont gérés par GitLab et entièrement intégrés à votre instance GitLab Dedicated. Les runners hébergés par GitLab pour Dedicated sont des [runners d'instance](../../ci/runners/runners_scope.md#instance-runners) à mise à l'échelle automatique, s'exécutant sur AWS EC2 dans la même région que l'instance GitLab Dedicated.

Lorsque vous utilisez des runners hébergés :

- Chaque job s'exécute dans une machine virtuelle (VM) nouvellement provisionnée, dédiée au job spécifique.
- La VM sur laquelle votre job s'exécute dispose d'un accès `sudo` sans mot de passe.
- Le stockage est partagé par le système d'exploitation, l'image avec les logiciels pré-installés et une copie de votre dépôt cloné. Cela signifie que l'espace disque libre disponible pour vos jobs est réduit.
- Par défaut, les jobs sans tag s'exécutent sur le petit runner Linux x86-64. Les administrateurs GitLab peuvent [modifier l'option d'exécution des jobs sans tag dans GitLab](#configure-hosted-runners-in-gitlab).

## Runners hébergés sur Linux {#hosted-runners-on-linux}

Les runners hébergés sur Linux pour GitLab Dedicated utilisent l'exécuteur [Docker Autoscaler](https://docs.gitlab.com/runner/executors/docker_autoscaler/). Chaque job obtient un environnement Docker dans une machine virtuelle (VM) entièrement isolée et éphémère, et s'exécute sur la dernière version de Docker Engine.

### Types de machines pour Linux - x86-64 {#machine-types-for-linux---x86-64}

Les types de machines suivants sont disponibles pour les runners hébergés sur Linux x86-64.

| Taille     | Tag de runner                    | vCPUs | Mémoire | Stockage |
|----------|-------------------------------|-------|--------|---------|
| Small    | `linux-small-amd64` (par défaut) | 2     | 8 Go   | 30 Go   |
| Medium   | `linux-medium-amd64`          | 4     | 16 Go  | 50 Go   |
| Large    | `linux-large-amd64`           | 8     | 32 Go  | 100 Go  |
| X-Large  | `linux-xlarge-amd64`          | 16    | 64 Go  | 200 Go  |
| 2X-Large | `linux-2xlarge-amd64`         | 32    | 128 Go | 200 Go  |

### Types de machines pour Linux - Arm64 {#machine-types-for-linux---arm64}

Les types de machines suivants sont disponibles pour les runners hébergés sur Linux Arm64.

| Taille     | Tag de runner            | vCPUs | Mémoire | Stockage |
|----------|-----------------------|-------|--------|---------|
| Small    | `linux-small-arm64`   | 2     | 8 Go   | 30 Go   |
| Medium   | `linux-medium-arm64`  | 4     | 16 Go  | 50 Go   |
| Large    | `linux-large-arm64`   | 8     | 32 Go  | 100 Go  |
| X-Large  | `linux-xlarge-arm64`  | 16    | 64 Go  | 200 Go  |
| 2X-Large | `linux-2xlarge-arm64` | 32    | 128 Go | 200 Go  |

> [!note]
> Le type de machine et le type de processeur sous-jacent peuvent changer. Les jobs optimisés pour une conception de processeur spécifique peuvent se comporter de manière incohérente.

Les tags de runner par défaut sont assignés lors de la création. Les administrateurs peuvent ensuite [modifier les paramètres de tags](#configure-hosted-runners-in-gitlab) pour leurs runners d'instance.

### Images de conteneur {#container-images}

Comme les runners sur Linux utilisent l'exécuteur [Docker Autoscaler](https://docs.gitlab.com/runner/executors/docker_autoscaler/), vous pouvez choisir n'importe quelle image de conteneur en définissant l'image dans votre fichier `.gitlab-ci.yml`. Assurez-vous que l'image Docker sélectionnée est compatible avec l'architecture de processeur sous-jacente. Consultez le [fichier exemple `.gitlab-ci.yml`](../../ci/runners/hosted_runners/linux.md#example-gitlab-ciyml-file).

Si aucune image n'est définie, la valeur par défaut est `ruby:3.1`.

Si vous utilisez des images du registre de conteneurs Docker Hub, vous pourriez rencontrer des [limites de débit](../settings/user_and_ip_rate_limits.md). Cela est dû au fait que GitLab Dedicated utilise une seule adresse IP de traduction d'adresses réseau (NAT).

Pour éviter les limites de débit, utilisez plutôt :

- Les images stockées dans le [registre de conteneurs GitLab](../../user/packages/container_registry/_index.md).
- Les images stockées dans d'autres registres publics sans limites de débit.
- Le [proxy de dépendances](../../user/packages/dependency_proxy/_index.md), agissant comme un cache intermédiaire.

### Prise en charge de Docker dans Docker {#docker-in-docker-support}

Les runners sont configurés pour s'exécuter en mode `privileged` afin de prendre en charge [Docker dans Docker](../../ci/docker/using_docker_build.md#use-docker-in-docker) pour créer des images Docker nativement ou exécuter plusieurs conteneurs dans votre job isolé.

## Gérer les runners hébergés {#manage-hosted-runners}

### Gérer les runners hébergés dans Switchboard {#manage-hosted-runners-in-switchboard}

Vous pouvez créer et afficher des runners hébergés pour votre instance GitLab Dedicated à l'aide de Switchboard.

Prérequis :

- Vous devez acheter un abonnement pour les Runners hébergés pour GitLab Dedicated.

#### Créer des runners hébergés dans Switchboard {#create-hosted-runners-in-switchboard}

Pour chaque instance, vous pouvez créer un runner pour chaque combinaison de type et de taille. Switchboard affiche les options de runner disponibles.

Pour créer des runners hébergés :

1. Connectez-vous à [Switchboard](https://console.gitlab-dedicated.com).
1. En haut de la page, sélectionnez **Hosted runners**.
1. Sélectionnez **New hosted runner**.
1. Choisissez une taille pour le runner, puis sélectionnez **Create hosted runner**.

Vous recevrez une notification par e-mail lorsque votre runner hébergé sera prêt à être utilisé.

Les [connexions PrivateLink sortantes](#outbound-privatelink-connections) configurées pour les runners existants ne s'appliquent pas aux nouveaux runners. Une demande séparée est requise pour chaque nouveau runner.

#### Afficher les runners hébergés dans Switchboard {#view-hosted-runners-in-switchboard}

Pour afficher les runners hébergés :

1. Connectez-vous à [Switchboard](https://console.gitlab-dedicated.com).
1. En haut de la page, sélectionnez **Hosted runners**.
1. Facultatif. Dans la liste des runners hébergés, copiez le **Runner ID** du runner auquel vous souhaitez accéder dans GitLab.

### Afficher et configurer les runners hébergés dans GitLab {#view-and-configure-hosted-runners-in-gitlab}

Les administrateurs GitLab peuvent gérer les runners hébergés pour leur instance GitLab Dedicated depuis la [zone **Admin**](../admin_area.md#administering-runners).

#### Afficher les runners hébergés dans GitLab {#view-hosted-runners-in-gitlab}

Vous pouvez afficher les runners hébergés pour votre instance GitLab Dedicated dans la page Runners et dans le [Tableau de bord de la flotte](../../ci/runners/runner_fleet_dashboard.md).

Prérequis :

- Vous devez être administrateur.

> [!note]
> Les visualisations d'utilisation des ressources de calcul ne sont pas disponibles, mais un [epic](https://gitlab.com/groups/gitlab-com/gl-infra/gitlab-dedicated/-/epics/524) existe pour les ajouter lors de la disponibilité générale.

Pour afficher les runners hébergés dans GitLab :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **CI/CD** > **Runners**.
1. Facultatif. Sélectionnez **Tableau de bord de la flotte**.

#### Configurer les runners hébergés dans GitLab {#configure-hosted-runners-in-gitlab}

Prérequis :

- Vous devez être administrateur.

Vous pouvez configurer les runners hébergés pour votre instance GitLab Dedicated, notamment en modifiant les valeurs par défaut des tags de runner.

Les options de configuration disponibles comprennent :

- [Modifier le délai d'expiration maximum du job](../../ci/runners/configure_runners.md#for-an-instance-runner).
- [Configurer le runner pour exécuter des jobs avec ou sans tag](../../ci/runners/configure_runners.md#for-an-instance-runner-2).

> [!note]
> Toute modification de la description du runner et des tags de runner n'est pas contrôlée par GitLab.

### Désactiver les runners hébergés pour les groupes ou les projets dans GitLab {#disable-hosted-runners-for-groups-or-projects-in-gitlab}

Par défaut, les runners hébergés sont disponibles pour tous les projets et groupes de votre instance GitLab Dedicated. Les mainteneurs GitLab peuvent désactiver les runners hébergés pour un [projet](../../ci/runners/runners_scope.md#disable-instance-runners-for-a-project) ou un [groupe](../../ci/runners/runners_scope.md#disable-instance-runners-for-a-group).

## Sécurité et réseau {#security-and-network}

Les runners hébergés pour GitLab Dedicated disposent de couches intégrées qui renforcent la sécurité de l'environnement de build GitLab Runner.

Les runners hébergés pour GitLab Dedicated ont les configurations suivantes :

- Les règles de pare-feu n'autorisent que les communications sortantes de la VM éphémère vers l'internet public.
- Les règles de pare-feu ne permettent pas les communications entrantes de l'internet public vers la VM éphémère.
- Les règles de pare-feu ne permettent pas les communications entre les VM.
- Seul le gestionnaire de runner peut communiquer avec les VM éphémères.
- Les VM de runner éphémères ne traitent qu'un seul job et sont supprimées après l'exécution du job.

Vous pouvez également [activer les connexions PrivateLink](#outbound-privatelink-connections) depuis les runners hébergés vers votre compte AWS.

Pour plus d'informations, consultez le diagramme d'architecture pour les [runners hébergés pour GitLab Dedicated](architecture.md#hosted-runners-for-gitlab-dedicated).

### Connexions PrivateLink sortantes {#outbound-privatelink-connections}

Les connexions PrivateLink sortantes établissent une connexion sécurisée entre les runners hébergés pour GitLab Dedicated et les services de votre VPC AWS. Cette connexion n'expose aucun trafic à l'internet public et permet aux runners hébergés de :

- Accéder à des services privés, tels que des gestionnaires de secrets personnalisés.
- Récupérer des artefacts ou des images de job stockés dans votre infrastructure.
- Déployer vers votre infrastructure.

Deux connexions PrivateLink sortantes existent par défaut pour tous les runners dans le compte de runner géré par GitLab :

- Une connexion à votre instance GitLab
- Une connexion à une instance Prometheus contrôlée par GitLab

Ces connexions sont pré-configurées et ne peuvent pas être modifiées. L'instance Prometheus du locataire est gérée par GitLab et n'est pas accessible aux utilisateurs.

Pour utiliser une connexion PrivateLink sortante avec d'autres services VPC pour les runners hébergés, [une configuration manuelle est requise via une demande d'assistance](configure_instance/network_security.md#add-an-outbound-privatelink-connection). Pour plus d'informations, consultez [les connexions PrivateLink sortantes](configure_instance/network_security.md#outbound-privatelink-connections).

### Plages IP {#ip-ranges}

Les plages IP pour les runners hébergés pour GitLab Dedicated sont disponibles sur demande. Les plages IP sont maintenues selon le principe du meilleur effort et peuvent changer à tout moment en raison de modifications de l'infrastructure. Pour plus d'informations, contactez votre responsable Customer Success ou votre représentant de compte.

## Utiliser les runners hébergés {#use-hosted-runners}

Après avoir [créé des runners hébergés dans Switchboard](#create-hosted-runners-in-switchboard) et que les runners sont prêts, vous pouvez les utiliser.

Pour utiliser des runners, ajustez les [tags](../../ci/yaml/_index.md#tags) dans la configuration de votre job dans le fichier `.gitlab-ci.yml` afin de correspondre au runner hébergé que vous souhaitez utiliser.

Pour le runner Linux medium x86-64, configurez votre job comme suit :

   ```yaml
   job_name:
     tags:
       - linux-medium-amd64  # Use the medium-sized Linux runner
   ```

Par défaut, les jobs sans tag sont pris en charge par le petit runner Linux x86-64. Les administrateurs GitLab peuvent [configurer les runners d'instance dans GitLab](#configure-hosted-runners-in-gitlab) pour ne pas exécuter les jobs sans tag.

Pour migrer des jobs sans modifier les configurations de job, [modifiez les tags des runners hébergés](#configure-hosted-runners-in-gitlab) afin de les faire correspondre aux tags utilisés dans vos configurations de job existantes.

Si vous constatez que votre job est bloqué avec le message d'erreur `no runners that match all of the job's tags` :

1. Vérifiez si vous avez sélectionné le bon tag
1. Confirmez si [les runners d'instance sont activés pour votre projet ou groupe](../../ci/runners/runners_scope.md#enable-instance-runners-for-a-project).

## Mises à niveau {#upgrades}

Les mises à niveau de version de runner nécessitent une courte interruption de service. Les runners sont mis à niveau pendant les fenêtres de maintenance planifiées d'un locataire GitLab Dedicated. Un [ticket](https://gitlab.com/gitlab-com/gl-infra/gitlab-dedicated/team/-/issues/4505) existe pour mettre en œuvre des mises à niveau sans interruption de service.

## Tarification {#pricing}

Pour les détails de tarification, contactez votre représentant de compte.

Nous offrons un essai gratuit de 30 jours pour les clients GitLab Dedicated. L'essai comprend :

- Runners Linux x86-64 Small, Medium et Large
- Runners Linux Arm Small et Medium
- Configuration de mise à l'échelle automatique limitée prenant en charge jusqu'à 100 jobs simultanés
