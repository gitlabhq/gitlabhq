---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
gitlab_dedicated: yes
title: Multiplicateur de la fréquence de scrutation
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

L'interface utilisateur GitLab scrute les mises à jour de différentes ressources (telles que les notes de ticket, les titres de ticket et les statuts de pipeline) selon une planification adaptée à la ressource.

Ajustez le multiplicateur de ces planifications pour modifier la fréquence à laquelle l'interface utilisateur GitLab scrute les mises à jour. Si vous définissez le multiplicateur sur :

- Une valeur supérieure à `1`, la scrutation de l'interface utilisateur ralentit. Si vous constatez des problèmes de charge de base de données liés à un grand nombre de clients scrutation des mises à jour, augmenter le multiplicateur peut être une bonne alternative à la désactivation complète de la scrutation. Par exemple, si vous définissez la valeur sur `2`, tous les intervalles de scrutation sont multipliés par 2, ce qui signifie que la scrutation se produit deux fois moins fréquemment.
- Une valeur comprise entre `0` et `1`, l'interface utilisateur effectue des scrutation plus fréquentes, de sorte que les mises à jour se produisent plus souvent. **Non recommandé**.
- `0`, toute scrutation est désactivée. Au prochain sondage, les clients cessent d'effectuer des scrutation des mises à jour.

La valeur par défaut (`1`) est recommandée pour la majorité des installations GitLab.

## Configurer {#configure}

Prérequis :

- Accès administrateur.

Pour ajuster le multiplicateur de la fréquence de scrutation :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Préférences**.
1. Développez **Multiplicateur de la fréquence de scrutation**.
1. Définissez une valeur pour le multiplicateur de la fréquence de scrutation. Ce multiplicateur est appliqué à toutes les ressources simultanément.
1. Sélectionnez **Sauvegarder les modifications**.
