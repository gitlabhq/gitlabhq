---
stage: none
group: unassigned
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/development/development_processes/#development-guidelines-review.
title: Secure coding development guidelines
---

This document contains descriptions and guidelines for secure Go programming practices commonly needed in the GitLab codebase. These guidelines are intended to help developers write secure Go code from the start, identify potential security vulnerabilities early in the development process, and follow Go-specific best practices. By adhering to these standards, we aim to reduce the number of security vulnerabilities released over time while leveraging Go's built-in security features effectively.

## Regular Expressions guidelines

### Escape sequences in Go

When a character in a string literal or regular expression literal is preceded by a backslash, it is interpreted as part of an escape sequence. For example, the escape sequence `\n` in a string literal corresponds to a single `newline` character, and not the ` \ ` and `n` characters.

There are two Go escape sequences that could produce surprising results. First, `regexp.Compile("\a")` matches the bell character, whereas `regexp.Compile("\\A")` matches the start of text and `regexp.Compile("\\a")` is a Vim (but not Go) regular expression matching any alphabetic character. Second, `regexp.Compile("\b")` matches a backspace, whereas `regexp.Compile("\\b")` matches the start of a word. Confusing one for the other could lead to a regular expression passing or failing much more often than expected, with potential security consequences.

#### Examples

The following example code fails to check for a forbidden word in an input string:

```go
package main

import "regexp"

func broken(hostNames []byte) string {
  var hostRe = regexp.MustCompile("\bforbidden.host.org")
  if hostRe.Match(hostNames) {
    return "Must not target forbidden.host.org"
  } else {
    // This will be reached even if hostNames is exactly "forbidden.host.org",
    // because the literal backspace is not matched
    return ""
  }
}
```

#### Mitigation

The above check does not work, but can be fixed by escaping the backslash:

```go
package main

import "regexp"

func fixed(hostNames []byte) string {
  var hostRe = regexp.MustCompile(`\bforbidden.host.org`)
  if hostRe.Match(hostNames) {
    return "Must not target forbidden.host.org"
  } else {
    // hostNames definitely doesn't contain a word "forbidden.host.org", as "\\b"
    // is the start-of-word anchor, not a literal backspace.
    return ""
  }
}
```

Alternatively, you can use backtick-delimited raw string literals. For example, the `\b` in ``regexp.Compile(`hello\bworld`)``  matches a word boundary, not a backspace character, as within backticks `\b` is not an escape sequence.

## Path Traversal guidelines

### Description

Path Traversal vulnerabilities grant attackers access to arbitrary directories and files on the server that is executing an application. This data can include data, code or credentials.

Traversal can occur when a path includes directories. A typical malicious example includes one or more `../`, which tells the file system to look in the parent directory. Supplying many of them in a path, for example `../../../../../../../etc/passwd`, usually resolves to `/etc/passwd`. If the file system is instructed to look back to the root directory and can't go back any further, then extra `../` are ignored. The file system then looks from the root, resulting in `/etc/passwd` - a file you definitely do not want exposed to a malicious attacker!

### Impact

Path Traversal attacks can lead to multiple critical and high severity issues, like arbitrary file read, remote code execution, or information disclosure.

### When to consider

When working with user-controlled filenames/paths and file system APIs.

### Mitigation and prevention

In order to prevent Path Traversal vulnerabilities, user-controlled filenames or paths should be validated before being processed.

- Comparing user input against an allowlist of allowed values or verifying that it only contains allowed characters.
- After validating the user supplied input, it should be appended to the base directory and the path should be canonicalized using the file system API.

