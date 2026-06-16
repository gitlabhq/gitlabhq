---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Détails du support.
title: Support des fonctionnalités à différentes étapes de développement
---

<!--
This page contains information targeting public users and customers of GitLab features.
The goal is to help users understand the risks of using features in various stages of development.

The user-targeted content has been approved by the GitLab legal team.
If you change this information, consider getting a legal team member to review it.

To add information about internal GitLab guidelines for developing and releasing features,
consider adding it to the handbook or to the '## Feature release requirements' section at the end of this page.
-->

GitLab publie parfois des fonctionnalités à différentes étapes de développement, comme en phase expérimentale ou bêta. Les utilisateurs peuvent s'inscrire et tester la nouvelle expérience. Voici quelques raisons de ce type de publication de fonctionnalités :

- Valider les cas limites en termes d'échelle, de support et de charge de maintenance des fonctionnalités dans leur forme actuelle pour chaque cas d'utilisation prévu.
- Les fonctionnalités pas suffisamment complètes pour être considérées comme un MVC, mais ajoutées à la base de code dans le cadre du processus de développement.

Certaines fonctionnalités peuvent ne pas être alignées sur ces recommandations si elles ont été développées avant que les recommandations soient en place, ou si une équipe a déterminé qu'une approche d'implémentation alternative était nécessaire.

Toutes les autres fonctionnalités sont considérées comme publiquement disponibles.

## Expérimental {#experiment}

Fonctionnalités expérimentales :

- Ne sont pas prêtes pour une utilisation en production.
- N'ont [aucun support disponible](https://support.gitlab.com/hc/en-us/articles/11625911285404-Statement-of-Support#experiment-&-beta-features). Les tickets concernant ces fonctionnalités doivent être ouverts dans le [système de suivi des tickets GitLab](https://gitlab.com/gitlab-org/gitlab/-/issues).
- Peuvent être instables.
- Peuvent être supprimées à tout moment.
- Pourraient ne pas atteindre la disponibilité générale.
- Peuvent présenter un risque de perte de données.
- Peuvent ne pas avoir de documentation, ou des informations limitées aux tickets GitLab ou à un blog.
- Peuvent ne pas avoir une expérience utilisateur finalisée, et pourraient n'être accessibles que via des actions rapides ou des requêtes API.

## Bêta {#beta}

Fonctionnalités bêta :

