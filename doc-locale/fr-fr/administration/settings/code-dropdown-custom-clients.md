---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Clients Git personnalisés dans la liste déroulante Code
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed
- Statut : version bêta

{{< /details >}}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/604390) dans GitLab 19.5 [avec un flag](../feature_flags/_index.md) nommé `custom_code_dropdown_clients`. Fonctionnalité désactivée par défaut.

{{< /history >}}

> [!flag]
> La disponibilité de cette fonctionnalité est contrôlée par un feature flag. Pour plus d'informations, consultez l'historique.

Ajoutez des clients personnalisés à la section **Ouvrir avec** de la liste déroulante **Code** sur les pages de projet. Les utilisateurs peuvent ainsi cloner un dépôt directement dans un client Git que GitLab ne répertorie pas par défaut.

## Configurer des clients personnalisés {#configure-custom-clients}

Prérequis :

- Vous devez être administrateur.
- Le feature flag `custom_code_dropdown_clients` doit être activé.

Pour configurer des entrées :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Sélectionnez **Paramètres** > **Dépôt**.
1. Développez **Général**.
1. Sélectionnez **Ajouter un client**.
1. Remplissez les champs. Saisissez au moins un modèle d'URL.
   - **Nom affiché** : le label affiché aux utilisateurs dans la liste déroulante. Non traduit.
   - **Modèle d'URL SSH** : L'URL ouverte lorsqu'un utilisateur sélectionne **SSH**.
   - **Modèle d'URL HTTPS** : L'URL ouverte lorsqu'un utilisateur sélectionne **HTTPS**.
1. Sélectionnez **Ajouter**.

Pour modifier une entrée, sélectionnez **Modifier le client** ({{< icon name="pencil" >}}) à côté de celle-ci, mettez à jour les champs, puis sélectionnez **Sauvegarder**.

Pour supprimer une entrée, sélectionnez **Supprimer le client** ({{< icon name="remove" >}}) à côté de celle-ci, puis dans la boîte de dialogue de confirmation, sélectionnez **Supprimer le client**.

Vous pouvez configurer jusqu'à 20 entrées.

## Modèles d'URL {#url-templates}

Chaque modèle d'URL doit contenir exactement une fois le paramètre fictif `{url}`. Lorsque la liste déroulante Code est affichée, GitLab remplace le paramètre fictif côté serveur par l'URL de clonage encodée en pourcentage du projet.

### Schémas d'URL autorisés {#allowed-url-schemes}

Saisissez le schéma attendu par le client que vous intégrez. Tout schéma d'URL est accepté, à l'exception des suivants, qu'un navigateur peut utiliser pour exécuter des scripts ou lire des fichiers locaux :

- `javascript`
- `data`
- `vbscript`
- `file`
- `blob`
- `filesystem`
- `about`

La sélection d'une entrée transmet l'URL à l'application que le système d'exploitation de l'utilisateur a enregistrée pour ce schéma.

> [!note]
> GitLab ne peut pas vérifier ce que cette application fait avec l'URL. N'ajoutez que des clients auxquels vous faites confiance.

Si aucune application n'est enregistrée pour le schéma sur le système d'exploitation de l'utilisateur, le navigateur ne peut pas ouvrir le lien.

### Exemples {#examples}

Les entrées suivantes ont été vérifiées par rapport à la documentation des fournisseurs.

Vérifiez toujours le schéma URI actuel dans la documentation officielle du client que vous intégrez, avant de publier l'entrée auprès de vos utilisateurs.

| Nom affiché | Modèle d'URL SSH | Modèle d'URL HTTPS | Source |
|---|---|---|---|
| VSCodium | `vscodium://vscode.git/clone?url={url}` | `vscodium://vscode.git/clone?url={url}` | [VSCodium prepare_vscode.sh](https://github.com/VSCodium/vscodium/blob/master/prepare_vscode.sh) enregistre `urlProtocol` en tant que `vscodium`, en réutilisant le gestionnaire `vscode.git/clone` de VS Code en amont. |
| Tower | `gittower://openRepo/{url}` | `gittower://openRepo/{url}` | [Documentation Tower (macOS)](https://www.git-tower.com/help/guides/integration/url-scheme/mac), [Documentation Tower (Windows)](https://www.git-tower.com/help/guides/integration/url-scheme/windows) |
| Sourcetree, Fork | `sourcetree://cloneRepo?cloneUrl={url}` | `sourcetree://cloneRepo?cloneUrl={url}` | Fork intercepte le même schéma. |

Certains clients ne sont pas compatibles avec le modèle à paramètre fictif unique `{url}`. Par exemple, GitKraken et GitHub Desktop nécessitent des paramètres supplémentaires par dépôt. D'autres clients (tels que Zed et Working Copy) apparaissent dans des documentations tierces, mais ne disposent pas d'une référence officielle de schéma URI fournisseur. Vérifiez auprès du fournisseur avant d'ajouter de telles entrées.
