import { mount } from '@vue/test-utils';
import { GlProgressBar, GlLink, GlBadge, GlButton } from '@gitlab/ui';
import { trimText } from 'helpers/text_helper';
import ReleaseBlockMilestoneInfo from '~/releases/components/release_block_milestone_info.vue';
import { milestones as originalMilestones } from '../mock_data';
import { MAX_MILESTONES_TO_DISPLAY } from '~/releases/constants';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';

describe('Release block milestone info', () => {
  let wrapper;
  let milestones;

  const factory = props => {
    wrapper = mount(ReleaseBlockMilestoneInfo, {
      propsData: props,
    });

    return wrapper.vm.$nextTick();
  };

  beforeEach(() => {
    milestones = convertObjectPropsToCamelCase(originalMilestones, { deep: true });
  });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  const milestoneProgressBarContainer = () => wrapper.find('.js-milestone-progress-bar-container');
  const milestoneListContainer = () => wrapper.find('.js-milestone-list-container');
  const issuesContainer = () => wrapper.find('.js-issues-container');

  describe('with default props', () => {
    beforeEach(() => factory({ milestones }));

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

      milestones.forEach((m, i) => {
        const milestoneLink = milestoneListContainer()
          .findAll(GlLink)
          .at(i);

        expect(milestoneLink.text()).toBe(m.title);
        expect(milestoneLink.attributes('href')).toBe(m.webUrl);
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
      const template = milestones[0];

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

      return factory({ milestones: lotsOfMilestones });
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
      milestones = milestones.map(m => ({
        ...m,
        issueStats: {
          ...m.issueStats,
          total: 0,
          closed: 0,
        },
      }));

      return factory({ milestones });
    });

    expectAllZeros();
  });

  describe('if the API response is missing the "issue_stats" property', () => {
    beforeEach(() => {
      milestones = milestones.map(m => ({
        ...m,
        issueStats: undefined,
      }));

      return factory({ milestones });
    });

    expectAllZeros();
  });

  describe('Issue links', () => {
    const findOpenIssuesLink = () => wrapper.find({ ref: 'openIssuesLink' });
    const findOpenIssuesText = () => wrapper.find({ ref: 'openIssuesText' });
    const findClosedIssuesLink = () => wrapper.find({ ref: 'closedIssuesLink' });
    const findClosedIssuesText = () => wrapper.find({ ref: 'closedIssuesText' });

    describe('when openIssuePath is provided', () => {
      const openIssuesPath = '/path/to/open/issues';

      beforeEach(() => {
        return factory({ milestones, openIssuesPath });
      });

      it('renders the open issues as a link', () => {
        expect(findOpenIssuesLink().exists()).toBe(true);
        expect(findOpenIssuesText().exists()).toBe(false);
      });

      it('renders the open issues link with the correct href', () => {
        expect(findOpenIssuesLink().attributes().href).toBe(openIssuesPath);
      });
    });

    describe('when openIssuePath is not provided', () => {
      beforeEach(() => {
        return factory({ milestones });
      });

      it('renders the open issues as plain text', () => {
        expect(findOpenIssuesLink().exists()).toBe(false);
        expect(findOpenIssuesText().exists()).toBe(true);
      });
    });

    describe('when closedIssuePath is provided', () => {
      const closedIssuesPath = '/path/to/closed/issues';

      beforeEach(() => {
        return factory({ milestones, closedIssuesPath });
      });

      it('renders the closed issues as a link', () => {
        expect(findClosedIssuesLink().exists()).toBe(true);
        expect(findClosedIssuesText().exists()).toBe(false);
      });

      it('renders the closed issues link with the correct href', () => {
        expect(findClosedIssuesLink().attributes().href).toBe(closedIssuesPath);
      });
    });

    describe('when closedIssuePath is not provided', () => {
      beforeEach(() => {
        return factory({ milestones });
      });

      it('renders the closed issues as plain text', () => {
        expect(findClosedIssuesLink().exists()).toBe(false);
        expect(findClosedIssuesText().exists()).toBe(true);
      });
    });
  });
});
