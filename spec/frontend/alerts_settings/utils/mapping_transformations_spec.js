import {
  getMappingData,
  setFieldsLabels,
  transformForSave,
} from '~/alerts_settings/utils/mapping_transformations';
import alertFields from '../mocks/alert_fields.json';
import parsedMapping from '../mocks/parsed_mapping.json';

describe('Mapping Transformation Utilities', () => {
  const nameField = {
    label: 'Name',
    path: ['alert', 'name'],
    type: 'STRING',
  };
  const dashboardField = {
    label: 'Dashboard Id',
    path: ['alert', 'dashboardId'],
    type: 'STRING',
  };

  describe('getMappingData', () => {
    it('should return mapping data', () => {
      const result = getMappingData(
        alertFields,
        parsedMapping.payloadAlertFields.slice(0, 3),
        parsedMapping.payloadAttributeMappings.slice(0, 3),
      );

      result.forEach((data, index) => {
        expect(data).toEqual(
          expect.objectContaining({
            ...alertFields[index],
            searchTerm: '',
            fallbackSearchTerm: '',
          }),
        );
      });
    });
  });

  describe('transformForSave', () => {
    it('should transform mapped data for save', () => {
      const fieldName = 'title';
      const mockMappingData = [
        {
          name: fieldName,
          mapping: ['alert', 'name'],
          mappingFields: [dashboardField, nameField],
        },
      ];
      const result = transformForSave(mockMappingData);
      const { path, type, label } = nameField;
      expect(result).toEqual([
        { fieldName: fieldName.toUpperCase(), path, type: type.toUpperCase(), label },
      ]);
    });

    it('should return empty array if no mapping provided', () => {
      const fieldName = 'title';
      const mockMappingData = [
        {
          name: fieldName,
          mapping: null,
          mappingFields: [nameField, dashboardField],
        },
      ];
      const result = transformForSave(mockMappingData);
      expect(result).toEqual([]);
    });
  });

  describe('setFieldsLabels', () => {
    const nonNestedFields = [{ label: 'title' }];
    const nonNestedFieldsResult = { displayLabel: 'Title', tooltip: undefined };

    const nestedFields = [
      {
        label: 'field/subfield',
      },
    ];
    const nestedFieldsResult = { displayLabel: '...Subfield', tooltip: 'field.subfield' };

    const nestedArrayFields = [
      {
        label: 'fields[1]/subfield',
      },
    ];

    const nestedArrayFieldsResult = { displayLabel: '...Subfield', tooltip: 'fields[1].subfield' };

    it.each`
      type                     | fields               | result
      ${'not nested field'}    | ${nonNestedFields}   | ${nonNestedFieldsResult}
      ${'nested field'}        | ${nestedFields}      | ${nestedFieldsResult}
      ${'nested inside array'} | ${nestedArrayFields} | ${nestedArrayFieldsResult}
    `('adds correct displayLabel and tooltip for $type', ({ fields, result }) => {
      expect(setFieldsLabels(fields)[0]).toMatchObject(result);
    });
  });
});
