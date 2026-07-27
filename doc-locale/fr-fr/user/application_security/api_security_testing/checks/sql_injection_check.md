---
stage: Application Security Testing
group: Dynamic Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Injection SQL
---

## Description {#description}

Vérifiez les vulnérabilités d'injection SQL et NoSQL. Une attaque par injection SQL consiste à insérer ou à « injecter » une requête SQL via les données d'entrée envoyées par le client à l'application. Un exploit d'injection SQL réussi peut lire des données sensibles dans la base de données, modifier des données de la base de données (Insert/Update/Delete), exécuter des opérations d'administration sur la base de données (telles que l'arrêt du SGBD), récupérer le contenu d'un fichier donné présent sur le système de fichiers du SGBD et, dans certains cas, émettre des commandes vers le système d'exploitation. Les attaques par injection SQL sont un type d'attaque par injection dans lequel des commandes SQL sont injectées dans une entrée du plan de données afin d'affecter l'exécution de commandes SQL prédéfinies. Cette vérification modifie les paramètres de la requête (chemin, chaîne de requête, en-têtes, JSON, XML, etc.) pour tenter de créer une erreur de syntaxe dans la requête SQL ou NoSQL. Les journaux et les réponses sont ensuite analysés pour tenter de détecter si une erreur s'est produite. Si une erreur est détectée, il est fort probable qu'une vulnérabilité existe.

## Remédiation {#remediation}

Le logiciel construit tout ou partie d'une commande SQL en utilisant des entrées influencées par des sources externes provenant d'un composant en amont, mais il ne neutralise pas ou neutralise incorrectement les éléments spéciaux qui pourraient modifier la commande SQL prévue lorsqu'elle est envoyée à un composant en aval.

Sans suppression ou mise entre guillemets suffisante de la syntaxe SQL dans les entrées contrôlables par l'utilisateur, la requête SQL générée peut amener ces entrées à être interprétées comme du SQL au lieu de données utilisateur ordinaires. Cela peut être utilisé pour modifier la logique des requêtes afin de contourner les contrôles de sécurité, ou pour insérer des instructions supplémentaires qui modifient la base de données back-end, y compris éventuellement l'exécution de commandes système.

L'injection SQL est devenue un problème courant pour les sites web pilotés par base de données. La faille est facilement détectable et facilement exploitable, et à ce titre, tout site ou logiciel disposant d'une base d'utilisateurs même minimale est susceptible de faire l'objet d'une tentative d'attaque de ce type. Cette faille repose sur le fait que SQL ne fait pas de réelle distinction entre les plans de contrôle et de données.

## Liens {#links}

- [OWASP](https://owasp.org/Top10/A03_2021-Injection/)
- [CWE](https://cwe.mitre.org/data/definitions/930.html)
