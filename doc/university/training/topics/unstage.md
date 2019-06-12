---
comments: false
---

# Unstage

## Unstage

- To remove files from stage use reset HEAD where HEAD is the last commit of the current branch. This will unstage the file but maintain the modifications. 

    ```bash
    git reset HEAD <file>
    ```

- To revert the file back to the state it was in before the changes we can use:

    ```bash
    git checkout -- <file>
    ```

- To remove a file from disk and repo use 'git rm' and to rm a dir use the '-r' flag:

    ```sh
    git rm '*.txt'
    git rm -r <dirname>
    ```

- If we want to remove a file from the repository but keep it on disk, say we forgot to add it to our `.gitignore` file then use `--cache`:

    ```sh
    git rm <filename> --cache
    ```
