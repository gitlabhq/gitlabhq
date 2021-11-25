import { mount } from '@vue/test-utils';
import { GlAlert, GlButton } from '@gitlab/ui';
import NoGcpProjects from '~/google_cloud/components/errors/no_gcp_projects.vue';

describe('NoGcpProjects component', () => {
  let wrapper;

  const findAlert = () => wrapper.findComponent(GlAlert);
  const findButton = () => wrapper.findComponent(GlButton);

  beforeEach(() => {
    wrapper = mount(NoGcpProjects);
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('contains alert', () => {
    expect(findAlert().exists()).toBe(true);
  });

  it('contains relevant text', () => {
    expect(findAlert().props('title')).toBe(NoGcpProjects.i18n.title);
    expect(findAlert().text()).toContain(NoGcpProjects.i18n.description);
  });

  it('contains create gcp project button', () => {
    const button = findButton();
    expect(button.text()).toBe(NoGcpProjects.i18n.createLabel);
    expect(button.attributes('href')).toBe('https://console.cloud.google.com/projectcreate');
  });
});
