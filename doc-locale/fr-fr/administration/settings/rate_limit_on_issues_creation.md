---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: "Limites de débit sur la création de tickets et d'epics"
---

{{< details >}}

- Niveau :  Free, Premium, Ultimate
- Offre :  GitLab Self-Managed

{{< /details >}}

Les limites de débit contrôlent la cadence à laquelle de nouveaux epics et tickets peuvent être créés. Par exemple, si vous définissez la limite à `300`, l'action [`Projects::IssuesController#create`](https://gitlab.com/gitlab-org/gitlab/blob/master/app/controllers/projects/issues_controller.rb) bloque les requêtes qui dépassent un débit de 300 par minute. L'accès au point de terminaison est disponible après une minute.

## Définir la limite de débit {#set-the-rate-limit}

Prérequis :

- Accès administrateur.

Pour limiter le nombre de requêtes effectuées vers les points de terminaison de création de tickets et d'epics :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Réseau**.
1. Développez **Issues Rate Limits**.
1. Sous **Max requests per minute**, saisissez la nouvelle valeur.
1. Sélectionnez **Sauvegarder les modifications**.

![La limite de débit du nombre maximum de requêtes par minute par utilisateur définie à 300.](img/rate_limit_on_issues_creation_v14_2.png)

La limite pour la création d'[epic](../../user/group/epics/_index.md) est la même que celle appliquée à la création de tickets. La limite de débit :

- Est appliquée indépendamment par projet et par utilisateur.
- N'est pas appliquée par adresse IP.
- Peut être définie à `0` pour désactiver la limite de débit.

Les requêtes dépassant la limite de débit sont consignées dans le fichier `auth.log`.
