---
stage: Application Security Testing
group: Secret Detection
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Secrets détectés
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

## Catégories de secrets {#secret-categories}

La détection des secrets GitLab identifie les secrets à l'aide de deux approches : la détection basée sur des règles et la détection générique.

### Détection basée sur des règles {#rule-based-detection}

La détection basée sur des règles identifie les secrets en comparant le contenu analysé à un modèle connu pour chaque type d'identifiant, appelé règle. Par exemple, un jeton d'accès personnel GitLab est identifié par le modèle `glpat-` suivi d'une chaîne de 20 caractères. GitLab prend en charge [plus de 200 règles](#supported-rules-for-rule-based-detection) couvrant les fournisseurs les plus courants par défaut.

La couverture de la détection basée sur des règles est limitée aux règles que l'analyseur prend en charge. Les secrets qui ne correspondent pas à une règle prise en charge ne sont pas détectés. L'analyseur basé sur Gitleaks et [GitLab Secret Scanning for Source Code](gitlab_secret_scanner/_index.md) prennent tous deux en charge la détection basée sur des règles.

### Détection générique {#generic-detection}

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Statut : version bêta

{{< /details >}}

La détection basée sur des règles ne peut détecter que les secrets correspondant à un modèle qu'elle connaît déjà. De nombreux identifiants ne suivent pas un format publié ou cohérent, de sorte qu'aucune règle ne peut les correspondre. Par exemple, un mot de passe pour un service interne, une chaîne de connexion à une base de données, ou une clé d'API sans préfixe distinctif. La détection générique cible ces secrets. Au lieu de correspondre à un modèle fixe, la détection générique examine le contexte autour d'une valeur et les propriétés de la valeur elle-même. Les deux signaux permettent de déterminer si la valeur est susceptible d'être un identifiant.

Étant donné que la détection générique ne dépend pas d'un modèle connu, elle peut détecter des secrets que la détection basée sur des règles manque. Elle est également plus sujette aux faux positifs, c'est pourquoi GitLab Secret Scanning for Source Code inclut une réduction des faux positifs pour limiter le bruit.

GitLab Secret Scanning for Source Code est le seul analyseur GitLab qui prend en charge la détection générique. Pour plus d'informations, consultez [les secrets génériques](gitlab_secret_scanner/_index.md#generic-secrets).

La détection générique ne se limite pas à une affectation évidente de type `secret = "value"`. L'extrait suivant présente des valeurs moins évidentes qu'elle identifie, ainsi que le résultat produit pour chacune :

```plaintext
# Secret assigned in a Perl hash, not a plain key-value pair
$config{'webhook_token'} = "Of0Pg2Qh4Ri6Sj8Tk";

# Password stored as the content of an XML element, not an attribute
<db_password>Ct8Du0Ev2Fw4Gx6Hy</db_password>

# API key passed as a URL query parameter
https://app.gitlab.com?api_key=Of3Pg5Qh7Ri9Sj1Tk

# Token embedded as a literal value in a SQL statement
INSERT INTO secrets (key, value) VALUES ('api_token', 'Kb1Lc3Md5Ne7Of9Pg');

# Password assigned through an environment variable lookup, not a plain variable
ENV["redis_pass"] = "Tt7Yy9Uu1Ii3OoPp5"

# Token passed as an argument to a setter method, not a direct assignment
config.put("dbToken", "Kb8Lc0Md2Ne4Of6Pg");

# Bearer token embedded in an XML configuration property
<property name="authorizationHeader" value="Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIn0.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c"/>

# Secret passed as a CLI flag, not a variable assignment
curl "https://api.example.com/v1/deploy" --api-token=7bN2vLpQ9wXzKfM4

# Credential left behind in a comment
# old admin password was T3mpP@ssw0rd2023XyZ1, rotate before removing this line

# UUID-formatted secret
client_secret: 123e4567-e89b-12d3-a456-426614174000

# Secret disguised by Base64 encoding
auth_token = "c2VjcmV0LWFwaS1rZXktdmFsdWU="

# Secret disguised by hex encoding
signing_key = "4f3c2b1a9e8d7c6b5a4938271605f4e3d2c1b0a"
```

