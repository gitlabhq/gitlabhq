---
stage: Application Security Testing
group: Static Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Triage
description: Séparation des vulnérabilités par statut.
---

Le triage est la deuxième phase du cycle de vie de la gestion des vulnérabilités : détecter, trier, analyser, remédier.

Le triage est un processus continu d'évaluation de chaque vulnérabilité afin de déterminer lesquelles nécessitent une attention immédiate et lesquelles sont moins critiques. Les vulnérabilités à risque élevé sont séparées des menaces à risque moyen ou faible. Il n'est pas toujours possible ni faisable d'analyser et de remédier à chaque vulnérabilité. Dans le cadre d'un dispositif de gestion des risques, le triage permet de s'assurer que les ressources sont utilisées là où elles sont les plus efficaces. Il est préférable de trier les vulnérabilités régulièrement, afin que le nombre de vulnérabilités par cycle de triage reste faible et gérable.

L'objectif de la phase de triage est de confirmer ou de rejeter chaque vulnérabilité. Une vulnérabilité confirmée passe à la phase d'analyse, contrairement à une vulnérabilité rejetée.

Utilisez les données contenues dans le tableau de bord de sécurité, l'inventaire de sécurité et le rapport de vulnérabilités pour trier les vulnérabilités de manière efficace et efficiente.

## Portée {#scope}

La portée de la phase de triage inclut toutes les vulnérabilités qui n'ont pas encore été évaluées.

Filtrez le rapport de vulnérabilités pour identifier les vulnérabilités nécessitant un triage :

- **Statut** : Nécessite une priorisation

## Analyse des risques {#risk-analysis}

Vous devez effectuer le triage des vulnérabilités conformément à un cadre d'évaluation des risques. Selon votre secteur d'activité ou votre zone géographique, la conformité à un cadre peut être imposée par la loi. Dans le cas contraire, vous devriez utiliser un cadre d'évaluation des risques reconnu, par exemple :

- [SANS Institute Vulnerability Management Framework](https://www.sans.org/blog/the-vulnerability-assessment-framework)
- [OWASP Threat and Safeguard Matrix (TaSM)](https://owasp.org/www-project-threat-and-safeguard-matrix/)

Si disponible, utilisez l'[agent Security Analyst](../../duo_agent_platform/agents/foundational_agents/security_analyst_agent.md) pour accélérer votre analyse des vulnérabilités. L'agent effectue efficacement le triage, l'évaluation et la remédiation des résultats de sécurité en fournissant des informations, des évaluations des risques et des conseils de remédiation.

En général, le temps et les efforts consacrés à une vulnérabilité doivent être proportionnels à son risque. Par exemple, votre stratégie de triage peut stipuler que seules les vulnérabilités à risque critique et élevé passent à la phase d'analyse, les autres étant rejetées. Vous devez prendre cette décision en fonction de votre seuil de tolérance au risque pour les vulnérabilités.

Après avoir effectué le triage d'une vulnérabilité, vous devez modifier son statut en choisissant l'une des options suivantes :

- **Confirmé** : vous avez effectué le triage de cette vulnérabilité et décidé qu'elle nécessite une analyse.
- **Rejeté** : vous avez effectué le triage de cette vulnérabilité et décidé de ne pas procéder à son analyse.

Lorsque vous rejetez une vulnérabilité, vous devez fournir un bref commentaire indiquant les raisons de ce rejet. Les vulnérabilités rejetées sont ignorées si elles sont détectées lors d'analyses ultérieures. Les enregistrements de vulnérabilités sont permanents, mais vous pouvez modifier le statut d'une vulnérabilité à tout moment.

## Stratégies de triage {#triage-strategies}

Essayez ces stratégies pour vous concentrer en priorité sur les vulnérabilités les plus importantes.

### Prioriser les vulnérabilités présentant un risque significatif {#prioritize-vulnerabilities-of-significant-risk}

Priorisez les vulnérabilités en fonction de leur risque.

- Utilisez le [composant CI/CD Vulnerability Prioritizer](../vulnerabilities/risk_assessment_data.md#vulnerability-prioritizer) pour aider à prioriser les vulnérabilités. Par exemple, les vulnérabilités figurant dans le catalogue CISA Known Exploited Vulnerabilities (KEV) doivent être analysées et faire l'objet d'une remédiation en priorité absolue, car elles sont connues pour avoir été exploitées.
- Pour chaque groupe, accédez à **Inventaire de sécurité** pour visualiser les actifs que vous devez sécuriser et comprendre les actions à entreprendre pour améliorer votre posture de sécurité.
- Pour chaque groupe, accédez au **Tableau de bord de sécurité** et consultez le panneau **État de la sécurité du projet**. Cela regroupe les projets en fonction de leur vulnérabilité de gravité la plus élevée. Utilisez ce regroupement pour prioriser le triage des vulnérabilités dans chaque projet.
- Priorisez le triage des vulnérabilités sur vos projets les plus prioritaires, par exemple les applications déployées auprès des clients.
- Pour chaque projet, consultez le rapport de vulnérabilités. Regroupez les vulnérabilités par gravité et changez le statut de toutes les vulnérabilités de gravité critique et élevée en « Confirmée ».

### Rejeter les vulnérabilités à faible risque {#dismiss-vulnerabilities-of-low-risk}

Effectuez un triage en masse des vulnérabilités à faible risque pour vous concentrer sur les plus importantes.

- Les vulnérabilités sont parfois détectées, puis ne sont plus détectées dans les pipelines CI/CD ultérieurs. Dans ce cas, l'activité de la vulnérabilité est libellée **N'est plus détectée**. Vous pouvez choisir de rejeter ces vulnérabilités si leur gravité est **Niveau faible** ou **Infos**. Utilisez le filtre **Activité : n'est plus détectée** dans le rapport de vulnérabilités pour les sélectionner et modifier leur statut en **Rejetée**. Vous pouvez également automatiser cette opération en utilisant une [politique de gestion des vulnérabilités](../policies/vulnerability_management_policy.md).
- Rejetez les vulnérabilités par identifiant. Si une vulnérabilité est atténuée par des contrôles externes à la couche applicative, vous pouvez choisir de la rejeter. Utilisez le filtre **Identifiant** dans le rapport de vulnérabilités pour les sélectionner et modifier leur statut en **Rejetée**.
