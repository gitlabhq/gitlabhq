---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Google Secure LDAP
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

[Google Cloud Identity](https://cloud.google.com/identity/)は、GitLabでの認証やグループ同期に利用できるSecure LDAPサービスを提供しています。

Secure LDAPは、標準のLDAPサーバーとはわずかに異なる設定が必要です。以下の手順について説明します:

- Google管理者コンソールでSecure LDAPクライアントを設定します。
- 必須のGitLab設定。

Secure LDAPは、特定のGoogle Workspaceエディションでのみ利用可能です。詳細については、[Google Secure LDAPサービスのドキュメント](https://support.google.com/a/answer/9048516)を参照してください。

## Google LDAPクライアントの設定 {#configuring-google-ldap-client}

1. <https://admin.google.com/Dashboard>にアクセスし、Google Workspaceドメインの管理者としてサインインします。

1. **Apps**（アプリ） > **LDAP** > **Add Client**（クライアントを追加） に移動します。

1. **LDAP client name**（LDAPクライアント名）とオプションの**説明**を入力します。任意の説明的な値を使用できます。たとえば、名前は`GitLab`、説明は`GitLab LDAP Client`にすることができます。**次に進む**を選択します。

   ![LDAPクライアントを追加するためのクライアント詳細を示すGoogle Workspaceウィンドウ](img/google_secure_ldap_add_step_1_v11_9.png)

1. 必要に応じて**Access Permission**（アクセス許可）を設定します。**Verify user credentials**（ユーザー認証情報の確認）と**Read user information**（ユーザー情報の読み取り）の両方に対して、`Entire domain (GitLab)`または`Selected organizational units`を選択する必要があります。**Add LDAP Client**（LDAPクライアントを追加）を選択します。

   {{< alert type="note" >}}

   GitLabの[LDAPグループ同期](ldap_synchronization.md#group-sync)を使用する場合は、`Read group information`をオンにします。

   {{< /alert >}}

   ![LDAPクライアントを追加するためのアクセス許可を示すGoogle Workspaceウィンドウ](img/google_secure_ldap_add_step_2_v11_9.png)

1. 生成された証明書をダウンロードします。これは、GitLabがGoogle Secure LDAPサービスと通信するために必要です。ダウンロードした証明書を保存して、後で使用できるようにします。ダウンロード後、**Continue to Client Details**（クライアント詳細に進む）を選択します。

1. **Service Status**（サービスステータス）セクションを展開し、LDAPクライアントを`ON for everyone`にします。**保存**を選択した後、**Service Status**（サービスステータス）バーを再度選択して折りたたみ、残りの設定に戻ります。

1. **認証**セクションを展開し、**Generate New Credentials**（新しい認証情報を生成）を選択します。これらの認証情報をコピー/メモして、後で使用できるようにします。**閉じる**を選択した後、**認証**バーを再度選択して折りたたみ、残りの設定に戻ります。

これで、Google Secure LDAPクライアントの設定が完了しました。以下のスクリーンショットは、最終的な設定の例を示しています。次に、GitLabを設定します。

![GitLab用に設定されたLDAP設定を示すGoogle Workspace管理者ウィンドウ](img/google_secure_ldap_client_settings_v11_9.png)

## GitLabの設定 {#configuring-gitlab}

以前に取得したアクセス認証情報と証明書を挿入して、GitLabの設定を編集します。

以下は、以前のLDAPクライアントの設定で取得した値を使用して変更する必要がある設定キーです:

- `bind_dn`: アクセス認証情報のユーザー名
- `password`: アクセス認証情報のパスワード
- `cert`: ダウンロードした証明書バンドルの`.crt`ファイルテキスト
- `key`: ダウンロードした証明書バンドルの`.key`ファイルテキスト

Linuxパッケージインストールの場合:

1. `/etc/gitlab/gitlab.rb`を編集します:

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

1. ファイルを保存して、変更を有効にするには、GitLabを[再設定](../../restart_gitlab.md#reconfigure-a-linux-package-installation)してください。

自己コンパイルによるインストールの場合: 

1. `config/gitlab.yml`を編集します:

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

1. ファイルを保存して、変更を有効にするには、GitLabを[再起動](../../restart_gitlab.md#self-compiled-installations)してください。

## 暗号化された認証情報を使用する {#using-encrypted-credentials}

オプションで、`bind_dn`と`password`を、[通常のLDAPインテグレーションと同じ手順](_index.md#use-encrypted-credentials)で、別の暗号化された設定ファイルに保存できます。