#### Résultats des secrets génériques {#generic-secret-findings}

Lorsqu'un secret générique est détecté, GitLab attribue un label au résultat dans le rapport de vulnérabilité en fonction du type de valeur détecté :

- `Generic Password` : un mot de passe défini par un utilisateur, tel qu'un mot de passe de base de données ou un mot de passe de service.
- `Generic Secret` : un identifiant généré par une machine, tel qu'une clé d'API ou un jeton d'accès, qui ne correspond pas à un format de fournisseur connu.
- `Generic UUID Secret`, `Generic Base64-Encoded Secret`, `Generic Base64URL-Encoded Secret`, `Generic Hex-Encoded Secret`, `Generic JWT Token` et `Generic Paseto Token` : identifiants générés par une machine que GitLab a classés selon leur format.

Chaque résultat inclut une description qui explique pourquoi la valeur a été signalée. La description fournit des conseils sur la façon de confirmer si la valeur est un vrai secret, de faire tourner un secret confirmé ou d'ignorer un faux positif.

#### Secrets que la détection générique pourrait manquer {#secrets-generic-detection-might-miss}

La détection générique identifie un secret à partir de son environnement, comme un mot-clé ou le format de la valeur, et non en confirmant ce que fait la valeur. Cette approche implique des compromis. Même avec une réduction des faux positifs en place, certaines valeurs non secrètes peuvent apparaître comme des résultats. Par exemple :

- Un secret construit par concaténation ou interpolation de chaîne, tel que `full_key = prefix + secret_suffix`.
- Un secret sans mot-clé reconnaissable à proximité, comme une valeur codée en dur sans label tel que `key`, `secret`, `token` ou `password` à côté de lui.
- Un secret dans un fichier ou un chemin exclu par la détection générique, comme une dépendance externalisée, un fichier généré ou de la documentation.
- Une valeur plus courte que la longueur minimale attendue par la détection générique pour ce type de secret.
- Un secret signalé avec un niveau de confiance moyen ou faible. GitLab Secret Scanning for Source Code n'affiche que les résultats à haute confiance dans le rapport de vulnérabilité.

## Règles prises en charge pour la détection basée sur des règles {#supported-rules-for-rule-based-detection}

Ce tableau répertorie les règles utilisées pour la détection basée sur des règles et indique si chacune est prise en charge par :

- Détection des secrets des pipelines
- Détection des secrets côté client
- Protection contre l'envoi de secrets par push

Les règles de détection des secrets sont mises à jour dans l'[ensemble de règles par défaut](https://gitlab.com/gitlab-org/security-products/secret-detection/secret-detection-rules/-/tree/main). Les secrets détectés dont les modèles ont été supprimés ou mis à jour restent ouverts pour que vous puissiez les trier.

