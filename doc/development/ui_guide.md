# UI Guide for building GitLab

## GitLab UI development kit

We created a page inside GitLab where you can check commonly used html and css elements.

When you run GitLab instance locally - just visit http://localhost:3000/help/ui page to see UI examples
you can use during GitLab development.

## Design repository

All design files are stored in the [gitlab-design](https://gitlab.com/gitlab-org/gitlab-design)
repository and maintained by GitLab UX designers.

## Navigation

GitLab's layout contains 2 sections: the left sidebar and the content. The left sidebar contains a static navigation menu.
This menu will be visible regardless of what page you visit. The left sidebar also contains the GitLab logo
and the current user's profile picture. The content section contains a header and the content itself.
The header describes the current GitLab page and what navigation is
available to user in this area. Depending on the area (project, group, profile setting) the header name and navigation may change. For example when user visits one of the
project pages the header will contain a project name and navigation for that project. When the user visits a group page it will contain a group name and navigation related to this group.

### Adding new tab to header navigation

We try to keep the amount of tabs in the header navigation between 5 and 10 so that it fits on a typical laptop screen. We also try not to confuse the user with too many options. Ideally each
tab should represent separate functionality. Everything related to the issue
tracker should be under the 'Issues' tab while everything related to the wiki should
be under 'Wiki' tab and so on and so forth.
When adding a new tab to the header don't use more than 2 words for text in the link.
We want to keep links short and easy to remember and fit all of them in the small screen.

## Mobile screen size

We want GitLab to work well on small mobile screens as well. Size limitations make it is impossible to fit everything on a mobile screen. In this case it is OK to hide
part of the UI for smaller resolutions in favor of a better user experience.
However core functionality like browsing files, creating issues, writing comments, should
be available on all resolutions.

## Icons

* `trash` icon for button or link that does destructive action like removing
information from database or file system
* `x` icon for closing/hiding UI element. For example close modal window
* `pencil` icon for edit button or link
* `eye` icon for subscribe action
* `rss` for rss/atom feed
* `plus` for link or dropdown that lead to page where you create new object (For example new issue page)


## Buttons

* Button should contain icon or text. Exceptions should be approved by UX designer.
* Use red button for destructive actions (not revertable). For example removing issue.
* Use green or blue button for primary action. Primary button should be only one.
Do not use both green and blue button in one form.
* For all other cases use default white button.
* Text button should have only first word capitalized. So should be "Create issue" instead of "Create Issue"

## Counts

* Always use the [`number_with_delimiter`][number_with_delimiter] helper to
  display counts in the UI.

[number_with_delimiter]: http://api.rubyonrails.org/classes/ActionView/Helpers/NumberHelper.html#method-i-number_with_delimiter
