---
stage: Application Security Testing
group: Secret Detection
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: GitLab Secret Scanning pour le code source
---

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Statut : version bêta

{{< /details >}}

{{< history >}}

- Introduit en tant que [version expérimentale](../../../../policy/development_stages_support.md) dans GitLab 19.0.
- [Passage](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/240774) de la version expérimentale à la version bêta dans GitLab 19.3.

{{< /history >}}

GitLab Secret Scanning pour le code source est un analyseur alternatif pour la [détection des secrets dans les pipelines](../pipeline/_index.md). Il s'exécute dans le même job CI/CD `secret_detection` que l'analyseur par défaut, mais offre une détection des secrets supplémentaire, notamment la détection de secrets génériques.

## Différences entre GitLab Secret Scanning pour le code source et les autres analyseurs {#how-gitlab-secret-scanning-for-source-code-differs}

L'analyseur utilise un moteur d'analyse propriétaire développé par GitLab. Plutôt que de s'appuyer sur la correspondance de motifs, il utilise des heuristiques pour détecter les secrets et mots de passe non structurés au-delà des [règles standard de détection des secrets GitLab](../detected_secrets.md). Il combine plusieurs techniques heuristiques pour réduire les faux positifs.

En version bêta, l'analyseur offre :

- Détection de secrets génériques : identifie les secrets et mots de passe non structurés, y compris les secrets contextuels au-delà de la couverture des règles standard de détection des secrets GitLab.
- Réduction des faux positifs : combine plusieurs techniques heuristiques pour évaluer à la fois le secret et son contexte environnant afin de réduire le bruit dans les résultats d'analyse.
- Détection de secrets encodés : détecte les secrets encodés plutôt que stockés en texte brut. Prend en charge les chaînes encodées en base64.

## Activer l'analyseur {#turn-on-the-analyzer}

Prérequis :

