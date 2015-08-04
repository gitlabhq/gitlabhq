# SAML OmniAuth Provider

GitLab can be configured to act as a SAML 2.0 Service Provider (SP). This allows GitLab to consume assertions from a SAML 2.0 Identity Provider (IdP) such as Microsoft ADFS to authenticate users. 

First configure SAML 2.0 support in GitLab, then register the GitLab application in your SAML IdP:  

1.  Make sure GitLab is configured with HTTPS. See [Using HTTPS](../install/installation.md#using-https) for instructions.

1.  On your GitLab server, open the configuration file.

    For omnibus package:

    ```sh
      sudo editor /etc/gitlab/gitlab.rb
    ```

    For instalations from source:

    ```sh
      cd /home/git/gitlab

      sudo -u git -H editor config/gitlab.yml
    ```

1.  See [Initial OmniAuth Configuration](omniauth.md#initial-omniauth-configuration) for initial settings.

1.  Add the provider configuration:

    For omnibus package:

    ```ruby
      gitlab_rails['omniauth_providers'] = [
        {
          "name" => "saml",
           args: {
                   assertion_consumer_service_url: 'https://gitlab.example.com/users/auth/saml/callback',
                   idp_cert_fingerprint: '43:51:43:a1:b5:fc:8b:b7:0a:3a:a9:b1:0f:66:73:a8',
                   idp_sso_target_url: 'https://login.example.com/idp',
                   issuer: 'https://gitlab.example.com',
                   name_identifier_format: 'urn:oasis:names:tc:SAML:2.0:nameid-format:transient'
                 }
        }
      ]
    ```

    For installations from source:

    ```yaml
      - { name: 'saml',
           args: {
                   assertion_consumer_service_url: 'https://gitlab.example.com/users/auth/saml/callback',
                   idp_cert_fingerprint: '43:51:43:a1:b5:fc:8b:b7:0a:3a:a9:b1:0f:66:73:a8',
                   idp_sso_target_url: 'https://login.example.com/idp',
                   issuer: 'https://gitlab.example.com',
                   name_identifier_format: 'urn:oasis:names:tc:SAML:2.0:nameid-format:transient'
                 } }
    ```

1.  Change the value for 'assertion_consumer_service_url' to match the HTTPS endpoint of GitLab (append 'users/auth/saml/callback' to the HTTPS URL of your GitLab installation to generate the correct value). 

1.  Change the values of 'idp_cert_fingerprint', 'idp_sso_target_url', 'name_identifier_format' to match your IdP. Check [the omniauth-saml documentation](https://github.com/PracticallyGreen/omniauth-saml) for details on these options.

1.  Change the value of 'issuer' to a unique name, which will identify the application to the IdP.

1.  Restart GitLab for the changes to take effect.

1.  Register the GitLab SP in your SAML 2.0 IdP, using the application name specified in 'issuer'. 

To ease configuration, most IdP accept a metadata URL for the application to provide configuration information to the IdP. To build the metadata URL for GitLab, append 'users/auth/saml/metadata' to the HTTPS URL of your GitLab installation, for instance:
   ```
   https://gitlab.example.com/users/auth/saml/metadata
   ```

At a minimum the IdP *must* provide a claim containing the user's email address, using claim name 'email' or 'mail'. The email will be used to automatically generate the GitLab username. GitLab will also use claims with name 'name', 'first_name', 'last_name' (see [the omniauth-saml gem](https://github.com/PracticallyGreen/omniauth-saml/blob/master/lib/omniauth/strategies/saml.rb) for supported claims).

On the sign in page there should now be a SAML button below the regular sign in form. Click the icon to begin the authentication process. If everything goes well the user will be returned to GitLab and will be signed in.

## Troubleshooting

If you see a "500 error" in GitLab when you are redirected back from the SAML sign in page, this likely indicates that GitLab could not get the email address for the SAML user.

Make sure the IdP provides a claim containing the user's email address, using claim name 'email' or 'mail'. The email will be used to automatically generate the GitLab username.
