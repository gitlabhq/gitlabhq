---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Limites de débit sur la création de pipeline
---

{{< details >}}

- Niveau :  Free, Premium, Ultimate
- Offre :  GitLab Self-Managed

{{< /details >}}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/362475) dans GitLab 15.0 [avec un indicateur](../feature_flags/_index.md) nommé `ci_enforce_throttle_pipelines_creation`. Désactivé par défaut. Activé sur GitLab.com
- [Activé par défaut](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/196545) dans la version 18.3.

{{< /history >}}

Vous pouvez définir des limites afin que les utilisateurs et les processus ne puissent pas demander plus d'un certain nombre de pipelines par minute. Ces limites peuvent aider à économiser des ressources et à améliorer la stabilité.

GitLab applique deux types de limites de débit pour la création de pipeline :

- **Per project, commit, and user** :  Limite les pipelines créés pour la même combinaison de projet, de SHA de commit et d'utilisateur. Désactivé par défaut.
- **Per user** :  Limite le nombre total de pipelines créés par un utilisateur dans tous les projets. Désactivé par défaut.

Par exemple, si vous définissez une limite de débit par utilisateur de `100`, et qu'un utilisateur envoie `101` demandes de création de pipeline à l'[API de déclenchement](../../ci/triggers/_index.md) en une minute sur différents projets, la 101e demande est bloquée. L'accès au point de terminaison est à nouveau autorisé après une minute.

Ces limites ne sont pas appliquées par adresse IP.

Les demandes dépassant les limites sont consignées dans le fichier `application_json.log`.

## Définir des limites de demandes de pipeline {#set-pipeline-request-limits}

Prérequis :

- Accès administrateur.

Pour limiter le nombre de demandes de pipeline :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Réseau**.
1. Développez **Pipelines Rate Limits**.
1. Sous **Max requests per minute per project, user, and commit**, saisissez une valeur supérieure à `0` pour limiter les pipelines pour la même combinaison de projet, de commit et d'utilisateur.
1. Sous **Max requests per minute per user**, saisissez une valeur supérieure à `0` pour limiter le nombre total de pipelines créés par chaque utilisateur. Définissez la valeur à 0 pour des demandes illimitées par minute.
1. Sélectionnez **Sauvegarder les modifications**.

## Fonctionnement conjoint des limites {#how-the-limits-work-together}

Les deux limites de débit sont évaluées indépendamment :

- Un utilisateur créant plusieurs pipelines pour le même SHA de commit dans un projet est soumis à la limite **per project, user, and commit**.
- Un utilisateur créant des pipelines dans différents projets ou commits est soumis à la limite **par utilisateur**.
- Si l'une ou l'autre des limites est dépassée, la demande de création de pipeline est bloquée.
