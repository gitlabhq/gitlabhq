import { GlIcon } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import CiIcon from '~/vue_shared/components/ci_icon/ci_icon.vue';

const mockStatus = {
  group: 'success',
  icon: 'status_success',
  text: 'Success',
};

describe('CI Icon component', () => {
  let wrapper;

  const createComponent = ({ props = {} } = {}) => {
    wrapper = shallowMount(CiIcon, {
      propsData: {
        status: mockStatus,
        ...props,
      },
    });
  };

  const findIcon = () => wrapper.findComponent(GlIcon);

  it('should render a span element and an icon', () => {
    createComponent();

    expect(findIcon().exists()).toBe(true);
  });

  describe.each`
    showStatusText | showTooltip | expectedText | expectedTooltip
    ${true}        | ${true}     | ${'Success'} | ${undefined}
    ${true}        | ${false}    | ${'Success'} | ${undefined}
    ${false}       | ${true}     | ${''}        | ${'Success'}
    ${false}       | ${false}    | ${''}        | ${undefined}
  `(
    'when showStatusText is %{showStatusText} and showTooltip is %{showTooltip}',
    ({ showStatusText, showTooltip, expectedText, expectedTooltip }) => {
      beforeEach(() => {
        createComponent({
          props: {
            showStatusText,
            showTooltip,
          },
        });
      });

      it(`aria-label is set`, () => {
        expect(wrapper.attributes('aria-label')).toBe('Status: Success');
      });

      it(`text shown is ${expectedText}`, () => {
        expect(wrapper.text()).toBe(expectedText);
      });

      it(`tooltip shown is ${expectedTooltip}`, () => {
        expect(wrapper.attributes('title')).toBe(expectedTooltip);
      });
    },
  );

  describe('when appearing as a link', () => {
    it('shows a GraphQL path', () => {
      createComponent({
        props: {
          status: {
            ...mockStatus,
            detailsPath: '/path',
          },
          useLink: true,
        },
      });

      expect(wrapper.attributes('href')).toBe('/path');
    });

    it('shows a REST API path', () => {
      createComponent({
        props: {
          status: {
            ...mockStatus,
            details_path: '/path',
          },
          useLink: true,
        },
      });

      expect(wrapper.attributes('href')).toBe('/path');
    });

    it('shows no path', () => {
      createComponent({
        status: {
          detailsPath: '/path',
          details_path: '/path',
        },
        props: {
          useLink: false,
        },
      });

      expect(wrapper.attributes('href')).toBe(undefined);
    });
  });

  describe('rendering a status icon and class', () => {
    it.each`
      icon                 | variant
      ${'status_success'}  | ${'success'}
      ${'status_warning'}  | ${'warning'}
      ${'status_pending'}  | ${'warning'}
      ${'status_failed'}   | ${'danger'}
      ${'status_running'}  | ${'info'}
      ${'status_created'}  | ${'neutral'}
      ${'status_skipped'}  | ${'neutral'}
      ${'status_canceled'} | ${'neutral'}
      ${'status_manual'}   | ${'neutral'}
    `('should render a $group status', ({ icon, variant }) => {
      createComponent({
        props: {
          status: {
            ...mockStatus,
            icon,
          },
          showStatusText: true,
        },
      });
      expect(wrapper.attributes('variant')).toBe(variant);
      expect(wrapper.classes(`ci-icon-variant-${variant}`)).toBe(true);

      expect(findIcon().props('name')).toBe(`${icon}_borderless`);
    });
  });
});
