import { GlBadge, GlLink } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import StuckBlock from '~/ci/job_details/components/stuck_block.vue';

describe('Stuck Block Job component', () => {
  let wrapper;

  const createWrapper = (props) => {
    wrapper = shallowMount(StuckBlock, {
      propsData: {
        ...props,
      },
    });
  };

  const tags = ['docker', 'gitlab-org'];

  const findStuckNoActiveRunners = () =>
    wrapper.find('[data-testid="job-stuck-no-active-runners"]');
  const findStuckNoRunners = () => wrapper.find('[data-testid="job-stuck-no-runners"]');
  const findStuckWithTags = () => wrapper.find('[data-testid="job-stuck-with-tags"]');
  const findRunnerPathLink = () => wrapper.findComponent(GlLink);
  const findAllBadges = () => wrapper.findAllComponents(GlBadge);

  describe('with no runners for project', () => {
    beforeEach(() => {
      createWrapper({
        hasOfflineRunnersForProject: true,
        runnersPath: '/root/project/runners#js-runners-settings',
      });
    });

    it('renders only information about project not having runners', () => {
      expect(findStuckNoRunners().exists()).toBe(true);
      expect(findStuckWithTags().exists()).toBe(false);
      expect(findStuckNoActiveRunners().exists()).toBe(false);
    });

    it('renders link to runners page', () => {
      expect(findRunnerPathLink().attributes('href')).toBe(
        '/root/project/runners#js-runners-settings',
      );
    });
  });

  describe('with tags', () => {
    beforeEach(() => {
      createWrapper({
        hasOfflineRunnersForProject: false,
        tags,
        runnersPath: '/root/project/runners#js-runners-settings',
      });
    });

    it('renders information about the tags not being set', () => {
      expect(findStuckWithTags().exists()).toBe(true);
      expect(findStuckNoActiveRunners().exists()).toBe(false);
      expect(findStuckNoRunners().exists()).toBe(false);
    });

    it('renders tags', () => {
      findAllBadges().wrappers.forEach((badgeElt, index) => {
        return expect(badgeElt.text()).toBe(tags[index]);
      });
    });

    it('renders link to runners page', () => {
      expect(findRunnerPathLink().attributes('href')).toBe(
        '/root/project/runners#js-runners-settings',
      );
    });
  });

  describe('without active runners', () => {
    beforeEach(() => {
      createWrapper({
        hasOfflineRunnersForProject: false,
        runnersPath: '/root/project/runners#js-runners-settings',
      });
    });

    it('renders information about project not having runners', () => {
      expect(findStuckNoActiveRunners().exists()).toBe(true);
      expect(findStuckNoRunners().exists()).toBe(false);
      expect(findStuckWithTags().exists()).toBe(false);
    });

    it('renders link to runners page', () => {
      expect(findRunnerPathLink().attributes('href')).toBe(
        '/root/project/runners#js-runners-settings',
      );
    });
  });
});
