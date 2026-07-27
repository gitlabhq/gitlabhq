---
stage: Application Security Testing
group: Dynamic Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Shellshock
---

## Description {#description}

Vérifier la présence de vulnérabilités Shellshock.

## Remédiation {#remediation}

La vulnérabilité Shellshock exploite un bug dans BASH, dans lequel BASH exécute incorrectement des commandes en fin de chaîne lorsqu'il importe une définition de fonction stockée dans une variable d'environnement. Tout environnement permettant de définir des variables d'environnement BASH pourrait être vulnérable à ce bug, comme par exemple un serveur Web Apache utilisant les modules mod_cgi et mod_cgid. Une requête connue comme valide a été modifiée pour inclure du contenu malveillant. Le contenu malveillant inclut une attaque Shell shock dans laquelle l'application côté serveur renvoie un texte spécifique (preuve) dans les en-têtes de réponse.

## Liens {#links}

- [OWASP](https://owasp.org/Top10/A03_2021-Injection/)
- [CWE](https://cwe.mitre.org/data/definitions/78.html)
