# Snippets

Snippets are little bits of code or text.

![GitLab Snippet](img/gitlab_snippet.png)

There are 2 types of snippets - project snippets and personal snippets.

## Comments

With GitLab Snippets you engage in a conversation about that piece of code,
facilitating the collaboration among users.

> **Note:**
Comments on snippets was [introduced](https://gitlab.com/gitlab-org/gitlab-ce/issues/12910) in [GitLab Community Edition 9.2](https://about.gitlab.com/2017/05/22/gitlab-9-2-released/#comments-for-personal-snippets).

## Project snippets

Project snippets are always related to a specific project - see [Project's features](project/index.md#project-39-s-features) for more information.

## Personal snippets

Personal snippets are not related to any project and can be created completely independently. There are 3 visibility levels that can be set (public, internal, private - see [Public Access](../public_access/public_access.md) for more information).

## Downloading snippets

You can download the raw content of a snippet.

By default snippets will be downloaded with Linux-style line endings (`LF`). If you want to preserve the original line endings you need to add a parameter `line_ending=raw` (eg. `https://gitlab.com/snippets/SNIPPET_ID/raw?line_ending=raw`). In case a snippet was created using the GitLab web interface the original line ending is Windows-like (`CRLF`).

## Embedded Snippets

> Introduced in GitLab 10.8.

Public snippets can not only be shared, but also embedded on any website. This
allows to reuse a GitLab snippet in multiple places and any change to the source
is automatically reflected in the embedded snippet.

To embed a snippet, first make sure that:

- The project is public (if it's a project snippet)
- The snippet is public
- In **Project > Settings > Permissions**, the snippets permissions are
  set to **Everyone with access**

Once the above conditions are met, the "Embed" section will appear in your snippet
where you can simply click on the "Copy to clipboard" button. This copies a one-line
script that you can add to any website or blog post.

Here's how an example code looks like:

```html
<script src="https://gitlab.com/namespace/project/snippets/SNIPPET_ID.js"></script>
```

Here's how an embedded snippet looks like:

<script src="https://gitlab.com/gitlab-org/gitlab-ce/snippets/1717978.js"></script>

Embedded snippets are displayed with a header that shows the file name if defined,
the snippet size, a link to GitLab, and the actual snippet content. Actions in
the header allow users to see the snippet in raw format and download it.
