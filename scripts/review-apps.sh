#!/bin/bash

# Docker images functions
function is_master(){
	[ "$CI_COMMIT_REF_NAME" == "master" ]
}

function needs_build(){
	echo "$CI_REGISTRY_IMAGE/$CI_PROJECT_PATH:$CI_COMMIT_SHA"
	! $(docker pull "$CI_REGISTRY_IMAGE/$CI_PROJECT_PATH:$CI_COMMIT_SHA" > /dev/null);
}

function build_if_needed(){
	if needs_build; then
		echo "BASE_IMAGE"
		echo $BASE_IMAGE
		if [ -n "$BASE_IMAGE" ]; then
			docker pull $BASE_IMAGE
		fi

		DOCKER_ARGS=( "$@" )
		CACHE_IMAGE="$CI_REGISTRY_IMAGE/$CI_JOB_NAME:$CI_COMMIT_REF_SLUG"
		echo "CACHE_IMAGE"
		echo $CACHE_IMAGE
		if ! $(docker pull $CACHE_IMAGE > /dev/null); then
			CACHE_IMAGE="$CI_REGISTRY_IMAGE/$CI_PROJECT_PATH:latest"
			docker pull $CACHE_IMAGE || true
		fi

		cd $CI_PROJECT_PATH

		echo "IMAGE"
		echo "$CI_REGISTRY_IMAGE/$CI_PROJECT_PATH:$CI_COMMIT_SHA"
		echo "DOCKER_ARGS"
		echo "${DOCKER_ARGS[@]}"
		docker build -t "$CI_REGISTRY_IMAGE/$CI_PROJECT_PATH:$CI_COMMIT_SHA" "${DOCKER_ARGS[@]}" --cache-from $CACHE_IMAGE .
		# Push new image
		# docker push "$CI_REGISTRY_IMAGE/$CI_PROJECT_PATH:$CI_COMMIT_SHA"

		# Create a tag based on Branch/Tag name for easy reference
		docker tag "$CI_REGISTRY_IMAGE/$CI_PROJECT_PATH:$CI_COMMIT_SHA" "$CI_REGISTRY_IMAGE/$CI_PROJECT_PATH:$CI_COMMIT_REF_SLUG" "$CI_REGISTRY_IMAGE/$CI_PROJECT_PATH:$CI_ENVIRONMENT_SLUG"
		# docker push "$CI_REGISTRY_IMAGE/$CI_PROJECT_PATH:$CI_COMMIT_REF_SLUG"
	fi
}

function push_latest(){
	docker tag "$CI_REGISTRY_IMAGE/$CI_PROJECT_PATH:$CI_COMMIT_SHA" "$CI_REGISTRY_IMAGE/$CI_PROJECT_PATH:latest"
	docker push "$CI_REGISTRY_IMAGE/$CI_PROJECT_PATH:latest"
}

function push_if_master(){
	if is_master; then
		push_latest $1
	fi
}

# Review apps variables and functions
[[ "$TRACE" ]] && set -x
auto_database_url=postgres://${POSTGRES_USER}:${POSTGRES_PASSWORD}@${CI_ENVIRONMENT_SLUG}-postgres:5432/${POSTGRES_DB}
export DATABASE_URL=${DATABASE_URL-$auto_database_url}
export CI_APPLICATION_REPOSITORY=$CI_REGISTRY_IMAGE/$CI_COMMIT_REF_SLUG
export CI_APPLICATION_TAG=$CI_COMMIT_SHA
export CI_CONTAINER_NAME=ci_job_build_${CI_JOB_ID}
export TILLER_NAMESPACE=$KUBE_NAMESPACE

function previousDeployFailed() {
	set +e
	echo "Checking for previous deployment of $CI_ENVIRONMENT_SLUG"
	deployment_status=$(helm status $CI_ENVIRONMENT_SLUG >/dev/null 2>&1)
	status=$?
	# if `status` is `0`, deployment exists, has a status
	if [ $status -eq 0 ]; then
		echo "Previous deployment found, checking status"
		deployment_status=$(helm status $CI_ENVIRONMENT_SLUG | grep ^STATUS | cut -d' ' -f2)
		echo "Previous deployment state: $deployment_status"
		if [[ "$deployment_status" == "FAILED" || "$deployment_status" == "PENDING_UPGRADE" || "$deployment_status" == "PENDING_INSTALL" ]]; then
			status=0;
		else
			status=1;
		fi
	else
		echo "Previous deployment NOT found."
	fi
	set -e
	return $status
}

