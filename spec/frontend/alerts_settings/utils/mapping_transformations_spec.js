import {
  getMappingData,
  getPayloadFields,
  transformForSave,
} from '~/alerts_settings/utils/mapping_transformations';
import gitlabFieldsMock from '~/alerts_settings/components/mocks/gitlabFields.json';
import parsedMapping from '~/alerts_settings/components/mocks/parsedMapping.json';

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
      const alertFields = gitlabFieldsMock.slice(0, 3);
      const result = getMappingData(
        alertFields,
        getPayloadFields(parsedMapping.samplePayload.payloadAlerFields.nodes.slice(0, 3)),
        parsedMapping.storedMapping.nodes.slice(0, 3),
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
          mapping: 'alert_name',
          mappingFields: getPayloadFields([dashboardField, nameField]),
        },
      ];
      const result = transformForSave(mockMappingData);
      const { path, type, label } = nameField;
      expect(result).toEqual([{ fieldName, path, type, label }]);
    });

    it('should return empty array if no mapping provided', () => {
      const fieldName = 'title';
      const mockMappingData = [
        {
          name: fieldName,
          mapping: null,
          mappingFields: getPayloadFields([nameField, dashboardField]),
        },
      ];
      const result = transformForSave(mockMappingData);
      expect(result).toEqual([]);
    });
  });

  describe('getPayloadFields', () => {
    it('should add name field to each payload field', () => {
      const result = getPayloadFields([nameField, dashboardField]);
      expect(result).toEqual([
        { ...nameField, name: 'alert_name' },
        { ...dashboardField, name: 'alert_dashboardId' },
      ]);
    });
  });
});
