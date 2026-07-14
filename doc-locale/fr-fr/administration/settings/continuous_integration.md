---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
gitlab_dedicated: yes
title: Paramètres CI/CD
---

{{< details >}}

- Niveau :  Free, Premium, Ultimate
- Offre :  GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Configurez les paramètres CI/CD de votre instance GitLab dans la zone Admin.

Prérequis :

- Vous devez disposer d'un accès administrateur.

Les paramètres suivants sont disponibles :

- Variables :  Configurez les variables CI/CD disponibles pour tous les projets de votre instance.
- Intégration et déploiement continus :  Configurez les paramètres pour Auto DevOps, les jobs, les artefacts, les runners d'instance et les fonctionnalités de pipeline.
- Registre de paquets :  Configurez le transfert de paquets et les limites de taille de fichier.
- Runners :  Configurez l'enregistrement des runners, la gestion des versions et les paramètres de jetons.
- Permissions de jetons de job :  Contrôlez l'accès aux jetons de job entre les projets.
- Journaux de jobs :  Configurez les paramètres de job log comme la journalisation incrémentale.
- [Limites CI/CD](../cicd/limits.md).

## Accéder aux paramètres d'intégration et de déploiement continus {#access-continuous-integration-and-deployment-settings}

Personnalisez les paramètres CI/CD, notamment Auto DevOps, les runners d'instance et les artefacts de job.

Pour accéder à ces paramètres :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **CI/CD**.
1. Développez **Intégration et déploiement continus**.

### Configurer Auto DevOps pour tous les projets {#configure-auto-devops-for-all-projects}

Configurez [Auto DevOps](../../topics/autodevops/_index.md) pour s'exécuter pour tous les projets qui n'ont pas de fichier `.gitlab-ci.yml`. Cela s'applique à la fois aux projets existants et aux nouveaux projets.

Pour configurer Auto DevOps pour tous les projets de votre instance :

