---
stage: Application Security Testing
group: Dynamic Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Path traversal
---

## Description

Many file operations are intended to take place within a restricted directory. By using special elements such as `..` and `/` separators, attackers can escape outside of the restricted location to access files or directories that are elsewhere on the system. One of the most common special elements is the `../` sequence, which in most modern operating systems is interpreted as the parent directory of the current location. This is referred to as relative path traversal. Path traversal also covers the use of absolute path-names such as `/usr/local/bin`, which may also be useful in accessing unexpected files. This is referred to as absolute path traversal.

In many programming languages, the injection of a null byte (the `0` or `NULL` ) may allow an attacker to truncate a generated filename to widen the scope of attack. For example, the software may add `.txt` to any pathname, thus limiting the attacker to text files, but a null injection may effectively remove this restriction.

This check modifies parameters in the request (path, query string, headers, JSON, XML, etc.) to try and access restricted files and files outside of the web-root. Logs and responses are then analyzed to try and detect if the file was successfully accessed.

## Remediation

The Path traversal attack technique allows an attacker access to files, directories, and commands that potentially reside outside the web document root directory. An attacker may manipulate a URL in such a way that the web site will execute or reveal the contents of arbitrary files anywhere on the web server. Any device that exposes an HTTP-based interface is potentially vulnerable to Path traversal.

Most web sites restrict user access to a specific portion of the file-system, typically called the "web document root" or "CGI root" directory. These directories contain the files intended for user access and the executable necessary to drive web application functionality. To access files or execute commands anywhere on the file-system, Path traversal attacks will utilize the ability of special-characters sequences.

The most basic Path traversal attack uses the `../` special-character sequence to alter the resource location requested in the URL. Although most popular web servers will prevent this technique from escaping the web document root, alternate encodings of the `../` sequence may help bypass the security filters. These method variations include valid and invalid Unicode-encoding (`..%u2216` or `..%c0%af`) of the forward slash character, backslash characters (`..`) on Windows-based servers, URL encoded characters (`%2e%2e%2f`), and double URL encoding (`..%255c`) of the backslash character.

Even if the web server properly restricts Path traversal attempts in the URL path, a web application itself may still be vulnerable due to improper handling of user-supplied input. This is a common problem of web applications that use template mechanisms or load static text from files. In variations of the attack, the original URL parameter value is substituted with the file name of one of the web application's dynamic scripts. Consequently, the results can reveal source code because the file is interpreted as text instead of an executable script. These techniques often employ additional special characters such as the dot (`.`) to reveal the listing of the current working directory, or `%00` NULL characters in order to bypass rudimentary file extension checks.

## Links

- [OWASP](https://owasp.org/Top10/A01_2021-Broken_Access_Control/)
- [CWE](https://cwe.mitre.org/data/definitions/22.html)
