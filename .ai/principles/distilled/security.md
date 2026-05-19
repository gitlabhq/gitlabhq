---
source_checksum: be71c57927b2a703
distilled_at_sha: 52964caf288c3d9936b8ce4a3d2242c1f92567fa
---
<!-- Auto-generated from docs.gitlab.com by gitlab-ai-principles-distiller — do not edit manually -->

# Security Principles

## Checklist

### Permissions & Authorization

- Write unit and feature specs that assert both what actors **can** and **cannot** do (abuse cases).
- Test visibility levels in addition to project access rights.
- Return `404 Not Found` (not `403 Forbidden`) when authorization fails, to avoid revealing resource existence; use `403` only when displaying a specific denial message.
- Use `user.is_a?(User)` before passing `user.id` to auth methods like `Gitlab::Auth::CurrentUserMode.bypass_session!` to prevent `DeployToken`/`DeployKey` ID confusion.
- Group all permissions for the same condition into one `.policy` block; DO NOT scatter rules across the file.
- DO NOT enable permissions in `BasePolicy` — it is inherited by all policies and would grant the permission on every object.
- DO NOT define permissions dynamically at runtime; declare each permission explicitly so it is searchable.
- Set the correct `:scope` on conditions: `scope: :user` for user-data-only, `scope: :subject` for subject-data-only, `scope: :global` for neither, and no scope when both are read.
- DO NOT cascade permissions through non-private intermediate abilities; add each permission directly to the appropriate role YAML file. Exception: private (underscore-prefixed) permissions may cascade exactly one level deep (private permission + condition enables public permission).
- Enable a permission unconditionally for a role, then use a separate `prevent` rule to restrict it when a condition is not met — DO NOT combine role checks and settings/flag checks in a single `rule { role & condition }`.
- DO NOT write `rule { admin | owner }` — `admin` already satisfies `condition(:owner)`.
- Use role YAML files (`config/authz/roles/*.yml`) as the single source of truth for which permissions each role has; DO NOT use `enable` rules in policy files to grant permissions based on role conditions.

### Regular Expressions (Ruby)

- Use `\A` and `\z` anchors instead of `^` and `$` in Ruby regexes to match the full string, not individual lines.
- Use `Gitlab::UntrustedRegexp` (backed by `re2`) for all user-provided regular expressions.
- Pass an explicit `timeout:` parameter to `Regexp.new` when using advanced features (back-references, look-around, large fixed repetitions).
- DO NOT use nested quantifiers (e.g., `(a+)+`) in regexes.
- Perform simple input validation (e.g., maximum length) before applying a regular expression to user input.

### Regular Expressions (Go)

- Use backtick raw string literals for Go regex patterns to avoid misinterpreting `\b` (backspace vs. word boundary) and `\a` (bell vs. text-start).

### ReDoS (Python)

- Prefer `re2` over `re`/`regex` in Python; when `re2` is not usable, always pass a `timeout` parameter to `re.match`/`regex.match`.

### SSRF

- Use `Gitlab::HTTP` for all outbound HTTP connections.
- Use `Gitlab::HTTP_V2::UrlBlocker` with `dns_rebind_protection: true` and **use the returned safe URI** (with hostname replaced by resolved IP) for the actual request.
- DO NOT validate URLs with `.start_with?` or `.end_with?`; parse with `URI` and validate each component (scheme, host, port, path).
- Block connections to localhost (`127.0.0.1/8`, `::1`), RFC 1918 ranges, and link-local addresses (`169.254.0.0/16`) when implementing feature-specific SSRF mitigations.
- Disable or validate redirect destinations for HTTP connections.

### TOCTOU / DNS Rebinding

- Re-validate URLs/IPs at time of use, not only at time of record creation/save.
- Use the IP address returned by `Gitlab::HTTP_V2::UrlBlocker.validate!` for the actual connection to prevent DNS rebinding.
- Use database constraints, transactions, or unique indexes to prevent race conditions in concurrent writes.

