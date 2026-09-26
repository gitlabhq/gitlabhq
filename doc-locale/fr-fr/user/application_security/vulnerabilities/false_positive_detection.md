---
stage: Security Risk Management
group: Security Insights
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Détecter automatiquement les faux positifs
description: Détection et filtrage automatiques des faux positifs dans les résultats SAST.
---

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Introduit](https://gitlab.com/groups/gitlab-org/-/work_items/18977) dans GitLab 18.7 en tant que [version bêta](../../../policy/development_stages_support.md#beta) [avec des feature flags](../../../administration/feature_flags/_index.md) nommés `enable_vulnerability_fp_detection` et `ai_experiment_sast_fp_detection`. Activés par défaut.
- [Disponible généralement](https://gitlab.com/groups/gitlab-org/-/work_items/19789) dans GitLab 18.10.
- Les feature flags [`ai_experiment_sast_fp_detection`](https://gitlab.com/gitlab-org/gitlab/-/work_items/584344) et [`enable_vulnerability_fp_detection`](https://gitlab.com/gitlab-org/gitlab/-/work_items/584343) ont été supprimés dans GitLab 19.1.
- La prise en charge dans le profil de triage et de remédiation a été [introduite](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/254011) dans GitLab 19.4 [avec un feature flag](../../../administration/feature_flags/_index.md) nommé `triage_and_remediation_profile`. Activés par défaut.

{{< /history >}}

Lorsqu'un scan de test statique de sécurité des applications (SAST) s'exécute, le flow SAST False Positive Detection analyse automatiquement chaque vulnérabilité SAST de gravité Critique et Haute afin de déterminer la probabilité qu'il s'agisse d'un faux positif. La détection est disponible pour les vulnérabilités issues des [analyseurs SAST pris en charge par GitLab](../sast/analyzers.md).

L'évaluation du flow comprend :

- Score de confiance : un score numérique indiquant la probabilité que le résultat soit un faux positif.
- Explication : un raisonnement contextuel expliquant pourquoi le résultat peut ou non être un vrai positif, basé sur le contexte du code et les caractéristiques de la vulnérabilité.
- Indicateur visuel : un badge dans le rapport de vulnérabilités affichant l'évaluation du faux positif.

La détection s'exécute automatiquement après chaque scan de sécurité, sans déclenchement manuel requis.

Les résultats reposent sur une analyse par IA et doivent être examinés par des spécialistes de la sécurité.

<i class="fa-youtube-play" aria-hidden="true"></i> Pour une vue d'ensemble, consultez [GitLab AI-Powered SAST False Positive Detection and Remediation](https://www.youtube.com/watch?v=kVMM5OFva_U).
<!-- Video published on 2026-03-20 -->

Pour une démo interactive, consultez [flow SAST False Positive Detection](https://gitlab.navattic.com/sast-fp-detection-flow).
<!-- Demo published on 2026-02-17 -->

Les profils de configuration de sécurité prennent également en charge ce flow. Pour activer et configurer le flow sur plusieurs projets et groupes à la fois, utilisez le [profil de triage et de remédiation automatisé](../configuration/security_configuration_profiles.md#automated-triage-and-remediation-profile).

## Prérequis {#prerequisites}

- Satisfaire aux [prérequis pour GitLab Duo Agent Platform](../../duo_agent_platform/_index.md#prerequisites).
- Activez **Autoriser les flows par défaut** et **Détection des faux positifs SAST** [pour le groupe principal](../../duo_agent_platform/flows/foundational_flows/_index.md#turn-foundational-flows-on-or-off).
- [Configurer les règles push pour autoriser un compte de service](../../duo_agent_platform/troubleshooting.md#configure-push-rules-to-allow-a-service-account).
- [Configurer vos propres runners](../../duo_agent_platform/flows/execution/_index.md#configure-runners-to-execute-flows) ou activer les [runners hébergés par GitLab](../../../ci/runners/hosted_runners/_index.md) pour votre projet.
- Définissez [un espace de nommage GitLab Duo par défaut](../../profile/preferences.md#set-a-default-gitlab-duo-namespace) dans vos préférences utilisateur.

## Autoriser le flow par défaut pour un groupe {#allow-foundational-flow-for-a-group}

Vous pouvez autoriser tous les projets d'un groupe à utiliser le flow par défaut. Chaque projet doit tout de même activer la fonctionnalité dans ses paramètres. Pour autoriser la détection des faux positifs pour l'ensemble des projets d'un groupe :

1. Dans la barre latérale gauche, sélectionnez **Rechercher ou accéder à** et repérez votre groupe.
1. Sélectionnez **Paramètres** > **GitLab Duo**.
1. Sous **Autoriser les flows par défaut**, cochez la case **Détection des faux positifs SAST**.
1. Sélectionnez **Enregistrer les modifications**.

## Activer pour un projet {#turn-on-for-a-project}

Prérequis :

- Le rôle Responsable sécurité, Chargé de maintenance ou Propriétaire pour le projet.

Pour activer la détection des faux positifs pour un projet donné :

1. Dans la barre latérale gauche, sélectionnez **Rechercher ou accéder à** et repérez votre projet.
1. Sélectionnez **Paramètres** > **Généralités**.
1. Développez **GitLab Duo**.
1. Activez le bouton **Activer la détection de faux positifs SAST**.
1. Sélectionnez **Enregistrer les modifications**.

Lorsque vous autorisez la détection des faux positifs pour le groupe et l'activez pour le projet, la fonctionnalité fonctionne automatiquement avec vos analyseurs SAST existants.

## Détection automatique {#automatic-detection}

Le flow de détection des faux positifs s'exécute automatiquement lorsque :

- Un scan de sécurité SAST se termine avec succès sur la branche par défaut.
- Le scan détecte des vulnérabilités de gravité Critique ou Haute.
- Les fonctionnalités GitLab Duo sont activées pour le projet.

L'analyse s'effectue en arrière-plan et les résultats apparaissent dans le rapport de vulnérabilités une fois le traitement terminé.

## Exécuter le flow SAST False Positive Detection {#run-the-sast-false-positive-detection-flow}

Vous pouvez déclencher manuellement l'analyse pour des vulnérabilités existantes :

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à**, puis recherchez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Sécurisation** > **Rapport de vulnérabilités**.
1. Sélectionnez la vulnérabilité que vous souhaitez analyser.
1. Dans le coin supérieur droit, sélectionnez **Actions IA**, puis sélectionnez **Vérifier les faux positifs**.

L'analyse GitLab Duo s'exécute et les résultats sont affichés sur la page de détails de la vulnérabilité.

## Analyser plusieurs vulnérabilités {#analyze-multiple-vulnerabilities}

{{< details >}}

- Offre : GitLab.com, GitLab Self-Managed
- Statut : version bêta

{{< /details >}}

{{< history >}}

- [Introduit](https://gitlab.com/groups/gitlab-org/-/work_items/21890) dans GitLab 19.3 en tant que fonctionnalité en [version bêta](../../../policy/development_stages_support.md#beta) [avec un feature flag](../../../administration/feature_flags/_index.md) nommé `bulk_vulnerabilities_duo_workflow_api`. Fonctionnalité désactivée par défaut.
- [Activé par défaut pour GitLab.com et GitLab Self-Managed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/253325) dans GitLab 19.4.

{{< /history >}}

> [!flag]
> La disponibilité de cette fonctionnalité est contrôlée par un feature flag. Pour plus d'informations, consultez l'historique.

Vous pouvez déclencher le flow pour analyser plusieurs vulnérabilités afin de détecter les faux positifs.

Les niveaux de gravité suivants sont analysés :

- Critique
- Élevé
- Moyen
- Faible
- Inconnu
- Info

Prérequis :

- Pour analyser plusieurs vulnérabilités, vous devez disposer de l'un des éléments suivants :
  - Le rôle Responsable sécurité, Mainteneur ou Propriétaire pour le projet
  - Rôle personnalisé avec la permission `admin_vulnerability`
- Pour consulter la progression du flow, vous devez disposer du rôle Développeur.

1. Dans la barre latérale gauche, sélectionnez **Rechercher ou accéder à** et repérez votre projet.
1. Sélectionnez **Sécuriser** > **Rapport de vulnérabilités**.
1. Cochez la case à côté de chaque vulnérabilité que vous souhaitez analyser. Pour sélectionner toutes les vulnérabilités de la page, cochez la case dans l'en-tête du tableau.
1. Dans la liste déroulante **Sélectionner une action**, sélectionnez **Exécuter la détection des faux positifs SAST**.
1. Sélectionnez **Exécuter la détection des faux positifs SAST**.

### Limitations connues {#known-limitations}

- Le rapport de progression affiche uniquement le nombre de vulnérabilités éligibles à la résolution. Si vous sélectionnez 10 vulnérabilités et que trois sont éligibles, le rapport de progression n'en signale que trois.
- Une seule exécution de chaque flow peut être active dans un projet à la fois. L'exécution appartient au projet ; ainsi, une exécution démarrée par un autre utilisateur bloque également une nouvelle exécution. Attendez que l'exécution active se termine avant de démarrer une autre exécution du même flow.
- Vous ne pouvez exécuter une exécution de flow en masse que pour un maximum de 1 000 vulnérabilités. Cette limite s'applique aux vulnérabilités que vous sélectionnez dans le rapport de vulnérabilités. Pour résoudre plus de 1 000 vulnérabilités, utilisez GraphQL.

## Scores de confiance {#confidence-scores}

Le score de confiance estime la probabilité que l'évaluation de GitLab Duo soit correcte :

- **Faux positif probable (80-100 %)** : GitLab Duo estime avec un niveau de confiance élevé que le résultat correspond à un faux positif.
- **Possible faux positif (60-79 %)** : GitLab Duo estime avec un niveau de confiance raisonnable que le résultat peut correspondre à un faux positif, mais recommande un examen manuel.
- **Probablement pas un faux positif (<60 %)** : GitLab Duo ne dispose pas d'un niveau de confiance suffisant pour considérer que le résultat correspond à un faux positif. Un examen manuel est vivement recommandé avant de rejeter la vulnérabilité.

## Rejet des faux positifs {#dismissing-false-positives}

Lorsque l'analyse GitLab Duo identifie une vulnérabilité comme un faux positif, vous pouvez choisir l'une des options suivantes :

- Rejeter la vulnérabilité
- Supprimer le marqueur de faux positif

### Rejeter la vulnérabilité {#dismiss-the-vulnerability}

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à**, puis recherchez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Sécurisation** > **Rapport de vulnérabilités**.
1. Sélectionnez la vulnérabilité à rejeter.
1. Dans la barre latérale droite, dans la section **Statut**, sélectionnez **Modifier**.
1. Dans la liste déroulante **Statut**, sous **Rejeter comme...**, sélectionnez **Faux positif**.
1. Dans la zone de texte **Commentaire**, précisez le contexte expliquant pourquoi vous le rejetez en tant que faux positif. Un commentaire est requis.
1. Sélectionnez **Modifier le statut**.

La vulnérabilité est marquée comme rejetée et n'apparaît plus dans les analyses ultérieures, sauf si elle est réintroduite.

### Supprimer le marqueur de faux positif {#remove-the-false-positive-flag}

Si vous souhaitez supprimer l'évaluation indiquant un faux positif tout en conservant la vulnérabilité :

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à**, puis recherchez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Sécurisation** > **Rapport de vulnérabilités**.
1. Repérez la vulnérabilité qui porte le marqueur de faux positif.
1. Survolez le badge de faux positif associé à la vulnérabilité.
1. Sélectionnez **Supprimer le drapeau de faux positif**.

Le drapeau de faux positif est supprimé et le score de confiance FP repasse à 0. La vulnérabilité reste dans le rapport et peut être réévaluée lors des analyses ultérieures.

## Fournir des commentaires {#providing-feedback}

Partagez vos commentaires dans le [ticket 583697](https://gitlab.com/gitlab-org/gitlab/-/issues/583697).

## Sujets connexes {#related-topics}

- [Détails de la vulnérabilité](_index.md)
- [Rapport de vulnérabilités](../vulnerability_report/_index.md)
- [SAST](../sast/_index.md)
- [GitLab Duo](../../gitlab_duo/_index.md)
