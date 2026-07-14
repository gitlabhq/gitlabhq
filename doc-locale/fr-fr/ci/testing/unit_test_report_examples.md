---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "Exemples de configuration JUnit XML pour Ruby, Go, Java, Python, JavaScript et d'autres langages."
title: Exemples de rapports de tests unitaires
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Utilisez ces exemples comme lignes directrices pour configurer des rapports de tests unitaires dans différents langages et frameworks de test. Les rapports de tests unitaires nécessitent que votre framework de test génère une sortie au format JUnit XML et que votre job CI/CD charge les résultats en tant qu'artefacts.

Les exemples suivants montrent les configurations de job individuelles à ajouter à votre fichier `.gitlab-ci.yml`. Tous les exemples utilisent :

- `artifacts:when: always` pour charger les rapports même lorsque les tests échouent.
- `artifacts:reports:junit` pour spécifier l'emplacement du fichier JUnit XML.
- L'installation des packages dans `before_script` lorsque cela est nécessaire.

Chaque exemple est un job fonctionnel que vous pouvez copier et adapter à votre projet. Vous pourriez avoir besoin de :

- Ajouter ou modifier la spécification `image:` pour votre environnement.
- Modifier les commandes d'installation des packages pour vos dépendances.
- Modifier les chemins de fichiers pour correspondre à la structure de votre projet.
- Mettre à jour les commandes de test pour correspondre à votre configuration de test.

Pour les instructions de configuration et le dépannage, consultez [les rapports de tests unitaires](unit_test_reports.md).

## Configuration de la sortie JUnit par outil {#junit-output-configuration-by-tool}

| Langage     | Outil                    | Indicateur de sortie JUnit |
| ------------ | ----------------------- | ----------------- |
| .NET         | `JunitXML.TestLogger`   | `--logger:"junit;LogFilePath=report.xml"` |
| C/C++        | GoogleTest              | `--gtest_output="xml:report.xml"` |
| C/C++        | CUnit                   | Automatique avec les macros `CUnitCI.h` |
| Flutter/Dart | `junitreport`           | `\| tojunit -o report.xml` |
| Go           | `gotestsum`             | `--junitfile report.xml` |
| Helm         | `helm-unittest`         | `-t JUnit -o report.xml` |
| Java         | Gradle                  | Automatique dans `build/test-results/test/` |
| Java         | Maven                   | Automatique dans `target/surefire-reports/` et `target/failsafe-reports/` |
| JavaScript   | `jest-junit`            | `--reporters=jest-junit` |
| JavaScript   | `karma-junit-reporter`  | `--reporters junit` |
| JavaScript   | `mocha-gitlab-reporter` | `--reporter mocha-gitlab-reporter` |
| PHP          | PHPUnit                 | `--log-junit report.xml` |
| Python       | `pytest`                | `--junitxml=report.xml` |
| Ruby         | `rspec_junit_formatter` | `--format RspecJunitFormatter --out report.xml` |
| Rust         | `cargo2junit`           | `\| cargo2junit > report.xml` |

## .NET {#net}

