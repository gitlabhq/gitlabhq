---
stage: Plan
group: Knowledge
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: API des domaines Pages
---

{{< details >}}

- Édition :  Gratuite, GitLab Premium, GitLab Ultimate
- Offre :  GitLab.com, GitLab Self-Managed

{{< /details >}}

Utilisez cette API pour gérer les [domaines GitLab Pages](../user/project/pages/custom_domains_ssl_tls_certification/_index.md).

La fonctionnalité GitLab Pages doit être activée pour utiliser ces endpoints. En savoir plus sur l'[administration](../administration/pages/_index.md) et l'[utilisation](../user/project/pages/_index.md) de cette fonctionnalité.

## Lister tous les domaines Pages {#list-all-pages-domains}

Liste tous les domaines Pages de l'instance.

Prérequis :

- Vous devez disposer d'un accès administrateur à l'instance.

```plaintext
GET /pages/domains
```

Attributs pris en charge :

| Attribut | Type           | Obligatoire | Description                                       |
| --------- | -------------- | -------- | ------------------------------------------------- |
| `domain`  | string         | non       | Le domaine du site GitLab Pages sur lequel filtrer. |

En cas de succès, renvoie [`200`](rest/troubleshooting.md#status-codes) et les attributs de réponse suivants :

| Attribut           | Type            | Description                              |
| ------------------- | --------------- | ---------------------------------------- |
| `domain`            | string          | Le nom de domaine personnalisé du site GitLab Pages. |
| `url`               | string          | L'URL complète du site Pages, protocole inclus. |
| `project_id`        | entier         | L'identifiant du projet GitLab associé à ce domaine Pages. |
| `verified`          | boolean         | Indique si le domaine a été vérifié. |
| `verification_code` | string          | Un enregistrement unique utilisé pour vérifier la propriété du domaine. |
| `enabled_until`     | date            | La date jusqu'à laquelle le domaine est activé. Ceci est mis à jour périodiquement au fur et à mesure que le domaine est revérifié.  |
| `auto_ssl_enabled`  | boolean         | Indique si la [génération automatique](../user/project/pages/custom_domains_ssl_tls_certification/lets_encrypt_integration.md) de certificats SSL via Let's Encrypt est activée pour ce domaine. |
| `certificate_expiration` | objet | Informations sur l'expiration du certificat SSL. |
| `certificate_expiration.expired` | boolean | Indique si le certificat SSL a expiré. |
| `certificate_expiration.expiration` | date | La date et l'heure d'expiration du certificat SSL. |

Exemple de requête :

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/pages/domains"
```

Exemple de réponse :

```json
[
  {
    "domain": "ssl.domain.example",
    "url": "https://ssl.domain.example",
    "project_id": 1337,
    "verified": true,
    "verification_code": "1234567890abcdef",
    "enabled_until": "2020-04-12T14:32:00.000Z",
    "auto_ssl_enabled": false,
    "certificate": {
      "expired": false,
      "expiration": "2020-04-12T14:32:00.000Z"
    }
  }
]
```

## Lister tous les domaines Pages d'un projet {#list-all-pages-domains-in-a-project}

Liste tous les domaines Pages du projet spécifié. L'utilisateur doit disposer des autorisations nécessaires pour afficher les domaines Pages.

```plaintext
GET /projects/:id/pages/domains
```

Attributs pris en charge :

| Attribut | Type           | Obligatoire | Description                              |
| --------- | -------------- | -------- | ---------------------------------------- |
| `id`      | entier ou chaîne | oui      | L'identifiant ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths) |

En cas de succès, renvoie [`200`](rest/troubleshooting.md#status-codes) et les attributs de réponse suivants :

| Attribut           | Type            | Description                              |
| ------------------- | --------------- | ---------------------------------------- |
| `domain`            | string          | Le nom de domaine personnalisé du site GitLab Pages. |
| `url`               | string          | L'URL complète du site Pages, protocole inclus. |
| `verified`          | boolean         | Indique si le domaine a été vérifié. |
| `verification_code` | string          | Un enregistrement unique utilisé pour vérifier la propriété du domaine. |
| `enabled_until`     | date            | La date jusqu'à laquelle le domaine est activé. Ceci est mis à jour périodiquement au fur et à mesure que le domaine est revérifié.  |
| `auto_ssl_enabled`  | boolean         | Indique si la [génération automatique](../user/project/pages/custom_domains_ssl_tls_certification/lets_encrypt_integration.md) de certificats SSL via Let's Encrypt est activée pour ce domaine. |
| `certificate` | objet | Informations sur le certificat SSL. |
| `certificate.subject` | string | Le sujet du certificat SSL, contenant généralement des informations sur le domaine. |
| `certificate.expired` | date | Indique si le certificat SSL a expiré (true) ou est encore valide (false). |
| `certificate.certificate` | string | Le certificat SSL complet au format PEM. |
| `certificate.certificate_text` | date | Une représentation textuelle lisible du certificat SSL, incluant des détails tels que l'émetteur, la période de validité, le sujet et d'autres informations sur le certificat.  |

Exemple de requête :

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/pages/domains"
```

Exemple de réponse :

```json
[
  {
    "domain": "www.domain.example",
    "url": "http://www.domain.example",
    "verified": true,
    "verification_code": "1234567890abcdef",
    "enabled_until": "2020-04-12T14:32:00.000Z",
    "auto_ssl_enabled": false,
  },
  {
    "domain": "ssl.domain.example",
    "url": "https://ssl.domain.example",
    "verified": true,
    "verification_code": "1234567890abcdef",
    "enabled_until": "2020-04-12T14:32:00.000Z",
    "auto_ssl_enabled": false,
    "certificate": {
      "subject": "/O=Example, Inc./OU=Example Origin CA/CN=Example Origin Certificate",
      "expired": false,
      "certificate": "-----BEGIN CERTIFICATE-----\n … \n-----END CERTIFICATE-----",
      "certificate_text": "Certificate:\n … \n"
    }
  }
]
```

## Récupérer un domaine Pages {#retrieve-a-pages-domain}

Récupère un domaine Pages du projet spécifié. L'utilisateur doit disposer des autorisations nécessaires pour afficher les domaines Pages.

```plaintext
GET /projects/:id/pages/domains/:domain
```

Attributs pris en charge :

| Attribut | Type           | Obligatoire | Description                              |
| --------- | -------------- | -------- | ---------------------------------------- |
| `id`      | entier ou chaîne | oui      | L'identifiant ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths) |
| `domain`  | string         | oui      | Le domaine personnalisé indiqué par l'utilisateur  |

En cas de succès, renvoie [`200`](rest/troubleshooting.md#status-codes) et les attributs de réponse suivants :

| Attribut           | Type            | Description                              |
| ------------------- | --------------- | ---------------------------------------- |
| `domain`            | string          | Le nom de domaine personnalisé du site GitLab Pages. |
| `url`               | string          | L'URL complète du site Pages, protocole inclus. |
| `verified`          | boolean         | Indique si le domaine a été vérifié. |
| `verification_code` | string          | Un enregistrement unique utilisé pour vérifier la propriété du domaine. |
| `enabled_until`     | date            | La date jusqu'à laquelle le domaine est activé. Ceci est mis à jour périodiquement au fur et à mesure que le domaine est revérifié.  |
| `auto_ssl_enabled`  | boolean         | Indique si la [génération automatique](../user/project/pages/custom_domains_ssl_tls_certification/lets_encrypt_integration.md) de certificats SSL via Let's Encrypt est activée pour ce domaine. |
| `certificate` | objet | Informations sur le certificat SSL. |
| `certificate.subject` | string | Le sujet du certificat SSL, contenant généralement des informations sur le domaine. |
| `certificate.expired` | date | Indique si le certificat SSL a expiré (true) ou est encore valide (false). |
| `certificate.certificate` | string | Le certificat SSL complet au format PEM. |
| `certificate.certificate_text` | date | Une représentation textuelle lisible du certificat SSL, incluant des détails tels que l'émetteur, la période de validité, le sujet et d'autres informations sur le certificat.  |

Exemple de requête :

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/pages/domains/ssl.domain.example"
```

Exemple de réponse :

```json
{
  "domain": "ssl.domain.example",
  "url": "https://ssl.domain.example",
  "verified": true,
  "verification_code": "1234567890abcdef",
  "enabled_until": "2020-04-12T14:32:00.000Z",
  "auto_ssl_enabled": false,
  "certificate": {
    "subject": "/O=Example, Inc./OU=Example Origin CA/CN=Example Origin Certificate",
    "expired": false,
    "certificate": "-----BEGIN CERTIFICATE-----\n … \n-----END CERTIFICATE-----",
    "certificate_text": "Certificate:\n … \n"
  }
}
```

## Créer un nouveau domaine Pages {#create-new-pages-domain}

Crée un domaine Pages dans le projet spécifié. L'utilisateur doit disposer des autorisations nécessaires pour créer de nouveaux domaines Pages.

```plaintext
POST /projects/:id/pages/domains
```

Attributs pris en charge :

| Attribut          | Type           | Obligatoire | Description                              |
| -------------------| -------------- | -------- | ---------------------------------------- |
| `id`               | entier ou chaîne | oui      | L'identifiant ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths) |
| `domain`           | string         | oui      | Le domaine personnalisé indiqué par l'utilisateur  |
| `auto_ssl_enabled` | boolean        | non       | Active la [génération automatique](../user/project/pages/custom_domains_ssl_tls_certification/lets_encrypt_integration.md) de certificats SSL émis par Let's Encrypt pour les domaines personnalisés. |
| `certificate`      | fichier/chaîne    | non       | Le certificat au format PEM avec les intermédiaires suivants dans l'ordre du plus spécifique au moins spécifique.|
| `key`              | fichier/chaîne    | non       | La clé du certificat au format PEM.       |

En cas de succès, renvoie [`201`](rest/troubleshooting.md#status-codes) et les attributs de réponse suivants :

| Attribut           | Type            | Description                              |
| ------------------- | --------------- | ---------------------------------------- |
| `domain`            | string          | Le nom de domaine personnalisé du site GitLab Pages. |
| `url`               | string          | L'URL complète du site Pages, protocole inclus. |
| `verified`          | boolean         | Indique si le domaine a été vérifié. |
| `verification_code` | string          | Un enregistrement unique utilisé pour vérifier la propriété du domaine. |
| `enabled_until`     | date            | La date jusqu'à laquelle le domaine est activé. Ceci est mis à jour périodiquement au fur et à mesure que le domaine est revérifié.  |
| `auto_ssl_enabled`  | boolean         | Indique si la [génération automatique](../user/project/pages/custom_domains_ssl_tls_certification/lets_encrypt_integration.md) de certificats SSL via Let's Encrypt est activée pour ce domaine. |
| `certificate` | objet | Informations sur le certificat SSL. |
| `certificate.subject` | string | Le sujet du certificat SSL, contenant généralement des informations sur le domaine. |
| `certificate.expired` | date | Indique si le certificat SSL a expiré (true) ou est encore valide (false). |
| `certificate.certificate` | string | Le certificat SSL complet au format PEM. |
| `certificate.certificate_text` | date | Une représentation textuelle lisible du certificat SSL, incluant des détails tels que l'émetteur, la période de validité, le sujet et d'autres informations sur le certificat.  |

Exemples de requêtes :

Créer un nouveau domaine Pages avec un certificat depuis un fichier `.pem` :

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/pages/domains" \
  --form "domain=ssl.domain.example" \
  --form "certificate=@/path/to/cert.pem" \
  --form "key=@/path/to/key.pem"
```

Créer un nouveau domaine Pages en utilisant une variable contenant le certificat :

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/pages/domains" \
  --form "domain=ssl.domain.example" \
  --form "certificate=$CERT_PEM" \
  --form "key=$KEY_PEM"
```

Créer un nouveau domaine Pages avec un [certificat automatique](../user/project/pages/custom_domains_ssl_tls_certification/lets_encrypt_integration.md#enabling-lets-encrypt-integration-for-your-custom-domain) :

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" --form "domain=ssl.domain.example" \
     --form "auto_ssl_enabled=true" "https://gitlab.example.com/api/v4/projects/5/pages/domains"
```

Exemple de réponse :

```json
{
  "domain": "ssl.domain.example",
  "url": "https://ssl.domain.example",
  "auto_ssl_enabled": true,
  "certificate": {
    "subject": "/O=Example, Inc./OU=Example Origin CA/CN=Example Origin Certificate",
    "expired": false,
    "certificate": "-----BEGIN CERTIFICATE-----\n … \n-----END CERTIFICATE-----",
    "certificate_text": "Certificate:\n … \n"
  }
}
```

## Mettre à jour un domaine Pages {#update-pages-domain}

Met à jour le domaine Pages spécifié dans un projet. L'utilisateur doit disposer des autorisations nécessaires pour modifier un domaine Pages existant.

```plaintext
PUT /projects/:id/pages/domains/:domain
```

Attributs pris en charge :

| Attribut          | Type           | Obligatoire | Description                              |
| ------------------ | -------------- | -------- | ---------------------------------------- |
| `id`               | entier ou chaîne | oui      | L'identifiant ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths) |
| `domain`           | string         | oui      | Le domaine personnalisé indiqué par l'utilisateur  |
| `auto_ssl_enabled` | boolean        | non       | Active la [génération automatique](../user/project/pages/custom_domains_ssl_tls_certification/lets_encrypt_integration.md) de certificats SSL émis par Let's Encrypt pour les domaines personnalisés. |
| `certificate`      | fichier/chaîne    | non       | Le certificat au format PEM avec les intermédiaires suivants dans l'ordre du plus spécifique au moins spécifique.|
| `key`              | fichier/chaîne    | non       | La clé du certificat au format PEM.       |

En cas de succès, renvoie [`200`](rest/troubleshooting.md#status-codes) et les attributs de réponse suivants :

| Attribut           | Type            | Description                              |
| ------------------- | --------------- | ---------------------------------------- |
| `domain`            | string          | Le nom de domaine personnalisé du site GitLab Pages. |
| `url`               | string          | L'URL complète du site Pages, protocole inclus. |
| `verified`          | boolean         | Indique si le domaine a été vérifié. |
| `verification_code` | string          | Un enregistrement unique utilisé pour vérifier la propriété du domaine. |
| `enabled_until`     | date            | La date jusqu'à laquelle le domaine est activé. Ceci est mis à jour périodiquement au fur et à mesure que le domaine est revérifié.  |
| `auto_ssl_enabled`  | boolean         | Indique si la [génération automatique](../user/project/pages/custom_domains_ssl_tls_certification/lets_encrypt_integration.md) de certificats SSL via Let's Encrypt est activée pour ce domaine. |
| `certificate` | objet | Informations sur le certificat SSL. |
| `certificate.subject` | string | Le sujet du certificat SSL, contenant généralement des informations sur le domaine. |
| `certificate.expired` | date | Indique si le certificat SSL a expiré (true) ou est encore valide (false). |
| `certificate.certificate` | string | Le certificat SSL complet au format PEM. |
| `certificate.certificate_text` | date | Une représentation textuelle lisible du certificat SSL, incluant des détails tels que l'émetteur, la période de validité, le sujet et d'autres informations sur le certificat.  |

### Ajout d'un certificat {#adding-certificate}

Ajouter un certificat pour un domaine Pages depuis un fichier `.pem` :

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/pages/domains/ssl.domain.example" \
  --form "certificate=@/path/to/cert.pem" \
  --form "key=@/path/to/key.pem"
```

Ajouter un certificat pour un domaine Pages en utilisant une variable contenant le certificat :

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/pages/domains/ssl.domain.example" \
  --form "certificate=$CERT_PEM" \
  --form "key=$KEY_PEM"
```

Exemple de réponse :

```json
{
  "domain": "ssl.domain.example",
  "url": "https://ssl.domain.example",
  "auto_ssl_enabled": false,
  "certificate": {
    "subject": "/O=Example, Inc./OU=Example Origin CA/CN=Example Origin Certificate",
    "expired": false,
    "certificate": "-----BEGIN CERTIFICATE-----\n … \n-----END CERTIFICATE-----",
    "certificate_text": "Certificate:\n … \n"
  }
}
```

### Activation de l'intégration Let's Encrypt pour les domaines personnalisés Pages {#enabling-lets-encrypt-integration-for-pages-custom-domains}

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/pages/domains/ssl.domain.example" \
  --form "auto_ssl_enabled=true"
```

Exemple de réponse :

```json
{
  "domain": "ssl.domain.example",
  "url": "https://ssl.domain.example",
  "auto_ssl_enabled": true
}
```

### Suppression d'un certificat {#removing-certificate}

Pour supprimer le certificat SSL associé au domaine Pages, exécutez :

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/pages/domains/ssl.domain.example" \
  --form "certificate=" \
  --form "key="
```

Exemple de réponse :

```json
{
  "domain": "ssl.domain.example",
  "url": "https://ssl.domain.example",
  "auto_ssl_enabled": false
}
```

## Vérifier un domaine Pages {#verify-pages-domain}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/21261) dans GitLab 17.7.

{{< /history >}}

Vérifie le domaine Pages spécifié dans un projet. L'utilisateur doit disposer des autorisations nécessaires pour mettre à jour les domaines Pages.

```plaintext
PUT /projects/:id/pages/domains/:domain/verify
```

Attributs pris en charge :

| Attribut          | Type           | Obligatoire | Description                              |
| ------------------ | -------------- | -------- | ---------------------------------------- |
| `id` | entier ou chaîne | oui | L'identifiant ou le chemin encodé en URL du projet |
| `domain` | string | oui | Le domaine personnalisé à vérifier |

En cas de succès, renvoie [`200`](rest/troubleshooting.md#status-codes) et les attributs de réponse suivants :

| Attribut           | Type            | Description                              |
| ------------------- | --------------- | ---------------------------------------- |
| `domain`            | string          | Le nom de domaine personnalisé du site GitLab Pages. |
| `url`               | string          | L'URL complète du site Pages, protocole inclus. |
| `verified`          | boolean         | Indique si le domaine a été vérifié. |
| `verification_code` | string          | Un enregistrement unique utilisé pour vérifier la propriété du domaine. |
| `enabled_until`     | date            | La date jusqu'à laquelle le domaine est activé. Ceci est mis à jour périodiquement au fur et à mesure que le domaine est revérifié.  |
| `auto_ssl_enabled`  | boolean         | Indique si la [génération automatique](../user/project/pages/custom_domains_ssl_tls_certification/lets_encrypt_integration.md) de certificats SSL via Let's Encrypt est activée pour ce domaine. |
| `certificate` | objet | Informations sur le certificat SSL. |
| `certificate.subject` | string | Le sujet du certificat SSL, contenant généralement des informations sur le domaine. |
| `certificate.expired` | date | Indique si le certificat SSL a expiré (true) ou est encore valide (false). |
| `certificate.certificate` | string | Le certificat SSL complet au format PEM. |
| `certificate.certificate_text` | date | Une représentation textuelle lisible du certificat SSL, incluant des détails tels que l'émetteur, la période de validité, le sujet et d'autres informations sur le certificat.  |

Exemple de requête :

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/pages/domains/ssl.domain.example/verify"
```

Exemple de réponse :

```json
{
  "domain": "ssl.domain.example",
  "url": "https://ssl.domain.example",
  "auto_ssl_enabled": false,
  "verified": true,
  "verification_code": "1234567890abcdef",
  "enabled_until": "2020-04-12T14:32:00.000Z"
}
```

## Supprimer un domaine Pages {#delete-pages-domain}

Supprime le domaine Pages spécifié dans un projet.

```plaintext
DELETE /projects/:id/pages/domains/:domain
```

Attributs pris en charge :

| Attribut | Type           | Obligatoire | Description                              |
| --------- | -------------- | -------- | ---------------------------------------- |
| `id`      | entier ou chaîne | oui      | L'identifiant ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths) |
| `domain`  | string         | oui      | Le domaine personnalisé indiqué par l'utilisateur  |

En cas de succès, une réponse HTTP `204 No Content` avec un corps vide est attendue.

Exemple de requête :

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/pages/domains/ssl.domain.example"
```
