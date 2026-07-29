---
stage: AI-powered
group: AI Coding
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "Personnalisez les instructions destinées à l'IA pour les utiliser dans les revues de merge request."
title: "Personnaliser les instructions de revue pour l'Agent Platform"
---

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Introduction](https://gitlab.com/gitlab-org/gitlab/-/issues/545136) dans GitLab 18.2 en tant que [version bêta](../../../policy/development_stages_support.md#beta) [avec un feature flag](../../../administration/feature_flags/_index.md) nommé `duo_code_review_custom_instructions`. Désactivés par défaut.
- Le feature flag `duo_code_review_custom_instructions` [activé par défaut](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/199802) dans GitLab 18.3.
- Feature flag `duo_code_review_custom_instructions` [supprimé](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/202262) dans GitLab 18.4.
- [Introduction](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/237952) des modèles d'union (par exemple, `{rb,ts}`) dans `fileFilters` dans GitLab 19.1.

{{< /history >}}

Créez des instructions de revue personnalisées pour fournir des normes que GitLab Duo peut utiliser comme référence lors de la revue des merge requests.

Par exemple, vous pouvez guider GitLab Duo pour qu'il se concentre sur les conventions de style Ruby pour les fichiers Ruby, et sur les conventions de style Go pour les fichiers Go.

> [!note]
> Les instructions de revue personnalisées sont des conseils à destination du relecteur IA, et non des politiques appliquées. GitLab Duo les utilise comme contexte pour orienter sa revue, mais ne peut pas garantir que chaque instruction est appliquée dans tous les cas. Ne vous fiez pas aux instructions personnalisées pour les contrôles de sécurité, les obligations de conformité ou d'autres exigences nécessitant une application cohérente.

GitLab Duo ajoute vos instructions de revue personnalisées à ses critères de revue standard, au lieu de les remplacer.

Le flow Code Review prend en charge les instructions de revue personnalisées pour un projet, un groupe ou une instance.

## Configurer des instructions de revue personnalisées pour un projet {#configure-custom-review-instructions-for-a-project}

Pour configurer des instructions de revue de merge request personnalisées :

1. À la racine de votre dépôt, créez un répertoire `.gitlab/duo` s'il n'existe pas déjà.
1. Dans le répertoire `.gitlab/duo`, créez un fichier nommé `mr-review-instructions.yaml`.
1. Ajoutez vos instructions personnalisées au format suivant :

   ```yaml
   instructions:
     - name: <instruction_group_name>
       fileFilters:
         - <glob_pattern_1>
         - <glob_pattern_2>
         - !<exclude_pattern>  # Exclude files matching this pattern
       instructions: |
         <your_custom_review_instructions>
   ```

   La section `fileFilters` est facultative. Utilisez des modèles glob dans cette section pour cibler l'instruction sur des fichiers spécifiques. Si vous omettez `fileFilters` ou le laissez vide, GitLab Duo applique l'instruction à chaque fichier de la merge request.

   Par exemple :

   ```yaml
   instructions:
     - name: Ruby Style Guide
       fileFilters:
         - "*.rb"           # Ruby files in the root directory
         - "lib/**/*.rb"    # Ruby files in lib and its subdirectories
         - "!spec/**/*.rb"  # Exclude test files
       instructions: |
         1. Ensure all methods have proper documentation
         2. Follow Ruby style guide conventions
         3. Prefer symbols over strings for hash keys

     - name: TypeScript Source Files
       fileFilters:
         - "**/*.ts"        # Typescript files in any directory
         - "!**/*.test.ts"  # Exclude test files
         - "!**/*.spec.ts"  # Exclude spec files
       instructions: |
         1. Ensure proper TypeScript types (avoid 'any')
         2. Follow naming conventions
         3. Document complex functions

     - name: All Files Except Tests
       fileFilters:
         - "!**/*.test.*"   # Exclude all test files
         - "!**/*.spec.*"   # Exclude all spec files
         - "!test/**/*"     # Exclude test directories
         - "!spec/**/*"     # Exclude spec directories
       instructions: |
         1. Follow consistent code style
         2. Add meaningful comments for complex logic
         3. Ensure proper error handling

     - name: Test Coverage
       fileFilters:
         - "spec/**/*_spec.rb" # Ruby test files in spec directory
       instructions: |
         1. Test both happy paths and edge cases
         2. Include error scenarios
         3. Use shared examples to reduce duplication

     - name: Database Migrations
       fileFilters:
         - "db/migrate/**/*.rb"
         - "db/post_migrate/**/*.rb"
       instructions: |
         1. Follow the migration safety guidelines in
            https://gitlab.com/gitlab-org/gitlab/-/blob/master/doc/development/database/avoiding_downtime_in_migrations.md
         2. Apply the team checklist in docs/migrations-checklist.md

     - name: All Files
       fileFilters:
         - "**/*"   # All files in the repository
       instructions: |
         1. Explain the "why" behind each suggestion
   ```

   Pour plus de détails sur le référencement de fichiers dans les instructions, voir [référencer des fichiers dans les instructions](#reference-files-in-instructions).

   Pour des exemples de syntaxe glob, consultez la [référence des modèles de fichiers](#file-pattern-reference).

1. Facultatif : ajoutez une entrée [Propriétaires du code](../../project/codeowners/_index.md) pour protéger les modifications apportées au fichier `mr-review-instructions.yaml`.

   ```markdown
   [GitLab Duo]
   .gitlab/duo @default-owner @tech-lead
   ```

1. [Créez une merge request](../../project/merge_requests/creating_merge_requests.md) pour réviser et fusionner les modifications :

   - GitLab Duo applique automatiquement vos instructions personnalisées lorsque les modèles de fichiers correspondent.
   - Plusieurs groupes d'instructions peuvent s'appliquer à un seul fichier. Lorsqu'un fichier correspond au `fileFilters` de plus d'un groupe, le flow Code Review applique les instructions de chaque groupe correspondant.
   - Pour les commentaires de revue déclenchés par vos instructions personnalisées, GitLab Duo utilise ce format :

     ```plaintext
     According to custom instructions in '[instruction_name]': [feedback comments]
     ```

     La valeur `instruction_name` correspond à la propriété `name` de votre fichier `.gitlab/duo/mr-review-instructions.yaml`. Les commentaires standard de GitLab Duo n'utilisent pas ce format.
     <br><br>
     Si GitLab Duo ne trouve aucun problème, il laisse un commentaire récapitulatif de la revue. Les instructions personnalisées ne s'appliquent pas à ce commentaire récapitulatif.
1. Facultatif :
   - Passez en revue les commentaires et affinez vos instructions si nécessaire.
   - Testez les modèles pour vous assurer qu'ils correspondent aux fichiers prévus.

## Configurer des instructions de revue personnalisées pour un groupe {#configure-custom-review-instructions-for-a-group}

{{< history >}}

- [Introduction](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/230090) dans GitLab 19.0.

{{< /history >}}

Vous pouvez définir des instructions de revue personnalisées pour un groupe en spécifiant un projet à utiliser comme modèle. Le projet modèle doit contenir un fichier `.gitlab/duo/mr-review-instructions.yaml` avec des instructions de revue qui s'appliquent à tous les projets du groupe et de ses sous-groupes.

Lorsque GitLab Duo effectue une revue de code, il combine les instructions du groupe principal avec les instructions définies dans le projet individuel.

Prérequis :

- Le rôle Propriétaire pour le groupe principal.
- Un projet du groupe contient les instructions de revue personnalisées que vous souhaitez utiliser comme modèle.

Pour configurer des instructions de revue personnalisées pour un groupe :

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à** et trouvez votre groupe principal.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Général** > **Fonctionnalités de GitLab Duo**.
1. Sous **Customize code review**, sélectionnez le projet qui contient le fichier `.gitlab/duo/mr-review-instructions.yaml` avec les instructions de revue de votre groupe.
1. Sélectionnez **Enregistrer les modifications**.

## Configurer des instructions de revue personnalisées pour une instance {#configure-custom-review-instructions-for-an-instance}

{{< details >}}

- Offre : GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Introduction](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/237573) dans GitLab 19.1.

{{< /history >}}

Sur GitLab Self-Managed et GitLab Dedicated, vous pouvez définir des instructions de revue personnalisées à l'échelle de l'instance en spécifiant un projet à utiliser comme modèle. Le projet modèle doit contenir un fichier `.gitlab/duo/mr-review-instructions.yaml` avec des instructions de revue qui s'appliquent à chaque projet de l'instance.

Lorsque GitLab Duo effectue une revue de code, il combine les instructions de l'instance avec les instructions du groupe et du projet.

Prérequis :

- Accès administrateur pour l'instance.
- Un projet sur l'instance contient les instructions de revue personnalisées que vous souhaitez utiliser comme modèle.

Pour configurer des instructions de revue personnalisées pour une instance :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **GitLab Duo**.
1. Sélectionnez **Modifier la configuration**.
1. Sous **Customize code review for all groups in this instance**, sélectionnez le projet qui contient le fichier `.gitlab/duo/mr-review-instructions.yaml` avec vos instructions de revue.
1. Sélectionnez **Enregistrer les modifications**.

## Référencer des fichiers dans les instructions {#reference-files-in-instructions}

Vous pouvez référencer d'autres fichiers dans des instructions personnalisées au lieu de dupliquer le contenu. Le flow Code Review lit les fichiers référencés lors de l'étape de pré-analyse et en extrait les conseils pertinents.

Les instructions personnalisées prennent en charge deux modèles de référence de fichiers :

- Fichiers dans le même projet que la merge request : utilisez un chemin relatif au dépôt, tel que `docs/security-checklist.md`.
- Fichiers dans d'autres projets sur la même instance GitLab : utilisez une URL blob GitLab complète, telle que `https://gitlab.example.com/group/project/-/blob/main/docs/style-guide.md`. L'URL doit pointer vers la même instance GitLab que la merge request et doit utiliser le format `/-/blob/<ref>/<path>`.

Par exemple :

```yaml
instructions:
  - name: Database Migrations
    fileFilters:
      - "db/migrate/**/*.rb"
    instructions: |
      1. Follow the migration guidelines in
         https://gitlab.com/gitlab-org/gitlab/-/blob/master/doc/development/database/avoiding_downtime_in_migrations.md
      2. Reference the team checklist in docs/db-checklist.md
```

### Limites des références de fichiers {#limitations-of-file-references}

La résolution des références de fichiers présente les contraintes suivantes :

- Même instance GitLab uniquement. Les URL pointant vers une instance GitLab différente, vers GitLab public depuis une instance GitLab Self-Managed, ou vers tout site non-GitLab, tel que Confluence ou un site de documentation public, ne sont pas récupérées.
- URL blob uniquement, au format `/-/blob/<ref>/<path>`. Les pages wiki, les tickets, les URL brutes et les extraits de code ne sont pas récupérés.
- Même projet pour les chemins nus. Un chemin nu tel que `docs/security.md` est résolu par rapport au même projet que la merge request. Utilisez une URL blob GitLab complète pour référencer un fichier dans un projet différent.
- Meilleur effort, sans garantie. Le flow Code Review détermine les références à récupérer en fonction du texte de l'instruction. Une référence qui échoue à se résoudre, comme un chemin qui n'existe pas ou une URL rejetée par l'analyseur, est ignorée silencieusement.
- Le flow Code Review utilise un résumé, et non le fichier original. Il résume le contenu récupéré lors de l'étape de pré-analyse et utilise le résumé lors de la revue. Deux revues de la même merge request peuvent produire des résumés différents.

Si vous souhaitez que le flow Code Review utilise le contenu exact du fichier et non un résumé, incluez-le directement dans le champ `instructions:` au lieu de référencer le fichier. Les instructions intégrées sont utilisées telles qu'elles sont rédigées.

## Bonnes pratiques {#best-practices}

Lors de la rédaction d'instructions de revue personnalisées :

- Soyez spécifique et concret. Le flow Code Review vérifie chaque règle par rapport au diff. Par exemple, une règle concrète comme « vérifier que les méthodes publiques ont une documentation YARD » produit des commentaires utiles, mais des conseils abstraits comme « bien documenter votre code » n'en produisent pas.
- Numérotez vos instructions pour plus de clarté.
- Concentrez-vous sur les normes les plus importantes. Le texte de chaque règle fait partie de l'invite de revue. Ainsi, de longues listes de règles peu utiles alourdissent l'invite sans apporter de valeur supplémentaire.
- Expliquez le « pourquoi » lorsque cela est utile.
- Commencez par des instructions simples, puis ajoutez de la complexité si nécessaire.
- Concentrez-vous sur les normes spécifiques au projet que le flow Code Review n'appliquerait pas par défaut. Les instructions personnalisées s'ajoutent aux critères de revue standard au lieu de les remplacer. Les conseils généraux comme « ajouter la gestion des erreurs » ou « utiliser des noms significatifs » sont généralement déjà couverts. Utilisez des instructions personnalisées pour ce que seul votre projet connaît : les API internes, les conventions architecturales, les modèles spécifiques au domaine.
- Rédigez les instructions comme des conseils, non comme des obligations. Les instructions sont des indications qui orientent le comportement de la revue, et non des politiques que GitLab Duo est tenu de suivre. Évitez les formulations comme « toujours signaler » ou « ne jamais autoriser ». Ce type de formulation peut induire les collaborateurs en erreur en leur faisant croire que le comportement est garanti.
- Faites en sorte que les modèles de fichiers reflètent la portée réelle de la règle. Le flow Code Review lit chaque instruction en regard de chaque référence `fileFilters` et applique la règle uniquement aux fichiers correspondant à ces modèles. Par exemple, une règle pour « les contrôleurs Rails » dont la portée est limitée à `**/*.rb` s'appliquera aux gems, scripts et tests, et pas seulement aux contrôleurs. Utilisez plutôt `app/controllers/**/*.rb`.
- N'utilisez les références de fichiers externes que pour les instructions où la formulation exacte n'a pas d'importance ; sinon, incluez les détails directement comme règle dans le champ `instructions:`. Le flow Code Review génère et utilise des résumés pour les fichiers référencés, mais utilise la formulation exacte définie dans `instructions`.

Par exemple :

```yaml
instructions: |
  1. All public functions must include docstrings with parameter descriptions
  2. Use parameterized queries to prevent SQL injection
  3. Validate user input before processing (check type, length, format)
  4. Include error handling for all external API calls
  5. Avoid hardcoded credentials - use environment variables
```

Pour des exemples spécifiques à un langage, consultez les [exemples de cas d'utilisation](#use-case-examples).

## Référence des modèles de fichiers {#file-pattern-reference}

Utilisez des modèles glob dans `fileFilters` pour cibler des fichiers spécifiques.

Par exemple, pour un projet contenant des fichiers Ruby :

| Modèle | Correspondance |
| --- | --- |
| `**/*.rb`       | Tous les fichiers Ruby dans n'importe quel répertoire |
| `*.rb`          | Fichiers Ruby dans le répertoire racine uniquement |
| `lib/**/*.rb`   | Fichiers Ruby dans le répertoire `lib` et ses sous-répertoires |
| `!**/*.test.rb` | Exclure tous les fichiers de test Ruby |
| `!spec/**/*.rb` | Exclure tous les fichiers Ruby dans le répertoire `spec` et ses sous-répertoires |
| `!tests/**/*`   | Exclure tous les fichiers dans le répertoire `tests` et ses sous-répertoires |
| `**/*.{js,jsx}` | Fichiers JavaScript et JSX dans tous les répertoires (GitLab 19.1 et versions ultérieures) |

L'exemple suivant montre la différence entre `**/*.rb` et `*.rb` :

```plaintext
project/
├── app.rb              ← matched by both *.rb and **/*.rb
├── lib/
│   └── helper.rb       ← matched only by **/*.rb
└── app/
    └── models/
        └── user.rb     ← matched only by **/*.rb
```

- `*.rb` ne correspond qu'à app.rb
- `**/*.rb` correspond aux trois fichiers

Pour le fichier `mr-review-instructions.yaml`, `**/*.rb` garantit que les instructions de revue s'appliquent aux fichiers Ruby n'importe où dans la structure du projet, pas seulement dans le répertoire racine.

## Exemples de cas d'utilisation {#use-case-examples}

<!-- 2025-11-12 Use case examples are maintained by DevRel, @dnsmichi
Inspired by the reference in <https://gitlab.com/gitlab-da/use-cases/ai/gitlab-duo-agent-platform/demo-environments/tanuki-iot-platform/-/blob/main/.gitlab/duo/mr-review-instructions.yaml?ref_type=heads>
-->

{{< tabs >}}

{{< tab title="Assembly" >}}

```yaml
instructions:
  - name: Assembly Style Guide
    fileFilters:
      - "**/*.asm"
      - "**/*.s"
      - "**/*.S"
    instructions: |
      1. Document the target architecture (x86-64, ARM, RISC-V, AVR, etc.) at the top
      2. Use meaningful labels and comment all non-obvious instructions
      3. Document register usage and calling conventions
      4. Align code sections properly for readability
      5. Include memory layout and stack usage documentation
```

{{< /tab >}}

{{< tab title="C" >}}

```yaml
instructions:
  - name: C Style Guide
    fileFilters:
      - "**/*.c"
      - "**/*.h"
    instructions: |
      1. goto is not allowed
      2. Avoid using global variables
      3. Use meaningful variable names
      4. Add comments for complex logic
```

{{< /tab >}}

{{< tab title="C++" >}}

```yaml
instructions:
  - name: C++ Style Guide
    fileFilters:
      - "**/*.cpp"
      - "**/*.{h,hpp}"
    instructions: |
      1. Ensure all methods have proper documentation
      2. Use smart pointers for dynamic memory management
      3. Avoid raw pointers
```

{{< /tab >}}

{{< tab title="C#" >}}

```yaml
instructions:
  - name: C# Style Guide
    fileFilters:
      - "**/*.cs"
    instructions: |
      1. Follow Microsoft C# coding conventions
      2. Use XML documentation comments for public APIs
      3. Prefer async/await for asynchronous operations
      4. Use nullable reference types appropriately
      5. Follow .NET naming conventions (PascalCase for public members)
```

{{< /tab >}}

{{< tab title="COBOL" >}}

```yaml
instructions:
  - name: COBOL Style Guide
    fileFilters:
      - "**/*.CBL"
      - "**/*.cbl"
      - "**/*.COB"
      - "**/*.cob"
    instructions: |
      1. Use clear and meaningful names for variables and procedures
      2. Prefer COBOL-85 syntax where possible
      3. Use proper division structure (IDENTIFICATION, ENVIRONMENT, DATA, PROCEDURE)
      4. Document all paragraphs and sections with meaningful comments
      5. Use 88-level condition names for boolean flags and status codes
      6. Avoid GO TO statements, prefer PERFORM for structured programming
      7. Use proper error handling with declaratives or status code checking
      8. Define working storage variables with appropriate PICTURE clauses
      9. Use meaningful paragraph names that describe the operation
      10. For mainframe integration, document JCL dependencies and file layouts
```

{{< /tab >}}

{{< tab title="Go" >}}

```yaml
instructions:
  - name: Go Style Guide
    fileFilters:
      - "**/*.go"
    instructions: |
      1. Use idiomatic Go practices
      2. Ensure all public functions and types have documentation
      3. Prefer standard library packages over third-party ones when possible
```

{{< /tab >}}

{{< tab title="Java" >}}

```yaml
instructions:
  - name: Java Style Guide
    fileFilters:
      - "**/*.java"
    instructions: |
      1. Do not modernize Java 8 code to Java 11+ features, unless there is a GitLab issue or task specifically requesting modernization
      2. All public classes must have Javadoc describing purpose and usage
      3. All public methods must have Javadoc with @param and @return tags
      4. Include code examples in main class Javadoc
      5. All public methods must have at least one test case
```

{{< /tab >}}

{{< tab title="JavaScript/TypeScript" >}}

```yaml
instructions:
  - name: JavaScript/TypeScript Files
    fileFilters:
      - "src/**/*.js"
      - "src/**/*.jsx"
      - "src/**/*.ts"
      - "src/**/*.tsx"
      - "!**/*.test.js"
      - "!**/*.test.ts"
      - "!**/*.spec.js"
      - "!**/*.spec.ts"
    instructions: |
      1. Use const/let instead of var
      2. Prefer async/await over promise chains
      3. Add JSDoc comments for complex functions
      4. Ensure proper error handling in async code
      5. Avoid any 'any' types in TypeScript
```

{{< /tab >}}

{{< tab title="Kotlin" >}}

```yaml
instructions:
  - name: Kotlin Style Guide
    fileFilters:
      - "**/*.kt"
      - "**/*.kts"
    instructions: |
      1. Follow Kotlin coding conventions
      2. Prefer immutability (val over var)
      3. Use coroutines for asynchronous operations
      4. Leverage Kotlin's null safety features
      5. Document public APIs with KDoc
```

{{< /tab >}}

{{< tab title="MATLAB" >}}

```yaml
instructions:
  - name: MATLAB Style Guide
    fileFilters:
      - "**/*.m"
    instructions: |
      1. Use descriptive variable and function names with camelCase convention
      2. Vectorize operations instead of using loops where possible
      3. Document functions with H1 line and help text comments
      4. Preallocate arrays before loops to improve performance
      5. Use proper error handling with try-catch blocks and error() function
```

{{< /tab >}}

{{< tab title="Perl" >}}

```yaml
instructions:
  - name: Perl Style Guide
    fileFilters:
      - "**/*.pl"
      - "**/*.pm"
    instructions: |
      1. Follow idiomatic Perl practices
      2. Ensure proper module documentation
      3. Use strict and warnings pragmas
```

{{< /tab >}}

{{< tab title="PHP" >}}

```yaml
instructions:
  - name: PHP Style Guide
    fileFilters:
      - "**/*.php"
    instructions: |
      1. Follow PSR-12 coding standard
      2. Use type declarations for function parameters and return types
      3. Ensure compatibility with PHP 8+
      4. Use proper error handling and exceptions
      5. Document classes and methods with PHPDoc
```

{{< /tab >}}

{{< tab title="Python" >}}

```yaml
instructions:
  - name: Python Source Files
    fileFilters:
      - "**/*.py"
      - "!tests/**/*.py"
      - "!test_*.py"
    instructions: |
      1. All functions must have docstrings with parameters and return types
      2. Use type hints for function signatures
      3. Follow PEP 8 style conventions
      4. Ensure proper exception handling
      5. Avoid using bare 'except' clauses

  - name: Python Tests
    fileFilters:
      - "tests/**/*.py"
      - "test_*.py"
    instructions: |
      1. Use pytest fixtures for common setup
      2. Test names should clearly describe the scenario being tested
      3. Include assertions for both expected outcomes and edge cases
      4. Mock external dependencies appropriately
```

{{< /tab >}}

{{< tab title="Ruby" >}}

```yaml
instructions:
  - name: Ruby Style Guide
    fileFilters:
      - "*.rb"
      - "lib/**/*.rb"
      - "!spec/**/*.rb"  # Exclude test files
    instructions: |
      1. Follow Ruby style guide conventions
      2. Prefer symbols over strings for hash keys
      3. Use snake_case for methods/variables, SCREAMING_SNAKE_CASE for constants, CamelCase for classes
      4. Prefer Ruby 3.0+ features (pattern matching, endless methods) where appropriate
      5. Use proper error handling - raise exceptions over returning nil for errors
      6. Write idiomatic Ruby - use blocks, enumerables, and Ruby idioms over procedural patterns
      7. Use meaningful method names - use ? for predicates, ! for dangerous methods
      8. Prefer keyword arguments for methods with multiple parameters
      9. All public methods should have corresponding RSpec/Minitest tests
      10. Manage dependencies with Gemfile and ensure version compatibility
      11. Document thread-safe code and use proper synchronization for concurrent operations
      12. Handle signals (SIGTERM, SIGINT) properly for daemon processes
```

{{< /tab >}}

{{< tab title="R" >}}

```yaml
instructions:
  - name: R Style Guide
    fileFilters:
      - "**/*.r"
      - "**/*.R"
    instructions: |
      1. Follow tidyverse style guide conventions
      2. Use snake_case for variable and function names
      3. Document functions with roxygen2 comments
      4. Prefer vectorized operations over loops
      5. Use proper error handling with tryCatch and stop()
```

{{< /tab >}}

{{< tab title="Rust" >}}

```yaml
instructions:
  - name: Rust Style Guide
    fileFilters:
      - "**/*.rs"
    instructions: |
      1. Follow Rust idioms and conventions
      2. Use proper error handling with Result and Option types
      3. Avoid unsafe code unless absolutely necessary and well-documented
      4. Ensure all public items have documentation comments
```

{{< /tab >}}

{{< tab title="Scala" >}}

```yaml
instructions:
  - name: Scala Style Guide
    fileFilters:
      - "**/*.scala"
    instructions: |
      1. Follow Scala style guide conventions
      2. Prefer immutable data structures (val over var)
      3. Use pattern matching effectively for control flow
      4. Document public APIs with ScalaDoc
      5. Use proper error handling with Try, Either, or Option types
```

{{< /tab >}}

{{< tab title="Shell" >}}

```yaml
instructions:
  - name: Shell Script Style Guide
    fileFilters:
      - "**/*.sh"
      - "**/*.bash"
      - "**/*.zsh"
      - "**/*.ksh"
    instructions: |
      1. Always quote variables to prevent word splitting ("$var" not $var)
      2. Use proper error handling with set -euo pipefail at script start
      3. Document script purpose, parameters, and exit codes in header comments
      4. Prefer [[ ]] over [ ] for conditional tests
      5. Use meaningful function names and avoid complex one-liners
```

{{< /tab >}}

{{< tab title="SQL" >}}

```yaml
instructions:
  - name: SQL Style Guide
    fileFilters:
      - "**/*.sql"
    instructions: |
      1. Use uppercase for SQL keywords (SELECT, FROM, WHERE, JOIN)
      2. Always specify column names explicitly instead of using SELECT *
      3. For PostgreSQL use SERIAL/RETURNING, for MySQL use AUTO_INCREMENT, for Oracle use SEQUENCE
      4. For NoSQL (MongoDB) use proper indexing and aggregation pipelines to avoid N+1 queries
      5. Document database-specific features and expected performance characteristics
      6. Use proper indentation for complex queries and subqueries
```

{{< /tab >}}

{{< tab title="VHDL" >}}

```yaml
instructions:
  - name: VHDL Style Guide
    fileFilters:
      - "**/*.vhd"
      - "**/*.vhdl"
    instructions: |
      1. Follow IEEE VHDL coding standards
      2. Use meaningful signal and entity names with clear prefixes
      3. Document all entities, architectures, and processes with comments
      4. Use synchronous design practices with proper clock and reset handling
      5. Avoid combinational loops and ensure proper timing constraints
```

{{< /tab >}}

{{< tab title="Fichiers de configuration" >}}

```yaml
instructions:
  - name: Configuration Files
    fileFilters:
      - "*.yaml"
      - "*.yml"
      - "*.json"
      - "config/**/*"
      - "!.gitlab/**/*"
    instructions: |
      1. Do not include sensitive data (passwords, API keys)
      2. Use environment variables for environment-specific values
      3. Document all configuration options
      4. Validate configuration schema if possible
```

{{< /tab >}}

{{< tab title="Infrastructure as Code" >}}

```yaml
instructions:
  - name: Ansible Style Guide
    fileFilters:
      - "*.yaml"
      - "*.yml"
      - "playbooks/**/*.yaml"
      - "roles/**/*.yaml"
    instructions: |
      1. Use meaningful play and task names that describe the action
      2. Prefer modules over shell/command tasks when possible
      3. Use variables and defaults for reusability across environments
      4. Implement idempotency - tasks should be safe to run multiple times
      5. Use handlers for service restarts and notifications
      6. Document playbook purpose, required variables, and dependencies

  - name: Dockerfile Style Guide
    fileFilters:
      - "Dockerfile"
      - "*.dockerfile"
      - "Dockerfile.*"
    instructions: |
      1. Use specific base image tags, avoid 'latest'
      2. Minimize layers by combining RUN commands with && where logical
      3. Use multi-stage builds to reduce final image size
      4. Run containers as non-root user for security
      5. Use .dockerignore to exclude unnecessary files
      6. Document exposed ports, volumes, and environment variables

  - name: GitLab CI/CD Style Guide
    fileFilters:
      - ".gitlab-ci.yml"
      - "**/.gitlab-ci.yml"
    instructions: |
      1. Use job extends instead of YAML anchors for reusability
      2. Always use rules instead of only/except for job conditions
      3. Define appropriate caching strategies for dependencies
      4. Use stages to organize pipeline workflow logically
      5. Include security scanning templates (SAST, dependency scanning, secret detection)
      6. Document job purpose, required variables, and dependencies in comments

  - name: Helm Chart Style Guide
    fileFilters:
      - "Chart.yaml"
      - "values.yaml"
      - "templates/**/*.yaml"
    instructions: |
      1. Use semantic versioning for chart versions
      2. Provide sensible defaults in values.yaml with comments
      3. Use template functions for conditional logic and loops
      4. Include NOTES.txt with post-installation instructions
      5. Validate charts with helm lint before committing
      6. Document all configurable values and their purpose

  - name: Kubernetes Style Guide
    fileFilters:
      - "*.yaml"
      - "*.yml"
      - "k8s/**/*.yaml"
      - "kubernetes/**/*.yaml"
    instructions: |
      1. Use explicit API versions and avoid deprecated APIs
      2. Always define resource limits and requests for containers
      3. Use namespaces to organize resources logically
      4. Define liveness and readiness probes for all deployments
      5. Use ConfigMaps and Secrets instead of hardcoded values
      6. Document resource purpose and dependencies in metadata annotations

  - name: Terraform/OpenTofu Style Guide
    fileFilters:
      - "*.tf"
      - "*.tfvars"
    instructions: |
      1. Use consistent naming conventions for resources (environment_service_resource)
      2. Organize code into modules for reusability
      3. Use variables with descriptions and validation rules
      4. Define outputs for important resource attributes
      5. Use remote state with locking for team collaboration
      6. Document module purpose, inputs, outputs, and provider requirements
```

{{< /tab >}}

{{< /tabs >}}

### Exemples de projets {#example-projects}

Pour plus de cas d'utilisation d'instructions de revue personnalisées, consultez les exemples de production suivants :

- [Développement GitLab dans `gitlab-org/gitlab`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/.gitlab/duo/mr-review-instructions.yaml)
- [Manuel GitLab](https://gitlab.com/gitlab-com/content-sites/handbook/-/blob/main/.gitlab/duo/mr-review-instructions.yaml)
- [Site web GitLab](https://gitlab.com/gitlab-com/marketing/digital-experience/about-gitlab-com/-/blob/main/.gitlab/duo/mr-review-instructions.yaml)
- [Developer Advocacy : Tanuki IoT Platform](https://gitlab.com/gitlab-da/use-cases/ai/gitlab-duo-agent-platform/demo-environments/tanuki-iot-platform/-/blob/main/.gitlab/duo/mr-review-instructions.yaml)

## Dépannage {#troubleshooting}

Lorsque vous travaillez avec `mr-review-instructions.yaml`, vous pouvez rencontrer les problèmes suivants.

### Le flow Code Review ignore les instructions ou renvoie une revue générique {#code-review-flow-skips-instructions-or-returns-a-generic-review}

Si le flow Code Review ignore vos instructions personnalisées ou renvoie une revue générique, le fichier présente peut-être un problème de structure. Utilisez le linter d'instructions personnalisées pour identifier les problèmes éventuels.

#### Exécuter le linter d'instructions personnalisées {#run-the-custom-instructions-linter}

Le linter d'instructions personnalisées vous aide à valider votre fichier `mr-review-instructions.yaml`.

Le linter vérifie :

- La syntaxe YAML invalide.
- Les clés de niveau supérieur manquantes ou inattendues.
- Les champs obligatoires manquants ou vides (`name`, `instructions`).
- Les clés inconnues dans une entrée d'instruction, telles que `rules` au lieu de `instructions`.
- Les valeurs `fileFilters` qui ne sont pas des listes ou qui contiennent des entrées non textuelles ou vides.
- La valeur `fileFilters` manquante ou vide, ce qui entraîne l'application de l'instruction à chaque fichier (info).
- Les valeurs `name` dupliquées dans les entrées d'instruction.

> [!note]
> Le linter lit uniquement le fichier et ne le modifie pas. Il n'a aucune dépendance envers GitLab ou Rails et s'exécute sur tout environnement où Ruby est installé.

Prérequis :

- Ruby 3.0 ou version ultérieure.

Pour exécuter le linter en tant que tâche Rake sur un serveur GitLab, remplacez `<path>` par le chemin d'accès à votre fichier `mr-review-instructions.yaml`. Par exemple :

```shell
sudo gitlab-rake "gitlab:duo:lint_review_instructions[<path>]"
```

Pour exécuter le linter en tant que script autonome sur toute machine où Ruby est installé :

1. Téléchargez [`review_instructions_linter.rb`](https://gitlab.com/gitlab-org/gitlab/-/raw/master/ee/lib/gitlab/duo/administration/review_instructions_linter.rb).
1. Exécutez le linter. Remplacez `<path>` par le chemin d'accès à votre fichier `mr-review-instructions.yaml`.

   ```shell
   ruby -r ./review_instructions_linter.rb -e '
     linter = Gitlab::Duo::Administration::ReviewInstructionsLinter.new(ARGV[0]).run
     linter.issues.each { |issue| puts issue }
     exit(linter.valid? ? 0 : 1)
   ' <path>
   ```

Si vous omettez le chemin, le linter utilise par défaut `.gitlab/duo/mr-review-instructions.yaml` dans le répertoire de travail. Le linter se termine avec le statut `0` si aucune erreur n'est trouvée, ou `1` dans le cas contraire. Les avertissements et les messages d'information n'entraînent pas une sortie non nulle.

Par exemple, ce fichier invalide utilise `rules` au lieu de `instructions` et omet `fileFilters` :

```yaml
instructions:
  - name: "General"
    rules: "Do something"
```

Le linter rapporte :

```plaintext
[ERROR E009] Field 'instructions' must be a non-empty string at instructions[0]
[WARNING W003] Unknown keys: "rules"; expected name, instructions, fileFilters at instructions[0]
[INFO I001] Missing 'fileFilters'; the instruction applies to every file at instructions[0]
```

Corrigez les erreurs signalées et réexécutez le linter jusqu'à ce qu'il ne signale plus aucune erreur.

#### Codes de message du linter {#linter-message-codes}

Chaque message inclut un code stable auquel vous pouvez vous référer lorsque vous demandez de l'aide. Les codes commençant par `E` sont des erreurs, les codes commençant par `W` sont des avertissements, et les codes commençant par `I` sont des notes informatives sur un comportement valide mais méritant d'être connu.

| Code | Description |
| ---- | ----------- |
| `E001` | Le fichier n'existe pas au chemin indiqué. |
| `E003` | Le fichier contient une syntaxe YAML invalide. |
| `E004` | La valeur YAML de niveau supérieur n'est pas un mappage. |
| `E005` | La clé `instructions` de niveau supérieur est manquante. |
| `E006` | La valeur `instructions` n'est pas une liste. |
| `E007` | Une entrée sous `instructions` n'est pas un mappage. |
| `E008` | Le champ `name` d'une entrée est manquant, vide ou n'est pas une chaîne de caractères. |
| `E009` | Le champ `instructions` d'une entrée est manquant, vide ou n'est pas une chaîne de caractères. |
| `E011` | La valeur `fileFilters` d'une entrée n'est pas une liste. |
| `E013` | Le champ `fileFilters` d'une entrée contient une valeur non textuelle, comme un nombre. |
| `E014` | Le champ `fileFilters` d'une entrée contient une chaîne vide. |
| `W001` | Le fichier contient une clé de niveau supérieur inconnue. |
| `W002` | La liste `instructions` est vide, donc aucune instruction ne s'applique. |
| `W003` | Une entrée contient des clés autres que `name`, `instructions` et `fileFilters`. |
| `W004` | Deux entrées ou plus partagent le même `name`. |
| `W007` | Le fichier est vide, donc aucune instruction ne s'applique. |
| `I001` | Une entrée ne contient pas le champ `fileFilters`, donc l'instruction s'applique à chaque fichier. |
| `I002` | La liste `fileFilters` d'une entrée est vide, donc l'instruction s'applique à chaque fichier. |

## Sujets connexes {#related-topics}

- [GitLab Duo dans les merge requests](../../project/merge_requests/duo_in_merge_requests.md)
- [Flow Code Review](../flows/foundational_flows/code_review.md)
