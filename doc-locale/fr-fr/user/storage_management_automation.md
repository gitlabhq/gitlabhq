---
stage: Fulfillment
group: Utilization
info: This page is maintained by Developer Relations, author @dnsmichi, see <https://handbook.gitlab.com/handbook/marketing/developer-relations/developer-advocacy/content/#maintained-documentation>
title: Automatiser la gestion du stockage
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Cette page décrit comment automatiser l'analyse et le nettoyage du stockage pour gérer votre utilisation du stockage avec l'API REST GitLab.

Vous pouvez également gérer votre utilisation du stockage en améliorant [l'efficacité des pipelines](../ci/pipelines/pipeline_efficiency.md).

Pour obtenir de l'aide supplémentaire sur l'automatisation de l'API, vous pouvez également utiliser le [forum communautaire GitLab et Discord](https://about.gitlab.com/community/).

> [!warning]
> Les exemples de scripts de cette page sont fournis à des fins de démonstration uniquement et ne doivent pas être utilisés en production. Vous pouvez utiliser ces exemples pour concevoir et tester vos propres scripts d'automatisation du stockage.

## Exigences de l'API {#api-requirements}

Pour automatiser la gestion du stockage, votre instance GitLab.com ou GitLab Self-Managed doit avoir accès à l'[API REST GitLab](../api/api_resources.md).

### Portée de l'authentification de l'API {#api-authentication-scope}

Utilisez les portées suivantes pour vous [authentifier](../api/rest/authentication.md) auprès de l'API :

- Analyse du stockage :
  - Accès en lecture à l'API avec la portée `read_api`.
  - Le rôle Développeur, Mainteneur ou Propriétaire sur tous les projets.
- Nettoyage du stockage :
  - Accès complet à l'API avec la portée `api`.
  - Le rôle Mainteneur ou Propriétaire sur tous les projets.

Vous pouvez utiliser des outils en ligne de commande ou un langage de programmation pour interagir avec l'API REST.

### Outils en ligne de commande {#command-line-tools}

Pour envoyer des requêtes API, installez l'un ou l'autre :

- curl avec votre gestionnaire de paquets préféré.
- [GitLab CLI](https://docs.gitlab.com/cli/) et utilisez la sous-commande `glab api`.

Pour formater les réponses JSON, installez `jq`. Pour plus d'informations, consultez [Conseils pour des workflows DevOps productifs : formatage JSON avec jq et automatisation du linting CI/CD](https://about.gitlab.com/blog/devops-workflows-json-format-jq-ci-cd-lint/).

Pour utiliser ces outils avec l'API REST :

{{< tabs >}}

{{< tab title="curl" >}}

```shell
export GITLAB_TOKEN=xxx

curl --silent --header "Authorization: Bearer $GITLAB_TOKEN" "https://gitlab.com/api/v4/user" | jq
```

{{< /tab >}}

{{< tab title="GitLab CLI" >}}

```shell
glab auth login

glab api groups/YOURGROUPNAME/projects
```

{{< /tab >}}

{{< /tabs >}}

#### Utilisation de GitLab CLI {#using-the-gitlab-cli}

Certains endpoints de l'API nécessitent une [pagination](../api/rest/_index.md#pagination) et des récupérations de pages successives pour obtenir tous les résultats. GitLab CLI fournit l'indicateur `--paginate`.

Les requêtes nécessitant un corps POST formaté en données JSON peuvent être écrites sous forme de paires `key=value` transmises au paramètre `--raw-field`.

Pour plus d'informations, consultez la [documentation des endpoints GitLab CLI](https://docs.gitlab.com/cli/#commands).

### Bibliothèques clientes de l'API {#api-client-libraries}

Les méthodes de gestion du stockage et d'automatisation du nettoyage décrites sur cette page utilisent :

- La bibliothèque [`python-gitlab`](https://python-gitlab.readthedocs.io/en/stable/), qui offre une interface de programmation riche en fonctionnalités.
- Le script `get_all_projects_top_level_namespace_storage_analysis_cleanup_example.py` dans le projet [GitLab API with Python](https://gitlab.com/gitlab-da/use-cases/gitlab-api/gitlab-api-python/).

Pour plus d'informations sur les cas d'utilisation de la bibliothèque `python-gitlab`, consultez [Workflows DevSecOps efficaces : automatisation pratique de l'API `python-gitlab`](https://about.gitlab.com/blog/efficient-devsecops-workflows-hands-on-python-gitlab-api-automation/).

Pour plus d'informations sur les autres bibliothèques clientes de l'API, consultez [Clients tiers](../api/rest/third_party_clients.md).

> [!note]
> Utilisez GitLab Duo Code Suggestions pour écrire du code plus efficacement.

## Analyse du stockage {#storage-analysis}

### Identifier les types de stockage {#identify-storage-types}

L'[endpoint de l'API projects](../api/projects.md#list-all-projects) fournit des statistiques pour les projets de votre instance GitLab. Pour utiliser l'endpoint de l'API projects, définissez la clé `statistics` sur le booléen `true`. Ces données fournissent des informations sur la consommation de stockage du projet selon les types de stockage suivants :

- `storage_size` : stockage global
- `lfs_objects_size` : stockage des objets LFS
- `job_artifacts_size` : stockage des artefacts de job
- `packages_size` : stockage des paquets
- `repository_size` : stockage du dépôt Git
- `snippets_size` : stockage des snippets
- `uploads_size` : stockage des uploads
- `wiki_size` : stockage du wiki

Pour identifier les types de stockage :

{{< tabs >}}

{{< tab title="curl" >}}

```shell
curl --silent --header "Authorization: Bearer $GITLAB_TOKEN" "https://gitlab.com/api/v4/projects/$GL_PROJECT_ID?statistics=true" | jq --compact-output '.id,.statistics' | jq
48349590
{
  "commit_count": 2,
  "storage_size": 90241770,
  "repository_size": 3521,
  "wiki_size": 0,
  "lfs_objects_size": 0,
  "job_artifacts_size": 90238249,
  "pipeline_artifacts_size": 0,
  "packages_size": 0,
  "snippets_size": 0,
  "uploads_size": 0
}
```

{{< /tab >}}

{{< tab title="GitLab CLI" >}}

```shell
export GL_PROJECT_ID=48349590
glab api --method GET projects/$GL_PROJECT_ID --field 'statistics=true' | jq --compact-output '.id,.statistics' | jq
48349590
{
  "commit_count": 2,
  "storage_size": 90241770,
  "repository_size": 3521,
  "wiki_size": 0,
  "lfs_objects_size": 0,
  "job_artifacts_size": 90238249,
  "pipeline_artifacts_size": 0,
  "packages_size": 0,
  "snippets_size": 0,
  "uploads_size": 0
}
```

{{< /tab >}}

{{< tab title="Python" >}}

```python
project_obj = gl.projects.get(project.id, statistics=True)

print("Project {n} statistics: {s}".format(n=project_obj.name_with_namespace, s=json.dump(project_obj.statistics, indent=4)))
```

{{< /tab >}}

{{< /tabs >}}

Pour afficher les statistiques du projet dans le terminal, exportez la variable d'environnement `GL_GROUP_ID` et exécutez le script :

```shell
export GL_TOKEN=xxx
export GL_GROUP_ID=56595735

pip3 install python-gitlab
python3 get_all_projects_top_level_namespace_storage_analysis_cleanup_example.py

Project Developer Evangelism and Technical Marketing at GitLab  / playground / Artifact generator group / Gen Job Artifacts 4 statistics: {
    "commit_count": 2,
    "storage_size": 90241770,
    "repository_size": 3521,
    "wiki_size": 0,
    "lfs_objects_size": 0,
    "job_artifacts_size": 90238249,
    "pipeline_artifacts_size": 0,
    "packages_size": 0,
    "snippets_size": 0,
    "uploads_size": 0
}
```

### Analyser le stockage dans les projets et les groupes {#analyze-storage-in-projects-and-groups}

Vous pouvez automatiser l'analyse de plusieurs projets et groupes. Par exemple, vous pouvez commencer au niveau de l'espace de nommage principal et analyser de manière récursive tous les sous-groupes et projets. Vous pouvez également analyser différents types de stockage.

Voici un exemple d'algorithme pour analyser plusieurs sous-groupes et projets :

1. Récupérez l'ID de l'espace de nommage de niveau supérieur. Vous pouvez copier la valeur de l'ID depuis la [vue d'ensemble de l'espace de nommage/groupe](namespace/_index.md#types-of-namespaces).
1. Récupérez tous les [sous-groupes](../api/groups.md#list-subgroups) du groupe principal et enregistrez les ID dans une liste.
1. Parcourez tous les groupes et récupérez tous les [projets de chaque groupe](../api/groups.md#list-projects), puis enregistrez les ID dans une liste.
1. Identifiez le type de stockage à analyser et collectez les informations à partir des attributs du projet, comme les statistiques du projet et les artefacts de job.
1. Affichez une vue d'ensemble de tous les projets, regroupés par groupe, ainsi que leurs informations de stockage.

L'approche shell avec `glab` peut être plus adaptée aux analyses de petite taille. Pour les analyses plus importantes, vous devriez utiliser un script qui utilise les bibliothèques clientes de l'API. Ce type de script peut améliorer la lisibilité, le stockage des données, le contrôle de flux, les tests et la réutilisabilité.

Pour s'assurer que le script n'atteint pas les [limites de débit de l'API](../rate_limits/_index.md), l'exemple de code suivant n'est pas optimisé pour les requêtes API parallèles.

Pour implémenter cet algorithme :

{{< tabs >}}

{{< tab title="GitLab CLI" >}}

```shell
export GROUP_NAME="gitlab-da"

# Return subgroup IDs
glab api groups/$GROUP_NAME/subgroups | jq --compact-output '.[]' | jq --compact-output '.id'
12034712
67218622
67162711
67640130
16058698
12034604

# Loop over all subgroups to get subgroups, until the result set is empty. Example group: 12034712
glab api groups/12034712/subgroups | jq --compact-output '.[]' | jq --compact-output '.id'
56595735
70677315
67218606
70812167

# Lowest group level
glab api groups/56595735/subgroups | jq --compact-output '.[]' | jq --compact-output '.id'
# empty result, return and continue with analysis

# Fetch projects from all collected groups. Example group: 56595735
glab api groups/56595735/projects | jq --compact-output '.[]' | jq --compact-output '.id'
48349590
48349263
38520467
38520405

# Fetch storage types from a project (ID 48349590): Job artifacts in the `artifacts` key
glab api projects/48349590/jobs | jq --compact-output '.[]' | jq --compact-output '.id, .artifacts'
4828297946
[{"file_type":"archive","size":52444993,"filename":"artifacts.zip","file_format":"zip"},{"file_type":"metadata","size":156,"filename":"metadata.gz","file_format":"gzip"},{"file_type":"trace","size":3140,"filename":"job.log","file_format":null}]
4828297945
[{"file_type":"archive","size":20978113,"filename":"artifacts.zip","file_format":"zip"},{"file_type":"metadata","size":157,"filename":"metadata.gz","file_format":"gzip"},{"file_type":"trace","size":3147,"filename":"job.log","file_format":null}]
4828297944
[{"file_type":"archive","size":10489153,"filename":"artifacts.zip","file_format":"zip"},{"file_type":"metadata","size":158,"filename":"metadata.gz","file_format":"gzip"},{"file_type":"trace","size":3146,"filename":"job.log","file_format":null}]
4828297943
[{"file_type":"archive","size":5244673,"filename":"artifacts.zip","file_format":"zip"},{"file_type":"metadata","size":157,"filename":"metadata.gz","file_format":"gzip"},{"file_type":"trace","size":3145,"filename":"job.log","file_format":null}]
4828297940
[{"file_type":"archive","size":1049089,"filename":"artifacts.zip","file_format":"zip"},{"file_type":"metadata","size":157,"filename":"metadata.gz","file_format":"gzip"},{"file_type":"trace","size":3140,"filename":"job.log","file_format":null}]
```

{{< /tab >}}

{{< tab title="Python" >}}

```python
#!/usr/bin/env python

import datetime
import gitlab
import os
import sys

GITLAB_SERVER = os.environ.get('GL_SERVER', 'https://gitlab.com')
GITLAB_TOKEN = os.environ.get('GL_TOKEN') # token requires developer permissions
PROJECT_ID = os.environ.get('GL_PROJECT_ID') #optional
GROUP_ID = os.environ.get('GL_GROUP_ID') #optional

if __name__ == "__main__":
    if not GITLAB_TOKEN:
        print("🤔 Please set the GL_TOKEN env variable.")
        sys.exit(1)

    gl = gitlab.Gitlab(GITLAB_SERVER, private_token=GITLAB_TOKEN, pagination="keyset", order_by="id", per_page=100)

    # Collect all projects, or prefer projects from a group id, or a project id
    projects = []

    # Direct project ID
    if PROJECT_ID:
        projects.append(gl.projects.get(PROJECT_ID))
    # Groups and projects inside
    elif GROUP_ID:
        group = gl.groups.get(GROUP_ID)

        for project in group.projects.list(include_subgroups=True, get_all=True):
            manageable_project = gl.projects.get(project.id , lazy=True)
            projects.append(manageable_project)

    for project in projects:
        jobs = project.jobs.list(pagination="keyset", order_by="id", per_page=100, iterator=True)
        for job in jobs:
            print("DEBUG: ID {i}: {a}".format(i=job.id, a=job.attributes['artifacts']))
```

{{< /tab >}}

{{< /tabs >}}

Le script génère les artefacts de job du projet dans une liste formatée en JSON :

```json
[
    {
        "file_type": "archive",
        "size": 1049089,
        "filename": "artifacts.zip",
        "file_format": "zip"
    },
    {
        "file_type": "metadata",
        "size": 157,
        "filename": "metadata.gz",
        "file_format": "gzip"
    },
    {
        "file_type": "trace",
        "size": 3146,
        "filename": "job.log",
        "file_format": null
    }
]
```

## Gérer le stockage du pipeline CI/CD {#manage-cicd-pipeline-storage}

Les artefacts de job consomment la majeure partie du stockage du pipeline, et les job logs peuvent également générer plusieurs centaines de kilo-octets. Vous devez d'abord supprimer les artefacts de job inutiles, puis nettoyer les job logs après l'analyse.

> [!warning]
> La suppression d'un job log et des artefacts est une action destructrice qui ne peut pas être annulée. À utiliser avec précaution. La suppression de certains fichiers, notamment les artefacts de rapport, les job logs et les fichiers de métadonnées, affecte les fonctionnalités GitLab qui utilisent ces fichiers comme sources de données.

### Lister les artefacts de job {#list-job-artifacts}

Pour analyser le stockage du pipeline, vous pouvez utiliser l'[endpoint de l'API Job](../api/jobs.md#list-all-jobs-for-a-project) pour récupérer une liste d'artefacts de job. L'endpoint renvoie la clé `file_type` des artefacts de job dans l'attribut `artifacts`. La clé `file_type` indique le type d'artefact :

- `archive` est utilisé pour les artefacts de job générés sous forme de fichier zip.
- `metadata` est utilisé pour les métadonnées supplémentaires dans un fichier Gzip.
- `trace` est utilisé pour le `job.log` en tant que fichier brut.

Les artefacts de job fournissent une structure de données qui peut être écrite sous forme de fichier cache sur le disque, que vous pouvez utiliser pour tester l'implémentation.

En vous basant sur l'exemple de code pour récupérer tous les projets, vous pouvez étendre le script Python pour effectuer des analyses supplémentaires.

L'exemple suivant montre une réponse à une requête d'artefacts de job dans un projet :

```json
[
    {
        "file_type": "archive",
        "size": 1049089,
        "filename": "artifacts.zip",
        "file_format": "zip"
    },
    {
        "file_type": "metadata",
        "size": 157,
        "filename": "metadata.gz",
        "file_format": "gzip"
    },
    {
        "file_type": "trace",
        "size": 3146,
        "filename": "job.log",
        "file_format": null
    }
]
```

Selon la façon dont vous implémentez le script, vous pouvez soit :

- Collecter tous les artefacts de job et afficher un tableau récapitulatif à la fin du script.
- Afficher les informations immédiatement.

Dans l'exemple suivant, les artefacts de job sont collectés dans la liste `ci_job_artifacts`. Le script parcourt tous les projets et récupère :

- La variable objet `project_obj` qui contient tous les attributs.
- L'attribut `artifacts` de l'objet `job`.

Vous pouvez utiliser la [pagination par jeu de clés](https://python-gitlab.readthedocs.io/en/stable/api-usage.html#pagination) pour itérer sur de grandes listes de pipelines et de jobs.

```python
   ci_job_artifacts = []

    for project in projects:
        project_obj = gl.projects.get(project.id)

        jobs = project.jobs.list(pagination="keyset", order_by="id", per_page=100, iterator=True)

        for job in jobs:
            artifacts = job.attributes['artifacts']
            #print("DEBUG: ID {i}: {a}".format(i=job.id, a=json.dumps(artifacts, indent=4)))
            if not artifacts:
                continue

            for a in artifacts:
                data = {
                    "project_id": project_obj.id,
                    "project_web_url": project_obj.name,
                    "project_path_with_namespace": project_obj.path_with_namespace,
                    "job_id": job.id,
                    "artifact_filename": a['filename'],
                    "artifact_file_type": a['file_type'],
                    "artifact_size": a['size']
                }

                ci_job_artifacts.append(data)

    print("\nDone collecting data.")

    if len(ci_job_artifacts) > 0:
        print("| Project | Job | Artifact name | Artifact type | Artifact size |\n|---------|-----|---------------|---------------|---------------|") # Start markdown friendly table
        for artifact in ci_job_artifacts:
            print('| [{project_name}]({project_web_url}) | {job_name} | {artifact_name} | {artifact_type} | {artifact_size} |'.format(project_name=artifact['project_path_with_namespace'], project_web_url=artifact['project_web_url'], job_name=artifact['job_id'], artifact_name=artifact['artifact_filename'], artifact_type=artifact['artifact_file_type'], artifact_size=render_size_mb(artifact['artifact_size'])))
    else:
        print("No artifacts found.")
```

À la fin du script, les artefacts de job sont affichés sous forme de tableau formaté en Markdown. Vous pouvez copier le contenu du tableau dans un commentaire ou une description de ticket, ou alimenter un fichier Markdown dans un dépôt GitLab.

```shell
$ python3 get_all_projects_top_level_namespace_storage_analysis_cleanup_example.py

| Project | Job | Artifact name | Artifact type | Artifact size |
|---------|-----|---------------|---------------|---------------|
| [gitlab-da/playground/artifact-gen-group/gen-job-artifacts-4](Gen Job Artifacts 4) | 4828297946 | artifacts.zip | archive | 50.0154 |
| [gitlab-da/playground/artifact-gen-group/gen-job-artifacts-4](Gen Job Artifacts 4) | 4828297946 | metadata.gz | metadata | 0.0001 |
| [gitlab-da/playground/artifact-gen-group/gen-job-artifacts-4](Gen Job Artifacts 4) | 4828297946 | job.log | trace | 0.0030 |
| [gitlab-da/playground/artifact-gen-group/gen-job-artifacts-4](Gen Job Artifacts 4) | 4828297945 | artifacts.zip | archive | 20.0063 |
| [gitlab-da/playground/artifact-gen-group/gen-job-artifacts-4](Gen Job Artifacts 4) | 4828297945 | metadata.gz | metadata | 0.0001 |
| [gitlab-da/playground/artifact-gen-group/gen-job-artifacts-4](Gen Job Artifacts 4) | 4828297945 | job.log | trace | 0.0030 |
```

### Supprimer des artefacts de job en masse {#delete-job-artifacts-in-bulk}

Vous pouvez utiliser un script Python pour filtrer les types d'artefacts de job à supprimer en masse.

Filtrez les résultats des requêtes API pour comparer :

- La valeur `created_at` pour calculer l'âge de l'artefact.
- L'attribut `size` pour déterminer si les artefacts respectent le seuil de taille.

Une requête typique :

- Supprime les artefacts de job plus anciens que le nombre de jours spécifié.
- Supprime les artefacts de job qui dépassent une quantité de stockage spécifiée. Par exemple, 100 Mo.

Dans l'exemple suivant, le script parcourt les attributs de job et les marque pour suppression. Lorsque les boucles de collecte suppriment les verrous d'objet, le script supprime les artefacts de job marqués pour suppression.

```python
   for project in projects:
        project_obj = gl.projects.get(project.id)

        jobs = project.jobs.list(pagination="keyset", order_by="id", per_page=100, iterator=True)

        for job in jobs:
            artifacts = job.attributes['artifacts']
            if not artifacts:
                continue

            # Advanced filtering: Age and Size
            # Example: 90 days, 10 MB threshold (TODO: Make this configurable)
            threshold_age = 90 * 24 * 60 * 60
            threshold_size = 10 * 1024 * 1024

            # job age, need to parse API format: 2023-08-08T22:41:08.270Z
            created_at = datetime.datetime.strptime(job.created_at, '%Y-%m-%dT%H:%M:%S.%fZ')
            now = datetime.datetime.now()
            age = (now - created_at).total_seconds()
            # Shorter: Use a function
            # age = calculate_age(job.created_at)

            for a in artifacts:
                # Analysis collection code removed for readability

                # Advanced filtering: match job artifacts age and size against thresholds
                if (float(age) > float(threshold_age)) or (float(a['size']) > float(threshold_size)):
                    # mark job for deletion (cannot delete inside the loop)
                    jobs_marked_delete_artifacts.append(job)

    print("\nDone collecting data.")

    # Advanced filtering: Delete all job artifacts marked to being deleted.
    for job in jobs_marked_delete_artifacts:
        # delete the artifact
        print("DEBUG", job)
        job.delete_artifacts()

    # Print collection summary (removed for readability)
```

### Supprimer tous les artefacts de job d'un projet {#delete-all-job-artifacts-for-a-project}

Si vous n'avez pas besoin des [artefacts de job](../ci/jobs/job_artifacts.md) du projet, vous pouvez utiliser la commande suivante pour supprimer tous les artefacts de job. Cette action ne peut pas être annulée.

La suppression des artefacts peut prendre plusieurs minutes ou heures, selon le nombre d'artefacts à supprimer. Les requêtes d'analyse ultérieures envoyées à l'API peuvent renvoyer les artefacts comme résultat faux positif. Pour éviter toute confusion avec les résultats, n'exécutez pas immédiatement des requêtes API supplémentaires.

Les [artefacts des jobs réussis les plus récents](../ci/jobs/job_artifacts.md#keep-artifacts-from-most-recent-successful-jobs) sont conservés par défaut.

Pour supprimer tous les artefacts de job d'un projet :

{{< tabs >}}

{{< tab title="curl" >}}

```shell
export GL_PROJECT_ID=48349590

curl --silent --header "Authorization: Bearer $GITLAB_TOKEN" --request DELETE "https://gitlab.com/api/v4/projects/$GL_PROJECT_ID/artifacts"
```

{{< /tab >}}

{{< tab title="GitLab CLI" >}}

```shell
glab api --method GET projects/$GL_PROJECT_ID/jobs | jq --compact-output '.[]' | jq --compact-output '.id, .artifacts'

glab api --method DELETE projects/$GL_PROJECT_ID/artifacts
```

{{< /tab >}}

{{< tab title="Python" >}}

```python
        project.artifacts.delete()
```

{{< /tab >}}

{{< /tabs >}}

### Supprimer les job logs {#delete-job-logs}

Lorsque vous supprimez un job log, vous [effacez également le job entier](../api/jobs.md#erase-a-job).

Exemple avec GitLab CLI :

```shell
glab api --method GET projects/$GL_PROJECT_ID/jobs | jq --compact-output '.[]' | jq --compact-output '.id'

4836226184
4836226183
4836226181
4836226180

glab api --method POST projects/$GL_PROJECT_ID/jobs/4836226180/erase | jq --compact-output '.name,.status'
"generate-package: [1]"
"success"
```

Dans la bibliothèque d'API `python-gitlab`, utilisez [`job.erase()`](https://python-gitlab.readthedocs.io/en/stable/gl_objects/pipelines_and_jobs.html#jobs) à la place de `job.delete_artifacts()`. Pour éviter que cet appel API ne soit bloqué, configurez le script pour qu'il se mette en veille pendant une courte période entre les appels qui suppriment l'artefact de job :

```python
    for job in jobs_marked_delete_artifacts:
        # delete the artifacts and job log
        print("DEBUG", job)
        #job.delete_artifacts()
        job.erase()
        # Sleep for 1 second
        time.sleep(1)
```

La prise en charge de la création d'une politique de rétention pour les job logs est proposée dans le [ticket 374717](https://gitlab.com/gitlab-org/gitlab/-/issues/374717).

### Supprimer les anciens pipelines {#delete-old-pipelines}

Les pipelines n'augmentent pas l'utilisation globale du stockage, mais si nécessaire, vous pouvez [automatiser leur suppression](../ci/pipelines/settings.md#automatic-pipeline-cleanup).

Pour supprimer des pipelines en fonction d'une date spécifique, spécifiez la clé `created_at`. Vous pouvez utiliser la date pour calculer la différence entre la date actuelle et la date de création du pipeline. Si l'âge est supérieur au seuil, le pipeline est supprimé.

> [!note]
> La clé `created_at` doit être convertie d'un horodatage en temps Unix epoch, par exemple avec `date -d '2023-08-08T18:59:47.581Z' +%s`.

Exemple avec GitLab CLI :

```shell
export GL_PROJECT_ID=48349590

glab api --method GET projects/$GL_PROJECT_ID/pipelines | jq --compact-output '.[]' | jq --compact-output '.id,.created_at'
960031926
"2023-08-08T22:09:52.745Z"
959884072
"2023-08-08T18:59:47.581Z"

glab api --method DELETE projects/$GL_PROJECT_ID/pipelines/960031926

glab api --method GET projects/$GL_PROJECT_ID/pipelines | jq --compact-output '.[]' | jq --compact-output '.id,.created_at'
959884072
"2023-08-08T18:59:47.581Z"
```

Dans l'exemple suivant qui utilise un script Bash :

- `jq` et GitLab CLI sont installés et autorisés.
- La variable d'environnement exportée `GL_PROJECT_ID`. Valeur par défaut de la variable prédéfinie GitLab `CI_PROJECT_ID`.
- La variable d'environnement exportée `CI_SERVER_HOST` qui pointe vers l'URL de l'instance GitLab.

{{< tabs >}}

{{< tab title="Utilisation de l'API avec glab" >}}

Le script complet `get_cicd_pipelines_compare_age_threshold_example.sh` est situé dans le projet [GitLab API with Linux Shell](https://gitlab.com/gitlab-da/use-cases/gitlab-api/gitlab-api-linux-shell).

```shell
#!/bin/bash

# Required programs:
# - GitLab CLI (glab): https://docs.gitlab.com/cli/
# - jq: https://jqlang.github.io/jq/

# Required variables:
# - PAT: Project Access Token with API scope and Owner role, or Personal Access Token with API scope
# - GL_PROJECT_ID: ID of the project where pipelines must be cleaned
# - AGE_THRESHOLD (optional): Maximum age in days of pipelines to keep (default: 90)

set -euo pipefail

# Constants
DEFAULT_AGE_THRESHOLD=90
SECONDS_PER_DAY=$((24 * 60 * 60))

# Functions
log_info() {
    echo "[INFO] $1"
}

log_error() {
    echo "[ERROR] $1" >&2
}

delete_pipeline() {
    local project_id=$1
    local pipeline_id=$2
    if glab api --method DELETE "projects/$project_id/pipelines/$pipeline_id"; then
        log_info "Deleted pipeline ID $pipeline_id"
    else
        log_error "Failed to delete pipeline ID $pipeline_id"
    fi
}

# Main script
main() {
    # Authenticate
    if ! glab auth login --hostname "$CI_SERVER_HOST" --token "$PAT"; then
        log_error "Authentication failed"
        exit 1
    fi

    # Set variables
    AGE_THRESHOLD=${AGE_THRESHOLD:-$DEFAULT_AGE_THRESHOLD}
    AGE_THRESHOLD_IN_SECONDS=$((AGE_THRESHOLD * SECONDS_PER_DAY))
    GL_PROJECT_ID=${GL_PROJECT_ID:-$CI_PROJECT_ID}

    # Fetch pipelines
    PIPELINES=$(glab api --method GET "projects/$GL_PROJECT_ID/pipelines")
    if [ -z "$PIPELINES" ]; then
        log_error "Failed to fetch pipelines or no pipelines found"
        exit 1
    fi

    # Process pipelines
    echo "$PIPELINES" | jq -r '.[] | [.id, .created_at] | @tsv' | while IFS=$'\t' read -r id created_at; do
        CREATED_AT_TS=$(date -d "$created_at" +%s)
        NOW=$(date +%s)
        AGE=$((NOW - CREATED_AT_TS))

        if [ "$AGE" -gt "$AGE_THRESHOLD_IN_SECONDS" ]; then
            log_info "Pipeline ID $id created at $created_at is older than threshold $AGE_THRESHOLD days, deleting..."
            delete_pipeline "$GL_PROJECT_ID" "$id"
        else
            log_info "Pipeline ID $id created at $created_at is not older than threshold $AGE_THRESHOLD days. Ignoring."
        fi
    done
}

main
```

{{< /tab >}}

{{< tab title="Utilisation de glab CLI" >}}

Le script complet `cleanup-old-pipelines.sh` est situé dans le projet [GitLab API with Linux Shell](https://gitlab.com/gitlab-da/use-cases/gitlab-api/gitlab-api-linux-shell).

```shell
#!/bin/bash

set -euo pipefail

# Required environment variables:
# PAT: Project Access Token with API scope and Owner role, or Personal Access Token with API scope.
# Optional environment variables:
# AGE_THRESHOLD: Maximum age (in days) of pipelines to keep. Default: 90 days.
# REPO: Repository to clean up. If not set, the current repository will be used.
# CI_SERVER_HOST: GitLab server hostname.

# Function to display error message and exit
error_exit() {
    echo "Error: $1" >&2
    exit 1
}

# Validate required environment variables
[[ -z "${PAT:-}" ]] && error_exit "PAT (Project Access Token or Personal Access Token) is not set."
[[ -z "${CI_SERVER_HOST:-}" ]] && error_exit "CI_SERVER_HOST is not set."

# Set and validate AGE_THRESHOLD
AGE_THRESHOLD=${AGE_THRESHOLD:-90}
[[ ! "$AGE_THRESHOLD" =~ ^[0-9]+$ ]] && error_exit "AGE_THRESHOLD must be a positive integer."

AGE_THRESHOLD_IN_HOURS=$((AGE_THRESHOLD * 24))

echo "Deleting pipelines older than $AGE_THRESHOLD days"

# Authenticate with GitLab
glab auth login --hostname "$CI_SERVER_HOST" --token "$PAT" || error_exit "Authentication failed"

# Delete old pipelines
delete_cmd="glab ci delete --older-than ${AGE_THRESHOLD_IN_HOURS}h"
if [[ -n "${REPO:-}" ]]; then
    delete_cmd+=" --repo $REPO"
fi

$delete_cmd || error_exit "Pipeline deletion failed"

echo "Pipeline cleanup completed."
```

{{< /tab >}}

{{< tab title="Utilisation de l'API avec Python" >}}

Vous pouvez également utiliser la [bibliothèque d'API `python-gitlab`](https://python-gitlab.readthedocs.io/en/stable/gl_objects/pipelines_and_jobs.html#project-pipelines) et l'attribut `created_at` pour implémenter un algorithme similaire qui compare l'âge des artefacts de job :

```python
        # ...

        for pipeline in project.pipelines.list(iterator=True):
            pipeline_obj = project.pipelines.get(pipeline.id)
            print("DEBUG: {p}".format(p=json.dumps(pipeline_obj.attributes, indent=4)))

            created_at = datetime.datetime.strptime(pipeline.created_at, '%Y-%m-%dT%H:%M:%S.%fZ')
            now = datetime.datetime.now()
            age = (now - created_at).total_seconds()

            threshold_age = 90 * 24 * 60 * 60

            if (float(age) > float(threshold_age)):
                print("Deleting pipeline", pipeline.id)
                pipeline_obj.delete()
```

{{< /tab >}}

{{< /tabs >}}

### Lister les paramètres d'expiration des artefacts de job {#list-expiry-settings-for-job-artifacts}

Pour gérer le stockage des artefacts, vous pouvez mettre à jour ou configurer la date d'expiration d'un artefact. Le paramètre d'expiration des artefacts est configuré dans chaque configuration de job dans le fichier `.gitlab-ci.yml`.

Si plusieurs projets sont impliqués et selon la façon dont les définitions de job sont organisées dans la configuration CI/CD, il peut être difficile de localiser le paramètre d'expiration. Vous pouvez utiliser un script pour rechercher dans l'ensemble de la configuration CI/CD. Cela inclut l'accès aux objets qui sont résolus après avoir hérité de valeurs, comme `extends` ou `!reference`.

Le script récupère les fichiers de configuration CI/CD fusionnés et recherche la clé artifacts pour :

- Identifier les jobs qui n'ont pas de paramètre d'expiration.
- Retourner les paramètres d'expiration pour les jobs dont l'expiration des artefacts est configurée.

Le processus suivant décrit comment le script recherche le paramètre d'expiration des artefacts :

1. Pour générer une configuration CI/CD fusionnée, le script parcourt tous les projets et appelle la méthode [`ci_lint()`](https://python-gitlab.readthedocs.io/en/stable/gl_objects/ci_lint.html).
1. La fonction `yaml_load` charge la configuration fusionnée dans des structures de données Python pour une analyse approfondie.
1. Un dictionnaire qui possède également la clé `script` s'identifie lui-même comme une définition de job, où la clé `artifacts` peut exister.
1. Si oui, le script analyse la sous-clé `expire_in` et stocke les détails pour les afficher ultérieurement dans un tableau récapitulatif Markdown.

```python
    ci_job_artifacts_expiry = {}

    # Loop over projects, fetch .gitlab-ci.yml, run the linter to get the full translated config, and extract the `artifacts:` setting
    # https://python-gitlab.readthedocs.io/en/stable/gl_objects/ci_lint.html
    for project in projects:
            project_obj = gl.projects.get(project.id)
            project_name = project_obj.name
            project_web_url = project_obj.web_url
            try:
                lint_result = project_obj.ci_lint.get()
                if lint_result.merged_yaml is None:
                    continue

                ci_pipeline = yaml.safe_load(lint_result.merged_yaml)
                #print("Project {p} Config\n{c}\n\n".format(p=project_name, c=json.dumps(ci_pipeline, indent=4)))

                for k in ci_pipeline:
                    v = ci_pipeline[k]
                    # This is a job object with `script` attribute
                    if isinstance(v, dict) and 'script' in v:
                        print(".", end="", flush=True) # Get some feedback that it is still looping
                        artifacts = v['artifacts'] if 'artifacts' in v else {}

                        print("Project {p} job {j} artifacts {a}".format(p=project_name, j=k, a=json.dumps(artifacts, indent=4)))

                        expire_in = None
                        if 'expire_in' in artifacts:
                            expire_in = artifacts['expire_in']

                        store_key = project_web_url + '_' + k
                        ci_job_artifacts_expiry[store_key] = { 'project_web_url': project_web_url,
                                                        'project_name': project_name,
                                                        'job_name': k,
                                                        'artifacts_expiry': expire_in}

            except Exception as e:
                 print(f"Exception searching artifacts on ci_pipelines: {e}".format(e=e))

    if len(ci_job_artifacts_expiry) > 0:
        print("| Project | Job | Artifact expiry |\n|---------|-----|-----------------|") #Start markdown friendly table
        for k, details in ci_job_artifacts_expiry.items():
            if details['job_name'][0] == '.':
                continue # ignore job templates that start with a '.'
            print(f'| [{ details["project_name"] }]({details["project_web_url"]}) | { details["job_name"] } | { details["artifacts_expiry"] if details["artifacts_expiry"] is not None else "❌ N/A" } |')
```

Le script génère un tableau récapitulatif Markdown avec :

- Nom et URL du projet.
- Nom du job.
- Le paramètre `artifacts:expire_in`, ou `N/A` si aucun paramètre n'est défini.

Le script n'affiche pas les modèles de job qui :

- Commencent par le caractère `.`.
- Ne sont pas instanciés en tant qu'objets de job à l'exécution générant des artefacts.

```shell
export GL_GROUP_ID=56595735

# Install script dependencies
python3 -m pip install 'python-gitlab[yaml]'

python3 get_all_cicd_config_artifacts_expiry.py

| Project | Job | Artifact expiry |
|---------|-----|-----------------|
| [Gen Job Artifacts 4](https://gitlab.com/gitlab-da/playground/artifact-gen-group/gen-job-artifacts-4) | generator | 30 days |
| [Gen Job Artifacts with expiry and included jobs](https://gitlab.com/gitlab-da/playground/artifact-gen-group/gen-job-artifacts-expiry-included-jobs) | included-job10 | 10 days |
| [Gen Job Artifacts with expiry and included jobs](https://gitlab.com/gitlab-da/playground/artifact-gen-group/gen-job-artifacts-expiry-included-jobs) | included-job1 | 1 days |
| [Gen Job Artifacts with expiry and included jobs](https://gitlab.com/gitlab-da/playground/artifact-gen-group/gen-job-artifacts-expiry-included-jobs) | included-job30 | 30 days |
| [Gen Job Artifacts with expiry and included jobs](https://gitlab.com/gitlab-da/playground/artifact-gen-group/gen-job-artifacts-expiry-included-jobs) | generator | 30 days |
| [Gen Job Artifacts 2](https://gitlab.com/gitlab-da/playground/artifact-gen-group/gen-job-artifacts-2) | generator | ❌ N/A |
| [Gen Job Artifacts 1](https://gitlab.com/gitlab-da/playground/artifact-gen-group/gen-job-artifacts-1) | generator | ❌ N/A |
```

Le script `get_all_cicd_config_artifacts_expiry.py` est situé dans le [projet GitLab API with Python](https://gitlab.com/gitlab-da/use-cases/gitlab-api/gitlab-api-python/).

Vous pouvez également utiliser la [recherche avancée](search/advanced_search.md) avec des requêtes API. L'exemple suivant utilise la [portée : blobs](../api/search.md#scope-blobs) pour rechercher la chaîne `artifacts` dans tous les fichiers `*.yml` :

```shell
# https://gitlab.com/gitlab-da/playground/artifact-gen-group/gen-job-artifacts-expiry-included-jobs
export GL_PROJECT_ID=48349263

glab api --method GET projects/$GL_PROJECT_ID/search --field "scope=blobs" --field "search=expire_in filename:*.yml"
```

Pour plus d'informations sur l'approche par inventaire, consultez [Comment GitLab peut aider à atténuer la suppression des images de conteneurs open source sur Docker Hub](https://about.gitlab.com/blog/how-gitlab-can-help-mitigate-deletion-open-source-images-docker-hub/).

### Définir l'expiration par défaut des artefacts de job {#set-default-expiry-for-job-artifacts}

Pour définir l'expiration par défaut des artefacts de job dans un projet, spécifiez la valeur `expire_in` dans le fichier `.gitlab-ci.yml` :

```yaml
default:
    artifacts:
        expire_in: 1 week
```

## Gérer le stockage des registres de conteneurs {#manage-container-registries-storage}

Les registres de conteneurs sont disponibles [pour les projets](../api/container_registry.md#within-a-project) ou [pour les groupes](../api/container_registry.md#within-a-group). Vous pouvez analyser les deux emplacements pour mettre en œuvre une stratégie de nettoyage.

### Lister les registres de conteneurs {#list-container-registries}

Pour lister les registres de conteneurs dans un projet :

{{< tabs >}}

{{< tab title="curl" >}}

```shell
export GL_PROJECT_ID=48057080

curl --silent --header "Authorization: Bearer $GITLAB_TOKEN" "https://gitlab.com/api/v4/projects/$GL_PROJECT_ID/registry/repositories" | jq --compact-output '.[]' | jq --compact-output '.id,.location' | jq
4435617
"registry.gitlab.com/gitlab-da/playground/container-package-gen-group/docker-alpine-generator"

curl --silent --header "Authorization: Bearer $GITLAB_TOKEN" "https://gitlab.com/api/v4/registry/repositories/4435617?size=true" | jq --compact-output '.id,.location,.size'
4435617
"registry.gitlab.com/gitlab-da/playground/container-package-gen-group/docker-alpine-generator"
3401613
```

{{< /tab >}}

{{< tab title="GitLab CLI" >}}

```shell
export GL_PROJECT_ID=48057080

glab api --method GET projects/$GL_PROJECT_ID/registry/repositories | jq --compact-output '.[]' | jq --compact-output '.id,.location'
4435617
"registry.gitlab.com/gitlab-da/playground/container-package-gen-group/docker-alpine-generator"

glab api --method GET registry/repositories/4435617 --field='size=true' | jq --compact-output '.id,.location,.size'
4435617
"registry.gitlab.com/gitlab-da/playground/container-package-gen-group/docker-alpine-generator"
3401613

glab api --method GET projects/$GL_PROJECT_ID/registry/repositories/4435617/tags | jq --compact-output '.[]' | jq --compact-output '.name'
"latest"

glab api --method GET projects/$GL_PROJECT_ID/registry/repositories/4435617/tags/latest | jq --compact-output '.name,.created_at,.total_size'
"latest"
"2023-08-07T19:20:20.894+00:00"
3401613
```

{{< /tab >}}

{{< /tabs >}}

### Supprimer des images de conteneurs en masse {#delete-container-images-in-bulk}

Lorsque vous [supprimez des tags d'images de conteneurs en masse](../api/container_registry.md#delete-registry-repository-tags-in-bulk), vous pouvez configurer :

- Les expressions régulières correspondantes pour les noms de tags et les images à conserver (`name_regex_keep`) ou à supprimer (`name_regex_delete`)
- Le nombre de tags d'images à conserver correspondant au nom du tag (`keep_n`)
- Le nombre de jours avant qu'un tag d'image puisse être supprimé (`older_than`)

> [!warning]
> Sur GitLab.com, en raison de l'échelle du registre de conteneurs, le nombre de tags supprimés par cette API est limité. Si votre registre de conteneurs contient un grand nombre de tags à supprimer, seuls certains d'entre eux sont supprimés. Vous devrez peut-être appeler l'API plusieurs fois. Pour planifier la suppression automatique des tags, utilisez plutôt une [politique de nettoyage](#create-a-cleanup-policy-for-containers).

L'exemple suivant utilise la [bibliothèque d'API `python-gitlab`](https://python-gitlab.readthedocs.io/en/stable/gl_objects/repository_tags.html) pour récupérer une liste de tags et appelle la méthode `delete_in_bulk()` avec des paramètres de filtre.

```python
        repositories = project.repositories.list(iterator=True, size=True)
        if len(repositories) > 0:
            repository = repositories.pop()
            tags = repository.tags.list()

            # Cleanup: Keep only the latest tag
            repository.tags.delete_in_bulk(keep_n=1)
            # Cleanup: Delete all tags older than 1 month
            repository.tags.delete_in_bulk(older_than="1m")
            # Cleanup: Delete all tags matching the regex `v.*`, and keep the latest 2 tags
            repository.tags.delete_in_bulk(name_regex_delete="v.+", keep_n=2)
```

### Créer une politique de nettoyage pour les conteneurs {#create-a-cleanup-policy-for-containers}

Utilisez l'endpoint de l'API REST du projet pour [créer des politiques de nettoyage](packages/container_registry/reduce_container_registry_storage.md#use-the-cleanup-policy-api) pour les conteneurs. Après avoir défini la politique de nettoyage, toutes les images de conteneurs correspondant à vos spécifications sont supprimées automatiquement. Vous n'avez pas besoin de scripts d'automatisation d'API supplémentaires.

Pour envoyer les attributs en tant que paramètre body :

- Utilisez le paramètre `--input -` pour lire depuis l'entrée standard.
- Définissez l'en-tête `Content-Type`.

L'exemple suivant utilise GitLab CLI pour créer une politique de nettoyage :

```shell
export GL_PROJECT_ID=48057080

echo '{"container_expiration_policy_attributes":{"cadence":"1month","enabled":true,"keep_n":1,"older_than":"14d","name_regex":".*","name_regex_keep":".*-main"}}' | glab api --method PUT --header 'Content-Type: application/json;charset=UTF-8' projects/$GL_PROJECT_ID --input -

...

  "container_expiration_policy": {
    "cadence": "1month",
    "enabled": true,
    "keep_n": 1,
    "older_than": "14d",
    "name_regex": ".*",
    "name_regex_keep": ".*-main",
    "next_run_at": "2023-09-08T21:16:25.354Z"
  },

```

### Optimiser les images de conteneurs {#optimize-container-images}

Vous pouvez optimiser les images de conteneurs pour réduire la taille des images et la consommation globale de stockage dans le registre de conteneurs. En savoir plus dans la [documentation sur l'efficacité des pipelines](../ci/pipelines/pipeline_efficiency.md#optimize-docker-images).

## Gérer le stockage du registre de paquets {#manage-package-registry-storage}

Les registres de paquets sont disponibles [pour les projets](../api/packages.md#for-a-project) ou [pour les groupes](../api/packages.md#for-a-group).

### Lister les paquets et les fichiers {#list-packages-and-files}

L'exemple suivant montre comment récupérer des paquets à partir d'un ID de projet défini en utilisant GitLab CLI. Le jeu de résultats est un tableau d'éléments de dictionnaire qui peut être filtré avec la chaîne de commandes `jq`.

```shell
# https://gitlab.com/gitlab-da/playground/container-package-gen-group/generic-package-generator
export GL_PROJECT_ID=48377643

glab api --method GET projects/$GL_PROJECT_ID/packages | jq --compact-output '.[]' | jq --compact-output '.id,.name,.package_type'
16669383
"generator"
"generic"
16671352
"generator"
"generic"
16672235
"generator"
"generic"
16672237
"generator"
"generic"
```

Utilisez l'ID du paquet pour inspecter les fichiers et leur taille dans le paquet.

```shell
glab api --method GET projects/$GL_PROJECT_ID/packages/16669383/package_files | jq --compact-output '.[]' |
 jq --compact-output '.package_id,.file_name,.size'

16669383
"nighly.tar.gz"
10487563
```

Un script shell d'automatisation similaire est créé dans la section [Supprimer les anciens pipelines](#delete-old-pipelines).

L'exemple de script suivant utilise la bibliothèque `python-gitlab` pour récupérer tous les paquets dans une boucle et parcourt ses fichiers de paquets pour afficher les attributs `file_name` et `size`.

```python
        packages = project.packages.list(order_by="created_at")

        for package in packages:

            package_files = package.package_files.list()
            for package_file in package_files:
                print("Package name: {p} File name: {f} Size {s}".format(
                    p=package.name, f=package_file.file_name, s=render_size_mb(package_file.size)))
```

### Supprimer des paquets {#delete-packages}

[La suppression d'un fichier dans un paquet](../api/packages.md#delete-a-package-file) peut corrompre le paquet. Vous devez supprimer le paquet lors d'une maintenance de nettoyage automatisée.

Pour supprimer un paquet, utilisez GitLab CLI pour modifier le paramètre `--method` en `DELETE` :

```shell
glab api --method DELETE projects/$GL_PROJECT_ID/packages/16669383
```

Pour calculer la taille du paquet et la comparer à un seuil de taille, vous pouvez utiliser la bibliothèque `python-gitlab` pour étendre le code décrit dans la section [Lister les paquets et les fichiers](#list-packages-and-files).

L'exemple de code suivant calcule également l'âge du paquet et supprime le paquet lorsque les conditions correspondent :

```python
        packages = project.packages.list(order_by="created_at")
        for package in packages:
            package_size = 0.0

            package_files = package.package_files.list()
            for package_file in package_files:
                print("Package name: {p} File name: {f} Size {s}".format(
                    p=package.name, f=package_file.file_name, s=render_size_mb(package_file.size)))

                package_size =+ package_file.size

            print("Package size: {s}\n\n".format(s=render_size_mb(package_size)))

            threshold_size = 10 * 1024 * 1024

            if (package_size > float(threshold_size)):
                print("Package size {s} > threshold {t}, deleting package.".format(
                    s=render_size_mb(package_size), t=render_size_mb(threshold_size)))
                package.delete()

            threshold_age = 90 * 24 * 60 * 60
            package_age = created_at = calculate_age(package.created_at)

            if (float(package_age > float(threshold_age))):
                print("Package age {a} > threshold {t}, deleting package.".format(
                    a=render_age_time(package_age), t=render_age_time(threshold_age)))
                package.delete()
```

Le code génère la sortie suivante que vous pouvez utiliser pour une analyse approfondie :

```shell
Package name: generator File name: nighly.tar.gz Size 10.0017
Package size: 10.0017
Package size 10.0017 > threshold 10.0000, deleting package.

Package name: generator File name: 1-nightly.tar.gz Size 1.0004
Package size: 1.0004

Package name: generator File name: 10-nightly.tar.gz Size 10.0018
Package name: generator File name: 20-nightly.tar.gz Size 20.0033
Package size: 20.0033
Package size 20.0033 > threshold 10.0000, deleting package.
```

### Proxy de dépendances {#dependency-proxy}

Consultez la [politique de nettoyage](packages/dependency_proxy/reduce_dependency_proxy_storage.md#cleanup-policies) et la procédure pour [purger le cache à l'aide de l'API](packages/dependency_proxy/reduce_dependency_proxy_storage.md#use-the-api-to-clear-the-cache)

## Améliorer la lisibilité des sorties {#improve-output-readability}

Vous devrez peut-être convertir des secondes d'horodatage en format de durée, ou afficher des octets bruts dans un format plus représentatif. Vous pouvez utiliser les fonctions d'aide suivantes pour transformer les valeurs afin d'améliorer la lisibilité :

```shell
# Current Unix timestamp
date +%s

# Convert `created_at` date time with timezone to Unix timestamp
date -d '2023-08-08T18:59:47.581Z' +%s
```

Exemple avec Python qui utilise la bibliothèque d'API `python-gitlab` :

```python
def render_size_mb(v):
    return "%.4f" % (v / 1024 / 1024)

def render_age_time(v):
    return str(datetime.timedelta(seconds = v))

# Convert `created_at` date time with timezone to Unix timestamp
def calculate_age(created_at_datetime):
    created_at_ts = datetime.datetime.strptime(created_at_datetime, '%Y-%m-%dT%H:%M:%S.%fZ')
    now = datetime.datetime.now()
    return (now - created_at_ts).total_seconds()
```

## Tests pour l'automatisation de la gestion du stockage {#testing-for-storage-management-automation}

Pour tester l'automatisation de la gestion du stockage, vous devrez peut-être générer des données de test ou alimenter le stockage pour vérifier que l'analyse et la suppression fonctionnent comme prévu. Les sections suivantes fournissent des outils et des conseils sur les tests et la génération de blobs de stockage en peu de temps.

### Générer des artefacts de job {#generate-job-artifacts}

Créez un projet de test pour générer de faux blobs d'artefacts à l'aide de builds matriciels de jobs CI/CD. Ajoutez un pipeline CI/CD pour générer des artefacts quotidiennement

1. Créez un nouveau projet.
1. Ajoutez l'extrait suivant à `.gitlab-ci.yml` pour inclure la configuration du générateur d'artefacts de job.

   ```yaml
   include:
       - remote: https://gitlab.com/gitlab-da/use-cases/efficiency/job-artifact-generator/-/raw/main/.gitlab-ci.yml
   ```

1. [Configurez les planifications de pipeline](../ci/pipelines/schedules.md#create-a-pipeline-schedule).
1. [Déclenchez le pipeline manuellement](../ci/pipelines/schedules.md#run-manually).

Vous pouvez également réduire les 86 Mo générés quotidiennement à différentes valeurs dans la variable `MB_COUNT`.

```yaml
include:
    - remote: https://gitlab.com/gitlab-da/use-cases/efficiency/job-artifact-generator/-/raw/main/.gitlab-ci.yml

generator:
    parallel:
        matrix:
            - MB_COUNT: [1, 5, 10, 20, 50]

```

Pour plus d'informations, consultez le [README du générateur d'artefacts de job](https://gitlab.com/gitlab-da/use-cases/efficiency/job-artifact-generator), avec un [groupe d'exemple](https://gitlab.com/gitlab-da/playground/artifact-gen-group).

### Générer des artefacts de job avec expiration {#generate-job-artifacts-with-expiry}

La configuration CI/CD du projet spécifie les définitions de job dans :

- Le fichier de configuration principal `.gitlab-ci.yml`.
- Le paramètre `artifacts:expire_in`.
- Les fichiers et modèles du projet.

Pour tester les scripts d'analyse, le projet [`gen-job-artifacts-expiry-included-jobs`](https://gitlab.com/gitlab-da/playground/artifact-gen-group/gen-job-artifacts-expiry-included-jobs) fournit un exemple de configuration.

```yaml
# .gitlab-ci.yml
include:
    - include_jobs.yml

default:
  artifacts:
      paths:
          - '*.txt'

.gen-tmpl:
    script:
        - dd if=/dev/urandom of=${$MB_COUNT}.txt bs=1048576 count=${$MB_COUNT}

generator:
    extends: [.gen-tmpl]
    parallel:
        matrix:
            - MB_COUNT: [1, 5, 10, 20, 50]
    artifacts:
        untracked: false
        when: on_success
        expire_in: 30 days

# include_jobs.yml
.includeme:
    script:
        - dd if=/dev/urandom of=1.txt bs=1048576 count=1

included-job10:
    script:
        - echo "Servus"
        - !reference [.includeme, script]
    artifacts:
        untracked: false
        when: on_success
        expire_in: 10 days

included-job1:
    script:
        - echo "Gruezi"
        - !reference [.includeme, script]
    artifacts:
        untracked: false
        when: on_success
        expire_in: 1 days

included-job30:
    script:
        - echo "Grias di"
        - !reference [.includeme, script]
    artifacts:
        untracked: false
        when: on_success
        expire_in: 30 days
```

### Générer des images de conteneurs {#generate-container-images}

Le groupe d'exemple [`container-package-gen-group`](https://gitlab.com/gitlab-da/playground/container-package-gen-group) fournit des projets qui :

- Utilisent une image de base dans le Dockerfile pour construire une nouvelle image.
- Incluent le modèle `Docker.gitlab-ci.yml` pour construire des images sur GitLab.com.
- Configurent des planifications de pipeline pour générer de nouvelles images quotidiennement.

Exemples de projets disponibles à dupliquer :

- [`docker-alpine-generator`](https://gitlab.com/gitlab-da/playground/container-package-gen-group/docker-alpine-generator)
- [`docker-python-generator`](https://gitlab.com/gitlab-da/playground/container-package-gen-group/docker-python-generator)

### Générer des paquets génériques {#generate-generic-packages}

Le projet d'exemple [`generic-package-generator`](https://gitlab.com/gitlab-da/playground/container-package-gen-group/generic-package-generator) fournit des projets qui :

- Génèrent un blob de texte aléatoire et créent une archive tarball avec l'horodatage Unix actuel comme version de release.
- Chargent l'archive tarball dans le registre de paquets générique, en utilisant l'horodatage Unix comme version de release.

Pour générer des paquets génériques, vous pouvez utiliser cette configuration autonome `.gitlab-ci.yml` :

```yaml
generate-package:
  parallel:
    matrix:
      - MB_COUNT: [1, 5, 10, 20]
  before_script:
    - apt update && apt -y install curl
  script:
    - dd if=/dev/urandom of="${MB_COUNT}.txt" bs=1048576 count=${MB_COUNT}
    - tar czf "generated-$MB_COUNT-nighly-`date +%s`.tar.gz" "${MB_COUNT}.txt"
    - 'curl --header "JOB-TOKEN: $CI_JOB_TOKEN" --upload-file "generated-$MB_COUNT-nighly-`date +%s`.tar.gz" "${CI_API_V4_URL}/projects/${CI_PROJECT_ID}/packages/generic/generator/`date +%s`/${MB_COUNT}-nightly.tar.gz"'

  artifacts:
    paths:
      - '*.tar.gz'

```

### Générer de l'utilisation du stockage avec des duplications {#generate-storage-usage-with-forks}

Utilisez les projets suivants pour tester l'utilisation du stockage avec les [facteurs de coût pour les duplications](storage_usage_quotas.md#view-project-fork-storage-usage) :

- Dupliquez [`gitlab-org/gitlab`](https://gitlab.com/gitlab-org/gitlab) dans un nouvel espace de nommage ou groupe (inclut LFS, dépôt Git).
- Dupliquez [`gitlab-com/www-gitlab-com`](https://gitlab.com/gitlab-com/www-gitlab-com) dans un nouvel espace de nommage ou groupe.

## Ressources de la communauté {#community-resources}

Les ressources suivantes ne sont pas officiellement prises en charge. Assurez-vous de tester les scripts et les tutoriels avant d'exécuter des commandes de nettoyage destructrices qui pourraient ne pas être annulées.

- Sujet du forum : [Ressources pour l'automatisation de la gestion du stockage](https://forum.gitlab.com/t/storage-management-automation-resources/91184)
- Script : [GitLab Storage Analyzer](https://gitlab.com/gitlab-da/use-cases/gitlab-api/gitlab-storage-analyzer), projet non officiel de la [GitLab Developer Evangelism team](https://gitlab.com/gitlab-da/). Vous trouverez des exemples de code similaires dans ce guide pratique de documentation.
