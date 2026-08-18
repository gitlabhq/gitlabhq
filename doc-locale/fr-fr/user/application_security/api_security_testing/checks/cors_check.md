---
stage: Application Security Testing
group: Dynamic Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: CORS
---

## Description {#description}

Vérifiez les erreurs de configuration CORS, notamment les listes blanches trop permissives des en-têtes Origin acceptés ou l'absence de validation de l'en-tête Origin. Vérifie également si des informations d'identification sont autorisées sur des origines potentiellement invalides ou dangereuses, ainsi que les en-têtes manquants pouvant potentiellement entraîner un empoisonnement du cache.

## Remédiation {#remediation}

Une implémentation CORS mal configurée peut être trop permissive quant aux domaines à approuver et au niveau de confiance à leur accorder. Cela pourrait permettre à un domaine non fiable de forger l'en-tête Origin et de lancer différents types d'attaques, telles que la falsification de requête intersites ou les scripts intersites. Un attaquant pourrait potentiellement voler les informations d'identification d'une victime ou envoyer des requêtes malveillantes au nom d'une victime. La victime peut même ne pas être consciente qu'une attaque est en cours.

## Liens {#links}

- [OWASP](https://owasp.org/Top10/A01_2021-Broken_Access_Control/)
- [CWE](https://cwe.mitre.org/data/definitions/942.html)
