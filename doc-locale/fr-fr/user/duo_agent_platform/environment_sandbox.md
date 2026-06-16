---
stage: AI-powered
group: Agent Foundations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: "Sandbox de l'environnement d'exécution distant"
---

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/578048) dans GitLab 18.7 [avec des feature flags](../../administration/feature_flags/_index.md) nommés `ai_duo_agent_platform_network_firewall` et `ai_dap_executor_connects_over_ws`
- Le feature flag `ai_duo_agent_platform_network_firewall` a été [activé](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/215950) dans GitLab 18.7.
- Le feature flag `ai_dap_executor_connects_over_ws` a été [activé](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/215774) dans GitLab 18.7.
- [Disponible en version générale](https://gitlab.com/gitlab-org/gitlab/-/work_items/585273) dans GitLab 18.8.
- Le paramètre `network_policy` a été [introduit](https://gitlab.com/gitlab-org/gitlab/-/work_items/590021) dans GitLab 18.10.
- Le paramètre de politique réseau `allow_all_unix_sockets` a été [introduit](https://gitlab.com/gitlab-org/gitlab/-/work_items/590871) dans GitLab 18.11.
- Les contrôles d'accès réseau au niveau de l'instance et au niveau du groupe ont été [introduits](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/229531) dans GitLab 18.11 [avec des feature flags](../../administration/feature_flags/_index.md) nommés `dap_instance_network_access_controls` et `dap_group_network_access_controls`. Désactivé par défaut.
- Les feature flags `dap_instance_network_access_controls` et `dap_group_network_access_controls` ont été [activés](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/235670) dans GitLab 19.0.

{{< /history >}}

Le sandbox de l'environnement d'exécution fournit une isolation réseau et système de fichiers au niveau applicatif qui contribue à protéger les flows distants de GitLab Duo Agent Platform contre les accès réseau non autorisés et l'exfiltration de données. Il est conçu pour aider à prévenir les tentatives d'exfiltration de données, le chargement de code malveillant depuis des sources externes et la collecte de données non autorisée, tout en maintenant la connectivité nécessaire aux opérations légitimes des flows.

## Quand le sandbox est appliqué {#when-the-sandbox-is-applied}

Le sandbox de l'environnement d'exécution est automatiquement appliqué lors de l'utilisation d'une image Docker compatible avec Anthropic Sandbox Runtime (SRT) installé. Cela inclut l'utilisation de l'image Docker GitLab par défaut (release [v0.0.6](https://gitlab.com/gitlab-org/duo-workflow/default-docker-image/-/tags/v0.0.6) et versions ultérieures) ou d'une [image personnalisée avec SRT installé](#install-anthropic-sandbox-runtime-srt-on-a-custom-image).

Le sandbox est activé lorsque :

- Anthropic Sandbox Runtime (SRT) est disponible dans l'image Docker.
- Les sessions GitLab Duo Agent Platform sont exécutées sur un runner (les environnements locaux ne sont pas soumis au sandbox).

Pour obtenir des informations sur les différences de variables CI/CD entre les configurations d'images par défaut et personnalisées, consultez [Variables d'exécution des flows](flows/execution_variables.md).

## Prérequis {#prerequisites}

Pour utiliser le sandbox de l'environnement d'exécution, vous avez besoin de :

- GitLab Duo Agent Platform activé dans votre projet.
- Mode runner privilégié activé. Il est [requis pour le bon fonctionnement du sandbox](flows/execution.md#configure-runners).
- Une image Docker compatible : il peut s'agir de l'image [Docker GitLab par défaut](https://gitlab.com/gitlab-org/duo-workflow/default-docker-image/container_registry) à la version `v0.0.6` ou supérieure, ou d'une [image personnalisée avec Anthropic Sandbox Runtime (SRT) installé](#install-anthropic-sandbox-runtime-srt-on-a-custom-image).

## Fonctionnement {#how-it-works}

Le sandbox de l'environnement d'exécution utilise [Anthropic Sandbox Runtime (SRT)](https://github.com/anthropic-experimental/sandbox-runtime) pour encapsuler l'exécution des flows avec les protections suivantes :

- Isolation réseau :  Intercepte toutes les requêtes réseau avant qu'elles ne quittent l'environnement d'exécution et les valide par rapport aux domaines figurant sur la liste d'autorisation.
- Restrictions du système de fichiers :  Limite l'accès en lecture et en écriture à des répertoires spécifiques et bloque l'accès aux fichiers sensibles.
- Reprise gracieuse :  Si SRT est indisponible ou si les privilèges requis par le système d'exploitation sont manquants, le flow s'exécute directement avec un message d'avertissement.

## Installer Anthropic Sandbox Runtime (SRT) sur une image personnalisée {#install-anthropic-sandbox-runtime-srt-on-a-custom-image}

Si vous utilisez une image personnalisée, par exemple avec un [`agent-config.yml`](flows/execution.md#create-the-configuration-file), Anthropic SRT version `0.0.20` ou ultérieure doit être installé et disponible dans l'environnement.

SRT est disponible via `npm` sous la forme `@anthropic-ai/sandbox-runtime`. L'exemple suivant montre l'étape d'installation dans un Dockerfile :

```dockerfile
# Install srt sandboxing with cache clearing and verification
ARG SANDBOX_RUNTIME_VERSION=0.0.20
RUN npm cache clean --force && \
    npm install -g @anthropic-ai/sandbox-runtime@${SANDBOX_RUNTIME_VERSION} && \
    test -s "$(npm root -g)/@anthropic-ai/sandbox-runtime/package.json" && \
    srt --version

```

Au moment de l'exécution, le runner vérifie que SRT est disponible et fonctionnel :

```shell
$ if which srt > /dev/null; then
$ echo "SRT found, creating config..."
SRT found, creating config...
$ echo '{"network":{"allowedDomains":["host.docker.internal","localhost","gitlab.com","*.gitlab.com","duo-workflow-svc.runway.gitlab.net"],"deniedDomains":[],"allowAllUnixSockets":false},"filesystem":{"denyRead":["~/.ssh"],"allowWrite":["./","/tmp"],"denyWrite":["/opt/.gitlab-sandbox"],"allowGitConfig":true}}' > /opt/.gitlab-sandbox/srt-settings.json
$ echo "Testing SRT sandbox capabilities..."
Testing SRT sandbox capabilities...
```

L'erreur suivante peut se produire au moment de l'exécution, ce qui peut indiquer que les dépendances de SRT ne sont pas disponibles :

```shell
Warning: SRT found but can't create sandbox (insufficient privileges), running command directly
```

Pour résoudre ce problème :

1. Utilisez bash pour vérifier l'image avec la commande suivante :

   ```shell
   docker run --rm -it <image>:<tag> /bin/bash
   ```

1. Utilisez `srt` :

   ```shell
   srt ls
   ```

1. Si l'erreur suivante s'affiche, vous devez installer des dépendances supplémentaires dans votre image personnalisée :

   ```shell
   Error: Sandbox dependencies are not available on this system. Required: ripgrep (rg), bubblewrap (bwrap), and socat.
   ```

## Restrictions réseau et du système de fichiers {#network-and-filesystem-restrictions}

Lorsque le sandbox de l'environnement d'exécution est appliqué, les restrictions suivantes sont appliquées.

### Configurer les paramètres du sandbox {#configure-sandbox-settings}

Utilisez un fichier [`agent-config.yml`](flows/execution.md#create-the-configuration-file) pour configurer certains de vos paramètres de sandbox.

Par défaut, le sandbox autorise l'accès aux configurations suivantes :

- Domaines figurant sur la liste d'autorisation par défaut. Ils sont configurés automatiquement et ne peuvent pas être modifiés ou mis à jour.

### Variables d'environnement {#environment-variables}

Seules les variables d'environnement et les paramètres requis pour exécuter les opérations DAP et Git sont accessibles depuis l'environnement sandbox.

### Configuration du système de fichiers {#filesystem-configuration}

Le sandbox applique les restrictions suivantes au système de fichiers :

- Restrictions en lecture :  Les clés SSH (`~/.ssh`) sont bloquées.
- Écriture autorisée :  Répertoire courant (`./`) et `/tmp`.
- Écriture restreinte : `/opt/.gitlab-sandbox` (utilisé pour les fichiers internes à la plateforme, comme les paramètres du sandbox).
- Accès à la configuration Git :  Autorisé.

### Configurer une politique réseau {#configure-a-network-policy}

SRT est inclus dans l'image Docker fournie par défaut par GitLab. Vous pouvez également [installer SRT sur une image personnalisée](#install-anthropic-sandbox-runtime-srt-on-a-custom-image).

Lorsque SRT est installé, les flows ne peuvent accéder par défaut qu'aux domaines suivants. Ces domaines sont toujours autorisés et ne peuvent pas être supprimés :

- `localhost`
- `host.docker.internal`
- Le domaine de votre instance GitLab (par exemple, `gitlab.com`, `*.gitlab.com`)
- Le domaine du service GitLab Duo Workflow

Si vous utilisez une image personnalisée sans SRT, aucune restriction réseau n'est appliquée et le flow peut accéder à n'importe quel domaine accessible depuis le runner.

> [!note]
> La `network_policy` n'autorise pas `"*"` dans `allowed_domains` ni dans `denied_domains`. SRT ne prend pas en charge l'activation de tout le trafic réseau. Cependant, les caractères génériques sont autorisés dans les domaines, par exemple `"*.domain.com"`.

#### Contrôles de la politique réseau par l'administrateur {#administrator-network-policy-controls}

Lorsqu'un propriétaire de groupe principal sur GitLab.com ou un administrateur d'instance sur GitLab Self-Managed configure les contrôles d'accès réseau, ces paramètres définissent la politique de référence pour tous les flows. La case à cocher **Allow projects to extend network sandbox settings** détermine quels paramètres sont appliqués lorsque les propriétaires de projets les configurent dans `agent-config.yml`.

**Flexible mode** (**Allow projects to extend network sandbox settings** activé) :

- Les `allowed_domains` de `agent-config.yml` sont fusionnés avec la liste d'autorisation de l'administrateur.
- Les `denied_domains` de `agent-config.yml` sont fusionnés avec la liste de refus de l'administrateur.
- `include_recommended_allowed` dans `agent-config.yml` remplace le paramètre de l'administrateur.
- `allow_all_unix_sockets` dans `agent-config.yml` remplace le paramètre de l'administrateur.

**Strict mode** (**Allow projects to extend network sandbox settings** désactivé) :

- Les `denied_domains` de `agent-config.yml` sont fusionnés avec la liste de refus de l'administrateur.
- `include_recommended_allowed` ne peut être défini qu'à `false` pour renforcer un paramètre activé par l'administrateur. Cela n'a aucun effet lorsque l'administrateur l'a désactivé.
- `allow_all_unix_sockets` ne peut être défini qu'à `false` pour renforcer un paramètre activé par l'administrateur. Cela n'a aucun effet lorsque l'administrateur l'a désactivé.
- Les `allowed_domains` de `agent-config.yml` sont ignorés.

#### Configurer les paramètres au niveau du projet {#configure-project-level-settings}

Pour autoriser ou refuser des domaines supplémentaires, ajoutez une `network_policy` à votre fichier `agent-config.yml` :

```yaml
network_policy:
  include_recommended_allowed: true # default: false
  allow_all_unix_sockets: true      # default: false
  allowed_domains:
    - my-own-site.com
  denied_domains:
    - malicious.com
```

#### Autoriser l'accès aux sockets Unix {#allow-unix-socket-access}

Utilisez le paramètre `allow_all_unix_sockets` pour accorder au flow l'accès à tous les sockets de domaine Unix sur l'hôte. Cette option est désactivée par défaut.

> [!warning]
> L'activation de `allow_all_unix_sockets` accorde l'accès à tous les sockets Unix. N'activez cette option que si nécessaire et uniquement dans des environnements de confiance.

### Configurer les contrôles d'accès réseau pour votre instance ou groupe {#configure-network-access-controls-for-your-instance-or-group}

{{< history >}}

- [Introduits](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/229531) dans GitLab 18.11 [avec des feature flags](../../administration/feature_flags/_index.md) nommés `dap_instance_network_access_controls` et `dap_group_network_access_controls`. Désactivé par défaut.

{{< /history >}}

> [!flag]
> La disponibilité de cette fonctionnalité est contrôlée par un feature flag. Pour plus d'informations, consultez l'historique. Cette fonctionnalité est disponible à des fins de test, mais n'est pas prête pour une utilisation en production.

En plus des [paramètres `agent-config.yml` au niveau du projet](#configure-a-network-policy), les administrateurs et les propriétaires de groupe principal peuvent gérer les contrôles d'accès réseau via l'interface utilisateur GitLab. Ces paramètres sont stockés au niveau de l'instance (GitLab Self-Managed) ou au niveau du groupe principal (GitLab.com) et sont hérités par tous les projets sous-jacents.

Pour une description de la façon dont ces paramètres se combinent avec le `agent-config.yml` au niveau du projet, consultez [Contrôles de la politique réseau par l'administrateur](#administrator-network-policy-controls).

#### Configurer les contrôles d'accès réseau au niveau de l'instance {#configure-instance-level-network-access-controls}

Prérequis :

- Vous devez être administrateur.

Pour configurer les contrôles d'accès réseau au niveau de l'instance :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **GitLab Duo**.
1. Sélectionnez **Modifier la configuration**.
1. Sous **Données et vie privée**, dans la section **Network access**, configurez les paramètres suivants :
   - **Include recommended domains in the allowlist** :  Une liste sélectionnée de domaines recommandés est automatiquement incluse dans la liste d'autorisation.
   - **Allow all Unix sockets** :  Tous les sockets Unix sont autorisés pour les opérations GitLab Duo Agent Platform.
   - **Allow projects to extend network sandbox settings** :  Les utilisateurs ayant le rôle Maintainer ou Owner pour un projet peuvent inclure des domaines recommandés via le fichier `agent-config.yml`, ajouter d'autres domaines et autoriser tous les sockets Unix.
1. Facultatif. Sous **Domaines autorisés**, ajoutez ou supprimez des domaines de la liste d'autorisation. Sous **Blocked domains**, ajoutez ou supprimez des domaines de la liste de refus.
1. Sélectionnez **Sauvegarder les modifications**.

#### Configurer les contrôles d'accès réseau du groupe principal (GitLab.com) {#configure-top-level-group-network-access-controls-gitlabcom}

Prérequis :

- Vous devez avoir le rôle Owner pour le groupe principal.
- Le groupe doit être un groupe principal sur GitLab.com. Les sous-groupes héritent des paramètres de leur groupe principal.

Pour configurer les contrôles d'accès réseau au niveau du groupe :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre groupe principal.
1. Dans la barre latérale gauche, sélectionnez **Paramètres**, puis **GitLab Duo**.
1. Sélectionnez **Modifier la configuration**.
1. Sous **Données et vie privée**, dans la section **Network access**, configurez les mêmes paramètres que ceux décrits dans [Configurer les contrôles d'accès réseau au niveau de l'instance](#configure-instance-level-network-access-controls).
1. Sélectionnez **Sauvegarder les modifications**.

#### Ressources API associées {#related-api-resources}

- Booléens au niveau de l'instance :  Mutation GraphQL [`duoSettingsUpdate`](../../api/graphql/reference/_index.md#mutationduosettingsupdate).
- Booléens au niveau du groupe :  API REST [Update group attributes](../../api/groups.md#update-group-attributes), en utilisant le paramètre `ai_settings_attributes`.
- Liste d'autorisation et liste de refus de domaines : mutations GraphQL [`aiDomainSettingsInstanceUpdate`](../../api/graphql/reference/_index.md#mutationaidomainsettingsinstanceupdate) et [`aiDomainSettingsNamespaceUpdate`](../../api/graphql/reference/_index.md#mutationaidomainsettingsnamespaceupdate).

### Activer les domaines autorisés {#turn-on-allowed-domains}

Pour donner à vos flows l'accès à un ensemble de domaines externes utilisés pour les registres de paquets et les outils de développement, activez le paramètre `include_recommended_allowed`.

Ce paramètre est désactivé par défaut (`false`). Pour l'activer, dans votre fichier `agent-config.yml`, définissez `include_recommended_allowed` sur `true`.

Lorsque les contrôles d'accès réseau sont activés en mode strict (**Allow projects to extend network sandbox settings** désactivé), vous pouvez uniquement désactiver `include_recommended_allowed`. Le définir sur `true` n'a aucun effet lorsque l'administrateur l'a désactivé.

> [!warning]
> L'activation de `include_recommended_allowed` autorise l'accès réseau à un large ensemble de domaines externes. Ces points de sortie pourraient potentiellement être utilisés pour exfiltrer des données de votre environnement. N'activez cette option que si nécessaire et uniquement dans des environnements de confiance.

Ce paramètre active l'accès aux domaines suivants :

- `github.com`
- `www.github.com`
- `api.github.com`
- `npm.pkg.github.com`
- `raw.githubusercontent.com`
- `pkg-npm.githubusercontent.com`
- `objects.githubusercontent.com`
- `codeload.github.com`
- `avatars.githubusercontent.com`
- `camo.githubusercontent.com`
- `gist.github.com`
- `gitlab.com`
- `www.gitlab.com`
- `registry.gitlab.com`
- `bitbucket.org`
- `www.bitbucket.org`
- `api.bitbucket.org`
- `registry-1.docker.io`
- `auth.docker.io`
- `index.docker.io`
- `hub.docker.com`
- `www.docker.com`
- `production.cloudflare.docker.com`
- `download.docker.com`
- `gcr.io`
- `*.gcr.io`
- `ghcr.io`
- `mcr.microsoft.com`
- `*.data.mcr.microsoft.com`
- `public.ecr.aws`
- `cloud.google.com`
- `accounts.google.com`
- `gcloud.google.com`
- `storage.googleapis.com`
- `compute.googleapis.com`
- `container.googleapis.com`
- `artifactregistry.googleapis.com`
- `cloudresourcemanager.googleapis.com`
- `oauth2.googleapis.com`
- `www.googleapis.com`
- `login.microsoftonline.com`
- `packages.microsoft.com`
- `dotnet.microsoft.com`
- `dot.net`
- `dev.azure.com`
- `s3.amazonaws.com`
- `*.s3.amazonaws.com`
- `*.codeartifact.amazonaws.com`
- `*.s3.api.aws`
- `*.codeartifact.api.aws`
- `download.oracle.com`
- `yum.oracle.com`
- `registry.npmjs.org`
- `www.npmjs.com`
- `www.npmjs.org`
- `npmjs.com`
- `npmjs.org`
- `yarnpkg.com`
- `registry.yarnpkg.com`
- `pypi.org`
- `www.pypi.org`
- `files.pythonhosted.org`
- `pythonhosted.org`
- `test.pypi.org`
- `pypi.python.org`
- `pypa.io`
- `www.pypa.io`
- `rubygems.org`
- `www.rubygems.org`
- `api.rubygems.org`
- `index.rubygems.org`
- `ruby-lang.org`
- `www.ruby-lang.org`
- `rubyonrails.org`
- `www.rubyonrails.org`
- `rvm.io`
- `get.rvm.io`
- `crates.io`
- `www.crates.io`
- `index.crates.io`
- `static.crates.io`
- `rustup.rs`
- `static.rust-lang.org`
- `www.rust-lang.org`
- `proxy.golang.org`
- `sum.golang.org`
- `index.golang.org`
- `golang.org`
- `www.golang.org`
- `goproxy.io`
- `pkg.go.dev`
- `maven.org`
- `repo.maven.org`
- `central.maven.org`
- `repo1.maven.org`
- `jcenter.bintray.com`
- `gradle.org`
- `www.gradle.org`
- `services.gradle.org`
- `plugins.gradle.org`
- `kotlin.org`
- `www.kotlin.org`
- `spring.io`
- `repo.spring.io`
- `packagist.org`
- `www.packagist.org`
- `repo.packagist.org`
- `nuget.org`
- `www.nuget.org`
- `api.nuget.org`
- `pub.dev`
- `api.pub.dev`
- `hex.pm`
- `www.hex.pm`
- `cpan.org`
- `www.cpan.org`
- `metacpan.org`
- `www.metacpan.org`
- `api.metacpan.org`
- `cocoapods.org`
- `www.cocoapods.org`
- `cdn.cocoapods.org`
- `haskell.org`
- `www.haskell.org`
- `hackage.haskell.org`
- `swift.org`
- `www.swift.org`
- `archive.ubuntu.com`
- `security.ubuntu.com`
- `ubuntu.com`
- `www.ubuntu.com`
- `*.ubuntu.com`
- `ppa.launchpad.net`
- `launchpad.net`
- `www.launchpad.net`
- `dl.k8s.io`
- `pkgs.k8s.io`
- `k8s.io`
- `www.k8s.io`
- `releases.hashicorp.com`
- `apt.releases.hashicorp.com`
- `rpm.releases.hashicorp.com`
- `archive.releases.hashicorp.com`
- `hashicorp.com`
- `www.hashicorp.com`
- `repo.anaconda.com`
- `conda.anaconda.org`
- `anaconda.org`
- `www.anaconda.com`
- `anaconda.com`
- `continuum.io`
- `apache.org`
- `www.apache.org`
- `archive.apache.org`
- `downloads.apache.org`
- `eclipse.org`
- `www.eclipse.org`
- `download.eclipse.org`
- `nodejs.org`
- `www.nodejs.org`
- `sourceforge.net`
- `*.sourceforge.net`
- `packagecloud.io`
- `*.packagecloud.io`
- `json-schema.org`
- `www.json-schema.org`
- `json.schemastore.org`
- `www.schemastore.org`
- `*.modelcontextprotocol.io`

## Avertissements et comportement de reprise {#warnings-and-fallback-behavior}

Si le sandbox est indisponible ou ne peut pas être appliqué :

- Le flow s'exécute directement sans protection par sandbox
- Un message d'avertissement s'affiche dans les job logs CI avec un lien vers les instructions de configuration du runner

Cela garantit que les flows continuent de s'exécuter même si le sandbox ne peut pas être activé, tout en vous alertant de la situation.
