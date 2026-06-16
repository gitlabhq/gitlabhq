---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Google Secure LDAP
---

{{< details >}}

- Niveau : Free, Premium, Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

[Google Cloud Identity](https://cloud.google.com/identity/) fournit un service LDAP sécurisé qui peut être configuré avec GitLab pour l'authentification et la synchronisation des groupes.

Le LDAP sécurisé nécessite une configuration légèrement différente de celle des serveurs LDAP standard. Les étapes ci-dessous couvrent :

- Configuration du client LDAP sécurisé dans la console d'administration Google.
- Configuration requise pour GitLab.

Le LDAP sécurisé n'est disponible que sur certaines éditions de Google Workspace. Pour plus d'informations, consultez la [documentation du service Google Secure LDAP](https://support.google.com/a/answer/9048516).

## Configuration du client Google LDAP {#configuring-google-ldap-client}

1. Accédez à <https://admin.google.com/Dashboard> et connectez-vous en tant qu'administrateur de domaine Google Workspace.
1. Accédez à **Apps** > **LDAP** > **Add Client**.
1. Fournissez un **LDAP client name** et une **Description** facultative. Toute valeur descriptive est acceptable. Par exemple, le nom pourrait être `GitLab` et la description pourrait être `GitLab LDAP Client`. Sélectionnez **Continuer**.

   ![Fenêtre Google Workspace avec les détails du client pour l'ajout d'un client LDAP.](img/google_secure_ldap_add_step_1_v11_9.png)

1. Définissez **Access Permission** selon vos besoins. Vous devez choisir soit `Entire domain (GitLab)` soit `Selected organizational units` pour **Verify user credentials** et **Read user information**. Sélectionnez **Add LDAP Client**.

   > [!note]
   > Si vous prévoyez d'utiliser la [synchronisation des groupes LDAP](ldap_synchronization.md#group-sync) de GitLab, activez `Read group information`.

   ![Fenêtre Google Workspace avec les autorisations d'accès pour l'ajout d'un client LDAP.](img/google_secure_ldap_add_step_2_v11_9.png)

1. Téléchargez le certificat généré. Ceci est requis pour que GitLab puisse communiquer avec le service Google Secure LDAP. Enregistrez les certificats téléchargés pour une utilisation ultérieure. Après le téléchargement, sélectionnez **Continue to Client Details**.

1. Développez la section **Service Status** et activez le client LDAP `ON for everyone`. Après avoir sélectionné **Enregistrer**, sélectionnez à nouveau la barre **Service Status** pour la réduire et revenir au reste des paramètres.

1. Développez la section **Authentification** et choisissez **Generate New Credentials**. Copiez/notez ces identifiants pour une utilisation ultérieure. Après avoir sélectionné **Fermer**, sélectionnez à nouveau la barre **Authentification** pour la réduire et revenir au reste des paramètres.

La configuration du client Google Secure LDAP est maintenant terminée. La capture d'écran ci-dessous montre un exemple des paramètres finaux. Continuez pour configurer GitLab.

![Fenêtre d'administration Google Workspace avec les paramètres LDAP configurés pour GitLab.](img/google_secure_ldap_client_settings_v11_9.png)

## Configuration de GitLab {#configuring-gitlab}

Modifiez la configuration de GitLab en y insérant les identifiants d'accès et le certificat obtenus précédemment.

Voici les clés de configuration qui doivent être modifiées à l'aide des valeurs obtenues lors de la configuration du client LDAP précédemment :

- `bind_dn` :  Le nom d'utilisateur des identifiants d'accès
- `password` :  Le mot de passe des identifiants d'accès
- `cert` :  Le texte du fichier `.crt` du bundle de certificats téléchargé
- `key` :  Le texte du fichier `.key` du bundle de certificats téléchargé

Pour les installations avec le package Linux :

1. Modifiez `/etc/gitlab/gitlab.rb` :

   ```ruby
   gitlab_rails['ldap_enabled'] = true
   gitlab_rails['ldap_servers'] = YAML.load <<-EOS # remember to close this block with 'EOS' below
     main: # 'main' is the GitLab 'provider ID' of this LDAP server
       label: 'Google Secure LDAP'

       host: 'ldap.google.com'
       port: 636
       uid: 'uid'
       bind_dn: 'DizzyHorse'
       password: 'd6V5H8nhMUW9AuDP25abXeLd'
       encryption: 'simple_tls'
       verify_certificates: true
       retry_empty_result_with_codes: [80]
       base: "DC=example,DC=com"
       tls_options:
         cert: |
           -----BEGIN CERTIFICATE-----
           MIIDbDCCAlSgAwIBAgIGAWlzxiIfMA0GCSqGSIb3DQEBCwUAMHcxFDASBgNVBAoTC0dvb2dsZSBJ
           bmMuMRYwFAYDVQQHEw1Nb3VudGFpbiBWaWV3MRQwEgYDVQQDEwtMREFQIENsaWVudDEPMA0GA1UE
           CxMGR1N1aXRlMQswCQYDVQQGEwJVUzETMBEGA1UECBMKQ2FsaWZvcm5pYTAeFw0xOTAzMTIyMTE5
           MThaFw0yMjAzMTEyMTE5MThaMHcxFDASBgNVBAoTC0dvb2dsZSBJbmMuMRYwFAYDVQQHEw1Nb3Vu
           dGFpbiBWaWV3MRQwEgYDVQQDEwtMREFQIENsaWVudDEPMA0GA1UECxMGR1N1aXRlMQswCQYDVQQG
           EwJVUzETMBEGA1UECBMKQ2FsaWZvcm5pYTCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEB
           ALOTy4aC38dyjESk6N8fRsKk8DN23ZX/GaNFL5OUmmA1KWzrvVC881OzNdtGm3vNOIxr9clteEG/
           tQwsmsJvQT5U+GkBt+tGKF/zm7zueHUYqTP7Pg5pxAnAei90qkIRFi17ulObyRHPYv1BbCt8pxNB
           4fG/gAXkFbCNxwh1eiQXXRTfruasCZ4/mHfX7MVm8JmWU9uAVIOLW+DSWOFhrDQduJdGBXJOyC2r
           Gqoeg9+tkBmNH/jjxpnEkFW8q7io9DdOUqqNgoidA1h9vpKTs3084sy2DOgUvKN9uXWx14uxIyYU
           Y1DnDy0wczcsuRt7l+EgtCEgpsLiLJQbKW+JS1UCAwEAATANBgkqhkiG9w0BAQsFAAOCAQEAf60J
           yazhbHkDKIH2gFxfm7QLhhnqsmafvl4WP7JqZt0u0KdnvbDPfokdkM87yfbKJU1MTI86M36wEC+1
           P6bzklKz7kXbzAD4GggksAzxsEE64OWHC+Y64Tkxq2NiZTw/76POkcg9StiIXjG0ZcebHub9+Ux/
           rTncip92nDuvgEM7lbPFKRIS/YMhLCk09B/U0F6XLsf1yYjyf5miUTDikPkov23b/YGfpc8kh6hq
           1kqdi6a1cYPP34eAhtRhMqcZU9qezpJF6s9EeN/3YFfKzLODFSsVToBRAdZgGHzj//SAtLyQTD4n
           KCSvK1UmaMxNaZyTHg8JnMf0ZuRpv26iSg==
           -----END CERTIFICATE-----

         key: |
           -----BEGIN PRIVATE KEY-----
           MIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQCzk8uGgt/HcoxEpOjfH0bCpPAz
           dt2V/xmjRS+TlJpgNSls671QvPNTszXbRpt7zTiMa/XJbXhBv7UMLJrCb0E+VPhpAbfrRihf85u8
           7nh1GKkz+z4OacQJwHovdKpCERYte7pTm8kRz2L9QWwrfKcTQeHxv4AF5BWwjccIdXokF10U367m
           rAmeP5h31+zFZvCZllPbgFSDi1vg0ljhYaw0HbiXRgVyTsgtqxqqHoPfrZAZjR/448aZxJBVvKu4
           qPQ3TlKqjYKInQNYfb6Sk7N9POLMtgzoFLyjfbl1sdeLsSMmFGNQ5w8tMHM3LLkbe5fhILQhIKbC
           4iyUGylviUtVAgMBAAECggEAIPb0CQy0RJoX+q/lGbRVmnyJpYDf+115WNnl+mrwjdGkeZyqw4v0
           BPzkWYzUFP1esJRO6buBNFybQRFdFW0z5lvVv/zzRKq71aVUBPInxaMRyHuJ8D5lIL8nDtgVOwyE
           7DOGyDtURUMzMjdUwoTe7K+O6QBU4X/1pVPZYgmissYSMmt68LiP8k0p601F4+r5xOi/QEy44aVp
           aOJZBUOisKB8BmUXZqmQ4Cy05vU9Xi1rLyzkn9s7fxnZ+JO6Sd1r0Thm1mE0yuPgxkDBh/b4f3/2
           GsQNKKKCiij/6TfkjnBi8ZvWR44LnKpu760g/K7psVNrKwqJG6C/8RAcgISWQQKBgQDop7BaKGhK
           1QMJJ/vnlyYFTucfGLn6bM//pzTys5Gop0tpcfX/Hf6a6Dd+zBhmC3tBmhr80XOX/PiyAIbc0lOI
           31rafZuD/oVx5mlIySWX35EqS14LXmdVs/5vOhsInNgNiE+EPFf1L9YZgG/zA7OUBmqtTeYIPDVC
           7ViJcydItQKBgQDFmK0H0IA6W4opGQo+zQKhefooqZ+RDk9IIZMPOAtnvOM7y3rSVrfsSjzYVuMS
           w/RP/vs7rwhaZejnCZ8/7uIqwg4sdUBRzZYR3PRNFeheW+BPZvb+2keRCGzOs7xkbF1mu54qtYTa
           HZGZj1OsD83AoMwVLcdLDgO1kw32dkS8IQKBgFRdgoifAHqqVah7VFB9se7Y1tyi5cXWsXI+Wufr
           j9U9nQ4GojK52LqpnH4hWnOelDqMvF6TQTyLIk/B+yWWK26Ft/dk9wDdSdystd8L+dLh4k0Y+Whb
           +lLMq2YABw+PeJUnqdYE38xsZVHoDjBsVjFGRmbDybeQxauYT7PACy3FAoGBAK2+k9bdNQMbXp7I
           j8OszHVkJdz/WXlY1cmdDAxDwXOUGVKIlxTAf7TbiijILZ5gg0Cb+hj+zR9/oI0WXtr+mAv02jWp
           W8cSOLS4TnBBpTLjIpdu+BwbnvYeLF6MmEjNKEufCXKQbaLEgTQ/XNlchBSuzwSIXkbWqdhM1+gx
           EjtBAoGARAdMIiDMPWIIZg3nNnFebbmtBP0qiBsYohQZ+6i/8s/vautEHBEN6Q0brIU/goo+nTHc
           t9VaOkzjCmAJSLPUanuBC8pdYgLu5J20NXUZLD9AE/2bBT3OpezKcdYeI2jqoc1qlWHlNtVtdqQ2
           AcZSFJQjdg5BTyvdEDhaYUKGdRw=
           -----END PRIVATE KEY-----
   EOS
   ```

1. Enregistrez le fichier et [reconfigurez](../../restart_gitlab.md#reconfigure-a-linux-package-installation) GitLab pour que les modifications prennent effet.

Pour les installations auto-compilées :

1. Modifiez `config/gitlab.yml` :

   ```yaml
   ldap:
     enabled: true
     servers:
       main: # 'main' is the GitLab 'provider ID' of this LDAP server
         label: 'Google Secure LDAP'
         base: "DC=example,DC=com"
         host: 'ldap.google.com'
         port: 636
         uid: 'uid'
         bind_dn: 'DizzyHorse'
         password: 'd6V5H8nhMUW9AuDP25abXeLd'
         encryption: 'simple_tls'
         verify_certificates: true
         retry_empty_result_with_codes: [80]

         tls_options:
           cert: |
             -----BEGIN CERTIFICATE-----
             MIIDbDCCAlSgAwIBAgIGAWlzxiIfMA0GCSqGSIb3DQEBCwUAMHcxFDASBgNVBAoTC0dvb2dsZSBJ
             bmMuMRYwFAYDVQQHEw1Nb3VudGFpbiBWaWV3MRQwEgYDVQQDEwtMREFQIENsaWVudDEPMA0GA1UE
             CxMGR1N1aXRlMQswCQYDVQQGEwJVUzETMBEGA1UECBMKQ2FsaWZvcm5pYTAeFw0xOTAzMTIyMTE5
             MThaFw0yMjAzMTEyMTE5MThaMHcxFDASBgNVBAoTC0dvb2dsZSBJbmMuMRYwFAYDVQQHEw1Nb3Vu
             dGFpbiBWaWV3MRQwEgYDVQQDEwtMREFQIENsaWVudDEPMA0GA1UECxMGR1N1aXRlMQswCQYDVQQG
             EwJVUzETMBEGA1UECBMKQ2FsaWZvcm5pYTCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEB
             ALOTy4aC38dyjESk6N8fRsKk8DN23ZX/GaNFL5OUmmA1KWzrvVC881OzNdtGm3vNOIxr9clteEG/
             tQwsmsJvQT5U+GkBt+tGKF/zm7zueHUYqTP7Pg5pxAnAei90qkIRFi17ulObyRHPYv1BbCt8pxNB
             4fG/gAXkFbCNxwh1eiQXXRTfruasCZ4/mHfX7MVm8JmWU9uAVIOLW+DSWOFhrDQduJdGBXJOyC2r
             Gqoeg9+tkBmNH/jjxpnEkFW8q7io9DdOUqqNgoidA1h9vpKTs3084sy2DOgUvKN9uXWx14uxIyYU
             Y1DnDy0wczcsuRt7l+EgtCEgpsLiLJQbKW+JS1UCAwEAATANBgkqhkiG9w0BAQsFAAOCAQEAf60J
             yazhbHkDKIH2gFxfm7QLhhnqsmafvl4WP7JqZt0u0KdnvbDPfokdkM87yfbKJU1MTI86M36wEC+1
             P6bzklKz7kXbzAD4GggksAzxsEE64OWHC+Y64Tkxq2NiZTw/76POkcg9StiIXjG0ZcebHub9+Ux/
             rTncip92nDuvgEM7lbPFKRIS/YMhLCk09B/U0F6XLsf1yYjyf5miUTDikPkov23b/YGfpc8kh6hq
             1kqdi6a1cYPP34eAhtRhMqcZU9qezpJF6s9EeN/3YFfKzLODFSsVToBRAdZgGHzj//SAtLyQTD4n
             KCSvK1UmaMxNaZyTHg8JnMf0ZuRpv26iSg==
             -----END CERTIFICATE-----

           key: |
             -----BEGIN PRIVATE KEY-----
             MIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQCzk8uGgt/HcoxEpOjfH0bCpPAz
             dt2V/xmjRS+TlJpgNSls671QvPNTszXbRpt7zTiMa/XJbXhBv7UMLJrCb0E+VPhpAbfrRihf85u8
             7nh1GKkz+z4OacQJwHovdKpCERYte7pTm8kRz2L9QWwrfKcTQeHxv4AF5BWwjccIdXokF10U367m
             rAmeP5h31+zFZvCZllPbgFSDi1vg0ljhYaw0HbiXRgVyTsgtqxqqHoPfrZAZjR/448aZxJBVvKu4
             qPQ3TlKqjYKInQNYfb6Sk7N9POLMtgzoFLyjfbl1sdeLsSMmFGNQ5w8tMHM3LLkbe5fhILQhIKbC
             4iyUGylviUtVAgMBAAECggEAIPb0CQy0RJoX+q/lGbRVmnyJpYDf+115WNnl+mrwjdGkeZyqw4v0
             BPzkWYzUFP1esJRO6buBNFybQRFdFW0z5lvVv/zzRKq71aVUBPInxaMRyHuJ8D5lIL8nDtgVOwyE
             7DOGyDtURUMzMjdUwoTe7K+O6QBU4X/1pVPZYgmissYSMmt68LiP8k0p601F4+r5xOi/QEy44aVp
             aOJZBUOisKB8BmUXZqmQ4Cy05vU9Xi1rLyzkn9s7fxnZ+JO6Sd1r0Thm1mE0yuPgxkDBh/b4f3/2
             GsQNKKKCiij/6TfkjnBi8ZvWR44LnKpu760g/K7psVNrKwqJG6C/8RAcgISWQQKBgQDop7BaKGhK
             1QMJJ/vnlyYFTucfGLn6bM//pzTys5Gop0tpcfX/Hf6a6Dd+zBhmC3tBmhr80XOX/PiyAIbc0lOI
             31rafZuD/oVx5mlIySWX35EqS14LXmdVs/5vOhsInNgNiE+EPFf1L9YZgG/zA7OUBmqtTeYIPDVC
             7ViJcydItQKBgQDFmK0H0IA6W4opGQo+zQKhefooqZ+RDk9IIZMPOAtnvOM7y3rSVrfsSjzYVuMS
             w/RP/vs7rwhaZejnCZ8/7uIqwg4sdUBRzZYR3PRNFeheW+BPZvb+2keRCGzOs7xkbF1mu54qtYTa
             HZGZj1OsD83AoMwVLcdLDgO1kw32dkS8IQKBgFRdgoifAHqqVah7VFB9se7Y1tyi5cXWsXI+Wufr
             j9U9nQ4GojK52LqpnH4hWnOelDqMvF6TQTyLIk/B+yWWK26Ft/dk9wDdSdystd8L+dLh4k0Y+Whb
             +lLMq2YABw+PeJUnqdYE38xsZVHoDjBsVjFGRmbDybeQxauYT7PACy3FAoGBAK2+k9bdNQMbXp7I
             j8OszHVkJdz/WXlY1cmdDAxDwXOUGVKIlxTAf7TbiijILZ5gg0Cb+hj+zR9/oI0WXtr+mAv02jWp
             W8cSOLS4TnBBpTLjIpdu+BwbnvYeLF6MmEjNKEufCXKQbaLEgTQ/XNlchBSuzwSIXkbWqdhM1+gx
             EjtBAoGARAdMIiDMPWIIZg3nNnFebbmtBP0qiBsYohQZ+6i/8s/vautEHBEN6Q0brIU/goo+nTHc
             t9VaOkzjCmAJSLPUanuBC8pdYgLu5J20NXUZLD9AE/2bBT3OpezKcdYeI2jqoc1qlWHlNtVtdqQ2
             AcZSFJQjdg5BTyvdEDhaYUKGdRw=
             -----END PRIVATE KEY-----
   ```

1. Enregistrez le fichier et [redémarrez](../../restart_gitlab.md#self-compiled-installations) GitLab pour que les modifications prennent effet.

## Utilisation des identifiants chiffrés {#using-encrypted-credentials}

Vous pouvez éventuellement stocker `bind_dn` et `password` dans un fichier de configuration chiffré séparé en utilisant les [mêmes étapes que pour l'intégration LDAP standard](_index.md#use-encrypted-credentials).
