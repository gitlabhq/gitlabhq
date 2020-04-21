# Security Guidelines

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
Some situations may reveal [sensitive data](https://gitlab.com/gitlab-com/gl-infra/production/issues/477) or allow a malicious actor to perform [harmful actions](https://gitlab.com/gitlab-org/gitlab/issues/8180).
The overall impact depends heavily on what resources can be accessed or modified improperly.

A common vulnerability when permission checks are missing is called [IDOR](https://www.owasp.org/index.php/Testing_for_Insecure_Direct_Object_References_(OTG-AUTHZ-004)) for Insecure Direct Object References.

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
- Naming convention to ease auditability: to be defined, e.g. a subfolder containing those specific permission tests or a `#permissions` block

Be careful to **also test [visibility levels](https://gitlab.com/gitlab-org/gitlab-foss/-/blob/master/doc/development/permissions.md#feature-specific-permissions)** and not only project access rights.

Some example of well implemented access controls and tests:

1. [example1](https://dev.gitlab.org/gitlab/gitlab-ee/merge_requests/710/diffs?diff_id=13750#af40ef0eaae3c1e018809e1d88086e32bccaca40_43_43)
1. [example2](https://dev.gitlab.org/gitlab/gitlabhq/merge_requests/2511/diffs#ed3aaab1510f43b032ce345909a887e5b167e196_142_155)
1. [example3](https://dev.gitlab.org/gitlab/gitlabhq/merge_requests/3170/diffs?diff_id=17494)

**NB:** any input from development team is welcome, e.g. about rubocop rules.

## Regular Expressions guidelines

### Anchors / Multi line

Unlike other programming languages (e.g. Perl or Python) Regular Expressions are matching multi-line by default in Ruby. Consider the following example in Python:

```python
import re
text = "foo\nbar"
matches = re.findall("^bar$",text)
print(matches)
```

The Python example will output an emtpy array (`[]`) as the matcher considers the whole string `foo\nbar` including the newline (`\n`). In contrast Ruby's Regular Expression engine acts differently:

```ruby
text = "foo\nbar"
p text.match /^bar$/
```

The output of this example is `#<MatchData "bar">`, as Ruby treats the input `text` line by line. In order to match the whole __string__ the Regex anchors `\A` and `\z` should be used according to [Rubular](https://rubular.com/).

#### Impact

This Ruby Regex speciality can have security impact, as often regular expressions are used for validations or to impose restrictions on user-input.

#### Examples

GitLab specific examples can be found [here](https://gitlab.com/gitlab-org/gitlab/issues/36029#note_251262187) and [there](https://gitlab.com/gitlab-org/gitlab/issues/33569).

Another example would be this fictional Ruby On Rails controller:

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

### Further Links

- [Rubular](https://rubular.com/) is a nice online tool to fiddle with Ruby Regexps.

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
  that could be used in further attacks. [More details](https://gitlab.com/gitlab-org/gitlab-foss/issues/51327).
- Reading internal services, including cloud service metadata.
  - The latter can be a serious problem, because an attacker can obtain keys that allow control of the victim's cloud infrastructure. (This is also a good reason
  to give only necessary privileges to the token.). [More details](https://gitlab.com/gitlab-org/gitlab-foss/issues/51490).
- When combined with CRLF vulnerability, remote code execution. [More details](https://gitlab.com/gitlab-org/gitlab-foss/issues/41293)

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
connection library for 3rd-party gems. This is preferrable over re-implementing
the mitigations for a new feature.

- [More details](https://dev.gitlab.org/gitlab/gitlabhq/merge_requests/2530/diffs)

#### Feature-specific Mitigations

For situtions in which a whitelist or GitLab:HTTP cannot be used, it will be necessary to implement mitigations directly in the feature. It is best to validate the destination IP addresses themselves, not just domain names, as DNS can be controlled by the attacker. Below are a list of mitigations that should be implemented.

**Important Note:** There are many tricks to bypass common SSRF validations. If feature-specific mitigations are necessary, they should be reviewed by the AppSec team, or a developer who has worked on SSRF mitigations previously.

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

See [url_blocker_spec.rb](https://gitlab.com/gitlab-org/gitlab/-/blob/master/spec/lib/gitlab/url_blocker_spec.rb) for examples of SSRF payloads

## XSS guidelines

### Description

Cross site scripting (XSS) is an issue where malicious JavaScript code gets injected into a trusted web application and executed in a client's browser. The input is intended to be data, but instead gets treated as code by the browser.

XSS issues are commonly classified in three categories, by their delivery method:

- [Persistent XSS](https://owasp.org/www-community/Types_of_Cross-Site_Scripting#stored-xss-aka-persistent-or-type-i)
- [Reflected XSS](https://owasp.org/www-community/Types_of_Cross-Site_Scripting#reflected-xss-aka-non-persistent-or-type-ii)
- [DOM XSS](https://owasp.org/www-community/Types_of_Cross-Site_Scripting#dom-based-xss-aka-type-0)

### Impact

The injected client-side code is executed on the victim's browser in the context of their current session. This means the attacker could perform any same action the victim would normally be able to do through a browser. The attacker would also have the ability to:

- [log victim keystrokes](https://youtu.be/2VFavqfDS6w?t=1367)
- launch a network scan from the victim's browser
- potentially [obtain the victim's session tokens](https://youtu.be/2VFavqfDS6w?t=739)
- perform actions that lead to data loss/theft or account takeover

Much of the impact is contingent upon the function of the application and the capabilities of the victim's session. For further impact possibilities, please check out [the beef project](https://beefproject.com/).

### When to consider?

When user submitted data is included in responses to end users, which is just about anywhere.

### Mitigation

In most situations, a two-step solution can be utilized: input validation and output encoding in the appropriate context.

#### Input validation

- [Input Validation](https://youtu.be/2VFavqfDS6w?t=7489)

##### Setting expectations

For any and all input fields, ensure to define expectations on the type/format of input, the contents, [size limits](https://youtu.be/2VFavqfDS6w?t=7582), the context in which it will be output. It's important to work with both security and product teams to determine what is considered acceptable input.

##### Validate input

- Treat all user input as untrusted.
- Based on the expectations you [defined above](#setting-expectations):
  - Validate the [input size limits](https://youtu.be/2VFavqfDS6w?t=7582).
  - Validate the input using a [whitelist approach](https://youtu.be/2VFavqfDS6w?t=7816) to only allow characters through which you are expecting to receive for the field.
    - Input which fails validation should be **rejected**, and not sanitized.

Note that blacklists should be avoided, as it is near impossible to block all [variations of XSS](https://www.owasp.org/index.php/XSS_Filter_Evasion_Cheat_Sheet).

#### Output encoding

Once you've [determined when and where](#setting-expectations) the user submitted data will be output, it's important to encode it based on the appropriate context. For example:

- Content placed inside HTML elements need to be [HTML entity encoded](https://cheatsheetseries.owasp.org/cheatsheets/Cross_Site_Scripting_Prevention_Cheat_Sheet.html#rule-1---html-escape-before-inserting-untrusted-data-into-html-element-content).
- Content placed into a JSON response needs to be [JSON encoded](https://cheatsheetseries.owasp.org/cheatsheets/Cross_Site_Scripting_Prevention_Cheat_Sheet.html#rule-31---html-escape-json-values-in-an-html-context-and-read-the-data-with-jsonparse).
- Content placed inside [HTML URL GET parameters](https://youtu.be/2VFavqfDS6w?t=3494) need to be [URL-encoded](https://cheatsheetseries.owasp.org/cheatsheets/Cross_Site_Scripting_Prevention_Cheat_Sheet.html#rule-5---url-escape-before-inserting-untrusted-data-into-html-url-parameter-values)
- [Additional contexts may require context-specific encoding](https://youtu.be/2VFavqfDS6w?t=2341).

### Additional info

#### Mitigating XSS in Rails

- [XSS Defense in Rails](https://youtu.be/2VFavqfDS6w?t=2442)
- [XSS Defense with HAML](https://youtu.be/2VFavqfDS6w?t=2796)
- [Validating Untrusted URLs in Ruby](https://youtu.be/2VFavqfDS6w?t=3936)
- [RoR Model Validators](https://youtu.be/2VFavqfDS6w?t=7636)

#### GitLab specific libraries for mitigating XSS

##### Vue

- [isSafeURL](https://gitlab.com/gitlab-org/gitlab/-/blob/v12.7.5-ee/app/assets/javascripts/lib/utils/url_utility.js#L190-207)

#### Content Security Policy

- [Content Security Policy](https://www.youtube.com/watch?v=2VFavqfDS6w&t=12991s)
- [Use nonce-based Content Security Policy for inline JavaScript](https://gitlab.com/gitlab-org/gitlab-foss/issues/65330)

#### Free form input fields

##### Sanitization

- [HTML Sanitization](https://youtu.be/2VFavqfDS6w?t=5075)
- [DOMPurify](https://youtu.be/2VFavqfDS6w?t=5381)

##### `iframe` sandboxes

- [iframe sandboxing](https://youtu.be/2VFavqfDS6w?t=7043)

### Select examples of past XSS issues affecting GitLab

- [Stored XSS in user status](https://gitlab.com/gitlab-org/gitlab-foss/issues/55320)

### Developer Training

- [Introduction to XSS](https://www.youtube.com/watch?v=PXR8PTojHmc&t=7785s)
- [Reflected XSS](https://youtu.be/2VFavqfDS6w?t=603s)
- [Persistent XSS](https://youtu.be/2VFavqfDS6w?t=643)
- [DOM XSS](https://youtu.be/2VFavqfDS6w?t=5871)
- [XSS in depth](https://www.youtube.com/watch?v=2VFavqfDS6w&t=111s)
- [XSS Defense](https://youtu.be/2VFavqfDS6w?t=1685)
- [XSS Defense in Rails](https://youtu.be/2VFavqfDS6w?t=2442)
- [XSS Defense with HAML](https://youtu.be/2VFavqfDS6w?t=2796)
- [JavaScript URLs](https://youtu.be/2VFavqfDS6w?t=3274)
- [URL encoding context](https://youtu.be/2VFavqfDS6w?t=3494)
- [Validating Untrusted URLs in Ruby](https://youtu.be/2VFavqfDS6w?t=3936)
- [HTML Sanitization](https://youtu.be/2VFavqfDS6w?t=5075)
- [DOMPurify](https://youtu.be/2VFavqfDS6w?t=5381)
- [Safe Client-side JSON Handling](https://youtu.be/2VFavqfDS6w?t=6334)
- [iframe sandboxing](https://youtu.be/2VFavqfDS6w?t=7043)
- [Input Validation](https://youtu.be/2VFavqfDS6w?t=7489)
- [Validate size limits](https://youtu.be/2VFavqfDS6w?t=7582)
- [RoR model validators](https://youtu.be/2VFavqfDS6w?t=7636)
- [Whitelist input validation](https://youtu.be/2VFavqfDS6w?t=7816)
- [Content Security Policy](https://www.youtube.com/watch?v=2VFavqfDS6w&t=12991s)
