---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Renforcement de la sécurité – Recommandations CI/CD
---

Les directives et philosophies générales de renforcement de la sécurité sont décrites dans la [documentation principale sur le renforcement de la sécurité](hardening.md).

Les recommandations et concepts de renforcement de la sécurité pour CI/CD sont présentés dans la section suivante.

## Recommandations de base {#basic-recommendations}

La façon dont vous configurez les différents paramètres CI/CD dépend de votre utilisation de CI/CD. Par exemple, si vous l'utilisez pour créer des packages, vous avez souvent besoin d'un accès en temps réel à des ressources externes telles que des images Docker ou des dépôts de code externes. Si vous l'utilisez pour l'Infrastructure as Code (IaC), vous devez souvent stocker des identifiants pour les systèmes externes afin d'automatiser le déploiement. Pour ces scénarios et bien d'autres, vous devez stocker des informations potentiellement sensibles à utiliser lors des opérations CI/CD. Les scénarios individuels étant nombreux, certaines informations de base sont résumées pour vous aider à renforcer la sécurité du processus CI/CD.

Les recommandations générales sont les suivantes :

- Protéger les secrets.
- Veiller à ce que les communications réseau soient chiffrées.
- Utiliser une journalisation approfondie à des fins d'audit et de dépannage.

## Recommandations spécifiques {#specific-recommendations}

Les pipelines sont un composant central de GitLab CI/CD qui exécutent des jobs par étapes pour automatiser des tâches au nom des utilisateurs d'un projet. Pour obtenir des directives spécifiques sur la gestion des pipelines, consultez les informations sur la [sécurité des pipelines](../ci/pipeline_security/_index.md).

Le déploiement est la partie de CI/CD qui déploie les résultats du pipeline en relation avec un environnement donné. Les paramètres par défaut n'imposent pas beaucoup de restrictions, et comme différents utilisateurs avec différents rôles et responsabilités peuvent déclencher des pipelines pouvant interagir avec ces environnements, vous devez restreindre ces environnements. Pour plus d'informations, consultez la section [environnements protégés](../ci/environments/protected_environments.md).
