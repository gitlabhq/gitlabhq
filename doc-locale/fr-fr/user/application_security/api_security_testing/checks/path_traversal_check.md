---
stage: Application Security Testing
group: Dynamic Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Traversée de chemin
---

## Description {#description}

De nombreuses opérations sur les fichiers sont destinées à s'effectuer dans un répertoire restreint. En utilisant des éléments spéciaux tels que les séparateurs `..` et `/`, les attaquants peuvent s'échapper en dehors de l'emplacement restreint pour accéder à des fichiers ou des répertoires situés ailleurs sur le système. L'un des éléments spéciaux les plus courants est la séquence `../`, qui dans la plupart des systèmes d'exploitation modernes est interprétée comme le répertoire parent de l'emplacement actuel. Cela est désigné sous le terme de traversée de chemin relative. La traversée de chemin couvre également l'utilisation de noms de chemins absolus tels que `/usr/local/bin`, qui peuvent également être utiles pour accéder à des fichiers inattendus. Cela est désigné sous le terme de traversée de chemin absolue.

Dans de nombreux langages de programmation, l'injection d'un octet nul (le `0` ou `NULL` ) peut permettre à un attaquant de tronquer un nom de fichier généré afin d'élargir la portée de l'attaque. Par exemple, le logiciel peut ajouter `.txt` à tout chemin d'accès, limitant ainsi l'attaquant aux fichiers texte, mais une injection nulle peut effectivement supprimer cette restriction.

Cette vérification modifie les paramètres de la requête (chemin, chaîne de requête, en-têtes, JSON, XML, etc.) afin de tenter d'accéder à des fichiers restreints et à des fichiers situés en dehors de la racine web. Les journaux et les réponses sont ensuite analysés pour tenter de détecter si le fichier a été accédé avec succès.

## Remédiation {#remediation}

La technique d'attaque par traversée de chemin permet à un attaquant d'accéder à des fichiers, des répertoires et des commandes qui résident potentiellement en dehors du répertoire racine du document web. Un attaquant peut manipuler une URL de telle sorte que le site web exécute ou révèle le contenu de fichiers arbitraires n'importe où sur le serveur web. Tout appareil exposant une interface HTTP est potentiellement vulnérable à la traversée de chemin.

La plupart des sites web restreignent l'accès des utilisateurs à une portion spécifique du système de fichiers, généralement appelée répertoire « web document root » ou « CGI root ». Ces répertoires contiennent les fichiers destinés à l'accès des utilisateurs ainsi que les exécutables nécessaires au fonctionnement des applications web. Pour accéder à des fichiers ou exécuter des commandes n'importe où sur le système de fichiers, les attaques par traversée de chemin exploitent la capacité des séquences de caractères spéciaux.

L'attaque par traversée de chemin la plus basique utilise la séquence de caractères spéciaux `../` pour modifier l'emplacement de la ressource demandée dans l'URL. Bien que la plupart des serveurs web populaires empêchent cette technique d'échapper à la racine du document web, d'autres encodages de la séquence `../` peuvent aider à contourner les filtres de sécurité. Ces variantes de méthode incluent l'encodage Unicode valide et invalide (`..%u2216` ou `..%c0%af`) du caractère barre oblique, les caractères barre oblique inverse (`..`) sur les serveurs Windows, les caractères encodés en URL (`%2e%2e%2f`), et le double encodage URL (`..%255c`) du caractère barre oblique inverse.

Même si le serveur web restreint correctement les tentatives de traversée de chemin dans le chemin de l'URL, une application web elle-même peut rester vulnérable en raison d'une gestion incorrecte des entrées fournies par l'utilisateur. Il s'agit d'un problème courant des applications web qui utilisent des mécanismes de gabarits ou chargent du texte statique depuis des fichiers. Dans des variantes de l'attaque, la valeur du paramètre d'URL d'origine est remplacée par le nom de fichier d'un des scripts dynamiques de l'application web. Par conséquent, les résultats peuvent révéler le code source car le fichier est interprété comme du texte plutôt que comme un script exécutable. Ces techniques emploient souvent des caractères spéciaux supplémentaires tels que le point (`.`) pour révéler la liste du répertoire de travail actuel, ou des caractères NULL `%00` afin de contourner les vérifications rudimentaires d'extension de fichier.

## Liens {#links}

- [OWASP](https://owasp.org/Top10/A01_2021-Broken_Access_Control/)
- [CWE](https://cwe.mitre.org/data/definitions/22.html)
