---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "Créez, suivez et livrez le code de votre projet."
title: Premiers pas avec la gestion du code
---

GitLab fournit des outils pour l'intégralité du cycle de vie du développement logiciel, de la création du code à sa livraison.

Apprenez-en davantage sur la création et la gestion du code dans GitLab. Le processus comprend la rédaction de votre code, sa révision, son commit avec le contrôle de version, et sa mise à jour au fil du temps.

Ce processus fait partie d'un workflow plus large :

![Gérez votre code dans l'étape Create du cycle de vie DevOps de GitLab.](img/get_started_code_workflow_v16_11.png)

## Étape 1 :  Créer un dépôt {#step-1-create-a-repository}

Un projet est un emplacement centralisé où vous collaborez avec d'autres personnes, suivez les tickets, gérez les merge requests et automatisez les pipelines CI/CD, entre autres.

Chaque projet contient un dépôt, où vous pouvez stocker votre code, votre documentation et d'autres fichiers liés à votre travail de développement logiciel. Les modifications apportées aux fichiers dans le dépôt sont suivies, ce qui vous permet de consulter un historique.

Alors qu'un dépôt se concentre sur le contrôle de version du code source, un projet fournit un environnement complet pour l'ensemble du cycle de vie du développement.

Pour plus d'informations, voir [créer un dépôt](../project/repository/_index.md#create-a-repository).

## Étape 2 :  Écrire votre code {#step-2-write-your-code}

Vous disposez de nombreuses options pour savoir comment et où écrire votre code.

Vous pouvez utiliser l'interface utilisateur de GitLab et développer directement dans votre navigateur. Vous avez deux options :

- L'éditeur de texte brut, appelé Web Editor, que vous pouvez utiliser pour modifier un seul fichier.
- Un éditeur plus complet, appelé Web IDE, que vous pouvez utiliser pour modifier plusieurs fichiers.

Vous préférez travailler en local ? Utilisez Git pour cloner le dépôt sur votre ordinateur et développez dans l'IDE de votre choix. Vous pouvez ensuite utiliser l'une des extensions d'éditeur GitLab pour faciliter l'interaction avec GitLab.

Vous ne souhaitez utiliser aucune des deux premières options ? Lancez un environnement de développement à distance et travaillez depuis le cloud.

Vous pouvez également diviser votre environnement de développement en créant des workspaces distincts. Les workspaces sont des environnements de développement distincts que vous utilisez pour vous assurer que différents projets n'interfèrent pas les uns avec les autres.

Pour plus d'informations, voir :

- [Créer un fichier dans le dépôt depuis l'interface utilisateur](../project/repository/_index.md#add-a-file-from-the-ui)
- [Ouvrir un fichier dans le Web IDE](../project/web_ide/_index.md#from-a-file)
- [Créer un environnement de développement à distance avec des workspaces](../workspace/_index.md)
- [Extensions d'éditeur disponibles](../../editor_extensions/_index.md)

Pour toute autre aide à la rédaction de code, utilisez Code Suggestions.

## Étape 3 :  Enregistrer les modifications et pousser vers GitLab {#step-3-save-changes-and-push-to-gitlab}

Lorsque vos modifications sont prêtes, vous devez les committer dans GitLab, où vous pouvez les partager avec les autres membres de votre équipe.

Pour committer vos modifications, copiez-les d'abord :

- Depuis votre ordinateur local, dans votre propre branche
- Vers GitLab, sur un ordinateur distant, vers la `default branch`.

Pour copier des fichiers entre des branches, vous créez une merge request. La façon dont vous procédez dépend de l'endroit où vous avez rédigé le code et des outils que vous utilisez pour le créer. Mais l'idée est de créer une merge request qui prend le contenu de votre branche source et propose de le fusionner dans la branche cible.

Pour plus d'informations, voir :

- [Utiliser Git pour créer une merge request](../../tutorials/make_first_git_commit/_index.md)
- [Utiliser l'interface utilisateur pour créer une merge request lors de l'ajout, de la modification ou de l'envoi d'un fichier](../project/merge_requests/creating_merge_requests.md)

## Étape 4 :  Faire réviser le code {#step-4-have-the-code-reviewed}

Après avoir créé une merge request proposant des modifications à la base de code, vous pouvez faire réviser votre proposition. Les revues de code aident à maintenir la qualité et la cohérence du code. C'est également une occasion de partage des connaissances entre les membres de l'équipe.

La merge request affiche la différence entre les modifications proposées et la branche dans laquelle vous souhaitez fusionner.

Les relecteurs peuvent voir les modifications et laisser des commentaires sur des lignes de code spécifiques. Les relecteurs peuvent également suggérer des modifications directement dans le diff.

Les relecteurs peuvent approuver les modifications ou demander des modifications supplémentaires avant la fusion. GitLab suit le statut de révision et empêche la fusion jusqu'à l'obtention des approbations nécessaires.

Votre organisation peut avoir des règles de protection qui exigent des approbations spécifiques ou empêchent certaines actions. Par exemple, vous pourriez avoir besoin de l'approbation d'un propriétaire du code pour les fichiers que vous modifiez, ou votre merge request pourrait nécessiter un certain nombre d'approbations avant de pouvoir être fusionnée.

Pour plus d'informations, voir :

- [Demander une révision de votre merge request](../project/merge_requests/reviews/_index.md#request-a-review)
- [Ajouter des suggestions à une merge request](../project/merge_requests/reviews/suggestions.md#create-suggestions)
- [Approbations de merge request](../project/merge_requests/approvals/_index.md)
- [Propriétaires du code](../project/codeowners/_index.md)

## Étape 5 :  Fusionner la merge request {#step-5-merge-the-merge-request}

Avant que vos modifications puissent être fusionnées, la merge request doit généralement être approuvée par d'autres personnes et disposer d'un pipeline CI/CD réussi. Les exigences sont propres à votre organisation, mais elles comprennent généralement la vérification des éléments suivants :

- Les modifications du code respectent les directives de votre organisation.
- Les messages de commit sont clairs et renvoient aux tickets associés.

Les branches protégées et d'autres mesures de protection du dépôt peuvent vous empêcher de fusionner directement ou nécessiter des étapes supplémentaires. Si vous ne pouvez pas fusionner vos modifications, consultez votre équipe au sujet des règles de protection en place.

Des conflits de merge peuvent se produire si quelqu'un d'autre modifie un fichier après que vous avez créé votre branche, mais avant que vous ne l'ayez fusionnée dans la branche cible. Vous devez résoudre tous les conflits avant de pouvoir fusionner.

Pour plus d'informations, voir :

- [Conflits de merge](../project/merge_requests/conflicts.md)
- [Méthodes de fusion](../project/merge_requests/methods/_index.md)
- [Protéger votre dépôt](../project/repository/protect.md)
