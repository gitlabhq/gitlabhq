import { isEqual } from 'lodash';
import { capitalizeFirstCharacter } from '~/lib/utils/text_utility';

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
      gitlabField.types.includes(type.toLowerCase()),
    );

    // find the mapping that was previously stored
    const foundMapping = savedMapping.find(
      ({ fieldName }) => fieldName.toLowerCase() === gitlabField.name,
    );
    const { path: mapping, fallbackPath: fallback } = foundMapping || {};

    return {
      mapping,
      fallback,
      searchTerm: '',
      fallbackSearchTerm: '',
      mappingFields,
      ...gitlabField,
    };
  });
};

export const setFieldsLabels = (fields) => {
  return fields.map((field) => {
    const { label } = field;
    let displayLabel;
    let tooltip;
    const labels = label.split('/');
    if (labels.length > 1) {
      tooltip = labels.join('.');
      displayLabel = `...${capitalizeFirstCharacter(labels.pop())}`;
    } else {
      displayLabel = capitalizeFirstCharacter(label);
    }

    return {
      ...field,
      displayLabel,
      tooltip,
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
    const mapped = field.mappingFields.find(({ path }) => isEqual(path, field.mapping));
    if (mapped) {
      const { path, type, label } = mapped;
      acc.push({
        fieldName: field.name.toUpperCase(),
        path,
        type: type.toUpperCase(),
        label,
      });
    }
    return acc;
  }, []);
};
