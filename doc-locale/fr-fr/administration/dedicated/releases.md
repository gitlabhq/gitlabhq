---
stage: GitLab Dedicated
group: Environment Automation
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "Calendriers de release, modèle de versionnage et processus de correctifs pour les instances GitLab Dedicated."
title: Versions et gestion des versions de GitLab Dedicated
---

{{< details >}}

- Niveau : Ultimate
- Offre : GitLab Dedicated

{{< /details >}}

GitLab Dedicated suit un modèle de versionnage et un calendrier de release spécifiques pour votre instance afin d'équilibrer la stabilité avec l'accès aux nouvelles fonctionnalités et aux correctifs de sécurité.

## Modèle de versionnage {#versioning-model}

Votre instance s'exécute sur la version mineure précédente (`N-1`) par rapport à la release GitLab actuelle. Par exemple, lorsque GitLab 16.9 est disponible, votre instance exécute GitLab 16.8.

Cette approche offre :

- Stabilité :  Temps supplémentaire pour les tests et la validation avant le déploiement.
- Sécurité :  Les correctifs critiques sont toujours appliqués rapidement via la maintenance d'urgence.
- Prévisibilité :  Calendrier de mise à niveau régulier aligné sur les cycles de release mensuels.

Les nouvelles fonctionnalités deviennent disponibles sur votre instance environ 1 mois après leur release GitLab initiale.

## Vérifier votre version de GitLab {#check-your-gitlab-version}

Vous pouvez vérifier votre version de GitLab via GitLab lui-même ou via Switchboard.

Pour vérifier votre version de GitLab :

- Dans GitLab :  Dans la barre latérale gauche, en bas, sélectionnez **Aide** ({{< icon name="question" >}}) > **Aide**, ou visitez `https://your-instance-url/help` directement.
- Dans Switchboard :  Consultez [la présentation du locataire](tenant_overview.md).

## Calendrier de déploiement des releases {#release-rollout-schedule}

Votre instance est mise à niveau lors des fenêtres de maintenance planifiées selon un calendrier échelonné qui commence 5 jours après chaque release GitLab.

Les mises à niveau ont lieu pendant votre fenêtre de maintenance assignée selon le calendrier suivant, où `T` est la date d'une release mineure de GitLab :

| Jours calendaires après la release | Début des mises à niveau des instances |
| --------------------------- | ----------------------- |
| `T`+5                       | Régions EMEA et Amériques (Option 1) |
| `T`+6                       | Région Asie-Pacifique     |
| `T`+10                      | Région Amériques (Option 2) |

Par exemple, GitLab 16.9 a été publié le 2024-02-15. Les instances dans les régions EMEA et Amériques (Option 1) ont été mises à niveau vers la version 16.8 le 2024-02-20, 5 jours après la release 16.9.

Si la maintenance est reportée en raison de contraintes opérationnelles, les mises à niveau ont lieu lors de la prochaine fenêtre de maintenance disponible.

## Fréquence des mises à jour {#update-frequency}

Votre instance reçoit des mises à jour régulières pendant votre fenêtre de maintenance préférée :

Les mises à jour mensuelles comprennent :

- Une release mineure
- Deux releases de correctifs

Les mises à jour supplémentaires peuvent inclure :

- Correctifs de sécurité critiques via la maintenance d'urgence
- Améliorations de l'infrastructure
- Optimisations des performances

## Calendrier de validation des correctifs {#patch-validation-timeline}

Les correctifs critiques suivent un calendrier accéléré pour s'assurer que les vulnérabilités de sécurité sont traitées rapidement :

1. Développement :  Les corrections de bugs doivent être fusionnées dans la branche stable au moins deux jours ouvrables avant la date de release du correctif prévue.
1. Release du correctif :  Un correctif est publié pour une vulnérabilité de sécurité ou un bug critique.
1. Validation (0 à 24 heures) :  Le correctif est validé dans les environnements de staging.
1. Déploiement d'urgence :  Le correctif est déployé sur votre instance via des procédures de maintenance d'urgence.

### Calendrier des releases de correctifs {#patch-release-schedule}

Les releases mensuelles ont lieu pendant la semaine qui suit le troisième jeudi de chaque mois.

Les correctifs critiques sont publiés deux fois par mois, le :

- Mercredi avant la semaine de release mensuelle
- Mercredi après la semaine de release mensuelle

Par exemple, si le troisième jeudi est le 16 janvier 2025 :

- Semaine de release mensuelle :  20-24 janvier 2025
- Première release de correctif :  15 janvier 2025 (mercredi avant)
- Deuxième release de correctif :  29 janvier 2025 (mercredi après)

Les correctifs non critiques sont déployés sur votre instance lors de la prochaine fenêtre de maintenance planifiée.

## Releases internes {#internal-releases}

Les releases internes sont des releases privées utilisées pour remédier aux vulnérabilités de sécurité critiques et aux bugs de haute gravité sur les instances GitLab Dedicated avant la divulgation publique. Ces releases sont déployées via [les procédures de maintenance d'urgence](maintenance.md#emergency-maintenance).

Les correctifs critiques qui ne peuvent pas attendre le prochain correctif planifié sont livrés via des releases internes pour garantir que votre instance reste sécurisée et stable.

## Corrections de bugs {#bug-fixes}

Les équipes d'ingénierie de GitLab travaillent à inclure des corrections de bugs et des améliorations des performances dans votre version lors des fenêtres de maintenance planifiées. Ces correctifs sont inclus de manière proactive sans aucune action requise de votre part.

### Demander une correction de bug {#request-a-bug-fix}

Vous pouvez demander une correction de bug spécifique si elle n'a pas été incluse dans votre version.

Pour demander une correction de bug :

1. Soumettez un ticket d'assistance avec un lien vers le merge request ou le ticket contenant le correctif.
1. Attendez une réponse indiquant si la demande est approuvée.

Si approuvée, la correction est incluse dans votre prochaine fenêtre de maintenance planifiée.

> [!note]
> Toutes les corrections ne peuvent pas être rétroportées en raison de dépendances, de complexité ou de considérations de compatibilité. Chaque demande est évaluée individuellement.

## Sujets connexes {#related-topics}

- [Opérations de maintenance de GitLab Dedicated](maintenance.md)
- [Politique de release et de maintenance de GitLab](../../policy/maintenance.md)
