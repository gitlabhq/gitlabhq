---
stage: Agent Foundations
group: Agent Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: "Configurer l'exécution des flows"
---

{{< history >}}

- [Introduction](https://gitlab.com/gitlab-org/gitlab/-/issues/477166) dans GitLab 18.3.

{{< /history >}}

Les flows utilisent des agents pour exécuter des tâches.

- Les flows exécutés depuis l'interface utilisateur GitLab utilisent CI/CD.
- Les flows exécutés dans un IDE s'exécutent localement.

Vous pouvez configurer l'environnement dans lequel les flows utilisent CI/CD pour s'exécuter. Vous pouvez également choisir de [utiliser vos propres runners](#configure-runners-to-execute-flows), et de [spécifier des variables dans vos jobs](execution_variables.md).

## Sécurité des flows {#flow-security}

Lorsque les flows s'exécutent dans GitLab CI/CD :

- Ils utilisent une [identité composite](../composite_identity.md) pour limiter les accès.
- Ils créent un [pipeline de charge de travail](../../../ci/pipelines/pipeline_types.md#workload-pipeline) éphémère, qui est supprimé une fois le flow terminé.
- Les outils à leur disposition sont spécifiques à l'objectif du flow. Ces outils peuvent inclure la création de merge requests ou l'exécution de commandes shell locales dans leur environnement d'exécution.

Par défaut, les flows ont accès au réseau uniquement vers l'instance GitLab. Pour plus d'informations sur les règles d'accès réseau, voir [comment configurer une politique réseau](../environment_sandbox.md#configure-a-network-policy). Cet environnement séparé protège contre les conséquences involontaires de l'exécution de commandes shell.

Pour empêcher les flows de s'exécuter de manière autonome dans l'interface utilisateur GitLab, vous pouvez [désactiver l'exécution des flows](foundational_flows/_index.md#turn-foundational-flows-on-or-off).

### Implications de sécurité de `agent-config.yml` {#security-implications-of-agent-configyml}

Le fichier `.gitlab/duo/agent-config.yml` contrôle la façon dont les flows s'exécutent dans CI/CD, y compris les commandes qui s'exécutent dans `setup_script`. En raison du fonctionnement des flows, les modifications apportées à ce fichier affectent plus que l'utilisateur qui les valide.

#### Exécution entre utilisateurs {#cross-user-execution}

Les flows s'exécutent sous l'identité de l'utilisateur qui les déclenche via l'[identité composite](../composite_identity.md). Les commandes dans `setup_script` s'exécutent avec les identifiants d'identité composite de l'utilisateur déclencheur, et non avec les identifiants de l'utilisateur qui a validé la configuration.

Un utilisateur disposant d'un accès en écriture sur `.gitlab/duo/agent-config.yml` peut influencer ce qui s'exécute dans l'environnement runner d'un autre utilisateur. Les modifications apportées à ce fichier affectent le contexte d'exécution de chaque utilisateur qui déclenche ultérieurement un flow dans le projet.

#### Variables d'environnement exposées {#exposed-environment-variables}

Lors de l'exécution de `setup_script`, qui s'exécute en dehors d'Anthropic Sandbox Runtime (SRT), les variables sensibles suivantes sont présentes dans l'environnement :

- `GITLAB_OAUTH_TOKEN` et `GITLAB_TOKEN` : le jeton OAuth de l'utilisateur déclencheur via l'identité composite.
- `DUO_WORKFLOW_GIT_HTTP_PASSWORD` : le mot de passe HTTP Git.
- `DUO_WORKFLOW_SERVICE_TOKEN` : le jeton de service.
- `DUO_WORKFLOW_GIT_USER_EMAIL` et `DUO_WORKFLOW_GIT_USER_NAME` : l'adresse e-mail et le nom de l'utilisateur déclencheur.

Pour la liste complète des variables exposées, voir [les variables d'exécution des flows](execution_variables.md).

#### Protections recommandées {#recommended-protections}

Pour réduire le risque de modifications non autorisées du fichier `.gitlab/duo/agent-config.yml` :

- [Protégez votre branche par défaut](../../../user/project/repository/branches/protected.md) pour empêcher les pushs directs.
- Utilisez les [propriétaires du code](../../../user/project/codeowners/_index.md) pour exiger l'approbation de propriétaires spécifiques avant que les modifications apportées à `.gitlab/duo/agent-config.yml` soient fusionnées. Par exemple, ajoutez ce qui suit à votre fichier `CODEOWNERS` :

  ```plaintext
  .gitlab/duo/agent-config.yml @your-group/security-reviewers
  ```

- Configurez des [règles d'approbation](../../../user/project/merge_requests/approvals/rules.md) qui exigent une revue de la part de responsables de confiance pour les merge requests qui modifient ce fichier.

## Architecture de l'exécuteur {#executor-architecture}

Lorsqu'un flow s'exécute dans CI/CD, le runner :

1. Télécharge le paquet `@gitlab/duo-cli` depuis le registre npm.
1. Exécute le GitLab Duo CLI, qui utilise WebSocket pour se connecter au service GitLab Duo Workflow.
1. Exécute des outils (opérations sur les fichiers, commandes Git) selon les instructions du modèle d'IA.

La version de l'exécuteur est gérée par GitLab et mise à jour dans le cadre des releases régulières.

## Configurer l'exécution CI/CD {#configure-cicd-execution}

Pour personnaliser la façon dont les flows sont exécutés dans CI/CD, créez un fichier de configuration d'agent dans votre projet.

Pour obtenir la liste des clés prises en charge et de leurs types, voir la [référence `agent-config.yml`](agent_config_yml.md).

> [!note]
> Vous ne pouvez pas utiliser de variables CI/CD prédéfinies dans ce scénario. Voir [la liste des variables disponibles](execution_variables.md#available-variables).

## Créer le fichier de configuration {#create-the-configuration-file}

1. Dans le dépôt de votre projet, créez un dossier `.gitlab/duo/` s'il n'existe pas.
1. Dans le dossier, créez un fichier de configuration nommé `agent-config.yml`.
1. Ajoutez vos options de configuration requises (voir les sections ci-dessous).
1. Validez et poussez le fichier vers votre branche par défaut.

La configuration est appliquée lorsque les flows s'exécutent dans CI/CD pour votre projet.

> [!note]
> Le fichier de configuration est lu uniquement depuis la branche par défaut du projet. Les fichiers validés sur d'autres branches sont ignorés, même lorsqu'un flow s'exécute depuis ces branches.

### Changer l'image Docker par défaut {#change-the-default-docker-image}

Par défaut, tous les flows exécutés avec CI/CD utilisent une image Docker standard fournie par GitLab. Cette image Docker utilise [Anthropic Sandbox Runtime (`srt`)](https://github.com/anthropic-experimental/sandbox-runtime) pour inclure automatiquement la protection réseau.

Vous pouvez changer l'image Docker et spécifier la vôtre à la place. Votre propre image peut être utile pour les projets complexes nécessitant des dépendances ou des outils spécifiques. Pour utiliser la protection réseau dans votre image, ajoutez `srt` à votre image Docker avec votre version préférée :

```Docker
# Install srt sandboxing with cache clearing and verification
ARG SANDBOX_RUNTIME_VERSION=0.0.20
RUN npm cache clean --force && \
    npm install -g @anthropic-ai/sandbox-runtime@${SANDBOX_RUNTIME_VERSION} && \
    test -s "$(npm root -g)/@anthropic-ai/sandbox-runtime/package.json" && \
    srt --version
```

Pour plus d'informations sur SRT et comment l'installer sur une image personnalisée, voir [le sandbox de l'environnement d'exécution à distance](../environment_sandbox.md).

Pour changer l'image Docker par défaut, dans le fichier `agent-config.yml`, ajoutez la configuration suivante :

```yaml
image: YOUR_DOCKER_IMAGE
```

Par exemple :

```yaml
image: python:3.11-slim
```

Ou pour un projet Node.js :

```yaml
image: node:20-alpine
```

#### Image renforcée UBI 9 Minimal {#hardened-ubi-9-minimal-image}

{{< history >}}

- [Introduction](https://gitlab.com/gitlab-org/duo-workflow/default-docker-image/-/merge_requests/12) dans GitLab 19.0.

{{< /history >}}

GitLab fournit également une variante d'image renforcée et minimale basée sur Red Hat Universal Base Image (UBI) 9 Minimal. Cette image est conçue pour les environnements à accès réseau restreint, de style FedRAMP, ou autrement sensibles sur le plan de la sécurité, où une surface d'attaque réduite, une exécution non root et une base Red Hat UBI sont requises.

L'image renforcée est publiée à l'adresse : `registry.gitlab.com/gitlab-org/duo-workflow/default-docker-image/workflow-generic-image-hardened`

Elle est construite pour `linux/amd64` et `linux/arm64`, et utilise le même schéma de tags que l'image par défaut :

- `:<short-sha>` par build
- `:<git-tag>` par release

##### Utiliser l'image renforcée {#use-the-hardened-image}

Prérequis :

- GitLab 18.10 ou version ultérieure

Pour utiliser l'image renforcée, définissez-la dans votre `agent-config.yml` :

```yaml
image: registry.gitlab.com/gitlab-org/duo-workflow/default-docker-image/workflow-generic-image-hardened:<tag>
```

##### Contenu de l'image {#image-contents}

| Composant           | Version                           |
|---------------------|-----------------------------------|
| Image de base          | Red Hat UBI 9 Minimal             |
| `git`               | UBI 9 stock                       |
| `git-lfs`           | UBI 9 stock                       |
| Node.js             | 20 (flux de module UBI 9)          |
| `npm`               | Inclus avec Node.js 20           |
| `@gitlab/duo-cli`   | Préinstallé                     |
| `glab` (GitLab CLI) | Préinstallé                     |
| Utilisateur d'exécution        | Non root, UID 1001 (`duo-runner`) |

L'image inclut `@gitlab/duo-cli` et `glab`, de sorte que l'accès sortant vers `registry.npmjs.org` ou `registry.gitlab.com` n'est pas nécessaire au moment de l'exécution des flows.

##### Étendre l'image avec des paquets supplémentaires {#extend-the-image-with-additional-packages}

L'image renforcée s'exécute en tant qu'UID 1001 (`duo-runner`). Le `setup_script` dans votre `agent-config.yml` s'exécute également en tant que cet utilisateur non root et ne peut donc pas installer de paquets système avec `microdnf`.

Pour ajouter des runtimes de langage ou des paquets système :

1. Étendez l'image avec votre propre couche `FROM` :

   ```dockerfile
   FROM registry.gitlab.com/gitlab-org/duo-workflow/default-docker-image/workflow-generic-image-hardened:<tag>

   USER root
   RUN microdnf install -y python3.12 python3.12-pip && microdnf clean all
   USER 1001
   ```

1. Utilisez `setup_script` pour les dépendances de projet qui ne nécessitent pas d'accès root. Par exemple, `pip install --user` ou `npm install`.

##### Quand utiliser l'image renforcée {#when-to-use-the-hardened-image}

Utilisez l'image renforcée lorsque votre environnement requiert :

- Une image de base Red Hat UBI. Par exemple, pour la conformité FedRAMP ou d'entreprise.
- L'exécution de conteneurs non root par défaut.
- Une surface d'attaque minimale sans runtimes de langage au-delà de ce dont la plateforme Agent a elle-même besoin.
- Aucun accès Internet sortant au moment de l'exécution des flows (toutes les dépendances de la plateforme Agent sont préinstallées).

Utilisez l'[image par défaut](#change-the-default-docker-image) pour les flows à usage général dans des environnements connectés qui nécessitent plusieurs runtimes de langage prêts à l'emploi.

#### Exigences relatives aux images personnalisées {#custom-image-requirements}

Si vous utilisez une image Docker personnalisée, assurez-vous que les commandes suivantes sont disponibles pour que l'agent fonctionne correctement :

- `git`
- `npm` avec une version Node.js compatible avec `@gitlab/duo-cli`. Pour plus d'informations, voir [les prérequis du GitLab Duo CLI](../../gitlab_duo_cli/_index.md#install).

La plupart des images de base incluent ces commandes par défaut. Cependant, les images minimales (comme les variantes `alpine`) peuvent nécessiter que vous les installiez explicitement. Si nécessaire, vous pouvez installer les commandes manquantes dans la [configuration du script de configuration](#configure-setup-scripts).

> [!note]
> Dans GitLab 18.9 et versions antérieures, il existe [un problème connu (587996)](https://gitlab.com/gitlab-org/gitlab/-/work_items/587996) où les flows peuvent échouer avec les versions plus récentes de `git` dans les images personnalisées. Ce problème est résolu dans la version 8.71.0 de `@gitlab/duo-cli`.
>
> Si vous utilisez `@gitlab/duo-cli` version 8.71.0 ou antérieure, pour éviter que les flows échouent avec les versions Git plus récentes, vous pouvez effectuer l'une des actions suivantes :
>
> - Utiliser la version Git `2.43.7` ou antérieure dans votre image personnalisée
> - Utiliser `@gitlab/duo-cli` version 8.71.0.

De plus, selon les appels d'outils effectués par les agents lors de l'exécution des flows, d'autres utilitaires courants peuvent être nécessaires.

Par exemple, si vous utilisez une image basée sur Alpine :

```yaml
image: python:3.11-alpine
setup_script:
  - apk add --update git nodejs npm
```

#### Sécurité et performances {#security-and-performance}

Lorsque vous utilisez une image Docker personnalisée, le [sandbox d'environnement](../environment_sandbox.md) n'est appliqué que si Anthropic Sandbox Runtime (SRT) est inclus dans votre image personnalisée. Si SRT n'est pas inclus, votre flow peut accéder à tout domaine accessible depuis le runner et à l'ensemble du système de fichiers.

Si vous avez besoin d'une isolation réseau avec des images personnalisées, [installez SRT sur votre image](../environment_sandbox.md#install-anthropic-sandbox-runtime-srt-on-a-custom-image) et [configurez une politique réseau](../environment_sandbox.md#configure-a-network-policy), ou configurez des contrôles au niveau du réseau sur votre runner (par exemple, des règles de pare-feu ou des politiques réseau).

Pour réduire le temps de démarrage des jobs d'environ 15 à 20 secondes, incluez le paquet npm `@gitlab/duo-cli` et le CLI `glab` dans votre image personnalisée. L'image renforcée préinstalle les deux outils.

### Configurer les scripts de configuration {#configure-setup-scripts}

Vous pouvez définir des scripts de configuration qui s'exécutent avant l'exécution de votre flow. Cela est utile pour installer des dépendances, configurer des environnements ou effectuer toute initialisation nécessaire.

Pour ajouter des scripts de configuration, dans le fichier `agent-config.yml`, ajoutez les commandes suivantes :

```yaml
setup_script:
  - apt-get update && apt-get install -y curl
  - pip install -r requirements.txt
  - echo "Setup complete"
```

Ces commandes effectuent les actions suivantes :

- S'exécutent avant les commandes principales du workflow.
- S'exécutent dans l'ordre spécifié.
- Peuvent être une seule commande ou un tableau de commandes.

Le contexte utilisateur pour `setup_script` dépend de l'image Docker. L'image GitLab par défaut s'exécute en tant que `root`. Les images personnalisées s'exécutent en tant qu'utilisateur défini dans la directive `USER` de l'image. Si votre `setup_script` nécessite un accès root (par exemple, pour installer des paquets système), assurez-vous que votre image personnalisée est configurée en conséquence.

> [!warning]
> Les commandes `setup_script` s'exécutent avant l'application de SRT et s'exécutent en dehors de celui-ci. Ces commandes ont accès à toutes les variables d'environnement du flow, y compris le jeton OAuth de l'utilisateur déclencheur, le jeton de service et les détails d'identité. Pour le modèle de sécurité et les protections recommandées, voir [les implications de sécurité de `agent-config.yml`](#security-implications-of-agent-configyml).

### Utiliser une image personnalisée dans un environnement hors ligne {#use-a-custom-image-in-an-offline-environment}

Dans les environnements hors ligne où les runners ne peuvent pas atteindre les registres externes, vous pouvez prédéfinir une image d'exécuteur personnalisée qui inclut `@gitlab/duo-cli`. Lorsque le GitLab Duo CLI est déjà présent dans l'image, le démarrage du flow ignore l'étape de téléchargement npm.

Prérequis :

- Disposer d'un accès administrateur.
- GitLab 18.9 ou version ultérieure.
- Accès à une machine en ligne pour construire l'image et télécharger les artefacts.

Pour configurer les flows pour un environnement hors ligne :

1. Sur une machine en ligne, construisez une image personnalisée avec le GitLab Duo CLI :

   ```dockerfile
   FROM registry.gitlab.com/gitlab-org/duo-workflow/default-docker-image/workflow-generic-image:v0.0.6
   RUN npm install -g @gitlab/duo-cli@8.86.0
   ```

   Alternativement, pour éviter complètement npm, téléchargez le binaire autonome depuis le [registre de paquets GitLab](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/packages) :

   ```dockerfile
   FROM registry.gitlab.com/gitlab-org/duo-workflow/default-docker-image/workflow-generic-image:v0.0.6
   COPY duo-linux-x64 /usr/bin/duo
   RUN chmod +x /usr/bin/duo
   ```

   Pour télécharger le binaire autonome, exécutez la commande suivante :

   ```shell
   curl --location "https://gitlab.com/api/v4/projects/46519181/packages/generic/duo-cli/8.86.0/duo-linux-x64" \
     --output duo-linux-x64
   ```

1. Transférez l'image vers votre environnement hors ligne. Par exemple, avec Docker, exécutez les commandes suivantes :

   ```shell
   # On an online machine
   docker save my-duo-executor:latest -o duo-executor.tar

   # Transfer `duo-executor.tar` to the offline environment

   # On an offline machine
   docker load -i duo-executor.tar
   ```

1. Poussez l'image vers votre registre de conteneurs interne.
1. Définissez le registre d'images personnalisé :
   1. Dans le coin supérieur droit, sélectionnez **Admin**.
   1. Dans la barre latérale gauche, sélectionnez **GitLab Duo**.
   1. Sélectionnez **Modifier la configuration**.
   1. Dans le champ de texte **Registre d'images**, saisissez l'URL de votre registre interne (par exemple, `registry.internal.example.com`).
1. Dans la barre supérieure, sélectionnez **Rechercher ou accédez à** et repérez votre projet.
1. Pour utiliser l'image personnalisée, mettez à jour le fichier `agent-config.yml` :

   ```yaml
   image: registry.internal.example.com/duo-executor:latest
   ```

### Configurer la mise en cache {#configure-caching}

Pour configurer la mise en cache afin d'accélérer les exécutions de flows ultérieures, configurez le fichier `agent-config.yml` pour conserver les fichiers et répertoires entre les exécutions. La mise en cache peut être utile pour les dossiers de dépendances tels que `node_modules` ou les environnements virtuels Python.

#### Configuration de cache de base {#basic-cache-configuration}

Pour mettre en cache des chemins spécifiques, ajoutez ce qui suit à votre fichier `agent-config.yml` :

```yaml
cache:
  paths:
    - node_modules/
    - .npm/
```

#### Cache avec clés {#cache-with-keys}

Vous pouvez utiliser des clés de cache pour créer différents caches selon les scénarios. Les clés de cache permettent de s'assurer que le cache est basé sur l'état de votre projet.

##### Utiliser une clé de type chaîne {#use-a-string-key}

```yaml
cache:
  key: my-project-cache
  paths:
    - vendor/
    - .bundle/
```

##### Utiliser des clés de cache basées sur des fichiers {#use-file-based-cache-keys}

Créez des clés de cache dynamiques basées sur le contenu des fichiers (comme les fichiers de verrouillage). Lorsque ces fichiers changent, un nouveau cache est créé. Cela génère une somme de contrôle SHA des fichiers spécifiés :

```yaml
cache:
  key:
    files:
      - package-lock.json
      - yarn.lock
  paths:
    - node_modules/
```

##### Utiliser un préfixe avec des clés basées sur des fichiers {#use-a-prefix-with-file-based-keys}

Combinez un préfixe avec le SHA calculé pour les fichiers de clé de cache :

```yaml
cache:
  key:
    files:
      - package-lock.json
    prefix: $CI_JOB_NAME
  paths:
    - node_modules/
    - .npm/
```

Dans cet exemple, si le nom du job est `test` et que la somme de contrôle SHA est `abc123`, la clé de cache devient `test-abc123`.

#### Limitations du cache {#cache-limitations}

- Vous pouvez spécifier jusqu'à deux fichiers pour la génération de clé de cache. Si plus de fichiers sont spécifiés, seuls les deux premiers sont utilisés.
- Le champ `paths` du cache est obligatoire. Une configuration de cache sans chemins n'a aucun effet.
- Les clés de cache prennent en charge les variables CI/CD dans le champ `prefix`.

### Configurer les jetons d'identification {#configure-id-tokens}

{{< history >}}

- [Introduction](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/224940) dans GitLab 19.2.

{{< /history >}}

Pour vous authentifier auprès de services tiers depuis un flow, configurez des [jetons d'identification](../../../ci/secrets/id_token_authentication.md).

Les jetons d'identification sont des jetons web JSON (JWT) que GitLab CI/CD génère et injecte dans le job qui exécute le flow pour une authentification OpenID Connect (OIDC) sans clé, sans stocker d'identifiants à longue durée de vie. Par exemple, vous pouvez utiliser des jetons d'identification pour récupérer des secrets depuis un gestionnaire de secrets ou signer des binaires et des commits Git.

Pour configurer les jetons d'identification, dans le fichier `agent-config.yml`, ajoutez un bloc `id_tokens`. Chaque jeton nécessite une revendication `aud` (audience) :

```yaml
id_tokens:
  VAULT_ID_TOKEN:
    aud: https://vault.example.com

network_policy:
  allowed_domains:
    - vault.example.com
```

La revendication `aud` peut être une chaîne unique ou une liste de chaînes :

```yaml
id_tokens:
  MY_ID_TOKEN:
    aud:
      - https://first.service.example.com
      - https://second.service.example.com

network_policy:
  allowed_domains:
    - first.service.example.com
    - second.service.example.com
```

Chaque jeton est disponible dans le job du flow en tant que variable d'environnement portant le nom du jeton. Pour les exemples précédents, le flow peut utiliser `$VAULT_ID_TOKEN` et `$MY_ID_TOKEN`.

Si un nom de jeton correspond à un nom de variable déclaré ailleurs dans votre configuration, le jeton d'identification a la priorité.

> [!warning]
> Un jeton d'identification est un identifiant qui accorde l'accès à tout service qui approuve sa revendication `aud`. Définissez la valeur `aud` la plus restreinte possible pour chaque jeton, afin qu'un jeton compromis puisse s'authentifier auprès du moins de services possible. Étant donné que le fichier de configuration est lu depuis la branche par défaut, appliquez les [protections recommandées](#recommended-protections) pour contrôler qui peut modifier les jetons qu'un flow peut demander.

Pour plus d'informations sur le contenu du jeton et la façon de configurer la confiance avec des services tiers, voir [Authentification OpenID Connect (OIDC) à l'aide de jetons d'identification](../../../ci/secrets/id_token_authentication.md).

### Exemple de configuration complète {#complete-configuration-example}

Voici un exemple de fichier `agent-config.yml` utilisant toutes les options disponibles :

```yaml
# Custom Docker image
image: python:3.11

# Setup script to run before the flow
setup_script:
  - apt-get update && apt-get install -y build-essential
  - pip install --upgrade pip
  - pip install -r requirements.txt

# Cache configuration
cache:
  key:
    files:
      - requirements.txt
      - Pipfile.lock
    prefix: python-deps
  paths:
    - .cache/pip
    - venv/

# Network configuration
network_policy:
  include_recommended_allowed: true
  allow_all_unix_sockets: true
  allowed_domains:
    - vault.example.com
  denied_domains:
    - malicious.com

# ID tokens for OIDC authentication
id_tokens:
  VAULT_ID_TOKEN:
    aud: https://vault.example.com
```

Cette configuration :

- Utilise Python 3.11 comme image de base.
- Installe les outils de compilation et les dépendances Python avant d'exécuter le flow.
- Met en cache les répertoires pip et d'environnement virtuel.
- Crée un nouveau cache lorsque `requirements.txt` ou `Pipfile.lock` change, avec un préfixe `python-deps`.
- Fournit un jeton d'identification `VAULT_ID_TOKEN` pour l'authentification OIDC avec HashiCorp Vault.

## Configurer des runners pour exécuter des flows {#configure-runners-to-execute-flows}

Les flows qui utilisent CI/CD s'exécutent sur des runners.

Sur GitLab.com, les flows peuvent utiliser des [runners hébergés](../../../ci/runners/hosted_runners/_index.md), fournis par GitLab. Ceux-ci sont activés par défaut. 

Vous avez également la possibilité de configurer votre propre runner pour les flows.

> [!note]
> Si votre groupe principal a activé des [restrictions d'adresses IP](../../group/access_and_permissions.md#restrict-group-access-by-ip-address), les runners hébergés ne peuvent pas être utilisés pour les flows. Les runners hébergés utilisent des adresses IP dynamiques provenant de pools de fournisseurs cloud qui ne peuvent pas être ajoutées à la liste d'autorisation IP de votre groupe. À la place, configurez votre propre runner de groupe au niveau du groupe principal.

Pour configurer votre propre runner pour les flows :

1. Créez un [runner d'instance](../../../ci/runners/runners_scope.md) ou un runner de groupe assigné au groupe principal. Si vous souhaitez que les flows utilisent des runners de projet ou des runners de groupe assignés à un sous-groupe, désactivez le feature flag `duo_runner_restrictions` (GitLab Self-Managed uniquement).
1. Ajoutez le tag `gitlab--duo` au runner afin qu'il récupère les jobs des flows. Si le runner ne possède pas ce tag, les jobs avec des flows restent en file d'attente indéfiniment. Utilisez l'une des méthodes suivantes :
   - Lorsque vous créez le runner, dans le champ **Étiquettes**, saisissez `gitlab--duo`.
   - Pour un runner existant, [modifiez les jobs que le runner peut exécuter](../../../ci/runners/configure_runners.md#control-jobs-that-a-runner-can-run) et saisissez `gitlab--duo` dans le champ **Étiquettes**.
   - Si vous configurez des runners avec un fichier `config.toml`, ajoutez le tag à la section `[[runners]]` :

     <!-- markdownlint-disable MD044 -->
     ```toml
     [[runners]]
       executor = "docker"
       tags = ["gitlab--duo"]
     ```
     <!-- markdownlint-enable MD044 -->

1. Configurez le runner pour utiliser un [exécuteur](https://docs.gitlab.com/runner/executors/) qui prend en charge les images Docker, comme `docker`, `docker-autoscaler` ou `kubernetes`. L'exécuteur `shell` n'est pas pris en charge.
1. Si votre groupe principal a activé des [restrictions d'adresses IP](../../group/access_and_permissions.md#restrict-group-access-by-ip-address), ajoutez l'adresse IP du runner à la liste d'autorisation IP de votre groupe afin que le runner puisse accéder au groupe.
1. GitLab Self-Managed uniquement. Assurez-vous que le runner peut atteindre les services requis par les flows :
   - [Autorisez les connexions sortantes depuis l'instance GitLab](../../../administration/gitlab_duo/configure/_index.md#allow-outbound-connections-from-the-gitlab-instance-to-gitlab-duo) vers la plateforme Agent.
   - [Autorisez les connexions sortantes depuis le runner](../../../administration/gitlab_duo/configure/_index.md#allow-connections-from-the-runner) vers la plateforme Agent.
   - Pour les instances avec des certificats auto-signés dans la chaîne de certificats, effectuez la [configuration supplémentaire du GitLab Duo CLI](../../gitlab_duo_cli/_index.md#custom-ssl-certificates).

### Utiliser le sandbox d'environnement d'exécution pour sécuriser les flows {#use-the-execution-environment-sandbox-to-secure-flows}

Pour l'isolation réseau et du système de fichiers, utilisez le [sandbox d'environnement d'exécution](../environment_sandbox.md) pour sécuriser les flows exécutés sur des runners.

Pour utiliser le sandbox, vous devez utiliser l'une des images suivantes :

- Image de base Docker par défaut pour la plateforme Agent
- Une [image personnalisée avec SRT installé](../environment_sandbox.md#install-anthropic-sandbox-runtime-srt-on-a-custom-image)

Pour configurer les runners afin d'utiliser le sandbox, définissez `privileged = true` dans votre [configuration du runner](https://docs.gitlab.com/runner/configuration/advanced-configuration/).

Par exemple :

<!-- markdownlint-disable MD044 -->
```toml
[[runners]]
  executor = "docker"
  tags = ["gitlab--duo"]
  [runners.docker]
    privileged = true
```
<!-- markdownlint-enable MD044 -->

Vous ne pouvez pas utiliser le sandbox avec les images suivantes :

- Images personnalisées sans SRT installé
- Image renforcée UBI 9 Minimal