1. Cochez la case **Utiliser par défaut le pipeline Auto DevOps pour tous les projets**.
1. Facultatif. Pour utiliser Auto Deploy et Auto Review Apps, spécifiez le [domaine de base Auto DevOps](../../topics/autodevops/requirements.md#auto-devops-base-domain).
1. Sélectionnez **Sauvegarder les modifications**.

### Runners d'instance {#instance-runners}

#### Activer les runners d'instance pour les nouveaux projets {#enable-instance-runners-for-new-projects}

Rendez les runners d'instance disponibles pour tous les nouveaux projets par défaut.

Pour rendre les runners d'instance disponibles aux nouveaux projets :

1. Cochez la case **Activer les runners d'instance pour les nouveaux projets**.
1. Sélectionnez **Sauvegarder les modifications**.

#### Ajouter des détails sur les runners d'instance {#add-details-for-instance-runners}

Ajoutez un texte explicatif sur les runners d'instance. Ce texte apparaît dans les paramètres de runner de tous les projets.

Pour ajouter des détails sur les runners d'instance :

1. Saisissez du texte dans la zone de texte **Instance runner details**. Vous pouvez utiliser la mise en forme Markdown.
1. Sélectionnez **Sauvegarder les modifications**.

Pour afficher les détails rendus :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre projet ou groupe.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **CI/CD**.
1. Développez **Runners**.

![Les paramètres de runner d'un projet affichent un message sur les directives relatives aux runners d'instance.](img/continuous_integration_instance_runner_details_v17_6.png)

#### Partager des runners de projet avec plusieurs projets {#share-project-runners-with-multiple-projects}

Partagez un runner de projet avec plusieurs projets.

Prérequis :

- Vous devez disposer d'un [runner de projet](../../ci/runners/runners_scope.md#project-runners) enregistré.

Pour partager un runner de projet avec plusieurs projets :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **CI/CD** > **Runners**.
1. Sélectionnez le runner que vous souhaitez modifier.
1. Dans le coin supérieur droit, sélectionnez **Éditer** ({{< icon name="pencil" >}}).
1. Sous **Restrict projects for this runner**, recherchez un projet.
1. À gauche du projet, sélectionnez **Activer**.
1. Répétez ce processus pour chaque projet supplémentaire.

### Artefacts de job {#job-artifacts}

Contrôlez la façon dont les [artefacts de job](../cicd/job_artifacts.md) sont stockés et gérés dans votre instance GitLab.

#### Définir la taille maximale des artefacts {#set-maximum-artifacts-size}

Définissez des limites de taille pour les artefacts de job afin de contrôler l'utilisation du stockage. Chaque fichier d'artefact dans un job a une taille maximale par défaut de 100 Mo.

Les artefacts de job définis avec `artifacts:reports` peuvent avoir des [limites différentes](../cicd/limits.md#maximum-file-size-per-type-of-artifact). Lorsque des limites différentes s'appliquent, la valeur la plus petite est utilisée.

> [!note]
> Ce paramètre s'applique à la taille du fichier d'archive final, et non aux fichiers individuels d'un job.

Vous pouvez configurer les limites de taille des artefacts pour :

- Une instance :  Le paramètre de base qui s'applique à tous les projets et groupes.
- Un groupe :  Remplace le paramètre d'instance pour tous les projets du groupe.
- Un projet :  Remplace les paramètres d'instance et de groupe pour un projet spécifique.

Pour les limites de GitLab.com, voir [Taille maximale des artefacts](../../user/gitlab_com/_index.md#cicd).

Pour modifier la taille maximale des artefacts pour une instance :

1. Saisissez une valeur dans la zone de texte **Taille maximale des artéfacts (Mo)**.
1. Sélectionnez **Sauvegarder les modifications**.

Pour modifier la taille maximale des artefacts pour un groupe ou un projet :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre projet ou groupe.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **CI/CD**.
1. Développez **Pipelines généraux**.
1. Modifiez la valeur de **Taille maximale des artéfacts** (en Mo).
1. Sélectionnez **Sauvegarder les modifications**.

#### Définir l'expiration par défaut des artefacts {#set-default-artifacts-expiration}

Définissez la durée de conservation des artefacts de job avant leur suppression automatique. La durée d'expiration par défaut est de 30 jours.

La syntaxe de la durée est décrite dans [`artifacts:expire_in`](../../ci/yaml/_index.md#artifactsexpire_in). Les définitions de job individuelles peuvent remplacer cette valeur par défaut dans le fichier `.gitlab-ci.yml` du projet.

Les modifications apportées à ce paramètre s'appliquent uniquement aux nouveaux artefacts. Les artefacts existants conservent leur durée d'expiration initiale. Pour obtenir des informations sur l'expiration manuelle des anciens artefacts, consultez la [documentation de dépannage](../cicd/job_artifacts_troubleshooting.md#delete-old-builds-and-artifacts).

Pour définir la durée d'expiration par défaut des artefacts de job :

1. Saisissez une valeur dans la zone de texte **Expiration par défaut des artéfacts**.
1. Sélectionnez **Sauvegarder les modifications**.

#### Conserver les artefacts des derniers pipelines réussis {#keep-artifacts-from-latest-successful-pipelines}

Conservez les artefacts du pipeline réussi le plus récent pour chaque référence Git (branche ou tag), quelle que soit leur durée d'expiration.

Par défaut, ce paramètre est activé.

Ce paramètre a priorité sur les [paramètres du projet](../../ci/jobs/job_artifacts.md#keep-artifacts-from-most-recent-successful-jobs). S'il est désactivé pour une instance, il ne peut pas être activé pour des projets individuels.

Lorsque cette fonctionnalité est désactivée, les artefacts conservés existants n'expirent pas immédiatement. Un nouveau pipeline réussi doit s'exécuter sur une branche avant que ses artefacts puissent expirer.

> [!note]
> Tous les paramètres d'application ont un [intervalle d'expiration du cache personnalisable](../application_settings_cache.md), ce qui peut retarder l'effet des modifications de paramètres.

Pour conserver les artefacts des derniers pipelines réussis :

1. Cochez la case **Conserver les derniers artéfacts de tous les jobs des pipelines réussis le plus récemment**.
1. Sélectionnez **Sauvegarder les modifications**.

Pour permettre aux artefacts d'expirer selon leurs paramètres d'expiration, décochez plutôt la case.

#### Afficher ou masquer la page d'avertissement de redirection externe {#display-or-hide-the-external-redirect-warning-page}

Contrôlez si une page d'avertissement doit s'afficher lorsque les utilisateurs consultent des artefacts de job via GitLab Pages. Cet avertissement signale les risques de sécurité potentiels liés au contenu généré par les utilisateurs.

La page d'avertissement de redirection externe est affichée par défaut. Pour la masquer :

1. Décochez la case **Enable the external redirect page for job artifacts**.
1. Sélectionnez **Sauvegarder les modifications**.

### Pipelines {#pipelines}

#### Archiver les pipelines {#archive-pipelines}

Archivez automatiquement les anciens pipelines et tous leurs jobs après une période spécifiée. Les jobs archivés :

- Affichent un avis informatif **This job is archived** en haut du job log.
- Ne peuvent pas être relancés ou réessayés.
- Ne peuvent pas s'exécuter en tant qu'[actions de déploiement on-stop](../../ci/environments/_index.md#stopping-an-environment) lorsque les environnements s'arrêtent automatiquement.
- Continuent d'avoir des job logs visibles.

La durée d'archivage est mesurée à partir du moment de la création du pipeline. Elle doit être d'au moins 1 jour. Voici des exemples de durées valides : `15 days`, `1 month` et `2 years`. Laissez ce champ vide pour ne jamais archiver les pipelines automatiquement.

Pour GitLab.com, voir [l'archivage des pipelines](../../user/gitlab_com/_index.md#cicd).

Pour configurer l'archivage des jobs :

1. Saisissez une valeur dans la zone de texte **Archiver les pipelines**.
1. Sélectionnez **Sauvegarder les modifications**.

#### Autoriser les variables de pipeline par défaut {#allow-pipeline-variables-by-default}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/190833) dans GitLab 18.1.

{{< /history >}}

Contrôlez si les variables CI/CD de pipeline sont autorisées par défaut dans les nouveaux projets des nouveaux groupes.

Lorsqu'il est désactivé, le paramètre [rôle par défaut pour utiliser les variables de pipeline](../../user/group/access_and_permissions.md#set-the-default-role-that-can-use-pipeline-variables) est défini sur **Aucun rôle autorisé** pour les nouveaux groupes, ce qui se répercute sur les nouveaux projets dans les nouveaux groupes. Lorsqu'il est activé, le paramètre est défini par défaut sur **Développeur**.

> [!warning]
> Pour conserver les paramètres par défaut les plus sécurisés pour les nouveaux groupes et projets, il est recommandé de définir ce paramètre sur désactivé.

Pour autoriser les variables CI/CD de pipeline par défaut dans tous les nouveaux projets des nouveaux groupes :

1. Cochez la case **Allow pipeline variables by default in new groups**.
1. Sélectionnez **Sauvegarder les modifications**.

Après la création d'un groupe ou d'un projet, les mainteneurs peuvent choisir un paramètre différent.

#### Protéger les variables CI/CD par défaut {#protect-cicd-variables-by-default}

Définissez toutes les nouvelles variables CI/CD dans les projets et les groupes comme protégées par défaut. Les variables protégées ne sont disponibles que pour les pipelines qui s'exécutent sur des branches protégées ou des tags protégés.

Pour protéger toutes les nouvelles variables CI/CD par défaut :

1. Cochez la case **Protéger les variables CI/CD par défaut**.
1. Sélectionnez **Sauvegarder les modifications**.

#### Définir le nombre maximum d'inclusions {#set-maximum-includes}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/207270) dans GitLab 16.0.

{{< /history >}}

Limitez le nombre de fichiers YAML externes qu'un pipeline peut inclure à l'aide du [mot-clé `include`](../../ci/yaml/includes.md). Cette limite prévient les problèmes de performance lorsque les pipelines incluent trop de fichiers.

Par défaut, un pipeline peut inclure jusqu'à 150 fichiers. Lorsqu'un pipeline dépasse cette limite, il échoue avec une erreur.

Pour définir le nombre maximum de fichiers inclus par pipeline :

1. Saisissez une valeur dans la zone de texte **Maximum d'inclusions**.
1. Sélectionnez **Sauvegarder les modifications**.

#### Limiter le taux de déclenchement des pipelines downstream {#limit-downstream-pipeline-trigger-rate}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/144077) dans GitLab 16.10.

{{< /history >}}

Limitez le nombre de [pipelines downstream](../../ci/pipelines/downstream_pipelines.md) pouvant être déclenchés par minute à partir d'une source unique.

Le taux maximum de déclenchement des pipelines downstream limite le nombre de pipelines downstream pouvant être déclenchés par minute pour une combinaison donnée de projet, d'utilisateur et de commit. La valeur par défaut est `0`, ce qui signifie qu'il n'y a aucune restriction.

#### Spécifier un fichier de configuration CI/CD par défaut {#specify-a-default-cicd-configuration-file}

Définissez un chemin et un nom de fichier personnalisés à utiliser par défaut pour les fichiers de configuration CI/CD dans tous les nouveaux projets. Par défaut, GitLab utilise le fichier `.gitlab-ci.yml` dans le répertoire racine du projet.

Ce paramètre s'applique uniquement aux nouveaux projets créés après sa modification. Les projets existants continuent d'utiliser leur chemin de fichier de configuration CI/CD actuel.

Pour définir un chemin de fichier de configuration CI/CD par défaut personnalisé :

1. Saisissez une valeur dans la zone de texte **Fichier de configuration CI/CD par défaut**.
1. Sélectionnez **Sauvegarder les modifications**.

Les projets individuels peuvent remplacer cette valeur par défaut d'instance en [spécifiant un fichier de configuration CI/CD personnalisé](../../ci/pipelines/settings.md#specify-a-custom-cicd-configuration-file).

#### Afficher ou masquer la bannière de suggestion de pipeline {#display-or-hide-the-pipeline-suggestion-banner}

Contrôlez si une bannière d'orientation doit être affichée dans les merge requests qui n'ont pas de pipelines. Cette bannière fournit une procédure pas à pas sur la façon d'ajouter un fichier `.gitlab-ci.yml`.

![Une bannière affiche des conseils sur la façon de démarrer avec les pipelines GitLab.](img/suggest_pipeline_banner_v14_5.png)

La bannière de suggestion de pipeline est affichée par défaut. Pour la masquer :

1. Décochez la case **Activer la bannière de suggestion de pipeline**.
1. Sélectionnez **Sauvegarder les modifications**.

#### Afficher ou masquer la bannière de migration Jenkins {#display-or-hide-the-jenkins-migration-banner}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/470025) dans GitLab 17.7.

{{< /history >}}

Contrôlez si une bannière encourageant la migration de Jenkins vers GitLab CI/CD doit être affichée. Cette bannière apparaît dans les merge requests pour les projets ayant l'[intégration Jenkins activée](../../integration/jenkins.md).

![Une bannière invitant à migrer de Jenkins vers GitLab CI](img/suggest_migrate_from_jenkins_v17_7.png)

La bannière de migration Jenkins est affichée par défaut. Pour la masquer :

1. Cochez la case **Afficher la bannière de migration depuis Jenkins**.
1. Sélectionnez **Sauvegarder les modifications**.

## Accéder aux paramètres du registre de paquets {#access-package-registry-settings}

Configurez la validation des paquets NuGet, les limites des paquets Helm, les limites de taille des fichiers de paquets et le transfert de paquets.

Pour accéder à ces paramètres :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **CI/CD**.
1. Développez **Registre de paquets**.

### Ignorer la validation de l'URL des métadonnées des paquets NuGet {#skip-nuget-package-metadata-url-validation}

Ignorez la validation des métadonnées `projectUrl`, `iconUrl` et `licenseUrl` dans les paquets NuGet.

Par défaut, GitLab valide ces URL. Si votre instance GitLab n'a pas d'accès à Internet, cette validation échoue et vous empêche de téléverser des paquets NuGet.

Pour ignorer la validation de l'URL des métadonnées des paquets NuGet :

1. Cochez la case **Ignorer la validation de l'URL des métadonnées pour le paquet NuGet**.
1. Sélectionnez **Sauvegarder les modifications**.

### Définir le nombre maximum de paquets Helm par canal {#set-maximum-helm-packages-per-channel}

Définissez le nombre maximum de paquets Helm pouvant être répertoriés par canal.

Pour définir la limite des paquets Helm :

1. Sous **Limites du paquet**, saisissez une valeur dans le champ **Nombre maximal de paquets Helm par canal**.
1. Sélectionnez **Sauvegarder les modifications**.

### Définir les limites de taille des fichiers de paquets {#set-package-file-size-limits}

Définissez les limites de taille de fichier maximales pour chaque type de paquet afin de contrôler l'utilisation du stockage et de maintenir les performances du système.

Vous pouvez configurer les limites de taille de fichier maximales pour les paquets suivants, en octets :

- Paquets Conan
- Charts Helm
- Paquets Maven
- Paquets npm
- Paquets NuGet
- Paquets PyPI
- Paquets de modules Terraform
- Paquets génériques

Pour configurer les limites de taille des fichiers de paquets :

1. Sous **Limites de taille de fichier des paquets**, saisissez les valeurs pour les limites que vous souhaitez configurer.
1. Sélectionnez **Save size limits**.

### Contrôler le transfert de paquets {#control-package-forwarding}

{{< details >}}

- Niveau :  Premium, Ultimate
- Offre :  GitLab Self-Managed

{{< /details >}}

Contrôlez si les demandes de paquets sont transférées vers les registres publics lorsque les paquets ne sont pas trouvés dans votre gistre de paquets GitLab.

Par défaut, GitLab transfère les demandes de paquets vers leurs registres publics respectifs :

- Les demandes Maven sont transférées vers [Maven Central](https://search.maven.org/).
- Les demandes npm sont transférées vers [npmjs.com](https://www.npmjs.com/).
- Les demandes PyPI sont transférées vers [pypi.org](https://pypi.org/).

Pour désactiver le transfert de paquets :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Vue d'ensemble** > **Groupes** et trouvez votre groupe.
1. Sélectionnez **Paramètres** > **CI/CD**.
1. Développez **Registre de paquets**.
1. Décochez l'une des cases suivantes :
   - **Forward npm package requests**
   - **Forward PyPI package requests**
1. Sélectionnez **Sauvegarder les modifications**.

Pour désactiver le transfert des demandes pour les paquets Maven, voir [Paquets Maven dans le registre de paquets](../../user/packages/maven_repository/_index.md#request-forwarding-to-maven-central).

## Accéder aux paramètres des runners {#access-runner-settings}

Configurez la gestion des versions des runners et les paramètres d'enregistrement.

Pour accéder à ces paramètres :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **CI/CD**.
1. Développez **Runners**.

### Contrôler la gestion des versions des runners {#control-runner-version-management}

Contrôlez si votre instance récupère les données officielles de version des runners depuis GitLab.com pour [déterminer si des runners nécessitent des mises à niveau](../../ci/runners/runners_scope.md#determine-which-runners-need-to-be-upgraded).

Par défaut, GitLab récupère les données de version des runners. Pour arrêter de récupérer ces données :

1. Sous **Gestion de la version du runner**, décochez la case **Récupérer les données de la release de GitLab Runner depuis GitLab.com**.
1. Sélectionnez **Sauvegarder les modifications**.

### Contrôler l'enregistrement des runners {#control-runner-registration}

{{< history >}}

- Paramètre **Autoriser le jeton d'enregistrement du runner** [introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/147559) dans GitLab 16.11.

{{< /history >}}

Contrôlez qui peut enregistrer des runners et si les jetons d'enregistrement sont autorisés.

> [!warning]
> L'option de transmission de jetons d'enregistrement de runner et la prise en charge de certains arguments de configuration sont considérées comme héritées et ne sont pas recommandées. Utilisez le [workflow de création de runner](https://docs.gitlab.com/runner/register/#register-with-a-runner-authentication-token) pour générer un jeton d'authentification permettant d'enregistrer des runners. Ce processus assure une traçabilité complète de la propriété des runners et renforce la sécurité de votre flotte de runners.
>
> Pour plus d'informations, voir [Migration vers le nouveau workflow d'enregistrement des runners](../../ci/runners/new_creation_workflow.md).

Par défaut, les jetons d'enregistrement des runners ainsi que l'enregistrement des membres de projet et de groupe sont autorisés. Pour restreindre l'enregistrement des runners :

1. Sous **Enregistrement de runner**, décochez l'une de ces cases :
   - **Autoriser le jeton d'enregistrement du runner**
   - **Members of the project can create runners**
   - **Members of the group can create runners**
1. Sélectionnez **Sauvegarder les modifications**.

> [!note]
> Lorsque vous désactivez l'enregistrement des runners pour les membres du projet, le jeton d'enregistrement est automatiquement renouvelé. Le jeton précédent devient invalide et vous devez utiliser le nouveau jeton d'enregistrement pour le projet.

### Restreindre l'enregistrement des runners pour un groupe spécifique {#restrict-runner-registration-for-a-specific-group}

Contrôlez si les membres d'un groupe spécifique peuvent enregistrer des runners.

Prérequis :

- La case **Members of the group can create runners** doit être cochée dans les [paramètres d'enregistrement des runners](#control-runner-registration).

Pour restreindre l'enregistrement des runners pour un groupe spécifique :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Vue d'ensemble** > **Groupes** et trouvez votre groupe.
1. Sélectionnez **Éditer**.
1. Sous **Enregistrement des runners**, décochez la case **De nouveaux runners peuvent être enregistrés pour ce groupe**.
1. Sélectionnez **Sauvegarder les modifications**.

## Accéder aux paramètres des permissions de jetons de job {#access-job-token-permission-settings}

Contrôlez comment les jetons de job CI/CD peuvent accéder à vos projets.

Pour accéder à ces paramètres :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **CI/CD**.
1. Développez **Permissions de jetons de job**.

### Appliquer la liste d'autorisation des jetons de job {#enforce-job-token-allowlist}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/496647) dans GitLab 17.6.

{{< /history >}}

Exigez que tous les projets contrôlent l'accès aux jetons de job à l'aide d'une liste d'autorisation.

Lorsque ce paramètre est activé :

- Les jetons de job CI/CD ne peuvent accéder aux projets que si le projet source du jeton est ajouté à la liste d'autorisation.
- L'[API de portée des jetons de job CI/CD](../../api/project_job_token_scopes.md#update-the-cicd-job-token-access-settings-for-a-project) renvoie une erreur si un utilisateur tente de désactiver la liste d'autorisation.

Pour plus d'informations, voir [contrôler l'accès des jetons de job à votre projet](../../ci/jobs/ci_job_token.md#control-job-token-access-to-your-project).

Pour appliquer les listes d'autorisation des jetons de job :

1. Sous **Groupes et projets autorisés**, cochez la case **Enable and enforce job token allowlist for all projects**.
1. Sélectionnez **Sauvegarder les modifications**.

## Accéder aux paramètres des journaux de jobs {#access-job-log-settings}

Contrôlez comment les job logs CI/CD sont stockés et traités.

Pour accéder à ces paramètres :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **CI/CD**.
1. Développez **Journal de jobs**.

### Configurer la journalisation incrémentale {#configure-incremental-logging}

{{< history >}}

- Paramètre d'instance [introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/186182) dans GitLab 17.11, remplaçant le feature flag `ci_enable_live_trace` [feature flag](../feature_flags/_index.md).
- Feature flag `ci_enable_live_trace` [supprimé](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/189232) dans GitLab 18.0.

{{< /history >}}

Utilisez Redis pour la mise en cache temporaire des job logs et téléversez progressivement les logs archivés vers le stockage objet. Cela améliore les performances et réduit l'utilisation de l'espace disque.

Pour plus d'informations, voir [journalisation incrémentale](../cicd/job_logs.md#incremental-logging).

Prérequis :

- Vous devez [configurer le stockage objet](../cicd/job_artifacts.md#using-object-storage) pour les artefacts, logs et builds CI/CD.

Pour activer la journalisation incrémentale pour tous les projets :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **CI/CD**.
1. Développez la section **Journal de jobs**.
1. Sous **Incremental logging configuration**, cochez la case **Activer la journalisation incrémentale**.
1. Sélectionnez **Sauvegarder les modifications**.

## Paramètres du catalogue CI/CD {#cicd-catalog-settings}

{{< details >}}

- Niveau :  Premium, Ultimate
- Offre :  GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/work_items/582044) dans GitLab 18.7.

{{< /history >}}

Contrôlez quels projets peuvent publier des composants dans le [catalogue CI/CD](../../ci/components/_index.md).

Pour accéder à ces paramètres :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **CI/CD**.
1. Développez **Catalog**.

### Restreindre la publication dans le catalogue CI/CD {#restrict-cicd-catalog-publishing}

Par défaut, tout projet peut publier des composants dans le catalogue CI/CD. Vous pouvez restreindre la publication à des projets spécifiques en configurant une liste d'autorisation.

Lorsque la liste d'autorisation est :

- Vide (par défaut) :  Tous les projets peuvent publier dans le catalogue.
- Remplie avec un certain nombre de projets :  Seuls les projets correspondant à une entrée dans la liste d'autorisation peuvent publier.

Vous pouvez définir des entrées dans la liste d'autorisation avec :

- Des chemins de projet exacts, par exemple `my-group/my-project`.
- Des expressions régulières : par exemple :
  - `my-group/.*` : tous les projets du groupe.
  - `my-group/security-.*` :  Projets commençant par `security-`.

Pour configurer la liste d'autorisation de publication dans le catalogue CI/CD :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **CI/CD**.
1. Développez **Catalog**.
1. Dans la zone de texte **Liste d'autorisation de publication dans le catalogue CI/CD**, saisissez un modèle de chemin par ligne.
1. Sélectionnez **Sauvegarder les modifications**.

Les projets ne figurant pas dans la liste d'autorisation reçoivent une erreur `not authorized to publish` lorsqu'ils tentent de publier une version de composant.

## Configuration du pipeline requise (obsolète) {#required-pipeline-configuration-deprecated}

{{< details >}}

- Niveau :  Ultimate
- Offre :  GitLab Self-Managed

{{< /details >}}

{{< history >}}

- [Obsolète](https://gitlab.com/gitlab-org/gitlab/-/issues/389467) dans GitLab 15.9.
- [Supprimé](https://gitlab.com/gitlab-org/gitlab/-/issues/389467) dans GitLab 17.0.
- [Réintroduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/165111) dans GitLab 17.4 [avec un flag](../feature_flags/_index.md) nommé `required_pipelines`. Désactivé par défaut.

{{< /history >}}

> [!warning]
> Cette fonctionnalité a été [rendue obsolète](https://gitlab.com/gitlab-org/gitlab/-/issues/389467) dans GitLab 15.9 et a été supprimée dans la version 17.0. À partir de la version 17.4, elle est disponible uniquement derrière le feature flag `required_pipelines`, désactivé par défaut. Utilisez plutôt les [pipelines de conformité](../../user/compliance/compliance_pipelines.md). Ce changement est un changement cassant.

Vous pouvez définir un modèle CI/CD comme configuration de pipeline requise pour tous les projets d'une instance GitLab. Vous pouvez utiliser un modèle provenant de :

- Les modèles CI/CD par défaut.
- Un modèle personnalisé stocké dans un [dépôt de modèles d'instance](instance_template_repository.md).

  > [!note]
  > Lorsque vous utilisez une configuration définie dans un dépôt de modèles d'instance, les mots-clés [`include:`](../../ci/yaml/_index.md#include) imbriqués (y compris `include:file`, `include:local`, `include:remote` et `include:template`) [ne fonctionnent pas](https://gitlab.com/gitlab-org/gitlab/-/issues/35345).

La configuration CI/CD du projet est fusionnée dans la configuration de pipeline requise lors de l'exécution d'un pipeline. La configuration fusionnée est identique à ce qu'elle serait si la configuration de pipeline requise ajoutait la configuration du projet avec le [mot-clé `include`](../../ci/yaml/_index.md#include). Pour afficher la configuration fusionnée complète d'un projet, utilisez [Afficher la configuration complète](../../ci/pipeline_editor/_index.md#view-full-configuration) dans l'éditeur de pipeline.

Pour sélectionner un modèle CI/CD pour la configuration de pipeline requise :

1. Dans la barre latérale gauche, en bas, sélectionnez **Admin**.
1. Sélectionnez **Paramètres** > **CI/CD**.
1. Développez la section **Configuration du pipeline requise**.
1. Sélectionnez un modèle CI/CD dans la liste déroulante.
1. Sélectionnez **Sauvegarder les modifications**.
