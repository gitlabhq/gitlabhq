---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Informations sur le package
---

{{< details >}}

- Niveau : Free, Premium, Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

Le package Linux est fourni avec toutes les dépendances requises pour que GitLab fonctionne correctement. Plus de détails peuvent être trouvés dans le [document sur le regroupement des dépendances](omnibus_packages.md).

## Version du package {#package-version}

Les versions de package publiées sont au format `MAJOR.MINOR.PATCH-EDITION.OMNIBUS_RELEASE`

| Composant           | Signification                                                                                                                                   | Exemple  |
|:--------------------|:------------------------------------------------------------------------------------------------------------------------------------------|:---------|
| `MAJOR.MINOR.PATCH` | La version de GitLab à laquelle cela correspond.                                                                                                   | `13.3.0` |
| `EDITION`           | L'édition de GitLab à laquelle cela correspond.                                                                                                | `ee`     |
| `OMNIBUS_RELEASE`   | La release du package Linux. Généralement, cette valeur est `0`. Nous l'incrémentons si nous devons créer un nouveau package sans modifier la version de GitLab. | `0`      |

## Licences {#licenses}

Voir [les licences](licensing.md)

## Valeurs par défaut {#defaults}

Le package Linux requiert diverses configurations pour que les composants fonctionnent correctement. Si la configuration n'est pas fournie, le package utilise les valeurs par défaut définies dans le package.

Ces valeurs par défaut sont décrites dans le [document sur les valeurs par défaut](defaults.md) du package.

## Vérification des versions des logiciels intégrés {#checking-the-versions-of-bundled-software}

Une fois le package Linux installé, vous pouvez trouver la version de GitLab et de toutes les bibliothèques intégrées dans `/opt/gitlab/version-manifest.txt`.

Si le package n'est pas installé, vous pouvez toujours consulter le [dépôt source](https://gitlab.com/gitlab-org/omnibus-gitlab/tree/master) du package Linux, en particulier le [répertoire de configuration](https://gitlab.com/gitlab-org/omnibus-gitlab/tree/master/config).

Par exemple, si vous examinez la branche `8-6-stable`, vous pouvez conclure que les packages 8.6 exécutaient [Ruby 2.1.8](https://gitlab.com/gitlab-org/omnibus-gitlab/blob/8-6-stable/config/projects/gitlab.rb#L48). Ou que les packages 8.5 étaient fournis avec [NGINX 1.9.0](https://gitlab.com/gitlab-org/omnibus-gitlab/blob/8-5-stable/config/software/nginx.rb#L20).

## Signatures des packages fournis par GitLab, Inc. {#signatures-of-gitlab-inc-provided-packages}

La documentation sur les signatures de packages peut être trouvée dans [Signed Packages](signed_packages.md)

## Recherche de nouvelles options de configuration lors de la mise à niveau {#checking-for-newer-configuration-options-on-upgrade}

Le fichier de configuration `/etc/gitlab/gitlab.rb` est créé lors de l'installation initiale du package Linux. Pour éviter les écrasements accidentels de la configuration utilisateur, le fichier de configuration `/etc/gitlab/gitlab.rb` n'est pas mis à jour avec la nouvelle configuration lors de la mise à niveau de l'installation du package Linux.

Les nouvelles options de configuration sont indiquées dans le [fichier `gitlab.rb.template`](https://gitlab.com/gitlab-org/omnibus-gitlab/raw/master/files/gitlab-config-template/gitlab.rb.template).

Le package Linux fournit également une commande pratique qui compare la configuration utilisateur existante avec la dernière version du modèle contenu dans le package.

Pour afficher un diff entre votre fichier de configuration et la dernière version, exécutez :

```shell
sudo gitlab-ctl diff-config
```

> [!warning]
> Si vous collez la sortie de cette commande dans votre fichier de configuration `/etc/gitlab/gitlab.rb`, omettez tout caractère `+` et `-` en début de chaque ligne.

## Détection du système d'init {#init-system-detection}

Le package Linux tente d'interroger le système sous-jacent pour vérifier quel système d'init il utilise. Cela se manifeste par un `WARNING` lors de l'exécution de `sudo gitlab-ctl reconfigure`.

Selon le système d'init, ce `WARNING` peut être l'un des suivants :

```plaintext
/sbin/init: unrecognized option '--version'
```

lorsque le système d'init sous-jacent n'est pas upstart.

```plaintext
  -.mount loaded active mounted   /
```

lorsque le système d'init sous-jacent est systemd.

Ces avertissements peuvent être ignorés en toute sécurité. Ils ne sont pas supprimés car cela permet à chacun de déboguer plus rapidement les éventuels problèmes de détection.
