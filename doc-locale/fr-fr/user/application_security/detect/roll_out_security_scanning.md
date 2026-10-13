---
stage: Secure
group: Static Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 'Déployer les tests de sécurité des applications'
---

Planifiez votre implémentation des tests de sécurité des applications par phases afin d'assurer une transition en douceur vers une pratique de développement plus sécurisée.

Ce guide vous aide à implémenter les tests de sécurité des applications GitLab au sein de votre organisation par phases. En commençant par un groupe pilote et en élargissant progressivement la couverture, vous pouvez minimiser les perturbations tout en maximisant les bénéfices en matière de sécurité. L'approche par phases permet à votre équipe de se familiariser avec les outils et les workflows de tests de sécurité des applications avant de les étendre à tous les projets.

Prérequis :

- GitLab Ultimate.
- Connaissance des pipelines CI/CD de GitLab. Les cours GitLab en autonomie suivants constituent une bonne introduction :
  - [Introduction to CI/CD](https://university.gitlab.com/courses/introduction-to-cicd-s2)
  - [Hands-on Labs : CI Fundamentals](https://university.gitlab.com/courses/hands-on-labs-ci-fundamentals)
- Compréhension des exigences de sécurité et de la tolérance au risque de votre organisation.

## Portée {#scope}

Ce guide explique comment planifier et exécuter une implémentation par phases des fonctionnalités de tests de sécurité des applications GitLab, notamment la configuration, la gestion des vulnérabilités et les stratégies de prévention. Il suppose que vous souhaitez introduire progressivement les tests de sécurité des applications afin de minimiser les perturbations des workflows existants tout en sécurisant votre base de code.

## Phases {#phases}

L'implémentation se compose de deux phases principales :

1. **Phase pilote** : implémenter les tests de sécurité des applications pour un ensemble limité de projets afin de valider les configurations et de former les équipes.
1. **Phase de déploiement** : étendre les tests de sécurité des applications à tous les projets cibles en utilisant les connaissances acquises lors du pilote.

## Phase pilote {#pilot-phase}

La phase pilote vous permet d'appliquer les tests de sécurité des applications avec un risque minimal avant un déploiement plus large.

Tenez compte des conseils suivants avant de démarrer la phase pilote :

- Identifiez les parties prenantes clés, notamment les membres de l'équipe de sécurité, les développeurs et les chefs de projet.
- Sélectionnez des projets pilotes représentatifs de votre base de code, mais non essentiels aux opérations quotidiennes.
- Planifiez des sessions de formation pour les développeurs et les membres de l'équipe de sécurité.
- Documentez les pratiques de sécurité actuelles afin de mesurer les améliorations.

### Objectifs du pilote {#pilot-goals}

La phase pilote vous aide à atteindre plusieurs objectifs clés :

- Implémenter les tests de sécurité des applications sans ralentir le développement

  Pendant le pilote, les résultats des tests de sécurité des applications sont disponibles pour les développeurs dans l'interface utilisateur, sans bloquer les merge requests. Cette approche minimise les risques pour les projets en dehors de la portée du pilote, tout en collectant des données précieuses sur votre posture de sécurité actuelle. Dans la phase de déploiement, vous devriez utiliser une [politique d'approbation des merge requests](#merge-request-approval-policy) pour ajouter une porte d'approbation supplémentaire lorsque des vulnérabilités sont détectées dans les merge requests.
- Établir des méthodes de détection évolutives

  Implémentez les tests de sécurité des applications sur les projets pilotes de façon à pouvoir les étendre à tous les projets dans le cadre du déploiement plus large. Privilégiez des configurations qui s'adaptent bien à l'échelle et peuvent être standardisées entre les projets.
- Tester les durées de scan

  Testez les durées de scan sur des bases de code et des applications représentatives.
- Simuler le workflow de remédiation des vulnérabilités

  Simulez la détection, la priorisation, l'analyse et la remédiation des vulnérabilités dans les workflows des développeurs. Vérifiez que les ingénieurs peuvent agir sur les résultats.
- Comparer les coûts de maintenance

  Comparez la maintenance d'une solution unique par rapport à l'intégration de plusieurs solutions endpoint. Dans quelle mesure cette solution s'intègre-t-elle à l'IDE, aux merge requests et au pipeline ?

#### Avantages pour les développeurs {#benefits-for-developers}

Les développeurs du groupe pilote bénéficieront des avantages suivants :

- Familiarisation avec les méthodes de tests de sécurité des applications et la façon d'interpréter les résultats.
- Expérience dans la prévention de la fusion de vulnérabilités dans la branche par défaut.
- Compréhension du workflow de gestion des vulnérabilités qui commence lorsqu'une vulnérabilité est détectée dans la branche par défaut.

#### Avantages pour la gestion de la sécurité {#benefits-for-security-management}

Les membres de l'équipe de sécurité participant au pilote bénéficieront des avantages suivants :

- Expérience du suivi et de la gestion des vulnérabilités dans GitLab.
- Données permettant d'établir des niveaux de référence en matière de sécurité et de définir des objectifs de remédiation réalistes.
- Informations pour affiner la politique de sécurité avant le déploiement plus large.

### Plan du pilote {#pilot-plan}

Une planification appropriée garantit une phase pilote efficace.

#### Rôles et responsabilités {#roles-and-responsibilities}

Définissez les personnes responsables de :

- La configuration des tests de sécurité des applications
- L'examen des résultats de scan
- La priorisation des vulnérabilités
- La gestion de la remédiation
- La formation des membres de l'équipe
- La mesure du succès du pilote

### Portée du pilote {#pilot-scope}

Sélectionnez soigneusement les projets à inclure dans la phase pilote.

Prenez en compte ces facteurs lors de la sélection des projets pilotes :

- Incluez des projets avec différentes stacks technologiques pour tester l'efficacité des tests de sécurité des applications.
- Choisissez des projets en développement actif pour obtenir des résultats en temps réel.
- Sélectionnez des projets dont les équipes sont prêtes à adopter de nouvelles pratiques de sécurité.
- Évitez de commencer par des applications critiques.

### Ordre des tests de sécurité des applications {#application-security-testing-order}

Introduisez les tests de sécurité des applications dans l'ordre suivant. Cet ordre équilibre la valeur apportée et la facilité de déploiement.

- Analyse des dépendances
- SAST
- Advanced SAST
- Détection des secrets des pipelines
- Protection contre l'envoi de secrets par push
- Analyse des conteneurs
- DAST
- Tests de sécurité des API
- Analyse IaC
- Analyse opérationnelle de conteneurs

## Tester les projets pilotes {#test-pilot-projects}

Une fois la planification terminée, commencez à implémenter les tests de sécurité des applications sur vos projets pilotes.

### Configurer les tests des projets pilotes {#set-up-testing-of-pilot-projects}

Prérequis :

- Vous devez disposer du rôle Maintainer pour les projets sur lesquels les tests de sécurité des applications doivent être activés.

Pour chaque projet dans la portée :

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à**, puis recherchez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Sécurisation** > **Configuration de la sécurité**.
1. Développez **Configuration de la sécurité**.
1. Activez les tests de sécurité des applications appropriés en fonction de la stack de votre projet.

Pour en savoir plus, consultez [la configuration de sécurité](security_configuration.md).

### Pour les développeurs {#for-developers}

Présentez aux développeurs les outils qui permettent de visualiser les résultats de sécurité.

#### Résultats du pipeline {#pipeline-results}

Les développeurs peuvent consulter les résultats de sécurité directement dans les résultats du pipeline.

Prérequis :

- Disposer du rôle Développeur, Chargé de maintenance ou Propriétaire pour le projet.

Pour consulter les résultats du pipeline :

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à**, puis recherchez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Compilation** > **Pipelines**.
1. Sélectionnez le pipeline à examiner.
1. Dans les détails du pipeline, sélectionnez l'onglet **Sécurité** pour afficher les vulnérabilités détectées.

Pour plus de détails, consultez [Afficher les résultats des scans de sécurité dans les pipelines](security_scanning_results.md).

#### Rapports de merge request {#merge-request-reports}

Pour les résultats des scans de sécurité dans une merge request, consultez [les rapports de merge request](../../project/merge_requests/reports.md).

#### Intégration VS Code {#vs-code-integration}

Les développeurs peuvent consulter les résultats de sécurité directement dans leur IDE.

Prérequis :

- Disposer du rôle Développeur, Chargé de maintenance ou Propriétaire pour le projet.

Pour consulter les résultats de sécurité dans VS Code :

1. Installez l'extension GitLab pour VS Code.
1. Connectez l'extension à votre instance GitLab.
1. Utilisez l'extension pour consulter les résultats de sécurité sans quitter votre environnement de développement.

Pour plus de détails, consultez [l'extension GitLab pour VS Code](../../../editor_extensions/visual_studio_code/_index.md).

## Workflow de gestion des vulnérabilités {#vulnerability-management-workflow}

Établissez un workflow structuré pour gérer les vulnérabilités détectées.

Le workflow de gestion des vulnérabilités comprend quatre étapes clés :

1. **Détecter** : trouvez les vulnérabilités grâce aux tests de sécurité des applications automatisés dans les pipelines.
1. **Priorisation** : évaluez la gravité et l'impact des vulnérabilités détectées.
1. **Analyse** : analysez la cause profonde et déterminez la meilleure approche de remédiation.
1. **Remédier** : implémentez des correctifs pour résoudre les vulnérabilités.

### Priorisation efficace {#efficient-triage}

GitLab propose plusieurs fonctionnalités pour simplifier la priorisation des vulnérabilités :

- Filtres de vulnérabilités pour se concentrer en priorité sur les problèmes à fort impact.
- Niveaux de gravité et de confiance pour prioriser les efforts.
- Suivi des vulnérabilités pour maintenir la visibilité des problèmes en suspens.
- Données d'évaluation des risques.

Pour plus de détails, consultez [Priorisation](../triage/_index.md).

La priorisation doit inclure des revues régulières du rapport de vulnérabilités avec les parties prenantes de la sécurité.

### Remédiation efficace {#efficient-remediation}

Simplifiez le processus de remédiation grâce à ces fonctionnalités GitLab :

- Suggestions de remédiation automatisées pour certains types de vulnérabilités.
- Création de merge requests directement depuis les détails de la vulnérabilité.
- Suivi de l'historique des vulnérabilités pour surveiller la progression.
- Résolution automatique des vulnérabilités qui ne sont plus détectées.

Pour plus de détails, consultez [Remédiation](../remediate/_index.md).

#### Intégration avec les systèmes de tickets {#integrate-with-ticketing-systems}

Vous pouvez utiliser un ticket GitLab pour suivre le travail de remédiation requis pour une vulnérabilité. Vous pouvez également utiliser un ticket Jira si c'est votre système de tickets principal.

Pour plus de détails, consultez [Lier une vulnérabilité aux tickets GitLab et Jira](../vulnerabilities/_index.md#linking-a-vulnerability-to-gitlab-and-jira-issues).

## Prévention des vulnérabilités {#vulnerability-prevention}

Implémentez des fonctionnalités pour empêcher l'introduction de vulnérabilités dès le départ.

### Stratégie d'approbation des requêtes de fusion {#merge-request-approval-policy}

Utilisez une politique d'approbation des merge requests pour ajouter une exigence d'approbation supplémentaire si le nombre et la gravité des vulnérabilités dans une merge request dépassent un seuil spécifique. Cela permet une revue supplémentaire de la part d'un membre de l'équipe de sécurité des applications, offrant un niveau de contrôle supplémentaire.

Prérequis :

- Le rôle Owner pour le groupe, ou un rôle personnalisé avec la permission `manage_security_policy_link`.

Pour configurer des politiques d'approbation afin d'exiger des revues de sécurité :

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à**, puis recherchez votre groupe.
1. Dans la barre latérale gauche, sélectionnez **Sécuriser** > **Politiques**.
1. Sélectionnez **Nouvelle politique**
1. Dans le volet **Stratégie d'approbation des requêtes de fusion**, sélectionnez **Sélectionner la politique**.
1. Ajoutez une politique d'approbation des merge requests exigeant l'approbation des membres de l'équipe de sécurité.

Pour plus de détails, consultez [Approbations de sécurité dans les merge requests](../policies/merge_request_approval_policies.md).

## Phase de déploiement {#rollout-phase}

Après un pilote réussi, étendez les tests de sécurité des applications à tous les projets cibles.

Avant de démarrer la phase de déploiement, tenez compte des points suivants :

- Évaluez les résultats de la phase pilote.
- Documentez les leçons apprises et les bonnes pratiques.
- Préparez des supports de formation basés sur les expériences du pilote.
- Mettez à jour les plans d'implémentation en fonction des retours du pilote.

### Définir les accès des membres de l'équipe {#define-access-to-team-members}

Les tâches de tests de sécurité des applications nécessitent des rôles ou des permissions spécifiques. Pour chaque personne participant aux phases de déploiement, définissez ses accès en fonction des tâches qu'elle effectuera.

- Les utilisateurs disposant du rôle Developer peuvent consulter les vulnérabilités sur leurs projets et leurs merge requests.
- Les utilisateurs disposant du rôle Maintainer peuvent configurer les configurations de sécurité pour les projets.
- Les utilisateurs auxquels est attribué un rôle personnalisé avec la permission `admin_vulnerability` peuvent gérer et prioriser les vulnérabilités.
- Les utilisateurs auxquels est attribué un rôle personnalisé avec la permission `manage_security_policy_link` peuvent appliquer des politiques sur les groupes et les projets.

Pour plus de détails, consultez [Rôles et permissions](../../permissions.md#group-application-security).

### Objectifs du déploiement {#rollout-goals}

La phase de déploiement vise à implémenter les tests de sécurité des applications sur tous les projets dans la portée, en utilisant les connaissances et l'expérience acquises lors du pilote.

### Plan de déploiement {#rollout-plan}

Examinez et mettez à jour les rôles et les responsabilités établis pendant le pilote. La même structure d'équipe devrait fonctionner pour le déploiement, mais vous devrez peut-être ajouter des membres supplémentaires à mesure que la portée s'élargit.

## Implémenter les tests de sécurité des applications à grande échelle {#implement-application-security-testing-at-scale}

Utilisez les fonctionnalités de politique pour faire évoluer efficacement votre implémentation de sécurité.

### Utiliser l'héritage des politiques {#use-policy-inheritance}

Utilisez l'héritage des politiques pour maximiser l'efficacité tout en minimisant le nombre de politiques à gérer.

Considérez le scénario dans lequel vous disposez d'un groupe principal nommé Finance, qui contient les sous-groupes A, B et C. Vous souhaitez exécuter l'analyse des dépendances et la détection des secrets sur tous les projets du groupe Finance. Pour chaque sous-groupe, vous souhaitez exécuter différents ensembles d'outils de tests de sécurité des applications.

Pour atteindre cet objectif, vous pourriez définir 3 politiques pour le groupe Finance :

- Politique 1 :
  - Inclut l'analyse des dépendances et la détection des secrets.
  - S'applique au groupe Finance, à tous ses sous-groupes et à leurs projets.
- Politique 2 :
  - Inclut DAST et les tests de sécurité des API.
  - Limitée aux sous-groupes A et B uniquement.
- Politique 3 :
  - Inclut SAST.
  - Limitée au sous-groupe C uniquement.

Un seul ensemble de politiques doit être maintenu, tout en offrant la flexibilité nécessaire pour répondre aux besoins des différents projets.

Pour plus de détails, consultez [Application des politiques](../policies/enforcement/_index.md#enforcement).

### Configurer les politiques d'exécution de scan {#configure-scan-execution-policies}

Implémentez des tests de sécurité des applications cohérents sur plusieurs projets en utilisant des politiques d'exécution de scan.

Prérequis :

- Vous devez disposer du rôle Owner, ou d'un rôle personnalisé avec la permission `manage_security_policy_link`, pour les groupes sur lesquels les tests de sécurité des applications doivent être activés.

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à**, puis recherchez votre projet ou votre groupe.
1. Dans la barre latérale gauche, sélectionnez **Sécuriser** > **Politiques**.
1. Créez des politiques d'exécution de scan basées sur la configuration des tests de sécurité des applications utilisée pendant la phase pilote.

Pour plus de détails, consultez [Politiques de sécurité](../policies/_index.md).

### Déployer progressivement {#scale-gradually}

Déployez progressivement, d'abord sur les projets pilotes, puis de façon incrémentale sur tous les projets cibles. Lors de l'application de politiques à tous les groupes et projets, sensibilisez l'ensemble des parties prenantes des projets, car cela peut avoir un impact sur les changements dans les pipelines et les workflows de merge requests. Par exemple, notifiez les parties prenantes

Implémentez vos politiques de sécurité par phases :

1. Commencez par appliquer les politiques aux projets de la phase pilote.
1. Surveillez tout problème ou perturbation éventuel.
1. Élargissez progressivement la portée des politiques pour inclure davantage de projets.
1. Continuez jusqu'à ce que tous les projets cibles soient couverts.

Pour plus de détails, consultez les [directives de conception des politiques](../policies/enforcement/_index.md#policy-design-guidelines).
