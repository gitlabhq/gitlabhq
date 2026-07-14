---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Pipelines programmés
description: "Créez et gérez des programmes pour exécuter des pipelines CI/CD automatiquement à l'aide de modèles cron."
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Créez des planifications de pipeline pour exécuter des pipelines à intervalles réguliers en fonction de modèles cron. Utilisez des planifications de pipeline pour les tâches devant s'exécuter selon un programme basé sur le temps plutôt que déclenchées par des modifications du code.

Contrairement aux pipelines déclenchés par des commits ou des merge requests, les pipelines programmés s'exécutent indépendamment des modifications du code. Cela les rend adaptés aux tâches devant s'effectuer indépendamment de l'activité de développement, telles que la mise à jour des déploiements ou l'exécution d'une maintenance périodique.

Les pipelines programmés cessent de s'exécuter lorsqu'un projet ou un groupe est marqué pour suppression.

## Créer une planification de pipeline {#create-a-pipeline-schedule}

{{< history >}}

- L'option Entrées [introduite](https://gitlab.com/gitlab-org/gitlab/-/issues/525504) dans GitLab 17.11.

{{< /history >}}

Lorsque vous créez une planification de pipeline, vous devenez le propriétaire de la planification. Le pipeline s'exécute avec vos autorisations et peut accéder aux [environnements protégés](../environments/protected_environments.md) et utiliser le [jeton de job CI/CD](../jobs/ci_job_token.md) en fonction de votre niveau d'accès.

Prérequis :

