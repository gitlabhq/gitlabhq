---
stage: Security Risk Management
group: Security Insights
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Secret false positive detection
---

{{< details >}}

- Édition : GitLab Ultimate
- Module d'extension : GitLab Duo Core, GitLab Duo Pro ou GitLab Duo Enterprise
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- Introduction de Secret false positive detection dans l'[epic 17885](https://gitlab.com/groups/gitlab-org/-/work_items/20152), dans GitLab 18.10, en [version bêta](../../../../policy/development_stages_support.md#beta), avec le [feature flag](../../../../administration/feature_flags/_index.md) `duo_secret_detection_false_positive`. [Activé sur GitLab.com, GitLab Self-Managed et GitLab Dedicated](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/227074).
- [Passage en disponibilité générale](../../../../policy/development_stages_support.md#generally-available) dans GitLab 19.1.

{{< /history >}}

Secret false positive detection analyse automatiquement les résultats de la détection des secrets pour identifier les potentiels faux positifs. Ignorer les secrets qui ne représentent probablement pas de véritables risques de sécurité réduit le bruit dans votre rapport de vulnérabilité.

Lorsqu'un scan de détection des secrets s'exécute, GitLab Duo analyse automatiquement chaque résultat pour déterminer la probabilité qu'il s'agisse d'un faux positif. La détection est disponible pour tous les types de secrets détectés par la [détection des secrets GitLab](../../../application_security/secret_detection/_index.md).

L'évaluation de GitLab Duo inclut des informations sur chaque résultat de détection de faux positif :

- Score de confiance : un score numérique indiquant la probabilité que le résultat soit un faux positif.
- Explication : les raisons pour lesquelles le résultat peut ou non être un vrai positif.
- Indicateur visuel : un badge dans le rapport de vulnérabilité qui affiche le résultat de l'évaluation.

Les résultats reposent sur une analyse par IA et doivent être examinés par des spécialistes de la sécurité. Cette fonctionnalité nécessite GitLab Duo avec un abonnement actif.

> [!note]
> Vous ne pouvez pas déclencher ce flow en mentionnant, assignant ou demandant une revue depuis son compte de service. Le flow s'exécute automatiquement une fois les scans de sécurité terminés. Pour l'exécuter manuellement, sur une page de vulnérabilité, sélectionnez **Actions IA**, puis sélectionnez **Vérifier les faux positifs**.

## Prérequis {#prerequisites}

- Satisfaire aux [prérequis pour GitLab Duo Agent Platform](../../_index.md#prerequisites).
- Activez **Autoriser les flows par défaut** et **Détection des faux positifs de détection de secret** [pour le groupe principal](_index.md#turn-foundational-flows-on-or-off).
- [Configurer les règles push pour autoriser un compte de service](../../troubleshooting.md#configure-push-rules-to-allow-a-service-account).
- [Configurer vos propres runners](../execution/_index.md#configure-runners-to-execute-flows) ou activer les [runners hébergés par GitLab](../../../../ci/runners/hosted_runners/_index.md) pour votre projet.

## Exécution de Secret false positive detection {#running-secret-false-positive-detection}

Le flow s'exécute automatiquement dans les scénarios suivants :

- Une analyse de détection de secret se termine avec succès sur la branche par défaut.
- L'analyse détecte des secrets.
- Les fonctionnalités GitLab Duo sont activées pour le projet ou le groupe.

Vous pouvez également déclencher manuellement l'analyse pour les vulnérabilités existantes :

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à**, puis recherchez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Sécurisation** > **Rapport de vulnérabilités**.
1. Sélectionnez la vulnérabilité que vous souhaitez analyser.
1. Dans le coin supérieur droit, sélectionnez **Actions IA**, puis sélectionnez **Vérifier les faux positifs**.

## Liens connexes {#related-links}

- [Secret false positive detection](../../../application_security/vulnerabilities/secret_false_positive_detection.md).
- [Rapport de vulnérabilité](../../../application_security/vulnerability_report/_index.md).
- [Détection des secrets](../../../application_security/secret_detection/_index.md).
