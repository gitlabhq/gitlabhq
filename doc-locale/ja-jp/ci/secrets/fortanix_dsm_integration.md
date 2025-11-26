---
type: concepts, howto
stage: Software Supply Chain Security
group: Pipeline Security
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: 'チュートリアル: GitLabでFortanix Data Security Manager（DSM）を使用する'
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

Fortanix Data Security Manager（DSM）をGitLab CI/CDパイプラインのシークレットマネージャーとして使用できます。

このチュートリアルでは、Fortanix DSMで新しいシークレットを生成するか、既存のシークレットを使用し、それらをGitLab CI/CDジョブで使用するために必要な手順について説明します。このインテグレーションを実装し、データセキュリティを強化し、CI/CDパイプラインを最適化するために、手順を注意深く行ってください。

## はじめる前 {#before-you-begin}

以下を確認してください:

- 適切な管理権限を持つFortanix DSMアカウントへのアクセス。詳細については、[Getting Started with Fortanix Data Security Manager](https://www.fortanix.com/start-your-free-trial)を参照してください。
- 設定するインテグレーションへのアクセス権を持つ[GitLabアカウント](https://gitlab.com/users/sign_up)。
- Fortanix DSMにシークレットを保存するプロセス（シークレットの生成とインポートを含む）に関する知識。
- グループ、アプリケーション、プラグイン、変数、およびシークレットの管理に必要なFortanix DSMおよびGitLabでの権限へのアクセス。

## 新しいシークレットを生成してインポートする {#generate-and-import-a-new-secret}

Fortanix DSMで新しいシークレットを生成し、GitLabで使用するには、次の手順を実行します:

1. Fortanix DSMアカウントにサインインします。
1. Fortanix DSMで、[新しいグループとアプリケーションを作成します](https://support.fortanix.com/hc/en-us/articles/360015809372-User-s-Guide-Getting-Started-with-Fortanix-Data-Security-Manager-UI)。
1. [APIキーをアプリケーションの認証方法として構成します](https://support.fortanix.com/hc/en-us/articles/360033272171-User-s-Guide-Authentication)。
1. 次のコードを使用して、Fortanix DSMに新しいプラグインを生成します:

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

   詳細については、[FortanixのUser's Guide: Plugin Library](https://support.fortanix.com/hc/en-us/articles/360041950371-User-s-Guide-Plugin-Library)を参照してください

   - Fortanix DSMにシークレットを保存する場合は、インポートオプションを`yes`に設定します:

     ```json
     {
         "type": "alphanumeric_caps",
         "length": 64,
         "name": "GitLab-Secret",
         "import": "yes"
     }
     ```

   - ローテーション用に生成された新しい値のみが必要な場合は、インポートオプションを`no`に設定します:

     ```json
     {
         "type": "numeric",
         "length": 64,
         "name": "GitLab-Secret",
         "import": "no"
     }
     ```

1. GitLabの左側のサイドバーで、**検索または移動先**を選択し、プロジェクトを見つけます。
1. **設定** > **CI/CD**を選択します。
1. **変数**を展開し、以下の変数を追加します:
   - `FORTANIX_API_ENDPOINT`
   - `FORTANIX_API_KEY`
   - `FORTANIX_PLUGIN_ID`

1. インテグレーションを使用するには、プロジェクトで`.gitlab-ci.yml`設定ファイルを作成または編集します:

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

1. `.gitlab-ci.yml`ファイルを保存すると、パイプラインが自動的に実行されます。そうでない場合は、**ビルド** > **パイプライン** > **パイプラインの実行**を選択します。
1. **ビルド** > **ジョブ**に移動し、`build`ジョブのログを確認します:

   ![gitlab_build_result_1](img/gitlab_build_result_1_v16_9.png)

![dsm_secrets](img/dsm_secrets_v16_9.png)

## Fortanix DSMからの既存のシークレットを使用する {#use-an-existing-secret-from-fortanix-dsm}

すでにFortanix DSMにあるシークレットをGitLabで使用するには、次の手順を実行します:

1. シークレットは、Fortanixでエクスポート可能としてマークされている必要があります:

   ![dsm_secret_import_1](img/dsm_secret_import_1_v16_9.png)

1. GitLabの左側のサイドバーで、**検索または移動先**を選択し、プロジェクトを見つけます。
1. **設定** > **CI/CD**を選択します。
1. **変数**を展開し、以下の変数を追加します:
   - `FORTANIX_API_ENDPOINT`
   - `FORTANIX_API_KEY`
   - `FORTANIX_PLUGIN_ID`

1. インテグレーションを使用するには、プロジェクトで`.gitlab-ci.yml`設定ファイルを作成または編集します:

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

1. `.gitlab-ci.yml`ファイルを保存すると、パイプラインが自動的に実行されます。そうでない場合は、**ビルド > パイプライン > パイプラインの実行**を選択します。
1. **ビルド** > **ジョブ**に移動し、`build`ジョブのログを確認します:

   - ![gitlab_build_result_2](img/gitlab_build_result_2_v16_9.png)

## コード署名 {#code-signing}

GitLab環境でコード署名を安全に設定するには、次の手順に従います:

1. Fortanix DSMアカウントにサインインします。
1. `keystore_password`と`key_password`をFortanix DSMにシークレットとしてインポートします。それらがエクスポート可能としてマークされていることを確認してください。

   ![dsm_secret_import_2](img/dsm_secret_import_2_v16_9.png)

1. GitLabの左側のサイドバーで、**検索または移動先**を選択し、プロジェクトを見つけます。
1. **設定** > **CI/CD**を選択します。
1. **変数**を展開し、以下の変数を追加します:
   - `FORTANIX_API_ENDPOINT`
   - `FORTANIX_API_KEY`
   - `FORTANIX_SECRET_NAME_1`（`keystore_password`用）
   - `FORTANIX_SECRET_NAME_2`（`key_password`用）

1. インテグレーションを使用するには、プロジェクトで`.gitlab-ci.yml`設定ファイルを作成または編集します:

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

1. `.gitlab-ci.yml`ファイルを保存すると、パイプラインが自動的に実行されます。そうでない場合は、**ビルド > パイプライン > パイプラインの実行**を選択します。
1. **ビルド** > **ジョブ**に移動し、`build`ジョブのログを確認します:

   - ![gitlab_build_result_3](img/gitlab_build_result_3_v16_9.png)
