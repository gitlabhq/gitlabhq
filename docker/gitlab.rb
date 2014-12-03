# External URL should be your Docker instance.
# By default, this example is the "standard" boot2docker IP.
# Always use port 80 here to force the internal nginx to bind port 80,
# even if you intend to use another port in Docker.
external_url "http://192.168.59.103/"

# Prevent Postgres from trying to allocate 25% of total memory
postgresql['shared_buffers'] = '1MB'

# Configure GitLab to redirect PostgreSQL logs to the data volume
postgresql['log_directory'] = '/var/log/gitlab/postgresql'

# Some configuration of GitLab
# You can find more at https://gitlab.com/gitlab-org/omnibus-gitlab/blob/master/README.md#configuration
gitlab_rails['gitlab_email_from'] = 'gitlab@example.com'
gitlab_rails['gitlab_support_email'] = 'support@example.com'
gitlab_rails['time_zone'] = 'Europe/Paris'

# SMTP settings
# You must use an external server, the Docker container does not install an SMTP server
gitlab_rails['smtp_enable'] = true
gitlab_rails['smtp_address'] = "smtp.example.com"
gitlab_rails['smtp_port'] = 587
gitlab_rails['smtp_user_name'] = "user"
gitlab_rails['smtp_password'] = "password"
gitlab_rails['smtp_domain'] = "example.com"
gitlab_rails['smtp_authentication'] = "plain"
gitlab_rails['smtp_enable_starttls_auto'] = true

# Enable LDAP authentication
# gitlab_rails['ldap_enabled'] = true
# gitlab_rails['ldap_host'] = 'ldap.example.com'
# gitlab_rails['ldap_port'] = 389
# gitlab_rails['ldap_method'] = 'plain' # 'ssl' or 'plain'
# gitlab_rails['ldap_allow_username_or_email_login'] = false
# gitlab_rails['ldap_uid'] = 'uid'
# gitlab_rails['ldap_base'] = 'ou=users,dc=example,dc=com'
