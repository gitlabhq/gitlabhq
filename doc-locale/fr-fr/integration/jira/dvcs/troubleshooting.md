---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Dépannage du connecteur Jira DVCS
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Lorsque vous utilisez le [connecteur Jira DVCS](_index.md), vous pouvez rencontrer les problèmes suivants.

## Jira ne peut pas accéder au serveur GitLab {#jira-cannot-access-the-gitlab-server}

Si vous remplissez le formulaire **Add New Account**, autorisez l'accès et recevez cette erreur, Jira et GitLab ne peuvent pas se connecter. Aucun autre message d'erreur n'apparaît dans les journaux :

```plaintext
Error obtaining access token. Cannot access https://gitlab.example.com from Jira.
```

## Bogue de jeton de session dans Jira {#session-token-bug-in-jira}

Lorsque vous utilisez GitLab 15.0 ou une version ultérieure avec Jira Server, vous pouvez rencontrer un [bogue de jeton de session dans Jira](https://jira.atlassian.com/browse/JSWSERVER-21389). Ce bogue affecte Jira Server 8.20.8, 8.22.3, 8.22.4, 9.4.6 et 9.4.14.

Pour résoudre ce problème, assurez-vous d'utiliser Jira Server 8.20.11 ou une version ultérieure, ou 9.1.0 ou une version ultérieure.

## Problèmes SSL et TLS {#ssl-and-tls-problems}

Les problèmes liés à SSL et TLS peuvent générer ce message d'erreur :

```plaintext
Error obtaining access token. Cannot access https://gitlab.example.com from Jira.
```

- L'[intégration des tickets Jira](../_index.md) nécessite que GitLab se connecte à Jira. Tout problème TLS résultant d'une autorité de certification privée ou d'un certificat auto-signé est résolu [sur le serveur GitLab](https://docs.gitlab.com/omnibus/settings/ssl/#install-custom-public-certificates), car GitLab est le client TLS.
- Le panneau de développement Jira nécessite que Jira se connecte à GitLab, ce qui fait de Jira le client TLS. Si le certificat de votre serveur GitLab n'est pas émis par une autorité de certification publique, ajoutez le certificat approprié (tel que le certificat racine de votre organisation) au Java Truststore sur Jira Server.

Pour plus d'informations sur la configuration de Jira, consultez la documentation Atlassian et le support Atlassian.

- [Ajoutez un certificat](https://confluence.atlassian.com/kb/how-to-import-a-public-ssl-certificate-into-a-jvm-867025849.html) au truststore.
  - L'approche la plus simple est [`keytool`](https://docs.oracle.com/javase/8/docs/technotes/tools/unix/keytool.html).
  - Ajoutez des racines supplémentaires au Truststore par défaut de Java (`cacerts`) pour permettre à Jira de faire également confiance aux autorités de certification publiques.
  - Si l'intégration cesse de fonctionner après la mise à niveau du runtime Java de Jira, le Truststore `cacerts` a peut-être été remplacé lors de la mise à niveau.
- Résolvez les problèmes de connectivité [jusqu'à la négociation TLS incluse](https://confluence.atlassian.com/kb/unable-to-connect-to-ssl-services-due-to-pkix-path-building-failed-error-779355358.html), à l'aide de la classe Java `SSLPoke`.
- Téléchargez la classe depuis la base de connaissances Atlassian vers un répertoire sur Jira Server, tel que `/tmp`.
- Utilisez le même runtime Java que Jira.
- Transmettez tous les paramètres liés au réseau avec lesquels Jira est appelé, tels que les paramètres de proxy ou un Truststore racine alternatif (`-Djavax.net.ssl.trustStore`) :

```shell
${JAVA_HOME}/bin/java -Djavax.net.ssl.trustStore=/var/atlassian/application-data/jira/cacerts -classpath /tmp SSLPoke gitlab.example.com 443
```

Le message `Successfully connected` indique une négociation TLS réussie.

En cas de problèmes, la bibliothèque Java TLS génère des erreurs que vous pouvez rechercher pour obtenir plus de détails.

## Erreur de portée lors de la connexion à Jira avec DVCS {#scope-error-when-connecting-to-jira-with-dvcs}

```plaintext
The requested scope is invalid, unknown, or malformed.
```

Résolutions potentielles :

1. Vérifiez que l'URL affichée dans le navigateur après la redirection depuis Jira dans la [configuration du connecteur Jira DVCS](https://confluence.atlassian.com/adminjiraserver/linking-gitlab-accounts-1027142272.html#LinkingGitLabaccounts-InJiraagain) inclut `scope=api` dans la chaîne de requête.
1. Si `scope=api` est absent de l'URL, modifiez la [configuration du compte GitLab](https://confluence.atlassian.com/adminjiraserver/linking-gitlab-accounts-1027142272.html#LinkingGitLabaccounts-InGitLab). Vérifiez le champ **Périmètre d'accès** et assurez-vous que la case `api` est cochée.

## Erreur : `410 Gone` {#error-410-gone}

Lorsque vous vous connectez à Jira et synchronisez les dépôts, vous pouvez obtenir une erreur `410 Gone`. Ce problème survient lorsque vous utilisez le connecteur Jira DVCS et que votre intégration est configurée pour utiliser **GitHub Enterprise**.

Pour plus d'informations, consultez le [ticket 340160](https://gitlab.com/gitlab-org/gitlab/-/issues/340160).

## Problèmes de synchronisation {#synchronization-issues}

Si Jira affiche des informations incorrectes, comme des branches supprimées, vous devrez peut-être resynchroniser les informations :

1. Dans Jira, sélectionnez **Jira Administration** > **Applications** > **DVCS accounts**.
1. Pour le compte (groupe ou sous-groupe), sélectionnez **Refresh repositories** dans le menu {{< icon name="ellipsis_h" >}} (points de suspension).
1. Pour chaque projet, à côté de la date de **Dernière activité** :
   - Pour effectuer une resynchronisation partielle, sélectionnez l'icône de synchronisation.
   - Pour effectuer une synchronisation complète, appuyez sur `Shift` et sélectionnez l'icône de synchronisation.

Pour plus d'informations, consultez la [documentation Atlassian](https://support.atlassian.com/jira-cloud-administration/docs/integrate-with-development-tools/).

## Erreur : `Sync Failed` {#error-sync-failed}

Si vous obtenez une erreur `Sync Failed` dans Jira lorsque vous [actualisez les données du dépôt](_index.md#refresh-data-imported-to-jira) pour des projets spécifiques, vérifiez les journaux de votre connecteur Jira DVCS. Recherchez les erreurs qui surviennent lors de l'exécution de requêtes vers des ressources API dans GitLab. Par exemple :

```plaintext
Failed to execute request [https://gitlab.com/api/v4/projects/:id/merge_requests?page=1&per_page=100 GET https://gitlab.com/api/v4/projects/:id/merge_requests?page=1&per_page=100 returned a response status of 403 Forbidden] errors:
{"message":"403 Forbidden"}
```

Si vous obtenez une erreur `403 Forbidden`, ce projet peut avoir certaines [fonctionnalités GitLab désactivées](../../../user/project/settings/_index.md#configure-project-features-and-permissions). Dans l'exemple précédent, la fonctionnalité de merge requests est désactivée.

Pour résoudre le problème, activez la fonctionnalité concernée :

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à** et trouvez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Généralités**.
1. Développez **Visibilité, fonctionnalités du projet, autorisations**.
1. Utilisez les bascules pour activer les fonctionnalités selon vos besoins.

## Trouver les journaux de webhook dans un projet lié à DVCS {#find-webhook-logs-in-a-dvcs-linked-project}

Pour trouver les journaux de webhook dans un projet lié à DVCS :

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à** et trouvez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Webhooks**.
1. Faites défiler jusqu'à **Project hooks**.
1. À côté du journal qui pointe vers votre instance Jira, sélectionnez **Éditer**.
1. Faites défiler jusqu'à **Événements récents**.

Si vous ne trouvez pas les journaux de webhook dans votre projet, vérifiez votre configuration DVCS pour détecter d'éventuels problèmes.
