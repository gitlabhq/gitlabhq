---
stage: AI-powered
group: Editor Extensions
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: "Dépannage de l'extension GitLab pour VS Code"
---

Lorsque vous utilisez GitLab pour VS Code, vous pouvez rencontrer les problèmes suivants.

Si votre problème n'est pas couvert ci-dessous, rassemblez les [informations requises pour le support](#required-information-for-support) et signalez le bug dans le [`gitlab-vscode-extension` issue tracker](https://gitlab.com/gitlab-org/gitlab-vscode-extension/-/issues).

## Journaux {#logs}

L'extension GitLab pour VS Code et le serveur de langage GitLab, qui alimente l'extension, fournissent tous deux des journaux qui peuvent vous aider à résoudre les problèmes.

### Activer les journaux de débogage {#enable-debug-logs}

Pour activer la journalisation de débogage :

1. Dans VS Code, ouvrez l'éditeur de paramètres :
   - Pour macOS, appuyez sur <kbd>Command</kbd>+<kbd>,</kbd>.
   - Pour Windows ou Linux, appuyez sur <kbd>Control</kbd>+<kbd>,</kbd>.
1. Sélectionnez **Extensions** > **GitLab** > **Autre**.
1. Sous **GitLab : Debug**, cochez la case pour activer le mode débogage.
1. Rechargez la fenêtre pour redémarrer l'extension.
   1. Ouvrez la palette de commandes :
      - Pour macOS, appuyez sur <kbd>Command</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>.
      - Pour Windows ou Linux, appuyez sur <kbd>Control</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>.
   1. Saisissez `Developer: Reload Window` et appuyez sur <kbd>Enter</kbd>.

### Afficher les journaux de débogage {#view-debug-logs}

Pour afficher les journaux de débogage :

1. Dans VS Code, sélectionnez **Afficher** > **Output**.
1. Dans le coin supérieur droit du panneau de sortie, sélectionnez la liste déroulante pour filtrer les journaux **GitLab** ou **GitLab Language Server**.
1. Recherchez les erreurs, avertissements, problèmes de connexion ou problèmes d'authentification.

## Authentification {#authentication}

Vous pouvez rencontrer les erreurs d'authentification suivantes.

### Erreur : `...can't access the OS Keychain` {#error-cant-access-the-os-keychain}

Sur macOS et Ubuntu, une erreur peut survenir lorsque l'extension ne peut pas accéder au trousseau du système d'exploitation pour s'authentifier.

Par exemple :

```plaintext
The GitLab extension can't access the OS Keychain.
If you use Ubuntu, see this existing issue.
```

```plaintext
Error: Cannot get password
at I.$getPassword (vscode-file://vscode-app/snap/code/97/usr/share/code/resources/app/out/vs/workbench/workbench.desktop.main.js:1712:49592)
```

Suivez la solution de contournement ci-dessous pour votre système d'exploitation.

Pour plus d'informations sur cette erreur, consultez :