function deploy() {
	track="${1-stable}"
	name="$CI_ENVIRONMENT_SLUG"

	if [[ "$track" != "stable" ]]; then
		name="$name-$track"
	fi

	replicas="1"
	service_enabled="false"
	postgres_enabled="$POSTGRES_ENABLED"
	# canary uses stable db
	[[ "$track" == "canary" ]] && postgres_enabled="false"

	env_track=$( echo $track | tr -s  '[:lower:]'  '[:upper:]' )
	env_slug=$( echo ${CI_ENVIRONMENT_SLUG//-/_} | tr -s  '[:lower:]'  '[:upper:]' )

	if [[ "$track" == "stable" ]]; then
		# for stable track get number of replicas from `PRODUCTION_REPLICAS`
		eval new_replicas=\$${env_slug}_REPLICAS
		service_enabled="true"
	else
		# for all tracks get number of replicas from `CANARY_PRODUCTION_REPLICAS`
		eval new_replicas=\$${env_track}_${env_slug}_REPLICAS
	fi
	if [[ -n "$new_replicas" ]]; then
		replicas="$new_replicas"
	fi

	#ROOT_PASSWORD=$(cat /dev/urandom | LC_TYPE=C tr -dc "[:alpha:]" | head -c 16)
	#echo "Generated root login: $ROOT_PASSWORD"
	# YAML_FILE=""${AUTO_DEVOPS_DOMAIN//\./-}.yaml"
	# Cleanup and previous installs, as FAILED and PENDING_UPGRADE will cause errors with `upgrade`
	if [ "$CI_ENVIRONMENT_SLUG" != "production" ] && previousDeployFailed ; then
		echo "Deployment in bad state, cleaning up $CI_ENVIRONMENT_SLUG"
		delete
		cleanup
	fi

	helm dep update .

	helm upgrade --install \
		--wait \
		--timeout 600 \

		--set gitlab.migrations.image.repository=registry.gitlab.com/$CI_PROJECT_PATH/gitlab-rails-ce:$CI_COMMIT_SHA \
		--set gitlab.sidekiq.image.repository=registry.gitlab.com/$CI_PROJECT_PATH/gitlab-sidekiq-ce:$CI_COMMIT_SHA \
		--set gitlab.unicorn.image.repository=registry.gitlab.com/$CI_PROJECT_PATH/gitlab-unicorn-ce:$CI_COMMIT_SHA \

		--set releaseOverride="$CI_ENVIRONMENT_SLUG" \
		--set global.hosts.hostSuffix="$HOST_SUFFIX" \
		--set global.hosts.domain="$AUTO_DEVOPS_DOMAIN" \
		--set global.hosts.externalIP="$DOMAIN_IP" \
		--set global.ingress.tls.secretName=helm-charts-win-tls \
		--set global.ingress.configureCertmanager=false \
		--set certmanager.install=false \
		--set gitlab.migrations.initialRootPassword="$ROOT_PASSWORD" \
		--set gitlab.omnibus.service.type=NodePort \
		--set gitlab.omnibus.resources.requests.cpu=100m \
		--set gitlab.unicorn.resources.requests.cpu=100m \
		--set gitlab.sidekiq.resources.requests.cpu=100m \
		--set gitlab.gitlab-shell.resources.requests.cpu=100m \
		--set redis.resources.requests.cpu=100m \
		--set minio.resources.requests.cpu=100m \
		--namespace="$KUBE_NAMESPACE" \
		--version="$CI_PIPELINE_ID-$CI_JOB_ID" \
		"$name" \
		.
}

function setup_test_db() {
	if [ -z ${KUBERNETES_PORT+x} ]; then
		DB_HOST=postgres
	else
		DB_HOST=localhost
	fi
	export DATABASE_URL="postgres://${POSTGRES_USER}:${POSTGRES_PASSWORD}@${DB_HOST}:5432/${POSTGRES_DB}"
}

function download_chart() {
	if [[ ! -d chart ]]; then
		auto_chart=${AUTO_DEVOPS_CHART:-gitlab/auto-deploy-app}
		auto_chart_name=$(basename $auto_chart)
		auto_chart_name=${auto_chart_name%.tgz}
	else
		auto_chart="chart"
		auto_chart_name="chart"
	fi

	helm init --client-only
	helm repo add gitlab https://charts.gitlab.io
	if [[ ! -d "$auto_chart" ]]; then
		helm fetch ${auto_chart} --untar
	fi
	if [ "$auto_chart_name" != "chart" ]; then
		mv ${auto_chart_name} chart
	fi

	helm dependency update chart/
	helm dependency build chart/
}

function ensure_namespace() {
	kubectl describe namespace "$KUBE_NAMESPACE" || kubectl create namespace "$KUBE_NAMESPACE"
}

function check_kube_domain() {
	if [ -z ${AUTO_DEVOPS_DOMAIN+x} ]; then
		echo "In order to deploy, AUTO_DEVOPS_DOMAIN must be set as a variable at the group or project level, or manually added in .gitlab-cy.yml"
		false
	else
		true
	fi
}

function check_domain_ip() {
	# Expect the `DOMAIN` is a wildcard.
	domain_ip=$(nslookup gitlab$DOMAIN 2>/dev/null | grep "Address 1:" | cut -d' ' -f3)
	if [ -z $domain_ip ]; then
		echo "There was a problem resolving the IP of 'gitlab$DOMAIN'. Be sure you have configured a DNS entry."
		false
	else
		export DOMAIN_IP=$domain_ip
		echo "Found IP for gitlab$DOMAIN: $DOMAIN_IP"
		true
	fi
}

function install_tiller() {
	echo "Checking Tiller..."
	helm init --upgrade --service-account tiller
	kubectl rollout status -n "$TILLER_NAMESPACE" -w "deployment/tiller-deploy"
	if ! helm version --debug; then
		echo "Failed to init Tiller."
		return 1
	fi
	echo ""
}

function create_secret() {
	kubectl create secret -n "$KUBE_NAMESPACE" \
		docker-registry gitlab-registry-docker \
		--docker-server="$CI_REGISTRY" \
		--docker-username="$CI_REGISTRY_USER" \
		--docker-password="$CI_REGISTRY_PASSWORD" \
		--docker-email="$GITLAB_USER_EMAIL" \
		-o yaml --dry-run | kubectl replace -n "$KUBE_NAMESPACE" --force -f -
}

function delete() {
	track="${1-stable}"
	name="$CI_ENVIRONMENT_SLUG"

	if [[ "$track" != "stable" ]]; then
		name="$name-$track"
	fi
	helm delete --purge "$name" || true
}

function cleanup() {
	kubectl get ingress,configmap,all -n "$KUBE_NAMESPACE" \
		-o jsonpath='{range .items[*]}{.kind}{" "}{.metadata.name}{"\n"}{end}' \
		| grep "CI_ENVIRONMENT_SLUG" \
		| xargs -n2 kubectl delete -n "$KUBE_NAMESPACE" \
		|| true
}

function terraform_up() {
	pushd ci/terraform/
	terraform apply -input=false -auto-approve -var environment=${CI_ENVIRONMENT_SLUG}
	export DOMAIN_IP=$(terraform output loadBalancerIP)
	popd
}

function terraform_down() {
	pushd ci/terraform
	terraform destroy -input=false -force -var environment=${CI_ENVIRONMENT_SLUG}
	popd
}

function terraform_init() {
	pushd ci/terraform
	echo ${GOOGLE_CLOUD_KEYFILE_JSON} > ${GOOGLE_APPLICATION_CREDENTIALS}
	# gcloud auth activate-service-account --key-file=${GOOGLE_APPLICATION_CREDENTIALS}
	# gcloud config set project $GOOGLE_PROJECT_ID
	terraform init -input=false \
		-backend-config="bucket=${GOOGLE_STORAGE_BUCKET}" \
		-backend-config="prefix=terraform/${CI_ENVIRONMENT_SLUG}"
	popd
}
