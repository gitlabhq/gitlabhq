import { GlLink } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import SidebarDetailRow from '~/ci/job_details/components/sidebar/sidebar_detail_row.vue';
import HelpIcon from '~/vue_shared/components/help_icon/help_icon.vue';

describe('Sidebar detail row', () => {
  let wrapper;

  const title = 'this is the title';
  const value = 'this is the value';
  const helpUrl = 'https://docs.gitlab.com/runner/register/index.html';
  const path = 'path/to/value';

  const createWrapper = (props) => {
    wrapper = shallowMountExtended(SidebarDetailRow, {
      propsData: {
        ...props,
      },
    });
  };

  const findHelpLink = () => wrapper.findByTestId('job-sidebar-help-link');
  const findValueTitle = () => wrapper.findByTestId('job-sidebar-value-title');
  const findValueLink = () => wrapper.findByTestId('job-sidebar-value-link');
  const findValueText = () => wrapper.findByTestId('job-sidebar-value-span');

  describe('with title/value props', () => {
    beforeEach(() => {
      createWrapper({ title, value });
    });

    it('should render provided title and value', () => {
      expect(findValueTitle().text()).toBe(title);
      expect(findValueText().text()).toBe(value);
    });

    it('renders title inside the default heading tag', () => {
      expect(findValueTitle().text()).toBe(title);
    });
  });

  describe('with headingTag prop', () => {
    it('renders title inside the provided heading tag', () => {
      createWrapper({ title, value, headingTag: 'h3' });

      expect(findValueTitle().text()).toBe(title);
      expect(findValueTitle().element.tagName).toBe('H3');
    });
  });

  describe('when title is not provided', () => {
    beforeEach(() => {
      createWrapper({ value });
    });

    it('should not render title', () => {
      expect(findValueTitle().exists()).toBe(false);
    });

    it('should render the value', () => {
      expect(findValueText().text()).toContain(value);
    });
  });

  describe('when helpUrl is provided', () => {
    beforeEach(() => {
      createWrapper({ title, value, helpUrl });
    });

    it('should render the help link', () => {
      expect(findHelpLink().exists()).toBe(true);
      expect(findHelpLink().attributes('href')).toBe(helpUrl);
    });

    it('should render an accessible label and help icon', () => {
      expect(findHelpLink().attributes('aria-label')).toBe('Job help');
      expect(findHelpLink().findComponent(HelpIcon).exists()).toBe(true);
    });
  });

  describe('when helpUrl is not provided', () => {
    it('should not render the help link', () => {
      createWrapper({ title, value });

      expect(findHelpLink().exists()).toBe(false);
    });
  });

  describe('when path is provided', () => {
    beforeEach(() => {
      createWrapper({ title, value, path });
    });

    it('should render the value as a link', () => {
      expect(findValueLink().exists()).toBe(true);
      expect(findValueLink().attributes('href')).toBe(path);
      expect(findValueLink().text()).toBe(value);
    });

    it('should not render the value inside a span', () => {
      expect(findValueLink().exists()).toBe(true);
      expect(findValueText().exists()).toBe(false);
    });
  });

  describe('when path is not provided', () => {
    beforeEach(() => {
      createWrapper({ title, value });
    });

    it('should not render the value link', () => {
      expect(findValueLink().exists()).toBe(false);
      expect(findValueText().exists()).toBe(true);
    });

    it('should render the value inside a span', () => {
      expect(findValueText().exists()).toBe(true);
      expect(findValueText().text()).toContain(value);
    });
  });

  describe('slot', () => {
    it('renders slot content inside the value span', () => {
      wrapper = shallowMountExtended(SidebarDetailRow, {
        propsData: { title, value },
        slots: {
          default: '<span data-testid="slot-content">slotted</span>',
        },
      });

      expect(wrapper.findByTestId('slot-content').exists()).toBe(true);
    });
  });

  describe('GlLink usage', () => {
    it('renders no links when neither path nor helpUrl are provided', () => {
      createWrapper({ title, value });

      expect(wrapper.findAllComponents(GlLink)).toHaveLength(0);
    });
  });
});
