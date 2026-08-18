---
stage: Verify
group: CI Functions Platform
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Créer une fonction GitLab
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Statut : Expérience

{{< /details >}}

Une fonction GitLab est un répertoire contenant un fichier `func.yml` qui définit l'interface et l'implémentation de la fonction. Les fonctions peuvent s'exécuter localement ou être publiées dans un registre OCI pour être réutilisées dans différents jobs et projets.

Pour plus d'informations sur l'utilisation des fonctions dans un job CI/CD, consultez [GitLab Functions](_index.md). Pour des exemples de fonctions, consultez [GitLab Functions examples](examples.md).

## Structure d'une fonction {#function-structure}

Une fonction est un répertoire qui contient au minimum un fichier `func.yml`, ainsi que tous les fichiers supplémentaires nécessaires à l'implémentation :

```plaintext
my-function/
├── func.yml
└── my-script.sh
```

Le fichier `func.yml` contient deux documents YAML séparés par `---` : une spécification qui définit les entrées et sorties de la fonction, et une définition qui décrit ce que fait la fonction.

```yaml
# Document 1: spec
spec:
  inputs:
    message:
      type: string
  outputs:
    result:
      type: string
---
# Document 2: definition
exec:
  command: ["${{ func_dir }}/my-script.sh", "${{ inputs.message }}"]
```

## Spécification : Déclarer les entrées et sorties {#spec-declare-inputs-and-outputs}

La spécification décrit l'interface de la fonction.

### Entrées {#inputs}

Chaque entrée nécessite un `type`. Les entrées avec une valeur `default` sont facultatives. Les entrées sans valeur par défaut doivent être fournies par l'appelant.

Les noms d'entrée doivent utiliser des caractères alphanumériques et des traits de soulignement, et ne peuvent pas commencer par un chiffre.

Les entrées doivent être de l'un des types suivants :

| Type      | Exemple                 | Description             |
|:----------|:------------------------|:------------------------|
| `array`   | `["a","b"]`             | Une liste d'éléments non typés |
| `boolean` | `true`                  | Vrai ou faux           |
| `number`  | `56.77`                 | Nombre flottant 64 bits            |
| `string`  | `"brown cow"`           | Texte                    |
| `struct`  | `{"k1":"v1","k2":"v2"}` | Contenu structuré      |

Par exemple :

```yaml
spec:
  inputs:
    # Required string input
    message:
      type: string

    # Optional input with a default
    count:
      type: number
      default: 1

    # Struct input for passing structured data
    config:
      type: struct
      default: {}
```

### Sorties {#outputs}

Les sorties définissent les valeurs que la fonction retourne aux étapes suivantes. Chaque sortie nécessite un `type`. Les sorties avec une valeur `default` sont facultatives. La valeur par défaut est utilisée lorsque la fonction n'écrit pas la valeur de sortie.

Les sorties utilisent les mêmes types et règles de nommage que les entrées.

Par exemple :

```yaml
spec:
  outputs:
    # Required string output
    artifact_path:
      type: string

    # Optional output with a default
    compressed:
      type: boolean
      default: false
```

Au moment de l'exécution, la fonction écrit les valeurs de sortie dans le chemin indiqué par `${{ output_file }}`. Chaque ligne doit être un objet JSON avec les champs `name` et `value` :

```shell
echo '{"name":"artifact_path","value":"/dist/app.tar.gz"}' >> "${{ output_file }}"
echo '{"name":"compressed","value":true}' >> "${{ output_file }}"
```

### Déléguer les sorties {#delegate-outputs}

Si une fonction comporte plusieurs étapes et que vous souhaitez que ses sorties proviennent d'une étape spécifique, utilisez `outputs: delegate` dans la spécification et `delegate: <step_name>` dans la définition :

```yaml
spec:
  outputs: delegate
---
run:
  - name: build
    func: ./build
  - name: package
    func: ./package
delegate: package  # use the package step outputs as this function outputs
```

## Définition : Implémenter la fonction {#definition-implement-the-function}

Le second document de `func.yml` décrit l'implémentation. Vous pouvez implémenter une fonction de deux manières.

### `exec` {#exec}

Utilisez `exec` pour exécuter une commande ou un script unique. La commande est transmise directement au système d'exploitation sans interpréteur de commandes, elle doit donc être un tableau de chaînes de caractères.

```yaml
spec:
  inputs:
    message:
      type: string
---
exec:
  command: ["./greet", "${{ inputs.message }}"]
```

Le répertoire de travail correspond par défaut à `CI_PROJECT_DIR`. Pour le remplacer, utilisez `work_dir`. Le mot-clé `work_dir` est valide uniquement pour les définitions `exec`, et non pour les définitions `run:`.

