---
stage: Application Security Testing
group: Composition Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: "Migration vers l'analyse des dépendances à l'aide de SBOM"
---

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- La fonctionnalité d'analyse des dépendances basée sur l'analyseur Gemnasium est obsolète dans GitLab 17.9 et sa suppression est proposée dans GitLab 20.0. Cependant, le calendrier de suppression n'est pas finalisé et vous pouvez continuer à utiliser Gemnasium selon vos besoins.

{{< /history >}}

La fonctionnalité d'analyse des dépendances est en cours de mise à niveau vers le scanner de vulnérabilités SBOM de GitLab. Dans le cadre de ce changement, la fonctionnalité [analyse des dépendances à l'aide de SBOM](dependency_scanning_sbom/_index.md) et le [nouvel analyseur d'analyse des dépendances](https://gitlab.com/gitlab-org/security-products/analyzers/dependency-scanning) remplacent la fonctionnalité d'analyse des dépendances héritée basée sur l'[analyseur Gemnasium](https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium). Cependant, les projets existants ne sont pas migrés automatiquement en raison des changements significatifs introduits lors de cette transition.

Suivez ce guide de migration si vous utilisez l'analyse des dépendances GitLab et que l'une des conditions suivantes s'applique :

- Les jobs CI/CD d'analyse des dépendances sont configurés en incluant l'un des modèles CI/CD d'analyse des dépendances.

  ```yaml
    include:
      - template: Jobs/Dependency-Scanning.gitlab-ci.yml
      - template: Jobs/Dependency-Scanning.latest.gitlab-ci.yml
  ```

- Les jobs CI/CD d'analyse des dépendances sont configurés à l'aide des [politiques d'exécution de scan](../policies/scan_execution_policies.md).
- Les jobs CI/CD d'analyse des dépendances sont configurés à l'aide des [politiques d'exécution de pipeline](../policies/pipeline_execution_policies.md).

## Préparer la migration {#prepare-for-migration}

Évaluez votre effort de migration, identifiez votre chemin, vérifiez les prérequis et déterminez quels projets sont concernés.

### Estimer l'effort de migration {#estimate-migration-effort}

L'[outil d'évaluation de la migration d'analyse des dépendances](https://dependency-scanning-migration-evaluator-cb84d1.gitlab.io/) génère une liste de contrôle de migration personnalisée en fonction de la façon dont l'analyse des dépendances est configurée dans vos projets. Il interroge sur votre chemin d'activation, les écosystèmes de langages, les personnalisations CI/CD et (pour les instances self-managed) le statut de synchronisation de la base de données de métadonnées de paquets. L'outil d'évaluation produit :

- Une estimation de l'effort (minimal, modéré, significatif ou complexe)
- Une liste de contrôle des étapes de migration qui s'appliquent à votre configuration, avec des liens directs vers les sections pertinentes de ce guide
- Des signalements pour les situations nécessitant une attention particulière (comme les projets qui doivent passer d'une politique d'exécution de scan à une politique d'exécution de pipeline)

L'outil d'évaluation s'exécute entièrement dans votre navigateur et n'envoie de données nulle part.

### Identifier votre chemin de migration {#identify-your-migration-path}

Les configurations existantes ne sont pas migrées automatiquement. Pour adopter la nouvelle fonctionnalité, vous devez mettre à jour votre configuration.

Utilisez la liste suivante pour trouver le chemin de migration qui vous correspond :

- Modèle stable (`Jobs/Dependency-Scanning.gitlab-ci.yml`) : passez au modèle `v2` en suivant les [étapes de migration génériques](#migrate-to-dependency-scanning-using-sbom), puis appliquez les [instructions spécifiques aux langages](#language-specific-instructions) pour les écosystèmes utilisés dans vos projets.
- Dernier modèle (`Jobs/Dependency-Scanning.latest.gitlab-ci.yml`) : identique au modèle stable. Passez au modèle `v2` en suivant les [étapes de migration génériques](#migrate-to-dependency-scanning-using-sbom), puis appliquez les [instructions spécifiques aux langages](#language-specific-instructions).
- Composant CI/CD : le [composant principal](https://gitlab.com/components/dependency-scanning/-/tree/main/templates/main) utilise déjà le nouvel analyseur, mais les versions plus anciennes (v0 et v1) sont en retard sur la version de l'analyseur et sur les entrées prises en charge. Mettez à jour l'include vers la version `v2` et appliquez les [instructions spécifiques aux langages](#language-specific-instructions). Si vous utilisez un composant spécialisé pour Android, Rust, Swift ou CocoaPods, migrez vers le composant principal.
- Politiques d'exécution de scan (SEP) ou politiques d'exécution de pipeline (PEP) : modifiez la politique pour référencer le modèle `v2`, puis suivez les [étapes de migration génériques](#migrate-to-dependency-scanning-using-sbom) et les [instructions spécifiques aux langages](#language-specific-instructions) pour les projets concernés. Les SEP et PEP sont construites sur la base des modèles CI/CD, de sorte que les modifications du modèle se propagent automatiquement à tous les projets concernés après la mise à jour de la SEP. Pour la PEP, mettez directement à jour la configuration CI/CD de la politique pour référencer le modèle `v2`.

### Vérifier les prérequis : synchronisation de la base de données de métadonnées de paquets {#verify-prerequisites-package-metadata-database-synchronization}

Le nouvel analyseur d'analyse des dépendances nécessite que la [base de données de métadonnées de paquets (PMDB)](../../../administration/settings/security_and_compliance.md#package-metadata-database-synchronization) soit synchronisée pour les types de paquets utilisés par vos projets. Sur GitLab.com, l'instance synchronise déjà les données pour tous les types de paquets pris en charge. Sur GitLab Self-Managed et GitLab Dedicated, un administrateur configure la synchronisation.

Avant de migrer, un administrateur doit :

- Confirmer que la synchronisation PMDB est activée et que les types de paquets utilisés par vos projets sont sélectionnés. Pour plus d'informations, consultez [choisir les métadonnées du registre de paquets à synchroniser](../../../administration/settings/security_and_compliance.md#choose-package-registry-metadata-to-sync).
- Pour les instances hors ligne ou derrière un pare-feu, suivez les instructions pour [activer la base de données de métadonnées de paquets](../../../topics/offline/quick_start_guide.md#enabling-the-package-metadata-database).

Si la synchronisation PMDB n'est pas complète pour un type de paquet utilisé par vos projets, le nouvel analyseur ne peut pas résoudre les avis pour les composants correspondants, et des résultats de sécurité peuvent manquer après la migration.

### Identifier les projets affectés {#identify-affected-projects}

Identifiez les projets qui utilisent la fonctionnalité d'analyse des dépendances héritée. L'[inventaire de sécurité](../security_inventory/_index.md) offre une visibilité sur la couverture des scanners à travers les groupes et les projets. Cette étape est le point de départ recommandé.

Vous pouvez également localiser l'utilisation héritée dans votre configuration CI/CD :

- Inclusions des modèles hérités `Jobs/Dependency-Scanning.gitlab-ci.yml` ou `Jobs/Dependency-Scanning.latest.gitlab-ci.yml` dans les fichiers `.gitlab-ci.yml`.
- Références aux mêmes modèles dans les politiques d'exécution de scan et les politiques d'exécution de pipeline.
- Noms de jobs de l'analyseur hérité (`gemnasium-dependency_scanning`, `gemnasium-maven-dependency_scanning`, `gemnasium-python-dependency_scanning`) dans les fichiers `.gitlab-ci.yml`, le YAML de politique, ou les jobs en aval qui les utilisent dans `needs:` ou `dependencies:`.

## Comprendre les changements {#understand-the-changes}

La transition de l'analyseur Gemnasium vers le nouvel analyseur d'analyse des dépendances est une évolution technique significative. La plupart des projets n'ont pas besoin de modifier quoi que ce soit au-delà du changement de configuration CI/CD décrit dans [migrer vers l'analyse des dépendances à l'aide de SBOM](#migrate-to-dependency-scanning-using-sbom). Les changements décrits dans cette section vous aident à comprendre pourquoi certains projets (notamment Gradle, Maven et Python sans lockfile) nécessitent des étapes supplémentaires.

Changements clés :

- Prise en charge étendue des langages et couverture des fichiers : le nouvel analyseur n'est pas limité aux versions de Python et Java prises en charge par l'analyseur Gemnasium, et bénéficie d'une [couverture des fichiers](https://gitlab.com/gitlab-org/security-products/analyzers/dependency-scanning#supported-files) étendue.
- Performances améliorées : le nouvel analyseur préfère les lockfiles existants ou les exports de graphes de dépendances et n'exécute des [jobs de résolution](dependency_scanning_sbom/_index.md#dependency-resolution) spécifiques à l'écosystème que pour les projets qui en sont dépourvus.
- Surface d'attaque réduite et configuration plus flexible : l'image de l'analyseur ne fait qu'analyser les lockfiles et les exports de graphes. Les paramètres spécifiques à l'écosystème (registres privés, bundles CA personnalisés, options JVM) s'appliquent uniquement au job de résolution des dépendances concerné. Vous pouvez remplacer les images de résolution pour correspondre à votre environnement de build.

### Une nouvelle approche pour l'analyse de sécurité {#a-new-approach-to-security-scanning}

Lors de l'utilisation de la fonctionnalité d'analyse des dépendances héritée, tout le travail d'analyse se déroule dans votre pipeline CI/CD. Lors de l'exécution d'une analyse, l'analyseur Gemnasium gère deux tâches critiques simultanément : il identifie les dépendances de votre projet et effectue immédiatement une analyse de sécurité de ces dépendances en utilisant une copie locale de la base de données d'avis GitLab et son moteur d'analyse de sécurité spécifique. Ensuite, il génère des résultats dans différents rapports (SBOM CycloneDX et rapport de sécurité d'analyse des dépendances).

D'autre part, la fonctionnalité d'analyse des dépendances à l'aide de SBOM repose sur une approche d'analyse des dépendances décomposée qui sépare la détection des dépendances des autres analyses, comme l'accessibilité statique ou l'analyse des vulnérabilités. Bien que ces tâches soient toujours exécutées dans le même job CI/CD, elles fonctionnent comme des composants découplés et réutilisables. Par exemple, l'analyse des vulnérabilités réutilise le moteur unifié, le scanner de vulnérabilités SBOM de GitLab, qui prend également en charge les fonctionnalités d'analyse continue des vulnérabilités de GitLab. Cela ouvre également des opportunités pour de futurs points d'intégration, permettant des workflows d'analyse des vulnérabilités plus flexibles.

En savoir plus sur la façon dont l'analyse des dépendances à l'aide de SBOM [analyse une application](dependency_scanning_sbom/_index.md#how-it-scans-an-application).

### Détection des dépendances pour Gradle, Maven et Python {#dependency-detection-for-gradle-maven-and-python}

Le nouvel analyseur modifie la façon dont les dépendances sont découvertes pour les projets Gradle, Maven et Python. Au lieu de builder votre application pour déterminer les dépendances, l'analyseur utilise un modèle de détection multi-niveaux qui suit le principe « la précision est un curseur » :

1. Lockfile ou export de graphe de dépendances : lorsqu'un fichier pris en charge est commité dans le dépôt ou transmis en tant qu'artefact de job (comme `maven.graph.json`, `dependencies.lock`, `requirements.txt`, `Pipfile.lock`), l'analyseur l'utilise directement. Il s'agit de l'option la plus précise.
1. [Résolution des dépendances](dependency_scanning_sbom/_index.md#dependency-resolution) : lorsqu'aucun fichier pris en charge n'existe pour les projets Maven, Gradle ou Python, l'analyseur tente d'en générer un automatiquement. Les jobs de résolution s'exécutent dans l'étape `.pre` avec des images d'écosystème minimales et des commandes natives (comme `mvn dependency:tree`, `pip-compile`, `gradle dependencies`). Le job `dependency-scanning` utilise les artefacts générés.
1. [Fallback de manifeste](dependency_scanning_sbom/_index.md#manifest-fallback) : lorsqu'aucun lockfile ou fichier de graphe de dépendances n'existe, l'analyseur analyse les fichiers manifestes pris en charge (comme `pom.xml`, `requirements.txt`, `build.gradle`, `build.gradle.kts`) pour extraire uniquement les dépendances directes. Les dépendances transitives ne sont pas détectées et les versions résolues exactes ne peuvent pas être déterminées.

Dans GitLab 19.0 et versions ultérieures, la résolution des dépendances et le fallback de manifeste sont activés par défaut.

Pour des résultats plus précis, commitez un lockfile ou un export de graphe de dépendances dans votre dépôt, ou générez-en un dans un job CI/CD précédent à l'aide de l'environnement de build réel de votre projet. Les sections suivantes décrivent les options disponibles pour chaque langage et gestionnaire de paquets.

### Accéder aux résultats d'analyse {#accessing-scan-results}

Le modèle `v2` produit le même [`gl-dependency-scanning-report.json`](../../../ci/yaml/artifacts_reports.md#artifactsreportsdependency_scanning) artefact de job que le modèle hérité. Les jobs en aval qui consomment cet artefact (avec `needs:` ou `dependencies:`) continuent de fonctionner après la migration, bien que le nom du job producteur change de `gemnasium-dependency_scanning` (et ses variantes Maven et Python) vers `dependency-scanning`.

## Migrer vers l'analyse des dépendances à l'aide de SBOM {#migrate-to-dependency-scanning-using-sbom}

La façon dont vous migrez dépend de la manière dont l'analyse des dépendances est activée dans vos projets. Chaque sous-section couvre les personnalisations à supprimer, les références à mettre à jour et un exemple minimal avant/après.

Pour trouver la sous-section qui vous correspond, consultez [identifier votre chemin de migration](#identify-your-migration-path). Pour les projets multi-langages, effectuez les étapes pour chaque langage dans les [instructions spécifiques aux langages](#language-specific-instructions).

### Migrer à l'aide du modèle CI/CD stable {#migrate-using-the-stable-cicd-template}

Pour éviter de perturber les pipelines CI/CD existants, le modèle stable (`Jobs/Dependency-Scanning.gitlab-ci.yml`) exécute l'analyseur Gemnasium hérité et n'est pas mis à jour pour utiliser le nouvel analyseur. Pour adopter le nouvel analyseur, remplacez `include` par le modèle `v2` (`Jobs/Dependency-Scanning.v2.gitlab-ci.yml`).

Par rapport au modèle stable, le modèle `v2` :

- Exécute le nouveau job `dependency-scanning` au lieu des jobs hérités `gemnasium-dependency_scanning`, `gemnasium-maven-dependency_scanning` et `gemnasium-python-dependency_scanning`.
- Ne prédéfinit pas les noms de jobs hérités. Les personnalisations qui remplacent les jobs `gemnasium-*` (par exemple, en les étendant dans votre `.gitlab-ci.yml`) ne s'appliquent plus et doivent être supprimées ou réécrites.
- Continue de produire l'`gl-dependency-scanning-report.json` [artefact de job](../../../ci/yaml/artifacts_reports.md#artifactsreportsdependency_scanning). Les jobs en aval qui consomment cet artefact via `needs:` ou `dependencies:` continuent de fonctionner après la migration, mais doivent référencer le nouveau nom de job `dependency-scanning` au lieu des noms de jobs hérités `gemnasium-*`.
- Accepte les mêmes variables CI/CD, avec quelques modifications documentées dans [Modifications des variables CI/CD](#changes-to-cicd-variables).

Prérequis :

- Le rôle Développeur, Chargé de maintenance ou Propriétaire pour le projet.

Pour migrer à l'aide du modèle CI/CD stable :

1. Supprimez les personnalisations qui remplacent les jobs hérités `gemnasium-*` dans votre `.gitlab-ci.yml` ou dans tout fichier inclus. Le modèle `v2` ne définit pas ces noms de jobs, donc les remplacements pourraient provoquer l'échec du pipeline CI/CD en raison d'une configuration CI/CD invalide.
1. Mettez à jour l'instruction `include` pour référencer le modèle `v2`.
1. Mettez à jour les jobs en aval qui référencent les noms de jobs hérités dans `needs:` ou `dependencies:` pour utiliser `dependency-scanning` à la place.
1. Appliquez les [instructions spécifiques aux langages](#language-specific-instructions) pour les écosystèmes de votre projet.

Avant :

```yaml
include:
  - template: Jobs/Dependency-Scanning.gitlab-ci.yml

# Customization that targets the legacy job name.
gemnasium-dependency_scanning:
  variables:
    SECURE_LOG_LEVEL: debug

# Downstream job that consumes the legacy report.
export-security-report:
  stage: deploy
  needs:
    - job: gemnasium-dependency_scanning
      artifacts: true
  script:
    - ./publish.sh gl-dependency-scanning-report.json
```

Après :

```yaml
include:
  - template: Jobs/Dependency-Scanning.v2.gitlab-ci.yml
    inputs:
      analyzer_log_level: debug

export-security-report:
  stage: deploy
  needs:
    - job: dependency-scanning
      artifacts: true
  script:
    - ./publish.sh gl-dependency-scanning-report.json
```

Si votre pipeline CI/CD doit exécuter des jobs personnalisés avant la résolution des dépendances (par exemple, pour s'authentifier auprès d'un registre privé ou préparer un cache de build), consultez [ajuster l'ordre des jobs de résolution](#adjust-resolution-job-ordering).

### Migrer à l'aide du dernier modèle CI/CD {#migrate-using-the-latest-cicd-template}

Le dernier modèle (`Jobs/Dependency-Scanning.latest.gitlab-ci.yml`) exécute l'analyseur Gemnasium hérité par défaut. En tant qu'étape transitoire, il prend en charge une activation opt-in du nouvel analyseur via la variable CI/CD `DS_ENFORCE_NEW_ANALYZER`, mais uniquement à la version `v1` du nouvel analyseur et sans les jobs de [résolution des dépendances](dependency_scanning_sbom/_index.md#dependency-resolution).

Prérequis :

- Le rôle Développeur, Chargé de maintenance ou Propriétaire pour le projet.

Pour les projets Maven, Gradle et Python, vous devez soit :

- Commiter un [lockfile ou un export de graphe de dépendances](dependency_scanning_sbom/_index.md#supported-languages-and-files) dans le dépôt ou le générer via un job CI/CD précédent.
- Activer la [solution de repli basée sur le manifeste](dependency_scanning_sbom/_index.md#manifest-fallback).

Pour une parité complète avec le modèle `v2` (analyseur `v2`, résolution des dépendances, fallback de manifeste), passez au modèle `v2` en suivant les [étapes du modèle stable](#migrate-using-the-stable-cicd-template). Le travail de migration est identique : supprimez les personnalisations ciblant les jobs hérités `gemnasium-*`, mettez à jour l'instruction `include` et mettez à jour les jobs en aval.

Si vous avez déjà activé le nouvel analyseur DS via `DS_ENFORCE_NEW_ANALYZER`, la transition est plus simple. Examinez les modifications que le nouveau modèle introduit avant de finaliser votre migration.

Si votre pipeline CI/CD doit exécuter des jobs personnalisés avant la résolution des dépendances (par exemple, pour s'authentifier auprès d'un registre privé ou préparer un cache de build), consultez [ajuster l'ordre des jobs de résolution](#adjust-resolution-job-ordering).

### Migrer à l'aide du composant CI/CD {#migrate-using-the-cicd-component}

> [!note]
> Sur GitLab Self-Managed, examinez les [limitations actuelles](../../../ci/components/_index.md#use-a-gitlabcom-component-on-gitlab-self-managed) pour l'utilisation des composants CI/CD GitLab.com.

La release `v2` du [composant CI/CD principal d'analyse des dépendances](https://gitlab.com/components/dependency-scanning/-/tree/main/templates/main) est à parité avec le modèle `v2`. Il exécute le nouvel analyseur dans sa version `v2` et prend en charge les mêmes entrées. Les releases plus anciennes (`v0` et `v1`) sont en retard sur la version de l'analyseur et sur les fonctionnalités prises en charge, de sorte que les projets qui incluent `v0` ou `v1` doivent mettre à jour l'include vers `v2`.

Prérequis :

- Le rôle Développeur, Chargé de maintenance ou Propriétaire pour le projet.

Pour migrer à l'aide du composant CI/CD :

1. Mettez à jour l'instruction `include` du composant pour référencer la version `2` du composant principal.
1. Remplacez toutes les entrées qui ont été renommées ou supprimées dans `v2`. La release `v2` du composant principal expose le même ensemble d'entrées que le modèle CI/CD `v2` ; consultez la référence des [entrées spec disponibles](dependency_scanning_sbom/_index.md#available-spec-inputs) pour la liste complète.
1. Appliquez les [instructions spécifiques aux langages](#language-specific-instructions) pour les écosystèmes de votre projet.

Si vous utilisez un composant spécialisé pour Android, Rust, Swift ou CocoaPods, migrez vers le composant principal. Le composant principal couvre désormais tous les langages et gestionnaires de paquets pris en charge. Les composants spécialisés ne sont plus nécessaires.

Avant :

```yaml
include:
  - component: $CI_SERVER_FQDN/components/dependency-scanning/main@1
```

Après :

```yaml
include:
  - component: $CI_SERVER_FQDN/components/dependency-scanning/main@2
```

Si votre pipeline CI/CD doit exécuter des jobs personnalisés avant la résolution des dépendances (par exemple, pour s'authentifier auprès d'un registre privé ou préparer un cache de build), consultez [ajuster l'ordre des jobs de résolution](#adjust-resolution-job-ordering).

### Migrer à l'aide des politiques d'exécution de scan {#migrate-using-scan-execution-policies}

Les politiques d'exécution de scan appliquent un modèle CI/CD à l'ensemble des projets ciblés par la politique. Pour l'analyse des dépendances, le champ `template` de la politique sélectionne le modèle à exécuter. Le nouvel analyseur est disponible via l'édition de modèle `v2`.

Le comportement de la politique sur chaque projet ciblé reflète celui d'un projet qui inclut directement le modèle CI/CD correspondant. Une fois la politique mise à jour pour référencer `v2`, les étapes de [migration à l'aide du modèle CI/CD stable](#migrate-using-the-stable-cicd-template) s'appliquent à chaque projet concerné : supprimez les personnalisations qui ciblent les jobs hérités `gemnasium-*` et mettez à jour tout job en aval qui les consomme.

Prérequis :

- Le rôle Owner pour le groupe, ou un rôle personnalisé avec la permission `manage_security_policy_link`.

Pour migrer à l'aide des politiques d'exécution de scan :

1. Modifiez la politique d'exécution de scan et définissez `template: v2` pour l'action `dependency_scanning`.
1. Dans chaque projet couvert par la politique, supprimez les personnalisations qui remplacent les jobs hérités `gemnasium-*` et mettez à jour les jobs en aval qui les référencent.
1. Appliquez les [instructions spécifiques aux langages](#language-specific-instructions) pour les écosystèmes des projets couverts par la politique.

Avant :

```yaml
scan_execution_policy:
  - name: Enforce dependency scanning
    enabled: true
    rules:
      - type: pipeline
        branch_type: all
    actions:
      - scan: dependency_scanning
```

Après :

```yaml
scan_execution_policy:
  - name: Enforce dependency scanning
    enabled: true
    rules:
      - type: pipeline
        branch_type: all
    actions:
      - scan: dependency_scanning
        template: v2
```

#### Projets non couverts par la résolution des dépendances ou le fallback de manifeste {#projects-not-covered-by-dependency-resolution-or-manifest-fallback}

Les politiques d'exécution de scan utilisent la capacité `build support` de l'analyseur Gemnasium hérité pour fournir un environnement de build par défaut. Le nouvel analyseur s'appuie sur la [résolution des dépendances](dependency_scanning_sbom/_index.md#dependency-resolution) ou le [fallback de manifeste](dependency_scanning_sbom/_index.md#manifest-fallback) pour détecter les dépendances des projets sans lockfile commité ou export de graphe de dépendances.

Ces mécanismes couvrent la plupart des projets qui reposaient auparavant sur `build support`. Quelques situations bénéficient encore de la flexibilité supplémentaire d'une politique d'exécution de pipeline :

- L'écosystème du projet est en dehors de la couverture actuelle de la résolution des dépendances et du fallback de manifeste (par exemple, Scala/sbt).
- La résolution des dépendances nécessite une étape de configuration qui va au-delà des variables CI/CD disponibles (par exemple, s'authentifier auprès d'un registre privé avec des identifiants non standard).

Pour ces projets, utilisez une [politique d'exécution de pipeline](#migrate-using-pipeline-execution-policies), où vous pouvez personnaliser les jobs CI/CD plus librement et [créer manuellement un lockfile ou un export de graphe de dépendances](dependency_scanning_sbom/_index.md#create-lockfile-or-dependency-graph-export-manually).

### Migrer à l'aide des politiques d'exécution de pipeline {#migrate-using-pipeline-execution-policies}

Les politiques d'exécution de pipeline appliquent une configuration CI/CD complète qui inclut généralement un modèle d'analyse des dépendances ou le composant CI/CD, ainsi que des personnalisations spécifiques au projet. Les étapes de migration applicables dépendent du contenu de la configuration CI/CD de la politique.

Prérequis :

- Le rôle Owner pour le groupe, ou un rôle personnalisé avec la permission `manage_security_policy_link`.

Pour migrer à l'aide des politiques d'exécution de pipeline :

1. Déterminez quel modèle ou composant votre politique utilise :
   - Si la politique inclut le modèle CI/CD stable, suivez [migrer à l'aide du modèle CI/CD stable](#migrate-using-the-stable-cicd-template).
   - Si la politique inclut le dernier modèle CI/CD, suivez [migrer à l'aide du dernier modèle CI/CD](#migrate-using-the-latest-cicd-template).
   - Si la politique inclut le composant CI/CD, suivez [migrer à l'aide du composant CI/CD](#migrate-using-the-cicd-component).

1. Appliquez ces étapes à la configuration CI/CD de la politique.
1. Appliquez les [instructions spécifiques aux langages](#language-specific-instructions) pour les écosystèmes des projets couverts par la politique.

Les variables CI/CD définies pour les projets, les groupes ou les instances (et les variables définies dans le bloc `variables:` de la politique) continuent de s'appliquer au nouveau job `dependency-scanning` et aux jobs de résolution qui s'exécutent avant lui. Pour les variables dont le statut a changé dans `v2`, consultez [les modifications des variables CI/CD](#changes-to-cicd-variables).

Si votre pipeline CI/CD doit exécuter des jobs personnalisés avant la résolution des dépendances (par exemple, pour s'authentifier auprès d'un registre privé ou préparer un cache de build), consultez [ajuster l'ordre des jobs de résolution](#adjust-resolution-job-ordering).

## Autres considérations {#other-considerations}

Les personnalisations suivantes s'appliquent quelle que soit la façon dont l'analyse des dépendances est activée dans vos projets.

### Ajuster l'ordre des jobs de résolution {#adjust-resolution-job-ordering}

Par défaut, les jobs de résolution des dépendances s'exécutent dans l'étape `.pre`. Si votre pipeline CI/CD comporte des jobs personnalisés qui doivent se terminer avant l'exécution de l'analyse des dépendances (par exemple, un job `.pre` qui s'authentifie auprès d'un registre privé ou prépare un cache de build), les jobs de résolution s'exécutent en parallèle avec ces jobs personnalisés plutôt qu'après eux. Les jobs de résolution ne peuvent pas voir les artefacts produits par les jobs personnalisés.

Pour préserver l'ordre souhaité, déplacez les jobs de résolution vers une étape ultérieure en utilisant l'entrée `resolution_jobs_stage` sur le modèle ou le composant `v2` :

```yaml
stages:
  - .pre
  - prepare
  - test

include:
  - template: Jobs/Dependency-Scanning.v2.gitlab-ci.yml
    inputs:
      resolution_jobs_stage: prepare

private-registry-cache-build:
  stage: .pre
  script:
    - ./scripts/login-private-registry.sh
    - ./scripts/build-dependency-cache.sh
```

Les jobs de résolution s'exécutent ensuite dans l'étape `prepare` après la fin du job `.pre` personnalisé. Pour la liste complète des entrées qui contrôlent le comportement des jobs de résolution, consultez les [entrées CI/CD disponibles](dependency_scanning_sbom/_index.md#available-spec-inputs).

## Instructions spécifiques aux langages {#language-specific-instructions}

Lors de votre migration vers le nouvel analyseur d'analyse des dépendances, vous devrez effectuer des ajustements spécifiques en fonction des langages de programmation et des gestionnaires de paquets de votre projet. Ces instructions s'appliquent chaque fois que vous utilisez le nouvel analyseur d'analyse des dépendances, quelle que soit la façon dont vous l'avez configuré pour s'exécuter – que ce soit via des modèles CI/CD, des politiques d'exécution de scan ou le composant CI/CD d'analyse des dépendances. Dans les sections suivantes, vous trouverez des instructions détaillées pour chaque langage et gestionnaire de paquets pris en charge. Chaque instruction contient des explications sur :

- Comment la détection des dépendances évolue
- Quels fichiers spécifiques vous devez fournir
- Comment générer ces fichiers s'ils ne font pas déjà partie de votre workflow

Partagez vos commentaires sur le nouvel analyseur des dépendances dans ce [ticket](https://gitlab.com/gitlab-org/gitlab/-/issues/523458).

### Bundler {#bundler}

**Comportement précédent** : l'analyse des dépendances basée sur l'analyseur Gemnasium prend en charge les projets Bundler à l'aide du job CI/CD `gemnasium-dependency_scanning` et de sa capacité à extraire les dépendances du projet en analysant le fichier `Gemfile.lock` (le nom de fichier alternatif `gems.locked` est également pris en charge). La combinaison des versions prises en charge de Bundler et du fichier `Gemfile.lock` est détaillée dans la [documentation d'analyse des dépendances (basée sur Gemnasium)](legacy_dependency_scanning/_index.md#obtaining-dependency-information-by-parsing-lockfiles).

**Nouveau comportement** : le nouvel analyseur d'analyse des dépendances extrait également les dépendances du projet en analysant le fichier `Gemfile.lock` (le nom de fichier alternatif `gems.locked` est également pris en charge) et génère un artefact de job de rapport SBOM CycloneDX avec le job CI/CD `dependency-scanning`.

#### Migrer un projet Bundler {#migrate-a-bundler-project}

Migrez un projet Bundler pour utiliser le nouvel analyseur d'analyse des dépendances.

Prérequis :

- Effectuez [les étapes de migration génériques](#migrate-to-dependency-scanning-using-sbom) requises pour tous les projets.
- Le rôle Développeur, Chargé de maintenance ou Propriétaire pour le projet.

Aucune étape supplémentaire n'est nécessaire pour migrer un projet Bundler vers l'analyseur d'analyse des dépendances.

### CocoaPods {#cocoapods}

**Comportement précédent** : l'analyse des dépendances basée sur l'analyseur Gemnasium ne prend pas en charge les projets CocoaPods lors de l'utilisation des modèles CI/CD ou des politiques d'exécution de scan. La prise en charge de CocoaPods est uniquement disponible sur le composant CI/CD CocoaPods expérimental.

**Nouveau comportement** : le nouvel analyseur d'analyse des dépendances extrait les dépendances du projet en analysant le fichier `Podfile.lock` et génère un artefact de job de rapport SBOM CycloneDX avec le job CI/CD `dependency-scanning`.

#### Migrer un projet CocoaPods {#migrate-a-cocoapods-project}

Migrez un projet CocoaPods pour utiliser le nouvel analyseur d'analyse des dépendances.

Prérequis :

- Effectuez [les étapes de migration génériques](#migrate-to-dependency-scanning-using-sbom) requises pour tous les projets.
- Le rôle Développeur, Chargé de maintenance ou Propriétaire pour le projet.

Il n'y a pas d'étapes supplémentaires pour migrer un projet CocoaPods vers l'analyseur d'analyse des dépendances.

### Composer {#composer}

**Comportement précédent** : l'analyse des dépendances basée sur l'analyseur Gemnasium prend en charge les projets Composer à l'aide du job CI/CD `gemnasium-dependency_scanning` et de sa capacité à extraire les dépendances du projet en analysant le fichier `composer.lock`. La combinaison des versions prises en charge de Composer et du fichier `composer.lock` est détaillée dans la [documentation d'analyse des dépendances (basée sur Gemnasium)](legacy_dependency_scanning/_index.md#obtaining-dependency-information-by-parsing-lockfiles).

**Nouveau comportement** : le nouvel analyseur d'analyse des dépendances extrait également les dépendances du projet en analysant le fichier `composer.lock` et génère un artefact de job de rapport SBOM CycloneDX avec le job CI/CD `dependency-scanning`.

#### Migrer un projet Composer {#migrate-a-composer-project}

Migrez un projet Composer pour utiliser le nouvel analyseur d'analyse des dépendances.

Prérequis :

- Effectuez [les étapes de migration génériques](#migrate-to-dependency-scanning-using-sbom) requises pour tous les projets.
- Le rôle Développeur, Chargé de maintenance ou Propriétaire pour le projet.

Il n'y a pas d'étapes supplémentaires pour migrer un projet Composer vers l'analyseur d'analyse des dépendances.

### Conan {#conan}

**Comportement précédent** : l'analyse des dépendances basée sur l'analyseur Gemnasium prend en charge les projets Conan à l'aide du job CI/CD `gemnasium-dependency_scanning` et de sa capacité à extraire les dépendances du projet en analysant le fichier `conan.lock`. La combinaison des versions prises en charge de Conan et du fichier `conan.lock` est détaillée dans la [documentation d'analyse des dépendances (basée sur Gemnasium)](legacy_dependency_scanning/_index.md#obtaining-dependency-information-by-parsing-lockfiles).

**Nouveau comportement** : le nouvel analyseur d'analyse des dépendances extrait également les dépendances du projet en analysant le fichier `conan.lock` et génère un artefact de job de rapport SBOM CycloneDX avec le job CI/CD `dependency-scanning`.

#### Migrer un projet Conan {#migrate-a-conan-project}

Migrez un projet Conan pour utiliser le nouvel analyseur d'analyse des dépendances.

Prérequis :

- Effectuez [les étapes de migration génériques](#migrate-to-dependency-scanning-using-sbom) requises pour tous les projets.
- Le rôle Développeur, Chargé de maintenance ou Propriétaire pour le projet.

Il n'y a pas d'étapes supplémentaires pour migrer un projet Conan vers l'analyseur d'analyse des dépendances.

### Go {#go}

**Comportement précédent** : l'analyse des dépendances basée sur l'analyseur Gemnasium prend en charge les projets Go à l'aide du job CI/CD `gemnasium-dependency_scanning` et de sa capacité à extraire les dépendances du projet en utilisant les fichiers `go.mod` et `go.sum`. Cet analyseur tente d'exécuter la commande `go list` pour augmenter la précision des dépendances détectées, ce qui nécessite un environnement Go fonctionnel. En cas d'échec, il revient à l'analyse du fichier `go.sum`. La combinaison des versions prises en charge de Go, des fichiers `go.mod` et `go.sum` est détaillée dans la [documentation d'analyse des dépendances (basée sur Gemnasium)](legacy_dependency_scanning/_index.md#obtaining-dependency-information-by-parsing-lockfiles).

**Nouveau comportement** : le nouvel analyseur d'analyse des dépendances ne tente pas d'exécuter la commande `go list` dans le projet pour extraire les dépendances et ne revient plus à l'analyse du fichier `go.sum`. À la place, le projet doit fournir au moins un fichier `go.mod` et idéalement un fichier `go.graph` généré avec la [`go mod graph` commande](https://go.dev/ref/mod#go-mod-graph) des Go Toolchains. Le fichier `go.graph` est nécessaire pour améliorer la précision des composants détectés et pour générer le graphe de dépendances afin d'activer des fonctionnalités comme le [chemin de dépendance](../dependency_list/_index.md#dependency-paths). Ces fichiers sont traités par le job CI/CD `dependency-scanning` pour générer un artefact de job de rapport SBOM CycloneDX. Cette approche ne nécessite pas que GitLab prenne en charge des versions spécifiques de Go. La [résolution des dépendances](dependency_scanning_sbom/_index.md#dependency-resolution) n'est pas prise en charge pour les projets Go.

#### Migrer un projet Go {#migrate-a-go-project}

Migrez un projet Go pour utiliser le nouvel analyseur d'analyse des dépendances.

Prérequis :

- Effectuez [les étapes de migration génériques](#migrate-to-dependency-scanning-using-sbom) requises pour tous les projets.
- Le rôle Développeur, Chargé de maintenance ou Propriétaire pour le projet.

Pour migrer un projet Go :

- Assurez-vous que votre projet fournit les fichiers `go.mod` et `go.graph`. Configurez la [`go mod graph` commande](https://go.dev/ref/mod#go-mod-graph) des Go Toolchains dans un job CI/CD précédent (par exemple : `build`) pour générer dynamiquement le fichier `go.graph` et l'exporter en tant qu'[artefact](../../../ci/jobs/job_artifacts.md) avant d'exécuter le job d'analyse des dépendances.

Consultez les [instructions d'activation pour Go](dependency_scanning_sbom/_index.md#go) pour plus de détails et d'exemples.

### Gradle {#gradle}

**Comportement précédent** : l'analyse des dépendances basée sur l'analyseur Gemnasium prend en charge les projets Gradle à l'aide du job CI/CD `gemnasium-maven-dependency_scanning` pour extraire les dépendances du projet en buildant l'application à partir des fichiers `build.gradle` et `build.gradle.kts`. Les combinaisons de versions prises en charge pour Java, Kotlin et Gradle sont complexes, comme détaillé dans la [documentation d'analyse des dépendances (basée sur Gemnasium)](legacy_dependency_scanning/_index.md#obtaining-dependency-information-by-running-a-package-manager-to-generate-a-parsable-file).

**Nouveau comportement** : le nouvel analyseur d'analyse des dépendances ne builde pas le projet pour extraire les dépendances. Il utilise plutôt un modèle de détection multi-niveaux :

- Si un [lockfile ou un export de graphe pris en charge](dependency_scanning_sbom/_index.md#supported-languages-and-files) existe dans le dépôt ou un artefact de job (par exemple, `gradle.lockfile`), l'analyseur l'utilise directement.
- Si aucun lockfile ou export de graphe pris en charge n'est détecté mais qu'un fichier de build pris en charge existe (par exemple, `build.gradle`), un job de [résolution des dépendances](dependency_scanning_sbom/_index.md#dependency-resolution) s'exécute dans l'étape `.pre`. Il exécute automatiquement `gradle dependencies` pour générer un export de graphe de dépendances pour le job `dependency-scanning`.
- Si la résolution des dépendances n'est pas disponible ou échoue, le [fallback de manifeste](dependency_scanning_sbom/_index.md#manifest-fallback) analyse directement `build.gradle` et `build.gradle.kts` pour extraire uniquement les dépendances directes. La précision du fallback de manifeste est réduite pour les projets qui déclarent des dépendances via `gradle.properties` ou `gradle/libs.versions.toml`, car les variables de version ne sont pas toujours résolues.

#### Migrer un projet Gradle {#migrate-a-gradle-project}

Migrez un projet Gradle pour utiliser le nouvel analyseur d'analyse des dépendances.

Prérequis :

- Effectuez [les étapes de migration génériques](#migrate-to-dependency-scanning-using-sbom) requises pour tous les projets.
- Le rôle Développeur, Chargé de maintenance ou Propriétaire pour le projet.

Pour migrer un projet Gradle, choisissez l'une des options suivantes :

- Pour des résultats plus précis, assurez-vous que votre projet fournit un fichier d'export de graphe de dépendances. Configurez la [tâche de dépendances Gradle](https://docs.gradle.org/current/userguide/viewing_debugging_dependencies.html) dans un job CI/CD précédent (par exemple : `build`) pour générer dynamiquement le fichier `gradle.graph.txt` et l'exporter en tant qu'[artefact](../../../ci/jobs/job_artifacts.md) avant d'exécuter le job d'analyse des dépendances. Vous pouvez également sélectionner un autre [lockfile ou export de graphe pris en charge](dependency_scanning_sbom/_index.md#supported-languages-and-files). Lorsque vous générez dynamiquement un lockfile ou un export de graphe, désactivez la résolution automatique des dépendances en ajoutant `gradle` à la valeur de la variable CI/CD `DS_DISABLED_RESOLUTION_JOBS`.
- Utilisez la [résolution des dépendances](dependency_scanning_sbom/_index.md#dependency-resolution) pour générer automatiquement le fichier `gradle.graph.txt`. Vérifiez que l'image de résolution peut générer avec succès l'export de graphe.
- Utilisez le [fallback de manifeste](dependency_scanning_sbom/_index.md#manifest-fallback) pour une couverture de base des dépendances directes déclarées dans `build.gradle` ou `build.gradle.kts`.

Consultez les [instructions d'activation pour Gradle](dependency_scanning_sbom/_index.md#gradle) pour plus de détails et d'exemples.

### Maven {#maven}

**Comportement précédent** : l'analyse des dépendances basée sur l'analyseur Gemnasium prend en charge les projets Maven à l'aide du job CI/CD `gemnasium-maven-dependency_scanning` pour extraire les dépendances du projet en buildant l'application à partir du fichier `pom.xml`. Les combinaisons de versions prises en charge pour Java, Kotlin et Maven sont complexes, comme détaillé dans la [documentation d'analyse des dépendances (basée sur Gemnasium)](legacy_dependency_scanning/_index.md#obtaining-dependency-information-by-running-a-package-manager-to-generate-a-parsable-file).

**Nouveau comportement** : le nouvel analyseur d'analyse des dépendances ne builde pas le projet pour extraire les dépendances. Il utilise plutôt un modèle de détection multi-niveaux :

- Si un fichier d'export de graphe `maven.graph.json` généré avec le [plugin de dépendances Maven](https://maven.apache.org/plugins/maven-dependency-plugin/index.html) existe dans le dépôt ou un artefact de job, l'analyseur l'utilise directement.
- Si aucun export de graphe n'est détecté mais qu'un fichier `pom.xml` pris en charge existe, un job de [résolution des dépendances](dependency_scanning_sbom/_index.md#dependency-resolution) s'exécute dans l'étape `.pre`. Il exécute automatiquement `mvn dependency:tree` pour générer un export de graphe de dépendances pour le job `dependency-scanning`.
- Si la résolution des dépendances n'est pas disponible ou échoue, le [fallback de manifeste](dependency_scanning_sbom/_index.md#manifest-fallback) analyse directement le fichier `pom.xml` pour extraire uniquement les dépendances directes.

#### Migrer un projet Maven {#migrate-a-maven-project}

Migrez un projet Maven pour utiliser le nouvel analyseur d'analyse des dépendances.

Prérequis :

- Effectuez [les étapes de migration génériques](#migrate-to-dependency-scanning-using-sbom) requises pour tous les projets.
- Le rôle Développeur, Chargé de maintenance ou Propriétaire pour le projet.

Pour migrer un projet Maven, choisissez l'une des options suivantes :

- Pour des résultats plus précis, assurez-vous que votre projet fournit un fichier `maven.graph.json`. Configurez le [plugin de dépendances Maven](https://maven.apache.org/plugins/maven-dependency-plugin/index.html) dans un job CI/CD précédent (par exemple : `build`) pour générer dynamiquement le fichier `maven.graph.json` et l'exporter en tant qu'[artefact](../../../ci/jobs/job_artifacts.md) avant d'exécuter le job d'analyse des dépendances. Lorsque vous générez dynamiquement un export de graphe, désactivez la résolution automatique des dépendances en ajoutant `maven` à la valeur de la variable CI/CD `DS_DISABLED_RESOLUTION_JOBS`.
- Utilisez la [résolution des dépendances](dependency_scanning_sbom/_index.md#dependency-resolution) pour générer automatiquement le fichier `maven.graph.json`. Vérifiez que l'image de résolution peut générer avec succès l'export de graphe.
- Utilisez le [fallback de manifeste](dependency_scanning_sbom/_index.md#manifest-fallback) pour une couverture de base des dépendances directes déclarées dans `pom.xml`.

Consultez les [instructions d'activation pour Maven](dependency_scanning_sbom/_index.md#maven) pour plus de détails et d'exemples.

### npm {#npm}

**Comportement précédent** : l'analyse des dépendances basée sur l'analyseur Gemnasium prend en charge les projets npm à l'aide du job CI/CD `gemnasium-dependency_scanning` et de sa capacité à extraire les dépendances du projet en analysant les fichiers `package-lock.json` ou `npm-shrinkwrap.json.lock`. La combinaison des versions prises en charge de npm et des fichiers `package-lock.json` ou `npm-shrinkwrap.json.lock` est détaillée dans la [documentation d'analyse des dépendances (basée sur Gemnasium)](legacy_dependency_scanning/_index.md#obtaining-dependency-information-by-parsing-lockfiles). Cet analyseur peut analyser les fichiers JavaScript vendorisés dans un projet npm à l'aide du scanner `Retire.JS`.

**Nouveau comportement** : le nouvel analyseur d'analyse des dépendances extrait également les dépendances du projet en analysant les fichiers `package-lock.json` ou `npm-shrinkwrap.json.lock` et génère un artefact de job de rapport SBOM CycloneDX avec le job CI/CD `dependency-scanning`. Cet analyseur n'analyse pas les fichiers JavaScript vendorisés. Pour plus d'informations, consultez l'[annonce de dépréciation de l'analyse des dépendances pour les bibliothèques JavaScript vendorisées](../../../update/deprecations.md#dependency-scanning-for-javascript-vendored-libraries) pour le contexte et les actions disponibles. La prise en charge d'une fonctionnalité de remplacement est proposée dans l'[epic 7186](https://gitlab.com/groups/gitlab-org/-/epics/7186).

#### Migrer un projet npm {#migrate-an-npm-project}

Migrez un projet npm pour utiliser le nouvel analyseur d'analyse des dépendances.

Prérequis :

- Effectuez [les étapes de migration génériques](#migrate-to-dependency-scanning-using-sbom) requises pour tous les projets.
- Le rôle Développeur, Chargé de maintenance ou Propriétaire pour le projet.

Il n'y a pas d'étapes supplémentaires pour migrer un projet npm vers l'analyseur d'analyse des dépendances.

### NuGet {#nuget}

**Comportement précédent** : l'analyse des dépendances basée sur l'analyseur Gemnasium prend en charge les projets NuGet à l'aide du job CI/CD `gemnasium-dependency_scanning` et de sa capacité à extraire les dépendances du projet en analysant le fichier `packages.lock.json`. La combinaison des versions prises en charge de NuGet et du fichier `packages.lock.json` est détaillée dans la [documentation d'analyse des dépendances (basée sur Gemnasium)](legacy_dependency_scanning/_index.md#obtaining-dependency-information-by-parsing-lockfiles).

**Nouveau comportement** : le nouvel analyseur d'analyse des dépendances extrait également les dépendances du projet en analysant le fichier `packages.lock.json` et génère un artefact de job de rapport SBOM CycloneDX avec le job CI/CD `dependency-scanning`.

#### Migrer un projet NuGet {#migrate-a-nuget-project}

Migrez un projet NuGet pour utiliser le nouvel analyseur d'analyse des dépendances.

Prérequis :

- Effectuez [les étapes de migration génériques](#migrate-to-dependency-scanning-using-sbom) requises pour tous les projets.
- Le rôle Développeur, Chargé de maintenance ou Propriétaire pour le projet.

Il n'y a pas d'étapes supplémentaires pour migrer un projet NuGet vers l'analyseur d'analyse des dépendances.

### pip {#pip}

**Comportement précédent** : l'analyse des dépendances basée sur l'analyseur Gemnasium prend en charge les projets pip à l'aide du job CI/CD `gemnasium-python-dependency_scanning` pour extraire les dépendances du projet en buildant l'application à partir du fichier `requirements.txt` (les noms de fichiers alternatifs `requirements.pip` et `requires.txt` sont également pris en charge). La variable d'environnement `PIP_REQUIREMENTS_FILE` peut également être utilisée pour spécifier un nom de fichier personnalisé. Les combinaisons de versions prises en charge pour Python et pip sont détaillées dans la [documentation d'analyse des dépendances (basée sur Gemnasium)](legacy_dependency_scanning/_index.md#obtaining-dependency-information-by-running-a-package-manager-to-generate-a-parsable-file).

**Nouveau comportement** : le nouvel analyseur d'analyse des dépendances ne builde pas le projet pour extraire les dépendances. Il utilise plutôt un modèle de détection multi-niveaux :

- Si un [lockfile ou un export de graphe pris en charge](dependency_scanning_sbom/_index.md#supported-languages-and-files) existe dans le dépôt ou un artefact de job (par exemple, `requirements.txt` généré avec pip-compile), l'analyseur l'utilise directement.
- Si aucun lockfile ou export de graphe pris en charge n'est détecté mais qu'un fichier de build pris en charge existe (par exemple, `requirements.in`), un job de [résolution des dépendances](dependency_scanning_sbom/_index.md#dependency-resolution) s'exécute dans l'étape `.pre`. Il exécute automatiquement `pip-compile` pour générer un lockfile pour le job `dependency-scanning`.
- Si la résolution des dépendances n'est pas disponible ou échoue, le [fallback de manifeste](dependency_scanning_sbom/_index.md#manifest-fallback) analyse directement le fichier `requirements.txt` pour extraire uniquement les dépendances directes.

#### Migrer un projet pip {#migrate-a-pip-project}

Migrez un projet pip pour utiliser le nouvel analyseur d'analyse des dépendances.

Prérequis :

- Effectuez [les étapes de migration génériques](#migrate-to-dependency-scanning-using-sbom) requises pour tous les projets.
- Le rôle Développeur, Chargé de maintenance ou Propriétaire pour le projet.

Pour migrer un projet pip, choisissez l'une des options suivantes :

- Pour des résultats plus précis, assurez-vous que votre projet fournit un lockfile. Configurez l'[outil en ligne de commande pip-compile](https://pip-tools.readthedocs.io/en/latest/cli/pip-compile/) dans votre projet et commitez le lockfile `requirements.txt` dans votre dépôt ou utilisez-le dans un job CI/CD précédent (par exemple : `build`) pour générer dynamiquement le fichier `requirements.txt` et l'exporter en tant qu'[artefact](../../../ci/jobs/job_artifacts.md) avant d'exécuter le job d'analyse des dépendances. Vous pouvez également sélectionner un autre [lockfile ou export de graphe pris en charge](dependency_scanning_sbom/_index.md#supported-languages-and-files). Lorsque vous générez dynamiquement un lockfile ou un export de graphe, désactivez la résolution automatique des dépendances en ajoutant `python` à la valeur de la variable CI/CD `DS_DISABLED_RESOLUTION_JOBS`.
- Utilisez la [résolution des dépendances](dependency_scanning_sbom/_index.md#dependency-resolution) pour générer automatiquement le fichier `pipcompile.lock.txt`. Vérifiez que l'image de résolution peut générer avec succès le lockfile.
- Utilisez le [fallback de manifeste](dependency_scanning_sbom/_index.md#manifest-fallback) pour une couverture de base des dépendances directes déclarées dans `requirements.txt`.

Consultez les [instructions d'activation pour pip](dependency_scanning_sbom/_index.md#pip) pour plus de détails et d'exemples.

### Pipenv {#pipenv}

**Comportement précédent** : l'analyse des dépendances basée sur l'analyseur Gemnasium prend en charge les projets Pipenv à l'aide du job CI/CD `gemnasium-python-dependency_scanning` pour extraire les dépendances du projet en buildant l'application à partir du fichier `Pipfile` ou d'un fichier `Pipfile.lock` si présent. Les combinaisons de versions prises en charge pour Python et Pipenv sont détaillées dans la [documentation d'analyse des dépendances (basée sur Gemnasium)](legacy_dependency_scanning/_index.md#obtaining-dependency-information-by-running-a-package-manager-to-generate-a-parsable-file).

**Nouveau comportement** : le nouvel analyseur d'analyse des dépendances ne builde pas le projet Pipenv pour extraire les dépendances. À la place, le projet doit fournir au moins un fichier `Pipfile.lock` et idéalement un fichier `pipenv.graph.json` généré par la [`pipenv graph` commande](https://pipenv.pypa.io/en/latest/cli.html#graph). Le fichier `pipenv.graph.json` est nécessaire pour générer le graphe de dépendances et activer des fonctionnalités comme le [chemin de dépendance](../dependency_list/_index.md#dependency-paths). Ces fichiers sont traités par le job CI/CD `dependency-scanning` pour générer un artefact de job de rapport SBOM CycloneDX. Cette approche ne nécessite pas que GitLab prenne en charge des versions spécifiques de Python et Pipenv. La [résolution des dépendances](dependency_scanning_sbom/_index.md#dependency-resolution) n'est pas prise en charge pour les projets utilisant un fichier `Pipfile` sans fichier `Pipfile.lock`.

#### Migrer un projet Pipenv {#migrate-a-pipenv-project}

Migrez un projet Pipenv pour utiliser le nouvel analyseur d'analyse des dépendances.

Prérequis :

- Effectuez [les étapes de migration génériques](#migrate-to-dependency-scanning-using-sbom) requises pour tous les projets.
- Le rôle Développeur, Chargé de maintenance ou Propriétaire pour le projet.

Pour migrer un projet Pipenv :

- Assurez-vous que votre projet fournit un fichier `Pipfile.lock`. Configurez la [`pipenv lock` commande](https://pipenv.pypa.io/en/latest/cli.html#graph) dans votre projet et commitez le fichier `Pipfile.lock` dans votre dépôt ou utilisez-le dans un job CI/CD précédent (par exemple : `build`) pour générer dynamiquement le fichier `Pipfile.lock` et l'exporter en tant qu'[artefact](../../../ci/jobs/job_artifacts.md) avant d'exécuter le job d'analyse des dépendances. Vous pouvez également sélectionner un autre [lockfile ou export de graphe pris en charge](dependency_scanning_sbom/_index.md#supported-languages-and-files).

### Poetry {#poetry}

**Comportement précédent** : l'analyse des dépendances basée sur l'analyseur Gemnasium prend en charge les projets Poetry à l'aide du job CI/CD `gemnasium-python-dependency_scanning` et de sa capacité à extraire les dépendances du projet en analysant le fichier `poetry.lock`. La combinaison des versions prises en charge de Poetry et du fichier `poetry.lock` est détaillée dans la [documentation d'analyse des dépendances (basée sur Gemnasium)](legacy_dependency_scanning/_index.md#obtaining-dependency-information-by-parsing-lockfiles).

**Nouveau comportement** : le nouvel analyseur d'analyse des dépendances extrait également les dépendances du projet en analysant le fichier `poetry.lock` et génère un artefact de job de rapport SBOM CycloneDX avec le job CI/CD `dependency-scanning`.

#### Migrer un projet Poetry {#migrate-a-poetry-project}

Migrez un projet Poetry pour utiliser le nouvel analyseur d'analyse des dépendances.

Prérequis :

- Effectuez [les étapes de migration génériques](#migrate-to-dependency-scanning-using-sbom) requises pour tous les projets.
- Le rôle Développeur, Chargé de maintenance ou Propriétaire pour le projet.

Il n'y a pas d'étapes supplémentaires pour migrer un projet Poetry vers l'analyseur d'analyse des dépendances.

### pnpm {#pnpm}

**Comportement précédent** : l'analyse des dépendances basée sur l'analyseur Gemnasium prend en charge les projets pnpm à l'aide du job CI/CD `gemnasium-dependency_scanning` et de sa capacité à extraire les dépendances du projet en analysant le fichier `pnpm-lock.yaml`. La combinaison des versions prises en charge de pnpm et du fichier `pnpm-lock.yaml` est détaillée dans la [documentation d'analyse des dépendances (basée sur Gemnasium)](legacy_dependency_scanning/_index.md#obtaining-dependency-information-by-parsing-lockfiles). Cet analyseur peut analyser les fichiers JavaScript vendorisés dans un projet npm à l'aide du scanner `Retire.JS`.

**Nouveau comportement** : le nouvel analyseur d'analyse des dépendances extrait également les dépendances du projet en analysant le fichier `pnpm-lock.yaml` et génère un artefact de job de rapport SBOM CycloneDX avec le job CI/CD `dependency-scanning`. Cet analyseur n'analyse pas les fichiers JavaScript vendorisés. Pour plus d'informations, consultez l'[annonce de dépréciation de l'analyse des dépendances pour les bibliothèques JavaScript vendorisées](../../../update/deprecations.md#dependency-scanning-for-javascript-vendored-libraries) pour le contexte et les actions disponibles. La prise en charge d'une fonctionnalité de remplacement est proposée dans l'[epic 7186](https://gitlab.com/groups/gitlab-org/-/epics/7186).

#### Migrer un projet pnpm {#migrate-a-pnpm-project}

Migrez un projet pnpm pour utiliser le nouvel analyseur d'analyse des dépendances.

Prérequis :

- Effectuez [les étapes de migration génériques](#migrate-to-dependency-scanning-using-sbom) requises pour tous les projets.
- Le rôle Développeur, Chargé de maintenance ou Propriétaire pour le projet.

Aucune étape supplémentaire n'est requise pour migrer un projet pnpm vers l'analyseur d'analyse des dépendances.

### sbt {#sbt}

**Comportement précédent** : l'analyse des dépendances basée sur l'analyseur Gemnasium prend en charge les projets sbt à l'aide du job CI/CD `gemnasium-maven-dependency_scanning` pour extraire les dépendances du projet en buildant l'application à partir du fichier `build.sbt`. Les combinaisons de versions prises en charge pour Java, Scala et sbt sont complexes, comme détaillé dans la [documentation d'analyse des dépendances (basée sur Gemnasium)](legacy_dependency_scanning/_index.md#obtaining-dependency-information-by-running-a-package-manager-to-generate-a-parsable-file).

**Nouveau comportement** : le nouvel analyseur d'analyse des dépendances ne builde pas le projet pour extraire les dépendances. À la place, le projet doit fournir un fichier `dependencies-compile.dot` généré avec le [plugin sbt-dependency-graph](https://github.com/sbt/sbt-dependency-graph) ([inclus dans sbt >= 1.4.0](https://www.scala-sbt.org/1.x/docs/sbt-1.4-Release-Notes.html#sbt-dependency-graph+is+in-sourced)). Ce fichier est traité par le job CI/CD `dependency-scanning` pour générer un artefact de job de rapport SBOM CycloneDX. Cette approche ne nécessite pas que GitLab prenne en charge des versions spécifiques de Java, Scala et sbt. La [résolution des dépendances](dependency_scanning_sbom/_index.md#dependency-resolution) n'est pas prise en charge pour les projets sbt.

#### Migrer un projet sbt {#migrate-an-sbt-project}

Migrez un projet sbt pour utiliser le nouvel analyseur d'analyse des dépendances.

Prérequis :

- Effectuez [les étapes de migration génériques](#migrate-to-dependency-scanning-using-sbom) requises pour tous les projets.
- Le rôle Développeur, Chargé de maintenance ou Propriétaire pour le projet.

Pour migrer un projet sbt :

- Assurez-vous que votre projet fournit un fichier `dependencies-compile.dot`. Configurez le [plugin sbt-dependency-graph](https://github.com/sbt/sbt-dependency-graph) dans un job CI/CD précédent (par exemple : `build`) pour générer dynamiquement le fichier `dependencies-compile.dot` et l'exporter en tant qu'[artefact](../../../ci/jobs/job_artifacts.md) avant d'exécuter le job d'analyse des dépendances.

Consultez les [instructions d'activation pour sbt](dependency_scanning_sbom/_index.md#sbt) pour plus de détails et d'exemples.

### setuptools {#setuptools}

**Comportement précédent** : l'analyse des dépendances basée sur l'analyseur Gemnasium prend en charge les projets setuptools à l'aide du job CI/CD `gemnasium-python-dependency_scanning` pour extraire les dépendances du projet en buildant l'application à partir du fichier `setup.py`. Les combinaisons de versions prises en charge pour Python et setuptools sont détaillées dans la [documentation d'analyse des dépendances (basée sur Gemnasium)](legacy_dependency_scanning/_index.md#obtaining-dependency-information-by-running-a-package-manager-to-generate-a-parsable-file).

**Nouveau comportement** : le nouvel analyseur d'analyse des dépendances ne builde pas un projet setuptools pour extraire les dépendances. Il utilise plutôt un modèle de détection multi-niveaux :

- Si un [lockfile ou un export de graphe pris en charge](dependency_scanning_sbom/_index.md#supported-languages-and-files) existe dans le dépôt ou un artefact de job (par exemple, `requirements.txt` généré avec pip-compile), l'analyseur l'utilise directement.
- Si aucun lockfile ou export de graphe pris en charge n'est détecté mais qu'un fichier de build pris en charge existe (par exemple, `setup.py`), un job de [résolution des dépendances](dependency_scanning_sbom/_index.md#dependency-resolution) s'exécute dans l'étape `.pre`. Il exécute automatiquement `pip-compile` pour générer un lockfile pour le job `dependency-scanning`.

#### Migrer un projet setuptools {#migrate-a-setuptools-project}

Migrez un projet setuptools pour utiliser le nouvel analyseur d'analyse des dépendances.

Prérequis :

- Effectuez [les étapes de migration génériques](#migrate-to-dependency-scanning-using-sbom) requises pour tous les projets.
- Le rôle Développeur, Chargé de maintenance ou Propriétaire pour le projet.

Pour migrer un projet setuptools, choisissez l'une des options suivantes :

- Pour des résultats plus précis, assurez-vous que votre projet fournit un lockfile `requirements.txt`. Configurez l'[outil en ligne de commande pip-compile](https://pip-tools.readthedocs.io/en/latest/cli/pip-compile/) dans votre projet et soit :
  - Intégrez définitivement l'outil en ligne de commande dans votre workflow de développement. Cela implique de commiter le fichier `requirements.txt` dans votre dépôt et de le mettre à jour au fur et à mesure des modifications apportées aux dépendances de votre projet.
  - Utilisez l'outil en ligne de commande dans un job CI/CD `build` pour générer dynamiquement le fichier `requirements.txt` et l'exporter en tant qu'[artefact](../../../ci/jobs/job_artifacts.md) avant d'exécuter le job d'analyse des dépendances.
- Activez la [résolution des dépendances](dependency_scanning_sbom/_index.md#dependency-resolution) pour générer automatiquement un lockfile `requirements.txt` à partir de vos fichiers manifestes.

Consultez les [instructions d'activation pour pip](dependency_scanning_sbom/_index.md#pip) pour plus de détails et d'exemples.

### Swift {#swift}

**Comportement précédent** : l'analyse des dépendances basée sur l'analyseur Gemnasium ne prend pas en charge les projets Swift lors de l'utilisation des modèles CI/CD ou des politiques d'exécution de scan. La prise en charge de Swift est uniquement disponible sur le composant CI/CD Swift expérimental.

**Nouveau comportement** : le nouvel analyseur d'analyse des dépendances extrait également les dépendances du projet en analysant le fichier `Package.resolved` et génère un artefact de job de rapport SBOM CycloneDX avec le job CI/CD `dependency-scanning`.

#### Migrer un projet Swift {#migrate-a-swift-project}

Migrez un projet Swift pour utiliser le nouvel analyseur d'analyse des dépendances.

Prérequis :

- Effectuez [les étapes de migration génériques](#migrate-to-dependency-scanning-using-sbom) requises pour tous les projets.
- Le rôle Développeur, Chargé de maintenance ou Propriétaire pour le projet.

Il n'y a pas d'étapes supplémentaires pour migrer un projet Swift vers l'analyseur d'analyse des dépendances.

### uv {#uv}

**Comportement précédent** : l'analyse des dépendances basée sur l'analyseur Gemnasium prend en charge les projets uv à l'aide du job CI/CD `gemnasium-dependency_scanning` et de sa capacité à extraire les dépendances du projet en analysant le fichier `uv.lock`. La combinaison des versions prises en charge de uv et du fichier `uv.lock` est détaillée dans la [documentation d'analyse des dépendances (basée sur Gemnasium)](legacy_dependency_scanning/_index.md#obtaining-dependency-information-by-parsing-lockfiles).

**Nouveau comportement** : le nouvel analyseur d'analyse des dépendances extrait également les dépendances du projet en analysant le fichier `uv.lock` et génère un artefact de job de rapport SBOM CycloneDX avec le job CI/CD `dependency-scanning`.

#### Migrer un projet uv {#migrate-a-uv-project}

Migrez un projet uv pour utiliser le nouvel analyseur d'analyse des dépendances.

Prérequis :

- Effectuez [les étapes de migration génériques](#migrate-to-dependency-scanning-using-sbom) requises pour tous les projets.
- Le rôle Développeur, Chargé de maintenance ou Propriétaire pour le projet.

Il n'y a pas d'étapes supplémentaires pour migrer un projet uv vers l'analyseur d'analyse des dépendances.

### Yarn {#yarn}

**Comportement précédent** : l'analyse des dépendances basée sur l'analyseur Gemnasium prend en charge les projets Yarn à l'aide du job CI/CD `gemnasium-dependency_scanning` et de sa capacité à extraire les dépendances du projet en analysant le fichier `yarn.lock`. La combinaison des versions prises en charge de Yarn et des fichiers `yarn.lock` est détaillée dans la [documentation d'analyse des dépendances (basée sur Gemnasium)](legacy_dependency_scanning/_index.md#obtaining-dependency-information-by-parsing-lockfiles). Cet analyseur peut fournir des données de remédiation pour [résoudre une vulnérabilité via une merge request](../vulnerabilities/_index.md#resolve-a-vulnerability) pour les dépendances Yarn. Cet analyseur peut analyser les fichiers JavaScript vendorisés dans un projet Yarn à l'aide du scanner `Retire.JS`.

**Nouveau comportement** : le nouvel analyseur d'analyse des dépendances extrait également les dépendances du projet en analysant le fichier `yarn.lock` et génère un artefact de job de rapport SBOM CycloneDX avec le job CI/CD `dependency-scanning`. Cet analyseur ne fournit pas de données de remédiation pour les dépendances Yarn. Pour plus d'informations, consultez l'[annonce de dépréciation de la résolution d'une vulnérabilité pour l'analyse des dépendances sur les projets Yarn](../../../update/deprecations.md#resolve-a-vulnerability-for-dependency-scanning-on-yarn-projects). La prise en charge d'une fonctionnalité de remplacement est proposée dans l'[epic 759](https://gitlab.com/groups/gitlab-org/-/epics/759). Cet analyseur n'analyse pas les fichiers JavaScript vendorisés. Pour plus d'informations, consultez l'[annonce de dépréciation de l'analyse des dépendances pour les bibliothèques JavaScript vendorisées](../../../update/deprecations.md#dependency-scanning-for-javascript-vendored-libraries) pour le contexte et les actions disponibles. La prise en charge d'une fonctionnalité de remplacement est proposée dans l'[epic 7186](https://gitlab.com/groups/gitlab-org/-/epics/7186).

#### Migrer un projet Yarn {#migrate-a-yarn-project}

Migrez un projet Yarn pour utiliser le nouvel analyseur d'analyse des dépendances.

Prérequis :

- Effectuez [les étapes de migration génériques](#migrate-to-dependency-scanning-using-sbom) requises pour tous les projets.
- Le rôle Développeur, Chargé de maintenance ou Propriétaire pour le projet.

Il n'y a pas d'étapes supplémentaires pour migrer un projet Yarn vers l'analyseur d'analyse des dépendances. Si vous dépendiez précédemment de la fonctionnalité Résoudre une vulnérabilité via merge request ou de l'analyse des JavaScript vendorisés, consultez les annonces de dépréciation liées dans la section **New behavior** ci-dessus pour le contexte et les actions disponibles.

## Modifications des variables CI/CD {#changes-to-cicd-variables}

Le tableau suivant répertorie les variables CI/CD précédemment utilisées avec la fonctionnalité d'analyse des dépendances héritée basée sur l'analyseur Gemnasium et leur statut avec le nouvel analyseur d'analyse des dépendances :

| Variable héritée                  | Statut avec le nouvel analyseur                                                                                    |
| -------------------------------- | --------------------------------------------------------------------------------------------------------------- |
| `ADDITIONAL_CA_CERT_BUNDLE`      | Conservée. Préférez l'entrée spec `additional_ca_cert_bundle`.                                                            |
| `AST_ENABLE_MR_PIPELINES`        | Conservée.                                                                                                           |
| `DEPENDENCY_SCANNING_DISABLED`   | Conservée.                                                                                                           |
| `DS_ANALYZER_IMAGE`              | Conservée.                                                                                                           |
| `DS_EXCLUDED_ANALYZERS`          | Supprimée.                                                                                                        |
| `DS_EXCLUDED_PATHS`              | Conservée. Préférez l'entrée spec `excluded_paths`.                                                                       |
| `DS_GRADLE_RESOLUTION_POLICY`    | Supprimée.                                                                                                        |
| `DS_IMAGE_SUFFIX`                | Supprimée.                                                                                                        |
| `DS_INCLUDE_DEV_DEPENDENCIES`    | Conservée. Préférez l'entrée spec `include_dev_dependencies`.                                                             |
| `DS_JAVA_VERSION`                | Supprimée.                                                                                                        |
| `DS_MAX_DEPTH`                   | Conservée. Préférez l'entrée spec `max_scan_depth`.                                                                       |
| `DS_PIP_DEPENDENCY_PATH`         | Conservée. S'applique uniquement à la [résolution des dépendances Python](dependency_scanning_sbom/_index.md#dependency-resolution). |
| `DS_PIP_VERSION`                 | Supprimée.                                                                                                        |
| `DS_REMEDIATE`                   | Supprimée.                                                                                                        |
| `DS_REMEDIATE_TIMEOUT`           | Supprimée.                                                                                                        |
| `GEMNASIUM_DB_LOCAL_PATH`        | Supprimée.                                                                                                        |
| `GEMNASIUM_DB_REF_NAME`          | Supprimée.                                                                                                        |
| `GEMNASIUM_DB_REMOTE_URL`        | Supprimée.                                                                                                        |
| `GEMNASIUM_DB_UPDATE_DISABLED`   | Supprimée.                                                                                                        |
| `GEMNASIUM_IGNORED_SCOPES`       | Supprimée.                                                                                                        |
| `GEMNASIUM_LIBRARY_SCAN_ENABLED` | Supprimée.                                                                                                        |
| `GOARCH`                         | Supprimée.                                                                                                        |
| `GOFLAGS`                        | Supprimée.                                                                                                        |
| `GOOS`                           | Supprimée.                                                                                                        |
| `GOPRIVATE`                      | Supprimée.                                                                                                        |
| `GRADLE_CLI_OPTS`                | Conservée. S'applique uniquement à la [résolution des dépendances Gradle](dependency_scanning_sbom/_index.md#dependency-resolution). |
| `GRADLE_PLUGIN_INIT_PATH`        | Supprimée.                                                                                                        |
| `MAVEN_CLI_OPTS`                 | Remplacée par `MAVEN_ARGS`.                                                                                       |
| `PIP_EXTRA_INDEX_URL`            | Conservée. S'applique uniquement à la [résolution des dépendances Python](dependency_scanning_sbom/_index.md#dependency-resolution). |
| `PIP_INDEX_URL`                  | Conservée. S'applique uniquement à la [résolution des dépendances Python](dependency_scanning_sbom/_index.md#dependency-resolution). |
| `PIP_REQUIREMENTS_FILE`          | Remplacée par `DS_PIP_MANIFEST_FILE_NAME_PATTERN`.                                                                |
| `PIPENV_PYPI_MIRROR`             | Supprimée.                                                                                                        |
| `SBT_CLI_OPTS`                   | Supprimée.                                                                                                        |
| `SEARCH_IGNORE_HIDDEN_DIRS`      | Conservée.                                                                                                           |
| `SECURE_ANALYZERS_PREFIX`        | Conservée. Préférez l'entrée de spécification `analyzer_image_prefix`.                                                                |
| `SECURE_LOG_LEVEL`               | Conservée. Préférez l'entrée de spécification `analyzer_log_level`.                                                                   |

Les variables marquées **Supprimée** sont ignorées par le nouvel analyseur. Supprimez-les de votre configuration CI/CD, sauf si elles sont également utilisées par d'autres jobs.

Les variables marquées **Remplacée par `<new-name>`** fonctionnent encore mais sont dépréciées. Leur suppression est prévue dans la prochaine version majeure de GitLab. Mettez à jour votre configuration CI/CD pour utiliser le nouveau nom de variable CI/CD.

Les variables marquées **Conservée** sont acceptées par le nouvel analyseur et se comportent comme indiqué dans la [référence des variables CI/CD disponibles](dependency_scanning_sbom/_index.md#available-cicd-variables). Certaines variables conservées s'appliquent désormais uniquement aux jobs de résolution des dépendances et sont indiquées comme telles dans le tableau.

Pour faciliter la transition pour les configurations utilisateur existantes (comme les politiques d'exécution de scan), le modèle `v2` est rétrocompatible avec ces variables CI/CD. Lorsqu'elles sont définies, elles ont la priorité sur les `spec:inputs` correspondants introduits dans ce nouveau modèle.

Lorsque vous utilisez le modèle CI/CD `v2` directement dans `.gitlab-ci.yml`, préférez les [entrées de spécification](dependency_scanning_sbom/_index.md#available-spec-inputs) aux variables CI/CD pour configurer l'analyseur. Les entrées de spécification sont validées au moment de la création du pipeline, fournissent des messages d'erreur plus clairs et ont une portée limitée à l'inclusion du modèle. Utilisez les variables CI/CD lorsque vous configurez l'analyse des dépendances via des politiques d'exécution de scan ou des profils de configuration de sécurité, où les entrées de spécification ne sont pas encore disponibles.

### Nouvelles variables CI/CD introduites avec le modèle v2 {#new-cicd-variables-introduced-with-the-v2-template}

Le modèle `v2` ajoute les variables suivantes. Pour plus de détails, consultez les références [entrées de spécification disponibles](dependency_scanning_sbom/_index.md#available-spec-inputs) et [variables CI/CD disponibles](dependency_scanning_sbom/_index.md#available-cicd-variables).

| Variable                                   | Équivalent en entrée de spécification                   | Objectif                                                                                                                                                  |
| ------------------------------------------ | --------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `ANALYZER_ARTIFACT_DIR`                    | _(aucun)_                                | Répertoire dans lequel les rapports CycloneDX SBOM sont enregistrés.                                                                                                        |
| `DS_API_SCAN_DOWNLOAD_DELAY`               | `api_scan_download_delay`               | Délai initial avant le téléchargement des résultats du scan de vulnérabilité.                                                                                             |
| `DS_API_TIMEOUT`                           | `api_timeout`                           | Délai d'expiration pour l'API de scan SBOM d'analyse des dépendances.                                                                                                       |
| `DS_DISABLED_RESOLUTION_JOBS`              | `disabled_resolution_jobs`              | Liste séparée par des virgules des jobs de [résolution des dépendances](dependency_scanning_sbom/_index.md#dependency-resolution) à désactiver (`maven`, `gradle`, `python`). |
| `DS_ENABLE_MANIFEST_FALLBACK`              | `enable_manifest_fallback`              | Activer le [repli sur le manifeste](dependency_scanning_sbom/_index.md#manifest-fallback) lorsqu'aucun fichier de verrouillage ou export de graphe de dépendances n'est disponible.               |
| `DS_ENABLE_VULNERABILITY_SCAN`             | `enable_vulnerability_scan`             | Activer ou désactiver le scan de vulnérabilité des SBOMs générés.                                                                                                        |
| `DS_FF_LINK_COMPONENTS_TO_GIT_FILES`       | _(aucun)_                                | (version bêta) Lier les composants de la liste des dépendances aux fichiers soumis dans le dépôt au lieu des fichiers générés dynamiquement.                               |
| `DS_GRADLE_RESOLUTION_IMAGE`               | `gradle_resolution_image`               | Image utilisée par le job de résolution des dépendances Gradle.                                                                                                      |
| `DS_MAVEN_RESOLUTION_IMAGE`                | `maven_resolution_image`                | Image utilisée par le job de résolution des dépendances Maven.                                                                                                       |
| `DS_MAVEN_DEPENDENCY_PLUGIN_VERSION`       | `maven_dependency_plugin_version`       | La version de `maven-dependency-plugin` utilisée lors de la résolution des dépendances Maven.                                                                        |
| `DS_PIP_MANIFEST_FILE_NAME_PATTERN`        | `pip_manifest_file_name_pattern`        | Modèle glob pour les fichiers manifeste pip.                                                                                                                     |
| `DS_PIPCOMPILE_LOCKFILE_FILE_NAME_PATTERN` | `pipcompile_lockfile_file_name_pattern` | Modèle glob pour les fichiers de verrouillage `pip-compile`.                                                                                                                |
| `DS_PYTHON_RESOLUTION_IMAGE`               | `python_resolution_image`               | Image utilisée par le job de résolution des dépendances Python.                                                                                                      |
| `DS_STATIC_REACHABILITY_ENABLED`           | `enable_static_reachability`            | Activer l'[atteignabilité statique](static_reachability.md).                                                                                                    |
