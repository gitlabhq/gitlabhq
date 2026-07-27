---
stage: Application Security Testing
group: Dynamic Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Injection HTML
---

## Description {#description}

Vérification des XSS via l'injection HTML dans tous les champs prenant en charge les chaînes de caractères. Cela inclut les portions de la requête HTTP telles que le chemin, la requête, les en-têtes, ainsi que les paramètres du corps tels que les champs XML, les champs JSON, etc. La détection est effectuée en surveillant les réponses pour la valeur injectée dans les champs HTML connus.

## Remédiation {#remediation}

Le cross-site scripting (XSS) est une technique d'attaque qui consiste à injecter du code fourni par un attaquant dans l'instance de navigateur d'un utilisateur. Une instance de navigateur peut être un client de navigateur web standard, ou un objet navigateur intégré dans un logiciel tel que le navigateur de WinAmp, un lecteur RSS ou un client de messagerie. Le code lui-même est généralement écrit en HTML/JavaScript, mais peut également s'étendre à VBScript, ActiveX, Java, Flash ou toute autre technologie prise en charge par les navigateurs.

Lorsqu'un attaquant amène le navigateur d'un utilisateur à exécuter son code, celui-ci s'exécute dans le contexte de sécurité (ou zone) du site web hôte. Avec ce niveau de privilège, le code est en mesure de lire, modifier et transmettre toutes les données sensibles accessibles par le navigateur. Un utilisateur victime de cross-site scripting peut voir son compte piraté (vol de cookies), son navigateur redirigé vers un autre emplacement, ou se voir présenter un contenu frauduleux délivré par le site web qu'il visite. Les attaques par cross-site scripting compromettent essentiellement la relation de confiance entre un utilisateur et le site web. Les applications utilisant des instances d'objets de navigation qui chargent du contenu depuis le système de fichiers peuvent exécuter du code dans la zone de la machine locale, permettant une compromission du système.

Il existe trois types d'attaques par cross-site scripting : non persistantes, persistantes et basées sur le DOM.

Les attaques non persistantes et les attaques basées sur le DOM nécessitent qu'un utilisateur visite un lien spécialement conçu contenant du code malveillant, ou visite une page web malveillante contenant un formulaire web qui, lorsqu'il est soumis au site vulnérable, déclenche l'attaque. L'utilisation d'un formulaire malveillant a souvent lieu lorsque la ressource vulnérable n'accepte que les requêtes HTTP POST. Dans ce cas, le formulaire peut être soumis automatiquement, à l'insu de la victime (par exemple, en utilisant JavaScript). En cliquant sur le lien malveillant ou en soumettant le formulaire malveillant, la charge XSS sera renvoyée, interprétée par le navigateur de l'utilisateur et exécutée. Une autre technique pour envoyer des requêtes quasi arbitraires (GET et POST) consiste à utiliser un client intégré, tel qu'Adobe Flash.

Les attaques persistantes se produisent lorsque le code malveillant est soumis à un site web où il est stocké pendant une certaine période. Parmi les cibles favorites d'un attaquant, on trouve souvent les publications sur les forums de discussion, les messages de messagerie web et les logiciels de chat en ligne. L'utilisateur non averti n'est pas tenu d'interagir avec un site ou un lien supplémentaire (par exemple, un site d'attaquant ou un lien malveillant envoyé par e-mail) ; il lui suffit de consulter la page web contenant le code.

## Liens {#links}

- [OWASP](https://owasp.org/Top10/A03_2021-Injection/)
- [CWE](https://cwe.mitre.org/data/definitions/79.html)
