---
stage: Application Security Testing
group: Static Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Analyser
description: Analyse et évaluation des vulnérabilités.
---

L'analyse est la troisième phase du cycle de vie de gestion des vulnérabilités : détecter, trier, analyser, remédier.

L'analyse est le processus d'évaluation des détails d'une vulnérabilité pour déterminer si elle peut et doit faire l'objet d'une remédiation. Les vulnérabilités peuvent être triées en masse, mais l'analyse doit être effectuée individuellement. Dans le cadre d'un framework de gestion des risques, l'analyse permet de s'assurer que les ressources sont appliquées là où elles sont les plus efficaces. Utilisez les données contenues dans le tableau de bord de sécurité et le rapport de vulnérabilités pour prioriser l'analyse des vulnérabilités en fonction de leur gravité et du risque associé.

## Portée {#scope}

La portée de la phase d'analyse comprend toutes les vulnérabilités qui ont traversé la phase de triage et ont été confirmées comme nécessitant une action supplémentaire.

Filtrez le rapport de vulnérabilités pour identifier les vulnérabilités nécessitant une analyse :

- **Statut** : confirmé

## Analyse des risques {#risk-analysis}

Vous devez conduire l'analyse des vulnérabilités selon un framework d'évaluation des risques. Si vous n'utilisez pas encore de framework d'évaluation des risques, envisagez les options suivantes :

- [SANS Institute Vulnerability Management Framework](https://www.sans.org/blog/the-vulnerability-assessment-framework/)
- [OWASP Threat and Safeguard Matrix (TaSM)](https://owasp.org/www-project-threat-and-safeguard-matrix/)

Si disponible, utilisez l'[agent Security Analyst](../../duo_agent_platform/agents/foundational_agents/security_analyst_agent.md) pour accélérer votre analyse des vulnérabilités. L'agent trie, évalue et remédie efficacement aux résultats de sécurité en fournissant des informations, des évaluations des risques et des conseils de remédiation.

Le calcul du score de risque d'une vulnérabilité dépend de critères spécifiques à votre organisation. Une formule de score de risque de base est :

Risque = Probabilité x Impact

Les valeurs de probabilité et d'impact varient en fonction de la vulnérabilité et de votre environnement. La détermination de ces valeurs et le calcul d'un score de risque peuvent nécessiter des informations non disponibles dans GitLab. Vous devez à la place les calculer selon votre framework de gestion des risques. Après les avoir calculées, consignez-les dans le ticket que vous avez créé pour la vulnérabilité.

En général, le temps et les efforts consacrés à une vulnérabilité doivent être proportionnels à son risque. Par exemple, vous pouvez choisir d'analyser uniquement les vulnérabilités présentant un risque critique ou élevé et d'ignorer les autres. Vous devez prendre cette décision en fonction de votre seuil de risque pour les vulnérabilités.

## Stratégies d'analyse {#analysis-strategies}

Essayez ces stratégies pour vous concentrer en priorité sur les vulnérabilités les plus importantes.

### Prioriser les vulnérabilités de gravité la plus élevée {#prioritize-vulnerabilities-of-highest-severity}

Pour aider à identifier les vulnérabilités de gravité la plus élevée :

- Si vous ne l'avez pas déjà fait lors de la phase de triage, utilisez le [composant CI/CD Vulnerability Prioritizer](../vulnerabilities/risk_assessment_data.md#vulnerability-prioritizer) pour aider à prioriser les vulnérabilités à analyser.
- Pour chaque groupe, filtrez le rapport de vulnérabilités pour prioriser les vulnérabilités nécessitant une analyse :

  - **Statut** : confirmé
  - **Activité** : toujours détectée
  - **Regrouper par** : gravité
- Priorisez l'analyse des vulnérabilités de vos projets à risque le plus élevé. Par exemple, les applications déployées auprès des clients.

### Prioriser les vulnérabilités pour lesquelles une solution est disponible {#prioritize-vulnerabilities-that-have-a-solution-available}

Certaines vulnérabilités disposent d'une solution, par exemple « Mise à niveau de la version 13.2 vers la version 13.8 ». Cela réduit le temps nécessaire pour analyser et remédier à ces vulnérabilités. Certaines solutions ne sont disponibles que si GitLab Duo est activé.

Filtrez le rapport de vulnérabilités pour identifier les vulnérabilités pour lesquelles une solution est disponible.

- Pour les vulnérabilités détectées par l'analyse SBOM, utilisez les critères suivants :
  - **Statut** : confirmé
  - **Activité** : a une solution
- Pour les vulnérabilités détectées par SAST, utilisez les critères suivants :
  - **Statut** : confirmé
  - **Activité** : résolution de vulnérabilité disponible

## Détails et actions relatifs aux vulnérabilités {#vulnerability-details-and-action}

Chaque vulnérabilité dispose d'une [page de vulnérabilité](../vulnerabilities/_index.md) qui contient des détails, notamment la date et le mode de détection, la cote de gravité, ainsi qu'un journal complet. Utilisez ces informations pour aider à analyser une vulnérabilité.

Les conseils suivants peuvent également vous aider à analyser une vulnérabilité :

- Utilisez [GitLab Duo Vulnerability Explanation](duo.md) pour aider à expliquer la vulnérabilité et suggérer une remédiation. Disponible uniquement pour les vulnérabilités détectées par SAST.
- Utilisez la [formation à la sécurité](../vulnerabilities/_index.md#view-security-training-for-a-vulnerability) fournie par des prestataires de formation tiers pour mieux comprendre la nature d'une vulnérabilité spécifique.

Après avoir analysé chaque vulnérabilité confirmée, vous devez soit :

- Laisser son statut à **Confirmée** si vous décidez qu'elle doit faire l'objet d'une remédiation.
- Changer son statut en **Rejetée** si vous décidez qu'elle ne doit pas faire l'objet d'une remédiation.

Si vous confirmez une vulnérabilité :

1. [Créez un ticket](../vulnerabilities/_index.md#create-a-gitlab-issue-for-a-vulnerability) pour suivre, documenter et gérer le travail de remédiation.
1. Passez à la phase de remédiation du cycle de vie de gestion des vulnérabilités.

Si vous rejetez une vulnérabilité, vous devez fournir un bref commentaire indiquant pourquoi vous l'avez rejetée. Les vulnérabilités rejetées sont ignorées si elles sont détectées à nouveau. Les enregistrements de vulnérabilités sont conservés à des fins d'audit (jusqu'à leur archivage). Vous pouvez gérer leur cycle de vie en mettant à jour leur statut selon les besoins.
