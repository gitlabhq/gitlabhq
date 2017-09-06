# GitLab JIRA Development Panel integration

As an extension to our [existing JIRA][existing-jira] project integration, you're now able to integrate
all your GitLab projects with [JIRA Development Panel][jira-development-panel].

By doing this you can easily monitor new Branches, Commits and Merge Requests directly on a Jira issue.

>**Note:**
Our current integration supports Branches and Commits, but we're eagerly looking forward to extend this functionality.

We have split the setup in a few steps so it is easier to follow.


## On GitLab

1. Create a new Application in order to allow Jira to connect with your GitLab account

	Logged-in on GitLab, go to `Settings -> Applications`

	![GitLab Application setup](img/jira_dev_panel_gl_setup_1.png)

	- Make sure to replace the `Redirect URI` HOST by your's (or `gitlab` in case you're using GitLab.com)
	- Make sure the logged-in user on GitLab has access to the projects you want to import to Jira.
	- Only the `api` scope needs to be checked

2. Save the generated 'Application id' and 'Secret', you'll need this information when configuring Jira.


## On Jira

1. Go to `Application -> DVCS accounts` and click on `Link GitHub account`

	![Jira DVCS from Dashboard](img/jira_dev_panel_jira_setup_1.png)

2. Provide the required information

	![Creation of Jira DVCS integration](img/jira_dev_panel_jira_setup_2.png)
	
	- Make sure to replace the `Host URL` HOST by your's (keeping the rest of the URL `/-/jira` unchanged)
	- Paste the `Application id` provided by GitLab on `Client ID` 
	- Paste the `Secret` provided by GitLab on `Client Secret` 
	
	>**Note:**
	In case you have multiple groups with projects that you want to import, you'll follow this process for each one of these groups. 
	So let's say your username on GitLab is 'mytest', but you have another group called 'group-a'. In order to import
	your projects ('mytest') and all projects within 'group-a', you'll create one integration providing 'mytest' as 'Team or User Account' and 	another one providing 'group-a'.

	
3. Click `Add` and finish the authorization process

	At that point you're done! All Projects Branches and Commits (within the configured groups) referring your Jira issues will be automatically
	imported.
	
	The import process can take a few seconds (or minutes) depending on how many projects and commits you have on GitLab.
	
	>**Note:**
	Jira automatically fetches your GitLab instance looking for new projects and referenced branches and projects in a 60 minute interval.
	

You can now see the linked `branches` and `commits` when entering a Jira issue.

![Branch and Commit links on Jira issue](img/jira_dev_panel_jira_setup_3.png)

Click these links for more information.

![GitLab commit details on a Jira issue](img/jira_dev_panel_jira_setup_4.png)


[existing-jira]: ../user/project/integrations/jira.md
[jira-development-panel]: https://confluence.atlassian.com/adminjiraserver070/integrating-with-development-tools-776637096.html#Integratingwithdevelopmenttools-Developmentpanelonissues
