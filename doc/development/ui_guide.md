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
This menu will be visible regardless of what page you visit.
The content section contains a header and the content itself. The header describes the current GitLab page and what navigation is
available to the user in this area. Depending on the area (project, group, profile setting) the header name and navigation may change. For example, when the user visits one of the
project pages the header will contain the project's name and navigation for that project. When the user visits a group page it will contain the group's name and navigation related to this group.

You can see a visual representation of the navigation in GitLab in the GitLab Product Map, which is located in the [Design Repository](gitlab-map-graffle)
along with [PDF](gitlab-map-pdf) and [PNG](gitlab-map-png) exports.


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

### SVGs

When exporting SVGs, be sure to follow the following guidelines:

1. Convert all strokes to outlines.
2. Use pathfinder tools to combine overlapping paths and create compound paths.
3. SVGs that are limited to one color should be exported without a fill color so the color can be set using CSS.
4. Ensure that exported SVGs have been run through an [SVG cleaner](https://github.com/RazrFalcon/SVGCleaner) to remove unused elements and attributes.

You can open your svg in a text editor to ensure that it is clean. 
Incorrect files will look like this:

```xml
<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<svg width="16px" height="17px" viewBox="0 0 16 17" version="1.1" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">
    <!-- Generator: Sketch 3.7.2 (28276) - http://www.bohemiancoding.com/sketch -->
    <title>Group</title>
    <desc>Created with Sketch.</desc>
    <defs></defs>
    <g id="Page-1" stroke="none" stroke-width="1" fill="none" fill-rule="evenodd">
        <g id="Group" fill="#7E7C7C">
            <path d="M15.1111,1 L0.8891,1 C0.3981,1 0.0001,1.446 0.0001,1.996 L0.0001,15.945 C0.0001,16.495 0.3981,16.941 0.8891,16.941 L15.1111,16.941 C15.6021,16.941 16.0001,16.495 16.0001,15.945 L16.0001,1.996 C16.0001,1.446 15.6021,1 15.1111,1 L15.1111,1 L15.1111,1 Z M14.0001,6.0002 L14.0001,14.949 L2.0001,14.949 L2.0001,6.0002 L14.0001,6.0002 Z M14.0001,4.0002 L14.0001,2.993 L2.0001,2.993 L2.0001,4.0002 L14.0001,4.0002 Z" id="Combined-Shape"></path>
            <polygon id="Fill-11" points="3 2.0002 5 2.0002 5 0.0002 3 0.0002"></polygon>
            <polygon id="Fill-16" points="11 2.0002 13 2.0002 13 0.0002 11 0.0002"></polygon>
            <path d="M5.37709616,11.5511984 L6.92309616,12.7821984 C7.35112915,13.123019 7.97359761,13.0565604 8.32002627,12.6330535 L10.7740263,9.63305349 C11.1237073,9.20557058 11.0606364,8.57555475 10.6331535,8.22587373 C10.2056706,7.87619272 9.57565475,7.93926361 9.22597373,8.36674651 L6.77197373,11.3667465 L8.16890384,11.2176016 L6.62290384,9.98660159 C6.19085236,9.6425813 5.56172188,9.71394467 5.21770159,10.1459962 C4.8736813,10.5780476 4.94504467,11.2071781 5.37709616,11.5511984 L5.37709616,11.5511984 Z" id="Stroke-21"></path>
        </g>
    </g>
</svg>
```

Correct file will look like this:

```xml
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 16 17" enable-background="new 0 0 16 17"><path d="m15.1 1h-2.1v-1h-2v1h-6v-1h-2v1h-2.1c-.5 0-.9.5-.9 1v14c0 .6.4 1 .9 1h14.2c.5 0 .9-.4.9-1v-14c0-.5-.4-1-.9-1m-1.1 14h-12v-9h12v9m0-11h-12v-1h12v1"/><path d="m5.4 11.6l1.5 1.2c.4.3 1.1.3 1.4-.1l2.5-3c.3-.4.3-1.1-.1-1.4-.5-.4-1.1-.3-1.5.1l-1.8 2.2-.8-.6c-.4-.3-1.1-.3-1.4.2-.3.4-.3 1 .2 1.4"/></svg>
```


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
[gitlab-map-graffle]: https://gitlab.com/gitlab-org/gitlab-design/blob/master/production/resources/gitlab-map.graffle
[gitlab-map-pdf]: https://gitlab.com/gitlab-org/gitlab-design/raw/master/production/resources/gitlab-map.pdf
[gitlab-map-png]: https://gitlab.com/gitlab-org/gitlab-design/raw/master/production/resources/gitlab-map.png