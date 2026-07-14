---
stage: Plan
group: Knowledge
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
gitlab_dedicated: yes
title: Proxy de diagramme
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/223314) dans GitLab 18.10.

{{< /history >}}

Utilisez le proxy de diagramme pour empêcher les navigateurs d'envoyer le contenu des diagrammes à des services externes tels que Kroki ou PlantUML. GitLab récupère les diagrammes au nom de l'utilisateur et les sert via une URL à usage unique qui expire après utilisation.

## Activer le proxy de diagramme {#turn-on-the-diagram-proxy}

Activez le proxy de diagramme séparément pour les intégrations [Kroki](kroki.md) et [PlantUML](plantuml.md). Vous pouvez activer le proxy de diagramme pour Kroki, PlantUML, ou les deux.

Prérequis :

- Accès administrateur.

Pour activer le proxy de diagramme :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Général**.
1. Développez **Kroki** ou **PlantUML**.
1. Cochez la case **Utiliser un proxy pour les diagrammes Kroki via GitLab** ou **Utiliser un proxy pour les diagrammes PlantUML via GitLab**.
1. Sélectionnez **Sauvegarder les modifications**.
