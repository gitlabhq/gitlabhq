import { shallowMount } from '@vue/test-utils';
import { nextTick } from 'vue';
import MRPopover from '~/mr_popover/components/mr_popover.vue';
import CiIcon from '~/vue_shared/components/ci_icon.vue';

describe('MR Popover', () => {
  let wrapper;

  beforeEach(() => {
    wrapper = shallowMount(MRPopover, {
      propsData: {
        target: document.createElement('a'),
        projectPath: 'foo/bar',
        mergeRequestIID: '1',
        mergeRequestTitle: 'MR Title',
      },
      mocks: {
        $apollo: {
          queries: {
            mergeRequest: {
              loading: false,
            },
          },
        },
      },
    });
  });

  it('shows skeleton-loader while apollo is loading', async () => {
    wrapper.vm.$apollo.queries.mergeRequest.loading = true;

    await nextTick();
    expect(wrapper.element).toMatchSnapshot();
  });

  describe('loaded state', () => {
    it('matches the snapshot', async () => {
      // setData usage is discouraged. See https://gitlab.com/groups/gitlab-org/-/epics/7330 for details
      // eslint-disable-next-line no-restricted-syntax
      wrapper.setData({
        mergeRequest: {
          title: 'Updated Title',
          state: 'opened',
          createdAt: new Date(),
          headPipeline: {
            detailedStatus: {
              group: 'success',
              status: 'status_success',
            },
          },
        },
      });

      await nextTick();
      expect(wrapper.element).toMatchSnapshot();
    });

    it('does not show CI Icon if there is no pipeline data', async () => {
      // setData usage is discouraged. See https://gitlab.com/groups/gitlab-org/-/epics/7330 for details
      // eslint-disable-next-line no-restricted-syntax
      wrapper.setData({
        mergeRequest: {
          state: 'opened',
          headPipeline: null,
          stateHumanName: 'Open',
          title: 'Merge Request Title',
          createdAt: new Date(),
        },
      });

      await nextTick();
      expect(wrapper.find(CiIcon).exists()).toBe(false);
    });

    it('falls back to cached MR title when request fails', async () => {
      await nextTick();
      expect(wrapper.text()).toContain('MR Title');
    });
  });
});
