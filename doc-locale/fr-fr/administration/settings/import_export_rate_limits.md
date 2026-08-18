---
stage: Create
group: Import
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Limites de débit pour les importations et les exportations de projets et de groupes
description: "Configurez les paramètres de limite de débit pour votre instance GitLab lors de l'importation ou de l'exportation de projets ou de groupes."
---

{{< details >}}

- Niveau :  Free, Premium, Ultimate
- Offre :  GitLab Self-Managed

{{< /details >}}

Vous pouvez configurer les limites de débit pour les importations et les exportations de fichiers de projets et de groupes. Pour plus d'informations sur les limites de débit par défaut, consultez [les limites de débit des importations et des exportations](../instance_limits.md#import-and-export).

Lorsqu'un utilisateur dépasse une limite de débit, cela est consigné dans `auth.log`.

## Modifier une limite de débit d'importation ou d'exportation {#change-an-import-or-export-rate-limit}

Prérequis :

- Accès administrateur.

Pour modifier une limite de débit :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Réseau**.
1. Développez **Limitation de la fréquence des importations et des exportations**.
1. Modifiez la valeur de n'importe quelle limite de débit. Les limites de débit sont par minute et par utilisateur, et non par adresse IP. Définissez la valeur sur `0` pour désactiver une limite de débit.
