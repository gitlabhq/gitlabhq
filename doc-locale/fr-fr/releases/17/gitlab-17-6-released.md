---
stage: Release Notes
group: Monthly Release
date: 2024-11-21
title: "Notes de release de GitLab 17.6"
description: "GitLab 17.6 publié avec la fonctionnalité d'utilisation d'un modèle auto-hébergé pour GitLab Duo Chat"
---

<!-- markdownlint-disable -->
<!-- vale off -->

Le 21 novembre 2024, GitLab 17.6 a été publié avec les fonctionnalités suivantes.

Nous souhaitons également remercier tous nos contributeurs, dont le contributeur remarquable de ce mois-ci.

## Contributeur notable du mois : Joel Gerber {#this-months-notable-contributor-joel-gerber}

Tout le monde peut [nommer des contributeurs de la communauté GitLab](https://gitlab.com/gitlab-org/developer-relations/contributor-success/team-task/-/issues/490) ! Montrez votre soutien à nos candidats actifs ou ajoutez une nouvelle nomination ! 🙌

Joel a été reconnu pour ses contributions inestimables à nos composants CI, ses retours pertinents sur les merge requests et ses commentaires réfléchis lors de discussions complexes. Ses contributions comprennent [l'amélioration de l'interface utilisateur du catalogue CI/CD](https://gitlab.com/gitlab-org/gitlab/-/issues/464703), des améliorations de documentation très demandées pour le fournisseur Terraform GitLab, [les horodatages du job log](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/164595), et [des retours fournis à l'équipe UI/UX](https://gitlab.com/gitlab-org/gitlab/-/issues/482524#note_2089551197).

Joel est ingénieur logiciel principal chez [HackerOne](https://www.hackerone.com/) et a été nommé par [Lee Tickett](https://gitlab.com/leetickett-gitlab), ingénieur FullStack principal, Contributor Success chez GitLab, pour ses contributions et pour avoir fourni des retours précieux.

[Gina Doyle](https://gitlab.com/gdoyle), conceptrice produit senior chez GitLab, a contribué à la nomination. « Il y avait beaucoup de discussions en interne qui ont rendu le processus de merge request plus compliqué », déclare Gina. « Mais Joel est resté actif et engagé dans la discussion et a finalisé la contribution. »

« Joel a également contribué à l'amélioration de l'interface utilisateur du catalogue CI/CD, » déclare [Sunjung Park](https://gitlab.com/sunjungp), conceptrice produit principale chez GitLab. « Cela rend notre interface utilisateur plus belle et cohérente avec les autres zones. »

Nous sommes très reconnaissants envers Joel pour toutes ses contributions et envers toute notre communauté open source pour ses contributions à GitLab !

## Fonctionnalités principales {#primary-features}

### Utiliser un modèle auto-hébergé pour GitLab Duo Chat {#use-self-hosted-model-for-gitlab-duo-chat}

<!-- categories: Self-Hosted Models -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab Self-Managed
- Modules complémentaires : Duo Enterprise
- Liens : [Documentation](../../administration/gitlab_duo_self_hosted/_index.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/501267)

{{< /details >}}

Vous pouvez désormais héberger des grands modèles de langage (LLM) sélectionnés dans votre propre infrastructure et configurer ces modèles comme source pour GitLab Duo Chat. Cette fonctionnalité est en version bêta et disponible avec un abonnement Ultimate et Duo Enterprise sur les environnements GitLab Self-Managed.

Avec les modèles auto-hébergés, vous pouvez utiliser des modèles hébergés sur site ou dans un cloud privé comme source pour GitLab Duo Chat ou Code Suggestions (introduit comme fonctionnalité en version bêta dans GitLab 17.5). Pour Code Suggestions, nous prenons actuellement en charge les modèles Mistral open source sur vLLM ou AWS Bedrock, Claude 3.5 Sonnet sur AWS Bedrock, et les modèles OpenAI sur Azure OpenAI. Pour Chat, nous prenons actuellement en charge les modèles Mistral open source sur vLLM ou AWS Bedrock, et Claude 3.5 Sonnet sur AWS Bedrock. En activant les modèles auto-hébergés, vous pouvez tirer parti de la puissance de l'IA générative tout en maintenant une souveraineté et une confidentialité complètes des données.

Veuillez laisser vos commentaires dans [le ticket 501268](https://gitlab.com/gitlab-org/gitlab/-/issues/501268).

### Assignations améliorées des relecteurs de merge requests {#enhanced-merge-request-reviewer-assignments}

<!-- categories: Code Review Workflow -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/project/merge_requests/reviews/_index.md#request-a-review)

{{< /details >}}

Après avoir soigneusement préparé vos modifications et créé une merge request, l'étape suivante consiste à identifier les relecteurs qui peuvent aider à la faire avancer. Identifier les bons relecteurs pour votre merge request implique de comprendre qui sont les bons approbateurs et qui pourrait être un expert en la matière (CODEOWNER) pour les modifications que vous proposez.

Désormais, lors de l'assignation des relecteurs, la barre latérale crée un lien entre les exigences d'approbation de votre merge request et les relecteurs. Consultez chaque règle d'approbation, puis sélectionnez parmi les approbateurs qui peuvent satisfaire cette règle d'approbation et faire avancer la merge request pour vous. Si vous utilisez [des sections CODEOWNER optionnelles](../../user/project/codeowners/reference.md#optional-sections), ces règles sont également affichées dans la barre latérale pour vous aider à identifier les experts en la matière appropriés pour vos modifications.

Les assignations de relecteurs améliorées constituent la prochaine évolution de l'application de l'intelligence aux relecteurs assignés dans GitLab. Cette itération s'appuie sur ce que nous avons appris des relecteurs suggérés et sur la manière d'identifier efficacement les meilleurs relecteurs pour faire avancer une merge request. Dans les [prochaines itérations](https://gitlab.com/groups/gitlab-org/-/epics/14808) des assignations de relecteurs, nous continuerons à améliorer l'intelligence utilisée pour recommander et classer les relecteurs possibles.

### Prise en charge des registres de conteneurs privés dans les workspaces {#support-for-private-container-registries-in-workspaces}

<!-- categories: Workspaces -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/workspace/configuration.md#configure-support-for-private-container-registries)

{{< /details >}}

Les workspaces GitLab prennent désormais en charge les registres de conteneurs privés. Avec cette configuration, vous pouvez extraire des images de conteneurs depuis n'importe quel registre privé de votre choix. Tant que votre cluster Kubernetes dispose d'un secret d'extraction d'image valide, vous pouvez référencer le secret dans votre [configuration de l'agent GitLab](../../user/workspace/gitlab_agent_configuration.md).

Cette fonctionnalité simplifie les workflows, en particulier pour les équipes qui utilisent des registres de conteneurs personnalisés ou tiers, et améliore la flexibilité et la sécurité des environnements de développement conteneurisés.

### La marketplace d'extensions est désormais disponible dans les workspaces {#extension-marketplace-now-available-in-workspaces}

<!-- categories: Workspaces -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/project/web_ide/_index.md#manage-extensions)

{{< /details >}}

La marketplace d'extensions est désormais disponible dans les workspaces. Grâce au marketplace d'extensions, vous pouvez découvrir, installer et gérer des extensions tierces pour améliorer votre expérience de développement. Choisissez parmi des milliers d'extensions pour augmenter votre productivité ou personnaliser votre workflow.

La marketplace d'extensions est désactivée par défaut. Pour commencer, accédez à vos préférences utilisateur et [activez la marketplace d'extensions](../../user/profile/preferences.md#integrate-with-the-extension-marketplace). Pour les utilisateurs enterprise, seuls les utilisateurs ayant le rôle Owner pour un groupe principal peuvent [activer la marketplace d'extensions](../../user/enterprise_user/_index.md#enable-the-extension-marketplace-for-enterprise-users).

### Cycle de vie des workspaces amélioré avec une terminaison différée {#improved-workspace-lifecycle-with-delayed-termination}

<!-- categories: Workspaces -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/workspace/_index.md#automatic-workspace-stop-and-termination)

{{< /details >}}

Avec cette release, un workspace s'arrête désormais plutôt que de se terminer après l'expiration du délai d'attente configuré. Cette fonctionnalité signifie que vous pouvez toujours redémarrer vos workspaces et reprendre là où vous vous étiez arrêté.

Par défaut, un workspace s'arrête automatiquement :

- S'arrête 36 heures après le dernier démarrage ou redémarrage du workspace
- Se termine 722 heures après le dernier arrêt du workspace

Vous pouvez configurer ces paramètres dans votre [configuration de l'agent GitLab](../../user/workspace/gitlab_agent_configuration.md).

Avec cette fonctionnalité, un workspace reste disponible pendant environ un mois après son arrêt. Ainsi, vous conservez votre progression tout en optimisant les ressources du workspace.

### Afficher les notes de release sur la page de détails du déploiement {#display-release-notes-on-deployment-details-page}

<!-- categories: Continuous Delivery -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../ci/environments/deployment_approvals.md#view-blocked-deployments) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/493260)

{{< /details >}}

Vous êtes-vous déjà demandé ce qui pourrait être inclus dans un déploiement dont on vous a demandé l'approbation ? Dans les versions précédentes, vous pouviez créer une release avec une description détaillée de son contenu et des instructions de test, mais le déploiement spécifique à l'environnement associé n'affichait pas ces données. Nous avons le plaisir de vous annoncer que GitLab affiche désormais les notes de release sur la page de détails du déploiement associé.

Étant donné que les releases GitLab sont toujours créées à partir d'un tag Git, les notes de release ne sont affichées que sur les déploiements liés au pipeline déclenché par le tag.

Cette fonctionnalité a été contribuée à GitLab par [Anton Kalmykov](https://gitlab.com/antonkalmykov). Merci !

### Paramètre d'administration pour appliquer la liste d'autorisation des jetons de job CI/CD {#admin-setting-to-enforce-cicd-job-token-allowlist}

<!-- categories: Secrets Management -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed, GitLab Dedicated
- Liens : [Documentation](../../administration/settings/continuous_integration.md#access-job-token-permission-settings) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/496647)

{{< /details >}}

Précédemment, nous avons annoncé que le comportement par défaut du jeton de job CI/CD (`CI_JOB_TOKEN`) [changera dans GitLab 18.0](../../update/deprecations.md#cicd-job-token---authorized-groups-and-projects-allowlist-enforcement), vous obligeant à ajouter explicitement des [projets ou groupes individuels à la liste d'autorisation des jetons de job de votre projet](../../ci/jobs/ci_job_token.md#add-a-group-or-project-to-the-job-token-allowlist) si vous souhaitez qu'ils continuent à pouvoir accéder à votre projet.

Désormais, nous donnons aux administrateurs d'instances self-managed et Dedicated la possibilité d'appliquer ce paramètre plus sécurisé à tous les projets d'une instance. Après avoir activé ce paramètre, tous les projets devront utiliser leur liste d'autorisation s'ils souhaitent utiliser des jetons de job CI/CD pour l'authentification. *Remarque : nous vous recommandons d'activer ce paramètre dans le cadre d'une politique de sécurité renforcée.*

### Suivre les authentifications par jeton de job CI/CD {#track-cicd-job-token-authentications}

<!-- categories: Secrets Management -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../ci/jobs/ci_job_token.md#job-token-authentication-log) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/467292)

{{< /details >}}

Auparavant, il était difficile de suivre quels autres projets accédaient à votre projet en s'authentifiant avec des jetons de job CI/CD. Pour faciliter l'audit et le contrôle de l'accès à votre projet, nous avons ajouté un journal d'authentification.

Grâce à ce journal d'authentification, vous pouvez consulter la liste des autres projets qui ont utilisé un jeton de job pour s'authentifier auprès de votre projet, à la fois dans l'interface utilisateur et sous forme de fichier CSV téléchargeable. Ces données peuvent être utilisées pour auditer l'accès au projet et aider à renseigner la liste d'autorisation des jetons de job afin d'activer un [contrôle plus strict sur les projets pouvant accéder à votre projet](../../ci/jobs/ci_job_token.md#control-job-token-access-to-your-project).

### Regroupement des rapports de vulnérabilités {#vulnerability-report-grouping}

<!-- categories: Vulnerability Management -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/application_security/vulnerability_report/_index.md#group-vulnerabilities) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/epics/10164)

{{< /details >}}

Les utilisateurs ont besoin de pouvoir consulter les vulnérabilités par groupes. Cela aidera les analystes en sécurité à optimiser leurs tâches de triage en utilisant des actions en masse. De plus, les utilisateurs peuvent voir combien de vulnérabilités correspondent à leur groupe ; par exemple, combien de vulnérabilités figurent dans le Top 10 OWASP ?

### Le registre de modèles est désormais généralement disponible {#model-registry-now-generally-available}

<!-- categories: MLOps -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/project/ml/model_registry/_index.md) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/epics/14998)

{{< /details >}}

Le registre de modèles de GitLab, désormais généralement disponible, est votre hub centralisé pour gérer les modèles de machine learning dans le cadre de votre workflow GitLab existant. Vous pouvez suivre les versions de modèles, stocker des artefacts et des métadonnées, et maintenir une documentation complète dans la fiche de modèle.

Conçu pour une intégration transparente, le registre de modèles fonctionne nativement avec les [clients MLflow](../../user/project/ml/experiment_tracking/mlflow_client.md) et se connecte directement à vos pipelines CI/CD, permettant le déploiement et les tests automatisés de modèles. Les data scientists peuvent gérer les modèles via une interface utilisateur intuitive ou des workflows MLflow existants, tandis que les équipes MLOps peuvent tirer parti de la gestion sémantique de version et de l'intégration CI/CD pour des déploiements en production simplifiés, le tout au sein de l'[API GitLab](../../api/model_registry.md).

N'hésitez pas à nous laisser un message dans notre [ticket de feedback](https://gitlab.com/gitlab-org/gitlab/-/issues/504458) et nous vous recontacterons ! Commencez dès aujourd'hui en accédant à **Déployer > Registre de modèles** dans votre instance GitLab.

### Nouvelles configurations réseau de tenant pour GitLab Dedicated {#new-tenant-networking-configurations-for-gitlab-dedicated}

<!-- categories: GitLab Dedicated, Switchboard -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab Dedicated
- Liens : [Documentation](../../administration/dedicated/configure_instance/network_security.md#outbound-privatelink-connections)

{{< /details >}}

En tant qu'administrateur tenant de GitLab Dedicated, vous pouvez désormais utiliser Switchboard pour configurer des liens privés sortants et des zones hébergées privées. Vous pouvez également surveiller vos connexions réseau en consultant des instantanés périodiques dans Switchboard.

Les liens privés sortants et les zones hébergées privées établissent une connectivité réseau sécurisée entre les ressources de votre compte AWS et GitLab Dedicated.

### Nouveaux contrôles de conformité pour les scanners de sécurité SAST et DAST {#new-adherence-checks-for-sast-and-dast-security-scanners}

<!-- categories: Compliance Management -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/compliance/compliance_center/compliance_status_report.md) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/epics/12661)

{{< /details >}}

GitLab propose une large gamme de scanners de sécurité tels que SAST, détection des secrets, analyse des dépendances, analyse des conteneurs, et bien d'autres, pour vous permettre de vérifier la présence de vulnérabilités de sécurité dans vos applications.

Vous avez besoin d'un moyen de montrer aux auditeurs et aux autorités de conformité compétentes que vos applications ont respecté les normes réglementaires qui vous imposent de mettre en place des scanners de sécurité pour vos dépôts.

Pour vous aider à démontrer la conformité à ces normes, cette release inclut deux nouveaux contrôles dans le cadre du rapport de conformité standard du Centre de conformité. Ces nouveaux contrôles vérifient si SAST et DAST ont été activés pour les projets au sein d'un groupe. Les contrôles confirment que les scanners de sécurité SAST et DAST ont correctement fonctionné dans un projet et que les résultats du pipeline contiennent les artefacts résultants appropriés.

## Mise à l'échelle et déploiements {#scale-and-deployments}

### Événements de projet pour les webhooks de groupe {#project-events-for-group-webhooks}

<!-- categories: Notifications -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/project/integrations/webhook_events.md#project-events) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/359044)

{{< /details >}}

Dans cette release, nous avons ajouté des événements de projet aux webhooks de groupe. Les événements de projet sont déclenchés lorsque :

- Un projet est créé dans un groupe.
- Un projet est supprimé dans un groupe.

Ces événements sont déclenchés uniquement pour les [webhooks de groupe](../../user/project/integrations/webhooks.md#group-webhooks).

### Filtrer les utilisateurs GitLab Duo par siège attribué {#filter-gitlab-duo-users-by-assigned-seat}

<!-- categories: Add-on Provisioning -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Modules complémentaires : GitLab Duo Pro, GitLab Duo Enterprise
- Liens : [Documentation](../../subscriptions/subscription-add-ons.md#view-assigned-gitlab-duo-users) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/epics/14683)

{{< /details >}}

Dans les versions précédentes de GitLab, la liste des utilisateurs affichée sur la page d'attribution des sièges GitLab Duo ne pouvait pas être filtrée, ce qui rendait difficile de voir quels utilisateurs avaient précédemment reçu un siège GitLab Duo. Désormais, vous pouvez filtrer votre liste d'utilisateurs par Siège attribué = Oui ou Siège attribué = Non pour voir quels utilisateurs sont actuellement assignés ou non à un siège GitLab Duo, facilitant ainsi l'ajustement des allocations de sièges.

### Mise à jour de l'e-mail d'attribution de siège GitLab Duo {#gitlab-duo-seat-assignment-email-update}

<!-- categories: Seat Cost Management -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed
- Modules complémentaires : Duo Pro, Duo Enterprise
- Liens : [Documentation](../../subscriptions/subscription-add-ons.md#assign-gitlab-duo-seats) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/170507)

{{< /details >}}

Tous les utilisateurs des instances self-managed recevront un e-mail lorsqu'un siège GitLab Duo leur sera attribué.

Auparavant, les personnes auxquelles un siège Duo Enterprise était attribué ou celles qui obtenaient l'accès par attribution en masse n'étaient pas notifiées. Vous ne sauriez pas qu'un siège vous a été attribué à moins que quelqu'un ne vous le dise ou que vous ne remarquiez une nouvelle fonctionnalité dans l'interface utilisateur de GitLab.

Pour désactiver cet e-mail, un administrateur peut désactiver le feature flag `duo_seat_assignment_email_for_sm`.

## DevOps et sécurité unifiés {#unified-devops-and-security}

### Priorisation efficace des risques avec EPSS {#efficient-risk-prioritization-with-epss}

<!-- categories: Software Composition Analysis -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../api/graphql/reference/_index.md#cveenrichmenttype) \| [Ticket associé](https://gitlab.com/groups/gitlab-org/-/epics/11544)

{{< /details >}}

Dans GitLab 17.6, nous avons ajouté la prise en charge du système de notation prédictive des exploits (EPSS). EPSS attribue à chaque CVE un score compris entre 0 et 1 indiquant la probabilité que la CVE soit exploitée dans les 30 prochains jours. Vous pouvez utiliser EPSS pour mieux prioriser les résultats des analyses et évaluer l'impact potentiel qu'une vulnérabilité peut avoir sur votre environnement.

Ces données sont disponibles pour les utilisateurs de l'analyse de composition via GraphQL.

### Activer la protection contre les push de secrets dans vos projets via l'API {#enable-secret-push-protection-in-your-projects-via-api}

<!-- categories: Secret Detection -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../api/projects.md)

{{< /details >}}

Il est désormais plus facile d'activer la protection contre les push de secrets de manière programmatique. Nous avons mis à jour l'API REST des paramètres d'application, ce qui vous permet de :

1. Activer la fonctionnalité dans votre instance self-managed afin qu'elle puisse être activée par projet.
1. Vérifier si la fonctionnalité a été activée sur un projet.
1. Activer la fonctionnalité pour un projet spécifié.

### Événements d'audit de Secret Push Protection pour les exclusions appliquées {#secret-push-protection-audit-events-for-applied-exclusions}

<!-- categories: Secret Detection -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/application_security/secret_detection/exclusions.md)

{{< /details >}}

Les événements d'audit sont désormais enregistrés lorsqu'une exclusion de protection contre les push de secrets est appliquée. Cela permet aux équipes de sécurité d'auditer et de suivre toute occurrence où un secret figurant sur la liste d'exclusions du projet est autorisé à être poussé.

### Repository X-Ray automatisé {#automated-repository-x-ray}

<!-- categories: Code Suggestions -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Modules complémentaires : Duo Pro, Duo Enterprise
- Liens : [Documentation](../../user/project/repository/code_suggestions/repository_xray.md) \| [Ticket associé](https://gitlab.com/groups/gitlab-org/-/epics/14100)

{{< /details >}}

Repository X-Ray enrichit les demandes de génération de code pour GitLab Duo Code Suggestions en fournissant un contexte supplémentaire sur les dépendances d'un projet afin d'améliorer la précision et la pertinence des recommandations de code. Cela améliore la qualité de la génération de code. Auparavant, Repository X-Ray utilisait un job CI que vous deviez configurer et gérer.

Désormais, lorsqu'un nouveau commit est poussé vers la branche par défaut de votre projet, Repository X-Ray déclenche automatiquement un job en arrière-plan qui analyse et parse les fichiers de configuration applicables dans votre dépôt.

### Prise en charge des réseaux d'entreprise pour GitLab Duo {#corporate-network-support-for-gitlab-duo}

<!-- categories: Editor Extensions -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../editor_extensions/language_server/_index.md#enable-proxy-authentication) \| [Ticket associé](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/issues/159)

{{< /details >}}

La dernière mise à jour du plugin GitLab Duo introduit une authentification proxy avancée. Cela permet aux développeurs de se connecter de manière transparente dans des environnements avec des pare-feu d'entreprise stricts. S'appuyant sur notre prise en charge existante du proxy HTTP, cette amélioration permet des connexions authentifiées. Elle assure un accès sécurisé et ininterrompu aux fonctionnalités Duo dans VS Code et les IDE JetBrains.

Cette mise à jour est essentielle pour les développeurs ayant besoin de connexions sécurisées et authentifiées dans des environnements réseau restreints. Elle garantit que toutes les fonctionnalités Duo restent disponibles sans compromettre la sécurité.

### Fusionner à une date et une heure planifiées {#merge-at-a-scheduled-date-and-time}

<!-- categories: Code Review Workflow -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/project/merge_requests/auto_merge.md#prevent-merge-before-a-specific-date)

{{< /details >}}

Certaines merge requests peuvent devoir être retenues jusqu'après une certaine date ou heure. Lorsque cette date et heure arrivent, vous devez trouver quelqu'un disposant des autorisations nécessaires pour fusionner et espérer qu'il soit disponible pour s'en occuper. Si cela survient en dehors des heures de travail ou si le calendrier est critique, vous devrez peut-être préparer des personnes bien à l'avance pour cette tâche.

Désormais, lorsque vous créez ou modifiez une merge request, vous pouvez spécifier une date `merge after`. Cette date sera utilisée pour empêcher la merge request d'être fusionnée jusqu'à ce qu'elle soit passée. L'utilisation de cette nouvelle fonctionnalité avec nos [améliorations de l'auto-merge](https://about.gitlab.com/releases/2024/09/19/gitlab-17-4-released/#auto-merge-when-all-checks-pass) précédemment publiées vous offre la flexibilité de planifier la fusion des merge requests dans le futur.

Un grand merci à [Niklas van Schrick](https://gitlab.com/Taucher2003) pour cette incroyable contribution !

### Ajouter la prise en charge des valeurs à la commande `glab agent bootstrap` {#add-support-for-values-to-the-glab-agent-bootstrap-command}

<!-- categories: Deployment Management -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](https://gitlab.com/gitlab-org/cli/-/blob/main/docs/source/cluster/agent/bootstrap.md#options) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/482844)

{{< /details >}}

Dans la dernière release, nous avons introduit la prise en charge du bootstrapping facile des agents dans l'outil CLI GitLab. GitLab 17.6 améliore encore la commande `glab cluster agent bootstrap` avec la prise en charge des valeurs Helm personnalisées. Vous pouvez utiliser les flags `--helm-release-values` et `--helm-release-values-from` pour personnaliser la ressource `HelmRelease` générée.

### Sélectionner un agent GitLab pour un environnement dans un job CI/CD {#select-a-gitlab-agent-for-an-environment-in-a-cicd-job}

<!-- categories: Environment Management -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../ci/environments/kubernetes_dashboard.md#configure-a-dashboard-for-a-dynamic-environment) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/467912)

{{< /details >}}

Pour utiliser le tableau de bord pour Kubernetes, vous devez sélectionner un agent pour la connexion Kubernetes dans les paramètres d'environnement. Jusqu'à présent, vous pouviez sélectionner l'agent uniquement depuis l'interface utilisateur ou (depuis GitLab 17.5) l'API, ce qui rendait difficile la configuration d'un tableau de bord depuis CI/CD. Dans GitLab 17.6, vous pouvez configurer une connexion d'agent avec la syntaxe `environment.kubernetes.agent`. De plus, [le ticket 500164](https://gitlab.com/gitlab-org/gitlab/-/issues/500164) propose d'ajouter la prise en charge de la sélection d'un espace de nommage et d'une ressource Flux depuis votre configuration CI/CD.

### Événements d'audit pour les actions privilégiées {#audit-events-for-privileged-actions}

<!-- categories: Audit Events -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed
- Liens : [Documentation](../../user/compliance/audit_event_types.md#groups-and-projects) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/486532)

{{< /details >}}

Il existe désormais des événements d'audit supplémentaires pour les actions administrateur liées aux paramètres privilégiés. Un enregistrement des modifications apportées à ces paramètres peut contribuer à améliorer la sécurité en fournissant une piste d'audit.

### Nouvel événement d'audit lors de la fusion des merge requests {#new-audit-event-when-merge-requests-are-merged}

<!-- categories: Audit Events -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/compliance/audit_event_types.md#compliance-management) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/442279)

{{< /details >}}

Avec cette release, lorsqu'une merge request est fusionnée, un nouveau type d'événement d'audit appelé `merge_request_merged` est déclenché et contient des informations clés sur la merge request, notamment :

- Le titre de la merge request
- La description ou le résumé de la merge request
- Le nombre d'approbations requises pour la fusion
- Le nombre d'approbations accordées pour la fusion
- Les utilisateurs qui ont approuvé la merge request
- Si les commiteurs ont approuvé la merge request
- Si les auteurs ont approuvé la merge request
- La date et l'heure de la fusion
- La liste des SHA de l'historique des commits

### Désactiver l'authentificateur OTP et les appareils WebAuthn indépendamment {#disable-otp-authenticator-and-webauthn-devices-independently}

<!-- categories: System Access -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/profile/account/two_factor_authentication.md#disable-two-factor-authentication) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/393419)

{{< /details >}}

Il est désormais possible de désactiver l'authentificateur OTP et les appareils WebAuthn individuellement ou simultanément. Auparavant, si vous désactiviez l'authentificateur OTP, le ou les appareils WebAuthn étaient également désactivés. Étant donné que les deux fonctionnent désormais indépendamment, il existe un contrôle plus granulaire sur ces méthodes d'authentification.

### Utiliser l'API pour obtenir des informations sur les jetons {#use-api-to-get-information-about-tokens}

<!-- categories: System Access -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed
- Liens : [Documentation](../../api/admin/token.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/443597)

{{< /details >}}

Les administrateurs peuvent utiliser la nouvelle API d'informations sur les jetons pour obtenir des informations sur les jetons d'accès personnels, les jetons de déploiement et les jetons de flux. Contrairement aux autres points de terminaison d'API qui exposent des informations sur les jetons, ce point de terminaison permet aux administrateurs de récupérer des informations sur les jetons sans connaître leur type.

Merci à [Nicholas Wittstruck](https://gitlab.com/nwittstruck) et au reste de l'équipe de Siemens pour votre contribution !

### Plus d'informations dans les e-mails de connexion depuis de nouveaux emplacements {#more-information-in-sign-in-emails-from-new-locations}

<!-- categories: System Access -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed
- Liens : [Documentation](../../user/profile/notifications.md#notifications-for-unknown-sign-ins) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/296128)

{{< /details >}}

GitLab envoie optionnellement un e-mail lorsqu'une connexion depuis un nouvel emplacement est détectée. Auparavant, cet e-mail ne contenait que l'adresse IP, difficile à associer à un emplacement géographique. Cet e-mail contient désormais également des informations de localisation par ville et par pays.

Merci à [Henry Helm](https://gitlab.com/shangsuru) pour votre contribution !

### Empêcher la modification des branches protégées de groupe {#prevent-modification-of-group-protected-branches}

<!-- categories: Security Policy Management -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/application_security/policies/merge_request_approval_policies.md#approval_settings) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/epics/13776)

{{< /details >}}

Lorsqu'une politique d'approbation des merge requests est configurée pour empêcher la modification des branches de groupe, les politiques prennent désormais en compte les branches protégées configurées pour un groupe. Ce paramètre garantit que les branches protégées au niveau du groupe ne peuvent pas être déprotégées. Les branches protégées restreignent certaines actions, telles que la suppression de la branche et le push forcé vers la branche. Vous pouvez remplacer ce comportement et déclarer des exceptions pour des groupes principaux spécifiques avec la nouvelle propriété `approval_settings.block_group_branch_modification` pour permettre aux propriétaires de groupe de modifier temporairement les branches protégées si nécessaire.

Ce nouveau paramètre de remplacement de projet garantit que les paramètres de branches protégées de groupe ne peuvent pas être modifiés pour contourner les exigences de sécurité et de conformité, assurant ainsi une application plus stable des branches protégées.

### Les propriétaires de groupe principal peuvent créer des comptes de service {#top-level-group-owners-can-create-service-accounts}

<!-- categories: System Access -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed
- Liens : [Documentation](../../administration/settings/account_and_limit_settings.md#allow-top-level-group-owners-to-create-service-accounts) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/468806)

{{< /details >}}

Actuellement, seuls les administrateurs peuvent créer des comptes de service sur GitLab Self-Managed. Désormais, il existe un paramètre optionnel qui permet aux propriétaires de groupe principal de créer des comptes de service. Cela permet aux administrateurs de choisir s'ils souhaitent autoriser un plus large éventail de rôles à créer des comptes de service, ou de conserver cette tâche comme réservée aux administrateurs.

### Badge des comptes de service {#service-accounts-badge}

<!-- categories: System Access -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/profile/service_accounts.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/439768)

{{< /details >}}

Les comptes de service disposent désormais d'un badge désigné et peuvent être facilement identifiés dans la liste des utilisateurs. Auparavant, ces comptes n'avaient que le badge `bot`, ce qui rendait difficile de les distinguer des jetons d'accès de groupe et de projet.

### Déployez votre site Pages avec n'importe quel job CI/CD {#deploy-your-pages-site-with-any-cicd-job}

<!-- categories: Pages -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/project/pages/_index.md#user-defined-job-names)

{{< /details >}}

Pour vous offrir plus de flexibilité dans la conception de vos pipelines, vous n'avez plus besoin de nommer votre job de déploiement Pages `pages`. Vous pouvez désormais simplement utiliser l'attribut `pages` dans n'importe quel job CI/CD pour déclencher un déploiement Pages.

### API AI Impact Analytics pour GitLab Duo Pro {#ai-impact-analytics-api-for-gitlab-duo-pro}

<!-- categories: Value Stream Management -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Modules complémentaires : Duo Pro, Duo Enterprise
- Liens : [Documentation](../../api/graphql/reference/_index.md#aimetrics)

{{< /details >}}

Les clients GitLab Duo Pro peuvent désormais accéder de manière programmatique aux métriques AI Impact Analytics avec l'API GraphQL `aiMetrics`. Les métriques incluent le nombre de sièges GitLab Duo attribués, les utilisateurs de Duo Chat et les utilisateurs de Code Suggestions. L'API fournit également des décomptes détaillés des suggestions de code affichées et acceptées. Avec ces données, vous pouvez calculer le taux d'acceptation pour Code Suggestions et mieux comprendre l'adoption de Duo Chat et de Code Suggestions par vos utilisateurs Duo Pro. Vous pouvez également associer les métriques AI Impact Analytics aux métriques Value Stream Analytics et DORA pour obtenir une vision plus approfondie de l'impact de l'adoption de Duo Chat et de Code Suggestions sur la productivité de votre équipe.

### Masquer facilement les éléments fermés de votre vue {#easily-remove-closed-items-from-your-view}

<!-- categories: Portfolio Management -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/group/epics/manage_epics.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/456941)

{{< /details >}}

Vous pouvez désormais masquer les éléments fermés des listes d'éléments liés et enfants en désactivant le bouton bascule **Afficher les éléments fermés**. Grâce à cet ajout, vous avez un meilleur contrôle sur votre vue et pouvez vous concentrer sur les travaux actifs tout en réduisant l'encombrement visuel dans les projets complexes.

### Interroger les métriques d'utilisation de GitLab Duo Enterprise au niveau utilisateur {#query-user-level-gitlab-duo-enterprise-usage-metrics}

<!-- categories: Value Stream Management -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Modules complémentaires : Duo Enterprise
- Liens : [Documentation](../../api/graphql/reference/_index.md#aiusermetrics) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/483049)

{{< /details >}}

Avant cette release, il n'était pas possible d'obtenir des données d'utilisation de GitLab Duo Chat et Code Suggestions par utilisateur Duo Enterprise. Dans la version 17.6, nous avons ajouté une API GraphQL pour fournir une visibilité sur le nombre de suggestions de code acceptées et les interactions Duo Chat pour chaque utilisateur Duo Enterprise actif. L'API peut vous aider à obtenir une vue plus granulaire sur qui utilise quelles fonctionnalités Duo Enterprise et à quelle fréquence. Il s'agit de la première itération vers notre objectif de [fournir des données d'utilisation Duo Enterprise plus complètes](https://gitlab.com/groups/gitlab-org/-/epics/15026) au sein de GitLab.

### Prise en charge des données de licence provenant des SBOM CycloneDX {#support-for-license-data-from-cyclonedx-sboms}

<!-- categories: Software Composition Analysis -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../ci/yaml/artifacts_reports.md#artifactsreportscyclonedx) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/415935)

{{< /details >}}

Le scanner de licences peut désormais consommer la licence d'une dépendance depuis un SBOM CycloneDX incluant des [types de packages pris en charge](../../user/compliance/license_scanning_of_cyclonedx_files/_index.md#supported-languages-and-package-managers).

Dans les cas où le champ `licenses` d'un SBOM CycloneDX est disponible, les utilisateurs verront les données de licence provenant de leur SBOM. Dans les cas où le SBOM ne contient pas d'informations de licence, nous continuerons à fournir ces données depuis notre base de données de licences.

### Image de job macOS Sequoia 15 et Xcode 16 {#macos-sequoia-15-and-xcode-16-job-image}

<!-- categories: GitLab Hosted Runners -->

{{< details >}}

- Édition : Silver, Gold
- Offre : GitLab.com
- Liens : [Documentation](../../ci/runners/hosted_runners/macos.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/502852)

{{< /details >}}

Vous pouvez désormais créer, tester et déployer des applications pour les dernières générations d'appareils Apple en utilisant macOS Sequoia 15 et Xcode 16.

Les [runners hébergés de GitLab sur macOS](../../ci/runners/hosted_runners/macos.md) aident vos équipes de développement à créer et déployer des applications macOS plus rapidement dans un environnement de build sécurisé et à la demande, intégré à GitLab CI/CD.

Essayez-le dès aujourd'hui en utilisant l'image `macos-15-xcode-16` dans votre fichier `.gitlab-ci.yml`.

### La visualisation de la couverture de tests JaCoCo est désormais généralement disponible {#jacoco-test-coverage-visualization-now-generally-available}

<!-- categories: Code Testing and Coverage -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../ci/testing/code_coverage/jacoco.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/227345)

{{< /details >}}

Vous pouvez désormais voir les résultats de couverture de tests JaCoCo directement dans la vue diff de votre merge request. Cette visualisation vous permet d'identifier rapidement quelles lignes sont couvertes par les tests et lesquelles nécessitent une couverture supplémentaire avant la fusion.

### GitLab Runner 17.6 {#gitlab-runner-176}

<!-- categories: GitLab Runner Core -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed
- Liens : [Documentation](https://docs.gitlab.com/runner)

{{< /details >}}

Nous publions également GitLab Runner 17.6 aujourd'hui ! GitLab Runner est l'agent de build hautement évolutif qui exécute vos jobs CI/CD et envoie les résultats à une instance GitLab. GitLab Runner fonctionne en conjonction avec GitLab CI/CD, le service d'intégration continue open source inclus avec GitLab.

#### Corrections de bugs {#bug-fixes}

- [Dans GitLab Runner 17.5.0, les pods échouent à devenir attachables](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/38260)
- [Le runner plante avec `exec format error` lors de l'installation du plugin fleeting](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/38247)
- [Les pods de l'exécuteur Kubernetes avec cgroup v2 activé se bloquent lors d'un OOMKilled](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/38244)
- [Les valeurs par défaut du runner ne sont pas respectées lors de l'enregistrement du runner avec un modèle de configuration](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/38231)
- [GitLab Runner attend que les pods Kubernetes deviennent attachables pendant la période de polling lors de l'utilisation du mode exec](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/37244)
- [Des problèmes d'authentification surviennent lorsque le feature flag `FF_GIT_URLS_WITHOUT_TOKENS` est activé](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/38268)

## Sujets connexes {#related-topics}

- [Correctifs de bugs](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=type%3A%3Abug&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=17.6)
- [Améliorations des performances](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=bug%3A%3Aperformance&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=17.6)
- [Améliorations de l'interface utilisateur](https://papercuts.gitlab.com/?milestone=17.6)
- [Dépréciations et suppressions](../../update/deprecations.md)
- [Notes de mise à niveau](../../update/versions/_index.md)
