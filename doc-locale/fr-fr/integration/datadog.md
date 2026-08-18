---
stage: Verify
group: CI Platform
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Datadog
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

L'intégration Datadog vous permet de connecter vos projets GitLab à [Datadog](https://www.datadoghq.com/), en synchronisant les métadonnées du dépôt pour enrichir votre télémétrie Datadog, permettre à Datadog de commenter les merge requests et envoyer les informations sur les pipelines CI/CD et les jobs à Datadog.

## Connecter votre compte Datadog {#connect-your-datadog-account}

Les utilisateurs disposant du rôle **Administrateur** peuvent configurer l'intégration pour l'instance entière ou pour un projet ou groupe spécifique :

1. Si vous ne disposez pas d'une clé d'API Datadog :
   1. Connectez-vous à Datadog.
   1. Accédez à la section **Intégrations**.
   1. Générez une clé d'API dans l'[onglet APIs](https://app.datadoghq.com/account/settings#api). Copiez cette valeur, car vous en aurez besoin lors d'une étape ultérieure.
1. *Pour les intégrations pour un projet ou un groupe spécifique :* Dans GitLab, accédez à votre projet ou groupe.
1. *Pour les intégrations pour l'instance entière :*
   1. Connectez-vous à GitLab en tant qu'utilisateur disposant d'un accès administrateur.
   1. dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Intégrations**.
1. Faites défiler jusqu'à **Ajouter une intégration**, puis sélectionnez **Datadog**.
1. Sélectionnez **Actif** pour activer l'intégration.
1. Spécifiez le [**Datadog site**](https://docs.datadoghq.com/getting_started/site/) vers lequel envoyer les données.
1. Facultatif. Pour remplacer l'URL de l'API utilisée pour envoyer les données directement, fournissez une **URL de l'API**. Utilisé uniquement dans les scénarios avancés.
1. Fournissez votre **Clé de l'API** Datadog.

## Configurer CI Visibility {#configure-ci-visibility}

Vous pouvez activer [Datadog CI Visibility](https://www.datadoghq.com/product/ci-cd-monitoring/) pour envoyer les données de pipeline CI/CD et de job à Datadog. Utilisez cette fonctionnalité pour surveiller et résoudre les échecs de job et les problèmes de performance.

Pour plus d'informations, consultez la [documentation Datadog CI Visibility](https://docs.datadoghq.com/continuous_integration/pipelines/?tab=gitlab).

> [!warning]
> Datadog CI Visibility est facturé par committer. L'utilisation de cette fonctionnalité peut affecter votre facture Datadog. Pour plus de détails, consultez la [page de tarification Datadog](https://www.datadoghq.com/pricing/?product=ci-pipeline-visibility#products).

Cette fonctionnalité est basée sur les webhooks ([Webhooks](../user/project/integrations/webhooks.md)) et ne nécessite qu'une configuration dans GitLab :

1. Facultatif. Sélectionnez **Activer la collecte des journaux de jobs du pipeline** pour activer la collecte des job logs pour la sortie des jobs. ([Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/346339) dans GitLab 15.3.)
1. Facultatif. Si vous utilisez plusieurs instances GitLab, fournissez un nom de **Service** unique pour différencier vos instances GitLab.
   <!-- vale gitlab_base.Spelling = NO -->
1. Facultatif. Si vous utilisez des groupes d'instances GitLab (comme les environnements de staging et de production), fournissez un nom d'**Env**. Cette valeur est associée à chaque span que l'intégration génère.
   <!-- vale gitlab_base.Spelling = YES -->
1. Facultatif. Pour définir des étiquettes personnalisées pour tous les spans auxquels l'intégration est configurée, saisissez une étiquette par ligne dans **Étiquettes**. Chaque ligne doit être au format `key:value`.
1. Facultatif. Sélectionnez **Tester les paramètres**.
1. Sélectionnez **Enregistrer les modifications**.

Lorsque l'intégration envoie des données, vous pouvez les consulter dans la section [CI Visibility](https://app.datadoghq.com/ci) de votre compte Datadog.

## Sujets connexes {#related-topics}

- [Documentation Datadog CI Visibility](https://docs.datadoghq.com/continuous_integration/)
