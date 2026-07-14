---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Limites de débit sur la création de notes
---

{{< details >}}

- Niveau :  Free, Premium, Ultimate
- Offre :  GitLab Self-Managed

{{< /details >}}

Vous pouvez configurer la limite de débit par utilisateur pour les requêtes vers le point de terminaison de création de notes.

Prérequis :

- Accès administrateur.

Pour modifier la limite de débit de création de notes :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Réseau**.
1. Développez **Notes rate limit**.
1. Dans le champ **Nombre maximum de requêtes par minute**, saisissez la nouvelle valeur.
1. Facultatif. Dans le champ **Utilisateurs à exclure de la limitation de fréquence**, répertoriez les utilisateurs autorisés à dépasser la limite.
1. Sélectionnez **Sauvegarder les modifications**.

Cette limite de débit est :

- Appliquée indépendamment par utilisateur.
- Non appliquée par adresse IP.

La valeur par défaut est `300`.

Les requêtes dépassant la limite de débit sont consignées dans le fichier `auth.log`.

Par exemple, si vous définissez une limite de 300, les requêtes utilisant l'action [`Projects::NotesController#create`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/app/controllers/projects/notes_controller.rb) dépassant un taux de 300 par minute sont bloquées. L'accès au point de terminaison est autorisé après une minute.
