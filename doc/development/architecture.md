# GitLab project architecture

GitLab project consists of two parts: GitLab and GitLab shell.

## GitLab

Web application with background jobs workers. 
Provides you with UI and most of functionality.
For some operations like repo creation - uses GitLab shell.

Uses: 
 * Ruby as main language for application code and most libraries. 
 * [Rails](http://rubyonrails.org/) web framework as main framework for application.
 * Mysql or postgres as main databases. Used for persistent data storage(users, project, issues etc). 
 * Redis database. Used for cache and exchange data between some components.
 * Python2 because of [pygments](http://pygments.org/) as code syntax highlighter.

## GitLab shell

Command line ruby application. Used by GitLab through shell commands.
It provides interface to all kind of manipulations with repositories and ssh keys.
Full list of commands you can find in README of GitLab shell repo.
Works on pure ruby and do not require any additional software.
