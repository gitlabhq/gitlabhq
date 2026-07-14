---
stage: GitLab Delivery
group: Build
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Licences des packages
---

{{< details >}}

- Niveau : Free, Premium, Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

## Licence {#license}

Bien que GitLab lui-même soit sous licence MIT, les sources du package Linux sont sous licence Apache-2.0.

## Emplacement du fichier de licence {#license-file-location}

À partir de la version 8.11, le package Linux contient les informations de licence de tous les logiciels inclus dans le package.

Après l'installation du package, les licences de chaque bibliothèque incluse individuellement se trouvent dans le répertoire `/opt/gitlab/LICENSES`.

Il existe également un fichier `LICENSE` qui contient toutes les licences compilées ensemble. Cette licence compilée se trouve dans le fichier `/opt/gitlab/LICENSE`.

À partir de la version 9.2, le package Linux est livré avec un fichier `dependency_licenses.json` contenant les informations de version et de licence de tous les logiciels inclus, notamment les bibliothèques logicielles, les gemmes Ruby utilisées par l'application Rails et les bibliothèques JavaScript requises pour les composants frontend. Étant donné qu'il est au format JSON, GitLab peut analyser ce fichier et l'utiliser pour des vérifications ou validations automatisées. Le fichier se trouve à l'emplacement `/opt/gitlab/dependency_licenses.json`.

À partir de la version 11.3, nous avons également mis les informations de licence à disposition en ligne, à l'adresse : <https://gitlab-org.gitlab.io/omnibus-gitlab/licenses.html>

## Vérification des licences {#checking-licenses}

Le package Linux est composé de nombreux éléments logiciels, comprenant du code couvert par de nombreuses licences différentes. Ces licences sont fournies et compilées comme indiqué précédemment.

À partir de la version 8.13, GitLab a ajouté une étape supplémentaire lors de l'installation du package Linux. L'étape `license_check` appelle `lib/gitlab/tasks/license_check.rake`, qui vérifie le fichier `LICENSE` compilé par rapport à la liste actuelle des licences approuvées et douteuses, telles que définies dans les tableaux en haut du script. Ce script génère l'une des valeurs `Good`, `Unknown` ou `Check` pour chaque élément logiciel faisant partie du package Linux.

- `Good` : désigne une licence approuvée pour tous les types d'utilisation, dans GitLab et dans le package Linux.
- `Unknown` : désigne une licence qui n'est pas reconnue dans la liste des licences « bonnes » ou « mauvaises » et qui doit être immédiatement examinée pour en évaluer les implications d'utilisation.
- `Check` : désigne une licence qui pourrait être incompatible avec GitLab lui-même, et qui doit donc être vérifiée quant à la façon dont elle est utilisée dans le cadre du package Linux pour garantir la conformité.

Cette liste est issue de la documentation de développement GitLab sur les licences. Cependant, en raison de la nature du package Linux, les licences peuvent ne pas s'appliquer de la même manière. C'est notamment le cas avec `git` et `rsync`. Consultez la [FAQ sur les licences GNU](https://www.gnu.org/licenses/gpl-faq.en.html#MereAggregation)

## Mentions de licences {#license-acknowledgments}

### libjpeg-turbo - Licence BSD 3 clauses {#libjpeg-turbo---bsd-3-clause-license}

Ce logiciel est basé en partie sur le travail de l'Independent JPEG Group.

## Utilisation des marques commerciales {#trademark-usage}

Dans la documentation GitLab, des références à des technologies tierces et/ou à des marques commerciales d'entités tierces peuvent être faites. L'inclusion de références à des technologies et/ou entités tierces a pour seul but d'illustrer comment le logiciel GitLab peut interagir avec ces technologies tierces ou être utilisé conjointement avec elles. Toutes les marques commerciales, les matériaux, la documentation et toute autre propriété intellectuelle restent la propriété de ces tiers.

### Exigences relatives aux marques commerciales {#trademark-requirements}

L'utilisation des marques commerciales GitLab doit être conforme aux normes définies dans nos directives (telles que mises à jour de temps à autre). CHEF® et toutes les marques Chef appartiennent à Progress Software Corporation et doivent être utilisées conformément à la [Progress Software Trademark Usage Policy](https://www.progress.com/legal/trademarks).

Lorsque vous utilisez une marque commerciale GitLab ou tierce dans la documentation, incluez le symbole (R) à la première occurrence, par exemple « Chef(R) est utilisé pour configurer... ». Vous pouvez omettre le symbole dans les occurrences suivantes.

Si un propriétaire de marque commerciale exige un avis ou une exigence particulière concernant la marque, cet avis ou cette exigence doit être indiqué ci-dessus.
