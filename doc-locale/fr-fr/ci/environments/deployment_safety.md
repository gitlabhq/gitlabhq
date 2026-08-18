---
stage: Verify
group: Runner Core
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Sécurité des déploiements
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Les [jobs de déploiement](../jobs/_index.md#deployment-jobs) sont un type spécifique de job CI/CD. Ils peuvent être plus sensibles que d'autres jobs dans un pipeline, et peuvent nécessiter une attention particulière. GitLab dispose de plusieurs fonctionnalités qui contribuent à maintenir la sécurité et la stabilité des déploiements.

Vous pouvez :

- Définissez des rôles appropriés pour votre projet. Consultez [les autorisations des membres du projet](../../user/permissions.md#project-permissions) pour connaître les différents rôles utilisateur pris en charge par GitLab et les autorisations associées à chacun.
- [Restreindre l'accès en écriture à un environnement critique](#restrict-write-access-to-a-critical-environment)
- [Empêcher les déploiements pendant les fenêtres de gel du déploiement](#prevent-deployments-during-deploy-freeze-windows)
- [Protéger les secrets de production](#protect-production-secrets)
- [Projet séparé pour les déploiements](#separate-project-for-deployments)

Si vous utilisez un workflow de déploiement continu et souhaitez vous assurer que des déploiements simultanés vers le même environnement ne se produisent pas, vous devriez :

- [S'assurer qu'un seul job de déploiement s'exécute à la fois](#ensure-only-one-deployment-job-runs-at-a-time).
- [Empêcher les jobs de déploiement obsolètes](#prevent-outdated-deployment-jobs).

<i class="fa-youtube-play" aria-hidden="true"></i> Pour une vue d'ensemble, consultez [Comment sécuriser vos pipelines/workflows CD](https://www.youtube.com/watch?v=Mq3C1KveDc0).

## Restreindre l'accès en écriture à un environnement critique {#restrict-write-access-to-a-critical-environment}

Par défaut, les environnements peuvent être modifiés par tout membre de l'équipe disposant au minimum du rôle Développeur. Si vous souhaitez restreindre l'accès en écriture à un environnement critique (par exemple un environnement `production`), vous pouvez configurer des [environnements protégés](protected_environments.md).

## S'assurer qu'un seul job de déploiement s'exécute à la fois {#ensure-only-one-deployment-job-runs-at-a-time}

Les jobs de pipeline dans GitLab CI/CD s'exécutent en parallèle, ce qui signifie que deux jobs de déploiement dans deux pipelines différents peuvent tenter de déployer vers le même environnement en même temps. Ce comportement n'est pas souhaitable, car les déploiements doivent s'effectuer de manière séquentielle.

Vous pouvez vous assurer qu'un seul job de déploiement s'exécute à la fois grâce au [mot-clé `resource_group`](../yaml/_index.md#resource_group) dans votre `.gitlab-ci.yml`.

Par exemple :

```yaml
deploy:
 script: deploy-to-prod
 resource_group: prod
```

Exemple d'un flux de pipeline problématique sans le groupe de ressources :

1. Le job `deploy` dans Pipeline-A commence à s'exécuter.
1. Le job `deploy` dans Pipeline-B commence à s'exécuter. *Il s'agit d'un déploiement simultané qui pourrait provoquer un résultat inattendu.*
1. Le job `deploy` dans Pipeline-A est terminé.
1. Le job `deploy` dans Pipeline-B est terminé.

Le flux de pipeline amélioré avec le groupe de ressources :

1. Le job `deploy` dans Pipeline-A commence à s'exécuter.
1. Le job `deploy` dans Pipeline-B tente de démarrer, mais attend que le premier job `deploy` se termine.
1. Le job `deploy` dans Pipeline-A se termine.
1. Le job `deploy` dans Pipeline-B commence à s'exécuter.

Pour plus d'informations, consultez la [documentation sur les groupes de ressources](../resource_groups/_index.md).

## Empêcher les jobs de déploiement obsolètes {#prevent-outdated-deployment-jobs}

{{< history >}}

- [Modifié](https://gitlab.com/gitlab-org/gitlab/-/issues/363328) dans GitLab 15.5 pour empêcher l'exécution des jobs obsolètes.

{{< /history >}}

L'ordre d'exécution effectif des jobs de pipeline peut varier d'une exécution à l'autre, ce qui peut provoquer un comportement indésirable. Par exemple, un [job de déploiement](../jobs/_index.md#deployment-jobs) dans un pipeline plus récent peut se terminer avant un job de déploiement dans un pipeline plus ancien. Cela crée une situation de compétition où le déploiement plus ancien se termine plus tard, écrasant le déploiement « plus récent ».

Vous pouvez empêcher les jobs de déploiement plus anciens de s'exécuter lorsqu'un job de déploiement plus récent est lancé grâce au paramètre [**Empêcher les jobs de déploiement obsolètes**](../pipelines/settings.md#prevent-outdated-deployment-jobs).

Lorsqu'un job de déploiement plus ancien démarre, il échoue et reçoit le label :

- `failed outdated deployment job` dans la vue du pipeline.
- `The deployment job is older than the latest deployment, and therefore failed.` lors de la consultation du job terminé.

Lorsqu'un job de déploiement plus ancien est manuel, le bouton **Exécution** ({{< icon name="play" >}}) est désactivé avec le message `This deployment job does not run automatically and must be started manually, but it's older than the latest deployment, and therefore can't run.`.

L'ancienneté du job est déterminée par l'heure de démarrage du job, et non par l'heure du commit ; ainsi, un commit plus récent peut être bloqué dans certaines circonstances. Par exemple, le pipeline A (commit plus ancien) et le pipeline B (commit plus récent) ont tous deux des jobs de déploiement manuels. Si vous démarrez le job du pipeline A après avoir créé le pipeline B, le job de déploiement manuel du pipeline B est bloqué comme obsolète, même si le pipeline lui-même est plus récent.

### Nouvelles tentatives de job pour les déploiements de retour en arrière {#job-retries-for-rollback-deployments}

{{< history >}}

- Retour en arrière via nouvelle tentative de job [introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/378359) dans GitLab 15.6.
- Case à cocher des nouvelles tentatives de job pour les déploiements de retour en arrière [introduite](https://gitlab.com/gitlab-org/gitlab/-/issues/410427) dans GitLab 16.3.

{{< /history >}}

Vous pourriez avoir besoin d'effectuer rapidement un retour en arrière vers un déploiement stable mais obsolète. Par défaut, les nouvelles tentatives de job de pipeline pour le [retour en arrière de déploiement](deployments.md#deployment-rollback) sont activées.

Pour désactiver les nouvelles tentatives de pipeline, décochez la case **Autoriser les tentatives de job pour les déploiements de retours en arrière**. Vous devriez désactiver les nouvelles tentatives de pipeline dans les projets sensibles.

Lorsqu'un retour en arrière est nécessaire, vous devez exécuter un nouveau pipeline avec un commit précédent.

### Exemple {#example}

Exemple d'un flux de pipeline problématique avec le paramètre **Empêcher les jobs de déploiement obsolètes** désactivé :

1. Pipeline-A est créé sur la branche par défaut.
1. Plus tard, Pipeline-B est créé sur la branche par défaut (avec un SHA de commit plus récent).
1. Le job `deploy` dans Pipeline-B se termine en premier et déploie le code le plus récent.
1. Le job `deploy` dans Pipeline-A se termine plus tard et déploie le code plus ancien, **écrasant** le déploiement le plus récent (le dernier).

Le flux de pipeline amélioré avec le paramètre activé :

1. Pipeline-A est créé sur la branche par défaut.
1. Plus tard, Pipeline-B est créé sur la branche par défaut (avec un SHA plus récent).
1. Le job `deploy` dans Pipeline-B se termine en premier et déploie le code le plus récent.
1. Le job `deploy` dans Pipeline-A échoue, afin de ne pas écraser le déploiement du pipeline plus récent.

## Empêcher les déploiements pendant les fenêtres de gel du déploiement {#prevent-deployments-during-deploy-freeze-windows}

Si vous souhaitez empêcher les déploiements pendant une période particulière, par exemple lors de congés planifiés pendant lesquels la plupart des employés sont absents, vous pouvez configurer un [gel du déploiement](../../user/project/releases/_index.md#prevent-unintentional-releases-by-setting-a-deploy-freeze). Pendant une période de gel du déploiement, aucun déploiement ne peut être exécuté. Cela est utile pour s'assurer que les déploiements ne se produisent pas de manière inattendue.

Le prochain gel du déploiement configuré est affiché en haut de la page [liste des déploiements d'environnements](_index.md#view-environments-and-deployments).

## Protéger les secrets de production {#protect-production-secrets}

Les secrets de production sont nécessaires pour effectuer un déploiement avec succès. Par exemple, lors d'un déploiement vers le cloud, les fournisseurs cloud nécessitent ces secrets pour se connecter à leurs services. Dans les paramètres du projet, vous pouvez définir et protéger des variables CI/CD pour ces secrets. Les [variables protégées](../variables/_index.md#protect-a-cicd-variable) sont uniquement transmises aux pipelines s'exécutant sur des [branches protégées](../../user/project/repository/branches/protected.md) ou des [tags protégés](../../user/project/protected_tags.md). Les autres pipelines ne reçoivent pas la variable protégée. Vous pouvez également [limiter la portée des variables à des environnements spécifiques](../variables/where_variables_can_be_used.md#variables-with-an-environment-scope). Nous vous recommandons d'utiliser des variables protégées sur des environnements protégés pour vous assurer que les secrets ne sont pas exposés involontairement. Vous pouvez également définir des secrets de production du [côté du runner](../runners/configure_runners.md#prevent-runners-from-revealing-sensitive-information). Cela empêche les autres utilisateurs disposant du rôle Maintainer de lire les secrets et garantit que le runner s'exécute uniquement sur des branches protégées.

Pour plus d'informations, consultez [la sécurité des pipelines](../pipelines/_index.md#pipeline-security-on-protected-branches).

## Projet séparé pour les déploiements {#separate-project-for-deployments}

Tous les utilisateurs disposant du rôle Maintainer pour le projet ont accès aux secrets de production. Si vous devez limiter le nombre d'utilisateurs pouvant déployer vers un environnement de production, vous pouvez créer un projet séparé et configurer un nouveau modèle d'autorisations qui isole les autorisations CD du projet d'origine et empêche les utilisateurs d'origine disposant du rôle Maintainer pour le projet d'accéder au secret de production et à la configuration CD. Vous pouvez connecter le projet CD à vos projets de développement en utilisant des [pipelines multi-projets](../pipelines/downstream_pipelines.md#multi-project-pipelines).

## Protéger `.gitlab-ci.yml` contre les modifications {#protect-gitlab-ciyml-from-change}

Un fichier `.gitlab-ci.yml` peut contenir des règles pour déployer une application sur le serveur de production. Ce déploiement s'exécute généralement automatiquement après l'envoi d'une merge request. Pour empêcher les développeurs de modifier le fichier `.gitlab-ci.yml`, vous pouvez le définir dans un dépôt différent. La configuration peut faire référence à un fichier dans un autre projet avec un ensemble d'autorisations complètement différent (similaire à [la séparation d'un projet pour les déploiements](#separate-project-for-deployments)). Dans ce scénario, le fichier `.gitlab-ci.yml` est accessible publiquement, mais ne peut être modifié que par les utilisateurs disposant des autorisations appropriées dans l'autre projet.

Pour plus d'informations, consultez [Chemin de configuration CI/CD personnalisé](../pipelines/settings.md#specify-a-custom-cicd-configuration-file).

## Exiger une approbation avant le déploiement {#require-an-approval-before-deploying}

Avant de promouvoir un déploiement vers un environnement de production, le vérifier de manière croisée avec un groupe de test dédié est un moyen efficace de garantir la sécurité. Pour plus d'informations, consultez [les approbations de déploiement](deployment_approvals.md).
