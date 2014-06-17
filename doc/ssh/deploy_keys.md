# Deploy keys

Deploy keys allow read-only access one or multiple projects with a single SSH key.

This is really useful for cloning repositories to your Continuous Integration (CI) server. By using a deploy keys you don't have to setup a dummy user account.

If you are a project master or owner you can add a deploy key in the project settings under the section Deploy Keys. Press the 'New Deploy Key' button and upload a public ssh key. After this the machine that uses the corresponding private key has read-only access to the project.

You can't add the same deploy key twice with the 'New Deploy Key' option. If you want to add the same key to another project please enable it in the list that says 'Deploy keys from projects available to you'. All the deploy keys of all the projects you have access to are available. This project access can happen through being a direct member of the project or through a group. See `def accessible_deploy_keys` in `app/models/user.rb` for more information.
