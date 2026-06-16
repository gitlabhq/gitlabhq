---
stage: AI-powered
group: Editor Extensions
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Agent Skills
---

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- Prise en charge des Agent Skills au niveau du projet [ajoutée](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/merge_requests/2951) dans GitLab 18.10.
  - [Introduit](https://gitlab.com/gitlab-org/gitlab-vscode-extension/-/releases/v6.71.4) dans GitLab for VS Code 6.71.4.
  - [Introduit](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/releases/v8.73.0) dans GitLab Duo CLI 8.73.0.
- Prise en charge des Agent Skills au niveau de l'utilisateur [introduite](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/merge_requests/3140) dans GitLab 19.0.
  - [Introduit](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/releases/v8.83.0) dans GitLab Duo CLI 8.83.0 en tant qu'[expérience](../../../policy/development_stages_support.md#experiment).

{{< /history >}}

GitLab Duo prend en charge la [spécification Agent Skills](https://agentskills.io/specification), un standard émergent permettant de donner aux agents de nouvelles capacités et expertises.

Utilisez les Agent Skills pour fournir aux agents des connaissances spécialisées et des workflows pour des tâches spécifiques, comme l'écriture de tests dans un framework particulier. Les agents chargent automatiquement les skills associées lorsqu'ils rencontrent des tâches et utilisent les informations durant leur travail.

Lorsque vous spécifiez un fichier `SKILL.md`, les skills sont disponibles pour GitLab Duo Agent Platform et tout autre outil d'IA prenant en charge la spécification.

Spécifiez les Agent Skills pour que GitLab Duo les utilise avec :

- GitLab Duo Chat dans votre environnement local.
- Les flows fondamentaux et personnalisés, à l'exclusion du flow Code Review.

Les skills au niveau de l'utilisateur sont uniquement disponibles pour une utilisation avec le GitLab Duo CLI.

## Comment GitLab Duo utilise les Agent Skills {#how-gitlab-duo-uses-agent-skills}

Lorsqu'un agent commence à travailler, GitLab Duo ajoute des métadonnées pour toutes les skills disponibles au contexte de l'agent. Lorsque l'agent rencontre une tâche correspondant à la description d'une skill, il charge automatiquement la skill et l'utilise pour accomplir la tâche.

Vous pouvez également demander manuellement à GitLab Duo d'utiliser une skill par son nom, son chemin de fichier ou une commande slash.

GitLab Duo prend en charge les types de skills suivants :

| Niveau                                                              | Interface utilisateur GitLab | Extensions de l'éditeur | GitLab Duo CLI |
|--------------------------------------------------------------------|-------------------------------|-------------------|----------------|
| Niveau utilisateur : S'appliquent à tous vos projets      | {{< no >}}                    | {{< no >}}        | {{< yes >}}    |
| Niveau projet : S'applique uniquement à un projet spécifique | {{< yes >}} <sup>1</sup>                   | {{< yes >}}       | {{< yes >}}    |

**Remarques** :

1. Dans l'interface utilisateur GitLab, seuls les flows fondamentaux et les flows personnalisés, à l'exclusion de la revue de code, prennent en charge les skills au niveau du projet. GitLab Duo Chat dans l'interface utilisateur GitLab ne prend pas en charge les skills.

## Utiliser les Agent Skills avec GitLab Duo {#use-agent-skills-with-gitlab-duo}

> [!note]
> Les conversations et flows existants n'ont pas automatiquement accès aux skills nouvelles ou mises à jour. Démarrez une nouvelle conversation ou demandez à GitLab Duo de charger une skill par son nom ou son chemin relatif.

### Prérequis {#prerequisites}

- Respectez les [prérequis de l'Agent Platform](../_index.md#prerequisites).
- Pour GitLab Duo Chat dans votre environnement local, installez et configurez l'un des éléments suivants :
  - Pour les skills au niveau du projet :
    - [GitLab for VS Code](../../../editor_extensions/visual_studio_code/setup.md) 6.71.4 ou version ultérieure.
    - [GitLab Duo CLI](../../gitlab_duo_cli/_index.md#set-up-the-gitlab-duo-cli) 8.73.0 ou version ultérieure.
  - Pour les skills au niveau de l'utilisateur :
    - [GitLab Duo CLI](../../gitlab_duo_cli/_index.md#set-up-the-gitlab-duo-cli) 8.83.0 ou version ultérieure.
- Pour les skills au niveau du projet avec des flows personnalisés, mettez à jour le fichier de configuration du flow pour accéder au contexte `workspace_agent_skills` transmis par l'exécuteur :

  ```yaml
  components:
  - name: "my_agent"
     type: AgentComponent
     prompt_id: "my_prompt"
     inputs:
     - from: "context:inputs.workspace_agent_skills"
        as: "workspace_agent_skills"
      optional: true
  ```

  En définissant `optional: true`, le flow gère de manière appropriée les cas où aucune agent skill n'existe. L'agent fonctionne avec ou sans contexte supplémentaire.

### Créer des skills {#create-skills}

Vous pouvez créer des skills au niveau du projet ou au niveau de l'utilisateur.

Si vous utilisez un workspace multi-racine dans votre IDE, vous pouvez créer des skills au niveau du projet pour chaque projet dans le workspace.

Si une skill au niveau de l'utilisateur et une skill au niveau du projet partagent le même nom, la skill au niveau du projet est prioritaire. Cela vous permet de remplacer une skill au niveau de l'utilisateur par une version spécifique au projet.

Dans un workspace multi-racine, si plusieurs projets définissent des skills avec le même nom, GitLab Duo charge la première qu'il rencontre.

#### Créer des skills au niveau du projet {#create-project-level-skills}

Les skills au niveau du projet s'appliquent à un projet spécifique. Vous les définissez dans un fichier `SKILL.md` dans un répertoire `skills/<skill-name>/` de votre projet.

Pour créer une skill au niveau du projet :

1. À la racine de votre projet, créez un répertoire `skills`.
1. Dans le nouveau répertoire, créez un autre répertoire pour la skill spécifique. Utilisez le nom de la skill comme nom de répertoire.
1. Créez un fichier `SKILL.md` et incluez des instructions en utilisant le format suivant. Les champs d'en-tête YAML `name` et `description` sont obligatoires.

   ```markdown
   ---
   name: <skill_name>
   description: <skill_description>
   ---

   <your_instructions_and_context_for_the_skill>
   ```

    Par exemple, une skill pour [signer des artefacts avec cosign](../../../ci/yaml/signing_examples.md) dans `skills/cosign-blob/SKILL.md` :

    ````markdown
    ---
    name: cosign-blob
    description: Sign artifacts using cosign with local keypairs and Sigstore v3 bundles. Integrate with 1Password for secure key management.
    ---

    ## Cosign Blob Signing

    Sign artifacts locally using cosign with Sigstore v3 bundles for artifact verification and integrity.

    ### Generate a Local Keypair

    Generate a new cosign keypair:

    ```shell
    cosign generate-key-pair
    ```

    This creates two files:
    - `cosign.key` - Private key (encrypted)
    - `cosign.pub` - Public key

    Store the private key securely, preferably in a password manager like 1Password.

    ### Store Private Key in 1Password

    1. Create a new login item in 1Password with:
      - Title: "Duo Skills cosign"
      - Username: (optional)
      - Password: Your cosign private key password

    2. Save the secret reference path (for example, `op://Employee/Duo Skills cosign/password`)

    ### Sign Artifacts with Cosign

    Sign a file and generate a Sigstore v3 bundle:

    ```shell
    COSIGN_PASSWORD=$(op read "op://Employee/Duo Skills cosign/password") \
      timeout -v 4 cosign sign-blob \
        --key ~/.gitlab/duo/cosign.key \
        --bundle <filename>.bundle \
        --new-bundle-format \
        --yes \
        <filename>
    ```

    Replace:
    - `<filename>` with the file to sign (for example, `SKILL.md`)
    - The bundle output will be saved as `<filename>.bundle`

    ### Key Points

    - Use timeout to fail-fast and report the error back to the user.
    - Use `--bundle` with `$file.bundle` format for Sigstore v3 bundles
    - Use `--yes` to skip interactive prompts
    - Use `--new-bundle-format` to output a v3 Sigstore bundle rather than the legacy format
    - Set `COSIGN_PASSWORD` environment variable to avoid password prompts
    - Integrate with 1Password CLI for secure credential management
    - The bundle file contains the signature and can be verified later
    ````

1. Enregistrez le fichier.
1. Démarrez une nouvelle conversation ou un nouveau flow. Vous devriez effectuer cette opération chaque fois que vous modifiez ou ajoutez un fichier `SKILL.md` pour éviter toute confusion de contexte pour l'agent.

#### Créer des skills au niveau de l'utilisateur {#create-user-level-skills}

{{< details >}}

- Statut : Expérience

{{< /details >}}

Les skills au niveau de l'utilisateur s'appliquent à l'ensemble de vos projets. Vous les définissez dans un fichier `SKILL.md` dans un répertoire `skills/<skill-name>/` dans votre répertoire personnel.

Les skills au niveau de l'utilisateur sont uniquement disponibles pour une utilisation avec le GitLab Duo CLI.

##### Créer un répertoire pour les skills au niveau de l'utilisateur {#create-a-directory-for-user-level-skills}

Vous pouvez créer un répertoire de skills dans l'un des emplacements suivants :

- Pour conserver vos skills avec vos autres fichiers de personnalisation GitLab Duo :
  - Pour Linux ou macOS, créez un répertoire à l'emplacement `~/.gitlab/duo/skills/`.
  - Pour Windows, créez un répertoire à l'emplacement `%APPDATA%\GitLab\duo\skills\`.
  - Si vous avez défini `GLAB_CONFIG_DIR` ou `XDG_CONFIG_HOME`, utilisez `$GLAB_CONFIG_DIR/skills/` ou `$XDG_CONFIG_HOME/gitlab/duo/skills/`. Si les deux sont définis, `GLAB_CONFIG_DIR` est prioritaire.
- Pour partager des skills avec d'autres outils d'IA prenant en charge la spécification Agent Skills :
  - Pour Linux ou macOS, créez un répertoire à l'emplacement `~/.agents/skills/`.
  - Pour Windows, créez un répertoire à l'emplacement `%USERPROFILE%\.agents\skills\`.

##### Créer un fichier de skill au niveau de l'utilisateur {#create-a-user-level-skill-file}

Pour créer une skill au niveau de l'utilisateur :

1. Activez les skills globales lors du démarrage du GitLab Duo CLI :

   {{< tabs >}}

   {{< tab title="glab" >}}

   ```shell
   glab duo cli --enable-global-skills
   ```

   {{< /tab >}}

   {{< tab title="duo" >}}

   ```shell
   duo --enable-global-skills
   ```

   {{< /tab >}}

   {{< /tabs >}}

   Vous pouvez également définir la variable d'environnement :

   ```shell
   export GITLAB_ENABLE_GLOBAL_SKILLS=true
   ```

1. Dans votre répertoire `skills`, créez un autre répertoire pour la skill spécifique. Utilisez le nom de la skill comme nom de répertoire. Par exemple, `~/.gitlab/duo/skills/<skill_name>/`.
1. Créez un fichier `SKILL.md` et incluez des instructions en utilisant le format suivant. Les champs d'en-tête YAML `name` et `description` sont obligatoires.

   ```markdown
   ---
   name: <skill_name>
   description: <skill_description>
   ---

   <your_instructions_and_context_for_the_skill>
   ```

1. Démarrez une nouvelle conversation. La skill est disponible dans n'importe quel projet.

#### Exposer les skills comme commandes slash {#expose-skills-as-slash-commands}

Pour activer une skill en tant que commande slash personnalisée, ajoutez `slash-command: enabled` aux métadonnées dans l'en-tête YAML de votre fichier `SKILL.md` :

```yaml
---
name: <skill_name>
description: <skill_description>
metadata:
  slash-command: enabled
---
```

Après avoir ajouté les métadonnées, vous pouvez utiliser `/<skill_name>` dans les nouvelles sessions pour demander à GitLab Duo d'utiliser la skill. Par exemple, `/fix-bugs`.

### Utiliser les skills manuellement {#use-skills-manually}

Pour demander à GitLab Duo d'utiliser une skill spécifique, utilisez l'une des méthodes suivantes :

- Demandez à GitLab Duo d'utiliser la skill par son nom ou son chemin de fichier dans votre invite.
- Commencez votre invite par la commande slash correspondant à la skill.

Pour lister toutes les skills disponibles dans le contexte de la session en cours, utilisez `/skills`.

## Sujets connexes {#related-topics}

- [Règles personnalisées](custom_rules.md)
