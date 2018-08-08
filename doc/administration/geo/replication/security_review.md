# Geo security review (Q&A)

The following security review of the Geo feature set focuses on security
aspects of the feature as they apply to customers running their own GitLab
instances. The review questions are based in part on the [application security architecture](https://www.owasp.org/index.php/Application_Security_Architecture_Cheat_Sheet)
questions from [owasp.org](https://www.owasp.org).

## Business Model

### What geographic areas does the application service?

- This varies by customer. Geo allows customers to deploy to multiple areas,
   and they get to choose where they are.
- Region and node selection is entirely manual.

## Data Essentials

### What data does the application receive, produce, and process?

- Geo streams almost all data held by a GitLab instance between sites. This
  includes full database replication, most files (user-uploaded attachments,
  etc) and repository + wiki data. In a typical configuration, this will
  happen across the public Internet, and be TLS-encrypted.
- PostgreSQL replication is TLS-encrypted.
- See also: [only TLSv1.2 should be supported](https://gitlab.com/gitlab-org/omnibus-gitlab/issues/2948)

### How can the data be classified into categories according to its sensitivity?

- GitLab’s model of sensitivity is centered around public vs. internal vs.
private projects. Geo replicates them all indiscriminately. “Selective sync”
exists for files and repositories (but not database content), which would permit
only less-sensitive projects to be replicated to a secondary if desired.
- See also: [developing a data classification policy](https://gitlab.com/gitlab-com/security/issues/4).

### What data backup and retention requirements have been defined for the application?

- Geo is designed to provide replication of a certain subset of the application
data. It is part of the solution, rather than part of the problem.

## End-Users

### Who are the application's end‐users?

- Geo nodes (secondaries) are created in regions that are distant (in terms of
  Internet latency) from the main GitLab installation (the primary). They are
  intended to be used by anyone who would ordinarily use the primary, who finds
  that the secondary is closer to them (in terms of Internet latency).

### How do the end‐users interact with the application?

- A Geo secondary node provides all the interfaces a Geo primary node does
(notably a HTTP/HTTPS web application, and HTTP/HTTPS or SSH git repository
access), but is constrained to read-only activities. The principal use case is
envisioned to be cloning git repositories from the secondary in favor of the
primary, but end-users may use the GitLab web interface to view projects,
issues, merge requests, snippets, etc.

### What security expectations do the end‐users have?

- The replication process must be secure. It would typically be unacceptable to
transmit the entire database contents or all files and repositories across the
public Internet in plaintext, for instance.
- The Geo secondary must have the same access controls over its content as the
primary - unauthenticated users must not be able to gain access to privileged
information on the primary by querying the secondary.
- Attackers must not be able to impersonate the secondary to the primary, and
thus gain access to privileged information.

## Administrators

### Who has administrative capabilities in the application?

- Nothing Geo-specific. Any user where `admin: true` is set in the database is
considered an admin with super-user privileges.
- See also: [more granular access control](https://gitlab.com/gitlab-org/gitlab-ce/issues/32730)
(not geo-specific)
- Much of Geo’s integration (database replication, for instance) must be
configured with the application, typically by system administrators.

### What administrative capabilities does the application offer?

- Geo secondaries may be added, modified, or removed by users with
administrative access.
- The replication process may be controlled (start/stop) via the Sidekiq
administrative controls.

## Network

### What details regarding routing, switching, firewalling, and load‐balancing have been defined?

- Geo requires the primary and secondary to be able to communicate with each
other across a TCP/IP network. In particular, the secondaries must be able to
access HTTP/HTTPS and PostgreSQL services on the primary.

### What core network devices support the application?

- Varies from customer to customer.

### What network performance requirements exist?

- Maximum replication speeds between primary and secondary is limited by the
available bandwidth between sites. No hard requirements exist - time to complete
replication (and ability to keep up with changes on the primary) is a function
of the size of the data set, tolerance for latency, and available network
capacity.

### What private and public network links support the application?

- Customers choose their own networks. As sites are intended to be
geographically separated, it is envisioned that replication traffic will pass
over the public Internet in a typical deployment, but this is not a requirement.

## Systems

### What operating systems support the application?

- Geo imposes no additional restrictions on operating system (see the
  [GitLab installation](https://about.gitlab.com/installation/) page for more
  details), however we recommend using the operating systems listed in the [Geo documentation](http://docs.gitlab.com/ee/gitlab-geo/#geo-recommendations). 

### What details regarding required OS components and lock‐down needs have been defined?

- The recommended installation method (Omnibus) packages most components itself.
A from-source installation method exists. Both are documented at
https://docs.gitlab.com/ee/gitlab-geo/
- There are significant dependencies on the system-installed OpenSSH daemon (Geo
  requires users to set up custom authentication methods) and the omnibus or
  system-provided PostgreSQL daemon (it must be configured to listen on TCP,
  additional users and replication slots must be added, etc).
- The process for dealing with security updates (for example, if there is a
  significant vulnerability in OpenSSH or other services, and the customer
  wants to patch those services on the OS) is identical to the non-Geo
  situation: security updates to OpenSSH would be provided to the user via the
  usual distribution channels. Geo introduces no delay there.

## Infrastructure Monitoring

### What network and system performance monitoring requirements have been defined?

- None specific to Geo.

### What mechanisms exist to detect malicious code or compromised application components?

- None specific to Geo.

### What network and system security monitoring requirements have been defined?

- None specific to Geo.

## Virtualization and Externalization

### What aspects of the application lend themselves to virtualization?

- All.

## What virtualization requirements have been defined for the application?

- Nothing Geo-specific, but everything in GitLab needs to have full
functionality in such an environment.

### What aspects of the product may or may not be hosted via the cloud computing model?

- GitLab is “cloud native” and this applies to Geo as much as to the rest of the
product. Deployment in clouds is a common and supported scenario.

## If applicable, what approach(es) to cloud computing will be taken (Managed Hosting versus "Pure" Cloud, a "full machine" approach such as AWS-EC2 versus a "hosted database" approach such as AWS-RDS and Azure, etc)?

- To be decided by our customers, according to their operational needs.

## Environment

### What frameworks and programming languages have been used to create the application?

- Ruby on Rails, Ruby.

### What process, code, or infrastructure dependencies have been defined for the application?

- Nothing specific to Geo.

### What databases and application servers support the application?

- PostgreSQL >= 9.6, Redis, Sidekiq, Unicorn.

### How will database connection strings, encryption keys, and other sensitive components be stored, accessed, and protected from unauthorized detection?

- There are some Geo-specific values. Some are shared secrets which must be
securely transmitted from the primary to the secondary at setup time. Our
documentation recommends transmitting them from the primary to the system
administrator via SSH, and then back out to the secondary in the same manner.
In particular, this includes the PostgreSQL replication credentials and a secret
key (`db_key_base`) which is used to decrypt certain columns in the database.
The `db_key_base` secret is stored unencrypted on the filesystem, in
`/etc/gitlab/gitlab-secrets.json`, along with a number of other secrets. There is
no at-rest protection for them.

## Data Processing

### What data entry paths does the application support?

- Data is entered via the web application exposed by GitLab itself. Some data is
also entered using system administration commands on the GitLab servers (e.g.,
  `gitlab-ctl set-primary-node`).
- Secondaries also receive inputs via PostgreSQL streaming replication from the
primary.

### What data output paths does the application support?

- Primaries output via PostgreSQL streaming replication to the secondary.
Otherwise, principally via the web application exposed by GitLab itself, and via
SSH `git clone` operations initiated by the end-user.

### How does data flow across the application's internal components?

- Secondaries and primaries interact via HTTP/HTTPS (secured with JSON web
  tokens) and via PostgreSQL streaming replication.
- Within a primary or secondary, the SSOT is the filesystem and the database
(including Geo tracking database on secondary). The various internal components
are orchestrated to make alterations to these stores.

### What data input validation requirements have been defined?

- Secondaries must have a faithful replication of the primary’s data.

### What data does the application store and how?

- Git repositories and files, tracking information related to the them, and the
GitLab database contents.

### What data is or may need to be encrypted and what key management requirements have been defined?

- Neither primaries or secondaries encrypt Git repository or filesystem data at
rest. A subset of database columns are encrypted at rest using the `db_otp_key`
- a static secret shared across all hosts in a GitLab deployment.
- In transit, data should be encrypted, although the application does permit
communication to proceed unencrypted. The two main transits are the secondary’s
replication process for PostgreSQL, and for git repositories/files. Both should
be protected using TLS, with the keys for that managed via Omnibus per existing
configuration for end-user access to GitLab.

### What capabilities exist to detect the leakage of sensitive data?

- Comprehensive system logs exist, tracking every connection to GitLab and
PostgreSQL.

### What encryption requirements have been defined for data in transit - including transmission over WAN, LAN, SecureFTP, or publicly accessible protocols such as http: and https:?

- Data must have the option to be encrypted in transit, and be secure against
both passive and active attack (e.g., MITM attacks should not be possible).

## Access

### What user privilege levels does the application support?

- Geo adds one type of privilege: secondaries can access a special Geo API to
download files over HTTP/HTTPS, and to clone repositories using HTTP/HTTPS.

### What user identification and authentication requirements have been defined?

- Geo secondaries identify to Geo primaries via OAuth or JWT authentication
based on the shared database (HTTP access) or a PostgreSQL replication user (for
database replication). The database replication also requires IP-based access
controls to be defined.

### What user authorization requirements have been defined?

- Secondaries must only be able to *read* data. They are not currently able to
mutate data on the primary.

### What session management requirements have been defined?

- Geo JWTs are defined to last for only two minutes before needing to be
regenerated.

### What access requirements have been defined for URI and Service calls?

- A Geo secondary makes many calls to the primary's API. This is how file
replication proceeds, for instance. This endpoint is only accessible with a JWT
token.
- The primary also makes calls to the secondary to get status information.

## Application Monitoring

### What application auditing requirements have been defined? How are audit and debug logs accessed, stored, and secured?

- Structured JSON log is written to the filesystem, and can also be ingested
into a Kibana installation for further analysis.
