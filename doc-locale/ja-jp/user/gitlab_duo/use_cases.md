---
stage: AI-powered
group: AI Framework
info: This page is maintained by Developer Relations, author @dnsmichi, see https://handbook.gitlab.com/handbook/marketing/developer-relations/developer-advocacy/content/#maintained-documentation
description: AIネイティブの機能と機能性。
title: GitLab Duoのユースケース
---

以下のユースケースでは、GitLab Duoを使用した実践的な例、演習、およびワークフローを提供します。方法を学びます:

- 既存のコードをリファクタリングします。
- GitLab Duo根本原因分析を使用して、失敗したジョブの問題を解決する。
- セキュリティ脆弱性を解決します。

{{< alert type="note" >}}

GitLab Self-Managedを使用している場合、: 最高のユーザーエクスペリエンスと結果を得るには、GitLab DuoでGitLab 17.2以降が必要です。以前のバージョンでも引き続き動作する可能性はありますが、エクスペリエンスが低下するおそれがあります。

{{< /alert >}}

## GitLab Duoを使用して、開発課題を解決します {#use-gitlab-duo-to-solve-development-challenges}

### C#アプリケーションから開始します {#start-with-a-c-application}

これらの例では、C# IDEを開き、[GitLab Duoが有効になっている](turn_on_off.md)ことを確認し、GitLab Duo AIネイティブ機能をより効率性を高めるために使用する方法を調査します。