### XSS (Ruby / Rails)

- DO NOT use `html_safe`, `raw`, or `!=` in HAML/ERB with user-controlled values.
- Sanitize and validate URL schemes when calling `link_to` or `redirect_to` with user-controlled parameters.
- Reject input that fails allowlist validation — DO NOT sanitize and accept it.
- Invalidate cached Markdown HTML after fixing a stored XSS vulnerability.

### XSS (JavaScript / Vue)

- DO NOT use `innerHTML` with user-controlled values; use `textContent` or `nodeValue`.
- DO NOT use `v-html` with user-controlled data; use `v-safe-html` instead.
- Sanitize unsafe HTML with the project-internal `sanitize` wrapper (backed by `dompurify`) before inserting into the DOM.
- Use `gl-sprintf` for interpolating translated strings that contain user-controlled values; DO NOT use `__()` for such strings.
- Validate the `origin` of `postMessage` messages against an allowlist.
- DO NOT include external fonts, CSS, or JavaScript; always serve assets locally from the GitLab instance.
- DO NOT use inline scripts; avoid inline styles except when no alternative exists.
- Mark security-related specs with `#security` in `describe` or `it` blocks so they are not accidentally removed.

### JSON Parsing

- Use `Gitlab::Json.safe_parse` instead of `Gitlab::Json.parse` when handling untrusted input (HTTP bodies, webhook payloads, user-uploaded files, external API responses)
- Rescue `JSON::ParserError` from `safe_parse` and return a safe error response; DO NOT expose internal limit-exceeded details to callers.

### JWT

- Use asymmetric algorithms (RS256, ES256) over symmetric ones (HS256) for JWT signing.
- Include `exp`, `iat`, `iss`, and `aud` claims in every JWT payload.
- Hardcode the expected algorithm during token verification; DO NOT accept `none` or allow algorithm negotiation.
- Verify the token signature before acting on any claims.

### Path Traversal (Ruby)

- Use `Gitlab::PathTraversal.check_allowed_absolute_path_and_path_traversal!` to validate user-supplied paths.
- Use the `FilePath` validator in REST API endpoints: `requires :file_path, type: String, file_path: { allowlist: [...] }`.
- Be aware that `Pathname#join` with an absolute second argument discards the base path; validate before joining.

### Path Traversal (Go)

- Use `safeopen.OpenBeneath` / `ReadFileBeneath` / `WriteFileBeneath` / `ReadlinkBeneath` instead of raw `os.Open`/`os.ReadFile`/`os.WriteFile`/`os.Readlink` with user-supplied paths.
- Be aware that `path.Clean` does not prevent traversal; always verify the resolved path starts with the intended base directory.

### OS Command Injection (Ruby)

- Use `FileUtils` or Ruby file APIs instead of shell commands where a Ruby API exists.
- Split commands into separate tokens (array form) instead of passing a single interpolated string to `system`.
- Always use `--` to separate options from arguments in shell commands.
- DO NOT use backticks for shell commands; use `Gitlab::Popen.popen` with a token array instead.
- Use the configurable `Gitlab.config.git.bin_path` for all Git commands.
- DO NOT start file paths with user input; prefix `./` to relative user-supplied paths.
- Prefix paths with a known base directory so they cannot start with `|` or `-`.

### OS Command Injection (Go)

- DO NOT pass commands to `sh -c` with user-supplied data; use `exec.Command` with separate arguments.

### Archive File Handling (Ruby)

- Use `SafeZip::Extract` for zip extraction.
- Expand and verify the destination path before writing each archive entry; raise an error if the resolved path escapes the destination directory.
- Skip symlink entries during extraction; DO NOT follow symbolic links from archive files.

### Archive File Handling (Go)

