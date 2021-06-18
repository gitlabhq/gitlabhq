import { GlDropdown, GlDropdownItem } from '@gitlab/ui';
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

  const findDropdown = () => wrapper.find(GlDropdown);
  const findDropdownItems = () => wrapper.findAll(GlDropdownItem);

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

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

      createComponent({ artifacts });
    });

    it('renders a dropdown', () => {
      expect(findDropdown().props('loading')).toBe(false);
    });

    it('renders a dropdown item for each artifact', () => {
      artifacts.forEach((artifact, i) => {
        const item = findDropdownItems().at(i);
        expect(item.text()).toContain(artifact.name);

        expect(item.element.getAttribute('href')).toBe(artifact.path);
        expect(item.element.getAttribute('download')).toBeDefined();
      });
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

  describe('given title props', () => {
    beforeEach(() => {
      createComponent({ artifacts: [], loading: true, title: 'test title' });
    });

    it('should render title', () => {
      expect(findDropdown().attributes('title')).toBe('test title');
    });

    it('should not render text', () => {
      expect(findDropdown().text().trim()).toBe('');
    });
  });

  describe('given text props', () => {
    beforeEach(() => {
      createComponent({ artifacts: [], loading: true, text: 'test text' });
    });

    it('should not render title', () => {
      expect(findDropdown().props().title).not.toBeDefined();
    });

    it('should render text', () => {
      expect(findDropdown().props().text).toContain('test text');
    });
  });
});
