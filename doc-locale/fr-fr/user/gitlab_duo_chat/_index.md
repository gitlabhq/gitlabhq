---
stage: AI Clients
group: Duo Chat
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "Utilisez GitLab Duo Chat pour poser des questions sur votre code, obtenir de l'aide avec GitLab et effectuer des tâches dans l'interface utilisateur GitLab ou votre IDE."
title: GitLab Duo Non-Agentic Chat
---

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Module complémentaire : GitLab Duo Pro ou GitLab Duo Enterprise, GitLab Duo avec Amazon Q
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< collapsible title="Informations sur le modèle" >}}

- [LLM par défaut](../gitlab_duo/model_selection.md#default-models)
- LLM pour Amazon Q : Amazon Q Developer
- Disponible sur [GitLab Duo avec des modèles auto-hébergés](../../administration/gitlab_duo_self_hosted/_index.md)

{{< /collapsible >}}

{{< history >}}

- Obligation de disposer du module d'extension GitLab Duo à partir de GitLab 17.6.
- [Ajout](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/201721) à GitLab Duo Core dans GitLab 18.3.
- [Mise à jour du LLM par défaut](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/-/issues/1541) vers Claude Sonnet 4.5 dans GitLab 18.6.
- L'accès à GitLab Duo Non-Agentic Chat a été supprimé pour les clients GitLab Duo Core le 21 mai 2026 dans le cadre de la version GitLab 19.0, avec un feature flag nommé `no_duo_classic_for_duo_core_users`. Activé par défaut.

{{< /history >}}

> [!flag]
> La suppression de l'accès pour les clients GitLab Duo Core est contrôlée par un feature flag. Pour plus d'informations, consultez l'historique.

GitLab Duo Chat est un assistant IA qui accélère le développement grâce à une IA contextuelle et conversationnelle. Ce Chat non-agentique :

- Explique le code et suggère des améliorations directement dans votre environnement de développement.
- Analyse le code, les merge requests, les tickets et d'autres artefacts GitLab.
- Génère du code, des tests et de la documentation en fonction de vos exigences et de votre base de code.
- S'intègre directement dans l'interface utilisateur GitLab, Web IDE, VS Code, les IDE JetBrains et Visual Studio.
- Peut inclure des informations provenant de vos dépôts et projets pour fournir des améliorations ciblées.

<i class="fa-youtube-play" aria-hidden="true"></i> [Visionner une présentation](https://www.youtube.com/watch?v=ZQBAuf-CTAY)
<!-- Video published on 2024-04-18 -->

En savoir plus sur [GitLab Duo Agentic Chat](agentic_chat.md).

## Accès pour les utilisateurs GitLab Duo Core {#access-for-gitlab-duo-core-users}

Depuis le 21 mai 2026, les utilisateurs de GitLab Duo Core sur toutes les versions de GitLab n'ont pas accès à GitLab Duo Non-Agentic Chat.

À la place, vous pouvez :

- Utiliser [GitLab Duo Agentic Chat](agentic_chat.md) dans le cadre de la plateforme GitLab Duo Agent.

  Si vous utilisiez le Chat non-agentique avec Web IDE ou Eclipse, vous devez utiliser un IDE différent.
- Acheter GitLab Duo Pro ou Enterprise.

## Extensions d'éditeur prises en charge {#supported-editor-extensions}

Vous pouvez utiliser GitLab Duo Chat dans :

- L'interface utilisateur GitLab
- [Le Web IDE GitLab (VS Code dans le cloud)](../project/web_ide/_index.md)

Vous pouvez également utiliser GitLab Duo Chat dans ces IDE en installant une extension d'éditeur :

- [VS Code](../../editor_extensions/visual_studio_code/setup.md)
- [JetBrains](../../editor_extensions/jetbrains_ide/setup.md)
- [Eclipse](../../editor_extensions/eclipse/setup.md)
- [Visual Studio](../../editor_extensions/visual_studio/setup.md)

> [!note]
> Si vous utilisez GitLab Self-Managed : utilisez GitLab 17.2 et versions ultérieures pour une expérience et des résultats optimaux. Les versions antérieures peuvent continuer à fonctionner, mais l'expérience peut être dégradée.

## Utiliser GitLab Duo Chat dans l'interface GitLab {#use-gitlab-duo-chat-in-the-gitlab-ui}

{{< history >}}

- [Modifié](https://gitlab.com/gitlab-org/gitlab/-/issues/562168) pour être disponible sur toutes les pages de l'interface utilisateur GitLab pour GitLab.com dans GitLab 18.5.
- Introduction de la nouvelle navigation et de la barre latérale GitLab Duo sur GitLab.com dans GitLab 18.6 avec le [feature flag](../../administration/feature_flags/_index.md) `paneled_view`. Activé par défaut.
- Suppression des instructions de navigation précédentes dans GitLab 18.7.
- [Passage en disponibilité générale](https://gitlab.com/gitlab-org/gitlab/-/work_items/574049) de la nouvelle navigation et de la barre latérale GitLab Duo dans GitLab 18.8. Suppression du feature flag `paneled_view`.

{{< /history >}}

Prérequis :

- Vous devez avoir accès à GitLab Duo Chat et GitLab Duo doit être activé.
- Sur GitLab Self-Managed, vous devez vous trouver là où Chat est disponible. Il n'est pas disponible sur :
  - Les pages **Votre travail**, comme la liste de tâches.
  - Votre page **Paramètres utilisateur**.
  - Le menu **Aide**.

Pour utiliser le Chat dans l'interface GitLab :

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à**, puis recherchez votre projet.
1. Dans la barre latérale GitLab Duo, sélectionnez **Nouveau GitLab Duo Chat** ({{< icon name="pencil-square" >}}) ou **GitLab Duo Chat actuel** ({{< icon name="duo-chat" >}}). Une conversation Chat s'ouvre dans la barre latérale GitLab Duo située à droite de l'écran.
1. Sous la zone de texte Chat, désactivez le bouton bascule **Agentique**.
1. Saisissez votre question dans la zone de message et appuyez sur <kbd>Entrée</kbd> ou sélectionnez **Envoyer**.
   - Vous pouvez fournir du [contexte](../gitlab_duo/context.md) supplémentaire pour votre conversation Chat.
   - Le chat interactif alimenté par l'IA peut mettre quelques secondes à générer une réponse.
1. Facultatif. Vous pouvez :
   - Poser une question de suivi.
   - Démarrer [une autre conversation](#have-multiple-conversations).

Pour poser une nouvelle question sans rapport, saisissez `/reset` et sélectionnez **Envoyer** pour effacer le contexte.

### Afficher l'historique du Chat {#view-the-chat-history}

Les 25 messages les plus récents sont conservés dans l'historique du chat.

Dans la barre latérale GitLab Duo, sélectionnez **Historique GitLab Duo Chat** ({{< icon name="history" >}}).

### Avoir plusieurs conversations {#have-multiple-conversations}

{{< history >}}

- [Introduction](https://gitlab.com/groups/gitlab-org/-/epics/16108) dans GitLab 17.10 [avec le feature flag](../../administration/feature_flags/_index.md) `duo_chat_multi_thread`. Fonctionnalité désactivée par défaut.
- [Activé sur GitLab Self-Managed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/187443) dans GitLab 17.11.
- [Passage en disponibilité générale](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/190042) dans GitLab 18.1. Suppression du feature flag `duo_chat_multi_thread`.
- [Introduction](https://gitlab.com/gitlab-org/gitlab/-/work_items/582513) de la fonctionnalité de recherche dans l'historique de discussion de l'interface GitLab dans GitLab 18.9.

{{< /history >}}

Dans GitLab 17.10 et versions ultérieures, vous pouvez avoir un nombre illimité de conversations simultanées avec Chat.

1. Créez une nouvelle conversation Chat en effectuant l'une des opérations suivantes :

   - Dans la barre latérale GitLab Duo, sélectionnez **Nouveau GitLab Duo Chat** ({{< icon name="pencil-square" >}}).
   - Dans la zone de message, saisissez `/new` et appuyez sur <kbd>Entrée</kbd> ou sélectionnez **Envoyer**.

   Une nouvelle conversation Chat remplace la précédente.
1. Sous la zone de texte Chat, désactivez le bouton bascule **Agentique**.
1. Pour afficher toutes vos conversations, consultez l'[historique du Chat](#view-the-chat-history).
1. Pour passer d'une conversation à l'autre, sélectionnez la conversation appropriée dans votre historique de Chat.
1. Dans l'interface utilisateur GitLab, pour rechercher une conversation spécifique dans l'historique du chat, saisissez votre terme de recherche dans la zone de texte **Rechercher un fil de discussion**.

Chaque conversation conserve un nombre illimité de messages. Cependant, seuls les 25 derniers messages sont envoyés au LLM pour faire tenir le contenu dans la fenêtre de contexte du LLM.

Les conversations créées avant l'activation de cette fonctionnalité ne sont pas visibles dans l'historique du Chat.

### Supprimer une conversation {#delete-a-conversation}

Pour supprimer une conversation :

1. Sélectionnez l'[historique du Chat](#view-the-chat-history).
1. Dans l'historique, sélectionnez **Supprimer cette discussion** ({{< icon name="remove" >}}).

Par défaut, les conversations individuelles expirent et sont automatiquement supprimées après 30 jours d'inactivité.

Cependant, les administrateurs peuvent [modifier cette période d'expiration](#configure-chat-conversation-expiration).

## Utiliser GitLab Duo Chat dans le Web IDE {#use-gitlab-duo-chat-in-the-web-ide}

Pour utiliser GitLab Duo Chat dans le Web IDE sur GitLab :

1. Ouvrez le Web IDE :
   1. Dans l'interface utilisateur GitLab, dans la barre supérieure, sélectionnez **Rechercher ou accéder à** et trouvez votre projet.
   1. Sélectionnez un fichier. Puis, dans le coin supérieur droit, sélectionnez **Modifier** > **Ouvrir dans Web EDI**.
1. Ouvrez Chat en utilisant l'une des méthodes suivantes :
   - Dans la barre latérale gauche, sélectionnez **GitLab Duo Chat**.
   - Dans le fichier ouvert dans l'éditeur, sélectionnez du code.
     1. Faites un clic droit et sélectionnez **GitLab Duo Chat**.
     1. Sélectionnez **Explain selected snippet**, **Fix**, **Generate tests**, **Open Quick Chat** ou **Refactor**.
   - Utilisez le raccourci clavier :
     - Sur Windows ou Linux : <kbd>ALT</kbd>+<kbd>d</kbd>
     - Sur macOS : <kbd>Option</kbd>+<kbd>d</kbd>
1. Dans la zone de message, saisissez votre question et appuyez sur <kbd>Entrée</kbd> ou sélectionnez **Envoyer**.

Si vous avez sélectionné du code dans l'éditeur, cette sélection est incluse dans votre question à GitLab Duo Chat. Par exemple, vous pouvez sélectionner du code et demander à Chat `Can you simplify this?`.

### Vérifier les diagnostics de configuration {#check-configuration-diagnostics}

Pour vérifier les diagnostics de configuration GitLab Duo et les paramètres système, notamment la gestion des versions système, la gestion des états de fonctionnalités et les feature flags :

- Dans le volet Chat, dans le coin supérieur droit, sélectionnez **Statut**.

## Utiliser GitLab Duo Chat dans VS Code {#use-gitlab-duo-chat-in-vs-code}

{{< history >}}

- Statut [ajouté](https://gitlab.com/gitlab-org/gitlab-vscode-extension/-/issues/1712) dans l'extension GitLab pour VS Code 5.29.0.

{{< /history >}}

Prérequis :

- Vous avez [installé et configuré l'extension VS Code](../../editor_extensions/visual_studio_code/setup.md).

Pour utiliser GitLab Duo Chat dans l'extension GitLab pour VS Code :

1. Dans VS Code, ouvrez un fichier. Le fichier n'a pas besoin d'être un fichier dans un dépôt Git.
1. Dans la barre latérale gauche, sélectionnez **GitLab Duo Chat** ({{< icon name="duo-chat" >}}).
1. Dans la zone de message, saisissez votre question et appuyez sur <kbd>Entrée</kbd> ou sélectionnez **Envoyer**.

Si vous avez sélectionné du code dans l'éditeur, cette sélection est incluse dans votre question à GitLab Duo Chat. Par exemple, vous pouvez sélectionner du code et demander à Chat `Can you simplify this?`.

### Utiliser Chat pendant que vous travaillez dans la fenêtre de l'éditeur {#use-chat-while-working-in-the-editor-window}

{{< history >}}

- Introduit en tant que [disponibilité générale](https://gitlab.com/groups/gitlab-org/-/work_items/15218) dans l'extension GitLab pour VS Code 5.15.0.
- Insert Snippet [ajouté](https://gitlab.com/gitlab-org/gitlab-vscode-extension/-/merge_requests/2150) dans l'extension GitLab pour VS Code 5.25.0.

{{< /history >}}

Pour ouvrir GitLab Duo Chat dans la fenêtre de l'éditeur, utilisez l'une de ces méthodes :

- À partir d'un raccourci clavier :
  - Sur Windows et Linux : <kbd>ALT</kbd>+<kbd>c</kbd>
  - Sur macOS : <kbd>Option</kbd>+<kbd>c</kbd>
- Dans le fichier actuellement ouvert dans votre IDE, faites un clic droit et sélectionnez **GitLab Duo Chat** > **Open Quick Chat**. Sélectionnez du code pour fournir un contexte supplémentaire.
- Ouvrez la palette de commandes, puis sélectionnez **GitLab Duo Chat : Open Quick Chat**.

Une fois Quick Chat ouvert :

1. Dans la zone de message, saisissez votre question. Vous pouvez également :
   - Saisissez `/` pour afficher toutes les commandes disponibles.
   - Saisissez `/re` pour afficher `/refactor` et `/reset`.
1. Pour envoyer votre question, sélectionnez **Envoyer** ou appuyez sur <kbd>Command</kbd>+<kbd>Entrée</kbd>.
1. Pour interagir avec les réponses, utilisez les liens **Copy Snippet** et **Insert Snippet** au-dessus des blocs de code.
1. Pour quitter le chat, sélectionnez l'icône de chat dans la marge, ou appuyez sur **Échappement** tout en étant concentré sur le chat.

### Vérifier le statut du Chat {#check-the-status-of-chat}

Pour vérifier l'état de santé de votre configuration GitLab Duo :

- Dans le volet de chat, dans le coin supérieur droit, sélectionnez **Statut**.

### Fermer Chat {#close-chat}

Pour fermer GitLab Duo Chat :

- Pour GitLab Duo Chat dans la barre latérale gauche, sélectionnez **GitLab Duo Chat** ({{< icon name="duo-chat" >}}).
- Pour la fenêtre de chat rapide intégrée dans votre fichier, dans le coin supérieur droit, sélectionnez **Réduire** ({{< icon name="chevron-lg-up" >}}).

## Utiliser GitLab Duo Chat dans Visual Studio pour Windows {#use-gitlab-duo-chat-in-visual-studio-for-windows}

Prérequis :

- Vous avez installé et configuré l'[extension GitLab pour Visual Studio](../../editor_extensions/visual_studio/setup.md).

Pour utiliser GitLab Duo Chat dans l'extension GitLab pour Visual Studio :

1. Dans Visual Studio, ouvrez un fichier. Le fichier n'a pas besoin d'être un fichier dans un dépôt Git.
1. Ouvrez Chat en utilisant l'une des méthodes suivantes :
   - Dans la barre de menu supérieure, sélectionnez **Extensions**, puis sélectionnez **Open Duo Chat**.
   - Dans le fichier ouvert dans l'éditeur, sélectionnez du code.
     1. Faites un clic droit et sélectionnez **GitLab Duo Chat**.
     1. Sélectionnez **Explain selected code** ou **Generate Tests**.
1. Dans la zone de message, saisissez votre question et appuyez sur <kbd>Entrée</kbd> ou sélectionnez **Envoyer**.

Si vous avez sélectionné du code dans l'éditeur, cette sélection est envoyée avec votre question à l'IA. Vous pouvez ainsi poser des questions sur cette sélection de code. Par exemple, `Could you refactor this?`.

## Utiliser GitLab Duo Chat dans les IDE JetBrains {#use-gitlab-duo-chat-in-jetbrains-ides}

Prérequis :

- Vous avez [installé et configuré le plugin GitLab Duo pour les IDE JetBrains](../../editor_extensions/jetbrains_ide/setup.md).

Pour utiliser GitLab Duo Chat dans le plugin GitLab Duo pour les IDE JetBrains :

1. Dans un IDE JetBrains, ouvrez un projet.
1. Ouvrez GitLab Duo Chat dans une fenêtre de chat ou une fenêtre d'éditeur.

### Dans une fenêtre de chat {#in-a-chat-window}

Pour ouvrir GitLab Duo Chat dans une fenêtre de chat, utilisez l'une de ces méthodes :

- Dans la barre de fenêtre d'outils de droite, sélectionnez **GitLab Duo Non-Agentic Chat**.
- À partir d'un raccourci clavier :
  - Sur Windows et Linux : <kbd>ALT</kbd>+<kbd>d</kbd>
  - Sur macOS : <kbd>Option</kbd>+<kbd>d</kbd>
- Depuis un fichier d'éditeur ouvert :
  1. Faites un clic droit et sélectionnez **GitLab Duo Chat**.
  1. Sélectionnez **Open Chat Window**.
- Avec du code sélectionné :
  1. Dans un éditeur, sélectionnez le code à inclure avec votre commande.
  1. Faites un clic droit et sélectionnez **GitLab Duo Chat**.
  1. Sélectionnez **Explain Code**, **Fix Code**, **Generate Tests** ou **Refactor Code**.
- Depuis un problème de code mis en évidence :
  1. Faites un clic droit et sélectionnez **Show Context Actions**.
  1. Sélectionnez **Fix with Duo**.
- Avec un raccourci clavier ou souris pour une action GitLab Duo, que vous pouvez définir dans **Paramètres** > **Keymap**.

Une fois GitLab Duo Chat ouvert :

1. Dans la zone de message, saisissez votre question. Vous pouvez également :
   - Saisissez `/` pour afficher toutes les commandes disponibles.
   - Saisissez `/re` pour afficher `/refactor` et `/reset`.
1. Pour envoyer votre question, appuyez sur <kbd>Entrée</kbd> ou sélectionnez **Envoyer**.
1. Utilisez les boutons dans les blocs de code des réponses pour interagir avec eux.

### Dans une fenêtre d'éditeur {#in-an-editor-window}

{{< history >}}

- Introduit en disponibilité générale dans le [plugin GitLab Duo pour JetBrains 3.0.0](https://gitlab.com/groups/gitlab-org/editor-extensions/-/epics/80) et l'[extension GitLab pour VS Code 5.14.0](https://gitlab.com/groups/gitlab-org/-/work_items/15218).

{{< /history >}}

Pour ouvrir GitLab Duo Chat dans la fenêtre de l'éditeur, utilisez l'une de ces méthodes :

- À partir d'un raccourci clavier :
  - Sur Windows et Linux : <kbd>ALT</kbd>+<kbd>c</kbd>
  - Sur macOS : <kbd>Option</kbd>+<kbd>c</kbd>
- Dans un fichier ouvert dans votre IDE, sélectionnez du code, puis, dans la barre d'outils flottante, sélectionnez **GitLab Duo Quick Chat** ({{< icon name="tanuki-ai" >}}).
- Faites un clic droit et sélectionnez **GitLab Duo Chat** > **Open Quick Chat**.

Une fois Quick Chat ouvert :

1. Dans la zone de message, saisissez votre question. Vous pouvez également :
   - Saisissez `/` pour afficher toutes les commandes disponibles.
   - Saisissez `/re` pour afficher `/refactor` et `/reset`.
1. Pour envoyer votre question, appuyez sur <kbd>Entrée</kbd>.
1. Pour interagir avec les réponses, utilisez les boutons autour des blocs de code.
1. Pour quitter le chat, sélectionnez **Escape to close** ou appuyez sur <kbd>Échappement</kbd> tout en étant concentré sur le chat.

<div class="video-fallback">
  <a href="https://youtu.be/5JbAM5g2VbQ">Voir comment utiliser GitLab Duo Quick Chat</a>.
</div>
<figure class="video-container">
  <iframe src="https://www.youtube.com/embed/5JbAM5g2VbQ?si=pm7bTRDCR5we_1IX" frameborder="0" allowfullscreen> </iframe>
</figure>
<!-- Video published on 2024-10-15 -->

## Utiliser GitLab Duo Chat dans Eclipse {#use-gitlab-duo-chat-in-eclipse}

{{< history >}}

- [Passé](https://gitlab.com/gitlab-org/editor-extensions/gitlab-eclipse-plugin/-/issues/163) de version expérimentale à version bêta dans GitLab 17.11.

{{< /history >}}

Prérequis :

- Vous avez [installé et configuré le plugin GitLab pour Eclipse](../../editor_extensions/eclipse/setup.md).

Pour utiliser GitLab Duo Chat dans le plugin GitLab pour Eclipse :

1. Ouvrez un projet dans Eclipse.
1. Dans le coin supérieur droit, sélectionnez **GitLab Duo Chat** ({{< icon name="duo-chat" >}}), ou utilisez le raccourci clavier :
   - Pour Windows et Linux : <kbd>Alt</kbd>+<kbd>D</kbd>
   - Pour macOS : <kbd>Option</kbd>+<kbd>D</kbd>
1. Dans la zone de message, saisissez votre question et appuyez sur <kbd>Entrée</kbd> ou sélectionnez **Envoyer**.

## Configurer l'expiration des conversations Chat {#configure-chat-conversation-expiration}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/161997) dans GitLab 17.11.

{{< /history >}}

Vous pouvez configurer la durée de conservation des conversations avant qu'elles n'expirent et ne soient automatiquement supprimées.

Prérequis :

- Vous devez être administrateur.

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **GitLab Duo**.
1. Sélectionnez **Modifier la configuration**.
1. Sous **Conversations GitLab Duo Chat**, sélectionnez l'une des options suivantes :
   - **Après la dernière mise à jour de la conversation**.
   - **Après la création de la conversation**.
1. Sélectionnez **Enregistrer les modifications**.

## Raccourcis IDE {#ide-shortcuts}

Lorsque vous utilisez Chat dans un IDE pris en charge, vous pouvez utiliser des [raccourcis clavier](../shortcuts.md#gitlab-duo-chat).

## Modèles de langage disponibles {#available-language-models}

Différents modèles de langage peuvent être la source de GitLab Duo Chat.

- Sur GitLab.com ou GitLab Self-Managed, les modèles gérés par GitLab par défaut et la passerelle d'IA basée sur le cloud hébergée par GitLab.
- Sur GitLab Self-Managed, dans GitLab 17.9 et versions ultérieures, [GitLab Duo Self-Hosted avec un modèle auto-hébergé pris en charge](../../administration/gitlab_duo_self_hosted/_index.md). Les modèles auto-hébergés maximisent la sécurité et la confidentialité en veillant à ce que rien ne soit envoyé à un modèle externe. Vous pouvez utiliser des modèles gérés par GitLab, d'autres modèles de langage pris en charge, ou apporter votre propre modèle compatible.

## Longueur des entrées et des sorties {#input-and-output-length}

Pour chaque conversation Chat, la longueur des entrées et des sorties est limitée :

- L'entrée est limitée à 200 000 tokens (environ 680 000 caractères). Les tokens d'entrée comprennent :
  - Tout le [contexte dont Chat a connaissance](../gitlab_duo/context.md).
  - Toutes les questions et réponses précédentes dans cette conversation.
- La sortie est limitée à 8 192 tokens (environ 28 600 caractères).

## Donner un avis {#give-feedback}

Vos retours sont importants car GitLab améliore continuellement l'expérience GitLab Duo Chat. Les retours permettent de personnaliser Chat selon vos besoins et d'améliorer ses performances pour tous.

Pour donner votre avis sur une réponse spécifique, utilisez les boutons de retour dans le message de réponse. Vous pouvez également ajouter un commentaire dans le [ticket de retour](https://gitlab.com/gitlab-org/gitlab/-/issues/430124).
