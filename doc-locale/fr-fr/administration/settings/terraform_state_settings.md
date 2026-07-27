---
stage: Verify
group: Runner Core
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: "Paramètres d'état Terraform"
description: "Configurez le chiffrement de l'état Terraform et les limites de stockage."
---

{{< details >}}

- Niveau :  Free, Premium, Ultimate
- Offre :  GitLab Self-Managed

{{< /details >}}

Vous pouvez configurer les paramètres pour les [fichiers d'état Terraform](../terraform_state.md), notamment le chiffrement et les limites de stockage.

## Chiffrement de l'état Terraform {#terraform-state-encryption}

{{< history >}}

- [Introduit](https://gitlab.com/groups/gitlab-org/-/epics/19738) dans GitLab 18.8.

{{< /history >}}

Par défaut, GitLab chiffre les fichiers d'état Terraform avant de les stocker. Vous pouvez désactiver le chiffrement si nécessaire.

Lorsque le chiffrement est désactivé, les fichiers d'état Terraform sont stockés tels qu'ils sont reçus, sans aucun chiffrement appliqué.

Prérequis :

- Vous devez disposer d'un accès administrateur.

Pour configurer le chiffrement de l'état Terraform :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Préférences**.
1. Développez **État Terraform**.
1. Cochez ou décochez la case **Activer le chiffrement d'état Terraform**.
1. Sélectionnez **Sauvegarder les modifications**.

> [!warning]
> Lorsque vous désactivez le chiffrement, la modification n'affecte que les nouveaux fichiers d'état Terraform. Les fichiers chiffrés existants restent chiffrés et continuent de fonctionner comme prévu.

## Limites de stockage de l'état Terraform {#terraform-state-storage-limits}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/352951) dans GitLab 15.7.

{{< /history >}}

Vous pouvez limiter le stockage total des [fichiers d'état Terraform](../terraform_state.md). La limite s'applique à chaque version individuelle de fichier d'état et est vérifiée lors de la création d'une nouvelle version.

Prérequis :

- Vous devez disposer d'un accès administrateur.

Pour ajouter une limite de stockage :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Préférences**.
1. Développez **État Terraform**.
1. Dans le champ **Limite de la taille du statut de Terraform (octets)**, saisissez une limite de taille en octets. Définissez la valeur sur `0` pour autoriser des fichiers de taille illimitée.
1. Sélectionnez **Sauvegarder les modifications**.

Lorsque les fichiers d'état Terraform dépassent cette limite, GitLab ne les enregistre pas et rejette les opérations Terraform associées.
