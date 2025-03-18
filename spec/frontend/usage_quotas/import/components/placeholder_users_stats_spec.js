import { shallowMount } from '@vue/test-utils';
import { GlSingleStat } from '@gitlab/ui/dist/charts';
import HelpPageLink from '~/vue_shared/components/help_page_link/help_page_link.vue';
import PlaceholderUsersStats from '~/usage_quotas/import/components/placeholder_users_stats.vue';

describe('PlaceholderUsersStats', () => {
  let wrapper;
  const defaultProvide = {
    placeholderUsersCount: 712,
    placeholderUsersLimit: 1001,
  };

  const createComponent = ({ provide = {} } = {}) => {
    wrapper = shallowMount(PlaceholderUsersStats, {
      provide: {
        ...defaultProvide,
        ...provide,
      },
    });
  };

  const findSingleStat = () => wrapper.findComponent(GlSingleStat);
  const findHelpPageLink = () => wrapper.findComponent(HelpPageLink);

  beforeEach(() => {
    createComponent();
  });

  it('renders help text', () => {
    const helpText = wrapper.find('p');

    expect(helpText.text()).toContain(
      "This limit is shared with all subgroups in the group's hierarchy.",
    );
  });

  it('renders help page link', () => {
    const helpPageLink = findHelpPageLink();

    expect(helpPageLink.props()).toMatchObject({
      href: 'user/project/import/_index',
      anchor: 'placeholder-user-limits',
    });
    expect(helpPageLink.text()).toBe('Learn more');
  });

  describe('with limit', () => {
    it('renders single stat', () => {
      expect(findSingleStat().props()).toMatchObject({
        title: 'Placeholder user limit',
        value: '712 / 1,001',
      });
    });
  });

  describe('when limit is unlimited', () => {
    beforeEach(() => {
      createComponent({
        provide: {
          placeholderUsersLimit: 0,
        },
      });
    });

    it('renders single stat', () => {
      expect(findSingleStat().props()).toMatchObject({
        title: 'Placeholder user limit',
        value: 'Unlimited',
      });
    });
  });
});
