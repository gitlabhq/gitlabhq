---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "Calculs, quotas, informations d'achat."
title: Administration des minutes de calcul
---

{{< details >}}

- Niveau : Premium, Ultimate
- Offre : GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Renommé](https://gitlab.com/groups/gitlab-com/-/epics/2150) de « minutes CI/CD » en « quota de calcul » ou « minutes de calcul » dans GitLab 16.1.

{{< /history >}}

Les administrateurs peuvent limiter le temps que les projets peuvent utiliser pour exécuter des jobs sur les [runners d'instance](../../ci/runners/runners_scope.md) chaque mois. Cette limite est suivie avec un [quota de minutes de calcul](../../ci/pipelines/compute_minutes.md). Les runners de groupe et de projet ne sont pas soumis au quota de calcul.

Sur GitLab Self-Managed :

- Les quotas de calcul sont désactivés par défaut.
- Les administrateurs peuvent [attribuer plus de minutes de calcul](#set-the-compute-quota-for-a-group) si un espace de nommage utilise tout son quota mensuel.
- Le [facteur de coût](../../ci/pipelines/compute_minutes.md#compute-usage-calculation) est `1` pour tous les projets.

Sur GitLab.com :

- Pour en savoir plus sur les quotas et les facteurs de coût appliqués, consultez [les minutes de calcul](../../ci/pipelines/compute_minutes.md).
- Pour gérer les minutes de calcul en tant que membre de l'équipe GitLab, consultez [l'administration des minutes de calcul pour GitLab.com](dot_com_compute_minutes.md).

Les [jobs de déclenchement](../../ci/yaml/_index.md#trigger) ne s'exécutent pas sur les runners, ils ne consomment donc pas de minutes de calcul, même lorsque vous utilisez [`strategy:depend`](../../ci/yaml/_index.md#triggerstrategy) pour attendre le statut du [pipeline downstream](../../ci/pipelines/downstream_pipelines.md). Le pipeline downstream déclenché consomme des minutes de calcul de la même façon que les autres pipelines.

## Définir le quota de calcul pour tous les espaces de nommage {#set-the-compute-quota-for-all-namespaces}

Par défaut, les instances GitLab n'ont pas de quota de calcul. La valeur par défaut du quota est `0`, ce qui signifie illimité.

Prérequis :

- Vous devez être administrateur GitLab.

Pour modifier le quota par défaut qui s'applique à tous les espaces de nommage :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **CI/CD**.
1. Développez **Intégration et déploiement continus**.
1. Dans le champ **Quota de calcul**, saisissez une limite.
1. Sélectionnez **Sauvegarder les modifications**.

Si un quota est déjà défini pour un espace de nommage spécifique, cette valeur ne modifie pas ce quota.

## Définir le quota de calcul pour un groupe {#set-the-compute-quota-for-a-group}

Vous pouvez remplacer la valeur globale et définir un quota de calcul pour un groupe.

Prérequis :

- Vous devez être administrateur GitLab.
- Le groupe doit être un groupe principal, et non un sous-groupe.

Pour définir un quota de calcul pour un groupe ou un espace de nommage :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Vue d'ensemble** > **Groupes**.
1. Pour le groupe que vous souhaitez mettre à jour, sélectionnez **Éditer**.
1. Dans le champ **Quota de calcul**, saisissez le nombre maximum de minutes de calcul.
1. Sélectionnez **Sauvegarder les modifications**.

Vous pouvez également utiliser l'[API de mise à jour de groupe](../../api/groups.md#update-group-attributes) ou l'[API de mise à jour d'utilisateur](../../api/users.md#modify-a-user) à la place.

## Réinitialiser la quantité d'unités de calcul utilisée {#reset-compute-usage}

Un administrateur peut réinitialiser la quantité d'unités de calcul utilisée pour un espace de nommage pour le mois en cours.

### Réinitialiser l'utilisation pour un espace de nommage personnel {#reset-usage-for-a-personal-namespace}

1. Trouvez l'[utilisateur dans la zone **Admin**](../admin_area.md#administering-users).
1. Sélectionnez **Éditer**.
1. Dans **Limites**, sélectionnez **Réinitialiser la quantité d'unités de calcul utilisée**.

### Réinitialiser l'utilisation pour un espace de nommage de groupe {#reset-usage-for-a-group-namespace}

1. Trouvez le [groupe dans la zone **Admin**](../admin_area.md#administering-groups).
1. Sélectionnez **Éditer**.
1. Dans **Permissions et fonctionnalités du groupe**, sélectionnez **Réinitialiser la quantité d'unités de calcul utilisée**.
