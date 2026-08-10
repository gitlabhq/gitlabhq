---
stage: none
group: Embody
info: This page is owned by <https://handbook.gitlab.com/handbook/engineering/embody-team/>
description: "Accédez à l'API GitLab Observability pour interroger des traces, des métriques et des journaux de manière programmatique."
ignore_in_report: true
title: "Accéder à l'API Observability"
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Statut : version expérimentale

{{< /details >}}

Utilisez l'API GitLab Observability pour interroger des traces, des métriques et des journaux, et pour gérer des tableaux de bord et des alertes de manière programmatique.

## Prérequis {#prerequisites}

- Observability doit être activé pour votre groupe. Pour les instructions de configuration, consultez [Configurer Observability sur GitLab.com](setup_gitlab_com.md) ou [Configurer Observability sur GitLab Self-Managed](setup_self_managed.md).
- Vous devez disposer du rôle Developer, Maintainer ou Owner pour le groupe.

## Obtenir votre clé API {#get-your-api-key}

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à** et repérez votre groupe.
1. Dans la barre latérale gauche, sélectionnez **Observability** > **API Keys**.
1. Copiez votre clé API.

Utilisez cette clé dans l'en-tête `SIGNOZ-API-KEY` lorsque vous effectuez des requêtes API.

## Point de terminaison API {#api-endpoint}

Le point de terminaison API dépend de votre offre GitLab.

### GitLab.com {#gitlabcom}

L'URL de base de votre API suit ce modèle :

```plaintext
https://<group_id>.gitlab-o11y.com
```

Remplacez `<group_id>` par l'identifiant de votre groupe GitLab.

### GitLab Self-Managed {#gitlab-self-managed}

L'URL de base de votre API est la même URL que celle que vous avez configurée comme `o11y_service_url` pour votre groupe. Par exemple :

```plaintext
http://<your-instance-ip>:8080
```

## Effectuer des requêtes API {#make-api-requests}

Incluez votre clé API dans l'en-tête `SIGNOZ-API-KEY` avec chaque requête.

L'exemple suivant interroge le point de terminaison de santé :

```shell
curl --header "SIGNOZ-API-KEY: <your_api_key>" \
  https://<group_id>.gitlab-o11y.com/api/v1/health
```

Remplacez `<your_api_key>` par la clé figurant sur la page **API Keys**, et `<group_id>` par l'identifiant de votre groupe GitLab (ou l'URL de votre instance self-managed).

## Points de terminaison API disponibles {#available-api-endpoints}

GitLab Observability utilise l'API SigNoz. Pour la liste complète des points de terminaison disponibles, les formats de requête et de réponse, ainsi que des exemples d'utilisation, consultez la [référence de l'API SigNoz](https://signoz.io/api-reference/).

## Sujets connexes {#related-topics}

- [Envoyer des données de télémétrie à GitLab Observability](send.md)
- [Résolution des problèmes d'Observability](troubleshooting.md)
