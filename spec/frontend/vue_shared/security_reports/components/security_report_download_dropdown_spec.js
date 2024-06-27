import { GlDisclosureDropdown } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import SecurityReportDownloadDropdown from '~/vue_shared/security_reports/components/security_report_download_dropdown.vue';

describe('SecurityReportDownloadDropdown component', () => {
  let wrapper;
  let artifacts;

  const createComponent = (props) => {
    wrapper = shallowMount(SecurityReportDownloadDropdown, {
      propsData: { ...props },
    });
  };

  const findDropdown = () => wrapper.findComponent(GlDisclosureDropdown);

  describe('given report artifacts', () => {
    beforeEach(() => {
      artifacts = [
        {
          name: 'foo',
          path: '/foo.json',
        },
        {
          name: 'bar',
          path: '/bar.json',
        },
      ];

      createComponent({ artifacts, text: 'test' });
    });

    it('renders a dropdown', () => {
      expect(findDropdown().props('loading')).toBe(false);
      expect(findDropdown().props('toggleText')).toBe('test');
      expect(findDropdown().attributes()).toMatchObject({
        placement: 'bottom-end',
        size: 'small',
        icon: 'download',
      });
    });

    it('passes artifacts as items', () => {
      expect(findDropdown().props('items')).toMatchObject([
        {
          text: 'Download foo',
          href: '/foo.json',
          extraAttrs: {
            download: '',
          },
        },
        {
          text: 'Download bar',
          href: '/bar.json',
          extraAttrs: {
            download: '',
          },
        },
      ]);
    });
  });

  describe('given it is loading', () => {
    beforeEach(() => {
      createComponent({ artifacts: [], loading: true });
    });

    it('renders a loading dropdown', () => {
      expect(findDropdown().props('loading')).toBe(true);
    });
  });

  describe('given it is not loading and no artifacts', () => {
    beforeEach(() => {
      createComponent({ artifacts: [], loading: false });
    });

    it('does not render dropdown', () => {
      expect(findDropdown().exists()).toBe(false);
    });
  });
});
