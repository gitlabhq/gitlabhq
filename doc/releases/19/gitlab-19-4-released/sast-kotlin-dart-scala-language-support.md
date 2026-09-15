---
title: Advanced SAST includes Kotlin, Dart, and Scala language support
tier: [ Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated, gitlab_dedicated_for_government ]
stage: application_security_testing
documentation_link: ../../../user/application_security/sast/gitlab_advanced_sast/#supported-languages
work_item: https://gitlab.com/groups/gitlab-org/-/work_items/23383
categories: [ SAST ]
level: primary
---

Advanced SAST now scans Kotlin, Dart, and Scala codebases with the same deep taint
analysis that covers Java, Python, and other supported languages, all delivered through
the Software Factory architecture with per-language front-ends and framework-aware rule gating.

- Kotlin detection targets Android APIs for SQL injection, unsafe WebView usage, OS command
  injection, hardcoded credentials, and weak cryptography.
- Dart detection includes a Flutter and Dio framework detector covering SSRF, path traversal,
  command injection, and cleartext HTTP.
- Scala detection covers Play, Slick, and Akka frameworks for SQL injection, SSRF, open redirect,
  path traversal, command injection, and XSS.

All three additions are verified using deliberately vulnerable real-code repositories,
with findings reported as code flows from source to sink.
