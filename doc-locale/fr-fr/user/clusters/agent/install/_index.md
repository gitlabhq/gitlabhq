---
stage: Verify
group: Runner Core
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: "Installation de l'agent pour Kubernetes"
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Pour connecter un cluster Kubernetes à GitLab, vous devez installer un agent dans votre cluster.

## Prérequis {#prerequisites}

Avant de pouvoir installer l'agent dans votre cluster, vous avez besoin de :

- Un [cluster Kubernetes existant auquel vous pouvez vous connecter depuis votre terminal local](https://kubernetes.io/docs/tasks/access-application-cluster/access-cluster/). Si vous n'avez pas de cluster, vous pouvez en créer un chez un fournisseur cloud, comme :
  - [Amazon Elastic Kubernetes Service (EKS)](https://docs.aws.amazon.com/eks/latest/userguide/getting-started.html)
  - [Azure Kubernetes Service (AKS)](https://learn.microsoft.com/en-us/azure/aks/what-is-aks)
  - [Digital Ocean](https://docs.digitalocean.com/products/kubernetes/getting-started/quickstart/)
  - [Google Kubernetes Engine (GKE)](https://docs.cloud.google.com/kubernetes-engine/docs/deploy-app-cluster)
  - Vous devriez utiliser des [techniques d'Infrastructure as Code](../../../infrastructure/iac/_index.md) pour gérer les ressources d'infrastructure à grande échelle.
- Accès à un serveur d'agent :
  - Sur GitLab.com, le serveur d'agent est disponible à l'adresse `grpcs://kas.gitlab.com`. L'adresse WebSocket `wss://kas.gitlab.com` est également disponible.
  - Sur GitLab Self-Managed, un administrateur GitLab doit configurer le [serveur d'agent](../../../../administration/clusters/kas.md). Il est ensuite disponible par défaut à l'adresse `wss://gitlab.example.com/-/kubernetes-agent/`.
  - Sur GitLab Dedicated, le serveur d'agent est disponible à l'adresse `wss://kas.<instance-domain>`, par exemple `wss://kas.example.gitlab-dedicated.com`. Si vous utilisez un [domaine personnalisé](../../../../administration/dedicated/configure_instance/network_security.md#custom-domains) pour votre instance GitLab Dedicated, vous pouvez également utiliser un domaine personnalisé pour le service KAS.

## Amorcer l'agent avec le support Flux (recommandé) {#bootstrap-the-agent-with-flux-support-recommended}

Vous pouvez installer l'agent en l'amorçant avec le [GitLab CLI (`glab`)](../../../../editor_extensions/gitlab_cli/_index.md) et Flux.

Prérequis :

- Les outils de ligne de commande suivants sont installés :
  - `glab`
  - `kubectl`
  - `flux`
- Vous disposez d'une connexion locale au cluster qui fonctionne avec `kubectl` et `flux`.
- Vous avez [amorcé Flux](https://fluxcd.io/flux/installation/bootstrap/gitlab/) dans le cluster avec `flux bootstrap`.
  - Assurez-vous d'amorcer Flux et l'agent dans des répertoires compatibles. Si vous avez amorcé Flux avec l'option `--path`, vous devez passer la même valeur à l'option `--manifest-path` de la commande `glab cluster agent bootstrap`.

Pour installer l'agent, au choix :

- Exécutez `glab cluster agent bootstrap` dans le répertoire du dépôt Git de votre projet cible :

  ```shell
  glab cluster agent bootstrap <agent-name> --manifest-path <same_path_used_in_flux_bootstrap>
  ```

- Exécutez `glab -R path-with-namespace cluster agent bootstrap` si vous devez exécuter la commande en dehors du dépôt Git de votre projet cible :

  ```shell
  glab -R <full/path/to/project> cluster agent bootstrap <agent-name> --manifest-path <same_path_used_in_flux_bootstrap>
  ```

Par défaut, la commande :

1. Enregistre l'agent.
1. Configure l'agent.
1. Configure un environnement avec un tableau de bord pour l'agent.
1. Crée un jeton d'agent.
1. Dans le cluster, crée un secret Kubernetes avec le jeton d'agent.
1. Commit les ressources Helm Flux dans le dépôt Git.
1. Déclenche une réconciliation Flux.

Pour les options de personnalisation, exécutez `glab cluster agent bootstrap --help`. Il est recommandé d'utiliser au minimum l'option `--path <flux_manifests_directory>`.

## Installer l'agent manuellement {#install-the-agent-manually}

L'installation de l'agent dans votre cluster s'effectue en trois étapes :

1. Facultatif. [Créer un fichier de configuration de l'agent](#create-an-agent-configuration-file).
1. [Enregistrer l'agent auprès de GitLab](#register-the-agent-with-gitlab).
1. [Installer l'agent dans votre cluster](#install-the-agent-in-the-cluster).

<i class="fa-youtube-play" aria-hidden="true"></i> Regardez une [présentation détaillée de ce processus](https://www.youtube.com/watch?v=XuBpKtsgGkE).
<!-- Video published on 2021-09-02 -->

### Créer un fichier de configuration de l'agent {#create-an-agent-configuration-file}

Pour les paramètres de configuration, l'agent utilise un fichier YAML dans le projet GitLab. L'ajout d'un fichier de configuration de l'agent est facultatif. Vous devez créer ce fichier si :

- Vous utilisez [un workflow GitLab CI/CD](../ci_cd_workflow.md#use-gitlab-cicd-with-your-cluster) et souhaitez autoriser un autre projet ou groupe à accéder à l'agent.
- Vous [autorisez des membres spécifiques d'un projet ou d'un groupe à accéder à Kubernetes](../user_access.md).

Pour créer un fichier de configuration de l'agent :

1. Choisissez un nom pour votre agent. Le nom de l'agent suit le [standard d'étiquette DNS défini par la RFC 1123](https://www.rfc-editor.org/info/rfc1123/). Le nom doit :

   - Être unique dans le projet.
   - Contenir au maximum 63 caractères.
   - Contenir uniquement des caractères alphanumériques en minuscules ou `-`.
   - Commencer par un caractère alphanumérique.
   - Se terminer par un caractère alphanumérique.

1. Dans le dépôt, dans la branche par défaut, créez un fichier de configuration de l'agent à l'emplacement suivant :

   ```plaintext
   .gitlab/agents/<agent-name>/config.yaml
   ```

Vous pouvez laisser le fichier vide pour l'instant et le [configurer](../work_with_agent.md#configure-your-agent) ultérieurement.

### Enregistrer l'agent auprès de GitLab {#register-the-agent-with-gitlab}

#### Option 1 : l'agent se connecte à GitLab {#option-1-agent-connects-to-gitlab}

Vous pouvez créer un nouvel enregistrement d'agent directement depuis l'interface utilisateur GitLab. L'agent peut être enregistré sans créer de fichier de configuration d'agent.

Vous devez enregistrer un agent avant de pouvoir l'installer dans votre cluster. Pour enregistrer un agent :

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à**, puis recherchez votre projet. Si vous disposez d'un [fichier de configuration d'agent](#create-an-agent-configuration-file), celui-ci doit se trouver dans ce projet. Les fichiers manifeste de votre cluster doivent également se trouver dans ce projet.
1. Sélectionnez **Opération** > **Clusters Kubernetes**.
1. Sélectionnez **Connecter un cluster (agent)**.
1. Dans le champ **Nom du nouvel agent**, saisissez un nom unique pour votre agent.
   - Si un [fichier de configuration d'agent](#create-an-agent-configuration-file) portant ce nom existe déjà, il est utilisé.
   - Si aucune configuration n'existe pour ce nom, un nouvel agent est créé avec la configuration par défaut.
1. Sélectionnez **Créer et enregistrer**.
1. GitLab génère un jeton d'accès pour l'agent. Vous avez besoin de ce jeton pour installer l'agent dans votre cluster.

   > [!warning]
   > Stockez le jeton d'accès de l'agent de manière sécurisée. Un acteur malveillant peut utiliser ce jeton pour accéder au code source du projet de configuration de l'agent, accéder au code source de n'importe quel projet public sur l'instance GitLab, ou même, dans des conditions très spécifiques, obtenir un manifeste Kubernetes.

1. Copiez la commande sous **Méthode d'installation recommandée**. Vous en avez besoin lorsque vous utilisez la méthode d'installation en une seule ligne pour installer l'agent dans votre cluster.

#### Option 2 : GitLab se connecte à l'agent (agent réceptif) {#option-2-gitlab-connects-to-agent-receptive-agent}

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

{{< history >}}

- [Introduction](https://gitlab.com/groups/gitlab-org/-/work_items/12180) dans GitLab 17.4.

{{< /history >}}

> [!note]
> La release du chart Helm de l'agent GitLab ne prend pas entièrement en charge l'authentification mTLS. Vous devez plutôt vous authentifier avec la méthode JWT. Le support de mTLS est suivi dans le [ticket 64](https://gitlab.com/gitlab-org/charts/gitlab-agent/-/issues/64).

Les [agents réceptifs](../_index.md#receptive-agents) permettent à GitLab de s'intégrer aux clusters Kubernetes qui ne peuvent pas établir de connexion réseau vers l'instance GitLab, mais vers lesquels GitLab peut se connecter.

1. Suivez les étapes de l'option 1 pour enregistrer un agent dans votre cluster. Enregistrez le jeton d'agent et la commande d'installation pour plus tard, mais n'installez pas encore l'agent.
1. Préparez une méthode d'authentification.

   La connexion de GitLab à l'agent peut être en gRPC en clair (`grpc://`) ou en gRPC chiffré (`grpcs://`, recommandé). GitLab peut s'authentifier auprès de l'agent dans votre cluster en utilisant :
   - Un jeton JWT. Disponible dans les configurations `grpc://` et `grpcs://`. Vous n'avez pas besoin de générer des certificats client avec cette méthode.
1. Ajoutez une configuration d'URL à l'agent avec l'[API des agents de cluster](../../../../api/cluster_agents.md#create-a-url-configuration). Si vous supprimez la configuration d'URL, l'agent réceptif devient un agent ordinaire. Vous pouvez associer un agent réceptif à une seule configuration d'URL à la fois.
1. Installez l'agent dans le cluster. Utilisez la commande que vous avez copiée lors de l'enregistrement de l'agent, mais supprimez le paramètre `--set config.kasAddress=...`.

   Exemple d'authentification par jeton JWT. Notez les paramètres ajoutés `config.receptive.enabled=true` et `config.api.jwt` :

   ```shell
   helm repo add gitlab https://charts.gitlab.io
   helm repo update
   helm upgrade --install my-agent gitlab/gitlab-agent \
    --namespace ns \
    --create-namespace \
    --set config.token=.... \
    --set config.receptive.enabled=true \
    --set config.api.jwtPublicKey=<public_key from the response>
   ```

GitLab peut mettre jusqu'à 10 minutes avant de commencer à tenter d'établir une connexion avec le nouvel agent.

### Installer l'agent dans le cluster {#install-the-agent-in-the-cluster}

Pour connecter votre cluster à GitLab, [installez l'agent enregistré avec Helm](#install-the-agent-with-helm).

Pour installer un agent réceptif, suivez les étapes de la section [GitLab se connecte à l'agent (agent réceptif)](#option-2-gitlab-connects-to-agent-receptive-agent).

> [!note]
> Pour vous connecter à plusieurs clusters, vous devez configurer, enregistrer et installer un agent dans chaque cluster. Assurez-vous de donner à chaque agent un nom unique.

#### Installer l'agent avec Helm {#install-the-agent-with-helm}

> [!warning]
> Par souci de simplicité, la configuration par défaut du chart Helm configure un compte de service pour l'agent avec les droits `cluster-admin`. Vous ne devriez pas l'utiliser sur des systèmes de production. Pour déployer sur un système de production, suivez les instructions de la section [Personnaliser l'installation Helm](#customize-the-helm-installation) afin de créer un compte de service avec les autorisations minimales requises pour votre déploiement et de les spécifier lors de l'installation.

Pour installer l'agent sur votre cluster avec Helm :

1. [Installez le CLI Helm](https://helm.sh/docs/intro/install/).
1. Sur votre ordinateur, ouvrez un terminal et [connectez-vous à votre cluster](https://kubernetes.io/docs/tasks/access-application-cluster/access-cluster/).
1. Exécutez la commande que vous avez copiée lorsque vous avez [enregistré votre agent auprès de GitLab](#register-the-agent-with-gitlab). La commande devrait ressembler à ceci :

   ```shell
   helm repo add gitlab https://charts.gitlab.io
   helm repo update
   helm upgrade --install test gitlab/gitlab-agent \
       --namespace gitlab-agent-test \
       --create-namespace \
       --set image.tag=<current agentk version> \
       --set config.token=<your_token> \
       --set config.kasAddress=<address_to_GitLab_KAS_instance>
   ```

1. Facultatif. [Personnaliser l'installation Helm](#customize-the-helm-installation). Si vous installez l'agent sur un système de production, vous devriez personnaliser l'installation Helm pour restreindre les autorisations du compte de service. Les options de personnalisation associées sont décrites ci-dessous.

##### Personnaliser l'installation Helm {#customize-the-helm-installation}

Par défaut, la commande d'installation Helm générée par GitLab :

- Crée un espace de nommage `gitlab-agent` pour le déploiement (`--namespace gitlab-agent`). Vous pouvez ignorer la création de l'espace de nommage en omettant le flag `--create-namespace`.
- Configure un compte de service pour l'agent et lui attribue le rôle `cluster-admin`. Vous pouvez :
  - Ignorez la création du compte de service en ajoutant `--set serviceAccount.create=false` à la commande `helm install`. Dans ce cas, vous devez définir `serviceAccount.name` sur un compte de service préexistant.
  - Personnalisez le rôle attribué au compte de service en ajoutant `--set rbac.useExistingRole <your role name>` à la commande `helm install`. Dans ce cas, vous devez disposer d'un rôle précréé avec des autorisations restreintes pouvant être utilisé par le compte de service.
  - Ignorez entièrement l'attribution de rôle en ajoutant `--set rbac.create=false` à votre commande `helm install`. Dans ce cas, vous devez créer `ClusterRoleBinding` manuellement.
- Crée une ressource `Secret` pour le jeton d'accès de l'agent. Pour utiliser votre propre secret avec un jeton, omettez le jeton (`--set token=...`) et utilisez à la place `--set config.secretName=<your secret name>`.
- Crée une ressource `Deployment` pour le pod `agentk`.

Pour consulter la liste complète des personnalisations disponibles, référez-vous au [README](https://gitlab.com/gitlab-org/charts/gitlab-agent/-/blob/main/README.md#values) du chart Helm.

##### Utiliser l'agent lorsque KAS est derrière un certificat auto-signé {#use-the-agent-when-kas-is-behind-a-self-signed-certificate}

Lorsque [KAS](../../../../administration/clusters/kas.md) est derrière un certificat auto-signé, vous pouvez définir la valeur de `config.kasCaCert` sur le certificat. Par exemple :

```shell
helm upgrade --install gitlab-agent gitlab/gitlab-agent \
  --set-file config.kasCaCert=my-custom-ca.pem
```

Dans cet exemple, `my-custom-ca.pem` est le chemin vers un fichier local contenant le certificat CA utilisé par KAS. Le certificat est automatiquement stocké dans une config map et monté dans le pod `agentk`.

Si KAS est installé avec le chart GitLab et que ce chart est configuré pour fournir un [certificat wildcard auto-signé généré automatiquement](https://docs.gitlab.com/charts/installation/tls/#option-4-use-auto-generated-self-signed-wildcard-certificate), vous pouvez extraire le certificat CA depuis le secret `RELEASE-wildcard-tls-ca`.

##### Utiliser l'agent derrière un proxy HTTP {#use-the-agent-behind-an-http-proxy}

Pour configurer un proxy HTTP lors de l'utilisation du chart Helm, vous pouvez utiliser les variables d'environnement `HTTP_PROXY`, `HTTPS_PROXY` et `NO_PROXY`. Les majuscules et les minuscules sont toutes deux acceptées.

Vous pouvez définir ces variables en utilisant la valeur `extraEnv`, sous la forme d'une liste d'objets avec les clés `name` et `value`. Par exemple, pour définir uniquement la variable d'environnement `HTTPS_PROXY` à la valeur `https://example.com/proxy`, vous pouvez exécuter :

```shell
helm upgrade --install gitlab-agent gitlab/gitlab-agent \
  --set extraEnv[0].name=HTTPS_PROXY \
  --set extraEnv[0].value=https://example.com/proxy \
  ...
```

> [!note]
> La protection contre le rebinding DNS est désactivée lorsque la variable d'environnement `HTTP_PROXY` ou `HTTPS_PROXY` est définie et que le DNS du domaine ne peut pas être résolu.

## Installer plusieurs agents dans votre cluster {#install-multiple-agents-in-your-cluster}

> [!note]
> Dans la plupart des cas, vous devriez exécuter un agent par cluster et utiliser les fonctionnalités d'emprunt d'identité de l'agent (Premium et Ultimate uniquement) pour prendre en charge la multi-location. Si vous devez exécuter plusieurs agents, partagez les problèmes que vous rencontrez. Vous pouvez nous faire part de vos retours dans le [ticket 454110](https://gitlab.com/gitlab-org/gitlab/-/issues/454110).

Pour installer un deuxième agent dans votre cluster, vous pouvez suivre les [étapes précédentes](#register-the-agent-with-gitlab) une deuxième fois. Pour éviter les collisions de noms de ressources au sein du cluster, vous devez soit :

- Utiliser un nom de release différent pour l'agent, par exemple `second-gitlab-agent` :

  ```shell
  helm upgrade --install second-gitlab-agent gitlab/gitlab-agent ...
  ```

- Ou installer l'agent dans un espace de nommage différent, par exemple `different-namespace` :

  ```shell
  helm upgrade --install gitlab-agent gitlab/gitlab-agent \
    --namespace different-namespace \
    ...
  ```

Comme chaque agent d'un cluster s'exécute indépendamment, les réconciliations sont déclenchées par chaque agent pour lequel le module Flux est activé. Le [ticket 357516](https://gitlab.com/gitlab-org/gitlab/-/issues/357516) propose de modifier ce comportement.

Pour contourner ce problème, vous pouvez :

- Configurer le RBAC avec l'agent afin qu'il accède uniquement aux ressources Flux dont il a besoin.
- Désactiver le module Flux sur les agents qui ne l'utilisent pas.

## Exemples de projets {#example-projects}

Les exemples de projets suivants peuvent vous aider à démarrer avec l'agent.

- [Exemple de dépôt distinct pour l'application et les manifestes](https://gitlab.com/gitlab-examples/ops/gitops-demo/hello-world-service-gitops)
- [Configuration Auto DevOps utilisant le workflow CI/CD](https://gitlab.com/gitlab-examples/ops/gitops-demo/hello-world-service)
- [Exemple de modèle de projet de gestion de cluster utilisant le workflow CI/CD](https://gitlab.com/gitlab-examples/ops/gitops-demo/cluster-management)

## Mises à jour et compatibilité des versions {#updates-and-version-compatibility}

GitLab vous avertit sur la page de liste des agents de mettre à jour la version de l'agent installée sur votre cluster.

Pour une expérience optimale, la version de l'agent installée dans votre cluster doit correspondre aux versions majeure et mineure de GitLab. Les versions mineures précédente et suivante sont également prises en charge. Par exemple, si votre version de GitLab est v14.9.4 (version majeure 14, version mineure 9), les versions v14.9.0 et v14.9.1 de l'agent sont idéales, mais toute version v14.8.x ou v14.10.x de l'agent est également prise en charge. Consultez [la page des releases](https://gitlab.com/gitlab-org/cluster-integration/gitlab-agent/-/releases) de l'agent GitLab pour Kubernetes.

### Mettre à jour la version de l'agent {#update-the-agent-version}

> [!note]
> Au lieu d'utiliser `--reuse-values`, vous devriez spécifier toutes les valeurs nécessaires. Si vous utilisez `--reuse-values`, vous risquez de manquer de nouveaux paramètres par défaut ou d'utiliser des valeurs dépréciées. Pour récupérer les arguments `--set` précédents, utilisez `helm get values <release name>`. Vous pouvez enregistrer les valeurs dans un fichier avec `helm get values gitlab-agent > agent.yaml`, et passer le fichier à Helm avec `-f` : `helm upgrade gitlab-agent gitlab/gitlab-agent -f agent.yaml`. Cela remplace en toute sécurité le comportement de `--reuse-values`.

Pour mettre à jour l'agent vers la dernière version, vous pouvez exécuter :

```shell
helm repo update
helm upgrade --install gitlab-agent gitlab/gitlab-agent \
  --namespace gitlab-agent
```

Pour définir une version spécifique, vous pouvez remplacer la valeur `image.tag`. Par exemple, pour installer la version `v14.9.1`, exécutez :

```shell
helm upgrade gitlab-agent gitlab/gitlab-agent \
  --namespace gitlab-agent \
  --set image.tag=v14.9.1
```

Le chart Helm est mis à jour indépendamment de l'agent pour Kubernetes, et peut parfois être en retard par rapport à la dernière version de l'agent. Si vous exécutez `helm repo update` sans spécifier de tag d'image, votre agent exécute la version spécifiée dans le chart.

Pour utiliser la dernière release de l'agent pour Kubernetes, définissez le tag d'image pour qu'il corresponde à l'image d'agent la plus récente.

## Désinstaller l'agent {#uninstall-the-agent}

Si vous avez [installé l'agent avec Helm](#install-the-agent-with-helm), vous pouvez également le désinstaller avec Helm. Par exemple, si la release et l'espace de nommage sont tous deux appelés `gitlab-agent`, vous pouvez désinstaller l'agent avec la commande suivante :

```shell
helm uninstall gitlab-agent \
    --namespace gitlab-agent
```

## Dépannage {#troubleshooting}

Lorsque vous installez l'agent pour Kubernetes, vous pourriez rencontrer les problèmes suivants.

### Erreur : `failed to reconcile the GitLab Agent` {#error-failed-to-reconcile-the-gitlab-agent}

Si la commande `glab cluster agent bootstrap` échoue avec le message `failed to reconcile the GitLab Agent`, cela signifie que `glab` n'a pas pu réconcilier l'agent avec Flux.

Cette erreur peut être due aux raisons suivantes :

- La configuration Flux ne pointe pas vers le répertoire où `glab` a placé les manifestes Flux pour l'agent. Si vous avez amorcé Flux avec l'option `--path`, vous devez passer la même valeur à l'option `--manifest-path` de la commande `glab cluster agent bootstrap`.
- Flux pointe vers le répertoire racine d'un projet sans `kustomization.yaml`, ce qui amène Flux à parcourir les sous-répertoires à la recherche de fichiers YAML. Pour utiliser l'agent, vous devez disposer d'un fichier de configuration d'agent à l'emplacement `.gitlab/agents/<agent-name>/config.yaml`, qui n'est pas un manifeste Kubernetes valide. Flux ne parvient pas à appliquer ce fichier, ce qui provoque une erreur. Pour résoudre ce problème, vous devriez pointer Flux vers un sous-répertoire plutôt que vers la racine.
