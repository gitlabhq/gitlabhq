import { GlIcon } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import ciIcon from '~/vue_shared/components/ci_icon.vue';

describe('CI Icon component', () => {
  let wrapper;

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  it('should render a span element with an svg', () => {
    wrapper = shallowMount(ciIcon, {
      propsData: {
        status: {
          icon: 'status_success',
        },
      },
    });

    expect(wrapper.find('span').exists()).toBe(true);
    expect(wrapper.find(GlIcon).exists()).toBe(true);
  });

  describe('rendering a status', () => {
    it.each`
      icon                 | group         | cssClass
      ${'status_success'}  | ${'success'}  | ${'ci-status-icon-success'}
      ${'status_failed'}   | ${'failed'}   | ${'ci-status-icon-failed'}
      ${'status_warning'}  | ${'warning'}  | ${'ci-status-icon-warning'}
      ${'status_pending'}  | ${'pending'}  | ${'ci-status-icon-pending'}
      ${'status_running'}  | ${'running'}  | ${'ci-status-icon-running'}
      ${'status_created'}  | ${'created'}  | ${'ci-status-icon-created'}
      ${'status_skipped'}  | ${'skipped'}  | ${'ci-status-icon-skipped'}
      ${'status_canceled'} | ${'canceled'} | ${'ci-status-icon-canceled'}
      ${'status_manual'}   | ${'manual'}   | ${'ci-status-icon-manual'}
    `('should render a $group status', ({ icon, group, cssClass }) => {
      wrapper = shallowMount(ciIcon, {
        propsData: {
          status: {
            icon,
            group,
          },
        },
      });

      expect(wrapper.classes()).toContain(cssClass);
    });
  });
});
