# SAML OmniAuth Provider

GitLab can be configured to act as a SAML 2.0 Service Provider (SP). This allows
GitLab to consume assertions from a SAML 2.0 Identity Provider (IdP) such as
Microsoft ADFS to authenticate users.

First configure SAML 2.0 support in GitLab, then register the GitLab application
in your SAML IdP:

1.  Make sure GitLab is configured with HTTPS.
    See [Using HTTPS](../install/installation.md#using-https) for instructions.

1.  On your GitLab server, open the configuration file.

    For omnibus package:

    ```sh
      sudo editor /etc/gitlab/gitlab.rb
    ```

    For installations from source:

    ```sh
      cd /home/git/gitlab

      sudo -u git -H editor config/gitlab.yml
    ```

1.  See [Initial OmniAuth Configuration](omniauth.md#initial-omniauth-configuration)
    for initial settings.

1.  To allow your users to use SAML to sign up without having to manually create
    an account first, don't forget to add the following values to your configuration:

    For omnibus package:

    ```ruby
      gitlab_rails['omniauth_allow_single_sign_on'] = ['saml']
      gitlab_rails['omniauth_block_auto_created_users'] = false
    ```

    For installations from source:

    ```yaml
      allow_single_sign_on: ["saml"]
      block_auto_created_users: false
    ```

1.  You can also automatically link SAML users with existing GitLab users if their
    email addresses match by adding the following setting:

    For omnibus package:

    ```ruby
      gitlab_rails['omniauth_auto_link_saml_user'] = true
    ```

    For installations from source:

    ```yaml
      auto_link_saml_user: true
    ```

1.  Add the provider configuration:

    For omnibus package:

    ```ruby
      gitlab_rails['omniauth_providers'] = [
        {
          name: 'saml',
          args: {
                   assertion_consumer_service_url: 'https://gitlab.example.com/users/auth/saml/callback',
                   idp_cert_fingerprint: '43:51:43:a1:b5:fc:8b:b7:0a:3a:a9:b1:0f:66:73:a8',
                   idp_sso_target_url: 'https://login.example.com/idp',
                   issuer: 'https://gitlab.example.com',
                   name_identifier_format: 'urn:oasis:names:tc:SAML:2.0:nameid-format:persistent'
                 },
          label: 'Company Login' # optional label for SAML login button, defaults to "Saml"
        }
      ]
    ```

    For installations from source:

    ```yaml
      - {
          name: 'saml',
          args: {
                 assertion_consumer_service_url: 'https://gitlab.example.com/users/auth/saml/callback',
                 idp_cert_fingerprint: '43:51:43:a1:b5:fc:8b:b7:0a:3a:a9:b1:0f:66:73:a8',
                 idp_sso_target_url: 'https://login.example.com/idp',
                 issuer: 'https://gitlab.example.com',
                 name_identifier_format: 'urn:oasis:names:tc:SAML:2.0:nameid-format:persistent'
               },
          label: 'Company Login' # optional label for SAML login button, defaults to "Saml"
        }
    ```

1.  Change the value for `assertion_consumer_service_url` to match the HTTPS endpoint
    of GitLab (append `users/auth/saml/callback` to the HTTPS URL of your GitLab
    installation to generate the correct value).

1.  Change the values of `idp_cert_fingerprint`, `idp_sso_target_url`,
    `name_identifier_format` to match your IdP. If a fingerprint is used it must
    be a SHA1 fingerprint; check
    [the omniauth-saml documentation](https://github.com/omniauth/omniauth-saml)
    for more details on these options.

1.  Change the value of `issuer` to a unique name, which will identify the application
    to the IdP.

1.  For the changes to take effect, you must [reconfigure][] GitLab if you installed via Omnibus or [restart GitLab][] if you installed from source.

1.  Register the GitLab SP in your SAML 2.0 IdP, using the application name specified
    in `issuer`.

To ease configuration, most IdP accept a metadata URL for the application to provide
configuration information to the IdP. To build the metadata URL for GitLab, append
`users/auth/saml/metadata` to the HTTPS URL of your GitLab installation, for instance:
   ```
   https://gitlab.example.com/users/auth/saml/metadata
   ```

At a minimum the IdP *must* provide a claim containing the user's email address, using
claim name `email` or `mail`. The email will be used to automatically generate the GitLab
username. GitLab will also use claims with name `name`, `first_name`, `last_name`
(see [the omniauth-saml gem](https://github.com/omniauth/omniauth-saml/blob/master/lib/omniauth/strategies/saml.rb)
for supported claims).

On the sign in page there should now be a SAML button below the regular sign in form.
Click the icon to begin the authentication process. If everything goes well the user
will be returned to GitLab and will be signed in.

## Marking Users as External based on SAML Groups

>**Note:**
This setting is only available on GitLab 8.7 and above.

SAML login includes support for automatically identifying whether a user should
be considered an [external](../user/permissions.md) user based on the user's group
membership in the SAML identity provider. This feature **does not** allow you to
automatically add users to GitLab [Groups](../user/group/index.md), it simply 
allows you to mark users as External if they are members of certain groups in the 
Identity Provider.

### Requirements

First you need to tell GitLab where to look for group information. For this you
need to make sure that your IdP server sends a specific `AttributeStament` along
with the regular SAML response. Here is an example:

```xml
<saml:AttributeStatement>
  <saml:Attribute Name="Groups">
    <saml:AttributeValue xsi:type="xs:string">SecurityGroup</saml:AttributeValue>
    <saml:AttributeValue xsi:type="xs:string">Developers</saml:AttributeValue>
    <saml:AttributeValue xsi:type="xs:string">Designers</saml:AttributeValue>
  </saml:Attribute>
</saml:AttributeStatement>
```

The name of the attribute can be anything you like, but it must contain the groups
to which a user belongs. In order to tell GitLab where to find these groups, you need
to add a `groups_attribute:` element to your SAML settings. You will also need to
tell GitLab which groups are external via the `external_groups:` element:

```yaml
{ name: 'saml',
  label: 'Our SAML Provider',
  groups_attribute: 'Groups',
  external_groups: ['Freelancers', 'Interns'],
  args: {
          assertion_consumer_service_url: 'https://gitlab.example.com/users/auth/saml/callback',
          idp_cert_fingerprint: '43:51:43:a1:b5:fc:8b:b7:0a:3a:a9:b1:0f:66:73:a8',
          idp_sso_target_url: 'https://login.example.com/idp',
          issuer: 'https://gitlab.example.com',
          name_identifier_format: 'urn:oasis:names:tc:SAML:2.0:nameid-format:persistent'
        } }
```

## Customization

### `auto_sign_in_with_provider`

You can add this setting to your GitLab configuration to automatically redirect you
to your SAML server for authentication, thus removing the need to click a button
before actually signing in.

For omnibus package:

```ruby
gitlab_rails['omniauth_auto_sign_in_with_provider'] = 'saml'
```

For installations from source:

```yaml
omniauth:
  auto_sign_in_with_provider: saml
```

Please keep in mind that every sign in attempt will be redirected to the SAML server,
so you will not be able to sign in using local credentials. Make sure that at least one
of the SAML users has admin permissions.

You may also bypass the auto signin feature by browsing to
https://gitlab.example.com/users/sign_in?auto_sign_in=false.

### `attribute_statements`

>**Note:**
This setting is only available on GitLab 8.6 and above.
This setting should only be used to map attributes that are part of the
OmniAuth info hash schema.

`attribute_statements` is used to map Attribute Names in a SAMLResponse to entries
in the OmniAuth [info hash](https://github.com/intridea/omniauth/wiki/Auth-Hash-Schema#schema-10-and-later).

For example, if your SAMLResponse contains an Attribute called 'EmailAddress',
specify `{ email: ['EmailAddress'] }` to map the Attribute to the
corresponding key in the info hash.  URI-named Attributes are also supported, e.g.
`{ email: ['http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress'] }`.

This setting allows you tell GitLab where to look for certain attributes required
to create an account. Like mentioned above, if your IdP sends the user's email
address as `EmailAddress` instead of `email`, let GitLab know by setting it on
your configuration:

```yaml
args: {
        assertion_consumer_service_url: 'https://gitlab.example.com/users/auth/saml/callback',
        idp_cert_fingerprint: '43:51:43:a1:b5:fc:8b:b7:0a:3a:a9:b1:0f:66:73:a8',
        idp_sso_target_url: 'https://login.example.com/idp',
        issuer: 'https://gitlab.example.com',
        name_identifier_format: 'urn:oasis:names:tc:SAML:2.0:nameid-format:persistent',
        attribute_statements: { email: ['EmailAddress'] }
}
```

### `allowed_clock_drift`

The clock of the Identity Provider may drift slightly ahead of your system clocks.
To allow for a small amount of clock drift you can use `allowed_clock_drift` within
your settings. Its value must be given in a number (and/or fraction) of seconds.
The value given is added to the current time at which the response is validated.

```yaml
args: {
        assertion_consumer_service_url: 'https://gitlab.example.com/users/auth/saml/callback',
        idp_cert_fingerprint: '43:51:43:a1:b5:fc:8b:b7:0a:3a:a9:b1:0f:66:73:a8',
        idp_sso_target_url: 'https://login.example.com/idp',
        issuer: 'https://gitlab.example.com',
        name_identifier_format: 'urn:oasis:names:tc:SAML:2.0:nameid-format:persistent',
        attribute_statements: { email: ['EmailAddress'] },
        allowed_clock_drift: 1 # for one second clock drift
}
```

## Troubleshooting

### 500 error after login

If you see a "500 error" in GitLab when you are redirected back from the SAML sign in page,
this likely indicates that GitLab could not get the email address for the SAML user.

Make sure the IdP provides a claim containing the user's email address, using claim name
`email` or `mail`.

### Redirect back to login screen with no evident error

If after signing in into your SAML server you are redirected back to the sign in page and
no error is displayed, check your `production.log` file. It will most likely contain the
message `Can't verify CSRF token authenticity`. This means that there is an error during
the SAML request, but this error never reaches GitLab due to the CSRF check.

To bypass this you can add `skip_before_action :verify_authenticity_token` to the
`omniauth_callbacks_controller.rb` file immediately after the `class` line and
comment out the `protect_from_forgery` line using a `#` then restart Unicorn. This
will allow the error to hit GitLab, where it can then be seen in the usual logs,
or as a flash message on the login screen.

That file is located in `/opt/gitlab/embedded/service/gitlab-rails/app/controllers`
for Omnibus installations and by default in `/home/git/gitlab/app/controllers` for
installations from source. Restart Unicorn using the `sudo gitlab-ctl restart unicorn`
command on Omnibus installations and `sudo service gitlab restart` on installations
from source.

You may also find the [SSO Tracer](https://addons.mozilla.org/en-US/firefox/addon/sso-tracer)
(Firefox) and [SAML Chrome Panel](https://chrome.google.com/webstore/detail/saml-chrome-panel/paijfdbeoenhembfhkhllainmocckace)
(Chrome) browser extensions useful in your debugging.

### Invalid audience

This error means that the IdP doesn't recognize GitLab as a valid sender and
receiver of SAML requests. Make sure to add the GitLab callback URL to the approved
audiences of the IdP server.

### Missing claims

The IdP server needs to pass certain information in order for GitLab to either
create an account, or match the login information to an existing account. `email`
is the minimum amount of information that needs to be passed. If the IdP server
is not providing this information, all SAML requests will fail.

Make sure this information is provided.

### Key validation error, Digest mismatch or Fingerprint mismatch

These errors all come from a similar place, the SAML certificate. SAML requests
need to be validated using a fingerprint, a certificate or a validator.

For this you need take the following into account:

- If a fingerprint is used, it must be the SHA1 fingerprint
- If no certificate is provided in the settings, a fingerprint or fingerprint
  validator needs to be provided and the response from the server must contain
  a certificate (`<ds:KeyInfo><ds:X509Data><ds:X509Certificate>`)
- If a certificate is provided in the settings, it is no longer necessary for
  the request to contain one. In this case the fingerprint or fingerprint
  validators are optional

Make sure that one of the above described scenarios is valid, or the requests will
fail with one of the mentioned errors.

[reconfigure]: ../administration/restart_gitlab.md#omnibus-gitlab-reconfigure
[restart GitLab]: ../administration/restart_gitlab.md#installations-from-source
