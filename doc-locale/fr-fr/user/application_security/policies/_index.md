---
stage: Security Risk Management
group: Security Policies
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Politiques
description: "Politiques de sécurité, application, conformité, approbations et scans."
---

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Les politiques offrent aux équipes de sécurité et de conformité un moyen d'appliquer des contrôles à l'échelle de leur organisation.

Les équipes de sécurité peuvent s'assurer que :

- Les scanners de sécurité sont appliqués dans les pipelines des équipes de développement avec une configuration appropriée.
- Tous les jobs de scan s'exécutent sans aucune modification ni altération.
- Les approbations appropriées sont fournies sur les merge requests, sur la base des résultats de ces findings.
- Les vulnérabilités qui ne sont plus détectées sont résolues automatiquement, ce qui réduit la charge de travail liée au triage des vulnérabilités.

Les équipes de conformité peuvent appliquer :

- Plusieurs approbateurs sur toutes les merge requests
- Les paramètres de projets basés sur les exigences organisationnelles, tels que l'activation ou le verrouillage des paramètres de merge request ou des paramètres du dépôt.

Les types de politiques suivants sont disponibles :

- [Politique d'exécution de scan](scan_execution_policies.md). Appliquer des scans de sécurité, soit dans le cadre du pipeline, soit selon un calendrier défini.
- [Politique d'approbation des merge requests](merge_request_approval_policies.md). Appliquer des paramètres au niveau du projet et des règles d'approbation basées sur les résultats des scans.
- [Politique d'exécution de pipeline](pipeline_execution_policies.md). Appliquer des jobs CI/CD dans le cadre des pipelines de projet.
  - [Politique d'exécution de pipeline planifiée (version expérimentale)](scheduled_pipeline_execution_policies.md). Appliquer des jobs CI/CD personnalisés selon une cadence planifiée sur l'ensemble des projets, indépendamment de l'activité de commit.
- [Politique de gestion des vulnérabilités](vulnerability_management_policy.md). Résoudre automatiquement les vulnérabilités qui ne sont plus détectées dans la branche par défaut.

## Configurer la portée de la politique {#configure-the-policy-scope}

## Mot-clé `policy_scope` {#policy_scope-keyword}

Utilisez le mot-clé `policy_scope` pour appliquer la politique uniquement aux groupes, projets, référentiels de conformité ou à une combinaison de ceux-ci que vous spécifiez.

| Champ                   | Type     | Valeurs possibles          | Description |
|-------------------------|----------|--------------------------|-------------|
| `match_mode` | `string` | `all`, `any` | [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/569793) dans GitLab 18.10. Détermine comment la politique gère plusieurs conditions de portée. Utilisez `all` (par défaut) pour exiger que toutes les conditions soient satisfaites, ou `any` pour exiger qu'au moins une condition soit satisfaite. |
| `compliance_frameworks` | `array`  | Non applicable           | Liste des identifiants des référentiels de conformité dans la portée d'application, sous forme d'un tableau d'objets avec la clé `id`. |
| `projects`              | `object` | `including`, `excluding` | Utilisez `excluding:` ou `including:` puis listez les identifiants des projets que vous souhaitez inclure ou exclure, sous forme d'un tableau d'objets avec la clé `id`. Vous pouvez également exclure des projets par type en utilisant `type: personal` pour les projets personnels ou `type: archived` pour les projets archivés. |
| `groups`                | `object` | `including`              | Utilisez `including:` puis listez les identifiants des groupes que vous souhaitez inclure, sous forme d'un tableau d'objets avec la clé `id`. Seuls les groupes liés au même projet de politique de sécurité peuvent être listés dans la politique. |

### Collections vides dans `policy_scope` {#empty-collections-in-policy_scope}

Lorsqu'un champ `policy_scope` est défini sur une collection vide (`[]`), il est traité comme si le champ était entièrement omis. Cela signifie que la politique s'applique à tous les projets sans aucune restriction.

Plus précisément :

- `projects: { including: [] }` applique la politique à tous les projets, et non à zéro projet.
- `groups: { including: [] }` applique la politique à tous les groupes, et non à zéro groupe.
- `compliance_frameworks: []` applique la politique à tous les projets, et non aux projets sans référentiel.

Ce comportement assure la rétrocompatibilité avec les politiques existantes qui reposent sur le fait que les collections vides sont traitées comme si le filtre n'avait pas été fourni.

Pour empêcher une politique de s'appliquer à un projet, définissez `enabled: false` au lieu d'utiliser une collection vide :

```yaml
policy_scope:
  projects:
    including:
      - id: 123
enabled: false  # Disables the policy entirely
```

### Comprendre `match_mode` {#understanding-match_mode}

Lorsque vous spécifiez plusieurs conditions de portée (par exemple, à la fois `projects` et `groups`), le champ `match_mode` détermine comment ces conditions sont combinées :

- **`all` (par défaut)** : La politique s'applique uniquement aux projets qui satisfont toutes les conditions spécifiées. Ce mode est plus restrictif et assure la rétrocompatibilité avec les politiques existantes.
- **`any`** :  La politique s'applique aux projets qui satisfont l'une quelconque des conditions spécifiées. Ce mode est plus permissif et utile lorsque vous souhaitez cibler différents ensembles de projets avec une seule politique.

Par exemple, si vous spécifiez à la fois une liste de projets à inclure et une liste de groupes à inclure :

- Avec `match_mode: all`, un projet doit figurer dans la liste des projets **et** appartenir à l'un des groupes spécifiés.
- Avec `match_mode: any`, un projet est dans la portée s'il figure dans la liste des projets **ou** appartient à l'un des groupes spécifiés.

Lorsque vous combinez des conditions `excluding` et `including` avec `match_mode: any`, sachez que la condition `excluding` élargit la portée de la politique. Étant donné que la logique OR signifie que la politique s'applique si une condition quelconque est satisfaite, une condition d'exclusion de groupes (qui correspond à tous les projets sauf ceux des groupes exclus) signifie que la politique s'applique à la plupart des projets, indépendamment de ce qui est spécifié dans les conditions `including`.

Par exemple, une politique qui exclut `group-2` de la liste des groupes et inclut des projets spécifiques `group-1/project-1-1` et `group-2/project-2-1` :

 ```yaml
policy_scope:
  match_mode: any
  groups:
    excluding:
      - id: 200  # group-2
  projects:
    including:
      - id: 101  # group-1/project-1-1
      - id: 201  # group-2/project-2-1
```

Avec cette configuration, la politique s'applique non seulement aux deux projets explicitement inclus, mais également à tous les autres projets situés en dehors de `group-2` (tels que `group-1/project-1-2`, qui ne figure pas dans les projets inclus). La condition d'exclusion de groupes correspond à tout projet n'appartenant pas à `group-2`, et avec la logique OR, une seule correspondance suffit pour que la politique s'applique.

### Exemples de portée {#scope-examples}

Dans cet exemple, la politique d'exécution de scan applique un scan SAST dans chaque pipeline de release, sur chaque projet dont les référentiels de conformité ont un identifiant `2` ou `11` qui leur est appliqué.

```yaml
---
scan_execution_policy:
- name: Enforce specified scans in every release pipeline
  description: This policy enforces a SAST scan for release branches
  enabled: true
  rules:
  - type: pipeline
    branches:
    - release/*
  actions:
  - scan: sast
  policy_scope:
    compliance_frameworks:
      - id: 2
      - id: 11
```

Dans cet exemple, la politique d'exécution de scan applique un scan de détection des secrets et un scan SAST sur les pipelines pour la branche par défaut, sur tous les projets du groupe avec l'identifiant `203` (y compris tous les sous-groupes descendants et leurs projets), à l'exclusion du projet avec l'identifiant `64`.

```yaml
- name: Enforce specified scans in every default branch pipeline
  description: This policy enforces secret detection and SAST scans for the default branch
  enabled: true
  rules:
  - type: pipeline
    branches:
    - main
  actions:
  - scan: secret_detection
  - scan: sast
  policy_scope:
    groups:
      including:
        - id: 203
    projects:
      excluding:
        - id: 64
```

Dans cet exemple, la politique d'exécution de scan applique un scan SAST sur tous les projets, à l'exception des projets archivés. Cela est utile lorsque vous avez de nombreux projets archivés qui ne doivent pas être scannés.

```yaml
- name: Enforce SAST scan excluding archived projects
  description: This policy enforces SAST scans but excludes archived projects
  enabled: true
  rules:
  - type: pipeline
    branches:
    - main
  actions:
  - scan: sast
  policy_scope:
    projects:
      excluding:
        - type: archived
```

Dans cet exemple, la politique d'exécution de scan utilise `match_mode: any` pour appliquer un scan de détection des secrets sur des projets spécifiques à haute priorité ou sur tous les projets au sein de groupes spécifiques. Sans `match_mode: any`, un projet doit figurer dans la liste des projets et dans l'un des groupes spécifiés pour que la politique s'applique.

```yaml
- name: Enforce secret detection on priority projects or security groups
  description: This policy enforces secret detection on specific projects or all projects in security-focused groups
  enabled: true
  rules:
  - type: pipeline
    branches:
    - main
  actions:
  - scan: secret_detection
  policy_scope:
    match_mode: any
    projects:
      including:
        - id: 123  # High-priority project outside of security groups
        - id: 456  # Another critical project
    groups:
      including:
        - id: 78   # Security team's group
        - id: 90   # Compliance team's group
```

## Séparation des tâches {#separation-of-duties}

La séparation des tâches est essentielle pour la mise en œuvre réussie des politiques. Mettez en œuvre des politiques qui répondent aux exigences de conformité et de sécurité nécessaires, tout en permettant aux équipes de développement d'atteindre leurs objectifs.

Équipes de sécurité et de conformité :

- Doivent être responsables de la définition des politiques et de la collaboration avec les équipes de développement pour s'assurer que les politiques répondent à leurs besoins.

Équipes de développement :

- Ne doivent pas être en mesure de désactiver, modifier ou contourner les politiques de quelque manière que ce soit.

Pour appliquer un projet de politique de sécurité à un groupe, un sous-groupe ou un projet, vous devez disposer de l'un des éléments suivants :

- Le rôle Owner dans ce groupe, sous-groupe ou projet.
- Un rôle personnalisé dans ce groupe, sous-groupe ou projet avec la permission `manage_security_policy_link`.

Le rôle Owner et les rôles personnalisés avec la permission `manage_security_policy_link` suivent les règles de hiérarchie standard dans les groupes, sous-groupes et projets :

| Unité organisationnelle | Owner du groupe ou permission `manage_security_policy_link` du groupe | Owner du sous-groupe ou permission `manage_security_policy_link` du sous-groupe | Owner du projet ou permission `manage_security_policy_link` du projet |
|-------------------|---------------------------------------------------------------|---------------------------------------------------------------------|-------------------------------------------------------------------|
| Groupe             | {{< yes >}} | {{< no >}}  | {{< no >}}  |
| Sous-groupe          | {{< yes >}} | {{< yes >}} | {{< no >}}  |
| Projet           | {{< yes >}} | {{< yes >}} | {{< yes >}} |

### Permissions requises {#required-permissions}

Pour créer et gérer des politiques de sécurité :

- Pour les politiques appliquées aux groupes : Vous devez disposer du rôle Maintainer ou Owner pour le groupe.
- Pour les politiques appliquées aux projets :
  - Vous devez être le propriétaire du projet.
  - Vous devez être membre du groupe avec les permissions nécessaires pour créer des projets dans le groupe.

> [!note]
> Si vous n'êtes pas membre du groupe, vous pouvez rencontrer des limitations lors de l'ajout ou de la modification de politiques pour votre projet. La capacité à créer et gérer des politiques nécessite des permissions pour créer des projets dans le groupe. Assurez-vous de disposer des permissions requises dans le groupe, même lorsque vous travaillez avec des politiques au niveau du projet.

## Recommandations sur les politiques {#policy-recommendations}

Lors de la mise en œuvre des politiques, tenez compte des recommandations suivantes.

### Noms de branches {#branch-names}

Lorsque vous spécifiez des noms de branches dans une politique, utilisez une catégorie générique de branches protégées, telle que **branche par défaut** ou **toutes les branches protégées**, et non des noms de branches individuels.

Une politique est appliquée à un projet uniquement si la branche spécifiée existe dans ce projet. Par exemple, si votre politique applique des règles sur la branche `main` mais que certains projets dans la portée utilisent `production` comme branche par défaut, la politique ne s'applique pas à ces derniers.

### Règles push {#push-rules}

Dans GitLab 17.3 et versions antérieures, si vous utilisez des règles push pour [valider les noms de branches](../../project/repository/push_rules.md#validate-branch-names), assurez-vous qu'elles autorisent la création de branches avec le préfixe `update-policy-`. Ce préfixe de nommage de branche est utilisé lors de la création ou de la modification d'une politique de sécurité. Par exemple, `update-policy-1659094451`, où `1659094451` est l'horodatage. Si les règles push bloquent la création de la branche, l'erreur suivante se produit :

```plaintext
Branch name `update-policy-<timestamp>` does not follow the pattern `<branch_name_regex>`.
```

Dans GitLab 17.4 et versions ultérieures, les projets de politique de sécurité sont exclus des règles push qui appliquent la validation des noms de branches.

### Projets de politique de sécurité {#security-policy-projects}

Pour éviter l'exposition d'informations sensibles destinées à rester privées dans votre projet de politique de sécurité, lorsque vous liez des projets de politique de sécurité à d'autres projets :

- N'incluez pas de contenu sensible dans vos projets de politique de sécurité.
- Avant de lier un projet de politique de sécurité privé, vérifiez la liste des membres du projet cible pour vous assurer que tous les membres doivent avoir accès au contenu de votre politique.
- Évaluez les paramètres de visibilité des projets cibles.
- Utilisez les journaux d'audit de [gestion des politiques de sécurité](../../compliance/audit_event_types.md#security-policy-management) pour surveiller les liaisons de projets.

Ces recommandations préviennent l'exposition d'informations sensibles pour les raisons suivantes :

- Visibilité partagée : Lorsqu'un projet de sécurité privé est lié à un autre projet, les utilisateurs ayant accès à la page **Security Policies** du projet lié peuvent consulter le contenu du fichier `.gitlab/security-policies/policy.yml`. Cela inclut la liaison d'un projet de politique de sécurité privé à un projet public, ce qui peut exposer le contenu de la politique à toute personne pouvant accéder au projet public.
- Contrôle d'accès : Tous les membres du projet auquel un projet de sécurité privé est lié peuvent consulter le fichier de politique sur la page **Policy**, même s'ils n'ont pas accès au dépôt privé d'origine.

### Contrôles de sécurité et de conformité {#security-and-compliance-controls}

Les mainteneurs de projet peuvent créer des politiques pour des projets qui interfèrent avec l'exécution des politiques pour les groupes. Pour limiter les personnes pouvant modifier les politiques pour les groupes et s'assurer que les exigences de conformité sont respectées, lorsque vous mettez en œuvre des contrôles critiques de sécurité ou de conformité :

- Utilisez des rôles personnalisés pour restreindre les personnes pouvant créer ou modifier des politiques d'exécution de pipeline au niveau du projet.
- Configurez des branches protégées pour la branche par défaut dans vos projets de politique de sécurité afin d'empêcher les pushs directs.
- Configurez des règles d'approbation des merge requests dans vos projets de politique de sécurité qui nécessitent une révision par des approbateurs désignés.
- Surveillez et examinez toutes les modifications de politiques dans les politiques pour les groupes et les projets.

## Gestion des politiques {#policy-management}

La page Politiques affiche les politiques déployées pour tous les environnements disponibles. Vous pouvez vérifier les informations d'une politique (par exemple, la description ou le statut d'application) et créer et modifier les politiques déployées :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Sécurisation** > **Politiques**.

![Page de liste des politiques](img/policies_list_v17_7.png)

Une coche verte dans la première colonne indique que la politique est activée et appliquée à tous les groupes et projets dans sa portée. Une coche grise indique que la politique n'est actuellement pas activée.

## Éditeur de politiques {#policy-editor}

L'éditeur de politiques dispose de deux modes :

- Mode règle : Construisez et prévisualisez les règles de politique à l'aide de blocs de règles et des contrôles associés.
- Mode YAML : Saisissez une définition de politique au format YAML. Adapté aux utilisateurs experts et aux cas que le mode règle ne prend pas en charge.

Vous pouvez basculer entre le mode règle et le mode YAML à tout moment. Si votre YAML contient des erreurs ou des données non prises en charge, le mode règle se désactive automatiquement. Corrigez d'abord le YAML pour utiliser à nouveau le mode règle.

Utilisez l'éditeur de politiques pour créer, modifier et supprimer des politiques :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Sécurisation** > **Politiques**.
   - Pour créer une nouvelle politique, sélectionnez **Nouvelle politique** dans l'en-tête de la page **Politiques**, puis sélectionnez le type de politique.
   - Pour modifier une politique existante, sélectionnez **Modifier la politique** dans le tiroir de la politique sélectionnée.

1. Sélectionnez **Configurer avec une requête de fusion** pour enregistrer et appliquer les modifications.

   Le YAML de la politique est validé et les éventuelles erreurs résultantes sont affichées.

1. Examinez et fusionnez le merge request résultant.

   Si vous êtes propriétaire du projet et qu'aucun projet de politique de sécurité n'est associé à ce projet, un projet de politique de sécurité est créé et lié à ce projet lors de la création du merge request.

### Dispositions d'éditeur standard et avancée {#standard-and-advanced-editor-layouts}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/450705) dans GitLab 17.8.

{{< /history >}}

L'éditeur de politiques dispose de deux dispositions qui déterminent la présentation du mode règle et du mode YAML :

- Éditeur standard : Affiche le mode règle et le mode YAML sous forme d'onglets séparés. Sélectionnez un onglet pour basculer entre les vues. En mode règle, un aperçu YAML en lecture seule apparaît dans la barre latérale.
- Éditeur avancé : Affiche le mode règle et le mode YAML côte à côte dans une vue fractionnée redimensionnable. Les modifications dans un panneau sont répercutées dans l'autre en temps réel. Vous pouvez :

  - Faites glisser le séparateur pour redimensionner les panneaux.
  - Réduisez l'un ou l'autre panneau pour vous concentrer sur une seule vue.
  - Pour réinitialiser la taille des panneaux, sélectionnez le séparateur deux fois.

La taille de panneau que vous préférez est enregistrée entre les sessions.

Pour basculer entre les dispositions d'éditeur standard et avancée :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Sécurisation** > **Politiques**.
   - Pour créer une nouvelle politique, sélectionnez **Nouvelle politique** dans l'en-tête de la page **Politiques**, puis sélectionnez le type de politique.
   - Pour modifier une politique existante, sélectionnez **Modifier la politique** dans le tiroir de la politique sélectionnée.

1. En haut de l'éditeur de politiques, sélectionnez **Activer l'éditeur avancé** ou **Activer l'éditeur standard**.

Votre préférence est enregistrée dans votre compte utilisateur et persiste entre les sessions.

### Annoter les identifiants dans `policy.yml` {#annotate-ids-in-policyyml}

{{< details >}}

Statut :  Expérience

{{< /details >}}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/497774) en tant que [version expérimentale](../../../policy/development_stages_support.md) dans GitLab 18.1 avec une option `annotate_ids` définie dans le fichier `policy.yml`.

{{< /history >}}

Pour simplifier votre fichier `policy.yml`, GitLab peut ajouter automatiquement des commentaires après les identifiants, tels que les identifiants de projet, les identifiants de groupe, les identifiants d'utilisateur ou les identifiants de référentiel de conformité. Les annotations aident les utilisateurs à identifier la signification ou l'origine de chaque identifiant, ce qui rend le fichier `policy.yml` plus facile à comprendre et à maintenir.

Pour activer cette fonctionnalité expérimentale, ajoutez une section `annotate_ids` à la section `experiments` dans le fichier `.gitlab/security-policies/policy.yml` de votre projet de politique de sécurité :

```yaml
experiments:
  annotate_ids:
    enabled: true
```

Après avoir activé l'option, toute modification apportée aux politiques de sécurité à l'aide de l'[éditeur de politiques](#policy-editor) GitLab crée des commentaires d'annotation à côté des identifiants dans le fichier `policy.yml`.

> [!note]
> Pour appliquer les annotations, vous devez utiliser l'éditeur de politiques. Si vous modifiez le fichier `policy.yml` manuellement (par exemple, avec un commit Git), les annotations ne sont pas appliquées.

Par exemple :

```yaml
# Example policy.yml with annotated IDs
approval_policy:
- name: Your policy name
  # ... other policy fields ...
  policy_scope:
    projects:
      including:
      - id: 361 # my-group/my-project
  actions:
  - type: require_approval
    approvals_required: 1
    user_approvers_ids:
    - 75 # jane.doe
    group_approvers_ids:
    - 203 # security-approvers
```

> [!note]
> Lorsque vous appliquez des annotations pour la première fois, GitLab crée les annotations pour tous les identifiants dans le fichier `policy.yml`, y compris ceux des politiques que vous ne modifiez pas.

## Utilisateur GitLab Security Policy Bot {#gitlab-security-policy-bot-user}

GitLab Security Policy Bot est un utilisateur interne qui exécute les politiques de sécurité sur l'ensemble de votre instance GitLab. Ce bot est essentiel pour que les politiques de sécurité et les pipelines planifiés fonctionnent correctement.

Le Security Policy Bot est responsable de :

- Exécution de pipeline planifiée : Déclenche les pipelines définis dans les politiques d'exécution de scan avec les règles `type: schedule`.
- Automatisation du scan de conteneurs : Déclenche les jobs de scan de conteneurs lorsque des images sont poussées avec le tag `latest`.
- Application des politiques : Exécute des scans de sécurité et des vérifications de conformité tels que définis dans vos politiques de sécurité.
- Création de pipeline : Crée et gère des pipelines pilotés par les politiques dans les projets où les politiques de sécurité sont appliquées.

### Caractéristiques du compte {#account-characteristics}

Le Security Policy Bot présente les caractéristiques suivantes :

- Créé automatiquement dans chaque projet où une politique de sécurité est appliquée.
- S'exécute avec les permissions du rôle Invité dans les projets, avec des permissions supplémentaires spécifiques.
- N'est pas comptabilisé dans les limites de licences car il est marqué comme utilisateur interne.
- Chaque projet dispose de sa propre instance du Security Policy Bot lorsque les politiques sont appliquées.

### Permissions et accès {#permissions-and-access}

Le Security Policy Bot opère avec des permissions minimales mais essentielles :

- Accès au dépôt : Accès en lecture seule au contenu du dépôt requis pour l'exécution des politiques.
- Création de pipeline : Capacité à créer et déclencher des pipelines pour l'application des politiques.
- Variables CI/CD : Accès aux variables CI/CD de projet et de groupe selon les règles de précédence des variables.
- Accès au registre : Peut s'authentifier auprès des registres de conteneurs lorsque configuré avec les informations d'identification appropriées.

### Limitations et restrictions {#limitations-and-restrictions}

Tenez compte des limitations suivantes pour GitLab Security Policy Bot :

- Impossible à supprimer manuellement : Vous ne pouvez pas supprimer le bot dans l'interface utilisateur.
- Impossible à modifier : Vous ne pouvez pas modifier manuellement les paramètres ou les permissions de l'utilisateur.
- Lié au projet : Chaque instance du bot est liée à un projet spécifique et vous ne pouvez pas partager une instance entre plusieurs projets.
- Dépendant des politiques : La fonctionnalité du bot dépend entièrement des politiques de sécurité configurées pour le projet.

### Dépannage de sécurité {#security-troubleshooting}

> [!warning]
> Vulnérabilité liée aux signalements d'abus : Les instances du GitLab Security Policy Bot peuvent être bannies ou supprimées via le système de signalement d'abus, ce qui peut empêcher les pipelines planifiés de s'exécuter. Les administrateurs doivent savoir que :
>
> - Signaler un Security Policy Bot pour abus peut entraîner le bannissement ou la suppression du bot.
> - Le bannissement ou la suppression du bot entraîne l'échec des pipelines planifiés.
> - Une fois banni, vous ne pouvez pas restaurer le bot via des actions administratives standard.
> - L'application des politiques de sécurité est complètement perturbée jusqu'à la restauration du bot.
>
> Pour éviter toute interruption accidentelle des politiques de sécurité, les administrateurs doivent faire preuve de prudence lors du traitement des signalements d'abus pour les comptes d'utilisateurs internes.

Si vous rencontrez des problèmes avec la fonctionnalité du Security Policy Bot :

#### Pipelines planifiés non exécutés {#scheduled-pipelines-not-running}

Si les pipelines planifiés ne s'exécutent pas comme configuré :

- Vérifiez que le compte du bot existe et n'est pas banni ou supprimé.
- Vérifiez que la configuration de la politique de sécurité est valide.
- Assurez-vous que le bot dispose des permissions nécessaires dans le projet.

#### Échec des jobs de politique {#policy-jobs-failing}

Si les jobs de politique échouent :

- Vérifiez que le bot a accès aux variables CI/CD requises.
- Vérifiez que les fichiers de configuration CI/CD référencés existent et sont accessibles.
- Examinez les journaux de pipeline pour les messages d'erreur spécifiques.

#### Scan de conteneurs non déclenché {#container-scanning-not-triggering}

Si le scan de conteneurs ne se déclenche pas comme configuré :

- Confirmez que les politiques de scan de conteneurs sont correctement configurées.
- Vérifiez que le bot dispose des informations d'identification d'authentification au registre, si nécessaire.
- Vérifiez que le push du tag `latest` a déclenché les règles de politique attendues.

#### Compte du bot manquant {#bot-account-missing}

Si le compte du bot n'existe plus :

- Réappliquez ou mettez à jour la politique de sécurité pour recréer le compte du bot.
- Contactez votre administrateur GitLab si le bot a été accidentellement banni ou supprimé via des signalements d'abus.

## Dépannage {#troubleshooting}

Lorsque vous travaillez avec des politiques de sécurité, tenez compte des conseils de dépannage suivants :

- Vous ne devez pas lier un projet de politique de sécurité à la fois à un projet de développement et au groupe ou sous-groupe auquel appartient le projet de développement. Une telle liaison entraîne la non-application des règles d'approbation des politiques d'approbation des merge requests aux merge requests dans le projet de développement.
- Lors de la création d'une politique d'approbation des merge requests, ni le tableau `severity_levels` ni le tableau `vulnerability_states` dans la [règle `scan_finding`](merge_request_approval_policies.md#scan_finding-rule-type) ne peuvent être laissés vides. Pour qu'une règle soit fonctionnelle, au moins une entrée doit exister pour chaque tableau.
- Le propriétaire d'un projet peut appliquer des politiques pour ce projet, à condition de disposer également des permissions pour créer des projets dans le groupe. Les propriétaires de projet qui ne sont pas membres du groupe peuvent rencontrer des limitations lors de l'ajout ou de la modification de politiques. Si vous n'êtes pas en mesure de gérer les politiques pour votre projet, contactez votre administrateur de groupe pour vous assurer de disposer des permissions nécessaires dans le groupe.
- En cas de conflits entre politiques, la politique appliquée le plus récemment a la priorité.

Si vous rencontrez encore des problèmes, vous pouvez [consulter les bugs récemment signalés](https://gitlab.com/gitlab-org/gitlab/-/issues/?sort=popularity&state=opened&label_name%5B%5D=group%3A%3Asecurity%20policies&label_name%5B%5D=type%3A%3Abug&first_page_size=20) et signaler de nouveaux problèmes non encore rapportés.

### Resynchroniser les politiques avec l'API GraphQL {#resynchronize-policies-with-the-graphql-api}

Si vous constatez des incohérences dans l'une des politiques, telles que des politiques qui ne sont pas appliquées ou des approbations incorrectes, vous pouvez forcer manuellement une resynchronisation des politiques avec la mutation GraphQL `resyncSecurityPolicies` :

```graphql
mutation {
  resyncSecurityPolicies(input: { fullPath: "group-or-project-path" }) {
    errors
  }
}
```

Définissez `fullPath` sur le chemin du projet ou du groupe auquel le projet de politique de sécurité est assigné.

#### Resynchroniser des projets avec l'API GraphQL {#resynchronize-projects-with-the-graphql-api}

Si le projet concerné hérite de la politique d'un groupe ou d'un sous-groupe, vous pouvez resynchroniser uniquement ce projet :

```graphql
mutation {
  resyncSecurityPolicies(
    input: {
      fullPath: "project-path"
      relationship: INHERITED
    }
  ) {
    errors
  }
}
```

Définissez `fullPath` sur le chemin du projet qui hérite de la politique. Utilisez `relationship: INHERITED` pour resynchroniser les politiques héritées par ce projet sans resynchroniser l'ensemble du groupe ou du sous-groupe.