#### GitLab REST APIをクエリするためのCLIツール {#cli-tool-for-querying-the-gitlab-rest-api}

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i> [GitLab Duo Coffee Chatをご覧ください: C#を始めよう](https://www.youtube.com/watch?v=AdRtX9L--Po)
<!-- Video published on 2024-01-30 -->

課題は、GitLab REST APIをクエリするためのCLIツールを作成することです。

- 新しいC#プロジェクトを開始する方法と、dotNET CLIの使用方法をGitLab Duo Chatに尋ねます:

  ```markdown
  How can I get started creating an empty C# console application in VS Code?
  ```

- コード提案を使用して、新しいコードコメントでREST APIクライアントを生成します:

  ```csharp
  // Connect to a REST API and print the response
  ```

- 生成されたコードには説明が必要な場合があります: コードタスク`/explain`を使用して、REST APIコールがどのように機能するかを理解します。

コード提案のコメントからコードが生成されたら、CI/CDを設定する必要があります。

- チャットは、C#の`.gitignore`ファイルのベストプラクティスに役立ちます:

  ```markdown
  Show a .gitignore and .gitlab-ci.yml configuration for a C# project.
  ```

- CI/CDジョブが失敗した場合は、根本原因分析を使用して、[失敗したCI/CDジョブのトラブルシューティングを行います](../gitlab_duo_chat/examples.md#troubleshoot-failed-cicd-jobs-with-root-cause-analysis)。または、エラーメッセージをGitLab Duo Chatにコピーして、ヘルプを求めることもできます:

  ```markdown
  Explain the CI/CD error: The current .NET SDK does not support targeting
  .NET 8.0
  ```

- 後でテストを作成するには、GitLab Duoにコードタスク`/refactor`を使用して、選択したコードを関数にリファクタリングするように依頼します。

- チャットは、プログラミング言語固有のキーワードと関数、またはC# コンパイラエラーの説明にも役立ちます。

  ```markdown
  Can you explain async and await in C# with practical examples?

  explain error CS0122: 'Program' is inaccessible due to its protection level
  ```

- `/tests`コードタスクを使用してテストを生成します。

次の質問は、生成されたテストをC# ソリューションのどこに配置するかということです。初心者の方は、インポートの問題を回避するために、アプリケーションプロジェクトとテストプロジェクトが同じソリューションレベルに存在する必要があることを知らない場合があります。

- GitLab Duo Chatは、プロンプトの質問を尋ねたり、改良したりすることで支援できます:

  ```markdown
  In C# and VS Code, how can I add a reference to a project from a test project?

  Provide the XML configuration which I can add to a C# .csproj file to add a
  reference to another project in the existing solution?
  ```

- より良い結果を得るには、プロンプトを改良する必要があります。プロンプト`/refactor into the public class`は、後でテストプロジェクトからアクセスできるコードの提案を作成します。

  ```markdown
  /refactor into the public class
  ```

- `/refactor`コードタスクを使用して、`.gitlab-ci.yml`ファイルでテストを実行する方法をチャットに尋ねることもできます。

  ```markdown
  /refactor add a job to run tests (the test project)
  ```

リソース:

- [ソースコード付きプロジェクト](https://gitlab.com/gitlab-da/use-cases/ai/gitlab-duo-coffee-chat/gitlab-duo-coffee-chat-2024-01-29)

### C++アプリケーションを改善する {#improve-a-c-application}

#### SQLiteでC++アプリケーションをリファクタリングする {#refactor-a-c-application-with-sqlite}

この例では、単一のメイン関数を持つ既存のコードが存在します。これはコードを繰り返し、テストできません。

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i> [GitLab Duo Coffee Chatをご覧ください: C++、SQLite、CMake](https://www.youtube.com/watch?v=zGOo1jzQ5zM)
<!-- Video published on 2024-01-10 -->

再利用可能でテスト可能な関数にコードをリファクタリングするには:

1. GitLab Duoが有効になっているVS CodeまたはWeb IDEを開きます。
1. コードを選択し、改良されたプロンプトを使用して、GitLab Duo Chatに関数にリファクタリングするように依頼します:

   ```markdown
   /refactor into functions
   ```

   このリファクタリング手順は、選択したコード全体に対して機能しない場合があります。

1. リファクタリング戦略を機能ブロックに分割します。たとえば、データベース内のすべての挿入、更新、および削除操作をイテレーションします。

1. 新しく作成された関数のテストを生成するには、コードを再度選択し、コードタスク`/tests`を使用します。テストフレームワークの指示の特定のプロンプトを含めます:

   ```markdown
   /tests using the CTest test framework
   ```

1. アプリケーションが代わりに`Boost.Test`フレームワークを使用する場合は、プロンプトを改良します:

   ```markdown
   /tests using the Boost.Test framework
   ```

リソース:

- [ソースコード付きプロジェクト](https://gitlab.com/gitlab-da/use-cases/ai/gitlab-duo-coffee-chat/gitlab-duo-coffee-chat-2024-01-09)

#### C++関数をオブジェクト指向コードにリファクタリングする {#refactor-c-functions-into-object-oriented-code}

この例では、既存のコードが関数にラップされています。将来的にさらに多くのデータベースタイプをサポートするには、コードをクラスとオブジェクト継承にリファクタリングする必要があります。

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i> [GitLab Duo Coffee Chatでこれらの手順のチュートリアルをご覧ください: `OOP`クラスへのC++関数のリファクタリング](https://www.youtube.com/watch?v=Z9EJh0J9358)
<!-- Video published on 2024-01-24 -->

##### クラスの作業を開始する {#start-working-on-the-class}

- 基本データベースクラスのオブジェクト指向パターンを実装し、それをSQLiteクラスで継承する方法をGitLab Duo Chatに尋ねます:

  ```markdown
  Explain a generic database implementation using a base class, and SQLite specific class using C++. Provide source examples and steps to follow.
  ```

- 学習曲線には、実装クラスで純粋な仮想関数と仮想関数オーバーライドについてGitLab Duo Chatに質問することが含まれます。

  ```markdown
  What is a pure virtual function, and what is required for the developer inheriting from that class?
  ```

- コードタスクは、コードのリファクタリングに役立ちます。C++ヘッダーファイルで関数を選択し、改良されたプロンプトを使用します:

  ```markdown
  /refactor into class with public functions, and private path/db attributes. Inherit from the base class DB

  /refactor into a base class with pure virtual functions called DB. Remote the SQLite specific parts.
  ```

- GitLab Duo Chatは、コンストラクターのオーバーロード、オブジェクトの初期化、および共有ポインターによる最適化されたメモリ管理もガイドします。

  ```markdown
  How to add a function implementation to a class in a cpp file?

  How to pass values to class attributes through the class constructor call?
  ```

##### より良い回答を見つける {#find-better-answers}

- 次の質問では、十分なコンテキストが提供されませんでした。

  ```markdown
  Should I use virtual override instead of just override?
  ```

- 代わりに、より多くのコンテキストを追加して、より良い回答を得るようにしてください。

  ```markdown
  When implementing a pure virtual function in an inherited class, should I use virtual function override, or just function override? Context is C++.
  ```

- 比較的複雑な質問には、新しく作成されたクラスからオブジェクトをインスタンス化し、特定の関数を呼び出す方法が含まれます。

  ```markdown
  How to instantiate an object from a class in C++, call the constructor with the SQLite DB path and call the functions. Prefer pointers.
  ```

- 結果は役立つ場合がありますが、共有ポインターと必要なコードヘッダーを改良する必要がありました。

  ```markdown
  How to instantiate an object from a class in C++, call the constructor with the SQLite DB path and call the functions. Prefer shared pointers. Explain which header includes are necessary.
  ```

- コード提案は、`std::shared_ptr`ポインター演算の正しい構文を生成し、コード品質の向上に役立ちます。

  ```cpp
  // Define the SQLite path in a variable, default value database.db

  // Create a shared pointer for the SQLite class

  // Open a database connection using OpenConnection
  ```

##### コードをリファクタリングする {#refactor-your-code}

- コードをリファクタリングした後、コンパイラエラーが発生する可能性があります。チャットに説明を求めてください。

  ```markdown
  Explain the error: `db` is a private member of `SQLiteDB`
  ```

- 特定のSQLクエリ文字列は、より効率的な編集のために複数行の文字列にリファクタリングする必要があります。

  ```cpp
  std::string sql = "CREATE TABLE IF NOT EXISTS users (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, email TEXT NOT NULL)";
  ```

- コードを選択し、`/refactor`コードタスクを使用します:

  ```markdown
  /refactor into a stringstream with multiple lines
  ```

- また、ユーティリティ関数をC++のstatic関数を持つクラスにリファクタリングし、それらを呼び出す方法をチャットに尋ねることもできます。

  ```markdown
  /refactor into a class providing static functions

  How to call the static functions in the class?
  ```

コードをリファクタリングした後、より多くのデータベースタイプの基盤が構築され、全体的なコード品質が向上しました。

リソース:

- [ソースコード付きプロジェクト](https://gitlab.com/gitlab-da/use-cases/ai/gitlab-duo-coffee-chat/gitlab-duo-coffee-chat-2024-01-23)

### Kotlinアプリケーションの説明、テスト、およびリファクタリング {#explain-test-and-refactor-a-kotlin-application}

この例では、[Kotlinコード生成プロンプト](use_cases.md#kotlin-code-generation-prompts)の調査アプリケーションを分析し、リファクタリングとテストで改善する必要があります。

現在のコードは次のようになります:

```kotlin
package org.example

// Create a text adventure
// Search for the golden LEGO brick
// Add visual helpers
// Use random timer traps for game over
// Create a text adventure
fun createTextAdventure() {
    println("Welcome to the golden LEGO brick adventure!")
    println("You find yourself in a dimly lit room. What do you do?")

    var gameOver = false
    while (!gameOver) {
        println("1. Search for the golden LEGO brick")
        println("2. Examine the room")
        println("3. Quit")

        val choice = readLine()?.toIntOrNull() ?: 0
        when (choice) {
            1 -> searchForBrick()
            2 -> examineRoom()
            3 -> {
                println("Goodbye!")
                gameOver = true
            }
            else -> println("Invalid choice. Please try again.")
        }
    }
}

fun searchForBrick() {
    println("You search the room carefully, looking for any sign of the golden LEGO brick.")
    if (Math.random() < 0.2) {
        println("Congratulations! You found the golden LEGO brick!")
    } else {
        println("Your search turns up nothing. You'll have to try again.")
    }
}

fun examineRoom() {
    println("You look around the room, taking in the details.")
    println("The room is dimly lit, with shadows in the corners.")
    println("There is a door to the north and a table in the center of the room.")
}

fun main() {
    createTextAdventure()
}
```

1. IDEでコードを選択し、右クリックしてGitLab Duo Chatにコードの説明を求めます。
1. バグ、最適化のヒント、または脆弱性について詳しく知るために、プロンプトを改良します:

   ```markdown
   /explain focus on bugs and improvements

   The provided code is a simple text adventure game written in Kotlin. It allows the user to search for a golden LEGO brick or
   examine the room. While the code is functional, there are a few potential bugs and areas for improvement:

   1. Potential Bugs:

   The searchForBrick() function uses Math.random() to determine if the player finds the golden LEGO brick. However, this function
   does not handle the case where the player finds the brick. The game will continue indefinitely, even after the player has found
   the brick.

   2. Improvements:

   Game Over Condition: The game should have a proper game over condition when the player finds the golden LEGO brick. This could
   be achieved by introducing a boolean flag or a separate game state to track whether the brick has been found.
   ```

1. `/tests`コマンドを使用して、選択したコードのテストを生成するようにチャットに依頼します:

   ```markdown
   /tests

   To test the code, we can use JUnit for Kotlin. Here are some tests you can write:

     import org.junit.jupiter.api.Test
     import java.io.ByteArrayInputStream
     import java.io.ByteArrayOutputStream
     import java.io.PrintStream

     class TextAdventureTest {

         private val standardOut = System.out
         private val standardIn = System.`in`

         @Test
         fun `test searchForBrick success`() {
             val outContent = ByteArrayOutputStream()
             System.setOut(PrintStream(outContent))

             searchForBrick()

             val output = outContent.toString().trim()
             assert(output.contains("Congratulations! You found the golden LEGO brick!"))

             System.setOut(standardOut)
         }

      ...
     }
    ```

すべてがテストされていることを確認したら、選択したコードをリファクタリングするようにチャットに依頼します:

```markdown
/refactor fix bugs, improve UX

...

Improvements:

Extracted the menu printing logic into a separate printMenu function for better code organization and readability.
Used Random.nextDouble() instead of Math.random() for better compatibility with Kotlin's standard library.
Added a prompt for the user to enter their choice after printing the menu.
Removed the unnecessary gameOver variable initialization, as it's already assigned a value in the createTextAdventure function.
Added a comment in the searchForBrick function to remind you to add additional logic or game over condition if needed.
These changes should improve the code's readability, maintainability, and user experience.
```

リファクタリングされたコードは次のようになります:

```kotlin
package org.example

import kotlin.random.Random

// Create a text adventure
// Search for the golden LEGO brick
// Add visual helpers
// Use random timer traps for game over
// Create a text adventure
fun createTextAdventure() {
    println("Welcome to the golden LEGO brick adventure!")
    println("You find yourself in a dimly lit room. What do you do?")

    var gameOver = false
    while (!gameOver) {
        printMenu()
        val choice = readLine()?.toIntOrNull()
        when (choice) {
            1 -> searchForBrick()
            2 -> examineRoom()
            3 -> {
                println("Goodbye!")
                gameOver = true
            }
            else -> println("Invalid choice. Please try again.")
        }
    }
}

fun printMenu() {
    println("1. Search for the golden LEGO brick")
    println("2. Examine the room")
    println("3. Quit")
    print("Enter your choice: ")
}

fun searchForBrick() {
    println("You search the room carefully, looking for any sign of the golden LEGO brick.")
    if (Random.nextDouble() < 0.2) {
        println("Congratulations! You found the golden LEGO brick!")
        // Add additional logic or game over condition here
    } else {
        println("Your search turns up nothing. You'll have to try again.")
    }
}

fun examineRoom() {
    println("You look around the room, taking in the details.")
    println("The room is dimly lit, with shadows in the corners.")
    println("There is a door to the north and a table in the center of the room.")
}

fun main() {
    createTextAdventure()
}
```

### PowerShellを始めましょう {#get-started-with-powershell}

{{< alert type="note" >}}

PowerShellのサポートは[実験的](../project/repository/code_suggestions/supported_extensions.md#add-support-for-more-languages)です。

{{< /alert >}}

1. GitLab Duo Chatを使用して、現在のディレクトリのファイルサイズを出力するPowerShellスクリプトを開始する方法を尋ねます。

   ```markdown
   How to get started with a PowerShell script that prints the file size of the current directory?
   ```

   または、コード提案を使用してコードを生成することもできます。

1. 次の内容で新しいスクリプト`get-file-sizes.ps1`を作成します:

   ```powershell
   # Collect the files in a directory and print their size
   ```

1. コード提案がプロンプトを完了するのを待ってから、次のプロンプトを追加して、さまざまな出力形式を試してください:

   ```powershell
   # Collect the files in a directory and print their size

   $directory = Read-Host -Prompt "Enter the directory path to get file sizes"
   $files = Get-ChildItem -Path $directory -File
   foreach ($file in $files) {
       $fileSize = [Math]::Round(($file.Length / 1KB), 2)
       Write-Host "$($file.Name) - $fileSize KB"
   }

   # Repeat the code above but store the results in a CSV file
   ```

1. さまざまなエクスポート形式のプロンプトを使用して手順を繰り返すか、コード提案の自動補完を使用します。次に例を示します: 

   ```powershell
   # Collect the files in a directory and print their size

   $directory = Read-Host -Prompt "Enter the directory path to get file sizes"
   $files = Get-ChildItem -Path $directory -File
   foreach ($file in $files) {
       $fileSize = [Math]::Round(($file.Length / 1KB), 2)
       Write-Host "$($file.Name) - $fileSize KB"
   }

   # Repeat the code above but store the results in a CSV file
   $csvFile = "$directory\file-sizes.csv"
   $fileData = foreach ($file in $files) {
       [PSCustomObject]@{
           FileName = $file.Name
           FileSize = [Math]::Round(($file.Length / 1KB), 2)
       }
   }
   $fileData | Export-Csv -Path $csvFile -NoTypeInformation
   Write-Host "File sizes saved to $csvFile"

   # Repeat the code above but store the results in a JSON file
   $jsonFile = "$directory\file-sizes.json"
   $fileData | ConvertTo-Json | Out-File -FilePath $jsonFile
   Write-Host "File sizes saved to $jsonFile"

   # Repeat the code above but store the results in a XML file
   $xmlFile = "$directory\file-sizes.xml"
   $fileData | ConvertTo-Xml -NoTypeInformation | Out-File -FilePath $xmlFile
   Write-Host "File sizes saved to $xmlFile"

   # Repeat the code above but store the results in a HTML file
   $htmlFile = "$directory\file-sizes.html"
   $fileData | ConvertTo-Html -Property FileName, FileSize | Out-File -FilePath $htmlFile
   Write-Host "File sizes saved to $htmlFile"

   # Repeat the code above but store the results in a TXT file
   $txtFile = "$directory\file-sizes.txt"
   $fileData | Out-File -FilePath $txtFile
   Write-Host "File sizes saved to $txtFile"
   ```

## 脆弱性について説明し、解決する {#explain-and-resolve-vulnerabilities}

### Cコードの脆弱性 {#vulnerabilities-in-c-code}

この例では、Cで検出されたセキュリティ脆弱性は、GitLab Duoの助けを借りて修正する必要があります。

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i> [GitLab Duo Coffee Chatのこれらの手順のチュートリアルをご覧ください: 脆弱性の解決1](https://www.youtube.com/watch?v=Ypwx4lFnHP0)
<!-- Video published on 2024-01-30 -->

[このスニペットコード](https://gitlab.com/gitlab-da/use-cases/ai/gitlab-duo-coffee-chat/gitlab-duo-coffee-chat-2024-01-30/-/blob/4685e4e1c658565ae956ad9befdfcc128e60c6cf/src/main-vulnerable-source.c)は、[バッファオーバーフロー](https://en.wikipedia.org/wiki/Buffer_overflow)によるセキュリティ脆弱性を引き起こします:

```c
    strcpy(region, "Hello GitLab Duo Vulnerability Resolution challenge");

    printf("Contents of region: %s\n", region);
```

[SASTセキュリティスキャナー](../application_security/sast/analyzers.md)は、問題を検出してレポートできます。[脆弱性の説明](../application_security/vulnerabilities/_index.md#vulnerability-explanation)を使用して、問題を理解してください。脆弱性は、MRを生成するのに役立ちます。提案された変更が要件に適合しない場合、または問題につながる可能性がある場合は、コード提案とチャットを使用して改良できます。次に例を示します: 

1. GitLab Duoが有効になっているVS CodeまたはWeb IDEを開き、指示付きのコメントを追加します:

   ```c
       // Avoid potential buffer overflows

       // Possible AI-generated code below
       strncpy(region, "Hello GitLab Duo Vulnerability Resolution challenge", pagesize);
       region[pagesize-1] = '\0';
       printf("Contents of region: %s\n", region);
   ```

1. 提案されたコードを削除し、別のコメントを使用して代替方法を使用します。

   ```c
       // Avoid potential buffer overflows using snprintf()

       // Possible AI-generated code below
       snprintf(region, pagesize, "Hello GitLab Duo Vulnerability Resolution challenge");

       printf("Contents of region: %s\n", region);
   ```

1. GitLab Duo Chatを使用して質問をします。`/refactor`コードタスクは、さまざまな提案を生成できます。特定のアルゴリズムまたは関数を優先する場合は、プロンプトを改良します:

   ```markdown
   /refactor using snprintf
   ```

リソース:

- ソースコード付きプロジェクト: [GitLab Duo Coffee Chat 2024-01-30 - 脆弱性チャレンジ](https://gitlab.com/gitlab-da/use-cases/ai/gitlab-duo-coffee-chat/gitlab-duo-coffee-chat-2024-01-30)

## GitLabに関する質問に答える {#answer-questions-about-gitlab}

この例では、課題はGitLab Duo Chatを使用して問題を解決することです。

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i> [GitLab Duo Coffee Chatでこれらの手順のチュートリアルをご覧ください: GitLab Duo Chatで問題を解決するチャレンジ](https://www.youtube.com/watch?v=Ypwx4lFnHP0)
<!-- Video published on 2024-02-02 -->

- GitLab Duo Chatを使用して、CI/CDエラーの説明をすることができます。

  ```markdown
  Explain this CI/CD error: build.sh: line 14: go command not found
  ```

- 我慢できずに、1つまたは2つの単語だけを入力するとどうなりますか?

  ```markdown
  labels

  issue labels
  ```

  GitLab Duo Chatは、より多くのコンテキストを要求します。

- 質問を完全な文に絞り込み、問題を説明し、解決策を求めます。

  ```markdown
  Explain labels in GitLab. Provide an example for efficient usage.
  ```

リソース:

- [ソースコード付きプロジェクト](https://gitlab.com/gitlab-da/use-cases/ai/gitlab-duo-coffee-chat/gitlab-duo-coffee-chat-2024-02-01)

## 根本原因分析のユースケース {#root-cause-analysis-use-cases}

根本原因分析を使用して、CI/CDジョブの失敗の根本原因を特定します。次の例は一般的なエラーを示しており、フォークを作成して、根本原因を見つけて修正する練習をすることをお勧めします。

詳細については、ブログ投稿「[GitLab Duoの開発: AIと根本原因分析をブレンドしてCI/CDパイプラインを修正する](https://about.gitlab.com/blog/2024/06/06/developing-gitlab-duo-blending-ai-and-root-cause-analysis-to-fix-ci-cd/)」を参照してください。

### Goランタイムの欠落を分析する {#analyze-missing-go-runtime}

CI/CDジョブは、提供された`image`属性から起動されたコンテナ内で実行できます。コンテナがプログラミング言語のランタイムを提供しない場合、`script` `go`バイナリを参照するセクションの実行は失敗します。たとえば、エラーメッセージ`/bin/sh: eval: line 149: go: not found`を理解して修正する必要があります。コンテナのランタイムコンテキストで`go`コマンドが見つからない場合は、複数の理由が考えられます:

- ジョブは`alpine`のような最小限のコンテナイメージを使用し、Go言語ランタイムがインストールされていませんでした。
- ジョブは、CI/CD設定で指定された誤ったデフォルトのコンテナイメージを使用するか、`default`キーワードを使用します。
- ジョブは、コンテナイメージの代わりにシェルexecutorを使用します。ホストのオペレーティングシステムが破損しているか、Go言語ランタイムがインストールされていないか、設定されていません。

プロジェクト[チャレンジ: 根本原因分析 - Go GitLabリリースフェッチャー](https://gitlab.com/gitlab-da/use-cases/ai/ai-workflows/gitlab-duo-challenges/root-cause-analysis/challenge-root-cause-analysis-go-gitlab-release-fetcher)は、Go TanukiアプリケーションでCI/CDの問題を分析して修正する演習を提供します。この演習では、`build`ジョブと`docker-build`ジョブが失敗しています。問題を修正すると、CI/CDパイプラインが成功し、`build`ジョブは出力を出力します。`solution/`ディレクトリは、2つの可能なソリューションを提供します。

## GitLabにコントリビュートするためにGitLab Duoを使用する {#use-gitlab-duo-to-contribute-to-gitlab}

GitLab Duoの使用法は、GitLabコードベースへのコントリビュートと、顧客がより効率性を高める方法に重点を置いています。

GitLabコードベースは大きく、複雑なアルゴリズムまたはアプリケーション固有の実装を理解する必要があります。

### フロントエンドにコントリビュートします: プロファイル設定 {#contribute-to-frontend-profile-settings}

この例では、課題は、GitLabプロファイルページを更新し、ソーシャルネットワークの設定を改善することです。

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>こちらで録音をご覧ください: [GitLab Duo Coffee Chat: コード提案とチャットを使用してGitLabにコントリビュートする](https://www.youtube.com/watch?v=TauP7soXj-E)
<!-- Video published on 2024-02-23 -->

GitLab Duo Chatを使用して、コードの説明とリファクタリングを行い、テストを生成できます。コード提案は、既存のコードの自動補完に役立ち、Ruby、Go、またはVueJSで新しい関数とアルゴリズムを生成できます。

1. `/explain`コードタスクを使用して、選択したコードセクションを説明し、HAMLテンプレートがどのように機能するかを学びます。
1. コードタスクのプロンプトを改良し、代わりに`/explain how HAML rendering works`を尋ねることができます

または、チャットプロンプトに直接書き込むこともできます。例:

```markdown
how to populate a select in haml
```

リファクタリングの例には、以下が含まれます:

1. `/refactor into a HAML dropdown`
1. 既存のUIフォームコードを検査した後、プロンプトを`/refactor into a HAML dropdown with a form select`に改良します

GitLab Duo Chatは、エラーのデバッグを支援し、エラーメッセージにプレフィックスを付けました:

```markdown
Explain this error: undefined method `icon` for
```

## コード生成プロンプト {#code-generation-prompts}

以下の例では、GitLab Duoの[サポートされている言語](../project/repository/code_suggestions/supported_extensions.md)の[コード生成](../project/repository/code_suggestions/_index.md#best-practices-for-code-generation)プロンプトを示します。複数行のコメントを使用して、コード生成プロンプトを調整できます。

これらの例は、デベロッパーリレーションズチームが管理する[GitLab Duoプロンプトプロジェクト](https://gitlab.com/gitlab-da/use-cases/ai/ai-workflows/gitlab-duo-prompts)に保存されています。これらの例は動作確認済みです。環境に合わせて確認し、適用する必要があります。

### Cコード生成プロンプト {#c-code-generation-prompts}

I/O、パフォーマンス、ディスクI/O、TCPレイテンシーを収集し、その出力を表示するLinux統計ツールを作成します。完全な例については、ブログ記事「[AIを活用したGitLab Duoによる効率的なコード提案のヒント](https://about.gitlab.com/blog/2024/06/11/top-tips-for-efficient-ai-powered-code-suggestions-with-gitlab-duo/#code-suggestions-flow-with-comments)」を参照してください。

```c
// Create a Linux statistic tool
// Collect IO, performance, disk usage, TCP latency
// Print summaries

// Import required headers
#include <sys/stat.h>
#include <stdio.h>
#include <unistd.h>
#include <string.h>
#include <math.h>
#include <sys/statfs.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <sys/time.h>


int main() {
    struct stat statbuf;

    if (stat("/etc", &statbuf) != 0) {
        perror("stat");
        return 1;
    }

    printf("IO Block Size: %ld\n", statbuf.st_blksize);

    // TODO: add CPU usage, disk usage, network latency measurements

```

AIによって生成されたソースコードの例は、[GitLab Duoプロンプトプロジェクトの`c`ディレクトリで確認できます](https://gitlab.com/gitlab-da/use-cases/ai/ai-workflows/gitlab-duo-prompts/-/tree/main/code-suggestions/c?ref_type=heads)。

### C++コード生成プロンプト {#c-code-generation-prompts-1}

HTTPクライアントとして機能するCLIアプリケーションを作成します。

```c++
// Create a CLI app as HTTP client
// Create a main function
// Include all headers
// Read program options: URL, API endpoint, basic auth

#include <iostream>
#include <curl/curl.h>
#include <string>

int main(int argc, char** argv) {
  std::string url;
  std::string endpoint;
  std::string username;
  std::string password;

  // Parse command line options
  // ...

  CURL* curl = curl_easy_init();
  if(curl) {
    curl_easy_setopt(curl, CURLOPT_URL, url.c_str());

    // Set up basic auth
    curl_easy_setopt(curl, CURLOPT_HTTPAUTH, CURLAUTH_BASIC);
    curl_easy_setopt(curl, CURLOPT_USERPWD, (username + ":" + password).c_str());

    CURLcode res = curl_easy_perform(curl);

    if(res != CURLE_OK) {
      std::cerr << "Request failed: " << curl_easy_strerror(res) << std::endl;
    }

    curl_easy_cleanup(curl);
  }

  return 0;
}
```

分散ファイルノードを管理するアプリケーションを作成します。

```c++
// Create an application to manage distributed file nodes
// Provide an overview the health state of nodes
// Use OOP patterns to define the base file node
// Add specific filesystems inherited from the base file

class FileNode {
public:
    std::string name;
    std::string ipAddress;
    int port;
    HealthState healthState;

    FileNode(std::string name, std::string ipAddress, int port)
        : name(name), ipAddress(ipAddress), port(port), healthState(HealthState::Healthy) {}

    void setHealthState(HealthState state) {
        healthState = state;
    }
};

class LocalFileNode : public FileNode {
public:
    std::string mountPoint;

    LocalFileNode(std::string name, std::string mountPoint)
        : FileNode(name, "127.0.0.1", 0), mountPoint(mountPoint) {}
};

class NetworkFileNode : public FileNode {
public:
    std::string user;
    std::string password;

    NetworkFileNode(std::string name, std::string ipAddress, int port, std::string user, std::string password)
        : FileNode(name, ipAddress, port), user(user), password(password) {}
};

int main(){

}
```

`XDP`カーネルイベントにアタッチして、ネットワークトラフィックを測定するeBPFプログラムを作成します。Linuxカーネルでのみ動作します。

```c++
// Create an eBPF program which attaches to XDP kernel events
// Count all packets by IP address
// Print a summary
// Include necessary headers

#include <bpf/bpf.h>

struct data {
    __uint(type, BPF_MAP_TYPE_PERCPU_ARRAY);
    __type(key, uint32_t);
    __type(value, uint64_t);
};

BPF_TABLE("array", int, long, counts, 1024);

int xdp_prog(struct xdp_md *ctx) {
    void* data_end = (void*)(long)ctx->data_end;
    void* data = (void*)(long)ctx->data;
    struct ethhdr *eth = data;

    if ((void*)eth + sizeof(*eth) <= data_end) {
        struct iphdr *ip = data + sizeof(*eth);
        if ((void*)ip + sizeof(*ip) <= data_end) {
            counts.increment(ip->saddr);
        }
    }

    return XDP_PASS;
}
```

AIによって生成されたソースコードの例は、[GitLab Duoプロンプトプロジェクトの`c++`ディレクトリで確認できます](https://gitlab.com/gitlab-da/use-cases/ai/ai-workflows/gitlab-duo-prompts/-/tree/main/code-suggestions/c%2B%2B?ref_type=heads)。

### `C#`コード生成プロンプト {#c-code-generation-prompts-2}

さまざまなセンサーからの医療アナライザーアプリケーションを作成し、データを`MSSQL`に格納します。

```c#
// Create a medical analyzer app
// Collect data from different sensors
// Store data in MSSQL
// Provide methods to access the sensor data

using System.Data.SqlClient;

namespace MedicalAnalyzer
{
    public class SensorDataStore
    {
        private SqlConnection connection;

        public SensorDataStore()
        {
            // Create SQL Server connection
            connection = new SqlConnection("connection string here");
        }

        public void StoreSensorData(SensorData data)
        {
            // Open connection
            connection.Open();

            // Insert sensor data into database
            var command = connection.CreateCommand();
            command.CommandText = "INSERT INTO SensorData (Timestamp, DeviceId, Value) " +
                                  "VALUES (@timestamp, @deviceId, @value)";
            command.Parameters.AddWithValue("@timestamp", data.Timestamp);
            command.Parameters.AddWithValue("@deviceId", data.DeviceId);
            command.Parameters.AddWithValue("@value", data.Value);
            command.ExecuteNonQuery();

            // Close connection
            connection.Close();
        }

        public SensorData[] GetSensorData(DateTime startTime, DateTime endTime)
        {
            // Query database and return results
        }
    }
}
```

AIによって生成されたソースコードの例は、[GitLab Duoプロンプトプロジェクトの`c#`ディレクトリで確認できます](https://gitlab.com/gitlab-da/use-cases/ai/ai-workflows/gitlab-duo-prompts/-/tree/main/code-suggestions/c%23?ref_type=heads)。

### CSSコード生成プロンプト {#css-code-generation-prompts}

```css
/* Create CSS classes for animating a rainbow */

@keyframes rainbow {
    0% {
        background-position: 0% 50%;
    }
    50% {
        background-position: 100% 50%;
    }
    100% {
        background-position: 0% 50%;
    }
}

.rainbow {
    background: linear-gradient(to right, #ff0000, #ff7700, #ffff00, #00ff00, #0000ff, #8b00ff);
    background-size: 600% 600%;
    animation: rainbow 30s ease infinite;
}
```

AIによって生成されたソースコードの例は、[GitLab Duoプロンプトプロジェクトの`css`ディレクトリで確認できます](https://gitlab.com/gitlab-da/use-cases/ai/ai-workflows/gitlab-duo-prompts/-/tree/main/code-suggestions/css?ref_type=heads)。

### Goコード生成プロンプト {#go-code-generation-prompts}

クラスター内のコンテナ、ポッド、およびサービスの状態を読み取って表示するKubernetesの可観測性アプリケーションを作成します。

```go
// Create a client for Kubernetes observability
// Create a function that
// Reads the kubernetes configuration file from the KUBECONFIG env var
// Create kubernetes context, namespace default
// Inspect container, pod, service status and print an overview
// Import necessary packages
// Create main package

package main

import (
  "context"
  "fmt"
  "os"

  "k8s.io/client-go/kubernetes"
  "k8s.io/client-go/tools/clientcmd"

  metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
)

func main() {

  clientset := getClientset()
  namespace := "default"

  printPods(clientset, namespace)
  printServices(clientset, namespace)
  printContainers(clientset, namespace)

}

func getClientset() *kubernetes.Clientset {

  kubeconfig := os.Getenv("KUBECONFIG")

  config, err := clientcmd.BuildConfigFromFlags("", kubeconfig)
  if err != nil {
    panic(err)
  }

  clientset, err := kubernetes.NewForConfig(config)
  if err != nil {
    panic(err)
  }

  return clientset
}

func printPods(clientset *kubernetes.Clientset, namespace string) {

  pods, err := clientset.CoreV1().Pods(namespace).List(context.TODO(), metav1.ListOptions{})
  if err != nil {
    panic(err)
  }

  fmt.Printf("There are %d pods in the %s namespace\n", len(pods.Items), namespace)

}

func printServices(clientset *kubernetes.Clientset, namespace string) {

  services, err := clientset.CoreV1().Services(namespace).List(context.TODO(), metav1.ListOptions{})
  if err != nil {
    panic(err)
  }

  fmt.Printf("There are %d services in the %s namespace\n", len(services.Items), namespace)

}

// Create a function to print Containers
// Collect and print the count

func printContainers(clientset *kubernetes.Clientset, namespace string) {

    pods, err := clientset.CoreV1().Pods(namespace).List(context.TODO(), metav1.ListOptions{})
    if err != nil {
        panic(err)
    }

    var totalContainers int
    for _, pod := range pods.Items {
        totalContainers += len(pod.Spec.Containers)
    }

    fmt.Printf("There are %d containers in the %s namespace\n", totalContainers, namespace)

}
```

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>録画はこちらをご覧ください: [GitLab Duo Coffee Chat: GoおよびKubernetesの可観測性によるコード生成チャレンジ](https://www.youtube.com/watch?v=ORpRqp-A9hQ)
<!-- Video published on 2024-03-27. Maintainer: Developer Relations. -->

Redisと同様の、メモリ内キー値ストアを作成します。完全なチュートリアルについては、ブログ記事「[AIを活用したGitLab Duoによる効率的なコード提案のヒント](https://about.gitlab.com/blog/2024/06/11/top-tips-for-efficient-ai-powered-code-suggestions-with-gitlab-duo/#iterate-faster-with-code-generation)」を参照してください。

```go
// Create an in-memory key value store, similar to Redis
// Provide methods to
// set/unset keys
// update values
// list/print with filters
// Use BoltDB as external library
```

AIによって生成されたソースコードの例は、[GitLab Duoプロンプトプロジェクトの`go`ディレクトリで確認できます](https://gitlab.com/gitlab-da/use-cases/ai/ai-workflows/gitlab-duo-prompts/-/tree/main/code-suggestions/go?ref_type=heads)。

### Javaコード生成プロンプト {#java-code-generation-prompts}

メトリクスのさまざまなデータソースを使用したデータ分析アプリケーションを作成します。データのクエリと集計のためのAPIを提供します。

```java
// Create a data analytics app
// Parse different input sources and their values
// Store the metrics in a columnar format
// Provide an API to query and aggregate data
```

AIによって生成されたソースコードの例は、[GitLab Duoプロンプトプロジェクトの`java`ディレクトリで確認できます](https://gitlab.com/gitlab-da/use-cases/ai/ai-workflows/gitlab-duo-prompts/-/tree/main/code-suggestions/java?ref_type=heads)。

### JavaScriptコード生成プロンプト {#javascript-code-generation-prompts}

ReactJSで従業員向けの有給休暇アプリケーションを、日付と時刻のピッカーとともに作成します。

```javascript
// Create a Paid Time Off app for users
// Create a date-time picker in ReactJS
// Provide start and end options
// Show public holidays based on the selected country
// Send the request to a server API
```

AIによって生成されたソースコードの例は、[GitLab Duoプロンプトプロジェクトの`javascript`ディレクトリで確認できます](https://gitlab.com/gitlab-da/use-cases/ai/ai-workflows/gitlab-duo-prompts/-/tree/main/code-suggestions/javascript)。

### HTMLコード生成プロンプト {#html-code-generation-prompts}

```html
<!-- Create an AI knowledge base.
Describe where AI can help with efficient DevSecOps workflows.
Add a table with one Dev, one Ops, one Sec example.
-->

<table>
  <tr>
    <th>Dev</th>
    <th>Ops</th>
    <th>Sec</th>
  </tr>
  <tr>
    <td>Automated testing and continuous integration</td>
    <td>Infrastructure as code and automated provisioning</td>
    <td>Static code analysis and vulnerability scanning</td>
  </tr>
</table>
```

AIによって生成されたソースコードの例は、[GitLab Duoプロンプトプロジェクトの`html`ディレクトリで確認できます](https://gitlab.com/gitlab-da/use-cases/ai/ai-workflows/gitlab-duo-prompts/-/tree/main/code-suggestions/html)。

### Kotlinコード生成プロンプト {#kotlin-code-generation-prompts}

テキストアドベンチャーを生成し、宝物を探します。ビジュアルヘルパーを追加し、ゲームオーバーにランダムタイマートラップを使用します。

```kotlin
package org.example

// Create a text adventure
// Search for the golden LEGO brick
// Add visual helpers
// Use random timer traps for game over
// Create a text adventure
fun createTextAdventure() {
    println("Welcome to the golden LEGO brick adventure!")
    println("You find yourself in a dimly lit room. What do you do?")

    var gameOver = false
    while (!gameOver) {
        println("1. Search for the golden LEGO brick")
        println("2. Examine the room")
        println("3. Quit")

        val choice = readLine()?.toIntOrNull() ?: 0
        when (choice) {
            1 -> searchForBrick()
            2 -> examineRoom()
            3 -> {
                println("Goodbye!")
                gameOver = true
            }
            else -> println("Invalid choice. Please try again.")
        }
    }
}

fun searchForBrick() {
    println("You search the room carefully, looking for any sign of the golden LEGO brick.")
    if (Math.random() < 0.2) {
        println("Congratulations! You found the golden LEGO brick!")
    } else {
        println("Your search turns up nothing. You'll have to try again.")
    }
}

fun examineRoom() {
    println("You look around the room, taking in the details.")
    println("The room is dimly lit, with shadows in the corners.")
    println("There is a door to the north and a table in the center of the room.")
}

fun main() {
    createTextAdventure()
}
```

AIによって生成されたソースコードの例は、[GitLab Duoプロンプトプロジェクトの`kotlin`ディレクトリで確認できます](https://gitlab.com/gitlab-da/use-cases/ai/ai-workflows/gitlab-duo-prompts/-/tree/main/code-suggestions/kotlin?ref_type=heads)。

### PHPコード生成プロンプト {#php-code-generation-prompts}

GitLabリリースのRSSフィードフェッチャーを作成し、タイトルでフィルタリングできるようにします。

```php
// Create a web form to show GitLab releases
// Fetch the RSS feed from https://about.gitlab.com/atom.xml
// Provide filter options for the title

$feedUrl = 'https://about.gitlab.com/atom.xml';

$xml = simplexml_load_file($feedUrl);

$titleFilter = $_GET['titleFilter'];

echo '<h1>GitLab Releases</h1>';
echo '<ul>';
foreach ($xml->entry as $entry) {
    $title = $entry->title;
    if (empty($titleFilter) || strpos($title, $titleFilter) !== false) {
        echo '<li>' . $title . '</li>';
    }
}
echo '</ul>';

```

AIによって生成されたソースコードの例は、[GitLab Duoプロンプトプロジェクトの`php`ディレクトリで確認できます](https://gitlab.com/gitlab-da/use-cases/ai/ai-workflows/gitlab-duo-prompts/-/tree/main/code-suggestions/php)。

### PowerShellコード生成プロンプト {#powershell-code-generation-prompts}

ディレクトリ内のすべてのファイルを収集し、そのサイズを出力するスクリプトを作成します。CSVまたはJSONファイルに結果を格納するようにプロンプトを調整します。

```powershell
# Collect the files in a directory and print their size

$directory = Read-Host -Prompt "Enter the directory path to get file sizes"
$files = Get-ChildItem -Path $directory -File
foreach ($file in $files) {
    $fileSize = [Math]::Round(($file.Length / 1KB), 2)
    Write-Host "$($file.Name) - $fileSize KB"
}

# Repeat the code above but store the results in a CSV file

$csvFile = "$directory\file-sizes.csv"
$fileData = foreach ($file in $files) {
    [PSCustomObject]@{
        FileName = $file.Name
        FileSize = [Math]::Round(($file.Length / 1KB), 2)
    }
}
$fileData | Export-Csv -Path $csvFile -NoTypeInformation
Write-Host "File sizes saved to $csvFile"

# Repeat the code above but store the results in a JSON file

$jsonFile = "$directory\file-sizes.json"
$fileData | ConvertTo-Json | Out-File -FilePath $jsonFile
Write-Host "File sizes saved to $jsonFile"
```

AIによって生成されたソースコードの例は、[GitLab Duoプロンプトプロジェクトの`powershell`ディレクトリで確認できます](https://gitlab.com/gitlab-da/use-cases/ai/ai-workflows/gitlab-duo-prompts/-/tree/main/code-suggestions/powershell?ref_type=heads)。

### Pythonコード生成プロンプト {#python-code-generation-prompts}

Flaskを使用してREST APIでユーザーを管理し、それらをSQLiteに格納するウェブサーバーを作成します。

```python
# Create a Flask webserver
# Add REST API entrypoints to manage users by ID
# Implement create, update, delete functions
# User data needs to be stored in SQlite, create table if not exists
# Run the server on port 8080, support TLS
# Print required packages for requirements.txt in a comment.
# Use Python 3.10 as default

# Potential AI-generated code below
import flask
from flask import request
import sqlite3

app = flask.Flask(__name__)

# Create SQLite database and users table if not exists
conn = sqlite3.connect('users.db')
conn.execute('''CREATE TABLE IF NOT EXISTS users
         (id INTEGER PRIMARY KEY, name TEXT, email TEXT)''')

@app.route('/users', methods=['POST'])
def create_user():
  # Get user data from request
  name = request.form['name']
  email = request.form['email']

  # Insert user into database
  conn.execute('INSERT INTO users (name, email) VALUES (?, ?)', (name, email))

  return 'User created successfully'

@app.route('/users/<int:id>', methods=['PUT'])
def update_user(id):
  # Get user data from request
  name = request.form['name']
  email = request.form['email']

  # Update user in database
  conn.execute('UPDATE users SET name = ?, email = ? WHERE id = ?', (name, email, id))

  return 'User updated successfully'

@app.route('/users/<int:id>', methods=['DELETE'])
def delete_user(id):
  # Delete user from database
  conn.execute('DELETE FROM users WHERE id = ?', (id,))

  return 'User deleted successfully'

if __name__ == '__main__':
  # Required packages - flask, sqlite3
  app.run(host='0.0.0.0', port=8080, ssl_context='adhoc')

```

AIによって生成されたソースコードの例は、[GitLab Duoプロンプトプロジェクトの`python`ディレクトリで確認できます](https://gitlab.com/gitlab-da/use-cases/ai/ai-workflows/gitlab-duo-prompts/-/tree/main/code-suggestions/python?ref_type=heads)。

### Rubyコード生成プロンプト {#ruby-code-generation-prompts}

Elasticsearchにログデータを格納するログ解析中アプリケーションを作成します。

```ruby
# Create a Ruby app as log parser
# Provide hooks to replace sensitive strings in log lines
# Format the logs and store them in Elasticsearch

# Potential AI-generated code below
require 'logger'
require 'elasticsearch'

class LogParser
  attr_reader :logger

  def initialize
    @logger = Logger.new(STDOUT)
    @elasticsearch = Elasticsearch::Client.new
  end

  def parse_and_store(logs)
    sanitized_logs = sanitize_logs(logs)
    formatted_logs = format_logs(sanitized_logs)
    store_in_elasticsearch(formatted_logs)
  end

  private

  def sanitize_logs(logs)
    logs.map { |line| sanitize_line(line) }
  end

  def sanitize_line(line)
    # replace sensitive data
    line.gsub(/\d{16}/, '[REDACTED]')
  end

  def format_logs(logs)
    logs.map { |line| "#{Time.now}: #{line}" }
  end

  def store_in_elasticsearch(logs)
    logs.each { |log| @elasticsearch.index(index: 'app-logs', document: log) }
  end
end
```

重大度レベル、アプリケーション名、メッセージ文字列を含むsyslog形式をサポートするログクライアントユーティリティクラスを作成します。

```ruby
# Create Logging utility class
# Define default log level as attribute
# Add method for logging, inputs: level, app, message
# Print the data with formatted date and time in syslog format

# Potential AI-generated code below
class Logging
  attr_accessor :log_level

  def log(level, app, message)
    time = Time.now.strftime("%b %d %H:%M:%S")
    puts "#{time} #{app}[#{Process.pid}]: #{level} - #{message}"
  end
end

# Instantiate class and test the log method

# Potential AI-generated code below
logger = Logging.new
logger.log_level = :debug

logger.log(:info, 'MyApp', 'Application started - info')
logger.log(:debug, 'MyApp', 'Application started - debug')
logger.log(:error, 'MyApp', 'Application started - error')
logger.log(:fatal, 'MyApp', 'Application started - fatal')
logger.log(:warn, 'MyApp', 'Application started - warn')
```

AIによって生成されたソースコードの例は、[GitLab Duoプロンプトプロジェクトの`ruby`ディレクトリで確認できます](https://gitlab.com/gitlab-da/use-cases/ai/ai-workflows/gitlab-duo-prompts/-/tree/main/code-suggestions/ruby)。

### Rustコード生成プロンプト {#rust-code-generation-prompts}

```rust
// Query the GitLab REST API
// Get all open merge requests for gitlab-org/gitlab

use serde_json::Value;

fn main() {

    let client = reqwest::blocking::Client::new();
    let url = "https://gitlab.com/api/v4/projects/278964/merge_requests?state=opened";
    let response = client.get(url).send().unwrap().text().unwrap();
    let json: Value = serde_json::from_str(&response).unwrap();

    // TODO: Pagination, default fetch results: 20
    // Read the response headers to access the next page

    println!("{}", json.to_string());

    for mr in json.as_array().unwrap() {
        println!("{} - URL: {}", mr["title"], mr["web_url"]);
    }
}
```

RSSフィードリーダーアプリを作成します。例としてブログ記事「[AIの助けを借りて高度なRustプログラミングを学ぶ](https://about.gitlab.com/blog/2023/10/12/learn-advanced-rust-programming-with-a-little-help-from-ai-code-suggestions/)」があります。

```rust
    // Create a function that iterates over the source array
    // and fetches the data using HTTP from the RSS feed items.
    // Store the results in a new hash map.
    // Print the hash map to the terminal.
```

AIによって生成されたソースコードの例は、[GitLab Duoプロンプトプロジェクトの`rust`ディレクトリで確認できます](https://gitlab.com/gitlab-da/use-cases/ai/ai-workflows/gitlab-duo-prompts/-/tree/main/code-suggestions/rust?ref_type=heads)。

### Scalaコード生成プロンプト {#scala-code-generation-prompts}

```scala
// Implement Newtons Method
// Create an object with a main function
// Add a function that implements Newtons method for solving equations
// Add a driver function which tests the implemented function
object NewtonsMethod {
  def solveEquation(f: Double => Double, df: Double => Double, x0: Double, tolerance: Double): Double = {
    var x = x0
    var error = Double.PositiveInfinity
    while (math.abs(error) > tolerance) {
      error = f(x) / df(x)
      x -= error
    }
    x
  }

  def main(args: Array[String]): Unit = {
    val f: Double => Double = x => x * x - 4
    val df: Double => Double = x => 2 * x
    val x0 = 3.0
    val tolerance = 1e-6
    val root = solveEquation(f, df, x0, tolerance)
    println(s"The root is: $root")
  }
}
```

AIによって生成されたソースコードの例は、[GitLab Duoプロンプトプロジェクトの`scala`ディレクトリで確認できます](https://gitlab.com/gitlab-da/use-cases/ai/ai-workflows/gitlab-duo-prompts/-/tree/main/code-suggestions/scala?ref_type=heads)。

### シェルスクリプトコード生成プロンプト {#shell-scripts-code-generation-prompts}

CPU、メモリ、ディスクI/Oの使用状況で上位10件のプロセスを表示するスクリプト`mytop.sh`を作成します。最初のコードコメントから始めて、残りはコード提案で生成させます。

```shell
#!/bin/bash

# Get the top 10 processes by CPU usage
top -b -n 1 | head -n 11 | awk '{print $1, $2, $3, $9}' | column -t

# Get the top 10 processes by memory usage
top -b -n 1 | head -n 11 | awk '{print $1, $2, $4, $6}' | column -t

# Get the top 10 processes by disk I/O
top -b -n 1 | head -n 11 | awk '{print $1, $2, $7, $8}' | column -t

# Get the top 10 processes by network I/O
top -b -n 1 | head -n 11 | awk '{print $1, $2, $10, $11}' | column -t

```

AIによって生成されたソースコードの例は、[GitLab Duoプロンプトプロジェクトの`shell`ディレクトリで確認できます](https://gitlab.com/gitlab-da/use-cases/ai/ai-workflows/gitlab-duo-prompts/-/tree/main/code-suggestions/shell?ref_type=heads)。

### TypeScriptコード生成プロンプト {#typescript-code-generation-prompts}

IPv6およびIPv4アドレス形式を解析するユーティリティ関数を作成します。

```typescript
"use strict";
// Generate a TypeScript function which parses IPv6 and IPv4 address formats
// Use regular expressions
function parseAddress(address) {
    const ipv6Regex = /^(([0-9a-fA-F]{1,4}:){7,7}[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,7}:|([0-9a-fA-F]{1,4}:){1,6}:[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,5}(:[0-9a-fA-F]{1,4}){1,2}|([0-9a-fA-F]{1,4}:){1,4}(:[0-9a-fA-F]{1,4}){1,3}|([0-9a-fA-F]{1,4}:){1,3}(:[0-9a-fA-F]{1,4}){1,4}|([0-9a-fA-F]{1,4}:){1,2}(:[0-9a-fA-F]{1,4}){1,5}|[0-9a-fA-F]{1,4}:((:[0-9a-fA-F]{1,4}){1,6})|:((:[0-9a-fA-F]{1,4}){1,7}|:)|fe80:(:[0-9a-fA-F]{0,4}){0,4}%[0-9a-zA-Z]{1,}|::(ffff(:0{1,4}){0,1}:){0,1}((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])\.){3,3}(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])|([0-9a-fA-F]{1,4}:){1,4}:((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])\.){3,3}(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9]))$/;
    const ipv4Regex = /^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$/;
    if (ipv6Regex.test(address)) {
        return {
            ipVersion: 6,
            address
        };
    }
    else if (ipv4Regex.test(address)) {
        return {
            ipVersion: 4,
            address
        };
    }
    else {
        throw new Error('Invalid IP address');
    }
}
// Test the function with random inputs
const testInputs = [
    '2001:0db8:85a3:0000:0000:8a2e:0370:7334',
    '192.168.0.1',
    'not-an-ip'
];
for (const input of testInputs) {
    try {
        const result = parseAddress(input);
        console.log(result);
    }
    catch (error) {
        console.error(`Invalid address: ${input}`);
    }
}
```

AIによって生成されたソースコードの例は、[GitLab Duoプロンプトプロジェクトの`typescript`ディレクトリで確認できます](https://gitlab.com/gitlab-da/use-cases/ai/ai-workflows/gitlab-duo-prompts/-/tree/main/code-suggestions/typescript?ref_type=heads)。

## リソース {#resources}

多くのユースケースは、[GitLab Duo Coffee Chat YouTubeプレイリスト](https://www.youtube.com/playlist?list=PL05JrBw4t0Kp5uj_JgQiSvHw1jQu0mSVZ)で実践的な録画として利用できます。

### ブログリソース {#blog-resources}

以下のブログ投稿では、これらのユースケースのチュートリアルを提供しています:

- [AIを活用したGitLab Duoによる効率的なコード提案のヒント](https://about.gitlab.com/blog/2024/06/11/top-tips-for-efficient-ai-powered-code-suggestions-with-gitlab-duo/)
- [AI搭載のGitLab Duo Chatを使用するための10のベストプラクティス](https://about.gitlab.com/blog/2024/04/02/10-best-practices-for-using-ai-powered-gitlab-duo-chat/)。
- [GitLab Duo Chat 101: AIアシスタントでGitLabでの作業を効率化](https://about.gitlab.com/blog/2024/05/29/gitlab-duo-chat-101-get-more-done-on-gitlab-with-our-ai-assistant/)
- [GitLab Duoの開発: AI機能をどのようにドッグフーディングしているか](https://about.gitlab.com/blog/2024/05/20/developing-gitlab-duo-how-we-are-dogfooding-our-ai-features/)
- [GitLab Duoの開発: AIによって生成されたコードを安全かつ徹底的にテストする](https://about.gitlab.com/blog/2024/05/30/how-gitlab-duo-helps-secure-and-thoroughly-test-ai-generated-code/)
- [GitLab Duoの開発: CI/CDパイプラインを修正するためにAIと根本原因分析をブレンド](https://about.gitlab.com/blog/2024/06/06/developing-gitlab-duo-blending-ai-and-root-cause-analysis-to-fix-ci-cd/)
- [GitLab Duoの開発: AIインパクト分析ダッシュボードでAIのROIを測定](https://about.gitlab.com/blog/2024/05/15/developing-gitlab-duo-ai-impact-analytics-dashboard-measures-the-roi-of-ai/)

コード提案のチュートリアルブログ投稿は、次の言語で利用できます:

- [AIの助けを借りてRustを学ぶ](https://about.gitlab.com/blog/2023/08/10/learning-rust-with-a-little-help-from-ai-code-suggestions-getting-started/)
- [AIの助けを借りて高度なRustプログラミングを学ぶ](https://about.gitlab.com/blog/2023/10/12/learn-advanced-rust-programming-with-a-little-help-from-ai-code-suggestions/)
- [AIの助けを借りてPythonを学ぶ](https://about.gitlab.com/blog/2023/11/09/learning-python-with-a-little-help-from-ai-code-suggestions/)
- [GitLab Duoコード提案を使用して、Terraformプランをより迅速に作成する](https://about.gitlab.com/blog/2024/01/24/write-terraform-plans-faster-with-gitlab-duo-code-suggestions/)
- [ドラゴンの領域を調査: AIの助けを借りてC++アドベンチャーゲームをビルド](https://about.gitlab.com/blog/2023/08/24/building-a-text-adventure-using-cplusplus-and-code-suggestions/)
