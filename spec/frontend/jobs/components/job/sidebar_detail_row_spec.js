import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import SidebarDetailRow from '~/jobs/components/job/sidebar/sidebar_detail_row.vue';

describe('Sidebar detail row', () => {
  let wrapper;

  const title = 'this is the title';
  const value = 'this is the value';
  const helpUrl = 'https://docs.gitlab.com/runner/register/index.html';
  const path = 'path/to/value';

  const findHelpLink = () => wrapper.findByTestId('job-sidebar-help-link');
  const findValueLink = () => wrapper.findByTestId('job-sidebar-value-link');

  const createComponent = (props) => {
    wrapper = shallowMountExtended(SidebarDetailRow, {
      propsData: {
        ...props,
      },
    });
  };

  describe('with title/value and without helpUrl/path', () => {
    beforeEach(() => {
      createComponent({ title, value });
    });

    it('should render the provided title and value', () => {
      expect(wrapper.text()).toBe(`${title}: ${value}`);
    });

    it('should not render the help link', () => {
      expect(findHelpLink().exists()).toBe(false);
    });

    it('should not render the value link', () => {
      expect(findValueLink().exists()).toBe(false);
    });
  });

  describe('when helpUrl provided', () => {
    beforeEach(() => {
      createComponent({
        helpUrl,
        title,
        value,
      });
    });

    it('should render the help link', () => {
      expect(findHelpLink().exists()).toBe(true);
      expect(findHelpLink().attributes('href')).toBe(helpUrl);
    });
  });

  describe('when path is provided', () => {
    it('should render link to value', () => {
      createComponent({
        path,
        title,
        value,
      });

      expect(findValueLink().attributes('href')).toBe(path);
    });
  });
});
