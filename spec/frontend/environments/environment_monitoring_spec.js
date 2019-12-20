import { shallowMount } from '@vue/test-utils';
import MonitoringComponent from '~/environments/components/environment_monitoring.vue';
import Icon from '~/vue_shared/components/icon.vue';

describe('Monitoring Component', () => {
  let wrapper;

  const monitoringUrl = 'https://gitlab.com';

  const createWrapper = () => {
    wrapper = shallowMount(MonitoringComponent, {
      sync: false,
      attachToDocument: true,
      propsData: {
        monitoringUrl,
      },
    });
  };

  const findIcons = () => wrapper.findAll(Icon);
  const findIconsByName = name => findIcons().filter(icon => icon.props('name') === name);

  beforeEach(() => {
    createWrapper();
  });

  describe('computed', () => {
    it('title', () => {
      expect(wrapper.vm.title).toBe('Monitoring');
    });
  });

  it('should render a link to environment monitoring page', () => {
    expect(wrapper.attributes('href')).toEqual(monitoringUrl);
    expect(findIconsByName('chart').length).toBe(1);
    expect(wrapper.attributes('data-original-title')).toBe('Monitoring');
    expect(wrapper.attributes('aria-label')).toBe('Monitoring');
  });
});
