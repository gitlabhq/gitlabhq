[[ "$TRACE" ]] && set -x

function create_user() {
    local user="${1}"

    # API details at https://docs.gitlab.com/ee/api/users.html#user-creation
    #
    # We set "can_create_group=false" because we don't want the DAST user to create groups.
    # Otherwise, the DAST user likely creates a group and enables 2FA for all group members,
    # which leads to the DAST scan getting "stuck" on the 2FA set up page.
    # Once https://gitlab.com/gitlab-org/gitlab/-/issues/231447 is resolved, we can use 
    # DAST_AUTH_EXCLUDE_URLS instead to prevent DAST from enabling 2FA.
    curl --silent --show-error --header "PRIVATE-TOKEN: ${REVIEW_APPS_ROOT_TOKEN}" \
        --data "email=${user}@example.com" \
        --data "name=${user}" \
        --data "username=${user}" \
        --data "password=${REVIEW_APPS_ROOT_PASSWORD}" \
        --data "skip_confirmation=true" \
        --data "can_create_group=false" \
        "${CI_ENVIRONMENT_URL}/api/v4/users" > /tmp/user.json

    [[ "$TRACE" ]] && cat /tmp/user.json >&2

    jq .id /tmp/user.json
}

function create_project_for_user() {
    local userid="${1}"

    # API details at https://docs.gitlab.com/ee/api/projects.html#create-project-for-user
    curl --silent --show-error --header "PRIVATE-TOKEN: ${REVIEW_APPS_ROOT_TOKEN}" \
        --data "user_id=${userid}" \
        --data "name=awesome-test-project-${userid}" \
        --data "visibility=private" \
        "${CI_ENVIRONMENT_URL}/api/v4/projects/user/${userid}" > /tmp/project.json

    [[ "$TRACE" ]] && cat /tmp/project.json >&2
}

function trigger_proj_user_creation(){
    local u1=$(create_user "user1")
    create_project_for_user $u1
    local u2=$(create_user "user2")
    create_project_for_user $u2
    local u3=$(create_user "user3")
    create_project_for_user $u3
    local u4=$(create_user "user4")
    create_project_for_user $u4
    local u5=$(create_user "user5")
    create_project_for_user $u5
    local u6=$(create_user "user6")
    create_project_for_user $u6
    local u7=$(create_user "user7")
    create_project_for_user $u7
    local u8=$(create_user "user8")
    create_project_for_user $u8
    local u9=$(create_user "user9")
    create_project_for_user $u9
    local u10=$(create_user "user10")
    create_project_for_user $u10
    local u11=$(create_user "user11")
    create_project_for_user $u11
    local u12=$(create_user "user12")
    create_project_for_user $u12
    local u13=$(create_user "user13")
    create_project_for_user $u13
    local u14=$(create_user "user14")
    create_project_for_user $u14
}
