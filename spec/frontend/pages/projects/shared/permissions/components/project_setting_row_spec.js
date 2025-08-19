import { nextTick } from 'vue';
import { GlIcon, GlFormGroup, GlSprintf } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import projectSettingRow from '~/pages/projects/shared/permissions/components/project_setting_row.vue';

describe('Project Setting Row', () => {
  let wrapper;

  const findLabel = () => wrapper.findByTestId('project-settings-row-label');
  const findHelpText = () => wrapper.findByTestId('project-settings-row-help-text');

  const createComponent = (customProps = {}) => {
    return shallowMountExtended(projectSettingRow, {
      propsData: {
        ...customProps,
      },
      stubs: { GlFormGroup, GlSprintf },
    });
  };

  beforeEach(() => {
    wrapper = createComponent();
  });

  it('should show the label if it is set', async () => {
    wrapper = createComponent({ label: 'Test label' });

    await nextTick();
    expect(findLabel().text()).toEqual('Test label');
  });

  it('should hide the label if it is not set', () => {
    expect(findLabel().exists()).toBe(false);
  });

  it('should apply gl-text-disabled class to label when locked', async () => {
    wrapper = createComponent({ label: 'Test label', locked: true });

    await nextTick();
    expect(findLabel().classes()).toContain('gl-text-disabled');
  });

  it('should render default slot content', () => {
    wrapper = shallowMountExtended(projectSettingRow, {
      slots: {
        'label-icon': GlIcon,
      },
      stubs: { GlFormGroup },
    });
    expect(wrapper.findComponent(GlIcon).exists()).toBe(true);
  });

  it('should show the help icon with the correct help path if it is set', async () => {
    wrapper = createComponent({ label: 'Test label', helpPath: '/123' });

    await nextTick();
    const link = wrapper.find('a');

    expect(link.exists()).toBe(true);
    expect(link.attributes().href).toEqual('/123');
  });

  it('should hide the help icon if no help path is set', async () => {
    wrapper = createComponent({ label: 'Test label' });

    await nextTick();
    expect(wrapper.find('a').exists()).toBe(false);
  });

  it('should show the help text if it is set', async () => {
    wrapper = createComponent({ helpText: 'Test text' });

    await nextTick();
    expect(findHelpText().text()).toEqual('Test text');
  });

  it('should hide the help text if it is set', () => {
    expect(findHelpText().exists()).toBe(false);
  });

  describe('slot content', () => {
    beforeEach(() => {
      wrapper = shallowMountExtended(projectSettingRow, {
        slots: {
          default: '<div data-testid="slot-content">Slot Content</div>',
        },
        stubs: { GlFormGroup },
      });
    });

    it('should render slot content in the template', () => {
      expect(wrapper.findByTestId('slot-content').exists()).toBe(true);
    });
  });
});
