export default ({ adminState = null, customState = {} } = {}) => {
  const override = adminState !== null ? adminState.id !== customState.inheritFromId : false;

  return {
    override,
    adminState,
    customState,
  };
};
