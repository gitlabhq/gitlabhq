---
stage: Application Security Testing
group: Static Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Détection
description: Détection des vulnérabilités et évaluation des résultats.
---

Détectez les vulnérabilités dans le dépôt de votre projet et dans le comportement de votre application tout au long du cycle de vie du développement logiciel.

Pour vous aider à gérer le risque de vulnérabilités pendant le développement :

- Les scanners de sécurité s'exécutent lorsque vous envoyez des modifications de code vers une branche.
- Vous pouvez consulter les détails des vulnérabilités détectées dans la branche. Les équipes de développement peuvent remédier aux vulnérabilités à ce stade, en les corrigeant avant qu'elles n'atteignent la production.
- Vous pouvez également imposer une approbation supplémentaire sur les [merge requests contenant des vulnérabilités](../../project/merge_requests/widgets.md#application-security-scanning). Pour plus de détails, consultez les [politiques d'approbation des merge requests](../policies/merge_request_approval_policies.md).

Pour vous aider à gérer les vulnérabilités en dehors du développement :

- L'analyse de sécurité peut être planifiée ou exécutée manuellement.
- Les vulnérabilités détectées dans la branche par défaut apparaissent dans [le rapport de vulnérabilités](../vulnerability_report/_index.md). Utilisez ce rapport pour trier, analyser et remédier aux vulnérabilités.

## Analyse de sécurité {#security-scanning}

Pour tirer le meilleur parti de l'analyse de sécurité, il est important de comprendre :

- Comment déclencher l'analyse de sécurité.
- Quels aspects de votre application ou de votre dépôt sont analysés.
- Ce qui détermine quels scanners s'exécutent.
- Comment l'analyse de sécurité se déroule.

### Déclencheurs {#triggers}

L'analyse de sécurité dans un pipeline CI/CD est déclenchée par défaut lorsque des modifications sont envoyées vers le dépôt d'un projet.

Vous pouvez également exécuter l'analyse de sécurité en :

- [Exécutant un pipeline CI/CD manuellement](../../../ci/pipelines/_index.md#run-a-pipeline-manually).
- Planifiant l'analyse de sécurité à l'aide d'une [politique d'exécution de scan](../policies/scan_execution_policies.md).
- Pour DAST uniquement, en exécutant [un scan DAST à la demande manuellement](../dast/on-demand_scan.md) ou [selon un calendrier](../../../ci/pipelines/schedules.md).
- Pour SAST uniquement, en exécutant un scan à l'aide de l'[extension GitLab pour VS Code](../../../editor_extensions/visual_studio_code/security_scanning.md#perform-sast-scanning).

### Couverture de détection {#detection-coverage}

Analysez le dépôt de votre projet et testez le comportement de votre application pour détecter des vulnérabilités :

- L'analyse du dépôt peut détecter des vulnérabilités dans le dépôt de votre projet. La couverture inclut le code source de votre application, ainsi que les bibliothèques et les images de conteneurs dont elle dépend.
- Les tests comportementaux de votre application et de son API peuvent détecter des vulnérabilités qui n'apparaissent qu'à l'exécution.

#### Analyse du dépôt {#repository-scanning}

Le dépôt de votre projet peut contenir du code source, des déclarations de dépendances et des définitions d'infrastructure. L'analyse du dépôt peut détecter des vulnérabilités dans chacun de ces éléments.

Les outils d'analyse du dépôt incluent :

- Test statique de sécurité des applications (SAST) : analysez le code source à la recherche de vulnérabilités.
- Analyse Infrastructure as Code (IaC) : détectez les vulnérabilités dans les définitions d'infrastructure de votre application.
- Détection des secrets : détectez et bloquez les secrets avant qu'ils ne soient commités dans le dépôt.
- Analyse des dépendances : détectez les vulnérabilités dans les dépendances de votre application et les images de conteneurs.

#### Tests comportementaux {#behavioral-testing}

Les tests comportementaux nécessitent une application déployable pour tester les vulnérabilités connues et les comportements inattendus.

Les outils de tests comportementaux incluent :

- Test dynamique de sécurité des applications (DAST) : testez votre application contre les vecteurs d'attaque connus.
- Test de sécurité des API : testez l'API de votre application contre les attaques connues et les vulnérabilités liées aux entrées.
- Test de fuzzing guidé par la couverture : testez votre application contre les comportements inattendus.

### Sélection des scanners {#scanner-selection}

Les scanners de sécurité sont activés pour un projet de l'une des manières suivantes :

- En ajoutant le modèle CI/CD du scanner au fichier `.gitlab-ci.yml`, directement ou en utilisant [AutoDevOps](../../../topics/autodevops/_index.md).
- En imposant le scanner à l'aide d'une politique d'exécution de scan, d'une politique d'exécution de pipeline ou d'un [cadre de conformité](../../compliance/compliance_frameworks/_index.md). Cette application peut être appliquée directement au projet ou héritée du groupe parent du projet.

Pour en savoir plus, consultez [la configuration de sécurité](security_configuration.md).

### Processus d'analyse de sécurité {#security-scanning-process}

Le processus d'analyse de sécurité est le suivant :

1. En fonction des critères des jobs CI/CD, les scanners activés et destinés à s'exécuter dans un pipeline s'exécutent en tant que jobs distincts.

   Chaque job réussi génère un ou plusieurs rapports de sécurité en tant qu'artefacts de job. Ces rapports contiennent les détails de toutes les vulnérabilités détectées dans la branche, qu'elles aient été précédemment trouvées, ignorées ou nouvelles.
1. Chaque rapport de sécurité est traité, notamment la [validation](security_report_validation.md) et la [déduplication](vulnerability_deduplication.md).
1. Lorsque tous les jobs sont terminés, y compris les jobs manuels, vous pouvez télécharger ou consulter les résultats.

Pour plus de détails sur les résultats de l'analyse de sécurité, consultez [Résultats de l'analyse de sécurité](security_scanning_results.md).

#### Critères des jobs de sécurité CI/CD {#cicd-security-job-criteria}

Les jobs d'analyse de sécurité dans un pipeline CI/CD sont déterminés par les critères suivants :

1. Inclusion des modèles d'analyse de sécurité

   La sélection des jobs d'analyse de sécurité est d'abord déterminée par les modèles inclus ou imposés par une politique ou un cadre de conformité.

   L'analyse de sécurité s'exécute par défaut dans les pipelines de branche. Pour exécuter l'analyse de sécurité dans les pipelines de merge request, vous devez spécifiquement [l'activer](security_configuration.md#use-security-scanning-tools-with-merge-request-pipelines).
1. Évaluation des règles

   Chaque modèle comporte des [règles](../../../ci/yaml/_index.md#rules) définies qui déterminent si l'analyseur est exécuté.

   Par exemple, certains analyseurs s'exécutent uniquement si des fichiers d'un type spécifique sont détectés dans le dépôt.
1. Logique de l'analyseur

   Si les règles du modèle imposent l'exécution du job, un job est créé dans l'étape de pipeline spécifiée dans le modèle. Cependant, chaque analyseur possède sa propre logique qui détermine si l'analyseur lui-même doit être exécuté.

   Par exemple, si l'analyse des dépendances ne détecte pas de fichiers pris en charge à la profondeur par défaut, l'analyseur n'est pas exécuté et aucun artefact n'est généré.

Les jobs réussissent s'ils effectuent un scan, même s'ils ne trouvent pas de vulnérabilités. La seule exception est le fuzzing de couverture, qui échoue s'il identifie des résultats. Tous les jobs sont autorisés à échouer afin qu'ils ne fassent pas échouer l'ensemble du pipeline. Ne modifiez pas le paramètre [`allow_failure` du job](../../../ci/yaml/_index.md#allow_failure), car cela fait échouer l'ensemble du pipeline.

## Confidentialité des données {#data-privacy}

GitLab traite le code source et effectue l'analyse localement sur le GitLab Runner. Aucune donnée n'est transmise en dehors de l'infrastructure GitLab (serveur et runners).

Les analyseurs de sécurité accèdent à Internet uniquement pour télécharger les derniers ensembles de signatures, de règles et de correctifs. Si vous préférez que les scanners n'accèdent pas à Internet, envisagez d'utiliser un [environnement hors ligne](../offline_deployments/_index.md).
