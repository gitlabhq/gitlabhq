import { shallowMount } from '@vue/test-utils';
import { GlIcon } from '@gitlab/ui';
import SeverityToken from '~/sidebar/components/severity/severity.vue';
import { INCIDENT_SEVERITY } from '~/sidebar/components/severity/constants';

describe('SeverityToken', () => {
  let wrapper;

  function createComponent(props) {
    wrapper = shallowMount(SeverityToken, {
      propsData: {
        ...props,
      },
    });
  }

  afterEach(() => {
    if (wrapper) {
      wrapper.destroy();
      wrapper = null;
    }
  });

  const findIcon = () => wrapper.find(GlIcon);

  it('renders severity token for each severity type', () => {
    Object.values(INCIDENT_SEVERITY).forEach(severity => {
      createComponent({ severity });
      expect(findIcon().classes()).toContain(`icon-${severity.icon}`);
      expect(findIcon().attributes('name')).toBe(`severity-${severity.icon}`);
      expect(wrapper.text()).toBe(severity.label);
    });
  });

  it('renders only icon when `iconOnly` prop is set to `true`', () => {
    const severity = INCIDENT_SEVERITY.CRITICAL;
    createComponent({ severity, iconOnly: true });
    expect(findIcon().classes()).toContain(`icon-${severity.icon}`);
    expect(findIcon().attributes('name')).toBe(`severity-${severity.icon}`);
    expect(wrapper.text()).toBe('');
  });

  describe('icon size', () => {
    it('renders the icon in default size when other is not specified', () => {
      const severity = INCIDENT_SEVERITY.HIGH;
      createComponent({ severity });
      expect(findIcon().attributes('size')).toBe('12');
    });

    it('renders the icon in provided size', () => {
      const severity = INCIDENT_SEVERITY.HIGH;
      const iconSize = 14;
      createComponent({ severity, iconSize });
      expect(findIcon().attributes('size')).toBe(`${iconSize}`);
    });
  });
});
