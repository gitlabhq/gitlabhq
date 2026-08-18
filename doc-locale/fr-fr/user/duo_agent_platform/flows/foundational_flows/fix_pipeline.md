---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Flow Fix CI/CD Pipeline
---

{{< details >}}

- Édition : [Gratuite](../../../../subscriptions/gitlab_credits.md#for-the-free-tier), GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- Introduction en tant que [version expérimentale](../../../../policy/development_stages_support.md) dans GitLab 18.4 [avec des feature flags](../../../../administration/feature_flags/_index.md) nommés `duo_workflow_in_ci` et `ai_duo_agent_fix_pipeline_button`. `duo_workflow_in_ci` est activé par défaut. `ai_duo_agent_fix_pipeline_button` est désactivé par défaut. Ces flags peuvent être activés ou désactivés pour l'instance ou le projet.
- Activé sur GitLab.com et GitLab Self-Managed dans GitLab 18.5.
- Le feature flag `ai_duo_agent_fix_pipeline_button` [activé par défaut](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/205086) dans GitLab 18.5.
- [Passage en disponibilité générale](https://gitlab.com/gitlab-org/gitlab/-/work_items/585273) dans GitLab 18.8. Le feature flag `ai_duo_agent_fix_pipeline_button` a été [supprimé](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/216681). Le feature flag `duo_workflow_in_ci` a été supprimé dans GitLab 18.9.
- Disponible sur l’édition Gratuite sur GitLab.com avec des GitLab Credits dans GitLab 18.10.
- Les corrections apportées aux pipelines associés à une merge request ont [été modifiées](https://gitlab.com/groups/gitlab-org/-/work_items/21837) pour s'appliquer en tant que suggestions de code dans GitLab 19.1 [avec un feature flag](../../../../administration/feature_flags/_index.md) nommé `fix_pipeline_next`. Activé sur GitLab.com pour un sous-ensemble d'utilisateurs.
- [Passage en disponibilité générale](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/241608) dans GitLab 19.2. Le feature flag `fix_pipeline_next` a été supprimé.

{{< /history >}}

Le flow Fix CI/CD Pipeline diagnostique et propose des corrections pour les problèmes de votre pipeline CI/CD GitLab. Pour diagnostiquer les échecs, le flow examine :

- Les logs du pipeline, notamment les messages d'erreur, les sorties des jobs en échec et les codes de sortie.
- Les modifications de la merge request qui auraient pu causer l'échec.
- Le contenu du dépôt, pour identifier les erreurs de syntaxe, de linting ou d'importation.
- Les erreurs de script, notamment les échecs de commandes, les exécutables manquants ou les problèmes de permissions.

La façon dont le flow applique les corrections dépend du contexte du pipeline :

- Si le pipeline est associé à une merge request, le flow applique des suggestions de code en ligne sur la branche source. Vous pouvez examiner et appliquer les suggestions directement depuis la merge request.
  - Si la correction nécessite des modifications de fichiers en dehors du diff de la merge request actuelle, le flow crée une nouvelle merge request à la place.
- Si le pipeline n'est pas associé à une merge request, le flow crée une nouvelle merge request contenant la correction.

Dans certains cas, au lieu de tenter une correction, le flow publie un commentaire décrivant l'échec et les prochaines étapes possibles. Cela se produit lorsque le pipeline est associé à une merge request, par exemple :

- Le contexte est insuffisant pour déterminer une correction fiable.
- L'échec est sensible du point de vue de la sécurité et doit être examiné par une personne.
- La catégorie d'échec ne peut pas être traitée par le flow.

Lorsqu'une session démarre et se termine, le flow publie des notes système dans la merge request avec un lien vers la session. Ce flow est disponible uniquement dans l'interface utilisateur de GitLab.

Ce flow est le chemin recommandé si vous utilisez la GitLab Duo Agent Platform et souhaitez corriger automatiquement un pipeline en échec. Il s'agit d'une expérience distincte de [Root Cause Analysis](../../../gitlab_duo_chat/examples.md#troubleshoot-failed-cicd-jobs-with-root-cause-analysis), une fonctionnalité de GitLab Duo Chat pour résoudre les échecs de jobs individuels.

## Prérequis {#prerequisites}

- Satisfaire aux [prérequis pour GitLab Duo Agent Platform](../../_index.md#prerequisites).
- Activez **Autoriser les flows par défaut** et **Corriger un pipeline CI/CD** [pour le groupe principal](_index.md#turn-foundational-flows-on-or-off).
- Disposer du rôle Développeur, Chargé de maintenance ou Propriétaire pour le projet.
- Disposer d'un pipeline en échec existant.
- [Configurer les règles push pour autoriser un compte de service](../../troubleshooting.md#configure-push-rules-to-allow-a-service-account).
- [Configurer vos propres runners](../execution.md#configure-runners-to-execute-flows) ou activer les [runners hébergés par GitLab](../../../../ci/runners/hosted_runners/_index.md) pour votre projet.

## Réparer le pipeline dans une merge request {#fix-the-pipeline-in-a-merge-request}

{{< history >}}

- [Introduction](https://gitlab.com/groups/gitlab-org/-/work_items/20484) de l'utilisation d'un flow dans une conversation GitLab Duo Agentic Chat dans GitLab 19.2 [avec un feature flag](../../../../administration/feature_flags/_index.md) nommé `agentic_foundational_flow_tool`. Activé par défaut.

{{< /history >}}

> [!flag]
> Un feature flag contrôle la disponibilité de cette fonctionnalité. Pour plus d'informations, consultez l'historique.

Pour corriger le pipeline CI/CD dans une merge request :

1. Dans la barre supérieure, sélectionnez **Rechercher ou accédez à** et repérez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Code** > **Requêtes de fusion** et ouvrez votre merge request.
1. Utilisez l'une de ces méthodes pour corriger le pipeline :
   - Sélectionnez l'onglet **Vue d'ensemble** et, sous le pipeline en échec, sélectionnez **Réparer le pipeline avec GitLab Duo**.
   - Sélectionnez l'onglet **Pipelines** et, dans la colonne la plus à droite, sélectionnez **Réparer le pipeline avec GitLab Duo** ({{< icon name="tanuki-ai" >}}).
   - Dans la barre latérale GitLab Duo, ouvrez une conversation Agentic Chat nouvelle ou existante. Demandez à Agentic Chat de corriger le pipeline.
1. Pour surveiller la progression, dans la barre latérale gauche, sélectionnez **IA** > **Sessions**.

   Si vous êtes dans Agentic Chat, vous pouvez également effectuer les actions suivantes :
   - Voir la progression dans la conversation Chat.
   - Sélectionnez **View Agent Session** dans la conversation.

Lorsque la session est terminée, le flow ajoute des suggestions de code à la merge request, ou un commentaire décrit les prochaines étapes possibles.

## Corriger d'autres pipelines CI/CD {#fix-other-cicd-pipelines}

Pour corriger un pipeline CI/CD qui n'est pas associé à une merge request :

1. Sélectionnez **Version** > **Pipelines**.
1. Sélectionnez votre pipeline en échec.
1. Dans le coin supérieur droit, sélectionnez **Réparer le pipeline avec GitLab Duo**.
1. Pour surveiller la progression, sélectionnez **IA** > **Sessions**.

## Utiliser `AGENTS.md` pour personnaliser le flow {#use-agentsmd-to-customize-the-flow}

Le flow lit les instructions spécifiques au dépôt depuis un fichier [`AGENTS.md`](../../customize/agents_md.md) dans votre dépôt. Vous pouvez utiliser `AGENTS.md` pour personnaliser le comportement, par exemple :

- Le format du message de commit pour les modifications que le flow effectue.
- Les métadonnées de merge request, telles que les labels et la description, pour les merge requests que le flow crée.
- Comment classifier et traiter des types d'échecs spécifiques.

Par exemple :

```markdown
## Fix pipeline merge requests

When opening a merge request as part of the Fix Pipeline flow (the title contains [FixPipeline]),
apply labels based on the following failed pipeline scenarios:

- Pipeline failed on merge_request: apply "pipeline::tier-1". This runs the cheaper tier-1
  pipeline instead of the full default pipeline.
- Pipeline failed on the default_branch (main): apply both "pipeline::expedited" and
  "main:broken". Do not apply pipeline::tier-1 in this case.
- Pipeline failed on other branches: apply "pipeline::tier-1". Same treatment as the
  merge_request case.
```

## Problèmes connus {#known-issues}

- La passerelle d'IA traite uniquement les 150 derniers Kio des job logs. Si votre job produit une sortie volumineuse, le flow pourrait ne pas capturer les informations d'échec pertinentes qui apparaissent plus tôt dans le log. Consultez la section suivante pour les solutions de contournement.
- Le flow ne peut pas toujours vérifier l'installation des packages dans l'environnement d'exécution sandboxé. Si des dépendances sont manquantes, vous pouvez personnaliser l'image du flow par défaut. Consultez [modifier l'image Docker par défaut](../execution.md#change-the-default-docker-image).
- Les instructions du dépôt dans `AGENTS.md` influencent le comportement du flow, mais leur application n'est pas garantie dans tous les cas.

## Dépannage {#troubleshooting}

Lorsque vous travaillez avec le flow Fix CI/CD Pipeline, vous pouvez rencontrer les problèmes suivants.

### Le flow ne parvient pas à identifier la cause première d'un échec {#flow-cannot-identify-the-root-cause-of-a-failure}

Le flow pourrait ne pas identifier la cause première d'un échec de pipeline.

Ce problème se produit lorsque les job logs dépassent 150 Kio. La passerelle d'IA traite uniquement les 150 derniers Kio, de sorte que les informations d'échec pertinentes apparaissant plus tôt dans le log pourraient ne pas être capturées.

Pour contourner ce problème, essayez les solutions suivantes :

- Réduisez la sortie verbose en supprimant les journaux de débogage et les indicateurs de progression.
- Redirigez les sorties non critiques à l'aide de la redirection shell (`> /dev/null`).
- Ajoutez une étape de synthèse à la fin de votre script qui affiche les messages d'erreur clés.
- Utilisez `after_script` pour afficher des informations de diagnostic après la fin du script principal.
- Divisez les jobs verbeux en jobs plus petits et ciblés avec des logs plus concis.

## Donner votre avis {#give-feedback}

L'équipe améliore activement le flow Fix CI/CD Pipeline. Pour signaler des problèmes ou suggérer des améliorations, laissez vos commentaires dans le [ticket de retours 601991](https://gitlab.com/gitlab-org/gitlab/-/work_items/601991).