- Use the LabSec `archive/zip` utilities for zip extraction when possible.
- Verify that `filepath.Join(dest, entry.Name)` starts with `filepath.Clean(dest) + string(os.PathSeparator)` before writing.
- Skip non-regular file entries (including symlinks) during extraction.

### XML / XXE

- Use Nokogiri with default (safe) parse options.
- DO NOT set `noent`, `dtdload`, `huge`, or `nononet` Nokogiri parse options when processing user-supplied XML.
- DO NOT use `REXML::Document` to parse untrusted XML.

### Credentials & Secrets

- Store secrets as salted hashes when only comparison is needed; use `encrypts` with a length validation (≤ 510) when the plaintext must be retrievable.
- DO NOT commit credentials to repositories.
- DO NOT log credentials under any circumstances; log the internal credential ID instead if debugging requires it.
- Use masked CI/CD variables for credentials in pipelines; use protected variables for sensitive values.
- DO NOT send credentials in URL parameters.
- Prefix new token types with `gl<abbreviation>-` (e.g., `glpat-`); DO NOT make the prefix configurable.
- Register new token prefixes in `secret_detection.js`, the GitLab secret detection rules, the secrets SAST analyzer, and the Token Overview documentation.
- Use `TokenAuthenticatable` with `digest: true` and `format_with_prefix:` for new token fields.
- Use `prevent_from_serialization` on sensitive ActiveRecord attributes to exclude them from `serializable_hash`/`to_json`/`as_json`.
- Use Grape entities for API serialization; DO NOT use `to_json`/`as_json` or `serialize :column` directly on ActiveRecord models.

### Logging

- Log authentication/authorization failures, account lockouts, invalid token usage, access token lifecycle events, and sensitive operations
- DO NOT log personal data beyond integer IDs, UUIDs, or IP addresses (when necessary)
- DO NOT log credentials, tokens, passwords, or keys under any circumstances.
- DO NOT log unvalidated user input directly.

### TLS

- Use TLS 1.2 or later; DO NOT use TLS 1.0 or 1.1.
- For TLS 1.2 in Go, explicitly set `CipherSuites` to the approved ECDHE-ECDSA/RSA-AES-GCM list and `MinVersion: tls.VersionTLS12`.
- Use `Gitlab::HTTP` (not raw `HTTParty`) for Ruby HTTP connections to benefit from SSRF and TLS protections.

### Metaprogramming

- DO NOT pass user-provided values into `method_missing`, `define_method`, `delegate`, or similar runtime method-defining constructs
- When using `method_missing` or `def_delegators`, ensure dynamically defined methods cannot overwrite existing security-critical methods.

### Paid Tiers as Security Controls

- DO NOT rely on subscription tier checks (Premium/Ultimate feature flags) as the sole mitigation for a security vulnerability; fix the vulnerability in all tiers.

### AI / LLM Features

- Treat all LLM responses as untrusted; sanitize before rendering (apply XSS guidelines).
- Implement rate limiting on model endpoints
- Validate and sanitize all inputs to LLM prompts to mitigate prompt injection
- Implement human oversight and limit LLM autonomy to mitigate excessive agency.

### URL Spoofing

- Use the `external_redirect_path` helper when presenting user-supplied links whose destination URL is not directly visible to the user

### Email / Notifications

- Use `Gitlab::Email::SingleRecipientValidator` for emails intended for a single recipient.
- Call `.to_s` on email values or check `value.kind_of?(String)` before passing to mailers to prevent array injection.

### Request Parameter Typing

- Use `ActionController::StrongParameters` (`params.require(...).permit(...)`) in all Rails controllers; DO NOT use raw `params[:key]` where a typed value is expected.

## Authoritative sources

For the full picture, see:

- doc/development/secure_coding_guidelines/_index.md
- doc/development/secure_coding_guidelines/ruby.md
- doc/development/secure_coding_guidelines/go.md
- doc/development/shell_commands.md
- doc/development/permissions/review_guidelines.md
- doc/development/fe_guide/security.md

