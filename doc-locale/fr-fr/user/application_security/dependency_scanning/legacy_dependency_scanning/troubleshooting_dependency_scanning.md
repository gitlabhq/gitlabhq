---
stage: Application Security Testing
group: Composition Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: "Dépannage de l'analyse des dépendances"
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Lorsque vous utilisez l'analyse des dépendances, vous pouvez rencontrer les problèmes suivants.

## Journalisation de niveau débogage {#debug-level-logging}

La journalisation de niveau débogage peut être utile lors du dépannage. Pour en savoir plus, reportez-vous à la section [Journalisation de niveau débogage](../../troubleshooting_application_security.md#turn-on-debug-level-logging).

## Exécuter l'analyseur dans un environnement local {#run-the-analyzer-in-a-local-environment}

Vous pouvez exécuter un analyseur d'analyse des dépendances localement pour déboguer des problèmes ou vérifier le comportement sans exécuter de pipeline.

Par exemple, pour exécuter l'analyseur Python :

```shell
cd project-git-repository

docker run \
   --interactive --tty --rm \
   --volume "$PWD":/tmp/app \
   --env CI_PROJECT_DIR=/tmp/app \
   --env SECURE_LOG_LEVEL=debug \
   -w /tmp/app \
   registry.gitlab.com/security-products/gemnasium-python:5 /analyzer run
```

Cette commande exécute l'analyseur avec la journalisation au niveau débogage et monte votre dépôt local pour analyser les dépendances. Vous pouvez remplacer `registry.gitlab.com/security-products/gemnasium-python:5` par la combinaison `image:tag` de scanner appropriée pour le langage et le gestionnaire de dépendances de votre projet.

### Contournement de l'absence de prise en charge de certains langages ou gestionnaires de paquets {#working-around-missing-support-for-certain-languages-or-package-managers}

Comme indiqué dans [Langages pris en charge](_index.md#supported-languages-and-package-managers), certains fichiers de définition de dépendances ne sont pas encore pris en charge. Cependant, l'analyse des dépendances peut être effectuée si le langage, un gestionnaire de paquets ou un outil tiers peut convertir le fichier de définition dans un format pris en charge.

En général, l'approche est la suivante :

1. Définissez un job de conversion dédié dans votre fichier `.gitlab-ci.yml`. Utilisez une image Docker appropriée, un script, ou les deux pour faciliter la conversion.
1. Laissez ce job charger le fichier converti et pris en charge en tant qu'artefact.
1. Ajoutez [`dependencies: [<your-converter-job>]`](../../../../ci/yaml/_index.md#dependencies) à votre job `dependency_scanning` pour utiliser les fichiers de définitions convertis.

Par exemple, les projets Poetry qui n'ont qu'un fichier `pyproject.toml` peuvent générer le fichier `poetry.lock` comme suit.

```yaml
include:
  - template: Jobs/Dependency-Scanning.gitlab-ci.yml

stages:
  - test

gemnasium-python-dependency_scanning:
  # Work around https://gitlab.com/gitlab-org/gitlab/-/issues/32774
  before_script:
    - pip install "poetry>=1,<2"  # Or via another method: https://python-poetry.org/docs/#installation
    - poetry update --lock # Generates the lockfile to be analyzed.
```

## Les jobs d'analyse des dépendances s'exécutent de manière inattendue {#dependency-scanning-jobs-are-running-unexpectedly}

Le [modèle CI d'analyse des dépendances](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Jobs/Dependency-Scanning.gitlab-ci.yml) utilise la syntaxe [`rules:exists`](../../../../ci/yaml/_index.md#rulesexists). Cette directive est limitée à 10 000 vérifications et retourne toujours `true` après avoir atteint ce nombre. Pour cette raison, et selon le nombre de fichiers dans votre dépôt, un job d'analyse des dépendances peut être déclenché même si le scanner ne prend pas en charge votre projet. Pour plus de détails sur cette limitation, consultez la [documentation de `rules:exists`](../../../../ci/yaml/_index.md#rulesexists).

## Erreur : `dependency_scanning is used for configuration only, and its script should not be executed` {#error-dependency_scanning-is-used-for-configuration-only-and-its-script-should-not-be-executed}

Pour plus d'informations, consultez [le dépannage des tests de sécurité des applications](../../troubleshooting_application_security.md#error-job-is-used-for-configuration-only-and-its-script-should-not-be-executed).

## Importer plusieurs certificats pour les projets Java {#import-multiple-certificates-for-java-based-projects}

L'analyseur `gemnasium-maven` lit le contenu de la variable `ADDITIONAL_CA_CERT_BUNDLE` à l'aide de `keytool`, qui importe soit un certificat unique, soit une chaîne de certificats. Les certificats non liés entre eux sont ignorés et seul le premier est importé par `keytool`.

Pour ajouter plusieurs certificats non liés à l'analyseur, vous pouvez déclarer un `before_script` comme celui-ci dans la définition du job `gemnasium-maven-dependency_scanning` :

```yaml
gemnasium-maven-dependency_scanning:
  before_script:
    - . $HOME/.bashrc # make the java tools available to the script
    - OIFS="$IFS"; IFS=""; echo $ADDITIONAL_CA_CERT_BUNDLE > multi.pem; IFS="$OIFS" # write ADDITIONAL_CA_CERT_BUNDLE variable to a PEM file
    - csplit -z --digits=2 --prefix=cert multi.pem "/-----END CERTIFICATE-----/+1" "{*}" # split the file into individual certificates
    - for i in `ls cert*`; do keytool -v -importcert -alias "custom-cert-$i" -file $i -trustcacerts -noprompt -storepass changeit -keystore /opt/asdf/installs/java/adoptopenjdk-11.0.7+10.1/lib/security/cacerts 1>/dev/null 2>&1 || true; done # import each certificate using keytool (note the keystore location is related to the Java version being used and should be changed accordingly for other versions)
    - unset ADDITIONAL_CA_CERT_BUNDLE # unset the variable so that the analyzer doesn't duplicate the import
```

## Le job d'analyse des dépendances échoue avec le message `strconv.ParseUint: parsing "0.0": invalid syntax` {#dependency-scanning-job-fails-with-message-strconvparseuint-parsing-00-invalid-syntax}

Docker-in-Docker n'est pas pris en charge, et tenter de l'invoquer est la cause probable de cette erreur.

Pour corriger cette erreur, désactivez Docker-in-Docker pour l'analyse des dépendances. Des jobs `<analyzer-name>-dependency_scanning` individuels sont créés pour chaque analyseur qui s'exécute dans votre pipeline CI/CD.

```yaml
include:
  - template: Dependency-Scanning.gitlab-ci.yml

variables:
  DS_DISABLE_DIND: "true"
```

## Message `<file> does not exist in <commit SHA>` {#message-file-does-not-exist-in-commit-sha}

Lorsque l'emplacement (`Location`) d'une dépendance dans un fichier est affiché, le chemin dans le lien pointe vers un SHA Git spécifique.

Si le fichier de verrouillage examiné par nos outils d'analyse des dépendances était mis en cache, la sélection de ce lien vous redirige vers la racine du dépôt, avec le message : `<file> does not exist in <commit SHA>`.

Le fichier de verrouillage est mis en cache pendant la phase de construction et transmis au job d'analyse des dépendances avant que l'analyse ne se produise. Comme le cache est téléchargé avant l'exécution de l'analyseur, la présence d'un fichier de verrouillage dans le répertoire `CI_BUILDS_DIR` déclenche le job d'analyse des dépendances.

Pour éviter cet avertissement, les fichiers de verrouillage doivent être commités.

## Vous n'obtenez plus la dernière image Docker après avoir défini `DS_MAJOR_VERSION` ou `DS_ANALYZER_IMAGE` {#you-no-longer-get-the-latest-docker-image-after-setting-ds_major_version-or-ds_analyzer_image}

Si vous avez défini manuellement `DS_MAJOR_VERSION` ou `DS_ANALYZER_IMAGE` pour des raisons spécifiques, et que vous devez maintenant mettre à jour votre configuration pour obtenir à nouveau les dernières versions corrigées de nos analyseurs, modifiez votre fichier `.gitlab-ci.yml` et effectuez l'une des actions suivantes :

- Définissez `DS_MAJOR_VERSION` pour correspondre à la version référencée dans le [modèle d'analyse des dépendances](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Jobs/Dependency-Scanning.gitlab-ci.yml#L17).
- Si vous avez codé en dur la variable `DS_ANALYZER_IMAGE` directement, modifiez-la pour correspondre à la dernière ligne telle qu'elle apparaît dans le [modèle d'analyse des dépendances](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Jobs/Dependency-Scanning.gitlab-ci.yml). Le numéro de ligne varie selon le job de scan que vous avez modifié.

  Par exemple, le job `gemnasium-maven-dependency_scanning` récupère la dernière image Docker `gemnasium-maven` car `DS_ANALYZER_IMAGE` est défini sur `"$SECURE_ANALYZERS_PREFIX/gemnasium-maven:$DS_MAJOR_VERSION"`.

## L'analyse des dépendances d'un projet setuptools échoue avec l'erreur `use_2to3 is invalid` {#dependency-scanning-of-setuptools-project-fails-with-use_2to3-is-invalid-error}

La prise en charge de [2to3](https://docs.python.org/3/library/2to3.html) a été [supprimée](https://setuptools.pypa.io/en/latest/history.html#v58-0-0) dans `setuptools` version `v58.0.0`. L'analyse des dépendances (exécutant `python 3.9`) utilise `setuptools` version `58.1.0+`, qui ne prend pas en charge `2to3`. Par conséquent, une dépendance `setuptools` reposant sur `lib2to3` échoue avec ce message :

```plaintext
error in <dependency name> setup command: use_2to3 is invalid
```

Pour contourner cette erreur, rétrogradez la version de `setuptools` de l'analyseur (par exemple, `v57.5.0`) :

```yaml
gemnasium-python-dependency_scanning:
  before_script:
    - pip install setuptools==57.5.0
```

## L'analyse des dépendances de projets utilisant psycopg2 échoue avec l'erreur `pg_config executable not found` {#dependency-scanning-of-projects-using-psycopg2-fails-with-pg_config-executable-not-found-error}

L'analyse d'un projet Python qui dépend de `psycopg2` peut échouer avec ce message :

```plaintext
Error: pg_config executable not found.
```

[psycopg2](https://pypi.org/project/psycopg2/) dépend du paquet Debian `libpq-dev`, qui n'est pas installé dans l'image Docker `gemnasium-python`. Pour contourner cette erreur, installez le paquet `libpq-dev` dans un `before_script` :

```yaml
gemnasium-python-dependency_scanning:
  before_script:
    - apt-get update && apt-get install -y libpq-dev
```

## `NoSuchOptionException` lors de l'utilisation de `poetry config http-basic` avec `CI_JOB_TOKEN` {#nosuchoptionexception-when-using-poetry-config-http-basic-with-ci_job_token}

Cette erreur peut se produire lorsque le `CI_JOB_TOKEN` généré automatiquement commence par un trait d'union (`-`). Pour éviter cette erreur, suivez [les conseils de configuration de Poetry](https://python-poetry.org/docs/repositories/#configuring-credentials).

## Erreur : le projet contient des dépendances non résolues {#error-project-has-unresolved-dependencies}

Le message d'erreur suivant indique un problème de résolution de dépendances Gradle causé par votre fichier `build.gradle` ou `build.gradle.kts` :

- `project has unresolved dependencies: ["dependency_name:version"]`

`gemnasium-maven` prend en charge la variable d'environnement `DS_GRADLE_RESOLUTION_POLICY` que vous pouvez utiliser pour contrôler la gestion des dépendances non résolues. Par défaut, l'analyse échoue lorsque des dépendances non résolues sont rencontrées. Cependant, vous pouvez définir la variable d'environnement `DS_GRADLE_RESOLUTION_POLICY` sur `"none"` pour permettre à l'analyse de continuer et de produire des résultats partiels.

Consultez la [documentation sur la résolution des dépendances Gradle](https://docs.gradle.org/current/userguide/dependency_resolution.html) pour obtenir des conseils sur la correction de votre fichier `build.gradle`. Pour plus de détails, consultez le [ticket 482650](https://gitlab.com/gitlab-org/gitlab/-/issues/482650).

De plus, il existe un problème connu dans Kotlin 2.0.0 affectant la résolution des dépendances, dont la correction est prévue dans Kotlin 2.0.20. Pour plus d'informations, consultez [ce ticket](https://github.com/gradle/github-dependency-graph-gradle-plugin/issues/140#issuecomment-2230255380).

## Définir des contraintes de build lors de l'analyse des projets Go {#setting-build-constraints-when-scanning-go-projects}

L'analyse des dépendances s'exécute dans un conteneur `linux/amd64`. Par conséquent, la liste de build générée pour un projet Go contient des dépendances compatibles avec cet environnement. Si votre environnement de déploiement n'est pas `linux/amd64`, la liste finale des dépendances peut contenir des modules incompatibles supplémentaires. La liste des dépendances peut également omettre des modules qui ne sont compatibles qu'avec votre environnement de déploiement. Pour éviter ce problème, vous pouvez configurer le processus de build pour cibler le système d'exploitation et l'architecture de l'environnement de déploiement en définissant les [variables d'environnement](https://go.dev/ref/mod#minimal-version-selection) `GOOS` et `GOARCH` dans votre fichier `.gitlab-ci.yml`.

Par exemple :

```yaml
variables:
  GOOS: "darwin"
  GOARCH: "arm64"
```

Vous pouvez également fournir des contraintes de tags de build en utilisant la variable `GOFLAGS` :

```yaml
variables:
  GOFLAGS: "-tags=test_feature"
```

## L'analyse des dépendances de projets Go retourne des faux positifs {#dependency-scanning-of-go-projects-returns-false-positives}

Le fichier `go.sum` contient une entrée pour chaque module considéré lors de la génération de la [liste de build](https://go.dev/ref/mod#glos-build-list) du projet. Plusieurs versions d'un module sont incluses dans le fichier `go.sum`, mais l'algorithme [MVS](https://go.dev/ref/mod#minimal-version-selection) utilisé par `go build` n'en sélectionne qu'une seule. Par conséquent, lorsque l'analyse des dépendances utilise `go.sum`, elle peut signaler des faux positifs.

Pour éviter les faux positifs, Gemnasium n'utilise `go.sum` que s'il est incapable de générer la liste de build pour le projet Go. Si `go.sum` est sélectionné, un avertissement se produit :

```shell
[WARN] [Gemnasium] [2022-09-14T20:59:38Z] ▶ Selecting "go.sum" parser for "/test-projects/gitlab-shell/go.sum". False positives may occur. See https://gitlab.com/gitlab-org/gitlab/-/issues/321081.
```

## `Host key verification failed` lors de la tentative d'utilisation de `ssh` {#host-key-verification-failed-when-trying-to-use-ssh}

Après avoir installé `openssh-client` sur n'importe quelle image `gemnasium`, l'utilisation de `ssh` peut entraîner un message `Host key verification failed`. Cela peut se produire si vous utilisez `~` pour représenter le répertoire utilisateur lors de la configuration, en raison de la définition de `$HOME` sur `/tmp` lors de la construction de l'image. Ce problème est décrit dans [Le clonage du projet via SSH échoue lors de l'utilisation de l'image `gemnasium-python`](https://gitlab.com/gitlab-org/gitlab/-/issues/374571). `openssh-client` s'attend à trouver `/root/.ssh/known_hosts`, mais ce chemin n'existe pas ; c'est `/tmp/.ssh/known_hosts` qui existe à la place.

Ce problème a été résolu dans `gemnasium-python` où `openssh-client` est préinstallé, mais le problème peut se produire lors de l'installation de `openssh-client` depuis zéro sur d'autres images. Pour résoudre ce problème, vous pouvez :

1. Utiliser des chemins absolus (`/root/.ssh/known_hosts` au lieu de `~/.ssh/known_hosts`) lors de la configuration des clés et des hôtes.
1. Ajouter `UserKnownHostsFile` à votre configuration `ssh` en spécifiant les fichiers `known_hosts` pertinents, par exemple : `echo 'UserKnownHostsFile /tmp/.ssh/known_hosts' >> /etc/ssh/ssh_config`.

## `ERROR: THESE PACKAGES DO NOT MATCH THE HASHES FROM THE REQUIREMENTS FILE` {#error-these-packages-do-not-match-the-hashes-from-the-requirements-file}

Cette erreur se produit lorsque le hachage d'un paquet dans un fichier `requirements.txt` ne correspond pas au hachage du paquet téléchargé. Par mesure de sécurité, `pip` supposera que le paquet a été altéré et refusera de l'installer. Pour remédier à cela, assurez-vous que le hachage contenu dans le fichier de prérequis est correct. Pour les fichiers de prérequis générés par [`pip-compile`](https://pip-tools.readthedocs.io/en/stable/), exécutez `pip-compile --generate-hashes` pour vous assurer que le hachage est à jour. Si vous utilisez un fichier `Pipfile.lock` généré par [`pipenv`](https://pipenv.pypa.io/), exécutez `pipenv verify` pour vérifier que le fichier de verrouillage contient les derniers hachages de paquets.

## `ERROR: In --require-hashes mode, all requirements must have their versions pinned with ==` {#error-in---require-hashes-mode-all-requirements-must-have-their-versions-pinned-with-}

Cette erreur se produit si le fichier de prérequis a été généré sur une plateforme différente de celle utilisée par le GitLab Runner. La prise en charge du ciblage d'autres plateformes est suivie dans le [ticket 416376](https://gitlab.com/gitlab-org/gitlab/-/issues/416376).

## Les flags modifiables peuvent bloquer l'analyse des dépendances pour Python {#editable-flags-can-cause-dependency-scanning-for-python-to-hang}

Si vous utilisez le flag [`-e/--editable`](https://pip.pypa.io/en/stable/cli/pip_install/#install-editable) dans le fichier `requirements.txt` pour cibler le répertoire actuel, vous pouvez rencontrer un problème qui entraîne le blocage de l'analyseur de dépendances Python Gemnasium lors de l'exécution de `pip3 download`. Cette commande est nécessaire pour construire le projet cible.

Pour résoudre ce problème, n'utilisez pas le flag `-e/--editable` lorsque vous exécutez l'analyse des dépendances pour Python.

## Gestion des erreurs de mémoire insuffisante avec SBT {#handling-out-of-memory-errors-with-sbt}

Si vous rencontrez des erreurs de mémoire insuffisante avec SBT lors de l'utilisation de l'analyse des dépendances sur un projet Scala, vous pouvez résoudre ce problème en définissant la variable d'environnement [`SBT_CLI_OPTS`](_index.md#analyzer-specific-settings). Voici un exemple de configuration :

```yaml
variables:
  SBT_CLI_OPTS: "-J-Xmx8192m -J-Xms4192m -J-Xss2M"
```

Si vous utilisez l'exécuteur Kubernetes, vous devrez peut-être remplacer les paramètres de ressources Kubernetes par défaut. Consultez la [documentation sur l'exécuteur Kubernetes](https://docs.gitlab.com/runner/executors/kubernetes/#overwrite-container-resources) pour plus de détails sur la façon d'ajuster les ressources des conteneurs afin d'éviter les problèmes de mémoire.

## Absence de fichier `package-lock.json` dans les projets NPM {#no-package-lockjson-file-in-npm-projects}

Par défaut, le job d'analyse des dépendances ne s'exécute que lorsqu'il existe un fichier `package-lock.json` dans le dépôt. Cependant, certains projets NPM génèrent le fichier `package-lock.json` pendant le processus de build, au lieu de le stocker dans le dépôt Git.

Pour analyser les dépendances dans ces projets :

1. Générez le fichier `package-lock.json` dans un job de build.
1. Stockez le fichier généré en tant qu'artefact.
1. Modifiez le job d'analyse des dépendances pour utiliser l'artefact et ajustez ses règles.

Par exemple, votre configuration pourrait ressembler à ceci :

```yaml
include:
  - template: Dependency-Scanning.gitlab-ci.yml

build:
  script:
    - npm i
  artifacts:
    paths:
      - package-lock.json  # Store the generated package-lock.json as an artifact

gemnasium-dependency_scanning:
  needs: ["build"]
  rules:
    - if: "$DEPENDENCY_SCANNING_DISABLED == 'true' || $DEPENDENCY_SCANNING_DISABLED == '1'"
      when: never
    - if: "$DS_EXCLUDED_ANALYZERS =~ /gemnasium([^-]|$)/"
      when: never
    - if: $CI_COMMIT_BRANCH && $GITLAB_FEATURES =~ /\bdependency_scanning\b/ && $CI_GITLAB_FIPS_MODE == "true"
      variables:
        DS_IMAGE_SUFFIX: "-fips"
        DS_REMEDIATE: 'false'
    - if: "$CI_COMMIT_BRANCH && $GITLAB_FEATURES =~ /\\bdependency_scanning\\b/"
```

## Aucun job d'analyse des dépendances ajouté au pipeline {#no-dependency-scanning-job-added-to-the-pipeline}

Le job d'analyse des dépendances utilise des règles pour vérifier si des fichiers de verrouillage avec des dépendances ou des fichiers liés aux outils de build existent. Si aucun de ces fichiers n'est détecté, le job n'est pas ajouté au pipeline, même si les fichiers de verrouillage sont générés par un autre job dans le pipeline.

Si vous êtes dans cette situation, assurez-vous que votre dépôt contient un [fichier pris en charge](https://gitlab.com/gitlab-org/security-products/analyzers/dependency-scanning#supported-files), ou un fichier indiquant qu'un fichier pris en charge est généré au moment de l'exécution. Réfléchissez à la possibilité d'ajouter de tels fichiers à votre dépôt pour déclencher le job d'analyse des dépendances.

Si vous pensez que votre dépôt contient bien ces fichiers et que le job n'est toujours pas déclenché, [ouvrez un ticket](https://gitlab.com/gitlab-org/gitlab/-/issues/new) avec les informations suivantes :

- Le langage et l'outil de build que vous utilisez
- Le type de fichier de verrouillage que vous fournissez et l'endroit où il est généré

Vous pouvez également contribuer directement au [modèle d'analyse des dépendances](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Jobs/Dependency-Scanning.latest.gitlab-ci.yml#L269-270).

## L'analyse des dépendances échoue avec `gradlew: permission denied` {#dependency-scanning-fails-with-gradlew-permission-denied}

L'erreur `permission denied` sur `gradlew` indique généralement que `gradlew` a été ajouté au dépôt sans que le bit exécutable soit défini. L'erreur peut apparaître dans votre job avec ce message :

```plaintext
[FATA] [gemnasium-maven] [2024-11-14T21:55:59Z] [/go/src/app/cmd/gemnasium-maven/main.go:65] ▶ fork/exec /builds/path/to/gradlew: permission denied
```

Rendez le fichier exécutable en exécutant `chmod +ux gradlew` localement et en le poussant vers votre dépôt Git.

## L'analyse des dépendances échoue lors de la création du verrou nebula en raison d'une version Gradle non prise en charge {#dependency-scanning-nebula-lock-creation-fails-due-to-unsupported-gradle-version}

Lors de la tentative de création de [dependency.lockfiles](../dependency_scanning_sbom/_index.md#dependency-lock-plugin) avec une version Gradle non prise en charge (9.0 ou supérieure), l'erreur suivante se produit :

```plaintext
FAILURE: Build failed with an exception.
* Where:
Initialization script '/builds/gitlab-org/app/app/nebula.gradle' line: 11
* What went wrong:
Failed to notify build listener.
> org/gradle/util/NameMatcher
```

Essayez de rétrograder votre build gradle vers Gradle 8.10.2.

## Le scanner d'analyse des dépendances n'est plus `Gemnasium` {#dependency-scanning-scanner-is-no-longer-gemnasium}

Historiquement, le scanner utilisé par l'analyse des dépendances est `Gemnasium` et c'est ce que l'utilisateur peut voir sur la [page des vulnérabilités](../../vulnerabilities/_index.md).

Avec le déploiement de [l'analyse des dépendances par SBOM](../dependency_scanning_sbom/_index.md), le scanner `Gemnasium` est remplacé par le scanner intégré `GitLab SBoM Vulnerability Scanner`. Ce nouveau scanner n'est plus exécuté dans un job CI/CD, mais au sein de la plateforme GitLab. Bien que les deux scanners soient censés fournir les mêmes résultats, comme l'analyse SBOM se produit après le job CI/CD d'analyse des dépendances existant, la valeur du scanner des vulnérabilités existantes est mise à jour avec le nouveau `GitLab SBoM Vulnerability Scanner`.

Le `GitLab SBoM Vulnerability Scanner` est la seule valeur attendue pour la fonctionnalité d'analyse des dépendances intégrée à GitLab.

## La liste des dépendances du projet n'est pas mise à jour selon le dernier SBOM {#dependency-list-for-project-not-being-updated-based-on-latest-sbom}

Lorsqu'un pipeline comporte un job en échec qui devrait générer un SBOM, le service `DeleteNotPresentOccurrencesService` ne s'exécute pas, ce qui empêche la liste des dépendances d'être modifiée ou mise à jour. Cela peut se produire même s'il existe d'autres jobs réussis qui chargent un SBOM et que le pipeline est globalement réussi. Cette conception vise à éviter la suppression accidentelle de dépendances de la liste des dépendances lorsque des jobs d'analyse de sécurité associés échouent. Si la liste des dépendances du projet ne se met pas à jour comme prévu, vérifiez si des jobs liés au SBOM ont échoué dans le pipeline, puis corrigez-les ou supprimez-les.

## L'analyse des dépendances échoue avec `open /etc/ssl/certs/ca-certificates.crt: permission denied` {#dependency-scanning-fails-with-open-etcsslcertsca-certificatescrt-permission-denied}

Cette erreur indique généralement que l'utilisateur exécutant le conteneur ne fait pas partie du groupe `root`. Assurez-vous que l'utilisateur fait partie du groupe en exécutant `id`.

```shell
$ id
uid=1000(node) gid=0(root) groups=0(root),1000(node)
```

Si vous utilisez OpenShift ou l'exécuteur Kubernetes, assurez-vous de configurer le runner pour qu'il s'exécute avec l'ID de groupe (GID) 0.

```toml
[[runners]]
[runners.kubernetes]
    [runners.kubernetes.pod_security_context]
    run_as_non_root = true
    run_as_group = 0
```

## L'analyse des vulnérabilités ne produit aucun résultat pour les SBOM CycloneDX personnalisés ou fusionnés {#vulnerability-scanning-produces-no-results-for-custom-or-merged-cyclonedx-sboms}

Le job CI/CD d'analyse des dépendances réussit et les composants SBOM apparaissent dans la liste des dépendances, mais aucune vulnérabilité n'est signalée dans l'onglet de sécurité du pipeline.

Sur GitLab 18.10 et versions ultérieures, l'onglet de sécurité affiche le message : « Le rapport SBOM ne contient pas les propriétés de métadonnées GitLab requises pour l'analyse des vulnérabilités. »

Ce problème se produit lorsque le SBOM ne contient pas les [propriétés GitLab CycloneDX](../../../../development/sec/cyclonedx_property_taxonomy.md) requises. Sans ces propriétés, le scanner de vulnérabilités ne peut pas construire de résultats pour les composants du SBOM. La liste des dépendances est toujours renseignée, mais aucune vulnérabilité n'est signalée.

Cela se produit généralement dans les cas suivants :

- Plusieurs SBOM sont fusionnés à l'aide de `cyclonedx merge`, ce qui supprime les propriétés des métadonnées.
- Un générateur SBOM tiers n'inclut pas les propriétés spécifiques à GitLab.
- La propriété `gitlab:meta:schema_version` (qui doit être `1`) est absente de `metadata.properties`.

### Propriétés requises pour l'analyse des vulnérabilités {#required-properties-for-vulnerability-scanning}

| Propriété | Emplacement | Description |
|---|---|---|
| `gitlab:meta:schema_version` | `metadata.properties` | Doit être défini sur `1`. |
| `gitlab:dependency_scanning:input_file:path` | `metadata.properties` ou le tableau `properties` de chaque composant | Chemin vers le fichier de verrouillage analysé pour produire la dépendance. Si aucun des deux n'est présent, aucun résultat de vulnérabilité n'est produit pour ces composants. Sur GitLab 18.10 et versions ultérieures, une erreur est affichée dans l'onglet de sécurité du pipeline. |

Pour résoudre ce problème, choisissez l'une des approches suivantes :

- Chargez chaque SBOM séparément.

  Au lieu de les fusionner, chargez chaque SBOM en tant qu'entrée [`artifacts: reports: cyclonedx:`](../../../../ci/yaml/artifacts_reports.md#artifactsreportscyclonedx) distincte. Cela préserve les propriétés spécifiques à GitLab dans chaque fichier.
- Ajoutez des propriétés aux SBOM tiers.

  Les SBOM générés par des outils tiers n'incluent généralement pas les propriétés spécifiques à GitLab. Pour activer l'analyse des vulnérabilités, assurez-vous que votre SBOM inclut les éléments suivants dans `metadata.properties` :

  - `gitlab:meta:schema_version` défini sur `1`
  - `gitlab:dependency_scanning:input_file:path` défini sur le chemin relatif au dépôt du fichier de verrouillage (par exemple, `package-lock.json` ou `src/Gemfile.lock`)

  Si votre SBOM contient des composants provenant de plusieurs fichiers de verrouillage, définissez `input_file:path` dans le tableau `properties` de chaque composant plutôt que dans les métadonnées, afin que chaque composant pointe vers son fichier source correct. Pour la liste complète des propriétés prises en charge, consultez la [taxonomie des propriétés GitLab CycloneDX](../../../../development/sec/cyclonedx_property_taxonomy.md).

Pour plus d'informations, consultez le [ticket 542813](https://gitlab.com/gitlab-org/gitlab/-/work_items/542813) et la [merge request 221549](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/221549).

## L'analyse des vulnérabilités affiche un fichier d'entrée incorrect pour toutes les dépendances {#vulnerability-scanning-shows-wrong-input-file-for-all-dependencies}

Toutes les dépendances dans le rapport de vulnérabilités ou la liste des dépendances affichent le même chemin de fichier d'entrée, même si elles proviennent de fichiers de verrouillage différents.

Ce problème se produit lorsque la propriété `gitlab:dependency_scanning:input_file:path` est définie dans `metadata.properties` plutôt que par composant. Conformément à la [taxonomie des propriétés](../../../../development/sec/cyclonedx_property_taxonomy.md), les propriétés au niveau des métadonnées s'appliquent à tous les objets du document, de sorte qu'une seule valeur remplace tous les composants.

Pour résoudre ce problème, définissez `input_file:path` dans le tableau `properties` de chaque composant individuellement, et non dans les métadonnées de niveau supérieur. La propriété `input_file:path` est particulièrement importante pour les SBOM fusionnés contenant des composants provenant de différents fichiers de verrouillage.

## Erreur : `node with package name <package_name> does not exist` {#error-node-with-package-name-package_name-does-not-exist}

Ce problème se produit lorsque le gestionnaire de paquets, généralement nuget, est incapable de trouver le paquet. Cela peut se produire parce que l'image utilisée pour construire l'application est différente de celle utilisée pour exécuter l'analyse des dépendances.

Pour résoudre ce problème, utilisez la même image .NET SDK que celle utilisée par le scanner de dépendances pour construire votre application. Vous pouvez trouver l'image exacte en exécutant :

```shell
curl --silent "https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium/-/raw/master/build/gemnasium/alpine/Dockerfile" | grep "vrange-nuget-build" | grep "FROM"
```

Vérifiez le Dockerfile lié ci-dessus pour la version actuelle de l'image.
