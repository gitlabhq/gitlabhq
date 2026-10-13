---
stage: Application Security Testing
group: Secret Detection
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Détection des secrets des pipelines
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

La détection des secrets des pipelines analyse les fichiers une fois qu'ils ont fait l'objet d'un commit dans un dépôt Git, puis d'un push vers GitLab.

Après avoir [activé la détection des secrets des pipelines](#getting-started), les analyses s'exécutent dans un job CI/CD nommé `secret_detection`. Vous pouvez exécuter des analyses et consulter les [artefacts de rapport JSON de détection des secrets des pipelines](../../../../ci/yaml/artifacts_reports.md#artifactsreportssecret_detection) dans n'importe quelle édition de GitLab.

Avec GitLab Ultimate, GitLab traite aussi les résultats de la détection des secrets dans les pipelines. Vous pouvez alors :

- Les consulter dans les [rapports de merge request](../../../project/merge_requests/reports.md), le [rapport de sécurité du pipeline](../../detect/security_scanning_results.md) et le [rapport de vulnérabilités](../../vulnerability_report/_index.md).
- Les utiliser dans les workflows d'approbation.
- Les examiner dans le tableau de bord de sécurité.
- [Répondre automatiquement](../automatic_response.md) aux fuites dans les dépôts publics.
- Appliquer des règles de détection des secrets cohérentes dans l'ensemble des projets au moyen des [politiques de sécurité](../../policies/_index.md).

<i class="fa-youtube-play" aria-hidden="true"></i> Pour une lecture interactive et une démonstration pratique de cette documentation sur la détection des secrets dans les pipelines, consultez :

- [Comment activer la détection des secrets dans GitLab Application Security, partie 1/2](https://youtu.be/dbMxeO6nJCE?feature=shared)
- [Comment activer la détection des secrets dans GitLab Application Security, partie 2/2](https://youtu.be/VL-_hdiTazo?feature=shared)

<i class="fa-youtube-play" aria-hidden="true"></i> Pour d'autres lectures interactives et démonstrations pratiques, consultez la [playlist Get Started With GitLab Application Security](https://www.youtube.com/playlist?list=PL05JrBw4t0KrUrjDoefSkgZLx5aJYFaF9).

## Disponibilité {#availability}

Différentes fonctionnalités sont disponibles selon les [éditions de GitLab](https://about.gitlab.com/pricing/).

| Capacité                                                              | Édition Gratuite et GitLab Premium | GitLab Ultimate |
|:------------------------------------------------------------------------|:------------------|:------------|
| [Personnaliser le comportement de l'analyseur](configure.md#customize-analyzer-behavior) | {{< yes >}}       | {{< yes >}} |
| Télécharger la [sortie](#secret-detection-results)                            | {{< yes >}}       | {{< yes >}} |
| Voir les nouveaux résultats dans les rapports de merge request                               | {{< no >}}        | {{< yes >}} |
| Afficher les secrets identifiés dans l'onglet **Sécurité** des pipelines              | {{< no >}}        | {{< yes >}} |
| [Gérer les vulnérabilités](../../vulnerability_report/_index.md)          | {{< no >}}        | {{< yes >}} |
| [Accéder au tableau de bord de sécurité](../../security_dashboard/_index.md)     | {{< no >}}        | {{< yes >}} |
| [Personnaliser les ensembles de règles de l'analyseur](configure.md#customize-analyzer-rulesets) | {{< no >}}        | {{< yes >}} |
| [Activer les politiques de sécurité](../../policies/_index.md)                    | {{< no >}}        | {{< yes >}} |

## Premiers pas {#getting-started}

Pour commencer, sélectionnez un projet pilote, puis activez l'analyseur de détection des secrets dans les pipelines.

Prérequis :

- Disposer d'un runner Linux avec l'exécuteur [`docker`](https://docs.gitlab.com/runner/executors/docker/) ou [`kubernetes`](https://docs.gitlab.com/runner/install/kubernetes/). Si vous utilisez des runners hébergés pour GitLab.com, cette configuration est activée par défaut.
  - Les runners Windows ne sont pas pris en charge.
  - Les architectures CPU autres que amd64 ne sont pas prises en charge.
- Disposer d'un fichier `.gitlab-ci.yml` qui inclut l'étape `test`.

Activez l'analyseur de détection des secrets selon l'une des méthodes suivantes :

- Modifier manuellement le fichier `.gitlab-ci.yml`. Utilisez cette méthode si votre configuration CI/CD est complexe.
- Utiliser une merge request configurée automatiquement. Utilisez cette méthode si vous n'avez pas de configuration CI/CD ou si votre configuration est minimale.
- Activer la détection des secrets des pipelines dans une [politique d'exécution de scan](../../policies/scan_execution_policies.md).

Lors de la première analyse de détection des secrets dans un projet, exécutez une analyse historique juste après l'activation de l'analyseur.

Une fois la détection des secrets dans les pipelines activée, vous pouvez [personnaliser les paramètres de l'analyseur](configure.md).

### Modifier manuellement le fichier `.gitlab-ci.yml` {#edit-the-gitlab-ciyml-file-manually}

Cette méthode nécessite que vous modifiiez manuellement un fichier `.gitlab-ci.yml` existant.

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à** et repérez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Version** > **Éditeur de pipeline**.
1. Copiez et collez ce qui suit à la fin du fichier `.gitlab-ci.yml` :

   ```yaml
   include:
     - template: Jobs/Secret-Detection.gitlab-ci.yml
   ```

1. Sélectionnez l'onglet **Valider**, puis sélectionnez **Valider le pipeline**. Le message **Simulation terminée avec succès** indique que le fichier est valide.
1. Sélectionnez l'onglet **Éditer**.
1. Facultatif. Dans la zone de texte **Message de commit**, personnalisez le message de commit.
1. Dans la zone de texte **Branche**, saisissez le nom de la branche par défaut.
1. Sélectionnez **Valider les modifications**.

Les pipelines incluent désormais un job de détection des secrets dans les pipelines. Envisagez d'[exécuter une analyse historique](#run-a-historic-scan) après avoir activé l'analyseur.

### Utiliser une merge request configurée automatiquement {#use-an-automatically-configured-merge-request}

Cette méthode prépare automatiquement une merge request pour ajouter un fichier `.gitlab-ci.yml` qui contient le modèle de détection des secrets dans les pipelines. Fusionnez la merge request pour activer la détection des secrets dans les pipelines.

Pour activer la détection des secrets dans les pipelines :

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à** et repérez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Sécurisation** > **Configuration de la sécurité**.
1. Dans la ligne **Détection des secrets des pipelines**, sélectionnez **Configurer avec une requête de fusion**.
1. Facultatif. Remplissez les champs.
1. Sélectionnez **Créer une requête de fusion**.
1. Examinez et fusionnez la merge request.

Les pipelines incluent désormais un job de détection des secrets dans les pipelines.

## Couverture {#coverage}

La détection des secrets des pipelines est optimisée pour équilibrer la couverture et la durée d'exécution. Seuls l'état actuel du dépôt et les commits ultérieurs sont analysés à la recherche de secrets. Pour identifier les secrets déjà présents dans l'historique du dépôt, exécutez une seule analyse historique après avoir activé la détection des secrets des pipelines. Les résultats de l'analyse ne sont disponibles qu'une fois le pipeline terminé.

Les éléments analysés à la recherche de secrets dépendent du type de pipeline et de l'éventuelle configuration supplémentaire.

Par défaut, lorsque vous exécutez un pipeline :

- Sur une branche :
  - Sur la **branche par défaut** :
    - Dans la version `v7.38.1` et les versions ultérieures de l'analyseur, si un commit précédent valide est disponible via la [variable CI/CD prédéfinie](../../../../ci/variables/predefined_variables.md) `CI_COMMIT_BEFORE_SHA`, le contenu de tous les commits du commit précédent au commit actuel est analysé.
    - Si aucun commit précédent valide n'est disponible (par exemple, lors du premier commit poussé vers un nouveau dépôt), le contenu de l'arbre de travail Git est analysé.
  - Sur une **branche de fonctionnalité** :
    - Dans la version `v7.35.0` et les versions ultérieures de l'analyseur, le contenu de tous les commits depuis la base de fusion jusqu'au commit le plus récent (tous les commits propres à la branche après sa divergence) est analysé. Ce comportement s'applique à tous les pipelines de branches de fonctionnalité lorsque la base de fusion est disponible.
    - À partir de GitLab 19.1, GitLab expose le SHA de la base de merge au moyen de la [variable CI prédéfinie](../../../../ci/variables/predefined_variables.md) `CI_COMMIT_DEFAULT_BRANCH_BASE_SHA`.
    - Dans les versions de GitLab antérieures à GitLab 19.1, ou lorsque la base de merge n'est pas disponible, l'analyseur revient au comportement précédent :
      - Sur les nouvelles branches de fonctionnalité, seul le commit le plus récent est analysé. Les commits antérieurs de la branche sont exclus de l'analyse.
      - Sur les branches de fonctionnalité existantes, tous les commits postérieurs au dernier commit envoyé par push, jusqu'au commit le plus récent inclus, sont analysés.

    > [!note]
    > Pour analyser tous les commits depuis le point de divergence de la branche à chaque exécution, activez les [pipelines de requête de fusion](../../../../ci/pipelines/merge_request_pipelines.md).
- Dans le cas d'une **merge request**, le contenu de tous les commits de la branche est analysé. Si l'analyseur ne peut pas accéder à tous les commits, il analyse le contenu de tous les commits compris entre le commit parent et le commit le plus récent. Pour analyser tous les commits, vous devez activer les [pipelines de merge request](../../detect/security_configuration.md#use-security-scanning-tools-with-merge-request-pipelines).

Pour remplacer le comportement par défaut, utilisez les [variables CI/CD disponibles](configure.md#available-cicd-variables).

### Récupération des commits par l'analyseur {#how-the-analyzer-fetches-commits}

Par défaut, lorsque GitLab clone un dépôt pour la première fois, il ne récupère que les commits les plus récents, sous la forme d'un « clone superficiel ». Lorsque des commits supplémentaires sont nécessaires en plus de ce clone initial, l'analyseur les récupère automatiquement à l'aide de stratégies optimisées :

- Pour les merge requests, l'analyseur récupère uniquement les changements apportés par les commits postérieurs à la base de merge, ce qui réduit au minimum le transfert de données.
- Si des options de log sont indiquées, comme `--since` ou `--max-count`, l'analyseur récupère uniquement les commits requis.
- Lors d'une analyse historique, l'analyseur récupère l'historique complet du dépôt. Si le dépôt a fait l'objet d'un clone superficiel, l'analyseur utilise l'option `--unshallow`.

Si l'analyseur ne peut pas récupérer les commits requis, il se replie sur l'analyse des données disponibles :

- Après une poussée forcée, l'analyseur analyse uniquement l'état actuel du dépôt.
- En cas de défaillances réseau, l'analyseur analyse les commits disponibles après le clone initial.
- En cas de dépassement de délai, l'analyseur poursuit l'analyse avec un historique de commits partiel.

Ces mécanismes de repli permettent au pipeline de se terminer correctement, même dans des environnements restreints.

### Profondeur du clone initial du dépôt {#initial-repository-clone-depth}

Le paramètre [`GIT_DEPTH`](../../../../ci/runners/configure_runners.md#shallow-cloning) du runner contrôle le nombre de commits clonés initialement. La détection des secrets des pipelines récupère automatiquement les commits supplémentaires si nécessaire. Vous n'avez donc généralement pas besoin de modifier ce paramètre.

Si vous rencontrez des problèmes persistants liés à des commits manquants dans des environnements réseau restreints, consultez la section de dépannage pour connaître les solutions de contournement.

### Exécuter une analyse historique {#run-a-historic-scan}

Par défaut, la détection des secrets des pipelines analyse uniquement l'état actuel du dépôt Git. Les secrets présents dans l'historique du dépôt ne sont pas détectés. Exécutez une analyse historique pour rechercher les secrets présents dans l'ensemble des commits et des branches du dépôt Git.

Vous devez exécuter une analyse historique une seule fois, après avoir activé la détection des secrets des pipelines. Les analyses historiques peuvent prendre beaucoup de temps, en particulier dans les dépôts volumineux dont l'historique Git est long. Une fois l'analyse historique initiale terminée, utilisez uniquement la détection standard des secrets des pipelines dans votre pipeline.

Si vous activez la détection des secrets des pipelines avec une [politique d'exécution de scan](../../policies/scan_execution_policies.md#scanner-behavior), la première analyse planifiée est par défaut une analyse historique.

Pour exécuter une analyse historique :

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à** et repérez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Version** > **Pipelines**.
1. Sélectionnez **Nouveau pipeline**.
1. Ajoutez une variable CI/CD :
   1. Dans la liste déroulante, sélectionnez **Variable**.
   1. Dans la zone **Nom de la variable d'entrée**, saisissez `SECRET_DETECTION_HISTORIC_SCAN`.
   1. Dans la zone **Valeur de la variable d'entrée**, saisissez `true`.
1. Sélectionnez **Nouveau pipeline**.

### Suivi des vulnérabilités en double {#duplicate-vulnerability-tracking}

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Introduction](https://gitlab.com/gitlab-org/gitlab/-/issues/434096) dans GitLab 17.0.

{{< /history >}}

La détection des secrets utilise un algorithme avancé de suivi des vulnérabilités afin d'empêcher la création de résultats en double et de vulnérabilités en double lorsqu'un fichier est refactorisé ou déplacé.

Aucun nouveau résultat n'est créé dans les cas suivants :

- Un secret est déplacé au sein d'un fichier.
- Un secret en double apparaît dans un fichier.

Le suivi des vulnérabilités en double s'effectue fichier par fichier. Si le même secret apparaît dans deux fichiers différents, deux résultats sont créés.

Pour plus d'informations, consultez le projet confidentiel `https://gitlab.com/gitlab-org/security-products/post-analyzers/tracking-calculator`. Ce projet est réservé aux membres de l'équipe GitLab.

#### Workflows non pris en charge {#unsupported-workflows}

Le suivi des vulnérabilités en double ne prend pas en charge les workflows dans lesquels :

- Le résultat existant ne possède pas de signature de suivi et n'a pas le même emplacement que le nouveau résultat.
- Certains secrets sont détectés à partir de leurs préfixes plutôt qu'à partir de leur valeur complète. Pour ces types de secrets, toutes les détections du même type et présentes dans le même fichier sont signalées sous la forme d'un résultat unique.

  Par exemple, une clé privée SSH est détectée à partir de son préfixe `-----BEGIN OPENSSH PRIVATE KEY-----`. Si plusieurs clés privées SSH se trouvent dans le même fichier, la détection des secrets des pipelines ne crée qu'un seul résultat.
- Lorsque vous exécutez une analyse historique ou que vous activez la détection des secrets des pipelines sur des commits existants, si un secret est introduit dans un commit puis modifié dans un commit ultérieur au cours de la même analyse, seule la valeur la plus récente de ce secret apparaît dans le rapport de vulnérabilités.

### Secrets détectés {#detected-secrets}

La détection des secrets des pipelines analyse le contenu du dépôt à la recherche de motifs spécifiques. Chaque motif correspond à un type de secret spécifique et est défini dans une règle au moyen de la syntaxe TOML. GitLab tient à jour l'ensemble de règles par défaut.

Avec GitLab Ultimate, vous pouvez étendre ces règles en fonction de vos besoins. Par défaut, les jetons d'accès personnels qui utilisent un préfixe personnalisé ne sont pas détectés. Vous pouvez toutefois personnaliser les règles pour les identifier. Pour en savoir plus, reportez-vous à la section [Personnaliser les ensembles de règles de l'analyseur](configure.md#customize-analyzer-rulesets).

Pour vérifier quels secrets sont détectés par la détection des secrets des pipelines, consultez [Secrets détectés](../detected_secrets.md). Pour fournir des résultats fiables avec un niveau de confiance élevé, la détection des secrets des pipelines ne recherche les mots de passe ou autres secrets non structurés que dans des contextes précis, par exemple les URL.

Lorsqu'un secret est détecté, une vulnérabilité est créée pour celui-ci. La vulnérabilité conserve le statut « Détection toujours active », même si le secret est supprimé du fichier analysé et que la détection des secrets des pipelines est réexécutée. En effet, le secret divulgué continue de présenter un risque de sécurité tant qu'il n'a pas été révoqué. Les secrets supprimés persistent également dans l'historique Git. Pour supprimer un secret de l'historique du dépôt Git, reportez-vous à la section [Expurger du texte du dépôt](../../../project/repository/repository_size.md#redact-text-from-repository).

### Éléments exclus {#excluded-items}

Pour améliorer les performances, la détection des secrets des pipelines exclut automatiquement certains types de fichiers et certains répertoires peu susceptibles de contenir des secrets.

Les éléments suivants sont exclus :

| Catégorie                            | Éléments exclus                                                                                                                                                                                                                                                                                                                                                                                                                                             |
|-------------------------------------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| Fichiers de configuration             | Fichiers : `gitleaks.toml`, `verification-metadata.xml`, `Database.refactorlog`, `.editorconfig`, `.gitattributes`                                                                                                                                                                                                                                                                                                                                             |
| Fichiers multimédias et binaires           | Extensions : `.bmp`, `.gif`, `.svg`, `.jpg/.jpeg`, `.png`, `.tiff/.tif`, `.webp`, `.ico`, `.heic`<br/>Polices : `.eot`, `.otf`, `.ttf`, `.woff`, `.woff2`<br/>Documents : `.doc/.docx`, `.xls/.xlsx`, `.ppt/.pptx`, `.pdf`<br/>Audio/vidéo : `.mp3`, `.mp4`, `.wav`, `.flac`, `.aac`, `.ogg`, `.avi`, `.mkv`, `.mov`, `.wmv`, `.flv`, `.webm`<br/>Archives : `.zip`, `.rar`, `.7z`, `.tar`, `.gz`, `.bz2`, `.xz`, `.dmg`, `.iso`<br/>Exécutables : `.exe`, `.gltf` |
| Fichiers Visual Studio             | Extensions : `.socket`, `.vsidx`, `.suo`, `.wsuo`, `.dll`, `.pdb`                                                                                                                                                                                                                                                                                                                                                                                           |
| Fichiers de verrouillage de paquets              | Fichiers : `deno.lock`, `npm-shrinkwrap.json`, `package-lock.json`, `pnpm-lock.yaml`, `yarn.lock`, `Pipfile.lock`, `poetry.lock`, `gradle.lockfile`, `Cargo.lock`, `composer.lock`                                                                                                                                                                                                                                                                             |
| Fichiers en langage Go               | Extensions : `go.mod`, `go.sum`, `go.work`, `go.work.sum`<br/>Répertoires : `vendor/` (uniquement pour les modules Go provenant de `github.com`, `golang.org`, `google.golang.org`, `gopkg.in`, `istio.io`, `k8s.io`, `sigs.k8s.io`)<br/>Fichiers : `vendor/modules.txt`                                                                                                                                                                                                            |
| Fichiers Ruby                      | Répertoires : `.bundle/`, `gems/`, `specifications/`<br/>Extensions : fichiers `.gem` dans le répertoire `gems/`, fichiers `.gemspec` dans le répertoire `specifications/`                                                                                                                                                                                                                                                                                                     |
| Wrappers d'outils de version             | Fichiers : `gradlew`, `gradlew.bat`, `mvnw`, `mvnw.cmd`<br/>Répertoires : `.mvn/wrapper/`<br/>Cas particulier : `MavenWrapperDownloader.java` dans le répertoire du wrapper Maven                                                                                                                                                                                                                                                                                                |
| Répertoires de dépendances          | Répertoires : `node_modules/`, `bower_components/`, `packages/`                                                                                                                                                                                                                                                                                                                                                                                             |
| Répertoires de sortie de version        | Répertoires : `target/`, `build/`, `bin/`, `obj/`                                                                                                                                                                                                                                                                                                                                                                                                           |
| Répertoires vendor             | Répertoires : `vendor/bundle/`, `vendor/ruby/`, `vendor/composer/`                                                                                                                                                                                                                                                                                                                                                                                          |
| Fichiers de cache Python              | Extensions : `.pyc`, `.pyo`<br/>Répertoires : `__pycache__/`                                                                                                                                                                                                                                                                                                                                                                                                 |
| Caches des outils Python              | Répertoires : `.pytest_cache/`, `.mypy_cache/`, `.tox/`                                                                                                                                                                                                                                                                                                                                                                                                     |
| Environnements virtuels Python     | Répertoires : `venv/`, `virtualenv/`, `.venv/`, `env/`                                                                                                                                                                                                                                                                                                                                                                                                      |
| Répertoires d'installation Python | Répertoires : `lib/python[version]/`, `lib64/python[version]/`, `python[version]/lib/`, `python[version]/Lib/`                                                                                                                                                                                                                                                                                                                                              |
| Métadonnées de paquets Python        | Noms de paquets se terminant par une version et `.dist-info`                                                                                                                                                                                                                                                                                                                                                                                                         |
| Bibliothèques JavaScript            | Fichiers : `angular*.js`, `bootstrap*.js`, `jquery*.js`, `jquery-ui*.js`, `plotly*.js`, `swagger-ui*.js` <br/>Source maps : Fichiers `.js.map` correspondants                                                                                                                                                                                                                                                                                                       |
| Ressources minifiées/regroupées         | Extensions : `.min.js`, `.min.css`, `.bundle.js`, `.bundle.css`, `.map` (fichiers de source map)                                                                                                                                                                                                                                                                                                                                                                  |
| Fichiers compilés                  | Extensions : `.class`, `.o`, `.obj`, `.jar`, `.war` (archive Web), `.ear`                                                                                                                                                                                                                                                                                                                                                                                   |
| Répertoires de cache             | Répertoires : `.cache/`, `.coverage/`, `.pytest_cache/`, `.mypy_cache/`, `.tox/`                                                                                                                                                                                                                                                                                                                                                                            |
| Documentation générée         | Répertoires : `htmlcov/`, `coverage/`, `_build/`, `_site/`, `docs/_build/`                                                                                                                                                                                                                                                                                                                                                                                  |
| Contrôle de version et IDE           | Répertoires : `.git/`, `.svn/`, `.hg/`, `.bzr/` (contrôle de version), `.vscode/`, `.idea/`, `.eclipse/`, `.vs/` (IDE)                                                                                                                                                                                                                                                                                                                                         |
| Fichiers du système d'exploitation          | Fichiers : `.DS_Store`, `Thumbs.db`                                                                                                                                                                                                                                                                                                                                                                                                                            |

## Résultats de la détection des secrets {#secret-detection-results}

La détection des secrets des pipelines produit le fichier `gl-secret-detection-report.json` sous forme d'artefact de job. Le fichier contient les secrets détectés. Vous pouvez [télécharger](../../../../ci/jobs/job_artifacts.md#download-job-artifacts) le fichier afin de le traiter en dehors de GitLab.

Pour en savoir plus, reportez-vous au [schéma du fichier de rapport](https://gitlab.com/gitlab-org/security-products/security-report-schemas/-/blob/master/dist/secret-detection-report-format.json) et à l'[exemple de fichier de rapport](https://gitlab.com/gitlab-org/security-products/analyzers/secrets/-/blob/master/qa/expect/secrets/gl-secret-detection-report.json).

### Sortie supplémentaire {#additional-output}

{{< details >}}

- Édition : GitLab Ultimate

{{< /details >}}

Les résultats des jobs sont également affichés dans les emplacements suivants :

- [Rapports de merge request](../../../project/merge_requests/reports.md) : affichent les nouveaux résultats introduits dans la merge request.
- [Rapport de sécurité du pipeline](../../detect/security_scanning_results.md) : affiche tous les résultats issus de la dernière exécution du pipeline.
- [Rapport de vulnérabilités](../../vulnerability_report/_index.md) : centralise la gestion de tous les résultats de sécurité.
- Tableau de bord de sécurité : donne une vue d'ensemble, à l'échelle de l'organisation, de toutes les vulnérabilités des projets et des groupes.

## Comprendre les résultats {#understanding-the-results}

La détection des secrets des pipelines fournit des informations détaillées sur les secrets potentiels repérés dans votre dépôt. Chaque secret détecté indique le type de secret divulgué et les consignes de remédiation à appliquer.

Lorsque vous passez les résultats en revue :

1. Examinez le code environnant pour déterminer si le motif détecté correspond bien à un secret.
1. Vérifiez si la valeur détectée correspond à un identifiant d'authentification valide.
1. Tenez compte de la visibilité du dépôt et de la portée du secret.
1. Traitez en priorité les secrets actifs dotés de privilèges élevés.

### Catégories de détection courantes {#common-detection-categories}

Les détections produites par la détection des secrets des pipelines relèvent souvent de l'une des trois catégories suivantes :

- **Vrais positifs** : véritables secrets qui doivent être renouvelés et supprimés. Par exemple :
  - Clés API actives, mots de passe de base de données, jetons d'authentification
  - Clés privées et certificats
  - Identifiants de compte de service
- **Faux positifs** : modèles détectés qui ne sont pas de véritables secrets. Par exemple :
  - Valeurs d'exemple dans la documentation
  - Données de test ou identifiants fictifs
  - Modèles de configuration contenant des valeurs indicatives
- **Résultats issus de l'historique** : secrets précédemment commités qui peuvent ne plus être actifs. Ces détections :
  - Nécessitent une investigation pour déterminer leur statut actuel
  - Doivent tout de même être renouvelés par précaution

## Remédier à un secret divulgué {#remediate-a-leaked-secret}

Lorsqu'un secret est détecté, vous devez le renouveler immédiatement. GitLab tente de [révoquer automatiquement](../automatic_response.md) certains types de secrets divulgués. Pour les secrets qui ne sont pas révoqués automatiquement, vous devez effectuer cette opération manuellement.

[La purge d'un secret de l'historique du dépôt](../../../project/repository/repository_size.md#purge-files-from-repository-history) ne permet pas de traiter entièrement la fuite. Le secret d'origine reste présent dans tous les forks ou clones existants du dépôt.

Pour savoir comment réagir à un secret divulgué, sélectionnez la vulnérabilité dans le rapport de vulnérabilités.

## Optimisation {#optimization}

Avant de déployer la détection des secrets des pipelines dans l'ensemble de votre organisation, optimisez la configuration afin de réduire les faux positifs et d'améliorer la précision dans votre environnement.

Les faux positifs peuvent provoquer une lassitude face aux alertes et réduire la confiance dans l'outil. Envisagez d'utiliser une configuration personnalisée d'ensemble de règles (GitLab Ultimate uniquement) :

- Excluez les motifs propres à votre base de code que vous savez sûrs.
- Ajustez la sensibilité des règles qui se déclenchent fréquemment sur des éléments qui ne sont pas des secrets.
- Ajoutez des règles personnalisées pour les formats de secrets propres à votre organisation.

Pour optimiser les performances dans les dépôts volumineux ou les organisations qui comptent de nombreux projets, passez en revue les points suivants :

- Gestion de la portée de l'analyse :
  - Désactivez l'analyse historique après l'avoir exécutée dans un projet.
  - Planifiez les analyses historiques pendant les périodes de faible utilisation.
- Allocation des ressources :
  - Allouez suffisamment de ressources de runner aux dépôts volumineux.
  - Envisagez d'utiliser des runners dédiés pour les charges de travail liées aux analyses de sécurité.
  - Surveillez la durée des analyses et ajustez la configuration en fonction de la taille du dépôt.

### Tester les modifications apportées à l'optimisation {#testing-optimization-changes}

Avant d'appliquer les optimisations à l'échelle de l'organisation :

1. Vérifiez que les optimisations ne laissent pas passer de véritables secrets.
1. Mesurez la réduction du nombre de faux positifs et l'amélioration des performances d'analyse.
1. Conservez une trace des pratiques d'optimisation efficaces.

## Déploiement {#roll-out}

Déployez progressivement la détection des secrets des pipelines. Commencez par un projet pilote à petite échelle afin de comprendre le comportement de l'outil avant de déployer la fonctionnalité à l'échelle de votre organisation.

Suivez ces recommandations lorsque vous déployez la détection des secrets des pipelines :

1. Choisissez un projet pilote. Les projets adaptés présentent les caractéristiques suivantes :
   - Un développement actif, avec des commits réguliers.
   - Une base de code d'une taille raisonnable.
   - Une équipe qui connaît GitLab CI/CD.
   - Une disposition à ajuster la configuration par itérations successives.
1. Commencez par une configuration simple. Activez la détection des secrets des pipelines dans votre projet pilote avec les paramètres par défaut.
1. Surveillez les résultats. Exécutez l'analyseur pendant une ou deux semaines afin de comprendre les résultats habituels.
1. Traitez les secrets détectés. Remédiez à tous les véritables secrets trouvés.
1. Affinez votre configuration. Ajustez les paramètres en fonction des résultats initiaux.
1. Documentez la mise en œuvre. Consignez les faux positifs courants et les schémas de remédiation récurrents.

## Images compatibles FIPS {#fips-enabled-images}

Les images de scanner par défaut sont construites à partir d'une image de base Alpine afin d'en limiter la taille et d'en faciliter la maintenance. GitLab propose des versions [Red Hat UBI](https://www.redhat.com/en/blog/introducing-red-hat-universal-base-image) de ces images, compatibles FIPS.

Pour utiliser les images compatibles FIPS, effectuez l'une des actions suivantes :

- Définir la variable CI/CD `SECRET_DETECTION_IMAGE_SUFFIX` sur `-fips`.
- Ajouter l'extension `-fips` au nom de l'image par défaut.

Par exemple :

```yaml
variables:
  SECRET_DETECTION_IMAGE_SUFFIX: '-fips'

include:
  - template: Jobs/Secret-Detection.gitlab-ci.yml
```

## Dépannage {#troubleshooting}

### Journalisation de niveau débogage {#debug-level-logging}

La journalisation de niveau débogage peut être utile lors du dépannage. Pour en savoir plus, reportez-vous à la section [Journalisation de niveau débogage](../../troubleshooting_application_security.md#turn-on-debug-level-logging).

#### Avertissement : `gl-secret-detection-report.json: no matching files` {#warning-gl-secret-detection-reportjson-no-matching-files}

Pour en savoir plus à ce sujet, reportez-vous à la [section générale de dépannage de la sécurité des applications](../../../../ci/jobs/job_artifacts_troubleshooting.md#error-message-no-files-to-upload).

#### Erreur : `Couldn't run the gitleaks command: exit status 2` {#error-couldnt-run-the-gitleaks-command-exit-status-2}

Cette erreur indique que l'analyseur ne peut pas accéder aux commits requis. Dans la plupart des cas, l'analyseur récupère automatiquement les commits manquants, mais des problèmes peuvent survenir dans des environnements restreints.

Pour diagnostiquer le problème, activez la [journalisation de niveau débogage](../../troubleshooting_application_security.md#turn-on-debug-level-logging) et recherchez :

```plaintext
ERRO[2020-11-18T18:05:52Z] object not found
[ERRO] [secrets] [2020-11-18T18:05:52Z] ▶ Couldn't run the gitleaks command: exit status 2
[ERRO] [secrets] [2020-11-18T18:05:52Z] ▶ Gitleaks analysis failed: exit status 2
```

Pour résoudre ce problème :

- Dans la plupart des cas, aucune action n'est requise. Laissez l'analyseur gérer automatiquement la récupération des commits.
- Pour les réseaux restreints, augmentez la profondeur du clone initial :

  ```yaml
  secret_detection:
    variables:
      GIT_DEPTH: 100  # or 0 to clone everything
  ```

- Pour les dépôts volumineux, limitez la portée de l'analyse :

  ```yaml
  secret_detection:
    variables:
      SECRET_DETECTION_LOG_OPTIONS: "--max-count=50"
  ```

#### Erreur : `ERR fatal: ambiguous argument` {#error-err-fatal-ambiguous-argument}

La pipeline de détection des secrets peut échouer avec le message `ERR fatal: ambiguous argument` si la branche par défaut de votre dépôt n'est pas liée à la branche pour laquelle le job a été déclenché. Pour en savoir plus, consultez le ticket [!352014](https://gitlab.com/gitlab-org/gitlab/-/issues/352014).

Pour résoudre le problème, veillez à [définir correctement votre branche par défaut](../../../project/repository/branches/default.md#change-the-default-branch-name-for-a-project) dans votre dépôt. Vous devez la définir sur une branche dont l'historique est lié à celui de la branche sur laquelle vous exécutez le job `secret-detection`.

#### Message `exec /bin/sh: exec format error` dans le job log {#exec-binsh-exec-format-error-message-in-job-log}

L'analyseur de détection des secrets des pipelines de GitLab [ne prend en charge](#getting-started) l'exécution que sur l'architecture CPU `amd64`. Ce message indique que le job s'exécute sur une autre architecture, par exemple `arm`.

#### Erreur : `fatal: detected dubious ownership in repository at '/builds/<project dir>'` {#error-fatal-detected-dubious-ownership-in-repository-at-buildsproject-dir}

La détection des secrets peut échouer avec le statut de sortie 128. Ce problème peut être dû à une modification de l'utilisateur dans l'image Docker.

Par exemple :

```shell
$ /analyzer run
[INFO] [secrets] [2024-06-06T07:28:13Z] ▶ GitLab secrets analyzer v6.0.1
[INFO] [secrets] [2024-06-06T07:28:13Z] ▶ Detecting project
[INFO] [secrets] [2024-06-06T07:28:13Z] ▶ Analyzer will attempt to analyze all projects in the repository
[INFO] [secrets] [2024-06-06T07:28:13Z] ▶ Loading ruleset for /builds....
[WARN] [secrets] [2024-06-06T07:28:13Z] ▶ /builds/....secret-detection-ruleset.toml not found, ruleset support will be disabled.
[INFO] [secrets] [2024-06-06T07:28:13Z] ▶ Running analyzer
[FATA] [secrets] [2024-06-06T07:28:13Z] ▶ get commit count: exit status 128
```

Pour contourner ce problème, ajoutez un élément `before_script` contenant ce qui suit :

```yaml
before_script:
    - git config --global --add safe.directory "$CI_PROJECT_DIR"
```

Pour en savoir plus sur ce problème, consultez le [ticket 465974](https://gitlab.com/gitlab-org/gitlab/-/issues/465974).

#### Modifier `GIT_DEPTH` ne change pas les éléments analysés {#adjusting-git_depth-doesnt-change-what-gets-scanned}

Ce comportement est attendu. `GIT_DEPTH` est une variable de runner qui s'applique au clone initial. Cette variable ne modifie pas le comportement de l'analyseur.

L'analyseur de détection des secrets détermine les éléments à analyser en fonction des facteurs suivants :

- Type de pipeline (push, merge request, planifié)
- Contexte de la branche (par défaut, nouvelle, existante)
- Votre configuration (`SECRET_DETECTION_LOG_OPTIONS`, `SECRET_DETECTION_HISTORIC_SCAN`)

Par exemple, pour analyser uniquement 30 commits :

```yaml
secret_detection:
  variables:
    # Scan the last 30 commits
    SECRET_DETECTION_LOG_OPTIONS: "--max-count=30"
```

Pour analyser uniquement les commits des deux dernières semaines :

```yaml
secret_detection:
  variables:
    # Scan commits made in the last two weeks
    SECRET_DETECTION_LOG_OPTIONS: "--since=2.weeks"
```

Pour analyser uniquement les commits compris entre `HEAD~10` et `HEAD` :

```yaml
secret_detection:
  variables:
    # Scan commits from HEAD~10 to HEAD
    SECRET_DETECTION_LOG_OPTIONS: "HEAD~10..HEAD"
```

Pour obtenir la liste complète des options, reportez-vous à la documentation sur les [options Git log](https://git-scm.com/docs/git-log).

#### Détection des poussées forcées {#force-push-detection}

Après une poussée forcée, le message suivant peut s'afficher :

```plaintext
Failed to retrieve all the commits from the last Git push event due to a force push
```

Ce comportement est attendu. L'analyse se poursuit à partir de l'état actuel du dépôt.

#### Configuration de la confiance du dépôt {#repository-trust-configuration}

Le message suivant peut s'afficher :

```plaintext
Added project directory to Git safe.directory configuration
```

Ce message signale une configuration de sécurité courante dans les environnements conteneurisés. Aucune action n'est requise.
