---
stage: Security Risk Management
group: Security Insights
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Liste des dépendances
description: "Vulnérabilités, licences, filtrage et exportation."
---

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Utilisez la liste des dépendances pour examiner les dépendances de votre projet ou groupe, ainsi que les informations clés les concernant, y compris leurs vulnérabilités connues. Cette liste regroupe les dépendances de votre projet, y compris les résultats existants et nouveaux. Ces informations sont parfois désignées sous le nom de Software Bill of Materials, SBOM ou BOM.

<i class="fa-youtube-play" aria-hidden="true"></i> Pour une présentation générale, consultez [Project Dependency - Advanced Security Testing](https://www.youtube.com/watch?v=ckqkn9Tnbw4).

## Configurer la liste des dépendances {#set-up-the-dependency-list}

Pour lister les dépendances de votre projet, exécutez l'[analyse des dépendances](../dependency_scanning/_index.md) ou le [container scanning](../container_scanning/_index.md) sur la branche par défaut de votre projet.

La liste des dépendances affiche également les dépendances provenant de tous les [rapports CycloneDX](../../../ci/yaml/artifacts_reports.md#artifactsreportscyclonedx) téléversés depuis le dernier pipeline de la branche par défaut. Les rapports CycloneDX doivent être conformes à [la spécification CycloneDX](https://github.com/CycloneDX/specification) version `1.4`, `1.5` ou `1.6`. Vous pouvez utiliser le [CycloneDX Web Tool](https://cyclonedx.github.io/cyclonedx-web-tool/validate) pour valider les rapports CycloneDX.

> [!note]
> Bien que cela ne soit pas obligatoire pour alimenter la liste des dépendances, le document SBOM doit inclure et respecter la taxonomie des propriétés CycloneDX de GitLab afin de fournir certaines propriétés et d'activer certaines fonctionnalités de sécurité.

## Afficher les dépendances d'un projet {#view-project-dependencies}

{{< history >}}

- Dans GitLab 17.2, le champ `location` ne renvoie plus vers le commit où la dépendance a été détectée pour la dernière fois lorsque le feature flag `skip_sbom_occurrences_update_on_pipeline_id_change` est activé. Le flag est désactivé par défaut.
- Dans GitLab 17.3, le champ `location` renvoie toujours vers le commit où la dépendance a été détectée pour la première fois. Suppression du feature flag `skip_sbom_occurrences_update_on_pipeline_id_change`.
- L'option Afficher les chemins de dépendance [introduite](https://gitlab.com/gitlab-org/gitlab/-/issues/519965) dans GitLab 17.11 [avec un feature flag](../../../administration/feature_flags/_index.md) nommé `dependency_paths`. Désactivées par défaut.
- [Passage en disponibilité générale](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/197224) de l'option Afficher les chemins de dépendance dans GitLab 18.2. Suppression du feature flag `dependency_paths`.

{{< /history >}}

Prérequis :

- Le rôle Développeur, Mainteneur ou Propriétaire pour le projet ou le groupe

Pour afficher les dépendances d'un projet ou de tous les projets d'un groupe :

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à** et repérez votre projet ou groupe.
1. Dans la barre latérale gauche, sélectionnez **Sécuriser** > **Liste des dépendances**.
1. Facultatif. S'il existe des dépendances transitives, vous pouvez également afficher l'ensemble des chemins de dépendance :
   - Pour un projet, dans la colonne **Emplacement**, sélectionnez **Afficher les chemins de dépendance**.
   - Pour un groupe, dans la colonne **Emplacement**, sélectionnez l'emplacement, puis sélectionnez **Afficher les chemins de dépendance**.

Les détails de chaque dépendance sont répertoriés, triés par gravité décroissante des vulnérabilités (le cas échéant). Vous pouvez également trier la liste par nom de composant, gestionnaire de paquets ou licence.

| Champ                       | Description |
|-----------------------------|-------------|
| Composant                   | Le nom et la version de la dépendance. |
| Gestionnaire de paquets                    | Le gestionnaire de paquets utilisé pour installer la dépendance. S'affiche comme « unknown » pour les gestionnaires de paquets non pris en charge. |
| Emplacement                    | Pour les dépendances système, ce champ répertorie l'image qui a été analysée. Pour les dépendances applicatives, ce champ affiche un lien vers le fichier de verrouillage spécifique au gestionnaire de paquets dans votre projet, qui a déclaré la dépendance. Il affiche également les [dépendants](#dependency-paths) directs, le cas échéant. S'il existe des dépendances transitives, sélectionner **Afficher les chemins de dépendance** affiche le chemin complet de tous les dépendants. Les dépendances transitives sont des dépendants indirects qui ont un dépendant direct comme ancêtre. |
| Licence (pour les projets uniquement) | Liens vers les licences logicielles de la dépendance. Un badge d'avertissement indiquant le nombre de vulnérabilités détectées dans la dépendance. |
| Projets (pour les groupes uniquement)  | Liens vers le projet contenant la dépendance. Si plusieurs projets partagent la même dépendance, le nombre total de ces projets est affiché. Pour accéder à un projet avec cette dépendance, sélectionnez le nombre affiché sous **Projets**, puis recherchez et sélectionnez son nom. |

## Filtrer la liste des dépendances {#filter-dependency-list}

{{< history >}}

- [Introduction](https://gitlab.com/gitlab-org/gitlab/-/issues/513320) du filtrage des dépendances pour les projets dans GitLab 17.9 avec un flag nommé [`project_component_filter`](../../../administration/feature_flags/_index.md). Activés par défaut.
- [Disponible généralement](https://gitlab.com/gitlab-org/gitlab/-/issues/513321) dans GitLab 17.10. Suppression du feature flag `project_component_filter`.
- Filtrage par version de dépendance introduit pour les [projets](https://gitlab.com/gitlab-org/gitlab/-/issues/520771) et les [groupes](https://gitlab.com/gitlab-org/gitlab/-/issues/523061) dans GitLab 18.0 avec des [flags](../../../administration/feature_flags/_index.md) nommés `version_filtering_on_project_level_dependency_list` et `version_filtering_on_group_level_dependency_list`. Désactivées par défaut.
- Filtrage par version de dépendance [activé](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/192291) sur GitLab.com, GitLab Self-Managed et GitLab Dedicated dans GitLab 18.1.
- Suppression des feature flags `version_filtering_on_project_level_dependency_list` et `version_filtering_on_group_level_dependency_list`.

{{< /history >}}

Vous pouvez filtrer la liste des dépendances pour vous concentrer sur un sous-ensemble de dépendances uniquement. La liste des dépendances est disponible pour les groupes et les projets.

Pour les groupes, vous pouvez filtrer par :

- Projet
- Licence
- Composants
- Version de composant

Pour les projets, vous pouvez filtrer par :

- Composants
- Version de composant

Pour filtrer par version de composant, vous devez d'abord filtrer par exactement un composant.

Prérequis :

- Le rôle Développeur, Mainteneur ou Propriétaire pour le projet ou le groupe

Pour filtrer la liste des dépendances :

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à** et repérez votre projet ou groupe.
1. Dans la barre latérale gauche, sélectionnez **Sécuriser** > **Liste des dépendances**.
1. Sélectionnez la barre de filtres.
1. Sélectionnez un filtre, puis choisissez un ou plusieurs critères dans la liste déroulante. Pour fermer la liste déroulante, cliquez en dehors de celle-ci. Pour ajouter d'autres filtres, répétez cette étape.
1. Pour appliquer les filtres sélectionnés, appuyez sur <kbd>Entrée</kbd>.

La liste des dépendances affiche uniquement les dépendances correspondant à vos filtres.

## Vulnérabilités {#vulnerabilities}

{{< history >}}

- [Introduction](https://gitlab.com/gitlab-org/gitlab/-/issues/500551) dans GitLab 17.9 [avec le feature flag](../../../administration/feature_flags/_index.md) `update_sbom_occurrences_vulnerabilities_on_cvs`. Désactivées par défaut.
- [Activé sur GitLab.com et GitLab Self-Managed](https://gitlab.com/gitlab-org/gitlab/-/issues/514223) dans GitLab 17.9.
- Une modification permettant à la liste des dépendances d'afficher uniquement les états `detected` et `confirmed` a été introduite dans GitLab 18.5.

{{< /history >}}

> [!flag]
> La disponibilité de la prise en charge des vulnérabilités associées à l'[analyse des dépendances basée sur les SBOM](../dependency_scanning/dependency_scanning_sbom/_index.md) est contrôlée par un feature flag. Pour plus d'informations, consultez l'historique.

Si une dépendance présente des vulnérabilités connues, consultez-les en sélectionnant la flèche à côté du nom de la dépendance ou le badge indiquant le nombre de vulnérabilités connues. Pour chaque vulnérabilité, sa gravité et sa description apparaissent en dessous. Pour afficher plus de détails sur une vulnérabilité, sélectionnez la description de la vulnérabilité. La page [des détails de la vulnérabilité](../vulnerabilities/_index.md) s'ouvre. La liste des dépendances affiche uniquement les vulnérabilités dans les états `detected` et `confirmed`. Lorsque l'état d'une vulnérabilité change, les modifications ne sont pas répercutées dans la liste des dépendances tant qu'un nouveau pipeline n'est pas exécuté sur la branche par défaut contenant un SBoM.

## Chemins de dépendance {#dependency-paths}

{{< history >}}

- Les informations sur les chemins de dépendance issues du SBOM CycloneDX ont été [introduites](https://gitlab.com/gitlab-org/gitlab/-/issues/393061) dans GitLab 16.9 [avec un feature flag](../../../administration/feature_flags/_index.md) nommé `project_level_sbom_occurrences`. Désactivées par défaut.
- Les informations sur les chemins de dépendance issues du SBOM CycloneDX ont été [activées sur GitLab.com, GitLab Self-Managed et GitLab Dedicated](https://gitlab.com/gitlab-org/gitlab/-/issues/434371) dans GitLab 17.0.
- Les informations sur les chemins de dépendance issues du SBOM CycloneDX sont [disponibles généralement](https://gitlab.com/gitlab-org/gitlab/-/issues/457633) dans GitLab 17.4. Suppression du feature flag `project_level_sbom_occurrences`.

{{< /history >}}

Le chemin de dépendance affiche les dépendants directs d'un composant répertorié si ce composant est transitif et appartient à un gestionnaire de paquets pris en charge. Le chemin de dépendance n'est affiché que pour les dépendances présentant des vulnérabilités.

Les chemins de dépendance sont pris en charge pour les gestionnaires de paquets suivants :

- [Conan](https://conan.io)
- [NuGet](https://www.nuget.org/)
- [sbt](https://www.scala-sbt.org)
- [Yarn 1.x](https://classic.yarnpkg.com/lang/en/)

Les chemins de dépendance sont pris en charge pour les gestionnaires de paquets suivants uniquement lors de l'utilisation du composant [`dependency-scanning`](https://gitlab.com/components/dependency-scanning/-/tree/main/templates/main) :

- [Gradle](https://gradle.org/)
- [Maven](https://maven.apache.org/)
- [NPM](https://www.npmjs.com/)
- [Pipenv](https://pipenv.pypa.io/en/latest/)
- [pip-tools](https://pip-tools.readthedocs.io/en/latest/)
- [pnpm](https://pnpm.io/)
- [Poetry](https://python-poetry.org/)

### Licences {#licenses}

Si le job CI/CD d'[analyse des dépendances](../dependency_scanning/_index.md) est configuré, les [licences découvertes](../../compliance/license_scanning_of_cyclonedx_files/_index.md) sont affichées sur cette page.

## Exporter {#export}

Vous pouvez exporter la liste des dépendances au format :

- JSON
- CSV
- Format CycloneDX (pour les projets uniquement)

Prérequis :

- Le rôle Développeur, Mainteneur ou Propriétaire pour le projet ou le groupe

Pour exporter la liste des dépendances :

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à** et repérez votre projet ou groupe.
1. Dans la barre latérale gauche, sélectionnez **Sécuriser** > **Liste des dépendances**.
1. Sélectionnez **Exporter**, puis sélectionnez le format de fichier.

La liste des dépendances est envoyée à votre adresse e-mail. Pour télécharger la liste des dépendances, sélectionnez le lien dans l'e-mail.

## Dépannage {#troubleshooting}

Lorsque vous utilisez la liste des dépendances, vous pouvez rencontrer les problèmes suivants.

### La licence apparaît comme « unknown » {#license-appears-as-unknown}

La licence d'une dépendance spécifique peut apparaître comme `unknown` pour plusieurs raisons possibles. Cette section explique comment déterminer si la licence d'une dépendance spécifique apparaît comme `unknown` pour une raison connue.

#### La licence est « unknown » en amont {#license-is-unknown-upstream}

Vérifiez la licence spécifiée pour la dépendance en amont :

- Pour les paquets C/C++, consultez [Conancenter](https://conan.io/center).
- Pour les paquets npm, consultez [npmjs.com](https://www.npmjs.com/).
- Pour les paquets Python, consultez [PyPI](https://pypi.org/).
- Pour les paquets NuGet, consultez [NuGet](https://www.nuget.org/packages).
- Pour les paquets Go, consultez [pkg.go.dev](https://pkg.go.dev/).

Si la licence apparaît comme `unknown` en amont, il est prévu que GitLab affiche également la **Licence** de cette dépendance comme `unknown`.

#### La licence inclut une expression de licence SPDX {#license-includes-spdx-license-expression}

Les [expressions de licence SPDX](https://spdx.github.io/spdx-spec/v2.3/SPDX-license-expressions/) ne sont pas prises en charge. Les dépendances avec des expressions de licence SPDX apparaissent avec une **Licence** indiquée comme `unknown`. Un exemple d'expression de licence SPDX est `(MIT OR CC0-1.0)`. En savoir plus dans le [ticket 336878](https://gitlab.com/gitlab-org/gitlab/-/issues/336878).

#### Version du paquet absente de la base de données des métadonnées de paquets {#package-version-not-in-package-metadata-db}

La version spécifique du paquet de dépendance doit exister dans la [base de données des métadonnées de paquets](../../../topics/offline/quick_start_guide.md#enabling-the-package-metadata-database). Si ce n'est pas le cas, la **Licence** de cette dépendance apparaît comme `unknown`. En savoir plus dans le [ticket 440218](https://gitlab.com/gitlab-org/gitlab/-/issues/440218) concernant les modules Go.

#### Le nom du paquet contient des caractères spéciaux {#package-name-contains-special-characters}

Si le nom du paquet de dépendance contient un trait d'union (`-`), la **Licence** peut apparaître comme `unknown`. Cela peut se produire lorsque des paquets sont ajoutés manuellement à `requirements.txt` ou lors de l'utilisation de `pip-compile`. Cela se produit parce que GitLab ne normalise pas les noms des paquets Python conformément aux recommandations sur les [noms normalisés dans la PEP 503](https://peps.python.org/pep-0503/#normalized-names) lors de l'ingestion des informations sur les dépendances. En savoir plus dans le [ticket 440391](https://gitlab.com/gitlab-org/gitlab/-/issues/440391).
