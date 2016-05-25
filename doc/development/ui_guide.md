# UI Guide for building GitLab 

## GitLab UI development kit

We created a page inside GitLab where you can check commonly used html and css elements.

When you run GitLab instance locally - just visit http://localhost:3000/help/ui page to see UI examples 
you can use during GitLab development.

## Design repository

All design files are stored in the [gitlab-design](https://gitlab.com/gitlab-org/gitlab-design) 
repository and maintained by GitLab UX designers. 

## Navigation

GitLab layout contains of 2 sections: left sidebar and content. Left sidebar 
contains static navigation menu no matter what page you visit. It also has GitLab logo 
and current user profile picture. Content section contains of header and content itself.  
Header describes what area of GitLab user see right now and what navigation is 
available to user in this area. Depends on area (project, group, profile setting) 
header name and navigation will change. For example when user visits one of the 
project pages the header will contain a project name and navigation for project 
pages. When visit group page it will contain a group name and navigation related 
to this group.

### Adding new tab to header navigation

We try to keep amount of tabs in header navigation between 5 and 10 so it fits on 
a laptop screens and doest not confure user with too many options. Ideally each 
tab should represent some separate functionality. So everything related to issue 
tracker should be under 'Issues' tab while everything related to wiki should 
be under 'Wiki' tab etc.

## Mobile screen size 

We want GitLab work on small mobile screens too. Because of size limitations 
its impossible to fit everything on phone screen. Its ok in this case to hide 
part of the UI on smaller resolutions in favor of better user experience. 
However core functionality like browsing file, creating issue, comment, etc should
be available on all resolutions.
