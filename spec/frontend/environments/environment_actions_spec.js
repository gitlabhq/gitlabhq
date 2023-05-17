import { GlDisclosureDropdown, GlDisclosureDropdownItem, GlIcon } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import { TEST_HOST } from 'helpers/test_constants';
import EnvironmentActions from '~/environments/components/environment_actions.vue';
import { confirmAction } from '~/lib/utils/confirm_via_gl_modal/confirm_via_gl_modal';

jest.mock('~/lib/utils/confirm_via_gl_modal/confirm_via_gl_modal');

const scheduledJobAction = {
  name: 'scheduled action',
  playPath: `${TEST_HOST}/scheduled/job/action`,
  playable: true,
  scheduledAt: '2063-04-05T00:42:00Z',
};

const expiredJobAction = {
  name: 'expired action',
  playPath: `${TEST_HOST}/expired/job/action`,
  playable: true,
  scheduledAt: '2018-10-05T08:23:00Z',
};

describe('EnvironmentActions Component', () => {
  let wrapper;

  function createComponent(props, { options = {} } = {}) {
    wrapper = mount(EnvironmentActions, {
      propsData: { actions: [], ...props },
      ...options,
    });
  }

  function createComponentWithScheduledJobs(opts = {}) {
    return createComponent({ actions: [scheduledJobAction, expiredJobAction] }, opts);
  }

  const findDropdownItems = () => wrapper.findAllComponents(GlDisclosureDropdownItem);
  const findDropdownItem = (action) => {
    const items = findDropdownItems();
    return items.filter((item) => item.text().startsWith(action.name)).at(0);
  };

  afterEach(() => {
    confirmAction.mockReset();
  });

  it('should render a dropdown button with 2 icons', () => {
    createComponent();
    expect(wrapper.findComponent(GlDisclosureDropdown).findAllComponents(GlIcon).length).toBe(2);
  });

  it('should render a dropdown button with aria-label description', () => {
    createComponent();
    expect(wrapper.findComponent(GlDisclosureDropdown).attributes('aria-label')).toBe(
      'Deploy to...',
    );
  });

  describe('manual actions', () => {
    const actions = [
      {
        name: 'bar',
        play_path: 'https://gitlab.com/play',
      },
      {
        name: 'foo',
        play_path: '#',
      },
      {
        name: 'foo bar',
        play_path: 'url',
        playable: false,
      },
    ];

    beforeEach(() => {
      createComponent({ actions });
    });

    it('should render a dropdown with the provided list of actions', () => {
      expect(findDropdownItems()).toHaveLength(actions.length);
    });

    it("should render a disabled action when it's not playable", () => {
      const dropdownItems = findDropdownItems();
      const lastDropdownItem = dropdownItems.at(dropdownItems.length - 1);
      expect(lastDropdownItem.find('button').attributes('disabled')).toBeDefined();
    });
  });

  describe('scheduled jobs', () => {
    beforeEach(() => {
      jest.spyOn(Date, 'now').mockImplementation(() => new Date('2063-04-04T00:42:00Z').getTime());
    });

    it('displays the remaining time in the dropdown', () => {
      confirmAction.mockResolvedValueOnce(true);
      createComponentWithScheduledJobs();
      expect(findDropdownItem(scheduledJobAction).text()).toContain('24:00:00');
    });

    it('displays 00:00:00 for expired jobs in the dropdown', () => {
      confirmAction.mockResolvedValueOnce(true);
      createComponentWithScheduledJobs();
      expect(findDropdownItem(expiredJobAction).text()).toContain('00:00:00');
    });
  });
});
