---
stage: none
group: Embody
info: This page is owned by <https://handbook.gitlab.com/handbook/engineering/embody-team/>
description: Surveillez les performances des applications et résolvez les problèmes de performance.
ignore_in_report: true
title: Observabilité
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Statut : version expérimentale

{{< /details >}}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/embody-team/experimental-observability/documentation/-/work_items/6) dans GitLab 18.1 en tant que version expérimentale disponible pour tous les utilisateurs.

{{< /history >}}

GitLab Observability fournit le traçage distribué, les métriques et les logs, le tout sur une seule plateforme. Aucune limite de cardinalité. Aucun outil supplémentaire à apprendre pour votre équipe.

Utilisez GitLab Observability pour :

- Surveiller les performances des applications grâce au traçage distribué entre les microservices.
- Corréler les modifications de code avec les tickets de production.
- Instrumenter les pipelines CI/CD automatiquement sans modification de code.
- Envoyer des métriques à haute cardinalité sans limites en utilisant les standards OpenTelemetry.

GitLab Observability est une fonctionnalité expérimentale en constante évolution. Vous pouvez commencer à envoyer des traces, des logs et des métriques dès maintenant. Pour vous familiariser avec le workflow, essayez-le d'abord sur un service non critique, puis étendez l'utilisation selon vos besoins.

