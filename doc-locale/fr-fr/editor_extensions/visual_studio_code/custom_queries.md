---
stage: AI-powered
group: Editor Extensions
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: "Requêtes personnalisées dans l'extension VS Code"
---

L'extension GitLab pour VS Code ajoute un panneau **GitLab** ({{< icon name="tanuki" >}}) à VS Code que vous pouvez utiliser pour [travailler avec vos projets](projects.md).

Par défaut, la section **Tickets et requêtes de fusion** du panneau affiche les résultats de ces requêtes de recherche :

- Tickets qui me sont assignés
- Tickets créés par moi
- Merge requests qui me sont assignées
- Merge requests créées par moi
- Merge requests que je relis

Utilisez des requêtes personnalisées pour adapter cette section et afficher les informations qui vous intéressent.

## Créer une requête personnalisée {#create-a-custom-query}

Les requêtes personnalisées remplacent les requêtes par défaut affichées dans le panneau **GitLab** ({{< icon name="tanuki" >}}) sous **Tickets et requêtes de fusion**.

Pour utiliser des requêtes personnalisées pour le panneau :

1. Dans VS Code, ouvrez l'éditeur **Paramètres** :
   - Pour macOS, appuyez sur <kbd>Command</kbd>+<kbd>,</kbd>.
   - Pour Windows ou Linux, appuyez sur <kbd>Control</kbd>+<kbd>,</kbd>.
1. Dans le coin supérieur droit, sélectionnez **Ouvrir les paramètres (JSON)** pour modifier votre fichier `settings.json`.
1. Dans le fichier, définissez `gitlab.customQueries`, comme dans cet exemple. Chaque requête doit être une entrée dans le tableau JSON `gitlab.customQueries` :

   ```json
   {
     "gitlab.customQueries": [
       {
         "name": "Issues assigned to me",
         "type": "issues",
         "scope": "assigned_to_me",
         "noItemText": "No issues assigned to you.",
         "state": "opened"
       }
     ]
   }
   ```

1. Facultatif. Pour conserver l'une des requêtes par défaut, copiez-la depuis le tableau `default` dans le [fichier `desktop.package.json`](https://gitlab.com/gitlab-org/gitlab-vscode-extension/-/blob/8e4350232154fe5bf0ef8a6c0765b2eac0496dc7/desktop.package.json#L955-998) de l'extension et ajoutez-la au tableau `gitlab.customQueries` en tant que requête personnalisée supplémentaire.
1. Enregistrez vos modifications.

### Paramètres pris en charge pour toutes les requêtes {#supported-parameters-for-all-queries}

Ces paramètres s'appliquent à tous les types de requêtes :

| Paramètre    | Obligatoire    | Valeur par défaut           | Définition |
|--------------|-------------|-------------------|------------|
| `name`       | {{< yes >}} | Aucune              | Spécifie le label à afficher dans le panneau **GitLab**. |
| `noItemText` | {{< no >}}  | `No items found.` | Spécifie le texte à afficher si la requête ne renvoie aucun élément. |
| `type`       | {{< no >}}  | `merge_requests`  | Spécifie les types d'éléments à retourner. Valeurs possibles : `issues`, `merge_requests`, `epics`, `snippets`, `vulnerabilities`. Les snippets [ne prennent pas en charge](../../api/project_snippets.md) les autres filtres. Les epics sont disponibles uniquement avec GitLab Premium et GitLab Ultimate. |

### Paramètres pris en charge pour les requêtes de tickets, d'epics et de merge requests {#supported-parameters-for-issue-epic-and-merge-request-queries}

Tous ces paramètres sont facultatifs.

