---
stage: Facilitated functionality
group: Facilitated functionality
info: For more information, see <https://handbook.gitlab.com/handbook/product/categories/#facilitated-functionality>
gitlab_dedicated: yes
title: "Conditions générales d'utilisation et politique de confidentialité"
---

{{< details >}}

- Niveau :  Free, Premium, Ultimate
- Offre :  GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Un administrateur peut imposer l'acceptation de conditions générales d'utilisation et d'une politique de confidentialité. Lorsque cette option est activée, les nouveaux utilisateurs et les utilisateurs existants doivent accepter les conditions.

Lorsque cette option est activée, vous pouvez consulter les Conditions générales d'utilisation à la page `-/users/terms` de l'instance, par exemple `https://gitlab.example.com/-/users/terms`.

Le lien `Terms and privacy` deviendra visible dans le menu d'aide si des conditions sont définies.

## Appliquer des Conditions générales d'utilisation et une politique de confidentialité {#enforce-a-terms-of-service-and-privacy-policy}

Pour imposer l'acceptation de Conditions générales d'utilisation et d'une politique de confidentialité :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Général**.
1. Développez la section **Conditions générales d'utilisation et politique de confidentialité**.
1. Cochez la case **Tous les utilisateurs doivent accepter les Conditions Générales d'Utilisation et la Politique de Confidentialité pour accéder à GitLab**.
1. Saisissez le texte des **Conditions générales d'utilisation et politique de confidentialité**. Vous pouvez utiliser [Markdown](../../user/markdown.md) dans cette zone de texte.
1. Sélectionnez **Sauvegarder les modifications**.

À chaque mise à jour des conditions, une nouvelle version est enregistrée. Lorsqu'un utilisateur accepte ou refuse les conditions, GitLab enregistre la version qu'il a acceptée ou refusée.

Les utilisateurs existants doivent accepter les conditions lors de leur prochaine interaction avec GitLab. Si un utilisateur authentifié refuse les conditions, il est déconnecté.

Lorsque cette option est activée, une case à cocher obligatoire est ajoutée à la page d'inscription pour les nouveaux utilisateurs :

![Formulaire de création de compte avec une case à cocher obligatoire d'acceptation des conditions](img/sign_up_terms_v11_0.png)
