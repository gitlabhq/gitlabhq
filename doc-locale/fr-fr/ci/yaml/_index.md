---
stage: Verify
group: Pipeline Authoring
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Référence de syntaxe YAML CI/CD
description: "Mots-clés de configuration du pipeline, syntaxe, exemples et entrées."
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Ce document répertorie les options de configuration du fichier `.gitlab-ci.yml` GitLab. Ce fichier est l'endroit où vous définissez les jobs CI/CD qui constituent votre pipeline.

- Si vous êtes déjà familiarisé avec les [concepts de base de CI/CD](../_index.md), essayez de créer votre propre fichier `.gitlab-ci.yml` en suivant un tutoriel qui présente un pipeline [simple](../quick_start/_index.md) ou [complexe](../quick_start/tutorial.md).
- Pour une collection d'exemples, consultez [les exemples GitLab CI/CD](../examples/_index.md).
- Pour afficher un grand fichier `.gitlab-ci.yml` utilisé dans une entreprise, consultez le [fichier `.gitlab-ci.yml` pour `gitlab`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/.gitlab-ci.yml).

Lorsque vous modifiez votre fichier `.gitlab-ci.yml`, vous pouvez le valider avec l'outil [CI Lint](lint.md).

La configuration GitLab CI/CD utilise le format YAML, l'ordre des mots-clés n'est donc pas important, sauf indication contraire.

Utilisez les [expressions CI/CD](expressions.md) pour des options de configuration de pipeline plus dynamiques.

<!--
If you are editing content on this page, follow the instructions for documenting keywords:
<https://docs.gitlab.com/development/cicd/cicd_reference_documentation_guide/>
-->

## Mots-clés {#keywords}

Une configuration de pipeline GitLab CI/CD inclut :

