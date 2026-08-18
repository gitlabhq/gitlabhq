---
stage: Application Security Testing
group: Dynamic Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Divulgation de fichiers sensibles
---

## Description {#description}

Vérification de la divulgation de fichiers sensibles. Cette vérification recherche les fichiers susceptibles de contenir des informations sensibles. Les exemples incluent .htaccess, .htpasswd, .bash_history, etc.

## Remédiation {#remediation}

La fuite d'informations est une faiblesse applicative par laquelle une application révèle des données sensibles, telles que des détails techniques de l'application web, de l'environnement ou des données propres aux utilisateurs. Des données sensibles peuvent être utilisées par un attaquant pour exploiter l'application web cible, son réseau d'hébergement ou ses utilisateurs. Par conséquent, la fuite de données sensibles doit être limitée ou évitée dans la mesure du possible. La fuite d'informations, sous sa forme la plus courante, est le résultat d'une ou de plusieurs des conditions suivantes : Un échec à supprimer les commentaires HTML/Script contenant des informations sensibles, des configurations incorrectes de l'application ou du serveur, ou des différences dans les réponses de page pour des données valides par rapport à des données invalides.

Dans le cas de cette défaillance, un ou plusieurs fichiers et/ou dossiers sont accessibles alors qu'ils ne devraient pas l'être. Cela peut inclure des fichiers courants dans les dossiers personnels, tels que des historiques de commandes ou des fichiers contenant des secrets comme des mots de passe.

## Liens {#links}

- [OWASP](https://owasp.org/Top10/A01_2021-Broken_Access_Control/)
- [CWE](https://cwe.mitre.org/data/definitions/200.html)
