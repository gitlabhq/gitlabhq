---
stage: Verify
group: Runner Core
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Provisionner des runners dans Google Cloud Compute Engine
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com

{{< /details >}}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/438316) dans GitLab 16.10 [avec un flag](../../administration/feature_flags/_index.md) nommé `google_cloud_support_feature_flag`. Cette fonctionnalité est en [bêta](../../policy/development_stages_support.md).
- [Activé sur GitLab.com](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/150472) dans GitLab 17.1. L'indicateur de fonctionnalité `google_cloud_support_feature_flag` a été supprimé.

{{< /history >}}

Vous pouvez créer un runner de projet ou un runner de groupe pour GitLab.com et le provisionner dans votre projet Google Cloud. Lorsque vous créez un runner, l'interface GitLab fournit des instructions et des scripts à l'écran pour provisionner automatiquement le runner dans votre projet Google Cloud.

Un jeton d'authentification de runner est assigné à votre runner lors de sa création. Un script Terraform [GRIT](https://gitlab.com/gitlab-org/ci-cd/runner-tools/grit) utilise ce jeton pour enregistrer le runner. Le runner utilise ensuite le jeton pour s'authentifier auprès de GitLab lorsqu'il récupère des jobs depuis la file d'attente des jobs.

Après le provisionnement, une flotte de runners avec mise à l'échelle automatique est prête à exécuter des jobs CI/CD dans Google Cloud. Le gestionnaire de runner crée automatiquement des runners temporaires.

Prérequis :

- Pour les runners de groupe : Rôle Owner pour le groupe.
- Pour les runners de projet : Rôle Maintainer pour le projet.
- Pour votre projet Google Cloud Platform : Rôle IAM [Owner](https://cloud.google.com/iam/docs/understanding-roles#owner).
- [Facturation activée](https://cloud.google.com/billing/docs/how-to/verify-billing-enabled#confirm_billing_is_enabled_on_a_project) pour votre projet Google Cloud Platform.
- Un [outil CLI `gcloud`](https://cloud.google.com/sdk/docs/install) fonctionnel authentifié avec le rôle IAM sur le projet Google Cloud.
- [Terraform v1.5 ou version ultérieure](https://releases.hashicorp.com/terraform/1.5.7/) et [l'outil CLI Terraform](https://developer.hashicorp.com/terraform/install).
- Un terminal avec Bash installé.

Pour créer un runner de groupe ou de projet et le provisionner dans Google Cloud :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre groupe.
1. Créez un nouveau runner.
   - Pour créer un nouveau runner de groupe, sélectionnez **Version** > **Runners** > **New group runner**.
   - Pour créer un nouveau runner de projet, sélectionnez **Paramètres** > **CI/CD** > **Runners** > **New project runner**.
1. Dans la section **Étiquettes**, dans le champ **Étiquettes**, saisissez les étiquettes de job pour spécifier les jobs que le runner peut exécuter. Pour utiliser le runner pour les jobs sans étiquettes en plus des jobs étiquetés, sélectionnez **Run untagged**.
1. facultatif. Dans la section **Configuration**, ajoutez la description du runner et des configurations supplémentaires.
1. Sélectionnez **Créer un runner**.
1. Dans la section **Plateforme**, sélectionnez **Google Cloud**.
1. Dans **Environnement**, saisissez les informations suivantes sur l'environnement Google Cloud :

   - **ID de projet Google Cloud**
   - **Région**
   - **Zone**
   - **Type de machine**

1. Dans **Set up GitLab Runner**, sélectionnez **Instructions de configuration**. Dans la boîte de dialogue :

   1. Pour activer les services requis, le compte de service et les autorisations, dans **Configure Google Cloud project**, exécutez le script Bash une fois pour chaque projet Google Cloud.
   1. Créez un fichier `main.tf` avec la configuration de **Install and register GitLab Runner**. Le script utilise le [GitLab Runner Infrastructure Toolkit](https://gitlab.com/gitlab-org/ci-cd/runner-tools/grit/-/blob/main/docs/scenarios/google/linux/docker-autoscaler-default/index.md) (GRIT) pour provisionner l'infrastructure sur le projet Google Cloud afin d'exécuter votre gestionnaire de runner.

      > [!warning]
      > Par défaut, le runner est configuré avec des paramètres susceptibles de provoquer une exécution continue des instances de VM, même lorsqu'aucun job CI/CD n'est actif. Pour contrôler le comportement de mise à l'échelle automatique et réduire les coûts, localisez le fichier de configuration du runner sur votre instance de gestionnaire et modifiez la [section `[runners.machine]`](https://docs.gitlab.com/runner/configuration/advanced-configuration/#the-runnersmachine-section) pour ajuster les paramètres tels que `IdleCount`, `IdleTime` et les limites d'instances.

Une fois les scripts exécutés, un gestionnaire de runner se connecte avec le jeton d'authentification du runner. Le gestionnaire de runner peut prendre jusqu'à une minute pour apparaître en ligne et commencer à recevoir des jobs.
