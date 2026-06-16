---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: "API d'intégration Google Cloud"
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com
- Statut : Expérience

{{< /details >}}

Utilisez cette API pour interagir avec l'intégration Google Cloud. Pour plus d'informations, consultez [Intégration GitLab et Google Cloud](../ci/gitlab_google_cloud_integration/_index.md).

## Scripts d'intégration Google Cloud au niveau du projet {#project-level-google-cloud-integration-scripts}

{{< details >}}

- Statut : Expérience

{{< /details >}}

{{< history >}}

- [Introduite](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/141870) dans GitLab 16.10. Cette fonctionnalité est une [expérience](../policy/development_stages_support.md).

{{< /history >}}

### Script de création de la fédération d'identité de charge de travail {#workload-identity-federation-creation-script}

{{< history >}}

- [Introduite](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/141870) dans GitLab 16.10.

{{< /history >}}

Les utilisateurs disposant du rôle Maintainer ou Owner pour le projet peuvent utiliser le point de terminaison suivant pour interroger un script shell qui crée et configure la fédération d'identité de charge de travail dans Google Cloud :

```plaintext
GET /projects/:id/google_cloud/setup/wlif.sh
```

Attributs pris en charge :

| Attribut                                         | Type             | Obligatoire | Description                                                                                                      |
|---------------------------------------------------|------------------|----------|------------------------------------------------------------------------------------------------------------------|
| `id`                                              | entier          | Oui      | L'ID d'un projet.                                                                                                |
| `google_cloud_project_id`                         | string           | Oui      | ID de projet Google Cloud pour la fédération d'identité de charge de travail.                                                    |
| `google_cloud_workload_identity_pool_id`          | string           | Non       | ID du pool d'identités de charge de travail Google Cloud à créer. Par défaut `gitlab-wlif`.                              |
| `google_cloud_workload_identity_pool_display_name`| string           | Non       | Nom d'affichage du pool d'identités de charge de travail Google Cloud à créer. Par défaut `WLIF for GitLab integration`.   |
| `google_cloud_workload_identity_pool_provider_id` | string           | Non       | ID du fournisseur du pool d'identités de charge de travail Google Cloud à créer. Par défaut `gitlab-wlif-oidc-provider`.       |
| `google_cloud_workload_identity_pool_provider_display_name`| string  | Non       | Nom d'affichage du fournisseur du pool d'identités de charge de travail Google Cloud à créer. Par défaut `GitLab OIDC provider`. |

Exemple de requête :

```shell
curl --request GET \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     --url "https://gitlab.com/api/v4/projects/<your_project_id>/google_cloud/setup/wlif.sh"
```

### Script de configuration d'une intégration Google Cloud {#script-to-set-up-a-google-cloud-integration}

{{< history >}}

- [Introduite](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/144787) dans GitLab 16.10.

{{< /history >}}

Les utilisateurs disposant du rôle Maintainer ou Owner pour le projet peuvent utiliser le point de terminaison suivant pour interroger un script shell permettant de configurer une intégration Google Cloud :

```plaintext
GET /projects/:id/google_cloud/setup/integrations.sh
```

Seule l'[intégration Google Artifact Management](../user/project/integrations/google_artifact_management.md) est prise en charge. Le script crée des politiques IAM pour accéder à Google Artifact Registry :

- Le rôle [Artifact Registry Reader](https://cloud.google.com/artifact-registry/docs/access-control#roles) est accordé aux membres disposant au moins du rôle Reporter
- Le rôle [Artifact Registry Writer](https://cloud.google.com/artifact-registry/docs/access-control#roles) est accordé aux membres disposant au moins du rôle Developer

Attributs pris en charge :

| Attribut                                   | Type    | Obligatoire | Description                                                                 |
|---------------------------------------------|---------|----------|-----------------------------------------------------------------------------|
| `id`                                        | entier | Oui      | L'ID d'un projet GitLab.                                                           |
| `enable_google_cloud_artifact_registry`     | boolean | Oui      | Indicateur permettant de spécifier si l'intégration Google Artifact Management doit être activée. |
| `google_cloud_artifact_registry_project_id` | string  | Oui      | ID de projet Google Cloud pour l'Artifact Registry.                          |

Exemple de requête :

```shell
curl --request GET \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     --url "https://gitlab.com/api/v4/projects/<your_project_id>/google_cloud/setup/integrations.sh"
```

### Script de configuration d'un projet Google Cloud pour le provisionnement des runners {#script-to-configure-a-google-cloud-project-for-runner-provisioning}

{{< history >}}

- [Introduite](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/145525) dans GitLab 16.10.

{{< /history >}}

Les utilisateurs disposant du rôle Maintainer ou Owner pour le projet peuvent utiliser le point de terminaison suivant pour interroger un script shell permettant de configurer un projet Google Cloud pour le provisionnement et l'exécution des runners :

```plaintext
GET /projects/:id/google_cloud/setup/runner_deployment_project.sh
```

Le script effectue des étapes de configuration préparatoires dans le projet Google Cloud spécifié, notamment l'activation des services requis et la création d'un rôle `GRITProvisioner` et d'un compte de service `grit-provisioner`.

Attributs pris en charge :

| Attribut                 | Type    | Obligatoire | Description                            |
|---------------------------|---------|----------|----------------------------------------|
| `id`                      | entier | Oui      | L'ID d'un projet GitLab.            |
| `google_cloud_project_id` | string  | Oui      | L'ID du projet Google Cloud.    |

Exemple de requête :

```shell
curl --request GET \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     --url "https://gitlab.com/api/v4/projects/<your_project_id>/google_cloud/setup/runner_deployment_project.sh?google_cloud_project_id=<your_google_cloud_project_id>"
```
