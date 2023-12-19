import { GlButton, GlAvatarLink, GlTooltip } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import CiIcon from '~/vue_shared/components/ci_icon/ci_icon.vue';
import JobHeader from '~/ci/job_details/components/job_header.vue';
import TimeagoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';

describe('Header CI Component', () => {
  let wrapper;

  const defaultProps = {
    status: {
      group: 'failed',
      icon: 'status_failed',
      label: 'failed',
      text: 'failed',
      details_path: 'path',
    },
    name: 'build_job',
    time: '2017-05-08T14:57:39.781Z',
    user: {
      id: 1234,
      web_url: 'path',
      name: 'Foo',
      username: 'foobar',
      email: 'foo@bar.com',
      avatar_url: 'link',
    },
    shouldRenderTriggeredLabel: true,
  };

  const findCiIcon = () => wrapper.findComponent(CiIcon);
  const findTimeAgo = () => wrapper.findComponent(TimeagoTooltip);
  const findUserLink = () => wrapper.findComponent(GlAvatarLink);
  const findSidebarToggleBtn = () => wrapper.findComponent(GlButton);
  const findStatusTooltip = () => wrapper.findComponent(GlTooltip);
  const findJobName = () => wrapper.findByTestId('job-name');

  const createComponent = (props) => {
    wrapper = extendedWrapper(
      shallowMount(JobHeader, {
        propsData: {
          ...defaultProps,
          ...props,
        },
      }),
    );
  };

  describe('render', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders the correct job name', () => {
      expect(findJobName().text()).toBe(defaultProps.name);
    });

    it('should render status badge', () => {
      expect(findCiIcon().exists()).toBe(true);
    });

    it('should render timeago date', () => {
      expect(findTimeAgo().exists()).toBe(true);
    });

    it('should render sidebar toggle button', () => {
      expect(findSidebarToggleBtn().exists()).toBe(true);
    });
  });

  describe('user avatar', () => {
    beforeEach(() => {
      createComponent();
    });

    it('contains the username', () => {
      expect(findUserLink().text()).toContain(defaultProps.user.username);
    });

    it('has the correct HTML attributes', () => {
      expect(findUserLink().attributes()).toMatchObject({
        'data-user-id': defaultProps.user.id.toString(),
        'data-username': defaultProps.user.username,
        'data-name': defaultProps.user.name,
        href: defaultProps.user.web_url,
      });
    });

    describe('when the user has a status', () => {
      const STATUS_MESSAGE = 'Working on exciting features...';

      beforeEach(() => {
        createComponent({
          user: { ...defaultProps.user, status: { message: STATUS_MESSAGE } },
        });
      });

      it('renders a tooltip', () => {
        expect(findStatusTooltip().text()).toBe(STATUS_MESSAGE);
      });
    });

    describe('with data from GraphQL', () => {
      const userId = 1;

      beforeEach(() => {
        createComponent({
          user: { ...defaultProps.user, id: `gid://gitlab/User/${1}` },
        });
      });

      it('has the correct user id', () => {
        expect(findUserLink().attributes('data-user-id')).toBe(userId.toString());
      });
    });

    describe('with data from REST', () => {
      it('has the correct user id', () => {
        expect(findUserLink().attributes('data-user-id')).toBe(defaultProps.user.id.toString());
      });
    });
  });

  describe('shouldRenderTriggeredLabel', () => {
    it('should render created keyword when the shouldRenderTriggeredLabel is false', () => {
      createComponent({ shouldRenderTriggeredLabel: false });

      expect(wrapper.text()).toContain('Created');
      expect(wrapper.text()).not.toContain('Started');
    });
  });
});
