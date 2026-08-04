---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Jenkins
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Déplacé](https://gitlab.com/gitlab-org/gitlab/-/issues/246756) vers GitLab Gratuite dans la version 13.7.

{{< /history >}}

[Jenkins](https://www.jenkins.io/) est un serveur d'automatisation open source qui prend en charge la création, le déploiement et l'automatisation de projets.

Vous devez utiliser une intégration Jenkins avec GitLab dans les cas suivants :

- Vous prévoyez de migrer votre CI de Jenkins vers [GitLab CI/CD](../ci/_index.md) à l'avenir, mais avez besoin d'une solution intermédiaire.
- Vous avez investi dans les [plugins Jenkins](https://plugins.jenkins.io/) et choisissez de continuer à utiliser Jenkins pour créer vos applications.

Cette intégration peut déclencher un build Jenkins lorsqu'une modification est poussée vers GitLab.

Vous ne pouvez pas utiliser cette intégration pour déclencher des pipelines GitLab CI/CD depuis Jenkins. Utilisez plutôt le [point de terminaison de l'API des déclencheurs de pipeline](../api/pipeline_triggers.md) dans un job Jenkins, authentifié avec un [jeton de déclenchement de pipeline](../ci/triggers/_index.md#create-a-pipeline-trigger-token).

Une fois l'intégration Jenkins configurée, vous déclenchez un build dans Jenkins lorsque vous poussez du code vers votre dépôt ou créez une merge request dans GitLab. Le statut du pipeline Jenkins s'affiche sur les widgets de la merge request et sur la page d'accueil du projet GitLab.

<i class="fa-youtube-play" aria-hidden="true"></i> Pour une vue d'ensemble de l'intégration Jenkins pour GitLab, consultez [Workflow GitLab avec ticket Jira et pipelines Jenkins](https://youtu.be/Jn-_fyra7xQ).

Pour configurer une intégration Jenkins avec GitLab :

- Accorder à Jenkins l'accès au projet GitLab
- Configurer le serveur Jenkins
- Configurer le projet Jenkins
- Configurer le projet GitLab

## Accorder à Jenkins l'accès au projet GitLab {#grant-jenkins-access-to-the-gitlab-project}

1. Créez un jeton d'accès personnel, un jeton d'accès au projet ou un jeton d'accès de groupe.

   - [Créez un jeton d'accès personnel](../user/profile/personal_access_tokens.md#create-a-personal-access-token) pour utiliser le jeton pour toutes les intégrations Jenkins de cet utilisateur.
   - [Créez un jeton d'accès au projet](../user/project/settings/project_access_tokens.md#create-a-project-access-token) pour utiliser le jeton uniquement au niveau du projet. Par exemple, vous pouvez révoquer le jeton dans un projet sans affecter les intégrations Jenkins dans d'autres projets.
   - [Créez un jeton d'accès de groupe](../user/group/settings/group_access_tokens.md#create-a-group-access-token) pour utiliser le jeton pour toutes les intégrations Jenkins dans tous les projets de ce groupe.

1. Définissez la portée du jeton d'accès personnel sur **API**.
1. Copiez la valeur du jeton d'accès personnel pour configurer le serveur Jenkins.

## Configurer le serveur Jenkins {#configure-the-jenkins-server}

Installez et configurez le plugin Jenkins pour autoriser la connexion à GitLab.

1. Sur le serveur Jenkins, sélectionnez **Manage Jenkins** > **Manage Plugins**.
1. Sélectionnez l'onglet **Available**. Recherchez `gitlab-plugin` et sélectionnez-le pour l'installer. Consultez la [documentation Jenkins GitLab](https://plugins.jenkins.io/gitlab-plugin/) pour d'autres méthodes d'installation du plugin.
1. Sélectionnez **Manage Jenkins** > **Configure System**.
1. Dans la section **GitLab**, sélectionnez **Enable authentication for '/project' end-point**.
1. Sélectionnez **Add**, puis choisissez **Jenkins Credential Provider**.
1. Sélectionnez **GitLab API token** comme type de jeton.
1. Dans **API Token**, [collez la valeur du jeton d'accès que vous avez copiée depuis GitLab](#grant-jenkins-access-to-the-gitlab-project) et sélectionnez **Add**.
1. Saisissez l'URL du serveur GitLab dans **GitLab host URL**.
1. Pour tester la connexion, sélectionnez **Test Connection**.

Pour plus d'informations, consultez [Jenkins-to-GitLab authentication](https://github.com/jenkinsci/gitlab-plugin#jenkins-to-gitlab-authentication).

## Configurer le projet Jenkins {#configure-the-jenkins-project}

Configurez le projet Jenkins sur lequel vous souhaitez exécuter votre build.

1. Sur votre instance Jenkins, sélectionnez **New Item**.
1. Saisissez le nom du projet.
1. Sélectionnez **Freestyle** ou **Pipeline** et sélectionnez **OK**. Vous devez sélectionner un projet freestyle, car le plugin Jenkins met à jour le statut du build sur GitLab. Dans un projet pipeline, vous devez configurer un script pour mettre à jour le statut sur GitLab.
1. Choisissez votre connexion GitLab dans la liste déroulante.
1. Sélectionnez **Build when a change is pushed to GitLab**.
1. Cochez les cases suivantes :
   - **Accepted Merge Request Events**
   - **Closed Merge Request Events**
1. Spécifiez comment le statut du build est signalé à GitLab :
   - Si vous avez créé un projet freestyle, dans la section **Post-build Actions**, choisissez **Publish build status to GitLab**.
   - Si vous avez créé un projet pipeline, vous devez utiliser un script Jenkins Pipeline pour mettre à jour le statut sur GitLab.

     Exemple de script Jenkins Pipeline :

      ```groovy
      pipeline {
         agent any

         stages {
            stage('gitlab') {
               steps {
                  echo 'Notify GitLab'
                  updateGitlabCommitStatus name: 'build', state: 'pending'
                  updateGitlabCommitStatus name: 'build', state: 'success'
               }
            }
         }
      }
      ```

      Pour plus d'exemples de scripts Jenkins Pipeline, consultez le [dépôt du plugin Jenkins GitLab sur GitHub](https://github.com/jenkinsci/gitlab-plugin#scripted-pipeline-jobs).

## Configurer le projet GitLab {#configure-the-gitlab-project}

Configurez l'intégration GitLab avec Jenkins de l'une des façons suivantes.

### Avec une URL de serveur Jenkins {#with-a-jenkins-server-url}

Vous devez utiliser cette approche pour les intégrations Jenkins si vous pouvez fournir à GitLab l'URL de votre serveur Jenkins et les informations d'authentification.

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à** et trouvez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Intégrations**.
1. Sélectionnez **Jenkins**.
1. Cochez la case **Actif**.
1. Sélectionnez les événements pour lesquels vous souhaitez que GitLab déclenche un build Jenkins :
   - Push
   - Merge request
   - Push de tag
1. Saisissez l'**URL du serveur Jenkins**.
1. Facultatif. Décochez la case **Activer la vérification SSL** pour désactiver la [vérification SSL](../user/project/integrations/_index.md#ssl-verification).
1. Saisissez le **Nom du projet**. Le nom du projet doit être compatible avec les URL, où les espaces sont remplacés par des tirets bas. Pour vous assurer que le nom du projet est valide, copiez-le depuis la barre d'adresse de votre navigateur lors de la consultation du projet Jenkins.
1. Si votre serveur Jenkins requiert une authentification, saisissez le **Nom d'utilisateur** et le **Mot de passe**.
1. Facultatif. Sélectionnez **Tester les paramètres**.
1. Sélectionnez **Enregistrer les modifications**.

### Avec un webhook {#with-a-webhook}

Si vous ne pouvez pas [fournir à GitLab l'URL de votre serveur Jenkins et les informations d'authentification](#with-a-jenkins-server-url), vous pouvez configurer un webhook pour intégrer GitLab et Jenkins.

1. Dans la configuration de votre job Jenkins, dans la section de configuration GitLab, sélectionnez **Paramètres avancés**.
1. Sous **Jeton secret**, sélectionnez **Générer**.
1. Copiez le jeton et enregistrez la configuration du job.
1. Dans GitLab :
   - [Créez un webhook pour votre projet](../user/project/integrations/webhooks.md#configure-webhooks).
   - Saisissez l'URL de déclenchement (par exemple `https://JENKINS_URL/project/YOUR_JOB`).
   - Collez le jeton dans **Jeton secret**.
1. Pour tester le webhook, sélectionnez **Test**.

## Sujets connexes {#related-topics}

- [Intégration GitLab Jenkins](https://about.gitlab.com/solutions/jenkins/)
- [Comment migrer de Jenkins vers GitLab CI/CD](../ci/migration/jenkins.md)
- [Jenkins to GitLab : le guide ultime pour moderniser votre environnement CI/CD](https://about.gitlab.com/blog/jenkins-gitlab-ultimate-guide-to-modernizing-cicd-environment/)

## Dépannage {#troubleshooting}

### Erreur : `Connection failed. Please check your settings` {#error-connection-failed-please-check-your-settings}

Lors de la configuration de GitLab, vous pouvez obtenir une erreur indiquant `Connection failed. Please check your settings`.

Ce problème a plusieurs causes et solutions possibles :

| Cause                                                            | Solution de contournement  |
|------------------------------------------------------------------|-------------|
| GitLab ne peut pas atteindre votre instance Jenkins à l'adresse indiquée.  | Pour GitLab Self-Managed, effectuez un ping de l'instance Jenkins au domaine fourni sur l'instance GitLab. |
| L'instance Jenkins se trouve à une adresse locale et n'est pas incluse dans la [liste d'autorisation de l'installation GitLab](../security/webhooks.md#allow-outbound-requests-to-certain-ip-addresses-and-domains). | Ajoutez l'instance à la liste d'autorisation de l'installation GitLab. |
| Les identifiants de l'instance Jenkins ne disposent pas d'un accès suffisant ou sont invalides. | Accordez aux identifiants un accès suffisant ou créez des identifiants valides. |
| La case **Activer l'authentification pour le point de terminaison `/project`** n'est pas cochée dans votre [configuration du plugin Jenkins](#configure-the-jenkins-server) | Cochez la case. |

### Erreur : `Could not connect to the CI server` {#error-could-not-connect-to-the-ci-server}

Vous pouvez obtenir une erreur indiquant `Could not connect to the CI server` dans une merge request si GitLab n'a pas reçu de mise à jour du statut du build de la part de Jenkins via l'[API Commit Status](../api/commits.md#commit-status).

Ce problème survient lorsque Jenkins n'est pas correctement configuré ou qu'une erreur se produit lors du signalement du statut via l'API.

Pour résoudre ce problème :

1. [Configurez le serveur Jenkins](#configure-the-jenkins-server) pour l'accès à l'API GitLab.
1. [Configurez le projet Jenkins](#configure-the-jenkins-project) et assurez-vous que, si vous créez un projet freestyle, vous choisissez l'action post-build « Publish build status to GitLab ».

### L'événement de merge request ne déclenche pas un pipeline Jenkins {#merge-request-event-does-not-trigger-a-jenkins-pipeline}

Ce problème peut survenir lorsque la requête dépasse la [limite de délai d'attente du webhook](../user/gitlab_com/_index.md#webhooks), définie à 10 secondes par défaut.

Pour ce problème, vérifiez :

- Les journaux du webhook d'intégration pour les échecs de requêtes.
- `/var/log/gitlab/gitlab-rails/production.log` pour des messages tels que :

  ```plaintext
  WebHook Error => Net::ReadTimeout
  ```

  ou

  ```plaintext
  WebHook Error => execution expired
  ```

Sur GitLab Self-Managed, vous pouvez résoudre ce problème en [augmentant la valeur du délai d'attente du webhook](../administration/instance_limits.md#webhook-timeout).

### Activer les job logs dans Jenkins {#enable-job-logs-in-jenkins}

Pour résoudre un problème d'intégration, vous pouvez activer les job logs dans Jenkins afin d'obtenir plus de détails sur vos builds.

Pour activer les job logs dans Jenkins :

1. Accédez à **Dashboard** > **Manage Jenkins** > **System Log**.
1. Sélectionnez **Add new log recorder**.
1. Saisissez un nom pour l'enregistreur de journaux.
1. Sur l'écran suivant, sélectionnez **Add** et saisissez `com.dabsquared.gitlabjenkins`.
1. Assurez-vous que le niveau de journal est défini sur **All** et sélectionnez **Save**.

Pour consulter vos journaux :

1. Exécutez un build.
1. Accédez à **Dashboard** > **Manage Jenkins** > **System Log**.
1. Sélectionnez votre enregistreur et consultez les journaux.
