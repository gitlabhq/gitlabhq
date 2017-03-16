# Writing Documentation

  - **General Documentation**: written by the developers responsible by creating features. Should be submitted in the same merge request containing code. Feature proposals (by GitLab contributors) should also be accompanied by its respective documentation. They can be later improved by PMs and Technical Writers.
  - **Technical Articles**: written by any GitLab Team member, GitLab contributors, or Community Writers.
  - **Indexes per topic**: initially prepared by the Technical Writing Team, and kept up-to-date by developers and PMs, in the same merge request containing code.

## Distinction between General Documentation and Technical Articles

### General Documentation

General documentation is categorized by _User_, _Admin_, and _Contributor_, and describe what that feature is, what it does, and its available settings.

### Technical Articles

Technical articles replace technical content that once lived in the [GitLab Blog](https://about.gitlab.com/blog/), where they got out-of-date and weren't easily found.

They are topic-related documentation, written with an user-friendly approach and language, aim to provide the community with guidance on specific processes to achieve certain objectives.

A technical article guides users and/or admins to achieve certain objectives (within guides and tutorials), or provide an overview of that particular topic or feature (within technical overviews). It can also describe the use, implementation, or integration of third-party tools with GitLab.

They live under `doc/topics/topic-name/`, and can be searched per topic, within "Indexes per Topic" pages. The topics are listed on the main [Indexes per Topic](../topics/) page.

#### Types of Technical Articles

- **User guides**: technical content to guide regular users from point A to point B
- **Admin guides**: technical content to guide administrators of GitLab instances from point A to point B
- **Technical Overviews**: technical content describing features, solutions, and third-party integrations
- **Tutorials**: technical content provided step-by-step on how to do things, or how to reach very specific objectives

#### Understanding Guides and Tutorials

Suppose there's a process to go from point A to point B in 5 steps: (A) 1 > 2 > 3 > 4 > 5 (B).

A **guide** can be understood as a description of certain processes to achieve a particular objective. A guide brings you from A to B describing the characteristics of that process, but not necessarily going over each step. It can mention, for example, the step 3, but, assumes that that step is known by the reader, or out of the scope of that article.

A **tutorial** requires a clear **step-by-step** guidance to achieve a singular objective. It brings you from A to B, describing precisely all the necessary steps involved in that process, showing each of the 5 steps to go from A to B. It does not assume that you step 3: it shows you each of them.

#### Special Format

Every **Technical Article** contains, in the very beginning, a blockquote with the following information:

- A reference to the **type of article** (user guide, admin guide, tech overview, tutorial)
- A reference to the **knowledge level** expected from the reader to be able to follow through (beginner, intermediate, advanced)
- A reference to the **author's name** and **GitLab.com handle**

```md
> Type: tutorial
> Level: intermediary
> Author: [Name Surname](https://gitlab.com/username)
```

#### Technical Articles - Writing Method

Use the [writing method](https://about.gitlab.com/handbook/marketing/developer-relations/technical-writing/#writing-method) defined by the Technical Writing team.

## Documentation Style Guidelines

All the documentation follow the same [styleguide](https://docs.gitlab.com/ce/development/doc_styleguide.html).

### Markdown

Currently GitLab docs use Redcarpet as markdown engine, but there's an open discussion for implementing Kramdown in the near future.
