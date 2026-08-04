---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Google Cloud Workload Identity Federation et politiques IAM
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre :  GitLab.com

{{< /details >}}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/141127) dans GitLab 16.10 [avec un feature flag](../administration/feature_flags/_index.md) nommé `google_cloud_support_feature_flag`.
- [Activé sur GitLab.com](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/150472) dans GitLab 17.1. Feature flag `google_cloud_support_feature_flag` supprimé.

{{< /history >}}

Pour utiliser les intégrations Google Cloud telles que [l'intégration Google Artifact Management](../user/project/integrations/google_artifact_management.md), vous devez créer et configurer un [pool et un fournisseur d'identité de charge de travail](https://cloud.google.com/iam/docs/workload-identity-federation). L'intégration Google Cloud utilise Workload Identity Federation pour accorder aux charges de travail GitLab l'accès aux ressources Google Cloud via OpenID Connect (OIDC) en utilisant des jetons JSON Web Token (JWT).

## Workload Identity Federation {#workload-identity-federation}

Workload Identity Federation vous permet d'utiliser Identity and Access Management (IAM) pour accorder aux identités externes des [rôles IAM](https://cloud.google.com/iam/docs/overview#roles).

Traditionnellement, les applications s'exécutant en dehors de Google Cloud utilisaient des [clés de compte de service](https://cloud.google.com/iam/docs/service-account-creds#key-types) pour accéder aux ressources Google Cloud. Cependant, les clés de compte de service sont des identifiants puissants et peuvent représenter un risque de sécurité si elles ne sont pas gérées correctement.

Avec la fédération d'identité, vous pouvez utiliser Identity and Access Management (IAM) pour accorder des rôles IAM directement aux identités externes, sans nécessiter de comptes de service. Cette approche élimine la charge de maintenance et de sécurité associée aux comptes de service et à leurs clés.

## Pools d'identité de charge de travail {#workload-identity-pools}

Un _pool d'identité de charge de travail_ est une entité qui vous permet de gérer les identités non-Google sur Google Cloud.

L'intégration GitLab sur Google Cloud vous guide dans la configuration d'un pool d'identité de charge de travail pour vous authentifier auprès de Google Cloud. Cette configuration comprend le mappage de vos attributs de rôle GitLab aux revendications IAM dans votre politique IAM Google Cloud. Pour obtenir la liste complète des attributs GitLab disponibles pour l'intégration GitLab sur Google Cloud, consultez [Revendications OIDC personnalisées](#oidc-custom-claims).

## Fournisseurs de pool d'identité de charge de travail {#workload-identity-pool-providers}

Un _fournisseur de pool d'identité de charge de travail_ est une entité qui décrit une relation entre Google Cloud et votre fournisseur d'identité (IdP). GitLab est l'IdP de votre pool d'identité de charge de travail pour l'intégration GitLab sur Google Cloud.

Pour plus d'informations sur la fédération d'identité pour les charges de travail externes, consultez [Workload Identity Federation](https://cloud.google.com/iam/docs/workload-identity-federation).

L'intégration GitLab sur Google Cloud par défaut suppose que vous souhaitez configurer votre authentification de GitLab vers Google Cloud au niveau de l'organisation GitLab. Si vous souhaitez contrôler l'accès à Google Cloud par projet, vous devez configurer vos politiques IAM pour votre fournisseur de pool d'identité de charge de travail. Pour plus d'informations sur le contrôle des personnes pouvant accéder à Google Cloud depuis votre organisation GitLab, consultez [Contrôle d'accès avec IAM](https://cloud.google.com/docs/gitlab).

## Authentification GitLab avec Workload Identity Federation {#gitlab-authentication-with-workload-identity-federation}

Une fois votre pool et votre fournisseur d'identité de charge de travail configurés pour mapper vos rôles et autorisations GitLab aux rôles IAM, vous pouvez provisionner des runners pour déployer des charges de travail de GitLab vers Google Cloud en définissant le mot-clé [`identity`](../ci/yaml/_index.md#identity) sur `google_cloud` pour l'autorisation sur Google Cloud.

Pour plus d'informations sur le provisionnement des runners à l'aide de l'intégration GitLab sur Google Cloud, consultez le tutoriel [Provisionnement de runners dans Google Cloud](../ci/runners/provision_runners_google_cloud.md).

## Créer et configurer un Workload Identity Federation {#create-and-configure-a-workload-identity-federation}

Pour configurer Workload Identity Federation, vous pouvez soit :

- Utiliser l'interface utilisateur GitLab pour une configuration guidée.
- Utiliser la CLI Google Cloud pour configurer Workload Identity Federation manuellement.

### Avec l'interface utilisateur GitLab {#with-the-gitlab-ui}

Pour utiliser l'interface utilisateur GitLab afin de configurer Workload Identity Federation :

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à** et trouvez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Intégrations**.
1. Localisez l'intégration Google Cloud IAM et sélectionnez **Configurer**.
1. Sélectionnez **Configuration guidée** et suivez les instructions.

### Avec la CLI Google Cloud {#with-the-google-cloud-cli}

Prérequis :

- La CLI Google Cloud doit être [installée et authentifiée](https://cloud.google.com/sdk/docs/install) avec Google Cloud.
- Vous devez disposer des [autorisations](https://cloud.google.com/iam/docs/manage-workload-identity-pools-providers#required-roles) nécessaires pour gérer Workload Identity Federation dans Google Cloud.

1. Créez un pool d'identité de charge de travail à l'aide de la commande suivante. Remplacez ces valeurs :

   - `<your_google_cloud_project_id>` par votre [ID de projet Google Cloud](https://cloud.google.com/resource-manager/docs/creating-managing-projects#identifying_projects). Pour améliorer la sécurité, utilisez un projet dédié à la gestion des identités, distinct des projets de ressources et CI/CD.
   - `<your_identity_pool_id>` par l'ID à utiliser pour le pool, qui doit contenir entre 4 et 32 lettres minuscules, chiffres ou traits d'union. Pour éviter les collisions, utilisez un ID unique. Vous devriez inclure l'ID de projet GitLab ou le chemin du projet, car cela facilite la gestion des politiques IAM. Par exemple, `gitlab-my-project-name`.

   ```shell
   gcloud iam workload-identity-pools create <your_identity_pool_id> \
            --project="<your_google_cloud_project_id>" \
            --location="global" \
            --display-name="Workload identity pool for GitLab project ID"
   ```

1. Ajoutez un fournisseur OIDC au pool d'identité de charge de travail à l'aide de la commande suivante. Remplacez ces valeurs :

   - `<your_identity_provider_id>` par l'ID à utiliser pour le fournisseur, qui doit contenir entre 4 et 32 lettres minuscules, chiffres ou traits d'union. Pour éviter les collisions, utilisez un ID unique dans le pool d'identité. Par exemple, `gitlab`.
   - `<your_google_cloud_project_id>` par votre [ID de projet Google Cloud](https://cloud.google.com/resource-manager/docs/creating-managing-projects#identifying_projects).
   - `<your_identity_pool_id>` par l'ID du pool d'identité de charge de travail que vous avez créé à l'étape précédente.
   - `<your_issuer_uri>` par l'URI d'émetteur de votre fournisseur d'identité, qui peut être copié depuis la page d'intégration IAM lors du choix de la configuration manuelle et doit correspondre exactement à la valeur. Le paramètre doit inclure le chemin du groupe principal. Par exemple, si le projet se trouve sous `my-root-group/my-subgroup/project-a`, le `issuer-uri` doit être défini sur `https://auth.gcp.gitlab.com/oidc/my-root-group`.

   ```shell
   gcloud iam workload-identity-pools providers create-oidc "<your_identity_provider_id>" \
         --location="global" \
         --project="<your_google_cloud_project_id>" \
         --workload-identity-pool="<your_identity_pool_id>" \
         --issuer-uri="<your_issuer_uri>" \
         --display-name="GitLab OIDC provider" \
         --attribute-mapping="attribute.guest_access=assertion.guest_access,\
   attribute.reporter_access=assertion.reporter_access,\
   attribute.developer_access=assertion.developer_access,\
   attribute.maintainer_access=assertion.maintainer_access,\
   attribute.owner_access=assertion.owner_access,\
   attribute.namespace_id=assertion.namespace_id,\
   attribute.namespace_path=assertion.namespace_path,\
   attribute.project_id=assertion.project_id,\
   attribute.project_path=assertion.project_path,\
   attribute.user_id=assertion.user_id,\
   attribute.user_login=assertion.user_login,\
   attribute.user_email=assertion.user_email,\
   attribute.user_access_level=assertion.user_access_level,\
   google.subject=assertion.sub"
   ```

   Le paramètre `attribute-mapping` doit inclure le mappage entre les revendications OIDC personnalisées incluses dans le jeton JWT ID et les attributs d'identité correspondants utilisés dans les politiques Identity and Access Management (IAM) pour accorder l'accès. Pour plus d'informations, consultez les [revendications OIDC personnalisées prises en charge](google_cloud_iam.md#oidc-custom-claims) que vous pouvez utiliser pour [contrôler l'accès à Google Cloud](https://cloud.google.com/docs/gitlab#control-access-google).

Pour restreindre [l'accès aux jetons d'identité](https://cloud.google.com/iam/docs/workload-identity-federation#mapping) à un projet ou groupe GitLab spécifique, utilisez une condition d'attribut. Utilisez l'attribut `assertion.project_id` pour un projet et l'attribut `assertion.namespace_id` pour un groupe. Pour plus d'informations, consultez la documentation Google Cloud sur la façon de [définir une condition d'attribut](https://cloud.google.com/iam/docs/workload-identity-federation-with-deployment-pipelines#gitlab-saas_2). Après avoir défini la condition d'attribut, vous pouvez [mettre à jour le fournisseur d'identité de charge de travail](https://cloud.google.com/iam/docs/workload-identity-federation-with-deployment-pipelines#update_attribute_condition_on_a_workload_identity_provider).

Après avoir créé le pool et le fournisseur d'identité de charge de travail, pour terminer la configuration dans GitLab :

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à** et trouvez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Intégrations**.
1. Localisez l'intégration Google Cloud IAM et sélectionnez **Configurer**.
1. Sélectionnez **Manual setup**
1. Remplissez les champs.
   - **[ID du projet](https://cloud.google.com/resource-manager/docs/creating-managing-projects#identifying_projects)** pour le projet Google Cloud dans lequel vous avez créé le pool et le fournisseur d'identité de charge de travail. Exemple : `my-sample-project-191923`.
   - **[Numéro du projet](https://cloud.google.com/resource-manager/docs/creating-managing-projects#identifying_projects)** pour le même projet Google Cloud. Exemple : `314053285323`.
   - **ID du pool** du pool d'identité de charge de travail que vous avez créé pour cette intégration.
   - **ID du fournisseur** du fournisseur d'identité de charge de travail que vous avez créé pour cette intégration.

### Revendications OIDC personnalisées {#oidc-custom-claims}

Le jeton d'identifiant inclut les revendications personnalisées suivantes :

| Nom de la revendication              | Quand                      | Description                                                                                              |
| ----------------------- | ------------------------- | -------------------------------------------------------------------------------------------------------- |
| `namespace_id`          | Lors d'événements de projet         | ID de l'espace de nommage de groupe ou au niveau de l'utilisateur.                                                                 |
| `namespace_path`        | Lors d'événements de projet         | Chemin de l'espace de nommage de groupe ou au niveau de l'utilisateur.                                                               |
| `project_id`            | Lors d'événements de projet         | ID du projet.                                                                                       |
| `project_path`          | Lors d'événements de projet         | Chemin du projet.                                                                                     |
| `root_namespace_id`     | Lors d'événements de groupe           | ID du groupe principal ou de l'espace de nommage au niveau de l'utilisateur.                                                            |
| `root_namespace_path`   | Lors d'événements de groupe           | Chemin du groupe principal ou de l'espace de nommage au niveau de l'utilisateur.                                                          |
| `user_id`               | Lors d'événements déclenchés par l'utilisateur    | ID de l'utilisateur.                                                                                          |
| `user_login`            | Lors d'événements déclenchés par l'utilisateur    | Nom d'utilisateur de l'utilisateur.                                                                                    |
| `user_email`            | Lors d'événements déclenchés par l'utilisateur    | Adresse e-mail de l'utilisateur.                                                                                       |
| `ci_config_ref_uri`     | Lors d'une exécution de pipeline CI/CD | Le chemin de référence vers la définition du pipeline CI/CD CI de niveau supérieur.                                                    |
| `ci_config_sha`         | Lors d'une exécution de pipeline CI/CD | SHA du commit Git pour `ci_config_ref_uri`.                                                              |
| `job_id`                | Lors d'une exécution de pipeline CI/CD | ID du job CI.                                                                                        |
| `pipeline_id`           | Lors d'une exécution de pipeline CI/CD | ID du pipeline CI.                                                                                   |
| `pipeline_source`       | Lors d'une exécution de pipeline CI/CD | Source du pipeline CI.                                                                                      |
| `project_visibility`    | Lors d'une exécution de pipeline CI/CD | La visibilité du projet dans lequel le pipeline s'exécute.                                             |
| `ref`                   | Lors d'une exécution de pipeline CI/CD | Référence Git pour le job CI.                                                                                  |
| `ref_path`              | Lors d'une exécution de pipeline CI/CD | Référence complète pour le job CI.                                                                      |
| `ref_protected`         | Lors d'une exécution de pipeline CI/CD | Indique si la référence Git est protégée.                                                                             |
| `ref_type`              | Lors d'une exécution de pipeline CI/CD | Type de référence Git.                                                                                            |
| `runner_environment`    | Lors d'une exécution de pipeline CI/CD | Type de runner utilisé par le job CI.                                                                   |
| `runner_id`             | Lors d'une exécution de pipeline CI/CD | ID du runner exécutant le job CI.                                                                   |
| `sha`                   | Lors d'une exécution de pipeline CI/CD | Le SHA du commit pour le job CI.                                                                           |
| `environment`           | Lors d'une exécution de pipeline CI/CD | Environnement vers lequel le job CI déploie.                                                                       |
| `environment_protected` | Lors d'une exécution de pipeline CI/CD | Indique si l'environnement déployé est protégé.                                                                    |
| `environment_action`    | Lors d'une exécution de pipeline CI/CD | Action d'environnement spécifiée dans le job CI.                                                              |
| `deployment_tier`       | Lors d'une exécution de pipeline CI/CD | Niveau de déploiement de l'environnement spécifié par le job CI.                                                 |
| `user_access_level`     | Lors d'événements déclenchés par l'utilisateur    | Rôle de l'utilisateur avec les valeurs `guest`, `reporter`, `developer`, `maintainer`, `owner`.                 |
| `guest_access`          | Lors d'événements déclenchés par l'utilisateur    | Indique si l'utilisateur possède au moins le rôle `guest`, avec les valeurs « true » ou « false » sous forme de chaîne.      |
| `reporter_access`       | Lors d'événements déclenchés par l'utilisateur    | Indique si l'utilisateur possède au moins le rôle `reporter`, avec les valeurs « true » ou « false » sous forme de chaîne.   |
| `developer_access`      | Lors d'événements déclenchés par l'utilisateur    | Indique si l'utilisateur possède au moins le rôle `developer`, avec les valeurs « true » ou « false » sous forme de chaîne.  |
| `maintainer_access`     | Lors d'événements déclenchés par l'utilisateur    | Indique si l'utilisateur possède au moins le rôle `maintainer`, avec les valeurs « true » ou « false » sous forme de chaîne. |
| `owner_access`          | Lors d'événements déclenchés par l'utilisateur    | Indique si l'utilisateur possède au moins le rôle `owner`, avec les valeurs « true » ou « false » sous forme de chaîne.      |

Ces revendications sont un sur-ensemble des [revendications du jeton d'identifiant](../ci/secrets/id_token_authentication.md#token-payload). Toutes les valeurs sont de type chaîne. Consultez la documentation sur les revendications du jeton d'identifiant pour plus de détails et des exemples de valeurs.

## Contrôler l'accès à Google Cloud {#control-access-to-google-cloud}

Lorsque vous [configurez un Workload Identity Federation](#create-and-configure-a-workload-identity-federation), la plupart des revendications GitLab standard (par exemple, `user_access_level`) sont automatiquement mappées aux attributs Google Cloud.

Vous pouvez personnaliser davantage les personnes autorisées à accéder à Google Cloud depuis votre organisation GitLab. Pour ce faire, utilisez le [Common Expression Language (CEL)](https://github.com/google/cel-spec/blob/master/doc/intro.md#introduction) pour définir des principaux en fonction des [attributs OIDC personnalisés](#oidc-custom-claims) pour l'intégration GitLab sur Google Cloud.

Par exemple, pour autoriser les utilisateurs ayant le rôle `maintainer` dans GitLab à publier des artefacts dans Google Artifact Registry depuis le projet GitLab `gitlab-org/my-project` :

1. Connectez-vous à la console Google Cloud et accédez à la [page **Workload Identity Federation**](https://console.cloud.google.com/iam-admin/workload-identity-pools?supportedpurview=project).
1. Dans la colonne **Nom affiché**, sélectionnez votre pool d'identité de charge de travail.
1. Dans la section **Fournisseurs**, à côté du fournisseur d'identité de charge de travail que vous souhaitez modifier, sélectionnez **Modifier** ({{< icon name="pencil" >}}) pour ouvrir **Détails du fournisseur**.
1. Dans la section **Mappage des attributs**, sélectionnez **Ajouter un mappage**.
1. Dans la zone de texte **Google N**, saisissez :

   ```shell
   attribute.my_project_maintainer
   ```

1. Dans la zone de texte **OIDC N**, saisissez l'expression CEL suivante :

   ```shell
   assertion.maintainer_access=="true" && assertion.project_path=="gitlab-org/my-project"
   ```

1. Sélectionnez **Enregistrer**.

   L'attribut Google `my_project_maintainer` est mappé aux revendications GitLab `maintainer_access==true` et `project_path=="gitlab-org/my-project"`.
1. Dans la console Google Cloud, accédez à la [page **IAM**](https://console.cloud.google.com/iam-admin/iam?supportedpurview=project).
1. Sélectionnez **Accorder l'accès**.
1. Dans la zone de texte **Nouveaux principaux**, saisissez l'ensemble de principaux incluant `attribute.my_project_maintainer/true` au format suivant :

   ```shell
   principalSet://iam.googleapis.com/projects/<PROJECT_NUMBER>/locations/global/workloadIdentityPools/<POOL_ID>/attribute.my_project_maintainer/true
   ```

   Remplacez ce qui suit :

   - `<PROJECT_NUMBER>` par le numéro de votre projet Google Cloud. Pour trouver votre numéro de projet, consultez [Identification des projets](https://cloud.google.com/resource-manager/docs/creating-managing-projects#identifying_projects).
   - `<POOL_ID>` par l'ID de votre pool d'identité de charge de travail.

1. Dans la liste déroulante **Sélectionner un rôle**, sélectionnez le **rôle Google Artifact Registry Writer** (`roles/artifactregistry.writer`).
1. Sélectionnez **Enregistrer**.

Le rôle est accordé à l'ensemble de principaux contenant les utilisateurs ayant le rôle `maintainer` dans GitLab sur le projet `gitlab-org/my-project`.

Pour empêcher vos autres projets GitLab de publier des artefacts dans Google Artifact Registry, vous pouvez consulter vos politiques IAM dans la console Google Cloud et supprimer ou modifier les rôles selon vos besoins.

## Afficher vos politiques IAM {#view-your-iam-policies}

Connectez-vous à la console Google Cloud et accédez à la [page **IAM**](https://console.cloud.google.com/iam-admin/iam?supportedpurview=project)

Vous pouvez sélectionner **Afficher par principaux** ou **Afficher par rôle**.
