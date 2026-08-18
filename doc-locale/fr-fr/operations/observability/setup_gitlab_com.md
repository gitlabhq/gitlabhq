---
stage: none
group: Embody
info: This page is owned by <https://handbook.gitlab.com/handbook/engineering/embody-team/>
description: Surveillez les performances des applications et résolvez les problèmes de performance.
ignore_in_report: true
title: Configurer Observability sur GitLab.com
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre :  GitLab.com
- Statut : version expérimentale

{{< /details >}}

Pour configurer GitLab Observability sur GitLab.com, activez GitLab Observability pour votre groupe.

Prérequis :

- Vous devez disposer du rôle Developer, Maintainer ou Owner pour le groupe.

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à** et repérez votre groupe.
1. Dans la barre latérale gauche, sélectionnez **Observability** > **Configuration**.
1. Sélectionnez **Activer Observability**.
1. Une fois l'activation effectuée, l'URL de votre endpoint OpenTelemetry (OTEL) est générée et affichée sur la page.

Copiez l'URL de l'endpoint OTEL pour l'utiliser lors de l'instrumentation de vos applications.

## Étapes suivantes {#next-steps}

- [Envoyez vos données de télémétrie à GitLab Observability](send.md).
- [Afficher la télémétrie du pipeline CI/CD](ci_cd.md).
- [Obtenir des informations de dépannage](troubleshooting.md).
