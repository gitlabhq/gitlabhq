---
stage: AI-powered
group: Editor Extensions
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "Utilisez l'extension GitLab pour VS Code pour effectuer et examiner des analyses de sécurité."
title: Sécuriser votre application dans GitLab pour VS Code
---

Utilisez l'extension GitLab pour VS Code pour vérifier la présence de vulnérabilités de sécurité dans votre application. Examinez les résultats de sécurité et exécutez le test statique de sécurité des applications (SAST) pour les fichiers directement dans votre IDE.

## Afficher les résultats de sécurité {#view-security-findings}

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Prérequis :

- GitLab pour VS Code 3.74.0 ou version ultérieure.
- Un projet qui inclut des fonctionnalités de [Security Risk Management](https://about.gitlab.com/features/?stage=secure), telles que le test statique de sécurité des applications (SAST), le test dynamique de sécurité des applications (DAST), l'analyse des conteneurs ou l'analyse des dépendances.
- Fonctionnalités de [gestion des risques de sécurité](../../user/application_security/secure_your_application.md) configurées.

Pour afficher les résultats de sécurité :

1. Dans VS Code, dans la barre latérale gauche, sélectionnez **GitLab** ({{< icon name="tanuki" >}}).
1. Dans la section de la branche actuelle, développez **Analyse de sécurité**.
1. Sélectionnez **New findings** ou **Fixed findings**.
1. Sélectionnez un niveau de gravité.
1. Sélectionnez un résultat pour l'ouvrir dans un onglet VS Code.

## Test statique de sécurité des applications (SAST) {#static-application-security-testing-sast}

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com
- Statut : Expérience

{{< /details >}}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab-vscode-extension/-/issues/1675) dans l'extension VS Code 5.31.

{{< /history >}}

Le test statique de sécurité des applications (SAST) dans VS Code détecte les vulnérabilités dans le fichier actif. Grâce à une détection précoce, vous pouvez corriger les vulnérabilités avant de fusionner vos modifications dans la branche par défaut.

Lorsque vous déclenchez une analyse SAST, le contenu du fichier actif est transmis à GitLab et vérifié par rapport aux règles de vulnérabilité SAST. GitLab affiche les résultats de l'analyse dans le panneau de l'extension **GitLab** ({{< icon name="tanuki" >}}).

<i class="fa-youtube-play" aria-hidden="true"></i> Pour en savoir plus sur la configuration de l'analyse SAST, consultez [SAST scanning in VS Code](https://www.youtube.com/watch?v=s-qOSQO0i-8) sur GitLab Unfiltered.
<!-- Video published on 2025-02-10 -->

### Activer l'analyse SAST {#enable-sast-scanning}

Pour activer l'analyse SAST en temps réel :

1. Sélectionnez **Extensions** > **GitLab**.
1. Sélectionnez **Gérer** ({{< icon name="settings" >}}), puis sélectionnez **Paramètres** > **Code Security**.
1. Cochez la case **Enable Real-time SAST scan**.
1. Facultatif. Pour activer l'analyse SAST du fichier actif lors de son enregistrement, cochez la case **Enable scanning on file save**.

### Effectuer une analyse SAST {#perform-sast-scanning}

Prérequis :

- GitLab pour VS Code 5.31.0 ou version ultérieure.
- L'extension est [authentifiée auprès de GitLab](setup.md#authenticate-with-gitlab).
- L'analyse SAST en temps réel est activée.

Pour effectuer une analyse SAST d'un fichier dans VS Code :

1. Ouvrez le fichier.
1. Déclenchez l'analyse SAST en effectuant l'une des actions suivantes :
   - Enregistrez le fichier (si vous avez activé l'analyse à l'enregistrement du fichier).
   - Dans la barre latérale gauche, sélectionnez **GitLab** ({{< icon name="tanuki" >}}) > **GitLab remote scan (SAST)**. Ensuite, sélectionnez le bouton **Scan current file** en haut de la section.
   - Utilisez la palette de commandes :
     1. Ouvrez la palette de commandes :
        - Sur macOS, appuyez sur <kbd>Command</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>.
        - Sur Windows ou Linux, appuyez sur <kbd>Control</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>.
     1. Recherchez **GitLab : Run Remote Scan (SAST)** et appuyez sur <kbd>Enter</kbd>.
1. Affichez les résultats de l'analyse SAST.
   1. Dans VS Code, dans la barre latérale gauche, sélectionnez **GitLab** ({{< icon name="tanuki" >}}).
   1. Développez la section GitLab remote scan (SAST). Les résultats de l'analyse SAST sont répertoriés par ordre décroissant de gravité.
   1. Sélectionnez un résultat pour examiner les détails.