- Vous devez disposer du rôle Developer, Maintainer ou Owner pour le projet.
- Votre adresse e-mail principale doit être vérifiée.
- Pour les planifications ciblant des [branches protégées](../../user/project/repository/branches/protected.md#protect-a-branch), vous devez disposer des autorisations de fusion pour la branche cible.
- Votre fichier `.gitlab-ci.yml` doit avoir une syntaxe valide. Vous pouvez [valider votre configuration](../yaml/lint.md) avant la planification.

Pour créer une planification de pipeline :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Version** > **Planifications de pipeline**.
1. Sélectionnez **Nouveau programme**.
1. Remplissez les champs.
   - **Schéma de l'intervalle** : Sélectionnez l'un des intervalles préconfigurés ou saisissez un intervalle personnalisé en [notation cron](../../topics/cron/_index.md). Vous pouvez utiliser n'importe quelle valeur cron, mais les pipelines programmés ne peuvent pas s'exécuter plus fréquemment que la [fréquence maximale des pipelines programmés](../../administration/cicd/limits.md#maximum-scheduled-pipeline-frequency) de l'instance.
   - **Target branch or tag** : Sélectionnez la branche ou le tag pour le pipeline.
   - **Entrées** : Définissez des valeurs pour toutes les [entrées](../inputs/_index.md) définies dans la section `spec:inputs` de votre pipeline. Ces valeurs d'entrée sont utilisées chaque fois que le pipeline programmé s'exécute. Une planification peut avoir un maximum de 20 entrées.
   - **Variables** : Ajoutez autant de [variables CI/CD](../variables/_index.md) que vous le souhaitez à la planification. Ces variables CI/CD sont disponibles uniquement lors de l'exécution du pipeline programmé, et non lors d'une autre exécution de pipeline. Les entrées sont recommandées pour la configuration du pipeline plutôt que les variables, car elles offrent une sécurité et une flexibilité améliorées.

Si le projet a atteint le [nombre maximal de planifications de pipeline](../../administration/cicd/limits.md#number-of-pipeline-schedules), supprimez les planifications inutilisées avant d'en ajouter une autre.

## Modifier une planification de pipeline {#edit-a-pipeline-schedule}

Prérequis :

- Vous devez être le propriétaire de la planification ou en prendre possession.
- Vous devez disposer du rôle Developer, Maintainer ou Owner pour le projet.
- Pour les planifications ciblant des [branches protégées](../../user/project/repository/branches/protected.md#protect-a-branch), vous devez disposer des autorisations de fusion pour la branche cible.
- Pour les planifications s'exécutant sur des [tags protégés](../../user/project/protected_tags.md#configure-protected-tags), vous devez être autorisé à créer des tags protégés.

Pour modifier une planification de pipeline :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Version** > **Planifications de pipeline**.
1. En regard de la planification, sélectionnez **Éditer** ({{< icon name="pencil" >}}).
1. Apportez vos modifications, puis sélectionnez **Sauvegarder les modifications**.

## Exécuter manuellement {#run-manually}

Vous pouvez exécuter manuellement des pipelines programmés une fois par minute. Lorsque vous exécutez un pipeline programmé manuellement, il utilise vos autorisations plutôt que celles du propriétaire de la planification.

Pour déclencher immédiatement une planification de pipeline au lieu d'attendre l'heure programmée suivante :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Version** > **Planifications de pipeline**.
1. En regard de la planification, sélectionnez **Exécution** ({{< icon name="play" >}}).

## Devenir propriétaire {#take-ownership}

Si une planification de pipeline devient inactive parce que le propriétaire d'origine n'est pas disponible, vous pouvez en prendre possession.

Les pipelines programmés s'exécutent avec les autorisations de l'utilisateur qui possède la planification.

Prérequis :

- Vous devez avoir le rôle Maintainer ou Owner pour le projet.

Pour prendre possession d'une planification :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Version** > **Planifications de pipeline**.
1. En regard de la planification, sélectionnez **Devenir propriétaire**.

## Afficher vos pipelines programmés {#view-your-scheduled-pipelines}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/558979) dans GitLab 18.4.

{{< /history >}}

Pour afficher les planifications de pipeline actives dont vous êtes propriétaire dans tous vos projets :

1. Dans le coin supérieur droit, sélectionnez votre avatar.
1. Sélectionnez **Modifier le profil**.
1. Sélectionnez **Compte**.
1. Faites défiler jusqu'à **Pipelines programmés dont vous êtes propriétaire**.

## Sujets connexes {#related-topics}

- [Pipelines CI/CD](_index.md)
- [Exécuter des jobs pour les pipelines programmés](../jobs/job_rules.md#run-jobs-for-scheduled-pipelines)
- [API des planifications de pipeline](../../api/pipeline_schedules.md)
- [Efficacité des pipelines](pipeline_efficiency.md#reduce-how-often-jobs-run)

## Dépannage {#troubleshooting}

Lorsque vous utilisez des planifications de pipeline, vous pouvez rencontrer les problèmes suivants.

### Le pipeline programmé devient inactif {#scheduled-pipeline-becomes-inactive}

Si le statut d'un pipeline programmé devient `Inactive` de façon inattendue, le propriétaire de la planification a peut-être été bloqué ou supprimé du projet.

Prenez possession de la planification pour la réactiver.

### Distribuer les planifications de pipeline pour éviter la surcharge système {#distribute-pipeline-schedules-to-prevent-system-load}

Pour éviter une charge excessive résultant du démarrage simultané de trop nombreux pipelines, examinez et distribuez vos planifications de pipeline :

1. Exécutez cette commande pour extraire et mettre en forme les données de planification :

   ```shell
   outfile=/tmp/gitlab_ci_schedules.tsv
   sudo gitlab-psql --command "
    COPY (SELECT
        ci_pipeline_schedules.cron,
        ci_pipeline_schedules.cron_timezone,
        namespaces.path AS group,
        projects.path   AS project,
        users.email
    FROM ci_pipeline_schedules
    JOIN projects ON projects.id = ci_pipeline_schedules.project_id
    JOIN namespaces ON namespaces.id = projects.namespace_id
    JOIN users    ON users.id    = ci_pipeline_schedules.owner_id
    WHERE ci_pipeline_schedules.active = 't'
    ) TO '$outfile' CSV HEADER DELIMITER E'\t' ;"
   sort  "$outfile" | uniq -c | sort -n
   ```

1. Examinez la sortie pour identifier les modèles `cron` les plus courants. Par exemple, de nombreuses planifications peuvent s'exécuter au début de chaque heure (`0 * * * *`).
1. Ajustez les planifications pour créer un [modèle `cron` décalé](../../topics/cron/_index.md#cron-syntax), en particulier pour les dépôts volumineux. Par exemple, au lieu de plusieurs planifications s'exécutant au début de chaque heure, distribuez-les tout au long de l'heure (`5 * * * *`, `15 * * * *`, `25 * * * *`).
