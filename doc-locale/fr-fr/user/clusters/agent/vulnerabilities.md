---
stage: Application Security Testing
group: Composition analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Analyse les images de conteneurs dans un cluster Kubernetes à la recherche de vulnérabilités.
title: Analyse opérationnelle de conteneurs
---

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

## Architectures prises en charge {#supported-architectures}

L'analyse opérationnelle des conteneurs (OCS) est prise en charge pour `linux/arm64` et `linux/amd64`.

## Activer l'analyse opérationnelle des conteneurs {#enable-operational-container-scanning}

Vous pouvez utiliser OCS pour analyser les images de conteneurs de votre cluster à la recherche de vulnérabilités de sécurité. OCS utilise une [image wrapper](https://gitlab.com/gitlab-org/security-products/analyzers/trivy-k8s-wrapper) autour de [Trivy](https://github.com/aquasecurity/trivy) pour analyser les images à la recherche de vulnérabilités.

OCS peut être configuré pour s'exécuter selon une cadence à l'aide de `agent config` ou d'une politique d'exécution de scan du projet.

> [!note]
> Si `agent config` et `scan execution policies` sont tous deux configurés, la configuration de `scan execution policy` est prioritaire.

### Activer via la configuration de l'agent {#enable-via-agent-configuration}

Pour activer l'analyse des images dans votre cluster Kubernetes via la configuration de l'agent, ajoutez un bloc de configuration `container_scanning` à votre configuration d'agent avec un champ `cadence` contenant une [expression CRON](https://en.wikipedia.org/wiki/Cron) indiquant quand les analyses sont exécutées.

```yaml
container_scanning:
  cadence: '0 0 * * *' # Daily at 00:00 (Kubernetes cluster time)
```

Le champ `cadence` est obligatoire. GitLab prend en charge les types de syntaxe CRON suivants pour le champ cadence :

- Une cadence quotidienne d'une fois par heure à une heure spécifiée, par exemple : `0 18 * * *`
- Une cadence hebdomadaire d'une fois par semaine à un jour et à une heure spécifiés, par exemple : `0 13 * * 0`

> [!note]
> D'autres éléments de la [syntaxe CRON](https://docs.oracle.com/cd/E12058_01/doc/doc.1014/e12030/cron_expressions.htm) peuvent fonctionner dans le champ cadence s'ils sont pris en charge par le [cron](https://github.com/robfig/cron) utilisé dans votre implémentation. Cependant, GitLab ne les teste ni ne les prend en charge officiellement.
>
> L'expression CRON est évaluée en [UTC](https://www.timeanddate.com/worldclock/timezone/utc) en utilisant l'heure système du pod de l'agent Kubernetes.

Par défaut, l'analyse opérationnelle des conteneurs n'analyse aucune charge de travail à la recherche de vulnérabilités. Vous pouvez définir le bloc `vulnerability_report` avec le champ `namespaces` qui permet de sélectionner les espaces de nommage à analyser. Par exemple, si vous souhaitez analyser uniquement les espaces de nommage `default`, `kube-system`, vous pouvez utiliser cette configuration :

```yaml
container_scanning:
  cadence: '0 0 * * *'
  vulnerability_report:
    namespaces:
      - default
      - kube-system
```

Pour chaque espace de nommage cible, toutes les images des ressources de charge de travail suivantes sont analysées par défaut :

- Pod
- ReplicaSet
- ReplicationController
- StatefulSet
- DaemonSet
- CronJob
- Job

Cela peut être personnalisé en [configurant la détection des ressources Kubernetes Trivy](#configure-trivy-kubernetes-resource-detection).

### Activer via les politiques d'exécution de scan {#enable-via-scan-execution-policies}

Pour activer l'analyse des images dans votre cluster Kubernetes à l'aide des politiques d'exécution de scan, utilisez l'[éditeur de politique d'exécution de scan](../../application_security/policies/scan_execution_policies.md#scan-execution-policy-editor) pour créer une nouvelle règle de planification.

> [!note]
> L'agent Kubernetes doit être en cours d'exécution dans votre cluster pour analyser les images de conteneurs en cours d'exécution.

L'analyse opérationnelle des conteneurs fonctionne indépendamment des pipelines GitLab. Elle est entièrement automatisée et gérée par l'agent Kubernetes, qui lance de nouvelles analyses à l'heure planifiée configurée dans la politique d'exécution de scan. L'agent crée un job dédié dans votre cluster pour effectuer l'analyse et transmettre les résultats à GitLab.

Voici un exemple de politique qui active l'analyse opérationnelle des conteneurs dans le cluster auquel l'agent Kubernetes est rattaché :

```yaml
- name: Enforce container scanning in cluster connected through my-gitlab-agent for default and kube-system namespaces
  enabled: true
  rules:
  - type: schedule
    cadence: '0 10 * * *'
    agents:
      <agent-name>:
        namespaces:
        - 'default'
        - 'kube-system'
  actions:
  - scan: container_scanning
```

Les clés d'une règle de planification sont :

- `cadence` (obligatoire) : une [expression CRON](https://docs.oracle.com/cd/E12058_01/doc/doc.1014/e12030/cron_expressions.htm) indiquant quand les analyses sont exécutées
- `agents:<agent-name>` (obligatoire) : le nom de l'agent à utiliser pour l'analyse
- `agents:<agent-name>:namespaces` (obligatoire) : Les espaces de nommage Kubernetes à scanner.

> [!note]
> D'autres éléments de la [syntaxe CRON](https://docs.oracle.com/cd/E12058_01/doc/doc.1014/e12030/cron_expressions.htm) peuvent fonctionner dans le champ cadence s'ils sont pris en charge par le [cron](https://github.com/robfig/cron) utilisé dans votre implémentation. Cependant, GitLab ne les teste ni ne les prend en charge officiellement.
>
> L'expression CRON est évaluée en [UTC](https://www.timeanddate.com/worldclock/timezone/utc) en utilisant l'heure système du pod de l'agent Kubernetes.

Vous pouvez consulter le schéma complet dans la [documentation sur les politiques d'exécution de scan](../../application_security/policies/scan_execution_policies.md#scan-execution-policies-schema).

## Résolution des vulnérabilités OCS pour une configuration multi-cluster {#ocs-vulnerability-resolution-for-multi-cluster-configuration}

Pour garantir un suivi précis des vulnérabilités avec OCS, vous devez créer un projet GitLab distinct avec OCS activé pour chaque cluster. Si vous disposez de plusieurs clusters, assurez-vous d'utiliser un projet par cluster.

OCS résout les vulnérabilités qui ne sont plus détectées dans votre cluster après chaque analyse en comparant les vulnérabilités de l'analyse en cours avec celles précédemment détectées. Toutes les vulnérabilités des analyses précédentes qui ne sont plus présentes dans l'analyse en cours sont résolues pour le projet GitLab.

Si plusieurs clusters sont configurés dans le même projet, une analyse OCS dans un cluster (par exemple, le projet A) résoudrait les vulnérabilités précédemment détectées dans un autre cluster (par exemple, le projet B), entraînant un rapport de vulnérabilités incorrect.

## Configurer les exigences en ressources du scanner {#configure-scanner-resource-requirements}

Par défaut, les exigences en ressources du pod du scanner sont :

```yaml
requests:
  cpu: 100m
  memory: 100Mi
  ephemeral_storage: 1Gi
limits:
  cpu: 500m
  memory: 500Mi
  ephemeral_storage: 3Gi
```

Vous pouvez le personnaliser avec un champ `resource_requirements`.

```yaml
container_scanning:
  resource_requirements:
    requests:
      cpu: '0.2'
      memory: 200Mi
      ephemeral_storage: 2Gi
    limits:
      cpu: '0.7'
      memory: 700Mi
      ephemeral_storage: 4Gi
```

Lorsque vous utilisez une valeur fractionnelle pour le CPU, formatez la valeur sous forme de chaîne de caractères.

> [!note]
>
> - Les exigences en ressources doivent être définies à l'aide du fichier de configuration de l'agent, même lorsque l'analyse opérationnelle des conteneurs est activée via des politiques d'exécution de scan.
> - Lorsque vous utilisez Google Kubernetes Engine (GKE) pour l'orchestration Kubernetes, [les limites de stockage éphémère sont automatiquement définies pour être égales aux demandes](https://cloud.google.com/kubernetes-engine/docs/concepts/autopilot-resource-requests#resource-limits).

## Dépôt personnalisé pour Trivy K8s Wrapper {#custom-repository-for-trivy-k8s-wrapper}

Lors d'une analyse, OCS déploie des pods à l'aide d'une image provenant du [dépôt Trivy K8s Wrapper](https://gitlab.com/security-products/trivy-k8s-wrapper/container_registry/5992609), qui transmet le rapport de vulnérabilités généré par [Trivy Kubernetes](https://aquasecurity.github.io/trivy/v0.54/docs/target/kubernetes) à OCS.

Si le pare-feu de votre cluster restreint l'accès au dépôt Trivy K8s Wrapper, vous pouvez configurer OCS pour extraire l'image depuis un dépôt personnalisé. Assurez-vous que le dépôt personnalisé reflète le dépôt Trivy K8s Wrapper pour garantir la compatibilité.

```yaml
container_scanning:
  trivy_k8s_wrapper_image:
    repository: "your-custom-registry/your-image-path"
```

## Configurer le délai d'expiration de l'analyse {#configure-scan-timeout}

{{< history >}}

- [Introduction](https://gitlab.com/gitlab-org/gitlab/-/issues/497460) dans GitLab 17.7.

{{< /history >}}

Par défaut, l'analyse Trivy expire après cinq minutes. L'agent lui-même dispose de 15 minutes supplémentaires pour lire les configmaps chaînées et transmettre les vulnérabilités.

Pour personnaliser la durée du délai d'expiration de Trivy :

- Spécifiez la durée en secondes avec le champ `scanner_timeout`.

Par exemple :

```yaml
container_scanning:
  scanner_timeout: "3600s" # 60 minutes
```

## Configurer la taille du rapport Trivy {#configure-trivy-report-size}

{{< history >}}

- [Introduction](https://gitlab.com/gitlab-org/gitlab/-/issues/497460) dans GitLab 17.7.

{{< /history >}}

Par défaut, le rapport Trivy est limité à 100 Mo, ce qui est suffisant pour la plupart des analyses. Cependant, si vous avez de nombreuses charges de travail, il se peut que vous deviez augmenter la limite.

Pour cela :

- Spécifiez la limite en octets avec le champ `report_max_size`.

Par exemple :

```yaml
container_scanning:
  report_max_size: "300000000" # 300 MB
```

## Configurer la détection des ressources Kubernetes Trivy {#configure-trivy-kubernetes-resource-detection}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/431707) dans GitLab 17.9.

{{< /history >}}

Par défaut, Trivy recherche les types de ressources Kubernetes suivants pour découvrir les images analysables :

- Pod
- ReplicaSet
- ReplicationController
- StatefulSet
- DaemonSet
- CronJob
- Job
- Deployment

Vous pouvez limiter les types de ressources Kubernetes que Trivy découvre, par exemple pour n'analyser que les images « actives ».

Pour cela :

- Spécifiez les types de ressources avec le champ `resource_types` :

  ```yaml
  container_scanning:
    vulnerability_report:
      resource_types:
        - Deployment
        - Pod
        - Job
  ```

## Configurer la suppression des artefacts de rapport Trivy {#configure-trivy-report-artifact-deletion}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/480845) dans GitLab 17.9.

{{< /history >}}

Par défaut, l'agent GitLab pour Kubernetes supprime l'artefact de rapport Trivy une fois l'analyse terminée.

Vous pouvez configurer l'agent pour conserver l'artefact de rapport, afin de pouvoir consulter le rapport dans son état brut.

Pour cela :

- Définissez `delete_report_artifact` sur `false` :

  ```yaml
  container_scanning:
    delete_report_artifact: false
  ```

## Configurer le filtre de seuil de gravité Trivy {#configure-trivy-severity-threshold-filter}

{{< history >}}

- [Introduction](https://gitlab.com/gitlab-org/gitlab/-/issues/559278) dans GitLab 18.4.

{{< /history >}}

OCS analyse les vulnérabilités pour tous les niveaux de [gravité](../../application_security/vulnerabilities/severities.md) par défaut.

Pour ne signaler que les vulnérabilités égales ou supérieures à un niveau de gravité spécifique, définissez la variable de configuration `severity_threshold` sur cette valeur. Une fois le seuil de gravité défini, les vulnérabilités dont la gravité est inférieure au niveau choisi ne sont plus renvoyées dans le rapport de vulnérabilités, les charges utiles d'API et les autres mécanismes de rapport.

Cela vous permet de vous concentrer sur les vulnérabilités qui correspondent aux besoins de tolérance au risque de votre organisation.

Les valeurs de seuil prises en charge sont `UNKNOWN`, `LOW`, `MEDIUM`, `HIGH` et `CRITICAL`.

Par exemple, pour signaler les vulnérabilités de gravité élevée et critique :

```yaml
container_scanning:
  severity_threshold: "HIGH"
```

## Afficher les vulnérabilités du cluster {#view-cluster-vulnerabilities}

Pour afficher les informations sur les vulnérabilités dans GitLab :

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à** et trouvez le projet contenant le fichier de configuration de l'agent.
1. Sélectionnez **Opération** > **Clusters Kubernetes**.
1. Sélectionnez l'onglet **Agent**.
1. Sélectionnez un agent pour afficher les vulnérabilités du cluster.

![Interface utilisateur de l'onglet de sécurité de l'agent de cluster](img/cluster_agent_security_tab_v14_8.png)

Ces informations sont également disponibles sous [vulnérabilités opérationnelles](../../application_security/vulnerability_report/_index.md#operational-vulnerabilities).

> [!note]
> Vous devez disposer du rôle Développeur, Mainteneur ou Propriétaire.

## Analyse des images privées {#scanning-private-images}

Pour analyser des images privées, le scanner s'appuie sur les secrets d'extraction d'images (références directes et depuis le compte de service) pour extraire l'image.

## Problèmes connus {#known-issues}

Dans l'agent GitLab pour Kubernetes 16.9 et versions ultérieures, l'analyse opérationnelle des conteneurs :

- Gère les rapports Trivy jusqu'à 100 Mo. Pour les releases précédentes, cette limite est de 10 Mo.
- Est désactivée lorsque l'agent GitLab pour Kubernetes s'exécute en mode `fips`.

## Dépannage {#troubleshooting}

### `Error running Trivy scan. Container terminated reason: OOMKilled` {#error-running-trivy-scan-container-terminated-reason-oomkilled}

OCS peut échouer avec une erreur OOM s'il y a trop de ressources à analyser ou si les images analysées sont volumineuses.

Pour résoudre ce problème, [configurez les exigences en ressources](#configure-scanner-resource-requirements) pour augmenter la quantité de mémoire disponible.

### `Pod ephemeral local storage usage exceeds the total limit of containers` {#pod-ephemeral-local-storage-usage-exceeds-the-total-limit-of-containers}

Les analyses OCS peuvent échouer pour les clusters Kubernetes dont le stockage éphémère par défaut est faible. Par exemple, [GKE autopilot](https://cloud.google.com/kubernetes-engine/docs/concepts/autopilot-resource-requests#defaults) définit le stockage éphémère par défaut à 1 Go. Cela pose un problème pour OCS lors de l'analyse d'espaces de nommage avec des images volumineuses, car il se peut qu'il n'y ait pas assez d'espace pour stocker toutes les données nécessaires à OCS.

Pour résoudre ce problème, [configurez les exigences en ressources](#configure-scanner-resource-requirements) pour augmenter la quantité de stockage éphémère disponible.

Un autre message indiquant ce problème peut être : `OCS Scanning pod evicted due to low resources. Please configure higher resource limits.`

### `Error running Trivy scan due to context timeout` {#error-running-trivy-scan-due-to-context-timeout}

OCS peut ne pas parvenir à terminer une analyse si Trivy met trop de temps à la compléter. Le délai d'expiration d'analyse par défaut est de 5 minutes, avec 15 minutes supplémentaires pour que l'agent lise les résultats et transmette les vulnérabilités.

Pour résoudre ce problème, [configurez le délai d'expiration du scanner](#configure-scan-timeout) pour augmenter la quantité de mémoire disponible.

### `trivy report size limit exceeded` {#trivy-report-size-limit-exceeded}

OCS peut échouer avec cette erreur si la taille du rapport Trivy généré est supérieure à la limite maximale par défaut.

Pour résoudre ce problème, [configurez la taille maximale du rapport Trivy](#configure-trivy-report-size) pour augmenter la taille maximale autorisée du rapport Trivy.
