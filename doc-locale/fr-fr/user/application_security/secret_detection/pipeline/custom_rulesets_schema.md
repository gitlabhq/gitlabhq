---
stage: Application Security Testing
group: Secret Detection
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Schéma des ensembles de règles personnalisés
---

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Vous pouvez utiliser [différents types de personnalisations d'ensembles de règles](configure.md#customize-analyzer-rulesets) pour personnaliser le comportement de la détection des secrets dans les pipelines.

## Schéma {#schema}

La personnalisation des ensembles de règles de détection des secrets dans les pipelines doit respecter un schéma strict. Les sections suivantes décrivent chacune des options disponibles ainsi que le schéma qui s'applique à cette section.

### La section de niveau supérieur {#the-top-level-section}

La section de niveau supérieur contient une ou plusieurs sections de configuration, définies sous forme de [tables TOML](https://toml.io/en/v1.0.0#table).

| Paramètre     | Description                                        |
|-------------|----------------------------------------------------|
| `[secrets]` | Déclare une section de configuration pour l'analyseur. |

Exemple de configuration :

```toml
[secrets]
...
```

### La section de configuration `[secrets]` {#the-secrets-configuration-section}

La section `[secrets]` vous permet de personnaliser le comportement de l'analyseur. Les propriétés valides diffèrent selon le type de configuration que vous effectuez.

| Paramètre               | S'applique à       | Description                                                                                                                                                                                                                                                                              |
|-----------------------|------------------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `[[secrets.ruleset]]` | Règles prédéfinies | Définit des modifications apportées à une règle existante.                                                                                                                                                                                                                                               |
| `interpolate`         | Tous              | Si défini sur `true`, vous pouvez utiliser `$VAR` dans la configuration pour évaluer des variables d'environnement. Utilisez cette fonctionnalité avec précaution afin de ne pas divulguer de secrets ou de jetons. (Valeur par défaut : `false`)                                                                                                      |
| `description`         | Passthroughs     | Description de l'ensemble de règles personnalisé.                                                                                                                                                                                                                                                       |
| `targetdir`           | Passthroughs     | Le répertoire dans lequel la configuration finale doit être persistée. Si vide, un répertoire avec un nom aléatoire est créé. Le répertoire peut contenir jusqu'à 100 Mo de fichiers.                                                                                                                   |
| `validate`            | Passthroughs     | Si défini sur `true`, le contenu de chaque passthrough est validé. La validation fonctionne pour les contenus `yaml`, `xml`, `json` et `toml`. Le validateur approprié est identifié en fonction de l'extension utilisée dans le paramètre `target` de la section `[[secrets.passthrough]]`. (Valeur par défaut : `false`) |
| `timeout`             | Passthroughs     | Le temps maximum à consacrer à l'évaluation de la chaîne de passthroughs avant l'expiration du délai. Le délai d'expiration ne peut pas dépasser 300 secondes. (Valeur par défaut : 60)                                                                                                                                                     |

#### `interpolate` {#interpolate}

> [!warning]
> Pour réduire le risque de divulgation de secrets, utilisez cette fonctionnalité avec précaution.

L'exemple ci-dessous montre une configuration qui utilise la variable d'environnement `$GITURL` pour accéder à un dépôt privé. La variable contient un nom d'utilisateur et un jeton (par exemple `https://user:token@url`), de sorte qu'ils ne sont pas explicitement stockés dans le fichier de configuration.

```toml
[secrets]
  description = "My private remote ruleset"
  interpolate = true

  [[secrets.passthrough]]
    type  = "git"
    value = "$GITURL"
    ref = "main"
```

### La section `[[secrets.ruleset]]` {#the-secretsruleset-section}

La section `[[secrets.ruleset]]` cible et modifie une seule règle prédéfinie. Vous pouvez définir une ou plusieurs de ces sections pour l'analyseur.

| Paramètre                        | Description                                             |
|--------------------------------|---------------------------------------------------------|
| `disable`                      | Indique si la règle doit être désactivée. (Valeur par défaut : `false`) |
| `[secrets.ruleset.identifier]` | Sélectionne la règle prédéfinie à modifier.             |
| `[secrets.ruleset.override]`   | Définit les substitutions pour la règle.                     |

Exemple de configuration :

```toml
[secrets]
  [[secrets.ruleset]]
    disable = true
    ...
```

### La section `[secrets.ruleset.identifier]` {#the-secretsrulesetidentifier-section}

La section `[secrets.ruleset.identifier]` définit les identifiants de la règle prédéfinie que vous souhaitez modifier.

| Paramètre | Description |
| --------| ----------- |
| `type`  | Le type d'identifiant utilisé par la règle prédéfinie. |
| `value` | La valeur de l'identifiant utilisé par la règle prédéfinie. |

Pour déterminer les valeurs correctes de `type` et `value`, consultez le [`gl-secret-detection-report.json`](_index.md#secret-detection-results) produit par l'analyseur. Vous pouvez télécharger ce fichier en tant qu'artefact de job depuis le job CI/CD de l'analyseur.

Par exemple, l'extrait ci-dessous montre un résultat issu d'une règle `gitlab_personal_access_token` avec un identifiant. Les clés `type` et `value` dans l'objet JSON correspondent aux valeurs que vous devez indiquer dans cette section.

```json
...
  "vulnerabilities": [
    {
      "id": "fccb407005c0fb58ad6cfcae01bea86093953ed1ae9f9623ecc3e4117675c91a",
      "category": "secret_detection",
      "name": "GitLab personal access token",
      "description": "GitLab personal access token has been found in commit 5c124166",
      ...
      "identifiers": [
        {
          "type": "gitleaks_rule_id",
          "name": "Gitleaks rule ID gitlab_personal_access_token",
          "value": "gitlab_personal_access_token"
        }
      ]
    }
    ...
  ]
...
```

Exemple de configuration :

```toml
[secrets]
  [[secrets.ruleset]]
    [secrets.ruleset.identifier]
      type = "gitleaks_rule_id"
      value = "gitlab_personal_access_token"
    ...
```

### La section `[secrets.ruleset.override]` {#the-secretsrulesetoverride-section}

La section `[secrets.ruleset.override]` vous permet de substituer des attributs d'une règle prédéfinie.

| Paramètre       | Description                                                                                         |
|---------------|-----------------------------------------------------------------------------------------------------|
| `description` | Une description détaillée du ticket.                                                                |
| `message`     | (Obsolète) Une description du ticket.                                                            |
| `name`        | Le nom de la règle.                                                                               |
| `severity`    | La gravité de la règle. Les options valides sont : `Critical`, `High`, `Medium`, `Low`, `Unknown`, `Info` |

> [!note]
> Bien que `message` soit encore renseigné par les analyseurs, il a été [déprécié](https://gitlab.com/gitlab-org/security-products/analyzers/report/-/blob/1d86d5f2e61dc38c775fb0490ee27a45eee4b8b3/vulnerability.go#L22) et remplacé par `name` et `description`.

Exemple de configuration :

```toml
[secrets]
  [[secrets.ruleset]]
    [secrets.ruleset.override]
      severity = "Medium"
      name = "systemd machine-id"
    ...
```

### Format de règle personnalisée {#custom-rule-format}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/511321) dans GitLab 17.9.

{{< /history >}}

Lors de la création de règles personnalisées, vous pouvez utiliser à la fois [le format de règle standard de Gitleaks](https://github.com/gitleaks/gitleaks?tab=readme-ov-file#configuration) et des champs spécifiques à GitLab. Les paramètres suivants sont disponibles pour chaque règle :

| Paramètre | Obligatoire | Description |
|---------|-------------|-------------|
| `title` | Non | Un champ spécifique à GitLab qui définit un titre personnalisé pour la règle. |
| `description` | Oui | Une description détaillée de ce que la règle détecte. |
| `remediation` | Non | Un champ spécifique à GitLab qui fournit des conseils de remédiation lorsque la règle est déclenchée. |
| `regex` | Oui | Le modèle d'expression régulière utilisé pour détecter les secrets. |
| `keywords` | Non | Une liste de mots-clés pour pré-filtrer le contenu avant d'appliquer l'expression régulière. |
| `id` | Oui |  Un identifiant unique pour la règle. |

Exemple de règle personnalisée avec tous les champs disponibles :

```toml
[[rules]]
  title = "API Key Detection Rule"
  description = "Detects potential API keys in the codebase"
  remediation = "Rotate the exposed API key and store it in a secure credential manager"
  id = "custom_api_key"
  keywords = ["apikey", "api_key"]
  regex = '''api[_-]key[_-][a-zA-Z0-9]{16,}'''
```

Lorsque vous créez une règle personnalisée qui partage le même identifiant qu'une règle dans l'ensemble de règles étendu, votre règle personnalisée est prioritaire. Toutes les propriétés de votre règle personnalisée remplacent les valeurs correspondantes de la règle étendue.

Exemple d'extension des règles par défaut avec une règle personnalisée :

```toml
title = "Extension of GitLab's default Gitleaks config"

[extend]
  path = "/gitleaks.toml"

[[rules]]
  title = "Custom API Key Rule"
  description = "Detects custom API key format"
  remediation = "Rotate the exposed API key"
  id = "custom_api_123"
  keywords = ["testing"]
  regex = '''testing-key-[1-9]{3}'''
```

### La section `[[secrets.passthrough]]` {#the-secretspassthrough-section}

La section `[[secrets.passthrough]]` vous permet de synthétiser une configuration personnalisée pour un analyseur.

Vous pouvez définir jusqu'à 20 de ces sections par analyseur. Les passthroughs sont ensuite composés en une chaîne de passthroughs qui est évaluée en une configuration complète pouvant être utilisée pour remplacer ou étendre les règles prédéfinies de l'analyseur.

Les passthroughs sont évalués dans l'ordre. Les passthroughs répertoriés plus loin dans la chaîne ont une priorité plus élevée et peuvent écraser ou ajouter des données générées par les passthroughs précédents (selon le `mode`). Utilisez les passthroughs lorsque vous devez utiliser ou modifier une configuration existante.

La taille de la configuration générée par un seul passthrough est limitée à 10 Mo.

| Paramètre     | S'applique à     | Description                                                                                                                                                                   |
|-------------|----------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `type`      | Tous            | L'un des types suivants : `file`, `raw`, `git` ou `url`.                                                                                                                                        |
| `target`    | Tous            | Le fichier cible destiné à contenir les données écrites lors de l'évaluation du passthrough. Si vide, un nom de fichier aléatoire est utilisé.                                                               |
| `mode`      | Tous            | Si `overwrite`, le fichier `target` est écrasé. Si `append`, le nouveau contenu est ajouté au fichier `target`. Le type `git` prend uniquement en charge `overwrite`. (Valeur par défaut : `overwrite`) |
| `ref`       | `type = "git"` | Contient le nom de la branche, du tag ou le SHA à récupérer.                                                                                                                     |
| `subdir`    | `type = "git"` | Utilisé pour sélectionner un sous-répertoire du dépôt Git comme source de configuration.                                                                                              |
| `auth`      | `type = "git"` | Utilisé pour fournir les identifiants à utiliser lors de l'utilisation d'une [configuration stockée dans un dépôt Git privé](configure.md#with-a-private-remote-ruleset).                       |
| `value`     | Tous            | Pour les types `file`, `url` et `git`, définit l'emplacement du fichier ou du dépôt Git. Pour le type `raw`, contient la configuration inline.                            |
| `validator` | Tous            | Utilisé pour invoquer explicitement des validateurs (`xml`, `yaml`, `json`, `toml`) sur le fichier cible après l'évaluation d'un passthrough.                                                |

#### Types de passthrough {#passthrough-types}

| Type   | Description                                           |
|--------|-------------------------------------------------------|
| `file` | Utiliser un fichier stocké dans le même dépôt Git. |
| `raw`  | Fournir la configuration de l'ensemble de règles en ligne.             |
| `git`  | Extraire la configuration depuis un dépôt Git distant.  |
| `url`  | Récupérer la configuration via HTTP.                   |
