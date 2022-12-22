LATEST_SHA=$(git rev-parse HEAD)
GIT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
BROKER_BASE_URL="http://localhost:9292"

cd "${0%/*}"

CONTRACTS=$(find ./contracts -name "*.json")
ERROR=0

trap 'catch' ERR

function catch() {
    printf "\e[31mAn error occured while trying to publish the pact.\033[0m\n"
    ERROR=1
}

for contract in $CONTRACTS
do
    printf "\e[32mPublishing ${contract}...\033[0m\n"
    pact-broker publish $contract --consumer-app-version $LATEST_SHA --branch $GIT_BRANCH --broker-base-url $BROKER_BASE_URL --output json
done

if [ ${ERROR} = 1 ]; then
    exit 1;
fi