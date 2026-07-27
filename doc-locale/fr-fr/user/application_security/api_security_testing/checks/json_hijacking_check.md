---
stage: Application Security Testing
group: Dynamic Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Détournement JSON
---

## Description {#description}

Vérifie si les données JSON sont potentiellement vulnérables au détournement. Cette vérification recherche une requête GET qui renvoie un tableau JSON, lequel pourrait potentiellement être détourné et lu par un site web malveillant.

## Remédiation {#remediation}

Le détournement JSON permet à un attaquant d'envoyer une requête GET via un site web malveillant ou un vecteur d'attaque similaire, et d'utiliser les identifiants stockés d'un utilisateur pour récupérer des données sensibles ou protégées auxquelles cet utilisateur a accès. Un tableau JSON seul constitue du JavaScript valide ; ainsi, une requête GET malveillante vers une ressource qui ne renvoie qu'un tableau JavaScript peut permettre à l'attaquant d'utiliser un script malveillant pour lire les données du tableau issues de la requête. Les requêtes GET ne doivent jamais renvoyer un tableau JSON, même si la ressource requiert une authentification pour y accéder. Envisagez d'utiliser POST plutôt que GET pour cette requête, ou d'encapsuler le tableau dans un objet JSON.

## Liens {#links}

- [OWASP](https://owasp.org/Top10/A01_2021-Broken_Access_Control/)
- [CWE](https://cwe.mitre.org/data/definitions/352.html)
