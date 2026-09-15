---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Présentation des jetons GitLab
description: "Comprendre les différents jetons d'authentification et leurs implications en matière de sécurité."
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Ce document répertorie les jetons utilisés dans GitLab, leur objectif et, le cas échéant, des conseils de sécurité.

## Considérations de sécurité {#security-considerations}

Pour sécuriser vos jetons :

- Traitez les jetons comme des mots de passe et conservez-les en lieu sûr.
- Lorsque vous créez un jeton à portée limitée, utilisez la portée la plus restreinte possible pour réduire l'impact d'une fuite accidentelle du jeton.
  - Si des processus distincts nécessitent des portées différentes (par exemple, `read` et `write`), envisagez d'utiliser des jetons distincts pour chaque portée. Si un jeton est compromis, il donne accès à moins de ressources qu'un jeton unique avec une portée étendue, comme un accès complet à l'API.
- Lors de la création d'un jeton :
  - Choisissez un nom en suivant les [consignes de nommage des jetons](#token-naming-guidance) ci-dessous.
  - Envisagez de définir une date d'expiration du jeton à la fin de votre tâche. Par exemple, si vous devez effectuer une importation unique, définissez une expiration du jeton après quelques heures.
  - Ajoutez une description fournissant davantage de contexte, notamment les URL pertinentes.
- Transmettez les jetons via des en-têtes plutôt que via des URL :
  - Utilisez `PRIVATE-TOKEN` pour les jetons d'accès personnels, de projet et de groupe.
  - Utilisez `JOB-TOKEN` pour les jetons de job.
- Si vous disposez d'un environnement de démonstration, révoquez tous les jetons après avoir enregistré des vidéos ou publié des articles de blog sur vos projets.
- Vous pouvez stocker les jetons à l'aide du [stockage des informations d'identification Git](https://git-scm.com/book/en/v2/Git-Tools-Credential-Storage).
- Vérifiez régulièrement tous les jetons d'accès actifs de tous types et révoquez ceux dont vous n'avez plus besoin.

À ne pas faire :

- Ajouter des jetons aux URL :
  - Lors du clonage ou de l'ajout d'un dépôt distant avec un jeton dans l'URL, Git écrit l'URL dans son fichier `.git/config` en texte clair.
  - Les URL sont souvent journalisées par les proxys et les serveurs d'applications, ce qui pourrait exposer ces informations d'identification aux administrateurs système.
- Stocker les jetons en texte clair dans vos projets.
  - Si le jeton est un secret externe pour GitLab CI/CD, consultez la procédure pour [utiliser des secrets externes dans CI/CD](../../ci/secrets/_index.md).
- Inclure des jetons lors du collage de code, de commandes de console ou de sorties de journaux dans un ticket, une description de merge request, un commentaire ou tout autre champ de texte libre.
- Journaliser des informations d'identification dans les journaux de console ou les artefacts. Pensez à [protéger](../../ci/variables/_index.md#protect-a-cicd-variable) et à [masquer](../../ci/variables/_index.md#mask-a-cicd-variable) vos informations d'identification.

### Consignes de nommage des jetons {#token-naming-guidance}

Une convention de nommage cohérente facilite l'audit des jetons d'accès, la compréhension de leur objectif et l'évaluation de l'impact de la rotation ou de la révocation de chaque jeton.

Les conventions de nommage varient selon les équipes, mais une convention utile répond aux questions suivantes :

- Quelle action le jeton effectue-t-il ? Par exemple, `ci-deploy` ou `api-read`.
- Sur quelle ressource ou quel service le jeton agit-il ? Par exemple, `gitlab` ou `terraform`.
- À quel environnement ou propriétaire le jeton est-il associé ? Par exemple, `production` ou `auth-team`.

Par exemple :

| Nom du jeton | Objectif |
| --- | --- |
| `ci-deploy-gitlab-production` | Job de déploiement CI/CD pour le projet GitLab en production |
| `api-read-reporting-dashboard` | Accès API en lecture seule pour un tableau de bord de reporting |
| `automation-sync-vulnmapper-staging` | Script d'automatisation synchronisant les données en staging |

- Soyez précis. Évitez les noms génériques comme `test`, `mytoken`, `token1`, `GITLAB_API_TOKEN`, `API_TOKEN` ou `default`. Ces noms rendent impossible l'identification de l'objectif d'un jeton lors d'un audit.
- Incluez le système ou l'outil consommateur. Si un jeton est utilisé par une application, un script ou une intégration spécifique, incluez son nom. Par exemple : `terraform-state-backend` ou `grafana-metrics-reader`.
- Incluez l'environnement. Le cas échéant, indiquez si le jeton cible `production`, `staging` ou `development`. Cela évite l'utilisation accidentelle d'un jeton de production dans un environnement inférieur.
- Évitez d'intégrer des informations sensibles. N'incluez pas de noms d'utilisateur, d'adresses e-mail ou toute autre information personnellement identifiable (PII) dans les noms de jetons, car les noms de jetons sont visibles dans les journaux d'audit et l'interface.
- Définissez des règles de capitalisation et de ponctuation standardisées. L'utilisation d'une capitalisation et de séparateurs cohérents facilite la lecture et la recherche de jetons. Par exemple, l'utilisation de tirets (-) plutôt que de traits de soulignement (_).
- Utilisez le champ de description. Le champ de description du jeton vous permet d'ajouter des détails supplémentaires tels que des liens vers des tickets connexes ou les noms des équipes qui utilisent le jeton.

### Jetons dans CI/CD {#tokens-in-cicd}

Évitez d'utiliser des jetons d'accès personnels comme variables CI/CD dans la mesure du possible en raison de leur large portée. Si un accès à d'autres ressources est requis depuis un job CI/CD, utilisez l'une des options suivantes, classées de la portée d'accès la plus restreinte à la plus étendue :

1. Jetons de job (portée d'accès la plus restreinte)
1. Jetons de projet
1. Jetons de groupe

Des recommandations supplémentaires concernant la [sécurité des variables CI/CD](../../ci/variables/_index.md#cicd-variable-security) incluent :

- Utilisez le [stockage des secrets](../../ci/pipeline_security/_index.md#secrets-storage) pour toutes les informations d'identification.
- Les variables CI/CD contenant des informations sensibles doivent être [protégées](../../ci/variables/_index.md#protect-a-cicd-variable), [masquées](../../ci/variables/_index.md#mask-a-cicd-variable) et [cachées](../../ci/variables/_index.md#hide-a-cicd-variable).

## Jetons d'accès personnels {#personal-access-tokens}

Vous pouvez créer des [jetons d'accès personnels](../../user/profile/personal_access_tokens.md) pour vous authentifier avec :

- L'API GitLab
- Les dépôts GitLab
- Le registre GitLab

Vous pouvez limiter la portée et la date d'expiration de vos jetons d'accès personnels. Par défaut, ils héritent des permissions de l'utilisateur qui les a créés.

Vous pouvez utiliser l'API des jetons d'accès personnels pour effectuer des actions par programmation, comme [faire pivoter un jeton d'accès personnel](../../api/personal_access_tokens.md#rotate-a-personal-access-token).

Vous [recevez un e-mail](../../user/profile/personal_access_tokens.md#personal-access-token-expiry-emails) lorsque vos jetons d'accès personnels arrivent bientôt à expiration.

Lorsque vous envisagez un job CI/CD nécessitant des jetons pour les permissions, évitez d'utiliser des jetons d'accès personnels, surtout s'ils sont stockés en tant que variable CI/CD. Les jetons de job CI/CD et les jetons d'accès au projet permettent souvent d'obtenir le même résultat avec beaucoup moins de risques.

## Jetons OAuth 2.0 {#oauth-20-tokens}

GitLab peut servir de [fournisseur OAuth 2.0](../../api/oauth2.md) pour permettre à d'autres services d'accéder à l'API GitLab au nom d'un utilisateur.

Vous pouvez limiter la portée et la durée de vie de vos jetons OAuth 2.0.

## Jetons d'usurpation d'identité {#impersonation-tokens}

Un [jeton d'usurpation d'identité](../../api/rest/authentication.md#impersonation-tokens) est un type spécial de jeton d'accès personnel. Il ne peut être créé que par un administrateur pour un utilisateur spécifique. Les jetons d'usurpation d'identité peuvent vous aider à créer des applications ou des scripts qui s'authentifient auprès de l'API GitLab, des dépôts et du registre GitLab en tant qu'utilisateur spécifique.

Vous pouvez limiter la portée et définir une date d'expiration pour un jeton d'usurpation d'identité.

## Jetons d'accès au projet {#project-access-tokens}

Les [jetons d'accès au projet](../../user/project/settings/project_access_tokens.md) sont limités à un projet. Comme les jetons d'accès personnels, vous pouvez les utiliser pour vous authentifier avec :

- L'API GitLab
- Les dépôts GitLab
- Le registre GitLab

Vous pouvez limiter la portée et la date d'expiration des jetons d'accès au projet. Lorsque vous créez un jeton d'accès au projet, GitLab crée un [utilisateur bot pour les projets](../../user/project/settings/project_access_tokens.md#bot-users-for-projects). Les utilisateurs bot pour les projets sont des comptes de service et ne sont pas comptabilisés dans les sièges sous licence.

Vous pouvez utiliser l'[API des jetons d'accès au projet](../../api/project_access_tokens.md) pour effectuer des actions par programmation, comme [faire pivoter un jeton d'accès au projet](../../api/project_access_tokens.md#rotate-a-project-access-token).

Les membres d'un projet ayant le rôle Maintainer ou Owner [reçoivent un e-mail](../../user/project/settings/project_access_tokens.md#project-access-token-expiry-emails) lorsque les jetons d'accès au projet arrivent bientôt à expiration.

## Jetons d'accès de groupe {#group-access-tokens}

Les [jetons d'accès de groupe](../../user/group/settings/group_access_tokens.md) sont limités à un groupe. Comme les jetons d'accès personnels, vous pouvez les utiliser pour vous authentifier avec :

- L'API GitLab
- Les dépôts GitLab
- Le registre GitLab

Vous pouvez limiter la portée et la date d'expiration des jetons d'accès de groupe. Lorsque vous créez un jeton d'accès de groupe, GitLab crée un [utilisateur bot pour les groupes](../../user/group/settings/group_access_tokens.md#bot-users-for-groups). Les utilisateurs bot pour les groupes sont des comptes de service et ne sont pas comptabilisés dans les sièges sous licence.

Vous pouvez utiliser l'[API des jetons d'accès de groupe](../../api/group_access_tokens.md) pour effectuer des actions par programmation, comme [faire pivoter un jeton d'accès de groupe](../../api/group_access_tokens.md#rotate-a-group-access-token).

Les membres d'un groupe ayant le rôle Owner [reçoivent un e-mail](../../user/group/settings/group_access_tokens.md#group-access-token-expiry-emails) lorsque les jetons d'accès de groupe arrivent bientôt à expiration.

## Jetons de déploiement {#deploy-tokens}

Les [jetons de déploiement](../../user/project/deploy_tokens/_index.md) vous permettent de cloner, pousser et récupérer des paquets et des images de registre de conteneurs d'un projet sans nom d'utilisateur ni mot de passe. Les jetons de déploiement ne peuvent pas être utilisés avec l'API GitLab.

Pour gérer les jetons de déploiement, vous devez être membre d'un projet avec au moins le rôle Maintainer.

## Clés de déploiement {#deploy-keys}

Les [clés de déploiement](../../user/project/deploy_keys/_index.md) permettent un accès en lecture seule ou en lecture-écriture à vos dépôts en important une clé publique SSH dans votre instance GitLab. Les clés de déploiement ne peuvent pas être utilisées avec l'API GitLab ou le registre.

Vous pouvez utiliser des clés de déploiement pour cloner des dépôts sur votre serveur d'intégration continue sans créer de faux compte utilisateur.

Pour ajouter ou activer une clé de déploiement pour un projet, vous devez avoir au moins le rôle Maintainer.

## Jetons d'authentification des runners {#runner-authentication-tokens}

Pour enregistrer un runner, vous pouvez utiliser un jeton d'authentification de runner à la place d'un jeton d'enregistrement de runner. Les jetons d'enregistrement de runner sont [dépréciés](../../ci/runners/new_creation_workflow.md).

Après avoir créé un runner et sa configuration, vous recevez un jeton d'authentification de runner que vous utilisez pour enregistrer le runner. Le jeton d'authentification du runner est stocké localement dans le fichier [`config.toml`](https://docs.gitlab.com/runner/configuration/advanced-configuration/), que vous utilisez pour configurer le runner.

Le runner utilise le jeton d'authentification du runner pour s'authentifier auprès de GitLab lorsqu'il récupère des jobs de la file d'attente. Une fois que le runner s'est authentifié auprès de GitLab, il reçoit un [jeton de job](../../ci/jobs/ci_job_token.md), qu'il utilise pour exécuter le job.

Le jeton d'authentification du runner reste sur la machine du runner. Les environnements d'exécution des exécuteurs suivants n'ont accès qu'au jeton de job et non au jeton d'authentification du runner :

- Docker Machine
- Kubernetes
- VirtualBox
- Parallels
- SSH

Un accès malveillant au système de fichiers d'un runner pourrait exposer le fichier `config.toml` et le jeton d'authentification du runner. L'attaquant pourrait utiliser le jeton d'authentification du runner pour [cloner le runner](https://docs.gitlab.com/runner/security/#cloning-a-runner).

Vous pouvez utiliser l'API des runners pour [faire pivoter ou révoquer un jeton d'authentification de runner](../../api/runners.md#reset-runners-authentication-token-by-using-the-current-token).

## Jetons d'enregistrement de runners (hérité) {#runner-registration-tokens-legacy}

> [!warning]
> L'option de transmission des jetons d'enregistrement de runners et la prise en charge de certains arguments de configuration sont considérées comme héritées et ne sont pas recommandées. Utilisez le [workflow de création de runner](https://docs.gitlab.com/runner/register/#register-with-a-runner-authentication-token) pour générer un jeton d'authentification permettant d'enregistrer des runners. Ce processus offre une traçabilité complète de la propriété des runners et renforce la sécurité de votre flotte de runners. GitLab a mis en œuvre une nouvelle [architecture de jetons GitLab Runner](../../ci/runners/new_creation_workflow.md), qui introduit une nouvelle méthode d'enregistrement des runners et supprime le jeton d'enregistrement de runner.

Les jetons d'enregistrement de runners sont utilisés pour [enregistrer](https://docs.gitlab.com/runner/register/) un [runner](https://docs.gitlab.com/runner/) auprès de GitLab. Les propriétaires de groupes ou de projets, ou les administrateurs d'instance, peuvent les obtenir via l'interface utilisateur GitLab. Le jeton d'enregistrement est limité à l'enregistrement des runners et n'a pas d'autre portée.

Vous pouvez utiliser le jeton d'enregistrement de runner pour ajouter des runners qui exécutent des jobs dans un projet ou un groupe. Le runner a accès au code du projet, donc soyez prudent lors de l'attribution des permissions aux projets ou aux groupes.

## Jetons de job CI/CD {#cicd-job-tokens}

Le jeton de job [CI/CD](../../ci/jobs/ci_job_token.md) est un jeton de courte durée valable uniquement pour la durée d'un job. Il donne à un job CI/CD l'accès à un nombre limité de points de terminaison de l'API. L'authentification API utilise le jeton de job en se basant sur l'autorisation de l'utilisateur qui déclenche le job.

Le jeton de job est sécurisé par sa courte durée de vie et sa portée limitée. Ce jeton pourrait être compromis si plusieurs jobs s'exécutent sur la même machine (par exemple, avec le [runner shell](https://docs.gitlab.com/runner/security/#usage-of-shell-executor)). Vous pouvez utiliser la [liste d'autorisation du projet](../../ci/jobs/ci_job_token.md#add-a-group-or-project-to-the-job-token-allowlist) pour limiter davantage ce à quoi le jeton de job peut accéder.

Sur les runners Docker Machine, vous devez configurer [`MaxBuilds=1`](https://docs.gitlab.com/runner/configuration/advanced-configuration/#the-runnersmachine-section) pour vous assurer que les machines du runner n'exécutent qu'un seul build et sont détruites ensuite. Le provisionnement prend du temps, donc cette configuration peut affecter les performances.

## Jetons de l'agent de cluster GitLab {#gitlab-cluster-agent-tokens}

Lorsque vous [enregistrez un agent GitLab pour Kubernetes](../../user/clusters/agent/install/_index.md#register-the-agent-with-gitlab), GitLab génère un jeton d'accès pour authentifier l'agent de cluster auprès de GitLab.

Pour révoquer ce jeton d'agent de cluster, vous pouvez :

- Révoquer le jeton avec l'[API des agents](../../api/cluster_agents.md#revoke-an-agent-token)
- [Réinitialiser le jeton](../../user/clusters/agent/work_with_agent.md#reset-the-agent-token)

Pour les deux méthodes, vous devez connaître les identifiants du jeton, de l'agent et du projet. Pour trouver ces informations, utilisez la [console Rails](../../administration/operations/rails_console.md) :

```ruby
# Find token ID
Clusters::AgentToken.find_by_token('glagent-xxx').id

# Find agent ID
Clusters::AgentToken.find_by_token('glagent-xxx').agent.id
=> 1234

# Find project ID
Clusters::AgentToken.find_by_token('glagent-xxx').agent.project_id
=> 12345
```

Vous pouvez également révoquer un jeton directement dans la console Rails :

```ruby
# Revoke token with RevokeService, including generating an audit event
Clusters::AgentTokens::RevokeService.new(token: Clusters::AgentToken.find_by_token('glagent-xxx'), current_user: User.find_by_username('admin-user')).execute

# Revoke token manually, which does not generate an audit event
Clusters::AgentToken.find_by_token('glagent-xxx').revoke!
```

## Autres jetons {#other-tokens}

### Jeton de flux {#feed-token}

Chaque utilisateur dispose d'un jeton de flux longue durée qui n'expire pas. Utilisez ce jeton pour vous authentifier avec :

- Les lecteurs RSS, pour charger un flux RSS personnalisé
- Les applications de calendrier, pour charger un calendrier personnalisé

Vous ne pouvez pas utiliser ce jeton pour accéder à d'autres données.

Vous pouvez utiliser le jeton de flux à portée utilisateur pour tous les flux. Cependant, les URL de flux et de calendrier sont générées avec un jeton différent valable pour un seul flux.

Toute personne disposant de votre jeton peut consulter l'activité de votre flux, y compris les tickets confidentiels, comme si elle était vous. Si vous pensez que votre jeton a été compromis, [réinitialisez le jeton](../../user/profile/contributions_calendar.md#reset-the-user-activity-feed-token) immédiatement.

#### Désactiver un jeton de flux {#disable-a-feed-token}

Prérequis :

- Être administrateur.

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Généralités**.
1. Développez **Contrôles de visibilité et d'accès**.
1. Sous **Jeton de flux**, cochez la case **Désactiver le jeton de flux**, puis sélectionnez **Sauvegarder les modifications**.

### Jeton d'e-mail entrant {#incoming-email-token}

Chaque utilisateur dispose d'un jeton d'e-mail entrant qui n'expire pas. Le jeton est inclus dans les adresses e-mail associées à un projet personnel. Vous utilisez ce jeton pour [créer un nouveau ticket par e-mail](../../user/project/issues/create_issues.md#by-sending-an-email).

Vous ne pouvez pas utiliser ce jeton pour accéder à d'autres données. Toute personne disposant de votre jeton peut créer des tickets et des merge requests comme si elle était vous. Si vous pensez que votre jeton a été compromis, réinitialisez-le immédiatement.

### Jeton de workspace {#workspace-token}

{{< history >}}

- [Introduction](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/194097) dans GitLab 18.2.

{{< /history >}}

Chaque [workspace](../../user/workspace/_index.md) dispose d'un jeton interne géré automatiquement qui n'expire pas. Il permet la communication HTTP et SSH avec un workspace. Il existe dès lors qu'un workspace est demandé à passer à l'état **en cours**, et est automatiquement injecté et utilisé par le workspace.

Le démarrage d'un workspace arrêté crée un nouveau jeton de workspace. Le redémarrage d'un workspace en cours d'exécution supprime le jeton existant et en crée un nouveau.

Vous ne pouvez pas afficher ni gérer directement ce jeton interne. Vous ne pouvez pas utiliser ce jeton pour accéder à d'autres données.

Pour révoquer un jeton de workspace, [**stop** ou **terminate** le workspace](../../user/workspace/_index.md#manage-workspaces-from-a-project). Le jeton est supprimé immédiatement.

## Portées disponibles {#available-scopes}

Ce tableau présente les portées par défaut par jeton. Pour certains jetons, vous pouvez limiter davantage les portées lors de la création du jeton.

| Nom du jeton                  | Accès API              | Accès au registre         | Accès au dépôt |
|-----------------------------|-------------------------|-------------------------|-------------------|
| Jeton d'accès personnel       | {{< yes >}}             | {{< yes >}}             | {{< yes >}}       |
| Jeton OAuth 2.0             | {{< yes >}}             | {{< no >}}              | {{< yes >}}       |
| Jeton d'usurpation d'identité         | {{< yes >}}             | {{< yes >}}             | {{< yes >}}       |
| Jeton d'accès au projet        | {{< yes >}}<sup>1</sup> | {{< yes >}}<sup>1</sup> | {{< yes >}}<sup>1</sup> |
| Jeton d'accès de groupe          | {{< yes >}}<sup>2</sup> | {{< yes >}}<sup>2</sup> | {{< yes >}}<sup>2</sup> |
| Jeton de déploiement                | {{< no >}}              | {{< yes >}}             | {{< yes >}}       |
| Clé de déploiement                  | {{< no >}}              | {{< no >}}              | {{< yes >}}       |
| Jeton d'enregistrement de runner   | {{< no >}}              | {{< no >}}              | Limité<sup>3</sup> |
| Jeton d'authentification de runner | {{< no >}}              | {{< no >}}              | Limité<sup>3</sup> |
| Jeton de job                   | Limité<sup>4</sup>     | {{< no >}}              | {{< yes >}}       |

**Notes de bas de page** :

1. Limité à un seul projet
1. Limité à un seul groupe
1. Les jetons d'enregistrement et d'authentification de runners ne fournissent pas d'accès direct aux dépôts, mais peuvent être utilisés pour enregistrer et authentifier de nouveaux runners capables d'exécuter des jobs qui ont accès aux dépôts.
1. Uniquement [certains points de terminaison](../../ci/jobs/ci_job_token.md)

## Préfixes des jetons {#token-prefixes}

Le tableau suivant présente les préfixes pour chaque type de jeton. À l'exception des jetons d'accès personnels, ces préfixes ne peuvent pas être configurés, car ils sont conçus pour être des identifications standardisées.

|            Nom du jeton             |      Préfixe        |
|-----------------------------------|--------------------|
| Jeton d'accès personnel             | `glpat-`           |
| Secret d'application OAuth          | `gloas-`           |
| Jeton d'usurpation d'identité               | `glpat-`           |
| Jeton d'accès au projet              | `glpat-`           |
| Jeton d'accès de groupe                | `glpat-`           |
| Jeton de déploiement                      | `gldt-`            |
| Jeton d'authentification de runner       | `glrt-` ou `glrtr-` si créé via un jeton d'enregistrement |
| Jeton de job CI/CD                   | `glcbt-`           |
| Jeton de déclenchement                     | `glptt-`           |
| Jeton de flux                        | `glft-`            |
| Jeton d'e-mail entrant               | `glimt-`           |
| Jeton de l'agent GitLab pour Kubernetes | `glagent-`         |
| Jeton de workspace                   | `glwt-` (Ajouté dans GitLab 18.2) |
| Cookies de session GitLab            | `_gitlab_session=` |
| Jetons SCIM                       | `glsoat-`          |
| Jeton client des feature flags        | `glffct-`          |
