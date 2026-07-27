---
stage: Application Security Testing
group: Dynamic Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Vulnérabilité Heartbleed OpenSSL
---

## Description {#description}

Vérification de la vulnérabilité Heartbleed OpenSSL.

## Remédiation {#remediation}

La vulnérabilité Heartbleed est un bug grave dans la populaire bibliothèque cryptographique OpenSSL. OpenSSL est utilisé pour chiffrer et déchiffrer les communications et sécuriser le trafic Internet. Cette vulnérabilité permet à un attaquant de dérober des informations protégées, qui ne devraient pas être accessibles dans d'autres circonstances, telles que les clés secrètes utilisées pour chiffrer des informations sensibles.

Toute personne ayant accès à l'API cible peut exploiter la vulnérabilité Heartbleed pour lire la mémoire de systèmes protégés en tirant parti des versions vulnérables de la bibliothèque OpenSSL.

## Liens {#links}

- [OWASP](https://owasp.org/Top10/A06_2021-Vulnerable_and_Outdated_Components/)
- [CWE](https://cwe.mitre.org/data/definitions/119.html)
