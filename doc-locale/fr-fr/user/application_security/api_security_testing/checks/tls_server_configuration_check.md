---
stage: Application Security Testing
group: Dynamic Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Configuration du serveur TLS
---

## Description {#description}

Vérification des différents problèmes de configuration du serveur TLS. Vérifie les versions TLS, les HMAC, les chiffrements et les algorithmes de compression pris en charge par le serveur.

## Remédiation {#remediation}

Une protection insuffisante de la couche transport permet d'exposer les communications à des tiers non approuvés, offrant ainsi un vecteur d'attaque pour compromettre une application web et/ou voler des informations sensibles. Les sites web utilisent généralement le protocole SSL/TLS (Secure Sockets Layer/Transport Layer Security) pour assurer le chiffrement au niveau de la couche transport. Cependant, à moins que le site web ne soit configuré pour utiliser SSL/TLS et ne soit correctement configuré pour l'utiliser, il peut être vulnérable à l'interception et à la modification du trafic.

SSL/TLS en tant que protocole a connu plusieurs révisions au fil des années. Chaque nouvelle version ajoute des fonctionnalités et corrige des failles dans le protocole. Avec le temps, certaines versions du protocole sont tellement compromises qu'elles deviennent des vulnérabilités si elles sont prises en charge. Il est recommandé de ne prendre en charge que les versions TLS les plus récentes, telles que TLS 1.3 (2018) et TLS 1.2 (2008).

La compression a été associée à des attaques par canal auxiliaire sur les connexions TLS. La désactivation de la compression peut prévenir ces attaques. Une attaque en particulier, CRIME (« Compression Ratio Info-leak Made Easy ») peut être évitée. CRIME est une attaque qui cible les clients, mais si le serveur ne prend pas en charge la compression, l'attaque est atténuée.

Historiquement, la cryptographie de haut niveau était soumise à des restrictions à l'exportation en dehors des États-Unis. Pour cette raison, les sites web étaient configurés pour prendre en charge des options cryptographiques faibles pour les clients limités à l'utilisation de chiffrements faibles. Les chiffrements faibles sont vulnérables aux attaques en raison de la relative facilité à les casser ; moins de deux semaines sur un ordinateur domestique standard et quelques secondes à l'aide de matériel dédié.

Aujourd'hui, tous les navigateurs et sites web modernes utilisent un chiffrement bien plus fort, mais certains sites web sont encore configurés pour prendre en charge des chiffrements faibles obsolètes. De ce fait, un attaquant peut être en mesure de forcer le client à utiliser un chiffrement plus faible lors de la connexion au site web, lui permettant ainsi de casser ce chiffrement faible. Pour cette raison, le serveur doit être configuré pour n'accepter que des chiffrements forts et ne pas fournir de service à un client qui demande à utiliser un chiffrement plus faible. De plus, certains sites web sont mal configurés et choisissent un chiffrement plus faible même lorsque le client prend en charge un chiffrement bien plus fort. L'OWASP propose un guide pour tester les problèmes SSL/TLS, notamment la prise en charge des chiffrements faibles et les erreurs de configuration, et il existe également d'autres ressources et outils.

## Liens {#links}

- [OWASP](https://owasp.org/Top10/A02_2021-Cryptographic_Failures/)
- [CWE](https://cwe.mitre.org/data/definitions/934.html)
