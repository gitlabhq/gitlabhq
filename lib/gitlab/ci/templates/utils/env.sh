function propagate_env_vars() {
  CURRENT_ENV=$(printenv)

  for VAR_NAME; do
    echo $CURRENT_ENV | grep "${VAR_NAME}=" > /dev/null && echo "--env $VAR_NAME "
  done
}
