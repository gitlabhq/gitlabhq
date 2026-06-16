---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Commandes de la console de maintenance CI/CD
---

{{< details >}}

- Niveau : Free, Premium, Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

Les commandes suivantes sont exécutées dans la [console Rails](../operations/rails_console.md#starting-a-rails-console-session).

> [!warning]
> Toute commande qui modifie directement des données peut être dangereuse si elle n'est pas exécutée correctement ou dans les bonnes conditions. Nous recommandons vivement de les exécuter dans un environnement de test avec une sauvegarde de l'instance prête à être restaurée, au cas où.

## Annuler tous les pipelines en cours d'exécution et leurs jobs {#cancel-all-running-pipelines-and-their-jobs}

```ruby
admin = User.find(user_id) # replace user_id with the id of the admin you want to cancel the pipeline
# Iterate over each cancelable pipeline
Ci::Pipeline.cancelable.find_each do |pipeline|
  Ci::CancelPipelineService.new(
    pipeline: pipeline,
    current_user: user,
    cascade_to_children: false # the children are included in the outer loop
  )
end
```

## Annuler les pipelines en attente bloqués {#cancel-stuck-pending-pipelines}

```ruby
project = Project.find_by_full_path('<project_path>')
Ci::Pipeline.where(project_id: project.id).where(status: 'pending').count
Ci::Pipeline.where(project_id: project.id).where(status: 'pending').each {|p| p.cancel if p.stuck?}
Ci::Pipeline.where(project_id: project.id).where(status: 'pending').count
```

## Tester l'intégration de merge request {#try-merge-request-integration}

```ruby
project = Project.find_by_full_path('<project_path>')
mr = project.merge_requests.find_by(iid: <merge_request_iid>)
mr.project.try(:ci_integration)
```

## Valider le fichier `.gitlab-ci.yml` {#validate-the-gitlab-ciyml-file}

```ruby
project = Project.find_by_full_path('<project_path>')
content = project.ci_config_for(project.repository.root_ref_sha)
Gitlab::Ci::Lint.new(project: project, current_user: User.first).validate(content)
```

## Désactiver AutoDevOps sur les projets existants {#disable-autodevops-on-existing-projects}

```ruby
Project.all.each do |p|
  p.auto_devops_attributes={"enabled"=>"0"}
  p.save
end
```

## Exécuter manuellement des planifications de pipeline {#run-pipeline-schedules-manually}

Vous pouvez exécuter manuellement des planifications de pipeline via la console Rails afin de révéler les erreurs qui ne sont généralement pas visibles.

```ruby
# schedule_id can be obtained from Edit Pipeline Schedule page
schedule = Ci::PipelineSchedule.find_by(id: <schedule_id>)

# Select the user that you want to run the schedule for
user = User.find_by_username('<username>')

# Run the schedule
ps = Ci::CreatePipelineService.new(schedule.project, user, ref: schedule.ref).execute!(:schedule, ignore_skip_ci: true, save_on_errors: false, schedule: schedule)
```

<!--- start_remove The following content will be removed on remove_date: '2027-08-15' -->

## Obtenir le jeton d'enregistrement des runners (obsolète) {#obtain-runners-registration-token-deprecated}

> [!warning]
> L'option permettant de transmettre des jetons d'enregistrement de runner et la prise en charge de certains arguments de configuration sont considérées comme héritées et ne sont pas recommandées. Utilisez le [workflow de création de runner](https://docs.gitlab.com/runner/register/#register-with-a-runner-authentication-token) pour générer un jeton d'authentification permettant d'enregistrer des runners. Ce processus offre une traçabilité complète de la propriété des runners et améliore la sécurité de votre flotte de runners. Pour plus d'informations, consultez [Migrer vers le nouveau workflow d'enregistrement des runners](../../ci/runners/new_creation_workflow.md).

Prérequis :

- Les jetons d'enregistrement des runners doivent être [activés](../settings/continuous_integration.md#control-runner-registration) dans la zone **Admin**.

```ruby
Gitlab::CurrentSettings.current_application_settings.runners_registration_token
```

## Remplir le jeton d'enregistrement des runners (obsolète) {#seed-runners-registration-token-deprecated}

> [!warning]
> L'option permettant de transmettre des jetons d'enregistrement de runner et la prise en charge de certains arguments de configuration sont considérées comme héritées et ne sont pas recommandées. Utilisez le [workflow de création de runner](https://docs.gitlab.com/runner/register/#register-with-a-runner-authentication-token) pour générer un jeton d'authentification permettant d'enregistrer des runners. Ce processus offre une traçabilité complète de la propriété des runners et améliore la sécurité de votre flotte de runners. Pour plus d'informations, consultez [Migrer vers le nouveau workflow d'enregistrement des runners](../../ci/runners/new_creation_workflow.md).

```ruby
appSetting = Gitlab::CurrentSettings.current_application_settings
appSetting.set_runners_registration_token('<new-runners-registration-token>')
appSetting.save!
```

<!--- end_remove -->