- [Extension issue 580](https://gitlab.com/gitlab-org/gitlab-vscode-extension/-/issues/580)
- [Upstream `microsoft/vscode` issue 147515](https://github.com/microsoft/vscode/issues/147515)

#### Solution de contournement pour macOS {#macos-workaround}

Pour contourner cette erreur sur macOS :

1. Sur votre machine, ouvrez **Keychain Access** et recherchez `vscodegitlab.gitlab-workflow`.
1. Supprimez `vscodegitlab.gitlab-workflow` de votre trousseau.
1. Appuyez sur <kbd>Command</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd> pour ouvrir la palette de commandes.
1. Saisissez `GitLab: Remove Account from VS Code` et appuyez sur <kbd>Enter</kbd> pour supprimer le compte corrompu de VS Code.
1. Ouvrez à nouveau la palette de commandes et exécutez `GitLab: Authenticate` pour ajouter le compte à nouveau.

#### Solution de contournement pour Ubuntu {#ubuntu-workaround}

Lorsque vous installez VS Code avec `snap` dans Ubuntu 20.04 et 22.04, VS Code ne peut pas lire les mots de passe depuis le trousseau du système d'exploitation. Les versions de l'extension 3.44.0 et ultérieures utilisent le trousseau du système d'exploitation pour le stockage sécurisé des jetons.

Si vous utilisez une version de VS Code antérieure à 1.68.0, essayez l'une de ces solutions de contournement :

- Rétrogradez l'extension GitLab pour VS Code vers la version 3.43.1.
- Installez VS Code depuis le package `.deb` plutôt que `snap` :
  1. Désinstallez VS Code installé via `snap`.
  1. Installez VS Code depuis le [package `.deb`](https://code.visualstudio.com/Download).
  1. Accédez à **Password & Keys** dans Ubuntu, trouvez l'entrée `vscodegitlab.workflow/gitlab-tokens` et supprimez-la.
  1. Dans VS Code, appuyez sur <kbd>Control</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd> pour ouvrir la palette de commandes.
  1. Saisissez `Gitlab: Remove Your Account` et appuyez sur <kbd>Enter</kbd> pour supprimer le compte avec les identifiants manquants.
  1. Ouvrez à nouveau la palette de commandes et exécutez `GitLab: Authenticate` pour ajouter le compte à nouveau.

Si vous utilisez VS Code version 1.68.0 ou ultérieure, essayez de vous ré-authentifier :

1. Accédez à **Password & Keys** dans Ubuntu, trouvez l'entrée `vscodegitlab.workflow/gitlab-tokens` et supprimez-la.
1. Dans VS Code, appuyez sur <kbd>Control</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd> pour ouvrir la palette de commandes.
1. Saisissez `Gitlab: Remove Your Account` et appuyez sur <kbd>Enter</kbd> pour supprimer le compte avec les identifiants manquants.
1. Ouvrez à nouveau la palette de commandes et exécutez `GitLab: Authenticate` pour ajouter le compte à nouveau.

### Erreur de connexion et d'autorisation lors de l'utilisation de GDK {#connection-and-authorization-error-when-using-gdk}

Lors de l'utilisation de VS Code avec GDK, vous pouvez obtenir une erreur indiquant que votre système est incapable d'établir une connexion TLS sécurisée vers une instance GitLab fonctionnant en local.

Par exemple, si vous utilisez `127.0.0.1:3000` comme serveur GitLab :

```plaintext
Request to https://127.0.0.1:3000/api/v4/version failed, reason: Client network
socket disconnected before secure TLS connection was established
```

Ce problème survient si vous exécutez GDK sur `http` et que votre instance GitLab est hébergée sur `https`.

Pour résoudre ce problème :

1. Ouvrez la palette de commandes :
   - Pour macOS, appuyez sur <kbd>Command</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>.
   - Pour Windows ou Linux, appuyez sur <kbd>Control</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>.
1. Saisissez `GitLab: Authenticate` et appuyez sur <kbd>Enter</kbd>.
1. Sélectionnez l'option pour saisir manuellement une URL `http` pour votre instance et appuyez sur <kbd>Enter</kbd>.
1. Suivez les invites restantes pour vous authentifier.

## Configuration du projet {#project-configuration}

Vous pouvez rencontrer les erreurs de configuration de projet suivantes.

### Erreurs de configuration de compte et de projet {#account-and-project-configuration-errors}

Lorsque vous ouvrez un projet dans VS Code, un message d'erreur peut s'afficher à côté du nom du projet dans l'onglet **GitLab** ({{< icon name="tanuki" >}}). Vous pouvez également voir des messages d'avertissement concernant plusieurs comptes ou projets dans la barre d'état.

Ces messages s'affichent lorsque l'extension est incapable d'identifier le dépôt, le compte ou le projet à utiliser.

Pour résoudre ces erreurs :

- Si aucun remote n'est défini ou si vous avez plusieurs remotes configurés, consultez [se connecter à votre dépôt](setup.md#connect-to-your-repository).
- Si **Multiple GitLab Accounts** apparaît dans la barre d'état, [changez de compte](setup.md#switch-accounts).
- Si **(multiple projects)** apparaît dans la barre d'état, [sélectionnez un projet](setup.md#select-a-project).

Si c'est la première fois que vous utilisez Git dans VS Code, consultez [le contrôle de source dans VS Code](https://code.visualstudio.com/docs/sourcecontrol/overview) pour des informations sur l'initialisation des dépôts et des workspaces VS Code, ce qui s'effectue en dehors de l'extension GitLab.

#### Remote Git avec alias SSH personnalisé {#git-remote-with-ssh-custom-alias}

Si le remote de votre dépôt utilise un alias SSH personnalisé, l'extension pourrait ne pas faire correspondre correctement votre dépôt à votre projet GitLab. Par exemple, si votre remote utilise `git@my-work-gitlab:group/project.git` au lieu de `git@gitlab.com:group/project.git`.

Pour résoudre ce problème, vous pouvez :

- Modifier le remote pour utiliser HTTP ou utiliser SSH sans alias personnalisé.
- Configurer un espace de nommage GitLab Duo par défaut dans l'extension.

Pour configurer un espace de nommage par défaut :

1. [Déterminez l'espace de nommage dans lequel se trouve votre projet](../../user/namespace/_index.md#determine-which-type-of-namespace-youre-in).
1. Dans VS Code, ouvrez l'éditeur de paramètres :
   - Pour macOS, appuyez sur <kbd>Command</kbd>+<kbd>,</kbd>.
   - Pour Windows ou Linux, appuyez sur <kbd>Control</kbd>+<kbd>,</kbd>.
1. Sélectionnez **Extensions** > **GitLab** > **GitLab Duo**.
1. Sous **GitLab › Duo Agent Platform : Default Namespace**, saisissez votre espace de nommage.

### Le clonage de projet HTTPS fonctionne mais le clonage SSH échoue {#https-project-cloning-works-but-ssh-cloning-fails}

Vous pouvez obtenir une erreur de clonage SSH alors que le clonage HTTPS fonctionne. Cela se produit lorsque l'hôte ou le chemin de votre URL SSH est différent de votre chemin HTTPS.

L'extension GitLab pour VS Code utilise :

- L'hôte pour faire correspondre le compte que vous avez configuré.
- Le chemin pour obtenir l'espace de nommage et le nom du projet.

Par exemple, les URL pour le projet d'extension VS Code sont :

- SSH : `git@gitlab.com:gitlab-org/gitlab-vscode-extension.git`
- HTTPS : `https://gitlab.com/gitlab-org/gitlab-vscode-extension.git`

Les deux ont l'hôte `gitlab.com` et le chemin `gitlab-org/gitlab-vscode-extension`.

Pour résoudre cette erreur :

1. Vérifiez si votre URL SSH se trouve sur un hôte différent ou si elle comporte des segments supplémentaires dans le chemin.
1. Si l'une ou l'autre de ces conditions est vraie, assignez manuellement le dépôt Git à un projet GitLab :
   1. Dans VS Code, dans la barre latérale gauche, sélectionnez **GitLab** ({{< icon name="tanuki" >}}).
   1. Sélectionnez le projet marqué `(no GitLab project)`, puis sélectionnez **Manually assign GitLab project** : ![Assign GitLab project manually](img/manually_assign_v15_3.png)
   1. Sélectionnez le projet correct dans la liste.

Pour plus d'informations sur la simplification de ce processus, consultez l'[issue 577](https://gitlab.com/gitlab-org/gitlab-vscode-extension/-/issues/577) dans le projet `gitlab-vscode-extension`.

## Réseau et connectivité {#network-and-connectivity}

Vous pouvez rencontrer les erreurs de réseau et de connectivité suivantes.

### Erreur : échec `407 Access Denied` avec un proxy {#error-407-access-denied-failure-with-a-proxy}

Si vous utilisez un proxy authentifié, vous pouvez rencontrer une erreur `407 Access Denied (authentication_failed)`.

Par exemple :

```plaintext
Request failed: Can't add GitLab account for https://gitlab.com. Check your instance URL and network connection.
Fetching resource from https://gitlab.com/api/v4/personal_access_tokens/self failed
```

Pour résoudre cette erreur, [activez l'authentification proxy](../language_server/_index.md#enable-proxy-authentication) pour le serveur de langage GitLab.

### Erreurs avec des certificats personnalisés {#errors-with-custom-certificates}

Si vous utilisez des certificats personnalisés pour vous connecter à votre instance GitLab, comme des certificats auto-signés, vous pouvez rencontrer des erreurs.

Ces erreurs peuvent survenir si vos certificats utilisent les paramètres suivants :

| Nom du paramètre                     | Informations |
|----------------------------------|-------------|
| `gitlab.ca`                      | Obsolète. Consultez [le guide de configuration SSL](ssl.md) pour plus d'informations sur la configuration de votre CA auto-signé.|
| `gitlab.cert`                    | Non pris en charge. Consultez l'[epic 6244](https://gitlab.com/groups/gitlab-org/-/epics/6244). |
| `gitlab.certKey`                 | Non pris en charge. Consultez l'[epic 6244](https://gitlab.com/groups/gitlab-org/-/epics/6244). |
| `gitlab.ignoreCertificateErrors` | Non pris en charge. Consultez l'[epic 6244](https://gitlab.com/groups/gitlab-org/-/epics/6244). |

Pour résoudre ce problème, consultez [configurer l'extension pour les autorités de certification personnalisées](https://gitlab.com/gitlab-org/gitlab-vscode-extension/-/blob/main/docs/user/custom-certificates.md).

### Certificat SSL expiré {#expired-ssl-certificate}

Vous pouvez rencontrer une fausse erreur de certificat SSL expiré. Par exemple :

`API request failed - Error: certificate has expired`.

Pour résoudre cette erreur, désactivez les certificats système :

1. Dans VS Code, ouvrez l'éditeur de paramètres :
   - Pour macOS, appuyez sur <kbd>Command</kbd>+<kbd>,</kbd>.
   - Pour Windows ou Linux, appuyez sur <kbd>Control</kbd>+<kbd>,</kbd>.
1. Dans l'onglet des paramètres **Utilisateur/utilisatrice**, sélectionnez **Application** > **Proxy**.
1. Désactivez les paramètres **Proxy Strict SSL** et **System Certificates**.

## GitLab Duo {#gitlab-duo}

Lorsque vous utilisez GitLab Duo dans VS Code, vous pouvez rencontrer les problèmes suivants.

### Les fonctionnalités de GitLab Duo sont indisponibles {#gitlab-duo-features-are-unavailable}

Pour résoudre les erreurs GitLab Duo dans VS Code :

1. Assurez-vous de remplir les [prérequis](setup.md#configure-gitlab-duo) et que les paramètres nécessaires sont activés.
1. Assurez-vous que [le mode Admin est désactivé](../../administration/settings/sign_in_restrictions.md#turn-off-admin-mode-for-your-session).
1. Examinez la sortie des diagnostics :
   1. Dans VS Code, ouvrez la palette de commandes :
      - Pour macOS, appuyez sur <kbd>Command</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>
      - Pour Windows ou Linux, appuyez sur <kbd>Control</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>
   1. Exécutez la commande `GitLab: Diagnostics` et examinez la sortie pour les vérifications ayant échoué.
1. Si les diagnostics indiquent que la fonctionnalité n'est pas activée :
   1. Dans VS Code, ouvrez l'éditeur de paramètres :
      - Pour macOS, appuyez sur <kbd>Command</kbd>+<kbd>,</kbd>.
      - Pour Windows ou Linux, appuyez sur <kbd>Control</kbd>+<kbd>,</kbd>.
   1. Sélectionnez **Extensions** > **GitLab** > **GitLab Duo**.
   1. Recherchez la section **GitLab ›** pour la fonctionnalité manquante et cochez la case pour l'activer.
1. Si les diagnostics indiquent que le chat agentique n'est pas pris en charge pour le projet actuel, définissez un [espace de nommage GitLab Duo par défaut](../../user/profile/preferences.md#namespace-resolution-in-your-local-environment).
1. Si les diagnostics indiquent que toutes les vérifications du chat agentique sont réussies et que vous ne voyez toujours pas le panneau, il est peut-être masqué dans votre [disposition VS Code personnalisée](https://code.visualstudio.com/docs/configure/custom-layout).
   1. Dans VS Code, ouvrez la palette de commandes :
      - Pour macOS, appuyez sur <kbd>Command</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>
      - Pour Windows ou Linux, appuyez sur <kbd>Control</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>
   1. Exécutez la commande `View: Show GitLab Duo Agent Platform` ou `View: Toggle GitLab Duo Agent Platform`.

Pour obtenir de l'aide concernant Code Suggestions, consultez [Dépannage de Code Suggestions](../../user/project/repository/code_suggestions/troubleshooting.md#vs-code-troubleshooting).

### GitLab Duo renvoie des réponses `HTTP/1.1` au lieu des endpoints WebSocket {#gitlab-duo-returns-http11-responses-instead-of-websocket-endpoints}

Vous pouvez voir des réponses `HTTP/1.1` de GitLab Duo dans vos journaux au lieu des endpoints WebSocket `/-/cable`.

Cela se produit lorsque votre instance GitLab bloque les connexions WebSocket.

Pour résoudre cette erreur, demandez à votre administrateur réseau de modifier votre instance GitLab pour [autoriser les connexions WebSocket entrantes provenant des clients IDE](../../administration/gitlab_duo/configure/_index.md#allow-inbound-connections-from-clients-to-the-gitlab-instance).

### L'initialisation de GitLab Duo Chat échoue dans les environnements distants {#gitlab-duo-chat-fails-to-initialize-in-remote-environments}

Lors de l'utilisation de GitLab Duo Chat dans des environnements de développement à distance (comme VS Code dans un navigateur ou des connexions SSH distantes), vous pouvez rencontrer des échecs d'initialisation tels que :

- Un panneau Chat vide ou qui ne se charge pas.
- Des erreurs dans les journaux, telles que `The webview didn't initialize in 10000ms`.
- L'extension tente de se connecter à des URL locales inaccessibles.

Pour résoudre ces erreurs :

1. Dans VS Code, ouvrez l'éditeur de paramètres :
   - Pour macOS, appuyez sur <kbd>Command</kbd>+<kbd>,</kbd>.
   - Pour Windows ou Linux, appuyez sur <kbd>Control</kbd>+<kbd>,</kbd>.
1. Dans le coin supérieur droit, sélectionnez **Ouvrir les paramètres (JSON)** pour modifier votre fichier `settings.json`.
1. Ajoutez ou modifiez ce paramètre :

   ```json
   "gitlab.featureFlags.languageServerWebviews": false
   ```

1. Enregistrez vos modifications et rechargez la fenêtre :
   1. Ouvrez la palette de commandes :
      - Pour macOS, appuyez sur <kbd>Command</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>.
      - Pour Windows ou Linux, appuyez sur <kbd>Control</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>.
   1. Saisissez `Developer: Reload Window` et appuyez sur <kbd>Enter</kbd>.

Pour les mises à jour concernant une solution permanente, consultez l'[issue #1944](https://gitlab.com/gitlab-org/gitlab-vscode-extension/-/issues/1944) et l'[Issue #1943](https://gitlab.com/gitlab-org/gitlab-vscode-extension/-/issues/1943)

### Les commandes GitLab Duo échouent ou s'exécutent indéfiniment {#gitlab-duo-commands-fail-or-run-indefinitely}

Lorsque vous utilisez GitLab Duo Agentic Chat ou le flow Software Development dans votre IDE, GitLab Duo peut se retrouver bloqué dans une boucle ou avoir des difficultés à exécuter des commandes.

Ce problème peut survenir lorsque vous utilisez des thèmes de shell ou des intégrations, comme `Oh My ZSH!` ou `powerlevel10k`. Lorsqu'un agent GitLab Duo crée un terminal, le thème ou l'intégration du shell peut empêcher les commandes de s'exécuter correctement.

À titre de solution de contournement, suivez les instructions ci-dessous pour utiliser un thème plus simple pour les commandes envoyées par les agents.

Pour plus d'informations sur un correctif, consultez l'[issue 2116](https://gitlab.com/gitlab-org/gitlab-vscode-extension/-/work_items/2116).

#### Modifier votre fichier `.zshrc` {#edit-your-zshrc-file}

Dans VS Code, configurez `Oh My ZSH!` ou `powerlevel10k` pour utiliser un thème plus simple lorsqu'il exécute des commandes envoyées par un agent. Vous pouvez utiliser les variables d'environnement exposées par les IDE pour définir ces valeurs.

Modifiez votre fichier `~/.zshrc` pour inclure ce code :

```shell
# ~/.zshrc

# Path to your oh-my-zsh installation
export ZSH="$HOME/.oh-my-zsh"

# ...

# Decide whether to load a full terminal environment,
# or keep it minimal for agentic AI in IDEs
if [[ "$TERM_PROGRAM" == "vscode" ]]; then
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

#### Modifier votre shell Bash {#edit-your-bash-shell}

Dans VS Code, vous pouvez désactiver les invites avancées dans Bash.

Modifiez votre fichier `~/.bashrc` ou `~/.bash_profile` pour inclure ce code :

```shell
# ~/.bashrc or ~/.bash_profile

# Decide whether to load a full terminal environment,
# or keep it minimal for Agentic AI in IDEs
if [[ "$TERM_PROGRAM" == "vscode" ]]; then
  echo "IDE agentic environment detected, not loading full shell integrations"

  # Keep only essential settings for agents
  export PS1='\$ '  # Minimal prompt

else
  # Load full Bash environment

  # Custom prompt (e.g., Starship, custom PS1)
  if command -v starship &> /dev/null; then
    eval "$(starship init bash)"
  else
    # ... Add your own PS1 variable
  fi

  # Load additional integrations
fi

# Always load essential environment variables and aliases
```

## Informations requises pour le support {#required-information-for-support}

Avant de contacter le support, assurez-vous que la dernière version de l'extension GitLab pour VS Code est installée.

Retrouvez les dernières releases sur le [VS Code Marketplace](https://marketplace.visualstudio.com/items?itemName=GitLab.gitlab-workflow), dans l'onglet **Version History**.

Collectez ces informations auprès des utilisateurs et utilisatrices concernés et fournissez-les dans votre rapport de bug :

1. Le message d'erreur affiché à l'utilisateur ou l'utilisatrice.
1. Les [journaux](#logs) **GitLab** et **GitLab Language Server**.
1. La sortie des diagnostics.
   1. Ouvrez la palette de commandes :
      - Pour macOS, appuyez sur <kbd>Command</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>.
      - Pour Windows ou Linux, appuyez sur <kbd>Control</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>.
   1. Saisissez `GitLab: Diagnostics` et appuyez sur <kbd>Enter</kbd>.
   1. Notez la version de l'extension.
1. Détails du système :
   - Dans VS Code, les détails **OS** :
     - Pour macOS, accédez à **Code** > **About Visual Studio Code** et trouvez **OS**.
     - Pour Windows ou Linux, accédez à **Aide** > **À propos** et trouvez **OS**.
   - Spécifications de la machine (CPU, RAM) : Fournissez ces informations depuis votre machine. Elles ne sont pas accessibles depuis l'IDE.
1. Décrivez la portée de l'impact. Combien d'utilisateurs et d'utilisatrices sont affectés ?
1. Décrivez comment reproduire l'erreur. Incluez un enregistrement d'écran, si possible.
1. Décrivez comment les autres fonctionnalités de GitLab Duo sont affectées :
   - GitLab Quick Chat est-il fonctionnel ?
   - Code Suggestions fonctionne-t-il ?
   - GitLab Duo Chat dans le Web IDE renvoie-t-il des réponses ?
1. Effectuez des tests d'isolation d'extension comme décrit dans le [guide d'isolation de l'extension GitLab pour VS Code](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/issues/814#step-2-extension-isolation-testing). Essayez de désactiver (ou de désinstaller) toutes les autres extensions pour déterminer si une autre extension est à l'origine du problème.