Définissez `work_dir` sur `${{ func_dir }}` lorsque la commande doit référencer des fichiers situés dans le même répertoire que `func.yml` :

```yaml
exec:
  command: ["./build.sh"]
  work_dir: "${{ func_dir }}"
```

La fonction échoue si la commande se termine avec un code de sortie non nul.

### `run` {#run}

Utilisez `run` pour une fonction qui appelle d'autres fonctions en séquence.

La fonction échoue si l'une des étapes de la séquence échoue. Les étapes suivantes de la séquence ne s'exécutent pas après un échec.

```yaml
spec:
  inputs:
    environment:
      type: string
  outputs:
    url:
      type: string
---
run:
  - name: build
    func: ./build
  - name: push
    func: registry.example.com/my-org/push:1.0.0
    inputs:
      artifact: ${{ steps.build.outputs.artifact_path }}
  - name: deploy
    func: ./deploy
    inputs:
      env: ${{ inputs.environment }}
      image: ${{ steps.push.outputs.image_ref }}
outputs:
  url: ${{ steps.deploy.outputs.url }}
```

### Définir des variables d'environnement {#set-environment-variables}

Utilisez `env` dans la définition pour définir des variables d'environnement pour la commande `exec` ou pour toutes les étapes d'une séquence `run:`. Les valeurs peuvent utiliser des expressions :

```yaml
spec:
---
run:
  - name: test
    func: ./run-tests
env:
  GOFLAGS: "-race"
  TARGET_ENV: "${{ inputs.environment }}"
```

## Exporter des variables d'environnement {#export-environment-variables}

Pour rendre une variable d'environnement disponible pour toutes les étapes qui s'exécutent après votre fonction pour le reste du job, écrivez-la dans `${{ export_file }}`. Chaque ligne doit être un objet JSON avec les champs `name` et `value` :

```shell
echo '{"name":"INSTALL_PATH","value":"/opt/myapp"}' >> "${{ export_file }}"
```

Seules les valeurs `string`, `number` et `boolean` peuvent être exportées en tant que variables d'environnement.

