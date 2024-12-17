import { GlFormInput, GlCollapsibleListbox } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import HelpIcon from '~/vue_shared/components/help_icon/help_icon.vue';
import AlertMappingBuilder, { i18n } from '~/alerts_settings/components/alert_mapping_builder.vue';
import * as transformationUtils from '~/alerts_settings/utils/mapping_transformations';
import { capitalizeFirstCharacter } from '~/lib/utils/text_utility';
import alertFields from '../mocks/alert_fields.json';
import parsedMapping from '../mocks/parsed_mapping.json';

describe('AlertMappingBuilder', () => {
  let wrapper;

  function mountComponent() {
    wrapper = shallowMount(AlertMappingBuilder, {
      propsData: {
        parsedPayload: parsedMapping.payloadAlertFields,
        savedMapping: parsedMapping.payloadAttributeMappings,
        alertFields,
      },
      stubs: {
        HelpIcon,
      },
    });
  }

  beforeEach(() => {
    mountComponent();
  });

  const findColumnInRow = (row, column) =>
    wrapper.findAll('.gl-table-row').at(row).findAll('.gl-table-cell ').at(column);

  const getMappingOptions = (types) => {
    return parsedMapping.payloadAlertFields.filter(({ type }) => types.includes(type));
  };

  it('renders column captions', () => {
    expect(findColumnInRow(0, 0).text()).toContain(i18n.columns.gitlabKeyTitle);
    expect(findColumnInRow(0, 2).text()).toContain(i18n.columns.payloadKeyTitle);
    expect(findColumnInRow(0, 3).text()).toContain(i18n.columns.fallbackKeyTitle);

    const fallbackColumnIcon = findColumnInRow(0, 3).findComponent(HelpIcon);
    expect(fallbackColumnIcon.exists()).toBe(true);
    expect(fallbackColumnIcon.attributes('name')).toBe('question-o');
    expect(fallbackColumnIcon.attributes('title')).toBe(i18n.fallbackTooltip);
  });

  it('renders disabled form input for each mapped field', () => {
    alertFields.forEach((field, index) => {
      const input = findColumnInRow(index + 1, 0).findComponent(GlFormInput);
      const types = field.types.map((t) => capitalizeFirstCharacter(t.toLowerCase())).join(' or ');
      expect(input.attributes('value')).toBe(`${field.label} (${types})`);
      expect(input.attributes('disabled')).toBeDefined();
    });
  });

  it('renders right arrow next to each input', () => {
    alertFields.forEach((field, index) => {
      const arrow = findColumnInRow(index + 1, 1).find('.right-arrow');
      expect(arrow.exists()).toBe(true);
    });
  });

  it('renders mapping listbox for each field', () => {
    alertFields.forEach(({ types }, index) => {
      const listbox = findColumnInRow(index + 1, 2).findComponent(GlCollapsibleListbox);
      const mappingOptions = getMappingOptions(types);

      expect(listbox.props('items')).toHaveLength(mappingOptions.length);
    });
  });

  it('renders fallback listbox only for the fields that have fallback', () => {
    alertFields.forEach(({ types, numberOfFallbacks }, index) => {
      const listbox = findColumnInRow(index + 1, 3).findComponent(GlCollapsibleListbox);
      expect(listbox.exists()).toBe(Boolean(numberOfFallbacks));

      if (numberOfFallbacks) {
        const mappingOptions = getMappingOptions(types);
        expect(listbox.props('items')).toHaveLength(mappingOptions.length);
      }
    });
  });

  it('emits event with selected mapping', () => {
    const mappingToSave = { fieldName: 'TITLE', mapping: 'PARSED_TITLE' };
    jest.spyOn(transformationUtils, 'transformForSave').mockReturnValue(mappingToSave);
    const listbox = findColumnInRow(1, 2).findComponent(GlCollapsibleListbox);
    listbox.vm.$emit('select', 'Dashboard Id');
    expect(wrapper.emitted('onMappingUpdate')[0]).toEqual([mappingToSave]);
  });
});
