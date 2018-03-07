---
comments: false
---

# GitLab Flow

- A simplified branching strategy
- All features and fixes first go to master
- Allows for 'production' or 'stable' branches
- Bug fixes/hot fix patches are cherry-picked from master

---

# Feature branches

- Create a feature/bugfix branch to do all work
- Use merge requests to merge to master

![inline](gitlab_flow/feature_branches.png)

---

# Production branch

- One, long-running production release branch
  as opposed to individual stable branches
- Consider creating a tag for each version that gets deployed

---

# Production branch

![inline](gitlab_flow/production_branch.png)

---

# Release branch

- Useful if you release software to customers
- When preparing a new release, create stable branch
  from master
- Consider creating a tag for each version
- Cherry-pick critical bug fixes to stable branch for patch release
- Never commit bug fixes directly to stable branch

---

# Release branch

![inline](gitlab_flow/release_branches.png)

---

# More details

Blog post on 'GitLab Flow' at
[http://doc.gitlab.com/ee/workflow/gitlab_flow.html](http://doc.gitlab.com/ee/workflow/gitlab_flow.html)
