---
stage: AI Coding
group: Code Review
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Dépannage du flow Code Review
---

Lorsque vous utilisez le flow Code Review, vous pourriez rencontrer les problèmes suivants.

## `Error DCR4000` {#error-dcr4000}

Vous pouvez obtenir une erreur indiquant `Code Review Flow is not enabled. Contact your group administrator to enable the foundational flow in the top-level group. Error code: DCR4000`.

Cette erreur se produit lorsque les [flows par défaut](../_index.md) ou le flow Code Review sont désactivés.

Contactez votre administrateur et demandez-lui d'activer le flow Code Review pour votre groupe principal.

## `Error DCR4001` {#error-dcr4001}

Vous pouvez obtenir une erreur indiquant `Code Review Flow is enabled but the service account needs to be verified. Contact your administrator. Error code: DCR4001`.

Cette erreur se produit lorsque le flow Code Review est activé, mais que le compte de service du groupe principal n'existe pas ou n'est pas prêt.

Demandez à votre administrateur de [vérifier que le compte de service existe](../../../troubleshooting.md#foundational-flow-service-account-not-created) et de suivre les étapes pour résoudre les problèmes éventuels.

## `Error DCR4002` {#error-dcr4002}

Vous pouvez obtenir une erreur indiquant `No GitLab Credits remain for this billing period. To continue using Code Review Flow, contact your administrator. Error code: DCR4002`.

Cette erreur se produit lorsque vous avez utilisé tous les GitLab Credits qui vous ont été attribués pour la période de facturation en cours.

Contactez votre administrateur pour acheter des crédits supplémentaires ou attendez que vos crédits soient réinitialisés au début de la prochaine période de facturation.

## `Error DCR4003` {#error-dcr4003}

Vous pouvez obtenir une erreur indiquant `<User>, you don't have permission to create a pipeline for Code Review Flow in this project. Contact your administrator to update your permissions. Error code: DCR4003`.

Cette erreur se produit parce que le flow Code Review s'exécute dans un pipeline CI/CD et que vous n'avez pas l'autorisation de créer des pipelines dans ce projet.

Contactez votre administrateur et demandez-lui de vous accorder les [autorisations requises pour exécuter des pipelines](../../../../permissions.md).

## `Error DCR4004` {#error-dcr4004}

Vous pouvez obtenir une erreur indiquant `<User>, you need to set a default GitLab Duo namespace to use Code Review Flow in this project. Please set a default GitLab Duo namespace in your preferences. Error code: DCR4004`.

Cette erreur se produit lorsque GitLab Duo ne parvient pas à identifier l'espace de nommage GitLab Duo par défaut de la personne qui a lancé la revue.

Définissez un espace de nommage GitLab Duo par défaut dans vos [préférences](../../../../profile/preferences.md#set-a-default-gitlab-duo-namespace), puis demandez à nouveau une revue.

## `Error DCR4005` {#error-dcr4005}

Vous pouvez obtenir une erreur indiquant `Code Review Flow could not obtain the required authentication tokens to connect to the GitLab AI Gateway and the GitLab API. Please request a new review. If the issue persists, contact your administrator. Error code: DCR4005`.

Le flow Code Review nécessite des jetons d'authentification pour se connecter à la passerelle d'IA GitLab et à l'API GitLab. Cette erreur se produit lorsque ces jetons ne peuvent pas être générés, généralement en raison d'une configuration GitLab Duo incorrecte ou d'un problème temporaire d'infrastructure.

Pour les instances autogérées, demandez à votre administrateur de vérifier la [configuration de GitLab Duo](../../../../../administration/gitlab_duo/configure/_index.md).

## `Error DCR4006` {#error-dcr4006}

Vous pouvez obtenir une erreur indiquant `Code Review Flow could not add the service account to this project. Contact your administrator to verify that the service account has the required project access. Error code: DCR4006`.

Cette erreur se produit lorsque le compte de service ne peut pas être ajouté comme membre du projet. Cela peut se produire lorsqu'un verrouillage de l'appartenance au groupe est activé ou lorsque le compte de service ne dispose pas de l'accès requis.

Contactez votre administrateur et demandez-lui de vérifier que le compte de service peut être ajouté au projet avec le rôle Développeur.

## `Error DCR4007` {#error-dcr4007}

Vous pouvez obtenir une erreur indiquant `Code Review Flow is not available for this project. Contact your administrator to verify that the flow is enabled and the required configuration is in place. Error code: DCR4007`.

Cette erreur se produit lorsque le flow est désactivé ou que la configuration requise pour le projet est manquante.

Contactez votre administrateur et demandez-lui de vérifier que [le flow est activé](../_index.md#turn-foundational-flows-on-or-off) pour le projet.

## `Error DCR4008` {#error-dcr4008}

Vous pouvez obtenir une erreur indiquant `Code Review Flow could not create the required CI/CD pipeline. Please request a new review. If the problem persists, contact your administrator. Error code: DCR4008`.

Cette erreur se produit lorsque le flow Code Review ne peut pas créer ou configurer le pipeline CI/CD chargé d'exécuter la revue, en raison de problèmes de disponibilité des runners ou de problèmes de configuration interne.

Essayez de relancer la revue. Si l'erreur persiste, contactez votre administrateur.

## `Error DCR4009` {#error-dcr4009}

Vous pouvez obtenir une erreur indiquant `Code Review Flow could not retrieve the source branch for this merge request. Please request a new review. Error code: DCR4009`.

Cette erreur se produit lorsque le flow Code Review ne parvient pas à récupérer la branche source de la merge request.

Essayez de relancer la revue.

## `Error DCR4011` {#error-dcr4011}

Vous pouvez obtenir une erreur indiquant `Code Review Flow could not start because the project has no runner available. It needs an instance runner or a top-level group runner with the gitlab--duo tag and a Docker-compatible executor. Error code: DCR4011`.

Cette erreur se produit lorsque le flow Code Review s'exécute sur un pipeline CI/CD, mais qu'aucun runner éligible n'est disponible. Les flows nécessitent un runner d'instance ou un runner de groupe assigné au groupe principal, avec le tag `gitlab--duo` et un exécuteur compatible Docker.

Pour connaître les exigences complètes relatives aux runners et savoir comment en configurer un, consultez [Le job ou la session d'un flow échoue au démarrage](../../../troubleshooting.md#a-flows-job-or-session-fails-to-start).

## `Error DCR4012` {#error-dcr4012}

Vous pouvez obtenir une erreur indiquant `Code Review Flow could not start because the namespace has run out of compute minutes. Ask someone with billing access to add compute minutes before trying again. Error code: DCR4012`.

Cette erreur se produit lorsque l'espace de nommage a utilisé l'intégralité de ses minutes de calcul, ce qui supprime également l'accès aux runners hébergés (d'instance). Les runners de projet et de groupe principal ne sont pas affectés.

Demandez à une personne disposant d'un accès à la facturation d'ajouter des minutes de calcul, puis demandez un nouvel examen. Pour plus de détails, consultez [Le job ou la session d'un flow échoue au démarrage](../../../troubleshooting.md#a-flows-job-or-session-fails-to-start).

## `Error DCR5000` {#error-dcr5000}

Vous pouvez obtenir une erreur indiquant `Something went wrong while starting Code Review Flow. Please try again later. Error code: DCR5000`.

Cette erreur se produit lorsque GitLab Duo Agent Platform ne parvient pas à démarrer le flow Code Review en raison d'une erreur interne.

Essayez de relancer la revue. Si l'erreur persiste, contactez votre administrateur.

## `Error DCR5001` {#error-dcr5001}

Vous pouvez obtenir une erreur indiquant `Code Review Flow completed the review but could not post the review comments. Please request a new review to try again. Error code: DCR5001`.

Cette erreur se produit lorsque le flow Code Review termine la revue mais, après plusieurs tentatives, ne peut pas publier les commentaires de revue. Cela est souvent dû à des problèmes d'infrastructure transitoires.

Demandez une nouvelle revue. Si l'erreur persiste, contactez votre administrateur.

## Contexte manquant dans les revues de merge requests volumineuses {#missing-context-in-large-merge-request-reviews}

Le flow Code Review peut ne pas tenir compte de tout le contexte lorsqu'une merge request contient de nombreux fichiers modifiés de grande taille.

Cela peut se produire lorsque les résultats du pré-scan dépassent les [limites de fichiers et de contexte](_index.md#file-and-context-limits) et que les données sont tronquées avant l'examen.

Pour améliorer la revue :

- Divisez la merge request en merge requests plus petites.
- [Excluez le contexte](../../../context.md#exclude-context-from-gitlab-duo) des fichiers qui ne sont pas pertinents pour la revue
- Demandez à un propriétaire de groupe ou à un administrateur d'instance de sélectionner un modèle différent pour [GitLab.com](../../../model_selection.md#select-a-model-for-a-feature) ou [GitLab Self-Managed et GitLab Dedicated](../../../../../administration/gitlab_duo/model_selection.md#select-a-model-for-code-review-flow).

## Script de diagnostic de configuration {#configuration-diagnostic-script}

Si vous ne parvenez pas à identifier la cause d'un problème du flow Code Review à partir des codes d'erreur documentés, vous pouvez exécuter un script de diagnostic pour vérifier votre configuration GitLab Duo.

Le script vérifie toute la chaîne de configuration requise pour le flow Code Review, notamment les vérifications applicables à toutes les fonctionnalités de GitLab Duo Agent Platform.

Pour en savoir plus, consultez la section [Exécuter le script de diagnostic de configuration](../../../troubleshooting.md#run-the-configuration-diagnostic-script).
