---
comments: false
---

# Bisect	  	

----------

## Bisect

- Find a commit that introduced a bug
- Works through a process of elimination
- Specify a known good and bad revision to begin	  	

----------

## Bisect

1. Start the bisect process
2. Enter the bad revision (usually latest commit)
3. Enter a known good revision (commit/branch)
4. Run code to see if bug still exists
5. Tell bisect the result
6. Repeat the previous 2 items until you find the offending commit

----------

## Setup

```
  mkdir bisect-ex
  cd bisect-ex
  touch index.html
  git add -A
  git commit -m "starting out"
  vi index.html
  # Add all good
  git add -A
  git commit -m "second commit"
  vi index.html
  # Add all good 2
  git add -A
  git commit -m "third commit"
  vi index.html
```

----------

```
  # Add all good 3
  git add -A
  git commit -m "fourth commit"
  vi index.html
  # This looks bad
  git add -A
  git commit -m "fifth commit"
  vi index.html
  # Really bad
  git add -A
  git commit -m "sixth commit"
  vi index.html
  # again just bad
  git add -A
  git commit -m "seventh commit"
```

----------

## Commands

```
  git bisect start
  # Test your code
  git bisect bad
  git bisect next
  # Say yes to the warning
  # Test
  git bisect good
  # Test
  git bisect bad
  # Test
  git bisect good
  # done
  git bisect reset
```
