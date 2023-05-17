import { mount } from '@vue/test-utils';
import { GlFormCheckbox } from '@gitlab/ui';
import AdvancedSettingsPanel from '~/import_entities/import_projects/components/advanced_settings.vue';

describe('Import Advanced Settings', () => {
  let wrapper;
  const OPTIONAL_STAGES = [
    { name: 'stage1', label: 'Stage 1', selected: false },
    { name: 'stage2', label: 'Stage 2', details: 'Extra details', selected: false },
  ];

  const createComponent = () => {
    wrapper = mount(AdvancedSettingsPanel, {
      propsData: {
        stages: OPTIONAL_STAGES,
        value: {
          stage1: false,
          stage2: false,
        },
      },
    });
  };

  beforeEach(() => {
    createComponent();
  });

  it('renders GLFormCheckbox for each optional stage', () => {
    expect(wrapper.findAllComponents(GlFormCheckbox)).toHaveLength(OPTIONAL_STAGES.length);
  });

  it('renders label for each optional stage', () => {
    wrapper.findAllComponents(GlFormCheckbox).wrappers.forEach((w, idx) => {
      expect(w.text()).toContain(OPTIONAL_STAGES[idx].label);
    });
  });

  it('renders details for stage with details', () => {
    expect(wrapper.findAllComponents(GlFormCheckbox).at(1).text()).toContain(
      OPTIONAL_STAGES[1].details,
    );
  });

  it('emits new stages selection state when checkbox is changed', () => {
    const firstCheckbox = wrapper.findComponent(GlFormCheckbox);

    firstCheckbox.vm.$emit('change', true);

    expect(wrapper.emitted('input')[0]).toStrictEqual([
      {
        stage1: true,
        stage2: false,
      },
    ]);
  });
});
