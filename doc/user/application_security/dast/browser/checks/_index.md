---
stage: Application Security Testing
group: Dynamic Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# DAST browser-based crawler vulnerability checks

DETAILS:
**Tier:** Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

The [DAST browser-based crawler](../_index.md) provides vulnerability checks that are used to
scan for vulnerabilities in the site under test.

## Passive Checks

| ID                    | Check                                                                                                          | Severity | Type    |
|:----------------------|:---------------------------------------------------------------------------------------------------------------|:---------|:--------|
| [1004.1](1004.1.md)   | Sensitive cookie without HttpOnly attribute                                                                    | Low      | Passive |
| [16.1](16.1.md)       | Missing Content-Type header                                                                                    | Low      | Passive |
| [16.10](16.10.md)     | Content-Security-Policy violations                                                                             | Info     | Passive |
| [16.2](16.2.md)       | Server header exposes version information                                                                      | Low      | Passive |
| [16.3](16.3.md)       | X-Powered-By header exposes version information                                                                | Low      | Passive |
| [16.4](16.4.md)       | X-Backend-Server header exposes server information                                                             | Info     | Passive |
| [16.5](16.5.md)       | AspNet header exposes version information                                                                      | Low      | Passive |
| [16.6](16.6.md)       | AspNetMvc header exposes version information                                                                   | Low      | Passive |
| [16.7](16.7.md)       | Strict-Transport-Security header missing or invalid                                                            | Low      | Passive |
| [16.8](16.8.md)       | Content-Security-Policy analysis                                                                               | Info     | Passive |
| [16.9](16.9.md)       | Content-Security-Policy-Report-Only analysis                                                                   | Info     | Passive |
| [200.1](200.1.md)     | Exposure of sensitive information to an unauthorized actor (private IP address)                                | Low      | Passive |
| [209.1](209.1.md)     | Generation of error message containing sensitive information                                                   | Low      | Passive |
| [209.2](209.2.md)     | Generation of database error message containing sensitive information                                          | Low      | Passive |
| [287.1](287.1.md)     | Insecure authentication over HTTP (Basic Authentication)                                                       | Medium   | Passive |
| [287.2](287.2.md)     | Insecure authentication over HTTP (Digest Authentication)                                                      | Low      | Passive |
| [319.1](319.1.md)     | Mixed Content                                                                                                  | Info     | Passive |
| [352.1](352.1.md)     | Absence of anti-CSRF tokens                                                                                    | Medium   | Passive |
| [359.1](359.1.md)     | Exposure of Private Personal Information (PII) to an unauthorized actor (credit card)                          | Medium   | Passive |
| [359.2](359.2.md)     | Exposure of Private Personal Information (PII) to an unauthorized actor (United States social security number) | Medium   | Passive |
| [548.1](548.1.md)     | Exposure of information through directory listing                                                              | Low      | Passive |
| [598.1](598.1.md)     | Use of GET request method with sensitive query strings (session ID)                                            | Medium   | Passive |
| [598.2](598.2.md)     | Use of GET request method with sensitive query strings (password)                                              | Medium   | Passive |
| [598.3](598.3.md)     | Use of GET request method with sensitive query strings (Authorization header details)                          | Medium   | Passive |
| [601.1](601.1.md)     | URL redirection to untrusted site ('open redirect')                                                            | Low      | Passive |
| [614.1](614.1.md)     | Sensitive cookie without Secure attribute                                                                      | Low      | Passive |
| [693.1](693.1.md)     | Missing X-Content-Type-Options: nosniff                                                                        | Low      | Passive |
| [798.1](798.1.md)     | Exposure of confidential secret or token Adafruit API Key                                                      | High     | Passive |
| [798.2](798.2.md)     | Exposure of confidential secret or token Adobe Client ID (OAuth Web)                                           | High     | Passive |
| [798.3](798.3.md)     | Exposure of confidential secret or token Adobe Client Secret                                                   | High     | Passive |
| [798.4](798.4.md)     | Exposure of confidential secret or token Age secret key                                                        | High     | Passive |
| [798.5](798.5.md)     | Exposure of confidential secret or token Airtable API Key                                                      | High     | Passive |
| [798.6](798.6.md)     | Exposure of confidential secret or token Algolia API Key                                                       | High     | Passive |
| [798.7](798.7.md)     | Exposure of confidential secret or token Alibaba AccessKey ID                                                  | High     | Passive |
| [798.8](798.8.md)     | Exposure of confidential secret or token Alibaba Secret Key                                                    | High     | Passive |
| [798.9](798.9.md)     | Exposure of confidential secret or token Asana Client ID                                                       | High     | Passive |
| [798.10](798.10.md)   | Exposure of confidential secret or token Asana Client Secret                                                   | High     | Passive |
| [798.11](798.11.md)   | Exposure of confidential secret or token Atlassian API token                                                   | High     | Passive |
| [798.12](798.12.md)   | Exposure of confidential secret or token AWS                                                                   | High     | Passive |
| [798.13](798.13.md)   | Exposure of confidential secret or token Bitbucket Client ID                                                   | High     | Passive |
| [798.14](798.14.md)   | Exposure of confidential secret or token Bitbucket Client Secret                                               | High     | Passive |
| [798.15](798.15.md)   | Exposure of confidential secret or token Bittrex Access Key                                                    | High     | Passive |
| [798.16](798.16.md)   | Exposure of confidential secret or token Bittrex Secret Key                                                    | High     | Passive |
| [798.17](798.17.md)   | Exposure of confidential secret or token Beamer API token                                                      | High     | Passive |
| [798.18](798.18.md)   | Exposure of confidential secret or token Codecov Access Token                                                  | High     | Passive |
| [798.19](798.19.md)   | Exposure of confidential secret or token Coinbase Access Token                                                 | High     | Passive |
| [798.20](798.20.md)   | Exposure of confidential secret or token Clojars API token                                                     | High     | Passive |
| [798.21](798.21.md)   | Exposure of confidential secret or token Confluent Access Token                                                | High     | Passive |
| [798.22](798.22.md)   | Exposure of confidential secret or token Confluent Secret Key                                                  | High     | Passive |
| [798.23](798.23.md)   | Exposure of confidential secret or token Contentful delivery API token                                         | High     | Passive |
| [798.24](798.24.md)   | Exposure of confidential secret or token Databricks API token                                                  | High     | Passive |
| [798.25](798.25.md)   | Exposure of confidential secret or token Datadog Access Token                                                  | High     | Passive |
| [798.26](798.26.md)   | Exposure of confidential secret or token Discord API key                                                       | High     | Passive |
| [798.27](798.27.md)   | Exposure of confidential secret or token Discord client ID                                                     | High     | Passive |
| [798.28](798.28.md)   | Exposure of confidential secret or token Discord client secret                                                 | High     | Passive |
| [798.29](798.29.md)   | Exposure of confidential secret or token Doppler API token                                                     | High     | Passive |
| [798.30](798.30.md)   | Exposure of confidential secret or token Dropbox API secret                                                    | High     | Passive |
| [798.31](798.31.md)   | Exposure of confidential secret or token Dropbox long lived API token                                          | High     | Passive |
| [798.32](798.32.md)   | Exposure of confidential secret or token Dropbox short lived API token                                         | High     | Passive |
| [798.33](798.33.md)   | Exposure of confidential secret or token Drone CI Access Token                                                 | High     | Passive |
| [798.34](798.34.md)   | Exposure of confidential secret or token Duffel API token                                                      | High     | Passive |
| [798.35](798.35.md)   | Exposure of confidential secret or token Dynatrace API token                                                   | High     | Passive |
| [798.36](798.36.md)   | Exposure of confidential secret or token EasyPost API token                                                    | High     | Passive |
| [798.37](798.37.md)   | Exposure of confidential secret or token EasyPost test API token                                               | High     | Passive |
| [798.38](798.38.md)   | Exposure of confidential secret or token Etsy Access Token                                                     | High     | Passive |
| [798.39](798.39.md)   | Exposure of confidential secret or token Facebook                                                              | High     | Passive |
| [798.40](798.40.md)   | Exposure of confidential secret or token Fastly API key                                                        | High     | Passive |
| [798.41](798.41.md)   | Exposure of confidential secret or token Finicity Client Secret                                                | High     | Passive |
| [798.42](798.42.md)   | Exposure of confidential secret or token Finicity API token                                                    | High     | Passive |
| [798.43](798.43.md)   | Exposure of confidential secret or token Flickr Access Token                                                   | High     | Passive |
| [798.44](798.44.md)   | Exposure of confidential secret or token Finnhub Access Token                                                  | High     | Passive |
| [798.46](798.46.md)   | Exposure of confidential secret or token Flutterwave Secret Key                                                | High     | Passive |
| [798.47](798.47.md)   | Exposure of confidential secret or token Flutterwave Encryption Key                                            | High     | Passive |
| [798.48](798.48.md)   | Exposure of confidential secret or token Frame.io API token                                                    | High     | Passive |
| [798.49](798.49.md)   | Exposure of confidential secret or token FreshBooks Access Token                                               | High     | Passive |
| [798.50](798.50.md)   | Exposure of confidential secret or token GoCardless API token                                                  | High     | Passive |
| [798.52](798.52.md)   | Exposure of confidential secret or token GitHub personal access token                                          | High     | Passive |
| [798.53](798.53.md)   | Exposure of confidential secret or token GitHub OAuth Access Token                                             | High     | Passive |
| [798.54](798.54.md)   | Exposure of confidential secret or token GitHub App Token                                                      | High     | Passive |
| [798.55](798.55.md)   | Exposure of confidential secret or token GitHub Refresh Token                                                  | High     | Passive |
| [798.56](798.56.md)   | Exposure of confidential secret or token GitLab personal access token                                          | High     | Passive |
| [798.57](798.57.md)   | Exposure of confidential secret or token Gitter Access Token                                                   | High     | Passive |
| [798.58](798.58.md)   | Exposure of confidential secret or token HashiCorp Terraform user/org API token                                | High     | Passive |
| [798.59](798.59.md)   | Exposure of confidential secret or token Heroku API Key                                                        | High     | Passive |
| [798.60](798.60.md)   | Exposure of confidential secret or token HubSpot API Token                                                     | High     | Passive |
| [798.61](798.61.md)   | Exposure of confidential secret or token Intercom API Token                                                    | High     | Passive |
| [798.62](798.62.md)   | Exposure of confidential secret or token Kraken Access Token                                                   | High     | Passive |
| [798.63](798.63.md)   | Exposure of confidential secret or token Kucoin Access Token                                                   | High     | Passive |
| [798.64](798.64.md)   | Exposure of confidential secret or token Kucoin Secret Key                                                     | High     | Passive |
| [798.65](798.65.md)   | Exposure of confidential secret or token LaunchDarkly Access Token                                             | High     | Passive |
| [798.66](798.66.md)   | Exposure of confidential secret or token Linear API Token                                                      | High     | Passive |
| [798.67](798.67.md)   | Exposure of confidential secret or token Linear Client Secret                                                  | High     | Passive |
| [798.68](798.68.md)   | Exposure of confidential secret or token LinkedIn Client ID                                                    | High     | Passive |
| [798.69](798.69.md)   | Exposure of confidential secret or token LinkedIn Client secret                                                | High     | Passive |
| [798.70](798.70.md)   | Exposure of confidential secret or token Lob API Key                                                           | High     | Passive |
| [798.72](798.72.md)   | Exposure of confidential secret or token Mailchimp API key                                                     | High     | Passive |
| [798.74](798.74.md)   | Exposure of confidential secret or token Mailgun private API token                                             | High     | Passive |
| [798.75](798.75.md)   | Exposure of confidential secret or token Mailgun webhook signing key                                           | High     | Passive |
| [798.77](798.77.md)   | Exposure of confidential secret or token Mattermost Access Token                                               | High     | Passive |
| [798.78](798.78.md)   | Exposure of confidential secret or token MessageBird API token                                                 | High     | Passive |
| [798.80](798.80.md)   | Exposure of confidential secret or token Netlify Access Token                                                  | High     | Passive |
| [798.81](798.81.md)   | Exposure of confidential secret or token New Relic user API Key                                                | High     | Passive |
| [798.82](798.82.md)   | Exposure of confidential secret or token New Relic user API ID                                                 | High     | Passive |
| [798.83](798.83.md)   | Exposure of confidential secret or token New Relic ingest browser API token                                    | High     | Passive |
| [798.84](798.84.md)   | Exposure of confidential secret or token npm access token                                                      | High     | Passive |
| [798.86](798.86.md)   | Exposure of confidential secret or token Okta Access Token                                                     | High     | Passive |
| [798.87](798.87.md)   | Exposure of confidential secret or token Plaid Client ID                                                       | High     | Passive |
| [798.88](798.88.md)   | Exposure of confidential secret or token Plaid Secret key                                                      | High     | Passive |
| [798.89](798.89.md)   | Exposure of confidential secret or token Plaid API Token                                                       | High     | Passive |
| [798.90](798.90.md)   | Exposure of confidential secret or token PlanetScale password                                                  | High     | Passive |
| [798.91](798.91.md)   | Exposure of confidential secret or token PlanetScale API token                                                 | High     | Passive |
| [798.92](798.92.md)   | Exposure of confidential secret or token PlanetScale OAuth token                                               | High     | Passive |
| [798.93](798.93.md)   | Exposure of confidential secret or token Postman API token                                                     | High     | Passive |
| [798.94](798.94.md)   | Exposure of confidential secret or token Private Key                                                           | High     | Passive |
| [798.95](798.95.md)   | Exposure of confidential secret or token Pulumi API token                                                      | High     | Passive |
| [798.96](798.96.md)   | Exposure of confidential secret or token PyPI upload token                                                     | High     | Passive |
| [798.97](798.97.md)   | Exposure of confidential secret or token RubyGems API token                                                    | High     | Passive |
| [798.98](798.98.md)   | Exposure of confidential secret or token RapidAPI Access Token                                                 | High     | Passive |
| [798.99](798.99.md)   | Exposure of confidential secret or token Sendbird Access ID                                                    | High     | Passive |
| [798.100](798.100.md) | Exposure of confidential secret or token Sendbird Access Token                                                 | High     | Passive |
| [798.101](798.101.md) | Exposure of confidential secret or token SendGrid API token                                                    | High     | Passive |
| [798.102](798.102.md) | Exposure of confidential secret or token Sendinblue API token                                                  | High     | Passive |
| [798.103](798.103.md) | Exposure of confidential secret or token Sentry Access Token                                                   | High     | Passive |
| [798.104](798.104.md) | Exposure of confidential secret or token Shippo API token                                                      | High     | Passive |
| [798.105](798.105.md) | Exposure of confidential secret or token Shopify access token                                                  | High     | Passive |
| [798.106](798.106.md) | Exposure of confidential secret or token Shopify custom access token                                           | High     | Passive |
| [798.107](798.107.md) | Exposure of confidential secret or token Shopify private app access token                                      | High     | Passive |
| [798.108](798.108.md) | Exposure of confidential secret or token Shopify shared secret                                                 | High     | Passive |
| [798.109](798.109.md) | Exposure of confidential secret or token Slack token                                                           | High     | Passive |
| [798.110](798.110.md) | Exposure of confidential secret or token Slack Webhook                                                         | High     | Passive |
| [798.111](798.111.md) | Exposure of confidential secret or token Stripe                                                                | High     | Passive |
| [798.112](798.112.md) | Exposure of confidential secret or token Square Access Token                                                   | High     | Passive |
| [798.113](798.113.md) | Exposure of confidential secret or token Squarespace Access Token                                              | High     | Passive |
| [798.114](798.114.md) | Exposure of confidential secret or token SumoLogic Access ID                                                   | High     | Passive |
| [798.115](798.115.md) | Exposure of confidential secret or token SumoLogic Access Token                                                | High     | Passive |
| [798.116](798.116.md) | Exposure of confidential secret or token Travis CI Access Token                                                | High     | Passive |
| [798.117](798.117.md) | Exposure of confidential secret or token Twilio API Key                                                        | High     | Passive |
| [798.118](798.118.md) | Exposure of confidential secret or token Twitch API token                                                      | High     | Passive |
| [798.119](798.119.md) | Exposure of confidential secret or token Twitter API Key                                                       | High     | Passive |
| [798.120](798.120.md) | Exposure of confidential secret or token Twitter API Secret                                                    | High     | Passive |
| [798.121](798.121.md) | Exposure of confidential secret or token Twitter Access Token                                                  | High     | Passive |
| [798.122](798.122.md) | Exposure of confidential secret or token Twitter Access Secret                                                 | High     | Passive |
| [798.123](798.123.md) | Exposure of confidential secret or token Twitter Bearer Token                                                  | High     | Passive |
| [798.124](798.124.md) | Exposure of confidential secret or token Typeform API token                                                    | High     | Passive |
| [798.125](798.125.md) | Exposure of confidential secret or token Yandex API Key                                                        | High     | Passive |
| [798.126](798.126.md) | Exposure of confidential secret or token Yandex AWS Access Token                                               | High     | Passive |
| [798.127](798.127.md) | Exposure of confidential secret or token Yandex Access Token                                                   | High     | Passive |
| [798.128](798.128.md) | Exposure of confidential secret or token Zendesk Secret Key                                                    | High     | Passive |
| [829.1](829.1.md)     | Inclusion of Functionality from Untrusted Control Sphere                                                       | Low      | Passive |
| [829.2](829.2.md)     | Invalid Sub-Resource Integrity values detected                                                                 | Medium   | Passive |

