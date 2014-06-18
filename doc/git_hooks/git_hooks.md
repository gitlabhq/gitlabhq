# Git Hooks

Sometimes you need additional control over pushes to your repository. GitLab already has protected branches. But there are cases when you need some specific rules like preventing git tag removal or special format of commit messages. And instead of manually writing shell script files directly into git repository GitLab Enterprise Edition offers a user-friendly interface for such cases. 

Git hooks are defined per project so you can have different rules applied for different projects depends on your needs. Git hooks settings you can find at Project settings -> Git Hooks page. 


## How to use

Let's assume you have next requirements for workflow:

* every commit should reference to reference JIRA issue. Ex. `Refactored css. Fixes JIRA-123. `
* users should not be able to remove git tags over `git push`

All you need to do is write simple regular expression that requires mention of JIRA issue in commit message. It can be something like this `/JIRA\-\d+/`. Just paste regular expression into commit message textfield(without start and ending slash) and save changes. See screenshot below: 
![screenshot](git_hooks.png)

Now when user tries to push commit like `Bugfix` - his push will be declined. 
And pushing commit with message like `Bugfix according to JIRA-123` will be accepted. 