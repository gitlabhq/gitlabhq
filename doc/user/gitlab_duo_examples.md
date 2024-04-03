---
stage: AI-powered
group: Duo Chat
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# GitLab Duo examples

The following use cases describe practical examples with GitLab Duo.
Learn how to start with software development and refactor existing source code.
Dive into debugging problems with root cause analysis, solve security vulnerabilities,
and use all stages of the DevSecOps lifecycle.

## Use GitLab Duo to solve development challenges

### Start with a C# application

In this example, open your C# application and start to explore how to use
GitLab Duo AI-powered features for more efficiency.

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>
Watch these steps in action in [GitLab Duo Coffee Chat: Get started with C#](https://www.youtube.com/watch?v=AdRtX9L--Po)
<!-- Video published on 2024-01-30 -->

The challenge is to create a CLI tool for querying the GitLab REST API.

- Ask GitLab Duo Chat how to start a new C# project and learn how to use the dotNET CLI:

  ```markdown
  How can I get started creating an empty C# console application in VSCode?
  ```

- Use Code Suggestions to generate a REST API client with a new code comment:

  ```csharp
  // Connect to a REST API and print the response
  ```

- The generated source code might need an explanation: Use the code task `/explain`
  to get an insight how the REST API calls work.

After successfully generating the source code from a Code Suggestions comment,
CI/CD configuration is needed.

- Chat can help with best practices for a `.gitignore` file for C#:

  ```markdown
  Please show a .gitignore and .gitlab-ci.yml configuration for a C# project.
  ```

- If your CI/CD job fails, [Root Cause Analysis](ai_features.md#root-cause-analysis)
  can help understand the problem. Alternatively, you can copy the error message into
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
As a beginner, you might not know that the application and test projects need to exist on the same solutions level to avoid import problems.

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

### Refactor a C++ application with SQLite

In this example, existing source code with a single main function exists. It repeats code, and cannot be tested.

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>
Watch these steps in action in [GitLab Duo Coffee Chat: C++, SQLite and CMake](https://www.youtube.com/watch?v=zGOo1jzQ5zM)
<!-- Video published on 2024-01-10 -->

Refactoring the source code into reusable and testable functions is a great first step.

1. Open VS Code or the Web IDE with GitLab Duo enabled.
1. Select the source code, and ask GitLab Duo Chat to refactor it into functions, using a refined prompt:

   ```markdown
   /refactor into functions
   ```

   This refactoring step might not work for the entire selected source code.

1. Split the refactoring strategy into functional blocks.
   For example, iterate on all insert, update, and delete operations in the database.

1. The next step is to generate tests for the newly created functions. Select the source code again.
   You can use the code task `/tests` with specific prompt instructions for the test framework:

   ```markdown
   /tests using the CTest test framework
   ```

1. If your application uses the `Boost.Test` framework instead, refine the prompt:

   ```markdown
   /tests using the Boost.Test framework
   ```

Resources:

- [Project with source code](https://gitlab.com/gitlab-da/use-cases/ai/gitlab-duo-coffee-chat/gitlab-duo-coffee-chat-2024-01-09)

### Refactor C++ functions into object-oriented code

In this example, existing source code has been wrapped into functions.
To support more database types in the future, the code needs to be refactored into classes and object inheritance.

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>
Watch these steps in action in [GitLab Duo Coffee Chat: Refactor C++ functions into `OOP` classes](https://www.youtube.com/watch?v=Z9EJh0J9358)
<!-- Video published on 2024-01-24 -->

#### Start working on the class

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

#### Find better answers

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

- Code Suggestions help generate the correct syntax for `std::shared_ptr` pointer arithmetic and help improve the code quality.

  ```cpp
  // Define the SQLite path in a variable, default value database.db

  // Create a shared pointer for the SQLite class

  // Open a database connection using OpenConnection
  ```

#### Refactor your code

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

## Explain and resolve vulnerabilities

In this example, detected security vulnerabilities in C should be fixed with the help from GitLab Duo.

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>
Watch the [GitLab Duo Coffee Chat: Vulnerability Resolution Challenge #1](https://www.youtube.com/watch?v=Ypwx4lFnHP0)
<!-- Video published on 2024-01-30 -->

[This source code snippet](https://gitlab.com/gitlab-da/use-cases/ai/gitlab-duo-coffee-chat/gitlab-duo-coffee-chat-2024-01-30/-/blob/4685e4e1c658565ae956ad9befdfcc128e60c6cf/src/main-vulnerable-source.c)
introduces a security vulnerability with a [buffer overflow](https://en.wikipedia.org/wiki/Buffer_overflow):

```c
    strcpy(region, "Hello GitLab Duo Vulnerability Resolution challenge");

    printf("Contents of region: %s\n", region);
```

[SAST security scanners](application_security/sast/analyzers.md) can detect and report the problem. Use [Vulnerability Explanation](application_security/vulnerabilities/index.md#explaining-a-vulnerability) to understand the problem.
[Vulnerability resolution](application_security/vulnerabilities/index.md#vulnerability-resolution) helps to generate an MR.
If the suggested changes do not fit requirements, or would otherwise lead to problems, you can use [Code Suggestions](project/repository/code_suggestions/index.md) and [Chat](gitlab_duo_chat.md) to refine. For example:

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

1. In addition, use GitLab Duo Chat to ask questions. The `/refactor` code task can generate different suggestions.
   If you prefer a specific algorithm or function, refine the prompt:

   ```markdown
   /refactor using snprintf
   ```

Resources:

- Project with source code: [GitLab Duo Coffee Chat 2024-01-30 - Vulnerability Resolution Challenge](https://gitlab.com/gitlab-da/use-cases/ai/gitlab-duo-coffee-chat/gitlab-duo-coffee-chat-2024-01-30)

### Answer questions about GitLab

In this example, the challenge is exploring the GitLab Duo Chat Beta to solve problems.

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>
Watch the recording here: [GitLab Duo Coffee Chat: Solve problems with GitLab Duo Chat Beta Challenge](https://www.youtube.com/watch?v=Ypwx4lFnHP0)
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

## Use GitLab Duo to contribute to GitLab

GitLab Duo usage focuses on contributing to the GitLab codebase, and how customers can contribute more efficiently.

The GitLab codebase is large, and requires to understand sometimes complex algorithms or application specific implementations.
Review the [architecture components](../development/architecture.md) to learn more.

### Contribute to frontend: Profile Settings

In this example, the challenge was to update the GitLab profile page and improve the social networks settings.

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>
Watch the recording here: [GitLab Duo Coffee Chat: Contribute to GitLab using Code Suggestions and Chat](https://www.youtube.com/watch?v=TauP7soXj-E)
<!-- Video published on 2024-02-23 -->

GitLab Duo Chat can be helpful to explain and refactor code, and generate tests.
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

The following examples provide helpful [code generation](project/repository/code_suggestions/index.md#best-practices)
prompts for the [supported languages](project/repository/code_suggestions/supported_extensions.md) in GitLab Duo.
Code generation prompts can be refined using multi-line comments.

The examples are stored in the [GitLab Duo Prompts project](https://gitlab.com/gitlab-da/use-cases/ai/ai-workflows/gitlab-duo-prompts), maintained by the Developer Relations team.

### C++ code generation prompts

Create an application to manage distributed file nodes.

```c++
// Create an application to manage distributed file nodes
// Provide an overview the health state of nodes
// Use OOP patterns to define the base file node
// Add specific filesystems inherited from the base file
```

Create an eBPF program which attaches to `XDP` kernel events to measure network traffic.
Only works on Linux kernels.

```c++
// Create an eBPF program which attaches to XDP kernel events
// Count all packets by IP address
// Print a summary
// Include necessary headers
```

### `C#` code generation prompts

Create a medical analyzer app from different sensors, and store the data in `MSSQL`.

```c#
// Create a medical analyzer app
// Collect data from different sensors
// Store data in MSSQL
// Provide methods to access the sensor data
```

### Go code generation prompts

Create an observability application for Kubernetes which reads and prints the state of containers, pods, and services in the cluster.

```go
// Create a client for Kubernetes observability
// Create a function that
// Read the kubernetes configuration file from the KUBECONFIG env var
// Create kubernetes context, namespace default
// Inspect container, pod, service status and print an overview
// Import necessary packages
// Create main package
```

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>
Watch the recording here: [GitLab Duo Coffee Chat: Code Generation Challenge with Go and Kubernetes Observability](https://www.youtube.com/watch?v=ORpRqp-A9hQ)
<!-- Video published on 2024-03-27. Maintainer: Developer Relations. -->

### Java code generation prompts

Create a data analytics application, with different data sources for metrics.
Provide an API for data queries and aggregation.

```java
// Create a data analytics app
// Parse different input sources and their values
// Store the metrics in a columnar format
// Provide an API to query and aggregate data
```

### JavaScript code generation prompts

Create a paid-time-off application for employees in ReactJS, with a date-time picker.

```javascript
// Create a Paid Time Off app for users
// Create a date-time picker in ReactJS
// Provide start and end options
// Show public holidays based on the selected country
// Send the request to a server API
```

### PHP code generation prompts

Create an RSS feed fetcher for GitLab releases, allow filtering by title.

```php
// Create a web form to show GitLab releases
// Fetch the RSS feed from https://about.gitlab.com/atom.xml
// Provide filter options for the title
```

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
```

### Ruby code generation prompts

Create a log parser application which stores log data in Elasticsearch.

```ruby
# Create a Ruby app as log parser
# Provide hooks to replace sensitive strings in log lines
# Format the logs and store them in Elasticsearch
```

### Rust code generation prompts

Create an RSS feed reader app, example from the blog post [Learn advanced Rust programming with a little help from AI](https://about.gitlab.com/blog/2023/10/12/learn-advanced-rust-programming-with-a-little-help-from-ai-code-suggestions/).

```rust
    // Create a function that iterates over the source array
    // and fetches the data using HTTP from the RSS feed items.
    // Store the results in a new hash map.
    // Print the hash map to the terminal.
```

## Resources

Many of the use cases are available as hands-on recordings in the [GitLab Duo Coffee Chat YouTube playlist](https://www.youtube.com/playlist?list=PL05JrBw4t0Kp5uj_JgQiSvHw1jQu0mSVZ).
The [GitLab Duo Coffee Chat](https://handbook.gitlab.com/handbook/marketing/developer-relations/developer-advocacy/projects/#gitlab-duo-coffee-chat) is a learning series maintained by the [Developer Relations team](https://handbook.gitlab.com/handbook/marketing/developer-relations/).

### Blog resources

- [10 best practices for using AI-powered GitLab Duo Chat](https://about.gitlab.com/blog/2024/04/02/10-best-practices-for-using-ai-powered-gitlab-duo-chat/)
- [Learning Rust with a little help from AI](https://about.gitlab.com/blog/2023/08/10/learning-rust-with-a-little-help-from-ai-code-suggestions-getting-started/)
- [Learn advanced Rust programming with a little help from AI](https://about.gitlab.com/blog/2023/10/12/learn-advanced-rust-programming-with-a-little-help-from-ai-code-suggestions/)
- [Learning Python with a little help from AI](https://about.gitlab.com/blog/2023/11/09/learning-python-with-a-little-help-from-ai-code-suggestions/)
- [Write Terraform plans faster with GitLab Duo Code Suggestions](https://about.gitlab.com/blog/2024/01/24/write-terraform-plans-faster-with-gitlab-duo-code-suggestions/)
- [Explore the Dragon Realm: Build a C++ adventure game with a little help from AI](https://about.gitlab.com/blog/2023/08/24/building-a-text-adventure-using-cplusplus-and-code-suggestions/)
- [GitLab uses Anthropic for smart, safe AI-assisted code generation](https://about.gitlab.com/blog/2024/01/16/gitlab-uses-anthropic-for-smart-safe-ai-assisted-code-generation/)
