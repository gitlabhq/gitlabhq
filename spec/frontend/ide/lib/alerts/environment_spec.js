import { GlLink } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import Environments from '~/ide/lib/alerts/environments.vue';

describe('~/ide/lib/alerts/environment.vue', () => {
  let wrapper;

  beforeEach(() => {
    wrapper = mount(Environments);
  });

  it('shows a message regarding environments', () => {
    expect(wrapper.text()).toBe(
      "No deployments detected. Use environments to control your software's continuous deployment. Learn more about deployment jobs.",
    );
  });

  it('links to the help page on environments', () => {
    expect(wrapper.findComponent(GlLink).attributes('href')).toBe('/help/ci/environments/index.md');
  });
});