- Disposer d'un runner Linux avec l'exécuteur [`docker`](https://docs.gitlab.com/runner/executors/docker/) ou [`kubernetes`](https://docs.gitlab.com/runner/install/kubernetes/). Si vous utilisez des runners hébergés pour GitLab.com, cette configuration est activée par défaut.
  - Les runners Windows ne sont pas pris en charge.
  - Les architectures CPU autres que amd64 ne sont pas prises en charge.
- Disposer d'un fichier `.gitlab-ci.yml` qui inclut l'étape `test`.

Pour activer l'analyseur, utilisez le dernier modèle de détection des secrets et définissez la variable CI/CD `SECRET_DETECTION_ENABLE_GSS` sur `true` :

```yaml
include:
  - template: Jobs/Secret-Detection.latest.gitlab-ci.yml

secret_detection:
  variables:
    SECRET_DETECTION_ENABLE_GSS: "true"
```

> [!note]
> L'analyseur ne signale que les résultats à haute confiance. Les résultats à confiance moyenne et faible sont intentionnellement filtrés pour minimiser le bruit dans le rapport de vulnérabilité. Si un secret attendu n'apparaît pas dans les résultats, il a probablement été signalé avec un niveau de confiance moyen ou faible. Ce comportement persistera jusqu'à ce que l'analyseur prenne en charge la configuration du niveau de confiance pour les analyses et que l'interface utilisateur du rapport de vulnérabilité prenne en charge le filtrage des résultats par niveau de confiance. Un artefact téléchargeable pour tous les résultats est proposé dans le [ticket 611174](https://gitlab.com/gitlab-org/gitlab/-/work_items/611174).

### Exécuter l'analyseur pour la première fois {#run-the-analyzer-for-the-first-time}

La première fois que vous exécutez GitLab Secret Scanning pour le code source, vous devez effectuer une analyse historique. L'analyseur analyse tous les commits et met à jour le rapport de vulnérabilité avec les résultats les plus récents, en reprenant notamment les résultats existants de la [détection des secrets dans les pipelines](../pipeline/_index.md).

Pour exécuter une analyse historique :

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à** et repérez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Compilation** > **Pipelines**.
1. Sélectionnez **Nouveau pipeline**.
1. Ajoutez une variable CI/CD :
   1. Dans la liste déroulante, sélectionnez **Variable**.
   1. Dans la zone **Nom de la variable d'entrée**, saisissez `SECRET_DETECTION_HISTORIC_SCAN`.
   1. Dans la zone **Valeur de la variable d'entrée**, saisissez `true`.
1. Sélectionnez **Nouveau pipeline**.

Si vous définissez `SECRET_DETECTION_HISTORIC_SCAN` sur `true` dans votre fichier `.gitlab-ci.yml` à la place, supprimez la variable une fois l'analyse terminée. Sinon, chaque pipeline analyse l'intégralité de l'historique du dépôt.

## Configuration par défaut {#default-configuration}

Lorsque vous activez l'analyseur, il s'exécute avec la configuration suivante :

| Paramètre | Valeur par défaut | Comment modifier |
|---------|---------|---------------|
| Détection de secrets génériques | Activée | Définissez `SECRET_DETECTION_GSS_ENABLE_GENERIC_SECRETS` sur `false`. Voir [secrets génériques](#generic-secrets). |
| Réduction des faux positifs | Activée | Non configurable. |
| Règles | L'ensemble de règles de détection des secrets GitLab par défaut | Voir [personnaliser les règles](#customize-rules). |

## Secrets génériques {#generic-secrets}

Lorsque l'analyseur est activé, la détection de secrets génériques est activée par défaut.

Pour désactiver la détection de secrets génériques, définissez la variable CI/CD `SECRET_DETECTION_GSS_ENABLE_GENERIC_SECRETS` sur `false` :

```yaml
include:
  - template: Jobs/Secret-Detection.latest.gitlab-ci.yml

secret_detection:
  variables:
    SECRET_DETECTION_ENABLE_GSS: "true"
    SECRET_DETECTION_GSS_ENABLE_GENERIC_SECRETS: "false"
```

## Personnaliser les règles {#customize-rules}

Vous pouvez appliquer des personnalisations d'analyse à GitLab Secret Scanning pour le code source à l'aide d'un fichier `.gitlab/secret-detection-ruleset.toml` dans votre dépôt. Pour créer ce fichier, voir [créer un fichier de configuration d'ensemble de règles](../pipeline/configure.md#create-a-ruleset-configuration-file).

Vous pouvez :

- [Désactiver une règle](../pipeline/configure.md#disable-a-rule) de l'ensemble de règles par défaut.
- [Étendre l'ensemble de règles par défaut](../pipeline/configure.md#extend-the-default-ruleset) avec vos propres règles. Les nouvelles règles doivent suivre le [format de règle personnalisée](../pipeline/custom_rulesets_schema.md#custom-rule-format).
- Ignorer les secrets par expression régulière ou chemin de fichier avec des listes d'autorisation.

Par exemple, pour étendre l'ensemble de règles par défaut et ignorer les secrets par expression régulière ou chemin de fichier, utilisez un passthrough `file` qui pointe vers un fichier de configuration étendu. Ajoutez le passthrough au fichier `.gitlab/secret-detection-ruleset.toml` :

```toml
# .gitlab/secret-detection-ruleset.toml
[secrets]
  [[secrets.passthrough]]
    type   = "file"
    target = "gss.toml"
    value  = "extended-gss-config.toml"
```

Dans le fichier de configuration étendu, utilisez `[extend]` pour vous appuyer sur l'ensemble de règles par défaut, et une ou plusieurs tables `[[allowlists]]` pour ignorer les résultats. Chaque liste d'autorisation peut faire correspondre des valeurs de secret avec `regexes` et des chemins de fichier avec `paths` :

```toml
# extended-gss-config.toml
[extend]
# Extends the default packaged ruleset. Do not change the path.
path = "/gitleaks.toml"

[[allowlists]]
  description = "Ignore known test values and fixture paths"
  regexes = [
    '''glpat-[0-9a-zA-Z_\-]{20}''',
  ]
  paths = [
    '''spec/fixtures/.*''',
  ]
```

Les éléments `regexes` et `paths` d'une liste d'autorisation sont combinés avec un OU logique. Un résultat est ignoré si son secret correspond à l'un des éléments `regexes`, ou si son chemin de fichier correspond à l'un des éléments `paths`.

## Migrer depuis l'analyseur par défaut {#migrate-from-the-default-analyzer}

GitLab Secret Scanning pour le code source remplace l'analyseur par défaut dans le job `secret_detection`. Lorsque la variable CI/CD `SECRET_DETECTION_ENABLE_GSS` est définie sur `true`, seul GitLab Secret Scanning pour le code source s'exécute.

Pour migrer depuis l'analyseur par défaut :

1. [Activer GitLab Secret Scanning pour le code source](#turn-on-the-analyzer) sur une branche de fonctionnalité.
1. Exécutez un pipeline et comparez les résultats avec une analyse utilisant l'analyseur par défaut.
1. Vérifiez vos personnalisations d'ensemble de règles. Pour les options disponibles, voir [personnaliser les règles](#customize-rules).
1. Lorsque vous êtes satisfait des résultats, activez l'analyseur sur votre branche par défaut.

### Résultats existants après la migration {#existing-findings-after-migration}

Lorsque vous activez GitLab Secret Scanning pour le code source sur votre branche par défaut, les secrets détectés par les deux analyseurs sont repris par l'analyseur. Il fait correspondre ces résultats aux vulnérabilités précédemment signalées par l'analyseur par défaut. Leurs enregistrements de vulnérabilité existants sont conservés au lieu d'être à nouveau signalés comme de nouveaux résultats.

Les résultats précédemment signalés par l'analyseur par défaut mais non détectés par GitLab Secret Scanning pour le code source restent inchangés.

## Images compatibles FIPS {#fips-enabled-images}

Tant que GitLab Secret Scanning pour le code source est en version bêta, aucune image compatible FIPS n'est publiée pour celui-ci. Si vous définissez la variable CI/CD `SECRET_DETECTION_IMAGE_SUFFIX` sur `-fips`, le job `secret_detection` échoue car il ne peut pas extraire l'image.

Pour analyser avec une image compatible FIPS, utilisez l'analyseur par défaut pour la [détection des secrets dans les pipelines](../pipeline/_index.md#fips-enabled-images).

## Sujets connexes {#related-topics}

- [Personnaliser la détection des secrets dans les pipelines](../pipeline/configure.md)
