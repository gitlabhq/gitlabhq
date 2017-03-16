# Writing Documentation

  - **General Documentation**: written by the developers responsible by creating features. Should be submitted in the same merge request containing code. Feature proposals (by GitLab contributors) should also be accompanied by its respective documentation. They can be later improved by PMs and Technical Writers.
  - **Documentation Articles**: written by any GitLab Team member, GitLab contributors, or Community Writers.
  - **Indexes per topic**: initially prepared by the Technical Writing Team, and kept up-to-date by developers and PMs, in the same merge request containing code.

## Distinction between General Documentation and Documentation Articles

Every **Documentation Article** contains, in the very beginning, a blockquote with the following information:

- A reference to the **type of article** (user guide, admin guide, tech overview, tutorial)
- A reference to the **knowledge level** expected from the reader to be able to follow through (beginner, intermediate, advanced)
- A reference to the **author's name** and **GitLab.com handle**

```md
> Type: tutorial
> Level: intermediary
> Author: [Name Surname](https://gitlab.com/username)
```

General documentation is categorized by _User_, _Admin_, and _Contributor_, and describe what that feature is, and how to use it or set it up.

## Documentation Articles - Writing Method

Use the [writing method](https://about.gitlab.com/handbook/marketing/developer-relations/technical-writing/#writing-method) defined by the Technical Writing team.

## Documentation Style Guidelines

All the documentation follow the same [styleguide](https://docs.gitlab.com/ce/development/doc_styleguide.html).

### Markdown

Currently GitLab docs use Redcarpet as markdown engine, but there's an open discussion for implementing Kramdown in the near future.
