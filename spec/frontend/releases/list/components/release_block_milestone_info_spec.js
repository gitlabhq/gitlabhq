import { mount } from '@vue/test-utils';
import { GlProgressBar, GlLink, GlBadge, GlButton } from '@gitlab/ui';
import { trimText } from 'helpers/text_helper';
import ReleaseBlockMilestoneInfo from '~/releases/list/components/release_block_milestone_info.vue';
import { milestones } from '../../mock_data';
import { MAX_MILESTONES_TO_DISPLAY } from '~/releases/list/constants';

describe('Release block milestone info', () => {
  let wrapper;
  let milestonesClone;

  const factory = milestonesProp => {
    wrapper = mount(ReleaseBlockMilestoneInfo, {
      propsData: {
        milestones: milestonesProp,
      },
    });

    return wrapper.vm.$nextTick();
  };

  beforeEach(() => {
    milestonesClone = JSON.parse(JSON.stringify(milestones));
  });

  afterEach(() => {
    wrapper.destroy();
  });

  const milestoneProgressBarContainer = () => wrapper.find('.js-milestone-progress-bar-container');
  const milestoneListContainer = () => wrapper.find('.js-milestone-list-container');
  const issuesContainer = () => wrapper.find('.js-issues-container');

  describe('with default props', () => {
    beforeEach(() => factory(milestonesClone));

    it('renders the correct percentage', () => {
      expect(milestoneProgressBarContainer().text()).toContain('41% complete');
    });

    it('renders a progress bar that displays the correct percentage', () => {
      const progressBar = milestoneProgressBarContainer().find(GlProgressBar);

      expect(progressBar.exists()).toBe(true);
      expect(progressBar.attributes()).toEqual(
        expect.objectContaining({
          value: '22',
          max: '54',
        }),
      );
    });

    it('renders a list of links to all associated milestones', () => {
      expect(trimText(milestoneListContainer().text())).toContain('Milestones 13.6 • 13.5');

      milestonesClone.forEach((m, i) => {
        const milestoneLink = milestoneListContainer()
          .findAll(GlLink)
          .at(i);

        expect(milestoneLink.text()).toBe(m.title);
        expect(milestoneLink.attributes('href')).toBe(m.web_url);
        expect(milestoneLink.attributes('title')).toBe(m.description);
      });
    });

    it('renders the "Issues" section with a total count of issues associated to the milestone(s)', () => {
      const totalIssueCount = 54;
      const issuesContainerText = trimText(issuesContainer().text());

      expect(issuesContainerText).toContain(`Issues ${totalIssueCount}`);

      const badge = issuesContainer().find(GlBadge);
      expect(badge.text()).toBe(totalIssueCount.toString());

      expect(issuesContainerText).toContain('Open: 32 • Closed: 22');
    });
  });

  describe('with lots of milestones', () => {
    let lotsOfMilestones;
    let fullListString;
    let abbreviatedListString;

    beforeEach(() => {
      lotsOfMilestones = [];
      const template = milestonesClone[0];

      for (let i = 0; i < MAX_MILESTONES_TO_DISPLAY + 10; i += 1) {
        lotsOfMilestones.push({
          ...template,
          id: template.id + i,
          iid: template.iid + i,
          title: `m-${i}`,
        });
      }

      fullListString = lotsOfMilestones.map(m => m.title).join(' • ');
      abbreviatedListString = lotsOfMilestones
        .slice(0, MAX_MILESTONES_TO_DISPLAY)
        .map(m => m.title)
        .join(' • ');

      return factory(lotsOfMilestones);
    });

    const clickShowMoreFewerButton = () => {
      milestoneListContainer()
        .find(GlButton)
        .trigger('click');

      return wrapper.vm.$nextTick();
    };

    const milestoneListText = () => trimText(milestoneListContainer().text());

    it('only renders a subset of the milestones', () => {
      expect(milestoneListText()).toContain(`Milestones ${abbreviatedListString} • show 10 more`);
    });

    it('renders all milestones when "show more" is clicked', () =>
      clickShowMoreFewerButton().then(() => {
        expect(milestoneListText()).toContain(`Milestones ${fullListString} • show fewer`);
      }));

    it('returns to the original view when "show fewer" is clicked', () =>
      clickShowMoreFewerButton()
        .then(clickShowMoreFewerButton)
        .then(() => {
          expect(milestoneListText()).toContain(
            `Milestones ${abbreviatedListString} • show 10 more`,
          );
        }));
  });

  const expectAllZeros = () => {
    it('displays percentage as 0%', () => {
      expect(milestoneProgressBarContainer().text()).toContain('0% complete');
    });

    it('shows 0 for all issue counts', () => {
      const issuesContainerText = trimText(issuesContainer().text());

      expect(issuesContainerText).toContain('Issues 0 Open: 0 • Closed: 0');
    });
  };

  /** Ensures we don't have any issues with dividing by zero when computing percentages */
  describe('when all issue counts are zero', () => {
    beforeEach(() => {
      milestonesClone = milestonesClone.map(m => ({
        ...m,
        issue_stats: {
          ...m.issue_stats,
          opened: 0,
          closed: 0,
        },
      }));

      return factory(milestonesClone);
    });

    expectAllZeros();
  });

  describe('if the API response is missing the "issue_stats" property', () => {
    beforeEach(() => {
      milestonesClone = milestonesClone.map(m => ({
        ...m,
        issue_stats: undefined,
      }));

      return factory(milestonesClone);
    });

    expectAllZeros();
  });
});
