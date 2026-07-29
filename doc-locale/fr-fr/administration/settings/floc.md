---
stage: Facilitated functionality
group: Facilitated functionality
info: For more information, see <https://handbook.gitlab.com/handbook/product/categories/#facilitated-functionality>
title: Federated Learning of Cohorts (FLoC)
---

{{< details >}}

- Niveau :  Free, Premium, Ultimate
- Offre :  GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Federated Learning of Cohorts (FLoC) était une fonctionnalité proposée pour Google Chrome qui catégorisait les utilisateurs en différentes cohortes pour la publicité basée sur les centres d'intérêt. FLoC a été remplacé par l'[API Topics](https://patcg-individual-drafts.github.io/topics/), qui offre des fonctionnalités similaires pour aider les annonceurs à cibler et à suivre les utilisateurs.

Par défaut, GitLab refuse le suivi des utilisateurs à des fins de publicité basée sur les centres d'intérêt en envoyant l'en-tête suivant :

```plaintext
Permissions-Policy: interest-cohort=()
```

Cet en-tête empêche les utilisateurs d'être suivis et catégorisés dans toute instance GitLab. L'en-tête est compatible avec l'API Topics et le système FLoC obsolète.

Prérequis :

- Accès administrateur.

Pour activer le suivi des utilisateurs à des fins de publicité basée sur les centres d'intérêt :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Général**.
1. Développez **Federated Learning of Cohorts (FLoC)**.
1. Cochez la case **Participer aux FLoC**.
1. Sélectionnez **Sauvegarder les modifications**.
