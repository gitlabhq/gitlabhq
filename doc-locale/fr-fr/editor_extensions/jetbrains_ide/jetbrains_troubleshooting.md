---
stage: AI-powered
group: Editor Extensions
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Connectez-vous à GitLab Duo et utilisez-le dans les IDE JetBrains.
title: Dépannage JetBrains
---

Si les étapes de cette page ne résolvent pas votre problème, consultez la [liste des tickets ouverts](https://gitlab.com/gitlab-org/editor-extensions/gitlab-jetbrains-plugin/-/issues/?sort=created_date&state=opened&first_page_size=100) dans le projet du plugin JetBrains. Si un ticket correspond à votre problème, mettez-le à jour. Si aucun ticket ne correspond à votre problème, [créez un nouveau ticket](https://gitlab.com/gitlab-org/editor-extensions/gitlab-jetbrains-plugin/-/issues/new) et fournissez les [informations requises pour le support](#required-information-for-support).

## Les fonctionnalités de GitLab Duo sont indisponibles {#gitlab-duo-features-are-unavailable}

Pour résoudre les erreurs GitLab Duo dans votre IDE :

1. Assurez-vous de remplir les [prérequis](setup.md#configure-gitlab-duo) et que les paramètres nécessaires sont activés.
1. Assurez-vous que [le mode Admin est désactivé](../../administration/settings/sign_in_restrictions.md#turn-off-admin-mode-for-your-session).
1. Examinez la sortie des diagnostics :
   - Dans votre IDE JetBrains, accédez à **Outils** > **GitLab** > **Diagnostics** et examinez la sortie pour identifier les vérifications échouées.
1. Si les diagnostics indiquent que la fonctionnalité n'est pas activée :
   1. Dans votre IDE JetBrains, accédez à **Paramètres** > **Outils** > **GitLab Duo**.
   1. Recherchez et cochez la case pour activer la fonctionnalité manquante.
   1. Sélectionnez **OK** ou **Enregistrer**.
   1. Redémarrez votre IDE si vous y êtes invité.
1. Si les diagnostics indiquent qu'Agentic Chat n'est pas pris en charge pour le projet actuel, [définissez un espace de nommage GitLab Duo par défaut](../../user/profile/preferences.md#namespace-resolution-in-your-local-environment).
1. Si vous utilisez JetBrains Remote Development et que les diagnostics indiquent qu'une fonctionnalité manquante est activée, vérifiez si le plugin GitLab Duo est installé à la fois sur la machine hôte et sur la machine cliente. Si c'est le cas, désinstallez le plugin de la machine cliente et conservez-le uniquement sur la machine hôte. Pour plus d'informations, consultez [l'utilisation avec le développement à distance](_index.md#use-with-remote-development).

Pour obtenir de l'aide concernant Code Suggestions, consultez [Dépannage de Code Suggestions](../../user/project/repository/code_suggestions/troubleshooting.md#jetbrains-ides-troubleshooting).

## Problèmes réseau {#network-issues}

Si vous voyez des réponses `HTTP/1.1` de GitLab Duo plutôt que des endpoints WebSocket `/-/cable` dans vos logs, vos connexions WebSocket sont peut-être bloquées.

Votre instance GitLab doit autoriser les connexions WebSocket entrantes depuis les clients IDE. Demandez à votre administrateur réseau d'[autoriser le trafic WebSocket vers votre instance GitLab](../../administration/gitlab_duo/configure/_index.md#allow-inbound-connections-from-clients-to-the-gitlab-instance) si vous soupçonnez que c'est le problème.

## Les commandes IDE échouent ou s'exécutent indéfiniment {#ide-commands-fail-or-run-indefinitely}

Lors de l'utilisation de GitLab Duo Agentic Chat ou du flow Software Development dans votre IDE, GitLab Duo peut se retrouver bloqué dans une boucle ou avoir des difficultés à exécuter des commandes.

Ce problème peut survenir lorsque vous utilisez des thèmes ou des intégrations de shell, comme `Oh My ZSH!` ou `powerlevel10k`. Lorsqu'un agent GitLab Duo génère un terminal, un thème ou une intégration peut empêcher les commandes de s'exécuter correctement.

Pour contourner ce problème, utilisez un thème plus simple pour les commandes envoyées par les agents. [Issue 2070](https://gitlab.com/gitlab-org/gitlab-vscode-extension/-/issues/2070) dans le projet d'extension VS Code suit les améliorations apportées à ce comportement afin que cette solution de contournement ne soit plus nécessaire.

### Modifier votre fichier `.zshrc` {#edit-your-zshrc-file}

Dans VS Code et les IDE JetBrains, configurez `Oh My ZSH!` ou `powerlevel10k` pour utiliser un thème plus simple lors de l'exécution des commandes envoyées par un agent. Vous pouvez utiliser les variables d'environnement exposées par les IDE pour définir ces valeurs.

Modifiez votre fichier `~/.zshrc` pour inclure ce code :

```shell
# ~/.zshrc

# Path to your oh-my-zsh installation
export ZSH="$HOME/.oh-my-zsh"

# ...

# Decide whether to load a full terminal environment,
# or keep it minimal for agentic AI in IDEs
if [[ "$TERM_PROGRAM" == "vscode" || "$TERMINAL_EMULATOR" == "JetBrains-JediTerm" ]]; then
  echo "IDE agentic environment detected, not loading full shell integrations"
else
  # Oh My ZSH
  source $ZSH/oh-my-zsh.sh
  # Theme: Powerlevel10k
  [[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
  # Other integrations like syntax highlighting
fi

# Other setup, like PATH variables
```

## Activer le mode débogage {#enable-debug-mode}

Pour activer les logs de débogage dans JetBrains :

1. Dans la barre supérieure, accédez à **Aide** > **Diagnostic Tools** > **Debug Log Settings**, ou recherchez l'action en accédant à **Aide** > **Find Action** > **Debug log settings**.
1. Ajoutez cette ligne : `com.gitlab.plugin`
1. Sélectionnez **OK** ou **Enregistrer**.

Si vous rencontrez des [erreurs de certificat](#certificate-errors) ou d'autres erreurs de connexion et que vous utilisez un proxy HTTP pour vous connecter à votre instance GitLab, vous devez [configurer le serveur de langage pour utiliser un proxy](../language_server/_index.md#configure-the-language-server-to-use-a-proxy) pour le serveur de langage GitLab.

Vous pouvez également [activer l'authentification par proxy](../language_server/_index.md#enable-proxy-authentication).

## Activer les logs de débogage du serveur de langage GitLab {#enable-gitlab-language-server-debug-logs}

Pour activer les logs de débogage du serveur de langage GitLab :

1. Dans votre IDE, dans la barre supérieure, sélectionnez le nom de votre IDE, puis sélectionnez **Paramètres**.
1. Dans la barre latérale gauche, sélectionnez **Outils** > **GitLab Duo**.
1. Sélectionnez **GitLab Language Server** pour développer la section.
1. Dans **Logging** > **Log Level**, saisissez `debug`.
1. Sélectionnez **Appliquer**.
1. Sous **Enable GitLab Language Server**, sélectionnez **Restart Language Server**.

## Obtenir les logs de débogage {#get-debug-logs}

Les logs de débogage sont disponibles dans le fichier log `idea.log`. Pour afficher ce fichier, vous pouvez :

<!-- vale gitlab_base.SubstitutionWarning = NO -->

- Dans votre IDE, accédez à **Aide** > **Show Log in Finder**.
- Accédez au répertoire `/Users/<user>/Library/Logs/JetBrains/IntelliJIdea<build_version>`, en remplaçant `<user>` et `<build_version>` par les valeurs appropriées.

<!-- vale gitlab_base.SubstitutionWarning = YES -->

## Erreurs de certificat {#certificate-errors}

Si votre machine se connecte à votre instance GitLab via un proxy, vous pourriez rencontrer des erreurs de certificat SSL dans JetBrains. GitLab Duo tente de détecter les certificats dans votre magasin système ; cependant, le serveur de langage ne peut pas effectuer cette opération. Si vous voyez des erreurs provenant du serveur de langage concernant des certificats, essayez d'activer l'option permettant de transmettre un certificat d'autorité de certification (CA) :

Pour ce faire :

1. Dans le coin inférieur droit de votre IDE, sélectionnez l'icône GitLab.
1. Dans la boîte de dialogue, sélectionnez **Show Settings**. Cela ouvre la boîte de dialogue **Paramètres** vers **Outils** > **GitLab Duo**.
1. Sélectionnez **GitLab Language Server** pour développer la section.
1. Sélectionnez **HTTP Agent Options** pour le développer.
1. L'une ou l'autre des options :
   - Sélectionnez l'option **Pass CA certificate from Duo to the Language Server**.
   - Dans **Certificate authority (CA)**, spécifiez le chemin vers votre fichier `.pem` contenant les certificats CA.
1. Redémarrez votre IDE.

### Ignorer les erreurs de certificat {#ignore-certificate-errors}

Si GitLab Duo ne parvient toujours pas à se connecter, vous devrez peut-être ignorer les erreurs de certificat. Vous pourriez voir des erreurs dans les logs du serveur de langage GitLab après avoir activé le [mode débogage](jetbrains_troubleshooting.md#enable-debug-mode) :

```plaintext
2024-10-31T10:32:54:165 [error]: fetch: request to https://gitlab.com/api/v4/personal_access_tokens/self failed with:
request to https://gitlab.com/api/v4/personal_access_tokens/self failed, reason: unable to get local issuer certificate
FetchError: request to https://gitlab.com/api/v4/personal_access_tokens/self failed, reason: unable to get local issuer certificate
```

Par conception, ce paramètre représente un risque de sécurité : ces erreurs vous alertent sur des failles de sécurité potentielles. Vous ne devez activer ce paramètre que si vous êtes absolument certain que le proxy est à l'origine du problème.

Prérequis :

- Vous avez vérifié la chaîne de certificats dans votre navigateur système, ou l'administrateur de votre machine a confirmé que cette erreur peut être ignorée en toute sécurité.

Pour ce faire :

1. Consultez la documentation JetBrains sur les [certificats SSL](https://www.jetbrains.com/help/idea/ssl-certificates.html).
1. Accédez à la barre de menu supérieure de votre IDE et sélectionnez **Paramètres**.
1. Dans la barre latérale gauche, sélectionnez **Outils** > **GitLab Duo**.
1. Confirmez que votre navigateur par défaut fait confiance à l'**URL to GitLab instance** que vous utilisez.
1. Activez l'option **Ignore certificate errors**.
1. Sélectionnez **Verify setup**.
1. Sélectionnez **OK** ou **Enregistrer**.

### L'authentification échoue dans PyCharm {#authentication-fails-in-pycharm}

Si vous rencontrez des problèmes lors de la phase **Verify setup** de l'authentification GitLab, confirmez que vous utilisez une version prise en charge de PyCharm :

1. Accédez à la page de [compatibilité du plugin](https://plugins.jetbrains.com/plugin/22325-gitlab-duo/versions).
1. Pour **Compatibility**, sélectionnez `PyCharm Community` ou `PyCharm Professional`.
1. Pour **Channels**, sélectionnez le niveau de stabilité souhaité pour le plugin GitLab.
1. Pour votre version de PyCharm, sélectionnez **Télécharger** pour télécharger la version correcte du plugin GitLab, puis installez-la.

## Erreurs JCEF {#jcef-errors}

Si vous rencontrez des problèmes avec GitLab Duo Chat liés à JCEF (Java Chromium Embedded Framework), vous pouvez essayer les étapes suivantes :

1. Dans la barre supérieure, accédez à **Aide** > **Find Action** et recherchez `Registry`.
1. Recherchez `ide.browser.jcef.sandbox.enable`.
1. Décochez la case pour désactiver ce paramètre.
1. Fermez la boîte de dialogue Registry.
1. Redémarrez votre IDE.
1. Dans la barre supérieure, accédez à **Aide** > **Find Action** et recherchez `Choose Boot Java Runtime for the IDE`.
1. Sélectionnez la version du runtime Java de démarrage identique à votre version actuelle de l'IDE, mais avec JCEF intégré : ![Exemple de runtime prenant en charge JCEF](img/jcef_supporting_runtime_example_v17_3.png)
1. Redémarrez votre IDE.

## Informations requises pour le support {#required-information-for-support}

Avant de contacter le support, assurez-vous que la dernière version du plugin GitLab Duo est installée. Toutes les releases sont disponibles sur le [JetBrains Marketplace](https://plugins.jetbrains.com/plugin/22325-gitlab-duo/versions), dans l'onglet **Versions**.

Collectez ces informations auprès des utilisateurs concernés et fournissez-les dans votre rapport de bug :

1. Le message d'erreur affiché à l'utilisateur ou l'utilisatrice.
1. Diagnostics et logs. Choisissez l'une des méthodes suivantes :
   - Automatique (recommandé) :
     - Exécutez l'action rapide `GitLab: Export Diagnostics Bundle`. Disponible avec le plugin GitLab Duo 3.27.0 ou version ultérieure.
     - Cela télécharge un fichier zip contenant les logs et les diagnostics de l'IDE vers un emplacement que vous spécifiez.
   - Manuel :
     - Activez et collectez les [logs de débogage](#enable-debug-mode)
     - Activez et collectez les [logs de débogage du serveur de langage](#enable-gitlab-language-server-debug-logs)
     - Capturez la [sortie des logs](#get-debug-logs)
     - Exécutez `GitLab: Diagnostics` depuis le menu des actions rapides et copiez la sortie Markdown
1. Décrivez la portée de l'impact. Combien d'utilisateurs et d'utilisatrices sont affectés ?
1. Décrivez comment reproduire l'erreur. Incluez un enregistrement d'écran, si possible.
1. Décrivez comment les autres fonctionnalités de GitLab Duo sont affectées :
   - GitLab Quick Chat est-il fonctionnel ?
   - Code Suggestions fonctionne-t-il ?
   - GitLab Duo Chat dans le Web IDE renvoie-t-il des réponses ?
1. Effectuez des tests d'isolation des extensions. Essayez de désactiver (ou de désinstaller) toutes les autres extensions pour déterminer si une autre extension est à l'origine du problème. Cela permet de déterminer si le problème provient de notre extension ou d'une source externe.
