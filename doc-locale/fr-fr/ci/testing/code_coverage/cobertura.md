---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "Affichez des annotations de couverture de test ligne par ligne dans les diffs de merge request à l'aide de rapports XML Cobertura."
title: Visualisation de la couverture Cobertura
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Utilisez des rapports XML Cobertura pour afficher des annotations de couverture ligne par ligne dans les diffs de merge request. GitLab lit le rapport XML Cobertura et annote chaque ligne modifiée comme couverte (vert), non couverte (rouge) ou chargée mais jamais exécutée (orange). GitLab inclut les rapports de tout job de toute étape du pipeline.

La visualisation de la couverture utilise le mot-clé [`artifacts:reports:coverage_report`](../../yaml/artifacts_reports.md#artifactsreportscoverage_report). Il n'affiche pas de pourcentage de couverture dans le widget MR et ne renseigne pas les graphiques d'historique de couverture. Pour afficher un pourcentage de couverture, configurez séparément le mot-clé [`coverage`](../../../ci/yaml/_index.md#coverage).

Le format [Cobertura XML](https://cobertura.github.io/cobertura/) a été développé à l'origine pour Java, mais la plupart des frameworks de couverture le prennent en charge via des plugins ou des exportateurs intégrés :

- [simplecov-cobertura](https://rubygems.org/gems/simplecov-cobertura) (Ruby)
- [gocover-cobertura](https://github.com/boumenot/gocover-cobertura) (Go)
- [cobertura](https://www.npmjs.com/package/cobertura) (Node.js)
- [Istanbul](https://istanbul.js.org/docs/advanced/alternative-reporters/#cobertura) (JavaScript)
- [Coverage.py](https://coverage.readthedocs.io/en/coverage-5.0.4/cmd.html#xml-reporting) (Python)
- [PHPUnit](https://github.com/sebastianbergmann/phpunit-documentation-english/blob/master/src/textui.rst#command-line-options) (PHP)

## Exemples de configurations CI/CD {#example-cicd-configurations}

Les exemples suivants montrent comment configurer des jobs CI/CD pour différents langages de programmation. Vous pouvez également consulter un exemple fonctionnel dans le projet de démonstration [`coverage-report`](https://gitlab.com/gitlab-org/ci-sample-projects/coverage-report/).

### Exemple JavaScript {#javascript-example}

L'exemple `.gitlab-ci.yml` suivant utilise [Mocha](https://mochajs.org/) et [nyc](https://github.com/istanbuljs/nyc) pour générer l'artefact de couverture :

```yaml
test:
  script:
    - npm install
    - npx nyc --reporter cobertura mocha
  artifacts:
    reports:
      coverage_report:
        coverage_format: cobertura
        path: coverage/cobertura-coverage.xml
```

### Exemples Java et Kotlin {#java-and-kotlin-examples}

GitLab 17.6 et versions ultérieures prennent en charge le format JaCoCo nativement. Pour les nouveaux projets, utilisez les [rapports JaCoCo natifs](jacoco.md).

Les exemples suivants utilisent l'image Docker [jacoco2cobertura](https://gitlab.com/haynes/jacoco2cobertura) pour convertir les rapports JaCoCo au format Cobertura.

#### Exemple Maven {#maven-example}

Le job `test-jdk11` utilise [Maven](https://maven.apache.org/) pour générer un artefact XML JaCoCo. Le job `coverage-jdk11` le convertit au format Cobertura :

```yaml
test-jdk11:
  stage: test
  image: maven:3.6.3-jdk-11
  script:
    - mvn $MAVEN_CLI_OPTS clean org.jacoco:jacoco-maven-plugin:prepare-agent test jacoco:report
  artifacts:
    paths:
      - target/site/jacoco/jacoco.xml

coverage-jdk11:
  # The `visualize` stage does not exist by default.
  # Define it first, or use an existing stage like `deploy`.
  stage: visualize
  image: registry.gitlab.com/haynes/jacoco2cobertura:1.0.11
  script:
    # Convert report from JaCoCo to Cobertura, using relative project path
    - python /opt/cover2cover.py target/site/jacoco/jacoco.xml $CI_PROJECT_DIR/src/main/java/
        > target/site/cobertura.xml
  needs: ["test-jdk11"]
  artifacts:
    reports:
      coverage_report:
        coverage_format: cobertura
        path: target/site/cobertura.xml
```

#### Exemple Gradle {#gradle-example}

Le job `test-jdk11` utilise [Gradle](https://gradle.org/) pour générer un artefact XML JaCoCo. Le job `coverage-jdk11` le convertit au format Cobertura :

```yaml
test-jdk11:
  stage: test
  image: gradle:6.6.1-jdk11
  script:
    - gradle test jacocoTestReport # JaCoCo must be configured to create an XML report
  artifacts:
    paths:
      - build/jacoco/jacoco.xml

coverage-jdk11:
  # The `visualize` stage does not exist by default.
  # Define it first, or use an existing stage like `deploy`.
  stage: visualize
  image: registry.gitlab.com/haynes/jacoco2cobertura:1.0.11
  script:
    # Convert report from JaCoCo to Cobertura, using relative project path
    - python /opt/cover2cover.py build/jacoco/jacoco.xml $CI_PROJECT_DIR/src/main/java/
        > build/cobertura.xml
  needs: ["test-jdk11"]
  artifacts:
    reports:
      coverage_report:
        coverage_format: cobertura
        path: build/cobertura.xml
```

### Exemple Python {#python-example}

L'exemple `.gitlab-ci.yml` suivant utilise [pytest-cov](https://pytest-cov.readthedocs.io/) pour collecter les données de couverture de test :

```yaml
run tests:
  stage: test
  image: python:3
  script:
    - pip install pytest pytest-cov
    - pytest --cov --cov-report term --cov-report xml:coverage.xml
  artifacts:
    reports:
      coverage_report:
        coverage_format: cobertura
        path: coverage.xml
```

### Exemple PHP {#php-example}

L'exemple `.gitlab-ci.yml` suivant utilise [PHPUnit](https://phpunit.readthedocs.io/) pour collecter les données de couverture de test et générer le rapport.

Avec un fichier [`phpunit.xml`](https://docs.phpunit.de/en/11.0/configuration.html) minimal (vous pouvez vous référer à [cet exemple de dépôt](https://gitlab.com/yookoala/code-coverage-visualization-with-php/)), vous pouvez exécuter les tests et générer `coverage.xml` :

```yaml
run tests:
  stage: test
  image: php:latest
  variables:
    XDEBUG_MODE: coverage
  before_script:
    - apt-get update && apt-get -yq install git unzip zip libzip-dev zlib1g-dev
    - docker-php-ext-install zip
    - pecl install xdebug && docker-php-ext-enable xdebug
    - php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
    - php composer-setup.php --install-dir=/usr/local/bin --filename=composer
    - composer install
    - composer require --dev phpunit/phpunit phpunit/php-code-coverage
  script:
    - php ./vendor/bin/phpunit --coverage-text --coverage-cobertura=coverage.cobertura.xml
  artifacts:
    reports:
      coverage_report:
        coverage_format: cobertura
        path: coverage.cobertura.xml
```

[Codeception](https://codeception.com/), via PHPUnit, prend également en charge la génération d'un rapport Cobertura avec [`run`](https://codeception.com/docs/reference/Commands#run). Le chemin du fichier généré dépend de l'option `--coverage-cobertura` et de la configuration [`paths`](https://codeception.com/docs/reference/Configuration#paths) pour la [suite de tests unitaires](https://codeception.com/docs/05-UnitTests). Configurez `.gitlab-ci.yml` pour trouver Cobertura dans le chemin approprié.

### Exemple C/C++ {#cc-example}

L'exemple `.gitlab-ci.yml` suivant pour C/C++ avec `gcc` ou `g++` utilise [`gcovr`](https://gcovr.com/en/stable/) pour générer le fichier de sortie de couverture au format XML Cobertura.

Cet exemple suppose :

- Le `Makefile` est créé par `cmake` dans le répertoire `build`, dans un autre job d'une étape précédente. Si vous utilisez `automake` pour générer le `Makefile`, appelez `make check` au lieu de `make test`.
- `cmake` (ou `automake`) a défini l'option de compilateur `--coverage`.

```yaml
run tests:
  stage: test
  script:
    - cd build
    - make test
    - gcovr --xml-pretty --exclude-unreachable-branches --print-summary -o coverage.xml --root ${CI_PROJECT_DIR}
  artifacts:
    name: ${CI_JOB_NAME}-${CI_COMMIT_REF_NAME}-${CI_COMMIT_SHA}
    expire_in: 2 days
    reports:
      coverage_report:
        coverage_format: cobertura
        path: build/coverage.xml
```

### Exemple Go {#go-example}

L'exemple `.gitlab-ci.yml` suivant utilise :

- [`go test`](https://go.dev/doc/tutorial/add-a-test) pour exécuter les tests.
- [`gocover-cobertura`](https://github.com/boumenot/gocover-cobertura) pour convertir le profil de couverture Go au format XML Cobertura.

Cet exemple suppose que les [modules Go](https://go.dev/ref/mod) sont utilisés. L'option `-covermode count` ne fonctionne pas avec le flag `-race`. Pour générer la couverture du code tout en utilisant `-race`, basculez vers `-covermode atomic`, qui est plus lent.

```yaml
run tests:
  stage: test
  image: golang:1.17
  script:
    - go install
    - go test ./... -coverprofile=coverage.txt -covermode count
    - go get github.com/boumenot/gocover-cobertura
    - go run github.com/boumenot/gocover-cobertura < coverage.txt > coverage.xml
  artifacts:
    reports:
      coverage_report:
        coverage_format: cobertura
        path: coverage.xml
```

### Exemple Ruby {#ruby-example}

L'exemple `.gitlab-ci.yml` suivant utilise :

- [`rspec`](https://rspec.info/) pour exécuter les tests.
- [`simplecov`](https://github.com/simplecov-ruby/simplecov) et [`simplecov-cobertura`](https://github.com/dashingrocket/simplecov-cobertura) pour enregistrer le profil de couverture et créer un rapport au format XML Cobertura.

Cet exemple suppose :

- [`bundler`](https://bundler.io/) est utilisé pour la gestion des dépendances, avec `rspec`, `simplecov` et `simplecov-cobertura` ajoutés à votre `Gemfile`.
- `CoberturaFormatter` a été ajouté à votre configuration `SimpleCov.formatters` dans `spec_helper.rb`.

```yaml
run tests:
  stage: test
  image: ruby:3.1
  script:
    - bundle install
    - bundle exec rspec
  artifacts:
    reports:
      coverage_report:
        coverage_format: cobertura
        path: coverage/coverage.xml
```

## Dépannage {#troubleshooting}

Pour le dépannage de la visualisation de la couverture, notamment les échecs de résolution de chemin, les limites de taille de fichier et les annotations qui n'apparaissent pas, consultez [le dépannage de la visualisation de la couverture](coverage_visualization.md#troubleshooting).
