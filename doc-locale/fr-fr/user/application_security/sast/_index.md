---
stage: Application Security Testing
group: Static Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Test statique de sécurité des applications (SAST)
description: "Analyse, configuration, analyseurs, vulnérabilités, rapports, personnalisation et intégration."
---

<style>
table.sast-table tr:nth-child(even) {
    background-color: transparent;
}

table.sast-table td {
    border-left: 1px solid #dbdbdb;
    border-right: 1px solid #dbdbdb;
    border-bottom: 1px solid #dbdbdb;
}

table.sast-table tr td:first-child {
    border-left: 0;
}

table.sast-table tr td:last-child {
    border-right: 0;
}

table.sast-table ul {
    font-size: 1em;
    list-style-type: none;
    padding-left: 0px;
    margin-bottom: 0px;
}

table.no-vertical-table-lines td {
    border-left: none;
    border-right: none;
    border-bottom: 1px solid #f0f0f0;
}

table.no-vertical-table-lines tr {
    border-top: none;
}
</style>

{{< details >}}

- Niveau :  Free, Premium, Ultimate
- Offre :  GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Le test statique de sécurité des applications (SAST) détecte les vulnérabilités dans votre code source avant qu'elles n'atteignent la production. Intégré directement dans votre pipeline CI/CD, le SAST identifie les problèmes de sécurité pendant le développement, au moment où il est le plus facile et le plus économique de les corriger.

Les vulnérabilités de sécurité détectées tardivement dans le développement entraînent des retards coûteux et des risques potentiels de failles. Les analyses SAST s'effectuent automatiquement à chaque commit, vous fournissant un retour immédiat sans perturber votre flux de travail.

## Réduction des faux positifs et résolution des vulnérabilités avec GitLab Duo {#reducing-false-positives-and-resolving-vulnerabilities-with-gitlab-duo}

{{< details >}}

- Niveau :  Ultimate

{{< /details >}}

Les analyseurs SAST peuvent générer des faux positifs qui créent du bruit dans vos rapports de vulnérabilités. GitLab Duo vous aide dans la gestion des vulnérabilités.

### Détection des faux positifs {#false-positive-detection}

[Détection des faux positifs GitLab Duo](../vulnerabilities/false_positive_detection.md) analyse automatiquement les vulnérabilités SAST de gravité critique et élevée pour identifier les faux positifs probables. Cela aide votre équipe de sécurité à se concentrer sur les vulnérabilités réelles et réduit le temps consacré au triage manuel.

Pour les clients du niveau Ultimate disposant d'un module complémentaire GitLab Duo, la détection des faux positifs s'exécute automatiquement après chaque analyse de sécurité et fournit des scores de confiance avec des explications pour chaque évaluation.

### Résolution agentique des vulnérabilités SAST {#agentic-sast-vulnerability-resolution}

[Agentic SAST Vulnerability Resolution](../vulnerabilities/agentic_vulnerability_resolution.md) génère automatiquement des merge requests avec des corrections de code contextuelles pour les vulnérabilités SAST de gravité Élevée et Critique. Cette approche agentique utilise un raisonnement multi-étapes pour résoudre les vulnérabilités avec une intervention humaine minimale.

Pour les clients du niveau Ultimate, la résolution agentique des vulnérabilités s'exécute automatiquement après chaque analyse de sécurité lorsque les vulnérabilités remplissent des conditions spécifiques.

## Fonctionnalités {#features}

Le tableau suivant répertorie les niveaux GitLab dans lesquels chaque fonctionnalité est disponible.

