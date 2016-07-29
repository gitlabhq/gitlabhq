# Email from GitLab

As a GitLab administrator you can email GitLab users from within GitLab.

In the administrator interface, go to `Users`. Here you will find the button to email users:

![admin users](email1.png)

Here you can simply compose an email.

![compose an email](email2.png)

Which will be sent to all users or users of a chosen group or project.

![recipients](email3.png)

## Note
User can choose to unsubscribe from receiving emails from GitLab by following the unsubscribe link from the email.
Unsubscribing is unauthenticated in order to keep the simplicity of this feature.

On unsubscribe, user will receive an email notifying that unsubscribe happened.
Endpoint that provides unsubscribe option is protected by request being rate-limited.
