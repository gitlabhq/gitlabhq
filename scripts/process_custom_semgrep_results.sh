# This script requires BOT_USER_ID, CUSTOM_SAST_RULES_BOT_PAT and CI_MERGE_REQUEST_IID variables to be set

echo "Processing vuln report"

# Preparing the message for the comment that will be posted by the bot
# Empty string if there are no findings
jq -crM '.vulnerabilities |
  map( select( .identifiers[0].name | test( "glappsec_" ) ) |
  "- `" + .location.file + "` line " + ( .location.start_line | tostring ) +
    (
      if .location.start_line = .location.end_line then ""
      else ( " to " + ( .location.end_line | tostring ) ) end
    ) + ": " + .message
  ) |
  sort |
  if length > 0 then
    { body: ("The findings below have been detected based on the AppSec custom SAST rules. For more information about this bot head over to [the FAQ](https://gitlab.com/gitlab-com/gl-security/appsec/sast-custom-rules/-/tree/main/#faq).\n\n" + join("\n") + "\n\nPing `@gitlab-com/gl-security/appsec` if you need assistance regarding those findings.") }
  else
    empty
  end' gl-sast-report.json >findings.txt

echo "Resulting file:"
cat findings.txt

EXISTING_COMMENT_ID=$(curl "https://gitlab.com/api/v4/projects/$CI_PROJECT_ID/merge_requests/$CI_MERGE_REQUEST_IID/notes?per_page=100" \
  --header "Private-Token: $CUSTOM_SAST_RULES_BOT_PAT" |
  jq -crM 'map( select( .author.id == (env.BOT_USER_ID | tonumber) ) | .id ) | first')

echo "EXISTING_COMMENT_ID: $EXISTING_COMMENT_ID"

if [ "$EXISTING_COMMENT_ID" == "null" ]; then
  if [ -s findings.txt ]; then
    echo "No existing comment and there are findings: a new comment will be posted"
    curl "https://gitlab.com/api/v4/projects/$CI_PROJECT_ID/merge_requests/$CI_MERGE_REQUEST_IID/notes" \
      --header "Private-Token: $CUSTOM_SAST_RULES_BOT_PAT" \
      --header 'Content-Type: application/json' \
      --data '@findings.txt'
  else
    echo "No existing comment and no findings: nothing to do"
  fi
else
  if [ -s findings.txt ]; then
    echo "There is an existing comment and there are findings: the existing comment will be updated"
    curl --request PUT "https://gitlab.com/api/v4/projects/$CI_PROJECT_ID/merge_requests/$CI_MERGE_REQUEST_IID/notes/$EXISTING_COMMENT_ID" \
      --header "Private-Token: $CUSTOM_SAST_RULES_BOT_PAT" \
      --header 'Content-Type: application/json' \
      --data '@findings.txt'
  else
    echo "There is an existing comment but no findings: the existing comment will be updated to mention everything is resolved"
    curl --request PUT "https://gitlab.com/api/v4/projects/$CI_PROJECT_ID/merge_requests/$CI_MERGE_REQUEST_IID/notes/$EXISTING_COMMENT_ID" \
      --header "Private-Token: $CUSTOM_SAST_RULES_BOT_PAT" \
      --header 'Content-Type: application/json' \
      --data '{"body":"All findings based on the [AppSec custom Semgrep rules](https://gitlab.com/gitlab-com/gl-security/appsec/sast-custom-rules/) have been resolved! :tada:"}'
  fi
fi
