import { GlIcon, GlFormInput, GlDropdown, GlSearchBoxByType, GlDropdownItem } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import AlertMappingBuilder, { i18n } from '~/alerts_settings/components/alert_mapping_builder.vue';
import gitlabFields from '~/alerts_settings/components/mocks/gitlabFields.json';
import parsedMapping from '~/alerts_settings/components/mocks/parsedMapping.json';
import { capitalizeFirstCharacter } from '~/lib/utils/text_utility';
import * as transformationUtils from '~/alerts_settings/utils/mapping_transformations';

describe('AlertMappingBuilder', () => {
  let wrapper;

  function mountComponent() {
    wrapper = shallowMount(AlertMappingBuilder, {
      propsData: {
        parsedPayload: parsedMapping.samplePayload.payloadAlerFields.nodes,
        savedMapping: parsedMapping.storedMapping.nodes,
      },
    });
  }

  afterEach(() => {
    if (wrapper) {
      wrapper.destroy();
      wrapper = null;
    }
  });

  beforeEach(() => {
    mountComponent();
  });

  const findColumnInRow = (row, column) =>
    wrapper.findAll('.gl-display-table-row').at(row).findAll('.gl-display-table-cell ').at(column);

  it('renders column captions', () => {
    expect(findColumnInRow(0, 0).text()).toContain(i18n.columns.gitlabKeyTitle);
    expect(findColumnInRow(0, 2).text()).toContain(i18n.columns.payloadKeyTitle);
    expect(findColumnInRow(0, 3).text()).toContain(i18n.columns.fallbackKeyTitle);

    const fallbackColumnIcon = findColumnInRow(0, 3).find(GlIcon);
    expect(fallbackColumnIcon.exists()).toBe(true);
    expect(fallbackColumnIcon.attributes('name')).toBe('question');
    expect(fallbackColumnIcon.attributes('title')).toBe(i18n.fallbackTooltip);
  });

  it('renders disabled form input for each mapped field', () => {
    gitlabFields.forEach((field, index) => {
      const input = findColumnInRow(index + 1, 0).find(GlFormInput);
      const types = field.type.map((t) => capitalizeFirstCharacter(t.toLowerCase())).join(' or ');
      expect(input.attributes('value')).toBe(`${field.label} (${types})`);
      expect(input.attributes('disabled')).toBe('');
    });
  });

  it('renders right arrow next to each input', () => {
    gitlabFields.forEach((field, index) => {
      const arrow = findColumnInRow(index + 1, 1).find('.right-arrow');
      expect(arrow.exists()).toBe(true);
    });
  });

  it('renders mapping dropdown for each field', () => {
    gitlabFields.forEach(({ compatibleTypes }, index) => {
      const dropdown = findColumnInRow(index + 1, 2).find(GlDropdown);
      const searchBox = dropdown.findComponent(GlSearchBoxByType);
      const dropdownItems = dropdown.findAllComponents(GlDropdownItem);
      const { nodes } = parsedMapping.samplePayload.payloadAlerFields;
      const mappingOptions = nodes.filter(({ type }) => compatibleTypes.includes(type));

      expect(dropdown.exists()).toBe(true);
      expect(searchBox.exists()).toBe(true);
      expect(dropdownItems).toHaveLength(mappingOptions.length);
    });
  });

  it('renders fallback dropdown only for the fields that have fallback', () => {
    gitlabFields.forEach(({ compatibleTypes, numberOfFallbacks }, index) => {
      const dropdown = findColumnInRow(index + 1, 3).find(GlDropdown);
      expect(dropdown.exists()).toBe(Boolean(numberOfFallbacks));

      if (numberOfFallbacks) {
        const searchBox = dropdown.findComponent(GlSearchBoxByType);
        const dropdownItems = dropdown.findAllComponents(GlDropdownItem);
        const { nodes } = parsedMapping.samplePayload.payloadAlerFields;
        const mappingOptions = nodes.filter(({ type }) => compatibleTypes.includes(type));

        expect(searchBox.exists()).toBe(Boolean(numberOfFallbacks));
        expect(dropdownItems).toHaveLength(mappingOptions.length);
      }
    });
  });

  it('emits event with selected mapping', () => {
    const mappingToSave = { fieldName: 'TITLE', mapping: 'PARSED_TITLE' };
    jest.spyOn(transformationUtils, 'transformForSave').mockReturnValue(mappingToSave);
    const dropdown = findColumnInRow(1, 2).find(GlDropdown);
    const option = dropdown.find(GlDropdownItem);
    option.vm.$emit('click');
    expect(wrapper.emitted('onMappingUpdate')[0]).toEqual([mappingToSave]);
  });
});
