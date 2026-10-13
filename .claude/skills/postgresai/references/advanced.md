# JSON output and explicit clones

## JSON

`scripts/joe.sh` is text-only and exits 2 on `--json`. For JSON, run the raw CLI with `--json`
and poll `postgresai joe result <id> --json` (exit 1 and `"status":"pending"` while running).

## Explicit clones

`postgresai dblab clone create|list|status|reset|destroy` is rarely needed; `joe` manages its
own session clone. Never pass `--protected`. Destroy clones you created if your role allows
it (it needs Admin or AllFeaturesUser); otherwise let auto-deletion handle it.