| Fonctionnalité                                                                                                                          | Dans Free & Premium | Dans Ultimate |
|:---------------------------------------------------------------------------------------------------------------------------------|:------------------|:------------|
| Analyse de base avec [des analyseurs open source](#supported-languages-and-frameworks)                                                 | {{< yes >}}       | {{< yes >}} |
| [Rapport JSON SAST](#download-a-sast-report) téléchargeable                                                                         | {{< yes >}}       | {{< yes >}} |
| Analyse inter-fichiers et inter-fonctions avec [GitLab Advanced SAST](gitlab_advanced_sast.md)                                         | {{< no >}}        | {{< yes >}} |
| Nouveaux résultats dans le [widget de merge request](#merge-request-widget)                                                                    | {{< no >}}        | {{< yes >}} |
| Nouveaux résultats dans la [vue des modifications de merge request](#merge-request-changes-view)                                                        | {{< no >}}        | {{< yes >}} |
| [Gestion des vulnérabilités](../vulnerabilities/_index.md)                                                                         | {{< no >}}        | {{< yes >}} |
| [Détection des faux positifs GitLab Duo](../vulnerabilities/false_positive_detection.md) (nécessite le module complémentaire GitLab Duo)               | {{< no >}}        | {{< yes >}} |
| [Agentic SAST Vulnerability Resolution](../vulnerabilities/agentic_vulnerability_resolution.md) | {{< no >}}        | {{< yes >}} |
| [Configuration du scanner via l'interface utilisateur](#enable-sast-by-using-the-ui)                                                                   | {{< no >}}        | {{< yes >}} |
| [Personnalisation des ensembles de règles](customize_rulesets.md)                                                                                   | {{< no >}}        | {{< yes >}} |
| [Suivi avancé des vulnérabilités](#advanced-vulnerability-tracking)                                                              | {{< no >}}        | {{< yes >}} |

## Premiers pas {#getting-started}

Activez le SAST dans votre projet en utilisant soit l'interface utilisateur, soit en modifiant le fichier de configuration GitLab CI/CD de votre projet.

> [!note]
> Par défaut, le SAST s'exécute uniquement dans les pipelines de branche. Pour exécuter le SAST dans des pipelines de merge request, voir [utiliser les outils d'analyse de sécurité avec les pipelines de merge request](../detect/security_configuration.md#use-security-scanning-tools-with-merge-request-pipelines).

### Activer le SAST via l'interface utilisateur {#enable-sast-by-using-the-ui}

{{< details >}}

- Niveau :  Ultimate
- Offre :  GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Suppression](https://gitlab.com/gitlab-org/gitlab/-/issues/410013) des options de configuration individuelles des analyseurs SAST de l'interface utilisateur dans GitLab 16.2.

{{< /history >}}

Vous pouvez activer et configurer le SAST via l'interface utilisateur, soit avec les paramètres par défaut, soit avec des personnalisations. La méthode que vous pouvez utiliser dépend de votre niveau de licence GitLab.

> [!note]
> La méthode de configuration via l'interface utilisateur fonctionne mieux avec un fichier `.gitlab-ci.yml` minimal ou inexistant. Si vous avez une configuration complexe, l'outil peut ne pas réussir à l'analyser. Dans ce cas, [modifiez plutôt le fichier CI/CD](#enable-sast-by-editing-the-cicd-file).

#### Activer le SAST avec des personnalisations {#enable-sast-with-customizations}

Prérequis :

- Le rôle Maintainer ou Owner pour le projet.
- Un runner GitLab sous Linux avec l'exécuteur Docker ou Kubernetes. Si vous utilisez des runners hébergés pour GitLab.com, l'exécuteur Docker ou Kubernetes est activé par défaut.
  - Le runner GitLab sur les runners Windows n'est pas pris en charge.
  - Les architectures CPU autres qu'AMD64 ne sont pas prises en charge.
- La configuration GitLab CI/CD (`.gitlab-ci.yml`) doit inclure l'étape `test`, qui est incluse par défaut. Si vous redéfinissez les étapes dans le fichier `.gitlab-ci.yml`, l'étape `test` est requise.

Pour activer et configurer le SAST avec des personnalisations :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Sécurisation** > **Configuration de la sécurité**.
1. Si le dernier pipeline pour la branche par défaut du projet s'est terminé et a produit des artefacts SAST valides, sélectionnez **Configure SAST**, sinon sélectionnez **Enable SAST** dans la ligne du test statique de sécurité des applications (SAST).
1. Saisissez les valeurs SAST personnalisées.

   Les valeurs personnalisées sont stockées dans le fichier `.gitlab-ci.yml`. Pour les variables CI/CD non présentes dans la page de configuration SAST, leurs valeurs sont héritées du modèle GitLab SAST.
1. Sélectionnez **Créer une requête de fusion**.
1. Examinez et fusionnez la merge request.

Les pipelines incluent désormais un job SAST. Si du code source pris en charge est présent, les analyseurs appropriés et les règles par défaut analysent automatiquement les vulnérabilités lors de l'exécution d'un pipeline. Les jobs correspondants apparaissent sous l'étape `test` dans le pipeline du projet.

#### Activer le SAST avec les paramètres par défaut uniquement {#enable-sast-with-default-settings-only}

Prérequis :

- Le rôle Maintainer ou Owner pour le projet.
- Un runner GitLab sous Linux avec l'exécuteur Docker ou Kubernetes. Si vous utilisez des runners hébergés pour GitLab.com, l'exécuteur Docker ou Kubernetes est activé par défaut.
  - Le runner GitLab sur les runners Windows n'est pas pris en charge.
  - Les architectures CPU autres qu'AMD64 ne sont pas prises en charge.
- La configuration GitLab CI/CD (`.gitlab-ci.yml`) doit inclure l'étape `test`, qui est incluse par défaut. Si vous redéfinissez les étapes dans le fichier `.gitlab-ci.yml`, l'étape `test` est requise.

Pour activer et configurer le SAST avec les paramètres par défaut :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Sécurisation** > **Configuration de la sécurité**.
1. Dans la section SAST, sélectionnez **Configurer avec une requête de fusion**.

   La page de la merge request s'ouvre.
1. Remplissez les champs.
1. Sélectionnez **Créer une requête de fusion**.
1. Examinez et fusionnez la merge request pour activer le SAST.

Les pipelines incluent désormais un job SAST. Si du code source pris en charge est présent, les analyseurs appropriés et les règles par défaut analysent automatiquement les vulnérabilités lors de l'exécution d'un pipeline. Les jobs correspondants apparaissent sous l'étape `test` dans le pipeline du projet.

### Activer le SAST en modifiant le fichier CI/CD {#enable-sast-by-editing-the-cicd-file}

Prérequis :

- Le rôle Developer, Maintainer ou Owner pour le projet.
- Un runner GitLab sous Linux avec l'exécuteur Docker ou Kubernetes. Si vous utilisez des runners hébergés pour GitLab.com, l'exécuteur Docker ou Kubernetes est activé par défaut.
  - Le runner GitLab sur les runners Windows n'est pas pris en charge.
  - Les architectures CPU autres qu'AMD64 ne sont pas prises en charge.
- La configuration GitLab CI/CD (`.gitlab-ci.yml`) doit inclure l'étape `test`, qui est incluse par défaut. Si vous redéfinissez les étapes dans le fichier `.gitlab-ci.yml`, l'étape `test` est requise.

Pour activer le SAST dans votre projet :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre projet.
1. Accédez à **Version** > éditeur de **Pipeline**.
1. Ajoutez le modèle ou le composant CI/CD SAST.

   Pour utiliser le modèle, ajoutez les lignes suivantes :

   ```yaml
   include:
     - template: Jobs/SAST.gitlab-ci.yml
   ```

   Pour utiliser le composant CI/CD, ajoutez les lignes suivantes :

   ```yaml
   include:
     - component: gitlab.com/components/sast/sast@main
   ```

1. Sélectionnez l'onglet **Valider**, puis sélectionnez **Valider le pipeline**.

   Le message **Simulation terminée avec succès** confirme que le fichier est valide.
1. Sélectionnez l'onglet **Éditer**.
1. Remplissez les champs :
   - Message de commit.
   - Branche. Par exemple, `add-sast`.
1. Cochez la case **Start a new merge request with these changes**, puis sélectionnez **Valider les modifications**.

   La page de la merge request s'ouvre.
1. Remplissez les champs selon votre flux de travail standard, puis sélectionnez **Créer une requête de fusion**.
1. Examinez et modifiez la merge request selon votre flux de travail standard, puis sélectionnez **Fusionner**.

Les pipelines incluent désormais un job SAST. Si du code source pris en charge est présent, les analyseurs appropriés et les règles par défaut analysent automatiquement les vulnérabilités lors de l'exécution d'un pipeline. Les jobs correspondants apparaissent sous l'étape `test` dans le pipeline du projet.

Vous pouvez voir un exemple fonctionnel dans [le projet d'exemple SAST](https://gitlab.com/gitlab-org/security-products/demos/analyzer-configurations/semgrep/sast-getting-started).

### Étapes suivantes {#next-steps}

Après avoir activé le SAST, vous pouvez :

- En savoir plus sur la façon de [comprendre les résultats](#understanding-the-results).
- Consulter les [conseils d'optimisation](#optimization).
- Planifier un [déploiement vers d'autres projets](#roll-out).

## Comprendre les résultats {#understanding-the-results}

Prérequis :

- Le rôle Responsable sécurité, Developer, Maintainer ou Owner pour le projet.

Vous pouvez examiner les vulnérabilités dans un pipeline :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Version** > **Pipelines**.
1. Sélectionnez le pipeline.
1. Sélectionnez l'onglet **Sécurité**.
1. Téléchargez les résultats, ou sélectionnez une vulnérabilité pour afficher ses détails (Ultimate uniquement), notamment :
   - Description :  Explique la cause de la vulnérabilité, son impact potentiel et les étapes de remédiation recommandées.
   - Statut :  Indique si la vulnérabilité a été triée ou résolue.
   - Gravité :  Classifiée en six niveaux selon l'impact. [En savoir plus sur les niveaux de gravité](../vulnerabilities/severities.md).
   - Emplacement :  Affiche le nom du fichier et le numéro de ligne où le problème a été trouvé. La sélection du chemin de fichier ouvre la ligne correspondante dans la vue du code.
   - Analyseur :  Identifie quel analyseur a détecté la vulnérabilité.
   - Identifiants :  Une liste de références utilisées pour classifier la vulnérabilité, telles que les identifiants CWE et les identifiants des règles qui l'ont détectée.

Les vulnérabilités SAST sont nommées d'après l'identifiant principal Common Weakness Enumeration (CWE) pour la vulnérabilité découverte. Lisez la description de chaque résultat de vulnérabilité pour en savoir plus sur le problème spécifique détecté par l'analyseur. Pour plus d'informations sur la couverture SAST, voir [les règles SAST](rules.md).

Dans Ultimate, vous pouvez également télécharger les résultats de l'analyse de sécurité :

Prérequis :

- Le rôle Responsable sécurité, Developer, Maintainer ou Owner pour le projet.

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Version** > **Pipelines**.
1. Sélectionnez le pipeline.
1. Sélectionnez l'onglet **Sécurité**.
1. Dans l'onglet **Sécurité** du pipeline, sélectionnez **Télécharger les résultats**.

Pour plus de détails, voir [Rapport de sécurité du pipeline](../detect/security_scanning_results.md).

> [!note]
> Les résultats sont générés sur les branches de fonctionnalité. Lorsqu'ils sont fusionnés dans la branche par défaut, ils deviennent des vulnérabilités. Cette distinction est importante lors de l'évaluation de votre posture de sécurité.

Autres façons de consulter les résultats SAST :

- Widget de merge request :  Affiche les résultats nouvellement introduits ou résolus.
- Vue des modifications de merge request :  Affiche les annotations en ligne pour les lignes modifiées.
- Rapport de vulnérabilités :  Affiche les vulnérabilités confirmées sur la branche par défaut.

Un pipeline se compose de plusieurs jobs, notamment les analyses SAST et DAST. Si un job ne se termine pas pour quelque raison que ce soit, le tableau de bord de sécurité n'affiche pas la sortie de l'analyseur SAST. Par exemple, si le job SAST se termine mais que le job DAST échoue, le tableau de bord de sécurité n'affiche pas les résultats SAST. En cas d'échec, l'analyseur génère un code de sortie.

### Widget de merge request {#merge-request-widget}

{{< details >}}

- Niveau :  Ultimate

{{< /details >}}

Les résultats SAST s'affichent dans la zone du widget de merge request si un rapport de la branche cible est disponible pour comparaison. Le widget de merge request affiche les éléments suivants :

- Nouveaux résultats SAST introduits par la MR.
- Résultats existants résolus par la MR.

Les résultats sont comparés à l'aide du suivi avancé des vulnérabilités chaque fois qu'il est disponible.

![Widget de merge request de sécurité](img/sast_mr_widget_v16_7.png)

### Vue des modifications de merge request {#merge-request-changes-view}

{{< details >}}

- Niveau :  Ultimate

{{< /details >}}

{{< history >}}

- [Introduit](https://gitlab.com/groups/gitlab-org/-/epics/10959) dans GitLab 16.6 avec un [flag](../../../administration/feature_flags/_index.md) nommé `sast_reports_in_inline_diff`. Désactivé par défaut.
- Activé par défaut dans GitLab 16.8.
- [Feature flag supprimé](https://gitlab.com/gitlab-org/gitlab/-/issues/410191) dans GitLab 16.9.

{{< /history >}}

Les résultats SAST s'affichent dans la vue **Modifications** de la merge request. Les lignes contenant des problèmes SAST sont marquées par un symbole à côté de la gouttière. Sélectionnez le symbole pour afficher la liste des problèmes, puis sélectionnez un problème pour en afficher les détails.

![Indicateur en ligne SAST](img/sast_inline_indicator_v16_7.png)

## Optimisation {#optimization}

Pour optimiser le SAST selon vos besoins, vous pouvez :

- Désactiver une règle.
- Exclure des fichiers ou des chemins de l'analyse.

### Désactiver une règle {#disable-a-rule}

Prérequis :

- Le rôle Developer, Maintainer ou Owner pour le projet.

Pour désactiver une règle, par exemple parce qu'elle génère trop de faux positifs :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre projet.
1. Créez un fichier `.gitlab/sast-ruleset.toml` à la racine de votre projet s'il n'existe pas déjà.
1. Dans les détails de la vulnérabilité, localisez l'identifiant de la règle qui a déclenché le résultat.
1. Utilisez l'identifiant de la règle pour désactiver la règle. Par exemple, pour désactiver `gosec.G107-1`, ajoutez ce qui suit dans `.gitlab/sast-ruleset.toml` :

   ```toml
   [semgrep]
     [[semgrep.ruleset]]
       disable = true
       [semgrep.ruleset.identifier]
         type = "semgrep_id"
         value = "gosec.G107-1"
   ```

Pour plus de détails sur la personnalisation des ensembles de règles, voir [Personnaliser les ensembles de règles](customize_rulesets.md).

### Exclure des fichiers ou des chemins de l'analyse {#exclude-files-or-paths-from-being-scanned}

Prérequis :

- Le rôle Developer, Maintainer ou Owner pour le projet.

Pour exclure des fichiers ou des chemins de l'analyse, par exemple du code de test ou temporaire, définissez la variable `SAST_EXCLUDED_PATHS`. Par exemple, pour ignorer `rule-template-injection.go`, ajoutez ce qui suit à votre `.gitlab-ci.yml` :

```yaml
variables:
  SAST_EXCLUDED_PATHS: "rule-template-injection.go"
```

Pour plus d'informations sur les options de configuration, voir [Variables CI/CD disponibles](#available-cicd-variables).

## Déploiement {#roll-out}

Lorsque vous êtes confiant dans les résultats SAST pour un seul projet, vous pouvez étendre son implémentation à d'autres projets :

- Utilisez [l'exécution d'analyse forcée](../detect/security_configuration.md#create-a-shared-configuration) pour appliquer les paramètres SAST à travers les groupes.
- Partagez et réutilisez un ensemble de règles central en [spécifiant un fichier de configuration distant](customize_rulesets.md#use-a-remote-ruleset-file).
- Si vous avez des besoins spécifiques, le SAST peut être exécuté dans un environnement hors ligne ou sous des contraintes SELinux.

## Langages et frameworks pris en charge {#supported-languages-and-frameworks}

GitLab SAST prend en charge l'analyse des langages et frameworks suivants.

Les options d'analyse disponibles dépendent du niveau GitLab :

- Dans Ultimate, GitLab Advanced SAST fournit des résultats plus précis. Vous devriez l'utiliser pour les langages qu'il prend en charge.
- Dans tous les niveaux, vous pouvez utiliser les analyseurs fournis par GitLab, basés sur des analyseurs open source, pour analyser votre code.

Pour plus d'informations sur les plans de prise en charge des langages dans le SAST, voir la [page de direction de catégorie](https://about.gitlab.com/direction/application_security_testing/static-analysis/sast/#language-support).

### Langages avec prise en charge complète {#languages-with-full-support}

{{< history >}}

- Prise en charge de C/C++ [introduite](https://gitlab.com/groups/gitlab-org/-/epics/14271) dans GitLab 18.6.

{{< /history >}}

Ces langages sont pris en charge à la fois par GitLab Advanced SAST (Ultimate) et les analyseurs standard (tous les niveaux) :

| Langage               | GitLab Advanced SAST<sup>1</sup> | Analyseur standard<sup>2</sup> |
|------------------------|----------------------------------|-------------------------------|
| C                      | {{< yes >}}                      | {{< yes >}}                   |
| C++                    | {{< yes >}}                      | {{< yes >}}                   |
| C#                     | {{< yes >}}                      | {{< yes >}}                   |
| Go                     | {{< yes >}}                      | {{< yes >}}                   |
| Java<sup>3</sup>       | {{< yes >}}                      | {{< yes >}}                   |
| Java Properties        | {{< yes >}}                      | {{< yes >}}                   |
| JavaScript<sup>4</sup> | {{< yes >}}                      | {{< yes >}}                   |
| PHP                    | {{< yes >}}                      | {{< yes >}}                   |
| Python                 | {{< yes >}}                      | {{< yes >}}                   |
| Ruby<sup>5</sup>       | {{< yes >}}                      | {{< yes >}}                   |
| TypeScript             | {{< yes >}}                      | {{< yes >}}                   |
| YAML<sup>6</sup>       | {{< yes >}}                      | {{< yes >}}                   |

**Footnotes** :

<!-- Disable ordered list rule <https://github.com/DavidAnson/markdownlint/blob/main/doc/Rules.md#md029---ordered-list-item-prefix> -->
<!-- markdownlint-disable MD029 -->

1. [GitLab Advanced SAST](gitlab_advanced_sast.md) \- niveau Ultimate uniquement.
2. Tous les niveaux. Utilise l'analyseur [Semgrep](https://gitlab.com/gitlab-org/security-products/analyzers/semgrep) avec les [règles gérées par GitLab](rules.md#semgrep-based-analyzer), sauf indication contraire.
3. Y compris Java Server Pages (JSP) et Android.
4. Y compris Node.js et React.
5. Y compris Ruby on Rails.
6. La prise en charge de YAML est limitée aux modèles de fichiers suivants :
   - `application*.yml`
   - `application*.yaml`
   - `bootstrap*.yml`
   - `bootstrap*.yaml`

<!-- markdownlint-enable MD029 -->

### Langages avec prise en charge par l'analyseur standard uniquement {#languages-with-standard-analyzer-support-only}

Ces langages sont pris en charge par les analyseurs standard (tous les niveaux) mais pas par GitLab Advanced SAST :

| Langage           | Analyseur standard<sup>1</sup>                                                                           | Prise en charge proposée<sup>2</sup> |
|--------------------|---------------------------------------------------------------------------------------------------------|------------------------------|
| Apex (Salesforce)  | {{< yes >}} [PMD-Apex](https://gitlab.com/gitlab-org/security-products/analyzers/pmd-apex)              | Aucune                         |
| Elixir (Phoenix)   | {{< yes >}} [Sobelow](https://gitlab.com/gitlab-org/security-products/analyzers/sobelow)                | Aucune                         |
| Groovy             | {{< yes >}} [SpotBugs](https://gitlab.com/gitlab-org/security-products/analyzers/spotbugs)<sup>3</sup>  | Aucune                         |
| Kotlin<sup>4</sup> | {{< yes >}}                                                                                             | [Epic 15173](https://gitlab.com/groups/gitlab-org/-/epics/15173) |
| Objective-C (iOS)  | {{< yes >}}                                                                                             | [Epic 16318](https://gitlab.com/groups/gitlab-org/-/epics/16318) |
| Scala              | {{< yes >}}                                                                                             | [Epic 15174](https://gitlab.com/groups/gitlab-org/-/epics/15174) |
| Swift (iOS)        | {{< yes >}}                                                                                             | [Epic 16318](https://gitlab.com/groups/gitlab-org/-/epics/16318) |

**Footnotes** :

1. Tous les niveaux. Utilise l'analyseur [Semgrep](https://gitlab.com/gitlab-org/security-products/analyzers/semgrep) avec les [règles gérées par GitLab](rules.md#semgrep-based-analyzer), sauf indication contraire.
1. L'epic référencé propose la prise en charge de GitLab Advanced SAST pour ces langages.
1. SpotBugs avec le plug-in find-sec-bugs. Prend en charge Gradle, Maven et SBT. Il peut également être utilisé avec des variantes telles que le wrapper Gradle, Grails et le wrapper Maven. Cependant, SpotBugs a des [limitations](https://gitlab.com/gitlab-org/gitlab/-/issues/350801) lorsqu'il est utilisé avec des projets basés sur Ant. Vous devriez utiliser GitLab Advanced SAST ou l'analyseur basé sur Semgrep pour les projets Java ou Scala basés sur Ant.
1. Y compris Android.

Le modèle CI/CD SAST inclut également un job d'analyseur capable d'analyser les manifestes Kubernetes et les charts Helm ; ce job est désactivé par défaut. Voir [Activer l'analyseur Kubesec](#enabling-kubesec-analyzer) ou envisager plutôt l'[analyse IaC](../iac_scanning/_index.md), qui prend en charge des plateformes supplémentaires.

Pour en savoir plus sur les analyseurs SAST qui ne sont plus pris en charge, voir [Analyseurs ayant atteint la fin de la prise en charge](analyzers.md#analyzers-that-have-reached-end-of-support).

## Suivi avancé des vulnérabilités {#advanced-vulnerability-tracking}

{{< details >}}

- Niveau :  Ultimate
- Offre :  GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Le code source est volatile ; à mesure que les développeurs apportent des modifications, le code source peut se déplacer dans le même fichier ou entre des fichiers. Des analyseurs de sécurité peuvent déjà avoir signalé des vulnérabilités qui sont suivies dans le rapport de vulnérabilités. Ces vulnérabilités sont liées à des fragments de code problématiques spécifiques afin qu'elles puissent être trouvées et corrigées. Si les fragments de code ne sont pas suivis de manière fiable au fur et à mesure de leur déplacement, la gestion des vulnérabilités devient plus difficile car la même vulnérabilité pourrait être signalée à nouveau.

GitLab SAST utilise un algorithme de suivi avancé des vulnérabilités pour identifier plus précisément quand la même vulnérabilité s'est déplacée dans le même fichier en raison d'un refactoring ou de modifications sans rapport.

La prise en charge du suivi avancé des vulnérabilités dépend du langage et des analyseurs utilisés.

Langages pris en charge à la fois par les analyseurs GitLab Advanced SAST et les analyseurs basés sur Semgrep :

- C
- C++
- C#
- Go
- Java
- JavaScript
- Python

Langages pris en charge uniquement par les analyseurs basés sur Semgrep :

- PHP
- Ruby

La prise en charge d'autres langages et analyseurs est suivie dans l'[epic 5144](https://gitlab.com/groups/gitlab-org/-/epics/5144).

Pour plus d'informations, voir le projet confidentiel `https://gitlab.com/gitlab-org/security-products/post-analyzers/tracking-calculator`. Le contenu de ce projet est accessible uniquement aux membres de l'équipe GitLab.

## Résolution automatique des vulnérabilités {#automatic-vulnerability-resolution}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/368284) dans GitLab 15.9 [avec un flag de projet](../../../administration/feature_flags/_index.md) nommé `sec_mark_dropped_findings_as_resolved`.
- Activé par défaut dans GitLab 15.10.
- [Feature flag supprimé](https://gitlab.com/gitlab-org/gitlab/-/issues/375128) dans GitLab 16.2.

{{< /history >}}

Pour vous aider à vous concentrer sur les vulnérabilités encore pertinentes, GitLab SAST [résout](../vulnerabilities/_index.md#vulnerability-status-values) automatiquement les vulnérabilités lorsque :

- Vous [désactivez une règle prédéfinie](customize_rulesets.md#disable-default-rules).
- Une règle est supprimée de l'ensemble de règles par défaut.

La résolution automatique est disponible uniquement pour les résultats provenant de l'[analyseur basé sur Semgrep](https://gitlab.com/gitlab-org/security-products/analyzers/semgrep). Le système de gestion des vulnérabilités laisse un commentaire sur les vulnérabilités résolues automatiquement afin que vous conserviez toujours un historique de la vulnérabilité.

Si vous réactivez la règle ultérieurement, les résultats sont rouverts pour triage.

## Distributions prises en charge {#supported-distributions}

Les images d'analyseur par défaut sont construites sur une image Alpine de base pour des raisons de taille et de maintenabilité.

### Images compatibles FIPS {#fips-enabled-images}

GitLab propose une version d'image, basée sur l'image de base [Red Hat UBI](https://www.redhat.com/en/blog/introducing-red-hat-universal-base-image), qui utilise un module cryptographique validé FIPS 140. Pour utiliser l'image compatible FIPS, vous pouvez soit :

- Définir `SAST_IMAGE_SUFFIX` sur `-fips`.
- Ajouter l'extension `-fips` au nom d'image par défaut.

Par exemple :

```yaml
variables:
  SAST_IMAGE_SUFFIX: '-fips'

include:
  - template: Jobs/SAST.gitlab-ci.yml
```

Une image conforme FIPS est uniquement disponible pour les analyseurs GitLab Advanced SAST et Semgrep.

> [!warning]
> Pour utiliser le SAST de manière conforme FIPS, vous devez [exclure les autres analyseurs de l'exécution](analyzers.md#customize-analyzers). Si vous utilisez une image compatible FIPS pour exécuter Advanced SAST ou Semgrep dans [un runner avec un utilisateur non root](https://docs.gitlab.com/runner/install/kubernetes_helm_chart_configuration/#run-with-non-root-user), vous devez mettre à jour l'attribut `run_as_user` sous `runners.kubernetes.pod_security_context` pour utiliser l'identifiant de l'utilisateur `gitlab` [créé par l'image](https://gitlab.com/gitlab-org/security-products/analyzers/semgrep/-/blob/a5d822401014f400b24450c92df93467d5bbc6fd/Dockerfile.fips#L58), qui est `1000`.

## Télécharger un rapport SAST {#download-a-sast-report}

Prérequis :

- Le rôle Developer, Maintainer ou Owner pour le projet.

Chaque analyseur SAST génère un rapport JSON en tant qu'artefact de job. Le fichier contient les détails de toutes les vulnérabilités détectées. Vous pouvez télécharger le fichier pour le traiter en dehors de GitLab.

Pour plus d'informations, voir :

- [Schéma du fichier de rapport SAST](https://gitlab.com/gitlab-org/security-products/security-report-schemas/-/blob/master/dist/sast-report-format.json)
- [Exemple de fichier de rapport SAST](https://gitlab.com/gitlab-org/security-products/analyzers/semgrep/-/blob/main/qa/expect/js/default/gl-sast-report.json)

## Configuration {#configuration}

GitLab SAST est conçu pour être utilisé dans sa configuration par défaut. Cependant, vous pouvez [modifier les variables de configuration](#available-cicd-variables) ou [personnaliser les règles de détection](customize_rulesets.md) selon vos besoins.

### Modèles SAST stables et derniers modèles {#stable-vs-latest-sast-templates}

SAST propose un modèle [`stable`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Jobs/SAST.gitlab-ci.yml) , utilisé par défaut en production, et un modèle [`latest`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Jobs/SAST.latest.gitlab-ci.yml) pour tester les fonctionnalités de pointe. Pour plus de détails sur les différences et quand utiliser chacun, voir [les éditions de modèles](../detect/security_configuration.md#template-editions).

### Remplacer les jobs SAST {#override-sast-jobs}

Remplacez les jobs SAST lorsque vous souhaitez personnaliser des propriétés telles que `variables`, `dependencies` et [`rules`](../../../ci/yaml/_index.md#rules).

Prérequis :

- Le rôle Developer, Maintainer ou Owner pour le projet.

Pour remplacer une définition de job :

- Déclarez un job portant le même nom que le job SAST à remplacer.

  Placez ce nouveau job après l'inclusion du modèle et spécifiez les clés supplémentaires sous celui-ci.

Dans l'exemple suivant, la variable CI/CD `FAIL_NEVER` est activée pour l'analyseur `spotbugs` :

```yaml
include:
  - template: Jobs/SAST.gitlab-ci.yml

spotbugs-sast:
  variables:
    FAIL_NEVER: 1
```

### Épingler la version de l'image de l'analyseur {#pin-analyzer-image-version}

Épinglez la version de l'image lorsque vous souhaitez utiliser une version spécifique de l'image d'analyseur dans le pipeline. Le modèle CI/CD géré par GitLab spécifie une version majeure et extrait automatiquement la dernière release de l'analyseur au sein de cette version majeure. Dans certains cas, vous pouvez avoir besoin d'utiliser une version spécifique. Par exemple, vous pourriez avoir besoin d'éviter une régression dans une release ultérieure.

Vous pouvez définir le tag sur l'une des options suivantes :

- Une version majeure, par exemple `3`. Vos pipelines utilisent toutes les mises à jour mineures ou de correctif publiées dans cette version majeure.
- Une version mineure, par exemple `3.7`. Vos pipelines utilisent toutes les mises à jour de correctif publiées dans cette version mineure.
- Une version de correctif, par exemple `3.7.0`. Vos pipelines ne reçoivent aucune mise à jour.

Définissez cette variable uniquement dans un job spécifique. Si vous la définissez [au niveau supérieur](../../../ci/variables/_index.md#define-a-cicd-variable-in-the-gitlab-ciyml-file), la version que vous définissez est utilisée pour tous les analyseurs SAST.

Prérequis :

- Le rôle Developer, Maintainer ou Owner pour le projet.

Pour épingler l'image de l'analyseur à une version spécifique :

- Définissez la variable CI/CD `SAST_ANALYZER_IMAGE_TAG` dans le fichier `.gitlab-ci.yml` du projet. Cette variable CI/CD doit être listée après l'inclusion du modèle `SAST.gitlab-ci.yml`.

Dans l'exemple suivant, une version mineure spécifique de l'analyseur `semgrep` et une version de correctif spécifique de l'analyseur `brakeman` sont définies :

```yaml
include:
  - template: Jobs/SAST.gitlab-ci.yml

semgrep-sast:
  variables:
    SAST_ANALYZER_IMAGE_TAG: "3.7"

brakeman-sast:
  variables:
    SAST_ANALYZER_IMAGE_TAG: "3.1.1"
```

### Utilisation des variables CI/CD pour transmettre des identifiants à des dépôts privés {#using-cicd-variables-to-pass-credentials-for-private-repositories}

Certains analyseurs nécessitent le téléchargement des dépendances du projet pour effectuer l'analyse. De telles dépendances peuvent résider dans des dépôts Git privés et nécessiter des identifiants tels qu'un nom d'utilisateur et un mot de passe pour les télécharger. Selon l'analyseur, ces identifiants peuvent lui être fournis en utilisant des [variables CI/CD personnalisées](#available-cicd-variables).

#### Utilisation d'une variable CI/CD pour transmettre le nom d'utilisateur et le mot de passe à un dépôt Maven privé {#using-a-cicd-variable-to-pass-username-and-password-to-a-private-maven-repository}

Si votre dépôt Maven privé nécessite des identifiants de connexion, vous pouvez utiliser la variable CI/CD `MAVEN_CLI_OPTS`.

Pour plus d'informations, voir [comment utiliser les dépôts Maven privés](../dependency_scanning/legacy_dependency_scanning/_index.md#authenticate-with-a-private-maven-repository).

### Activation de l'analyseur Kubesec {#enabling-kubesec-analyzer}

Prérequis :

- Le rôle Developer, Maintainer ou Owner pour le projet.

Vous devez définir `SCAN_KUBERNETES_MANIFESTS` sur `"true"` pour activer l'analyseur Kubesec. Dans `.gitlab-ci.yml`, définissez :

```yaml
include:
  - template: Jobs/SAST.gitlab-ci.yml

variables:
  SCAN_KUBERNETES_MANIFESTS: "true"
```

### Analyser d'autres langages avec l'analyseur basé sur Semgrep {#scan-other-languages-with-the-semgrep-based-analyzer}

Vous pouvez personnaliser l'analyseur SAST basé sur Semgrep pour analyser des langages qui ne sont pas pris en charge par un ensemble de règles géré par GitLab. Cependant, comme GitLab ne fournit pas d'ensembles de règles pour ces autres langages, vous devez [remplacer ou compléter les règles par défaut](customize_rulesets.md#replace-or-add-to-the-default-rules) pour les couvrir. Vous devez également modifier les `rules` du job CI/CD `semgrep-sast` afin que le job s'exécute lorsque les fichiers concernés sont modifiés.

#### Analyser une application Rust {#scan-a-rust-application}

Prérequis :

- Le rôle Developer, Maintainer ou Owner pour le projet.

Pour analyser une application Rust, effectuez ces étapes :

1. Fournissez un ensemble de règles personnalisé pour Rust. Créez un fichier nommé `sast-ruleset.toml` dans un répertoire `.gitlab/` à la racine de votre dépôt.

   L'exemple suivant utilise l'ensemble de règles par défaut du registre Semgrep pour Rust :

   ```toml
   [semgrep]
     description = "Rust ruleset for Semgrep"
     targetdir = "/sgrules"
     timeout = 60

     [[semgrep.passthrough]]
       type  = "url"
       value = "https://semgrep.dev/c/p/rust"
       target = "rust.yml"
   ```

   Pour plus de détails, voir [Remplacer ou compléter les règles prédéfinies](customize_rulesets.md#replace-or-add-to-the-default-rules).
1. Remplacez le job `semgrep-sast` pour ajouter une règle qui détecte les fichiers Rust (`.rs`).

   Définissez ce qui suit dans le fichier `.gitlab-ci.yml` :

   ```yaml
   include:
     - template: Jobs/SAST.gitlab-ci.yml

   semgrep-sast:
     rules:
       - if: $CI_COMMIT_BRANCH
         exists:
           - '**/*.rs'
           # include any other file extensions you need to scan from the semgrep-sast template: Jobs/SAST.gitlab-ci.yml
   ```

### Prise en charge de JDK21 pour l'analyseur SpotBugs {#jdk21-support-for-spotbugs-analyzer}

La version `6` de l'analyseur SpotBugs ajoute la prise en charge de JDK21 et supprime JDK11. La version par défaut reste à `5` comme indiqué dans le [ticket 517169](https://gitlab.com/gitlab-org/gitlab/-/issues/517169).

Pour utiliser la version `6`, épinglez la version de l'analyseur. Pour plus de détails, voir [épingler la version de l'image de l'analyseur](#pin-analyzer-image-version).

```yaml
spotbugs-sast:
  variables:
    SAST_ANALYZER_IMAGE_TAG: "6"
```

### Utilisation de la précompilation avec l'analyseur SpotBugs {#using-pre-compilation-with-spotbugs-analyzer}

L'analyseur basé sur SpotBugs analyse le bytecode compilé pour les projets Groovy. Par défaut, il tente automatiquement de récupérer les dépendances et de compiler votre code afin qu'il puisse être analysé.

La compilation automatique peut échouer si :

- Votre projet nécessite des configurations de build personnalisées.
- Vous utilisez des versions de langage qui ne sont pas intégrées dans l'analyseur.

Pour résoudre ces problèmes, ignorez l'étape de compilation de l'analyseur et fournissez directement des artefacts d'une étape antérieure de votre pipeline. Cette stratégie est appelée précompilation.

#### Partager des artefacts précompilés {#share-pre-compiled-artifacts}

Prérequis :

- Le rôle Developer, Maintainer ou Owner pour le projet.

Pour partager des artefacts précompilés, apportez les modifications suivantes au fichier `.gitlab-ci.yml` de votre projet :

1. Utilisez un job de compilation (généralement nommé `build`) pour compiler votre projet et stocker la sortie compilée en tant que `job artifact` en utilisant la variable CI/CD `artifacts: paths`.

   - Pour les projets Maven, le dossier de sortie est généralement le répertoire `target`.
   - Pour les projets Gradle, il s'agit généralement du répertoire `build`.
   - Si votre projet utilise un emplacement de sortie personnalisé, définissez le chemin des artefacts en conséquence.

1. Désactivez la compilation automatique en définissant la variable CI/CD `COMPILE: "false"` dans le job `spotbugs-sast`.
1. Assurez-vous que le job `spotbugs-sast` dépend du job de compilation en définissant le mot-clé `dependencies`. Cela permet au job `spotbugs-sast` de télécharger et d'utiliser les artefacts créés dans le job de compilation.

L'exemple suivant précompile un projet Gradle et fournit le bytecode compilé à l'analyseur :

```yaml
stages:
  - build
  - test

include:
  - template: Jobs/SAST.gitlab-ci.yml

build:
  image: gradle:7.6-jdk8
  stage: build
  script:
    - gradle build
  artifacts:
    paths:
      - build/

spotbugs-sast:
  dependencies:
    - build
  variables:
    COMPILE: "false"
    SECURE_LOG_LEVEL: debug
```

### Spécifier les dépendances (Maven uniquement) {#specify-dependencies-maven-only}

Prérequis :

- Le rôle Developer, Maintainer ou Owner pour le projet.

Si votre projet nécessite que des dépendances externes soient reconnues par l'analyseur et que vous utilisez Maven, vous pouvez spécifier l'emplacement du dépôt local en utilisant la variable `MAVEN_REPO_PATH`.

La spécification des dépendances est uniquement prise en charge pour les projets basés sur Maven. Les autres outils de build (par exemple, Gradle) ne disposent pas d'un mécanisme équivalent pour spécifier les dépendances. Dans ce cas, assurez-vous que vos artefacts compilés incluent toutes les dépendances nécessaires.

Pour spécifier les dépendances Maven, apportez les modifications suivantes au fichier `.gitlab-ci.yml` de votre projet :

1. Définissez la variable `MAVEN_REPO_PATH` pour pointer vers votre dépôt Maven local.
1. Assurez-vous que votre job de build crée le dépôt à ce chemin (par exemple, en exécutant `mvn package
   -Dmaven.repo.local=./.m2/repository`).
1. Configurez le job `spotbugs-sast` pour qu'il dépende de votre job de build et désactivez la compilation.

L'exemple suivant précompile un projet Maven et fournit le bytecode compilé ainsi que les dépendances à l'analyseur :

```yaml
stages:
  - build
  - test

include:
  - template: Jobs/SAST.gitlab-ci.yml

build:
  image: maven:3.6-jdk-8-slim
  stage: build
  script:
    - mvn package -Dmaven.repo.local=./.m2/repository
  artifacts:
    paths:
      - .m2/
      - target/

spotbugs-sast:
  dependencies:
    - build
  variables:
    MAVEN_REPO_PATH: $CI_PROJECT_DIR/.m2/repository
    COMPILE: "false"
    SECURE_LOG_LEVEL: debug
```

L'analyseur reconnaît désormais les dépendances de votre projet lors de l'analyse.

### Variables CI/CD disponibles {#available-cicd-variables}

Le SAST peut être configuré en utilisant le paramètre `variables` dans `.gitlab-ci.yml`.

Lorsque le modèle GitLab SAST est utilisé, toutes les variables CI/CD de configuration SAST standard et les [variables personnalisées](../../../ci/variables/_index.md#define-a-cicd-variable-in-the-ui) sont propagées aux images d'analyseur SAST sous-jacentes.

> [!warning]
> Toute personnalisation des outils d'analyse de sécurité GitLab doit être testée dans une merge request avant de fusionner ces modifications dans la branche par défaut. Ne pas le faire peut donner des résultats inattendus, y compris un grand nombre de faux positifs.

L'exemple suivant inclut le modèle SAST pour remplacer la variable `SEARCH_MAX_DEPTH` par `10` dans tous les jobs. Le modèle est évalué avant la configuration du pipeline, donc la dernière mention de la variable a la priorité.

```yaml
include:
  - template: Jobs/SAST.gitlab-ci.yml

variables:
  SEARCH_MAX_DEPTH: 10
```

#### Autorité de certification personnalisée {#custom-certificate-authority}

La prise en charge d'une autorité de certification (CA) personnalisée a été introduite dans les versions d'analyseur suivantes.

| Analyseur   | Version                                                                                        |
|------------|------------------------------------------------------------------------------------------------|
| `kubesec`  | [v2.1.0](https://gitlab.com/gitlab-org/security-products/analyzers/kubesec/-/releases/v2.1.0)  |
| `pmd-apex` | [v2.1.0](https://gitlab.com/gitlab-org/security-products/analyzers/pmd-apex/-/releases/v2.1.0) |
| `semgrep`  | [v0.0.1](https://gitlab.com/gitlab-org/security-products/analyzers/semgrep/-/releases/v0.0.1)  |
| `sobelow`  | [v2.2.0](https://gitlab.com/gitlab-org/security-products/analyzers/sobelow/-/releases/v2.2.0)  |
| `spotbugs` | [v2.7.1](https://gitlab.com/gitlab-org/security-products/analyzers/spotbugs/-/releases/v2.7.1) |

##### Utiliser une autorité de certification personnalisée {#use-a-custom-certificate-authority}

Prérequis :

- Le rôle Maintainer ou Developer pour le projet.
- [Représentation textuelle du certificat de clé publique X.509 PEM](https://www.rfc-editor.org/rfc/rfc7468#section-5.1).

  Vous pouvez fournir le certificat par l'une des méthodes suivantes :

  - Ajoutez le certificat directement dans le fichier `.gitlab-ci.yml` de votre projet.
  - Créez une variable CI/CD de type `file` qui fournit le chemin vers le certificat.
  - Configurez une [variable personnalisée dans l'interface utilisateur](../../../ci/variables/_index.md#for-a-project) qui contient la représentation textuelle du certificat.

Pour approuver un certificat CA personnalisé :

- Définissez la variable `ADDITIONAL_CA_CERT_BUNDLE` sur le bundle de certificats CA que vous souhaitez approuver dans l'environnement SAST.

Par exemple, pour configurer cette valeur dans le fichier `.gitlab-ci.yml` de votre projet, utilisez ce qui suit :

```yaml
variables:
  ADDITIONAL_CA_CERT_BUNDLE: |
      -----BEGIN CERTIFICATE-----
      MIIGqTCCBJGgAwIBAgIQI7AVxxVwg2kch4d56XNdDjANBgkqhkiG9w0BAQsFADCB
      ...
      jWgmPqF3vUbZE0EyScetPJquRFRKIesyJuBFMAs=
      -----END CERTIFICATE-----
```

#### Images Docker {#docker-images}

Les éléments suivants sont des variables CI/CD liées aux images Docker.

| Variable CI/CD            | Description                                                                                                                                                   |
|---------------------------|---------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `SECURE_ANALYZERS_PREFIX` | Remplace le nom du registre Docker fournissant les images par défaut (proxy). Pour plus de détails, voir [personnalisation des analyseurs](analyzers.md).                   |
| `SAST_EXCLUDED_ANALYZERS` | Noms des images par défaut qui ne doivent jamais s'exécuter. Pour plus de détails, voir [personnaliser les analyseurs](analyzers.md).                                                     |
| `SAST_ANALYZER_IMAGE_TAG` | Remplace la version par défaut de l'image de l'analyseur. Pour plus de détails, voir [épingler la version de l'image de l'analyseur](#pin-analyzer-image-version).                          |
| `SAST_IMAGE_SUFFIX`       | Suffixe ajouté au nom de l'image. Si défini sur `-fips`, les images `FIPS-enabled` sont utilisées pour l'analyse. Voir [les images compatibles FIPS](#fips-enabled-images) pour plus de détails. |

#### Filtres de vulnérabilités {#vulnerability-filters}

Le SAST peut être configuré pour exclure du code en fonction des chemins de fichiers et de la profondeur de recherche. Les variables CI/CD suivantes contrôlent quels fichiers sont analysés et dans quelle mesure l'analyseur recherche dans votre base de code.

<table class="sast-table">
  <thead>
    <tr>
      <th>Variable CI/CD</th>
      <th>Description</th>
      <th>Valeur par défaut</th>
      <th>Analyseur</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td rowspan="3">
        <code>SAST_EXCLUDED_PATHS</code>
      </td>
      <td rowspan="3">
        Liste séparée par des virgules de chemins pour l'exclusion des vulnérabilités. La gestion exacte de cette variable dépend de l'analyseur utilisé.<sup><b><a href="#sast-excluded-paths-description">1</a></b></sup>
      </td>
      <td rowspan="3">
        <code> <a href="https://gitlab.com/gitlab-org/gitlab/blob/v17.3.0-ee/lib/gitlab/ci/templates/Jobs/SAST.gitlab-ci.yml#L13">spec, test, tests, tmp</a> </code>
      </td>
      <td>
        <a href="https://gitlab.com/gitlab-org/security-products/analyzers/semgrep">Semgrep</a><sup><b><a href="#sast-excluded-paths-semgrep">2</a></b>,</sup><sup><b><a href="#sast-excluded-paths-all-other-sast-analyzers">3</a></b></sup>
      </td>
    </tr>
    <tr>
      <td>
        <a href="https://docs.gitlab.com/user/application_security/sast/gitlab_advanced_sast/">GitLab Advanced SAST</a><sup><b><a href="#sast-excluded-paths-semgrep">2</a></b>,</sup><sup><b><a href="#sast-excluded-paths-all-other-sast-analyzers">3</a></b></sup>
      </td>
    </tr>
    <tr>
      <td>
        Tous les autres analyseurs SAST<sup><b><a href="#sast-excluded-paths-all-other-sast-analyzers">3</a></b></sup>
      </td>
    </tr>
    <tr>
      <td>
        <code>SAST_SEMGREP_EXCLUDED_PATHS</code>
      </td>
      <td>
        Liste de chemins séparés par des virgules qui sont exclus spécifiquement pour l'analyseur Semgrep lorsque l'analyseur GitLab Advanced SAST s'exécute en même temps. Cela évite les doublons de vulnérabilités en excluant les fichiers déjà analysés par GitLab Advanced SAST. Cette liste est fusionnée avec <code>SAST_EXCLUDED_PATHS</code>.
      </td>
      <td>Aucune</td>
      <td>
        <a href="https://gitlab.com/gitlab-org/security-products/analyzers/semgrep">Semgrep</a>
      </td>
    </tr>
    <tr>
      <td>
        <!-- markdownlint-disable MD044 --> <code>SAST_SPOTBUGS_EXCLUDED_BUILD_PATHS</code> <!-- markdownlint-enable MD044 -->
      </td>
      <td>
        Liste de chemins séparés par des virgules permettant d'exclure des répertoires de la compilation et de l'analyse.
      </td>
      <td>Aucune</td>
      <td>
        <a href="https://gitlab.com/gitlab-org/security-products/analyzers/spotbugs">SpotBugs</a><sup><b><a href="#sast-spotbugs-excluded-build-paths-description">4</a></b></sup>
      </td>
    </tr>
    <tr>
      <td rowspan="3">
        <code>SEARCH_MAX_DEPTH</code>
      </td>
      <td rowspan="3">
        Nombre de niveaux de répertoires dans lesquels l'analyseur descend lors de la recherche de fichiers correspondants à analyser.<sup><b><a href="#search-max-depth-description">5</a></b></sup>
      </td>
      <td rowspan="2">
        <code> <a href="https://gitlab.com/gitlab-org/gitlab/-/blob/v17.3.0-ee/lib/gitlab/ci/templates/Jobs/SAST.gitlab-ci.yml#L54">20</a> </code>
      </td>
      <td>
        <a href="https://gitlab.com/gitlab-org/security-products/analyzers/semgrep">Semgrep</a>
      </td>
    </tr>
    <tr>
      <td>
        <a href="https://docs.gitlab.com/user/application_security/sast/gitlab_advanced_sast/">GitLab Advanced SAST</a>
      </td>
    </tr>
    <tr>
      <td>
        <code> <a href="https://gitlab.com/gitlab-org/gitlab/blob/v17.3.0-ee/lib/gitlab/ci/templates/Jobs/SAST.gitlab-ci.yml#L26">4</a> </code>
      </td>
      <td>
        Tous les autres analyseurs SAST
      </td>
    </tr>
  </tbody>
</table>

**Footnotes** :

1. <a id="sast-excluded-paths-description"></a>Il peut être nécessaire d'exclure les répertoires temporaires utilisés par votre outil de compilation, car ceux-ci peuvent générer des faux positifs. Pour exclure des chemins, copiez et collez les chemins exclus par défaut, puis **ajoutez** vos propres chemins à exclure. Si vous ne spécifiez pas les chemins exclus par défaut, les valeurs par défaut sont remplacées et seuls les chemins que vous spécifiez sont exclus des analyses SAST.
1. <a id="sast-excluded-paths-semgrep"></a>Pour ces analyseurs, `SAST_EXCLUDED_PATHS` est implémenté comme un **pré-filtre**, appliqué avant l'exécution de l'analyse.

   L'analyseur ignore tout fichier ou répertoire dont le chemin correspond à l'un des modèles séparés par des virgules.

   Par exemple, si `SAST_EXCLUDED_PATHS` est défini sur `*.py,tests` :

   - `*.py` ignore les éléments suivants :
     - `foo.py`
     - `src/foo.py`
     - `foo.py/bar.sh`
   - `tests` ignore :
     - `tests/foo.py`
     - `a/b/tests/c/foo.py`

   Chaque modèle est un modèle de type glob qui utilise la même syntaxe que [gitignore](https://git-scm.com/docs/gitignore#_pattern_format).
1. <a id="sast-excluded-paths-all-other-sast-analyzers"></a>Pour ces analyseurs, `SAST_EXCLUDED_PATHS` est implémenté comme un **post-filtre**, appliqué après l'exécution de l'analyse.

   Les modèles peuvent être des globs (voir [`doublestar.Match`](https://pkg.go.dev/github.com/bmatcuk/doublestar/v4@v4.0.2#Match) pour les modèles pris en charge), ou des chemins de fichiers ou de dossiers (par exemple, `doc,spec`). Les répertoires parents correspondent également aux modèles.

   L'implémentation en post-filtre de `SAST_EXCLUDED_PATHS` est disponible pour tous les analyseurs SAST. Certains analyseurs SAST, tels que ceux avec [l'exposant `2`](#sast-excluded-paths-semgrep), implémentent `SAST_EXCLUDED_PATHS` à la fois comme pré-filtre et post-filtre. Un pré-filtre est plus efficace car il réduit le nombre de fichiers à analyser.

   Pour les analyseurs qui prennent en charge `SAST_EXCLUDED_PATHS` à la fois comme pré-filtre et post-filtre, le pré-filtre est appliqué en premier, puis le post-filtre est appliqué aux vulnérabilités restantes.
1. <a id="sast-spotbugs-excluded-build-paths-description"></a> Pour cette variable, les modèles de chemins peuvent être des globs (voir [`doublestar.Match`](https://pkg.go.dev/github.com/bmatcuk/doublestar/v4@v4.0.2#Match) pour les modèles pris en charge). Les répertoires sont exclus du processus de compilation si le modèle de chemin correspond à un fichier de compilation pris en charge :

   - `build.sbt`
   - `grailsw`
   - `gradlew`
   - `build.gradle`
   - `mvnw`
   - `pom.xml`
   - `build.xml`

   Par exemple, pour exclure la compilation et l'analyse d'un projet `maven` contenant un fichier de compilation avec le chemin `project/subdir/pom.xml`, passez un modèle glob qui correspond explicitement au fichier de compilation, comme `project/*/*.xml` ou `**/*.xml`, ou une correspondance exacte telle que `project/subdir/pom.xml`.

   Passer un répertoire parent comme modèle, tel que `project` ou `project/subdir`, n'exclut pas le répertoire de la compilation, car dans ce cas, le fichier de compilation n'est pas explicitement mis en correspondance avec le modèle.
1. <a id="search-max-depth-description"></a>Le [modèle CI/CD SAST](https://gitlab.com/gitlab-org/gitlab/blob/v17.4.1-ee/lib/gitlab/ci/templates/Jobs/SAST.gitlab-ci.yml) parcourt le dépôt pour détecter les langages de programmation utilisés et sélectionne les analyseurs correspondants. Ensuite, chaque analyseur parcourt la base de code pour trouver les fichiers ou répertoires spécifiques à analyser. Définissez la valeur de `SEARCH_MAX_DEPTH` pour spécifier le nombre de niveaux de répertoires que la phase de recherche de l'analyseur doit parcourir.

#### Paramètres de l'analyseur {#analyzer-settings}

Certains analyseurs peuvent être personnalisés à l'aide de variables CI/CD.

| Variable CI/CD                      | Analyseur             | Valeur par défaut                                  | Description |
|-------------------------------------|----------------------|------------------------------------------|-------------|
| `GITLAB_ADVANCED_SAST_ENABLED`      | GitLab Advanced SAST | `false`                                  | Définissez sur `true` pour activer l'analyse GitLab Advanced SAST (disponible dans GitLab Ultimate uniquement). |
| `SCAN_KUBERNETES_MANIFESTS`         | Kubesec              | `"false"`                                | Définissez sur `"true"` pour analyser les manifestes Kubernetes. |
| `KUBESEC_HELM_CHARTS_PATH`          | Kubesec              |                                          | Chemin facultatif vers les charts Helm que `helm` utilise pour générer un manifeste Kubernetes que `kubesec` analyse. Si des dépendances sont définies, `helm dependency build` doit être exécuté dans un `before_script` pour récupérer les dépendances nécessaires. |
| `KUBESEC_HELM_OPTIONS`              | Kubesec              |                                          | Arguments supplémentaires pour l'exécutable `helm`. |
| `COMPILE`                           | SpotBugs             | `true`                                   | Définissez sur `false` pour désactiver la compilation du projet et la récupération des dépendances. |
| `ANT_HOME`                          | SpotBugs             |                                          | La variable `ANT_HOME`. |
| `ANT_PATH`                          | SpotBugs             | `ant`                                    | Chemin vers l'exécutable `ant`. |
| `GRADLE_PATH`                       | SpotBugs             | `gradle`                                 | Chemin vers l'exécutable `gradle`. |
| `JAVA_OPTS`                         | SpotBugs             | `-XX:MaxRAMPercentage=80`                | Arguments supplémentaires pour l'exécutable `java`. |
| `JAVA_PATH`                         | SpotBugs             | `java`                                   | Chemin vers l'exécutable `java`. |
| `SAST_JAVA_VERSION`                 | SpotBugs             | `17`                                     | Version Java utilisée. Les versions prises en charge sont `17` et `11`. |
| `MAVEN_CLI_OPTS`                    | SpotBugs             | `--batch-mode -DskipTests=true`          | Arguments supplémentaires pour l'exécutable `mvn` ou `mvnw`. |
| `MAVEN_PATH`                        | SpotBugs             | `mvn`                                    | Chemin vers l'exécutable `mvn`. |
| `MAVEN_REPO_PATH`                   | SpotBugs             | `$HOME/.m2/repository`                   | Chemin vers le dépôt local Maven (raccourci pour la propriété `maven.repo.local`). |
| `SBT_PATH`                          | SpotBugs             | `sbt`                                    | Chemin vers l'exécutable `sbt`. |
| `FAIL_NEVER`                        | SpotBugs             | `false`                                  | Définissez sur `true` ou `1` pour ignorer les échecs de compilation. |
| `SAST_SEMGREP_METRICS`              | Semgrep              | `true`                                   | Définissez sur `false` pour désactiver l'envoi de métriques d'analyse anonymisées à `r2c`. |
| `SAST_SCANNER_ALLOWED_CLI_OPTS`     | Semgrep              | `--max-target-bytes=1000000 --timeout=5` | Options CLI (arguments avec valeur ou indicateurs) transmises au scanner de sécurité sous-jacent lors de l'exécution d'une opération d'analyse. Seul un ensemble limité d'[options](#security-scanner-configuration) est accepté. Séparez une option CLI et sa valeur en utilisant soit un espace vide, soit le caractère égal (`=`). Par exemple : `name1 value1` ou `name1=value1`. Les options multiples doivent être séparées par des espaces vides. Par exemple : `name1 value1 name2 value2`. |
| `SAST_RULESET_GIT_REFERENCE`        | Tous                  |                                          | Définit un chemin vers une configuration d'ensemble de règles personnalisée. Si un projet possède un fichier `.gitlab/sast-ruleset.toml` validé, cette configuration locale est prioritaire et le fichier provenant de `SAST_RULESET_GIT_REFERENCE` n'est pas utilisé. Cette variable est disponible uniquement pour le niveau Ultimate. |
| `SECURE_ENABLE_LOCAL_CONFIGURATION` | Tous                  | `false`                                  | Active l'option d'utilisation d'une configuration d'ensemble de règles personnalisée. Si `SECURE_ENABLE_LOCAL_CONFIGURATION` est défini sur `false`, le fichier de configuration d'ensemble de règles personnalisé du projet situé à `.gitlab/sast-ruleset.toml` est ignoré et le fichier provenant de `SAST_RULESET_GIT_REFERENCE` ou la configuration par défaut est prioritaire. |

#### Configuration du scanner de sécurité {#security-scanner-configuration}

Les analyseurs SAST utilisent en interne des scanners de sécurité OSS pour effectuer l'analyse. GitLab définit la configuration recommandée pour le scanner de sécurité afin que vous n'ayez pas à vous soucier de les paramétrer. Cependant, il peut exister de rares cas où notre configuration de scanner par défaut ne convient pas à vos besoins.

Pour permettre une certaine personnalisation du comportement du scanner, vous pouvez ajouter un ensemble limité d'indicateurs au scanner sous-jacent. Spécifiez les indicateurs dans la variable CI/CD `SAST_SCANNER_ALLOWED_CLI_OPTS`. Ces indicateurs sont ajoutés aux options CLI du scanner.

<table class="sast-table">
  <thead>
    <tr>
      <th>Analyseur</th>
      <th>Option CLI</th>
      <th>Description</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td rowspan="2">
        GitLab Advanced SAST
      </td>
      <td>
        <code>--include-propagator-files</code>
      </td>
      <td>
        AVERTISSEMENT :  Cet indicateur peut entraîner une dégradation significative des performances. <br> Cette option permet l'analyse des fichiers intermédiaires qui relient les fichiers source et cible sans contenir ni sources ni cibles eux-mêmes. Bien qu'utile pour une analyse complète dans les petits dépôts, l'activation de cette fonctionnalité pour les grands dépôts aura un impact substantiel sur les performances.
      </td>
    </tr>
    <tr>
      <td>
        <code>--multi-core</code>
      </td>
      <td>
        L'analyse multi-cœur est activée par défaut, avec détection automatique des cœurs CPU disponibles (plafonnée à 4 sur les runners auto-hébergés). Remplacez avec <code>--multi-core </code> (par exemple, <code>--multi-core 12</code>). L'exécution multi-cœur nécessite proportionnellement plus de mémoire. Vous devriez allouer 4 Go par cœur. Pour désactiver, définissez <code>DISABLE_MULTI_CORE</code>. Dépasser les ressources disponibles peut causer des problèmes de performances.
      </td>
    </tr>
    <tr>
      <td rowspan="3">
        <a href="https://gitlab.com/gitlab-org/security-products/analyzers/semgrep">Semgrep</a>
      </td>
      <td>
        <code>--max-memory</code>
      </td>
      <td>
        Définit la mémoire système maximale en Mo à utiliser lors de l'exécution d'une règle sur un seul fichier.
      </td>
    </tr>
    <tr>
      <td>
        <code>--max-target-bytes</code>
      </td>
      <td>
        <p>
          Taille maximale d'un fichier à analyser. Tout programme d'entrée dépassant cette taille est ignoré. Définissez sur <code>0</code> ou une valeur négative pour désactiver ce filtre. Les octets peuvent être spécifiés avec ou sans unité de mesure, par exemple :  <code>12.5kb</code>, <code>1.5MB</code> ou <code>123</code>. La valeur par défaut est <code>1000000</code> octets.
        </p>
        <p>
          <b>Remarque :</b> Vous devriez conserver cet indicateur défini sur la valeur par défaut. De plus, évitez de modifier cet indicateur pour analyser du JavaScript minifié, ce qui est peu susceptible de fonctionner correctement, des <code>DLL</code>, des <code>JAR</code> ou d'autres fichiers binaires, car les fichiers binaires ne sont pas analysés.
        </p>
      </td>
    </tr>
    <tr>
      <td>
        <code>--timeout</code>
      </td>
      <td>
        Durée maximale en secondes à consacrer à l'exécution d'une règle sur un seul fichier. Définissez sur <code>0</code> pour ne pas avoir de limite de temps. La valeur du délai d'expiration doit être un entier, par exemple :  <code>10</code> ou <code>15</code>. La valeur par défaut est <code>5</code>.
      </td>
    </tr>
    <tr>
      <td>
        <a href="https://gitlab.com/gitlab-org/security-products/analyzers/spotbugs">SpotBugs</a>
      </td>
      <td>
        <code>-effort</code>
      </td>
      <td>
        Définit le niveau d'effort d'analyse. Les valeurs valides sont, par ordre croissant de précision et de capacité à détecter davantage de vulnérabilités : <code>min</code>, <code>less</code>, <code>more</code> et <code>max</code>. La valeur par défaut est <code>max</code>, ce qui peut nécessiter plus de mémoire et de temps pour terminer l'analyse, selon la taille du projet. Si vous rencontrez des problèmes de mémoire ou de performances, vous pouvez réduire le niveau d'effort d'analyse à une valeur inférieure. Par exemple : <code>-effort less</code>.
      </td>
    </tr>
  </tbody>
</table>

### Exclure du code de l'analyse {#exclude-code-from-analysis}

Vous pouvez marquer des lignes individuelles, ou des blocs, de code pour les exclure de l'analyse des vulnérabilités. Vous devriez gérer toutes les vulnérabilités via la gestion des vulnérabilités, ou ajuster les chemins de fichiers analysés à l'aide de `SAST_EXCLUDED_PATHS` avant d'utiliser cette méthode d'annotation commentaire finding par finding.

Lors de l'utilisation de l'analyseur basé sur Semgrep, les options suivantes sont également disponibles :

- Ignorer une ligne de code - ajoutez le commentaire `// nosemgrep:` à la fin de la ligne (le préfixe est selon le langage de développement).

  Exemple Java :

  ```java
  vuln_func(); // nosemgrep
  ```

  Exemple Python :

  ```python
  vuln_func(); # nosemgrep
  ```

- Ignorer une ligne de code pour une règle spécifique - ajoutez le commentaire `// nosemgrep: RULE_ID` à la fin de la ligne (le préfixe est selon le langage de développement).
- Le commentaire `//nosemgrep` peut également être ajouté à la ligne précédant immédiatement la détection. Aucune autre ligne (y compris les autres commentaires) ne doit se trouver entre le commentaire d'exclusion et le code détecté.
- Ignorer un fichier ou un répertoire - créez un fichier `.semgrepignore` dans le répertoire racine de votre dépôt ou le répertoire de travail de votre projet et ajoutez-y des modèles pour les fichiers et les dossiers. L'analyseur GitLab Semgrep fusionne automatiquement votre fichier `.semgrepignore` personnalisé avec les [modèles d'exclusion intégrés de GitLab](https://gitlab.com/gitlab-org/security-products/analyzers/semgrep/-/blob/abcea7419961320f9718a2f24fe438cc1a7f8e08/semgrepignore).

> [!note]
> L'analyseur Semgrep ne respecte pas les fichiers `.gitignore`. Les fichiers répertoriés dans `.gitignore` sont analysés sauf s'ils sont explicitement exclus en utilisant `.semgrepignore` ou `SAST_EXCLUDED_PATHS`.

Pour plus de détails, consultez la [documentation Semgrep](https://semgrep.dev/docs/ignoring-files-folders-code).

## Exécuter SAST dans un environnement hors ligne {#running-sast-in-an-offline-environment}

{{< details >}}

- Niveau :  Free, Premium, Ultimate
- Offre :  GitLab Self-Managed

{{< /details >}}

Pour les instances dans un environnement avec un accès limité, restreint ou intermittent aux ressources externes via Internet, certains ajustements sont nécessaires pour que le job SAST s'exécute correctement. Pour plus d'informations, consultez [Environnements hors ligne](../offline_deployments/_index.md).

### Prérequis pour SAST hors ligne {#requirements-for-offline-sast}

Pour utiliser SAST dans un environnement hors ligne, vous avez besoin de :

- GitLab Runner avec l'exécuteur [`docker`](https://docs.gitlab.com/runner/executors/docker/) ou [`kubernetes`](https://docs.gitlab.com/runner/install/kubernetes/). Consultez les [prérequis](#getting-started) pour plus de détails.
- Un registre de conteneurs Docker avec des copies disponibles localement des images d'[analyseurs](https://gitlab.com/gitlab-org/security-products/analyzers) SAST.
- Configurer la vérification des certificats des paquets (facultatif).

GitLab Runner a une [valeur par défaut de `pull_policy` égale à `always`](https://docs.gitlab.com/runner/executors/docker/#using-the-always-pull-policy), ce qui signifie que le runner tente de télécharger des images Docker depuis le registre de conteneurs GitLab même si une copie locale est disponible. Le [`pull_policy` de GitLab Runner peut être défini sur `if-not-present`](https://docs.gitlab.com/runner/executors/docker/#using-the-if-not-present-pull-policy) dans un environnement hors ligne si vous préférez utiliser uniquement les images Docker disponibles localement. Cependant, conservez le paramètre de politique de téléchargement sur `always` si vous n'êtes pas dans un environnement hors ligne. Ce paramètre permet l'utilisation de scanners mis à jour dans vos pipelines CI/CD.

### Rendre les images d'analyseurs GitLab SAST disponibles dans votre registre de conteneurs Docker {#make-gitlab-sast-analyzer-images-available-inside-your-docker-registry}

Pour le SAST avec tous les langages et frameworks pris en charge, importez les images d'analyseurs SAST par défaut suivantes depuis `registry.gitlab.com` dans votre [registre de conteneurs Docker local](../../packages/container_registry/_index.md) :

```plaintext
registry.gitlab.com/security-products/gitlab-advanced-sast:2
registry.gitlab.com/security-products/kubesec:6
registry.gitlab.com/security-products/pmd-apex:6
registry.gitlab.com/security-products/semgrep:6
registry.gitlab.com/security-products/sobelow:6
registry.gitlab.com/security-products/spotbugs:5
```

Le processus d'importation des images Docker dans un registre de conteneurs Docker hors ligne local dépend de **votre politique de sécurité réseau**. Consultez votre service informatique pour trouver un processus accepté et approuvé par lequel les ressources externes peuvent être importées ou accessibles temporairement. Ces scanners sont [mis à jour périodiquement](../detect/vulnerability_scanner_maintenance.md) avec de nouvelles définitions, et vous pourrez peut-être effectuer des mises à jour occasionnelles par vous-même.

Pour plus de détails sur la sauvegarde et le transport des images Docker sous forme de fichier, consultez la documentation Docker sur :

- `docker save`
- `docker load`
- `docker export`
- `docker import`

### Utiliser des analyseurs SAST locaux {#use-local-sast-analyzers}

Prérequis :

- Le rôle Developer, Maintainer ou Owner pour le projet.

Pour utiliser des analyseurs SAST locaux :

- Dans le fichier `.gitlab-ci.yml` de votre projet, définissez la variable CI/CD `SECURE_ANALYZERS_PREFIX` pour pointer vers votre registre de conteneurs Docker local.

Par exemple :

```yaml
variables:
  SECURE_ANALYZERS_PREFIX: "localhost:5000/analyzers"
```

Le job SAST devrait maintenant utiliser des copies locales des analyseurs SAST pour analyser votre code et générer des rapports de sécurité sans nécessiter d'accès Internet.

### Configurer la vérification des certificats des paquets {#configure-certificate-checking-of-packages}

Si un job SAST invoque un gestionnaire de paquets, vous devez configurer sa vérification des certificats. Dans un environnement hors ligne, la vérification des certificats avec une source externe n'est pas possible. Utilisez soit un certificat auto-signé, soit désactivez la vérification des certificats. Consultez la documentation du gestionnaire de paquets pour obtenir des instructions.

## Exécuter SAST sous SELinux {#running-sast-in-selinux}

Par défaut, les analyseurs SAST sont pris en charge dans les instances GitLab hébergées sur SELinux. L'ajout d'un `before_script` dans un [job SAST remplacé](#override-sast-jobs) peut ne pas fonctionner car les runners hébergés sur SELinux ont des permissions restreintes.
