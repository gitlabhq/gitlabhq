---
stage: Application Security Testing
group: Dynamic Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: "Divulgation d'informations sur l'application"
---

## Description {#description}

Vérification de la divulgation d'informations sur l'application. Cela inclut des informations telles que les numéros de version, les messages d'erreur de base de données et les traces de pile.

## Remédiation {#remediation}

La divulgation d'informations sur l'application est une faiblesse applicative par laquelle une application révèle des données sensibles, telles que des détails techniques de l'application web ou de son environnement. Les données de l'application peuvent être utilisées par un attaquant pour exploiter l'application web cible, son réseau d'hébergement ou ses utilisateurs. Par conséquent, la fuite de données sensibles doit être limitée ou évitée dans la mesure du possible. La divulgation d'informations, dans sa forme la plus courante, est le résultat d'une ou plusieurs des conditions suivantes : un échec à supprimer les commentaires HTML ou de script contenant des informations sensibles, ou des configurations incorrectes de l'application ou du serveur.

L'absence de suppression des commentaires HTML ou de script avant un déploiement en environnement de production peut entraîner la fuite d'informations sensibles et contextuelles, telles que la structure des répertoires du serveur, la structure des requêtes SQL et les informations sur le réseau interne. Il est fréquent qu'un développeur laisse des commentaires dans le code HTML et le code de script pour faciliter le débogage ou le processus d'intégration durant la phase de pré-production. Bien qu'il n'y ait aucun inconvénient à autoriser les développeurs à inclure des commentaires en ligne dans le contenu qu'ils développent, ces commentaires doivent tous être supprimés avant la release publique du contenu.

Les numéros de version des logiciels et les messages d'erreur détaillés (tels que les numéros de version ASP.NET) sont des exemples de configurations de serveur incorrectes. Ces informations sont utiles à un attaquant car elles lui fournissent des renseignements détaillés sur le framework, les langages ou les fonctions préconstruites utilisés par une application web. La plupart des configurations de serveur par défaut fournissent des numéros de version des logiciels et des messages d'erreur détaillés à des fins de débogage et de dépannage. Des modifications de configuration peuvent être effectuées pour désactiver ces fonctionnalités, empêchant ainsi l'affichage de ces informations.

## Liens {#links}

- [OWASP](https://owasp.org/Top10/A05_2021-Security_Misconfiguration/)
- [CWE](https://cwe.mitre.org/data/definitions/200.html)
