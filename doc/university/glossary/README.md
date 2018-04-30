---
comments: false
---

# What is the Glossary

This contains a simplified list and definitions of some of the terms that you will encounter in your day to day activities when working with GitLab.
Please add any terms that you discover that you think would be useful for others.

### 2FA

User authentication by combination of 2 different steps during login. This allows for [more security](https://about.gitlab.com/handbook/security/).

### Access Levels

Process of selective restriction to create, view, modify or delete a resource based on a set of assigned permissions. See [GitLab's Permission Guidelines](../../user/permissions.md)

### Active Directory (AD)

A Microsoft-based [directory service](https://msdn.microsoft.com/en-us/library/bb742424.aspx) for windows domain networks. It uses LDAP technology under the hood.

### Agile

Building and [delivering software](http://agilemethodology.org/) in phases/parts rather than trying to build everything at once then delivering to the user/client. The latter is known as the WaterFall model.

### Amazon RDS

External reference: <http://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/CHAP_Storage.html>

### Application Lifecycle Management (ALM)

The entire product lifecycle management process for an application, from requirements management, development, and testing until deployment. GitLab has [advantages](https://docs.google.com/presentation/d/1vCU-NbZWz8NTNK8Vu3y4zGMAHb5DpC8PE5mHtw1PWfI/edit#slide=id.g72f2e4906_2_288) over both legacy and modern ALM tools.

### Artifactory

A version control [system](https://www.jfrog.com/open-source/#os-arti) for non-text files.

### Artifacts

Objects (usually binary and large) created by a build process. These can include use cases, class diagrams, requirements and design documents.

### Atlassian

A [company](https://www.atlassian.com) that develops software products for developers and project managers including Bitbucket, Jira, Hipchat, Confluence, Bamboo.

### Audit Log

Also called an [audit trail](https://en.wikipedia.org/wiki/Audit_trail), an audit log is a document that records an event in an IT system.

### Auto Defined User Group

User groups are a way of centralizing control over important management tasks, particularly access control and password policies. A simple example of such groups are the users and the admins groups.
In most of the cases these groups are auto defined in terms of access, rules of usage, conditions to be part of, etc.

### Bamboo

Atlassian's CI tool similar to GitLab CI and Jenkins.

### Basic Subscription

Entry level [subscription](https://about.gitlab.com/pricing/) for GitLab EE currently available in packs of 10.

### Bitbucket

Atlassian's web hosting service for Git and Mercurial Projects. Read about [migrating](https://docs.gitlab.com/ce/workflow/importing/import_projects_from_bitbucket.html) from BitBucket to a GitLab instance.

### Branch

A branch is a parallel version of a repository. This allows you to work on the repository without affecting the "master" branch, and without affecting the current "live" version. When you have made all your changes to your branch you can then merge to the master. When your merge request is accepted your changes will be "live."

### Branded Login

Having your own logo on [your GitLab instance login page](https://docs.gitlab.com/ee/customization/branded_login_page.html) instead of the GitLab logo.

### Job triggers (Build Triggers)
These protect your code base against breaks, for instance when a team is working on the same project. Learn about [setting up](https://docs.gitlab.com/ce/ci/triggers/README.html) job triggers.

### CEPH

 A distributed object store and file [system](http://ceph.com/) designed to provide excellent performance, reliability and scalability.

### ChatOps

The ability to [initiate an action](https://gitlab.com/gitlab-org/omnibus-gitlab/issues/1412) from chat. ChatBots run in your chat application and give you the ability to do "anything" from chat.

### Clone

A [copy](https://git-scm.com/docs/git-clone) of a repository stored on your machine that allows you to use your own editor without being online, but still tracks the changes made remotely.

### Code Review

Examination of a program's code. The main aim is to maintain high quality standards of code that is being shipped. Merge requests [serve as a code review tool](https://about.gitlab.com/2014/09/29/gitlab-flow/) in GitLab.

### Code Snippet

A small amount of code, usually selected for the purpose of showing other developers how to do something specific or reproduce a problem.

### Collaborator

Person with read and write access to a repository who has been invited by repository owner.

### Commit

A [change](https://git-scm.com/docs/git-commit) (revision) to a file that also creates an ID, allowing you to see revision history and the author of the changes.

### Community

[Everyone](https://about.gitlab.com/community/) who uses GitLab.

### Confluence

Atlassian's product for collaboration on documents and projects.

### Continuous Delivery

A [software engineering approach](https://about.gitlab.com/2016/08/05/continuous-integration-delivery-and-deployment-with-gitlab/) in which continuous integration, automated testing, and automated deployment capabilities allow software to be developed and deployed rapidly, reliably and repeatedly with minimal human intervention. Still, the deployment to production is defined strategically and triggered manually. [Amazon moves toward continuous delivery](https://www.youtube.com/watch?v=esEFaY0FDKc)

### Continuous Deployment

A [software development practice](https://about.gitlab.com/2016/08/05/continuous-integration-delivery-and-deployment-with-gitlab/) in which every code change goes through the entire pipeline and is put into production automatically, resulting in many production deployments every day. It does everything that Continuous Delivery does, but the process is fully automated, there's no human intervention at all. [The difference between Continuous Delivery and Continuous Integration.](https://www.youtube.com/watch?v=igwFj8PPSnw)

### Continuous Integration

A [software development practice](https://about.gitlab.com/2016/08/05/continuous-integration-delivery-and-deployment-with-gitlab/) in which you build and test software every time a developer pushes code to the application, and it happens several times a day. [Thoughtworks discusses continuous integration.](https://www.thoughtworks.com/continuous-integration)

### Contributor

Term used for a person contributing to an open source project.

### Conversational Development (ConvDev)

A [natural evolution](https://about.gitlab.com/2016/09/14/gitlab-live-event-recap/) of software development that carries a conversation across functional groups throughout the development process, enabling developers to track the full path of development in a cohesive and intuitive way. ConvDev accelerates the development lifecycle by fostering collaboration and knowledge sharing from idea to production.

### Cycle Analytics

See <https://gitlab.com/gitlab-org/gitlab-ce/issues/22458>

### Cycle Time

The time it takes to move from [idea to production](https://about.gitlab.com/2016/08/05/continuous-integration-delivery-and-deployment-with-gitlab/#from-idea-to-production-with-gitlab).

### Data Centre

Atlassian product for High Availability.

### Dependencies

As in "specify [dependencies](https://gitlab.com/gitlab-org/gitlab-ce/issues/14728) between stages."

### Deploy Keys

A [SSH key](https://docs.gitlab.com/ce/gitlab-basics/create-your-ssh-keys.html)stored on your server that grants access to a single GitLab repository. This is used by a GitLab runner to clone a project's code so that tests can be run against the checked out code.

### Developer

For us at GitLab, this means a software developer, or someone who makes software. It is also one of the levels of access in our multi-level approval system.

### DevOps

The intersection of software engineering, quality assurance, and technology operations. Explore more DevOps topics in the [glossary by XebiaLabs](https://xebialabs.com/glossary/)

### Diff

The difference between two commits, or saved changes. This will also be shown visually after the changes.

### Directory

A folder used for storing multiple files.

### Docker Container Registry

A [feature](https://docs.gitlab.com/ce/user/project/container_registry.html) of [GitLab projects](https://about.gitlab.com/2016/05/23/gitlab-container-registry/). Containers wrap up a piece of software in a complete filesystem that contains everything it needs to run: code, runtime, system tools, system libraries – anything you can install on a server. This guarantees that it will always run the same, regardless of the environment it is running in.

### Dynamic Environment (review apps)

### EC2 Instance

### Elasticsearch

Elasticsearch is a flexible, scalable and powerful search service. When [enabled](https://gitlab.com/help/integration/elasticsearch.md), it helps keep GitLab's search fast when dealing with a huge amount of data.

### Emacs

External reference: <https://www.masteringemacs.org/article/mastering-key-bindings-emacs>

### First Byte

External reference: <https://en.wikipedia.org/wiki/Time_To_First_Byte>

First Byte (sometimes referred to as time to first byte or [TTFB](https://en.wikipedia.org/wiki/Time_To_First_Byte)) measures the time between making a request and receiving the first byte of information in return. As a result, First Byte encompasses everything that is the backend as well as network transit issues. It differs from [_Speed Index_](#speed-index) mostly by frontend related issues which are included in Speed Index such as javascript loading, page rendering, and so on.

### Fork

Your [own copy](https://docs.gitlab.com/ce/workflow/forking_workflow.html) of a repository that allows you to make changes to the repository without affecting the original.

### Funnel, or: TOFU, MOFU, BOFU

External reference: [Blog post](https://www.weidert.com/whole_brain_marketing_blog/bid/113688/ToFu-MoFu-BoFu-Serving-Up-The-Right-Content-for-Lead-Nurturing)

TOFU: top of funnel
MOFU: middle of funnel
BOFU:  bottom of funnel

### Gerrit

A code review [tool](https://www.gerritcodereview.com/) built on top of Git.

### Git Attributes

A [git attributes file](https://git-scm.com/docs/gitattributes) is a simple text file that gives attributes to pathnames.

### Git Hooks

[Scripts](https://git-scm.com/book/en/v2/Customizing-Git-Git-Hooks) you can use to trigger actions at certain points.

Difference between a [webhook](#webhooks) and a git hook: a git hook is local to its repo (usually) while a webhook is not (it can make API or http calls). So for example if you want your linter to fire before you commit, you can set that up with a git hook. If the linter fails, the commit does not go through. A git hook _can_ be configured to go beyond its repo, e.g. by having it make an API call.

### GitHost.io

A single-tenant solution that provides GitLab CE or EE as a managed service. GitLab Inc. is responsible for installing, updating, hosting, and backing up customers' own private and secure GitLab instance.

### GitHub

A web-based Git repository hosting service with an enterprise offering. Its main features are: issue tracking, pull request with code review, abundancy of integrations and wiki. It offers free public repos, private repos and enterprise services are paid. Read about [importing a project](https://docs.gitlab.com/ce/workflow/importing/import_projects_from_github.html) from GitHub to GitLab.

### GitLab CE

Our free on Premise solution with >100,000 users

### GitLab CI

Our own Continuous Integration [feature](https://about.gitlab.com/gitlab-ci/) that is shipped with each instance

### GitLab EE

Our premium on premise [solution](https://about.gitlab.com/features/#enterprise) that currently has Basic, Standard and Plus subscription packages with additional features and support.

### GitLab.com

Our free SaaS for public and private repositories.

### GitLab Geo

Allows you to replicate your GitLab instance to other geographical locations as a read-only fully operational version. It [can be used](https://docs.gitlab.com/ee/gitlab-geo/README.html) for cloning and fetching projects, in addition to reading any data. This will make working with large repositories over large distances much faster.

### GitLab High Availability

### GitLab Master Plan

Related blog post: <https://about.gitlab.com/2016/09/13/gitlab-master-plan/>.

### GitLab Pages

These allow you to [create websites](https://gitlab.com/help/pages/README.md) for your GitLab projects, groups, or user account.

### GitLab Runner

Related project: <https://gitlab.com/gitlab-org/gitlab-runner>

### Gitolite

An [access layer](https://git-scm.com/book/en/v1/Git-on-the-Server-Gitolite) that sits on top of Git. Users are granted access to repos via a simple config file. As an admin, you only need the users' public SSH key and a username.

### Gitorious

A web-based hosting service for projects using Git. It was acquired by GitLab and we discontinued the service. Read the[Gitorious Acquisition Blog Post](https://about.gitlab.com/2015/03/03/gitlab-acquires-gitorious/).

### Go

An open source programming [language](https://golang.org/).

### Gogs

External reference: <https://gogs.io/>

### GUI/ Git GUI

A portable [graphical interface](https://git-scm.com/docs/git-gui) to Git that allows users to make changes to their repository by making new commits, amending existing ones, creating branches, performing local merges, and fetching/pushing to remote repositories.

### High Availability for Disaster Recovery (HADR)

Sometimes written HA/DR, this usually refers to a strategy for having a failover server in place in case the main server fails.

### Hip Chat

Atlassian's real time chat application for teams, Hip Chat is a competitor to Slack, RocketChat and MatterMost.

### High Availability

Refers to a [system or component](https://about.gitlab.com/high-availability/) that is continuously operational for a desirably long length of time. Availability can be measured relative to "100% operational" or "never failing."

### Inner-sourcing

The [use of](https://about.gitlab.com/2014/09/05/innersourcing-using-the-open-source-workflow-to-improve-collaboration-within-an-organization/) open source development techniques within the corporation.

### Internet Relay Chat (IRC)

An [application layer protocol](http://www.irchelp.org/) that facilitates communication in the form of text.

### Issue Tracker

A [tool](https://docs.gitlab.com/ee/integration/external-issue-tracker.html) used to manage, organize, and maintain a list of issues, making it easier for an organization to manage.

### Jenkins

An Open Source CI tool written using the Java programming language. [Jenkins](https://jenkins-ci.org/) does the same job as GitLab CI, Bamboo, and Travis CI. It is extremely popular. Related [documentation](https://docs.gitlab.com/ee/integration/jenkins.html). 

### Jira

Atlassian's [project management software](https://www.atlassian.com/software/jira), i.e. a complex issue tracker. GitLab [can be configured](https://docs.gitlab.com/ee/project_services/jira.html) to interact with JIRA Core either using an on-premise instance or the SaaS solution that Atlassian offers.

### JUnit

A testing framework for the Java programming language, [JUnit](http://junit.org/junit4/) has been important in the evolution of test-driven development.

### Kerberos

A network authentication [protocol](http://web.mit.edu/kerberos/) that uses secret-key cryptography for security.

### Kubernetes

An open source container cluster manager originally designed by Google. It's basically a platform for automating deployment, scaling, and operations of application containers over clusters of hosts.

### Labels

An [identifier](https://docs.gitlab.com/ce/user/project/labels.html) to describe a group of one or more specific file revisions.

### Lightweight Directory Access Protocol (LDAP)

 A directory (electronic address book) with user information (e.g. name, phone_number etc.)

### LDAP User Authentication

GitLab [integrates](https://docs.gitlab.com/ce/administration/auth/ldap.html) with LDAP to support user authentication. This enables GitLab to sign in people from an LDAP server (i.e., allowing people whose names are on the electronic user directory server to be able to use their LDAP accounts to login.)

### LDAP Group Sync

Allows you to synchronize the members of a GitLab group with one or more LDAP groups.

### Lint

Static code analysis for our various file types. For example, we use [scss-lint](https://github.com/brigade/scss-lint) to ensure that a consistent code styling is respected. Similar tools: rubocop / eslint.

### Load Balancer

A [device](https://en.wikipedia.org/wiki/Load_balancing_(computing)) that distributes network or application traffic across multiple servers.

### Git Large File Storage (LFS)

A way [to enable](https://about.gitlab.com/2015/11/23/announcing-git-lfs-support-in-gitlab/) git to handle large binary files by using reference pointers within small text files to point to the large files. Large files such as high resolution images and videos, audio files, and assets can be called from a remote server.

### Linux

An operating system like Windows or OS X. It is mostly used by software developers and on servers.

### Markdown

A lightweight markup language with plain text formatting syntax designed so that it can be converted to HTML and many other formats using a tool by the same name. Markdown is often used to format readme files, for writing messages in online discussion forums, and to create rich text using a plain text editor. Checkout GitLab's [Markdown guide](https://gitlab.com/help/user/markdown.md).

### Maria DB

A community developed fork/variation of MySQL. MySQL is owned by Oracle.

### Master

Name of the [default branch](https://git-scm.com/book/en/v1/Git-Branching-What-a-Branch-Is) in every git repository.

### Mattermost

An open source, self-hosted messaging alternative to Slack. View GitLab's Mattermost [feature](https://gitlab.com/gitlab-org/gitlab-mattermost).

### Mercurial

A free distributed version control system similar to and a competitor with Git.

### Merge

Takes changes from one branch, and [applies them](https://git-scm.com/docs/git-merge) into another branch.

### Merge Conflict

[Arises](https://about.gitlab.com/2016/09/06/resolving-merge-conflicts-from-the-gitlab-ui/) when a merge can't be performed cleanly between two versions of the same file.

#### Merge Request

[Takes changes](https://docs.gitlab.com/ce/gitlab-basics/add-merge-request.html) from one branch, and applies them into another branch.

### Meteor

A [platform](https://www.meteor.com) for building javascript apps.

### Milestones

Allow you to [organize issues](../../user/project/milestones/index.md) and merge requests in GitLab into a cohesive group, optionally setting a due date. A common use is keeping track of an upcoming software version. Milestones are created per-project.

### Mirror Repositories

A project that is setup to automatically have its branches, tags, and commits [updated from an upstream repository](https://docs.gitlab.com/ee/workflow/repository_mirroring.html). This is useful when a repository you're interested in is located on a different server, and you want to be able to browse its content and activity using the familiar GitLab interface.

### MIT License

A type of software license. It lets people do anything with your code with proper attribution and without warranty. It is the most common license for open source applications written in Ruby on Rails. GitLab CE is issued under this [license](https://docs.gitlab.com/ce/development/licensing.html). This means you can download the code, modify it as you want, and even build a new commercial product using the underlying code and it's not illegal. The only condition is that there is no form of warranty provided by GitLab so whatever happens when you use the code is your own problem.

### Mondo Rescue

A free disaster recovery [software](https://help.ubuntu.com/community/MondoMindi).

#### Mount

External reference: 

As stated on the [wikipedia page](https://en.wikipedia.org/wiki/Mount_(Unix)), "Mounting makes file systems, files, directories, devices and special files available for use and available to the user."

For example, we have NFS servers where the _git files_  reside. In order for a worker node to "see" or "use" the git files, the NFS server needs to be _mounted_ on the worker; that is, the worker needs to know that the NFS server exists and how to connect to it. Think of it as getting a shared drive to show up in your Finder (on Mac) or Explorer (on Windows).

### MySQL

A relational [database](http://www.mysql.com/) owned by Oracle. Currently only supported if you are using EE.

### Namespace

A set of symbols that are used to organize objects of various kinds so that these objects may be referred to by name. Examples of namespaces in action include file systems that assign names to files; programming languages that organize their variables and subroutines in namespaces; and computer networks and distributed systems that assign names to resources, such as computers, printers, websites, (remote) files, etc.

### Nginx

A web [server](https://www.nginx.com/resources/wiki/) (pronounced "engine x"). [It can act]((https://gitlab.com/gitlab-org/omnibus-gitlab/blob/master/doc/settings/nginx.md) as a reverse proxy server for HTTP, HTTPS, SMTP, POP3, and IMAP protocols, as well as a load balancer and an HTTP cache.

### OAuth

An open standard for authorization, commonly used as a way for internet users to log into third party websites using their Microsoft, Google, Facebook or Twitter accounts without exposing their password. GitLab [is](https://docs.gitlab.com/ce/integration/oauth_provider.html) an OAuth2 authentication service provider.

### Omnibus Packages

A way to [package different services and tools](https://docs.gitlab.com/omnibus/) required to run GitLab, so that most developers can install it without laborious configuration.

### On Premise

On your own server. In GitLab, this [refers](https://about.gitlab.com/2015/02/12/why-ship-on-premises-in-the-saas-era/) to the ability to download GitLab EE/GitLab CE and host it on your own server rather than using GitLab.com, which is hosted by GitLab Inc's servers.

### Open Core

GitLab's [business model](https://about.gitlab.com/2016/07/20/gitlab-is-open-core-github-is-closed-source/). Coined by Andrew Lampitt in 2008, the [open core model](https://en.wikipedia.org/wiki/Open_core) primarily involves offering a "core" or feature-limited version of a software product as free and open-source software, while offering "commercial" versions or add-ons as proprietary software.

### Open Source Software

Software for which the original source code is freely [available](https://opensource.org/docs/osd) and may be redistributed and modified. GitLab prioritizes open source [stewardship](https://about.gitlab.com/2016/01/11/being-a-good-open-source-steward/). Including to providing access to the source code, open source software must comply with a number of criteria, among them free distribution and no discrimination against persons, groups, or fields of endeavor.

#### Open Source Stewardship

[Related blog post](https://about.gitlab.com/2016/01/11/being-a-good-open-source-steward/). 

### Owner

The most powerful person on a GitLab project. They have the permissions of all the other users plus the additional permission of being able to destroy (i.e. delete) the project.

### Platform as a Service (PaaS)

Typically referred to in regards to application development, PaaS is a model in which a cloud provider delivers hardware and software tools to its users as a service.

### Perforce

The company that produces Helix.  A commercial, proprietary, centralised VCS well known for its ability to version files of any size and type.  They OEM a re-branded version of GitLab called "GitSwarm" that is tightly integrated with their "GitFusion" product, which in turn represents a portion of a Helix repository (called a depot) as a git repo.

### Phabricator

A suite of web-based software development collaboration tools, including the Differential code review tool, the Diffusion repository browser, the Herald change monitoring tool, the Maniphest bug tracker and the Phriction wiki. Phabricator integrates with Git, Mercurial, and Subversion.

### Piwik Analytics

An open source analytics software to help you analyze web traffic. It is similar to Google Analytics, except that the latter is not open source and information is stored by Google. In Piwik, the information is stored on your own server and hence is fully private.

### Plus Subscription

GitLab Premium EE [subscription](https://about.gitlab.com/pricing/) that includes training and dedicated Account Management and Service Engineer and complete support package.

### PostgreSQL

An [object-relational](https://en.wikipedia.org/wiki/PostgreSQL) database. Touted as the most advanced open source database, it is one of two database management systems [supported by](https://gitlab.com/gitlab-org/omnibus-gitlab/blob/master/doc/settings/database.md) GitLab, the other being MySQL.

### Protected Branches

A [feature](https://docs.gitlab.com/ce/user/project/protected_branches.html) that protects branches from unauthorized pushes, force pushing or deletion.

### Protected Tags

A [feature](https://docs.gitlab.com/ce/user/project/protected_tags.html) that protects tags from unauthorized creation, update or deletion

### Pull

Git command to [synchronize](https://git-scm.com/docs/git-pull) the local repository with the remote repository, by fetching all remote changes and merging them into the local repository.

### Puppet

A popular DevOps [automation tool](https://puppet.com/product/how-puppet-works).

### Push

Git [command](https://git-scm.com/docs/git-push) to send commits from the local repository to the remote repository. Read about [advanced push rules](https://gitlab.com/help/pages/README.md) in GitLab.

### Raketasks

### RE Read Only

Permissions to see a file and its contents, but not change it.

### Rebase

In addition to the merge, the [rebase](https://git-scm.com/book/en/v2/Git-Branching-Rebasing) is a main way to integrate changes from one branch into another.

### Regression

A regression is something that used to work one way in the last release and then we made a **breaking change** and it no longer works the same way.

_or_

A regression is defined as a change that results in a negative impact on the functionality of an existing feature due to recent changes, i.e. the latest release.

### Remote mirroring

### (Git) Repository

A directory where Git [has been initiatlized](https://git-scm.com/book/en/v2/Git-Basics-Getting-a-Git-Repository) to start version controlling your files. The history of your work is stored here. A remote repository is not on your machine, but usually online (like on GitLab.com, for instance). The main remote repository is usually called "Origin."

##### Remote repository

A [repository](https://about.gitlab.com/2015/05/18/simple-words-for-a-gitlab-newbie/) that is not-on-your-machine, so it's anything that is not your computer. Usually, it is online, GitLab.com for instance. The main remote repository is usually called “Origin”.

### Requirements management

Gives your distributed teams a single shared repository to collaborate and share requirements, understand their relationship to tests, and evaluate linked defects. It includes multiple, preconfigured requirement types.

### Revision Control

Also known as version control or source control, this is the management of changes to documents, computer programs, large web sites, and other collections of information. Changes are usually identified by a number or letter code, termed the "revision number," "revision level," or simply "revision."

### RocketChat

An open source chat application for teams, RocketChat is very similar to Slack but it is also open-source.

### Route Table

A route table contains rules (called routes) that determine where network traffic is directed. Each [subnet in a VPC](http://docs.aws.amazon.com/AmazonVPC/latest/UserGuide/VPC_Route_Tables.html) must be associated with a route table.

### Runners

Actual build machines/containers that [run and execute tests](https://gitlab.com/gitlab-org/gitlab-runner) you have specified to be run on GitLab CI.

### Sidekiq

The background job processor GitLab [uses](https://docs.gitlab.com/ce/administration/troubleshooting/sidekiq.html) to asynchronously run tasks.

### Software as a service (SaaS)

Software that is hosted centrally and accessed on-demand (i.e. whenever you want to). This applies to GitLab.com.

### Software Configuration Management (SCM)

This term is often used by people when they mean "Version Control."

#### SCLAU

Abbreviation for SQO Count [Large And Up](https://about.gitlab.com/handbook/sales/#market-segmentation). This is the number of opportunities in large and strategic organizations passed from marketing to sales.

### Scrum 

An Agile [framework](https://www.scrum.org/Resources/What-is-Scrum) designed to typically help complete complex software projects. It's made up of several parts: product requirements backlog, sprint planning, sprint (development), sprint review, and retrospec (analyzing the sprint). The goal is to end up with potentially shippable products.

### Scrum Board

The board used to track the status and progress of each of the sprint backlog items.

### Shell

Terminal on Mac OSX, GitBash on Windows, or Linux Terminal on Linux. You [use git](https://docs.gitlab.com/ce/gitlab-basics/start-using-git.html) and make changes to GitLab projects in your shell. You [use git](https://docs.gitlab.com/ce/gitlab-basics/start-using-git.html) and make changes to GitLab projects in your shell.

### Shell command runner

### Single-tenant

The tenant purchases their own copy of the software and the software can be customized to meet the specific and needs of that customer. [GitHost.io](https://about.gitlab.com/handbook/positioning-faq/) is our provider of single-tenant 'managed cloud' GitLab instances.

### Slack

Real time messaging app for teams that is used internally by  GitLab team members. GitLab users can enable [Slack integration](https://docs.gitlab.com/ce/project_services/slack.html) to trigger push, issue, and merge request events among others.

### Slash commands

### Slave Servers

Also known as secondary servers, these help to spread the load over multiple machines. They also provide backups when the master/primary server crashes.

### Source Code

Program code as typed by a computer programmer (i.e. it has not yet been compiled/translated by the computer to machine language).

### Speed Index

[Speed Index](https://sites.google.com/a/webpagetest.org/docs/using-webpagetest/metrics/speed-index) is "the average time at which visible parts of the page are displayed".

### SSH Key

A unique identifier of a computer. It is used to identify computers without the need for a password (e.g., On GitLab I have [added the ssh key](https://docs.gitlab.com/ce/gitlab-basics/create-your-ssh-keys.html) of all my work machines so that the GitLab instance knows that it can accept code pushes and pulls from this trusted machines whose keys are I have added.)

### Single Sign On (SSO)

An authentication process that allows you enter one username and password to access multiple applications.

### Staging Area

[Staging occurs](https://git-scm.com/book/en/v2/Getting-Started-Git-Basics) before the commit process in git. The staging area is a file, generally contained in your Git directory, that stores information about what will go into your next commit. It’s sometimes referred to as the “index.""

### Standard Subscription

Our mid range EE subscription that includes 24/7 support and support for High Availability [Standard Subscription](https://about.gitlab.com/pricing/).

### Stash

Atlassian's Git on-premise solution. Think of it as Atlassian's GitLab EE, now known as BitBucket Server.

### Static Site Generators (SSGs)

A [software](https://wiki.python.org/moin/StaticSiteGenerator) that takes some text and templates as input and produces html files on the output.

### Subversion

Non-proprietary, centralized version control system.

### Sudo

A program that allows you to perform superuser/administrator actions on Unix Operating Systems (e.g., Linux, OS X.) It actually stands for 'superuser do.'

### Subversion (SVN)

An open source version control system. Read about [migrating from SVN](https://docs.gitlab.com/ce/workflow/importing/migrating_from_svn.html) to GitLab using SubGit.

### Tag

[Represents](https://docs.gitlab.com/ce/api/tags.html) a version of a particular branch at a moment in time.

### Tenancy

#### Multi-tenant

A [multi-tenant](http://whatis.techtarget.com/definition/multi-tenancy) GitLab instance can have any number of customers - such as companies or groups of users using it. GitLab.com is an example of a multi-tenant GitLab instance.

#### Single-tenant

A [single-tenant](http://searchcloudapplications.techtarget.com/definition/single-tenancy) GitLab instance has only one customer - such as a company - using it. On premise GitLab instances are almost exclusively single-tenant.

### Tool Stack

The set of tools used in a process to achieve a common outcome (e.g. set of tools used in Application Lifecycle Management).

### Trac

An open source project management and bug tracking web [application](https://trac.edgewall.org/).

### True-Up licensing model

### Ubuntu

### Untracked files

New files that Git has not [been told](https://git-scm.com/book/en/v2/Git-Basics-Recording-Changes-to-the-Repository) to track previously. Add them by using the command "git add [file path]"

### Upstream repository vs. GitLab repository

[External conversation](https://news.ycombinator.com/item?id=12487112)

### User

Anyone interacting with the software.

### Version Control Software (VCS)

Version control is a system that records changes to a file or set of files over time so that you can recall specific versions later. VCS [has evolved](https://docs.google.com/presentation/d/16sX7hUrCZyOFbpvnrAFrg6tVO5_yT98IgdAqOmXwBho/edit#slide=id.gd69537a19_0_32) from local version control systems, to centralized version control systems, to the present [distributed version control systems](https://en.wikipedia.org/wiki/Distributed_version_control) like Git, Mercurial, Bazaar, and Darcs. If any server dies, and these systems were collaborating via it, any of the client repositories can be copied back up to the server to restore it.

### Virtual Private Cloud (VPC)

A [VPC](https://docs.gitlab.com/ce/university/glossary/README.html#virtual-private-cloud-vpc) is an on demand configurable pool of shared computing resources allocated within a public cloud environment, providing some isolation between the different users using the resources. GitLab users need to create a new Amazon VPC in order to [setup High Availability](https://docs.gitlab.com/ce/university/high-availability/aws/).

### Virtual private server (VPS)

A [virtual machine](https://en.wikipedia.org/wiki/Virtual_private_server) sold as a service by an Internet hosting service. A VPS runs its own copy of an operating system, and customers have superuser-level access to that operating system instance, so they can install almost any software that runs on that OS.

### VM Instance

In object-oriented programming, an [instance](http://stackoverflow.com/questions/20461907/what-is-meaning-of-instance-in-programming) is a specific realization of any [object](https://cloud.google.com/compute/docs/instances/). An object may be varied in a number of ways. Each realized variation of that object is an instance. Therefore, a VM instance is an instance of a virtual machine, which is an emulation of a computer system.

### Waterfall

A [model](http://www.umsl.edu/~hugheyd/is6840/waterfall.html) of building software that involves collecting all requirements from the customer, then building and refining all the requirements and finally delivering the complete software to the customer that meets all the requirements they specified.

### Webhooks

A way for for an app to [provide](https://docs.gitlab.com/ce/user/project/integrations/webhooks.html) other applications with real-time information (e.g., send a message to a slack channel when a commit is pushed.) Read about setting up [custom git hooks](https://gitlab.com/help/administration/custom_hooks.md) for when webhooks are insufficient.

### Wiki

A [website/system](http://www.wiki.com/) that allows for collaborative editing of its content by the users. In programming, wikis usually contain documentation of how to use the software.

### Working area

Files that have been modified but are not committed. Check them by using the command "git status". 

### Working Tree

[Consists of files](http://stackoverflow.com/questions/3689838/difference-between-head-working-tree-index-in-git) that you are currently working on.

### YAML

A human-readable data serialization [language](http://www.yaml.org/about.html) that takes concepts from programming languages such as C, Perl, and Python, and ideas from XML and the data format of electronic mail.

