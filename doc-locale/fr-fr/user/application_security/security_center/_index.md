---
stage: Security Risk Management
group: Security Insights
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Centre de sécurité
description: Espace configurable pour afficher les vulnérabilités de plusieurs projets.
---

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Le centre de sécurité est un espace personnel configurable contenant des données sur les vulnérabilités de plusieurs projets. Vous pouvez ajouter jusqu'à 1 000 projets au centre de sécurité parmi les projets auxquels vous appartenez.

> [!note]
> La liste **Projet** dans la page des paramètres du centre de sécurité affiche un maximum de 100 projets. Pour trouver des projets qui ne figurent pas dans les 100 premiers projets, utilisez le filtre de recherche.

Le centre de sécurité affiche :

- Un tableau de bord de sécurité pour les projets que vous avez ajoutés.
- Un [rapport de vulnérabilités](../vulnerability_report/_index.md) pour les projets que vous avez ajoutés.
- Une zone de paramètres pour ajouter ou supprimer des projets.

## Afficher le centre de sécurité {#view-the-security-center}

Pour afficher le centre de sécurité :

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à**.
1. Sélectionnez **Votre travail**.
1. Sélectionnez **Sécurité** > **Tableau de bord de sécurité**.

Le centre de sécurité est vide par défaut. Vous devez ajouter un ou plusieurs projets qui ont été configurés avec au moins un scanner de sécurité.

## Ajouter des projets au centre de sécurité {#add-projects-to-the-security-center}

Pour ajouter des projets :

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à**.
1. Sélectionnez **Votre travail**.
1. Développez **Sécurité**.
1. Sélectionnez **Paramètres**.
1. Utilisez la zone de texte **Rechercher dans vos projets** pour rechercher et sélectionner des projets.
1. Sélectionnez **Ajouter des projets**.

Une fois les projets ajoutés, le tableau de bord de sécurité et le rapport de vulnérabilités affichent les vulnérabilités détectées dans les branches par défaut de ces projets.

## Supprimer des projets du centre de sécurité {#remove-projects-from-the-security-center}

Le centre de sécurité affiche un maximum de 100 projets. Il peut donc être nécessaire d'utiliser la fonction de recherche pour supprimer un projet. Pour supprimer des projets :

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à**.
1. Sélectionnez **Votre travail**.
1. Développez **Sécurité**.
1. Sélectionnez **Paramètres**.
1. Utilisez la zone de texte **Rechercher dans vos projets** pour rechercher le projet.
1. Sélectionnez **Supprimer le projet du tableau de bord** ({{< icon name="remove" >}}).

Une fois les projets supprimés, le tableau de bord de sécurité et le rapport de vulnérabilités n'affichent plus les vulnérabilités détectées dans les branches par défaut de ces projets.

## Export {#exporting}

{{< history >}}

- [Introduction](https://gitlab.com/gitlab-org/gitlab/-/issues/546219) dans GitLab 18.2 [avec un feature flag](../../../administration/feature_flags/_index.md) nommé `vulnerabilities_pdf_export`. Activés par défaut.
- Disponible en général dans GitLab 18.5. Le feature flag `vulnerabilities_pdf_export` a été supprimé.

{{< /history >}}

Vous pouvez exporter un fichier PDF contenant les détails des vulnérabilités répertoriées dans le tableau de bord de sécurité.

Les graphiques de l'export incluent :

- Vulnérabilités au fil du temps
- Statut de sécurité du projet
- Tableau de bord de sécurité du projet

### Détails de l'export {#export-details}

Pour exporter les détails de toutes les vulnérabilités répertoriées dans le tableau de bord de sécurité, sélectionnez **Exporter**.

Une fois les détails exportés disponibles, GitLab vous envoie un e-mail. Pour télécharger les détails exportés, sélectionnez le lien dans l'e-mail.

## Sujets connexes {#related-topics}

- [Tableau de bord de sécurité](../security_dashboard/_index.md)
- [Rapports de vulnérabilités](../vulnerability_report/_index.md)
- [Page de vulnérabilité](../vulnerabilities/_index.md)
