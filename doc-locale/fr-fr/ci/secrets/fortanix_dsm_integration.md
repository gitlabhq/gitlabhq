---
type: concepts, howto
stage: Software Supply Chain Security
group: Pipeline Security
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 'Tutoriel : Utiliser Fortanix Data Security Manager (DSM) avec GitLab'
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Vous pouvez utiliser Fortanix Data Security Manager (DSM) comme gestionnaire de secrets pour vos pipelines GitLab CI/CD.

Ce tutoriel explique les étapes nécessaires pour générer de nouveaux secrets dans Fortanix DSM, ou utiliser des secrets existants, et les utiliser dans les jobs GitLab CI/CD. Suivez attentivement les instructions pour mettre en œuvre cette intégration, renforcer la sécurité des données et optimiser vos pipelines CI/CD.

## Avant de commencer {#before-you-begin}

Assurez-vous de disposer des éléments suivants :

- Un accès à un compte Fortanix DSM avec les privilèges administratifs appropriés. Pour plus d'informations, consultez [Getting Started with Fortanix Data Security Manager](https://www.fortanix.com/start-your-free-trial).
- Un [compte GitLab](https://gitlab.com/users/sign_up) avec accès au projet dans lequel vous souhaitez configurer l'intégration.
- Des connaissances sur le processus d'enregistrement des secrets dans Fortanix DSM, notamment la génération et l'importation de secrets.
- Un accès aux autorisations nécessaires dans Fortanix DSM et GitLab pour la gestion des groupes, des applications, des plugins, des variables et des secrets.

## Générer et importer un nouveau secret {#generate-and-import-a-new-secret}

Pour générer un nouveau secret dans Fortanix DSM et l'utiliser avec GitLab :

1. Connectez-vous à votre compte Fortanix DSM.
1. Dans Fortanix DSM, [créez un nouveau groupe et une application](https://support.fortanix.com/hc/en-us/articles/360015809372-User-s-Guide-Getting-Started-with-Fortanix-Data-Security-Manager-UI).
1. Configurez la [clé API comme méthode d'authentification pour l'application](https://support.fortanix.com/hc/en-us/articles/360033272171-User-s-Guide-Authentication).
1. Utilisez le code suivant pour générer un nouveau plugin dans Fortanix DSM :

   ```lua
   numericAlphabet = "0123456789"
   alphanumericAlphabet = numericAlphabet .. "abcdefghijklmnopqrstuvwxyz"
   alphanumericCapsAlphabet = alphanumericAlphabet .. "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
   alphanumericCapsSymbolsAlphabets = alphanumericCapsAlphabet .. "!@#$&*_%="

   function genPass(alphabet, len, name, import)
       local alphabetSize = #alphabet
       local password = ''

       for i = 1, len, 1 do
           local random_char = math.random(alphabetSize)
           password = password .. string.sub(alphabet, random_char, random_char)
       end

       local pass = Blob.from_bytes(password)

       if import == "yes" then
           local sobject = assert(Sobject.import { name = name, obj_type = "SECRET", value = pass, key_ops = {'APPMANAGEABLE', 'EXPORT'} })
           return password
       end

       return password;
   end

   function run(input)
       if input.type == "numeric" then
           return genPass(numericAlphabet, input.length, input.name, input.import)
       end

       if input.type == "alphanumeric" then
           return genPass(alphanumericAlphabet, input.length, input.name, input.import)
       end

       if input.type == "alphanumeric_caps" then
           return genPass(alphanumericCapsAlphabet, input.length, input.name, input.import)
       end

       if input.type == "alphanumeric_caps_symbols" then
           return genPass(alphanumericCapsSymbolsAlphabets, input.length, input.name, input.import)
       end
   end
   ```

   Pour plus d'informations, consultez le [Guide utilisateur Fortanix : Plugin Library](https://support.fortanix.com/hc/en-us/articles/360041950371-User-s-Guide-Plugin-Library).

   - Définissez l'option d'importation sur `yes` si vous souhaitez stocker le secret dans Fortanix DSM :

     ```json
     {
         "type": "alphanumeric_caps",
         "length": 64,
         "name": "GitLab-Secret",
         "import": "yes"
     }
     ```

   - Définissez l'option d'importation sur `no` si vous souhaitez uniquement générer une nouvelle valeur pour la rotation :

     ```json
     {
         "type": "numeric",
         "length": 64,
         "name": "GitLab-Secret",
         "import": "no"
     }
     ```

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **CI/CD**.
1. Développez **Variables** et ajoutez ces variables :
   - `FORTANIX_API_ENDPOINT`
   - `FORTANIX_API_KEY`
   - `FORTANIX_PLUGIN_ID`

1. Créez ou modifiez le fichier de configuration `.gitlab-ci.yml` dans votre projet pour utiliser l'intégration :

   ```yaml
   stages:
     - build

   build:
     stage: build
     image: ubuntu
     script:
       - apt-get update
       - apt install --assume-yes jq
       - apt install --assume-yes curl
       - jq --version
       - curl --version
       - secret=$(curl --silent --request POST --header "Authorization:Basic ${FORTANIX_API_KEY}" ${FORTANIX_API_ENDPOINT}/sys/v1/plugins/${FORTANIX_PLUGIN_ID} --data "{\"type\":\"alphanumeric_caps\", \"name\":\"$CI_PIPELINE_ID\",\"import\":\"yes\", \"length\":\"48\"}" | jq --raw-output)
       - nsecret=$(curl --silent --request POST --header "Authorization:Basic ${FORTANIX_API_KEY}" ${FORTANIX_API_ENDPOINT}/sys/v1/plugins/${FORTANIX_PLUGIN_ID} --data "{\"type\":\"alphanumeric_caps\", \"import\":\"no\", \"length\":\"48\"}" | jq --raw-output)
       - encodesecret=$(echo $nsecret | base64)
       - rotate=$(curl --silent --request POST --header "Authorization:Basic ${FORTANIX_API_KEY}" ${FORTANIX_API_ENDPOINT}/crypto/v1/keys/rekey --data "{\"name\":\"$CI_PIPELINE_ID\", \"value\":\"$encodesecret\"}" | jq --raw-output .kid)
   ```

1. Le pipeline devrait s'exécuter automatiquement après l'enregistrement du fichier `.gitlab-ci.yml`. Sinon, sélectionnez **Version** > **Pipelines** > **Exécuter le pipeline**.
1. Accédez à **Version** > **Jobs** et vérifiez le job log du job `build` :

   ![Le job log du job de build indiquant une configuration Fortanix DSM réussie.](img/gitlab_build_result_1_v16_9.png)

![Vue des secrets dans Fortanix Data Security Manager.](img/dsm_secrets_v16_9.png)

## Utiliser un secret existant depuis Fortanix DSM {#use-an-existing-secret-from-fortanix-dsm}

Pour utiliser un secret existant dans Fortanix DSM avec GitLab :

1. Le secret doit être marqué comme exportable dans Fortanix :

   ![Le paramètre de secret exportable dans Fortanix Data Security Manager.](img/dsm_secret_import_1_v16_9.png)

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **CI/CD**.
1. Développez **Variables** et ajoutez ces variables :
   - `FORTANIX_API_ENDPOINT`
   - `FORTANIX_API_KEY`
   - `FORTANIX_PLUGIN_ID`

1. Créez ou modifiez le fichier de configuration `.gitlab-ci.yml` dans votre projet pour utiliser l'intégration :

   ```yaml
   stages:
     - build

   build:
     stage: build
     image: ubuntu
     script:
     - apt-get update
     - apt install --assume-yes jq
     - apt install --assume-yes curl
     - jq --version
     - curl --version
     - secret=$(curl --silent --request POST --header "Authorization:Basic ${FORTANIX_API_KEY}" ${FORTANIX_API_ENDPOINT}/crypto/v1/keys/export --data "{\"name\":\"${FORTANIX_SECRET_NAME}\"}" | jq --raw-output .value)
   ```

1. Le pipeline devrait s'exécuter automatiquement après l'enregistrement du fichier `.gitlab-ci.yml`. Sinon, sélectionnez **Version** > **Pipelines** > **Exécuter le pipeline**.
1. Accédez à **Version** > **Jobs** et vérifiez le job log du job `build` :

   - ![Le job log du job de build indiquant la récupération réussie d'un secret Fortanix existant.](img/gitlab_build_result_2_v16_9.png)

## Signature de code {#code-signing}

Pour configurer la signature de code de manière sécurisée dans votre environnement GitLab :

1. Connectez-vous à votre compte Fortanix DSM.
1. Importez `keystore_password` et `key_password` comme secrets dans Fortanix DSM. Assurez-vous qu'ils sont marqués comme exportables.

   ![Les mots de passe keystore et key importés comme secrets exportables dans Fortanix Data Security Manager.](img/dsm_secret_import_2_v16_9.png)

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **CI/CD**.
1. Développez **Variables** et ajoutez ces variables :
   - `FORTANIX_API_ENDPOINT`
   - `FORTANIX_API_KEY`
   - `FORTANIX_SECRET_NAME_1` (pour `keystore_password`)
   - `FORTANIX_SECRET_NAME_2` (pour `key_password`)

1. Créez ou modifiez le fichier de configuration `.gitlab-ci.yml` dans votre projet pour utiliser l'intégration :

   ```yaml
   stages:
     - build

   build:
     stage: build
     image: ubuntu
     script:
     - apt-get update -qy
     - apt install --assume-yes jq
     - apt install --assume-yes curl
     - apt-get install wget
     - apt-get install unzip
     - apt-get install --assume-yes openjdk-8-jre-headless openjdk-8-jdk   # Install Java
     - keystore_password=$(curl --silent --request POST --header "Authorization:Basic ${FORTANIX_API_KEY}" ${FORTANIX_API_ENDPOINT}/crypto/v1/keys/export --data "{\"name\":\"${FORTANIX_SECRET_NAME_1}\"}" | jq --raw-output .value)
     - key_password=$(curl --silent --request POST --header "Authorization:Basic ${FORTANIX_API_KEY}" ${FORTANIX_API_ENDPOINT}/crypto/v1/keys/export --data "{\"name\":\"${FORTANIX_SECRET_NAME_2}\"}" | jq --raw-output .value)
     - echo "yes" | keytool -genkeypair -alias mykey -keyalg RSA -keysize 2048 -keystore keystore.jks -storepass $keystore_password -keypass $key_password -dname "CN=test"
     - mkdir -p src/main/java
     - echo 'public class HelloWorld { public static void main(String[] args) { System.out.println("Hello, World!"); } }' > src/main/java/HelloWorld.java
     - javac src/main/java/HelloWorld.java
     - mkdir -p target
     - jar cfe target/HelloWorld.jar HelloWorld -C src/main/java HelloWorld.class
     - jarsigner -keystore keystore.jks -storepass $keystore_password -keypass $key_password -signedjar signed.jar target/HelloWorld.jar mykey
   ```

1. Le pipeline devrait s'exécuter automatiquement après l'enregistrement du fichier `.gitlab-ci.yml`. Sinon, sélectionnez **Version** > **Pipelines** > **Exécuter le pipeline**.
1. Accédez à **Version** > **Jobs** et vérifiez le job log du job `build` :

   - ![Le job log du job de build indiquant le processus de signature de code à l'aide des secrets Fortanix.](img/gitlab_build_result_3_v16_9.png)
