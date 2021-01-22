/**
 * Given data for GitLab alert fields, parsed payload fields data and previously stored mapping (if any)
 * creates an object in a form convenient to build UI && interact with it
 * @param {Object} gitlabFields  - structure describing GitLab alert fields
 * @param {Object} payloadFields - parsed from sample JSON sample alert fields
 * @param {Object} savedMapping  - GitLab fields to parsed fields mapping
 *
 * @return {Object} mapping data for UI mapping builder
 */
export const getMappingData = (gitlabFields, payloadFields, savedMapping) => {
  return gitlabFields.map((gitlabField) => {
    // find fields from payload that match gitlab alert field by type
    const mappingFields = payloadFields.filter(({ type }) =>
      gitlabField.compatibleTypes.includes(type),
    );

    // find the mapping that was previously stored
    const foundMapping = savedMapping.find(({ fieldName }) => fieldName === gitlabField.name);

    const { fallbackAlertPaths, payloadAlertPaths } = foundMapping || {};

    return {
      mapping: payloadAlertPaths,
      fallback: fallbackAlertPaths,
      searchTerm: '',
      fallbackSearchTerm: '',
      mappingFields,
      ...gitlabField,
    };
  });
};

/**
 * Based on mapping data configured by the user creates an object in a format suitable for save on BE
 * @param {Object} mappingData  - structure describing mapping between GitLab fields and parsed payload fields
 *
 * @return {Object} mapping data  to send to BE
 */
export const transformForSave = (mappingData) => {
  return mappingData.reduce((acc, field) => {
    const mapped = field.mappingFields.find(({ name }) => name === field.mapping);
    if (mapped) {
      const { path, type, label } = mapped;
      acc.push({
        fieldName: field.name,
        path,
        type,
        label,
      });
    }
    return acc;
  }, []);
};

/**
 * Adds `name` prop to each provided by BE parsed payload field
 * @param {Object} payload  - parsed sample payload
 *
 * @return {Object} same as input with an extra `name` property which basically serves as a key to make a match
 */
export const getPayloadFields = (payload) => {
  return payload.map((field) => ({ ...field, name: field.path.join('_') }));
};
