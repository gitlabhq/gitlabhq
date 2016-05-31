# Wiki-Specific Markdown

## Table of Contents

* [Links to Other Wiki Pages](#links-to-other-wiki-pages)
  * [Direct Page Link](#direct-page-link)
  * [Direct File Link](#direct-file-link)
  * [Hierarchical Link](#hierarchical-link)
  * [Root Link](#root-link)

## Links to Other Wiki Pages

You can link to other pages on your wiki in a few different ways.

### Direct Page Link

A link which just includes the slug for a page will point to that page, _at the base level of the wiki_.

1. This snippet would link to a `documentation` page at the root of your wiki.

```markdown
[Link to Documentation](documentation)
```

### Direct File Link

Links with a file extension point to that file, _relative to the current page_.

1. If this snippet was placed on a page at `<your_wiki>/documentation/related`, it would link to `<your_wiki>/documentation/file.md`.

	```markdown
	[Link to File](file.md)
	```

### Hierarchical Link

A link can be constructed relative to the current wiki page using `./<page>`, `../<page>`, etc.

1. If this snippet was placed on a page at `<your_wiki>/documentation/main`, it would link to `<your_wiki>/documentation/related`.

	```markdown
	[Link to Related Page](./related)
	```

1. If this snippet was placed on a page at `<your_wiki>/documentation/related/content`, it would link to `<your_wiki>/documentation/main`.

	```markdown
	[Link to Related Page](../main)
	```

1. If this snippet was placed on a page at `<your_wiki>/documentation/main`, it would link to `<your_wiki>/documentation/related.md`.

	```markdown
	[Link to Related Page](./related.md)
	```

1. If this snippet was placed on a page at `<your_wiki>/documentation/related/content`, it would link to `<your_wiki>/documentation/main.md`.

	```markdown
	[Link to Related Page](../main.md)
	```

### Root Link

A link starting with a `/` is relative to the wiki root, for non-file links.

1. This snippet links to `<wiki_root>/documentation`

	```markdown
	[Link to Related Page](/documentation)
	```

1. This snippet links to `<wiki_root>/miscellaneous.md`

	```markdown
	[Link to Related Page](/miscellaneous.md)
	```
