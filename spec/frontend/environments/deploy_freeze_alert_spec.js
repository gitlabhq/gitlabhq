import { GlAlert, GlLink } from '@gitlab/ui';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import DeployFreezeAlert from '~/environments/components/deploy_freeze_alert.vue';
import deployFreezesQuery from '~/environments/graphql/queries/deploy_freezes.query.graphql';
import { localeDateFormat } from '~/lib/utils/datetime/locale_dateformat';

const ENVIRONMENT_NAME = 'staging';

Vue.use(VueApollo);
describe('~/environments/components/deploy_freeze_alert.vue', () => {
  let wrapper;

  const createWrapper = (deployFreezes = []) => {
    const mockApollo = createMockApollo([
      [
        deployFreezesQuery,
        jest.fn().mockResolvedValue({
          data: {
            project: {
              id: '1',
              __typename: 'Project',
              environment: {
                id: '1',
                __typename: 'Environment',
                deployFreezes,
              },
            },
          },
        }),
      ],
    ]);
    wrapper = mountExtended(DeployFreezeAlert, {
      apolloProvider: mockApollo,
      provide: {
        projectFullPath: 'gitlab-org/gitlab',
      },
      propsData: {
        name: ENVIRONMENT_NAME,
      },
    });
  };

  describe('with deploy freezes', () => {
    let deployFreezes;
    let alert;

    beforeEach(async () => {
      deployFreezes = [
        {
          __typename: 'CiFreezePeriod',
          startTime: new Date('2020-02-01'),
          endTime: new Date('2020-02-02'),
        },
        {
          __typename: 'CiFreezePeriod',
          startTime: new Date('2020-01-01'),
          endTime: new Date('2020-01-02'),
        },
      ];

      createWrapper(deployFreezes);

      await waitForPromises();

      alert = wrapper.findComponent(GlAlert);
    });

    it('shows an alert', () => {
      expect(alert.exists()).toBe(true);
    });

    it('shows the start time of the most recent freeze period', () => {
      expect(alert.text()).toContain(
        `from ${localeDateFormat.asDateTimeFull.format(deployFreezes[1].startTime)}`,
      );
    });

    it('shows the end time of the most recent freeze period', () => {
      expect(alert.text()).toContain(
        `to ${localeDateFormat.asDateTimeFull.format(deployFreezes[1].endTime)}`,
      );
    });

    it('shows a link to the docs', () => {
      const link = alert.findComponent(GlLink);
      expect(link.attributes('href')).toBe(
        '/help/user/project/releases/_index#prevent-unintentional-releases-by-setting-a-deploy-freeze',
      );
      expect(link.text()).toBe('deploy freeze documentation');
    });
  });

  describe('without deploy freezes', () => {
    let deployFreezes;
    let alert;

    beforeEach(async () => {
      deployFreezes = [];

      createWrapper(deployFreezes);

      await waitForPromises();

      alert = wrapper.findComponent(GlAlert);
    });

    it('does not show an alert', () => {
      expect(alert.exists()).toBe(false);
    });
  });
});
