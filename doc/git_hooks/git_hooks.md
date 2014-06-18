# Git Hooks

Sometimes you need additional control over pushes to your repository. GitLab already has protected branches. But there are cases when you need some specific rules like preventing git tag removal or special format of commit messages. And instead of manually writing shell script files directly into git repository GitLab Enterprise Edition offers a user-friendly interface for such cases. 

You can visit Project settings -> Git Hooks page to setup such rules. 
 
![screenshot](git_hooks.png)

On above below we requires each commit to mention JIRA issue. If user push commit with message like `Refactored css. Fixes JIRA-123.` But if user push commit message like `Refactored css` it will be declined.