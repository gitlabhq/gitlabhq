---
stage: Analytics
group: Platform Insights
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "Utilisez des webhooks pour recevoir des alertes de sources externes, mapper les champs d'alerte, déclencher des alertes de test et intégrer des outils tels que Prometheus et Opsgenie."
title: Intégrations
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

GitLab peut accepter des alertes de n'importe quelle source via un récepteur de webhook. [Les notifications d'alerte](alerts.md) peuvent [déclencher des appels](paging.md#paging) pour les rotations d'astreinte ou être utilisées pour [créer des incidents](manage_incidents.md#from-an-alert).

## Liste des intégrations {#integrations-list}

Avec le rôle Maintainer ou Owner, vous pouvez consulter la liste des intégrations d'alertes configurées en accédant à **Paramètres** > **Supervision** dans le menu latéral de votre projet, et en développant la section **Alertes**. La liste affiche le nom, le type et le statut de l'intégration (activée ou désactivée) :

![Tableau affichant les détails des alertes configurées](img/integrations_list_v13_5.png)

## Configuration {#configuration}

GitLab peut recevoir des alertes via un point de terminaison HTTP que vous configurez.

### Point de terminaison d'alerte unique {#single-alerting-endpoint}

L'activation d'un point de terminaison d'alerte dans un projet GitLab lui permet de recevoir des charges utiles d'alerte au format JSON. Vous pouvez toujours [personnaliser la charge utile](#customize-the-alert-payload-outside-of-gitlab) selon vos besoins.

1. Connectez-vous à GitLab en tant qu'utilisateur disposant du rôle Maintainer pour un projet.
1. Accédez à **Paramètres** > **Supervision** dans votre projet.
1. Développez la section **Alertes** et, dans la liste déroulante **Sélectionnez le type d'intégration**, sélectionnez **Prometheus** pour les alertes Prometheus, ou **Point de terminaison HTTP** pour tout autre outil de supervision.
1. Activez le paramètre d'alerte **Actif**. L'URL et la clé d'autorisation pour la configuration du webhook sont disponibles dans l'onglet **Afficher les identifiants** après avoir enregistré l'intégration. Vous devez également saisir l'URL et la clé d'autorisation dans votre service externe.

### Points de terminaison d'alerte {#alerting-endpoints}

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Avec [GitLab Premium](https://about.gitlab.com/pricing/), vous pouvez créer plusieurs points de terminaison d'alerte uniques pour recevoir des alertes de n'importe quelle source externe au format JSON, et vous pouvez [personnaliser la charge utile](#customize-the-alert-payload-outside-of-gitlab).

1. Connectez-vous à GitLab en tant qu'utilisateur disposant du rôle Maintainer pour un projet.
1. Accédez à **Paramètres** > **Supervision** dans votre projet.
1. Développez la section **Alertes**.
1. Pour chaque point de terminaison que vous souhaitez créer :

   1. Sélectionnez **Ajouter une nouvelle intégration**.
   1. Dans la liste déroulante **Sélectionnez le type d'intégration**, sélectionnez **Prometheus** pour les alertes Prometheus, ou **Point de terminaison HTTP** pour tout autre outil de supervision. Voir les détails
   1. Nommez l'intégration.
   1. Activez le paramètre d'alerte **Actif**. L'**URL** et la **Authorization Key** pour la configuration du webhook sont disponibles dans l'onglet **Afficher les identifiants** après avoir enregistré l'intégration. Vous devez également saisir l'URL et la clé d'autorisation dans votre service externe.
   1. facultatif. Pour mapper les champs de l'alerte de votre outil de supervision avec les champs GitLab, saisissez un exemple de charge utile et sélectionnez **Parse payload for custom mapping**. Un JSON valide est requis. Si vous mettez à jour un exemple de charge utile, vous devez également remapper les champs. Pour les intégrations Prometheus, saisissez une seule alerte à partir de la clé `alerts` de la charge utile au lieu de la charge utile entière.

   1. facultatif. Si vous avez fourni un exemple de charge utile valide, sélectionnez chaque valeur dans **Clé d'alerte de la charge utile** pour [mapper vers une **Clé d'alerte GitLab**](#map-fields-in-custom-alerts).
   1. Pour enregistrer votre intégration, sélectionnez **Save Integration**. Si vous le souhaitez, vous pouvez envoyer une alerte de test depuis l'onglet **Envoyer une alerte de test** de votre intégration après la création de celle-ci.

Le nouveau point de terminaison HTTP s'affiche dans la [liste des intégrations](#integrations-list). Vous pouvez modifier l'intégration en sélectionnant l'icône des paramètres {{< icon name="settings" >}} sur le côté droit de la liste des intégrations.

#### Mapper les champs dans les alertes personnalisées {#map-fields-in-custom-alerts}

Vous pouvez intégrer le format d'alerte de votre outil de supervision avec les alertes GitLab. Pour afficher les informations correctes dans la [liste des alertes](alerts.md#alert-list) et la [page des détails de l'alerte](alerts.md#alert-details-page), mappez les champs de votre alerte avec les champs GitLab lorsque vous [créez un point de terminaison HTTP](#alerting-endpoints) :

![Liste de gestion des alertes](img/custom_alert_mapping_v13_11.png)

### Ajouter les identifiants d'intégration à Alertmanager (intégrations Prometheus uniquement) {#add-integration-credentials-to-alertmanager-prometheus-integrations-only}

Pour envoyer des notifications d'alerte Prometheus à GitLab, copiez l'URL et la clé d'autorisation depuis votre [intégration Prometheus](#single-alerting-endpoint) dans la section [`webhook_configs`](https://prometheus.io/docs/alerting/latest/configuration/#webhook_config) de la configuration Prometheus Alertmanager :

```yaml
receivers:
  - name: gitlab
    webhook_configs:
      - http_config:
          authorization:
            type: Bearer
            credentials: 1234567890abdcdefg
        send_resolved: true
        url: http://IP_ADDRESS:PORT/root/manual_prometheus/prometheus/alerts/notify.json
        # Rest of configuration omitted
        # ...
```

## Personnaliser la charge utile d'alerte en dehors de GitLab {#customize-the-alert-payload-outside-of-gitlab}

### Attributs de requête HTTP attendus {#expected-http-request-attributes}

Pour les points de terminaison HTTP sans [mappages personnalisés](#map-fields-in-custom-alerts), vous pouvez personnaliser la charge utile en envoyant les paramètres suivants. Tous les champs sont facultatifs. Si l'alerte entrante ne contient pas de valeur pour le champ `Title`, une valeur par défaut de `New: Alert` est appliquée.

| Propriété                  | Type            | Description |
| ------------------------- | --------------- | ----------- |
| `title`                   | Chaîne          | Le titre de l'alerte.|
| `description`             | Chaîne          | Un résumé général du problème. |
| `start_time`              | DateHeure        | L'heure de l'alerte. Si aucune valeur n'est fournie, l'heure actuelle est utilisée. |
| `end_time`                | DateHeure        | L'heure de résolution de l'alerte. Si cette valeur est fournie, l'alerte est résolue. |
| `service`                 | Chaîne          | Le service affecté. |
| `monitoring_tool`         | Chaîne          | Le nom de l'outil de supervision associé. |
| `hosts`                   | Chaîne ou tableau | Un ou plusieurs hôtes indiquant où cet incident s'est produit. |
| `severity`                | Chaîne          | La gravité de l'alerte. Non sensible à la casse. Peut être l'une des valeurs suivantes : `critical`, `high`, `medium`, `low`, `info`, `unknown`. La valeur par défaut est `critical` si la valeur est manquante ou absente de cette liste. |
| `fingerprint`             | Chaîne ou tableau | L'identifiant unique de l'alerte. Cet identifiant peut être utilisé pour regrouper les occurrences d'une même alerte. Lorsque la fonctionnalité `generic_alert_fingerprinting` est activée, l'empreinte est générée automatiquement à partir de la charge utile (en excluant les paramètres `start_time`, `end_time` et `hosts`). |
| `gitlab_environment_name` | Chaîne          | Le nom de l'[environnement](../../ci/environments/_index.md) GitLab associé. Requis pour [afficher les alertes sur un tableau de bord](../../user/operations_dashboard/_index.md#adding-a-project-to-the-dashboard). |

Vous pouvez également ajouter des champs personnalisés à la charge utile de l'alerte. Les valeurs des paramètres supplémentaires ne sont pas limitées aux types primitifs (tels que les chaînes ou les nombres), mais peuvent être un objet JSON imbriqué. Par exemple :

```json
{ "foo": { "bar": { "baz": 42 } } }
```

> [!note]
> Assurez-vous que vos requêtes sont inférieures aux [limites d'application de charge utile](../../administration/instance_limits.md#generic-alert-json-payloads).

#### Exemple de corps de requête {#example-request-body}

Exemple de charge utile :

```json
{
  "title": "Incident title",
  "description": "Short description of the incident",
  "start_time": "2019-09-12T06:00:55Z",
  "service": "service affected",
  "monitoring_tool": "value",
  "hosts": "value",
  "severity": "high",
  "fingerprint": "d19381d4e8ebca87b55cda6e8eee7385",
  "foo": {
    "bar": {
      "baz": 42
    }
  }
}
```

### Attributs de requête Prometheus attendus {#expected-prometheus-request-attributes}

Les alertes doivent être formatées pour un [récepteur de webhook](https://prometheus.io/docs/alerting/latest/configuration/#webhook_config) Prometheus.

Attributs requis de premier niveau :

- `alerts`
- `commonAnnotations`
- `commonLabels`
- `externalURL`
- `groupKey`
- `groupLabels`
- `receiver`
- `status`
- `version`

À partir de `alerts` dans la charge utile Prometheus, une alerte GitLab est créée pour chaque élément du tableau. Vous pouvez modifier les paramètres imbriqués listés ci-dessous pour configurer l'alerte GitLab.

| Attribut                                                                  | Type     | Obligatoire | Description                          |
| -------------------------------------------------------------------------- | -------- | -------- | ------------------------------------ |
| L'un des attributs suivants : `annotations/title`, `annotations/summary` ou `labels/alertname`   | Chaîne   | Oui      | Le titre de l'alerte.              |
| `startsAt`                                                                 | DateHeure | Oui      | L'heure de début de l'alerte.         |
| `annotations/description`                                                  | Chaîne   | Non       | Un résumé général du problème. |
| `annotations/gitlab_incident_markdown`                                     | Chaîne   | Non       | [GitLab Flavored Markdown](../../user/markdown.md) à ajouter à tout incident créé à partir de l'alerte. |
| `annotations/runbook`                                                      | Chaîne   | Non       | Lien vers la documentation ou les instructions pour gérer cette alerte. |
| `endsAt`                                                                   | DateHeure | Non       | L'heure de résolution de l'alerte.    |
| Paramètre de requête `g0.expr` dans `generatorUrl`                                | Chaîne   | Non       | Requête de la métrique associée.          |
| `labels/gitlab_environment_name`                                           | Chaîne   | Non       | Le nom de l'[environnement](../../ci/environments/_index.md) GitLab associé. Requis pour [afficher les alertes sur un tableau de bord](../../user/operations_dashboard/_index.md#adding-a-project-to-the-dashboard). |
| `labels/severity`                                                          | Chaîne   | Non       | La gravité de l'alerte. Doit correspondre à l'une des [options de gravité Prometheus](#prometheus-severity-options). La valeur par défaut est `critical` si la valeur est manquante ou absente de cette liste. |
| `status`                                                                   | Chaîne   | Non       | Statut de l'alerte dans Prometheus. Si la valeur est « resolved », l'alerte est résolue. |
| L'un des attributs suivants : `annotations/gitlab_y_label`, `annotations/title`, `annotations/summary` ou `labels/alertname` | Chaîne | Non | Le label de l'axe Y à utiliser lors de l'intégration des métriques de cette alerte dans [GitLab Flavored Markdown](../../user/markdown.md). |

Les attributs supplémentaires inclus dans `annotations` sont disponibles sur la [page des détails de l'alerte](alerts.md#alert-details-page). Tous les autres attributs sont ignorés.

Les attributs ne sont pas limités aux types primitifs (tels que les chaînes ou les nombres), mais peuvent être un objet JSON imbriqué. Par exemple :

```json
{
    "target": {
        "user": {
            "id": 42
        }
    }
}
```

> [!note]
> Assurez-vous que vos requêtes sont inférieures aux [limites d'application de charge utile](../../administration/instance_limits.md#generic-alert-json-payloads).

#### Options de gravité Prometheus {#prometheus-severity-options}

Les alertes Prometheus peuvent fournir l'une des valeurs suivantes (non sensibles à la casse) pour la [gravité d'alerte](alerts.md#alert-severity) :

- **Critique** : `critical`, `s1`, `p1`, `emergency`, `fatal`
- **Niveau élevé** : `high`, `s2`, `p2`, `major`, `page`
- **Niveau moyen** : `medium`, `s3`, `p3`, `error`, `alert`
- **Niveau faible** : `low`, `s4`, `p4`, `warn`, `warning`
- **Infos** : `info`, `s5`, `p5`, `debug`, `information`, `notice`

La gravité est définie par défaut sur `critical` si la valeur est manquante ou absente de cette liste.

#### Exemple d'alerte Prometheus {#example-prometheus-alert}

Exemple de règle d'alerte :

```yaml
groups:
- name: example
  rules:
  - alert: ServiceDown
    expr: up == 0
    for: 5m
    labels:
      severity: high
    annotations:
      title: "Example title"
      runbook: "http://example.com/my-alert-runbook"
      description: "Service has been down for more than 5 minutes."
      gitlab_y_label: "y-axis label"
      foo:
        bar:
          baz: 42
```

Exemple de charge utile de requête :

```json
{
  "version" : "4",
  "groupKey": null,
  "status": "firing",
  "receiver": "",
  "groupLabels": {},
  "commonLabels": {},
  "commonAnnotations": {},
  "externalURL": "",
  "alerts": [{
    "startsAt": "2022-010-30T11:22:40Z",
    "generatorURL": "http://host?g0.expr=up",
    "endsAt": null,
    "status": "firing",
    "labels": {
      "gitlab_environment_name": "production",
      "severity": "high"
    },
    "annotations": {
      "title": "Example title",
      "runbook": "http://example.com/my-alert-runbook",
      "description": "Service has been down for more than 5 minutes.",
      "gitlab_y_label": "y-axis label",
      "foo": {
        "bar": {
          "baz": 42
        }
      }
    }
  }]
}
```

> [!note]
> Lorsque vous [déclenchez une alerte de test](#triggering-test-alerts), saisissez la charge utile entière telle qu'indiquée dans l'exemple. Lorsque vous [configurez des mappages personnalisés](#map-fields-in-custom-alerts), saisissez uniquement le premier élément du tableau `alerts` comme exemple de charge utile.

## Autorisation {#authorization}

Les méthodes d'autorisation suivantes sont acceptées :

- En-tête d'autorisation Bearer
- Authentification basique

Les valeurs `<authorization_key>` et `<url>` peuvent être trouvées lors de la configuration d'une intégration d'alerte.

### En-tête d'autorisation Bearer {#bearer-authorization-header}

La clé d'autorisation peut être utilisée comme jeton Bearer :

```shell
curl --request POST \
  --data '{"title": "Incident title"}' \
  --header "Authorization: Bearer <authorization_key>" \
  --header "Content-Type: application/json" \
  <url>
```

### Authentification basique {#basic-authentication}

La clé d'autorisation peut être utilisée comme `password`. Le champ `username` est laissé vide :

- username : `<blank>`
- password : `<authorization_key>`

```shell
curl --request POST \
  --data '{"title": "Incident title"}' \
  --header "Authorization: Basic <base_64_encoded_credentials>" \
  --header "Content-Type: application/json" \
  <url>
```

L'authentification basique peut également être utilisée avec des identifiants directement dans l'URL :

```shell
curl --request POST \
  --data '{"title": "Incident title"}' \
  --header "Content-Type: application/json" \
  <username:password@url>
```

> [!warning]
> L'utilisation de votre clé d'autorisation dans l'URL est risquée, car elle est visible dans les journaux du serveur. Nous recommandons d'utiliser l'une des options d'en-tête décrites précédemment si votre outil le prend en charge.

## Corps de la réponse {#response-body}

Le corps de réponse JSON contient la liste des alertes créées dans la requête :

```json
[
  {
    "iid": 1,
    "title": "Incident title"
  },
  {
    "iid": 2,
    "title": "Second Incident title"
  }
]
```

Les réponses réussies renvoient un code de réponse `200`.

## Déclenchement d'alertes de test {#triggering-test-alerts}

Après qu'un [responsable de maintenance ou propriétaire du projet](../../user/permissions.md) configure une intégration, vous pouvez déclencher une alerte de test pour confirmer que votre intégration fonctionne correctement.

1. Connectez-vous en tant qu'utilisateur disposant du rôle Developer, Maintainer ou Owner.
1. Accédez à **Paramètres** > **Supervision** dans votre projet.
1. Sélectionnez **Alertes** pour développer la section.
1. Sélectionnez l'icône des paramètres {{< icon name="settings" >}} sur le côté droit de l'intégration dans [la liste](#integrations-list).
1. Sélectionnez l'onglet **Envoyer une alerte de test** pour l'ouvrir.
1. Saisissez une charge utile de test dans le champ de charge utile (un JSON valide est requis).
1. Sélectionnez **Envoyer**.

GitLab affiche un message d'erreur ou de succès selon le résultat de votre test.

## Regroupement automatique des alertes identiques {#automatic-grouping-of-identical-alerts}

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

GitLab regroupe les alertes en fonction de leur charge utile. Lorsqu'une alerte entrante contient la même charge utile qu'une autre alerte (à l'exclusion des attributs `start_time` et `hosts`), GitLab regroupe ces alertes et affiche un compteur sur la [liste de gestion des alertes](incidents.md) et les pages de détails.

Si l'alerte existante est déjà `resolved`, GitLab crée une nouvelle alerte à la place.

![Liste de gestion des alertes](img/alert_list_v13_1.png)

## Alertes de récupération {#recovery-alerts}

L'alerte dans GitLab est automatiquement résolue lorsqu'un point de terminaison HTTP reçoit une charge utile avec l'heure de fin de l'alerte définie. Pour les points de terminaison HTTP sans [mappages personnalisés](#map-fields-in-custom-alerts), le champ attendu est `end_time`. Avec les mappages personnalisés, vous pouvez sélectionner le champ attendu.

GitLab détermine l'alerte à résoudre en fonction de la valeur `fingerprint` qui peut être fournie dans la charge utile. Pour plus d'informations sur les propriétés et les mappages des alertes, consultez [Personnaliser la charge utile d'alerte en dehors de GitLab](#customize-the-alert-payload-outside-of-gitlab).

Vous pouvez également configurer l'[incident associé pour qu'il soit fermé automatiquement](manage_incidents.md#automatically-close-incidents-via-recovery-alerts) lorsque l'alerte est résolue.

## Lien vers vos alertes Opsgenie {#link-to-your-opsgenie-alerts}

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Introduit](https://gitlab.com/groups/gitlab-org/-/epics/3066) dans GitLab 13.2.

{{< /history >}}

> [!warning]
> Nous développons une intégration plus poussée avec Opsgenie et d'autres outils d'alerte via les [intégrations de points de terminaison HTTP](#single-alerting-endpoint) afin que vous puissiez consulter les alertes dans l'interface GitLab.

Vous pouvez surveiller les alertes en utilisant une intégration GitLab avec [Opsgenie](https://www.atlassian.com/software/opsgenie).

Si vous activez l'intégration Opsgenie, vous ne pouvez pas avoir d'autres services d'alerte GitLab actifs en même temps.

Pour activer l'intégration Opsgenie :

1. Connectez-vous en tant qu'utilisateur disposant du rôle Maintainer ou Owner.
1. Accédez à **Supervision** > **Alertes**.
1. Dans la liste déroulante **Intégrations**, sélectionnez **Opsgenie**.
1. Sélectionnez le bouton bascule **Actif**.
1. Dans le champ **URL de l'API**, saisissez l'URL de base de votre intégration Opsgenie, par exemple `https://app.opsgenie.com/alert/list`.
1. Sélectionnez **Sauvegarder les modifications**.

Après avoir activé l'intégration, accédez à la page **Alertes** via **Supervision** > **Alertes**, puis sélectionnez **View alerts in Opsgenie**.
