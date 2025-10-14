---
stage: Plan
group: Knowledge
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Wiki-specific Markdown
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

## Links

The following topics show how links inside wikis behave.

When you link to wiki pages, use the page slug rather than the page name.
A page slug is the URL-friendly version of the page title, where spaces are replaced with hyphens
and special characters are removed or converted.
For example, a page titled "How to Use GitLab" has the slug `How-to-Use-GitLab`.

### Wiki-style links

In addition to standard [Markdown links](../../markdown.md#links), wikis support special wiki-style
link syntax that provides a more convenient way to link between wiki pages.

#### Double bracket syntax

You can link to wiki pages using double brackets:

```markdown
[[Home]]
```

This syntax creates a link to a wiki page with the slug `Home`.
If the page doesn't exist, when you select the link, you can create this page.

When the page slug contains hyphens, the link displays the slug as-is:

```markdown
[[Home-page-new-slug]]
```

This displays `Home-page-new-slug` as the link text.

#### Double bracket syntax with custom text

If the page slug is different from the title you want to display, use the pipe (`|`) character to
separate the display text from the page slug:

```markdown
[[How to use GitLab|how-to-use-gitlab]]
```

This displays "How to use GitLab" as the link text, but links to the page with the slug `how-to-use-gitlab`.

You can also use this syntax to provide a more readable title for pages with hyphenated slugs:

```markdown
[[Home page (renamed)|Home-page-new-slug]]
```

This displays "Home page (renamed)" as the link text, but links to the page with the slug `Home-page-new-slug`.

#### Alternative wiki page syntax

You can also use the `[wiki_page:PAGE_SLUG]` syntax:

```markdown
[wiki_page:Home]
```

For cross-project references, specify the full project path:

```markdown
[wiki_page:namespace/project:Home]
[wiki_page:group1/subgroup:Home]
```

#### Automatic URL recognition

When you paste a full URL to a wiki page without any Markdown formatting, GitLab automatically converts it to a link and displays the page slug with spaces instead of hyphens:

```markdown
https://gitlab.com/namespace/project/-/wikis/Home-page-new-slug
```

This automatically renders as a link with the text "Home page new slug" (hyphens converted to spaces).

### Direct page link

A direct page link includes the slug for a page that points to that page,
at the base level of the wiki.

This example links to a `documentation` page at the root of your wiki:

```markdown
[Link to Documentation](documentation-top-page)
```

### Direct file link

A direct file link points to a file extension for a file, relative to the current page.

If the following example is on a page at `<your_wiki>/documentation/related`,
it links to `<your_wiki>/documentation/file.md`:

```markdown
[Link to File](file.md)
```

### Hierarchical link

A hierarchical link can be constructed relative to the current wiki page by using relative paths like `./<page>` or
`../<page>`.

If this example is on a page at `<your_wiki>/documentation/main`,
it links to `<your_wiki>/documentation/related`:

```markdown
[Link to Related Page](related)
```

If this example is on a page at `<your_wiki>/documentation/related/content`,
it links to `<your_wiki>/documentation/main`:

```markdown
[Link to Related Page](../main)
```

If this example is on a page at `<your_wiki>/documentation/main`,
it links to `<your_wiki>/documentation/related.md`:

```markdown
[Link to Related Page](related.md)
```

If this example is on a page at `<your_wiki>/documentation/related/content`,
it links to `<your_wiki>/documentation/main.md`:

```markdown
[Link to Related Page](../main.md)
```

### Root link

A root link starts with a `/` and is relative to the wiki root.

This example links to `<wiki_root>/documentation`:

```markdown
[Link to Related Page](/documentation)
```

This example links to `<wiki_root>/documentation.md`:

```markdown
[Link to Related Page](/documentation.md)
```

## diagrams.net editor

In wikis, you can use the [diagrams.net](https://app.diagrams.net/) editor to create diagrams. You
can also edit diagrams created with the diagrams.net editor. The diagram editor is available in both
the plain text editor and the rich text editor.

For more information, see [Diagrams.net](../../../administration/integration/diagrams_net.md).

### Plain text editor

To create a diagram in the plain text editor:

1. On the wiki page you want to edit, select **Edit**.
1. In the text box, make sure you're using the plain text editor
   (the button on the bottom left says **Switch to rich text editing**).
1. In the editor's toolbar, select **Insert or edit diagram** ({{< icon name="diagram" >}}).
1. Create the diagram in the [app.diagrams.net](https://app.diagrams.net/) editor.
1. Select **Save & exit**.

A Markdown image reference to the diagram is inserted in the wiki content.

To edit a diagram in the plain text editor:

1. On the wiki page you want to edit, select **Edit**.
1. In the text box, make sure you're using the plain text editor
   (the button on the bottom left says **Switch to rich text editing**).
1. Position your cursor in the Markdown image reference that contains the diagram.
1. Select **Insert or edit diagram** ({{< icon name="diagram" >}}).
1. Edit the diagram in the [app.diagrams.net](https://app.diagrams.net/) editor.
1. Select **Save & exit**.

A Markdown image reference to the diagram is inserted in the wiki content,
replacing the previous diagram.

### Rich text editor

To create a diagram in the rich text editor:

1. On the wiki page you want to edit, select **Edit**.
1. In the text box, make sure you're using the rich text editor
   (the button on the bottom left says **Switch to plain text editing**).
1. In the editor's toolbar, select **More options** ({{< icon name="plus" >}}).
1. In the dropdown list, select **Create or edit diagram**.
1. Create the diagram in the [app.diagrams.net](https://app.diagrams.net/) editor.
1. Select **Save & exit**.

The diagram as visualized in the diagrams.net editor is inserted in the wiki content.

To edit a diagram in the rich text editor:

1. On the wiki page you want to edit, select **Edit**.
1. In the text box, make sure you're using the rich text editor
   (the button on the bottom left says **Switch to plain text editing**).
1. Select the diagram that you want to edit.
1. In the floating toolbar, select **Edit diagram** ({{< icon name="diagram" >}}).
1. Edit the diagram in the [app.diagrams.net](https://app.diagrams.net/) editor.
1. Select **Save & exit**.

The selected diagram is replaced with an updated version.
