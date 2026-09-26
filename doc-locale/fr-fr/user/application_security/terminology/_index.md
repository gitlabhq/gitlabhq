---
stage: Application Security Testing
group: Static Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Glossaire de sécurité
description: Définitions des termes relatifs aux fonctionnalités de sécurité dans GitLab.
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Ce glossaire fournit des définitions pour les termes relatifs aux fonctionnalités de sécurité dans GitLab. Bien que certains termes puissent avoir des significations différentes ailleurs, ces définitions sont spécifiques à GitLab.

## Analyseur {#analyzer}

Logiciel qui analyse un [type de cible de scan](#scan-target-type) à la recherche de vulnérabilités de sécurité. En interne, il est responsable de la collecte des paramètres de configuration requis et de l'exécution des transformations de données nécessaires pour convertir la cible dans un format standardisé afin que le [scanner](#scanner) puisse exécuter l'opération de scan. Enfin, il produit un rapport dans le format requis par l'appelant.

Les analyseurs basés sur CI/CD s'intègrent dans GitLab à l'aide d'un job CI/CD. Le rapport produit par l'analyseur basé sur CI/CD est publié en tant qu'artefact une fois le job terminé. GitLab ingère ce rapport, permettant aux utilisateurs de visualiser et de gérer les vulnérabilités détectées. Les rapports générés respectent le [format de rapport sécurisé](#secure-report-format).

De nombreux analyseurs GitLab suivent une approche standard utilisant Docker pour exécuter un scanner encapsulé. Par exemple, l'image `semgrep` est un analyseur qui encapsule le scanner `Semgrep`. Cependant, certains analyseurs s'exécutent directement dans GitLab Rails ou d'autres environnements cibles plutôt que dans des conteneurs séparés.

## Surface d'attaque {#attack-surface}

Les différents endroits d'une application qui sont vulnérables à une attaque. Les produits de sécurité découvrent et explorent la surface d'attaque lors des scans. Chaque produit définit la surface d'attaque différemment. Par exemple, SAST utilise des fichiers et des numéros de ligne, et DAST utilise des URL.

## Composant {#component}

Un composant logiciel qui constitue une partie d'un projet logiciel. Les exemples incluent les bibliothèques, les pilotes, les données, et [bien d'autres](https://cyclonedx.org/docs/1.5/json/#components_items_type).

## Corpus {#corpus}

L'ensemble des cas de test significatifs générés pendant l'exécution du fuzzer. Chaque cas de test significatif produit une nouvelle couverture dans le programme testé. Vous devriez réutiliser le corpus et le transmettre aux exécutions suivantes.

## CNA {#cna}

Les autorités de numérotation [CVE](#cve) (CNA) sont des organisations du monde entier autorisées par la [Mitre Corporation](https://cve.mitre.org/) à attribuer des [CVE](#cve) aux vulnérabilités dans des produits ou services relevant de leur portée respective. [GitLab est une CNA](https://about.gitlab.com/security/cve/).

## CVE {#cve}

Les vulnérabilités et expositions communes (CVE®) constituent une liste d'identifiants communs pour les vulnérabilités de cybersécurité connues du public. La liste est gérée par la [Mitre Corporation](https://cve.mitre.org/).

## CVSS {#cvss}

Le système de notation des vulnérabilités communes (CVSS) est un standard industriel gratuit et ouvert pour évaluer la gravité des vulnérabilités de sécurité des systèmes informatiques.

## CWE {#cwe}

L'énumération des faiblesses communes (CWE™) est une liste développée par la communauté des types de faiblesses courantes dans les logiciels et le matériel qui ont des répercussions sur la sécurité. Les faiblesses sont des défauts, des erreurs, des bugs, des vulnérabilités ou d'autres erreurs dans l'implémentation logicielle ou matérielle, le code, la conception ou l'architecture. Si elles ne sont pas traitées, les faiblesses pourraient rendre les systèmes, les réseaux ou le matériel vulnérables aux attaques. La liste CWE et la taxonomie de classification associée servent de langage que vous pouvez utiliser pour identifier et décrire ces faiblesses en termes de CWE.

## Déduplication {#deduplication}

Lorsque le processus d'une catégorie considère que des résultats sont identiques, ou s'ils sont suffisamment similaires pour nécessiter une réduction du bruit, un seul résultat est conservé et les autres sont éliminés. En savoir plus sur le [processus de déduplication](../detect/vulnerability_deduplication.md).

## Export de graphe de dépendances {#dependency-graph-export}

Un export de graphe de dépendances liste les dépendances directes et indirectes utilisées par un projet ainsi que les relations entre elles. Il est généré par une commande du gestionnaire de paquets (par exemple, `go mod graph` ou `mvn dependency:tree`) et produit sous forme de fichier.

Terme associé : [lockfile](#lockfile).

## Conflit de versions de dépendances {#dependency-version-conflict}

Un conflit de versions de dépendances survient lorsque les contraintes de version des dépendances ne peuvent pas être satisfaites.

Considérez ce qui suit :

- La dépendance X requiert `packageA` à la version exacte 1.0.0
- La dépendance Y requiert `packageA` en version 1.0.1 ou supérieure

Dans cet exemple, aucune version de `packageA` ne peut satisfaire les deux contraintes, ce qui entraîne un conflit de versions de dépendances.

## Incompatibilité de versions de dépendances {#dependency-version-incompatibility}

Une incompatibilité de versions de dépendances survient lorsque la version d'un paquet ne satisfait pas une contrainte de version.

Considérez ce qui suit :

- `packageA` possède les versions `1.0.0` et `1.0.1`
- La dépendance X requiert `packageA` en version 1.0.1 ou supérieure

Dans cet exemple, `packageA` version `1.0.0` ne satisfait pas la contrainte de version et est donc incompatible. Cependant, `packageA` version `1.0.1` satisfait la contrainte.

## Résultat dupliqué {#duplicate-finding}

Un résultat légitime qui est signalé plusieurs fois. Cela peut se produire lorsque différents scanners découvrent le même résultat, ou lorsqu'un seul scan signale par inadvertance le même résultat plus d'une fois.

## Faux positif {#false-positive}

Un résultat qui n'existe pas mais qui est signalé à tort comme existant.

## Résultat {#finding}

Un actif qui a le potentiel d'être vulnérable, identifié dans un projet par un analyseur. Les actifs incluent, sans s'y limiter, le code source, les paquets binaires, les conteneurs, les dépendances, les réseaux, les applications et l'infrastructure.

Les résultats sont tous les éléments de vulnérabilité potentiels que les scanners identifient dans les MR/branches de fonctionnalités. Ce n'est qu'après la fusion vers la branche par défaut qu'un résultat devient une [vulnérabilité](#vulnerability).

Vous pouvez interagir avec les résultats de vulnérabilité de deux manières.

1. Vous pouvez ouvrir un ticket ou une merge request pour le résultat de vulnérabilité.
1. Vous pouvez ignorer le résultat de vulnérabilité. Ignorer le résultat le masque des vues par défaut.

## Regroupement {#grouping}

Une manière flexible et non destructive d'organiser visuellement les vulnérabilités en groupes lorsqu'il existe plusieurs résultats probablement liés mais ne remplissant pas les conditions de déduplication. Par exemple, vous pouvez inclure des résultats qui doivent être évalués ensemble, qui seraient corrigés par la même action, ou qui proviennent de la même source.

## Identifiant {#identifier}

Un identifiant est un ID pour la vulnérabilité provenant d'une base de données externe, telle que Common Vulnerabilities and Exposures (CVE) ou Common Weakness Enumeration (CWE). Une vulnérabilité peut avoir plusieurs identifiants. Un identifiant est composé d'un type (comme `CVE`) et d'un ID (comme `CVE-2021-44228`).

## Résultat insignifiant {#insignificant-finding}

Un résultat légitime qui n'intéresse pas un client particulier.

## Composant affecté connu {#known-affected-component}

Un composant qui correspond aux exigences permettant à une vulnérabilité d'être exploitable. Par exemple, `packageA@1.0.3` correspond au nom, au type de paquet et à l'une des versions affectées ou plages de versions de `FAKECVE-2023-0001`.

## Empreinte de localisation {#location-fingerprint}

L'empreinte de localisation d'un résultat est une valeur textuelle unique pour chaque emplacement sur la surface d'attaque. Chaque produit de sécurité la définit en fonction de son type de surface d'attaque. Par exemple, SAST intègre le chemin du fichier et le numéro de ligne.

## Lockfile {#lockfile}

Un fichier qui liste les dépendances directes et indirectes d'une application ainsi que leurs numéros de version. Son objectif est la reproductibilité, afin de garantir que toute personne installant les dépendances de l'application obtienne exactement les mêmes versions. Certains fichiers de verrouillage, comme `Gemfile.lock`, incluent également des informations sur les relations entre les dépendances, mais cela n'est pas obligatoire.

Terme associé : [export de graphe de dépendances](#dependency-graph-export).

## Gestionnaires de paquets et types de paquets {#package-managers-and-package-types}

### Gestionnaires de paquets {#package-managers}

Un gestionnaire de paquets est un système qui gère les dépendances de votre projet.

Le gestionnaire de paquets fournit une méthode pour installer de nouvelles dépendances (également appelées « paquets »), gérer l'emplacement de stockage des paquets sur votre système de fichiers et offrir des fonctionnalités pour publier vos propres paquets.

### Types de paquets {#package-types}

Chaque gestionnaire de paquets, plateforme, type ou écosystème possède ses propres conventions et protocoles pour identifier, localiser et fournir des paquets logiciels.

Le tableau suivant est une liste non exhaustive de certains des gestionnaires de paquets et types référencés dans la documentation GitLab et les outils logiciels.

<style>
table.package-managers-and-types tr:nth-child(even) {
    background-color: transparent;
}

table.package-managers-and-types td {
    border-left: 1px solid #dbdbdb;
    border-right: 1px solid #dbdbdb;
    border-bottom: 1px solid #dbdbdb;
}

table.package-managers-and-types tr td:first-child {
    border-left: 0;
}

table.package-managers-and-types tr td:last-child {
    border-right: 0;
}

table.package-managers-and-types ul {
    font-size: 1em;
    list-style-type: none;
    padding-left: 0px;
    margin-bottom: 0px;
}
</style>

<table class="package-managers-and-types">
  <thead>
    <tr>
      <th>Type de paquet</th>
      <th>Gestionnaire de paquets</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td>gem</td>
      <td><a href="https://bundler.io/">Bundler</a></td>
    </tr>
    <tr>
      <td>Packagist</td>
      <td><a href="https://getcomposer.org/">Composer</a></td>
    </tr>
    <tr>
      <td>Conan</td>
      <td><a href="https://conan.io/">Conan</a></td>
    </tr>
    <tr>
      <td>go</td>
      <td><a href="https://go.dev/blog/using-go-modules">go</a></td>
    </tr>
    <tr>
      <td rowspan="3">maven</td>
      <td><a href="https://gradle.org/">Gradle</a></td>
    </tr>
    <tr>
      <td><a href="https://maven.apache.org/">Maven</a></td>
    </tr>
    <tr>
      <td><a href="https://www.scala-sbt.org">sbt</a></td>
    </tr>
    <tr>
      <td rowspan="2">npm</td>
      <td><a href="https://www.npmjs.com">npm</a></td>
    </tr>
    <tr>
      <td><a href="https://classic.yarnpkg.com/en">yarn</a></td>
    </tr>
    <tr>
      <td>NuGet</td>
      <td><a href="https://www.nuget.org/">NuGet</a></td>
    </tr>
    <tr>
      <td rowspan="4">PyPI</td>
      <td><a href="https://setuptools.pypa.io/en/latest/">Setuptools</a></td>
    </tr>
    <tr>
      <td><a href="https://pip.pypa.io/en/stable/">pip</a></td>
    </tr>
    <tr>
      <td><a href="https://pipenv.pypa.io/en/latest/">Pipenv</a></td>
    </tr>
    <tr>
      <td><a href="https://python-poetry.org/">Poetry</a></td>
    </tr>
  </tbody>
</table>

## Onglet Sécurité du pipeline {#pipeline-security-tab}

Une page qui affiche les résultats découverts dans le pipeline CI associé.

## Composant potentiellement affecté {#possibly-affected-component}

Un composant logiciel potentiellement affecté par une vulnérabilité. Par exemple, lors du scan d'un projet à la recherche de vulnérabilités connues, les composants sont d'abord évalués pour voir s'ils correspondent au nom et au [type de paquet](https://github.com/package-url/purl-spec/blob/main/PURL-TYPES.rst). Durant cette étape, ils sont potentiellement affectés par la vulnérabilité, et ne sont [connus comme affectés](#known-affected-component) qu'après confirmation qu'ils se situent dans la plage de versions affectées.

## Post-filtre {#post-filter}

Les post-filtres aident à réduire le bruit dans les résultats du scanner et à automatiser les tâches manuelles. Vous pouvez spécifier des critères qui mettent à jour ou modifient les données de vulnérabilité en fonction des résultats du scanner. Par exemple, vous pouvez signaler des résultats comme étant probablement des faux positifs et résoudre automatiquement les vulnérabilités qui ne sont plus détectées. Ces actions ne sont pas permanentes et peuvent être modifiées.

La prise en charge de la résolution automatique des résultats est suivie dans l'[epic 7478](https://gitlab.com/groups/gitlab-org/-/epics/7478) et la prise en charge du scan économique est proposée dans l'[epic 7886](https://gitlab.com/groups/gitlab-org/-/epics/7886).

## Pré-filtre {#pre-filter}

Une action irréversible qui consiste à filtrer les cibles avant que l'analyse ne se produise. Cette option est généralement fournie pour permettre à l'utilisateur de réduire la portée et le bruit et d'accélérer l'analyse. Cette opération ne doit pas être effectuée si un enregistrement est nécessaire, car GitLab ne stocke rien concernant le code ou les actifs ignorés/exclus.

Exemples : `DS_EXCLUDED_PATHS` doit `Exclude files and directories from the scan based on the paths provided.`

## Identifiant principal {#primary-identifier}

Le premier [identifiant](#identifier) est l'identifiant principal. L'identifiant principal doit être stable. Les scans suivants doivent retourner la même valeur pour le même résultat, même si l'emplacement de la vulnérabilité a changé.

## Processeur {#processor}

Logiciel qui accepte une entrée et la transforme selon des critères spécifiés, soit en modifiant les données d'entrée, soit en attachant des métadonnées supplémentaires en sortie. Les processeurs existent pour prendre en charge les opérations des scanners et sont couramment utilisés dans les phases de pré-scan et de post-scan. Contrairement aux [filtres](#pre-filter), les processeurs n'ont pas de capacités de prise de décision pour contrôler la poursuite ou l'arrêt du workflow en fonction de la logique métier. Au lieu de cela, ils effectuent des transformations et transmettent les résultats inconditionnellement.

### Pré-processeur {#pre-processor}

Les pré-processeurs effectuent généralement des tâches de préparation des données telles que la normalisation des formats d'entrée, l'enrichissement des cibles de scan avec du contexte supplémentaire, l'application de transformations spécifiques aux cibles ou l'augmentation des paramètres de configuration. Ils s'assurent que le scanner reçoit des entrées correctement formatées et améliorées, optimisées pour l'opération de scan.

### Post-processeur {#post-processor}

Les post-processeurs appliquent une analyse intelligente aux résultats de scan après que le [scanner](#scanner) a terminé son opération. Les post-processeurs améliorent la sortie brute du scanner via des opérations telles que la classification des vulnérabilités, le filtrage des faux positifs, l'ajustement de la gravité et l'enrichissement contextuel. Les résultats du scanner peuvent traverser plusieurs post-processeurs en séquence avant que les résultats traités ne soient renvoyés à l'[analyseur](#analyzer).

## Accessibilité {#reachability}

L'accessibilité indique si un [composant](#component) répertorié comme dépendance dans un projet est réellement utilisé dans la base de code.

## Résultat de rapport {#report-finding}

Un [résultat](#finding) qui n'existe que dans un rapport produit par un analyseur et qui n'a pas encore été persisté dans la base de données. Le résultat de rapport devient un [résultat de vulnérabilité](#vulnerability-finding) après son importation dans la base de données.

## Type de scan (type de rapport) {#scan-type-report-type}

Décrit le type de scan. Cela doit être l'un des éléments suivants :

- `api_fuzzing`
- `container_scanning`
- `coverage_fuzzing`
- `dast`
- `dependency_scanning`
- `sast`
- `secret_detection`

Cette liste est susceptible d'évoluer à mesure que des scanners sont ajoutés.

## Type de cible de scan {#scan-target-type}

Une unité discrète de contenu ou d'artefact qui sert de limite de portée pour l'exécution du scan. Chaque type de cible de scan représente une entité autonome avec des contraintes de scan définies. Une instance spécifique d'un type de cible de scan (comme un dépôt Git particulier ou une image de conteneur) est appelée « cible de scan ». Les exemples de types de cibles de scan incluent les dépôts Git, les systèmes de fichiers, les conteneurs, etc.

## Scanner {#scanner}

Logiciel qui recherche des vulnérabilités de sécurité dans une cible de scan (une instance d'un [type de cible de scan](#scan-target-type)). Il s'agit généralement d'un composant sans état qui reçoit les paramètres de configuration de scan nécessaires et les charges utiles de scan de l'analyseur. Le rapport de scan résultant n'est pas nécessairement au [format de rapport sécurisé](#secure-report-format). Un scanner peut être un composant sophistiqué qui encapsule un ou plusieurs moteurs de scan avec des processeurs supplémentaires (par exemple, le scanner de détection des secrets), ou il peut être aussi simple qu'un moteur de scan autonome (par exemple, Trivy).

## Produit de sécurité {#secure-product}

Un ensemble de fonctionnalités liées à un domaine spécifique de la sécurité des applications avec un support de premier ordre par GitLab.

Les produits incluent le scan de conteneurs, l'analyse des dépendances, le test dynamique de sécurité des applications (DAST), la détection des secrets, le test statique de sécurité des applications (SAST) et les tests de fuzzing.

Chacun de ces produits inclut généralement un ou plusieurs analyseurs.

## Format de rapport sécurisé {#secure-report-format}

Un format de rapport standard auquel les produits de sécurité se conforment lors de la création de rapports JSON. Le format est décrit par un [schéma JSON](https://gitlab.com/gitlab-org/security-products/security-report-schemas).

## Tableau de bord de sécurité {#security-dashboard}

Fournit une vue d'ensemble de toutes les vulnérabilités pour un projet, un groupe ou une instance GitLab. Les vulnérabilités ne sont créées qu'à partir des résultats découverts sur la branche par défaut du projet.

## Corpus d'amorçage {#seed-corpus}

L'ensemble des cas de test fournis comme entrée initiale à la cible de fuzzing. Cela accélère généralement considérablement la cible de fuzzing. Il peut s'agir de cas de test créés manuellement ou générés automatiquement avec la cible de fuzzing elle-même à partir d'exécutions précédentes.

## Fournisseur {#vendor}

La partie qui maintient un analyseur. À ce titre, un fournisseur est responsable de l'intégration d'un scanner dans GitLab et de sa compatibilité au fil de son évolution. Un fournisseur n'est pas nécessairement l'auteur ou le mainteneur du scanner, comme dans le cas de l'utilisation d'un projet open core ou OSS comme solution de base d'une offre. Pour les scanners inclus dans une distribution GitLab ou un abonnement GitLab, le fournisseur est répertorié comme GitLab.

## Vulnérabilité {#vulnerability}

Un défaut qui a un impact négatif sur la sécurité de son environnement. Les vulnérabilités décrivent l'erreur ou la faiblesse, et ne décrivent pas l'emplacement de l'erreur (voir [résultat](#finding)).

Chaque vulnérabilité correspond à un résultat unique.

Les vulnérabilités existent dans la branche par défaut. Les résultats (voir [résultat](#finding)) sont tous les éléments de vulnérabilité potentiels que les scanners identifient dans les MR/branches de fonctionnalités. Ce n'est qu'après la fusion vers la branche par défaut qu'un résultat devient une vulnérabilité.

## Résultat de vulnérabilité {#vulnerability-finding}

Lorsqu'un [résultat de rapport](#report-finding) est stocké dans la base de données, il devient un [résultat](#finding) de vulnérabilité.

## Suivi des vulnérabilités {#vulnerability-tracking}

Prend en charge la responsabilité de faire correspondre les résultats entre les scans afin que le cycle de vie d'un résultat puisse être compris. Les équipes d'ingénierie et de sécurité utilisent ces informations pour décider de fusionner ou non les modifications de code, et pour voir les résultats non résolus et le moment où ils ont été introduits.

Les vulnérabilités sont suivies en comparant l'empreinte de localisation, l'identifiant principal et le type de rapport.

## Occurrence de vulnérabilité {#vulnerability-occurrence}

Déprécié, voir [résultat](#finding).
