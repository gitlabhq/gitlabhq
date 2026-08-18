---
stage: Application Security Testing
group: Composition Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "Accédez à l'API Dependencies pour récupérer les informations de dépendances d'un projet, notamment les détails des packages, les versions, les vulnérabilités et les licences pour les gestionnaires de packages pris en charge."
title: API Dependencies
---

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Chaque appel à ce point de terminaison nécessite une authentification. Pour effectuer cet appel, l'utilisateur doit être autorisé à lire le dépôt. Pour voir les vulnérabilités dans la réponse, l'utilisateur doit être autorisé à lire le [Tableau de bord de sécurité du projet](../user/application_security/security_dashboard/_index.md).

## Lister les dépendances d'un projet {#list-project-dependencies}

Répertorie toutes les dépendances d'un projet spécifié. Cette opération reproduit partiellement la fonctionnalité [liste des dépendances](../user/application_security/dependency_list/_index.md) , disponible uniquement pour les [langages et gestionnaires de packages](../user/application_security/dependency_scanning/dependency_scanning_sbom/_index.md#supported-languages-and-files) pris en charge par Gemnasium.

Les réponses sont [paginées](rest/_index.md#pagination) et renvoient 20 résultats par défaut.

```plaintext
GET /projects/:id/dependencies
GET /projects/:id/dependencies?package_manager=maven
GET /projects/:id/dependencies?package_manager=yarn,bundler
```

| Attribut     | Type           | Obligatoire | Description                                                                                                                                                                 |
| ------------- | -------------- | -------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `id`          | entier ou chaîne | oui      | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths).                                                            |
| `package_manager` | tableau de chaînes   | non       | Renvoie les dépendances appartenant au gestionnaire de packages spécifié. Valeurs valides : `bundler`, `composer`, `conan`, `go`, `gradle`, `maven`, `npm`, `nuget`, `pip`, `pipenv`, `pnpm`, `yarn`, `sbt` ou `setuptools`. |

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/4/dependencies"
```

Exemple de réponse :

```json
[
  {
    "name": "rails",
    "version": "5.0.1",
    "package_manager": "bundler",
    "dependency_file_path": "Gemfile.lock",
    "vulnerabilities": [
      {
        "name": "DDoS",
        "severity": "unknown",
        "id": 144827,
        "url": "https://gitlab.example.com/group/project/-/security/vulnerabilities/144827"
      }
    ],
    "licenses": [
      {
        "name": "MIT",
        "url": "https://opensource.org/licenses/MIT"
      }
    ]
  },
  {
    "name": "hanami",
    "version": "1.3.1",
    "package_manager": "bundler",
    "dependency_file_path": "Gemfile.lock",
    "vulnerabilities": [],
    "licenses": [
      {
        "name": "MIT",
        "url": "https://opensource.org/licenses/MIT"
      }
    ]
  }
]
```
