---
type: reference, dev
stage: none
group: Development
info: "See the Technical Writers assigned to Development Guidelines: https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments-to-development-guidelines"
---

# Secure Coding Guidelines

This document contains descriptions and guidelines for addressing security
vulnerabilities commonly identified in the GitLab codebase. They are intended
to help developers identify potential security vulnerabilities early, with the
goal of reducing the number of vulnerabilities released over time.

**Contributing**

If you would like to contribute to one of the existing documents, or add
guidelines for a new vulnerability type, please open an MR! Please try to
include links to examples of the vulnerability found, and link to any resources
used in defined mitigations. If you have questions or when ready for a review,
please ping `gitlab-com/gl-security/appsec`.

## Permissions

### Description

Application permissions are used to determine who can access what and what actions they can perform.
For more information about the permission model at GitLab, please see [the GitLab permissions guide](permissions.md) or the [EE docs on permissions](../../ee/user/permissions.md).

### Impact

Improper permission handling can have significant impacts on the security of an application.
Some situations may reveal [sensitive data](https://gitlab.com/gitlab-com/gl-infra/production/-/issues/477) or allow a malicious actor to perform [harmful actions](https://gitlab.com/gitlab-org/gitlab/-/issues/8180).
The overall impact depends heavily on what resources can be accessed or modified improperly.

A common vulnerability when permission checks are missing is called [IDOR](https://owasp.org/www-project-web-security-testing-guide/latest/4-Web_Application_Security_Testing/05-Authorization_Testing/04-Testing_for_Insecure_Direct_Object_References) for Insecure Direct Object References.

### When to Consider

Each time you implement a new feature/endpoint, whether it is at UI, API or GraphQL level.

### Mitigations

**Start by writing tests** around permissions: unit and feature specs should both include tests based around permissions

- Fine-grained, nitty-gritty specs for permissions are good: it is ok to be verbose here
  - Make assertions based on the actors and objects involved: can a user or group or XYZ perform this action on this object?
  - Consider defining them upfront with stakeholders, particularly for the edge cases
- Do not forget **abuse cases**: write specs that **make sure certain things can't happen**
  - A lot of specs are making sure things do happen and coverage percentage doesn't take into account permissions as same piece of code is used.
  - Make assertions that certain actors cannot perform actions
- Naming convention to ease auditability: to be defined, for example, a subfolder containing those specific permission tests or a `#permissions` block

Be careful to **also test [visibility levels](https://gitlab.com/gitlab-org/gitlab-foss/-/blob/master/doc/development/permissions.md#feature-specific-permissions)** and not only project access rights.

Some example of well implemented access controls and tests:

1. [example1](https://dev.gitlab.org/gitlab/gitlab-ee/-/merge_requests/710/diffs?diff_id=13750#af40ef0eaae3c1e018809e1d88086e32bccaca40_43_43)
1. [example2](https://dev.gitlab.org/gitlab/gitlabhq/-/merge_requests/2511/diffs#ed3aaab1510f43b032ce345909a887e5b167e196_142_155)
1. [example3](https://dev.gitlab.org/gitlab/gitlabhq/-/merge_requests/3170/diffs?diff_id=17494)

**NB:** any input from development team is welcome, for example, about Rubocop rules.

## Regular Expressions guidelines

### Anchors / Multi line

Unlike other programming languages (for example, Perl or Python) Regular Expressions are matching multi-line by default in Ruby. Consider the following example in Python:

```python
import re
text = "foo\nbar"
matches = re.findall("^bar$",text)
print(matches)
```

The Python example will output an empty array (`[]`) as the matcher considers the whole string `foo\nbar` including the newline (`\n`). In contrast Ruby's Regular Expression engine acts differently:

```ruby
text = "foo\nbar"
p text.match /^bar$/
```

The output of this example is `#<MatchData "bar">`, as Ruby treats the input `text` line by line. In order to match the whole __string__ the Regex anchors `\A` and `\z` should be used.

#### Impact

This Ruby Regex specialty can have security impact, as often regular expressions are used for validations or to impose restrictions on user-input.

#### Examples

GitLab-specific examples can be found in the following [path traversal](https://gitlab.com/gitlab-org/gitlab/-/issues/36029#note_251262187)
and [open redirect](https://gitlab.com/gitlab-org/gitlab/-/issues/33569) issues.

Another example would be this fictional Ruby on Rails controller:

```ruby
class PingController < ApplicationController
  def ping
    if params[:ip] =~ /^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$/
      render :text => `ping -c 4 #{params[:ip]}`
    else
      render :text => "Invalid IP"
    end
  end
end
```

Here `params[:ip]` should not contain anything else but numbers and dots. However this restriction can be easily bypassed as the Regex anchors `^` and `$` are being used. Ultimately this leads to a shell command injection in `ping -c 4 #{params[:ip]}` by using newlines in `params[:ip]`.

#### Mitigation

In most cases the anchors `\A` for beginning of text and `\z` for end of text should be used instead of `^` and `$`.

## Denial of Service (ReDoS) / Catastrophic Backtracking

When a regular expression (regex) is used to search for a string and can't find a match,
it may then backtrack to try other possibilities.

For example when the regex `.*!$` matches the string `hello!`, the `.*` first matches
the entire string but then the `!` from the regex is unable to match because the
character has already been used. In that case, the Ruby regex engine _backtracks_
one character to allow the `!` to match.

[ReDoS](https://owasp.org/www-community/attacks/Regular_expression_Denial_of_Service_-_ReDoS)
is an attack in which the attacker knows or controls the regular expression used.
The attacker may be able to enter user input that triggers this backtracking behavior in a
way that increases execution time by several orders of magnitude.

### Impact

The resource, for example Puma, or Sidekiq, can be made to hang as it takes
a long time to evaluate the bad regex match. The evaluation time may require manual
termination of the resource.

### Examples

Here are some GitLab-specific examples.

User inputs used to create regular expressions:

- [User-controlled filename](https://gitlab.com/gitlab-org/gitlab/-/issues/257497)
- [User-controlled domain name](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/25314)
- [User-controlled email address](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/25122#note_289087459)

Hardcoded regular expressions with backtracking issues:

- [Repository name validation](https://gitlab.com/gitlab-org/gitlab/-/issues/220019)
- [Link validation](https://gitlab.com/gitlab-org/gitlab/-/issues/218753), and [a bypass](https://gitlab.com/gitlab-org/gitlab/-/issues/273771)
- [Entity name validation](https://gitlab.com/gitlab-org/gitlab/-/issues/289934)
- [Validating color codes](https://gitlab.com/gitlab-org/gitlab/commit/717824144f8181bef524592eab882dd7525a60ef)

Consider the following example application, which defines a check using a regular expression. A user entering `user@aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa!.com` as the email on a form will hang the web server.

```ruby
class Email < ApplicationRecord
  DOMAIN_MATCH = Regexp.new('([a-zA-Z0-9]+)+\.com')

  validates :domain_matches

  private

  def domain_matches
    errors.add(:email, 'does not match') if email =~ DOMAIN_MATCH
  end
end
```

### Mitigation

#### Ruby

GitLab has [`Gitlab::UntrustedRegexp`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/untrusted_regexp.rb)
 which internally uses the [`re2`](https://github.com/google/re2/wiki/Syntax) library.
`re2` does not support backtracking so we get constant execution time, and a smaller subset of available regex features.

All user-provided regular expressions should use `Gitlab::UntrustedRegexp`.

For other regular expressions, here are a few guidelines:

- If there's a clean non-regex solution, such as `String#start_with?`, consider using it
- Ruby supports some advanced regex features like [atomic groups](https://www.regular-expressions.info/atomic.html)
and [possessive quantifiers](https://www.regular-expressions.info/possessive.html) that eliminate backtracking
- Avoid nested quantifiers if possible (for example `(a+)+`)
- Try to be as precise as possible in your regex and avoid the `.` if there's an alternative
  - For example, Use `_[^_]+_` instead of `_.*_` to match `_text here_`
- If in doubt, don't hesitate to ping `@gitlab-com/gl-security/appsec`

#### Go

Go's [`regexp`](https://golang.org/pkg/regexp/) package uses `re2` and isn't vulnerable to backtracking issues.

## Further Links

- [Rubular](https://rubular.com/) is a nice online tool to fiddle with Ruby Regexps.
- [Runaway Regular Expressions](https://www.regular-expressions.info/catastrophic.html)
- [The impact of regular expression denial of service (ReDoS) in practice: an empirical study at the ecosystem scale](https://people.cs.vt.edu/~davisjam/downloads/publications/DavisCoghlanServantLee-EcosystemREDOS-ESECFSE18.pdf). This research paper discusses approaches to automatically detect ReDoS vulnerabilities.
- [Freezing the web: A study of ReDoS vulnerabilities in JavaScript-based web servers](https://www.usenix.org/system/files/conference/usenixsecurity18/sec18-staicu.pdf). Another research paper about detecting ReDoS vulnerabilities.

## Server Side Request Forgery (SSRF)

### Description

A [Server-side Request Forgery (SSRF)](https://www.hackerone.com/blog-How-To-Server-Side-Request-Forgery-SSRF) is an attack in which an attacker
is able coerce a application into making an outbound request to an unintended
resource. This resource is usually internal. In GitLab, the connection most
commonly uses HTTP, but an SSRF can be performed with any protocol, such as
Redis or SSH.

With an SSRF attack, the UI may or may not show the response. The latter is
called a Blind SSRF. While the impact is reduced, it can still be useful for
attackers, especially for mapping internal network services as part of recon.

### Impact

The impact of an SSRF can vary, depending on what the application server
can communicate with, how much the attacker can control of the payload, and
if the response is returned back to the attacker. Examples of impact that
have been reported to GitLab include:

- Network mapping of internal services
  - This can help an attacker gather information about internal services
  that could be used in further attacks. [More details](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/51327).
- Reading internal services, including cloud service metadata.
  - The latter can be a serious problem, because an attacker can obtain keys that allow control of the victim's cloud infrastructure. (This is also a good reason
  to give only necessary privileges to the token.). [More details](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/51490).
- When combined with CRLF vulnerability, remote code execution. [More details](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/41293).

### When to Consider

- When the application makes any outbound connection

### Mitigations

In order to mitigate SSRF vulnerabilities, it is necessary to validate the destination of the outgoing request, especially if it includes user-supplied information.

The preferred SSRF mitigations within GitLab are:

1. Only connect to known, trusted domains/IP addresses.
1. Use the [GitLab::HTTP](#gitlab-http-library) library
1. Implement [feature-specific mitigations](#feature-specific-mitigations)

#### GitLab HTTP Library

The [GitLab::HTTP](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/http.rb) wrapper library has grown to include mitigations for all of the GitLab-known SSRF vectors. It is also configured to respect the
`Outbound requests` options that allow instance administrators to block all internal connections, or limit the networks to which connections can be made.

In some cases, it has been possible to configure GitLab::HTTP as the HTTP
connection library for 3rd-party gems. This is preferable over re-implementing
the mitigations for a new feature.

- [More details](https://dev.gitlab.org/gitlab/gitlabhq/-/merge_requests/2530/diffs)

#### Feature-specific mitigations

For situations in which an allowlist or GitLab:HTTP cannot be used, it will be necessary to implement mitigations directly in the feature. It is best to validate the destination IP addresses themselves, not just domain names, as DNS can be controlled by the attacker. Below are a list of mitigations that should be implemented.

There are many tricks to bypass common SSRF validations. If feature-specific mitigations are necessary, they should be reviewed by the AppSec team, or a developer who has worked on SSRF mitigations previously.

- Block connections to all localhost addresses
  - `127.0.0.1/8` (IPv4 - note the subnet mask)
  - `::1` (IPv6)
- Block connections to networks with private addressing (RFC 1918)
  - `10.0.0.0/8`
  - `172.16.0.0/12`
  - `192.168.0.0/24`
- Block connections to link-local addresses (RFC 3927)
  - `169.254.0.0/16`
  - In particular, for GCP: `metadata.google.internal` -> `169.254.169.254`
- For HTTP connections: Disable redirects or validate the redirect destination
- To mitigate DNS rebinding attacks, validate and use the first IP address received

See [`url_blocker_spec.rb`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/spec/lib/gitlab/url_blocker_spec.rb) for examples of SSRF payloads

## XSS guidelines

### Description

Cross site scripting (XSS) is an issue where malicious JavaScript code gets injected into a trusted web application and executed in a client's browser. The input is intended to be data, but instead gets treated as code by the browser.

XSS issues are commonly classified in three categories, by their delivery method:

- [Persistent XSS](https://owasp.org/www-community/Types_of_Cross-Site_Scripting#stored-xss-aka-persistent-or-type-i)
- [Reflected XSS](https://owasp.org/www-community/Types_of_Cross-Site_Scripting#reflected-xss-aka-non-persistent-or-type-ii)
- [DOM XSS](https://owasp.org/www-community/Types_of_Cross-Site_Scripting#dom-based-xss-aka-type-0)

### Impact

The injected client-side code is executed on the victim's browser in the context of their current session. This means the attacker could perform any same action the victim would normally be able to do through a browser. The attacker would also have the ability to:

- <i class="fa fa-youtube-play youtube" aria-hidden="true"></i> [log victim keystrokes](https://youtu.be/2VFavqfDS6w?t=1367)
- launch a network scan from the victim's browser
- potentially <i class="fa fa-youtube-play youtube" aria-hidden="true"></i> [obtain the victim's session tokens](https://youtu.be/2VFavqfDS6w?t=739)
- perform actions that lead to data loss/theft or account takeover

Much of the impact is contingent upon the function of the application and the capabilities of the victim's session. For further impact possibilities, please check out [the beef project](https://beefproject.com/).

### When to consider?

When user submitted data is included in responses to end users, which is just about anywhere.

### Mitigation

In most situations, a two-step solution can be used: input validation and output encoding in the appropriate context.

#### Input validation

- [Input Validation](https://youtu.be/2VFavqfDS6w?t=7489)

##### Setting expectations

For any and all input fields, ensure to define expectations on the type/format of input, the contents, <i class="fa fa-youtube-play youtube" aria-hidden="true"></i> [size limits](https://youtu.be/2VFavqfDS6w?t=7582), the context in which it will be output. It's important to work with both security and product teams to determine what is considered acceptable input.

##### Validate input

- Treat all user input as untrusted.
- Based on the expectations you [defined above](#setting-expectations):
  - Validate the <i class="fa fa-youtube-play youtube" aria-hidden="true"></i> [input size limits](https://youtu.be/2VFavqfDS6w?t=7582).
  - Validate the input using an <i class="fa fa-youtube-play youtube" aria-hidden="true"></i> [allowlist approach](https://youtu.be/2VFavqfDS6w?t=7816) to only allow characters through which you are expecting to receive for the field.
    - Input which fails validation should be **rejected**, and not sanitized.
- When adding redirects or links to a user-controlled URL, ensure that the scheme is HTTP or HTTPS. Allowing other schemes like `javascript://` can lead to XSS and other security issues.

Note that denylists should be avoided, as it is near impossible to block all [variations of XSS](https://owasp.org/www-community/xss-filter-evasion-cheatsheet).

#### Output encoding

Once you've [determined when and where](#setting-expectations) the user submitted data will be output, it's important to encode it based on the appropriate context. For example:

- Content placed inside HTML elements need to be [HTML entity encoded](https://cheatsheetseries.owasp.org/cheatsheets/Cross_Site_Scripting_Prevention_Cheat_Sheet.html#rule-1---html-escape-before-inserting-untrusted-data-into-html-element-content).
- Content placed into a JSON response needs to be [JSON encoded](https://cheatsheetseries.owasp.org/cheatsheets/Cross_Site_Scripting_Prevention_Cheat_Sheet.html#rule-31---html-escape-json-values-in-an-html-context-and-read-the-data-with-jsonparse).
- Content placed inside <i class="fa fa-youtube-play youtube" aria-hidden="true"></i> [HTML URL GET parameters](https://youtu.be/2VFavqfDS6w?t=3494) need to be [URL-encoded](https://cheatsheetseries.owasp.org/cheatsheets/Cross_Site_Scripting_Prevention_Cheat_Sheet.html#rule-5---url-escape-before-inserting-untrusted-data-into-html-url-parameter-values)
- <i class="fa fa-youtube-play youtube" aria-hidden="true"></i> [Additional contexts may require context-specific encoding](https://youtu.be/2VFavqfDS6w?t=2341).

### Additional information

#### XSS mitigation and prevention in Rails

By default, Rails automatically escapes strings when they are inserted into HTML templates. Avoid the
methods used to keep Rails from escaping strings, especially those related to user-controlled values.
Specifically, the following options are dangerous because they mark strings as trusted and safe:

| Method               | Avoid these options           |
|----------------------|-------------------------------|
| HAML templates       | `html_safe`, `raw`, `!=`      |
| Embedded Ruby (ERB)  | `html_safe`, `raw`, `<%== %>` |

In case you want to sanitize user-controlled values against XSS vulnerabilities, you can use
[`ActionView::Helpers::SanitizeHelper`](https://api.rubyonrails.org/classes/ActionView/Helpers/SanitizeHelper.html).
Calling `link_to` and `redirect_to` with user-controlled parameters can also lead to cross-site scripting.

Do also sanitize and validate URL schemes.

References:

- <i class="fa fa-youtube-play youtube" aria-hidden="true"></i> [XSS Defense in Rails](https://youtu.be/2VFavqfDS6w?t=2442)
- <i class="fa fa-youtube-play youtube" aria-hidden="true"></i> [XSS Defense with HAML](https://youtu.be/2VFavqfDS6w?t=2796)
- <i class="fa fa-youtube-play youtube" aria-hidden="true"></i> [Validating Untrusted URLs in Ruby](https://youtu.be/2VFavqfDS6w?t=3936)
- <i class="fa fa-youtube-play youtube" aria-hidden="true"></i> [RoR Model Validators](https://youtu.be/2VFavqfDS6w?t=7636)

#### XSS mitigation and prevention in JavaScript and Vue

- When updating the content of an HTML element using JavaScript, mark user-controlled values as `textContent` or `nodeValue` instead of `innerHTML`.
- Avoid using `v-html` with user-controlled data, use [`v-safe-html`](https://gitlab-org.gitlab.io/gitlab-ui/?path=/story/directives-safe-html-directive--default) instead.
- Render unsafe or unsanitized content using [`dompurify`](fe_guide/security.md#sanitize-html-output).
- Consider using [`gl-sprintf`](../../ee/development/i18n/externalization.md#interpolation) to interpolate translated strings securely.
- Avoid `__()` with translations that contain user-controlled values.
- When working with `postMessage`, ensure the `origin` of the message is allowlisted.
- Consider using the [Safe Link Directive](https://gitlab-org.gitlab.io/gitlab-ui/?path=/story/directives-safe-link-directive--default) to generate secure hyperlinks by default.

#### GitLab specific libraries for mitigating XSS

##### Vue

- [isSafeURL](https://gitlab.com/gitlab-org/gitlab/-/blob/v12.7.5-ee/app/assets/javascripts/lib/utils/url_utility.js#L190-207)
- [GlSprintf](https://gitlab-org.gitlab.io/gitlab-ui/?path=/story/utilities-sprintf--default)

#### Content Security Policy

- <i class="fa fa-youtube-play youtube" aria-hidden="true"></i> [Content Security Policy](https://www.youtube.com/watch?v=2VFavqfDS6w&t=12991s)
- [Use nonce-based Content Security Policy for inline JavaScript](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/65330)

#### Free form input field

### Select examples of past XSS issues affecting GitLab

- [Stored XSS in user status](https://gitlab.com/gitlab-org/gitlab-foss/issues/55320)
- [XSS vulnerability on custom project templates form](https://gitlab.com/gitlab-org/gitlab/-/issues/197302)
- [Stored XSS in branch names](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/55320)
- [Stored XSS in merge request pages](https://gitlab.com/gitlab-org/gitlab/-/issues/35096)

### Internal Developer Training

- <i class="fa fa-youtube-play youtube" aria-hidden="true"></i> [Introduction to XSS](https://www.youtube.com/watch?v=PXR8PTojHmc&t=7785s)
- <i class="fa fa-youtube-play youtube" aria-hidden="true"></i> [Reflected XSS](https://youtu.be/2VFavqfDS6w?t=603s)
- <i class="fa fa-youtube-play youtube" aria-hidden="true"></i> [Persistent XSS](https://youtu.be/2VFavqfDS6w?t=643)
- <i class="fa fa-youtube-play youtube" aria-hidden="true"></i> [DOM XSS](https://youtu.be/2VFavqfDS6w?t=5871)
- <i class="fa fa-youtube-play youtube" aria-hidden="true"></i> [XSS in depth](https://www.youtube.com/watch?v=2VFavqfDS6w&t=111s)
- <i class="fa fa-youtube-play youtube" aria-hidden="true"></i> [XSS Defense](https://youtu.be/2VFavqfDS6w?t=1685)
- <i class="fa fa-youtube-play youtube" aria-hidden="true"></i> [XSS Defense in Rails](https://youtu.be/2VFavqfDS6w?t=2442)
- <i class="fa fa-youtube-play youtube" aria-hidden="true"></i> [XSS Defense with HAML](https://youtu.be/2VFavqfDS6w?t=2796)
- <i class="fa fa-youtube-play youtube" aria-hidden="true"></i> [JavaScript URLs](https://youtu.be/2VFavqfDS6w?t=3274)
- <i class="fa fa-youtube-play youtube" aria-hidden="true"></i> [URL encoding context](https://youtu.be/2VFavqfDS6w?t=3494)
- <i class="fa fa-youtube-play youtube" aria-hidden="true"></i> [Validating Untrusted URLs in Ruby](https://youtu.be/2VFavqfDS6w?t=3936)
- <i class="fa fa-youtube-play youtube" aria-hidden="true"></i> [HTML Sanitization](https://youtu.be/2VFavqfDS6w?t=5075)
- <i class="fa fa-youtube-play youtube" aria-hidden="true"></i> [DOMPurify](https://youtu.be/2VFavqfDS6w?t=5381)
- <i class="fa fa-youtube-play youtube" aria-hidden="true"></i> [Safe Client-side JSON Handling](https://youtu.be/2VFavqfDS6w?t=6334)
- <i class="fa fa-youtube-play youtube" aria-hidden="true"></i> [iframe sandboxing](https://youtu.be/2VFavqfDS6w?t=7043)
- <i class="fa fa-youtube-play youtube" aria-hidden="true"></i> [Input Validation](https://youtu.be/2VFavqfDS6w?t=7489)
- <i class="fa fa-youtube-play youtube" aria-hidden="true"></i> [Validate size limits](https://youtu.be/2VFavqfDS6w?t=7582)
- <i class="fa fa-youtube-play youtube" aria-hidden="true"></i> [RoR model validators](https://youtu.be/2VFavqfDS6w?t=7636)
- <i class="fa fa-youtube-play youtube" aria-hidden="true"></i> [Allowlist input validation](https://youtu.be/2VFavqfDS6w?t=7816)
- <i class="fa fa-youtube-play youtube" aria-hidden="true"></i> [Content Security Policy](https://www.youtube.com/watch?v=2VFavqfDS6w&t=12991s)

## Path Traversal guidelines

### Description

Path Traversal vulnerabilities grant attackers access to arbitrary directories and files on the server that is executing an application, including data, code or credentials.

### Impact

Path Traversal attacks can lead to multiple critical and high severity issues, like arbitrary file read, remote code execution or information disclosure.

### When to consider

When working with user-controlled filenames/paths and file system APIs.

### Mitigation and prevention

In order to prevent Path Traversal vulnerabilities, user-controlled filenames or paths should be validated before being processed.

- Comparing user input against an allowlist of allowed values or verifying that it only contains allowed characters.
- After validating the user supplied input, it should be appended to the base directory and the path should be canonicalized using the file system API.

#### GitLab specific validations

The methods `Gitlab::Utils.check_path_traversal!()` and `Gitlab::Utils.check_allowed_absolute_path!()`
can be used to validate user-supplied paths and prevent vulnerabilities.
`check_path_traversal!()` will detect their Path Traversal payloads and accepts URL-encoded paths.
`check_allowed_absolute_path!()` will check if a path is absolute and whether it is inside the allowed path list. By default, absolute
paths are not allowed, so you need to pass a list of allowed absolute paths to the `path_allowlist`
parameter when using `check_allowed_absolute_path!()`.

To use a combination of both checks, follow the example below:

```ruby
path = Gitlab::Utils.check_path_traversal!(path)
Gitlab::Utils.check_allowed_absolute_path!(path, path_allowlist)
```

In the REST API, we have the [`FilePath`](https://gitlab.com/gitlab-org/security/gitlab/-/blob/master/lib/api/validations/validators/file_path.rb)
validator that can be used to perform the checking on any file path argument the endpoints have.
It can be used as follows:

```ruby
requires :file_path, type: String, file_path: { allowlist: ['/foo/bar/', '/home/foo/', '/app/home'] }
```

The Path Traversal check can also be used to forbid any absolute path:

```ruby
requires :file_path, type: String, file_path: true
```

Absolute paths are not allowed by default. If allowing an absolute path is required, you
need to provide an array of paths to the parameter `allowlist`.

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

#### Ruby

Consider using `system("command", "arg0", "arg1", ...)` whenever you can. This prevents an attacker
from concatenating commands.

For more examples on how to use shell commands securely, consult
[Guidelines for shell commands in the GitLab codebase](shell_commands.md).
It contains various examples on how to securely call OS commands.

#### Go

Go has built-in protections that usually prevent an attacker from successfully injecting OS commands.

Consider the following example:

```golang
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

```golang
out, _ = exec.Command("sh", "-c", "echo 1 | cat /etc/passwd").Output()
```

This outputs `1` followed by the content of `/etc/passwd`.

## GitLab Internal Authorization

### Introduction

There are some cases where `users` passed in the code is actually referring to a `DeployToken`/`DeployKey` entity instead of a real `User`, because of the code below in **`/lib/api/api_guard.rb`**

```ruby
      def find_user_from_sources
        strong_memoize(:find_user_from_sources) do
          deploy_token_from_request ||
            find_user_from_bearer_token ||
            find_user_from_job_token ||
            user_from_warden
        end
      end
```

### Past Vulnerable Code

In some scenarios such as [this one](https://gitlab.com/gitlab-org/gitlab/-/issues/237795), user impersonation is possible because a `DeployToken` ID can be used in place of a `User` ID. This happened because there was no check on the line with `Gitlab::Auth::CurrentUserMode.bypass_session!(user.id)`. In this case, the `id` is actually a `DeployToken` ID instead of a `User` ID.

```ruby
      def find_current_user!
        user = find_user_from_sources
        return unless user

        # Sessions are enforced to be unavailable for API calls, so ignore them for admin mode
        Gitlab::Auth::CurrentUserMode.bypass_session!(user.id) if Gitlab::CurrentSettings.admin_mode

        unless api_access_allowed?(user)
          forbidden!(api_access_denied_message(user))
        end
```

### Best Practices

In order to prevent this from happening, it is recommended to use the method `user.is_a?(User)` to make sure it returns `true` when we are expecting to deal with a `User` object. This could prevent the ID confusion from the method `find_user_from_sources` mentioned above. Below code snippet shows the fixed code after applying the best practice to the vulnerable code above.

```ruby
      def find_current_user!
        user = find_user_from_sources
        return unless user

        if user.is_a?(User) && Gitlab::CurrentSettings.admin_mode
          # Sessions are enforced to be unavailable for API calls, so ignore them for admin mode
          Gitlab::Auth::CurrentUserMode.bypass_session!(user.id)
        end

        unless api_access_allowed?(user)
          forbidden!(api_access_denied_message(user))
        end
```
