---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
gitlab_dedicated: yes
description: Configurez la taille maximale du diff à afficher sur GitLab Self-Managed.
title: Administration des limites du diff
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Afficher le contenu complet de fichiers volumineux peut ralentir les merge requests. Pour éviter cela, vous pouvez configurer des limites pour les diffs affichés dans les merge requests, notamment la taille maximale du diff, le nombre de fichiers modifiés, le nombre de lignes modifiées, les versions de diff et les commits de diff. Ces limites s'appliquent à la fois à l'interface utilisateur GitLab et aux endpoints API qui renvoient des informations de diff.

Lorsqu'un diff atteint 10 % de la taille maximale du correctif diff, du nombre maximal de fichiers diff ou des valeurs de lignes diff maximales, GitLab affiche les fichiers dans une vue réduite avec un lien pour développer le diff. Les diffs qui dépassent l'une de ces trois valeurs sont affichés comme **Trop volumineux**, et vous ne pouvez pas les développer dans l'interface utilisateur.

Les valeurs de versions de diff maximales et de commits de diff maximaux limitent les mises à jour des merge requests. Les merge requests qui atteignent ces limites ne peuvent plus être mises à jour :

| Valeur                       | Définition                                                              | Valeur par défaut | Valeur maximale |
|-----------------------------|-------------------------------------------------------------------------|:-------------:|:-------------:|
| **Taille maximale du correctif diff** | La taille totale, en octets, du diff entier.                           |    200 Ko     |    500 Ko     |
| **Maximum diff files**      | Le nombre total de fichiers modifiés dans un diff.                            |     1000      |     3000      |
| **Maximum diff lines**      | Le nombre total de lignes modifiées dans un diff.                            |    50 000     |    100 000    |
| **Maximum diff versions**   | Le nombre de versions de diff par merge request.                          |     1 000     |     Aucune      |
| **Maximum diff commits**    | Le nombre total de commits de diff dans toutes les versions par merge request. |   1 000 000   |     Aucune      |

[Les limites du diff ne peuvent pas être configurées](../user/gitlab_com/_index.md#diff-display-limits) sur GitLab.com.

Pour plus de détails sur les fichiers diff, [consultez les modifications entre les fichiers](../user/project/merge_requests/changes.md). En savoir plus sur les [limites intégrées pour les merge requests et les diffs](instance_limits.md#merge-requests).

## Configurer les limites du diff {#configure-diff-limits}

> [!warning]
> Ces paramètres sont expérimentaux. Une valeur maximale accrue augmente la consommation de ressources de votre instance. Gardez cela à l'esprit lors de l'ajustement du maximum.

Prérequis :

- Accès administrateur.

Pour définir les valeurs maximales pour l'affichage des diffs dans les merge requests :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Général**.
1. Développez **Limites du diff**.
1. Saisissez une valeur pour la limite du diff.
1. Sélectionnez **Sauvegarder les modifications**.
