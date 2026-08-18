---
stage: Application Security Testing
group: Dynamic Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Vérifications des vulnérabilités du test de sécurité des API
---

{{< details >}}

- Édition : Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Renommé](https://gitlab.com/gitlab-org/gitlab/-/issues/457449) de **DAST API vulnerability checks** en **API security testing vulnerability checks** dans GitLab 17.0.

{{< /history >}}

[Le test de sécurité des API](../_index.md) fournit des vérifications de vulnérabilités utilisées pour détecter les vulnérabilités dans l'API testée.

## Vérifications passives {#passive-checks}

| Vérification                                                                        | Gravité | Type    | Profils |
|:-----------------------------------------------------------------------------|:---------|:--------|:---------|
| [Vérification des informations d'application](application_information_check.md)            | Moyenne   | Passive | Passive, Passive-Quick, Active-Quick, Active-Full, Quick, Full |
| [Vérification de l'authentification en texte clair](cleartext_authentication_check.md)          | Élevée     | Passive | Passive, Passive-Quick, Active-Quick, Active-Full, Quick, Full |
| [Détournement JSON](json_hijacking_check.md)                                    | Moyenne   | Passive | Passive, Passive-Quick, Active-Quick, Active-Full, Quick, Full |
| [Informations sensibles](sensitive_information_disclosure_check.md)           | Élevée     | Passive | Passive, Passive-Quick, Active-Quick, Active-Full, Quick, Full |
| [Cookie de session](session_cookie_check.md)                                    | Moyenne   | Passive | Passive, Passive-Quick, Active-Quick, Active-Full, Quick, Full |

## Vérifications actives {#active-checks}

| Vérification                                                                        | Gravité | Type    | Profils |
|:-----------------------------------------------------------------------------|:---------|:--------|:---------|
| [CORS](cors_check.md)                                                        | Moyenne   | Active  | Active-Full, Full |
| [Rebinding DNS](dns_rebinding_check.md)                                      | Moyenne   | Active  | Active-Full, Full |
| [Mode debug du framework](framework_debug_mode_check.md)                        | Élevée     | Active  | Active-Quick, Active-Full, Quick, Full |
| [Vulnérabilité Heartbleed OpenSSL](heartbleed_open_ssl_check.md)             | Élevée     | Active  | Active-Full, Full |
| [Vérification d'injection HTML](html_injection_check.md)                              | Moyenne   | Active  | Active-Quick, Active-Full, Quick, Full |
| [Méthodes HTTP non sécurisées](insecure_http_methods_check.md)                      | Moyenne   | Active  | Active-Quick, Active-Full, Quick, Full |
| [Injection JSON](json_injection_check.md)                                    | Moyenne   | Active  | Active-Quick, Active-Full, Quick, Full |
| [Redirection ouverte](open_redirect_check.md)                                      | Moyenne   | Active  | Active-Full, Full |
| [Injection de commande OS](os_command_injection_check.md)                        | Élevée     | Active  | Active-Quick, Active-Full, Quick, Full |
| [Traversée de chemin](path_traversal_check.md)                                    | Élevée     | Active  | Active-Full, Full |
| [Fichier sensible](sensitive_file_disclosure_check.md)                         | Moyenne   | Active  | Active-Full, Full |
| [Shellshock](shellshock_check.md)                                            | Élevée     | Active  | Active-Full, Full |
| [Injection SQL](sql_injection_check.md)                                      | Élevée     | Active  | Active-Quick, Active-Full, Quick, Full |
| [Configuration TLS](tls_server_configuration_check.md)                       | Élevée     | Active  | Active-Full, Full |
| [Jeton d'authentification](authentication_token_check.md)                        | Élevée     | Active  | Active-Quick, Active-Full, Quick, Full |
| [Entité externe XML](xml_external_entity_check.md)                          | Élevée     | Active  | Active-Full, Full |
| [Injection XML](xml_injection_check.md)                                      | Moyenne   | Active  | Active-Quick, Active-Full, Quick, Full |

## Vérifications du test de sécurité des API par profil {#api-security-testing-checks-by-profile}

### Passive-Quick {#passive-quick}

- [Vérification des informations d'application](application_information_check.md)
- [Vérification de l'authentification en texte clair](cleartext_authentication_check.md)
- [Détournement JSON](json_hijacking_check.md)
- [Informations sensibles](sensitive_information_disclosure_check.md)
- [Cookie de session](session_cookie_check.md)

### Active-Quick {#active-quick}

- [Vérification des informations d'application](application_information_check.md)
- [Vérification de l'authentification en texte clair](cleartext_authentication_check.md)
- [Mode debug du framework](framework_debug_mode_check.md)
- [Vérification d'injection HTML](html_injection_check.md)
- [Méthodes HTTP non sécurisées](insecure_http_methods_check.md)
- [Détournement JSON](json_hijacking_check.md)
- [Injection JSON](json_injection_check.md)
- [Injection de commande OS](os_command_injection_check.md)
- [Informations sensibles](sensitive_information_disclosure_check.md)
- [Cookie de session](session_cookie_check.md)
- [Injection SQL](sql_injection_check.md)
- [Jeton d'authentification](authentication_token_check.md)
- [Injection XML](xml_injection_check.md)

### Active-Full {#active-full}

- [Vérification des informations d'application](application_information_check.md)
- [Vérification de l'authentification en texte clair](cleartext_authentication_check.md)
- [CORS](cors_check.md)
- [Rebinding DNS](dns_rebinding_check.md)
- [Mode debug du framework](framework_debug_mode_check.md)
- [Vulnérabilité Heartbleed OpenSSL](heartbleed_open_ssl_check.md)
- [Vérification d'injection HTML](html_injection_check.md)
- [Méthodes HTTP non sécurisées](insecure_http_methods_check.md)
- [Détournement JSON](json_hijacking_check.md)
- [Injection JSON](json_injection_check.md)
- [Redirection ouverte](open_redirect_check.md)
- [Injection de commande OS](os_command_injection_check.md)
- [Traversée de chemin](path_traversal_check.md)
- [Fichier sensible](sensitive_file_disclosure_check.md)
- [Informations sensibles](sensitive_information_disclosure_check.md)
- [Cookie de session](session_cookie_check.md)
- [Shellshock](shellshock_check.md)
- [Injection SQL](sql_injection_check.md)
- [Configuration TLS](tls_server_configuration_check.md)
- [Jeton d'authentification](authentication_token_check.md)
- [Injection XML](xml_injection_check.md)
- [Entité externe XML](xml_external_entity_check.md)

### Quick {#quick}

- [Vérification des informations d'application](application_information_check.md)
- [Vérification de l'authentification en texte clair](cleartext_authentication_check.md)
- [Mode debug du framework](framework_debug_mode_check.md)
- [Vérification d'injection HTML](html_injection_check.md)
- [Méthodes HTTP non sécurisées](insecure_http_methods_check.md)
- [Détournement JSON](json_hijacking_check.md)
- [Injection JSON](json_injection_check.md)
- [Injection de commande OS](os_command_injection_check.md)
- [Informations sensibles](sensitive_information_disclosure_check.md)
- [Cookie de session](session_cookie_check.md)
- [Injection SQL](sql_injection_check.md)
- [Jeton d'authentification](authentication_token_check.md)
- [Injection XML](xml_injection_check.md)

### Full {#full}

- [Vérification des informations d'application](application_information_check.md)
- [Vérification de l'authentification en texte clair](cleartext_authentication_check.md)
- [CORS](cors_check.md)
- [Rebinding DNS](dns_rebinding_check.md)
- [Mode debug du framework](framework_debug_mode_check.md)
- [Vulnérabilité Heartbleed OpenSSL](heartbleed_open_ssl_check.md)
- [Vérification d'injection HTML](html_injection_check.md)
- [Méthodes HTTP non sécurisées](insecure_http_methods_check.md)
- [Détournement JSON](json_hijacking_check.md)
- [Injection JSON](json_injection_check.md)
- [Redirection ouverte](open_redirect_check.md)
- [Injection de commande OS](os_command_injection_check.md)
- [Traversée de chemin](path_traversal_check.md)
- [Fichier sensible](sensitive_file_disclosure_check.md)
- [Informations sensibles](sensitive_information_disclosure_check.md)
- [Cookie de session](session_cookie_check.md)
- [Shellshock](shellshock_check.md)
- [Injection SQL](sql_injection_check.md)
- [Configuration TLS](tls_server_configuration_check.md)
- [Jeton d'authentification](authentication_token_check.md)
- [Injection XML](xml_injection_check.md)
- [Entité externe XML](xml_external_entity_check.md)
