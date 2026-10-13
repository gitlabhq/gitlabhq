---
stage: Application Security Testing
group: Static Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: GitLab Advanced SAST utilise une analyse de taint inter-fichiers et inter-fonctions pour détecter des vulnérabilités complexes avec une haute précision.
title: Analyseur Advanced SAST de GitLab
---

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- Introduit dans GitLab 17.1 en tant que [version expérimentale](../../../policy/development_stages_support.md) pour Python.
- Prise en charge de Go et Java ajoutée dans la version 17.2.
- [Passage](https://gitlab.com/gitlab-org/gitlab/-/issues/461859) de la version expérimentale à la version bêta dans GitLab 17.2.
- Prise en charge de JavaScript, TypeScript et C# ajoutée dans la version 17.3.
- [Passage en disponibilité générale](https://gitlab.com/gitlab-org/gitlab/-/issues/474094) dans GitLab 17.3.
- Prise en charge de Java Server Pages (JSP) ajoutée dans GitLab 17.4.
- Prise en charge de PHP [ajoutée](https://gitlab.com/groups/gitlab-org/-/epics/14273) dans GitLab 18.1.
- Prise en charge de C/C++ [ajoutée](https://gitlab.com/groups/gitlab-org/-/work_items/14271) dans GitLab 18.6.
- Prise en charge de Swift et Objective-C [ajoutée](https://gitlab.com/groups/gitlab-org/-/work_items/16318) dans GitLab 19.3 en tant que [version bêta](../../../policy/development_stages_support.md#beta).

{{< /history >}}

GitLab Advanced SAST est un analyseur de test statique de sécurité des applications (SAST) qui utilise une analyse de taint inter-fonctions et inter-fichiers pour détecter des vulnérabilités complexes avec moins de faux positifs que les outils SAST traditionnels.

GitLab Advanced SAST est une fonctionnalité optionnelle. Lorsqu'il est activé, GitLab Advanced SAST analyse tous les fichiers de langages pris en charge à l'aide de son ensemble de règles prédéfini, tandis que l'analyseur SAST continue d'analyser les autres fichiers. Les deux analyseurs peuvent s'exécuter en parallèle. SAST et GitLab Advanced SAST n'ont pas une parité complète : chaque analyseur détecte certaines vulnérabilités que l'autre ne détecte pas. Un [processus de transition](#transitioning-from-semgrep-to-gitlab-advanced-sast) automatisé dédoublonne les résultats lorsque les deux analyseurs détectent la même vulnérabilité.

GitLab Advanced SAST effectue une analyse plus approfondie que l'analyseur SAST standard basé sur Semgrep. Cette approche globale peut améliorer la précision et réduire les faux positifs, mais nécessite davantage de ressources de calcul et une durée d'analyse plus longue.

<i class="fa-youtube-play" aria-hidden="true"></i> Pour un aperçu, consultez [GitLab Advanced SAST : Accelerating Vulnerability Resolution](https://youtu.be/xDa1MHOcyn8).
<!-- Video published on 2025-09-19 -->

Pour une visite guidée du produit, consultez la [visite guidée de GitLab Advanced SAST](https://gitlab.navattic.com/advanced-sast).

## Fonctionnalités {#features}

| Fonctionnalité                                                                      | SAST                                                                                                                                      | Advanced SAST                                                                                                                               |
|------------------------------------------------------------------------------|-------------------------------------------------------------------------------------------------------------------------------------------|---------------------------------------------------------------------------------------------------------------------------------------------|
| Profondeur d'analyse                                                            | Capacité limitée à détecter des vulnérabilités complexes ; l'analyse est limitée à un seul fichier et (avec quelques exceptions) à une seule fonction. | Détecte les vulnérabilités complexes grâce à une analyse de taint inter-fichiers et inter-fonctions.                                                            |
| Précision                                                                     | Plus susceptible de générer des faux positifs en raison d'un contexte limité.                                                                      | Génère moins de faux positifs en utilisant une analyse de taint inter-fichiers et inter-fonctions pour se concentrer sur les vulnérabilités réellement exploitables.      |
| Conseils de remédiation                                                         | Les résultats de vulnérabilité sont identifiés par numéro de ligne.                                                                                     | La [vue du flux de code](#code-flow) détaillée montre comment la vulnérabilité se propage dans le programme, permettant une remédiation plus rapide. |
| Fonctionne avec GitLab Duo Vulnerability Explanation et Vulnerability Resolution | Oui.                                                                                                                                      | Oui.                                                                                                                                        |
| Couverture des langages                                                            | [Plus étendue](_index.md#supported-languages-and-frameworks).                                                                           | [Plus limitée](#supported-languages).                                                                                                       |

## Activer GitLab Advanced SAST {#turn-on-gitlab-advanced-sast}

Suivez ces étapes pour activer GitLab Advanced SAST dans votre projet.

Prérequis :

- Disposer du rôle Chargé de maintenance ou Propriétaire pour le projet.
- Activez l'analyseur SAST standard. Pour en savoir plus, consultez [les prérequis SAST](_index.md#getting-started).
- Pour GitLab Self-Managed, utilisez une version GitLab prise en charge :
  - Version minimale : GitLab 17.1 ou version ultérieure
  - Version recommandée : GitLab 17.4 ou version ultérieure (inclut la vue du flux de code, la déduplication des vulnérabilités et les modèles mis à jour)
  - Compatibilité des modèles :
    - Modèle stable : GitLab 17.3 ou version ultérieure
    - Dernier modèle : GitLab 17.2 ou version ultérieure
    - Ne pas mélanger [les modèles stable et latest](../detect/security_configuration.md#template-editions) dans le même projet

Activer GitLab Advanced SAST :

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à** et repérez votre projet.
1. Accédez à **Compilation** > Éditeur de **pipeline**.
1. Créez ou modifiez votre fichier `.gitlab-ci.yml`.
1. Ajoutez la variable appropriée pour activer Advanced SAST :

   - Pour tous les langages pris en charge sauf C/C++ : `GITLAB_ADVANCED_SAST_ENABLED: 'true'`

   - Pour C/C++ : `GITLAB_ADVANCED_SAST_CPP_ENABLED: 'true'`

1. Sélectionnez l'onglet **Valider**, puis sélectionnez **Valider le pipeline**.

   Le message **Simulation terminée avec succès** confirme que le fichier est valide.
1. Sélectionnez l'onglet **Éditer**.
1. Remplissez les champs.
1. Cochez la case **Lancer une nouvelle merge request avec ces modifications**, puis sélectionnez **Valider les modifications**.
1. Remplissez les champs selon votre workflow standard, puis sélectionnez **Créer une requête de fusion**.
1. Examinez et modifiez la merge request selon votre workflow standard, puis sélectionnez **Fusionner**.

À ce stade, GitLab Advanced SAST est activé dans votre pipeline. Le code source pris en charge est analysé à la recherche de vulnérabilités lorsqu'un pipeline s'exécute. Le job correspondant apparaît dans l'étape `test` de votre pipeline.

Après avoir effectué ces étapes, vous pouvez :

- En savoir plus sur l'évaluation des [résultats de vulnérabilité](#vulnerability-results).
- Consulter les [conseils sur les performances d'analyse](#improve-scanning-performance).
- Planifier un [déploiement vers d'autres projets](#roll-out).

## Résultats de vulnérabilité {#vulnerability-results}

Les vulnérabilités de GitLab Advanced SAST incluent des informations détaillées pour vous aider à évaluer et à remédier aux problèmes de sécurité. Chaque vulnérabilité affiche :

- Description :  explique la cause de la vulnérabilité, son impact potentiel et les étapes de remédiation recommandées.
- Statut : indique si la vulnérabilité a été classée ou résolue.
- Gravité :  classifiée en six niveaux selon l'impact. [En savoir plus sur les niveaux de gravité](../vulnerabilities/severities.md).
- Emplacement :  affiche le nom du fichier et le numéro de ligne où le problème a été trouvé. La sélection du chemin de fichier ouvre la ligne correspondante dans la vue du code.
- Flux de code : le chemin emprunté par les données depuis l'entrée utilisateur (source) jusqu'à la ligne de code vulnérable.
- Analyseur :  identifie quel analyseur a détecté la vulnérabilité.
- Identifiants :  une liste de références utilisées pour classifier la vulnérabilité, telles que les identifiants CWE et les identifiants des règles qui l'ont détectée.

Les vulnérabilités SAST sont nommées d'après l'identifiant principal Common Weakness Enumeration (CWE) pour la vulnérabilité découverte. Pour plus d'informations sur la couverture SAST, voir [les règles SAST](rules.md).

### Afficher les résultats {#view-results}

Prérequis :

- Le rôle Gestionnaire de sécurité, Développeur, Chargé de maintenance ou Propriétaire pour le projet.

Pour afficher les vulnérabilités dans votre pipeline :

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à** et repérez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Compilation** > **Pipelines**.
1. Sélectionnez le pipeline.
1. Sélectionnez l'onglet **Sécurisation**.
1. Téléchargez les résultats ou sélectionnez une vulnérabilité pour afficher ses détails (Ultimate uniquement).

#### Flux de code {#code-flow}

{{< history >}}

- Introduit dans GitLab 17.3 [avec plusieurs feature flags](../../../administration/feature_flags/_index.md). Activés par défaut.
- Activé sur GitLab Self-Managed et GitLab Dedicated dans GitLab 17.7.
- Disponible en général dans GitLab 17.7. Tous les feature flags ont été supprimés.

{{< /history >}}

Pour certains types de vulnérabilités, GitLab Advanced SAST fournit des informations sur le flux de code. Le flow de code d'une vulnérabilité correspond au chemin suivi par les données depuis l'entrée utilisateur (source) jusqu'à la ligne de code vulnérable (sink), en passant par toutes les affectations, manipulations et opérations d'assainissement. Ces informations vous aident à comprendre et à évaluer le contexte, l'impact et le risque de la vulnérabilité. Les informations sur le flux de code sont disponibles pour les vulnérabilités détectées en traçant l'entrée d'une source vers un point de sortie (sink), notamment :

- Injection SQL
- Injection de commande
- Cross-site scripting (XSS)
- Traversée de chemin

Les informations sur le flux de code sont affichées dans l'onglet **Flux de données** et comprennent :

- Les étapes de la source au point de sortie (sink).
- Les fichiers concernés, y compris les extraits de code.

![Le flux de données d'une injection SQL, depuis le paramètre de requête qui fournit le terme de recherche jusqu'à la requête de base de données qui l'exécute](img/code_flow_view_v19_3.png)

## Langages pris en charge {#supported-languages}

{{< history >}}

- La prise en charge de la version C# [a été étendue de la version 10.0 à la version 13.0](https://gitlab.com/gitlab-org/gitlab/-/issues/570499) dans GitLab 18.6.

{{< /history >}}

GitLab Advanced SAST prend en charge les langages suivants :

- C# (jusqu'à la version 13.0 incluse)
- C/C++
- Go
- Java, y compris Java Server Pages (JSP)
- JavaScript, TypeScript
- Objective-C (version bêta)
- PHP
- Python
- Ruby
- Swift (version bêta)

GitLab Advanced SAST CPP nécessite une configuration supplémentaire, notamment une base de données de compilation. Pour en savoir plus, consultez [la configuration C/C++](advanced_sast_cpp.md). GitLab Advanced SAST CPP et Semgrep s'exécutent tous les deux pour les projets C/C++, chacun avec des ensembles de règles différents.

La prise en charge de Swift et Objective-C est en [version bêta](../../../policy/development_stages_support.md#beta). L'analyse s'exécute en tant que job CI/CD distinct, `gitlab-advanced-sast-ext`, lorsque GitLab Advanced SAST est activé et que le dépôt contient des fichiers Swift ou Objective-C. Aucune variable supplémentaire n'est requise. Pour en savoir plus, consultez [la configuration de Swift et Objective-C](advanced_sast_swift_objc.md).

### Problèmes connus de PHP {#php-known-issues}

Lors de l'analyse du code PHP, GitLab Advanced SAST présente les problèmes connus suivants :

- Inclusion de fichiers dynamique : les instructions d'inclusion de fichiers dynamique (`include`, `include_once`, `require`, `require_once`) utilisant des variables pour les chemins de fichiers ne sont pas prises en charge dans cette version. Seuls les chemins d'inclusion de fichiers statiques sont pris en charge pour l'analyse inter-fichiers. Consultez [le ticket 527341](https://gitlab.com/gitlab-org/gitlab/-/issues/527341).
- Sensibilité à la casse : la nature insensible à la casse de PHP pour les noms de fonctions, de classes et de méthodes n'est pas entièrement prise en charge dans l'analyse inter-fichiers. Consultez [le ticket 526528](https://gitlab.com/gitlab-org/gitlab/-/issues/526528).

## Améliorer les performances d'analyse {#improve-scanning-performance}

Les performances d'analyse de GitLab Advanced SAST sont principalement déterminées par la couverture du code et les ressources des runners. Pour améliorer les performances d'analyse de GitLab Advanced SAST, vous pouvez ajuster la couverture du code et les ressources des runners.

### Ajuster la couverture du code {#tune-code-coverage}

La couverture du code désigne la proportion de votre base de code analysée. GitLab Advanced SAST analyse tous les fichiers de langages pris en charge à l'aide de son ensemble de règles prédéfini. L'analyseur SAST basé sur Semgrep n'analyse pas ces fichiers. Un [processus de transition](#transitioning-from-semgrep-to-gitlab-advanced-sast) automatisé supprime les résultats en double lorsque les deux analyseurs détectent la même vulnérabilité.

Vous pouvez éventuellement [signaler les vulnérabilités non vérifiées](#report-unverified-vulnerabilities), lorsque le chemin complet de la source au point de sortie (sink) n'est pas identifié.

Par défaut, GitLab Advanced SAST analyse l'intégralité du dépôt. Vous pouvez ajuster la couverture du code en utilisant les méthodes suivantes :

- Exclure des chemins du dépôt pour réduire la quantité de code analysé.
- Exclure des lignes individuelles à l'aide de commentaires inline pour supprimer des résultats spécifiques.
- Activer l'analyse basée sur les diff pour analyser uniquement les fichiers modifiés dans une merge request (et leurs fichiers dépendants).
- Activer l'analyse incrémentielle, qui met en cache les résultats des analyses précédentes et réduit ainsi la charge de calcul.

L'analyse basée sur les diff et l'analyse incrémentielle peuvent être utilisées indépendamment ou conjointement pour améliorer les performances d'analyse.

Analyse basée sur les diff : analyse uniquement les fichiers modifiés et leurs dépendants dans les pipelines associés aux merge requests (pipelines de merge request ou pipelines de branche associés à une merge request), en échangeant une couverture complète contre la vitesse.

Analyse incrémentielle : met en cache les résultats d'analyse précédents et les réutilise dans les pipelines suivants, réduisant la durée d'analyse tout en maintenant une couverture complète des fichiers. Disponible dans tous les pipelines.

| Configuration                     | Pipelines associés aux merge requests              | Tous les autres pipelines                  |
|-----------------------------------|-------------------------------------------------|--------------------------------------|
| Aucune optimisation                   | Standard. Analyse tous les fichiers, sans cache.            | Standard. Analyse tous les fichiers, sans cache. |
| Analyse incrémentielle uniquement         | Rapide. Analyse tous les fichiers avec cache.               | Rapide. Analyse tous les fichiers avec cache.    |
| Analyse basée sur les diff uniquement          | Plus rapide. Analyse uniquement les fichiers modifiés, sans cache.     | Standard. Analyse tous les fichiers, sans cache. |
| Analyse basée sur les diff + analyse incrémentielle | La plus rapide. Analyse uniquement les fichiers modifiés avec cache.   | Rapide. Analyse tous les fichiers avec cache.    |

#### Exclure des chemins {#exclude-paths}

Pour réduire la durée d'analyse, excluez de l'analyse GitLab Advanced SAST les chemins peu susceptibles de contenir des vulnérabilités.

Lors de l'exclusion de chemins, soyez sélectif pour éviter de masquer des vulnérabilités. Effectuez les modifications de manière incrémentielle et testez l'effet sur la durée d'analyse après chaque exclusion.

Envisagez d'exclure les chemins contenant les éléments suivants :

- Migrations de base de données
- Tests unitaires
- Dépendances, telles que `node_modules/`
- Fichiers de build
- Informations de configuration
- Ressources statiques
- Données de test
- Infrastructure as Code

Prérequis :

- Disposer du rôle Chargé de maintenance ou Propriétaire pour le projet.

Pour exclure des chemins :

- Répertoriez les chemins exclus dans la variable CI/CD [`SAST_EXCLUDED_PATHS`](_index.md#vulnerability-filters).

#### Exclure des lignes {#exclude-lines}

Pour supprimer les résultats sur une ligne spécifique, ajoutez `gitlab-advanced-sast-exclude` à votre code source en tant que commentaire. Le tag est insensible à la casse et fonctionne avec n'importe quelle syntaxe de commentaire, par exemple `#`, `//` ou `--`.

Placez le commentaire soit sur la même ligne que le résultat, soit sur la ligne qui le précède immédiatement :

```python
# Suppress all findings on the next line (previous-line comment):
# gitlab-advanced-sast-exclude
result = db.execute(query)

# Suppress all findings inline:
result = db.execute(query)  # gitlab-advanced-sast-exclude
```

Pour supprimer les résultats de règles spécifiques uniquement, ajoutez `:` ou `=` suivi d'un ou plusieurs identifiants de règles séparés par des virgules :

```python
# gitlab-advanced-sast-exclude: rule-id-1, rule-id-2
result = db.execute(query)
```

Lorsqu'aucun identifiant de règle n'est spécifié, tous les résultats sur cette ligne sont supprimés.

#### Analyse basée sur les diff {#diff-based-scanning}

{{< history >}}

- [Introduction](https://gitlab.com/groups/gitlab-org/-/epics/16790) dans GitLab 18.5 [avec le feature flag](../../../administration/feature_flags/_index.md) `vulnerability_partial_scans`. Désactivées par défaut.
- [Activé sur GitLab.com, GitLab Self-Managed et GitLab Dedicated](https://gitlab.com/gitlab-org/gitlab/-/issues/552051) dans GitLab 18.5.
- [Disponible en général](https://gitlab.com/gitlab-org/gitlab/-/issues/552051) dans GitLab 18.6. Suppression du feature flag `vulnerability_partial_scans`.

{{< /history >}}

L'analyse basée sur les diff analyse uniquement les fichiers modifiés dans une merge request, ainsi que leurs fichiers dépendants. Cette approche ciblée réduit la durée d'analyse, ce qui permet d'obtenir un retour plus rapide pendant le développement.

Pour garantir une couverture complète, une analyse complète s'exécute sur la branche par défaut après la fusion de la merge request.

L'analyse basée sur les diff est prise en charge dans les pipelines de merge request et les pipelines de branche, sous les conditions suivantes :

- Pipelines de merge request : l'analyse basée sur les diff a lieu lorsque GitLab Advanced SAST est configuré pour s'exécuter sur les [pipelines de merge request](../detect/security_configuration.md#use-security-scanning-tools-with-merge-request-pipelines).
- Pipelines de branche : l'analyse basée sur les diff a lieu lorsqu'il y a exactement une merge request ouverte associée à la branche. S'il n'y en a aucune ou plus d'une, l'analyse revient à une analyse complète car elle ne peut pas déterminer contre quel commit la branche doit être comparée.

Lorsque l'analyse basée sur les diff est active :

- Seuls les fichiers qui ont été modifiés ou ajoutés dans la merge request, ainsi que leurs fichiers dépendants, sont analysés.
- Le job log inclut la sortie : `Running differential scan`. (Si elle est inactive, elle affiche : `Running
  full scan`.)
- Dans le rapport d'analyse de sécurité de la merge request, un onglet **Basée sur les diff** dédié affiche les résultats d'analyse pertinents.
- Dans l'onglet de sécurité du pipeline, une alerte intitulée **Partial SAST report** indique que seuls des résultats partiels sont inclus.

L'analyse basée sur les diff présente les problèmes connus suivants :

- Faux négatifs et faux positifs : l'analyse basée sur les diff peut ne pas capturer le graphe d'appels complet dans les fichiers analysés, ce qui peut entraîner des vulnérabilités manquées (faux négatifs) ou la réapparition de celles déjà résolues (faux positifs). Ce compromis réduit les temps d'analyse et permet un retour plus rapide pendant le développement. Pour une couverture complète, une analyse complète s'exécute toujours sur la branche par défaut.
- Couverture des fichiers d'en-tête C/C++ : l'analyse basée sur les diff ne prend pas entièrement en charge les fichiers d'en-tête C/C++. Les vulnérabilités qui s'étendent à la fois aux fichiers d'en-tête et aux fichiers source peuvent être détectées, mais celles situées entièrement dans les fichiers d'en-tête peuvent ne pas l'être.
- Vulnérabilités corrigées non signalées : pour éviter des résultats trompeurs, les vulnérabilités corrigées sont exclues de l'analyse basée sur les diff. Étant donné que seul un sous-ensemble de fichiers est analysé, le graphe d'appels complet n'est pas disponible, ce qui rend impossible la confirmation qu'une vulnérabilité a été corrigée. Une analyse complète s'exécute toujours sur la branche par défaut après la fusion, où les vulnérabilités corrigées sont signalées. Par conséquent, les éventuelles lacunes de l'analyse basée sur les diff sont atténuées par l'analyse complète qui s'exécute automatiquement lors des fusions vers la branche par défaut, garantissant ainsi une couverture complète. Cette approche en couches équilibre les boucles de retour rapide pendant le développement avec une analyse de sécurité approfondie avant que le code n'atteigne la production.

##### Activer l'analyse basée sur les diff {#turn-on-diff-based-scanning}

Prérequis :

- Disposer du rôle Chargé de maintenance ou Propriétaire pour le projet.

Pour activer l'analyse basée sur les diff dans les pipelines de merge request :

- Définissez la variable CI/CD `ADVANCED_SAST_PARTIAL_SCAN` sur `differential` dans le fichier `.gitlab-ci.yml` du projet.

##### Fichiers dépendants {#dependent-files}

Pour éviter de manquer des vulnérabilités inter-fichiers au-delà des fichiers modifiés, l'analyse basée sur les diff inclut leurs dépendants immédiats. Cela réduit les faux négatifs tout en maintenant des analyses rapides, bien que cela puisse produire des résultats imprécis dans des chaînes de dépendances plus profondes.

Les fichiers suivants sont inclus dans l'analyse :

- Fichiers modifiés (fichiers modifiés ou ajoutés dans la merge request)
- Fichiers dépendants (fichiers qui importent les fichiers modifiés)

Cette conception permet de détecter les flux de données inter-fichiers, tels que des données contaminées se déplaçant d'une fonction modifiée vers un appelant qui l'importe.

Les fichiers importés par les fichiers modifiés ne sont pas analysés car ils n'ont généralement pas d'impact sur le comportement ou le flux de données du code modifié.

Par exemple, considérons une merge request qui modifie le fichier B :

- Si le fichier A importe le fichier B, les fichiers A et B sont analysés.
- Si le fichier B importe le fichier C, seul le fichier B est analysé.

#### Analyse incrémentielle {#incremental-scanning}

{{< history >}}

- [Introduction](https://gitlab.com/groups/gitlab-org/-/work_items/15545) dans GitLab 18.11.

{{< /history >}}

L'analyse incrémentielle met en cache les résultats de l'analyse des signatures de taint entre les exécutions de pipeline. Lors des analyses suivantes, le code inchangé réutilise les signatures mises en cache au lieu d'être réanalysé, tandis que le code modifié ou nouveau est entièrement analysé. Cela réduit les temps d'analyse sur les grandes bases de code où la plupart des fichiers ne changent pas entre les commits.

L'analyse incrémentielle fonctionne comme suit :

1. Première analyse (exécution à froid) : l'analyseur effectue une analyse complète et crée un cache de signatures de taint. Le cache est stocké en tant qu'artefact CI (`ts-cache.sqlite.gz`).
1. Analyses suivantes (exécutions à chaud) : l'analyseur recherche dans les commits précédents un pipeline réussi contenant un artefact de cache. S'il est trouvé, le cache est récupéré et les résultats inchangés sont réutilisés. Une fois l'analyse terminée, le cache mis à jour est stocké en tant que nouvel artefact.

##### Invalidation du cache {#cache-invalidation}

Le cache est invalidé pour garantir la précision tout en maximisant la réutilisation :

Invalidation partielle : seules les entrées affectées sont recalculées, le reste du cache est réutilisé :

- Fichiers nouveaux ou modifiés : lorsqu'un fichier est ajouté, modifié, supprimé ou renommé, ses signatures mises en cache sont invalidées et recalculées lors de la prochaine analyse.
- Règles nouvelles ou modifiées : lorsque des règles de détection sont ajoutées ou modifiées, seules ces règles spécifiques sont recalculées sur la base de code.

Invalidation complète : l'intégralité du cache est reconstruite :

- Modifications du moteur : lorsque des modifications au niveau du moteur rendent le cache existant incompatible, un nouveau cache est généré automatiquement à partir d'une analyse complète.

##### Activer l'analyse incrémentielle {#turn-on-incremental-scanning}

Pour activer l'analyse incrémentielle :

- Définissez la variable CI/CD `GITLAB_ADV_SAST_INCR_SCAN` sur `true` dans le fichier `.gitlab-ci.yml` du projet :

  ```yaml
  gitlab-advanced-sast:
    variables:
      GITLAB_ADV_SAST_INCR_SCAN: "true"
  ```

##### Configurer la rétention du cache {#configure-cache-retention}

Le modèle CI/CD de SAST stocke l'artefact de cache avec une expiration par défaut de 3 jours. La variable `GITLAB_ADV_SAST_INCR_SCAN_SEARCH_PERIOD` contrôle jusqu'où l'analyseur recherche un artefact de cache (valeur par défaut : `3 days`).

Ces deux valeurs doivent être alignées. La période de recherche ne doit pas dépasser l'expiration de l'artefact, sinon l'analyseur peut rechercher des artefacts qui ont déjà expiré.

Pour personnaliser les deux valeurs, remplacez `artifacts:expire_in` et définissez la variable de période de recherche :

```yaml
gitlab-advanced-sast:
  variables:
    GITLAB_ADV_SAST_INCR_SCAN: "true"
    GITLAB_ADV_SAST_INCR_SCAN_SEARCH_PERIOD: "7 days"
  artifacts:
    paths:
      - gl-sast-report.json
      - ts-cache.sqlite.gz
    expire_in: 7 days
```

La période de recherche prend en charge un nombre suivi de `d`, `day` ou `days` (par exemple, `7 days`, `14d`).

##### Configurer le nom de job personnalisé {#configure-custom-job-name}

L'analyseur utilise le nom du job CI/CD pour identifier les artefacts du job qui contiennent le cache. Si vous renommez le job `gitlab-advanced-sast`, définissez `GITLAB_ADV_SAST_INCR_SCAN_CUSTOM_JOB_NAME` sur le nom personnalisé afin que la recherche de cache trouve le bon job :

```yaml
my-custom-sast-job:
  variables:
    GITLAB_ADV_SAST_INCR_SCAN: "true"
    GITLAB_ADV_SAST_INCR_SCAN_CUSTOM_JOB_NAME: "my-custom-sast-job"
```

##### Limites de taille du cache {#cache-size-limits}

Le cache est stocké en tant qu'artefact CI/CD compressé. Des limites de taille d'artefact s'appliquent :

- GitLab.com : taille maximale d'artefact de 1 Go.
- GitLab Self-Managed : taille maximale d'artefact par défaut de 100 Mo. Un administrateur peut ajuster cette limite dans les [paramètres CI/CD](../../../administration/cicd/limits.md#maximum-artifacts-size).

##### Stocker le cache dans un stockage d'objets externe {#store-cache-in-external-object-storage}

En alternative au stockage d'artefacts CI/CD, vous pouvez stocker le cache d'analyse incrémentielle dans un stockage d'objets externe. Utilisez cette méthode de stockage lorsque les limites de stockage d'artefacts sont une contrainte ou lorsque vous souhaitez gérer le cycle de vie du cache de manière indépendante. AWS S3 est pris en charge.

L'authentification utilise [OpenID Connect (OIDC)](../../../ci/cloud_services/_index.md) pour échanger des jetons de courte durée avec votre fournisseur de cloud. Vous n'avez pas besoin de stocker des informations d'identification à longue durée de vie en tant que variables CI/CD.

Prérequis :

- Un bucket S3.
- Un [fournisseur d'identité IAM OIDC configuré pour GitLab](../../../ci/cloud_services/aws/_index.md).
- Un rôle IAM avec les autorisations suivantes sur le bucket :
  - `s3:GetObject`
  - `s3:PutObject`
  - `s3:HeadObject`
- La politique de confiance du rôle IAM doit être limitée aux projets ou groupes qui nécessitent un accès (par exemple, `project_path:myorg/*` pour tous les projets d'un groupe).

Pour stocker le cache dans S3 :

1. Ajoutez cette configuration à votre `.gitlab-ci.yml` :

   ```yaml
   gitlab-advanced-sast:
     id_tokens:
       GITLAB_ADV_SAST_INCR_SCAN_OIDC_TOKEN:
         aud: https://gitlab.com
     variables:
       GITLAB_ADV_SAST_INCR_SCAN: "true"
       GITLAB_ADV_SAST_INCR_SCAN_STORAGE: "s3"
       GITLAB_ADV_SAST_INCR_SCAN_S3_BUCKET: "advanced-sast-cache"
       GITLAB_ADV_SAST_INCR_SCAN_S3_REGION: "us-east-1"
       GITLAB_ADV_SAST_INCR_SCAN_S3_ROLE_ARN: "arn:aws:iam::<account-id>:role/<role-name>"
   ```

1. Pour GitLab Self-Managed ou GitLab Dedicated, remplacez `aud: https://gitlab.com` par l'URL de votre instance GitLab.
1. Configurez une [politique de cycle de vie S3](https://docs.aws.amazon.com/AmazonS3/latest/userguide/object-lifecycle-mgmt.html) pour faire expirer automatiquement les objets du cache.

   L'expiration doit être alignée avec la valeur `GITLAB_ADV_SAST_INCR_SCAN_SEARCH_PERIOD` (valeur par défaut : 3 jours) pour éviter de conserver des fichiers de cache obsolètes.

Le cache est stocké dans S3 à l'emplacement `<project-path>/<commit-sha>/ts-cache.sqlite.gz`. L'analyseur recherche dans les commits parents le cache le plus récent, correspondant au comportement de la mise en cache basée sur les artefacts.

### Signaler les vulnérabilités non vérifiées {#report-unverified-vulnerabilities}

{{< details >}}

- Statut : version bêta

{{< /details >}}

{{< history >}}

- [Introduit](https://gitlab.com/groups/gitlab-org/-/epics/15649) dans GitLab 18.11 en tant que [version bêta](../../../policy/development_stages_support.md#beta).

{{< /history >}}

GitLab Advanced SAST utilise l'analyse de taint pour tracer les flux de données des sources non fiables vers les points de sortie (sinks) vulnérables. Par défaut, l'analyseur ne signale une vulnérabilité que lorsqu'il peut tracer un chemin complet, ce qui privilégie la précision par rapport à la couverture. Pour détecter davantage de flux de données potentiels, vous pouvez activer les vulnérabilités non vérifiées. Cette fonctionnalité signale des résultats même lorsqu'un chemin de flux de données complet ne peut pas être établi, ce qui augmente la couverture mais peut également augmenter le nombre de faux positifs.

Lorsque vous activez le signalement des vulnérabilités non vérifiées, l'analyseur signale également les résultats pour lesquels un flux de taint partiel a été détecté mais n'a pas pu être entièrement vérifié de la source au point de sortie (sink). Ces résultats quasi-positifs vous aident à identifier et à corriger de manière proactive le code à risque avant qu'il ne devienne exploitable. Les résultats non vérifiés sont uniquement signalés pour les règles avec une gravité de sécurité Moyenne ou supérieure.

Les résultats non vérifiés se distinguent clairement des vulnérabilités entièrement vérifiées de la façon suivante :

- Dans l'onglet **Sécurité** du pipeline, la description de la vulnérabilité commence par le préfixe **(Unverified)**.
- Dans le **Rapport de vulnérabilités**, les résultats non vérifiés sont également préfixés de la même manière.
- Dans l'onglet **Flux de données**, les vulnérabilités non vérifiées n'ont pas de nœud source. Le premier nœud dans le flux est un **Point d'entrée de la trace**, indiquant où commence la trace partielle.

#### Activer le signalement des vulnérabilités non vérifiées {#turn-on-unverified-vulnerability-reporting}

Pour inclure les résultats non vérifiés dans les résultats d'analyse, définissez la variable CI/CD `REPORT_UNVERIFIED_VULNS` sur une valeur vraie dans votre fichier `.gitlab-ci.yml` :

```yaml
gitlab-advanced-sast:
  variables:
    REPORT_UNVERIFIED_VULNS: "true"
```

> [!warning]
> L'activation du signalement des vulnérabilités non vérifiées peut augmenter considérablement le nombre de résultats générés par l'analyseur. Ces résultats sont stockés dans la base de données de vulnérabilités et peuvent avoir un impact sur les workflows de gestion des vulnérabilités, notamment l'effort de triage et le reporting.

### Ajuster les ressources des runners {#tune-runner-resources}

Les ressources des runners ont un impact direct sur la durée d'analyse. GitLab Advanced SAST exécute les vérifications en parallèle par défaut, ce qui nécessite plusieurs cœurs de processeur et un minimum de 4 Go de mémoire par cœur. Les ressources des runners sont détectées automatiquement, mais vous pouvez ajuster certains paramètres si nécessaire.

L'analyseur détermine le processeur et la mémoire disponibles selon la priorité suivante :

1. Tags de runner GitLab SaaS (`CI_RUNNER_TAGS`) :
   - Sur les runners hébergés par GitLab, l'analyseur lit le tag du runner (par exemple, `saas-linux-large-amd64`) et recherche les valeurs connues de processeur et de mémoire pour ce type de runner.
1. Limites de ressources du conteneur (`/sys/fs/cgroup/cpu.max`, `/sys/fs/cgroup/memory.max`) :
   - Sur les runners auto-gérés, l'analyseur lit les limites de ressources du conteneur depuis les cgroups Linux. Seules les limites de ressources sont reflétées dans les cgroups. Les requêtes ne sont pas appliquées au niveau du conteneur et n'ont aucun effet.
1. Substitutions de variables CI/CD (`ADVANCED_SAST_AVAILABLE_CPUS`, `ADVANCED_SAST_AVAILABLE_MEMORY`) :
   - Si elles sont définies, ces valeurs remplacent ce qui a été détecté aux étapes 1 ou 2.

Si la détection échoue aux étapes 1 et 2, l'analyseur utilise par défaut 1 cœur et 4 Go de mémoire.

Pour confirmer l'allocation du processeur et de la mémoire, consultez le job log `gitlab-advanced-sast` et recherchez les entrées de GitLab Advanced SAST. Par exemple :

```plaintext
[INFO] [GitLab Advanced SAST] [2026-03-30T02:38:09Z] ▶ Detected 2 CPU Cores
[INFO] [GitLab Advanced SAST] [2026-03-30T02:38:09Z] ▶ No Memory limit is detected
```

#### Configurer les paramètres de ressources du runner {#configure-runner-resource-settings}

Vous pouvez ajuster manuellement les paramètres de processeur et de mémoire de l'analyseur en utilisant des variables CI/CD dans les cas suivants :

- Les limites de cgroup ne sont pas définies sur votre runner (par exemple, sur du bare-metal ou des machines virtuelles sans contraintes).
- Les valeurs détectées ne correspondent pas à la capacité réelle de votre runner.
- Vous souhaitez limiter les ressources utilisées par l'analyseur en dessous de ce qui est disponible.

Utilisez les paramètres CI/CD suivants pour ajuster les ressources du runner GitLab Advanced SAST :

- `ADVANCED_SAST_AVAILABLE_CPUS` - Spécifiez les cœurs de processeur disponibles pour l'analyseur
- `ADVANCED_SAST_AVAILABLE_MEMORY` - Spécifiez la mémoire totale disponible pour l'analyseur
- `MAX_UNVERIFIED_CORES` - Définissez une limite supérieure pour la détection automatique des cœurs
- `DISABLE_MULTI_CORE` - Désactivez entièrement l'analyse multi-cœur

Pour les runners auto-gérés, vous pouvez utiliser l'indicateur `--multi-core` dans la [configuration du scanner de sécurité](_index.md#security-scanner-configuration) pour spécifier le nombre de cœurs `requested`.

Pour en savoir plus, consultez la [configuration](#configuration).

Pour trouver la configuration optimale pour votre projet, modifiez un seul paramètre à la fois et surveillez la durée d'analyse.

Dans l'exemple suivant, 4 cœurs de processeur et 16 Go de mémoire sont disponibles pour l'analyseur GitLab Advanced SAST. Chacun des 4 workers dispose de 4 Go de mémoire.

```yaml
include:
  - template: Jobs/SAST.gitlab-ci.yml

variables:
  GITLAB_ADVANCED_SAST_ENABLED: 'true'
  ADVANCED_SAST_AVAILABLE_CPUS: '4'
  ADVANCED_SAST_AVAILABLE_MEMORY: '16384'  # 16 GB for 4 cores
```

## Configuration {#configuration}

Vous pouvez ajuster le comportement de GitLab Advanced SAST en utilisant les variables suivantes :

| Variable CI/CD                              | Valeur par défaut                | Description                                                                                                                                                                                     |
|---------------------------------------------|------------------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `GITLAB_ADVANCED_SAST_ENABLED`              | `false`                | Activer l'analyse GitLab Advanced SAST pour tous les langages pris en charge sauf C et C++. L'analyse de Swift et Objective-C s'exécute en tant que job `gitlab-advanced-sast-ext` distinct. |
| `GITLAB_ADVANCED_SAST_CPP_ENABLED`          | `false`                | Activer l'analyse GitLab Advanced SAST spécifiquement pour les projets C et C++.                                                                                                                       |
| `GITLAB_ADVANCED_SAST_EXT_INCREMENTAL_ENABLED` | `true` | Définissez sur `false` pour désactiver l'[analyse incrémentielle](advanced_sast_swift_objc.md#incremental-scanning) pour l'analyseur Swift et Objective-C (`gitlab-advanced-sast-ext`). |
| `ADVANCED_SAST_PARTIAL_SCAN`                | `false`                | Activer le mode d'analyse par diff de GitLab Advanced SAST en définissant sur `differential`.                                                                                                                    |
| `GITLAB_ADVANCED_SAST_RULE_TIMEOUT`         | `30`                   | Délai d'expiration en secondes par règle et par fichier. En cas de dépassement, cette analyse est ignorée.                                                                                                                  |
| `REPORT_UNVERIFIED_VULNS`                   | `false`                | Inclure les résultats non vérifiés dans les résultats d'analyse. Définissez sur `true`, `1` ou `True` pour activer.                                                                                                           |
| `GITLAB_ADV_SAST_INCR_SCAN`                 | `false`                | Activer l'[analyse incrémentielle](#incremental-scanning) pour mettre en cache les signatures de taint entre les exécutions de pipeline.                                                                                           |
| `GITLAB_ADV_SAST_INCR_SCAN_SEARCH_PERIOD`   | `3 days`               | Jusqu'où rechercher un artefact de signature de taint mis en cache. Format pris en charge : nombre suivi de `d`, `day` ou `days` (par exemple, `7 days`). Ne doit pas dépasser la période d'expiration de l'artefact. |
| `GITLAB_ADV_SAST_INCR_SCAN_CUSTOM_JOB_NAME` | `gitlab-advanced-sast` | Nom de job personnalisé pour la recherche d'artefacts de cache. Définissez cette valeur si vous avez renommé le job `gitlab-advanced-sast`.                                                                                              |
| `GITLAB_ADV_SAST_INCR_SCAN_STORAGE`         | Non défini                | Backend de stockage du cache. Définissez sur `s3` pour stocker le cache dans AWS S3 plutôt que dans les artefacts CI/CD. Pour en savoir plus, consultez [stocker le cache dans un stockage d'objets externe](#store-cache-in-external-object-storage).           |
| `GITLAB_ADV_SAST_INCR_SCAN_S3_BUCKET`       | Non défini                | Nom du bucket S3 pour le stockage du cache. Requis lorsque `GITLAB_ADV_SAST_INCR_SCAN_STORAGE` est `s3`.                                                                                                   |
| `GITLAB_ADV_SAST_INCR_SCAN_S3_REGION`       | Non défini                | Région AWS du bucket S3. Requis lorsque `GITLAB_ADV_SAST_INCR_SCAN_STORAGE` est `s3`.                                                                                                        |
| `GITLAB_ADV_SAST_INCR_SCAN_S3_ROLE_ARN`     | Non défini                | ARN du rôle IAM à assumer via OIDC. Requis lorsque `GITLAB_ADV_SAST_INCR_SCAN_STORAGE` est `s3`.                                                                                              |

L'analyse GitLab Advanced SAST est désactivée par défaut. Pour la désactiver explicitement lorsqu'elle est activée à un niveau supérieur (par exemple, pour un groupe), définissez `GITLAB_ADVANCED_SAST_ENABLED` (ou `GITLAB_ADVANCED_SAST_CPP_ENABLED` pour les projets C/C++) sur `false`.

## Déploiement {#roll-out}

Une fois que vous êtes satisfait des résultats de GitLab Advanced SAST pour un projet, étendez-le à des projets et groupes supplémentaires. Vous devez créer une configuration CI/CD partagée qui inclut GitLab Advanced SAST et l'appliquer aux groupes et projets souhaités.

Pour en savoir plus, consultez [la configuration de sécurité](../detect/security_configuration.md).

## Critères de détection des vulnérabilités {#vulnerability-detection-criteria}

GitLab Advanced SAST utilise une analyse inter-fichiers et inter-fonctions avec l'analyse de taint pour tracer le flux des entrées utilisateur dans le programme. Cela garantit que les vulnérabilités par injection, telles que l'injection SQL et le cross-site scripting (XSS), sont détectées même lorsqu'elles s'étendent sur plusieurs fonctions et fichiers.

L'analyseur ne signale les vulnérabilités basées sur le taint que lorsqu'il existe un flux vérifiable qui amène des entrées utilisateur non fiables depuis une source jusqu'à un point où des données non fiables pourraient provoquer des vulnérabilités de sécurité. Cette approche minimise le bruit par rapport à d'autres produits qui peuvent signaler des vulnérabilités avec moins de validation.

La détection met l'accent sur les entrées qui franchissent les frontières de confiance, comme les valeurs provenant de requêtes HTTP, mais exclut les arguments de ligne de commande, les variables d'environnement ou d'autres entrées généralement fournies par l'utilisateur qui exploite le programme.

Pour en savoir plus sur les types de vulnérabilités détectés par GitLab Advanced SAST, consultez [la couverture CWE de GitLab Advanced SAST](advanced_sast_coverage.md).

## Transition de Semgrep vers GitLab Advanced SAST {#transitioning-from-semgrep-to-gitlab-advanced-sast}

Lorsque vous migrez de Semgrep vers GitLab Advanced SAST, un processus de transition automatisé dédoublonne les vulnérabilités. Ce processus associe les vulnérabilités Semgrep précédemment détectées aux résultats correspondants de GitLab Advanced SAST, en les remplaçant lorsqu'une correspondance est trouvée.

Après avoir activé l'analyse Advanced SAST sur la branche par défaut, lorsqu'une analyse s'exécute et détecte des vulnérabilités, elle vérifie si l'une d'elles doit remplacer des vulnérabilités Semgrep existantes selon les conditions suivantes.

### Conditions de déduplication {#conditions-for-deduplication}

1. **Matching Identifier** :
   - Au moins l'un des identifiants de la vulnérabilité GitLab Advanced SAST (à l'exclusion de CWE et OWASP) doit correspondre à l'**primary identifier** d'une vulnérabilité Semgrep existante.
   - L'identifiant principal est le premier identifiant dans le tableau des identifiants de la vulnérabilité dans le [rapport SAST](_index.md#download-a-sast-report).
   - Par exemple, si une vulnérabilité GitLab Advanced SAST a des identifiants incluant `bandit.B506` et que l'identifiant principal d'une vulnérabilité Semgrep est également `bandit.B506`, cette condition est remplie.

1. **Matching Location** :
   - Les vulnérabilités doivent être associées au **same location** dans le code. Cela est déterminé à l'aide de l'un des champs suivants dans une vulnérabilité dans le [rapport SAST](_index.md#download-a-sast-report) :
     - Champ de suivi (si présent)
     - Champ d'emplacement (si le champ de suivi est absent)

### Modifications des vulnérabilités {#vulnerability-changes}

Lorsque les conditions sont remplies, la vulnérabilité Semgrep existante est convertie en vulnérabilité GitLab Advanced SAST. Cette vulnérabilité mise à jour apparaît dans le [rapport des vulnérabilités](../vulnerability_report/_index.md) avec les modifications suivantes :

- Le type de scanner passe de Semgrep à GitLab Advanced SAST.
- Tout identifiant supplémentaire présent dans la vulnérabilité GitLab Advanced SAST est ajouté à la vulnérabilité existante.
- Tous les autres détails de la vulnérabilité restent inchangés.

Lorsque les conditions ne sont pas remplies, les vulnérabilités Semgrep existantes persistent dans le tableau de bord des vulnérabilités, même si les problèmes de code sous-jacents ont été corrigés. Pour marquer ces vulnérabilités corrigées comme résolues dans GitLab, vous devez soit les résoudre manuellement dans le tableau de bord des vulnérabilités, soit exécuter à nouveau l'analyseur Semgrep.

### Résoudre les vulnérabilités en double {#resolve-duplicate-vulnerabilities}

Dans certains cas, les vulnérabilités Semgrep peuvent encore apparaître en double si les [conditions de déduplication](#conditions-for-deduplication) ne sont pas remplies. Pour résoudre ce problème dans le [Rapport de vulnérabilités](../vulnerability_report/_index.md) :

1. [Filtrez les vulnérabilités](../vulnerability_report/_index.md#filtering-vulnerabilities) par scanner Advanced SAST et [exportez les résultats au format CSV](../vulnerability_report/_index.md#export-details).
1. [Filtrez les vulnérabilités](../vulnerability_report/_index.md#filtering-vulnerabilities) par scanner Semgrep. Il s'agit probablement des vulnérabilités qui n'ont pas été dédoublonnées.
1. Pour chaque vulnérabilité Semgrep, vérifiez si elle a une correspondance dans les résultats Advanced SAST exportés.
1. Si un doublon existe, résolvez la vulnérabilité Semgrep de manière appropriée.

## Demander le code source des composants sous licence LGPL dans GitLab Advanced SAST {#request-source-code-of-lgpl-licensed-components-in-gitlab-advanced-sast}

Pour demander des informations sur le code source des composants sous licence LGPL dans GitLab Advanced SAST, [contactez le support GitLab](https://support.gitlab.com/).

Pour garantir une réponse rapide, incluez la version de l'analyseur GitLab Advanced SAST dans votre demande.

Cette fonctionnalité étant uniquement disponible dans l'édition Ultimate, vous devez être associé à une organisation bénéficiant de ce niveau de droit au support.