## Active Checks

| ID                  | Check                                                                        | Severity | Type   |
|:--------------------|:-----------------------------------------------------------------------------|:---------|:-------|
| [113.1](113.1.md)   | Improper Neutralization of CRLF Sequences in HTTP Headers                    | High     | Active |
| [1336.1](1336.1.md) | Server-Side Template Injection                                               | High     | Active |
| [16.11](16.11.md)   | TRACE HTTP method enabled                                                    | High     | Active |
| [22.1](22.1.md)     | Improper limitation of a pathname to a restricted directory (Path traversal) | High     | Active |
| [611.1](611.1.md)   | External XML Entity Injection (XXE)                                          | High     | Active |
| [74.1](74.1.md)     | XSLT Injection                                                               | High     | Active |
| [78.1](78.1.md)     | OS Command Injection                                                         | High     | Active |
| [89.1](89.1.md)     | SQL Injection                                                                | High     | Active |
| [917.1](917.1.md)   | Expression Language Injection                                                | High     | Active |
| [918.1](918.1.md)   | Server-Side Request Forgery                                                  | High     | Active |
| [94.1](94.1.md)     | Server-side code injection (PHP)                                             | High     | Active |
| [94.2](94.2.md)     | Server-side code injection (Ruby)                                            | High     | Active |
| [94.3](94.3.md)     | Server-side code injection (Python)                                          | High     | Active |
| [94.4](94.4.md)     | Server-side code injection (NodeJS)                                          | High     | Active |
| [943.1](943.1.md)   | Improper neutralization of special elements in data query logic              | High     | Active |
| [98.1](98.1.md)     | PHP Remote File Inclusion                                                    | High     | Active |
