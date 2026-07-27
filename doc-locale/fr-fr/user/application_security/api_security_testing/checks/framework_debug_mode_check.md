---
stage: Application Security Testing
group: Dynamic Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Mode debug du framework
---

## Description {#description}

Vérifie si le mode debug est activé dans divers frameworks tels que Flask et ASP.NET. Cette vérification présente un faible taux de faux positifs.

## Remédiation {#remediation}

Le framework Flask ou ASP .NET a été identifié avec le mode debug activé. Cela permet à un attaquant de télécharger n'importe quel fichier sur le système de fichiers, ainsi que d'autres capacités. Il s'agit d'un problème de gravité élevée qu'un attaquant peut facilement exploiter.

## Liens {#links}

- [OWASP](https://owasp.org/Top10/A05_2021-Security_Misconfiguration/)
- [CWE-23 : Traversée de chemin relatif](https://cwe.mitre.org/data/definitions/23.html)
- [CWE-285 : Autorisation incorrecte](https://cwe.mitre.org/data/definitions/285.html)
