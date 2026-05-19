#!/usr/bin/env python3
"""
Validates category tags in GitLab release notes files.

All H3 headings MUST have a <!-- categories: ... --> tag.

Usage:
  python3 validate_release_categories.py \
    --release-notes doc/releases/19/gitlab-19-0-released.md \
    --categories-url https://gitlab.com/gitlab-com/www-gitlab-com/-/raw/master/data/categories.yml
"""

import argparse
import re
import sys
import urllib.error
import urllib.request

CATEGORIES_URL = "https://gitlab.com/gitlab-com/www-gitlab-com/-/raw/master/data/categories.yml"

# Matches <!-- categories: Foo, Bar, Baz -->
CATEGORY_COMMENT_RE = re.compile(r"<!--\s*categories:\s*(.+?)\s*-->")

# Matches `name: 'Some Category'` or `name: "Some Category"` or `name: Some Category`
CATEGORY_NAME_RE = re.compile(r"^\s{2}name:\s*['\"]?(.+?)['\"]?\s*$", re.MULTILINE)

# 1MB limit to prevent memory exhaustion from unexpectedly large responses
MAX_RESPONSE_BYTES = 1024 * 1024

def fetch_valid_category_names(url: str) -> set[str]:
  if not url.startswith("https://"):
    raise ValueError(f"URL must use HTTPS: {url}")

  request = urllib.request.Request(url)
  with urllib.request.urlopen(request, timeout=30) as response:
    content = response.read(MAX_RESPONSE_BYTES)

  if len(content) == MAX_RESPONSE_BYTES:
    raise ValueError("Response exceeded 1MB limit")

  return set(CATEGORY_NAME_RE.findall(content.decode("utf-8")))


def parse_release_notes(path: str) -> list[tuple[str, list[str] | None, bool]]:
  """
  Returns a list of (heading, categories) tuples for every H3 in the file.
  - heading: the H3 heading text.
  - categories: None if no tag was found, or a list of category name strings if found.
  """
  with open(path, encoding="utf-8") as f:
    content = f.read()

  # Remove feature addition template comment blocks entirely before parsing
  template_comment_pattern = r'<!--\s*Copy this template.*?-->'
  content = re.sub(template_comment_pattern, '', content, flags=re.DOTALL)

  results = []

  # Split on H2 and H3 headings, keeping the heading lines as tokens
  sections = re.split(r"^(#{2,3} .+)$", content, flags=re.MULTILINE)

  i = 1
  while i < len(sections) - 1:
    heading_line = sections[i].strip()
    body = sections[i + 1]

    if heading_line.startswith("## "):
      h2_text = heading_line.removeprefix("## ").strip()

    elif heading_line.startswith("### "):
      heading = heading_line.removeprefix("### ").strip()

      # Only search for the category tag before the {{< details >}} block
      # to enforce that it stays co-located with the heading
      before_details = (
        body.split("{{< details >}}")[0] if "{{< details >}}" in body else body
      )
      
      match = CATEGORY_COMMENT_RE.search(before_details)

      categories = (
        [c.strip() for c in match.group(1).split(",") if c.strip()]
        if match
        else None
      )

      results.append((heading, categories))

    i += 2

  return results

def validate_file(file_path: str, valid_names: set[str]) -> tuple[bool, list[str]]:
  """
  Validate a single release note file and return (success, errors).
  """
  try:
    features = parse_release_notes(file_path)
  except FileNotFoundError:
    return False, [f"File not found: {file_path}"]
  except Exception as e:
    return False, [f"Error reading {file_path}: {e}"]

  tagged = [(h, cats) for h, cats in features if cats is not None]
  untagged = [(h, cats) for h, cats in features if cats is None]

  if not tagged:
    print(f"No category tags found in {file_path}, skipping.")
    return True, []

  errors = []
  lower_map = {name.lower(): name for name in valid_names}

  # Fail on features missing a tag
  for heading in untagged:
    errors.append(
      f"  MISSING tag  ### {heading}\n"
      f"               All features must have a category."
    )

  # Fail on incorrect category names in any tagged heading
  for heading, categories in tagged:
    for cat in categories:
      if cat not in valid_names:
        if cat.lower() in lower_map:
          correct = lower_map[cat.lower()]
          errors.append(
            f"  CASE MISMATCH ### {heading}\n"
            f"               '{cat}' should be '{correct}'"
          )
        else:
          errors.append(
            f"  UNKNOWN      ### {heading}\n"
            f"               '{cat}' not found in categories.yml"
          )

  return len(errors) == 0, errors

def main() -> None:
  parser = argparse.ArgumentParser(
    description="Validate release note category tags against categories.yml."
  )
  parser.add_argument(
    "--release-notes",
    nargs="+",
    required=True,
    help="Path(s) to the release notes markdown file(s)",
  )
  parser.add_argument(
    "--categories-url",
    default=CATEGORIES_URL,
    help="Raw HTTPS URL to categories.yml",
  )
  args = parser.parse_args()

  print(f"Fetching categories from {args.categories_url} ...\n")
  try:
    valid_names = fetch_valid_category_names(args.categories_url)
  except (urllib.error.URLError, ValueError) as e:
    print(f"Failed to fetch or parse categories.yml: {e}")
    sys.exit(2)

  print(f"{len(valid_names)} valid category names loaded.\n")

  all_errors = []
  files_processed = 0
  files_with_errors = 0

  for file_path in args.release_notes:
    print(f"Validating {file_path} ...")
    success, errors = validate_file(file_path, valid_names)
    files_processed += 1
    
    if not success:
      files_with_errors += 1
      all_errors.extend([f"In {file_path}:"] + errors + [""])
    else:
      if errors:
        files_with_errors += 1
        all_errors.extend([f"In {file_path}:"] + errors + [""])

  # print("\n" + "=" * 50)
  print(f"Processed {files_processed} file(s)")

  if all_errors:
    print(f"\n{files_with_errors} file(s) had validation errors:\n")
    for error in all_errors:
      print(error)
    print("Valid category names:\n  " + "\n  ".join(sorted(valid_names)))
    sys.exit(1)

  print(f"All {files_processed} file(s) passed validation.")


if __name__ == "__main__":
  main()
