import { GlSprintf, GlButton, GlModal, GlCard, GlAvatar, GlLink, GlTruncateText } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { sprintf } from '~/locale';
import { renderGFM } from '~/behaviors/markdown/render_gfm';
import ReportedContent from '~/admin/abuse_report/components/reported_content.vue';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import { REPORTED_CONTENT_I18N } from '~/admin/abuse_report/constants';
import { mockAbuseReport } from '../mock_data';

jest.mock('~/behaviors/markdown/render_gfm');

const modalId = 'abuse-report-screenshot-modal';

describe('ReportedContent', () => {
  let wrapper;

  const { report } = { ...mockAbuseReport };

  const findScreenshotButton = () => wrapper.findByTestId('screenshot-button');
  const findReportUrlButton = () => wrapper.findByTestId('report-url-button');
  const findModal = () => wrapper.findComponent(GlModal);
  const findCard = () => wrapper.findComponent(GlCard);
  const findCardHeader = () => findCard().find('.js-test-card-header');
  const findTruncatedText = () => findCardHeader().findComponent(GlTruncateText);
  const findCardBody = () => findCard().find('.js-test-card-body');
  const findCardFooter = () => findCard().find('.js-test-card-footer');
  const findAvatar = () => findCardFooter().findComponent(GlAvatar);
  const findProfileLink = () => findCardFooter().findComponent(GlLink);
  const findTimeAgo = () => findCardFooter().findComponent(TimeAgoTooltip);

  const createComponent = (props = {}) => {
    wrapper = shallowMountExtended(ReportedContent, {
      propsData: {
        report,
        ...props,
      },
      stubs: {
        GlSprintf,
        GlButton,
        GlCard,
        GlTruncateText,
      },
    });
  };

  beforeEach(() => {
    createComponent();
  });

  it('renders the reported type', () => {
    expect(wrapper.html()).toContain(sprintf(REPORTED_CONTENT_I18N.reportTypes[report.type]));
  });

  describe('when the type is unknown', () => {
    beforeEach(() => {
      createComponent({ report: { ...report, type: null } });
    });

    it('renders a header with a generic text content', () => {
      expect(wrapper.html()).toContain(sprintf(REPORTED_CONTENT_I18N.reportTypes.unknown));
    });
  });

  describe('showing the screenshot', () => {
    describe('when the report contains a screenshot', () => {
      it('renders a button to show the screenshot', () => {
        expect(findScreenshotButton().text()).toBe(REPORTED_CONTENT_I18N.viewScreenshot);
      });

      it('renders a modal with the corrrect id and title', () => {
        const modal = findModal();

        expect(modal.props('title')).toBe(REPORTED_CONTENT_I18N.screenshotTitle);
        expect(modal.props('modalId')).toBe(modalId);
      });

      it('contains an image with the screenshot', () => {
        expect(findModal().find('img').element.src).toBe(report.screenshot);
        expect(findModal().find('img').attributes('alt')).toBe(
          REPORTED_CONTENT_I18N.screenshotTitle,
        );
      });

      it('opens the modal when clicking the button', async () => {
        const modal = findModal();

        expect(modal.props('visible')).toBe(false);

        await findScreenshotButton().trigger('click');

        expect(modal.props('visible')).toBe(true);
      });
    });

    describe('when the report does not contain a screenshot', () => {
      beforeEach(() => {
        createComponent({ report: { ...report, screenshot: '' } });
      });

      it('does not render a button and a modal', () => {
        expect(findScreenshotButton().exists()).toBe(false);
        expect(findModal().exists()).toBe(false);
      });
    });
  });

  describe('showing a button to open the reported URL', () => {
    describe('when the report contains a URL', () => {
      it('renders a button with a link to the reported URL', () => {
        expect(findReportUrlButton().text()).toBe(
          sprintf(REPORTED_CONTENT_I18N.goToType[report.type]),
        );
      });
    });

    describe('when the report type is unknown', () => {
      beforeEach(() => {
        createComponent({ report: { ...report, type: null } });
      });

      it('renders a button with a generic text content', () => {
        expect(findReportUrlButton().text()).toBe(sprintf(REPORTED_CONTENT_I18N.goToType.unknown));
      });
    });

    describe('when the report contains no URL', () => {
      beforeEach(() => {
        createComponent({ report: { ...report, url: '' } });
      });

      it('does not render a button with a link to the reported URL', () => {
        expect(findReportUrlButton().exists()).toBe(false);
      });
    });
  });

  describe('rendering the card header', () => {
    describe('when the report contains the reported content', () => {
      it('renders the content', () => {
        const dummyElement = document.createElement('div');
        dummyElement.innerHTML = report.content;
        expect(findTruncatedText().text()).toBe(dummyElement.textContent);
      });

      it('renders gfm', () => {
        expect(renderGFM).toHaveBeenCalled();
      });
    });

    describe('when the report does not contain the reported content', () => {
      beforeEach(() => {
        createComponent({ report: { ...report, content: '' } });
      });

      it('does not render the card header', () => {
        expect(findCardHeader().exists()).toBe(false);
      });
    });
  });

  describe('rendering the card body', () => {
    it('renders the reported by', () => {
      expect(findCardBody().text()).toBe(REPORTED_CONTENT_I18N.reportedBy);
    });
  });

  describe('rendering the card footer', () => {
    it('renders the reporters avatar', () => {
      expect(findAvatar().props('src')).toBe(report.reporter.avatarUrl);
    });

    it('renders the users name', () => {
      expect(findCardFooter().text()).toContain(report.reporter.name);
    });

    it('renders a link to the users profile page', () => {
      const link = findProfileLink();

      expect(link.attributes('href')).toBe(report.reporter.path);
      expect(link.text()).toBe(`@${report.reporter.username}`);
    });

    it('renders the time-ago tooltip', () => {
      expect(findTimeAgo().props('time')).toBe(report.reportedAt);
    });

    it('renders the message', () => {
      expect(findCardFooter().text()).toContain(report.message);
    });
  });
});
