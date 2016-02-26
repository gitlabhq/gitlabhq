#!/bin/bash
# Sends Slack notification ERROR_MSG to CHANNEL
# An env. variable CI_SLACK_WEBHOOK_URL needs to be set.

CHANNEL=$1
ERROR_MSG=$2

if [ -z "$CHANNEL" ] || [ -z "$ERROR_MSG" ] || [ -z "$CI_SLACK_WEBHOOK_URL" ]; then
    echo "Missing argument(s) - Use: $0 channel message"
    echo "and set CI_SLACK_WEBHOOK_URL environment variable."
else
    curl -X POST --data-urlencode 'payload={"channel": "'"$CHANNEL"'", "username": "gitlab-ci", "text": "'"$ERROR_MSG"'", "icon_emoji": ":gitlab:"}' "$CI_SLACK_WEBHOOK_URL"
fi