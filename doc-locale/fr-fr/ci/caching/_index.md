---
stage: Verify
group: Pipeline Authoring
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Utilisez la mise en cache dans GitLab CI/CD pour télécharger des dépendances à travers les jobs et les pipelines.
title: La mise en cache dans GitLab CI/CD
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Un cache est un ou plusieurs fichiers qu'un job télécharge et enregistre. Les jobs suivants qui utilisent le même cache n'ont pas à télécharger à nouveau les fichiers, ce qui leur permet de s'exécuter plus rapidement.

Pour apprendre à définir le cache dans votre fichier `.gitlab-ci.yml`, consultez la [référence `cache`](../yaml/_index.md#cache).

Pour les stratégies avancées de clés de cache, vous pouvez utiliser :

- [`cache:key:files`](../yaml/_index.md#cachekeyfiles) :  Générez des clés liées au contenu de fichiers spécifiques.
- [`cache:key:files_commits`](../yaml/_index.md#cachekeyfiles_commits) :  Générez des clés liées au dernier commit de fichiers spécifiques.

Pour plus de cas d'utilisation et d'exemples, consultez [les exemples de mise en cache CI/CD](examples.md).

## Différences entre le cache et les artefacts {#how-cache-is-different-from-artifacts}

Utilisez le cache pour les dépendances, comme les packages que vous téléchargez depuis Internet. Le cache est stocké là où GitLab Runner est installé et téléversé vers S3 si [le cache distribué est activé](https://docs.gitlab.com/runner/configuration/autoscale/#distributed-runners-caching).

Utilisez les artefacts pour transmettre des résultats de build intermédiaires entre les étapes. Les artefacts sont générés par un job, stockés dans GitLab et peuvent être téléchargés.

Les artefacts et les caches définissent tous deux leurs chemins par rapport au répertoire du projet et ne peuvent pas établir de liens vers des fichiers en dehors de celui-ci.

### Cache {#cache}

- Définissez le cache par job en utilisant le mot-clé `cache`. Sinon, il est désactivé.
- Les pipelines suivants peuvent utiliser le cache.
- Les jobs suivants dans le même pipeline peuvent utiliser le cache, si les dépendances sont identiques.
- Des projets différents ne peuvent pas partager le cache.
- Par défaut, les branches protégées et non protégées [ne partagent pas le cache](#cache-key-names). Cependant, vous pouvez [modifier ce comportement](#use-the-same-cache-for-all-branches).

### Artefacts {#artifacts}

- Définissez les artefacts par job.
- Les jobs suivants dans les étapes ultérieures du même pipeline peuvent utiliser les artefacts.
- Les artefacts expirent après 30 jours par défaut. Vous pouvez définir un [délai d'expiration](../yaml/_index.md#artifactsexpire_in) personnalisé.
- Les derniers artefacts n'expirent pas si [conserver les derniers artefacts](../jobs/job_artifacts.md#keep-artifacts-from-most-recent-successful-jobs) est activé.
- Utilisez les [dépendances](../yaml/_index.md#dependencies) pour contrôler quels jobs récupèrent les artefacts.

## Bonnes pratiques de mise en cache {#good-caching-practices}

Pour garantir une disponibilité maximale du cache, effectuez une ou plusieurs des actions suivantes :

- [Taguez vos runners](../runners/configure_runners.md#control-jobs-that-a-runner-can-run) et utilisez le tag sur les jobs qui partagent le cache.
- [Utilisez des runners disponibles uniquement pour un projet particulier](../runners/runners_scope.md#prevent-a-project-runner-from-being-enabled-for-other-projects).
- [Utilisez une `key`](../yaml/_index.md#cachekey) adaptée à votre workflow. Par exemple, vous pouvez configurer un cache différent pour chaque branche.

Pour que les runners travaillent efficacement avec les caches, vous devez effectuer l'une des actions suivantes :

- Utilisez un seul runner pour tous vos jobs.
- Utilisez plusieurs runners dotés d'un [cache distribué](https://docs.gitlab.com/runner/configuration/autoscale/#distributed-runners-caching), où le cache est stocké dans des buckets S3. Les runners d'instance sur GitLab.com se comportent de cette façon. Ces runners peuvent être en mode autoscale, mais ce n'est pas obligatoire. Pour gérer les objets de cache, appliquez des règles de cycle de vie pour supprimer les objets de cache après une certaine période. Les règles de cycle de vie sont disponibles sur le serveur de stockage d'objets.
- Utilisez plusieurs runners avec la même architecture et faites en sorte que ces runners partagent un répertoire monté en réseau commun pour stocker le cache. Ce répertoire doit utiliser NFS ou quelque chose de similaire. Ces runners doivent être en mode autoscale.

## Utiliser plusieurs caches {#use-multiple-caches}

Vous pouvez avoir un maximum de quatre caches par job :

```yaml
test-job:
  stage: build
  cache:
    - key:
        files:
          - Gemfile.lock
      paths:
        - vendor/ruby
    - key:
        files:
          - yarn.lock
      paths:
        - .yarn-cache/
  script:
    - bundle config set --local path 'vendor/ruby'
    - bundle install
    - yarn install --cache-folder .yarn-cache
    - echo Run tests...
```

Si plusieurs caches sont combinés avec une clé de cache de secours, le cache de secours global est récupéré chaque fois qu'un cache n'est pas trouvé.

## Utiliser une clé de cache de secours {#use-a-fallback-cache-key}

### Clés de secours par cache {#per-cache-fallback-keys}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/110467) dans GitLab 16.0

{{< /history >}}

Chaque entrée de cache prend en charge jusqu'à cinq clés de secours avec le [mot-clé `fallback_keys`](../yaml/_index.md#cachefallback_keys). Lorsqu'un job ne trouve pas de clé de cache, il tente de récupérer un cache de secours à la place. Les clés de secours sont recherchées dans l'ordre jusqu'à ce qu'un cache soit trouvé. Si aucun cache n'est trouvé, le job s'exécute sans utiliser de cache. Par exemple :

```yaml
test-job:
  stage: build
  cache:
    - key: cache-$CI_COMMIT_REF_SLUG
      fallback_keys:
        - cache-$CI_DEFAULT_BRANCH
        - cache-default
      paths:
        - vendor/ruby
  script:
    - bundle config set --local path 'vendor/ruby'
    - bundle install
    - echo Run tests...
```

Dans cet exemple :

1. Le job recherche le cache `cache-$CI_COMMIT_REF_SLUG`.
1. Si `cache-$CI_COMMIT_REF_SLUG` n'est pas trouvé, le job recherche `cache-$CI_DEFAULT_BRANCH` comme option de secours.
1. Si `cache-$CI_DEFAULT_BRANCH` n'est pas non plus trouvé, le job recherche `cache-default` comme deuxième option de secours.
1. Si aucun n'est trouvé, le job télécharge toutes les dépendances Ruby sans utiliser de cache, mais crée un nouveau cache pour `cache-$CI_COMMIT_REF_SLUG` à la fin du job.

Les clés de secours suivent la même logique de traitement que `cache:key` :

- Si vous [videz les caches manuellement](#clear-the-cache-manually), les clés de secours par cache sont complétées par un index comme les autres clés de cache.
- Si le [paramètre **Utiliser des caches distincts pour les branches protégées**](#cache-key-names) est activé, les clés de secours par cache sont complétées par `-protected` ou `-non_protected`.

### Clé de secours globale {#global-fallback-key}

Vous pouvez utiliser la [variable prédéfinie](../variables/predefined_variables.md) `$CI_COMMIT_REF_SLUG` pour spécifier votre [`cache:key`](../yaml/_index.md#cachekey). Par exemple, si votre `$CI_COMMIT_REF_SLUG` est `test`, vous pouvez configurer un job pour télécharger le cache tagué avec `test`.

Si un cache avec ce tag n'est pas trouvé, vous pouvez utiliser `CACHE_FALLBACK_KEY` pour spécifier un cache à utiliser lorsqu'il n'en existe aucun.

Dans l'exemple suivant, si `$CI_COMMIT_REF_SLUG` n'est pas trouvé, le job utilise la clé définie par la variable `CACHE_FALLBACK_KEY` :

```yaml
variables:
  CACHE_FALLBACK_KEY: fallback-key

job1:
  script:
    - echo
  cache:
    key: "$CI_COMMIT_REF_SLUG"
    paths:
      - binaries/
```

L'ordre d'extraction des caches est le suivant :

1. Tentative de récupération pour `cache:key`
1. Tentatives de récupération pour chaque entrée dans l'ordre dans `fallback_keys`
1. Tentative de récupération pour la clé de secours globale dans `CACHE_FALLBACK_KEY`

Le processus d'extraction du cache s'arrête après la récupération réussie du premier cache.

## Désactiver le cache pour des jobs spécifiques {#disable-cache-for-specific-jobs}

Si vous définissez le cache globalement, chaque job utilise la même définition. Vous pouvez remplacer ce comportement pour chaque job.

Pour le désactiver complètement pour un job, utilisez une liste vide :

```yaml
job:
  cache: []
```

## Hériter de la configuration globale, mais remplacer des paramètres spécifiques par job {#inherit-global-configuration-but-override-specific-settings-per-job}

Vous pouvez remplacer les paramètres de cache sans écraser le cache global en utilisant des [ancres](../yaml/yaml_optimization.md#anchors). Par exemple, si vous souhaitez remplacer la `policy` pour un job :

```yaml
default:
  cache: &global_cache
    key: $CI_COMMIT_REF_SLUG
    paths:
      - node_modules/
      - public/
      - vendor/
    policy: pull-push

job:
  cache:
    # inherit all global cache settings
    <<: *global_cache
    # override the policy
    policy: pull
```

Pour plus d'informations, consultez [`cache: policy`](../yaml/_index.md#cachepolicy).

## Noms des clés de cache {#cache-key-names}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/330047) dans GitLab 15.0.
- Le suffixe `-protected` pour le rôle Maintainer et supérieur a été [introduit](https://about.gitlab.com/releases/2025/11/26/patch-release-gitlab-18-6-1-released/) dans GitLab 18.4.5.

{{< /history >}}

Un suffixe est ajouté à la clé de cache, à l'exception de la [clé de cache de secours globale](#global-fallback-key).

Les clés de cache reçoivent le suffixe `-protected` si le pipeline :

- S'exécute pour une branche ou un tag protégé. L'utilisateur doit avoir la permission de fusionner vers la [branche protégée](../../user/project/repository/branches/protected.md) ou la permission de créer un [tag protégé](../../user/project/protected_tags.md).
- A été démarré par un utilisateur ayant le rôle Maintainer ou Owner.

Les clés générées dans d'autres pipelines reçoivent le suffixe `non_protected`.

Par exemple, si :

- `cache:key` est défini sur `$CI_COMMIT_REF_SLUG`.
- `main` est une branche protégée.
- `feature` est une branche non protégée.

| Branche      | Clé de cache du rôle Developer | Clé de cache du rôle Maintainer |
|-------------|--------------------------|---------------------------|
| `main`      | `main-protected`         | `main-protected`          |
| `feature`   | `feature-non_protected`  | `feature-protected`       |

De plus, pour les pipelines associés aux tags, le statut de protection du tag est prioritaire pour le suffixe, et non la branche où le pipeline s'exécute. Ce comportement garantit des limites de sécurité cohérentes, car la référence déclencheuse détermine les permissions d'accès au cache.

Par exemple, si :

- `cache:key` est défini sur `$CI_COMMIT_TAG`.
- `main` est une branche protégée.
- `feature` est une branche non protégée.
- `1.0.0` est un tag protégé.
- `1.1.1-rc1` est un tag non protégé.

| Tag         | Branche    | Clé de cache du rôle Developer  | Clé de cache du rôle Maintainer |
|-------------|-----------|---------------------------|---------------------------|
| `1.0.0`     | `main`    | `1.0.0-protected`         | `1.0.0-protected`         |
| `1.0.0`     | `feature` | `1.0.0-protected`         | `1.0.0-protected`         |
| `1.1.1-rc1` | `main`    | `1.1.1-rc1-non_protected` | `1.1.1-rc1-protected`     |
| `1.1.1-rc1` | `feature` | `1.1.1-rc1-non_protected` | `1.1.1-rc1-protected`     |

### Utiliser le même cache pour toutes les branches {#use-the-same-cache-for-all-branches}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/361643) dans GitLab 15.0.

{{< /history >}}

Si vous ne souhaitez pas utiliser les [noms de clés de cache](#cache-key-names), vous pouvez faire en sorte que toutes les branches (protégées et non protégées) utilisent le même cache.

La séparation du cache avec les [noms de clés de cache](#cache-key-names) est une fonctionnalité de sécurité et ne doit être désactivée que dans un environnement où tous les utilisateurs ayant le rôle Developer sont hautement fiables.

Pour utiliser le même cache pour toutes les branches :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **CI/CD**.
1. Développez **Pipelines généraux**.
1. Décochez la case **Utiliser des caches distincts pour les branches protégées**.
1. Sélectionnez **Sauvegarder les modifications**.

## Disponibilité du cache {#availability-of-the-cache}

La mise en cache est une optimisation, mais elle n'est pas garantie de toujours fonctionner. Vous devrez peut-être régénérer les fichiers mis en cache dans chaque job qui en a besoin.

Après avoir défini un [cache dans `.gitlab-ci.yml`](../yaml/_index.md#cache), la disponibilité du cache dépend de :

- Le type d'exécuteur du runner.
- Si différents runners sont utilisés pour transmettre le cache entre les jobs.

### Emplacement de stockage des caches {#where-the-caches-are-stored}

Tous les caches définis pour un job sont archivés dans un seul fichier `cache.zip`. La configuration du runner définit l'emplacement de stockage du fichier. Par défaut, le cache est stocké sur la machine où GitLab Runner est installé. L'emplacement dépend également du type d'exécuteur.

| Exécuteur du runner        | Chemin par défaut du cache |
| ---------------------- | ------------------------- |
| [Shell](https://docs.gitlab.com/runner/executors/shell/) | Localement, dans le répertoire personnel de l'utilisateur `gitlab-runner` : `/home/gitlab-runner/cache/<user>/<project>/<cache-key>/cache.zip`. |
| [Docker](https://docs.gitlab.com/runner/executors/docker/) | Localement, dans les [volumes Docker](https://docs.gitlab.com/runner/executors/docker/#configure-directories-for-the-container-build-and-cache) : `/var/lib/docker/volumes/<volume-id>/_data/<user>/<project>/<cache-key>/cache.zip`. |
| [Docker Machine](https://docs.gitlab.com/runner/executors/docker_machine/) (runners en autoscale) | Identique à l'exécuteur Docker. |

Si vous utilisez le cache et les artefacts pour stocker le même chemin dans vos jobs, le cache peut être écrasé car les caches sont restaurés avant les artefacts.

### Fonctionnement de l'archivage et de l'extraction {#how-archiving-and-extracting-works}

Cet exemple montre deux jobs dans deux étapes consécutives :

```yaml
stages:
  - build
  - test

default:
  cache:
    key: build-cache
    paths:
      - vendor/
  before_script:
    - echo "Hello"

job A:
  stage: build
  script:
    - mkdir vendor/
    - echo "build" > vendor/hello.txt
  after_script:
    - echo "World"

job B:
  stage: test
  script:
    - cat vendor/hello.txt
```

Si une machine dispose d'un seul runner installé, tous les jobs de votre projet s'exécutent sur le même hôte :

1. Le pipeline démarre.
1. `job A` s'exécute.
1. Le cache est extrait (s'il est trouvé).
1. `before_script` est exécuté.
1. `script` est exécuté.
1. `after_script` est exécuté.
1. `cache` s'exécute et le répertoire `vendor/` est compressé dans `cache.zip`. Ce fichier est ensuite enregistré dans le répertoire en fonction du [paramètre du runner](#where-the-caches-are-stored) et de la `cache: key`.
1. `job B` s'exécute.
1. Le cache est extrait (s'il est trouvé).
1. `before_script` est exécuté.
1. `script` est exécuté.
1. Le pipeline se termine.

En utilisant un seul runner sur une seule machine, vous évitez le problème où `job B` pourrait s'exécuter sur un runner différent de `job A`. Cette configuration garantit que le cache peut être réutilisé entre les étapes. Cela ne fonctionne que si l'exécution passe de l'étape `build` à l'étape `test` sur le même runner/machine. Dans le cas contraire, le cache [peut ne pas être disponible](#cache-mismatch).

Pendant le processus de mise en cache, il y a également quelques points à prendre en compte :

- Si un autre job, avec une autre configuration de cache, a enregistré son cache dans le même fichier zip, il est écrasé. Si le cache partagé basé sur S3 est utilisé, le fichier est en outre téléversé vers S3 dans un objet basé sur la clé de cache. Ainsi, deux jobs avec des chemins différents mais la même clé de cache écrasent leur cache respectif.
- Lors de l'extraction du cache depuis `cache.zip`, tout le contenu du fichier zip est extrait dans le répertoire de travail du job (généralement le dépôt téléchargé), et le runner ne se soucie pas si l'archive de `job A` écrase des éléments de l'archive de `job B`.

Cela fonctionne ainsi car le cache créé pour un runner n'est souvent pas valide lorsqu'il est utilisé par un autre. Un runner différent peut s'exécuter sur une architecture différente (par exemple, lorsque le cache contient des fichiers binaires). De plus, étant donné que les différentes étapes peuvent être exécutées par des runners fonctionnant sur des machines différentes, c'est un comportement par défaut sûr.

## Vider le cache {#clearing-the-cache}

Les runners utilisent le [cache](../yaml/_index.md#cache) pour accélérer l'exécution de vos jobs en réutilisant les données existantes. Cela peut parfois entraîner un comportement incohérent.

Il existe deux façons de repartir avec une nouvelle copie du cache.

### Vider le cache en modifiant `cache:key` {#clear-the-cache-by-changing-cachekey}

Modifiez la valeur de `cache: key` dans votre fichier `.gitlab-ci.yml`. La prochaine fois que le pipeline s'exécute, le cache est stocké dans un emplacement différent.

### Vider le cache manuellement {#clear-the-cache-manually}

Vous pouvez vider le cache dans l'interface utilisateur de GitLab :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Version** > **Pipelines**.
1. Dans le coin supérieur droit, sélectionnez **Vider les caches des runners**.

Au prochain commit, vos jobs CI/CD utilisent un nouveau cache.

> [!note]
> Chaque fois que vous videz le cache manuellement, le [nom interne du cache](#where-the-caches-are-stored) est mis à jour. Le nom utilise le format `cache-<index>`, et l'index est incrémenté de un. L'ancien cache n'est pas supprimé. Vous pouvez supprimer manuellement ces fichiers depuis le stockage du runner.

## Dépannage {#troubleshooting}

### Incohérence de cache {#cache-mismatch}

Si vous avez une incohérence de cache, suivez ces étapes pour résoudre le problème.

| Cause de l'incohérence de cache | Comment y remédier |
| --------------------------- | ------------- |
| Vous utilisez plusieurs runners autonomes (pas en mode autoscale) associés à un projet sans cache partagé. | Utilisez un seul runner pour votre projet ou utilisez plusieurs runners avec le cache distribué activé. |
| Vous utilisez des runners en mode autoscale sans cache distribué activé. | Configurez le runner en mode autoscale pour utiliser un cache distribué. |
| La machine sur laquelle le runner est installé manque d'espace disque ou, si vous avez configuré un cache distribué, le bucket S3 où le cache est stocké ne dispose pas d'assez d'espace. | Assurez-vous de libérer de l'espace pour permettre le stockage de nouveaux caches. Il n'existe pas de moyen automatique d'effectuer cette opération. |
| Vous utilisez la même `key` pour des jobs qui mettent en cache des chemins différents. | Utilisez des clés de cache différentes afin que l'archive de cache soit stockée dans un emplacement différent et n'écrase pas les mauvais caches. |
| Vous n'avez pas activé la [mise en cache distribuée des runners sur vos runners](https://docs.gitlab.com/runner/configuration/autoscale/#distributed-runners-caching). | Définissez `Shared = false` et re-provisionnez vos runners. |

#### Exemple d'incohérence de cache 1 {#cache-mismatch-example-1}

Si vous n'avez qu'un seul runner assigné à votre projet, le cache est stocké par défaut sur la machine du runner.

Si deux jobs ont la même clé de cache mais un chemin différent, les caches peuvent être écrasés. Par exemple :

```yaml
stages:
  - build
  - test

job A:
  stage: build
  script: make build
  cache:
    key: same-key
    paths:
      - public/

job B:
  stage: test
  script: make test
  cache:
    key: same-key
    paths:
      - vendor/
```

1. `job A` s'exécute.
1. `public/` est mis en cache sous `cache.zip`.
1. `job B` s'exécute.
1. Le cache précédent, le cas échéant, est décompressé.
1. `vendor/` est mis en cache sous `cache.zip` et écrase le précédent.
1. La prochaine fois que `job A` s'exécute, il utilise le cache de `job B`, qui est différent et donc inefficace.

Pour résoudre ce problème, utilisez des `keys` différentes pour chaque job.

#### Exemple d'incohérence de cache 2 {#cache-mismatch-example-2}

Dans cet exemple, vous avez plus d'un runner assigné à votre projet et le cache distribué n'est pas activé.

La deuxième fois que le pipeline s'exécute, vous souhaitez que `job A` et `job B` réutilisent leur cache respectif (qui dans ce cas est différent) :

```yaml
stages:
  - build
  - test

job A:
  stage: build
  script: build
  cache:
    key: keyA
    paths:
      - vendor/

job B:
  stage: test
  script: test
  cache:
    key: keyB
    paths:
      - vendor/
```

Même si la `key` est différente, les fichiers mis en cache peuvent être « nettoyés » avant chaque étape si les jobs s'exécutent sur des runners différents dans des pipelines successifs.

### Runners concurrents avec cache local manquant {#concurrent-runners-missing-local-cache}

Si vous avez configuré plusieurs runners concurrents avec l'exécuteur Docker, les fichiers mis en cache localement peuvent ne pas être présents pour les jobs s'exécutant de façon concurrente comme prévu. Les noms des volumes de cache sont construits de façon unique pour chaque instance de runner, de sorte que les fichiers mis en cache par une instance de runner ne sont pas trouvés dans le cache par une autre instance de runner.

Pour partager le cache entre des runners concurrents, vous pouvez :

- Utilisez la section `[runners.docker]` du fichier `config.toml` des runners pour configurer un point de montage unique sur l'hôte mappé vers `/cache` dans chaque conteneur, par exemple `volumes = ["/mnt/gitlab-runner/cache-for-all-concurrent-jobs:/cache"]`. Cette approche empêche le runner de créer des noms de volume uniques pour les jobs concurrents.
- Utilisez un cache distribué.
