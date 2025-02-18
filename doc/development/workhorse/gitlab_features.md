---
stage: Create
group: Source Code
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: Features that rely on Workhorse
---

Workhorse itself is not a feature, but there are several features in
GitLab that would not work efficiently without Workhorse.

To put the efficiency benefit in context, consider that in 2020Q3 on
GitLab.com [we see](https://dashboards.gitlab.net/explore?schemaVersion=1&panes=%7B%22m95%22:%7B%22datasource%22:%22e58c2f51-20f8-4f4b-ad48-2968782ca7d6%22,%22queries%22:%5B%7B%22refId%22:%22A%22,%22expr%22:%22sum%28ruby_process_resident_memory_bytes%7Bapp%3D%5C%22webservice%5C%22,env%3D%5C%22gprd%5C%22,release%3D%5C%22gitlab%5C%22%7D%29%20%2F%20sum%28puma_max_threads%7Bapp%3D%5C%22webservice%5C%22,env%3D%5C%22gprd%5C%22,release%3D%5C%22gitlab%5C%22%7D%29%22,%22range%22:true,%22instant%22:true,%22datasource%22:%7B%22type%22:%22prometheus%22,%22uid%22:%22e58c2f51-20f8-4f4b-ad48-2968782ca7d6%22%7D,%22editorMode%22:%22code%22,%22legendFormat%22:%22__auto%22%7D,%7B%22refId%22:%22B%22,%22expr%22:%22sum%28go_memstats_sys_bytes%7Bapp%3D%5C%22webservice%5C%22,env%3D%5C%22gprd%5C%22,release%3D%5C%22gitlab%5C%22%7D%29%2Fsum%28go_goroutines%7Bapp%3D%5C%22webservice%5C%22,env%3D%5C%22gprd%5C%22,release%3D%5C%22gitlab%5C%22%7D%29%22,%22range%22:true,%22instant%22:true,%22datasource%22:%7B%22type%22:%22prometheus%22,%22uid%22:%22e58c2f51-20f8-4f4b-ad48-2968782ca7d6%22%7D,%22editorMode%22:%22code%22,%22legendFormat%22:%22__auto%22%7D%5D,%22range%22:%7B%22from%22:%22now-1h%22,%22to%22:%22now%22%7D%7D%7D&orgId=1)
Rails application threads using on average
about 200 MB of RSS vs about 200 KB for Workhorse goroutines.

Examples of features that rely on Workhorse:

## 1. `git clone` and `git push` over HTTP

Git clone, pull and push are slow because they transfer large amounts
of data and because each is CPU intensive on the GitLab side. Without
Workhorse, HTTP access to Git repositories would compete with regular
web access to the application, requiring us to run way more Rails
application servers.

## 2. CI runner long polling

GitLab CI runners fetch new CI jobs by polling the GitLab server.
Workhorse acts as a kind of "waiting room" where CI runners can sit
and wait for new CI jobs. Because of Go's efficiency we can fit a lot
of runners in the waiting room at little cost. Without this waiting
room mechanism we would have to add a lot more Rails server capacity.
See [the long polling documentation](../../ci/runners/long_polling.md)
for more details.

## 3. File uploads and downloads

File uploads and downloads may be slow either because the file is
large or because the user's connection is slow. Workhorse can handle
the slow part for Rails. This improves the efficiency of features such
as CI artifacts, package repositories, LFS objects, etc.

## 4. Websocket proxying

Features such as the web terminal require a long lived connection
between the user's web browser and a container inside GitLab that is
not directly accessible from the internet. Dedicating a Rails
application thread to proxying such a connection would cost much more
memory than it costs to have Workhorse look after it.

## 5. Web IDE

For security, some parts of the Web IDE must run in a separate origin.
To support this approach, the Web IDE relies on Workhorse to appropriately
route and decorate certain requests to and from Web IDE assets.
Because the Web IDE assets are static frontend assets, it's unnecessary
overhead to rely on Rails for this effort.

## Quick facts (how does Workhorse work)

- Workhorse can handle some requests without involving Rails at all:
  for example, JavaScript files and CSS files are served straight
  from disk.
- Workhorse can modify responses sent by Rails: for example if you use
  `send_file` in Rails then GitLab Workhorse opens the file on
  disk and send its contents as the response body to the client.
- Workhorse can take over requests after asking permission from Rails.
  Example: handling `git clone`.
- Workhorse can modify requests before passing them to Rails. Example:
  when handling a Git LFS upload Workhorse first asks permission from
  Rails, then it stores the request body in a temporary file, then it sends
  a modified request containing the file path to Rails.
- Workhorse can manage long-lived WebSocket connections for Rails.
  Example: handling the terminal websocket for environments.
- Workhorse does not connect to PostgreSQL, only to Rails and (optionally) Redis.
- We assume that all requests that reach Workhorse pass through an
  upstream proxy such as NGINX or Apache first.
- Workhorse does not clean up idle client connections.
- We assume that all requests to Rails pass through Workhorse.

For more information see ['A brief history of GitLab Workhorse'](https://about.gitlab.com/blog/2016/04/12/a-brief-history-of-gitlab-workhorse/).
