import { GlBadge } from '@gitlab/ui';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import { s__ } from '~/locale';
import DeploymentStatusBadge from '~/environments/components/deployment_status_badge.vue';

describe('~/environments/components/deployment_status_badge.vue', () => {
  let wrapper;

  const createWrapper = ({ propsData = {} } = {}) =>
    mountExtended(DeploymentStatusBadge, {
      propsData,
    });

  describe.each`
    status        | text                           | variant      | icon
    ${'created'}  | ${s__('Deployment|Created')}   | ${'neutral'} | ${'status_created'}
    ${'running'}  | ${s__('Deployment|Running')}   | ${'info'}    | ${'status_running'}
    ${'success'}  | ${s__('Deployment|Success')}   | ${'success'} | ${'status_success'}
    ${'failed'}   | ${s__('Deployment|Failed')}    | ${'danger'}  | ${'status_failed'}
    ${'canceled'} | ${s__('Deployment|Cancelled')} | ${'neutral'} | ${'status_canceled'}
    ${'skipped'}  | ${s__('Deployment|Skipped')}   | ${'neutral'} | ${'status_skipped'}
    ${'blocked'}  | ${s__('Deployment|Waiting')}   | ${'neutral'} | ${'status_manual'}
  `('$status', ({ status, text, variant, icon }) => {
    let badge;

    beforeEach(() => {
      wrapper = createWrapper({ propsData: { status } });
      badge = wrapper.findComponent(GlBadge);
    });

    it(`sets the text to ${text}`, () => {
      expect(wrapper.text()).toBe(text);
    });

    it(`sets the variant to ${variant}`, () => {
      expect(badge.props('variant')).toBe(variant);
    });
    it(`sets the icon to ${icon}`, () => {
      expect(badge.props('icon')).toBe(icon);
    });
  });

  it('passes an href to the GlBadge', () => {
    const href = 'http://example.com';
    wrapper = createWrapper({ propsData: { status: 'created', href } });
    const badge = wrapper.findComponent(GlBadge);

    expect(badge.attributes('href')).toBe(href);
  });
});
