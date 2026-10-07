#!/usr/bin/env bash
# Tests scripts/joe.sh with a stubbed `postgresai` on PATH. No network.
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
joe="$here/../scripts/joe.sh"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
failures=0

cat > "$tmp/postgresai" <<'STUB'
#!/usr/bin/env bash
# Behavior driven by STUB_MODE; STUB_STATE counts `result` calls.
echo "$*" >> "$STUB_DIR/calls"
if [ "$2" = "result" ]; then
  n=$(($(cat "$STUB_DIR/state" 2>/dev/null || echo 0) + 1)); echo "$n" > "$STUB_DIR/state"
  if [ "$n" -ge "${STUB_READY_AFTER:-2}" ]; then echo "command 42 · ok"; echo "plan: done"; exit 0; fi
  echo "${STUB_RESULT_ERR:-command 42 · pending — result is not ready}" >&2; exit 1
fi
if [ "$STUB_MODE" = "literal" ]; then
  echo "command 43 · ok"; echo "plan:"; echo "  Index Cond: (name = 'resume: pgai joe result 7'::text)"; exit 0
fi
if [ "$STUB_MODE" = "banner" ]; then
  echo "WARNING: new CLI version available"
  echo "started 42 · pending · budget 25s reached — resume:  pgai joe result 42"; exit 0
fi
if [ "$STUB_MODE" = "reworded" ]; then
  echo "command 42 is still running (budget reached) — resume: postgresai joe result 42"; exit 0
fi
if [ "$STUB_MODE" = "noid" ]; then
  echo "budget reached — resume: later"; exit 0
fi
if [ "$STUB_MODE" = "pending" ]; then
  echo "started 42 · pending · budget 25s reached — resume:  pgai joe result 42"; exit 0
fi
echo "command 41 · ok"; echo "plan: fast"
STUB
chmod +x "$tmp/postgresai"

run() { # name expected_rc expected_output_substring; remaining env set by caller
  local name="$1" want_rc="$2" want_out="$3" out rc=0
  : > "$tmp/calls"; rm -f "$tmp/state"
  out="$(PATH="$tmp:$PATH" STUB_DIR="$tmp" JOE_POLL_MAX_SECONDS=1 "$joe" plan --project x "SELECT 1" 2>/dev/null)" || rc=$?
  out_last="$out"
  if [ "$rc" -eq "$want_rc" ] && [[ "$out" == *"$want_out"* ]]; then echo "ok - $name"
  else echo "FAIL - $name (rc=$rc out=$out)"; failures=$((failures + 1)); fi
}

STUB_MODE=fast run "passes through immediate result" 0 "plan: fast"
if [ "$(grep -c result "$tmp/calls")" -ne 0 ]; then echo "FAIL - fast path polled"; failures=$((failures + 1)); fi
STUB_MODE=literal run "passes through a result whose body echoes resume literals" 0 "joe result 7"
if [ "$(grep -c result "$tmp/calls")" -ne 0 ]; then echo "FAIL - literal path polled"; failures=$((failures + 1)); fi
STUB_MODE=banner STUB_READY_AFTER=2 run "polls when a banner precedes the status line" 0 "plan: done"
STUB_MODE=reworded STUB_READY_AFTER=2 run "polls on reworded line carrying the resume command" 0 "plan: done"
STUB_MODE=noid run "fails loud when resume: has no id" 1 ""
export STUB_MODE=pending
STUB_READY_AFTER=2 run "polls pending until ready" 0 "plan: done"
STUB_READY_AFTER=2 run "prints only the final result" 0 "command 42 · ok"
if [[ "$out_last" == *"started 42"* || "$out_last" == *"pending"* ]]; then echo "FAIL - pending text leaked to stdout"; failures=$((failures + 1)); fi
STUB_READY_AFTER=99 JOE_WAIT_SECONDS=2 run "times out with exit 1" 1 ""
# A non-pending failure from `result` must abort instead of polling until timeout.
STUB_READY_AFTER=99 STUB_RESULT_ERR="Error: unauthorized" JOE_WAIT_SECONDS=30 run "aborts on non-pending error" 1 ""
if [ "$(grep -c result "$tmp/calls")" -ne 1 ]; then echo "FAIL - kept polling after error"; failures=$((failures + 1)); fi
# An error whose body merely mentions "pending" must not be treated as pending.
STUB_READY_AFTER=99 STUB_RESULT_ERR=$'command 42 · error\nERROR: relation "pending_jobs" does not exist' JOE_WAIT_SECONDS=30 run "fails fast when error body mentions pending" 1 ""
if [ "$(grep -c result "$tmp/calls")" -ne 1 ]; then echo "FAIL - polled on pending-looking error body"; failures=$((failures + 1)); fi

# --json is unsupported by the wrapper.
rc=0; msg="$(PATH="$tmp:$PATH" STUB_DIR="$tmp" "$joe" plan --json --project x "SELECT 1" 2>&1)" || rc=$?
if [ "$rc" -eq 2 ] && [[ "$msg" == *"text-only"* ]]; then echo "ok - rejects --json with exit 2"
else echo "FAIL - --json handling (rc=$rc msg=$msg)"; failures=$((failures + 1)); fi
# (b) An unrecognized result header reports the id and the manual resume command.
STUB_READY_AFTER=99 STUB_RESULT_ERR="status: waiting" JOE_WAIT_SECONDS=30 run "unrecognized header fails" 1 ""
err="$(PATH="$tmp:$PATH" STUB_DIR="$tmp" STUB_MODE=pending STUB_READY_AFTER=99 STUB_RESULT_ERR="status: waiting" "$joe" plan --project x "SELECT 1" 2>&1 >/dev/null)" || true
if [[ "$err" == *"command 42"* && "$err" == *"postgresai joe result 42"* ]]; then echo "ok - unrecognized header names id and resume command"
else echo "FAIL - resume hint missing (err=$err)"; failures=$((failures + 1)); fi

# (c) A budget-expired line with `resume:` but no extractable id must fail instead of passing as success.
cat > "$tmp/postgresai" <<'STUB'
#!/usr/bin/env bash
echo "queued - waiting - resume: ask support"
STUB
rc=0; err="$(PATH="$tmp:$PATH" "$joe" plan --project x "SELECT 1" 2>&1 >/dev/null)" || rc=$?
if [ "$rc" -eq 1 ] && [[ "$err" == *"no command id"* ]]; then echo "ok - resume without id fails"
else echo "FAIL - reworded line (rc=$rc err=$err)"; failures=$((failures + 1)); fi

# A failing CLI passes through with its own message and exit code, without a script trailer.
cat > "$tmp/postgresai" <<'STUB'
#!/usr/bin/env bash
echo "ERROR: failed to create a Database Lab clone" >&2
exit 3
STUB
rc=0; err="$(PATH="$tmp:$PATH" "$joe" plan --project x "SELECT 1" 2>&1 >/dev/null)" || rc=$?
if [ "$rc" -eq 3 ] && [[ "$err" != *"failed at line"* ]] && [[ "$err" == *"failed to create a Database Lab clone"* ]]; then echo "ok - CLI failure passes through"
else echo "FAIL - CLI failure handling (rc=$rc err=$err)"; failures=$((failures + 1)); fi
exit "$failures"
