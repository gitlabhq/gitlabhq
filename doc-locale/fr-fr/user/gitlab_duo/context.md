---
stage: AI Platform
group: AI Core Infra
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "Découvrez les informations auxquelles GitLab Duo peut accéder pour fournir des suggestions, et comment exclure du contenu sensible du contexte de la revue de code."
title: Sensibilisation contextuelle de GitLab Duo
---

Différentes informations sont disponibles pour aider GitLab Duo à prendre des décisions et à offrir des suggestions.

Les informations peuvent être disponibles :

- Toujours.
- En fonction de votre emplacement (le contexte change lorsque vous naviguez).
- Lorsqu'elles sont référencées explicitement. Par exemple, vous mentionnez les informations par URL, ID ou chemin de fichier.

## Toujours disponible {#always-available}

- Documentation GitLab.
- Connaissances générales en programmation, meilleures pratiques et spécificités des langages.
- Contenu du fichier que vous consultez ou modifiez, y compris le code avant et après votre curseur.
- Lors de l'utilisation de Chat dans l'interface utilisateur GitLab, le titre et l'URL de la page actuelle.
- Les commandes slash `/refactor`, `/fix`, `/tests` et `/explain` ont accès au dernier rapport Repository X-Ray de Code Suggestions.

## En fonction de l'emplacement {#based-on-location}

Lorsque l'une de ces ressources est ouverte, GitLab Duo en a connaissance.

- Les fichiers que vous avez indiqués à Chat, soit :
  - En fournissant un chemin de fichier direct.
  - Dans votre IDE, notamment avec la commande `/include`.
- Code sélectionné dans un fichier.
- Tickets (GitLab Duo Enterprise uniquement).
- Epics (GitLab Duo Enterprise uniquement).
- [Autres types d'éléments de travail](../work_items/_index.md#work-item-types) (GitLab Duo Enterprise uniquement).

> [!note]
> Dans les IDE, les secrets et les valeurs sensibles correspondant à des formats connus sont expurgés avant d'être envoyés à GitLab Duo Chat.

Dans l'interface utilisateur, lorsque vous êtes dans une merge request, GitLab Duo connaît également :

- La merge request elle-même (GitLab Duo Enterprise uniquement).
- Les commits dans la merge request (GitLab Duo Enterprise uniquement).
- Les jobs CI/CD du pipeline de merge request (GitLab Duo Enterprise uniquement).

### Lorsque référencé explicitement {#when-referenced-explicitly}

Toutes les ressources disponibles en fonction de votre emplacement sont également disponibles lorsque vous y faites référence explicitement par leur ID ou URL.

## Exclure le contexte de la revue de code {#exclude-context-from-code-review}

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Module d'extension : GitLab Duo Pro ou Enterprise

{{< /details >}} {{< history >}}

- [Introduction](https://gitlab.com/groups/gitlab-org/-/work_items/17124) dans GitLab 18.2 [avec un feature flag](../../administration/feature_flags/_index.md) nommé `use_duo_context_exclusion`. Fonctionnalité désactivée par défaut.
- Passé en version bêta dans GitLab 18.4.
- Activé par défaut dans GitLab 18.5.

{{< /history >}}

Vous pouvez exclure le contenu du projet utilisé comme contexte par la revue de code. Excluez le contexte pour protéger les informations sensibles, comme les mots de passe et les fichiers de configuration.

Pour spécifier le contenu que la revue de code exclut :

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à**, puis recherchez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Généralités**.
1. Sous **GitLab Duo**, dans la section **Exclusions du contexte de GitLab Duo**, sélectionnez **Gérer les exclusions**.
1. Spécifiez les fichiers et répertoires du projet exclus du contexte de GitLab Duo, puis sélectionnez **Sauvegarder les exclusions**.
1. Facultatif. Pour supprimer une exclusion existante, sélectionnez **Supprimer** ({{< icon name="remove" >}}) pour l'exclusion appropriée.
1. Sélectionnez **Enregistrer les modifications**.
