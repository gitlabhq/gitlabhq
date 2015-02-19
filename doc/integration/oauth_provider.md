## GitLab as OAuth2 authentication service provider

This document is about using GitLab as an OAuth authentication service provider to sign into other services.
If you want to use other OAuth authentication service providers to sign into GitLab please see the [OAuth2 client documentation](../api/oauth2.md)

OAuth2 provides client applications a 'secure delegated access' to server resources on behalf of a resource owner. Or you can allow users to sign in to your application with their GitLab.com account.
In fact OAuth allows to issue access token to third-party clients by an authorization server, 
with the approval of the resource owner, or end-user. 
Mostly, OAuth2 is using for SSO (Single sign-on). But you can find a lot of different usages for this functionality. 
For example, our feature 'GitLab Importer' is using OAuth protocol to give an access to repositories without sharing user credentials to GitLab.com account. 
Also GitLab.com application can be used for authentication to your GitLab instance if needed [GitLab OmniAuth](gitlab.md).

GitLab has two ways to add new OAuth2 application to an instance, you can add application as regular user and through admin area. So GitLab actually can have an instance-wide and a user-wide applications. There is no defferences between them except the different permission levels.

### Adding application through profile
Go to your profile section 'Application' and press button 'New Application'

![applications](oauth_provider/user_wide_applications.png)

After this you will see application form, where "Name" is arbitrary name, "Redirect URI" is URL in your app where users will be sent after authorization on GitLab.com.

![application_form](oauth_provider/application_form.png)

### Authorized application
Every application you authorized will be shown in your "Authorized application" sections.

![authorized_application](oauth_provider/authorized_application.png)

At any time you can revoke access just clicking button "Revoke"

### OAuth applications in admin area

If you want to create application that does not belong to certain user you can create it from admin area 

![admin_application](oauth_provider/admin_application.png)