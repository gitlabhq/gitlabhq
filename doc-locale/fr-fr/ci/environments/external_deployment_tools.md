---
stage: Verify
group: Runner Core
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: "Suivre les déploiements d'un outil de déploiement externe"
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Bien que GitLab propose une [solution de déploiement intégrée](_index.md), vous préférerez peut-être utiliser un outil de déploiement externe, tel que Heroku ou ArgoCD. GitLab peut recevoir des événements de déploiement de ces outils externes et vous permet de suivre les déploiements dans GitLab. Par exemple, les fonctionnalités suivantes sont disponibles en configurant le suivi :

- [Voir quand une merge request a été déployée, et vers quel environnement](../../user/project/merge_requests/widgets.md#post-merge-pipeline-status).
- [Filtrer les merge requests par environnement ou date de déploiement](../../user/project/merge_requests/_index.md#by-environment-or-deployment-date).
- [Métriques DevOps Research and Assessment (DORA)](../../user/analytics/dora_metrics.md).
- [Afficher les environnements et les déploiements](_index.md#view-environments-and-deployments).
- [Suivre les nouvelles merge requests incluses par déploiement](deployments.md#track-newly-included-merge-requests-per-deployment).

> [!note]
> Certaines fonctionnalités ne sont pas disponibles car GitLab ne peut pas autoriser et exploiter ces déploiements externes, notamment les [environnements protégés](protected_environments.md), les [approbations de déploiement](deployment_approvals.md), la [sécurité des déploiements](deployment_safety.md) et le [rollback de déploiement](deployments.md#deployment-rollback).

## Comment configurer le suivi des déploiements {#how-to-set-up-deployment-tracking}

Les outils de déploiement externes proposent généralement un [webhook](https://en.wikipedia.org/wiki/Webhook) pour exécuter une requête API supplémentaire lorsque l'état du déploiement change. Vous pouvez configurer votre outil pour effectuer une requête vers l'[API de déploiement](../../api/deployments.md) GitLab. Voici une vue d'ensemble du flux d'événements et de requêtes API :

- Lorsqu'un déploiement commence à s'exécuter, [créez un déploiement avec le statut `running`](../../api/deployments.md#create-a-deployment).
- Lorsqu'un déploiement réussit, [mettez à jour le statut du déploiement vers `success`](../../api/deployments.md#update-a-deployment).
- Lorsqu'un déploiement échoue, [mettez à jour le statut du déploiement vers `failed`](../../api/deployments.md#update-a-deployment).

> [!note]
> Vous pouvez créer un [jeton d'accès au projet](../../user/project/settings/project_access_tokens.md) pour l'authentification à l'API GitLab.

### Exemple : Suivre les déploiements d'ArgoCD {#example-track-deployments-of-argocd}

Vous pouvez utiliser le [webhook ArgoCD](https://argo-cd.readthedocs.io/en/stable/operator-manual/notifications/services/webhook/) pour envoyer des événements de déploiement à l'API de déploiement GitLab. Voici un exemple de configuration qui crée un enregistrement de déploiement `success` dans GitLab lorsqu'ArgoCD déploie avec succès une nouvelle révision :

1. Créez un nouveau webhook. Vous pouvez enregistrer le fichier manifeste suivant et l'appliquer via `kubectl apply -n argocd -f <manifiest-file-path>` :

   ```yaml
   apiVersion: v1
   kind: ConfigMap
   metadata:
     name: argocd-notifications-cm
   data:
     trigger.on-deployed: |
       - description: Application is synced and healthy. Triggered once per commit.
         oncePer: app.status.sync.revision
         send:
         - gitlab-deployment-status
         when: app.status.operationState.phase in ['Succeeded'] and app.status.health.status == 'Healthy'
     template.gitlab-deployment-status: |
       webhook:
         gitlab:
           method: POST
           path: /projects/<your-project-id>/deployments
           body: |
             {
               "status": "success",
               "environment": "production",
               "sha": "{{.app.status.operationState.operation.sync.revision}}",
               "ref": "main",
               "tag": "false"
             }
     service.webhook.gitlab: |
       url: https://gitlab.com/api/v4
       headers:
       - name: PRIVATE-TOKEN
         value: <your-access-token>
       - name: Content-type
         value: application/json
   ```

1. Créez un nouvel abonnement dans votre application :

   ```shell
   kubectl patch app <your-app-name> -n argocd -p '{"metadata": {"annotations": {"notifications.argoproj.io/subscribe.on-deployed.gitlab":""}}}' --type merge
   ```

> [!note]
> Si un déploiement n'a pas été créé comme prévu, vous pouvez résoudre le problème avec l'[outil `argocd-notifications`](https://argo-cd.readthedocs.io/en/stable/operator-manual/notifications/troubleshooting/). Par exemple, `argocd-notifications template notify gitlab-deployment-status <your-app-name> --recipient gitlab:argocd-notifications` déclenche immédiatement une requête API et affiche un message d'erreur provenant du serveur de l'API GitLab, le cas échéant.