<i class="fa-youtube-play" aria-hidden="true"></i> Pour une présentation détaillée, consultez [GitLab Observability (O11y) Introduction](https://www.youtube.com/watch?v=XI9ZruyNEgs).
<!-- Video published on 2025-06-18 -->

GitLab Observability est disponible et gratuit pour toutes les éditions. [Partagez vos commentaires ou demandez des fonctionnalités](#share-your-feedback).

## Premiers pas {#get-started}

1. Configurez Observability, soit sur [votre instance GitLab Self-Managed](setup_self_managed.md), soit sur [GitLab.com](setup_gitlab_com.md).
1. Ajoutez votre endpoint OTLP pour [commencer à envoyer de la télémétrie](send.md), ou [consulter la télémétrie du pipeline CI/CD](ci_cd.md).
1. Consultez votre première trace.
1. Déboguez une requête lente.
1. [Accédez à l'API](api_access.md) pour interroger les données de manière programmatique.

<div class="video-fallback">
  Regardez : <a href="https://www.youtube.com/watch?v=lZtgor6chMs">Configuration de GitLab Observability</a>.
</div>
<figure class="video-container">
  <iframe src="https://www.youtube-nocookie.com/embed/lZtgor6chMs" frameborder="0" allowfullscreen> </iframe>
</figure>
<!-- Video published on 2026-05-04 -->

## Utilisation réelle {#real-world-usage}

GitLab Observability est utilisé par des équipes du monde entier pour surveiller leurs applications et leur infrastructure.

<!-- TODO: Add usage demonstration video showing real debugging workflow
<i class="fa-youtube-play" aria-hidden="true"></i>
For a usage demonstration, see [How to Debug Production Issues with GitLab Observability](VIDEO_URL).
-->

Nos utilisateurs surveillent activement leurs systèmes avec GitLab Observability sur GitLab.com (pour la semaine du 21 avril 2026) :

- Plus de 57 millions de traces traitées quotidiennement.
- Plus de 3 000 services activement surveillés.

## Fonctionnalités clés {#key-features}

### Surveiller les performances, tracer les problèmes {#monitor-performance-trace-issues}

Trouvez et déboguez les problèmes plus rapidement.

- Workflow de développement amélioré. Corrélez les modifications de code directement avec les métriques de performance des applications pour identifier quand les déploiements introduisent des problèmes.
- Réponse aux incidents simplifiée. Consultez les déploiements récents, les modifications de code et les développeurs impliqués en un seul endroit.

Lorsqu'un problème survient, consultez :

- La trace de performance qui affiche la requête lente.
- La merge request qui a introduit la modification.
- Le développeur qui peut le corriger.
- Le déploiement qui l'a mis en production.

### Plateforme unifiée {#unified-platform}

Surveillez les performances des applications grâce à un tableau de bord unifié qui combine :

- Traçage distribué. Suivez les requêtes entre les microservices pour identifier les goulots d'étranglement.
- Métriques. Suivez les performances des applications et de l'infrastructure dans le temps.
- Logs. Corrélez les entrées de logs avec les traces et les métriques pour un contexte complet.

La gestion centralisée offre :

- Gestion des accès simplifiée. Les nouveaux ingénieurs accèdent automatiquement aux données d'observabilité de production lorsqu'ils reçoivent l'accès au dépôt de code.
- Aucun changement de contexte. Accédez aux données de surveillance sans quitter GitLab.

### Intégration adaptée aux développeurs {#developer-friendly-integration}

Envoyez les mêmes données OpenTelemetry vers plusieurs backends pendant que vous évaluez GitLab Observability.

- Migration depuis Datadog ou New Relic. Si vous utilisez OpenTelemetry, il vous suffit de modifier votre endpoint OTLP.
- Aucun verrouillage fournisseur. Utilisez les bibliothèques d'instrumentation OpenTelemetry standard. Changez de fournisseur à tout moment en modifiant votre endpoint OTLP.

### Configuration et instrumentation rapides {#fast-setup-and-instrumentation}

La plupart des équipes voient leurs premières traces dans les 5 à 10 minutes suivant l'activation de la fonctionnalité.

- Tableaux de bord préconfigurés. Commencez avec des modèles pour les cas d'usage courants.
- Instrumentation CI/CD automatique. Définissez une variable d'environnement et GitLab instrumente automatiquement vos pipelines CI/CD.

### Rentable et évolutif {#cost-effective-and-scalable}

- Gratuit pour toutes les éditions. Aucun frais par siège, par métrique ou par hôte. Aucune limite sur les traces, les métriques ou les logs.
- Aucune limite de cardinalité. Envoyez des métriques à haute cardinalité sans contrainte de coût.
- Modèle open source. Contribuez directement aux fonctionnalités et aux correctifs.
- Coûts prévisibles. Aucune facture surprise liée aux explosions de métriques.

### Conformité et pistes d'audit {#compliance-and-audit-trails}

L'intégration crée des pistes d'audit complètes qui relient les modifications de code au comportement du système, précieuses pour les exigences de conformité et l'analyse post-incident.

## En savoir plus {#learn-more}

- [Accéder à l'API Observability](api_access.md). Interrogez les traces, les métriques et les logs de manière programmatique.
- [Documentation OpenTelemetry](https://opentelemetry.io/docs/instrumentation/). Guides d'instrumentation spécifiques à chaque langage.
- [Modèles GitLab Observability](https://gitlab.com/gitlab-org/embody-team/experimental-observability/o11y-templates/). Tableaux de bord et exemples préconfigurés.
- [Fonctionnalités proposées](https://gitlab.com/gitlab-org/embody-team/experimental-observability/gitlab_o11y/-/issues/8)

## Obtenir de l'aide {#get-help}

- [Communauté Discord](https://discord.com/channels/778180511088640070/1379585187909861546). Rejoignez la conversation avec d'autres utilisateurs.
- [Tickets GitLab](https://gitlab.com/gitlab-org/embody-team/experimental-observability/gitlab_o11y/-/issues). Signalez des bugs ou demandez des fonctionnalités.
- [Informations de dépannage](troubleshooting.md).

## Partagez vos commentaires {#share-your-feedback}

GitLab Observability est amélioré en fonction des retours des utilisateurs. Pour fournir des commentaires :

- Rejoignez le [canal Discord](https://discord.com/channels/778180511088640070/1379585187909861546).
- [Ouvrez un ticket](https://gitlab.com/gitlab-org/embody-team/experimental-observability/gitlab_o11y/-/issues) pour signaler des bugs ou demander des fonctionnalités.
