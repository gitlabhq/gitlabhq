# Code Review Guidelines

## Review methodology

Work through these layers in order when reviewing any change:

1. **Scope and intent** — understand what the change is trying to do before evaluating how it does it
2. **Architecture** — does the approach fit the codebase's established patterns? Does it introduce debt?
3. **Blockers** — regressions, security issues, missing error handling, test coverage gaps, pattern violations, unreachable code
4. **Improvements** — non-blocking but meaningful suggestions worth making
5. **Nitpicks** — style, naming, minor inconsistencies — label these explicitly as nitpicks so the author knows they are not blockers

## Verdict

- Any blocker present → **Request Changes**. Do not approve with unresolved blockers.
- Nitpicks only → **Approve** (note them, but do not block on them)
- No issues → **Approve**

## Minimal change principle

Prefer the smallest change that correctly solves the problem. When reviewing, flag unnecessary scope creep — changes to files or layers not required for the fix add risk without benefit. If a change touches more than what the task requires, question whether each additional change is genuinely load-bearing.

## Debugging during review

When a bug resists 1–2 fix attempts, stop speculating through code alone. Ask the author or user to verify runtime state directly: console output, DevTools element inspection, computed styles, network requests. Formulate precise questions ("what classes are on this element?", "what does this variable log as?") — one targeted observation resolves what many iterations of code guessing cannot.
