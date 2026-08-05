---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "Comment configurer l'intégration GitLab de Diffblue Cover - Cover Pipeline for GitLab"
title: Diffblue Cover
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Vous pouvez intégrer l'outil d'IA par apprentissage par renforcement [Diffblue Cover](https://www.diffblue.com/) à vos pipelines CI/CD, afin d'écrire et de maintenir automatiquement des tests unitaires Java pour vos projets GitLab. L'intégration de Diffblue Cover Pipeline for GitLab vous permet d'effectuer automatiquement les opérations suivantes :

- Écrire une suite de tests unitaires de base pour vos projets.
- Écrire de nouveaux tests unitaires pour le nouveau code.
- Mettre à jour les tests unitaires existants dans votre code.
- Supprimer les tests unitaires existants dans votre code lorsqu'ils ne sont plus nécessaires.

![Processus MR de base de Cover Pipeline for GitLab](img/diffblue_cover_workflow_after_v16_8.png)

## Configurer l'intégration {#configure-the-integration}

Pour intégrer Diffblue Cover dans votre pipeline :

1. Rechercher et configurer l'intégration Diffblue Cover.
1. Configurer un pipeline pour un exemple de projet à l'aide de l'éditeur de pipeline GitLab et du modèle de pipeline Diffblue Cover.
1. Créer une suite de tests unitaires de base complète pour le projet.

### Configurer Diffblue Cover {#configure-diffblue-cover}

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à** et trouvez votre projet.
   - Si vous souhaitez tester l'intégration avec un exemple de projet, vous pouvez [importer](../user/import/third_party_systems/repo_by_url.md) l'[exemple de projet Spring PetClinic](https://github.com/diffblue/demo-spring-petclinic) de Diffblue.
1. Sélectionnez **Paramètres** > **Intégrations**.
1. Trouvez **Diffblue Cover** et sélectionnez **Configurer**.
1. Remplissez les champs :

   - Cochez la case **Actif**.
   - Saisissez votre **Clé de licence** Diffblue Cover fournie dans votre e-mail de bienvenue ou par votre organisation. Si nécessaire, sélectionnez le lien [**Essayer Diffblue Cover**](https://www.diffblue.com/try-cover/gitlab/) pour vous inscrire à un essai gratuit.
   - Saisissez les détails de votre jeton d'accès GitLab (**Nom** et **Secret**) pour permettre à Diffblue Cover d'accéder à votre projet. En général, utilisez un jeton d'accès au projet GitLab [project access token](../user/project/settings/project_access_tokens.md) avec le rôle `Developer`, ainsi que les portées `api` et `write_repository`. Si nécessaire, vous pouvez utiliser un [jeton d'accès de groupe](../user/group/settings/group_access_tokens.md) ou un jeton d'accès personnel [personal access token](../user/profile/personal_access_tokens.md), toujours avec le rôle `Developer`, ainsi que les portées `api` et `write_repository`.

     > [!note]
     > L'utilisation d'un jeton d'accès avec des permissions excessives représente un risque de sécurité. Si vous utilisez un jeton d'accès personnel, envisagez de créer un utilisateur dédié dont l'accès est limité au seul projet concerné, afin de minimiser l'impact en cas de fuite du jeton.

1. Sélectionnez **Enregistrer les modifications**. Votre intégration Diffblue Cover est désormais <mark style="color:green;">**Actif**</mark> et prête à être utilisée dans votre projet.

### Configurer un pipeline {#configure-a-pipeline}

Créez un pipeline de merge request pour le projet qui télécharge la dernière version de Diffblue Cover, compile le projet, écrit des tests unitaires Java pour le projet et commit les modifications dans la branche.

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à** et trouvez votre projet.
1. Copiez le contenu du [modèle `Diffblue-Cover.gitlab-ci.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Diffblue-Cover.gitlab-ci.yml) dans le fichier `.gitlab-ci.yml` de votre projet.

   > [!note]
   > Lorsque vous utilisez le modèle de pipeline Diffblue Cover avec votre propre projet et un fichier de pipeline existant, ajoutez le contenu du modèle Diffblue à votre fichier et modifiez-le selon vos besoins. Pour plus d'informations, consultez [Cover Pipeline for GitLab](https://docs.diffblue.com/features/cover-pipeline/cover-pipeline-for-gitlab) dans la documentation Diffblue.
1. Saisissez un message de commit.
1. Saisissez un nouveau nom de **Branche**. Par exemple, `add-diffblue-cover-pipeline`.
1. Sélectionnez **Start a new merge request with these changes**.
1. Sélectionnez **Valider les modifications**.

### Créer une suite de tests unitaires de base {#create-a-baseline-unit-test-suite}

1. Dans le formulaire **Nouvelle requête de fusion**, saisissez un **Titre** (par exemple, « Ajouter le pipeline Cover et créer une suite de tests unitaires de base ») et renseignez les autres champs.
1. Sélectionnez **Créer une requête de fusion**. Le pipeline de merge request exécute Diffblue Cover pour créer la suite de tests unitaires de base pour le projet.
1. Une fois le pipeline terminé, les modifications peuvent être examinées depuis l'onglet **Modifications**. Lorsque vous êtes satisfait, fusionnez les mises à jour dans votre dépôt. Accédez aux dossiers `src/test` dans le dépôt du projet pour voir les tests unitaires créés par Diffblue Cover (avec le suffixe `*DiffblueTest.java`).

## Modifications de code ultérieures {#subsequent-code-changes}

Lors de modifications de code ultérieures sur un projet, le pipeline de merge request exécute Diffblue Cover, mais ne met à jour que les tests associés. Le diff résultant peut ensuite être analysé pour vérifier le nouveau comportement, détecter les régressions et repérer tout changement de comportement non planifié dans le code.

![Diff de merge request montrant les modifications de code avec les ajouts de tests en vert et les suppressions en rouge.](img/diffblue_cover_diff_v16_8.png)

## Étapes suivantes {#next-steps}

Cette rubrique présente certaines des fonctionnalités clés de Cover Pipeline for GitLab et explique comment utiliser l'intégration dans un pipeline. Les fonctionnalités plus larges et plus avancées, disponibles via les commandes `dcover` dans le modèle de pipeline, peuvent être implémentées pour étendre encore davantage vos capacités de tests unitaires. Pour plus d'informations, consultez [Cover Pipeline for GitLab](https://docs.diffblue.com/features/cover-pipeline/cover-pipeline-for-gitlab) dans la documentation Diffblue.