Générez des rapports JUnit XML avec .NET en utilisant le package NuGet [`JunitXML.TestLogger`](https://www.nuget.org/packages/JunitXml.TestLogger/) :

```yaml
Test:
  stage: test
  script:
    - 'dotnet test --test-adapter-path:. --logger:"junit;LogFilePath=..\artifacts\{assembly}-test-result.xml;MethodFormat=Class;FailureBodyFormat=Verbose"'
  artifacts:
    when: always
    paths:
      - ./**/*test-result.xml
    reports:
      junit:
        - ./**/*test-result.xml
```

Cet exemple suppose qu'une solution se trouve dans le dossier racine du dépôt, avec un ou plusieurs fichiers de projet dans des sous-dossiers. Un fichier de résultats est produit par projet de test, et chaque fichier est placé dans le dossier des artefacts. Les arguments de formatage améliorent la lisibilité des données de test dans le widget de test.

## C/C++ {#cc}

### GoogleTest {#googletest}

Générez des rapports JUnit XML avec [GoogleTest](https://github.com/google/googletest) en utilisant la sortie XML intégrée :

```yaml
cpp:
  stage: test
  script:
    - gtest.exe --gtest_output="xml:report.xml"
  artifacts:
    when: always
    reports:
      junit: report.xml
```

Si plusieurs exécutables `gtest` sont créés pour différentes architectures (`x86`, `x64` ou `arm`), assurez-vous que chaque test possède un nom de fichier unique. Les résultats sont ensuite agrégés.

### CUnit {#cunit}

Générez des rapports JUnit XML avec CUnit en utilisant les [macros `CUnitCI.h`](https://cunity.gitlab.io/cunit/group__CI.html) :

```yaml
cunit:
  stage: test
  script:
    - ./my-cunit-test
  artifacts:
    when: always
    reports:
      junit: ./my-cunit-test.xml
```

## Flutter ou Dart {#flutter-or-dart}

Générez des rapports JUnit XML avec Flutter ou Dart en utilisant le package [`junitreport`](https://pub.dev/packages/junitreport) :

```yaml
test:
  stage: test
  script:
    - flutter test --machine | tojunit -o report.xml
  artifacts:
    when: always
    reports:
      junit:
        - report.xml
```

Cet exemple utilise le package `junitreport` pour convertir la sortie `flutter test` au format JUnit XML.

## Go {#go}

Générez des rapports JUnit XML avec Go en utilisant [`gotestsum`](https://github.com/gotestyourself/gotestsum) :

```yaml
golang:
  stage: test
  script:
    - go install gotest.tools/gotestsum@latest
    - gotestsum --junitfile report.xml --format testname
  artifacts:
    when: always
    reports:
      junit: report.xml
```

## Helm {#helm}

Générez des rapports JUnit XML avec Helm en utilisant le plugin [`Helm Unittest`](https://github.com/helm-unittest/helm-unittest#docker-usage) :

```yaml
helm:
  image: helmunittest/helm-unittest:latest
  stage: test
  script:
    - '-t JUnit -o report.xml -f tests/*[._]test.yaml .'
  artifacts:
    when: always
    reports:
      junit: report.xml
```

L'indicateur `-f tests/*[._]test.yaml` configure `helm-unittest` pour rechercher les fichiers dans le répertoire `tests/` dont le nom se termine par `.test.yaml` ou `_test.yaml`.

## Java {#java}

### Gradle {#gradle}

Générez des rapports JUnit XML avec [Gradle](https://gradle.org/) en utilisant le reporting de test intégré :

```yaml
java:
  stage: test
  script:
    - gradle test
  artifacts:
    when: always
    reports:
      junit: build/test-results/test/**/TEST-*.xml
```

Si plusieurs tâches de test sont définies, `gradle` génère plusieurs répertoires sous `build/test-results/`. Dans ce cas, vous pouvez tirer parti de la correspondance glob en définissant le chemin suivant : `build/test-results/test/**/TEST-*.xml`.

### Maven {#maven}

Générez des rapports JUnit XML avec Maven en utilisant les rapports de test [Surefire](https://maven.apache.org/surefire/maven-surefire-plugin/) et [Failsafe](https://maven.apache.org/surefire/maven-failsafe-plugin/) :

```yaml
java:
  stage: test
  script:
    - mvn verify
  artifacts:
    when: always
    reports:
      junit:
        - target/surefire-reports/TEST-*.xml
        - target/failsafe-reports/TEST-*.xml
```

## JavaScript {#javascript}

### Jest {#jest}

Générez des rapports JUnit XML avec Jest en utilisant le package npm [`jest-junit`](https://github.com/jest-community/jest-junit) :

```yaml
javascript:
  image: node:latest
  stage: test
  before_script:
    - 'yarn global add jest'
    - 'yarn add --dev jest-junit'
  script:
    - 'jest --ci --reporters=default --reporters=jest-junit'
  artifacts:
    when: always
    reports:
      junit:
        - junit.xml
```

Pour que le job réussisse lorsqu'il n'y a aucun fichier `.test.js` contenant des tests unitaires, ajoutez l'indicateur `--passWithNoTests` à la fin de la commande `jest` dans la section `script:`.

### Karma {#karma}

Générez des rapports JUnit XML avec Karma en utilisant le package npm [`karma-junit-reporter`](https://github.com/karma-runner/karma-junit-reporter) :

```yaml
javascript:
  stage: test
  script:
    - karma start --reporters junit
  artifacts:
    when: always
    reports:
      junit:
        - junit.xml
```

### Mocha {#mocha}

Pour un exemple de configuration Mocha, consultez [`mocha-gitlab-reporter`](https://github.com/X-Guardian/mocha-gitlab-reporter?tab=readme-ov-file#gitlab-ci-configuration).

## PHP {#php}

Générez des rapports JUnit XML avec PHP en utilisant [`PHPUnit`](https://phpunit.de/index.html) :

```yaml
phpunit:
  stage: test
  script:
    - composer install
    - vendor/bin/phpunit --log-junit report.xml
  artifacts:
    when: always
    reports:
      junit: report.xml
```

Vous pouvez également configurer cette option en utilisant [XML](https://docs.phpunit.de/en/11.0/configuration.html#the-junit-element) dans le fichier de configuration `phpunit.xml`.

## Python {#python}

Générez des rapports JUnit XML avec Python en utilisant [`pytest`](https://pytest.org/) :

```yaml
pytest:
  stage: test
  script:
    - pytest --junitxml=report.xml
  artifacts:
    when: always
    reports:
      junit: report.xml
```

## Ruby {#ruby}

Générez des rapports JUnit XML avec RSpec en utilisant le gem [`rspec_junit_formatter`](https://github.com/sj26/rspec_junit_formatter) :

```yaml
ruby:
  image: ruby:3.0.4
  stage: test
  before_script:
    - apt-get update -y && apt-get install -y bundler
  script:
    - bundle install
    - bundle exec rspec --format progress --format RspecJunitFormatter --out rspec.xml
  artifacts:
    when: always
    paths:
      - rspec.xml
    reports:
      junit: rspec.xml
```

## Rust {#rust}

Générez des rapports JUnit XML avec Rust en utilisant [`cargo2junit`](https://crates.io/crates/cargo2junit) :

```yaml
run unittests:
  image: rust:latest
  stage: test
  before_script:
    - cargo install --root . cargo2junit
  script:
    - cargo test -- -Z unstable-options --format json --report-time | bin/cargo2junit > report.xml
  artifacts:
    when: always
    reports:
      junit:
        - report.xml
```

Pour récupérer la sortie JSON de `cargo test`, vous devez activer le compilateur nightly. L'outil est installé dans le répertoire courant.
