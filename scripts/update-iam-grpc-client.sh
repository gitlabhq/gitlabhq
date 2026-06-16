#!/usr/bin/env bash
set -eo pipefail

## Run this script at the root of the GitLab Rails app

usage() {
    echo "Usage: $0 <directory>"
    echo "  directory: Path to the directory to process"
    exit 1
}

# Check if argument is provided
if [ $# -eq 0 ]; then
    echo "Error: No directory specified"
    usage
fi

# Get the directory argument
target_dir="$1"

if [ ! -d "$target_dir" ]; then
    echo "Error: '$target_dir' is not a valid directory"
    exit 1
fi

if [ ! -r "$target_dir" ]; then
    echo "Error: Directory '$target_dir' is not readable"
    exit 1
fi

if [ -z "$(ls -A "$target_dir")" ]; then
    echo "Warning: Directory '$target_dir' is empty"
fi

# Ensure grpc_tools_ruby_protoc exists
if ! command -v grpc_tools_ruby_protoc >/dev/null 2>&1; then
    echo "Error: grpc_tools_ruby_protoc not found. Please install grpc-tools gem."
    exit 1
fi

echo "Using target directory: $target_dir"

for file in "$target_dir"/proto/auth/*.proto; do
    if [ -f "$file" ]; then
        echo "Generating client for file: $file"
        grpc_tools_ruby_protoc \
          --ruby_out=vendor/gems/gitlab-iam-grpc/lib \
          --grpc_out=vendor/gems/gitlab-iam-grpc/lib \
          -I "$target_dir"/proto \
          "$file"
    fi
done

echo "IAM gRPC Client Updated"
