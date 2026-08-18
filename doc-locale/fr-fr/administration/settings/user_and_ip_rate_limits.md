---
stage: Production Engineering
group: Networking and Incident Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Limitations de fréquence des IP et Utilisateurs
---

{{< details >}}

- Niveau :  Free, Premium, Ultimate
- Offre :  GitLab Self-Managed

{{< /details >}}

La limitation de débit est une technique courante utilisée pour améliorer la sécurité et la durabilité d'une application web. Pour plus de détails, voir [Limites de débit](../../security/rate_limits.md).

Les limites suivantes sont désactivées par défaut :

- [Requêtes d'API non authentifiées (par IP)](#enable-unauthenticated-api-request-rate-limit).
- [Requêtes web non authentifiées (par IP)](#enable-unauthenticated-web-request-rate-limit).
- [Requêtes d'API authentifiées (par utilisateur)](#enable-authenticated-api-request-rate-limit).
- [Requêtes web authentifiées (par utilisateur)](#enable-authenticated-web-request-rate-limit).

> [!note]
> Par défaut, toutes les opérations Git sont d'abord tentées sans authentification. Pour cette raison, les opérations Git HTTP peuvent déclencher les limites de débit configurées pour les requêtes non authentifiées.

Les limites de débit pour les requêtes d'API n'affectent pas les requêtes effectuées par le frontend, car celles-ci sont toujours comptabilisées comme du trafic web.

## Prérequis {#prerequisites}

Vous devez disposer d'un accès administrateur.

## Activer la limite de fréquence des requêtes d'API non authentifiées {#enable-unauthenticated-api-request-rate-limit}

Pour activer la limite de débit des requêtes d'API non authentifiées :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Réseau**.
1. Développez **Limitations de fréquence des IP et Utilisateurs**.
1. Sélectionnez **Activer la limite de fréquence des requêtes d'API non authentifiées**.

   - Facultatif. Mettez à jour la valeur **Nombre maximum de requêtes d'API non authentifiées par période de la limite de fréquence et par IP**. La valeur par défaut est `3600`.
   - Facultatif. Mettez à jour la valeur **Unauthenticated rate limit period in seconds**. La valeur par défaut est `3600`.

## Activer la limite de fréquence des requêtes web non authentifiées {#enable-unauthenticated-web-request-rate-limit}

Pour activer la limite de débit des requêtes non authentifiées :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Réseau**.
1. Développez **Limitations de fréquence des IP et Utilisateurs**.
1. Sélectionnez **Activer la limite de fréquence des requêtes web non authentifiées**.

   - Facultatif. Mettez à jour la valeur **Nombre maximum de requêtes Web non authentifiées par période de la limite de fréquence et par IP**. La valeur par défaut est `3600`.
   - Facultatif. Mettez à jour la valeur **Unauthenticated rate limit period in seconds**. La valeur par défaut est `3600`.

## Activer la limite de fréquence des requêtes d'API authentifiées {#enable-authenticated-api-request-rate-limit}

Pour activer la limite de débit des requêtes d'API authentifiées :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Réseau**.
1. Développez **Limitations de fréquence des IP et Utilisateurs**.
1. Sélectionnez **Activer la limite de fréquence des requêtes d'API authentifiées**.

   - Facultatif. Mettez à jour la valeur **Nombre maximum de requêtes d'API authentifiées par période de limite de fréquence et par utilisateur**. La valeur par défaut est `7200`.
   - Facultatif. Mettez à jour la valeur **Limitation de fréquence des requêtes d'API authentifiées en secondes**. La valeur par défaut est `3600`.

## Activer la limite de fréquence des requêtes Web authentifiées {#enable-authenticated-web-request-rate-limit}

Pour activer la limite de débit des requêtes authentifiées :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Réseau**.
1. Développez **Limitations de fréquence des IP et Utilisateurs**.
1. Sélectionnez **Activer la limite de fréquence des requêtes Web authentifiées**.

   - Facultatif. Mettez à jour la valeur **Nombre maximum de requêtes Web authentifiées par période de limite de fréquence et par utilisateur**. La valeur par défaut est `7200`.
   - Facultatif. Mettez à jour la valeur **Limitation de fréquence des requêtes Web authentifiées en secondes**. La valeur par défaut est `3600`.

## Utiliser une réponse personnalisée à la limite de débit {#use-a-custom-rate-limit-response}

Une requête qui dépasse une limite de débit retourne un code de réponse `429` et un corps en texte brut, qui par défaut est `Retry later`.

Pour utiliser une réponse personnalisée :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Réseau**.
1. Développez **Limitations de fréquence des IP et Utilisateurs**.
1. Dans la zone de texte **Réponse en texte brut à envoyer aux clients qui atteignent une limitation de fréquence**, ajoutez le message de réponse en texte brut.

## Nombre maximum de requêtes authentifiées vers `project/:id/jobs` par minute {#maximum-authenticated-requests-to-projectidjobs-per-minute}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/129319) dans GitLab 16.5.

{{< /history >}}

Pour réduire les délais d'expiration, le point de terminaison `project/:id/jobs` dispose d'une [limite de débit](../../security/rate_limits.md#project-jobs-api-endpoint) par défaut de 600 appels par utilisateur authentifié.

Pour modifier le nombre maximum de requêtes :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Réseau**.
1. Développez **Limitations de fréquence des IP et Utilisateurs**.
1. Mettez à jour la valeur **Maximum authenticated requests to `project/:id/jobs` per minute**.

## En-têtes de réponse {#response-headers}

Les en-têtes de réponse incluent des informations sur la limite de débit pour toutes les requêtes. Utilisez ces en-têtes pour surveiller de manière proactive l'utilisation et ajuster les modèles de requêtes afin d'éviter la limitation.

### Systèmes de limitation de débit multiples {#multiple-rate-limiting-systems}

Les limites de débit sont appliquées via deux systèmes indépendants :

- Limites de débit du middleware `Rack::Attack` :  Appliquées au niveau de la couche HTTP. Parmi les exemples, on trouve les requêtes d'API authentifiées par utilisateur, ou les requêtes web non authentifiées par IP. Ces limites sont reflétées dans les en-têtes de réponse.
- Limites de débit de l'application :  Appliquées au niveau de l'application. Parmi les exemples, on trouve la création de tickets par utilisateur, ou l'export de projet par utilisateur. Ces limites ne sont pas incluses dans les en-têtes de réponse.

Une seule requête peut être comptabilisée simultanément dans les deux types de limites de débit. Les en-têtes de réponse n'affichent que le statut de limite de débit `Rack::Attack` le plus restrictif.

> [!note]
> Les limites de débit de l'application ne sont pas incluses dans les en-têtes de réponse.

#### Exemple {#example}

Une requête pour créer un ticket via l'API est comptabilisée dans :

- La limite de débit des requêtes d'API authentifiées (`Rack::Attack`). Incluse dans les en-têtes de réponse.
- La limite de débit de création de tickets (au niveau de l'application). Non incluse dans les en-têtes de réponse.

Le dépassement de la limite de débit de création de tickets entraîne une réponse `429`, même lorsque les en-têtes de réponse précédents indiquaient suffisamment de requêtes d'API authentifiées restantes.

### En-têtes retournés pour toutes les requêtes {#headers-returned-for-all-requests}

Les en-têtes suivants sont inclus dans toutes les réponses pour aider les clients à suivre l'état de leur limite de débit :

| En-tête                | Exemple                      | Description                                                                                                                                                                                                      |
|:----------------------|:-----------------------------|:------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `RateLimit-Limit`     | `60`                         | Le quota de requêtes du client par minute. Si la période de limite de débit définie dans la zone **Admin** est différente de 1 minute, la valeur de cet en-tête est ajustée à environ la période de 60 minutes la plus proche. |
| `RateLimit-Name`      | `throttle_authenticated_api` | Nom du régulateur appliqué à la requête.                                                                                                                                                                     |
| `RateLimit-Observed`  | `67`                         | Nombre de requêtes associées au client dans la fenêtre temporelle.                                                                                                                                                  |
| `RateLimit-Remaining` | `33`                         | Quota restant dans la fenêtre temporelle. Le résultat de `RateLimit-Limit` - `RateLimit-Observed`.                                                                                                                     |
| `RateLimit-Reset`     | `1609844400`                 | Heure au format [Unix time](https://en.wikipedia.org/wiki/Unix_time) à laquelle le quota de requêtes est réinitialisé.                                                                                                             |

### En-têtes supplémentaires pour les requêtes limitées {#additional-headers-for-throttled-requests}

Lorsqu'un client dépasse la limite de débit (statut HTTP `429`), les en-têtes supplémentaires suivants sont inclus :

| En-tête                | Exemple                         | Description                                                                                                                                                   |
|:----------------------|:--------------------------------|:--------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `RateLimit-ResetTime` | `Tue, 05 Jan 2021 11:00:00 GMT` | Date et heure au format [RFC2616](https://www.rfc-editor.org/rfc/rfc2616#section-3.3.1) à laquelle le quota de requêtes est réinitialisé.                                     |
| `Retry-After`         | `30`                            | Durée restante en secondes jusqu'à la réinitialisation du quota. Il s'agit d'un [en-tête HTTP standard](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Retry-After). |

## Utiliser un en-tête HTTP pour contourner la limitation de débit {#use-an-http-header-to-bypass-rate-limiting}

Selon les besoins de votre organisation, vous pouvez souhaiter activer la limitation de débit tout en permettant à certaines requêtes de contourner le limiteur de débit.

Vous pouvez faire cela en marquant les requêtes qui doivent contourner le limiteur de débit avec un en-tête personnalisé. Vous devez effectuer cette opération dans un équilibreur de charge ou un proxy inverse devant GitLab. Par exemple :

1. Choisissez un nom pour votre en-tête de contournement. Par exemple, `Gitlab-Bypass-Rate-Limiting`.
1. Configurez votre équilibreur de charge pour définir `Gitlab-Bypass-Rate-Limiting: 1` sur les requêtes qui doivent contourner la limitation de débit de GitLab.
1. Configurez votre équilibreur de charge pour :
   - Supprimer `Gitlab-Bypass-Rate-Limiting`.
   - Définir `Gitlab-Bypass-Rate-Limiting` sur une valeur autre que `1` pour toutes les requêtes qui doivent être soumises à la limitation de débit.
1. Définissez la variable d'environnement `GITLAB_THROTTLE_BYPASS_HEADER`.
   - Pour les [installations avec le package Linux](https://docs.gitlab.com/omnibus/settings/environment-variables/), définissez `'GITLAB_THROTTLE_BYPASS_HEADER' => 'Gitlab-Bypass-Rate-Limiting'` dans `gitlab_rails['env']`.
   - Pour les installations auto-compilées, définissez `export GITLAB_THROTTLE_BYPASS_HEADER=Gitlab-Bypass-Rate-Limiting` dans `/etc/default/gitlab`.

Il est important que votre équilibreur de charge supprime ou écrase l'en-tête de contournement sur tout le trafic entrant. Sinon, vous devez faire confiance à vos utilisateurs pour ne pas définir cet en-tête et contourner le limiteur de débit de GitLab.

Le contournement ne fonctionne que si l'en-tête est défini sur `1`.

Les requêtes qui ont contourné le limiteur de débit en raison de l'en-tête de contournement sont marquées avec `"throttle_safelist":"throttle_bypass_header"` dans [`production_json.log`](../logs/_index.md#production_jsonlog).

Pour désactiver le mécanisme de contournement, assurez-vous que la variable d'environnement `GITLAB_THROTTLE_BYPASS_HEADER` est non définie ou vide.

## Autoriser des utilisateurs spécifiques à contourner la limitation de débit des requêtes authentifiées {#allow-specific-users-to-bypass-authenticated-request-rate-limiting}

De manière similaire à l'en-tête de contournement décrit précédemment, il est possible d'autoriser un certain ensemble d'utilisateurs à contourner le limiteur de débit. Cela s'applique uniquement aux requêtes authentifiées : pour les requêtes non authentifiées, GitLab ne sait pas par définition qui est l'utilisateur.

La liste d'autorisation est configurée sous la forme d'une liste d'identifiants d'utilisateurs séparés par des virgules dans la variable d'environnement `GITLAB_THROTTLE_USER_ALLOWLIST`. Si vous souhaitez que les utilisateurs 1, 53 et 217 contournent le limiteur de débit des requêtes authentifiées, la configuration de la liste d'autorisation serait `1,53,217`.

- Pour les [installations avec le package Linux](https://docs.gitlab.com/omnibus/settings/environment-variables/), définissez `'GITLAB_THROTTLE_USER_ALLOWLIST' => '1,53,217'` dans `gitlab_rails['env']`.
- Pour les installations auto-compilées, définissez `export GITLAB_THROTTLE_USER_ALLOWLIST=1,53,217` dans `/etc/default/gitlab`.

Les requêtes qui ont contourné le limiteur de débit en raison de la liste d'autorisation des utilisateurs sont marquées avec `"throttle_safelist":"throttle_user_allowlist"` dans [`production_json.log`](../logs/_index.md#production_jsonlog).

Au démarrage de l'application, la liste d'autorisation est consignée dans [`auth.log`](../logs/_index.md#authlog).

## Tester les paramètres de régulation avant de les appliquer {#try-out-throttling-settings-before-enforcing-them}

Vous pouvez tester les paramètres de régulation en définissant la variable d'environnement `GITLAB_THROTTLE_DRY_RUN` sur une liste de noms de régulateurs séparés par des virgules.

Les noms possibles sont :

- `throttle_unauthenticated`
  - [Obsolète](https://gitlab.com/gitlab-org/gitlab/-/issues/335300) dans GitLab 14.3. Utilisez `throttle_unauthenticated_api` ou `throttle_unauthenticated_web` à la place. `throttle_unauthenticated` est toujours pris en charge et sélectionne les deux.
- `throttle_unauthenticated_api`
- `throttle_unauthenticated_web`
- `throttle_authenticated_api`
- `throttle_authenticated_web`
- `throttle_unauthenticated_protected_paths`
- `throttle_authenticated_protected_paths_api`
- `throttle_authenticated_protected_paths_web`
- `throttle_unauthenticated_packages_api`
- `throttle_authenticated_packages_api`
- `throttle_authenticated_git_lfs`
- `throttle_unauthenticated_files_api`
- `throttle_authenticated_files_api`
- `throttle_unauthenticated_deprecated_api`
- `throttle_authenticated_deprecated_api`
- `throttle_unauthenticated_git_http`
- `throttle_authenticated_git_http`

Par exemple, pour tester les régulateurs pour toutes les requêtes authentifiées vers des chemins non protégés, vous pouvez définir `GITLAB_THROTTLE_DRY_RUN='throttle_authenticated_web,throttle_authenticated_api'`.

Pour activer le mode simulation pour tous les régulateurs, la variable peut être définie sur `*`.

La définition d'un régulateur en mode simulation consigne un message dans [`auth.log`](../logs/_index.md#authlog) lorsqu'il atteindrait la limite, tout en laissant la requête continuer. Le message du journal contient un champ `env` défini sur `track`. Le champ `matched` contient le nom du régulateur qui a été atteint.

Il est important de définir la variable d'environnement avant d'activer la limitation de débit dans les paramètres. Les paramètres de la zone **Admin** prennent effet immédiatement, tandis que la définition de la variable d'environnement nécessite un redémarrage de tous les processus Puma.

## Dépannage {#troubleshooting}

### Désactiver la régulation après avoir accidentellement verrouillé les administrateurs {#disable-throttling-after-accidentally-locking-administrators-out}

Si de nombreux utilisateurs se connectent à GitLab via le même proxy ou la même passerelle réseau, il est possible que, si une limite de débit est trop basse, cette limite verrouille également les administrateurs, car GitLab les voit utiliser la même IP que les requêtes qui ont déclenché la régulation.

Les administrateurs peuvent utiliser [la console Rails](../operations/rails_console.md) pour désactiver les mêmes limites que celles répertoriées pour [la variable `GITLAB_THROTTLE_DRY_RUN`](#try-out-throttling-settings-before-enforcing-them). Par exemple :

```ruby
Gitlab::CurrentSettings.update!(throttle_authenticated_web_enabled: false)
```

Dans cet exemple, le paramètre `throttle_authenticated_web` a le suffixe de nom `_enabled`.

Pour définir des valeurs numériques pour les limites, remplacez le suffixe de nom `_enabled` par les suffixes `_period_in_seconds` et `_requests_per_period`.
