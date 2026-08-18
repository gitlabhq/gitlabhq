#!/usr/bin/env bash
set -euo pipefail
## Run this script at the root of the GitLab Rails app

## Regenerates the vendored IAM gRPC client stubs from the IAM repo
## (https://gitlab.com/gitlab-org/auth/iam) and commits the result.
##
## Set REF to generate from a specific branch, tag or commit (defaults to main):
##   REF=my-branch scripts/update-iam-grpc-client.sh

repo=https://gitlab.com/gitlab-org/auth/iam.git
ref=${REF:-main}
tmp=tmp/gitlab-iam
services=(auth relationships update lookup)

gem_target="vendor/gems/gitlab-iam-grpc"
out_dir="$gem_target/lib"
revision_file="$gem_target/REVISION"

## Check if there are uncommitted changes
if git diff --exit-code; then
  echo "Clean repo"
else
  echo "There are uncommitted changes. Please commit them and then run this command"
  exit 1
fi

## Ensure required tools exist. `buf` resolves the IAM repo's proto dependencies
## (incl. buf.validate) so we never have to vendor or strip them; protoc then
## parses the (buf.validate.*) options as known custom options and the Ruby
## runtime ignores them at runtime.
for tool in grpc_tools_ruby_protoc buf; do
  if ! command -v "$tool" >/dev/null 2>&1; then
    echo "Error: $tool not found in PATH."
    exit 1
  fi
done

## Clone the IAM repo into a temporary directory
rm -rf "$tmp"
git clone --single-branch --branch "$ref" "$repo" "$tmp"
echo "Checked out ${ref}"

prev_rev=$(cat "$revision_file" 2>/dev/null || true)
rev=$(git -C "$tmp" rev-parse HEAD)
short_rev=$(git -C "$tmp" rev-parse --short HEAD)

export_dir="$(mktemp -d)"   # IAM protos + resolved deps (incl. buf/validate)
gen_dir="$(mktemp -d)"      # flat proto tree we hand to protoc
trap 'rm -rf "$export_dir" "$gen_dir" "$tmp"' EXIT

echo "Exporting IAM protos and their dependencies into a temporary directory"
# Materializes the module and every import (buf.validate, etc.) under
# $export_dir. Build inputs only -- nothing here is committed.
buf export "$tmp" -o "$export_dir"

echo "Assembling a flat proto tree for generation"
# Carry resolved dependency protos through unchanged (buf.validate lives here, so
# protoc can parse the (buf.validate.*) options instead of us stripping them).
cp -R "$export_dir"/. "$gen_dir"/
rm -rf "$gen_dir/proto"

# Flatten the repo-root-relative `proto/` import prefix to match the vendored
# flat layout. Literal substring replace on import lines -- no option parsing.
for svc in "${services[@]}"; do
    mkdir -p "$gen_dir/$svc"
    for file in "$export_dir"/proto/"$svc"/*.proto; do
        [ -f "$file" ] || continue
        sed 's#import "proto/#import "#' "$file" > "$gen_dir/$svc/$(basename "$file")"
    done
done

echo "Generating Ruby gRPC client stubs into $out_dir"
for svc in "${services[@]}"; do
    for file in "$gen_dir/$svc"/*.proto; do
        [ -f "$file" ] || continue
        echo "  Generating client for: $svc/$(basename "$file")"
        grpc_tools_ruby_protoc \
          --ruby_out="$out_dir" \
          --grpc_out="$out_dir" \
          -I "$gen_dir" \
          "$svc/$(basename "$file")"
    done
done

# Vendor the buf.validate proto too, so the gem is self-contained and does not
# depend on another gem (such as gitlab-kas-grpc) providing
# buf/validate/validate_pb at runtime. The relationships/update stubs require it
# because their descriptors carry the (buf.validate.*) options. It defines no
# service, so generate messages only (--ruby_out).
if [ -f "$gen_dir/buf/validate/validate.proto" ]; then
    echo "  Generating client for: buf/validate/validate.proto"
    grpc_tools_ruby_protoc \
      --ruby_out="$out_dir" \
      -I "$gen_dir" \
      "buf/validate/validate.proto"
fi

## Commit changes
git add "$gem_target"
if git diff --exit-code HEAD "$gem_target"; then
  echo "No changes to commit"
else
  echo "Committing code"
  # Record the IAM repo revision the stubs were generated from, so regeneration
  # is reproducible and the committed stubs are auditable.
  printf '%s\n' "$rev" > "$revision_file"
  git add "$revision_file"
  if [ -n "$prev_rev" ]; then
    changelog=$(git -C "$tmp" log --no-merges --pretty="- %h: %s" "$prev_rev..$rev" -- proto/)
  else
    changelog=""
  fi
  git commit -m "Update IAM gRPC Client Gem to $short_rev" -m "$changelog" -m 'Changelog: other'
fi

echo "IAM gRPC Client Updated"
