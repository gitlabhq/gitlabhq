# Issue API — State Transitions and Notes

## Close / reopen an issue

```bash
glab api --method PUT "projects/<project_id>/issues/<iid>" -f state_event=close
glab api --method PUT "projects/<project_id>/issues/<iid>" -f state_event=reopen
```

## Post a comment (note)

**⚠️ The `body` field on PUT is silently ignored — always use POST for notes.**

```bash
# Plain text comment
glab api --method POST "projects/<project_id>/issues/<iid>/notes" -f "body=Your comment"

# Comment with special characters (backticks, $, etc.) — write to file first
MSG=<agent picks path>
cat > "$MSG" << 'EOF'
Your comment with `backticks` and $vars here.
EOF
glab api --method POST "projects/<project_id>/issues/<iid>/notes" \
  -f "body=$(cat "$MSG")"
```

## URL-encode project paths

Use `%2F` for `/` in project paths:

```bash
# project gitlab-org/myproject → gitlab-org%2Fmyproject
glab api --method PUT "projects/gitlab-org%2Fmyproject/issues/42" -f state_event=close
```

## Notes on state events

- `state_event=close` — closes the issue
- `state_event=reopen` — reopens a closed issue
- No other state events are supported via REST on issues
