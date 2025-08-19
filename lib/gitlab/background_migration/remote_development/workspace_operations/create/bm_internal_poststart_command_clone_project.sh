#!/bin/sh
echo "$(date -Iseconds): ----------------------------------------"
echo "$(date -Iseconds): Cloning project if necessary..."

# The project should be cloned only if one is not cloned successfully already.
# This is required to avoid resetting user's modifications to the files.
# This is achieved by checking for the existence of a file before cloning.
# If the file does not exist, clone the project.
if [ -f "%<project_cloning_successful_file>s" ]
then
  echo "$(date -Iseconds): Project cloning was already successful, because '%<project_cloning_successful_file>s' file already exists"
  echo "$(date -Iseconds): ----------------------------------------"
  exit 0
fi

# To accommodate for scenarios where the project cloning failed midway in the previous attempt,
# remove the directory before cloning.
if [ -d "%<clone_dir>s" ]
then
  echo "$(date -Iseconds): Removing unsuccessfully cloned project directory"
  rm -rf "%<clone_dir>s"
fi

clone_depth_option="%<clone_depth_option>s"
depth_msg="${clone_depth_option:+ with \"${clone_depth_option}\" option}"

echo "$(date -Iseconds): Cloning project${depth_msg}"
git clone $clone_depth_option --branch "%<project_ref>s" "%<project_url>s" "%<clone_dir>s"
exit_code=$?

# Once cloning is successful, create the file which is used in the check above.
# This will ensure the project is not cloned again on restarts.
if [ "${exit_code}" -eq 0 ]
then
  echo "$(date -Iseconds): Project cloning successful"
  touch "%<project_cloning_successful_file>s"
  echo "$(date -Iseconds): Updated '%<project_cloning_successful_file>s' file to indicate successful project cloning"
  echo "$(date -Iseconds): Successfully finished cloning project."
else
  echo "$(date -Iseconds): Project cloning failed with exit code: ${exit_code}" >&2
  echo "$(date -Iseconds): Failed to clone project, exit code was ${exit_code}"
fi

echo "$(date -Iseconds): ----------------------------------------"
exit "${exit_code}"
