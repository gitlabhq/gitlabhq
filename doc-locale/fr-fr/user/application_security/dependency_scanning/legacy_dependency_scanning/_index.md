---
stage: Application Security Testing
group: Composition Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Analyse des dépendances
description: "Vulnérabilités, remédiation, configuration, analyseurs et rapports."
---

<style>
table.ds-table tr:nth-child(even) {
    background-color: transparent;
}

table.ds-table td {
    border-left: 1px solid #dbdbdb;
    border-right: 1px solid #dbdbdb;
    border-bottom: 1px solid #dbdbdb;
}

table.ds-table tr td:first-child {
    border-left: 0;
}

table.ds-table tr td:last-child {
    border-right: 0;
}

table.ds-table ul {
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

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

> [!warning]
> La fonctionnalité d'analyse des dépendances basée sur l'analyseur Gemnasium est dépréciée dans GitLab 17.9 et il est proposé de la supprimer dans GitLab 20.0. Cependant, le calendrier de suppression n'est pas finalisé, et vous pouvez continuer à utiliser Gemnasium selon vos besoins. Pour plus d'informations, consultez [l'epic 15961](https://gitlab.com/groups/gitlab-org/-/epics/15961).

L'analyse des dépendances s'intègre dans vos pipelines CI/CD et s'exécute automatiquement pour identifier les vulnérabilités de sécurité dans les dépendances de votre application. En analysant les branches avant leur fusion, vous avez une visibilité immédiate des problèmes de sécurité dans les merge requests. Cela peut vous aider à prendre des décisions éclairées concernant les vulnérabilités potentielles avant de fusionner votre code.

Par défaut, l'analyse des dépendances analyse toutes les dépendances de votre code, y compris les dépendances d'exécution, de développement et transitives (imbriquées). Vous pouvez exclure facultativement les dépendances de développement de l'analyse.

- <i class="fa-youtube-play" aria-hidden="true"></i> Pour une présentation générale, voir [Dependency scanning - Advanced Security Testing](https://www.youtube.com/watch?v=TBnfbGk4c4o)<!-- Video published on 2024-04-06 -->
- <i class="fa-youtube-play" aria-hidden="true"></i> Pour une lecture interactive et une démonstration pratique de cette documentation sur l'analyse des dépendances, voir [How to use dependency scanning tutorial hands-on GitLab Application Security part 3](https://www.youtube.com/watch?v=ii05cMbJ4xQ)<!-- Video published on 2023-09-19 -->
- <i class="fa-youtube-play" aria-hidden="true"></i> Pour d'autres lectures interactives et démonstrations pratiques, voir [Get Started With GitLab Application Security Playlist](https://www.youtube.com/playlist?list=PL05JrBw4t0KrUrjDoefSkgZLx5aJYFaF9)<!-- Video published on 2023-09-19 -->

Pour l'analyse des vulnérabilités des dépendances en dehors d'un pipeline CI/CD, consultez [l'analyse continue des vulnérabilités](../../continuous_vulnerability_scanning/_index.md).

## Activer l'analyse des dépendances {#turn-on-dependency-scanning}

Suivez ces étapes pour activer l'analyse des dépendances dans votre projet.

Pour activer l'analyseur, vous pouvez :

- Activer [Auto DevOps](../../../../topics/autodevops/_index.md), qui inclut l'analyse des dépendances.
- Utiliser une merge request préconfigurée.
- Créer une [politique d'exécution de scan](../../policies/scan_execution_policies.md) qui impose l'analyse des dépendances.
- Modifier manuellement le fichier `.gitlab-ci.yml`.
- [Utiliser des composants CI/CD](#use-cicd-components)

### Utiliser une merge request préconfigurée {#use-a-preconfigured-merge-request}

Cette méthode prépare automatiquement une merge request qui inclut le modèle d'analyse des dépendances dans le fichier `.gitlab-ci.yml`. Vous fusionnez ensuite la merge request pour activer l'analyse des dépendances.

> [!note]
> Cette méthode fonctionne mieux sans fichier `.gitlab-ci.yml` existant, ou avec un fichier de configuration minimal. Si vous avez un fichier de configuration GitLab complexe, il se peut qu'il ne soit pas analysé correctement et qu'une erreur se produise. Dans ce cas, utilisez plutôt la méthode [manuelle](#edit-the-gitlab-ciyml-file-manually).

Prérequis :

- Disposer du rôle Chargé de maintenance ou Propriétaire pour le projet.
- L'étape `test` est requise dans le fichier `.gitlab-ci.yml`.
- Pour les runners auto-gérés, GitLab Runner avec l'exécuteur [`docker`](https://docs.gitlab.com/runner/executors/docker/) ou [`kubernetes`](https://docs.gitlab.com/runner/install/kubernetes/).
- Pour les runners hébergés sur GitLab.com, cette configuration est activée par défaut.

Pour activer l'analyse des dépendances :

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à** et repérez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Sécurisation** > **Configuration de la sécurité**.
1. Dans la ligne **Analyse des dépendances**, sélectionnez **Configurer avec une requête de fusion**.
1. Sélectionnez **Créer une requête de fusion**.
1. Examinez la merge request, puis sélectionnez **Fusionner**.

Les pipelines incluent désormais un job d'analyse des dépendances.

### Modifier manuellement le fichier `.gitlab-ci.yml` {#edit-the-gitlab-ciyml-file-manually}

Cette méthode nécessite de modifier manuellement le fichier `.gitlab-ci.yml` existant. Utilisez cette méthode si votre fichier de configuration GitLab CI/CD est complexe.

Prérequis :

- Disposer du rôle Chargé de maintenance ou Propriétaire pour le projet.
- L'étape `test` est requise dans le fichier `.gitlab-ci.yml`.
- Pour les runners auto-gérés, GitLab Runner avec l'exécuteur [`docker`](https://docs.gitlab.com/runner/executors/docker/) ou [`kubernetes`](https://docs.gitlab.com/runner/install/kubernetes/).
- Pour les runners hébergés sur GitLab.com, cette configuration est activée par défaut.

Pour activer l'analyse des dépendances :

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à** et repérez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Version** > **Éditeur de pipeline**.
1. Si aucun fichier `.gitlab-ci.yml` n'existe, sélectionnez **Configure pipeline**, puis supprimez le contenu d'exemple.
1. Copiez et collez ce qui suit au bas du fichier `.gitlab-ci.yml`. Si une ligne `include` existe déjà, ajoutez uniquement la ligne `template` en dessous.

   ```yaml
   include:
     - template: Jobs/Dependency-Scanning.gitlab-ci.yml
   ```

1. Sélectionnez l'onglet **Valider**, puis sélectionnez **Valider le pipeline**.

   Le message **Simulation terminée avec succès** confirme que le fichier est valide.
1. Sélectionnez l'onglet **Éditer**.
1. Remplissez les champs. N'utilisez pas la branche par défaut pour le champ **Branche**.
1. Cochez la case **Lancer une nouvelle merge request avec ces modifications**, puis sélectionnez **Valider les modifications**.
1. Remplissez les champs selon votre workflow standard, puis sélectionnez **Créer une requête de fusion**.
1. Examinez et modifiez la merge request selon votre workflow standard, puis sélectionnez **Fusionner**.

Les pipelines incluent désormais un job d'analyse des dépendances.

### utiliser les composants CI/CD {#use-cicd-components}

> [!note]
> Le composant CI/CD d'analyse des dépendances ne prend en charge que les projets Android.

Utilisez des [composants CI/CD](../../../../ci/components/_index.md) pour effectuer l'analyse des dépendances de votre application. Pour obtenir des instructions, consultez le fichier README du composant concerné.

#### Composants CI/CD disponibles {#available-cicd-components}

Voir <https://gitlab.com/explore/catalog/components/dependency-scanning>

Après avoir effectué ces étapes, vous pouvez :

- En savoir plus sur la façon de [comprendre les résultats](#understanding-the-results).
- Planifier un [déploiement progressif](#roll-out) vers d'autres projets.

## Comprendre les résultats {#understanding-the-results}

Les résultats de l'analyse des dépendances sont disponibles dans plusieurs formats. Consultez-les directement dans l'interface du pipeline, dans le rapport d'analyse détaillé ou dans le Software Bill of Materials (SBOM) généré lors de l'analyse.

### Examiner les vulnérabilités dans le pipeline {#review-vulnerabilities-in-the-pipeline}

Examinez les vulnérabilités détectées dans votre pipeline et prenez les mesures nécessaires avant la fusion de votre merge request.

Prérequis :

- Le rôle Développeur, Chargé de maintenance ou Propriétaire pour le projet

Pour examiner les résultats de l'analyse des dépendances dans un pipeline :

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à** et repérez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Compilation** > **Pipelines**.
1. Sélectionnez le pipeline.
1. Sélectionnez l'onglet **Sécurisation**.
1. Sélectionnez une vulnérabilité pour afficher ses détails, notamment :
   - Statut : indique si la vulnérabilité a été classée ou résolue.
   - Description :  explique la cause de la vulnérabilité, son impact potentiel et les étapes de remédiation recommandées.
   - Gravité :  classifiée en six niveaux selon l'impact. [En savoir plus sur les niveaux de gravité](../../vulnerabilities/severities.md).
   - Score CVSS : fournit une valeur numérique correspondant à la gravité.
   - EPSS : indique la probabilité qu'une vulnérabilité soit exploitée dans la nature.
   - Exploit connu (KEV) : indique qu'une vulnérabilité donnée a été exploitée.
   - Projet : met en évidence le projet dans lequel la vulnérabilité a été identifiée.
   - Type de rapport/scanner : explique le type de sortie et le scanner utilisé pour générer la sortie.
   - Accessible : indique si la dépendance vulnérable est utilisée dans le code.
   - Analyseur :  identifie quel analyseur a détecté la vulnérabilité.
   - Emplacement :  indique le fichier dans lequel se trouve la dépendance vulnérable.
   - Liens : preuve que la vulnérabilité est répertoriée dans diverses bases de données de référence.
   - Identifiants :  une liste de références utilisées pour classer la vulnérabilité, telles que les identifiants CVE.

### Rapport d'analyse des dépendances {#dependency-scanning-report}

L'analyse des dépendances génère un rapport contenant les détails de toutes les vulnérabilités. Le rapport est traité en interne et les résultats sont affichés dans l'interface utilisateur. Le rapport est également généré en tant qu'artefact du job d'analyse des dépendances, nommé `gl-dependency-scanning-report.json`, et est toujours généré à la racine du projet.

Pour plus de détails sur le rapport d'analyse des dépendances, consultez le [schéma du rapport d'analyse des dépendances](https://gitlab.com/gitlab-org/security-products/security-report-schemas/-/blob/master/dist/dependency-scanning-report-format.json).

### Nomenclature logicielle CycloneDX {#cyclonedx-software-bill-of-materials}

L'analyse des dépendances génère un Software Bill of Materials (SBOM) [CycloneDX](https://cyclonedx.org/) pour chaque fichier de verrouillage ou fichier de build pris en charge qu'elle détecte.

Les SBOM CycloneDX sont :

- Nommées `gl-sbom-<package-type>-<package-manager>.cdx.json`
- Disponibles en tant qu'artefacts de job du job d'analyse des dépendances
- Enregistré dans le même répertoire que le fichier de verrouillage ou les fichiers de build détectés

Par exemple, si la structure de votre projet est la suivante :

```plaintext
.
├── ruby-project/
│   └── Gemfile.lock
├── ruby-project-2/
│   └── Gemfile.lock
├── php-project/
│   └── composer.lock
└── go-project/
    └── go.sum
```

Le scanner Gemnasium génère alors les SBOMs CycloneDX suivants :

```plaintext
.
├── ruby-project/
│   ├── Gemfile.lock
│   └── gl-sbom-gem-bundler.cdx.json
├── ruby-project-2/
│   ├── Gemfile.lock
│   └── gl-sbom-gem-bundler.cdx.json
├── php-project/
│   ├── composer.lock
│   └── gl-sbom-packagist-composer.cdx.json
└── go-project/
    ├── go.sum
    └── gl-sbom-go-go.cdx.json
```

## Déploiement {#roll-out}

Après avoir vérifié les résultats de l'analyse des dépendances pour un projet unique, vous pouvez étendre son implémentation à d'autres projets :

- Utilisez [l'exécution de scan imposée](../../detect/security_configuration.md#create-a-shared-configuration) pour appliquer les paramètres d'analyse des dépendances à l'ensemble des groupes.
- Si vous avez des exigences particulières, l'analyse des dépendances avec SBOM peut être exécutée dans des [environnements hors ligne](../../offline_deployments/_index.md).

## Langages et gestionnaires de paquets pris en charge {#supported-languages-and-package-managers}

> [!note]
> L'analyse des dépendances ne prend pas en charge l'installation au moment de l'exécution de compilateurs et d'interpréteurs.

Les langages et gestionnaires de dépendances suivants sont pris en charge par l'analyse des dépendances :

<!-- markdownlint-disable MD044 -->
<table class="ds-table">
  <thead>
    <tr>
      <th>Langage</th>
      <th>Versions du langage</th>
      <th>Gestionnaire de paquets</th>
      <th>Fichiers pris en charge</th>
      <th><a href="#how-multiple-files-are-processed">Traite plusieurs fichiers ?</a></th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td>.NET</td>
      <td rowspan="2">Toutes les versions</td>
      <td rowspan="2"><a href="https://www.nuget.org/">NuGet</a></td>
      <td rowspan="2"><a href="https://learn.microsoft.com/en-us/nuget/consume-packages/package-references-in-project-files#enabling-lock-file"><code>packages.lock.json</code></a></td>
      <td rowspan="2">O</td>
    </tr>
    <tr>
      <td>C#</td>
    </tr>
    <tr>
      <td>C</td>
      <td rowspan="2">Toutes les versions</td>
      <td rowspan="2"><a href="https://conan.io/">Conan</a></td>
      <td rowspan="2"><a href="https://docs.conan.io/en/latest/versioning/lockfiles.html"><code>conan.lock</code></a></td>
      <td rowspan="2">O</td>
    </tr>
    <tr>
      <td>C++</td>
    </tr>
    <tr>
      <td>Go</td>
      <td>Toutes les versions</td>
      <td><a href="https://go.dev/">Go</a></td>
      <td>
        <ul>
          <li><code>go.sum</code></li>
        </ul>
      </td>
      <td>O</td>
    </tr>
    <tr>
      <td rowspan="2">Java et Kotlin</td>
      <td rowspan="2">
        8 LTS, 11 LTS, 17 LTS ou 21 LTS<sup>1</sup>
      </td>
      <td><a href="https://gradle.org/">Gradle</a><sup>2</sup></td>
      <td>
        <ul>
            <li><code>build.gradle</code></li>
            <li><code>build.gradle.kts</code></li>
        </ul>
      </td>
      <td>N</td>
    </tr>
    <tr>
      <td><a href="https://maven.apache.org/">Maven</a><sup>6</sup></td>
      <td><code>pom.xml</code></td>
      <td>N</td>
    </tr>
    <tr>
      <td rowspan="3">JavaScript et TypeScript</td>
      <td rowspan="3">Toutes les versions</td>
      <td><a href="https://www.npmjs.com/">npm</a></td>
      <td>
        <ul>
            <li><code>package-lock.json</code></li>
            <li><code>npm-shrinkwrap.json</code></li>
        </ul>
      </td>
      <td>O</td>
    </tr>
    <tr>
      <td><a href="https://classic.yarnpkg.com/en/">yarn</a></td>
      <td><code>yarn.lock</code></td>
      <td>O</td>
    </tr>
    <tr>
      <td><a href="https://pnpm.io/">pnpm</a><sup>3</sup></td>
      <td><code>pnpm-lock.yaml</code></td>
      <td>O</td>
    </tr>
    <tr>
      <td>PHP</td>
      <td>Toutes les versions</td>
      <td><a href="https://getcomposer.org/">Composer</a></td>
      <td><code>composer.lock</code></td>
      <td>O</td>
    </tr>
    <tr>
      <td rowspan="5">Python</td>
      <td rowspan="5">3.11<sup>7</sup></td>
      <td><a href="https://setuptools.readthedocs.io/en/latest/">setuptools</a><sup>8</sup></td>
      <td><code>setup.py</code></td>
      <td>N</td>
    </tr>
    <tr>
      <td><a href="https://pip.pypa.io/en/stable/">pip</a></td>
      <td>
        <ul>
            <li><code>requirements.txt</code></li>
            <li><code>requirements.pip</code></li>
            <li><code>requires.txt</code></li>
        </ul>
      </td>
      <td>N</td>
    </tr>
    <tr>
      <td><a href="https://pipenv.pypa.io/en/latest/">Pipenv</a></td>
      <td>
        <ul>
            <li><a href="https://pipenv.pypa.io/en/latest/pipfile.html#example-pipfile"><code>Pipfile</code></a></li>
            <li><a href="https://pipenv.pypa.io/en/latest/pipfile.html#example-pipfile-lock"><code>Pipfile.lock</code></a></li>
        </ul>
      </td>
      <td>N</td>
    </tr>
    <tr>
      <td><a href="https://python-poetry.org/">Poetry</a><sup>4</sup></td>
      <td><code>poetry.lock</code></td>
      <td>N</td>
    </tr>
    <tr>
      <td><a href="https://docs.astral.sh/uv/">uv</a><sup>11</sup></td>
      <td><code>uv.lock</code></td>
      <td>O</td>
    </tr>
    <tr>
      <td>Ruby</td>
      <td>Toutes les versions</td>
      <td><a href="https://bundler.io/">Bundler</a></td>
      <td>
        <ul>
            <li><code>Gemfile.lock</code></li>
            <li><code>gems.locked</code></li>
        </ul>
      </td>
      <td>O</td>
    </tr>
    <tr>
      <td>Scala</td>
      <td>Toutes les versions</td>
      <td><a href="https://www.scala-sbt.org/">sbt</a><sup>5</sup></td>
      <td><code>build.sbt</code></td>
      <td>N</td>
    </tr>
    <tr>
      <td>Swift</td>
      <td>Toutes les versions</td>
      <td><a href="https://swift.org/package-manager/">Swift Package Manager</a></td>
      <td><code>Package.resolved</code></td>
      <td>N</td>
    </tr>
    <tr>
      <td>CocoaPods<sup>9</sup></td>
      <td>Toutes les versions</td>
      <td><a href="https://cocoapods.org/">CocoaPods</a></td>
      <td><code>Podfile.lock</code></td>
      <td>N</td>
    </tr>
    <tr>
      <td>Dart<sup>10</sup></td>
      <td>Toutes les versions</td>
      <td><a href="https://pub.dev/">Pub</a></td>
      <td><code>pubspec.lock</code></td>
      <td>N</td>
    </tr>
  </tbody>
</table>

<!-- markdownlint-disable MD029 -->

**Notes de bas de page** :

1. Java 21 LTS pour [sbt](https://www.scala-sbt.org/) est limité à la version 1.9.7. La prise en charge d'autres versions de sbt peut être suivie dans le [ticket 430335](https://gitlab.com/gitlab-org/gitlab/-/issues/430335). Non pris en charge lorsque le mode FIPS est activé.
2. Gradle n'est pas pris en charge lorsque le mode FIPS est activé.
3. Les fichiers de verrouillage pnpm ne stockent pas les dépendances groupées ; les dépendances signalées peuvent donc différer de celles de npm ou yarn.
4. La prise en charge des projets sans fichier `poetry.lock` est suivie dans le [ticket 32774](https://gitlab.com/gitlab-org/gitlab/-/issues/32774).
5. La prise en charge de sbt 1.0.x a été [dépréciée](https://gitlab.com/gitlab-org/gitlab/-/issues/415835) dans GitLab 16.8 et [supprimée](https://gitlab.com/gitlab-org/gitlab/-/issues/436985) dans GitLab 17.0.
6. La prise en charge de Maven antérieur à la version 3.8.8 a été [dépréciée](https://gitlab.com/gitlab-org/gitlab/-/issues/438772) dans GitLab 16.9 et supprimée dans GitLab 17.0.
7. La prise en charge des versions antérieures de Python a été [dépréciée](https://gitlab.com/gitlab-org/gitlab/-/issues/441201) dans GitLab 16.9 et [supprimée](https://gitlab.com/gitlab-org/gitlab/-/issues/441491) dans GitLab 17.0.
8. Exclut à la fois `pip` et `setuptools` du rapport, car ils sont requis par le programme d'installation.
9. SBOM uniquement, sans avis de sécurité. Voir le [ticket 468764](https://gitlab.com/gitlab-org/gitlab/-/issues/468764).
10. Aucune détection de licence. Voir l'[epic 17037](https://gitlab.com/groups/gitlab-org/-/epics/17037).
11. Si un fichier de verrouillage contient plusieurs entrées pour le même paquet avec des marqueurs d'environnement différents (par exemple, numpy==2.2.6 pour Python <3.11 et numpy==2.4.1 pour Python ≥3.11), seule la première entrée est analysée et signalée.

<!-- markdownlint-enable MD029 -->
<!-- markdownlint-enable MD044 -->

## Dépendances de développement prises en charge {#supported-development-dependencies}

La détection des dépendances de développement est prise en charge pour les langages et gestionnaires de paquets suivants :

<!-- vale gitlab_base.Substitutions = NO -->
<!-- markdownlint-disable MD044 -->

| Langage                  | Gestionnaire de paquets | Fichiers |
|---------------------------|-----------------|-------|
| C/C++/Fortran/Go/Python/R | conda           | `conda-lock.yml` |
| Java                      | Maven           | `maven.graph.json` |
| Java/Kotlin               | Gradle          | `dependencies.lock`, `dependencies.direct.lock`, `gradle-html-dependency-report.js`, `gradle.lockfile` |
| JavaScript/TypeScript     | npm             | `package-lock.json`, `npm-shrinkwrap.json` |
| JavaScript/TypeScript     | pnpm            | `pnpm-lock.yaml` |
| PHP                       | Composer        | `composer.lock` |
| Python                    | Pipenv          | `Pipfile.lock` |
| Python                    | Poetry          | `poetry.lock` |
| Python                    | uv              | `uv.lock` |

<!-- markdownlint-enable MD044 -->
<!-- vale gitlab_base.Substitutions = YES -->

## Exécution des jobs dans les pipelines de merge request {#running-jobs-in-merge-request-pipelines}

Voir [Utiliser les outils d'analyse de sécurité avec les pipelines de merge request](../../detect/security_configuration.md#use-security-scanning-tools-with-merge-request-pipelines)

## Personnalisation du comportement de l'analyseur {#customizing-analyzer-behavior}

Pour personnaliser l'analyse des dépendances, utilisez les [variables CI/CD](#available-cicd-variables).

> [!warning]
> Testez toutes les personnalisations des analyseurs GitLab dans une merge request avant de fusionner ces modifications dans la branche par défaut. Ne pas le faire peut donner des résultats inattendus, y compris un grand nombre de faux positifs.

### Remplacement des jobs d'analyse des dépendances {#overriding-dependency-scanning-jobs}

Pour remplacer une définition de job (par exemple, pour modifier des propriétés telles que `variables` ou `dependencies`), déclarez un nouveau job portant le même nom que celui à remplacer. Placez ce nouveau job après l'inclusion du template et spécifiez les clés supplémentaires sous celui-ci.

Par exemple, cette configuration désactive la remédiation automatique des dépendances vulnérables pour l'analyseur `gemnasium` :

```yaml
include:
  - template: Jobs/Dependency-Scanning.gitlab-ci.yml

gemnasium-dependency_scanning:
  variables:
    DS_REMEDIATE: "false"
```

Pour remplacer l'attribut `dependencies: []`, ajoutez un job de remplacement comme décrit précédemment, en ciblant cet attribut :

```yaml
include:
  - template: Jobs/Dependency-Scanning.gitlab-ci.yml

gemnasium-dependency_scanning:
  dependencies: ["build"]
```

### Variables CI/CD disponibles {#available-cicd-variables}

Vous pouvez utiliser des variables CI/CD pour [personnaliser](#customizing-analyzer-behavior) le comportement de l'analyse des dépendances.

#### Paramètres globaux de l'analyseur {#global-analyzer-settings}

Les variables suivantes permettent de configurer les paramètres globaux de l'analyse des dépendances.

| Variables CI/CD             | Description |
| ----------------------------|------------ |
| `ADDITIONAL_CA_CERT_BUNDLE` | Lot de certificats CA à approuver. Le lot de certificats fourni ici est également utilisé par d'autres outils au cours du processus d'analyse, tels que `git`, `yarn` ou `npm`. Pour plus de détails, consultez [Autorité de certification TLS personnalisée](#custom-tls-certificate-authority). |
| `DS_EXCLUDED_ANALYZERS`     | Spécifier les analyseurs (par nom) à exclure de l'analyse des dépendances. Pour plus d'informations, voir [Analyseurs](#analyzers). |
| `DS_EXCLUDED_PATHS`         | Exclure les fichiers et répertoires de l'analyse en fonction des chemins. Une liste de modèles séparés par des virgules. Les modèles peuvent être des globs (voir [`doublestar.Match`](https://pkg.go.dev/github.com/bmatcuk/doublestar/v4@v4.0.2#Match) pour les modèles pris en charge), ou des chemins de fichiers ou de dossiers (par exemple, `doc,spec`). Les répertoires parents correspondent également aux modèles. Il s'agit d'un pré-filtre appliqué avant l'exécution de l'analyse. Par défaut : `"spec, test, tests, tmp"`. |
| `DS_IMAGE_SUFFIX`           | Suffixe ajouté au nom de l'image. (Les membres de l'équipe GitLab peuvent consulter plus d'informations dans ce ticket confidentiel : `https://gitlab.com/gitlab-org/gitlab/-/issues/354796`). Définie automatiquement sur `"-fips"` lorsque le mode FIPS est activé. |
| `DS_MAX_DEPTH`              | Définit le nombre de niveaux de répertoires en profondeur que l'analyseur doit rechercher pour les fichiers pris en charge à analyser. Une valeur de `-1` analyse tous les répertoires quelle que soit la profondeur. Par défaut : `2`. |
| `SECURE_ANALYZERS_PREFIX`   | Remplacer le nom du registre Docker fournissant les images officielles par défaut (proxy). |

#### Paramètres spécifiques à l'analyseur {#analyzer-specific-settings}

Les variables suivantes configurent le comportement d'analyseurs d'analyse des dépendances spécifiques.

| Variable CI/CD                       | Analyseur           | Valeur par défaut                      | Description |
|--------------------------------------|--------------------|------------------------------|-------------|
| `GEMNASIUM_DB_LOCAL_PATH`            | `gemnasium`        | `/gemnasium-db`              | Chemin vers la base de données Gemnasium locale. |
| `GEMNASIUM_DB_UPDATE_DISABLED`       | `gemnasium`        | `"false"`                    | Désactive les mises à jour automatiques de la base de données de référence `gemnasium-db`. Pour l'utilisation, voir [Accès à la base de données de référence GitLab](#access-to-the-gitlab-advisory-database). |
| `GEMNASIUM_DB_REMOTE_URL`            | `gemnasium`        | `https://gitlab.com/gitlab-org/security-products/gemnasium-db.git` | URL du dépôt pour récupérer la base de données de référence GitLab. |
| `GEMNASIUM_DB_REF_NAME`              | `gemnasium`        | `master`                     | Nom de la branche pour la base de données du dépôt distant. `GEMNASIUM_DB_REMOTE_URL` est requis. |
| `GEMNASIUM_IGNORED_SCOPES`           | `gemnasium`        |                              | Liste séparée par des virgules des portées de dépendances Maven à ignorer. Pour plus de détails, voir la [documentation sur les portées de dépendances Maven](https://maven.apache.org/guides/introduction/introduction-to-dependency-mechanism.html#Dependency_Scope) |
| `DS_REMEDIATE`                       | `gemnasium`        | `"true"`, `"false"` en mode FIPS | Active la remédiation automatique des dépendances vulnérables. Non pris en charge en mode FIPS. |
| `DS_REMEDIATE_TIMEOUT`               | `gemnasium`        | `5m`                         | Délai d'expiration pour la remédiation automatique. |
| `GEMNASIUM_LIBRARY_SCAN_ENABLED`     | `gemnasium`        | `"true"`                     | Active la détection des vulnérabilités dans les bibliothèques JavaScript intégrées (bibliothèques qui ne sont pas gérées par un gestionnaire de paquets). Cette fonctionnalité nécessite la présence d'un fichier de verrouillage JavaScript dans un commit, sinon l'analyse des dépendances n'est pas exécutée et les fichiers intégrés ne sont pas analysés.<br>L'analyse des dépendances utilise le scanner [Retire.js](https://github.com/RetireJS/retire.js) pour détecter un ensemble limité de vulnérabilités. Pour plus de détails sur les vulnérabilités détectées, consultez le [dépôt Retire.js](https://github.com/RetireJS/retire.js/blob/master/repository/jsrepository.json). |
| `DS_INCLUDE_DEV_DEPENDENCIES`        | `gemnasium`        | `"true"`                     | Lorsque cette option est définie sur `"false"`, les dépendances de développement et leurs vulnérabilités ne sont pas signalées. Seuls les projets utilisant Composer, Maven, npm, pnpm, Pipenv ou Poetry sont pris en charge. |
| `GOOS`                               | `gemnasium`        | `"linux"`                    | Le système d'exploitation pour lequel compiler le code Go. |
| `GOARCH`                             | `gemnasium`        | `"amd64"`                    | L'architecture du processeur pour lequel compiler le code Go. |
| `GOFLAGS`                            | `gemnasium`        |                              | Les indicateurs transmis à l'outil `go build`. |
| `GOPRIVATE`                          | `gemnasium`        |                              | Une liste de modèles glob et de préfixes à récupérer depuis la source. Pour plus d'informations, consultez la [documentation](https://go.dev/ref/mod#private-modules) sur les modules privés Go. |
| `DS_JAVA_VERSION`                    | `gemnasium-maven`  | `17`                         | Version de Java. Versions disponibles : `8`, `11`, `17`, `21`. |
| `MAVEN_CLI_OPTS`                     | `gemnasium-maven`  | `"-DskipTests --batch-mode"` | Liste d'arguments de ligne de commande transmis à `maven` par l'analyseur. Voir un exemple pour [l'utilisation de dépôts privés](#authenticate-with-a-private-maven-repository). |
| `GRADLE_CLI_OPTS`                    | `gemnasium-maven`  |                              | Liste d'arguments de ligne de commande transmis à `gradle` par l'analyseur. |
| `GRADLE_PLUGIN_INIT_PATH`            | `gemnasium-maven`  | `"gemnasium-init.gradle"`    | Spécifie le chemin vers le script d'initialisation Gradle. Le script d'initialisation doit inclure `allprojects { apply plugin: 'project-report' }` pour assurer la compatibilité. |
| `DS_GRADLE_RESOLUTION_POLICY`        | `gemnasium-maven`  | `"failed"`                   | Contrôle la rigueur de la résolution des dépendances Gradle. Accepte `"none"` pour autoriser des résultats partiels, ou `"failed"` pour faire échouer l'analyse lorsque des dépendances ne parviennent pas à être résolues. |
| `SBT_CLI_OPTS`                       | `gemnasium-maven`  |                              | Liste d'arguments de ligne de commande que l'analyseur transmet à `sbt`. |
| `PIP_INDEX_URL`                      | `gemnasium-python` | `https://pypi.org/simple`    | URL de base de l'index de paquets Python. |
| `PIP_EXTRA_INDEX_URL`                | `gemnasium-python` |                              | Tableau d'[URL supplémentaires](https://pip.pypa.io/en/stable/reference/pip_install/#cmdoption-extra-index-url) d'index de paquets à utiliser en plus de `PIP_INDEX_URL`. Séparées par des virgules. **Avertissement** : lisez [la considération de sécurité suivante](#python-projects) lorsque vous utilisez cette variable d'environnement. |
| `PIP_REQUIREMENTS_FILE`              | `gemnasium-python` |                              | Fichier de prérequis pip à analyser. Il s'agit d'un nom de fichier, pas d'un chemin. Lorsque cette variable d'environnement est définie, seul le fichier spécifié est analysé. |
| `PIPENV_PYPI_MIRROR`                 | `gemnasium-python` |                              | Si définie, remplace l'index PyPi utilisé par Pipenv par un [miroir](https://github.com/pypa/pipenv/blob/v2022.1.8/pipenv/environments.py#L263). |
| `DS_PIP_VERSION`                     | `gemnasium-python` |                              | Force l'installation d'une version spécifique de pip (exemple : `"19.3"`), sinon la version de pip installée dans l'image Docker est utilisée. |
| `DS_PIP_DEPENDENCY_PATH`             | `gemnasium-python` |                              | Chemin à partir duquel charger les dépendances pip Python. |

#### Autres variables {#other-variables}

Les tableaux précédents ne constituent pas une liste exhaustive de toutes les variables pouvant être utilisées. Ils contiennent toutes les variables spécifiques à GitLab et à l'analyseur qui sont prises en charge et testées. De nombreuses autres variables, telles que les variables d'environnement, peuvent être transmises et fonctionner correctement. Cette liste est volumineuse et n'est pas entièrement documentée.

Par exemple, pour transmettre la variable d'environnement non-GitLab `HTTPS_PROXY` à tous les jobs d'analyse des dépendances, définissez-la en tant que [variable CI/CD dans votre fichier `.gitlab-ci.yml`](../../../../ci/variables/_index.md#define-a-cicd-variable-in-the-gitlab-ciyml-file) comme suit :

```yaml
variables:
  HTTPS_PROXY: "https://squid-proxy:3128"
```

> [!note]
> Les projets Gradle nécessitent [une variable supplémentaire](#use-a-proxy-with-gradle-projects) pour utiliser un proxy.

Elle peut également être utilisée dans des jobs spécifiques, comme l'analyse des dépendances :

```yaml
dependency_scanning:
  variables:
    HTTPS_PROXY: $HTTPS_PROXY
```

Étant donné que toutes les variables n'ont pas été testées, certaines peuvent fonctionner et d'autres non. Si vous avez besoin d'une variable qui ne fonctionne pas, [soumettez une demande de fonctionnalité](https://gitlab.com/gitlab-org/gitlab/-/issues/new?description_template=Feature%20proposal%20-%20detailed&issue[title]=Docs%20feedback%20-%20feature%20proposal:%20Write%20your%20title) ou contribuez au code pour permettre son utilisation.

### Autorité de certification TLS personnalisée {#custom-tls-certificate-authority}

L'analyse des dépendances permet l'utilisation de certificats TLS personnalisés pour les connexions SSL/TLS à la place de ceux fournis par défaut avec l'image de conteneur de l'analyseur.

La prise en charge des autorités de certification personnalisées a été introduite dans les versions suivantes.

| Analyseur           | Version                                                                                                |
|--------------------|--------------------------------------------------------------------------------------------------------|
| `gemnasium`        | [v2.8.0](https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium/-/releases/v2.8.0)        |
| `gemnasium-maven`  | [v2.9.0](https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium-maven/-/releases/v2.9.0)  |
| `gemnasium-python` | [v2.7.0](https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium-python/-/releases/v2.7.0) |

#### Utiliser une autorité de certification TLS personnalisée {#use-a-custom-tls-certificate-authority}

Prérequis :

- Disposer du rôle Chargé de maintenance ou Propriétaire pour le projet.

Pour utiliser une autorité de certification TLS personnalisée :

- Attribuez la [représentation textuelle du certificat à clé publique X.509 PEM](https://www.rfc-editor.org/rfc/rfc7468#section-5.1) à la variable CI/CD `ADDITIONAL_CA_CERT_BUNDLE`.

Par exemple, pour configurer le certificat dans le fichier `.gitlab-ci.yml` :

```yaml
variables:
  ADDITIONAL_CA_CERT_BUNDLE: |
      -----BEGIN CERTIFICATE-----
      MIIGqTCCBJGgAwIBAgIQI7AVxxVwg2kch4d56XNdDjANBgkqhkiG9w0BAQsFADCB
      ...
      jWgmPqF3vUbZE0EyScetPJquRFRKIesyJuBFMAs=
      -----END CERTIFICATE-----
```

### S'authentifier auprès d'un dépôt Maven privé {#authenticate-with-a-private-maven-repository}

Pour permettre à l'analyseur de dépendances de s'authentifier auprès d'un dépôt Maven privé, vous devez configurer des informations d'identification dans le pipeline CI/CD. Sans authentification, l'analyseur de dépendances ne peut pas accéder aux dépendances privées et l'analyse échouera.

> [!warning]
> N'ajoutez pas les informations d'identification à votre fichier `.gitlab-ci.yml`.

Prérequis :

- Disposer du rôle Chargé de maintenance ou Propriétaire pour le projet.

Pour permettre à l'analyseur de dépendances de s'authentifier auprès d'un dépôt Maven privé :

1. [Créez une variable CI/CD de projet](../../../../ci/variables/_index.md#for-a-project) nommée `MAVEN_CLI_OPTS` et définissez sa valeur pour inclure vos informations d'identification.

   Par exemple, en supposant un fichier de paramètres nommé `mysettings.xml`, un nom d'utilisateur `myuser` et un mot de passe `verysecret`, vous définiriez la variable CI/CD `MAVEN_CLI_OPTS` comme suit :

   `--settings mysettings.xml -Drepository.password=verysecret -Drepository.user=myuser`
1. Créez le fichier de paramètres Maven `mysettings.xml` avec la configuration de votre serveur. Le nom de fichier doit correspondre à la valeur que vous avez spécifiée dans l'option `--settings` à l'étape 1.

   ```xml
   <!-- mysettings.xml -->
   <settings>
       ...
       <servers>
           <server>
               <id>private_server</id>
               <username>${repository.user}</username>
               <password>${repository.password}</password>
           </server>
       </servers>
   </settings>
   ```

### Images compatibles FIPS {#fips-enabled-images}

GitLab propose également des versions [Red Hat UBI compatibles FIPS](https://www.redhat.com/en/blog/introducing-red-hat-universal-base-image) des images Gemnasium. Lorsque le mode FIPS est activé dans l'instance GitLab, les jobs d'analyse Gemnasium utilisent automatiquement les images compatibles FIPS. Pour passer manuellement aux images compatibles FIPS, définissez la variable `DS_IMAGE_SUFFIX` sur `"-fips"`.

L'analyse des dépendances pour les projets Gradle et la remédiation automatique pour les projets Yarn ne sont pas prises en charge en mode FIPS.

Les images compatibles FIPS sont basées sur UBI micro de RedHat. Elles ne disposent pas de gestionnaires de paquets tels que `dnf` ou `microdnf`, ce qui rend impossible l'installation de paquets système au moment de l'exécution.

### Environnement hors ligne {#offline-environment}

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

Pour les instances dans un environnement avec un accès limité, restreint ou intermittent aux ressources externes via Internet, certains ajustements sont nécessaires pour que les jobs d'analyse des dépendances s'exécutent correctement. Pour plus d'informations, consultez [Environnements hors ligne](../../offline_deployments/_index.md).

Prérequis :

- Disposer d'un accès administrateur
- Un GitLab Runner avec l'exécuteur `docker` ou `kubernetes`
- Copies locales des images d'analyseur d'analyse des dépendances
- Accès à la [base de données de référence GitLab](https://gitlab.com/gitlab-org/security-products/gemnasium-db)
- Accès à la [base de données de métadonnées des paquets](../../../../topics/offline/quick_start_guide.md#enabling-the-package-metadata-database)

#### Copies locales des images d'analyseur {#local-copies-of-analyzer-images}

Pour utiliser l'analyse des dépendances avec tous les [langages et frameworks pris en charge](#supported-languages-and-package-managers) :

1. Importez les images d'analyseur d'analyse des dépendances par défaut suivantes depuis `registry.gitlab.com` dans votre [registre de conteneurs Docker local](../../../packages/container_registry/_index.md) :

   ```plaintext
   registry.gitlab.com/security-products/gemnasium:6
   registry.gitlab.com/security-products/gemnasium:6-fips
   registry.gitlab.com/security-products/gemnasium-maven:6
   registry.gitlab.com/security-products/gemnasium-maven:6-fips
   registry.gitlab.com/security-products/gemnasium-python:6
   registry.gitlab.com/security-products/gemnasium-python:6-fips
   ```

   Le processus d'importation des images Docker dans un registre de conteneurs Docker hors ligne local dépend de **votre politique de sécurité réseau**. Consultez votre service informatique pour trouver un processus accepté et approuvé par lequel les ressources externes peuvent être importées ou accessibles temporairement. Ces scanners sont [mis à jour périodiquement](../../detect/vulnerability_scanner_maintenance.md) avec de nouvelles définitions, et vous souhaiterez peut-être les télécharger régulièrement.
1. Configurez GitLab CI/CD pour utiliser les analyseurs locaux.

   Définissez la valeur de la variable CI/CD `SECURE_ANALYZERS_PREFIX` sur votre registre Docker local - dans cet exemple, `docker-registry.example.com`.

   ```yaml
   include:
     - template: Jobs/Dependency-Scanning.gitlab-ci.yml

   variables:
     SECURE_ANALYZERS_PREFIX: "docker-registry.example.com/analyzers"
   ```

#### Accès à la base de données de référence GitLab {#access-to-the-gitlab-advisory-database}

La [base de données de référence GitLab](https://gitlab.com/gitlab-org/security-products/gemnasium-db) est la source de données sur les vulnérabilités utilisée par les analyseurs `gemnasium`, `gemnasium-maven` et `gemnasium-python`. Les images Docker de ces analyseurs incluent un clone de la base de données. Le clone est synchronisé avec la base de données avant le démarrage d'une analyse, afin de garantir que les analyseurs disposent des dernières données sur les vulnérabilités.

Dans un environnement hors ligne, l'hôte par défaut de la base de données de référence GitLab n'est pas accessible. Vous devez donc héberger la base de données à un emplacement accessible aux runners GitLab. Vous devez également mettre à jour la base de données manuellement selon votre propre calendrier.

Les options disponibles pour héberger la base de données sont :

- [Utiliser un clone de la base de données de référence GitLab](#use-a-copy-of-the-gitlab-advisory-database).
- [Utiliser une copie de la base de données de référence GitLab](#use-a-copy-of-the-gitlab-advisory-database).

##### Utiliser un clone de la base de données de référence GitLab {#use-a-clone-of-the-gitlab-advisory-database}

L'utilisation d'un clone de la base de données de référence GitLab est recommandée car c'est la méthode la plus efficace.

Pour héberger un clone de la base de données de référence GitLab :

1. Clonez la base de données de référence GitLab vers un hôte accessible par HTTP depuis les runners GitLab.
1. Dans votre fichier `.gitlab-ci.yml`, définissez la valeur de la variable CI/CD `GEMNASIUM_DB_REMOTE_URL` sur l'URL du dépôt Git.

Par exemple :

```yaml
variables:
  GEMNASIUM_DB_REMOTE_URL: https://users-own-copy.example.com/gemnasium-db.git
```

##### Utiliser une copie de la base de données de référence GitLab {#use-a-copy-of-the-gitlab-advisory-database}

L'utilisation d'une copie de la base de données de référence GitLab nécessite d'héberger un fichier d'archive téléchargé par les analyseurs.

Pour utiliser une copie de la base de données de référence GitLab :

1. Téléchargez une archive de la base de données de référence GitLab vers un hôte accessible par HTTP depuis les runners GitLab. L'archive se trouve à l'adresse `https://gitlab.com/gitlab-org/security-products/gemnasium-db/-/archive/master/gemnasium-db-master.tar.gz`.
1. Mettez à jour votre fichier `.gitlab-ci.yml`.

   - Définissez la variable CI/CD `GEMNASIUM_DB_LOCAL_PATH` pour utiliser la copie locale de la base de données.
   - Définissez la variable CI/CD `GEMNASIUM_DB_UPDATE_DISABLED` pour désactiver la mise à jour de la base de données.
   - Téléchargez et extrayez la base de données de référence avant le début de l'analyse.

   ```yaml
   variables:
     GEMNASIUM_DB_LOCAL_PATH: ./gemnasium-db-local
     GEMNASIUM_DB_UPDATE_DISABLED: "true"

   dependency_scanning:
     before_script:
       - wget https://local.example.com/gemnasium_db.tar.gz
       - mkdir -p $GEMNASIUM_DB_LOCAL_PATH
       - tar -xzvf gemnasium_db.tar.gz --strip-components=1 -C $GEMNASIUM_DB_LOCAL_PATH
   ```

### Utiliser un proxy avec des projets Gradle {#use-a-proxy-with-gradle-projects}

Le script wrapper Gradle ne lit pas les variables d'environnement `HTTP(S)_PROXY`. Pour plus de détails, voir le [problème Gradle 11065](https://github.com/gradle/gradle/issues/11065).

Prérequis :

- Disposer du rôle Chargé de maintenance ou Propriétaire pour le projet.

Pour que le script wrapper Gradle utilise un proxy :

- Spécifiez les options de proxy en utilisant la variable CI/CD `GRADLE_CLI_OPTS` :

  ```yaml
  variables:
    GRADLE_CLI_OPTS: "-Dhttps.proxyHost=squid-proxy -Dhttps.proxyPort=3128 -Dhttp.proxyHost=squid-proxy -Dhttp.proxyPort=3128 -Dhttp.nonProxyHosts=localhost"
  ```

### Utiliser un proxy avec des projets Maven {#use-a-proxy-with-maven-projects}

Maven ne lit pas la variable d'environnement `HTTP(S)_PROXY`. Vous devez à la place utiliser un fichier de paramètres Maven.

Prérequis :

- Disposer du rôle Chargé de maintenance ou Propriétaire pour le projet.

Pour configurer le scanner de dépendances Maven afin d'utiliser un proxy :

1. Créez un fichier `mysettings.xml` dans le dépôt du projet. Configurez les paramètres du proxy Maven dans ce fichier.

   Pour plus de détails sur la façon de spécifier la configuration du proxy, consultez la [documentation Maven](https://maven.apache.org/guides/mini/guide-proxies.html).
1. Définissez la variable CI/CD `MAVEN_CLI_OPTS` dans le fichier `.gitlab-ci.yml` de votre projet pour référencer le fichier de paramètres `mysettings.xml`.

   ```yaml
   variables:
     MAVEN_CLI_OPTS: "--settings mysettings.xml"
   ```

### Paramètres spécifiques aux langages et aux gestionnaires de paquets {#specific-settings-for-languages-and-package-managers}

Consultez les sections suivantes pour configurer des langages et des gestionnaires de paquets spécifiques.

#### Python (pip) {#python-pip}

Si vous devez installer des paquets Python avant l'exécution de l'analyseur, utilisez `pip install --user` dans le `before_script` du job d'analyse. L'indicateur `--user` entraîne l'installation des dépendances du projet dans le répertoire utilisateur. Si vous ne transmettez pas l'option `--user`, les paquets sont installés globalement, et ils ne sont pas analysés et n'apparaissent pas lors de la liste des dépendances du projet.

#### Python (setuptools) {#python-setuptools}

Si vous devez installer des paquets Python avant l'exécution de l'analyseur, utilisez `python setup.py install --user` dans le `before_script` du job d'analyse. L'indicateur `--user` entraîne l'installation des dépendances du projet dans le répertoire utilisateur. Si vous ne transmettez pas l'option `--user`, les paquets sont installés globalement, et ils ne sont pas analysés et n'apparaissent pas lors de la liste des dépendances du projet.

Lors de l'utilisation de certificats auto-signés pour votre dépôt PyPi privé, aucune configuration supplémentaire de job (hormis le modèle `.gitlab-ci.yml` précédent) n'est nécessaire. Cependant, vous devez mettre à jour votre `setup.py` pour vous assurer qu'il peut atteindre votre dépôt privé. Voici un exemple de configuration :

1. Mettez à jour `setup.py` pour créer un attribut `dependency_links` pointant vers votre dépôt privé pour chaque dépendance dans la liste `install_requires` :

   ```python
   install_requires=['pyparsing>=2.0.3'],
   dependency_links=['https://pypi.example.com/simple/pyparsing'],
   ```

1. Récupérez le certificat depuis l'URL de votre dépôt et ajoutez-le au projet :

   ```shell
   printf "\n" | openssl s_client -connect pypi.example.com:443 -servername pypi.example.com | sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p' > internal.crt
   ```

1. Pointez `setup.py` vers le certificat nouvellement téléchargé :

   ```python
   import setuptools.ssl_support
   setuptools.ssl_support.cert_paths = ['internal.crt']
   ```

#### Python (Pipenv) {#python-pipenv}

Si vous opérez dans un environnement à connectivité réseau limitée, vous devez configurer la variable `PIPENV_PYPI_MIRROR` pour utiliser un miroir PyPi privé. Ce miroir doit contenir à la fois les dépendances par défaut et les dépendances de développement.

```yaml
variables:
  PIPENV_PYPI_MIRROR: https://pypi.example.com/simple
```

<!-- markdownlint-disable MD044 -->
Alternativement, s'il n'est pas possible d'utiliser un registre privé, vous pouvez charger les paquets requis dans le cache de l'environnement virtuel Pipenv. Pour cette option, le projet doit enregistrer le fichier `Pipfile.lock` dans le dépôt et charger à la fois les paquets par défaut et de développement dans le cache. Consultez l'exemple de projet [python-pipenv](https://gitlab.com/gitlab-org/security-products/tests/python-pipenv/-/blob/41cc017bd1ed302f6edebcfa3bc2922f428e07b6/.gitlab-ci.yml#L20-42) pour voir comment procéder.
<!-- markdownlint-enable MD044 -->

## Détection des dépendances {#dependency-detection}

L'analyse des dépendances détecte automatiquement les langages utilisés dans le dépôt. Tous les analyseurs correspondant aux langages détectés sont exécutés. Il n'est généralement pas nécessaire de personnaliser la sélection des analyseurs. Ne spécifiez pas les analyseurs afin d'utiliser automatiquement la sélection complète pour une meilleure couverture, et évitez d'avoir à effectuer des ajustements en cas de dépréciations ou de suppressions. Cependant, vous pouvez remplacer la sélection en utilisant la variable `DS_EXCLUDED_ANALYZERS`.

La détection du langage repose sur les [`rules`](../../../../ci/yaml/_index.md#rules) du job CI pour détecter le [fichier de dépendances pris en charge](#how-analyzers-are-triggered)

Pour Java et Python, lorsqu'un fichier de dépendances pris en charge est détecté, l'analyse des dépendances tente de construire le projet et d'exécuter certaines commandes Java ou Python pour obtenir la liste des dépendances. Pour tous les autres projets, le fichier de verrouillage est analysé pour obtenir la liste des dépendances sans avoir à construire le projet au préalable.

Toutes les dépendances directes et transitives sont analysées, sans limite de profondeur pour les dépendances transitives.

### Analyseurs {#analyzers}

L'analyse des dépendances prend en charge les analyseurs officiels [basés sur Gemnasium](https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium) suivants :

- `gemnasium`
- `gemnasium-maven`
- `gemnasium-python`

Les analyseurs sont publiés sous forme d'images Docker, que l'analyse des dépendances utilise pour lancer des conteneurs dédiés à chaque analyse. Vous pouvez également intégrer un scanner de sécurité personnalisé.

Chaque analyseur est mis à jour à mesure que de nouvelles versions de Gemnasium sont publiées.

### Comment les analyseurs obtiennent les informations sur les dépendances {#how-analyzers-obtain-dependency-information}

Les analyseurs GitLab obtiennent les informations sur les dépendances à l'aide de l'une des deux méthodes suivantes :

1. [Analyse directe des fichiers de verrouillage.](#obtaining-dependency-information-by-parsing-lockfiles)
1. [Exécution d'un gestionnaire de paquets ou d'un outil de build pour générer un fichier d'informations sur les dépendances qui est ensuite analysé.](#obtaining-dependency-information-by-running-a-package-manager-to-generate-a-parsable-file)

#### Obtention des informations sur les dépendances par analyse des fichiers de verrouillage {#obtaining-dependency-information-by-parsing-lockfiles}

Les gestionnaires de paquets suivants utilisent des fichiers de verrouillage que les analyseurs GitLab sont capables d'analyser directement :

<table class="ds-table no-vertical-table-lines">
  <thead>
    <tr>
      <th>Gestionnaire de paquets</th>
      <th>Versions de format de fichier prises en charge</th>
      <th>Versions de gestionnaire de paquets testées</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td>Bundler</td>
      <td>Sans objet</td>
      <td>
        <a href="https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium/-/blob/master/qa/fixtures/ruby-bundler/default/Gemfile.lock#L118">1.17.3</a>, <a href="https://gitlab.com/gitlab-org/security-products/tests/ruby-bundler/-/blob/bundler2-FREEZE/Gemfile.lock#L118">2.1.4</a>
      </td>
    </tr>
    <tr>
      <td>Composer</td>
      <td>Sans objet</td>
      <td>
        <a href="https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium/-/blob/master/qa/fixtures/php-composer/default/composer.lock">1.x</a>
      </td>
    </tr>
    <tr>
      <td>Conan</td>
      <td>0.4</td>
      <td>
        <a href="https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium/-/blob/master/qa/fixtures/c-conan/default/conan.lock#L38">1.x</a>
      </td>
    </tr>
    <tr>
      <td>Go</td>
      <td>Sans objet</td>
      <td>
        <a href="https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium/-/blob/master/qa/fixtures/go-modules/gosum/default/go.sum">1.x</a>
      </td>
    </tr>
    <tr>
      <td>NuGet</td>
      <td>v1, v2</td>
      <td>
        <a href="https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium/-/blob/master/qa/fixtures/csharp-nuget-dotnetcore/default/src/web.api/packages.lock.json#L2">4.9</a>
      </td>
    </tr>
    <tr>
      <td>npm</td>
      <td>v1, v2, v3</td>
      <td>
        <a href="https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium/-/blob/master/qa/fixtures/js-npm/default/package-lock.json#L4">6.x</a>, <a href="https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium/-/blob/master/qa/fixtures/js-npm/lockfileVersion2/package-lock.json#L4">7.x</a>, <a href="https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium/-/blob/master/scanner/parser/npm/fixtures/lockfile-v3/simple/package-lock.json#L4">9.x</a>
      </td>
    </tr>
    <tr>
      <td>pnpm</td>
      <td>v5, v6, v9</td>
      <td>
        <a href="https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium/-/blob/master/qa/fixtures/js-pnpm/default/pnpm-lock.yaml#L1">7.x</a>, <a href="https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium/-/blob/master/scanner/parser/pnpm/fixtures/v6/simple/pnpm-lock.yaml#L1">8.x</a> <a href="https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium/-/blob/master/scanner/parser/pnpm/fixtures/v9/simple/pnpm-lock.yaml#L1">9.x</a>
      </td>
    </tr>
    <tr>
      <td>yarn</td>
      <td>versions 1, 2, 3, 4<sup>1</sup></td>
      <td>
        <a href="https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium/-/blob/master/qa/fixtures/js-yarn/classic/default/yarn.lock#L2">1.x</a>, <a href="https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium/-/blob/master/qa/fixtures/js-yarn/berry/v2/default/yarn.lock">2.x</a>, <a href="https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium/-/blob/master/qa/fixtures/js-yarn/berry/v3/default/yarn.lock">3.x</a>
      </td>
    </tr>
    <tr>
      <td>Poetry</td>
      <td>v1</td>
      <td>
        <a href="https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium/-/blob/master/qa/fixtures/python-poetry/default/poetry.lock">1.x</a>
      </td>
    </tr>
    <tr>
      <td>uv</td>
      <td>v0.x</td>
      <td>
        <a href="https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium/-/blob/master/scanner/parser/uv/fixtures/simple/uv.lock">0.x</a>
      </td>
    </tr>
  </tbody>
</table>

**Notes de bas de page** :

1. Les fonctionnalités suivantes ne sont pas prises en charge pour Yarn Berry :

   - Workspaces
   - `yarn patch`

   Les fichiers Yarn contenant un patch, un workspace, ou les deux, sont toujours traités, mais ces fonctionnalités sont ignorées.

#### Obtention des informations sur les dépendances en exécutant un gestionnaire de paquets pour générer un fichier analysable {#obtaining-dependency-information-by-running-a-package-manager-to-generate-a-parsable-file}

Pour prendre en charge les gestionnaires de paquets suivants, les analyseurs GitLab procèdent en deux étapes :

1. Exécuter le gestionnaire de paquets ou une tâche spécifique pour exporter les informations sur les dépendances.
1. Analyser les informations sur les dépendances exportées.

<table class="ds-table no-vertical-table-lines">
  <thead>
    <tr>
      <th>Gestionnaire de paquets</th>
      <th>Versions préinstallées</th>
      <th>Versions testées</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td>sbt</td>
      <td><a href="https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium/-/blob/v5.2.14/build/gemnasium-maven/debian/config/.tool-versions#L4">1.6.2</a></td>
      <td>
        <a href="https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium/-/blob/v5.2.14/spec/gemnasium-maven_image_spec.rb#L794-798">1.1.6</a>, <a href="https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium/-/blob/v5.2.14/spec/gemnasium-maven_image_spec.rb#L800-805">1.2.8</a>, <a href="https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium/-/blob/v5.2.14/spec/gemnasium-maven_image_spec.rb#L722-725">1.3.12</a>, <a href="https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium/-/blob/v5.2.14/spec/gemnasium-maven_image_spec.rb#L722-725">1.4.6</a>, <a href="https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium/-/blob/v5.2.14/spec/gemnasium-maven_image_spec.rb#L742-746">1.5.8</a>, <a href="https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium/-/blob/v5.2.14/spec/gemnasium-maven_image_spec.rb#L748-762">1.6.2</a>, <a href="https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium/-/blob/v5.2.14/spec/gemnasium-maven_image_spec.rb#L764-768">1.7.3</a>, <a href="https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium/-/blob/v5.2.14/spec/gemnasium-maven_image_spec.rb#L770-774">1.8.3</a>, <a href="https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium/-/blob/v5.2.14/spec/gemnasium-maven_image_spec.rb#L776-781">1.9.6</a>, <a href="https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium/-/blob/v5.2.14/.gitlab/ci/gemnasium-maven.gitlab-ci.yml#L111-121">1.9.7</a>
      </td>
    </tr>
    <tr>
      <td>maven</td>
      <td><a href="https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium/-/blob/v5.3.1/build/gemnasium-maven/debian/config/.tool-versions#L3">3.9.8</a></td>
      <td>
        <a href="https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium/-/blob/v5.3.1/spec/gemnasium-maven_image_spec.rb#L92-94">3.9.8</a><sup>1</sup>
      </td>
    </tr>
    <tr>
      <td>Gradle</td>
      <td>
        <a href="https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium/-/blob/v5.2.14/build/gemnasium-maven/debian/config/.tool-versions#L5">6.7.1</a>, <a href="https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium/-/blob/v5.2.14/build/gemnasium-maven/debian/config/.tool-versions#L5">7.6.4</a>, <a href="https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium/-/blob/v5.2.14/build/gemnasium-maven/debian/config/.tool-versions#L5">8.8</a><sup>2</sup>
      </td>
      <td>
        <a href="https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium/-/blob/v5.2.14/spec/gemnasium-maven_image_spec.rb#L316-321">5.6</a>, <a href="https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium/-/blob/v5.2.14/spec/gemnasium-maven_image_spec.rb#L323-328">6.7</a>, <a href="https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium/-/blob/v5.2.14/spec/gemnasium-maven_image_spec.rb#L330-335">6.9</a>, <a href="https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium/-/blob/v5.2.14/spec/gemnasium-maven_image_spec.rb#L337-341">7.6</a>, <a href="https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium/-/blob/v5.2.14/spec/gemnasium-maven_image_spec.rb#L343-347">8.8</a>
      </td>
    </tr>
    <tr>
      <td>setuptools</td>
      <td>
        <a href="https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium/-/blob/v5.4.1/build/gemnasium-python/requirements.txt#L41">70.3.0</a>
      </td>
      <td>
        <a href="https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium/-/blob/v5.4.1/spec/gemnasium-python_image_spec.rb#L294-316">>= 70.3.0</a>
      </td>
    </tr>
    <tr>
      <td>pip</td>
      <td>
        <a href="https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium/-/blob/v5.2.14/build/gemnasium-python/debian/Dockerfile#L21">24</a>
      </td>
      <td>
        <a href="https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium/-/blob/v5.2.14/spec/gemnasium-python_image_spec.rb#L77-90">24</a>
      </td>
    </tr>
    <tr>
      <td>Pipenv</td>
      <td>
        <a href="https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium/-/blob/v5.2.14/build/gemnasium-python/requirements.txt#L23">2023.11.15</a>
      </td>
      <td>
        <a href="https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium/-/blob/v5.2.14/spec/gemnasium-python_image_spec.rb#L243-256">2023.11.15</a><sup>3</sup>, <a href="https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium/-/blob/v5.2.14/spec/gemnasium-python_image_spec.rb#L219-241">2023.11.15</a>
      </td>
    </tr>
    <tr>
      <td>Go</td>
      <td>
        <a href="https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium/-/blob/v5.2.14/build/gemnasium/alpine/Dockerfile#L91-93">1.21</a>
      </td>
      <td>
        <a href="https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium/-/blob/v5.2.14/build/gemnasium/alpine/Dockerfile#L91-93">1.21</a><sup>4</sup>
      </td>
    </tr>
  </tbody>
</table>

**Notes de bas de page** :

1. Ce test utilise la version par défaut de maven spécifiée par le fichier `.tool-versions`.
1. Différentes versions de Java nécessitent différentes versions de Gradle. Les versions de Gradle répertoriées dans le tableau précédent sont préinstallées dans l'image de l'analyseur. La version de Gradle utilisée par l'analyseur dépend de si votre projet utilise un fichier `gradlew` (wrapper Gradle) ou non :
   - Si votre projet n'utilise pas de fichier `gradlew`, l'analyseur bascule automatiquement vers l'une des versions de Gradle préinstallées, en fonction de la version de Java spécifiée par la variable `DS_JAVA_VERSION` (la version par défaut est 17).

     Pour les versions Java 8 et 11, Gradle 6.7.1 est automatiquement sélectionné, Java 17 utilise Gradle 7.6.4, et Java 21 utilise Gradle 8.8.
   - Si votre projet utilise un fichier `gradlew`, la version de Gradle préinstallée dans l'image de l'analyseur est ignorée, et la version spécifiée dans votre fichier `gradlew` est utilisée à la place.
1. Ce test confirme que si un fichier `Pipfile.lock` est trouvé, il est utilisé par Gemnasium pour analyser les versions exactes des paquets répertoriées dans ce fichier.
1. En raison de l'implémentation de `go build`, le processus de build Go nécessite un accès réseau, un cache de modules préchargé via `go mod download`, ou des dépendances intégrées. Pour plus d'informations, consultez la [documentation Go sur la compilation des paquets et des dépendances](https://pkg.go.dev/cmd/go#hdr-Compile_packages_and_dependencies).

## Déclenchement des analyseurs {#how-analyzers-are-triggered}

GitLab utilise [`rules:exists`](../../../../ci/yaml/_index.md#rulesexists) pour démarrer les analyseurs appropriés pour les langages détectés par la présence des [fichiers pris en charge](#supported-languages-and-package-managers) dans le dépôt. Un maximum de deux niveaux de répertoires à partir de la racine du dépôt est parcouru. Par exemple, le job `gemnasium-dependency_scanning` est activé si un dépôt contient `Gemfile`, `api/Gemfile` ou `api/client/Gemfile`, mais pas si le seul fichier de dépendances pris en charge est `api/v1/client/Gemfile`.

## Traitement de plusieurs fichiers {#how-multiple-files-are-processed}

> [!note]
> Si vous avez rencontré des problèmes lors de l'analyse de plusieurs fichiers, contribuez un commentaire à [ce ticket](https://gitlab.com/gitlab-org/gitlab/-/issues/337056).

### Python {#python}

GitLab n'exécute qu'une seule installation dans le répertoire où un fichier de prérequis ou un fichier de verrouillage a été détecté. Les dépendances ne sont analysées par `gemnasium-python` que pour le premier fichier détecté. Les fichiers sont recherchés dans l'ordre suivant :

1. `requirements.txt`, `requirements.pip` ou `requires.txt` pour les projets utilisant Pip
1. `Pipfile` ou `Pipfile.lock` pour les projets utilisant Pipenv
1. `poetry.lock` pour les projets utilisant Poetry
1. `setup.py` pour les projets utilisant Setuptools

La recherche commence par le répertoire racine, puis se poursuit dans les sous-répertoires si aucun build n'est trouvé dans le répertoire racine. Par conséquent, un fichier de verrouillage Poetry dans le répertoire racine serait détecté avant un fichier Pipenv dans un sous-répertoire.

### Java et Scala {#java-and-scala}

GitLab n'exécute qu'un seul build dans le répertoire où un fichier de build a été détecté. Pour les grands projets qui incluent plusieurs builds Gradle, Maven ou sbt, ou toute combinaison de ces derniers, `gemnasium-maven` analyse uniquement les dépendances du premier fichier de build détecté. Les fichiers de build sont recherchés dans l'ordre suivant :

1. `pom.xml` pour les projets Maven simples ou [multi-modules](https://maven.apache.org/pom.html#Aggregation)
1. `build.gradle` ou `build.gradle.kts` pour les builds Gradle simples ou [multi-projets](https://docs.gradle.org/current/userguide/intro_multi_project_builds.html)
1. `build.sbt` pour les builds sbt simples ou [multi-projets](https://www.scala-sbt.org/1.x/docs/Multi-Project.html)

La recherche commence par le répertoire racine, puis se poursuit dans les sous-répertoires si aucun build n'est trouvé dans le répertoire racine. Par conséquent, un fichier de build sbt dans le répertoire racine serait détecté avant un fichier de build Gradle dans un sous-répertoire. Pour les projets Maven [multi-modules](https://maven.apache.org/pom.html#Aggregation), et les builds [Gradle](https://docs.gradle.org/current/userguide/intro_multi_project_builds.html) et [sbt](https://www.scala-sbt.org/1.x/docs/Multi-Project.html) multi-projets, les fichiers de sous-modules et de sous-projets sont analysés s'ils sont déclarés dans le fichier de build parent.

### JavaScript {#javascript}

Les analyseurs suivants sont exécutés, chacun ayant un comportement différent lors du traitement de plusieurs fichiers :

- [Gemnasium](https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium)

  Prend en charge plusieurs fichiers de verrouillage
- [Retire.js](https://retirejs.github.io/retire.js/)

  Ne prend pas en charge plusieurs fichiers de verrouillage. Lorsque plusieurs fichiers de verrouillage existent, `Retire.js` analyse le premier fichier de verrouillage découvert en parcourant l'arborescence de répertoires dans l'ordre alphabétique.

L'analyseur `gemnasium` prend en charge les projets JavaScript pour les bibliothèques intégrées (c'est-à-dire celles enregistrées dans le projet mais non gérées par le gestionnaire de paquets).

### Go {#go}

Plusieurs fichiers sont pris en charge. Lorsqu'un fichier `go.mod` est détecté, l'analyseur tente de générer une [liste de build](https://go.dev/ref/mod#glos-build-list) en utilisant la [sélection de version minimale](https://go.dev/ref/mod#glos-minimal-version-selection). Si cela échoue, l'analyseur tente plutôt d'analyser les dépendances dans le fichier `go.mod`.

En prérequis, le fichier `go.mod` doit être nettoyé à l'aide de la commande `go mod tidy` pour assurer une gestion correcte des dépendances. Le processus est répété pour chaque fichier `go.mod` détecté.

### PHP, C, C++, .NET, C#, Ruby, JavaScript {#php-c-c-net-c35-ruby-javascript}

L'analyseur pour ces langages prend en charge plusieurs fichiers de verrouillage.

### Prise en charge de langages supplémentaires {#support-for-additional-languages}

La prise en charge de langages supplémentaires, de gestionnaires de dépendances et de fichiers de dépendances est suivie dans les tickets suivants :

| Gestionnaires de paquets    | Langages | Fichiers pris en charge | Outils d'analyse | Ticket |
| ------------------- | --------- | --------------- | ---------- | ----- |
| [Poetry](https://python-poetry.org/) | Python | `pyproject.toml` | [Gemnasium](https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium) | [GitLab#32774](https://gitlab.com/gitlab-org/gitlab/-/issues/32774) |

## Avertissements {#warnings}

Utilisez la version la plus récente de tous les conteneurs, ainsi que la version prise en charge la plus récente de tous les gestionnaires de paquets et langages. L'utilisation de versions antérieures présente un risque de sécurité accru, car les versions non prises en charge peuvent ne plus bénéficier d'un signalement actif des problèmes de sécurité et du rétroportage des correctifs de sécurité.

### Projets Gradle {#gradle-projects}

Ne remplacez pas les propriétés `reports.html.destination` ou `reports.html.outputLocation` lors de la génération d'un rapport de dépendances HTML pour les projets Gradle. Cela empêche l'analyse des dépendances de fonctionner correctement.

### Projets Maven {#maven-projects}

Dans les réseaux isolés, si le dépôt central est un registre privé (explicitement défini avec la directive `<mirror>`), les builds Maven peuvent ne pas trouver la dépendance `gemnasium-maven-plugin`. Ce problème survient car Maven ne recherche pas par défaut dans le dépôt local (`/root/.m2`) et tente de récupérer depuis le dépôt central. Le résultat est une erreur concernant la dépendance manquante.

#### Solution de contournement {#workaround}

Pour résoudre ce problème, ajoutez une section `<pluginRepositories>` à votre fichier `settings.xml`. Cela permet à Maven de trouver les plugins dans le dépôt local.

Avant de commencer, tenez compte des points suivants :

- Cette solution de contournement est uniquement destinée aux environnements où le dépôt central Maven par défaut est mis en miroir vers un registre privé.
- Après avoir appliqué cette solution de contournement, Maven recherche les plugins dans le dépôt local, ce qui peut avoir des implications de sécurité dans certains environnements. Assurez-vous que cela est conforme aux politiques de sécurité de votre organisation.

Prérequis :

- Disposer du rôle Chargé de maintenance ou Propriétaire pour le projet.

Suivez ces étapes pour modifier le fichier `settings.xml` :

1. Localisez votre fichier Maven `settings.xml`. Ce fichier se trouve généralement dans l'un de ces emplacements :

   - `/root/.m2/settings.xml` pour l'utilisateur root.
   - `~/.m2/settings.xml` pour un utilisateur standard.
   - `${maven.home}/conf/settings.xml` paramètres globaux.

1. Vérifiez s'il existe une section `<pluginRepositories>` dans le fichier.
1. Si une section `<pluginRepositories>` existe déjà, ajoutez uniquement l'élément `<pluginRepository>` suivant à l'intérieur. Sinon, ajoutez l'intégralité de la section `<pluginRepositories>` :

   ```xml
     <pluginRepositories>
       <pluginRepository>
           <id>local2</id>
           <name>local repository</name>
           <url>file:///root/.m2/repository/</url>
       </pluginRepository>
     </pluginRepositories>
   ```

1. Réexécutez votre build Maven ou votre processus d'analyse des dépendances.

### Projets Python {#python-projects}

Il convient d'être particulièrement vigilant lors de l'utilisation de la variable d'environnement [`PIP_EXTRA_INDEX_URL`](https://pipenv.pypa.io/en/latest/indexes.html) en raison d'une exploitation possible documentée par [CVE-2018-20225](https://nvd.nist.gov/vuln/detail/CVE-2018-20225) :

> [!warning]
> Un problème a été découvert dans pip (toutes versions), car il installe la version portant le numéro de version le plus élevé, même si l'utilisateur avait l'intention d'obtenir un paquet privé depuis un index privé. Cela n'affecte que l'utilisation de l'option `PIP_EXTRA_INDEX_URL`, et l'exploitation nécessite que le paquet n'existe pas déjà dans l'index public (ce qui permet à un attaquant d'y placer le paquet avec un numéro de version arbitraire).

### Analyse des numéros de version {#version-number-parsing}

Dans certains cas, il n'est pas possible de déterminer si la version d'une dépendance de projet est dans la plage affectée d'un avis de sécurité.

Par exemple :

- La version est inconnue.
- La version est invalide.
- L'analyse de la version ou sa comparaison à la plage échoue.
- La version est une branche, comme `dev-master` ou `1.5.x`.
- Les versions comparées sont ambiguës. Par exemple, `1.0.0-20241502` ne peut pas être comparé à `1.0.0-2` car l'une des versions contient un horodatage tandis que l'autre n'en contient pas.

Dans ces cas, l'analyseur ignore la dépendance et affiche un message dans le journal.

Les analyseurs GitLab n'émettent pas d'hypothèses, car celles-ci pourraient entraîner un faux positif ou un faux négatif. Pour en discuter, consultez [le ticket 442027](https://gitlab.com/gitlab-org/gitlab/-/issues/442027).

## Créer des projets Swift {#build-swift-projects}

Swift Package Manager (SPM) est l'outil officiel pour gérer la distribution du code Swift. Il s'intègre au système de build Swift pour automatiser le processus de téléchargement, de compilation et de liaison des dépendances.

Suivez ces bonnes pratiques lorsque vous créez un projet Swift avec SPM.

1. Incluez un fichier `Package.resolved`.

   Le fichier `Package.resolved` verrouille vos dépendances à des versions spécifiques. Commitez toujours ce fichier dans votre dépôt pour garantir la cohérence entre les différents environnements.

   ```shell
   git add Package.resolved
   git commit -m "Add Package.resolved to lock dependencies"
   ```

1. Pour créer votre projet Swift, utilisez les commandes suivantes :

   ```shell
   # Update dependencies
   swift package update

   # Build the project
   swift build
   ```

1. Pour configurer CI/CD, ajoutez ces étapes à votre fichier `.gitlab-ci.yml` :

   ```yaml
   swift-build:
     stage: build
     script:
       - swift package update
       - swift build
   ```

1. Facultatif. Si vous utilisez des dépôts de packages Swift privés avec des certificats auto-signés, vous devrez peut-être ajouter le certificat à votre projet et configurer Swift pour lui faire confiance :

   1. Récupérez le certificat :

      ```shell
      echo | openssl s_client -servername your.repo.url -connect your.repo.url:443 | sed -ne '/-BEGIN CERTIFICATE-/,/-END
      CERTIFICATE-/p' > repo-cert.crt
      ```

   1. Ajoutez ces lignes à votre manifeste de package Swift (`Package.swift`) :

      ```swift
      import Foundation

      #if canImport(Security)
      import Security
      #endif

      extension Package {
          public static func addCustomCertificate() {
              guard let certPath = Bundle.module.path(forResource: "repo-cert", ofType: "crt") else {
                  fatalError("Certificate not found")
              }
              SecCertificateAddToSystemStore(SecCertificateCreateWithData(nil, try! Data(contentsOf: URL(fileURLWithPath: certPath)) as CFData)!)
          }
      }

      // Call this before defining your package
      Package.addCustomCertificate()
      ```

Testez toujours votre processus de build dans un environnement propre pour vous assurer que vos dépendances sont correctement spécifiées et se résolvent automatiquement.

## Créer des projets CocoaPods {#build-cocoapods-projects}

CocoaPods est un gestionnaire de dépendances populaire pour les projets Swift et Objective-C Cocoa. Il fournit un format standard pour gérer les bibliothèques externes dans les projets iOS, macOS, watchOS et tvOS.

Suivez ces bonnes pratiques lorsque vous créez des projets qui utilisent CocoaPods pour la gestion des dépendances.

1. Incluez un fichier `Podfile.lock`.

   Le fichier `Podfile.lock` est essentiel pour verrouiller vos dépendances à des versions spécifiques. Commitez toujours ce fichier dans votre dépôt pour garantir la cohérence entre les différents environnements.

   ```shell
   git add Podfile.lock
   git commit -m "Add Podfile.lock to lock CocoaPods dependencies"
   ```

1. Vous pouvez créer votre projet avec l'une des méthodes suivantes :

   - L'outil en ligne de commande `xcodebuild` :

     ```shell
     # Install CocoaPods dependencies
     pod install

     # Build the project
     xcodebuild -workspace YourWorkspace.xcworkspace -scheme YourScheme build
     ```

   - L'IDE Xcode :

     1. Ouvrez votre fichier `.xcworkspace` dans Xcode.
     1. Sélectionnez votre schéma cible.
     1. Sélectionnez **Produit** > **Version**. Vous pouvez également appuyer sur <kbd>⌘</kbd>+<kbd>B</kbd>.
   - [fastlane](https://fastlane.tools/), un outil pour automatiser les builds et les releases pour les applications iOS et Android :

     1. Installez `fastlane` :

        ```shell
        sudo gem install fastlane
        ```

     1. Dans votre projet, configurez `fastlane` :

        ```shell
        fastlane init
        ```

     1. Ajoutez une lane à votre `fastfile` :

        ```ruby
        lane :build do
          cocoapods
          gym(scheme: "YourScheme")
        end
        ```

     1. Lancez le build :

        ```shell
        fastlane build
        ```

   - Si votre projet utilise à la fois CocoaPods et Carthage, vous pouvez utiliser Carthage pour créer vos dépendances :

     1. Créez un `Cartfile` qui inclut vos dépendances CocoaPods.
     1. Exécutez la commande suivante :

        ```shell
        carthage update --platform iOS
        ```

1. Configurez CI/CD pour créer le projet selon votre méthode préférée.

   Par exemple, avec `xcodebuild` :

   ```yaml
   cocoapods-build:
     stage: build
     script:
       - pod install
       - xcodebuild -workspace YourWorkspace.xcworkspace -scheme YourScheme build
   ```

1. Facultatif. Si vous utilisez des dépôts CocoaPods privés, vous devrez peut-être configurer votre projet pour y accéder :

   1. Ajoutez le dépôt de spécifications privé :

      ```shell
      pod repo add REPO_NAME SOURCE_URL
      ```

   1. Dans votre Podfile, spécifiez la source :

      ```ruby
      source 'https://github.com/CocoaPods/Specs.git'
      source 'SOURCE_URL'
      ```

1. Facultatif. Si votre dépôt CocoaPods privé utilise SSL, assurez-vous que le certificat SSL est correctement configuré :

   - Si vous utilisez un certificat auto-signé, ajoutez-le aux certificats de confiance de votre système. Vous pouvez également spécifier la configuration SSL dans votre fichier `.netrc` :

     ```netrc
     machine your.private.repo.url
       login your_username
       password your_password
     ```

1. Après avoir mis à jour votre Podfile, exécutez `pod install` pour installer les dépendances et mettre à jour votre workspace.

N'oubliez pas de toujours exécuter `pod install` après avoir mis à jour votre Podfile pour vous assurer que toutes les dépendances sont correctement installées et que le workspace est mis à jour.

## Contribuer à la base de données de vulnérabilités {#contributing-to-the-vulnerability-database}

Pour trouver une vulnérabilité, vous pouvez effectuer une recherche dans la [`GitLab advisory database`](https://advisories.gitlab.com/). Vous pouvez également [soumettre de nouvelles vulnérabilités](https://gitlab.com/gitlab-org/security-products/gemnasium-db/blob/master/CONTRIBUTING.md).
