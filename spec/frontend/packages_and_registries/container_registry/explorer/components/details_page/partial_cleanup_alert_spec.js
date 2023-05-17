import { GlAlert, GlSprintf } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import component from '~/packages_and_registries/container_registry/explorer/components/details_page/partial_cleanup_alert.vue';
import {
  DELETE_ALERT_TITLE,
  DELETE_ALERT_LINK_TEXT,
} from '~/packages_and_registries/container_registry/explorer/constants';

describe('Partial Cleanup alert', () => {
  let wrapper;

  const findAlert = () => wrapper.findComponent(GlAlert);
  const findRunLink = () => wrapper.find('[data-testid="run-link"');
  const findHelpLink = () => wrapper.find('[data-testid="help-link"');

  const mountComponent = () => {
    wrapper = shallowMount(component, {
      stubs: { GlSprintf },
      propsData: {
        runCleanupPoliciesHelpPagePath: 'foo',
        cleanupPoliciesHelpPagePath: 'bar',
      },
    });
  };

  it(`gl-alert has the correct properties`, () => {
    mountComponent();

    expect(findAlert().props()).toMatchObject({
      title: DELETE_ALERT_TITLE,
      variant: 'warning',
    });
  });

  it('has the right text', () => {
    mountComponent();

    expect(wrapper.text()).toMatchInterpolatedText(DELETE_ALERT_LINK_TEXT);
  });

  it('contains run link', () => {
    mountComponent();

    const link = findRunLink();
    expect(link.exists()).toBe(true);
    expect(link.attributes()).toMatchObject({
      href: 'foo',
      target: '_blank',
    });
  });

  it('contains help link', () => {
    mountComponent();

    const link = findHelpLink();
    expect(link.exists()).toBe(true);
    expect(link.attributes()).toMatchObject({
      href: 'bar',
      target: '_blank',
    });
  });

  it('GlAlert dismiss event triggers a dismiss event', () => {
    mountComponent();

    findAlert().vm.$emit('dismiss');
    expect(wrapper.emitted('dismiss')).toEqual([[]]);
  });
});