- Peuvent ne pas être prêtes pour une utilisation en production.
- Sont [prises en charge sur la base d'un effort commercialement raisonnable](https://about.gitlab.com/support/statement-of-support/#experiment-beta-features), mais avec l'attente que les problèmes nécessitent un temps supplémentaire et une assistance du développement pour être résolus.
- Peuvent être instables.
- Ont une configuration et des dépendances susceptibles de ne pas changer.
- Ont des fonctionnalités et des fonctions susceptibles de ne pas changer. Cependant, des changements majeurs peuvent survenir en dehors des releases majeures ou avec moins de préavis que pour les fonctionnalités généralement disponibles.
- Présentent un faible risque de perte de données.
- Ont une expérience utilisateur complète ou presque terminée.
- Peuvent être équivalentes au statut « Public Preview » des partenaires.

## Disponibilité publique {#public-availability}

Deux types de releases publiques sont disponibles :

- Disponibilité limitée
- Généralement disponible

Les deux types sont prêts pour la production, mais ont des portées différentes.

### Disponibilité limitée {#limited-availability}

Les fonctionnalités à disponibilité limitée suivent les mêmes exigences de sécurité que les fonctionnalités généralement disponibles, mais peuvent être déployées sur un sous-ensemble de plateformes ou avec des limitations d'échelle lors du déploiement initial.

Fonctionnalités à disponibilité limitée :

- Sont prêtes pour une utilisation en production à une échelle réduite.
- Peuvent être initialement disponibles sur une ou plusieurs plateformes GitLab (GitLab.com, GitLab Self-Managed, GitLab Dedicated).
- Peuvent être initialement gratuites, puis devenir payantes lors de la disponibilité générale.
- Peuvent être proposées à prix réduit avant de devenir généralement disponibles.
- Peuvent avoir des conditions commerciales qui changent pour les nouveaux contrats lors de la disponibilité générale.
- Sont [entièrement prises en charge](https://about.gitlab.com/support/statement-of-support/) et documentées.
- Ont une expérience utilisateur complète alignée sur les standards de conception GitLab.

### Généralement disponible {#generally-available}

Fonctionnalités généralement disponibles :

- Sont prêtes pour une utilisation en production à n'importe quelle échelle.
- Sont [entièrement prises en charge](https://about.gitlab.com/support/statement-of-support/) et documentées.
- Ont une expérience utilisateur complète alignée sur les standards de conception GitLab.
- Doivent être disponibles sur toutes les offres GitLab (GitLab.com, GitLab.com Cells, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government).
- L'utilisation des fonctionnalités généralement disponibles dans la plateforme GitLab Duo Agent consomme des GitLab Credits. Lorsqu'une fonctionnalité devient généralement disponible dans la version la plus récente de GitLab, son utilisation commence à consommer des crédits sur toutes les versions et offres. Les fonctionnalités bêta peuvent passer en disponibilité générale avec facturation à l'utilisation à tout moment.

## Exigences pour la publication de fonctionnalités {#feature-release-requirements}

Avant de rendre une fonctionnalité disponible pour les utilisateurs, les équipes GitLab qui développent la fonctionnalité doivent tenir compte des recommandations de statut ci-dessus et des exigences pour chaque étape de développement.

### Terminologie {#terminology}

Pour plus de clarté, ces directives utilisent les définitions suivantes :

- **Acceptation explicite** : Une fonctionnalité est désactivée par défaut et nécessite une action d'activation délibérée par un utilisateur autorisé (tel qu'un administrateur d'instance, un propriétaire de groupe ou un utilisateur individuel, selon la portée de la fonctionnalité). Les fonctionnalités disponibles à l'activation mais restant désactivées sauf si elles sont activées sont considérées comme nécessitant une acceptation explicite.
- **Activé par défaut** : Une fonctionnalité est active pour les utilisateurs ou les instances sans nécessiter d'action d'opt-in. Les fonctionnalités ne doivent pas être activées par défaut lors des étapes Expérimentale ou Bêta.
- **Utilisation en production** : Fait référence aux deux cas suivants :
  - Charges de travail de production client (fonctionnalités dont les utilisateurs dépendent pour les opérations métier)
  - Infrastructure de production gérée par GitLab (services partagés affectant la fiabilité ou la sécurité de la plateforme) prenant en charge GitLab.com, Dedicated et Dedicated for Federal
- **Tests internes** : Utilisation des fonctionnalités pré-GA par les membres de l'équipe GitLab à des fins de validation, également connue sous le nom de Customer Zero.

### Principe de transition de maturité des fonctionnalités {#feature-maturity-transition-principle}

Lors de l'évaluation de la disponibilité d'une fonctionnalité à passer à une étape de maturité supérieure, appliquez le **test de réponse aux incidents** :

> « Si cette fonctionnalité était déjà au niveau de maturité cible et que ce risque se manifestait, déclarerions-nous un incident et pousserions-nous un correctif urgent ? »

Les fonctionnalités ne doivent pas passer en GA avec des risques qui déclencheraient une réponse aux incidents si elles survenaient après la GA, notamment :

- Vulnérabilités de sécurité critiques (S1/S2)
- Dégradations des performances qui enfreindraient les engagements SLA
- Problèmes d'intégrité des données nécessitant une notification client
- Impacts sur la disponibilité affectant la stabilité de la plateforme

Ce principe garantit que les fonctionnalités atteignent la maturité de production avec une posture de risque appropriée plutôt que de créer des incidents futurs prévisibles.

### Fonctionnalités expérimentales {#experimental-features}

- Doivent être désactivées par défaut et nécessitent un opt-in explicite. Ne peuvent pas être automatiquement activées pour les utilisateurs ou les instances sans action du client.
- Sur les plateformes multi-locataires, doivent maintenir l'isolation des locataires de sorte que les utilisateurs qui s'inscrivent ne créent pas de risque pour les autres locataires.
- Peuvent avoir des correctifs de sécurité publiés en canonique (en open source) selon l'état actuel de la maturité de la release. Les SLO de remédiation des vulnérabilités standard ne s'appliquent pas aux fonctionnalités expérimentales.
- Nécessitent l'approbation d'un VP pour les exceptions permettant de passer en Bêta sans satisfaire aux exigences Bêta énoncées.

Les tests internes (Customer Zero) peuvent utiliser les fonctionnalités expérimentales à des fins de validation technique. Les fonctionnalités affectant les processus métier à l'échelle de l'entreprise (telles que l'intégration, la gestion des accès ou les workflows de conformité) nécessitent une acceptation documentée des risques de la part des responsables de l'ingénierie et de la sécurité.

### Fonctionnalités bêta {#beta-features}

- Doivent être désactivées par défaut et nécessitent un opt-in explicite. Ne peuvent pas être automatiquement activées pour les utilisateurs ou les instances sans action du client.
- Sur les plateformes multi-locataires, doivent maintenir l'isolation des locataires de sorte que les utilisateurs qui s'inscrivent ne créent pas de risque pour les autres locataires.
- Doivent disposer d'un plan documenté et aligné avec les parties prenantes pour l'établissement d'un processus de release de sécurité avant la disponibilité générale. Ce processus doit permettre une remédiation sécurisée des vulnérabilités sans divulgation publique prématurée, notamment en précisant comment les vulnérabilités sont identifiées, suivies, priorisées, corrigées et communiquées par le biais d'une divulgation coordonnée.
- Peuvent avoir des correctifs de sécurité publiés en canonique (en open source) selon l'état actuel de la maturité de la release. Les SLO de remédiation des vulnérabilités standard ne s'appliquent pas aux fonctionnalités bêta.
- Doivent disposer d'un plan documenté et aligné avec les parties prenantes pour la mise en œuvre de la journalisation d'audit avant la disponibilité générale. Ce plan doit spécifier quels événements sont enregistrés, le format et la rétention des journaux, la façon dont les équipes de sécurité accéderont aux journaux, et les points d'intégration avec les systèmes d'audit existants.
- Nécessitent l'approbation du e-group pour les exceptions permettant de passer en GA sans satisfaire aux exigences GA énoncées.

### Fonctionnalités à disponibilité limitée {#limited-availability-features}

- Doivent disposer d'un processus de release de sécurité opérationnel permettant une remédiation sécurisée des vulnérabilités sans divulgation publique prématurée.
- Doivent disposer d'une journalisation d'audit opérationnelle permettant aux équipes de sécurité (internes et client) de détecter les comportements anormaux, d'enquêter sur les incidents de sécurité et de répondre aux questions fondamentales sur qui, quoi, où et quand. La journalisation d'audit ne nécessite pas une interface utilisateur soignée, mais doit fournir un accès programmatique aux événements pertinents pour la sécurité.
- Doivent disposer d'une [documentation de runbook opérationnelle](https://gitlab.com/gitlab-com/runbooks/-/tree/master/docs).

### Fonctionnalités en disponibilité générale {#generally-available-features}

- Doivent avoir une revue de sécurité complétée avant de passer en GA. La portée de la revue de sécurité est déterminée par les caractéristiques de la fonctionnalité (fonctionnalité orientée client, impact sur l'infrastructure, modèles d'accès aux données). Les fonctionnalités passant en GA avec des revues de sécurité partiellement complètes nécessitent l'approbation du E-Group.
- Se conformer aux SLO de remédiation des vulnérabilités et ne pas publier avec des vulnérabilités S1/S2 sans acceptation documentée des risques de la part du E-Group. Appliquer le test de réponse aux incidents : les fonctionnalités ne doivent pas être publiées avec des risques qui déclencheraient des correctifs urgents si découverts après la GA.
- Doivent disposer d'un processus de release de sécurité opérationnel permettant une remédiation sécurisée des vulnérabilités sans divulgation publique prématurée.
- Doivent disposer d'une journalisation d'audit opérationnelle permettant aux équipes de sécurité (internes et client) de détecter les comportements anormaux, d'enquêter sur les incidents de sécurité et de répondre aux questions fondamentales sur qui, quoi, où et quand. La journalisation d'audit ne nécessite pas une interface utilisateur soignée, mais doit fournir un accès programmatique aux événements pertinents pour la sécurité.

## Gouvernance des exceptions {#exception-governance}

Dans des circonstances exceptionnelles où les besoins métier nécessitent de déroger à ces exigences, GitLab suit un processus d'exception documenté avec l'approbation de la direction exécutive et l'acceptation des risques.
