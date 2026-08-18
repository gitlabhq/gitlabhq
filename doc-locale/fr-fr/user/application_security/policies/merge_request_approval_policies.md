---
stage: Security Risk Management
group: Security Policies
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "Découvrez comment appliquer des règles de sécurité dans GitLab à l'aide de politiques d'approbation des merge requests pour automatiser les scans, les approbations et la conformité dans vos projets."
title: "Politiques d'approbation des merge requests"
---

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- Les politiques de résultats de scan au niveau du groupe ont été [introduites](https://gitlab.com/groups/gitlab-org/-/epics/7622) dans GitLab 15.6.
- La fonctionnalité de politiques de résultats de scan a été renommée en politiques d'approbation des merge requests dans GitLab 16.9.

{{< /history >}}

> [!note]
> La fonctionnalité de politiques de résultats de scan a été renommée en politiques d'approbation des merge requests dans GitLab 16.9.

Vous pouvez utiliser les politiques d'approbation des merge requests à plusieurs fins, notamment :

- Détecter les résultats des scanners de sécurité et de licences pour appliquer des règles d'approbation. Par exemple, un type de politique de merge request est une politique d'approbation de sécurité qui permet d'exiger une approbation en fonction des résultats d'un ou plusieurs jobs de scan de sécurité. Les politiques d'approbation des merge requests sont évaluées après l'exécution complète d'un job de scan CI et les politiques de type vulnérabilité et de licence sont toutes deux évaluées en fonction des rapports d'artefact de job publiés dans le pipeline terminé.
- Appliquer des règles d'approbation à toutes les merge requests répondant à certaines conditions. Par exemple, imposer que les merge requests soient examinées par plusieurs utilisateurs avec les rôles Développeur et Mainteneur pour toutes les merge requests ciblant les branches par défaut.
- Appliquer des paramètres de sécurité et de conformité à un projet. Par exemple, empêcher les utilisateurs ayant rédigé ou commité des modifications dans une merge request d'approuver celle-ci. Ou empêcher les utilisateurs d'effectuer des pushs ou des force pushes vers la branche par défaut pour s'assurer que toutes les modifications passent par une merge request.

> [!note]
> Lorsqu'une branche protégée est créée ou supprimée, les règles d'approbation de la politique se synchronisent, avec un délai d'1 minute.

La vidéo suivante vous donne un aperçu des politiques d'approbation des merge requests GitLab (anciennement politiques de résultats de scan) :

<div class="video-fallback">
  Voir la vidéo : <a href="https://youtu.be/w5I9gcUgr9U">Présentation des politiques de résultats de scan GitLab</a>.
</div>
<figure class="video-container">
  <iframe src="https://www.youtube-nocookie.com/embed/w5I9gcUgr9U" frameborder="0" allowfullscreen> </iframe>
</figure>

## Restrictions {#restrictions}

- Vous pouvez appliquer des politiques d'approbation des merge requests uniquement sur les branches cibles [protégées](../../project/repository/branches/protected.md).
- Vous pouvez attribuer un maximum de cinq règles à chaque politique.
- Vous pouvez attribuer un maximum de cinq politiques d'approbation des merge requests à chaque projet de politique de sécurité.
- Les politiques créées pour un groupe ou un sous-groupe peuvent mettre un certain temps à s'appliquer à toutes les merge requests du groupe. Le temps nécessaire est déterminé par le nombre de projets et le nombre de merge requests dans ces projets. En général, le temps nécessaire est de l'ordre de quelques secondes. D'après les observations passées, le processus peut prendre plusieurs minutes pour les groupes comptant des milliers de projets et de merge requests.
- Les politiques d'approbation des merge requests ne vérifient pas l'intégrité ou l'authenticité des résultats de scan générés dans les rapports d'artefacts.
- Une politique d'approbation des merge requests est évaluée conformément à ses règles. Par défaut, si les règles sont invalides ou ne peuvent pas être évaluées, une approbation est requise. Vous pouvez modifier ce comportement avec le [champ `fallback_behavior`](#fallback_behavior).

## Prérequis du pipeline {#pipeline-requirements}

Une politique d'approbation des merge requests est appliquée en fonction du résultat du pipeline. Tenez compte des points suivants lors de l'implémentation d'une politique d'approbation des merge requests :

- Une politique d'approbation des merge requests évalue les jobs de pipeline terminés, en ignorant les jobs manuels. Lorsque les jobs manuels sont exécutés, la politique réévalue les jobs de la merge request.
- Pour une politique d'approbation des merge requests qui évalue les résultats des scanners de sécurité, tous les scanners spécifiés doivent avoir produit un rapport de sécurité. Dans le cas contraire, des approbations sont imposées pour minimiser le risque d'introduction de vulnérabilités. Ce comportement peut affecter :
  - Les nouveaux projets où les scans de sécurité ne sont pas encore établis.
  - Les branches créées avant la configuration des scans de sécurité.
  - Les projets avec des configurations de scanner incohérentes entre les branches.
- Le pipeline doit produire des artefacts pour tous les scanners activés, à la fois pour les branches source et cible. Dans le cas contraire, il n'y a aucune base de comparaison et la politique ne peut pas être évaluée de manière fiable. Consultez [Scans de sécurité manquants](#missing-security-scans) pour plus d'informations. Vous devriez utiliser une politique d'exécution de scan pour appliquer cette exigence.
- L'évaluation de la politique dépend d'un pipeline de base de fusion réussi et terminé. Si le pipeline de base de fusion est ignoré, les merge requests utilisant ce pipeline sont bloquées.
- Les scanners de sécurité spécifiés dans une politique doivent être configurés et activés dans les projets sur lesquels la politique est appliquée. Dans le cas contraire, la politique d'approbation des merge requests ne peut pas être évaluée et les approbations correspondantes sont requises.

## Bonnes pratiques pour l'utilisation des scanners de sécurité avec les politiques d'approbation des merge requests {#best-practices-for-using-security-scanners-with-merge-request-approval-policies}

Lorsque vous créez un nouveau projet, vous pouvez appliquer à la fois des politiques d'approbation des merge requests et des scans de sécurité sur ce projet. Cependant, des scanners de sécurité mal configurés peuvent affecter les politiques d'approbation des merge requests.

Il existe plusieurs façons de configurer les scans de sécurité dans les nouveaux projets :

- Dans la configuration CI/CD du projet en ajoutant les scanners au fichier de configuration initial `.gitlab-ci.yml`.
- Dans une politique d'exécution de scan pour imposer que les pipelines exécutent des scanners de sécurité spécifiques.
- Dans une politique d'exécution de pipeline pour contrôler quels jobs doivent s'exécuter dans les pipelines.

Pour les cas d'utilisation simples, vous pouvez utiliser la configuration CI/CD du projet. Pour une stratégie de sécurité complète, envisagez de combiner les politiques d'approbation des merge requests avec les autres types de politiques.

Pour minimiser les exigences d'approbation inutiles et garantir des évaluations de sécurité précises :

- **Run security scans on your default branch first** : Avant de créer des branches de fonctionnalité, assurez-vous que les scans de sécurité se sont exécutés avec succès sur votre branche par défaut.
- **Use consistent scanner configuration** : Exécutez les mêmes scanners dans les branches source et cible, de préférence dans un seul pipeline.
- **Verify that scans produce artifacts** : Assurez-vous que les scans se terminent avec succès et produisent des artefacts pour la comparaison.
- **Keep branches synchronized** : Fusionnez régulièrement les modifications de la branche par défaut dans les branches de fonctionnalité.
- **Consider pipeline configurations** : Pour les nouveaux projets, incluez les scanners de sécurité dans votre configuration initiale `.gitlab-ci.yml`.

### Vérifiez les scanners de sécurité avant d'appliquer les politiques d'approbation des merge requests {#verify-security-scanners-before-you-apply-merge-request-approval-policies}

En implémentant vos scans de sécurité dans votre nouveau projet avant d'appliquer une politique d'approbation des merge requests, vous pouvez vous assurer que les scanners de sécurité s'exécutent de manière cohérente avant de vous fier aux politiques d'approbation des merge requests, ce qui permet d'éviter les situations où les merge requests sont bloquées en raison de scans de sécurité manquants.

Pour créer et vérifier vos scanners de sécurité et vos politiques d'approbation des merge requests ensemble, utilisez ce workflow recommandé :

1. Créez le projet.
1. Configurez les scanners de sécurité à l'aide de la configuration `.gitlab-ci.yml`, d'une politique d'exécution de scan ou d'une politique d'exécution de pipeline.
1. Attendez que le pipeline initial se termine sur la branche par défaut. Résolvez les éventuels problèmes et relancez le pipeline pour vous assurer qu'il se termine correctement avant de continuer.
1. Créez des merge requests à l'aide de branches de fonctionnalité avec les mêmes scanners de sécurité configurés. Assurez-vous également que les scanners de sécurité se terminent correctement.
1. Appliquez vos politiques d'approbation des merge requests.

## Merge request avec plusieurs pipelines {#merge-request-with-multiple-pipelines}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/379108) dans GitLab 16.2 [avec un indicateur](../../../administration/feature_flags/_index.md) nommé `multi_pipeline_scan_result_policies`. Désactivé par défaut.
- [Disponible en général](https://gitlab.com/gitlab-org/gitlab/-/issues/409482) dans GitLab 16.3. L'indicateur de fonctionnalité `multi_pipeline_scan_result_policies` a été supprimé.
- La prise en charge des pipelines parent-enfant a été [introduite](https://gitlab.com/gitlab-org/gitlab/-/issues/428591) dans GitLab 16.11 [avec un indicateur](../../../administration/feature_flags/_index.md) nommé `approval_policy_parent_child_pipeline`. Désactivé par défaut.
- [Activé sur GitLab.com](https://gitlab.com/gitlab-org/gitlab/-/issues/451597) dans GitLab 17.0.
- [Disponible en général](https://gitlab.com/gitlab-org/gitlab/-/issues/428591) dans GitLab 17.1. L'indicateur de fonctionnalité `approval_policy_parent_child_pipeline` a été supprimé.

{{< /history >}}

Un projet peut avoir plusieurs types de pipeline configurés. Un seul commit peut initier plusieurs pipelines, chacun pouvant contenir un scan de sécurité.

- Dans GitLab 16.3 et versions ultérieures, les résultats de tous les pipelines terminés pour le dernier commit dans la branche source et cible de la merge request sont évalués et utilisés pour appliquer la politique d'approbation des merge requests. Les pipelines DAST à la demande ne sont pas pris en compte.
- Dans GitLab 16.2 et versions antérieures, seuls les résultats du dernier pipeline terminé étaient évalués lors de l'application des politiques d'approbation des merge requests.

Si un projet utilise des [pipelines de merge request](../../../ci/pipelines/merge_request_pipelines.md), vous devez définir la variable CI/CD `AST_ENABLE_MR_PIPELINES` sur `"true"` pour que les jobs de scan de sécurité soient présents dans le pipeline. Pour plus d'informations, consultez [Utiliser les outils de scan de sécurité avec les pipelines de merge request](../detect/security_configuration.md#use-security-scanning-tools-with-merge-request-pipelines).

Pour les projets où de nombreux pipelines ont été exécutés sur le dernier commit (par exemple, les projets dormants), l'évaluation de la politique prend en compte un maximum de 1 000 pipelines des branches source et cible de la merge request.

Pour les pipelines parent-enfant, l'évaluation de la politique prend en compte un maximum de 1 000 pipelines enfant.

## Éditeur de politique d'approbation des merge requests {#merge-request-approval-policy-editor}

> [!note]
> Seuls les propriétaires de projet disposent des [permissions](../../permissions.md#project-permissions) nécessaires pour sélectionner un projet de politique de sécurité.

Une fois votre politique complète, enregistrez-la en sélectionnant **Configurer avec une requête de fusion** en bas de l'éditeur. Cette action vous redirige vers la merge request dans le projet de politique de sécurité configuré du projet. Si un projet de politique de sécurité n'est pas lié à votre projet, GitLab en crée un pour vous. Les politiques existantes peuvent également être supprimées depuis l'interface de l'éditeur en sélectionnant **Supprimer une politique** en bas de l'éditeur.

La plupart des modifications de politique prennent effet dès que la merge request est fusionnée. Toute modification qui ne passe pas par une merge request et qui est commitée directement sur la branche par défaut peut nécessiter jusqu'à 10 minutes avant que les modifications de politique prennent effet.

L'[éditeur de politique](_index.md#policy-editor) prend en charge le mode YAML et le mode règle.

> [!note]
> La propagation des politiques d'approbation des merge requests créées pour des groupes comportant un grand nombre de projets prend un certain temps.

## Schéma des politiques d'approbation des merge requests {#merge-request-approval-policies-schema}

Le fichier YAML contenant les politiques d'approbation des merge requests est constitué d'un tableau d'objets correspondant au schéma de politique d'approbation des merge requests, imbriqué sous la clé `approval_policy`. Vous pouvez configurer un maximum de cinq politiques sous la clé `approval_policy`.

> [!note]
> Les politiques d'approbation des merge requests étaient définies sous la clé `scan_result_policy`. Jusqu'à GitLab 17.0, les politiques peuvent être définies sous les deux clés. À partir de GitLab 17.0, seule la clé `approval_policy` est prise en charge.

Lorsque vous enregistrez une nouvelle politique, GitLab valide son contenu par rapport à [ce schéma JSON](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/app/validators/json_schemas/security_orchestration_policy.json). Si vous n'êtes pas familier avec la lecture des [schémas JSON](https://json-schema.org/), les sections et tableaux suivants constituent une alternative.

| Champ             | Type                                     | Obligatoire | Description                                          |
|-------------------|------------------------------------------|----------|------------------------------------------------------|
| `approval_policy` | `array` d'objets de politique d'approbation des merge requests | true     | Liste des politiques d'approbation des merge requests (maximum 5). |

## Schéma de politique d'approbation des merge requests {#merge-request-approval-policy-schema}

{{< history >}}

- Le champ `enforcement_type` :
  - [Introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/202746) dans GitLab 18.4 [avec l'indicateur](../../../administration/feature_flags/_index.md) nommé `security_policy_approval_warn_mode`.
  - [Activé sur GitLab.com](https://gitlab.com/gitlab-org/gitlab/-/issues/505352) dans GitLab 18.6. L'indicateur de fonctionnalité `security_policy_approval_warn_mode` a été supprimé.
  - [En disponibilité générale](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/221747) dans GitLab 18.9. L'indicateur de fonctionnalité `security_policy_approval_warn_mode` a été supprimé.

{{< /history >}}

| Champ               | Type               | Obligatoire | Valeurs possibles | Description                                              |
|---------------------|--------------------|----------|-----------------|----------------------------------------------------------|
| `name`              | `string`           | true     |                 | Nom de la politique. Maximum de 255 caractères.           |
| `description`       | `string`           | false    |                 | Description de la politique.                               |
| `enabled`           | `boolean`          | true     | `true`, `false` | Indicateur pour activer (`true`) ou désactiver (`false`) la politique. |
| `rules`             | `array` de règles   | true     |                 | Liste des règles que la politique applique.                   |
| `actions`           | `array` d'actions | false    |                 | Liste des actions que la politique applique.                |
| `approval_settings` | `object`           | false    |                 | Paramètres du projet que la politique remplace.              |
| `fallback_behavior` | `object`           | false    |                 | Paramètres affectant les règles invalides ou non applicables.     |
| `policy_scope`      | `object` de [`policy_scope`](_index.md#configure-the-policy-scope) | false |  | Définit la portée de la politique en fonction des projets, groupes ou labels de cadre de conformité que vous spécifiez. |
| `policy_tuning`     | `object`           | false    |                 | (Expérimental) Paramètres affectant la logique de comparaison de politique.     |
| `bypass_settings`   | `object`           | false    |                 | Paramètres définissant quand certaines branches, jetons ou comptes peuvent contourner une politique.     |
| `enforcement_type`  | `string`           | false    | `enforce`, `warn` | Définit la manière dont la politique est appliquée. La valeur par défaut (si non spécifiée) est `enforce`, ce qui bloque les merge requests lorsque des violations sont détectées. La valeur `warn` permet aux merge requests de continuer mais affiche des avertissements et des commentaires de bot. |

## Type de règle `scan_finding` {#scan_finding-rule-type}

{{< history >}}

- Champ de politique d'approbation des merge requests `vulnerability_attributes` :
  - [Introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/123052) dans GitLab 16.2 [avec un indicateur](../../../administration/feature_flags/_index.md) nommé `enforce_vulnerability_attributes_rules`.
  - [Disponible en général](https://gitlab.com/gitlab-org/gitlab/-/issues/418784) dans GitLab 16.3. Feature flag supprimé.
- Le champ `vulnerability_age` de politique d'approbation des merge requests a été [ajouté](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/123956) dans GitLab 16.2.
- Le champ `branch_exceptions` :
  - [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/418741) dans GitLab 16.3 [avec un indicateur](../../../administration/feature_flags/_index.md) nommé `security_policies_branch_exceptions`.
  - [Disponible en général](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/133753) dans GitLab 16.5. Feature flag supprimé.
- L'option `newly_detected` de `vulnerability_states` a été [supprimée](https://gitlab.com/gitlab-org/gitlab/-/issues/422414) dans GitLab 17.0 et les options `new_needs_triage` et `new_dismissed` ont été ajoutées pour la remplacer.

{{< /history >}}

Cette règle applique les actions définies en fonction des résultats de scan de sécurité.

| Champ                      | Type                | Obligatoire                                   | Valeurs possibles                                                                                                    | Description |
|----------------------------|---------------------|--------------------------------------------|--------------------------------------------------------------------------------------------------------------------|-------------|
| `type`                     | `string`            | true                                       | `scan_finding`                                                                                                     | Le type de la règle. |
| `branches`                 | `array` de `string` | true si le champ `branch_type` n'existe pas | `[]` ou le nom de la branche                                                                                          | Applicable uniquement aux branches cibles protégées. Un tableau vide, `[]`, applique la règle à toutes les branches cibles protégées. Ne peut pas être utilisé avec le champ `branch_type`. |
| `branch_type`              | `string`            | true si le champ `branches` n'existe pas    | `default` ou `protected`                                                                                           | Les types de branches protégées auxquels la politique donnée s'applique. Ne peut pas être utilisé avec le champ `branches`. Les branches par défaut doivent également être `protected`. |
| `branch_exceptions`        | `array` de `string` | false                                      | Noms des branches                                                                                                  | Branches cibles à exclure de cette règle. |
| `scanners`                 | `array` de `string` ou objets [`scanner_with_attributes`](#scanner_with_attributes-object) | true | `[]` ou `sast`, `secret_detection`, `dependency_scanning`, `container_scanning`, `dast`, `coverage_fuzzing`, `api_fuzzing` | Les scanners de sécurité à prendre en compte pour cette règle. `sast` inclut les résultats des scanners SAST et SAST IaC. Un tableau vide, `[]`, applique la règle à tous les scanners de sécurité. Spécifiez le scanner sous forme de chaîne (pour appliquer les paramètres au niveau de la règle) ou d'objet (avec des remplacements par scanner pour `severity_levels`, `vulnerabilities_allowed` et `vulnerability_attributes`). |
| `vulnerabilities_allowed`  | `integer`           | true                                       | Supérieur ou égal à zéro                                                                                      | Nombre de vulnérabilités autorisées avant que cette règle ne soit prise en compte. |
| `severity_levels`          | `array` de `string` | true                                       | `info`, `unknown`, `low`, `medium`, `high`, `critical`                                                             | Les niveaux de gravité à prendre en compte pour cette règle. |
| `vulnerability_states`     | `array` de `string` | true                                       | `[]` ou `detected`, `confirmed`, `resolved`, `dismissed`, `new_needs_triage`, `new_dismissed`                      | Toutes les vulnérabilités se répartissent en deux catégories :<br><br>**Newly Detected Vulnerabilities** \- Vulnérabilités identifiées dans la branche de la merge request elle-même mais qui n'existent pas actuellement sur la branche cible de la merge request. Cette option de politique nécessite qu'un pipeline se termine avant que la règle ne soit évaluée afin de savoir si les vulnérabilités sont nouvellement détectées ou non. Les merge requests sont bloquées jusqu'à ce que le pipeline et les scans de sécurité nécessaires soient terminés. L'option `new_needs_triage` prend en compte le statut<br><br> • Détecté<br><br> L'option `new_dismissed` prend en compte le statut<br><br> • Rejeté<br><br>**Pre-Existing Vulnerabilities** \- ces options de politique sont évaluées immédiatement et ne nécessitent pas qu'un pipeline se termine, car elles ne prennent en compte que les vulnérabilités précédemment détectées dans la branche par défaut.<br><br> • `Detected` - la politique recherche les vulnérabilités à l'état détecté.<br> • `Confirmed` - la politique recherche les vulnérabilités à l'état confirmé.<br> • `Dismissed` - la politique recherche les vulnérabilités à l'état rejeté.<br> • `Resolved` - la politique recherche les vulnérabilités à l'état résolu. <br><br>Un tableau vide, `[]`, couvre les mêmes statuts que `['new_needs_triage', 'new_dismissed']`. |
| `vulnerability_attributes` | `object`            | false                                      | objet [`vulnerability_attributes`](#vulnerability_attributes-object) | Tous les résultats de vulnérabilité sont pris en compte par défaut. Appliquez ces filtres pour ne prendre en compte que les résultats de vulnérabilité correspondant à des critères spécifiques. Consultez [l'objet `vulnerability_attributes`](#vulnerability_attributes-object) pour plus de détails. |
| `vulnerability_age`        | `object`            | false                                      | N/A                                                                                                                | Filtrer les résultats de vulnérabilité préexistants par ancienneté. L'ancienneté d'une vulnérabilité est calculée à partir du moment où elle a été détectée dans le projet. Les critères sont `operator`, `value` et `interval`.<br>\- Le critère `operator` indique si la comparaison d'ancienneté utilisée est plus ancien que (`greater_than`) ou plus récent que (`less_than`).<br>\- Le critère `value` spécifie la valeur numérique représentant l'ancienneté de la vulnérabilité.<br>\- Le critère `interval` spécifie l'unité de mesure de l'ancienneté de la vulnérabilité : `day`, `week`, `month` ou `year`.<br><br>Exemple : `operator: greater_than`, `value: 30`, `interval: day`. |

### Objet `vulnerability_attributes` {#vulnerability_attributes-object}

{{< history >}}

- Les champs `known_exploited`, `epss_score` et `enrichment_data_unavailable` ont été [introduits](https://gitlab.com/gitlab-org/gitlab/-/issues/576860) dans GitLab 18.11 [avec un feature flag](../../../administration/feature_flags/_index.md) nommé `security_policies_kev_filter`. Désactivé par défaut.
- [Disponible en général](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/229501) dans GitLab 19.1. L'indicateur de fonctionnalité `security_policies_kev_filter` a été supprimé.

{{< /history >}}

| Champ                        | Type                 | Obligatoire | Valeurs possibles                                              | Description |
|------------------------------|----------------------|----------|--------------------------------------------------------------|-------------|
| `false_positive`             | `boolean`            | false    | `true`, `false`                                              | Filtrer par statut de faux positif. `true` inclut uniquement les faux positifs ; `false` les exclut. |
| `fix_available`              | `boolean`            | false    | `true`, `false`                                              | Filtrer par disponibilité d'un correctif. `true` inclut uniquement les vulnérabilités pour lesquelles un correctif est disponible ; `false` inclut uniquement celles qui n'en ont pas. |
| `known_exploited`            | `boolean` | false    | `true`, `false`                               | Filtrer en fonction du catalogue [CISA Known Exploited Vulnerabilities (KEV)](https://www.cisa.gov/known-exploited-vulnerabilities-catalog). Lorsque true, inclut uniquement les vulnérabilités qui sont activement exploitées dans la nature. Lorsque false, ne filtre pas les vulnérabilités en fonction du statut d'exploit connu. |
| `epss_score`                 | `object` | false    | Objet `{operator, value}`                    | Filtrer en fonction du score [Exploit Prediction Scoring System (EPSS)](https://www.first.org/epss/). EPSS estime la probabilité (de 0 à 1) qu'une vulnérabilité soit exploitée. En tant qu'objet : `operator` peut être `greater_than` ou `less_than` ; `value` est un nombre compris entre `0.0` et `1.0`. Exemple : `{operator: greater_than, value: 0.8}`.  |
| `enrichment_data_unavailable`| `object`             | false    | `{action: "block"}` ou `{action: "ignore"}`                  | Définissez comment gérer les vulnérabilités CVE dont les données d'enrichissement sont indisponibles (score EPSS manquant ou statut d'exploit connu manquant). Avec 'block', les vulnérabilités sans données d'enrichissement sont évaluées selon les critères au niveau de la règle. Avec 'ignore', les vulnérabilités sans données d'enrichissement sont exclues de l'évaluation de la politique. |

### Objet `scanner_with_attributes` {#scanner_with_attributes-object}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/584704) dans GitLab 18.10 [avec un indicateur](../../../administration/feature_flags/_index.md) nommé `atomic_scanner_rule_criteria`. Activé par défaut. [En disponibilité générale](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/230346) dans GitLab 18.11. Feature flag supprimé.

{{< /history >}}

> [!flag]
> La disponibilité de cette fonctionnalité est contrôlée par un feature flag. Pour plus d'informations, consultez l'historique.

Lorsqu'un scanner est spécifié sous forme d'objet plutôt que de chaîne, chaque type de scanner est évalué indépendamment avec ses propres critères. Tout champ non spécifié au niveau du scanner revient au paramètre défini par la valeur au niveau de la règle.

| Champ                      | Type                | Obligatoire | Valeurs possibles                                                                   | Description |
|----------------------------|---------------------|----------|-----------------------------------------------------------------------------------|-------------|
| `type`                     | `string`            | true     | `sast`, `secret_detection`, `dependency_scanning`, `container_scanning`, `dast`, `coverage_fuzzing`, `api_fuzzing` | Le type de scanner. |
| `severity_levels`          | `array` de `string` | false    | `info`, `unknown`, `low`, `medium`, `high`, `critical`                            | Remplace le `severity_levels` au niveau de la règle pour ce scanner. |
| `vulnerabilities_allowed`  | `integer`           | false    | Supérieur ou égal à zéro                                                     | Remplace le `vulnerabilities_allowed` au niveau de la règle pour ce scanner. |
| `vulnerability_attributes` | `object`            | false    | objet [`vulnerability_attributes`](#vulnerability_attributes-object)              | Remplace le `vulnerability_attributes` au niveau de la règle pour ce scanner. |

Exemple utilisant des critères par scanner :

```yaml
rules:
  - type: scan_finding
    branches: []
    scanners:
      - type: dependency_scanning
        vulnerability_attributes:
          fix_available: true
        vulnerabilities_allowed: 0
        severity_levels:
          - critical
          - high
      - type: container_scanning
        vulnerability_attributes:
          known_exploited: true
          epss_score:
             value: 0.5
             operator: greater_than
          enrichment_data_unavailable:
             action: block
        vulnerabilities_allowed: 0
        severity_levels:
          - critical
    vulnerabilities_allowed: 5
    severity_levels:
      - critical
      - high
      - medium
    vulnerability_states:
      - new_needs_triage
```

Dans cet exemple :

- **Analyse des dépendances** requiert une approbation si une vulnérabilité de gravité critique ou élevée avec un correctif disponible est détectée.
- **Analyse de conteneurs** requiert une approbation si une vulnérabilité critique et connue comme exploitée est détectée.
- Chaque scanner est évalué indépendamment par rapport à ses propres seuils. Le `vulnerabilities_allowed: 5` et les `severity_levels` au niveau de la règle servent de valeurs par défaut pour tout scanner sans remplacements explicites.

## Type de règle `license_finding` {#license_finding-rule-type}

{{< history >}}

- [Introduit](https://gitlab.com/groups/gitlab-org/-/epics/8092) dans GitLab 15.9 [avec un indicateur](../../../administration/feature_flags/_index.md) nommé `license_scanning_policies`.
- [Disponible en général](https://gitlab.com/gitlab-org/gitlab/-/issues/397644) dans GitLab 15.11. L'indicateur de fonctionnalité `license_scanning_policies` a été supprimé.
- Le champ `branch_exceptions` a été [introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/418741) dans GitLab 16.3 [avec un indicateur](../../../administration/feature_flags/_index.md) nommé `security_policies_branch_exceptions`. Activé par défaut. [Disponible en général](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/133753) dans GitLab 16.5. Feature flag supprimé.
- Le champ `licenses` a été [introduit](https://gitlab.com/groups/gitlab-org/-/epics/10203) dans GitLab 17.11 [avec un indicateur](../../../administration/feature_flags/_index.md) nommé `exclude_license_packages`. Feature flag supprimé.

{{< /history >}}

Cette règle applique les actions définies en fonction des résultats de licences.

| Champ          | Type     | Obligatoire                                      | Valeurs possibles              | Description                                                                                                                                                                                                         |
|----------------|----------|-----------------------------------------------|------------------------------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `type`         | `string` | true                                          | `license_finding`            | Le type de la règle.                                                                                                                                                                                                    |
| `branches`     | `array` de `string` | true si le champ `branch_type` n'existe pas    | `[]` ou le nom de la branche    | Applicable uniquement aux branches cibles protégées. Un tableau vide, `[]`, applique la règle à toutes les branches cibles protégées. Ne peut pas être utilisé avec le champ `branch_type`.                                                 |
| `branch_type`  | `string` | true si le champ `branches` n'existe pas       | `default` ou `protected`     | Les types de branches protégées auxquels la politique donnée s'applique. Ne peut pas être utilisé avec le champ `branches`. Les branches par défaut doivent également être `protected`.                                                                   |
| `branch_exceptions` | `array` de `string` | false                                         | Noms des branches            | Branches cibles à exclure de cette règle.                                                                                                                                                                                 |
| `match_on_inclusion_license` | `boolean` | true si le champ `licenses` n'existe pas      | `true`, `false`              | Indique si la règle correspond à l'inclusion ou à l'exclusion des licences listées dans `license_types`.                                                                                                                              |
| `license_types` | `array` de `string` | true si le champ `licenses` n'existe pas      | types de licences                | [Noms de licences SPDX](https://spdx.org/licenses) sur lesquels effectuer la correspondance, par exemple `Affero General Public License v1.0` ou `MIT License`.                                                                                     |
| `license_states` | `array` de `string` | true                                          | `newly_detected`, `detected` | Indique si la correspondance porte sur les licences nouvellement détectées et/ou précédemment détectées. L'état `newly_detected` déclenche une approbation lorsqu'un nouveau package est introduit ou lorsqu'une nouvelle licence pour un package existant est détectée. |
| `licenses`     | `object` | true si le champ `license_types` n'existe pas | Objet `licenses`            | [Noms de licences SPDX](https://spdx.org/licenses) sur lesquels effectuer la correspondance, y compris les exceptions de package.                                                                                                                        |

### Objet `licenses` {#licenses-object}

| Champ     | Type     | Obligatoire                                | Valeurs possibles                                      | Description                                                |
|-----------|----------|-----------------------------------------|------------------------------------------------------|------------------------------------------------------------|
| `denied`  | `object` | true si le champ `allowed` n'existe pas | `array` d'objets `licenses_with_package_exclusion`  | La liste des licences refusées, y compris les exceptions de package.  |
| `allowed` | `object` | true si le champ `denied` n'existe pas  | `array` d'objets `licenses_with_package_exclusion`  | La liste des licences autorisées, y compris les exceptions de package. |

### Objet `licenses_with_package_exclusion` {#licenses_with_package_exclusion-object}

Utilisez l'objet `licenses_with_package_exclusion` pour définir un nom de licence et des exclusions de package facultatives.

| Champ  | Type     | Obligatoire | Valeurs possibles   | Description                                        |
|--------|----------|----------|-------------------|----------------------------------------------------|
| `name` | `string` | true     | Nom de licence SPDX | [Nom de licence SPDX](https://spdx.org/licenses).    |
| `packages` | `object` | false    | Objet `packages` | Liste des exceptions de package pour la licence donnée. |

> [!note]
> Le champ `name` doit être un [nom de licence SPDX](https://spdx.org/licenses) valide. La valeur `unknown` n'est pas un nom de licence SPDX reconnu et n'est pas prise en charge dans le champ `licenses`. Les exclusions au niveau du package configurées pour les licences `unknown` sont ignorées lors de l'évaluation de l'approbation des merge requests. Pour gérer les packages avec des licences `unknown`, utilisez le champ [`license_types`](#license_finding-rule-type) ou autorisez `unknown` comme licence dans votre politique. Pour plus d'informations, consultez [les politiques d'approbation de licences bloquant les merge requests en raison de licences `unknown`](../../compliance/license_approval_policies.md#license-approval-policies-block-merge-requests-due-to-unknown-licenses).

### Objet `packages` {#packages-object}

Utilisez l'objet `packages` pour définir des exclusions d'URL de package pour une entrée de licence.

| Champ  | Type     | Obligatoire | Valeurs possibles                                       | Description                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                |
|--------|----------|----------|-------------------------------------------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `excluding` | `object` | true     | {purls : `array` de `strings` au format `uri`} | Liste des exceptions de package pour la licence donnée. Définissez la liste des exceptions de package à l'aide des composants [`purl`](https://github.com/package-url/purl-spec?tab=readme-ov-file#purl) `scheme:type/name@version`. Les composants `scheme:type/name` sont obligatoires. `@` et `version` sont facultatifs. Si une version est spécifiée, seule cette version est considérée comme une exception. Si aucune version n'est spécifiée et que le caractère `@` est ajouté à la fin du `purl`, seuls les packages portant le nom exact sont considérés comme une correspondance. Si le caractère `@` n'est pas ajouté au nom du package, tous les packages ayant le même préfixe pour la licence donnée sont des correspondances. Par exemple, un purl `pkg:gem/bundler` correspond aux packages `bundler` et `bundler-stats` car les deux packages utilisent la même licence. La définition d'un `purl` `pkg:gem/bundler@` correspond uniquement au package `bundler`. |

## Type de règle `any_merge_request` {#any_merge_request-rule-type}

{{< history >}}

- Le champ `branch_exceptions` a été [introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/418741) dans GitLab 16.3 [avec un indicateur](../../../administration/feature_flags/_index.md) nommé `security_policies_branch_exceptions`. Activé par défaut. [Disponible en général](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/133753) dans GitLab 16.5. Feature flag supprimé.
- Le type de règle `any_merge_request` a été [introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/418752) dans GitLab 16.4. Activé par défaut. [Disponible en général](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/136298) dans GitLab 16.6. Feature flag [supprimé](https://gitlab.com/gitlab-org/gitlab/-/issues/432127).

{{< /history >}}

Cette règle applique les actions définies pour toute merge request en fonction de la signature des commits.

| Champ               | Type                | Obligatoire                                   | Valeurs possibles           | Description |
|---------------------|---------------------|--------------------------------------------|---------------------------|-------------|
| `type`              | `string`            | true                                       | `any_merge_request`       | Le type de la règle. |
| `branches`          | `array` de `string` | true si le champ `branch_type` n'existe pas | `[]` ou le nom de la branche | Applicable uniquement aux branches cibles protégées. Un tableau vide, `[]`, applique la règle à toutes les branches cibles protégées. Ne peut pas être utilisé avec le champ `branch_type`. |
| `branch_type`       | `string`            | true si le champ `branches` n'existe pas    | `default` ou `protected`  | Les types de branches protégées auxquels la politique donnée s'applique. Ne peut pas être utilisé avec le champ `branches`. Les branches par défaut doivent également être `protected`. |
| `branch_exceptions` | `array` de `string` | false                                      | Noms des branches         | Branches cibles à exclure de cette règle. |
| `commits`           | `string`            | true                                       | `any`, `unsigned`         | Indique si la règle s'applique à tous les commits, ou uniquement si des commits non signés sont détectés dans la merge request. |

## Type d'action `require_approval` {#require_approval-action-type}

{{< history >}}

- Prise en charge de la spécification de jusqu'à cinq actions `require_approval` distinctes :
  - [Ajouté](https://gitlab.com/groups/gitlab-org/-/epics/12319) dans GitLab 17.7 [avec un indicateur](../../../administration/feature_flags/_index.md) nommé `multiple_approval_actions`.
  - [Disponible en général](https://gitlab.com/gitlab-org/gitlab/-/issues/505374) dans GitLab 17.8. L'indicateur de fonctionnalité `multiple_approval_actions` a été supprimé.
- Prise en charge de la spécification de rôles personnalisés en tant que `role_approvers` :
  - [Introduit](https://gitlab.com/groups/gitlab-org/-/epics/13550) dans GitLab 17.9 [avec un indicateur](../../../administration/feature_flags/_index.md) nommé `security_policy_custom_roles`. Activé par défaut.
  - [Disponible en général](https://gitlab.com/gitlab-org/gitlab/-/issues/505742) dans GitLab 17.10. L'indicateur de fonctionnalité `security_policy_custom_roles` a été supprimé.

{{< /history >}}

Cette action rend une règle d'approbation obligatoire lorsque les conditions sont remplies pour au moins une règle dans la politique définie.

Si vous spécifiez plusieurs approbateurs dans le même bloc `require_approval`, l'un des approbateurs éligibles peut satisfaire l'exigence d'approbation. Par exemple, si vous spécifiez deux `group_approvers` et `approvals_required` comme `2`, les deux approbations peuvent provenir du même groupe. Pour exiger plusieurs approbations de types d'approbateurs uniques, utilisez plusieurs actions `require_approval`.

| Champ | Type | Obligatoire | Valeurs possibles | Description |
|-------|------|----------|-----------------|-------------|
| `type` | `string` | true | `require_approval` | Le type de l'action. |
| `approvals_required` | `integer` | true | Supérieur ou égal à zéro | Le nombre d'approbations de merge request requises. |
| `user_approvers` | `array` de `string` | Conditionnel | Nom d'utilisateur d'un ou plusieurs utilisateurs | Les utilisateurs à considérer comme approbateurs. Les utilisateurs doivent avoir accès au projet pour être éligibles à l'approbation. |
| `user_approvers_ids` | `array` de `integer` | Conditionnel <sup>1</sup> | ID d'un ou plusieurs utilisateurs | Les ID des utilisateurs à considérer comme approbateurs. Les utilisateurs doivent avoir accès au projet pour être éligibles à l'approbation. |
| `group_approvers` | `array` de `string` | Conditionnel <sup>1</sup> | Chemin d'un ou plusieurs groupes | Les groupes à considérer comme approbateurs. Les utilisateurs avec [une adhésion directe au groupe](../../project/merge_requests/approvals/rules.md#group-approvers) sont éligibles à l'approbation. |
| `group_approvers_ids` | `array` de `integer` | Conditionnel <sup>1</sup> | ID d'un ou plusieurs groupes | Les ID des groupes à considérer comme approbateurs. Les utilisateurs avec [une adhésion directe au groupe](../../project/merge_requests/approvals/rules.md#group-approvers) sont éligibles à l'approbation. |
| `role_approvers` | `array` de `string` | Conditionnel <sup>1</sup> | Un ou plusieurs [rôles](../../permissions.md#roles) (par exemple : `owner`, `maintainer`). Vous pouvez également spécifier des rôles personnalisés (ou des identifiants de rôle personnalisé en mode YAML) en tant que `role_approvers` si les rôles personnalisés ont la permission d'approuver les merge requests. Les rôles personnalisés peuvent être sélectionnés avec les approbateurs d'utilisateurs et de groupes. | Les rôles éligibles à l'approbation. Seuls les utilisateurs ayant exactement le rôle que vous spécifiez, ou les utilisateurs ayant un rôle personnalisé basé sur ce rôle, peuvent approuver. Les rôles avec des privilèges plus élevés ne peuvent pas approuver. Par exemple, si vous sélectionnez `developer`, les utilisateurs avec le rôle Développeur peuvent approuver. Si un rôle personnalisé basé sur `developer` existe, les utilisateurs ayant ce rôle personnalisé peuvent également approuver. Les Mainteneurs et les Propriétaires ne peuvent pas approuver sauf si vous les ajoutez également. |

**Footnotes:**

1. Vous devez spécifier au moins un approbateur à l'aide des champs d'approbateur (`user_approvers`, `user_approvers_ids`, `group_approvers`, `group_approvers_ids` ou `role_approvers`).

### Exemples de configuration valide {#valid-configuration-examples}

**`user_approvers` valide :**

```yaml
actions:
  - type: require_approval
    approvals_required: 2
    user_approvers:
      - alice
      - bob
```

**`group_approvers` valide :**

```yaml
actions:
  - type: require_approval
    approvals_required: 1
    group_approvers:
      - security-team
```

**`role_approvers` valide :**

```yaml
actions:
  - type: require_approval
    approvals_required: 1
    role_approvers:
      - maintainer
```

**Valid with multiple approver types:**

```yaml
actions:
  - type: require_approval
    approvals_required: 2
    user_approvers:
      - alice
    group_approvers:
      - security-team
    role_approvers:
      - maintainer
```

### Exemple de configuration invalide {#invalid-configuration-example}

**Invalid because no approvers specified:**

```yaml
actions:
  - type: require_approval
    approvals_required: 2
    # ERROR: At least one approver field must be specified
    # This configuration will fail validation
```

## Type d'action `send_bot_message` {#send_bot_message-action-type}

{{< history >}}

- Le type d'action `send_bot_message` pour les projets :
  - [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/438269) dans GitLab 16.11 [avec un flag](../../../administration/feature_flags/_index.md) nommé `approval_policy_disable_bot_comment`. Désactivé par défaut.
  - [Activé sur GitLab Self-Managed et GitLab Dedicated](https://gitlab.com/gitlab-org/gitlab/-/issues/454852) dans GitLab 17.0.
  - [En disponibilité générale](https://gitlab.com/gitlab-org/gitlab/-/issues/454852) dans GitLab 17.3. L'indicateur de fonctionnalité `approval_policy_disable_bot_comment` a été supprimé.
- Le type d'action `send_bot_message` pour les groupes :
  - [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/469449) dans GitLab 17.2 [avec un indicateur](../../../administration/feature_flags/_index.md) nommé `approval_policy_disable_bot_comment_group`. Désactivé par défaut.
  - [Activé sur GitLab Self-Managed et GitLab Dedicated](https://gitlab.com/gitlab-org/gitlab/-/issues/469449) dans GitLab 17.2.
  - [En disponibilité générale](https://gitlab.com/gitlab-org/gitlab/-/issues/469449) dans GitLab 17.3. L'indicateur de fonctionnalité `approval_policy_disable_bot_comment_group` a été supprimé.

{{< /history >}}

Cette action permet de configurer le message du bot dans les merge requests lorsque des violations de politique sont détectées. Si l'action n'est pas spécifiée, le message du bot est activé par défaut. Si plusieurs politiques sont définies, le message du bot est envoyé tant qu'au moins l'une de ces politiques a l'action `send_bot_message` activée.

| Champ | Type | Obligatoire | Valeurs possibles | Description |
|-------|------|----------|-----------------|-------------|
| `type` | `string` | true | `send_bot_message` | Le type de l'action. |
| `enabled` | `boolean` | true | `true`, `false` | Indique si un message de bot doit être créé lorsque des violations de politique sont détectées. Par défaut : `true` |

### Exemples de messages de bot {#example-bot-messages}

![Exemple de message de bot affichant les vulnérabilités détectées par les scans de sécurité.](img/scan_result_policy_example_bot_message_vulnerabilities_v17_0.png)

![Exemple de message de bot affichant les artefacts de scan manquants ou incomplets requis pour l'évaluation de la politique.](img/scan_result_policy_example_bot_message_artifacts_v17_0.png)

## Mode avertissement {#warn-mode}

{{< history >}}

- [Introduit](https://gitlab.com/groups/gitlab-org/-/epics/15552) dans GitLab 17.8 [avec un feature flag](../../../administration/feature_flags/_index.md) nommé `security_policy_approval_warn_mode`. Désactivé par défaut
- [Activé sur GitLab.com, GitLab Self-Managed et GitLab Dedicated](https://gitlab.com/gitlab-org/gitlab/-/issues/505352) dans GitLab 18.6.
- Prise en charge du scan de licences :
  - [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/579664) dans GitLab 18.7 [avec un feature flag](../../../administration/feature_flags/_index.md) nommé `security_policy_warn_mode_license_scanning`. Activé par défaut.
  - [En disponibilité générale](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/221747) dans GitLab 18.9. L'indicateur de fonctionnalité `security_policy_approval_warn_mode` a été supprimé.

{{< /history >}}

> [!flag]
> La disponibilité de cette fonctionnalité est contrôlée par un feature flag. Pour plus d'informations, consultez l'historique.

Le mode avertissement permet aux équipes de sécurité de tester et de valider l'impact des politiques de sécurité avant d'appliquer une application complète, réduisant ainsi les frictions pour les développeurs lors de l'application de nouvelles politiques de sécurité. Lorsqu'une politique est configurée avec `enforcement_type: warn`, la merge request offre la possibilité de contourner toute violation de la politique d'approbation des merge requests.

Lorsque le mode avertissement est activé (`enforcement_type: warn`) et qu'une merge request déclenche une violation de politique de sécurité, l'application de la politique diffère de plusieurs manières :

- Validation non bloquante : La politique génère des commentaires de bot informatifs listant les violations de politique.
- Approbations optionnelles : Les approbations sont optionnelles si l'utilisateur contourne la politique et fournit la justification du rejet.
- Audit renforcé : Après la fusion de la merge request avec une politique de sécurité contournée, des événements d'audit sont créés.
- Intégration au rapport de vulnérabilités : Si une vulnérabilité a été introduite par une merge request avec une politique contournée, les détails du contournement sont visibles dans le rapport de vulnérabilités.
- Intégration à la liste des dépendances : Si une merge request qui contourne une politique introduit une licence, la liste des dépendances affiche un badge de violation de politique à côté de la licence. Les badges de violation de politique sont disponibles uniquement dans la liste des dépendances pour les projets.
- Paramètres d'approbation désactivés : Les remplacements de paramètres d'approbation ne sont pas appliqués.

### Configuration du mode avertissement {#configuring-warn-mode}

Pour activer le mode avertissement pour une politique d'approbation des merge requests, définissez le champ `enforcement_type` sur `warn` :

```yaml
approval_policy:
  - name: Warn mode policy
    description: ''
    enabled: true
    enforcement_type: warn
    policy_scope:
      projects:
        excluding: []
    rules:
      - type: scan_finding
        scanners:
          - secret_detection
        vulnerabilities_allowed: 0
        severity_levels: []
        vulnerability_states: []
        branch_type: protected
    actions:
      - type: require_approval
        approvals_required: 1
        role_approvers:
          - developer
          - maintainer
      - type: send_bot_message
        enabled: true
```

## `approval_settings` {#approval_settings}

{{< history >}}

- Le champ `block_group_branch_modification` :
  - [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/420724) dans GitLab 16.8 [avec l'indicateur](../../../administration/feature_flags/_index.md) nommé `scan_result_policy_block_group_branch_modification`.
  - [Activé sur GitLab.com et GitLab Self-Managed](https://gitlab.com/gitlab-org/gitlab/-/issues/437306) dans GitLab 17.6.
  - [Disponible en général](https://gitlab.com/gitlab-org/gitlab/-/issues/503930) dans GitLab 17.7. L'indicateur de fonctionnalité `scan_result_policy_block_group_branch_modification` a été supprimé.
- Le champ `block_unprotecting_branches`
  - [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/423101) dans GitLab 16.4 [avec l'indicateur](../../../administration/feature_flags/_index.md) nommé `scan_result_policy_settings`. Désactivé par défaut.
  - Le champ `block_unprotecting_branches` a été [remplacé](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/137153) par le champ `block_branch_modification` dans GitLab 16.7.
- Le feature flag `scan_result_policies_block_unprotecting_branches` a remplacé le feature flag `scan_result_policy_settings` dans la version 16.4.
  - [Activé sur GitLab.com et GitLab Self-Managed](https://gitlab.com/gitlab-org/gitlab/-/issues/423901) dans GitLab 16.7.
  - [Disponible en général](https://gitlab.com/gitlab-org/gitlab/-/issues/433415) dans GitLab 16.11. L'indicateur de fonctionnalité `scan_result_policies_block_unprotecting_branches` a été supprimé.
- Les champs `prevent_approval_by_author`, `prevent_approval_by_commit_author`, `remove_approvals_with_new_commit` et `require_password_to_approve` :
  - [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/418752) dans GitLab 16.4 [avec l'indicateur](../../../administration/feature_flags/_index.md) nommé `scan_result_any_merge_request`. Désactivé par défaut.
  - [Activé sur GitLab.com](https://gitlab.com/gitlab-org/gitlab/-/issues/423988) dans GitLab 16.6.
  - [Activé sur GitLab Self-Managed](https://gitlab.com/gitlab-org/gitlab/-/issues/423988) dans GitLab 16.7.
  - [En disponibilité générale](https://gitlab.com/gitlab-org/gitlab/-/issues/432127) dans GitLab 16.8. L'indicateur de fonctionnalité `scan_result_any_merge_request` a été supprimé.
- Le champ `prevent_pushing_and_force_pushing`
  - [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/420629) dans GitLab 16.4 [avec l'indicateur](../../../administration/feature_flags/_index.md) nommé `scan_result_policies_block_force_push`. Désactivé par défaut.
  - [Activé sur GitLab.com](https://gitlab.com/gitlab-org/gitlab/-/issues/427260) dans GitLab 16.6.
  - [Activé sur GitLab Self-Managed](https://gitlab.com/gitlab-org/gitlab/-/issues/427260) dans GitLab 16.7.
  - [Disponible en général](https://gitlab.com/gitlab-org/gitlab/-/issues/432123) dans GitLab 16.9. L'indicateur de fonctionnalité `scan_result_policies_block_force_push` a été supprimé.

{{< /history >}}

Les paramètres définis dans la politique écrasent les paramètres du projet.

| Champ                               | Type                  | Obligatoire | Valeurs possibles                                               | Type de règle applicable | Description |
|-------------------------------------|-----------------------|----------|---------------------------------------------------------------|----------------------|-------------|
| `block_branch_modification`         | `boolean`             | false    | `true`, `false`                                               | Tous                  | Lorsque cette option est activée, empêche un utilisateur de supprimer une branche de la liste des branches protégées, de supprimer une branche protégée ou de modifier la branche par défaut si cette branche est incluse dans la politique de sécurité. Cela garantit que les utilisateurs ne peuvent pas supprimer le statut de protection d'une branche pour fusionner du code vulnérable. Appliqué en fonction de `branches`, `branch_type` et `policy_scope`, indépendamment des vulnérabilités détectées. |
| `block_group_branch_modification`   | `boolean` ou `object` | false    | `true`, `false`, `{ enabled: boolean, exceptions: [{ id: Integer}] }` | Tous                  | Lorsque cette option est activée, empêche un utilisateur de supprimer des branches protégées au niveau du groupe pour chaque groupe auquel la politique s'applique. Si `block_branch_modification` est `true`, la valeur par défaut implicite est `true`. Ajoutez les groupes principaux qui prennent en charge [les branches protégées au niveau du groupe](../../project/repository/branches/protected.md#in-a-group) en tant que `exceptions` |
| `prevent_approval_by_author`        | `boolean`             | false    | `true`, `false`                                               | `Any merge request`  | Lorsque cette option est activée, les auteurs de merge requests ne peuvent pas approuver leurs propres merge requests. Cela garantit que les auteurs du code ne peuvent pas introduire des vulnérabilités et approuver le code à fusionner. |
| `prevent_approval_by_commit_author` | `boolean`             | false    | `true`, `false`                                               | `Any merge request`  | Lorsque cette option est activée, les utilisateurs ayant contribué du code à la merge request ne sont pas éligibles pour l'approbation. Cela garantit que les personnes ayant effectué des commits du code ne peuvent pas introduire des vulnérabilités et approuver le code à fusionner. |
| `remove_approvals_with_new_commit`  | `boolean`             | false    | `true`, `false`                                               | `Any merge request`  | Lorsque cette option est activée, si une merge request reçoit toutes les approbations nécessaires pour être fusionnée, mais qu'un nouveau commit est ajouté, de nouvelles approbations sont requises. Cela garantit que les nouveaux commits susceptibles d'inclure des vulnérabilités ne peuvent pas être introduits. |
| `require_password_to_approve`       | `boolean`             | false    | `true`, `false`                                               | `Any merge request`  | Lorsque cette option est activée, les approbateurs doivent s'authentifier à nouveau avant d'approuver. L'approbateur peut se réauthentifier en utilisant son mot de passe ou SAML, selon sa méthode d'authentification configurée. Cela ajoute une couche de sécurité supplémentaire pour garantir l'identité de l'approbateur. Pour plus d'informations, voir [exiger la réauthentification de l'utilisateur pour approuver](../../project/merge_requests/approvals/settings.md#require-user-re-authentication-to-approve). |
| `prevent_pushing_and_force_pushing` | `boolean`             | false    | `true`, `false`                                               | Tous                  | Lorsque cette option est activée, empêche les utilisateurs d'effectuer des pushs et des pushs forcés vers une branche protégée si cette branche est incluse dans la politique de sécurité. Cela garantit que les utilisateurs ne contournent pas le processus de merge request pour ajouter du code vulnérable à une branche. La création d'une branche qui n'existe pas encore est régie par les règles standard de [branche protégée](../../project/repository/branches/protected.md) ; ce paramètre s'applique aux pushs et pushs forcés ultérieurs une fois que la branche existe. |

### Portée d'application des paramètres d'approbation {#enforcement-scope-of-approval-settings}

Ces paramètres sont appliqués uniquement aux merge requests qui présentent des violations de la politique :

- `prevent_approval_by_author`
- `prevent_approval_by_commit_author`
- `remove_approvals_with_new_commit`
- `require_password_to_approve`

Si une merge request ne présente aucune violation de politique, les paramètres n'ont aucun effet sur cette merge request.

Ces paramètres sont toujours appliqués si la politique est active, qu'une merge request présente ou non des violations de politique :

- `block_branch_modification`
- `block_group_branch_modification`
- Paramètres `prevent_pushing_and_force_pushing`

## `fallback_behavior` {#fallback_behavior}

{{< history >}}

- Le champ `fallback_behavior` :
  - [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/451784) dans GitLab 17.0 [avec un indicateur](../../../administration/feature_flags/_index.md) nommé `security_scan_result_policies_unblock_fail_open_approval_rules`. Désactivé par défaut.
  - [Activé sur GitLab.com, GitLab Self-Managed et GitLab Dedicated](https://gitlab.com/groups/gitlab-org/-/epics/10816) dans GitLab 17.0.
  - [Disponible en général](https://gitlab.com/gitlab-org/gitlab/-/issues/451784) dans GitLab 17.1. L'indicateur de fonctionnalité `security_scan_result_policies_unblock_fail_open_approval_rules` a été supprimé.

{{< /history >}}

| Champ  | Type     | Obligatoire | Valeurs possibles    | Description                                                                                                          |
|--------|----------|----------|--------------------|----------------------------------------------------------------------------------------------------------------------|
| `fail` | `string` | false    | `open` ou `closed` | `closed` (par défaut) : Les règles invalides ou inapplicables d'une politique requièrent une approbation. `open` : Les règles invalides ou inapplicables d'une politique ne requièrent pas d'approbation. |

## `policy_tuning` {#policy_tuning}

### `unblock_rules_using_execution_policies` {#unblock_rules_using_execution_policies}

{{< history >}}

- [Introduction](https://gitlab.com/gitlab-org/gitlab/-/issues/498624) de la prise en charge dans les politiques d'exécution de pipeline dans GitLab 17.10 [avec un indicateur](../../../administration/feature_flags/_index.md) nommé `unblock_rules_using_pipeline_execution_policies`. Activé par défaut.
- [Disponible en général](https://gitlab.com/gitlab-org/gitlab/-/issues/525270) dans GitLab 18.3. L'indicateur de fonctionnalité `unblock_rules_using_pipeline_execution_policies` a été supprimé.

{{< /history >}}

| Champ  | Type     | Obligatoire | Valeurs possibles    | Description                                                                                                          |
|--------|----------|----------|--------------------|----------------------------------------------------------------------------------------------------------------------|
| `unblock_rules_using_execution_policies` | `boolean` | false    | `true`, `false` | Lorsque cette option est activée, les règles d'approbation ne bloquent pas les merge requests lorsqu'un scan est requis par une politique d'exécution de scan ou une politique d'exécution de pipeline, mais qu'un artefact de scan requis est manquant dans la branche source. Cette option fonctionne uniquement lorsque le projet ou le groupe dispose d'une politique d'exécution de scan ou d'une politique d'exécution de pipeline existante avec des scanners correspondants. |

Vous pouvez uniquement exclure les [règles de recherche de licences](#license_finding-rule-type) si elles ciblent uniquement les états nouvellement détectés (`license_states` est défini sur `newly_detected`).

#### Exemples {#examples}

##### Exemple de `policy_tuning` avec une politique d'exécution de scan {#example-of-policy_tuning-with-a-scan-execution-policy}

Vous pouvez utiliser cet exemple dans un fichier `.gitlab/security-policies/policy.yml` stocké dans un [projet de politique de sécurité](enforcement/security_policy_projects.md) :

```yaml
scan_execution_policy:
- name: Enforce dependency scanning
  description: ''
  enabled: true
  policy_scope:
    projects:
      excluding: []
  rules:
  - type: pipeline
    branch_type: all
  actions:
  - scan: dependency_scanning
approval_policy:
- name: Dependency scanning approvals
  description: ''
  enabled: true
  policy_scope:
    projects:
      excluding: []
  rules:
  - type: scan_finding
    scanners:
    - dependency_scanning
    vulnerabilities_allowed: 0
    severity_levels: []
    vulnerability_states: []
    branch_type: protected
  actions:
  - type: require_approval
    approvals_required: 1
    role_approvers:
    - developer
  - type: send_bot_message
    enabled: true
  fallback_behavior:
    fail: closed
  policy_tuning:
    unblock_rules_using_execution_policies: true
```

##### Exemple de `policy_tuning` avec une politique d'exécution de pipeline {#example-of-policy_tuning-with-a-pipeline-execution-policy}

> [!warning]
> Cette fonctionnalité ne fonctionne pas avec les politiques d'exécution de pipeline créées avant GitLab 17.10. Pour utiliser cette fonctionnalité avec d'anciennes politiques d'exécution de pipeline, copiez, supprimez et recréez les politiques. Pour plus d'informations, voir [Recréer les politiques d'exécution de pipeline créées avant GitLab 17.10](#recreate-pipeline-execution-policies-created-before-gitlab-1710).

Vous pouvez utiliser cet exemple dans un fichier `.gitlab/security-policies/policy.yml` stocké dans un [projet de politique de sécurité](enforcement/security_policy_projects.md) :

```yaml
---
pipeline_execution_policy:
- name: Enforce dependency scanning
  description: ''
  enabled: true
  pipeline_config_strategy: inject_policy
  content:
    include:
    - project: my-group/pipeline-execution-ci-project
      file: policy-ci.yml
      ref: main # optional
```

La configuration CI/CD de la politique d'exécution de pipeline liée dans `policy-ci.yml` :

```yaml
include:
  - template: Jobs/Dependency-Scanning.gitlab-ci.yml
```

###### Recréer les politiques d'exécution de pipeline créées avant GitLab 17.10 {#recreate-pipeline-execution-policies-created-before-gitlab-1710}

Les politiques d'exécution de pipeline créées avant GitLab 17.10 ne contiennent pas les données requises pour utiliser la fonctionnalité `policy_tuning`. Pour utiliser cette fonctionnalité avec d'anciennes politiques d'exécution de pipeline, copiez et supprimez les anciennes politiques, puis recréez-les.

<i class="fa-youtube-play" aria-hidden="true"></i> Pour une vidéo de présentation, voir [Politiques de sécurité : Recréer une politique d'exécution de pipeline pour une utilisation avec `policy_tuning`](https://youtu.be/XN0jCQWlk1A).
<!-- Video published on 2025-03-07 -->

Pour recréer une politique d'exécution de pipeline :

<!-- markdownlint-disable MD044 -->

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre groupe.
1. Dans la barre latérale gauche, sélectionnez **Sécurisation** > **Politiques**.
1. Sélectionnez la politique d'exécution de pipeline que vous souhaitez recréer.
1. Dans la barre latérale droite, sélectionnez l'onglet **YAML** et copiez le contenu de l'intégralité du fichier de politique.
1. À côté du tableau des politiques, sélectionnez l'ellipse verticale ({{< icon name="ellipsis_v" >}}), puis sélectionnez **Supprimer**.
1. Fusionnez la merge request générée.
1. Revenez à **Sécurisation** > **Politiques** et sélectionnez **Nouvelle politique**.
1. Dans la section **Politique d'exécution de pipeline**, sélectionnez **Sélectionner la politique**.
1. Dans le **Mode .yaml**, collez le contenu de l'ancienne politique.
1. Sélectionnez **Mettre à jour via une requête de fusion** et fusionnez la merge request générée.

<!-- markdownlint-enable MD044 -->

### `security_report_time_window` {#security_report_time_window}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/525509) dans GitLab 18.5 [avec un flag](../../../administration/feature_flags/_index.md) nommé `approval_policy_time_window`.
- [En disponibilité générale](https://gitlab.com/gitlab-org/gitlab/-/issues/543027) dans GitLab 18.5. L'indicateur de fonctionnalité `approval_policy_time_window` a été supprimé.

{{< /history >}}

Dans les projets très actifs, le pipeline le plus récent peut ne pas disposer immédiatement des scans de sécurité terminés, ce qui bloque les comparaisons de rapports de sécurité. Utilisez le paramètre `security_report_time_window` pour utiliser à la place les rapports de sécurité des pipelines récemment terminés. Les rapports de sécurité ne peuvent pas être plus anciens que la fenêtre temporelle, spécifiée en minutes avant la création du pipeline de la branche cible. Ce paramètre ne s'applique pas si le pipeline sélectionné dispose déjà de rapports de sécurité terminés.

| Champ  | Type     | Obligatoire | Valeurs possibles    | Description                                                                                                          |
|--------|----------|----------|--------------------|----------------------------------------------------------------------------------------------------------------------|
| `security_report_time_window` | `integer` | false    | 1 à 10080 (7 jours) | Spécifie la fenêtre temporelle en minutes pour choisir le pipeline cible pour la comparaison des rapports de sécurité. |

## Schéma de la portée de la politique {#policy-scope-schema}

Pour personnaliser l'application de la politique, vous pouvez définir la portée d'une politique afin d'inclure ou d'exclure des projets, groupes ou labels de cadre de conformité spécifiques. Pour plus de détails, voir [Portée](_index.md#configure-the-policy-scope).

> [!note]
> Définir un champ `policy_scope` sur une collection vide (par exemple, `including: []`) est traité de la même façon qu'omettre le champ, de sorte que la politique s'applique à tous les projets pour cette dimension de portée. Pour désactiver entièrement une politique, utilisez `enabled: false`. Pour plus de détails, voir [Collections vides dans `policy_scope`](_index.md#empty-collections-in-policy_scope).

## `bypass_settings` {#bypass_settings}

Le champ `bypass_settings` vous permet de spécifier des exceptions à la politique pour certaines branches, jetons d'accès ou comptes de service. Lorsqu'une condition de contournement est remplie, la politique n'est pas appliquée pour la merge request ou la branche correspondante.

| Champ             | Type    | Obligatoire | Description                                                                     |
|-------------------|---------|----------|---------------------------------------------------------------------------------|
| `branches`        | array   | false    | Liste des branches source et cible (par nom ou motif) qui contournent la politique. |
| `access_tokens`   | array   | false    | Liste des identifiants de jetons d'accès qui contournent la politique.                                |
| `service_accounts`| array   | false    | Liste des identifiants de comptes de service qui contournent la politique.                             |
| `users`           | array   | false    | Liste des identifiants d'utilisateurs pouvant contourner la politique.                                        |
| `groups`          | array   | false    | Liste des identifiants de groupes pouvant contourner la politique.                                       |
| `roles`           | array   | false    | Liste des rôles par défaut pouvant contourner la politique.                                   |
| `custom_roles`    | array   | false    | Liste des identifiants de rôles personnalisés pouvant contourner la politique.                                 |

### Exceptions de branche source {#source-branch-exceptions}

{{< history >}}

- [Introduit](https://gitlab.com/groups/gitlab-org/-/epics/18113) dans GitLab 18.2 [avec un indicateur](../../../administration/feature_flags/_index.md) nommé `approval_policy_branch_exceptions`. Activé par défaut
- [Disponible en général](https://gitlab.com/gitlab-org/gitlab/-/issues/543778) dans GitLab 18.3. L'indicateur de fonctionnalité `approval_policy_branch_exceptions` a été supprimé.

{{< /history >}}

Grâce aux exceptions basées sur les branches, vous pouvez configurer les politiques d'approbation des merge requests pour dispenser automatiquement les exigences d'approbation pour des combinaisons spécifiques de branche source et branche cible. Cela vous permet de préserver la gouvernance de sécurité et de maintenir des règles d'approbation strictes pour certains types de fusions, comme feature-to-main, tout en permettant plus de flexibilité pour d'autres, comme release-to-main. Les événements de contournement sont enregistrés comme événements d'audit dans un projet de politique de sécurité.

| Champ   | Type   | Obligatoire | Valeurs possibles | Description |
|---------|--------|----------|-----------------|-------------|
| `source`| object | false    | `name` (string) ou `pattern` (string) | Exception de branche source. Spécifiez soit un nom exact, soit un motif.         |
| `target`| object | false    | `name` (string) ou `pattern` (string) | Exception de branche cible. Spécifiez soit un nom exact, soit un motif.         |

### Exceptions de jeton d'accès et de compte de service {#access-token-and-service-account-exceptions}

{{< history >}}

- [Introduit](https://gitlab.com/groups/gitlab-org/-/epics/18112) dans GitLab 18.2 [avec un indicateur](../../../administration/feature_flags/_index.md) nommé `security_policies_bypass_options_tokens_accounts`. Activé par défaut
- [Disponible en général](https://gitlab.com/gitlab-org/gitlab/-/issues/551129) dans GitLab 18.3. L'indicateur de fonctionnalité `security_policies_bypass_options_tokens_accounts` a été supprimé.

{{< /history >}}

Grâce aux exceptions de jeton d'accès et de compte de service, vous pouvez désigner des comptes de service et des jetons d'accès spécifiques pouvant contourner les protections de branches appliquées par les politiques d'approbation des merge requests lorsque cela est nécessaire. Cette approche permet aux automatisations auxquelles vous faites confiance de fonctionner sans approbation manuelle tout en maintenant des restrictions pour les utilisateurs humains. Par exemple, les automatisations de confiance peuvent inclure les pipelines CI/CD, la mise en miroir de dépôt et les mises à jour automatisées. Les événements de contournement sont enregistrés comme événements d'audit dans un projet de politique de sécurité.

| Champ | Type    | Obligatoire | Description                                    |
|-------|---------|----------|------------------------------------------------|
| `id`  | integer | true     | L'identifiant du jeton d'accès ou du compte de service. |

### Autoriser les utilisateurs à contourner les politiques de sécurité {#allowing-users-to-bypass-security-policies}

{{< history >}}

- [Introduit](https://gitlab.com/groups/gitlab-org/-/epics/18114) dans GitLab 18.5 [avec un flag](../../../administration/feature_flags/_index.md) nommé `security_policies_bypass_options_group_roles`. Activé par défaut.
- [Disponible en général](https://gitlab.com/gitlab-org/gitlab/-/issues/551920) dans GitLab 18.6. L'indicateur de fonctionnalité `security_policies_bypass_options_group_roles` a été supprimé.

{{< /history >}}

Vous pouvez anticiper les situations urgentes en désignant des utilisateurs, groupes, rôles ou rôles personnalisés spécifiques pouvant contourner les politiques d'approbation des merge requests. Cette capacité offre de la flexibilité pour les réponses d'urgence et le maintien des contrôles de gouvernance. Pour permettre à un utilisateur, un groupe, un rôle ou un rôle personnalisé de contourner les politiques de sécurité, accordez-leur une exception. Les événements de contournement sont enregistrés comme événements d'audit dans un projet de politique de sécurité.

Les utilisateurs disposant de ces exceptions peuvent contourner à deux niveaux :

- Exigences d'approbation des merge requests : L'utilisateur peut contourner une exigence d'approbation en fournissant une raison depuis l'interface de la merge request.
- Protections de branches : L'utilisateur peut pousser directement vers une branche avec protection de push provenant d'une politique d'approbation des merge requests en fournissant une raison dans les [options de push Git `security_policy.bypass_reason`](../../../topics/git/commit.md#push-options-for-security-policy)

> [!note]
> L'option de push `security_policy.bypass_reason` fonctionne uniquement pour les branches avec protection de push provenant d'une politique d'approbation des merge requests configurée avec [`approval_settings`](merge_request_approval_policies.md#approval_settings). Les pushs vers des branches protégées qui ne sont pas couvertes par une politique d'approbation des merge requests ne peuvent pas être contournés avec cette option.

#### Exemple YAML {#example-yaml}

```yaml
bypass_settings:
  access_tokens:
    - id: 123
    - id: 456
  service_accounts:
    - id: 789
    - id: 1011
  users:
    - id: 123
    - id: 456
  groups:
    - id: 789
    - id: 1011
  roles:
    - maintainer
    - developer
  custom_roles:
    - id: 789
    - id: 1011
```

## Exemple `policy.yml` dans un projet de politique de sécurité {#example-policyyml-in-a-security-policy-project}

Vous pouvez utiliser cet exemple dans un fichier `.gitlab/security-policies/policy.yml` stocké dans un [projet de politique de sécurité](enforcement/security_policy_projects.md) :

```yaml
---
approval_policy:
- name: critical vulnerability CS approvals
  description: critical severity level only for container scanning
  enabled: true
  rules:
  - type: scan_finding
    branches:
    - main
    scanners:
    - container_scanning
    vulnerabilities_allowed: 0
    severity_levels:
    - critical
    vulnerability_states: []
    vulnerability_attributes:
      false_positive: true
      fix_available: true
  actions:
  - type: require_approval
    approvals_required: 1
    user_approvers:
    - adalberto.dare
- name: secondary CS approvals
  description: secondary only for container scanning
  enabled: true
  rules:
  - type: scan_finding
    branches:
    - main
    scanners:
    - container_scanning
    vulnerabilities_allowed: 1
    severity_levels:
    - low
    - unknown
    vulnerability_states:
    - detected
    vulnerability_age:
      operator: greater_than
      value: 30
      interval: day
  actions:
  - type: require_approval
    approvals_required: 1
    role_approvers:
    - owner
    - 1002816 # Example custom role identifier called "AppSec Engineer"
- name: critical vulnerability CS approvals
  description: high/critical severity level only for SAST scanning
  enabled: true
  enforcement_type: warn
  rules:
  - type: scan_finding
    branch_type: default
    scanners:
    - sast
    vulnerabilities_allowed: 0
    severity_levels:
    - critical
    - high
    vulnerability_states: []
  actions:
  - type: require_approval
    approvals_required: 1
    role_approvers:
    - maintainer
```

Dans cet exemple :

- Chaque merge request contenant de nouvelles vulnérabilités `critical` identifiées par le scan de conteneurs nécessite une approbation de `alberto.dare`.
- Chaque merge request contenant plus d'une vulnérabilité préexistante `low` ou `unknown` de plus de 30 jours identifiée par le scan de conteneurs nécessite une approbation d'un membre du projet avec le rôle Owner ou d'un utilisateur avec le rôle personnalisé `AppSec Engineer`.
- Chaque merge request contenant de nouvelles vulnérabilités de gravité `critical` ou `high`, identifiées par le scan SAST, déclenche la politique en mode avertissement. Le mode avertissement génère un commentaire de bot et bloque la merge request. Un développeur peut alors contourner la violation de politique. Optionnellement, un maintainer peut également approuver la merge request.

## Exemple pour l'éditeur de politique d'approbation des merge requests {#example-for-merge-request-approval-policy-editor}

Vous pouvez utiliser cet exemple dans le mode YAML de l'[éditeur de politique d'approbation des merge requests](#merge-request-approval-policy-editor). Il correspond à un seul objet de l'exemple précédent :

```yaml
type: approval_policy
name: critical vulnerability CS approvals
description: critical severity level only for container scanning
enabled: true
rules:
- type: scan_finding
  branches:
  - main
  scanners:
  - container_scanning
  vulnerabilities_allowed: 1
  severity_levels:
  - critical
  vulnerability_states: []
actions:
- type: require_approval
  approvals_required: 1
  user_approvers:
  - adalberto.dare
```

## Comprendre les approbations des politiques d'approbation des merge requests {#understanding-merge-request-approval-policy-approvals}

{{< history >}}

- La logique de comparaison des branches pour `scan_finding` a été [modifiée](https://gitlab.com/gitlab-org/gitlab/-/issues/428518) dans GitLab 16.8 [avec un indicateur](../../../administration/feature_flags/_index.md) nommé `scan_result_policy_merge_base_pipeline`. Désactivé par défaut.
- [Disponible en général](https://gitlab.com/gitlab-org/gitlab/-/issues/435297) dans GitLab 16.9. L'indicateur de fonctionnalité `scan_result_policy_merge_base_pipeline` a été supprimé.

{{< /history >}}

### Portée de la comparaison des politiques d'approbation des merge requests {#scope-of-merge-request-approval-policy-comparison}

- Pour déterminer quand une approbation est requise sur une merge request, GitLab compare les pipelines terminés pour chaque source de pipeline prise en charge pour la branche source et la branche cible (par exemple, `feature`/`main`). Cela garantit l'évaluation la plus complète des résultats de scan.
- Pour la branche source, les pipelines de comparaison sont tous les pipelines terminés pour chaque source de pipeline prise en charge pour le dernier commit de la branche source.
- Si la politique d'approbation des merge requests ne recherche que les états nouvellement détectés (`new_needs_triage` & `new_dismissed`), la comparaison est effectuée par rapport à toutes les sources de pipeline prises en charge dans l'ancêtre commun entre la branche source et la branche cible. Une exception s'applique lors de l'utilisation des pipelines de résultats fusionnés, auquel cas la comparaison est effectuée par rapport à la pointe de la branche cible de la merge request.
- Si la politique d'approbation des merge requests recherche des états préexistants (`detected`, `confirmed`, `resolved`, `dismissed`), la comparaison est toujours effectuée par rapport à la pointe de la branche par défaut (par exemple, `main`).
- Si la politique d'approbation des merge requests recherche une combinaison de nouveaux états de vulnérabilité et d'états préexistants, la comparaison est effectuée par rapport à l'ancêtre commun des branches source et cible.
- Les politiques d'approbation des merge requests prennent en compte toutes les sources de pipeline prises en charge (basées sur la [variable `CI_PIPELINE_SOURCE`](../../../ci/variables/predefined_variables.md)) lors de la comparaison des résultats des branches source et cible pour déterminer si une merge request nécessite une approbation. Les pipelines avec la source `webide` ne sont pas pris en charge.
- Dans GitLab 16.11 et versions ultérieures, les pipelines enfants de chacun des pipelines sélectionnés sont également pris en compte pour la comparaison.

### Accepter les risques et ignorer les vulnérabilités dans les futures merge requests {#accepting-risk-and-ignoring-vulnerabilities-in-future-merge-requests}

Pour les politiques d'approbation des merge requests limitées aux résultats nouvellement détectés (statuts `new_needs_triage` ou `new_dismissed`), il est important de comprendre les implications de cet état de vulnérabilité. Un résultat est considéré comme nouvellement détecté s'il existe sur la branche de la merge request mais pas sur la branche cible. Lorsqu'une merge request avec une branche contenant des résultats nouvellement détectés est approuvée et fusionnée, les approbateurs « acceptent le risque » de ces vulnérabilités. Si une ou plusieurs des mêmes vulnérabilités sont détectées après cette période, le statut sera `detected` et donc ignoré par une politique configurée pour prendre en compte les résultats `new_needs_triage` ou `new_dismissed`. Par exemple :

- Une politique d'approbation des merge requests est créée pour bloquer les résultats SAST critiques. Si un résultat SAST pour CVE-1234 est approuvé, les futures merge requests présentant la même violation ne nécessiteront pas d'approbation dans le projet.

Lors de l'utilisation des états de vulnérabilité `new_needs_triage` et `new_dismissed`, la politique bloquera les merge requests pour tout résultat correspondant aux règles de politique s'ils sont nouveaux et pas encore triés, même s'ils ont été rejetés. Si vous souhaitez ignorer les vulnérabilités nouvellement détectées puis rejetées dans la merge request, vous pouvez utiliser uniquement le statut `new_needs_triage`.

Lors de l'utilisation des politiques d'approbation de licences, la combinaison du projet, du composant (dépendance) et de la licence est prise en compte dans l'évaluation. Si une licence est approuvée à titre d'exception, les futures merge requests ne nécessitent pas d'approbation pour la même combinaison de projet, composant (dépendance) et licence. La version du composant n'est pas prise en compte dans ce cas. Si un package précédemment approuvé est mis à jour vers une nouvelle version, les approbateurs n'auront pas besoin de réapprouver. Par exemple :

- Une politique d'approbation de licences est créée pour bloquer les merge requests avec des licences nouvellement détectées correspondant à `AGPL-1.0`. Une modification est apportée dans le projet `demo` pour le composant `osframework` qui viole la politique. Si approuvée et fusionnée, les futures merge requests vers `osframework` dans le projet `demo` avec la licence `AGPL-1.0` ne nécessitent pas d'approbation.

### Approbations supplémentaires {#additional-approvals}

Les politiques d'approbation des merge requests nécessitent une étape d'approbation supplémentaire dans certaines situations. Par exemple :

- Le nombre de jobs de sécurité est réduit dans la branche de travail et ne correspond plus au nombre de jobs de sécurité dans la branche cible. Les utilisateurs ne peuvent pas ignorer les politiques de résultats de scan en supprimant les jobs de scan de la configuration CI/CD. Seuls les scans de sécurité configurés dans les règles de la politique d'approbation des merge requests sont vérifiés pour suppression.

  Par exemple, considérez une situation où le pipeline de la branche par défaut comporte quatre scans de sécurité : `sast`, `secret_detection`, `container_scanning` et `dependency_scanning`. Une politique d'approbation des merge requests applique deux scanners : `container_scanning` et `dependency_scanning`. Si une merge request supprime un scan configuré dans la politique d'approbation des merge requests, `container_scanning` par exemple, une approbation supplémentaire est requise.
- Quelqu'un arrête un job de sécurité de pipeline, et les utilisateurs ne peuvent pas ignorer le scan de sécurité.
- Un job dans une merge request échoue et est configuré avec `allow_failure: false`. En conséquence, le pipeline est dans un état bloqué.
- Un pipeline comporte un job manuel qui doit s'exécuter avec succès pour que l'ensemble du pipeline réussisse.

### Gestion des résultats de scan utilisés pour évaluer les exigences d'approbation {#managing-scan-findings-used-to-evaluate-approval-requirements}

Les politiques d'approbation des merge requests évaluent les rapports d'artefacts générés par les scanners dans vos pipelines après la fin du pipeline. Les politiques d'approbation des merge requests se concentrent sur l'évaluation des résultats et la détermination des approbations en fonction des résultats de scan pour identifier les risques potentiels, bloquer les merge requests et exiger une approbation.

Les politiques d'approbation des merge requests ne vont pas au-delà de cette portée pour accéder aux fichiers d'artefacts ou aux scanners. GitLab fait plutôt confiance aux résultats des rapports d'artefacts. Cela offre aux équipes une flexibilité dans la gestion de leur exécution de scan et de leur chaîne d'approvisionnement, et dans la personnalisation des résultats de scan générés dans les rapports d'artefacts (par exemple, pour filtrer les faux positifs) si nécessaire.

La falsification de fichier de verrouillage, par exemple, est hors de la portée de la gestion des politiques de sécurité, mais peut être atténuée par l'utilisation des [propriétaires du code](../../project/codeowners/_index.md#codeowners-file) ou des [vérifications de statut externes](../../project/merge_requests/status_checks.md). Pour plus d'informations, voir le [ticket 433029](https://gitlab.com/gitlab-org/gitlab/-/issues/433029).

![Évaluation des résultats de scan](img/scan_results_evaluation_white-bg_v16_8.png)

### Filtrer les violations de politique avec les attributs **Fix Available** ou **False Positive** {#filter-out-policy-violations-with-the-attributes-fix-available-or-false-positive}

Pour éviter des exigences d'approbation inutiles, ces filtres supplémentaires garantissent que vous bloquez les merge requests uniquement pour les résultats les plus exploitables.

En définissant `fix_available` sur `false` en YAML, ou **n'est pas** et **Fix Available** dans l'éditeur de politique, le résultat n'est pas considéré comme une violation de politique lorsque le résultat dispose d'une remédiation ou d'une solution disponible. Les solutions apparaissent en bas de l'objet de vulnérabilité sous le titre **Solution**. Les remédiations apparaissent sous la forme d'un bouton **Resolve with Merge Request** dans l'objet de vulnérabilité.

Le bouton **Resolve with Merge Request** n'apparaît que lorsque l'un des critères suivants est rempli :

1. Une vulnérabilité SAST est détectée dans un projet bénéficiant de l'édition Ultimate avec GitLab Duo Enterprise.
1. Une vulnérabilité de scan de conteneurs est détectée dans un projet bénéficiant de l'édition Ultimate dans un job où `GIT_STRATEGY: fetch` a été défini. De plus, la vulnérabilité doit avoir un package contenant un correctif disponible pour les dépôts activés pour l'image de conteneur.
1. Une vulnérabilité d'analyse des dépendances est détectée dans un projet Node.js géré par yarn et un correctif est disponible. De plus, le projet doit bénéficier de l'édition Ultimate et le mode FIPS doit être désactivé pour l'instance.

**Fix Available** s'applique uniquement à l'analyse des dépendances et au scan de conteneurs.

En utilisant l'attribut **False Positive**, de la même manière, vous pouvez ignorer les résultats détectés par une politique en définissant `false_positive` sur `false` (ou en définissant l'attribut sur **N'est pas** et **False Positive** dans l'éditeur de politique).

L'attribut **False Positive** s'applique uniquement aux résultats détectés par l'outil d'extraction de vulnérabilités pour les résultats SAST.

### Évaluation de la politique et changements d'état des vulnérabilités {#policy-evaluation-and-vulnerability-state-changes}

Lorsqu'un utilisateur modifie le statut d'une vulnérabilité (par exemple, rejette la vulnérabilité dans la page de détails de la vulnérabilité), GitLab ne réévalue pas automatiquement les politiques d'approbation des merge requests pour des raisons de performances. Pour récupérer les données mises à jour depuis les rapports de vulnérabilité, mettez à jour votre merge request ou relancez les pipelines associés.

Ce comportement garantit des performances système optimales et maintient l'application des politiques de sécurité. L'évaluation de la politique se produit lors de la prochaine exécution du pipeline ou lors de la mise à jour de la merge request, mais pas immédiatement lors du changement d'état de la vulnérabilité.

Pour refléter immédiatement les changements d'état des vulnérabilités dans les politiques, exécutez manuellement le pipeline ou poussez un nouveau commit vers la merge request.

## Comprendre les divergences entre le widget de sécurité et le bot de politique {#understanding-security-widget-and-policy-bot-discrepancies}

Vous pouvez remarquer des incohérences entre ce qu'affiche le widget de sécurité de la merge request et ce qu'indiquent les commentaires du bot de sécurité concernant les vulnérabilités. Ces fonctionnalités utilisent des sources de données et des méthodes de comparaison différentes pour les résultats de sécurité, ce qui peut entraîner des différences dans ce qu'elles affichent.

Sources de données :

- **Merge request security widget** : Compare les résultats du dernier pipeline de la branche source avec les vulnérabilités précédemment stockées dans la base de données pour la branche par défaut.
- **Security Bot (and approval policy logic)** : Compare les résultats entre les artefacts de pipeline réels, en particulier entre le dernier pipeline de branche cible réussi et le dernier pipeline de branche source réussi.

### Scénarios courants où des incohérences se produisent {#common-scenarios-where-inconsistencies-occur}

La différence de sources de données peut entraîner un comportement incohérent dans plusieurs scénarios.

#### Scans de sécurité manquants ou échoués dans la branche cible {#missing-or-failed-security-scans-in-target-branch}

Lorsque le dernier pipeline de votre branche cible ne parvient pas à exécuter correctement les scans de sécurité (par exemple, en raison d'une mauvaise configuration ou d'échecs de jobs), le bot de sécurité peut signaler de nouveaux résultats et exiger une approbation à titre de mesure de précaution, car il ne peut pas comparer les résultats efficacement. Pendant ce temps, le widget de sécurité peut n'afficher aucune nouvelle vulnérabilité, car il utilise des données de vulnérabilité précédemment stockées.

#### Modifications de la branche cible entre les comparaisons {#changes-in-target-branch-between-comparisons}

Si plusieurs commits sur la branche cible modifient le profil de sécurité entre le moment où le widget effectue sa comparaison et celui où le bot effectue la sienne, les résultats peuvent différer.

### Bonnes pratiques pour des résultats cohérents {#best-practices-for-consistent-results}

Pour minimiser la confusion lors de l'utilisation de ces fonctionnalités de sécurité :

- Assurez une exécution complète du pipeline : Assurez-vous que les scans de sécurité se terminent avec succès sur les branches source et cible.
- Maintenez une configuration CI/CD cohérente : Évitez de supprimer ou de casser les configurations de scan de sécurité dans votre pipeline.
- Pour les nouveaux projets : Exécutez un scan de sécurité sur la branche par défaut avant de créer des merge requests pour établir des données de référence sur les vulnérabilités.
- Envisagez d'utiliser des politiques d'exécution de scan : Combinées aux politiques d'approbation des merge requests, elles permettent de s'assurer que les scans de sécurité s'exécutent toujours là où c'est nécessaire.

## Dépannage {#troubleshooting}

### Le widget de règles de merge request indique qu'une politique d'approbation des merge requests est invalide ou dupliquée {#merge-request-rules-widget-shows-a-merge-request-approval-policy-is-invalid-or-duplicated}

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Sur GitLab Self-Managed de la version 15.0 à 16.4, la cause la plus probable est que le projet a été exporté depuis un groupe et importé dans un autre, et comportait des règles de politique d'approbation des merge requests. Ces règles sont stockées dans un projet distinct de celui qui a été exporté. En conséquence, le projet contient des règles de politique qui font référence à des entités qui n'existent pas dans le groupe du projet importé. Le résultat est des règles de politique invalides, dupliquées, ou les deux.

Pour supprimer toutes les règles de politique d'approbation des merge requests invalides d'une instance GitLab, un administrateur peut exécuter le script suivant dans la [console Rails](../../../administration/operations/rails_console.md).

```ruby
Project.joins(:approval_rules).where(approval_rules: { report_type: %i[scan_finding license_scanning] }).where.not(approval_rules: { security_orchestration_policy_configuration_id: nil }).find_in_batches.flat_map do |batch|
  batch.map do |project|
    # Get projects and their configuration_ids for applicable project rules
    [project, project.approval_rules.where(report_type: %i[scan_finding license_scanning]).pluck(:security_orchestration_policy_configuration_id).uniq]
  end.uniq.map do |project, configuration_ids| # Take only unique combinations of project + configuration_ids
    # If you find more configurations than what is available for the project, take records with the extra configurations
    [project, configuration_ids - project.all_security_orchestration_policy_configurations.pluck(:id)]
  end.select { |_project, configuration_ids| configuration_ids.any? }
end.each do |project, configuration_ids|
  # For each found pair project + ghost configuration, remove these rules for a given project
  Security::OrchestrationPolicyConfiguration.where(id: configuration_ids).each do |configuration|
    configuration.delete_scan_finding_rules_for_project(project.id)
  end
  # Ensure you sync any potential rules from new group's policy
  Security::ScanResultPolicies::SyncProjectWorker.perform_async(project.id)
end
```

### CVE nouvellement détectées {#newly-detected-cves}

Lors de l'utilisation de `new_needs_triage` et `new_dismissed`, certains résultats peuvent nécessiter une approbation lorsqu'ils ne sont pas introduits par la merge request (comme un nouveau CVE sur une dépendance associée). Ces résultats ne seront pas présents dans le widget de merge request, mais seront mis en évidence dans le commentaire du bot de politique et le rapport de pipeline.

### Les politiques ont toujours un effet après l'invalidation manuelle de `policy.yml` {#policies-still-have-effect-after-policyyml-was-manually-invalidated}

Dans GitLab 17.2 et versions antérieures, vous pouvez constater que les politiques définies dans un fichier `policy.yml` sont appliquées, même si le fichier a été modifié manuellement et ne valide plus le [schéma de politique](#merge-request-approval-policies-schema). Ce problème est dû à un bug dans la logique de synchronisation des politiques.

Les symptômes potentiels incluent :

- `approval_settings` bloque toujours la suppression des protections de branches, bloque les pushs forcés ou affecte autrement les merge requests ouvertes.
- Les politiques `any_merge_request` s'appliquent toujours aux merge requests ouvertes.

Pour résoudre ce problème, vous pouvez :

- Modifiez manuellement le fichier `policy.yml` qui définit la politique afin qu'il redevienne valide.
- Désattribuez et réattribuez les projets de politique de sécurité où le fichier `policy.yml` est stocké.

### Scans de sécurité manquants {#missing-security-scans}

Lors de l'utilisation des politiques d'approbation des merge requests, vous pouvez rencontrer des situations où les merge requests sont bloquées, notamment dans les nouveaux projets ou lorsque certains scans de sécurité ne sont pas exécutés. Ce comportement est intentionnel pour réduire le risque d'introduction de vulnérabilités dans votre système.

Exemples de scénarios :

- Scans manquants sur les branches source

  Si des scans de sécurité sont manquants sur la branche source, GitLab ne peut pas évaluer efficacement si la merge request introduit de nouvelles vulnérabilités. Dans ce cas, une approbation est requise à titre de mesure de précaution.

- Scans manquants sur les branches cible

  Si des scans de sécurité sont manquants sur la branche cible, GitLab ne peut pas comparer efficacement les vulnérabilités détectées sur la branche source. Dans ce cas, toutes les vulnérabilités détectées sont signalées comme nouvelles.

- Projets sans fichiers à scanner

  Même dans les projets ne contenant aucun fichier pertinent pour les scans de sécurité sélectionnés, l'exigence d'approbation est toujours appliquée. Cela maintient des pratiques de sécurité cohérentes dans tous les projets.

- Première merge request

  La toute première merge request dans un nouveau projet peut être bloquée si la branche par défaut ne dispose pas d'un scan de sécurité, même si la branche source ne présente aucune vulnérabilité.

Pour résoudre ces problèmes :

- Assurez-vous que tous les scans de sécurité requis sont configurés et s'exécutent avec succès sur les branches source et cible.
- Pour les nouveaux projets, configurez et exécutez les scans de sécurité nécessaires sur la branche par défaut avant de créer des merge requests.
- Envisagez d'utiliser des politiques d'exécution de scan ou des politiques d'exécution de pipeline pour garantir une exécution cohérente des scans de sécurité sur toutes les branches.
- Envisagez d'utiliser [`fallback_behavior`](#fallback_behavior) avec `open` pour éviter que des règles invalides ou inapplicables dans une politique exigent une approbation.
- Envisagez d'utiliser le paramètre [`policy tuning`](#policy_tuning) `unblock_rules_using_execution_policies` pour traiter les scénarios où les artefacts de scan de sécurité sont manquants et où des politiques d'exécution de scan sont appliquées. Lorsque cette option est activée, ce paramètre rend les règles d'approbation optionnelles lorsque les artefacts de scan sont manquants sur la branche source et qu'un scan est requis par une politique d'exécution de scan. Cette fonctionnalité fonctionne uniquement avec une politique d'exécution de scan existante ayant des scanners correspondants. Elle offre de la flexibilité dans le processus de merge request lorsque certains scans de sécurité ne peuvent pas être effectués en raison d'artefacts manquants.

### `Target: none` dans les commentaires du bot de sécurité {#target-none-in-security-bot-comments}

Si vous voyez `Target: none` dans les commentaires du bot de sécurité, cela signifie que GitLab n'a pas pu trouver un rapport de sécurité pour la branche cible. Pour résoudre ce problème :

1. Exécutez un pipeline sur la branche cible incluant les scanners de sécurité requis.
1. Assurez-vous que le pipeline se termine avec succès et produit des rapports de sécurité.
1. Relancez le pipeline sur la branche source. La création d'un nouveau commit déclenche également la relance du pipeline

#### Messages du bot de sécurité {#security-bot-messages}

Lorsque la branche cible ne dispose d'aucun scan de sécurité :

- Le bot de sécurité peut lister toutes les vulnérabilités trouvées dans la branche source.
- Certaines vulnérabilités peuvent déjà exister dans la branche cible, mais sans scan de branche cible, GitLab ne peut pas déterminer lesquelles sont nouvelles.

Solutions potentielles :

1. **Manual approvals** : Approuvez temporairement les merge requests manuellement pour les nouveaux projets jusqu'à ce que les scans de sécurité soient établis.
1. **Targeted policies** : Créez des politiques distinctes pour les nouveaux projets avec des exigences d'approbation différentes.
1. **Comportement de repli** : Envisagez d'utiliser `fail: open` pour les politiques des nouveaux projets, mais sachez que cela peut permettre aux utilisateurs de fusionner des vulnérabilités même si les scans échouent.

### Demande d'assistance pour le débogage d'une politique d'approbation des merge requests {#support-request-for-debugging-of-merge-request-approval-policy}

Les utilisateurs de GitLab.com peuvent soumettre un [ticket d'assistance](https://support.gitlab.com/) intitulé « Merge request approval policy debugging ». Fournissez les informations suivantes :

- Chemin du groupe, chemin du projet et identifiant de merge request (optionnel)
- Gravité
- Comportement actuel
- Comportement attendu

#### GitLab.com {#gitlabcom}

Les équipes d'assistance examineront les [journaux](https://log.gprd.gitlab.net/) (`pubsub-sidekiq-inf-gprd*`) pour identifier la `reason` de l'échec. Voici un exemple d'extrait de réponse des journaux. Vous pouvez utiliser cette requête pour trouver les journaux liés aux approbations : `json.event.keyword: "update_approvals"` et `json.project_path: "group-path/project-path"`. Optionnellement, vous pouvez filtrer davantage par l'identifiant de merge request en utilisant `json.merge_request_iid` :

```json
"json": {
  "project_path": "group-path/project-path",
  "merge_request_iid": 2,
  "missing_scans": [
    "api_fuzzing"
  ],
  "reason": "Scanner removed by MR",
  "event": "update_approvals",
}
```

#### GitLab Self-Managed {#gitlab-self-managed}

Recherchez des mots-clés tels que `project-path`, `api_fuzzing` et `merge_request`. Exemple : `grep group-path/project-path`, et `grep merge_request`. Si vous connaissez l'ID de corrélation, vous pouvez rechercher par ID de corrélation. Par exemple, si la valeur de `correlation_id` est 01HWN2NFABCEDFG, recherchez `01HWN2NFABCEDFG`. Recherchez dans les fichiers suivants :

- `/gitlab/gitlab-rails/production_json.log`
- `/gitlab/sidekiq/current`

Raisons d'échec courantes :

- Scanner supprimé par la merge request : La politique d'approbation des merge requests s'attend à ce que les scanners définis dans la politique soient présents et qu'ils produisent avec succès un artefact pour la comparaison.

### Approbations incohérentes provenant des politiques d'approbation des merge requests {#inconsistent-approvals-from-merge-request-approval-policies}

Si vous remarquez des incohérences dans vos règles d'approbation des merge requests, vous pouvez effectuer l'une des étapes suivantes pour resynchroniser vos politiques :

- Utilisez la [mutation GraphQL `resyncSecurityPolicies`](_index.md#resynchronize-policies-with-the-graphql-api) pour resynchroniser les politiques.
- Désattribuez puis réattribuez le projet de politique de sécurité au groupe ou au projet concerné.
- Vous pouvez également mettre à jour une politique pour déclencher la resynchronisation de cette politique pour le groupe ou le projet concerné.
- Vérifiez que la syntaxe du fichier YAML dans le projet de politique de sécurité est valide.

Ces actions permettent de s'assurer que vos politiques d'approbation des merge requests sont correctement appliquées et cohérentes pour toutes les merge requests.

Si vous continuez à rencontrer des problèmes avec les politiques d'approbation des merge requests après avoir suivi ces étapes, contactez le support GitLab pour obtenir de l'aide.

### Les merge requests qui corrigent une vulnérabilité détectée nécessitent une approbation {#merge-requests-that-fix-a-detected-vulnerability-require-approval}

Si votre configuration de politique inclut l'état `detected`, les merge requests qui corrigent des vulnérabilités précédemment détectées nécessitent toujours une approbation. La politique d'approbation des merge requests évalue en fonction des vulnérabilités qui existaient avant les modifications de la merge request, ce qui ajoute une couche d'examen supplémentaire pour tout changement affectant les vulnérabilités connues.

Si vous souhaitez autoriser les merge requests qui corrigent des vulnérabilités à continuer sans approbations supplémentaires dues à une vulnérabilité détectée, envisagez de supprimer l'état `detected` de votre configuration de politique.

### Évaluation de politique incohérente entre les pipelines de résultats fusionnés et les pipelines de branche {#inconsistent-policy-evaluation-between-merged-results-pipelines-and-branch-pipelines}

Lorsqu'un projet dispose de [pipelines de résultats fusionnés](../../../ci/pipelines/merged_results_pipelines.md) activés et exécute également des pipelines de branche avec des scans de sécurité, vous pouvez rencontrer des incohérences dans la façon dont les politiques d'approbation des merge requests sont évaluées dans les différents pipelines. Considérez l'exemple suivant :

1. Un pipeline de résultats fusionnés et un pipeline de branche exécutent tous deux des scans de sécurité pour la même merge request.
1. Le pipeline de branche se termine après le pipeline de résultats fusionnés.
1. L'évaluation de la politique sélectionne le pipeline de branche pour la comparaison au lieu du pipeline de résultats fusionnés.

Les politiques d'approbation des merge requests évaluent les pipelines terminés pour le dernier commit, et le pipeline qui se termine en dernier est sélectionné pour la comparaison. Lorsque le pipeline de branche se termine après le pipeline de résultats fusionnés, la politique utilise le pipeline de branche pour l'évaluation.

Pour éviter ce problème :

- Exécutez les scans de sécurité uniquement dans les pipelines de résultats fusionnés : Configurez vos jobs de scan de sécurité pour qu'ils s'exécutent uniquement dans les pipelines de merge request lorsque les pipelines de résultats fusionnés sont activés. Utilisez [`rules`](../../../ci/jobs/job_rules.md) pour contrôler quand les jobs de sécurité s'exécutent :

  ```yaml
  sast:
    rules:
      - if: $CI_PIPELINE_SOURCE == "merge_request_event"
  ```

- Évitez les pipelines en double : Suivez les recommandations dans [éviter les pipelines en double](../../../ci/jobs/job_rules.md#avoid-duplicate-pipelines) pour vous assurer que les scans de sécurité s'exécutent dans un seul type de pipeline par commit.
- Utilisez des configurations de scanner cohérentes : Exécutez les mêmes scanners avec le même type de pipeline pour les branches source et cible.

Pour plus d'informations sur les pipelines en double, voir [deux pipelines lors d'un push vers une branche](../../../ci/pipelines/mr_pipeline_troubleshooting.md#two-pipelines-when-pushing-to-a-branch).
