---
stage: Application Security Testing
group: Dynamic Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Cookie de session
---

## Description {#description}

Vérifiez que le cookie de session dispose des indicateurs et de la date d'expiration corrects.

## Remédiation {#remediation}

HTTP est un protocole sans état, de sorte que les sites Web utilisent généralement des cookies pour stocker les identifiants de session qui identifient de manière unique un utilisateur d'une requête à l'autre. Par conséquent, la confidentialité de chaque identifiant de session doit être maintenue afin d'empêcher plusieurs utilisateurs d'accéder au même compte. Un identifiant de session volé peut être utilisé pour consulter le compte d'un autre utilisateur ou effectuer une transaction frauduleuse.

- L'une des mesures de sécurisation des identifiants de session consiste à les marquer correctement pour qu'ils expirent et à exiger le bon ensemble d'indicateurs afin de s'assurer qu'ils ne sont pas transmis en clair ni accessibles depuis des scripts.
- HttpOnly est un indicateur supplémentaire inclus dans un en-tête de réponse HTTP Set-Cookie. L'utilisation de l'indicateur HttpOnly lors de la génération d'un cookie permet de réduire le risque qu'un script côté client accède au cookie protégé (si le navigateur le prend en charge). Si l'indicateur HttpOnly (facultatif) est inclus dans l'en-tête de réponse HTTP, le cookie ne peut pas être accédé via un script côté client (encore une fois, si le navigateur prend en charge cet indicateur). En conséquence, même si une faille de type cross-site scripting (XSS) existe et qu'un utilisateur accède accidentellement à un lien exploitant cette faille, le navigateur ne divulguera pas le cookie à un tiers.
- L'attribut Secure pour les cookies sensibles dans les sessions HTTPS n'est pas défini, ce qui pourrait amener l'agent utilisateur à envoyer ces cookies en texte clair lors d'une session HTTP.
- Un cookie lié à une session a été identifié comme étant utilisé sur un protocole de transport non sécurisé. Les protocoles de transport non sécurisés sont ceux qui n'utilisent pas SSL/TLS pour sécuriser la connexion. Parmi les exemples de tels protocoles, on peut citer « http ».
- L'expiration de session insuffisante survient lorsqu'une application Web permet à un attaquant de réutiliser d'anciennes informations d'identification de session ou des identifiants de session à des fins d'autorisation. L'expiration de session insuffisante accroît l'exposition d'un site Web aux attaques qui volent ou réutilisent les identifiants de session d'un utilisateur.

## Liens {#links}

- [OWASP](https://owasp.org/Top10/A07_2021-Identification_and_Authentication_Failures/)
- [CWE](https://cwe.mitre.org/data/definitions/930.html)
