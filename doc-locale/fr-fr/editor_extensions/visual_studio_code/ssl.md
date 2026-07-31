---
stage: AI-powered
group: Editor Extensions
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: "Utilisation de l'extension VS Code avec des certificats auto-signés"
---

Vous pouvez toujours utiliser l'extension GitLab pour VS Code même si votre instance GitLab utilise un certificat SSL auto-signé.

Si vous utilisez également un proxy pour vous connecter à votre instance GitLab, faites-le nous savoir dans l'[issue 314](https://gitlab.com/gitlab-org/gitlab-vscode-extension/-/issues/314). Si vous rencontrez toujours des problèmes de connexion après avoir effectué ces étapes, consultez l'[epic 6244](https://gitlab.com/groups/gitlab-org/-/epics/6244), qui contient des liens vers tous les problèmes SSL existants pour l'extension GitLab pour VS Code.

## Utiliser l'extension avec une CA auto-signée {#use-the-extension-with-a-self-signed-ca}

Prérequis :

- Votre instance GitLab utilise un certificat signé par une autorité de certification (CA) auto-signée.
- Votre version de GitLab pour VS Code est 6.51.1 ou ultérieure.
- Votre version de VS Code est 1.101.2 (mai 2025) ou ultérieure.
- Le paramètre VS Code `gitlab.ca` n'est pas utilisé.

1. Vérifiez que votre certificat CA est correctement ajouté à votre système pour que l'extension fonctionne. VS Code lit le magasin de certificats système et modifie toutes les requêtes node `http` pour qu'elles approuvent les certificats :

   ```mermaid
   %%{init: { "fontFamily": "GitLab Sans" }}%%
   graph LR
      accTitle: Self-signed certificate chain
      accDescr: Shows a self-signed CA that signs the GitLab instance certificate.

      A[Self-signed CA] -- signed --> B[Your GitLab instance certificate]
   ```

   La CA du certificat de l'instance GitLab doit être explicitement spécifiée en tant que CA approuvée. Si des certificats intermédiaires sont utilisés, ceux-ci doivent être disponibles sur le système. Si la chaîne complète ne se valide pas correctement, les connexions réseau au sein de l'extension échouent à l'authentification.

   Pour plus d'informations, consultez [Self-signed certificate error when installing Python support in WSL](https://github.com/microsoft/vscode/issues/131836#issuecomment-909983815) dans le suivi des problèmes de Visual Studio Code.

1. Dans votre `settings.json` VS Code, définissez `"http.systemCertificates": true`. La valeur par défaut est `true`, vous n'aurez donc peut-être pas besoin de modifier cette valeur.
1. Suivez les instructions des sections suivantes en fonction de votre système d'exploitation.

### Windows {#windows}

> [!note]
> Ces instructions ont été testées sur Windows 10 et VS Code 1.60.0.

Vérifiez que vous pouvez voir votre CA auto-signée dans votre magasin de certificats :

1. Ouvrez l'invite de commandes.
1. Exécutez `certmgr`.
1. Vérifiez que votre certificat apparaît dans **Trusted Root Certification Authorities** > **Certificats**.

### Linux {#linux}

> [!note]
> Ces instructions ont été testées sur Arch Linux `5.14.3-arch1-1` et VS Code 1.60.0.

1. Utilisez les outils de votre système d'exploitation pour confirmer que vous pouvez ajouter votre CA auto-signée à votre système :
   - `update-ca-trust` (Fedora, RHEL, CentOS)
   - `update-ca-certificates` (Ubuntu, Debian, OpenSUSE, SLES)
   - `trust` (Arch)
1. Confirmez que le certificat CA se trouve dans `/etc/ssl/certs/ca-certificates.crt` ou `/etc/ssl/certs/ca-bundle.crt`. VS Code [vérifie cet emplacement](https://github.com/microsoft/vscode/issues/131836#issuecomment-909983815).

### MacOS {#macos}

> [!note]
> Ces instructions ont été testées sur macOS Tahoe 26, VS Code 1.101.2 et GitLab pour VS Code 6.51.1.

Vérifiez que la CA auto-signée apparaît dans votre trousseau :

1. Accédez à **Finder** > **Applications** > **Utilities** > **Keychain Access**.
1. Dans la colonne de gauche, sélectionnez **Système**.
1. Trouvez votre certificat CA auto-signé dans la liste.
1. Faites un clic droit sur le certificat et sélectionnez **Get Info**.
1. Développez la section **Trust**.
1. Vérifiez que l'option **Secure Sockets Layer (SSL)** est définie sur « Always Trust ».