Si vous souhaitez ajouter une nouvelle règle de détection des secrets, vous pouvez [proposer de nouvelles règles de détection](pipeline/configure.md#propose-new-detection-rules) pour tous les utilisateurs GitLab, ou [personnaliser les ensembles de règles](pipeline/configure.md#customize-analyzer-rulesets) pour votre projet spécifique.

<!-- markdownlint-disable MD044 -->
<!-- vale gitlab_base.Spelling = NO -->
<!-- vale gitlab_base.SentenceSpacing = NO -->

| Description                                   | ID                                            | Détection des secrets des pipelines | Détection des secrets côté client | Protection contre l'envoi de secrets par push |
|:----------------------------------------------|:----------------------------------------------|:--------------------------|:-----------------------------|:-----------------------|
| Clé Adafruit IO                               | AdafruitIOKey                                 | {{< yes >}} | {{< no >}} | {{< yes >}} |
| ID client Adobe (OAuth Web)                       | Adobe Client ID (Oauth Web)                   | {{< yes >}} | {{< no >}} | {{< no >}} |
| Secret client Adobe                               | Adobe Client Secret                           | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Jeton d'accès Adobe IMS                            | AdobeIMSAccessToken                           | {{< yes >}} | {{< no >}} | {{< no >}} |
| Clé secrète Age                                    | Clé secrète Age                                | {{< yes >}} | {{< no >}} | {{< no >}} |
| Mot de passe du service Aiven                            | AivenServicePassword                          | {{< yes >}} | {{< no >}} | {{< yes >}} |
| ID AccessKey Alibaba                              | ID AccessKey Alibaba                          | {{< yes >}} | {{< no >}} | {{< no >}} |
| Clé secrète Alibaba                                | Clé secrète Alibaba                            | {{< yes >}} | {{< no >}} | {{< no >}} |
| ID client OAuth Amazon                            | AmazonOAuthClientID                           | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Clé API Anthropic                                 | anthropic_key                                 | {{< yes >}} | {{< yes >}} | {{< yes >}} |
| Clé API Artifactory                               | ArtifactoryApiKey                             | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Jeton d'identité Artifactory                        | ArtifactoryIdentityToken                      | {{< yes >}} | {{< no >}} | {{< yes >}} |
| ID client Asana                                   | Asana Client ID                               | {{< yes >}} | {{< no >}} | {{< no >}} |
| Secret client Asana                               | Asana Client Secret                           | {{< yes >}} | {{< no >}} | {{< no >}} |
| Jeton d'accès personnel Asana V1                   | AsanaPersonalAccessTokenV1                    | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Jeton d'accès personnel Asana V2                   | AsanaPersonalAccessTokenV2                    | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Clé API Atlassian                                 | AtlassianApiKey                               | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Jeton d'API Atlassian                               | Jeton d'API Atlassian                           | {{< yes >}} | {{< no >}} | {{< no >}} |
| Jeton d'API utilisateur Atlassian                          | AtlassianUserApiToken                         | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Secret client Auth0                               | Auth0ClientSecret                             | {{< yes >}} | {{< no >}} | {{< no >}} |
| ID de clé d'accès AWS                                 | AWS                                           | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Clé secrète d'accès AWS                             | AWSSecretAccessKey                            | {{< yes >}} | {{< no >}} | {{< no >}} |
| Jeton de session AWS                                 | AWSSessionToken                               | {{< yes >}} | {{< no >}} | {{< yes >}} |
| ID de pool d'identités AWS Cognito                      | AWSCognitoIdentityPoolID                      | {{< yes >}} | {{< no >}} | {{< no >}} |
| Clé AWS Bedrock                                   | AWSBedrockKey                       | {{< yes >}} | {{< no >}} | {{< no >}} |
| Clé AWS Bedrock à durée de vie courte                       | AWSBedrockShortLivedKey                       | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Clé de passerelle de gestion d'API Azure                  | AzureAPIManagementGatewayKey                  | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Clé directe de gestion d'API Azure                   | AzureAPIManagementDirectKey                   | {{< yes >}} | {{< no >}} | {{< no >}} |
| Configuration d'application Azure                                  | AzureAppConfigConnectionString                        | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Services de communication Azure                      | AzureCommServicesConnectionString                     | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Identifiants Azure Cosmos DB                       | AzureCosmosDBCredentials                   | {{< yes >}} | {{< no >}} | {{< no >}} |
| Secret client Azure Entra                         | AzureEntraClientSecret                        | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Jeton d'ID client Azure Entra                       | AzureEntraIDToken                          | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Clé d'accès Azure EventGrid                        | AzureEventGridAccessKey                       | {{< yes >}} | {{< no >}} | {{< no >}} |
| Clé API Azure Functions                           | AzureFunctionsAPIKey                          | {{< yes >}} | {{< no >}} | {{< yes >}} |
| SAS Azure Logic App                               | AzureLogicAppSAS                          | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Clé API Azure OpenAI                              | AzureOpenAIAPIKey                       | {{< yes >}} | {{< no >}} | {{< no >}} |
| Jeton d'accès personnel Azure                       | AzurePersonalAccessToken                   | {{< yes >}} | {{< no >}} | {{< no >}} |
| Clé d'accès Azure SignalR                          | AzureSignalRAccessKey                          | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Jeton d'API Beamer                                  | Jeton d'API Beamer                              | {{< yes >}} | {{< no >}} | {{< no >}} |
| ID client Bitbucket                               | ID client Bitbucket                           | {{< yes >}} | {{< no >}} | {{< no >}} |
| Secret client Bitbucket                           | Secret client Bitbucket                       | {{< yes >}} | {{< no >}} | {{< no >}} |
| Jeton d'API Brevo                                   | Sendinblue API token                          | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Jeton SMTP Brevo                                  | Sendinblue SMTP token                         | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Clé API Canada Digital Service Notify             | CDSCanadaNotifyAPIKey                         | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Jeton d'accès CircleCI                             | CircleCI access tokens                        | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Jeton de déploiement Clojars                              | Clojars API token                             | {{< yes >}} | {{< no >}} | {{< no >}} |
| Jeton d'API de diffusion Contentful                     | Jeton d'API de diffusion Contentful                 | {{< yes >}} | {{< no >}} | {{< no >}} |
| Jeton d'accès personnel Contentful                  | ContentfulPersonalAccessToken                 | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Jeton d'API de prévisualisation Contentful                      | Jeton d'API de prévisualisation Contentful                  | {{< yes >}} | {{< no >}} | {{< no >}} |
| Jeton d'API Databricks                              | Jeton d'API Databricks                          | {{< yes >}} | {{< no >}} | {{< no >}} |
| Clé API DataDog                                   | DataDogAPIKey                                 | {{< yes >}} | {{< no >}} | {{< no >}} |
| Jeton d'accès OAuth DigitalOcean                   | digitalocean-access-token                     | {{< yes >}} | {{< no >}} | {{< no >}} |
| Jeton d'accès personnel DigitalOcean                | digitalocean-pat                              | {{< yes >}} | {{< no >}} | {{< no >}} |
| Jeton de rafraîchissement DigitalOcean                        | digitalocean-refresh-token                    | {{< yes >}} | {{< no >}} | {{< no >}} |
| Clé API Discord                                   | Clé API Discord                               | {{< yes >}} | {{< no >}} | {{< no >}} |
| ID client Discord                                 | ID client Discord                             | {{< yes >}} | {{< no >}} | {{< no >}} |
| Secret client Discord                             | Secret client Discord                         | {{< yes >}} | {{< no >}} | {{< no >}} |
| Jeton d'accès personnel Docker                      | DockerPersonalAccessToken                     | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Jeton d'API Doppler                                 | Jeton d'API Doppler                             | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Jeton de service Doppler                             | Jeton de service Doppler                         | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Secret/clé API Dropbox                            | Secret/clé API Dropbox                        | {{< yes >}} | {{< no >}} | {{< no >}} |
| Jeton d'accès à l'application Dropbox                          | DropboxAppAccessToken                         | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Jeton d'API Dropbox à longue durée de vie                      | Jeton d'API Dropbox à longue durée de vie                  | {{< yes >}} | {{< no >}} | {{< no >}} |
| Jeton d'API Dropbox à courte durée de vie                     | Jeton d'API Dropbox à courte durée de vie                 | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Jeton d'API Duffel                                  | Jeton d'API Duffel                              | {{< yes >}} | {{< no >}} | {{< no >}} |
| Jeton de plateforme Dynatrace                          | DynatracePlatformToken                        | {{< yes >}} | {{< no >}} | {{< no >}} |
| Clé API EasyPost de production                       | EasyPost API token                            | {{< yes >}} | {{< no >}} | {{< no >}} |
| Clé API de test EasyPost                             | EasyPost test API token                       | {{< yes >}} | {{< no >}} | {{< no >}} |
| Jeton Facebook                                    | Jeton Facebook                                | {{< yes >}} | {{< no >}} | {{< no >}} |
| Jeton d'API utilisateur ou d'automatisation Fastly               | Fastly API token                              | {{< yes >}} | {{< no >}} | {{< no >}} |
| Jeton d'accès personnel Figma                       | FigmaPersonalAccessToken                      | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Jeton d'API Finicity                                | Jeton d'API Finicity                            | {{< yes >}} | {{< no >}} | {{< no >}} |
| Secret client Finicity                            | Secret client Finicity                        | {{< yes >}} | {{< no >}} | {{< no >}} |
| Clé chiffrée de production Flutterwave                    | FlutterwaveProdEncryptedKey                   | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Clé chiffrée de test Flutterwave                    | Flutterwave encrypted key                     | {{< yes >}} | {{< no >}} | {{< no >}} |
| Clé publique de production Flutterwave                       | FlutterwaveProdPublicKey                      | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Clé publique de test Flutterwave                       | Flutterwave public key                        | {{< yes >}} | {{< no >}} | {{< no >}} |
| Clé secrète de production Flutterwave                       | FlutterwaveProdSecretKey                      | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Clé secrète de test Flutterwave                       | Flutterwave secret key                        | {{< yes >}} | {{< no >}} | {{< no >}} |
| Jeton d'API Frame.io                                | Jeton d'API Frame.io                            | {{< yes >}} | {{< no >}} | {{< no >}} |
| Clé API GCP                                       | Clé API GCP                                   | {{< yes >}} | {{< no >}} | {{< no >}} |
| Secret client OAuth GCP                           | Secret client OAuth GCP                       | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Clé de mode Express GCP Vertex                       | GCPVertexExpressModeKey                       | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Jeton d'application GitHub                                  | Github App Token                              | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Jeton d'installation d'application GitHub                     | GithubAppInstallationToken                    | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Jeton d'accès personnel à granularité fine GitHub         | GithubFineGrainedPersonalAccessToken          | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Jeton d'accès OAuth GitHub                         | Github OAuth Access Token                     | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Jeton d'accès personnel GitHub (classique)            | Github Personal Access Token                  | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Jeton de rafraîchissement GitHub                              | Github Refresh Token                          | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Jeton de job CI/CD GitLab                            | gitlab_ci_build_token                         | {{< yes >}} | {{< yes >}} | {{< no >}} |
| Jeton de déploiement GitLab                               | gitlab_deploy_token                           | {{< yes >}} | {{< yes >}} | {{< no >}} |
| Jeton client des feature flags GitLab                 | Aucune                                          | {{< no >}} | {{< yes >}} | {{< no >}} |
| Jeton de flux GitLab                                 | gitlab_feed_token                             | {{< yes >}} | {{< yes >}} | {{< no >}} |
| Jeton de flux GitLab v2                              | gitlab_feed_token_v2                          | {{< yes >}} | {{< yes >}} | {{< yes >}} |
| Jeton d'e-mail entrant GitLab                       | gitlab_incoming_email_token                   | {{< yes >}} | {{< yes >}} | {{< yes >}} |
| Jeton d'agent Kubernetes GitLab                     | gitlab_kubernetes_agent_token                 | {{< yes >}} | {{< yes >}} | {{< yes >}} |
| Secret d'application OAuth GitLab                   | gitlab_oauth_app_secret                       | {{< yes >}} | {{< yes >}} | {{< yes >}} |
| Jeton d'accès personnel GitLab                      | gitlab_personal_access_token                  | {{< yes >}} | {{< yes >}} | {{< yes >}} |
| Jeton d'accès personnel GitLab (routable)           | gitlab_personal_access_token_routable         | {{< yes >}} | {{< yes >}} | {{< yes >}} |
| Jeton de déclenchement de pipeline GitLab                     | gitlab_pipeline_trigger_token                 | {{< yes >}} | {{< yes >}} | {{< yes >}} |
| Jeton d'authentification du runner GitLab                | gitlab_runner_auth_token                      | {{< yes >}} | {{< yes >}} | {{< yes >}} |
| Jeton d'enregistrement du runner GitLab                  | gitlab_runner_registration_token              | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Jeton OAuth SCIM GitLab                           | gitlab_scim_oauth_token                       | {{< yes >}} | {{< yes >}} | {{< no >}} |
| Jeton d'API GoCardless                              | Jeton d'API GoCardless                          | {{< yes >}} | {{< no >}} | {{< no >}} |
| Clé API Google                                    | Clé API GCP                                   | {{< yes >}} | {{< no >}} | {{< no >}} |
| Compte de service Google (GCP)                      | Google (GCP) Service-account                  | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Jeton de compte de service Grafana                     | GrafanaServiceAccountToken                    | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Jeton de politique d'accès cloud Grafana                 | GrafanaCloudAccessPolicyToken                 | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Jeton d'API HashiCorp Terraform                     | Hashicorp Terraform user/org API token        | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Jeton de lot HashiCorp Vault                       | Hashicorp Vault batch token                   | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Jeton de service HashiCorp Vault                     | HashicorpVaultServiceToken                     | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Clé API Heroku ou jeton d'autorisation d'application | Heroku API Key                                | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Clé secrète live Highnote                          | HighnoteLiveSecretKey                         | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Clé secrète de test Highnote                          | HighnoteTestSecretKey                         | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Jeton d'API d'application privée HubSpot                     | Hubspot API token                             | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Jeton d'accès utilisateur Hugging Face                    | HuggingFaceUserAccessToken                    | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Jeton d'accès Instagram                            | Jeton d'accès Instagram                        | {{< yes >}} | {{< no >}} | {{< no >}} |
| Jeton d'API Intercom                                | Jeton d'API Intercom                            | {{< yes >}} | {{< no >}} | {{< no >}} |
| Jeton d'accès à l'application Intercom                         | IntercomAppAccessToken                        | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Secret client ou ID client Intercom               | Intercom client secret/ID                     | {{< yes >}} | {{< no >}} | {{< no >}} |
| Jeton d'accès personnel Ionic                       | Ionic API token                               | {{< yes >}} | {{< no >}} | {{< no >}} |
| Jetons d'accès à la plateforme JFrog                      | JfrogPlatformAccessToken                      | {{< yes >}} | {{< no >}} | {{< no >}} |
| Jeton de compte de service Kubernetes                  | KubernetesServiceAccToken                     | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Clé API LangChain                                 | LangChainAPIKey                               | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Jeton d'API Linear                                  | Jeton d'API Linear                              | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Secret client ou ID Linear (OAuth 2.0)            | Linear client secret/ID                       | {{< yes >}} | {{< no >}} | {{< no >}} |
| ID client LinkedIn                                | Linkedin Client ID                            | {{< yes >}} | {{< no >}} | {{< no >}} |
| Secret client LinkedIn                            | Linkedin Client secret                        | {{< yes >}} | {{< no >}} | {{< no >}} |
| Clé API Lob                                       | Lob API Key                                   | {{< yes >}} | {{< no >}} | {{< no >}} |
| Clé API publiable Lob                           | Lob Publishable API Key                       | {{< yes >}} | {{< no >}} | {{< no >}} |
| Clé API Mailchimp                                 | Clé API Mailchimp                             | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Jeton d'API privé Mailgun                         | Jeton d'API privé Mailgun                     | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Clé de vérification publique Mailgun                   | Mailgun public validation key                 | {{< yes >}} | {{< no >}} | {{< no >}} |
| Clé de signature de webhook Mailgun                       | Clé de signature de webhook Mailgun                   | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Jeton d'API Mapbox                                  | Jeton d'API Mapbox                              | {{< yes >}} | {{< no >}} | {{< no >}} |
| Jeton d'API secret Mapbox                           | MapboxSecretApiToken                          | {{< yes >}} | {{< no >}} | {{< no >}} |
| Clé de licence MaxMind                               | Clé de licence MaxMind                           | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Clé d'accès MessageBird                            | messagebird-api-token                         | {{< yes >}} | {{< no >}} | {{< no >}} |
| ID client d'API MessageBird                         | ID client d'API MessageBird                     | {{< yes >}} | {{< no >}} | {{< no >}} |
| Jeton d'accès Meta                                 | Jeton d'accès Meta                             | {{< yes >}} | {{< no >}} | {{< no >}} |
| Jeton d'API de navigateur d'ingestion New Relic                | Jeton d'API de navigateur d'ingestion New Relic            | {{< yes >}} | {{< no >}} | {{< no >}} |
| Jeton d'API de navigateur d'ingestion New Relic v2             | Jeton d'API de navigateur d'ingestion New Relic v2         | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Clé d'API REST New Relic                            | Clé d'API REST New Relic                        | {{< yes >}} | {{< no >}} | {{< yes >}} |
| ID d'API utilisateur New Relic                             | ID d'API utilisateur New Relic                         | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Clé d'API utilisateur New Relic                            | New Relic user API Key                        | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Jeton d'accès npm                                  | Jeton d'accès npm                              | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Jeton d'accès Oculus                               | Jeton d'accès Oculus                           | {{< yes >}} | {{< no >}} | {{< no >}} |
| Jeton d'API Okta                                    | OktaAPIToken                                  | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Secret client Okta                                | OktaClientSecret                              | {{< yes >}} | {{< no >}} | {{< no >}} |
| Jeton d'API live Onfido                             | Jeton d'API live Onfido                         | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Clé API OpenAI                                    | open ai token                                 | {{< yes >}} | {{< no >}} | {{< no >}} |
| Clé de projet OpenAI                                | OpenAiProjectKey                              | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Clé de compte de service OpenAI                        | OpenAiServiceAccountKey                       | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Mot de passe dans l'URL                                   | Mot de passe dans l'URL                               | {{< yes >}} | {{< no >}} | {{< no >}} |
| Clé privée PGP                                   | Clé privée PGP                               | {{< yes >}} | {{< no >}} | {{< no >}} |
| Clé privée PKCS8                                 | Clé privée PKCS8                             | {{< yes >}} | {{< no >}} | {{< no >}} |
| Jeton d'API PlanetScale                             | Planetscale API token                         | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Secret d'application PlanetScale                            | PlanetscaleAppSecret                          | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Secret OAuth PlanetScale                          | PlanetscaleOAuthSecret                        | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Mot de passe PlanetScale                              | Planetscale password                          | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Clé API personnelle PostHog                          | PostHogPersonalAPIkey                         | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Clé API de projet PostHog                           | PostHogProjectAPIkey                          | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Jeton d'API Postman                                 | Jeton d'API Postman                             | {{< yes >}} | {{< no >}} | {{< no >}} |
| Clé d'accès à la collection Postman                     | PostmanCollectionAccessKey                    | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Jeton d'API Pulumi                                  | Jeton d'API Pulumi                              | {{< yes >}} | {{< no >}} | {{< no >}} |
| Jeton d'import PyPi                                 | PyPI upload token                             | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Clé privée RSA                                   | Clé privée RSA                               | {{< yes >}} | {{< no >}} | {{< no >}} |
| Jeton d'API RubyGems                                | Rubygem API token                             | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Jeton d'API public Segment                          | Segment Public API token                      | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Jeton d'API SendGrid                                | Sendgrid API token                            | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Jeton d'API Shippo                                  | Jeton d'API Shippo                              | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Jeton d'API de test Shippo                             | Jeton d'API de test Shippo                         | {{< yes >}} | {{< no >}} | {{< no >}} |
| Jeton d'API partenaire Shopify                         | ShopifyPartnerAPIToken                        | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Jeton d'accès personnel Shopify                     | Shopify access token                          | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Jeton d'accès d'application privée Shopify                  | Jeton d'accès d'application privée Shopify              | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Jeton d'accès d'application personnalisée Shopify                   | Shopify custom app access token               | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Secret partagé Shopify                             | Secret partagé Shopify                         | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Jeton de configuration d'application Slack                     | SlackAppConfigurationToken                    | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Jeton de rafraîchissement de configuration d'application Slack             | SlackAppConfigurationRefreshToken             | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Jeton de niveau d'application Slack                             | SlackAppLevelToken                            | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Jeton OAuth d'utilisateur bot Slack                        | Slack token                                   | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Webhook Slack                                     | Slack Webhook                                 | {{< yes >}} | {{< no >}} | {{< no >}} |
| Jeton d'analyse globale SonarQube                   | SonarQubeGlobalAnalysisToken                  | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Jeton d'analyse de projet SonarQube                  | SonarQubeProjectAnalysisToken                 | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Jeton utilisateur SonarQube                              | SonarQubeUserToken                            | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Jeton d'authentification Splunk                       | SplunkAuthToken                               | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Jeton HTTP Event Collector (HEC) Splunk            | SplunkHECToken                               | {{< yes >}} | {{< no >}} | {{< no >}} |
| Clé privée SSH (DSA)                             | Clé privée SSH (DSA)                         | {{< yes >}} | {{< no >}} | {{< no >}} |
| Clé privée SSH (EC)                              | Clé privée SSH (EC)                          | {{< yes >}} | {{< no >}} | {{< no >}} |
| Clé privée SSH                                   | Clé privée SSH                               | {{< yes >}} | {{< no >}} | {{< no >}} |
| Clé restreinte live Stripe                        | StripeLiveRestrictedKey                       | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Clé secrète live Stripe                            | StripeLiveSecretKey                           | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Clé secrète courte live Stripe                      | StripeLiveShortSecretKey                      | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Clé publiable live Stripe                       | StripeLivePublishableKey                      | {{< yes >}} | {{< no >}} | {{< no >}} |
| Clé publiable de test Stripe                       | StripeTestPublishableKey                      | {{< yes >}} | {{< no >}} | {{< no >}} |
| Clé restreinte de test Stripe                        | StripeTestRestrictedKey                       | {{< yes >}} | {{< no >}} | {{< no >}} |
| Clé secrète de test Stripe                            | StripeTestSecretKey                           | {{< yes >}} | {{< no >}} | {{< no >}} |
| Clé secrète courte de test Stripe                      | StripeTestShortSecretKey                      | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Secret client OAuth Tailscale                     | TailscaleOauthClientSecret                    | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Jeton d'accès à l'API Tailscale                        | TailscaleApiAccessToken                       | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Clé d'authentification personnelle Tailscale                       | TailscalePersonalAuthKey                      | {{< yes >}} | {{< no >}} | {{< yes >}} |
| ID secret Tencent Cloud                           | TencentCloudSecretID                          | {{< yes >}} | {{< no >}} | {{< yes >}} |
| SID de compte Twilio                                | SID de compte Twilio                            | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Clé API Twilio                                    | Twilio API Key                                | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Secret client OAuth Twitch                        | Twitch API token                              | {{< yes >}} | {{< no >}} | {{< no >}} |
| Jeton d'accès personnel Typeform                    | Typeform API token                            | {{< yes >}} | {{< no >}} | {{< no >}} |
| ID de clé d'accès Volcengine                          | VolcengineAccessKeyID                         | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Clé API WakaTime                                  | WakaTimeAPIKey                                | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Jeton X                                           | Twitter token                                 | {{< yes >}} | {{< no >}} | {{< no >}} |
| Secret d'accès compatible API AWS Yandex.Cloud     | Yandex.Cloud AWS API compatible Access Secret | {{< yes >}} | {{< no >}} | {{< no >}} |
| Clé API Yandex.Cloud                              | Clé API Yandex.Cloud                          | {{< yes >}} | {{< no >}} | {{< no >}} |
| Cookie IAM Yandex.Cloud v1-1                      | Yandex.Cloud IAM Cookie v1 - 1                | {{< yes >}} | {{< no >}} | {{< no >}} |
| Cookie IAM Yandex.Cloud v1-3                      | Yandex.Cloud IAM Cookie v1 - 3                | {{< yes >}} | {{< no >}} | {{< no >}} |

<!-- vale gitlab_base.SentenceSpacing = YES -->
<!-- vale gitlab_base.Spelling = YES -->
<!-- markdownlint-enable MD044 -->