Go has unintuitive behavior with [`path.Clean`](https://pkg.go.dev/path#example-Clean). Remember that with many file systems, using `../../../../` traverses up to the root directory. Any remaining `../` are ignored. This example may give an attacker access to `/etc/passwd`:

```go
path.Clean("/../../etc/passwd")
// renders the path to "etc/passwd"; the file path is relative to whatever the current directory is
path.Clean("../../etc/passwd")
// renders the path to "../../etc/passwd"; the file path will look back up to two parent directories!
```

#### Safe File Operations in Go

The Go standard library provides basic file operations like `os.Open`, `os.ReadFile`, `os.WriteFile`, and `os.Readlink`. However, these functions do not prevent path traversal attacks, where user-supplied paths can escape the intended directory and access sensitive system files.

Example of unsafe usage:

```go
// Vulnerable: user input is directly used in the path
os.Open(filepath.Join("/app/data", userInput))
os.ReadFile(filepath.Join("/app/data", userInput))
os.WriteFile(filepath.Join("/app/data", userInput), []byte("data"), 0644)
os.Readlink(filepath.Join("/app/data", userInput))
```

To mitigate these risks, use the  [`safeopen`](https://pkg.go.dev/github.com/google/safeopen) library functions. These functions enforce a secure root directory and sanitize file paths:

Example of safe usage:

```go
safeopen.OpenBeneath("/app/data", userInput)
safeopen.ReadFileBeneath("/app/data", userInput)
safeopen.WriteFileBeneath("/app/data", []byte("data"), 0644)
safeopen.ReadlinkBeneath("/app/data", userInput)
```

Benefits:

- Prevents path traversal attacks (`../` sequences).
- Restricts file operations to trusted root directories.
- Secures against unauthorized file reads, writes, and symlink resolutions.
- Provides simple, developer-friendly replacements.

References:

- [Go Standard Library os Package](https://pkg.go.dev/os)
- [Safe Go Libraries Announcement](https://bughunters.google.com/blog/4925068200771584/the-family-of-safe-golang-libraries-is-growing)
- [OWASP Path Traversal Cheat Sheet](https://owasp.org/www-community/attacks/Path_Traversal)

## OS command injection guidelines

Command injection is an issue in which an attacker is able to execute arbitrary commands on the host
operating system through a vulnerable application. Such attacks don't always provide feedback to a
user, but the attacker can use simple commands like `curl` to obtain an answer.

### Impact

The impact of command injection greatly depends on the user context running the commands, as well as
how data is validated and sanitized. It can vary from low impact because the user running the
injected commands has limited rights, to critical impact if running as the root user.

Potential impacts include:

- Execution of arbitrary commands on the host machine.
- Unauthorized access to sensitive data, including passwords and tokens in secrets or configuration
  files.
- Exposure of sensitive system files on the host machine, such as `/etc/passwd/` or `/etc/shadow`.
- Compromise of related systems and services gained through access to the host machine.

You should be aware of and take steps to prevent command injection when working with user-controlled
data that are used to run OS commands.

### Mitigation and prevention

To prevent OS command injections, user-supplied data shouldn't be used within OS commands. In cases
where you can't avoid this:

- Validate user-supplied data against an allowlist.
- Ensure that user-supplied data only contains alphanumeric characters (and no syntax or whitespace
  characters, for example).
- Always use `--` to separate options from arguments.

Go has built-in protections that usually prevent an attacker from successfully injecting OS commands.

Consider the following example:

```go
package main

import (
  "fmt"
  "os/exec"
)

func main() {
  cmd := exec.Command("echo", "1; cat /etc/passwd")
  out, _ := cmd.Output()
  fmt.Printf("%s", out)
}
```

This echoes `"1; cat /etc/passwd"`.

**Do not** use `sh`, as it bypasses internal protections:

```go
out, _ = exec.Command("sh", "-c", "echo 1 | cat /etc/passwd").Output()
```

This outputs `1` followed by the content of `/etc/passwd`.

## Working with archive files

Working with archive files like `zip`, `tar`, `jar`, `war`, `cpio`, `apk`, `rar` and `7z` presents an area where potentially critical security vulnerabilities can sneak into an application.

### Zip Slip

In 2018, the security company Snyk [released a blog post](https://security.snyk.io/research/zip-slip-vulnerability) describing research into a widespread and critical vulnerability present in many libraries and applications which allows an attacker to overwrite arbitrary files on the server file system which, in many cases, can be leveraged to achieve remote code execution. The vulnerability was dubbed Zip Slip.

A Zip Slip vulnerability happens when an application extracts an archive without validating and sanitizing the filenames inside the archive for directory traversal sequences that change the file location when the file is extracted.

Example malicious filenames:

- `../../etc/passwd`
- `../../root/.ssh/authorized_keys`
- `../../etc/gitlab/gitlab.rb`

If a vulnerable application extracts an archive file with any of these filenames, the attacker can overwrite these files with arbitrary content.

### Insecure archive extraction examples

```go
// unzip INSECURELY extracts source zip file to destination.
func unzip(src, dest string) error {
  r, err := zip.OpenReader(src)
  if err != nil {
    return err
  }
  defer r.Close()

  os.MkdirAll(dest, 0750)

  for _, f := range r.File {
    if f.FileInfo().IsDir() { // Skip directories in this example for simplicity.
      continue
    }

    rc, err := f.Open()
    if err != nil {
      return err
    }
    defer rc.Close()

    path := filepath.Join(dest, f.Name) // Oops! We blindly use the entry filename for the destination.
    os.MkdirAll(filepath.Dir(path), f.Mode())
    f, err := os.OpenFile(path, os.O_WRONLY|os.O_CREATE|os.O_TRUNC, f.Mode())
    if err != nil {
      return err
    }
    defer f.Close()

    if _, err := io.Copy(f, rc); err != nil {
      return err
    }
  }

  return nil
}
```

#### Best practices

Always expand the destination file path by resolving all potential directory traversals and other sequences that can alter the path and refuse extraction if the final destination path does not start with the intended destination directory.

You are encouraged to use the secure archive utilities provided by [LabSec](https://gitlab.com/gitlab-com/gl-security/appsec/labsec) which will handle Zip Slip and other types of vulnerabilities for you. The LabSec utilities are also context aware which makes it possible to cancel or timeout extractions:

```go
package main

import "gitlab-com/gl-security/appsec/labsec/archive/zip"

func main() {
  f, err := os.Open("/tmp/uploaded.zip")
  if err != nil {
    panic(err)
  }
  defer f.Close()

  fi, err := f.Stat()
  if err != nil {
    panic(err)
  }

  if err := zip.Extract(context.Background(), f, fi.Size(), "/tmp/extracted"); err != nil {
    panic(err)
  }
}
```

In case the LabSec utilities do not fit your needs, here is an example for extracting a zip file with protection against Zip Slip attacks:

```go
// unzip extracts source zip file to destination with protection against Zip Slip attacks.
func unzip(src, dest string) error {
  r, err := zip.OpenReader(src)
  if err != nil {
    return err
  }
  defer r.Close()

  os.MkdirAll(dest, 0750)

  for _, f := range r.File {
    if f.FileInfo().IsDir() { // Skip directories in this example for simplicity.
      continue
    }

    rc, err := f.Open()
    if err != nil {
      return err
    }
    defer rc.Close()

    path := filepath.Join(dest, f.Name)

    // Check for Zip Slip / directory traversal
    if !strings.HasPrefix(path, filepath.Clean(dest) + string(os.PathSeparator)) {
      return fmt.Errorf("illegal file path: %s", path)
    }

    os.MkdirAll(filepath.Dir(path), f.Mode())
    f, err := os.OpenFile(path, os.O_WRONLY|os.O_CREATE|os.O_TRUNC, f.Mode())
    if err != nil {
      return err
    }
    defer f.Close()

    if _, err := io.Copy(f, rc); err != nil {
      return err
    }
  }

  return nil
}
```

### Symlink attacks

Symlink attacks makes it possible for an attacker to read the contents of arbitrary files on the server of a vulnerable application. While it is a high-severity vulnerability that can often lead to remote code execution and other critical vulnerabilities, it is only exploitable in scenarios where a vulnerable application accepts archive files from the attacker and somehow displays the extracted contents back to the attacker without any validation or sanitization of symbolic links inside the archive.

### Insecure archive symlink extraction examples

```go
// printZipContents INSECURELY prints contents of files in a zip file.
func printZipContents(src string) error {
  r, err := zip.OpenReader(src)
  if err != nil {
    return err
  }
  defer r.Close()

  // Loop over each entry and output file contents
  for _, f := range r.File {
    if f.FileInfo().IsDir() {
      continue
    }

    rc, err := f.Open()
    if err != nil {
      return err
    }
    defer rc.Close()

    // Oops! We don't check if the file is actually a symbolic link to a potentially sensitive file.
    buf, err := ioutil.ReadAll(rc)
    if err != nil {
      return err
    }

    fmt.Println(buf.String())
  }

  return nil
}
```

#### Best practices

Always check the type of the archive entry before reading the contents and ignore entries that are not plain files. If you absolutely must support symbolic links, ensure that they only point to files inside the archive and nowhere else.

You are encouraged to use the secure archive utilities provided by [LabSec](https://gitlab.com/gitlab-com/gl-security/appsec/labsec) which will handle Zip Slip and symlink vulnerabilities for you. The LabSec utilities are also context aware which makes it possible to cancel or timeout extractions.

In case the LabSec utilities do not fit your needs, here is an example for extracting a zip file with protection against symlink attacks:

```go
// printZipContents prints contents of files in a zip file with protection against symlink attacks.
func printZipContents(src string) error {
  r, err := zip.OpenReader(src)
  if err != nil {
    return err
  }
  defer r.Close()

  // Loop over each entry and output file contents
  for _, f := range r.File {
    if f.FileInfo().IsDir() {
      continue
    }

    // By skipping all irregular file types (including symbolic links), we are sure they can't cause any trouble!
    if !zf.Mode().IsRegular() {
      continue
    }

    rc, err := f.Open()
    if err != nil {
      return err
    }
    defer rc.Close()

    buf, err := ioutil.ReadAll(rc)
    if err != nil {
      return err
    }

    fmt.Println(buf.String())
  }

  return nil
}
```
