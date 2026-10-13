---
stage: Agent Foundations
group: Agent Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "Comprenez le modèle de sécurité des flows dans CI/CD, les risques liés au fichier de configuration de l'agent et les protections recommandées."
title: "Considérations de sécurité pour l'exécution des flows"
---

{{< details >}}

- Édition : [Gratuite](../../../../subscriptions/gitlab_credits.md#for-the-free-tier), GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Lorsque les flows s'exécutent dans GitLab CI/CD :

- Ils utilisent une [identité composite](../../composite_identity.md) pour limiter les accès.
- Ils créent un [pipeline de charge de travail](../../../../ci/pipelines/pipeline_types.md#workload-pipeline) éphémère, qui est supprimé lorsque le flow est terminé.
- Les outils à leur disposition sont spécifiques à l'objectif du flow. Ces outils peuvent inclure la création de merge requests ou l'exécution de commandes shell locales dans leur environnement d'exécution.

Par défaut, les flows ont accès au réseau uniquement vers l'instance GitLab. Pour plus d'informations sur les règles d'accès réseau, voir [comment configurer une politique réseau](../../environment_sandbox.md#configure-a-network-policy). Cet environnement séparé protège contre les conséquences involontaires de l'exécution de commandes shell.

Pour empêcher les flows de s'exécuter de manière autonome dans l'interface utilisateur GitLab, vous pouvez [désactiver l'exécution des flows](../foundational_flows/_index.md#turn-foundational-flows-on-or-off).

## Implications de sécurité de `agent-config.yml` {#security-implications-of-agent-configyml}

Le fichier `.gitlab/duo/agent-config.yml` contrôle la façon dont les flows s'exécutent dans CI/CD, y compris les commandes qui s'exécutent dans `setup_script`. En raison du fonctionnement des flows, les modifications apportées à ce fichier ont des répercussions qui vont au-delà de l'utilisateur qui les valide.

### Exécution entre utilisateurs {#cross-user-execution}

Les flows s'exécutent sous l'identité de l'utilisateur qui les déclenche via l'[identité composite](../../composite_identity.md). Les commandes dans `setup_script` s'exécutent avec les identifiants d'identité composite de l'utilisateur déclencheur, et non avec les identifiants de l'utilisateur qui a validé la configuration.

Un utilisateur disposant d'un accès en écriture sur `.gitlab/duo/agent-config.yml` peut influencer ce qui s'exécute dans l'environnement runner d'un autre utilisateur. Les modifications apportées à ce fichier affectent le contexte d'exécution de chaque utilisateur qui déclenche ultérieurement un flow dans le projet.

### Variables d'environnement exposées {#exposed-environment-variables}

Lors de l'exécution de `setup_script`, qui s'exécute en dehors d'Anthropic Sandbox Runtime (SRT), les variables sensibles suivantes sont présentes dans l'environnement :

- `GITLAB_OAUTH_TOKEN` et `GITLAB_TOKEN` : le jeton OAuth de l'utilisateur déclencheur via l'identité composite.
- `DUO_WORKFLOW_GIT_HTTP_PASSWORD` : le mot de passe HTTP Git.
- `DUO_WORKFLOW_SERVICE_TOKEN` : le jeton de service.
- `DUO_WORKFLOW_GIT_USER_EMAIL` et `DUO_WORKFLOW_GIT_USER_NAME` : l'adresse e-mail et le nom de l'utilisateur déclencheur.

Pour la liste complète des variables exposées, voir [les variables d'exécution des flows](execution-variables.md).

### Protections recommandées {#recommended-protections}

Pour réduire le risque de modifications non autorisées du fichier `.gitlab/duo/agent-config.yml` :

- [Protégez votre branche par défaut](../../../project/repository/branches/protected.md) pour empêcher les pushs directs.
- Utilisez les [propriétaires du code](../../../project/codeowners/_index.md) pour exiger l'approbation de propriétaires spécifiques avant que les modifications apportées à `.gitlab/duo/agent-config.yml` soient fusionnées. Par exemple, ajoutez ce qui suit à votre fichier `CODEOWNERS` :

  ```plaintext
  .gitlab/duo/agent-config.yml @your-group/security-reviewers
  ```

- Configurez des [règles d'approbation](../../../project/merge_requests/approvals/rules.md) qui exigent une revue de la part de responsables de confiance pour les merge requests qui modifient ce fichier.
