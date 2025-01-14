import { GlIcon } from '@gitlab/ui';
import CiIcon from '~/vue_shared/components/ci_icon/ci_icon.vue';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import DeploymentStatusBadge from '~/environments/components/deployment_status_badge.vue';

describe('~/environments/components/deployment_status_badge.vue', () => {
  let wrapper;

  const createWrapper = ({ propsData = {} } = {}) =>
    mountExtended(DeploymentStatusBadge, {
      propsData,
      stubs: {
        CiIcon,
      },
    });

  const findCiIcon = () => wrapper.findComponent(CiIcon);
  const findIcon = () => wrapper.findComponent(GlIcon);

  describe.each`
    status        | text           | variant      | icon
    ${'created'}  | ${'Created'}   | ${'neutral'} | ${'status_created_borderless'}
    ${'running'}  | ${'Running'}   | ${'info'}    | ${'status_running_borderless'}
    ${'success'}  | ${'Success'}   | ${'success'} | ${'status_success_borderless'}
    ${'failed'}   | ${'Failed'}    | ${'danger'}  | ${'status_failed_borderless'}
    ${'canceled'} | ${'Cancelled'} | ${'neutral'} | ${'status_canceled_borderless'}
    ${'skipped'}  | ${'Skipped'}   | ${'neutral'} | ${'status_skipped_borderless'}
    ${'blocked'}  | ${'Waiting'}   | ${'neutral'} | ${'status_manual_borderless'}
  `('$status', ({ status, text, variant, icon }) => {
    beforeEach(() => {
      wrapper = createWrapper({ propsData: { status } });
    });

    it(`sets the text to ${text}`, () => {
      expect(findCiIcon().text()).toBe(text);
    });

    it(`sets the variant to ${variant}`, () => {
      expect(findCiIcon().attributes('variant')).toBe(variant);
    });

    it(`sets the icon to ${icon}`, () => {
      expect(findIcon().props('name')).toBe(icon);
    });
  });

  it('passes an href to the GlBadge', () => {
    const href = 'http://example.com';
    wrapper = createWrapper({ propsData: { status: 'created', href } });
    const badge = wrapper.findComponent(CiIcon);

    expect(badge.attributes('href')).toBe(href);
  });
});
