import { mount } from '@vue/test-utils';
import { GlAlert, GlFormCheckbox } from '@gitlab/ui';
import AdvancedSettings from '~/import_entities/import_projects/components/advanced_settings.vue';

describe('Import Advanced Settings', () => {
  let wrapper;

  const OPTIONAL_STAGES = [
    { name: 'stage1', label: 'Stage 1', selected: false },
    { name: 'stage2', label: 'Stage 2', details: 'Extra details', selected: false },
  ];

  const createComponent = ({ provide } = {}) => {
    wrapper = mount(AdvancedSettings, {
      propsData: {
        stages: OPTIONAL_STAGES,
        value: {
          stage1: false,
          stage2: false,
        },
      },
      provide: {
        isFineGrainedToken: false,
        ...provide,
      },
    });
  };

  const findAlert = () => wrapper.findComponent(GlAlert);
  const findAllCheckboxes = () => wrapper.findAllComponents(GlFormCheckbox);

  beforeEach(() => {
    createComponent();
  });

  it('renders a warning message', () => {
    expect(findAlert().text()).toMatchInterpolatedText(
      'The more information you select, the longer it will take to import. To import collaborators, or if your project has Git LFS files, you must use a classic personal access token with read:org scope. Learn more.',
    );
  });

  it('renders GLFormCheckbox for each optional stage', () => {
    expect(findAllCheckboxes()).toHaveLength(OPTIONAL_STAGES.length);
  });

  it('renders label for each optional stage', () => {
    findAllCheckboxes().wrappers.forEach((w, idx) => {
      expect(w.text()).toContain(OPTIONAL_STAGES[idx].label);
    });
  });

  it('renders details for stage with details', () => {
    expect(findAllCheckboxes().at(1).text()).toContain(OPTIONAL_STAGES[1].details);
  });

  it('emits new stages selection state when checkbox is changed', () => {
    const firstCheckbox = findAllCheckboxes().at(0);

    firstCheckbox.vm.$emit('change', true);

    expect(wrapper.emitted('input')[0]).toStrictEqual([
      {
        stage1: true,
        stage2: false,
      },
    ]);
  });
});
