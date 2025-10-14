---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Google Secure LDAP
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed

{{< /details >}}

[Google Cloud Identity](https://cloud.google.com/identity/) provides a Secure
LDAP service that can be configured with GitLab for authentication and group sync.

Secure LDAP requires a slightly different configuration than standard LDAP servers.
The steps below cover:

- Configuring the Secure LDAP Client in the Google administrator console.
- Required GitLab configuration.

Secure LDAP is only available on specific Google Workspace editions. For more information, see the [Google Secure LDAP service documentation](https://support.google.com/a/answer/9048516).

## Configuring Google LDAP client

1. Go to <https://admin.google.com/Dashboard> and sign in as a Google Workspace domain administrator.

1. Go to **Apps** > **LDAP** > **Add Client**.

1. Provide an **LDAP client name** and an optional **Description**. Any descriptive
   values are acceptable. For example, the name could be `GitLab` and the
   description could be `GitLab LDAP Client`. Select **Continue**.

   ![Google Workspace window with client details for adding LDAP client.](img/google_secure_ldap_add_step_1_v11_9.png)

1. Set **Access Permission** according to your needs. You must choose either
   `Entire domain (GitLab)` or `Selected organizational units` for both **Verify user
   credentials** and **Read user information**. Select **Add LDAP Client**.

   {{< alert type="note" >}}

   If you plan to use GitLab [LDAP Group Sync](ldap_synchronization.md#group-sync)
   , turn on `Read group information`.

   {{< /alert >}}

   ![Google Workspace window with access permissions for adding LDAP client.](img/google_secure_ldap_add_step_2_v11_9.png)

1. Download the generated certificate. This is required for GitLab to
   communicate with the Google Secure LDAP service. Save the downloaded certificates
   for later use. After downloading, select **Continue to Client Details**.

1. Expand the **Service Status** section and turn the LDAP client `ON for everyone`.
   After selecting **Save**, select the **Service Status** bar again to collapse
   and return to the rest of the settings.

1. Expand the **Authentication** section and choose **Generate New Credentials**.
   Copy/note these credentials for later use. After selecting **Close**, select
   the **Authentication** bar again to collapse and return to the rest of the settings.

Now the Google Secure LDAP Client configuration is finished. The screenshot below
shows an example of the final settings. Continue on to configure GitLab.

![Google Workspace Admin window with configured LDAP settings for GitLab.](img/google_secure_ldap_client_settings_v11_9.png)

## Configuring GitLab

Edit GitLab configuration, inserting the access credentials and certificate
obtained earlier.

The following are the configuration keys that need to be modified using the
values obtained during the LDAP client configuration earlier:

- `bind_dn`: The access credentials username
- `password`: The access credentials password
- `cert`: The `.crt` file text from the downloaded certificate bundle
- `key`: The `.key` file text from the downloaded certificate bundle

For Linux package installations:

1. Edit `/etc/gitlab/gitlab.rb`:

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

1. Save the file and [reconfigure](../../restart_gitlab.md#reconfigure-a-linux-package-installation) GitLab for the changes to take effect.

For self-compiled installations:

1. Edit `config/gitlab.yml`:

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

1. Save the file and [restart](../../restart_gitlab.md#self-compiled-installations) GitLab for the changes to take effect.

## Using encrypted credentials

You can optionally store the `bind_dn` and `password` in a separate encrypted configuration file using the
[same steps as the regular LDAP integration](_index.md#use-encrypted-credentials).