- Les [mots-clés globaux](#global-keywords) qui configurent le comportement du pipeline :

  | Mot-clé                           | Description |
  |-----------------------------------|:------------|
  | [`default`](#default)             | Valeurs par défaut personnalisées pour les mots-clés de job. |
  | [`include`](#include)             | Importer la configuration à partir d'autres fichiers YAML. |
  | [`stages`](#stages)               | Les noms et l'ordre des étapes du pipeline. |
  | [`variables`](#default-variables) | Définir les variables CI/CD par défaut pour tous les jobs du pipeline. |
  | [`workflow`](#workflow)           | Contrôler les types de pipeline qui s'exécutent. |

- [Mots-clés d'en-tête](#header-keywords)

  | Mot-clé         | Description |
  |-----------------|:------------|
  | [`spec`](#spec) | Définir les spécifications pour les fichiers de configuration externes. |

- Les [jobs](../jobs/_index.md) configurés avec des [mots-clés de job](#job-keywords) :

  | Mot-clé                                       | Description |
  |:----------------------------------------------|:------------|
  | [`after_script`](#after_script)               | Remplacer un ensemble de commandes exécutées après le job. |
  | [`allow_failure`](#allow_failure)             | Autoriser l'échec du job. Un job en échec ne provoque pas l'échec du pipeline. |
  | [`artifacts`](#artifacts)                     | Liste de fichiers et de répertoires à joindre à un job en cas de succès. |
  | [`before_script`](#before_script)             | Remplacer un ensemble de commandes exécutées avant le job. |
  | [`cache`](#cache)                             | Liste de fichiers à mettre en cache entre les exécutions successives. |
  | [`coverage`](#coverage)                       | Paramètres de couverture de code pour un job donné. |
  | [`dast_configuration`](#dast_configuration)   | Utiliser la configuration des profils DAST au niveau du job. |
  | [`dependencies`](#dependencies)               | Restreindre les artefacts transmis à un job spécifique en fournissant une liste de jobs dont les artefacts doivent être récupérés. |
  | [`environment`](#environment)                 | Nom d'un environnement vers lequel le job effectue un déploiement. |
  | [`extends`](#extends)                         | Entrées de configuration dont ce job hérite. |
  | [`identity`](#identity)                       | S'authentifier auprès de services tiers à l'aide de la fédération d'identité. |
  | [`image`](#image)                             | Utiliser des images Docker. |
  | [`inherit`](#inherit)                         | Sélectionner les valeurs par défaut globales dont tous les jobs héritent. |
  | [`interruptible`](#interruptible)             | Définit si un job peut être annulé lorsqu'il est rendu redondant par une exécution plus récente. |
  | [`manual_confirmation`](#manual_confirmation) | Définir un message de confirmation personnalisé pour un job manuel. |
  | [`needs`](#needs)                             | Exécuter des jobs plus tôt que l'ordre des étapes. |
  | [`pages`](#pages)                             | Téléverser le résultat d'un job à utiliser avec GitLab Pages. |
  | [`parallel`](#parallel)                       | Nombre d'instances d'un job à exécuter en parallèle. |
  | [`release`](#release)                         | Indique au runner de générer un objet de [release](../../user/project/releases/_index.md). |
  | [`resource_group`](#resource_group)           | Limiter la simultanéité des jobs. |
  | [`retry`](#retry)                             | Quand et combien de fois un job peut être réessayé automatiquement en cas d'échec. |
  | [`rules`](#rules)                             | Liste de conditions à évaluer pour déterminer les attributs sélectionnés d'un job et si celui-ci est créé ou non. |
  | [`script`](#script)                           | Script shell exécuté par un runner. |
  | [`run`](#run)                                 | Configuration d'exécution exécutée par un runner. |
  | [`secrets`](#secrets)                         | Les secrets CI/CD dont le job a besoin. |
  | [`services`](#services)                       | Utiliser des images de services Docker. |
  | [`stage`](#stage)                             | Définit l'étape d'un job. |
  | [`start_in`](#start_in)                       | Retarder l'exécution d'un job pendant une durée spécifiée. Nécessite `when: delayed`. |
  | [`tags`](#tags)                               | Liste de tags utilisés pour sélectionner un runner. |
  | [`timeout`](#timeout)                         | Définir un délai d'expiration personnalisé au niveau du job qui prend la priorité sur le paramètre global du projet. |
  | [`trigger`](#trigger)                         | Définit un déclencheur de pipeline downstream. |
  | [`variables`](#job-variables)                 | Définir des variables CI/CD pour des jobs individuels. |
  | [`when`](#when)                               | Quand exécuter le job. |

- [Mots-clés obsolètes](deprecated_keywords.md) qui ne sont plus recommandés.

---

## Mots-clés globaux {#global-keywords}

Certains mots-clés ne sont pas définis dans un job. Ces mots-clés contrôlent le comportement du pipeline ou importent une configuration de pipeline supplémentaire.

---

### `default` {#default}

Vous pouvez définir des valeurs par défaut globales pour certains mots-clés. Chaque mot-clé par défaut est copié dans chaque job qui ne l'a pas encore défini.

La configuration par défaut ne fusionne pas avec la configuration du job. Si le job a déjà un mot-clé défini, le mot-clé du job est prioritaire et la configuration par défaut pour ce mot-clé n'est pas utilisée.

**Type de mot-clé** : Mot-clé global.

**Valeurs prises en charge** : Ces mots-clés peuvent avoir des valeurs par défaut personnalisées :

- [`after_script`](#after_script)
- [`artifacts`](#artifacts)
- [`before_script`](#before_script)
- [`cache`](#cache)
- [`hooks`](#hooks)
- [`id_tokens`](#id_tokens)
- [`image`](#image)
- [`interruptible`](#interruptible)
- [`retry`](#retry)
- [`services`](#services)
- [`tags`](#tags)

**Exemple de `default`** :

```yaml
default:
  image: ruby:3.0
  retry: 2

rspec:
  script: bundle exec rspec

rspec 2.7:
  image: ruby:2.7
  script: bundle exec rspec
```

Dans cet exemple :

- `image: ruby:3.0` et `retry: 2` sont les mots-clés par défaut pour tous les jobs du pipeline.
- Le job `rspec` n'a pas `image` ni `retry` défini, il utilise donc les valeurs par défaut `image: ruby:3.0` et `retry: 2`.
- Le job `rspec 2.7` n'a pas `retry` défini, mais il a `image` explicitement défini. Il utilise la valeur par défaut `retry: 2`, mais ignore la valeur par défaut `image` et utilise `image: ruby:2.7` défini dans le job.

**Informations complémentaires** :

- Contrôlez l'héritage des mots-clés par défaut dans les jobs avec [`inherit:default`](#inheritdefault).
- Les valeurs par défaut globales ne sont pas transmises aux [pipelines downstream](../pipelines/downstream_pipelines.md), qui s'exécutent indépendamment du pipeline upstream qui a déclenché le pipeline downstream.

---

### `include` {#include}

Utilisez `include` pour inclure des fichiers YAML externes dans votre configuration CI/CD. Vous pouvez diviser un long fichier `.gitlab-ci.yml` en plusieurs fichiers pour améliorer la lisibilité ou réduire la duplication de la même configuration à plusieurs endroits.

Vous pouvez également stocker des fichiers de modèles dans un dépôt central et les inclure dans des projets.

Les fichiers `include` sont :

- Fusionnés avec ceux du fichier `.gitlab-ci.yml`.
- Toujours évalués en premier, puis fusionnés avec le contenu du fichier `.gitlab-ci.yml`, quelle que soit la position du mot-clé `include`.

Le délai maximal pour résoudre tous les fichiers est de 30 secondes.

**Type de mot-clé** : Mot-clé global.

**Valeurs prises en charge** : Les sous-clés de `include` :

- [`include:component`](#includecomponent)
- [`include:local`](#includelocal)
- [`include:project`](#includeproject)
- [`include:remote`](#includeremote)
- [`include:template`](#includetemplate)

Et éventuellement :

- [`include:inputs`](#includeinputs)
- [`include:rules`](#includerules)
- [`include:integrity`](#includeintegrity)
- [`include:cache`](#includecache)

**Informations complémentaires** :

- Seules [certaines variables CI/CD](includes.md#use-variables-with-include) peuvent être utilisées avec les mots-clés `include`.
- Utilisez la fusion pour personnaliser et remplacer les configurations CI/CD incluses avec les configurations locales.
- Vous pouvez remplacer la configuration incluse en utilisant le même nom de job ou le même mot-clé global dans le fichier `.gitlab-ci.yml`. Les deux configurations sont fusionnées et la configuration du fichier `.gitlab-ci.yml` est prioritaire sur la configuration incluse.
- Si vous réexécutez un :
  - Job, les fichiers `include` ne sont pas récupérés à nouveau. Tous les jobs d'un pipeline utilisent la configuration récupérée lors de la création du pipeline. Toute modification apportée aux fichiers source `include` n'affecte pas les réexécutions de jobs.
  - Pipeline, les fichiers `include` sont récupérés à nouveau. S'ils ont changé depuis la dernière exécution du pipeline, le nouveau pipeline utilise la configuration modifiée.
- Vous pouvez avoir jusqu'à 150 inclusions par pipeline par défaut, y compris les inclusions [imbriquées](includes.md#use-nested-includes). De plus :
  - Dans [GitLab 16.0 et versions ultérieures](https://gitlab.com/gitlab-org/gitlab/-/issues/207270), les utilisateurs de GitLab Self-Managed peuvent modifier la valeur du [nombre maximum d'inclusions](../../administration/cicd/limits.md#maximum-number-of-includes).
  - Dans les inclusions imbriquées, le même fichier peut être inclus plusieurs fois, mais les inclusions en double sont comptabilisées dans la limite.

---

#### `include:component` {#includecomponent}

Utilisez `include:component` pour ajouter un [composant CI/CD](../components/_index.md) à la configuration du pipeline.

**Type de mot-clé** : Mot-clé global.

**Valeurs prises en charge** : L'adresse complète du composant CI/CD, formatée sous la forme `<fully-qualified-domain-name>/<project-path>/<component-name>@<specific-version>`.

**Exemple de `include:component`** :

```yaml
include:
  - component: $CI_SERVER_FQDN/my-org/security-components/secret-detection@1.0
```

**Informations complémentaires** :

- Si le projet source du composant est privé, l'utilisateur exécutant le pipeline doit disposer au minimum du rôle Reporter. Pour les projets internes, tout utilisateur authentifié non externe peut accéder au composant. Pour les projets publics, aucune adhésion n'est requise.

**Related topics** :

- [Utiliser un composant CI/CD](../components/_index.md#use-a-component).

---

#### `include:local` {#includelocal}

Utilisez `include:local` pour inclure un fichier qui se trouve dans le même dépôt et la même branche que le fichier de configuration contenant le mot-clé `include`. Utilisez `include:local` à la place des liens symboliques.

**Type de mot-clé** : Mot-clé global.

**Valeurs prises en charge** :

Un chemin complet relatif au répertoire racine (`/`) :

- Le fichier YAML doit avoir l'extension `.yml` ou `.yaml`.
- Vous pouvez [utiliser les caractères génériques `*` et `**` dans le chemin du fichier](includes.md#use-includelocal-with-wildcard-file-paths).
- Vous pouvez utiliser [certaines variables CI/CD](includes.md#use-variables-with-include).

**Exemple de `include:local`** :

```yaml
include:
  - local: '/templates/.gitlab-ci-template.yml'
```

Vous pouvez également utiliser une syntaxe plus courte pour définir le chemin :

```yaml
include: '.gitlab-ci-production.yml'
```

**Informations complémentaires** :

- Le fichier `.gitlab-ci.yml` et le fichier local doivent être sur la même branche.
- Vous ne pouvez pas inclure de fichiers locaux via des chemins de sous-modules Git.
- La configuration `include` est toujours évaluée en fonction de l'emplacement du fichier contenant le mot-clé `include`, et non du projet exécutant le pipeline. Si un [`include` imbriqué](includes.md#use-nested-includes) se trouve dans un fichier de configuration d'un autre projet, `include: local` recherche le fichier dans cet autre projet.

---

#### `include:project` {#includeproject}

Pour inclure des fichiers d'un autre projet privé sur la même instance GitLab, utilisez `include:project` et `include:file`.

**Type de mot-clé** : Mot-clé global.

**Valeurs prises en charge** :

- `include:project` : Le chemin complet du projet GitLab.
- `include:file` Un chemin de fichier complet, ou un tableau de chemins de fichiers, relatif au répertoire racine (`/`). Les fichiers YAML doivent avoir l'extension `.yml` ou `.yaml`.
- `include:ref` : Facultatif. La référence depuis laquelle récupérer le fichier. Par défaut, la valeur est `HEAD` du projet lorsqu'elle n'est pas spécifiée.
- Vous pouvez utiliser [certaines variables CI/CD](includes.md#use-variables-with-include).

**Exemple de `include:project`** :

```yaml
include:
  - project: 'my-group/my-project'
    file: '/templates/.gitlab-ci-template.yml'
  - project: 'my-group/my-subgroup/my-project-2'
    file:
      - '/templates/.builds.yml'
      - '/templates/.tests.yml'
```

Vous pouvez également spécifier un `ref` :

```yaml
include:
  - project: 'my-group/my-project'
    ref: main                                      # Git branch
    file: '/templates/.gitlab-ci-template.yml'
  - project: 'my-group/my-project'
    ref: v1.0.0                                    # Git Tag
    file: '/templates/.gitlab-ci-template.yml'
  - project: 'my-group/my-project'
    ref: 787123b47f14b552955ca2786bc9542ae66fee5b  # Git SHA
    file: '/templates/.gitlab-ci-template.yml'
```

**Informations complémentaires** :

- La configuration `include` est toujours évaluée en fonction de l'emplacement du fichier contenant le mot-clé `include`, et non du projet exécutant le pipeline. Si un [`include` imbriqué](includes.md#use-nested-includes) se trouve dans un fichier de configuration d'un autre projet, `include: local` recherche le fichier dans cet autre projet.
- Au démarrage du pipeline, la configuration du fichier `.gitlab-ci.yml` incluse par toutes les méthodes est évaluée. La configuration est un instantané dans le temps et est conservée dans la base de données. GitLab ne prend en compte aucune modification de la configuration du fichier `.gitlab-ci.yml` référencé jusqu'au démarrage du prochain pipeline.
- Pour tout projet privé dans `include:project`, l'utilisateur exécutant le pipeline doit disposer au minimum du rôle Reporter. Pour les projets internes, tout utilisateur authentifié non externe peut accéder aux fichiers inclus. Pour les projets publics, aucune adhésion n'est requise. Une erreur `not found or access denied` s'affiche si l'utilisateur ne dispose pas des autorisations suffisantes sur le projet inclus.
- Soyez prudent lorsque vous incluez le fichier de configuration CI/CD d'un autre projet. Aucun pipeline ni notification n'est déclenché lorsque les fichiers de configuration CI/CD changent. Du point de vue de la sécurité, cela est similaire à l'extraction d'une dépendance tierce. Pour `ref`, envisagez :
  - L'utilisation d'un hachage SHA spécifique, qui devrait être l'option la plus stable. Utilisez le hachage SHA complet de 40 caractères pour vous assurer que le commit souhaité est référencé, car l'utilisation d'un hachage SHA court pour `ref` peut être ambiguë.
  - L'application des règles de [branche protégée](../../user/project/repository/branches/protected.md) et de [tag protégé](../../user/project/protected_tags.md#prevent-tag-creation-with-branch-names) à `ref` dans l'autre projet. Les tags et branches protégés sont plus susceptibles de passer par un processus de gestion des changements avant d'être modifiés.

---

#### `include:remote` {#includeremote}

Utilisez `include:remote` avec une URL complète pour inclure un fichier à partir d'un emplacement différent.

**Type de mot-clé** : Mot-clé global.

**Valeurs prises en charge** :

Une URL publique accessible via une requête HTTP/HTTPS `GET` :

- L'authentification avec l'URL distante n'est pas prise en charge.
- Le fichier YAML doit avoir l'extension `.yml` ou `.yaml`.
- Vous pouvez utiliser [certaines variables CI/CD](includes.md#use-variables-with-include).

**Exemple de `include:remote`** :

```yaml
include:
  - remote: 'https://gitlab.com/example-project/-/raw/main/.gitlab-ci.yml'
```

**Informations complémentaires** :

- Toutes les [inclusions imbriquées](includes.md#use-nested-includes) sont exécutées sans contexte en tant qu'utilisateur public ; vous ne pouvez donc inclure que des projets ou des modèles publics. Aucune variable n'est disponible dans la section `include` des inclusions imbriquées.
- Soyez prudent lorsque vous incluez le fichier de configuration CI/CD d'un autre projet. Aucun pipeline ni notification n'est déclenché lorsque les fichiers de l'autre projet changent. Du point de vue de la sécurité, cela est similaire à l'extraction d'une dépendance tierce. Pour vérifier l'intégrité du fichier inclus, envisagez d'utiliser le mot-clé [`integrity`](#includeintegrity). Si vous créez un lien vers un autre projet GitLab que vous possédez, envisagez d'utiliser à la fois les [branches protégées](../../user/project/repository/branches/protected.md) et les [tags protégés](../../user/project/protected_tags.md#prevent-tag-creation-with-branch-names) pour appliquer des règles de gestion des changements.

---

#### `include:template` {#includetemplate}

Utilisez `include:template` pour inclure des [modèles `.gitlab-ci.yml`](https://gitlab.com/gitlab-org/gitlab/-/tree/master/lib/gitlab/ci/templates).

**Type de mot-clé** : Mot-clé global.

**Valeurs prises en charge** :

- Le nom de fichier d'un modèle CI/CD, par exemple `Auto-DevOps.gitlab-ci.yml`.
- Vous pouvez utiliser [certaines variables CI/CD](includes.md#use-variables-with-include).

**Exemple de `include:template`** :

```yaml
# File sourced from the GitLab template collection
include:
  - template: Auto-DevOps.gitlab-ci.yml
```

Plusieurs fichiers `include:template` :

```yaml
include:
  - template: Android-Fastlane.gitlab-ci.yml
  - template: Auto-DevOps.gitlab-ci.yml
```

**Informations complémentaires** :

- Tous les modèles peuvent être consultés dans [`lib/gitlab/ci/templates`](https://gitlab.com/gitlab-org/gitlab/-/tree/master/lib/gitlab/ci/templates). Tous les modèles ne sont pas conçus pour être utilisés avec `include:template`, vérifiez donc les commentaires du modèle avant de l'utiliser.
- Toutes les [inclusions imbriquées](includes.md#use-nested-includes) sont exécutées sans contexte en tant qu'utilisateur public ; vous ne pouvez donc inclure que des projets ou des modèles publics. Aucune variable n'est disponible dans la section `include` des inclusions imbriquées.

---

#### `include:inputs` {#includeinputs}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/391331) dans GitLab 15.11 en tant que fonctionnalité bêta.
- [En disponibilité générale](https://gitlab.com/gitlab-com/www-gitlab-com/-/merge_requests/134062) dans GitLab 17.0.

{{< /history >}}

Utilisez `include:inputs` pour définir les valeurs des paramètres d'entrée lorsque la configuration incluse utilise [`spec:inputs`](#specinputs) et est ajoutée au pipeline.

**Type de mot-clé** : Mot-clé global.

**Valeurs prises en charge** : Une chaîne de caractères, une valeur numérique ou un booléen.

**Exemple de `include:inputs`** :

```yaml
include:
  - local: 'custom_configuration.yml'
    inputs:
      website: "My website"
```

Dans cet exemple :

- La configuration contenue dans `custom_configuration.yml` est ajoutée au pipeline, avec une entrée `website` définie à la valeur `My website` pour la configuration incluse.

**Informations complémentaires** :

- Si le fichier de configuration inclus utilise [`spec:inputs:type`](#specinputstype), la valeur d'entrée doit correspondre au type défini.
- Si le fichier de configuration inclus utilise [`spec:inputs:options`](#specinputsoptions), la valeur d'entrée doit correspondre à l'une des options listées.

**Sujets connexes** :

- [Définir les valeurs d'entrée lors de l'utilisation de `include`](../inputs/_index.md#for-configuration-added-with-include).

---

#### `include:rules` {#includerules}

Vous pouvez utiliser [`rules`](#rules) avec `include` pour inclure conditionnellement d'autres fichiers de configuration.

**Type de mot-clé** : Mot-clé global.

**Valeurs prises en charge** : Ces sous-clés de `rules` :

- [`rules:if`](#rulesif).
- [`rules:exists`](#rulesexists).
- [`rules:changes`](#ruleschanges).

Certaines [variables CI/CD sont prises en charge](includes.md#use-variables-with-include).

**Exemple de `include:rules`** :

```yaml
include:
  - local: build_jobs.yml
    rules:
      - if: $INCLUDE_BUILDS == "true"

test-job:
  stage: test
  script: echo "This is a test job"
```

Dans cet exemple, si la variable `INCLUDE_BUILDS` est :

- `true`, la configuration `build_jobs.yml` est incluse dans le pipeline.
- Différente de `true` ou inexistante, la configuration `build_jobs.yml` n'est pas incluse dans le pipeline.

**Sujets connexes** :

- Exemples d'utilisation de `include` avec :
  - [`rules:if`](includes.md#include-with-rulesif).
  - [`rules:changes`](includes.md#include-with-ruleschanges).
  - [`rules:exists`](includes.md#include-with-rulesexists).

---

#### `include:integrity` {#includeintegrity}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/178593) dans GitLab 17.9.

{{< /history >}}

Utilisez `integrity` avec `include:remote` pour spécifier un hachage SHA256 du fichier distant inclus. Si `integrity` ne correspond pas au contenu réel, le fichier distant n'est pas traité et le pipeline échoue.

**Type de mot-clé** : Mot-clé global.

**Valeurs prises en charge** : Hachage SHA256 encodé en Base64 du contenu inclus.

**Exemple de `include:integrity`** :

```yaml
include:
  - remote: 'https://gitlab.com/example-project/-/raw/main/.gitlab-ci.yml'
    integrity: 'sha256-L3/GAoKaw0Arw6hDCKeKQlV1QPEgHYxGBHsH4zG1IY8='
```

---

#### `include:cache` {#includecache}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/351252) dans GitLab 18.9 en tant que [version expérimentale](../../policy/development_stages_support.md#experiment) avec un [feature flag](../../administration/feature_flags/_index.md) nommé `ci_cache_remote_includes`. Désactivé par défaut.
- [En disponibilité générale](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/235028) dans GitLab 19.0. Le feature flag `ci_cache_remote_includes` a été supprimé.

{{< /history >}}

Utilisez `cache` avec `include:remote` pour mettre en cache le contenu du fichier distant récupéré et réduire les requêtes HTTP. Lorsqu'il est activé, le fichier distant est mis en cache pendant une durée de vie (TTL) spécifiée, améliorant ainsi les performances du pipeline pour les configurations qui utilisent les mêmes inclusions distantes de manière répétée.

Évaluez le compromis entre les performances et la fraîcheur des données lors de la définition des durées de mise en cache. Des durées de mise en cache plus longues améliorent les performances, mais peuvent utiliser du contenu obsolète si le fichier distant change fréquemment.

Lorsque `cache` n'est pas défini, le fichier distant est récupéré à chaque fois.

**Type de mot-clé** : Mot-clé global.

**Valeurs prises en charge** :

- `true` : Activer la mise en cache avec une durée de vie (TTL) par défaut d'1 heure.
- Une durée (chaîne de caractères) : Les chaînes de durée TTL valides utilisent des unités de temps telles que `minutes`, `hours` ou `days` (minimum `1 minute`).

**Exemple de `include:cache`** :

```yaml
include:
  - remote: 'https://gitlab.com/example-project/-/raw/main/sample1.gitlab-ci.yml'
    cache: true
  - remote: 'https://gitlab.com/example-project/-/raw/main/sample2.gitlab-ci.yml'
    cache: '1 day'
```

**Informations complémentaires** :

- La mise en cache est uniquement disponible pour `include:remote`.
- Une fois le fichier distant mis en cache, la version mise en cache continue d'être utilisée jusqu'à l'expiration du TTL, même si le contenu du fichier distant change.
- Si vous utilisez [`integrity`](#includeintegrity) avec `cache`, la vérification d'intégrité est effectuée à chaque exécution du pipeline, même lors de l'utilisation du contenu mis en cache.

---

### `stages` {#stages}

Utilisez `stages` pour définir des étapes qui contiennent des groupes de jobs. Utilisez [`stage`](#stage) dans un job pour configurer son exécution dans une étape spécifique.

Si `stages` n'est pas défini dans le fichier `.gitlab-ci.yml`, les étapes par défaut du pipeline sont :

- [`.pre`](#stage-pre)
- `build`
- `test`
- `deploy`
- [`.post`](#stage-post)

L'ordre des éléments dans `stages` définit l'ordre d'exécution des jobs :

- Les jobs d'une même étape s'exécutent en parallèle.
- Les jobs de l'étape suivante s'exécutent une fois que les jobs de l'étape précédente se sont terminés avec succès.

Si un pipeline ne contient que des jobs dans les étapes `.pre` ou `.post`, il ne s'exécute pas. Il doit y avoir au moins un autre job dans une étape différente.

**Type de mot-clé** : Mot-clé global.

**Exemple de `stages`** :

```yaml
stages:
  - build
  - test
  - deploy
```

Dans cet exemple :

1. Tous les jobs dans `build` s'exécutent en parallèle.
1. Si tous les jobs dans `build` réussissent, les jobs `test` s'exécutent en parallèle.
1. Si tous les jobs dans `test` réussissent, les jobs `deploy` s'exécutent en parallèle.
1. Si tous les jobs dans `deploy` réussissent, le pipeline est marqué comme `passed`.

Si un job échoue, le pipeline est marqué comme `failed` et les jobs des étapes suivantes ne démarrent pas. Les jobs de l'étape en cours ne sont pas arrêtés et continuent de s'exécuter.

**Informations complémentaires** :

- Si un job ne spécifie pas d'[`stage`](#stage), le job est affecté à l'étape `test`.
- Si une étape est définie mais qu'aucun job ne l'utilise, l'étape n'est pas visible dans le pipeline, ce qui peut être utile pour les [configurations de pipelines de conformité](../../user/compliance/compliance_pipelines.md) :
  - Les étapes peuvent être définies dans la configuration de conformité, mais restent masquées si elles ne sont pas utilisées.
  - Les étapes définies deviennent visibles lorsque les développeurs les utilisent dans les définitions de jobs.

**Sujets connexes** :

- Pour qu'un job démarre plus tôt et ignore l'ordre des étapes, utilisez le mot-clé [`needs`](#needs).

---

### `workflow` {#workflow}

Utilisez [`workflow`](workflow.md) pour contrôler le comportement du pipeline.

Vous pouvez utiliser certaines [variables CI/CD prédéfinies](../variables/predefined_variables.md) dans la configuration `workflow`, mais pas les variables qui ne sont définies qu'au démarrage des jobs.

**Sujets connexes** :

- [Exemples de `workflow: rules`](workflow.md#workflow-rules-examples)
- [Basculer entre les pipelines de branche et les pipelines de merge request](workflow.md#switch-between-branch-pipelines-and-merge-request-pipelines)

---

#### `workflow:auto_cancel:on_new_commit` {#workflowauto_cancelon_new_commit}

Utilisez `workflow:auto_cancel:on_new_commit` pour configurer le comportement de la fonctionnalité d'[annulation automatique des pipelines redondants](../pipelines/settings.md#auto-cancel-redundant-pipelines).

**Valeurs prises en charge** :

- `conservative` : Annuler le pipeline, mais uniquement si aucun job avec `interruptible: false` n'a encore démarré. Valeur par défaut lorsqu'elle n'est pas définie.
- `interruptible` : Annuler uniquement les jobs avec `interruptible: true`.
- `none` : Ne pas annuler automatiquement les jobs.

**Exemple de `workflow:auto_cancel:on_new_commit`** :

```yaml
workflow:
  auto_cancel:
    on_new_commit: interruptible

job1:
  interruptible: true
  script: sleep 60

job2:
  interruptible: false  # Default when not defined.
  script: sleep 60
```

Dans cet exemple :

- Lorsqu'un nouveau commit est poussé vers une branche, GitLab crée un nouveau pipeline et `job1` et `job2` démarrent.
- Si un nouveau commit est poussé vers la branche avant la fin des jobs, seul `job1` est annulé.

---

#### `workflow:auto_cancel:on_job_failure` {#workflowauto_cancelon_job_failure}

Utilisez `workflow:auto_cancel:on_job_failure` pour configurer les jobs qui doivent être annulés dès qu'un job échoue.

**Valeurs prises en charge** :

- `all` : Annuler le pipeline et tous les jobs en cours dès qu'un job échoue.
- `none` : Ne pas annuler automatiquement les jobs.

**Exemple de `workflow:auto_cancel:on_job_failure`** :

```yaml
stages: [stage_a, stage_b]

workflow:
  auto_cancel:
    on_job_failure: all

job1:
  stage: stage_a
  script: sleep 60

job2:
  stage: stage_a
  script:
    - sleep 30
    - exit 1

job3:
  stage: stage_b
  script:
    - sleep 30
```

Dans cet exemple, si `job2` échoue, `job1` est annulé s'il est toujours en cours d'exécution et `job3` ne démarre pas.

**Sujets connexes** :

- [Annuler automatiquement le pipeline parent depuis un pipeline downstream](../pipelines/downstream_pipelines.md#auto-cancel-the-parent-pipeline-from-a-downstream-pipeline)

---

#### `workflow:name` {#workflowname}

Vous pouvez utiliser `name` dans `workflow:` pour définir un nom pour les pipelines.

Tous les pipelines reçoivent le nom défini. Les espaces en début et en fin de nom sont supprimés.

**Valeurs prises en charge** :

- Une chaîne de caractères.
- [Variables CI/CD](../variables/where_variables_can_be_used.md#gitlab-ciyml-file).
- Une combinaison des deux.

**Exemples de `workflow:name`** :

Un nom de pipeline simple avec une variable prédéfinie :

```yaml
workflow:
  name: 'Pipeline for branch: $CI_COMMIT_BRANCH'
```

Une configuration avec différents noms de pipeline en fonction des conditions du pipeline :

```yaml
variables:
  PROJECT1_PIPELINE_NAME: 'Default pipeline name'  # A default is not required

workflow:
  name: '$PROJECT1_PIPELINE_NAME'
  rules:
    - if: '$CI_MERGE_REQUEST_LABELS =~ /pipeline:run-in-ruby3/'
      variables:
        PROJECT1_PIPELINE_NAME: 'Ruby 3 pipeline'
    - if: '$CI_PIPELINE_SOURCE == "merge_request_event"'
      variables:
        PROJECT1_PIPELINE_NAME: 'MR pipeline: $CI_MERGE_REQUEST_SOURCE_BRANCH_NAME'
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH  # For default branch pipelines, use the default name
```

**Informations complémentaires** :

- Si le nom est une chaîne vide, aucun nom n'est attribué au pipeline. Un nom composé uniquement de variables CI/CD peut être évalué comme une chaîne vide si toutes les variables sont également vides.
- `workflow:rules:variables` devient des [variables par défaut](#default-variables) disponibles dans tous les jobs, y compris les jobs [`trigger`](#trigger) qui transmettent les variables aux pipelines downstream par défaut. Si le pipeline downstream utilise la même variable, la [variable est écrasée](../variables/_index.md#cicd-variable-precedence) par la valeur de la variable du pipeline upstream. Assurez-vous de :
  - Utiliser un nom de variable unique dans la configuration du pipeline de chaque projet, comme `PROJECT1_PIPELINE_NAME`.
  - Utiliser [`inherit:variables`](#inheritvariables) dans le job déclencheur et lister les variables exactes que vous souhaitez transmettre au pipeline downstream.

---

#### `workflow:rules` {#workflowrules}

Le mot-clé `rules` dans `workflow` est similaire aux [`rules` définis dans les jobs](#rules), mais contrôle si un pipeline entier est créé ou non.

Lorsqu'aucune règle n'est évaluée à true, le pipeline ne s'exécute pas.

**Valeurs prises en charge** : Vous pouvez utiliser certains des mêmes mots-clés que les [`rules`](#rules) au niveau du job :

- [`rules: if`](#rulesif).
- [`rules: changes`](#ruleschanges).
- [`rules: exists`](#rulesexists).
- [`when`](#when), peut uniquement être `always` ou `never` lorsqu'il est utilisé avec `workflow`.
- [`variables`](#workflowrulesvariables).

**Exemple de `workflow:rules`** :

```yaml
workflow:
  rules:
    - if: $CI_COMMIT_TITLE =~ /-draft$/
      when: never
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH
```

Dans cet exemple, les pipelines s'exécutent si le titre du commit (première ligne du message de commit) ne se termine pas par `-draft` et que le pipeline est destiné à :

- Une merge request
- La branche par défaut.

**Informations complémentaires** :

- Si vos règles correspondent à la fois aux pipelines de branche (autres que la branche par défaut) et aux pipelines de merge request, des [pipelines en double](../jobs/job_rules.md#avoid-duplicate-pipelines) peuvent se produire.
- `start_in`, `allow_failure` et `needs` ne sont pas pris en charge dans `workflow:rules`, mais ne causent pas d'erreur de syntaxe. Bien qu'ils n'aient aucun effet, ne les utilisez pas dans `workflow:rules` car cela pourrait causer des erreurs de syntaxe à l'avenir. Consultez le [ticket 436473](https://gitlab.com/gitlab-org/gitlab/-/issues/436473) pour plus de détails.

**Sujets connexes** :

- [Clauses `if` courantes pour `workflow:rules`](workflow.md#common-if-clauses-for-workflowrules).
- [Utiliser `rules` pour exécuter des pipelines de merge request](../pipelines/merge_request_pipelines.md#configure-merge-request-pipelines).

---

#### `workflow:rules:variables` {#workflowrulesvariables}

Vous pouvez utiliser [`variables`](#variables) dans `workflow:rules` pour définir des variables pour des conditions de pipeline spécifiques.

Lorsque la condition correspond, la variable est créée et peut être utilisée par tous les jobs du pipeline. Si la variable est déjà définie au niveau supérieur comme variable par défaut, la variable `workflow` est prioritaire et remplace la variable par défaut.

**Type de mot-clé** : Mot-clé global.

**Valeurs prises en charge** : Paires nom-valeur de variables :

- Le nom ne peut contenir que des chiffres, des lettres et des tirets bas (`_`).
- La valeur doit être une chaîne de caractères.

**Exemple de `workflow:rules:variables`** :

```yaml
variables:
  DEPLOY_VARIABLE: "default-deploy"

workflow:
  rules:
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH
      variables:
        DEPLOY_VARIABLE: "deploy-production"  # Override globally-defined DEPLOY_VARIABLE
    - if: $CI_COMMIT_BRANCH =~ /feature/
      variables:
        IS_A_FEATURE: "true"                  # Define a new variable.
    - if: $CI_COMMIT_BRANCH                   # Run the pipeline in other cases

job1:
  variables:
    DEPLOY_VARIABLE: "job1-default-deploy"
  rules:
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH
      variables:                                   # Override DEPLOY_VARIABLE defined
        DEPLOY_VARIABLE: "job1-deploy-production"  # at the job level.
    - when: on_success                             # Run the job in other cases
  script:
    - echo "Run script with $DEPLOY_VARIABLE as an argument"
    - echo "Run another script if $IS_A_FEATURE exists"

job2:
  script:
    - echo "Run script with $DEPLOY_VARIABLE as an argument"
    - echo "Run another script if $IS_A_FEATURE exists"
```

Lorsque la branche est la branche par défaut :

- La variable `DEPLOY_VARIABLE` de job1 est `job1-deploy-production`.
- La variable `DEPLOY_VARIABLE` de job2 est `deploy-production`.

Lorsque la branche est `feature` :

- La variable `DEPLOY_VARIABLE` de job1 est `job1-default-deploy`, et `IS_A_FEATURE` est `true`.
- La variable `DEPLOY_VARIABLE` de job2 est `default-deploy`, et `IS_A_FEATURE` est `true`.

Lorsque la branche est autre chose :

- La variable `DEPLOY_VARIABLE` de job1 est `job1-default-deploy`.
- La variable `DEPLOY_VARIABLE` de job2 est `default-deploy`.

**Informations complémentaires** :

- `workflow:rules:variables` devient des [variables par défaut](#variables) disponibles dans tous les jobs, y compris les jobs [`trigger`](#trigger) qui transmettent les variables aux pipelines downstream par défaut. Si le pipeline downstream utilise la même variable, la [variable est écrasée](../variables/_index.md#cicd-variable-precedence) par la valeur de la variable du pipeline upstream. Assurez-vous de :
  - Utiliser des noms de variables uniques dans la configuration du pipeline de chaque projet, comme `PROJECT1_VARIABLE_NAME`.
  - Utiliser [`inherit:variables`](#inheritvariables) dans le job déclencheur et lister les variables exactes que vous souhaitez transmettre au pipeline downstream.

---

#### `workflow:rules:auto_cancel` {#workflowrulesauto_cancel}

Utilisez `workflow:rules:auto_cancel` pour configurer le comportement de la fonctionnalité [`workflow:auto_cancel:on_new_commit`](#workflowauto_cancelon_new_commit) ou de la fonctionnalité [`workflow:auto_cancel:on_job_failure`](#workflowauto_cancelon_job_failure).

**Valeurs prises en charge** :

- `on_new_commit` : [`workflow:auto_cancel:on_new_commit`](#workflowauto_cancelon_new_commit)
- `on_job_failure` : [`workflow:auto_cancel:on_job_failure`](#workflowauto_cancelon_job_failure)

**Exemple de `workflow:rules:auto_cancel`** :

```yaml
workflow:
  auto_cancel:
    on_new_commit: interruptible
    on_job_failure: all
  rules:
    - if: $CI_COMMIT_REF_PROTECTED == 'true'
      auto_cancel:
        on_new_commit: none
        on_job_failure: none
    - when: always                  # Run the pipeline in other cases

test-job1:
  script: sleep 10
  interruptible: false

test-job2:
  script: sleep 10
  interruptible: true
```

Dans cet exemple, [`workflow:auto_cancel:on_new_commit`](#workflowauto_cancelon_new_commit) est défini sur `interruptible` et [`workflow:auto_cancel:on_job_failure`](#workflowauto_cancelon_job_failure) est défini sur `all` pour tous les jobs par défaut. Mais si un pipeline s'exécute pour une branche protégée, la règle remplace la valeur par défaut avec `on_new_commit: none` et `on_job_failure: none`. Par exemple, si un pipeline s'exécute pour :

- Une branche non protégée et qu'un nouveau commit est poussé, `test-job1` continue de s'exécuter et `test-job2` est annulé.
- Une branche protégée et qu'un nouveau commit est poussé, `test-job1` et `test-job2` continuent tous les deux de s'exécuter.

---

## Mots-clés d'en-tête {#header-keywords}

Certains mots-clés doivent être définis dans la section d'en-tête d'un fichier de configuration YAML. L'en-tête doit se trouver en haut du fichier, séparé du reste de la configuration par `---`.

---

### `spec` {#spec}

Ajoutez une section `spec` à l'en-tête d'un fichier YAML pour configurer le comportement d'un pipeline lorsqu'une configuration est ajoutée au pipeline avec le mot-clé `include`.

Les spécifications doivent être déclarées en haut d'un fichier de configuration, dans une section d'en-tête séparée du reste de la configuration par `---`.

---

#### `spec:inputs` {#specinputs}

Vous pouvez utiliser `spec:inputs` pour définir des [entrées](../inputs/_index.md) pour la configuration CI/CD.

Utilisez le format d'interpolation `$[[ inputs.input-id ]]` pour référencer les valeurs en dehors de la section d'en-tête. Les entrées sont évaluées et interpolées lors de la récupération de la configuration pendant la création du pipeline. Lors de l'utilisation de `inputs`, l'interpolation est effectuée avant que la configuration ne soit fusionnée avec le contenu du fichier `.gitlab-ci.yml`.

**Type de mot-clé** : Mot-clé d'en-tête. `spec` doit être déclaré en haut du fichier de configuration, dans une section d'en-tête.

**Valeurs prises en charge** : Un ensemble de chaînes de caractères représentant les entrées attendues.

**Exemple de `spec:inputs`** :

```yaml
spec:
  inputs:
    environment:
    job-stage:
---

scan-website:
  stage: $[[ inputs.job-stage ]]
  script: ./scan-website $[[ inputs.environment ]]
```

**Informations complémentaires** :

- Les entrées sont obligatoires, sauf si vous utilisez [`spec:inputs:default`](#specinputsdefault) pour définir une valeur par défaut. Évitez les entrées obligatoires, sauf si vous utilisez uniquement des entrées avec [`include:inputs`](#includeinputs).
- Les entrées attendent des chaînes de caractères, sauf si vous utilisez [`spec:inputs:type`](#specinputstype) pour définir un type d'entrée différent.
- Une chaîne de caractères contenant un bloc d'interpolation ne doit pas dépasser 1 Mo.
- La chaîne à l'intérieur d'un bloc d'interpolation ne doit pas dépasser 1 Ko.
- Vous pouvez définir des valeurs d'entrée [lors de l'exécution d'un nouveau pipeline](../inputs/_index.md#for-a-pipeline).

**Sujets connexes** :

- [Définir les paramètres d'entrée avec `spec:inputs`](../inputs/_index.md#define-input-parameters-with-specinputs).

---

##### `spec:inputs:default` {#specinputsdefault}

Les entrées sont obligatoires lors de leur inclusion, sauf si vous définissez une valeur par défaut avec `spec:inputs:default`.

Utilisez `default: ''` pour ne pas avoir de valeur par défaut.

**Type de mot-clé** : Mot-clé d'en-tête. `spec` doit être déclaré en haut du fichier de configuration, dans une section d'en-tête.

**Valeurs prises en charge** : Une chaîne de caractères représentant la valeur par défaut, ou `''`.

**Exemple de `spec:inputs:default`** :

```yaml
spec:
  inputs:
    website:
    user:
      default: 'test-user'
    flags:
      default: ''
---
# The pipeline configuration would follow...
```

Dans cet exemple :

- `website` est obligatoire et doit être défini.
- `user` est facultatif. Si non défini, la valeur est `test-user`.
- `flags` est facultatif. S'il n'est pas défini, il n'a aucune valeur.

**Informations complémentaires** :

- Le pipeline échoue avec une erreur de validation lorsque l'entrée :
  - Utilise à la fois `default` et [`options`](#specinputsoptions), mais la valeur par défaut ne fait pas partie des options listées.
  - Utilise à la fois `default` et `regex`, mais la valeur par défaut ne correspond pas à l'expression régulière.
  - La valeur ne correspond pas au [`type`](#specinputstype).

---

##### `spec:inputs:description` {#specinputsdescription}

Utilisez `description` pour donner une description à une entrée spécifique. La description n'affecte pas le comportement de l'entrée et sert uniquement à aider les utilisateurs du fichier à comprendre l'entrée.

**Type de mot-clé** : Mot-clé d'en-tête. `spec` doit être déclaré en haut du fichier de configuration, dans une section d'en-tête.

**Valeurs prises en charge** : Une chaîne de caractères représentant la description.

**Exemple de `spec:inputs:description`** :

```yaml
spec:
  inputs:
    flags:
      description: 'Sample description of the `flags` input details.'
---
# The pipeline configuration would follow...
```

---

##### `spec:inputs:options` {#specinputsoptions}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/393401) dans GitLab 16.6.
- La prise en charge des entrées de type tableau a été [introduite](https://gitlab.com/gitlab-org/gitlab/-/issues/566155) dans GitLab 19.0.

{{< /history >}}

Les entrées peuvent utiliser `options` pour spécifier une liste de valeurs autorisées pour une entrée. La limite est de 50 options par entrée.

**Type de mot-clé** : Mot-clé d'en-tête. `spec` doit être déclaré en haut du fichier de configuration, dans une section d'en-tête.

**Valeurs prises en charge** : Un tableau d'options d'entrée.

**Exemple de `spec:inputs:options`** :

```yaml
spec:
  inputs:
    environment:
      options:
        - development
        - staging
        - production
---
# The pipeline configuration would follow...
```

Dans cet exemple :

- `environment` est obligatoire et doit être défini avec l'une des valeurs de la liste.

**Informations complémentaires** :

- Le pipeline échoue avec une erreur de validation lorsque :
  - L'entrée utilise à la fois `options` et [`default`](#specinputsdefault), mais la valeur par défaut ne fait pas partie des options listées.
  - L'une des options d'entrée ne correspond pas au [`type`](#specinputstype), qui peut être `string` ou `number`, mais pas `boolean` lors de l'utilisation de `options`.

---

##### `spec:inputs:regex` {#specinputsregex}

Utilisez `spec:inputs:regex` pour spécifier une expression régulière à laquelle l'entrée doit correspondre.

**Type de mot-clé** : Mot-clé d'en-tête. `spec` doit être déclaré en haut du fichier de configuration, dans une section d'en-tête.

**Valeurs prises en charge** : Doit être une expression régulière.

**Exemple de `spec:inputs:regex`** :

```yaml
spec:
  inputs:
    version:
      regex: ^v\d\.\d+(\.\d+)?$
---
# The pipeline configuration would follow...
```

Dans cet exemple, les entrées `v1.0` ou `v1.2.3` correspondent à l'expression régulière et passent la validation. Une entrée de `v1.A.B` ne correspond pas à l'expression régulière et échoue à la validation.

**Informations complémentaires** :

- `inputs:regex` peut uniquement être utilisé avec un [`type`](#specinputstype) de `string`, pas `number` ni `boolean`.
- N'entourez pas l'expression régulière avec le caractère `/`. Par exemple, utilisez `regex.*`, et non `/regex.*/`.
- `inputs:regex` utilise [RE2](https://github.com/google/re2/wiki/Syntax) pour analyser les expressions régulières.
- La validation de l'entrée par rapport à l'expression régulière a lieu avant l'expansion des variables. Si le texte d'entrée contient un nom de variable, la valeur brute de l'entrée (le nom de la variable) est validée, et non la valeur de la variable.

---

##### `spec:inputs:rules` {#specinputsrules}

{{< history >}}

- [Introduites](https://gitlab.com/gitlab-org/gitlab/-/issues/582671) dans GitLab 18.7.

{{< /history >}}

Utilisez `spec:inputs:rules` pour définir des valeurs conditionnelles de `options` et de `default` pour une entrée en fonction des valeurs d'autres entrées.

**Type de mot-clé** : Mot-clé d'en-tête. `spec` doit être déclaré en haut du fichier de configuration, dans une section d'en-tête.

**Valeurs prises en charge** : Un tableau d'objets de règles. Chaque règle peut avoir :

- `if` : Une expression conditionnelle pour vérifier les valeurs d'entrée, en utilisant la [syntaxe `$[[ inputs.input-id ]]`](../inputs/_index.md#define-input-parameters-with-specinputs).
- `options` : Un tableau de valeurs autorisées pour l'entrée.
- `default` : La valeur par défaut de l'entrée lorsque cette règle correspond. Utilisez [`default: null`](../inputs/_index.md#allow-user-entered-values-with-default-null) pour permettre aux utilisateurs de saisir leur propre valeur pour l'entrée.

**Exemple de `spec:inputs:rules`** :

```yaml
spec:
  inputs:
    environment:
      options: ['development', 'production']
      default: 'development'

    instance_type:
      description: 'VM instance size'
      rules:
        - if: $[[ inputs.environment ]] == 'development'
          options: ['small', 'medium']
          default: 'small'
        - if: $[[ inputs.environment ]] == 'production'
          options: ['large', 'xlarge']
          default: 'large'
---

deploy:
  script: echo "Deploying $[[ inputs.instance_type ]] instance"
```

Dans cet exemple, lorsque `environment` est `development`, les utilisateurs ne peuvent sélectionner que des instances `small` ou `medium`. Lorsque `environment` est `production`, seules les instances `large` ou `xlarge` sont disponibles.

**Informations complémentaires** :

- Les règles sont évaluées dans l'ordre. La première règle avec une condition `if` correspondante est utilisée.
- Une règle sans condition `if` agit comme un repli lorsqu'aucune autre règle ne correspond.
- Les règles de repli doivent définir `options` avec au moins une valeur.
- Toutes les règles avec `options` doivent également définir une valeur `default` qui existe dans la liste `options`.
- Vous ne pouvez pas utiliser à la fois `rules` et `options` ou `default` de niveau supérieur pour la même entrée.

**Sujets connexes** :

- [Définir des options d'entrée conditionnelles avec `spec:inputs:rules`](../inputs/_index.md#define-conditional-input-options-with-specinputsrules).

---

##### `spec:inputs:type` {#specinputstype}

Par défaut, les entrées attendent des chaînes de caractères. Utilisez `spec:inputs:type` pour définir un type requis différent pour les entrées.

**Type de mot-clé** : Mot-clé d'en-tête. `spec` doit être déclaré en haut du fichier de configuration, dans une section d'en-tête.

**Valeurs prises en charge** : Peut être l'une des valeurs suivantes :

- `array`, pour accepter un [tableau](../inputs/_index.md#array-type) d'entrées.
- `string`, pour accepter des entrées de type chaîne de caractères (valeur par défaut lorsqu'il n'est pas défini).
- `number`, pour n'accepter que des entrées numériques.
- `boolean`, pour n'accepter que des entrées `true` ou `false`.

**Exemple de `spec:inputs:type`** :

```yaml
spec:
  inputs:
    job_name:
    website:
      type: string
    port:
      type: number
    available:
      type: boolean
    array_input:
      type: array
---
# The pipeline configuration would follow...
```

---

#### `spec:include` {#specinclude}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/206931) dans GitLab 18.6 [avec un indicateur](../../administration/feature_flags/_index.md) nommé `ci_file_inputs`. Désactivé par défaut.
- [En disponibilité générale](https://gitlab.com/gitlab-org/gitlab/-/issues/579240) dans GitLab 18.9. Le feature flag `ci_file_inputs` a été supprimé.

{{< /history >}}

Utilisez `spec:include` pour inclure des définitions d'entrées externes à partir d'autres fichiers. Vous pouvez partager et réutiliser des définitions d'entrées dans plusieurs configurations de pipeline.

**Type de mot-clé** : Mot-clé d'en-tête. `spec` doit être déclaré en haut du fichier de configuration, dans une section d'en-tête.

**Valeurs prises en charge** : Un tableau d'emplacements d'inclusion. Prend en charge uniquement les inclusions `local`, `remote` et `project`.

**Exemple de `spec:include`** :

```yaml
spec:
  include:
    - local: /shared-inputs.yml
  inputs:
    environment:
      default: production
---

deploy:
  script: echo "Deploying to $[[ inputs.environment ]]"
```

Avec plusieurs inclusions provenant de différentes sources :

```yaml
spec:
  include:
    - local: /base-inputs.yml
    - remote: 'https://example.com/ci/common-inputs.yml'
    - project: 'my-group/shared-configs'
      ref: main
      file: '/ci/team-inputs.yml'
  inputs:
    environment:
      default: production
---

deploy:
  script: echo "Deploying to $[[ inputs.environment ]]"
```

**Informations complémentaires** :

- Vous ne pouvez pas utiliser `spec:include` dans les [composants CI/CD](../components/_index.md#component-spec-section).
- Les fichiers d'entrées externes ne doivent contenir que la clé `inputs`. Les autres clés provoquent des erreurs de validation.
- Les entrées externes sont fusionnées en premier, puis les entrées en ligne sont appliquées.
- Les entrées en ligne ne peuvent pas avoir le même nom que les entrées incluses.
- Lorsque vous incluez plusieurs fichiers d'entrées, ils sont fusionnés dans l'ordre spécifié.
- Prend en charge les types d'inclusion [`local`](#includelocal), [`remote`](#includeremote) et [`project`](#includeproject). Ne prend pas en charge les inclusions `template`, `component` ou `artifact`.

**Sujets connexes** :

- [Utiliser des entrées provenant de fichiers externes](../inputs/_index.md#define-pipeline-inputs-in-external-files).

---

#### `spec:component` {#speccomponent}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/438275) dans GitLab 18.6 en tant que [bêta](../../policy/development_stages_support.md#beta) [avec un flag](../../administration/feature_flags/_index.md) nommé `ci_component_context_interpolation`. Activé par défaut.
- [En disponibilité générale](https://gitlab.com/gitlab-org/gitlab/-/issues/571986) dans GitLab 18.7. Le feature flag `ci_component_context_interpolation` a été supprimé.

{{< /history >}}

Utilisez `spec:component` pour définir quelles données de contexte du composant sont disponibles pour l'interpolation dans un [composant CI/CD](../components/_index.md).

Le contexte du composant fournit des métadonnées sur le composant lui-même, telles que son nom, sa version et le SHA du commit. Cela permet aux modèles de composants de référencer leurs propres métadonnées de manière dynamique.

Utilisez le format d'interpolation `$[[ component.field-name ]]` pour référencer les valeurs du contexte du composant dans le modèle de composant.

**Type de mot-clé** : Mot-clé d'en-tête. `spec` doit être déclaré en haut du fichier de configuration, dans une section d'en-tête.

**Valeurs prises en charge** : Un tableau de chaînes de caractères. Chaque chaîne doit être l'une des valeurs suivantes :

- `name` : Le nom du composant tel que spécifié dans le chemin du composant.
- `sha` : Le SHA du commit du composant.
- `version` : La version sémantique résolue à partir de la ressource du catalogue. Renvoie `null` si :
  - Le composant n'est pas une ressource du catalogue.
  - La référence est un nom de branche ou un SHA de commit (pas une version publiée).
- `reference` : La référence originale spécifiée après `@` dans le chemin du composant. Par exemple, `1.0`, `~latest`, un nom de branche ou un SHA de commit.

**Exemple de `spec:component`** :

```yaml
spec:
  component: [name, version, reference]
  inputs:
    stage:
      default: build
---

build-image:
  stage: $[[ inputs.stage ]]
  image: registry.example.com/$[[ component.name ]]:$[[ component.version ]]
  script:
    - echo "Building with component version $[[ component.version ]]"
    - echo "Component reference: $[[ component.reference ]]"
```

**Informations complémentaires** :

- Le champ `version` se résout en version sémantique réelle lors de l'utilisation de :
  - Une version complète comme `@1.0.0` (renvoie `1.0.0`)
  - Une version partielle comme `@1.0` (renvoie la dernière version correspondante, par exemple `1.0.2`)
  - `@~latest` (renvoie la dernière version)
- Le champ `reference` renvoie toujours la valeur exacte spécifiée après `@` :
  - `@1.0` renvoie `1.0` (tandis que `version` pourrait renvoyer `1.0.2`)
  - `@~latest` renvoie `~latest` (tandis que `version` renvoie le numéro de version réel)
  - `@abc123` renvoie `abc123` (tandis que `version` renvoie `null`)

**Sujets connexes** :

- [Utiliser le contexte de composant dans les composants](../components/_index.md#use-component-context-in-components).

---

#### `spec:description` {#specdescription}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/588286) dans GitLab 18.10.

{{< /history >}}

Utilisez `spec:description` pour fournir une brève description du composant. La description est affichée dans le catalogue CI/CD sur la page de détails du composant, au-dessus du tableau des entrées.

**Type de mot-clé** : Mot-clé d'en-tête. `spec` doit être déclaré en haut du fichier de configuration, dans une section d'en-tête.

**Valeurs prises en charge** : Une chaîne décrivant le composant.

**Exemple de `spec:description`** :

```yaml
spec:
  description: "A description of the component visible to users in the CI/CD Catalog."
  inputs:
    stage:
      default: test
---
scan-job:
  stage: $[[ inputs.stage ]]
  script: ./run-scan.sh
```

---

## Mots-clés de job {#job-keywords}

Les rubriques suivantes expliquent comment utiliser les mots-clés pour configurer des pipelines CI/CD.

---

### `after_script` {#after_script}

{{< history >}}

- L'exécution de commandes `after_script` pour les jobs annulés a été [introduite](https://gitlab.com/groups/gitlab-org/-/epics/10158) dans GitLab 17.0.

{{< /history >}}

Utilisez `after_script` pour définir un tableau de commandes à exécuter en dernier, après la fin des sections `before_script` et `script` d'un job. Les commandes `after_script` s'exécutent également lorsque :

- Le job est annulé pendant que les sections `before_script` ou `script` sont encore en cours d'exécution.
- Le job échoue avec un type d'échec `script_failure`, mais pas avec les [autres types d'échec](#retrywhen).

La configuration du job et la configuration par défaut ne sont pas fusionnées. Si le pipeline a [`default:after_script`](#default) défini, et que le job a également `after_script`, la configuration du job est prioritaire et la configuration par défaut n'est pas utilisée.

**Type de mot-clé** : Mot-clé de job. Vous pouvez l'utiliser uniquement dans un job ou dans la [section `default`](#default).

**Valeurs prises en charge** : Un tableau comprenant :

- Des commandes sur une seule ligne.
- Des commandes longues [réparties sur plusieurs lignes](script.md#split-long-commands).
- [Ancres YAML](yaml_optimization.md#yaml-anchors-for-scripts).

Les variables CI/CD [sont prises en charge](../variables/where_variables_can_be_used.md#gitlab-ciyml-file).

**Exemple de `after_script`** :

```yaml
job:
  script:
    - echo "An example script section."
  after_script:
    - echo "Execute this command after the `script` section completes."
```

**Informations complémentaires** :

Les scripts que vous spécifiez dans `after_script` s'exécutent dans un nouveau shell, séparé des commandes `before_script` ou `script`. En conséquence, ils :

- Ont le répertoire de travail courant réinitialisé à la valeur par défaut (selon les [variables qui définissent la manière dont le runner traite les requêtes Git](../runners/configure_runners.md#configure-runner-behavior-with-variables)).
- N'ont pas accès aux modifications apportées par les commandes définies dans `before_script` ou `script`, notamment :
  - Les alias de commandes et les variables exportés dans les scripts `script`.
  - Les modifications en dehors de l'arbre de travail (selon l'exécuteur du runner), comme les logiciels installés par un script `before_script` ou `script`.
- Disposent d'un délai d'expiration distinct. Pour GitLab Runner 16.4 et versions ultérieures, la valeur par défaut est 5 minutes et peut être configurée avec la variable [`RUNNER_AFTER_SCRIPT_TIMEOUT`](../runners/configure_runners.md#set-script-and-after_script-timeouts). Dans GitLab 16.3 et versions antérieures, le délai d'expiration est fixé à 5 minutes.
- N'affectent pas le code de sortie du job. Si la section `script` réussit et que `after_script` expire ou échoue, le job se termine avec le code `0` (`Job Succeeded`).
- Pour les jobs qui expirent :
  - Les commandes `after_script` ne s'exécutent pas par défaut.
  - Vous pouvez [configurer les valeurs de délai d'expiration](../runners/configure_runners.md#ensuring-after_script-execution) pour vous assurer que `after_script` s'exécute en définissant des valeurs appropriées pour `RUNNER_SCRIPT_TIMEOUT` et `RUNNER_AFTER_SCRIPT_TIMEOUT` qui ne dépassent pas le délai d'expiration du job.
- L'utilisation de `after_script` au niveau supérieur, mais pas dans la section `default`, est [dépréciée](deprecated_keywords.md#globally-defined-image-services-cache-before_script-after_script).

**Execution timing and file inclusion** :

Les commandes `after_script` s'exécutent avant les opérations de téléversement du cache et des artefacts.

- Si vous avez configuré la collecte d'artefacts :
  - Les fichiers créés ou modifiés dans `after_script` sont inclus dans les artefacts.
  - Les modifications apportées dans `after_script` sont incluses dans les téléversements du cache.
- Tous les fichiers que `after_script` crée ou modifie dans les chemins de cache ou d'artefacts spécifiés sont capturés et téléversés. Vous pouvez utiliser cette temporisation pour des scénarios tels que :
  - Génération de rapports de tests ou de données de couverture après le script principal.
  - Création de fichiers récapitulatifs ou de journaux.
  - Post-traitement des sorties de build.

Dans l'exemple suivant, les seuls fichiers non inclus sont ceux créés ou modifiés après les étapes de téléversement des artefacts ou du cache :

```yaml
job:
  script:
    - echo "main" > output.txt
    - build_something

  after_script:
    - echo "modified in after_script" >> output.txt  # This WILL be in the artifact
    - generate_test_report > report.html            # This WILL be in the artifact

  artifacts:
    paths:
      - output.txt
      - report.html

  cache:
    paths:
      - output.txt  # Will include the "modified in after_script" line
```

Pour plus d'informations, consultez [le flux d'exécution du job](../jobs/job_execution.md).

**Sujets connexes** :

- [Utilisez `after_script` avec `default`](script.md#set-a-default-before_script-or-after_script-for-all-jobs) pour définir un tableau de commandes par défaut à exécuter après tous les jobs.
- Vous pouvez configurer un job pour [ignorer les commandes `after_script` si le job est annulé](script.md#skip-after_script-commands-if-a-job-is-canceled).
- Vous pouvez [ignorer les codes de sortie non nuls](script.md#ignore-non-zero-exit-codes).
- [Utilisez des codes couleur avec `after_script`](script.md#add-color-codes-to-script-output) pour faciliter la révision des job logs.
- [Créez des sections repliables personnalisées](../jobs/job_logs.md#create-custom-collapsible-sections) pour simplifier la sortie du job log.
- Vous pouvez [ignorer les erreurs dans `after_script`](../runners/configure_runners.md#ignore-errors-in-after_script).

---

### `allow_failure` {#allow_failure}

Utilisez `allow_failure` pour déterminer si un pipeline doit continuer à s'exécuter lorsqu'un job échoue.

- Pour permettre au pipeline de continuer à exécuter les jobs suivants, utilisez `allow_failure: true`.
- Pour empêcher le pipeline d'exécuter les jobs suivants, utilisez `allow_failure: false`.

Lorsque les jobs sont autorisés à échouer (`allow_failure: true`), un avertissement orange ({{< icon name="status_warning" >}}) indique qu'un job a échoué. Cependant, le pipeline est réussi et le commit associé est marqué comme passé sans avertissement.

Ce même avertissement s'affiche lorsque :

- Tous les autres jobs de l'étape ont réussi.
- Tous les autres jobs du pipeline ont réussi.

La valeur par défaut de `allow_failure` est :

- `true` pour les [jobs manuels](../jobs/job_control.md#create-a-job-that-must-be-run-manually).
- `false` pour les jobs qui utilisent `when: manual` dans [`rules`](#rules).
- `false` dans tous les autres cas.

**Type de mot-clé** : Mot-clé de job. Vous pouvez l'utiliser uniquement dans un job.

**Valeurs prises en charge** :

- `true` ou `false`.

**Exemple de `allow_failure`** :

```yaml
job1:
  stage: test
  script:
    - execute_script_1

job2:
  stage: test
  script:
    - execute_script_2
  allow_failure: true

job3:
  stage: deploy
  script:
    - deploy_to_staging
  environment: staging
```

Dans cet exemple, `job1` et `job2` s'exécutent en parallèle :

- Si `job1` échoue, les jobs de l'étape `deploy` ne démarrent pas.
- Si `job2` échoue, les jobs de l'étape `deploy` peuvent tout de même démarrer.

**Informations complémentaires** :

- Vous pouvez utiliser `allow_failure` comme sous-clé de [`rules`](#rulesallow_failure).
- Si `allow_failure: true` est défini, le job est toujours considéré comme réussi, et les jobs ultérieurs avec [`when: on_failure`](#when) ne démarrent pas si ce job échoue.
- Vous pouvez utiliser `allow_failure: false` avec un job manuel pour créer un [job manuel bloquant](../jobs/job_control.md#types-of-manual-jobs). Un pipeline bloqué n'exécute aucun job dans les étapes ultérieures tant que le job manuel n'est pas démarré et terminé avec succès.

---

#### `allow_failure:exit_codes` {#allow_failureexit_codes}

Utilisez `allow_failure:exit_codes` pour contrôler quand un job est autorisé à échouer. Le job est `allow_failure: true` pour l'un des codes de sortie listés, et `allow_failure` false pour tout autre code de sortie.

**Type de mot-clé** : Mot-clé de job. Vous pouvez l'utiliser uniquement dans un job.

**Valeurs prises en charge** :

- Un code de sortie unique.
- Un tableau de codes de sortie.

**Exemple de `allow_failure`** :

```yaml
test_job_1:
  script:
    - echo "Run a script that results in exit code 1. This job fails."
    - exit 1
  allow_failure:
    exit_codes: 137

test_job_2:
  script:
    - echo "Run a script that results in exit code 137. This job is allowed to fail."
    - exit 137
  allow_failure:
    exit_codes:
      - 137
      - 255
```

---

### `artifacts` {#artifacts}

{{< history >}}

- [Mise à jour](https://gitlab.com/gitlab-org/gitlab-runner/-/merge_requests/5543) dans GitLab Runner 18.1. Lors du processus de mise en cache, les `symlinks` ne sont plus suivis, ce qui se produisait dans certains cas limites avec les versions précédentes de GitLab Runner.

{{< /history >}}

Utilisez `artifacts` pour spécifier les fichiers à enregistrer en tant qu'[artefacts de job](../jobs/job_artifacts.md). Les artefacts de job sont une liste de fichiers et de répertoires attachés au job lorsqu'il [réussit, échoue ou dans tous les cas](#artifactswhen).

Les artefacts sont envoyés à GitLab une fois le job terminé. Ils sont disponibles au téléchargement dans l'interface GitLab si leur taille est inférieure à la [taille maximale des artefacts](../../user/gitlab_com/_index.md#cicd).

Par défaut, les jobs des étapes ultérieures téléchargent automatiquement tous les artefacts créés par les jobs des étapes précédentes. Vous pouvez contrôler le comportement de téléchargement des artefacts dans les jobs avec [`dependencies`](#dependencies).

Lors de l'utilisation du mot-clé [`needs`](#needs), les jobs peuvent uniquement télécharger des artefacts à partir des jobs définis dans la configuration `needs`.

Les artefacts de job ne sont collectés que pour les jobs réussis par défaut, et les artefacts sont restaurés après les [caches](#cache).

La configuration du job et la configuration par défaut ne sont pas fusionnées. Si le pipeline a [`default:artifacts`](#default) défini, et que le job a également `artifacts`, la configuration du job est prioritaire et la configuration par défaut n'est pas utilisée.

[En savoir plus sur les artefacts](../jobs/job_artifacts.md).

---

#### `artifacts:paths` {#artifactspaths}

Les chemins sont relatifs au répertoire du projet (`$CI_PROJECT_DIR`) et ne peuvent pas pointer directement en dehors de celui-ci.

**Type de mot-clé** : Mot-clé de job. Vous pouvez l'utiliser uniquement dans un job ou dans la [section `default`](#default).

**Valeurs prises en charge** :

- Un tableau de chemins de fichiers, relatifs au répertoire du projet.
- Vous pouvez utiliser des caractères génériques avec des modèles [glob](https://en.wikipedia.org/wiki/Glob_(programming)) et [`doublestar.Glob`](https://pkg.go.dev/github.com/bmatcuk/doublestar@v1.2.2?tab=doc#Match).
- Pour les [jobs GitLab Pages](#pages) :
  - Dans [GitLab 17.10 et versions ultérieures](https://gitlab.com/gitlab-org/gitlab/-/issues/428018), le chemin [`pages.publish`](#pagespublish) est automatiquement ajouté à `artifacts:paths`, vous n'avez donc pas besoin de le spécifier à nouveau.
  - Dans [GitLab 17.10 et versions ultérieures](https://gitlab.com/gitlab-org/gitlab/-/issues/428018), lorsque le chemin [`pages.publish`](#pagespublish) n'est pas spécifié, le répertoire `public` est automatiquement ajouté à `artifacts:paths`.

Les variables CI/CD [sont prises en charge](../variables/where_variables_can_be_used.md#gitlab-ciyml-file).

**Exemple de `artifacts:paths`** :

```yaml
job:
  artifacts:
    paths:
      - binaries/
      - .config
```

Cet exemple crée un artefact avec `.config` et tous les fichiers du répertoire `binaries`.

**Informations complémentaires** :

- Si non utilisé avec [`artifacts:name`](#artifactsname), le fichier d'artefacts est nommé `artifacts`, ce qui devient `artifacts.zip` lors du téléchargement.

**Sujets connexes** :

- Pour restreindre les jobs à partir desquels un job spécifique récupère des artefacts, consultez [`dependencies`](#dependencies).
- [Créer des artefacts de job](../jobs/job_artifacts.md#create-job-artifacts).

---

#### `artifacts:exclude` {#artifactsexclude}

Utilisez `artifacts:exclude` pour empêcher l'ajout de fichiers dans une archive d'artefacts.

**Type de mot-clé** : Mot-clé de job. Vous pouvez l'utiliser uniquement dans un job ou dans la [section `default`](#default).

**Valeurs prises en charge** :

- Un tableau de chemins de fichiers, relatifs au répertoire du projet.
- Vous pouvez utiliser des caractères génériques avec des modèles [glob](https://en.wikipedia.org/wiki/Glob_(programming)) ou [`doublestar.PathMatch`](https://pkg.go.dev/github.com/bmatcuk/doublestar@v1.2.2?tab=doc#PathMatch).

**Exemple de `artifacts:exclude`** :

```yaml
artifacts:
  paths:
    - binaries/
  exclude:
    - binaries/**/*.o
```

Cet exemple stocke tous les fichiers dans `binaries/`, mais pas les fichiers `*.o` situés dans les sous-répertoires de `binaries/`.

**Informations complémentaires** :

- Les chemins `artifacts:exclude` ne font pas l'objet d'une recherche récursive.
- Les fichiers correspondant à [`artifacts:untracked`](#artifactsuntracked) peuvent également être exclus à l'aide de `artifacts:exclude`.

**Sujets connexes** :

- [Exclure des fichiers des artefacts de job](../jobs/job_artifacts.md#without-excluded-files).

---

#### `artifacts:expire_in` {#artifactsexpire_in}

Utilisez `expire_in` pour spécifier la durée de conservation des [artefacts de job](../jobs/job_artifacts.md) avant leur expiration et leur suppression. Le paramètre `expire_in` n'affecte pas :

- Les artefacts du dernier job, à moins que la conservation des artefacts du dernier job ne soit désactivée [au niveau du projet](../jobs/job_artifacts.md#keep-artifacts-from-most-recent-successful-jobs) ou [à l'échelle de l'instance](../../administration/settings/continuous_integration.md#keep-artifacts-from-latest-successful-pipelines).

Une fois expirés, les artefacts sont supprimés toutes les heures par défaut (via un job cron) et ne sont plus accessibles.

**Type de mot-clé** : Mot-clé de job. Vous pouvez l'utiliser uniquement dans un job ou dans la [section `default`](#default).

**Valeurs prises en charge** : La durée d'expiration. Si aucune unité n'est fournie, la durée est en secondes. Les valeurs valides comprennent :

- `'42'`
- `42 seconds`
- `3 mins 4 sec`
- `2 hrs 20 min`
- `2h20min`
- `6 mos 1 day`
- `47 yrs 6 mos and 4d`
- `3 weeks and 2 days`
- `never`

**Exemple de `artifacts:expire_in`** :

```yaml
job:
  artifacts:
    expire_in: 1 week
```

**Informations complémentaires** :

- La période d'expiration commence lorsque l'artefact est téléversé et stocké sur GitLab. Si la durée d'expiration n'est pas définie, elle utilise par défaut le [paramètre à l'échelle de l'instance](../../administration/settings/continuous_integration.md#set-default-artifacts-expiration).
- Pour remplacer la date d'expiration et protéger les artefacts d'une suppression automatique :
  - Sélectionnez **Garder** sur la page du job.
  - Définissez la valeur de `expire_in` sur `never`.
- Si la durée d'expiration est trop courte, les jobs des étapes ultérieures d'un long pipeline peuvent tenter de récupérer des artefacts expirés des jobs antérieurs. Si les artefacts sont expirés, les jobs qui tentent de les récupérer échouent avec une [erreur `could not retrieve the needed artifacts`](../jobs/job_artifacts_troubleshooting.md#error-message-this-job-could-not-start-because-it-could-not-retrieve-the-needed-artifacts). Augmentez la durée d'expiration, ou utilisez [`dependencies`](#dependencies) dans les jobs ultérieurs pour éviter qu'ils ne tentent de récupérer des artefacts expirés.
- `artifacts:expire_in` n'affecte pas les déploiements GitLab Pages. Pour configurer l'expiration des déploiements Pages, utilisez [`pages.expire_in`](#pagesexpire_in).

---

#### `artifacts:expose_as` {#artifactsexpose_as}

Utilisez le mot-clé `artifacts:expose_as` pour [exposer les artefacts dans l'interface des merge requests](../jobs/job_artifacts.md#link-to-job-artifacts-in-the-merge-request-ui).

**Type de mot-clé** : Mot-clé de job. Vous pouvez l'utiliser uniquement dans un job ou dans la [section `default`](#default).

**Valeurs prises en charge** :

- Le nom à afficher dans l'interface des merge requests pour le lien de téléchargement des artefacts. Doit être combiné avec [`artifacts:paths`](#artifactspaths).

**Exemple de `artifacts:expose_as`** :

```yaml
test:
  script: ["echo 'test' > file.txt"]
  artifacts:
    expose_as: 'artifact 1'
    paths: ['file.txt']
```

**Informations complémentaires** :

- Vous pouvez utiliser `expose_as` une seule fois par job, avec un maximum de 10 jobs par merge request.
- Les modèles glob ne sont pas pris en charge.
- Les artefacts sont toujours envoyés à GitLab. Ils sont affichés dans l'interface, sauf si les valeurs de `artifacts:paths` :
  - Utilisent des [variables CI/CD](../variables/_index.md).
  - Définissent un répertoire, mais ne se terminent pas par `/`. Par exemple, `directory/` fonctionne avec `artifacts:expose_as`, mais `directory` ne fonctionne pas.
- Si `artifacts:paths` ne comprend qu'un seul fichier, le lien ouvre directement le fichier. Dans tous les autres cas, le lien ouvre le [navigateur d'artefacts](../jobs/job_artifacts.md#download-job-artifacts).
- Les fichiers liés sont téléchargés par défaut. Si [GitLab Pages](../../administration/pages/_index.md) est activé, vous pouvez prévisualiser certains artefacts dont l'extension est prise en charge directement dans votre navigateur. Consultez [Parcourir le contenu de l'archive d'artefacts](../jobs/job_artifacts.md#browse-the-contents-of-the-artifacts-archive) pour plus de détails.

**Sujets connexes** :

- [Exposer les artefacts de job dans l'interface des merge requests](../jobs/job_artifacts.md#link-to-job-artifacts-in-the-merge-request-ui).

---

#### `artifacts:name` {#artifactsname}

Utilisez le mot-clé `artifacts:name` pour définir le nom de l'archive d'artefacts créée. Vous pouvez spécifier un nom unique pour chaque archive.

Si non défini, le nom par défaut est `artifacts`, ce qui devient `artifacts.zip` lors du téléchargement.

**Type de mot-clé** : Mot-clé de job. Vous pouvez l'utiliser uniquement dans un job ou dans la [section `default`](#default).

**Valeurs prises en charge** :

- Le nom de l'archive d'artefacts. Les variables CI/CD [sont prises en charge](../variables/where_variables_can_be_used.md#gitlab-ciyml-file). Doit être combiné avec [`artifacts:paths`](#artifactspaths).

**Exemple de `artifacts:name`** :

Pour créer une archive avec le nom du job en cours :

```yaml
job:
  artifacts:
    name: "job1-artifacts-file"
    paths:
      - binaries/
```

**Sujets connexes** :

- [Utiliser des variables CI/CD pour définir la configuration des artefacts](../jobs/job_artifacts.md#with-variable-expansion)

---

#### `artifacts:public` {#artifactspublic}

> [!note]
> `artifacts:public` est désormais remplacé par [`artifacts:access`](#artifactsaccess) qui offre davantage d'options.

Utilisez `artifacts:public` pour contrôler si les artefacts de job dans les pipelines publics sont disponibles au téléchargement via l'interface GitLab et l'API par les utilisateurs anonymes, ou par les rôles Guest et Reporter.

> [!warning]
> Cette option affecte uniquement l'accès via l'interface GitLab et l'API. Les jobs CI/CD utilisant des jetons de job peuvent toujours accéder aux artefacts via l'API du runner, quel que soit ce paramètre. Pour restreindre l'accès par jeton de job, configurez les [paramètres de visibilité CI/CD](../../user/project/settings/_index.md#configure-project-features-and-permissions) de votre projet sur **Uniquement les membres du projet**.

**Type de mot-clé** : Mot-clé de job. Vous pouvez l'utiliser uniquement dans un job ou dans la [section `default`](#default).

**Valeurs prises en charge** :

- `true` (par défaut) : Les artefacts d'un job dans les pipelines publics sont disponibles au téléchargement par n'importe qui, y compris les utilisateurs anonymes, ou les rôles Guest et Reporter.
- `false` : Les artefacts du job ne sont disponibles au téléchargement que pour les utilisateurs ayant le rôle Developer, Maintainer ou Owner.

**Exemple de `artifacts:public`** :

```yaml
job:
  artifacts:
    public: false
```

---

#### `artifacts:access` {#artifactsaccess}

{{< history >}}

- L'option `maintainer` a été [introduite](https://gitlab.com/gitlab-org/gitlab/-/issues/454398) dans GitLab 18.4.

{{< /history >}}

Utilisez `artifacts:access` pour déterminer qui peut accéder aux artefacts de job via l'interface GitLab ou l'API. Cette option ne vous empêche pas de transmettre des artefacts aux pipelines downstream.

Vous ne pouvez pas utiliser [`artifacts:public`](#artifactspublic) et `artifacts:access` dans le même job.

> [!warning]
> Cette option affecte uniquement l'accès via l'interface GitLab et l'API. Les jobs CI/CD utilisant des jetons de job peuvent toujours accéder aux artefacts via l'API du runner, quel que soit ce paramètre. Pour restreindre l'accès par jeton de job, configurez les [paramètres de visibilité CI/CD](../../user/project/settings/_index.md#configure-project-features-and-permissions) de votre projet sur **Uniquement les membres du projet**.

**Type de mot-clé** : Mot-clé de job. Vous pouvez l'utiliser uniquement dans un job.

**Valeurs prises en charge** :

- `all` (par défaut) : Les artefacts d'un job dans les pipelines publics sont disponibles au téléchargement par n'importe qui, y compris les utilisateurs anonymes, invités et reporters.
- `developer` : Les artefacts du job ne sont disponibles au téléchargement que pour les utilisateurs ayant le rôle Developer, Maintainer ou Owner.
- `maintainer` : Les artefacts du job ne sont disponibles au téléchargement que pour les utilisateurs ayant le rôle Maintainer ou Owner.
- `none` : Les artefacts du job ne sont disponibles au téléchargement pour personne.

**Exemple de `artifacts:access`** :

```yaml
job:
  artifacts:
    access: 'developer'
```

**Informations complémentaires** :

- `artifacts:access` affecte également tous les [`artifacts:reports`](#artifactsreports), vous pouvez donc également restreindre l'accès aux [artefacts pour les rapports](artifacts_reports.md).

---

#### `artifacts:reports` {#artifactsreports}

Utilisez [`artifacts:reports`](artifacts_reports.md) pour collecter les artefacts générés par les modèles inclus dans les jobs.

**Type de mot-clé** : Mot-clé de job. Vous pouvez l'utiliser uniquement dans un job ou dans la [section `default`](#default).

**Valeurs prises en charge** :

- Consultez la liste des [types de rapports d'artefacts](artifacts_reports.md) disponibles.

**Exemple de `artifacts:reports`** :

```yaml
rspec:
  stage: test
  script:
    - bundle install
    - rspec --format RspecJunitFormatter --out rspec.xml
  artifacts:
    reports:
      junit: rspec.xml
```

**Informations complémentaires** :

- La combinaison de rapports dans les pipelines parents à l'aide des [artefacts des pipelines enfants](#needspipelinejob) n'est pas prise en charge. Pour plus d'informations, consultez l'[epic 8205](https://gitlab.com/groups/gitlab-org/-/work_items/8205).
- Pour pouvoir parcourir et télécharger les fichiers de sortie de rapport, incluez le mot-clé [`artifacts:paths`](#artifactspaths). L'artefact est ainsi téléversé et stocké deux fois.
- Les artefacts créés pour `artifacts: reports` sont toujours téléversés, quels que soient les résultats du job (succès ou échec). Vous pouvez utiliser [`artifacts:expire_in`](#artifactsexpire_in) pour définir une date d'expiration pour les artefacts.

---

#### `artifacts:untracked` {#artifactsuntracked}

Utilisez `artifacts:untracked` pour ajouter tous les fichiers Git non suivis en tant qu'artefacts (en plus des chemins définis dans `artifacts:paths`). `artifacts:untracked` ignore la configuration du fichier `.gitignore` du dépôt, de sorte que les artefacts correspondants dans `.gitignore` sont inclus.

**Type de mot-clé** : Mot-clé de job. Vous pouvez l'utiliser uniquement dans un job ou dans la [section `default`](#default).

**Valeurs prises en charge** :

- `true` ou `false` (par défaut si non défini).

**Exemple de `artifacts:untracked`** :

Enregistrer tous les fichiers Git non suivis :

```yaml
job:
  artifacts:
    untracked: true
```

**Sujets connexes** :

- [Ajouter des fichiers non suivis aux artefacts](../jobs/job_artifacts.md#with-untracked-files).

---

#### `artifacts:when` {#artifactswhen}

Utilisez `artifacts:when` pour téléverser des artefacts en cas d'échec du job ou malgré l'échec.

**Type de mot-clé** : Mot-clé de job. Vous pouvez l'utiliser uniquement dans un job ou dans la [section `default`](#default).

**Valeurs prises en charge** :

- `on_success` (par défaut) : Téléverser les artefacts uniquement lorsque le job réussit.
- `on_failure` : Téléverser les artefacts uniquement lorsque le job échoue.
- `always` : Toujours téléverser les artefacts (sauf lorsque les jobs expirent). Par exemple, lors du [téléversement d'artefacts](../testing/unit_test_reports.md#add-screenshots-to-test-reports) nécessaires au dépannage de tests qui échouent.

**Exemple de `artifacts:when`** :

```yaml
job:
  artifacts:
    when: on_failure
```

**Informations complémentaires** :

- Les artefacts créés pour [`artifacts:reports`](#artifactsreports) sont toujours téléversés, quels que soient les résultats du job (succès ou échec). `artifacts:when` ne modifie pas ce comportement.

---

### `before_script` {#before_script}

Utilisez `before_script` pour définir un tableau de commandes à exécuter avant les commandes `script` de chaque job, mais après la restauration des [artefacts](#artifacts).

**Type de mot-clé** : Mot-clé de job. Vous pouvez l'utiliser uniquement dans un job ou dans la [section `default`](#default).

**Valeurs prises en charge** : Un tableau comprenant :

- Des commandes sur une seule ligne.
- Des commandes longues [réparties sur plusieurs lignes](script.md#split-long-commands).
- [Ancres YAML](yaml_optimization.md#yaml-anchors-for-scripts).

Les variables CI/CD [sont prises en charge](../variables/where_variables_can_be_used.md#gitlab-ciyml-file).

**Exemple de `before_script`** :

```yaml
job:
  before_script:
    - echo "Execute this command before any 'script:' commands."
  script:
    - echo "This command executes after the job's 'before_script' commands."
```

**Informations complémentaires** :

- Les scripts que vous spécifiez dans `before_script` sont concaténés avec les scripts que vous spécifiez dans le [`script`](#script) principal. Les scripts combinés s'exécutent ensemble dans un seul shell.
- L'utilisation de `before_script` au niveau supérieur, mais pas dans la section `default`, est [dépréciée](deprecated_keywords.md#globally-defined-image-services-cache-before_script-after_script).

**Sujets connexes** :

- [Utilisez `before_script` avec `default`](script.md#set-a-default-before_script-or-after_script-for-all-jobs) pour définir un tableau de commandes par défaut à exécuter avant les commandes `script` dans tous les jobs.
  - La configuration du job et la configuration par défaut ne sont pas fusionnées. Si le pipeline a [`default:before_script`](#default) défini, et que le job a également `before_script`, la configuration du job est prioritaire et la configuration par défaut n'est pas utilisée.
- Vous pouvez [ignorer les codes de sortie non nuls](script.md#ignore-non-zero-exit-codes).
- [Utilisez des codes couleur avec `before_script`](script.md#add-color-codes-to-script-output) pour faciliter la révision des job logs.
- [Créez des sections repliables personnalisées](../jobs/job_logs.md#create-custom-collapsible-sections) pour simplifier la sortie du job log.

---

### `cache` {#cache}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/330047) dans GitLab 15.0, les caches ne sont pas partagés entre les branches protégées et non protégées.
- [Mise à jour](https://gitlab.com/gitlab-org/gitlab-runner/-/merge_requests/5543) dans GitLab Runner 18.1. Lors du processus de mise en cache, les `symlinks` ne sont plus suivis, ce qui se produisait dans certains cas limites avec les versions précédentes de GitLab Runner.

{{< /history >}}

Utilisez `cache` pour spécifier une liste de fichiers et de répertoires à mettre en cache entre les jobs. Vous pouvez uniquement utiliser des chemins situés dans la copie de travail locale.

Les caches sont :

- Partagés entre les pipelines et les jobs.
- Par défaut, non partagés entre les branches [protégées](../../user/project/repository/branches/protected.md) et non protégées.
- Restaurés avant les [artefacts](#artifacts).
- Limités à un maximum de quatre [caches différents](../caching/_index.md#use-multiple-caches).

Vous pouvez [désactiver la mise en cache pour des jobs spécifiques](../caching/_index.md#disable-cache-for-specific-jobs), par exemple pour remplacer :

- Un cache par défaut défini avec [`default`](#default).
- La configuration d'un job ajouté avec [`include`](#include).

La configuration du job et la configuration par défaut ne sont pas fusionnées. Si le pipeline a [`default:cache`](#default) défini, et que le job a également `cache`, la configuration du job est prioritaire et la configuration par défaut n'est pas utilisée.

Pour plus d'informations sur les caches, consultez [Mise en cache dans GitLab CI/CD](../caching/_index.md).

L'utilisation de `cache` au niveau supérieur, mais pas dans la section `default`, est [dépréciée](deprecated_keywords.md#globally-defined-image-services-cache-before_script-after_script).

---

#### `cache:paths` {#cachepaths}

Utilisez le mot-clé `cache:paths` pour choisir les fichiers ou répertoires à mettre en cache.

**Type de mot-clé** : Mot-clé de job. Vous pouvez l'utiliser uniquement dans un job ou dans la [section `default`](#default).

**Valeurs prises en charge** :

- Un tableau de chemins relatifs au répertoire du projet (`$CI_PROJECT_DIR`). Vous pouvez utiliser des caractères génériques avec des modèles [glob](https://en.wikipedia.org/wiki/Glob_(programming)) et [`doublestar.Glob`](https://pkg.go.dev/github.com/bmatcuk/doublestar@v1.2.2?tab=doc#Match).

Les [variables CI/CD](../variables/where_variables_can_be_used.md#gitlab-ciyml-file) sont prises en charge.

**Exemple de `cache:paths`** :

Mettre en cache tous les fichiers dans `binaries` se terminant par `.apk` et le fichier `.config` :

```yaml
rspec:
  script:
    - echo "This job uses a cache."
  cache:
    key: binaries-cache
    paths:
      - binaries/*.apk
      - .config
```

**Informations complémentaires** :

- Le mot-clé `cache:paths` inclut les fichiers même s'ils ne sont pas suivis ou s'ils figurent dans votre fichier `.gitignore`.

**Sujets connexes** :

- Consultez les [exemples de mise en cache CI/CD](../caching/examples.md) pour plus d'exemples de `cache:paths`.

---

#### `cache:key` {#cachekey}

Utilisez le mot-clé `cache:key` pour attribuer une clé d'identification unique à chaque cache. Tous les jobs qui utilisent la même clé de cache utilisent le même cache, y compris dans différents pipelines.

Si non définie, la clé par défaut est `default`. Tous les jobs avec le mot-clé `cache` mais sans `cache:key` partagent le cache `default`.

Doit être utilisé avec `cache: paths`, sinon rien n'est mis en cache.

**Type de mot-clé** : Mot-clé de job. Vous pouvez l'utiliser uniquement dans un job ou dans la [section `default`](#default).

**Valeurs prises en charge** :

- Une chaîne de caractères.
- Une [variable CI/CD](../variables/where_variables_can_be_used.md#gitlab-ciyml-file) prédéfinie.
- Une combinaison des deux.

**Exemple de `cache:key`** :

```yaml
cache-job:
  script:
    - echo "This job uses a cache."
  cache:
    key: binaries-cache-$CI_COMMIT_REF_SLUG
    paths:
      - binaries/
```

**Informations complémentaires** :

- Si vous utilisez **Windows Batch** pour exécuter vos scripts shell, vous devez remplacer `$` par `%`. Par exemple : `key: %CI_COMMIT_REF_SLUG%`
- La valeur de `cache:key` ne peut pas contenir :
  - Le caractère `/`, ou son équivalent encodé en URI `%2F`.
  - Uniquement le caractère `.` (quel qu'en soit le nombre), ou son équivalent encodé en URI `%2E`.
- Le cache étant partagé entre les jobs, si vous utilisez des chemins différents pour différents jobs, vous devriez également définir un `cache:key` différent. Sinon, le contenu du cache peut être écrasé.

**Sujets connexes** :

- Vous pouvez spécifier une [clé de cache de secours](../caching/_index.md#use-a-fallback-cache-key) à utiliser si le `cache:key` spécifié est introuvable.
- Vous pouvez [utiliser plusieurs clés de cache](../caching/_index.md#use-multiple-caches) dans un seul job.
- Consultez les [exemples de mise en cache CI/CD](../caching/examples.md) pour plus d'exemples de `cache:key`.

---

##### `cache:key:files` {#cachekeyfiles}

Utilisez `cache:key:files` pour générer une nouvelle clé de cache lorsque le contenu des fichiers spécifiés change. Si le contenu reste inchangé, la clé de cache reste cohérente entre les branches et les pipelines. Vous pouvez réutiliser les caches et les reconstruire moins souvent, ce qui accélère les exécutions ultérieures du pipeline.

**Type de mot-clé** : Mot-clé de job. Vous pouvez l'utiliser uniquement dans un job ou dans la [section `default`](#default).

**Valeurs prises en charge** :

- Un tableau d'au maximum deux chemins ou modèles de fichiers.

Les variables CI/CD ne sont pas prises en charge.

**Exemple de `cache:key:files`** :

```yaml
cache-job:
  script:
    - echo "This job uses a cache."
  cache:
    key:
      files:
        - Gemfile.lock
        - package.json
    paths:
      - vendor/ruby
      - node_modules
```

Cet exemple crée un cache pour les dépendances Ruby et Node.js. Le cache est lié aux versions actuelles des fichiers `Gemfile.lock` et `package.json`. Lorsque l'un de ces fichiers change, une nouvelle clé de cache est calculée et un nouveau cache est créé. Toutes les futures exécutions de jobs qui utilisent les mêmes `Gemfile.lock` et `package.json` avec `cache:key:files` utilisent le nouveau cache, au lieu de reconstruire les dépendances.

**Informations complémentaires** :

- La `key` du cache est un SHA calculé à partir du contenu des fichiers listés. Si un fichier n'existe pas, il est ignoré dans le calcul de la clé. Si aucun des fichiers spécifiés n'existe, la clé de secours est `default`.
- Des modèles avec caractères génériques comme `**/package.json` peuvent être utilisés.
- Un maximum de deux fichiers peut être spécifié. Pour les mises à jour concernant l'augmentation du nombre de chemins ou de modèles autorisés, consultez le [ticket 301161](https://gitlab.com/gitlab-org/gitlab/-/work_items/301161).

---

##### `cache:key:files_commits` {#cachekeyfiles_commits}

Utilisez `cache:key:files_commits` pour générer une nouvelle clé de cache lorsque le dernier commit change pour les fichiers spécifiés. Les clés de cache `cache:key:files_commits` changent chaque fois que les fichiers spécifiés font l'objet d'un nouveau commit, même si le contenu du fichier reste identique.

**Type de mot-clé** : Mot-clé de job. Vous pouvez l'utiliser uniquement dans un job ou dans la [section `default`](#default).

**Valeurs prises en charge** :

- Un tableau d'au maximum deux chemins ou modèles de fichiers.

**Exemple de `cache:key:files_commits`** :

```yaml
cache-job:
  script:
    - echo "This job uses a commit-based cache."
  cache:
    key:
      files_commits:
        - package.json
        - yarn.lock
    paths:
      - node_modules
```

Cet exemple crée un cache basé sur l'historique des commits de `package.json` et `yarn.lock`. Si l'historique des commits de ces fichiers change, une nouvelle clé de cache est calculée et un nouveau cache est créé.

**Informations complémentaires** :

- La `key` du cache est un SHA calculé à partir du commit le plus récent pour chaque fichier spécifié.
- Si un fichier n'existe pas, il est ignoré dans le calcul de la clé.
- Si aucun des fichiers spécifiés n'existe, la clé de secours est `default`.
- Ne peut pas être utilisé conjointement avec [`cache:key:files`](#cachekeyfiles) dans la même configuration de cache.

---

##### `cache:key:prefix` {#cachekeyprefix}

Utilisez `cache:key:prefix` pour combiner un préfixe avec le SHA calculé pour [`cache:key:files`](#cachekeyfiles).

**Type de mot-clé** : Mot-clé de job. Vous pouvez l'utiliser uniquement dans un job ou dans la [section `default`](#default).

**Valeurs prises en charge** :

- Une chaîne de caractères.
- Une [variable CI/CD](../variables/where_variables_can_be_used.md#gitlab-ciyml-file) prédéfinie.
- Une combinaison des deux.

**Exemple de `cache:key:prefix`** :

```yaml
rspec:
  script:
    - echo "This rspec job uses a cache."
  cache:
    key:
      files:
        - Gemfile.lock
      prefix: $CI_JOB_NAME
    paths:
      - vendor/ruby
```

Par exemple, l'ajout d'un `prefix` avec la valeur `$CI_JOB_NAME` donne une clé du type `rspec-feef9576d21ee9b6a32e30c5c79d0a0ceb68d1e5`. Si une branche modifie `Gemfile.lock`, cette branche dispose d'un nouveau checksum SHA pour `cache:key:files`. Une nouvelle clé de cache est générée et un nouveau cache est créé pour cette clé. Si `Gemfile.lock` est introuvable, le préfixe est ajouté à `default`, de sorte que la clé dans l'exemple serait `rspec-default`.

**Informations complémentaires** :

- Si aucun fichier dans `cache:key:files` n'est modifié dans aucun commit, le préfixe est ajouté à la clé `default`.

---

#### `cache:untracked` {#cacheuntracked}

Utilisez `untracked: true` pour mettre en cache tous les fichiers non suivis dans votre dépôt Git. Les fichiers non suivis comprennent les fichiers qui sont :

- Ignorés en raison de la [configuration `.gitignore`](https://git-scm.com/docs/gitignore).
- Créés, mais non ajoutés au checkout avec [`git add`](https://git-scm.com/docs/git-add).

La mise en cache des fichiers non suivis peut créer des caches de taille inattendue si le job télécharge :

- Des dépendances, comme des gems ou des modules node, qui sont généralement non suivis.
- Des [artefacts](#artifacts) d'un autre job. Les fichiers extraits des artefacts ne sont pas suivis par défaut.

**Type de mot-clé** : Mot-clé de job. Vous pouvez l'utiliser uniquement dans un job ou dans la [section `default`](#default).

**Valeurs prises en charge** :

- `true` ou `false` (par défaut).

**Exemple de `cache:untracked`** :

```yaml
rspec:
  script: test
  cache:
    untracked: true
```

**Informations complémentaires** :

- Vous pouvez combiner `cache:untracked` avec `cache:paths` pour mettre en cache tous les fichiers non suivis, ainsi que les fichiers dans les chemins configurés. Utilisez `cache:paths` pour mettre en cache des fichiers spécifiques, y compris les fichiers suivis ou les fichiers en dehors du répertoire de travail, et utilisez `cache: untracked` pour mettre également en cache tous les fichiers non suivis. Par exemple :

  ```yaml
  rspec:
    script: test
    cache:
      untracked: true
      paths:
        - binaries/
  ```

  Dans cet exemple, le job met en cache tous les fichiers non suivis du dépôt, ainsi que tous les fichiers dans `binaries/`. Si des fichiers non suivis se trouvent dans `binaries/`, ils sont couverts par les deux mots-clés.

---

#### `cache:unprotect` {#cacheunprotect}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/362114) dans GitLab 15.8.

{{< /history >}}

Utilisez `cache:unprotect` pour configurer un cache partagé entre les branches [protégées](../../user/project/repository/branches/protected.md) et non protégées.

> [!warning]
> Lorsque cette option est définie sur `true`, les utilisateurs sans accès aux branches protégées peuvent lire et écrire dans les clés de cache utilisées par les branches protégées.

**Type de mot-clé** : Mot-clé de job. Vous pouvez l'utiliser uniquement dans un job ou dans la [section `default`](#default).

**Valeurs prises en charge** :

- `true` ou `false` (par défaut).

**Exemple de `cache:unprotect`** :

```yaml
rspec:
  script: test
  cache:
    unprotect: true
```

---

#### `cache:when` {#cachewhen}

Utilisez `cache:when` pour définir quand enregistrer le cache, en fonction du statut du job.

Doit être utilisé avec `cache: paths`, sinon rien n'est mis en cache.

**Type de mot-clé** : Mot-clé de job. Vous pouvez l'utiliser uniquement dans un job ou dans la [section `default`](#default).

**Valeurs prises en charge** :

- `on_success` (par défaut) : Enregistrer le cache uniquement lorsque le job réussit.
- `on_failure` : Enregistrer le cache uniquement lorsque le job échoue.
- `always` : Toujours enregistrer le cache.

**Exemple de `cache:when`** :

```yaml
rspec:
  script: rspec
  cache:
    paths:
      - rspec/
    when: 'always'
```

Cet exemple stocke le cache que le job échoue ou réussisse.

---

#### `cache:policy` {#cachepolicy}

Pour modifier le comportement de téléchargement et de téléversement d'un cache, utilisez le mot-clé `cache:policy`. Par défaut, le job télécharge le cache au démarrage du job et téléverse les modifications du cache à la fin du job. Ce style de mise en cache est la politique `pull-push` (par défaut).

Pour configurer un job afin qu'il télécharge uniquement le cache au démarrage du job, mais ne téléverse jamais de modifications à la fin du job, utilisez `cache:policy:pull`.

Pour configurer un job afin qu'il téléverse uniquement un cache à la fin du job, mais ne télécharge jamais le cache au démarrage du job, utilisez `cache:policy:push`.

Utilisez la politique `pull` lorsque de nombreux jobs s'exécutent en parallèle et utilisent le même cache. Cette politique accélère l'exécution des jobs et réduit la charge sur le serveur de cache. Vous pouvez utiliser un job avec la politique `push` pour construire le cache.

Doit être utilisé avec `cache: paths`, sinon rien n'est mis en cache.

**Type de mot-clé** : Mot-clé de job. Vous pouvez l'utiliser uniquement dans un job ou dans la [section `default`](#default).

**Valeurs prises en charge** :

- `pull`
- `push`
- `pull-push` (par défaut)
- [Variables CI/CD](../variables/where_variables_can_be_used.md#gitlab-ciyml-file).

**Exemple de `cache:policy`** :

```yaml
prepare-dependencies-job:
  stage: build
  cache:
    key: gems
    paths:
      - vendor/bundle
    policy: push
  script:
    - echo "This job only downloads dependencies and builds the cache."
    - echo "Downloading dependencies..."

faster-test-job:
  stage: test
  cache:
    key: gems
    paths:
      - vendor/bundle
    policy: pull
  script:
    - echo "This job script uses the cache, but does not update it."
    - echo "Running tests..."
```

**Sujets connexes** :

- Vous pouvez [utiliser une variable pour contrôler la politique de cache d'un job](../caching/examples.md#use-a-variable-to-control-a-jobs-cache-policy).

---

#### `cache:fallback_keys` {#cachefallback_keys}

Utilisez `cache:fallback_keys` pour spécifier une liste de clés à partir desquelles tenter de restaurer le cache si aucun cache n'est trouvé pour `cache:key`. Les caches sont récupérés dans l'ordre spécifié dans la section `fallback_keys`.

**Type de mot-clé** : Mot-clé de job. Vous pouvez l'utiliser uniquement dans un job ou dans la [section `default`](#default).

**Valeurs prises en charge** :

- Un tableau de clés de cache

**Exemple de `cache:fallback_keys`** :

```yaml
rspec:
  script: rspec
  cache:
    key: gems-$CI_COMMIT_REF_SLUG
    paths:
      - rspec/
    fallback_keys:
      - gems
    when: 'always'
```

---

### `coverage` {#coverage}

Utilisez `coverage` avec une expression régulière personnalisée pour configurer la façon dont la couverture de code est extraite de la sortie du job. GitLab affiche le pourcentage correspondant dans le widget MR, la liste des jobs du pipeline et les graphiques analytiques.

**Valeurs prises en charge** :

- Une expression régulière RE2. Doit commencer et se terminer par `/`. Doit correspondre au numéro de couverture. Peut également correspondre au texte environnant, vous n'avez donc pas besoin d'utiliser un groupe de caractères d'expression régulière pour capturer le numéro exact. Étant donné qu'il utilise la syntaxe RE2, tous les groupes doivent être non capturants.

**Exemple de `coverage`** :

```yaml
job1:
  script: rspec
  coverage: '/Code coverage: \d+(?:\.\d+)?/'
```

Dans cet exemple :

1. GitLab vérifie dans le job log s'il existe une correspondance avec l'expression régulière. Une ligne comme `Code coverage: 67.89% of lines covered` correspond.
1. GitLab vérifie ensuite le fragment correspondant par rapport à `\d+(?:\.\d+)?` pour extraire le numéro. L'expression régulière exemple correspond à `67.89`.

**Informations complémentaires** :

- S'il y a plusieurs lignes correspondantes dans la sortie du job, la dernière ligne est utilisée.
- S'il y a plusieurs correspondances dans une seule ligne, la dernière correspondance est utilisée.
- S'il y a plusieurs numéros de couverture dans le fragment correspondant, le premier numéro est utilisé.
- Les zéros non significatifs sont supprimés.
- La sortie de couverture des [pipelines enfants](../pipelines/downstream_pipelines.md#parent-child-pipelines) n'est pas enregistrée. Voir le [ticket 280818](https://gitlab.com/gitlab-org/gitlab/-/issues/280818).
- Pour afficher les annotations de diff ligne par ligne dans le diff du merge request, configurez [`artifacts:reports:coverage_report`](artifacts_reports.md#artifactsreportscoverage_report) séparément. La configuration de l'un n'active pas l'autre.

**Sujets connexes** :

- [Modèles regex de couverture](../testing/code_coverage/coverage_reporting.md#coverage-regex-patterns)
- [Visualisation de la couverture](../testing/code_coverage/coverage_visualization.md)

---

### `dast_configuration` {#dast_configuration}

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Utilisez le mot-clé `dast_configuration` pour spécifier un profil de site et un profil de scanner à utiliser dans une configuration CI/CD. Les deux profils doivent d'abord avoir été créés dans le projet. L'étape du job doit être `dast`.

**Type de mot-clé** : Mot-clé de job. Vous pouvez l'utiliser uniquement dans le cadre d'un job.

**Valeurs prises en charge** : Un de chaque : `site_profile` et `scanner_profile`.

- Utilisez `site_profile` pour spécifier le profil de site à utiliser dans le job.
- Utilisez `scanner_profile` pour spécifier le profil de scanner à utiliser dans le job.

**Exemple de `dast_configuration`** :

```yaml
stages:
  - build
  - dast

include:
  - template: DAST.gitlab-ci.yml

dast:
  dast_configuration:
    site_profile: "Example Co"
    scanner_profile: "Quick Passive Test"
```

Dans cet exemple, le job `dast` étend la configuration `dast` ajoutée avec le mot-clé `include` pour sélectionner un profil de site et un profil de scanner spécifiques.

**Informations complémentaires** :

- Les paramètres contenus dans un profil de site ou un profil de scanner ont la priorité sur ceux contenus dans le modèle DAST.

**Sujets connexes** :

- [Profil de site](../../user/application_security/dast/profiles.md#site-profile).
- [Profil de scanner](../../user/application_security/dast/profiles.md#scanner-profile).

---

### `dependencies` {#dependencies}

Utilisez le mot-clé `dependencies` pour définir une liste de jobs spécifiques à partir desquels récupérer des [artefacts](#artifacts). Les jobs spécifiés doivent tous se trouver dans des étapes antérieures. Vous pouvez également configurer un job pour qu'il ne télécharge aucun artefact.

Lorsque `dependencies` n'est pas défini dans un job, tous les jobs des étapes antérieures sont considérés comme dépendants et le job récupère tous les artefacts de ces jobs.

Pour récupérer des artefacts d'un job à la même étape, vous devez utiliser [`needs:artifacts`](#needsartifacts). Vous ne devriez pas combiner `dependencies` avec `needs` dans le même job.

**Type de mot-clé** : Mot-clé de job. Vous pouvez l'utiliser uniquement dans un job.

**Valeurs prises en charge** :

- Les noms des jobs à partir desquels récupérer les artefacts.
- Un tableau vide (`[]`), pour configurer le job afin qu'il ne télécharge aucun artefact.

**Exemple de `dependencies`** :

```yaml
build mac:
  stage: build
  script: make build:mac
  artifacts:
    paths:
      - binaries/

build linux:
  stage: build
  script: make build:linux
  artifacts:
    paths:
      - binaries/

test mac:
  stage: test
  script: make test:mac
  dependencies:
    - build mac

test linux:
  stage: test
  script: make test:linux
  dependencies:
    - build linux

deploy:
  stage: deploy
  script: make deploy
  environment: production
```

Dans cet exemple, deux jobs ont des artefacts : `build mac` et `build linux`. Lorsque `test mac` est exécuté, les artefacts de `build mac` sont téléchargés et extraits dans le contexte de la build. La même chose se produit pour `test linux` et les artefacts de `build linux`.

Le job `deploy` télécharge les artefacts de tous les jobs précédents en raison de la priorité des [étapes](#stages).

**Informations complémentaires** :

- Si le job précédent ne génère pas d'artefacts, ou s'il s'agit d'un job manuel qui n'a pas été exécuté, le job dépendant s'exécute quand même et ne génère pas d'erreur.
- Si les artefacts d'un job dépendant sont [expirés](#artifactsexpire_in) ou [supprimés](../jobs/job_artifacts.md#delete-job-log-and-artifacts), le job échoue.

---

### `environment` {#environment}

Utilisez `environment` pour définir l'[environnement](../environments/_index.md) vers lequel un job se déploie.

**Type de mot-clé** : Mot-clé de job. Vous pouvez l'utiliser uniquement dans un job.

**Valeurs prises en charge** : Le nom de l'environnement vers lequel le job se déploie, dans l'un des formats suivants :

- Texte brut, incluant des lettres, des chiffres, des espaces et ces caractères : `-`, `_`, `/`, `$`, `{`, `}`.
- Variables CI/CD, y compris les variables prédéfinies, de projet, de groupe, d'instance, ou les variables définies dans le fichier `.gitlab-ci.yml`. Vous ne pouvez pas utiliser les variables définies dans une section `script`.

**Exemple de `environment`** :

```yaml
deploy to production:
  stage: deploy
  script: git push production HEAD:main
  environment: production
```

**Informations complémentaires** :

- Si vous spécifiez un `environment` et qu'aucun environnement portant ce nom n'existe, un environnement est créé.

---

#### `environment:name` {#environmentname}

Définissez un nom pour un [environnement](../environments/_index.md).

Les noms d'environnements courants sont `qa`, `staging` et `production`, mais vous pouvez utiliser n'importe quel nom.

**Type de mot-clé** : Mot-clé de job. Vous pouvez l'utiliser uniquement dans un job.

**Valeurs prises en charge** : Le nom de l'environnement vers lequel le job se déploie, dans l'un des formats suivants :

- Texte brut, incluant des lettres, des chiffres, des espaces et ces caractères : `-`, `_`, `/`, `$`, `{`, `}`.
- [Variables CI/CD](../variables/where_variables_can_be_used.md#gitlab-ciyml-file), y compris les variables prédéfinies, de projet, de groupe, d'instance, ou les variables définies dans le fichier `.gitlab-ci.yml`. Vous ne pouvez pas utiliser les variables définies dans une section `script`.

**Exemple de `environment:name`** :

```yaml
deploy to production:
  stage: deploy
  script: git push production HEAD:main
  environment:
    name: production
```

---

#### `environment:url` {#environmenturl}

Définissez une URL pour un [environnement](../environments/_index.md).

**Type de mot-clé** : Mot-clé de job. Vous pouvez l'utiliser uniquement dans un job.

**Valeurs prises en charge** : Une URL unique, dans l'un des formats suivants :

- Texte brut, comme `https://prod.example.com`.
- [Variables CI/CD](../variables/where_variables_can_be_used.md#gitlab-ciyml-file), y compris les variables prédéfinies, de projet, de groupe, d'instance, ou les variables définies dans le fichier `.gitlab-ci.yml`. Vous ne pouvez pas utiliser les variables définies dans une section `script`.

**Exemple de `environment:url`** :

```yaml
deploy to production:
  stage: deploy
  script: git push production HEAD:main
  environment:
    name: production
    url: https://prod.example.com
```

**Informations complémentaires** :

- Une fois le job terminé, vous pouvez accéder à l'URL en sélectionnant un bouton dans les pages du merge request, de l'environnement ou du déploiement.

---

#### `environment:on_stop` {#environmenton_stop}

La fermeture (l'arrêt) des environnements peut être effectuée avec le mot-clé `on_stop` défini sous `environment`. Il déclare un job différent qui s'exécute pour fermer l'environnement.

**Type de mot-clé** : Mot-clé de job. Vous pouvez l'utiliser uniquement dans un job.

**Informations complémentaires** :

- Voir [`environment:action`](#environmentaction) pour plus de détails et un exemple.

---

#### `environment:action` {#environmentaction}

Utilisez le mot-clé `action` pour spécifier comment le job interagit avec l'environnement.

**Type de mot-clé** : Mot-clé de job. Vous pouvez l'utiliser uniquement dans un job.

**Valeurs prises en charge** : L'un des mots-clés suivants :

| **Valeur** | **Description** |
|:----------|:----------------|
| `start`   | Valeur par défaut. Indique que le job démarre l'environnement. Le déploiement est créé après le démarrage du job. |
| `prepare` | Indique que le job prépare uniquement l'environnement. Il ne déclenche pas de déploiements. [En savoir plus sur la préparation des environnements](../environments/_index.md#access-an-environment-for-preparation-or-verification-purposes). |
| `stop`    | Indique que le job arrête un environnement. [En savoir plus sur l'arrêt d'un environnement](../environments/_index.md#stopping-an-environment). |
| `verify`  | Indique que le job vérifie uniquement l'environnement. Il ne déclenche pas de déploiements. [En savoir plus sur la vérification des environnements](../environments/_index.md#access-an-environment-for-preparation-or-verification-purposes). |
| `access`  | Indique que le job accède uniquement à l'environnement. Il ne déclenche pas de déploiements. [En savoir plus sur l'accès aux environnements](../environments/_index.md#access-an-environment-for-preparation-or-verification-purposes). |

**Exemple de `environment:action`** :

```yaml
stop_review_app:
  stage: deploy
  variables:
    GIT_STRATEGY: none
  script: make delete-app
  when: manual
  environment:
    name: review/$CI_COMMIT_REF_SLUG
    action: stop
```

---

#### `environment:auto_stop_in` {#environmentauto_stop_in}

{{< history >}}

- La prise en charge des variables CI/CD a été [introduite](https://gitlab.com/gitlab-org/gitlab/-/issues/365140) dans GitLab 15.4.
- [Mis à jour](https://gitlab.com/gitlab-org/gitlab/-/issues/437133) pour prendre en charge les actions d'environnement `prepare`, `access` et `verify` dans GitLab 17.7.

{{< /history >}}

Le mot-clé `auto_stop_in` spécifie la durée de vie de l'environnement. Lorsqu'un environnement expire, GitLab l'arrête automatiquement.

**Type de mot-clé** : Mot-clé de job. Vous pouvez l'utiliser uniquement dans un job.

**Valeurs prises en charge** : Une durée exprimée en langage naturel. Par exemple, ces valeurs sont toutes équivalentes :

- `168 hours`
- `7 days`
- `one week`
- `never`

Les variables CI/CD [sont prises en charge](../variables/where_variables_can_be_used.md#gitlab-ciyml-file).

**Exemple de `environment:auto_stop_in`** :

```yaml
review_app:
  script: deploy-review-app
  environment:
    name: review/$CI_COMMIT_REF_SLUG
    auto_stop_in: 1 day
```

Lorsque l'environnement pour `review_app` est créé, la durée de vie de l'environnement est définie sur `1 day`. Chaque fois que l'environnement éphémère est déployé, cette durée de vie est également réinitialisée à `1 day`.

Le mot-clé `auto_stop_in` peut être utilisé pour toutes les [actions d'environnement](#environmentaction) sauf `stop`. Certaines actions peuvent être utilisées pour réinitialiser l'heure d'arrêt planifiée de l'environnement. Pour plus d'informations, voir [Accéder à un environnement à des fins de préparation ou de vérification](../environments/_index.md#access-an-environment-for-preparation-or-verification-purposes).

**Sujets connexes** :

- [Documentation sur l'arrêt automatique des environnements](../environments/_index.md#stop-an-environment-after-a-certain-time-period).

---

#### `environment:kubernetes` {#environmentkubernetes}

{{< history >}}

- Le mot-clé `agent` a été [introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/467912) dans GitLab 17.6.
- Les mots-clés `namespace` et `flux_resource_path` ont été [introduits](https://gitlab.com/gitlab-org/gitlab/-/issues/500164) dans GitLab 17.7.
- Les mots-clés `namespace` et `flux_resource_path` ont été [dépréciés](deprecated_keywords.md) dans GitLab 18.4.
- Les mots-clés `dashboard:namespace` et `dashboard:flux_resource_path` ont été [introduits](https://gitlab.com/gitlab-org/gitlab/-/issues/515854) dans GitLab 18.4.

{{< /history >}}

Utilisez le mot-clé `kubernetes` pour configurer le [tableau de bord pour Kubernetes](../environments/kubernetes_dashboard.md) et les [ressources Kubernetes gérées par GitLab](../../user/clusters/agent/managed_kubernetes_resources.md) pour un environnement.

**Type de mot-clé** : Mot-clé de job. Vous pouvez l'utiliser uniquement dans un job.

**Valeurs prises en charge** :

- `agent` : Une chaîne spécifiant l'[agent GitLab pour Kubernetes](../../user/clusters/agent/_index.md). Le format est `path/to/agent/project:agent-name`. Si l'agent est connecté au projet exécutant le pipeline, utilisez `$CI_PROJECT_PATH:agent-name`.
- `dashboard:namespace` : Une chaîne représentant l'espace de nommage Kubernetes où l'environnement est déployé. L'espace de nommage doit être défini conjointement avec le mot-clé `agent`. `namespace` est [déprécié](deprecated_keywords.md#environmentkubernetesnamespace-and-environmentkubernetesflux_resource_path).
- `dashboard:flux_resource_path` : Une chaîne représentant le chemin complet vers la ressource Flux, telle qu'une `HelmRelease`. La ressource Flux doit être définie conjointement avec les mots-clés `agent` et `dashboard:namespace`. `flux_resource_path` est [déprécié](deprecated_keywords.md#environmentkubernetesnamespace-and-environmentkubernetesflux_resource_path).
- `managed_resources` : Un hash avec le mot-clé `enabled` pour configurer les [ressources Kubernetes gérées par GitLab](../../user/clusters/agent/managed_kubernetes_resources.md) pour l'environnement.
  - `managed_resources:enabled` : Une valeur booléenne indiquant si les ressources Kubernetes gérées par GitLab sont activées pour l'environnement.
- `dashboard` : Un hash avec les mots-clés `dashboard:namespace` et `dashboard:flux_resource_path` pour configurer le [tableau de bord pour Kubernetes](../environments/kubernetes_dashboard.md) pour l'environnement.

**Exemple de `environment:kubernetes`** :

```yaml
deploy:
  stage: deploy
  script: make deploy-app
  environment:
    name: production
    kubernetes:
      agent: path/to/agent/project:agent-name
      dashboard:
        namespace: my-namespace
        flux_resource_path: helm.toolkit.fluxcd.io/v2/namespaces/flux-system/helmreleases/helm-release-resource
```

**Exemple de `environment:kubernetes`** lors de la désactivation des ressources gérées :

```yaml
deploy:
  stage: deploy
  script: make deploy-app
  environment:
    name: production
    kubernetes:
      agent: path/to/agent/project:agent-name
      managed_resources:
        enabled: false
      dashboard:
        namespace: my-namespace
        flux_resource_path: helm.toolkit.fluxcd.io/v2/namespaces/flux-system/helmreleases/helm-release-resource
```

Cette configuration :

- Configure le job `deploy` pour se déployer dans l'environnement `production`.
- Associe l'[agent](../../user/clusters/agent/_index.md) nommé `agent-name` à l'environnement.
- Configure le [tableau de bord pour Kubernetes](../environments/kubernetes_dashboard.md) pour un environnement avec l'espace de nommage `my-namespace` et `flux_resource_path` défini sur `helm.toolkit.fluxcd.io/v2/namespaces/flux-system/helmreleases/helm-release-resource`.

**Informations complémentaires** :

- Pour utiliser le tableau de bord, vous devez [installer l'agent GitLab pour Kubernetes](../../user/clusters/agent/install/_index.md) et [configurer `user_access`](../../user/clusters/agent/user_access.md) pour le projet de l'environnement ou son groupe parent.
- L'utilisateur qui exécute le job doit être autorisé à accéder à l'agent de cluster. Sinon, le tableau de bord ignore les attributs `agent`, `namespace` et `flux_resource_path`.
- Si vous souhaitez uniquement définir `agent`, vous n'avez pas à définir `namespace`, et ne pouvez pas définir `flux_resource_path`. Cependant, cette configuration liste tous les espaces de nommage d'un cluster dans le tableau de bord pour Kubernetes.

---

#### `environment:deployment_tier` {#environmentdeployment_tier}

{{< history >}}

- La prise en charge des variables CI/CD a été [ajoutée](https://gitlab.com/gitlab-org/gitlab/-/issues/365402) dans GitLab 18.5.

{{< /history >}}

Utilisez le mot-clé `deployment_tier` pour spécifier le niveau de l'environnement de déploiement.

**Type de mot-clé** : Mot-clé de job. Vous pouvez l'utiliser uniquement dans un job.

**Valeurs prises en charge** : L'une des valeurs suivantes :

- `production`
- `staging`
- `testing`
- `development`
- `other`
- [Variables CI/CD](../variables/where_variables_can_be_used.md#gitlab-ciyml-file), y compris les variables prédéfinies, de projet, de groupe, d'instance, ou les variables définies dans le fichier `.gitlab-ci.yml`. Vous ne pouvez pas utiliser les variables définies dans une section `script`.

**Exemple de `environment:deployment_tier`** :

```yaml
deploy:
  script: echo
  environment:
    name: customer-portal
    deployment_tier: production
```

**Informations complémentaires** :

- Les environnements créés à partir de cette définition de job se voient attribuer une [édition](../environments/_index.md#deployment-tier-of-environments) basée sur cette valeur.
- Les environnements existants ne voient pas leur édition mise à jour si cette valeur est ajoutée ultérieurement. Les environnements existants doivent voir leur édition mise à jour via l'[API Environments](../../api/environments.md#update-an-existing-environment).

**Sujets connexes** :

- [Niveau de déploiement des environnements](../environments/_index.md#deployment-tier-of-environments).

---

#### Environnements dynamiques {#dynamic-environments}

Utilisez des [variables](../variables/_index.md) CI/CD pour nommer les environnements de manière dynamique.

Par exemple :

```yaml
deploy as review app:
  stage: deploy
  script: make deploy
  environment:
    name: review/$CI_COMMIT_REF_SLUG
    url: https://$CI_ENVIRONMENT_SLUG.example.com/
```

Le job `deploy as review app` est marqué comme un déploiement pour créer dynamiquement l'environnement `review/$CI_COMMIT_REF_SLUG`. `$CI_COMMIT_REF_SLUG` est une [variable CI/CD](../variables/_index.md) définie par le runner. La variable `$CI_ENVIRONMENT_SLUG` est basée sur le nom de l'environnement, mais adaptée pour être incluse dans les URLs. Si le job `deploy as review app` s'exécute dans une branche nommée `pow`, cet environnement serait accessible avec une URL comme `https://review-pow.example.com/`.

Le cas d'utilisation courant est de créer des environnements dynamiques pour les branches et de les utiliser comme environnements éphémères. Vous pouvez voir un exemple qui utilise des environnements éphémères à l'adresse <https://gitlab.com/gitlab-examples/review-apps-nginx/>.

---

### `extends` {#extends}

Utilisez `extends` pour réutiliser des sections de configuration. C'est une alternative aux [ancres YAML](yaml_optimization.md#anchors) et est un peu plus flexible et lisible.

**Type de mot-clé** : Mot-clé de job. Vous pouvez l'utiliser uniquement dans un job.

**Valeurs prises en charge** :

- Le nom d'un autre job dans le pipeline.
- Une liste (tableau) de noms d'autres jobs dans le pipeline.

**Exemple de `extends`** :

```yaml
.tests:
  stage: test
  image: ruby:3.0

rspec:
  extends: .tests
  script: rake rspec

rubocop:
  extends: .tests
  script: bundle exec rubocop
```

Dans cet exemple, le job `rspec` utilise la configuration du job modèle `.tests`. Lors de la création du pipeline, GitLab :

- Effectue une fusion profonde inversée basée sur les clés.
- Fusionne le contenu de `.tests` avec le job `rspec`.
- Ne fusionne pas les valeurs des clés.

La configuration combinée est équivalente à ces jobs :

```yaml
rspec:
  stage: test
  image: ruby:3.0
  script: rake rspec

rubocop:
  stage: test
  image: ruby:3.0
  script: bundle exec rubocop
```

**Informations complémentaires** :

- Vous pouvez utiliser plusieurs parents pour `extends`.
- Le mot-clé `extends` prend en charge jusqu'à onze niveaux d'héritage, mais vous devriez éviter d'en utiliser plus de trois.
- Dans l'exemple précédent, `.tests` est un [job masqué](../jobs/_index.md#hide-a-job), mais vous pouvez également étendre la configuration à partir de jobs ordinaires.

**Sujets connexes** :

- [Réutiliser des sections de configuration en utilisant `extends`](yaml_optimization.md#use-extends-to-reuse-configuration-sections).
- Utilisez `extends` pour réutiliser la configuration des [fichiers de configuration inclus](yaml_optimization.md#use-extends-and-include-together).

---

### `hooks` {#hooks}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/356850) dans GitLab 15.6 [avec un indicateur](../../administration/feature_flags/_index.md) nommé `ci_hooks_pre_get_sources_script`. Désactivé par défaut.
- [Généralement disponible](https://gitlab.com/gitlab-org/gitlab/-/issues/381840) dans GitLab 15.10. Le feature flag `ci_hooks_pre_get_sources_script` a été supprimé.

{{< /history >}}

Utilisez `hooks` pour spécifier des listes de commandes à exécuter sur le runner à certaines étapes de l'exécution du job, par exemple avant la récupération du dépôt Git.

La configuration du job et la configuration par défaut ne sont pas fusionnées. Si le pipeline a [`default:hooks`](#default) défini, et que le job a également `hooks`, la configuration du job est prioritaire et la configuration par défaut n'est pas utilisée.

**Type de mot-clé** : Mot-clé de job. Vous pouvez l'utiliser uniquement dans un job ou dans la [section `default`](#default).

**Valeurs prises en charge** :

- Un hash de hooks et de leurs commandes. Hooks disponibles : `pre_get_sources_script`.

---

#### `hooks:pre_get_sources_script` {#hookspre_get_sources_script}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/356850) dans GitLab 15.6 [avec un indicateur](../../administration/feature_flags/_index.md) nommé `ci_hooks_pre_get_sources_script`. Désactivé par défaut.
- [Généralement disponible](https://gitlab.com/gitlab-org/gitlab/-/issues/381840) dans GitLab 15.10. Le feature flag `ci_hooks_pre_get_sources_script` a été supprimé.

{{< /history >}}

Utilisez `hooks:pre_get_sources_script` pour spécifier une liste de commandes à exécuter sur le runner avant le clonage du dépôt Git et de ses sous-modules. Vous pouvez l'utiliser par exemple pour :

- Ajuster la [configuration Git](../jobs/job_troubleshooting.md#get_sources-job-section-fails-because-of-an-http2-problem).
- Exporter les [variables de traçage](../../topics/git/troubleshooting_git.md#debug-git-with-traces).

**Valeurs prises en charge** : Un tableau comprenant :

- Des commandes sur une seule ligne.
- Des commandes longues [réparties sur plusieurs lignes](script.md#split-long-commands).
- [Ancres YAML](yaml_optimization.md#yaml-anchors-for-scripts).

Les variables CI/CD [sont prises en charge](../variables/where_variables_can_be_used.md#gitlab-ciyml-file).

**Exemple de `hooks:pre_get_sources_script`** :

```yaml
job1:
  hooks:
    pre_get_sources_script:
      - echo 'hello job1 pre_get_sources_script'
  script: echo 'hello job1 script'
```

**Sujets connexes** :

- [Configuration de GitLab Runner](https://docs.gitlab.com/runner/configuration/advanced-configuration/#the-runners-section)

---

### `identity` {#identity}

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com
- Statut : Version bêta

{{< /details >}}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/142054) dans GitLab 16.9 [avec un feature flag](../../administration/feature_flags/_index.md) nommé `google_cloud_support_feature_flag`. Cette fonctionnalité est en [bêta](../../policy/development_stages_support.md).
- [Activé sur GitLab.com](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/150472) dans GitLab 17.1. Le feature flag `google_cloud_support_feature_flag` a été supprimé.

{{< /history >}}

Cette fonctionnalité est en [bêta](../../policy/development_stages_support.md).

Utilisez `identity` pour vous authentifier auprès de services tiers à l'aide de la fédération d'identités.

**Type de mot-clé** : Mot-clé de job. Vous pouvez l'utiliser uniquement dans un job.

**Valeurs prises en charge** : Un identifiant. Fournisseurs pris en charge :

- `google_cloud` : Google Cloud. Doit être configuré avec l'[intégration Google Cloud IAM](../../integration/google_cloud_iam.md).

**Exemple de `identity`** :

```yaml
job_with_workload_identity:
  identity: google_cloud
  script:
    - gcloud compute instances list
```

**Sujets connexes** :

- [Fédération des identités de charge de travail](https://cloud.google.com/iam/docs/workload-identity-federation).
- [Intégration Google Cloud IAM](../../integration/google_cloud_iam.md).

---

### `id_tokens` {#id_tokens}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/356986) dans GitLab 15.7.

{{< /history >}}

Utilisez `id_tokens` pour créer des [tokens d'identité](../secrets/id_token_authentication.md) afin de vous authentifier auprès de services tiers. Tous les JWT créés de cette façon prennent en charge l'authentification OIDC. Le sous-mot-clé requis `aud` est utilisé pour configurer la revendication `aud` pour le JWT.

La configuration du job et la configuration par défaut ne sont pas fusionnées. Si le pipeline a [`default:id_tokens`](#default) défini, et que le job a également `id_tokens`, la configuration du job est prioritaire et la configuration par défaut n'est pas utilisée.

**Valeurs prises en charge** :

- Noms de tokens avec leurs revendications `aud`. `aud` prend en charge :
  - Une chaîne unique.
  - Un tableau de chaînes de caractères.
  - [Variables CI/CD](../variables/where_variables_can_be_used.md#gitlab-ciyml-file).

**Exemple de `id_tokens`** :

```yaml
job_with_id_tokens:
  id_tokens:
    ID_TOKEN_1:
      aud: https://vault.example.com
    ID_TOKEN_2:
      aud:
        - https://gcp.com
        - https://aws.com
    SIGSTORE_ID_TOKEN:
      aud: sigstore
  script:
    - command_to_authenticate_with_vault $ID_TOKEN_1
    - command_to_authenticate_with_aws $ID_TOKEN_2
    - command_to_authenticate_with_gcp $ID_TOKEN_2
```

**Sujets connexes** :

- [Authentification par token d'identité](../secrets/id_token_authentication.md).
- [Se connecter aux services cloud](../cloud_services/_index.md).
- [Signature sans clé avec Sigstore](signing_examples.md).

---

### `image` {#image}

Utilisez `image` pour spécifier une image Docker dans laquelle le job s'exécute.

La configuration du job et la configuration par défaut ne sont pas fusionnées. Si le pipeline a [`default:image`](#default) défini, et que le job a également `image`, la configuration du job est prioritaire et la configuration par défaut n'est pas utilisée.

**Type de mot-clé** : Mot-clé de job. Vous pouvez l'utiliser uniquement dans un job ou dans la [section `default`](#default).

**Valeurs prises en charge** : Le nom de l'image, y compris le chemin de registre si nécessaire, dans l'un des formats suivants :

- `<image-name>` (identique à l'utilisation de `<image-name>` avec le tag `latest`)
- `<image-name>:<tag>`
- `<image-name>@<digest>`

Les variables CI/CD [sont prises en charge](../variables/where_variables_can_be_used.md#gitlab-ciyml-file).

**Exemple de `image`** :

```yaml
default:
  image: ruby:3.0

rspec:
  script: bundle exec rspec

rspec 2.7:
  image: registry.example.com/my-group/my-project/ruby:2.7
  script: bundle exec rspec
```

Dans cet exemple, l'image `ruby:3.0` est celle par défaut pour tous les jobs du pipeline. Le job `rspec 2.7` n'utilise pas la valeur par défaut, car il la remplace par une section `image` spécifique au job.

**Informations complémentaires** :

- L'utilisation de `image` au niveau supérieur, mais pas dans la section `default`, est [dépréciée](deprecated_keywords.md#globally-defined-image-services-cache-before_script-after_script).

**Sujets connexes** :

- [Exécuter vos jobs CI/CD dans des conteneurs Docker](../docker/using_docker_images.md).

---

#### `image:name` {#imagename}

Le nom de l'image Docker dans laquelle le job s'exécute. Similaire à [`image`](#image) utilisé seul.

**Type de mot-clé** : Mot-clé de job. Vous pouvez l'utiliser uniquement dans un job ou dans la [section `default`](#default).

**Valeurs prises en charge** : Le nom de l'image, y compris le chemin de registre si nécessaire, dans l'un des formats suivants :

- `<image-name>` (identique à l'utilisation de `<image-name>` avec le tag `latest`)
- `<image-name>:<tag>`
- `<image-name>@<digest>`

Les variables CI/CD [sont prises en charge](../variables/where_variables_can_be_used.md#gitlab-ciyml-file).

**Exemple de `image:name`** :

```yaml
test-job:
  image:
    name: "registry.example.com/my/image:latest"
  script: echo "Hello world"
```

**Sujets connexes** :

- [Exécuter vos jobs CI/CD dans des conteneurs Docker](../docker/using_docker_images.md).

---

#### `image:entrypoint` {#imageentrypoint}

Commande ou script à exécuter comme point d'entrée du conteneur.

Lors de la création du conteneur Docker, `entrypoint` est traduit en option Docker `--entrypoint`. La syntaxe est similaire à la [directive `ENTRYPOINT` du Dockerfile](https://docs.docker.com/reference/dockerfile/#entrypoint), où chaque token shell est une chaîne séparée dans le tableau.

**Type de mot-clé** : Mot-clé de job. Vous pouvez l'utiliser uniquement dans un job ou dans la [section `default`](#default).

**Valeurs prises en charge** :

- Une chaîne de caractères.

**Exemple de `image:entrypoint`** :

```yaml
test-job:
  image:
    name: super/sql:experimental
    entrypoint: [""]
  script: echo "Hello world"
```

**Sujets connexes** :

- [Remplacer le point d'entrée d'une image](../docker/using_docker_images.md#override-the-entrypoint-of-an-image).

---

#### `image:docker` {#imagedocker}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/27919) dans GitLab 16.7. Requiert GitLab Runner 16.7 ou une version ultérieure.
- L'option d'entrée `user` a été [introduite](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/137907) dans GitLab 16.8.

{{< /history >}}

Utilisez `image:docker` pour transmettre des options aux runners utilisant l'[exécuteur Docker](https://docs.gitlab.com/runner/executors/docker/) ou l'[exécuteur Kubernetes](https://docs.gitlab.com/runner/executors/kubernetes/). Ce mot-clé ne fonctionne pas avec les autres types d'exécuteurs.

**Type de mot-clé** : Mot-clé de job. Vous pouvez l'utiliser uniquement dans un job ou dans la [section `default`](#default).

**Valeurs prises en charge** :

Un hash d'options pour l'exécuteur Docker, qui peut inclure :

- `platform` : Sélectionne l'architecture de l'image à télécharger. Lorsqu'elle n'est pas spécifiée, la valeur par défaut est la même plateforme que le runner hôte.
- `user` : Spécifiez le nom d'utilisateur ou l'UID à utiliser lors de l'exécution du conteneur.

**Exemple de `image:docker`** :

```yaml
arm-sql-job:
  script: echo "Run sql tests"
  image:
    name: super/sql:experimental
    docker:
      platform: arm64/v8
      user: dave
```

**Informations complémentaires** :

- `image:docker:platform` correspond à l'[option `docker pull --platform`](https://docs.docker.com/reference/cli/docker/image/pull/#options).
- `image:docker:user` correspond à l'[option `docker run --user`](https://docs.docker.com/reference/cli/docker/container/run/#options).

---

#### `image:kubernetes` {#imagekubernetes}

{{< history >}}

- [Introduite](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/38451) dans GitLab 18.0. Requiert GitLab Runner 17.11 ou une version ultérieure.
- L'option d'entrée `user` a été [introduite](https://gitlab.com/gitlab-org/gitlab-runner/-/merge_requests/5469) dans GitLab Runner 17.11.
- L'option d'entrée `user` a été [étendue pour prendre en charge le format `uid:gid`](https://gitlab.com/gitlab-org/gitlab-runner/-/merge_requests/5540) dans GitLab 18.0.

{{< /history >}}

Utilisez `image:kubernetes` pour transmettre des options à l'[exécuteur Kubernetes](https://docs.gitlab.com/runner/executors/kubernetes/) de GitLab Runner. Ce mot-clé ne fonctionne pas avec les autres types d'exécuteurs.

**Type de mot-clé** : Mot-clé de job. Vous pouvez l'utiliser uniquement dans un job ou dans la [section `default`](#default).

**Valeurs prises en charge** :

Un hash d'options pour l'exécuteur Kubernetes, qui peut inclure :

- `user` : Spécifiez le nom d'utilisateur ou l'UID à utiliser lors de l'exécution du conteneur. Vous pouvez également l'utiliser pour définir le GID en utilisant le format `UID:GID`.

**Exemple de `image:kubernetes` avec l'UID uniquement** :

```yaml
arm-sql-job:
  script: echo "Run sql tests"
  image:
    name: super/sql:experimental
    kubernetes:
      user: "1001"
```

**Exemple de `image:kubernetes` avec l'UID et le GID** :

```yaml
arm-sql-job:
  script: echo "Run sql tests"
  image:
    name: super/sql:experimental
    kubernetes:
      user: "1001:1001"
```

---

#### `image:pull_policy` {#imagepull_policy}

{{< history >}}

- [Introduite](https://gitlab.com/gitlab-org/gitlab/-/issues/21619) dans GitLab 15.1 [avec un flag](../../administration/feature_flags/_index.md) nommé `ci_docker_image_pull_policy`. Désactivé par défaut.
- [Activé sur GitLab.com et GitLab Self-Managed](https://gitlab.com/gitlab-org/gitlab/-/issues/363186) dans GitLab 15.2.
- [Généralement disponible](https://gitlab.com/gitlab-org/gitlab/-/issues/363186) dans GitLab 15.4. [Feature flag `ci_docker_image_pull_policy`](https://gitlab.com/gitlab-org/gitlab/-/issues/363186) supprimé.
- Requiert GitLab Runner 15.1 ou une version ultérieure.

{{< /history >}}

La politique d'extraction que le runner utilise pour récupérer l'image Docker.

**Type de mot-clé** : Mot-clé de job. Vous pouvez l'utiliser uniquement dans un job ou dans la [section `default`](#default).

**Valeurs prises en charge** :

- Une seule politique d'extraction, ou plusieurs politiques d'extraction dans un tableau. Peut être `always`, `if-not-present` ou `never`.

**Exemples de `image:pull_policy`** :

```yaml
job1:
  script: echo "A single pull policy."
  image:
    name: ruby:3.0
    pull_policy: if-not-present

job2:
  script: echo "Multiple pull policies."
  image:
    name: ruby:3.0
    pull_policy: [always, if-not-present]
```

**Informations complémentaires** :

- Si le runner ne prend pas en charge la politique d'extraction définie, le job échoue avec une erreur similaire à : `ERROR: Job failed (system failure): the configured PullPolicies ([always]) are not allowed by AllowedPullPolicies ([never])`.

**Sujets connexes** :

- [Exécuter vos jobs CI/CD dans des conteneurs Docker](../docker/using_docker_images.md).
- [Configurer la façon dont les runners extraient les images](https://docs.gitlab.com/runner/executors/docker/#configure-how-runners-pull-images).
- [Définir plusieurs politiques d'extraction](https://docs.gitlab.com/runner/executors/docker/#set-multiple-pull-policies).

---

### `inputs` {#inputs}

{{< history >}}

- [Introduit](https://gitlab.com/groups/gitlab-org/-/epics/17833) dans GitLab 18.10.

{{< /history >}}

Utilisez `inputs` pour définir des entrées typées et validées pour un job. Les [entrées de job](../jobs/job_inputs.md) peuvent être remplacées lors de l'exécution ou de la relance manuelle d'un job.

Les entrées de job sont des paramètres qui fournissent la sécurité des types et la validation. Contrairement aux [variables CI/CD](../variables/_index.md), seules les entrées explicitement définies dans le job peuvent être spécifiées lors de l'exécution ou de la relance du job. Tous les noms d'entrées de job doivent être prédéfinis.

Référencez les valeurs d'entrée de job avec la syntaxe d'expression [Moa](../functions/moa.md) `${{ job.inputs.INPUT_NAME }}`.

**Type de mot-clé** : Mot-clé de job. Vous pouvez l'utiliser uniquement dans un job.

**Valeurs prises en charge** :

Un hash de noms d'entrées, où chaque entrée est configurée avec un ou plusieurs sous-mots-clés :

- [`default`](#inputsdefault) (requis)
- [`type`](#inputstype)
- [`options`](#inputsoptions)
- [`description`](#inputsdescription)
- [`regex`](#inputsregex)

**Exemple de `inputs`** :

```yaml
test_job:
  inputs:
    test_suite:
      default: unit
      description: Which test suite to run
      options: [unit, integration, e2e]
    parallel_count:
      type: number
      default: 5
      description: Number of parallel test runners
    verbose:
      type: boolean
      default: false
      description: Enable verbose test output
  script:
    - 'echo "Running ${{ job.inputs.test_suite }} tests"'
    - 'if [ "${{ job.inputs.verbose }}" == "true" ]; then export TEST_VERBOSE=1; fi'
    - ./run_tests.sh --suite ${{ job.inputs.test_suite }} --parallel ${{ job.inputs.parallel_count }}
```

**Informations complémentaires** :

- Les entrées de job sont validées lors de la création du job et lorsque vous essayez de relancer un job avec de nouvelles valeurs d'entrée. Si la validation échoue, le job ne démarre pas.
- Les entrées de job ont une portée limitée au job dans lequel elles sont définies et ne peuvent pas être accédées par d'autres jobs.
- Pour obtenir la liste complète des mots-clés qui prennent en charge les entrées de job, voir [où vous pouvez utiliser les entrées de job](../jobs/job_inputs.md#where-you-can-use-job-inputs).

---

#### `inputs:default` {#inputsdefault}

Toutes les entrées de job doivent avoir une valeur par défaut définie avec `default`.

**Type de mot-clé** : Mot-clé de job. Vous pouvez l'utiliser uniquement dans un job.

**Valeurs prises en charge** : Toute valeur correspondant au [`type`](#inputstype) de l'entrée.

**Exemple de `inputs:default`** :

```yaml
test_job:
  inputs:
    environment:
      default: staging
    timeout:
      type: number
      default: 30
```

---

#### `inputs:type` {#inputstype}

Utilisez `type` pour définir le type de données de la valeur d'entrée.

**Type de mot-clé** : Mot-clé de job. Vous pouvez l'utiliser uniquement dans un job.

**Valeurs prises en charge** :

- `string` (par défaut)
- `number`
- `boolean`
- `array`.

**Exemple de `inputs:type`** :

```yaml
test_job:
  inputs:
    count:
      type: number
      default: 5
    enabled:
      type: boolean
      default: true
```

---

#### `inputs:description` {#inputsdescription}

Utilisez `description` pour fournir des informations sur l'objectif de l'entrée. La description n'a pas d'effet sur le comportement de l'entrée.

**Type de mot-clé** : Mot-clé de job. Vous pouvez l'utiliser uniquement dans un job.

**Valeurs prises en charge** : Une chaîne de caractères.

**Exemple de `inputs:description`** :

```yaml
deploy_job:
  inputs:
    environment:
      default: staging
      description: Target deployment environment
```

---

#### `inputs:options` {#inputsoptions}

Utilisez `options` pour spécifier une liste de valeurs autorisées pour une entrée.

La valeur d'entrée doit correspondre exactement à l'une des options listées (sensible à la casse). La validation échoue si la valeur ne correspond à aucune option.

**Type de mot-clé** : Mot-clé de job. Vous pouvez l'utiliser uniquement dans un job.

**Valeurs prises en charge** : Un tableau de valeurs autorisées.

**Exemple de `inputs:options`** :

```yaml
deploy_job:
  inputs:
    environment:
      default: staging
      options: [development, staging, production]
```

---

#### `inputs:regex` {#inputsregex}

Utilisez `regex` pour spécifier un modèle d'expression régulière auquel la valeur d'entrée doit correspondre.

La validation échoue si la valeur ne correspond pas à l'expression régulière.

**Type de mot-clé** : Mot-clé de job. Vous pouvez l'utiliser uniquement dans un job.

**Valeurs prises en charge** : Une chaîne d'expression régulière.

**Exemple de `inputs:regex`** :

```yaml
deploy_job:
  inputs:
    version:
      default: v1.0.0
      regex: ^v\d+\.\d+\.\d+$
```

Dans cet exemple, une valeur d'entrée `v1.1.1` passe la validation regex, mais une entrée `v1.1.1-beta` ne la passe pas.

---

### `inherit` {#inherit}

Utilisez `inherit` pour [contrôler l'héritage des mots-clés par défaut et des variables](../jobs/_index.md#control-the-inheritance-of-default-keywords-and-variables).

---

#### `inherit:default` {#inheritdefault}

Utilisez `inherit:default` pour contrôler l'héritage des [mots-clés par défaut](#default).

**Type de mot-clé** : Mot-clé de job. Vous pouvez l'utiliser uniquement dans un job.

**Valeurs prises en charge** :

- `true` (par défaut) ou `false` pour activer ou désactiver l'héritage de tous les mots-clés par défaut.
- Une liste de mots-clés par défaut spécifiques à hériter.

**Exemple de `inherit:default`** :

```yaml
default:
  retry: 2
  image: ruby:3.0
  interruptible: true

job1:
  script: echo "This job does not inherit any default keywords."
  inherit:
    default: false

job2:
  script: echo "This job inherits only the two listed default keywords. It does not inherit 'interruptible'."
  inherit:
    default:
      - retry
      - image
```

**Informations complémentaires** :

- Vous pouvez également lister les mots-clés par défaut à hériter sur une seule ligne : `default: [keyword1, keyword2]`

---

#### `inherit:variables` {#inheritvariables}

Utilisez `inherit:variables` pour contrôler l'héritage des mots-clés de [variables par défaut](#default-variables).

**Type de mot-clé** : Mot-clé de job. Vous pouvez l'utiliser uniquement dans un job.

**Valeurs prises en charge** :

- `true` (par défaut) ou `false` pour activer ou désactiver l'héritage de toutes les variables par défaut.
- Une liste de variables spécifiques à hériter.

**Exemple de `inherit:variables`** :

```yaml
variables:
  VARIABLE1: "This is default variable 1"
  VARIABLE2: "This is default variable 2"
  VARIABLE3: "This is default variable 3"

job1:
  script: echo "This job does not inherit any default variables."
  inherit:
    variables: false

job2:
  script: echo "This job inherits only the two listed default variables. It does not inherit 'VARIABLE3'."
  inherit:
    variables:
      - VARIABLE1
      - VARIABLE2
```

**Informations complémentaires** :

- Vous pouvez également lister les variables par défaut à hériter sur une seule ligne : `variables: [VARIABLE1, VARIABLE2]`

---

### `interruptible` {#interruptible}

{{< history >}}

- La prise en charge des jobs `trigger` a été [introduite](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/138508) dans GitLab 16.8.

{{< /history >}}

Utilisez `interruptible` pour configurer la fonctionnalité d'[annulation automatique des pipelines redondants](../pipelines/settings.md#auto-cancel-redundant-pipelines) afin d'annuler un job avant qu'il ne se termine si un nouveau pipeline sur la même référence démarre pour un commit plus récent. Si la fonctionnalité est désactivée, le mot-clé n'a aucun effet. Le nouveau pipeline doit concerner un commit avec de nouvelles modifications. Par exemple, la fonctionnalité **Annulation automatique des pipelines redondants** n'a aucun effet si vous sélectionnez **Nouveau pipeline** dans l'interface utilisateur pour exécuter un pipeline pour le même commit.

Le comportement de la fonctionnalité **Annulation automatique des pipelines redondants** peut être contrôlé par le paramètre [`workflow:auto_cancel:on_new_commit`](#workflowauto_cancelon_new_commit).

**Type de mot-clé** : Mot-clé de job. Vous pouvez l'utiliser uniquement dans un job ou dans la [section `default`](#default).

**Valeurs prises en charge** :

- `true` ou `false` (par défaut).

**Exemple de `interruptible` avec le comportement par défaut** :

```yaml
workflow:
  auto_cancel:
    on_new_commit: conservative # the default behavior

stages:
  - stage1
  - stage2
  - stage3

step-1:
  stage: stage1
  script:
    - echo "Can be canceled."
  interruptible: true

step-2:
  stage: stage2
  script:
    - echo "Can not be canceled."

step-3:
  stage: stage3
  script:
    - echo "Because step-2 can not be canceled, this step can never be canceled, even though it's set as interruptible."
  interruptible: true
```

Dans cet exemple, un nouveau pipeline entraîne l'annulation d'un pipeline en cours d'exécution :

- Annulé, si uniquement `step-1` est en cours d'exécution ou en attente.
- Non annulé, après le démarrage de `step-2`.

**Exemple de `interruptible` avec le paramètre `auto_cancel:on_new_commit:interruptible`** :

```yaml
workflow:
  auto_cancel:
    on_new_commit: interruptible

stages:
  - stage1
  - stage2
  - stage3

step-1:
  stage: stage1
  script:
    - echo "Can be canceled."
  interruptible: true

step-2:
  stage: stage2
  script:
    - echo "Can not be canceled."

step-3:
  stage: stage3
  script:
    - echo "Can be canceled."
  interruptible: true
```

Dans cet exemple, un nouveau pipeline entraîne l'annulation de `step-1` et `step-3` par un pipeline en cours d'exécution s'ils sont en cours d'exécution ou en attente.

**Informations complémentaires** :

- Définissez `interruptible: true` uniquement si le job peut être annulé en toute sécurité après son démarrage, comme un job de build. Les jobs de déploiement ne devraient généralement pas être annulés, afin d'éviter les déploiements partiels.
- Lors de l'utilisation du comportement par défaut ou de `workflow:auto_cancel:on_new_commit: conservative` :
  - Un job qui n'a pas encore démarré est toujours considéré comme `interruptible: true`, quelle que soit la configuration du job. La configuration `interruptible` n'est prise en compte qu'après le démarrage du job.
  - Les pipelines **En cours** ne sont annulés que si tous les jobs en cours sont configurés avec `interruptible: true` ou si aucun job configuré avec `interruptible: false` n'a démarré à quelque moment que ce soit. Une fois qu'un job avec `interruptible: false` démarre, l'ensemble du pipeline n'est plus considéré comme interruptible.
  - Si le pipeline a déclenché un pipeline downstream, mais qu'aucun job avec `interruptible: false` dans le pipeline downstream n'a encore démarré, le pipeline downstream est également annulé.
- Vous pouvez ajouter un job manuel optionnel avec `interruptible: false` dans la première étape d'un pipeline pour permettre aux utilisateurs d'empêcher manuellement l'annulation automatique d'un pipeline. Une fois qu'un utilisateur démarre le job, le pipeline ne peut plus être annulé par la fonctionnalité **Annulation automatique des pipelines redondants**.
- Lors de l'utilisation de `interruptible` avec un [déclencheur de job](#trigger) :
  - Le pipeline downstream déclenché n'est jamais affecté par la configuration `interruptible` du déclencheur de job.
  - Si [`workflow:auto_cancel`](#workflowauto_cancelon_new_commit) est défini sur `conservative`, la configuration `interruptible` du déclencheur de job n'a aucun effet.
  - Si [`workflow:auto_cancel`](#workflowauto_cancelon_new_commit) est défini sur `interruptible`, un déclencheur de job avec `interruptible: true` peut être annulé automatiquement.

---

### `needs` {#needs}

Utilisez `needs` pour exécuter des jobs dans un ordre différent. Les relations entre les jobs qui utilisent `needs` peuvent être visualisées sous forme de [graphe acyclique dirigé](needs.md).

Vous pouvez ignorer l'ordre des étapes et exécuter certains jobs sans attendre que d'autres se terminent. Les jobs de plusieurs étapes peuvent s'exécuter simultanément.

**Type de mot-clé** : Mot-clé de job. Vous pouvez l'utiliser uniquement dans un job.

**Valeurs prises en charge** :

- Un tableau de jobs (50 jobs maximum).
- Un tableau vide (`[]`), pour que le job démarre dès que le pipeline est créé.

**Exemple de `needs`** :

```yaml
linux:build:
  stage: build
  script: echo "Building linux..."

mac:build:
  stage: build
  script: echo "Building mac..."

lint:
  stage: test
  needs: []
  script: echo "Linting..."

linux:rspec:
  stage: test
  needs: ["linux:build"]
  script: echo "Running rspec on linux..."

mac:rspec:
  stage: test
  needs: ["mac:build"]
  script: echo "Running rspec on mac..."

production:
  stage: deploy
  script: echo "Running production..."
  environment: production
```

Cet exemple crée quatre chemins d'exécution :

- Linter : Le job `lint` s'exécute immédiatement sans attendre que l'étape `build` se termine, car il n'a aucune dépendance (`needs: []`).
- Chemin Linux : Le job `linux:rspec` s'exécute dès que le job `linux:build` se termine, sans attendre que `mac:build` se termine.
- Chemin macOS : Le job `mac:rspec` s'exécute dès que le job `mac:build` se termine, sans attendre que `linux:build` se termine.
- Le job `production` s'exécute dès que tous les jobs précédents se terminent : `lint`, `linux:build`, `linux:rspec`, `mac:build`, `mac:rspec`.

**Informations complémentaires** :

- Le nombre maximum de jobs qu'un seul job peut avoir dans le tableau `needs` est limité :
  - Pour GitLab.com, la limite est de 50. Pour plus d'informations, voir le [ticket 350398](https://gitlab.com/gitlab-org/gitlab/-/issues/350398).
  - Pour GitLab Self-Managed et GitLab Dedicated, la limite par défaut est de 50. Cette limite peut être modifiée en [mettant à jour les limites CI/CD dans la zone d'administration](../../administration/cicd/limits.md#maximum-number-of-needs-dependencies).
- Si `needs` fait référence à un job qui utilise le mot-clé [`parallel`](#parallel), il dépend de tous les jobs créés en parallèle, pas seulement d'un seul job. Il télécharge également les artefacts de tous les jobs parallèles par défaut. Si les artefacts ont le même nom, ils s'écrasent mutuellement et seul le dernier téléchargé est sauvegardé.
  - Pour que `needs` fasse référence à un sous-ensemble de jobs parallélisés (et non à la totalité des jobs parallélisés), utilisez le mot-clé [`needs:parallel:matrix`](#needsparallelmatrix).
- Vous pouvez faire référence à des jobs dans la même étape que le job que vous configurez.
- Si `needs` fait référence à un job qui pourrait ne pas être ajouté à un pipeline en raison de `only`, `except` ou `rules`, la création du pipeline pourrait échouer. Utilisez le mot-clé [`needs:optional`](#needsoptional) pour résoudre un échec de création de pipeline.
- Si un pipeline contient des jobs avec `needs: []` et des jobs à l'étape [`.pre`](#stage-pre), ils démarreront tous dès que le pipeline est créé. Les jobs avec `needs: []` démarrent immédiatement, et les jobs à l'étape `.pre` démarrent également immédiatement.

---

#### `needs:artifacts` {#needsartifacts}

Lorsqu'un job utilise `needs`, il ne télécharge plus par défaut tous les artefacts des étapes précédentes, car les jobs avec `needs` peuvent démarrer avant que les étapes antérieures ne se terminent. Avec `needs`, vous pouvez uniquement télécharger les artefacts des jobs listés dans la configuration `needs`.

Utilisez `artifacts: true` (par défaut) ou `artifacts: false` pour contrôler le moment où les artefacts sont téléchargés dans les jobs qui utilisent `needs`.

**Type de mot-clé** : Mot-clé de job. Vous pouvez l'utiliser uniquement dans un job. Doit être utilisé avec `needs:job`.

**Valeurs prises en charge** :

- `true` (par défaut) ou `false`.

**Exemple de `needs:artifacts`** :

```yaml
test-job1:
  stage: test
  needs:
    - job: build_job1
      artifacts: true

test-job2:
  stage: test
  needs:
    - job: build_job2
      artifacts: false

test-job3:
  needs:
    - job: build_job1
      artifacts: true
    - job: build_job2
    - build_job3
```

Dans cet exemple :

- Le `test-job1` job télécharge les artefacts de `build_job1`
- Le `test-job2` job ne télécharge pas les artefacts de `build_job2`.
- Le `test-job3` job télécharge les artefacts des trois `build_jobs`, car `artifacts` est `true`, ou utilise la valeur par défaut `true`, pour les trois jobs requis.

**Informations complémentaires** :

- Il est déconseillé de combiner `needs` avec [`dependencies`](#dependencies) dans le même job.

---

#### `needs:project` {#needsproject}

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Utilisez `needs:project` pour télécharger des artefacts depuis cinq jobs au maximum dans d'autres pipelines. Les artefacts sont téléchargés depuis la dernière exécution réussie du job spécifié pour la référence spécifiée. Pour spécifier plusieurs jobs, ajoutez chacun d'eux en tant qu'élément de tableau distinct sous le mot-clé `needs`.

Si un pipeline est en cours d'exécution pour la référence, un job avec `needs:project` n'attend pas que le pipeline se termine. À la place, les artefacts sont téléchargés depuis la dernière exécution réussie du job spécifié.

`needs:project` doit être utilisé avec `job`, `ref` et `artifacts`.

**Type de mot-clé** : Mot-clé de job. Vous pouvez l'utiliser uniquement dans un job.

**Valeurs prises en charge** :

- `needs:project` : Un chemin de projet complet, incluant l'espace de nommage et le groupe.
- `job` : Le job à partir duquel télécharger les artefacts.
- `ref` : La référence à partir de laquelle télécharger les artefacts.
- `artifacts` : Doit être `true` pour télécharger les artefacts.

**Exemples de `needs:project`** :

```yaml
build_job:
  stage: build
  script:
    - ls -lhR
  needs:
    - project: namespace/group/project-name
      job: build-1
      ref: main
      artifacts: true
    - project: namespace/group/project-name-2
      job: build-2
      ref: main
      artifacts: true
```

Dans cet exemple, `build_job` télécharge les artefacts des dernières exécutions réussies des jobs `build-1` et `build-2` sur les branches `main` dans les projets `group/project-name` et `group/project-name-2`.

Vous pouvez utiliser des [variables CI/CD](../variables/where_variables_can_be_used.md#gitlab-ciyml-file) dans `needs:project`, par exemple :

```yaml
build_job:
  stage: build
  script:
    - ls -lhR
  needs:
    - project: $CI_PROJECT_PATH
      job: $DEPENDENCY_JOB_NAME
      ref: $ARTIFACTS_DOWNLOAD_REF
      artifacts: true
```

**Informations complémentaires** :

- Pour télécharger des artefacts depuis un autre pipeline du projet actuel, définissez `project` comme étant le même que le projet actuel, mais utilisez une référence différente de celle du pipeline actuel. Des pipelines s'exécutant simultanément sur la même référence pourraient écraser les artefacts.
- L'utilisateur qui exécute le pipeline doit avoir le rôle Reporter, Developer, Maintainer ou Owner pour le groupe ou le projet, ou le groupe/projet doit avoir une visibilité publique.
- Vous ne pouvez pas utiliser `needs:project` dans le même job que [`trigger`](#trigger).
- Lors de l'utilisation de `needs:project` pour télécharger des artefacts depuis un autre pipeline, le job n'attend pas que le job requis se termine. [L'utilisation de `needs` pour attendre la fin des jobs](needs.md) est limitée aux jobs du même pipeline. Assurez-vous que le job requis dans l'autre pipeline se termine avant que le job qui en dépend tente de télécharger les artefacts.
- Vous ne pouvez pas télécharger des artefacts depuis des jobs qui s'exécutent dans [`parallel`](#parallel).
- Prise en charge des [variables CI/CD](../variables/_index.md) dans `project`, `job` et `ref`.

**Sujets connexes** :

- Pour télécharger des artefacts entre des [pipelines parent-enfant](../pipelines/downstream_pipelines.md#parent-child-pipelines), utilisez [`needs:pipeline:job`](#needspipelinejob).

---

#### `needs:pipeline:job` {#needspipelinejob}

Un [pipeline enfant](../pipelines/downstream_pipelines.md#parent-child-pipelines) peut télécharger des artefacts depuis un job terminé avec succès dans son pipeline parent ou dans un autre pipeline enfant de la même hiérarchie de pipeline parent-enfant.

**Type de mot-clé** : Mot-clé de job. Vous pouvez l'utiliser uniquement dans un job.

**Valeurs prises en charge** :

- `needs:pipeline` : Un identifiant de pipeline. Doit être un pipeline présent dans la même hiérarchie de pipeline parent-enfant.
- `job` : Le job à partir duquel télécharger les artefacts.

**Exemple de `needs:pipeline:job`** :

- Pipeline parent (`.gitlab-ci.yml`) :

  ```yaml
  stages:
    - build
    - test

  create-artifact:
    stage: build
    script: echo "sample artifact" > artifact.txt
    artifacts:
      paths: [artifact.txt]

  child-pipeline:
    stage: test
    trigger:
      include: child.yml
      strategy: mirror
    variables:
      PARENT_PIPELINE_ID: $CI_PIPELINE_ID
  ```

- Pipeline enfant (`child.yml`) :

  ```yaml
  use-artifact:
    script: cat artifact.txt
    needs:
      - pipeline: $PARENT_PIPELINE_ID
        job: create-artifact
  ```

Dans cet exemple, le `create-artifact` job dans le pipeline parent crée des artefacts. Le `child-pipeline` job déclenche un pipeline enfant et transmet la variable `CI_PIPELINE_ID` au pipeline enfant en tant que nouvelle variable `PARENT_PIPELINE_ID`. Le pipeline enfant peut utiliser cette variable dans `needs:pipeline` pour télécharger des artefacts depuis le pipeline parent. Le fait d'avoir les jobs `create-artifact` et `child-pipeline` dans des étapes successives garantit que le `use-artifact` job ne s'exécute que lorsque `create-artifact` s'est terminé avec succès.

**Informations complémentaires** :

- L'attribut `pipeline` n'accepte pas l'identifiant du pipeline actuel (`$CI_PIPELINE_ID`). Pour télécharger des artefacts depuis un job du pipeline actuel, utilisez [`needs:artifacts`](#needsartifacts).
- Vous ne pouvez pas utiliser `needs:pipeline:job` dans un [job de déclenchement](#trigger), ni pour récupérer des artefacts depuis un [pipeline multi-projets](../pipelines/downstream_pipelines.md#multi-project-pipelines). Pour récupérer des artefacts depuis un pipeline multi-projets, utilisez [`needs:project`](#needsproject).
- Le job répertorié dans `needs:pipeline:job` doit se terminer avec un statut `success` pour que les artefacts puissent être récupérés. [Issue 367229](https://gitlab.com/gitlab-org/gitlab/-/issues/367229) propose d'autoriser la récupération d'artefacts depuis n'importe quel job disposant d'artefacts.

---

#### `needs:optional` {#needsoptional}

Pour qu'un job qui n'existe parfois pas dans le pipeline soit requis, ajoutez `optional: true` à la configuration `needs`. Si non défini, `optional: false` est la valeur par défaut.

Les jobs qui utilisent [`rules`](#rules), [`only` ou `except`](deprecated_keywords.md#only--except) et qui sont ajoutés avec [`include`](#include) peuvent ne pas toujours être ajoutés à un pipeline. GitLab vérifie les relations `needs` avant de démarrer un pipeline :

- Si l'entrée `needs` comporte `optional: true` et que le job requis est présent dans le pipeline, le job attend sa fin avant de démarrer.
- Si le job requis n'est pas présent, le job peut démarrer lorsque toutes les autres exigences sont satisfaites.
- Si la section `needs` ne contient que des jobs optionnels et qu'aucun n'est ajouté au pipeline, le job démarre immédiatement (comme une entrée `needs` vide : `needs: []`).
- Si un job requis a `optional: false` mais n'a pas été ajouté au pipeline, le pipeline échoue au démarrage avec une erreur du type : `'job1' job needs 'job2' job, but it was not added to the pipeline`.

**Type de mot-clé** : Mot-clé de job. Vous pouvez l'utiliser uniquement dans un job.

**Exemple de `needs:optional`** :

```yaml
build-job:
  stage: build

test-job1:
  stage: test

test-job2:
  stage: test
  rules:
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH

deploy-job:
  stage: deploy
  needs:
    - job: test-job2
      optional: true
    - job: test-job1
  environment: production

review-job:
  stage: deploy
  needs:
    - job: test-job2
      optional: true
  environment: review
```

Dans cet exemple :

- `build-job`, `test-job1` et `test-job2` démarrent selon l'ordre des étapes.
- Lorsque la branche est la branche par défaut, `test-job2` est ajouté au pipeline, ainsi :
  - `deploy-job` attend que `test-job1` et `test-job2` se terminent.
  - `review-job` attend que `test-job2` se termine.
- Lorsque la branche n'est pas la branche par défaut, `test-job2` n'est pas ajouté au pipeline, ainsi :
  - `deploy-job` attend uniquement que `test-job1` se termine et n'attend pas le `test-job2` manquant.
  - `review-job` n'a aucun autre job requis et démarre immédiatement (en même temps que `build-job`), comme `needs: []`.

**Informations complémentaires** :

- Vous ne pouvez pas utiliser `needs:optional` avec [`needs:parallel:matrix`](#needsparallelmatrix).

---

#### `needs:pipeline` {#needspipeline}

Vous pouvez reproduire le statut d'un pipeline upstream dans un job en utilisant le mot-clé `needs:pipeline`. Le dernier statut du pipeline de la branche par défaut est répliqué vers le job.

**Type de mot-clé** : Mot-clé de job. Vous pouvez l'utiliser uniquement dans un job.

**Valeurs prises en charge** :

- Un chemin de projet complet, incluant l'espace de nommage et le groupe. Si le projet est dans le même groupe ou espace de nommage, vous pouvez les omettre du mot-clé `project`. Par exemple : `project: group/project-name` ou `project: project-name`.

**Exemple de `needs:pipeline`** :

```yaml
upstream_status:
  stage: test
  needs:
    pipeline: other/project
```

**Informations complémentaires** :

- Si vous ajoutez le mot-clé `job` à `needs:pipeline`, le job ne reproduit plus le statut du pipeline. Le comportement change pour adopter celui de [`needs:pipeline:job`](#needspipelinejob).

---

#### `needs:parallel:matrix` {#needsparallelmatrix}

{{< history >}}

- [Introduite](https://gitlab.com/gitlab-org/gitlab/-/issues/254821) dans GitLab 16.3.

{{< /history >}}

Les jobs peuvent utiliser [`parallel:matrix`](#parallelmatrix) pour exécuter un job plusieurs fois en parallèle dans un même pipeline, mais avec des valeurs de variables différentes pour chaque instance du job.

Utilisez `needs:parallel:matrix` pour exécuter des jobs dans le désordre en fonction de jobs parallélisés.

**Type de mot-clé** : Mot-clé de job. Vous pouvez l'utiliser uniquement dans un job. Doit être utilisé avec `needs:job`.

**Valeurs prises en charge** : Un tableau de tables de hachage d'identifiants de matrice :

- Les identifiants et les valeurs doivent être sélectionnés parmi les identifiants et les valeurs définis dans le `parallel:matrix` job.
- Vous pouvez utiliser des [expressions de matrice](matrix_expressions.md).

**Exemple de `needs:parallel:matrix`** :

```yaml
linux:build:
  stage: build
  script: echo "Building linux..."
  parallel:
    matrix:
      - PROVIDER: aws
        STACK:
          - monitoring
          - app1
          - app2

linux:rspec:
  stage: test
  needs:
    - job: linux:build
      parallel:
        matrix:
          - PROVIDER: aws
            STACK: app1
  script: echo "Running rspec on linux..."
```

L'exemple précédent génère les jobs suivants :

```plaintext
linux:build: [aws, monitoring]
linux:build: [aws, app1]
linux:build: [aws, app2]
linux:rspec
```

Le `linux:rspec` job s'exécute dès que le `linux:build: [aws, app1]` job se termine.

**Informations complémentaires** :

- Vous ne pouvez pas utiliser `needs:parallel:matrix` avec [`needs:optional`](#needsoptional).
- L'ordre des identifiants de matrice dans `needs:parallel:matrix` doit correspondre à l'ordre des variables de matrice dans le job requis. Par exemple, inverser l'ordre des variables dans le `linux:rspec` job dans l'exemple précédent serait invalide :

  ```yaml
  linux:rspec:
    stage: test
    needs:
      - job: linux:build
        parallel:
          matrix:
            - STACK: app1        # The variable order does not match `linux:build` and is invalid.
              PROVIDER: aws
    script: echo "Running rspec on linux..."
  ```

**Sujets connexes** :

- [Spécifier un job parallélisé en utilisant needs avec plusieurs jobs parallélisés](../jobs/job_control.md#specify-a-parallelized-job-using-needs-with-multiple-parallelized-jobs).
- [Expressions de matrice dans `needs:parallel:matrix`](matrix_expressions.md#matrix-expressions-in-needsparallelmatrix).

### `pages` {#pages}

Utilisez `pages` pour définir un job [GitLab Pages](../../user/project/pages/_index.md) qui charge du contenu statique vers GitLab. Le contenu est ensuite publié sous forme de site web.

Vous devez :

- Définir `pages: true` pour publier un répertoire nommé `public`
- Vous pouvez également définir [`pages.publish`](#pagespublish) si vous souhaitez utiliser un autre répertoire de contenu.
- Avoir un fichier `index.html` non vide à la racine du répertoire de contenu.

**Type de mot-clé** : Mot-clé de job ou nom de job (déprécié). Vous pouvez l'utiliser uniquement dans un job.

**Valeurs prises en charge** :

- Un booléen. Utilise la configuration par défaut lorsque défini sur `true`
- Une table de hachage d'options de configuration ; consultez les sections suivantes pour plus de détails.

**Exemple de `pages`** :

```yaml
create-pages:
  stage: deploy
  script:
    - mv my-html-content public
  pages: true  # specifies that this is a Pages job and publishes the default public directory
  rules:
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH
  environment: production
```

Cet exemple renomme le répertoire `my-html-content/` en `public/`. Ce répertoire est exporté en tant qu'artefact et publié avec GitLab Pages.

**Exemple utilisant un hash de configuration** :

```yaml
create-pages:
  stage: deploy
  script:
    - echo "nothing to do here"
  pages:  # specifies that this is a Pages job and publishes the default public directory
    publish: my-html-content
    expire_in: "1 week"
  rules:
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH
  environment: production
```

Cet exemple ne déplace pas le répertoire, mais utilise directement la propriété `publish`. Il configure également le déploiement Pages pour qu'il soit dépublié après une semaine.

**Informations complémentaires** :

- L'utilisation de `pages` comme nom de job [est dépréciée](deprecated_keywords.md#publish-keyword-and-pages-job-name-for-gitlab-pages).
- Pour utiliser `pages` comme nom de job sans déclencher de déploiement Pages, définissez la propriété `pages` sur false

---

#### `pages.publish` {#pagespublish}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/415821) dans GitLab 16.1.
- [Modifié](https://gitlab.com/gitlab-org/gitlab/-/issues/500000) pour autoriser les variables lorsqu'elles sont transmises à la propriété `publish` dans GitLab 17.9.
- [Déplacement](https://gitlab.com/gitlab-org/gitlab/-/issues/428018) de la propriété `publish` sous le mot-clé `pages` dans GitLab 17.9.
- [Ajout automatique](https://gitlab.com/gitlab-org/gitlab/-/issues/428018) du chemin `pages.publish` à `artifacts:paths` dans GitLab 17.10.

{{< /history >}}

Utilisez `pages.publish` pour configurer le répertoire de contenu d'un [job `pages`](#pages).

**Type de mot-clé** : Mot-clé de job. Vous pouvez l'utiliser uniquement dans le cadre d'un `pages` job.

**Valeurs prises en charge** : Un chemin vers un répertoire contenant le contenu Pages. Dans [GitLab 17.10 et versions ultérieures](https://gitlab.com/gitlab-org/gitlab/-/issues/428018), si non spécifié, le répertoire par défaut `public` est utilisé et si spécifié, ce chemin est automatiquement ajouté à [`artifacts:paths`](#artifactspaths).

**Exemple de `pages.publish`** :

```yaml
create-pages:
  stage: deploy
  script:
    - npx @11ty/eleventy --input=path/to/eleventy/root --output=dist
  pages:
    publish: dist  # this path is automatically appended to artifacts:paths
  rules:
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH
  environment: production
```

Cet exemple utilise [Eleventy](https://www.11ty.dev) pour générer un site web statique et exporte les fichiers HTML générés dans le répertoire `dist/`. Ce répertoire est exporté en tant qu'artefact et publié avec GitLab Pages.

Il est également possible d'utiliser des variables dans le champ `pages.publish`. Par exemple :

```yaml
create-pages:
  stage: deploy
  script:
    - mkdir -p $CUSTOM_FOLDER/$CUSTOM_PATH
    - cp -r public $CUSTOM_FOLDER/$CUSTOM_SUBFOLDER
  pages:
    publish: $CUSTOM_FOLDER/$CUSTOM_SUBFOLDER  # this path is automatically appended to artifacts:paths
  rules:
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH
  variables:
    CUSTOM_FOLDER: "custom_folder"
    CUSTOM_SUBFOLDER: "custom_subfolder"
```

Le chemin de publication spécifié doit être relatif à la racine du build.

**Informations complémentaires** :

- Le mot-clé `publish` de niveau supérieur [est déprécié](deprecated_keywords.md#publish-keyword-and-pages-job-name-for-gitlab-pages) et doit désormais être imbriqué sous le mot-clé `pages`

---

#### `pages.path_prefix` {#pagespath_prefix}

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Statut : Version bêta

{{< /details >}}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/129534) dans GitLab 16.7 en tant que [version expérimentale](../../policy/development_stages_support.md) [avec un indicateur](../../administration/feature_flags/_index.md) nommé `pages_multiple_versions_setting`, désactivé par défaut.
- [Activé sur GitLab.com, GitLab Self-Managed et GitLab Dedicated](https://gitlab.com/gitlab-org/gitlab/-/issues/422145) dans GitLab 17.4.
- [Modifié](https://gitlab.com/gitlab-org/gitlab/-/issues/507423) pour autoriser les points dans GitLab 17.8.
- [Généralement disponible](https://gitlab.com/gitlab-org/gitlab/-/issues/487161) dans GitLab 17.9. Le feature flag `pages_multiple_versions_setting` a été supprimé.

{{< /history >}}

Utilisez `pages.path_prefix` pour configurer un préfixe de chemin pour les [déploiements parallèles](../../user/project/pages/_index.md#parallel-deployments) de GitLab Pages.

**Type de mot-clé** : Mot-clé de job. Vous pouvez l'utiliser uniquement dans le cadre d'un `pages` job.

**Valeurs prises en charge** :

- Une chaîne de caractères
- [Variables CI/CD](../variables/where_variables_can_be_used.md#gitlab-ciyml-file)
- Une combinaison des deux

La valeur donnée est convertie en minuscules et raccourcie à 63 octets. Tout caractère autre qu'un caractère alphanumérique ou un point est remplacé par un tiret. Les tirets ou les points en début et en fin de valeur ne sont pas autorisés.

**Exemple de `pages.path_prefix`** :

```yaml
create-pages:
  stage: deploy
  script:
    - echo "Pages accessible through ${CI_PAGES_URL}"
  pages:  # specifies that this is a Pages job and publishes the default public directory
    path_prefix: "$CI_COMMIT_BRANCH"
```

Dans cet exemple, un déploiement Pages différent est créé pour chaque branche.

---

#### `pages.expire_in` {#pagesexpire_in}

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/456478) dans GitLab 17.4.
- Prise en charge des variables [introduite](https://gitlab.com/gitlab-org/gitlab/-/issues/492289) dans GitLab 17.11.

{{< /history >}}

Utilisez `expire_in` pour spécifier la durée pendant laquelle un déploiement doit être disponible avant d'expirer. Une fois le déploiement expiré, il est désactivé par un job cron s'exécutant toutes les 10 minutes.

Par défaut, les [déploiements parallèles](../../user/project/pages/_index.md#parallel-deployments) expirent automatiquement après 24 heures. Pour désactiver ce comportement, définissez la valeur sur `never`.

**Type de mot-clé** : Mot-clé de job. Vous pouvez l'utiliser uniquement dans le cadre d'un `pages` job.

**Valeurs prises en charge** : La durée d'expiration. Si aucune unité n'est fournie, la durée est en secondes. Les variables sont également prises en charge. Les valeurs valides comprennent :

- `'42'`
- `42 seconds`
- `3 mins 4 sec`
- `2 hrs 20 min`
- `2h20min`
- `6 mos 1 day`
- `47 yrs 6 mos and 4d`
- `3 weeks and 2 days`
- `never`
- `$DURATION`

**Exemple de `pages.expire_in`** :

```yaml
create-pages:
  stage: deploy
  script:
    - echo "Pages accessible through ${CI_PAGES_URL}"
  pages:  # specifies that this is a Pages job and publishes the default public directory
    expire_in: 1 week
```

---

### `parallel` {#parallel}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/336576) dans GitLab 15.9, la valeur maximale de `parallel` passe de 50 à 200.

{{< /history >}}

Utilisez `parallel` pour exécuter un job plusieurs fois en parallèle dans un même pipeline.

Plusieurs runners doivent exister, ou un seul runner doit être configuré pour exécuter plusieurs jobs simultanément.

Les jobs parallèles sont nommés séquentiellement de `job_name 1/N` à `job_name N/N`.

**Type de mot-clé** : Mot-clé de job. Vous pouvez l'utiliser uniquement dans un job.

**Valeurs prises en charge** :

- Une valeur numérique comprise entre `1` et `200`.

**Exemple de `parallel`** :

```yaml
test:
  script: rspec
  parallel: 5
```

Cet exemple crée 5 jobs s'exécutant en parallèle, nommés de `test 1/5` à `test 5/5`.

**Informations complémentaires** :

- Chaque job parallèle dispose d'une [variable CI/CD prédéfinie](../variables/_index.md#predefined-cicd-variables) `CI_NODE_INDEX` et `CI_NODE_TOTAL`.
- Un pipeline avec des jobs qui utilisent `parallel` peut :
  - Créer plus de jobs s'exécutant en parallèle que de runners disponibles. Les jobs excédentaires sont mis en file d'attente et marqués `pending` en attendant qu'un runner soit disponible.
  - Échouer avec une erreur `job_activity_limit_exceeded` si la création du pipeline amènerait le nombre total de jobs dans tous les pipelines actifs à [dépasser la limite de l'instance](../../administration/cicd/limits.md#number-of-jobs-in-active-pipelines).

**Sujets connexes** :

- [Paralléliser les grands jobs](../jobs/job_control.md#parallelize-large-jobs).

---

#### `parallel:matrix` {#parallelmatrix}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/336576) dans GitLab 15.9, le nombre maximum de permutations passe de 50 à 200.

{{< /history >}}

Utilisez `parallel:matrix` pour exécuter un job plusieurs fois en parallèle dans un même pipeline, mais avec des valeurs de variables différentes pour chaque instance du job.

Plusieurs runners doivent exister, ou un seul runner doit être configuré pour exécuter plusieurs jobs simultanément.

**Type de mot-clé** : Mot-clé de job. Vous pouvez l'utiliser uniquement dans un job.

**Valeurs prises en charge** : Un tableau de tables de hachage de variables :

- Les identifiants de matrice, qui deviennent les noms de variables, ne peuvent utiliser que des chiffres, des lettres et des tirets bas (`_`).
- Les valeurs doivent être soit une chaîne de caractères, soit un tableau de chaînes de caractères.
- Le nombre de permutations ne peut pas dépasser 200.

**Exemple de `parallel:matrix`** :

```yaml
deploystacks:
  stage: deploy
  script:
    - bin/deploy
  parallel:
    matrix:
      - PROVIDER: aws
        STACK:
          - monitoring
          - app1
          - app2
      - PROVIDER: [gcp, vultr]
        STACK: [data, processing]
  environment: $PROVIDER/$STACK
```

L'exemple génère 7 `deploystacks` jobs parallèles, chacun avec des valeurs différentes pour `PROVIDER` et `STACK` :

- `deploystacks: [aws, monitoring]`
- `deploystacks: [aws, app1]`
- `deploystacks: [aws, app2]`
- `deploystacks: [gcp, data]`
- `deploystacks: [gcp, processing]`
- `deploystacks: [vultr, data]`
- `deploystacks: [vultr, processing]`

**Informations complémentaires** :

- Les jobs `parallel:matrix` ajoutent les valeurs de la matrice aux noms des jobs pour les différencier les uns des autres. Cependant, des valeurs longues peuvent entraîner des noms de jobs dépassant la limite de 255 caractères. Pour plus d'informations, consultez [l'epic 11791](https://gitlab.com/groups/gitlab-org/-/work_items/11791).
- Les valeurs des variables de matrice sont disponibles en tant que variables CI/CD dans les expressions [`rules:if`](#rulesif). Pour plus d'informations, consultez [Utiliser les variables de matrice dans `rules:if`](../jobs/job_control.md#use-matrix-variables-in-rulesif).
- Vous ne pouvez pas créer plusieurs configurations de matrice avec les mêmes valeurs mais des noms différents. Les noms des jobs sont générés à partir des valeurs de la matrice, et non des noms ; ainsi, les entrées de matrice avec des valeurs identiques génèrent des noms de jobs identiques qui s'écrasent mutuellement.

  Par exemple, cette configuration `test` tenterait de créer deux séries de jobs identiques, mais les versions `OS2` écraseraient les versions `OS` :

  ```yaml
  test:
    parallel:
      matrix:
        - OS: [ubuntu]
          PROVIDER: [aws, gcp]
        - OS2: [ubuntu]
          PROVIDER: [aws, gcp]
  ```

**Sujets connexes** :

- [Exécuter une matrice unidimensionnelle de jobs parallèles](../jobs/job_control.md#run-a-one-dimensional-matrix-of-parallel-jobs).
- [Exécuter une matrice de jobs de déclenchement parallèles](../jobs/job_control.md#run-a-matrix-of-parallel-trigger-jobs).
- [Sélectionner différentes étiquettes de runner pour chaque job de matrice parallèle](../jobs/job_control.md#select-different-runner-tags-for-each-parallel-matrix-job).
- [Utiliser les variables de matrice dans les règles](../jobs/job_control.md#use-matrix-variables-in-rules).
- [Expressions de matrice dans `needs:parallel:matrix`](matrix_expressions.md#matrix-expressions-in-needsparallelmatrix).

---

### `release` {#release}

Utilisez `release` pour créer une [release](../../user/project/releases/_index.md).

Le job de release doit avoir accès à la [CLI `glab`](https://gitlab.com/gitlab-org/cli), qui doit se trouver dans le `$PATH`.

Si vous utilisez l'[exécuteur Docker](https://docs.gitlab.com/runner/executors/docker/), vous pouvez utiliser cette image depuis le registre de conteneurs GitLab : `registry.gitlab.com/gitlab-org/cli:latest`

Si vous utilisez l'[exécuteur Shell](https://docs.gitlab.com/runner/executors/shell/) ou similaire, [installez la CLI `glab`](https://gitlab.com/gitlab-org/cli#installation) sur le serveur où le runner est enregistré.

**Type de mot-clé** : Mot-clé de job. Vous pouvez l'utiliser uniquement dans un job.

**Valeurs prises en charge** : Les sous-clés de `release` :

- [`tag_name`](#releasetag_name)
- [`tag_message`](#releasetag_message) (optionnel)
- [`name`](#releasename) (optionnel)
- [`description`](#releasedescription)
- [`ref`](#releaseref) (optionnel)
- [`milestones`](#releasemilestones) (optionnel)
- [`released_at`](#releasereleased_at) (optionnel)
- [`assets:links`](#releaseassetslinks) (optionnel)

**Exemple de mot-clé `release`** :

```yaml
release_job:
  stage: release
  image: registry.gitlab.com/gitlab-org/cli:latest
  rules:
    - if: $CI_COMMIT_TAG                  # Run this job when a tag is created manually
  script:
    - echo "Running the release job."
  release:
    tag_name: $CI_COMMIT_TAG
    name: 'Release $CI_COMMIT_TAG'
    description: 'Release created using the CLI.'
```

Cet exemple crée une release :

- Lorsque vous poussez un tag Git.
- Lorsque vous ajoutez un tag Git dans l'interface utilisateur via **Code** > **Étiquettes**.

**Informations complémentaires** :

- Les jobs de release doivent inclure le mot-clé `script`. Un job de release peut utiliser la sortie des commandes de script. Si vous n'avez pas besoin du script, vous pouvez utiliser un espace réservé :

  ```yaml
  script:
    - echo "release job"
  ```

  Pour plus de détails, consultez [l'issue 223856](https://gitlab.com/gitlab-org/gitlab/-/issues/223856), qui vise à supprimer cette restriction.

- La section `release` s'exécute après le mot-clé `script` et avant le `after_script`.
- Une release n'est créée que si le script principal du job réussit.
- Si la release existe déjà, elle n'est pas mise à jour et le job avec le mot-clé `release` échoue.

**Sujets connexes** :

- [Exemple CI/CD du mot-clé `release`](../../user/project/releases/_index.md#creating-a-release-by-using-a-cicd-job).
- [Créer plusieurs releases dans un même pipeline](../../user/project/releases/_index.md#create-multiple-releases-in-a-single-pipeline).
- [Utiliser une autorité de certification SSL personnalisée](../../user/project/releases/_index.md#use-a-custom-ssl-ca-certificate-authority).

---

#### `release:tag_name` {#releasetag_name}

Obligatoire. Le tag Git pour la release.

Si le tag n'existe pas encore dans le projet, il est créé en même temps que la release. Les nouveaux tags utilisent le SHA associé au pipeline.

**Type de mot-clé** : Mot-clé de job. Vous pouvez l'utiliser uniquement dans un job.

**Valeurs prises en charge** :

- Un nom de tag.

Les variables CI/CD [sont prises en charge](../variables/where_variables_can_be_used.md#gitlab-ciyml-file).

**Exemple de `release:tag_name`** :

Pour créer une release lorsqu'un nouveau tag est ajouté au projet :

- Utilisez la variable CI/CD `$CI_COMMIT_TAG` comme `tag_name`.
- Utilisez [`rules:if`](#rulesif) pour configurer le job afin qu'il s'exécute uniquement pour les nouveaux tags.

```yaml
job:
  script: echo "Running the release job for the new tag."
  release:
    tag_name: $CI_COMMIT_TAG
    description: 'Release description'
  rules:
    - if: $CI_COMMIT_TAG
```

Pour créer une release et un nouveau tag simultanément, vos [`rules`](#rules) ne doivent pas configurer le job pour qu'il s'exécute uniquement pour les nouveaux tags. Un exemple de gestion sémantique de version :

```yaml
job:
  script: echo "Running the release job and creating a new tag."
  release:
    tag_name: ${MAJOR}_${MINOR}_${REVISION}
    description: 'Release description'
  rules:
    - if: $CI_PIPELINE_SOURCE == "schedule"
```

---

#### `release:tag_message` {#releasetag_message}

Si le tag n'existe pas, le tag nouvellement créé est annoté avec le message spécifié par `tag_message`. Si omis, un tag léger est créé.

**Type de mot-clé** : Mot-clé de job. Vous pouvez l'utiliser uniquement dans un job.

**Valeurs prises en charge** :

- Une chaîne de texte.

**Exemple de `release:tag_message`** :

```yaml
  release_job:
    stage: release
    release:
      tag_name: $CI_COMMIT_TAG
      description: 'Release description'
      tag_message: 'Annotated tag message'
```

---

#### `release:name` {#releasename}

Le nom de la release. Si omis, il est renseigné avec la valeur de `release: tag_name`.

**Type de mot-clé** : Mot-clé de job. Vous pouvez l'utiliser uniquement dans un job.

**Valeurs prises en charge** :

- Une chaîne de texte.

**Exemple de `release:name`** :

```yaml
  release_job:
    stage: release
    release:
      name: 'Release $CI_COMMIT_TAG'
```

---

#### `release:description` {#releasedescription}

La description longue de la release.

**Type de mot-clé** : Mot-clé de job. Vous pouvez l'utiliser uniquement dans un job.

**Valeurs prises en charge** :

- Une chaîne avec la description longue.
- Le chemin vers un fichier contenant la description.
  - L'emplacement du fichier doit être relatif au répertoire du projet (`$CI_PROJECT_DIR`).
  - Si le fichier est un lien symbolique, il doit se trouver dans le `$CI_PROJECT_DIR`.
  - Le `./path/to/file` et le nom du fichier ne peuvent pas contenir d'espaces.

**Exemple de `release:description`** :

```yaml
job:
  release:
    tag_name: ${MAJOR}_${MINOR}_${REVISION}
    description: './path/to/CHANGELOG.md'
```

**Informations complémentaires** :

- La `description` est évaluée par le shell qui exécute `glab`. Vous pouvez utiliser des variables CI/CD pour définir la description, mais certains shells [utilisent une syntaxe différente](../variables/job_scripts.md) pour référencer les variables. De même, certains shells peuvent nécessiter l'échappement de caractères spéciaux. Par exemple, les apostrophes inversées (`` ` ``) peuvent nécessiter d'être échappées avec une barre oblique inverse (` \ `).

---

#### `release:ref` {#releaseref}

La `ref` pour la release, si le `release: tag_name` n'existe pas encore.

**Type de mot-clé** : Mot-clé de job. Vous pouvez l'utiliser uniquement dans un job.

**Valeurs prises en charge** :

- Un SHA de commit, un autre nom de tag ou un nom de branche.

---

#### `release:milestones` {#releasemilestones}

Le titre de chaque jalon auquel la release est associée.

---

#### `release:released_at` {#releasereleased_at}

La date et l'heure auxquelles la release est prête.

**Valeurs prises en charge** :

- Une date entre guillemets exprimée au format ISO 8601.

**Exemple de `release:released_at`** :

```yaml
released_at: '2021-03-15T08:00:00Z'
```

**Informations complémentaires** :

- Si non défini, la date et l'heure actuelles sont utilisées.

---

#### `release:assets:links` {#releaseassetslinks}

Utilisez `release:assets:links` pour inclure des [liens vers des ressources](../../user/project/releases/release_fields.md#release-assets) dans la release.

**Exemple de `release:assets:links`** :

```yaml
assets:
  links:
    - name: 'asset1'
      url: 'https://example.com/assets/1'
    - name: 'asset2'
      url: 'https://example.com/assets/2'
      filepath: '/pretty/url/1' # optional
      link_type: 'other' # optional
```

---

### `resource_group` {#resource_group}

Utilisez `resource_group` pour créer un [groupe de ressources](../resource_groups/_index.md) qui garantit qu'un job est mutuellement exclusif entre différents pipelines pour le même projet.

Par exemple, si plusieurs jobs appartenant au même groupe de ressources sont mis en file d'attente simultanément, un seul des jobs démarre. Les autres jobs attendent que le `resource_group` soit libre.

Les groupes de ressources se comportent de manière similaire aux sémaphores dans d'autres langages de programmation.

Vous pouvez choisir un [mode de traitement](../resource_groups/_index.md#process-modes) pour contrôler stratégiquement la simultanéité des jobs selon vos préférences de déploiement. Le mode de traitement par défaut est `unordered`. Pour modifier le mode de traitement d'un groupe de ressources, utilisez l'[API](../../api/resource_groups.md#update-a-resource-group) pour envoyer une requête afin de modifier un groupe de ressources existant.

Vous pouvez définir plusieurs groupes de ressources par environnement. Par exemple, lors du déploiement sur des appareils physiques, vous pouvez avoir plusieurs appareils physiques. Chaque appareil peut recevoir un déploiement, mais un seul déploiement peut avoir lieu par appareil à un moment donné.

**Type de mot-clé** : Mot-clé de job. Vous pouvez l'utiliser uniquement dans un job.

**Valeurs prises en charge** :

- Uniquement des lettres, des chiffres, `-`, `_`, `/`, `$`, `{`, `}`, `.` et des espaces. Ne peut pas commencer ou se terminer par `/`. Les variables CI/CD [sont prises en charge](../variables/where_variables_can_be_used.md#gitlab-ciyml-file).

**Exemple de `resource_group`** :

```yaml
deploy-to-production:
  script: deploy
  resource_group: production
```

Dans cet exemple, deux `deploy-to-production` jobs dans deux pipelines distincts ne peuvent jamais s'exécuter en même temps. Ainsi, vous pouvez garantir qu'aucun déploiement simultané ne se produira dans l'environnement de production.

**Sujets connexes** :

- [Contrôle de la simultanéité au niveau du pipeline avec des pipelines multi-projets/parent-enfant](../resource_groups/_index.md#pipeline-level-concurrency-control-with-cross-projectparent-child-pipelines).

---

### `retry` {#retry}

Utilisez `retry` pour configurer le nombre de nouvelles tentatives d'un job en cas d'échec. Si non défini, la valeur par défaut est `0` et les jobs ne font pas l'objet de nouvelles tentatives.

En cas d'échec d'un job, celui-ci est traité jusqu'à deux fois supplémentaires, jusqu'à ce qu'il réussisse ou atteigne le nombre maximum de tentatives.

Par défaut, tous les types d'échec entraînent une nouvelle tentative pour le job. Utilisez [`retry:when`](#retrywhen) ou [`retry:exit_codes`](#retryexit_codes) pour sélectionner les types d'échec sur lesquels effectuer de nouvelles tentatives.

**Type de mot-clé** : Mot-clé de job. Vous pouvez l'utiliser uniquement dans un job ou dans la [section `default`](#default).

**Valeurs prises en charge** :

- `0` (par défaut), `1` ou `2`.

**Exemple de `retry`** :

```yaml
test:
  script: rspec
  retry: 2

test_advanced:
  script:
    - echo "Run a script that results in exit code 137."
    - exit 137
  retry:
    max: 2
    when: runner_system_failure
    exit_codes: 137
```

`test_advanced` fera l'objet de jusqu'à 2 nouvelles tentatives si le code de sortie est `137` ou en cas d'échec système du runner.

---

#### `retry:when` {#retrywhen}

Utilisez `retry:when` avec `retry:max` pour effectuer de nouvelles tentatives pour les jobs uniquement dans des cas d'échec spécifiques. `retry:max` est le nombre maximum de tentatives, comme pour [`retry`](#retry), et peut être `0`, `1` ou `2`.

**Type de mot-clé** : Mot-clé de job. Vous pouvez l'utiliser uniquement dans un job ou dans la [section `default`](#default).

**Valeurs prises en charge** :

- Un seul type d'échec, ou un tableau d'un ou plusieurs types d'échec :

<!--
  If you change any of the following values, make sure to update the `RETRY_WHEN_IN_DOCUMENTATION`
  array in `spec/lib/gitlab/ci/config/entry/retry_spec.rb`.
  The test there makes sure that all documented
  values are valid as a configuration option and therefore should always
  stay in sync with this documentation.
-->

- `always` : Réessayer en cas d'échec quelconque (par défaut).
- `unknown_failure` : Réessayer lorsque la raison de l'échec est inconnue.
- `script_failure` : Réessayer lorsque :
  - Le script a échoué.
  - Le runner n'a pas réussi à extraire l'image Docker. Pour les [exécuteurs](https://docs.gitlab.com/runner/executors/) `docker`, `docker+machine`, `kubernetes`.
- `api_failure` : Réessayer en cas d'échec de l'API.
- `stuck_or_timeout_failure` : Réessayer lorsque le job est bloqué ou a expiré.
- `runner_system_failure` : Réessayer en cas d'échec système du runner (par exemple, si la configuration du job a échoué).
- `runner_unsupported` : Réessayer si le runner n'est pas pris en charge.
- `stale_schedule` : Réessayer si un job différé n'a pas pu être exécuté.
- `job_execution_timeout` : Réessayer si le script a dépassé la durée maximale d'exécution définie pour le job.
- `archived_failure` : Réessayer si le job est archivé et ne peut pas être exécuté.
- `unmet_prerequisites` : Réessayer si le job n'a pas réussi à terminer les tâches prérequises.
- `scheduler_failure` : Réessayer si le planificateur n'a pas réussi à attribuer le job à un runner.
- `data_integrity_failure` : Réessayer en cas de problème inconnu avec le job.

**Exemple de `retry:when`** (type d'échec unique) :

```yaml
test:
  script: rspec
  retry:
    max: 2
    when: runner_system_failure
```

En cas d'échec autre qu'un échec système du runner, le job ne fait pas l'objet d'une nouvelle tentative.

**Exemple de `retry:when`** (tableau de types d'échec) :

```yaml
test:
  script: rspec
  retry:
    max: 2
    when:
      - runner_system_failure
      - stuck_or_timeout_failure
```

---

#### `retry:exit_codes` {#retryexit_codes}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/430037) dans GitLab 16.10 [avec un flag](../../administration/feature_flags/_index.md) nommé `ci_retry_on_exit_codes`. Désactivé par défaut.
- [Activé sur GitLab.com et GitLab Self-Managed](https://gitlab.com/gitlab-org/gitlab/-/issues/430037) dans GitLab 16.11.
- [Généralement disponible](https://gitlab.com/gitlab-org/gitlab/-/issues/452412) dans GitLab 17.5. Le feature flag `ci_retry_on_exit_codes` a été supprimé.

{{< /history >}}

Utilisez `retry:exit_codes` avec `retry:max` pour effectuer de nouvelles tentatives pour les jobs uniquement dans des cas d'échec spécifiques. `retry:max` est le nombre maximum de tentatives, comme pour [`retry`](#retry), et peut être `0`, `1` ou `2`.

**Type de mot-clé** : Mot-clé de job. Vous pouvez l'utiliser uniquement dans un job ou dans la [section `default`](#default).

**Valeurs prises en charge** :

- Un code de sortie unique.
- Un tableau de codes de sortie.

**Exemple de `retry:exit_codes`** :

```yaml
test_job_1:
  script:
    - echo "Run a script that results in exit code 1. This job isn't retried."
    - exit 1
  retry:
    max: 2
    exit_codes: 137

test_job_2:
  script:
    - echo "Run a script that results in exit code 137. This job will be retried."
    - exit 137
  retry:
    max: 1
    exit_codes:
      - 255
      - 137
```

**Sujets connexes** :

Vous pouvez spécifier le nombre de [tentatives pour certaines étapes de l'exécution du job](../runners/configure_runners.md#job-stages-attempts) à l'aide de variables.

---

### `rules` {#rules}

Utilisez `rules` pour inclure ou exclure des jobs dans les pipelines.

Les règles sont évaluées lors de la création du pipeline et évaluées dans l'ordre. Lorsqu'une correspondance est trouvée, aucune autre règle n'est vérifiée et le job est soit inclus, soit exclu du pipeline en fonction de la configuration. Si aucune règle ne correspond, le job n'est pas ajouté au pipeline.

`rules` accepte un tableau de règles. Chaque règle doit comporter au moins l'un des éléments suivants :

- `if`
- `changes`
- `exists`
- `when`

Les règles peuvent également être combinées en option avec :

- `allow_failure`
- `needs`
- `variables`
- `interruptible`

Vous pouvez combiner plusieurs mots-clés pour des [règles complexes](../jobs/job_rules.md#complex-rules).

Le job est ajouté au pipeline :

- Si une règle `if`, `changes` ou `exists` correspond et est configurée avec `when: on_success` (par défaut si non défini), `when: delayed` ou `when: always`.
- Si une règle est atteinte qui est uniquement `when: on_success`, `when: delayed` ou `when: always`.

Le job n'est pas ajouté au pipeline :

- Si aucune règle ne correspond.
- Si une règle correspond et a `when: never`.

Pour des exemples supplémentaires, consultez [Spécifier quand les jobs s'exécutent avec `rules`](../jobs/job_rules.md).

---

#### `rules:if` {#rulesif}

Utilisez des clauses `rules:if` pour spécifier quand ajouter un job à un pipeline :

- Si une instruction `if` est vraie, ajoutez le job au pipeline.
- Si une instruction `if` est vraie, mais qu'elle est combinée avec `when: never`, n'ajoutez pas le job au pipeline.
- Si une instruction `if` est fausse, vérifiez l'élément `rules` suivant (s'il en existe d'autres).

Les clauses `if` sont évaluées :

- En fonction des valeurs des [variables CI/CD](../variables/_index.md) ou des [variables CI/CD prédéfinies](../variables/predefined_variables.md), avec [quelques exceptions](../variables/where_variables_can_be_used.md#gitlab-ciyml-file).
- Dans l'ordre, en suivant le [flux d'exécution de `rules`](#rules).

**Type de mot-clé** : Spécifique au job et au pipeline. Vous pouvez l'utiliser dans un job pour configurer le comportement du job, ou avec [`workflow`](#workflow) pour configurer le comportement du pipeline.

**Valeurs prises en charge** :

- Une [expression de variable CI/CD](../jobs/job_rules.md#cicd-variable-expressions).

**Exemple de `rules:if`** :

```yaml
job:
  script: echo "Hello, Rules!"
  rules:
    - if: $CI_MERGE_REQUEST_SOURCE_BRANCH_NAME =~ /^feature/ && $CI_MERGE_REQUEST_TARGET_BRANCH_NAME != $CI_DEFAULT_BRANCH
      when: never
    - if: $CI_MERGE_REQUEST_SOURCE_BRANCH_NAME =~ /^feature/
      when: manual
      allow_failure: true
    - if: $CI_MERGE_REQUEST_SOURCE_BRANCH_NAME
```

**Informations complémentaires** :

- Vous ne pouvez pas utiliser de [variables imbriquées](../variables/where_variables_can_be_used.md#nested-variable-expansion) avec `if`. Consultez [l'issue 327780](https://gitlab.com/gitlab-org/gitlab/-/issues/327780) pour plus de détails.
- Si une règle correspond et n'a pas de `when` défini, la règle utilise le `when` défini pour le job, dont la valeur par défaut est `on_success` si non défini.
- Vous pouvez combiner `when` au niveau du job avec `when` dans les règles. La configuration `when` dans `rules` a la priorité sur `when` au niveau du job.
- Contrairement aux variables dans les sections [`script`](../variables/job_scripts.md), les variables dans les expressions de règles sont toujours formatées en tant que `$VARIABLE`.
  - Vous pouvez utiliser `rules:if` avec `include` pour [inclure d'autres fichiers de configuration de manière conditionnelle](includes.md#use-rules-with-include).
- Les variables CI/CD à droite des expressions `=~` et `!~` sont [évaluées comme des expressions régulières](../jobs/job_rules.md#store-a-regular-expression-in-a-variable).

**Sujets connexes** :

- [Expressions `if` courantes pour `rules`](../jobs/job_rules.md#common-if-clauses-with-predefined-variables).
- [Éviter les pipelines en double](../jobs/job_rules.md#avoid-duplicate-pipelines).
- [Utiliser `rules` pour exécuter des pipelines de merge request](../pipelines/merge_request_pipelines.md#configure-merge-request-pipelines).

---

#### `rules:changes` {#ruleschanges}

Utilisez `rules:changes` pour spécifier quand ajouter un job à un pipeline en vérifiant les modifications apportées à des fichiers spécifiques.

Pour les nouveaux pipelines de branche ou lorsqu'il n'y a pas d'événement Git `push`, `rules: changes` s'évalue toujours à true et le job s'exécute toujours. Les pipelines tels que les pipelines de tags, les pipelines planifiés et les pipelines manuels n'ont pas d'événement Git `push` associé. Pour couvrir ces cas, utilisez [`rules: changes: compare_to`](#ruleschangescompare_to) pour spécifier la branche à comparer à la référence du pipeline.

Si vous n'utilisez pas `compare_to`, vous devriez utiliser `rules: changes` uniquement avec des [pipelines de branche](../pipelines/pipeline_types.md#branch-pipeline) ou des [pipelines de merge request](../pipelines/merge_request_pipelines.md), même si `rules: changes` s'évalue toujours à true lors de la création d'une nouvelle branche. Avec :

- Pour les pipelines de merge request, `rules:changes` compare les modifications avec la branche MR cible.
- Pour les pipelines de branche, `rules:changes` compare les modifications avec le commit précédent sur la branche.

**Type de mot-clé** : Mot-clé de job. Vous pouvez l'utiliser uniquement dans un job.

**Valeurs prises en charge** :

Un tableau comprenant un nombre quelconque de :

- Chemins vers des fichiers. Les chemins de fichiers peuvent inclure des [variables CI/CD](../variables/where_variables_can_be_used.md#gitlab-ciyml-file).
- Chemins génériques pour :
  - Des répertoires individuels, par exemple `path/to/directory/*`.
  - Un répertoire et tous ses sous-répertoires, par exemple `path/to/directory/**/*`.
- Chemins [glob](https://en.wikipedia.org/wiki/Glob_(programming)) génériques pour tous les fichiers avec la même extension ou plusieurs extensions, par exemple `*.md` ou `path/to/directory/*.{rb,py,sh}`.
- Chemins génériques vers des fichiers dans le répertoire racine ou tous les répertoires, entre guillemets doubles. Par exemple `"*.json"` ou `"**/*.json"`.

**Exemple de `rules:changes`** :

```yaml
docker build:
  script: docker build -t my-image:$CI_COMMIT_REF_SLUG .
  rules:
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"
      changes:
        - Dockerfile
      when: manual
      allow_failure: true

docker build alternative:
  variables:
    DOCKERFILES_DIR: 'path/to/dockerfiles'
  script: docker build -t my-image:$CI_COMMIT_REF_SLUG .
  rules:
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"
      changes:
        - $DOCKERFILES_DIR/**/*
```

Dans cet exemple :

- Si le pipeline est un pipeline de merge request, vérifier les modifications apportées à `Dockerfile` et aux fichiers dans `$DOCKERFILES_DIR/**/*`.
- Si `Dockerfile` a été modifié, ajouter le job au pipeline en tant que job manuel, et le pipeline continue de s'exécuter même si le job n'est pas déclenché (`allow_failure: true`).
- Si un fichier dans `$DOCKERFILES_DIR/**/*` a été modifié, ajouter le job au pipeline.
- Si aucun fichier répertorié n'a été modifié, n'ajouter aucun des jobs à un pipeline (identique à `when: never`).

**Informations complémentaires** :

- Les patterns glob sont interprétés avec la méthode Ruby [`File.fnmatch`](https://docs.ruby-lang.org/en/master/File.html#method-c-fnmatch) avec les [indicateurs](https://docs.ruby-lang.org/en/master/File/Constants.html#module-File::Constants-label-Filename+Globbing+Constants+-28File-3A-3AFNM_-2A-29) `File::FNM_PATHNAME | File::FNM_DOTMATCH | File::FNM_EXTGLOB`.
- Pour des raisons de performance, GitLab effectue au maximum 50 000 vérifications par rapport aux patterns `changes` ou aux chemins de fichiers. Au-delà de la 50 000e vérification, les règles avec des patterns glob correspondent toujours. En d'autres termes, la règle `changes` suppose toujours une correspondance lorsque plus de 50 000 fichiers ont été modifiés, ou si moins de 50 000 fichiers ont été modifiés mais que les règles `changes` sont vérifiées plus de 50 000 fois.
- Un maximum de 50 patterns ou chemins de fichiers peut être défini par section `rules:changes`.
- `changes` est évalué à `true` si l'un des fichiers correspondants est modifié (opération `OR`).
- Pour des exemples supplémentaires, consultez [Spécifier quand les jobs s'exécutent avec `rules`](../jobs/job_rules.md).
- Vous pouvez utiliser le caractère `$` pour les variables et les chemins. Par exemple, si la variable `$VAR` existe, sa valeur est utilisée. Si elle n'existe pas, le `$` est interprété comme faisant partie d'un chemin.
- N'utilisez pas `./`, les doubles barres obliques (`//`) ni aucun autre type de chemin relatif. Les chemins sont comparés par correspondance exacte de chaîne ; ils ne sont pas évalués comme dans un shell.

**Sujets connexes** :

- [Les jobs ou pipelines peuvent s'exécuter de manière inattendue lors de l'utilisation de `rules: changes`](../jobs/job_troubleshooting.md#jobs-or-pipelines-run-unexpectedly-when-using-changes).

---

##### `rules:changes:paths` {#ruleschangespaths}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/90171) dans GitLab 15.2.

{{< /history >}}

Utilisez `rules:changes` pour spécifier qu'un job ne soit ajouté à un pipeline que lorsque des fichiers spécifiques sont modifiés, et utilisez `rules:changes:paths` pour spécifier les fichiers.

`rules:changes:paths` est identique à l'utilisation de [`rules:changes`](#ruleschanges) sans sous-clés. Tous les détails supplémentaires et les sujets connexes sont identiques.

**Type de mot-clé** : Mot-clé de job. Vous pouvez l'utiliser uniquement dans un job.

**Valeurs prises en charge** :

- Identique à `rules:changes`.

**Exemple de `rules:changes:paths`** :

```yaml
docker-build-1:
  script: docker build -t my-image:$CI_COMMIT_REF_SLUG .
  rules:
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"
      changes:
        - Dockerfile

docker-build-2:
  script: docker build -t my-image:$CI_COMMIT_REF_SLUG .
  rules:
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"
      changes:
        paths:
          - Dockerfile
```

Dans cet exemple, les deux jobs ont le même comportement.

---

##### `rules:changes:compare_to` {#ruleschangescompare_to}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/293645) dans GitLab 15.3 [avec un indicateur](../../administration/feature_flags/_index.md) nommé `ci_rules_changes_compare`. Activé par défaut.
- [Généralement disponible](https://gitlab.com/gitlab-org/gitlab/-/issues/366412) dans GitLab 15.5. Le feature flag `ci_rules_changes_compare` a été supprimé.
- Prise en charge des variables CI/CD [introduite](https://gitlab.com/gitlab-org/gitlab/-/issues/369916) dans GitLab 17.2.

{{< /history >}}

Utilisez `rules:changes:compare_to` pour spécifier la référence à comparer pour les modifications apportées aux fichiers répertoriés sous [`rules:changes:paths`](#ruleschangespaths).

**Type de mot-clé** : Mot-clé de job. Vous pouvez l'utiliser uniquement dans le cadre d'un job et il doit être combiné avec `rules:changes:paths`.

**Valeurs prises en charge** :

- Un nom de branche, tel que `main`, `branch1` ou `refs/heads/branch1`.
- Un nom de tag, tel que `tag1` ou `refs/tags/tag1`.
- Un SHA de commit, tel que `2fg31ga14b`.

Les variables CI/CD [sont prises en charge](../variables/where_variables_can_be_used.md#gitlab-ciyml-file).

**Exemple de `rules:changes:compare_to`** :

```yaml
docker build:
  script: docker build -t my-image:$CI_COMMIT_REF_SLUG .
  rules:
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"
      changes:
        paths:
          - Dockerfile
        compare_to: 'refs/heads/branch1'
```

Dans cet exemple, le `docker build` job n'est inclus que lorsque le `Dockerfile` a été modifié par rapport à `refs/heads/branch1` et que la source du pipeline est un événement de merge request.

**Informations complémentaires** :

- L'utilisation de `compare_to` dans certaines situations peut produire des résultats inattendus :
  - Avec les [pipelines de résultats fusionnés](../pipelines/merged_results_pipelines.md#troubleshooting), car la base de comparaison est un commit interne que GitLab crée.
  - Dans un projet dupliqué, voir le [ticket 424584](https://gitlab.com/gitlab-org/gitlab/-/issues/424584).

**Sujets connexes** :

- Vous pouvez utiliser `rules:changes:compare_to` pour [ignorer un job si la branche est vide](../jobs/job_rules.md#skip-jobs-if-the-branch-is-empty).

---

#### `rules:exists` {#rulesexists}

{{< history >}}

- Prise en charge des variables CI/CD [introduite](https://gitlab.com/gitlab-org/gitlab/-/issues/283881) dans GitLab 15.6.
- Le nombre maximum de vérifications par rapport aux patterns ou chemins de fichiers `exists` [est passé](https://gitlab.com/gitlab-org/gitlab/-/issues/227632) de 10 000 à 50 000 dans GitLab 17.7.
- Prise en charge des chemins de répertoires [introduite](https://gitlab.com/gitlab-org/gitlab/-/issues/327485) dans GitLab 18.2.

{{< /history >}}

Utilisez `exists` pour exécuter un job lorsque certains fichiers ou répertoires existent dans le dépôt.

**Type de mot-clé** : Mot-clé de job. Vous pouvez l'utiliser dans le cadre d'un job ou d'un [`include`](#include).

**Valeurs prises en charge** :

- Un tableau de chemins de fichiers ou de répertoires. Les chemins sont relatifs au répertoire du projet (`$CI_PROJECT_DIR`) et ne peuvent pas pointer directement en dehors de celui-ci. Les chemins de fichiers peuvent utiliser des patterns glob et des [variables CI/CD](../variables/where_variables_can_be_used.md#gitlab-ciyml-file).

**Exemple de `rules:exists`** :

```yaml
job1:
  script: docker build -t my-image:$CI_COMMIT_REF_SLUG .
  rules:
    - exists:
        - Dockerfile

job2:
  variables:
    DOCKERPATH: "**/Dockerfile"
  script: docker build -t my-image:$CI_COMMIT_REF_SLUG .
  rules:
    - exists:
        - $DOCKERPATH
```

Dans cet exemple :

- `job1` s'exécute si un `Dockerfile` existe dans le répertoire racine du dépôt.
- `job2` s'exécute si un `Dockerfile` existe n'importe où dans le dépôt.

**Informations complémentaires** :

- Les patterns glob sont interprétés avec la méthode Ruby [`File.fnmatch`](https://docs.ruby-lang.org/en/master/File.html#method-c-fnmatch) avec les [indicateurs](https://docs.ruby-lang.org/en/master/File/Constants.html#module-File::Constants-label-Filename+Globbing+Constants+-28File-3A-3AFNM_-2A-29) `File::FNM_PATHNAME | File::FNM_DOTMATCH | File::FNM_EXTGLOB`.
- Pour des raisons de performance, GitLab effectue au maximum 50 000 vérifications par rapport aux patterns `exists` ou aux chemins de fichiers. Au-delà de la 50 000e vérification, les règles avec des patterns glob correspondent toujours. En d'autres termes, la règle `exists` suppose toujours une correspondance dans les projets comportant plus de 50 000 fichiers, ou s'il y a moins de 50 000 fichiers mais que les règles `exists` sont vérifiées plus de 50 000 fois.
  - S'il y a plusieurs globs à pattern, la limite est de 50 000 divisée par le nombre de globs. Par exemple, une règle avec 5 globs à pattern a une limite de fichiers de 10 000.
- Un maximum de 50 patterns ou chemins de fichiers peut être défini par section `rules:exists`.
- `exists` prend la valeur `true` si l'un des fichiers listés est trouvé (opération `OR`).
- Avec `rules:exists` au niveau du job, GitLab recherche les fichiers dans le projet et la référence qui exécute le pipeline. Lors de l'utilisation de [`include` avec `rules:exists`](includes.md#include-with-rulesexists), GitLab recherche les fichiers ou répertoires dans le projet et la référence du fichier qui contient la section `include`. Le projet contenant la section `include` peut être différent du projet qui exécute le pipeline lors de l'utilisation de :
  - [Inclusions imbriquées](includes.md#use-nested-includes).
  - [Pipelines de conformité](../../user/compliance/compliance_pipelines.md).
- `rules:exists` ne peut pas rechercher la présence d'[artefacts](../jobs/job_artifacts.md), car l'évaluation de `rules` s'effectue avant l'exécution des jobs et la récupération des artefacts.
- Pour tester l'existence d'un répertoire, le chemin doit se terminer par une barre oblique (/)

---

##### `rules:exists:paths` {#rulesexistspaths}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/386040) dans GitLab 16.11 [avec un flag](../../administration/feature_flags/_index.md) nommé `ci_support_rules_exists_paths_and_project`. Désactivé par défaut.
- [En disponibilité générale](https://gitlab.com/gitlab-org/gitlab/-/issues/386040) dans GitLab 17.0. Le feature flag `ci_support_rules_exists_paths_and_project` a été supprimé.

{{< /history >}}

`rules:exists:paths` est identique à l'utilisation de [`rules:exists`](#rulesexists) sans sous-clés. Toutes les informations complémentaires sont identiques.

**Type de mot-clé** : Mot-clé de job. Vous pouvez l'utiliser dans le cadre d'un job ou d'un [`include`](#include).

**Valeurs prises en charge** :

- Un tableau de chemins de fichiers.

**Exemple de `rules:exists:paths`** :

```yaml
docker-build-1:
  script: docker build -t my-image:$CI_COMMIT_REF_SLUG .
  rules:
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"
      exists:
        - Dockerfile

docker-build-2:
  script: docker build -t my-image:$CI_COMMIT_REF_SLUG .
  rules:
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"
      exists:
        paths:
          - Dockerfile
```

Dans cet exemple, les deux jobs ont le même comportement.

---

##### `rules:exists:project` {#rulesexistsproject}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/386040) dans GitLab 16.11 [avec un flag](../../administration/feature_flags/_index.md) nommé `ci_support_rules_exists_paths_and_project`. Désactivé par défaut.
- [En disponibilité générale](https://gitlab.com/gitlab-org/gitlab/-/issues/386040) dans GitLab 17.0. Le feature flag `ci_support_rules_exists_paths_and_project` a été supprimé.

{{< /history >}}

Utilisez `rules:exists:project` pour spécifier l'emplacement dans lequel rechercher les fichiers listés sous [`rules:exists:paths`](#rulesexistspaths). Doit être utilisé avec `rules:exists:paths`.

**Type de mot-clé** : Mot-clé de job. Vous pouvez l'utiliser dans le cadre d'un job ou d'un [`include`](#include), et doit être combiné avec `rules:exists:paths`.

**Valeurs prises en charge** :

- `exists:project` : Un chemin de projet complet, incluant l'espace de nommage et le groupe.
- `exists:ref` : Facultatif. La référence du commit à utiliser pour rechercher le fichier. La référence peut être un tag, un nom de branche ou un SHA. Par défaut, la valeur est `HEAD` du projet lorsqu'elle n'est pas spécifiée.

**Exemple de `rules:exists:project`** :

```yaml
docker build:
  script: docker build -t my-image:$CI_COMMIT_REF_SLUG .
  rules:
    - exists:
        paths:
          - Dockerfile
        project: my-group/my-project
        ref: v1.0.0
```

Dans cet exemple, le job `docker build` n'est inclus que lorsque le `Dockerfile` existe dans le projet `my-group/my-project` sur le commit tagué avec `v1.0.0`.

---

#### `rules:when` {#ruleswhen}

Utilisez `rules:when` seul ou dans le cadre d'une autre règle pour contrôler les conditions d'ajout d'un job à un pipeline. `rules:when` est similaire à [`when`](#when), mais avec des options d'entrée légèrement différentes.

Si une règle `rules:when` n'est pas combinée avec `if`, `changes` ou `exists`, elle correspond toujours si elle est atteinte lors de l'évaluation des règles d'un job.

**Type de mot-clé** : Spécifique au job. Vous pouvez l'utiliser uniquement dans un job.

**Valeurs prises en charge** :

- `on_success` (par défaut) : Exécuter le job uniquement lorsqu'aucun job des étapes précédentes n'échoue.
- `on_failure` : Exécuter le job uniquement lorsqu'au moins un job d'une étape précédente échoue.
- `never` : Ne pas exécuter le job quel que soit le statut des jobs des étapes précédentes.
- `always` : Exécuter le job quel que soit le statut des jobs des étapes précédentes.
- `manual` : Ajouter le job au pipeline en tant que [job manuel](../jobs/job_control.md#create-a-job-that-must-be-run-manually). La valeur par défaut de [`allow_failure`](#allow_failure) est remplacée par `false`.
- `delayed` : Ajouter le job au pipeline en tant que [job différé](../jobs/job_control.md#run-a-job-after-a-delay).

**Exemple de `rules:when`** :

```yaml
job1:
  rules:
    - if: $CI_COMMIT_REF_NAME == $CI_DEFAULT_BRANCH
    - if: $CI_COMMIT_REF_NAME =~ /feature/
      when: delayed
    - when: manual
  script:
    - echo
```

Dans cet exemple, `job1` est ajouté aux pipelines :

- Pour la branche par défaut, avec `when: on_success`, qui est le comportement par défaut lorsque `when` n'est pas défini.
- Pour les branches de fonctionnalité en tant que job différé.
- Dans tous les autres cas en tant que job manuel.

**Informations complémentaires** :

- Lors de l'évaluation du statut des jobs pour `on_success` et `on_failure` :
  - Les jobs avec [`allow_failure: true`](#allow_failure) dans les étapes précédentes sont considérés comme réussis, même s'ils ont échoué.
  - Les jobs ignorés dans les étapes précédentes, par exemple les [jobs manuels qui n'ont pas été démarrés](../jobs/job_control.md#create-a-job-that-must-be-run-manually), sont considérés comme réussis.
- Lors de l'utilisation de `rules:when: manual` pour [ajouter un job manuel](../jobs/job_control.md#create-a-job-that-must-be-run-manually) :
  - [`allow_failure`](#allow_failure) prend la valeur `false` par défaut. Cette valeur par défaut est l'opposé de l'utilisation de [`when: manual`](#when) pour ajouter un job manuel.
  - Pour obtenir le même comportement que `when: manual` défini en dehors de `rules`, définissez [`rules: allow_failure`](#rulesallow_failure) sur `true`.

---

#### `rules:allow_failure` {#rulesallow_failure}

Utilisez [`allow_failure: true`](#allow_failure) dans `rules` pour permettre à un job d'échouer sans arrêter le pipeline.

Vous pouvez également utiliser `allow_failure: true` avec un job manuel. Le pipeline continue de s'exécuter sans attendre le résultat du job manuel. `allow_failure: false` combiné avec `when: manual` dans les règles oblige le pipeline à attendre que le job manuel s'exécute avant de continuer.

**Type de mot-clé** : Mot-clé de job. Vous pouvez l'utiliser uniquement dans un job.

**Valeurs prises en charge** :

- `true` ou `false`. Par défaut, `false` si non défini.

**Exemple de `rules:allow_failure`** :

```yaml
job:
  script: echo "Hello, Rules!"
  rules:
    - if: $CI_MERGE_REQUEST_TARGET_BRANCH_NAME == $CI_DEFAULT_BRANCH
      when: manual
      allow_failure: true
```

Si la règle correspond, le job est un job manuel avec `allow_failure: true`.

**Informations complémentaires** :

- Le `rules:allow_failure` au niveau de la règle remplace le [`allow_failure`](#allow_failure) au niveau du job et s'applique uniquement lorsque la règle spécifique déclenche le job.

---

#### `rules:needs` {#rulesneeds}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/31581) dans GitLab 16.0 [avec un indicateur](../../administration/feature_flags/_index.md) nommé `introduce_rules_with_needs`. Désactivé par défaut.
- [Généralement disponible](https://gitlab.com/gitlab-org/gitlab/-/issues/408871) dans GitLab 16.2. Le feature flag `introduce_rules_with_needs` a été supprimé.

{{< /history >}}

Utilisez `needs` dans les règles pour mettre à jour la configuration [`needs`](#needs) d'un job pour des conditions spécifiques. Lorsqu'une condition correspond à une règle, la configuration `needs` du job est entièrement remplacée par le `needs` de la règle.

**Type de mot-clé** : Spécifique au job. Vous pouvez l'utiliser uniquement dans un job.

**Valeurs prises en charge** :

- Un tableau de noms de jobs sous forme de chaînes.
- Un hash avec un nom de job, optionnellement avec des attributs supplémentaires.
- Un tableau vide (`[]`), pour définir les dépendances du job sur aucune lorsque la condition spécifique est remplie.

**Exemple de `rules:needs`** :

```yaml
build-dev:
  stage: build
  rules:
    - if: $CI_COMMIT_BRANCH != $CI_DEFAULT_BRANCH
  script: echo "Feature branch, so building dev version..."

build-prod:
  stage: build
  rules:
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH
  script: echo "Default branch, so building prod version..."

tests:
  stage: test
  rules:
    - if: $CI_COMMIT_BRANCH != $CI_DEFAULT_BRANCH
      needs: ['build-dev']
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH
      needs: ['build-prod']
  script: echo "Running dev specs by default, or prod specs when default branch..."
```

Dans cet exemple :

- Si le pipeline s'exécute sur une branche qui n'est pas la branche par défaut, et que la règle correspond donc à la première condition, le job `specs` dépend du job `build-dev`.
- Si le pipeline s'exécute sur la branche par défaut, et que la règle correspond donc à la deuxième condition, le job `specs` dépend du job `build-prod`.

**Informations complémentaires** :

- `needs` dans les règles remplace tout `needs` défini au niveau du job. Lorsqu'il est remplacé, le comportement est identique à celui de [`needs`](#needs) au niveau du job.
- `needs` dans les règles peut accepter [`artifacts`](#needsartifacts) et [`optional`](#needsoptional).

---

#### `rules:variables` {#rulesvariables}

Utilisez [`variables`](#variables) dans `rules` pour définir des variables pour des conditions spécifiques.

**Type de mot-clé** : Spécifique au job. Vous pouvez l'utiliser uniquement dans un job.

**Valeurs prises en charge** :

- Un hash de variables au format `VARIABLE-NAME: value`.

**Exemple de `rules:variables`** :

```yaml
job:
  variables:
    DEPLOY_VARIABLE: "default-deploy"
  rules:
    - if: $CI_COMMIT_REF_NAME == $CI_DEFAULT_BRANCH
      variables:                              # Override DEPLOY_VARIABLE defined
        DEPLOY_VARIABLE: "deploy-production"  # at the job level.
    - if: $CI_COMMIT_REF_NAME =~ /feature/
      variables:
        IS_A_FEATURE: "true"                  # Define a new variable.
  script:
    - echo "Run script with $DEPLOY_VARIABLE as an argument"
    - echo "Run another script if $IS_A_FEATURE exists"
```

---

#### `rules:interruptible` {#rulesinterruptible}

{{< history >}}

- [Introduite](https://gitlab.com/gitlab-org/gitlab/-/issues/194023) dans GitLab 16.10.

{{< /history >}}

Utilisez `interruptible` dans les règles pour mettre à jour la valeur [`interruptible`](#interruptible) d'un job pour des conditions spécifiques.

**Type de mot-clé** : Spécifique au job. Vous pouvez l'utiliser uniquement dans un job.

**Valeurs prises en charge** :

- `true` ou `false`.

**Exemple de `rules:interruptible`** :

```yaml
job:
  script: echo "Hello, Rules!"
  interruptible: true
  rules:
    - if: $CI_COMMIT_REF_NAME == $CI_DEFAULT_BRANCH
      interruptible: false  # Override interruptible defined at the job level.
    - when: on_success
```

**Informations complémentaires** :

- Le `rules:interruptible` au niveau de la règle remplace le [`interruptible`](#interruptible) au niveau du job et s'applique uniquement lorsque la règle spécifique déclenche le job.

---

### `run` {#run}

{{< details >}}

- Statut : Expérience

{{< /details >}}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/440487) dans GitLab 17.3 [avec un indicateur](../../administration/feature_flags/_index.md) nommé `pipeline_run_keyword`. Désactivé par défaut. Requiert GitLab Runner 17.1.
- Le feature flag `pipeline_run_keyword` a été [supprimé](https://gitlab.com/gitlab-org/gitlab/-/issues/471925) dans GitLab 17.5.

{{< /history >}}

> [!note]
> Cette fonctionnalité est disponible pour les tests, mais n'est pas prête pour une utilisation en production.

Utilisez `run` pour définir une série d'[étapes](../functions/_index.md) à exécuter dans un job. Chaque étape peut être un script ou une étape prédéfinie.

Vous pouvez également fournir des variables d'environnement et des entrées optionnelles.

**Type de mot-clé** : Mot-clé de job. Vous pouvez l'utiliser uniquement dans un job.

**Valeurs prises en charge** :

- Un tableau de hashes, où chaque hash représente une étape avec les clés possibles suivantes :
  - `name` : Une chaîne représentant le nom de l'étape.
  - `script` : Une chaîne contenant les commandes shell à exécuter.
  - `step` : Une chaîne identifiant une étape prédéfinie à exécuter.
  - `env` : Facultatif. Un hash de variables d'environnement spécifiques à cette étape.
  - `inputs` : Facultatif. Un hash de paramètres d'entrée pour les étapes prédéfinies.

Chaque entrée du tableau doit avoir un `name`, et un `script` ou `step` (mais pas les deux).

**Exemple de `run`** :

``` yaml
job:
  run:
    - name: 'hello_steps'
      script: 'echo "hello from step1"'
    - name: 'bye_steps'
      step: gitlab.com/gitlab-org/ci-cd/runner-tools/echo-step@main
      inputs:
        echo: 'bye steps!'
      env:
        var1: 'value 1'
```

Dans cet exemple, le job comporte deux étapes :

- `hello_steps` exécute la commande shell `echo`.
- `bye_steps` utilise une étape prédéfinie avec une variable d'environnement et un paramètre d'entrée.

**Informations complémentaires** :

- Une étape peut avoir soit une clé `script`, soit une clé `step`, mais pas les deux.
- Une configuration `run` ne peut pas être utilisée conjointement avec les mots-clés existants [`script`](#script), [`after_script`](#after_script) ou [`before_script`](#before_script).
- Les scripts multiligne peuvent être définis à l'aide de la [syntaxe de scalaire de bloc YAML](script.md#split-long-commands).

---

### `script` {#script}

Utilisez `script` pour spécifier les commandes à exécuter par le runner.

Tous les jobs, à l'exception des [jobs de déclenchement](#trigger), nécessitent un mot-clé `script`.

**Type de mot-clé** : Mot-clé de job. Vous pouvez l'utiliser uniquement dans un job.

**Valeurs prises en charge** : Un tableau comprenant :

- Des commandes sur une seule ligne.
- Des commandes longues [réparties sur plusieurs lignes](script.md#split-long-commands).
- [Ancres YAML](yaml_optimization.md#yaml-anchors-for-scripts).

Les variables CI/CD [sont prises en charge](../variables/where_variables_can_be_used.md#gitlab-ciyml-file).

**Exemple de `script`** :

```yaml
job1:
  script: "bundle exec rspec"

job2:
  script:
    - uname -a
    - bundle exec rspec
```

**Informations complémentaires** :

- Lorsque vous utilisez [ces caractères spéciaux dans `script`](script.md#use-special-characters-with-script), vous devez utiliser des guillemets simples (`'`) ou des guillemets doubles (`"`).

**Sujets connexes** :

- Vous pouvez [ignorer les codes de sortie non nuls](script.md#ignore-non-zero-exit-codes).
- [Utilisez des codes couleur avec `script`](script.md#add-color-codes-to-script-output) pour faciliter la révision des job logs.
- [Créez des sections repliables personnalisées](../jobs/job_logs.md#create-custom-collapsible-sections) pour simplifier la sortie du job log.

---

### `secrets` {#secrets}

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Utilisez `secrets` pour spécifier des [secrets CI/CD](../secrets/_index.md) à :

- Récupérer depuis un fournisseur de secrets externe.
- Rendre disponibles dans le job en tant que [variables CI/CD](../variables/_index.md) (de type [`file`](../variables/_index.md#use-file-type-cicd-variables) par défaut).

---

#### `secrets:vault` {#secretsvault}

{{< history >}}

- L'option moteur `generic` a été [introduite](https://gitlab.com/gitlab-org/gitlab/-/issues/366492) dans GitLab Runner 16.11.

{{< /history >}}

Utilisez `secrets:vault` pour spécifier les secrets fournis par un [HashiCorp Vault](https://www.vaultproject.io/).

**Type de mot-clé** : Mot-clé de job. Vous pouvez l'utiliser uniquement dans un job.

**Valeurs prises en charge** :

- `engine:name` : Nom du moteur de secrets. Peut être `kv-v2` (par défaut), `kv-v1` ou `generic`.
- `engine:path` : Chemin vers le moteur de secrets.
- `path` : Chemin vers le secret.
- `field` : Nom du champ où le mot de passe est stocké.

**Exemple de `secrets:vault`** :

Pour spécifier tous les détails explicitement et utiliser le moteur de secrets [KV-V2](https://developer.hashicorp.com/vault/docs/secrets/kv/kv-v2) :

```yaml
job:
  secrets:
    DATABASE_PASSWORD:  # Store the path to the secret in this CI/CD variable
      vault:  # Translates to secret: `ops/data/production/db`, field: `password`
        engine:
          name: kv-v2
          path: ops
        path: production/db
        field: password
```

Vous pouvez raccourcir cette syntaxe. Avec la syntaxe courte, `engine:name` et `engine:path` ont tous deux pour valeur par défaut `kv-v2` :

```yaml
job:
  secrets:
    DATABASE_PASSWORD:  # Store the path to the secret in this CI/CD variable
      vault: production/db/password  # Translates to secret: `kv-v2/data/production/db`, field: `password`
```

Pour spécifier un chemin de moteur de secrets personnalisé dans la syntaxe courte, ajoutez un suffixe commençant par `@` :

```yaml
job:
  secrets:
    DATABASE_PASSWORD:  # Store the path to the secret in this CI/CD variable
      vault: production/db/password@ops  # Translates to secret: `ops/data/production/db`, field: `password`
```

---

#### `secrets:gcp_secret_manager` {#secretsgcp_secret_manager}

{{< history >}}

- [Introduit](https://gitlab.com/groups/gitlab-org/-/epics/11739) dans GitLab 16.8 et GitLab Runner 16.8.

{{< /history >}}

Utilisez `secrets:gcp_secret_manager` pour spécifier les secrets fournis par [GCP Secret Manager](https://cloud.google.com/security/products/secret-manager).

**Type de mot-clé** : Mot-clé de job. Vous pouvez l'utiliser uniquement dans un job.

**Valeurs prises en charge** :

- `name` : Nom du secret.
- `version` : Version du secret.

**Exemple de `secrets:gcp_secret_manager`** :

```yaml
job:
  secrets:
    DATABASE_PASSWORD:
      gcp_secret_manager:
        name: 'test'
        version: 2
```

**Sujets connexes** :

- [Utiliser les secrets GCP Secret Manager dans GitLab CI/CD](../secrets/gcp_secret_manager.md).

---

#### `secrets:azure_key_vault` {#secretsazure_key_vault}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/271271) dans GitLab 16.3 et GitLab Runner 16.3.

{{< /history >}}

Utilisez `secrets:azure_key_vault` pour spécifier les secrets fournis par un [Azure Key Vault](https://azure.microsoft.com/en-us/products/key-vault/).

**Type de mot-clé** : Mot-clé de job. Vous pouvez l'utiliser uniquement dans un job.

**Valeurs prises en charge** :

- `name` : Nom du secret.
- `version` : Version du secret.

**Exemple de `secrets:azure_key_vault`** :

```yaml
job:
  secrets:
    DATABASE_PASSWORD:
      azure_key_vault:
        name: 'test'
        version: 'test'
```

**Sujets connexes** :

- [Utiliser les secrets Azure Key Vault dans GitLab CI/CD](../secrets/azure_key_vault.md).

---

#### `secrets:file` {#secretsfile}

Utilisez `secrets:file` pour configurer le secret afin qu'il soit stocké en tant que [variable CI/CD de type `file` ou `variable`](../variables/_index.md#use-file-type-cicd-variables)

Par défaut, le secret est transmis au job en tant que variable CI/CD de type `file`. La valeur du secret est stockée dans le fichier et la variable contient le chemin vers le fichier.

Si votre logiciel ne peut pas utiliser les variables CI/CD de type `file`, définissez `file: false` pour stocker la valeur du secret directement dans la variable.

**Type de mot-clé** : Mot-clé de job. Vous pouvez l'utiliser uniquement dans un job.

**Valeurs prises en charge** :

- `true` (par défaut) ou `false`.

**Exemple de `secrets:file`** :

```yaml
job:
  secrets:
    DATABASE_PASSWORD:
      vault: production/db/password@ops
      file: false
```

**Informations complémentaires** :

- Le mot-clé `file` est un paramètre pour la variable CI/CD et doit être imbriqué sous le nom de la variable CI/CD, et non dans la section `vault`.

---

#### `secrets:token` {#secretstoken}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/356986) dans GitLab 15.8, contrôlé par le paramètre **Limit JSON Web Token (JWT) access**.
- [Rendu toujours disponible et paramètre **Limit JSON Web Token (JWT) access** supprimé](https://gitlab.com/gitlab-org/gitlab/-/issues/366798) dans GitLab 16.0.

{{< /history >}}

Utilisez `secrets:token` pour sélectionner explicitement un jeton à utiliser lors de l'authentification auprès du fournisseur de secrets externe en référençant la variable CI/CD du jeton.

**Type de mot-clé** : Mot-clé de job. Vous pouvez l'utiliser uniquement dans un job.

**Valeurs prises en charge** :

- Le nom d'un jeton d'identifiant

**Exemple de `secrets:token`** :

```yaml
job:
  id_tokens:
    AWS_TOKEN:
      aud: https://aws.example.com
    VAULT_TOKEN:
      aud: https://vault.example.com
  secrets:
    DB_PASSWORD:
      vault: gitlab/production/db
      token: $VAULT_TOKEN
```

**Informations complémentaires** :

- Lorsque le mot-clé `token` n'est pas défini et qu'un seul jeton est défini, le jeton défini est automatiquement utilisé.
- S'il y a plus d'un jeton défini, vous devez spécifier le jeton à utiliser en définissant le mot-clé `token`. Si vous ne spécifiez pas quel jeton utiliser, il n'est pas possible de prédire quel jeton sera utilisé à chaque exécution du job.

---

### `services` {#services}

Utilisez `services` pour spécifier les images Docker supplémentaires requises par vos scripts pour s'exécuter correctement. L'[image `services`](../services/_index.md) est liée à l'image spécifiée dans le mot-clé [`image`](#image).

La configuration du job et la configuration par défaut ne sont pas fusionnées. Si le pipeline a [`default:services`](#default) défini, et que le job a également `services`, la configuration du job est prioritaire et la configuration par défaut n'est pas utilisée.

> [!warning]
> Pour activer la mise en réseau inter-services, définissez `FF_NETWORK_PER_BUILD` sur `true`. Sans cet indicateur, les services peuvent ne pas fonctionner correctement. Pour plus d'informations, voir les [feature flags](https://docs.gitlab.com/runner/configuration/feature-flags)

**Type de mot-clé** : Mot-clé de job. Vous pouvez l'utiliser uniquement dans un job ou dans la [section `default`](#default).

**Valeurs prises en charge** : Le nom de l'image de services, incluant le chemin du registre si nécessaire, dans l'un des formats suivants :

- `<image-name>` (identique à l'utilisation de `<image-name>` avec le tag `latest`)
- `<image-name>:<tag>`
- `<image-name>@<digest>`

Les variables CI/CD [sont prises en charge](../variables/where_variables_can_be_used.md#gitlab-ciyml-file), mais pas pour `alias`. Pour personnaliser `alias` dynamiquement, utilisez plutôt les [entrées CI/CD](../inputs/_index.md).

**Exemple de `services`** :

```yaml
default:
  image:
    name: ruby:2.6
    entrypoint: ["/bin/bash"]

  services:
    - name: my-postgres:11.7
      alias: db-postgres
      entrypoint: ["/usr/local/bin/db-postgres"]
      command: ["start"]

  before_script:
    - bundle install

test:
  script:
    - bundle exec rake spec
```

Dans cet exemple, GitLab lance deux conteneurs pour le job :

- Un conteneur Ruby qui exécute les commandes `script`.
- Un conteneur PostgreSQL. Les commandes `script` dans le conteneur Ruby peuvent se connecter à la base de données PostgreSQL au nom d'hôte `db-postgres`.

**Informations complémentaires** :

- L'utilisation de `services` au niveau supérieur, mais pas dans la section `default`, est [dépréciée](deprecated_keywords.md#globally-defined-image-services-cache-before_script-after_script).

**Sujets connexes** :

- [Paramètres disponibles pour `services`](../services/_index.md#available-settings-for-services).
- [Définir `services` dans le fichier `.gitlab-ci.yml`](../services/_index.md#define-services-in-the-gitlab-ciyml-file).
- [Exécuter vos jobs CI/CD dans des conteneurs Docker](../docker/using_docker_images.md).
- [Utiliser Docker pour créer des images Docker](../docker/using_docker_build.md).

---

#### `services:name` {#servicesname}

Le nom complet de l'image à utiliser pour le service.

**Type de mot-clé** : Mot-clé de job. Vous pouvez l'utiliser uniquement dans un job ou dans la [section `default`](#default).

**Valeurs prises en charge** : Le nom de l'image de service, incluant le chemin du registre si nécessaire, dans l'un des formats suivants :

- `<image-name>` (identique à l'utilisation de `<image-name>` avec le tag `latest`)
- `<image-name>:<tag>`
- `<image-name>@<digest>`

Les variables CI/CD [sont prises en charge](../variables/where_variables_can_be_used.md#gitlab-ciyml-file).

**Exemple de `services:name`** :

```yaml
services:
  - name: postgres:11.7
  - name: registry.example.com/my-org/custom-service:latest
```

**Informations complémentaires** :

- Utilisez [`alias`](#servicesalias) pour définir des alias de nom uniques lors de l'utilisation de plusieurs images de service identiques, ou lorsque le nom de l'image de service est long.
- Lorsqu'il est utilisé avec d'autres options de service telles que `entrypoint`, `command` ou `variables`, le mot-clé `name` est obligatoire.
- Pour plus d'informations, voir [accéder aux services](../services/_index.md#accessing-the-services).

---

#### `services:alias` {#servicesalias}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/421131) dans GitLab Runner 17.9.

{{< /history >}}

Alias supplémentaires pour accéder au service depuis le conteneur du job.

**Type de mot-clé** : Mot-clé de job. Vous pouvez l'utiliser uniquement dans un job ou dans la [section `default`](#default).

**Valeurs prises en charge** : Une chaîne avec un ou plusieurs alias séparés par des espaces ou des virgules.

**Exemple de `services:alias`** :

```yaml
services:
  - name: postgres:11.7
    alias: db,postgres,pg
  - name: mysql:latest
    alias: mysql-1
```

**Informations complémentaires** :

- Plusieurs alias peuvent être séparés par des espaces ou des virgules.
- Pour plus d'informations, voir [accéder aux services](../services/_index.md#accessing-the-services) et [utiliser des alias comme noms de conteneurs de service pour l'exécuteur Kubernetes](../services/_index.md#using-aliases-as-service-container-names-for-the-kubernetes-executor).

---

#### `services:docker` {#servicesdocker}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/27919) dans GitLab 16.7. Requiert GitLab Runner 16.7 ou une version ultérieure.
- L'option d'entrée `user` a été [introduite](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/137907) dans GitLab 16.8.

{{< /history >}}

Utilisez `services:docker` pour transmettre des options à l'exécuteur Docker d'un GitLab Runner.

**Type de mot-clé** : Mot-clé de job. Vous pouvez l'utiliser uniquement dans un job ou dans la [section `default`](#default).

**Valeurs prises en charge** :

Un hash d'options pour l'exécuteur Docker, qui peut inclure :

- `platform` : Sélectionne l'architecture de l'image à télécharger. Lorsqu'elle n'est pas spécifiée, la valeur par défaut est la même plateforme que le runner hôte.
- `user` : Spécifiez le nom d'utilisateur ou l'UID à utiliser lors de l'exécution du conteneur.

**Exemple de `services:docker`** :

```yaml
arm-sql-job:
  script: echo "Run sql tests in service container"
  image: ruby:2.6
  services:
    - name: super/sql:experimental
      docker:
        platform: arm64/v8
        user: dave
```

**Informations complémentaires** :

- `services:docker:platform` correspond à l'[option `docker pull --platform`](https://docs.docker.com/reference/cli/docker/image/pull/#options).
- `services:docker:user` correspond à l'[option `docker run --user`](https://docs.docker.com/reference/cli/docker/container/run/#options).

---

#### `services:kubernetes` {#serviceskubernetes}

{{< history >}}

- [Introduite](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/38451) dans GitLab 18.0. Requiert GitLab Runner 17.11 ou une version ultérieure.
- L'option d'entrée `user` a été [introduite](https://gitlab.com/gitlab-org/gitlab-runner/-/merge_requests/5469) dans GitLab Runner 17.11.
- L'option d'entrée `user` a été [étendue pour prendre en charge le format `uid:gid`](https://gitlab.com/gitlab-org/gitlab-runner/-/merge_requests/5540) dans GitLab 18.0.

{{< /history >}}

Utilisez `services:kubernetes` pour transmettre des options à l'[exécuteur Kubernetes](https://docs.gitlab.com/runner/executors/kubernetes/) de GitLab Runner.

**Type de mot-clé** : Mot-clé de job. Vous pouvez l'utiliser uniquement dans un job ou dans la [section `default`](#default).

**Valeurs prises en charge** :

Un hash d'options pour l'exécuteur Kubernetes, qui peut inclure :

- `user` : Spécifiez le nom d'utilisateur ou l'UID à utiliser lors de l'exécution du conteneur. Vous pouvez également l'utiliser pour définir le GID en utilisant le format `UID:GID`.

**Exemple de `services:kubernetes` avec l'UID uniquement** :

```yaml
arm-sql-job:
  script: echo "Run sql tests"
  image: ruby:2.6
  services:
    - name: super/sql:experimental
      kubernetes:
        user: "1001"
```

**Exemple de `services:kubernetes` avec l'UID et le GID** :

```yaml
arm-sql-job:
  script: echo "Run sql tests"
  image: ruby:2.6
  services:
    - name: super/sql:experimental
      kubernetes:
        user: "1001:1001"
```

---

#### `services:entrypoint` {#servicesentrypoint}

Une commande ou un script à exécuter comme point d'entrée du conteneur.

Lors de la création du conteneur Docker, `entrypoint` est traduit en option Docker `--entrypoint`. La syntaxe est similaire à la [directive `ENTRYPOINT` du Dockerfile](https://docs.docker.com/reference/dockerfile/#entrypoint), où chaque token shell est une chaîne séparée dans le tableau.

**Type de mot-clé** : Mot-clé de job. Vous pouvez l'utiliser uniquement dans un job ou dans la [section `default`](#default).

**Valeurs prises en charge** : Un tableau de chaînes représentant la commande de point d'entrée.

**Exemple de `services:entrypoint`** :

```yaml
services:
  - name: my-postgres:11.7
    entrypoint: ["/usr/local/bin/db-postgres"]
```

---

#### `services:command` {#servicescommand}

Commande ou script à utiliser comme commande du conteneur.

Il est traduit en arguments passés à Docker après le nom de l'image. La syntaxe est similaire à la [directive `CMD` du Dockerfile](https://docs.docker.com/reference/dockerfile/#cmd), où chaque token shell est une chaîne séparée dans le tableau.

**Type de mot-clé** : Mot-clé de job. Vous pouvez l'utiliser uniquement dans un job ou dans la [section `default`](#default).

**Valeurs prises en charge** : Un tableau de chaînes représentant la commande.

**Exemple de `services:command`** :

```yaml
services:
  - name: super/sql:latest
    command: ["/usr/bin/super-sql", "run"]
```

---

#### `services:variables` {#servicesvariables}

Variables d'environnement supplémentaires transmises exclusivement au service. Les variables de service sont transmises exclusivement au conteneur de service et ne sont pas disponibles dans le conteneur du job.

La syntaxe est identique à celle des [variables de job](../variables/_index.md).

**Type de mot-clé** : Mot-clé de job. Vous pouvez l'utiliser uniquement dans un job ou dans la [section `default`](#default).

**Valeurs prises en charge** : Un hash de noms et de valeurs de variables d'environnement.

**Exemple de `services:variables`** :

```yaml
services:
  - name: postgres:11.7
    alias: db
    variables:
      POSTGRES_DB: "my_custom_db"
      POSTGRES_USER: "postgres"
      POSTGRES_PASSWORD: "example"
      PGDATA: "/var/lib/postgresql/data"
```

**Informations complémentaires** :

- Les variables de service ne peuvent pas se référencer elles-mêmes, elles ne prennent pas en charge l'expansion ou l'interpolation de variables.
- Les variables définies au niveau du job ou du pipeline sont automatiquement transmises aux services. Voir [transmission des variables CI/CD aux services](../services/_index.md#passing-cicd-variables-to-services) pour plus d'informations.
- Les variables de service ne sont disponibles que pour le service spécifique pour lequel elles sont définies.

---

#### `services:pull_policy` {#servicespull_policy}

{{< history >}}

- [Introduite](https://gitlab.com/gitlab-org/gitlab/-/issues/21619) dans GitLab 15.1 [avec un flag](../../administration/feature_flags/_index.md) nommé `ci_docker_image_pull_policy`. Désactivé par défaut.
- [Activé sur GitLab.com et GitLab Self-Managed](https://gitlab.com/gitlab-org/gitlab/-/issues/363186) dans GitLab 15.2.
- [Généralement disponible](https://gitlab.com/gitlab-org/gitlab/-/issues/363186) dans GitLab 15.4. [Feature flag `ci_docker_image_pull_policy`](https://gitlab.com/gitlab-org/gitlab/-/issues/363186) supprimé.

{{< /history >}}

La politique d'extraction que le runner utilise pour récupérer l'image Docker. Requiert GitLab Runner 15.1 ou une version ultérieure.

**Type de mot-clé** : Mot-clé de job. Vous pouvez l'utiliser uniquement dans un job ou dans la [section `default`](#default).

**Valeurs prises en charge** :

- Une seule politique d'extraction, ou plusieurs politiques d'extraction dans un tableau. Peut être `always`, `if-not-present` ou `never`.

**Exemples de `services:pull_policy`** :

```yaml
job1:
  script: echo "A single pull policy."
  services:
    - name: postgres:11.6
      pull_policy: if-not-present

job2:
  script: echo "Multiple pull policies."
  services:
    - name: postgres:11.6
      pull_policy: [always, if-not-present]
```

**Informations complémentaires** :

- Si le runner ne prend pas en charge la politique d'extraction définie, le job échoue avec une erreur similaire à : `ERROR: Job failed (system failure): the configured PullPolicies ([always]) are not allowed by AllowedPullPolicies ([never])`.

**Sujets connexes** :

- [Exécuter vos jobs CI/CD dans des conteneurs Docker](../docker/using_docker_images.md).
- [Configurer la façon dont les runners extraient les images](https://docs.gitlab.com/runner/executors/docker/#configure-how-runners-pull-images).
- [Définir plusieurs politiques d'extraction](https://docs.gitlab.com/runner/executors/docker/#set-multiple-pull-policies).

---

### `stage` {#stage}

Utilisez `stage` pour définir dans quelle [étape](#stages) un job s'exécute. Les jobs dans le même `stage` peuvent s'exécuter en parallèle (voir les **Informations complémentaires**).

Si `stage` n'est pas défini, le job utilise l'étape `test` par défaut.

**Type de mot-clé** : Mot-clé de job. Vous pouvez l'utiliser uniquement dans un job.

**Valeurs prises en charge** : Une chaîne, qui peut être :

- Une [étape par défaut](#stages).
- Des étapes définies par l'utilisateur.

**Exemple de `stage`** :

```yaml
stages:
  - build
  - test
  - deploy

job1:
  stage: build
  script:
    - echo "This job compiles code."

job2:
  stage: test
  script:
    - echo "This job tests the compiled code. It runs when the build stage completes."

job3:
  script:
    - echo "This job also runs in the test stage."

job4:
  stage: deploy
  script:
    - echo "This job deploys the code. It runs when the test stage completes."
  environment: production
```

**Informations complémentaires** :

- Le nom de l'étape doit comporter 255 caractères ou moins.
- Les jobs peuvent s'exécuter en parallèle s'ils s'exécutent sur des runners différents.
- Si vous n'avez qu'un seul runner, les jobs peuvent s'exécuter en parallèle si le [paramètre `concurrent`](https://docs.gitlab.com/runner/configuration/advanced-configuration/#the-global-section) du runner est supérieur à `1`.

---

#### `stage: .pre` {#stage-pre}

Utilisez l'étape `.pre` pour faire s'exécuter un job au début d'un pipeline. Par défaut, `.pre` est la première étape d'un pipeline. Les étapes définies par l'utilisateur s'exécutent après `.pre`. Il n'est pas nécessaire de définir `.pre` dans [`stages`](#stages).

Si un pipeline ne contient que des jobs dans les étapes `.pre` ou `.post`, il ne s'exécute pas. Il doit y avoir au moins un autre job dans une étape différente.

**Type de mot-clé** : Vous ne pouvez l'utiliser qu'avec le mot-clé `stage` d'un job.

**Exemple de `stage: .pre`** :

```yaml
stages:
  - build
  - test

job1:
  stage: build
  script:
    - echo "This job runs in the build stage."

first-job:
  stage: .pre
  script:
    - echo "This job runs in the .pre stage, before all other stages."

job2:
  stage: test
  script:
    - echo "This job runs in the test stage."
```

**Informations complémentaires** :

- Si un pipeline contient des jobs avec [`needs: []`](#needs) et des jobs dans l'étape `.pre`, ils démarreront tous dès que le pipeline sera créé. Les jobs avec `needs: []` démarrent immédiatement, ignorant toute configuration d'étape.
- Une [politique d'exécution de pipeline](../../user/application_security/policies/pipeline_execution_policies.md) peut définir une étape `.pipeline-policy-pre` qui s'exécute avant `.pre`.

---

#### `stage: .post` {#stage-post}

Utilisez l'étape `.post` pour faire s'exécuter un job à la fin d'un pipeline. Par défaut, `.post` est la dernière étape d'un pipeline. Les étapes définies par l'utilisateur s'exécutent avant `.post`. Il n'est pas nécessaire de définir `.post` dans [`stages`](#stages).

Si un pipeline ne contient que des jobs dans les étapes `.pre` ou `.post`, il ne s'exécute pas. Il doit y avoir au moins un autre job dans une étape différente.

**Type de mot-clé** : Vous ne pouvez l'utiliser qu'avec le mot-clé `stage` d'un job.

**Exemple de `stage: .post`** :

```yaml
stages:
  - build
  - test

job1:
  stage: build
  script:
    - echo "This job runs in the build stage."

last-job:
  stage: .post
  script:
    - echo "This job runs in the .post stage, after all other stages."

job2:
  stage: test
  script:
    - echo "This job runs in the test stage."
```

**Informations complémentaires** :

- Une [politique d'exécution de pipeline](../../user/application_security/policies/pipeline_execution_policies.md) peut définir une étape `.pipeline-policy-post` qui s'exécute après `.post`.

---

### `tags` {#tags}

Utilisez `tags` pour sélectionner un runner spécifique parmi la liste de tous les runners disponibles pour le projet.

Lorsque vous enregistrez un runner, vous pouvez spécifier les tags du runner, par exemple `ruby`, `postgres` ou `development`. Pour récupérer et exécuter un job, un runner doit disposer de chaque tag listé dans le job.

La configuration du job et la configuration par défaut ne sont pas fusionnées. Si le pipeline a [`default:tags`](#default) défini, et que le job a également `tags`, la configuration du job est prioritaire et la configuration par défaut n'est pas utilisée.

**Type de mot-clé** : Mot-clé de job. Vous pouvez l'utiliser uniquement dans un job ou dans la [section `default`](#default).

**Valeurs prises en charge** :

- Un tableau de noms de tags, sensibles à la casse.
- Les variables CI/CD [sont prises en charge](../variables/where_variables_can_be_used.md#gitlab-ciyml-file).

**Exemple de `tags`** :

```yaml
job:
  tags:
    - ruby
    - postgres
```

Dans cet exemple, seuls les runners disposant à la fois des tags `ruby` et `postgres` peuvent exécuter le job.

**Informations complémentaires** :

- Le nombre de tags doit être inférieur à `50`.

**Sujets connexes** :

- [Utiliser les tags pour contrôler les jobs qu'un runner peut exécuter](../runners/configure_runners.md#control-jobs-that-a-runner-can-run)
- [Sélectionner différents tags de runner pour chaque job de matrice parallèle](../jobs/job_control.md#select-different-runner-tags-for-each-parallel-matrix-job)
- Tags de runner pour les runners hébergés :
  - [Runners hébergés sur Linux](../runners/hosted_runners/linux.md)
  - [Runners hébergés avec GPU](../runners/hosted_runners/gpu_enabled.md)
  - [Runners hébergés sur macOS](../runners/hosted_runners/macos.md)
  - [Runners hébergés sur Windows](../runners/hosted_runners/windows.md)

---

### `timeout` {#timeout}

Utilisez `timeout` pour configurer un délai d'expiration pour un job spécifique. Si le job s'exécute plus longtemps que le délai d'expiration, il échoue.

Le délai d'expiration au niveau du job peut être plus long que le [délai d'expiration au niveau du projet](../pipelines/settings.md#set-a-limit-for-how-long-jobs-can-run), mais ne peut pas être plus long que le [délai d'expiration du runner](../runners/configure_runners.md#set-the-maximum-job-timeout).

**Type de mot-clé** : Mot-clé de job. Vous pouvez l'utiliser uniquement dans un job.

**Valeurs prises en charge** : Une durée exprimée en langage naturel. Par exemple, ces valeurs sont toutes équivalentes :

- `3600 seconds`
- `60 minutes`
- `one hour`

**Exemple de `timeout`** :

```yaml
build:
  script: build.sh
  timeout: 3 hours 30 minutes

test:
  script: rspec
  timeout: 3h 30m
```

**Informations complémentaires** :

- Le mot-clé `timeout` n'est pas pris en charge dans la configuration `default`. Définissez plutôt `timeout` dans les configurations individuelles des jobs. Pour plus d'informations, voir le [ticket 213634](https://gitlab.com/gitlab-org/gitlab/-/issues/213634).

---

### `trigger` {#trigger}

{{< history >}}

- La prise en charge de `environment` a été [introduite](https://gitlab.com/gitlab-org/gitlab/-/issues/369061) dans GitLab 16.4.

{{< /history >}}

Utilisez `trigger` pour déclarer qu'un job est un « job de déclenchement » qui lance un [pipeline downstream](../pipelines/downstream_pipelines.md) qui est soit :

- [Un pipeline multi-projets](../pipelines/downstream_pipelines.md#multi-project-pipelines).
- [Un pipeline enfant](../pipelines/downstream_pipelines.md#parent-child-pipelines).

Les jobs de déclenchement ne peuvent utiliser qu'un ensemble limité de mots-clés de configuration GitLab CI/CD. Les mots-clés disponibles pour une utilisation dans les jobs de déclenchement sont :

- [`allow_failure`](#allow_failure).
- [`extends`](#extends).
- [`needs`](#needs), mais pas [`needs:project`](#needsproject).
- [`only` et `except`](deprecated_keywords.md#only--except).
- [`parallel`](#parallel).
- [`rules`](#rules).
- [`stage`](#stage).
- [`trigger`](#trigger).
- [`variables`](#variables).
- [`when`](#when) (uniquement avec une valeur de `on_success`, `on_failure`, `always` ou `manual`).
- [`resource_group`](#resource_group).
- [`environment`](#environment).

**Type de mot-clé** : Mot-clé de job. Vous pouvez l'utiliser uniquement dans un job.

**Valeurs prises en charge** :

- Pour les pipelines multi-projets, le chemin vers le projet downstream. Les variables CI/CD [sont prises en charge](../variables/where_variables_can_be_used.md#gitlab-ciyml-file) dans GitLab 15.3 et versions ultérieures, mais pas les [variables propres aux jobs](../variables/predefined_variables.md#variable-availability). Vous pouvez également utiliser [`trigger:project`](#triggerproject).
- Pour les pipelines enfants, utilisez [`trigger:include`](#triggerinclude).

**Exemple de `trigger`** :

```yaml
trigger-multi-project-pipeline:
  trigger: my-group/my-project
```

**Informations complémentaires** :

- Vous pouvez utiliser [`when:manual`](#when) dans le même job que `trigger`, mais vous ne pouvez pas utiliser l'API pour démarrer les jobs de déclenchement `when:manual`. Voir le [ticket 284086](https://gitlab.com/gitlab-org/gitlab/-/issues/284086) pour plus de détails.
- Vous ne pouvez pas [spécifier manuellement des variables CI/CD](../jobs/job_control.md#specify-variables-when-running-manual-jobs) avant d'exécuter un job de déclenchement manuel.
- Les [variables CI/CD](#variables) définies dans une section `variables` de niveau supérieur (globalement) ou dans le job de déclenchement sont transmises au pipeline downstream en tant que [variables de déclenchement](../pipelines/downstream_pipelines.md#pass-cicd-variables-to-a-downstream-pipeline).
- Les [variables de pipeline](../variables/_index.md#cicd-variable-precedence) ne sont pas transmises aux pipelines downstream par défaut. Utilisez [`trigger:forward`](#triggerforward) pour transmettre ces variables aux pipelines downstream.
- Les [variables propres aux jobs](../variables/predefined_variables.md#variable-availability) ne sont pas disponibles dans les jobs de déclenchement.
- Les variables d'environnement [définies dans le fichier `config.toml` du runner](https://docs.gitlab.com/runner/configuration/advanced-configuration/#the-runners-section) ne sont pas disponibles pour les jobs de déclenchement et ne sont pas transmises aux pipelines downstream.
- Vous ne pouvez pas utiliser [`needs:pipeline:job`](#needspipelinejob) dans un job de déclenchement.

**Sujets connexes** :

- [Exemples de configuration de pipeline multi-projets](../pipelines/downstream_pipelines.md#trigger-a-downstream-pipeline-from-a-job-in-the-gitlab-ciyml-file).
- Pour exécuter un pipeline pour une branche, un tag ou un commit spécifique, vous pouvez utiliser un [jeton de déclenchement](../triggers/_index.md) pour vous authentifier auprès de l'[API des déclencheurs de pipeline](../../api/pipeline_triggers.md). Le jeton de déclenchement est différent du mot-clé `trigger`.

---

#### `trigger:inputs` {#triggerinputs}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/519963) dans GitLab 17.11.

{{< /history >}}

Utilisez `trigger:inputs` pour définir les [entrées CI/CD](../inputs/_index.md) d'un pipeline multi-projets lorsque la configuration du pipeline downstream utilise [`spec:inputs`](#specinputs).

**Exemple de `trigger:inputs`** :

```yaml
trigger:
  - project: 'my-group/my-project'
    inputs:
      website: "My website"
```

---

#### `trigger:include` {#triggerinclude}

Utilisez `trigger:include` pour déclarer qu'un job est un « job de déclenchement » qui lance un [pipeline enfant](../pipelines/downstream_pipelines.md#parent-child-pipelines).

**Type de mot-clé** : Mot-clé de job. Vous pouvez l'utiliser uniquement dans un job.

**Valeurs prises en charge** :

- Le chemin vers le fichier de configuration du pipeline enfant.

**Exemple de `trigger:include`** :

```yaml
trigger-child-pipeline:
  trigger:
    include: path/to/child-pipeline.gitlab-ci.yml
```

**Informations complémentaires** :

Utilisez :

- `trigger:include:artifact` pour déclencher un [pipeline enfant dynamique](../pipelines/downstream_pipelines.md#dynamic-child-pipelines).
- `trigger:include:inputs` pour définir les [entrées CI/CD](../inputs/_index.md) lorsque la configuration du pipeline downstream utilise [`spec:inputs`](#specinputs).
- `trigger:include:local` pour un chemin vers un fichier de configuration de pipeline enfant lorsque :
  - Combinaison de [plusieurs fichiers de configuration de pipeline enfant](../pipelines/downstream_pipelines.md#combine-multiple-child-pipeline-configuration-files).
  - Combiné avec `trigger:include:inputs` pour transmettre des entrées au pipeline parent-enfant. Par exemple :

    ```yaml
    staging-job:
      trigger:
        include:
          - local: path/to/child-pipeline.yml
            inputs:
              environment: staging
    ```

- `trigger:include:project` pour déclencher un pipeline parent-enfant [avec un fichier de configuration dans un autre projet](../pipelines/downstream_pipelines.md#use-a-child-pipeline-configuration-file-in-a-different-project). Si le fichier contient des entrées [`include`](#include) supplémentaires, GitLab recherche les fichiers dans le projet exécutant le pipeline, et non dans le projet hébergeant le fichier.
- `trigger:include:template` pour déclencher un pipeline parent-enfant avec un template CI/CD.

**Sujets connexes** :

- [Exemples de configuration de pipeline parent-enfant](../pipelines/downstream_pipelines.md#trigger-a-downstream-pipeline-from-a-job-in-the-gitlab-ciyml-file).

---

#### `trigger:include:inputs` {#triggerincludeinputs}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/519963) dans GitLab 17.11.

{{< /history >}}

Utilisez `trigger:include:inputs` pour définir les [entrées](../inputs/_index.md) d'un pipeline parent-enfant lorsque la configuration du pipeline downstream utilise [`spec:inputs`](#specinputs).

**Exemple de `trigger:inputs`** :

```yaml
trigger-job:
  trigger:
    include:
      - local: path/to/child-pipeline.yml
        inputs:
          website: "My website"
```

---

#### `trigger:project` {#triggerproject}

Utilisez `trigger:project` pour déclarer qu'un job est un « job déclencheur » qui démarre un [pipeline multi-projets](../pipelines/downstream_pipelines.md#multi-project-pipelines).

Par défaut, le pipeline multi-projets se déclenche pour la branche par défaut. Utilisez `trigger:branch` pour spécifier une autre branche.

**Type de mot-clé** : Mot-clé de job. Vous pouvez l'utiliser uniquement dans un job.

**Valeurs prises en charge** :

- Le chemin vers le projet downstream. Les variables CI/CD [sont prises en charge](../variables/where_variables_can_be_used.md#gitlab-ciyml-file) dans GitLab 15.3 et versions ultérieures, mais pas les [variables propres aux jobs](../variables/predefined_variables.md#variable-availability).

**Exemple de `trigger:project`** :

```yaml
trigger-multi-project-pipeline:
  trigger:
    project: my-group/my-project
```

**Exemple de `trigger:project` pour une autre branche** :

```yaml
trigger-multi-project-pipeline:
  trigger:
    project: my-group/my-project
    branch: development
```

**Sujets connexes** :

- [Exemples de configuration de pipeline multi-projets](../pipelines/downstream_pipelines.md#trigger-a-downstream-pipeline-from-a-job-in-the-gitlab-ciyml-file).
- Pour exécuter un pipeline pour une branche, un tag ou un commit spécifique, vous pouvez également utiliser un [jeton de déclenchement](../triggers/_index.md) pour vous authentifier auprès de l'[API de déclenchement de pipelines](../../api/pipeline_triggers.md). Le jeton de déclenchement est différent du mot-clé `trigger`.

---

#### `trigger:strategy` {#triggerstrategy}

{{< history >}}

- Option `strategy:mirror` [introduite](https://gitlab.com/gitlab-org/gitlab/-/issues/431882) dans GitLab 18.2.

{{< /history >}}

Utilisez `trigger:strategy` pour forcer le job `trigger` à attendre que le pipeline downstream se termine avant d'être marqué comme **réussi**.

Ce comportement est différent du comportement par défaut, selon lequel le job `trigger` est marqué comme **réussi** dès que le pipeline downstream est créé.

Ce paramètre rend l'exécution de votre pipeline linéaire plutôt que parallèle.

**Valeurs prises en charge** :

- `mirror` : Reproduit exactement le statut du pipeline downstream.
- `depend` : Non recommandé, utilisez `mirror` à la place. Le statut du job déclencheur affiche **en échec**, **réussi** ou **en cours**, selon le statut du pipeline downstream. Consultez les informations complémentaires.

**Exemple de `trigger:strategy`** :

```yaml
trigger_job:
  trigger:
    include: path/to/child-pipeline.yml
    strategy: mirror
```

Dans cet exemple, les jobs des étapes suivantes attendent que le pipeline déclenché se termine avec succès avant de démarrer.

**Informations complémentaires** :

- Les [jobs manuels facultatifs](../jobs/job_control.md#types-of-manual-jobs) du pipeline downstream n'affectent pas le statut du pipeline downstream ni le job déclencheur upstream. Le pipeline downstream peut se terminer avec succès sans exécuter aucun job manuel facultatif.
- Par défaut, les jobs des étapes ultérieures ne démarrent pas tant que le job déclencheur n'est pas terminé.
- Les [jobs manuels bloquants](../jobs/job_control.md#types-of-manual-jobs) du pipeline downstream doivent s'exécuter avant que le job déclencheur soit marqué comme réussi ou en échec.
- Lors de l'utilisation de `strategy:depend` (plus recommandé, utilisez `strategy:mirror` à la place) :
  - Le job déclencheur affiche **en cours** ({{< icon name="status_running" >}}) si le statut du pipeline downstream est **en attente d'une action manuelle** ({{< icon name="status_manual" >}}) en raison de jobs manuels.
  - Si le pipeline downstream contient un job en échec, mais que le job utilise [`allow_failure: true`](#allow_failure), le pipeline downstream est considéré comme réussi et le job déclencheur affiche **réussi**.

---

#### `trigger:forward` {#triggerforward}

{{< history >}}

- [Disponible de manière générale](https://gitlab.com/gitlab-org/gitlab/-/issues/355572) dans GitLab 15.1. [Feature flag `ci_trigger_forward_variables`](https://gitlab.com/gitlab-org/gitlab/-/issues/355572) supprimé.

{{< /history >}}

Utilisez `trigger:forward` pour spécifier ce qui doit être transmis au pipeline downstream. Vous pouvez contrôler ce qui est transmis aux [pipelines parent-enfant](../pipelines/downstream_pipelines.md#parent-child-pipelines) et aux [pipelines multi-projets](../pipelines/downstream_pipelines.md#multi-project-pipelines).

Les variables transmises ne sont pas retransmises dans les pipelines downstream imbriqués par défaut, sauf si le job déclencheur downstream imbriqué utilise également `trigger:forward`.

**Valeurs prises en charge** :

- `yaml_variables` : `true` (par défaut), ou `false`. Lorsque la valeur est `true`, les variables définies dans le job déclencheur sont transmises aux pipelines downstream.
- `pipeline_variables` : `true` ou `false` (par défaut). Lorsque la valeur est `true`, les [variables de pipeline](../variables/_index.md#cicd-variable-precedence) sont transmises au pipeline downstream.

**Exemple de `trigger:forward`** :

[Exécutez ce pipeline manuellement](../pipelines/_index.md#run-a-pipeline-manually), avec la variable CI/CD `MYVAR = my value` :

```yaml
variables: # default variables for each job
  VAR: value

---

# Default behavior:
---

# - VAR is passed to the child
---

# - MYVAR is not passed to the child
child1:
  trigger:
    include: .child-pipeline.yml

---

# Forward pipeline variables:
---

# - VAR is passed to the child
---

# - MYVAR is passed to the child
child2:
  trigger:
    include: .child-pipeline.yml
    forward:
      pipeline_variables: true

---

# Do not forward YAML variables:
---

# - VAR is not passed to the child
---

# - MYVAR is not passed to the child
child3:
  trigger:
    include: .child-pipeline.yml
    forward:
      yaml_variables: false
```

**Informations complémentaires** :

- Les variables CI/CD transmises aux pipelines downstream avec `trigger:forward` sont des [variables de pipeline](../variables/_index.md#cicd-variable-precedence), qui ont une priorité élevée. Si une variable portant le même nom est définie dans le pipeline downstream, cette variable est généralement écrasée par la variable transmise.

---

### `when` {#when}

Utilisez `when` pour configurer les conditions dans lesquelles les jobs s'exécutent. Si non définie dans un job, la valeur par défaut est `when: on_success`.

**Type de mot-clé** : Mot-clé de job. Vous pouvez l'utiliser dans le cadre d'un job. `when: always` et `when: never` peuvent également être utilisés dans [`workflow:rules`](#workflow).

**Valeurs prises en charge** :

- `on_success` (par défaut) : Exécuter le job uniquement lorsqu'aucun job des étapes précédentes n'échoue.
- `on_failure` : Exécuter le job uniquement lorsqu'au moins un job d'une étape précédente échoue.
- `never` : Ne pas exécuter le job quel que soit le statut des jobs des étapes précédentes. Peut être utilisé uniquement dans une section [`rules`](#ruleswhen) ou [`workflow: rules`](#workflowrules).
- `always` : Exécuter le job quel que soit le statut des jobs des étapes précédentes.
- `manual` : Ajouter le job au pipeline en tant que [job manuel](../jobs/job_control.md#create-a-job-that-must-be-run-manually).
- `delayed` : Ajouter le job au pipeline en tant que [job différé](../jobs/job_control.md#run-a-job-after-a-delay).

**Exemple de `when`** :

```yaml
stages:
  - build
  - cleanup_build
  - test
  - deploy
  - cleanup

build_job:
  stage: build
  script:
    - make build

cleanup_build_job:
  stage: cleanup_build
  script:
    - cleanup build when failed
  when: on_failure

test_job:
  stage: test
  script:
    - make test

deploy_job:
  stage: deploy
  script:
    - make deploy
  when: manual
  environment: production

cleanup_job:
  stage: cleanup
  script:
    - cleanup after jobs
  when: always
```

Dans cet exemple, le script :

1. Exécute `cleanup_build_job` uniquement lorsque `build_job` échoue.
1. Exécute toujours `cleanup_job` comme dernière étape du pipeline, quelle que soit la réussite ou l'échec.
1. Exécute `deploy_job` lorsque vous le lancez manuellement dans l'interface GitLab.

**Informations complémentaires** :

- Lors de l'évaluation du statut des jobs pour `on_success` et `on_failure` :
  - Les jobs avec [`allow_failure: true`](#allow_failure) dans les étapes précédentes sont considérés comme réussis, même s'ils ont échoué.
  - Les jobs ignorés dans les étapes précédentes, par exemple les [jobs manuels qui n'ont pas été démarrés](../jobs/job_control.md#create-a-job-that-must-be-run-manually), sont considérés comme réussis.
- La valeur par défaut de [`allow_failure`](#allow_failure) est `true` avec `when: manual`. La valeur par défaut passe à `false` avec [`rules:when: manual`](#ruleswhen).

**Sujets connexes** :

- `when` peut être utilisé avec [`rules`](#rules) pour un contrôle des jobs plus dynamique.
- `when` peut être utilisé avec [`workflow`](#workflow) pour contrôler quand un pipeline peut démarrer.

---

#### `manual_confirmation` {#manual_confirmation}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/18906) dans GitLab 17.1.
- Prise en charge des jobs d'arrêt d'environnement [introduite](https://gitlab.com/gitlab-org/gitlab/-/issues/479318) dans GitLab 18.3.

{{< /history >}}

Utilisez `manual_confirmation` avec [`when: manual`](#when) pour définir un message de confirmation personnalisé pour les jobs manuels. Si aucun job manuel n'est défini avec `when: manual`, ce mot-clé est sans effet.

La confirmation manuelle fonctionne avec tous les jobs manuels, y compris les jobs d'arrêt d'environnement qui utilisent [`environment:action: stop`](#environmentaction).

**Type de mot-clé** : Mot-clé de job. Vous pouvez l'utiliser uniquement dans un job.

**Valeurs prises en charge** :

- Une chaîne contenant le message de confirmation.

**Exemple de `manual_confirmation`** :

```yaml
delete_job:
  stage: post-deployment
  script:
    - make delete
  when: manual
  manual_confirmation: 'Are you sure you want to delete this environment?'

stop_production:
  stage: cleanup
  script:
    - echo "Stopping production environment"
  environment:
    name: production
    action: stop
  when: manual
  manual_confirmation: "Are you sure you want to stop the production environment?"
```

---

### `start_in` {#start_in}

Utilisez `start_in` pour retarder l'exécution d'un job d'une durée spécifiée après la création du job. Vous devez configurer `when: delayed` pour le job.

**Type de mot-clé** : Mot-clé de job. Vous pouvez l'utiliser uniquement dans un job.

**Possible inputs** : Une durée en secondes, minutes ou heures. Doit être inférieur ou égal à une semaine. Exemples de valeurs valides :

- `'5'` (5 secondes)
- `'10 seconds'`
- `'30 minutes'`
- `'1 hour'`
- `'1 day'`

**Exemple de `start_in`** :

```yaml
deploy_production:
  stage: deploy
  script:
    - echo "Deploying to production"
  when: delayed
  start_in: 30 minutes
```

Dans cet exemple, le job `deploy_production` démarre 30 minutes après la fin de l'étape précédente.

**Informations complémentaires** :

- La minuterie démarre lorsque l'étape du job commence, et non lorsque le job précédent se termine.
- Pour démarrer immédiatement un job différé manuellement, sélectionnez **Play** ({{< icon name="play" >}}) dans la vue du pipeline.
- Le délai minimum est d'une seconde et le délai maximum est d'une semaine.
- `start_in` fonctionne uniquement lorsque [`when`](#when) est défini sur `delayed`. Si vous utilisez une autre valeur pour `when`, la configuration est invalide. Si un job utilise `rules`, `start_in` et `when` doivent être définis dans `rules`, et non au niveau du job. Sinon, vous recevez une erreur de validation : `config key may not be used with 'rules': start_in`.
- `start_in` n'est pas pris en charge avec `workflow:rules`, mais ne provoque aucune violation de syntaxe.

**Sujets connexes** :

- [Exécuter un job après un délai](../jobs/job_control.md#run-a-job-after-a-delay)

---

## `variables` {#variables}

Utilisez `variables` pour définir des [variables CI/CD](../variables/_index.md#define-a-cicd-variable-in-the-gitlab-ciyml-file).

Les variables peuvent être [définies dans un job CI/CD](#job-variables), ou en tant que mot-clé de niveau supérieur (global) pour définir des [variables CI/CD par défaut](#default-variables) pour tous les jobs.

**Informations complémentaires** :

- Toutes les variables définies en YAML sont également transmises aux [conteneurs de service Docker](../services/_index.md) associés.
- Les variables définies en YAML sont destinées à la configuration de projet non sensible. Stockez les informations sensibles dans des [variables protégées](../variables/_index.md#protect-a-cicd-variable) ou des [secrets CI/CD](../secrets/_index.md).
- Les [variables de pipeline manuel](../variables/_index.md#use-pipeline-variables) et les [variables de pipeline planifié](../pipelines/schedules.md#create-a-pipeline-schedule) ne sont pas transmises aux pipelines downstream par défaut. Utilisez [`trigger:forward`](#triggerforward) pour transmettre ces variables aux pipelines downstream.

**Sujets connexes** :

- Les [variables prédéfinies](../variables/predefined_variables.md) sont des variables que le runner crée automatiquement et met à disposition dans le job.
- Vous pouvez [configurer le comportement du runner avec des variables](../runners/configure_runners.md#configure-runner-behavior-with-variables).

---

### Job `variables` {#job-variables}

Vous pouvez utiliser des variables de job dans les commandes des sections `script`, `before_script` ou `after_script` du job, ainsi qu'avec certains [mots-clés de job](#job-keywords). Consultez la section **Valeurs prises en charge** de chaque mot-clé de job pour vérifier s'il prend en charge les variables.

Vous ne pouvez pas utiliser les variables de job comme valeurs pour des [mots-clés globaux](#global-keywords) tels que [`include`](includes.md#use-variables-with-include).

**Valeurs prises en charge** : Paires nom-valeur de variables :

- Le nom ne peut contenir que des chiffres, des lettres et des tirets bas (`_`). Dans certains shells, le premier caractère doit être une lettre.
- La valeur doit être une chaîne de caractères.

Les variables CI/CD [sont prises en charge](../variables/where_variables_can_be_used.md#gitlab-ciyml-file).

**Exemple de `variables` de job** :

```yaml
review_job:
  variables:
    DEPLOY_SITE: "https://dev.example.com/"
    REVIEW_PATH: "/review"
  script:
    - deploy-review-script --url $DEPLOY_SITE --path $REVIEW_PATH
```

Dans cet exemple :

- `review_job` a les variables de job `DEPLOY_SITE` et `REVIEW_PATH` définies. Les deux variables de job peuvent être utilisées dans la section `script`.

---

### `variables` par défaut {#default-variables}

Les variables définies dans une section `variables` de niveau supérieur servent de variables par défaut pour tous les jobs.

Chaque variable par défaut est mise à disposition de chaque job dans le pipeline, sauf lorsque le job possède déjà une variable définie avec le même nom. La variable définie dans le job [est prioritaire](../variables/_index.md#cicd-variable-precedence), de sorte que la valeur de la variable par défaut portant le même nom ne peut pas être utilisée dans le job.

Comme pour les variables de job, vous ne pouvez pas utiliser les variables par défaut comme valeurs pour d'autres mots-clés globaux, tels que [`include`](includes.md#use-variables-with-include).

**Valeurs prises en charge** : Paires nom-valeur de variables :

- Le nom ne peut contenir que des chiffres, des lettres et des tirets bas (`_`). Dans certains shells, le premier caractère doit être une lettre.
- La valeur doit être une chaîne de caractères.

Les variables CI/CD [sont prises en charge](../variables/where_variables_can_be_used.md#gitlab-ciyml-file).

**Exemples de `variables`** :

```yaml
variables:
  DEPLOY_SITE: "https://example.com/"

deploy_job:
  stage: deploy
  script:
    - deploy-script --url $DEPLOY_SITE --path "/"
  environment: production

deploy_review_job:
  stage: deploy
  variables:
    DEPLOY_SITE: "https://dev.example.com/"
    REVIEW_PATH: "/review"
  script:
    - deploy-review-script --url $DEPLOY_SITE --path $REVIEW_PATH
  environment: production
```

Dans cet exemple :

- `deploy_job` n'a aucune variable définie. La variable `DEPLOY_SITE` par défaut est copiée dans le job et peut être utilisée dans la section `script`.
- `deploy_review_job` a déjà une variable `DEPLOY_SITE` définie, de sorte que la valeur par défaut `DEPLOY_SITE` n'est pas copiée dans le job. Le job a également une variable de job `REVIEW_PATH` définie. Les deux variables de job peuvent être utilisées dans la section `script`.

---

#### `variables:description` {#variablesdescription}

Utilisez le mot-clé `description` pour définir une description pour une variable par défaut. La description s'affiche avec [le nom de la variable prérempli lors de l'exécution manuelle d'un pipeline](../pipelines/_index.md#prefill-variables-in-manual-pipelines).

**Type de mot-clé** : Vous ne pouvez utiliser ce mot-clé qu'avec les `variables` par défaut, et non avec les `variables` de job.

**Valeurs prises en charge** :

- Une chaîne de caractères. Vous pouvez utiliser Markdown.

**Exemple de `variables:description`** :

```yaml
variables:
  DEPLOY_NOTE:
    description: "The deployment note. Explain the reason for this deployment."
```

**Informations complémentaires** :

- Lorsqu'utilisé sans `value`, la variable existe dans les pipelines qui n'ont pas été déclenchés manuellement, et la valeur par défaut est une chaîne vide (`''`).

---

#### `variables:value` {#variablesvalue}

Utilisez le mot-clé `value` pour définir la valeur d'une variable de niveau pipeline (par défaut). Lorsqu'utilisé avec [`variables: description`](#variablesdescription), la valeur de la variable est [préremplie lors de l'exécution manuelle d'un pipeline](../pipelines/_index.md#prefill-variables-in-manual-pipelines).

**Type de mot-clé** : Vous ne pouvez utiliser ce mot-clé qu'avec les `variables` par défaut, et non avec les `variables` de job.

**Valeurs prises en charge** :

- Une chaîne de caractères.

**Exemple de `variables:value`** :

```yaml
variables:
  DEPLOY_ENVIRONMENT:
    value: "staging"
    description: "The deployment target. Change this variable to 'canary' or 'production' if needed."
```

**Informations complémentaires** :

- Si utilisé sans [`variables: description`](#variablesdescription), le comportement est identique à celui de [`variables`](#variables).

---

#### `variables:options` {#variablesoptions}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/105502) dans GitLab 15.7.

{{< /history >}}

Utilisez `variables:options` pour définir un tableau de valeurs [sélectionnables dans l'interface lors de l'exécution manuelle d'un pipeline](../pipelines/_index.md#configure-a-list-of-selectable-prefilled-variable-values).

Doit être utilisé avec `variables: value`, et la chaîne définie pour `value` :

- Doit également être l'une des chaînes du tableau `options`.
- Est la sélection par défaut.

En l'absence de [`description`](#variablesdescription), ce mot-clé est sans effet.

**Type de mot-clé** : Vous ne pouvez utiliser ce mot-clé qu'avec les `variables` par défaut, et non avec les `variables` de job.

**Valeurs prises en charge** :

- Un tableau de chaînes de caractères.

**Exemple de `variables:options`** :

```yaml
variables:
  DEPLOY_ENVIRONMENT:
    value: "staging"
    options:
      - "production"
      - "staging"
      - "canary"
    description: "The deployment target. Set to 'staging' by default."
```

---

### `variables:expand` {#variablesexpand}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/353991) dans GitLab 15.6 [avec un indicateur](../../administration/feature_flags/_index.md) nommé `ci_raw_variables_in_yaml_config`. Désactivé par défaut.
- [Activé sur GitLab.com](https://gitlab.com/gitlab-org/gitlab/-/issues/375034) dans GitLab 15.6.
- [Activé sur GitLab Self-Managed](https://gitlab.com/gitlab-org/gitlab/-/issues/375034) dans GitLab 15.7.
- [Disponible de manière générale](https://gitlab.com/gitlab-org/gitlab/-/issues/375034) dans GitLab 15.8. Le feature flag `ci_raw_variables_in_yaml_config` a été supprimé.

{{< /history >}}

Utilisez le mot-clé `expand` pour configurer une variable comme étant développable ou non.

**Type de mot-clé** : Vous pouvez utiliser ce mot-clé avec les `variables` par défaut et de job.

**Valeurs prises en charge** :

- `true` (par défaut) : La variable est développable.
- `false` : La variable n'est pas développable.

**Exemple de `variables:expand`** :

```yaml
variables:
  VAR1: value1
  VAR2: value2 $VAR1
  VAR3:
    value: value3 $VAR1
    expand: false
```

- Le résultat de `VAR2` est `value2 value1`.
- Le résultat de `VAR3` est `value3 $VAR1`.

**Informations complémentaires** :

- Le mot-clé `expand` ne peut être utilisé qu'avec les mots-clés `variables` par défaut et de job. Vous ne pouvez pas l'utiliser avec [`rules:variables`](#rulesvariables) ou [`workflow:rules:variables`](#workflowrulesvariables).
