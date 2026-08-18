---
stage: Application Security Testing
group: Dynamic Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Redirection ouverte
---

## Description {#description}

Identifier les redirections ouvertes et déterminer si elles peuvent être exploitées par des attaquants.

## Remédiation {#remediation}

Des redirections et des transferts non validés sont possibles lorsqu'une application web accepte des entrées non fiables susceptibles de l'amener à rediriger la requête vers une URL contenue dans ces entrées non fiables. En modifiant une entrée URL non fiable vers un site malveillant, un attaquant peut réussir à lancer une attaque de hameçonnage et à voler les identifiants des utilisateurs. Étant donné que le nom du serveur dans le lien modifié est identique à celui du site d'origine, les tentatives de hameçonnage peuvent sembler plus dignes de confiance. Les attaques par redirection et transfert non validés peuvent également être utilisées pour créer de manière malveillante une URL qui passerait le contrôle d'accès de l'application et redirigerait ensuite l'attaquant vers des fonctions privilégiées auxquelles il ne pourrait normalement pas accéder.

## Liens {#links}

- [OWASP](https://owasp.org/Top10/A01_2021-Broken_Access_Control/)
- [CWE](https://cwe.mitre.org/data/definitions/601.html)
