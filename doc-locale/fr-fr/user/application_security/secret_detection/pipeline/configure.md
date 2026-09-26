---
stage: Application Security Testing
group: Secret Detection
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Personnaliser la détection des secrets dans les pipelines
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

En fonction de votre [édition d'abonnement](_index.md#availability) et de la méthode de configuration, vous pouvez modifier le fonctionnement de la détection des secrets dans les pipelines.

[Personnalisez le comportement de l'analyseur](#customize-analyzer-behavior) pour :

- Modifier les types de secrets détectés par l'analyseur.
- Utiliser une version différente de l'analyseur.
- Analyser votre projet avec une méthode spécifique.

[Personnalisez les ensembles de règles de l'analyseur](#customize-analyzer-rulesets) pour :

- Détecter des types de secrets personnalisés.
- Remplacer les règles par défaut du scanner.

## Personnaliser le comportement de l'analyseur {#customize-analyzer-behavior}

Pour modifier le comportement de l'analyseur, définissez des variables à l'aide du paramètre [`variables`](../../../../ci/yaml/_index.md#variables) dans `.gitlab-ci.yml`.

> [!warning]
> Toute configuration des outils d'analyse de sécurité GitLab doit être testée dans une merge request avant de fusionner ces modifications dans la branche par défaut. Ne pas le faire peut donner des résultats inattendus, y compris un grand nombre de faux positifs.

### Ajouter de nouveaux modèles {#add-new-patterns}

Pour rechercher d'autres types de secrets dans vos dépôts, vous pouvez [personnaliser les ensembles de règles de l'analyseur](#customize-analyzer-rulesets).

### Proposer de nouvelles règles de détection {#propose-new-detection-rules}

Vous pouvez proposer de nouvelles règles de détection pour tous les utilisateurs de la détection des secrets dans les pipelines de deux manières :

- Demander une nouvelle règle : créez un ticket à l'aide du [modèle de ticket Secret Detection Pattern Change](https://gitlab.com/gitlab-org/gitlab/-/work_items/new?description_template=Secret_Detection_Pattern_Change). L'équipe GitLab examinera la demande et vous contactera pour décider comment et quand la nouvelle règle sera mise en œuvre.
- Contribuer une nouvelle règle : si vous souhaitez contribuer vous-même à la règle, suivez les [directives de contribution](https://gitlab.com/gitlab-org/security-products/secret-detection/secret-detection-rules/-/blob/main/README.md#adding-new-rules) dans le dépôt Secret Detection Rules.

Si vous exploitez un produit cloud ou SaaS et que vous souhaitez vous associer à GitLab pour mieux protéger vos utilisateurs, consultez le [programme partenaire de GitLab pour les notifications de fuites d'identifiants](../automatic_response.md#partner-program-for-leaked-credential-notifications).

### Épingler à une version spécifique de l'analyseur {#pin-to-specific-analyzer-version}

Le template CI/CD géré par GitLab spécifie une version majeure et extrait automatiquement la dernière release de l'analyseur au sein de cette version majeure.

Dans certains cas, vous pouvez avoir besoin d'utiliser une version spécifique. Par exemple, vous pourriez avoir besoin d'éviter une régression dans une release ultérieure.

Pour remplacer le comportement de mise à jour automatique, définissez la variable CI/CD `SECRETS_ANALYZER_VERSION` dans votre fichier de configuration CI/CD après avoir inclus le [modèle `Secret-Detection.gitlab-ci.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Jobs/Secret-Detection.gitlab-ci.yml).

Vous pouvez définir le tag sur :

- Une version majeure, comme `4`. Vos pipelines utilisent toutes les mises à jour mineures ou de correctifs publiées dans cette version majeure. Vos pipelines utilisent toutes les mises à jour mineures ou de correctif publiées dans cette version majeure.
- Une version mineure, comme `4.5`. Vos pipelines utilisent toutes les mises à jour de correctifs publiées dans cette version mineure. Vos pipelines utilisent toutes les mises à jour de correctif publiées dans cette version mineure.
- Une version de correctif, comme `4.5.0`. Vos pipelines ne reçoivent aucune mise à jour. Vos pipelines ne reçoivent aucune mise à jour.

Cet exemple utilise une version mineure spécifique de l'analyseur :

```yaml
include:
  - template: Jobs/Secret-Detection.gitlab-ci.yml

secret_detection:
  variables:
    SECRETS_ANALYZER_VERSION: "4.5"
```

### Activer l'analyse historique {#enable-historic-scan}

Pour activer une analyse historique, définissez la variable `SECRET_DETECTION_HISTORIC_SCAN` sur `true` dans votre fichier `.gitlab-ci.yml`.

### Exécuter des jobs dans les pipelines de merge request {#run-jobs-in-merge-request-pipelines}

Consultez [Utiliser les outils d'analyse de sécurité avec les pipelines de merge request](../../detect/security_configuration.md#use-security-scanning-tools-with-merge-request-pipelines).

### Remplacer les jobs de l'analyseur {#override-the-analyzer-jobs}

Pour remplacer une définition de job (par exemple, modifier des propriétés telles que `variables` ou `dependencies`), déclarez un job portant le même nom que le job `secret_detection` à remplacer. Placez ce nouveau job après l'inclusion du template et spécifiez les clés supplémentaires sous celui-ci.

Dans l'extrait d'exemple suivant d'un fichier `.gitlab-ci.yml` :

- Le modèle CI/CD `Jobs/Secret-Detection` est [inclus](../../../../ci/yaml/_index.md#include).
- Dans le job `secret_detection`, la variable CI/CD `SECRET_DETECTION_HISTORIC_SCAN` est définie sur `true`. Le modèle étant évalué avant la configuration du pipeline, la dernière mention de la variable est prioritaire, une analyse historique est donc effectuée.

```yaml
include:
  - template: Jobs/Secret-Detection.gitlab-ci.yml

secret_detection:
  variables:
    SECRET_DETECTION_HISTORIC_SCAN: "true"
```

### Variables CI/CD disponibles {#available-cicd-variables}

Modifiez le comportement de la détection des secrets dans les pipelines en définissant les variables CI/CD disponibles :

| Variable CI/CD                    | Valeur par défaut | Description |
|-----------------------------------|---------------|-------------|
| `SECRET_DETECTION_EXCLUDED_PATHS` | ""            | Exclut les vulnérabilités de la sortie en fonction des chemins. Les chemins forment une liste de modèles séparés par des virgules. Les modèles peuvent être des globs (voir [`doublestar.Match`](https://pkg.go.dev/github.com/bmatcuk/doublestar/v4@v4.0.2#Match) pour les modèles pris en charge), ou des chemins de fichiers ou de dossiers (par exemple, `doc,spec` ). Les répertoires parents correspondent également aux modèles. Les secrets détectés précédemment ajoutés au rapport de vulnérabilités ne sont pas supprimés. |
| `SECRET_DETECTION_HISTORIC_SCAN`  | false         | Indicateur permettant d'activer une analyse Gitleaks historique. |
| `SECRET_DETECTION_IMAGE_SUFFIX`   | "" | Suffixe ajouté au nom de l'image. Si défini sur `-fips`, les images `FIPS-enabled` sont utilisées pour l'analyse. Consultez [Utiliser des images compatibles FIPS](_index.md#fips-enabled-images) pour plus d'informations. |
| `SECRET_DETECTION_LOG_OPTIONS`  | ""        | Indicateur permettant de spécifier une plage de commits à analyser. Gitleaks utilise [`git log`](https://git-scm.com/docs/git-log) pour déterminer la plage de commits. Lorsqu'elle est définie, la détection des secrets dans les pipelines tente de récupérer tous les commits de la branche. Si l'analyseur ne peut pas accéder à tous les commits, il continue avec le dépôt déjà extrait. |

## Personnaliser les ensembles de règles de l'analyseur {#customize-analyzer-rulesets}

{{< details >}}

- Édition : GitLab Ultimate

{{< /details >}}

{{< history >}}

- [Activation](https://gitlab.com/gitlab-org/gitlab/-/issues/336395) de la prise en charge des chaînes de passthroughs et ajout de types de passthroughs supplémentaires `git` et `url` dans GitLab 17.2.

{{< /history >}}

Vous pouvez personnaliser les types de secrets détectés par la détection des secrets dans les pipelines en créant un fichier de configuration d'ensemble de règles personnalisé, soit dans le dépôt analysé, soit dans un dépôt distant.

La personnalisation vous permet de

- Modifier le comportement des règles dans l'ensemble de règles par défaut.
- Remplacer l'ensemble de règles par défaut par un ensemble de règles personnalisé.
- Étendre le comportement de l'ensemble de règles par défaut.
- Ignorer des secrets et des chemins.

### Créer un fichier de configuration d'ensemble de règles {#create-a-ruleset-configuration-file}

Pour créer un fichier de configuration d'ensemble de règles :

1. Créez un répertoire `.gitlab` à la racine de votre projet, s'il n'existe pas déjà.
1. Créez un fichier nommé `secret-detection-ruleset.toml` dans le répertoire `.gitlab`.

### Modifier des règles de l'ensemble de règles par défaut {#modify-rules-from-the-default-ruleset}

Vous pouvez modifier les règles prédéfinies dans l'[ensemble de règles par défaut](../detected_secrets.md).

La modification des règles peut vous aider à adapter la détection des secrets dans les pipelines à un workflow ou à un outil existant. Par exemple, vous pouvez remplacer la gravité d'un secret détecté ou désactiver complètement une règle.

Vous pouvez également utiliser un fichier de configuration d'ensemble de règles stocké à distance (c'est-à-dire un dépôt Git distant ou un site web) pour modifier les règles prédéfinies. Les nouvelles règles doivent utiliser le [format de règle personnalisée](custom_rulesets_schema.md#custom-rule-format).

#### Désactiver une règle {#disable-a-rule}

Vous pouvez désactiver les règles que vous ne souhaitez pas activer. Pour désactiver des règles de l'ensemble de règles par défaut de l'analyseur :

1. [Créez un fichier de configuration d'ensemble de règles](#create-a-ruleset-configuration-file), s'il n'existe pas déjà.
1. Définissez l'indicateur `disabled` sur `true` dans le contexte d'une [section `ruleset`](custom_rulesets_schema.md#the-secretsruleset-section).
1. Dans une ou plusieurs sous-sections `ruleset.identifier`, listez les règles à désactiver. Chaque [section `ruleset.identifier`](custom_rulesets_schema.md#the-secretsrulesetidentifier-section) contient :
   - Un champ `type` pour l'identifiant de règle prédéfini.
   - Un champ `value` pour le nom de la règle.

Dans l'exemple de fichier `secret-detection-ruleset.toml` suivant, les règles désactivées sont mises en correspondance par le `type` et la `value` des identifiants :

```toml
[secrets]
  [[secrets.ruleset]]
    disable = true
    [secrets.ruleset.identifier]
      type  = "gitleaks_rule_id"
      value = "RSA private key"
```

#### Remplacer une règle {#override-a-rule}

Si certaines règles nécessitent une personnalisation, vous pouvez les remplacer. Par exemple, vous pouvez augmenter la gravité d'un type de secret spécifique car sa divulgation aurait un impact plus élevé sur votre workflow.

Pour remplacer des règles de l'ensemble de règles par défaut de l'analyseur :

1. [Créez un fichier de configuration d'ensemble de règles](#create-a-ruleset-configuration-file), s'il n'existe pas déjà.
1. Dans une ou plusieurs sous-sections `ruleset.identifier`, listez les règles à remplacer. Chaque [section `ruleset.identifier`](custom_rulesets_schema.md#the-secretsrulesetidentifier-section) contient :
   - Un champ `type` pour l'identifiant de règle prédéfini.
   - Un champ `value` pour le nom de la règle.
1. Dans le [contexte `ruleset.override`](custom_rulesets_schema.md#the-secretsrulesetoverride-section) d'une [section `ruleset`](custom_rulesets_schema.md#the-secretsruleset-section), fournissez les clés à remplacer. N'importe quelle combinaison de clés peut être remplacée. Les clés valides sont :
   - `description`
   - `message`
   - `name`
   - `severity` (options valides : `Critical`, `High`, `Medium`, `Low`, `Unknown`, `Info`)

Dans le fichier `secret-detection-ruleset.toml` suivant, les règles sont mises en correspondance par le `type` et la `value` des identifiants, puis remplacées :

```toml
[secrets]
  [[secrets.ruleset]]
    [secrets.ruleset.identifier]
      type  = "gitleaks_rule_id"
      value = "RSA private key"
    [secrets.ruleset.override]
      description = "OVERRIDDEN description"
      message     = "OVERRIDDEN message"
      name        = "OVERRIDDEN name"
      severity    = "Info"
```

#### Avec un ensemble de règles distant {#with-a-remote-ruleset}

Un ensemble de règles distant est un fichier de configuration stocké en dehors du dépôt actuel. Il peut être utilisé pour modifier des règles dans plusieurs projets.

Pour modifier une règle prédéfinie avec un ensemble de règles distant, vous pouvez utiliser la [variable CI/CD](../../../../ci/variables/_index.md) `SECRET_DETECTION_RULESET_GIT_REFERENCE` :

```yaml
include:
  - template: Jobs/Secret-Detection.gitlab-ci.yml

variables:
  SECRET_DETECTION_RULESET_GIT_REFERENCE: "gitlab.com/example-group/remote-ruleset-project"
```

La détection des secrets dans les pipelines suppose que la configuration est définie dans le fichier `.gitlab/secret-detection-ruleset.toml` du dépôt référencé par la variable CI/CD où l'ensemble de règles distant est stocké. Si ce fichier n'existe pas, veillez à [en créer un](#create-a-ruleset-configuration-file) et suivez les étapes pour [remplacer](#override-a-rule) ou [désactiver](#disable-a-rule) une règle prédéfinie comme indiqué précédemment.

> [!note]
> Un fichier local `.gitlab/secret-detection-ruleset.toml` dans le projet est prioritaire sur `SECRET_DETECTION_RULESET_GIT_REFERENCE` par défaut, car `SECURE_ENABLE_LOCAL_CONFIGURATION` est défini sur `true`. Si vous définissez `SECURE_ENABLE_LOCAL_CONFIGURATION` sur `false`, le fichier local est ignoré et la configuration par défaut ou `SECRET_DETECTION_RULESET_GIT_REFERENCE` (si défini) est utilisée.

La variable `SECRET_DETECTION_RULESET_GIT_REFERENCE` utilise un format similaire aux [URL Git](https://git-scm.com/docs/git-clone#_git_urls) pour spécifier un URI, une authentification optionnelle et un SHA Git optionnel. La variable utilise le format suivant :

```plaintext
<AUTH_USER>:<AUTH_PASSWORD>@<PROJECT_PATH>@<GIT_SHA>
```

Si le fichier de configuration est stocké dans un projet privé nécessitant une authentification, vous pouvez utiliser un [jeton d'accès de groupe](../../../group/settings/group_access_tokens.md) stocké de manière sécurisée dans une variable CI/CD pour charger l'ensemble de règles distant :

```yaml
include:
  - template: Jobs/Secret-Detection.gitlab-ci.yml

variables:
  SECRET_DETECTION_RULESET_GIT_REFERENCE: "group_2504721_bot_7c9311ffb83f2850e794d478ccee36f5:$GROUP_ACCESS_TOKEN@gitlab.com/example-group/remote-ruleset-project"
```

Le jeton d'accès de groupe doit avoir la portée `read_repository` et le rôle Reporter, Developer, Maintainer ou Owner. Pour plus d'informations, consultez [Permissions du dépôt](../../../permissions.md#project-repositories).

Consultez [les utilisateurs bot pour les groupes](../../../group/settings/group_access_tokens.md#bot-users-for-groups) pour savoir comment trouver le nom d'utilisateur associé à un jeton d'accès de groupe.

### Remplacer l'ensemble de règles par défaut {#replace-the-default-ruleset}

Vous pouvez remplacer la configuration de l'ensemble de règles par défaut en utilisant des [personnalisations](custom_rulesets_schema.md). Elles peuvent être combinées à l'aide de [passthroughs](custom_rulesets_schema.md#passthrough-types) en une seule configuration.

Grâce aux passthroughs, vous pouvez :

- Enchaîner jusqu'à [20 passthroughs](custom_rulesets_schema.md#the-secretspassthrough-section) en une seule configuration pour remplacer ou étendre des règles prédéfinies.
- Inclure des [variables d'environnement dans les passthroughs](custom_rulesets_schema.md#interpolate).
- Définir un [délai d'expiration](custom_rulesets_schema.md#the-secrets-configuration-section) pour l'évaluation des passthroughs.
- [Valider](custom_rulesets_schema.md#the-secrets-configuration-section) la syntaxe TOML utilisée dans chaque passthrough défini.

#### Avec un ensemble de règles en ligne {#with-an-inline-ruleset}

Vous pouvez utiliser le [passthrough `raw`](custom_rulesets_schema.md#passthrough-types) pour remplacer l'ensemble de règles par défaut par une configuration fournie en ligne.

Ajoutez ce qui suit dans le fichier de configuration `.gitlab/secret-detection-ruleset.toml` stocké dans le même dépôt, et ajustez la règle définie sous `[[rules]]` selon vos besoins :

```toml
[secrets]
  [[secrets.passthrough]]
    type   = "raw"
    target = "gitleaks.toml"
    value  = """
title = "replace default ruleset with a raw passthrough"

[[rules]]
description = "Test for Raw Custom Rulesets"
regex = '''Custom Raw Ruleset T[est]{3}'''
"""
```

L'exemple précédent remplace l'ensemble de règles par défaut par une règle qui vérifie la regex définie - `Custom Raw Ruleset T` avec un suffixe de 3 caractères parmi `e`, `s` ou `t`.

Pour plus d'informations sur la syntaxe de passthrough à utiliser, consultez [Schéma](custom_rulesets_schema.md#schema).

#### Avec un ensemble de règles local {#with-a-local-ruleset}

Vous pouvez utiliser le [passthrough `file`](custom_rulesets_schema.md#passthrough-types) pour remplacer l'ensemble de règles par défaut par un autre fichier commité dans le dépôt actuel.

Ajoutez ce qui suit dans le fichier de configuration `.gitlab/secret-detection-ruleset.toml` stocké dans le même dépôt, et ajustez la `value` selon vos besoins pour pointer vers le chemin du fichier contenant la configuration d'ensemble de règles local :

```toml
[secrets]
  [[secrets.passthrough]]
    type   = "file"
    target = "gitleaks.toml"
    value  = "config/gitleaks.toml"
```

Cela remplacerait l'ensemble de règles par défaut par la configuration définie dans le fichier `config/gitleaks.toml`.

Pour plus d'informations sur la syntaxe de passthrough à utiliser, consultez [Schéma](custom_rulesets_schema.md#schema).

#### Avec un ensemble de règles distant {#with-a-remote-ruleset-1}

Vous pouvez remplacer l'ensemble de règles par défaut par une configuration définie dans un dépôt Git distant ou un fichier stocké en ligne à l'aide des passthroughs `git` et `url`.

Un ensemble de règles distant peut être utilisé dans plusieurs projets. Par exemple, vous souhaitez peut-être appliquer le même ensemble de règles à plusieurs projets dans l'un de vos espaces de nommage ; dans ce cas, vous pouvez utiliser l'un ou l'autre type de passthrough pour charger cet ensemble de règles distant et l'utiliser dans plusieurs projets. Cela permet également une gestion centralisée d'un ensemble de règles, seules les personnes autorisées pouvant le modifier.

Pour utiliser le passthrough `git`, ajoutez ce qui suit dans le fichier de configuration `.gitlab/secret-detection-ruleset.toml` stocké dans un dépôt et ajustez la `value` pour pointer vers l'adresse du dépôt Git :

```toml
# .gitlab/secret-detection-ruleset.toml in https://gitlab.com/user_group/basic_repository
[secrets]
  [[secrets.passthrough]]
    type   = "git"
    ref    = "main"
    subdir = "config"
    value  = "https://gitlab.com/user_group/central_repository_with_shared_ruleset"
```

Dans cette configuration, l'analyseur charge l'ensemble de règles à partir du fichier `gitleaks.toml` situé dans le répertoire `config` sur la branche `main` du dépôt stocké à l'adresse `user_group/central_repository_with_shared_ruleset`. Vous pouvez ensuite inclure la même configuration dans des projets autres que `user_group/basic_repository`.

Vous pouvez également utiliser le passthrough `url` pour remplacer l'ensemble de règles par défaut par une configuration d'ensemble de règles distant.

Pour utiliser le passthrough `url`, ajoutez ce qui suit dans le fichier de configuration `.gitlab/secret-detection-ruleset.toml` stocké dans un dépôt et ajustez la `value` pour pointer vers l'adresse du fichier distant :

```toml
# .gitlab/secret-detection-ruleset.toml in https://gitlab.com/user_group/basic_repository
[secrets]
  [[secrets.passthrough]]
    type   = "url"
    target = "gitleaks.toml"
    value  = "https://example.com/gitleaks.toml"
```

Dans cette configuration, l'analyseur charge la configuration d'ensemble de règles à partir du fichier `gitleaks.toml` stocké à l'adresse fournie.

Pour plus d'informations sur la syntaxe de passthrough à utiliser, consultez [Schéma](custom_rulesets_schema.md#schema).

#### Avec un ensemble de règles distant privé {#with-a-private-remote-ruleset}

Si une configuration d'ensemble de règles est stockée dans un dépôt privé, vous devez fournir les identifiants pour accéder au dépôt en utilisant le [paramètre `auth`](custom_rulesets_schema.md#the-secretspassthrough-section) du passthrough.

> [!note]
> Le paramètre `auth` fonctionne uniquement avec le passthrough `git`.

Pour utiliser un ensemble de règles distant stocké dans un dépôt privé, ajoutez ce qui suit dans le fichier de configuration `.gitlab/secret-detection-ruleset.toml` stocké dans un dépôt, ajustez la `value` pour pointer vers l'adresse du dépôt Git, et mettez à jour `auth` pour utiliser les identifiants appropriés :

```toml
[secrets]
  [[secrets.passthrough]]
    type   = "git"
    ref    = "main"
    auth   = "USERNAME:PASSWORD" # replace USERNAME and PASSWORD as appropriate
    subdir = "config"
    value  = "https://gitlab.com/user_group/central_repository_with_shared_ruleset"
```

> [!warning]
> Attention à la fuite d'identifiants lors de l'utilisation de cette fonctionnalité. Consultez [cette section](custom_rulesets_schema.md#interpolate) pour un exemple d'utilisation de variables d'environnement afin de minimiser le risque.

Pour plus d'informations sur la syntaxe de passthrough à utiliser, consultez [Schéma](custom_rulesets_schema.md#schema).

### Activer les règles en version bêta {#turn-on-beta-rules}

Les règles en version bêta sont des règles de détection expérimentales qui ne font pas partie de l'ensemble de règles par défaut. Utilisez les règles en version bêta pour détecter des types de secrets supplémentaires avant que les règles ne soient promues dans l'ensemble de règles par défaut.

> [!warning]
> Les règles en version bêta sont expérimentales. Elles peuvent produire plus de faux positifs que les règles par défaut. Elles peuvent être modifiées ou supprimées sans préavis. Examinez attentivement les résultats des règles en version bêta.

L'image de l'analyseur inclut un ensemble de règles en version bêta dans `/beta.toml`. Cet ensemble de règles contient toutes les règles par défaut, ainsi que les règles avec une maturité `beta`. L'analyseur ne charge pas l'ensemble de règles en version bêta sauf si vous l'activez explicitement.

Pour activer les règles en version bêta, utilisez un [passthrough `file`](custom_rulesets_schema.md#passthrough-types) pour remplacer l'ensemble de règles par défaut par l'ensemble de règles en version bêta intégré. Ajoutez ce qui suit dans le fichier de configuration `.gitlab/secret-detection-ruleset.toml` stocké dans le même dépôt :

```toml
[secrets]
  [[secrets.passthrough]]
    type   = "file"
    target = "gitleaks.toml"
    value  = "/beta.toml"
```

L'ensemble de règles en version bêta inclut déjà les règles par défaut ; vous n'avez donc pas besoin d'étendre séparément l'ensemble de règles par défaut.

### Étendre l'ensemble de règles par défaut {#extend-the-default-ruleset}

Vous pouvez également étendre la configuration de l'[ensemble de règles par défaut](../detected_secrets.md) avec des règles supplémentaires selon vos besoins. Cela peut être utile lorsque vous souhaitez continuer à bénéficier des règles prédéfinies à haute confiance maintenues par GitLab dans l'ensemble de règles par défaut, tout en voulant ajouter des règles pour des types de secrets susceptibles d'être utilisés dans vos propres projets et espaces de nommage. Les nouvelles règles doivent respecter le [format des règles personnalisées](custom_rulesets_schema.md#custom-rule-format).

#### Avec un ensemble de règles local {#with-a-local-ruleset-1}

Vous pouvez utiliser un passthrough `file` pour étendre l'ensemble de règles par défaut afin d'ajouter des règles supplémentaires.

Ajoutez ce qui suit dans le fichier de configuration `.gitlab/secret-detection-ruleset.toml` stocké dans le même dépôt, et ajustez la `value` selon vos besoins pour pointer vers le chemin du fichier de configuration étendu :

```toml
# .gitlab/secret-detection-ruleset.toml
[secrets]
  [[secrets.passthrough]]
    type   = "file"
    target = "gitleaks.toml"
    value  = "extended-gitleaks-config.toml"
```

La configuration étendue stockée dans `extended-gitleaks-config.toml` est incluse dans la configuration utilisée par l'analyseur dans le pipeline CI/CD.

L'exemple ci-dessous ajoute de nouvelles sections `[[rules]]` avec des expressions régulières à mettre en correspondance :

```toml
# extended-gitleaks-config.toml
[extend]
# Extends default packaged ruleset, NOTE: do not change the path.
path = "/gitleaks.toml"

[[rules]]
  id = "example_api_key"
  description = "Example Service API Key"
  regex = '''example_api_key'''

[[rules]]
  id = "example_api_secret"
  description = "Example Service API Secret"
  regex = '''example_api_secret'''
```

Avec cette configuration d'ensemble de règles, l'analyseur détecte toutes les chaînes correspondant aux modèles regex définis.

Pour plus d'informations sur la syntaxe de passthrough à utiliser, consultez [Schéma](custom_rulesets_schema.md#schema).

#### Avec un ensemble de règles distant {#with-a-remote-ruleset-2}

De même qu'il est possible de remplacer l'ensemble de règles par défaut par un ensemble de règles distant, vous pouvez également étendre l'ensemble de règles par défaut avec une configuration stockée dans un dépôt Git distant ou un fichier externe au dépôt dans lequel se trouve le fichier de configuration `.gitlab/secret-detection-ruleset.toml`.

Cela peut être réalisé en utilisant les passthroughs `git` ou `url` comme indiqué précédemment.

Pour ce faire avec un passthrough `git`, ajoutez ce qui suit dans le fichier de configuration `.gitlab/secret-detection-ruleset.toml` stocké dans le même dépôt, et ajustez les valeurs `value`, `ref` et `subdir` selon vos besoins pour pointer vers le chemin du fichier de configuration étendu :

```toml
# .gitlab/secret-detection-ruleset.toml in https://gitlab.com/user_group/basic_repository
[secrets]
  [[secrets.passthrough]]
    type   = "git"
    ref    = "main"
    subdir = "config"
    value  = "https://gitlab.com/user_group/central_repository_with_shared_ruleset"
```

La détection des secrets dans les pipelines suppose que le fichier de configuration d'ensemble de règles distant est nommé `gitleaks.toml` et est stocké dans le répertoire `config` sur la branche `main` du dépôt référencé.

Pour étendre l'ensemble de règles par défaut, le fichier `gitleaks.toml` doit utiliser la directive `[extend]` comme dans l'exemple précédent :

```toml
# https://gitlab.com/user_group/central_repository_with_shared_ruleset/-/raw/main/config/gitleaks.toml
[extend]
# Extends default packaged ruleset, NOTE: do not change the path.
path = "/gitleaks.toml"

[[rules]]
  id = "example_api_key"
  description = "Example Service API Key"
  regex = '''example_api_key'''

[[rules]]
  id = "example_api_secret"
  description = "Example Service API Secret"
  regex = '''example_api_secret'''
```

Pour utiliser un passthrough `url`, ajoutez ce qui suit dans le fichier de configuration `.gitlab/secret-detection-ruleset.toml` stocké dans le même dépôt, et ajustez la `value` selon vos besoins pour pointer vers le chemin du fichier de configuration étendu

```toml
# .gitlab/secret-detection-ruleset.toml in https://gitlab.com/user_group/basic_repository
[secrets]
  [[secrets.passthrough]]
    type   = "url"
    target = "gitleaks.toml"
    value  = "https://example.com/gitleaks.toml"
```

Pour plus d'informations sur la syntaxe de passthrough à utiliser, consultez [Schéma](custom_rulesets_schema.md#schema).

#### Avec une politique d'exécution de scan {#with-a-scan-execution-policy}

Pour étendre et appliquer l'ensemble de règles avec une politique d'exécution de scan :

- Suivez les étapes décrites dans [Configurer une configuration de détection des secrets dans les pipelines avec une politique d'exécution de scan](https://support.gitlab.com/hc/en-us/articles/18863735262364-How-to-set-up-a-centrally-managed-pipeline-secret-detection-configuration-applied-via-Scan-Execution-Policy).

### Ignorer des modèles et des chemins {#ignore-patterns-and-paths}

Il peut arriver que vous ayez besoin d'ignorer un certain modèle ou chemin pour qu'il ne soit pas détecté par la détection des secrets dans les pipelines. Par exemple, vous pouvez avoir un fichier contenant de faux secrets destinés à être utilisés dans une suite de tests.

Dans ce cas, vous pouvez utiliser la directive [native `[allowlist]` de Gitleaks](https://github.com/gitleaks/gitleaks#configuration) pour ignorer des modèles ou des chemins spécifiques.

> [!note]
> Cette fonctionnalité fonctionne que vous utilisiez un fichier de configuration d'ensemble de règles local ou distant. Les exemples ci-dessous utilisent néanmoins un ensemble de règles local avec le passthrough `file`.

Pour ignorer un modèle, ajoutez ce qui suit dans le fichier de configuration `.gitlab/secret-detection-ruleset.toml` stocké dans le même dépôt, et ajustez la `value` selon vos besoins pour pointer vers le chemin du fichier de configuration étendu :

```toml
# .gitlab/secret-detection-ruleset.toml
[secrets]
  [[secrets.passthrough]]
    type   = "file"
    target = "gitleaks.toml"
    value  = "extended-gitleaks-config.toml"
```

La configuration étendue stockée dans `extended-gitleaks-config.toml` est incluse dans la configuration utilisée par l'analyseur.

L'exemple ci-dessous ajoute une directive `[allowlist]` qui définit une regex correspondant au secret à ignorer (« autorisé ») :

```toml
# extended-gitleaks-config.toml
[extend]
# Extends default packaged ruleset, NOTE: do not change the path.
path = "/gitleaks.toml"

[allowlist]
  description = "allowlist of patterns to ignore in detection"
  regexTarget = "match"
  regexes = [
    '''glpat-[0-9a-zA-Z_\\-]{20}'''
  ]
```

Cela ignore toute chaîne correspondant à `glpat-` avec un suffixe de 20 caractères composés de chiffres et de lettres.

De même, vous pouvez exclure des chemins spécifiques de l'analyse. L'exemple ci-dessous définit un tableau de chemins à ignorer sous la directive `[allowlist]`. Un chemin peut être une expression régulière ou un chemin de fichier spécifique :

```toml
# extended-gitleaks-config.toml
[extend]
# Extends default packaged ruleset, NOTE: do not change the path.
path = "/gitleaks.toml"

[allowlist]
  description = "allowlist of patterns to ignore in detection"
  paths = [
    '''/gitleaks.toml''',
    '''(.*?)(jpg|gif|doc|pdf|bin|svg|socket)'''
  ]
```

Cela ignore tous les secrets détectés dans le fichier `/gitleaks.toml` ou dans tout fichier se terminant par l'une des extensions spécifiées.

Depuis [Gitleaks v8.20.0](https://github.com/gitleaks/gitleaks/releases/tag/v8.20.0), vous pouvez également utiliser `regexTarget` avec `[allowlist]`. Cela signifie que vous pouvez configurer un [préfixe de jeton d'accès personnel](../../../../administration/settings/account_and_limit_settings.md#personal-access-token-prefix) ou un [préfixe d'instance personnalisé](../../../../administration/settings/account_and_limit_settings.md#instance-token-prefix) en remplaçant les règles existantes. Par exemple, pour `personal access tokens`, vous pouvez configurer :

```toml
# extended-gitleaks-config.toml
[extend]
# Extends default packaged ruleset, NOTE: do not change the path.
path = "/gitleaks.toml"

[[rules]]
# Rule id you want to override:
id = "gitlab_personal_access_token"
# all the other attributes from the default rule are inherited
    [[rules.allowlists]]
    regexTarget = "line"
    regexes = [ '''CUSTOMglpat-''' ]

[[rules]]
id = "gitlab_personal_access_token_with_custom_prefix"
regex = '<Regex that match a personal access token starting with your CUSTOM prefix>'

```

Gardez à l'esprit que vous devez prendre en compte toutes les règles configurées dans l'[ensemble de règles par défaut](https://gitlab.com/gitlab-org/security-products/secret-detection/secret-detection-rules/-/blob/main/rules/mit/gitlab/gitlab.toml).

Pour plus d'informations sur la syntaxe de passthrough à utiliser, consultez [Schéma](custom_rulesets_schema.md#schema).

### Ignorer des secrets en ligne {#ignore-secrets-inline}

Dans certains cas, vous pouvez souhaiter ignorer un secret en ligne. Par exemple, vous pouvez avoir un faux secret dans un exemple ou une suite de tests. Dans ces cas, vous devez ignorer le secret plutôt que de le faire apparaître comme une vulnérabilité.

Pour ignorer un secret, ajoutez `gitleaks:allow` en tant que commentaire sur la ligne contenant le secret.

Par exemple :

```ruby
"A personal token for GitLab will look like glpat-JUST20LETTERSANDNUMB"  # gitleaks:allow
```

### Détecter des chaînes complexes {#detecting-complex-strings}

L'[ensemble de règles par défaut](_index.md#detected-secrets) fournit des modèles pour détecter des chaînes structurées avec un faible taux de faux positifs. Cependant, vous pouvez souhaiter détecter des chaînes plus complexes, comme des mots de passe. [Gitleaks ne prend pas en charge le lookahead ou le lookbehind](https://github.com/google/re2/issues/411), il n'est donc pas possible d'écrire une règle générale à haute confiance pour détecter des chaînes non structurées.

Même si vous ne pouvez pas détecter toutes les chaînes complexes, vous pouvez étendre votre ensemble de règles pour répondre à des cas d'utilisation spécifiques.

Par exemple, cette règle modifie la [règle `generic-api-key`](https://github.com/gitleaks/gitleaks/blob/4e43d1109303568509596ef5ef576fbdc0509891/config/gitleaks.toml#L507-L514) de l'ensemble de règles par défaut de Gitleaks :

```regex
(?i)(?:pwd|passwd|password)(?:[0-9a-z\-_\t .]{0,20})(?:[\s|']|[\s|"]){0,3}(?:=|>|=:|:{1,3}=|\|\|:|<=|=>|:|\?=)(?:'|\"|\s|=|\x60){0,5}([0-9a-z\-_.=\S_]{3,50})(?:['|\"|\n|\r|\s|\x60|;]|$)
```

Cette expression régulière correspond à :

1. Un identifiant insensible à la casse qui commence par `pwd`, `passwd` ou `password`. Vous pouvez l'ajuster avec d'autres variantes comme `secret` ou `key`.
1. Un suffixe qui suit l'identifiant. Le suffixe est une combinaison de chiffres, de lettres et de symboles, et contient entre zéro et 23 caractères.
1. Les opérateurs d'affectation couramment utilisés, tels que `=`, `:=`, `:` ou `=>`.
1. Un préfixe de secret, souvent utilisé comme délimiteur pour faciliter la détection du secret.
1. Une chaîne de chiffres, de lettres et de symboles, comprise entre trois et 50 caractères. Il s'agit du secret lui-même. Si vous attendez des chaînes plus longues, vous pouvez ajuster la longueur.
1. Un suffixe de secret, souvent utilisé comme délimiteur. Cela correspond aux fins courantes comme les apostrophes, les sauts de ligne et les nouvelles lignes.

Voici des exemples de chaînes correspondant à cette expression régulière :

```plaintext
pwd = password1234
passwd = 'p@ssW0rd1234'
password = thisismyverylongpassword
password => mypassword
password := mypassword
password: password1234
"password" = "p%ssward1234"
'password': 'p@ssW0rd1234'
```

Pour utiliser cette regex, étendez votre ensemble de règles avec l'une des méthodes documentées sur cette page.

Par exemple, imaginez que vous souhaitiez étendre l'ensemble de règles par défaut [avec un ensemble de règles local](#with-a-local-ruleset-1) incluant cette règle.

Ajoutez ce qui suit dans un fichier de configuration `.gitlab/secret-detection-ruleset.toml` stocké dans le même dépôt. Ajustez la `value` pour pointer vers le chemin du fichier de configuration étendu :

```toml
# .gitlab/secret-detection-ruleset.toml
[secrets]
  [[secrets.passthrough]]
    type   = "file"
    target = "gitleaks.toml"
    value  = "extended-gitleaks-config.toml"
```

Dans le fichier `extended-gitleaks-config.toml`, ajoutez une nouvelle section `[[rules]]` avec l'expression régulière que vous souhaitez utiliser :

```toml
# extended-gitleaks-config.toml
[extend]
# Extends default packaged ruleset, NOTE: do not change the path.
path = "/gitleaks.toml"

[[rules]]
  description = "Generic Password Rule"
  id = "generic-password"
  regex = '''(?i)(?:pwd|passwd|password)(?:[0-9a-z\-_\t .]{0,20})(?:[\s|']|[\s|"]){0,3}(?:=|>|=:|:{1,3}=|\|\|:|<=|=>|:|\?=)(?:'|\"|\s|=|\x60){0,5}([0-9a-z\-_.=\S_]{3,50})(?:['|\"|\n|\r|\s|\x60|;]|$)'''
  entropy = 3.5
  keywords = ["pwd", "passwd", "password"]
```

> [!note]
> Cet exemple de configuration est fourni uniquement à titre pratique et peut ne pas fonctionner pour tous les cas d'utilisation. Si vous configurez votre ensemble de règles pour détecter des chaînes complexes, vous risquez de générer un grand nombre de faux positifs ou de ne pas capturer certains modèles.

### Démonstrations {#demonstrations}

Des [projets de démonstration](https://gitlab.com/gitlab-org/security-products/demos/analyzer-configurations/secret-detection) illustrent certaines de ces options de configuration.

Vous trouverez ci-dessous un tableau avec les projets de démonstration et leurs workflows associés :

| Action/Workflow         | S'applique à/via   | Avec un ensemble de règles en ligne ou local                                                                                                                                                                                                                                                                                                                                                                                       | Avec un ensemble de règles distant |
|-------------------------|------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|---------------------|
| Désactiver une règle          | Règles prédéfinies | [Ensemble de règles local](https://gitlab.com/gitlab-org/security-products/demos/analyzer-configurations/secret-detection/modify-default-ruleset/local-ruleset/disable-rule-project/-/blob/main/.gitlab/secret-detection-ruleset.toml?ref_type=heads) / [Projet](https://gitlab.com/gitlab-org/security-products/demos/analyzer-configurations/secret-detection/modify-default-ruleset/local-ruleset/disable-rule-project)   | [Ensemble de règles distant](https://gitlab.com/gitlab-org/security-products/demos/analyzer-configurations/secret-detection/modify-default-ruleset/remote-ruleset/disable-rule-ruleset) / [Projet](https://gitlab.com/gitlab-org/security-products/demos/analyzer-configurations/secret-detection/modify-default-ruleset/remote-ruleset/disable-rule-project) |
| Remplacer une règle         | Règles prédéfinies | [Ensemble de règles local](https://gitlab.com/gitlab-org/security-products/demos/analyzer-configurations/secret-detection/modify-default-ruleset/local-ruleset/override-rule-project/-/blob/main/.gitlab/secret-detection-ruleset.toml?ref_type=heads) / [Projet](https://gitlab.com/gitlab-org/security-products/demos/analyzer-configurations/secret-detection/modify-default-ruleset/local-ruleset/override-rule-project) | [Ensemble de règles distant](https://gitlab.com/gitlab-org/security-products/demos/analyzer-configurations/secret-detection/modify-default-ruleset/remote-ruleset/override-rule-ruleset) / [Projet](https://gitlab.com/gitlab-org/security-products/demos/analyzer-configurations/secret-detection/modify-default-ruleset/remote-ruleset/override-rule-project) |
| Remplacer l'ensemble de règles par défaut | Passthrough de fichier | [Ensemble de règles local](https://gitlab.com/gitlab-org/security-products/demos/analyzer-configurations/secret-detection/replace-default-ruleset/file-passthrough/-/blob/main/config/gitleaks.toml) / [Projet](https://gitlab.com/gitlab-org/security-products/demos/analyzer-configurations/secret-detection/replace-default-ruleset/file-passthrough)                                                                     | Sans objet      |
| Remplacer l'ensemble de règles par défaut | Passthrough brut  | [Ensemble de règles en ligne](https://gitlab.com/gitlab-org/security-products/demos/analyzer-configurations/secret-detection/replace-default-ruleset/raw-passthrough/-/blob/main/.gitlab/secret-detection-ruleset.toml?ref_type=heads) / [Projet](https://gitlab.com/gitlab-org/security-products/demos/analyzer-configurations/secret-detection/replace-default-ruleset/raw-passthrough)                                      | Sans objet      |
| Remplacer l'ensemble de règles par défaut | Passthrough Git  | Sans objet                                                                                                                                                                                                                                                                                                                                                                                                     | [Ensemble de règles distant](https://gitlab.com/gitlab-org/security-products/tests/secrets-passthrough-git-and-url-test/-/blob/config-demos-replace/config/gitleaks.toml) / [Projet](https://gitlab.com/gitlab-org/security-products/demos/analyzer-configurations/secret-detection/replace-default-ruleset/git-passthrough) |
| Remplacer l'ensemble de règles par défaut | Passthrough URL  | Sans objet                                                                                                                                                                                                                                                                                                                                                                                                     | [Ensemble de règles distant](https://gitlab.com/gitlab-org/security-products/tests/secrets-passthrough-git-and-url-test/-/blob/config-demos-replace/config/gitleaks.toml) / [Projet](https://gitlab.com/gitlab-org/security-products/demos/analyzer-configurations/secret-detection/replace-default-ruleset/url-passthrough) |
| Étendre l'ensemble de règles par défaut  | Passthrough de fichier | [Ensemble de règles local](https://gitlab.com/gitlab-org/security-products/demos/analyzer-configurations/secret-detection/extend-default-ruleset/file-passthrough/-/blob/main/config/extended-gitleaks-config.toml) / [Projet](https://gitlab.com/gitlab-org/security-products/demos/analyzer-configurations/secret-detection/extend-default-ruleset/file-passthrough)                                                       | Sans objet      |
| Étendre l'ensemble de règles par défaut  | Passthrough Git  | Sans objet                                                                                                                                                                                                                                                                                                                                                                                                     | [Ensemble de règles distant](https://gitlab.com/gitlab-org/security-products/tests/secrets-passthrough-git-and-url-test/-/blob/config-demos-extend/config/gitleaks.toml) / [Projet](https://gitlab.com/gitlab-org/security-products/demos/analyzer-configurations/secret-detection/extend-default-ruleset/git-passthrough) |
| Étendre l'ensemble de règles par défaut  | Passthrough URL  | Sans objet                                                                                                                                                                                                                                                                                                                                                                                                     | [Ensemble de règles distant](https://gitlab.com/gitlab-org/security-products/tests/secrets-passthrough-git-and-url-test/-/blob/config-demos-extend/config/gitleaks.toml) / [Projet](https://gitlab.com/gitlab-org/security-products/demos/analyzer-configurations/secret-detection/extend-default-ruleset/url-passthrough) |
| Ignorer des chemins            | Passthrough de fichier | [Ensemble de règles local](https://gitlab.com/gitlab-org/security-products/demos/analyzer-configurations/secret-detection/ignore-paths/file-passthrough/-/blob/main/config/extended-gitleaks-config.toml) / [Projet](https://gitlab.com/gitlab-org/security-products/demos/analyzer-configurations/secret-detection/ignore-paths/file-passthrough)                                                                           | Sans objet      |
| Ignorer des chemins            | Passthrough Git  | Sans objet                                                                                                                                                                                                                                                                                                                                                                                                     | [Ensemble de règles distant](https://gitlab.com/gitlab-org/security-products/tests/secrets-passthrough-git-and-url-test/-/blob/config-demos-ignore-paths/config/gitleaks.toml) / [Projet](https://gitlab.com/gitlab-org/security-products/demos/analyzer-configurations/secret-detection/ignore-paths/git-passthrough) |
| Ignorer des chemins            | Passthrough URL  | Sans objet                                                                                                                                                                                                                                                                                                                                                                                                     | [Ensemble de règles distant](https://gitlab.com/gitlab-org/security-products/tests/secrets-passthrough-git-and-url-test/-/blob/config-demos-ignore-paths/config/gitleaks.toml) / [Projet](https://gitlab.com/gitlab-org/security-products/demos/analyzer-configurations/secret-detection/ignore-paths/url-passthrough) |
| Ignorer des modèles         | Passthrough de fichier | [Ensemble de règles local](https://gitlab.com/gitlab-org/security-products/demos/analyzer-configurations/secret-detection/ignore-patterns/file-passthrough/-/blob/main/config/extended-gitleaks-config.toml) / [Projet](https://gitlab.com/gitlab-org/security-products/demos/analyzer-configurations/secret-detection/ignore-patterns/file-passthrough)                                                                     | Sans objet      |
| Ignorer des modèles         | Passthrough Git  | Sans objet                                                                                                                                                                                                                                                                                                                                                                                                     | [Ensemble de règles distant](https://gitlab.com/gitlab-org/security-products/tests/secrets-passthrough-git-and-url-test/-/blob/config-demos-ignore-patterns/config/gitleaks.toml) / [Projet](https://gitlab.com/gitlab-org/security-products/demos/analyzer-configurations/secret-detection/ignore-patterns/git-passthrough) |
| Ignorer des modèles         | Passthrough URL  | Sans objet                                                                                                                                                                                                                                                                                                                                                                                                     | [Ensemble de règles distant](https://gitlab.com/gitlab-org/security-products/tests/secrets-passthrough-git-and-url-test/-/blob/config-demos-ignore-patterns/config/gitleaks.toml) / [Projet](https://gitlab.com/gitlab-org/security-products/demos/analyzer-configurations/secret-detection/ignore-patterns/url-passthrough) |
| Ignorer des valeurs           | Passthrough de fichier | [Ensemble de règles local](https://gitlab.com/gitlab-org/security-products/demos/analyzer-configurations/secret-detection/ignore-values/file-passthrough/-/blob/main/config/extended-gitleaks-config.toml) / [Projet](https://gitlab.com/gitlab-org/security-products/demos/analyzer-configurations/secret-detection/ignore-values/file-passthrough)                                                                         | Sans objet      |
| Ignorer des valeurs           | Passthrough Git  | Sans objet                                                                                                                                                                                                                                                                                                                                                                                                     | [Ensemble de règles distant](https://gitlab.com/gitlab-org/security-products/tests/secrets-passthrough-git-and-url-test/-/blob/config-demos-ignore-values/config/gitleaks.toml) / [Projet](https://gitlab.com/gitlab-org/security-products/demos/analyzer-configurations/secret-detection/ignore-values/git-passthrough) |
| Ignorer des valeurs           | Passthrough URL  | Sans objet                                                                                                                                                                                                                                                                                                                                                                                                     | [Ensemble de règles distant](https://gitlab.com/gitlab-org/security-products/tests/secrets-passthrough-git-and-url-test/-/blob/config-demos-ignore-values/config/gitleaks.toml) / [Projet](https://gitlab.com/gitlab-org/security-products/demos/analyzer-configurations/secret-detection/ignore-values/url-passthrough) |

Des démonstrations vidéo guidant la configuration des ensembles de règles distants sont également disponibles :

- [Détection des secrets avec un ensemble de règles local et distant](https://youtu.be/rsN1iDug5GU)

## Configuration hors ligne {#offline-configuration}

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

Un environnement hors ligne dispose d'un accès limité, restreint ou intermittent aux ressources externes via Internet. Pour les instances dans un tel environnement, la détection des secrets dans les pipelines nécessite certaines modifications de configuration. Les instructions de cette section doivent être complétées en même temps que les instructions détaillées dans [les environnements hors ligne](../../offline_deployments/_index.md).

### Configurer GitLab Runner {#configure-gitlab-runner}

Par défaut, un runner tente d'extraire des images Docker du registre de conteneurs GitLab, même si une copie locale est disponible. Vous devez utiliser ce paramètre par défaut pour garantir que les images Docker restent à jour. Cependant, si aucune connectivité réseau n'est disponible, vous devez modifier la variable `pull_policy` par défaut de GitLab Runner.

Configurez la variable CI/CD `pull_policy` de GitLab Runner sur [`if-not-present`](https://docs.gitlab.com/runner/executors/docker/#using-the-if-not-present-pull-policy).

### Utiliser une image d'analyseur de détection des secrets dans les pipelines locale {#use-local-pipeline-secret-detection-analyzer-image}

Utilisez une image d'analyseur de détection des secrets dans les pipelines locale si vous souhaitez obtenir l'image depuis un registre Docker local plutôt que depuis le registre de conteneurs GitLab.

Prérequis :

- L'importation d'images Docker dans un registre Docker hors ligne local dépend de votre politique de sécurité réseau. Consultez votre équipe informatique pour trouver un processus accepté et approuvé pour importer ou accéder temporairement aux ressources externes.

1. Importez l'image d'analyseur de détection des secrets dans les pipelines par défaut depuis `registry.gitlab.com` dans votre [registre de conteneurs Docker local](../../../packages/container_registry/_index.md) :

   ```plaintext
   registry.gitlab.com/security-products/secrets:7
   ```

   L'image de l'analyseur de détection des secrets dans les pipelines est [mise à jour périodiquement](../../detect/vulnerability_scanner_maintenance.md) ; vous devez donc mettre à jour périodiquement la copie locale.

1. Définissez la variable CI/CD `SECURE_ANALYZERS_PREFIX` sur le registre de conteneurs Docker local.

   ```yaml
   include:
     - template: Jobs/Secret-Detection.gitlab-ci.yml

   variables:
     SECURE_ANALYZERS_PREFIX: "localhost:5000/analyzers"
   ```

Le job de détection des secrets dans les pipelines doit maintenant utiliser la copie locale de l'image Docker de l'analyseur, sans nécessiter d'accès à Internet.

## Utilisation d'une autorité de certification SSL personnalisée {#using-a-custom-ssl-ca-certificate-authority}

Pour faire confiance à une autorité de certification personnalisée, définissez la variable `ADDITIONAL_CA_CERT_BUNDLE` sur le bundle de certificats CA auxquels vous faites confiance. Effectuez cette opération soit dans le fichier `.gitlab-ci.yml`, soit dans une variable de fichier, soit en tant que variable CI/CD.

- Dans le fichier `.gitlab-ci.yml`, la valeur `ADDITIONAL_CA_CERT_BUNDLE` doit contenir la [représentation textuelle du certificat à clé publique X.509 PEM](https://www.rfc-editor.org/rfc/rfc7468#section-5.1).

  Par exemple :

  ```yaml
  variables:
    ADDITIONAL_CA_CERT_BUNDLE: |
        -----BEGIN CERTIFICATE-----
        MIIGqTCCBJGgAwIBAgIQI7AVxxVwg2kch4d56XNdDjANBgkqhkiG9w0BAQsFADCB
        ...
        jWgmPqF3vUbZE0EyScetPJquRFRKIesyJuBFMAs=
        -----END CERTIFICATE-----
  ```

- Si vous utilisez une variable de fichier, définissez la valeur de `ADDITIONAL_CA_CERT_BUNDLE` sur le chemin vers le certificat.

- Si vous utilisez une variable, définissez la valeur de `ADDITIONAL_CA_CERT_BUNDLE` sur la représentation textuelle du certificat.
