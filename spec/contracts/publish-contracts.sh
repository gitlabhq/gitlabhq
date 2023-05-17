LATEST_SHA=$(git rev-parse HEAD)
GIT_BRANCH=$(git rev-parse --abbrev-ref HEAD)

cd "${0%/*}" || exit 1

function catch() {
    printf "\e[31mAn error occured while trying to publish the pact.\033[0m\n"
    ERROR=1
}

function publish_contract () {
    CONTRACTS=$(find ./contracts -name "*.json")
    ERROR=0

    trap 'catch' ERR

    for contract in $CONTRACTS
    do
        printf "\e[32mPublishing %s...\033[0m\n" "$contract"
        pact-broker publish "$contract" --consumer-app-version "$LATEST_SHA" --branch "$GIT_BRANCH" --broker-base-url "$QA_PACT_BROKER_HOST" --output json
    done

    if [ ${ERROR} = 1 ]; then
        exit 1;
    fi
}

function publish_ce_contracts () {
    publish_contract
}

function publish_ee_contracts () {
    cd "../../ee/spec/contracts" || exit 1
    publish_contract
}

if [ $1 = "ce" ]; then
    printf "\e[32mPublishing CE contracts...\033[0m\n"
    publish_ce_contracts
elif [ $1 = "ee" ]; then
    printf "\e[32mPublishing EE contracts...\033[0m\n"
    publish_ee_contracts
elif [ $1 = "all" ]; then
    printf "\e[32mPublishing all contracts...\033[0m\n"
    publish_ce_contracts
    publish_ee_contracts
else
    printf "\e[31mInvalid argument. Please choose either \"ce\", \"ee\", or \"all\".\033[0m\n"
    exit 1;
fi
