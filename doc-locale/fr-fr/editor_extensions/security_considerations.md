---
stage: AI-powered
group: Editor Extensions
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "Considérations de sécurité relatives à l'utilisation des extensions d'éditeur GitLab et des outils CLI avec l'exécution locale d'agent d'IA."
title: "Considérations de sécurité pour les extensions d'éditeur et les outils CLI"
---

Les extensions d'éditeur GitLab et les outils CLI peuvent exécuter des agents d'IA dans votre environnement local. Comprenez les implications en matière de sécurité et suivez les bonnes pratiques pour protéger votre environnement de développement.

## Risques liés à l'exécution locale des agents {#local-agent-execution-risks}

Lorsque les extensions d'éditeur et les outils CLI exécutent des agents localement, ceux-ci s'exécutent sans isolation de conteneur et disposent d'un accès direct aux ressources de votre système.

### Accès au système de fichiers {#file-system-access}

Les agents disposent de différents niveaux d'accès aux fichiers selon le type d'opération.

#### Opérations sur les fichiers {#file-operations}

Les agents peuvent effectuer des opérations sur les fichiers (lecture, écriture, modification, recherche et liste) sur :

- Les fichiers situés dans le dépôt Git de votre projet GitLab.
- Les fichiers non exclus par les règles `.gitignore`.
- Les liens symboliques valides ou résolvables qui pointent vers des fichiers situés dans le dépôt Git.

#### Opérations shell sur les fichiers {#shell-operations-on-files}

Les commandes shell exécutées par les agents peuvent accéder à tous les fichiers, y compris ceux situés en dehors des dépôts Git et ceux qui correspondent aux patterns `.gitignore`.

### Accès aux variables d'environnement {#environment-variable-access}

Les agents ont accès à toutes les variables d'environnement de votre session shell, à l'exception des suivantes :

- `CI_JOB_TOKEN`
- `GITLAB_OAUTH_TOKEN`
- `DUO_WORKFLOW_SERVICE_TOKEN`

### Ressources système {#system-resources}

Les agents ont accès aux ressources système suivantes :

- Requêtes réseau : Les agents peuvent effectuer des requêtes réseau depuis votre poste de travail.
- Exécution de processus : Les agents peuvent exécuter des commandes dans votre environnement shell.

### Menaces de sécurité {#security-threats}

En l'absence d'isolation, les menaces suivantes sont possibles :

- Injection de prompt : Des prompts malveillants manipulent le comportement des agents et exécutent des actions non souhaitées.
- Compromission d'agent : Des agents compromis fournissent un accès aux ressources de votre poste de travail.
- Exfiltration de données : Toutes les données présentes sur votre poste de travail, y compris les données sensibles telles que les mots de passe, le code source et les fichiers personnels, peuvent être dérobées.
- Déplacement latéral : Des identifiants exposés permettent l'accès à d'autres systèmes et services.

## Bonnes pratiques de sécurité recommandées {#recommended-security-practices}

Pour protéger votre environnement de développement, suivez ces bonnes pratiques de sécurité.

### Examiner les appels d'outils avant approbation {#review-tool-calls-before-approval}

Lorsque les agents demandent votre approbation pour exécuter des actions, examinez attentivement chaque appel d'outil avant de l'approuver.

Vérifiez que :

- Les commandes et les opérations sur les fichiers correspondent à la tâche souhaitée.
- Les chemins de fichiers se trouvent dans les répertoires attendus, y compris les fichiers cibles des liens symboliques.
- Les arguments de commande n'incluent pas d'indicateurs ou de paramètres inattendus.
- L'accès aux fichiers sensibles et les requêtes réseau sont nécessaires à la tâche.

Votre administrateur peut contrôler si vous pouvez approuver les outils une seule fois pour une session, au lieu d'approuver chaque invocation. Pour plus d'informations, consultez [les approbations d'outils](../user/gitlab_duo_chat/agentic_chat.md#tool-approvals).

Si vous utilisez le CLI GitLab Duo en mode headless, les appels d'outils sont approuvés automatiquement. Utilisez le mode headless avec précaution et dans un environnement sandbox contrôlé, tel qu'un conteneur de développement.

### Vérifier les sources et les permissions des serveurs MCP {#verify-mcp-server-sources-and-permissions}

Pour utiliser les serveurs Model Context Protocol (MCP) de manière sécurisée avec GitLab Duo :

- Activez uniquement les serveurs MCP provenant de sources fiables.
- Examinez les permissions et les capacités que chaque serveur MCP demande.
- Vérifiez les données auxquelles les serveurs MCP peuvent accéder avant de les activer.
- Effectuez régulièrement un audit des serveurs MCP activés dans votre environnement.

### Utiliser des conteneurs de développement pour l'isolation {#use-development-containers-for-isolation}

Utilisez des conteneurs de développement pour atténuer les risques liés à l'exécution locale.

Pour les utilisateurs du CLI GitLab Duo, le mode headless contourne les approbations manuelles des outils, ce qui rend les conteneurs de développement particulièrement importants.

Les conteneurs de développement offrent :

- Isolation des processus : Exécutez les agents dans un environnement de conteneur isolé, et non directement sur votre machine hôte.
- Accès limité au système de fichiers : Configurez les conteneurs pour restreindre l'accès aux seuls fichiers nécessaires.
- Isolation des identifiants : Gérez les identifiants séparément et injectez-les dans le conteneur selon les besoins.
- Isolation réseau : Restreignez la mise en réseau des conteneurs pour limiter l'accès externe.

L'extension GitLab pour VS Code est compatible avec VS Code Dev Containers. Pour plus d'informations, consultez [utiliser l'extension dans un Dev Container Visual Studio Code](visual_studio_code/setup.md#install-in-a-visual-studio-code-dev-container).
