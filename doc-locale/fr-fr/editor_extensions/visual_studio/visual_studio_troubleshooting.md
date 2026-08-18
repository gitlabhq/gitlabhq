---
stage: AI-powered
group: Editor Extensions
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "Découvrez comment résoudre les problèmes courants liés à l'extension GitLab pour Visual Studio."
title: "Dépannage de l'extension GitLab pour Visual Studio"
---

Si les étapes décrites sur cette page ne résolvent pas votre problème, consultez la [liste des tickets ouverts](https://gitlab.com/gitlab-org/editor-extensions/gitlab-visual-studio-extension/-/issues/?sort=created_date&state=opened&first_page_size=100) dans le projet de l'extension. Si un ticket correspond à votre problème, mettez-le à jour. Si aucun ticket ne correspond à votre problème, [créez un nouveau ticket](https://gitlab.com/gitlab-org/editor-extensions/gitlab-visual-studio-extension/-/issues/new).

## Les fonctionnalités GitLab Duo n'apparaissent pas {#gitlab-duo-features-do-not-appear}

Si GitLab Duo Chat ou GitLab Duo Code Suggestions ne sont pas disponibles dans Visual Studio :

- Assurez-vous de remplir les [prérequis](setup.md#configure-gitlab-duo) et que les paramètres nécessaires sont activés.
- Assurez-vous que [le mode Admin est désactivé](../../administration/settings/sign_in_restrictions.md#turn-off-admin-mode-for-your-session).
- Vérifiez que GitLab Duo Agentic Chat est activé :
  1. Dans Visual Studio, accédez à **Outils** > **Options** > **GitLab**.
  1. Sous **GitLab**, sélectionnez **Général**.
  1. Vérifiez que **Enable Agentic Duo Chat** est défini sur **Vrai**.
- Vérifiez que Code Suggestions est activé :
  1. Dans Visual Studio, dans la barre de statut inférieure, vérifiez l'info-bulle de l'icône GitLab pour connaître le statut actuel de la fonctionnalité.
  1. Si Code Suggestions n'est pas activé, dans la barre supérieure, sélectionnez **Extensions** > **GitLab** > **Toggle Code Suggestions**.

Pour obtenir de l'aide concernant Code Suggestions, consultez [Dépannage de Code Suggestions](../../user/project/repository/code_suggestions/troubleshooting.md#microsoft-visual-studio-troubleshooting).

## Problèmes réseau {#network-issues}

Si vous voyez des réponses `HTTP/1.1` de GitLab Duo plutôt que des endpoints WebSocket `/-/cable` dans vos logs, vos connexions WebSocket sont peut-être bloquées.

Votre instance GitLab doit autoriser les connexions WebSocket entrantes depuis les clients IDE. Demandez à votre administrateur réseau d'[autoriser le trafic WebSocket vers votre instance GitLab](../../administration/gitlab_duo/configure/_index.md#allow-inbound-connections-from-clients-to-the-gitlab-instance) si vous soupçonnez que c'est le problème.

## Afficher plus de journaux {#view-more-logs}

Des journaux supplémentaires sont disponibles dans la fenêtre **GitLab Extension Output** :

1. Dans Visual Studio, dans la barre supérieure, accédez au menu **Outils** > **Options**.
1. Trouvez l'option **GitLab** et définissez **Log Level** sur **Déboguer**.
1. Accédez à **Afficher** > **Output** pour ouvrir le journal de l'extension. Dans la liste déroulante, sélectionnez **GitLab Extension** comme filtre de journal.
1. Vérifiez que le journal de débogage contient une sortie similaire :

   ```shell
   GetProposalManagerAsync: Code suggestions enabled. ContentType (csharp) or file extension (cs) is supported.
   GitlabProposalSourceProvider.GetProposalSourceAsync
   ```

### Afficher le journal d'activité {#view-activity-log}

Si votre extension ne se charge pas ou se bloque, consultez le journal d'activité pour détecter les erreurs. Votre journal d'activité est disponible à cet emplacement :

```plaintext
C:\Users\WINDOWS_USERNAME\AppData\Roaming\Microsoft\VisualStudio\VS_VERSION\ActivityLog.xml
```

Remplacez ces valeurs dans le chemin du répertoire :

- `WINDOWS_USERNAME` : Votre nom d'utilisateur Windows.
- `VS_VERSION` : La version de votre installation de Visual Studio.

## Informations requises pour le support {#required-information-for-support}

Avant de contacter le support, assurez-vous que la dernière version de l'extension GitLab est installée. Visual Studio devrait automatiquement se mettre à jour vers la dernière version de l'extension.

Collectez ces informations auprès des utilisateurs concernés et fournissez-les dans votre rapport de bug :

1. Le message d'erreur affiché à l'utilisateur ou l'utilisatrice.
1. Journaux du workflow et du serveur de langage :
   1. [Activez les journaux de débogage](#view-more-logs).
   1. [Récupérez les fichiers journaux](#view-activity-log).
1. Sortie de diagnostic :
   1. Avec Visual Studio ouvert, dans la bannière supérieure, sélectionnez **Aide** > **About Microsoft Visual Studio**.
   1. Dans la boîte de dialogue, sélectionnez **Copy Info** pour copier toutes les informations requises pour cette section dans votre presse-papiers.
1. Détails du système :
   1. Avec Visual Studio ouvert, dans la bannière supérieure, sélectionnez **Aide** > **About Microsoft Visual Studio**.
   1. Dans la boîte de dialogue, sélectionnez **System Info** pour afficher des informations plus détaillées.
   1. Pour le **OS type and version** : Copiez les valeurs `OS Name` et `Version`.
   1. Pour les **Machine specifications (CPU, RAM)** : copiez les sections `Processor` et `Installed Physical Memory (RAM)`.
1. Décrivez la portée de l'impact. Combien d'utilisateurs et d'utilisatrices sont affectés ?
1. Décrivez comment reproduire l'erreur. Incluez un enregistrement d'écran si possible.
1. Décrivez comment les autres fonctionnalités de GitLab Duo sont affectées :
   - Code Suggestions fonctionne-t-il ?
   - GitLab Duo Chat dans le Web IDE renvoie-t-il des réponses ?
1. Effectuez des tests d'isolation des extensions. Essayez de désactiver (ou de désinstaller) toutes les autres extensions pour déterminer si une autre extension est à l'origine du problème. Cela permet de déterminer si le problème provient de notre extension ou d'une source externe.
