import { GlButton, GlToggle, GlTableLite } from '@gitlab/ui';
import { nextTick } from 'vue';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import { trimText } from 'helpers/text_helper';
import { mockTracking } from 'helpers/tracking_helper';
import FeatureFlagsTable from '~/feature_flags/components/feature_flags_table.vue';
import {
  ROLLOUT_STRATEGY_ALL_USERS,
  ROLLOUT_STRATEGY_PERCENT_ROLLOUT,
  ROLLOUT_STRATEGY_USER_ID,
  ROLLOUT_STRATEGY_GITLAB_USER_LIST,
} from '~/feature_flags/constants';

const getDefaultProps = () => ({
  featureFlags: [
    {
      id: 1,
      iid: 1,
      active: true,
      name: 'flag name',
      description: 'flag description',
      destroy_path: 'destroy/path',
      edit_path: 'edit/path',
      scopes: [],
      strategies: [
        {
          name: ROLLOUT_STRATEGY_ALL_USERS,
          parameters: {},
          scopes: [{ environment_scope: '*' }],
        },
        {
          name: ROLLOUT_STRATEGY_PERCENT_ROLLOUT,
          parameters: { percentage: '50' },
          scopes: [{ environment_scope: 'production' }, { environment_scope: 'staging' }],
        },
        {
          name: ROLLOUT_STRATEGY_USER_ID,
          parameters: { userIds: '1,2,3,4' },
          scopes: [{ environment_scope: 'review/*' }],
        },
        {
          name: ROLLOUT_STRATEGY_GITLAB_USER_LIST,
          parameters: {},
          user_list: { name: 'test list' },
          scopes: [{ environment_scope: '*' }],
        },
      ],
    },
    {
      id: 2,
      iid: 2,
      active: true,
      name: 'flag without description',
      description: '',
    },
  ],
});

describe('Feature flag table', () => {
  let wrapper;
  let props;
  let labels;

  const createWrapper = (propsData, opts = {}) => {
    wrapper = mountExtended(FeatureFlagsTable, {
      propsData,
      provide: {
        csrfToken: 'fakeToken',
      },
      ...opts,
      directives: {
        GlTooltip: createMockDirective('gl-tooltip'),
      },
    });
  };

  const findTable = () => wrapper.findComponent(GlTableLite);

  beforeEach(() => {
    props = getDefaultProps();
    createWrapper(props, {
      provide: { csrfToken: 'fakeToken' },
    });

    labels = wrapper.findAllByTestId('strategy-label');
  });

  beforeEach(() => {
    props = getDefaultProps();
  });

  describe('with an active scope and a standard rollout strategy', () => {
    beforeEach(() => {
      createWrapper(props);
    });

    it('Should render a table', () => {
      expect(findTable().exists()).toBe(true);
    });

    it('should render an ID column', () => {
      expect(wrapper.findByTestId('feature-flag-id').exists()).toBe(true);
      expect(trimText(wrapper.findByTestId('feature-flag-id').text())).toEqual('^1');
    });

    it('Should render a status column', () => {
      const badge = wrapper.findByTestId('feature-flag-status-badge');

      expect(badge.exists()).toBe(true);
      expect(trimText(badge.text())).toEqual('Active');
    });

    it('Should render a feature flag column', () => {
      expect(wrapper.findByTestId('feature-flag-title').exists()).toBe(true);
      expect(trimText(wrapper.find('.feature-flag-name').text())).toEqual('flag name');
    });

    it('should render an environments specs label', () => {
      const strategyLabel = wrapper.findByTestId('strategy-label');

      expect(trimText(strategyLabel.text())).toBe('All Users: All Environments');
    });

    it('should render an actions column', () => {
      expect(wrapper.findByTestId('flags-table-action-buttons').exists()).toBe(true);
      expect(wrapper.findByTestId('feature-flag-delete-button').exists()).toBe(true);
      expect(wrapper.findByTestId('feature-flag-edit-button').exists()).toBe(true);
      expect(wrapper.findByTestId('feature-flag-edit-button').attributes('href')).toEqual(
        'edit/path',
      );
    });
  });

  describe.each(getDefaultProps().featureFlags)('description tooltip', (featureFlag) => {
    beforeEach(() => {
      createWrapper(props);
    });

    const haveInfoIcon = Boolean(featureFlag.description);

    it(`${haveInfoIcon ? 'displays' : "doesn't display"} an information icon`, () => {
      expect(
        wrapper
          .findByTestId(`feature-flag-description-${featureFlag.id}`)
          .findComponent(GlButton)
          .exists(),
      ).toBe(haveInfoIcon);
    });

    if (haveInfoIcon) {
      it('includes a tooltip', () => {
        const icon = wrapper
          .findByTestId(`feature-flag-description-${featureFlag.id}`)
          .findComponent(GlButton);
        const tooltip = getBinding(icon.element, 'gl-tooltip');

        expect(tooltip).toBeDefined();
        expect(tooltip.value).toBe(featureFlag.description);
      });
    }
  });

  describe('when active and with an update toggle', () => {
    let toggle;
    let spy;

    beforeEach(() => {
      props.featureFlags[0].update_path = props.featureFlags[0].destroy_path;
      createWrapper(props);
      toggle = wrapper.findComponent(GlToggle);
      spy = mockTracking('_category_', toggle.element, jest.spyOn);
    });

    it('should have a toggle', () => {
      expect(toggle.exists()).toBe(true);
      expect(toggle.props()).toMatchObject({
        label: FeatureFlagsTable.i18n.toggleLabel,
        value: true,
      });
    });

    it('should trigger a toggle event', async () => {
      toggle.vm.$emit('change');
      const flag = { ...props.featureFlags[0], active: !props.featureFlags[0].active };

      await nextTick();
      expect(wrapper.emitted('toggle-flag')).toEqual([[flag]]);
    });

    it('tracks a click', () => {
      toggle.trigger('click');

      expect(spy).toHaveBeenCalledWith('_category_', 'click_button', {
        label: 'feature_flag_toggle',
      });
    });
  });

  it('shows All Environments if the environment scope is *', () => {
    expect(labels.at(0).text()).toContain('All Environments');
  });

  it('shows the environment scope if another is set', () => {
    expect(labels.at(1).text()).toContain('production');
    expect(labels.at(1).text()).toContain('staging');
    expect(labels.at(2).text()).toContain('review/*');
  });

  it('shows All Users for the default strategy', () => {
    expect(labels.at(0).text()).toContain('All Users');
  });

  it('shows the percent for a percent rollout', () => {
    expect(labels.at(1).text()).toContain('Percent of users - 50%');
  });

  it('shows the number of users for users with ID', () => {
    expect(labels.at(2).text()).toContain('User IDs - 4 users');
  });

  it('shows the name of a user list for user list', () => {
    expect(labels.at(3).text()).toContain('User List - test list');
  });

  it('renders a feature flag without an iid', () => {
    delete props.featureFlags[0].iid;
    createWrapper(props);

    expect(wrapper.findByTestId('feature-flag-id').exists()).toBe(true);
    expect(trimText(wrapper.findByTestId('feature-flag-id').text())).toBe('');
  });
});
