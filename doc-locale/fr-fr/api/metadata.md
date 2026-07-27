---
stage: Verify
group: Runner Core
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: API Metadata
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/357032) dans GitLab 15.2.
- `enterprise` [introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/103969) dans GitLab 15.6.
- `kas.externalK8sProxyUrl` [introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/172373) dans GitLab 17.6.

{{< /history >}}

Récupère les informations de métadonnées pour une instance GitLab spécifiée.

```plaintext
GET /metadata
GET /version
```

Attributs du corps de la réponse :

| Attribut                 | Type           | Description                                                                                                                   |
|:--------------------------|:---------------|:------------------------------------------------------------------------------------------------------------------------------|
| `version`                 | string         | Version de l'instance GitLab.                                                                                               |
| `revision`                | string         | Révision de l'instance GitLab.                                                                                              |
| `kas`                     | objet         | Métadonnées sur le serveur d'agent GitLab pour Kubernetes (KAS).                                                                  |
| `kas.enabled`             | boolean        | Indique si KAS est activé.                                                                                             |
| `kas.externalUrl`         | chaîne ou null | URL utilisée par les agents pour communiquer avec KAS. La valeur est `null` si `kas.enabled` est `false`.                                      |
| `kas.externalK8sProxyUrl` | chaîne ou null | URL utilisée par les outils Kubernetes pour communiquer avec le proxy API Kubernetes de KAS. La valeur est `null` si `kas.enabled` est `false`. |
| `kas.version`             | chaîne ou null | Version de KAS. La valeur est `null` si `kas.enabled` est `false` ou lorsque l'instance GitLab n'a pas réussi à récupérer les informations du serveur depuis KAS.         |
| `enterprise`              | boolean        | Indique si l'instance GitLab est Enterprise Edition.                                                                      |

Exemple de requête :

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/metadata"
```

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/version"
```

Exemple de réponse :

```json
{
  "version": "18.1.1-ee",
  "revision": "ceb07b24cb0",
  "kas": {
    "enabled": true,
    "externalUrl": "grpc://gitlab.example.com:8150",
    "externalK8sProxyUrl": "https://gitlab.example.com:8150/k8s-proxy",
    "version": "18.1.1"
  },
  "enterprise": true
}
```
