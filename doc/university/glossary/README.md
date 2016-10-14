
## What is the Glossary

This contains a simplified list and definitions of some of the terms that you will encounter in your day to day activities when working with GitLab.
Please add any terms that you discover that you think would be useful for others.

### 2FA

User authentication by combination of 2 different steps during login. This allows for more security.

### Access Levels

Process of selective restriction to create, view, modify or delete a resource based on a set of assigned permissions.
See, [GitLab's Permission Guidelines](http://doc.gitlab.com/ce/permissions/permissions.html)

### Active Directory (AD)

A Microsoft based directory service for windows domain networks. It uses LDAP technology under the hood

### Agile

Building and delivering software in phases/parts rather than trying to build everything at once then delivering to the user/client. The later is known as a WaterFall model

### Application Lifecycle Management (ALM)

Entire product lifecycle management process for an application. From requirements management, development and testing until deployment.

### Artifactory

Version control for binaries.

### Artifacts

objects (usually binary and large) created by a build process

### Atlassian

A company that develops software products for developers and project managers including Bitbucket, Jira, Hipchat, Confluence, Bamboo. See [Atlassian] (https://www.atlassian.com)

### Audit Log

*** Needs definition here

### Auto Defined User Group

User groups are a way of centralizing control over important management tasks, particularly access control and password policies.
A simple example of such groups are the users and the admins groups.
In most of the cases these groups are auto defined in terms of access, rules of usage, conditions to be part of, etc...

### Bamboo

Atlassian's CI tool similar to GitLab CI and Jenkins

### Basic Subscription

Entry level subscription for GitLab EE currently available in packs of 10 see [Basic subscription](https://about.gitlab.com/pricing/)

### Bitbucket

Atlassian's web hosting service for Git and Mercurial Projects i.e. GitLab.com competitor

### Branch

A branch is a parallel version of a repository. Allows you to work on the repository without you affecting the "master" branch. Allows you to make changes without affecting the current "live" version. When you have made all your changes to your branch you can then merge to the master and to make the changes fo "live".

### Branded Login

Having your own logo on your GitLab instance login page instead of the GitLab logo.

### CEPH

is a distributed object store and file system designed to provide excellent performance, reliability and scalability.

### Clone

A copy of a repository stored on your machine that allows you to use your own editor without being online, but still tracks the changes made remotely.

### Code Review

Examination of a progam's code. The main aim is to maintain high standards quality of code that is being shipped.

### Code Snippet

A small amount of code. Usually for the purpose of showing other developers how
to do something specific or reproduce a problem.

### Collaborator

Person with read and write access to a repository who has been invited by repository owner.

### Commit

Is a change (revision) to a file, and also creates an ID that allows you to see revision history and who made the changes.

### Community

Everyone who is using GitLab

### Confluence

Atlassian's product for collaboration of documents and projects.

### Continuous Deivery

Continuous delivery is a series of practices designed to ensure that code can be rapidly and safely deployed to production by delivering every change to a production-like environment and ensuring business applications and services function as expected through rigorous automated testing.

### Continuous Deployment

Continuous deployment is the next step of continuous delivery: Every change that passes the automated tests is deployed to production automatically.

### Continuous Integration

A process that involves adding new code commits to source code with the combined code being run on an automated test to ensure that the changes do not break the software.

### Contributor

Term used to a person contributing to an Open Source Project.

### Data Centre

Atlassian product for High Availability.

### Deploy Keys

An SSH key stored on the your server that grants access to a single GitLab repository. This is used by a GitLab runner to clone a project's code so that tests can be run against the checked out code.

### Developer

For us (GitLab) this means a software developer, i.e. someone who makes software. It is also one of the levels of access in our multi level approval system.

### Diff

Is the difference between two commits, or saved changes. This will also be shown visually after the changes.

### Docker

Containers wrap up a piece of software in a complete filesystem that contains everything it needs to run: code, runtime, system tools, system libraries – anything you can install on a server.
This guarantees that it will always run the same, regardless of the environment it is running in.

### Fork

Your own copy of a repository that allows you to make changes to the repository without affecting the original.

### Gerrit

A code review tool built on top of Git.

### Git Hooks

Are scripts you can use to trigger actions at certain points.

### GitHost.io

Is a single-tenant solution that provides GitLab CE or EE as a managed service. GitLab Inc. is responsible for
installing, updating, hosting, and backing up customers own private and secure GitLab instance.

### GitHub

A web-based Git repository hosting service with an enterprise offering. Its main features are: issue tracking, pull request with code review, abundancy of integrations and wiki. As of April 2016, the service has over 14 million users. It offers free public repos, private repos and enterprise services are paid.

### GitLab CE

Our free on Premise solution with >100,000 users

### GitLab CI

Our own Continuos Integration feature that is shipped with each instance

### GitLab EE

Our premium on premise solution that currently has Basic, Standard and Plus subscription packages with additional features and support.

### GitLab.com

Our free SaaS for public and private repositories.

### Gitolite

Is basically an access layer that sits on top of Git. Users are granted access to repos via a simple config file and you as an admin only needs the users public SSH key and a username from the user.

### Gitorious

A web based hosting service for projects using Git. It was acquired by GitLab and we discontinued the service. [Gitorious Acquisition Blog Post](https://about.gitlab.com/2015/03/03/gitlab-acquires-gitorious/)

### HADR

Sometimes written HA/DR.  High Availability for Disaster Recovery.  Usually refers to a strategy having a failover server in place in case the main server fails.

### Hip Chat

Atlassian's real time chat application for teams. Competitor to Slack, RocketChat and MatterMost.

### High Availability

Refers to a system or component that is continuously operational for a desirably long length of time. Availability can be measured relative to "100% operational" or "never failing."

### Issue Tracker

A tool used to manage, organize, and maintain a list of issues, making it easier for an organization to manage.

### Jenkins

An Open Source CI tool written using the Java programming language. Does the same job as GitLab CI, Bamboo, Travis CI. It is extremely popular. see [Jenkins](https://jenkins-ci.org/)

### Jira

Atlassian's project management software. i.e. a complex issue tracker. See[Jira](https://www.atlassian.com/software/jira)

### Kerberos

A network authentication protocol that uses secret-key cryptography for security.

### Kubernetes

An open source container cluster manager originally designed by Google. It's basically a platform for automating deployment, scaling, and operations of application containers over clusters of hosts.

### Labels

An identifier to describe a group of one or more specific file revisions

### LDAP

Lightweight Directory Access Protocol - basically its a directory (electronic address book) with user information e.g. name, phone_number etc

### LDAP User Authentication

Allowing GitLab to sign in people from an LDAP server i.e. Allow people whose names are on the electronic user directory server) to be able to use their LDAP accounts to login.

### LDAP Group Sync

Allows you to synchronize the members of a GitLab group with one or more LDAP groups.

### Git LFS

Git Large File Storage. A way to enable git to handle large binary files by using reference pointers within small text files to point to the large files.

### Linux

An operating system like Windows or OS X. It is mostly used by software developers and on servers.

### Markdown

Is a lightweight markup language with plain text formatting syntax designed so that it can be converted to HTML and many other formats using a tool by the same name.
Markdown is often used to format readme files, for writing messages in online discussion forums, and to create rich text using a plain text editor.

### Maria DB

A community developed fork/variation of MySQL. MySQL is owned by Oracle.

### Master

Name of the default branch in every git repository.

### Mercurial

A free distributed version control system like Git. Think of it as a competitor to Git.

### Merge

Takes changes from one branch, and applies them into another branch.

### Meteor

A hip platform for building javascript apps.[Meteor] (https://www.meteor.com)

### Milestones

Allows you to track the progress on issues, and merge requests, which allows you to get a snapshot of the progress made.

### Mirror Repositories

You can set up a project to automatically have its branches, tags, and commits updated from an upstream repository. This is useful when a repository you're interested in is located on a different server, and you want to be able to browse its content and its activity using the familiar GitLab interface.

### MIT License

A type of software license. It lets people do anything with your code with proper attribution and without warranty. It is the most common license for open source applications written in Ruby on Rails. GitLab CE is issued under this license.
This means, you can download the code, modify it as you want even build a new commercial product using the underlying code and its not illegal. The only condition is that there is no form of waranty provided by GitLab so whatever happens if you use the code is your own problem.

### Mondo

*** Needs definition here

### Multi LDAP Server

*** Needs definition here

### My SQL

A relational database. Currently only supported if you are using EE. It is owned by Oracle.

### Namespace

In computing, a namespace is a set of symbols that are used to organize objects of various kinds, so that these objects may be referred to by name.

Prominent examples include:
- file systems are namespaces that assign names to files;
- programming languages organize their variables and subroutines in namespaces;
- computer networks and distributed systems assign names to resources, such as computers, printers, websites, (remote) files, etc.

### Nginx

(pronounced "engine x") is a web server. It can act as a reverse proxy server for HTTP, HTTPS, SMTP, POP3, and IMAP protocols, as well as a load balancer and an HTTP cache.

### oAuth

Is an open standard for authorization, commonly used as a way for Internet users to log into third party websites using their Microsoft, Google, Facebook or Twitter accounts without exposing their password.

### Omnibus Packages

Omnibus is a way to package the different services and tools required to run GitLab, so that users can install it without as much work.

### On Premise

On your own server. In GitLab, this refers to the ability to download GitLab EE/GitLab CE and host it on your own server rather than using GitLab.com which is hosted by GitLab Inc's servers.

### Open Source Software

Software for which the original source code is freely available and may be redistributed and modified.

### Owner

This is the most powerful person on a GitLab project. He has the permissions of all the other users plus the additional permission of being able to destroy i.e. delete the project

### PaaS

Typically referred to in regards to application development, it is a model in which a cloud provider delivers hardware and software tools to its users as a service

### Perforce

The company that produces Helix.  A commercial, proprietary, centralised VCS well known for it's ability to version files of any size and type.  They OEM a re-branded version of GitLab called "GitSwarm" that is tightly integrated with their "GitFusion" product, which in turn represents a portion of a Helix repository (called a depot) as a git repo

### Phabricator

Is a suite of web-based software development collaboration tools, including the Differential code review tool, the Diffusion repository browser, the Herald change monitoring tool, the Maniphest bug tracker and the Phriction wiki. Phabricator integrates with Git, Mercurial, and Subversion.

### Piwik Analytics

An open source analytics software to help you analyze web traffic. It is similar to google analytics only that google analytics is not open source and information is stored by google while in Piwik the information is stored in your own server hence fully private.

### Plus Subscription

GitLab Premium EE subscription that includes training and dedicated Account Management and Service Engineer and complete support package [Plus subscription](https://about.gitlab.com/pricing/)

### PostgreSQL

A relational database. Touted as the most advanced open source database.

### Protected Branches

A feature that protects branches from unauthorized pushes, force pushing or deletion.

### Pull

Git command to synchronize the local repository with the remote repository, by fetching all remote changes and merging them into the local repository.

### Puppet

A popular devops automation tool

### Push

Git command to send commits from the local repository to the remote repository.

### RE Read Only

Permissions to see a file and it's contents, but not change it

### Rebase

Moves a branch from one commit to another.  This allows you to re-write your project's history.

### Git Repository

Storage location of all files which are tracked by git.

### Requirements management

*** Needs definition here

### Revision

*** Needs definition here

### Revision Control

Also known as version control or source control, is the management of changes to documents, computer programs, large web sites, and other collections of information. Changes are usually identified by a number or letter code, termed the "revision number", "revision level", or simply "revision".

### RocketChat

An open source chat application for teams. Very similar to Slack only that is is open-source.

### Runners

Actual build machines/containers that run/execute tests you have specified to be run on GitLab CI

### SaaS

Software as a service. Software is hosted centrally and accessed on-demand i.e. when you want to. This refers to GitLab.com in our scenario

### SCM

Software Configuration Management.  Often used by people when they mean Version Control

## Scrum

An Agile framework designed to help complete complex (typically) software projects. It's made up of several parts: product requirments backlog, sprint plannnig, sprint (development), sprint review, retrospec (analyzing the sprint). The goal is to end up with potentially shippable products.

### Scrum Board

The board used to track the status and progress of each of the sprint backlog items.

### Slack

Real time messaging app for teams. Used internally by  GitLab

### Slave Servers

Also known as secondary servers. They help to spread the load over multiple machines, they also provide backups when the master/primary server crashes.

### Source Code

Program code as typed by a computer programmer. i.e. it has not yet been compiled/translated by the computer to machine language.

### SSH Key

A unique identifier of a computer. It is used to identify computers without the need for a password. e.g. On GitLab I have added the ssh key of all my work machines so that the GitLab instance knows that it can accept code pushes and pulls from this trusted machines whose keys are I have added.

### SSO

Single Sign On. An authentication process that allows you enter one username and password to access multiple applications.

### Standard Subscription

Our mid range EE subscription that includes 24/7 support, support for High Availability [Standard Subscription](https://about.gitlab.com/pricing/)

### Stash

Atlassian's Git On-Premises solution. Think of it as Atlassian's GitLab EE. It is now known as BitBucket Server.

### Subversion

Non-proprietary, centralized version control system.

### Sudo

A program that allows you to perform superuser/administrator actions on Unix Operating Systems e.g. Linux, OS X. It actually stands for 'superuser do'

### SVN

Abbreviation for Subversion.

### Tag

Represents a version of a particular branch at a moment in time.

### Tool Stack

Set of tools used in a process to achieve a common outcome. E.g. set of tools used in Application Lifecycle Management.

### Trac

An Open Source project management and bug tracking web application.

### User

Anyone interacting with the software.

### VCS

Version Control Software

### Waterfall

A model of building software that involves collecting all requirements from the customer, then building and refining all the requirements and finally delivering the COMPLETE software to the customer that meets all the requirements specified by the customer

### Webhooks

A way for for an app to provide other applications with real-time information. e.g. send a message to a slack channel when a commit is pushed

### Wiki

A website/system that allows for collaborative editing of its content by the users. In programming, they usually contain documentation of how to use the software
