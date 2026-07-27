---
stage: Application Security Testing
group: Dynamic Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Authentification en clair
---

## Description {#description}

Cette vérification recherche les authentifications en clair, telles que l'authentification HTTP Basic sans TLS.

## Remédiation {#remediation}

Les identifiants d'authentification sont transmis via un canal non chiffré (HTTP). Cela expose les identifiants transmis à tout attaquant capable de surveiller (intercepter) le trafic réseau lors de la transmission. Les informations sensibles telles que les identifiants doivent toujours être transmises via des canaux chiffrés tels que HTTPS.

## Liens {#links}

- [OWASP](https://owasp.org/Top10/A02_2021-Cryptographic_Failures/)
- [CWE](https://cwe.mitre.org/data/definitions/319.html)
