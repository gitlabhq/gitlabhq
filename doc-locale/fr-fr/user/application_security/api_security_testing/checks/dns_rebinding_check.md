---
stage: Application Security Testing
group: Dynamic Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Rebinding DNS
---

## Description {#description}

Vérification du rebinding DNS. Cette vérification confirme que l'hôte contrôle que l'en-tête HOST de la requête existe et correspond au nom attendu de l'hôte, afin d'éviter les attaques via des entrées DNS malveillantes.

## Remédiation {#remediation}

Le rebinding DNS permet à un hôte malveillant d'usurper ou de rediriger une requête vers une adresse IP alternative, permettant potentiellement à un attaquant de contourner l'authentification ou l'autorisation de sécurité. La résolution DNS seule ne constitue pas à proprement parler un mécanisme d'authentification valide. Les serveurs doivent vérifier que l'en-tête Host de la requête correspond au nom d'hôte attendu du serveur. Dans les cas où le nom d'hôte est manquant ou ne correspond pas à la valeur attendue, le serveur doit retourner une erreur 400. L'en-tête X-Forwarded-Host est parfois utilisé à la place de l'en-tête Host dans les cas où la requête est transmise. Dans ces cas, l'en-tête X-Forwarded-Host doit également être validé s'il est utilisé pour déterminer l'hôte de la requête d'origine.

## Liens {#links}

- [OWASP](https://owasp.org/Top10/A05_2021-Security_Misconfiguration/)
- [CWE](https://cwe.mitre.org/data/definitions/350.html)
