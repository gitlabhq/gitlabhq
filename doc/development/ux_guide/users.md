# UX Personas

* [Nazim Ramesh](#nazim-ramesh)
    - Small to medium size organizations using GitLab CE
* [Matthieu Poirier](#matthieu-poirier)
    - Responsible for managing and maintaining GitLab installation
    - Any size organization
    - Using CE or EE
* [James Mackey](#james-mackey)
    - Medium to large size organizations using CE or EE
    - Small organizations using EE
* [Karolina Plaskaty](#karolina-plaskaty)
    - Using GitLab.com for personal/hobby projects
    - Would like to use GitLab at work
    - Working within a medium to large size organization

---

## Nazim Ramesh
- Small to medium size organizations using GitLab CE

![nazim-ramesh](img/nazim-ramesh.png)

### Demographics

**Age**

32 years old

**Location**

Germany

**Education**

Bachelor of Science in Computer Science

**Occupation**

Full-stack web developer

**Programming experience**

Over 10 years

**Frequently used programming languages**

JavaScript, SQL, PHP

**Hobbies / interests**

Functional programming, open source, gaming, web development, and web security.

### Motivations
Nazim works for a software development company which currently hires around 80 people. When Nazim first joined the company, the engineering team were using Subversion (SVN) as their primary form of source control. However, Nazim felt SVN was not flexible enough to work with many feature branches and noticed that developers with less experience of source control struggled with the central-repository nature of SVN. Armed with a wish list of features, Nazim began comparing source control tools. A search for "self-hosted Git server repository management" returned GitLab. In his own words, Nazim explains why he wanted the engineering team to start using GitLab:

>"I wanted them to switch away from SVN. I needed a server application to manage repositories. The common tools that were around just didn't meet the requirements. Most of them were too simple or plain...GitLab provided all the required features. Also, costs had to be low since we don't have a big budget for those things...the Community Edition was perfect in this regard."

In his role as a full-stack web developer, Nazim could recommend products that he would like the engineering team to use, but final approval lay with his line manager, Mike, VP of Engineering. Nazim recalls that he was met with reluctance from his colleagues when he raised moving to Git and using GitLab.

>"The biggest challenge...why should we change anything at all from the status quo? We needed to switch from SVN to Git. They knew they needed to learn Git and a Git workflow...using Git was scary to my colleagues...they thought it was more complex than SVN to use."

Undeterred, Nazim decided to migrate a couple of projects across to GitLab.

>"Old SVN users couldn't see the benefits of Git at first. It took a month or two to convince them."

Slowly, by showing his colleagues how easy it was to use Git, the majority of the team's projects were migrated to GitLab.

The engineering team have been using GitLab CE for around 2 years now. Nazim credits himself as being entirely responsible for his company's decision to move to GitLab.

### Frustrations
#### Adoption to GitLab has been slow
Not only has the engineering team had to get to grips with Git, they've also had to adapt to using GitLab. Due to lack of training and existing skills in other tools, the full feature set of GitLab CE is not being utilized. Nazim sold GitLab to his manager as an ‘all in one' tool which would replace multiple tools used within the company, thus saving costs. Nazim hasn't had the time to integrate the legacy tools to GitLab and he's struggling to convince his peers to change their habits.

#### Missing Features
Nazim's company want GitLab to be able to do everything. There isn't a large budget for software, so they're selective about what tools are implemented. It needs to add real value to the company. In order for GitLab to be widely adopted and to meet the requirements of different roles within the company, it needs a host of features. When an individual within Nazim's company wants to know if GitLab has a specific feature or does a particular thing, Nazim is the person to ask. He becomes the point of contact to investigate, build or sometimes just raise the feature request. Nazim gets frustrated when GitLab isn't able to do what he or his colleagues need it to do.

#### Regressions and bugs
Nazim often has to calm down his colleagues, when a release contains regressions or new bugs. As he puts it "every new version adds something awesome, but breaks something". He feels that "old issues for minor annoyances get quickly buried in the mass of open issues and linger for a very long time. More generally, I have the feeling that GitLab focus on adding new functionalities, but overlook a bunch of annoying minor regressions or introduced bugs." Due to limited resource and expertise within the team, not only is it difficult to remain up-to-date with the frequent release cycle, it's also counterproductive to fix workflows every month.

#### Uses too much RAM and CPU
>"Memory usages mean that if we host it from a cloud-based host like AWS, we spend almost as much on the instance as what we would pay GitHub"


#### UI/UX
GitLab's interface initially attracted Nazim when he was comparing version control software. He thought it would help his less technical colleagues to adapt to using Git and perhaps, GitLab could be rolled out to other areas of the business, beyond engineering. However, using GitLab's interface daily has left him frustrated at the lack of personalization/control over his user experience. He's also regularly lost in a maze of navigation. Whilst he acknowledges that GitLab listens to its users and that the interface is improving, he becomes annoyed when the changes are too progressive. "Too frequent UI changes. Most of them tend to turn out great after a few cycles of fixes, but the frequency is still far too high for me to feel comfortable to always stay on the current release."

### Goals
* To convince his colleagues to fully adopt GitLab CE, thus improving workflow and collaboration.
* To use a feature-rich version control platform that covers all stages of the development lifecycle, in order to reduce dependencies on other tools.
* To use an intuitive and stable product, so he can spend more time on his core job responsibilities and less time bug-fixing, guiding colleagues, etc.

---
## Matthieu Poirier
- Responsible for managing and maintaining GitLab installation
- Any size organization
- Using CE or EE

![matthieu-poirier](img/matthieu-poirier.png)

### Demographics

**Age**
 
42 years old

**Location**

France

**Education**

Masters Degree in Computer Science

**Occupation**

DevOps Engineer

**Programming experience**

Over 10 years

**Frequently used programming languages**

JavaScript, SQL, PHP and Node.js

**Hobbies / interests**

Functional programming, data analysis, building apps, and tools.

### Motivations
Matthieu works in DevOps for a web services company which currently hires 90 staff. When Matthieu first joined the company, he was responsible for managing a custom built in-house bug tracking tool and release management system. Over time, as the company grew, his colleagues requested more features and tools to help them in their day-to-day work. To meet their needs, Matthieu was forced to "hack together" a solution. In his own words, Matthieu explains that it became:

>"...a huge pain managing access to all the individual pieces. In addition, they didn't have any integration with each other, nobody ended up using them and we couldn't do any workflows with merge requests and the like. I was sick of managing all those separate parts and wanted to move to a single platform that would handle it all."


He further explains that he wanted to introduce "better, easier, more formal code reviews" and to start using continuous integration and deployment.

Matthieu tried to find a platform which would consolidate the company's existing toolset, and centralize code, documentation, and issues. He discovered GitHub, but the price was an issue:

>"We needed to host our code on-site and wanted GitHub Enterprise functionality without the GitHub Enterprise costs."


Not only was GitLab cheaper than GitHub, it was also more cost-effective than maintaining multiple tools. Subsequently, Matthieu found it easy to sell the merits of GitLab to his manager.

Matthieu describes GitLab as:

>"the only tool that offers the real feeling of having everything you need in one place."


He credits himself as being entirely responsible for moving his company to GitLab. 

### Frustrations
#### Updating to the latest release
Matthieu introduced his company to GitLab. He is responsible for maintaining and managing the company's installation in addition to his day job. He feels updates are too frequent and he doesn't always have sufficient time to update GitLab. As a result, he's not up to date with releases. 

Matthieu tried to set up automatic updates, however, as he isn't a Systems Administrator, he wasn't confident in his set-up. He feels he should be able to "upgrade without users even noticing" but hasn't figured out how to do this yet. Matthieu would like the "update process to be triggered from the Admin Panel, perhaps accompanied with a changelog and the option to skip updates."

Matthieu is looking for confirmation that his update procedure is "secure and efficient" so more tutorials related to this topic would be useful to him.

#### Configuration
Matthieu dislikes using the combination of gitlab.rb and the UI for changing settings. He explains that it "would be nice to be able to configure more from the Admin UI rather than just the config files."

#### Creating a backup
Matthieu explains that the "backup solution is not well integrated into the UI", for example, he "cannot see if backups succeeded" or whether they have been rolled back to via the UI.

#### Onboarding
It's Matthieu's responsibility to get teams across his organization up and running with GitLab. He explains that whilst many teams might be leveraging GitLab, they are:

>"..not aware of GitLab's powerful CI or our omnibus install of Mattermost...It would be nice to have a tutorial type walkthrough available when a new user logs in on how to get started with all these features. AutoDevOps may solve some of this, but GitLab has many powerful features wrapped up into it and some [teams] may just think that it is only a Git repo similar to GitHub."


He states that there has been: "a sluggishness of others to adapt" and it's "a low-effort adaptation at that."

### Goals
* To save time. One of the reasons Matthieu moved his company to GitLab was to reduce the effort it took him to manage and configure multiple tools, thus saving him time. He has to balance his day job in addition to managing the company's GitLab installation and onboarding new teams to GitLab. 
* To use a platform which is easy to manage. Matthieu isn't a Systems Administrator, and when updating GitLab, creating backups, etc. He would prefer to work within GitLab's UI. Explanations / guided instructions when configuring settings in GitLab's interface would really help Matthieu. He needs reassurance that what he is about to change is 

1. the right setting
2. will provide him with the desired result he wants.

* Matthieu needs to educate his colleagues about GitLab. Matthieu's colleagues won't adopt GitLab as they're unaware of its capabilities and the positive impact it could have on their work. Matthieu needs support in getting this message across to them.

---

## James Mackey
- Medium to large size organizations using CE or EE
- Small organizations using EE

![james-mackey.png](img/james-mackey.png)

### Demographics

**Age**

36 years old

**Location**

US

**Education**

Masters degree in Computer Science

**Occupation**

Full-stack web developer

**Programming experience**

Over 10 years

**Frequently used programming languages**

JavaScript, SQL, Node.js, Java, PHP, Python

**Hobbies / interests**

DevOps, open source, web development, science, automation, and electronics.

### Motivations
James works for a research company which currently hires around 800 staff. He began using GitLab.com back in 2013 for his own open source, hobby projects and loved "the simplicity of installation, administration and use". After using GitLab for over a year, he began to wonder about using it at work. James explains:

>"We first installed the CE edition...on a staging server for a PoC and asked a beta team to use it, specifically for the Merge Request features. Soon other teams began asking us to be beta users too because the team that was already using GitLab was really enjoying it."


James and his colleagues also reviewed competitor products including GitHub Enterprise, but they found it "less innovative and with considerable costs...GitLab had the features we wanted at a much lower cost per head than GitHub".

The company James works for provides employees with a discretionary budget to spend how they want on software, so James and his team decided to upgrade to EE.

James feels partially responsible for his organization's decision to start using GitLab.

>"It's still up to the teams themselves [to decide] which tools to use. We just had a great experience moving our daily development to GitLab, so other teams have followed the path or are thinking about switching."


### Frustrations
#### Third Party Integration
Some of GitLab EE's features are too basic, in particular, issues boards which do not have the level of reporting that James and his team need. Subsequently, they still need to use GitLab EE in conjunction with other tools, such as JIRA. Whilst James feels it isn't essential for GitLab to meet all his needs (his company are happy for him to use, and pay for, multiple tools), he sometimes isn't sure what is/isn't possible with plugins and what level of custom development he and his team will need to do.

#### UX/UI
James and his team use CI quite heavily for several projects. Whilst they've welcomed improvements to the builds and pipelines interface, they still have some difficulty following build process on the different tabs under Pipelines. Some confusion has arisen from not knowing where to find different pieces of information or how to get to the next stages logs from the current stage's log output screen. They feel more intuitive linking and flow may alleviate the problem. Generally, they feel GitLab's navigation needs to reviewed and optimized.

#### Permissions
>"There is no granular control over user or group permissions. The permissions for a project are too tightly coupled to the permissions for Gitlab CI/build pipelines."


### Goals
* To be able to integrate third-party tools easily with GitLab EE and to create custom integrations and patches where needed.
* To use GitLab EE primarily for code hosting, merge requests, continuous integration and issue management. James and his team want to be able to understand and use these particular features easily.
* To able to share one instance of GitLab EE with multiple teams across the business. Advanced user management, the ability to separate permissions on different parts of the source code, etc are important to James.

---

## Karolina Plaskaty
- Using GitLab.com for personal/hobby projects
- Would like to use GitLab at work
- Working within a medium to large size organization

![karolina-plaskaty.png](img/karolina-plaskaty.png)

### Demographics

**Age**

26 years old

**Location**

UK

**Education**

Self taught

**Occupation**

Junior web-developer

**Programming experience**

6 years

**Frequently used programming languages**

JavaScript and SQL

**Hobbies / interests**

Web development, mobile development, UX, open source, gaming, and travel.

### Motivations
Karolina has been using GitLab.com for around a year. She roughly spends 8 hours every week programming, of that, 2 hours is spent contributing to open source projects. Karolina contributes to open source projects to gain programming experience and to give back to the community. She likes GitLab.com for its free private repositories and range of features which provide her with everything she needs for her personal projects. Karolina is also a massive fan of GitLab's values and the fact that it isn't a "behemoth of a company".  She explains that "displaying every single thing (doc, culture, assumptions, development...) in the open gives me greater confidence to choose Gitlab personally and to recommend it at work."  She's also an avid reader of GitLab's blog.

Karolina works for a software development company which currently hires around 500 people. Karolina would love to use GitLab at work but the company has used GitHub Enterprise for a number of years. She describes management at her company as "old fashioned" and explains that it's "less of a technical issue and more of a cultural issue" to convince upper management to move to GitLab. Karolina is also relatively new to the company so she's apprehensive about pushing too hard to change version control platforms.

### Frustrations
#### Unable to use GitLab at work
Karolina wants to use GitLab at work but isn't sure how to approach the subject with management. In her current role, she doesn't feel that she has the authority to request GitLab.

#### Performance
GitLab.com is frequently slow and unavailable. Karolina has also heard that GitLab is a "memory hog"  which has deterred her from running GitLab on her own machine for just hobby / personal projects.

#### UX/UI
Karolina has an interest in UX and therefore has strong opinions about how GitLab should look and feel. She feels the interface is cluttered, "it has too many links/buttons" and the navigation "feels a bit weird sometimes. I get lost if I don't pay attention." As Karolina also enjoys contributing to open-source projects, it's important to her that GitLab is well designed for public repositories, she doesn't feel that GitLab currently achieves this.

### Goals
* To develop her programming experience and to learn from other developers.
* To contribute to both her own and other open source projects.
* To use a fast and intuitive version control platform.