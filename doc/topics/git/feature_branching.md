---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
comments: false
---

# Feature branching **(FREE)**

- Efficient parallel workflow for teams
- Develop each feature in a branch
- Keeps changes isolated
- Consider a 1-to-1 link to issues
- Push branches to the server frequently
  - Hint: This is a cheap backup for your work-in-progress code

## Feature branching sample workflow

1. Create a new feature branch called 'squash_some_bugs'
1. Edit '`bugs.rb`' and remove all the bugs.
1. Commit
1. Push

```shell
git checkout -b squash_some_bugs
# Edit `bugs.rb`
git status
git add bugs.rb
git commit -m 'Fix some buggy code'
git push origin squash_some_bugs
```
