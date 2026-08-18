---
stage: Verify
group: Runner Core
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "Limitez l'accès aux déploiements en protégeant les environnements. Contrôlez qui peut déployer vers des environnements spécifiques en fonction des rôles, des utilisateurs ou de l'appartenance à un groupe."
title: Environnements protégés
---

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Les [environnements](_index.md) peuvent être utilisés à des fins de test et de production.

Étant donné que les jobs de déploiement peuvent être déclenchés par différents utilisateurs avec différents rôles, il est important de pouvoir protéger des environnements spécifiques des effets des utilisateurs non autorisés.

Par défaut, un environnement protégé garantit que seules les personnes disposant des privilèges appropriés peuvent y déployer, ce qui assure la sécurité de l'environnement.

> [!note]
> Les administrateurs GitLab peuvent utiliser tous les environnements, y compris les environnements protégés.

Pour protéger ou déprotéger un environnement, vous devez disposer au minimum du rôle Maintainer. De plus, pour mettre à jour les attributs de l'environnement tels que `external_url`, `tier` ou `description`, vous devez également figurer dans la liste **Autorisés à déployer**.

## Protection des environnements {#protecting-environments}

Prérequis :

- Lorsque vous accordez l'autorisation **Autorisés à déployer** à un groupe d'approbateurs, l'utilisateur configurant l'environnement protégé doit être un **direct member** du groupe d'approbateurs à ajouter. Sinon, le groupe ou sous-groupe n'apparaît pas dans la liste déroulante. Pour plus d'informations, consultez le [ticket #345140](https://gitlab.com/gitlab-org/gitlab/-/issues/345140).
- Lorsque vous accordez des autorisations **Approbateurs** à un groupe ou un projet d'approbateurs, par défaut, seuls les membres directs du groupe ou du projet d'approbateurs reçoivent ces autorisations. Pour accorder également ces autorisations aux membres hérités du groupe ou du projet d'approbateurs :
  - Cochez la case **Activer l'héritage de groupe**.
  - [Utilisez l'API](../../api/protected_environments.md#group-inheritance-types).

Pour protéger un environnement :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **CI/CD**.
1. Développez **Environnements protégés**.
1. Sélectionnez **Protéger un environnement**.
1. Dans la liste **Environnement**, sélectionnez l'environnement que vous souhaitez protéger.
1. Dans la liste **Autorisés à déployer**, sélectionnez le rôle, les utilisateurs ou les groupes auxquels vous souhaitez accorder l'accès au déploiement. Gardez à l'esprit que :
   - Deux rôles sont disponibles :
     - **Chargés de maintenance** : Accorde l'accès à tous les utilisateurs du projet ayant le rôle Maintainer.
     - **Développeurs/développeuses** : Accorde l'accès à tous les utilisateurs du projet ayant le rôle Maintainer et Developer.
   - Vous pouvez également sélectionner des groupes déjà [invités](../../user/project/members/sharing_projects_groups.md#invite-a-group-to-a-project) dans le projet. Les groupes invités ajoutés au projet avec le rôle Reporter apparaissent dans la liste déroulante pour l'[accès limité au déploiement](#deployment-only-access-to-protected-environments).
   - Vous pouvez également sélectionner des utilisateurs spécifiques. Les utilisateurs doivent avoir le rôle Developer, Maintainer ou Owner pour apparaître dans la liste **Autorisés à déployer**.
1. Dans la liste **Approbateurs**, sélectionnez le rôle, les utilisateurs ou les groupes auxquels vous souhaitez accorder l'accès au déploiement. Gardez à l'esprit que :

   - Deux rôles sont disponibles :
     - **Chargés de maintenance** : Accorde l'accès à tous les utilisateurs du projet ayant le rôle Maintainer.
     - **Développeurs/développeuses** : Accorde l'accès à tous les utilisateurs du projet ayant le rôle Maintainer et Developer.
   - Vous pouvez uniquement sélectionner des groupes déjà [invités](../../user/project/members/sharing_projects_groups.md#invite-a-group-to-a-project) dans le projet.
   - Les utilisateurs doivent avoir le rôle Developer, Maintainer ou Owner pour apparaître dans la liste **Approbateurs**.

1. Dans la section **Règles d'approbation** :

   - Assurez-vous que ce nombre est inférieur ou égal au nombre de membres dans la règle.
   - Consultez [Approbations de déploiement](deployment_approvals.md) pour plus d'informations sur cette fonctionnalité.

1. Sélectionnez **Protéger**.

L'environnement protégé apparaît désormais dans la liste des environnements protégés.

### Utiliser l'API pour protéger un environnement {#use-the-api-to-protect-an-environment}

Vous pouvez également utiliser l'API pour protéger un environnement :

1. Utilisez un projet avec une CI qui crée un environnement. Par exemple :

   ```yaml
   stages:
     - test
     - deploy

   test:
     stage: test
     script:
       - 'echo "Testing Application: ${CI_PROJECT_NAME}"'

   production:
     stage: deploy
     when: manual
     script:
       - 'echo "Deploying to ${CI_ENVIRONMENT_NAME}"'
     environment:
       name: ${CI_JOB_NAME}
   ```

1. Utilisez l'interface utilisateur pour [créer un nouveau groupe](../../user/group/_index.md#create-a-group). Par exemple, ce groupe s'appelle `protected-access-group` et a l'ID de groupe `9899826`. Notez que le reste des exemples dans ces étapes utilisent ce groupe.

   ![Interface du groupe d'accès protégé avec le bouton Nouveau projet mis en évidence.](img/protected_access_group_v13_6.png)

1. Utilisez l'API pour ajouter un utilisateur au groupe en tant que reporter :

   ```shell
   $ curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" \
          --data "user_id=3222377&access_level=20" "https://gitlab.com/api/v4/groups/9899826/members"

   {"id":3222377,"name":"Sean Carroll","username":"sfcarroll","state":"active","avatar_url":"https://gitlab.com/uploads/-/system/user/avatar/3222377/avatar.png","web_url":"https://gitlab.com/sfcarroll","access_level":20,"created_at":"2020-10-26T17:37:50.309Z","expires_at":null}
   ```

1. Utilisez l'API pour ajouter le groupe au projet en tant que reporter :

   ```shell
   $ curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" \
          --request POST "https://gitlab.com/api/v4/projects/22034114/share?group_id=9899826&group_access=20"

   {"id":1233335,"project_id":22034114,"group_id":9899826,"group_access":20,"expires_at":null}
   ```

1. Utilisez l'API pour ajouter le groupe avec l'accès à l'environnement protégé :

   ```shell
   curl --header 'Content-Type: application/json' --request POST --data '{"name": "production", "deploy_access_levels": [{"group_id": 9899826}]}' \
        --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.com/api/v4/projects/22034114/protected_environments"
   ```

Le groupe a maintenant accès et peut être consulté dans l'interface utilisateur.

## Accès à l'environnement par appartenance à un groupe {#environment-access-by-group-membership}

Un utilisateur peut se voir accorder l'accès aux environnements protégés dans le cadre d'une [appartenance à un groupe](../../user/group/_index.md). Les utilisateurs ayant le rôle Reporter ne peuvent se voir accorder l'accès aux environnements protégés qu'avec cette méthode.

## Accès aux environnements par branche de déploiement {#deployment-branch-access}

Les utilisateurs ayant le rôle Developer peuvent se voir accorder l'accès à un environnement protégé via l'une des méthodes suivantes :

- En tant que contributeur individuel, via un rôle.
- Via une appartenance à un groupe.

Si l'utilisateur dispose également d'un accès push ou merge vers la branche déployée en production, il bénéficie des privilèges suivants :

- [Arrêter un environnement](_index.md#stopping-an-environment).
- [Supprimer un environnement](_index.md#delete-an-environment).
- [Créer un terminal d'environnement](_index.md#web-terminals-deprecated).

## Accès limité au déploiement vers les environnements protégés {#deployment-only-access-to-protected-environments}

Les utilisateurs qui ont accès à un environnement protégé, mais pas d'accès push ou merge vers la branche qui y est déployée, ne bénéficient que de l'accès au déploiement de l'environnement. Les [groupes invités](../../user/project/members/sharing_projects_groups.md#invite-a-group-to-a-project) ajoutés au projet avec le [rôle Reporter](../../user/permissions.md#project-permissions) apparaissent dans la liste déroulante pour l'accès limité au déploiement.

Pour ajouter un accès limité au déploiement :

1. Créez un groupe avec les membres autorisés à accéder à l'environnement protégé, s'il n'existe pas encore.
1. [Invitez le groupe](../../user/project/members/sharing_projects_groups.md#invite-a-group-to-a-project) dans le projet avec le rôle Reporter.
1. Suivez les étapes de la section [Protection des environnements](#protecting-environments).

## Modification et déprotection des environnements {#modifying-and-unprotecting-environments}

Les chargés de maintenance peuvent :

- Mettre à jour les paramètres de protection, y compris la liste **Autorisés à déployer** et les règles d'approbation, à tout moment.
- Déprotéger un environnement protégé en sélectionnant **Déprotéger** pour cet environnement.

Pour mettre à jour les attributs de l'environnement tels que `external_url`, `tier` ou `description` sur un environnement protégé, l'utilisateur doit également figurer dans la liste **Autorisés à déployer**.

Lorsqu'un environnement est déprotégé, toutes les entrées d'accès sont supprimées et doivent être saisies à nouveau si l'environnement est de nouveau protégé.

Lorsqu'une règle d'approbation est supprimée, les déploiements précédemment approuvés n'indiquent plus qui a approuvé le déploiement. Les informations sur la personne ayant approuvé un déploiement sont toujours disponibles dans les [événements d'audit du projet](../../user/compliance/audit_events.md#project-audit-events). Si une nouvelle règle est ajoutée, les déploiements précédents affichent les nouvelles règles sans l'option d'approbation du déploiement. Le [ticket 506687](https://gitlab.com/gitlab-org/gitlab/-/issues/506687) propose d'afficher l'historique complet des approbations des déploiements, même si une règle d'approbation est supprimée.

Pour plus d'informations, consultez [Sécurité des déploiements](deployment_safety.md).

## Environnements protégés au niveau du groupe {#group-level-protected-environments}

En général, les grandes organisations d'entreprise ont une frontière de permissions explicite entre [les développeurs et les opérateurs](https://about.gitlab.com/topics/devops/). Les développeurs créent et testent leur code, et les opérateurs déploient et surveillent l'application. Grâce aux environnements protégés au niveau du groupe, les opérateurs peuvent restreindre l'accès des développeurs aux environnements critiques. Les environnements protégés au niveau du groupe étendent les [environnements protégés au niveau du projet](#protecting-environments) au niveau du groupe.

Les permissions de déploiement peuvent être illustrées dans le tableau suivant :

| Environnement | Développeur  | Opérateur | Catégorie |
|-------------|------------|----------|----------|
| Développement | Autorisé    | Autorisé  | Environnement inférieur |
| Tests     | Autorisé    | Autorisé  | Environnement inférieur |
| Staging     | Non autorisé | Autorisé  | Environnement supérieur |
| Production  | Non autorisé | Autorisé  | Environnement supérieur |

_(Référence : [Environnements de déploiement sur Wikipédia](https://en.wikipedia.org/wiki/Deployment_environment))_

### Noms des environnements protégés au niveau du groupe {#group-level-protected-environments-names}

Contrairement aux environnements protégés au niveau du projet, les environnements protégés au niveau du groupe utilisent le [niveau de déploiement](_index.md#deployment-tier-of-environments) comme nom.

Un groupe peut être composé de nombreux environnements de projet avec des noms uniques. Par exemple, Project-A dispose d'un environnement `gprd` et Project-B d'un environnement `Production`, ce qui fait que la protection d'un nom d'environnement spécifique ne s'adapte pas bien à l'échelle. En utilisant les niveaux de déploiement, les deux sont reconnus comme le niveau de déploiement `production` et sont protégés en même temps.

### Configurer les appartenances au niveau du groupe {#configure-group-level-memberships}

{{< history >}}

- Les opérateurs doivent disposer du rôle Owner+ au lieu du rôle Maintainer+ d'origine, et ce changement de rôle est introduit à partir de GitLab 15.3 [avec un flag](https://gitlab.com/gitlab-org/gitlab/-/issues/369873) nommé `group_level_protected_environment_settings_permission`. Activé par défaut.
- [Feature flag supprimé](https://gitlab.com/gitlab-org/gitlab/-/issues/369873) dans GitLab 15.4.

{{< /history >}}

Pour maximiser l'efficacité des environnements protégés au niveau du groupe, les [appartenances au niveau du groupe](../../user/group/_index.md) doivent être correctement configurées :

- Les opérateurs doivent se voir attribuer le rôle Owner pour le groupe principal. Ils peuvent gérer les configurations CI/CD pour les environnements supérieurs (tels que la production) dans la page des paramètres au niveau du groupe, qui inclut les environnements protégés au niveau du groupe, les [runners au niveau du groupe](../runners/runners_scope.md#group-runners) et les [clusters au niveau du groupe](../../user/group/clusters/_index.md). Ces configurations sont héritées par les projets enfants en tant qu'entrées en lecture seule. Cela garantit que seuls les opérateurs peuvent configurer l'ensemble de règles de déploiement à l'échelle de l'organisation.
- Les développeurs ne doivent pas se voir attribuer plus que le rôle Developer pour le groupe principal, ou explicitement le rôle Owner pour un projet enfant. Ils n'ont pas accès aux configurations CI/CD dans le groupe principal, ce qui permet aux opérateurs de s'assurer que la configuration critique ne sera pas modifiée par inadvertance par les développeurs.
- Pour les sous-groupes et les projets enfants :
  - Concernant les [sous-groupes](../../user/group/subgroups/_index.md), si un groupe de niveau supérieur a configuré l'environnement protégé au niveau du groupe, les groupes de niveau inférieur ne peuvent pas le remplacer.
  - Les [environnements protégés au niveau du projet](#protecting-environments) peuvent être combinés avec le paramètre au niveau du groupe. Si des configurations d'environnement au niveau du groupe et au niveau du projet existent toutes les deux, pour exécuter un job de déploiement, l'utilisateur doit être autorisé dans les deux ensembles de règles.
  - Dans un projet ou un sous-groupe du groupe principal, les développeurs peuvent se voir attribuer en toute sécurité le rôle Maintainer pour ajuster leurs environnements inférieurs (tels que `testing`).

Avec cette configuration en place :

- Si un utilisateur est sur le point d'exécuter un job de déploiement dans un projet et qu'il est autorisé à déployer vers l'environnement, le job de déploiement se poursuit.
- Si un utilisateur est sur le point d'exécuter un job de déploiement dans un projet mais n'est pas autorisé à déployer vers l'environnement, le job de déploiement échoue avec un message d'erreur.

### Protéger les environnements critiques sous un groupe {#protect-critical-environments-under-a-group}

Pour protéger un environnement au niveau du groupe, assurez-vous que vos environnements ont le [`deployment_tier`](_index.md#deployment-tier-of-environments) correct défini dans `.gitlab-ci.yml`.

#### Utilisation de l'interface utilisateur {#using-the-ui}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/325249) dans GitLab 15.1.

{{< /history >}}

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre groupe.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **CI/CD**.
1. Développez **Environnements protégés**.
1. Dans la liste **Environnement**, sélectionnez le [niveau de déploiement des environnements](_index.md#deployment-tier-of-environments) que vous souhaitez protéger.
1. Dans la liste **Autorisés à déployer**, sélectionnez les [sous-groupes](../../user/group/subgroups/_index.md) auxquels vous souhaitez accorder l'accès au déploiement.
1. Sélectionnez **Protéger**.

#### Utilisation de l'API {#using-the-api}

Configurez les environnements protégés au niveau du groupe en utilisant l'[API REST](../../api/group_protected_environments.md).

## Approbations de déploiement {#deployment-approvals}

Les environnements protégés peuvent également être utilisés pour exiger des approbations manuelles avant les déploiements. Consultez [Approbations de déploiement](deployment_approvals.md) pour plus d'informations.

## Dépannage {#troubleshooting}

### Un reporter ne peut pas exécuter un job de déclenchement qui déploie vers un environnement protégé dans un pipeline downstream {#reporter-cant-run-a-trigger-job-that-deploys-to-a-protected-environment-in-downstream-pipeline}

Un utilisateur qui dispose d'un [accès limité au déploiement vers les environnements protégés](#deployment-only-access-to-protected-environments) pourrait ne pas être en mesure d'exécuter un job s'il utilise le mot-clé [`trigger`](../yaml/_index.md#trigger). Cela est dû au fait que le job ne contient pas la définition du mot-clé [`environment`](../yaml/_index.md#environment) pour associer le job à l'environnement protégé ; par conséquent, le job est reconnu comme un job standard utilisant le [modèle d'autorisation CI/CD standard](../../user/permissions.md#project-cicd).

Consultez [ce ticket](https://gitlab.com/groups/gitlab-org/-/epics/8483) pour plus d'informations sur la prise en charge du mot-clé `environment` avec le mot-clé `trigger`.
