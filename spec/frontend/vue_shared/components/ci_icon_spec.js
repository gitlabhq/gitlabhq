import { GlIcon } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import ciIcon from '~/vue_shared/components/ci_icon.vue';

describe('CI Icon component', () => {
  let wrapper;

  const findIconWrapper = () => wrapper.find('[data-testid="ci-icon-wrapper"]');

  it('should render a span element with an svg', () => {
    wrapper = shallowMount(ciIcon, {
      propsData: {
        status: {
          icon: 'status_success',
        },
      },
    });

    expect(wrapper.find('span').exists()).toBe(true);
    expect(wrapper.findComponent(GlIcon).exists()).toBe(true);
  });

  describe('active icons', () => {
    it.each`
      isActive | cssClass
      ${true}  | ${'active'}
      ${false} | ${'active'}
    `('active should be $isActive', ({ isActive, cssClass }) => {
      wrapper = shallowMount(ciIcon, {
        propsData: {
          status: {
            icon: 'status_success',
          },
          isActive,
        },
      });

      if (isActive) {
        expect(findIconWrapper().classes()).toContain(cssClass);
      } else {
        expect(findIconWrapper().classes()).not.toContain(cssClass);
      }
    });
  });

  describe('interactive icons', () => {
    it.each`
      isInteractive | cssClass
      ${true}       | ${'interactive'}
      ${false}      | ${'interactive'}
    `('interactive should be $isInteractive', ({ isInteractive, cssClass }) => {
      wrapper = shallowMount(ciIcon, {
        propsData: {
          status: {
            icon: 'status_success',
          },
          isInteractive,
        },
      });

      if (isInteractive) {
        expect(findIconWrapper().classes()).toContain(cssClass);
      } else {
        expect(findIconWrapper().classes()).not.toContain(cssClass);
      }
    });
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
