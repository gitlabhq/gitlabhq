---
stage: Application Security Testing
group: Dynamic Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Méthodes HTTP non sécurisées
---

## Description {#description}

Vérifie si les méthodes HTTP telles qu'OPTIONS et TRACE sont activées sur les points de terminaison cibles.

## Remédiation {#remediation}

La ressource testée prend en charge la méthode HTTP OPTIONS. En général, cela est considéré comme une mauvaise configuration de sécurité, car cela expose les méthodes HTTP prises en charge, permettant ainsi la collecte d'informations sur un serveur ou une ressource spécifique. Cependant, une partie de la communauté API cherche à utiliser OPTIONS comme méthode de découverte automatique des opérations sur les ressources. Si telle est l'utilisation prévue pour l'activation d'OPTIONS, ce ticket peut être considéré comme un faux positif.

La ressource testée prend en charge la méthode HTTP TRACE. En combinaison avec d'autres vulnérabilités inter-domaines dans les navigateurs Web, des informations sensibles peuvent être divulguées depuis les en-têtes. Il est recommandé de désactiver la méthode TRACE dans votre serveur/framework.

## Liens {#links}

- [OWASP](https://owasp.org/Top10/A05_2021-Security_Misconfiguration/)
- [CWE](https://cwe.mitre.org/data/definitions/200.html)
