import { GlLink } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import SidebarDetailRow from '~/jobs/components/job/sidebar/sidebar_detail_row.vue';

describe('Sidebar detail row', () => {
  let wrapper;

  const title = 'this is the title';
  const value = 'this is the value';
  const helpUrl = 'https://docs.gitlab.com/runner/register/index.html';

  const findHelpLink = () => wrapper.findComponent(GlLink);

  const createComponent = (props) => {
    wrapper = shallowMount(SidebarDetailRow, {
      propsData: {
        ...props,
      },
    });
  };

  describe('with title/value and without helpUrl', () => {
    beforeEach(() => {
      createComponent({ title, value });
    });

    it('should render the provided title and value', () => {
      expect(wrapper.text()).toBe(`${title}: ${value}`);
    });

    it('should not render the help link', () => {
      expect(findHelpLink().exists()).toBe(false);
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
});