| Paramètre          | Valeur par défaut        | Définition |
|--------------------|----------------|------------|
| `assignee`         | Aucune           | Retourne les éléments assignés au nom d'utilisateur donné. `None` retourne les éléments GitLab non assignés. `Any` retourne les éléments GitLab avec un responsable. Non disponible pour les epics et les vulnérabilités. |
| `author`           | Aucune           | Retourne les éléments créés par le nom d'utilisateur donné. |
| `confidential`     | Aucune           | Retourne les tickets confidentiels ou publics. Disponible uniquement pour les tickets. |
| `createdAfter`     | Aucune           | Retourne les éléments créés après la date donnée. |
| `createdBefore`    | Aucune           | Retourne les éléments créés avant la date donnée. |
| `draft`            | `no`           | Retourne les merge requests filtrées par statut de brouillon : `yes` retourne uniquement les merge requests en [statut de brouillon](../../user/project/merge_requests/drafts.md), `no` retourne uniquement les merge requests qui ne sont pas en statut de brouillon. Disponible uniquement pour les merge requests. |
| `excludeAssignee`  | Aucune           | Retourne les éléments non assignés au nom d'utilisateur donné. Disponible uniquement pour les tickets. Pour l'utilisateur actuel, définissez la valeur sur `<current_user>`. |
| `excludeAuthor`    | Aucune           | Retourne les éléments non créés par le nom d'utilisateur donné. Disponible uniquement pour les tickets. Pour l'utilisateur actuel, définissez la valeur sur `<current_user>`. |
| `excludeLabels`    | `[]`           | Retourne les éléments ne possédant aucun des labels du tableau donné. Disponible uniquement pour les tickets. Les noms prédéfinis ne sont pas sensibles à la casse. |
| `excludeMilestone` | Aucune           | Retourne les éléments excluant le titre du jalon donné. Disponible uniquement pour les tickets. |
| `excludeSearch`    | Aucune           | Retourne les éléments ne contenant pas le terme de recherche dans leur titre ou leur description. Fonctionne uniquement avec les tickets. |
| `labels`           | `[]`           | Retourne les éléments possédant tous les labels du tableau donné. `None` retourne les éléments sans label. `Any` retourne les éléments avec au moins un label. Les noms prédéfinis ne sont pas sensibles à la casse. |
| `maxResults`       | 20             | Retourne jusqu'à ce nombre de résultats. |
| `milestone`        | Aucune           | Retourne les éléments correspondant au titre du jalon donné. `None` retourne tous les éléments sans jalon. `Any` retourne tous les éléments avec un jalon assigné. Non disponible pour les epics et les vulnérabilités. |
| `orderBy`          | `created_at`   | Retourne les éléments triés selon la valeur sélectionnée. Valeurs possibles : `created_at`, `updated_at`, `priority`, `due_date`, `relative_position`, `label_priority`, `milestone_due`, `popularity`, `weight`. Certaines valeurs sont spécifiques aux tickets et d'autres aux merge requests. Pour plus d'informations, consultez [lister les merge requests](../../api/merge_requests.md#list-merge-requests). |
| `reviewer`         | Aucune           | Retourne les merge requests pour lesquelles le nom d'utilisateur donné est assigné en tant que relecteur. Pour l'utilisateur actuel, définissez la valeur sur `<current_user>`. `None` retourne les éléments sans relecteur. `Any` retourne les éléments avec un relecteur. |
| `scope`            | `all`          | Retourne les éléments pour la portée donnée. Non applicable pour les epics. Valeurs possibles : `assigned_to_me`, `created_by_me`, `all`. |
| `search`           | Aucune           | Retourne les éléments contenant le terme de recherche donné dans leur titre et leur description. |
| `searchIn`         | `all`          | Retourne les résultats avec l'attribut `excludeSearch` dont la portée est limitée à la valeur donnée. Valeurs possibles : `all`, `title`, `description`. Fonctionne uniquement avec les tickets. |
| `sort`             | `desc`         | Retourne les tickets triés par ordre croissant ou décroissant. Valeurs possibles : `asc`, `desc`. |
| `state`            | `opened`       | Retourne tous les tickets ou uniquement ceux correspondant à un statut particulier. Valeurs possibles : `all`, `opened`, `closed`. |
| `updatedAfter`     | Aucune           | Retourne les éléments mis à jour après la date donnée. |
| `updatedBefore`    | Aucune           | Retourne les éléments mis à jour avant la date donnée. |

### Paramètres pris en charge pour les requêtes de rapport de vulnérabilités {#supported-parameters-for-vulnerability-report-queries}

Les rapports de vulnérabilités ne partagent [aucun paramètre de requête commun](../../api/vulnerability_findings.md) avec les autres types d'entrées. Chaque paramètre répertorié dans ce tableau fonctionne uniquement avec les rapports de vulnérabilités, et tous les paramètres sont facultatifs :

| Paramètre          | Valeur par défaut        | Définition |
|--------------------|----------------|------------|
| `confidenceLevels` | `all`          | Retourne les vulnérabilités avec les niveaux de confiance donnés. Valeurs possibles : `undefined`, `ignore`, `unknown`, `experimental`, `low`, `medium`, `high`, `confirmed`. |
| `reportTypes`      | Aucune           | Retourne les vulnérabilités avec les types de rapport donnés. Valeurs possibles : `sast`, `dast`, `dependency_scanning`, `container_scanning`. |
| `scope`            | `dismissed`    | Retourne les vulnérabilités pour la portée donnée. Valeurs possibles : `all`, `dismissed`. Pour plus d'informations, consultez l'[API Vulnerability findings](../../api/vulnerability_findings.md). |
| `severityLevels`   | `all`          | Retourne les vulnérabilités avec les niveaux de gravité donnés. Valeurs possibles : `undefined`, `info`, `unknown`, `low`, `medium`, `high`, `critical`. |
