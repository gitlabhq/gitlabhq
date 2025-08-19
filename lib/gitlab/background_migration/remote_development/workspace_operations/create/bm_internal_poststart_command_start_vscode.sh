#!/bin/sh

echo "$(date -Iseconds): ----------------------------------------"
echo "$(date -Iseconds): Starting GitLab Fork of VS Code server in background with output written to ${GL_WORKSPACE_LOGS_DIR}/start-vscode.log..."

# Define log file path
LOG_FILE="${GL_WORKSPACE_LOGS_DIR}/start-vscode.log"

mkdir -p "$(dirname "${LOG_FILE}")"

echo "$(date -Iseconds): VS Code initialization started"

# Start logging
exec 1>>"${LOG_FILE}" 2>&1

# # This script initilizes the tools injected into the workspace on startup.
# #
# # It uses the following environment variables
# # $GL_TOOLS_DIR - directory where the tools are copied.
# # $GL_VSCODE_LOG_LEVEL - log level for the server. defaults to "info".
# # $GL_VSCODE_PORT - port on which the server is exposed. defaults to "60001".
# # $GL_VSCODE_IGNORE_VERSION_MISMATCH - if set to true, the server works even when server and WebIDE versions do not match.
# # $GL_VSCODE_ENABLE_MARKETPLACE - if set to true, set configuration to enable marketplace.
# # $GL_VSCODE_EXTENSION_MARKETPLACE_SERVICE_URL - service url for the extensions marketplace.
# # $GL_VSCODE_EXTENSION_MARKETPLACE_ITEM_URL - item url for the extensions marketplace.
# # $GL_VSCODE_EXTENSION_MARKETPLACE_RESOURCE_URL_TEMPLATE - resource url template for the extensions marketplace.
# # $GITLAB_WORKFLOW_TOKEN - a giltab personal access token to configure the gitlab vscode extension.
# # $GITLAB_WORKFLOW_TOKEN_FILE - the contents of this file populate GITLAB_WORKFLOW_TOKEN if it is not set.

if [ -z "${GL_TOOLS_DIR}" ]; then
	echo "$(date -Iseconds): \$GL_TOOLS_DIR is not set"
	exit 1
fi

if [ -z "${GL_VSCODE_LOG_LEVEL}" ]; then
	GL_VSCODE_LOG_LEVEL="info"
	echo "$(date -Iseconds): Setting default GL_VSCODE_LOG_LEVEL=${GL_VSCODE_LOG_LEVEL}"
fi

if [ -z "${GL_VSCODE_PORT}" ]; then
	GL_VSCODE_PORT="60001"
	echo "$(date -Iseconds): Setting default GL_VSCODE_PORT=${GL_VSCODE_PORT}"
fi

if [ -z "${GL_VSCODE_EXTENSION_MARKETPLACE_SERVICE_URL}" ]; then
	GL_VSCODE_EXTENSION_MARKETPLACE_SERVICE_URL="https://open-vsx.org/vscode/gallery"
	echo "$(date -Iseconds): Setting default GL_VSCODE_EXTENSION_MARKETPLACE_SERVICE_URL=${GL_VSCODE_EXTENSION_MARKETPLACE_SERVICE_URL}"
fi

if [ -z "${GL_VSCODE_EXTENSION_MARKETPLACE_ITEM_URL}" ]; then
	GL_VSCODE_EXTENSION_MARKETPLACE_ITEM_URL="https://open-vsx.org/vscode/item"
	echo "$(date -Iseconds): Setting default GL_VSCODE_EXTENSION_MARKETPLACE_ITEM_URL=${GL_VSCODE_EXTENSION_MARKETPLACE_ITEM_URL}"
fi

if [ -z "${GL_VSCODE_EXTENSION_MARKETPLACE_RESOURCE_URL_TEMPLATE}" ]; then
	GL_VSCODE_EXTENSION_MARKETPLACE_RESOURCE_URL_TEMPLATE="https://open-vsx.org/api/{publisher}/{name}/{version}/file/{path}"
	echo "$(date -Iseconds): Setting default GL_VSCODE_EXTENSION_MARKETPLACE_RESOURCE_URL_TEMPLATE=${GL_VSCODE_EXTENSION_MARKETPLACE_RESOURCE_URL_TEMPLATE}"
fi

PRODUCT_JSON_FILE="${GL_TOOLS_DIR}/vscode-reh-web/product.json"

if [ "$GL_VSCODE_IGNORE_VERSION_MISMATCH" = true ]; then
	# TODO: remove this section once issue is fixed - https://gitlab.com/gitlab-org/gitlab/-/issues/373669
	# remove "commit" key from product.json to avoid client-server mismatch
	# TODO: remove this once we are not worried about version mismatch
	# https://gitlab.com/gitlab-org/gitlab/-/issues/373669
	echo "$(date -Iseconds): Ignoring VS Code client-server version mismatch"
	sed -i.bak '/"commit"/d' "${PRODUCT_JSON_FILE}" && rm "${PRODUCT_JSON_FILE}.bak"
	echo "$(date -Iseconds): Removed 'commit' key from ${PRODUCT_JSON_FILE}"
fi

if [ "$GL_VSCODE_ENABLE_MARKETPLACE" = true ]; then
	EXTENSIONS_GALLERY_KEY="{\\n\\t\"extensionsGallery\": {\\n\\t\\t\"serviceUrl\": \"${GL_VSCODE_EXTENSION_MARKETPLACE_SERVICE_URL}\",\\n\\t\\t\"itemUrl\": \"${GL_VSCODE_EXTENSION_MARKETPLACE_ITEM_URL}\",\\n\\t\\t\"resourceUrlTemplate\": \"${GL_VSCODE_EXTENSION_MARKETPLACE_RESOURCE_URL_TEMPLATE}\"\\n\\t},"
	echo "$(date -Iseconds): '${EXTENSIONS_GALLERY_KEY}' in '${PRODUCT_JSON_FILE}' at the beginning of the file"
	sed -i.bak "1s|.*|$EXTENSIONS_GALLERY_KEY|" "${PRODUCT_JSON_FILE}" && rm "${PRODUCT_JSON_FILE}.bak"
	echo "$(date -Iseconds): Extensions gallery configuration added"
fi

echo "$(date -Iseconds): Contents of ${PRODUCT_JSON_FILE} are: "
cat "${PRODUCT_JSON_FILE}"
echo

GL_VSCODE_HOST="0.0.0.0"

echo "$(date -Iseconds): Starting server for the editor with:"
echo "$(date -Iseconds): - Host: ${GL_VSCODE_HOST}"
echo "$(date -Iseconds): - Port: ${GL_VSCODE_PORT}"
echo "$(date -Iseconds): - Log level: ${GL_VSCODE_LOG_LEVEL}"
echo "$(date -Iseconds): - Without connection token: yes"
echo "$(date -Iseconds): - Workspace trust disabled: yes"

# The server execution is backgrounded to allow for the rest of the internal init scripts to execute.
"${GL_TOOLS_DIR}/vscode-reh-web/bin/gitlab-webide-server" \
	--host "${GL_VSCODE_HOST}" \
	--port "${GL_VSCODE_PORT}" \
	--log "${GL_VSCODE_LOG_LEVEL}" \
	--without-connection-token \
	--disable-workspace-trust &

echo "$(date -Iseconds): Finished starting GitLab Fork of VS Code server in background"
echo "$(date -Iseconds): ----------------------------------------"
