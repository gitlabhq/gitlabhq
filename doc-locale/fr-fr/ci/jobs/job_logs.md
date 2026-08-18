---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Job logs CI/CD
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Un job log affiche l'historique complet d'exécution d'un [job CI/CD](_index.md).

## Afficher les job logs {#view-job-logs}

Pour afficher les job logs :

1. Sélectionnez le projet pour lequel vous souhaitez afficher les job logs.
1. Dans la barre latérale gauche, sélectionnez **CI/CD** > **Pipelines**.
1. Sélectionnez le pipeline que vous souhaitez inspecter.
1. Dans la vue du pipeline, dans la liste des jobs, sélectionnez un job pour afficher la page des job logs.

Pour afficher des informations détaillées sur le job et la sortie de son log, faites défiler la page des job logs.

## Afficher les job logs en mode plein écran {#view-job-logs-in-full-screen-mode}

Vous pouvez afficher le contenu d'un job log en mode plein écran en cliquant sur **Afficher le mode plein écran**.

Pour utiliser le mode plein écran, votre navigateur web doit également le prendre en charge. Si votre navigateur web ne prend pas en charge le mode plein écran, l'option n'est pas disponible.

## Développer et réduire les sections de job log {#expand-and-collapse-job-log-sections}

{{< history >}}

