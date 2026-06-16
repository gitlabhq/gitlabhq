---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: "Limites de l'application GitLab"
description: Configurez des limites sur une instance.
---

{{< details >}}

- Niveau :  Free, Premium, Ultimate
- Offre :  GitLab Self-Managed

{{< /details >}}

GitLab, comme la plupart des grandes applications, applique des limites à certaines fonctionnalités afin de maintenir un niveau minimum de qualité des performances. Permettre à certaines fonctionnalités d'être illimitées pourrait affecter la sécurité, les performances, les données, ou même épuiser les ressources allouées à l'application.

## Configuration de l'instance {#instance-configuration}

Sur la page de configuration de l'instance, vous pouvez trouver des informations sur certains des paramètres utilisés dans votre instance GitLab actuelle.

Selon les limites que vous avez configurées, vous pouvez voir :

- Informations sur les clés hôtes SSH
- Limites CI/CD
- Limites GitLab Pages
- Limites du registre de paquets
- Limites de débit
- Limites de taille

Cette page étant visible par tout le monde, les utilisateurs non authentifiés ne voient que les informations qui les concernent.

Pour visiter la page de configuration de l'instance :

1. Dans la barre latérale gauche, sélectionnez **Aide** ({{< icon name="question-o" >}}) > **Aide**.
1. Sur la page d'aide, sélectionnez **Check the current instance configuration**.

L'URL directe est `<gitlab_url>/help/instance_configuration`. Pour GitLab.com, vous pouvez visiter <https://gitlab.com/help/instance_configuration>.

## Limites de débit {#rate-limits}

Les limites de débit peuvent être utilisées pour améliorer la sécurité et la durabilité de GitLab.

En savoir plus sur la [configuration des limites de débit](../security/rate_limits.md).

### Création de ticket {#issue-creation}

Ce paramètre limite le taux de requêtes vers le point de terminaison de création de ticket.

En savoir plus sur les [limites de débit pour la création de tickets](settings/rate_limit_on_issues_creation.md).

- **Default rate limit** :  Désactivé par défaut.

### Par utilisateur ou IP {#by-user-or-ip}

Ce paramètre limite le taux de requêtes par utilisateur ou IP.

En savoir plus sur les [limites de débit par utilisateur et par IP](settings/user_and_ip_rate_limits.md).

- **Default rate limit** :  Désactivé par défaut.

### Par point de terminaison brut {#by-raw-endpoint}

Ces paramètres limitent le taux de requêtes sur les points de terminaison bruts.

En savoir plus sur les [limites de débit des points de terminaison bruts](settings/rate_limits_on_raw_endpoints.md).

- **Default rate limit (authenticated and unauthenticated)** :  300 requêtes par minute, par projet et chemin de fichier.
- **Default rate limit (unauthenticated)** :  800 requêtes par minute, par projet pour tous les chemins de fichiers.

### Par chemin protégé {#by-protected-path}

Ce paramètre limite le taux de requêtes sur des chemins spécifiques.

GitLab limite par défaut le débit des chemins suivants pour les requêtes POST :

```plaintext
'/users/password',
'/users/sign_in',
'/api/#{API::API.version}/session.json',
'/api/#{API::API.version}/session',
'/users',
'/users/confirmation',
'/unsubscribes/',
'/import/github/personal_access_token',
'/admin/session'
```

GitLab limite par défaut le débit des chemins suivants pour les requêtes GET :

```plaintext
'/users/sign_in_path'
```

En savoir plus sur les [limites de débit des chemins protégés](settings/protected_paths.md).

- **Default rate limit** :  Après 10 requêtes, le client doit attendre 60 secondes avant de réessayer.

### Registre de paquets {#package-registry}

Ce paramètre limite le taux de requêtes sur l'API Packages par utilisateur ou IP. Pour plus d'informations, consultez les [limites de débit du registre de paquets](settings/package_registry_rate_limits.md).

- **Default rate limit** :  Désactivé par défaut.

### Git LFS {#git-lfs}

Ce paramètre limite le taux de requêtes sur les requêtes [Git LFS](../topics/git/lfs/_index.md) par utilisateur. Pour plus d'informations, consultez [Administration de GitLab Git Large File Storage (LFS)](lfs/_index.md).

- **Default rate limit** :  Désactivé par défaut.

### API Files {#files-api}

