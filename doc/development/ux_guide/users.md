# UX Personas

* [Nazim Ramesh](#nazim-ramesh)
    - Small to medium size organisations using GitLab CE
* [James Mackey](#james-mackey)
    - Medium to large size organisations using CE or EE
    - Small organisations using EE
* [Karolina Plaskaty](#karolina-plaskaty)
    - Using GitLab.com for personal/hobby projects
    - Would like to use GitLab at work
    - Working for a medium to large size organisation

---

## Nazim Ramesh
- Small to medium size organisations using GitLab CE

<img src="img/nazim-ramesh.png" width="300px">

### Demographics

- **Age**<br>32 years old
- **Location**<br>Germany
- **Education**<br>Bachelor of Science in Computer Science
- **Occupation**<br>Full-stack web developer
- **Programming experience**<br>Over 10 years
- **Frequently used programming languages**<br>JavaScript, SQL, PHP
- **Hobbies / interests**<br>Functional programming, open source, gaming, web development and web security.

### Motivations
Nazim works for a software development company which currently hires around 80 people. When Nazim first joined the company, the engineering team were using Subversion (SVN) as their primary form of source control. However, Nazim felt SVN was not flexible enough to work with many feature branches and noticed that developers with less experience of source control struggled with the central-repository nature of SVN. Armed with a wishlist of features, Nazim began comparing source control tools. A search for “self-hosted Git server repository management” returned GitLab. In his own words, Nazim explains why he wanted the engineering team to start using GitLab:

>
“I wanted them to switch away from SVN. I needed a server application to manage repositories. The common tools that were around just didn’t meet the requirements. Most of them were too simple or plain...GitLab provided all the required features. Also costs had to be low, since we don’t have a big budget for those things...the Community Edition was perfect in this regard.”
>

In his role as a full-stack web developer, Nazim could recommend products that he would like the engineering team to use, but final approval lay with his line manager, Mike, VP of Engineering. Nazim recalls that he was met with reluctance from his colleagues when he raised moving to Git and using GitLab.

>
“The biggest challenge...why should we change anything at all from the status quo? We needed to switch from SVN to Git. They knew they needed to learn Git and a Git workflow...using Git was scary to my colleagues...they thought it was more complex than SVN to use.”
>

Undeterred, Nazim decided to migrate a couple of projects across to GitLab.

>
“Old SVN users couldn’t see the benefits of Git at first. It took a month or two to convince them.”
>

Slowly, by showing his colleagues how easy it was to use Git, the majority of the team’s projects were migrated to GitLab.

The engineering team have been using GitLab CE for around 2 years now. Nazim credits himself as being entirely responsible for his company’s decision to move to GitLab.

### Frustrations
#### Adoption to GitLab has been slow
Not only has the engineering team had to get to grips with Git, they’ve also had to adapt to using GitLab. Due to lack of training and existing skills in other tools, the full feature set of GitLab CE is not being utilised. Nazim sold GitLab to his manager as an ‘all in one’ tool which would replace multiple tools used within the company, thus saving costs. Nazim hasn’t had the time to integrate the legacy tools to GitLab and he’s struggling to convince his peers to change their habits.

#### Missing Features
Nazim’s company want GitLab to be able to do everything. There isn’t a large budget for software, so they’re selective about what tools are implemented. It needs to add real value to the company. In order for GitLab to be widely adopted and to meet the requirements of different roles within the company, it needs a host of features. When an individual within Nazim’s company wants to know if GitLab has a specific feature or does a particular thing, Nazim is the person to ask. He becomes the point of contact to investigate, build or sometimes just raise the feature request. Nazim gets frustrated when GitLab isn’t able to do what he or his colleagues need it to do.

#### Regressions and bugs
Nazim often has to calm down his colleagues, when a release contains regressions or new bugs. As he puts it “every new version adds something awesome, but breaks something”. He feels that “old issues for "minor" annoyances get quickly buried in the mass of open issues and linger for a very long time. More generally, I have the feeling that GitLab focus on adding new functionalities, but overlook a bunch of annoying minor regressions or introduced bugs.” Due to limited resource and expertise within the team, not only is it difficult to remain up-to-date with the frequent release cycle, it’s also counterproductive to fix workflows every month.

#### Uses too much RAM and CPU
>
“Memory usages mean that if we host it from a cloud based host like AWS, we spend almost as much on the instance as what we would pay GitHub”
>

#### UI/UX
GitLab’s interface initially attracted Nazim when he was comparing version control software. He thought it would help his less technical colleagues to adapt to using Git and perhaps, GitLab could be rolled out to other areas of the business, beyond engineering. However, using GitLab’s interface daily has left him frustrated at the lack of personalisation / control over his user experience. He’s also regularly lost in a maze of navigation. Whilst he acknowledges that GitLab listens to its users and that the interface is improving, he becomes annoyed when the changes are too progressive. “Too frequent UI changes. Most of them tend to turn out great after a few cycles of fixes, but the frequency is still far too high for me to feel comfortable to always stay on the current release.”

### Goals
* To convince his colleagues to fully adopt GitLab CE, thus improving workflow and collaboration.
* To use a feature rich version control platform that covers all stages of the development lifecycle, in order to reduce dependencies on other tools.
* To use an intuitive and stable product, so he can spend more time on his core job responsibilities and less time bug-fixing, guiding colleagues, etc.

---

## James Mackey
- Medium to large size organisations using CE or EE
- Small organisations using EE

<img src="img/james-mackey.png" width="300px">

### Demographics

- **Age**<br>36 years old
- **Location**<br>US
- **Education**<br>Masters degree in Computer Science
- **Occupation**<br>Full-stack web developer
- **Programming experience**<br>Over 10 years
- **Frequently used programming languages**<br>JavaScript, SQL, Node.js, Java, PHP, Python
- **Hobbies / interests**<br>DevOps, open source, web development, science, automation and electronics.

### Motivations
James works for a research company which currently hires around 800 staff. He began using GitLab.com back in 2013 for his own open source, hobby projects and loved “the simplicity of installation, administration and use”. After using GitLab for over a year, he began to wonder about using it at work. James explains:

>
“We first installed the CE edition...on a staging server for a PoC and asked a beta team to use it, specifically for the Merge Request features. Soon other teams began asking us to be beta users too, because the team that was already using GitLab was really enjoying it.”
>

James and his colleagues also reviewed competitor products including GitHub Enterprise, but they found it “less innovative and with considerable costs...GitLab had the features we wanted at a much lower cost per head than GitHub”.

The company James works for provides employees with a discretionary budget to spend how they want on software, so James and his team decided to upgrade to EE.

James feels partially responsible for his organisation’s decision to start using GitLab.

>
“It's still up to the teams themselves [to decide] which tools to use. We just had a great experience moving our daily development to GitLab, so other teams have followed the path or are thinking about switching.”
>

### Frustrations
#### Third Party Integration
Some of GitLab EE’s features are too basic, in particular, issues boards which do not have the level of reporting that James and his team need. Subsequently, they still need to use GitLab EE in conjunction with other tools, such as JIRA. Whilst James feels it isn’t essential for GitLab to meet all his needs (his company are happy for him to use, and pay for, multiple tools), he sometimes isn’t sure what is/isn’t possible with plugins and what level of custom development he and his team will need to do.

#### UX/UI
James and his team use CI quite heavily for several projects. Whilst they’ve welcomed improvements to the builds and pipelines interface, they still have some difficulty following build process on the different tabs under Pipelines. Some confusion has arisen from not knowing where to find different pieces of information or how to get to the next stages logs from the current stage’s log output screen. They feel more intuitive linking and flow may alleviate the problem. Generally, they feel GitLab’s navigation needs to reviewed and optimised.

#### Permissions
>
“There is no granular control over user or group permissions. The permissions for a project are too tightly coupled to the permissions for Gitlab CI/build pipelines.”
>

### Goals
* To be able to integrate third party tools easily with GitLab EE and to create custom integrations and patches where needed.
* To use GitLab EE primarily for code hosting, merge requests, continuous integration and issue management. James and his team want to be able to understand and use these particular features easily.
* To able to share one instance of GitLab EE with multiple teams across the business. Advanced user management, the ability to separate permissions on different parts of the source code, etc are important to James.

---

## Karolina Plaskaty
- Using GitLab.com for personal/hobby projects
- Would like to use GitLab at work
- Working for a medium to large size organisation

<img src="img/karolina-plaskaty.png" width="300px">

### Demographics

- **Age**<br>26 years old
- **Location**<br>UK
- **Education**<br>Self taught
- **Occupation**<br>Junior web-developer
- **Programming experience**<br>6 years
- **Frequently used programming languages**<br>JavaScript and SQL
- **Hobbies / interests**<br>Web development, mobile development, UX, open source, gaming and travel.

### Motivations
Karolina has been using GitLab.com for around a year. She roughly spends 8 hours every week programming, of that, 2 hours is spent contributing to open source projects. Karolina contributes to open source projects to gain programming experience and to give back to the community. She likes GitLab.com for its free private repositories and range of features which provide her with everything she needs for her personal projects. Karolina is also a massive fan of GitLab’s values and the fact that it isn’t a “behemoth of a company”.  She explains that “displaying every single thing (doc, culture, assumptions, development...) in the open gives me greater confidence to choose Gitlab personally and to recommend it at work.”  She’s also an avid reader of GitLab’s blog.

Karolina works for a software development company which currently hires around 500 people. Karolina would love to use GitLab at work but the company has used GitHub Enterprise for a number of years. She describes management at her company as “old fashioned” and explains that it’s “less of a technical issue and more of a cultural issue” to convince upper management to move to GitLab. Karolina is also relatively new to the company so she’s apprehensive about pushing too hard to change version control platforms.

### Frustrations
#### Unable to use GitLab at work
Karolina wants to use GitLab at work but isn’t sure how to approach the subject with management. In her current role, she doesn’t feel that she has the authority to request GitLab.

#### Performance
GitLab.com is frequently slow and unavailable. Karolina has also heard that GitLab is a “memory hog”  which has deterred her from running GitLab on her own machine for just hobby / personal projects.

#### UX/UI
Karolina has an interest in UX and therefore has strong opinions about how GitLab should look and feel. She feels the interface is cluttered, “it has too many links/buttons” and the navigation “feels a bit weird sometimes. I get lost if I don’t pay attention.” As Karolina also enjoys contributing to open-source projects, it’s important to her that GitLab is well designed for public repositories, she doesn’t feel that GitLab currently achieves this.

### Goals
* To develop her programming experience and to learn from other developers.
* To contribute to both her own and other open source projects.
* To use a fast and intuitive version control platform.
