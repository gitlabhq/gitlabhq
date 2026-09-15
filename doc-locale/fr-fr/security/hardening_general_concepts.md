---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Renforcement de la sécurité - Concepts généraux
---

Les directives générales de renforcement de la sécurité sont présentées dans la [documentation principale sur le renforcement](hardening.md).

La documentation suivante résume certaines des philosophies sous-jacentes au renforcement de la sécurité des instances GitLab. Dans de nombreux cas, ces philosophies peuvent également s'appliquer à tous les systèmes informatiques.

## Sécurité en couches {#layered-security}

S'il existe deux façons de mettre en œuvre la sécurité, les deux doivent être implémentées plutôt qu'une seule. Un exemple rapide est la sécurité des comptes :

- Utilisez un mot de passe long, complexe et unique pour le compte.
- Implémentez un second facteur dans le processus d'authentification pour renforcer la sécurité.
- Utilisez un jeton matériel comme second facteur.
- Verrouillez un compte (pendant au moins une durée fixe) en cas de tentatives d'authentification échouées.
- Un compte non utilisé pendant une période donnée doit être désactivé ; appliquez cette règle par automatisation ou via des audits réguliers.

Plutôt que de n'utiliser qu'un ou deux éléments de la liste, utilisez-en le plus grand nombre possible. Cette philosophie peut s'appliquer à d'autres domaines que la sécurité des comptes ; elle devrait être appliquée à chaque domaine possible.

## Éliminer la sécurité par l'obscurité {#eliminate-security-through-obscurity}

La sécurité par l'obscurité signifie que l'on ne discute pas de certains éléments d'un système, d'un service ou d'un processus par crainte qu'un attaquant potentiel puisse utiliser ces détails pour formuler une attaque. Au contraire, le système doit être sécurisé au point que les détails de sa configuration pourraient être publics et que le système resterait aussi sécurisé que possible. En substance, si un attaquant prenait connaissance des détails de la configuration d'un système informatique, cela ne lui conférerait aucun avantage. L'un des inconvénients de la sécurité par l'obscurité est qu'elle peut engendrer un faux sentiment de sécurité chez l'administrateur du système, qui pense que celui-ci est plus sécurisé qu'il ne l'est réellement.

Un exemple de cela est l'exécution d'un service sur un port TCP non standard. Par exemple, le port par défaut du démon SSH sur les serveurs est le port TCP 22, mais il est possible de configurer le démon SSH pour qu'il s'exécute sur un autre port, tel que le port TCP 2222. L'administrateur qui a effectué cette configuration pourrait penser qu'elle renforce la sécurité du système ; cependant, il est très courant qu'un attaquant effectue un scan de ports sur un système pour découvrir tous les ports ouverts, permettant ainsi une détection rapide du service SSH et éliminant tout avantage de sécurité perçu.

GitLab étant un système open-core dont toutes les options de configuration sont bien documentées et constituent des informations publiques, l'idée de sécurité par l'obscurité va à l'encontre d'une valeur fondamentale de GitLab : la transparence. Ces recommandations de renforcement sont destinées à être publiques, afin d'aider à éliminer toute sécurité par l'obscurité.

## Réduction de la surface d'attaque {#attack-surface-reduction}

GitLab est un système complexe composé de nombreux composants. En règle générale, pour la sécurité, il est utile de désactiver les systèmes inutilisés. Cela élimine la « surface d'attaque » disponible qu'un attaquant potentiel peut exploiter. Cela peut également avoir l'avantage supplémentaire d'augmenter les ressources système disponibles.

À titre d'exemple, un processus sur un système se déclenche et vérifie les files d'attente pour des entrées toutes les cinq minutes, en interrogeant plusieurs sous-processus lors de ses vérifications. Si vous n'utilisez pas ce processus, il n'y a aucune raison de le configurer et il devrait être désactivé. Si un attaquant a identifié un vecteur d'attaque utilisant ce processus, il pourrait l'exploiter même si votre organisation ne l'utilise pas. En règle générale, vous devriez désactiver tout service qui n'est pas utilisé.

## Systèmes externes {#external-systems}

Dans les déploiements plus importants mais néanmoins renforcés, plusieurs nœuds sont souvent utilisés pour gérer la charge que nécessite votre déploiement GitLab. Dans ces cas, utilisez une combinaison d'options externes, de système d'exploitation et de configuration pour les règles de pare-feu. Toute option utilisant des restrictions ne doit être ouverte que dans la mesure nécessaire pour permettre au sous-système de fonctionner. Dans la mesure du possible, utilisez le chiffrement TLS pour le trafic réseau.
