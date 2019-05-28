# Restrict allowed SSH key technologies and minimum length

`ssh-keygen` allows users to create RSA keys with as few as 768 bits, which
falls well below recommendations from certain standards groups (such as the US
NIST). Some organizations deploying GitLab will need to enforce minimum key
strength, either to satisfy internal security policy or for regulatory
compliance.

Similarly, certain standards groups recommend using RSA, ECDSA, or ED25519 over
the older DSA, and administrators may need to limit the allowed SSH key
algorithms.

GitLab allows you to restrict the allowed SSH key technology as well as specify
the minimum key length for each technology.

In the Admin area under **Settings** (`/admin/application_settings`), look for
the "Visibility and Access Controls" area:

![SSH keys restriction admin settings](img/ssh_keys_restrictions_settings.png)

If a restriction is imposed on any key type, users will be unable to upload new SSH keys that don't meet the requirement. Any existing keys that don't meet it will be disabled but not removed and users will be unable to pull or push code using them.

An icon will be visible to the user of a restricted key in the SSH keys section of their profile:

![Restricted SSH key icon](img/ssh_keys_restricted_key_icon.png)

Hovering over this icon will tell you why the key is restricted.
