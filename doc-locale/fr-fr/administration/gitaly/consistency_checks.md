---
stage: Tenant Scale
group: Gitaly
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Vérifications de cohérence des dépôts
---

Gitaly exécute des vérifications de cohérence des dépôts :

- Lors du déclenchement d'une vérification de dépôt.
- Lorsque des modifications sont récupérées depuis un dépôt miroir.
- Lorsque des utilisateurs poussent des modifications dans le dépôt.

Ces vérifications de cohérence permettent de s'assurer qu'un dépôt contient tous les objets requis et que ces objets sont valides. Elles peuvent être classées comme suit :

- Les vérifications de base qui s'assurent qu'un dépôt ne devient pas corrompu. Cela inclut les vérifications de connectivité et les vérifications que les objets peuvent être analysés.
- Les vérifications de sécurité qui identifient les objets susceptibles d'exploiter d'anciens bogues liés à la sécurité dans Git.
- Les vérifications cosmétiques qui vérifient que toutes les métadonnées d'objet sont valides. Les anciennes versions de Git et d'autres implémentations Git peuvent avoir produit des objets avec des métadonnées invalides, mais les versions plus récentes peuvent interpréter ces objets malformés.

La suppression d'objets malformés qui échouent aux vérifications de cohérence nécessite une réécriture de l'historique du dépôt, ce qui n'est souvent pas possible. Par conséquent, Gitaly [désactive par défaut les vérifications de cohérence pour un ensemble de problèmes cosmétiques](#disabled-checks) qui n'ont pas d'impact négatif sur la cohérence du dépôt.

Par défaut, Gitaly ne désactive pas les vérifications de base ou liées à la sécurité afin de ne pas distribuer des objets pouvant déclencher des vulnérabilités connues dans les clients Git. Cela limite également la possibilité d'importer des dépôts contenant de tels objets, même si le projet n'a pas d'intention malveillante.

## Remplacer les vérifications de cohérence des dépôts {#override-repository-consistency-checks}

Les administrateurs d'instance peuvent remplacer les vérifications de cohérence s'ils doivent traiter des dépôts qui ne passent pas les vérifications de cohérence.

Pour les installations de paquets Linux, modifiez `/etc/gitlab/gitlab.rb` et définissez les clés suivantes (dans cet exemple, pour autoriser les en-têtes d'e-mail incorrects dans les anciens commits, et désactiver les vérifications de cohérence `hasDotgit` et `gitmodulesUrl`) :

```ruby
ignored_blobs = "/etc/gitlab/instance_wide_ignored_git_blobs.txt"

gitaly['configuration'] = {
  # ...
  git: {
    # ...
    config: [
      # Allow bad email headers in old commits
      # (Populate a file with one unabbreviated SHA-1 per line.
      #  See https://git-scm.com/docs/git-config#Documentation/git-config.txt-fsckskipList)
      { key: "fsck.skipList", value: ignored_blobs },
      { key: "fetch.fsck.skipList", value: ignored_blobs },
      { key: "receive.fsck.skipList", value: ignored_blobs },
      { key: "fsck.missingSpaceBeforeEmail", value: "ignore" },

      # Ignore specific consistency checks
      # See https://git-scm.com/docs/git-fsck.html#_fsck_messages
      { key: "fsck.hasDotgit", value: "ignore" },
      { key: "fetch.fsck.hasDotgit", value: "ignore" },
      { key: "receive.fsck.hasDotgit", value: "ignore" },
      { key: "fsck.gitmodulesUrl", value: "ignore" },
      { key: "fetch.fsck.gitmodulesUrl", value: "ignore" },
    ],
  },
}
```

Pour les installations compilées manuellement, modifiez la configuration Gitaly (`gitaly.toml`) pour faire l'équivalent :

```toml
[[git.config]]
key = "fsck.hasDotgit"
value = "ignore"

[[git.config]]
key = "fetch.fsck.hasDotgit"
value = "ignore"

[[git.config]]
key = "receive.fsck.hasDotgit"
value = "ignore"

[[git.config]]
key = "fsck.missingSpaceBeforeEmail"
value = "ignore"

[[git.config]]
key = "fetch.fsck.missingSpaceBeforeEmail"
value = "ignore"

[[git.config]]
key = "receive.fsck.missingSpaceBeforeEmail"
value = "ignore"

[[git.config]]
key = "fsck.gitmodulesUrl"
value = "ignore"

[[git.config]]
key = "fetch.fsck.gitmodulesUrl"
value = "ignore"

[[git.config]]
key = "fsck.skipList"
value = "/etc/gitlab/instance_wide_ignored_git_blobs.txt"

[[git.config]]
key = "fetch.fsck.skipList"
value = "/etc/gitlab/instance_wide_ignored_git_blobs.txt"

[[git.config]]
key = "receive.fsck.skipList"
value = "/etc/gitlab/instance_wide_ignored_git_blobs.txt"
```

## Vérifications désactivées {#disabled-checks}

Afin que Gitaly puisse continuer à fonctionner avec des dépôts présentant certaines caractéristiques malformées qui n'ont pas d'impact sur la sécurité ou les clients Gitaly, Gitaly désactive par défaut un [sous-ensemble de vérifications cosmétiques](https://gitlab.com/gitlab-org/gitaly/-/blob/79643229c351d39a7b16d90b6023ebe5f8108c16/internal/git/command_description.go#L483-524).

Pour la liste complète des vérifications de cohérence, consultez la [documentation Git](https://git-scm.com/docs/git-fsck#_fsck_messages).

### `badTimezone` {#badtimezone}

La vérification `badTimezone` est désactivée car il existait un bogue dans Git qui amenait les utilisateurs à créer des commits avec des fuseaux horaires invalides. Par conséquent, certains journaux Git contiennent des commits qui ne correspondent pas à la spécification. Étant donné que Gitaly exécute `fsck` sur les `packfiles` reçus par défaut, tout push contenant de tels commits serait rejeté.

### `missingSpaceBeforeDate` {#missingspacebeforedate}

La vérification `missingSpaceBeforeDate` est désactivée car `git-fsck(1)` échoue lorsqu'une signature ne comporte pas d'espace entre le courrier et la date, ou lorsque la date est complètement absente. Cela peut être causé par diverses raisons, notamment des clients Git défaillants.

### `zeroPaddedFilemode` {#zeropaddedfilemode}

La vérification `zeroPaddedFilemode` est désactivée car les anciennes versions de Git avaient l'habitude de compléter avec des zéros certains modes de fichier. Par exemple, au lieu d'un mode de fichier `40000`, l'objet arbre aurait encodé le mode de fichier comme `040000`.