Pour plus d'informations sur la façon dont les variables exportées interagissent avec `env:` et l'environnement plus général, consultez [variables d'environnement](_index.md#environment-variables).

## Expressions {#expressions}

Les expressions utilisent la syntaxe `${{ }}` et sont évaluées juste avant l'exécution de la fonction. Elles peuvent apparaître dans les valeurs `inputs`, les valeurs `env`, les arguments de commande `exec` et `work_dir`.

Les variables de contexte suivantes sont disponibles dans une définition de fonction, en plus de celles décrites dans [expressions](_index.md#expressions) :

| Variable                                  | Description                                                                                 |
|:------------------------------------------|:--------------------------------------------------------------------------------------------|
| `inputs.<name>`                           | La valeur de l'entrée nommée transmise à cette fonction.                                       |
| `func_dir`                                | Chemin absolu vers le répertoire contenant ce fichier `func.yml`. À utiliser pour référencer les fichiers inclus.  |
| `output_file`                             | Chemin vers le fichier pour l'écriture des sorties.                                                       |
| `export_file`                             | Chemin vers le fichier pour l'exportation des variables d'environnement.                                       |
| `steps.<step_name>.outputs.<output_name>` | Sortie d'une étape nommée (disponible uniquement dans les définitions `run:`).                            |

## Exemple complet {#complete-example}

La fonction suivante accepte un chemin de fichier, le compresse avec `gzip` et retourne le chemin vers le fichier compressé.

### Créer la fonction {#create-the-function}

Structure du répertoire :

```plaintext
compress/
├── func.yml
└── compress.sh
```

`func.yml` :

```yaml
spec:
  inputs:
    input_path:
      type: string
  outputs:
    output_path:
      type: string
---
exec:
  command: ["${{ func_dir }}/compress.sh", "${{ inputs.input_path }}", "${{ output_file }}"]
```

`compress.sh` (doit être exécutable) :

```shell
#!/usr/bin/env sh
set -e

INPUT_PATH="$1"
OUTPUT_FILE="$2"

gzip --keep "$INPUT_PATH"

echo "{\"name\":\"output_path\",\"value\":\"${INPUT_PATH}.gz\"}" >> "$OUTPUT_FILE"
```

### Utiliser la fonction depuis un job {#use-the-function-from-a-job}

Cette fonction nécessite `gzip` dans l'environnement du job. Cet exemple suppose que `gzip` est déjà disponible sur l'instance où le job s'exécute. Si ce n'est pas le cas, vous pouvez l'installer au préalable avec une étape `script:`, ou invoquer une fonction qui gère l'installation avant d'appeler `compress`.

```yaml
my-job:
  run:
    - name: compress_artifact
      func: ./compress
      inputs:
        input_path: "dist/app.tar"
    - name: list_compressed
      script: ls -lh ${{ steps.compress_artifact.outputs.output_path }}
```

Pour plus d'exemples de fonctions, consultez [GitLab Functions examples](examples.md).

## Compiler et publier des fonctions {#build-and-release-functions}

Les fonctions sont distribuées sous forme d'images OCI. Le runner d'étapes fournit deux fonctions intégrées pour compiler et publier des images de fonctions.

### Compilation {#build}

La fonction `builtin://function/oci/build` compile une image OCI de fonction multi-architecture à partir des fichiers du répertoire de projet et l'archive sous le nom `function-image.tar` dans le `CI_PROJECT_DIR`.

`common.files` copie les fichiers partagés entre toutes les plateformes. `platforms.<os/arch>.files` copie les fichiers spécifiques à cette plateforme. Dans les deux cas, les clés de la correspondance sont les chemins de destination dans l'image et les valeurs sont les chemins sources relatifs à `CI_PROJECT_DIR`.

Dans l'exemple suivant, `function-image.tar` est une image OCI de fonction qui prend en charge deux plateformes : `linux/amd64` et `linux/arm64`. Chaque image de plateforme contient trois fichiers : `func.yml`, `my-script.sh` et `bin/my-binary`. L'utilisation du même nom de fichier pour les binaires de plateforme permet à `func.yml` d'être indépendant de la plateforme.

<!-- vale gitlab_base.Substitutions = NO -->
```yaml
build_function:
  artifacts:
    paths:
      - function-image.tar
  run:
    - name: build
      func: builtin://function/oci/build
      inputs:
        version: "1.2.3"
        common:
          files:
            func.yml: func.yml
            my-script.sh: my-script.sh
        platforms:
          linux/amd64:
            files:
              bin/my-binary: bin/linux-amd64/my-binary
          linux/arm64:
            files:
              bin/my-binary: bin/linux-arm64/my-binary
```
<!-- vale gitlab_base.Substitutions = YES -->

### Release {#release}

La fonction `builtin://function/oci/publish` publie l'archive issue de `function/oci/build` dans un registre OCI.

La fonction de publication utilise la gestion sémantique de version pour les tags d'image de fonction : `1.0.0`, `1.1.0`, `2.0.0`. La fonction extrait la version du fichier `function-image.tar`. La publication met à jour les tags `major`, `major.minor`, `major.minor.patch` et `latest` si nécessaire.

Les candidats à la release utilisent un suffixe de pré-release tel que `1.2.0-rc1`. La publication d'un candidat à la release crée uniquement le tag exact `major.minor.patch-prerelease`. Elle ne met pas à jour les tags `major`, `major.minor` ou `latest`.

```yaml
publish_function:
  needs: [build_function]
  run:
    - name: publish
      func: builtin://function/oci/publish
      inputs:
        archive: function-image.tar  # version is baked into the tar file
        to_repository: registry.example.com/my-org/my-function
```

### S'authentifier auprès d'un registre {#authenticate-to-a-registry}

Pour publier dans un registre privé, authentifiez-vous avant d'exécuter `function/oci/publish`. Utilisez la fonction [Docker Auth](https://gitlab.com/gitlab-org/ci-cd/runner-tools/gitlab-functions-examples/docker-auth) pour générer et exporter `DOCKER_AUTH_CONFIG` comme étape avant la publication :

```yaml
publish_function:
  needs: [build_function]
  run:
    - name: auth
      func: registry.gitlab.com/gitlab-org/ci-cd/runner-tools/gitlab-functions-examples/docker-auth:1
      inputs:
        registry: ${{ vars.CI_REGISTRY }}
        username: ${{ vars.CI_REGISTRY_USER }}
        password: ${{ vars.CI_REGISTRY_PASSWORD }}
    - name: publish
      func: builtin://function/oci/publish
      inputs:
        archive: function-image.tar
        to_repository: ${{ vars.CI_REGISTRY_IMAGE }}
```

`docker-auth` exporte `DOCKER_AUTH_CONFIG` vers toutes les étapes suivantes, de sorte que `function/oci/publish` le récupère automatiquement.

Une fois publiée, les appelants référencent la fonction en utilisant l'URL du registre et un tag :

```yaml
run:
  - name: run_my_function
    func: registry.example.com/my-org/my-function:1.2.3
```
