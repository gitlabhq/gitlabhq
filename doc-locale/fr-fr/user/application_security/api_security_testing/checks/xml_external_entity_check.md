---
stage: Application Security Testing
group: Dynamic Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Entité externe XML
---

## Description {#description}

Vérifier les vulnérabilités de traitement XML DTD.

## Remédiation {#remediation}

L'attaque par entité externe XML est un type d'attaque contre une application qui analyse des entrées XML. Cette attaque se produit lorsqu'une entrée XML contenant une référence à une entité externe est traitée par un analyseur XML mal configuré. Cette attaque peut entraîner la divulgation de données confidentielles, un déni de service, une falsification de requêtes côté serveur, un balayage de ports du point de vue de la machine sur laquelle se trouve l'analyseur, ainsi que d'autres impacts sur le système.

## Liens {#links}

- [OWASP](https://owasp.org/Top10/A03_2021-Injection/)
- [CWE](https://cwe.mitre.org/data/definitions/611.html)
