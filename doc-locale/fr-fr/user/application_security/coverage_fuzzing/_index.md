---
stage: Application Security Testing
group: Dynamic Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Tests à données aléatoires guidés par la couverture de code (déprécié)
description: "Tests à données aléatoires guidés par la couverture de code, entrées aléatoires et comportements inattendus."
---

<!--- start_remove The following content will be removed on remove_date: '2026-08-15' -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

> [!warning]
> Cette fonctionnalité a été [dépréciée](https://gitlab.com/gitlab-org/gitlab/-/issues/517841) dans GitLab 18.0 et est prévue pour suppression dans la version 19.0. Il s'agit d'un changement majeur.

## Premiers pas {#getting-started}

Les tests à données aléatoires guidés par la couverture de code envoient des entrées aléatoires à une version instrumentée de votre application dans le but de provoquer des comportements inattendus. Un tel comportement indique un bug que vous devez corriger. GitLab vous permet d'ajouter des tests à données aléatoires guidés par la couverture de code à vos pipelines. Cela vous aide à découvrir des bugs et des problèmes de sécurité potentiels que d'autres processus d'assurance qualité pourraient manquer.

Vous devez utiliser les tests à données aléatoires en complément des autres scanners de sécurité dans [GitLab Secure](../_index.md) et de vos propres processus de test. Si vous utilisez [GitLab CI/CD](../../../ci/_index.md), vous pouvez exécuter vos tests à données aléatoires guidés par la couverture de code dans le cadre de votre workflow CI/CD.

<i class="fa-youtube-play" aria-hidden="true"></i> Pour une présentation générale, consultez [Coverage-guided Fuzzing - Advanced Security Testing](https://www.youtube.com/watch?v=bbIenVVcjW0).

### Confirmer le statut des tests à données aléatoires guidés par la couverture de code {#confirm-status-of-coverage-guided-fuzz-testing}

Pour confirmer le statut des tests à données aléatoires guidés par la couverture de code :

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à** et repérez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Sécurisation** > **Configuration de la sécurité**.
1. Dans la section **Tests à données aléatoires guidés par la couverture de code**, le statut est :
   - **Non configuré**
   - **Activé**
   - Une invite pour passer à GitLab Ultimate.

### Activer les tests à données aléatoires guidés par la couverture de code {#enable-coverage-guided-fuzz-testing}

Pour activer les tests à données aléatoires guidés par la couverture de code, modifiez `.gitlab-ci.yml` :

1. Ajoutez l'étape `fuzz` à la liste des étapes.
1. Si votre application n'est pas écrite en Go, [fournissez une image Docker](../../../ci/yaml/_index.md#image) en utilisant le moteur de fuzzing correspondant. Par exemple :

   ```yaml
   image: python:latest
   ```

1. [Incluez](../../../ci/yaml/_index.md#includetemplate) le [modèle `Coverage-Fuzzing.gitlab-ci.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Security/Coverage-Fuzzing.gitlab-ci.yml) fourni dans le cadre de votre installation GitLab.

1. Personnalisez le job `my_fuzz_target` selon vos besoins.

### Exemple d'extrait de configuration de tests à données aléatoires guidés par la couverture de code {#example-extract-of-coverage-guided-fuzzing-configuration}

```yaml
stages:
  - fuzz

include:
  - template: Coverage-Fuzzing.gitlab-ci.yml

my_fuzz_target:
  extends: .fuzz_base
  script:
    # Build your fuzz target binary in these steps, then run it with gitlab-cov-fuzz
    # See our example repos for how you could do this with any of our supported languages
    - ./gitlab-cov-fuzz run --regression=$REGRESSION -- <your fuzz target>
```

Le modèle `Coverage-Fuzzing` inclut le [job masqué](../../../ci/jobs/_index.md#hide-a-job) `.fuzz_base`, que vous devez [étendre](../../../ci/yaml/_index.md#extends) pour chacune de vos cibles de fuzzing. Chaque cible de fuzzing **doit** avoir un job distinct. Par exemple, le [projet go-fuzzing-example](https://gitlab.com/gitlab-org/security-products/demos/go-fuzzing-example) contient un job qui étend `.fuzz_base` pour sa cible de fuzzing unique.

Le job masqué `.fuzz_base` utilise plusieurs clés YAML que vous ne devez pas remplacer dans votre propre job. Si vous incluez ces clés dans votre propre job, vous devez copier leur contenu d'origine :

- `before_script`
- `artifacts`
- `rules`

## Comprendre les résultats {#understanding-the-results}

### Sortie {#output}

Chaque étape de fuzzing produit les artefacts suivants :

- `gl-coverage-fuzzing-report.json` : un rapport contenant les détails des tests à données aléatoires guidés par la couverture de code et leurs résultats.
- `artifacts.zip` : ce fichier contient deux répertoires :
  - `corpus` : contient tous les cas de test générés par le job actuel et tous les jobs précédents.
  - `crashes` : contient tous les événements de plantage détectés par le job actuel et ceux non corrigés dans les jobs précédents.

Vous pouvez télécharger le fichier de rapport JSON depuis la page des pipelines CI/CD. Pour plus d'informations, consultez [Téléchargement des artefacts](../../../ci/jobs/job_artifacts.md#download-job-artifacts).

### Registre de corpus {#corpus-registry}

Le registre de corpus est une bibliothèque de corpus. Les corpus du registre de paquets d'un projet sont disponibles pour tous les jobs de ce projet. Un registre à l'échelle du projet est une méthode plus efficace pour gérer les corpus que l'option par défaut d'un corpus par job.

Le registre de corpus utilise le registre de paquets pour stocker les corpus du projet. Les corpus stockés dans le registre sont masqués pour garantir l'intégrité des données.

Lorsque vous téléchargez un corpus, le fichier est nommé `artifacts.zip`, quel que soit le nom de fichier utilisé lors du téléversement initial du corpus. Ce fichier contient uniquement le corpus, ce qui diffère des fichiers d'artefacts que vous pouvez télécharger depuis le pipeline CI/CD. De plus, un membre du projet disposant du privilège Reporter ou supérieur peut télécharger le corpus via le lien de téléchargement direct.

#### Afficher les détails du registre de corpus {#view-details-of-the-corpus-registry}

Pour afficher les détails du registre de corpus :

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à** et repérez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Sécurisation** > **Configuration de la sécurité**.
1. Dans la section **Tests à données aléatoires guidés par la couverture de code**, sélectionnez **Gestion de corpus**.

#### Créer un corpus dans le registre de corpus {#create-a-corpus-in-the-corpus-registry}

Pour créer un corpus dans le registre de corpus, vous pouvez :

- Créer un corpus dans un pipeline.
- Téléverser un fichier de corpus existant.

##### Créer un corpus dans un pipeline {#create-a-corpus-in-a-pipeline}

Pour créer un corpus dans un pipeline :

1. Dans le fichier `.gitlab-ci.yml`, modifiez le job `my_fuzz_target`.
1. Définissez les variables suivantes :
   - Définissez `COVFUZZ_USE_REGISTRY` sur `true`.
   - Définissez `COVFUZZ_CORPUS_NAME` pour nommer le corpus.
   - Définissez `COVFUZZ_GITLAB_TOKEN` sur la valeur du jeton d'accès personnel.

Une fois le job `my_fuzz_target` exécuté, le corpus est stocké dans le registre de corpus, avec le nom fourni par la variable `COVFUZZ_CORPUS_NAME`. Le corpus est mis à jour à chaque exécution du pipeline.

##### Téléverser un fichier de corpus {#upload-a-corpus-file}

Pour téléverser un fichier de corpus existant :

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à** et repérez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Sécurisation** > **Configuration de la sécurité**.
1. Dans la section **Tests à données aléatoires guidés par la couverture de code**, sélectionnez **Gestion de corpus**.
1. Sélectionnez **Nouveau corpus**.
1. Remplissez les champs.
1. Sélectionnez **Téléverser un fichier**.
1. Sélectionnez **Ajouter**.

Vous pouvez maintenant référencer le corpus dans le fichier `.gitlab-ci.yml`. Assurez-vous que la valeur utilisée dans la variable `COVFUZZ_CORPUS_NAME` correspond exactement au nom donné au fichier de corpus téléversé.

### Utiliser un corpus stocké dans le registre de corpus {#use-a-corpus-stored-in-the-corpus-registry}

Pour utiliser un corpus stocké dans le registre de corpus, vous devez le référencer par son nom. Pour confirmer le nom du corpus concerné, consultez les détails du registre de corpus.

Prérequis :

- [Activer les tests à données aléatoires guidés par la couverture de code](#enable-coverage-guided-fuzz-testing) dans le projet.

1. Définissez les variables suivantes dans le fichier `.gitlab-ci.yml` :
   - Définissez `COVFUZZ_USE_REGISTRY` sur `true`.
   - Définissez `COVFUZZ_CORPUS_NAME` sur le nom du corpus.
   - Définissez `COVFUZZ_GITLAB_TOKEN` sur la valeur du jeton d'accès personnel.

### Rapport de tests à données aléatoires guidés par la couverture de code {#coverage-guided-fuzz-testing-report}

Pour des informations détaillées sur le format du fichier `gl-coverage-fuzzing-report.json`, consultez le [schéma](https://gitlab.com/gitlab-org/security-products/security-report-schemas/-/blob/master/dist/coverage-fuzzing-report-format.json).

Exemple de rapport de tests à données aléatoires guidés par la couverture de code :

```json
{
  "version": "v1.0.8",
  "regression": false,
  "exit_code": -1,
  "vulnerabilities": [
    {
      "category": "coverage_fuzzing",
      "message": "Heap-buffer-overflow\nREAD 1",
      "description": "Heap-buffer-overflow\nREAD 1",
      "severity": "Critical",
      "stacktrace_snippet": "INFO: Seed: 3415817494\nINFO: Loaded 1 modules   (7 inline 8-bit counters): 7 [0x10eee2470, 0x10eee2477), \nINFO: Loaded 1 PC tables (7 PCs): 7 [0x10eee2478,0x10eee24e8), \nINFO:        5 files found in corpus\nINFO: -max_len is not provided; libFuzzer will not generate inputs larger than 4096 bytes\nINFO: seed corpus: files: 5 min: 1b max: 4b total: 14b rss: 26Mb\n#6\tINITED cov: 7 ft: 7 corp: 5/14b exec/s: 0 rss: 26Mb\n=================================================================\n==43405==ERROR: AddressSanitizer: heap-buffer-overflow on address 0x602000001573 at pc 0x00010eea205a bp 0x7ffee0d5e090 sp 0x7ffee0d5e088\nREAD of size 1 at 0x602000001573 thread T0\n    #0 0x10eea2059 in FuzzMe(unsigned char const*, unsigned long) fuzz_me.cc:9\n    #1 0x10eea20ba in LLVMFuzzerTestOneInput fuzz_me.cc:13\n    #2 0x10eebe020 in fuzzer::Fuzzer::ExecuteCallback(unsigned char const*, unsigned long) FuzzerLoop.cpp:556\n    #3 0x10eebd765 in fuzzer::Fuzzer::RunOne(unsigned char const*, unsigned long, bool, fuzzer::InputInfo*, bool*) FuzzerLoop.cpp:470\n    #4 0x10eebf966 in fuzzer::Fuzzer::MutateAndTestOne() FuzzerLoop.cpp:698\n    #5 0x10eec0665 in fuzzer::Fuzzer::Loop(std::__1::vector\u003cfuzzer::SizedFile, fuzzer::fuzzer_allocator\u003cfuzzer::SizedFile\u003e \u003e\u0026) FuzzerLoop.cpp:830\n    #6 0x10eead0cd in fuzzer::FuzzerDriver(int*, char***, int (*)(unsigned char const*, unsigned long)) FuzzerDriver.cpp:829\n    #7 0x10eedaf82 in main FuzzerMain.cpp:19\n    #8 0x7fff684fecc8 in start+0x0 (libdyld.dylib:x86_64+0x1acc8)\n\n0x602000001573 is located 0 bytes to the right of 3-byte region [0x602000001570,0x602000001573)\nallocated by thread T0 here:\n    #0 0x10ef92cfd in wrap__Znam+0x7d (libclang_rt.asan_osx_dynamic.dylib:x86_64+0x50cfd)\n    #1 0x10eebdf31 in fuzzer::Fuzzer::ExecuteCallback(unsigned char const*, unsigned long) FuzzerLoop.cpp:541\n    #2 0x10eebd765 in fuzzer::Fuzzer::RunOne(unsigned char const*, unsigned long, bool, fuzzer::InputInfo*, bool*) FuzzerLoop.cpp:470\n    #3 0x10eebf966 in fuzzer::Fuzzer::MutateAndTestOne() FuzzerLoop.cpp:698\n    #4 0x10eec0665 in fuzzer::Fuzzer::Loop(std::__1::vector\u003cfuzzer::SizedFile, fuzzer::fuzzer_allocator\u003cfuzzer::SizedFile\u003e \u003e\u0026) FuzzerLoop.cpp:830\n    #5 0x10eead0cd in fuzzer::FuzzerDriver(int*, char***, int (*)(unsigned char const*, unsigned long)) FuzzerDriver.cpp:829\n    #6 0x10eedaf82 in main FuzzerMain.cpp:19\n    #7 0x7fff684fecc8 in start+0x0 (libdyld.dylib:x86_64+0x1acc8)\n\nSUMMARY: AddressSanitizer: heap-buffer-overflow fuzz_me.cc:9 in FuzzMe(unsigned char const*, unsigned long)\nShadow bytes around the buggy address:\n  0x1c0400000250: fa fa fd fa fa fa fd fa fa fa fd fa fa fa fd fa\n  0x1c0400000260: fa fa fd fa fa fa fd fa fa fa fd fa fa fa fd fa\n  0x1c0400000270: fa fa fd fa fa fa fd fa fa fa fd fa fa fa fd fa\n  0x1c0400000280: fa fa fd fa fa fa fd fa fa fa fd fa fa fa fd fa\n  0x1c0400000290: fa fa fd fa fa fa fd fa fa fa fd fa fa fa fd fa\n=\u003e0x1c04000002a0: fa fa fd fa fa fa fd fa fa fa fd fa fa fa[03]fa\n  0x1c04000002b0: fa fa fa fa fa fa fa fa fa fa fa fa fa fa fa fa\n  0x1c04000002c0: fa fa fa fa fa fa fa fa fa fa fa fa fa fa fa fa\n  0x1c04000002d0: fa fa fa fa fa fa fa fa fa fa fa fa fa fa fa fa\n  0x1c04000002e0: fa fa fa fa fa fa fa fa fa fa fa fa fa fa fa fa\n  0x1c04000002f0: fa fa fa fa fa fa fa fa fa fa fa fa fa fa fa fa\nShadow byte legend (one shadow byte represents 8 application bytes):\n  Addressable:           00\n  Partially addressable: 01 02 03 04 05 06 07 \n  Heap left redzone:       fa\n  Freed heap region:       fd\n  Stack left redzone:      f1\n  Stack mid redzone:       f2\n  Stack right redzone:     f3\n  Stack after return:      f5\n  Stack use after scope:   f8\n  Global redzone:          f9\n  Global init order:       f6\n  Poisoned by user:        f7\n  Container overflow:      fc\n  Array cookie:            ac\n  Intra object redzone:    bb\n  ASan internal:           fe\n  Left alloca redzone:     ca\n  Right alloca redzone:    cb\n  Shadow gap:              cc\n==43405==ABORTING\nMS: 1 EraseBytes-; base unit: de3a753d4f1def197604865d76dba888d6aefc71\n0x46,0x55,0x5a,\nFUZ\nartifact_prefix='./crashes/'; Test unit written to ./crashes/crash-0eb8e4ed029b774d80f2b66408203801cb982a60\nBase64: RlVa\nstat::number_of_executed_units: 122\nstat::average_exec_per_sec:     0\nstat::new_units_added:          0\nstat::slowest_unit_time_sec:    0\nstat::peak_rss_mb:              28",
      "scanner": {
        "id": "libFuzzer",
        "name": "libFuzzer"
      },
      "location": {
        "crash_address": "0x602000001573",
        "crash_state": "FuzzMe\nstart\nstart+0x0\n\n",
        "crash_type": "Heap-buffer-overflow\nREAD 1"
      },
      "tool": "libFuzzer"
    }
  ]
}
```

### Interagir avec les vulnérabilités {#interacting-with-the-vulnerabilities}

Après la détection d'une vulnérabilité, vous pouvez [y remédier](../vulnerabilities/_index.md). L'onglet **Rapports** de la merge request répertorie la vulnérabilité et contient un bouton pour télécharger les artefacts de fuzzing. En sélectionnant l'une des vulnérabilités détectées, vous pouvez en consulter les détails.

Vous pouvez également consulter la vulnérabilité depuis le [Security Dashboard](../security_dashboard/_index.md), qui présente une vue d'ensemble de toutes les vulnérabilités de sécurité dans vos groupes, projets et pipelines.

La sélection de la vulnérabilité ouvre une fenêtre modale qui fournit des informations supplémentaires sur la vulnérabilité :

- Statut : le statut de la vulnérabilité. Comme pour tout type de vulnérabilité, une vulnérabilité de fuzzing par couverture peut être Détectée, Confirmée, Ignorée ou Résolue.
- Projet : le projet dans lequel la vulnérabilité existe.
- Type de plantage : le type de plantage ou de faiblesse dans le code. Cela correspond généralement à un [CWE](https://cwe.mitre.org/).
- État de plantage : une version normalisée de la trace de pile, contenant les trois dernières fonctions du plantage (sans adresses aléatoires).
- Extrait de trace de pile : les dernières lignes de la trace de pile, qui affichent les détails du plantage.
- Identifiant : l'identifiant de la vulnérabilité. Cela correspond à un [CVE](https://cve.mitre.org/) ou un [CWE](https://cwe.mitre.org/).
- Gravité :  la gravité de la vulnérabilité. Elle peut être Critique, Élevée, Moyenne, Faible, Info ou Inconnue.
- Analyseur :  le scanner qui a détecté la vulnérabilité (par exemple, Coverage Fuzzing).
- Fournisseur du scanner : le moteur qui a effectué le scan. Pour Coverage Fuzzing, il peut s'agir de l'un des moteurs répertoriés dans [Moteurs de fuzzing et langages pris en charge](#supported-fuzzing-engines-and-languages).

## Optimisation {#optimization}

Utilisez les options de personnalisation suivantes pour optimiser les tests à données aléatoires guidés par la couverture de code pour votre projet.

### Variables CI/CD disponibles {#available-cicd-variables}

Utilisez les variables suivantes pour configurer les tests à données aléatoires guidés par la couverture de code dans votre pipeline CI/CD.

> [!warning]
> Toutes les personnalisations des outils de scan de sécurité GitLab doivent être testées dans une merge request avant d'être fusionnées dans la branche par défaut. Ne pas le faire peut donner des résultats inattendus, y compris un grand nombre de faux positifs.

| Variable CI/CD            | Description                                                                     |
|---------------------------|---------------------------------------------------------------------------------|
| `COVFUZZ_ADDITIONAL_ARGS` | Arguments transmis à `gitlab-cov-fuzz`. Utilisé pour personnaliser le comportement du moteur de fuzzing sous-jacent. Consultez la documentation du moteur de fuzzing pour obtenir la liste complète des arguments. |
| `COVFUZZ_BRANCH`          | La branche sur laquelle les jobs de fuzzing de longue durée doivent être exécutés. Sur toutes les autres branches, seuls les tests de régression de fuzzing sont exécutés. Par défaut : branche par défaut du dépôt. |
| `COVFUZZ_SEED_CORPUS`     | Chemin vers un répertoire de corpus de départ. Par défaut : vide. |
| `COVFUZZ_URL_PREFIX`      | Chemin vers le dépôt `gitlab-cov-fuzz` cloné pour une utilisation dans un environnement hors ligne. Vous ne devez modifier cette valeur que lorsque vous utilisez un environnement hors ligne. Par défaut : `https://gitlab.com/gitlab-org/security-products/analyzers/gitlab-cov-fuzz/-/raw`. |
| `COVFUZZ_USE_REGISTRY`    | Définissez sur `true` pour que le corpus soit stocké dans le registre de corpus GitLab. Les variables `COVFUZZ_CORPUS_NAME` et `COVFUZZ_GITLAB_TOKEN` sont requises si cette variable est définie sur `true`. Par défaut : `false`. |
| `COVFUZZ_CORPUS_NAME`     | Nom du corpus à utiliser dans le job. |
| `COVFUZZ_GITLAB_TOKEN`    | Variable d'environnement configurée avec un [jeton d'accès personnel](../../profile/personal_access_tokens.md#create-a-personal-access-token) ou un [jeton d'accès au projet](../../project/settings/project_access_tokens.md#create-a-project-access-token) avec accès en lecture/écriture à l'API. |

#### Corpus de départ {#seed-corpus}

Les fichiers du [corpus de départ](../terminology/_index.md#seed-corpus) doivent être mis à jour manuellement. Ils ne sont pas mis à jour ni écrasés par le job de tests à données aléatoires guidés par la couverture de code.

### Processus de tests à données aléatoires guidés par la couverture de code {#coverage-guided-fuzz-testing-process}

Le processus de tests à données aléatoires :

1. Compile l'application cible.
1. Exécute l'application instrumentée à l'aide de l'outil `gitlab-cov-fuzz`.
1. Analyse et traite les informations d'exception produites par le fuzzer.
1. Télécharge le [corpus](../terminology/_index.md#corpus) depuis :
   - Les pipelines précédents.
   - Si `COVFUZZ_USE_REGISTRY` est défini sur `true`, le [registre de corpus](#corpus-registry).
1. Télécharge les événements de plantage du pipeline précédent.
1. Produit les événements de plantage analysés et les données dans le fichier `gl-coverage-fuzzing-report.json`.
1. Met à jour le corpus, soit :
   - Dans le pipeline du job.
   - Si `COVFUZZ_USE_REGISTRY` est défini sur `true`, dans le registre de corpus.

Les résultats des tests à données aléatoires guidés par la couverture de code sont disponibles dans le pipeline CI/CD.

## Déploiement {#roll-out}

Une fois que vous êtes à l'aise avec les tests à données aléatoires guidés par la couverture de code dans un seul projet, vous pouvez tirer parti des fonctionnalités avancées suivantes, notamment l'activation des tests dans des environnements hors ligne.

### Moteurs de fuzzing et langages pris en charge {#supported-fuzzing-engines-and-languages}

Vous pouvez utiliser les moteurs de fuzzing suivants pour tester les langages spécifiés.

| Langage                                    | Moteur de fuzzing                                                                                       | Exemple                                                                                                                         |
|---------------------------------------------|------------------------------------------------------------------------------------------------------|---------------------------------------------------------------------------------------------------------------------------------|
| C/C++                                       | [libFuzzer](https://llvm.org/docs/LibFuzzer.html)                                                    | [c-cpp-example](https://gitlab.com/gitlab-org/security-products/demos/coverage-fuzzing/c-cpp-fuzzing-example)                   |
| Go                                          | [go-fuzz (libFuzzer support)](https://github.com/dvyukov/go-fuzz)                                    | [go-fuzzing-example](https://gitlab.com/gitlab-org/security-products/demos/coverage-fuzzing/go-fuzzing-example)                 |
| Swift                                       | [libFuzzer](https://github.com/apple/swift/blob/master/docs/libFuzzerIntegration.md)                 | [swift-fuzzing-example](https://gitlab.com/gitlab-org/security-products/demos/coverage-fuzzing/swift-fuzzing-example)           |
| Rust                                        | [cargo-fuzz (libFuzzer support)](https://github.com/rust-fuzz/cargo-fuzz)                            | [rust-fuzzing-example](https://gitlab.com/gitlab-org/security-products/demos/coverage-fuzzing/rust-fuzzing-example)             |
| Java (Maven uniquement)<sup>1</sup>               | [Javafuzz](https://gitlab.com/gitlab-org/security-products/analyzers/fuzzers/javafuzz) (recommandé) | [javafuzz-fuzzing-example](https://gitlab.com/gitlab-org/security-products/demos/coverage-fuzzing/javafuzz-fuzzing-example)     |
| Java                                        | [JQF](https://github.com/rohanpadhye/JQF) (non recommandé)                                            | [jqf-fuzzing-example](https://gitlab.com/gitlab-org/security-products/demos/coverage-fuzzing/java-fuzzing-example)              |
| JavaScript                                  | [`jsfuzz`](https://gitlab.com/gitlab-org/security-products/analyzers/fuzzers/jsfuzz)                 | [jsfuzz-fuzzing-example](https://gitlab.com/gitlab-org/security-products/demos/coverage-fuzzing/jsfuzz-fuzzing-example)         |
| Python                                      | [`pythonfuzz`](https://gitlab.com/gitlab-org/security-products/analyzers/fuzzers/pythonfuzz)         | [pythonfuzz-fuzzing-example](https://gitlab.com/gitlab-org/security-products/demos/coverage-fuzzing/pythonfuzz-fuzzing-example) |
| AFL (tout langage fonctionnant sur AFL) | [AFL](https://lcamtuf.coredump.cx/afl/)                                                              | [afl-fuzzing-example](https://gitlab.com/gitlab-org/security-products/demos/coverage-fuzzing/afl-fuzzing-example)               |

1. La prise en charge de Gradle est prévue dans le ticket [409764](https://gitlab.com/gitlab-org/gitlab/-/issues/409764).

### Durée des tests à données aléatoires guidés par la couverture de code {#duration-of-coverage-guided-fuzz-testing}

Les durées disponibles pour les tests à données aléatoires guidés par la couverture de code sont :

- Durée de 10 minutes (par défaut) : recommandé pour la branche par défaut.
- Durée de 60 minutes : recommandé pour la branche de développement et les merge requests. La durée plus longue offre une couverture accrue. Dans la variable `COVFUZZ_ADDITIONAL_ARGS`, définissez la valeur `--regression=true`.

Pour un exemple complet, consultez l'[exemple de fuzzing guidé par la couverture de code en Go](https://gitlab.com/gitlab-org/security-products/demos/coverage-fuzzing/go-fuzzing-example/-/blob/master/.gitlab-ci.yml).

#### Tests à données aléatoires guidés par la couverture de code en continu {#continuous-coverage-guided-fuzz-testing}

Il est également possible d'exécuter les jobs de fuzzing guidés par la couverture de code plus longtemps et sans bloquer votre pipeline principal. Cette configuration utilise les [pipelines parent-enfant](../../../ci/pipelines/downstream_pipelines.md#parent-child-pipelines) GitLab.

Le workflow suggéré dans ce scénario consiste à avoir des jobs de fuzzing asynchrones de longue durée sur la branche principale ou de développement, et des jobs de fuzzing synchrones de courte durée sur toutes les autres branches et merge requests. Cela équilibre les besoins de complétion rapide du pipeline par commit tout en laissant au fuzzer suffisamment de temps pour explorer et tester l'application en profondeur. Les jobs de fuzzing de longue durée sont généralement nécessaires pour que le fuzzer guidé par la couverture de code puisse détecter des bugs plus profonds dans votre base de code.

Ce qui suit est un extrait du fichier `.gitlab-ci.yml` pour ce workflow. Pour l'exemple complet, consultez le [dépôt de l'exemple de fuzzing en Go](https://gitlab.com/gitlab-org/security-products/demos/coverage-fuzzing/go-fuzzing-example/-/tree/continuous_fuzzing) :

```yaml

sync_fuzzing:
  variables:
    COVFUZZ_ADDITIONAL_ARGS: '-max_total_time=300'
  trigger:
    include: .covfuzz-ci.yml
    strategy: depend
  rules:
    - if: $CI_COMMIT_BRANCH != 'continuous_fuzzing' && $CI_PIPELINE_SOURCE != 'merge_request_event'

async_fuzzing:
  variables:
    COVFUZZ_ADDITIONAL_ARGS: '-max_total_time=3600'
  trigger:
    include: .covfuzz-ci.yml
  rules:
    - if: $CI_COMMIT_BRANCH == 'continuous_fuzzing' && $CI_PIPELINE_SOURCE != 'merge_request_event'
```

Cela crée deux jobs :

1. `sync_fuzzing` : exécute toutes vos cibles de fuzzing pendant une courte période dans une configuration bloquante. Cela détecte les bugs simples et vous permet d'être confiant que vos merge requests n'introduisent pas de nouveaux bugs ni ne font réapparaître d'anciens bugs.
1. `async_fuzzing` : s'exécute sur votre branche et détecte des bugs profonds dans votre code sans bloquer votre cycle de développement et vos merge requests.

Le fichier `covfuzz-ci.yml` est identique à celui de l'[exemple synchrone d'origine](https://gitlab.com/gitlab-org/security-products/demos/coverage-fuzzing/go-fuzzing-example#running-go-fuzz-from-ci).

### Binaire compatible FIPS {#fips-enabled-binary}

Le binaire de fuzzing par couverture est compilé avec `golang-fips` sur Linux x86 et utilise OpenSSL comme backend cryptographique. Pour plus de détails, consultez la conformité FIPS chez GitLab avec Go.

### Environnement hors ligne {#offline-environment}

Pour utiliser le fuzzing par couverture dans un environnement hors ligne :

1. Clonez [`gitlab-cov-fuzz`](https://gitlab.com/gitlab-org/security-products/analyzers/gitlab-cov-fuzz) dans un dépôt privé auquel votre instance GitLab hors ligne peut accéder.

1. Pour chaque étape de fuzzing, définissez `COVFUZZ_URL_PREFIX` sur `${NEW_URL_GITLAB_COV_FUZ}/-/raw`, où `NEW_URL_GITLAB_COV_FUZ` est l'URL du clone privé de `gitlab-cov-fuzz` que vous avez configuré à la première étape.

## Dépannage {#troubleshooting}

### Erreur `Unable to extract corpus folder from artifacts zip file` {#error-unable-to-extract-corpus-folder-from-artifacts-zip-file}

Si vous voyez ce message d'erreur et que `COVFUZZ_USE_REGISTRY` est défini sur `true`, assurez-vous que le fichier de corpus téléversé se décompresse dans un dossier nommé `corpus`.

### Erreur `400 Bad request - Duplicate package is not allowed` {#error-400-bad-request---duplicate-package-is-not-allowed}

Si vous voyez ce message d'erreur lors de l'exécution du job de fuzzing avec `COVFUZZ_USE_REGISTRY` défini sur `true`, assurez-vous que les doublons sont autorisés. Pour plus de détails, consultez [les paquets génériques en double](../../packages/generic_packages/_index.md#disable-publishing-duplicate-package-names).

<!--- end_remove -->