- La sortie des commandes multi-lignes dans les shells bash a été [introduite](https://gitlab.com/gitlab-org/gitlab-runner/-/merge_requests/3486) dans GitLab 16.5 [avec un feature flag](https://docs.gitlab.com/runner/configuration/feature-flags/) nommé `FF_SCRIPT_SECTIONS`. Désactivé par défaut.

{{< /history >}}

> [!flag]
> La disponibilité de cette fonctionnalité est contrôlée par un feature flag. Pour plus d'informations, consultez l'historique.

Lorsque `FF_SCRIPT_SECTIONS` est activé, les commandes de script multi-lignes apparaissent sous forme de sections réductibles dans les job logs. Les commandes sur une seule ligne sont affichées directement avec le préfixe `$`. Les durées ne sont pas affichées.

Dans les shells `powershell` et `pwsh`, `FF_SCRIPT_SECTIONS` ne crée pas de sections réductibles. Les commandes sont affichées uniquement avec une sortie en couleur.

### Créer des sections réductibles personnalisées {#create-custom-collapsible-sections}

Vous pouvez créer des sections réductibles dans les job logs en générant manuellement des codes spéciaux que GitLab utilise pour délimiter les sections réductibles :

- Marqueur de début de section : `\e[0Ksection_start:UNIX_TIMESTAMP:SECTION_NAME\r\e[0K` + `TEXT_OF_SECTION_HEADER`
- Marqueur de fin de section : `\e[0Ksection_end:UNIX_TIMESTAMP:SECTION_NAME\r\e[0K`

Vous devez ajouter ces codes à la section script de la configuration CI. Par exemple, en utilisant `echo` :

```yaml
job1:
  script:
    - echo -e "\e[0Ksection_start:`date +%s`:my_first_section\r\e[0KHeader of the 1st collapsible section"
    - echo 'this line should be hidden when collapsed'
    - echo -e "\e[0Ksection_end:`date +%s`:my_first_section\r\e[0K"
```

La syntaxe d'échappement peut varier selon le shell utilisé par votre runner. Par exemple, si vous utilisez Zsh, vous devrez peut-être échapper les caractères spéciaux avec `\\e` ou `\\r`.

Dans l'exemple ci-dessus :

- `date +%s` :  Commande qui produit le timestamp Unix (par exemple `1560896352`).
- `my_first_section` :  Le nom donné à la section. Le nom peut uniquement être composé de lettres, de chiffres et des caractères `_`, `.` ou `-`.
- `\r\e[0K` :  Séquence d'échappement qui empêche les marqueurs de section de s'afficher dans le job log rendu (en couleur). Ils s'affichent lors de la consultation du job log brut, accessible dans le coin supérieur droit du job log en sélectionnant **Afficher la version brute complète** ({{< icon name="doc-text" >}}).
  - `\r` : retour chariot (ramène le curseur au début de la ligne).
  - `\e[0K` :  Code d'échappement ANSI pour effacer la ligne de la position du curseur jusqu'à la fin de la ligne. (`\e[K` seul ne fonctionne pas ; le `0` doit être inclus).

Exemple de job log brut :

```plaintext
\e[0Ksection_start:1560896352:my_first_section\r\e[0KHeader of the 1st collapsible section
this line should be hidden when collapsed
\e[0Ksection_end:1560896353:my_first_section\r\e[0K
```

Exemple de log console de job :

![Un job log affichant une section réduite avec du contenu masqué](img/collapsible_job_v16_10.png)

#### Améliorer l'affichage des sections avec un script {#improve-section-display-with-a-script}

Pour supprimer les instructions `echo` qui créent les marqueurs de section dans la sortie du job, vous pouvez déplacer le contenu du job dans un fichier script et l'appeler depuis le job :

1. Créez un script capable de gérer les en-têtes de section. Par exemple :

   ```shell
   # function for starting the section
   function section_start () {
     local section_title="${1}"
     local section_description="${2:-$section_title}"

     echo -e "section_start:`date +%s`:${section_title}[collapsed=true]\r\e[0K${section_description}"
   }

   # Function for ending the section
   function section_end () {
     local section_title="${1}"

     echo -e "section_end:`date +%s`:${section_title}\r\e[0K"
   }

   # Create sections
   section_start "my_first_section" "Header of the 1st collapsible section"

   echo "this line should be hidden when collapsed"

   section_end "my_first_section"

   # Repeat as required
   ```

1. Ajoutez le script au fichier `.gitlab-ci.yml` :

   ```yaml
   job:
     script:
       - source script.sh
   ```

### Réduire les sections par défaut {#collapse-sections-by-default}

Pour réduire les sections par défaut, ajoutez `[collapsed=true]` au marqueur de début de section, après le nom de la section et avant le `\r` :

- Marqueur de début de section avec `[collapsed=true]` : `\e[0Ksection_start:UNIX_TIMESTAMP:SECTION_NAME[collapsed=true]\r\e[0K` + `TEXT_OF_SECTION_HEADER`
- Marqueur de fin de section (inchangé) : `\e[0Ksection_end:UNIX_TIMESTAMP:SECTION_NAME\r\e[0K`

Ajoutez le texte de début de section mis à jour à la configuration CI. Par exemple, en utilisant `echo` :

```yaml
job1:
  script:
    - echo -e "\e[0Ksection_start:`date +%s`:my_first_section[collapsed=true]\r\e[0KHeader of the 1st collapsible section"
    - echo 'this line should be hidden automatically after loading the job log'
    - echo -e "\e[0Ksection_end:`date +%s`:my_first_section\r\e[0K"
```

## Supprimer les job logs {#delete-job-logs}

Lorsque vous supprimez un job log, vous [effacez également le job entier](../../api/jobs.md#erase-a-job).

Pour plus d'informations, consultez [Supprimer les job logs](../../user/storage_management_automation.md#delete-job-logs).

## Timestamps {#timestamps}

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/455582) dans GitLab 17.1 [avec un feature flag](../../administration/feature_flags/_index.md) nommé `parse_ci_job_timestamps`. Désactivé par défaut.
- Le feature flag `parse_ci_job_timestamps` a été [supprimé](https://gitlab.com/gitlab-org/gitlab/-/issues/464785) dans GitLab 17.2.
- [En disponibilité générale](https://gitlab.com/gitlab-org/gitlab/-/issues/202293) dans GitLab 18.9.

{{< /history >}}

Par défaut, les job logs incluent des timestamps au [format ISO 8601](https://www.iso.org/iso-8601-date-and-time-format.html) pour chaque ligne. Utilisez les timestamps pour résoudre les problèmes de performances, identifier les goulots d'étranglement et mesurer la durée des étapes de build spécifiques.

Lorsque les timestamps sont activés, le job log utilise environ 10 % d'espace de stockage supplémentaire.

L'exemple suivant montre un job log avec des timestamps :

![Un job log avec des timestamps en UTC pour chaque ligne](img/ci_log_timestamp_v17_6.png)

### Contrôler les timestamps dans les job logs {#control-timestamps-in-job-logs}

Prérequis :

- GitLab Runner 18.7 ou version ultérieure.

Pour contrôler l'affichage des timestamps dans les job logs, utilisez la variable CI/CD `FF_TIMESTAMPS` :

- Définir sur `false` pour désactiver les timestamps
- Définir sur `true` pour activer explicitement les timestamps

Par exemple :

```yaml
variables:
  FF_TIMESTAMPS: false  # Disables timestamps

job:
  script:
    - echo "This job's log behavior depends on FF_TIMESTAMPS value"
```

Pour plus d'informations, consultez [définir une variable CI/CD dans le fichier `.gitlab-ci.yml`](../variables/_index.md#define-a-cicd-variable-in-the-gitlab-ciyml-file).

## Dépannage {#troubleshooting}

### Job log lent à se mettre à jour {#job-log-slow-to-update}

Lorsque vous visitez la page de job log pour un job en cours d'exécution, un délai pouvant aller jusqu'à 60 secondes peut survenir avant une mise à jour du log. La durée d'actualisation par défaut est de 60 secondes, mais une fois le log affiché dans l'interface utilisateur, les mises à jour du log devraient intervenir toutes les 3 secondes.

### Erreur : `This job does not have a trace` dans GitLab 18.0 ou version ultérieure {#error-this-job-does-not-have-a-trace-in-gitlab-180-or-later}

Après la mise à niveau d'une instance GitLab Self-Managed vers la version 18.0 ou ultérieure, des erreurs `This job does not have a trace` peuvent apparaître. Cela peut être causé par l'échec d'une migration de mise à niveau sur une instance présentant les deux conditions suivantes :

- Stockage d'objets activé
- La journalisation incrémentielle était précédemment activée avec le feature flag supprimé `ci_enable_live_trace`. Ce feature flag est activé par défaut dans les déploiements GitLab Environment Toolkit ou Helm Chart, mais peut également être activé manuellement.

Pour restaurer la capacité à afficher les job logs sur les jobs concernés, [réactivez la journalisation incrémentielle](../../administration/settings/continuous_integration.md#configure-incremental-logging)
