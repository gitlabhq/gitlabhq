# Fast-forward merge

GitLab Enterprise Edition offers a way to accept merge request without creating merge commit.
If you prefer linear git history - this might be a good feature for you.
You can configure this per project basis by navigating to the project settings page and selecting `Only fast-forward merging` checkbox.

![Merge request settings](ff_merge.png)

Now when you visit merge request page you will be able to accept it only if fast-forward merge is possible. 
If target branch is ahead of source branch - you need to rebase source branch before you will be able to do fast-forward merge.

For simple rebase operations you can use [Rebase before merge](rebase_before_merge.md) feature. 
