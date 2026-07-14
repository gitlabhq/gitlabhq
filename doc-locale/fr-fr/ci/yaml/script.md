---
stage: Verify
group: Pipeline Authoring
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Apprenez à rédiger des sections `script` GitLab CI/CD et à améliorer les job logs avec une syntaxe ou une configuration spéciale.
title: Scripts et job logs
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Vous pouvez utiliser une syntaxe spéciale dans les sections [`script`](_index.md#script) pour :

- [Fractionner les commandes longues](#split-long-commands) en commandes multilignes.
- [Utiliser des codes couleur](#add-color-codes-to-script-output) pour faciliter la révision des job logs.
- [Créez des sections repliables personnalisées](../jobs/job_logs.md#create-custom-collapsible-sections) pour simplifier la sortie du job log.

## Utiliser des caractères spéciaux avec `script` {#use-special-characters-with-script}

Parfois, les commandes `script` doivent être encapsulées dans des guillemets simples ou doubles. Par exemple, les commandes contenant un deux-points (`:`) doivent être encapsulées dans des guillemets simples (`'`). L'analyseur YAML doit interpréter le texte comme une chaîne plutôt que comme une paire « clé : valeur ».

Par exemple, ce script utilise un deux-points :

```yaml
job:
  script:
    - curl --request POST --header 'Content-Type: application/json' "https://gitlab.example.com/api/v4/projects"
```

Pour être considéré comme un YAML valide, vous devez encapsuler la commande entière dans des guillemets simples. Si la commande utilise déjà des guillemets simples, vous devez les remplacer par des guillemets doubles (`"`) si possible :

```yaml
job:
  script:
    - 'curl --request POST --header "Content-Type: application/json" "https://gitlab.example.com/api/v4/projects"'
```

Vous pouvez vérifier que la syntaxe est valide avec l'outil [CI Lint](lint.md).

Soyez également prudent lorsque vous utilisez ces caractères :

- `{`, `}`, `[`, `]`, `,`, `&`, `*`, `#`, `?`, `|`, `-`, `<`, `>`, `=`, `!`, `%`, `@`, `` ` ``.

## Ignorer les codes de sortie non nuls {#ignore-non-zero-exit-codes}

Lorsque des commandes de script renvoient un code de sortie autre que zéro, le job échoue et les commandes suivantes ne s'exécutent pas.

Stockez le code de sortie dans une variable pour éviter ce comportement :

```yaml
job:
  script:
    - exit_code=0
    - false || exit_code=$?
    - if [ $exit_code -ne 0 ]; then echo "Previous command failed"; fi;
```

## Définir un `before_script` ou `after_script` par défaut pour tous les jobs {#set-a-default-before_script-or-after_script-for-all-jobs}

Vous pouvez utiliser [`before_script`](_index.md#before_script) et [`after_script`](_index.md#after_script) avec [`default`](_index.md#default) :

- Utilisez `before_script` avec `default` pour définir un tableau de commandes par défaut qui doivent s'exécuter avant les commandes `script` dans tous les jobs.
- Utilisez `after_script` avec default pour définir un tableau de commandes par défaut qui doivent s'exécuter après la fin ou l'annulation de tout job.

Vous pouvez remplacer une valeur par défaut en en définissant une autre dans un job. Pour ignorer la valeur par défaut, utilisez `before_script: []` ou `after_script: []` :

```yaml
default:
  before_script:
    - echo "Execute this `before_script` in all jobs by default."
  after_script:
    - echo "Execute this `after_script` in all jobs by default."

job1:
  script:
    - echo "These script commands execute after the default `before_script`,"
    - echo "and before the default `after_script`."

job2:
  before_script:
    - echo "Execute this script instead of the default `before_script`."
  script:
    - echo "This script executes after the job's `before_script`,"
    - echo "but the job does not use the default `after_script`."
  after_script: []
```

## Ignorer les commandes `after_script` si un job est annulé {#skip-after_script-commands-if-a-job-is-canceled}

{{< history >}}

- [Introduit](https://gitlab.com/groups/gitlab-org/-/epics/10158) dans GitLab 17.0 [avec un indicateur](../../administration/feature_flags/_index.md) nommé `ci_canceling_status`. Activé par défaut. Nécessite GitLab Runner version 16.11.1.
- [En disponibilité générale](https://gitlab.com/gitlab-org/gitlab/-/issues/460285) dans GitLab 17.3. Le feature flag `ci_canceling_status` a été supprimé.

{{< /history >}}

Les commandes [`after_script`](_index.md) s'exécutent si un job est annulé pendant que la section `before_script` ou `script` de ce job est en cours d'exécution.

Le statut du job dans l'interface utilisateur est `canceling` pendant l'exécution des `after_script`, et passe à `canceled` une fois les commandes `after_script` terminées. La variable prédéfinie `$CI_JOB_STATUS` a la valeur `canceled` pendant l'exécution des commandes `after_script`.

Pour empêcher l'exécution des commandes `after_script` après l'annulation d'un job, configurez la section `after_script` de façon à :

1. Vérifier la variable prédéfinie `$CI_JOB_STATUS` au début de la section `after_script`.
1. Terminer l'exécution prématurément si la valeur est `canceled`.

Par exemple :

```yaml
job1:
  script:
    - my-script.sh
  after_script:
    - if [ "$CI_JOB_STATUS" == "canceled" ]; then exit 0; fi
    - my-after-script.sh
```

## Fractionner les commandes longues {#split-long-commands}

Vous pouvez fractionner les commandes longues en commandes multilignes pour améliorer la lisibilité avec les [indicateurs scalaires de bloc multiligne YAML](https://yaml-multiline.info/) `|` (littéral) et `>` (replié).

> [!warning]
> Si plusieurs commandes sont combinées en une seule chaîne de commandes, seul l'échec ou le succès de la dernière commande est rapporté. [Les échecs des commandes précédentes sont ignorés en raison d'un bug](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/25394). Pour contourner ce problème, exécutez chaque commande en tant qu'élément `script` séparé, ou ajoutez une commande `exit 1` à chaque chaîne de commandes.

Vous pouvez utiliser l'indicateur scalaire de bloc multiligne YAML `|` (littéral) pour écrire des commandes sur plusieurs lignes dans la section `script` d'une description de job. Chaque ligne est traitée comme une commande distincte. Seule la première commande est répétée dans le job log, mais les commandes supplémentaires sont toujours exécutées :

```yaml
job:
  script:
    - |
      echo "First command line."
      echo "Second command line."
      echo "Third command line."
```

L'exemple précédent s'affiche dans le job log comme suit :

```shell
$ echo First command line # collapsed multiline command
First command line
Second command line.
Third command line.
```

L'indicateur scalaire de bloc multiligne YAML `>` (replié) traite les lignes vides entre les sections comme le début d'une nouvelle commande :

```yaml
job:
  script:
    - >
      echo "First command line
      is split over two lines."

      echo "Second command line."
```

Ce comportement est similaire aux commandes multilignes sans les indicateurs scalaires de bloc `>` ou `|` :

```yaml
job:
  script:
    - echo "First command line
      is split over two lines."

      echo "Second command line."
```

Les deux exemples précédents s'affichent dans le job log comme suit :

```shell
$ echo First command line is split over two lines. # collapsed multiline command
First command line is split over two lines.
Second command line.
```

Lorsque vous omettez les indicateurs scalaires de bloc `>` ou `|`, GitLab concatène les lignes non vides pour former la commande. Assurez-vous que les lignes peuvent s'exécuter une fois concaténées.

<!-- vale gitlab_base.MeaningfulLinkWords = NO -->

Les [here documents Shell](https://en.wikipedia.org/wiki/Here_document) fonctionnent également avec les opérateurs `|` et `>`. L'exemple suivant translittère les lettres minuscules en majuscules :

<!-- vale gitlab_base.MeaningfulLinkWords = YES -->

```yaml
job:
  script:
    - |
      tr a-z A-Z << END_TEXT
        one two three
        four five six
      END_TEXT
```

Résultat :

```shell
$ tr a-z A-Z << END_TEXT # collapsed multiline command
  ONE TWO THREE
  FOUR FIVE SIX
```

## Ajouter des codes couleur à la sortie du script {#add-color-codes-to-script-output}

La sortie du script peut être colorée à l'aide de [codes d'échappement ANSI](https://en.wikipedia.org/wiki/ANSI_escape_code#Colors), ou en exécutant des commandes ou des programmes qui génèrent des codes d'échappement ANSI.

Par exemple, avec [Bash et des codes couleur](https://misc.flogisoft.com/bash/tip_colors_and_formatting) :

```yaml
job:
  script:
    - echo -e "\e[31mThis text is red,\e[0m but this text isn't\e[31m however this text is red again."
```

Vous pouvez définir les codes couleur dans des variables d'environnement Shell, ou même dans des [variables CI/CD](../variables/_index.md#define-a-cicd-variable-in-the-gitlab-ciyml-file), ce qui rend les commandes plus faciles à lire et réutilisables.

Par exemple, en utilisant l'exemple précédent et des variables d'environnement définies dans un `before_script` :

```yaml
job:
  before_script:
    - TXT_RED="\e[31m" && TXT_CLEAR="\e[0m"
  script:
    - echo -e "${TXT_RED}This text is red,${TXT_CLEAR} but this part isn't${TXT_RED} however this part is again."
    - echo "This text is not colored"
```

Ou avec les [codes couleur PowerShell](https://superuser.com/a/1259916) :

```yaml
job:
  before_script:
    - $esc="$([char]27)"; $TXT_RED="$esc[31m"; $TXT_CLEAR="$esc[0m"
  script:
    - Write-Host $TXT_RED"This text is red,"$TXT_CLEAR" but this text isn't"$TXT_RED" however this text is red again."
    - Write-Host "This text is not colored"
```
