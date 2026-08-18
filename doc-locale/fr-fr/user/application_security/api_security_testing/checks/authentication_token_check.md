---
stage: Application Security Testing
group: Dynamic Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: "Jeton d'authentification"
---

## Description {#description}

Effectuez diverses vérifications du jeton d'authentification, comme la suppression du jeton ou le remplacement par une valeur non valide.

## Remédiation {#remediation}

Les jetons d'API doivent être imprévisibles (suffisamment aléatoires) pour prévenir les attaques par devinette, où un attaquant est capable de deviner ou de prédire un jeton d'API valide grâce à des techniques d'analyse statistique. À cette fin, un bon PRNG (générateur de nombres pseudo-aléatoires) doit être utilisé.

Le jeton d'authentification peut avoir été :

- modifié avec une valeur non valide.
- supprimé de la requête.
- ne pas correspondre aux exigences de longueur.
- configuré comme signature.

Une opération d'API n'a pas réussi à restreindre correctement l'accès à l'aide d'un jeton d'authentification. Cela permet à un attaquant de contourner l'authentification et d'accéder à des informations, voire de modifier des données.

## Liens {#links}

- [OWASP](https://owasp.org/Top10/A07_2021-Identification_and_Authentication_Failures/)
- [CWE](https://cwe.mitre.org/data/definitions/285.html)
