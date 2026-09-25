---
stage: Agent Foundations
group: Agent Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "Configurez l'environnement CI/CD, les scripts de configuration, la mise en cache, les jetons d'identification et les runners qui exécutent les flows de GitLab Duo Agent Platform."
title: "Configurer l'exécution des flows"
---

{{< details >}}

- Édition : [Gratuite](../../../../subscriptions/gitlab_credits.md#for-the-free-tier), GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Introduction](https://gitlab.com/gitlab-org/gitlab/-/issues/477166) dans GitLab 18.3.

{{< /history >}}

Les flows utilisent des agents pour exécuter des tâches.

- Les flows exécutés depuis l'interface utilisateur GitLab utilisent CI/CD.
- Les flows exécutés dans un IDE s'exécutent localement.

Vous pouvez configurer l'environnement dans lequel les flows utilisent CI/CD pour s'exécuter. Vous pouvez également [utiliser vos propres runners](#configure-runners-to-execute-flows) et [spécifier des variables dans vos jobs](execution-variables.md).

## Architecture de l'exécuteur {#executor-architecture}

{{< history >}}

- [Modification](https://gitlab.com/gitlab-org/gitlab/-/issues/600436) : remplacement par un binaire précompilé au lieu d'un paquet `npm` dans GitLab 19.4.

{{< /history >}}

Lorsqu'un flow s'exécute dans CI/CD, le runner :

1. Télécharge le binaire GitLab Duo CLI correspondant à son système d'exploitation et à son architecture depuis le registre de paquets GitLab. Node.js et `npm` ne sont pas nécessaires.
1. Exécute GitLab Duo CLI, qui utilise WebSocket pour se connecter au service GitLab Duo Workflow.
1. Exécute des outils (opérations sur les fichiers, commandes Git) selon les instructions du modèle d'IA.

La version de l'exécuteur est gérée par GitLab et mise à jour dans le cadre des releases régulières.

## Configurer l'exécution CI/CD {#configure-cicd-execution}

Pour personnaliser la façon dont les flows sont exécutés dans CI/CD, créez un fichier de configuration d'agent dans votre projet.

Pour obtenir la liste des clés prises en charge et de leurs types, voir la [référence `agent-config.yml`](agent-config-yaml.md).

> [!note]
> Vous ne pouvez pas utiliser des variables CI/CD prédéfinies pour configurer le fichier `agent-config.yml`. Vous devez utiliser des [variables](execution-variables.md#available-variables) pour les jobs qui exécutent vos flows.

### Créer le fichier de configuration de l'agent {#create-the-agent-configuration-file}

1. Dans le dépôt de votre projet, créez un dossier `.gitlab/duo/`.
1. Dans le dossier, créez un fichier de configuration nommé `agent-config.yml`.
1. Ajoutez les options de configuration requises.
1. Validez et poussez le fichier vers votre branche par défaut.

La configuration est appliquée lorsque les flows s'exécutent dans CI/CD pour votre projet.

Pour obtenir un exemple de fichier `agent-config.yml` complet, consultez la [référence `agent-config.yml`](agent-config-yaml.md#complete-example).

> [!note]
> Le fichier de configuration est en lecture seule depuis la branche par défaut du projet. Les fichiers validés sur d'autres branches sont ignorés, même lorsqu'un flow s'exécute depuis ces branches.

### Configurer les scripts de configuration {#configure-setup-scripts}

Vous pouvez définir des scripts de configuration qui s'exécutent avant l'exécution de votre flow. Cela est utile pour installer des dépendances, configurer des environnements ou effectuer une initialisation.

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
> Les commandes `setup_script` s'exécutent avant l'application de SRT et s'exécutent en dehors de celui-ci. Ces commandes ont accès à toutes les variables d'environnement du flow, y compris le jeton OAuth de l'utilisateur déclencheur, le jeton de service et les détails d'identité. Pour le modèle de sécurité et les protections recommandées, voir [les implications de sécurité de `agent-config.yml`](security-considerations.md#security-implications-of-agent-configyml).

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

- [Introduction](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/224940) dans GitLab 19.2.

{{< /history >}}

Pour vous authentifier auprès de services tiers depuis un flow, configurez des [jetons d'identification](../../../../ci/secrets/id_token_authentication.md).

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
> Un jeton d'identification est un identifiant qui accorde l'accès à tout service qui approuve sa revendication `aud`. Définissez la valeur `aud` la plus restreinte possible pour chaque jeton, afin qu'un jeton compromis puisse s'authentifier auprès du moins de services possible. Étant donné que le fichier de configuration est lu depuis la branche par défaut, appliquez les [protections recommandées](security-considerations.md#recommended-protections) pour contrôler qui peut modifier les jetons qu'un flow peut demander.

Pour plus d'informations sur le contenu du jeton et la façon de configurer la confiance avec des services tiers, voir [Authentification OpenID Connect (OIDC) à l'aide de jetons d'identification](../../../../ci/secrets/id_token_authentication.md).

## Configurer des runners pour exécuter des flows {#configure-runners-to-execute-flows}

Les flows qui utilisent CI/CD s'exécutent sur des runners.

Sur GitLab.com, les flows peuvent utiliser des [runners hébergés](../../../../ci/runners/hosted_runners/_index.md), fournis par GitLab. Ceux-ci sont activés par défaut.

Vous avez également la possibilité de configurer votre propre runner pour les flows.

> [!note]
> Si votre groupe principal a activé des [restrictions d'adresses IP](../../../group/access_and_permissions.md#restrict-group-access-by-ip-address), les runners hébergés ne peuvent pas être utilisés pour les flows. Les runners hébergés utilisent des adresses IP dynamiques provenant de pools de fournisseurs cloud qui ne peuvent pas être ajoutées à la liste d'autorisation IP de votre groupe. À la place, configurez votre propre runner de groupe au niveau du groupe principal.

Pour configurer votre propre runner pour les flows :

1. Créez un [runner d'instance](../../../../ci/runners/runners_scope.md) ou un runner de groupe assigné au groupe principal. Si vous souhaitez que les flows utilisent des runners de projet ou des runners de groupe assignés à un sous-groupe, désactivez le feature flag `duo_runner_restrictions` (GitLab Self-Managed uniquement).
1. Ajoutez le tag `gitlab--duo` au runner afin qu'il récupère les jobs des flows. Si le runner ne possède pas ce tag, les jobs avec des flows restent en file d'attente indéfiniment. Utilisez l'une des méthodes suivantes :
   - Lorsque vous créez le runner, dans le champ **Étiquettes**, saisissez `gitlab--duo`.
   - Pour un runner existant, [modifiez les jobs que le runner peut exécuter](../../../../ci/runners/configure_runners.md#control-jobs-that-a-runner-can-run) et saisissez `gitlab--duo` dans le champ **Étiquettes**.
   - Si vous configurez des runners avec un fichier `config.toml`, ajoutez le tag à la section `[[runners]]` :

     ```toml
     [[runners]]
       executor = "docker"
       tags = ["gitlab--duo"]
     ```

1. Configurez le runner pour utiliser un [exécuteur](https://docs.gitlab.com/runner/executors/) qui prend en charge les images Docker, comme `docker`, `docker-autoscaler` ou `kubernetes`. L'exécuteur `shell` n'est pas pris en charge.
1. Si votre groupe principal a activé des [restrictions d'adresses IP](../../../group/access_and_permissions.md#restrict-group-access-by-ip-address), ajoutez l'adresse IP du runner à la liste d'autorisation IP de votre groupe afin que le runner puisse accéder au groupe.
1. GitLab Self-Managed uniquement. Assurez-vous que le runner peut atteindre les services requis par les flows :
   - [Autorisez les connexions sortantes depuis l'instance GitLab](../../../../administration/gitlab_duo/configure/_index.md#allow-outbound-connections-from-the-gitlab-instance-to-gitlab-duo) vers Agent Platform.
   - [Autorisez les connexions sortantes depuis le runner](../../../../administration/gitlab_duo/configure/_index.md#allow-connections-from-the-runner) vers Agent Platform.
   - Pour les instances avec des certificats auto-signés dans la chaîne de certificats, effectuez la [configuration supplémentaire de GitLab Duo CLI](../../../gitlab_duo_cli/use.md#certificate-errors).

### Utiliser le sandbox d'environnement d'exécution pour sécuriser les flows {#use-the-execution-environment-sandbox-to-secure-flows}

Pour l'isolation réseau et du système de fichiers, utilisez le [sandbox d'environnement d'exécution](../../environment_sandbox.md) pour sécuriser les flows exécutés sur des runners.

Pour utiliser le sandbox, vous devez utiliser l'une des images suivantes :

- Image de base Docker par défaut pour Agent Platform
- [Image renforcée UBI 9 Minimal](images.md#use-a-red-hat-universal-base-image-9-minimal)
- Une [image personnalisée avec SRT installé](../../environment_sandbox.md#install-anthropic-sandbox-runtime-srt-on-a-custom-image)

Pour configurer les runners afin d'utiliser le sandbox, définissez `privileged = true` dans votre [configuration du runner](https://docs.gitlab.com/runner/configuration/advanced-configuration/).

Par exemple :

```toml
[[runners]]
  executor = "docker"
  tags = ["gitlab--duo"]
  [runners.docker]
    privileged = true
```

Vous ne pouvez pas utiliser le bac à sable avec des images personnalisées sur lesquelles SRT n'est pas installé.

### Exigences du bac à sable sans mode privilégié {#sandbox-requirements-without-privileged-mode}

Le mode privilégié est l'un des moyens de satisfaire aux exigences du bac à sable, mais il n'est pas suffisant à lui seul et n'est pas toujours nécessaire.

Le bac à sable exige que le job puisse créer des espaces de nommage utilisateur et de montage. Au moment de l'exécution, le bac à sable teste d'abord `unshare -m`, puis se replie sur `unshare -rm` :

- `unshare -m` nécessite `CAP_SYS_ADMIN`, que possède un conteneur s'exécutant en tant que root lorsque le runner est configuré avec `privileged = true`.
- `unshare -rm` crée un espace de nommage utilisateur non privilégié et fonctionne pour les images s'exécutant en tant qu'utilisateur non root, comme l'image UBI 9 Minimal renforcée. `unshare -rm` mappe l'utilisateur du conteneur vers root uniquement dans le nouvel espace de nommage. Il n'accorde aucun privilège sur l'hôte du runner.

Un paramètre `privileged = true` ne garantit pas l'initialisation du bac à sable. L'initialisation échoue toujours dans les cas suivants :

- L'hôte du runner a `user.max_user_namespaces` défini sur `0`.
- Un profil seccomp ou AppArmor bloque l'indicateur `CLONE_NEWUSER`.
- Le mode privilégié est défini sur le runner, mais n'atteint pas le conteneur du job. Cela peut se produire avec certaines configurations d'exécuteur `docker-autoscaler` et `kubernetes`.

Si aucun mode d'espace de nommage n'est disponible, le flow s'exécute sans le bac à sable et le job log contient l'avertissement suivant :

```plaintext
Warning: SRT found but can't create sandbox (insufficient privileges), running command directly
```