Ce paramètre limite le taux de requêtes sur l'API Files par utilisateur ou adresse IP. Pour plus d'informations, consultez les [limites de débit de l'API Files](settings/files_api_rate_limits.md).

- **Default rate limit** :  Désactivé par défaut.

### Points de terminaison d'API obsolètes {#deprecated-api-endpoints}

Ce paramètre limite le taux de requêtes sur les points de terminaison d'API obsolètes par utilisateur ou adresse IP. Pour plus d'informations, consultez les [limites de débit des API obsolètes](settings/deprecated_api_rate_limits.md).

- **Default rate limit** :  Désactivé par défaut.

### Import et export {#import-and-export}

Ces paramètres limitent les imports et exports de fichiers pour les groupes et les projets.

| Limite                   | Par défaut (par minute par utilisateur) |
|:------------------------|:------------------------------|
| Import de projet          | 6 requêtes d'import             |
| Export de projet          | 6 requêtes d'export             |
| Téléchargement d'export de projet | 1 requête de téléchargement           |
| Import de groupe            | 6 requêtes d'import             |
| Export de groupe            | 6 requêtes d'export             |
| Téléchargement d'export de groupe   | 1 requête de téléchargement           |

Ces paramètres [peuvent être configurés](settings/import_export_rate_limits.md).

#### Migration par transfert direct {#direct-transfer-migration}

{{< history >}}

- La limite du nombre maximum de migrations autorisées a été [introduite](https://gitlab.com/gitlab-org/gitlab/-/issues/386452) dans GitLab 15.9.
- Les paramètres configurables ont été [introduits](https://gitlab.com/gitlab-org/gitlab/-/issues/384976) dans GitLab 16.3.
- La limite de temps de huit heures sur les migrations a été [supprimée](https://gitlab.com/gitlab-org/gitlab/-/issues/429867) dans GitLab 16.7.

{{< /history >}}

Les limites suivantes s'appliquent à la migration par transfert direct.

| Limite                                                                      | Valeur par défaut     | Configurable |
|:---------------------------------------------------------------------------|:------------|:-------------|
| Nombre de migrations par une instance GitLab de destination par minute et par utilisateur. | 6           | {{< no >}}   |
| Temps d'attente pour la décompression d'un fichier archive.                            | 210 secondes | {{< no >}}   |
| Longueur d'une ligne NDJSON.                                                   | 50 Mo       | {{< no >}}   |
| Délai avant qu'un statut d'export vide sur l'instance source soit signalé.            | 5 minutes   | {{< no >}}   |
| Taille de la relation pouvant être téléchargée depuis l'instance source.             | 5 Gio       | {{< yes >}}  |
| Taille d'une archive décompressée.                                            | 10 Gio      | {{< yes >}}  |

Pour plus d'informations sur la modification des limites configurables, consultez les [paramètres d'import et d'export](settings/import_and_export_settings.md).

### Invitations de membres {#member-invitations}

Limitez le nombre maximum d'invitations de membres quotidiennes autorisées par hiérarchie de groupe.

- GitLab.com :  Les membres Free peuvent inviter 20 membres par jour, les membres de la période d'essai Premium et Ultimate peuvent inviter 50 membres par jour.
- GitLab Self-Managed :  Les invitations ne sont pas limitées.

### Limite de débit des webhooks {#webhook-rate-limit}

Limitez le nombre de fois par minute que les webhooks d'un espace de nommage de premier niveau peuvent être appelés. Tous les webhooks de projet et de groupe dans l'espace de nommage partagent cette limite.

Les appels qui dépassent la limite de débit sont enregistrés dans `auth.log`.

Pour définir cette limite pour une instance GitLab Self-Managed, utilisez l'[API Plan Limits](../api/plan_limits.md) ou exécutez ce qui suit dans la [console Rails GitLab](operations/rails_console.md#starting-a-rails-console-session) :

```ruby
# If limits don't exist for the default plan, you can create one with:
# Plan.default.create_limits!

Plan.default.actual_limits.update!(web_hook_calls: 10)
```

Définissez la limite à `0` pour la désactiver.

- **Default rate limit** :  Désactivée (illimitée).

### Limite de débit de recherche {#search-rate-limit}

{{< history >}}

- [Modifié](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/104208) dans GitLab 15.9 pour inclure les recherches de tickets, merge requests et epics dans la limite de débit.
- [Modifié](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/118525) dans GitLab 16.0 pour appliquer des limites de débit aux [portées de recherche](../user/search/_index.md#disable-global-search-scopes) pour les requêtes authentifiées.

{{< /history >}}

Ce paramètre limite les requêtes de recherche comme suit :

| Limite                | Par défaut (requêtes par minute) |
|----------------------|-------------------------------|
| Utilisateur authentifié   | 30                            |
| Utilisateur non authentifié | 10                            |

Les requêtes de recherche qui dépassent la limite de débit de recherche par minute renvoient l'erreur suivante :

```plaintext
This endpoint has been requested too many times. Try again later.
```

### Limite de débit de la saisie semi-automatique des utilisateurs {#autocomplete-users-rate-limit}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/368926) dans GitLab 17.10 [avec un flag](feature_flags/_index.md) nommé `autocomplete_users_rate_limit`. Désactivé par défaut.
- [Disponible de manière générale](https://gitlab.com/gitlab-org/gitlab/-/issues/523595) dans GitLab 18.1. Le feature flag `autocomplete_users_rate_limit` a été supprimé.

{{< /history >}}

Ce paramètre limite les requêtes de saisie semi-automatique des utilisateurs comme suit :

| Limite                | Par défaut (requêtes par minute) |
|----------------------|-------------------------------|
| Utilisateur authentifié   | 300                           |
| Utilisateur non authentifié | 100                           |

Les requêtes de saisie semi-automatique qui dépassent la limite de débit de saisie semi-automatique par minute renvoient l'erreur suivante :

```plaintext
This endpoint has been requested too many times. Try again later.
```

### Limite de débit de création de pipeline {#pipeline-creation-rate-limit}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/362475) dans GitLab 15.0.

{{< /history >}}

Ce paramètre limite le taux de requêtes vers les points de terminaison de création de pipeline.

En savoir plus sur les [limites de débit de création de pipeline](settings/rate_limit_on_pipelines_creation.md).

## Limite de simultanéité Gitaly {#gitaly-concurrency-limit}

Le trafic de clonage peut exercer une forte pression sur votre service Gitaly. Pour éviter que ces charges de travail ne submergent votre serveur Gitaly, vous pouvez définir des limites de simultanéité dans le fichier de configuration Gitaly.

En savoir plus sur les [limites de simultanéité de Gitaly](gitaly/concurrency_limiting.md#limit-rpc-concurrency).

- **Default rate limit** :  Désactivée.

## Nombre de commentaires par ticket, merge request ou commit {#number-of-comments-per-issue-merge-request-or-commit}

Il existe une limite au nombre de commentaires pouvant être soumis sur un ticket, une merge request ou un commit. Lorsque la limite est atteinte, des notes système peuvent toujours être ajoutées afin que l'historique des événements ne soit pas perdu, mais le commentaire soumis par l'utilisateur échoue.

- **Max limit** :  5 000 commentaires.

## Taille des commentaires et descriptions des tickets, merge requests et epics {#size-of-comments-and-descriptions-of-issues-merge-requests-and-epics}

Il existe une limite à la taille des commentaires et des descriptions des tickets, des merge requests et des epics. Toute tentative d'ajouter un corps de texte plus grand que la limite entraîne une erreur, et l'élément n'est pas non plus créé.

Il est possible que cette limite soit réduite à l'avenir.

- **Max size** : ~1 million de caractères / ~1 Mo.

## Taille des titres et descriptions des commits {#size-of-commit-titles-and-descriptions}

Des commits avec des messages de taille arbitrairement grande peuvent être poussés vers GitLab, mais les limites d'affichage suivantes s'appliquent :

- **Titre** \- La première ligne du message de commit. Limité à 1 Kio.
- **Description** \- Le reste du message de commit. Limitée à 1 Mio.

Lorsqu'un commit est poussé, GitLab traite le titre et la description pour remplacer les références aux tickets (`#123`) et aux merge requests (`!123`) par des liens vers les tickets et les merge requests.

Lorsqu'une branche comportant un grand nombre de commits est poussée, seuls les 100 derniers commits sont traités.

### Taille lors des opérations de rebase {#size-during-rebase-operations}

Lorsque vous rebasez des commits, les messages de commit qui dépassent la limite de taille sont tronqués. Cette limite est distincte des limites de taille pour les titres et descriptions de commits.

- **Limite** :  10 240 octets (10 Ko).

## Nombre de tickets dans la vue d'ensemble du jalon {#number-of-issues-in-the-milestone-overview}

Le nombre maximum de tickets chargés sur la page de vue d'ensemble du jalon est de 500. Lorsque le nombre dépasse la limite, la page affiche une alerte et renvoie vers une [liste de tickets](../user/project/issues/managing_issues.md) paginée de tous les tickets du jalon.

- **Limite** :  500 tickets.

## Nombre de pipelines par push Git {#number-of-pipelines-per-git-push}

Lors du push de plusieurs modifications avec un seul push Git, comme plusieurs tags ou branches, seuls quatre pipelines de tag ou de branche peuvent être déclenchés par défaut. Cette limite empêche la création accidentelle d'un grand nombre de pipelines lors de l'utilisation de `git push --all` ou de `git push --mirror`.

Les [pipelines de merge request](../ci/pipelines/merge_request_pipelines.md) sont limités. Si le push Git met à jour plusieurs merge requests en même temps, un pipeline de merge request peut se déclencher pour chaque merge request mise à jour avant d'atteindre la limite.

La valeur par défaut est `4` pour GitLab Self-Managed et GitLab.com.

Pour modifier cette limite sur votre instance GitLab Self-Managed, utilisez la [zone Admin](settings/continuous_integration.md#pipeline-limit-per-git-push).

> [!warning]
> Il n'est pas recommandé d'augmenter cette limite. Cela peut entraîner une charge excessive sur votre instance GitLab si de nombreuses modifications sont poussées simultanément, créant potentiellement un afflux de pipelines.

## Conservation de l'historique d'activité {#retention-of-activity-history}

L'historique d'activité des projets et des profils individuels est limité à trois ans.

## Nombre de métriques intégrées {#number-of-embedded-metrics}

Il existe une limite lors de l'intégration de métriques dans GitLab Flavored Markdown (GLFM) pour des raisons de performances.

- **Max limit** :  100 intégrations.

## Limites des réponses HTTP {#http-response-limits}

### Taille maximale compressée par Gzip {#maximum-gzip-compressed-size}

{{< history >}}

- Introduit dans GitLab 17.10.

{{< /history >}}

Ce paramètre restreint la taille maximale autorisée en Mio pour les réponses HTTP compressées par Gzip après décompression.

La taille maximale par défaut est de 100 Mio. Pour désactiver cette limite, définissez la valeur sur 0.

Vous pouvez modifier cette limite en utilisant la console Rails GitLab ou l'[API des paramètres d'application](../api/settings.md)

 ```ruby
 ApplicationSetting.update(max_http_decompressed_size: 50)
 ```

### Taille maximale des réponses HTTP provenant de requêtes sortantes {#maximum-http-responses-size-from-outbound-requests}

{{< history >}}

- Introduit dans GitLab 17.10.

{{< /history >}}

Ce paramètre restreint la taille maximale autorisée en Mio pour les réponses HTTP décompressées. Il s'applique aux intégrations, aux importateurs et aux webhooks.

La taille maximale par défaut est de 100 Mio. Pour désactiver cette limite, définissez la valeur sur 0.

Vous pouvez modifier cette limite en utilisant la console Rails GitLab ou l'[API des paramètres d'application](../api/settings.md)

 ```ruby
 ApplicationSetting.update(max_http_response_size_limit: 60)
 ```

### Nombre maximum d'objets autorisé dans les réponses HTTP JSON provenant de requêtes sortantes {#maximum-allowed-object-count-in-json-http-responses-from-outbound-requests}

{{< history >}}

- Introduit dans GitLab 18.4.

{{< /history >}}

Ce paramètre restreint le nombre maximum d'objets autorisé dans les réponses HTTP JSON provenant de requêtes sortantes. Le nombre d'objets est estimé en fonction du nombre d'occurrences de `:`, `,`, `{` et `[` dans la réponse.

Le nombre maximum par défaut est de 1 000 000 objets. Pour désactiver cette limite, définissez la valeur sur 0.

Vous pouvez modifier cette limite en utilisant la console Rails GitLab ou l'[API des paramètres d'application](../api/settings.md) :

```ruby
ApplicationSetting.update(max_http_response_json_structural_chars: 500000)
```

### Profondeur d'imbrication maximale autorisée dans les réponses HTTP JSON provenant de requêtes sortantes {#maximum-allowed-nesting-depth-in-json-http-responses-from-outbound-requests}

{{< history >}}

- Introduit dans GitLab 18.4.

{{< /history >}}

Ce paramètre restreint la profondeur d'imbrication maximale autorisée dans les réponses HTTP JSON provenant de requêtes sortantes.

La profondeur d'imbrication maximale par défaut est de 32.

Vous pouvez modifier cette limite en utilisant la console Rails GitLab ou l'[API des paramètres d'application](../api/settings.md) :

```ruby
ApplicationSetting.update(max_http_response_json_depth: 100)
```

### Nombre maximum d'objets autorisé dans les réponses HTTP XML provenant de requêtes sortantes {#maximum-allowed-object-count-in-xml-http-responses-from-outbound-requests}

{{< history >}}

- Introduit dans GitLab 18.4.

{{< /history >}}

Ce paramètre restreint le nombre maximum d'objets autorisé dans les réponses HTTP XML provenant de requêtes sortantes. Le nombre d'objets est estimé en fonction du nombre d'occurrences de `<`, `=` dans la réponse.

Le nombre maximum par défaut est de 250 000 objets. Pour désactiver cette limite, définissez la valeur sur 0.

Vous pouvez modifier cette limite en utilisant la console Rails GitLab ou l'[API des paramètres d'application](../api/settings.md) :

```ruby
ApplicationSetting.update(max_http_response_xml_structural_chars: 500000)
```

### Nombre maximum d'objets autorisé dans les réponses HTTP CSV provenant de requêtes sortantes {#maximum-allowed-object-count-in-csv-http-responses-from-outbound-requests}

{{< history >}}

- Introduit dans GitLab 18.4.

{{< /history >}}

Ce paramètre restreint le nombre maximum d'objets autorisé dans les réponses HTTP CSV provenant de requêtes sortantes. Le nombre d'objets est estimé en fonction du nombre d'occurrences de `,`, `;`, `\t`, `\r` et `\n` dans la réponse.

Le nombre maximum par défaut est de 250 000 objets. Pour désactiver cette limite, définissez la valeur sur 0.

Vous pouvez modifier cette limite en utilisant la console Rails GitLab ou l'[API des paramètres d'application](../api/settings.md) :

```ruby
ApplicationSetting.update(max_http_response_csv_structural_chars: 500000)
```

## Limites des requêtes HTTP {#http-request-limits}

Par défaut, les paramètres JSON dans les requêtes sont limités. Pour plus d'informations, consultez [les limites de validation JSON par point de terminaison](#json-validation-limits-by-endpoint).

{{< tabs >}}

{{< tab title="Linux package (Omnibus)" >}}

Pour désactiver cette vérification :

1. Définissez la variable d'environnement `GITLAB_JSON_GLOBAL_VALIDATION_MODE` sur tous les nœuds qui exécutent Puma :

   ```shell
   sudo -e /etc/gitlab/gitlab.rb
   ```

   ```ruby
   gitlab_rails['env'] = { 'GITLAB_JSON_GLOBAL_VALIDATION_MODE' => 'disabled' }
   ```

1. Reconfigurez les nœuds mis à jour pour que la modification prenne effet :

   ```shell
   sudo gitlab-ctl reconfigure
   ```

{{< /tab >}}

{{< tab title="Helm chart (Kubernetes)" >}}

Pour désactiver cette vérification, vous pouvez utiliser `--set gitlab.webservice.extraEnv.GITLAB_JSON_GLOBAL_VALIDATION_MODE="disabled"`, ou spécifier ce qui suit dans votre fichier de valeurs :

```yaml
gitlab:
  webservice:
    extraEnv:
      GITLAB_JSON_GLOBAL_VALIDATION_MODE: "disabled"
```

{{< /tab >}}

{{< /tabs >}}

### Limites de validation JSON par point de terminaison {#json-validation-limits-by-endpoint}

Certains points de terminaison d'API ont des limites de validation JSON spécifiques.

| Point de terminaison                                                                                     | Description           | Méthodes | Profondeur maximale | Taille maximale du tableau | Taille maximale du hash | Nombre total maximum d'éléments | Taille maximale JSON | Mode |
|:---------------------------------------------------------------------------------------------|:----------------------|:--------|:----------|:---------------|:--------------|:-------------------|:--------------|:-----|
| Tous les autres chemins                                                                              | Valeur par défaut               | Tous     | 32        | 50 000         | 50 000        | 100 000            | 0 (désactivé)  | enforced |
| `/api/v4/projects/{id}/terraform/state/`                                                     | État Terraform       | POST    | 64        | 50 000         | 50 000        | 250 000            | 50 Mo         | logging <sup>1</sup> |
| `/api/v4/packages/npm/-/npm/v1/security/`<br/>`{advisories/bulk\|audits/quick}`               | Paquets NPM d'instance | POST    | 32        | 50 000         | 50 000        | 250 000            | 50 Mo         | enforced |
| `/api/v4/groups/{id}/-/packages/npm/-/npm/v1/security/`<br/>`{advisories/bulk\|audits/quick}` | Paquets NPM de groupe    | POST    | 32        | 50 000         | 50 000        | 250 000            | 50 Mo         | enforced |
| `/api/v4/projects/{id}/packages/npm/-/npm/v1/security/`<br/>`{advisories/bulk\|audits/quick}` | Paquets NPM de projet  | POST    | 32        | 50 000         | 50 000        | 250 000            | 50 Mo         | enforced |
| `/api/v4/internal/*`                                                                         | API interne          | POST    | 32        | 50 000         | 50 000        | 0 (désactivé)       | 10 Mo         | enforced |
| `/api/v4/ai/duo_workflows/workflows/*`                                                        | API GitLab Duo Workflow      | POST    | 32        | 5 000          | 5 000         | 0 (désactivé)       | 25 Mo         | enforced |

**Footnotes** :

1. La limite de taille maximale de l'état Terraform peut être définie en utilisant l'[API des paramètres d'application](../api/settings.md) pour définir `max_terraform_state_size_bytes`.

### Configuration des variables d'environnement {#environment-variable-configuration}

Les variables d'environnement suivantes modifient les limites par défaut et les modes de validation :

| Variable d'environnement                 | Objectif                     | Valeur par défaut      | Portée |
|:-------------------------------------|:----------------------------|:-------------|:------|
| `GITLAB_JSON_MAX_DEPTH`              | Profondeur d'imbrication maximale par défaut   | 32           | Limites par défaut uniquement |
| `GITLAB_JSON_MAX_ARRAY_SIZE`         | Nombre maximum d'éléments de tableau par défaut  | 50 000       | Limites par défaut uniquement |
| `GITLAB_JSON_MAX_HASH_SIZE`          | Nombre maximum de clés de hash par défaut       | 50 000       | Limites par défaut uniquement |
| `GITLAB_JSON_MAX_TOTAL_ELEMENTS`     | Nombre total maximum d'éléments par défaut  | 100 000      | Limites par défaut uniquement |
| `GITLAB_JSON_MAX_JSON_SIZE_BYTES`    | Taille maximale du corps par défaut       | 0 (désactivé) | Limites par défaut uniquement |
| `GITLAB_JSON_VALIDATION_MODE`        | Mode de validation par défaut     | `enforced`   | Limites par défaut uniquement |
| `GITLAB_JSON_GLOBAL_VALIDATION_MODE` | Remplacer tous les modes de point de terminaison | Non défini      | Tous les points de terminaison (remplacement global) |

La variable d'environnement `GITLAB_JSON_GLOBAL_VALIDATION_MODE` peut être définie sur l'un de ces modes.

| Mode       | Description |
|:-----------|:------------|
| `enforced` | Valide et bloque les requêtes dépassant les limites (renvoie HTTP 400). Utilisé pour la protection en production. |
| `logging`  | Valide et enregistre les violations, mais laisse passer les requêtes. Utilisé pour la surveillance et le débogage. Tous les points de terminaison sont en mode log uniquement, ce qui remplace `enforced`. |
| disabled   | Ignore entièrement la validation. Utilisé comme contournement d'urgence. |

Lors de l'utilisation de `GITLAB_JSON_GLOBAL_VALIDATION_MODE` :

- Les configurations spécifiques aux routes remplacent les limites par défaut, mais pas le mode de validation global.
- Lorsque les limites sont dépassées en mode enforced, la réponse est HTTP 400 avec un message d'erreur JSON.
- Le nombre total d'éléments inclut tous les éléments dans les tableaux et les hashes dans toute la structure JSON.

## Limites des webhooks {#webhook-limits}

Voir aussi [les limites de débit des webhooks](#webhook-rate-limit).

### Nombre de webhooks {#number-of-webhooks}

Pour définir le nombre maximum de webhooks de groupe ou de projet pour une instance GitLab Self-Managed, exécutez ce qui suit dans la [console Rails GitLab](operations/rails_console.md#starting-a-rails-console-session) :

```ruby
# If limits don't exist for the default plan, you can create one with:
# Plan.default.create_limits!

# For project webhooks
Plan.default.actual_limits.update!(project_hooks: 200)

# For group webhooks
Plan.default.actual_limits.update!(group_hooks: 100)
```

Définissez la limite à `0` pour la désactiver.

Le nombre maximum par défaut de webhooks est `100` par projet et `50` par groupe. Les webhooks d'un sous-groupe ne sont pas comptabilisés dans la limite de webhook de leur groupe parent.

Pour GitLab.com, consultez les [limites de webhook pour GitLab.com](../user/gitlab_com/_index.md#webhooks).

### Taille du payload de webhook {#webhook-payload-size}

La taille maximale du payload de webhook est de 25 Mo.

### Délai d'expiration du webhook {#webhook-timeout}

Le nombre de secondes pendant lesquelles GitLab attend une réponse HTTP après l'envoi d'un webhook.

Pour modifier la valeur du délai d'expiration du webhook :

1. Modifiez `/etc/gitlab/gitlab.rb` sur tous les nœuds GitLab qui exécutent Sidekiq :

   ```ruby
   gitlab_rails['webhook_timeout'] = 60
   ```

1. Enregistrez le fichier.
1. Reconfigurez et redémarrez GitLab pour que les modifications prennent effet :

   ```shell
   gitlab-ctl reconfigure
   gitlab-ctl restart
   ```

Voir aussi [les limites de webhook pour GitLab.com](../user/gitlab_com/_index.md#other-limits).

### Webhooks récursifs {#recursive-webhooks}

GitLab détecte et bloque les webhooks récursifs ou qui dépassent la limite de webhooks pouvant être déclenchés par d'autres webhooks. Cela permet à GitLab de continuer à prendre en charge les workflows qui utilisent des webhooks pour appeler l'API de manière non récursive, ou qui ne déclenchent pas un nombre déraisonnable d'autres webhooks.

La récursion peut se produire lorsqu'un webhook est configuré pour effectuer un appel vers sa propre instance GitLab (par exemple, l'API). L'appel déclenche alors le même webhook et crée une boucle infinie.

Le nombre maximum de requêtes vers une instance effectuées par une série de webhooks qui en déclenchent d'autres est de 100. Lorsque la limite est atteinte, GitLab bloque tout webhook supplémentaire qui serait déclenché par la série.

Les appels de webhook récursifs bloqués sont enregistrés dans `auth.log` avec le message `"Recursive webhook blocked from executing"`.

## Limites des utilisateurs fictifs d'import {#import-placeholder-user-limits}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/455903) dans GitLab 17.4.

{{< /history >}}

Le nombre d'[utilisateurs fictifs](../user/import/mapping/post_migration_mapping.md#placeholder-users) créés lors d'un import peut être limité par espace de nommage de premier niveau.

La limite par défaut pour [GitLab Self-Managed](../subscriptions/manage_subscription.md) est `0` (illimitée).

Pour modifier cette limite pour une instance GitLab Self-Managed, exécutez ce qui suit dans la [console Rails GitLab](operations/rails_console.md#starting-a-rails-console-session) :

```ruby
# If limits don't exist for the default plan, you can create one with:
# Plan.default.create_limits!

Plan.default.actual_limits.update!(import_placeholder_user_limit_tier_1: 200)
```

Définissez la limite à `0` pour la désactiver.

## Intervalle de mise en miroir pull {#pull-mirroring-interval}

Le [temps d'attente minimum entre les actualisations pull](../user/project/repository/mirror/_index.md) est par défaut de 300 secondes (5 minutes). Par exemple, une actualisation pull ne s'exécute qu'une seule fois dans une période de 300 secondes donnée, quel que soit le nombre de fois où vous la déclenchez.

Ce paramètre s'applique dans le contexte des actualisations pull invoquées à l'aide de l'[API projects](../api/project_pull_mirroring.md#start-the-pull-mirroring-process-for-a-project), ou lors du forçage d'une mise à jour en sélectionnant **Mettre à jour maintenant** ({{< icon name="retry" >}}) dans **Paramètres** > **Dépôt** > **Dépôts miroir**. Ce paramètre n'a aucun effet sur la planification automatique à intervalles de 30 minutes utilisée par Sidekiq pour la [mise en miroir pull](../user/project/repository/mirror/pull.md).

Pour modifier cette limite pour une instance GitLab Self-Managed, exécutez ce qui suit dans la [console Rails GitLab](operations/rails_console.md#starting-a-rails-console-session) :

```ruby
# If limits don't exist for the default plan, you can create one with:
# Plan.default.create_limits!

Plan.default.actual_limits.update!(pull_mirror_interval_seconds: 200)
```

## E-mails entrants provenant de répondeurs automatiques {#incoming-emails-from-auto-responders}

GitLab ignore tous les e-mails entrants envoyés depuis des répondeurs automatiques en recherchant l'en-tête `X-Autoreply`. Ces e-mails ne créent pas de commentaires sur les tickets ou les merge requests.

## Quantité de données envoyées depuis Sentry via Error Tracking {#amount-of-data-sent-from-sentry-through-error-tracking}

{{< history >}}

- [Limitation de toutes les réponses Sentry](https://gitlab.com/gitlab-org/gitlab/-/issues/356448) introduite dans GitLab 15.6.

{{< /history >}}

Les payloads Sentry envoyés à GitLab ont une limite maximale de 1 Mo, à la fois pour des raisons de sécurité et pour limiter la consommation de mémoire.

## Décalage maximum autorisé par l'API REST pour la pagination basée sur le décalage {#max-offset-allowed-by-the-rest-api-for-offset-based-pagination}

Lors de l'utilisation de la pagination basée sur le décalage dans l'API REST, il existe une limite au décalage maximum demandé dans l'ensemble des résultats. Cette limite ne s'applique qu'aux points de terminaison qui prennent également en charge la pagination basée sur les ensembles de clés. Vous trouverez plus d'informations sur les options de pagination dans la [section de la documentation de l'API sur la pagination](../api/rest/_index.md#pagination).

Pour définir cette limite pour une instance GitLab Self-Managed, exécutez ce qui suit dans la [console Rails GitLab](operations/rails_console.md#starting-a-rails-console-session) :

```ruby
# If limits don't exist for the default plan, you can create one with:
# Plan.default.create_limits!

Plan.default.actual_limits.update!(offset_pagination_limit: 10000)
```

- **Default offset pagination limit** : `50000`.

Définissez la limite à `0` pour la désactiver.

## Limites CI/CD {#cicd-limits}

### Nombre de jobs dans les pipelines actifs {#number-of-jobs-in-active-pipelines}

Le nombre total de jobs dans les pipelines actifs peut être limité par projet. Cette limite est vérifiée à chaque fois qu'un nouveau pipeline est créé. Un pipeline actif est tout pipeline dans l'un des états suivants :

- `created`
- `pending`
- `running`

Si un nouveau pipeline entraîne le dépassement de la limite par le nombre total de jobs, le pipeline échoue avec une erreur `job_activity_limit_exceeded`.

- Sur GitLab.com, une limite est [définie pour chaque niveau d'abonnement](../user/gitlab_com/_index.md#cicd), et cette limite affecte tous les projets avec ce niveau.
- Sur GitLab Self-Managed, les abonnements [Premium ou Ultimate](https://about.gitlab.com/pricing/), cette limite est définie dans un plan `default` qui affecte tous les projets. Cette limite est désactivée (`0`) par défaut.

Pour définir cette limite pour une instance GitLab Self-Managed, exécutez ce qui suit dans la [console Rails GitLab](operations/rails_console.md#starting-a-rails-console-session) :

```ruby
# If limits don't exist for the default plan, you can create one with:
# Plan.default.create_limits!

Plan.default.actual_limits.update!(ci_active_jobs: 500)
```

Définissez la limite à `0` pour la désactiver.

### Durée maximale d'exécution des jobs {#maximum-time-jobs-can-run}

La durée maximale par défaut pendant laquelle les jobs peuvent s'exécuter est de 60 minutes. Les jobs qui s'exécutent pendant plus de 60 minutes expirent.

Vous pouvez modifier la durée maximale pendant laquelle un job peut s'exécuter avant d'expirer :

- Au niveau du projet dans les [paramètres CI/CD du projet](../ci/pipelines/settings.md#set-a-limit-for-how-long-jobs-can-run) pour un projet donné. Cette limite doit être comprise entre 10 minutes et 1 mois.
- Au niveau du [runner](../ci/runners/configure_runners.md#set-the-maximum-job-timeout). Cette limite doit être de 10 minutes ou plus.

Indépendamment des limites de délai d'expiration configurées, GitLab termine tout job qui est resté inactif pendant 60 minutes. Un job inactif est un job qui n'a produit aucun nouveau log ni aucune mise à jour de trace.

### Nombre maximum de jobs dans un pipeline {#maximum-number-of-jobs-in-a-pipeline}

Vous pouvez limiter le nombre maximum de jobs dans un pipeline. Le nombre de jobs dans un pipeline est vérifié à la création du pipeline et lors de la création de nouveaux statuts de commit. Les pipelines qui ont trop de jobs échouent avec une erreur `size_limit_exceeded`.

- Sur GitLab.com, une limite est [définie pour chaque niveau d'abonnement](../user/gitlab_com/_index.md#cicd), et cette limite affecte tous les projets avec ce niveau.
- Sur GitLab Self-Managed, les abonnements [Premium ou Ultimate](https://about.gitlab.com/pricing/), cette limite est définie dans un plan `default` qui affecte tous les projets. Cette limite est désactivée (`0`) par défaut.

Pour modifier la limite pour une instance GitLab Self-Managed, modifiez la limite du plan `default` avec la commande [console Rails GitLab](operations/rails_console.md#starting-a-rails-console-session) suivante :

```ruby
# If limits don't exist for the default plan, you can create one with:
# Plan.default.create_limits!

Plan.default.actual_limits.update!(ci_pipeline_size: 500)
```

Définissez la limite à `0` pour la désactiver.

### Nombre maximum de jobs de déploiement dans un pipeline {#maximum-number-of-deployment-jobs-in-a-pipeline}

Vous pouvez limiter le nombre maximum de jobs de déploiement dans un pipeline. Un déploiement est tout job avec un [`environment`](../ci/environments/_index.md) spécifié. Le nombre de déploiements dans un pipeline est vérifié à la création du pipeline. Les pipelines qui ont trop de déploiements échouent avec une erreur `deployments_limit_exceeded`.

La limite par défaut est de 500 pour tous les [abonnements GitLab Self-Managed et GitLab.com](https://about.gitlab.com/pricing/).

Pour modifier la limite pour une instance GitLab Self-Managed, modifiez la limite du plan `default` avec la commande [console Rails GitLab](operations/rails_console.md#starting-a-rails-console-session) suivante :

```ruby
# If limits don't exist for the default plan, you can create one with:
# Plan.default.create_limits!

Plan.default.actual_limits.update!(ci_pipeline_deployments: 500)
```

Définissez la limite à `0` pour la désactiver.

### Limiter la taille de la hiérarchie de pipeline {#limit-pipeline-hierarchy-size}

Par défaut, une [hiérarchie de pipeline](../ci/pipelines/downstream_pipelines.md) peut contenir jusqu'à 1 000 pipelines downstream. Lorsque cette limite est dépassée, la création du pipeline échoue avec l'erreur `downstream pipeline tree is too large`.

> [!warning]
> Il n'est pas recommandé d'augmenter cette limite. La limite par défaut protège votre instance GitLab d'une consommation excessive de ressources, d'une récursion potentielle de pipeline et d'une surcharge de la base de données.
>
> Au lieu d'augmenter la limite, restructurez votre configuration CI/CD en divisant les grandes hiérarchies de pipeline en pipelines plus petits. Envisagez d'utiliser `needs` entre les jobs ou des étapes dépendantes au sein d'un seul pipeline.

Pour modifier cette limite sur votre instance, utilisez l'interface utilisateur GitLab dans la [zone Admin](settings/continuous_integration.md#set-cicd-limits) ou l'[API Plan Limits](../api/plan_limits.md).

Vous pouvez également exécuter la commande suivante dans la console Rails GitLab :

```ruby
Plan.default.actual_limits.update!(pipeline_hierarchy_size: 500)
```

Cette limite est activée sur GitLab.com et ne peut pas être modifiée.

### Limite de pipeline parallèle du merge train {#merge-train-parallel-pipeline-limit}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/374188) dans GitLab 19.0.

{{< /history >}}

Par défaut, chaque [merge train](../ci/pipelines/merge_trains.md) peut exécuter un maximum de 20 pipelines en parallèle. Lorsque cette limite est atteinte, les merge requests supplémentaires sont mises en file d'attente jusqu'à ce qu'un emplacement de pipeline soit disponible.

Pour modifier cette limite sur votre instance, accédez à la zone **Admin** > **Paramètres** > **CI/CD** > **CI/CD Limits**, ou utilisez l'[API plan limits](../api/plan_limits.md).

Vous pouvez également exécuter la commande suivante dans la console Rails GitLab :

```ruby
Plan.default.actual_limits.update!(max_pipelines_per_merge_train: 10)
```

Pour définir une limite inférieure pour un projet spécifique, accédez à **Paramètres** > **Requêtes de fusion** > **Options de fusion**, utilisez l'[API projects](../api/projects.md) , ou l'[API GraphQL](../api/graphql/reference/_index.md#projectcicdsetting). La limite du projet ne peut pas dépasser la limite de l'instance.

La valeur minimale est `1`. Une valeur de `1` traite les merge requests séquentiellement sans parallélisme.

### Nombre d'abonnements CI/CD à un projet {#number-of-cicd-subscriptions-to-a-project}

Le nombre total d'abonnements peut être limité par projet. Cette limite est vérifiée à chaque fois qu'un nouvel abonnement est créé.

Si un nouvel abonnement entraîne le dépassement de la limite par le nombre total d'abonnements, l'abonnement est considéré comme invalide.

- Sur GitLab.com, une limite est [définie pour chaque niveau d'abonnement](../user/gitlab_com/_index.md#cicd), et cette limite affecte tous les projets avec ce niveau.
- Sur GitLab Self-Managed [Premium ou Ultimate](https://about.gitlab.com/pricing/), cette limite est définie dans un plan `default` qui affecte tous les projets. Par défaut, il existe une limite de `2` abonnements.

Pour définir cette limite pour une instance GitLab Self-Managed, exécutez ce qui suit dans la [console Rails GitLab](operations/rails_console.md#starting-a-rails-console-session) :

```ruby
Plan.default.actual_limits.update!(ci_project_subscriptions: 500)
```

Définissez la limite à `0` pour la désactiver.

### Limiter le nombre de déclencheurs de pipeline {#limit-the-number-of-pipeline-triggers}

Vous pouvez définir une limite sur le nombre maximum de déclencheurs de pipeline par projet. Cette limite est vérifiée à chaque fois qu'un nouveau déclencheur est créé.

Si un nouveau déclencheur entraîne le dépassement de la limite par le nombre total de déclencheurs de pipeline, le déclencheur est considéré comme invalide.

Définissez la limite à `0` pour la désactiver. La valeur par défaut est `25000` sur GitLab Self-Managed.

Pour définir cette limite à `100` sur une instance GitLab Self-Managed, exécutez ce qui suit dans la [console Rails GitLab](operations/rails_console.md#starting-a-rails-console-session) :

```ruby
Plan.default.actual_limits.update!(pipeline_triggers: 100)
```

Cette limite est [activée sur GitLab.com](../user/gitlab_com/_index.md#cicd).

### Nombre de planifications de pipeline {#number-of-pipeline-schedules}

{{< details >}}

- Niveau :  Premium, Ultimate
- Offre :  GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Le nombre total de planifications de pipeline peut être limité par projet. Cette limite est vérifiée à chaque fois qu'une nouvelle planification de pipeline est créée. Si une nouvelle planification de pipeline entraîne le dépassement de la limite par le nombre total de planifications de pipeline, la planification de pipeline n'est pas créée.

Sur GitLab.com, la limite est [définie pour chaque niveau d'abonnement](../user/gitlab_com/_index.md#cicd), et cette limite affecte tous les projets avec ce niveau.

Sur GitLab Self-Managed et GitLab Dedicated, cette limite est définie dans un plan `default` qui affecte tous les projets. Par défaut, il existe une limite de `10` planifications de pipeline.

Pour définir cette limite, utilisez l'[API Plan Limits](../api/plan_limits.md).

Pour GitLab Self-Managed, vous pouvez également utiliser la [console Rails GitLab](operations/rails_console.md#starting-a-rails-console-session). Par exemple, pour définir la limite à 100 :

```ruby
Plan.default.actual_limits.update!(ci_pipeline_schedules: 100)
```

### Limiter le nombre de pipelines créés par une planification de pipeline chaque jour {#limit-the-number-of-pipelines-created-by-a-pipeline-schedule-each-day}

Vous pouvez limiter le nombre de pipelines que chaque planification de pipeline individuelle peut déclencher par jour.

Les planifications qui tentent d'exécuter des pipelines plus fréquemment que la limite sont ralenties à une fréquence maximale. La fréquence est calculée en divisant 1440 (le nombre de minutes dans une journée) par la valeur limite. Par exemple, pour une fréquence maximale de :

- Une fois par minute, la limite doit être `1440`.
- Une fois par 10 minutes, la limite doit être `144`.
- Une fois par 60 minutes, la limite doit être `24`

La valeur minimale est `24`, soit un pipeline par 60 minutes. Il n'y a pas de valeur maximale.

Pour définir cette limite à `1440` sur une instance GitLab Self-Managed, exécutez ce qui suit dans la [console Rails GitLab](operations/rails_console.md#starting-a-rails-console-session) :

```ruby
Plan.default.actual_limits.update!(ci_daily_pipeline_schedule_triggers: 1440)
```

Cette limite est [activée sur GitLab.com](../user/gitlab_com/_index.md#cicd).

### Limiter le nombre de règles de planification définies pour le projet de politique de sécurité {#limit-the-number-of-schedule-rules-defined-for-security-policy-project}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/335659) dans GitLab 15.1.

{{< /history >}}

Vous pouvez limiter le nombre total de règles de planification par projet de politique de sécurité. Cette limite est vérifiée à chaque fois que les politiques avec des règles de planification sont mises à jour. Si une nouvelle règle de planification entraîne le dépassement de la limite par le nombre total de règles de planification, la nouvelle règle de planification n'est pas traitée.

Par défaut, GitLab Self-Managed ne limite pas le nombre de règles de planification traitables.

Pour définir cette limite pour une instance GitLab Self-Managed, exécutez ce qui suit dans la [console Rails GitLab](operations/rails_console.md#starting-a-rails-console-session) :

```ruby
Plan.default.actual_limits.update!(security_policy_scan_execution_schedules: 100)
```

Cette limite est [activée sur GitLab.com](../user/gitlab_com/_index.md#cicd).

### Limites des variables CI/CD {#cicd-variable-limits}

{{< history >}}

- Les limites de variables de groupe et de projet ont été [introduites](https://gitlab.com/gitlab-org/gitlab/-/issues/362227) dans GitLab 15.7.

{{< /history >}}

Le nombre de [variables CI/CD](../ci/variables/_index.md) pouvant être définies dans les paramètres de projet, de groupe et d'instance est limité pour l'ensemble de l'instance. Ces limites sont vérifiées à chaque fois qu'une nouvelle variable est créée. Si une nouvelle variable devait entraîner le dépassement de la limite respective par le nombre total de variables, la nouvelle variable n'est pas créée.

Pour mettre à jour le plan `default` de l'une de ces limites sur une instance GitLab Self-Managed, exécutez la commande suivante dans la [console Rails GitLab](operations/rails_console.md#starting-a-rails-console-session) :

- Limite des [variables CI/CD au niveau de l'instance](../ci/variables/_index.md#for-an-instance) (par défaut : `25`) :

  ```ruby
  Plan.default.actual_limits.update!(ci_instance_level_variables: 30)
  ```

- Limite des [variables CI/CD au niveau du groupe](../ci/variables/_index.md#for-a-group) par groupe (par défaut : `30000`) :

  ```ruby
  Plan.default.actual_limits.update!(group_ci_variables: 40000)
  ```

- Limite des [variables CI/CD au niveau du projet](../ci/variables/_index.md#for-a-project) par projet (par défaut : `8000`) :

  ```ruby
  Plan.default.actual_limits.update!(project_ci_variables: 10000)
  ```

### Taille de fichier maximale par type d'artefact {#maximum-file-size-per-type-of-artifact}

{{< history >}}

- Limite `ci_max_artifact_size_annotations` [introduite](https://gitlab.com/gitlab-org/gitlab/-/issues/38337) dans GitLab 16.3.
- Limite `ci_max_artifact_size_jacoco` [introduite](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/159696) dans GitLab 17.3
- Limite `ci_max_artifact_size_lsif` [augmentée](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/175684) dans GitLab 17.8.

{{< /history >}}

Les artefacts de job définis avec [`artifacts:reports`](../ci/yaml/_index.md#artifactsreports) qui sont téléversés par le runner sont rejetés si la taille du fichier dépasse la limite maximale. La limite est déterminée en comparant le [paramètre de taille maximale d'artefact](settings/continuous_integration.md#set-maximum-artifacts-size) du projet avec la limite d'instance pour le type d'artefact concerné, et en choisissant la valeur la plus petite.

Les limites sont définies en mégaoctets, donc la plus petite valeur possible pouvant être définie est `1 MB`.

Chaque type d'artefact dispose d'une limite de taille pouvant être configurée. Une valeur par défaut de `0` signifie qu'il n'y a pas de limite pour ce type d'artefact spécifique, et le paramètre de taille maximale d'artefact du projet est utilisé :

| Nom de la limite d'artefact                         | Valeur par défaut |
|---------------------------------------------|---------------|
| `ci_max_artifact_size_accessibility`        | 0             |
| `ci_max_artifact_size_annotations`          | 0             |
| `ci_max_artifact_size_api_fuzzing`          | 0             |
| `ci_max_artifact_size_archive`              | 0             |
| `ci_max_artifact_size_browser_performance`  | 0             |
| `ci_max_artifact_size_cluster_applications` | 0             |
| `ci_max_artifact_size_cobertura`            | 0             |
| `ci_max_artifact_size_codequality`          | 0             |
| `ci_max_artifact_size_container_scanning`   | 0             |
| `ci_max_artifact_size_coverage_fuzzing`     | 0             |
| `ci_max_artifact_size_dast`                 | 0             |
| `ci_max_artifact_size_dependency_scanning`  | 0             |
| `ci_max_artifact_size_dotenv`               | 0             |
| `ci_max_artifact_size_jacoco`               | 0             |
| `ci_max_artifact_size_junit`                | 0             |
| `ci_max_artifact_size_license_management`   | 0             |
| `ci_max_artifact_size_license_scanning`     | 0             |
| `ci_max_artifact_size_load_performance`     | 0             |
| `ci_max_artifact_size_lsif`                 | 200 MB        |
| `ci_max_artifact_size_metadata`             | 0             |
| `ci_max_artifact_size_metrics_referee`      | 0             |
| `ci_max_artifact_size_metrics`              | 0             |
| `ci_max_artifact_size_network_referee`      | 0             |
| `ci_max_artifact_size_performance`          | 0             |
| `ci_max_artifact_size_requirements`         | 0             |
| `ci_max_artifact_size_requirements_v2`      | 0             |
| `ci_max_artifact_size_sast`                 | 0             |
| `ci_max_artifact_size_secret_detection`     | 0             |
| `ci_max_artifact_size_terraform`            | 5 MB          |
| `ci_max_artifact_size_trace`                | 0             |
| `ci_max_artifact_size_cyclonedx`            | 5 MB          |

Par exemple, pour définir la limite `ci_max_artifact_size_junit` à 10 Mo sur GitLab Self-Managed, exécutez la commande suivante dans la [console Rails GitLab](operations/rails_console.md#starting-a-rails-console-session) :

```ruby
Plan.default.actual_limits.update!(ci_max_artifact_size_junit: 10)
```

### Nombre de fichiers par site web GitLab Pages {#number-of-files-per-gitlab-pages-website}

Le nombre total d'entrées de fichiers (y compris les répertoires et les liens symboliques) est limité à `200,000` par site web GitLab Pages.

Il s'agit de la limite par défaut pour [GitLab Self-Managed et GitLab.com](https://about.gitlab.com/pricing/).

Pour mettre à jour la limite dans votre instance GitLab Self-Managed, utilisez la [console Rails GitLab](operations/rails_console.md#starting-a-rails-console-session). Par exemple, pour modifier la limite à `100` :

```ruby
Plan.default.actual_limits.update!(pages_file_entries: 100)
```

### Nombre de domaines personnalisés par site web GitLab Pages {#number-of-custom-domains-per-gitlab-pages-website}

Le nombre total de domaines personnalisés par site web GitLab Pages est limité à `150` pour [GitLab.com](../subscriptions/manage_seats.md#gitlabcom-billing-and-usage).

La limite par défaut pour [GitLab Self-Managed](../subscriptions/manage_subscription.md) est `0` (illimitée). Pour définir une limite sur votre instance, utilisez la [zone **Admin**](pages/_index.md#set-maximum-number-of-gitlab-pages-custom-domains-for-a-project).

### Nombre de déploiements Pages en parallèle {#number-of-parallel-pages-deployments}

Lors de l'utilisation des [déploiements Pages en parallèle](../user/project/pages/parallel_deployments.md), le nombre total de déploiements Pages en parallèle autorisés pour un groupe principal est de 1000.

Lorsqu'un projet dispose d'un [domaine unique](../user/project/pages/_index.md#unique-domains) activé, le domaine unique du projet est traité comme son propre groupe principal avec une limite distincte de 1000 déploiements.

### Nombre de runners enregistrés pour chaque portée {#number-of-registered-runners-for-each-scope}

{{< history >}}

- Délai d'expiration de runner inactif [modifié](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/155795) de 3 mois à 7 jours dans GitLab 17.1.

{{< /history >}}

Le nombre total de runners enregistrés est limité pour les groupes et les projets. À chaque enregistrement d'un nouveau runner, GitLab vérifie ces limites par rapport aux runners créés ou actifs au cours des 7 derniers jours. L'enregistrement d'un runner échoue s'il dépasse la limite pour la portée déterminée par le jeton d'enregistrement du runner. Si la valeur de la limite est définie sur zéro, la limite est désactivée.

Les abonnés GitLab.com ont des limites différentes définies par abonnement, affectant tous les projets utilisant cet abonnement.

Les limites Premium et Ultimate sur GitLab Self-Managed sont définies par un plan par défaut qui affecte tous les projets :

| Portée du runner                    | Valeur par défaut |
|---------------------------------|---------------|
| `ci_registered_group_runners`   | 1000          |
| `ci_registered_project_runners` | 1000          |

Pour mettre à jour ces limites, exécutez la commande suivante dans la [console Rails GitLab](operations/rails_console.md#starting-a-rails-console-session) :

```ruby
# Use ci_registered_group_runners or ci_registered_project_runners
# depending on desired scope
Plan.default.actual_limits.update!(ci_registered_project_runners: 100)
```

### Taille de fichier maximale pour les job logs {#maximum-file-size-for-job-logs}

La limite de taille de fichier de job log dans GitLab est de 100 mégaoctets par défaut. Tout job qui dépasse la limite est marqué comme ayant échoué et est abandonné par le runner.

Vous pouvez modifier la limite dans la [console Rails GitLab](operations/rails_console.md#starting-a-rails-console-session). Mettez à jour `ci_jobs_trace_size_limit` avec la nouvelle valeur en mégaoctets :

```ruby
Plan.default.actual_limits.update!(ci_jobs_trace_size_limit: 125)
```

GitLab Runner dispose également d'un [paramètre `output_limit`](https://docs.gitlab.com/runner/configuration/advanced-configuration/#the-runners-section) qui configure la taille maximale du log dans un runner. Les jobs qui dépassent la limite du runner continuent de s'exécuter, mais le log est tronqué lorsqu'il atteint la limite.

### Nombre maximal de planifications de profils DAST actives par projet {#maximum-number-of-active-dast-profile-schedules-per-project}

Limiter le nombre de planifications de profils DAST actives par projet. Une planification de profil DAST peut être active ou inactive.

Vous pouvez modifier la limite dans la [console Rails GitLab](operations/rails_console.md#starting-a-rails-console-session). Mettez à jour `dast_profile_schedules` avec la nouvelle valeur :

```ruby
Plan.default.actual_limits.update!(dast_profile_schedules: 50)
```

### Taille maximale de l'archive d'artefacts CI {#maximum-size-of-the-ci-artifacts-archive}

Ce paramètre est utilisé pour restreindre les tailles YAML des [pipelines enfants dynamiques](../ci/pipelines/downstream_pipelines.md#dynamic-child-pipelines).

La taille maximale par défaut de l'archive d'artefacts CI est de 5 mégaoctets.

Vous pouvez modifier cette limite en utilisant la [console Rails GitLab](operations/rails_console.md#starting-a-rails-console-session). Pour mettre à jour la taille maximale de l'archive d'artefacts CI, mettez à jour `max_artifacts_content_include_size` avec la nouvelle valeur. Par exemple, pour la définir à 20 Mo :

```ruby
ApplicationSetting.update(max_artifacts_content_include_size: 20.megabytes)
```

### Taille et profondeur maximales des fichiers YAML de configuration CI/CD {#maximum-size-and-depth-of-cicd-configuration-yaml-files}

{{< history >}}

- Valeur par défaut de `max_yaml_size_bytes` [modifiée](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/160826) dans GitLab 17.3.

{{< /history >}}

La taille maximale par défaut d'un seul fichier YAML de configuration CI/CD est de 2 mégaoctets et la profondeur par défaut est de 100.

Vous pouvez modifier ces limites dans la [console Rails GitLab](operations/rails_console.md#starting-a-rails-console-session) :

- Pour mettre à jour la taille maximale du YAML, mettez à jour `max_yaml_size_bytes` avec la nouvelle valeur en mégaoctets :

  ```ruby
  ApplicationSetting.update(max_yaml_size_bytes: 4.megabytes)
  ```

  La valeur `max_yaml_size_bytes` n'est pas directement liée à la taille du fichier YAML, mais plutôt à la mémoire allouée pour les objets concernés.

- Pour mettre à jour la profondeur maximale du YAML, mettez à jour `max_yaml_depth` avec la nouvelle valeur en nombre de lignes :

  ```ruby
  ApplicationSetting.update(max_yaml_depth: 125)
  ```

### Taille maximale de l'ensemble de la configuration CI/CD {#maximum-size-of-the-entire-cicd-configuration}

{{< history >}}

- Valeur par défaut de `max_yaml_size_bytes` [modifiée](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/160826) dans GitLab 17.3.
- Valeur par défaut de `ci_max_total_yaml_size_bytes` [modifiée](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/160826) dans GitLab 17.3.

{{< /history >}}

La quantité maximale de mémoire, en octets, pouvant être allouée pour la configuration complète du pipeline, avec tous les fichiers de configuration YAML inclus.

La valeur par défaut est calculée en multipliant [`max_yaml_size_bytes`](#maximum-size-and-depth-of-cicd-configuration-yaml-files) (2 Mo par défaut) par [`ci_max_includes`](../api/settings.md#available-settings) (150 par défaut) :

- Dans GitLab 17.2 et versions antérieures :  1 Mo × 150 = `157286400` octets (150 Mo).
- Dans GitLab 17.3 et versions ultérieures :  2 Mo × 150 = `314572800` octets (314,6 Mo).

Vous pouvez modifier cette limite en utilisant la [console Rails GitLab](operations/rails_console.md#starting-a-rails-console-session). Pour mettre à jour la mémoire maximale pouvant être allouée pour la configuration CI/CD, mettez à jour `ci_max_total_yaml_size_bytes` avec la nouvelle valeur. Par exemple, pour la définir à 20 Mo :

```ruby
ApplicationSetting.update(ci_max_total_yaml_size_bytes: 20.megabytes)
```

### Limiter les variables dotenv {#limit-dotenv-variables}

Vous pouvez définir une limite sur le nombre maximal de variables dans un artefact dotenv. Cette limite est vérifiée chaque fois qu'un fichier dotenv est exporté en tant qu'artefact.

Définissez la limite à `0` pour la désactiver. La valeur par défaut est `20` sur GitLab Self-Managed.

Pour définir cette limite à `100` sur votre instance, exécutez la commande suivante dans la [console Rails GitLab](operations/rails_console.md#starting-a-rails-console-session) :

```ruby
Plan.default.actual_limits.update!(dotenv_variables: 100)
```

Vous pouvez également définir cette limite en utilisant l'[interface utilisateur GitLab](settings/continuous_integration.md#set-cicd-limits) ou l'[API Plan Limits](../api/plan_limits.md).

Cette limite est [activée sur GitLab.com](../user/gitlab_com/_index.md#cicd).

### Limiter la taille des fichiers dotenv {#limit-dotenv-file-size}

Vous pouvez définir une limite sur la taille maximale d'un artefact dotenv. Cette limite est vérifiée chaque fois qu'un fichier dotenv est exporté en tant qu'artefact.

Définissez la limite à `0` pour la désactiver. La valeur par défaut est 5 Ko.

Pour définir cette limite à 5 Ko sur une instance GitLab Self-Managed, exécutez la commande suivante dans la [console Rails GitLab](operations/rails_console.md#starting-a-rails-console-session) :

```ruby
Plan.default.actual_limits.update!(dotenv_size: 5.kilobytes)
```

### Limiter les annotations de job CI/CD {#limit-cicd-job-annotations}

{{< history >}}

- [Introduite](https://gitlab.com/gitlab-org/gitlab/-/issues/38337) dans GitLab 16.3.

{{< /history >}}

Vous pouvez définir une limite sur le nombre maximal d'[annotations](../ci/yaml/artifacts_reports.md#artifactsreportsannotations) par job CI/CD.

Définissez la limite à `0` pour la désactiver. La valeur par défaut est `20` sur GitLab Self-Managed.

Pour définir cette limite à `100` sur votre instance, exécutez la commande suivante dans la [console Rails GitLab](operations/rails_console.md#starting-a-rails-console-session) :

```ruby
Plan.default.actual_limits.update!(ci_job_annotations_num: 100)
```

### Limiter la taille des fichiers d'annotations de job CI/CD {#limit-cicd-job-annotations-file-size}

{{< history >}}

- [Introduite](https://gitlab.com/gitlab-org/gitlab/-/issues/38337) dans GitLab 16.3.

{{< /history >}}

Vous pouvez définir une limite sur la taille maximale d'une [annotation](../ci/yaml/artifacts_reports.md#artifactsreportsannotations) de job CI/CD.

Définissez la limite à `0` pour la désactiver. La valeur par défaut est 80 Ko.

Pour définir cette limite à 100 Ko sur une instance GitLab Self-Managed, exécutez la commande suivante dans la [console Rails GitLab](operations/rails_console.md#starting-a-rails-console-session) :

```ruby
Plan.default.actual_limits.update!(ci_job_annotations_size: 100.kilobytes)
```

### Taille maximale de partition de base de données pour les tables CI/CD {#maximum-database-partition-size-for-cicd-tables}

{{< history >}}

- [Introduite](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/189131) dans GitLab 18.0.
- [Supprimée](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/577314) dans GitLab 18.11.

{{< /history >}}

La quantité maximale d'espace disque, en octets, pouvant être utilisée par une partition d'une table partitionnée avant que de nouvelles partitions soient automatiquement créées. La valeur par défaut est 100 Go.

Vous pouvez modifier cette limite en utilisant la [console Rails GitLab](operations/rails_console.md#starting-a-rails-console-session). Pour modifier la limite, mettez à jour `ci_partitions_size_limit` avec la nouvelle valeur. Par exemple, pour la définir à 20 Go :

```ruby
ApplicationSetting.update(ci_partitions_size_limit: 20.gigabytes)
```

### Fenêtre temporelle maximale pour les partitions CI/CD {#maximum-time-window-for-cicd-partitions}

{{< history >}}

- [Introduite](https://gitlab.com/gitlab-org/gitlab/-/work_items/577314) dans GitLab 18.10.

{{< /history >}}

La fenêtre temporelle, en secondes, avant que de nouvelles partitions CI soient créées et que le système bascule vers le prochain ensemble de partitions. Doit être compris entre 1 mois et 6 mois. La valeur par défaut est 1 mois (2592000 secondes).

Vous pouvez modifier cette limite en utilisant la [console Rails GitLab](operations/rails_console.md#starting-a-rails-console-session). Pour modifier la limite, mettez à jour `ci_partitions_in_seconds_limit` avec la nouvelle valeur. Par exemple, pour la définir à 3 mois :

```ruby
ApplicationSetting.update(ci_partitions_in_seconds_limit: ChronicDuration.parse('3 months'))
```

### Valeur de configuration maximale pour le nettoyage automatique des pipelines {#maximum-config-value-for-automatic-pipeline-cleanup}

{{< history >}}

- [Introduite](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/189191) dans GitLab 18.0.

{{< /history >}}

Configure la limite supérieure pour le [nettoyage automatique des pipelines](../ci/pipelines/settings.md#automatic-pipeline-cleanup). La valeur par défaut est 1 an.

Vous pouvez modifier cette limite en utilisant la [console Rails GitLab](operations/rails_console.md#starting-a-rails-console-session). Pour modifier la limite, mettez à jour `ci_delete_pipelines_in_seconds_limit_human_readable` avec la nouvelle valeur. Par exemple, pour la définir à 3 ans :

```ruby
ApplicationSetting.update(ci_delete_pipelines_in_seconds_limit_human_readable: '3 years')
```

## Surveillance et métriques de l'instance {#instance-monitoring-and-metrics}

### Limiter les alertes entrantes de gestion des incidents {#limit-inbound-incident-management-alerts}

Ce paramètre limite le nombre de charges utiles d'alertes entrantes sur une période de temps.

En savoir plus sur les [limites de débit de la gestion des incidents](settings/rate_limit_on_pipelines_creation.md).

### Charges utiles JSON des alertes Prometheus {#prometheus-alert-json-payloads}

Les charges utiles des alertes Prometheus envoyées au point de terminaison `notify.json` sont limitées à 1 Mo.

### Charges utiles JSON d'alertes génériques {#generic-alert-json-payloads}

Les charges utiles des alertes envoyées au point de terminaison `notify.json` sont limitées à 1 Mo.

## Limites du tableau de bord des environnements {#environment-dashboard-limits}

{{< details >}}

- Niveau :  Premium, Ultimate
- Offre :  GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Consultez le [tableau de bord des environnements](../ci/environments/environments_dashboard.md#adding-a-project-to-the-dashboard) pour connaître le nombre maximal de projets affichés.

## Données d'environnement sur les tableaux de déploiement {#environment-data-on-deploy-boards}

Les [tableaux de déploiement](../user/project/deploy_boards.md) chargent les informations de Kubernetes concernant les pods et les déploiements. Cependant, les données supérieures à 10 Mo pour un environnement donné lues depuis Kubernetes ne sont pas affichées.

## Merge requests {#merge-requests}

### Limites de diff {#diff-limits}

GitLab impose des limites concernant :

- La taille du patch pour un seul fichier. [Cette option est configurable sur GitLab Self-Managed](diff_limits.md).
- La taille totale de tous les diffs pour une merge request.

Une limite supérieure et une limite inférieure s'appliquent à chacun de ces éléments :

- Le nombre de fichiers modifiés.
- Le nombre de lignes modifiées.
- La taille cumulée des modifications affichées.

Les limites inférieures entraînent la réduction des diffs supplémentaires. Les limites supérieures empêchent l'affichage de toute modification supplémentaire. Pour plus d'informations sur ces limites, consultez la documentation de développement GitLab sur l'utilisation des diffs.

### Limite de version de diff {#diff-version-limit}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/521970) dans GitLab 17.10 [avec un flag](feature_flags/_index.md) nommé `merge_requests_diffs_limit`. Désactivé par défaut. Désactivé par défaut.
- [Activée sur GitLab.com](https://gitlab.com/gitlab-org/gitlab/-/issues/521970) dans GitLab 17.10.
- [Disponibilité générale](https://gitlab.com/gitlab-org/gitlab/-/issues/537447) dans GitLab 19.0. Le feature flag `merge_requests_diffs_limit` a été supprimé.

{{< /history >}}

GitLab limite chaque merge request à 1000 [versions de diff](../user/project/merge_requests/versions.md). Les merge requests qui atteignent cette limite ne peuvent plus être mises à jour. Au lieu de cela, fermez la merge request concernée et créez-en une nouvelle.

Pour configurer cette limite, consultez [l'administration des limites de diff](diff_limits.md).

### Limite de taille des rapports de merge request {#merge-request-reports-size-limit}

Les rapports dépassant la limite de 20 Mo ne sont pas chargés. Rapports concernés :

- [Rapports de sécurité des merge requests](../ci/testing/_index.md#security-reports)
- [Paramètre CI/CD `artifacts:expose_as`](../ci/yaml/_index.md#artifactsexpose_as)
- [Rapports de tests unitaires](../ci/testing/unit_test_reports.md)

## Limites de la recherche avancée {#advanced-search-limits}

### Taille maximale de fichier indexée {#maximum-file-size-indexed}

Vous pouvez définir une limite sur le contenu des fichiers du dépôt indexés dans Elasticsearch. Tout fichier plus volumineux que cette limite n'indexe que le nom du fichier. Le contenu du fichier n'est ni indexé ni consultable.

Définir une limite aide à réduire l'utilisation de la mémoire des processus d'indexation et la taille globale de l'index. Cette valeur est par défaut `1024 KiB` (1 Mio), car les fichiers texte plus volumineux ne sont probablement pas destinés à être lus par des humains.

Vous devez définir une limite car les tailles de fichiers illimitées ne sont pas prises en charge. Définir cette valeur à un niveau supérieur à la quantité de mémoire disponible sur les nœuds GitLab Sidekiq entraîne une saturation de la mémoire de ces nœuds, car cette quantité de mémoire est préallouée lors de l'indexation.

### Longueur maximale de champ {#maximum-field-length}

Vous pouvez définir une limite sur le contenu des champs de texte indexés pour la recherche avancée. Définir un maximum aide à réduire la charge des processus d'indexation. Si un champ de texte dépasse cette limite, le texte est tronqué à ce nombre de caractères. Le reste du texte n'est pas indexé et n'est pas consultable. Ceci s'applique à toutes les données indexées, à l'exception des fichiers du dépôt indexés qui ont une limite distincte. Pour plus d'informations, consultez [Taille maximale de fichier indexée](#maximum-file-size-indexed).

- Sur GitLab.com, la limite de longueur de champ est de 20 000 caractères.
- Pour les instances GitLab Self-Managed, la longueur de champ est illimitée par défaut.

Vous pouvez configurer cette limite pour les instances GitLab Self-Managed lorsque vous [activez Elasticsearch](../integration/advanced_search/elasticsearch.md#enable-advanced-search). Définissez la limite à `0` pour la désactiver.

## Limites de rendu des formules mathématiques {#math-rendering-limits}

{{< history >}}

- [Introduite](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/132939) dans GitLab 16.5.
- Limite de 50 nœuds [supprimée](https://gitlab.com/gitlab-org/gitlab/-/issues/368009) des fichiers Wiki et des dépôts.
- [Ajout](https://gitlab.com/gitlab-org/gitlab/-/issues/368009) d'un paramètre au niveau du groupe pour permettre de désactiver les limites de rendu des formules mathématiques, et réactivation par défaut des limites mathématiques pour les fichiers wiki et les fichiers de dépôt dans GitLab 16.9.

{{< /history >}}

GitLab impose des limites par défaut lors du rendu des formules mathématiques dans les champs Markdown. Ces limites offrent une meilleure sécurité et de meilleures performances.

Les limites pour les tickets, les merge requests, les epics, les wikis et les fichiers de dépôt :

- Nombre maximal d'expansions de macros : `1000`.
- Taille maximale spécifiée par l'utilisateur en [em](https://en.wikipedia.org/wiki/Em_(typography)) : `20`.
- Nombre maximal de nœuds rendus : `50`.
- Nombre maximal de caractères dans un bloc mathématique : `1000`.
- Temps de rendu maximal : `2000 ms`.

Vous pouvez désactiver ces limites lorsque vous exécutez GitLab Self-Managed et que vous faites confiance aux entrées utilisateur.

Utilisez la [console Rails GitLab](operations/rails_console.md#starting-a-rails-console-session) :

```ruby
ApplicationSetting.update(math_rendering_limits_enabled: false)
```

Ces limites peuvent également être désactivées par groupe en utilisant l'API GraphQL ou REST.

Si les limites sont désactivées, les formules mathématiques sont rendues sans pratiquement aucune limite dans les tickets, les merge requests, les epics, les wikis et les fichiers de dépôt. Cela signifie qu'un acteur malveillant pourrait ajouter des formules mathématiques qui provoqueraient un DoS lors de la consultation dans le navigateur. Vous devez vous assurer que seules les personnes en qui vous avez confiance peuvent ajouter du contenu.

## Limites du Wiki {#wiki-limits}

- [Limite de taille du contenu des pages wiki](wikis/_index.md#wiki-page-content-size-limit).
- [Restrictions de longueur pour les noms de fichiers et de répertoires](../user/project/wiki/_index.md#length-restrictions-for-file-and-directory-names).

## Limites des extraits de code {#snippets-limits}

Consultez la [documentation sur les paramètres des extraits de code](snippets/_index.md).

## Limites de la gestion des conceptions {#design-management-limits}

Consultez les limites dans la section [Ajouter une conception à un ticket](../user/project/issues/design_management.md#add-a-design-to-an-issue).

## Limites des événements push {#push-event-limits}

### Taille maximale de push {#max-push-size}

La [taille de push](settings/account_and_limit_settings.md#max-push-size) maximale autorisée.

Non définie par défaut sur GitLab Self-Managed. Pour GitLab.com, consultez les [paramètres de compte et de limite](../user/gitlab_com/_index.md#account-and-limit-settings)

### Webhooks et services de projet {#webhooks-and-project-services}

Nombre total de modifications (branches ou tags) dans un seul push. Si les modifications sont supérieures à la limite spécifiée, les hooks ne sont pas exécutés.

Pour plus d'informations, voir :

- [Événements push de webhook](../user/project/integrations/webhook_events.md#push-events)
- [Limite de hook push pour les intégrations de projet](../user/project/integrations/_index.md#push-hook-limit)

### Activités {#activities}

Nombre total de modifications (branches ou tags) dans un seul push pour déterminer si des événements push individuels ou un événement push groupé sont créés.

Plus d'informations sont disponibles dans la [documentation sur la limite d'activités d'événements push et les événements push groupés](settings/push_event_activities_limit.md).

## Limites du registre de paquets {#package-registry-limits}

### Limites de taille de fichier {#file-size-limits}

La taille de fichier maximale par défaut pour un paquet téléversé dans le [registre de paquets GitLab](../user/packages/package_registry/_index.md) varie selon le format :

- Conan :  3 Go
- Generic :  5 Go
- Helm :  5 MB
- Maven :  3 Go
- npm :  500 Mo
- NuGet :  500 Mo
- PyPI :  3 Go
- Terraform :  1 Go

Les [tailles de fichiers maximales sur GitLab.com](../user/gitlab_com/_index.md#package-registry-limits) peuvent être différentes.

Pour définir ces limites pour une instance GitLab Self-Managed, vous pouvez le faire [via la zone **Admin**](settings/continuous_integration.md#set-package-file-size-limits) ou exécuter la commande suivante dans la [console Rails GitLab](operations/rails_console.md#starting-a-rails-console-session) :

```ruby
# File size limit is stored in bytes

# For Conan Packages
Plan.default.actual_limits.update!(conan_max_file_size: 100.megabytes)

# For npm Packages
Plan.default.actual_limits.update!(npm_max_file_size: 100.megabytes)

# For NuGet Packages
Plan.default.actual_limits.update!(nuget_max_file_size: 100.megabytes)

# For Maven Packages
Plan.default.actual_limits.update!(maven_max_file_size: 100.megabytes)

# For PyPI Packages
Plan.default.actual_limits.update!(pypi_max_file_size: 100.megabytes)

# For Debian Packages
Plan.default.actual_limits.update!(debian_max_file_size: 100.megabytes)

# For Helm Charts
Plan.default.actual_limits.update!(helm_max_file_size: 100.megabytes)

# For Generic Packages
Plan.default.actual_limits.update!(generic_packages_max_file_size: 100.megabytes)
```

Définissez la limite à `0` pour autoriser toute taille de fichier.

### Versions de paquets retournées {#package-versions-returned}

Lors d'une demande de versions d'un nom de paquet NuGet donné, le registre de paquets GitLab retourne un maximum de 300 versions.

## Limites du proxy de dépendances {#dependency-proxy-limits}

La taille maximale de fichier pour une image mise en cache dans le [proxy de dépendances](../user/packages/dependency_proxy/_index.md) varie selon le type de fichier :

- Blob d'image :  5 Go
- Manifeste d'image :  10 Mo

## Nombre maximal d'assignés et de relecteurs {#maximum-number-of-assignees-and-reviewers}

{{< history >}}

- Nombre maximal d'assignés [introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/368936) dans GitLab 15.6.
- Nombre maximal de relecteurs [introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/366485) dans GitLab 15.9.

{{< /history >}}

Les tickets et les merge requests appliquent ces maximums :

- Nombre maximal d'assignés :  200
- Nombre maximal de relecteurs :  200

## Nombre maximal de miroirs push de projet {#maximum-number-of-project-push-mirrors}

{{< history >}}

- [Introduite](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/221965) dans GitLab 18.9.

{{< /history >}}

Chaque projet peut avoir un maximum de 10 miroirs push activés. Cette limite prévient les problèmes de performance liés à un trop grand nombre de tâches de synchronisation simultanées.

Si vous avez besoin de plus de miroirs, vous pouvez :

- Désactiver les miroirs inutilisés.
- Consolider les miroirs en combinant plusieurs destinations en un seul miroir.

## Limites basées sur le CDN sur GitLab.com {#cdn-based-limits-on-gitlabcom}

En plus des limites basées sur l'application, GitLab.com est configuré pour utiliser la protection DDoS standard de Cloudflare et Spectrum pour protéger Git via SSH. Cloudflare met fin aux connexions TLS client mais n'est pas compatible avec les applications et ne peut pas être utilisé pour des limites liées aux utilisateurs ou aux groupes. Les règles de page et les limites de débit Cloudflare sont configurées avec Terraform. Ces configurations ne sont pas publiques car elles incluent des implémentations de sécurité et de lutte contre les abus qui détectent les activités malveillantes, et les rendre publiques compromettrait ces opérations.

## Limite de suppression de tags du dépôt de conteneurs {#container-repository-tag-deletion-limit}

Les tags du dépôt de conteneurs se trouvent dans le registre de conteneurs, de sorte que chaque suppression de tag déclenche des requêtes réseau vers le registre de conteneurs. Pour cette raison, nous limitons le nombre de tags qu'un seul appel API peut supprimer à 20.

## Limites de l'API des fichiers sécurisés au niveau du projet {#project-level-secure-files-api-limits}

L'[API des fichiers sécurisés](../api/secure_files.md) applique les limites suivantes :

- Les fichiers doivent être inférieurs à 5 Mo.
- Les projets ne peuvent pas avoir plus de 100 fichiers sécurisés.

## Limites de l'API Changelog {#changelog-api-limits}

{{< history >}}

- [Introduite](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/89032) dans GitLab 15.1 [avec un flag](feature_flags/_index.md) nommé `changelog_commits_limitation`. Désactivé par défaut.
- [Activée sur GitLab.com et par défaut sur GitLab Self-Managed](https://gitlab.com/gitlab-org/gitlab/-/issues/33893) dans GitLab 15.3.
- [Disponibilité générale](https://gitlab.com/gitlab-org/gitlab/-/issues/364101) dans GitLab 17.3. Le feature flag `changelog_commits_limitation` a été supprimé.

{{< /history >}}

L'[API changelog](../api/repositories.md#add-changelog-data-to-file) applique les limites suivantes :

- La plage de commits entre `from` et `to` ne peut pas dépasser 15 000 commits.

## Limites de Value Stream Analytics {#value-stream-analytics-limits}

- Chaque espace de nommage (tel qu'un groupe ou un projet) peut avoir un maximum de 50 flux de valeur.
- Chaque flux de valeur peut avoir un maximum de 15 étapes.

## Limites des destinations de diffusion d'événements d'audit {#audit-events-streaming-destination-limits}

### Point de terminaison HTTP personnalisé {#custom-http-endpoint}

- Chaque groupe principal peut avoir un maximum de 5 destinations de diffusion HTTP personnalisées.

### Google Cloud Logging {#google-cloud-logging}

- Chaque groupe principal peut avoir un maximum de 5 destinations de diffusion Google Cloud Logging.

### Amazon S3 {#amazon-s3}

- Chaque groupe principal peut avoir un maximum de 5 destinations de diffusion Amazon S3.

## Limites de l'analyse des dépendances avec SBOM {#dependency-scanning-using-sbom-limits}

La [fonctionnalité d'analyse des dépendances avec SBOM](../user/application_security/dependency_scanning/dependency_scanning_sbom/_index.md) utilise une API interne avec les limites suivantes :

- Nombre maximal de requêtes de téléversement par projet et par heure :  400
- Nombre maximal de requêtes de téléchargement par projet et par heure :  6000

Vous pouvez configurer ces limites pour les instances GitLab Self-Managed en utilisant les [paramètres d'analyse des dépendances](settings/security_and_compliance.md#sbom-scan-api-limits).

## Limites de l'API Commits et Files {#commits-and-files-api-limits}

{{< history >}}

- Introduite dans GitLab 18.7.

{{< /history >}}

Les API Commits et Files appliquent des limites maximales de taille et de débit sur les points de terminaison suivants :

- `POST /projects/:id/repository/commits` - [Créer un commit](../api/commits.md#create-a-commit)
- `POST /projects/:id/repository/files/:file_path` - [Créer un fichier dans un dépôt](../api/repository_files.md#create-a-file-in-a-repository)
- `PUT /projects/:id/repository/files/:file_path` - [Mettre à jour un fichier dans un dépôt](../api/repository_files.md#update-a-file-in-a-repository)
- **Maximum request size** :  Les requêtes dépassant cette limite reçoivent une erreur `413 Request Entity Too Large` avec le message suivant : `RequestBody: upload failed: the upload size <size> is over maximum of 314572800 bytes: entity is too large`. La valeur par défaut est 300 Mo (314 572 800 octets).
- **Limite de fréquence** :  3 requêtes par 30 secondes pour les requêtes supérieures à 20 Mo.

La taille maximale de la requête est configurable sur GitLab Self-Managed en définissant la variable d'environnement `GITLAB_COMMITS_MAX_REQUEST_SIZE_BYTES`. Cette variable définit la taille maximale de la requête en octets. Les instructions pour définir une variable d'environnement se trouvent dans [Limites des requêtes HTTP](#http-request-limits).

## Répertorier toutes les limites de l'instance {#list-all-instance-limits}

Pour répertorier toutes les valeurs de limite de l'instance, exécutez la commande suivante depuis la [console Rails GitLab](operations/rails_console.md#starting-a-rails-console-session) :

```ruby
Plan.default.actual_limits
```

Exemple de sortie :

```ruby
id: 1,
plan_id: 1,
ci_pipeline_size: 0,
ci_active_jobs: 0,
project_hooks: 100,
group_hooks: 50,
ci_project_subscriptions: 3,
ci_pipeline_schedules: 10,
offset_pagination_limit: 50000,
ci_instance_level_variables: "[FILTERED]",
storage_size_limit: 0,
ci_max_artifact_size_lsif: 200,
ci_max_artifact_size_archive: 0,
ci_max_artifact_size_metadata: 0,
ci_max_artifact_size_trace: "[FILTERED]",
ci_max_artifact_size_junit: 0,
ci_max_artifact_size_sast: 0,
ci_max_artifact_size_dependency_scanning: 350,
ci_max_artifact_size_container_scanning: 150,
ci_max_artifact_size_dast: 0,
ci_max_artifact_size_codequality: 0,
ci_max_artifact_size_license_management: 0,
ci_max_artifact_size_license_scanning: 100,
ci_max_artifact_size_performance: 0,
ci_max_artifact_size_metrics: 0,
ci_max_artifact_size_metrics_referee: 0,
ci_max_artifact_size_network_referee: 0,
ci_max_artifact_size_dotenv: 0,
ci_max_artifact_size_cobertura: 0,
ci_max_artifact_size_terraform: 5,
ci_max_artifact_size_accessibility: 0,
ci_max_artifact_size_cluster_applications: 0,
ci_max_artifact_size_secret_detection: "[FILTERED]",
ci_max_artifact_size_requirements: 0,
ci_max_artifact_size_coverage_fuzzing: 0,
ci_max_artifact_size_browser_performance: 0,
ci_max_artifact_size_load_performance: 0,
ci_needs_size_limit: 2,
conan_max_file_size: 3221225472,
maven_max_file_size: 3221225472,
npm_max_file_size: 524288000,
nuget_max_file_size: 524288000,
pypi_max_file_size: 3221225472,
generic_packages_max_file_size: 5368709120,
golang_max_file_size: 104857600,
debian_max_file_size: 3221225472,
project_feature_flags: 200,
ci_max_artifact_size_api_fuzzing: 0,
ci_pipeline_deployments: 500,
pull_mirror_interval_seconds: 300,
daily_invites: 0,
rubygems_max_file_size: 3221225472,
terraform_module_max_file_size: 1073741824,
helm_max_file_size: 5242880,
ci_registered_group_runners: 1000,
ci_registered_project_runners: 1000,
ci_daily_pipeline_schedule_triggers: 0,
ci_max_artifact_size_cluster_image_scanning: 0,
ci_jobs_trace_size_limit: "[FILTERED]",
pages_file_entries: 200000,
dast_profile_schedules: 1,
external_audit_event_destinations: 5,
dotenv_variables: "[FILTERED]",
dotenv_size: 5120,
pipeline_triggers: 25000,
project_ci_secure_files: 100,
repository_size: 0,
security_policy_scan_execution_schedules: 0,
web_hook_calls_mid: 0,
web_hook_calls_low: 0,
project_ci_variables: "[FILTERED]",
group_ci_variables: "[FILTERED]",
ci_max_artifact_size_cyclonedx: 1,
rpm_max_file_size: 5368709120,
pipeline_hierarchy_size: 1000,
ci_max_artifact_size_requirements_v2: 0,
enforcement_limit: 0,
notification_limit: 0,
dashboard_limit_enabled_at: nil,
web_hook_calls: 0,
project_access_token_limit: 0,
google_cloud_logging_configurations: 5,
ml_model_max_file_size: 10737418240,
limits_history: {},
audit_events_amazon_s3_configurations: 5
```

Certaines valeurs de limite s'affichent sous la forme `[FILTERED]` dans la liste en raison du [filtrage dans la console Rails](operations/rails_console.md#filtered-console-output).
