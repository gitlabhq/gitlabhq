# Wiki-specific Markdown

This page has information related to wiki-specific Markdown. For more
information on GitLab's Markdown, see the [main Markdown document](./markdown.md).

## Table of contents

* [Links to other wiki pages](#links-to-other-wiki-pages)
  * [Direct page link](#direct-page-link)
  * [Direct file link](#direct-file-link)
  * [Hierarchical link](#hierarchical-link)
  * [Root link](#root-link)

## Links to other wiki pages

You can link to other pages on your wiki in a few different ways.

### Direct page link

A link which just includes the slug for a page will point to that page,
_at the base level of the wiki_.

This snippet would link to a `documentation` page at the root of your wiki:

```markdown
[Link to Documentation](documentation)
```

### Direct file link

Links with a file extension point to that file, _relative to the current page_.

If this snippet was placed on a page at `<your_wiki>/documentation/related`,
it would link to `<your_wiki>/documentation/file.md`:

```markdown
[Link to File](file.md)
```

### Hierarchical link

A link can be constructed relative to the current wiki page using `./<page>`,
`../<page>`, etc.

- If this snippet was placed on a page at `<your_wiki>/documentation/main`,
  it would link to `<your_wiki>/documentation/related`:

	```markdown
	[Link to Related Page](./related)
	```

- If this snippet was placed on a page at `<your_wiki>/documentation/related/content`,
  it would link to `<your_wiki>/documentation/main`:

	```markdown
	[Link to Related Page](../main)
	```

- If this snippet was placed on a page at `<your_wiki>/documentation/main`,
  it would link to `<your_wiki>/documentation/related.md`:

	```markdown
	[Link to Related Page](./related.md)
	```

- If this snippet was placed on a page at `<your_wiki>/documentation/related/content`,
  it would link to `<your_wiki>/documentation/main.md`:

	```markdown
	[Link to Related Page](../main.md)
	```

### Root link

A link starting with a `/` is relative to the wiki root.

- This snippet links to `<wiki_root>/documentation`:

	```markdown
	[Link to Related Page](/documentation)
	```

- This snippet links to `<wiki_root>/miscellaneous.md`:

	```markdown
	[Link to Related Page](/miscellaneous.md)
	```
