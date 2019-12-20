# Sends Slack notification MSG to CI_SLACK_WEBHOOK_URL (which needs to be set).
# ICON_EMOJI needs to be set to an icon emoji name (without the `:` around it).
function notify_slack() {
    CHANNEL=$1
    MSG=$2
    ICON_EMOJI=$3

    if [ -z "$CHANNEL" ] || [ -z "$CI_SLACK_WEBHOOK_URL" ] || [ -z "$MSG" ] || [ -z "$ICON_EMOJI" ]; then
        echo "Missing argument(s) - Use: $0 channel message icon_emoji"
        echo "and set CI_SLACK_WEBHOOK_URL environment variable."
    else
        curl -X POST --data-urlencode 'payload={"channel": "#'"${CHANNEL}"'", "username": "GitLab QA Bot", "text": "'"${MSG}"'", "icon_emoji": "'":${ICON_EMOJI}:"'"}' "${CI_SLACK_WEBHOOK_URL}"
    fi
}

function notify_on_job_failure() {
    JOB_NAME=$1
    CHANNEL=$2
    MSG=$3
    ICON_EMOJI=$4

    local job_id
    job_id=$(scripts/get-job-id "$CI_PROJECT_ID" "$CI_PIPELINE_ID" "$JOB_NAME" -s failed)
    if [ -n "${job_id}" ]; then
        notify_slack "${CHANNEL}" "${MSG}" "${ICON_EMOJI}"
    fi
}
