---
stage: AI-powered
group: AI Model Validation
description: AI-powered features and functionality.
info: This page is maintained by Developer Relations, author @dnsmichi, see https://handbook.gitlab.com/handbook/marketing/developer-relations/developer-advocacy/content/#maintained-documentation
title: GitLab Duo use cases
---

The following use cases provide practical examples, exercises, and workflows with GitLab Duo.
Learn how to:

- Refactor existing source code.
- Use GitLab Duo Root Cause Analysis to troubleshoot failed jobs.
- Solve security vulnerabilities.

NOTE:
If you have GitLab Self-Managed: GitLab Duo requires GitLab 17.2 and later for the best user experience and results. Earlier versions may continue to work, however the experience may be degraded.

## Use GitLab Duo to solve development challenges

### Start with a C# application

In these examples, open your C# IDE, ensure that [GitLab Duo is enabled](turn_on_off.md),
and explore how to use GitLab Duo AI-powered features for more efficiency.

#### CLI tool for querying the GitLab REST API

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>
Watch the [GitLab Duo Coffee Chat: Get started with C#](https://www.youtube.com/watch?v=AdRtX9L--Po)
<!-- Video published on 2024-01-30 -->

The challenge is to create a CLI tool for querying the GitLab REST API.

- Ask GitLab Duo Chat how to start a new C# project and learn how to use the dotNET CLI:

  ```markdown
  How can I get started creating an empty C# console application in VS Code?
  ```

- Use Code Suggestions to generate a REST API client with a new code comment:

  ```csharp
  // Connect to a REST API and print the response
  ```

- The generated source code might need an explanation: Use the code task `/explain`
  to get an insight how the REST API calls work.

After the source code is generated from a Code Suggestions comment,
you need to configure CI/CD.

- Chat can help with best practices for a `.gitignore` file for C#:

  ```markdown
  Please show a .gitignore and .gitlab-ci.yml configuration for a C# project.
  ```

- If your CI/CD job fails, use Root Cause Analysis to [troubleshoot failed CI/CD jobs](../gitlab_duo_chat/examples.md#troubleshoot-failed-cicd-jobs-with-root-cause-analysis).
  Alternatively, you can copy the error message into
  GitLab Duo Chat, and ask for help:

  ```markdown
  Please explain the CI/CD error: The current .NET SDK does not support targeting
  .NET 8.0
  ```

- To create tests later, ask GitLab Duo to use the code task `/refactor` to refactor
  the selected code into a function.

- Chat can also explain programming language specific keywords and functions, or C#
  compiler errors.

  ```markdown
  Can you explain async and await in C# with practical examples?

  explain error CS0122: 'Program' is inaccessible due to its protection level
  ```

- Generate tests by using the `/tests` code task.

The next question is where to put the generated tests in C# solutions.
As a beginner, you might not know that the application and test projects must exist on the same
solutions level to avoid import problems.

- GitLab Duo Chat can help by asking and refining the prompt questions:

  ```markdown
  In C# and VS Code, how can I add a reference to a project from a test project?

  Please provide the XML configuration which I can add to a C# .csproj file to add a
  reference to another project in the existing solution?
  ```

- Sometimes, you must refine the prompt to get better results. The prompt
  `/refactor into the public class` creates a proposal for code that can be accessed
  from the test project later.

  ```markdown
  /refactor into the public class
  ```

- You can also use the `/refactor` code task to ask Chat how to execute tests in the
  `.gitlab-ci.yml` file.

  ```markdown
  /refactor add a job to run tests (the test project)
  ```

Resources:

- [Project with source code](https://gitlab.com/gitlab-da/use-cases/ai/gitlab-duo-coffee-chat/gitlab-duo-coffee-chat-2024-01-29)

### Improve a C++ application

#### Refactor a C++ application with SQLite

In this example, existing source code with a single main function exists. It repeats code, and cannot be tested.

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>
Watch the [GitLab Duo Coffee Chat: C++, SQLite and CMake](https://www.youtube.com/watch?v=zGOo1jzQ5zM)
<!-- Video published on 2024-01-10 -->

To refactor the source code into reusable and testable functions:

1. Open VS Code or the Web IDE with GitLab Duo enabled.
1. Select the source code, and use a refined prompt to ask GitLab Duo Chat to refactor it into functions:

   ```markdown
   /refactor into functions
   ```

   This refactoring step might not work for the entire selected source code.

1. Split the refactoring strategy into functional blocks.
   For example, iterate on all insert, update, and delete operations in the database.

1. To generate tests for the newly created functions, select the source code again and
   use the code task `/tests`. Include a specific prompt of instructions for the test framework:

   ```markdown
   /tests using the CTest test framework
   ```

1. If your application uses the `Boost.Test` framework instead, refine the prompt:

   ```markdown
   /tests using the Boost.Test framework
   ```

Resources:

- [Project with source code](https://gitlab.com/gitlab-da/use-cases/ai/gitlab-duo-coffee-chat/gitlab-duo-coffee-chat-2024-01-09)

#### Refactor C++ functions into object-oriented code

In this example, existing source code has been wrapped into functions.
To support more database types in the future, the code must be refactored into classes and object inheritance.

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>
Watch the walkthrough of these steps in [GitLab Duo Coffee Chat: Refactor C++ functions into `OOP` classes](https://www.youtube.com/watch?v=Z9EJh0J9358)
<!-- Video published on 2024-01-24 -->

##### Start working on the class

- Ask GitLab Duo Chat how to implement an object-oriented pattern for a base database class and inherit it in a SQLite class:

  ```markdown
  Explain a generic database implementation using a base class, and SQLite specific class using C++. Provide source examples and steps to follow.
  ```

- The learning curve includes asking GitLab Duo Chat about pure virtual functions and virtual function overrides in the implementation class.

  ```markdown
  What is a pure virtual function, and what is required for the developer inheriting from that class?
  ```

- Code tasks can help refactoring the code. Select the functions in the C++ header file, and use a refined prompt:

  ```markdown
  /refactor into class with public functions, and private path/db attributes. Inherit from the base class DB

  /refactor into a base class with pure virtual functions called DB. Remote the SQLite specific parts.
  ```

- GitLab Duo Chat also guides with constructor overloading, object initialization, and optimized memory management with shared pointers.

  ```markdown
  How to add a function implementation to a class in a cpp file?

  How to pass values to class attributes through the class constructor call?
  ```

##### Find better answers

- The following question did not provide enough context.

  ```markdown
  Should I use virtual override instead of just override?
  ```

- Instead, try to add more context to get better answers.

  ```markdown
  When implementing a pure virtual function in an inherited class, should I use virtual function override, or just function override? Context is C++.
  ```

- A relatively complex question involves how to instantiate an object from the newly created class, and call specific functions.

  ```markdown
  How to instantiate an object from a class in C++, call the constructor with the SQLite DB path and call the functions. Prefer pointers.
  ```

- The result can be helpful, but needed refinements for shared pointers and required source code headers.

  ```markdown
  How to instantiate an object from a class in C++, call the constructor with the SQLite DB path and call the functions. Prefer shared pointers. Explain which header includes are necessary.
  ```

- Code Suggestions helps generate the correct syntax for `std::shared_ptr` pointer arithmetic and help improve the code quality.

  ```cpp
  // Define the SQLite path in a variable, default value database.db

  // Create a shared pointer for the SQLite class

  // Open a database connection using OpenConnection
  ```

##### Refactor your code

- After refactoring the source code, compiler errors may occur. Ask Chat to explain them.

  ```markdown
  Explain the error: `db` is a private member of `SQLiteDB`
  ```

- A specific SQL query string should be refactored into a multi-line string for more efficient editing.

  ```cpp
  std::string sql = "CREATE TABLE IF NOT EXISTS users (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, email TEXT NOT NULL)";
  ```

- Select the source code, and use the `/refactor` code task:

  ```markdown
  /refactor into a stringstream with multiple lines
  ```

- You can also refactor utility functions into a class with static functions in C++ and then ask Chat how to call them.

  ```markdown
  /refactor into a class providing static functions

  How to call the static functions in the class?
  ```

After refactoring the source code, the foundation for more database types is built, and overall code quality improved.

Resources:

- [Project with source code](https://gitlab.com/gitlab-da/use-cases/ai/gitlab-duo-coffee-chat/gitlab-duo-coffee-chat-2024-01-23)

### Explain, test, and refactor a Kotlin application

In this example, the adventure application from the [Kotlin Code Generation prompts](use_cases.md#kotlin-code-generation-prompts)
must be analyzed, and improved with refactoring and tests.

The current source code looks like this:

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

1. Select the source code in the IDE, then right-click for GitLab Duo Chat to explain the code.
1. Refine the prompts to learn more about bugs, optimization tips, or vulnerabilities:

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

1. Use the `/tests` command to ask Chat to generate tests for the selected code:

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

After you ensure that everything is tested, ask Chat to refactor the selected code:

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

The refactored source code can look like this:

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

### Get Started with PowerShell

NOTE:
PowerShell support is [experimental](../project/repository/code_suggestions/supported_extensions.md#add-support-for-more-languages).

1. Use GitLab Duo Chat to ask how to get started with a PowerShell script that prints the file size of the current directory.

   ```markdown
   How to get started with a PowerShell script that prints the file size of the current directory?
   ```

   Alternatively, you can use Code Suggestions to generate the source code.

1. Create a new script `get-file-sizes.ps1` with the following content:

   ```powershell
   # Collect the files in a directory and print their size
   ```

1. Wait for Code Suggestions to complete the prompt, and then add the following prompts to
experiment with different output formats:

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

1. Repeat the steps with prompts for different export formats,
or use Code Suggestions auto-complete. For example:

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

## Explain and resolve vulnerabilities

### Vulnerabilities in C code

In this example, detected security vulnerabilities in C should be fixed with the help from GitLab Duo.

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>
Watch the walkthrough of these steps [GitLab Duo Coffee Chat: Vulnerability Resolution Challenge #1](https://www.youtube.com/watch?v=Ypwx4lFnHP0)
<!-- Video published on 2024-01-30 -->

[This source code snippet](https://gitlab.com/gitlab-da/use-cases/ai/gitlab-duo-coffee-chat/gitlab-duo-coffee-chat-2024-01-30/-/blob/4685e4e1c658565ae956ad9befdfcc128e60c6cf/src/main-vulnerable-source.c)
introduces a security vulnerability with a [buffer overflow](https://en.wikipedia.org/wiki/Buffer_overflow):

```c
    strcpy(region, "Hello GitLab Duo Vulnerability Resolution challenge");

    printf("Contents of region: %s\n", region);
```

[SAST security scanners](../application_security/sast/analyzers.md) can detect and report the problem. Use [Vulnerability Explanation](../application_security/vulnerabilities/_index.md#explaining-a-vulnerability) to understand the problem.
Vulnerability Resolution helps to generate an MR.
If the suggested changes do not fit requirements, or might lead to problems, you can use Code Suggestions and Chat to refine. For example:

1. Open VS Code or the Web IDE with GitLab Duo enabled, and add a comment with instructions:

   ```c
       // Avoid potential buffer overflows

       // Possible AI-generated code below
       strncpy(region, "Hello GitLab Duo Vulnerability Resolution challenge", pagesize);
       region[pagesize-1] = '\0';
       printf("Contents of region: %s\n", region);
   ```

1. Delete the suggested code, and use a different comment to use an alternative method.

   ```c
       // Avoid potential buffer overflows using snprintf()

       // Possible AI-generated code below
       snprintf(region, pagesize, "Hello GitLab Duo Vulnerability Resolution challenge");

       printf("Contents of region: %s\n", region);
   ```

1. Use GitLab Duo Chat to ask questions. The `/refactor` code task can generate different suggestions.
   If you prefer a specific algorithm or function, refine the prompt:

   ```markdown
   /refactor using snprintf
   ```

Resources:

- Project with source code: [GitLab Duo Coffee Chat 2024-01-30 - Vulnerability Resolution Challenge](https://gitlab.com/gitlab-da/use-cases/ai/gitlab-duo-coffee-chat/gitlab-duo-coffee-chat-2024-01-30)

## Answer questions about GitLab

In this example, the challenge is to use GitLab Duo Chat to solve problems.

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>
Watch the walkthrough of these steps in [GitLab Duo Coffee Chat: Solve problems with GitLab Duo Chat Challenge](https://www.youtube.com/watch?v=Ypwx4lFnHP0)
<!-- Video published on 2024-02-02 -->

- You can use GitLab Duo Chat to explain CI/CD errors.

  ```markdown
  Explain this CI/CD error: build.sh: line 14: go command not found
  ```

- What happens when you are impatient, and input just one or two words?

  ```markdown
  labels

  issue labels
  ```

  GitLab Duo Chat asks for more context.

- Refine your question into a full sentence, describing the problem and asking for a solution.

  ```markdown
  Explain labels in GitLab. Provide an example for efficient usage.
  ```

Resources:

- [Project with source code](https://gitlab.com/gitlab-da/use-cases/ai/gitlab-duo-coffee-chat/gitlab-duo-coffee-chat-2024-02-01)

## Root Cause Analysis use cases

Use Root Cause Analysis to determine the root cause of a CI/CD
job failure. The following examples illustrate common errors, and
encourage you to fork and practice finding and fixing the root cause.

For more information, see the blog post [Developing GitLab Duo: Blending AI and Root Cause Analysis to fix CI/CD pipelines](https://about.gitlab.com/blog/2024/06/06/developing-gitlab-duo-blending-ai-and-root-cause-analysis-to-fix-ci-cd/).

### Analyze missing Go runtime

CI/CD jobs can be executed in containers, spawned from the contributed `image`
attribute. If the container does not provide a programming language runtime,
the executed `script` sections that reference the `go` binary fail. For example,
the error message `/bin/sh: eval: line 149: go: not found` must be understood
and fixed. If the `go` command is not found in the container's runtime context,
it might be due to multiple reasons:

- The job uses a minimal container image like `alpine`, and the Go language
runtime was not installed.
- The job uses the wrong default container image specified in
the CI/CD configuration, or uses the `default` keyword.
- The job uses the shell executor instead of the container image. The host operating
system is broken, doesn't have the Go language runtime installed, or is not
configured.

The project [Challenge: Root Cause Analysis - Go GitLab Release Fetcher](https://gitlab.com/gitlab-da/use-cases/ai/ai-workflows/gitlab-duo-challenges/root-cause-analysis/challenge-root-cause-analysis-go-gitlab-release-fetcher)
provides an exercise to analyze and fix CI/CD problems with a Go Tanuki app. In this exercise,
the `build` and `docker-build` jobs are failing. When you have fixed
the problem, the CI/CD pipeline succeeds and the `build` job prints an output.
The `solution/` directory provides two possible solutions.

## Use GitLab Duo to contribute to GitLab

GitLab Duo usage focuses on contributing to the GitLab codebase, and how customers can contribute more efficiently.

The GitLab codebase is large, and requires to understand sometimes complex algorithms or application specific implementations.
Review the [architecture components](../../development/architecture.md) to learn more.

### Contribute to frontend: Profile Settings

In this example, the challenge is to update the GitLab profile page and improve the social networks settings.

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>
Watch the recording here: [GitLab Duo Coffee Chat: Contribute to GitLab using Code Suggestions and Chat](https://www.youtube.com/watch?v=TauP7soXj-E)
<!-- Video published on 2024-02-23 -->

You can use GitLab Duo Chat to explain and refactor code, and generate tests.
Code Suggestions help complete existing code, and can generate new functions and algorithms in Ruby, Go, or VueJS.

1. Use the `/explain` code task to explain selected code sections, and learn how the HAML templates work.
1. You can refine the code task prompts, and instead ask `/explain how HAML rendering works`

Alternatively, you can write in the chat prompt directly, for example:

```markdown
how to populate a select in haml
```

The refactoring examples involve the following:

1. `/refactor into a HAML dropdown`
1. After inspecting the existing UI form code, refine the prompt to `/refactor into a HAML dropdown with a form select`

GitLab Duo Chat helped with error debugging, prefixing the error message:

```markdown
please explain this error: undefined method `icon` for
```

## Code generation prompts

The following examples provide [code generation](../project/repository/code_suggestions/_index.md#best-practices-for-code-generation)
prompts for the [supported languages](../project/repository/code_suggestions/supported_extensions.md) in GitLab Duo.
You can use multi-line comments to refine code generation prompts.

The examples are stored in the [GitLab Duo Prompts project](https://gitlab.com/gitlab-da/use-cases/ai/ai-workflows/gitlab-duo-prompts),
maintained by the Developer Relations team. These examples are tested working. You should review and adapt them for your environment.

### C code generation prompts

Create a Linux statistics tool that collects I/O, performance, disk usage, and TCP latency
and prints their output. For a full example, see the blog post [Top tips for efficient AI-powered Code Suggestions with GitLab Duo blog post](https://about.gitlab.com/blog/2024/06/11/top-tips-for-efficient-ai-powered-code-suggestions-with-gitlab-duo/#code-suggestions-flow-with-comments).

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

The AI-generated source code examples are available in the [`c` directory in the GitLab Duo Prompts project](https://gitlab.com/gitlab-da/use-cases/ai/ai-workflows/gitlab-duo-prompts/-/tree/main/code-suggestions/c?ref_type=heads).

### C++ code generation prompts

Create a CLI application that acts as HTTP client.

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

Create an application to manage distributed file nodes.

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

Create an eBPF program which attaches to `XDP` kernel events to measure network traffic.
Only works on Linux kernels.

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

The AI-generated source code examples are available in the [`c++` directory in the GitLab Duo Prompts project](https://gitlab.com/gitlab-da/use-cases/ai/ai-workflows/gitlab-duo-prompts/-/tree/main/code-suggestions/c%2B%2B?ref_type=heads).

### `C#` code generation prompts

Create a medical analyzer app from different sensors, and store the data in `MSSQL`.

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

The AI-generated source code examples are available in the [`c#` directory in the GitLab Duo Prompts project](https://gitlab.com/gitlab-da/use-cases/ai/ai-workflows/gitlab-duo-prompts/-/tree/main/code-suggestions/c%23?ref_type=heads).

### CSS code generation prompts

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

The AI-generated source code examples are available in the [`css` directory in the GitLab Duo Prompts project](https://gitlab.com/gitlab-da/use-cases/ai/ai-workflows/gitlab-duo-prompts/-/tree/main/code-suggestions/css?ref_type=heads).

### Go code generation prompts

Create an observability application for Kubernetes which reads and prints the state of containers, pods, and services in the cluster.

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

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>
Watch the recording here: [GitLab Duo Coffee Chat: Code Generation Challenge with Go and Kubernetes Observability](https://www.youtube.com/watch?v=ORpRqp-A9hQ)
<!-- Video published on 2024-03-27. Maintainer: Developer Relations. -->

Create an in-memory key value store, similar to Redis. For a complete walkthrough, see the
blog post, [Top tips for efficient AI-powered Code Suggestions with GitLab Duo](https://about.gitlab.com/blog/2024/06/11/top-tips-for-efficient-ai-powered-code-suggestions-with-gitlab-duo/#iterate-faster-with-code-generation)
blog post.

```go
// Create an in-memory key value store, similar to Redis
// Provide methods to
// set/unset keys
// update values
// list/print with filters
// Use BoltDB as external library
```

The AI-generated source code examples are available in the [`go` directory in the GitLab Duo Prompts project](https://gitlab.com/gitlab-da/use-cases/ai/ai-workflows/gitlab-duo-prompts/-/tree/main/code-suggestions/go?ref_type=heads).

### Java code generation prompts

Create a data analytics application, with different data sources for metrics.
Provide an API for data queries and aggregation.

```java
// Create a data analytics app
// Parse different input sources and their values
// Store the metrics in a columnar format
// Provide an API to query and aggregate data
```

The AI-generated source code examples are available in the [`java` directory in the GitLab Duo Prompts project](https://gitlab.com/gitlab-da/use-cases/ai/ai-workflows/gitlab-duo-prompts/-/tree/main/code-suggestions/java?ref_type=heads).

### JavaScript code generation prompts

Create a paid-time-off application for employees in ReactJS, with a date-time picker.

```javascript
// Create a Paid Time Off app for users
// Create a date-time picker in ReactJS
// Provide start and end options
// Show public holidays based on the selected country
// Send the request to a server API
```

The AI-generated source code examples are available in the [`javascript` directory in the GitLab Duo Prompts project](https://gitlab.com/gitlab-da/use-cases/ai/ai-workflows/gitlab-duo-prompts/-/tree/main/code-suggestions/javascript).

### HTML code generation prompts

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

The AI-generated source code examples are available in the [`html` directory in the GitLab Duo Prompts project](https://gitlab.com/gitlab-da/use-cases/ai/ai-workflows/gitlab-duo-prompts/-/tree/main/code-suggestions/html).

### Kotlin code generation prompts

Generate a text adventure and search for a treasure. Add visual helpers and use random timer traps for game over.

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

The AI-generated source code examples are available in the [`kotlin` directory in the GitLab Duo Prompts project](https://gitlab.com/gitlab-da/use-cases/ai/ai-workflows/gitlab-duo-prompts/-/tree/main/code-suggestions/kotlin?ref_type=heads).

### PHP code generation prompts

Create an RSS feed fetcher for GitLab releases, allow filtering by title.

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

The AI-generated source code examples are available in the [`php` directory in the GitLab Duo Prompts project](https://gitlab.com/gitlab-da/use-cases/ai/ai-workflows/gitlab-duo-prompts/-/tree/main/code-suggestions/php).

### PowerShell code generation prompts

Create a script which collects all files in a directory and prints their size.
Refine the prompt to store the results in a CSV or JSON file.

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

The AI-generated source code examples are available in the [`powershell` directory in the GitLab Duo Prompts project](https://gitlab.com/gitlab-da/use-cases/ai/ai-workflows/gitlab-duo-prompts/-/tree/main/code-suggestions/powershell?ref_type=heads).

### Python code generation prompts

Create a webserver using Flask to manage users using the REST API, store them in SQLite.

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

The AI-generated source code examples are available in the [`python` directory in the GitLab Duo Prompts project](https://gitlab.com/gitlab-da/use-cases/ai/ai-workflows/gitlab-duo-prompts/-/tree/main/code-suggestions/python?ref_type=heads).

### Ruby code generation prompts

Create a log parser application which stores log data in Elasticsearch.

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

Create a log client utility class that supports the syslog format with
severity levels, application name and message string.

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

The AI-generated source code examples are available in the [`ruby` directory in the GitLab Duo Prompts project](https://gitlab.com/gitlab-da/use-cases/ai/ai-workflows/gitlab-duo-prompts/-/tree/main/code-suggestions/ruby).

### Rust code generation prompts

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

Create an RSS feed reader app, example from the blog post [Learn advanced Rust programming with a little help from AI](https://about.gitlab.com/blog/2023/10/12/learn-advanced-rust-programming-with-a-little-help-from-ai-code-suggestions/).

```rust
    // Create a function that iterates over the source array
    // and fetches the data using HTTP from the RSS feed items.
    // Store the results in a new hash map.
    // Print the hash map to the terminal.
```

The AI-generated source code examples are available in the [`rust` directory in the GitLab Duo Prompts project](https://gitlab.com/gitlab-da/use-cases/ai/ai-workflows/gitlab-duo-prompts/-/tree/main/code-suggestions/rust?ref_type=heads).

### Scala code generation prompts

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

The AI-generated source code examples are available in the [`scala` directory in the GitLab Duo Prompts project](https://gitlab.com/gitlab-da/use-cases/ai/ai-workflows/gitlab-duo-prompts/-/tree/main/code-suggestions/scala?ref_type=heads).

### Shell scripts code generation prompts

Create a script `mytop.sh` that displays the top 10 processes by CPU, memory and disk I/O usage.
Start with the first code comment, and let Code Suggestions generate everything else.

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

The AI-generated source code examples are available in the [`shell` directory in the GitLab Duo Prompts project](https://gitlab.com/gitlab-da/use-cases/ai/ai-workflows/gitlab-duo-prompts/-/tree/main/code-suggestions/shell?ref_type=heads).

### TypeScript code generation prompts

Create a utility function that parses IPv6 and IPv4 address formats.

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

The AI-generated source code examples are available in the [`typescript` directory in the GitLab Duo Prompts project](https://gitlab.com/gitlab-da/use-cases/ai/ai-workflows/gitlab-duo-prompts/-/tree/main/code-suggestions/typescript?ref_type=heads).

## Resources

Many of the use cases are available as hands-on recordings in the [GitLab Duo Coffee Chat YouTube playlist](https://www.youtube.com/playlist?list=PL05JrBw4t0Kp5uj_JgQiSvHw1jQu0mSVZ).
The [GitLab Duo Coffee Chat](https://handbook.gitlab.com/handbook/marketing/developer-relations/developer-advocacy/projects/#gitlab-duo-coffee-chat) is a learning series maintained by the [Developer Relations team](https://handbook.gitlab.com/handbook/marketing/developer-relations/).

### Blog resources

The following blog posts provide tutorials for these use cases:

- [Top tips for efficient AI-powered Code Suggestions with GitLab Duo](https://about.gitlab.com/blog/2024/06/11/top-tips-for-efficient-ai-powered-code-suggestions-with-gitlab-duo/)
- [10 best practices for using AI-powered GitLab Duo Chat](https://about.gitlab.com/blog/2024/04/02/10-best-practices-for-using-ai-powered-gitlab-duo-chat/)
- [GitLab Duo Chat 101: Get more done on GitLab with our AI assistant](https://about.gitlab.com/blog/2024/05/29/gitlab-duo-chat-101-get-more-done-on-gitlab-with-our-ai-assistant/)
- [Developing GitLab Duo: How we are dogfooding our AI features](https://about.gitlab.com/blog/2024/05/20/developing-gitlab-duo-how-we-are-dogfooding-our-ai-features/)
- [Developing GitLab Duo: Secure and thoroughly test AI-generated code](https://about.gitlab.com/blog/2024/05/30/how-gitlab-duo-helps-secure-and-thoroughly-test-ai-generated-code/)
- [Developing GitLab Duo: Blending AI and Root Cause Analysis to fix CI/CD pipelines](https://about.gitlab.com/blog/2024/06/06/developing-gitlab-duo-blending-ai-and-root-cause-analysis-to-fix-ci-cd/)
- [Developing GitLab Duo: AI Impact analytics dashboard measures the ROI of AI](https://about.gitlab.com/blog/2024/05/15/developing-gitlab-duo-ai-impact-analytics-dashboard-measures-the-roi-of-ai/)

Code Suggestions tutorial blog posts are available for the following languages:

- [Learning Rust with a little help from AI](https://about.gitlab.com/blog/2023/08/10/learning-rust-with-a-little-help-from-ai-code-suggestions-getting-started/)
- [Learn advanced Rust programming with a little help from AI](https://about.gitlab.com/blog/2023/10/12/learn-advanced-rust-programming-with-a-little-help-from-ai-code-suggestions/)
- [Learning Python with a little help from AI](https://about.gitlab.com/blog/2023/11/09/learning-python-with-a-little-help-from-ai-code-suggestions/)
- [Write Terraform plans faster with GitLab Duo Code Suggestions](https://about.gitlab.com/blog/2024/01/24/write-terraform-plans-faster-with-gitlab-duo-code-suggestions/)
- [Explore the Dragon Realm: Build a C++ adventure game with a little help from AI](https://about.gitlab.com/blog/2023/08/24/building-a-text-adventure-using-cplusplus-and-code-suggestions/)
