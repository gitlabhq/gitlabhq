---
stage: Application Security Testing
group: Dynamic Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Injection de commande OS
---

## Description {#description}

Recherche de vulnérabilités d'injection de commande OS. Une attaque par injection de commande OS consiste à insérer ou « injecter » une commande OS via les données d'entrée du client vers l'application. Un exploit d'injection de commande OS réussi peut exécuter des commandes arbitraires. Cela permet à un attaquant de lire, d'écrire et de supprimer des données. Selon l'utilisateur sous lequel les commandes s'exécutent, cela peut également inclure des fonctions administratives.

Cette vérification modifie les paramètres de la requête (chemin, chaîne de requête, en-têtes, JSON, XML, etc.) pour tenter d'exécuter une commande OS. Des injections standard et des injections aveugles sont effectuées. Les injections aveugles provoquent des délais dans la réponse lorsqu'elles réussissent.

## Remédiation {#remediation}

Il est possible d'exécuter des commandes OS arbitraires sur le serveur d'application cible. L'injection de commande OS est une vulnérabilité critique qui peut conduire à une compromission totale du système. Les entrées utilisateur ne doivent jamais être utilisées dans la construction de commandes ou d'arguments de commande pour des fonctions qui exécutent des commandes OS. Cela inclut les noms de fichiers fournis par les téléchargements ou les téléversements des utilisateurs.

Assurez-vous que votre application ne fait pas ce qui suit :

- Utiliser des informations fournies par l'utilisateur dans le nom du processus à exécuter.
- Utiliser des informations fournies par l'utilisateur dans une fonction d'exécution de commande OS qui n'échappe pas les métacaractères du shell.
- Utiliser des informations fournies par l'utilisateur dans les arguments des commandes OS.

L'application doit disposer d'un ensemble d'arguments codés en dur à transmettre aux commandes OS. Si des noms de fichiers sont transmis à ces fonctions, il est recommandé d'utiliser à la place un hachage du nom de fichier ou un autre identifiant unique. Il est fortement recommandé d'utiliser une bibliothèque native qui implémente la même fonctionnalité plutôt que des commandes système OS, en raison du risque d'attaques inconnues visant des commandes tierces.

## Liens {#links}

- [OWASP](https://owasp.org/Top10/A03_2021-Injection/)
- [CWE](https://cwe.mitre.org/data/definitions/78.html)
